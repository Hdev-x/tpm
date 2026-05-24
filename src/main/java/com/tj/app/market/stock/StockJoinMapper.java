package com.tj.app.market.stock;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

/** ============================================================
 * [클래스 읽기] STOCK 테이블(종목 코드-이름 매핑)을 조회하는 MyBatis Mapper.
 *
 * [역할]
 * KIS API는 종목 코드(6자리)를 기준으로 동작하지만,
 * 사용자는 종목명으로 검색한다. 이 Mapper가 이름 ↔ 코드 변환을 담당한다.
 *
 * [테이블 구조] STOCK("STOCK_CODE", "STOCK_NAME")
 * PostgreSQL은 대소문자를 구분하므로 컬럼명을 큰따옴표로 감싼다.
 * ============================================================ */
@Mapper
public interface StockJoinMapper {

    /** ============================================================
     * 종목명(검색어) → 종목 코드 변환.
     *
     * [실행 흐름]
     * LOWER(REPLACE(STOCK_NAME, ' ', '')) → 공백 제거 + 소문자 변환
     * 예: "삼성 전자" → "삼성전자", "Samsung" → "samsung"
     * 사용자가 공백·대소문자를 섞어도 일치하도록 정규화 후 비교한다.
     * cleanKeyword: Java쪽에서 이미 공백 제거 + 소문자 변환된 값이 넘어온다.
     * ============================================================ */
    @Select("SELECT \"STOCK_CODE\" FROM \"STOCK\" " +
            "WHERE LOWER(REPLACE(\"STOCK_NAME\", ' ', '')) = #{cleanKeyword}")
    String findCodeByCleanName(@Param("cleanKeyword") String cleanKeyword);

    /** ============================================================
     * 종목 코드 → 종목명 변환.
     * KIS API 응답의 6자리 코드를 사람이 읽을 수 있는 이름으로 바꿀 때 사용한다.
     * ============================================================ */
    @Select("SELECT \"STOCK_NAME\" FROM \"STOCK\" " +
            "WHERE \"STOCK_CODE\" = #{code}")
    String findNameByStockCode(@Param("code") String code);

    /** ============================================================
     * 전체 종목 목록을 코드 오름차순으로 조회한다.
     * AS code, AS name → Map의 키 이름을 지정 → JS에서 data.code, data.name으로 접근
     * ============================================================ */
    @Select("SELECT \"STOCK_CODE\" AS code, \"STOCK_NAME\" AS name FROM \"STOCK\" ORDER BY \"STOCK_CODE\"")
    List<Map<String, Object>> findAllStocks();

    /** ============================================================
     * 상위 40개 종목만 조회한다.
     * 종목 선택 드롭다운 등 초기 로딩 시 전체 수백 개를 내려주지 않고 40개만 반환한다.
     * ============================================================ */
    @Select("SELECT \"STOCK_CODE\" AS code, \"STOCK_NAME\" AS name FROM \"STOCK\" LIMIT 40")
    List<Map<String, Object>> findTop40Stocks();
}