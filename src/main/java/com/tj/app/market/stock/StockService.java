package com.tj.app.market.stock;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import com.tj.app.market.stock.StockListDTO.StockListOutput;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@EnableScheduling // 중요: 스케줄링 활성화
public class StockService {

    @Autowired
    private StockJoinService stockJoinService; // 만든 서비스 주입
    
    @Autowired
    private WebClientService webClientService; // 한국투자증권 API 호출 서비스 (가칭)

    // 실시간 데이터를 들고 있을 '캐시' (메모리 저장소)
    private List<StockListOutput> top100Stocks = new CopyOnWriteArrayList<>();

    // 2. [API 컨트롤러용] 현재 메모리에 있는 100개 바로 던져주기
    public List<StockListDTO.StockListOutput> getCachedTop100() {
        return this.top100Stocks;
    }
    
  //  @Scheduled(fixedRate = 15000) // 15초마다 갱신
    public void refreshTop100() {
        try {
            StockListDTO marketData = webClientService.getFullMarketPrices();
            
            if (marketData != null && marketData.getOutput2() != null) {
                // 받아온 데이터 중 상위 100개만 잘라서 캐시에 저장
                this.top100Stocks = marketData.getOutput2().stream()
                                        .limit(100)
                                        .collect(Collectors.toList());
                
                log.info("✅ 2번 방식으로 100개 종목 광속 갱신 완료!");
            }
        } catch (Exception e) {
            log.error("❌ 시세 업데이트 실패: {}", e.getMessage());
        }
    }
    
}
