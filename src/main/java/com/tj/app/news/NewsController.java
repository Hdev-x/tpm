package com.tj.app.news;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/news")
public class NewsController {

    @Autowired
    private NewsService newsService;

    /**
     * 📰 특정 종목 맞춤형 실시간 뉴스 페치 창구
     * GET /stock/news?keyword=삼성전자
     */
    @GetMapping
    public ResponseEntity<?> getRealtimeNews(@RequestParam(value = "keyword", required = false, defaultValue = "주식") String keyword) {
        log.info("📡 [뉴스 도메인 엔진 가동] 검색어: {}", keyword);

        NewsDTO newsData = newsService.searchStockNews(keyword);

        if (newsData != null && newsData.getItems() != null && !newsData.getItems().isEmpty()) {
            return ResponseEntity.ok(newsData);
        }

        // 🛡️ 뉴스 서버가 통신 불능이거나 응답이 없으면 404 에러와 실패 메시지 리턴
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("message", "네이버 뉴스 인프라 세션 점검 또는 검색 결과가 존재하지 않는 종목명입니다."));
    }
}