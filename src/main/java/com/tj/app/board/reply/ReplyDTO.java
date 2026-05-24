package com.tj.app.board.reply;

import java.time.LocalDateTime;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

/** ============================================================
 * [클래스 읽기] 게시글 댓글(Reply) 한 건을 담는 DTO.
 *
 * BOARD_REPLIES 테이블과 1:1 대응한다.
 * 댓글은 특정 게시글(boardNo)에 종속된다.
 *
 * [@Getter @Setter @ToString]
 *   Lombok이 접근자와 문자열 변환 메서드를 자동 생성한다.
 *
 * [MarketCommentDTO와의 차이]
 *   MarketCommentDTO : 코인·주식 종목별 실시간 WebSocket 댓글 (STOMP 브로드캐스트)
 *   ReplyDTO         : 자유 게시판 댓글 (일반 HTTP POST, 실시간 아님)
 * ============================================================ */
@Getter
@Setter
@ToString
public class ReplyDTO {

	private Long replyNo;              // 댓글 고유 번호 (PK)
	private String replyContent;       // 댓글 내용
	private LocalDateTime replyDate;   // 작성 일시
	private String username;           // 작성자 아이디 (FK → MEMBER.USERNAME)
	private Long boardNo;              // 어떤 게시글의 댓글인지 (FK → BOARD.BOARD_NO)
}
