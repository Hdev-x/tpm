package com.tj.app.news;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

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
        return searchStockNews(keyword, 1);
    }

    public NewsDTO searchStockNews(String keyword, int start) {
        try {
            WebClient naverClient = WebClient.builder()
                    .baseUrl("https://openapi.naver.com")
                    .build();

            NewsDTO result = naverClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/v1/search/news.json")
                            .queryParam("query", keyword)
                            .queryParam("display", 30) // 중복 제거 후 15개 확보를 위해 여유있게 요청
                            .queryParam("start", start)
                            .queryParam("sort", "sim")
                            .build())
                    .header("X-Naver-Client-Id", naverClientId)
                    .header("X-Naver-Client-Secret", naverClientSecret)
                    .retrieve()
                    .bodyToMono(NewsDTO.class)
                    .block(Duration.ofSeconds(5));

            if (result != null && result.getItems() != null) {
                result.setItems(deduplicateByTitle(result.getItems(), 15));
            }
            return result;

        } catch (Exception e) {
            log.error("❌ 네이버 뉴스 수급 실패 [검색어: {}]: {}", keyword, e.getMessage());
            return null;
        }
    }

    // 제목 앞 25자 기준으로 중복 제거 후 limit개 반환
    private List<NewsDTO.NewsItem> deduplicateByTitle(List<NewsDTO.NewsItem> items, int limit) {
        Set<String> seen = new HashSet<>();
        List<NewsDTO.NewsItem> unique = new ArrayList<>();
        for (NewsDTO.NewsItem item : items) {
            String key = item.getTitle()
                    .replaceAll("<[^>]+>", "") // HTML 태그 제거
                    .replaceAll("\\s+", " ")
                    .trim();
            key = key.length() > 25 ? key.substring(0, 25) : key;
            if (seen.add(key)) {
                unique.add(item);
                if (unique.size() == limit) break;
            }
        }
        return unique;
    }
}