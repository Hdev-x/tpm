//package com.tj.app.market.stock;
//
//import java.util.List;
//import org.apache.ibatis.annotations.Mapper;
//import org.apache.ibatis.annotations.Param;
//
//@Mapper
//public interface StockMapper {
//    // 사용자의 보유 주식 리스트 조회
//    List<AssetDTO> selectMyStockList(String username);
//
//    // 주식 매수 시 업데이트 또는 삽입 (XML의 MERGE 문 사용)
//    void upsertMyStock( 
//                       @Param("stockCode") String stockCode, 
//                       @Param("stockCount") int stockCount, 
//                       @Param("stockPurchase") long stockPurchase);
//}