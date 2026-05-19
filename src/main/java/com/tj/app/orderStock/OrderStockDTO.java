package com.tj.app.orderStock;

import java.time.LocalDate;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
public class OrderStockDTO {
	
	private Long orderId;
	private boolean orderType;
	private Long orderPrice;
	private Long orderCount;
	private LocalDate orderDate;
	private Long stockNo;
	private String username;
}
