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
            @RequestParam(name = "symbol", defaultValue = "005930") String keyword, // keyword로 명칭 변경
            @RequestParam(name = "range", defaultValue = "1y") String range) {

        // 1. 종목 코드 판별 로직 (이름 -> 코드 변환)
        String stockCode = keyword;
        String stockName = keyword; // 기본값

        if (!keyword.matches("\\d{6}")) { 
            // 입력값에서 공백/특수문자 싹 제거 (ex: "SK 하이닉스" -> "sk하이닉스")
            String cleanKeyword = keyword.replaceAll("[^a-zA-Z0-9가-힣]", "").toLowerCase();
            stockCode = stockJoinService.getCode(cleanKeyword);
            
            if (stockCode == null) {
                log.warn("❌ 매핑 실패: 원본[{}], 정제[{}]", keyword, cleanKeyword);
                return ResponseEntity.ok(Map.of("error", "종목을 찾을 수 없습니다."));
            }
        }

        // 2. 기간 및 timeframe 설정
        Map<String, String> periodMap = calculatePeriod(range);
        String startDate = periodMap.get("start");
        String endDate = periodMap.get("end");
        String timeframe = periodMap.get("timeframe");
        boolean isMinute = "min".equals(range);

        // 3. 서비스 호출 및 로깅
        StockChartDTO data = isMinute 
                ? webClientService.getMinuteChart(stockCode)
                : webClientService.getDailyChart(stockCode, startDate, endDate, timeframe);

        if (data == null || data.getOutput2() == null || data.getOutput2().isEmpty()) {
            log.error("❌ 데이터 조회 실패: {} (Msg: {})", stockCode, data != null ? data.getMsg1() : "Empty Response");
            return ResponseEntity.ok(Map.of("candles", new ArrayList<>(), "message", "데이터가 없습니다."));
        }

        // 4. 데이터 정제 (Data Transformation)
        List<Map<String, Object>> candles = transformToCandles(data.getOutput2(), isMinute);

        // 5. 최종 응답 구조화 (실무형 응답)
        Map<String, Object> result = new HashMap<>();
        result.put("candles", candles);
        result.put("isMinute", isMinute);
        result.put("stockCode", stockCode);
        result.put("stockName", stockName);
        result.put("range", range);

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