package com.tj.app.member;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@ToString
public class ProfileDTO {
    private Long profileNo;
    private String username;
    private String fileName;
    private String oriName;
}
