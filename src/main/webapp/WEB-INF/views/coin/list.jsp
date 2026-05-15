<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">

<head>
    <meta charset="UTF-8">
    <title>TradeBot · 코인 리스트</title>
    <link rel="stylesheet"
        href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/coinList.css">
</head>

<body data-sidebar-animate="true">

    <div class="app-wrapper">

        <div class="page">

            <%@ include file="../common/nav.jsp" %>

            <div class="main-content">

                <!-- 상단 티커 바 -->
                <div class="ticker-bar">
                    <div class="ticker-left">
                        <div class="ticker-today">
                            <div class="ticker-today-label">오늘</div>
                            <div class="ticker-today-content">
                                <div class="ticker-today-title">증시캘린더</div>
                                <div class="ticker-today-sub">주간 신규실업수당 청구건수...</div>
                            </div>
                        </div>
                    </div>
                    <div class="ticker-items">
                        <div class="ticker-item">
                            <div class="ticker-item-chart down-chart">
                                <svg viewBox="0 0 60 28" preserveAspectRatio="none">
                                    <polyline points="0,8 15,10 30,14 45,18 60,22" />
                                </svg>
                            </div>
                            <div class="ticker-item-info">
                                <div class="ticker-item-name">달러 환율</div>
                                <div class="ticker-item-price">1,493.25 <span class="down">-1.85 (0.12%)</span></div>
                            </div>
                        </div>
                        <div class="ticker-item">
                            <div class="ticker-item-chart up-chart">
                                <svg viewBox="0 0 60 28" preserveAspectRatio="none">
                                    <polyline points="0,20 15,18 30,14 45,10 60,6" />
                                </svg>
                            </div>
                            <div class="ticker-item-info">
                                <div class="ticker-item-name">코스피</div>
                                <div class="ticker-item-price">7,860.98 <span class="up">+16.97 (0.21%)</span></div>
                            </div>
                        </div>
                        <div class="ticker-item">
                            <div class="ticker-item-chart down-chart">
                                <svg viewBox="0 0 60 28" preserveAspectRatio="none">
                                    <polyline points="0,8 15,12 30,16 45,20 60,22" />
                                </svg>
                            </div>
                            <div class="ticker-item-info">
                                <div class="ticker-item-name">코스닥</div>
                                <div class="ticker-item-price">1,165.77 <span class="down">-11.16 (0.94%)</span></div>
                            </div>
                        </div>
                        <div class="ticker-item">
                            <div class="ticker-item-chart up-chart">
                                <svg viewBox="0 0 60 28" preserveAspectRatio="none">
                                    <polyline points="0,22 15,18 30,14 45,10 60,4" />
                                </svg>
                            </div>
                            <div class="ticker-item-info">
                                <div class="ticker-item-name">나스닥</div>
                                <div class="ticker-item-price">26,402.34 <span class="up">+314.14 (1.20%)</span></div>
                            </div>
                        </div>
                    </div>
                    <div class="ticker-right">
                        <button class="ticker-arrow">›</button>
                    </div>
                </div>

                <!-- 메인 탭 -->
                <div class="main-tabs">
                    <button class="main-tab active" data-tab="realtime">실시간 차트</button>
                    <!-- <button class="main-tab" data-tab="category">지금 뜨는 카테고리</button>
                    <button class="main-tab" data-tab="investor">국내 투자자 동향</button> -->
                </div>

                <!-- 탭 컨텐츠 -->
                <div class="tab-content" id="tab-realtime">

                    <!-- 필터 버튼 행 -->
                    <div class="filter-row">
                        <div class="filter-group">
                            <button class="filter-btn active">전체</button>
                            <button class="filter-btn">USDT</button>
                            <button class="filter-btn">USDC</button>
                        </div>
                        <div class="filter-divider"></div>
                        <div class="filter-group">
                            <button class="filter-btn active">거래대금</button>
                            <button class="filter-btn">급상승</button>
                            <button class="filter-btn">급하락</button>
                        </div>
                        <div class="filter-divider"></div>
                        <div class="filter-group">
                            <button class="filter-btn time active">실시간</button>
                            <button class="filter-btn time">1일</button>
                            <button class="filter-btn time" disabled>1주일</button>
                            <button class="filter-btn time" disabled>1개월</button>
                            <button class="filter-btn time" disabled>3개월</button>
                            <button class="filter-btn time" disabled>6개월</button>
                            <button class="filter-btn time" disabled>1년</button>
                        </div>

                    </div>

                    <div class="content-layout">

                        <!-- 좌측: 테이블 -->
                        <div class="list-panel">

                            <!-- 테이블 헤더 -->
                            <div class="stock-table-wrap">
                                <table class="stock-table">
                                    <thead>
                                        <tr>
                                            <th class="th-rank">코인</th>
                                            <th class="th-price">현재가</th>
                                            <th class="th-change">등락률</th>
                                            <th class="th-quote">거래대금</th>
                                            <th class="th-high">고가</th>
                                            <th class="th-low">저가</th>
                                        </tr>
                                    </thead>
                                    <tbody id="stockTableBody">



                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- 우측: 종목 상세 패널 -->
                        <div class="detail-panel" id="detailPanel">
                            <div class="detail-empty" id="detailEmpty">
                                <span>코인을 선택하세요</span>
                            </div>
                            <div class="detail-body" id="detailBody" style="display:none;">

                                <!-- 고정 헤더 -->
                                <div class="detail-sticky-header">
                                    <div class="hc-main-id">
                                        <div class="hc-logo hc-logo-wrap" id="detailLogoWrap">
                                            <img id="detailLogoImg" src="" alt="" class="hc-logo-img">
                                        </div>
                                        <div class="hc-main-name-col">
                                            <span class="hc-main-ticker" id="detailName">-</span>
                                            <span class="hc-main-sub" id="detailSub">-</span>
                                        </div>
                                    </div>
                                    <div class="hc-main-right">
                                        <span class="hc-main-eval" id="detailPrice">-</span>
                                        <span class="hc-main-pnl" id="detailChange">-</span>
                                    </div>
                                </div>

                                <!-- 차트 -->
                                <div class="detail-chart-section">
                                    <div class="detail-chart-label">주봉</div>
                                    <div class="detail-chart-area" id="detailChartArea"></div>
                                </div>

                                <!-- 커뮤니티 댓글 -->
                                <div class="detail-community-title">커뮤니티</div>
                                <div class="chat-messages" id="chat-messages"></div>

                            </div>

                        </div>

                    </div>
                </div>

                <div class="tab-content hidden" id="tab-category">
                    <div class="empty-tab">지금 뜨는 카테고리</div>
                </div>
                <div class="tab-content hidden" id="tab-investor">
                    <div class="empty-tab">국내 투자자 동향</div>
                </div>

            </div>

        </div>

        <%@ include file="../common/sidebar.jsp" %>

        <%@ include file="../common/sidebar-icons.jsp" %>


    </div>

    <script src="/js/common.js"></script>
    <script src="/js/coinList.js"></script>
</body>

</html>