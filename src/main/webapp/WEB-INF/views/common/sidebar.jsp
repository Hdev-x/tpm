<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<div class="sidebar-panel" id="sidebar-panel">

    <div class="sidebar-header">
        <span id="sidebar-title">내 투자</span>
        <div class="sidebar-header-btns">
            <button class="sb-fold-btn" onclick="closeSidebar()">접기</button>
            <button class="sb-expand-btn">&gt;&gt;</button>
        </div>
    </div>

    <!-- ① 내 투자 섹션 -->
    <div class="sidebar-section" id="sidebar-invest">
        <div class="sb-tabs">
            <div class="sb-tab active" onclick="switchBpTab(this,'positions')">포지션</div>
            <div class="sb-tab" onclick="switchBpTab(this,'orders')">오더</div>
            <div class="sb-tab" onclick="switchBpTab(this,'history')">기록</div>
        </div>

        <div class="sb-content" id="tab-positions">
            <div class="sb-empty" id="bp-empty">
                <span class="sb-empty-icon">📊</span>
                <span>포지션이 없습니다.</span>
            </div>
            <table class="sb-table" id="bp-holdings-table" style="display:none">
                <thead>
                    <tr>
                        <th>코인</th>
                        <th>수량</th>
                        <th>평균단가</th>
                        <th>현재가</th>
                        <th>손익</th>
                    </tr>
                </thead>
                <tbody id="bp-holdings-body"></tbody>
            </table>
        </div>

        <div class="sb-content" id="tab-orders" style="display:none">
            <div class="sb-empty">
                <span class="sb-empty-icon">📋</span>
                <span>오픈 오더가 없습니다.</span>
            </div>
            <table class="sb-table" id="orders-table" style="display:none">
                <thead>
                    <tr>
                        <th>코인</th>
                        <th>유형</th>
                        <th>가격</th>
                        <th>수량</th>
                        <th>취소</th>
                    </tr>
                </thead>
                <tbody id="orders-body"></tbody>
            </table>
        </div>

        <div class="sb-content" id="tab-history" style="display:none">
            <div class="sb-empty">
                <span class="sb-empty-icon">🕐</span>
                <span>거래 기록이 없습니다.</span>
            </div>
            <table class="sb-table" id="history-table" style="display:none">
                <thead>
                    <tr>
                        <th>일시</th>
                        <th>유형</th>
                        <th>가격</th>
                        <th>수량</th>
                        <th>금액</th>
                    </tr>
                </thead>
                <tbody id="history-body"></tbody>
            </table>
        </div>
    </div>

    <!-- ② 관심 섹션 -->
    <div class="sidebar-section" id="sidebar-interest" style="display:none; flex-direction:column; flex:1; overflow:hidden;">

        <!-- 통화 토글 -->
        <div class="si-currency-bar">
            <button class="si-cur-btn active">$</button>
            <button class="si-cur-btn">원</button>
        </div>

        <!-- AI 배너 -->
        <div class="si-ai-banner">
            <div class="si-ai-inner">
                <span class="si-ai-label">✦ 토스증권 AI</span>
                <p class="si-ai-text">엔비디아 H200 칩 판매 승인으로 2.5% 상승</p>
            </div>
            <span class="si-ai-arrow">›</span>
        </div>

        <!-- 전체 / 주식 / 코인 탭 -->
        <div class="si-type-tabs">
            <div class="si-type-tab active" onclick="switchInterestTab(this,'all')">전체</div>
            <div class="si-type-tab" onclick="switchInterestTab(this,'stock')">주식</div>
            <div class="si-type-tab" onclick="switchInterestTab(this,'coin')">코인</div>
        </div>

        <!-- 전체 탭 -->
        <div class="si-tab-content" id="interest-all">
            <div class="si-all-header">
                <button class="si-swap-btn" onclick="swapInterestGroups()" title="순서 변경">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M7 16V4m0 0L3 8m4-4l4 4"/><path d="M17 8v12m0 0l4-4m-4 4l-4-4"/></svg>
                    순서 변경
                </button>
            </div>
            <div class="si-all-container" id="si-all-container">

                <!-- 주식 그룹 -->
                <div class="si-all-group" id="si-group-stock">
                    <div class="si-group-title">
                        <div class="si-group-left">
                            <span class="si-group-main">주식</span>
                        </div>
                    </div>
                    <div class="si-stock-list">
                        <div class="si-stock-item">
                            <div class="si-logo" style="background:#1428A0;">삼</div>
                            <span class="si-stock-name">삼성전자</span>
                            <div class="si-stock-price">
                                <span class="si-price">293,000원</span>
                                <span class="si-change up">+9,000원 (3.16%)</span>
                            </div>
                            <button class="si-heart active"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                        </div>
                        <div class="si-stock-item">
                            <div class="si-logo" style="background:#A50034;">G</div>
                            <span class="si-stock-name">LG전자</span>
                            <div class="si-stock-price">
                                <span class="si-price">219,000원</span>
                                <span class="si-change up">+27,600원 (14.42%)</span>
                            </div>
                            <button class="si-heart active"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                        </div>
                        <div class="si-stock-item">
                            <div class="si-logo" style="background:#E8001C;">SK</div>
                            <span class="si-stock-name">SK하이닉스</span>
                            <div class="si-stock-price">
                                <span class="si-price">1,971,000원</span>
                                <span class="si-change down">-5,000원 (0.25%)</span>
                            </div>
                            <button class="si-heart active"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                        </div>
                        <div class="si-stock-item">
                            <div class="si-logo" style="background:#76B900;">N</div>
                            <span class="si-stock-name">엔비디아</span>
                            <div class="si-stock-price">
                                <span class="si-price">343,977원</span>
                                <span class="si-change up">+6,339원 (1.87%)</span>
                            </div>
                            <button class="si-heart active"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                        </div>
                    </div>
                </div>

                <!-- 코인 그룹 -->
                <div class="si-all-group" id="si-group-coin">
                    <div class="si-group-title">
                        <div class="si-group-left">
                            <span class="si-group-main">코인</span>
                        </div>
                    </div>
                    <div class="si-stock-list">
                        <div class="si-stock-item">
                            <div class="si-logo" style="background:#F7931A;">₿</div>
                            <span class="si-stock-name">비트코인</span>
                            <div class="si-stock-price">
                                <span class="si-price">135,420,000원</span>
                                <span class="si-change up">+2,100,000원 (1.57%)</span>
                            </div>
                            <button class="si-heart active"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                        </div>
                        <div class="si-stock-item">
                            <div class="si-logo" style="background:#627EEA;">E</div>
                            <span class="si-stock-name">이더리움</span>
                            <div class="si-stock-price">
                                <span class="si-price">3,812,000원</span>
                                <span class="si-change down">-45,000원 (1.17%)</span>
                            </div>
                            <button class="si-heart active"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                        </div>
                    </div>
                </div>

            </div>
        </div>

        <!-- 주식 탭 -->
        <div class="si-tab-content" id="interest-stock" style="display:none">
            <div class="si-group-title">
                <span class="si-group-main">관심 주식</span>
            </div>
            <div class="si-stock-list">
                <div class="si-stock-item">
                    <div class="si-logo" style="background:#1428A0;">삼</div>
                    <span class="si-stock-name">삼성전자</span>
                    <div class="si-stock-price">
                        <span class="si-price">293,000원</span>
                        <span class="si-change up">+9,000원 (3.16%)</span>
                    </div>
                    <button class="si-heart active"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                </div>
                <div class="si-stock-item">
                    <div class="si-logo" style="background:#A50034;">G</div>
                    <span class="si-stock-name">LG전자</span>
                    <div class="si-stock-price">
                        <span class="si-price">219,000원</span>
                        <span class="si-change up">+27,600원 (14.42%)</span>
                    </div>
                    <button class="si-heart active"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                </div>
                <div class="si-stock-item">
                    <div class="si-logo" style="background:#E8001C;">SK</div>
                    <span class="si-stock-name">SK하이닉스</span>
                    <div class="si-stock-price">
                        <span class="si-price">1,971,000원</span>
                        <span class="si-change down">-5,000원 (0.25%)</span>
                    </div>
                    <button class="si-heart active"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                </div>
                <div class="si-stock-item">
                    <div class="si-logo" style="background:#76B900;">N</div>
                    <span class="si-stock-name">엔비디아</span>
                    <div class="si-stock-price">
                        <span class="si-price">343,977원</span>
                        <span class="si-change up">+6,339원 (1.87%)</span>
                    </div>
                    <button class="si-heart active"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                </div>
                <div class="si-stock-item si-add-btn">
                    <div class="si-logo si-add-logo">+</div>
                    <span class="si-stock-name">추가하기</span>
                </div>
            </div>
        </div>

        <!-- 코인 탭 -->
        <div class="si-tab-content" id="interest-coin" style="display:none">
            <div class="si-group-title">
                <span class="si-group-main">관심 코인</span>
            </div>
            <div class="si-stock-list">
                <div class="si-stock-item">
                    <div class="si-logo" style="background:#F7931A;">₿</div>
                    <span class="si-stock-name">비트코인</span>
                    <div class="si-stock-price">
                        <span class="si-price">135,420,000원</span>
                        <span class="si-change up">+2,100,000원 (1.57%)</span>
                    </div>
                    <button class="si-heart active"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                </div>
                <div class="si-stock-item">
                    <div class="si-logo" style="background:#627EEA;">E</div>
                    <span class="si-stock-name">이더리움</span>
                    <div class="si-stock-price">
                        <span class="si-price">3,812,000원</span>
                        <span class="si-change down">-45,000원 (1.17%)</span>
                    </div>
                    <button class="si-heart active"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                </div>
                <div class="si-stock-item si-add-btn">
                    <div class="si-logo si-add-logo">+</div>
                    <span class="si-stock-name">추가하기</span>
                </div>
            </div>
        </div>

    </div>

    <!-- ③ 최근 본 섹션 -->
    <div class="sidebar-section sb-content" id="sidebar-recent" style="display:none">
        <div class="sb-empty">
            <span class="sb-empty-icon">🕐</span>
            <span>최근 본 종목이 없습니다.</span>
        </div>
    </div>

    <!-- ④ 실시간 섹션 -->
    <div class="sidebar-section sb-content" id="sidebar-live" style="display:none">
        <div class="sb-empty">
            <span class="sb-empty-icon">📡</span>
            <span>실시간 데이터가 없습니다.</span>
        </div>
    </div>

</div>
