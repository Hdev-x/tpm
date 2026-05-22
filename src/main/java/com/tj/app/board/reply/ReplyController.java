package com.tj.app.board.reply;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import com.tj.app.board.BoardDTO;
import com.tj.app.board.BoardService;
import com.tj.app.member.MemberDTO;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/reply/*")
public class ReplyController {

    private final BoardService boardService;

	@Autowired
	private ReplyService replyService;

    ReplyController(BoardService boardService) {
        this.boardService = boardService;
    }

    @PostMapping("create")
    public String create(ReplyDTO replyDTO, HttpSession session) throws Exception {
    	
    	MemberDTO member = (MemberDTO) session.getAttribute("member");
    	
        if (member == null) {
        	return "redirect:/member/login";
        }
        
        replyDTO.setUsername(member.getUsername());
        replyService.create(replyDTO);

        return "redirect:/board/detail?boardNo=" + replyDTO.getBoardNo();
    }

	@GetMapping("detail")
	public String detail(BoardDTO boardDTO, Model model) throws Exception {
	    // 1. 게시글 상세 데이터를 가져옴 (지금 하고 계신 것)
	    boardDTO = boardService.detail(boardDTO);
	    
	    // 2. 🚨 여기서 댓글 목록을 가져오는 로직이 추가되어야 합니다!
	    ReplyDTO replyDTO = new ReplyDTO();
	    replyDTO.setBoardNo(boardDTO.getBoardNo()); // 현재 게시글 번호를 세팅
	    
	    // ReplyService를 여기서 @Autowired 해서 사용하세요
	    List<ReplyDTO> replyList = replyService.list(replyDTO); 
	    
	    // 3. 모델에 담아서 JSP로 보내줌
	    model.addAttribute("detail", boardDTO);
	    model.addAttribute("replyList", replyList); // 👈 이게 있어야 JSP의 ${replyList}가 작동함!
	    
	    return "board/detail";
	}
	
	@PostMapping("delete")
	public String delete(ReplyDTO replyDTO) throws Exception {
		Long boardNo = replyDTO.getBoardNo();
		replyService.delete(replyDTO);
		return "redirect:/board/detail?boardNo=" + boardNo;
	}
}
