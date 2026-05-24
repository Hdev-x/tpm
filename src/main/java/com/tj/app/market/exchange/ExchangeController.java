package com.tj.app.market.exchange;

import com.tj.app.member.MemberDTO;
import jakarta.servlet.http.HttpSession;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** ============================================================
 * [클래스 읽기] KRW ↔ USDT 환전 요청을 처리하는 REST 컨트롤러.
 *
 * JS에서 fetch("/api/exchange/krw-to-usdt", { method: "POST", ... }) 형태로 호출한다.
 * 세션에서 로그인 정보를 꺼내 사용자를 식별하고, ExchangeService에 처리를 위임한다.
 *
 * [응답 패턴]
 * - 로그인 안 된 경우: HTTP 401 + { success: false, message: "..." }
 * - 환전 성공:         HTTP 200 + { success: true }
 * - 환전 실패(잔액 부족 등): HTTP 200 + { success: false, message: "..." }
 *   [주의] 실패도 200으로 내려주는 이유: JS 쪽에서 success 필드로 성공/실패를 판단하기 때문.
 *          4xx/5xx를 쓰면 JS fetch가 catch()로 빠져 응답 body를 읽기 어려워진다.
 * ============================================================ */
@Slf4j
@RestController
@RequestMapping("/api/exchange")
public class ExchangeController {

    @Autowired
    private ExchangeService exchangeService;

    /** ============================================================
     * POST /api/exchange/krw-to-usdt
     * 주식 예수금(KRW) → 코인 지갑(USDT) 환전.
     *
     * @param krwAmount 환전할 원화 금액 (폼 파라미터)
     * @param rate      현재 USD/KRW 환율 (JS에서 Frankfurter API로 조회 후 전달)
     * @param session   로그인 사용자 정보 조회용
     * ============================================================ */
    @PostMapping("/krw-to-usdt")
    public ResponseEntity<?> krwToUsdt(
            @RequestParam("krwAmount") long krwAmount,
            @RequestParam("rate") double rate,
            HttpSession session) {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        // [실행 흐름] 세션에 member 없으면 미로그인 → 401 반환
        if (member == null) return ResponseEntity.status(401).body(Map.of("success", false, "message", "로그인이 필요합니다."));

        try {
            exchangeService.krwToUsdt(member.getUsername(), krwAmount, rate);
            return ResponseEntity.ok(Map.of("success", true));
        } catch (Exception e) {
            log.warn("환전 실패 [KRW→USDT] {}: {}", member.getUsername(), e.getMessage());
            return ResponseEntity.ok(Map.of("success", false, "message", e.getMessage()));
        }
    }

    /** ============================================================
     * POST /api/exchange/usdt-to-krw
     * 코인 지갑(USDT) → 주식 예수금(KRW) 환전.
     *
     * @param usdtAmount 환전할 USDT 금액 (폼 파라미터)
     * @param rate       현재 USD/KRW 환율
     * @param session    로그인 사용자 정보 조회용
     * ============================================================ */
    @PostMapping("/usdt-to-krw")
    public ResponseEntity<?> usdtToKrw(
            @RequestParam("usdtAmount") double usdtAmount,
            @RequestParam("rate") double rate,
            HttpSession session) {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.status(401).body(Map.of("success", false, "message", "로그인이 필요합니다."));

        try {
            exchangeService.usdtToKrw(member.getUsername(), usdtAmount, rate);
            return ResponseEntity.ok(Map.of("success", true));
        } catch (Exception e) {
            log.warn("환전 실패 [USDT→KRW] {}: {}", member.getUsername(), e.getMessage());
            return ResponseEntity.ok(Map.of("success", false, "message", e.getMessage()));
        }
    }
}
