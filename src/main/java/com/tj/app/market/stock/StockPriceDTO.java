package com.tj.app.market.stock;

import lombok.Data;

/** ============================================================
 * [클래스 읽기] KIS API의 주식 현재가(단건) 조회 응답을 매핑하는 DTO.
 *
 * KIS API JSON 구조:
 *   { "rt_cd": "0", "msg1": "정상처리", "output": { "stck_prpr": "75000", ... } }
 *
 * StockListDTO와 달리 output이 배열(output2)이 아닌 단일 객체(output)이다.
 * 종목 상세 페이지나 WebSocket 현재가 조회에서 사용한다.
 * ============================================================ */
@Data
public class StockPriceDTO {
    private String rt_cd; // 응답 코드 ("0" = 정상)
    private String msg1;  // 응답 메시지
    private Output output;

    /** ============================================================
     * [중첩 클래스] 현재가 단건 응답 데이터.
     * KIS API 응답 필드명을 그대로 사용한다.
     * ============================================================ */
    @Data
    public static class Output {
        private String stck_prpr; // 주식 현재가 (예: "75000")
        private String prdy_vrss; // 전일 대비 등락폭 (예: "+500")
        private String prdy_ctrt; // 전일 대비율 (%) (예: "+0.67")
    }
}
