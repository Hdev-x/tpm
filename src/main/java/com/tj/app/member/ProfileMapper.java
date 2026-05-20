package com.tj.app.member;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface ProfileMapper {
    ProfileDTO findByUsername(@Param("username") String username);
    int insert(ProfileDTO dto);
    int update(ProfileDTO dto);
}
