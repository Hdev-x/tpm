package com.tj.app.board;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.ModelAndView;

import com.tj.app.like.LikeDTO;
import com.tj.app.like.LikeService;
import com.tj.app.member.MemberDTO;
import com.tj.app.reply.ReplyDTO;
import com.tj.app.reply.ReplyService;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/board/*")
public class BoardController {

	@Autowired
    private final LikeService likeService;

    @Autowired
    private BoardService boardService;
    
    @Autowired
    private ReplyService replyService;


    BoardController(LikeService likeService) {
        this.likeService = likeService;
    }
    

    @GetMapping("list")
    public String list(BoardDTO boardDTO, Model model) throws Exception {
    	List<BoardDTO> list = boardService.list(boardDTO);
    	model.addAttribute("list", list);
    	return "board/list";
    }
    
    @GetMapping("detail")
    public String detail(BoardDTO boardDTO, Model model, HttpSession session) throws Exception {
        // 1. 게시글 상세 정보 (조회수 증가 로직이 detail 내부에 포함되어 있다면 좋습니다)
        BoardDTO detail = boardService.detail(boardDTO);
        model.addAttribute("detail", detail);

        // 2. 좋아요 관련 정보 처리
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        int likeCount = 0;
        
        // 비로그인 상태여도 좋아요 개수는 보여야 하므로 따로 뺍니다.
        LikeDTO likeDTO = new LikeDTO();
        likeDTO.setBoardNo(detail.getBoardNo());
        
        if (member != null) {
            likeDTO.setUsername(member.getUsername());
            // 로그인 유저의 좋아요 클릭 여부 (객체 혹은 null)
            model.addAttribute("myLike", likeService.checkLike(likeDTO));
        }
        
        // 전체 좋아요 개수 담기
        model.addAttribute("likeCount", likeService.getCount(likeDTO));

        // 3. 댓글 리스트 조회
        ReplyDTO replyDTO = new ReplyDTO();
        replyDTO.setBoardNo(detail.getBoardNo());
        model.addAttribute("replyList", replyService.list(replyDTO));

        return "board/detail";
    }
    
    @GetMapping("create")
    public String create() throws Exception{
    	return "board/create";
    }
    
    @PostMapping("create")
    public String create(BoardDTO boardDTO, @RequestParam(value = "attach", required = false) MultipartFile[] attach, HttpSession session) throws Exception {
    	MemberDTO memberDTO = (MemberDTO) session.getAttribute("member");
    	
    	if(memberDTO !=null) {
    		boardDTO.setBoardWriter(memberDTO.getUsername());
    		boardDTO.setUsername(memberDTO.getUsername());
    	}
    	
    	int result = boardService.create(boardDTO, attach);
    	return "redirect:./list";
    }
    
    @GetMapping("update")
    public String update(BoardDTO boardDTO, Model model) throws Exception {
    	boardDTO = boardService.detail(boardDTO);
    	
    	model.addAttribute("detail", boardDTO);
    	
    	return "board/update";
    }
   
    @PostMapping("update")
    public ModelAndView update(BoardDTO boardDTO, @RequestParam(value = "attach", required = false) MultipartFile[] attach, Model model) throws Exception {
	   int result = boardService.update(boardDTO, attach);
	
	   ModelAndView mv = new ModelAndView();
	   
	   mv.setViewName("redirect:./list");
	   mv.addObject("update", boardDTO);
	   
	   return mv;
   }

    @PostMapping("delete")
    public String delete(BoardDTO boardDTO, HttpSession session, Model model) throws Exception {
    	MemberDTO memberDTO = (MemberDTO)session.getAttribute("member");
    	
    	boardDTO = boardService.detail(boardDTO);
    	
    	if(boardDTO.getBoardWriter().equals(memberDTO.getUsername())) {
			int result = boardService.delete(boardDTO);
			return "redirect:./list";
		}else {
			model.addAttribute("url", "작성자가 아님");
			model.addAttribute("url", "./list");
			return "commons/result";
		}
		
    }
}

