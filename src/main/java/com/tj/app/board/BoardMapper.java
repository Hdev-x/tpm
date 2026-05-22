package com.tj.app.board;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;

import com.tj.app.common.file.FileDTO;
import com.tj.app.common.pager.Pager;

@Mapper
public interface BoardMapper {
	
	public Long getCount(Pager page) throws Exception;
	
	public int create(BoardDTO boardDTO) throws Exception;
	
	public List<BoardDTO> list(Pager pager) throws Exception;
	
	public List<BoardDTO> listRecent(int limit) throws Exception;
	
	public BoardDTO detail(BoardDTO boardDTO) throws Exception;
	
	public int update(BoardDTO boardDTO) throws Exception;
	
	public int delete(BoardDTO boardDTO) throws Exception;
	
	public int createFile(FileDTO fileDTO) throws Exception;
	
	public List<FileDTO> detailFile(BoardDTO boardDTO) throws Exception;
	
	public int deleteFiles(BoardDTO boardDTO) throws Exception;
	
	public int updateViewCount(BoardDTO boardDTO) throws Exception;
}
