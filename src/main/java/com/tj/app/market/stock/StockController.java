package com.tj.app.market.stock;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.tj.app.asset.AssetService;
import com.tj.app.member.MemberDTO;
import com.tj.app.market.stock.order.OrderStockService;
import jakarta.servlet.http.HttpSession;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;

/** ============================================================
 * [클래스 읽기] 주식 시세·차트·종목 목록·랭킹 데이터를 JSON으로 반환하는 REST 컨트롤러.
 *
 * JS에서 fetch("/stock/chart"), fetch("/stock/ticker") 형태로 호출한다.
 * JSP를 렌더링하지 않고 순수 JSON 데이터만 반환한다.
 *
 * [주요 엔드포인트]
 * GET /stock/chart          : 종목 차트 데이터 (일봉/주봉/월봉/분봉)
 * GET /stock/ticker         : 개별 종목 현재가 단건 조회
 * GET /stock/tickers/summary: 코스피 지수 포함 실시간 요약 리스트
 * GET /stock/db-list        : DB의 종목 목록 + 실시간/마감 가격 병합
 * GET /stock/rank           : 등락률 기준 상위/하위 종목 랭킹
 * GET /stock/mini-charts    : 종목별 1년 미니차트 데이터
 * GET /stock/my-asset       : 로그인 사용자 총 자산 조회
 * ============================================================ */
@Slf4j
@RestController
@RequestMapping("/stock")
public class StockController {

    @Autowired
    private AssetService assetService;

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

    @Autowired
    private StockDailyPriceMapper stockDailyPriceMapper;

    /** ============================================================
     * GET /stock/chart?code={코드or이름}&range={기간}
     * 종목 차트 데이터를 조회해 캔들 형식으로 반환한다.
     *
     * [실행 흐름]
     * 1. keyword가 6자리 숫자면 종목 코드, 아니면 이름으로 코드 변환
     * 2. range → calculatePeriod()로 시작일·종료일·타임프레임 계산
     * 3. StockService 캐시 조회 → 캐시 hit이면 API 호출 없이 반환
     * 4. 캐시 miss → KIS API 호출 → 조회 성공 시 캐시 저장
     * 5. transformToCandles()로 차트 라이브러리 형식으로 변환 후 반환
     *
     * range 옵션: "min"=분봉, "1y"=1년일봉(기본), "3y"=3년주봉, "10y"=10년월봉
     * ============================================================ */
    @GetMapping("/chart")
    public ResponseEntity<Map<String, Object>> getChart(
            @RequestParam(name = "code", defaultValue = "005930") String keyword,
            @RequestParam(name = "range", defaultValue = "1y") String range) {

        // [실행 흐름] 6자리 숫자면 코드 직접 사용, 아니면 이름으로 코드 조회
        String stockCode = keyword;
        String stockName = "";
        if (!keyword.matches("\\d{6}")) {
            String cleanKeyword = keyword.replaceAll("[^a-zA-Z0-9가-힣]", "").toLowerCase();
            stockCode = stockJoinService.getCode(cleanKeyword);
            stockName = stockJoinService.getName(stockCode);
        } else {
            stockName = stockJoinService.getName(stockCode);
        }

        // [실행 흐름] range → 시작일·종료일·타임프레임 Map으로 변환
        Map<String, String> periodMap = calculatePeriod(range);
        String startDate  = periodMap.get("start");
        String endDate    = periodMap.get("end");
        String timeframe  = periodMap.get("timeframe");
        boolean isMinute  = "min".equals(timeframe);

        // [실행 흐름] 3단계: 인메모리 캐시 확인 → 있으면 API 호출 없이 반환
        StockChartDTO cachedData = stockService.getCachedDailyChart(stockCode, startDate, endDate, timeframe);
        if (cachedData != null) {
            log.info("개별 종목 [{}] 캐시 데이터 반환", stockName);
            return buildResponse(cachedData, stockCode, stockName, isMinute);
        }

        // [실행 흐름] 4단계: 캐시 없음 → KIS API 직접 호출
        log.info("개별 종목 [{}] API 호출", stockName);
        StockChartDTO data = isMinute ? webClientService.getMinuteChart(stockCode)
                                      : webClientService.getDailyChart(stockCode, startDate, endDate, timeframe);

        if (data != null && data.getOutput2() != null && !data.getOutput2().isEmpty()) {
            if (!isMinute) {
                stockService.putChartCache(stockCode, startDate, endDate, timeframe, data); // 캐시 저장
            }
            return buildResponse(data, stockCode, stockName, isMinute);
        }

        log.warn("API 데이터 없음 [{}]", stockCode);
        Map<String, Object> errorResult = new HashMap<>();
        errorResult.put("message", "시세 데이터를 제공하지 않는 구간입니다.");
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResult);
    }

    /** ============================================================
     * 차트 응답 Map을 생성하는 공통 헬퍼.
     * stockCode, stockName, output2(변환된 캔들), rt_cd를 묶어 반환한다.
     * ============================================================ */
    private ResponseEntity<Map<String, Object>> buildResponse(StockChartDTO data, String stockCode, String stockName, boolean isMinute) {
        Map<String, Object> result = new HashMap<>();
        result.put("stockCode", stockCode);
        result.put("stockName", stockName);
        result.put("output2", transformToCandles(data.getOutput2(), isMinute));
        result.put("rt_cd", data.getRt_cd());
        return ResponseEntity.ok(result);
    }

    /** ============================================================
     * range 문자열을 시작일·종료일·타임프레임으로 변환한다.
     *
     * range  → timeframe (KIS API 파라미터)
     * "min"  → "min" (분봉, 별도 API 사용)
     * "1y"   → "D"  (일봉, 1년)
     * "3y"   → "W"  (주봉, 3년)
     * "10y"  → "M"  (월봉, 10년)
     * ============================================================ */
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

    /** ============================================================
     * KIS API 응답(ChartOutput 리스트)을 차트 라이브러리 형식으로 변환한다.
     *
     * [실행 흐름]
     * - KIS API는 최신→과거 역순으로 반환 → 역순(i=size-1→0)으로 순회해 과거→최신 정렬
     * - 분봉: time = "YYYY-MM-DD HH:MM" 형식
     * - 일봉 이상: time = "YYYY-MM-DD" 형식
     * ============================================================ */
    private List<Map<String, Object>> transformToCandles(List<StockChartDTO.ChartOutput> list, boolean isMinute) {
        List<Map<String, Object>> candles = new ArrayList<>();

        // [실행 흐름] KIS 응답이 최신순 → 역순 순회로 오래된 것부터 리스트에 추가
        for (int i = list.size() - 1; i >= 0; i--) {
            StockChartDTO.ChartOutput out = list.get(i);
            if (out.getStck_bsop_date() == null || out.getStck_bsop_date().isEmpty() || out.getStck_bsop_date().equals("null")) {
                continue;
            }

            Map<String, Object> candle = new HashMap<>();
            candle.put("time",   formatTimeLabel(out, isMinute));
            candle.put("open",   parseDouble(out.getStck_oprc()));
            candle.put("high",   parseDouble(out.getStck_hgpr()));
            candle.put("low",    parseDouble(out.getStck_lwpr()));
            candle.put("close",  parseDouble(out.getStck_clpr()));
            candle.put("volume", parseDouble(out.getAcml_vol()));

            candles.add(candle);
        }
        return candles;
    }

    /** ============================================================
     * GET /stock/ticker?code={종목코드}
     * 네이버 금융에서 개별 종목 현재가를 조회한다.
     *
     * [실행 흐름]
     * 네이버 API → { price, rate, diff } 추출
     * 종목명은 DB에서 별도 조회해서 합쳐서 반환
     * 실패 시 503 Service Unavailable 반환
     * ============================================================ */
    @GetMapping("/ticker")
    public ResponseEntity<Map<String, Object>> getTicker(@RequestParam("code") String code) {
        Map<String, String> naverData = webClientService.getStockPriceFromNaver(code);

        if (naverData == null || naverData.isEmpty() || "-".equals(naverData.get("price"))) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(Map.of("error", "시세 데이터를 가져올 수 없습니다."));
        }

        Map<String, Object> output = new HashMap<>();
        output.put("stck_prpr",     naverData.get("price")); // 현재가
        output.put("prdy_ctrt",     naverData.get("rate"));  // 등락률
        output.put("prdy_vrss",     naverData.get("diff"));  // 등락폭
        output.put("hts_kor_isnm",  stockJoinService.getName(code)); // 종목명

        return ResponseEntity.ok(Map.of("output", output));
    }

    /** ============================================================
     * GET /stock/tickers/summary
     * 코스피 지수를 포함한 실시간 종목 요약 리스트를 반환한다.
     * StockService.getCachedTop100()의 인메모리 캐시를 그대로 포맷팅해 반환한다.
     * ============================================================ */
    @GetMapping("/tickers/summary")
    public ResponseEntity<Map<String, Object>> getTickersSummary() {
        List<StockListDTO.StockListOutput> cachedData = stockService.getCachedTop100();

        if (cachedData == null || cachedData.isEmpty()) {
            return ResponseEntity.ok(Map.of("data", new ArrayList<>()));
        }

        List<Map<String, Object>> formattedList = new ArrayList<>();
        for (StockListDTO.StockListOutput out : cachedData) {
            Map<String, Object> item = new HashMap<>();
            item.put("stock_name", out.getHts_kor_isnm()); // 코스피 또는 종목명
            item.put("stck_prpr",  out.getMkstat_prpr());  // 지수 또는 현재가
            item.put("prdy_ctrt",  out.getPrdy_ctrt());    // 등락률
            formattedList.add(item);
        }

        return ResponseEntity.ok(Map.of("data", formattedList));
    }

    /** ============================================================
     * ChartOutput의 날짜·시간을 차트 라이브러리 time 형식으로 변환한다.
     * 일봉: "YYYY-MM-DD", 분봉: "YYYY-MM-DD HH:MM"
     * KIS 날짜 "20250524" → substring으로 분리해 포맷팅
     * ============================================================ */
    private String formatTimeLabel(StockChartDTO.ChartOutput out, boolean isMinute) {
        String date = out.getStck_bsop_date();
        if (isMinute && out.getStck_cntg_hour() != null) {
            String time = out.getStck_cntg_hour(); // "143000" = 14:30:00
            return String.format("%s-%s-%s %s:%s",
                date.substring(0, 4), date.substring(4, 6), date.substring(6, 8),
                time.substring(0, 2), time.substring(2, 4));
        }
        return String.format("%s-%s-%s", date.substring(0, 4), date.substring(4, 6), date.substring(6, 8));
    }

    /** ============================================================
     * 문자열을 double로 안전하게 변환하는 헬퍼.
     * null·빈 문자열·"null" 문자열 모두 0으로 반환한다.
     * ============================================================ */
    private double parseDouble(String value) {
        try {
            return (value == null || value.isEmpty() || value.equals("null")) ? 0 : Double.parseDouble(value);
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    /** ============================================================
     * GET /stock/db-list?limit={n}
     * DB 종목 목록에 주식 가격을 병합해 반환한다.
     *
     * [가격 우선순위]
     * 1. 장중 WebSocket priceCache: 실시간 체결가·등락률·고가·저가·거래량
     * 2. STOCK_DAILY_PRICE 최신 종가: 장 마감/서버 재시작 등으로 캐시가 비었을 때 fallback
     *
     * limit=40이면 상위 40개, 0이면 전체, 그 외면 해당 수만큼 잘라서 반환.
     * ============================================================ */
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

    /** ============================================================
     * 종목 목록에 가격 데이터를 합쳐 반환한다.
     *
     * [실행 흐름]
     * 1. WebSocket priceCache에 해당 종목의 실시간 가격이 있으면 그 값을 사용
     * 2. WebSocket 캐시가 없으면 STOCK_DAILY_PRICE 최신 종가를 사용
     * 3. 최신 종가와 직전 종가가 모두 있으면 등락폭(diff)·등락률(rate)을 계산
     *
     * [장 마감 대응]
     * WebSocket 캐시는 서버 메모리라 재시작하면 비어 있다.
     * 이때 DB 종가 fallback을 붙여 주식 리스트/사이드바가 '-'만 표시하지 않게 한다.
     * ============================================================ */
    private List<Map<String, Object>> withCachedPrices(List<Map<String, Object>> stocks) {
        if (stocks == null || stocks.isEmpty()) return List.of();

        Map<String, Map<String, String>> priceCache = kisWebSocketService.getPriceCache();
        Map<String, Map<String, Object>> closeFallback = getLatestCloseFallback(stocks);

        return stocks.stream()
                .map(stock -> {
                    Map<String, Object> item = new HashMap<>(stock);
                    String code = String.valueOf(item.get("code"));
                    Map<String, String> price = priceCache.get(code);
                    if (hasUsablePrice(price)) {
                        // [실행 흐름] 장중 WebSocket 캐시에 해당 종목 가격이 있으면 최우선으로 병합
                        item.put("price",  price.get("price"));
                        item.put("rate",   price.get("rate"));
                        item.put("diff",   price.get("diff"));
                        item.put("high",   price.get("high"));
                        item.put("low",    price.get("low"));
                        item.put("volume", price.get("volume"));
                    } else {
                        // [실행 흐름] 장 마감/캐시 없음 → DB에 저장된 최신 종가로 fallback
                        applyLatestCloseFallback(item, closeFallback.get(code));
                    }
                    return item;
                })
                .toList();
    }

    private boolean hasUsablePrice(Map<String, String> price) {
        if (price == null) return false;
        String value = price.get("price");
        return value != null && !value.isBlank() && !"-".equals(value);
    }

    private Map<String, Map<String, Object>> getLatestCloseFallback(List<Map<String, Object>> stocks) {
        List<String> codes = stocks.stream()
                .map(stock -> String.valueOf(stock.get("code")))
                .filter(code -> code != null && !code.isBlank() && !"null".equals(code))
                .distinct()
                .toList();

        if (codes.isEmpty()) return Map.of();

        try {
            List<Map<String, Object>> rows = stockDailyPriceMapper.findLatestCloseRowsByCodes(codes);
            Map<String, Map<String, Object>> result = new HashMap<>();
            for (Map<String, Object> row : rows) {
                Object code = firstValue(row, "stockCode", "STOCKCODE", "stock_code", "STOCK_CODE");
                if (code != null) result.put(String.valueOf(code), row);
            }
            return result;
        } catch (Exception e) {
            log.warn("주식 최신 종가 fallback 조회 실패: {}", e.getMessage());
            return Map.of();
        }
    }

    private void applyLatestCloseFallback(Map<String, Object> item, Map<String, Object> row) {
        if (row == null) return;

        BigDecimal close = toBigDecimal(firstValue(row, "closePrice", "CLOSEPRICE", "close_price", "CLOSE_PRICE"));
        if (close == null) return;

        item.put("price", formatStockNumber(close));

        BigDecimal prevClose = toBigDecimal(firstValue(row, "prevClosePrice", "PREVCLOSEPRICE", "prev_close_price", "PREV_CLOSE_PRICE"));
        if (prevClose != null && prevClose.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal diff = close.subtract(prevClose);
            BigDecimal rate = diff.multiply(BigDecimal.valueOf(100))
                    .divide(prevClose, 4, java.math.RoundingMode.HALF_UP);
            item.put("diff", formatSignedStockNumber(diff));
            item.put("rate", rate.stripTrailingZeros().toPlainString());
        }

        BigDecimal volume = toBigDecimal(firstValue(row, "volume", "VOLUME"));
        if (volume != null) item.put("volume", formatStockNumber(volume));
    }

    private Object firstValue(Map<String, Object> row, String... keys) {
        for (String key : keys) {
            if (row.containsKey(key)) return row.get(key);
        }
        return null;
    }

    private BigDecimal toBigDecimal(Object value) {
        if (value == null) return null;
        if (value instanceof BigDecimal bd) return bd;
        if (value instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        try {
            return new BigDecimal(String.valueOf(value));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private String formatStockNumber(BigDecimal value) {
        return value.stripTrailingZeros().toPlainString();
    }

    private String formatSignedStockNumber(BigDecimal value) {
        String text = formatStockNumber(value.abs());
        return value.signum() < 0 ? "-" + text : text;
    }

    /** ============================================================
     * GET /stock/rank?mode={UP|DOWN}
     * WebSocket priceCache를 등락률 기준으로 정렬해 상위 40개를 반환한다.
     * mode=UP: 상승률 순, mode=DOWN: 하락률 순
     * WebSocket 미연결 시(priceCache 비어있으면) 빈 리스트 반환
     * ============================================================ */
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
                        // [실행 흐름] UP: 높은 등락률 우선, DOWN: 낮은(음수) 등락률 우선
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
                    item.put("name", nameCache.getOrDefault(e.getKey(), "-")); // 종목명 추가
                    return item;
                })
                .toList();

            return ResponseEntity.ok(ranked);

        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    /** ============================================================
     * GET /stock/mini-charts?limit={n}
     * DB에 저장된 종목별 1년 미니차트 데이터를 반환한다.
     * ============================================================ */
    @GetMapping("/mini-charts")
    public ResponseEntity<?> getMiniCharts(
            @RequestParam(value = "limit", defaultValue = "40") int limit) {
        return ResponseEntity.ok(stockMiniChartService.getMiniCharts(limit));
    }

    /** ============================================================
     * POST /stock/mini-charts/refresh?limit={n}
     * Yahoo Finance에서 미니차트 데이터를 재수집해 DB에 저장한다.
     * 관리자용 수동 갱신 엔드포인트.
     * ============================================================ */
    @PostMapping("/mini-charts/refresh")
    public ResponseEntity<?> refreshMiniCharts(
            @RequestParam(value = "limit", defaultValue = "40") int limit) {
        return ResponseEntity.ok(stockMiniChartService.refreshTopMiniCharts(limit));
    }

    /** ============================================================
     * GET /stock/my-asset
     * 로그인 사용자의 총 자산(주식+코인 합산)을 원화로 반환한다.
     * 세션에서 MemberDTO를 꺼내 AssetService에 위임한다.
     * ============================================================ */
    @GetMapping("/my-asset")
    public ResponseEntity<Long> getMyTotalAsset(HttpSession session) {
        MemberDTO user = (MemberDTO) session.getAttribute("member");
        return ResponseEntity.ok(assetService.calculateTotalAsset(user));
    }
}
