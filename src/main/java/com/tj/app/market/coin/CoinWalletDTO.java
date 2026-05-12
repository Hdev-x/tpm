package com.tj.app.market.coin;

import lombok.Data;

@Data
public class CoinWalletDTO {
    private Long walletNo;
    private String username;
    private Double usdtBalance;
}