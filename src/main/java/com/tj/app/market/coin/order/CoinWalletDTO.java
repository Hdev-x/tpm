package com.tj.app.market.coin.order;

import lombok.Data;

/** ============================================================
 * [클래스 읽기] 코인 지갑(USDT 잔고)을 담는 DTO.
 *
 * COIN_WALLET 테이블과 1:1 대응한다.
 * 회원 가입 시 coinMapper.createWallet()으로 초기 생성되며,
 * 코인 매수/매도·환전 시 usdtBalance가 업데이트된다.
 * usdtBalance는 코인 거래에 사용하는 투자 자금(USDT 단위)이다.
 * ============================================================ */
@Data
public class CoinWalletDTO {
    private Long walletNo;       // 지갑 고유 번호 (PK)
    private String username;     // 지갑 소유자 아이디 (FK)
    private Double usdtBalance;  // 보유 USDT 잔고 (코인 매수 가능 금액)
}