package com.tj.app.news;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** ============================================================
 * [클래스 읽기] 뉴스 검색 API 요청과 뉴스 목록 페이지 이동을 처리하는 컨트롤러.
 *
 * [@Slf4j] Lombok이 log 필드를 자동 생성한다.
 *
 * [@Controller + @RequestMapping("/news")]
 *   /news 경로로 들어오는 요청을 처리한다.
 *   @ResponseBody 없는 메서드는 뷰 이름(JSP 경로)을 반환하고,
 *   @ResponseBody 있는 메서드는 JSON 데이터를 반환한다.
 * ============================================================ */
@Slf4j
@Controller
@RequestMapping("/news")
public class NewsController {

    @Autowired
    private NewsService newsService;

    /** ============================================================
     * [메서드 읽기] 뉴스 검색 결과를 JSON으로 반환한다. GET /news
     *
     * [실행 흐름]
     * 1. newsService.searchStockNews() → 네이버 뉴스 API 호출
     * 2. 결과가 있으면 ResponseEntity.ok(newsData) 반환 (HTTP 200 + JSON)
     * 3. 결과가 없으면 빈 규격 응답 반환
     *    → { "items": [], "message": "검색 결과가 존재하지 않는 종목명입니다." }
     *
     * [keyword 기본값 "주식"]
     *   keyword 파라미터가 없으면 "주식"으로 검색한다.
     *   JS에서 종목명을 keyword로 전달해 해당 종목 관련 뉴스를 가져온다.
     *
     * [start 파라미터] 페이징 시작 위치. 기본값 1 (첫 번째 기사부터).
     *   "더 보기" 기능 구현 시 start를 31, 61 등으로 증가시켜 호출한다.
     *
     * [ResponseEntity<?>]
     *   성공: NewsDTO 반환 / 실패: Map<String,Object> 반환 — 두 타입을 ? 와일드카드로 처리.
     *   HTTP 상태 코드를 함께 담아 반환할 수 있다.
     *
     * [빈 규격 반환 이유]
     *   null 또는 HTTP 오류 대신 { items:[], message:... } 구조를 반환하면
     *   JS에서 타입 오류 없이 items 배열을 순회할 수 있다.
     * ============================================================ */
    @ResponseBody
    @GetMapping("")
    public ResponseEntity<?> getRealtimeNews(
            @RequestParam(value = "keyword", required = false, defaultValue = "주식") String keyword,
            @RequestParam(value = "start", required = false, defaultValue = "1") int start) {

        log.info("📡 [뉴스 도메인 엔진 가동] 검색어: {}, start: {}", keyword, start);

        NewsDTO newsData = newsService.searchStockNews(keyword, start);

        // [실행 흐름] 정상 결과 → ResponseEntity.ok() = HTTP 200 + body
        if (newsData != null && newsData.getItems() != null && !newsData.getItems().isEmpty()) {
            return ResponseEntity.ok(newsData);
        }

        // [실행 흐름] 결과 없음 또는 실패 → 빈 규격 Map 반환 (JS에서 타입 오류 방지)
        log.warn("⚠️ [{}] 뉴스 데이터가 비어있어 빈 규격 객체를 반환합니다.", keyword);
        return ResponseEntity.ok(Map.of(
            "items", List.of(),
            "message", "검색 결과가 존재하지 않는 종목명입니다."
        ));
    }

    /** ============================================================
     * [메서드 읽기] 뉴스 목록 페이지(news/list.jsp)로 이동한다. GET /news/list
     *
     * [void가 아닌 String 반환] "news/list"를 반환하면 ViewResolver가
     *   /WEB-INF/views/news/list.jsp를 찾아 렌더링한다.
     * ============================================================ */
    @GetMapping("/list")
    public String openNewsRoomPage() {
        return "news/list"; // news/list.jsp 렌더링
    }
}
