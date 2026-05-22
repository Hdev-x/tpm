package com.tj.app.market.exchange;

import com.tj.app.market.coin.order.CoinMapper;
import com.tj.app.market.coin.order.CoinWalletDTO;
import com.tj.app.market.stock.order.OrderStockMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
public class ExchangeService {

    @Autowired
    private OrderStockMapper stockMapper;

    @Autowired
    private CoinMapper coinMapper;

    /**
     * KRW → USDT 환전
     * 주식 예수금(KRW) 차감 + 코인 지갑(USDT) 증가
     */
    @Transactional
    public void krwToUsdt(String username, long krwAmount, double rate) throws Exception {
        long stockCash = stockMapper.getWallet(username);
        if (stockCash < krwAmount) throw new Exception("주식 예수금이 부족합니다.");

        CoinWalletDTO wallet = coinMapper.getWallet(username);
        if (wallet == null) throw new Exception("코인 지갑이 존재하지 않습니다.");

        double usdtAmount = krwAmount / rate;

        stockMapper.updateWallet(username, stockCash - krwAmount);
        wallet.setUsdtBalance(wallet.getUsdtBalance() + usdtAmount);
        coinMapper.updateWallet(wallet);
    }

    /**
     * USDT → KRW 환전
     * 코인 지갑(USDT) 차감 + 주식 예수금(KRW) 증가
     */
    @Transactional
    public void usdtToKrw(String username, double usdtAmount, double rate) throws Exception {
        CoinWalletDTO wallet = coinMapper.getWallet(username);
        if (wallet == null) throw new Exception("코인 지갑이 존재하지 않습니다.");
        if (wallet.getUsdtBalance() < usdtAmount) throw new Exception("코인 투자금이 부족합니다.");

        long krwAmount = (long)(usdtAmount * rate);
        long stockCash = stockMapper.getWallet(username);

        wallet.setUsdtBalance(wallet.getUsdtBalance() - usdtAmount);
        coinMapper.updateWallet(wallet);
        stockMapper.updateWallet(username, stockCash + krwAmount);
    }
}
