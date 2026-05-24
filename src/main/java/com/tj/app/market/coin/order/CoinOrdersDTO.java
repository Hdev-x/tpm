package com.tj.app.market.coin.order;

import lombok.Data;

/** ============================================================
 * [클래스 읽기] 코인 주문 한 건을 담는 DTO.
 *
 * COIN_ORDERS 테이블과 1:1 대응한다.
 * 주식과 달리 코인은 시장가 즉시 체결만 지원하므로
 * status는 항상 "DONE"으로 INSERT된다(PENDING 없음).
 * avgPrice: 매도 시 수익/손실 계산을 위해 매수 평단가를 함께 저장한다.
 * ============================================================ */
@Data
public class CoinOrdersDTO {
    private Long orderNo;       // 주문 고유 번호 (PK)
    private String username;    // 주문자 아이디
    private String coinCode;    // 코인 심볼 (예: "BTCUSDT")
    private String orderType;   // 주문 유형: "BUY"(매수), "SELL"(매도)
    private Double orderPrice;  // 체결 단가 (USDT)
    private Double orderCount;  // 체결 수량
    private String orderDate;   // 체결 일시 (문자열 형태)
    private Double avgPrice;    // 매수 평단가 (매도 시 손익 계산용으로 저장)
    private String status;      // 주문 상태: 현재는 항상 "DONE" (코인은 시장가 즉시 체결)
    private Double targetPrice; // 지정가 (현재 미사용, 향후 지정가 기능 확장을 위한 예비 필드)
}