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
    
    @Autowired
    private StockService stockService;

    /**
     * 📊 1. 개별 종목 차트 데이터 조회 엔드포인트 (가상 백업 완전 제거)
     */
    @GetMapping("chart")
    public ResponseEntity<Map<String, Object>> getChart(
            @RequestParam(name = "code", defaultValue = "005930") String keyword,
            @RequestParam(name = "range", defaultValue = "1y") String range) {

        String stockCode = keyword;
        String stockName = "";

        // 이름 또는 코드로 개별 종목 검색 및 판별
        if (keyword.equals("0001") || keyword.equalsIgnoreCase("KOSPI")) {
            stockCode = "0001";
            stockName = "코스피";
        } else if (!keyword.matches("\\d{6}")) { 
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

        // 기간 및 timeframe 설정 계산
        Map<String, String> periodMap = calculatePeriod(range);
        String startDate = periodMap.get("start");
        String endDate = periodMap.get("end");
        String timeframe = periodMap.get("timeframe");

        Map<String, Object> result = new HashMap<>();
        result.put("stockCode", stockCode); 
        result.put("stockName", stockName);

        // 코스피 지수가 아닐 때만 한투 개별 주식 차트 API 호출
        if (!"0001".equals(stockCode)) {
            StockChartDTO data = null; 
            boolean isMinute = "min".equals(timeframe); 
            
            if (isMinute) {
                log.info("📊 개별 종목 [{}] 당일 분봉 호출", stockName);
                data = webClientService.getMinuteChart(stockCode);
            } else {
                log.info("📊 개별 종목 [{}] 일봉 호출 ({} ~ {})", stockName, startDate, endDate);
                data = webClientService.getDailyChart(stockCode, startDate, endDate, timeframe);
            }

            log.info("🚀 한투 API 최종 응답 결과: {}", data);

            // 데이터 검증 및 변환
            if (data != null && data.getOutput2() != null && !data.getOutput2().isEmpty()) {
                List<Map<String, Object>> refinedCandles = transformToCandles(data.getOutput2(), isMinute);
                
                if (!refinedCandles.isEmpty()) {
                    result.put("output2", refinedCandles);  
                    result.put("rt_cd", data.getRt_cd());
                    return ResponseEntity.ok(result);
                }
            }
            
            // 🛡️ [가상 데이터 가드 파괴] 이제 가짜 데이터를 주지 않고 프론트엔드에 404 에러로 사실을 알림
            log.error("❌ 한투 API 데이터 수급 원천 실패 -> 응답 버퍼가 공백입니다.");
            result.put("message", "한투 오픈 API 인프라로부터 시세 데이터를 가져오지 못했습니다.");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(result);
            
        } else {
            // 코스피(0001) 히스토리 응답 처리
            result.put("output2", new ArrayList<>());
            result.put("message", "지수 차트는 메인 요약 피드로 대체 서빙됩니다.");
        }

        return ResponseEntity.ok(result);
    }

    /**
     * 📈 2. 대시보드 메인 화면 실시간 카드용
     */
    @GetMapping("/tickers/summary")
    public ResponseEntity<Map<String, Object>> getTickersSummary() {
        List<StockListDTO.StockListOutput> cachedList = stockService.getCachedTop100();
        List<Map<String, Object>> formattedList = new ArrayList<>();
        
        for (StockListDTO.StockListOutput out : cachedList) {
            Map<String, Object> item = new HashMap<>();
            item.put("stock_name", out.getHts_kor_isnm());   
            item.put("stck_prpr", out.getMkstat_prpr());    
            item.put("prdy_ctrt", out.getPrdy_ctrt());     
            formattedList.add(item);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("data", formattedList);
        return ResponseEntity.ok(result);
    }
    
    /**
     * 🔍 3. 개별 종목 현재가 단건 조회 (가상 백업 완전 제거)
     */
    @GetMapping("/ticker")
    public ResponseEntity<Map<String, Object>> getTicker(@RequestParam String code) {
        log.info("📡 [한투 실시간 직통] 개별 종목 현재가 단건 Open API 호출 (종목코드: {})", code);
        
        StockPriceDTO priceData = webClientService.getCurrentPrice(code);
        
        Map<String, Object> result = new HashMap<>();
        Map<String, Object> output = new HashMap<>();

        if (priceData != null && priceData.getOutput() != null) {
            StockPriceDTO.Output out = priceData.getOutput();
            
            output.put("stck_prpr", out.getStck_prpr());  
            output.put("prdy_ctrt", out.getPrdy_ctrt());  
            
            output.put("stck_oprc", out.getStck_prpr());  
            output.put("stck_hgpr", out.getStck_prpr());  
            output.put("stck_lwpr", out.getStck_prpr());  
            output.put("acml_vol",  "0");           
            
            result.put("output", output);
            return ResponseEntity.ok(result);
        }

        // 🛡️ [가상 데이터 가드 파괴] 한투 실시간 가격 조회 실패 시 503 에러 리턴
        log.error("⚠️ 한투 API 현재가 수급 불능 -> 단가 기준선 가드를 발동하지 않고 실패 처리합니다.");
        result.put("message", "실시간 현재가를 가져올 수 없습니다.");
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(result);
    }

    /**
     * 📅 날짜 계산 연산 기술 정밀 보정
     */
    private Map<String, String> calculatePeriod(String range) {
        LocalDate now = LocalDate.now();
        // 장 마감 직후 정산 락을 피하기 위해 안전하게 '어제' 날짜를 종료일로 설정
        LocalDate safeEnd = now.minusDays(1); 
        
        // 월요일이면 금요일 날짜로 강제 후퇴
        if (now.getDayOfWeek().getValue() == 1) { 
            safeEnd = now.minusDays(3); 
        }

        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyyMMdd");
        Map<String, String> map = new HashMap<>();
        
        map.put("end", safeEnd.format(fmt)); 
        
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
                LocalDate calcStart = now.minusDays(60);
                if (calcStart.getDayOfWeek().getValue() == 6) { 
                    calcStart = calcStart.minusDays(2);
                } else if (calcStart.getDayOfWeek().getValue() == 7) { 
                    calcStart = calcStart.minusDays(1);
                }
                
                map.put("start", calcStart.format(fmt));
                map.put("timeframe", "D");
                break;
        }
        return map;
    }

    private List<Map<String, Object>> transformToCandles(List<StockChartDTO.ChartOutput> list, boolean isMinute) {
        List<Map<String, Object>> candles = new ArrayList<>();
        DateTimeFormatter defaultFmt = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        LocalDate fallbackDate = LocalDate.now().minusDays(list.size());

        for (int i = list.size() - 1; i >= 0; i--) {
            StockChartDTO.ChartOutput out = list.get(i);
            Map<String, Object> candle = new HashMap<>();
            
            if (out.getStck_bsop_date() != null && !out.getStck_bsop_date().isEmpty() && !out.getStck_bsop_date().equals("null")) {
                candle.put("time", formatTimeLabel(out, isMinute));
            } else {
                candle.put("time", fallbackDate.plusDays(candles.size()).format(defaultFmt));
            }
            
            candle.put("open", parseDouble(out.getStck_oprc()));
            candle.put("high", parseDouble(out.getStck_hgpr()));
            candle.put("low", parseDouble(out.getStck_lwpr()));
            candle.put("close", parseDouble(out.getStck_clpr()));
            candle.put("volume", parseDouble(out.getAcml_vol()));
            candles.add(candle);
        }
        return candles;
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
}