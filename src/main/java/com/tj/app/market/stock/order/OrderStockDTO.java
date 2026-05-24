package com.tj.app.market.stock.order;

import java.time.LocalDate;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

/** ============================================================
 * [클래스 읽기] 주식 주문 한 건의 데이터를 담는 DTO.
 *
 * ORDER 테이블과 1:1 대응한다.
 * 매수/매도 주문 생성, 조회, 상태 변경 시 이 객체를 사용한다.
 * ============================================================ */
@Getter
@Setter
@ToString
public class OrderStockDTO {

    private Long orderId;      // 주문 고유 번호 (PK)
    private String orderType;  // 주문 유형: "BUY"(매수), "SELL"(매도)
    private Long orderPrice;   // 주문 단가 (원화)
    private Long orderCount;   // 주문 수량 (주)
    private LocalDate orderDate; // 주문 일자
    private Long stockNo;      // 보유 주식 FK (STOCK_HOLDINGS 테이블 참조)
    private String stockCode;  // 종목 코드 (예: "005930")
    private String username;   // 주문한 사용자 아이디
    private String status;     // 주문 상태: "PENDING"(미체결), "DONE"(체결완료), "CANCELED"(취소)
    private Long targetPrice;  // 지정가 주문 시 목표 체결 가격 (시장가이면 null)
}
