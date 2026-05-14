package com.tj.app.member;

import java.util.List;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
public class MemberDTO {
	private String username;
	private String name;
	private String password;
	private Long cash;
	private String email;
	
	private List<RoleDTO> roles;
}
