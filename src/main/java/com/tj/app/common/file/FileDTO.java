package com.tj.app.common.file;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

/** ============================================================
 * [클래스 읽기] 업로드 파일 정보를 담는 공통 DTO.
 *
 * 게시판(board)과 공지사항(notice) 첨부 파일 모두 이 DTO를 공유한다.
 * fileName  : UUID 기반 저장 파일명 (중복 방지)
 * oriName   : 사용자가 올린 원본 파일명 (다운로드 시 이 이름으로 표시)
 * boardNo   : 게시글 첨부 파일일 때 연결되는 게시글 번호
 * noticeNo  : 공지사항 첨부 파일일 때 연결되는 공지사항 번호
 * ============================================================ */
@Setter
@Getter
@ToString
public class FileDTO {
	private Long fileNo;
	private String fileName; // UUID_원본파일명 형태로 저장 (예: a3f2..._report.pdf)
	private String oriName;  // 브라우저에 표시되는 원본 파일명
	private Long boardNo;    // 게시글 첨부 시 FK
	private Long noticeNo;   // 공지사항 첨부 시 FK
}
