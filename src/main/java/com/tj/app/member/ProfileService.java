package com.tj.app.member;

import com.tj.app.common.file.FileManager;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

/** ============================================================
 * [클래스 읽기] 프로필 사진 업로드/조회 서비스.
 *
 * @Autowired 대신 생성자 주입 방식을 사용한다.
 * 생성자 주입은 final 필드를 쓸 수 있고, 의존성이 명확히 드러나 테스트에 유리하다.
 * ============================================================ */
@Service
public class ProfileService {

    private final ProfileMapper profileMapper;
    private final FileManager fileManager; // 파일을 서버 디스크에 저장하는 공통 유틸

    // [실행 흐름] application.properties의 app.upload.base 값을 주입받는다.
    // 예) app.upload.base=/files/ → savePath = /files/profile/
    @Value("${app.upload.base}")
    private String uploadBase;

    // [실행 흐름] Spring이 이 생성자를 찾아 ProfileMapper, FileManager Bean을 자동으로 주입한다.
    public ProfileService(ProfileMapper profileMapper, FileManager fileManager) {
        this.profileMapper = profileMapper;
        this.fileManager = fileManager;
    }

    /** ============================================================
     * username으로 프로필 정보 조회. 없으면 null 반환.
     * ============================================================ */
    public ProfileDTO getProfile(String username) {
        return profileMapper.findByUsername(username);
    }

    /** ============================================================
     * [메서드 읽기] 프로필 사진 저장 (Upsert 패턴).
     *
     * [실행 흐름]
     * 1. FileManager로 파일을 서버 디스크에 저장하고 UUID 기반 fileName 받아옴
     * 2. 기존 프로필이 있으면 UPDATE, 없으면 INSERT
     *    → DB에는 회원당 프로필이 항상 1개만 유지된다
     *
     * @param username 프로필을 저장할 회원 ID
     * @param file     업로드된 이미지 파일
     * ============================================================ */
    public void saveProfile(String username, MultipartFile file) throws Exception {
        String savePath = uploadBase + "profile"; // 예) /files/profile

        // [실행 흐름] 파일을 디스크에 저장하고 UUID 기반 fileName 반환받음
        String fileName = fileManager.fileSave(savePath, file);

        // [실행 흐름] 기존 프로필 유무 확인 → insert / update 분기
        ProfileDTO existing = profileMapper.findByUsername(username);
        ProfileDTO dto = new ProfileDTO();
        dto.setUsername(username);
        dto.setFileName(fileName);
        dto.setOriName(file.getOriginalFilename()); // 사용자가 올린 원본 파일명

        if (existing == null) {
            profileMapper.insert(dto); // 최초 업로드
        } else {
            profileMapper.update(dto); // 사진 교체
        }
    }
}
