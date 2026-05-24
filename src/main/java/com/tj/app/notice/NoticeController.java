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

/** ============================================================
 * [클래스 읽기] 공지사항 CRUD 요청을 처리하는 컨트롤러.
 *
 * BoardController와 구조가 거의 동일하지만 더 단순하다.
 * 차이점:
 *   - 좋아요(LikeService), 댓글(ReplyService) 의존성 없음
 *   - 생성자 주입 없이 모두 @Autowired 필드 주입 사용
 *   - list()가 Pager가 아닌 NoticeDTO를 파라미터로 받음 (페이징 없음)
 *   - create() POST에서 boardWriter 대신 noticeWriter만 설정 (username 미설정)
 *
 * [@Controller + @RequestMapping("/notice/*")]
 *   모든 엔드포인트는 /notice/ 아래에 매핑된다.
 *   @ResponseBody 없으므로 반환값은 뷰 이름(JSP 경로)이다.
 * ============================================================ */
@Controller
@RequestMapping("/notice/*")
public class NoticeController {

    @Autowired
    private NoticeService noticeService;

    /** ============================================================
     * [메서드 읽기] 공지사항 목록 페이지(notice/list.jsp)로 이동한다.
     *
     * [실행 흐름] noticeService.list() → 전체 목록 조회 → model에 담아 JSP에 전달.
     * NoticeDTO에 검색 조건이 담겨 있으면 Service를 통해 SQL에 반영된다.
     * ============================================================ */
    @GetMapping("list")
    public String list(NoticeDTO noticeDTO, Model model) throws Exception {
    	List<NoticeDTO> list = noticeService.list(noticeDTO);
    	model.addAttribute("list", list);
    	return "notice/list"; // notice/list.jsp 렌더링
    }

    /** ============================================================
     * [메서드 읽기] 공지사항 상세 페이지(notice/detail.jsp)로 이동한다.
     *
     * [실행 흐름]
     * 1. noticeService.detail() → 조회수 +1 + 본문 + 파일 목록 조회
     * 2. "detail" model attribute로 noticeDTO를 전달
     *
     * [BoardController.detail()과 차이]
     *   좋아요·댓글 조회 없음 (공지사항은 해당 기능 없음)
     *   세션에서 MemberDTO를 꺼낼 필요가 없다.
     * ============================================================ */
    @GetMapping("detail")
    public String detail(NoticeDTO noticeDTO, Model model) throws Exception {
    	noticeDTO = noticeService.detail(noticeDTO); // [실행 흐름] 조회수 +1 + 상세 조회
    	model.addAttribute("detail", noticeDTO);
    	return "notice/detail"; // notice/detail.jsp 렌더링
    }

    /** ============================================================
     * [메서드 읽기] 공지사항 작성 폼 페이지(notice/create.jsp)로 이동한다.
     * ============================================================ */
    @GetMapping("create")
    public String create() throws Exception{
    	return "notice/create"; // 빈 폼 페이지
    }

    /** ============================================================
     * [메서드 읽기] 공지사항을 등록하고 목록 페이지로 리다이렉트한다.
     *
     * [실행 흐름]
     * 1. 세션에서 MemberDTO 확인 → 로그인 상태면 noticeWriter·username 모두 설정
     * 2. noticeService.create() → DB INSERT + 파일 저장
     * 3. "redirect:./list" → PRG 패턴
     *
     * [noticeWriter vs username]
     *   noticeWriter : 화면에 표시되는 작성자명
     *   username     : 소유권 확인(삭제 시 본인 여부)에 사용하는 실제 로그인 아이디
     *   둘 다 세션의 username 값으로 설정한다.
     * ============================================================ */
    @PostMapping("create")
    public String create(NoticeDTO noticeDTO,
    					 @RequestParam(value = "attach", required = false) MultipartFile[] attach,
    					 HttpSession session) throws Exception {
    	MemberDTO memberDTO = (MemberDTO) session.getAttribute("member");
    	if (memberDTO != null) {
    		noticeDTO.setNoticeWriter(memberDTO.getUsername()); // 화면 표시용 작성자명
    		noticeDTO.setUsername(memberDTO.getUsername());     // 소유권 확인용 아이디
    	}

    	int result = noticeService.create(noticeDTO, attach);
    	return "redirect:./list"; // [실행 흐름] PRG 패턴 — 목록으로 리다이렉트
    }

    /** ============================================================
     * [메서드 읽기] 공지사항 수정 폼 페이지(notice/update.jsp)로 이동한다.
     *
     * [실행 흐름] 기존 공지사항 정보를 조회해 model에 담아 JSP 폼에 pre-fill.
     * ============================================================ */
    @GetMapping("update")
    public String update(NoticeDTO noticeDTO, Model model) throws Exception {
    	noticeDTO = noticeService.detail(noticeDTO);
    	model.addAttribute("detail", noticeDTO);
    	return "notice/update"; // notice/update.jsp 렌더링
    }

    /** ============================================================
     * [메서드 읽기] 공지사항을 수정하고 목록 페이지로 리다이렉트한다.
     *
     * [ModelAndView] View 이름과 Model을 하나로 관리한다.
     *   setViewName("redirect:./list") → 수정 후 목록으로 이동.
     *   mv.addObject("update", noticeDTO) → redirect 시 JSP에 전달되지 않는다.
     * ============================================================ */
    @PostMapping("update")
    public ModelAndView update(NoticeDTO noticeDTO,
    						   @RequestParam(value = "attach", required = false) MultipartFile[] attach,
    						   Model model) throws Exception {
	   int result = noticeService.update(noticeDTO, attach);

	   ModelAndView mv = new ModelAndView();
	   mv.setViewName("redirect:./list"); // [실행 흐름] 수정 후 목록으로 리다이렉트
	   mv.addObject("update", noticeDTO); // [주의] redirect 시 JSP에 전달되지 않음

	   return mv;
   }

    /** ============================================================
     * [메서드 읽기] 공지사항을 삭제한다.
     *
     * [실행 흐름]
     * 1. 세션에서 MemberDTO 확인
     * 2. noticeService.detail() → noticeWriter 조회
     * 3. noticeWriter와 로그인 username 비교 → 일치하면 삭제 → 목록 리다이렉트
     *    불일치하면 common/result.jsp에 오류 메시지 표시
     *
     * create() POST에서 noticeWriter·username 모두 세션 아이디로 저장하므로
     *   noticeWriter 비교로 소유권을 확인한다.
     * ============================================================ */
    @PostMapping("delete")
    public String delete(NoticeDTO noticeDTO, HttpSession session, Model model) throws Exception {
    	MemberDTO memberDTO = (MemberDTO) session.getAttribute("member");

    	noticeDTO = noticeService.detail(noticeDTO); // noticeWriter 확인을 위해 상세 조회

    	if (noticeDTO.getNoticeWriter().equals(memberDTO.getUsername())) {
			// [실행 흐름] 본인 글 → 삭제 후 목록으로
			int result = noticeService.delete(noticeDTO);
			return "redirect:./list";
		} else {
			// [실행 흐름] 타인 글 → 오류 메시지 표시
			model.addAttribute("msg", "작성자가 아닙니다.");
			model.addAttribute("url", "./list");
			return "common/result"; // 안내 화면 (msg·url을 받아 표시)
		}
    }
}
