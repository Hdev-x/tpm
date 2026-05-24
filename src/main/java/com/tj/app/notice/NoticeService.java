package com.tj.app.notice;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.tj.app.common.file.FileDTO;
import com.tj.app.common.file.FileManager;

/** ============================================================
 * [클래스 읽기] 공지사항 작성·조회·수정·삭제 비즈니스 로직을 담당하는 서비스.
 *
 * BoardService와 구조가 거의 동일하다.
 * 차이점:
 *   - detail()에 @Transactional 없음 (BoardService.detail()에는 있음)
 *   - list()가 Pager를 받지 않아 전체 목록을 조회한다 (페이징 없음)
 *   - 좋아요·댓글 연동 없음
 *
 * [@Value("${app.upload.base}")] 업로드 기본 경로를 주입받는다.
 *   변수명 'name'은 명확하지 않지만 동작에는 문제 없다.
 * ============================================================ */
@Service
public class NoticeService {

	@Autowired
	private NoticeMapper noticeMapper;

	@Autowired
	private FileManager fileManager;

	/** 업로드 기본 디렉터리 (application.properties: app.upload.base) */
	@Value("${app.upload.base}")
	private String name;

	/** ============================================================
	 * 공지사항을 등록하고 첨부 파일을 저장한다.
	 *
	 * [실행 흐름]
	 * 1. noticeMapper.create() → DB INSERT (noticeNo 자동 채워짐)
	 * 2. attach가 null이면 즉시 반환
	 * 3. 파일 배열 순회 → 빈 파일 건너뜀 → 서버 저장 → DB 기록
	 *
	 * [BoardService.create()와 동일한 패턴]
	 *   fileDTO.setNoticeNo()로 공지사항 번호를 파일에 연결한다.
	 *
	 * @param noticeDTO 공지사항 내용 (noticeNo는 INSERT 후 채워짐)
	 * @param attach    첨부 파일 배열 (없으면 null)
	 * @return 마지막 파일 저장 결과 (영향받은 행 수)
	 * ============================================================ */
	public int create(NoticeDTO noticeDTO, MultipartFile[] attach) throws Exception {
		int result = noticeMapper.create(noticeDTO); // [실행 흐름] INSERT → noticeNo 자동 세팅

		if (attach == null) {
			return result; // 첨부 없음 → 즉시 반환
		}

		for (MultipartFile f : attach) {
			if (f.isEmpty()) {
				continue; // 빈 파일 건너뜀
			}

			String fileName = fileManager.fileSave(name, f); // 서버 디스크에 저장

			FileDTO fileDTO = new FileDTO();
			fileDTO.setNoticeNo(noticeDTO.getNoticeNo()); // INSERT로 생성된 공지 번호 연결
			fileDTO.setOriName(f.getOriginalFilename());   // 원본 파일명 (화면 표시용)
			fileDTO.setFileName(fileName);                 // 저장된 파일명 (다운로드·삭제용)

			result = noticeMapper.createFile(fileDTO); // 파일 정보 DB 저장
		}

		return result;
	}

	/** ============================================================
	 * 공지사항 목록 전체를 조회한다 (페이징 없음).
	 *
	 * [BoardService.list()와 차이] Pager를 받지 않으므로 모든 공지사항이 반환된다.
	 *   공지사항 수가 많아지면 페이징 추가가 필요하다.
	 * ============================================================ */
	public List<NoticeDTO> list(NoticeDTO noticeDTO) throws Exception {
		return noticeMapper.list(noticeDTO);
	}

	/** ============================================================
	 * 최근 공지사항 N건을 조회한다 (메인·사이드바용).
	 * ============================================================ */
	public List<NoticeDTO> listRecent(int limit) throws Exception {
		return noticeMapper.listRecent(limit);
	}

	/** ============================================================
	 * 공지사항 상세 정보(본문 + 첨부 파일 목록)를 조회하고 조회수를 증가시킨다.
	 *
	 * [BoardService.detail()과 차이] @Transactional이 없다.
	 *   updateViewCount + detail + detailFile이 각각 독립 트랜잭션으로 실행된다.
	 *   중간 실패 시 조회수 증가가 롤백되지 않는다.
	 *
	 * [실행 흐름]
	 * 1. updateViewCount() → 조회수 +1
	 * 2. detail()          → 본문 조회
	 * 3. detailFile()      → 첨부 파일 목록 조회 → noticeDTO.list에 설정
	 * ============================================================ */
	public NoticeDTO detail(NoticeDTO noticeDTO) throws Exception {
		noticeMapper.updateViewCount(noticeDTO); // [실행 흐름] 조회수 +1

		noticeDTO = noticeMapper.detail(noticeDTO); // [실행 흐름] 본문 조회

		List<FileDTO> files = noticeMapper.detailFile(noticeDTO); // [실행 흐름] 파일 목록 조회
		noticeDTO.setList(files); // 파일 목록을 DTO에 담아 한 번에 전달

	    return noticeDTO;
	}

	/** ============================================================
	 * 공지사항을 수정하고 새 첨부 파일을 추가한다.
	 *
	 * [주의] 기존 첨부 파일은 자동으로 삭제되지 않는다. (파일 추가만 가능)
	 *   BoardService.update()와 동일한 한계가 있다.
	 * ============================================================ */
	public int update(NoticeDTO noticeDTO, MultipartFile[] attach) throws Exception {
		int result = noticeMapper.update(noticeDTO); // 본문 UPDATE

		if (attach != null) {
	        for (MultipartFile f : attach) {
	            if (f.isEmpty()) continue;

	            String fileName = fileManager.fileSave(name, f);

	            FileDTO fileDTO = new FileDTO();
	            fileDTO.setNoticeNo(noticeDTO.getNoticeNo());
	            fileDTO.setOriName(f.getOriginalFilename());
	            fileDTO.setFileName(fileName);

	            noticeMapper.createFile(fileDTO);
	        }
	    }
	    return result;
	}

	/** ============================================================
	 * 공지사항과 첨부 파일을 삭제한다.
	 *
	 * [@Transactional] 파일 레코드 삭제 + 공지사항 삭제가 하나의 트랜잭션.
	 *   (단, 디스크 파일 삭제는 물리 작업이라 롤백 불가)
	 *
	 * [실행 흐름]
	 * 1. detail()      → 삭제할 공지사항 + 파일 목록 조회
	 * 2. fileDelete()  → 서버 디스크에서 파일 삭제 (루프)
	 * 3. deleteFiles() → NOTICE_FILES 레코드 삭제
	 * 4. delete()      → NOTICE 레코드 삭제
	 * ============================================================ */
	@Transactional
	public int delete(NoticeDTO noticeDTO) throws Exception {
		noticeDTO = noticeMapper.detail(noticeDTO); // [실행 흐름] 파일 목록 포함 상세 조회

		if (noticeDTO.getList() != null) {
	        for (FileDTO fileDTO : noticeDTO.getList()) {
	            fileManager.fileDelete(name, fileDTO); // 물리 파일 삭제
	        }
	    }

		noticeMapper.deleteFiles(noticeDTO); // NOTICE_FILES 레코드 삭제
		int result = noticeMapper.delete(noticeDTO); // NOTICE 삭제

	    return result;
	}

	/** ============================================================
	 * 공지사항의 첨부 파일 목록을 조회한다.
	 *
	 * fileDTO.noticeNo를 NoticeDTO에 옮겨 담아 해당 공지사항의 파일만 조회한다.
	 *
	 * @param fileDTO noticeNo가 담긴 FileDTO
	 * @return 해당 공지사항의 첨부 파일 목록
	 * ============================================================ */
	public List<FileDTO> fileDetail(FileDTO fileDTO) throws Exception {
		NoticeDTO noticeDTO = new NoticeDTO();
		noticeDTO.setNoticeNo(fileDTO.getNoticeNo()); // [코드 읽기] noticeNo를 옮겨 담아야 해당 공지 파일만 조회됨
		return noticeMapper.detailFile(noticeDTO);
	}
}
