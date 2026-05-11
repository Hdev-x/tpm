//package com.tj.app.market.stock;
//
//import java.util.List;
//
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.stereotype.Service;
//
//@Service
//	public class StockService {
//
//	    @Autowired
//	    private WebClientService webClientService;
//
//	    /**
//	     * 사용자의 보유 주식 리스트를 받아서 실시간 시세와 수익률을 계산해주는 메서드
//	     */
//	    public List<AssetDTO> calculateAssets(List<AssetDTO> myAssets) {
//	        // 1. API 접근 토큰 가져오기 (캐싱된 토큰 사용)
//	        String token = webClientService.getAccessToken();
//
//	        // 2. 각 종목별 데이터 요리
//	        for (AssetDTO asset : myAssets) {
//	            StockPriceDTO priceInfo = webClientService.getRealTimePrice(asset.getStockCode(), token);
//	            
//	            if (priceInfo != null && priceInfo.getOutput() != null) {
//	                long nowPrice = Long.parseLong(priceInfo.getOutput().getStck_prpr());
//	                asset.setCurrentPrice(nowPrice);
//	                
//	                // 수익률 계산 로직 (따로 private 메서드로 빼면 더 깔끔!)
//	                asset.setProfitRate(calculateProfitRate(nowPrice, asset.getPurchasePrice()));
//	                asset.setEvaluationAmount(nowPrice * asset.getQuantity());
//	            }
//	        }
//	        return myAssets;
//	    }
//
//	    // 수익률 계산 전용 로직
//	    private double calculateProfitRate(long nowPrice, long purchasePrice) {
//	        if (purchasePrice == 0) return 0.0;
//	        double rate = ((double)(nowPrice - purchasePrice) / purchasePrice) * 100;
//	        return Math.round(rate * 100) / 100.0;
//	    }
//	}
