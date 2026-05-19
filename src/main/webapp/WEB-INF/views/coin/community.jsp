<!-- ====================================================
     [JSP 지시어 읽기]
     이 JSP는 /coin/chart 화면의 HTML 구조를 만듭니다.
     page 지시어의 UTF-8 설정은 서버 응답과 파일 인코딩을 맞춰 한글 깨짐을 막습니다.
     ==================================================== -->
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<!-- ====================================================
     [이 파일을 읽는 법]

     JSP        : 서버에서 먼저 실행되어 최종 HTML을 만드는 파일
     page 지시어 : JSP의 언어, 응답 타입, 파일 인코딩을 설정
     include    : 공통 JSP 조각을 현재 위치에 합치는 지시어
     ${symbol}  : 서버가 Model 등에 담아 JSP로 전달한 현재 코인 심볼 값

     div        : 화면 영역을 나누는 기본 태그
     span       : 줄바꿈 없이 작은 텍스트나 값을 감싸는 태그
     button     : 시간 단위, 보조지표, 주문, 댓글 전송처럼 사용자가 클릭하는 태그
     input      : 종목 검색어, 주문 가격/수량, 체크박스 설정 값을 받는 태그
     label      : 체크박스와 설명 텍스트를 묶어 클릭 영역을 넓히는 태그
     table      : 호가처럼 행과 열로 된 데이터를 보여주는 표
     tbody      : JavaScript가 호가 행 같은 반복 데이터를 채울 수 있는 표 본문 영역
     svg        : 검색 아이콘, 관심 하트 아이콘처럼 벡터 그림을 그리는 태그
     script     : JavaScript 라이브러리, 서버값, 화면 동작 파일을 브라우저에 전달하는 태그
     link       : CSS 파일을 현재 HTML에 연결하는 태그

     class      : CSS가 여러 요소에 같은 스타일을 적용할 때 쓰는 이름
     id         : JavaScript가 특정 요소 하나를 정확히 찾을 때 주로 쓰는 이름
     data-*     : 화면에는 보이지 않지만 JavaScript가 읽을 값을 HTML에 저장하는 속성
     onclick    : 버튼이나 영역을 클릭했을 때 실행할 JavaScript 함수를 연결하는 속성
     onchange   : 체크박스나 설정값이 바뀔 때 실행할 JavaScript 함수를 연결하는 속성
     oninput    : 입력값이 바뀔 때 실행할 JavaScript 함수를 연결하는 속성
     readonly   : 사용자가 직접 수정하지 못하는 입력값
     checked    : 체크박스가 처음부터 선택된 상태로 보이게 하는 속성
     placeholder: 입력 전 보여주는 안내 문구
     autocomplete: 브라우저 자동완성 사용 여부를 정하는 속성
     style      : 태그에 직접 적는 인라인 CSS

     [이 화면의 연결 흐름]
     chart.jsp
     -> nav/sidebar JSP include
     -> common.css + chart-toss-coin.css로 화면 배치/스타일 적용
     -> LightweightCharts 라이브러리 로드
     -> common.js + chart-toss-coin.js 실행
     -> #chart-container에 차트 표시
     -> #ph-price, #ph-high, #ph-low 등에 종목 정보 표시
     -> #hoga-asks, #hoga-bids에 호가 행 표시
     -> #chat-messages에 댓글 표시
     -> #ticker-track에 시장 티커 표시

     [큰 화면 감싸는 구조]
     html
     ├─ document head
     │  ├─ meta charset
     │  ├─ title
     │  └─ stylesheet links
     └─ document body
        ├─ app shell
        │  ├─ main page
        │  │  ├─ nav include
        │  │  ├─ price header
        │  │  ├─ trading workspace
        │  │  │  ├─ chart panel
        │  │  │  ├─ first resize handle
        │  │  │  ├─ order book workspace
        │  │  │  ├─ second resize handle
        │  │  │  └─ chat panel
        │  │  └─ market ticker
        │  ├─ sidebar include
        │  └─ sidebar icons include
        └─ scripts
     ==================================================== -->
<!DOCTYPE html>
<html lang="ko">

<!-- ====================================================
     [DOCUMENT HEAD] head
     ==================================================== -->
<head>
    <!--
         위치 : html > head
         역할 : 문서 설정, 브라우저 탭 제목, 외부 CSS 파일 연결을 담당합니다.
         연결 : 공통 CSS와 차트 화면 전용 CSS를 불러옵니다.
    -->
    <meta charset="UTF-8">
    <title>TradeBot · 커뮤니티</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/chart-toss-coin.css">
    <link rel="stylesheet" href="/css/coinCommunity.css">
</head><!-- /head -->

<!-- ====================================================
     [DOCUMENT BODY] body.chart-page
     ==================================================== -->
<body class="chart-page community-page" data-sidebar-tab="invest" data-sidebar-invest-tab="coin">
    <!--
         위치 : html > body
         역할 : 브라우저에 실제로 보이는 차트 화면 전체를 담습니다.
         연결 : data-sidebar-tab="invest"는 공통 사이드바가 현재 투자 탭 상태를 알 수 있게 하는 값입니다.
    -->

    <!-- ====================================================
         [APP SHELL] .app-wrapper
         ==================================================== -->
    <div class="app-wrapper">
        <!--
             위치 : body > .app-wrapper
             역할 : 메인 페이지, 사이드바, 사이드바 아이콘을 함께 담는 최상위 화면 껍데기입니다.
             구성 : MAIN PAGE + SIDEBAR INCLUDE + SIDEBAR ICONS INCLUDE
        -->

        <!-- ====================================================
             [MAIN PAGE] .page
             ==================================================== -->
        <div class="page">
            <!--
                 위치 : .app-wrapper > .page
                 역할 : 상단 내비게이션, 가격 헤더, 차트/주문/댓글 본문을 세로로 담습니다.
                 구성 : NAV INCLUDE -> PRICE HEADER -> TRADING WORKSPACE -> MARKET TICKER
            -->

            <%-- ====================================================
                 [NAV INCLUDE] nav.jsp
                 ==================================================== --%>
            <%@ include file="../common/nav.jsp" %>
            <%--
                 위치 : .page 안에서 본문보다 먼저 합쳐지는 공통 상단 내비게이션
                 역할 : nav.jsp의 내용을 서버가 이 위치에 붙여 넣어 하나의 HTML로 만듭니다.
            --%>

            <!-- ====================================================
                 [PRICE HEADER] .price-header
                 ==================================================== -->
            <div class="price-header">
                <!--
                     위치 : .page > .price-header
                     역할 : 현재 종목명, 현재가, 24시간 통계, 관심 버튼을 보여주는 상단 요약 영역입니다.

                     내부 구조:
                     price header
                     ├─ price identity
                     ├─ market stats
                     └─ action buttons
                -->

                <!-- ====================================================
                     [PRICE IDENTITY] .ph-left
                     ==================================================== -->
                <div class="ph-left">
                    <!--
                         위치 : .price-header > .ph-left
                         역할 : 종목명, 심볼, 검색 드롭다운, 현재가와 전일대비 정보를 보여줍니다.
                         연결 : ${symbol}은 서버에서 전달된 현재 종목 심볼입니다.
                    -->
                    <div class="ph-name-row search-trigger" id="search-trigger">
                        <div class="ph-name-group">
                            <span class="ph-name" id="ph-display-name">Bitcoin</span>
                            <span class="ph-ticker">${symbol}</span>
                            <span class="ph-arrow">▾</span>
                        </div>

                        <!-- ====================================================
                             [SYMBOL SEARCH] .search-dropdown #search-dropdown
                             ==================================================== -->
                        <div class="search-dropdown" id="search-dropdown">
                            <!--
                                 위치 : .ph-name-row > .search-dropdown
                                 역할 : 종목을 검색하거나 인기 종목 목록을 보여주는 드롭다운 영역입니다.
                                 연결 : 검색 결과 목록은 실행 후 JavaScript가 채웁니다.
                            -->
                            <div class="sd-input-wrap">
                                <div class="sd-search-box">
                                    <svg class="sd-search-icon" viewBox="0 0 24 24">
                                        <circle cx="11" cy="11" r="8" />
                                        <path d="M21 21l-4.35-4.35" />
                                    </svg>
                                    <input type="text" id="sd-input" placeholder="종목 검색" autocomplete="off">
                                </div>
                            </div>

                            <div class="sd-content">
                                <div class="sd-label" id="sd-label">인기 검색</div>
                                <div class="sd-list" id="sd-list"></div>
                            </div>
                        </div><!-- /#search-dropdown.search-dropdown -->
                    </div>

                    <!-- ====================================================
                         [PRICE ROW] .ph-price-row
                         ==================================================== -->
                    <div class="ph-price-row">
                        <!--
                             위치 : .ph-left > .ph-price-row
                             역할 : 현재가, 전일대비 변동액, 전일대비 변동률을 한 줄로 보여줍니다.
                             연결 : 값은 처음에는 비어 있고 실행 후 JavaScript가 채웁니다.
                        -->
                        <span class="ph-price" id="ph-price">-</span>
                        <span
                            style="width:1px;height:16px;background:var(--border2);margin:0 6px;flex-shrink:0;align-self:center;"></span>
                        <span style="font-size:13px;color:var(--text3);font-weight:500;line-height:1;">전일대비</span>
                        <span class="ph-change" id="ph-change-abs">-</span>
                        <span class="ph-change" id="ph-change">-</span>
                    </div>
                </div><!-- /.ph-left -->

                <!-- ====================================================
                     [MARKET STATS] .ph-right
                     ==================================================== -->
                <div class="ph-right">
                    <!--
                         위치 : .price-header > .ph-right
                         역할 : 24시간 고가/저가, 거래량, 거래대금, 시가총액 정보를 보여줍니다.
                         연결 : 각 값은 실행 후 현재 종목 데이터로 채워집니다.
                    -->
                    <div class="ph-group">
                        <div class="ph-item">
                            <span class="ph-label">전날 종가</span>
                            <span class="ph-value" id="ph-prev-close">-</span>
                        </div>
                        <div class="ph-item">
                            <span class="ph-label">당일 시가</span>
                            <span class="ph-value" id="ph-open">-</span>
                        </div>
                    </div>

                    <div class="ph-vdivider"></div>

                    <div class="ph-group">
                        <div class="ph-item">
                            <span class="ph-label">24h 고가</span>
                            <span class="ph-value" id="ph-high">-</span>
                        </div>
                        <div class="ph-item">
                            <span class="ph-label">24h 저가</span>
                            <span class="ph-value" id="ph-low">-</span>
                        </div>
                    </div>

                    <div class="ph-vdivider"></div>

                    <div class="ph-group">
                        <div class="ph-item">
                            <span class="ph-label">24h 거래량 (BTC)</span>
                            <span class="ph-value" id="ph-vol">-</span>
                        </div>
                        <div class="ph-item">
                            <span class="ph-label">24h 거래대금 (USDT)</span>
                            <span class="ph-value" id="ph-turnover">-</span>
                        </div>
                    </div>

                    <div class="ph-vdivider"></div>

                    <div class="ph-group">
                        <div class="ph-item">
                            <span class="ph-label">시가총액</span>
                            <span class="ph-value" id="ph-mktcap">-</span>
                        </div>
                    </div>
                </div><!-- /.ph-right -->

                <!-- ====================================================
                     [PRICE ACTIONS] .ph-actions
                     ==================================================== -->
                <div class="ph-actions">
                    <!--
                         위치 : .price-header > .ph-actions
                         역할 : 현재 종목에 대한 사용자 액션 버튼을 담습니다.
                    -->
                    <button class="ph-like-btn" id="watchlist-btn" onclick="toggleWatchlist(currentSymbol)">
                        <svg viewBox="0 0 24 24">
                            <path
                                d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                        </svg>
                        관심
                    </button>
                </div><!-- /.ph-actions -->
            </div><!-- /.price-header -->

            <!-- ====================================================
                 [TRADING WORKSPACE] .main-layout
                 ==================================================== -->
            <div class="main-layout">
                <div class="card panel-chat cm-news-panel" id="panel-chat">
                    <div class="cm-panel-title">뉴스</div>
                    <div class="cm-news-list">
                        <div class="cm-news-item">
                            <span class="cm-news-source">코인데스크</span>
                            <span class="cm-news-time">5분 전</span>
                            <p class="cm-news-text">비트코인, 사상 최고가 경신 눈앞...기관 매수세 지속</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">블록미디어</span>
                            <span class="cm-news-time">23분 전</span>
                            <p class="cm-news-text">이더리움 ETF 순유입 3일 연속 증가...투자심리 회복</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">디지털애셋</span>
                            <span class="cm-news-time">1시간 전</span>
                            <p class="cm-news-text">연준 금리 동결에 암호화폐 시장 일제히 상승</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">코인니스</span>
                            <span class="cm-news-time">2시간 전</span>
                            <p class="cm-news-text">솔라나 네트워크 업그레이드 완료, 처리 속도 30% 향상</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">코인텔레그래프</span>
                            <span class="cm-news-time">3시간 전</span>
                            <p class="cm-news-text">글로벌 암호화폐 시총 3조 달러 돌파...강세장 진입 신호</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">블록미디어</span>
                            <span class="cm-news-time">5시간 전</span>
                            <p class="cm-news-text">바이낸스, 신규 코인 상장 발표...24시간 거래량 폭증</p>
                        </div>
                    </div>
                </div><!-- /.panel-chat -->

                <div class="resize-h" id="rh-1"></div>

                <div class="card panel-chart cm-feed-panel" id="panel-chart">
                    <div class="cm-input-wrap">
                        <div class="cm-input-avatar">익</div>
                        <div class="cm-input-inner">
                            <textarea class="cm-input-box" placeholder="지금 무슨 생각을 하고 있나요?"></textarea>
                            <div class="cm-input-actions">
                                <button class="cm-input-icon-btn" title="이미지 업로드">
                                    <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18">
                                        <path d="M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-1.1 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z"/>
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
                                <button class="cm-input-icon-btn" title="공유">
                                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="18" height="18">
                                        <polyline points="17 1 21 5 17 9"/>
                                        <path d="M3 11V9a4 4 0 0 1 4-4h14"/>
                                        <polyline points="7 23 3 19 7 15"/>
                                        <path d="M21 13v2a4 4 0 0 1-4 4H3"/>
                                    </svg>
                                </button>
                            </div>
                        </div>
                    </div>

                    <div class="cm-feed-filter">
                        <button class="cm-filter-btn active">인기순 ⇅</button>
                    </div>

                    <div class="cm-feed-list" id="cmFeedList">
                        <div class="chat-empty">
                            <span class="chat-empty-icon">💬</span>
                            <span>첫 댓글을 남겨보세요</span>
                        </div>
                    </div>
                </div><!-- /.panel-chart -->

                <div class="resize-h" id="rh-2"></div>

                <div class="panel-middle cm-order-panel" id="panel-middle">
                    <div class="card panel-order-wrap" id="panel-order-wrap">
                        <div class="order-tabs">
                            <div class="order-tab buy active" id="tab-buy" onclick="switchOrderTab('buy')">매수</div>
                            <div class="order-tab sell" id="tab-sell" onclick="switchOrderTab('sell')">매도</div>
                        </div>

                        <div class="order-panel" id="panel-order">
                            <div class="order-type-row">
                                <button class="order-type-btn sel" onclick="selectOrderType(this)">지정가</button>
                                <button class="order-type-btn" onclick="selectOrderType(this)">시장가</button>
                            </div>

                            <div class="order-section-label">가격 (USDT)</div>
                            <div class="order-input-row">
                                <input class="order-input" id="trade-price-input" type="number" placeholder="0.00" oninput="calcAmount()">
                                <span class="order-input-unit">USDT</span>
                            </div>

                            <div class="order-section-label">수량</div>
                            <div class="order-input-row">
                                <input class="order-input" id="trade-qty" type="number" placeholder="0.000" step="0.001" oninput="calcAmount()">
                                <span class="order-input-unit" id="cm-qty-unit">${symbol}</span>
                            </div>

                            <div class="pct-row">
                                <button class="pct-btn" onclick="setPercent(25)">25%</button>
                                <button class="pct-btn" onclick="setPercent(50)">50%</button>
                                <button class="pct-btn" onclick="setPercent(75)">75%</button>
                                <button class="pct-btn" onclick="setPercent(100)">최대</button>
                            </div>

                            <div class="order-section-label">주문금액 (USDT)</div>
                            <div class="order-input-row" style="margin-bottom:14px">
                                <input class="order-input" id="trade-amount" type="number" readonly style="background:var(--bg)">
                                <span class="order-input-unit">USDT</span>
                            </div>

                            <div class="order-avail">가용 잔고 <span>- USDT</span></div>
                            <button id="order-submit-btn" class="btn-buy" onclick="submitCommunityOrder()">매수 주문</button>
                        </div><!-- /#panel-order.order-panel -->
                    </div><!-- /.panel-order-wrap -->
                </div><!-- /.panel-middle -->

            </div><!-- /.main-layout -->

            <!-- ====================================================
                 [MARKET TICKER] .ticker-bar
                 ==================================================== -->
            <div class="ticker-bar">
                <!--
                     위치 : .page > .ticker-bar
                     역할 : 화면 하단 또는 보조 위치에서 시장 티커 흐름을 보여주는 영역입니다.
                     연결 : ticker-track 내부는 실행 후 JavaScript가 채울 수 있습니다.
                -->
                <div class="ticker-track" id="ticker-track"></div>
            </div>

        </div><!-- /.page -->

        <%-- ====================================================
             [SIDEBAR INCLUDE] sidebar.jsp
             ==================================================== --%>
        <%@ include file="../common/sidebar.jsp" %>
        <%--
             위치 : .app-wrapper 안에서 .page 다음에 합쳐지는 공통 사이드바 영역
             역할 : sidebar.jsp의 내용을 현재 화면에 포함합니다.
        --%>

        <%-- ====================================================
             [SIDEBAR ICONS INCLUDE] sidebar-icons.jsp
             ==================================================== --%>
        <%@ include file="../common/sidebar-icons.jsp" %>
        <%--
             위치 : .app-wrapper 안에서 sidebar.jsp 다음에 합쳐지는 사이드바 아이콘 영역
             역할 : sidebar-icons.jsp의 내용을 현재 화면에 포함합니다.
        --%>

    </div><!-- /.app-wrapper -->

    <div class="cm-image-modal" id="cmImageModal" onclick="this.classList.remove('open')">
        <img id="cmImageModalImg" src="" alt="">
    </div>

<script src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js"></script>
<script src="/js/common.js"></script>
<script>
    const currentSymbol = "${symbol}";
    let orderSide = 'buy';


    function switchOrderTab(side) {
        orderSide = side;
        const isBuy = side === 'buy';
        document.getElementById('tab-buy').classList.toggle('active', isBuy);
        document.getElementById('tab-sell').classList.toggle('active', !isBuy);
        const submitBtn = document.getElementById('order-submit-btn');
        submitBtn.textContent = isBuy ? '매수 주문' : '매도 주문';
        submitBtn.className = isBuy ? 'btn-buy' : 'btn-sell';
    }

    function selectOrderType(btn) {
        document.querySelectorAll('.order-type-btn').forEach(el => el.classList.remove('sel'));
        btn.classList.add('sel');
        const priceInput = document.getElementById('trade-price-input');
        const isLimit = btn.textContent.trim() === '지정가';
        priceInput.readOnly = !isLimit;
        if (!isLimit && !priceInput.value) priceInput.value = document.getElementById('ph-price').textContent.replace(/[^0-9.]/g, '');
        calcAmount();
    }

    function setPercent(pct) {
        const price = parseFloat(document.getElementById('trade-price-input').value) || 0;
        if (price <= 0) return;
        const mockBalance = 10000;
        document.getElementById('trade-qty').value = (mockBalance * pct / 100 / price).toFixed(6);
        calcAmount();
    }

    function calcAmount() {
        const price = parseFloat(document.getElementById('trade-price-input').value) || 0;
        const qty = parseFloat(document.getElementById('trade-qty').value) || 0;
        document.getElementById('trade-amount').value = (price * qty).toFixed(2);
    }

    function submitCommunityOrder() {
        const qty = document.getElementById('trade-qty').value;
        if (!qty || parseFloat(qty) <= 0) {
            alert('수량을 입력하세요');
            return;
        }
        alert((orderSide === 'buy' ? '매수' : '매도') + ' 주문 기능은 준비 중입니다.');
    }

    async function loadCmMarketCap() {
        const ticker = currentSymbol.replace(/USDT$/, '').replace(/USDC$/, '').replace(/_SPBL$/, '').toLowerCase();
        try {
            const res = await fetch('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&symbols=' + encodeURIComponent(ticker) + '&order=market_cap_desc&per_page=1&page=1&sparkline=false').then(r => r.json());
            const mktcap = Array.isArray(res) && res[0] ? Number(res[0].market_cap) : NaN;
            document.getElementById('ph-mktcap').textContent = Number.isFinite(mktcap) ? '$' + fmtNum(mktcap) : '-';
        } catch (e) {
            document.getElementById('ph-mktcap').textContent = '-';
        }
    }

    let cmPrevClose = 0;
    let cmPriceWs = null;

    async function loadCmTicker() {
        try {
            const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers?symbol=' + encodeURIComponent(currentSymbol)).then(r => r.json());
            const d = res && res.data && res.data[0];
            if (!d) return;
            const price = parseFloat(d.lastPr);
            const candleRes = await fetch('https://api.bitget.com/api/v2/spot/market/candles?symbol=' + encodeURIComponent(currentSymbol) + '&granularity=1Dutc&limit=2').then(r => r.json());
            cmPrevClose = parseFloat(candleRes.data[0][4]);
            const todayOpen = parseFloat(candleRes.data[1][1]);
            const tickerName = currentSymbol.replace(/USDT$/, '').replace(/USDC$/, '').replace(/_SPBL$/, '');

            document.getElementById('ph-display-name').textContent = tickerName;
            document.querySelector('.ph-ticker').textContent = currentSymbol;
            document.getElementById('cm-qty-unit').textContent = tickerName;
            document.getElementById('ph-prev-close').textContent = '$' + cmPrevClose.toLocaleString(undefined, { maximumFractionDigits: 6 });
            document.getElementById('ph-open').textContent = '$' + todayOpen.toLocaleString(undefined, { maximumFractionDigits: 6 });
            document.getElementById('ph-high').textContent = '$' + parseFloat(d.high24h).toLocaleString(undefined, { maximumFractionDigits: 6 });
            document.getElementById('ph-low').textContent = '$' + parseFloat(d.low24h).toLocaleString(undefined, { maximumFractionDigits: 6 });
            document.getElementById('ph-vol').textContent = fmtNum(parseFloat(d.baseVolume)) + ' ' + tickerName;
            document.getElementById('ph-turnover').textContent = fmtNum(parseFloat(d.quoteVolume)) + ' USDT';
            document.getElementById('trade-price-input').value = Number.isFinite(price) ? price : '';
            updateCmPriceHeader(price);
            calcAmount();
        } catch (e) {}
    }

    function updateCmPriceHeader(price) {
        document.getElementById('ph-price').textContent = '$' + price.toLocaleString(undefined, { maximumFractionDigits: 6 });
        if (cmPrevClose > 0) {
            const absChange = price - cmPrevClose;
            const chgPct = (absChange / cmPrevClose) * 100;
            const cls = chgPct >= 0 ? 'up' : 'down';
            const sign = chgPct >= 0 ? '+' : '';
            const absEl = document.getElementById('ph-change-abs');
            const pctEl = document.getElementById('ph-change');
            if (absEl) { absEl.textContent = sign + absChange.toLocaleString(undefined, { maximumFractionDigits: 6 }); absEl.className = 'ph-change ' + cls; }
            if (pctEl) { pctEl.textContent = '(' + sign + chgPct.toFixed(2) + '%)'; pctEl.className = 'ph-change ' + cls; }
        }
    }

    function connectCmPriceWs() {
        if (cmPriceWs) cmPriceWs.close();
        cmPriceWs = new WebSocket('wss://ws.bitget.com/v2/ws/public');
        cmPriceWs.onopen = () => {
            cmPriceWs.send(JSON.stringify({ op: 'subscribe', args: [{ instType: 'SPOT', channel: 'ticker', instId: currentSymbol }] }));
            setInterval(() => cmPriceWs.readyState === 1 && cmPriceWs.send('ping'), 20000);
        };
        cmPriceWs.onmessage = (event) => {
            if (event.data === 'pong') return;
            const msg = JSON.parse(event.data);
            if (!msg.data || !msg.arg || msg.arg.channel !== 'ticker') return;
            const price = parseFloat(msg.data[0].lastPr);
            if (price) updateCmPriceHeader(price);
        };
        cmPriceWs.onclose = () => setTimeout(connectCmPriceWs, 3000);
    }

    loadCmTicker();
    loadCmMarketCap();
    connectCmPriceWs();

    /* ── 종목 검색 드롭다운 ── */
    let allCoinList = [], popularCoins = [];

    function renderSearchList(list, isPopular) {
        const container = document.getElementById('sd-list');
        if (!container) return;
        container.innerHTML = list.map((c, i) => {
            const ticker = c.symbol.replace('USDT', '');
            const change = parseFloat(c.change24h) * 100;
            const cls = change >= 0 ? 'up' : 'down';
            const sign = change >= 0 ? '+' : '';
            const logoUrl = 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/' + ticker.toLowerCase() + '.png';
            return '<div class="sd-item" onclick="location.href=\'/coin/chart?symbol=' + c.symbol + '\'">' +
                (isPopular ? '<span class="sd-rank">' + (i + 1) + '</span>' : '') +
                '<div class="sd-coin-logo"><img src="' + logoUrl + '" alt="' + ticker + '" onerror="this.style.display=\'none\';this.parentElement.textContent=\'' + ticker.slice(0, 2) + '\'"></div>' +
                '<div class="sd-info"><div class="sd-name-row"><span class="sd-name">' + ticker + '</span><span class="sd-symbol">' + c.symbol + '</span></div></div>' +
                '<div class="sd-change ' + cls + '">' + sign + change.toFixed(2) + '%</div>' +
            '</div>';
        }).join('');
    }

    async function initSearchMenu() {
        const trigger = document.getElementById('search-trigger');
        const dropdown = document.getElementById('search-dropdown');
        const input = document.getElementById('sd-input');
        if (!trigger || !dropdown || !input) return;

        trigger.addEventListener('click', e => {
            e.stopPropagation();
            const isActive = dropdown.classList.toggle('active');
            if (isActive) { input.value = ''; input.focus(); renderSearchList(popularCoins, true); }
        });
        document.addEventListener('click', () => dropdown.classList.remove('active'));
        dropdown.addEventListener('click', e => e.stopPropagation());

        try {
            const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers').then(r => r.json());
            if (res.data) {
                allCoinList = res.data.filter(c => c.symbol.endsWith('USDT'));
                popularCoins = [...allCoinList].sort((a, b) => parseFloat(b.quoteVolume) - parseFloat(a.quoteVolume)).slice(0, 5);
                renderSearchList(popularCoins, true);
            }
        } catch (e) {}

        input.addEventListener('input', () => {
            const keyword = input.value.trim().toUpperCase();
            if (!keyword) { document.getElementById('sd-label').textContent = '인기 검색'; renderSearchList(popularCoins, true); return; }
            const filtered = allCoinList.filter(c => c.symbol.includes(keyword) || c.symbol.replace('USDT', '').includes(keyword)).slice(0, 20);
            document.getElementById('sd-label').textContent = '검색 결과';
            renderSearchList(filtered, false);
        });
    }

    initSearchMenu();

    /* ── 하단 티커바 ── */
    const CM_TICKER_SYMBOLS = [currentSymbol, 'ETHUSDT', 'XRPUSDT', 'SOLUSDT', 'DOGEUSDT', 'ADAUSDT', 'AVAXUSDT', 'DOTUSDT'];
    let cmTickerX = 0, cmTickerPaused = false, cmTickerHalfWidth = 0, cmTickerTrackEl = null;

    async function loadCmTickerBar() {
        const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers').then(r => r.json()).catch(() => null);
        if (!res || !res.data) return;
        const filtered = res.data.filter(d => CM_TICKER_SYMBOLS.includes(d.symbol));
        const track = document.getElementById('ticker-track');
        if (!track.children.length) {
            const items = filtered.map(d => {
                const change = parseFloat(d.change24h) * 100;
                const cls = change >= 0 ? 'up' : 'down';
                const sign = change >= 0 ? '+' : '';
                return '<div class="ticker-item"><span class="ticker-name">' + d.symbol.replace('USDT', '') + '</span><span class="ticker-price">' + parseFloat(d.lastPr).toLocaleString() + '</span><span class="ticker-change ' + cls + '">' + sign + change.toFixed(2) + '%</span></div>';
            }).join('');
            track.innerHTML = items + items + items + items;
            setTimeout(() => { cmTickerHalfWidth = track.scrollWidth / 2; cmTickerTrackEl = track; }, 500);
            return;
        }
        const allItems = track.querySelectorAll('.ticker-item');
        filtered.forEach((d, i) => {
            const change = parseFloat(d.change24h) * 100;
            const cls = change >= 0 ? 'up' : 'down';
            const sign = change >= 0 ? '+' : '';
            [allItems[i], allItems[i + filtered.length]].forEach(el => {
                if (!el) return;
                el.querySelector('.ticker-price').textContent = parseFloat(d.lastPr).toLocaleString();
                const changeEl = el.querySelector('.ticker-change');
                changeEl.textContent = sign + change.toFixed(2) + '%';
                changeEl.className = 'ticker-change ' + cls;
            });
        });
    }

    function animateCmTicker() {
        if (!cmTickerPaused && cmTickerHalfWidth > 0 && cmTickerTrackEl) {
            cmTickerX -= 0.6;
            if (Math.abs(cmTickerX) >= cmTickerHalfWidth) cmTickerX += cmTickerHalfWidth;
            cmTickerTrackEl.style.transform = 'translateX(' + cmTickerX + 'px)';
        }
        requestAnimationFrame(animateCmTicker);
    }

    const _cmTickerEl = document.getElementById('ticker-track');
    if (_cmTickerEl) {
        _cmTickerEl.addEventListener('mouseenter', () => cmTickerPaused = true);
        _cmTickerEl.addEventListener('mouseleave', () => cmTickerPaused = false);
    }

    loadCmTickerBar();
    setInterval(loadCmTickerBar, 15000);
    animateCmTicker();

    /* ── 커뮤니티 피드 실시간 댓글 ── */
    let _stompClient = null;

    function cmFeedAvatarColor(name) {
        const palette = ['#4caf50','#2196f3','#e91e63','#ff9800','#9c27b0','#00bcd4','#f44336','#3f51b5','#009688','#795548'];
        let h = 0;
        for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) & 0x7fffffff;
        return palette[h % palette.length];
    }

    function cmFeedRelTime(createdAt) {
        if (!createdAt) return '';
        const diff = Date.now() - new Date(createdAt).getTime();
        const m = Math.floor(diff / 60000);
        if (m < 1) return '방금';
        if (m < 60) return m + '분';
        const h = Math.floor(m / 60);
        if (h < 24) return h + '시간';
        return Math.floor(h / 24) + '일';
    }

    function appendFeedMsg(username, content, createdAt, scroll, imageUrl) {
        const feed = document.getElementById('cmFeedList');
        const empty = feed.querySelector('.chat-empty');
        if (empty) empty.remove();

        const safe = s => String(s).replace(/</g, '&lt;');
        const color = cmFeedAvatarColor(username);
        const initial = username.charAt(0).toUpperCase();
        const time = cmFeedRelTime(createdAt);
        const MAX = 100;
        const isTrunc = content.length > MAX;
        const preview = isTrunc ? safe(content.slice(0, MAX)) + '...' : safe(content);
        const full = safe(content);
        const imgHtml = imageUrl ? '<img class="cm-image" src="' + imageUrl + '" alt="" onclick="cmOpenImage(this)">' : '';

        const div = document.createElement('div');
        div.className = 'cm-feed-item';
        div.innerHTML =
            '<div class="cm-left">' +
                '<div class="cm-avatar" style="background:' + color + '">' + initial + '</div>' +
                '<span class="cm-rank">주주</span>' +
            '</div>' +
            '<div class="cm-right">' +
                '<div class="cm-meta">' +
                    '<span class="cm-name">' + safe(username) + '</span>' +
                    '<span class="cm-time">' + time + '</span>' +
                    '<button class="cm-follow-btn">팔로우</button>' +
                '</div>' +
                '<div class="cm-text" data-full="' + full.replace(/"/g, '&quot;') + '" data-trunc="' + (isTrunc ? '1' : '0') + '">' +
                    preview +
                    (isTrunc ? ' <button class="cm-more-btn" onclick="cmFeedToggleMore(this)">더 보기</button>' : '') +
                '</div>' +
                imgHtml +
                '<div class="cm-feed-actions">' +
                    '<button class="cm-action-btn cm-like-btn">' +
                        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" width="16" height="16"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>' +
                        '<span>0</span>' +
                    '</button>' +
                    '<button class="cm-action-btn cm-reply-btn">' +
                        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" width="16" height="16"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>' +
                        '<span>0</span>' +
                    '</button>' +
                    '<button class="cm-action-btn cm-share-btn">' +
                        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" width="16" height="16"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>' +
                    '</button>' +
                '</div>' +
            '</div>';

        /* 좋아요 토글 */
        const likeBtn = div.querySelector('.cm-like-btn');
        likeBtn.addEventListener('click', function() {
            const liked = this.dataset.liked === '1';
            const countEl = this.querySelector('span');
            const count = parseInt(countEl.textContent) || 0;
            this.dataset.liked = liked ? '0' : '1';
            countEl.textContent = liked ? count - 1 : count + 1;
            const svg = this.querySelector('svg');
            svg.style.fill = liked ? 'none' : '#e91e63';
            svg.style.stroke = liked ? 'currentColor' : '#e91e63';
        });

        feed.prepend(div);
    }

    function cmFeedToggleMore(btn) {
        const textEl = btn.parentElement;
        textEl.innerHTML = textEl.dataset.full + ' <button class="cm-more-btn" onclick="cmFeedToggleLess(this)">접기</button>';
    }

    function cmFeedToggleLess(btn) {
        const textEl = btn.parentElement;
        const MAX = 100;
        const preview = textEl.dataset.full.slice(0, MAX) + '...';
        textEl.innerHTML = preview + ' <button class="cm-more-btn" onclick="cmFeedToggleMore(this)">더 보기</button>';
    }

    function loadCommunityFeedHistory(symbol) {
        fetch('/coin/comments/' + symbol)
            .then(r => r.json())
            .then(list => {
                const feed = document.getElementById('cmFeedList');
                feed.innerHTML = '';
                if (!list.length) {
                    feed.innerHTML = '<div class="chat-empty"><span class="chat-empty-icon">💬</span><span>첫 댓글을 남겨보세요</span></div>';
                    return;
                }
                list.forEach(dto => appendFeedMsg(dto.username, dto.content, dto.createdAt, false, dto.imageUrl));
            })
            .catch(() => {});
    }

    function connectCommunityFeed(symbol) {
        if (_stompClient) _stompClient.disconnect();
        const socket = new SockJS('/ws-coin');
        _stompClient = Stomp.over(socket);
        _stompClient.debug = null;
        _stompClient.connect({}, () => {
            _stompClient.subscribe('/topic/coin/' + symbol, msg => {
                const dto = JSON.parse(msg.body);
                appendFeedMsg(dto.username, dto.content, dto.createdAt, true, dto.imageUrl);
            });
            loadCommunityFeedHistory(symbol);
        });
    }

    connectCommunityFeed(currentSymbol);
</script>

</body>

</html>
