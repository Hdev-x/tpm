package com.tj.app.common.file;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Setter
@Getter
@ToString
public class FileDTO {
	
	private Long fileNo;
	private String fileName;
	private String oriName;
	private Long boardNo;
	
	private Long noticeNo;
}
