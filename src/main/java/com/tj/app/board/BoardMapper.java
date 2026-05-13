package com.tj.app.board;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;

import com.tj.app.file.FileDTO;

@Mapper
public interface BoardMapper {
	
	public int create(BoardDTO boardDTO) throws Exception;
	
	public List<BoardDTO> list(BoardDTO boardDTO) throws Exception;
	
	public BoardDTO detail(BoardDTO boardDTO) throws Exception;
	
	public int update(BoardDTO boardDTO) throws Exception;
	
	public int delete(BoardDTO boardDTO) throws Exception;
	
	public int createFile(FileDTO fileDTO) throws Exception;
	
	public List<FileDTO> detailFile(BoardDTO boardDTO) throws Exception;
}
