package com.tj.app.orderStock;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.tj.app.market.stock.StockService;
import com.tj.app.member.MemberDTO;

import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@Slf4j
public class OrderStockService {

	@Autowired
	private OrderStockMapper orderStockMapper;

	@Autowired
	private StockService stockService;

	/**
     * 💰 [주식 주문 체결 코어 트랜잭션 수립]
     * @param member 현재 로그인한 사용자 DTO 객체
     * @param side 프론트엔드에서 보낸 매수/매도 구분 문자열 ("BUY" 또는 "SELL")
     * @param dto 프론트엔드에서 넘어온 주문 요청 객체
     * @return 체결 성공 여부 (true: 성공 / false: 잔고 부족 등 실패)
     */

	@Transactional
	public void processExecution(OrderStockDTO dto) {
		String side = dto.getOrderType(); // 매수("BUY")인지 매도("SELL")인지 확인
		String username = dto.getUsername();
		long totalOrderAmount = dto.getOrderPrice() * dto.getOrderCount();

		if ("BUY".equalsIgnoreCase(side)) {
			// 💡 [수정] placeOrder에서 이미 잔고를 차감했으므로, 여기서는 잔고 업데이트를 하지 않습니다.
			// (ASSETS 업데이트만 수행)

			Map<String, Object> holdingStock = orderStockMapper.getHolding(username, dto.getStockCode());
			if (holdingStock == null || holdingStock.isEmpty()) {
				orderStockMapper.insertHolding(dto);
			} else {
				long currentCount = ((Number) holdingStock.get("STOCK_COUNT")).longValue();
				long currentPurchase = ((Number) holdingStock.get("STOCK_PURCHASE")).longValue();
				long newCount = currentCount + dto.getOrderCount();
				long newPurchase = ((currentCount * currentPurchase) + totalOrderAmount) / newCount;
				dto.setOrderCount(newCount);
				dto.setOrderPrice(newPurchase);
				orderStockMapper.updateHolding(dto);
			}
		} else {
			// 기존 매도 로직 (ASSETS 업데이트)
			Map<String, Object> holdingStock = orderStockMapper.getHolding(username, dto.getStockCode());
			if (holdingStock == null || holdingStock.isEmpty()) {
				log.error("❌ [체결 실패] 보유 주식이 없습니다. 유저: {}, 종목: {}", username, dto.getStockCode());
				return;
			}

			long currentCount = ((Number) holdingStock.get("STOCK_COUNT")).longValue();
			long currentPurchase = ((Number) holdingStock.get("STOCK_PURCHASE")).longValue();

			if (currentCount < dto.getOrderCount()) {
				log.error("❌ [체결 실패] 보유 수량 부족. 유저: {}, 보유: {}, 주문: {}", username, currentCount, dto.getOrderCount());
				return;
			}

			Long userCash = orderStockMapper.getWallet(username);
			orderStockMapper.updateWallet(username, userCash + totalOrderAmount);

			if (currentCount == dto.getOrderCount())
				orderStockMapper.deleteHolding(username, dto.getStockCode());
			else {
				dto.setOrderCount(currentCount - dto.getOrderCount());
				dto.setOrderPrice(currentPurchase);
				orderStockMapper.updateHolding(dto);
			}
		}

		// 상태를 COMPLETED로 변경
		dto.setStatus("COMPLETED");
		orderStockMapper.updateOrderStatus(dto);
	}

	// ====================================================
	// 2. 가용 잔고 조회 엔진 (getUserBalance)
	// ====================================================
	public long getUserBalance(MemberDTO member) {
		return orderStockMapper.getWallet(member.getUsername());
	}

	// ====================================================
	// 3. 보유 자산 리스트 조회 엔진 (getHoldingStockList)
	// ====================================================
	public List<Map<String, Object>> getHoldingStockList(MemberDTO member) {
		return orderStockMapper.getHoldingList(member.getUsername());
	}

	// ====================================================
	// ⏳ 4. 미체결 예약 주문 목록 전체 조회 엔진 (getPendingOrders)
	// ====================================================
	public List<Map<String, Object>> getPendingOrders(MemberDTO member) {
		return orderStockMapper.getPendingOrders(member.getUsername());
	}

	// ====================================================
	// 📜 5. 체결 완료 거래 내역 목록 전체 조회 엔진 (getOrderList)
	// ====================================================
	public List<Map<String, Object>> getOrderList(MemberDTO member) {
		return orderStockMapper.getOrderList(member.getUsername());
	}

	// ====================================================
	// ❌ 6. 우측 사이드바 미체결 예약 주문 일괄 취소 엔진 (cancelStockOrder)
	// ====================================================
	// 🔴 [싱크 교정]: 인터페이스 명칭인 cancelPendingByStock 규격에 맞춰 결합하고,
	// orderNo 대신 매퍼가 요구하는 특정 유저의 특정 종목코드 취소선으로 완벽 동기화합니다.
	@Transactional
	public boolean cancelStockOrder(MemberDTO member ,long orderNo) {
	    // 1. 주문 정보 조회 (위에서 추가한 쿼리 사용)
	    OrderStockDTO order = orderStockMapper.getOrderById(orderNo);
	    
	    // 2. 주문이 없거나 본인 주문이 아닌 경우 보안 체크
	    if (order == null || !order.getUsername().equals(member.getUsername())) {
	        log.warn("🚨 비정상적인 주문 취소 시도: 유저 {}, 주문번호 {}", member.getUsername(), orderNo);
	        return false;
	    }
	    
	    if (!"PENDING".equals(order.getStatus())) {
	        return false;
	    }

	    // 3. [매수 취소 시] 예수금 복구
	    if ("BUY".equalsIgnoreCase(order.getOrderType())) {
	        long refundAmount = (long) order.getOrderPrice() * order.getOrderCount();
	        Long currentWallet = orderStockMapper.getWallet(order.getUsername());
	        orderStockMapper.updateWallet(order.getUsername(), currentWallet + refundAmount);
	    }

	    // 4. 상태 변경
	    int result = orderStockMapper.cancelPendingByStock(orderNo);
	    log.info("❌ 주문 취소 완료: 유저 {}, 주문번호 {}", member.getUsername(), orderNo);
	    return result > 0;
	}
	
	@Transactional
	public boolean placeOrder(MemberDTO member, String side, OrderStockDTO dto) {
	    dto.setUsername(member.getUsername());
	    dto.setOrderType(side);
	    dto.setStatus("PENDING");

	    // 종목 코드 정규화 (6자리 숫자로 보정)
	    if (dto.getStockCode() == null || dto.getStockCode().isBlank()) {
	        if (dto.getStockNo() != null) {
	            dto.setStockCode(String.format("%06d", dto.getStockNo()));
	        } else {
	            return false;
	        }
	    }
	    dto.setStockCode(dto.getStockCode().trim());

	    if ("BUY".equalsIgnoreCase(side)) {
	        // 1. 매수 주문: 잔고 확인 및 차감
	        long totalAmount = (long) dto.getOrderPrice() * dto.getOrderCount();
	        long currentBalance = orderStockMapper.getWallet(member.getUsername());

	        if (currentBalance < totalAmount) {
	            log.warn("⚠️ [주문 실패] 잔고 부족. 유저: {}, 필요: {}, 현재: {}", member.getUsername(), totalAmount, currentBalance);
	            return false; 
	        }
	        orderStockMapper.updateWallet(member.getUsername(), currentBalance - totalAmount);

	    } else {
	        // 2. 매도 주문: 보유 수량 확인
	        Map<String, Object> holdingStock = orderStockMapper.getHolding(member.getUsername(), dto.getStockCode());
	        if (holdingStock == null || holdingStock.isEmpty()) {
	            log.warn("⚠️ [주문 실패] 보유 주식 없음. 유저: {}, 종목: {}", member.getUsername(), dto.getStockCode());
	            return false;
	        }
	        long currentCount = ((Number) holdingStock.get("STOCK_COUNT")).longValue();
	        if (currentCount < dto.getOrderCount()) {
	            log.warn("⚠️ [주문 실패] 보유 수량 부족. 유저: {}, 보유: {}, 주문: {}", member.getUsername(), currentCount, dto.getOrderCount());
	            return false;
	        }
	        // (참고: 실제 금융 시스템에서는 매도 주문 시 주식을 'lock' 처리하지만, 여기서는 단순화하여 체결 시점에 차감합니다.)
	    }

	    // 3. DB에 주문 저장
	    int result = orderStockMapper.insertOrder(dto);
	    
	    return result > 0;
	}
	
	// OrderStockService.java
	public long calculateTotalAsset(MemberDTO member) {
	    long cash = orderStockMapper.getWallet(member.getUsername());
	    List<Map<String, Object>> holdingList = orderStockMapper.getHoldingList(member.getUsername());
	    
	    long stockValue = 0;
	    for (Map<String, Object> holding : holdingList) {
	        String stockCode = (String) holding.get("STOCK_CODE");
	        long count = ((Number) holding.get("STOCK_COUNT")).longValue();
	        
	        // 💡 중요: 이제 API 호출(getCurrentPrice) 대신 캐시를 읽습니다!
	        long currentPrice = stockService.getPriceFromCache(stockCode); 
	        
	        // 캐시에 없으면(0이면) 어쩔 수 없이 API를 한 번만 호출
	        if (currentPrice <= 0) {
	            currentPrice = stockService.getCurrentPrice(stockCode);
	        }
	        
	        stockValue += (count * currentPrice);
	    }
	    return cash + stockValue;
	}
	
	public List<Map<String, Object>> getAssetDetails(MemberDTO member) {
        // 1. 현재 유저의 보유 종목을 DB에서 가져옴 (기존 매핑 활용)
        List<Map<String, Object>> holdings = orderStockMapper.getHoldingList(member.getUsername());
        List<Map<String, Object>> details = new ArrayList<>();
        
        for (Map<String, Object> h : holdings) {
            String code = (String) h.get("STOCK_CODE");
            long count = ((Number) h.get("STOCK_COUNT")).longValue();
            long avgPrice = ((Number) h.get("STOCK_PURCHASE")).longValue();
            
            // 2. StockService(메모리 캐시)에서 실시간 가격 가져오기
            long currentPrice = stockService.getPriceFromCache(code);
            
            // 3. 수익률 및 평가금액 계산 (currentPrice가 0이면 데이터 없음 처리)
            long totalBuy = avgPrice * count;
            long totalEval = (currentPrice > 0) ? (currentPrice * count) : totalBuy; // 가격 없으면 원금 기준
            
            double profitRate = (totalBuy == 0) ? 0 : ((double)(totalEval - totalBuy) / totalBuy) * 100;
            
            // 4. 결과 맵에 담기
            Map<String, Object> map = new HashMap<>();
            map.put("name", h.get("STOCK_NAME"));      // 종목명
            map.put("count", count);                   // 보유 수량
            map.put("buyPrice", avgPrice);             // 매수 단가
            map.put("currentPrice", currentPrice);     // 현재가
            map.put("eval", totalEval);                // 평가금액
            map.put("rate", String.format("%.2f", profitRate)); // 수익률
            
            details.add(map);
        }
        return details;
    }
	
}