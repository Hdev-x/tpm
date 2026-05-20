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
    @Scheduled(fixedRate = 50000)
    public void checkPendingOrders() {
        // 1. 모든 미체결 주문 조회 (매퍼에 getAllPendingOrders 쿼리 필요)
        List<OrderStockDTO> pendingList = orderStockMapper.getAllPendingOrders();
        
        for (OrderStockDTO dto : pendingList) {
            long currentPrice = stockService.getCurrentPrice(dto.getStockCode());
            
            // 2. 현재가가 주문가에 도달했는지 확인
            boolean isExecutable = ("BUY".equalsIgnoreCase(dto.getOrderType())) ? 
                                   (dto.getOrderPrice() >= currentPrice) : 
                                   (dto.getOrderPrice() <= currentPrice);
            
            if (isExecutable) {
                log.info("🎯 [자동 체결] 종목: {} 주문가: {} 현재가: {}", dto.getStockCode(), dto.getOrderPrice(), currentPrice);
                
                // 3. 체결 로직 수행 (기존 로직 재사용을 위해 서비스에 분리해둔 메서드 활용)
                orderStockService.processExecution(dto);
            }
        }
    }
}