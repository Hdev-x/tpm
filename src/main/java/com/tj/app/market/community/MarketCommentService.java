package com.tj.app.market.community;

import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class MarketCommentService {

    @Autowired
    private MarketCommentMapper mapper;

    @Autowired
    private MarketCommentLikeMapper likeMapper;

    public MarketCommentDTO save(MarketCommentDTO dto, String username) throws Exception {
        dto.setUsername(username);
        mapper.insert(dto);
        dto.setType("NEW");
        return dto;
    }

    public MarketCommentDTO update(MarketCommentDTO dto, String username) throws Exception {
        dto.setUsername(username);
        mapper.update(dto);
        dto.setType("UPDATE");
        return dto;
    }

    public void delete(Long commentNo, String username) throws Exception {
        mapper.delete(commentNo, username);
    }

    public List<MarketCommentDTO> listByCode(String marketType, String marketCode, String sort, String username) throws Exception {
        List<MarketCommentDTO> list = "popular".equals(sort)
                ? mapper.listByCodePopular(marketType, marketCode)
                : mapper.listByCode(marketType, marketCode);
        if (username != null && !username.isEmpty()) {
            for (MarketCommentDTO dto : list) {
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
