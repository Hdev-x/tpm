<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>Dashboard</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/chart-toss-coin.css">
    <link rel="stylesheet" href="/css/coinCommunity.css"> <style>
        /* 대시보드 레이아웃 고도화 */
        .main-layout { padding: 24px; max-width: 1200px; margin: 0 auto; }
        
        /* 1. 글로벌 지수 티커 바 */
        .ticker-bar {
            background: var(--surface);
            border-bottom: 1px solid var(--border);
            padding: 14px 24px;
            display: flex;
            gap: 30px;
            overflow-x: auto;
            white-space: nowrap;
            margin: -40px -50px 32px -50px; /* 💡 상단 여백 규격 수정 */
            scrollbar-width: none;
        }
        .ticker-bar::-webkit-scrollbar { display: none; }
        .ticker-item { display: flex; align-items: center; gap: 8px; font-size: 13px; }
        .ticker-label { color: var(--text-grey); font-weight: 500; }
        .ticker-price { font-weight: 700; color: var(--text); }
        .ticker-change { font-size: 12px; font-weight: 600; }
        
        /* 2. 히어로 섹션 */
        .hero-section {
            background: linear-gradient(135deg, #3182F6 0%, #1c2030 100%);
            border-radius: 24px;
            padding: 40px;
            margin-bottom: 24px;
            color: white;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 10px 30px rgba(49, 130, 246, 0.2);
        }
        .hero-content h2 { font-size: 28px; font-weight: 800; margin-bottom: 8px; color: white !important; }
        .hero-content p { opacity: 0.8; font-size: 16px; color: white !important; }
        .hero-stats { text-align: right; }
        .hero-asset-label { font-size: 14px; opacity: 0.7; margin-bottom: 4px; color: rgba(255,255,255,0.8); }
        .hero-asset-value { font-size: 32px; font-weight: 800; color: white; }

        /* 3. 섹션 헤더 */
        .section-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 16px;
        }
        .section-title { font-size: 18px; font-weight: 700; display: flex; align-items: center; gap: 8px; color: var(--text); }
        .btn-more { font-size: 13px; color: #3182F6; text-decoration: none; font-weight: 600; }

        /* 4. 커뮤니티/공지사항 그리드 */
        .community-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 24px;
        }
        .list-card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 20px;
            padding: 24px;
        }
        .list-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid rgba(255,255,255,0.05);
            text-decoration: none;
            color: inherit;
            transition: transform 0.2s;
        }
        .list-item:last-child { border-bottom: none; }
        .list-item:hover { transform: translateX(4px); }
        .item-title { font-size: 14px; font-weight: 500; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; flex: 1; padding-right: 15px; color: var(--text); }
        .item-date { font-size: 12px; color: var(--text-grey); flex-shrink: 0; }
        
        /* 배지 스타일 */
        .badge {
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
            margin-right: 8px;
        }
        .badge-notice { background: rgba(240, 68, 82, 0.1); color: #F04452; }
        .badge-new { background: rgba(49, 130, 246, 0.1); color: #3182F6; }
    </style>
</head>
<body class="chart-page community-page board-community-page" style="overflow: auto;">

<div class="app-wrapper">
    <div class="page">
        <%@ include file="common/nav.jsp" %>
        
        <div class="main-layout" style="display: block; padding: 40px 50px 80px; height: calc(100vh - 70px); overflow-y: auto; box-sizing: border-box;">
            
            <div id="global-ticker" class="ticker-bar">
                <div class="ticker-item"><span class="ticker-label">Loading indices...</span></div>
            </div>

            <div class="hero-section">
                <div class="hero-content">
                    <h2>안녕하세요, ${not empty member ? member.name : '투자자'}님!</h2>
                    <p>오늘의 시장 흐름을 한눈에 확인해보세요.</p>
                    <div style="margin-top: 24px; display: flex; gap: 12px;">
                        <a href="/stock/view" class="order-type-btn sel" style="background: white; color: #3182F6; border: none;">거래소 가기</a>
                        <a href="/board/list" class="order-type-btn" style="border-color: rgba(255,255,255,0.3); color: white;">커뮤니티</a>
                    </div>
                </div>
                <c:if test="${not empty member}">
                    <div class="hero-stats">
                        <div class="hero-asset-label">내 총 자산</div>
                        <div id="hero-total-asset" class="hero-asset-value">계산 중...</div>
                    </div>
                </c:if>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 24px;">
                <div class="card" style="padding: 24px; border: 1px solid var(--border);">
                    <div class="chart-header" style="display: flex; justify-content: space-between; margin-bottom: 15px;">
                        <div>
                            <span style="font-size: 14px; color: var(--text-grey);">KOSPI</span>
                            <h3 id="idx-kospi-price" style="font-size: 20px; margin-top: 5px; color: var(--text); font-weight: 700;">-</h3>
                        </div>
                        <span id="idx-kospi-change" class="ph-change" style="font-size: 14px;">-</span>
                    </div>
                    <div id="kospi-mini-chart" style="height: 180px;"></div>
                </div>

                <div class="card" style="padding: 24px; border: 1px solid var(--border);">
                    <div class="chart-header" style="display: flex; justify-content: space-between; margin-bottom: 15px;">
                        <div>
                            <span style="font-size: 14px; color: var(--text-grey);">BITCOIN</span>
                            <h3 id="idx-btc-price" style="font-size: 20px; margin-top: 5px; color: var(--text); font-weight: 700;">-</h3>
                        </div>
                        <span id="idx-btc-change" class="ph-change" style="font-size: 14px;">-</span>
                    </div>
                    <div id="btc-mini-chart" style="height: 180px;"></div>
                </div>
            </div>
            
            <div class="community-grid">
                <div class="list-card">
                    <div class="section-header">
                        <h3 class="section-title">📢 최근 공지사항</h3>
                        <a href="/notice/list" class="btn-more">더보기</a>
                    </div>
                    <div id="recent-notices" class="list-content">
                        <p style="color: var(--text-grey); font-size: 13px;">로딩 중...</p>
                    </div>
                </div>
                <div class="list-card">
                    <div class="section-header">
                        <h3 class="section-title">💬 커뮤니티 인기글</h3>
                        <a href="/board/list" class="btn-more">더보기</a>
                    </div>
                    <div id="recent-boards" class="list-content">
                        <p style="color: var(--text-grey); font-size: 13px;">로딩 중...</p>
                    </div>
                </div>
            </div>

            <div class="dashboard-bottom-grid" style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; font-family: 'Pretendard', sans-serif;">
                <div class="news-panel" style="background-color: var(--surface); color: #ffffff; padding: 24px; border-radius: 20px; border: 1px solid var(--border); max-height: 480px; overflow-y: auto;">
                    <h3 style="padding-bottom: 15px; margin-top: 0; display: flex; justify-content: space-between; align-items: center; margin-bottom: 0;">
                        <a href="/news/list" class="main-news-title-link" style="font-size: 16px; font-weight: bold; color: var(--text); text-decoration: none;">
                            📰 실시간 종목 뉴스
                        </a>
                        <input type="text" id="main-news-search" value="삼성전자" 
                               style="width: 100px; background: #131722; border: 1px solid #2962ff; color: #2962ff; font-size: 12px; font-weight: bold; padding: 4px 10px; border-radius: 4px; text-align: center; outline: none;">
                    </h3>
                    <div id="naver-news-list" class="news-list"></div>
                </div>

                <div class="market-rank-panel" style="background-color: var(--surface); color: #ffffff; padding: 24px; border-radius: 20px; border: 1px solid var(--border); max-height: 480px; overflow-y: auto;">
                    <h3 style="padding-bottom: 15px; margin-top: 0; font-size: 16px; color: var(--text); font-weight: 700; margin-bottom: 0;">🔥 실시간 급등락 TOP 5</h3>
                    <table style="width: 100%; border-collapse: collapse; text-align: left; font-size: 14px;">
                        <thead>
                            <tr style="border-bottom: 1px solid var(--border); color: var(--text-grey);">
                                <th style="padding: 8px 4px;">순위</th>
                                <th style="padding: 8px 4px;">종목명</th>
                                <th style="padding: 8px 4px; text-align: right;">현재가</th>
                                <th style="padding: 8px 4px; text-align: right;">등락률</th>
                            </tr>
                        </thead>
                        <tbody id="market-rank-list"></tbody>
                    </table>
                </div>
            </div>
        </div> </div> <%@ include file="common/sidebar.jsp" %>
    <%@ include file="common/sidebar-icons.jsp" %>
</div>

<script>
    if (!sessionStorage.getItem('visited')) {
        sessionStorage.setItem('visited', 'true');
        document.body.setAttribute('data-sidebar-closed', 'true');
    }

    let currentKospiPrice = 7500.00;
    let currentBtcPrice = 90000000;
</script>

<script src="https://unpkg.com/lightweight-charts/dist/lightweight-charts.standalone.production.js"></script>
<script src="/js/index.js"></script>
<script src="/js/common.js"></script>

</body>
</html>