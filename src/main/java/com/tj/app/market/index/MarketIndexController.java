package com.tj.app.market.index;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/market-index")
@RequiredArgsConstructor
public class MarketIndexController {

    private final MarketIndexService marketIndexService;

    @GetMapping
    public List<MarketIndexDTO> getMarketIndex() {
        return marketIndexService.getMarketIndex();
    }
}
