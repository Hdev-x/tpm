package com.tj.app.market.coin;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class CoinService {

    @Autowired
    private CoinMapper coinMapper;

    /**
     * 지갑 잔고 조회
     * @param username 사용자 아이디
     * @return 지갑 정보
     */
    public CoinWalletDTO getWallet(String username) throws Exception {
        return coinMapper.getWallet(username);
    }

    /**
     * 매수 처리
     * @param order 주문 정보
     */
    public void buy(CoinOrdersDTO order) throws Exception {
        // 지갑 잔고 조회
        CoinWalletDTO wallet = coinMapper.getWallet(order.getUsername());

        // 잔고 부족 체크
        double totalPrice = order.getOrderPrice() * order.getOrderCount();
        if (wallet.getUsdtBalance() < totalPrice) {
            throw new Exception("잔고가 부족합니다.");
        }

        // 잔고 차감
        wallet.setUsdtBalance(wallet.getUsdtBalance() - totalPrice);
        coinMapper.updateWallet(wallet);

        // 보유 코인 확인
        CoinHoldingsDTO holding = new CoinHoldingsDTO();
        holding.setUsername(order.getUsername());
        holding.setCoinCode(order.getCoinCode());
        CoinHoldingsDTO existing = coinMapper.getHolding(holding);

        if (existing == null) {
            // 처음 매수 → 추가
            holding.setCoinCount(order.getOrderCount());
            holding.setAvgPrice(order.getOrderPrice());
            coinMapper.insertHolding(holding);
        } else {
            // 추가 매수 → 평단가 갱신
            double newCount = existing.getCoinCount() + order.getOrderCount();
            double newAvg = (existing.getAvgPrice() * existing.getCoinCount()
                    + order.getOrderPrice() * order.getOrderCount()) / newCount;
            existing.setCoinCount(newCount);
            existing.setAvgPrice(newAvg);
            coinMapper.updateHolding(existing);
        }

        // 주문 내역 저장
        order.setOrderType("BUY");
        coinMapper.insertOrder(order);
    }

    /**
     * 매도 처리
     * @param order 주문 정보
     */
    public void sell(CoinOrdersDTO order) throws Exception {
        // 보유 코인 확인
        CoinHoldingsDTO holding = new CoinHoldingsDTO();
        holding.setUsername(order.getUsername());
        holding.setCoinCode(order.getCoinCode());
        CoinHoldingsDTO existing = coinMapper.getHolding(holding);

        // 보유 수량 부족 체크
        if (existing == null || existing.getCoinCount() < order.getOrderCount()) {
            throw new Exception("보유 수량이 부족합니다.");
        }

        // 보유 수량 차감
        double newCount = existing.getCoinCount() - order.getOrderCount();
        if (newCount == 0) {
            // 전량 매도 → 삭제
            coinMapper.deleteHolding(existing);
        } else {
            existing.setCoinCount(newCount);
            coinMapper.updateHolding(existing);
        }

        // 잔고 추가
        CoinWalletDTO wallet = coinMapper.getWallet(order.getUsername());
        wallet.setUsdtBalance(wallet.getUsdtBalance() + order.getOrderPrice() * order.getOrderCount());
        coinMapper.updateWallet(wallet);

        // 주문 내역 저장
        order.setOrderType("SELL");
        coinMapper.insertOrder(order);
    }

    /**
     * 보유 코인 목록 조회
     * @param username 사용자 아이디
     * @return 보유 코인 목록
     */
    public List<CoinHoldingsDTO> getHoldingList(String username) throws Exception {
        return coinMapper.getHoldingList(username);
    }

    /**
     * 주문 내역 조회
     * @param username 사용자 아이디
     * @return 주문 내역 목록
     */
    public List<CoinOrdersDTO> getOrderList(String username) throws Exception {
        return coinMapper.getOrderList(username);
    }
}