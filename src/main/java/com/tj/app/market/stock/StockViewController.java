package com.tj.app.market.stock;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

/** ============================================================
 * [클래스 읽기] 주식 관련 JSP 페이지를 렌더링하는 View 컨트롤러.
 *
 * StockController(@RestController, JSON 반환)와 역할이 다르다.
 * 이 클래스는 @Controller로 JSP View 이름을 반환해 화면을 그린다.
 *
 * [페이지 매핑]
 * /stock/list      → stock/list.jsp      (주식 종목 리스트 화면)
 * /stock/view      → stock/chart.jsp     (종목 차트 상세 화면)
 * /stock/community → stock/community.jsp (종목별 커뮤니티 화면)
 * ============================================================ */
@Controller
public class StockViewController {

    @Autowired
    private StockJoinService stockJoinService;

    /** ============================================================
     * GET /stock/list → stock/list.jsp 렌더링
     * 주식 종목 목록 화면. 실제 데이터는 JS에서 /stock/db-list API를 호출한다.
     * ============================================================ */
    @GetMapping("/stock/list")
    public String listPage() {
        return "stock/list";
    }

    /** ============================================================
     * GET /stock/view → stock/chart.jsp 렌더링
     * 종목 차트 상세 화면. JS에서 /stock/chart API를 호출해 데이터를 그린다.
     * ============================================================ */
    @GetMapping("/stock/view")
    public String chartPage() {
        return "stock/chart";
    }

    /** ============================================================
     * GET /stock/community?code={종목코드} → stock/community.jsp 렌더링
     *
     * [실행 흐름]
     * code 파라미터로 종목 코드를 받아 Model에 담는다.
     * JSP에서 ${code}, ${stockName}으로 종목 코드·이름을 사용한다.
     * defaultValue = "005930" → 파라미터 없으면 삼성전자로 기본 진입
     * ============================================================ */
    @GetMapping("/stock/community")
    public String communityPage(
            @RequestParam(value = "code", required = false, defaultValue = "005930") String code,
            Model model) {
        model.addAttribute("code", code);
        model.addAttribute("stockName", stockJoinService.getName(code)); // DB에서 종목명 조회
        return "stock/community";
    }
}
