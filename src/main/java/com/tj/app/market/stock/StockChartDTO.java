package com.tj.app.market.stock;

import java.util.List;
import lombok.Data;

/** ============================================================
 * [클래스 읽기] KIS API의 주식 차트(캔들) 조회 응답을 매핑하는 DTO.
 *
 * KIS API JSON 구조:
 *   { "rt_cd": "0", "output2": [ { "stck_bsop_date": "20250524", ... }, ... ] }
 *
 * output2 배열의 각 원소가 캔들 하나(일봉 또는 분봉)를 나타낸다.
 * 일봉/분봉 모두 같은 DTO를 재사용하며, 사용하지 않는 필드는 null로 채워진다.
 * ============================================================ */
@Data
public class StockChartDTO {
    private String rt_cd;              // 응답 코드 ("0" = 정상)
    private String msg1;               // 응답 메시지
    private List<ChartOutput> output2; // 캔들 데이터 배열 (최신순 또는 과거순)

    /** ============================================================
     * [중첩 클래스] 캔들 하나의 데이터 (일봉·분봉 공용).
     *
     * 캔들차트(OHLC)는 시가(O)·고가(H)·저가(L)·종가(C) 4가지 값으로 구성된다.
     * - 일봉 조회 시: stck_bsop_date(날짜) + 4가지 가격 + acml_vol(거래량) 사용
     * - 분봉 조회 시: stck_cntg_hour(체결시간) + stck_prpr(현재가) 추가 사용
     * ============================================================ */
    @Data
    public static class ChartOutput {
        private String stck_bsop_date; // 영업 일자 (일봉용, 예: "20250524")
        private String stck_clpr;      // 종가 Close (캔들 닫힘 가격)
        private String stck_oprc;      // 시가 Open  (캔들 시작 가격)
        private String stck_hgpr;      // 고가 High  (캔들 위꼬리 끝)
        private String stck_lwpr;      // 저가 Low   (캔들 아래꼬리 끝)
        private String acml_vol;       // 누적 거래량
        private String stck_cntg_hour; // 체결 시간 (분봉용, 예: "143000" = 14:30:00)
        private String stck_prpr;      // 현재가 (분봉 실시간 조회 시 사용)
    }
}