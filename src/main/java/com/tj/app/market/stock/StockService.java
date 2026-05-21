package com.tj.app.market.stock;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

import jakarta.annotation.PostConstruct;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
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

    @Autowired
    private ObjectProvider<KisWebSocketService> kisWebSocketProvider;

    @PostConstruct
    public void init() {
        if (!stockWebSocketEnabled) {
            log.info("주식 WebSocket 자동 연결이 비활성화되어 있습니다.");
            return;
        }
        log.info("🚀 앱 시작 - KIS WebSocket 연결 초기화");
        
        // ObjectProvider를 통해 안전하게 객체를 가져와서 연결합니다.
        kisWebSocketProvider.getObject().connect();
    }

    @Value("${app.stock.websocket.enabled:false}")
    private boolean stockWebSocketEnabled;

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
                
                kospiIndexItem.setMkstat_prpr(String.format("%.2f", rawPrice)); // 실시간 지수 반영
                kospiIndexItem.setPrdy_ctrt(naverKospi.get("rate"));             // 실시간 등락률 반영
                
                // 최종 메모리 교체를 위해 리스트에 담기
                combinedList.add(kospiIndexItem);
                log.info("📈 [네이버 단일 지수 연동] KOSPI 종합지수 로딩 성공: {} ({}%)", kospiIndexItem.getMkstat_prpr(), kospiIndexItem.getPrdy_ctrt());
            }
            
            // 3. 최종 결합된 리스트를 메모리에 동기화 (원자적 치환)
            if (!combinedList.isEmpty()) {
                this.top100Stocks = combinedList;
                log.info("✅ [동기화 완료] 총 1개의 요소 캐시 업데이트 완료 (순정 지수 1건)");
            }
            
        } catch (Exception e) {
            log.error("❌ 시세 캐시 엔진 스케줄러 루프 제어 장애: {}", e.getMessage());
        }
    }
    
    public long getCurrentPrice(String stockCode) {
        // 1. [메모리 탐색] 이미 캐싱된 데이터가 있는지 먼저 확인
        for (StockListOutput stock : top100Stocks) {
            if (stock.getMkstat_shrn_iscd() != null && stock.getMkstat_shrn_iscd().equals(stockCode)) {
                String priceStr = stock.getMkstat_prpr().replaceAll("[^0-9]", "");
                long price = Long.parseLong(priceStr);
                return (price > 0) ? price : -1;
            }
        }

        // 2. [메모리에 없을 때] API 호출
        try {
            StockPriceDTO dto = webClientService.getCurrentPrice(stockCode);
            
            // 🚨 널 체크와 성공 코드(rt_cd == "0") 확인
            if (dto != null && "0".equals(dto.getRt_cd()) && dto.getOutput() != null) {
                String priceStr = dto.getOutput().getStck_prpr();
                if (priceStr != null && !priceStr.isEmpty()) {
                    long price = Long.parseLong(priceStr);
                    return (price > 0) ? price : -1;
                }
            }
        } catch (Exception e) {
            log.error("❌ API 조회 중 예외 발생 - 종목: {}", stockCode);
        }
        
        return -1; // 실패/데이터 없음 시 -1 반환
    }
    
    private Map<String, StockChartDTO> chartCache = new ConcurrentHashMap<>();

    public StockChartDTO getCachedDailyChart(String stockCode, String startDate, String endDate, String timeframe) {
        // 분봉은 캐시하지 않거나 별도 처리 (여기서는 일봉 이상만 캐시)
        if ("min".equals(timeframe)) return null;

        String cacheKey = stockCode + "_" + startDate + "_" + endDate + "_" + timeframe;
        return chartCache.get(cacheKey);
    }

    public void putChartCache(String stockCode, String startDate, String endDate, String timeframe, StockChartDTO dto) {
        if (dto == null || "min".equals(timeframe)) return;
        String cacheKey = stockCode + "_" + startDate + "_" + endDate + "_" + timeframe;
        chartCache.put(cacheKey, dto);
    }

    public long getPriceFromCache(String stockCode) {
        // WebSocket 등으로 유입된 최신 실시간가 리턴
        return this.latestPriceMap.getOrDefault(stockCode, 0L);
    }
    
 // 실시간 가격을 저장하는 맵
    private Map<String, Long> latestPriceMap = new ConcurrentHashMap<>();

    // 웹소켓으로부터 가격을 받아 업데이트하는 메서드 (KisWebSocketService에서 호출하게 만드세요)
    public void updatePrice(String stockCode, long price) {
        latestPriceMap.put(stockCode, price);
    }
}
