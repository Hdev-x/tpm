package com.tj.app.market.coin.order;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** ============================================================
 * [클래스 읽기] 코인 매수·매도·보유 조회 등 비즈니스 로직을 담당하는 서비스.
 *
 * [@Transactional 클래스 레벨]
 * 모든 public 메서드가 기본적으로 트랜잭션 안에서 실행된다.
 * 중간에 예외가 발생하면 지갑 차감·보유 수량 변경·주문 삽입이 모두 롤백된다.
 *
 * [주식 Service와의 차이점]
 * 코인: 시장가 즉시 체결만 지원 → buy()/sell() 호출 즉시 DB 반영
 * 주식: 지정가 PENDING → OrderScheduler가 주기적으로 체결 처리
 *
 * [평단가 계산 공식]
 * 가중평균 = (기존보유금액 + 신규매수금액) / 총수량
 * 주식과 동일한 방식이지만 double 타입 사용 (소수점 수량 허용)
 * ============================================================ */
@Service
@Transactional
public class CoinService {

    @Autowired
    private CoinMapper coinMapper;

    /** ============================================================
     * 코인 지갑(USDT 잔고) 조회.
     * ExchangeService에서 환전 시에도 호출한다.
     * ============================================================ */
    public CoinWalletDTO getWallet(String username) throws Exception {
        return coinMapper.getWallet(username);
    }

    /** ============================================================
     * 코인 매수 처리 (시장가 즉시 체결).
     *
     * [실행 흐름]
     * 1. 지갑 조회 → null이면 예외 (미생성 지갑)
     * 2. totalPrice = orderPrice × orderCount → 잔고 부족 체크
     * 3. USDT 잔고 차감
     * 4. 보유 현황 조회 → null이면 insertHolding(), 있으면 평단가 재계산 후 updateHolding()
     * 5. COIN_ORDERS에 "BUY"/"COMPLETED" 상태로 기록
     * ============================================================ */
    public void buy(CoinOrdersDTO order) throws Exception {
        CoinWalletDTO wallet = coinMapper.getWallet(order.getUsername());

        if (wallet == null) {
            throw new Exception("지갑 정보를 찾을 수 없습니다. 먼저 지갑을 생성해주세요.");
        }

        double totalPrice = order.getOrderPrice() * order.getOrderCount();
        if (wallet.getUsdtBalance() < totalPrice) {
            throw new Exception("잔고가 부족합니다.");
        }

        // [실행 흐름] USDT 잔고 차감
        wallet.setUsdtBalance(wallet.getUsdtBalance() - totalPrice);
        coinMapper.updateWallet(wallet);

        // [실행 흐름] 보유 여부 확인 → 신규 or 추가 매수 분기
        CoinHoldingsDTO holding = new CoinHoldingsDTO();
        holding.setUsername(order.getUsername());
        holding.setCoinCode(order.getCoinCode());
        CoinHoldingsDTO existing = coinMapper.getHolding(holding);

        if (existing == null) {
            // [실행 흐름] 처음 매수 → 신규 보유 행 삽입
            holding.setCoinCount(order.getOrderCount());
            holding.setAvgPrice(order.getOrderPrice());
            coinMapper.insertHolding(holding);
        } else {
            // [실행 흐름] 추가 매수 → 가중평균 평단가 재계산
            double newCount = existing.getCoinCount() + order.getOrderCount();
            double newAvg   = (existing.getAvgPrice() * existing.getCoinCount()
                             + order.getOrderPrice() * order.getOrderCount()) / newCount;
            existing.setCoinCount(newCount);
            existing.setAvgPrice(newAvg);
            coinMapper.updateHolding(existing);
        }

        order.setOrderType("BUY");
        order.setStatus("COMPLETED");
        coinMapper.insertOrder(order);
    }

    /** ============================================================
     * 코인 매도 처리 (시장가 즉시 체결).
     *
     * [실행 흐름]
     * 1. 보유 현황 조회 → null이거나 수량 부족이면 예외
     * 2. 수량 차감: 전량 매도 → deleteHolding(), 일부 → updateHolding()
     * 3. 매도 대금 = orderPrice × orderCount → USDT 잔고 증가
     * 4. COIN_ORDERS에 "SELL"/"COMPLETED" + avgPrice(매수 평단가) 저장
     *    avgPrice는 나중에 손익 계산에 사용할 수 있다.
     * ============================================================ */
    public void sell(CoinOrdersDTO order) throws Exception {
        CoinHoldingsDTO holding = new CoinHoldingsDTO();
        holding.setUsername(order.getUsername());
        holding.setCoinCode(order.getCoinCode());
        CoinHoldingsDTO existing = coinMapper.getHolding(holding);

        if (existing == null || existing.getCoinCount() < order.getOrderCount()) {
            throw new Exception("보유 수량이 부족합니다.");
        }

        double newCount = existing.getCoinCount() - order.getOrderCount();
        if (newCount == 0) {
            // [실행 흐름] 전량 매도 → 보유 행 삭제 + 미체결 관련 주문 취소
            coinMapper.deleteHolding(existing);
            coinMapper.cancelPendingByCoin(existing.getUsername(), existing.getCoinCode());
        } else {
            existing.setCoinCount(newCount);
            coinMapper.updateHolding(existing);
        }

        // [실행 흐름] 매도 대금을 USDT 잔고에 추가
        CoinWalletDTO wallet = coinMapper.getWallet(order.getUsername());
        if (wallet == null) {
            throw new Exception("지갑 정보를 찾을 수 없습니다.");
        }
        wallet.setUsdtBalance(wallet.getUsdtBalance() + order.getOrderPrice() * order.getOrderCount());
        coinMapper.updateWallet(wallet);

        // [실행 흐름] 매도 기록 저장 (avgPrice = 매수 평단가 → 손익 계산용)
        order.setOrderType("SELL");
        order.setAvgPrice(existing.getAvgPrice()); // 기존 평단가를 거래 기록에 저장
        order.setStatus("COMPLETED");
        coinMapper.insertOrder(order);
    }

    /** ============================================================
     * 보유 코인 목록 조회.
     * 사이드바·보유 현황 화면·자산 계산에 사용한다.
     * ============================================================ */
    public List<CoinHoldingsDTO> getHoldingList(String username) throws Exception {
        return coinMapper.getHoldingList(username);
    }

    /** ============================================================
     * 코인 거래 내역 목록 조회.
     * ============================================================ */
    public List<CoinOrdersDTO> getOrderList(String username) throws Exception {
        return coinMapper.getOrderList(username);
    }

    /** ============================================================
     * 미체결 코인 주문 목록 조회 (예비 기능, 현재 미사용).
     * ============================================================ */
    public List<CoinOrdersDTO> getPendingOrders(String username) throws Exception {
        return coinMapper.getPendingOrders(username);
    }

    /** ============================================================
     * 지정가 주문 등록 (예비 기능, 현재 UI에서 미사용).
     * 잔고/수량 검증 후 PENDING 상태로 DB에 저장한다.
     * 실제 체결은 executePendingOrder()에서 처리한다.
     * ============================================================ */
    public void limitOrder(CoinOrdersDTO order) throws Exception {
        if ("BUY".equals(order.getOrderType())) {
            CoinWalletDTO wallet = coinMapper.getWallet(order.getUsername());
            double totalPrice = order.getTargetPrice() * order.getOrderCount();
            if (wallet.getUsdtBalance() < totalPrice) throw new Exception("잔고가 부족합니다.");
        } else {
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

    /** ============================================================
     * 미체결 지정가 주문 취소 (예비 기능, 현재 미사용).
     * stream().filter()로 해당 주문번호를 찾아 CANCELLED 상태로 업데이트한다.
     * ============================================================ */
    public void cancelOrder(CoinOrdersDTO order) throws Exception {
        CoinOrdersDTO pending = coinMapper.getPendingOrders(order.getUsername())
                .stream().filter(o -> o.getOrderNo().equals(order.getOrderNo())).findFirst()
                .orElseThrow(() -> new Exception("주문을 찾을 수 없습니다."));
        pending.setStatus("CANCELLED");
        coinMapper.updateOrderStatus(pending);
    }

    /** ============================================================
     * 지정가 미체결 주문 체결 처리 (예비 기능, 현재 미사용).
     * WebSocket에서 지정가 조건 충족 시 호출 예정.
     * buy()/sell()과 동일한 HOLDINGS·WALLET 처리 후 ORDER 상태를 COMPLETED로 변경한다.
     * ============================================================ */
    public void executePendingOrder(CoinOrdersDTO order) throws Exception {
        if ("BUY".equals(order.getOrderType())) {
            // [실행 흐름] 매수 체결: 잔고 차감 + 보유 추가
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
                double newAvg   = (existing.getAvgPrice() * existing.getCoinCount()
                                 + order.getOrderPrice() * order.getOrderCount()) / newCount;
                existing.setCoinCount(newCount);
                existing.setAvgPrice(newAvg);
                coinMapper.updateHolding(existing);
            }
        } else {
            // [실행 흐름] 매도 체결: 보유 차감 + 잔고 추가
            CoinHoldingsDTO holding = new CoinHoldingsDTO();
            holding.setUsername(order.getUsername());
            holding.setCoinCode(order.getCoinCode());
            CoinHoldingsDTO existing = coinMapper.getHolding(holding);
            if (existing == null || existing.getCoinCount() < order.getOrderCount())
                throw new Exception("보유 수량이 부족합니다.");
            order.setAvgPrice(existing.getAvgPrice());
            double newCount = existing.getCoinCount() - order.getOrderCount();
            if (newCount == 0) {
                coinMapper.deleteHolding(existing);
                coinMapper.cancelPendingByCoin(existing.getUsername(), existing.getCoinCode());
            } else {
                existing.setCoinCount(newCount);
                coinMapper.updateHolding(existing);
            }
            CoinWalletDTO wallet = coinMapper.getWallet(order.getUsername());
            wallet.setUsdtBalance(wallet.getUsdtBalance() + order.getOrderPrice() * order.getOrderCount());
            coinMapper.updateWallet(wallet);
        }
        order.setStatus("COMPLETED");
        coinMapper.updateOrderStatus(order);
    }

    /** ============================================================
     * 코인 지갑 잔고를 직접 업데이트한다.
     * ExchangeService에서 KRW↔USDT 환전 시 호출한다.
     * ============================================================ */
    public void updateWallet(CoinWalletDTO wallet) throws Exception {
        coinMapper.updateWallet(wallet);
    }
}