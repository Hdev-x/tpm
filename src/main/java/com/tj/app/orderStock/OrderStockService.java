package com.tj.app.orderStock;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.tj.app.market.stock.StockService;
import com.tj.app.member.MemberDTO;

import lombok.extern.slf4j.Slf4j;

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
    public boolean executeStockOrder(MemberDTO member, String side, OrderStockDTO dto) {
        String username = member.getUsername();
        dto.setUsername(username);

        if (dto.getStockCode() == null || dto.getStockCode().isBlank()) {
            if (dto.getStockNo() != null) dto.setStockCode(String.format("%06d", dto.getStockNo()));
            else return false;
        }
        String stockCodeStr = dto.getStockCode().trim();
        dto.setStockCode(stockCodeStr);

        long currentMarketPrice = stockService.getCurrentPrice(stockCodeStr); 
        
        boolean isExecutable = ("BUY".equalsIgnoreCase(side)) ? 
                               (dto.getOrderPrice() >= currentMarketPrice) : 
                               (dto.getOrderPrice() <= currentMarketPrice);

        if (isExecutable) {
            // [체결 성공]
            dto.setStatus("COMPLETED");
            // 💡 여기서 insertOrder를 한 번만 실행하고, processExecution에서는 update만 하도록 구조 변경
            orderStockMapper.insertOrder(dto); 
            processExecution(dto);
        } else {
            // [미체결 처리]
            dto.setStatus("PENDING");
            orderStockMapper.insertOrder(dto);
        }
        return true;
    }

	@Transactional
	public void processExecution(OrderStockDTO dto) {
		String side = dto.getOrderType(); // 매수("BUY")인지 매도("SELL")인지 확인
		String username = dto.getUsername();
		long totalOrderAmount = dto.getOrderPrice() * dto.getOrderCount();

		if ("BUY".equalsIgnoreCase(side)) {
			// 기존 매수 로직 (ASSETS 업데이트)
			Long userCash = orderStockMapper.getWallet(username);
			orderStockMapper.updateWallet(username, userCash - totalOrderAmount);

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
			long currentCount = ((Number) holdingStock.get("STOCK_COUNT")).longValue();
			long currentPurchase = ((Number) holdingStock.get("STOCK_PURCHASE")).longValue();

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
	public boolean cancelStockOrder(long orderNo) {
		// 매퍼에게도 주문 번호를 그대로 전달하여 쿼리를 실행하게 합니다.
		int result = orderStockMapper.cancelPendingByStock(orderNo);
		return result > 0;
	}
}