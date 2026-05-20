package com.tj.app.orderStock;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.tj.app.member.MemberDTO;

import java.util.List;
import java.util.Map;

@Service
public class OrderStockService {

    @Autowired
    private OrderStockMapper orderStockMapper; 

    /**
     * 💰 [주식 주문 체결 코어 트랜잭션 수립]
     * @param member 현재 로그인한 사용자 DTO 객체
     * @param side 프론트엔드에서 보낸 매수/매도 구분 문자열 ("BUY" 또는 "SELL")
     * @param dto 프론트엔드에서 넘어온 주문 요청 객체
     * @return 체결 성공 여부 (true: 성공 / false: 잔고 부족 등 실패)
     */
    @Transactional // 🔴 트랜잭션 보장: 하나라도 에러 나면 자동 롤백
    public boolean executeStockOrder(MemberDTO member, String side, OrderStockDTO dto) {
        // 객체 내부에서 실제 아이디 문자열(username)을 추출합니다.
        String username = member.getUsername();
        
        // 안전하게 DTO 내부에 현재 로그인한 유저의 username을 세팅합니다.
        dto.setUsername(username);
        
        // 데이터 안정성을 위해 종목코드를 명시적 문자열 변수로 추출 및 트림 처리합니다.
        String stockCodeStr = String.valueOf(dto.getStockNo()).trim();
        
        // 총 주문 금액 산출 (체결 가격 * 주문 수량)
        long totalOrderAmount = (long) dto.getOrderPrice() * dto.getOrderCount();

        // ====================================================
        // [CASE 1] 매수 (BUY) 비즈니스 로직
        // ====================================================
        if ("BUY".equalsIgnoreCase(side)) {
            Long userCash = orderStockMapper.getWallet(username);
            
            if (userCash == null || userCash < totalOrderAmount) {
                System.out.println("❌ [매수 실패] 잔고 부족 또는 계정 정보 누락.");
                return false; 
            }

            // 기존 잔고에서 차감 업데이트
            orderStockMapper.updateWallet(username, userCash - totalOrderAmount);

            // 🔴 [싱크 교정]: 인터페이스 규격에 맞게 인자값을 username과 문자열 stockCodeStr로 찢어서 던집니다.
            Map<String, Object> holdingStock = orderStockMapper.getHolding(username, stockCodeStr);
            
            if (holdingStock == null || holdingStock.isEmpty()) {
                // 최초 매수 시 DTO 내부의 stockNo도 확실하게 문자열 처리 후 인서트
                dto.setStockNo(stockCodeStr);
            	orderStockMapper.insertHolding(dto);
            } else {
                long currentCount = ((Number) holdingStock.get("STOCK_COUNT")).longValue();
                long currentPurchase = ((Number) holdingStock.get("STOCK_PURCHASE")).longValue();
                
                long newCount = currentCount + dto.getOrderCount();
                long newPurchase = ((currentCount * currentPurchase) + totalOrderAmount) / newCount;
                
                dto.setStockNo(stockCodeStr);
                dto.setOrderCount(newCount);
                dto.setOrderPrice(newPurchase); 
                
                orderStockMapper.updateHolding(dto);
            }

        // ====================================================
        // [CASE 2] 매도 (SELL) 비즈니스 로직
        // ====================================================
        } else if ("SELL".equalsIgnoreCase(side)) {
            // 🔴 [싱크 교정]: 매도 검증 시에도 똑같이 인자값을 분리하여 호출합니다.
        	Map<String, Object> holdingStock = orderStockMapper.getHolding(username, stockCodeStr);
            if (holdingStock == null || holdingStock.isEmpty()) {
                System.out.println("❌ [매도 실패] 해당 주식을 보유하고 있지 않습니다.");
                return false;
            }

            long currentCount = ((Number) holdingStock.get("STOCK_COUNT")).longValue();
            long currentPurchase = ((Number) holdingStock.get("STOCK_PURCHASE")).longValue();

            if (currentCount < dto.getOrderCount()) {
                System.out.println("❌ [매도 실패] 매도 가능 수량 부족.");
                return false;
            }

            // 가용 자산 조회 후 매도 금액 합산 업데이트
            long userCash = orderStockMapper.getWallet(username);
            orderStockMapper.updateWallet(username, userCash + totalOrderAmount);

            if (currentCount == dto.getOrderCount()) {
                // 🔴 [싱크 교정]: 전량 매도 삭제 시 인터페이스 규격에 맞게 파라미터를 대조합니다.
            	orderStockMapper.deleteHolding(username, stockCodeStr);
            } else {
                long newCount = currentCount - dto.getOrderCount();
                dto.setStockNo(stockCodeStr);
                dto.setOrderCount(newCount);
                dto.setOrderPrice(currentPurchase); 
                
                orderStockMapper.updateHolding(dto);
            }
        }

        // DTO 내부의 종목 코드를 문자열로 안전하게 보정한 후 주문 이력을 남깁니다.
        dto.setStockNo(stockCodeStr);
        orderStockMapper.insertOrder(dto);
        return true;
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