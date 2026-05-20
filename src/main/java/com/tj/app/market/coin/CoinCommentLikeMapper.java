package com.tj.app.market.coin;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface CoinCommentLikeMapper {
    int insert(@Param("commentNo") Long commentNo, @Param("username") String username);
    int delete(@Param("commentNo") Long commentNo, @Param("username") String username);
    int check(@Param("commentNo") Long commentNo, @Param("username") String username);
    long count(@Param("commentNo") Long commentNo);
}
