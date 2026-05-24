package com.tj.app.market.community;

import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/** ============================================================
 * [클래스 읽기] 커뮤니티 댓글(MARKET_COMMENTS) DB 작업을 담당하는 MyBatis Mapper.
 *
 * SQL은 MarketCommentMapper.xml에 정의되어 있다.
 *
 * [관련 테이블]
 *   MARKET_COMMENTS      : 댓글 본문 (commentNo, marketType, marketCode, content, username, ...)
 *   MARKET_COMMENT_LIKES : 좋아요 집계를 위한 JOIN 대상 (likeCount는 여기서 COUNT)
 *
 * [int 반환] insert/update/delete는 영향받은 행 수(affected rows)를 반환한다.
 *   0이면 해당 행이 없거나 조건 불일치, 1이면 정상 처리.
 *
 * [보안 패턴] delete()에 username을 같이 전달하는 이유:
 *   SQL WHERE 절에 "AND USERNAME = #{username}" 조건을 추가해
 *   본인 댓글만 삭제할 수 있도록 DB 레벨에서 소유권을 검증한다.
 * ============================================================ */
@Mapper
public interface MarketCommentMapper {

    /** ============================================================
     * 댓글 삽입. 삽입 후 MyBatis가 자동 생성된 PK(commentNo)를 dto에 채워준다.
     * (XML에서 useGeneratedKeys="true" keyProperty="commentNo" 설정 필요)
     * @return 영향받은 행 수 (정상: 1)
     * ============================================================ */
    int insert(MarketCommentDTO dto) throws Exception;

    /** ============================================================
     * 특정 종목·마켓의 댓글 목록 조회 (최신순).
     * SQL 정렬: ORDER BY CREATED_AT DESC
     *
     * [@Param] 파라미터가 2개 이상이면 @Param으로 이름을 명시해야 MyBatis XML에서 #{name}으로 참조 가능.
     * ============================================================ */
    List<MarketCommentDTO> listByCode(@Param("marketType") String marketType,
                                      @Param("marketCode") String marketCode) throws Exception;

    /** ============================================================
     * 특정 종목·마켓의 댓글 목록 조회 (인기순).
     * SQL 정렬: ORDER BY 좋아요수 DESC → CREATED_AT DESC (좋아요 수가 같으면 최신 우선)
     * MarketCommentService.listByCode()에서 sort="popular"일 때 호출한다.
     * ============================================================ */
    List<MarketCommentDTO> listByCodePopular(@Param("marketType") String marketType,
                                              @Param("marketCode") String marketCode) throws Exception;

    /** ============================================================
     * 댓글 내용 수정.
     * SQL WHERE 절에 commentNo + username 조건이 있어 본인 댓글만 수정된다.
     * @return 영향받은 행 수 (정상: 1)
     * ============================================================ */
    int update(MarketCommentDTO dto) throws Exception;

    /** ============================================================
     * 댓글 삭제.
     * username 조건으로 본인 댓글만 삭제 가능 (DB 레벨 소유권 검증).
     *
     * @param commentNo 삭제할 댓글 번호
     * @param username  삭제 요청한 사용자 아이디 (본인 확인용)
     * @return 영향받은 행 수 (정상: 1, 타인 댓글이면: 0)
     * ============================================================ */
    int delete(@Param("commentNo") Long commentNo, @Param("username") String username) throws Exception;
}
