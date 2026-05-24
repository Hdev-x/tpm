package com.tj.app.board.like;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import jakarta.servlet.http.HttpSession;
import com.tj.app.member.MemberDTO;

/** ============================================================
 * [클래스 읽기] 게시글 좋아요 토글 요청을 처리하는 컨트롤러.
 *
 * [@Controller + @ResponseBody]
 *   @ResponseBody가 메서드에 붙어 있으므로 int 반환값이 JSON/텍스트로 직접 응답된다.
 *   페이지 이동 없이 숫자(0, 1, -1)만 브라우저로 보낸다.
 *
 * [반환값 의미 — JS와의 약속]
 *   -1 → 비로그인 (로그인 안내 필요)
 *    1 → 좋아요 추가됨 (하트 활성화)
 *    0 → 좋아요 취소됨 (하트 비활성화)
 * ============================================================ */
@Controller
@RequestMapping("/like/*")
public class LikeController {

    @Autowired
    private LikeService likeService;

    /** ============================================================
     * [메서드 읽기] 좋아요를 토글(추가↔취소)한다. POST /like/toggle
     *
     * [실행 흐름]
     * 1. 세션에서 MemberDTO 확인 → null이면 -1 반환 (비로그인 신호)
     * 2. likeDTO에 세션의 username 설정 (클라이언트 값 무시 → 보안)
     * 3. likeService.toggleLike() → 1(좋아요) 또는 0(취소) 반환
     * 4. JS에서 반환값으로 하트 아이콘 상태와 개수를 갱신한다.
     *
     * [LikeDTO 파라미터] Spring이 요청 파라미터(boardNo 등)를 자동으로 LikeDTO에 바인딩.
     *   JS fetch/form에서 boardNo를 함께 전송해야 한다.
     * ============================================================ */
    @PostMapping("toggle")
    @ResponseBody
    public int toggle(LikeDTO likeDTO, HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) {
            return -1; // [실행 흐름] 비로그인 → -1 반환 (JS에서 로그인 안내 처리)
        }

        likeDTO.setUsername(member.getUsername()); // [보안] 서버 측 username으로 설정

        // [실행 흐름] 좋아요 토글 → 1(추가) 또는 0(취소) 반환
        return likeService.toggleLike(likeDTO);
    }
}
