package com.tj.app.like;

import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface LikeMapper {

	public int create(LikeDTO likeDTO) throws Exception;
	
	public int delete(LikeDTO likeDTO) throws Exception;
	
	public LikeDTO checkLike(LikeDTO likeDTO) throws Exception;
	
	public Long countLike(LikeDTO likeDTO) throws Exception;
}
