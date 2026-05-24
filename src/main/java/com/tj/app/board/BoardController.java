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

import com.tj.app.board.like.LikeDTO;
import com.tj.app.board.like.LikeService;
import com.tj.app.member.MemberDTO;
import com.tj.app.common.pager.Pager;
import com.tj.app.board.reply.ReplyDTO;
import com.tj.app.board.reply.ReplyService;

import jakarta.servlet.http.HttpSession;

/** ============================================================
 * [클래스 읽기] 게시판 게시글 CRUD 요청을 처리하는 컨트롤러.
 *
 * [@Controller + @RequestMapping("/board/*")]
 *   모든 엔드포인트는 /board/ 아래에 매핑된다.
 *   @ResponseBody가 없으므로 메서드 반환값은 뷰 이름(JSP 경로)이다.
 *
 * [의존성 주입 방식 혼용]
 *   LikeService : 생성자 주입 (constructor injection) — final 필드 + 생성자로 주입
 *   BoardService, ReplyService : 필드 주입 (@Autowired)
 *   생성자 주입이 더 안전(테스트 용이, NPE 방지)하지만 여기서는 혼용되어 있다.
 * ============================================================ */
@Controller
@RequestMapping("/board/*")
public class BoardController {

	/** LikeService: final + 생성자 주입 (불변성 보장) */
	@Autowired
    private final LikeService likeService;

    @Autowired
    private BoardService boardService;

    @Autowired
    private ReplyService replyService;

	/** ============================================================
	 * [생성자 읽기] LikeService를 생성자로 주입받는다.
	 *
	 * [이유] likeService 필드가 final로 선언되어 있으면 반드시 생성자에서 초기화해야 한다.
	 *   @Autowired를 필드와 생성자 양쪽에 모두 쓰는 것은 중복이지만 동작에 문제는 없다.
	 * ============================================================ */
    BoardController(LikeService likeService) {
        this.likeService = likeService;
    }

	/** ============================================================
	 * [메서드 읽기] 게시글 목록 페이지(board/list.jsp)로 이동한다.
	 *
	 * [실행 흐름]
	 * 1. Pager 파라미터: Spring이 쿼리 파라미터(currentPage 등)를 자동으로 Pager에 바인딩
	 * 2. boardService.list() → 페이징 계산 + 목록 조회
	 * 3. model에 "list" 담기 → JSP에서 ${list}로 접근
	 * ============================================================ */
    @GetMapping("list")
    public String list(Pager pager, Model model) throws Exception {
    	List<BoardDTO> list = boardService.list(pager);
    	model.addAttribute("list", list);
    	return "board/list"; // board/list.jsp 렌더링
    }

	/** ============================================================
	 * [메서드 읽기] 게시글 상세 페이지(board/detail.jsp)로 이동한다.
	 *
	 * [실행 흐름]
	 * 1. boardService.detail() → 조회수 +1 + 본문 + 파일 목록 조회
	 * 2. 세션에서 MemberDTO 꺼냄 (비로그인 허용 — 비로그인도 상세 조회 가능)
	 * 3. 좋아요 정보:
	 *    - 로그인 상태: likeService.checkLike() → 현재 사용자 좋아요 여부 → "myLike"
	 *    - 비로그인: myLike 미설정 (null)
	 *    - 전체 좋아요 수는 로그인 여부 무관하게 항상 조회 → "likeCount"
	 * 4. 댓글 목록: replyService.list() → "replyList"
	 *
	 * [BoardDTO 파라미터] Spring이 쿼리 파라미터(boardNo 등)를 자동으로 boardDTO에 바인딩한다.
	 *   예: GET /board/detail?boardNo=5 → boardDTO.boardNo = 5
	 * ============================================================ */
    @GetMapping("detail")
    public String detail(BoardDTO boardDTO, Model model, HttpSession session) throws Exception {
        BoardDTO detail = boardService.detail(boardDTO); // [실행 흐름] 조회수 +1 + 상세 조회
        model.addAttribute("detail", detail);

        // [실행 흐름] 좋아요 정보 조회 — 비로그인도 개수는 볼 수 있어야 하므로 분리
        MemberDTO member = (MemberDTO) session.getAttribute("member");

        LikeDTO likeDTO = new LikeDTO();
        likeDTO.setBoardNo(detail.getBoardNo());

        if (member != null) {
            likeDTO.setUsername(member.getUsername());
            // [실행 흐름] 이 사용자가 좋아요를 눌렀는지 → myLike가 null이 아니면 이미 누름
            model.addAttribute("myLike", likeService.checkLike(likeDTO));
        }

        // [실행 흐름] 전체 좋아요 수 (비로그인도 표시)
        model.addAttribute("likeCount", likeService.getCount(likeDTO));

        // [실행 흐름] 댓글 목록 조회 → JSP에서 ${replyList}로 출력
        ReplyDTO replyDTO = new ReplyDTO();
        replyDTO.setBoardNo(detail.getBoardNo());
        model.addAttribute("replyList", replyService.list(replyDTO));

        return "board/detail"; // board/detail.jsp 렌더링
    }

	/** ============================================================
	 * [메서드 읽기] 게시글 작성 폼 페이지(board/create.jsp)로 이동한다.
	 * ============================================================ */
    @GetMapping("create")
    public String create() throws Exception{
    	return "board/create"; // board/create.jsp 렌더링 (빈 폼)
    }

	/** ============================================================
	 * [메서드 읽기] 게시글을 등록하고 목록 페이지로 리다이렉트한다.
	 *
	 * [실행 흐름]
	 * 1. 세션에서 MemberDTO 확인 → 로그인 상태면 boardWriter·username 설정
	 * 2. boardService.create() → DB INSERT + 파일 저장
	 * 3. "redirect:./list" → POST 완료 후 GET /board/list로 이동 (PRG 패턴)
	 *
	 * [PRG 패턴] POST-Redirect-GET: 제출 후 즉시 redirect하면 새로고침 시 중복 제출 방지.
	 *
	 * [@RequestParam attach] 파일 배열. required=false → 첨부 없어도 됨.
	 * ============================================================ */
    @PostMapping("create")
    public String create(BoardDTO boardDTO,
    					 @RequestParam(value = "attach", required = false) MultipartFile[] attach,
    					 HttpSession session) throws Exception {
    	MemberDTO memberDTO = (MemberDTO) session.getAttribute("member");

    	if(memberDTO != null) {
    		boardDTO.setBoardWriter(memberDTO.getUsername()); // 화면 표시용 작성자명
    		boardDTO.setUsername(memberDTO.getUsername());    // 소유권 확인용 아이디
    	}

    	int result = boardService.create(boardDTO, attach);
    	return "redirect:./list"; // [실행 흐름] PRG 패턴 — 목록 페이지로 리다이렉트
    }

	/** ============================================================
	 * [메서드 읽기] 게시글 수정 폼 페이지(board/update.jsp)로 이동한다.
	 *
	 * [실행 흐름] 기존 게시글 정보를 조회해 model에 담아 JSP에 전달 → 폼에 pre-fill.
	 * ============================================================ */
    @GetMapping("update")
    public String update(BoardDTO boardDTO, Model model) throws Exception {
    	boardDTO = boardService.detail(boardDTO); // [실행 흐름] 기존 내용 조회 (조회수도 +1됨)

    	model.addAttribute("detail", boardDTO); // JSP 폼의 기본값으로 사용
    	return "board/update";
    }

	/** ============================================================
	 * [메서드 읽기] 게시글을 수정하고 목록 페이지로 리다이렉트한다.
	 *
	 * [ModelAndView]
	 *   Model + View 이름을 하나의 객체로 관리하는 Spring 클래스.
	 *   setViewName() = 뷰 이름 설정, addObject() = model attribute 추가.
	 *   여기서는 redirect URL을 설정하는 용도로 사용한다.
	 *
	 * [주의] redirect 시 mv.addObject("update", boardDTO)를 추가했지만
	 *   redirect는 URL로만 데이터를 전달하므로 이 값은 실제로 JSP에 전달되지 않는다.
	 * ============================================================ */
    @PostMapping("update")
    public ModelAndView update(BoardDTO boardDTO,
    						   @RequestParam(value = "attach", required = false) MultipartFile[] attach,
    						   Model model) throws Exception {
	   int result = boardService.update(boardDTO, attach); // [실행 흐름] DB UPDATE + 파일 추가

	   ModelAndView mv = new ModelAndView();
	   mv.setViewName("redirect:./list"); // [실행 흐름] 수정 후 목록 페이지로 리다이렉트
	   mv.addObject("update", boardDTO);  // [주의] redirect 시 이 값은 JSP에 전달되지 않음

	   return mv;
   }

	/** ============================================================
	 * [메서드 읽기] 게시글을 삭제한다.
	 *
	 * [실행 흐름]
	 * 1. 세션에서 MemberDTO 확인
	 * 2. boardService.detail() → 삭제할 게시글의 boardWriter 조회
	 * 3. boardWriter와 로그인 username 비교 → 일치하면 삭제 → 목록 리다이렉트
	 *    불일치하면 "common/result.jsp"에 오류 메시지 표시
	 *
	 * [보안] boardWriter.equals(memberDTO.getUsername())로 본인 글인지 서버에서 확인.
	 *   클라이언트에서 boardNo만 보내도 타인 글 삭제가 불가능하다.
	 *
	 * [model.addAttribute("url")] result.jsp에서 이 URL로 이동 버튼을 표시한다.
	 * ============================================================ */
    @PostMapping("delete")
    public String delete(BoardDTO boardDTO, HttpSession session, Model model) throws Exception {
    	MemberDTO memberDTO = (MemberDTO) session.getAttribute("member");

    	boardDTO = boardService.detail(boardDTO); // [실행 흐름] boardWriter 확인을 위해 상세 조회

    	if (boardDTO.getBoardWriter().equals(memberDTO.getUsername())) {
			// [실행 흐름] 본인 글 → 삭제 후 목록으로
			int result = boardService.delete(boardDTO);
			return "redirect:./list";
		} else {
			// [실행 흐름] 타인 글 → 오류 메시지 표시
			model.addAttribute("msg", "작성자가 아닙니다.");
			model.addAttribute("url", "./list");
			return "common/result"; // common/result.jsp: msg와 url을 받아 안내 화면 출력
		}
    }
}
