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
    <title>TradeBot · 차트</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/chart-toss-coin.css">
</head><!-- /head -->

<!-- ====================================================
     [DOCUMENT BODY] body.chart-page
     ==================================================== -->
<body class="chart-page">
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
                <!--
                     위치 : .page > .main-layout
                     역할 : 차트, 주문/호가, 댓글 패널을 한 작업 화면에 배치합니다.

                     내부 구조:
                     trading workspace
                     ├─ chart panel
                     ├─ first resize handle
                     ├─ order book workspace
                     ├─ second resize handle
                     └─ chat panel
                -->

                <!-- ====================================================
                     [CHART PANEL] .panel-chart #panel-chart
                     ==================================================== -->
                <div class="card panel-chart" id="panel-chart">
                    <!--
                         위치 : .main-layout > #panel-chart.panel-chart
                         역할 : 차트 툴바와 실제 차트 렌더링 영역을 담는 메인 패널입니다.

                         내부 구조:
                         chart panel
                         ├─ chart toolbar
                         └─ chart stage
                    -->

                    <!-- ====================================================
                         [CHART TOOLBAR] .chart-toolbar
                         ==================================================== -->
                    <div class="chart-toolbar">
                        <!--
                             위치 : .panel-chart > .chart-toolbar
                             역할 : 시간 단위, 보조지표, 차트 설정을 조작하는 버튼 영역입니다.
                             연결 : 각 버튼은 차트 표시 상태를 바꾸는 사용자 입력 지점입니다.
                        -->
                        <div class="tf-dropdown-wrap">
                            <button class="tf-btn tf-dropdown-btn" id="current-tf-display">1분</button>
                            <div class="tf-dropdown-content">
                                <button class="tf-btn" data-tf onclick="changeTimeframe('1min')">1분</button>
                                <button class="tf-btn" data-tf onclick="changeTimeframe('3min')">3분</button>
                                <button class="tf-btn" data-tf onclick="changeTimeframe('5min')">5분</button>
                                <button class="tf-btn" data-tf onclick="changeTimeframe('15min')">15분</button>
                                <button class="tf-btn" data-tf onclick="changeTimeframe('30min')">30분</button>
                                <button class="tf-btn" data-tf onclick="changeTimeframe('1h')">1H</button>
                                <button class="tf-btn" data-tf onclick="changeTimeframe('4h')">4H</button>
                                <button class="tf-btn" data-tf onclick="changeTimeframe('6h')">6H</button>
                                <button class="tf-btn" data-tf onclick="changeTimeframe('12h')">12H</button>
                            </div>
                        </div>

                        <button class="tf-btn active" data-tf onclick="changeTimeframe('1day')">1D</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('3day')">3D</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('1week')">1W</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('1month')">1M</button>

                        <div class="tb-divider"></div>

                        <button class="ind-btn" id="ind-ma5" onclick="toggleInd('ma5')">MA5</button>
                        <button class="ind-btn" id="ind-ma20" onclick="toggleInd('ma20')">MA20</button>
                        <button class="ind-btn" id="ind-ma60" onclick="toggleInd('ma60')">MA60</button>
                        <button class="ind-btn" id="ind-bb" onclick="toggleInd('bb')">BB</button>
                        <button class="ind-btn" id="ind-ichimoku" onclick="toggleInd('ichimoku')">일목</button>
                        <button class="ind-btn" id="ind-rsi" onclick="toggleInd('rsi')">RSI</button>

                        <div class="tb-divider"></div>

                        <!-- ====================================================
                             [CHART SETTINGS] .settings-wrap
                             ==================================================== -->
                        <div class="settings-wrap">
                            <!--
                                 위치 : .chart-toolbar > .settings-wrap
                                 역할 : 차트 설정 버튼과 설정 드롭다운을 담습니다.
                            -->
                            <button class="ind-btn" onclick="toggleSettingsMenu()">
                                <span style="font-size:24px;">⚙</span>
                            </button>

                            <div class="settings-menu" id="settings-menu">
                                <div class="settings-title">차트 설정</div>

                                <label class="settings-item">
                                    <span class="settings-label"><span>최고 최저 가격</span></span>
                                    <input type="checkbox" id="set-highlow" onchange="toggleHighLow(this.checked)"
                                        checked>
                                </label>

                                <label class="settings-item">
                                    <span class="settings-label">
                                        <span>로그 스케일</span>
                                        <small>변화율 기준으로 차트 보기</small>
                                    </span>
                                    <input type="checkbox" id="set-log" onchange="toggleLog()">
                                </label>

                                <label class="settings-item">
                                    <span class="settings-label">
                                        <span>봉 카운트다운</span>
                                        <small>다음 봉까지 남은 시간 표시</small>
                                    </span>
                                    <input type="checkbox" id="set-countdown" onchange="toggleCountdown(this.checked)"
                                        checked>
                                </label>
                            </div>
                        </div><!-- /.settings-wrap -->
                    </div><!-- /.chart-toolbar -->

                    <!-- ====================================================
                         [CHART STAGE] #chart-wrapper
                         ==================================================== -->
                    <div id="chart-wrapper">
                        <!--
                             위치 : .panel-chart > #chart-wrapper
                             역할 : 가격 마커, 메인 차트, OHLC 표시, 카운트다운, RSI 보조 차트를 담는 차트 무대입니다.

                             내부 구조:
                             chart stage
                             ├─ high price marker
                             ├─ low price marker
                             ├─ main chart container
                             ├─ RSI divider
                             └─ RSI container
                        -->

                        <!-- ====================================================
                             [HIGH PRICE MARKER] #hl-high
                             ==================================================== -->
                        <div id="hl-high"
                            style="position:absolute;display:none;flex-direction:column;align-items:center;pointer-events:none;z-index:10;transform:translateX(-50%);">
                            <!--
                                 위치 : #chart-wrapper > #hl-high
                                 역할 : 차트 위에 최고가 위치를 표시하는 마커 영역입니다.
                            -->
                            <span id="hl-high-val" style="font-size:12px;color:var(--up);white-space:nowrap;"></span>
                            <span
                                style="color:var(--up);font-size:12px;display:block;transform:rotate(90deg);line-height:1;">⇒</span>
                        </div>

                        <!-- ====================================================
                             [LOW PRICE MARKER] #hl-low
                             ==================================================== -->
                        <div id="hl-low"
                            style="position:absolute;display:none;flex-direction:column;align-items:center;pointer-events:none;z-index:10;transform:translateX(-50%);">
                            <!--
                                 위치 : #chart-wrapper > #hl-low
                                 역할 : 차트 위에 최저가 위치를 표시하는 마커 영역입니다.
                            -->
                            <span
                                style="color:var(--down);font-size:12px;display:block;transform:rotate(-90deg);line-height:1;">⇒</span>
                            <span id="hl-low-val" style="font-size:12px;color:var(--down);white-space:nowrap;"></span>
                        </div>

                        <!-- ====================================================
                             [MAIN CHART CONTAINER] #chart-container
                             ==================================================== -->
                        <div id="chart-container">
                            <!--
                                 위치 : #chart-wrapper > #chart-container
                                 역할 : LightweightCharts가 실제 메인 차트를 그리는 영역입니다.
                                 연결 : OHLC 바와 봉 카운트다운 표시 영역도 함께 포함합니다.
                            -->
                            <div id="ohlc-bar">
                                <span>O: <b id="val-o">-</b></span>&nbsp;
                                <span>H: <b id="val-h">-</b></span>&nbsp;
                                <span>L: <b id="val-l">-</b></span>&nbsp;
                                <span>C: <b id="val-c">-</b></span>&nbsp;
                                <span id="val-oc-abs" style="font-size:11px;">-</span>&nbsp;
                                <span id="val-oc-pct" style="font-size:11px;">-</span>
                            </div>
                            <div id="countdown-box">
                                <span id="countdown-time"></span>
                            </div>
                        </div><!-- /#chart-container -->

                        <div id="pane-divider"></div>
                        <div id="rsi-container"></div>
                    </div><!-- /#chart-wrapper -->

                </div><!-- /.panel-chart -->

                <!-- ====================================================
                     [RESIZE HANDLE] .resize-h #rh-1
                     ==================================================== -->
                <div class="resize-h" id="rh-1"></div>

                <!-- ====================================================
                     [ORDER BOOK WORKSPACE] .panel-middle #panel-middle
                     ==================================================== -->
                <div class="panel-middle" id="panel-middle">
                    <!--
                         위치 : .main-layout > #panel-middle.panel-middle
                         역할 : 주문 입력 패널과 호가 패널을 세로로 담는 중간 작업 영역입니다.

                         내부 구조:
                         order book workspace
                         ├─ order panel
                         ├─ vertical resize handle
                         └─ order book panel
                    -->

                    <!-- ====================================================
                         [ORDER PANEL] .panel-order-wrap #panel-order-wrap
                         ==================================================== -->
                    <div class="card panel-order-wrap" id="panel-order-wrap">
                        <!--
                             위치 : .panel-middle > #panel-order-wrap.panel-order-wrap
                             역할 : 매수/매도 탭, 주문 유형, 가격/수량 입력, 주문 버튼을 담습니다.
                        -->
                        <div class="order-tabs">
                            <div class="order-tab buy active" id="tab-buy" onclick="switchOrderTab('buy')">매수</div>
                            <div class="order-tab sell" id="tab-sell" onclick="switchOrderTab('sell')">매도</div>
                        </div>

                        <!-- ====================================================
                             [ORDER FORM] .order-panel #panel-order
                             ==================================================== -->
                        <div class="order-panel" id="panel-order">
                            <!--
                                 위치 : .panel-order-wrap > #panel-order.order-panel
                                 역할 : 주문 유형, 가격, 수량, 비율, 주문금액, 제출 버튼을 담는 입력 폼 영역입니다.
                                 연결 : 사용자가 입력하거나 누르는 주문 관련 DOM이 모여 있습니다.
                            -->
                            <div class="order-type-row">
                                <button class="order-type-btn sel" onclick="selectOrderType(this)">지정가</button>
                                <button class="order-type-btn" onclick="selectOrderType(this)">시장가</button>
                            </div>

                            <div class="order-section-label">가격 (USDT)</div>
                            <div class="order-input-row">
                                <input class="order-input" id="trade-price-input" type="number" placeholder="0.00">
                                <span class="order-input-unit">USDT</span>
                            </div>

                            <div class="order-section-label">수량 (BTC)</div>
                            <div class="order-input-row">
                                <input class="order-input" id="trade-qty" type="number" placeholder="0.000" step="0.001"
                                    oninput="calcAmount()">
                                <div class="pct-drop-wrap" id="pct-drop-wrap">
                                    <div class="pct-drop-menu" id="pct-drop-menu" style="display:none;">
                                        <div class="pct-drop-item" onclick="setPercent(25)">25%</div>
                                        <div class="pct-drop-item" onclick="setPercent(50)">50%</div>
                                        <div class="pct-drop-item" onclick="setPercent(75)">75%</div>
                                        <div class="pct-drop-item" onclick="setPercent(100)">최대</div>
                                    </div>
                                    <button class="pct-drop-btn" onclick="togglePctDrop()">
                                        <span id="pct-drop-label">비율</span>
                                        <svg width="10" height="10" viewBox="0 0 10 10"><path d="M2 3.5l3 3 3-3" stroke="currentColor" stroke-width="1.4" fill="none" stroke-linecap="round"/></svg>
                                    </button>
                                </div>
                            </div>

                            <div class="order-info-row">
                                <span class="order-avail">가용 <span>- USDT</span></span>
                                <span class="order-amount-label">주문금액 <span id="trade-amount">0</span> USDT</span>
                            </div>

                            <button id="order-submit-btn" class="btn-buy" onclick="submitOrder(orderSide)">매수
                                주문</button>
                        </div><!-- /#panel-order.order-panel -->
                    </div><!-- /.panel-order-wrap -->

                    <!-- ====================================================
                         [VERTICAL RESIZE HANDLE] .resize-v #rh-v
                         ==================================================== -->
                    <div class="resize-v" id="rh-v"></div>

                    <!-- ====================================================
                         [ORDER BOOK PANEL] .panel-hoga #panel-hoga
                         ==================================================== -->
                    <div class="card panel-hoga" id="panel-hoga">
                        <!--
                             위치 : .panel-middle > #panel-hoga.panel-hoga
                             역할 : 매도 호가, 현재가, 매수 호가를 보여주는 호가 패널입니다.

                             내부 구조:
                             order book panel
                             ├─ order book header
                             ├─ ask rows
                             ├─ current price row
                             └─ bid rows
                        -->
                        <div class="hoga-header-row">
                            <span>호가</span>
                            <span>수량(BTC)</span>
                            <span>총량</span>
                        </div>
                        <div class="hoga-body">

                            <!-- ====================================================
                                 [ASK ROWS] .hoga-top
                                 ==================================================== -->
                            <div class="hoga-top">
                                <!--
                                     위치 : .hoga-body > .hoga-top
                                     역할 : 매도 호가 행이 들어가는 위쪽 영역입니다.
                                     연결 : 초기에는 뼈대 행을 보여주고, 실행 후 실제 호가 데이터로 바뀝니다.
                                -->
                                <table class="hoga-table">
                                    <tbody id="hoga-asks">
                                        <tr class="hoga-skel">
                                            <td class="hoga-ask">--,---.--</td>
                                            <td>-.------</td>
                                            <td>-.------</td>
                                        </tr>
                                        <tr class="hoga-skel">
                                            <td class="hoga-ask">--,---.--</td>
                                            <td>-.------</td>
                                            <td>-.------</td>
                                        </tr>
                                        <tr class="hoga-skel">
                                            <td class="hoga-ask">--,---.--</td>
                                            <td>-.------</td>
                                            <td>-.------</td>
                                        </tr>
                                        <tr class="hoga-skel">
                                            <td class="hoga-ask">--,---.--</td>
                                            <td>-.------</td>
                                            <td>-.------</td>
                                        </tr>
                                        <tr class="hoga-skel">
                                            <td class="hoga-ask">--,---.--</td>
                                            <td>-.------</td>
                                            <td>-.------</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>

                            <!-- ====================================================
                                 [CURRENT PRICE ROW] .hoga-mid #hoga-mid
                                 ==================================================== -->
                            <div class="hoga-mid" id="hoga-mid">
                                <!--
                                     위치 : .hoga-body > #hoga-mid.hoga-mid
                                     역할 : 매도/매수 호가 사이에서 현재 체결가와 변동 정보를 보여줍니다.
                                -->
                                <span id="hoga-cur-price">-</span>
                                <span class="hoga-mid-change" id="hoga-cur-change"></span>
                            </div>

                            <!-- ====================================================
                                 [BID ROWS] .hoga-bot
                                 ==================================================== -->
                            <div class="hoga-bot">
                                <!--
                                     위치 : .hoga-body > .hoga-bot
                                     역할 : 매수 호가 행이 들어가는 아래쪽 영역입니다.
                                     연결 : 초기에는 뼈대 행을 보여주고, 실행 후 실제 호가 데이터로 바뀝니다.
                                -->
                                <table class="hoga-table">
                                    <tbody id="hoga-bids">
                                        <tr class="hoga-skel">
                                            <td class="hoga-bid">--,---.--</td>
                                            <td>-.------</td>
                                            <td>-.------</td>
                                        </tr>
                                        <tr class="hoga-skel">
                                            <td class="hoga-bid">--,---.--</td>
                                            <td>-.------</td>
                                            <td>-.------</td>
                                        </tr>
                                        <tr class="hoga-skel">
                                            <td class="hoga-bid">--,---.--</td>
                                            <td>-.------</td>
                                            <td>-.------</td>
                                        </tr>
                                        <tr class="hoga-skel">
                                            <td class="hoga-bid">--,---.--</td>
                                            <td>-.------</td>
                                            <td>-.------</td>
                                        </tr>
                                        <tr class="hoga-skel">
                                            <td class="hoga-bid">--,---.--</td>
                                            <td>-.------</td>
                                            <td>-.------</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div><!-- /.panel-hoga -->

                </div><!-- /.panel-middle -->

                <!-- ====================================================
                     [RESIZE HANDLE] .resize-h #rh-2
                     ==================================================== -->
                <div class="resize-h" id="rh-2"></div>

                <!-- ====================================================
                     [CHAT PANEL] .panel-chat #panel-chat
                     ==================================================== -->
                <div class="card panel-chat" id="panel-chat">
                    <!--
                         위치 : .main-layout > #panel-chat.panel-chat
                         역할 : 실시간 댓글 목록과 댓글 입력 영역을 담습니다.

                         내부 구조:
                         chat panel
                         ├─ panel title
                         ├─ chat messages
                         └─ chat input
                    -->
                    <div class="panel-title-row">
                        <span class="panel-title">실시간 댓글</span>
                        <div class="chat-sort-tabs">
                            <button class="chat-sort-btn active" data-sort="latest">최신순</button>
                            <button class="chat-sort-btn" data-sort="popular">인기순</button>
                        </div>
                    </div>

                    <div class="chat-messages" id="chat-messages">
                        <div class="chat-empty">
                            <span class="chat-empty-icon">💬</span>
                            <span>첫 댓글을 남겨보세요</span>
                        </div>
                    </div>

                    <div class="chat-view-all" id="community-view-all" role="link" tabindex="0">전체 보기 ›</div>

                </div><!-- /.panel-chat -->

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

    <!-- ====================================================
         [SCRIPT LOAD] script
         ==================================================== -->
    <!--
         위치 : body 맨 아래
         역할 : HTML 구조가 먼저 만들어진 뒤 차트 라이브러리와 화면 동작 스크립트를 불러옵니다.
         연결 : currentSymbol은 서버에서 전달된 `${symbol}` 값을 JavaScript가 사용할 수 있게 보관합니다.
    -->
    <script src="https://unpkg.com/lightweight-charts@5.2.0/dist/lightweight-charts.standalone.production.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
    <div class="cm-image-modal" id="cmImageModal" onclick="this.classList.remove('open')">
        <img id="cmImageModalImg" src="" alt="">
    </div>
    <script src="https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js"></script>
    <script>
        window.currentSymbol = "${symbol}";
        document.addEventListener('DOMContentLoaded', () => {
            const communityLink = document.getElementById('community-view-all');
            if (!communityLink) return;

            const openCommunity = () => {
                const symbol = window.currentSymbol || 'BTCUSDT';
                window.location.href = '/coin/community?symbol=' + encodeURIComponent(symbol);
            };

            communityLink.addEventListener('click', openCommunity);
            communityLink.addEventListener('keydown', event => {
                if (event.key === 'Enter') openCommunity();
            });
        });
    </script>
    <script src="/js/common.js"></script>
    <script src="/js/coin/coin-common.js"></script>
    <script src="/js/coin/coin-order.js"></script>
    <script src="/js/coin/chart-toss-coin.js"></script>
</body>

</html>
