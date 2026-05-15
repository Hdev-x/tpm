package com.tj.app.reply;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/reply/*")
public class ReplyController {
	
	@Autowired
	private ReplyService replyService;
	
	@PostMapping("create")
	public String create(ReplyDTO replyDTO) throws Exception {
		replyService.create(replyDTO);
		return "redirect:/board/detail?boardNo"+replyDTO.getBoardNo();
	}
	
	public String delete(ReplyDTO replyDTO) throws Exception {
		int result = replyService.delete(replyDTO);
		return "redirect:/board/detail?boardNo"+result;
	}
}
