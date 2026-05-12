package com.tj.app.member;

public interface MemberService {
	
	public int create(MemberDTO memberDTO) throws Exception;
	
	public int update(MemberDTO memberDTO) throws Exception;
	
	public int delete(MemberDTO memberDTO) throws Exception;
	
	public MemberDTO read(MemberDTO memberDTO) throws Exception;
}
