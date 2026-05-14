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

import com.tj.app.member.MemberDTO;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/board/*")
public class BoardController {

    @Autowired
    private BoardService boardService;

    @GetMapping("list")
    public String list(BoardDTO boardDTO, Model model) throws Exception {
    	List<BoardDTO> list = boardService.list(boardDTO);
    	model.addAttribute("list", list);
    	return "board/list";
    }
    
    @GetMapping("detail")
    public String detail(BoardDTO boardDTO, Model model) throws Exception {
    	boardDTO = boardService.detail(boardDTO);
    	model.addAttribute("detail", boardDTO);
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

