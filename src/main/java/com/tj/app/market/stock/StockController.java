package com.tj.app.market.stock;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Slf4j
@RestController
@RequestMapping("/stock")
public class StockController {

    @Autowired
    private WebClientService webClientService;
    
    @Autowired
    private StockJoinService stockJoinService;

    // 🎯 네이버 지수가 합성된 캐시 데이터 수급을 위해 StockService 주입
    @Autowired
    private StockService stockService;

    /**
     * 📊 1. 개별 종목 차트 데이터 조회 엔드포인트
     */
    @GetMapping("/chart")
    public ResponseEntity<Map<String, Object>> getChart(
            @RequestParam(name = "code", defaultValue = "005930") String keyword,
            @RequestParam(name = "range", defaultValue = "1y") String range) {

        String stockCode = keyword;
        String stockName = "";
        if (!keyword.matches("\\d{6}")) { 
            String cleanKeyword = keyword.replaceAll("[^a-zA-Z0-9가-힣]", "").toLowerCase();
            stockCode = stockJoinService.getCode(cleanKeyword);
            stockName = stockJoinService.getName(stockCode); 
        } else {
            stockCode = keyword;
            stockName = stockJoinService.getName(stockCode); 
        }

        if (stockName == null || stockName.equals("알 수 없는 종목")) {
            stockName = "종목명 없음";
        }

        Map<String, String> periodMap = calculatePeriod(range);
        String startDate = periodMap.get("start");
        String endDate = periodMap.get("end");
        String timeframe = periodMap.get("timeframe");

        StockChartDTO data = null;
        boolean isMinute = "min".equals(timeframe);

        if (isMinute) {
            log.info("📊 개별 종목 [{}] 순정 당일 분봉 API 직통 호출", stockName);
            data = webClientService.getMinuteChart(stockCode);
        } else {
            log.info("📊 개별 종목 [{}] 순정 기간별 시세 API 직통 호출 ({} ~ {})", stockName, startDate, endDate);
            data = webClientService.getDailyChart(stockCode, startDate, endDate, timeframe);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("stockCode", stockCode);
        result.put("stockName", stockName);

        if (data != null && data.getOutput2() != null && !data.getOutput2().isEmpty()) {
            List<Map<String, Object>> refinedCandles = transformToCandles(data.getOutput2(), isMinute);
            if (!refinedCandles.isEmpty()) {
                result.put("output2", refinedCandles);
                result.put("rt_cd", data.getRt_cd());
                return ResponseEntity.ok(result);
            }
        }

        log.warn("⚠️ [인프라 통신 공백 확인] 한투 API가 빈 데이터를 반환했습니다. 백업 모드 없이 원본 실패 처리 전개.");
        result.put("output2", new ArrayList<>());
        result.put("message", "한투 오픈 API 인프라 정산 처리 혹은 주말 세션 제약으로 시세 데이터가 제공되지 않는 구간입니다.");
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(result);
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
    public ResponseEntity<?> getDbStockList() {
        List<Map<String, Object>> stocks = stockJoinService.getAllStocks();
        return ResponseEntity.ok(stocks);
    }

    @GetMapping("/rank")
    public ResponseEntity<?> getMarketRank(@RequestParam(value = "mode", defaultValue = "UP") String mode) {
        
        List<com.tj.app.market.stock.StockListDTO.StockListOutput> allStocks = stockService.getCachedTop100(); 
        
        // 🛡️ 1단계 방어: 리스트 자체가 비어있거나 지수 1건만 딸랑 있으면 500 에러 없이 안전하게 빈 배열 리턴
        if (allStocks == null || allStocks.size() <= 1) {
            return ResponseEntity.ok(List.of()); 
        }

        try {
            List<com.tj.app.market.stock.StockListDTO.StockListOutput> rankedList = allStocks.stream()
                // 🛡️ 2단계 방어: 코스피 지수는 랭킹에서 무조건 칼같이 드롭
                .filter(stock -> stock.getHts_kor_isnm() != null && !stock.getHts_kor_isnm().equals("코스피"))
                // 🛡️ 3단계 방어: 등락률 필드가 null이거나 완전히 비어있는 녀석은 정렬 대상에서 필터링
                .filter(stock -> stock.getPrdy_ctrt() != null && !stock.getPrdy_ctrt().trim().isEmpty()) 
                .sorted((s1, s2) -> {
                    try {
                        // 특수 기호 정제 가드
                        String rateStr1 = s1.getPrdy_ctrt().replace("+", "").replace("%", "").trim();
                        String rateStr2 = s2.getPrdy_ctrt().replace("+", "").replace("%", "").trim();
                        
                        double rate1 = Double.parseDouble(rateStr1);
                        double rate2 = Double.parseDouble(rateStr2);
                        
                        if ("UP".equalsIgnoreCase(mode)) {
                            return Double.compare(rate2, rate1); // 📈 급상승 내림차순
                        } else {
                            return Double.compare(rate1, rate2); // 📉 급하락 오름차순
                        }
                    } catch (Exception e) {
                        // 🛡️ 4단계 내부 방어: 파싱 중 에러 발생 시 예외를 던지지 않고 무시하여 500 발생 원천 봉쇄
                        return 0; 
                    }
                })
                .limit(5)
                .toList();

            return ResponseEntity.ok(rankedList);
            
        } catch (Exception e) {
            // 혹시 모를 스트림 전체 예외가 발생하더라도 빈 배열로 안전하게 가드
            return ResponseEntity.ok(List.of());
        }
    }
    
    
}