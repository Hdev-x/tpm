package com.tj.app.market.coin;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.reactive.function.client.WebClient;
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

	@GetMapping("chart")
	public void chart() throws Exception {
	}

	@GetMapping("chart2")
	public void chart2() throws Exception {
	}

	@GetMapping("list")
	public void list() throws Exception {
	}

	@GetMapping("chart3")
	public void chart3() throws Exception {
	}

	@GetMapping("chart3-toss")
	public void chart3_toss() throws Exception {
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
	public String buy(CoinOrdersDTO order) throws Exception {
		coinService.buy(order);
		return "success";
	}

	/** 매도 주문 */
	@PostMapping("sell")
	@ResponseBody
	public String sell(CoinOrdersDTO order) throws Exception {
		coinService.sell(order);
		return "success";
	}

	/** 지갑 잔고 조회 */
	@GetMapping("wallet")
	@ResponseBody
	public CoinWalletDTO getWallet(@RequestParam("username") String username) throws Exception {
		return coinService.getWallet(username);
	}

	/** 보유 코인 목록 조회 */
	@GetMapping("holdings")
	@ResponseBody
	public List<CoinHoldingsDTO> getHoldings(@RequestParam("username") String username) throws Exception {
		return coinService.getHoldingList(username);
	}

	/** 주문 내역 조회 */
	@GetMapping("orders")
	@ResponseBody
	public List<CoinOrdersDTO> getOrders(@RequestParam("username") String username) throws Exception {
		return coinService.getOrderList(username);
	}

}