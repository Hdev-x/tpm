package com.tj.app.member;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/member/*")
public class MemberController {

    @Autowired
    private MemberService memberService;

    @GetMapping("create")
    public String create() {
        return "member/create";
    }

    @PostMapping("create")
    public String create(MemberDTO memberDTO) throws Exception {
        memberService.create(memberDTO);
        
        return "redirect:/";
    }

    @GetMapping("read")
    public String read(HttpSession session, Model model) throws Exception {
        MemberDTO user = (MemberDTO) session.getAttribute("member");
        if (user == null) {
        	return "redirect:/member/login";
        }
        
        MemberDTO result = memberService.read(user);
        model.addAttribute("dto", result);
        
        return "member/read";
    }


    @PostMapping("update")
    public String update(MemberDTO memberDTO, HttpSession session) throws Exception {
        memberService.update(memberDTO);
        
        return "redirect:/member/read";
    }

    @GetMapping("delete")
    public String delete(MemberDTO memberDTO, HttpSession session) throws Exception {
        memberService.delete(memberDTO);
        session.invalidate();
        
        return "redirect:/";
    }
    
    @GetMapping("login")
    public String login() throws Exception {
        return "member/login";
    }
    
    @PostMapping("login")
    public String login(MemberDTO memberDTO, HttpSession session) throws Exception {
        MemberDTO result = memberService.read(memberDTO);
        
        if (result != null && result.getPassword().equals(memberDTO.getPassword())) {
            session.setAttribute("member", result);
            return "redirect:/";
        } else {
            return "member/login";
        }
    }
    
    @GetMapping("logout")
    public String logout(HttpSession session) {
        session.invalidate();
        return "redirect:/";
    }
}