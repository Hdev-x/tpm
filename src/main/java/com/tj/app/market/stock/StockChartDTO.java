package com.tj.app.market.stock;

import java.util.List;
import lombok.Data;

@Data
public class StockChartDTO {
    private String rt_cd;	// 응답 코드 (0: 성공, 0 이외: 실패)
    private String msg1;    // 응답 메시지 (에러 사유 등)
    private List<ChartOutput> output2;	// 실제 캔들 데이터 리스트

    @Data
    public static class ChartOutput {
        // 일봉 조회용 날짜
        private String stck_bsop_date; // 영업 일자
        
        // 캔들을 만드는 4가지 가격 데이터
        private String stck_clpr;      // 종가 (Close)
        private String stck_oprc;      // 시가 (Open)
        private String stck_hgpr;      // 고가 (High)
        private String stck_lwpr;      // 저가 (Low)
        
        private String acml_vol;	// 누적 거래량
        
        // 분봉 조회 시 필요한 필드
        private String stck_cntg_hour; // 체결 시간 (분봉용)
        private String stck_prpr;
    }
}