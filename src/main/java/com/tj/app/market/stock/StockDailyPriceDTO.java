package com.tj.app.market.stock;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

/** ============================================================
 * [클래스 읽기] DB에 저장된 주식 일별 종가 데이터를 담는 DTO.
 *
 * StockChartDTO는 KIS API 응답을 그대로 담는 외부 API 전용 DTO인 반면,
 * StockDailyPriceDTO는 DB(stock_daily_price 테이블)에서 읽어오는 내부 DTO다.
 *
 * 미니차트(StockMiniChartService)에서 종목별 최근 종가 30일치를 조회할 때 사용한다.
 * BigDecimal: 금액·주가처럼 정밀도가 중요한 값에 double 대신 사용한다.
 *   (double은 부동소수점 오차가 있어 금융 계산에 부적합)
 * ============================================================ */
@Data
public class StockDailyPriceDTO {
    private String stockCode;      // 종목 코드 (예: "005930")
    private LocalDate tradeDate;   // 거래 일자
    private BigDecimal closePrice; // 종가 (정밀 소수점 보장)
    private BigDecimal volume;     // 거래량
}
