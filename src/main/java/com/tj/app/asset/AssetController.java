package com.tj.app.asset;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import com.tj.app.member.MemberDTO;

import jakarta.servlet.http.HttpSession;

/** ============================================================
 * [클래스 읽기] 자산 관련 요청을 처리하는 Controller.
 *
 * @RequestMapping("/asset") → 모든 메서드는 /asset 으로 시작하는 URL을 처리한다.
 *
 * [전체 흐름]
 * HTTP 요청 → AssetController → AssetService(주식+코인 통합 계산) → 응답
 *
 * 뷰 반환: GET /asset         → JSP 페이지
 * JSON 반환: GET /asset/summary, /asset/detail-data → fetch로 호출해 화면에 표시
 * ============================================================ */
@Controller
@RequestMapping("/asset")
public class AssetController {

    @Autowired
    private AssetService assetService;

    /** ============================================================
     * GET /asset → 자산 현황 페이지.
     * 비로그인 시 로그인 페이지로 리다이렉트하며 redirect 파라미터로 복귀 경로를 전달한다.
     * 실제 자산 데이터는 이 메서드에서 계산하지 않고,
     * 페이지 로드 후 JS에서 /asset/summary를 fetch해 채운다.
     * ============================================================ */
    @GetMapping("")
    public String assetPage(HttpSession session) {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return "redirect:/member/login?redirect=/asset";
        return "member/asset";
    }

    /** ============================================================
     * GET /asset/summary → 주식+코인 통합 자산 요약 JSON 반환.
     *
     * @ResponseBody → 반환값을 JSP가 아닌 JSON으로 직접 출력한다.
     * ResponseEntity<Map> → 상태 코드와 응답 바디를 함께 제어한다.
     * 비로그인이면 빈 Map({})을 200으로 반환한다 (에러 대신 빈 데이터).
     *
     * 반환 구조:
     *   { grandTotal, stock: { total, cash, locked, eval, pnl, rate, items[] },
     *                  coin:  { totalKrw, cashUsdt, evalUsdt, pnlUsdt, rate, items[] } }
     * ============================================================ */
    @GetMapping("/summary")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getAssetSummary(HttpSession session) {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.ok(new HashMap<>());
        return ResponseEntity.ok(assetService.getAssetSummary(member));
    }

    /** ============================================================
     * GET /asset/detail-data → 보유 종목 상세 리스트 JSON 반환.
     *
     * 주식과 코인 보유 종목을 하나의 리스트로 합쳐서 반환한다.
     * 각 항목에 type("stock"/"coin") 필드가 있어 프론트에서 구분할 수 있다.
     * 비로그인이면 List.of() → 빈 배열([]) 반환.
     * ============================================================ */
    @GetMapping("/detail-data")
    @ResponseBody
    public List<Map<String, Object>> getAssetDetailData(HttpSession session) {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return List.of();
        return assetService.getAssetDetails(member);
    }
}
