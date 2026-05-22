package com.tj.app.board.reply;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class ReplyService {
	
	@Autowired
	private ReplyMapper replyMapper;
	
	public int create(ReplyDTO replyDTO) throws Exception {
		int result = replyMapper.create(replyDTO);
		
		return result;
	}
	
	public List<ReplyDTO> list(ReplyDTO replyDTO) throws Exception {
		return replyMapper.list(replyDTO);
	}
	
	public ReplyDTO detail(ReplyDTO replyDTO) throws Exception {
		return replyMapper.detail(replyDTO);
	}
	
	public int update(ReplyDTO replyDTO) throws Exception {
		return replyMapper.update(replyDTO);
	}
	
	public int delete(ReplyDTO replyDTO) throws Exception {
		int result = replyMapper.delete(replyDTO);
		return result;
	}
}
