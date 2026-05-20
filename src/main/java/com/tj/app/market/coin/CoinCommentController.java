package com.tj.app.market.coin;

import java.util.List;
import java.util.Map;

import com.tj.app.file.FileManager;
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
public class CoinCommentController {

    @Autowired
    private CoinCommentService service;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private ProfileService profileService;

    @Autowired
    private FileManager fileManager;

    @Value("${app.upload.base}")
    private String uploadBase;

    @PostMapping("/api/coin/comment")
    @ResponseBody
    public ResponseEntity<?> create(
            @RequestParam("symbol") String symbol,
            @RequestParam("content") String content,
            @RequestParam(value = "file", required = false) MultipartFile file,
            HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.status(401).body("로그인이 필요합니다");

        CoinCommentDTO dto = new CoinCommentDTO();
        dto.setSymbol(symbol);
        dto.setContent(content);

        if (file != null && !file.isEmpty()) {
            String fileName = fileManager.fileSave(uploadBase + "comment", file);
            dto.setImageUrl("/files/comment/" + fileName);
        }

        CoinCommentDTO saved = service.save(dto, member.getUsername());
        ProfileDTO profile = profileService.getProfile(member.getUsername());
        if (profile != null) saved.setProfileFileName(profile.getFileName());
        messagingTemplate.convertAndSend("/topic/coin/" + saved.getSymbol(), saved);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/api/coin/comment/{commentNo}")
    @ResponseBody
    public ResponseEntity<?> update(
            @PathVariable("commentNo") Long commentNo,
            @RequestParam("symbol") String symbol,
            @RequestParam("content") String content,
            @RequestParam(value = "file", required = false) MultipartFile file,
            @RequestParam(value = "removeImage", required = false, defaultValue = "false") boolean removeImage,
            HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.status(401).body("로그인이 필요합니다");

        CoinCommentDTO dto = new CoinCommentDTO();
        dto.setCommentNo(commentNo);
        dto.setSymbol(symbol);
        dto.setContent(content);

        if (file != null && !file.isEmpty()) {
            String fileName = fileManager.fileSave(uploadBase + "comment", file);
            dto.setImageUrl("/files/comment/" + fileName);
        } else if (removeImage) {
            dto.setImageUrl("");
        }

        CoinCommentDTO updated = service.update(dto, member.getUsername());
        messagingTemplate.convertAndSend("/topic/coin/" + updated.getSymbol(), updated);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/api/coin/comment/{commentNo}")
    @ResponseBody
    public ResponseEntity<?> delete(@PathVariable("commentNo") Long commentNo, @RequestParam("symbol") String symbol, HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.status(401).body("로그인이 필요합니다");
        service.delete(commentNo, symbol, member.getUsername());
        CoinCommentDTO broadcast = new CoinCommentDTO();
        broadcast.setCommentNo(commentNo);
        broadcast.setSymbol(symbol);
        broadcast.setType("DELETE");
        messagingTemplate.convertAndSend("/topic/coin/" + symbol, broadcast);
        return ResponseEntity.ok(Map.of("deleted", true));
    }

    @GetMapping("/coin/comments/{symbol}")
    @ResponseBody
    public List<CoinCommentDTO> list(
            @PathVariable("symbol") String symbol,
            @RequestParam(value = "sort", defaultValue = "latest") String sort,
            HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        String username = member != null ? member.getUsername() : null;
        return service.listBySymbol(symbol, sort, username);
    }

    @PostMapping("/api/coin/comment/{commentNo}/like")
    @ResponseBody
    public ResponseEntity<?> toggleLike(@PathVariable("commentNo") Long commentNo, HttpSession session) throws Exception {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.status(401).body("로그인이 필요합니다");
        return ResponseEntity.ok(service.toggleLike(commentNo, member.getUsername()));
    }
}
