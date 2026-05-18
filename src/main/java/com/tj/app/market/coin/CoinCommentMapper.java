package com.tj.app.market.coin;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface CoinCommentMapper {

    int insert(CoinCommentDTO dto) throws Exception;

    List<CoinCommentDTO> listBySymbol(@Param("symbol") String symbol) throws Exception;
}
