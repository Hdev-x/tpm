package com.tj.app.market.stock;

import lombok.Data;

@Data
public class AssetDTO {
	private String stockCode;      // 종목코드 (DB)
    private String stockName;      // 종목명 (DB JOIN)
    private int quantity;          // 보유수량 (DB: STOCK_COUNT)
    private long purchasePrice;    // 매수단가 (DB: STOCK_PURCHASE)
    
    private long currentPrice;     // 현재가 (API)
    private double profitRate;     // 수익률 (계산)
    private long evaluationAmount; // 평가금액 (현재가 * 수량)
}
