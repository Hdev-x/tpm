package com.tj.app.board.reply;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** ============================================================
 * [클래스 읽기] 게시글 댓글 CRUD 비즈니스 로직을 담당하는 서비스.
 *
 * [@Transactional 클래스 레벨]
 *   모든 public 메서드가 트랜잭션 안에서 실행된다.
 *   현재는 각 메서드가 단일 DB 작업이라 트랜잭션 효과가 크지 않지만,
 *   향후 댓글 삭제 시 연관 데이터(첨부파일, 알림 등) 추가 시 유용하다.
 *
 * [구조] ReplyMapper의 얇은 래퍼(thin wrapper).
 *   현재는 별도 비즈니스 로직 없이 Mapper를 그대로 호출한다.
 *   향후 유효성 검사·알림·로깅 등이 추가될 자리다.
 * ============================================================ */
@Service
@Transactional
public class ReplyService {

	@Autowired
	private ReplyMapper replyMapper;

	/** ============================================================
	 * 댓글을 등록한다.
	 * ReplyController에서 username을 세션 값으로 설정한 뒤 호출한다.
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int create(ReplyDTO replyDTO) throws Exception {
		int result = replyMapper.create(replyDTO);
		return result;
	}

	/** ============================================================
	 * 특정 게시글의 댓글 목록을 조회한다.
	 * replyDTO.boardNo로 해당 게시글의 댓글만 가져온다.
	 * ============================================================ */
	public List<ReplyDTO> list(ReplyDTO replyDTO) throws Exception {
		return replyMapper.list(replyDTO);
	}

	/** ============================================================
	 * 댓글 단건을 조회한다.
	 * @return 조회된 ReplyDTO (없으면 null)
	 * ============================================================ */
	public ReplyDTO detail(ReplyDTO replyDTO) throws Exception {
		return replyMapper.detail(replyDTO);
	}

	/** ============================================================
	 * 댓글 내용을 수정한다.
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int update(ReplyDTO replyDTO) throws Exception {
		return replyMapper.update(replyDTO);
	}

	/** ============================================================
	 * 댓글을 삭제한다.
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	public int delete(ReplyDTO replyDTO) throws Exception {
		int result = replyMapper.delete(replyDTO);
		return result;
	}
}
