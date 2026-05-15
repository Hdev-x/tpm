package com.tj.app.notice;

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
@RequestMapping("/notice/*")
public class NoticeController {

    @Autowired
    private NoticeService noticeService;

    @GetMapping("list")
    public String list(NoticeDTO noticeDTO, Model model) throws Exception {
    	List<NoticeDTO> list = noticeService.list(noticeDTO);
    	model.addAttribute("list", list);
    	return "notice/list";
    }
    
    @GetMapping("detail")
    public String detail(NoticeDTO noticeDTO, Model model) throws Exception {
    	noticeDTO = noticeService.detail(noticeDTO);
    	model.addAttribute("detail", noticeDTO);
    	return "notice/detail";
    }
    
    @GetMapping("create")
    public String create() throws Exception{
    	return "notice/create";
    }
    
    @PostMapping("create")
    public String create(NoticeDTO noticeDTO, @RequestParam(value = "attach", required = false) MultipartFile[] attach, HttpSession session) throws Exception {
    	MemberDTO memberDTO = (MemberDTO) session.getAttribute("member");
    	if(memberDTO !=null) {
    		noticeDTO.setNoticeWriter(memberDTO.getUsername());
    	}
    	
    	int result = noticeService.create(noticeDTO, attach);
    	return "redirect:./list";
    }
    
    @GetMapping("update")
    public String update(NoticeDTO noticeDTO, Model model) throws Exception {
    	noticeDTO = noticeService.detail(noticeDTO);
    	
    	model.addAttribute("detail", noticeDTO);
    	
    	return "notice/update";
    }
   
    @PostMapping("update")
    public ModelAndView update(NoticeDTO noticeDTO, @RequestParam(value = "attach", required = false) MultipartFile[] attach, Model model) throws Exception {
	   int result = noticeService.update(noticeDTO, attach);
	
	   ModelAndView mv = new ModelAndView();
	   
	   mv.setViewName("redirect:./list");
	   mv.addObject("update", noticeDTO);
	   
	   return mv;
   }

    @PostMapping("delete")
    public String delete(NoticeDTO noticeDTO, HttpSession session, Model model) throws Exception {
    	MemberDTO memberDTO = (MemberDTO)session.getAttribute("member");
    	
    	noticeDTO = noticeService.detail(noticeDTO);
    	
    	if(noticeDTO.getNoticeWriter().equals(memberDTO.getUsername())) {
			int result = noticeService.delete(noticeDTO);
			return "redirect:./list";
		}else {
			model.addAttribute("url", "작성자가 아님");
			model.addAttribute("url", "./list");
			return "commons/result";
		}
		
    }
}

