package com.tj.app.notice;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.tj.app.file.FileDTO;
import com.tj.app.file.FileManager;

@Service
public class NoticeService {

	@Autowired
	private NoticeMapper noticeMapper;

	@Autowired
	private FileManager fileManager;

	private List<FileDTO> fileDTO;

	@Value("${app.upload.base}")
	private String name;

	public int create(NoticeDTO noticeDTO, MultipartFile[] attach) throws Exception {
		int result = noticeMapper.create(noticeDTO);

		if (attach == null) {
			return result;
		}

		for (MultipartFile f : attach) {
			if (f.isEmpty()) {
				continue;
			}

			String fileName = fileManager.fileSave(name, f);
			FileDTO fileDTO = new FileDTO();
			fileDTO.setNoticeNo(noticeDTO.getNoticeNo());
			fileDTO.setOriName(f.getOriginalFilename());
			fileDTO.setFileName(fileName);

			result = noticeMapper.createFile(fileDTO);
		}

		return result;
	}

	public List<NoticeDTO> list(NoticeDTO noticeDTO) throws Exception {
		return noticeMapper.list(noticeDTO);
	}

	public NoticeDTO detail(NoticeDTO noticeDTO) throws Exception {
		noticeDTO = noticeMapper.detail(noticeDTO);
		
		List<FileDTO> files = noticeMapper.detailFile(noticeDTO);
		noticeDTO.setList(files); 

	    return noticeDTO;
	}

	public int update(NoticeDTO noticeDTO, MultipartFile[] attach) throws Exception {
		int result = noticeMapper.update(noticeDTO);
		
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

	@Transactional
	public int delete(NoticeDTO noticeDTO) throws Exception {
		noticeDTO = noticeMapper.detail(noticeDTO);

		if (noticeDTO.getList() != null) {
	        for (FileDTO fileDTO : noticeDTO.getList()) {
	            fileManager.fileDelete(name, fileDTO);
	        }
	    }
		
		noticeMapper.deleteFiles(noticeDTO);

		int result = noticeMapper.delete(noticeDTO);
	    
	    return result;
	}

	public List<FileDTO> fileDetail(FileDTO fileDTO) throws Exception {
		NoticeDTO noticeDTO = new NoticeDTO();
		return noticeMapper.detailFile(noticeDTO);
	}
}
