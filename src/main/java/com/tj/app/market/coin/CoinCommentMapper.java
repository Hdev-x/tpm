package com.tj.app.market.coin;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface CoinCommentMapper {

    int insert(CoinCommentDTO dto) throws Exception;

    List<CoinCommentDTO> listBySymbol(@Param("symbol") String symbol) throws Exception;

    List<CoinCommentDTO> listBySymbolPopular(@Param("symbol") String symbol) throws Exception;

    int update(CoinCommentDTO dto) throws Exception;

    int delete(@Param("commentNo") Long commentNo, @Param("username") String username) throws Exception;
}
