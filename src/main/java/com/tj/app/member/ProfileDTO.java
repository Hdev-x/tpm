package com.tj.app.member;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

/** ============================================================
 * [클래스 읽기] 회원 프로필 사진 정보를 담는 DTO.
 *
 * 파일을 서버에 저장할 때 원본 이름(oriName)과 저장된 이름(fileName)을 분리해서 관리한다.
 * 저장된 이름(fileName)은 UUID 기반으로 생성되어 파일명 충돌을 방지한다.
 * 실제 파일 경로: /files/profile/{fileName}
 * ============================================================ */
@Getter
@Setter
@ToString
public class ProfileDTO {
    private Long profileNo;
    private String username; // 어떤 회원의 프로필인지 식별하는 FK
    private String fileName; // 서버에 저장된 파일명 (UUID 기반, 중복 방지)
    private String oriName;  // 사용자가 업로드한 원본 파일명
}
