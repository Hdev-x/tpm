package com.tj.app.market.stock;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.tj.app.member.MemberDTO;
import com.tj.app.market.stock.order.OrderStockService;
import jakarta.servlet.http.HttpSession;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Slf4j
@RestController
@RequestMapping("/stock")
public class StockController {
	
	@Autowired
    private OrderStockService orderStockService;

    @Autowired
    private WebClientService webClientService;

    @Autowired
    private StockJoinService stockJoinService;

    @Autowired
    private StockService stockService;

    @Autowired
    private KisWebSocketService kisWebSocketService;

    @Autowired
    private StockMiniChartService stockMiniChartService;

    /**
     * 📊 1. 개별 종목 차트 데이터 조회 엔드포인트
     */
    @GetMapping("/chart")
    public ResponseEntity<Map<String, Object>> getChart(
            @RequestParam(name = "code", defaultValue = "005930") String keyword,
            @RequestParam(name = "range", defaultValue = "1y") String range) {

        // 1. 코드 및 이름 확정
        String stockCode = keyword;
        String stockName = "";
        if (!keyword.matches("\\d{6}")) { 
            String cleanKeyword = keyword.replaceAll("[^a-zA-Z0-9가-힣]", "").toLowerCase();
            stockCode = stockJoinService.getCode(cleanKeyword);
            stockName = stockJoinService.getName(stockCode); 
        } else {
            stockName = stockJoinService.getName(stockCode); 
        }

        // 2. 기간 계산
        Map<String, String> periodMap = calculatePeriod(range);
        String startDate = periodMap.get("start");
        String endDate = periodMap.get("end");
        String timeframe = periodMap.get("timeframe");
        boolean isMinute = "min".equals(timeframe);

        // 3. 캐시 조회 (변수 선언 후에 실행!)
        StockChartDTO cachedData = stockService.getCachedDailyChart(stockCode, startDate, endDate, timeframe);
        if (cachedData != null) {
            log.info("📊 개별 종목 [{}] 캐시 데이터 반환", stockName);
            return buildResponse(cachedData, stockCode, stockName, isMinute);
        }
        
        // 4. 캐시가 없을 때만 API 호출
        log.info("📊 개별 종목 [{}] 순정 API 직통 호출", stockName);
        StockChartDTO data = isMinute ? webClientService.getMinuteChart(stockCode) 
                                      : webClientService.getDailyChart(stockCode, startDate, endDate, timeframe);

        if (data != null && data.getOutput2() != null && !data.getOutput2().isEmpty()) {
            // 조회 성공 시 캐시에 저장 (일봉 이상만)
            if (!isMinute) {
                stockService.putChartCache(stockCode, startDate, endDate, timeframe, data);
            }
            return buildResponse(data, stockCode, stockName, isMinute);
        }

        log.warn("⚠️ [인프라 통신 공백 확인] API 데이터 없음");
        Map<String, Object> errorResult = new HashMap<>();
        errorResult.put("message", "시세 데이터를 제공하지 않는 구간입니다.");
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResult);
    }

    // 응답 생성 공통 메서드 추가 (코드 중복 방지)
    private ResponseEntity<Map<String, Object>> buildResponse(StockChartDTO data, String stockCode, String stockName, boolean isMinute) {
        Map<String, Object> result = new HashMap<>();
        result.put("stockCode", stockCode);
        result.put("stockName", stockName);
        result.put("output2", transformToCandles(data.getOutput2(), isMinute));
        result.put("rt_cd", data.getRt_cd());
        return ResponseEntity.ok(result);
    }

    /**
     * 📅 날짜 계산 로직
     */
    private Map<String, String> calculatePeriod(String range) {
        LocalDate now = LocalDate.now();
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyyMMdd");
        Map<String, String> map = new HashMap<>();
        
        map.put("end", now.format(fmt));
        
        switch (range) {
            case "min": 
                map.put("start", now.format(fmt));
                map.put("timeframe", "min");
                break;
            case "3y":
                map.put("start", now.minusYears(3).format(fmt));
                map.put("timeframe", "W");
                break;
            case "10y":
                map.put("start", now.minusYears(10).format(fmt));
                map.put("timeframe", "M");
                break;
            case "1y":
            default:
                map.put("start", now.minusYears(1).format(fmt));
                map.put("timeframe", "D");
                break;
        }
        return map;
    }

    /**
     * 📈 API 데이터를 차트 라이브러리 규격에 맞게 변환
     */
    private List<Map<String, Object>> transformToCandles(List<StockChartDTO.ChartOutput> list, boolean isMinute) {
        List<Map<String, Object>> candles = new ArrayList<>();
        
        for (int i = list.size() - 1; i >= 0; i--) {
            StockChartDTO.ChartOutput out = list.get(i);
            if (out.getStck_bsop_date() == null || out.getStck_bsop_date().isEmpty() || out.getStck_bsop_date().equals("null")) {
                continue;
            }

            Map<String, Object> candle = new HashMap<>();
            candle.put("time", formatTimeLabel(out, isMinute));
            candle.put("open", parseDouble(out.getStck_oprc()));
            candle.put("high", parseDouble(out.getStck_hgpr()));
            candle.put("low", parseDouble(out.getStck_lwpr()));
            candle.put("close", parseDouble(out.getStck_clpr()));
            candle.put("volume", parseDouble(out.getAcml_vol())); 

            candles.add(candle);
        }
        return candles;
    }
    
    /**
     * 🔍 2. 개별 종목 현재가 단건 조회
     */
    @GetMapping("/ticker")
    public ResponseEntity<Map<String, Object>> getTicker(@RequestParam("code") String code) {
        Map<String, String> naverData = webClientService.getStockPriceFromNaver(code);

        if (naverData == null || naverData.isEmpty() || "-".equals(naverData.get("price"))) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(Map.of("error", "시세 데이터를 가져올 수 없습니다."));
        }

        Map<String, Object> output = new HashMap<>();
        output.put("stck_prpr", naverData.get("price"));
        output.put("prdy_ctrt", naverData.get("rate"));
        output.put("prdy_vrss", naverData.get("diff"));
        output.put("hts_kor_isnm", stockJoinService.getName(code));

        return ResponseEntity.ok(Map.of("output", output));
    }
    
    /**
     * 📈 3. 대시보드 메인 화면 실시간 카드용 리스트 (네이버 코스피 지수 완벽 포함)
     */
    @GetMapping("/tickers/summary")
    public ResponseEntity<Map<String, Object>> getTickersSummary() {
        // 🔄 핵심 변경: 한투 인프라 대신 네이버 코스피가 0번째로 조인된 StockService 캐시를 가져옴
        List<StockListDTO.StockListOutput> cachedData = stockService.getCachedTop100();
        
        if (cachedData == null || cachedData.isEmpty()) {
            return ResponseEntity.ok(Map.of("data", new ArrayList<>()));
        }

        List<Map<String, Object>> formattedList = new ArrayList<>();
        for (StockListDTO.StockListOutput out : cachedData) {
            Map<String, Object> item = new HashMap<>();
            item.put("stock_name", out.getHts_kor_isnm());   // 코스피 지수 및 한투 종목명 매핑
            item.put("stck_prpr", out.getMkstat_prpr());    // 지수 포인트 및 주가 매핑
            item.put("prdy_ctrt", out.getPrdy_ctrt());     // 등락률 매핑
            formattedList.add(item);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("data", formattedList);
        return ResponseEntity.ok(result);
    }
    
    private String formatTimeLabel(StockChartDTO.ChartOutput out, boolean isMinute) {
        String date = out.getStck_bsop_date();
        if (isMinute && out.getStck_cntg_hour() != null) {
            String time = out.getStck_cntg_hour();
            return String.format("%s-%s-%s %s:%s", 
                date.substring(0, 4), date.substring(4, 6), date.substring(6, 8), 
                time.substring(0, 2), time.substring(2, 4));
        }
        return String.format("%s-%s-%s", date.substring(0, 4), date.substring(4, 6), date.substring(6, 8));
    }

    private double parseDouble(String value) {
        try {
            return (value == null || value.isEmpty() || value.equals("null")) ? 0 : Double.parseDouble(value);
        } catch (NumberFormatException e) {
            return 0;
        }
    }
    
    @GetMapping("/db-list")
    public ResponseEntity<?> getDbStockList(
            @RequestParam(value = "limit", defaultValue = "0") int limit) {
        if (limit == 40) {
            return ResponseEntity.ok(withCachedPrices(stockJoinService.getTop40Stocks()));
        }
        List<Map<String, Object>> stocks = stockJoinService.getAllStocks();
        if (limit > 0 && stocks.size() > limit) {
            stocks = stocks.subList(0, limit);
        }
        return ResponseEntity.ok(withCachedPrices(stocks));
    }

    private List<Map<String, Object>> withCachedPrices(List<Map<String, Object>> stocks) {
        Map<String, Map<String, String>> priceCache = kisWebSocketService.getPriceCache();
        return stocks.stream()
                .map(stock -> {
                    Map<String, Object> item = new HashMap<>(stock);
                    String code = String.valueOf(item.get("code"));
                    Map<String, String> price = priceCache.get(code);
                    if (price != null) {
                        item.put("price", price.get("price"));
                        item.put("rate", price.get("rate"));
                        item.put("diff", price.get("diff"));
                        item.put("high", price.get("high"));
                        item.put("low", price.get("low"));
                        item.put("volume", price.get("volume"));
                    }
                    return item;
                })
                .toList();
    }

    @GetMapping("/rank")
    public ResponseEntity<?> getMarketRank(@RequestParam(value = "mode", defaultValue = "UP") String mode) {
        Map<String, Map<String, String>> priceCache = kisWebSocketService.getPriceCache();
        Map<String, String> nameCache = kisWebSocketService.getNameCache();

        if (priceCache.isEmpty()) {
            return ResponseEntity.ok(List.of());
        }

        try {
            List<Map<String, Object>> ranked = priceCache.entrySet().stream()
                .filter(e -> {
                    String rate = e.getValue().get("rate");
                    return rate != null && !rate.isEmpty() && !"-".equals(rate);
                })
                .sorted((a, b) -> {
                    try {
                        double r1 = Double.parseDouble(a.getValue().get("rate"));
                        double r2 = Double.parseDouble(b.getValue().get("rate"));
                        return "UP".equalsIgnoreCase(mode)
                            ? Double.compare(r2, r1)
                            : Double.compare(r1, r2);
                    } catch (Exception e) {
                        return 0;
                    }
                })
                .limit(40)
                .map(e -> {
                    Map<String, Object> item = new HashMap<>(e.getValue());
                    item.put("name", nameCache.getOrDefault(e.getKey(), "-"));
                    return item;
                })
                .toList();

            return ResponseEntity.ok(ranked);

        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @GetMapping("/mini-charts")
    public ResponseEntity<?> getMiniCharts(
            @RequestParam(value = "limit", defaultValue = "40") int limit) {
        return ResponseEntity.ok(stockMiniChartService.getMiniCharts(limit));
    }

    @PostMapping("/mini-charts/refresh")
    public ResponseEntity<?> refreshMiniCharts(
            @RequestParam(value = "limit", defaultValue = "40") int limit) {
        return ResponseEntity.ok(stockMiniChartService.refreshTopMiniCharts(limit));
    }

    @GetMapping("/my-asset")
    public ResponseEntity<Long> getMyTotalAsset(HttpSession session) {
        MemberDTO user = (MemberDTO) session.getAttribute("member");
        return ResponseEntity.ok(orderStockService.calculateTotalAsset(user));
    }
    
}
