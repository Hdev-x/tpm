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

import com.tj.app.member.MemberDTO;

import jakarta.servlet.http.HttpSession;

import org.springframework.web.bind.annotation.PostMapping;
import java.util.List;

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

	@Autowired
	private CoinService coinService;

	@Autowired
	private CoinMarketService marketService;

	/** Bitget Tickers 프록시 */
	@GetMapping("api/tickers")
	@ResponseBody
	public Object getTickers() {
		return marketService.getTickers();
	}

	/** Bitget Candles 프록시 */
	@GetMapping("api/candles")
	@ResponseBody
	public Object getCandles(@RequestParam("symbol") String symbol,
							 @RequestParam("granularity") String granularity,
							 @RequestParam(value = "limit", defaultValue = "200") String limit,
							 @RequestParam(value = "endTime", required = false) String endTime) {
		return marketService.getCandles(symbol, granularity, limit, endTime);
	}

	/** CoinGecko 추가 정보 프록시 (429 방지용 캐시 적용됨) */
	@GetMapping("api/extra-stats")
	@ResponseBody
	public Object getExtraStats(@RequestParam("ticker") String ticker) {
		return marketService.getExtraStats(ticker);
	}

	/** Bithumb Ticker 프록시 */
	@GetMapping("api/bithumb/ticker")
	@ResponseBody
	public Object getBithumbTicker(@RequestParam(value="order", defaultValue="BTC") String order,
								   @RequestParam(value="payment", defaultValue="KRW") String payment) {
		return marketService.getBithumbTicker(order, payment);
	}

	@GetMapping("chart")
	public String chart(@RequestParam(value = "symbol", required = false) String symbol, Model model) throws Exception {
		// 1. 파라미터로 넘어온 symbol을 받아서
		// 2. JSP에서 쓸 수 있도록 model에 담아줍니다.
		model.addAttribute("symbol", symbol);

		// 3. 만약 파라미터가 없으면 기본값으로 "BTCUSDT" 같은 걸 줄 수도있습니다.
		if (symbol == null) {
			model.addAttribute("symbol", "BTCUSDT");
		}

		return "coin/chart"; // coin/chart.jsp를 보여줘!
	}

	@GetMapping("chart2")
	public void chart2() throws Exception {
	}

	@GetMapping("list")
	public void list() throws Exception {
	}

	@GetMapping("community")
	public String community(@RequestParam(value = "symbol", required = false, defaultValue = "BTCUSDT") String symbol, Model model) throws Exception {
		model.addAttribute("symbol", symbol);
		return "coin/community";
	}

	@GetMapping("sample")
	public String sample(@RequestParam(value = "symbol", required = false, defaultValue = "BTCUSDT") String symbol, Model model) throws Exception {
		model.addAttribute("symbol", symbol);
		return "coin/sample";
	}

	@GetMapping("chart3")
	public void chart3() throws Exception {
	}

	@GetMapping("chart4")
	public void chart4() throws Exception {
	}

	// // 토큰 발급
	// private String cachedToken = null;
	// private long tokenExpiry = 0;
	//
	// private String getAccessToken() {
	// // 토큰이 있고 아직 유효하면 재사용
	// if (cachedToken != null && System.currentTimeMillis() < tokenExpiry) {
	// return cachedToken;
	// }
	//
	// Map<String, String> body = Map.of("grant_type", "client_credentials",
	// "appsecret", appSecret, "appkey", appKey);
	//
	// Map response =
	// kisWebClient.post().uri("/oauth2/tokenP").header("content-type",
	// "application/json")
	// .bodyValue(body).retrieve().bodyToMono(Map.class).block();
	//
	// cachedToken = (String) response.get("access_token");
	// tokenExpiry = System.currentTimeMillis() + 23 * 60 * 60 * 1000; // 23시간
	// return cachedToken;
	// }

	// // chart5 페이지 (토큰 발급해서 JSP로 전달)
	// @GetMapping("chart5")
	// public String chart5(Model model) throws Exception {
	// String token = getAccessToken();
	// model.addAttribute("token", token);
	// model.addAttribute("appKey", appKey);
	// return "coin/chart5";
	// }
	//
	// // 프록시: 분봉 데이터
	// @GetMapping("kisdata")
	// @ResponseBody
	// public String kisData(@RequestParam("symbol") String symbol,
	// @RequestParam("interval") String interval)
	// throws Exception {
	// String token = getAccessToken();
	//
	// // 현재 시각 HHmmss 형식
	// String now = new java.text.SimpleDateFormat("HHmmss").format(new
	// java.util.Date());
	//
	// return kisWebClient.get()
	// .uri(uriBuilder ->
	// uriBuilder.path("/uapi/domestic-stock/v1/quotations/inquire-time-itemchartprice")
	// .queryParam("FID_ETC_CLS_CODE", "").queryParam("FID_COND_MRKT_DIV_CODE", "J")
	// .queryParam("FID_INPUT_ISCD", symbol).queryParam("FID_INPUT_HOUR_1", now)
	// .queryParam("FID_PW_DATA_INCU_YN", "Y").build())
	// .header("authorization", "Bearer " + token).header("appkey",
	// appKey).header("appsecret", appSecret)
	// .header("tr_id",
	// "FHKST03010200").retrieve().bodyToMono(String.class).block();
	// }

	/** 매수 주문 */
	@PostMapping("buy")
    @ResponseBody
    public String buy(CoinOrdersDTO order, HttpSession session) throws Exception {
        // 세션에서 "member" Key로 MemberDTO 객체를 꺼냅니다.
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return "fail_login_required";
        
        order.setUsername(member.getUsername()); // DTO에서 실제 유저 ID 추출
        coinService.buy(order);
        return "success";
    }

	/** 매도 주문 */
	@PostMapping("sell")
    @ResponseBody
    public String sell(CoinOrdersDTO order, HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return "fail_login_required";
        
        order.setUsername(member.getUsername());
        coinService.sell(order);
        return "success";
    }

	/** 지갑 잔고 조회 */
    @GetMapping("wallet")
    @ResponseBody
    public CoinWalletDTO getWallet(HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) {
            CoinWalletDTO emptyWallet = new CoinWalletDTO();
            emptyWallet.setUsdtBalance(0.0);
            return emptyWallet;
        }
        return coinService.getWallet(member.getUsername());
    }

    /** 보유 코인 목록 조회 */
    @GetMapping("holdings")
    @ResponseBody
    public List<CoinHoldingsDTO> getHoldings(HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return List.of();
        return coinService.getHoldingList(member.getUsername());
    }

    /** 주문 내역 조회 (체결 완료) */
    @GetMapping("orders")
    @ResponseBody
    public List<CoinOrdersDTO> getOrders(HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return List.of();
        return coinService.getOrderList(member.getUsername());
    }

    /** 미체결 주문 조회 */
    @GetMapping("pending")
    @ResponseBody
    public List<CoinOrdersDTO> getPendingOrders(HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return List.of();
        return coinService.getPendingOrders(member.getUsername());
    }

    /** 지정가 주문 등록 */
    @PostMapping("limitOrder")
    @ResponseBody
    public String limitOrder(CoinOrdersDTO order, HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return "fail_login_required";
        
        order.setUsername(member.getUsername());
        coinService.limitOrder(order);
        return "success";
    }

    /** 미체결 주문 취소 */
    @PostMapping("cancelOrder")
    @ResponseBody
    public String cancelOrder(CoinOrdersDTO order, HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return "fail_login_required";
        
        order.setUsername(member.getUsername());
        coinService.cancelOrder(order);
        return "success";
    }

    /** 지정가 체결 처리 */
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
