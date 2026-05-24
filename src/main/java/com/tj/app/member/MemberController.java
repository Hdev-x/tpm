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

import com.tj.app.asset.AssetService;

import jakarta.servlet.http.HttpSession;

/** ============================================================
 * [클래스 읽기] 회원 관련 요청을 처리하는 Controller.
 *
 * @Controller  → 반환값을 뷰 이름(JSP 경로)으로 해석한다.
 * @RequestMapping("/member/*") → 이 클래스의 모든 메서드는 /member/ 로 시작하는 URL을 처리한다.
 *
 * [전체 흐름]
 * HTTP 요청 → MemberController → MemberService(비즈니스 로직) → MemberMapper(DB) → 응답
 *
 * 인증 방식: HttpSession. 로그인 성공 시 session에 "member" 키로 MemberDTO를 저장한다.
 * 이후 모든 요청에서 session.getAttribute("member")로 로그인 여부를 확인한다.
 * ============================================================ */
@Controller
@RequestMapping("/member/*")
public class MemberController {

    @Autowired
    private MemberService memberService;

    @Autowired
    private ProfileService profileService;

    @Autowired
    private AssetService assetService; // 마이페이지에서 총 자산 계산에 사용

    /** ============================================================
     * GET /member/create → 회원가입 폼 페이지 반환.
     * 단순히 JSP 뷰만 열어준다.
     * ============================================================ */
    @GetMapping("create")
    public String create() {
        return "member/create";
    }

    /** ============================================================
     * POST /member/create → 회원가입 처리.
     *
     * [실행 흐름]
     * 1. doubleCheck()로 ID 중복·유효성 검사 → 실패하면 로그인 페이지로 이동
     * 2. memberService.create() → DB INSERT + 코인 지갑 생성
     * 3. 성공하면 메인("/")으로 리다이렉트
     *
     * @param bindingResult 폼 바인딩 오류 객체. doubleCheck()에 전달해 오류를 기록한다.
     * ============================================================ */
    @PostMapping("create")
    public String create(MemberDTO memberDTO, BindingResult bindingResult) throws Exception {
        if (memberService.doubleCheck(memberDTO, bindingResult)) {
            return "member/login"; // [실행 흐름] 검증 실패 → 로그인 페이지로 이동
        }
        memberService.create(memberDTO);
        return "redirect:/";
    }

    /** ============================================================
     * GET /member/read → 마이페이지.
     *
     * [실행 흐름]
     * 1. 세션에서 로그인 정보 확인 → 없으면 로그인 페이지로 리다이렉트
     * 2. DB에서 최신 회원 정보 조회 → model에 담아 JSP로 전달
     * 3. 프로필 사진 정보 조회
     * 4. 총 자산(주식+코인) 계산 → ${totalAsset}으로 JSP에서 사용
     * ============================================================ */
    @GetMapping("read")
    public String read(HttpSession session, Model model) throws Exception {
        MemberDTO user = (MemberDTO) session.getAttribute("member");
        if (user == null) {
            return "redirect:/member/login"; // [실행 흐름] 비로그인 → 로그인 페이지
        }

        model.addAttribute("dto", memberService.read(user));
        model.addAttribute("profile", profileService.getProfile(user.getUsername()));

        // [실행 흐름] 주식 예수금 + 보유 주식 평가금 + 코인 평가금을 합산한 총 자산
        long totalAsset = assetService.calculateTotalAsset(user);
        model.addAttribute("totalAsset", totalAsset);

        return "member/read";
    }

    /** ============================================================
     * GET /member/update → 정보 수정 폼 페이지.
     * 세션의 회원 정보를 읽어 model에 담아 폼을 채워준다.
     * ============================================================ */
    @GetMapping("update")
    public String updateForm(HttpSession session, Model model) throws Exception {
        MemberDTO user = (MemberDTO) session.getAttribute("member");
        if (user == null) return "redirect:/member/login";
        model.addAttribute("dto", memberService.read(user));
        return "member/update";
    }

    /** ============================================================
     * POST /member/update → 정보 수정 처리.
     * 수정 후 마이페이지("/member/read")로 리다이렉트.
     * ============================================================ */
    @PostMapping("update")
    public String update(MemberDTO memberDTO, HttpSession session) throws Exception {
        memberService.update(memberDTO);
        return "redirect:/member/read";
    }

    /** ============================================================
     * GET /member/delete → 회원 탈퇴 처리.
     * DB에서 삭제 후 session.invalidate()로 세션을 즉시 만료시킨다.
     * ============================================================ */
    @GetMapping("delete")
    public String delete(MemberDTO memberDTO, HttpSession session) throws Exception {
        memberService.delete(memberDTO);
        session.invalidate(); // [실행 흐름] 세션 전체 삭제 → 자동 로그아웃
        return "redirect:/";
    }

    /** ============================================================
     * GET /member/login → 로그인 폼 페이지.
     *
     * @param redirect 로그인 성공 후 돌아갈 URL. 없으면 "/"로 기본 설정.
     *                 예) /member/login?redirect=/asset → 로그인 후 /asset으로 이동
     * ============================================================ */
    @GetMapping("login")
    public String login(@RequestParam(value = "redirect", required = false) String redirect, Model model) throws Exception {
        model.addAttribute("redirect", redirect != null ? redirect : "/");
        return "member/login";
    }

    /** ============================================================
     * POST /member/login → 로그인 처리.
     *
     * [실행 흐름]
     * 1. username으로 DB 조회 → MemberDTO 반환 (비밀번호 포함)
     * 2. 입력한 비밀번호와 DB 비밀번호를 직접 비교 (평문 비교 — 암호화 미적용)
     * 3. 일치하면 session에 "member" 저장 + 프로필 파일명도 session에 저장
     * 4. 성공 → redirect 파라미터 경로로 이동 / 실패 → 로그인 페이지 재표시
     * ============================================================ */
    @PostMapping("login")
    public String login(MemberDTO memberDTO, HttpSession session,
                        @RequestParam(value = "redirect", required = false, defaultValue = "/") String redirect) throws Exception {
        MemberDTO result = memberService.read(memberDTO);

        if (result != null && result.getPassword().equals(memberDTO.getPassword())) {
            // [실행 흐름] 로그인 성공 → 세션에 회원 정보 저장
            session.setAttribute("member", result);

            // [실행 흐름] 프로필 사진 파일명도 세션에 저장 (nav.jsp에서 아바타 표시에 사용)
            ProfileDTO profile = profileService.getProfile(result.getUsername());
            session.setAttribute("profileFileName", profile != null ? profile.getFileName() : null);

            return "redirect:" + redirect;
        } else {
            return "member/login"; // [실행 흐름] 로그인 실패 → 폼 재표시
        }
    }

    /** ============================================================
     * POST /member/profile → 프로필 사진 업로드 (AJAX 요청).
     *
     * @ResponseBody → 반환값을 뷰가 아닌 HTTP 응답 바디로 직접 출력한다 (JSON/문자열).
     * ResponseEntity → 상태 코드(200/401/500)와 바디를 함께 제어할 수 있다.
     *
     * [실행 흐름]
     * 1. 세션 확인 → 비로그인이면 401 반환
     * 2. 파일 저장 → session의 profileFileName 갱신
     * 3. 성공 → 200 + 파일명 반환 / 실패 → 500 반환
     * ============================================================ */
    @PostMapping("profile")
    @ResponseBody
    public ResponseEntity<?> uploadProfile(@RequestParam("file") MultipartFile file, HttpSession session) {
        MemberDTO user = (MemberDTO) session.getAttribute("member");
        if (user == null) return ResponseEntity.status(401).build();
        try {
            profileService.saveProfile(user.getUsername(), file);
            ProfileDTO profile = profileService.getProfile(user.getUsername());
            session.setAttribute("profileFileName", profile.getFileName()); // nav 아바타 즉시 반영
            return ResponseEntity.ok(profile.getFileName());
        } catch (Exception e) {
            return ResponseEntity.status(500).body("업로드 실패");
        }
    }

    /** ============================================================
     * GET /member/logout → 로그아웃.
     * session.invalidate()로 세션 전체를 삭제하고 redirect 경로로 이동한다.
     * ============================================================ */
    @GetMapping("logout")
    public String logout(HttpSession session,
                         @RequestParam(value = "redirect", required = false, defaultValue = "/") String redirect) {
        session.invalidate();
        return "redirect:" + redirect;
    }
}