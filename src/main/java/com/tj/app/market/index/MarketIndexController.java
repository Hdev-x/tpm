package com.tj.app.market.index;

import com.tj.app.board.BoardDTO;
import com.tj.app.board.BoardService;
import com.tj.app.notice.NoticeDTO;
import com.tj.app.notice.NoticeService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

/** ============================================================
 * [클래스 읽기] 시장 지수·최신 게시글·최신 공지사항을 JSON으로 반환하는 REST 컨트롤러.
 *
 * 메인 대시보드(홈 화면)에서 JavaScript가 이 API를 호출해
 * 시장 지수 티커, 최근 게시글 목록, 최근 공지사항을 동적으로 렌더링한다.
 *
 * [@RestController] = @Controller + @ResponseBody
 *   모든 메서드 반환값을 자동으로 JSON으로 직렬화한다.
 *   JSP를 렌더링하지 않고 순수 데이터만 반환한다.
 *
 * [@RequiredArgsConstructor] final 필드를 파라미터로 받는 생성자를 자동 생성.
 *   Spring이 해당 생성자를 통해 Service 빈을 주입한다(생성자 주입).
 * ============================================================ */
@RestController
@RequestMapping("/api/market-index")
@RequiredArgsConstructor
public class MarketIndexController {

    private final MarketIndexService marketIndexService;
    private final BoardService boardService;
    private final NoticeService noticeService;

    /** ============================================================
     * GET /api/market-index
     * 7개 시장 지수를 병렬 조회해 JSON 배열로 반환한다.
     * JS에서 fetch("/api/market-index") 로 호출 → 티커 바에 렌더링
     * ============================================================ */
    @GetMapping
    public List<MarketIndexDTO> getMarketIndex() {
        return marketIndexService.getMarketIndex();
    }

    /** ============================================================
     * GET /api/market-index/recent-board?limit=5
     * 최신 게시글 N개를 반환한다.
     * defaultValue = "5" → limit 파라미터 없이 호출하면 5개 반환
     * ============================================================ */
    @GetMapping("/recent-board")
    public List<BoardDTO> getRecentBoard(@RequestParam(value = "limit", defaultValue = "5") int limit) throws Exception {
        return boardService.listRecent(limit);
    }

    /** ============================================================
     * GET /api/market-index/recent-notice?limit=5
     * 최신 공지사항 N개를 반환한다.
     * ============================================================ */
    @GetMapping("/recent-notice")
    public List<NoticeDTO> getRecentNotice(@RequestParam(value = "limit", defaultValue = "5") int limit) throws Exception {
        return noticeService.listRecent(limit);
    }
}