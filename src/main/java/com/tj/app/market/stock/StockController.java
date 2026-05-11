package com.tj.app.market.stock;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/stock")
public class StockController {

	@Autowired
	private WebClientService webClientService;

	@GetMapping("/chart")
	public Map<String, Object> getPastChart(@RequestParam(name = "symbol", defaultValue = "005930") String symbol,
			@RequestParam(name = "type", defaultValue = "day") String type,
			@RequestParam(name = "startDate", defaultValue = "20250511") String startDate) {

		String today = "20260511"; // 현재 날짜 (시스템 날짜를 쓰려면 LocalDate.now() 권장)
		StockChartDTO data;
		boolean isMinute = type.equals("min");

		if (isMinute) {
			data = webClientService.getMinuteChart(symbol);
		} else {
			data = webClientService.getDailyChart(symbol, startDate, today);
		}

		List<Map<String, Object>> candles = new ArrayList<>();

		// 데이터 파싱 로직
		if (data != null && data.getOutput2() != null) {
			List<StockChartDTO.ChartOutput> list = data.getOutput2();

			for (int i = list.size() - 1; i >= 0; i--) {
				try {
					StockChartDTO.ChartOutput out = list.get(i);
					if (out.getStck_bsop_date() == null)
						continue;

					Map<String, Object> candle = new HashMap<>();
					String rawDate = out.getStck_bsop_date();
					String timeLabel;

					if (isMinute && out.getStck_cntg_hour() != null) {
						String rawTime = out.getStck_cntg_hour(); // "153000"
						timeLabel = String.format("%s-%s-%s %s:%s", rawDate.substring(0, 4), rawDate.substring(4, 6),
								rawDate.substring(6, 8), rawTime.substring(0, 2), rawTime.substring(2, 4));
					} else {
						timeLabel = String.format("%s-%s-%s", rawDate.substring(0, 4), rawDate.substring(4, 6),
								rawDate.substring(6, 8));
					}

					candle.put("time", timeLabel);
					candle.put("open", Double.parseDouble(out.getStck_oprc().isEmpty() ? "0" : out.getStck_oprc()));
					candle.put("high", Double.parseDouble(out.getStck_hgpr().isEmpty() ? "0" : out.getStck_hgpr()));
					candle.put("low", Double.parseDouble(out.getStck_lwpr().isEmpty() ? "0" : out.getStck_lwpr()));
					candle.put("close", Double.parseDouble(out.getStck_clpr().isEmpty() ? "0" : out.getStck_clpr()));

					candles.add(candle);
				} catch (Exception e) {
					System.err.println("Data parsing error: " + e.getMessage());
				}
			}
		}

		// ⭐ 반환 객체 생성 위치를 밖으로 이동하여 항상 응답하도록 보장
		Map<String, Object> result = new HashMap<>();
		result.put("candles", candles);
		result.put("isMinute", isMinute);
		return result;
	}
}