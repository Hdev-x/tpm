package com.tj.app.market.coin;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
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
        
     // [수정된 부분] 지갑이 없는 경우에 대한 예외 처리 추가
        if (wallet == null) {
            throw new Exception("지갑 정보를 찾을 수 없습니다. 먼저 지갑을 생성해주세요.");
        }

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
        order.setStatus("COMPLETED");
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
            // 전량 매도 → 삭제 + 미체결 주문 일괄 취소
            coinMapper.deleteHolding(existing);
            coinMapper.cancelPendingByCoin(existing.getUsername(), existing.getCoinCode());
        } else {
            existing.setCoinCount(newCount);
            coinMapper.updateHolding(existing);
        }

        // 잔고 추가
        CoinWalletDTO wallet = coinMapper.getWallet(order.getUsername());
        if (wallet == null) {
            throw new Exception("지갑 정보를 찾을 수 없습니다.");
        }
        
        wallet.setUsdtBalance(wallet.getUsdtBalance() + order.getOrderPrice() * order.getOrderCount());
        coinMapper.updateWallet(wallet);

        // 주문 내역 저장
        order.setOrderType("SELL");
        order.setAvgPrice(existing.getAvgPrice());
        order.setStatus("COMPLETED");
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

    public List<CoinOrdersDTO> getPendingOrders(String username) throws Exception {
        return coinMapper.getPendingOrders(username);
    }

    /** 지정가 주문 등록 (미체결) */
    public void limitOrder(CoinOrdersDTO order) throws Exception {
        if ("BUY".equals(order.getOrderType())) {
            // 매수: 잔고 충분한지만 확인 (차감은 체결 시)
            CoinWalletDTO wallet = coinMapper.getWallet(order.getUsername());
            double totalPrice = order.getTargetPrice() * order.getOrderCount();
            if (wallet.getUsdtBalance() < totalPrice) throw new Exception("잔고가 부족합니다.");
        } else {
            // 매도: 보유 수량 충분한지만 확인 (차감은 체결 시)
            CoinHoldingsDTO holding = new CoinHoldingsDTO();
            holding.setUsername(order.getUsername());
            holding.setCoinCode(order.getCoinCode());
            CoinHoldingsDTO existing = coinMapper.getHolding(holding);
            if (existing == null || existing.getCoinCount() < order.getOrderCount())
                throw new Exception("보유 수량이 부족합니다.");
            order.setAvgPrice(existing.getAvgPrice());
        }
        order.setStatus("PENDING");
        coinMapper.insertOrder(order);
    }

    /** 미체결 주문 취소 */
    public void cancelOrder(CoinOrdersDTO order) throws Exception {
        CoinOrdersDTO pending = coinMapper.getPendingOrders(order.getUsername())
                .stream().filter(o -> o.getOrderNo().equals(order.getOrderNo())).findFirst()
                .orElseThrow(() -> new Exception("주문을 찾을 수 없습니다."));
        pending.setStatus("CANCELLED");
        coinMapper.updateOrderStatus(pending);
    }

    /** 지정가 체결 처리 (WebSocket에서 호출) */
    public void executePendingOrder(CoinOrdersDTO order) throws Exception {
        if ("BUY".equals(order.getOrderType())) {
            // 매수 체결: 잔고 차감 + 보유 추가
            CoinWalletDTO wallet = coinMapper.getWallet(order.getUsername());
            double totalPrice = order.getOrderPrice() * order.getOrderCount();
            if (wallet.getUsdtBalance() < totalPrice) throw new Exception("잔고가 부족합니다.");
            wallet.setUsdtBalance(wallet.getUsdtBalance() - totalPrice);
            coinMapper.updateWallet(wallet);
            CoinHoldingsDTO holding = new CoinHoldingsDTO();
            holding.setUsername(order.getUsername());
            holding.setCoinCode(order.getCoinCode());
            CoinHoldingsDTO existing = coinMapper.getHolding(holding);
            if (existing == null) {
                holding.setCoinCount(order.getOrderCount());
                holding.setAvgPrice(order.getOrderPrice());
                coinMapper.insertHolding(holding);
            } else {
                double newCount = existing.getCoinCount() + order.getOrderCount();
                double newAvg = (existing.getAvgPrice() * existing.getCoinCount()
                        + order.getOrderPrice() * order.getOrderCount()) / newCount;
                existing.setCoinCount(newCount);
                existing.setAvgPrice(newAvg);
                coinMapper.updateHolding(existing);
            }
        } else {
            // 매도 체결: 보유 차감 + 잔고 추가
            CoinHoldingsDTO holding = new CoinHoldingsDTO();
            holding.setUsername(order.getUsername());
            holding.setCoinCode(order.getCoinCode());
            CoinHoldingsDTO existing = coinMapper.getHolding(holding);
            if (existing == null || existing.getCoinCount() < order.getOrderCount())
                throw new Exception("보유 수량이 부족합니다.");
            order.setAvgPrice(existing.getAvgPrice());
            double newCount = existing.getCoinCount() - order.getOrderCount();
            if (newCount == 0) { coinMapper.deleteHolding(existing); coinMapper.cancelPendingByCoin(existing.getUsername(), existing.getCoinCode()); }
            else { existing.setCoinCount(newCount); coinMapper.updateHolding(existing); }
            CoinWalletDTO wallet = coinMapper.getWallet(order.getUsername());
            wallet.setUsdtBalance(wallet.getUsdtBalance() + order.getOrderPrice() * order.getOrderCount());
            coinMapper.updateWallet(wallet);
        }
        order.setStatus("COMPLETED");
        coinMapper.updateOrderStatus(order);
    }

    public void updateWallet(CoinWalletDTO wallet) throws Exception {
        coinMapper.updateWallet(wallet);
    }
}