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

@RestController
@RequestMapping("/api/market-index")
@RequiredArgsConstructor
public class MarketIndexController {

    private final MarketIndexService marketIndexService;
    private final BoardService boardService;
    private final NoticeService noticeService;

    @GetMapping
    public List<MarketIndexDTO> getMarketIndex() {
        return marketIndexService.getMarketIndex();
    }

    // 💡 1. @RequestParam 안에 value = "limit" 지정
    @GetMapping("/recent-board")
    public List<BoardDTO> getRecentBoard(@RequestParam(value = "limit", defaultValue = "5") int limit) throws Exception {
        return boardService.listRecent(limit);
    }

    // 💡 2. @RequestParam 안에 value = "limit" 지정
    @GetMapping("/recent-notice")
    public List<NoticeDTO> getRecentNotice(@RequestParam(value = "limit", defaultValue = "5") int limit) throws Exception {
        return noticeService.listRecent(limit);
    }
}