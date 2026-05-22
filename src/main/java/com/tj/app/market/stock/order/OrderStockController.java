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

@Controller
@RequestMapping("/stock")
public class OrderStockController {

	@Autowired
	private OrderStockService stockOrderService;

	/**
	 * 🖥️ [주식 주문 접수 엔드포인트]
	 * URL: POST /stock/order
	 */
	@PostMapping("/order")
	@ResponseBody
	public ResponseEntity<Map<String, Object>> submitStockOrder(@RequestParam("side") String side,
			@RequestBody OrderStockDTO dto, HttpSession session) {

		Map<String, Object> response = new HashMap<>();

		// 💡 세션에서 '실제' 로그인한 사용자의 username을 꺼내옵니다.
		MemberDTO member = (MemberDTO) session.getAttribute("member");

		// 🔴 [수정포인트 1] 로그인하지 않은 가상 유저의 불법 요청 차단 가드 세우기
		if (member == null) {
			response.put("success", false);
			response.put("message", "로그인 세션이 만료되었습니다. 다시 로그인 후 이용해주세요.");
			return ResponseEntity.ok(response);
		}

		try {
			// 비즈니스 코어 엔진(Service)을 호출하여 실제 로그인한 회원의 트랜잭션을 실행합니다.
			boolean isSuccess = stockOrderService.placeOrder(member, side, dto);

			if (isSuccess) {
	            response.put("success", true);
	            // [수정] 주문 유형과 상태에 따라 정확한 메시지 반환
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

	/**
	 * 💳 [가용 잔고 및 계좌 정보 조회 엔드포인트]
	 * URL: GET /stock/account-balance
	 */
	@GetMapping("/account-balance")
	@ResponseBody
	public ResponseEntity<Map<String, Object>> getAccountBalance(HttpSession session) {
		Map<String, Object> response = new HashMap<>();

		MemberDTO member = (MemberDTO) session.getAttribute("member");
		
		// 🔴 [수정포인트 2] 로그인 안 된 경우 잔고 0원 반환 및 안전 차단
		if (member == null) {
			response.put("balance", 0);
			response.put("locked", 0);
			return ResponseEntity.ok(response);
		}

		try {
			long currentCash = stockOrderService.getUserBalance(member);
			long lockedCash = stockOrderService.getLockedPendingBuyCash(member);
			response.put("balance", currentCash);
			response.put("locked", lockedCash);
		} catch (Exception e) {
			response.put("balance", 0);
			response.put("locked", 0);
		}

		return ResponseEntity.ok(response);
	}
	
	/**
	 * 📊 [우측 사이드바 보유 자산 목록 전체 조회 API]
	 * URL: GET /stock/holding-list
	 */
	@GetMapping("/holding-list")
	@ResponseBody
	public ResponseEntity<List<Map<String, Object>>> getHoldingList(HttpSession session) {
		MemberDTO member = (MemberDTO) session.getAttribute("member");
	    
	    // 🔴 [수정포인트 3] 로그인 안 되었으면 비어있는 리스트 리턴하여 사이드바 sb-empty 트리거 활성화
	    if (member == null) {
	        return ResponseEntity.ok(java.util.Collections.emptyList());
	    }

	    List<Map<String, Object>> holdingList = stockOrderService.getHoldingStockList(member);
	    return ResponseEntity.ok(holdingList);
	}
	
	/**
	 * ⏳ [우측 사이드바 미체결 예약 주문 목록 조회 API]
	 * URL: GET /stock/pending-list
	 */
	@GetMapping("/pending-list")
	@ResponseBody
	public ResponseEntity<List<Map<String, Object>>> getPendingList(HttpSession session) {
		MemberDTO member = (MemberDTO) session.getAttribute("member");
		
		// 로그인 안 되어 있으면 비어있는 리스트 반환
		if (member == null) {
			return ResponseEntity.ok(java.util.Collections.emptyList());
		}

		// 서비스단 호출하여 매퍼의 getPendingOrders 결과 가져오기
		List<Map<String, Object>> pendingList = stockOrderService.getPendingOrders(member);
		return ResponseEntity.ok(pendingList);
	}

	/**
	 * 📜 [우측 사이드바 체결 완료 거래 내역 조회 API]
	 * URL: GET /stock/history-list
	 */
	@GetMapping("/history-list")
	@ResponseBody
	public ResponseEntity<List<Map<String, Object>>> getHistoryList(HttpSession session) {
		MemberDTO member = (MemberDTO) session.getAttribute("member");
		
		if (member == null) {
			return ResponseEntity.ok(java.util.Collections.emptyList());
		}

		// 서비스단 호출하여 매퍼의 getOrderList 결과 가져오기
		List<Map<String, Object>> historyList = stockOrderService.getOrderList(member);
		return ResponseEntity.ok(historyList);
	}

	/**
	 * ❌ [우측 사이드바 미체결 예약 주문 즉시 취소 엔드포인트]
	 * URL: POST /stock/cancel-order
	 * 💡 프론트엔드 stock.js의 cancelStockOrder() 함수와 매핑 완결
	 */
	@PostMapping("/cancel-order")
	@ResponseBody
	public ResponseEntity<Map<String, Object>> cancelOrder(@RequestParam("orderNo") long orderNo, HttpSession session) {
		Map<String, Object> response = new HashMap<>();
		MemberDTO member = (MemberDTO) session.getAttribute("member");
		
		if (member == null) {
			response.put("success", false);
			response.put("message", "로그인 세션이 만료되었습니다.");
			return ResponseEntity.ok(response);
		}

		try {
			// 서비스 레이어의 취소 비즈니스 트랜잭션 엔진 작동
			boolean isCancelled = stockOrderService.cancelStockOrder(member, orderNo);
			
			response.put("success", isCancelled);
			if (isCancelled) {
				response.put("message", "주문이 정상적으로 취소되었습니다.");
			} else {
				response.put("success", false);
				response.put("message", "주문 취소에 실패했거나 이미 처리된 주문입니다.");
			}
		} catch (Exception e) {
			e.printStackTrace();
			response.put("success", false);
			response.put("message", "서버 오류로 인해 주문을 취소하지 못했습니다.");
		}

		return ResponseEntity.ok(response);
	}
	
	@GetMapping("/asset-detail-data")
	@ResponseBody
	public List<Map<String, Object>> getAssetDetailData(HttpSession session) {
	    // 1. 세션에서 로그인 정보 가져오기
	    MemberDTO member = (MemberDTO) session.getAttribute("member");
	    
	    // 2. 🔴 로그인 세션이 끊겼을 때를 대비한 안전 가드
	    if (member == null) {
	        System.out.println("⚠️ 로그인을 해주세요");
	        return java.util.Collections.emptyList(); // 에러 대신 빈 리스트 반환
	    }
	    
	    // 3. 정상일 때만 서비스 호출
	    return stockOrderService.getAssetDetails(member);
	}
	
	@GetMapping("/asset")
	public String assetDetailPage(HttpSession session) {
	    MemberDTO member = (MemberDTO) session.getAttribute("member");
	    if (member == null) return "redirect:/member/login?redirect=/stock/asset";
	    return "member/asset";
	}
	
}