package com.tj.app.market.stock.order;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.util.List;
import com.tj.app.market.stock.StockService;

/** ============================================================
 * [클래스 읽기] 미체결(PENDING) 지정가 주문을 10초마다 감시하는 스케줄러.
 *
 * [전체 흐름]
 * 10초마다 ORDER 테이블에서 PENDING 주문 전체 조회
 * → 종목별로 현재가와 지정가 비교
 * → 체결 조건 충족 시 OrderStockService.processExecution() 호출 → 즉시 체결
 *
 * [체결 조건]
 * 매수(BUY):  지정가 ≥ 현재가 → 지정가 이하에 살 수 있으므로 체결
 * 매도(SELL): 지정가 ≤ 현재가 → 지정가 이상에 팔 수 있으므로 체결
 *
 * [@Component] @Service가 아닌 일반 컴포넌트로 등록.
 *   스케줄링 전용 클래스이므로 비즈니스 로직 레이어(@Service)와 구분한다.
 *
 * [fixedDelay vs fixedRate]
 * fixedDelay = 10000: 이전 실행이 끝난 후 10초 뒤 다시 실행 (중복 실행 방지)
 * fixedRate: 이전 실행 시작부터 10초마다 실행 (느린 실행 시 중복 가능)
 * ============================================================ */
@Slf4j
@Component
public class OrderScheduler {

    @Autowired
    private OrderStockMapper orderStockMapper;

    @Autowired
    private OrderStockService orderStockService;

    @Autowired
    private StockService stockService;

    /** ============================================================
     * 10초마다 전체 미체결 주문을 조회하고 체결 조건을 확인한다.
     *
     * [실행 흐름]
     * 1. DB에서 PENDING 주문 전체 조회
     * 2. 각 주문별로 현재가 조회:
     *    - 1순위: StockService.latestPriceMap (WebSocket 실시간 캐시, API 호출 없음)
     *    - 2순위: KIS API 직접 호출 (캐시 미스 시, 700ms 딜레이 추가)
     * 3. 현재가 조회 실패 시 해당 주문 건너뜀
     * 4. 체결 조건 충족 시 processExecution() 호출
     * ============================================================ */
    @Scheduled(fixedDelay = 10000)
    public void checkPendingOrders() {
        List<OrderStockDTO> pendingList = orderStockMapper.getAllPendingOrders();

        for (OrderStockDTO dto : pendingList) {
            // [실행 흐름] 1순위: WebSocket 캐시에서 현재가 조회 (API 호출 없음)
            long currentPrice = stockService.getPriceFromCache(dto.getStockCode());

            // [실행 흐름] 2순위: 캐시 미스 시에만 KIS API 직접 호출 + 속도 제한 딜레이
            if (currentPrice <= 0) {
                currentPrice = stockService.getCurrentPrice(dto.getStockCode());
                try { Thread.sleep(700); } catch (InterruptedException e) { Thread.currentThread().interrupt(); }
            }

            if (currentPrice <= 0) {
                log.warn("종목 {} 실시간 시세 수신 불가 (건너뜀)", dto.getStockCode());
                continue;
            }

            // [실행 흐름] 체결 조건 확인
            // 매수: 지정가 ≥ 현재가 (지정가보다 싸게 살 수 있음)
            // 매도: 지정가 ≤ 현재가 (지정가보다 비싸게 팔 수 있음)
            boolean isExecutable = "BUY".equalsIgnoreCase(dto.getOrderType())
                    ? (dto.getOrderPrice() >= currentPrice)
                    : (dto.getOrderPrice() <= currentPrice);

            if (isExecutable) {
                log.info("[자동 체결] 종목: {} 주문가: {} 현재가: {}", dto.getStockCode(), dto.getOrderPrice(), currentPrice);
                orderStockService.processExecution(dto);
            }
        }
    }
}