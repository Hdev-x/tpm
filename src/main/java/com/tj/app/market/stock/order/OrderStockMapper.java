package com.tj.app.market.stock.order;

import java.util.List;
import java.util.Map;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface OrderStockMapper {

	// 1. 가용 잔고 조회
	long getWallet(@Param("username") String username);

	// 2. 가용 잔고 업데이트
	int updateWallet(@Param("username") String username, @Param("cash") long cash);

	// 3. 보유 주식 단건 조회 (★ 서비스단의 getHolding(username, stockNoStr) 호출과 100% 일치)
	Map<String, Object> getHolding(@Param("username") String username, @Param("stockCode") String stockCode);

	// 4. 우측 사이드바 보유 자산 목록 조회
	List<Map<String, Object>> getHoldingList(@Param("username") String username);

	// 5. 보유 자산 최초 추가
	int insertHolding(OrderStockDTO dto);

	// 6. 보유 자산 수량 및 평단가 업데이트
	int updateHolding(OrderStockDTO dto);

	// 7. 보유 자산 전량 매도 시 행 삭제
	int deleteHolding(@Param("username") String username, @Param("stockCode") String stockCode);

	// 8. 주식 트레이딩 거래 주문 이력 생성
	int insertOrder(OrderStockDTO dto);

	// 9. 체결 완료 거래 내역 리스트 조회
	List<Map<String, Object>> getOrderList(@Param("username") String username);

	// 10. 미체결 지정가 예약 주문 리스트 조회
	List<Map<String, Object>> getPendingOrders(@Param("username") String username);

	// 11. 특정 주식 미체결 예약 주문 일괄 취소
	int cancelPendingByStock(@Param("orderNo") long orderNo);

	// 12. [스케줄러용] 전체 미체결 주문 목록 조회
	List<OrderStockDTO> getAllPendingOrders();

	// 13. [스케줄러용] 주문 상태 업데이트 (PENDING -> COMPLETED)
	int updateOrderStatus(OrderStockDTO dto);

	// 14. [주문 취소용] 주문 번호로 주문 상세 조회
	OrderStockDTO getOrderById(@Param("orderId") long orderNo);
}