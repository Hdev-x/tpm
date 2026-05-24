package com.tj.app.news;

import lombok.Data;
import java.util.List;

/** ============================================================
 * [클래스 읽기] 네이버 뉴스 검색 API 응답을 담는 DTO.
 *
 * 네이버 뉴스 검색 API (GET /v1/search/news.json) 응답 구조와 1:1 대응한다.
 * Jackson이 JSON 응답을 이 클래스로 자동으로 역직렬화한다.
 *
 * [네이버 뉴스 API 응답 예시]
 * {
 *   "lastBuildDate": "...",
 *   "total": 1234,
 *   "start": 1,
 *   "display": 30,
 *   "items": [
 *     { "title": "삼성전자 <b>주가</b>...", "link": "...", "pubDate": "..." },
 *     ...
 *   ]
 * }
 *
 * [@Data] @Getter + @Setter + @ToString + @EqualsAndHashCode + @RequiredArgsConstructor
 *   Jackson 역직렬화 시 setter가 필요하므로 @Data(또는 @Setter)가 필수다.
 *
 * [중첩 static class NewsItem]
 *   items 배열의 각 기사 한 건을 담는 내부 DTO.
 *   static이므로 외부 클래스 인스턴스 없이도 사용할 수 있다.
 * ============================================================ */
@Data
public class NewsDTO {

    private String lastBuildDate; // API 응답 생성 시각
    private int total;            // 검색어에 매칭된 전체 뉴스 수
    private int start;            // 페이징 시작 위치 (1부터 시작)
    private int display;          // 이번 응답에 포함된 뉴스 수

    /** 뉴스 기사 리스트. NewsService에서 중복 제거 후 최대 15건으로 축소된다. */
    private List<NewsItem> items;

    /** ============================================================
     * [내부 클래스 읽기] 뉴스 기사 한 건을 담는 DTO.
     *
     * [title, description의 HTML 태그]
     *   네이버 API는 검색 키워드를 <b>태그로 강조해 반환한다.
     *   예: "삼성전자 <b>주가</b> 상승..."
     *   NewsService.deduplicateByTitle()에서 중복 제거 시 태그를 제거하고,
     *   JSP에서 화면 출력 시에도 태그 처리가 필요하다.
     * ============================================================ */
    @Data
    public static class NewsItem {
        private String title;        // 뉴스 제목 (<b>태그로 키워드 강조됨)
        private String originallink; // 언론사 원문 링크 (외부 사이트)
        private String link;         // 네이버 뉴스 링크 (네이버 뷰어로 열림)
        private String description;  // 뉴스 본문 요약 (<b>태그 포함)
        private String pubDate;      // 게시 일자 (RFC 2822 형식: "Mon, 01 Jan 2024 12:00:00 +0900")
    }
}
