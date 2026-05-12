package com.tj.app.market.stock;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;
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

        // Map.of 대신 HashMap 사용 (null 방어)
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
            e.printStackTrace(); // 콘솔에서 상세 에러 원인 확인용
        }

        throw new RuntimeException("API 인증 토큰 발급에 실패했습니다. 키 설정을 확인하세요.");
    }

    /**
     * 2. 현재가 조회 추가
     */
    public StockPriceDTO getCurrentPrice(String stockCode) {
        try {
            WebClient.RequestHeadersSpec<?> request = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/uapi/domestic-stock/v1/quotations/inquire-price")
                            .queryParam("FID_COND_MRKT_DIV_CODE", "J")
                            .queryParam("FID_INPUT_ISCD", stockCode)
                            .build());

            return applyDefaultHeaders(request, "FHKST01010100") // 현재가 조회 TR ID
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
                            .queryParam("FID_PW_DATA_INCU_YN", "Y") // 👈 당일 데이터 포함 여부 (Y 추천)
                            .queryParam("FID_PW_DATA_IN_YN", "N")   // 👈 연속조회 여부
                            .build());

            // 모의투자용 분봉 TR ID: FHKST03010200
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
                            // 👈 매우 중요: 과거 데이터를 최대한 포함해서 가져오도록 'Y' 설정
                            .queryParam("FID_PW_DATA_IN_YN", "Y") 
                            .build());

            // 모의투자용 일/주/월봉 TR ID: FHKST03010100
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
}