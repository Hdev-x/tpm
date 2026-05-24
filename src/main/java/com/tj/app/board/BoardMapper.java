package com.tj.app.board;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;

import com.tj.app.common.file.FileDTO;
import com.tj.app.common.pager.Pager;

/** ============================================================
 * [클래스 읽기] 게시판 게시글·파일 DB 작업을 담당하는 MyBatis Mapper.
 *
 * SQL은 BoardMapper.xml에 정의되어 있다.
 *
 * [관련 테이블]
 *   BOARD       : 게시글 본문 (boardNo, title, content, writer, date, view, username)
 *   BOARD_FILES : 첨부 파일 목록 (fileNo, boardNo, oriName, fileName)
 *
 * [Pager 클래스]
 *   페이지네이션 정보를 담는 공통 VO.
 *   총 게시글 수(getCount)를 기반으로 페이지 수·시작 행 번호를 계산한다.
 *   SQL에서 LIMIT·OFFSET 또는 ROWNUM 범위 지정에 사용된다.
 * ============================================================ */
@Mapper
public interface BoardMapper {

	/** ============================================================
	 * 게시글 총 개수 조회 (페이징 계산 기준).
	 * Pager에 검색 조건(키워드 등)이 있으면 WHERE 절에 반영된다.
	 * @return 조건에 맞는 게시글 수
	 * ============================================================ */
	public Long getCount(Pager page) throws Exception;

	/** ============================================================
	 * 게시글 등록.
	 * MyBatis가 INSERT 후 생성된 PK(boardNo)를 boardDTO에 자동으로 채워준다.
	 * (XML: useGeneratedKeys="true" keyProperty="boardNo" 설정 필요)
	 * 이후 createFile() 호출 시 boardDTO.getBoardNo()를 파일에 연결한다.
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int create(BoardDTO boardDTO) throws Exception;

	/** ============================================================
	 * 게시글 목록 조회 (페이징 적용).
	 * Pager의 startNum·pageSize를 SQL OFFSET·LIMIT으로 사용한다.
	 * ============================================================ */
	public List<BoardDTO> list(Pager pager) throws Exception;

	/** ============================================================
	 * 최근 게시글 N건 조회.
	 * 메인 페이지·사이드바의 최신 게시글 섹션에서 사용한다.
	 * @param limit 가져올 게시글 수
	 * ============================================================ */
	public List<BoardDTO> listRecent(int limit) throws Exception;

	/** ============================================================
	 * 게시글 상세 조회.
	 * boardDTO.boardNo로 한 건을 조회한다.
	 * @return 조회된 BoardDTO (없으면 null)
	 * ============================================================ */
	public BoardDTO detail(BoardDTO boardDTO) throws Exception;

	/** ============================================================
	 * 게시글 수정.
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int update(BoardDTO boardDTO) throws Exception;

	/** ============================================================
	 * 게시글 삭제.
	 * 첨부 파일은 deleteFiles()로 먼저 삭제한 뒤 이 메서드를 호출한다.
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int delete(BoardDTO boardDTO) throws Exception;

	/** ============================================================
	 * 첨부 파일 정보를 BOARD_FILES에 삽입한다.
	 * 파일 1건당 1번씩 호출된다 (for 루프 내에서 반복 호출).
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int createFile(FileDTO fileDTO) throws Exception;

	/** ============================================================
	 * 특정 게시글의 첨부 파일 목록 조회.
	 * detail() 호출 후 파일 목록을 가져와 boardDTO.list에 담는다.
	 * ============================================================ */
	public List<FileDTO> detailFile(BoardDTO boardDTO) throws Exception;

	/** ============================================================
	 * 특정 게시글의 첨부 파일 DB 레코드 전체 삭제.
	 * 게시글 삭제 전 파일 레코드를 먼저 지워야 FK 제약 위반이 없다.
	 * @return 삭제된 파일 수
	 * ============================================================ */
	public int deleteFiles(BoardDTO boardDTO) throws Exception;

	/** ============================================================
	 * 조회수를 1 증가시킨다.
	 * BoardService.detail()의 @Transactional 안에서 실행된다.
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int updateViewCount(BoardDTO boardDTO) throws Exception;
}
