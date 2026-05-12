package com.tj.app.market.coin;

import lombok.Data;

@Data
public class CoinHoldingsDTO {
    private Long holdingNo;
    private String username;
    private String coinCode;
    private Double coinCount;
    private Double avgPrice;
}