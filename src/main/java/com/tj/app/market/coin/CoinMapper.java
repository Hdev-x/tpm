package com.tj.app.market.coin;

import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper
public interface CoinMapper {

    /**
     * 지갑 잔고 조회
     * @param username 사용자 아이디
     * @return 지갑 정보
     */
    CoinWalletDTO getWallet(String username) throws Exception;

    /**
     * 지갑 잔고 업데이트
     * @param wallet 업데이트할 지갑 정보
     */
    void updateWallet(CoinWalletDTO wallet) throws Exception;

    /**
     * 보유 코인 단건 조회 (특정 코인 보유 여부 확인)
     * @param holding 조회할 코인 정보 (username, coinCode)
     * @return 보유 코인 정보
     */
    CoinHoldingsDTO getHolding(CoinHoldingsDTO holding) throws Exception;

    /**
     * 보유 코인 목록 조회
     * @param username 사용자 아이디
     * @return 보유 코인 목록
     */
    List<CoinHoldingsDTO> getHoldingList(String username) throws Exception;

    /**
     * 보유 코인 추가 (처음 매수할 때)
     * @param holding 추가할 코인 정보
     */
    void insertHolding(CoinHoldingsDTO holding) throws Exception;

    /**
     * 보유 코인 업데이트 (추가 매수 시 수량/평단가 갱신)
     * @param holding 업데이트할 코인 정보
     */
    void updateHolding(CoinHoldingsDTO holding) throws Exception;

    /**
     * 보유 코인 삭제 (전량 매도 시)
     * @param holding 삭제할 코인 정보 (username, coinCode)
     */
    void deleteHolding(CoinHoldingsDTO holding) throws Exception;

    /**
     * 주문 내역 추가
     * @param order 주문 정보
     */
    void insertOrder(CoinOrdersDTO order) throws Exception;

    /**
     * 주문 내역 조회
     * @param username 사용자 아이디
     * @return 주문 내역 목록
     */
    List<CoinOrdersDTO> getOrderList(String username) throws Exception;
}