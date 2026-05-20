package com.tj.app.market.stock;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface StockDailyPriceMapper {

    @Insert("""
            INSERT INTO "STOCK_DAILY_PRICE" ("STOCK_CODE", "TRADE_DATE", "CLOSE_PRICE", "VOLUME", "UPDATED_AT")
            VALUES (#{item.stockCode}, #{item.tradeDate}, #{item.closePrice}, #{item.volume}, now())
            ON CONFLICT ("STOCK_CODE", "TRADE_DATE")
            DO UPDATE SET
                "CLOSE_PRICE" = EXCLUDED."CLOSE_PRICE",
                "VOLUME" = EXCLUDED."VOLUME",
                "UPDATED_AT" = now()
            """)
    int upsert(@Param("item") StockDailyPriceDTO item);

    @Select("""
            SELECT
                "STOCK_CODE" AS "stockCode",
                "TRADE_DATE" AS "tradeDate",
                "CLOSE_PRICE" AS "closePrice",
                "VOLUME" AS "volume"
            FROM "STOCK_DAILY_PRICE"
            WHERE "STOCK_CODE" = #{stockCode}
              AND "TRADE_DATE" >= CURRENT_DATE - INTERVAL '1 year'
            ORDER BY "TRADE_DATE"
            """)
    List<StockDailyPriceDTO> findOneYearByStockCode(@Param("stockCode") String stockCode);
}
