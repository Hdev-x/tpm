package com.tj.app.market.stock;

import java.util.List;

import lombok.Data;

/** ============================================================
 * [클래스 읽기] 한국투자증권(KIS) API의 주식 시장 종목 리스트 응답을 매핑하는 DTO.
 *
 * KIS API가 반환하는 JSON 구조:
 *   { "rt_cd": "0", "msg1": "정상처리", "output2": [ {...}, {...}, ... ] }
 *
 * Jackson이 JSON 필드명을 그대로 Java 필드에 매핑하므로
 * 필드명을 KIS API 응답 키와 동일하게 사용한다(스네이크 케이스).
 *
 * [정적 중첩 클래스 StockListOutput]
 *   output2 배열의 각 원소를 담는다.
 *   static 으로 선언해 바깥 클래스(StockListDTO) 인스턴스 없이도 생성 가능하다.
 * ============================================================ */
@Data
public class StockListDTO {

    private String rt_cd;               // 응답 코드 ("0" = 정상, 그 외 오류)
    private String msg1;                // 응답 메시지 (예: "정상처리")
    private List<StockListOutput> output2; // 종목 데이터 배열

    /** ============================================================
     * [중첩 클래스] 종목 리스트 배열(output2)의 개별 원소.
     * KIS API 응답 필드명을 그대로 사용한다.
     * ============================================================ */
    @Data
    public static class StockListOutput {
        private String mkstat_prpr;      // 현재가
        private String prdy_vrss;        // 전일 대비 등락폭 (양수=상승, 음수=하락)
        private String prdy_ctrt;        // 전일 대비율 (%) (예: "+1.25")
        private String hts_kor_isnm;     // 종목명 (한글, 예: "삼성전자")
        private String mkstat_shrn_iscd; // 단축 종목코드 (예: "005930")
    }
}
