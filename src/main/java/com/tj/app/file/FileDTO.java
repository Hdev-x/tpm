package com.tj.app.file;

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
}
