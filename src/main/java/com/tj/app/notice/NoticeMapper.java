package com.tj.app.notice;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;

import com.tj.app.file.FileDTO;

@Mapper
public interface NoticeMapper {
	
	public int create(NoticeDTO noticeDTO) throws Exception;
	
	public List<NoticeDTO> list(NoticeDTO noticeDTO) throws Exception;
	
	public NoticeDTO detail(NoticeDTO noticeDTO) throws Exception;
	
	public int update(NoticeDTO noticeDTO) throws Exception;
	
	public int delete(NoticeDTO noticeDTO) throws Exception;
	
	public int createFile(FileDTO fileDTO) throws Exception;
	
	public List<FileDTO> detailFile(NoticeDTO noticeDTO) throws Exception;
	
	public int deleteFiles(NoticeDTO noticeDTO) throws Exception;
	
	public int updateViewCount(NoticeDTO noticeDTO) throws Exception;
}
