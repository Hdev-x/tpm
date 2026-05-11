package com.tj.app.market.stock;

import java.util.List;
import lombok.Data;

@Data
public class StockChartDTO {
    private String rt_cd;
    private List<ChartOutput> output2;

    @Data
    public static class ChartOutput {
        // 일봉 조회용 날짜
        private String stck_bsop_date; 
        
        // 캔들을 만드는 4가지 가격 데이터
        private String stck_clpr;      // 종가 (Close)
        private String stck_oprc;      // 시가 (Open)
        private String stck_hgpr;      // 고가 (High)
        private String stck_lwpr;      // 저가 (Low)
        
        // 기존 분봉용 (필요시 유지)
        private String stck_cntg_hour;
        private String stck_prpr;
    }
}