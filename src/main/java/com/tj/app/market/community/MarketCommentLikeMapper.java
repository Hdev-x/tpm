package com.tj.app.market.community;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/** ============================================================
 * [클래스 읽기] 댓글 좋아요(MARKET_COMMENT_LIKES) DB 작업을 담당하는 MyBatis Mapper.
 *
 * [관련 테이블] MARKET_COMMENT_LIKES (commentNo + username 복합 UNIQUE 제약)
 *
 * [좋아요 토글 흐름]
 *   1. check() → 이미 좋아요가 있으면 delete() (좋아요 취소)
 *                없으면 insert() (좋아요 추가)
 *   2. count() → 최신 좋아요 수를 다시 조회해 클라이언트에 반환
 *   이 로직은 MarketCommentService.toggleLike()에 구현되어 있다.
 * ============================================================ */
@Mapper
public interface MarketCommentLikeMapper {

    /** ============================================================
     * 좋아요 삽입 (commentNo + username 조합으로 INSERT).
     * DB에 UNIQUE 제약이 있으므로 중복 insert 시 오류가 발생한다.
     * 반드시 check()로 확인 후 호출해야 한다.
     * @return 영향받은 행 수 (정상: 1)
     * ============================================================ */
    int insert(@Param("commentNo") Long commentNo, @Param("username") String username);

    /** ============================================================
     * 좋아요 삭제 (좋아요 취소).
     * @return 영향받은 행 수 (정상: 1, 좋아요가 없었으면: 0)
     * ============================================================ */
    int delete(@Param("commentNo") Long commentNo, @Param("username") String username);

    /** ============================================================
     * 특정 사용자가 해당 댓글에 좋아요를 눌렀는지 확인한다.
     * SQL: SELECT COUNT(*) WHERE COMMENT_NO=#{commentNo} AND USERNAME=#{username}
     *
     * [사용 패턴]
     *   check() > 0 → 이미 좋아요 눌렀음 → delete()
     *   check() == 0 → 좋아요 미등록 → insert()
     *
     * @return 0 (미등록) 또는 1 (등록됨)
     * ============================================================ */
    int check(@Param("commentNo") Long commentNo, @Param("username") String username);

    /** ============================================================
     * 특정 댓글의 전체 좋아요 수를 반환한다.
     * insert/delete 후 최신 카운트를 다시 클라이언트에 내려줄 때 사용한다.
     * @return 좋아요 수 (long: 많아질 수 있으므로 int 대신 long 사용)
     * ============================================================ */
    long count(@Param("commentNo") Long commentNo);
}
