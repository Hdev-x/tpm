package com.tj.app.asset;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.tj.app.market.coin.CoinMarketService;
import com.tj.app.market.coin.order.CoinHoldingsDTO;
import com.tj.app.market.coin.order.CoinService;
import com.tj.app.market.coin.order.CoinWalletDTO;
import com.tj.app.market.index.MarketIndexDTO;
import com.tj.app.market.index.MarketIndexService;
import com.tj.app.market.stock.StockService;
import com.tj.app.market.stock.order.OrderStockMapper;
import com.tj.app.member.MemberDTO;

import lombok.extern.slf4j.Slf4j;

/** ============================================================
 * [클래스 읽기] 주식 + 코인 통합 자산 계산 서비스.
 *
 * 이 프로젝트의 모든 자산 계산은 이 클래스를 통해 일원화된다.
 * MemberController(마이페이지), AssetController(자산 페이지),
 * StockController(주식 내 계좌) 모두 이 서비스를 공유하기 때문에
 * 어느 페이지에서 봐도 동일한 총 자산이 표시된다.
 *
 * @Slf4j → log.error() 등 로그 출력을 위한 Lombok 어노테이션.
 * ============================================================ */
@Service
@Slf4j
public class AssetService {

    @Autowired
    private OrderStockMapper orderStockMapper; // 주식 예수금·보유·미체결 DB 조회

    @Autowired
    private StockService stockService; // 주식 현재가 캐시 조회

    @Autowired
    private MarketIndexService indexService; // 환율 정보 조회

    @Autowired
    private CoinService coinService; // 코인 지갑·보유 조회

    @Autowired
    private CoinMarketService coinMarketService; // 코인 실시간 시세 조회

    /** ============================================================
     * [메서드 읽기] 현재 환율(USD→KRW) 조회.
     *
     * [실행 흐름]
     * 1. MarketIndexService에서 시세 목록을 가져와 "환율" 항목을 찾는다
     * 2. stream().filter().findFirst() → 조건에 맞는 첫 번째 요소를 Optional로 반환
     * 3. .orElse(null) → 없으면 null
     * 4. 조회 실패 또는 예외 발생 시 기본값 1400 반환
     * ============================================================ */
    private double getExchangeRate() {
        try {
            MarketIndexDTO exDTO = indexService.getMarketIndex().stream()
                    .filter(d -> d.getName().contains("환율"))
                    .findFirst().orElse(null);
            if (exDTO != null)
                // [실행 흐름] "1,350.50" 같은 문자열에서 쉼표 제거 후 double 변환
                return Double.parseDouble(exDTO.getPrice().replace(",", ""));
        } catch (Exception e) {
            log.error("환율 조회 실패", e);
        }
        return 1400; // [주의] API 실패 시 기본 환율 1400원 사용
    }

    /** ============================================================
     * [메서드 읽기] 총 자산 금액(원)만 반환하는 간편 메서드.
     *
     * 내부적으로 getAssetSummary()에 위임해 계산한다.
     * 모든 페이지에서 이 메서드를 공유하므로 어디서 봐도 총 자산이 동일하게 표시된다.
     *
     * @return 주식+코인 통합 총 자산 (단위: 원). member가 null이면 0.
     * ============================================================ */
    public long calculateTotalAsset(MemberDTO member) {
        if (member == null) return 0;
        Map<String, Object> summary = getAssetSummary(member);
        // [실행 흐름] grandTotal은 long이지만 Map에서 꺼낼 때 Number로 받아 longValue()로 변환
        Number grandTotal = (Number) summary.get("grandTotal");
        return grandTotal != null ? grandTotal.longValue() : 0;
    }

    /** ============================================================
     * [메서드 읽기] 주식+코인 통합 자산 요약 계산 (핵심 메서드).
     *
     * [실행 흐름 — 주식]
     * 1. 예수금(stockCash) 조회
     * 2. 미체결 매수 주문의 예약금(stockLocked) 합산
     *    → BUY 주문만 집계 (SELL은 현금이 묶이지 않음)
     * 3. 보유 주식 평가금(stockEval) 계산
     *    → 캐시 가격 우선, 없으면 API 조회, 그래도 0이면 매수가로 대체
     * 4. stockTotal = 예수금 + 예약금 + 평가금
     *
     * [실행 흐름 — 코인]
     * 5. USDT 잔고(coinCash) 조회
     * 6. 보유 코인 평가금(coinEval) 계산 (실시간 시세 Map에서 조회)
     * 7. coinTotalKrw = (USDT잔고 + 평가금) × 환율 → 원화로 환산
     *
     * [최종]
     * 8. grandTotal = stockTotal(원) + coinTotalKrw(원)
     *
     * @return { grandTotal, stock:{...}, coin:{...} } 구조의 Map
     * ============================================================ */
    public Map<String, Object> getAssetSummary(MemberDTO member) {
        Map<String, Object> result = new HashMap<>();
        if (member == null) return result;

        double exchangeRate = getExchangeRate();

        // ── 주식 계산 ──────────────────────────────────────────────
        long stockCash = orderStockMapper.getWallet(member.getUsername());
        long stockLocked = 0;
        List<Map<String, Object>> pendingOrders = orderStockMapper.getPendingOrders(member.getUsername());
        for (Map<String, Object> o : pendingOrders) {
            // [실행 흐름] 미체결 매수 주문의 금액(주문가 × 수량)만 잠긴 금액으로 집계
            if ("BUY".equalsIgnoreCase((String) o.get("ORDER_TYPE")))
                stockLocked += ((Number) o.get("ORDER_PRICE")).longValue() * ((Number) o.get("ORDER_COUNT")).longValue();
        }

        List<Map<String, Object>> stockHoldings = orderStockMapper.getHoldingList(member.getUsername());
        List<Map<String, Object>> stockItems = new ArrayList<>();
        long stockEval = 0, stockBuy = 0;
        for (Map<String, Object> h : stockHoldings) {
            String code = (String) h.get("STOCK_CODE");
            long count = ((Number) h.get("STOCK_COUNT")).longValue();
            long avgPrice = ((Number) h.get("STOCK_PURCHASE")).longValue();

            // [실행 흐름] 현재가 조회: 메모리 캐시 우선 → 없으면 외부 API 호출
            long curPrice = stockService.getPriceFromCache(code);
            if (curPrice <= 0) curPrice = stockService.getCurrentPrice(code);

            // [실행 흐름] 현재가도 없으면 매수가로 대체 (평가손익 0으로 보이게)
            long eval = curPrice > 0 ? curPrice * count : avgPrice * count;
            long buy = avgPrice * count;
            stockEval += eval;
            stockBuy += buy;

            Map<String, Object> item = new HashMap<>();
            item.put("name", h.get("STOCK_NAME"));
            item.put("count", count);
            item.put("buyPrice", avgPrice);
            item.put("currentPrice", curPrice);
            item.put("eval", eval);
            item.put("rate", buy == 0 ? 0.0 : (double) (eval - buy) / buy * 100); // 수익률(%)
            stockItems.add(item);
        }
        long stockTotal = stockCash + stockLocked + stockEval;
        long stockPnl = stockEval - stockBuy; // 보유 주식 전체 평가손익
        double stockRate = stockBuy == 0 ? 0.0 : (double) stockPnl / stockBuy * 100;

        Map<String, Object> stock = new HashMap<>();
        stock.put("total", stockTotal);   // 주식 총자산 (예수금+예약금+평가금)
        stock.put("cash", stockCash);     // 사용 가능 예수금
        stock.put("locked", stockLocked); // 미체결 매수로 묶인 예약금
        stock.put("eval", stockEval);     // 보유 주식 평가금
        stock.put("pnl", stockPnl);       // 평가손익
        stock.put("rate", stockRate);     // 수익률(%)
        stock.put("items", stockItems);   // 보유 종목 상세 리스트

        // ── 코인 계산 ──────────────────────────────────────────────
        double coinCash = 0, coinEval = 0, coinBuy = 0;
        List<Map<String, Object>> coinItems = new ArrayList<>();
        try {
            CoinWalletDTO wallet = coinService.getWallet(member.getUsername());
            if (wallet != null) coinCash = wallet.getUsdtBalance(); // 보유 USDT 잔고

            List<CoinHoldingsDTO> coinHoldings = coinService.getHoldingList(member.getUsername());
            // [실행 흐름] 실시간 시세를 Map<코인코드, 가격>으로 한 번에 가져옴 (반복 API 호출 방지)
            Map<String, Double> prices = coinMarketService.getTickerPriceMap();
            for (CoinHoldingsDTO ch : coinHoldings) {
                // [실행 흐름] 시세 Map에 없으면 매수 평균가로 대체 (getOrDefault)
                double curPrice = prices.getOrDefault(ch.getCoinCode(), ch.getAvgPrice());
                double eval = curPrice * ch.getCoinCount();
                double buy = ch.getAvgPrice() * ch.getCoinCount();
                coinEval += eval;
                coinBuy += buy;

                Map<String, Object> item = new HashMap<>();
                item.put("name", ch.getCoinCode().replace("USDT", "")); // "BTCUSDT" → "BTC"
                item.put("count", ch.getCoinCount());
                item.put("buyPrice", ch.getAvgPrice());
                item.put("currentPrice", curPrice);
                item.put("eval", eval);
                item.put("rate", buy == 0 ? 0.0 : (eval - buy) / buy * 100);
                coinItems.add(item);
            }
        } catch (Exception e) {
            // [실행 흐름] 코인 조회 실패해도 주식 자산은 정상 반환 (독립적으로 처리)
            log.error("코인 자산 조회 실패", e);
        }
        double coinPnl = coinEval - coinBuy;
        double coinRate = coinBuy == 0 ? 0.0 : coinPnl / coinBuy * 100;
        // [실행 흐름] USDT(달러) 기준 코인 자산을 환율 적용해 원화로 변환
        long coinTotalKrw = Math.round((coinCash + coinEval) * exchangeRate);

        Map<String, Object> coin = new HashMap<>();
        coin.put("totalKrw", coinTotalKrw);   // 원화 환산 코인 총자산
        coin.put("cashUsdt", coinCash);        // 보유 USDT 잔고
        coin.put("evalUsdt", coinEval);        // 보유 코인 평가금(USDT)
        coin.put("pnlUsdt", coinPnl);          // 평가손익(USDT)
        coin.put("rate", coinRate);            // 수익률(%)
        coin.put("exchangeRate", exchangeRate);// 적용된 환율 (프론트 표시용)
        coin.put("items", coinItems);          // 보유 코인 상세 리스트

        // [실행 흐름] 주식(원) + 코인(원) = 통합 총 자산
        result.put("grandTotal", stockTotal + coinTotalKrw);
        result.put("stock", stock);
        result.put("coin", coin);
        return result;
    }

    /** ============================================================
     * [메서드 읽기] 보유 종목 상세 리스트 반환 (주식+코인 혼합).
     *
     * getAssetSummary()와 달리 요약 통계 없이 종목별 상세 정보만 반환한다.
     * 각 항목에 type 필드("stock"/"coin")를 포함해 프론트에서 구분할 수 있다.
     *
     * [실행 흐름]
     * 1. 주식 보유 목록 조회 → 각 종목 현재가 계산 → details에 추가
     * 2. 코인 보유 목록 조회 → 실시간 시세 적용 → details에 추가
     *    (코인 오류 시 try-catch로 격리 → 주식 데이터는 정상 반환)
     * ============================================================ */
    public List<Map<String, Object>> getAssetDetails(MemberDTO member) {
        List<Map<String, Object>> details = new ArrayList<>();
        if (member == null) return details;

        // ── 주식 보유 종목 ─────────────────────────────────────────
        List<Map<String, Object>> stockHoldings = orderStockMapper.getHoldingList(member.getUsername());
        for (Map<String, Object> h : stockHoldings) {
            String code = (String) h.get("STOCK_CODE");
            long count = ((Number) h.get("STOCK_COUNT")).longValue();
            long avgPrice = ((Number) h.get("STOCK_PURCHASE")).longValue();

            long currentPrice = stockService.getPriceFromCache(code);
            if (currentPrice <= 0) currentPrice = stockService.getCurrentPrice(code);

            long totalBuy = avgPrice * count;
            // [실행 흐름] 현재가 없으면 매수가 기준으로 평가 (손익 0)
            long totalEval = (currentPrice > 0) ? (currentPrice * count) : totalBuy;
            double profitRate = (totalBuy == 0) ? 0 : ((double) (totalEval - totalBuy) / totalBuy) * 100;

            Map<String, Object> map = new HashMap<>();
            map.put("type", "stock"); // 프론트에서 주식/코인 구분에 사용
            map.put("name", h.get("STOCK_NAME"));
            map.put("count", count);
            map.put("buyPrice", avgPrice);
            map.put("currentPrice", currentPrice);
            map.put("eval", totalEval);
            map.put("rate", String.format("%.2f", profitRate)); // 소수점 2자리 문자열
            details.add(map);
        }

        // ── 코인 보유 종목 ─────────────────────────────────────────
        try {
            // [실행 흐름] var → Java 10+ 타입 추론. List<CoinHoldingsDTO>와 동일하다.
            var coinHoldings = coinService.getHoldingList(member.getUsername());
            Map<String, Double> prices = coinMarketService.getTickerPriceMap();

            for (var ch : coinHoldings) {
                double count = ch.getCoinCount();
                double avgPrice = ch.getAvgPrice();
                double currentPrice = prices.getOrDefault(ch.getCoinCode(), avgPrice);

                double totalBuy = avgPrice * count;
                double totalEval = currentPrice * count;
                double profitRate = (totalBuy == 0) ? 0 : ((totalEval - totalBuy) / totalBuy) * 100;

                Map<String, Object> map = new HashMap<>();
                map.put("type", "coin"); // 프론트에서 주식/코인 구분에 사용
                map.put("name", ch.getCoinCode().replace("USDT", "")); // "BTCUSDT" → "BTC"
                map.put("count", count);
                map.put("buyPrice", avgPrice);
                map.put("currentPrice", currentPrice);
                map.put("eval", totalEval);
                map.put("rate", String.format("%.2f", profitRate));
                details.add(map);
            }
        } catch (Exception e) {
            log.error("코인 자산 상세 조회 실패", e);
        }

        return details;
    }
}
