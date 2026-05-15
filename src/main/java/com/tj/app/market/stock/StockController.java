package com.tj.app.market.stock;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity; // 응답 규격화
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

    @GetMapping("/chart")
    public ResponseEntity<Map<String, Object>> getChart(
            @RequestParam(name = "code", defaultValue = "005930") String keyword, // 파라미터명 code로 변경
            @RequestParam(name = "range", defaultValue = "1y") String range) {

        // 1. 종목 코드 판별 (기존 로직 유지)
    	String stockCode = keyword;
        String stockName = "";
        if (!keyword.matches("\\d{6}")) { 
            // [이름으로 검색 시]
            String cleanKeyword = keyword.replaceAll("[^a-zA-Z0-9가-힣]", "").toLowerCase();
            stockCode = stockJoinService.getCode(cleanKeyword);
            // 서비스에서 가져온 진짜 이름을 저장 (예: sk하이닉스 -> SK하이닉스)
            stockName = stockJoinService.getName(stockCode); 
        } else {
            // [코드로 검색 시]
            stockCode = keyword;
            // ✅ 핵심: 서비스에 코드를 넣어서 진짜 이름을 가져오는 로직이 필요합니다!
            stockName = stockJoinService.getName(stockCode); 
        }

        // 이름이 여전히 비어있다면 기본값 설정
        if (stockName == null || stockName.equals("알 수 없는 종목")) {
            stockName = "종목명 없음";
        }

        // 2. 기간 및 timeframe 설정 (기존 calculatePeriod 활용)
        Map<String, String> periodMap = calculatePeriod(range);
        String startDate = periodMap.get("start");
        String endDate = periodMap.get("end");
        String timeframe = periodMap.get("timeframe");

        // 3. 서비스 호출 (DTO 그대로 가져오기)
        StockChartDTO data = webClientService.getDailyChart(stockCode, startDate, endDate, timeframe);

        // 4. [방법 A 핵심] 프론트엔드가 기대하는 "output2"라는 키에 리스트를 담아 리턴
        Map<String, Object> result = new HashMap<>();

        if (data != null && data.getOutput2() != null) {
            result.put("output2", data.getOutput2());  // JS의 res.output2.map(...)과 연결됨
            result.put("rt_cd", data.getRt_cd());
            
            // ✅ 1. 우리가 위에서 서비스로 찾은 진짜 코드와 이름을 넣어줍니다.
            result.put("stockCode", stockCode); 
            result.put("stockName", stockName); // "조회된 종목" 대신 변수 stockName 사용!
            
        } else {
            result.put("output2", new ArrayList<>());
            result.put("message", "데이터가 없습니다.");
            
            // 데이터가 없더라도 어떤 종목을 찾으려 했는지는 알려주는 게 좋습니다.
            result.put("stockCode", stockCode);
            result.put("stockName", stockName);
        }

        return ResponseEntity.ok(result);
    }

    /**
     * 날짜 계산 로직 분리 (가독성 향상)
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
     * API 데이터를 차트 라이브러리 규격에 맞게 변환
     */
    private List<Map<String, Object>> transformToCandles(List<StockChartDTO.ChartOutput> list, boolean isMinute) {
        List<Map<String, Object>> candles = new ArrayList<>();
        
        for (int i = list.size() - 1; i >= 0; i--) {
            StockChartDTO.ChartOutput out = list.get(i);
            if (out.getStck_bsop_date() == null) continue;

            Map<String, Object> candle = new HashMap<>();
            candle.put("time", formatTimeLabel(out, isMinute));
            candle.put("open", parseDouble(out.getStck_oprc()));
            candle.put("high", parseDouble(out.getStck_hgpr()));
            candle.put("low", parseDouble(out.getStck_lwpr()));
            candle.put("close", parseDouble(out.getStck_clpr()));
            
            // ✅ 거래량 추가 (한투 API의 acml_vol 필드 활용)
            // 숫자가 크므로 parseLong을 사용하거나 안전하게 parseDouble 사용
            candle.put("volume", parseDouble(out.getAcml_vol()));

            candles.add(candle);
        }
        return candles;
    }
    
    @GetMapping("/ticker")
    public ResponseEntity<Map<String, Object>> getTicker(@RequestParam String code) {
        // 1. 서비스에서 현재가 DTO 가져오기
        StockPriceDTO priceData = webClientService.getCurrentPrice(code);
        
        if (priceData == null || priceData.getOutput() == null) {
            return ResponseEntity.ok(Map.of("error", "데이터를 가져올 수 없습니다."));
        }

        // 2. JS가 기대하는 필드명으로 변환해서 리턴 (방법 A)
        // 한투 API의 필드명을 그대로 넘겨주면 JS의 loadTicker() 함수와 바로 연동됩니다.
        Map<String, Object> result = new HashMap<>();
        result.put("output", priceData.getOutput()); 
        
        return ResponseEntity.ok(result);
    }
    
    @GetMapping("/tickers/summary")
    public ResponseEntity<Map<String, Object>> getTickersSummary() {
        StockListDTO listData = webClientService.getFullMarketPrices();
        
        if (listData == null || listData.getOutput2() == null) {
            return ResponseEntity.ok(Map.of("data", new ArrayList<>()));
        }

        // JS의 기대 필드명에 맞춰 맵핑 (변환)
        List<Map<String, Object>> formattedList = new ArrayList<>();
        for (StockListDTO.StockListOutput out : listData.getOutput2()) {
            Map<String, Object> item = new HashMap<>();
            item.put("stock_name", out.getHts_kor_isnm());   // 이름 맵핑
            item.put("stck_prpr", out.getMkstat_prpr());    // 현재가 맵핑
            item.put("prdy_ctrt", out.getPrdy_ctrt());     // 등락률 맵핑
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
            return (value == null || value.isEmpty()) ? 0 : Double.parseDouble(value);
        } catch (NumberFormatException e) {
            return 0;
        }
    }
}