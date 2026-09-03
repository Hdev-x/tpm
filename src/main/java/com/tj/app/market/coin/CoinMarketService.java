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

/** ============================================================
 * [클래스 읽기] 코인 시세·캔들·로고 등 외부 API 데이터를 가져오는 서비스.
 *
 * [@Slf4j] Lombok이 자동으로 'private static final Logger log = ...' 필드를 생성한다.
 *          log.warn() / log.error() / log.info() 로 사용한다.
 *
 * [사용하는 외부 API]
 *   1. Bitget  (bitgetClient) : 코인 시세·캔들 (메인 데이터 소스)
 *   2. Bithumb (메서드 내부 임시 생성) : 원화 ticker (호출 빈도가 낮아 필드로 두지 않음)
 *   3. CoinGecko (geckoClient) : 시가총액·등락률 등 부가 정보 + 코인 로고 이미지 URL
 *
 * [WebClient 생성 위치]
 *   Bitget·CoinGecko는 자주 호출하므로 필드로 미리 만들어 커넥션 풀을 재사용한다.
 *   Bithumb은 getBithumbTicker() 내부에서 매번 새로 만든다. (호출 빈도 낮음)
 *
 * [TTL 인메모리 캐시]
 *   cache     : key → 응답 데이터 (Object)
 *   cacheExpiry : key → 만료 시각 (Unix ms)
 *   ConcurrentHashMap을 써서 멀티스레드 환경에서 동시 접근해도 안전하다.
 *   외부 캐시 라이브러리(Caffeine, Redis) 없이 직접 TTL을 구현한 패턴이다.
 * ============================================================ */
@Slf4j
@Service
public class CoinMarketService {

    /** Bitget API (https://api.bitget.com) 용 WebClient — 필드로 재사용 */
    private final WebClient bitgetClient;

    /** CoinGecko API (https://api.coingecko.com) 용 WebClient — 필드로 재사용 */
    private final WebClient geckoClient;

    /** 캐시 저장소: key → 응답 데이터 (Object). ConcurrentHashMap = 스레드 안전한 HashMap */
    private final Map<String, Object> cache = new ConcurrentHashMap<>();

    /** 캐시 만료 시각 저장: key → 만료 Unix 밀리초. isCacheValid()에서 비교한다. */
    private final Map<String, Long> cacheExpiry = new ConcurrentHashMap<>();

    /** ============================================================
     * [생성자 읽기] WebClient 두 개를 초기화한다.
     *
     * [@Autowired 없음] Spring이 자동 주입할 의존성이 없으므로 기본 생성자만 사용.
     * baseUrl을 지정하면 이후 uri() 호출 시 경로만 추가하면 된다.
     * ============================================================ */
    public CoinMarketService() {
        this.bitgetClient = WebClient.builder()
                .baseUrl("https://api.bitget.com")
                // 전체 티커 응답이 기본 버퍼(256KB)를 넘어 실패하므로 상한을 5MB로 확장
                .codecs(c -> c.defaultCodecs().maxInMemorySize(5 * 1024 * 1024))
                .build();
        this.geckoClient = WebClient.builder()
                .baseUrl("https://api.coingecko.com")
                .build();
    }

    /** ============================================================
     * [메서드 읽기] Bithumb 현재가(Ticker) 조회 — 캐시 TTL 2초.
     *
     * [캐시가 짧은 이유] Ticker는 실시간성이 중요하므로 2초만 캐싱한다.
     *
     * [WebClient 생성 위치] 이 메서드 안에서만 사용하고 호출 빈도가 낮으므로
     *   매번 새로운 WebClient 인스턴스를 만든다. (필드로 두지 않음)
     *
     * [block(Duration)] 비동기 WebClient를 동기로 전환한다.
     *   3초 안에 응답이 없으면 예외를 던진다.
     *
     * @param orderCurrency   조회할 코인 심볼 (예: "BTC")
     * @param paymentCurrency 결제 통화 (예: "KRW")
     * @return Bithumb API 응답 Map, 실패 시 빈 Map
     * ============================================================ */
    public Object getBithumbTicker(String orderCurrency, String paymentCurrency) {
        // [실행 흐름] 캐시 키: "bithumb_BTC_KRW" 형태
        String cacheKey = "bithumb_" + orderCurrency + "_" + paymentCurrency;
        if (isCacheValid(cacheKey)) return cache.get(cacheKey); // [실행 흐름] 유효한 캐시가 있으면 즉시 반환

        try {
            // [실행 흐름] Bithumb용 WebClient를 메서드 내부에서 임시 생성
            WebClient client = WebClient.builder().baseUrl("https://api.bithumb.com").build();
            Object data = client.get()
                    .uri("/public/ticker/" + orderCurrency + "_" + paymentCurrency)
                    .retrieve()
                    .bodyToMono(Object.class) // 응답을 Java Object(Map/List)로 역직렬화
                    .block(Duration.ofSeconds(3)); // 최대 3초 대기 (동기 전환)

            if (data != null) {
                putCache(cacheKey, data, 2); // [실행 흐름] 2초 캐시 저장 후 반환
                return data;
            }
        } catch (Exception e) {
            log.warn("⚠️ Bithumb Ticker 조회 실패: {}", e.getMessage());
        }
        return Collections.emptyMap(); // [실행 흐름] 실패 시 빈 Map 반환 (NPE 방지)
    }

    /** ============================================================
     * [메서드 읽기] Bitget 전체 스팟 Ticker 목록 조회 — 캐시 TTL 10초.
     *
     * [응답 구조] { "code": "00000", "data": [ { "symbol":"BTCUSDT", "lastPr":"..." }, ... ] }
     * data 배열에 모든 스팟 거래쌍의 현재가 정보가 담긴다.
     *
     * [캐시 10초] Ticker 전체 목록은 용량이 크므로 10초 캐싱으로 API 호출을 줄인다.
     *
     * @return Bitget API 전체 응답 Object, 실패 시 빈 Map
     * ============================================================ */
    public Object getTickers() {
        String cacheKey = "bitget_tickers";
        if (isCacheValid(cacheKey)) {
            return cache.get(cacheKey); // [실행 흐름] 캐시 히트 → 즉시 반환
        }

        try {
            Object data = bitgetClient.get()
                    .uri("/api/v2/spot/market/tickers") // Bitget 스팟 전체 Ticker 엔드포인트
                    .retrieve()
                    .bodyToMono(Object.class)
                    .block(Duration.ofSeconds(5)); // 최대 5초 대기

            if (data != null) {
                putCache(cacheKey, data, 10); // [실행 흐름] 10초 캐시 저장
                return data;
            }
        } catch (Exception e) {
            log.error("❌ Bitget Tickers 조회 실패: {}", e.getMessage());
        }
        return Collections.emptyMap();
    }

    /** ============================================================
     * [메서드 읽기] Bitget Ticker 응답에서 { 심볼 → 현재가 } 맵을 추출한다.
     *
     * [실행 흐름]
     * 1. getTickers() 호출 → 캐시 또는 API에서 전체 Ticker 목록 가져옴
     * 2. 응답이 Map인지 확인 (방어 코드: 실패 시 emptyMap이 반환될 수 있음)
     * 3. data 배열 꺼내기 → 각 항목의 symbol·lastPr 파싱
     * 4. { "BTCUSDT" → 105000.5, "ETHUSDT" → 3200.0 } 형태의 Map 반환
     *
     * [캐스팅 이유] bodyToMono(Object.class)는 JSON을 LinkedHashMap/ArrayList로 역직렬화한다.
     *   실제 타입은 Map<String,Object>이지만 컴파일러는 Object로만 알고 있으므로 강제 캐스팅이 필요하다.
     *
     * @return 심볼 → 가격 Map (파싱 실패 항목은 무시)
     * ============================================================ */
    public Map<String, Double> getTickerPriceMap() {
        Object tickersObj = getTickers();
        // [코드 읽기] instanceof로 타입 확인 → 실패 응답(emptyMap)이 들어오면 조기 반환
        if (!(tickersObj instanceof Map)) return Collections.emptyMap();

        Map<String, Object> res = (Map<String, Object>) tickersObj;
        Object dataListObj = res.get("data"); // [코드 읽기] "data" 키에 Ticker 배열이 있다
        if (!(dataListObj instanceof java.util.List)) return Collections.emptyMap();

        java.util.List<Map<String, Object>> dataList = (java.util.List<Map<String, Object>>) dataListObj;
        Map<String, Double> priceMap = new java.util.HashMap<>();

        for (Map<String, Object> item : dataList) {
            String symbol = (String) item.get("symbol"); // 예: "BTCUSDT"
            Object lastPr = item.get("lastPr");          // 현재가 (문자열 형태로 내려옴)
            if (symbol != null && lastPr != null) {
                try {
                    // [코드 읽기] lastPr는 String이므로 Double.parseDouble()로 변환
                    priceMap.put(symbol, Double.parseDouble(lastPr.toString()));
                } catch (Exception e) {
                    // [코드 읽기] 변환 실패 항목은 조용히 건너뜀 (숫자가 아닌 값 방어)
                }
            }
        }
        return priceMap;
    }

    /** ============================================================
     * [메서드 읽기] Bitget 캔들(OHLCV) 데이터 조회 — 캐시 미적용.
     *
     * [캐시를 안 쓰는 이유] symbol, granularity, limit, endTime 조합이 너무 다양해
     *   캐시 키가 폭발적으로 늘어난다. 대신 Controller에서 필요 시 따로 관리한다.
     *
     * [UriBuilder 람다] uri(uriBuilder -> { ... }) 형태로 URL을 동적으로 구성한다.
     *   queryParam("key", value)를 메서드 체이닝으로 추가한 뒤 .build()로 완성한다.
     *
     * [endTime 조건부 추가 — 핵심 패턴]
     *   endTime이 null이거나 빈 문자열일 때 queryParam을 추가하면 Bitget이 오류를 반환한다.
     *   if 블록으로 null/empty 체크 후에만 추가해야 한다.
     *
     * @param symbol      조회할 심볼 (예: "BTCUSDT")
     * @param granularity 캔들 주기 (예: "1min", "1hour", "1day")
     * @param limit       캔들 개수 (예: "100")
     * @param endTime     조회 기준 종료 시각 (Unix ms, null이면 최신 기준)
     * @return Bitget 캔들 응답 Object, 실패 시 빈 Map
     * ============================================================ */
    public Object getCandles(String symbol, String granularity, String limit, String endTime) {
        try {
            return bitgetClient.get()
                    .uri(uriBuilder -> {
                        // [실행 흐름] 필수 파라미터 3개를 먼저 세팅
                        var builder = uriBuilder
                                .path("/api/v2/spot/market/candles")
                                .queryParam("symbol", symbol)
                                .queryParam("granularity", granularity)
                                .queryParam("limit", limit);

                        // [실행 흐름] endTime이 있을 때만 추가 (null 파라미터 전송 방지)
                        if (endTime != null && !endTime.isEmpty()) {
                            builder.queryParam("endTime", endTime);
                        }

                        return builder.build();
                    })
                    .retrieve()
                    .bodyToMono(Object.class)
                    // [코드 읽기] java.time.Duration — import 충돌 방지 목적으로 패키지 전체 경로 사용
                    .block(java.time.Duration.ofSeconds(5));
        } catch (Exception e) {
            System.err.println("❌ Bitget Candles 조회 실패: symbol=" + symbol + ", error=" + e.getMessage());
            return java.util.Collections.emptyMap();
        }
    }

    /** ============================================================
     * [메서드 읽기] CoinGecko에서 코인 부가 정보(시가총액·24h 등락률 등) 조회 — 캐시 TTL 10분.
     *
     * [CoinGecko 무료 API 주의]
     *   무료 플랜은 분당 요청 수가 제한된다(429 Too Many Requests).
     *   10분(600초) 캐싱으로 반복 호출을 최소화한다.
     *
     * [API 엔드포인트] /api/v3/coins/markets
     *   vs_currency=usd : 시세 기준 통화
     *   symbols=btc     : 조회할 코인 (소문자로 변환해 전달)
     *   per_page=1      : 결과 1건만 가져옴
     *   sparkline=false : 7일 스파크라인 데이터 제외 (응답 크기 절감)
     *
     * @param ticker 코인 심볼 (예: "BTC" → "btc"로 변환해 쿼리)
     * @return CoinGecko List 응답 Object, 실패 시 빈 List
     * ============================================================ */
    public Object getExtraStats(String ticker) {
        String cacheKey = "gecko_" + ticker.toLowerCase(); // 예: "gecko_btc"
        if (isCacheValid(cacheKey)) {
            return cache.get(cacheKey); // [실행 흐름] 10분 이내 캐시면 즉시 반환
        }

        try {
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
                putCache(cacheKey, data, 600); // [실행 흐름] 10분(600초) 캐시 저장
                return data;
            }
        } catch (Exception e) {
            // [주의] 429는 CoinGecko 무료 플랜 초과. warn으로 기록만 하고 emptyList 반환
            log.warn("⚠️ CoinGecko 조회 실패 (정상 동작 중 429 가능성 높음): {}", e.getMessage());
        }
        return Collections.emptyList();
    }

    /** ============================================================
     * [메서드 읽기] CoinGecko에서 코인 로고 이미지 URL 맵을 수집한다 — 캐시 TTL 1시간.
     *
     * [실행 흐름]
     * 1. 캐시 유효하면 즉시 반환
     * 2. CoinGecko /api/v3/coins/markets를 페이지 1~3(각 250개)로 3번 호출
     * 3. 각 코인의 "symbol"(예: "btc")·"image"(URL) 추출
     * 4. result 맵에 symbol.toUpperCase() → imageUrl 형태로 저장
     * 5. 전체 수집 완료 후 1시간 캐시 저장 후 반환
     *
     * [ParameterizedTypeReference] bodyToMono(List.class) 로 하면 제네릭 타입이 지워져
     *   항목 타입을 알 수 없다. ParameterizedTypeReference<List<Map<String,Object>>>{}로
     *   런타임에도 List<Map<String,Object>> 타입 정보를 보존할 수 있다.
     *
     * [final int p = page] 람다 안에서 외부 변수를 쓰려면 effectively final이어야 한다.
     *   for 루프 변수 page는 변하므로, p 에 복사해서 람다에 전달한다.
     *
     * [@SuppressWarnings("unchecked")] cache.get(cacheKey)는 Object를 반환하는데
     *   Map<String,String>으로 강제 캐스팅하면 컴파일러가 경고를 낸다.
     *   putCache() 시 실제로 Map<String,String>을 저장하므로 안전하다고 판단해 억제한다.
     *
     * @return { "BTC" → logoUrl, "ETH" → logoUrl, ... } 형태의 Map
     * ============================================================ */
    @SuppressWarnings("unchecked")
    public Map<String, String> getLogos() {
        String cacheKey = "gecko_logos";
        if (isCacheValid(cacheKey)) return (Map<String, String>) cache.get(cacheKey);

        Map<String, String> result = new HashMap<>();

        // [실행 흐름] 페이지 1~3 순회 (250개 × 3 = 최대 750개 코인 로고 수집)
        for (int page = 1; page <= 3; page++) {
            final int p = page; // [코드 읽기] 람다 캡처용 final 복사본 (람다는 effectively final 변수만 참조 가능)
            try {
                // [코드 읽기] ParameterizedTypeReference: 제네릭 타입 정보를 런타임에 보존
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
                        Object sym = coin.get("symbol"); // 예: "btc"
                        Object img = coin.get("image");  // 예: "https://coin-images.../btc.png"
                        if (sym != null && img != null) {
                            // [코드 읽기] 심볼을 대문자로 통일 ("btc" → "BTC")
                            result.put(sym.toString().toUpperCase(), img.toString());
                        }
                    }
                }
            } catch (Exception e) {
                log.warn("⚠️ CoinGecko 로고 페이지 {} 조회 실패: {}", p, e.getMessage());
            }
        }

        // [실행 흐름] 하나라도 수집됐으면 1시간(3600초) 캐시 저장
        if (!result.isEmpty()) putCache(cacheKey, result, 3600);
        return result;
    }

    // ============================================================
    // [내부 캐시 도우미 메서드]
    // ============================================================

    /** ============================================================
     * [메서드 읽기] 해당 캐시 키가 아직 유효한지 확인한다.
     *
     * [판단 기준] cacheExpiry에 저장된 만료 시각(Unix ms) > 현재 시각이면 유효.
     *   키가 없거나 만료됐으면 false를 반환한다.
     *
     * @param key 캐시 키
     * @return true = 캐시 사용 가능, false = 재조회 필요
     * ============================================================ */
    private boolean isCacheValid(String key) {
        Long expiry = cacheExpiry.get(key);
        // [코드 읽기] expiry가 null이면 캐시 미존재 → false
        //             expiry <= currentTime이면 만료됨 → false
        return expiry != null && expiry > System.currentTimeMillis();
    }

    /** ============================================================
     * [메서드 읽기] 캐시에 데이터를 저장하고 만료 시각을 기록한다.
     *
     * @param key     캐시 키
     * @param data    저장할 응답 데이터
     * @param seconds 캐시 유효 시간 (초 단위)
     * ============================================================ */
    private void putCache(String key, Object data, int seconds) {
        cache.put(key, data);
        // [코드 읽기] seconds * 1000L → 초 → 밀리초 변환. 'L'을 붙여 int 오버플로를 방지한다.
        cacheExpiry.put(key, System.currentTimeMillis() + (seconds * 1000L));
    }
}
