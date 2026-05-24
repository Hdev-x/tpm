package com.tj.app.market.stock.order;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.tj.app.member.MemberDTO;

import jakarta.servlet.http.HttpSession;

/** ============================================================
 * [클래스 읽기] 주식 주문 접수·조회·취소 요청을 처리하는 컨트롤러.
 *
 * [@Controller + @ResponseBody] = @RestController와 동일하지만,
 * 클래스 레벨이 아닌 메서드 레벨에 @ResponseBody를 붙여 JSON 반환을 명시한다.
 * (일부 메서드에서 JSP를 반환할 가능성이 있을 때 이 방식을 쓰기도 한다)
 *
 * [로그인 체크 패턴]
 * 모든 메서드에서 세션에 member가 없으면 인증 실패 응답 또는 빈 리스트 반환.
 * 미로그인 상태에서 주문/취소를 막기 위한 서버 측 방어 로직이다.
 *
 * [주요 엔드포인트]
 * POST /stock/order           : 매수/매도 주문 접수
 * GET  /stock/account-balance : 예수금 + 잠긴 금액 조회
 * GET  /stock/holding-list    : 보유 주식 목록
 * GET  /stock/pending-list    : 미체결 주문 목록
 * GET  /stock/history-list    : 체결 완료 거래 내역
 * POST /stock/cancel-order    : 미체결 주문 취소
 * ============================================================ */
@Controller
@RequestMapping("/stock")
public class OrderStockController {

    @Autowired
    private OrderStockService stockOrderService;

    /** ============================================================
     * POST /stock/order?side={BUY|SELL}
     * 주식 매수/매도 주문을 접수한다.
     *
     * [@RequestBody OrderStockDTO dto] JS에서 JSON body로 전송한 주문 데이터
     * [@RequestParam side] 매수("BUY") 또는 매도("SELL") 구분
     *
     * [응답 메시지 분기]
     * - 즉시 체결(COMPLETED): "시장가 즉시 체결" 또는 "지정가 조건 만족 즉시 체결"
     * - 미체결(PENDING):      "주문 접수 완료 (미체결 상태)"
     * - 실패:                 잔고/수량 부족 메시지
     * ============================================================ */
    @PostMapping("/order")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> submitStockOrder(
            @RequestParam("side") String side,
            @RequestBody OrderStockDTO dto,
            HttpSession session) {

        Map<String, Object> response = new HashMap<>();
        MemberDTO member = (MemberDTO) session.getAttribute("member");

        // [실행 흐름] 미로그인 요청 차단
        if (member == null) {
            response.put("success", false);
            response.put("message", "로그인 세션이 만료되었습니다. 다시 로그인 후 이용해주세요.");
            return ResponseEntity.ok(response);
        }

        try {
            boolean isSuccess = stockOrderService.placeOrder(member, side, dto);

            if (isSuccess) {
                response.put("success", true);
                // [실행 흐름] 즉시 체결 vs 미체결 여부에 따라 메시지 분기
                if ("COMPLETED".equals(dto.getStatus())) {
                    if ("MARKET".equalsIgnoreCase(dto.getOrderType()) || dto.getTargetPrice() == 0) {
                        response.put("message", "시장가 주문이 즉시 체결되었습니다.");
                    } else {
                        response.put("message", "지정가 주문이 현재가 조건에 맞아 즉시 체결되었습니다.");
                    }
                } else {
                    response.put("message", "주문이 접수되었습니다. (미체결 상태)");
                }
            } else {
                response.put("success", false);
                response.put("message", "주문 체결에 실패했습니다. 잔고나 보유 수량을 확인하세요.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.put("success", false);
            response.put("message", "서버 오류로 인해 주문을 처리하지 못했습니다.");
        }

        return ResponseEntity.ok(response);
    }

    /** ============================================================
     * GET /stock/account-balance
     * 현재 예수금(balance)과 미체결 매수에 묶인 금액(locked)을 반환한다.
     * JS에서 주문 폼에 잔고를 표시할 때 사용한다.
     * 미로그인 시 balance=0, locked=0 반환 (빈 화면 표시용).
     * ============================================================ */
    @GetMapping("/account-balance")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getAccountBalance(HttpSession session) {
        Map<String, Object> response = new HashMap<>();
        MemberDTO member = (MemberDTO) session.getAttribute("member");

        if (member == null) {
            response.put("balance", 0);
            response.put("locked", 0);
            return ResponseEntity.ok(response);
        }

        try {
            long currentCash = stockOrderService.getUserBalance(member);
            long lockedCash  = stockOrderService.getLockedPendingBuyCash(member);
            response.put("balance", currentCash);
            response.put("locked",  lockedCash);
        } catch (Exception e) {
            response.put("balance", 0);
            response.put("locked",  0);
        }

        return ResponseEntity.ok(response);
    }

    /** ============================================================
     * GET /stock/holding-list
     * 사용자의 보유 주식 목록을 반환한다.
     * 우측 사이드바 보유 자산 탭에서 사용한다.
     * 미로그인 시 빈 리스트 반환 → 사이드바에 "보유 종목 없음" 표시.
     * ============================================================ */
    @GetMapping("/holding-list")
    @ResponseBody
    public ResponseEntity<List<Map<String, Object>>> getHoldingList(HttpSession session) {
        MemberDTO member = (MemberDTO) session.getAttribute("member");

        if (member == null) {
            return ResponseEntity.ok(java.util.Collections.emptyList());
        }

        List<Map<String, Object>> holdingList = stockOrderService.getHoldingStockList(member);
        return ResponseEntity.ok(holdingList);
    }

    /** ============================================================
     * GET /stock/pending-list
     * 미체결(PENDING) 지정가 주문 목록을 반환한다.
     * 사이드바 예약 주문 탭에서 사용한다.
     * ============================================================ */
    @GetMapping("/pending-list")
    @ResponseBody
    public ResponseEntity<List<Map<String, Object>>> getPendingList(HttpSession session) {
        MemberDTO member = (MemberDTO) session.getAttribute("member");

        if (member == null) {
            return ResponseEntity.ok(java.util.Collections.emptyList());
        }

        List<Map<String, Object>> pendingList = stockOrderService.getPendingOrders(member);
        return ResponseEntity.ok(pendingList);
    }

    /** ============================================================
     * GET /stock/history-list
     * 체결 완료(DONE) 거래 내역 목록을 반환한다.
     * 사이드바 거래 내역 탭에서 사용한다.
     * ============================================================ */
    @GetMapping("/history-list")
    @ResponseBody
    public ResponseEntity<List<Map<String, Object>>> getHistoryList(HttpSession session) {
        MemberDTO member = (MemberDTO) session.getAttribute("member");

        if (member == null) {
            return ResponseEntity.ok(java.util.Collections.emptyList());
        }

        List<Map<String, Object>> historyList = stockOrderService.getOrderList(member);
        return ResponseEntity.ok(historyList);
    }

    /** ============================================================
     * POST /stock/cancel-order?orderNo={주문번호}
     * 미체결 지정가 주문을 취소한다.
     *
     * [실행 흐름]
     * Service의 cancelStockOrder() 호출 → 본인 주문 확인 → 예수금 복원 → 상태 CANCELED
     * ============================================================ */
    @PostMapping("/cancel-order")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> cancelOrder(
            @RequestParam("orderNo") long orderNo,
            HttpSession session) {

        Map<String, Object> response = new HashMap<>();
        MemberDTO member = (MemberDTO) session.getAttribute("member");

        if (member == null) {
            response.put("success", false);
            response.put("message", "로그인 세션이 만료되었습니다.");
            return ResponseEntity.ok(response);
        }

        try {
            boolean isCancelled = stockOrderService.cancelStockOrder(member, orderNo);
            response.put("success", isCancelled);
            response.put("message", isCancelled
                    ? "주문이 정상적으로 취소되었습니다."
                    : "주문 취소에 실패했거나 이미 처리된 주문입니다.");
        } catch (Exception e) {
            e.printStackTrace();
            response.put("success", false);
            response.put("message", "서버 오류로 인해 주문을 취소하지 못했습니다.");
        }

        return ResponseEntity.ok(response);
    }
}