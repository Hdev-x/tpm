package com.tj.app.market.stock;

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
@EnableScheduling // 스케줄링 활성화
public class StockService {

    @Autowired
    private WebClientService webClientService; // 네이버 및 한투 연동 클라이언트
    
    // 💡 프론트엔드 유저들에게 4초 주기로 서빙할 인메모리 Thread-Safe 캐시 저장소
    private List<StockListOutput> top100Stocks = new CopyOnWriteArrayList<>();

    /**
     * [API 컨트롤러 전용] 현재 메모리에 동기화된 클린 시세 리스트 즉시 반환 창구
     */
    public List<StockListOutput> getCachedTop100() {
        return this.top100Stocks;
    }
    
    /**
     * ⏲️ 4초 주기: 네이버 실전 주가 피드를 가로채 자릿수 보정 후 캐시 적재 (가상 백업 완전 제거)
     */
    @Scheduled(fixedRate = 4000) 
    public void refreshTop100() {
        try {
            // 네이버 금융 실시간 지수 수급
            Map<String, String> naverKospi = webClientService.getRealtimeKospiFromNaver();
            
            // 🛡️ [가상 데이터 가드 파괴] 네이버 피드가 유실되었거나 정상 응답이 아니면 캐시를 갱신하지 않고 즉시 리턴
            if (naverKospi == null || naverKospi.get("price") == null || "7565.40".equals(naverKospi.get("price"))) {
                log.warn("⚠️ 네이버 금융 피드 수급 실패 또는 우회 방어막 감지 -> 인메모리 싱크를 스킵합니다.");
                return;
            }
            
            StockListOutput kospiItem = new StockListOutput();
            kospiItem.setHts_kor_isnm("코스피");
            
            // 🔴 [순정 원복] 네이버 금융에서 유입된 실전 주가 문자열 추출
            String rawPriceStr = naverKospi.get("price").replaceAll("[^0-9.]", ""); 
            double rawPrice = Double.parseDouble(rawPriceStr);
            
            // 💡 만약 네이버 데이터가 소수점 없는 통정수(예: 755239)로 유입될 경우에만 100을 나눕니다.
            if (!naverKospi.get("price").contains(".") && rawPrice > 70000.0) {
                rawPrice = rawPrice / 100.0;
            }
            
            // 최종 대역 스펙 문자열로 포맷팅 완료
            String formattedPrice = String.format("%.2f", rawPrice);
            kospiItem.setMkstat_prpr(formattedPrice); 
            kospiItem.setPrdy_ctrt(naverKospi.get("rate")); // 등락률 매핑 (+0.79%)
            
            // 캐시 스왑 버퍼 레이아웃 구성
            List<StockListOutput> tempSummary = new java.util.ArrayList<>();
            tempSummary.add(kospiItem);
            
            // 최종 메모리 싱크 완료 (원자적 치환)
            this.top100Stocks = tempSummary;
            
            log.debug("🚀 [인메모리 싱크 완수] KOSPI 캐시 동기화 완료 -> {} ({}%)", 
                    kospiItem.getMkstat_prpr(), kospiItem.getPrdy_ctrt());
            
        } catch (Exception e) {
            log.error("❌ 실시간 시세 캐시 엔진 동기화 실패: {}", e.getMessage());
        }
    }
}