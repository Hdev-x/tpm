package com.tj.app.market.stock;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class StockJoinService {

    @Autowired
    private StockJoinMapper stockJoinMapper;

    /**
     * 🔍 프론트엔드가 보낸 검색어로 Supabase에서 주식 코드를 가져오는 관문
     */
    public String getCode(String cleanKeyword) {
        if (cleanKeyword == null || cleanKeyword.isEmpty()) {
            return "005930"; // 검색어가 빈 값이면 기본값 삼성전자
        }

        // 안전을 위해 자바단에서도 대소문자 및 공백 정제 후 매퍼 전송
        String processedKeyword = cleanKeyword.toLowerCase().replaceAll("\\s+", "");
        
        String code = stockJoinMapper.findCodeByCleanName(processedKeyword);
        
        // 🛡️ [데이터 미존재 방어] DB에서 못 찾으면 에러로 터뜨리지 않고 삼성전자 코드로 복귀
        return (code != null) ? code : "005930";
    }

    /**
     * 📛 차트 상단 레이블에 이쁜 진짜 종목 한글 이름을 뿌려주기 위한 관문
     */
    public String getName(String code) {
        if (code == null || code.isEmpty()) {
            return "종목명 없음";
        }

        String name = stockJoinMapper.findNameByStockCode(code);
        
        // 🛡️ 혹시 수급된 코드가 DB에 없으면 '알 수 없는 종목'으로 가드
        return (name != null) ? name : "알 수 없는 종목";
    }
}