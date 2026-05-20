package com.tj.app.market.stock;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class StockDailyPriceDTO {
    private String stockCode;
    private LocalDate tradeDate;
    private BigDecimal closePrice;
    private BigDecimal volume;
}
