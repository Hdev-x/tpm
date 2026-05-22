package com.tj.app.market.coin;

import lombok.extern.slf4j.Slf4j;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import java.time.Duration;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class CoinMarketService {

    private final WebClient bitgetClient;
    private final WebClient geckoClient;

    // 캐시 저장소 (메모리 내 ConcurrentHashMap 사용)
    private final Map<String, Object> cache = new ConcurrentHashMap<>();
    private final Map<String, Long> cacheExpiry = new ConcurrentHashMap<>();

    public CoinMarketService() {
        this.bitgetClient = WebClient.builder()
                .baseUrl("https://api.bitget.com")
                .build();
        this.geckoClient = WebClient.builder()
                .baseUrl("https://api.coingecko.com")
                .build();
    }

    /**
     * Bithumb Ticker 정보 조회 (캐싱 적용: 2초 - 실시간성 유지)
     */
    public Object getBithumbTicker(String orderCurrency, String paymentCurrency) {
        String cacheKey = "bithumb_" + orderCurrency + "_" + paymentCurrency;
        if (isCacheValid(cacheKey)) return cache.get(cacheKey);

        try {
            WebClient client = WebClient.builder().baseUrl("https://api.bithumb.com").build();
            Object data = client.get()
                    .uri("/public/ticker/" + orderCurrency + "_" + paymentCurrency)
                    .retrieve()
                    .bodyToMono(Object.class)
                    .block(Duration.ofSeconds(3));
            if (data != null) {
                putCache(cacheKey, data, 2);
                return data;
            }
        } catch (Exception e) {
            log.warn("⚠️ Bithumb Ticker 조회 실패: {}", e.getMessage());
        }
        return Collections.emptyMap();
    }

    /**
     * Bitget Tickers 정보 조회 (캐싱 적용: 10초)
     */
    public Object getTickers() {
        String cacheKey = "bitget_tickers";
        if (isCacheValid(cacheKey)) {
            return cache.get(cacheKey);
        }

        try {
            Object data = bitgetClient.get()
                    .uri("/api/v2/spot/market/tickers")
                    .retrieve()
                    .bodyToMono(Object.class)
                    .block(Duration.ofSeconds(5));
            
            if (data != null) {
                putCache(cacheKey, data, 10); // 10초 캐시
                return data;
            }
        } catch (Exception e) {
            log.error("❌ Bitget Tickers 조회 실패: {}", e.getMessage());
        }
        return Collections.emptyMap();
    }

    /**
     * 실시간 코인 시세를 Map<Symbol, Price> 형태로 반환 (캐시 활용)
     */
    public Map<String, Double> getTickerPriceMap() {
        Object tickersObj = getTickers();
        if (!(tickersObj instanceof Map)) return Collections.emptyMap();

        Map<String, Object> res = (Map<String, Object>) tickersObj;
        Object dataListObj = res.get("data");
        if (!(dataListObj instanceof java.util.List)) return Collections.emptyMap();

        java.util.List<Map<String, Object>> dataList = (java.util.List<Map<String, Object>>) dataListObj;
        Map<String, Double> priceMap = new java.util.HashMap<>();
        
        for (Map<String, Object> item : dataList) {
            String symbol = (String) item.get("symbol");
            Object lastPr = item.get("lastPr");
            if (symbol != null && lastPr != null) {
                try {
                    priceMap.put(symbol, Double.parseDouble(lastPr.toString()));
                } catch (Exception e) {}
            }
        }
        return priceMap;
    }

    /**
     * Bitget Candles 정보 조회 (캐싱 미적용 - 파라미터가 너무 다양함)
     */
    public Object getCandles(String symbol, String granularity, String limit, String endTime) {
        try {
            return bitgetClient.get()
                    .uri(uriBuilder -> {
                        // 1. 공통으로 들어가는 필수 파라미터들을 먼저 세팅합니다.
                        var builder = uriBuilder
                                .path("/api/v2/spot/market/candles")
                                .queryParam("symbol", symbol)
                                .queryParam("granularity", granularity)
                                .queryParam("limit", limit);
                        
                        // 2. [문제 해결 핵심] endTime이 존재할 때만 안전하게 queryParam을 추가합니다.
                        if (endTime != null && !endTime.isEmpty()) {
                            builder.queryParam("endTime", endTime);
                        }
                        
                        return builder.build();
                    })
                    .retrieve()
                    .bodyToMono(Object.class)
                    .block(java.time.Duration.ofSeconds(5)); // 임포트 에러 방지를 위해 java.time 풀경로 지정
        } catch (Exception e) {
            System.err.println("❌ Bitget Candles 조회 실패: symbol=" + symbol + ", error=" + e.getMessage());
            return java.util.Collections.emptyMap();
        }
    }

    /**
     * CoinGecko 추가 정보 조회 (캐싱 적용: 10분 - 429 방지 핵심)
     */
    public Object getExtraStats(String ticker) {
        String cacheKey = "gecko_" + ticker.toLowerCase();
        if (isCacheValid(cacheKey)) {
            return cache.get(cacheKey);
        }

        try {
            // CoinGecko API: /api/v3/coins/markets?vs_currency=usd&symbols=btc
            Object data = geckoClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/api/v3/coins/markets")
                            .queryParam("vs_currency", "usd")
                            .queryParam("symbols", ticker.toLowerCase())
                            .queryParam("order", "market_cap_desc")
                            .queryParam("per_page", "1")
                            .queryParam("page", "1")
                            .queryParam("sparkline", "false")
                            .build())
                    .retrieve()
                    .bodyToMono(Object.class)
                    .block(Duration.ofSeconds(5));

            if (data != null) {
                putCache(cacheKey, data, 600); // 10분(600초) 캐시
                return data;
            }
        } catch (Exception e) {
            log.warn("⚠️ CoinGecko 조회 실패 (정상 동작 중 429 가능성 높음): {}", e.getMessage());
        }
        return Collections.emptyList();
    }

    /**
     * CoinGecko 코인 로고 맵 조회 (캐싱: 1시간)
     * 반환 형태: { "BTC": "https://...", "ETH": "https://..." }
     */
    @SuppressWarnings("unchecked")
    public Map<String, String> getLogos() {
        String cacheKey = "gecko_logos";
        if (isCacheValid(cacheKey)) return (Map<String, String>) cache.get(cacheKey);

        Map<String, String> result = new HashMap<>();
        for (int page = 1; page <= 3; page++) {
            final int p = page;
            try {
                List<Map<String, Object>> data = geckoClient.get()
                        .uri(ub -> ub.path("/api/v3/coins/markets")
                                .queryParam("vs_currency", "usd")
                                .queryParam("per_page", "250")
                                .queryParam("page", p)
                                .build())
                        .retrieve()
                        .bodyToMono(new ParameterizedTypeReference<List<Map<String, Object>>>() {})
                        .block(Duration.ofSeconds(5));

                if (data != null) {
                    for (Map<String, Object> coin : data) {
                        Object sym = coin.get("symbol");
                        Object img = coin.get("image");
                        if (sym != null && img != null) {
                            result.put(sym.toString().toUpperCase(), img.toString());
                        }
                    }
                }
            } catch (Exception e) {
                log.warn("⚠️ CoinGecko 로고 페이지 {} 조회 실패: {}", p, e.getMessage());
            }
        }

        if (!result.isEmpty()) putCache(cacheKey, result, 3600); // 1시간 캐시
        return result;
    }

    // --- 캐시 도우미 함수 ---
    private boolean isCacheValid(String key) {
        Long expiry = cacheExpiry.get(key);
        return expiry != null && expiry > System.currentTimeMillis();
    }

    private void putCache(String key, Object data, int seconds) {
        cache.put(key, data);
        cacheExpiry.put(key, System.currentTimeMillis() + (seconds * 1000L));
    }
}
