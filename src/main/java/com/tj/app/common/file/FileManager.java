package com.tj.app.common.file;

import java.io.File;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.util.FileCopyUtils;
import org.springframework.web.multipart.MultipartFile;

/** ============================================================
 * [클래스 읽기] 파일 저장·삭제를 담당하는 공통 유틸리티 클래스.
 *
 * @Component → @Service/@Repository 대신 일반 컴포넌트로 등록.
 * Service 레이어에서 @Autowired로 주입받아 사용한다.
 * ProfileService, BoardService 등 파일이 필요한 모든 서비스에서 공유한다.
 * ============================================================ */
@Component
public class FileManager {

	// [실행 흐름] application.properties의 app.upload.base 경로를 주입
	@Value("${app.upload.base}")
	private String path;

	/** ============================================================
	 * 파일 삭제.
	 * path + name 디렉토리 안의 fileDTO.fileName 파일을 삭제한다.
	 * @return 삭제 성공 여부 (true/false)
	 * ============================================================ */
	public boolean fileDelete(String name, FileDTO fileDTO) throws Exception {
		File file = new File(path, name);            // 기본 경로 + 하위 폴더명
		file = new File(file, fileDTO.getFileName()); // 실제 파일 경로
		return file.delete();
	}

	/** ============================================================
	 * 파일 저장.
	 *
	 * [실행 흐름]
	 * 1. 저장 디렉토리가 없으면 mkdirs()로 생성
	 * 2. UUID + 원본파일명으로 fileName 생성 (중복 방지)
	 * 3. FileCopyUtils.copy()로 파일을 디스크에 저장
	 * 4. 저장된 fileName 반환 → DB에 이 이름을 저장한다
	 *
	 * @param name 저장할 디렉토리 절대 경로 (예: /files/profile)
	 * @param mf   업로드된 파일 객체
	 * @return 저장된 파일명 (UUID_원본파일명)
	 * ============================================================ */
	public String fileSave(String name, MultipartFile mf) throws Exception {
		File file = new File(name);
		if (!file.exists()) {
			file.mkdirs(); // [실행 흐름] 경로의 모든 중간 디렉토리까지 한 번에 생성
		}

		// [실행 흐름] UUID로 고유 파일명 생성 → 같은 이름 파일이 올라와도 충돌 없음
		String fileName = UUID.randomUUID().toString();
		fileName = fileName + "_" + mf.getOriginalFilename();

		file = new File(file, fileName);
		FileCopyUtils.copy(mf.getBytes(), file); // [실행 흐름] 업로드 파일 바이트를 디스크에 복사

		return fileName;
	}
}
