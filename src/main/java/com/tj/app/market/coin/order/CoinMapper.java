package com.tj.app.market.coin.order;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

/** ============================================================
 * [클래스 읽기] 코인 지갑·보유 현황·주문 내역 관련 DB 작업을 담당하는 MyBatis Mapper.
 *
 * SQL은 CoinMapper.xml에 정의되어 있다.
 *
 * [관련 테이블]
 * COIN_WALLET  : 코인 지갑 (USDT 잔고)
 * COIN_HOLDINGS: 코인 보유 현황 (종목별 수량·평단가)
 * COIN_ORDERS  : 코인 주문 이력
 *
 * [주식 Mapper와의 차이]
 * 주식은 Map<String, Object> 반환이 많지만, 코인은 DTO를 직접 반환한다.
 * 코인은 시장가만 지원하므로 PENDING 관련 메서드는 예비 기능이다.
 * ============================================================ */
@Mapper
public interface CoinMapper {

    /** ============================================================
     * 코인 지갑 조회.
     * ExchangeService에서 KRW↔USDT 환전 시에도 호출한다.
     * ============================================================ */
    CoinWalletDTO getWallet(String username) throws Exception;

    /** ============================================================
     * 코인 지갑 최초 생성.
     * MemberServiceImpl.joinMember()에서 회원 가입 시 자동 호출된다.
     * ============================================================ */
    void createWallet(String username) throws Exception;

    /** ============================================================
     * 코인 지갑 USDT 잔고 업데이트.
     * CoinWalletDTO 전체를 파라미터로 받아 usdtBalance를 SET한다.
     * ============================================================ */
    void updateWallet(CoinWalletDTO wallet) throws Exception;

    /** ============================================================
     * 특정 코인 보유 현황 단건 조회.
     * CoinHoldingsDTO의 username·coinCode로 조회한다.
     * null이면 미보유, 아니면 보유 중 → INSERT vs UPDATE 분기에 사용한다.
     * ============================================================ */
    CoinHoldingsDTO getHolding(CoinHoldingsDTO holding) throws Exception;

    /** ============================================================
     * 사용자의 전체 보유 코인 목록 조회.
     * 사이드바·보유 현황 화면·자산 계산에 사용한다.
     * ============================================================ */
    List<CoinHoldingsDTO> getHoldingList(String username) throws Exception;

    /** ============================================================
     * 코인 보유 최초 추가 (처음 매수).
     * COIN_HOLDINGS에 새 행을 삽입한다.
     * ============================================================ */
    void insertHolding(CoinHoldingsDTO holding) throws Exception;

    /** ============================================================
     * 코인 보유 수량·평단가 업데이트 (추가 매수 또는 일부 매도).
     * ============================================================ */
    void updateHolding(CoinHoldingsDTO holding) throws Exception;

    /** ============================================================
     * 코인 보유 행 삭제 (전량 매도 후 수량 0).
     * ============================================================ */
    void deleteHolding(CoinHoldingsDTO holding) throws Exception;

    /** ============================================================
     * 코인 주문 이력 삽입.
     * 매수/매도 체결 즉시 COIN_ORDERS에 기록한다 (status="DONE").
     * ============================================================ */
    void insertOrder(CoinOrdersDTO order) throws Exception;

    /** ============================================================
     * 코인 거래 내역 목록 조회 (전체).
     * 사이드바 거래 내역 탭에서 사용한다.
     * ============================================================ */
    List<CoinOrdersDTO> getOrderList(String username) throws Exception;

    /** ============================================================
     * 미체결 코인 주문 목록 조회 (예비 기능, 현재 미사용).
     * 코인은 시장가 즉시 체결이므로 PENDING이 생성되지 않는다.
     * ============================================================ */
    List<CoinOrdersDTO> getPendingOrders(String username) throws Exception;

    /** ============================================================
     * 코인 주문 상태 업데이트 (예비 기능, 현재 미사용).
     * ============================================================ */
    void updateOrderStatus(CoinOrdersDTO order) throws Exception;

    /** ============================================================
     * 특정 코인의 미체결 주문 취소 (예비 기능, 현재 미사용).
     * ============================================================ */
    void cancelPendingByCoin(@Param("username") String username, @Param("coinCode") String coinCode) throws Exception;
}