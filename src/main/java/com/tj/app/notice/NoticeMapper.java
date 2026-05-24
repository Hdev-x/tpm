package com.tj.app.notice;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;

import com.tj.app.common.file.FileDTO;

/** ============================================================
 * [클래스 읽기] 공지사항(NOTICE) DB 작업을 담당하는 MyBatis Mapper.
 *
 * SQL은 NoticeMapper.xml에 정의되어 있다.
 *
 * [관련 테이블]
 *   NOTICE       : 공지사항 본문 (noticeNo, title, content, writer, date, view, username)
 *   NOTICE_FILES : 첨부 파일 목록 (fileNo, noticeNo, oriName, fileName)
 *
 * [BoardMapper와의 차이]
 *   list(): NoticeDTO를 파라미터로 받는다 (Pager 없음 → 페이징 미지원, 전체 조회).
 *   likeCount, reply 관련 메서드 없음 (공지사항은 좋아요·댓글 기능 없음).
 * ============================================================ */
@Mapper
public interface NoticeMapper {

	/** ============================================================
	 * 공지사항 등록. INSERT 후 생성된 PK(noticeNo)를 noticeDTO에 자동 채워준다.
	 * (XML: useGeneratedKeys="true" keyProperty="noticeNo" 설정 필요)
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int create(NoticeDTO noticeDTO) throws Exception;

	/** ============================================================
	 * 공지사항 목록 전체 조회 (페이징 없음).
	 * noticeDTO에 검색 조건(제목 키워드 등)이 있으면 WHERE 절에 반영될 수 있다.
	 * ============================================================ */
	public List<NoticeDTO> list(NoticeDTO noticeDTO) throws Exception;

	/** ============================================================
	 * 최근 공지사항 N건 조회 (메인 페이지·사이드바용).
	 * @param limit 가져올 공지사항 수
	 * ============================================================ */
	public List<NoticeDTO> listRecent(int limit) throws Exception;

	/** ============================================================
	 * 공지사항 상세 단건 조회. noticeDTO.noticeNo로 조회한다.
	 * @return 조회된 NoticeDTO (없으면 null)
	 * ============================================================ */
	public NoticeDTO detail(NoticeDTO noticeDTO) throws Exception;

	/** ============================================================
	 * 공지사항 수정.
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int update(NoticeDTO noticeDTO) throws Exception;

	/** ============================================================
	 * 공지사항 삭제.
	 * 첨부 파일은 deleteFiles()로 먼저 삭제한 뒤 이 메서드를 호출한다.
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int delete(NoticeDTO noticeDTO) throws Exception;

	/** ============================================================
	 * 첨부 파일 정보를 NOTICE_FILES에 삽입한다. 파일 1건당 1번씩 호출된다.
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int createFile(FileDTO fileDTO) throws Exception;

	/** ============================================================
	 * 특정 공지사항의 첨부 파일 목록 조회.
	 * detail() 호출 후 파일 목록을 가져와 noticeDTO.list에 담는다.
	 * ============================================================ */
	public List<FileDTO> detailFile(NoticeDTO noticeDTO) throws Exception;

	/** ============================================================
	 * 특정 공지사항의 첨부 파일 DB 레코드 전체 삭제.
	 * 공지사항 삭제 전 호출해야 FK 제약 위반을 방지할 수 있다.
	 * @return 삭제된 파일 수
	 * ============================================================ */
	public int deleteFiles(NoticeDTO noticeDTO) throws Exception;

	/** ============================================================
	 * 조회수를 1 증가시킨다.
	 * NoticeService.detail() 호출 시 함께 실행된다.
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int updateViewCount(NoticeDTO noticeDTO) throws Exception;
}
