package com.tj.app.member;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/** ============================================================
 * [클래스 읽기] 프로필 사진 DB 접근 Mapper.
 * SQL은 ProfileMapper.xml에 정의되어 있다.
 * ============================================================ */
@Mapper
public interface ProfileMapper {

    /** ============================================================
     * username으로 프로필 정보 조회.
     * @Param("username") → XML의 #{username}에 이 값을 바인딩한다.
     * 프로필이 없으면 null 반환 → ProfileService에서 insert/update 분기에 사용.
     * ============================================================ */
    ProfileDTO findByUsername(@Param("username") String username);

    /** ============================================================
     * 최초 프로필 사진 저장 (INSERT).
     * ============================================================ */
    int insert(ProfileDTO dto);

    /** ============================================================
     * 기존 프로필 사진 교체 (UPDATE).
     * ============================================================ */
    int update(ProfileDTO dto);
}
