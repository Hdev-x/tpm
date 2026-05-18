package com.tj.app.market.stock;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import com.tj.app.market.stock.StockListDTO.StockListOutput;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@EnableScheduling
public class StockService {

    @Autowired
    private StockJoinService stockJoinService; 
    
    @Autowired
    private WebClientService webClientService; 

    // 프론트엔드가 긁어갈 최종 인메모리 캐시 (0번: 네이버 코스피 지수, 1번~: 한투 100개 종목)
    private List<StockListOutput> top100Stocks = new CopyOnWriteArrayList<>();

    /**
     * 📊 [API 컨트롤러용] 현재 메모리에 동기화된 지수 + 종목 리스트 반환
     */
    public List<StockListOutput> getCachedTop100() {
        return this.top100Stocks;
    }
    
    /**
     * ⏲️ 15초 주기: 한투 전 종목 데이터와 네이버 코스피 단일 지수 조인 스케줄러
     */
    @Scheduled(fixedRate = 15000) 
    public void refreshTop100() {
        try {
            List<StockListOutput> combinedList = new ArrayList<>();
            
            // 1. 🎯 [네이버 코스피 '단일' 지수 피드 가로채기]
            Map<String, String> naverKospi = webClientService.getRealtimeKospiFromNaver();
            
            if (naverKospi != null && naverKospi.get("price") != null) {
                StockListOutput kospiIndexItem = new StockListOutput();
                kospiIndexItem.setHts_kor_isnm("코스피"); // 화면 전광판용 이름
                
                // 네이버에서 유입된 실전 주가 문자열 추출 및 포맷 가공
                String rawPriceStr = naverKospi.get("price").replaceAll("[^0-9.]", ""); 
                double rawPrice = Double.parseDouble(rawPriceStr);
                
                // 자릿수가 밀려 들어올 경우를 대비한 세이프 보정 연산
                if (!naverKospi.get("price").contains(".") && rawPrice > 70000.0) {
                    rawPrice = rawPrice / 100.0;
                }
                
                kospiIndexItem.setMkstat_prpr(String.format("%.2f", rawPrice)); // 스크린샷의 7516.04 반영
                kospiIndexItem.setPrdy_ctrt(naverKospi.get("rate"));             // 스크린샷의 +0.31% 반영
                
                // 0번째 인덱스 확보를 위해 리스트에 먼저 추가
                combinedList.add(kospiIndexItem);
                log.info("📈 [네이버 단일 지수 연동] KOSPI 종합지수 로딩 성공: {} ({}%)", kospiIndexItem.getMkstat_prpr(), kospiIndexItem.getPrdy_ctrt());
            }
            
            // 2. 📡 [한투 순정 전종목 리스트 수급]
            StockListDTO marketData = webClientService.getFullMarketPrices();
            
            if (marketData != null && marketData.getOutput2() != null && !marketData.getOutput2().isEmpty()) {
                // 한투가 준 순정 종목 100개를 네이버 지수 뒤에 그대로 이어 붙임
                combinedList.addAll(marketData.getOutput2());
            } else {
                // 🛡️ 장마감/모의투자 404 방어: 한투가 뻗었을 경우 기존 캐시에 저장되어 있던 주식 목록 복사해서 생명 연장
                log.warn("⚠️ 한투 종목 API 수급 제한 단계 발생 -> 기존 메모리에 살아있는 주식 데이터를 보존합니다.");
                if (this.top100Stocks != null && this.top100Stocks.size() > 1) {
                    List<StockListOutput> oldStocks = new ArrayList<>(this.top100Stocks.subList(1, this.top100Stocks.size()));
                    combinedList.addAll(oldStocks);
                }
            }
            
            // 3. 최종 결합된 리스트를 메모리에 동기화 (원자적 치환)
            if (!combinedList.isEmpty()) {
                this.top100Stocks = combinedList;
                log.info("✅ [동기화 완료] 총 {}개의 요소 캐시 업데이트 완료 (지수 1건 + 종목)", combinedList.size());
            }
            
        } catch (Exception e) {
            log.error("❌ 시세 캐시 엔진 스케줄러 루프 제어 장애: {}", e.getMessage());
        }
    }
}