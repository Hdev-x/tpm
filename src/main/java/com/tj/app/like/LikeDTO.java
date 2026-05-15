package com.tj.app.like;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
public class LikeDTO {

	private Long likeNo;
	private String username;
	private Long boardNo;
}
