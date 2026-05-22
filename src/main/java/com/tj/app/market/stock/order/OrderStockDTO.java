package com.tj.app.market.stock.order;

import java.time.LocalDate;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
public class OrderStockDTO {
	
	private Long orderId;
	private String orderType;
	private Long orderPrice;
	private Long orderCount;
	private LocalDate orderDate;
	private Long stockNo;
	private String stockCode;
	private String username;
	private String status;
	private Long targetPrice;
}
