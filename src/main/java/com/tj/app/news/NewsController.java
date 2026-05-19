package com.tj.app.news;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@Controller
@RequestMapping("/news") 
public class NewsController {

    @Autowired
    private NewsService newsService;

    @ResponseBody 
    @GetMapping("")
    public ResponseEntity<?> getRealtimeNews(@RequestParam(value = "keyword", required = false, defaultValue = "주식") String keyword) {
        log.info("📡 [뉴스 도메인 엔진 가동] 검색어: {}", keyword);

        NewsDTO newsData = newsService.searchStockNews(keyword);

        if (newsData != null && newsData.getItems() != null && !newsData.getItems().isEmpty()) {
            return ResponseEntity.ok(newsData);
        }

        log.warn("⚠️ [{}] 뉴스 데이터가 비어있어 빈 규격 객체를 반환합니다.", keyword);
        return ResponseEntity.ok(Map.of(
            "items", List.of(), 
            "message", "검색 결과가 존재하지 않는 종목명입니다."
        ));
    }
    
   
    @GetMapping("/list")
    public String openNewsRoomPage() {
        return "news/list";
    }
}