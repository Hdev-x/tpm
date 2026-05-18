<!-- ====================================================
     [JSP 지시어 읽기]
     이 JSP는 /coin/list 화면의 HTML 뼈대를 만듭니다.
     page 지시어의 UTF-8 설정은 서버가 만든 HTML과 파일 자체의 한글 인코딩을 맞춥니다.
     ==================================================== -->
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<!-- ====================================================
     [이 파일을 읽는 법]

     JSP        : 서버에서 먼저 실행되어 최종 HTML을 만드는 파일
     page 지시어 : JSP의 언어, 응답 타입, 파일 인코딩을 설정
     include    : 다른 JSP 조각을 현재 위치에 합침

     div        : 화면 영역을 나누는 기본 태그
     span       : 줄바꿈 없이 작은 텍스트나 값을 감싸는 태그
     button     : 사용자가 클릭할 수 있는 버튼 태그
     table      : 표 전체
     thead      : 표의 제목 영역
     tbody      : 실제 데이터 행이 들어가는 영역
     tr         : 표의 한 줄
     th         : 표의 제목 칸
     svg        : 브라우저에서 직접 그리는 벡터 그림 영역
     polyline   : SVG 안에서 여러 점을 이어 선을 그리는 태그

     class      : CSS가 여러 요소에 스타일을 적용할 때 쓰는 이름
     id         : JavaScript가 특정 요소 하나를 정확히 찾을 때 주로 쓰는 이름
     data-*     : 화면에는 보이지 않지만 JS가 읽을 값을 HTML에 저장하는 속성
     disabled   : 버튼이나 입력 요소를 클릭/입력할 수 없게 만드는 속성
     href       : link/a 태그에서 연결할 주소
     src        : img/script 태그에서 불러올 파일 주소
     style      : HTML 태그에 직접 적는 인라인 CSS

     [이 화면의 연결 흐름]
     list.jsp
     -> nav/sidebar JSP include
     -> common.css + coinList.css로 화면 배치/스타일 적용
     -> common.js + coinList.js 실행
     -> Bitget API/WebSocket 데이터 수신
     -> #stockTableBody에 코인 행 추가
     -> #detailPanel에 선택 코인 상세 정보 표시

     [큰 화면 감싸는 구조]
     html
     ├─ document head
     │  ├─ meta charset
     │  ├─ title
     │  └─ link stylesheet
     └─ document body
        ├─ app shell
        │  ├─ main page
        │  │  ├─ nav include
        │  │  └─ coin list content
        │  │     ├─ market summary
        │  │     ├─ tab controls
        │  │     ├─ realtime workspace
        │  │     │  ├─ filters
        │  │     │  └─ split layout
        │  │     │     ├─ coin table panel
        │  │     │     └─ detail panel
        │  │     └─ hidden tab placeholders
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
         역할 : 화면에 직접 보이는 내용이 아니라, 문서 설정과 외부 파일 연결을 담당하는 영역

         meta charset : HTML 문서의 문자 인코딩 설정. UTF-8은 한글 깨짐을 막기 위해 사용합니다.
         title        : 브라우저 탭에 표시되는 페이지 제목입니다.
         link         : 외부 CSS 파일을 현재 HTML에 연결하는 태그입니다.
         rel          : 연결한 파일의 관계입니다. stylesheet는 CSS 파일이라는 뜻입니다.
         href         : 불러올 외부 파일의 주소입니다.

         [CSS 연결]
         Pretendard CDN : 외부 폰트 파일
         /css/common.css : nav/sidebar 등 공통 레이아웃 스타일
         /css/coinList.css : coin/list 화면 전용 스타일
    -->
    <meta charset="UTF-8">
    <title>TradeBot · 코인 리스트</title>
    <link rel="stylesheet"
        href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/coinList.css">
</head><!-- /head -->

<!-- ====================================================
     [DOCUMENT BODY] body
     ==================================================== -->
<body>
    <!--
         위치 : html > body
         역할 : 브라우저 화면에 실제로 보이는 모든 요소를 담는 영역

         속성:
           - data-sidebar-animate="true": HTML에 저장된 설정값입니다.
             common.js나 공통 sidebar 스크립트가 사이드바 애니메이션 여부를 판단할 때 사용할 수 있습니다.
    -->

    <!-- ====================================================
         [APP SHELL] .app-wrapper
         ==================================================== -->
    <div class="app-wrapper">
        <!--
             위치 : body > .app-wrapper
             역할 : 메인 페이지, 사이드바, 사이드바 아이콘을 한 화면에 배치하는 최상위 앱 껍데기
             연결 : 공통 레이아웃의 바깥 감싸개입니다.
        -->

        <!-- ====================================================
             [MAIN PAGE] .page
             ==================================================== -->
        <div class="page">
            <!--
                 위치 : .app-wrapper > .page
                 역할 : nav.jsp와 코인 리스트 본문을 세로로 담는 메인 화면 영역
                 연결 : 상단 내비게이션과 본문을 함께 담습니다.
            -->

            <%-- ====================================================
                 [NAV INCLUDE] nav.jsp
                 ==================================================== --%>
            <%@ include file="../common/nav.jsp" %>
            <%--
                 위치 : .page 안에서 .main-content보다 먼저 합쳐지는 공통 상단 내비게이션
                 역할 : nav.jsp 파일의 내용을 서버가 이 위치에 붙여 넣어 하나의 HTML로 만듭니다.
                 주의 : JSP include 설명은 브라우저 최종 HTML에 남기지 않기 위해 JSP 전용 주석을 사용합니다.
            --%>

            <!-- ====================================================
                 [COIN LIST CONTENT] .main-content
                 ==================================================== -->
            <div class="main-content">
                <!--
                     위치 : .page > .main-content
                     역할 : 코인 리스트 화면의 실제 본문입니다.
                     구성 : MARKET SUMMARY -> TAB CONTROLS -> REALTIME WORKSPACE
                     연결 : coinList.css가 본문 레이아웃을 담당합니다.
                -->

                <!-- ====================================================
                     [MARKET SUMMARY] .ticker-bar
                     ==================================================== -->
                <div class="ticker-bar">
                    <!--
                         위치 : .main-content > .ticker-bar
                         역할 : 화면 상단에서 환율/지수 요약을 보여주는 정적 시장 요약 영역
                         연결 : 현재는 API 없이 JSP에 직접 적힌 정적 마크업입니다.
                    -->
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
                </div><!-- /.ticker-bar -->

                <!-- ====================================================
                     [TAB CONTROLS] .main-tabs
                     ==================================================== -->
                <div class="main-tabs">
                    <!--
                         위치 : .main-content > .main-tabs
                         역할 : 현재 보여줄 탭 본문을 선택하는 버튼 영역
                         연결 : data-tab 값으로 탭 본문과 연결됩니다.
                    -->
                    <button class="main-tab active" data-tab="realtime">실시간 차트</button>

                </div><!-- /.main-tabs -->

                <!-- ====================================================
                     [REALTIME WORKSPACE] .tab-content #tab-realtime
                     ==================================================== -->
                <div class="tab-content" id="tab-realtime">
                    <!--
                         위치 : .main-content > #tab-realtime.tab-content
                         역할 : 필터, 좌측 코인 테이블, 우측 상세 패널을 담는 실제 본문
                         연결 : 탭 버튼에서 선택되는 실시간 화면 영역입니다.
                    -->

                    <!-- ====================================================
                         [FILTER ROW] .filter-row
                         ==================================================== -->
                    <div class="filter-row">
                        <!--
                             위치 : #tab-realtime > .filter-row
                             역할 : 마켓, 정렬, 시간 필터 버튼을 보여주는 영역
                             연결 : 사용자가 누르는 필터 버튼 묶음입니다.
                        -->
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

                    </div><!-- /.filter-row -->

                    <!-- ====================================================
                         [CONTENT SPLIT] .content-layout
                         ==================================================== -->
                    <div class="content-layout">
                        <!--
                             위치 : #tab-realtime > .content-layout
                             역할 : 좌측 리스트 패널과 우측 상세 패널을 가로로 나누는 영역
                             구성 : COIN TABLE PANEL + DETAIL PANEL
                        -->

                        <!-- ====================================================
                             [COIN TABLE PANEL] .list-panel
                             ==================================================== -->
                        <div class="list-panel">
                            <!--
                                 위치 : .content-layout > .list-panel > .stock-table-wrap
                                 역할 : API로 받은 코인 목록을 표 형태로 보여주는 영역
                                 연결 : coinList.js가 코인 목록을 채우는 영역입니다.

                                 내부 구조:
                                 coin table panel
                                 └─ table scroll area
                                    └─ coin table
                                       ├─ table header
                                       └─ rendered coin rows
                            -->

                            <!-- ====================================================
                                 [TABLE SCROLL AREA] .stock-table-wrap
                                 ==================================================== -->
                            <div class="stock-table-wrap">
                                <!--
                                     위치 : .list-panel > .stock-table-wrap
                                     역할 : 코인 표가 길어질 때 이 영역 안에서 세로 스크롤이 생기게 하는 감싸개
                                     연결 : 목록이 많아질 때 표를 담아두는 스크롤 기준 영역입니다.
                                -->

                                <!-- ====================================================
                                     [COIN TABLE] table.stock-table
                                     ==================================================== -->
                                <table class="stock-table">
                                    <!--
                                         위치 : .stock-table-wrap > table.stock-table
                                         역할 : 코인 이름, 현재가, 등락률, 거래대금, 고가, 저가를 표 형태로 정렬
                                         구성 : thead는 제목 줄, tbody는 데이터 행 영역입니다.
                                    -->
                                    <thead>
                                        <tr>
                                            <th class="th-rank">코인</th>
                                            <th class="th-price">현재가</th>
                                            <th class="th-change">등락률</th>
                                            <th class="th-quote">거래대금(USDT)</th>
                                            <th class="th-high">고가</th>
                                            <th class="th-low">저가</th>
                                        </tr>
                                    </thead>

                                    <!-- ====================================================
                                         [RENDERED COIN ROWS] tbody#stockTableBody
                                         ==================================================== -->
                                    <tbody id="stockTableBody">
                                        <!--
                                             위치 : table.stock-table > tbody#stockTableBody
                                             역할 : 실제 코인 데이터 행이 들어가는 자리
                                             연결 : 서버가 미리 그리지 않고 JavaScript가 실행 후 내용을 채웁니다.
                                        -->

                                    </tbody>
                                </table>
                            </div><!-- /.stock-table-wrap -->
                        </div><!-- /.list-panel -->

                        <!-- ====================================================
                             [DETAIL PANEL] .detail-panel #detailPanel
                             ==================================================== -->
                        <div class="detail-panel" id="detailPanel">
                            <!--
                                 위치 : .content-layout > .detail-panel#detailPanel
                                 역할 : 선택/hover된 코인의 로고, 가격, 미니 차트, 댓글을 보여주는 영역
                                 연결 : 코인을 선택하면 이 패널의 빈 상태와 상세 본문이 전환됩니다.

                                 내부 구조:
                                 detail panel
                                 ├─ empty state
                                 └─ detail body
                                    ├─ detail header
                                    ├─ detail chart
                                    └─ community comments
                            -->

                            <!-- ====================================================
                                 [EMPTY STATE] .detail-empty #detailEmpty
                                 ==================================================== -->
                            <div class="detail-empty" id="detailEmpty">
                                <!--
                                     위치 : .detail-panel > #detailEmpty
                                     역할 : 아직 코인을 선택하지 않았을 때 보여주는 안내 영역
                                     연결 : 선택 전 상태를 보여줍니다.
                                -->
                                <span>코인을 선택하세요</span>
                            </div>

                            <!-- ====================================================
                                 [DETAIL BODY] .detail-body #detailBody
                                 ==================================================== -->
                            <div class="detail-body" id="detailBody" style="display:none;">
                                <!--
                                     위치 : .detail-panel > #detailBody
                                     역할 : 코인을 선택한 뒤 실제 상세 정보를 보여주는 본문 영역
                                     연결 : 처음에는 숨겨져 있고, 코인 선택 후 표시됩니다.
                                -->

                                <!-- ====================================================
                                     [DETAIL HEADER] .detail-sticky-header
                                     ==================================================== -->
                                <div class="detail-sticky-header">
                                    <!--
                                         위치 : #detailBody > .detail-sticky-header
                                         역할 : 상세 패널 상단에서 코인 로고, 심볼, 가격, 등락률을 고정 헤더처럼 표시
                                         연결 : 코인 기본 정보가 들어가는 자리입니다.
                                    -->
                                    <div class="hc-main-id">
                                        <div class="hc-logo hc-logo-wrap" id="detailLogoWrap">
                                            <img id="detailLogoImg" src="" alt="" class="hc-logo-img">
                                        </div>
                                        <div class="hc-main-name-col">
                                            <span class="hc-main-ticker" id="detailName">-</span>
                                            <span class="hc-main-sub" id="detailSub">-</span>
                                        </div>
                                        <button class="ph-like-btn" id="detail-watchlist-btn" onclick="toggleWatchlist(currentDetailSymbol)" style="padding:4px 10px;font-size:12px;border-radius:8px;">
                                            <svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
                                            관심
                                        </button>
                                    </div>
                                    <div class="hc-main-right">
                                        <span class="hc-main-eval" id="detailPrice">-</span>
                                        <span class="hc-main-pnl" id="detailChange">-</span>
                                    </div>
                                </div>

                                <!-- ====================================================
                                     [DETAIL CHART] .detail-chart-section
                                     ==================================================== -->
                                <div class="detail-chart-section">
                                    <!--
                                         위치 : #detailBody > .detail-chart-section
                                         역할 : 선택한 코인의 미니 주봉 차트를 보여주는 영역
                                         연결 : 차트가 들어갈 영역을 제공합니다.
                                    -->
                                    <div class="detail-chart-label">주봉</div>
                                    <div class="detail-chart-area" id="detailChartArea"></div>
                                </div>

                                <!-- ====================================================
                                     [COMMUNITY COMMENTS] .detail-chat
                                     ==================================================== -->
                                <div class="card panel-chat" id="panel-chat">
                                    <div class="panel-title">실시간 댓글</div>
                                    <div class="chat-messages" id="chat-messages">
                                        <div class="chat-empty">
                                            <span class="chat-empty-icon">💬</span>
                                            <span>코인을 선택하면 댓글을 볼 수 있어요</span>
                                        </div>
                                    </div>
                                </div>

                            </div><!-- /#detailBody -->

                        </div><!-- /#detailPanel.detail-panel -->

                    </div><!-- /.content-layout -->
                </div><!-- /#tab-realtime.tab-content -->

                <!-- ====================================================
                     [HIDDEN TAB PLACEHOLDERS] .tab-content.hidden #tab-category/#tab-investor
                     ==================================================== -->
                <div class="tab-content hidden" id="tab-category">
                    <!--
                         위치 : .main-content > #tab-category.tab-content.hidden
                         역할 : 나중에 '지금 뜨는 카테고리' 탭 내용을 넣기 위한 자리
                         연결 : 현재는 숨겨진 예비 탭 영역입니다.
                    -->
                    <div class="empty-tab">지금 뜨는 카테고리</div>
                </div><!-- /#tab-category.tab-content -->

                <div class="tab-content hidden" id="tab-investor">
                    <!--
                         위치 : .main-content > #tab-investor.tab-content.hidden
                         역할 : 나중에 '국내 투자자 동향' 탭 내용을 넣기 위한 자리
                         연결 : 현재는 숨겨진 예비 탭 영역입니다.
                    -->
                    <div class="empty-tab">국내 투자자 동향</div>
                </div><!-- /#tab-investor.tab-content -->

            </div><!-- /.main-content -->

        </div><!-- /.page -->

        <%-- ====================================================
             [SIDEBAR INCLUDE] sidebar.jsp
             ==================================================== --%>
        <%@ include file="../common/sidebar.jsp" %>
        <%--
             위치 : .app-wrapper 안에서 .page 다음에 합쳐지는 공통 사이드바 영역
             역할 : sidebar.jsp의 패널 UI를 현재 화면에 포함합니다.
             연결 : 공통 사이드바 JSP 조각입니다.
        --%>

        <%-- ====================================================
             [SIDEBAR ICONS INCLUDE] sidebar-icons.jsp
             ==================================================== --%>
        <%@ include file="../common/sidebar-icons.jsp" %>
        <%--
             위치 : .app-wrapper 안에서 sidebar.jsp 다음에 합쳐지는 사이드바 아이콘 영역
             역할 : 접힘/펼침 상태나 빠른 이동에 쓰이는 공통 아이콘 UI를 포함합니다.
             연결 : 공통 사이드바 아이콘 JSP 조각입니다.
        --%>

    </div><!-- /.app-wrapper -->

    <!-- ====================================================
         [SCRIPT LOAD] script
         ==================================================== -->
    <!--
         위치 : body 맨 아래
         역할 : HTML 요소가 먼저 만들어진 뒤 JavaScript를 실행하도록 JS 파일을 마지막에 불러옵니다.

         script src="/js/common.js"   : 공통 nav/sidebar UI 동작을 불러옵니다.
         script src="/js/coinList.js" : 코인 리스트 API/WebSocket, 테이블 렌더링, 상세 패널 동작을 불러옵니다.

         실행 흐름:
           1. 서버가 JSP와 include 파일을 합쳐 HTML을 만듭니다.
           2. 브라우저가 common.css/coinList.css를 적용해 레이아웃을 잡습니다.
           3. common.js가 공통 UI를 준비합니다.
           4. coinList.js가 API/WebSocket 데이터를 받아 #stockTableBody와 #detailPanel을 채웁니다.
    -->
    <div class="cm-image-modal" id="cmImageModal" onclick="this.classList.remove('open')">
        <img id="cmImageModalImg" src="" alt="">
    </div>
    <script src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js"></script>
    <script src="/js/common.js"></script>
    <script src="/js/coinList.js"></script>
</body><!-- /body -->

</html>
