package com.tj.app.common.file;

import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.util.Iterator;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.util.FileCopyUtils;
import org.springframework.web.servlet.view.AbstractView;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/** ============================================================
 * [클래스 읽기] 파일 다운로드를 처리하는 커스텀 View 클래스.
 *
 * AbstractView를 상속해 Controller가 반환한 Model 데이터를
 * JSP 대신 파일 스트림으로 직접 응답한다.
 *
 * [전체 흐름]
 * Controller → return new ModelAndView(fileDownView, model)
 *           → Spring이 이 클래스의 renderMergedOutputModel()을 호출
 *           → HTTP 응답 바디에 파일 바이트를 직접 출력
 *
 * model에 담아야 할 데이터:
 *   "fileDTO" → FileDTO (저장 파일명, 원본 파일명)
 *   "name"    → 하위 폴더명 (예: "board", "notice")
 * ============================================================ */
@Component
public class FileDownView extends AbstractView {

	@Value("${app.upload.base}")
	private String base; // 파일 저장 기본 경로 (application.properties)

	/** ============================================================
	 * 파일 다운로드 응답 생성.
	 *
	 * [실행 흐름]
	 * 1. model에서 FileDTO와 하위 폴더명(name)을 꺼냄
	 * 2. base + name + fileName으로 실제 파일 경로를 완성
	 * 3. 응답 헤더에 파일 크기, 파일명, 다운로드 모드 설정
	 * 4. FileInputStream → OutputStream으로 파일 바이트 전송
	 * ============================================================ */
	@Override
	protected void renderMergedOutputModel(Map<String, Object> model, HttpServletRequest request,
			HttpServletResponse response) throws Exception {

		FileDTO fileDTO = (FileDTO) model.get("fileDTO");
		String name = (String) model.get("name"); // 하위 폴더 (예: "board")

		File file = new File(base, name);
		file = new File(file, fileDTO.getFileName()); // 실제 파일 경로 완성

		response.setCharacterEncoding("UTF-8");
		response.setContentLengthLong(file.length()); // 파일 크기 → 브라우저 다운로드 진행률 표시에 사용

		// [실행 흐름] 한글 파일명이 깨지지 않도록 URL 인코딩 처리
		String oriName = URLEncoder.encode(fileDTO.getOriName(), "UTF-8");

		// [실행 흐름] Content-Disposition: attachment → 브라우저가 열지 않고 다운로드하도록 지시
		response.setHeader("Content-Disposition", "attachment;filename=\"" + oriName + "\"");
		response.setHeader("Content-Transfer-Encoding", "binary");

		FileInputStream fi = new FileInputStream(file);
		OutputStream os = response.getOutputStream();
		FileCopyUtils.copy(fi, os); // [실행 흐름] 파일 바이트를 응답 스트림으로 복사

		os.close();
		fi.close();
	}
}
