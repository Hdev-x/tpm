<!-- ============================================================
     JSP 파일 선언 (서버 사이드)
     - language="java"       : 이 JSP 파일의 스크립트 언어를 Java로 지정
     - contentType="text/html; charset=UTF-8" : 브라우저에게 UTF-8 HTML임을 알림
     - pageEncoding="UTF-8"  : 소스 파일 자체의 인코딩 (한글 깨짐 방지)
     ※ 이 파일은 현재 Java 로직 없이 순수 HTML 구조만 담당하고 있음
     ============================================================ -->
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">

<head>
    <meta charset="UTF-8">
    <title>TradeBot · 차트</title>

    <!-- ── 외부 라이브러리 로드 ──────────────────────────────────────
         LightweightCharts v5.2.0 (TradingView 오픈소스 차트 라이브러리)
         - 캔들스틱, 라인, 에리어 등 금융 차트를 그릴 수 있음
         - standalone : 번들러 없이 브라우저에서 바로 쓸 수 있는 단독 빌드
         - production : 코드가 압축(minify)된 배포용 버전
         unpkg.com : npm 패키지를 CDN으로 즉시 제공해주는 서비스
    -->
    <script src="https://unpkg.com/lightweight-charts@5.2.0/dist/lightweight-charts.standalone.production.js"></script>

    <!-- lwc-plugin-countdown-to-close v2.0.0
         - LightweightCharts 플러그인: 현재 봉의 남은 시간을 차트 위에 표시해줌
         - umd.cjs : UMD(Universal Module Definition) 형식으로 브라우저에서 바로 사용 가능
    -->
    <script
        src="https://unpkg.com/lwc-plugin-countdown-to-close@2.0.0/dist/lwc-plugin-countdown-to-close.umd.cjs"></script>

    <!-- 외부 CSS 파일 연결
         - /css/chart-toss.css → src/main/resources/static/css/chart-toss.css
         - Spring Boot는 static/ 하위 파일을 자동으로 정적 리소스로 서빙함
         - <link rel="stylesheet"> : CSS 파일을 스타일시트로 불러오는 표준 방법
    -->
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/chart-toss.css">
</head>

<body>

    <!-- ================================================================
         최상위 레이아웃 컨테이너
         .app-wrapper : 전체 앱을 감싸는 flex row 컨테이너
                        → [.page | .sidebar-panel | .sidebar-icons] 가 가로로 배치됨
         display:flex + flex-direction:row 구조:
           [ page(flex-grow:1) ] [ sidebar-panel(슬라이드) ] [ sidebar-icons(고정) ]
    ================================================================ -->
    <div class="app-wrapper">

        <!-- .page : 메인 콘텐츠 영역 (NAV + PRICE HEADER + MAIN LAYOUT)
             flex-direction:column 으로 세로로 쌓임 -->
        <div class="page">

            <%@ include file="../common/nav.jsp" %>
            <!-- ────────────────────────────────────────────────────────
                 PRICE HEADER (종목 정보 헤더)
                 - NAV 바로 아래, 종목명·현재가·24h 통계를 한눈에 보여주는 영역
                 - display:flex; align-items:center 로 가로 배치
                 - 구성: [ph-left | ph-right | ph-actions]
            ──────────────────────────────────────────────────────── -->
            <div class="price-header">

                <!-- ── ph-left: 종목명 + 현재가 (왼쪽) ───────────────────
                     세로로 두 줄:
                       1행: 종목명(Bitcoin) + 티커(BTCUSDT)
                       2행: 현재가 + 구분선 + 전일대비 변동액·변동률
                -->
                <div class="ph-left">

                    <!-- 1행: 종목명 + 티커 기호 -->
                    <div class="ph-name-row">
                        <span class="ph-name">Bitcoin</span>
                        <span class="ph-ticker">BTCUSDT</span>
                    </div>

                    <!-- 2행: 가격 정보 행
                         display:flex; align-items:center 로 모든 요소를 세로 중앙정렬
                         요소 순서:
                           [현재가] [구분선(1px)] [전일대비 라벨] [변동액] [변동률]
                    -->
                    <div class="ph-price-row">
                        <!-- 현재가: JS의 loadTicker()에서 id="ph-price" 를 찾아 실시간 업데이트 -->
                        <span class="ph-price" id="ph-price">-</span>

                        <!-- 세로 구분선: 1px 너비의 얇은 선으로 가격과 전일대비를 시각적으로 분리
                             - width:1px; height:16px : 세로선 크기
                             - background:var(--border2) : CSS 변수로 테마 색상 사용
                             - flex-shrink:0 : flex 컨테이너에서 이 요소가 줄어들지 않도록
                             - align-self:center : 세로 중앙 정렬 (flex 자식 개별 정렬)
                        -->
                        <span
                            style="width:1px;height:16px;background:var(--border2);margin:0 6px;flex-shrink:0;align-self:center;"></span>

                        <!-- "전일대비" 라벨: 고정 텍스트, JS로 변경 안 함 -->
                        <span style="font-size:13px;color:var(--text3);font-weight:500;line-height:1;">전일대비</span>

                        <!-- 전일 대비 변동액(절댓값): 예) +1,234.56 또는 -1,234.56
                             JS loadTicker()에서 prevClose 계산 후 업데이트
                             상승이면 CSS .up 클래스(빨강), 하락이면 .down 클래스(파랑) 추가
                        -->
                        <span class="ph-change" id="ph-change-abs">-</span>

                        <!-- 전일 대비 변동률: 예) (+2.34%) 또는 (-1.23%)
                             Bitget API의 change24h 필드로부터 계산
                        -->
                        <span class="ph-change" id="ph-change">-</span>
                    </div>
                </div>

                <!-- ── ph-right: 24h 통계 그룹들 (오른쪽) ──────────────────
                     display:flex; align-items:center; gap:16px
                     구성: [그룹1 | 수직선 | 그룹2 | 수직선 | 그룹3 | 수직선 | 그룹4]
                     각 .ph-group : 2개의 .ph-item 을 세로로 배치
                     각 .ph-item  : [라벨(회색)] [값(흰색)] 을 세로로 배치
                     각 .ph-vdivider : 그룹 사이 세로 구분선 (height:32px)
                -->
                <div class="ph-right">

                    <!-- 그룹 1: 24시간 고가·저가 -->
                    <div class="ph-group">
                        <div class="ph-item">
                            <span class="ph-label">24h 고가</span>
                            <!-- id="ph-high" : JS에서 loadTicker() 실행 시 값 주입 -->
                            <span class="ph-value" id="ph-high">-</span>
                        </div>
                        <div class="ph-item">
                            <span class="ph-label">24h 저가</span>
                            <span class="ph-value" id="ph-low">-</span>
                        </div>
                    </div>

                    <div class="ph-vdivider"></div>

                    <!-- 그룹 2: 24시간 거래량·거래대금 -->
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

                    <!-- 그룹 3: 펀딩비·미결제약정 (선물 전용 정보)
                         - 펀딩비(Funding Rate): 선물 포지션 보유자가 8시간마다 주고받는 비용
                         - 미결제약정(Open Interest): 현재 열려있는 선물 계약 수
                    -->
                    <div class="ph-group">
                        <div class="ph-item">
                            <span class="ph-label">펀딩비</span>
                            <span class="ph-value" id="ph-funding">-</span>
                        </div>
                        <div class="ph-item">
                            <span class="ph-label">미결제약정</span>
                            <span class="ph-value" id="ph-oi">-</span>
                        </div>
                    </div>

                    <div class="ph-vdivider"></div>

                    <!-- 그룹 4: 시가총액·도미넌스 -->
                    <div class="ph-group">
                        <div class="ph-item">
                            <span class="ph-label">시가총액</span>
                            <span class="ph-value" id="ph-mktcap">-</span>
                        </div>
                        <div class="ph-item">
                            <span class="ph-label">도미넌스</span>
                            <span class="ph-value" id="ph-dominance">-</span>
                        </div>
                    </div>
                </div>

                <!-- ── ph-actions: 우측 액션 버튼 ─────────────────────────
                     관심 버튼: SVG 하트 아이콘 + "관심" 텍스트
                     SVG path : 하트 모양의 베지어 곡선
                -->
                <div class="ph-actions">
                    <button class="ph-like-btn">
                        <svg viewBox="0 0 24 24">
                            <path
                                d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                        </svg>
                        관심
                    </button>
                </div>
            </div><!-- /.price-header -->

            <!-- ================================================================
                 MAIN LAYOUT (메인 콘텐츠 영역)
                 display:flex; flex-direction:row 로 가로 배치:
                   [① 차트 카드] [resize핸들] [② 주문/호가 카드] [resize핸들] [③ 댓글 카드]
                 각 카드 사이에 .resize-h (수평 리사이즈 핸들) 가 있어
                 드래그로 패널 너비를 조절할 수 있음 (JS의 makeHResizer() 참고)
            ================================================================ -->
            <div class="main-layout">

                <!-- ────────────────────────────────────────────────────────
                     ① 차트 패널 (.panel-chart)
                     - flex:1 1 0 → 남는 공간을 모두 차지하는 메인 패널
                     - 내부 구조:
                         [.chart-toolbar] ← 타임프레임 버튼 + 보조지표 버튼 + 설정
                         [#chart-wrapper] ← 실제 차트 렌더링 영역
                ──────────────────────────────────────────────────────── -->
                <div class="card panel-chart" id="panel-chart">

                    <!-- ── 차트 툴바 ──────────────────────────────────────
                         display:flex; align-items:center; flex-wrap:wrap
                         두 그룹으로 구성:
                           [타임프레임 버튼들] [tb-divider] [보조지표 버튼들] [tb-divider] [설정]
                    -->
                    <div class="chart-toolbar">

                        <!-- 타임프레임(TF) 버튼들
                             - data-tf 속성: JS에서 querySelectorAll('[data-tf]') 로 모두 선택하기 위한 마커
                             - onclick="changeTimeframe('1min')" : JS 함수 호출, 캔들 타임프레임 변경
                             - .active 클래스: 현재 선택된 TF 버튼을 강조 (JS에서 클래스 교체)
                             - 기본 선택: 1분봉 (.active 가 기본으로 붙어있음)
                        -->
                        <button class="tf-btn active" data-tf onclick="changeTimeframe('1min')">1분</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('3min')">3분</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('5min')">5분</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('15min')">15분</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('30min')">30분</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('1h')">1H</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('4h')">4H</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('6h')">6H</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('12h')">12H</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('1day')">1D</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('3day')">3D</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('1week')">1W</button>
                        <button class="tf-btn" data-tf onclick="changeTimeframe('1month')">1M</button>

                        <!-- 구분선: 타임프레임 ↔ 보조지표 그룹 분리 -->
                        <div class="tb-divider"></div>

                        <!-- 보조지표(Indicator) 버튼들
                             - id="ind-ma5" : JS의 toggleInd()에서 id로 요소를 찾아 .active 토글
                             - onclick="toggleInd('ma5')" : 해당 지표 ON/OFF
                             - MA5  : 5봉 단순이동평균선 (단기 추세)
                             - MA20 : 20봉 이동평균선 (중기 추세)
                             - MA60 : 60봉 이동평균선 (장기 추세)
                             - BB   : 볼린저 밴드 (MA20 ± 2σ, 변동성 범위 표시)
                             - 일목  : 일목균형표 (기준선/전환선/구름대)
                             - RSI  : 상대강도지수 (0~100, 70이상=과매수 30이하=과매도)
                        -->
                        <button class="ind-btn" id="ind-ma5" onclick="toggleInd('ma5')">MA5</button>
                        <button class="ind-btn" id="ind-ma20" onclick="toggleInd('ma20')">MA20</button>
                        <button class="ind-btn" id="ind-ma60" onclick="toggleInd('ma60')">MA60</button>
                        <button class="ind-btn" id="ind-bb" onclick="toggleInd('bb')">BB</button>
                        <button class="ind-btn" id="ind-ichimoku" onclick="toggleInd('ichimoku')">일목</button>
                        <button class="ind-btn" id="ind-rsi" onclick="toggleInd('rsi')">RSI</button>

                        <div class="tb-divider"></div>

                        <!-- 설정 버튼 + 드롭다운 메뉴
                             .settings-wrap : position:relative → 드롭다운 메뉴의 기준점
                             ⚙ 아이콘 : 유니코드 톱니바퀴 기호 (font-size:24px으로 크기 지정)
                             toggleSettingsMenu() : 클릭 시 #settings-menu 의 display 토글
                        -->
                        <div class="settings-wrap">
                            <button class="ind-btn" onclick="toggleSettingsMenu()">
                                <span style="font-size:24px;">⚙</span>
                            </button>

                            <!-- 설정 드롭다운 메뉴
                                 - position:absolute → .settings-wrap 기준으로 아래에 띄움
                                 - 기본 display:none → toggleSettingsMenu()로 보이게 함
                                 - 각 설정 항목: <label> 로 감싸 체크박스 클릭 영역을 넓힘
                            -->
                            <div class="settings-menu" id="settings-menu">
                                <div class="settings-title">차트 설정</div>

                                <!-- 설정 항목 1: 최고·최저 가격 마커 표시 여부
                                     - type="checkbox" checked : 기본값 ON
                                     - onchange="toggleHighLow(this.checked)" : 체크 상태를 JS로 전달
                                     - JS에서 showHighLow 전역변수와 updateHighLow()로 처리
                                -->
                                <label class="settings-item">
                                    <span class="settings-label"><span>최고 최저 가격</span></span>
                                    <input type="checkbox" id="set-highlow" onchange="toggleHighLow(this.checked)"
                                        checked>
                                </label>

                                <!-- 설정 항목 2: 로그 스케일
                                     - 로그 스케일: 가격 축을 로그(log) 단위로 변환
                                     - 절대 가격 변화보다 변화율(%) 기준으로 차트를 볼 수 있음
                                     - 예: 100→200(+100%)과 10000→20000(+100%)이 같은 높이로 표시됨
                                -->
                                <label class="settings-item">
                                    <span class="settings-label">
                                        <span>로그 스케일</span>
                                        <small>변화율 기준으로 차트 보기</small>
                                    </span>
                                    <input type="checkbox" id="set-log" onchange="toggleLog()">
                                </label>

                                <!-- 설정 항목 3: 봉 카운트다운
                                     - 현재 진행 중인 봉이 닫히기까지 남은 시간을 차트에 표시
                                     - lwc-plugin-countdown-to-close 라이브러리가 처리
                                -->
                                <label class="settings-item">
                                    <span class="settings-label">
                                        <span>봉 카운트다운</span>
                                        <small>다음 봉까지 남은 시간 표시</small>
                                    </span>
                                    <input type="checkbox" id="set-countdown" onchange="toggleCountdown(this.checked)"
                                        checked>
                                </label>
                            </div>
                        </div>
                    </div><!-- /.chart-toolbar -->

                    <!-- ── 차트 렌더링 영역 ────────────────────────────────
                         #chart-wrapper : position:relative → 내부 절대위치 요소들의 기준점
                         내부 구성:
                           [#hl-high]         ← 고가 마커 (절대위치, JS로 좌표 계산)
                           [#hl-low]          ← 저가 마커 (절대위치, JS로 좌표 계산)
                           [#chart-container] ← LightweightCharts 메인 차트
                             └ [#ohlc-bar]    ← 마우스 오버시 OHLC 값 표시
                           [#pane-divider]    ← RSI 창 구분선
                           [#rsi-container]   ← RSI 보조 차트 패널
                    -->
                    <div id="chart-wrapper">

                        <!-- 고가 마커 (#hl-high)
                             - position:absolute : chart-wrapper 기준으로 정확한 좌표에 배치
                             - display:none : 기본 숨김 → JS updateHighLow()에서 "flex"로 변경
                             - flex-direction:column : 텍스트와 화살표를 세로로 쌓음
                             - align-items:center : 가로 중앙 정렬
                             - transform:translateX(-50%) : left 좌표를 기준으로 정중앙 정렬
                             - pointer-events:none : 마우스 이벤트 무시 (차트 인터랙션 방해 안 함)
                             - z-index:10 : 차트 캔버스 위에 표시

                             구조: [텍스트 라벨(위)] [⇒ 화살표(아래, 90도 회전=↓)]
                             텍스트 예시: "104,200 (+1.23%)\n전일마감기준"
                        -->
                        <div id="hl-high"
                            style="position:absolute;display:none;flex-direction:column;align-items:center;pointer-events:none;z-index:10;transform:translateX(-50%);">
                            <!-- 고가 텍스트: JS에서 textContent로 가격 + 전일대비% 주입
                                 color:var(--up) = 빨간색 (상승 색상) -->
                            <span id="hl-high-val" style="font-size:12px;color:var(--up);white-space:nowrap;"></span>
                            <!-- ⇒ 화살표: rotate(90deg)로 아래를 가리키는 ↓ 방향으로 변환 -->
                            <span
                                style="color:var(--up);font-size:12px;display:block;transform:rotate(90deg);line-height:1;">⇒</span>
                        </div>

                        <!-- 저가 마커 (#hl-low)
                             고가 마커와 반대: 화살표가 위(↑)를 가리키고 텍스트가 아래
                             구조: [⇒ 화살표(-90도 회전=↑)] [텍스트 라벨(아래)]
                        -->
                        <div id="hl-low"
                            style="position:absolute;display:none;flex-direction:column;align-items:center;pointer-events:none;z-index:10;transform:translateX(-50%);">
                            <!-- ⇒ 화살표: rotate(-90deg)로 위를 가리키는 ↑ 방향으로 변환 -->
                            <span
                                style="color:var(--down);font-size:12px;display:block;transform:rotate(-90deg);line-height:1;">⇒</span>
                            <!-- 저가 텍스트: color:var(--down) = 파란색 (하락 색상) -->
                            <span id="hl-low-val" style="font-size:12px;color:var(--down);white-space:nowrap;"></span>
                        </div>

                        <!-- 메인 차트 컨테이너
                             - JS의 LightweightCharts.createChart(document.getElementById('chart-container'), ...)
                               로 이 div 안에 <canvas>를 생성·삽입함
                        -->
                        <div id="chart-container">
                            <!-- OHLC 바 (시고저종 정보 표시줄)
                                 - 차트 좌상단에 고정된 텍스트 바
                                 - 마우스를 캔들 위에 올리면 JS의 crosshairMoved 이벤트로 값 업데이트
                                 - O=시가(Open), H=고가(High), L=저가(Low), C=종가(Close)
                                 - id="val-o/h/l/c" : JS에서 innerHTML로 값 주입
                                 - &nbsp; : HTML 엔티티, 요소 사이 공백 (일반 스페이스는 HTML에서 무시됨)
                            -->
                            <div id="ohlc-bar">
                                <span>O: <b id="val-o">-</b></span>&nbsp;
                                <span>H: <b id="val-h">-</b></span>&nbsp;
                                <span>L: <b id="val-l">-</b></span>&nbsp;
                                <span>C: <b id="val-c">-</b></span>
                            </div>
                        </div>

                        <!-- RSI 패널 구분선
                             - RSI가 활성화되면 JS에서 display:'block'으로 표시
                             - 드래그로 메인 차트와 RSI 패널 비율 조절 (JS의 makeVResizer() 로직과 유사)
                        -->
                        <div id="pane-divider"></div>

                        <!-- RSI 보조 차트 컨테이너
                             - RSI 지표 ON 시 JS가 이 div 안에 별도 LightweightCharts 인스턴스 생성
                             - 기본: height 0, display none → RSI 활성화시 높이 부여
                        -->
                        <div id="rsi-container"></div>
                    </div><!-- /#chart-wrapper -->

                </div><!-- /.panel-chart -->

                <!-- ── 수평 리사이즈 핸들 (차트 ↔ 주문창) ─────────────────
                     - .resize-h : cursor:col-resize (좌우 화살표 커서)
                     - JS의 makeHResizer(el, leftPanel, rightPanel) 로 드래그 기능 연결
                     - id="rh-1" : 첫 번째 핸들 (차트 | 주문창 사이)
                -->
                <div class="resize-h" id="rh-1"></div>

                <!-- ────────────────────────────────────────────────────────
                     ② 주문/호가 패널 (.panel-middle)
                     - display:flex; flex-direction:column 로 세로 배치
                     - 내부 구조:
                         [주문창 (.panel-order-wrap)]  ← 위
                         [수직 resize 핸들 (.resize-v)] ← 중간
                         [호가 (.panel-hoga)]           ← 아래
                ──────────────────────────────────────────────────────── -->
                <div class="panel-middle" id="panel-middle">

                    <!-- 주문창 카드
                         - .card : 공통 카드 스타일 (배경색, 테두리, padding)
                         - flex:0 0 auto 또는 특정 height로 고정 크기 유지
                    -->
                    <div class="card panel-order-wrap" id="panel-order-wrap">

                        <!-- 매수/매도 탭
                             - .active 클래스가 선택된 탭을 강조
                             - switchOrderTab('buy'/'sell') : 탭 전환 + 버튼 색상 변경
                        -->
                        <div class="order-tabs">
                            <div class="order-tab buy active" id="tab-buy" onclick="switchOrderTab('buy')">매수</div>
                            <div class="order-tab sell" id="tab-sell" onclick="switchOrderTab('sell')">매도</div>
                        </div>

                        <!-- 주문 패널 본문 -->
                        <div class="order-panel" id="panel-order">

                            <!-- 주문 유형 선택: 지정가 / 시장가
                                 - .sel 클래스: 선택된 버튼 강조
                                 - selectOrderType(this) : 클릭한 버튼에 .sel, 나머지는 제거
                            -->
                            <div class="order-type-row">
                                <button class="order-type-btn sel" onclick="selectOrderType(this)">지정가</button>
                                <button class="order-type-btn" onclick="selectOrderType(this)">시장가</button>
                            </div>

                            <!-- 가격 입력 필드
                                 - type="number" : 숫자만 입력 가능
                                 - placeholder : 입력 전 표시되는 안내 텍스트
                                 - JS의 WebSocket 연결 후 현재가로 자동 채워짐
                            -->
                            <div class="order-section-label">가격 (USDT)</div>
                            <div class="order-input-row">
                                <input class="order-input" id="trade-price-input" type="number" placeholder="0.00">
                                <span class="order-input-unit">USDT</span>
                            </div>

                            <!-- 수량 입력 필드
                                 - oninput="calcAmount()" : 수량 입력시 주문금액 자동 계산
                                 - step="0.001" : 0.001 단위로 증감 (스핀 버튼 step)
                            -->
                            <div class="order-section-label">수량 (BTC)</div>
                            <div class="order-input-row">
                                <input class="order-input" id="trade-qty" type="number" placeholder="0.000" step="0.001"
                                    oninput="calcAmount()">
                                <span class="order-input-unit">BTC</span>
                            </div>

                            <!-- 비율 버튼: 가용잔고의 몇 %로 주문할지 선택
                                 - setPercent(25) : walletBalance * 0.25 / 현재가 = 수량 계산
                            -->
                            <div class="pct-row">
                                <button class="pct-btn" onclick="setPercent(25)">25%</button>
                                <button class="pct-btn" onclick="setPercent(50)">50%</button>
                                <button class="pct-btn" onclick="setPercent(75)">75%</button>
                                <button class="pct-btn" onclick="setPercent(100)">최대</button>
                            </div>

                            <!-- 주문금액 (읽기 전용, 자동 계산)
                                 - readonly : 직접 입력 불가, calcAmount()로만 값 변경
                                 - background:var(--bg) : 읽기전용임을 시각적으로 구분
                            -->
                            <div class="order-section-label">주문금액 (USDT)</div>
                            <div class="order-input-row" style="margin-bottom:14px">
                                <input class="order-input" id="trade-amount" type="number" readonly
                                    style="background:var(--bg)">
                                <span class="order-input-unit">USDT</span>
                            </div>

                            <!-- 가용 잔고 표시 -->
                            <div class="order-avail">가용 잔고 <span>- USDT</span></div>

                            <!-- 주문 제출 버튼
                                 - id="order-submit-btn" : JS에서 매수/매도에 따라 클래스 교체
                                 - .btn-buy : 빨간색 배경 (매수 상태)
                                 - submitOrder(orderSide) : orderSide 전역변수('buy'/'sell')로 처리
                            -->
                            <button id="order-submit-btn" class="btn-buy" onclick="submitOrder(orderSide)">매수
                                주문</button>
                        </div>
                    </div><!-- /.panel-order-wrap -->

                    <!-- 수직 리사이즈 핸들 (주문창 ↔ 호가)
                         - .resize-v : cursor:row-resize (상하 화살표 커서)
                         - JS의 makeVResizer() 로 드래그 기능 연결
                    -->
                    <div class="resize-v" id="rh-v"></div>

                    <!-- 호가 패널 (Order Book)
                         - 매도호가(asks) : 빨간색, 위에 표시 (가격 내림차순, 낮은 가격이 맨 아래)
                         - 매수호가(bids) : 파란색, 아래에 표시 (가격 내림차순, 높은 가격이 맨 위)
                         - 중간(hoga-mid) : 현재 체결가 + 전일대비 변동률
                    -->
                    <div class="card panel-hoga" id="panel-hoga">
                        <div class="hoga-header-row">
                            <span>호가</span>
                            <span>수량(BTC)</span>
                            <span>총량</span>
                        </div>
                        <div class="hoga-body">

                            <!-- 매도 호가 영역 (위 절반) - flex:1로 항상 50% 차지, 테이블이 아래 붙음 -->
                            <div class="hoga-top">
                                <table class="hoga-table">
                                    <tbody id="hoga-asks">
                                        <tr class="hoga-skel"><td class="hoga-ask">--,---.--</td><td>-.------</td><td>-.------</td></tr>
                                        <tr class="hoga-skel"><td class="hoga-ask">--,---.--</td><td>-.------</td><td>-.------</td></tr>
                                        <tr class="hoga-skel"><td class="hoga-ask">--,---.--</td><td>-.------</td><td>-.------</td></tr>
                                        <tr class="hoga-skel"><td class="hoga-ask">--,---.--</td><td>-.------</td><td>-.------</td></tr>
                                        <tr class="hoga-skel"><td class="hoga-ask">--,---.--</td><td>-.------</td><td>-.------</td></tr>
                                    </tbody>
                                </table>
                            </div>

                            <!-- 현재가 중간 표시줄 (항상 패널 중앙 고정) -->
                            <div class="hoga-mid" id="hoga-mid">
                                <span id="hoga-cur-price">-</span>
                                <span class="hoga-mid-change" id="hoga-cur-change"></span>
                            </div>

                            <!-- 매수 호가 영역 (아래 절반) - flex:1로 항상 50% 차지 -->
                            <div class="hoga-bot">
                                <table class="hoga-table">
                                    <tbody id="hoga-bids">
                                        <tr class="hoga-skel"><td class="hoga-bid">--,---.--</td><td>-.------</td><td>-.------</td></tr>
                                        <tr class="hoga-skel"><td class="hoga-bid">--,---.--</td><td>-.------</td><td>-.------</td></tr>
                                        <tr class="hoga-skel"><td class="hoga-bid">--,---.--</td><td>-.------</td><td>-.------</td></tr>
                                        <tr class="hoga-skel"><td class="hoga-bid">--,---.--</td><td>-.------</td><td>-.------</td></tr>
                                        <tr class="hoga-skel"><td class="hoga-bid">--,---.--</td><td>-.------</td><td>-.------</td></tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div><!-- /.panel-hoga -->

                </div><!-- /.panel-middle -->

                <!-- ── 수평 리사이즈 핸들 (주문/호가 ↔ 댓글) -->
                <div class="resize-h" id="rh-2"></div>

                <!-- ────────────────────────────────────────────────────────
                     ③ 실시간 댓글 패널 (.panel-chat)
                     - 다른 사용자들의 실시간 댓글을 표시하는 채팅 인터페이스
                     - 구성: [제목] [메시지 목록] [입력창]
                ──────────────────────────────────────────────────────── -->
                <div class="card panel-chat" id="panel-chat">
                    <div class="panel-title">실시간 댓글</div>

                    <!-- 댓글 목록 영역
                         - overflow-y:auto : 메시지가 많으면 스크롤
                         - 초기: 빈 상태 안내 UI (.chat-empty) 표시
                         - JS의 sendChat() 실행 시 댓글이 추가되면 .chat-empty는 숨겨짐
                    -->
                    <div class="chat-messages" id="chat-messages">
                        <!-- 빈 상태 UI: 댓글이 없을 때 표시
                             - chat-empty-icon: 아이콘 이모지 (큰 크기)
                             - 댓글이 추가되면 JS에서 이 요소를 제거
                        -->
                        <div class="chat-empty">
                            <span class="chat-empty-icon">💬</span>
                            <span>첫 댓글을 남겨보세요</span>
                        </div>
                    </div>

                    <!-- 댓글 입력 영역
                         - display:flex 로 [입력창]과 [전송 버튼]을 가로로 배치
                         - sendChat() : 입력값 읽어서 XSS 방지 후 댓글 목록에 추가
                         - XSS 방지: text.replace(/</g, '&lt;') 로 HTML 태그 삽입 차단
                    -->
                    <div class="chat-input-wrap">
                        <input type="text" class="chat-input" id="chat-input" placeholder="댓글 입력...">
                        <button class="chat-send-btn" onclick="sendChat()">전송</button>
                    </div>
                </div><!-- /.panel-chat -->

            </div><!-- /.main-layout -->

            <div class="ticker-bar">
                <div class="ticker-track" id="ticker-track"></div>
            </div>

        </div><!-- /.page -->

        <%@ include file="../common/sidebar.jsp" %>

        <!-- ================================================================
             아이콘 스트립 (.sidebar-icons)
             - 항상 화면 오른쪽 끝에 표시되는 세로 아이콘 탭 바
             - 각 아이콘 클릭 시 해당 사이드바 콘텐츠로 슬라이드 인
             - toggleSidebar('invest'/'interest'/'recent'/'live') 로 제어
             - display:flex; flex-direction:column; align-items:center
        ================================================================ -->
        <div class="sidebar-icons">

            <!-- 내 투자 버튼: 파형 아이콘 (polyline = 꺾인 선)
                 - SVG viewBox="0 0 24 24" : 24x24 좌표계 기준
                 - polyline points : 점들을 직선으로 연결 (차트 파형 모양)
                 - id="si-invest" : 활성화 시 JS에서 .active 클래스 추가
            -->
            <button class="si-btn" id="si-invest" onclick="toggleSidebar('invest')">
                <svg viewBox="0 0 24 24">
                    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
                </svg>
                <span>내 투자</span>
            </button>

            <!-- 구분선: 아이콘 그룹 시각적 분리 -->
            <div class="si-divider"></div>

            <!-- 관심 버튼: 하트 아이콘 -->
            <button class="si-btn" id="si-interest" onclick="toggleSidebar('interest')">
                <svg viewBox="0 0 24 24">
                    <path
                        d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                </svg>
                <span>관심</span>
            </button>

            <!-- 최근 본 버튼: 시계 아이콘 (circle=시계 테두리, polyline=시침/분침) -->
            <button class="si-btn" id="si-recent" onclick="toggleSidebar('recent')">
                <svg viewBox="0 0 24 24">
                    <circle cx="12" cy="12" r="10" />
                    <polyline points="12 6 12 12 16 14" />
                </svg>
                <span>최근 본</span>
            </button>

            <!-- 실시간 버튼: 와이파이/라디오 방사 아이콘
                 - circle : 중앙 점
                 - path : 안쪽 → 바깥쪽으로 퍼지는 호(arc) 3겹
            -->
            <button class="si-btn" id="si-live" onclick="toggleSidebar('live')">
                <svg viewBox="0 0 24 24">
                    <circle cx="12" cy="12" r="2" />
                    <path
                        d="M16.24 7.76a6 6 0 0 1 0 8.49M7.76 16.24a6 6 0 0 1 0-8.49M20.49 3.51a12 12 0 0 1 0 16.97M3.51 20.49a12 12 0 0 1 0-16.97" />
                </svg>
                <span>실시간</span>
            </button>
        </div><!-- /.sidebar-icons -->

    </div><!-- /.app-wrapper -->

    <!-- 외부 JS 파일 로드
         - <body> 최하단에 위치: DOM이 모두 파싱된 후 스크립트 실행
           → document.getElementById() 등이 null 반환하는 문제 방지
         - /js/chart-toss.js → src/main/resources/static/js/chart-toss.js
         - 이 파일이 로드되면 즉시 init() 함수가 실행되어 차트·WebSocket 초기화
    -->
    <script src="/js/common.js"></script>
    <script src="/js/chart-toss.js"></script>
</body>

</html>