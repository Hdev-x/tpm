package com.tj.app.market.stock;

import java.util.List;

import lombok.Data;

@Data
public class StockListDTO {
	
	    private String rt_cd;
	    private String msg1;
	    private List<StockListOutput> output2; // 배열로 데이터가 들어옴

	    @Data
	    public static class StockListOutput {
	        private String mkstat_prpr;    // 현재가
	        private String prdy_vrss;       // 전일 대비
	        private String prdy_ctrt;       // 전일 대비율
	        private String hts_kor_isnm;    // 종목명 (여기에 이름이 포함되어 옵니다!)
	        private String mkstat_shrn_iscd; // 종목코드
	    }
	}
