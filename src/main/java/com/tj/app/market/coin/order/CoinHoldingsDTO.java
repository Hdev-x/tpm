package com.tj.app.market.coin.order;

import lombok.Data;

/** ============================================================
 * [클래스 읽기] 코인 보유 현황 한 건을 담는 DTO.
 *
 * COIN_HOLDINGS 테이블과 1:1 대응한다.
 * 코인을 처음 매수하면 INSERT, 추가 매수 시 coinCount·avgPrice를 UPDATE한다.
 * 전량 매도 시 해당 행을 DELETE한다.
 * avgPrice는 가중평균 평단가로, 수익/손실 계산의 기준이 된다.
 * ============================================================ */
@Data
public class CoinHoldingsDTO {
    private Long holdingNo;   // 보유 고유 번호 (PK)
    private String username;  // 보유자 아이디 (FK)
    private String coinCode;  // 코인 심볼 (예: "BTCUSDT", "ETHUSDT")
    private Double coinCount; // 보유 수량 (소수점 허용, 예: 0.00312 BTC)
    private Double avgPrice;  // 평균 매수가(평단가, USDT 기준) → 수익률 계산에 사용
}