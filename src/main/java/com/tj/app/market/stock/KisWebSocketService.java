package com.tj.app.market.stock;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketHttpHeaders;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.handler.AbstractWebSocketHandler;

import jakarta.websocket.ContainerProvider;
import jakarta.websocket.WebSocketContainer;
import java.net.URI;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class KisWebSocketService {

    @Autowired
    private WebClientService webClientService;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private StockJoinMapper stockJoinMapper;

    @Value("${app.stock.websocket.enabled:false}")
    private boolean stockWebSocketEnabled;

    private final ObjectMapper objectMapper = new ObjectMapper();

    // 종목코드 → 최신 시세 (price/rate/diff/high/low)
    private final Map<String, Map<String, String>> priceCache = new ConcurrentHashMap<>();
    // 종목코드 → 종목명
    private final Map<String, String> nameCache = new ConcurrentHashMap<>();

    public Map<String, Map<String, String>> getPriceCache() { return priceCache; }
    public Map<String, String> getNameCache() { return nameCache; }

    public void connect() {
        if (!stockWebSocketEnabled) {
            log.info("주식 WebSocket 연결이 비활성화되어 있습니다.");
            return;
        }

        try {
            String approvalKey = webClientService.getApprovalKey();

            List<Map<String, Object>> stocks;
            try {
                stocks = stockJoinMapper.findTop40Stocks();
            } catch (Exception dbEx) {
                log.warn("⚠️ DB 조회 실패로 KIS WebSocket 연결을 중단합니다: {}", dbEx.getMessage());
                return;
            }

            List<String> codes = stocks.stream()
                    .map(s -> (String) s.get("code"))
                    .toList();

            // 종목명 캐시 초기화
            stocks.forEach(s -> nameCache.put((String) s.get("code"), (String) s.get("name")));

            WebSocketContainer container = ContainerProvider.getWebSocketContainer();
            container.setDefaultMaxTextMessageBufferSize(1024 * 1024);
            container.setDefaultMaxBinaryMessageBufferSize(1024 * 1024);
            StandardWebSocketClient client = new StandardWebSocketClient(container);
            URI uri = URI.create("ws://ops.koreainvestment.com:31000");
            client.execute(new AbstractWebSocketHandler() {

                @Override
                public void afterConnectionEstablished(WebSocketSession session) throws Exception {
                    log.info("✅ KIS WebSocket 연결 성공");
                    for (String code : codes) {
                        subscribe(session, approvalKey, code);
                        Thread.sleep(50); // 요청 사이 딜레이 (너무 빠르면 누락됨)
                    }
                    log.info("📡 {}개 종목 구독 완료", codes.size());
                }

                @Override
                protected void handleTextMessage(WebSocketSession session, TextMessage message) {
                    parseAndBroadcast(message.getPayload());
                }

                @Override
                public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
                    log.warn("⚠️ KIS WebSocket 연결 끊김 ({}), 3초 후 재연결", status);
                    new Thread(() -> {
                        try {
                            Thread.sleep(3000);
                            if (stockWebSocketEnabled) connect();
                        } catch (InterruptedException ignored) {}
                    }).start();
                }

            }, new WebSocketHttpHeaders(), uri);

        } catch (Exception e) {
            log.error("❌ KIS WebSocket 연결 실패: {}", e.getMessage());
        }
    }

    private void subscribe(WebSocketSession session, String approvalKey, String code) throws Exception {
        Map<String, Object> msg = new HashMap<>();
        msg.put("header", Map.of(
                "approval_key", approvalKey,
                "custtype", "P",
                "tr_type", "1",
                "content-type", "utf-8"
        ));
        msg.put("body", Map.of(
                "input", Map.of(
                        "tr_id", "H0STCNT0",
                        "tr_key", code
                )
        ));
        session.sendMessage(new TextMessage(objectMapper.writeValueAsString(msg)));
    }

    private void parseAndBroadcast(String payload) {
        try {
            // 구독 확인 메시지(JSON)는 무시
            if (payload.startsWith("{")) return;

            // 포맷: 0|H0STCNT0|001|필드0^필드1^필드2^...
            String[] outer = payload.split("\\|");
            if (outer.length < 4 || !"0".equals(outer[0])) return;
            if (!"H0STCNT0".equals(outer[1])) return;

            String[] fields = outer[3].split("\\^");
            if (fields.length < 10) return;

            String code   = fields[0];  // 종목코드
            String price  = fields[2];  // 현재가
            String sign   = fields[3];  // 부호 (1,2:상승 / 3:보합 / 4,5:하락)
            String diff   = fields[4];  // 전일대비 금액
            String rate   = fields[5];  // 등락률
            String high   = fields[8];  // 고가
            String low    = fields[9];  // 저가
            String volume = fields.length > 14 ? fields[14] : "0"; // 누적 거래대금

            // 하락이면 마이너스 부호 적용
            boolean isDown = "4".equals(sign) || "5".equals(sign);
            if (isDown) {
                if (!diff.startsWith("-")) diff = "-" + diff;
                if (!rate.startsWith("-")) rate = "-" + rate;
            }

            Map<String, String> data = new HashMap<>();
            data.put("code",   code);
            data.put("price",  price);
            data.put("rate",   rate);
            data.put("diff",   diff);
            data.put("high",   high);
            data.put("low",    low);
            data.put("volume", volume);

            // 서버 캐시 갱신 (급상승/급하락 필터용)
            priceCache.put(code, data);

            messagingTemplate.convertAndSend("/topic/stock/price", data);

        } catch (Exception e) {
            log.error("❌ KIS 데이터 파싱 오류: {}", e.getMessage());
        }
    }
}
