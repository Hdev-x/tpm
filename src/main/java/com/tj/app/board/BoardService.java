package com.tj.app.board;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.tj.app.file.FileDTO;
import com.tj.app.file.FileManager;

@Service
public class BoardService {

	@Autowired
	private BoardMapper boardMapper;

	@Autowired
	private FileManager fileManager;

	private List<FileDTO> fileDTO;

	@Value("${app.upload.base}")
	private String name;

	public int create(BoardDTO boardDTO, MultipartFile[] attach) throws Exception {
		int result = boardMapper.create(boardDTO);

		if (attach == null) {
			return result;
		}

		for (MultipartFile f : attach) {
			if (f.isEmpty()) {
				continue;
			}

			String fileName = fileManager.fileSave(name, f);
			FileDTO fileDTO = new FileDTO();
			fileDTO.setBoardNo(boardDTO.getBoardNo());
			fileDTO.setOriName(f.getOriginalFilename());
			fileDTO.setFileName(fileName);

			result = boardMapper.createFile(fileDTO);
		}

		return result;
	}

	public List<BoardDTO> list(BoardDTO boardDTO) throws Exception {
		return boardMapper.list(boardDTO);
	}

	@Transactional
	public BoardDTO detail(BoardDTO boardDTO) throws Exception {
		
		boardMapper.updateViewCount(boardDTO);
		
		boardDTO = boardMapper.detail(boardDTO);
		
		List<FileDTO> files = boardMapper.detailFile(boardDTO);
	    boardDTO.setList(files); 

	    return boardDTO;
	}

	public int update(BoardDTO boardDTO, MultipartFile[] attach) throws Exception {
		int result = boardMapper.update(boardDTO);
		
		if (attach != null) {
	        for (MultipartFile f : attach) {
	            if (f.isEmpty()) continue;

	            String fileName = fileManager.fileSave(name, f);
	            
	            FileDTO fileDTO = new FileDTO();

	            fileDTO.setBoardNo(boardDTO.getBoardNo()); 
	            fileDTO.setOriName(f.getOriginalFilename());
	            fileDTO.setFileName(fileName);

	            boardMapper.createFile(fileDTO);
	        }
	    }
	    return result;
	}

	@Transactional
	public int delete(BoardDTO boardDTO) throws Exception {
		boardDTO = boardMapper.detail(boardDTO);

		if (boardDTO.getList() != null) {
	        for (FileDTO fileDTO : boardDTO.getList()) {
	            fileManager.fileDelete(name, fileDTO);
	        }
	    }
		
		boardMapper.deleteFiles(boardDTO);

		int result = boardMapper.delete(boardDTO);
	    
	    return result;
	}

	public List<FileDTO> fileDetail(FileDTO fileDTO) throws Exception {
		BoardDTO boardDTO = new BoardDTO();
		return boardMapper.detailFile(boardDTO);
	}
}
