package com.tj.app.market.exchange;

import com.tj.app.member.MemberDTO;
import jakarta.servlet.http.HttpSession;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/exchange")
public class ExchangeController {

    @Autowired
    private ExchangeService exchangeService;

    /** KRW → USDT */
    @PostMapping("/krw-to-usdt")
    public ResponseEntity<?> krwToUsdt(
            @RequestParam("krwAmount") long krwAmount,
            @RequestParam("rate") double rate,
            HttpSession session) {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.status(401).body(Map.of("success", false, "message", "로그인이 필요합니다."));

        try {
            exchangeService.krwToUsdt(member.getUsername(), krwAmount, rate);
            return ResponseEntity.ok(Map.of("success", true));
        } catch (Exception e) {
            log.warn("환전 실패 [KRW→USDT] {}: {}", member.getUsername(), e.getMessage());
            return ResponseEntity.ok(Map.of("success", false, "message", e.getMessage()));
        }
    }

    /** USDT → KRW */
    @PostMapping("/usdt-to-krw")
    public ResponseEntity<?> usdtToKrw(
            @RequestParam("usdtAmount") double usdtAmount,
            @RequestParam("rate") double rate,
            HttpSession session) {
        MemberDTO member = (MemberDTO) session.getAttribute("member");
        if (member == null) return ResponseEntity.status(401).body(Map.of("success", false, "message", "로그인이 필요합니다."));

        try {
            exchangeService.usdtToKrw(member.getUsername(), usdtAmount, rate);
            return ResponseEntity.ok(Map.of("success", true));
        } catch (Exception e) {
            log.warn("환전 실패 [USDT→KRW] {}: {}", member.getUsername(), e.getMessage());
            return ResponseEntity.ok(Map.of("success", false, "message", e.getMessage()));
        }
    }
}
