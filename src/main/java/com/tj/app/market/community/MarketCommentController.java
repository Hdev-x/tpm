package com.tj.app.market.community;

import java.util.List;
import java.util.Map;

import com.tj.app.common.file.FileManager;
import com.tj.app.member.MemberDTO;
import com.tj.app.member.ProfileDTO;
import com.tj.app.member.ProfileService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/** ============================================================
 * [클래스 읽기] 커뮤니티 댓글 CRUD + 좋아요 토글을 처리하는 컨트롤러.
 *
 * [@Controller + @ResponseBody 개별 지정]
 *   클래스에는 @Controller를 두고 각 메서드에 @ResponseBody를 붙이는 혼합 방식이다.
 *   → 이 프로젝트에서는 댓글 전용이라 JSP 뷰 없이 항상 JSON을 반환하므로
 *     @RestController로 통일해도 동일하다.
 *
 * [SimpMessagingTemplate messagingTemplate]
 *   Spring STOMP WebSocket의 브로드캐스트 전송 도구.
 *   convertAndSend(destination, payload)를 호출하면
 *   해당 토픽을 구독 중인 모든 클라이언트에 payload(JSON)가 동시에 전달된다.
 *   → 댓글 작성·수정·삭제 직후 실시간으로 다른 사용자 화면에 반영된다.
 *
 * [ProfileService]
 *   댓글 저장 후 작성자의 프로필 이미지 파일명을 조회해 DTO에 추가한다.
 *   브로드캐스트 시 상대방 화면에서도 프로필 이미지가 표시되도록 하기 위함이다.
 *
 * [FileManager]
 *   댓글 첨부 이미지를 서버에 저장하는 공통 유틸 클래스.
 *   fileSave()가 저장된 파일명을 반환한다.
 *
 * [@Value("${app.upload.base}")]
 *   application.properties의 업로드 기본 경로를 주입받는다.
 *   댓글 이미지는 uploadBase + "comment/" 디렉터리에 저장된다.
 *
 * [브로드캐스트 토픽 구조]
 *   /topic/market/{marketType}/{marketCode}
 *   예: /topic/market/COIN/BTCUSDT, /topic/market/STOCK/005930
 *   JS에서 이 토픽을 구독하면 해당 종목 댓글의 실시간 변경을 받는다.
 * ============================================================ */
@Controller
public class MarketCommentController {

    @Autowired
    private MarketCommentService service;

    /** STOMP WebSocket 브로드캐스트 전송 도구 */
    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    /** 작성자 프로필 이미지 조회용 서비스 */
    @Autowired
    private ProfileService profileService;

    /** 첨부 이미지 파일 저장 유틸 */
    @Autowired
    private FileManager fileManager;

    /** 업로드 기본 경로 (application.properties: app.upload.base) */
    @Value("${app.upload.base}")
    private String uploadBase;

    /** ============================================================
     * [내부 헬퍼] 댓글 DTO를 WebSocket 토픽으로 브로드캐스트한다.
     *
     * [토픽 경로] /topic/market/{COIN or STOCK}/{종목코드}
     *   → 같은 종목 페이지를 보고 있는 모든 클라이언트에게 dto가 전달된다.
     *   → JS에서 dto.type("NEW"/"UPDATE"/"DELETE")으로 UI를 갱신한다.
     * ============================================================ */
    private void broadcast(MarketCommentDTO dto) {
        messagingTemplate.convertAndSend(
            "/topic/market/" + dto.getMarketType() + "/" + dto.getMarketCode(), dto);
    }

    /** ============================================================
     * [메서드 읽기] 새 댓글을 등록한다. POST /api/market/comment
     *
     * [실행 흐름]
     * 1. 세션에서 MemberDTO 확인 → null이면 401 Unauthorized 반환
     * 2. MarketCommentDTO 생성 후 파라미터 세팅
     *    - marketType을 대문자로 통일 ("coin" → "COIN")
     * 3. 이미지 파일이 있으면 서버에 저장 → imageUrl 설정
     * 4. service.save() → DB INSERT + type="NEW" 설정
     * 5. 작성자 프로필 이미지 조회 → dto에 추가
     * 6. broadcast(dto) → 같은 종목 구독자들에게 실시간 전파
     * 7. ResponseEntity.ok(dto) → 작성자 자신에게도 저장된 댓글 반환
     *
     * [@RequestParam vs @RequestBody]
     *   파일 업로드(MultipartFile)가 포함된 요청은 multipart/form-data 형식이다.
     *   @RequestBody(JSON)가 아닌 @RequestParam으로 각 필드를 따로 받아야 한다.
     *
     * [ResponseEntity<?>]
     *   ? 와일드카드: 성공 시 MarketCommentDTO, 실패 시 String을 반환하는 유연한 타입.
     *   HTTP 상태 코드(200, 401 등)를 함께 담아 반환할 수 있다.
     * ============================================================ */
    @PostMapping("/api/market/comment")
    @ResponseBody
    public ResponseEntity<?> create(
            @RequestParam("marketType") String marketType,
            @RequestParam("marketCode") String marketCode,
            @RequestParam("content") String content,
            @RequestParam(value = "file", required = false) MultipartFile file, // 첨부 이미지 (선택)
            HttpSession session) throws Exception {

        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.status(401).body("로그인이 필요합니다"); // [실행 흐름] 비로그인 → 401

        // [실행 흐름] 댓글 DTO 구성
        MarketCommentDTO dto = new MarketCommentDTO();
        dto.setMarketType(marketType.toUpperCase()); // 대문자 통일 ("coin" → "COIN")
        dto.setMarketCode(marketCode);
        dto.setContent(content);

        // [실행 흐름] 이미지 파일이 첨부됐으면 서버 저장 후 URL 설정
        if (file != null && !file.isEmpty()) {
            String fileName = fileManager.fileSave(uploadBase + "comment", file);
            dto.setImageUrl("/files/comment/" + fileName); // 브라우저에서 접근 가능한 URL 경로
        }

        MarketCommentDTO saved = service.save(dto, member.getUsername()); // [실행 흐름] DB INSERT

        // [실행 흐름] 프로필 이미지 조회 → 브로드캐스트 시 상대방 화면에 표시
        ProfileDTO profile = profileService.getProfile(member.getUsername());
        if (profile != null) saved.setProfileFileName(profile.getFileName());

        broadcast(saved); // [실행 흐름] 같은 종목 구독자들에게 WebSocket 전파 (type="NEW")
        return ResponseEntity.ok(saved); // [실행 흐름] 작성자에게 저장된 댓글 반환
    }

    /** ============================================================
     * [메서드 읽기] 기존 댓글을 수정한다. PUT /api/market/comment/{commentNo}
     *
     * [@PathVariable] URL 경로의 {commentNo}를 Long 파라미터로 받는다.
     *   예: PUT /api/market/comment/42 → commentNo=42
     *
     * [이미지 처리 3가지 경우]
     *   a. 새 파일 업로드: file != null → 서버 저장 → 새 imageUrl 설정
     *   b. 이미지 삭제 요청: removeImage=true → imageUrl="" (빈 문자열로 제거)
     *   c. 이미지 변경 없음: file도 없고 removeImage도 false → imageUrl 그대로
     *
     * [removeImage=false 기본값] 파라미터 미전송 시 false로 처리.
     * ============================================================ */
    @PutMapping("/api/market/comment/{commentNo}")
    @ResponseBody
    public ResponseEntity<?> update(
            @PathVariable("commentNo") Long commentNo,
            @RequestParam("marketType") String marketType,
            @RequestParam("marketCode") String marketCode,
            @RequestParam("content") String content,
            @RequestParam(value = "file", required = false) MultipartFile file,
            @RequestParam(value = "removeImage", required = false, defaultValue = "false") boolean removeImage,
            HttpSession session) throws Exception {

        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.status(401).body("로그인이 필요합니다");

        MarketCommentDTO dto = new MarketCommentDTO();
        dto.setCommentNo(commentNo);
        dto.setMarketType(marketType.toUpperCase());
        dto.setMarketCode(marketCode);
        dto.setContent(content);

        // [실행 흐름] 이미지 처리 분기
        if (file != null && !file.isEmpty()) {
            // a. 새 파일 → 저장 후 URL 갱신
            String fileName = fileManager.fileSave(uploadBase + "comment", file);
            dto.setImageUrl("/files/comment/" + fileName);
        } else if (removeImage) {
            // b. 이미지 삭제 요청 → 빈 문자열로 설정 (SQL에서 NULL 또는 '' 처리)
            dto.setImageUrl("");
        }
        // c. 변경 없음 → imageUrl 미설정 (SQL에서 기존 값 유지하거나 null 처리)

        MarketCommentDTO updated = service.update(dto, member.getUsername()); // DB UPDATE
        broadcast(updated); // WebSocket 전파 (type="UPDATE")
        return ResponseEntity.ok(updated);
    }

    /** ============================================================
     * [메서드 읽기] 댓글을 삭제한다. DELETE /api/market/comment/{commentNo}
     *
     * [실행 흐름]
     * 1. 세션 확인 → 비로그인 시 401
     * 2. service.delete() → DB DELETE (SQL에 username 조건 포함 → 본인만 삭제)
     * 3. type="DELETE" DTO 생성 → broadcast()로 구독자들에게 삭제 신호 전송
     *    JS는 type="DELETE"를 받아 해당 commentNo의 댓글 요소를 화면에서 제거한다.
     * 4. { "deleted": true } 반환
     *
     * [broadcast용 DTO] 삭제 시에는 content 등이 필요 없고 commentNo·type만 있으면 된다.
     *   최소 정보만 담아 간소화된 DTO를 직접 만들어 전파한다.
     * ============================================================ */
    @DeleteMapping("/api/market/comment/{commentNo}")
    @ResponseBody
    public ResponseEntity<?> delete(
            @PathVariable("commentNo") Long commentNo,
            @RequestParam("marketType") String marketType,
            @RequestParam("marketCode") String marketCode,
            HttpSession session) throws Exception {

        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.status(401).body("로그인이 필요합니다");

        service.delete(commentNo, member.getUsername()); // [실행 흐름] DB DELETE

        // [실행 흐름] 브로드캐스트용 최소 DTO 생성 (commentNo + type="DELETE"만 필요)
        MarketCommentDTO broadcast = new MarketCommentDTO();
        broadcast.setCommentNo(commentNo);
        broadcast.setMarketType(marketType.toUpperCase());
        broadcast.setMarketCode(marketCode);
        broadcast.setType("DELETE");
        broadcast(broadcast); // 구독자들에게 삭제 신호 전파

        return ResponseEntity.ok(Map.of("deleted", true));
    }

    /** ============================================================
     * [메서드 읽기] 특정 종목의 댓글 목록을 조회한다. GET /market/comments/{marketType}/{marketCode}
     *
     * [@PathVariable] URL 경로에서 marketType·marketCode를 바로 받는다.
     *   예: GET /market/comments/COIN/BTCUSDT
     *
     * [비로그인 처리]
     *   member == null이면 username = null로 전달.
     *   service에서 username이 null이면 likedByMe 체크를 건너뛴다 (항상 false).
     *
     * [sort 파라미터] "popular" → 인기순, 그 외 → 최신순 (기본값: "latest")
     * ============================================================ */
    @GetMapping("/market/comments/{marketType}/{marketCode}")
    @ResponseBody
    public List<MarketCommentDTO> list(
            @PathVariable("marketType") String marketType,
            @PathVariable("marketCode") String marketCode,
            @RequestParam(value = "sort", defaultValue = "latest") String sort,
            HttpSession session) throws Exception {

        MemberDTO member = (MemberDTO) session.getAttribute("member");
        // [코드 읽기] 삼항 연산자: 로그인이면 username 전달, 비로그인이면 null 전달
        String username = member != null ? member.getUsername() : null;
        return service.listByCode(marketType.toUpperCase(), marketCode, sort, username);
    }

    /** ============================================================
     * [메서드 읽기] 댓글 좋아요를 토글(추가↔취소)한다. POST /api/market/comment/{commentNo}/like
     *
     * [실행 흐름]
     * 1. 세션 확인 → 비로그인 시 401
     * 2. service.toggleLike() → 좋아요 추가 or 취소 → 최신 카운트 조회
     * 3. { "liked": true/false, "count": N } 반환
     *    JS는 이 값으로 하트 아이콘 색상과 숫자를 즉시 갱신한다.
     *
     * [브로드캐스트 없음] 좋아요는 개인 상태 변경이므로 실시간 전파를 하지 않는다.
     *   (필요하면 추후 broadcast 추가 가능)
     * ============================================================ */
    @PostMapping("/api/market/comment/{commentNo}/like")
    @ResponseBody
    public ResponseEntity<?> toggleLike(
            @PathVariable("commentNo") Long commentNo,
            HttpSession session) throws Exception {

        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.status(401).body("로그인이 필요합니다");

        // [실행 흐름] { liked: true/false, count: N } Map 반환
        return ResponseEntity.ok(service.toggleLike(commentNo, member.getUsername()));
    }
}
