<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>TradeBot · 주식 리스트</title>
    <link rel="stylesheet"
        href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/market/market-list.css">
    <link rel="stylesheet" href="/css/market/chart.css">
    <link rel="stylesheet" href="/css/market/stock/list.css">
</head>
<body>

    <div class="app-wrapper">

        <div class="page">
            <%@ include file="../common/nav.jsp" %>

            <div class="main-content">

                <!-- 시장 지수 티커 바 -->
                <div class="ticker-bar">
                    <div class="ticker-items" id="marketIndexItems"></div>
                    <div class="ticker-right">
                        <button class="ticker-arrow" id="tickerArrowBtn">›</button>
                    </div>
                </div>

                <!-- 탭 -->
                <div class="main-tabs">
                    <button class="main-tab active" data-tab="realtime">실시간 시세</button>
                </div>

                <!-- 실시간 탭 본문 -->
                <div class="tab-content" id="tab-realtime">

                    <!-- 필터 -->
                    <div class="filter-row">
                        <div class="filter-group">
                            <button class="filter-btn active">전체</button>
                            <button class="filter-btn">급상승</button>
                            <button class="filter-btn">급하락</button>
                        </div>
                    </div>

                    <!-- 리스트 + 상세 패널 -->
                    <div class="content-layout">

                        <!-- 종목 테이블 -->
                        <div class="list-panel">
                            <div class="stock-table-wrap">
                                <table class="stock-table">
                                    <thead>
                                        <tr>
                                            <th class="th-rank">종목</th>
                                            <th class="th-price">현재가</th>
                                            <th class="th-change">등락률</th>
                                            <th class="th-diff">전일대비</th>
                                            <th class="th-high">고가</th>
                                            <th class="th-low">저가</th>
                                        </tr>
                                    </thead>
                                    <tbody id="stockTableBody">
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- 상세 패널 -->
                        <div class="detail-panel" id="detailPanel">

                            <div class="detail-empty" id="detailEmpty">
                                <span>종목을 선택하세요</span>
                            </div>

                            <div class="detail-body" id="detailBody" style="display:none;">

                                <div class="detail-sticky-header">
                                    <div class="hc-main-id">
                                        <div class="hc-logo hc-logo-wrap" id="detailLogoWrap">
                                            <img id="detailLogoImg" src="" alt="" class="hc-logo-img" style="display:none;">
                                        </div>
                                        <div class="hc-main-name-col">
                                            <span class="hc-main-ticker" id="detailName">-</span>
                                            <span class="hc-main-sub" id="detailSub">-</span>
                                        </div>
                                        <button class="ph-like-btn" id="detail-watchlist-btn"
                                            onclick="if(currentDetailCode){toggleStockWatchlistRow(currentDetailCode);this.classList.toggle('active',getStockWatchlist().includes(currentDetailCode));}"
                                            style="padding:4px 10px;font-size:12px;border-radius:8px;">
                                            <svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
                                            관심
                                        </button>
                                    </div>
                                    <div class="hc-main-right">
                                        <span class="hc-main-eval" id="detailPrice">-</span>
                                        <span class="hc-main-pnl" id="detailChange">-</span>
                                    </div>
                                </div>

                                <div class="detail-chart-section">
                                    <div class="detail-chart-label">1년 차트</div>
                                    <div class="detail-chart-area" id="detailChartArea"></div>
                                </div>

                                <div class="card panel-chat" id="panel-chat">
                                    <div class="panel-title-row">
                                        <div class="panel-title">실시간 댓글</div>
                                        <div class="chat-sort-group">
                                            <button class="chat-sort-btn active" data-sort="latest">최신순</button>
                                            <button class="chat-sort-btn" data-sort="popular">인기순</button>
                                        </div>
                                    </div>
                                    <div class="chat-messages" id="chat-messages">
                                        <div class="chat-empty">
                                            <span class="chat-empty-icon">💬</span>
                                            <span>종목을 선택하면 댓글을 볼 수 있어요</span>
                                        </div>
                                    </div>
                                </div>

                            </div>

                        </div>

                    </div>
                </div>

            </div>

        </div>

        <%@ include file="../common/sidebar.jsp" %>
        <%@ include file="../common/sidebar-icons.jsp" %>

    </div>

    <script src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js"></script>

    <script src="/js/common.js" defer></script>
	<script src="/js/sidebar-data.js" defer></script>
    <script src="/js/market/market-common.js"></script>
    <script src="/js/market/stock/stock-list.js"></script>
</body>
</html>
