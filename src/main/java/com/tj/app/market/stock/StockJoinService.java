package com.tj.app.market.stock;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Map;

@Service
public class StockJoinService {

    @Autowired
    private StockJoinMapper stockJoinMapper;

    /**
     * 🔍 프론트엔드가 보낸 검색어로 Supabase에서 주식 코드를 가져오는 관문
     */
    public String getCode(String cleanKeyword) {
        if (cleanKeyword == null || cleanKeyword.isEmpty()) {
            return "005930";
        }
        try {
            String processedKeyword = cleanKeyword.toLowerCase().replaceAll("\\s+", "");
            String code = stockJoinMapper.findCodeByCleanName(processedKeyword);
            return (code != null) ? code : "005930";
        } catch (Exception e) {
            return "005930";
        }
    }

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

    public List<Map<String, Object>> getAllStocks() {
        try {
            return stockJoinMapper.findAllStocks();
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    public List<Map<String, Object>> getTop40Stocks() {
        try {
            return stockJoinMapper.findTop40Stocks();
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }
}