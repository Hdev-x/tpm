package com.tj.app.market.exchange;

import com.tj.app.market.coin.order.CoinMapper;
import com.tj.app.market.coin.order.CoinWalletDTO;
import com.tj.app.market.stock.order.OrderStockMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** ============================================================
 * [클래스 읽기] 주식(KRW) ↔ 코인(USDT) 간 환전을 처리하는 서비스.
 *
 * [환전 구조]
 * - 주식 예수금(KRW): OrderStockMapper.getWallet / updateWallet 으로 관리
 * - 코인 지갑(USDT):  CoinMapper.getWallet / updateWallet 으로 관리
 * - 환율(rate): Controller에서 외부 API로 받은 현재 USD/KRW 환율을 파라미터로 전달
 *
 * [@Transactional] 두 DB 업데이트(주식 + 코인)를 하나의 트랜잭션으로 묶는다.
 *   중간에 예외가 발생하면 두 업데이트 모두 롤백되어 잔액 불일치를 방지한다.
 * ============================================================ */
@Slf4j
@Service
public class ExchangeService {

    @Autowired
    private OrderStockMapper stockMapper;

    @Autowired
    private CoinMapper coinMapper;

    /** ============================================================
     * KRW → USDT 환전.
     * 주식 예수금(KRW) 차감 + 코인 지갑(USDT) 증가.
     *
     * [실행 흐름]
     * 1. 주식 예수금 조회 → 잔액 부족이면 예외
     * 2. 코인 지갑 존재 여부 확인 → 없으면 예외
     * 3. usdtAmount = krwAmount / rate (원화를 달러로 환산)
     * 4. 주식 예수금 차감 + 코인 USDT 잔액 증가 → 각각 DB 업데이트
     *
     * @param username  사용자 아이디
     * @param krwAmount 환전할 원화 금액
     * @param rate      현재 USD/KRW 환율 (예: 1380.0)
     * ============================================================ */
    @Transactional
    public void krwToUsdt(String username, long krwAmount, double rate) throws Exception {
        long stockCash = stockMapper.getWallet(username);
        if (stockCash < krwAmount) throw new Exception("주식 예수금이 부족합니다.");

        CoinWalletDTO wallet = coinMapper.getWallet(username);
        if (wallet == null) throw new Exception("코인 지갑이 존재하지 않습니다.");

        double usdtAmount = krwAmount / rate; // [실행 흐름] KRW → USDT 환산

        stockMapper.updateWallet(username, stockCash - krwAmount); // 주식 예수금 차감
        wallet.setUsdtBalance(wallet.getUsdtBalance() + usdtAmount); // USDT 잔액 증가
        coinMapper.updateWallet(wallet);
    }

    /** ============================================================
     * USDT → KRW 환전.
     * 코인 지갑(USDT) 차감 + 주식 예수금(KRW) 증가.
     *
     * [실행 흐름]
     * 1. 코인 지갑 존재 및 USDT 잔액 확인 → 부족하면 예외
     * 2. krwAmount = (long)(usdtAmount × rate) (달러를 원화로 환산, 소수점 버림)
     * 3. USDT 잔액 차감 + 주식 예수금 증가 → 각각 DB 업데이트
     *
     * @param username   사용자 아이디
     * @param usdtAmount 환전할 USDT 금액
     * @param rate       현재 USD/KRW 환율
     * ============================================================ */
    @Transactional
    public void usdtToKrw(String username, double usdtAmount, double rate) throws Exception {
        CoinWalletDTO wallet = coinMapper.getWallet(username);
        if (wallet == null) throw new Exception("코인 지갑이 존재하지 않습니다.");
        if (wallet.getUsdtBalance() < usdtAmount) throw new Exception("코인 투자금이 부족합니다.");

        long krwAmount = (long)(usdtAmount * rate); // [실행 흐름] USDT → KRW 환산 (소수점 버림)
        long stockCash = stockMapper.getWallet(username);

        wallet.setUsdtBalance(wallet.getUsdtBalance() - usdtAmount); // USDT 잔액 차감
        coinMapper.updateWallet(wallet);
        stockMapper.updateWallet(username, stockCash + krwAmount);    // 주식 예수금 증가
    }
}
