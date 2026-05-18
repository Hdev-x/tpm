package com.tj.app.market.coin;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class CoinCommentController {

    @Autowired
    private CoinCommentService service;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @MessageMapping("/coin/send")
    public void send(CoinCommentDTO dto) throws Exception {
        CoinCommentDTO saved = service.save(dto);
        messagingTemplate.convertAndSend("/topic/coin/" + saved.getSymbol(), saved);
    }

    @GetMapping("/coin/comments/{symbol}")
    @ResponseBody
    public List<CoinCommentDTO> list(@PathVariable("symbol") String symbol) throws Exception {
        return service.listBySymbol(symbol);
    }
}
