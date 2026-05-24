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

/** ============================================================
 * [클래스 읽기] 시장 주요 지수(코스피·코스닥·나스닥·S&P500·달러환율·비트코인·BTC 도미넌스)를
 * 여러 외부 API에서 동시에 조회해 리스트로 반환하는 서비스.
 *
 * [핵심 설계]
 * - 각 지수를 별도 CompletableFuture로 병렬 실행 → 7개를 순차 호출하면 최대 35초,
 *   병렬로 실행하면 가장 느린 하나의 응답 시간(≒5초)으로 단축된다.
 * - 외부 API마다 전용 WebClient 인스턴스를 사용한다.
 *   각 API는 고유한 baseUrl·헤더(Referer, User-Agent)가 필요하기 때문이다.
 * - 개별 조회에서 예외가 발생하면 null을 반환하고, 최종 리스트에서 null을 필터링한다.
 *   한 지수 조회 실패가 전체 페이지 렌더링을 막지 않도록 방어한다.
 *
 * [@Slf4j] Lombok이 log 필드를 자동 생성한다.
 *   log.error(), log.warn() 으로 콘솔/로그파일에 오류를 기록한다.
 * ============================================================ */
@Slf4j
@Service
public class MarketIndexService {

	// [실행 흐름] Jackson ObjectMapper: JSON 문자열 → Map 으로 파싱할 때 사용
	private final ObjectMapper mapper = new ObjectMapper();

	// [실행 흐름] 네이버 금융 폴링 API (코스피·코스닥 실시간 시세)
	// Referer 헤더 필수 → 없으면 네이버가 403 반환
	private final WebClient naverClient = WebClient.builder().baseUrl("https://polling.finance.naver.com")
			.defaultHeader("Referer", "https://finance.naver.com").build();

	// [실행 흐름] 네이버 차트 API (코스피·코스닥 30일 종가 히스토리)
	private final WebClient naverChartClient = WebClient.builder().baseUrl("https://fchart.stock.naver.com")
			.defaultHeader("Referer", "https://finance.naver.com").build();

	// [실행 흐름] Stooq API (나스닥 ^NDX 현재가 조회)
	private final WebClient stooqClient = WebClient.builder().baseUrl("https://stooq.com").build();

	// [실행 흐름] Yahoo Finance API (나스닥·S&P500 히스토리 조회)
	// User-Agent 없으면 403 차단 → 브라우저처럼 위장하는 헤더를 추가한다
	private final WebClient yahooClient = WebClient.builder().baseUrl("https://query1.finance.yahoo.com")
			.defaultHeader("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36")
			.defaultHeader("Accept", "application/json").defaultHeader("Referer", "https://finance.yahoo.com").build();

	// [실행 흐름] Frankfurter API (달러 환율 조회, 리다이렉트 자동 추적 설정 필수)
	private final WebClient fxClient = WebClient.builder().baseUrl("https://api.frankfurter.app")
			.clientConnector(new ReactorClientHttpConnector(HttpClient.create().followRedirect(true))).build();

	// [실행 흐름] Bitget API (비트코인 현재가 + 30일 캔들 조회)
	private final WebClient bitgetClient = WebClient.builder().baseUrl("https://api.bitget.com").build();

	// [실행 흐름] Coinlore API (BTC 도미넌스 조회)
	private final WebClient coinloreClient = WebClient.builder().baseUrl("https://api.coinlore.net").build();

	/** ============================================================
	 * 7개 지수를 병렬로 조회해 리스트로 반환한다.
	 *
	 * [실행 흐름]
	 * 1. CompletableFuture.supplyAsync() 로 각 fetch 메서드를 별도 스레드에서 실행
	 * 2. Stream.of(f1..f7).map(::join) → 모든 Future가 끝날 때까지 기다린 뒤 결과를 모음
	 * 3. filter(d -> d != null) → 조회 실패한 지수(null 반환)는 제외
	 * 4. collect(toList()) → 최종 리스트 반환 → Controller가 JSON으로 내려보냄
	 * ============================================================ */
	public List<MarketIndexDTO> getMarketIndex() {
		CompletableFuture<MarketIndexDTO> f1 = CompletableFuture.supplyAsync(this::fetchExchangeRate);
		CompletableFuture<MarketIndexDTO> f2 = CompletableFuture
				.supplyAsync(() -> fetchNaver("코스피", "SERVICE_INDEX:KOSPI", "KOSPI", true));
		CompletableFuture<MarketIndexDTO> f3 = CompletableFuture
				.supplyAsync(() -> fetchNaver("코스닥", "SERVICE_INDEX:KOSDAQ", "KOSDAQ", true));
		CompletableFuture<MarketIndexDTO> f4 = CompletableFuture.supplyAsync(this::fetchNasdaq);
		CompletableFuture<MarketIndexDTO> f5 = CompletableFuture.supplyAsync(this::fetchSP500);
		CompletableFuture<MarketIndexDTO> f6 = CompletableFuture.supplyAsync(this::fetchBitcoin);
		CompletableFuture<MarketIndexDTO> f7 = CompletableFuture.supplyAsync(this::fetchBtcDominance);

		// [실행 흐름] 전체 Future를 Stream으로 묶어 join → filter → 리스트 반환
		return Stream.of(f1, f2, f3, f4, f5, f6, f7).map(CompletableFuture::join).filter(d -> d != null)
				.collect(Collectors.toList());
	}

	/** ============================================================
	 * 네이버 금융 API로 국내 지수(코스피·코스닥)를 조회한다.
	 *
	 * [실행 흐름]
	 * 1. priceFuture: 네이버 realtime API → 현재가(nv)·등락폭(cv)·등락률(cr) 파싱
	 * 2. histFuture: 네이버 차트 API → 30일 종가 리스트 동시 조회
	 * 3. divideBy100: 네이버 API는 값에 ×100 된 정수로 내려오므로 나눠서 실제 값으로 복원
	 *    (예: 265032 → 2650.32)
	 * 4. up 플래그: cr(등락률) ≥ 0 이면 상승 → JSP에서 색상 분기에 사용
	 *
	 * @param name         표시 이름 ("코스피", "코스닥")
	 * @param query        API 쿼리 파라미터 ("SERVICE_INDEX:KOSPI")
	 * @param chartSymbol  차트 API 심볼 ("KOSPI")
	 * @param divideBy100  응답값을 100으로 나눠야 하면 true
	 * ============================================================ */
	private MarketIndexDTO fetchNaver(String name, String query, String chartSymbol, boolean divideBy100) {
		try {
			// [실행 흐름] 현재가와 히스토리를 동시에 요청 → 둘 다 끝날 때까지 기다림
			CompletableFuture<String> priceFuture = CompletableFuture
					.supplyAsync(() -> naverClient.get().uri("/api/realtime?query=" + query).retrieve()
							.bodyToMono(String.class).block(Duration.ofSeconds(5)));
			CompletableFuture<List<Double>> histFuture = CompletableFuture
					.supplyAsync(() -> fetchNaverHistory(chartSymbol, divideBy100));

			// [실행 흐름] JSON 파싱: result.areas[0].datas[0] 구조에서 값 추출
			Map<String, Object> res = mapper.readValue(priceFuture.join(), Map.class);
			List<Map<String, Object>> areas = (List<Map<String, Object>>) ((Map<String, Object>) res.get("result"))
					.get("areas");
			if (areas == null || areas.isEmpty())
				return null;

			List<Map<String, Object>> datas = (List<Map<String, Object>>) areas.get(0).get("datas");
			if (datas == null || datas.isEmpty())
				return null;

			Map<String, Object> d = datas.get(0);
			double nv = toDouble(d.get("nv")); // 현재가 (raw)
			double cv = toDouble(d.get("cv")); // 등락폭 (raw)
			double cr = toDouble(d.get("cr")); // 등락률 (%)
			if (divideBy100) {
				nv /= 100.0; // [실행 흐름] 네이버 원시값 보정 (예: 265032 → 2650.32)
				cv /= 100.0;
			}

			boolean up = cr >= 0;
			String sign = up ? "+" : ""; // 양수일 때만 "+" 접두사 추가
			return new MarketIndexDTO(name, String.format("%,.2f", nv), sign + String.format("%,.2f", cv),
					sign + String.format("%.2f", cr), up, histFuture.join());
		} catch (Exception e) {
			log.error("{} 조회 실패: {}", name, e.getMessage());
			return null; // [실행 흐름] 실패하면 null → getMarketIndex()에서 필터링됨
		}
	}

	/** ============================================================
	 * 네이버 차트 API로 30일 종가 히스토리를 조회한다.
	 *
	 * [실행 흐름]
	 * 1. API 응답은 XML 형식: <item data="날짜|시가|고가|저가|종가|거래량" />
	 * 2. 정규식 data="..." 로 각 item의 data 속성을 추출
	 * 3. "|" 로 분리하면 [날짜, 시가, 고가, 저가, 종가, 거래량] → index 4가 종가
	 * 4. divideBy100 이면 네이버 원시값 보정
	 * ============================================================ */
	private List<Double> fetchNaverHistory(String symbol, boolean divideBy100) {
		try {
			String xml = naverChartClient.get()
					.uri("/sise.nhn?symbol=" + symbol + "&timeframe=day&count=30&requestType=0").retrieve()
					.bodyToMono(String.class).block(Duration.ofSeconds(5));

			List<Double> prices = new ArrayList<>();
			// [실행 흐름] 정규식으로 XML에서 data="..." 속성 값만 추출
			Matcher m = Pattern.compile("data=\"([^\"]+)\"").matcher(xml);
			while (m.find()) {
				String[] parts = m.group(1).split("\\|");
				if (parts.length >= 5) {
					double close = Double.parseDouble(parts[4]); // index 4 = 종가
					prices.add(divideBy100 ? close / 100.0 : close);
				}
			}
			return prices;
		} catch (Exception e) {
			return new ArrayList<>(); // 실패 시 빈 리스트 → 미니차트 없이 표시
		}
	}

	/** ============================================================
	 * Stooq API로 나스닥 100(^NDX) 현재가를 조회하고,
	 * Yahoo Finance API로 30일 히스토리를 동시에 가져온다.
	 *
	 * [실행 흐름]
	 * - Stooq 응답: symbols[0].close, open 으로 종가·시가 추출
	 * - 등락폭 = close - open, 등락률 = 등락폭 / open × 100
	 * - 히스토리(%5ENDX = URL 인코딩된 ^NDX)는 Yahoo Finance에서 조회
	 * ============================================================ */
	private MarketIndexDTO fetchNasdaq() {
		try {
			CompletableFuture<String> priceFuture = CompletableFuture
					.supplyAsync(() -> stooqClient.get().uri("/q/l/?s=^NDX&f=sd2t2ohlcv&h&e=json").retrieve()
							.bodyToMono(String.class).block(Duration.ofSeconds(5)));
			CompletableFuture<List<Double>> histFuture = CompletableFuture
					.supplyAsync(() -> fetchYahooHistory("%5ENDX")); // %5E = ^ (URL 인코딩)

			Map<String, Object> res = mapper.readValue(priceFuture.join(), Map.class);
			List<Map<String, Object>> symbols = (List<Map<String, Object>>) res.get("symbols");
			if (symbols == null || symbols.isEmpty())
				return null;

			Map<String, Object> d = symbols.get(0);
			double close = toDouble(d.get("close"));
			double open = toDouble(d.get("open"));
			double cv = close - open;                              // 등락폭
			double cr = open > 0 ? cv / open * 100 : 0;           // 등락률 (%)

			boolean up = cr >= 0;
			String sign = up ? "+" : "";
			return new MarketIndexDTO("나스닥", String.format("%,.2f", close), sign + String.format("%,.2f", cv),
					sign + String.format("%.2f", cr), up, histFuture.join());
		} catch (Exception e) {
			log.error("나스닥 조회 실패: {}", e.getMessage());
			return null;
		}
	}

	/** ============================================================
	 * Yahoo Finance API로 S&P 500(^GSPC) 30일 히스토리를 조회한다.
	 *
	 * [실행 흐름]
	 * - 나스닥과 달리 별도 현재가 API를 쓰지 않고, 히스토리 마지막 값을 현재가로 사용
	 * - prices.last = 오늘 종가, prices.last-1 = 어제 종가 → 등락폭/등락률 계산
	 * ============================================================ */
	private MarketIndexDTO fetchSP500() {
		try {
			List<Double> prices = fetchYahooHistory("%5EGSPC"); // %5E = ^ (URL 인코딩)
			if (prices.size() < 2)
				return null;

			double close = prices.get(prices.size() - 1); // 가장 최근 종가
			double prev  = prices.get(prices.size() - 2); // 전일 종가
			double cv = close - prev;
			double cr = prev > 0 ? cv / prev * 100 : 0;

			boolean up = cv >= 0;
			String sign = up ? "+" : "";
			return new MarketIndexDTO("S&P 500", String.format("%,.2f", close), sign + String.format("%,.2f", cv),
					sign + String.format("%.2f", cr), up, prices);
		} catch (Exception e) {
			log.error("S&P500 조회 실패: {}", e.getMessage());
			return null;
		}
	}

	/** ============================================================
	 * Bitget API로 비트코인(BTCUSDT) 현재가와 30일 캔들 히스토리를 조회한다.
	 *
	 * [실행 흐름]
	 * - tickers API: data[0].lastPr = 현재가, data[0].open = 당일 시작가
	 * - 등락폭/등락률은 당일 시작가 대비로 계산
	 * - %,.0f : 천 단위 구분자 + 소수점 없이 표시 (예: 95,320,000)
	 * ============================================================ */
	private MarketIndexDTO fetchBitcoin() {
		try {
			CompletableFuture<String> tickerFuture = CompletableFuture
					.supplyAsync(() -> bitgetClient.get().uri("/api/v2/spot/market/tickers?symbol=BTCUSDT").retrieve()
							.bodyToMono(String.class).block(Duration.ofSeconds(5)));
			CompletableFuture<List<Double>> histFuture = CompletableFuture
					.supplyAsync(() -> fetchBitgetCandles("BTCUSDT")); // 30일 캔들 동시 조회

			Map<String, Object> res = mapper.readValue(tickerFuture.join(), Map.class);
			List<Map<String, Object>> data = (List<Map<String, Object>>) res.get("data");
			if (data == null || data.isEmpty())
				return null;

			Map<String, Object> t = data.get(0);
			double last = toDouble(t.get("lastPr")); // 현재가
			double open = toDouble(t.get("open"));   // 당일 시작가
			double cv = last - open;
			double cr = open > 0 ? cv / open * 100 : 0;

			boolean up = cv >= 0;
			String sign = up ? "+" : "";
			return new MarketIndexDTO("비트코인", String.format("%,.0f", last), sign + String.format("%,.0f", cv),
					sign + String.format("%.2f", cr), up, histFuture.join());
		} catch (Exception e) {
			log.error("비트코인 조회 실패: {}", e.getMessage());
			return null;
		}
	}

	/** ============================================================
	 * Bitget API로 일봉 캔들 30개를 조회해 종가 리스트로 반환한다.
	 *
	 * [실행 흐름]
	 * - Bitget 캔들 응답: data = [[타임스탬프, 시가, 고가, 저가, 종가, 거래량, ...], ...]
	 * - 응답은 최신순(내림차순) → 오래된 것부터 오름차순으로 뒤집어서 반환
	 * - index 4 = 종가
	 * - 미니차트(sparkline)에서 왼쪽(과거)→오른쪽(최근) 순서로 그리기 위해 역순 처리
	 * ============================================================ */
	private List<Double> fetchBitgetCandles(String symbol) {
		try {
			String json = bitgetClient.get()
					.uri("/api/v2/spot/market/candles?symbol=" + symbol + "&granularity=1Dutc&limit=30").retrieve()
					.bodyToMono(String.class).block(Duration.ofSeconds(5));

			Map<String, Object> res = mapper.readValue(json, Map.class);
			List<List<Object>> data = (List<List<Object>>) res.get("data");
			if (data == null)
				return new ArrayList<>();

			// [실행 흐름] Bitget은 최신 데이터가 앞 → 역순(i=size-1→0)으로 순회해 과거→최근 순서로 변환
			List<Double> prices = new ArrayList<>();
			for (int i = data.size() - 1; i >= 0; i--) {
				prices.add(toDouble(data.get(i).get(4))); // index 4 = 종가
			}
			return prices;
		} catch (Exception e) {
			return new ArrayList<>();
		}
	}

	/** ============================================================
	 * Coinlore API로 BTC 도미넌스를 조회한다.
	 *
	 * [실행 흐름]
	 * 1. domFuture: Coinlore /api/global/ → btc_d(도미넌스%), mcap_change(시총 변화율)
	 * 2. histFuture: Bitget BTCUSDT 캔들 → 미니차트용 히스토리 (BTC 가격 선 사용)
	 * 3. domFuture 타임아웃(1초) 초과 시 → getFallbackDominance()로 하드코딩 기본값 반환
	 *    [이유] 도미넌스 조회 실패가 전체 대시보드 로딩을 막으면 안 되기 때문
	 * 4. 외부 catch → 파싱 완전 실패 시에도 기본값 DTO 반환 (null 반환 금지)
	 * ============================================================ */
	private MarketIndexDTO fetchBtcDominance() {
		try {
			// [실행 흐름] 타임아웃 1초로 설정 → Coinlore가 느리면 대시보드 전체를 기다리게 하지 않음
			CompletableFuture<String> domFuture = CompletableFuture.supplyAsync(() -> coinloreClient.get()
					.uri("/api/global/").retrieve().bodyToMono(String.class).block(Duration.ofSeconds(1)));

			CompletableFuture<List<Double>> histFuture = CompletableFuture
					.supplyAsync(() -> fetchBitgetCandles("BTCUSDT"));

			// [실행 흐름] join() 시 타임아웃 예외를 별도 catch로 포획 → 폴백 반환
			String jsonResult;
			try {
				jsonResult = domFuture.join();
			} catch (Exception te) {
				log.warn("⚠️ Coinlore API 응답 지연(타임아웃) 발생 - 기본값으로 대체합니다.");
				return getFallbackDominance(histFuture.join());
			}

			List<Map<String, Object>> arr = mapper.readValue(jsonResult, List.class);
			if (arr == null || arr.isEmpty())
				return getFallbackDominance(histFuture.join());

			Map<String, Object> data = arr.get(0);
			double dom    = toDouble(data.get("btc_d"));       // BTC 도미넌스 (%)
			double change = toDouble(data.get("mcap_change")); // 시가총액 변화율
			boolean up = change >= 0;
			String sign = up ? "+" : "";

			return new MarketIndexDTO("BTC 도미넌스", String.format("%.2f%%", dom), sign + String.format("%.2f%%", change),
					sign + String.format("%.2f", change), up, histFuture.join());

		} catch (Exception e) {
			log.error("⚠️ BTC 도미넌스 최종 파싱 실패: {}", e.getMessage());
			// [실행 흐름] 완전히 실패해도 null 대신 하드코딩 기본값 반환 → 대시보드 안정성 보장
			return new MarketIndexDTO("BTC 도미넌스", "55.20%", "+0.15%", "+0.15%", true, new ArrayList<>());
		}
	}

	/** ============================================================
	 * BTC 도미넌스 조회 실패 시 반환할 폴백(기본값) DTO를 생성한다.
	 * @param history 히스토리 리스트 (null이면 빈 리스트로 대체)
	 * ============================================================ */
	private MarketIndexDTO getFallbackDominance(List<Double> history) {
		return new MarketIndexDTO("BTC 도미넌스", "55.00%", "+0.00%", "+0.00%", true,
				history != null ? history : new ArrayList<>());
	}

	/** ============================================================
	 * Yahoo Finance v8 API로 1개월 일봉 종가 히스토리를 조회한다.
	 *
	 * [실행 흐름]
	 * 1. URI.create() 사용 → %5E 등 이미 인코딩된 문자를 재인코딩하지 않기 위해
	 * 2. JSON 구조: chart.result[0].indicators.quote[0].close = 종가 배열
	 * 3. null 필터링: 휴장일 등으로 close 값이 null인 항목을 제거
	 *
	 * @param encodedSymbol URL 인코딩된 심볼 (예: %5ENDX, %5EGSPC)
	 * ============================================================ */
	private List<Double> fetchYahooHistory(String encodedSymbol) {
		try {
			// [실행 흐름] URI.create()로 직접 생성 → WebClient가 심볼을 이중 인코딩하지 않도록 방지
			String json = yahooClient.get()
					.uri(URI.create("https://query1.finance.yahoo.com/v8/finance/chart/" + encodedSymbol
							+ "?interval=1d&range=1mo"))
					.retrieve().bodyToMono(String.class).block(Duration.ofSeconds(5));

			Map<String, Object> res = mapper.readValue(json, Map.class);
			Map<String, Object> chart = (Map<String, Object>) res.get("chart");
			List<Map<String, Object>> results = (List<Map<String, Object>>) chart.get("result");
			if (results == null || results.isEmpty())
				return new ArrayList<>();

			// [실행 흐름] 중첩 Map 탐색: result[0] → indicators → quote[0] → close 배열
			Map<String, Object> indicators = (Map<String, Object>) results.get(0).get("indicators");
			List<Map<String, Object>> quotes  = (List<Map<String, Object>>) indicators.get("quote");
			List<Double> closes = (List<Double>) quotes.get(0).get("close");
			return closes.stream().filter(p -> p != null).collect(Collectors.toList()); // null(휴장일) 제거
		} catch (Exception e) {
			return new ArrayList<>();
		}
	}

	/** ============================================================
	 * Frankfurter API로 달러(USD→KRW) 환율을 조회한다.
	 *
	 * [실행 흐름]
	 * 1. todayFuture: /latest → 오늘 환율
	 * 2. histFuture: /2025-04-19..2025-05-24?from=USD&to=KRW → 35일 히스토리
	 * 3. TreeMap으로 날짜 키를 오름차순 정렬 → 미니차트용 리스트로 변환
	 * 4. 등락폭 = 오늘 환율 - 어제 환율 (히스토리 마지막-2 인덱스)
	 * ============================================================ */
	private MarketIndexDTO fetchExchangeRate() {
		try {
			// [실행 흐름] 35일 히스토리 URI: /YYYY-MM-DD..YYYY-MM-DD?from=USD&to=KRW
			final String histUri = "/" + LocalDate.now().minusDays(35) + ".." + LocalDate.now() + "?from=USD&to=KRW";

			CompletableFuture<String> todayFuture = CompletableFuture.supplyAsync(() -> fxClient.get()
					.uri("/latest?from=USD&to=KRW").retrieve().bodyToMono(String.class).block(Duration.ofSeconds(5)));
			CompletableFuture<String> histFuture = CompletableFuture.supplyAsync(
					() -> fxClient.get().uri(histUri).retrieve().bodyToMono(String.class).block(Duration.ofSeconds(5)));

			Map<String, Object> todayRes = mapper.readValue(todayFuture.join(), Map.class);
			Map<String, Object> todayRates = (Map<String, Object>) todayRes.get("rates");
			if (todayRates == null)
				return null;
			double today = toDouble(todayRates.get("KRW")); // 현재 환율

			// [실행 흐름] 히스토리 파싱: { "2025-04-19": { "KRW": 1380.5 }, ... }
			List<Double> prices = new ArrayList<>();
			Map<String, Object> histRes   = mapper.readValue(histFuture.join(), Map.class);
			Map<String, Object> histRates = (Map<String, Object>) histRes.get("rates");
			if (histRates != null) {
				// TreeMap → 날짜 문자열을 자동으로 오름차순 정렬 (오래된 날짜부터 리스트에 추가)
				new TreeMap<>(histRates).forEach((date, rateObj) -> {
					Map<String, Object> dayRate = (Map<String, Object>) rateObj;
					prices.add(toDouble(dayRate.get("KRW")));
				});
			}

			// [실행 흐름] 히스토리 마지막-2 항목을 전일 기준으로 사용해 등락폭 계산
			double prev = prices.size() >= 2 ? prices.get(prices.size() - 2) : today;
			double cv = today - prev;
			double cr = prev > 0 ? cv / prev * 100 : 0;
			boolean up = cv >= 0;
			String sign = up ? "+" : "";
			return new MarketIndexDTO("달러 환율", String.format("%,.2f", today), sign + String.format("%,.2f", cv),
					sign + String.format("%.2f", cr), up, prices);
		} catch (Exception e) {
			log.error("환율 조회 실패: {}", e.getMessage());
			return null;
		}
	}

	/** ============================================================
	 * Object 타입 값을 double로 안전하게 변환하는 헬퍼.
	 *
	 * Jackson이 JSON 숫자를 Integer, Long, Double 등 다양한 타입으로 파싱하므로
	 * toString() 후 Double.parseDouble()로 통일 변환한다.
	 * null이거나 변환 실패 시 0을 반환해 NullPointerException을 방지한다.
	 * ============================================================ */
	private double toDouble(Object val) {
		if (val == null)
			return 0;
		try {
			return Double.parseDouble(val.toString());
		} catch (Exception e) {
			return 0;
		}
	}
}
