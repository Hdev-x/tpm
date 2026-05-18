package com.tj.app.news;

import lombok.Data;
import java.util.List;

@Data
public class NewsDTO {
    private String lastBuildDate;
    private int total;
    private int start;
    private int display;
    private List<NewsItem> items; // 뉴스 기사 리스트

    @Data
    public static class NewsItem {
        private String title;        // 뉴스 제목 (<b>태그 포함됨)
        private String originallink; // 언론사 원문 링크
        private String link;         // 네이버 뉴스 링크
        private String description;  // 뉴스 본문 요약 (<b>태그 포함됨)
        private String pubDate;      // 게시 일자
    }
}