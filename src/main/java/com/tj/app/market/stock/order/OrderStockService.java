package com.tj.app.market.stock.order;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.tj.app.market.coin.CoinMarketService;
import com.tj.app.market.coin.order.CoinHoldingsDTO;
import com.tj.app.market.coin.order.CoinService;
import com.tj.app.market.coin.order.CoinWalletDTO;
import com.tj.app.market.index.MarketIndexDTO;
import com.tj.app.market.index.MarketIndexService;
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

	@Autowired
	private MarketIndexService indexService;

	@Autowired
	private CoinService coinService;

	@Autowired
	private CoinMarketService coinMarketService;

	/**
	 * 💰 [주식 주문 체결 코어 트랜잭션 수립] - placeOrder 단계에서 검증 및 예수금 선차감이 완료된 주문만 들어옵니다.
	 */
	@Transactional
	public void processExecution(OrderStockDTO dto) {
		String side = dto.getOrderType();
		String username = dto.getUsername();
		// dto.getOrderPrice()가 Long이므로 바로 계산 가능
		long totalOrderAmount = dto.getOrderPrice() * dto.getOrderCount();

		if ("BUY".equalsIgnoreCase(side)) {
			Map<String, Object> holdingStock = orderStockMapper.getHolding(username, dto.getStockCode());

			if (holdingStock == null || holdingStock.isEmpty()) {
				orderStockMapper.insertHolding(dto);
			} else {
				long currentCount = ((Number) holdingStock.get("STOCK_COUNT")).longValue();
				long currentPurchase = ((Number) holdingStock.get("STOCK_PURCHASE")).longValue();

				long newCount = currentCount + dto.getOrderCount();
				// 평단가 가중평균 계산 (long 타입 유지하여 금액 짤림 방지)
				long newPurchase = ((currentCount * currentPurchase) + totalOrderAmount) / newCount;

				dto.setOrderCount(newCount);
				dto.setOrderPrice(newPurchase); // 💡 깔끔하게 Long형으로 세팅 완료
				orderStockMapper.updateHolding(dto);
			}
		} else {
			// [매도 체결]
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

			if (currentCount == dto.getOrderCount()) {
				orderStockMapper.deleteHolding(username, dto.getStockCode());
			} else {
				dto.setOrderCount(currentCount - dto.getOrderCount());
				dto.setOrderPrice(currentPurchase); // 💡 기존 평단가(Long) 유지
				orderStockMapper.updateHolding(dto);
			}
		}

		dto.setStatus("COMPLETED");
		orderStockMapper.updateOrderStatus(dto);
	}

	@Transactional
	public boolean placeOrder(MemberDTO member, String side, OrderStockDTO dto) {
		dto.setUsername(member.getUsername());
		dto.setOrderType(side);
		
		if (dto.getStatus() == null || dto.getStatus().isBlank()) {
			dto.setStatus("PENDING");
		}

		// 종목 코드 6자리 자릿수 보정
		if (dto.getStockCode() == null || dto.getStockCode().isBlank()) {
			if (dto.getStockNo() != null) {
				dto.setStockCode(String.format("%06d", dto.getStockNo()));
			} else {
				return false;
			}
		}
		dto.setStockCode(dto.getStockCode().trim());

		if ("BUY".equalsIgnoreCase(side)) {
			// 1. 매수 주문: 잔고 확인 후 '예수금 선차감' (미체결 락)
			long totalAmount = dto.getOrderPrice() * dto.getOrderCount();
			long currentBalance = orderStockMapper.getWallet(member.getUsername());

			if (currentBalance < totalAmount) {
				log.warn("⚠️ [주문 실패] 잔고 부족. 유저: {}, 필요: {}, 현재: {}", member.getUsername(), totalAmount, currentBalance);
				return false; 
			}
			orderStockMapper.updateWallet(member.getUsername(), currentBalance - totalAmount);

		} else {
			// 2. 매도 주문: 보유 수량 확인 (미체결 매도 주문 수량 제외하고 체크)
			Map<String, Object> holdingStock = orderStockMapper.getHolding(member.getUsername(), dto.getStockCode());
			if (holdingStock == null || holdingStock.isEmpty()) {
				log.warn("⚠️ [주문 실패] 보유 주식 없음. 유저: {}, 종목: {}", member.getUsername(), dto.getStockCode());
				return false; 
			}
			
			long totalHeldCount = ((Number) holdingStock.get("STOCK_COUNT")).longValue();
			
			// 현재 미체결된 매도 주문 수량 합계 조회
			List<Map<String, Object>> pendingOrders = orderStockMapper.getPendingOrders(member.getUsername());
			long pendingSellCount = 0;
			for (Map<String, Object> po : pendingOrders) {
				if ("SELL".equalsIgnoreCase((String) po.get("ORDER_TYPE")) && 
					dto.getStockCode().equals(po.get("STOCK_CODE"))) {
					pendingSellCount += ((Number) po.get("ORDER_COUNT")).longValue();
				}
			}
			
			long availableCount = totalHeldCount - pendingSellCount;
			
			if (availableCount < dto.getOrderCount()) {
				log.warn("⚠️ [주문 실패] 매도 가능 수량 부족. 유저: {}, 보유: {}, 미체결매도: {}, 주문: {}", 
						member.getUsername(), totalHeldCount, pendingSellCount, dto.getOrderCount());
				return false;
			}
			
			// [수정] 사용자의 요청에 따라, 미체결(PENDING) 상태에서는 ASSETS 테이블의 수량을 건드리지 않습니다.
			// 대신 DB의 ORDER 테이블에 PENDING으로 저장되어 "매도 가능 수량" 체크 시에만 반영됩니다.
		}

		// 3. 지정가 주문인 경우 현재가와 비교하여 즉시 체결 조건 충족 시 상태 변경
		if ("PENDING".equals(dto.getStatus())) {
			long currentPrice = stockService.getPriceFromCache(dto.getStockCode());
			if (currentPrice <= 0) currentPrice = stockService.getCurrentPrice(dto.getStockCode());
			
			if (currentPrice > 0) {
				boolean isExecutable = "BUY".equalsIgnoreCase(side) ? 
									   (dto.getOrderPrice() >= currentPrice) : 
									   (dto.getOrderPrice() <= currentPrice);
				if (isExecutable) {
					dto.setStatus("COMPLETED");
				}
			}
		}

		// 4. DB 주문 마스터 테이블 기록
		int result = orderStockMapper.insertOrder(dto);
		
		// 5. 시장가 또는 조건 만족으로 COMPLETED가 되었다면 즉시 체결 엔진 수행
		if (result > 0 && "COMPLETED".equals(dto.getStatus())) {
			processExecution(dto);
		}
		
		return result > 0;
	}

	/**
	 * 📊 [통합 자산 계산 엔진]
	 * 미체결 매수 주문으로 인해 선차감된 예수금만 합산하여 자산 총액을 유지합니다.
	 * 주식 평가금액은 미체결 매도와 상관없이 실제 보유 수량(ASSETS 테이블)을 기준으로 계산됩니다.
	 */
	public long calculateTotalAsset(MemberDTO member) {
		if (member == null)
			return 0;

		// 1. 주식 실제 예수금 조회 (차감된 후의 금액)
		long stockCash = orderStockMapper.getWallet(member.getUsername());

		// 2. 미체결 매수 주문에 묶여 있는 현금만 합산 (매도는 주식이 아직 ASSETS에 있으므로 합산 제외)
		List<Map<String, Object>> pendingOrders = orderStockMapper.getPendingOrders(member.getUsername());
		long lockedPendingCash = 0;
		for (Map<String, Object> order : pendingOrders) {
			if ("BUY".equalsIgnoreCase((String) order.get("ORDER_TYPE"))) {
				long price = ((Number) order.get("ORDER_PRICE")).longValue();
				long count = ((Number) order.get("ORDER_COUNT")).longValue();
				lockedPendingCash += (price * count);
			}
		}

		// 3. 보유 주식 평가액 계산 (미체결 매도 주식도 여기에 포함되어 계산됨)
		List<Map<String, Object>> stockHoldings = orderStockMapper.getHoldingList(member.getUsername());
		long stockValue = 0;
		for (Map<String, Object> holding : stockHoldings) {
			String code = (String) holding.get("STOCK_CODE");
			long count = ((Number) holding.get("STOCK_COUNT")).longValue();
			long price = stockService.getPriceFromCache(code);
			if (price <= 0)
				price = stockService.getCurrentPrice(code);
			stockValue += (count * price);
		}

		// 4. 코인 자산 계산
		double coinTotalUsdt = 0;
		try {
			CoinWalletDTO wallet = coinService.getWallet(member.getUsername());
			if (wallet != null) {
				coinTotalUsdt += wallet.getUsdtBalance();
			}

			List<CoinHoldingsDTO> coinHoldings = coinService.getHoldingList(member.getUsername());
			if (coinHoldings != null && !coinHoldings.isEmpty()) {
				Map<String, Double> prices = coinMarketService.getTickerPriceMap();
				for (CoinHoldingsDTO ch : coinHoldings) {
					double price = prices.getOrDefault(ch.getCoinCode(), ch.getAvgPrice());
					coinTotalUsdt += (ch.getCoinCount() * price);
				}
			}
		} catch (Exception e) {
			log.error("코인 자산 합산 중 오류", e);
		}

		// 5. 환율 적용
		double exchangeRate = 1400;
		try {
			MarketIndexDTO exDTO = indexService.getMarketIndex().stream().filter(d -> d.getName().contains("환율"))
					.findFirst().orElse(null);
			if (exDTO != null) {
				exchangeRate = Double.parseDouble(exDTO.getPrice().replace(",", ""));
			}
		} catch (Exception e) {
			log.error("환율 정보 획득 실패", e);
		}

		return (stockCash + lockedPendingCash) + stockValue + (long) (coinTotalUsdt * exchangeRate);
	}

	// 단순 조회 API 인터페이스 핸들러 모음
	public long getUserBalance(MemberDTO member) {
		return orderStockMapper.getWallet(member.getUsername());
	}

	public List<Map<String, Object>> getHoldingStockList(MemberDTO member) {
		return orderStockMapper.getHoldingList(member.getUsername());
	}

	public List<Map<String, Object>> getPendingOrders(MemberDTO member) {
		return orderStockMapper.getPendingOrders(member.getUsername());
	}

	public List<Map<String, Object>> getOrderList(MemberDTO member) {
		return orderStockMapper.getOrderList(member.getUsername());
	}

	public long getLockedPendingBuyCash(MemberDTO member) {
		List<Map<String, Object>> pendingOrders = orderStockMapper.getPendingOrders(member.getUsername());
		long locked = 0;
		for (Map<String, Object> order : pendingOrders) {
			if ("BUY".equalsIgnoreCase((String) order.get("ORDER_TYPE"))) {
				long price = ((Number) order.get("ORDER_PRICE")).longValue();
				long count = ((Number) order.get("ORDER_COUNT")).longValue();
				locked += (price * count);
			}
		}
		return locked;
	}

	@Transactional
	public boolean cancelStockOrder(MemberDTO member, long orderNo) {
		OrderStockDTO order = orderStockMapper.getOrderById(orderNo);

		if (order == null || !order.getUsername().equals(member.getUsername())) {
			log.warn("🚨 비정상적인 주문 취소 시도: 유저 {}, 주문번호 {}", member.getUsername(), orderNo);
			return false;
		}

		if (!"PENDING".equals(order.getStatus())) {
			return false;
		}

		// [매수 취소 시] 선차감했던 예수금을 다시 지갑으로 롤백
		if ("BUY".equalsIgnoreCase(order.getOrderType())) {
			long refundAmount = (long) order.getOrderPrice() * order.getOrderCount();
			Long currentWallet = orderStockMapper.getWallet(order.getUsername());
			orderStockMapper.updateWallet(order.getUsername(), currentWallet + refundAmount);
		}
		
		// [매도 취소 시] PENDING 상태에서 수량을 차감하지 않았으므로, 롤백할 수량이 없습니다.
		// (단순히 ORDER 테이블의 상태만 CANCELLED로 바꾸면 됨)

		int result = orderStockMapper.cancelPendingByStock(orderNo);
		log.info("❌ 주문 취소 완료: 유저 {}, 주문번호 {}", member.getUsername(), orderNo);
		return result > 0;
	}

	public List<Map<String, Object>> getAssetDetails(MemberDTO member) {
		List<Map<String, Object>> details = new ArrayList<>();
		if (member == null)
			return details;

		List<Map<String, Object>> stockHoldings = orderStockMapper.getHoldingList(member.getUsername());
		for (Map<String, Object> h : stockHoldings) {
			String code = (String) h.get("STOCK_CODE");
			long count = ((Number) h.get("STOCK_COUNT")).longValue();
			long avgPrice = ((Number) h.get("STOCK_PURCHASE")).longValue();
			long currentPrice = stockService.getPriceFromCache(code);
			if (currentPrice <= 0)
				currentPrice = stockService.getCurrentPrice(code);

			long totalBuy = avgPrice * count;
			long totalEval = (currentPrice > 0) ? (currentPrice * count) : totalBuy;
			double profitRate = (totalBuy == 0) ? 0 : ((double) (totalEval - totalBuy) / totalBuy) * 100;

			Map<String, Object> map = new HashMap<>();
			map.put("type", "stock");
			map.put("name", h.get("STOCK_NAME"));
			map.put("count", count);
			map.put("buyPrice", avgPrice);
			map.put("currentPrice", currentPrice);
			map.put("eval", totalEval);
			map.put("rate", String.format("%.2f", profitRate));
			details.add(map);
		}

		try {
			var coinHoldings = coinService.getHoldingList(member.getUsername());
			Map<String, Double> prices = coinMarketService.getTickerPriceMap();

			for (var ch : coinHoldings) {
				double count = ch.getCoinCount();
				double avgPrice = ch.getAvgPrice();
				double currentPrice = prices.getOrDefault(ch.getCoinCode(), avgPrice);

				double totalBuy = avgPrice * count;
				double totalEval = currentPrice * count;
				double profitRate = (totalBuy == 0) ? 0 : ((totalEval - totalBuy) / totalBuy) * 100;

				Map<String, Object> map = new HashMap<>();
				map.put("type", "coin");
				map.put("name", ch.getCoinCode().replace("USDT", ""));
				map.put("count", count);
				map.put("buyPrice", avgPrice);
				map.put("currentPrice", currentPrice);
				map.put("eval", totalEval);
				map.put("rate", String.format("%.2f", profitRate));
				details.add(map);
			}
		} catch (Exception e) {
			log.error("코인 자산 상세 조회 실패", e);
		}

		return details;
	}
}