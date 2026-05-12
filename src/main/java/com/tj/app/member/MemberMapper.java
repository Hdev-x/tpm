package com.tj.app.member;

import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface MemberMapper {

	public int create(MemberDTO memberDTO) throws Exception;
	
	public MemberDTO read(MemberDTO memberDTO) throws Exception;
	
	public int update(MemberDTO memberDTO) throws Exception;
	
	public int delete(MemberDTO memberDTO) throws Exception;
		
}
