package com.tj.app.market.stock;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;

import org.springframework.beans.factory.ObjectProvider;
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
import org.springframework.scheduling.annotation.Scheduled;

import java.net.URI;
import java.time.DayOfWeek;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class KisWebSocketService {

	private final ObjectProvider<StockService> stockServiceProvider;

    // 생성자에서 바로 StockService를 받지 말고 ObjectProvider로 받으세요!
    public KisWebSocketService(ObjectProvider<StockService> stockServiceProvider) {
        this.stockServiceProvider = stockServiceProvider;
    }

    // 서비스가 실제로 필요할 때 아래처럼 호출합니다.
    private StockService getStockService() {
        return stockServiceProvider.getObject();
    }

    @Autowired
    private WebClientService webClientService;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private StockJoinMapper stockJoinMapper;

    @Value("${app.stock.websocket.enabled:false}")
    private boolean stockWebSocketEnabled;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private volatile WebSocketSession currentSession;

    private static final ZoneId KST = ZoneId.of("Asia/Seoul");
    private static final LocalTime MARKET_OPEN  = LocalTime.of(9, 0);
    private static final LocalTime MARKET_CLOSE = LocalTime.of(15, 35);

    // 종목코드 → 최신 시세 (price/rate/diff/high/low)
    private final Map<String, Map<String, String>> priceCache = new ConcurrentHashMap<>();
    // 종목코드 → 종목명
    private final Map<String, String> nameCache = new ConcurrentHashMap<>();

    public Map<String, Map<String, String>> getPriceCache() { return priceCache; }
    public Map<String, String> getNameCache() { return nameCache; }

    private boolean isMarketHours() {
        ZonedDateTime now = ZonedDateTime.now(KST);
        DayOfWeek day = now.getDayOfWeek();
        if (day == DayOfWeek.SATURDAY || day == DayOfWeek.SUNDAY) return false;
        LocalTime time = now.toLocalTime();
        return !time.isBefore(MARKET_OPEN) && !time.isAfter(MARKET_CLOSE);
    }

    @Scheduled(cron = "0 0 9 * * MON-FRI", zone = "Asia/Seoul")
    public void connectOnMarketOpen() {
        log.info("🔔 장 시작 - KIS WebSocket 연결 시도");
        connect();
    }

    @Scheduled(cron = "0 35 15 * * MON-FRI", zone = "Asia/Seoul")
    public void disconnectOnMarketClose() {
        log.info("🔔 장 마감 - KIS WebSocket 연결 종료");
        disconnect();
    }

    public void disconnect() {
        if (currentSession != null && currentSession.isOpen()) {
            try {
                currentSession.close();
            } catch (Exception e) {
                log.warn("⚠️ KIS WebSocket 종료 중 오류: {}", e.getMessage());
            }
        }
    }

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
                    currentSession = session;
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
                    if (isMarketHours()) {
                        log.warn("⚠️ KIS WebSocket 연결 끊김 ({}), 3초 후 재연결", status);
                        new Thread(() -> {
                            try {
                                Thread.sleep(3000);
                                if (stockWebSocketEnabled) connect();
                            } catch (InterruptedException ignored) {}
                        }).start();
                    } else {
                        log.info("📴 KIS WebSocket 연결 종료 (장 시간 외) - 재연결 안 함");
                    }
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
            // 1. 구독 확인 메시지(JSON)는 무시
            if (payload.startsWith("{")) return;

            // 2. 포맷 분석
            String[] outer = payload.split("\\|");
            if (outer.length < 4 || !"0".equals(outer[0])) return;
            if (!"H0STCNT0".equals(outer[1])) return;

            String[] fields = outer[3].split("\\^");
            if (fields.length < 10) return;

            // 3. 필드 추출
            String code  = fields[0];
            String price = fields[2];
            String sign  = fields[3];
            String diff  = fields[4];
            String rate  = fields[5];
            String high  = fields[8];
            String low   = fields[9];
            String volume = fields.length > 14 ? fields[14] : "0";

            // 4. 하락 부호 적용
            boolean isDown = "4".equals(sign) || "5".equals(sign);
            if (isDown) {
                if (!diff.startsWith("-")) diff = "-" + diff;
                if (!rate.startsWith("-")) rate = "-" + rate;
            }

            // 5. 데이터 맵 생성
            Map<String, String> data = new HashMap<>();
            data.put("code", code);
            data.put("price", price);
            data.put("rate", rate);
            data.put("diff", diff);
            data.put("high", high);
            data.put("low", low);
            data.put("volume", volume);

            // 6. 캐시 및 메시지 전송
            priceCache.put(code, data);
            messagingTemplate.convertAndSend("/topic/stock/price", data);

            // 💡 [중요] StockService 캐시 업데이트 (API 호출 방지용)
            try {
                long longPrice = Long.parseLong(price.replaceAll("[^0-9.]", ""));
                // 💡 getStockService() 메서드를 사용하여 안전하게 가져옵니다.
                getStockService().updatePrice(code, longPrice); 
            } catch (NumberFormatException e) {
                log.warn("가격 데이터 변환 실패: {}", price);
            }

        } catch (Exception e) {
            log.error("❌ KIS 데이터 파싱 오류: {}", e.getMessage());
        }
    }
}
