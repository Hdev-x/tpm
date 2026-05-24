package com.tj.app.market.community;

import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

/** ============================================================
 * [클래스 읽기] 코인·주식 커뮤니티 댓글 한 건을 담는 DTO.
 *
 * [Lombok 개별 애노테이션]
 *   @Getter : 모든 필드에 getXxx() 자동 생성
 *   @Setter : 모든 필드에 setXxx() 자동 생성
 *   @ToString : toString() 자동 생성 (디버깅용 로그 출력)
 *   @Data를 쓰지 않은 이유: @Data는 @EqualsAndHashCode도 포함해 ID 기반 비교가 필요 없는 경우
 *   원하지 않는 동작이 생길 수 있으므로 필요한 애노테이션만 골라 사용하는 패턴이다.
 *
 * [관련 테이블] MARKET_COMMENTS (댓글 본문) + 조인으로 가져오는 필드 포함
 *
 * [DB 컬럼이 아닌 필드들] — 서비스 로직에서 동적으로 채워진다.
 *   likeCount   : 집계 쿼리(COUNT) 결과로 채움
 *   likedByMe   : MarketCommentLikeMapper.check()로 채움 (로그인 사용자가 좋아요 눌렀는지)
 *   profileFileName : ProfileService에서 별도 조회해 채움 (댓글 작성자 프로필 이미지)
 *   type        : DB에 저장하지 않음. WebSocket 브로드캐스트 시 NEW/UPDATE/DELETE 구분용
 * ============================================================ */
@Getter
@Setter
@ToString
public class MarketCommentDTO {

    private Long commentNo;      // 댓글 고유 번호 (PK)

    /** 댓글이 달린 마켓 종류. "COIN" 또는 "STOCK"
     *  하나의 DTO·테이블이 두 마켓을 공용으로 처리한다. */
    private String marketType;

    /** 댓글이 달린 종목 코드. 코인="BTCUSDT", 주식="005930" 등 */
    private String marketCode;

    private String content;        // 댓글 본문
    private String username;       // 작성자 아이디 (FK)
    private LocalDateTime createdAt; // 작성 일시 (Java 8 날짜 타입. String보다 정렬/비교가 쉽다)
    private String imageUrl;       // 댓글 첨부 이미지 URL (없으면 null)
    private String profileFileName; // 작성자 프로필 이미지 파일명 (ProfileService에서 별도 조회)

    /** 이 댓글의 좋아요 수. 집계 쿼리(COUNT) 결과로 채운다. */
    private long likeCount;

    /** 현재 로그인한 사용자가 이 댓글에 좋아요를 눌렀으면 true.
     *  MarketCommentLikeMapper.check()로 판별한다. 비로그인 시 항상 false. */
    private boolean likedByMe;

    /** WebSocket 브로드캐스트 전용 필드 (DB에 저장하지 않음).
     *  "NEW"(새 댓글), "UPDATE"(수정), "DELETE"(삭제) 중 하나.
     *  JS에서 이 값을 보고 댓글 목록에 추가/교체/제거를 처리한다. */
    private String type;
}
