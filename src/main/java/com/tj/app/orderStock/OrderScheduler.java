package com.tj.app.orderStock;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.util.List;
import com.tj.app.market.stock.StockService;

@Slf4j
@Component
public class OrderScheduler {

    @Autowired
    private OrderStockMapper orderStockMapper;
    
    @Autowired
    private OrderStockService orderStockService;
    
    @Autowired
    private StockService stockService;

    // 50초마다 모든 미체결 주문을 감시합니다.
    @Scheduled(fixedDelay = 90000)
    public void checkPendingOrders() {
        List<OrderStockDTO> pendingList = orderStockMapper.getAllPendingOrders();
        
        for (OrderStockDTO dto : pendingList) {
            // 1. API 호출 대신 메모리 캐시부터 조회 (API 호출 0회!)
            long currentPrice = stockService.getPriceFromCache(dto.getStockCode());
            
            // 2. 캐시에 가격 정보가 없는 경우(웹소켓 미연결 등)에만 예외적으로 1번만 API 호출
            if (currentPrice <= 0) {
                currentPrice = stockService.getCurrentPrice(dto.getStockCode());
                // API 호출 시에는 예의상 잠시 대기
                try { Thread.sleep(700); } catch (InterruptedException e) { Thread.currentThread().interrupt(); }
            }
            
            if (currentPrice <= 0) {
                log.warn("⚠️ 종목 {} 실시간 시세 수신 불가 (건너뜀)", dto.getStockCode());
                continue; 
            }
            
            // 3. 체결 로직
            boolean isExecutable = ("BUY".equalsIgnoreCase(dto.getOrderType())) ? 
                                   (dto.getOrderPrice() >= currentPrice) : 
                                   (dto.getOrderPrice() <= currentPrice);
            
            if (isExecutable) {
                log.info("🎯 [자동 체결] 종목: {} 주문가: {} 현재가: {}", dto.getStockCode(), dto.getOrderPrice(), currentPrice);
                orderStockService.processExecution(dto);
            }
        }
    }
}