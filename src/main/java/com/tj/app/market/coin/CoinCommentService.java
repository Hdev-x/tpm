package com.tj.app.market.coin;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class CoinCommentService {

    @Autowired
    private CoinCommentMapper mapper;

    public CoinCommentDTO save(CoinCommentDTO dto) throws Exception {
        dto.setUsername("익명");
        mapper.insert(dto);
        return dto;
    }

    public List<CoinCommentDTO> listBySymbol(String symbol) throws Exception {
        return mapper.listBySymbol(symbol);
    }
}
