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

/** ============================================================
 * [클래스 읽기] KIS(한국투자증권) 실시간 WebSocket에 연결해
 * 종목별 체결 시세를 수신·파싱·브로드캐스트하는 서비스.
 *
 * [전체 흐름]
 * connect() → KIS WebSocket(ws://ops.koreainvestment.com:31000) 연결
 *           → 상위 40개 종목 구독(H0STCNT0)
 *           → 체결 메시지 수신 → parseAndBroadcast()
 *           → STOMP /topic/stock/price 로 브로드캐스트
 *           → 클라이언트 JS에서 구독해 화면 업데이트
 *
 * [장 시간 연결 관리]
 * @Scheduled: 평일 09:00 자동 연결, 15:35 자동 종료
 * afterConnectionClosed: 장 시간 중 끊기면 3초 후 자동 재연결
 *
 * [순환 의존성 해결]
 * KisWebSocketService ↔ StockService 상호 참조 문제를
 * ObjectProvider<StockService>로 지연 조회하여 해결한다.
 * (생성자에서 즉시 주입하면 순환 의존성 오류 발생)
 * ============================================================ */
@Slf4j
@Service
public class KisWebSocketService {

    // [실행 흐름] ObjectProvider: getObject() 호출 시점에 빈을 조회 → 순환 참조 방지
    private final ObjectProvider<StockService> stockServiceProvider;

    public KisWebSocketService(ObjectProvider<StockService> stockServiceProvider) {
        this.stockServiceProvider = stockServiceProvider;
    }

    private StockService getStockService() {
        return stockServiceProvider.getObject();
    }

    @Autowired
    private WebClientService webClientService;

    // [실행 흐름] SimpMessagingTemplate: STOMP 채널로 메시지를 브로드캐스트하는 Spring 유틸리티
    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private StockJoinMapper stockJoinMapper;

    @Value("${app.stock.websocket.enabled:false}")
    private boolean stockWebSocketEnabled;

    private final ObjectMapper objectMapper = new ObjectMapper();

    // [실행 흐름] volatile: 여러 스레드에서 currentSession을 읽을 때 최신 값을 보장
    private volatile WebSocketSession currentSession;

    private static final ZoneId KST          = ZoneId.of("Asia/Seoul");
    private static final LocalTime MARKET_OPEN  = LocalTime.of(9, 0);
    private static final LocalTime MARKET_CLOSE = LocalTime.of(15, 35);

    // [실행 흐름] 종목코드 → 최신 시세(price/rate/diff/high/low) 캐시
    private final Map<String, Map<String, String>> priceCache = new ConcurrentHashMap<>();
    // [실행 흐름] 종목코드 → 종목명 캐시 (WebSocket 수신 데이터에 이름이 없으므로 별도 저장)
    private final Map<String, String> nameCache = new ConcurrentHashMap<>();

    public Map<String, Map<String, String>> getPriceCache() { return priceCache; }
    public Map<String, String> getNameCache() { return nameCache; }

    /** ============================================================
     * 현재 장 시간(평일 09:00~15:35)인지 확인한다.
     * 연결 끊김 시 재연결 여부를 판단하는 데 사용한다.
     * ============================================================ */
    private boolean isMarketHours() {
        ZonedDateTime now = ZonedDateTime.now(KST);
        DayOfWeek day = now.getDayOfWeek();
        if (day == DayOfWeek.SATURDAY || day == DayOfWeek.SUNDAY) return false;
        LocalTime time = now.toLocalTime();
        return !time.isBefore(MARKET_OPEN) && !time.isAfter(MARKET_CLOSE);
    }

    /** ============================================================
     * 평일 09:00에 WebSocket 연결을 자동으로 시작한다.
     * ============================================================ */
    @Scheduled(cron = "0 0 9 * * MON-FRI", zone = "Asia/Seoul")
    public void connectOnMarketOpen() {
        log.info("장 시작 - KIS WebSocket 연결 시도");
        connect();
    }

    /** ============================================================
     * 평일 15:35에 WebSocket 연결을 자동으로 종료한다.
     * ============================================================ */
    @Scheduled(cron = "0 35 15 * * MON-FRI", zone = "Asia/Seoul")
    public void disconnectOnMarketClose() {
        log.info("장 마감 - KIS WebSocket 연결 종료");
        disconnect();
    }

    /** ============================================================
     * 현재 WebSocket 세션을 닫는다.
     * ============================================================ */
    public void disconnect() {
        if (currentSession != null && currentSession.isOpen()) {
            try {
                currentSession.close();
            } catch (Exception e) {
                log.warn("KIS WebSocket 종료 중 오류: {}", e.getMessage());
            }
        }
    }

    /** ============================================================
     * KIS WebSocket에 연결하고 상위 40개 종목을 구독한다.
     *
     * [실행 흐름]
     * 1. Approval Key 발급 (WebClientService에서 캐시된 키 재사용)
     * 2. DB에서 상위 40개 종목 코드 조회
     * 3. WebSocketContainer 생성 → StandardWebSocketClient로 연결
     * 4. afterConnectionEstablished: 연결 성공 시 종목별 subscribe() 호출
     * 5. handleTextMessage: 체결 메시지 수신 시 parseAndBroadcast() 호출
     * 6. afterConnectionClosed: 장 시간 중 끊기면 3초 후 재연결
     * ============================================================ */
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
                log.warn("DB 조회 실패로 KIS WebSocket 연결 중단: {}", dbEx.getMessage());
                return;
            }

            List<String> codes = stocks.stream()
                    .map(s -> (String) s.get("code"))
                    .toList();

            // [실행 흐름] 종목명 캐시 초기화 (수신 데이터에 이름이 없으므로 미리 저장)
            stocks.forEach(s -> nameCache.put((String) s.get("code"), (String) s.get("name")));

            // [실행 흐름] 버퍼 크기 1MB로 설정 → 대량 메시지 수신 시 버퍼 초과 방지
            WebSocketContainer container = ContainerProvider.getWebSocketContainer();
            container.setDefaultMaxTextMessageBufferSize(1024 * 1024);
            container.setDefaultMaxBinaryMessageBufferSize(1024 * 1024);

            StandardWebSocketClient client = new StandardWebSocketClient(container);
            URI uri = URI.create("ws://ops.koreainvestment.com:31000");

            client.execute(new AbstractWebSocketHandler() {

                @Override
                public void afterConnectionEstablished(WebSocketSession session) throws Exception {
                    currentSession = session;
                    log.info("KIS WebSocket 연결 성공");
                    for (String code : codes) {
                        subscribe(session, approvalKey, code);
                        Thread.sleep(50); // [실행 흐름] 구독 요청 간격 딜레이 (너무 빠르면 누락됨)
                    }
                    log.info("{}개 종목 구독 완료", codes.size());
                }

                @Override
                protected void handleTextMessage(WebSocketSession session, TextMessage message) {
                    parseAndBroadcast(message.getPayload()); // [실행 흐름] 체결 메시지 파싱·브로드캐스트
                }

                @Override
                public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
                    if (isMarketHours()) {
                        // [실행 흐름] 장 시간 중 끊기면 3초 후 재연결 시도
                        log.warn("KIS WebSocket 연결 끊김 ({}), 3초 후 재연결", status);
                        new Thread(() -> {
                            try {
                                Thread.sleep(3000);
                                if (stockWebSocketEnabled) connect();
                            } catch (InterruptedException ignored) {}
                        }).start();
                    } else {
                        log.info("KIS WebSocket 연결 종료 (장 시간 외) - 재연결 안 함");
                    }
                }

            }, new WebSocketHttpHeaders(), uri);

        } catch (Exception e) {
            log.error("KIS WebSocket 연결 실패: {}", e.getMessage());
        }
    }

    /** ============================================================
     * 특정 종목을 KIS WebSocket 실시간 체결 채널에 구독한다.
     *
     * [메시지 구조]
     * { "header": { approval_key, custtype, tr_type: "1", content-type },
     *   "body":   { "input": { tr_id: "H0STCNT0", tr_key: 종목코드 } } }
     *
     * tr_id "H0STCNT0" = 실시간 체결가 구독
     * tr_type "1" = 구독 등록 (반대로 "2"면 해제)
     * ============================================================ */
    private void subscribe(WebSocketSession session, String approvalKey, String code) throws Exception {
        Map<String, Object> msg = new HashMap<>();
        msg.put("header", Map.of(
                "approval_key", approvalKey,
                "custtype", "P",
                "tr_type", "1",       // 1 = 구독 등록
                "content-type", "utf-8"
        ));
        msg.put("body", Map.of(
                "input", Map.of(
                        "tr_id", "H0STCNT0", // 실시간 체결 tr_id
                        "tr_key", code        // 구독할 종목 코드
                )
        ));
        session.sendMessage(new TextMessage(objectMapper.writeValueAsString(msg)));
    }

    /** ============================================================
     * KIS WebSocket에서 수신한 메시지를 파싱하고 STOMP 채널로 브로드캐스트한다.
     *
     * [KIS 실시간 메시지 형식]
     * JSON({"header":{...}}) : 구독 확인 메시지 → 무시
     * 파이프 구분 문자열: 0|H0STCNT0|001|{^로 분리된 필드들}
     *   outer[0]: "0" = 정상 데이터
     *   outer[1]: tr_id ("H0STCNT0")
     *   outer[3]: 실제 필드 데이터 (^ 구분)
     *
     * [fields 인덱스]
     * [0]=종목코드, [2]=현재가, [3]=부호(상승/하락), [4]=등락폭,
     * [5]=등락률, [8]=고가, [9]=저가, [14]=거래량
     * ============================================================ */
    private void parseAndBroadcast(String payload) {
        try {
            // [실행 흐름] JSON으로 시작하면 구독 확인 메시지 → 무시
            if (payload.startsWith("{")) return;

            // [실행 흐름] "|"로 분리하여 외부 구조 파악
            String[] outer = payload.split("\\|");
            if (outer.length < 4 || !"0".equals(outer[0])) return;
            if (!"H0STCNT0".equals(outer[1])) return; // 체결 데이터만 처리

            // [실행 흐름] "^"로 분리하여 개별 필드 추출
            String[] fields = outer[3].split("\\^");
            if (fields.length < 10) return;

            String code   = fields[0];
            String price  = fields[2];
            String sign   = fields[3]; // 1=상한, 2=상승, 3=보합, 4=하한, 5=하락
            String diff   = fields[4]; // 등락폭 (절대값)
            String rate   = fields[5]; // 등락률 (절대값)
            String high   = fields[8];
            String low    = fields[9];
            String volume = fields.length > 14 ? fields[14] : "0";

            // [실행 흐름] 하락(4, 5)이면 부호 추가
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

            // [실행 흐름] 시세 캐시 저장 + STOMP /topic/stock/price 로 브로드캐스트
            priceCache.put(code, data);
            messagingTemplate.convertAndSend("/topic/stock/price", data);

            // [실행 흐름] StockService.latestPriceMap 업데이트 → REST API 조회 캐시 동기화
            try {
                long longPrice = Long.parseLong(price.replaceAll("[^0-9.]", ""));
                getStockService().updatePrice(code, longPrice);
            } catch (NumberFormatException e) {
                log.warn("가격 데이터 변환 실패: {}", price);
            }

        } catch (Exception e) {
            log.error("KIS 데이터 파싱 오류: {}", e.getMessage());
        }
    }
}
