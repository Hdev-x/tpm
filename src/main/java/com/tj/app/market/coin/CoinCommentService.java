package com.tj.app.market.coin;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class CoinCommentService {

    @Autowired
    private CoinCommentMapper mapper;

    @Autowired
    private CoinCommentLikeMapper likeMapper;

    public CoinCommentDTO save(CoinCommentDTO dto, String username) throws Exception {
        dto.setUsername(username);
        mapper.insert(dto);
        dto.setType("NEW");
        return dto;
    }

    public CoinCommentDTO update(CoinCommentDTO dto, String username) throws Exception {
        dto.setUsername(username);
        mapper.update(dto);
        dto.setType("UPDATE");
        return dto;
    }

    public void delete(Long commentNo, String symbol, String username) throws Exception {
        mapper.delete(commentNo, username);
    }

    public List<CoinCommentDTO> listBySymbol(String symbol, String sort, String username) throws Exception {
        List<CoinCommentDTO> list = "popular".equals(sort)
                ? mapper.listBySymbolPopular(symbol)
                : mapper.listBySymbol(symbol);
        if (username != null && !username.isEmpty()) {
            for (CoinCommentDTO dto : list) {
                dto.setLikedByMe(likeMapper.check(dto.getCommentNo(), username) > 0);
            }
        }
        return list;
    }

    public Map<String, Object> toggleLike(Long commentNo, String username) throws Exception {
        boolean liked;
        if (likeMapper.check(commentNo, username) > 0) {
            likeMapper.delete(commentNo, username);
            liked = false;
        } else {
            likeMapper.insert(commentNo, username);
            liked = true;
        }
        long count = likeMapper.count(commentNo);
        return Map.of("liked", liked, "count", count);
    }
}
