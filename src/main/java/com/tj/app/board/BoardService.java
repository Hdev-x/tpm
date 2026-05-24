package com.tj.app.board;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.tj.app.common.file.FileDTO;
import com.tj.app.common.file.FileManager;
import com.tj.app.common.pager.Pager;

/** ============================================================
 * [클래스 읽기] 게시판 게시글 작성·조회·수정·삭제 비즈니스 로직을 담당하는 서비스.
 *
 * [파일 업로드 흐름]
 *   Controller → MultipartFile[] 전달 → Service에서 FileManager로 서버에 저장
 *   → 저장된 파일명을 FileDTO에 담아 DB(BOARD_FILES)에 기록
 *
 * [@Value("${app.upload.base}")]
 *   application.properties의 업로드 기본 디렉터리를 주입받는다.
 *   (변수명 'name'은 의미를 알기 어려우므로 실제로는 'uploadBase' 같은 이름이 더 명확하다)
 *   파일은 이 경로 아래에 저장된다.
 *
 * [@Transactional 적용 범위]
 *   detail(), delete()에만 적용 — 조회수 갱신+상세조회, 파일삭제+게시글삭제가 하나의 트랜잭션.
 *   create(), update()는 파일 저장 실패 시 DB 롤백이 안 되는 한계가 있다. (향후 개선 가능)
 * ============================================================ */
@Service
public class BoardService {

	@Autowired
	private BoardMapper boardMapper;

	@Autowired
	private FileManager fileManager;

	/** 업로드 기본 디렉터리 (application.properties: app.upload.base) */
	@Value("${app.upload.base}")
	private String name;

	/** ============================================================
	 * 게시글을 등록하고 첨부 파일을 저장한다.
	 *
	 * [실행 흐름]
	 * 1. boardMapper.create() → DB INSERT (boardNo 자동 채워짐)
	 * 2. attach가 null이면 (첨부 없음) 즉시 반환
	 * 3. 파일 배열 순회 → 빈 파일 건너뜀
	 * 4. fileManager.fileSave() → 서버 디스크에 저장 → 저장된 파일명 반환
	 * 5. FileDTO 생성 후 boardNo·oriName·fileName 설정 → DB INSERT
	 *
	 * @param boardDTO 게시글 정보 (boardNo는 insert 후 채워짐)
	 * @param attach   첨부 파일 배열 (없으면 null)
	 * @return 마지막 파일 저장 결과 (영향받은 행 수), 파일 없으면 게시글 INSERT 결과
	 * ============================================================ */
	public int create(BoardDTO boardDTO, MultipartFile[] attach) throws Exception {
		int result = boardMapper.create(boardDTO); // [실행 흐름] 게시글 INSERT → boardNo 자동 세팅

		if (attach == null) {
			return result; // [실행 흐름] 첨부 없음 → 즉시 반환
		}

		for (MultipartFile f : attach) {
			if (f.isEmpty()) {
				continue; // [코드 읽기] 빈 파일 항목은 건너뜀 (폼에서 파일 미선택 시 빈 항목이 올 수 있음)
			}

			// [실행 흐름] 서버 디스크에 파일 저장 → 중복 방지를 위한 변환된 파일명 반환
			String fileName = fileManager.fileSave(name, f);

			FileDTO fileDTO = new FileDTO();
			fileDTO.setBoardNo(boardDTO.getBoardNo()); // [코드 읽기] INSERT로 생성된 게시글 번호 연결
			fileDTO.setOriName(f.getOriginalFilename()); // 원본 파일명 (화면에 표시용)
			fileDTO.setFileName(fileName);               // 서버 저장 파일명 (다운로드·삭제용)

			result = boardMapper.createFile(fileDTO); // [실행 흐름] 파일 정보 DB 저장
		}

		return result;
	}

	/** ============================================================
	 * 게시글 목록을 페이징해 조회한다.
	 *
	 * [실행 흐름]
	 * 1. pager.makePageNum() : 총 게시글 수를 기반으로 전체 페이지 수 계산
	 * 2. pager.makeStartNum(): 현재 페이지의 시작 행 번호(OFFSET) 계산
	 * 3. boardMapper.list()  : OFFSET·LIMIT을 적용해 해당 페이지 데이터 조회
	 *
	 * [Pager] 공통 페이징 클래스. 쿼리 파라미터(currentPage, pageSize 등)를
	 *   Spring이 자동으로 바인딩해 Controller에서 바로 넘겨준다.
	 * ============================================================ */
	public List<BoardDTO> list(Pager pager) throws Exception {
		pager.makePageNum(boardMapper.getCount(pager)); // [실행 흐름] 전체 수 → 페이지 수 계산
		pager.makeStartNum();                           // [실행 흐름] 시작 행 번호(OFFSET) 계산
		return boardMapper.list(pager);
	}

	/** ============================================================
	 * 최근 게시글 N건을 조회한다 (메인·사이드바용).
	 * ============================================================ */
	public List<BoardDTO> listRecent(int limit) throws Exception {
		return boardMapper.listRecent(limit);
	}

	/** ============================================================
	 * 총 게시글 수를 반환한다 (검색 조건 포함).
	 * list()와 별도로 Ajax 페이징 계산에 사용할 수 있다.
	 * ============================================================ */
	public Long getCount(Pager pager) throws Exception {
        return boardMapper.getCount(pager);
    }

	/** ============================================================
	 * 게시글 상세 정보(본문 + 첨부 파일 목록)를 조회하고 조회수를 증가시킨다.
	 *
	 * [@Transactional]
	 *   updateViewCount() + detail() + detailFile() 3단계가 하나의 트랜잭션.
	 *   중간에 실패하면 조회수 증가가 롤백된다.
	 *
	 * [실행 흐름]
	 * 1. updateViewCount() → 조회수 +1
	 * 2. detail()          → 게시글 본문 조회
	 * 3. detailFile()      → 첨부 파일 목록 조회 → boardDTO.list에 설정
	 *
	 * @return 본문 + 파일 목록이 담긴 BoardDTO
	 * ============================================================ */
	@Transactional
	public BoardDTO detail(BoardDTO boardDTO) throws Exception {
		boardMapper.updateViewCount(boardDTO); // [실행 흐름] 조회수 +1

		boardDTO = boardMapper.detail(boardDTO); // [실행 흐름] 게시글 본문 조회

		List<FileDTO> files = boardMapper.detailFile(boardDTO); // [실행 흐름] 첨부 파일 목록 조회
	    boardDTO.setList(files); // [코드 읽기] 파일 목록을 boardDTO.list에 담아 한 번에 전달

	    return boardDTO;
	}

	/** ============================================================
	 * 게시글을 수정하고 새 첨부 파일을 추가한다.
	 *
	 * [실행 흐름]
	 * 1. boardMapper.update() → 제목·본문 UPDATE
	 * 2. 새 파일가 있으면 서버 저장 → DB 파일 레코드 추가
	 *
	 * [주의] 기존 첨부 파일은 자동으로 삭제되지 않는다.
	 *   기존 파일을 지우려면 별도로 deleteFiles()를 호출해야 한다.
	 *   현재 구현은 파일 추가만 가능하다.
	 * ============================================================ */
	public int update(BoardDTO boardDTO, MultipartFile[] attach) throws Exception {
		int result = boardMapper.update(boardDTO); // [실행 흐름] 게시글 UPDATE

		if (attach != null) {
	        for (MultipartFile f : attach) {
	            if (f.isEmpty()) continue; // 빈 파일 건너뜀

	            String fileName = fileManager.fileSave(name, f); // 서버에 저장

	            FileDTO fileDTO = new FileDTO();
	            fileDTO.setBoardNo(boardDTO.getBoardNo());
	            fileDTO.setOriName(f.getOriginalFilename());
	            fileDTO.setFileName(fileName);

	            boardMapper.createFile(fileDTO); // 파일 정보 DB 저장
	        }
	    }
	    return result;
	}

	/** ============================================================
	 * 게시글과 첨부 파일을 삭제한다.
	 *
	 * [@Transactional]
	 *   파일 삭제(디스크) + DB 레코드 삭제 + 게시글 삭제가 하나의 트랜잭션.
	 *   게시글 삭제 실패 시 DB 파일 레코드 삭제가 롤백된다.
	 *   (단, 디스크 파일 삭제는 물리적 작업이므로 롤백 불가 → 고아 파일 가능성)
	 *
	 * [실행 흐름]
	 * 1. detail()      → 삭제할 게시글 + 파일 목록 조회
	 * 2. fileDelete()  → 서버 디스크에서 파일 삭제 (루프)
	 * 3. deleteFiles() → BOARD_FILES에서 레코드 삭제
	 * 4. delete()      → BOARD에서 게시글 삭제
	 *
	 * @return 영향받은 행 수 (정상: 1)
	 * ============================================================ */
	@Transactional
	public int delete(BoardDTO boardDTO) throws Exception {
		boardDTO = boardMapper.detail(boardDTO); // [실행 흐름] 파일 목록 포함 상세 조회

		// [실행 흐름] 첨부 파일이 있으면 서버 디스크에서 삭제
		if (boardDTO.getList() != null) {
	        for (FileDTO fileDTO : boardDTO.getList()) {
	            fileManager.fileDelete(name, fileDTO); // 물리 파일 삭제
	        }
	    }

		boardMapper.deleteFiles(boardDTO); // [실행 흐름] BOARD_FILES 레코드 삭제

		int result = boardMapper.delete(boardDTO); // [실행 흐름] BOARD 게시글 삭제

	    return result;
	}

	/** ============================================================
	 * 게시글의 첨부 파일 목록을 조회한다.
	 *
	 * fileDTO.boardNo를 BoardDTO에 옮겨 담아 해당 게시글의 파일만 조회한다.
	 *
	 * @param fileDTO boardNo가 담긴 FileDTO
	 * @return 해당 게시글의 첨부 파일 목록
	 * ============================================================ */
	public List<FileDTO> fileDetail(FileDTO fileDTO) throws Exception {
		BoardDTO boardDTO = new BoardDTO();
		boardDTO.setBoardNo(fileDTO.getBoardNo()); // [코드 읽기] boardNo를 옮겨 담아야 해당 게시글 파일만 조회됨
		return boardMapper.detailFile(boardDTO);
	}
}
