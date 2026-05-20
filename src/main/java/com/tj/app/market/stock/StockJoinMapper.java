package com.tj.app.market.stock;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

@Mapper
public interface StockJoinMapper {

    /**
     * 🔍 1. [이름 -> 코드 변환]
     * 사용자가 입력한 검색어로 DB에서 대문자 컬럼 스펙에 맞춰 주식 코드를 찾습니다.
     * 공백을 넣거나 대소문자를 섞어쳐도 검색이 되도록 LOWER, REPLACE를 적용했습니다.
     */
    @Select("SELECT \"STOCK_CODE\" FROM \"STOCK\" " +
            "WHERE LOWER(REPLACE(\"STOCK_NAME\", ' ', '')) = #{cleanKeyword}")
    String findCodeByCleanName(@Param("cleanKeyword") String cleanKeyword);

    /**
     * 📛 2. [코드 -> 이름 변환]
     * 한투 API가 반환한 6자리 종목 코드를 기반으로, DB에서 진짜 주식 이름을 매칭해 옵니다.
     */
    @Select("SELECT \"STOCK_NAME\" FROM \"STOCK\" " +
            "WHERE \"STOCK_CODE\" = #{code}")
    String findNameByStockCode(@Param("code") String code);

    @Select("SELECT \"STOCK_CODE\" AS code, \"STOCK_NAME\" AS name FROM \"STOCK\" ORDER BY \"STOCK_CODE\"")
    List<Map<String, Object>> findAllStocks();

    @Select("SELECT \"STOCK_CODE\" AS code, \"STOCK_NAME\" AS name FROM \"STOCK\" LIMIT 40")
    List<Map<String, Object>> findTop40Stocks();
}