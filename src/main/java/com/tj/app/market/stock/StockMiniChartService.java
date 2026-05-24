package com.tj.app.market.stock;

import lombok.extern.slf4j.Slf4j;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** ============================================================
 * [클래스 읽기] 주식 종목 미니차트(1년 종가 라인차트)용 데이터를 관리하는 서비스.
 *
 * [전체 흐름]
 * 1. 서버 시작 시(@PostConstruct) 3초 후 Yahoo Finance에서 상위 40개 종목 1년치 종가 수집
 * 2. 매일 16:30(평일)에 @Scheduled로 자동 갱신 (장 마감 후)
 * 3. Controller 요청 시 DB에 캐시된 데이터를 바로 반환 → 외부 API 실시간 호출 없음
 *
 * [Yahoo Finance 심볼 규칙]
 * 한국 코스피 종목: {코드}.KS (예: 005930.KS = 삼성전자)
 * 한국 코스닥 종목: {코드}.KQ (예: 247540.KQ)
 * KS로 먼저 시도, 빈 결과면 KQ로 재시도한다.
 *
 * [auto-refresh 설정]
 * application.properties의 app.stock.mini-chart.auto-refresh 값으로
 * 개발 환경에서 외부 API 호출을 끌 수 있다 (기본값 true).
 * ============================================================ */
@Slf4j
@Service
public class StockMiniChartService {

    // [실행 흐름] Yahoo Finance에서 1년치 일봉 데이터 조회용 WebClient
    private final WebClient yahooClient = WebClient.builder()
            .baseUrl("https://query1.finance.yahoo.com")
            .defaultHeader("User-Agent", "Mozilla/5.0")
            .build();

    @Autowired
    private StockJoinMapper stockJoinMapper;

    @Autowired
    private StockDailyPriceMapper stockDailyPriceMapper;

    // [실행 흐름] application.properties에서 주입, 기본값 true (없으면 true)
    @Value("${app.stock.mini-chart.auto-refresh:true}")
    private boolean autoRefresh;

    /** ============================================================
     * 서버 시작 후 3초 지연 뒤 미니차트 데이터를 초기 수집한다.
     *
     * [@PostConstruct] 빈 생성 완료 직후 한 번만 실행되는 메서드.
     * [3초 지연 이유] 서버 완전 기동(DB 연결, Mapper 초기화 등)을 기다리기 위함.
     * [데몬 스레드] main 스레드가 종료되면 함께 종료되는 백그라운드 스레드.
     *   서버 종료 시 미니차트 수집이 완료되지 않아도 강제 종료된다.
     * ============================================================ */
    @PostConstruct
    public void init() {
        if (!autoRefresh) return;

        Thread refreshThread = new Thread(() -> {
            try {
                Thread.sleep(3000); // [실행 흐름] 서버 기동 완료 대기
                refreshTopMiniCharts(40);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } catch (Exception e) {
                log.warn("미니차트 초기 수집 실패: {}", e.getMessage());
            }
        }, "stock-mini-chart-refresh");
        refreshThread.setDaemon(true); // 데몬 스레드: JVM 종료 시 같이 종료
        refreshThread.start();
    }

    /** ============================================================
     * 매일 평일 16:30(서울 시간)에 미니차트 데이터를 자동 갱신한다.
     * 한국 주식 장 마감(15:30) 후 최종 종가가 확정되므로 16:30에 수집한다.
     * ============================================================ */
    @Scheduled(cron = "0 30 16 * * MON-FRI", zone = "Asia/Seoul")
    public void refreshDailyMiniCharts() {
        if (!autoRefresh) return;
        log.info("주식 미니차트 일일 갱신을 시작합니다.");
        refreshTopMiniCharts(40);
    }

    /** ============================================================
     * DB에 저장된 미니차트 데이터를 종목 코드별로 반환한다.
     *
     * [반환 구조]
     * { "005930": [ {"time":"2024-06-01","close":70000}, ... ], "000660": [...] }
     * LinkedHashMap: 삽입 순서를 유지해 종목 순서가 바뀌지 않도록 한다.
     * ============================================================ */
    public Map<String, List<Map<String, Object>>> getMiniCharts(int limit) {
        List<Map<String, Object>> stocks = getTopStocks(limit);
        Map<String, List<Map<String, Object>>> result = new LinkedHashMap<>();

        for (Map<String, Object> stock : stocks) {
            String code = String.valueOf(stock.get("code"));
            // [실행 흐름] DB에서 1년치 종가 조회 → 미니차트 포인트 형식으로 변환
            result.put(code, toMiniChartPoints(stockDailyPriceMapper.findOneYearByStockCode(code)));
        }

        return result;
    }

    /** ============================================================
     * Yahoo Finance에서 상위 N개 종목의 1년치 종가를 수집해 DB에 UPSERT한다.
     *
     * [실행 흐름]
     * 1. 종목 코드 목록 조회
     * 2. 각 종목별 Yahoo API 호출 → DB UPSERT
     * 3. Thread.sleep(700): API 과부하 방지용 요청 간 딜레이
     * 4. 성공/실패 카운트를 Map으로 반환
     * ============================================================ */
    public Map<String, Object> refreshTopMiniCharts(int limit) {
        List<Map<String, Object>> stocks = getTopStocks(limit);
        int success = 0;
        int failed = 0;

        for (Map<String, Object> stock : stocks) {
            String code = String.valueOf(stock.get("code"));
            try {
                List<StockDailyPriceDTO> prices = fetchYahooOneYear(code);
                for (StockDailyPriceDTO price : prices) {
                    stockDailyPriceMapper.upsert(price); // [실행 흐름] 이미 있으면 덮어쓰기(UPSERT)
                }
                if (!prices.isEmpty()) success++;
                else failed++;
                Thread.sleep(700); // [실행 흐름] 연속 API 호출 방지 (Rate Limit 대응)
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            } catch (Exception e) {
                failed++;
                log.warn("미니차트 수집 실패 [{}]: {}", code, e.getMessage());
            }
        }

        return Map.of(
                "requested", stocks.size(),
                "success", success,
                "failed", failed
        );
    }

    /** ============================================================
     * DB에서 상위 N개 종목 목록을 가져온다.
     * limit이 실제 종목 수보다 작으면 subList로 잘라낸다.
     * ============================================================ */
    private List<Map<String, Object>> getTopStocks(int limit) {
        List<Map<String, Object>> stocks = stockJoinMapper.findTop40Stocks();
        if (limit > 0 && stocks.size() > limit) {
            return stocks.subList(0, limit);
        }
        return stocks;
    }

    /** ============================================================
     * StockDailyPriceDTO 리스트를 차트용 { time, close } 포인트 리스트로 변환한다.
     * JS 차트 라이브러리(Lightweight Charts 등)가 요구하는 형식에 맞춘다.
     * ============================================================ */
    private List<Map<String, Object>> toMiniChartPoints(List<StockDailyPriceDTO> prices) {
        List<Map<String, Object>> points = new ArrayList<>();
        for (StockDailyPriceDTO price : prices) {
            points.add(Map.of(
                    "time",  price.getTradeDate().toString(), // "2024-06-01" 형식
                    "close", price.getClosePrice()
            ));
        }
        return points;
    }

    /** ============================================================
     * 종목 코드로 Yahoo Finance에서 1년치 종가를 조회한다.
     * 코스피(.KS) 먼저 시도 → 결과 없으면 코스닥(.KQ)으로 재시도.
     * ============================================================ */
    private List<StockDailyPriceDTO> fetchYahooOneYear(String code) {
        List<StockDailyPriceDTO> ks = fetchYahooOneYear(code, code + ".KS");
        if (!ks.isEmpty()) return ks;
        return fetchYahooOneYear(code, code + ".KQ"); // [실행 흐름] KS 실패 시 KQ로 폴백
    }

    /** ============================================================
     * Yahoo Finance v8 API로 지정 심볼의 1년치 일봉 데이터를 조회해
     * StockDailyPriceDTO 리스트로 변환한다.
     *
     * [실행 흐름]
     * 1. API 응답 구조: chart.result[0].timestamp[], indicators.quote[0].close[]
     * 2. timestamp = Unix 타임스탬프(초) → LocalDate(서울 시간대) 변환
     * 3. close[i]가 null인 날(휴장일 등)은 건너뜀
     * ============================================================ */
    @SuppressWarnings("unchecked")
    private List<StockDailyPriceDTO> fetchYahooOneYear(String code, String symbol) {
        Map<String, Object> response = yahooClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/v8/finance/chart/{symbol}")
                        .queryParam("range", "1y")
                        .queryParam("interval", "1d")
                        .build(symbol))
                .retrieve()
                .bodyToMono(Map.class)
                .block(Duration.ofSeconds(8));

        if (response == null) return List.of();

        Map<String, Object> chart = (Map<String, Object>) response.get("chart");
        if (chart == null) return List.of();

        List<Map<String, Object>> results = (List<Map<String, Object>>) chart.get("result");
        if (results == null || results.isEmpty()) return List.of();

        Map<String, Object> result = results.get(0);
        List<Number> timestamps  = (List<Number>) result.get("timestamp");        // Unix 초 타임스탬프 배열
        Map<String, Object> indicators = (Map<String, Object>) result.get("indicators");
        if (timestamps == null || indicators == null) return List.of();

        List<Map<String, Object>> quoteList = (List<Map<String, Object>>) indicators.get("quote");
        if (quoteList == null || quoteList.isEmpty()) return List.of();

        Map<String, Object> quote = quoteList.get(0);
        List<Number> closes  = (List<Number>) quote.get("close");   // 종가 배열
        List<Number> volumes = (List<Number>) quote.get("volume");  // 거래량 배열
        if (closes == null) return List.of();

        List<StockDailyPriceDTO> prices = new ArrayList<>();
        int size = Math.min(timestamps.size(), closes.size());
        ZoneId seoul = ZoneId.of("Asia/Seoul");

        for (int i = 0; i < size; i++) {
            Number close = closes.get(i);
            if (close == null) continue; // [실행 흐름] 휴장일 등 null 종가 건너뜀

            StockDailyPriceDTO dto = new StockDailyPriceDTO();
            dto.setStockCode(code);
            // [실행 흐름] Unix 초 타임스탬프 → LocalDate (서울 시간대 기준 변환)
            dto.setTradeDate(LocalDate.ofInstant(Instant.ofEpochSecond(timestamps.get(i).longValue()), seoul));
            dto.setClosePrice(BigDecimal.valueOf(close.doubleValue()));

            if (volumes != null && i < volumes.size() && volumes.get(i) != null) {
                dto.setVolume(BigDecimal.valueOf(volumes.get(i).longValue()));
            }

            prices.add(dto);
        }

        return prices;
    }
}
