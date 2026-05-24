package com.tj.app.market.stock;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Map;

/** ============================================================
 * [클래스 읽기] 종목 이름 ↔ 코드 변환과 종목 목록 조회를 담당하는 서비스.
 *
 * StockJoinMapper를 감싸 예외 처리와 기본값(폴백)을 제공한다.
 * DB 조회 실패 시 예외를 던지지 않고 기본값(삼성전자 005930 등)을 반환해
 * 화면이 깨지지 않도록 방어한다.
 * ============================================================ */
@Service
public class StockJoinService {

    @Autowired
    private StockJoinMapper stockJoinMapper;

    /** ============================================================
     * 검색어(종목명)를 종목 코드로 변환한다.
     *
     * [실행 흐름]
     * 1. null 또는 빈 문자열이면 기본값 "005930"(삼성전자) 반환
     * 2. 소문자 변환 + 공백 제거 후 DB에서 코드 검색
     * 3. 코드 없거나 예외 발생 시 "005930" 반환
     *
     * @param cleanKeyword 사용자가 입력한 검색어 (공백·대소문자 무관)
     * ============================================================ */
    public String getCode(String cleanKeyword) {
        if (cleanKeyword == null || cleanKeyword.isEmpty()) {
            return "005930"; // 기본값: 삼성전자
        }
        try {
            // [실행 흐름] DB 쿼리와 동일한 정규화(소문자+공백제거) 적용 후 조회
            String processedKeyword = cleanKeyword.toLowerCase().replaceAll("\\s+", "");
            String code = stockJoinMapper.findCodeByCleanName(processedKeyword);
            return (code != null) ? code : "005930";
        } catch (Exception e) {
            return "005930";
        }
    }

    /** ============================================================
     * 종목 코드를 종목명으로 변환한다.
     * KIS API 응답의 코드를 화면에 표시할 이름으로 바꿀 때 사용한다.
     * ============================================================ */
    public String getName(String code) {
        if (code == null || code.isEmpty()) {
            return "종목명 없음";
        }
        try {
            String name = stockJoinMapper.findNameByStockCode(code);
            return (name != null) ? name : "알 수 없는 종목";
        } catch (Exception e) {
            return "알 수 없는 종목";
        }
    }

    /** ============================================================
     * 전체 종목 목록을 반환한다.
     * 예외 발생 시 빈 리스트 반환 → 화면이 에러 없이 빈 목록을 표시한다.
     * ============================================================ */
    public List<Map<String, Object>> getAllStocks() {
        try {
            return stockJoinMapper.findAllStocks();
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    /** ============================================================
     * 상위 40개 종목 목록을 반환한다.
     * 초기 화면 로딩 시 전체 종목 대신 대표 40개만 내려보낸다.
     * ============================================================ */
    public List<Map<String, Object>> getTop40Stocks() {
        try {
            return stockJoinMapper.findTop40Stocks();
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }
}