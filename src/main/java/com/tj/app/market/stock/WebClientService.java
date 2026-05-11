package com.tj.app.market.stock;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.time.Duration;
import java.time.LocalDateTime;
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

        Map<String, String> bodyMap = Map.of(
                "grant_type", "client_credentials",
                "appkey", appkey,
                "appsecret", appsecret
        );

        try {
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
            }
        } catch (Exception e) {
            log.error("❌ 토큰 발급 실패: {}", e.getMessage());
        }

        throw new RuntimeException("API 인증 토큰 발급에 실패했습니다.");
    }

    /**
     * 2. 분봉 데이터 조회
     */
    public StockChartDTO getMinuteChart(String stockCode) {
        try {
            WebClient.RequestHeadersSpec<?> request = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/uapi/domestic-stock/v1/quotations/inquire-time-itemchartprice")
                            .queryParam("FID_ETC_CLS_CODE", "")
                            .queryParam("FID_COND_MRKT_DIV_CODE", "J")
                            .queryParam("FID_INPUT_ISCD", stockCode)
                            .queryParam("FID_HOUR_CLS_CODE", "1")
                            .queryParam("FID_PW_DATA_IN_YN", "Y")
                            .build());

            return applyDefaultHeaders(request, "VHKST03010200") // TR ID 적용
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
     * 3. 일봉 데이터 조회
     */
    public StockChartDTO getDailyChart(String stockCode, String startDate, String endDate) {
        try {
            WebClient.RequestHeadersSpec<?> request = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/uapi/domestic-stock/v1/quotations/inquire-daily-itemchartprice")
                            .queryParam("FID_COND_MRKT_DIV_CODE", "J")
                            .queryParam("FID_INPUT_ISCD", stockCode)
                            .queryParam("FID_INPUT_DATE_1", startDate)
                            .queryParam("FID_INPUT_DATE_2", endDate)
                            .queryParam("FID_PERIOD_DIV_CODE", "D")
                            .queryParam("FID_ORG_ADJ_PRC", "0")
                            .build());

            return applyDefaultHeaders(request, "VHKST03010100") // TR ID 적용
                    .retrieve()
                    .bodyToMono(StockChartDTO.class)
                    .block(Duration.ofSeconds(10));

        } catch (WebClientResponseException e) {
            log.error("❌ 일봉 API 에러: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
            return null;
        } catch (Exception e) {
            log.error("❌ 일봉 조회 중 오류: {}", e.getMessage());
            return null;
        }
    }
}