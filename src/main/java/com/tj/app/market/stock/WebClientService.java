package com.tj.app.market.stock;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** ============================================================
 * [클래스 읽기] 한국투자증권(KIS) Open API와 네이버 금융 API를 호출하는 WebClient 서비스.
 *
 * [제공 기능]
 * 1. KIS OAuth2 Access Token 발급·캐싱
 * 2. KIS WebSocket Approval Key 발급·캐싱
 * 3. KIS API: 현재가 조회, 분봉 조회, 일봉 조회
 * 4. 네이버 금융 API: 개별 종목 시세, 코스피 지수 실시간 조회
 *
 * [토큰 캐싱 전략]
 * KIS API는 토큰이 만료되기 전까지 재발급 없이 재사용한다.
 * 만료 10분 전부터 미리 갱신해 API 호출 도중 만료되는 상황을 방지한다.
 * synchronized: 여러 스레드가 동시에 토큰을 갱신하는 중복 발급을 막는다.
 *
 * [생성자 주입]
 * baseUrl을 @Value로 받아 WebClient를 생성자에서 초기화한다.
 * application.properties의 app.stock.baseurl 값이 주입된다.
 * ============================================================ */
@Slf4j
@Service
public class WebClientService {

    private final WebClient webClient;

    // [실행 흐름] 토큰 캐시: null이면 아직 발급 안 됨, 만료시간 10분 이전에 재발급
    private String cachedToken;
    private LocalDateTime tokenExpireTime;
    private String cachedApprovalKey;
    private LocalDateTime approvalKeyExpireTime;

    @Value("${app.stock.appkey}")
    private String appkey;

    @Value("${app.stock.appsecret}")
    private String appsecret;

    /** ============================================================
     * [생성자] KIS API baseUrl을 주입받아 공통 WebClient를 초기화한다.
     * Content-Type: application/json → KIS API 요구사항
     * ============================================================ */
    public WebClientService(@Value("${app.stock.baseurl}") String baseUrl) {
        this.webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Content-Type", "application/json")
                .build();
    }

    /** ============================================================
     * KIS API 공통 인증 헤더를 요청에 추가한다.
     * 모든 KIS API 호출에 Authorization·appkey·appsecret·tr_id·custtype이 필요하다.
     *
     * @param trId KIS API의 거래 ID (API마다 다름, 예: "FHKST01010100")
     * ============================================================ */
    private WebClient.RequestHeadersSpec<?> applyDefaultHeaders(WebClient.RequestHeadersSpec<?> spec, String trId) {
        return spec.header("Authorization", "Bearer " + getAccessToken())
                   .header("appkey", appkey)
                   .header("appsecret", appsecret)
                   .header("tr_id", trId)
                   .header("custtype", "P"); // P = 개인, B = 법인
    }

    /** ============================================================
     * KIS OAuth2 Access Token을 발급하거나 캐시에서 반환한다.
     *
     * [실행 흐름]
     * 1. 캐시된 토큰이 있고 만료 10분 이상 남아있으면 재사용
     * 2. 없거나 만료 임박하면 POST /oauth2/tokenP 로 새 토큰 발급
     * 3. expires_in(초)을 더해 tokenExpireTime 갱신
     * 4. 발급 실패 시 RuntimeException → 이 서비스를 사용하는 모든 API 호출 차단
     *
     * [synchronized] 멀티스레드 환경에서 토큰이 중복 발급되지 않도록 메서드 잠금
     * ============================================================ */
    public synchronized String getAccessToken() {
        // [실행 흐름] 유효한 캐시 토큰이 있으면 재발급 없이 재사용
        if (cachedToken != null && tokenExpireTime != null &&
            tokenExpireTime.isAfter(LocalDateTime.now().plusMinutes(10))) {
            return cachedToken;
        }

        log.info("Access Token 갱신 시작");

        Map<String, String> bodyMap = new HashMap<>();
        bodyMap.put("grant_type", "client_credentials");
        bodyMap.put("appkey", appkey);
        bodyMap.put("appsecret", appsecret);

        try {
            log.info("토큰 요청 전 키 확인: appkey={}, appsecret={}",
                     (appkey != null ? "OK" : "NULL"),
                     (appsecret != null ? "OK" : "NULL"));

            Map<String, Object> response = webClient.post()
                    .uri("/oauth2/tokenP")
                    .bodyValue(bodyMap)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block(Duration.ofSeconds(10));

            if (response != null && response.containsKey("access_token")) {
                this.cachedToken = (String) response.get("access_token");
                int expiresIn = Integer.parseInt(String.valueOf(response.get("expires_in")));
                this.tokenExpireTime = LocalDateTime.now().plusSeconds(expiresIn); // [실행 흐름] 만료 시각 계산
                log.info("새로운 토큰 발급 완료");
                return this.cachedToken;
            } else {
                log.warn("API 응답에 토큰이 없습니다: {}", response);
            }
        } catch (Exception e) {
            log.error("토큰 발급 시도 중 예외 발생: {}", e.getMessage());
        }

        throw new RuntimeException("API 인증 토큰 발급에 실패했습니다. 키 설정을 확인하세요.");
    }

    /** ============================================================
     * KIS WebSocket Approval Key를 발급하거나 캐시에서 반환한다.
     * WebSocket 연결 시 인증에 사용한다. 유효기간 24시간.
     *
     * [Access Token과 차이]
     * Access Token: REST API 인증용, grant_type + appkey + appsecret
     * Approval Key: WebSocket 인증용, grant_type + appkey + secretkey (키명 다름!)
     * ============================================================ */
    public synchronized String getApprovalKey() {
        if (cachedApprovalKey != null && approvalKeyExpireTime != null &&
            approvalKeyExpireTime.isAfter(LocalDateTime.now().plusMinutes(10))) {
            return cachedApprovalKey;
        }

        log.info("WebSocket Approval Key 발급 시작");

        Map<String, String> bodyMap = new HashMap<>();
        bodyMap.put("grant_type", "client_credentials");
        bodyMap.put("appkey", appkey);
        bodyMap.put("secretkey", appsecret); // [주의] Access Token은 "appsecret", 여기는 "secretkey"

        try {
            Map<String, Object> response = webClient.post()
                    .uri("/oauth2/Approval")
                    .bodyValue(bodyMap)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block(Duration.ofSeconds(10));

            if (response != null && response.containsKey("approval_key")) {
                this.cachedApprovalKey = (String) response.get("approval_key");
                this.approvalKeyExpireTime = LocalDateTime.now().plusHours(24);
                log.info("Approval Key 발급 완료");
                return this.cachedApprovalKey;
            }
        } catch (Exception e) {
            log.error("Approval Key 발급 실패: {}", e.getMessage());
        }

        throw new RuntimeException("WebSocket Approval Key 발급 실패");
    }

    /** ============================================================
     * KIS API로 종목 현재가를 조회한다.
     *
     * tr_id "FHKST01010100" = 주식 현재가 조회
     * FID_COND_MRKT_DIV_CODE "J" = 장내(코스피·코스닥)
     * 응답을 StockPriceDTO로 역직렬화한다.
     * ============================================================ */
    public StockPriceDTO getCurrentPrice(String stockCode) {
        try {
            WebClient.RequestHeadersSpec<?> request = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/uapi/domestic-stock/v1/quotations/inquire-price")
                            .queryParam("FID_COND_MRKT_DIV_CODE", "J")
                            .queryParam("FID_INPUT_ISCD", stockCode)
                            .build());

            return applyDefaultHeaders(request, "FHKST01010100")
                    .retrieve()
                    .bodyToMono(StockPriceDTO.class)
                    .block(Duration.ofSeconds(10));
        } catch (Exception e) {
            log.error("현재가 조회 중 오류 [{}]: {}", stockCode, e.getMessage());
            return null;
        }
    }

    /** ============================================================
     * KIS API로 분봉 데이터를 조회한다.
     *
     * tr_id "FHKST03010200" = 주식 분봉 조회
     * FID_PW_DATA_INCU_YN "Y" = 장전/후 데이터 포함
     * FID_PW_DATA_IN_YN "N" = 연장 시간 데이터 미포함
     * ============================================================ */
    public StockChartDTO getMinuteChart(String stockCode) {
        try {
            WebClient.RequestHeadersSpec<?> request = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/uapi/domestic-stock/v1/quotations/inquire-time-itemchartprice")
                            .queryParam("FID_ETC_CLS_CODE", "")
                            .queryParam("FID_COND_MRKT_DIV_CODE", "J")
                            .queryParam("FID_INPUT_ISCD", stockCode)
                            .queryParam("FID_PW_DATA_INCU_YN", "Y")
                            .queryParam("FID_PW_DATA_IN_YN", "N")
                            .build());

            return applyDefaultHeaders(request, "FHKST03010200")
                    .retrieve()
                    .bodyToMono(StockChartDTO.class)
                    .block(Duration.ofSeconds(10));

        } catch (WebClientResponseException e) {
            log.error("분봉 API 에러: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
            return null;
        } catch (Exception e) {
            log.error("분봉 조회 중 오류: {}", e.getMessage());
            return null;
        }
    }

    /** ============================================================
     * KIS API로 일봉·주봉·월봉 데이터를 조회한다.
     *
     * tr_id "FHKST03010100" = 주식 기간별 시세 조회
     * FID_PERIOD_DIV_CODE: "D"=일봉, "W"=주봉, "M"=월봉 (timeframe 파라미터로 전달)
     * FID_ORG_ADJ_PRC "0" = 수정주가 미반영 원주가 사용
     * ============================================================ */
    public StockChartDTO getDailyChart(String stockCode, String startDate, String endDate, String timeframe) {
        try {
            WebClient.RequestHeadersSpec<?> request = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/uapi/domestic-stock/v1/quotations/inquire-daily-itemchartprice")
                            .queryParam("FID_COND_MRKT_DIV_CODE", "J")
                            .queryParam("FID_INPUT_ISCD", stockCode)
                            .queryParam("FID_INPUT_DATE_1", startDate)
                            .queryParam("FID_INPUT_DATE_2", endDate)
                            .queryParam("FID_PERIOD_DIV_CODE", timeframe) // "D", "W", "M"
                            .queryParam("FID_ORG_ADJ_PRC", "0")
                            .queryParam("FID_PW_DATA_IN_YN", "Y")
                            .build());

            return applyDefaultHeaders(request, "FHKST03010100")
                    .retrieve()
                    .bodyToMono(StockChartDTO.class)
                    .block(Duration.ofSeconds(10));

        } catch (WebClientResponseException e) {
            log.error("차트 API 에러 (Timeframe: {}): {} - {}", timeframe, e.getStatusCode(), e.getResponseBodyAsString());
            return null;
        } catch (Exception e) {
            log.error("차트 조회 중 예외 발생: {}", e.getMessage());
            return null;
        }
    }

    /** ============================================================
     * 네이버 금융에서 개별 종목 시세(현재가·등락률·등락폭)를 조회한다.
     *
     * [실행 흐름]
     * 1. 네이버 realtime API에서 result.areas[0].datas[0] 파싱
     * 2. nv=현재가, cr=등락률(절대값), sv=등락폭(절대값)
     * 3. rf(Rise & Fall) 플래그: 4=하한, 5=하락 → 음수 부호 추가
     *    [이유] 네이버는 cr·sv를 항상 양수로 내려주고, rf로 방향을 별도 표시
     *
     * @return { price, rate, diff } Map. 실패 시 빈 Map
     * ============================================================ */
    public Map<String, String> getStockPriceFromNaver(String code) {
        Map<String, String> resultMap = new HashMap<>();
        try {
            WebClient naverClient = WebClient.builder()
                    .baseUrl("https://polling.finance.naver.com")
                    .build();

            String jsonString = naverClient.get()
                    .uri("/api/realtime?query=SERVICE_ITEM:" + code)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block(Duration.ofSeconds(3));

            if (jsonString != null && !jsonString.isEmpty()) {
                com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                Map<String, Object> response = mapper.readValue(jsonString, Map.class);

                if (response != null && response.containsKey("result")) {
                    Map<String, Object> result = (Map<String, Object>) response.get("result");
                    if (result != null && result.containsKey("areas")) {
                        List<Map<String, Object>> areas = (List) result.get("areas");
                        if (areas != null && !areas.isEmpty()) {
                            List<Map<String, Object>> datas = (List<Map<String, Object>>) areas.get(0).get("datas");
                            if (datas != null && !datas.isEmpty()) {
                                Map<String, Object> data = datas.get(0);

                                // [실행 흐름] 네이버는 cr·sv를 절대값(양수)으로만 반환
                                String price = String.valueOf(data.getOrDefault("nv", "-"));
                                String rate  = String.valueOf(data.getOrDefault("cr", "-"));
                                String diff  = String.valueOf(data.getOrDefault("sv", "-"));

                                // rf: 1=상한가, 2=상승, 3=보합, 4=하한가, 5=하락
                                String rf = String.valueOf(data.getOrDefault("rf", "3"));

                                // [실행 흐름] 하락(4, 5)이면 rate·diff에 "-" 부호 추가
                                if ("4".equals(rf) || "5".equals(rf)) {
                                    if (!"-".equals(rate) && !rate.startsWith("-")) rate = "-" + rate;
                                    if (!"-".equals(diff) && !diff.startsWith("-")) diff = "-" + diff;
                                }

                                resultMap.put("price", price);
                                resultMap.put("rate",  rate);
                                resultMap.put("diff",  diff);
                                return resultMap;
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.error("네이버 개별 종목 시세 조회 실패 [{}]: {}", code, e.getMessage());
        }
        return resultMap;
    }

    /** ============================================================
     * 네이버 금융에서 코스피 실시간 지수를 조회한다.
     * StockService.refreshTop100()에서 15초마다 호출된다.
     *
     * [실행 흐름]
     * SERVICE_INDEX:KOSPI 쿼리로 코스피 종합지수 단건 조회
     * nv = 현재 지수값, cr = 등락률
     *
     * [실패 처리] 통신 장애 시 가짜 값을 만들지 않고 빈 Map 반환.
     * 호출한 StockService에서 빈 Map을 확인하고 캐시 갱신을 건너뛴다.
     * ============================================================ */
    public Map<String, String> getRealtimeKospiFromNaver() {
        Map<String, String> resultMap = new HashMap<>();
        try {
            WebClient naverClient = WebClient.builder()
                    .baseUrl("https://polling.finance.naver.com")
                    .build();

            // [실행 흐름] Jackson 파싱 오류 방지용으로 String으로 먼저 수신 후 수동 파싱
            String jsonString = naverClient.get()
                    .uri("/api/realtime?query=SERVICE_INDEX:KOSPI")
                    .retrieve()
                    .bodyToMono(String.class)
                    .block(Duration.ofSeconds(3));

            if (jsonString != null && !jsonString.isEmpty()) {
                com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                Map<String, Object> response = mapper.readValue(jsonString, Map.class);

                if (response != null && response.containsKey("result")) {
                    Map<String, Object> result = (Map<String, Object>) response.get("result");
                    if (result != null && result.containsKey("areas")) {
                        List<Map<String, Object>> areas = (List) result.get("areas");
                        if (areas != null && !areas.isEmpty()) {
                            List<Map<String, Object>> datas = (List<Map<String, Object>>) areas.get(0).get("datas");
                            if (datas != null && !datas.isEmpty()) {
                                Map<String, Object> realTimeData = datas.get(0);
                                resultMap.put("price", String.valueOf(realTimeData.get("nv"))); // 현재 지수
                                resultMap.put("rate",  String.valueOf(realTimeData.get("cr"))); // 등락률
                                return resultMap;
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.error("네이버 금융 코스피 실시간 조회 실패: {}", e.getMessage());
        }

        // [실행 흐름] 실패 시 빈 Map 반환 → StockService가 실패를 인지하고 캐시 유지
        return resultMap;
    }
}