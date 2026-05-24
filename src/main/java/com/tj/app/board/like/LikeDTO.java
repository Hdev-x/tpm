package com.tj.app.board.like;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

/** ============================================================
 * [클래스 읽기] 게시글 좋아요(Like) 한 건을 담는 DTO.
 *
 * BOARD_LIKES 테이블과 1:1 대응한다.
 * "누가(username) 어떤 게시글(boardNo)에 좋아요를 눌렀는가"를 기록하는
 * 다대다 관계의 중간 테이블 DTO이다.
 *
 * [사용 패턴]
 *   조회·확인: likeNo 없이 boardNo + username으로 조회
 *   토글:     checkLike()로 존재 확인 → null이면 create(), 있으면 delete()
 *   개수:     countLike()에서 boardNo로 COUNT(*)
 *
 * [@Getter @Setter @ToString]
 *   필드 접근자와 문자열 변환 메서드를 Lombok이 자동 생성한다.
 * ============================================================ */
@Getter
@Setter
@ToString
public class LikeDTO {

	private Long likeNo;    // 좋아요 고유 번호 (PK, AUTO INCREMENT)
	private String username; // 좋아요를 누른 사용자 아이디 (FK → MEMBER.USERNAME)
	private Long boardNo;    // 어떤 게시글에 눌렀는지 (FK → BOARD.BOARD_NO)
}
