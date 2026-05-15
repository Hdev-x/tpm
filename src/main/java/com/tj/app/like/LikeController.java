package com.tj.app.like;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import jakarta.servlet.http.HttpSession;
import com.tj.app.member.MemberDTO;

@Controller
@RequestMapping("/like/*")
public class LikeController {

    @Autowired
    private LikeService likeService;

    @PostMapping("toggle")
    @ResponseBody // 👈 페이지 이동 없이 데이터(0 또는 1)만 브라우저로 보냅니다.
    public int toggle(LikeDTO likeDTO, HttpSession session) throws Exception {
        // 1. 로그인 확인
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) {
            return -1; // 로그인이 안 되어 있으면 -1 리턴 (스크립트에서 처리)
        }

        // 2. 현재 로그인한 유저의 아이디를 LikeDTO에 세팅
        likeDTO.setUsername(member.getUsername());

        // 3. 서비스 호출 (눌렀으면 1, 취소했으면 0 리턴 예정)
        return likeService.toggleLike(likeDTO);
    }
}