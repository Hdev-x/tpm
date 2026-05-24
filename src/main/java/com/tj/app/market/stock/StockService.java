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

/** ============================================================
 * [클래스 읽기] 주식 시세 인메모리 캐시와 실시간 데이터 관리를 담당하는 핵심 서비스.
 *
 * [전체 구조]
 * 1. top100Stocks: 네이버 코스피 지수를 15초마다 갱신하는 인메모리 캐시
 * 2. chartCache: 일봉 차트 데이터를 메모리에 캐시 (동일 요청 시 API 재호출 방지)
 * 3. latestPriceMap: KIS WebSocket에서 실시간으로 수신한 최신 종목 가격 저장소
 *
 * [CopyOnWriteArrayList]
 * 여러 스레드가 동시에 읽어도 안전한 리스트.
 * 쓰기(갱신) 시 내부 배열을 복사하므로 읽기 중 잠금이 없다.
 * → 15초 스케줄러가 쓰고, HTTP 요청 스레드가 읽는 동시 접근 상황에 적합.
 *
 * [ConcurrentHashMap]
 * 여러 스레드에서 동시에 put/get해도 안전한 Map.
 * 일반 HashMap은 멀티스레드 환경에서 데이터 손상이 발생할 수 있다.
 * ============================================================ */
@Slf4j
@Service
@EnableScheduling
public class StockService {

    @Autowired
    private StockJoinService stockJoinService;

    @Autowired
    private WebClientService webClientService;

    // [실행 흐름] ObjectProvider: KisWebSocketService를 지연 조회(순환 의존성 방지)
    @Autowired
    private ObjectProvider<KisWebSocketService> kisWebSocketProvider;

    // [실행 흐름] application.properties의 app.stock.websocket.enabled 값 주입 (기본 false)
    @Value("${app.stock.websocket.enabled:false}")
    private boolean stockWebSocketEnabled;

    /** ============================================================
     * 서버 시작 시 KIS WebSocket 연결을 초기화한다.
     * app.stock.websocket.enabled=false 이면 WebSocket 연결을 건너뛴다.
     * ============================================================ */
    @PostConstruct
    public void init() {
        if (!stockWebSocketEnabled) {
            log.info("주식 WebSocket 자동 연결이 비활성화되어 있습니다.");
            return;
        }
        log.info("앱 시작 - KIS WebSocket 연결 초기화");
        kisWebSocketProvider.getObject().connect();
    }

    // [실행 흐름] 코스피 지수 인메모리 캐시 (HTTP 요청 시 DB나 API 대신 이 리스트를 반환)
    private List<StockListOutput> top100Stocks = new CopyOnWriteArrayList<>();

    /** ============================================================
     * 현재 메모리에 캐시된 코스피 지수 + 종목 리스트를 반환한다.
     * Controller가 이 메서드를 호출해 JSON으로 내려보낸다.
     * ============================================================ */
    public List<StockListOutput> getCachedTop100() {
        return this.top100Stocks;
    }

    /** ============================================================
     * 15초마다 네이버에서 코스피 지수를 가져와 인메모리 캐시를 갱신한다.
     *
     * [실행 흐름]
     * 1. WebClientService.getRealtimeKospiFromNaver() → { price, rate } Map
     * 2. 네이버 응답값은 ×100 정수로 오는 경우가 있어 70,000 초과 시 ÷100 보정
     * 3. StockListOutput에 이름·가격·등락률 세팅 후 top100Stocks 교체
     *
     * [CopyOnWriteArrayList 교체]
     * this.top100Stocks = combinedList → 참조를 원자적으로 교체.
     * 기존 리스트를 읽고 있는 스레드는 이전 참조를 유지하므로 안전.
     * ============================================================ */
    @Scheduled(fixedRate = 15000)
    public void refreshTop100() {
        try {
            List<StockListOutput> combinedList = new ArrayList<>();

            // [실행 흐름] 네이버 실시간 코스피 지수 조회
            Map<String, String> naverKospi = webClientService.getRealtimeKospiFromNaver();

            if (naverKospi != null && naverKospi.get("price") != null) {
                StockListOutput kospiIndexItem = new StockListOutput();
                kospiIndexItem.setHts_kor_isnm("코스피");

                // [실행 흐름] 숫자 외 문자 제거 후 double 변환
                String rawPriceStr = naverKospi.get("price").replaceAll("[^0-9.]", "");
                double rawPrice = Double.parseDouble(rawPriceStr);

                // [실행 흐름] 소수점 없는 정수가 70,000 초과면 ×100 된 값 → ÷100 보정
                if (!naverKospi.get("price").contains(".") && rawPrice > 70000.0) {
                    rawPrice = rawPrice / 100.0;
                }

                kospiIndexItem.setMkstat_prpr(String.format("%.2f", rawPrice));
                kospiIndexItem.setPrdy_ctrt(naverKospi.get("rate"));
                combinedList.add(kospiIndexItem);
                log.info("[네이버 단일 지수 연동] KOSPI: {} ({}%)", kospiIndexItem.getMkstat_prpr(), kospiIndexItem.getPrdy_ctrt());
            }

            if (!combinedList.isEmpty()) {
                this.top100Stocks = combinedList; // [실행 흐름] 캐시 원자적 교체
            }

        } catch (Exception e) {
            log.error("시세 캐시 갱신 실패: {}", e.getMessage());
        }
    }

    /** ============================================================
     * 종목 코드로 현재가를 조회한다.
     *
     * [실행 흐름 - 2단계 조회]
     * 1단계: top100Stocks 캐시에서 해당 종목 검색 (빠름)
     * 2단계: 캐시에 없으면 KIS API 직접 호출 (느림, API 호출 비용 발생)
     * 실패 시 -1 반환 → 호출 측에서 -1 여부로 실패 판단
     * ============================================================ */
    public long getCurrentPrice(String stockCode) {
        // [실행 흐름] 1단계: 인메모리 캐시 탐색
        for (StockListOutput stock : top100Stocks) {
            if (stock.getMkstat_shrn_iscd() != null && stock.getMkstat_shrn_iscd().equals(stockCode)) {
                String priceStr = stock.getMkstat_prpr().replaceAll("[^0-9]", "");
                long price = Long.parseLong(priceStr);
                return (price > 0) ? price : -1;
            }
        }

        // [실행 흐름] 2단계: 캐시 미스 → KIS API 직접 호출
        try {
            StockPriceDTO dto = webClientService.getCurrentPrice(stockCode);
            if (dto != null && "0".equals(dto.getRt_cd()) && dto.getOutput() != null) {
                String priceStr = dto.getOutput().getStck_prpr();
                if (priceStr != null && !priceStr.isEmpty()) {
                    long price = Long.parseLong(priceStr);
                    return (price > 0) ? price : -1;
                }
            }
        } catch (Exception e) {
            log.error("API 조회 중 예외 발생 - 종목: {}", stockCode);
        }

        return -1; // 조회 실패
    }

    // [실행 흐름] 일봉 차트 데이터 캐시: 동일 종목+기간+타임프레임 재요청 시 API 생략
    private Map<String, StockChartDTO> chartCache = new ConcurrentHashMap<>();

    /** ============================================================
     * 일봉 차트 캐시에서 데이터를 조회한다.
     * 분봉(timeframe="min")은 캐시하지 않는다(실시간 변동이 크기 때문).
     * ============================================================ */
    public StockChartDTO getCachedDailyChart(String stockCode, String startDate, String endDate, String timeframe) {
        if ("min".equals(timeframe)) return null; // 분봉은 캐시 없음
        String cacheKey = stockCode + "_" + startDate + "_" + endDate + "_" + timeframe;
        return chartCache.get(cacheKey);
    }

    /** ============================================================
     * 일봉 차트 데이터를 캐시에 저장한다.
     * 분봉이거나 dto가 null이면 저장하지 않는다.
     * ============================================================ */
    public void putChartCache(String stockCode, String startDate, String endDate, String timeframe, StockChartDTO dto) {
        if (dto == null || "min".equals(timeframe)) return;
        String cacheKey = stockCode + "_" + startDate + "_" + endDate + "_" + timeframe;
        chartCache.put(cacheKey, dto);
    }

    // [실행 흐름] KIS WebSocket에서 수신한 실시간 종목 가격 저장 (종목코드 → 가격)
    private Map<String, Long> latestPriceMap = new ConcurrentHashMap<>();

    /** ============================================================
     * WebSocket 실시간 가격 캐시에서 종목의 최신 가격을 반환한다.
     * WebSocket 수신 전이거나 해당 종목이 없으면 0 반환.
     * ============================================================ */
    public long getPriceFromCache(String stockCode) {
        return this.latestPriceMap.getOrDefault(stockCode, 0L);
    }

    /** ============================================================
     * KisWebSocketService에서 실시간 가격을 수신할 때 호출된다.
     * latestPriceMap에 최신 가격을 저장한다.
     * ============================================================ */
    public void updatePrice(String stockCode, long price) {
        latestPriceMap.put(stockCode, price);
    }
}
