package com.tj.app.market.coin;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.reactive.function.client.WebClient;

import com.tj.app.market.coin.order.CoinHoldingsDTO;
import com.tj.app.market.coin.order.CoinOrdersDTO;
import com.tj.app.market.coin.order.CoinService;
import com.tj.app.market.coin.order.CoinWalletDTO;
import com.tj.app.member.MemberDTO;

import jakarta.servlet.http.HttpSession;

import org.springframework.web.bind.annotation.PostMapping;
import java.util.List;

/** ============================================================
 * [클래스 읽기] 코인 관련 모든 요청을 처리하는 컨트롤러.
 *
 * [@Controller vs @RestController]
 *   @Controller 이므로 기본적으로 String 반환 = 뷰 이름(JSP 경로)으로 해석된다.
 *   JSON 응답이 필요한 메서드에는 개별적으로 @ResponseBody를 붙여야 한다.
 *   → @RestController는 클래스 전체에 @ResponseBody가 적용된 축약형이다.
 *
 * [@RequestMapping("/coin/*")]
 *   이 컨트롤러의 모든 엔드포인트는 /coin/ 아래에 매핑된다.
 *   * 와일드카드: /coin/chart, /coin/buy, /coin/api/tickers 등 모두 포함.
 *
 * [프록시 엔드포인트 존재 이유]
 *   브라우저의 Same-Origin Policy(동일 출처 정책)로 인해
 *   JavaScript에서 Bitget·CoinGecko·Bithumb API를 직접 호출하면 CORS 오류가 발생한다.
 *   Spring 서버를 중간 프록시로 두면 서버 → 외부 API → 브라우저 흐름으로 우회할 수 있다.
 *   캐싱(CoinMarketService)도 함께 적용돼 외부 API 호출 횟수를 줄인다.
 *
 * [주석 처리된 KIS 코드]
 *   초기에 KIS(한국투자증권) API로 코인 데이터를 가져오던 코드.
 *   현재는 Bitget API 기반으로 전환되어 사용하지 않는다.
 * ============================================================ */
@Controller
@RequestMapping("/coin/*")
public class CoinController {

	// @Value("${kis.appkey}")
	// private String appKey;
	//
	// @Value("${kis.appsecret}")
	// private String appSecret;
	//
	// @Autowired
	// private WebClient kisWebClient;
	// → KIS API 기반 구현 당시 사용하던 설정. 현재 미사용.

	/** CoinService: 매수·매도·보유·주문 내역 등 비즈니스 로직 처리 */
	@Autowired
	private CoinService coinService;

	/** CoinMarketService: Bitget·CoinGecko·Bithumb 외부 API 호출 + 캐싱 */
	@Autowired
	private CoinMarketService marketService;

	// ============================================================
	// [외부 API 프록시 엔드포인트] — @ResponseBody → JSON 반환
	// ============================================================

	/** ============================================================
	 * [메서드 읽기] Bitget 전체 Ticker 목록을 프록시로 반환한다.
	 *
	 * [흐름] GET /coin/api/tickers → CoinMarketService.getTickers() → Bitget API (캐시 10초)
	 * [이유] 브라우저 CORS 제한 우회. JS가 직접 Bitget을 호출하지 않아도 된다.
	 * ============================================================ */
	@GetMapping("api/tickers")
	@ResponseBody
	public Object getTickers() {
		return marketService.getTickers();
	}

	/** ============================================================
	 * [메서드 읽기] Bitget 캔들(OHLCV) 데이터를 프록시로 반환한다.
	 *
	 * [@RequestParam defaultValue] limit을 전달하지 않으면 "200"이 기본값.
	 * [@RequestParam required=false] endTime은 없어도 되는 선택적 파라미터.
	 *   값이 없으면 null로 넘어가고, CoinMarketService에서 null 체크 후 생략한다.
	 * ============================================================ */
	@GetMapping("api/candles")
	@ResponseBody
	public Object getCandles(@RequestParam("symbol") String symbol,
							 @RequestParam("granularity") String granularity,
							 @RequestParam(value = "limit", defaultValue = "200") String limit,
							 @RequestParam(value = "endTime", required = false) String endTime) {
		return marketService.getCandles(symbol, granularity, limit, endTime);
	}

	/** ============================================================
	 * [메서드 읽기] CoinGecko 코인 부가 정보(시가총액·등락률 등)를 프록시로 반환한다.
	 *
	 * [주의] CoinGecko 무료 플랜은 분당 요청 수가 제한된다(429 Too Many Requests).
	 *   CoinMarketService에서 10분 캐시를 적용해 과도한 호출을 방지한다.
	 * ============================================================ */
	@GetMapping("api/extra-stats")
	@ResponseBody
	public Object getExtraStats(@RequestParam("ticker") String ticker) {
		return marketService.getExtraStats(ticker);
	}

	/** ============================================================
	 * [메서드 읽기] CoinGecko 코인 로고 이미지 URL 맵을 프록시로 반환한다.
	 *
	 * [반환 형태] { "BTC": "https://...", "ETH": "https://..." }
	 * [캐시] 1시간. 로고는 자주 바뀌지 않으므로 긴 TTL 적용.
	 * ============================================================ */
	@GetMapping("api/logos")
	@ResponseBody
	public Map<String, String> getLogos() {
		return marketService.getLogos();
	}

	/** ============================================================
	 * [메서드 읽기] Bithumb 원화(KRW) 기준 Ticker를 프록시로 반환한다.
	 *
	 * [defaultValue] order="BTC", payment="KRW" → 파라미터 없으면 BTC/KRW 조회.
	 * [캐시] CoinMarketService 내부에서 2초 캐싱 처리.
	 * ============================================================ */
	@GetMapping("api/bithumb/ticker")
	@ResponseBody
	public Object getBithumbTicker(@RequestParam(value="order", defaultValue="BTC") String order,
								   @RequestParam(value="payment", defaultValue="KRW") String payment) {
		return marketService.getBithumbTicker(order, payment);
	}

	// ============================================================
	// [페이지 이동 엔드포인트] — String 또는 void 반환 → JSP 뷰 렌더링
	// ============================================================

	/** ============================================================
	 * [메서드 읽기] 코인 차트 페이지(coin/chart.jsp)로 이동한다.
	 *
	 * [실행 흐름]
	 * 1. symbol 파라미터를 받아 model에 담는다 (JSP에서 ${symbol}로 접근)
	 * 2. symbol이 null이면 기본값 "BTCUSDT" 설정
	 * 3. "coin/chart" 반환 → ViewResolver가 /WEB-INF/views/coin/chart.jsp를 렌더링
	 *
	 * [model.addAttribute()] → JSP에서 EL(${symbol})로 꺼내 쓸 수 있다.
	 * ============================================================ */
	@GetMapping("chart")
	public String chart(@RequestParam(value = "symbol", required = false) String symbol, Model model) throws Exception {
		model.addAttribute("symbol", symbol); // [실행 흐름] JSP에 symbol 전달

		// [실행 흐름] symbol 없이 접근하면 기본 코인(BTC/USDT)으로 설정
		if (symbol == null) {
			model.addAttribute("symbol", "BTCUSDT");
		}

		return "coin/chart"; // [실행 흐름] → coin/chart.jsp 렌더링
	}

	/** ============================================================
	 * [메서드 읽기] 코인 차트2 페이지로 이동 (개발·테스트용 예비 페이지).
	 *
	 * [void 반환] Spring은 반환값이 void이면 요청 경로에서 뷰 이름을 추론한다.
	 *   /coin/chart2 → coin/chart2.jsp 자동 매핑.
	 * ============================================================ */
	@GetMapping("chart2")
	public void chart2() throws Exception {
	}

	/** coin/list.jsp 렌더링 (코인 목록 페이지) — void이므로 경로에서 뷰 이름 추론 */
	@GetMapping("list")
	public void list() throws Exception {
	}

	/** ============================================================
	 * [메서드 읽기] 코인 커뮤니티 페이지(coin/community.jsp)로 이동한다.
	 *
	 * [defaultValue] symbol 파라미터가 없으면 "BTCUSDT" 기본값으로 model에 전달.
	 * ============================================================ */
	@GetMapping("community")
	public String community(@RequestParam(value = "symbol", required = false, defaultValue = "BTCUSDT") String symbol, Model model) throws Exception {
		model.addAttribute("symbol", symbol);
		return "coin/community"; // coin/community.jsp 렌더링
	}

	/** 샘플·테스트용 페이지 — symbol을 model에 담아 coin/sample.jsp 렌더링 */
	@GetMapping("sample")
	public String sample(@RequestParam(value = "symbol", required = false, defaultValue = "BTCUSDT") String symbol, Model model) throws Exception {
		model.addAttribute("symbol", symbol);
		return "coin/sample";
	}

	/** 개발·테스트용 예비 페이지 chart3 (void → coin/chart3.jsp 자동 매핑) */
	@GetMapping("chart3")
	public void chart3() throws Exception {
	}

	/** 개발·테스트용 예비 페이지 chart4 (void → coin/chart4.jsp 자동 매핑) */
	@GetMapping("chart4")
	public void chart4() throws Exception {
	}

	// ============================================================
	// [주석 처리된 KIS 기반 코드] — 현재 미사용
	// getAccessToken(): 토큰 캐싱 + KIS OAuth2 발급
	// kisdata: 분봉 캔들 조회 프록시
	// chart5: 토큰을 JSP에 전달하는 페이지
	// ============================================================

	// ============================================================
	// [매수·매도·조회 API] — @ResponseBody → JSON/String 반환
	// ============================================================

	/** ============================================================
	 * [메서드 읽기] 코인 매수 주문을 처리한다.
	 *
	 * [실행 흐름]
	 * 1. 세션에서 MemberDTO 꺼냄 → null이면 "fail_login_required" 문자열 반환
	 * 2. order에 서버 측 username 설정 (클라이언트가 보낸 username은 무시 — 보안)
	 * 3. CoinService.buy() 호출 → 잔고 차감·보유 추가·주문 기록
	 * 4. 성공 시 "success" 반환 → JS에서 문자열로 분기 처리
	 *
	 * [String 반환] @ResponseBody + String = 문자열 그대로 응답.
	 *   HTTP 200 상태에 "success" 또는 "fail_login_required" 텍스트가 담긴다.
	 *
	 * [보안 주의] order.setUsername()으로 세션의 실제 아이디를 덮어씌운다.
	 *   클라이언트에서 조작한 username을 그대로 쓰면 타인의 계좌로 주문할 수 있다.
	 * ============================================================ */
	@PostMapping("buy")
    @ResponseBody
    public String buy(CoinOrdersDTO order, HttpSession session) throws Exception {
		// [실행 흐름] 세션에서 로그인 정보 확인
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return "fail_login_required"; // [실행 흐름] 비로그인 → 즉시 반환

        order.setUsername(member.getUsername()); // [보안] 서버 측 username으로 덮어쓰기
        coinService.buy(order);
        return "success";
    }

	/** ============================================================
	 * [메서드 읽기] 코인 매도 주문을 처리한다.
	 *
	 * [실행 흐름] buy()와 동일한 세션 체크 → username 설정 → CoinService.sell() 호출.
	 * sell()에서 보유 수량 부족 시 Exception을 던진다.
	 * (Controller에서 try-catch 없음 → Spring이 500으로 처리)
	 * ============================================================ */
	@PostMapping("sell")
    @ResponseBody
    public String sell(CoinOrdersDTO order, HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return "fail_login_required";

        order.setUsername(member.getUsername());
        coinService.sell(order);
        return "success";
    }

	/** ============================================================
	 * [메서드 읽기] 코인 지갑(USDT 잔고)을 조회해 반환한다.
	 *
	 * [비로그인 처리] null 대신 usdtBalance=0.0인 빈 DTO를 반환한다.
	 *   JS에서 null 체크 없이 바로 wallet.usdtBalance를 사용할 수 있다 (NPE 방지).
	 *
	 * [wallet null 처리] 로그인됐지만 지갑이 없는 경우(비정상)도 빈 DTO로 방어.
	 * ============================================================ */
    @GetMapping("wallet")
    @ResponseBody
    public CoinWalletDTO getWallet(HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) {
            // [실행 흐름] 비로그인 → 잔고 0인 빈 DTO 반환 (null 반환 시 JS 오류 방지)
            CoinWalletDTO emptyWallet = new CoinWalletDTO();
            emptyWallet.setUsdtBalance(0.0);
            return emptyWallet;
        }
        CoinWalletDTO wallet = coinService.getWallet(member.getUsername());
        if (wallet == null) {
            // [실행 흐름] 지갑 미생성 비정상 상태 → 빈 DTO로 방어
            wallet = new CoinWalletDTO();
            wallet.setUsdtBalance(0.0);
        }
        return wallet;
    }

	/** ============================================================
	 * [메서드 읽기] 현재 로그인한 사용자의 보유 코인 목록을 반환한다.
	 *
	 * [List.of()] Java 9+. 수정 불가능한 빈 리스트. 비로그인 시 빈 배열([])을 반환한다.
	 * ============================================================ */
    @GetMapping("holdings")
    @ResponseBody
    public List<CoinHoldingsDTO> getHoldings(HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return List.of(); // [실행 흐름] 비로그인 → 빈 리스트
        return coinService.getHoldingList(member.getUsername());
    }

	/** ============================================================
	 * [메서드 읽기] 체결 완료된 코인 주문 내역 목록을 반환한다.
	 *
	 * 코인은 시장가 즉시 체결이므로 모든 주문이 status="COMPLETED"다.
	 * ============================================================ */
    @GetMapping("orders")
    @ResponseBody
    public List<CoinOrdersDTO> getOrders(HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return List.of();
        return coinService.getOrderList(member.getUsername());
    }

	/** ============================================================
	 * [메서드 읽기] 미체결(PENDING) 코인 주문 목록을 반환한다.
	 *
	 * [현재 상태] 코인은 시장가 즉시 체결이므로 PENDING 주문이 생성되지 않는다.
	 *   향후 지정가 기능 구현을 대비한 예비 엔드포인트다.
	 * ============================================================ */
    @GetMapping("pending")
    @ResponseBody
    public List<CoinOrdersDTO> getPendingOrders(HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return List.of();
        return coinService.getPendingOrders(member.getUsername());
    }

	/** ============================================================
	 * [메서드 읽기] 지정가 코인 주문을 등록한다 (예비 기능, 현재 UI에서 미사용).
	 *
	 * CoinService.limitOrder()에서 잔고/수량 확인 후 PENDING 상태로 저장한다.
	 * 실제 체결은 executePendingOrder()에서 처리한다.
	 * ============================================================ */
    @PostMapping("limitOrder")
    @ResponseBody
    public String limitOrder(CoinOrdersDTO order, HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return "fail_login_required";

        order.setUsername(member.getUsername());
        coinService.limitOrder(order);
        return "success";
    }

	/** ============================================================
	 * [메서드 읽기] 미체결 코인 주문을 취소한다 (예비 기능, 현재 미사용).
	 *
	 * CoinService.cancelOrder()에서 orderNo로 주문을 찾아 CANCELLED 상태로 변경.
	 * ============================================================ */
    @PostMapping("cancelOrder")
    @ResponseBody
    public String cancelOrder(CoinOrdersDTO order, HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return "fail_login_required";

        order.setUsername(member.getUsername());
        coinService.cancelOrder(order);
        return "success";
    }

	/** ============================================================
	 * [메서드 읽기] 지정가 조건이 충족된 미체결 주문을 체결 처리한다 (예비 기능, 현재 미사용).
	 *
	 * 향후 WebSocket에서 실시간 가격을 모니터링하다가 지정가 조건 충족 시 이 엔드포인트를
	 * 호출하는 방식으로 지정가 자동 체결 기능을 구현할 수 있다.
	 * ============================================================ */
    @PostMapping("executePending")
    @ResponseBody
    public String executePendingOrder(CoinOrdersDTO order, HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return "fail_login_required";

        order.setUsername(member.getUsername());
        coinService.executePendingOrder(order);
        return "success";
    }

}
