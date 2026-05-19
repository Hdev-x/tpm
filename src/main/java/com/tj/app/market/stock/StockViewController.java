package com.tj.app.market.stock;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class StockViewController {

    @GetMapping("/stock/list")
    public String listPage() {
        return "stock/list";
    }

    @GetMapping("/stock/view")
    public String chartPage() {
        return "stock/chart";
    }
}
