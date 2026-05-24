package com.tj.app.news;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** ============================================================
 * [클래스 읽기] 네이버 뉴스 검색 API를 호출해 뉴스 데이터를 가져오는 서비스.
 *
 * [@Slf4j] Lombok이 log 필드를 자동 생성한다. log.info/warn/error()로 사용.
 *
 * [네이버 뉴스 검색 API]
 *   URL: GET https://openapi.naver.com/v1/search/news.json
 *   인증: X-Naver-Client-Id / X-Naver-Client-Secret 헤더
 *   키: application.properties의 app.news.clientid / app.news.clientsecret
 *
 * [@Value 주입]
 *   @Value("${app.news.clientid}") → naverClientId 필드에 설정값 자동 주입
 *   API 키를 코드에 하드코딩하지 않고 외부 설정 파일에서 관리하는 방식이다.
 *
 * [WebClient 생성 위치]
 *   메서드 내부에서 매 호출 시 생성한다. 캐시가 없으므로 Controller에서 호출할 때마다 API를 요청한다.
 *   뉴스는 실시간성이 중요하므로 CoinMarketService처럼 캐시를 두지 않는다.
 * ============================================================ */
@Slf4j
@Service
public class NewsService {

    /** 네이버 개발자센터에서 발급받은 Client ID (application.properties) */
    @Value("${app.news.clientid}")
    private String naverClientId;

    /** 네이버 개발자센터에서 발급받은 Client Secret (application.properties) */
    @Value("${app.news.clientsecret}")
    private String naverClientSecret;

    /** ============================================================
     * [메서드 읽기] 뉴스 검색 편의 메서드 (start=1 고정).
     * start 파라미터 없이 첫 페이지부터 검색할 때 사용한다.
     * ============================================================ */
    public NewsDTO searchStockNews(String keyword) {
        return searchStockNews(keyword, 1); // [코드 읽기] start=1로 오버로딩 메서드 위임
    }

    /** ============================================================
     * [메서드 읽기] 네이버 뉴스 API를 직접 호출해 검색 결과를 반환한다.
     *
     * [실행 흐름]
     * 1. WebClient로 네이버 뉴스 API 호출 (display=30 요청)
     * 2. bodyToMono(NewsDTO.class): JSON → NewsDTO 자동 역직렬화
     * 3. block(5초): 비동기 → 동기 전환 (최대 5초 대기)
     * 4. items가 있으면 deduplicateByTitle()로 중복 제거 후 15건으로 축소
     * 5. 실패 시 null 반환 (Controller에서 빈 규격 응답으로 처리)
     *
     * [display=30 요청하는 이유]
     *   중복 제거 후 15건을 확보하려면 여유있게 30건을 요청해야 한다.
     *   뉴스 제목이 비슷한 기사가 많아 30건 중 15건 이하가 유니크할 수 있다.
     *
     * [sort=sim] 관련도 순 정렬. "date"로 변경 시 최신 순 정렬.
     *
     * @param keyword 검색 키워드 (예: "삼성전자", "BTCUSDT", "코스피")
     * @param start   페이징 시작 위치 (1부터 시작, 1=1번째 기사부터)
     * @return 중복 제거된 뉴스 결과 NewsDTO, 실패 시 null
     * ============================================================ */
    public NewsDTO searchStockNews(String keyword, int start) {
        try {
            // [실행 흐름] 네이버 API용 WebClient 생성
            WebClient naverClient = WebClient.builder()
                    .baseUrl("https://openapi.naver.com")
                    .build();

            NewsDTO result = naverClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/v1/search/news.json")
                            .queryParam("query", keyword)   // 검색 키워드
                            .queryParam("display", 30)      // 중복 제거 대비 여유분 요청
                            .queryParam("start", start)     // 페이징 시작 위치
                            .queryParam("sort", "sim")      // 관련도 순 정렬
                            .build())
                    .header("X-Naver-Client-Id", naverClientId)         // API 인증 헤더
                    .header("X-Naver-Client-Secret", naverClientSecret) // API 인증 헤더
                    .retrieve()
                    .bodyToMono(NewsDTO.class) // [코드 읽기] JSON → NewsDTO로 자동 역직렬화
                    .block(Duration.ofSeconds(5)); // 최대 5초 대기 (동기 전환)

            // [실행 흐름] 중복 뉴스 제거 후 최대 15건으로 축소
            if (result != null && result.getItems() != null) {
                result.setItems(deduplicateByTitle(result.getItems(), 15));
            }
            return result;

        } catch (Exception e) {
            log.error("❌ 네이버 뉴스 수급 실패 [검색어: {}]: {}", keyword, e.getMessage());
            return null; // [실행 흐름] 실패 시 null → Controller에서 빈 규격 응답 반환
        }
    }

    /** ============================================================
     * [메서드 읽기] 뉴스 제목 앞 25자를 기준으로 중복 기사를 제거한다.
     *
     * [중복 제거 기준]
     *   title에서 HTML 태그 제거 → 공백 정규화 → 앞 25자 추출
     *   같은 25자 prefix를 가진 기사는 중복으로 간주해 첫 번째만 남긴다.
     *
     * [실행 흐름]
     * 1. seen: 이미 처리된 25자 key 집합 (HashSet → O(1) 중복 체크)
     * 2. 각 뉴스 제목에서 HTML 태그 제거 + 공백 정규화 + 25자 자르기
     * 3. seen.add(key): 처음 보는 key면 true → unique 리스트에 추가
     * 4. unique 크기가 limit에 도달하면 루프 종료
     *
     * [정규식]
     *   "<[^>]+>" : <b>, </b>, <a href="..."> 등 HTML 태그 전체 제거
     *   "\\s+"    : 연속된 공백(스페이스·탭·줄바꿈)을 하나의 공백으로 축약
     *
     * @param items 원본 뉴스 목록 (30건)
     * @param limit 반환할 최대 건수 (15)
     * @return 중복 제거된 뉴스 목록 (최대 limit건)
     * ============================================================ */
    private List<NewsDTO.NewsItem> deduplicateByTitle(List<NewsDTO.NewsItem> items, int limit) {
        Set<String> seen = new HashSet<>();          // [코드 읽기] 이미 추가된 key 집합
        List<NewsDTO.NewsItem> unique = new ArrayList<>();

        for (NewsDTO.NewsItem item : items) {
            String key = item.getTitle()
                    .replaceAll("<[^>]+>", "") // [코드 읽기] HTML 태그 제거 ("삼성전자 <b>주가</b>" → "삼성전자 주가")
                    .replaceAll("\\s+", " ")   // [코드 읽기] 연속 공백 단일화
                    .trim();
            // [코드 읽기] 앞 25자만 비교 키로 사용 (제목이 짧으면 전체 사용)
            key = key.length() > 25 ? key.substring(0, 25) : key;

            if (seen.add(key)) { // [코드 읽기] HashSet.add(): 새 값이면 true 반환 → 추가
                unique.add(item);
                if (unique.size() == limit) break; // [실행 흐름] 목표 건수 도달 시 조기 종료
            }
        }
        return unique;
    }
}
