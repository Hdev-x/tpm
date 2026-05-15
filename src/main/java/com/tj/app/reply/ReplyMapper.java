package com.tj.app.reply;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ReplyMapper {
	
	public int create(ReplyDTO replyDTO) throws Exception;
	
	public List<ReplyDTO> list(ReplyDTO replyDTO) throws Exception;
	
	public ReplyDTO detail(ReplyDTO replyDTO) throws Exception;
	
	public int update(ReplyDTO replyDTO) throws Exception;
	
	public int delete(ReplyDTO replyDTO) throws Exception;	
	
}
