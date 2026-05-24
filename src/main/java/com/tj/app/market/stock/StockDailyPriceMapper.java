package com.tj.app.market.stock;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

/** ============================================================
 * [클래스 읽기] STOCK_DAILY_PRICE 테이블의 CRUD를 담당하는 MyBatis Mapper.
 *
 * XML 없이 어노테이션(@Insert, @Select)으로 SQL을 직접 작성한다.
 * Java 15+ 텍스트 블록(""" ... """)으로 여러 줄 SQL을 가독성 있게 표현한다.
 *
 * [테이블 역할]
 * KIS API에서 가져온 일별 종가를 주기적으로 저장해두는 캐시 테이블.
 * 매번 외부 API를 호출하는 대신 DB에서 빠르게 조회할 수 있다.
 * ============================================================ */
@Mapper
public interface StockDailyPriceMapper {

    /** ============================================================
     * 일별 종가 데이터를 UPSERT(삽입 또는 수정)한다.
     *
     * [실행 흐름]
     * INSERT 시도 → (STOCK_CODE, TRADE_DATE)가 이미 존재하면 CONFLICT 발생
     * → DO UPDATE: CLOSE_PRICE, VOLUME, UPDATED_AT 을 새 값으로 덮어쓴다.
     * EXCLUDED: 충돌된 새 INSERT 값을 참조하는 PostgreSQL 키워드
     *
     * @param item 저장할 일별 가격 데이터
     * @return 영향받은 행 수 (삽입=1, 수정=1)
     * ============================================================ */
    @Insert("""
            INSERT INTO "STOCK_DAILY_PRICE" ("STOCK_CODE", "TRADE_DATE", "CLOSE_PRICE", "VOLUME", "UPDATED_AT")
            VALUES (#{item.stockCode}, #{item.tradeDate}, #{item.closePrice}, #{item.volume}, now())
            ON CONFLICT ("STOCK_CODE", "TRADE_DATE")
            DO UPDATE SET
                "CLOSE_PRICE" = EXCLUDED."CLOSE_PRICE",
                "VOLUME" = EXCLUDED."VOLUME",
                "UPDATED_AT" = now()
            """)
    int upsert(@Param("item") StockDailyPriceDTO item);

    /** ============================================================
     * 특정 종목의 최근 1년치 일별 종가를 날짜 오름차순으로 조회한다.
     *
     * [실행 흐름]
     * CURRENT_DATE - INTERVAL '1 year' → 오늘로부터 1년 전 이후 데이터만 조회
     * AS "camelCase" → DB 컬럼명(대문자)을 DTO 필드명(camelCase)으로 매핑
     * ORDER BY TRADE_DATE → 차트에서 날짜 순서대로 그리기 위해 오름차순 정렬
     *
     * @param stockCode 조회할 종목 코드 (예: "005930")
     * ============================================================ */
    @Select("""
            SELECT
                "STOCK_CODE" AS "stockCode",
                "TRADE_DATE" AS "tradeDate",
                "CLOSE_PRICE" AS "closePrice",
                "VOLUME" AS "volume"
            FROM "STOCK_DAILY_PRICE"
            WHERE "STOCK_CODE" = #{stockCode}
              AND "TRADE_DATE" >= CURRENT_DATE - INTERVAL '1 year'
            ORDER BY "TRADE_DATE"
            """)
    List<StockDailyPriceDTO> findOneYearByStockCode(@Param("stockCode") String stockCode);

    /** ============================================================
     * 여러 종목의 최신 종가와 직전 종가를 한 번에 조회한다.
     *
     * [사용 위치]
     * 주식 리스트/사이드바에서 WebSocket 실시간 캐시가 비어 있을 때
     * 장 마감 후 마지막 종가를 fallback 가격으로 표시하기 위해 사용한다.
     *
     * [실행 흐름]
     * 1. 요청 종목 코드만 STOCK_DAILY_PRICE에서 조회
     * 2. 종목별 최신 거래일 순으로 번호(row_number)를 매김
     * 3. lead(close)로 최신 종가 바로 이전 거래일의 종가를 함께 가져옴
     * 4. rn=1만 반환 → 종목당 1행
     *
     * @param codes 조회할 종목 코드 목록
     * ============================================================ */
    @Select("""
            <script>
            WITH ranked AS (
                SELECT
                    "STOCK_CODE",
                    "CLOSE_PRICE",
                    "VOLUME",
                    row_number() OVER (
                        PARTITION BY "STOCK_CODE"
                        ORDER BY "TRADE_DATE" DESC
                    ) AS rn,
                    lead("CLOSE_PRICE") OVER (
                        PARTITION BY "STOCK_CODE"
                        ORDER BY "TRADE_DATE" DESC
                    ) AS "PREV_CLOSE_PRICE"
                FROM "STOCK_DAILY_PRICE"
                WHERE "STOCK_CODE" IN
                <foreach collection="codes" item="code" open="(" separator="," close=")">
                    #{code}
                </foreach>
            )
            SELECT
                "STOCK_CODE" AS "stockCode",
                "CLOSE_PRICE" AS "closePrice",
                "PREV_CLOSE_PRICE" AS "prevClosePrice",
                "VOLUME" AS "volume"
            FROM ranked
            WHERE rn = 1
            </script>
            """)
    List<Map<String, Object>> findLatestCloseRowsByCodes(@Param("codes") List<String> codes);
}
