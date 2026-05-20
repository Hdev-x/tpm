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

@Slf4j
@Service
public class StockMiniChartService {

    private final WebClient yahooClient = WebClient.builder()
            .baseUrl("https://query1.finance.yahoo.com")
            .defaultHeader("User-Agent", "Mozilla/5.0")
            .build();

    @Autowired
    private StockJoinMapper stockJoinMapper;

    @Autowired
    private StockDailyPriceMapper stockDailyPriceMapper;

    @Value("${app.stock.mini-chart.auto-refresh:true}")
    private boolean autoRefresh;

    @PostConstruct
    public void init() {
        if (!autoRefresh) return;

        Thread refreshThread = new Thread(() -> {
            try {
                Thread.sleep(3000);
                refreshTopMiniCharts(40);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } catch (Exception e) {
                log.warn("미니차트 초기 수집 실패: {}", e.getMessage());
            }
        }, "stock-mini-chart-refresh");
        refreshThread.setDaemon(true);
        refreshThread.start();
    }

    @Scheduled(cron = "0 30 16 * * MON-FRI", zone = "Asia/Seoul")
    public void refreshDailyMiniCharts() {
        if (!autoRefresh) return;
        log.info("주식 미니차트 일일 갱신을 시작합니다.");
        refreshTopMiniCharts(40);
    }

    public Map<String, List<Map<String, Object>>> getMiniCharts(int limit) {
        List<Map<String, Object>> stocks = getTopStocks(limit);
        Map<String, List<Map<String, Object>>> result = new LinkedHashMap<>();

        for (Map<String, Object> stock : stocks) {
            String code = String.valueOf(stock.get("code"));
            result.put(code, toMiniChartPoints(stockDailyPriceMapper.findOneYearByStockCode(code)));
        }

        return result;
    }

    public Map<String, Object> refreshTopMiniCharts(int limit) {
        List<Map<String, Object>> stocks = getTopStocks(limit);
        int success = 0;
        int failed = 0;

        for (Map<String, Object> stock : stocks) {
            String code = String.valueOf(stock.get("code"));
            try {
                List<StockDailyPriceDTO> prices = fetchYahooOneYear(code);
                for (StockDailyPriceDTO price : prices) {
                    stockDailyPriceMapper.upsert(price);
                }
                if (!prices.isEmpty()) success++;
                else failed++;
                Thread.sleep(700);
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

    private List<Map<String, Object>> getTopStocks(int limit) {
        List<Map<String, Object>> stocks = stockJoinMapper.findTop40Stocks();
        if (limit > 0 && stocks.size() > limit) {
            return stocks.subList(0, limit);
        }
        return stocks;
    }

    private List<Map<String, Object>> toMiniChartPoints(List<StockDailyPriceDTO> prices) {
        List<Map<String, Object>> points = new ArrayList<>();
        for (StockDailyPriceDTO price : prices) {
            points.add(Map.of(
                    "time", price.getTradeDate().toString(),
                    "close", price.getClosePrice()
            ));
        }
        return points;
    }

    private List<StockDailyPriceDTO> fetchYahooOneYear(String code) {
        List<StockDailyPriceDTO> ks = fetchYahooOneYear(code, code + ".KS");
        if (!ks.isEmpty()) return ks;
        return fetchYahooOneYear(code, code + ".KQ");
    }

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
        List<Number> timestamps = (List<Number>) result.get("timestamp");
        Map<String, Object> indicators = (Map<String, Object>) result.get("indicators");
        if (timestamps == null || indicators == null) return List.of();

        List<Map<String, Object>> quoteList = (List<Map<String, Object>>) indicators.get("quote");
        if (quoteList == null || quoteList.isEmpty()) return List.of();

        Map<String, Object> quote = quoteList.get(0);
        List<Number> closes = (List<Number>) quote.get("close");
        List<Number> volumes = (List<Number>) quote.get("volume");
        if (closes == null) return List.of();

        List<StockDailyPriceDTO> prices = new ArrayList<>();
        int size = Math.min(timestamps.size(), closes.size());
        ZoneId seoul = ZoneId.of("Asia/Seoul");

        for (int i = 0; i < size; i++) {
            Number close = closes.get(i);
            if (close == null) continue;

            StockDailyPriceDTO dto = new StockDailyPriceDTO();
            dto.setStockCode(code);
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
