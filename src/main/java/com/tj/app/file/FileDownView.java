package com.tj.app.file;

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

@Component
public class FileDownView extends AbstractView {
	
	@Value("${app.upload.base}")
	private String base;

	@Override
	protected void renderMergedOutputModel(Map<String, Object> model, HttpServletRequest request,
			HttpServletResponse response) throws Exception {
		// TODO Auto-generated method stub
		
		FileDTO fileDTO = (FileDTO)model.get("fileDTO");
		String name = (String)model.get("name");
			
		File file = new File(base, name);
		file = new File(file, fileDTO.getFileName());
		
		response.setCharacterEncoding("UTF-8");
		response.setContentLengthLong(file.length());
		
		String oriName = fileDTO.getOriName();
		oriName = URLEncoder.encode(oriName, "UTF-8");
		
		response.setHeader("Content-Disposition", "attachment;filename=\""+oriName+"\"");
		response.setHeader("Content-Transfer-Encoding", "binary");
		
		FileInputStream fi = new FileInputStream(file);
		OutputStream os = response.getOutputStream(); 
		FileCopyUtils.copy(fi, os);
		
		os.close();
		fi.close();
		
	}
}
