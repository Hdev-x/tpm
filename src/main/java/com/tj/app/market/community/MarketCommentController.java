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

@Controller
public class MarketCommentController {

    @Autowired
    private MarketCommentService service;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private ProfileService profileService;

    @Autowired
    private FileManager fileManager;

    @Value("${app.upload.base}")
    private String uploadBase;

    private void broadcast(MarketCommentDTO dto) {
        messagingTemplate.convertAndSend(
            "/topic/market/" + dto.getMarketType() + "/" + dto.getMarketCode(), dto);
    }

    @PostMapping("/api/market/comment")
    @ResponseBody
    public ResponseEntity<?> create(
            @RequestParam("marketType") String marketType,
            @RequestParam("marketCode") String marketCode,
            @RequestParam("content") String content,
            @RequestParam(value = "file", required = false) MultipartFile file,
            HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.status(401).body("로그인이 필요합니다");

        MarketCommentDTO dto = new MarketCommentDTO();
        dto.setMarketType(marketType.toUpperCase());
        dto.setMarketCode(marketCode);
        dto.setContent(content);

        if (file != null && !file.isEmpty()) {
            String fileName = fileManager.fileSave(uploadBase + "comment", file);
            dto.setImageUrl("/files/comment/" + fileName);
        }

        MarketCommentDTO saved = service.save(dto, member.getUsername());
        ProfileDTO profile = profileService.getProfile(member.getUsername());
        if (profile != null) saved.setProfileFileName(profile.getFileName());
        broadcast(saved);
        return ResponseEntity.ok(saved);
    }

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

        if (file != null && !file.isEmpty()) {
            String fileName = fileManager.fileSave(uploadBase + "comment", file);
            dto.setImageUrl("/files/comment/" + fileName);
        } else if (removeImage) {
            dto.setImageUrl("");
        }

        MarketCommentDTO updated = service.update(dto, member.getUsername());
        broadcast(updated);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/api/market/comment/{commentNo}")
    @ResponseBody
    public ResponseEntity<?> delete(
            @PathVariable("commentNo") Long commentNo,
            @RequestParam("marketType") String marketType,
            @RequestParam("marketCode") String marketCode,
            HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.status(401).body("로그인이 필요합니다");
        service.delete(commentNo, member.getUsername());
        MarketCommentDTO broadcast = new MarketCommentDTO();
        broadcast.setCommentNo(commentNo);
        broadcast.setMarketType(marketType.toUpperCase());
        broadcast.setMarketCode(marketCode);
        broadcast.setType("DELETE");
        broadcast(broadcast);
        return ResponseEntity.ok(Map.of("deleted", true));
    }

    @GetMapping("/market/comments/{marketType}/{marketCode}")
    @ResponseBody
    public List<MarketCommentDTO> list(
            @PathVariable("marketType") String marketType,
            @PathVariable("marketCode") String marketCode,
            @RequestParam(value = "sort", defaultValue = "latest") String sort,
            HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        String username = member != null ? member.getUsername() : null;
        return service.listByCode(marketType.toUpperCase(), marketCode, sort, username);
    }

    @PostMapping("/api/market/comment/{commentNo}/like")
    @ResponseBody
    public ResponseEntity<?> toggleLike(
            @PathVariable("commentNo") Long commentNo,
            HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.status(401).body("로그인이 필요합니다");
        return ResponseEntity.ok(service.toggleLike(commentNo, member.getUsername()));
    }
}
