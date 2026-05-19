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

@Slf4j
@Service
public class WebClientService {

    private final WebClient webClient;
    private String cachedToken;
    private LocalDateTime tokenExpireTime;

    @Value("${app.stock.appkey}")
    private String appkey;

    @Value("${app.stock.appsecret}")
    private String appsecret;

    public WebClientService(@Value("${app.stock.baseurl}") String baseUrl) {
        this.webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Content-Type", "application/json")
                .build();
    }

    /**
     * 공통 헤더 설정 (중복 제거용)
     */
    private WebClient.RequestHeadersSpec<?> applyDefaultHeaders(WebClient.RequestHeadersSpec<?> spec, String trId) {
        return spec.header("Authorization", "Bearer " + getAccessToken())
                   .header("appkey", appkey)
                   .header("appsecret", appsecret)
                   .header("tr_id", trId)
                   .header("custtype", "P");
    }

    /**
     * 1. 한국투자증권 토큰 발급 및 캐싱
     */
    public synchronized String getAccessToken() {
        if (cachedToken != null && tokenExpireTime != null && 
            tokenExpireTime.isAfter(LocalDateTime.now().plusMinutes(10))) {
            return cachedToken;
        }

        log.info("🔐 Access Token 갱신을 시작합니다.");

        Map<String, String> bodyMap = new HashMap<>();
        bodyMap.put("grant_type", "client_credentials");
        bodyMap.put("appkey", appkey);
        bodyMap.put("appsecret", appsecret);

        try {
            log.info("📡 토큰 요청 전 키 확인: appkey={}, appsecret={}", 
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
                this.tokenExpireTime = LocalDateTime.now().plusSeconds(expiresIn);
                
                log.info("✅ 새로운 토큰 발급 완료");
                return this.cachedToken;
            } else {
                log.warn("⚠️ API 응답에 토큰이 없습니다: {}", response);
            }
        } catch (Exception e) {
            log.error("❌ 토큰 발급 시도 중 예외 발생: {}", e.getMessage());
        }

        throw new RuntimeException("API 인증 토큰 발급에 실패했습니다. 키 설정을 확인하세요.");
    }

    /**
     * 2. 현재가 조회
     */
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
            log.error("❌ 현재가 조회 중 오류 [{}]: {}", stockCode, e.getMessage());
            return null;
        }
    }

    /**
     * 3. 분봉 데이터 조회
     */
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
            log.error("❌ 분봉 API 에러: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
            return null;
        } catch (Exception e) {
            log.error("❌ 분봉 조회 중 오류: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 4. 일봉 데이터 조회
     */
    public StockChartDTO getDailyChart(String stockCode, String startDate, String endDate, String timeframe) {
        try {
            WebClient.RequestHeadersSpec<?> request = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/uapi/domestic-stock/v1/quotations/inquire-daily-itemchartprice")
                            .queryParam("FID_COND_MRKT_DIV_CODE", "J")
                            .queryParam("FID_INPUT_ISCD", stockCode)
                            .queryParam("FID_INPUT_DATE_1", startDate)
                            .queryParam("FID_INPUT_DATE_2", endDate)
                            .queryParam("FID_PERIOD_DIV_CODE", timeframe)
                            .queryParam("FID_ORG_ADJ_PRC", "0")
                            .queryParam("FID_PW_DATA_IN_YN", "Y") 
                            .build());

            return applyDefaultHeaders(request, "FHKST03010100") 
                    .retrieve()
                    .bodyToMono(StockChartDTO.class)
                    .block(Duration.ofSeconds(10));

        } catch (WebClientResponseException e) {
            log.error("❌ 차트 API 에러 (Timeframe: {}): {} - {}", timeframe, e.getStatusCode(), e.getResponseBodyAsString());
            return null;
        } catch (Exception e) {
            log.error("❌ 차트 조회 중 예외 발생: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 5. 업종별 종목 시세(KOSPI 전체 리스트) 조회
     */
    public StockListDTO getFullMarketPrices() {
        try {
            WebClient.RequestHeadersSpec<?> request = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/uapi/domestic-stock/v1/quotations/inquire-index-category-stock")
                            .queryParam("FID_COND_MRKT_DIV_CODE", "J") 
                            .queryParam("FID_INPUT_ISCD", "0001")      
                            .build());

            return applyDefaultHeaders(request, "FHPK13010000") 
                    .retrieve()
                    .bodyToMono(StockListDTO.class)
                    .block(Duration.ofSeconds(10));
        } catch (Exception e) {
            log.error("❌ 다건 시세 조회 중 오류: {}", e.getMessage());
            return null;
        }
    }
    
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
                                resultMap.put("price", String.valueOf(data.getOrDefault("nv", "-")));
                                resultMap.put("rate",  String.valueOf(data.getOrDefault("cr", "-")));
                                resultMap.put("diff",  String.valueOf(data.getOrDefault("sv", "-")));
                                return resultMap;
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.error("❌ 네이버 개별 종목 시세 조회 실패 [{}]: {}", code, e.getMessage());
        }
        return resultMap;
    }

    public Map<String, String> getRealtimeKospiFromNaver() {
        Map<String, String> resultMap = new HashMap<>();
        try {
            // 네이버 금융 폴링 서버 전용 비동기 클라이언트 즉석 빌드
            WebClient naverClient = WebClient.builder()
                    .baseUrl("https://polling.finance.naver.com")
                    .build();

            // Jackson Jackson 파싱 에러(Type Mismatch)를 방지하기 위해 String으로 통째로 수급
            String jsonString = naverClient.get()
                    .uri("/api/realtime?query=SERVICE_INDEX:KOSPI")
                    .retrieve()
                    .bodyToMono(String.class)
                    .block(Duration.ofSeconds(3)); // 3초 타임아웃 가드

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
                                
                                // nv: 현재 지수 평점, cr: 전일대비 등락율 변동선
                                String livePrice = String.valueOf(realTimeData.get("nv"));
                                String liveRate = String.valueOf(realTimeData.get("cr"));

                                resultMap.put("price", livePrice);
                                resultMap.put("rate", liveRate);
                                return resultMap; // 매핑 성공 시 실시간 데이터 즉시 반환
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.error("❌ 네이버 금융 실시간 지수 파이프라인 가로채기 실패: {}", e.getMessage());
        }
        
        // 🛡️ [가상 데이터 영구 퇴출] 통신 장해나 점검 시 가짜 데이터를 지어내지 않고, 
        // 상위 서비스(StockService)가 실패를 인지할 수 있도록 온전한 빈 맵(Empty Map)을 리턴합니다.
        return resultMap;
    }
    
    
    
}