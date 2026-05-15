package com.tj.app.market.stock;

import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class StockJoinService {
	private final Map<String, String> nameToCodeMap = new HashMap<>();
	private final Map<String, String> codeToNameMap = new HashMap<>();

	@PostConstruct
	public void init() {
		try {
			// 리소스 폴더에서 파일 읽기
			Path path = Paths.get(new ClassPathResource("kospi_code.mst").getURI());
			List<String> lines = Files.readAllLines(path, Charset.forName("CP949"));

			for (String line : lines) {
				if (line.length() < 50)
					continue; // 최소 길이 체크

				// 1. 단축코드 (0~6번 사이가 000660임)
				String code = line.substring(0, 6).trim();

				// 2. 종목명 (올려주신 샘플 기준 KR... 뒤인 15번 혹은 18번 이후부터 시작됨)
				// 넉넉하게 15번부터 50번까지 자른 후 trim() 하면 'SK하이닉스'가 잡힙니다.
				String rawName = line.substring(21, 50).trim();

				// 특수문자 제거 및 소문자화
				String searchKey = rawName.replaceAll("[^a-zA-Z0-9가-힣]", "").toLowerCase();

				if (!searchKey.isEmpty() && code.matches("\\d{6}")) {
					nameToCodeMap.put(searchKey, code);
					codeToNameMap.put(code, rawName);
					// 확인용 로그: 처음에 5개 정도만 찍어서 위치 맞는지 보세요.
					// System.out.println("DEBUG: [" + searchKey + "] -> [" + code + "]");
					if (nameToCodeMap.size() < 10) {
						log.info("DEBUG: 저장된 키=[{}], 원본이름=[{}], 코드=[{}]", searchKey, rawName, code);
					}
				}
			}

			log.info("✅ 총 {}개의 종목 로드 완료!", nameToCodeMap.size());
		} catch (Exception e) {
			log.error("❌ 종목 마스터 로드 실패: {}", e.getMessage());
			e.printStackTrace();
		}
	}

	public String getName(String code) {
		// 맵에서 코드를 키로 이름을 찾거나, CSV 리스트를 순회해서 이름을 리턴
		return codeToNameMap.get(code);
	}

	public String getCode(String name) {
		if (name == null || name.isEmpty())
			return null;

		String cleanInput = name.replaceAll("\\s+", "").toLowerCase();

		// 1순위: 이름이 토씨 하나 안 틀리고 '정확히' 일치하는 것부터 찾기
		for (Map.Entry<String, String> entry : nameToCodeMap.entrySet()) {
			if (entry.getKey().equals(cleanInput)) { // contains가 아니라 equals!
				return entry.getValue();
			}
		}

		// 2순위: (정확히 일치하는 게 없을 때만) 포함된 이름 찾기
		for (Map.Entry<String, String> entry : nameToCodeMap.entrySet()) {
			if (entry.getKey().contains(cleanInput)) {
				return entry.getValue();
			}
		}

		return null;
	}
}