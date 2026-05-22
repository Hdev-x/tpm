package com.tj.app.member;

import com.tj.app.common.file.FileManager;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class ProfileService {

    private final ProfileMapper profileMapper;
    private final FileManager fileManager;

    @Value("${app.upload.base}")
    private String uploadBase;

    public ProfileService(ProfileMapper profileMapper, FileManager fileManager) {
        this.profileMapper = profileMapper;
        this.fileManager = fileManager;
    }

    public ProfileDTO getProfile(String username) {
        return profileMapper.findByUsername(username);
    }

    public void saveProfile(String username, MultipartFile file) throws Exception {
        String savePath = uploadBase + "profile";
        String fileName = fileManager.fileSave(savePath, file);

        ProfileDTO existing = profileMapper.findByUsername(username);
        ProfileDTO dto = new ProfileDTO();
        dto.setUsername(username);
        dto.setFileName(fileName);
        dto.setOriName(file.getOriginalFilename());

        if (existing == null) {
            profileMapper.insert(dto);
        } else {
            profileMapper.update(dto);
        }
    }
}
