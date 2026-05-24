package com.tj.app.market.community;

import lombok.Getter;
import lombok.Setter;

/** ============================================================
 * [클래스 읽기] 댓글 좋아요(Like) 한 건을 담는 DTO.
 *
 * MARKET_COMMENT_LIKES 테이블과 1:1 대응한다.
 * 이 테이블은 "누가(username) 어떤 댓글(commentNo)에 좋아요를 눌렀는가"를 기록하는
 * 다대다 관계의 중간 테이블이다.
 *
 * (사용자 1명 : 좋아요 N개, 댓글 1개 : 좋아요 N개)
 *
 * [제약 조건] (commentNo, username) 조합이 UNIQUE → 한 사용자가 같은 댓글에 중복 좋아요 불가.
 *   → MarketCommentLikeMapper.check()로 사전 확인 후 insert/delete를 분기한다.
 *
 * [@Getter @Setter] 필드를 외부에서 읽고 쓸 수 있도록 Lombok이 접근자를 자동 생성한다.
 * ============================================================ */
@Getter
@Setter
public class MarketCommentLikeDTO {

    private Long likeNo;     // 좋아요 고유 번호 (PK, AUTO INCREMENT)
    private Long commentNo;  // 어떤 댓글에 눌렀는지 (FK → MARKET_COMMENTS.COMMENT_NO)
    private String username; // 누가 눌렀는지 (FK → MEMBER.USERNAME)
}
