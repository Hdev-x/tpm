package com.tj.app.market.stock.order;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.tj.app.market.stock.StockService;
import com.tj.app.member.MemberDTO;

import lombok.extern.slf4j.Slf4j;

import java.util.List;
import java.util.Map;

/** ============================================================
 * [클래스 읽기] 주식 매수/매도 주문의 전체 흐름을 처리하는 핵심 서비스.
 *
 * [주문 흐름 2단계]
 * 1. placeOrder()  : 검증·예수금 선차감·DB 기록 → 즉시 체결 가능하면 processExecution() 호출
 * 2. processExecution() : 실제 STOCK_HOLDINGS 업데이트 (수량/평단가 변경)
 *
 * [지정가 vs 시장가]
 * - 시장가: placeOrder()에서 바로 status="COMPLETED" → processExecution() 즉시 실행
 * - 지정가: status="PENDING"으로 DB에 저장 → OrderScheduler가 주기적으로 현재가 확인 후 체결
 *
 * [매수 예수금 선차감 방식]
 * 지정가 매수 주문 시 체결 전에 예수금을 먼저 차감한다.
 * 이유: 잔고 부족 상태에서 여러 주문이 중복 등록되는 것을 방지하기 위함.
 * 취소 시 차감한 금액을 복원(롤백)한다.
 *
 * [매도 미체결 처리]
 * 지정가 매도 주문 시 STOCK_HOLDINGS의 수량은 건드리지 않는다.
 * 대신 getPendingOrders()로 미체결 매도 수량을 누적해 가용 수량에서 뺀다.
 * ============================================================ */
@Service
@Slf4j
public class OrderStockService {

    @Autowired
    private OrderStockMapper orderStockMapper;

    @Autowired
    private StockService stockService;

    /** ============================================================
     * 주문 체결 처리 (STOCK_HOLDINGS 업데이트).
     * placeOrder()에서 검증·예수금 처리가 끝난 뒤 호출된다.
     *
     * [매수 체결 흐름]
     * 1. 해당 종목 첫 매수 → insertHolding() (새 행 삽입)
     * 2. 이미 보유 중 → 평단가 가중평균 재계산 후 updateHolding()
     *    평단가 = (기존보유금액 + 이번주문금액) / 총수량
     *
     * [매도 체결 흐름]
     * 1. 전량 매도 → deleteHolding() (행 삭제)
     * 2. 일부 매도 → 수량 차감 후 updateHolding()
     * 3. 매도 대금 = 체결가 × 수량 → 예수금 증가
     * ============================================================ */
    @Transactional
    public void processExecution(OrderStockDTO dto) {
        String side     = dto.getOrderType();
        String username = dto.getUsername();
        long totalOrderAmount = dto.getOrderPrice() * dto.getOrderCount();

        if ("BUY".equalsIgnoreCase(side)) {
            Map<String, Object> holdingStock = orderStockMapper.getHolding(username, dto.getStockCode());

            if (holdingStock == null || holdingStock.isEmpty()) {
                // [실행 흐름] 처음 매수 → 신규 보유 행 삽입
                orderStockMapper.insertHolding(dto);
            } else {
                long currentCount    = ((Number) holdingStock.get("STOCK_COUNT")).longValue();
                long currentPurchase = ((Number) holdingStock.get("STOCK_PURCHASE")).longValue();
                long newCount    = currentCount + dto.getOrderCount();
                // [실행 흐름] 가중평균 평단가 = (기존금액 + 신규금액) / 총수량
                long newPurchase = ((currentCount * currentPurchase) + totalOrderAmount) / newCount;

                dto.setOrderCount(newCount);
                dto.setOrderPrice(newPurchase);
                orderStockMapper.updateHolding(dto);
            }
        } else {
            // [실행 흐름] 매도 체결
            Map<String, Object> holdingStock = orderStockMapper.getHolding(username, dto.getStockCode());
            if (holdingStock == null || holdingStock.isEmpty()) {
                log.error("[체결 실패] 보유 주식이 없습니다. 유저: {}, 종목: {}", username, dto.getStockCode());
                return;
            }

            long currentCount    = ((Number) holdingStock.get("STOCK_COUNT")).longValue();
            long currentPurchase = ((Number) holdingStock.get("STOCK_PURCHASE")).longValue();

            if (currentCount < dto.getOrderCount()) {
                log.error("[체결 실패] 보유 수량 부족. 유저: {}, 보유: {}, 주문: {}", username, currentCount, dto.getOrderCount());
                return;
            }

            // [실행 흐름] 매도 대금을 예수금에 추가
            Long userCash = orderStockMapper.getWallet(username);
            orderStockMapper.updateWallet(username, userCash + totalOrderAmount);

            if (currentCount == dto.getOrderCount()) {
                // [실행 흐름] 전량 매도 → 보유 행 삭제
                orderStockMapper.deleteHolding(username, dto.getStockCode());
            } else {
                // [실행 흐름] 일부 매도 → 잔여 수량으로 업데이트, 평단가는 기존 유지
                dto.setOrderCount(currentCount - dto.getOrderCount());
                dto.setOrderPrice(currentPurchase);
                orderStockMapper.updateHolding(dto);
            }
        }

        dto.setStatus("COMPLETED");
        orderStockMapper.updateOrderStatus(dto);
    }

    /** ============================================================
     * 주문 접수 (검증·예수금 처리·DB 기록·즉시체결 판단).
     *
     * [실행 흐름 5단계]
     * 1. 파라미터 보정: username, orderType, status, stockCode 세팅
     * 2. BUY: 잔고 확인 → 예수금 선차감
     *    SELL: 보유 수량 확인 → 미체결 매도 수량 빼고 가용 수량 계산
     * 3. PENDING 상태 + 현재가 조회 성공 → 즉시 체결 조건 충족이면 status="COMPLETED"로 전환
     * 4. ORDER 테이블에 주문 기록 INSERT
     * 5. COMPLETED 상태이면 processExecution() 호출해 HOLDINGS 업데이트
     *
     * @return true=접수 성공, false=잔고/수량 부족 등 실패
     * ============================================================ */
    @Transactional
    public boolean placeOrder(MemberDTO member, String side, OrderStockDTO dto) {
        dto.setUsername(member.getUsername());
        dto.setOrderType(side);

        // [실행 흐름] status가 없으면 기본 PENDING(지정가 대기)으로 세팅
        if (dto.getStatus() == null || dto.getStatus().isBlank()) {
            dto.setStatus("PENDING");
        }

        // [실행 흐름] stockCode가 없고 stockNo가 있으면 6자리 코드로 변환
        if (dto.getStockCode() == null || dto.getStockCode().isBlank()) {
            if (dto.getStockNo() != null) {
                dto.setStockCode(String.format("%06d", dto.getStockNo()));
            } else {
                return false;
            }
        }
        dto.setStockCode(dto.getStockCode().trim());

        if ("BUY".equalsIgnoreCase(side)) {
            // [실행 흐름] 매수: 잔고 확인 → 부족하면 false → 충분하면 예수금 선차감
            long totalAmount     = dto.getOrderPrice() * dto.getOrderCount();
            long currentBalance  = orderStockMapper.getWallet(member.getUsername());

            if (currentBalance < totalAmount) {
                log.warn("[주문 실패] 잔고 부족. 유저: {}, 필요: {}, 현재: {}", member.getUsername(), totalAmount, currentBalance);
                return false;
            }
            orderStockMapper.updateWallet(member.getUsername(), currentBalance - totalAmount); // 선차감

        } else {
            // [실행 흐름] 매도: 보유 수량 확인
            Map<String, Object> holdingStock = orderStockMapper.getHolding(member.getUsername(), dto.getStockCode());
            if (holdingStock == null || holdingStock.isEmpty()) {
                log.warn("[주문 실패] 보유 주식 없음. 유저: {}, 종목: {}", member.getUsername(), dto.getStockCode());
                return false;
            }

            long totalHeldCount = ((Number) holdingStock.get("STOCK_COUNT")).longValue();

            // [실행 흐름] 이미 미체결 매도 주문이 있으면 그 수량만큼 가용 수량에서 제외
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
                log.warn("[주문 실패] 매도 가능 수량 부족. 유저: {}, 보유: {}, 미체결매도: {}, 주문: {}",
                        member.getUsername(), totalHeldCount, pendingSellCount, dto.getOrderCount());
                return false;
            }
            // [주의] PENDING 매도 시 STOCK_HOLDINGS 수량을 즉시 차감하지 않는다.
            // ORDER 테이블에 PENDING으로만 기록해 가용 수량 체크에만 사용한다.
        }

        // [실행 흐름] 3단계: 지정가 주문인데 현재가가 체결 조건을 이미 만족하면 즉시 COMPLETED로 전환
        if ("PENDING".equals(dto.getStatus())) {
            long currentPrice = stockService.getPriceFromCache(dto.getStockCode());
            if (currentPrice <= 0) currentPrice = stockService.getCurrentPrice(dto.getStockCode());

            if (currentPrice > 0) {
                // 매수: 지정가 ≥ 현재가일 때 즉시 체결 / 매도: 지정가 ≤ 현재가일 때 즉시 체결
                boolean isExecutable = "BUY".equalsIgnoreCase(side)
                        ? (dto.getOrderPrice() >= currentPrice)
                        : (dto.getOrderPrice() <= currentPrice);
                if (isExecutable) {
                    dto.setStatus("COMPLETED");
                }
            }
        }

        // [실행 흐름] 4단계: ORDER 테이블에 주문 기록
        int result = orderStockMapper.insertOrder(dto);

        // [실행 흐름] 5단계: COMPLETED 상태이면 STOCK_HOLDINGS 즉시 업데이트
        if (result > 0 && "COMPLETED".equals(dto.getStatus())) {
            processExecution(dto);
        }

        return result > 0;
    }

    /** ============================================================
     * 사용자의 주식 예수금(현금 잔고)을 조회한다.
     * ============================================================ */
    public long getUserBalance(MemberDTO member) {
        return orderStockMapper.getWallet(member.getUsername());
    }

    /** ============================================================
     * 사용자의 보유 주식 목록을 조회한다.
     * 사이드바·자산 화면에서 사용한다.
     * ============================================================ */
    public List<Map<String, Object>> getHoldingStockList(MemberDTO member) {
        return orderStockMapper.getHoldingList(member.getUsername());
    }

    /** ============================================================
     * 미체결 지정가 주문 목록을 조회한다.
     * ============================================================ */
    public List<Map<String, Object>> getPendingOrders(MemberDTO member) {
        return orderStockMapper.getPendingOrders(member.getUsername());
    }

    /** ============================================================
     * 체결 완료 거래 내역 목록을 조회한다.
     * ============================================================ */
    public List<Map<String, Object>> getOrderList(MemberDTO member) {
        return orderStockMapper.getOrderList(member.getUsername());
    }

    /** ============================================================
     * 미체결 매수 주문에 묶여 있는 예수금 합계를 계산한다.
     * AssetService에서 "잠긴 예수금"으로 총 자산에 포함시킬 때 사용한다.
     * [이유] 매수 PENDING 시 예수금을 선차감했으므로 이 금액도 자산으로 집계해야 한다.
     * ============================================================ */
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

    /** ============================================================
     * 주문 취소 처리.
     *
     * [실행 흐름]
     * 1. 주문 조회 → 본인 주문인지 확인 (타인 주문 취소 방지)
     * 2. 상태가 PENDING이 아니면 취소 불가 (이미 체결된 주문)
     * 3. 매수 취소: 선차감한 예수금 복원
     *    매도 취소: PENDING 시 수량을 건드리지 않았으므로 복원 불필요
     * 4. cancelPendingByStock()으로 상태를 CANCELED로 변경
     * ============================================================ */
    @Transactional
    public boolean cancelStockOrder(MemberDTO member, long orderNo) {
        OrderStockDTO order = orderStockMapper.getOrderById(orderNo);

        if (order == null || !order.getUsername().equals(member.getUsername())) {
            log.warn("비정상적인 주문 취소 시도: 유저 {}, 주문번호 {}", member.getUsername(), orderNo);
            return false;
        }

        if (!"PENDING".equals(order.getStatus())) {
            return false; // 이미 체결됐거나 취소된 주문
        }

        // [실행 흐름] 매수 취소 시 선차감한 예수금을 복원
        if ("BUY".equalsIgnoreCase(order.getOrderType())) {
            long refundAmount = order.getOrderPrice() * order.getOrderCount();
            Long currentWallet = orderStockMapper.getWallet(order.getUsername());
            orderStockMapper.updateWallet(order.getUsername(), currentWallet + refundAmount);
        }
        // [실행 흐름] 매도 취소: PENDING 시 수량을 차감하지 않았으므로 복원 불필요

        int result = orderStockMapper.cancelPendingByStock(orderNo);
        log.info("주문 취소 완료: 유저 {}, 주문번호 {}", member.getUsername(), orderNo);
        return result > 0;
    }
}