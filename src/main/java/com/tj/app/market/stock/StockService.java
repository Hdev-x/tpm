package com.tj.app.market.stock;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

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
    private List<StockPriceDTO> top100Stocks = new CopyOnWriteArrayList<>();

    // 2. [API 컨트롤러용] 현재 메모리에 있는 100개 바로 던져주기
    public List<StockPriceDTO> getCachedTop100() {
        return this.top100Stocks;
    }
    
    @Scheduled(fixedRate = 3000)
    public void refreshTop100() {
        try {
            // 1. 테스트용 종목 리스트 (나중에 100개로 확장)
            List<String> codes = Arrays.asList("005930", "000660", "035420"); 
            List<StockPriceDTO> newList = new CopyOnWriteArrayList<>();

            for (String code : codes) {
                StockPriceDTO priceDTO = webClientService.getCurrentPrice(code);
                if (priceDTO != null) {
                    // TODO: 여기에 종목명(삼성전자 등)을 넣어주는 로직을 추가하면 더 좋음
                    newList.add(priceDTO);
                }
                // API 호출 제한을 피하기 위해 아주 잠깐의 쉬는 시간 (선택)
                Thread.sleep(100); 
            }
            
            // 2. 전체 리스트 교체 (원자적 교체)
            this.top100Stocks = newList;
            log.info("🚀 실시간 시세 {}건 업데이트 완료", top100Stocks.size());

        } catch (Exception e) {
            log.error("❌ 시세 업데이트 실패: {}", e.getMessage());
        }
    }
    
}
