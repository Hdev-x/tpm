package com.tj.app.reply;

import java.time.LocalDateTime;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
public class ReplyDTO {

	private Long replyNo;
	private String replyContent;
	private LocalDateTime replyDate;
	private String username;
	private Long boardNo;
}
