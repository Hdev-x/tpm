<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<div class="sidebar-panel" id="sidebar-panel">

    <div class="sidebar-header">
        <div style="display:flex; align-items:baseline; gap:8px;">
            <span id="sidebar-title">내 투자</span>
            <span id="sidebar-title-sub" style="display:none; font-size:14px; color:var(--text2); font-weight:300;"></span>
        </div>
        <div class="sidebar-header-btns">
            <div class="cur-switch" id="cur-switch" onclick="setCurrency(currencyMode === 'usd' ? 'krw' : 'usd')">
                <span class="cur-switch-label">$</span>
                <span class="cur-switch-label">원</span>
                <div class="cur-switch-thumb"></div>
            </div>
        </div>
        <script>(function(){
            var s = document.getElementById('cur-switch');
            if(localStorage.getItem('currencyMode')==='krw') s.classList.add('krw');
            var tab = localStorage.getItem('sidebar');
            if(!tab || tab === 'invest') s.style.display = 'none';
        })();</script>
    </div>

    <!-- ① 내 투자 섹션 -->
    <div class="sidebar-section" id="sidebar-invest">

        <!-- 상위 탭: 주식 / 코인 -->
        <div class="si-type-tabs">
            <div class="si-type-tab active" onclick="switchInvestTab(this,'stock')">주식</div>
            <div class="si-type-tab" onclick="switchInvestTab(this,'coin')">코인</div>
        </div>

        <!-- 주식 탭 -->
        <div class="sb-content" id="invest-stock" style="flex-direction:column; flex:1;">
            <div class="sb-tabs sb-subtabs">
                <div class="sb-tab active" onclick="switchBpTab(this,'stock-holdings')">보유</div>
                <div class="sb-tab" onclick="switchBpTab(this,'stock-pending')">미체결</div>
                <div class="sb-tab" onclick="switchBpTab(this,'stock-history')">거래내역</div>
            </div>
            <div class="sb-content" id="tab-stock-holdings">
                <div class="holding-cards">
                    <!-- 삼성전자 및 SK하이닉스 카드 삭제됨 -->
                </div>
            </div>
            <div class="sb-content" id="tab-stock-pending" style="display:none">
                <div class="sb-empty">
                    <span class="sb-empty-icon">📋</span>
                    <span>미체결 주문이 없습니다.</span>
                </div>
                <table class="sb-table" style="display:none">
                    <thead><tr><th>종목</th><th>유형</th><th>가격</th><th>수량</th><th>취소</th></tr></thead>
                    <tbody id="stock-pending-body"></tbody>
                </table>
            </div>
            <div class="sb-content" id="tab-stock-history" style="display:none">
                <div class="sb-empty">
                    <span class="sb-empty-icon">🕐</span>
                    <span>거래 내역이 없습니다.</span>
                </div>
                <table class="sb-table" style="display:none">
                    <thead><tr><th>일시</th><th>유형</th><th>종목</th><th>가격</th><th>수량</th><th>금액</th></tr></thead>
                    <tbody id="stock-history-body"></tbody>
                </table>
            </div>
        </div>

        <!-- 코인 탭 -->
        <div class="sb-content" id="invest-coin" style="display:none; flex-direction:column; flex:1; overflow-y:auto;">
            <div class="sb-tabs sb-subtabs">
                <div class="sb-tab active" onclick="switchBpTab(this,'coin-holdings')">보유</div>
                <div class="sb-tab" onclick="switchBpTab(this,'coin-pending')">미체결</div>
                <div class="sb-tab" onclick="switchBpTab(this,'coin-history')">거래내역</div>
            </div>
            <div class="sb-content" id="tab-coin-holdings">
                <div class="sb-empty" id="bp-empty">
                    <span class="sb-empty-icon">📊</span>
                    <span>보유 코인이 없습니다.</span>
                </div>
                <div class="holding-cards" id="bp-holdings-body"></div>
            </div>
            <div class="sb-content" id="tab-coin-pending" style="display:none">
                <div class="sb-empty">
                    <span class="sb-empty-icon">📋</span>
                    <span>미체결 주문이 없습니다.</span>
                </div>
                <table class="sb-table" id="orders-table" style="display:none">
                    <thead><tr><th>코인</th><th>유형</th><th>가격</th><th>수량</th><th>취소</th></tr></thead>
                    <tbody id="orders-body"></tbody>
                </table>
            </div>
            <div class="sb-content" id="tab-coin-history" style="display:none">
                <div class="sb-empty" id="history-empty">
                    <span class="sb-empty-icon">🕐</span>
                    <span>거래 내역이 없습니다.</span>
                </div>
                <div class="holding-cards" id="history-cards"></div>
            </div>
        </div>

    </div>

    <!-- ② 관심 섹션 -->
    <div class="sidebar-section" id="sidebar-interest" style="display:none; flex-direction:column; flex:1; overflow:hidden;">

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
                <div class="wl-sort-wrap" id="wl-sort-wrap-all">
                    <button class="wl-sort-btn" onclick="toggleSortDropdown('all')">
                        <span id="wl-sort-label-all">등록순</span>
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
                    </button>
                    <div class="wl-sort-dropdown" id="wl-sort-dropdown-all">
                        <div class="wl-sort-item active" onclick="setWatchlistSort('등록순', 'all')">등록순</div>
                        <div class="wl-sort-item" onclick="setWatchlistSort('이름순', 'all')">이름순</div>
                        <div class="wl-sort-item" onclick="setWatchlistSort('등락률 높은순', 'all')">등락률 높은순</div>
                        <div class="wl-sort-item" onclick="setWatchlistSort('등락률 낮은순', 'all')">등락률 낮은순</div>
                        <div class="wl-sort-item" onclick="setWatchlistSort('가격 높은순', 'all')">가격 높은순</div>
                        <div class="wl-sort-item" onclick="setWatchlistSort('가격 낮은순', 'all')">가격 낮은순</div>
                    </div>
                </div>
            </div>
            <div class="si-all-container" id="si-all-container">

                <!-- 주식 그룹 -->
                <div class="si-all-group" id="si-group-stock">
                    <div class="si-group-title">
                        <div class="si-group-left">
                            <span class="si-group-main">주식</span>
                        </div>
                    </div>
                    <div class="si-stock-list" id="watchlist-stock-all-list"></div>
                </div>

                <!-- 코인 그룹 -->
                <div class="si-all-group" id="si-group-coin">
                    <div class="si-group-title">
                        <div class="si-group-left">
                            <span class="si-group-main">코인</span>
                        </div>
                    </div>
                    <div class="si-stock-list" id="watchlist-coin-all-list"></div>
                </div>

            </div>
        </div>

        <!-- 주식 탭 -->
        <div class="si-tab-content" id="interest-stock" style="display:none">
            <div class="si-group-title">
                <span class="si-group-main">관심 주식</span>
            </div>
            <div class="si-stock-list" id="watchlist-stock-list"></div>
        </div>

        <!-- 코인 탭 -->
        <div class="si-tab-content" id="interest-coin" style="display:none">
            <div class="si-all-header" style="justify-content:flex-end">
                <div class="wl-sort-wrap" id="wl-sort-wrap-coin">
                    <button class="wl-sort-btn" onclick="toggleSortDropdown('coin')">
                        <span id="wl-sort-label-coin">등록순</span>
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
                    </button>
                    <div class="wl-sort-dropdown" id="wl-sort-dropdown-coin">
                        <div class="wl-sort-item active" onclick="setWatchlistSort('등록순', 'coin')">등록순</div>
                        <div class="wl-sort-item" onclick="setWatchlistSort('이름순', 'coin')">이름순</div>
                        <div class="wl-sort-item" onclick="setWatchlistSort('등락률 높은순', 'coin')">등락률 높은순</div>
                        <div class="wl-sort-item" onclick="setWatchlistSort('등락률 낮은순', 'coin')">등락률 낮은순</div>
                        <div class="wl-sort-item" onclick="setWatchlistSort('가격 높은순', 'coin')">가격 높은순</div>
                        <div class="wl-sort-item" onclick="setWatchlistSort('가격 낮은순', 'coin')">가격 낮은순</div>
                    </div>
                </div>
            </div>
            <div class="si-group-title" style="padding: 4px 14px 0;">
                <span class="si-group-main">관심 코인</span>
            </div>
            <div class="si-stock-list" id="watchlist-coin-list"></div>
        </div>

    </div>

    <!-- ③ 최근 본 섹션 -->
    <div class="sidebar-section" id="sidebar-recent" style="display:none; flex-direction:column; flex:1; overflow:hidden;">

        <div class="si-type-tabs">
            <div class="si-type-tab active" onclick="switchRecentTab(this,'all')">전체</div>
            <div class="si-type-tab" onclick="switchRecentTab(this,'stock')">주식</div>
            <div class="si-type-tab" onclick="switchRecentTab(this,'coin')">코인</div>
        </div>

        <!-- 전체 탭 -->
        <div class="si-recent-tab" id="recent-tab-all" style="display:flex; flex-direction:column; flex:1; overflow:hidden;">
            <div class="si-all-header">
                <span style="font-size:14px; color:var(--text3);">최근 본 종목</span>
                <button class="wl-sort-btn" onclick="clearRecent('all')">전체 삭제</button>
            </div>
            <div style="overflow-y:auto; flex:1; padding-bottom:12px;">
                <div class="si-all-group" id="recent-group-coin">
                    <div class="si-group-title"><span class="si-group-main">코인</span></div>
                    <div class="si-stock-list" id="recent-coin-all"></div>
                </div>
                <div class="si-all-group" id="recent-group-stock">
                    <div class="si-group-title"><span class="si-group-main">주식</span></div>
                    <div class="si-stock-list" id="recent-stock-all"></div>
                </div>
            </div>
        </div>

        <!-- 주식 탭 -->
        <div class="si-recent-tab" id="recent-tab-stock" style="display:none; flex-direction:column; flex:1; overflow:hidden;">
            <div class="si-all-header">
                <span style="font-size:12px; color:var(--text3);">최근 본 주식</span>
                <button class="wl-sort-btn" onclick="clearRecent('stock')">전체 삭제</button>
            </div>
            <div class="si-stock-list" id="recent-stock-only" style="overflow-y:auto; flex:1; padding-bottom:12px;"></div>
        </div>

        <!-- 코인 탭 -->
        <div class="si-recent-tab" id="recent-tab-coin" style="display:none; flex-direction:column; flex:1; overflow:hidden;">
            <div class="si-all-header">
                <span style="font-size:12px; color:var(--text3);">최근 본 코인</span>
                <button class="wl-sort-btn" onclick="clearRecent('coin')">전체 삭제</button>
            </div>
            <div class="si-stock-list" id="recent-coin-only" style="overflow-y:auto; flex:1; padding-bottom:12px;"></div>
        </div>

    </div>

    <!-- ④ 실시간 섹션 -->
    <div class="sidebar-section" id="sidebar-live" style="display:none;">

        <div class="si-type-tabs">
            <div class="si-type-tab" onclick="switchLiveTab(this,'all')">전체</div>
            <div class="si-type-tab active" onclick="switchLiveTab(this,'stock')">주식</div>
            <div class="si-type-tab" onclick="switchLiveTab(this,'coin')">코인</div>
        </div>

        <div class="live-filter-bar">
            <div class="wl-sort-wrap">
                <button class="wl-sort-btn live-filter-btn" onclick="toggleLiveDropdown('sort')">
                    <span id="live-sort-label">거래대금</span>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
                </button>
                <div class="wl-sort-dropdown" id="live-sort-dd">
                    <div class="wl-sort-item active" onclick="setLiveSort('거래대금')">거래대금</div>
                    <div class="wl-sort-item" onclick="setLiveSort('급상승')">급상승</div>
                    <div class="wl-sort-item" onclick="setLiveSort('급하락')">급하락</div>
                </div>
            </div>
        </div>

        <!-- 전체 탭 -->
        <div class="live-tab-panel" id="live-tab-all" style="display:none;">
            <div class="live-list" id="live-all-list"></div>
        </div>

        <!-- 주식 탭 -->
        <div class="live-tab-panel" id="live-tab-stock">
            <div class="live-list" id="live-stock-list">
                <div class="si-wl-empty">데이터를 불러오는 중입니다</div>
            </div>
        </div>

        <!-- 코인 탭 -->
        <div class="live-tab-panel" id="live-tab-coin" style="display:none;">
            <div class="live-list" id="live-coin-list"></div>
        </div>

    </div>

</div>
