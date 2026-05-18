package com.tj.app.news;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import java.time.Duration;

@Slf4j
@Service
public class NewsService {

    @Value("${app.news.clientid}")
    private String naverClientId;

    @Value("${app.news.clientsecret}")
    private String naverClientSecret;

    /**
     * 📰 네이버 뉴스 검색 API 직통 호출 (가상 데이터 0%)
     */
    public NewsDTO searchStockNews(String keyword) {
        try {
            WebClient naverClient = WebClient.builder()
                    .baseUrl("https://openapi.naver.com")
                    .build();

            // 관련도순(sim)으로 최신 뉴스 10건 수급
            return naverClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/v1/search/news.json")
                            .queryParam("query", keyword)
                            .queryParam("display", 10)
                            .queryParam("sort", "sim")
                            .build())
                    .header("X-Naver-Client-Id", naverClientId)
                    .header("X-Naver-Client-Secret", naverClientSecret)
                    .retrieve()
                    .bodyToMono(NewsDTO.class)
                    .block(Duration.ofSeconds(5)); // 5초 타임아웃 가드

        } catch (Exception e) {
            log.error("❌ 네이버 뉴스 수급 실패 [검색어: {}]: {}", keyword, e.getMessage());
            return null; // 실패 시 깔끔하게 null 반환하여 컨트롤러가 에러 제어하게 위임
        }
    }
}