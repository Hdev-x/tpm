package com.tj.app.member;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;

import com.tj.app.market.stock.order.OrderStockService;

import jakarta.servlet.http.HttpSession;

@Controller
@RequestMapping("/member/*")
public class MemberController {

    @Autowired
    private MemberService memberService;

    @Autowired
    private ProfileService profileService;
    
    @Autowired
    private OrderStockService orderStockService;

    @GetMapping("create")
    public String create() {
        return "member/create";
    }

    @PostMapping("create")
    public String create(MemberDTO memberDTO, BindingResult bindingResult) throws Exception {
    	
    	if(memberService.doubleCheck(memberDTO, bindingResult)) {
    		return "member/login";
    	}
    	
    	int result = memberService.create(memberDTO);
        
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
        model.addAttribute("profile", profileService.getProfile(user.getUsername()));
        
        // 💡 [추가] 실시간 자산 총액 계산
        // 보유 주식 평가금 + 예수금을 합산합니다.
        long totalAsset = orderStockService.calculateTotalAsset(user);
        model.addAttribute("totalAsset", totalAsset);

        return "member/read";
    }
    
   
    @GetMapping("update")
    public String updateForm(HttpSession session, Model model) throws Exception {
        MemberDTO user = (MemberDTO) session.getAttribute("member");
        if (user == null) return "redirect:/member/login";
        model.addAttribute("dto", memberService.read(user));
        return "member/update";
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
    public String login(@RequestParam(value = "redirect", required = false) String redirect, Model model) throws Exception {
        model.addAttribute("redirect", redirect != null ? redirect : "/");
        return "member/login";
    }

    @PostMapping("login")
    public String login(MemberDTO memberDTO, HttpSession session,
                        @RequestParam(value = "redirect", required = false, defaultValue = "/") String redirect) throws Exception {
        MemberDTO result = memberService.read(memberDTO);

        if (result != null && result.getPassword().equals(memberDTO.getPassword())) {
            session.setAttribute("member", result);
            ProfileDTO profile = profileService.getProfile(result.getUsername());
            session.setAttribute("profileFileName", profile != null ? profile.getFileName() : null);
            return "redirect:" + redirect;
        } else {
            return "member/login";
        }
    }
    
    @PostMapping("profile")
    @ResponseBody
    public ResponseEntity<?> uploadProfile(@RequestParam("file") MultipartFile file, HttpSession session) {
        MemberDTO user = (MemberDTO) session.getAttribute("member");
        if (user == null) return ResponseEntity.status(401).build();
        try {
            profileService.saveProfile(user.getUsername(), file);
            ProfileDTO profile = profileService.getProfile(user.getUsername());
            session.setAttribute("profileFileName", profile.getFileName());
            return ResponseEntity.ok(profile.getFileName());
        } catch (Exception e) {
            return ResponseEntity.status(500).body("업로드 실패");
        }
    }

    @GetMapping("logout")
    public String logout(HttpSession session,
                         @RequestParam(value = "redirect", required = false, defaultValue = "/") String redirect) {
        session.invalidate();
        return "redirect:" + redirect;
    }
}