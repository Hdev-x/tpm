package com.tj.app.notice;

import java.time.LocalDateTime;
import java.util.List;

import com.tj.app.common.file.FileDTO;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

/** ============================================================
 * [클래스 읽기] 공지사항 한 건을 담는 DTO.
 *
 * NOTICE 테이블과 1:1 대응한다.
 * BoardDTO와 구조가 거의 동일하지만 별도 테이블·기능으로 분리되어 있다.
 *
 * [BoardDTO와의 차이]
 *   board: 일반 사용자가 작성하는 자유 게시판 (좋아요·댓글 있음)
 *   notice: 관리자가 작성하는 공지사항 (좋아요·댓글 없음)
 *
 * [Lombok]
 *   @Getter/@Setter/@ToString : 접근자·문자열 변환 메서드를 자동 생성한다.
 *
 * [list 필드]
 *   NOTICE_FILES 테이블의 첨부 파일 목록. DB 컬럼이 아니며
 *   NoticeMapper.detailFile()로 별도 조회해 NoticeService.detail()에서 채운다.
 * ============================================================ */
@Getter
@Setter
@ToString
public class NoticeDTO {

	private Long noticeNo;            // 공지사항 고유 번호 (PK)
	private String noticeTitle;       // 제목
	private String noticeWriter;      // 작성자명 (화면 표시용)
	private String noticeContent;     // 본문
	private LocalDateTime noticeDate; // 작성 일시
	private Long noticeView;          // 조회수
	private String username;          // 작성자 로그인 아이디 (소유권 확인용 FK)

	/** 첨부 파일 목록 (DB 컬럼 아님 — 상세 조회 시에만 채워진다) */
	private List<FileDTO> list;
}
