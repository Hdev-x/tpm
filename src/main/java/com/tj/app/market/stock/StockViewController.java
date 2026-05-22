package com.tj.app.market.stock;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class StockViewController {

    @Autowired
    private StockJoinService stockJoinService;

    @GetMapping("/stock/list")
    public String listPage() {
        return "stock/list";
    }

    @GetMapping("/stock/view")
    public String chartPage() {
        return "stock/chart";
    }

    @GetMapping("/stock/community")
    public String communityPage(
            @RequestParam(value = "code", required = false, defaultValue = "005930") String code,
            Model model) {
        model.addAttribute("code", code);
        model.addAttribute("stockName", stockJoinService.getName(code));
        return "stock/community";
    }
}
