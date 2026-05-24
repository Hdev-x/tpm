package com.tj.app.board;

import java.time.LocalDateTime;
import java.util.List;

import com.tj.app.common.file.FileDTO;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

/** ============================================================
 * [클래스 읽기] 자유 게시판 게시글 한 건을 담는 DTO.
 *
 * BOARD 테이블과 1:1 대응하며, 파일 목록(list)은 JOIN 또는
 * 별도 쿼리(BoardMapper.detailFile)로 채워진다.
 *
 * [Lombok]
 *   @Getter  : 모든 필드에 getXxx() 자동 생성
 *   @Setter  : 모든 필드에 setXxx() 자동 생성
 *   @ToString: toString() 자동 생성 (디버깅·로그 출력용)
 *
 * [boardWriter vs username]
 *   boardWriter : 화면에 표시되는 작성자명 (게시글 테이블에 저장)
 *   username    : 실제 로그인 아이디 (FK) — 소유권 확인·본인 글 체크에 사용
 *   두 값 모두 Controller에서 세션의 member.getUsername()으로 설정한다.
 * ============================================================ */
@Getter
@Setter
@ToString
public class BoardDTO {

	private Long boardNo;          // 게시글 고유 번호 (PK)
	private String boardTitle;     // 게시글 제목
	private String boardWriter;    // 화면에 표시할 작성자명
	private String boardContent;   // 게시글 본문
	private LocalDateTime boardDate; // 작성 일시 (Java 8 날짜 타입)
	private Long boardView;        // 조회수 (detail() 호출 시 1씩 증가)
	private String username;       // 작성자 로그인 아이디 (소유권 확인용)

	/** 첨부 파일 목록.
	 *  DB 컬럼이 아니라 BoardMapper.detailFile()로 별도 조회해 설정한다.
	 *  게시글 목록(list)에서는 null, 상세(detail) 조회 시에만 채워진다. */
	private List<FileDTO> list;
}
