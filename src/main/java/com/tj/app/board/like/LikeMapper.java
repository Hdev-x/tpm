package com.tj.app.board.like;

import org.apache.ibatis.annotations.Mapper;

/** ============================================================
 * [클래스 읽기] 게시글 좋아요(BOARD_LIKES) DB 작업을 담당하는 MyBatis Mapper.
 *
 * SQL은 LikeMapper.xml에 정의되어 있다.
 *
 * [좋아요 토글 흐름]
 *   1. checkLike() → null이면 좋아요 없음 → create()
 *   2. checkLike() → LikeDTO 반환이면 이미 좋아요 → delete()
 *   3. countLike() → 변경 후 최신 개수 반환
 *   이 로직은 LikeService.toggleLike()에 구현되어 있다.
 * ============================================================ */
@Mapper
public interface LikeMapper {

	/** ============================================================
	 * 좋아요를 삽입한다 (좋아요 추가).
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int create(LikeDTO likeDTO) throws Exception;

	/** ============================================================
	 * 좋아요를 삭제한다 (좋아요 취소).
	 * SQL WHERE 조건: boardNo + username 모두 일치해야 삭제.
	 * @return 영향받은 행 수 (정상: 1, 없으면: 0)
	 * ============================================================ */
	public int delete(LikeDTO likeDTO) throws Exception;

	/** ============================================================
	 * 특정 사용자가 해당 게시글에 좋아요를 눌렀는지 확인한다.
	 *
	 * [반환값 의미]
	 *   null     → 좋아요 없음 → create()로 추가
	 *   LikeDTO  → 이미 좋아요 눌렀음 → delete()로 취소
	 *
	 * @return 좋아요 정보(LikeDTO), 없으면 null
	 * ============================================================ */
	public LikeDTO checkLike(LikeDTO likeDTO) throws Exception;

	/** ============================================================
	 * 특정 게시글의 전체 좋아요 수를 반환한다.
	 * SQL: SELECT COUNT(*) FROM BOARD_LIKES WHERE BOARD_NO=#{boardNo}
	 *
	 * @return 좋아요 수 (Long: COUNT 결과가 클 수 있으므로)
	 * ============================================================ */
	public Long countLike(LikeDTO likeDTO) throws Exception;
}
