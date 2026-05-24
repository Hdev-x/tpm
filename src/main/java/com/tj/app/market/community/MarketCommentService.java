package com.tj.app.market.community;

import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/** ============================================================
 * [클래스 읽기] 댓글 작성·수정·삭제·조회·좋아요 토글 비즈니스 로직을 담당하는 서비스.
 *
 * [의존성]
 *   MarketCommentMapper    : 댓글 CRUD SQL
 *   MarketCommentLikeMapper: 좋아요 삽입·삭제·카운트 SQL
 *
 * [@Transactional 없음]
 *   각 메서드가 단일 DB 작업(insert/update/delete)이라 트랜잭션이 반드시 필요하지 않다.
 *   toggleLike()는 check→insert/delete→count 3단계이지만,
 *   좋아요 토글 실패 시 롤백해야 하는 중요 비즈니스 데이터가 아니어서 현재는 @Transactional 미적용.
 * ============================================================ */
@Service
public class MarketCommentService {

    @Autowired
    private MarketCommentMapper mapper;

    @Autowired
    private MarketCommentLikeMapper likeMapper;

    /** ============================================================
     * 새 댓글을 저장한다.
     *
     * [실행 흐름]
     * 1. dto에 서버 측 username 설정 (클라이언트에서 받은 값 무시 → 보안)
     * 2. DB에 INSERT → MyBatis가 생성된 PK(commentNo)를 dto에 자동 채워줌
     * 3. dto.type = "NEW" 설정 → 컨트롤러에서 WebSocket 브로드캐스트 시 구분용
     * 4. 저장된 dto 반환 (commentNo·type이 채워진 상태)
     *
     * @param dto      작성된 댓글 내용 (content, marketType, marketCode, imageUrl 포함)
     * @param username 세션에서 가져온 실제 로그인 사용자 아이디
     * @return commentNo·type이 채워진 저장 완료 DTO
     * ============================================================ */
    public MarketCommentDTO save(MarketCommentDTO dto, String username) throws Exception {
        dto.setUsername(username);       // [보안] 서버 측 username으로 설정
        mapper.insert(dto);              // [실행 흐름] INSERT → commentNo 자동 채워짐
        dto.setType("NEW");              // [실행 흐름] 브로드캐스트 타입 표시
        return dto;
    }

    /** ============================================================
     * 기존 댓글을 수정한다.
     *
     * [실행 흐름]
     * 1. username 설정 (SQL WHERE 절에서 본인 댓글만 수정하도록 검증)
     * 2. UPDATE 실행
     * 3. type="UPDATE" → 브로드캐스트 시 JS가 기존 댓글 요소를 교체하도록 신호
     *
     * @param dto      수정 내용 (commentNo, content, imageUrl 포함)
     * @param username 세션에서 가져온 실제 로그인 사용자 아이디
     * @return 수정 완료 DTO (type="UPDATE" 포함)
     * ============================================================ */
    public MarketCommentDTO update(MarketCommentDTO dto, String username) throws Exception {
        dto.setUsername(username);
        mapper.update(dto);
        dto.setType("UPDATE");           // [실행 흐름] 브로드캐스트 타입 표시
        return dto;
    }

    /** ============================================================
     * 댓글을 삭제한다.
     *
     * [보안] Mapper의 delete()는 commentNo + username 두 조건 모두 일치해야 삭제된다.
     *   → 타인이 commentNo만 알아도 본인 것만 삭제되고 타인 댓글은 삭제 불가.
     *
     * [void 반환] 삭제 후 별도로 반환할 데이터가 없으므로 void.
     *   컨트롤러에서 직접 type="DELETE" DTO를 만들어 브로드캐스트한다.
     * ============================================================ */
    public void delete(Long commentNo, String username) throws Exception {
        mapper.delete(commentNo, username);
    }

    /** ============================================================
     * 특정 종목·마켓의 댓글 목록을 정렬 기준에 따라 조회한다.
     *
     * [실행 흐름]
     * 1. sort="popular" → listByCodePopular() (좋아요 수 내림차순)
     *    그 외 (기본: "latest") → listByCode() (최신 순)
     * 2. username이 있으면 (로그인 상태) 각 댓글에 likedByMe 플래그를 채운다.
     *    likeMapper.check() > 0 이면 현재 사용자가 좋아요를 누른 댓글.
     * 3. username이 null이면 (비로그인) likedByMe는 기본값 false 유지.
     *
     * [성능 주의] 댓글 수만큼 likeMapper.check() 호출 → N+1 문제.
     *   댓글이 많아지면 배치 조회나 JOIN으로 개선이 필요하다.
     *
     * @param marketType  "COIN" 또는 "STOCK"
     * @param marketCode  종목 코드 (예: "BTCUSDT", "005930")
     * @param sort        정렬 기준 ("latest" 또는 "popular")
     * @param username    로그인한 사용자 아이디 (비로그인이면 null)
     * @return 댓글 목록 (likedByMe 포함)
     * ============================================================ */
    public List<MarketCommentDTO> listByCode(String marketType, String marketCode,
                                              String sort, String username) throws Exception {
        // [실행 흐름] 정렬 기준에 따라 다른 Mapper 메서드 호출
        List<MarketCommentDTO> list = "popular".equals(sort)
                ? mapper.listByCodePopular(marketType, marketCode)
                : mapper.listByCode(marketType, marketCode);

        // [실행 흐름] 로그인 상태일 때만 likedByMe 플래그 설정
        if (username != null && !username.isEmpty()) {
            for (MarketCommentDTO dto : list) {
                // [코드 읽기] check() > 0이면 이 사용자가 해당 댓글에 좋아요를 눌렀음
                dto.setLikedByMe(likeMapper.check(dto.getCommentNo(), username) > 0);
            }
        }
        return list;
    }

    /** ============================================================
     * 댓글 좋아요를 토글(추가↔취소)한다.
     *
     * [실행 흐름]
     * 1. check() → 이미 좋아요가 있으면 delete() (좋아요 취소), liked=false
     *              없으면 insert() (좋아요 추가), liked=true
     * 2. count() → 최신 좋아요 수 재조회
     * 3. { "liked": true/false, "count": N } 형태의 Map 반환
     *    JS는 이 값을 받아 하트 아이콘 상태와 카운트를 즉시 갱신한다.
     *
     * [Map.of()] Java 9+. 수정 불가능한 불변 Map을 간단히 생성한다.
     *
     * @param commentNo 좋아요를 토글할 댓글 번호
     * @param username  요청한 사용자 아이디
     * @return { "liked": boolean, "count": long }
     * ============================================================ */
    public Map<String, Object> toggleLike(Long commentNo, String username) throws Exception {
        boolean liked;
        if (likeMapper.check(commentNo, username) > 0) {
            // [실행 흐름] 이미 좋아요 → 취소
            likeMapper.delete(commentNo, username);
            liked = false;
        } else {
            // [실행 흐름] 좋아요 없음 → 추가
            likeMapper.insert(commentNo, username);
            liked = true;
        }
        long count = likeMapper.count(commentNo); // [실행 흐름] 변경 후 최신 카운트 조회
        return Map.of("liked", liked, "count", count); // [코드 읽기] 불변 Map 생성 (Java 9+)
    }
}
