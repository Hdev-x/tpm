package com.tj.app.board.reply;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import com.tj.app.member.MemberDTO;

import jakarta.servlet.http.HttpSession;

/** ============================================================
 * [클래스 읽기] 게시글 댓글 작성·삭제 요청을 처리하는 컨트롤러.
 *
 * [@Controller + @RequestMapping("/reply/*")]
 *   /reply/ 아래의 요청을 처리한다.
 *
 * [담당 엔드포인트]
 *   POST /reply/create : 댓글 등록 (AJAX, @ResponseBody)
 *   POST /reply/delete : 댓글 삭제 → 게시글 상세 리다이렉트
 *
 * [게시글 상세 조회는 BoardController에서 담당]
 *   댓글 목록 포함 조회는 BoardController.detail()에서 처리한다.
 * ============================================================ */
@Controller
@RequestMapping("/reply/*")
public class ReplyController {

	@Autowired
	private ReplyService replyService;

	/** ============================================================
	 * [메서드 읽기] 댓글을 등록한다. POST /reply/create
	 *
	 * [비동기 처리 (AJAX)]
	 *   @ResponseBody → 페이지 이동 없이 문자열만 응답한다.
	 *   JS에서 fetch/XMLHttpRequest로 호출하고 반환값으로 UI를 갱신한다.
	 *
	 * [실행 흐름]
	 * 1. 세션에서 MemberDTO 확인 → null이면 "not_logged_in" 반환
	 * 2. replyDTO에 세션 username 설정 (클라이언트 값 무시 → 보안)
	 * 3. replyService.create() → DB INSERT
	 * 4. result > 0이면 "1" 반환, 실패 시 "0" 반환
	 *    JS에서 "1"이면 성공 처리, "0"이면 실패 안내, "not_logged_in"이면 로그인 안내.
	 *
	 * [String 반환] @ResponseBody + String = 문자열 그대로 응답.
	 * ============================================================ */
	@PostMapping("create")
	@ResponseBody
	public String create(ReplyDTO replyDTO, HttpSession session) throws Exception {
		MemberDTO member = (MemberDTO) session.getAttribute("member");

		// [실행 흐름] 비로그인 → JS가 인식할 수 있는 신호 문자열 반환
		if (member == null) {
			return "not_logged_in";
		}

		replyDTO.setUsername(member.getUsername()); // [보안] 서버 측 username으로 설정

		int result = replyService.create(replyDTO);

		// [실행 흐름] 성공 "1", 실패 "0" 반환 (JS와의 약속)
		if (result > 0) {
			return "1";
		} else {
			return "0";
		}
	}

	/** ============================================================
	 * [메서드 읽기] 댓글을 삭제하고 게시글 상세 페이지로 리다이렉트한다. POST /reply/delete
	 *
	 * [실행 흐름]
	 * 1. replyDTO.boardNo를 미리 꺼내 저장 (delete 후 DTO가 덮어씌워질 수 있으므로)
	 * 2. replyService.delete() → DB DELETE
	 * 3. "redirect:/board/detail?boardNo=" + boardNo → 같은 게시글 상세 페이지로 이동
	 *
	 * [소유권 확인 없음] 현재 구현에서는 username 체크 없이 삭제된다.
	 *   SQL WHERE 절에 username 조건을 추가하거나 서비스에서 검증하는 것이 더 안전하다.
	 * ============================================================ */
	@PostMapping("delete")
	public String delete(ReplyDTO replyDTO) throws Exception {
		Long boardNo = replyDTO.getBoardNo(); // [코드 읽기] 리다이렉트 URL에 쓸 boardNo를 미리 저장
		replyService.delete(replyDTO);        // [실행 흐름] DB DELETE
		return "redirect:/board/detail?boardNo=" + boardNo; // [실행 흐름] 게시글 상세로 리다이렉트
	}
}
