package com.tj.app.board;

import java.time.LocalDateTime;
import java.util.List;

import com.tj.app.common.file.FileDTO;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
public class BoardDTO {
	
	private Long boardNo;
	private String boardTitle;
	private String boardWriter;
	private String boardContent;
	private LocalDateTime boardDate;
	private Long boardView;
	private String username;
	
	private List<FileDTO> list;
}
