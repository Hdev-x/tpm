package com.tj.app.notice;

import java.time.LocalDate;
import java.util.List;

import com.tj.app.file.FileDTO;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
public class NoticeDTO {
	
	private Long noticeNo;
	private String noticeTitle;
	private String noticeWriter;
	private String noticeContent;
	private LocalDate noticeDate;
	private Long noticeView;
	private String username;
	
	private List<FileDTO> list;
}
