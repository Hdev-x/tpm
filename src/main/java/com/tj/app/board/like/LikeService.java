package com.tj.app.board.like;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class LikeService {

	@Autowired
	private LikeMapper likeMapper;
	
	public int toggleLike(LikeDTO likeDTO) throws Exception {
        // 1. 먼저 이 유저가 좋아요를 눌렀는지 확인
        LikeDTO result = likeMapper.checkLike(likeDTO);
        
        if (result == null) {
            // 2. 누른 적이 없다면 -> 좋아요 생성
            return likeMapper.create(likeDTO); // 성공 시 1 리턴
        } else {
            // 3. 이미 눌렀다면 -> 좋아요 삭제 (취소)
            likeMapper.delete(likeDTO);
            return 0; // 취소됐다는 의미로 0 리턴 (컨트롤러와 약속)
        }
    }
    
	// 2. 페이지 로딩 시 (사용자가 눌렀는지 확인)
    public LikeDTO checkLike(LikeDTO likeDTO) throws Exception {
        return likeMapper.checkLike(likeDTO);
    }

    // 3. 페이지 로딩 시 (전체 좋아요 개수 확인)
    public Long getCount(LikeDTO likeDTO) throws Exception {
        return likeMapper.countLike(likeDTO);
    }
}
