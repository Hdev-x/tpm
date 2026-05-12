package com.tj.app.market.stock;

import lombok.Data;

@Data
public class StockPriceDTO {
	private String rt_cd; // 0: 성공, 이외: 실패
	private String msg1; // 응답 메시지
	private Output output;

	@Data
	public static class Output {
		private String stck_prpr; // 주식 현재가
		private String prdy_vrss; // 전일 대비
		private String prdy_ctrt; // 전일 대비율
	}
}
