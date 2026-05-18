package com.tj.app.market.coin;

import lombok.Data;

@Data
public class CoinOrdersDTO {
    private Long orderNo;
    private String username;
    private String coinCode;
    private String orderType;
    private Double orderPrice;
    private Double orderCount;
    private String orderDate;
    private Double avgPrice;
    private String status;
    private Double targetPrice;
}