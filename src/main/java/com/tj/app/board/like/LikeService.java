package com.tj.app.board.like;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** ============================================================
 * [클래스 읽기] 게시글 좋아요 토글·조회 비즈니스 로직을 담당하는 서비스.
 *
 * [@Transactional 클래스 레벨]
 *   모든 public 메서드가 트랜잭션 안에서 실행된다.
 *   toggleLike()에서 checkLike → delete/create 두 DB 작업이 하나의 트랜잭션으로 묶인다.
 *   중간에 예외 발생 시 모두 롤백된다.
 * ============================================================ */
@Service
@Transactional
public class LikeService {

	@Autowired
	private LikeMapper likeMapper;

	/** ============================================================
	 * 좋아요를 토글한다 (없으면 추가, 있으면 취소).
	 *
	 * [실행 흐름]
	 * 1. checkLike() → null이면 좋아요 없음 → create() → 1 반환 (좋아요 추가됨)
	 * 2. checkLike() → LikeDTO 반환이면 이미 좋아요 → delete() → 0 반환 (취소됨)
	 *
	 * [반환값 약속 (Controller와 JS 간 약속)]
	 *   1  → 좋아요 추가됨 (JS에서 하트 활성화)
	 *   0  → 좋아요 취소됨 (JS에서 하트 비활성화)
	 *  -1  → 비로그인 (Controller에서 반환, LikeService 도달 전에 처리)
	 *
	 * @return 1(추가) 또는 0(취소)
	 * ============================================================ */
	public int toggleLike(LikeDTO likeDTO) throws Exception {
        LikeDTO result = likeMapper.checkLike(likeDTO); // [실행 흐름] 좋아요 여부 확인

        if (result == null) {
            // [실행 흐름] 좋아요 없음 → 추가
            return likeMapper.create(likeDTO); // 성공 시 1 반환
        } else {
            // [실행 흐름] 이미 좋아요 → 취소
            likeMapper.delete(likeDTO);
            return 0; // 취소됐다는 의미 (Controller와의 약속: 0 = 취소)
        }
    }

	/** ============================================================
	 * 현재 로그인한 사용자가 해당 게시글에 좋아요를 눌렀는지 확인한다.
	 * BoardController.detail()에서 페이지 로딩 시 호출한다.
	 * JSP에서 myLike != null이면 이미 좋아요를 누른 것으로 처리한다.
	 *
	 * @return LikeDTO (좋아요 있음) 또는 null (좋아요 없음)
	 * ============================================================ */
    public LikeDTO checkLike(LikeDTO likeDTO) throws Exception {
        return likeMapper.checkLike(likeDTO);
    }

	/** ============================================================
	 * 특정 게시글의 전체 좋아요 수를 반환한다.
	 * BoardController.detail()에서 비로그인 포함 모든 사용자에게 표시하기 위해 호출한다.
	 *
	 * @return 좋아요 수 (Long)
	 * ============================================================ */
    public Long getCount(LikeDTO likeDTO) throws Exception {
        return likeMapper.countLike(likeDTO);
    }
}
