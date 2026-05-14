package com.tj.app.file;

import java.io.File;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.util.FileCopyUtils;
import org.springframework.web.multipart.MultipartFile;

@Component
public class FileManager {
	
	@Value("${app.upload.base}")
	private String path;
	
	public boolean fileDelete(String name, FileDTO fileDTO)throws Exception{
		File file = new File(path, name);
		file = new File(file, fileDTO.getFileName());
		
		return file.delete();
		
	}
	
	public String fileSave(String name, MultipartFile mf)throws Exception{
		File file = new File(name); 
	    
	    if(!file.exists()) {
	        file.mkdirs();
	    }
	    
	    String fileName = UUID.randomUUID().toString();
	    fileName = fileName + "_" + mf.getOriginalFilename();
	    file = new File(file, fileName);
	    FileCopyUtils.copy(mf.getBytes(), file);
	    
	    return fileName;
	}
}
