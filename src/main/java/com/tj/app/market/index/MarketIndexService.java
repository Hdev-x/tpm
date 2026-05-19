package com.tj.app.market.index;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;

import java.net.URI;
import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.CompletableFuture;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Slf4j
@Service
public class MarketIndexService {

    private final ObjectMapper mapper = new ObjectMapper();

    private final WebClient naverClient = WebClient.builder()
            .baseUrl("https://polling.finance.naver.com")
            .defaultHeader("Referer", "https://finance.naver.com")
            .build();

    private final WebClient naverChartClient = WebClient.builder()
            .baseUrl("https://fchart.stock.naver.com")
            .defaultHeader("Referer", "https://finance.naver.com")
            .build();

    private final WebClient stooqClient = WebClient.builder()
            .baseUrl("https://stooq.com")
            .build();

    private final WebClient yahooClient = WebClient.builder()
            .baseUrl("https://query1.finance.yahoo.com")
            .defaultHeader("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36")
            .defaultHeader("Accept", "application/json")
            .defaultHeader("Referer", "https://finance.yahoo.com")
            .build();

    private final WebClient fxClient = WebClient.builder()
            .baseUrl("https://api.frankfurter.app")
            .clientConnector(new ReactorClientHttpConnector(
                    HttpClient.create().followRedirect(true)
            ))
            .build();

    private final WebClient bitgetClient = WebClient.builder()
            .baseUrl("https://api.bitget.com")
            .build();

    private final WebClient coinloreClient = WebClient.builder()
            .baseUrl("https://api.coinlore.net")
            .build();

    public List<MarketIndexDTO> getMarketIndex() {
        CompletableFuture<MarketIndexDTO> f1 = CompletableFuture.supplyAsync(this::fetchExchangeRate);
        CompletableFuture<MarketIndexDTO> f2 = CompletableFuture.supplyAsync(() -> fetchNaver("코스피", "SERVICE_INDEX:KOSPI", "KOSPI", true));
        CompletableFuture<MarketIndexDTO> f3 = CompletableFuture.supplyAsync(() -> fetchNaver("코스닥", "SERVICE_INDEX:KOSDAQ", "KOSDAQ", true));
        CompletableFuture<MarketIndexDTO> f4 = CompletableFuture.supplyAsync(this::fetchNasdaq);
        CompletableFuture<MarketIndexDTO> f5 = CompletableFuture.supplyAsync(this::fetchSP500);
        CompletableFuture<MarketIndexDTO> f6 = CompletableFuture.supplyAsync(this::fetchBitcoin);
        CompletableFuture<MarketIndexDTO> f7 = CompletableFuture.supplyAsync(this::fetchBtcDominance);

        return Stream.of(f1, f2, f3, f4, f5, f6, f7)
                .map(CompletableFuture::join)
                .filter(d -> d != null)
                .collect(Collectors.toList());
    }

    private MarketIndexDTO fetchNaver(String name, String query, String chartSymbol, boolean divideBy100) {
        try {
            CompletableFuture<String> priceFuture = CompletableFuture.supplyAsync(() ->
                    naverClient.get().uri("/api/realtime?query=" + query)
                            .retrieve().bodyToMono(String.class).block(Duration.ofSeconds(5)));
            CompletableFuture<List<Double>> histFuture = CompletableFuture.supplyAsync(() ->
                    fetchNaverHistory(chartSymbol, divideBy100));

            Map<String, Object> res = mapper.readValue(priceFuture.join(), Map.class);
            List<Map<String, Object>> areas = (List<Map<String, Object>>)
                    ((Map<String, Object>) res.get("result")).get("areas");
            if (areas == null || areas.isEmpty()) return null;

            List<Map<String, Object>> datas = (List<Map<String, Object>>) areas.get(0).get("datas");
            if (datas == null || datas.isEmpty()) return null;

            Map<String, Object> d = datas.get(0);
            double nv = toDouble(d.get("nv"));
            double cv = toDouble(d.get("cv"));
            double cr = toDouble(d.get("cr"));
            if (divideBy100) { nv /= 100.0; cv /= 100.0; }

            boolean up = cr >= 0;
            String sign = up ? "+" : "";
            return new MarketIndexDTO(name,
                    String.format("%,.2f", nv),
                    sign + String.format("%,.2f", cv),
                    sign + String.format("%.2f", cr),
                    up, histFuture.join());
        } catch (Exception e) {
            log.error("{} 조회 실패: {}", name, e.getMessage());
            return null;
        }
    }

    private List<Double> fetchNaverHistory(String symbol, boolean divideBy100) {
        try {
            String xml = naverChartClient.get()
                    .uri("/sise.nhn?symbol=" + symbol + "&timeframe=day&count=30&requestType=0")
                    .retrieve().bodyToMono(String.class).block(Duration.ofSeconds(5));

            List<Double> prices = new ArrayList<>();
            Matcher m = Pattern.compile("data=\"([^\"]+)\"").matcher(xml);
            while (m.find()) {
                String[] parts = m.group(1).split("\\|");
                if (parts.length >= 5) {
                    double close = Double.parseDouble(parts[4]);
                    prices.add(divideBy100 ? close / 100.0 : close);
                }
            }
            return prices;
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    private MarketIndexDTO fetchNasdaq() {
        try {
            CompletableFuture<String> priceFuture = CompletableFuture.supplyAsync(() ->
                    stooqClient.get().uri("/q/l/?s=^NDX&f=sd2t2ohlcv&h&e=json")
                            .retrieve().bodyToMono(String.class).block(Duration.ofSeconds(5)));
            CompletableFuture<List<Double>> histFuture = CompletableFuture.supplyAsync(() ->
                    fetchYahooHistory("%5ENDX"));

            Map<String, Object> res = mapper.readValue(priceFuture.join(), Map.class);
            List<Map<String, Object>> symbols = (List<Map<String, Object>>) res.get("symbols");
            if (symbols == null || symbols.isEmpty()) return null;

            Map<String, Object> d = symbols.get(0);
            double close = toDouble(d.get("close"));
            double open = toDouble(d.get("open"));
            double cv = close - open;
            double cr = open > 0 ? cv / open * 100 : 0;

            boolean up = cr >= 0;
            String sign = up ? "+" : "";
            return new MarketIndexDTO("나스닥",
                    String.format("%,.2f", close),
                    sign + String.format("%,.2f", cv),
                    sign + String.format("%.2f", cr),
                    up, histFuture.join());
        } catch (Exception e) {
            log.error("나스닥 조회 실패: {}", e.getMessage());
            return null;
        }
    }

    private MarketIndexDTO fetchSP500() {
        try {
            List<Double> prices = fetchYahooHistory("%5EGSPC");
            if (prices.size() < 2) return null;

            double close = prices.get(prices.size() - 1);
            double prev  = prices.get(prices.size() - 2);
            double cv = close - prev;
            double cr = prev > 0 ? cv / prev * 100 : 0;

            boolean up = cv >= 0;
            String sign = up ? "+" : "";
            return new MarketIndexDTO("S&P 500",
                    String.format("%,.2f", close),
                    sign + String.format("%,.2f", cv),
                    sign + String.format("%.2f", cr),
                    up, prices);
        } catch (Exception e) {
            log.error("S&P500 조회 실패: {}", e.getMessage());
            return null;
        }
    }

    private MarketIndexDTO fetchBitcoin() {
        try {
            CompletableFuture<String> tickerFuture = CompletableFuture.supplyAsync(() ->
                    bitgetClient.get()
                            .uri("/api/v2/spot/market/tickers?symbol=BTCUSDT")
                            .retrieve().bodyToMono(String.class).block(Duration.ofSeconds(5)));
            CompletableFuture<List<Double>> histFuture = CompletableFuture.supplyAsync(() ->
                    fetchBitgetCandles("BTCUSDT"));

            Map<String, Object> res = mapper.readValue(tickerFuture.join(), Map.class);
            List<Map<String, Object>> data = (List<Map<String, Object>>) res.get("data");
            if (data == null || data.isEmpty()) return null;

            Map<String, Object> t = data.get(0);
            double last = toDouble(t.get("lastPr"));
            double open = toDouble(t.get("open"));
            double cv = last - open;
            double cr = open > 0 ? cv / open * 100 : 0;

            boolean up = cv >= 0;
            String sign = up ? "+" : "";
            return new MarketIndexDTO("비트코인",
                    String.format("%,.0f", last),
                    sign + String.format("%,.0f", cv),
                    sign + String.format("%.2f", cr),
                    up, histFuture.join());
        } catch (Exception e) {
            log.error("비트코인 조회 실패: {}", e.getMessage());
            return null;
        }
    }

    private List<Double> fetchBitgetCandles(String symbol) {
        try {
            String json = bitgetClient.get()
                    .uri("/api/v2/spot/market/candles?symbol=" + symbol + "&granularity=1Dutc&limit=30")
                    .retrieve().bodyToMono(String.class).block(Duration.ofSeconds(5));

            Map<String, Object> res = mapper.readValue(json, Map.class);
            List<List<Object>> data = (List<List<Object>>) res.get("data");
            if (data == null) return new ArrayList<>();

            // Bitget returns newest first → reverse, close at index 4
            List<Double> prices = new ArrayList<>();
            for (int i = data.size() - 1; i >= 0; i--) {
                prices.add(toDouble(data.get(i).get(4)));
            }
            return prices;
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    private MarketIndexDTO fetchBtcDominance() {
        try {
            CompletableFuture<String> domFuture = CompletableFuture.supplyAsync(() ->
                    coinloreClient.get().uri("/api/global/")
                            .retrieve().bodyToMono(String.class).block(Duration.ofSeconds(5)));
            CompletableFuture<List<Double>> histFuture = CompletableFuture.supplyAsync(() ->
                    fetchBitgetCandles("BTCUSDT"));

            List<Map<String, Object>> arr = mapper.readValue(domFuture.join(), List.class);
            if (arr == null || arr.isEmpty()) return null;

            Map<String, Object> data = arr.get(0);
            double dom = toDouble(data.get("btc_d"));
            double change = toDouble(data.get("mcap_change"));
            boolean up = change >= 0;
            String sign = up ? "+" : "";
            return new MarketIndexDTO("BTC 도미넌스",
                    String.format("%.2f%%", dom),
                    sign + String.format("%.2f%%", change),
                    sign + String.format("%.2f", change),
                    up, histFuture.join());
        } catch (Exception e) {
            log.error("BTC 도미넌스 조회 실패: {}", e.getMessage());
            return null;
        }
    }

    private List<Double> fetchYahooHistory(String encodedSymbol) {
        try {
            String json = yahooClient.get()
                    .uri(URI.create("https://query1.finance.yahoo.com/v8/finance/chart/" + encodedSymbol + "?interval=1d&range=1mo"))
                    .retrieve().bodyToMono(String.class).block(Duration.ofSeconds(5));

            Map<String, Object> res = mapper.readValue(json, Map.class);
            Map<String, Object> chart = (Map<String, Object>) res.get("chart");
            List<Map<String, Object>> results = (List<Map<String, Object>>) chart.get("result");
            if (results == null || results.isEmpty()) return new ArrayList<>();

            Map<String, Object> indicators = (Map<String, Object>) results.get(0).get("indicators");
            List<Map<String, Object>> quotes = (List<Map<String, Object>>) indicators.get("quote");
            List<Double> closes = (List<Double>) quotes.get(0).get("close");
            return closes.stream().filter(p -> p != null).collect(Collectors.toList());
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    private MarketIndexDTO fetchExchangeRate() {
        try {
            final String histUri = "/" + LocalDate.now().minusDays(35) + ".." + LocalDate.now() + "?from=USD&to=KRW";

            CompletableFuture<String> todayFuture = CompletableFuture.supplyAsync(() ->
                    fxClient.get().uri("/latest?from=USD&to=KRW")
                            .retrieve().bodyToMono(String.class).block(Duration.ofSeconds(5)));
            CompletableFuture<String> histFuture = CompletableFuture.supplyAsync(() ->
                    fxClient.get().uri(histUri)
                            .retrieve().bodyToMono(String.class).block(Duration.ofSeconds(5)));

            Map<String, Object> todayRes = mapper.readValue(todayFuture.join(), Map.class);
            Map<String, Object> todayRates = (Map<String, Object>) todayRes.get("rates");
            if (todayRates == null) return null;
            double today = toDouble(todayRates.get("KRW"));

            List<Double> prices = new ArrayList<>();
            Map<String, Object> histRes = mapper.readValue(histFuture.join(), Map.class);
            Map<String, Object> histRates = (Map<String, Object>) histRes.get("rates");
            if (histRates != null) {
                new TreeMap<>(histRates).forEach((date, rateObj) -> {
                    Map<String, Object> dayRate = (Map<String, Object>) rateObj;
                    prices.add(toDouble(dayRate.get("KRW")));
                });
            }

            double prev = prices.size() >= 2 ? prices.get(prices.size() - 2) : today;
            double cv = today - prev;
            double cr = prev > 0 ? cv / prev * 100 : 0;
            boolean up = cv >= 0;
            String sign = up ? "+" : "";
            return new MarketIndexDTO("달러 환율",
                    String.format("%,.2f", today),
                    sign + String.format("%,.2f", cv),
                    sign + String.format("%.2f", cr),
                    up, prices);
        } catch (Exception e) {
            log.error("환율 조회 실패: {}", e.getMessage());
            return null;
        }
    }

    private double toDouble(Object val) {
        if (val == null) return 0;
        try { return Double.parseDouble(val.toString()); }
        catch (Exception e) { return 0; }
    }
}
