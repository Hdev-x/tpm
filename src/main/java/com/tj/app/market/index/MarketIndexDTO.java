package com.tj.app.market.index;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/** ============================================================
 * [클래스 읽기] 시장 지수 하나의 데이터를 담는 DTO.
 *
 * 코스피, 나스닥, S&P500, 다우존스 등 각 지수 정보를 표현한다.
 * 외부 API(예: 한국투자증권)에서 받아온 값을 이 객체로 변환해
 * JSP 또는 JSON 응답으로 내려보낸다.
 *
 * [@Data] Lombok 합성 어노테이션:
 *   @Getter + @Setter + @ToString + @EqualsAndHashCode + @RequiredArgsConstructor
 *   를 한 번에 적용한다.
 *
 * [@NoArgsConstructor] 파라미터 없는 기본 생성자 자동 생성.
 *   JSON 역직렬화(Jackson)나 MyBatis ResultSet 매핑 시 필요하다.
 *
 * [@AllArgsConstructor] 모든 필드를 받는 생성자 자동 생성.
 *   Service에서 new MarketIndexDTO(name, price, ...) 형태로 직접 생성할 때 사용한다.
 * ============================================================ */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class MarketIndexDTO {
    private String name;        // 지수 이름 (예: "KOSPI", "NASDAQ")
    private String price;       // 현재가 (문자열로 표시, 예: "2,650.32")
    private String change;      // 전일 대비 등락폭 (예: "+12.45", "-8.30")
    private String changeRate;  // 등락률 (예: "+0.47%")
    private boolean up;         // true = 상승, false = 하락 → JSP에서 색상(빨강/파랑) 분기에 사용
    private List<Double> prices;// 미니차트용 최근 가격 리스트 (예: [2640.1, 2645.3, 2650.2, ...])
}
