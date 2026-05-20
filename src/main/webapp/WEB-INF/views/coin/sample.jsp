<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>TradeBot · 커뮤니티 샘플</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/chart-toss-coin.css">
    <link rel="stylesheet" href="/css/coinCommunity.css">
    <style>
        .sample-page .price-header {
            min-height: 92px;
            border-bottom: 1px solid var(--border);
            background: var(--bg);
        }

        .sample-page .main-layout {
            display: grid;
            grid-template-columns: minmax(520px, 1fr) 360px;
            gap: var(--gap);
            padding: var(--gap) 50px 34px;
            overflow: hidden;
        }

        .sample-page .cm-feed-panel {
            min-width: 0;
        }

        .sample-page .cm-news-panel {
            width: auto;
            min-width: 0;
            max-width: none;
            flex-basis: auto;
        }

        .sample-page .cm-feed-list {
            padding: 0 28px 24px;
            overflow-y: auto;
        }

        .sample-feed-item {
            padding: 18px 0;
            border-bottom: 1px solid var(--border);
        }

        .sample-feed-head {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 10px;
        }

        .sample-feed-avatar {
            width: 34px;
            height: 34px;
            border-radius: 50%;
            background: #343741;
            color: var(--text2);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            font-weight: 700;
            flex-shrink: 0;
        }

        .sample-feed-user {
            font-size: 14px;
            font-weight: 700;
            color: var(--text);
        }

        .sample-feed-meta {
            font-size: 12px;
            color: var(--text3);
        }

        .sample-feed-body {
            margin: 0;
            font-size: 14px;
            line-height: 1.6;
            color: var(--text2);
        }

        .sample-feed-actions {
            display: flex;
            gap: 14px;
            margin-top: 12px;
            font-size: 12px;
            color: var(--text3);
        }

        @media (max-width: 980px) {
            .sample-page .main-layout {
                grid-template-columns: 1fr;
                padding: var(--gap) 18px 28px;
            }

            .sample-page .cm-feed-panel {
                border-right: 0;
                border-bottom: 1px solid var(--border);
            }
        }
    </style>
</head>
<body class="chart-page community-page sample-page" data-sidebar-tab="invest" data-sidebar-invest-tab="coin">
    <div class="app-wrapper">
        <div class="page">
            <%@ include file="../common/nav.jsp" %>

            <div class="price-header"></div>

            <div class="main-layout">
                <div class="card panel-chart cm-feed-panel">
                    <div class="cm-input-wrap">
                        <div class="cm-input-avatar">익</div>
                        <div class="cm-input-inner">
                            <textarea class="cm-input-box" placeholder="지금 무슨 생각을 하고 있나요?"></textarea>
                            <div class="cm-input-actions">
                                <button class="cm-input-icon-btn" title="이미지 업로드">
                                    <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18">
                                        <path d="M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z"/>
                                    </svg>
                                </button>
                                <button class="cm-input-icon-btn" title="작성 옵션">
                                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="18" height="18">
                                        <line x1="8" y1="6" x2="21" y2="6"/>
                                        <line x1="8" y1="12" x2="21" y2="12"/>
                                        <line x1="8" y1="18" x2="21" y2="18"/>
                                        <line x1="3" y1="6" x2="3.01" y2="6"/>
                                        <line x1="3" y1="12" x2="3.01" y2="12"/>
                                        <line x1="3" y1="18" x2="3.01" y2="18"/>
                                    </svg>
                                </button>
                            </div>
                        </div>
                    </div>

                    <div class="cm-feed-filter">
                        <button class="cm-filter-btn active">인기순</button>
                        <button class="cm-filter-btn">최신순</button>
                    </div>

                    <div class="cm-feed-list">
                        <div class="sample-feed-item">
                            <div class="sample-feed-head">
                                <div class="sample-feed-avatar">익</div>
                                <div>
                                    <div class="sample-feed-user">익명 투자자</div>
                                    <div class="sample-feed-meta">방금 전 · BTCUSDT</div>
                                </div>
                            </div>
                            <p class="sample-feed-body">오늘 거래량이 붙는 구간이 생각보다 탄탄합니다. 단기 저항선만 넘기면 흐름이 더 좋아질 수 있어 보입니다.</p>
                            <div class="sample-feed-actions">
                                <span>좋아요 12</span>
                                <span>댓글 4</span>
                                <span>공유</span>
                            </div>
                        </div>

                        <div class="sample-feed-item">
                            <div class="sample-feed-head">
                                <div class="sample-feed-avatar">차</div>
                                <div>
                                    <div class="sample-feed-user">차트보는사람</div>
                                    <div class="sample-feed-meta">12분 전 · ETHUSDT</div>
                                </div>
                            </div>
                            <p class="sample-feed-body">이더리움은 박스권 상단을 계속 두드리고 있어서 돌파 여부만 보면 될 듯합니다. 거래량 확인이 중요합니다.</p>
                            <div class="sample-feed-actions">
                                <span>좋아요 8</span>
                                <span>댓글 2</span>
                                <span>공유</span>
                            </div>
                        </div>

                        <div class="sample-feed-item">
                            <div class="sample-feed-head">
                                <div class="sample-feed-avatar">장</div>
                                <div>
                                    <div class="sample-feed-user">장기보유</div>
                                    <div class="sample-feed-meta">38분 전 · SOLUSDT</div>
                                </div>
                            </div>
                            <p class="sample-feed-body">단기 변동성은 커졌지만 네트워크 지표는 나쁘지 않습니다. 무리한 추격보다 눌림 구간을 기다리는 쪽이 편해 보입니다.</p>
                            <div class="sample-feed-actions">
                                <span>좋아요 21</span>
                                <span>댓글 9</span>
                                <span>공유</span>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card panel-chat cm-news-panel">
                    <div class="cm-panel-title">뉴스</div>
                    <div class="cm-news-list">
                        <div class="cm-news-item">
                            <span class="cm-news-source">코인데스크</span>
                            <span class="cm-news-time">5분 전</span>
                            <p class="cm-news-text">비트코인, 기관 매수세 지속에 변동성 확대</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">블록미디어</span>
                            <span class="cm-news-time">23분 전</span>
                            <p class="cm-news-text">이더리움 ETF 순유입 증가, 투자심리 회복</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">디지털애셋</span>
                            <span class="cm-news-time">1시간 전</span>
                            <p class="cm-news-text">연준 금리 동결 이후 위험자산 반등세</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">코인니스</span>
                            <span class="cm-news-time">2시간 전</span>
                            <p class="cm-news-text">솔라나 네트워크 업그레이드 완료</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">마켓워치</span>
                            <span class="cm-news-time">3시간 전</span>
                            <p class="cm-news-text">글로벌 암호화폐 시총, 주요 지표 개선</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <%@ include file="../common/sidebar.jsp" %>
        <%@ include file="../common/sidebar-icons.jsp" %>
    </div>

    <script src="/js/common.js"></script>
</body>
</html>
