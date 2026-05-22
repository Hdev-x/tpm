package com.tj.app.market.community;

import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface MarketCommentMapper {
    int insert(MarketCommentDTO dto) throws Exception;
    List<MarketCommentDTO> listByCode(@Param("marketType") String marketType, @Param("marketCode") String marketCode) throws Exception;
    List<MarketCommentDTO> listByCodePopular(@Param("marketType") String marketType, @Param("marketCode") String marketCode) throws Exception;
    int update(MarketCommentDTO dto) throws Exception;
    int delete(@Param("commentNo") Long commentNo, @Param("username") String username) throws Exception;
}
