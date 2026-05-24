package com.tj.app.board.reply;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;

/** ============================================================
 * [클래스 읽기] 게시글 댓글(BOARD_REPLIES) DB 작업을 담당하는 MyBatis Mapper.
 *
 * SQL은 ReplyMapper.xml에 정의되어 있다.
 *
 * [관련 테이블] BOARD_REPLIES (replyNo, replyContent, replyDate, username, boardNo)
 *
 * [int 반환] create/update/delete는 영향받은 행 수를 반환한다.
 *   ReplyController에서 result > 0이면 성공으로 처리한다.
 * ============================================================ */
@Mapper
public interface ReplyMapper {

	/** ============================================================
	 * 댓글을 삽입한다.
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int create(ReplyDTO replyDTO) throws Exception;

	/** ============================================================
	 * 특정 게시글의 댓글 목록을 조회한다.
	 * replyDTO.boardNo로 해당 게시글의 댓글만 필터링한다.
	 * SQL 정렬: 일반적으로 replyDate ASC (오래된 순)
	 * ============================================================ */
	public List<ReplyDTO> list(ReplyDTO replyDTO) throws Exception;

	/** ============================================================
	 * 댓글 단건 조회.
	 * 수정 전 기존 내용을 확인할 때 사용한다.
	 * @return 조회된 ReplyDTO (없으면 null)
	 * ============================================================ */
	public ReplyDTO detail(ReplyDTO replyDTO) throws Exception;

	/** ============================================================
	 * 댓글 내용을 수정한다.
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int update(ReplyDTO replyDTO) throws Exception;

	/** ============================================================
	 * 댓글을 삭제한다.
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int delete(ReplyDTO replyDTO) throws Exception;
}
