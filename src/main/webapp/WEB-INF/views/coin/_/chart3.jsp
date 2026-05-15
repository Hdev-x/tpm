<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">

<head>
    <meta charset="UTF-8">
    <title>TradeBot · 차트</title>
    <script src="https://unpkg.com/lightweight-charts@5.2.0/dist/lightweight-charts.standalone.production.js"></script>
    <script
        src="https://unpkg.com/lwc-plugin-countdown-to-close@2.0.0/dist/lwc-plugin-countdown-to-close.umd.cjs"></script>
    <style>
* {
	margin: 0;
	padding: 0;
	box-sizing: border-box;
}

body {
	font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica,
		Arial, sans-serif;
	background: #0d1117;
	color: #e6edf3;
	font-size: 14px;
	height: 100vh;
	overflow: hidden;
	font-variant-numeric: tabular-nums;
}

.up {
	color: #ff3b30;
}

.down {
	color: #007aff;
}

nav {
	height: 48px;
	background: #0f1318;
	border-bottom: 1px solid #1c2128;
	display: flex;
	align-items: center;
	padding: 0 16px;
	flex-shrink: 0;
}

.logo {
	color: #e6edf3;
	font-weight: 700;
	font-size: 15px;
	margin-right: 24px;
}

.logo span {
	color: #58a6ff;
}

.nav-item {
	color: #8b949e;
	font-size: 13px;
	cursor: pointer;
	padding: 0 12px;
	height: 48px;
	display: flex;
	align-items: center;
	border-bottom: 2px solid transparent;
	text-decoration: none;
}

.nav-item:hover {
	color: #e6edf3;
}

.nav-item.active {
	color: #e6edf3;
	border-bottom-color: #58a6ff;
}

.price-header {
	height: 52px;
	background: #0f1318;
	border-bottom: 1px solid #1c2128;
	display: flex;
	align-items: center;
	padding: 0 16px;
	gap: 24px;
	flex-shrink: 0;
}

.ph-symbol {
	font-size: 15px;
	font-weight: 700;
}

.ph-price {
	font-size: 22px;
	font-weight: 700;
}

.ph-divider {
	width: 1px;
	height: 24px;
	background: #1c2128;
}

.ph-item {
	display: flex;
	flex-direction: column;
	gap: 2px;
}

.ph-label {
	font-size: 10px;
	color: #484f58;
	text-transform: uppercase;
	letter-spacing: 0.4px;
}

.ph-value {
	font-size: 12px;
	color: #8b949e;
}

.toolbar {
	height: 38px;
	background: #0f1318;
	border-bottom: 1px solid #1c2128;
	display: flex;
	align-items: center;
	padding: 0 12px;
	gap: 2px;
	flex-shrink: 0;
}

.tf-btn {
	padding: 4px 9px;
	border-radius: 4px;
	font-size: 12px;
	color: #8b949e;
	cursor: pointer;
	border: none;
	background: none;
}

.tf-btn:hover {
	background: #1c2128;
	color: #e6edf3;
}

.tf-btn.active {
	background: #1f6feb;
	color: #fff;
}

.tb-divider {
	width: 1px;
	height: 18px;
	background: #1c2128;
	margin: 0 6px;
}

.ind-btn {
	padding: 4px 9px;
	border-radius: 4px;
	font-size: 12px;
	color: #8b949e;
	cursor: pointer;
	border: 1px solid transparent;
	background: none;
}

.ind-btn:hover {
	background: #1c2128;
	color: #e6edf3;
}

.tb-right {
	margin-left: auto;
	display: flex;
	align-items: center;
	gap: 6px;
}

.page {
	display: flex;
	flex-direction: column;
	height: 100vh;
}

.body {
	display: flex;
	flex: 1;
	overflow: hidden;
	min-height: 0;
}

.chart-area {
	flex: 1;
	background: #0d1117;
	display: flex;
	flex-direction: column;
	position: relative;
	overflow: hidden;
	min-width: 0;
}

.right-panel {
	width: 260px;
	background: #0f1318;
	border-left: 1px solid #1c2128;
	display: flex;
	flex-direction: column;
	flex-shrink: 0;
	overflow-y: auto;
}

.rp-tabs {
	display: flex;
	border-bottom: 1px solid #1c2128;
	flex-shrink: 0;
}

.rp-tab {
	flex: 1;
	padding: 10px 0;
	text-align: center;
	font-size: 12px;
	color: #8b949e;
	cursor: pointer;
	border-bottom: 2px solid transparent;
}

.rp-tab.active {
	color: #e6edf3;
	border-bottom-color: #58a6ff;
}

.rp-tab:hover {
	color: #e6edf3;
}

.order-panel {
	padding: 14px;
}

.order-type-row {
	display: flex;
	gap: 6px;
	margin-bottom: 14px;
}

.order-type-btn {
	flex: 1;
	padding: 6px 0;
	text-align: center;
	font-size: 12px;
	font-weight: 500;
	border-radius: 4px;
	cursor: pointer;
	border: 1px solid #1e242c;
	background: #111519;
	color: #8b949e;
}

.order-type-btn.sel {
	background: rgba(88, 166, 255, 0.1);
	color: #58a6ff;
	border-color: rgba(88, 166, 255, 0.3);
}

.order-section-label {
	font-size: 11px;
	color: #484f58;
	text-transform: uppercase;
	letter-spacing: 0.4px;
	margin-bottom: 6px;
	margin-top: 12px;
}

.order-input-row {
	display: flex;
	gap: 6px;
	margin-bottom: 8px;
}

.order-input {
	flex: 1;
	background: #111519;
	border: 1px solid #1e242c;
	color: #e6edf3;
	font-size: 12px;
	padding: 7px 10px;
	border-radius: 4px;
	outline: none;
}

.order-input:focus {
	border-color: #58a6ff;
}

.order-input-unit {
	background: #111519;
	border: 1px solid #1e242c;
	color: #8b949e;
	font-size: 12px;
	padding: 7px 8px;
	border-radius: 4px;
}

.pct-row {
	display: flex;
	gap: 4px;
	margin-bottom: 14px;
}

.pct-btn {
	flex: 1;
	padding: 4px 0;
	text-align: center;
	font-size: 11px;
	border-radius: 3px;
	cursor: pointer;
	border: 1px solid #1e242c;
	background: #111519;
	color: #8b949e;
}

.pct-btn:hover {
	border-color: #58a6ff;
	color: #58a6ff;
}

.order-avail {
	font-size: 11px;
	color: #8b949e;
	margin-bottom: 14px;
}

.order-avail span {
	color: #e6edf3;
}

.btn-long {
	width: 100%;
	padding: 10px;
	border-radius: 4px;
	cursor: pointer;
	font-size: 13px;
	font-weight: 600;
	margin-bottom: 6px;
	border: none;
	background: linear-gradient(135deg, #ff3b30, #ff6b63);
	color: #fff;
}

.btn-long:hover {
	background: linear-gradient(135deg, #ff4f45, #ff7a72);
}

.btn-short {
	width: 100%;
	padding: 10px;
	border-radius: 4px;
	cursor: pointer;
	font-size: 13px;
	font-weight: 600;
	border: none;
	background: linear-gradient(135deg, #0a7ff5, #2b9dff);
	color: #fff;
}

.btn-short:hover {
	background: linear-gradient(135deg, #1a8df8, #3baeff);
}

.bot-panel {
	padding: 14px;
	display: none;
}

.bot-card {
	background: #111519;
	border: 1px solid #1e242c;
	border-radius: 6px;
	padding: 12px;
	margin-bottom: 8px;
}

.bc-header {
	display: flex;
	align-items: center;
	justify-content: space-between;
	margin-bottom: 8px;
}

.bc-name {
	font-size: 13px;
	font-weight: 500;
}

.bc-dot {
	width: 7px;
	height: 7px;
	border-radius: 50%;
}

.bc-dot.on {
	background: #58a6ff;
	box-shadow: 0 0 5px rgba(88, 166, 255, 0.5);
}

.bc-dot.off {
	background: #484f58;
}

.bc-row {
	display: flex;
	justify-content: space-between;
	font-size: 11px;
	margin-top: 4px;
}

.bc-row span:first-child {
	color: #484f58;
}

.bc-actions {
	display: flex;
	gap: 6px;
	margin-top: 10px;
}

.bc-btn {
	flex: 1;
	padding: 5px 0;
	text-align: center;
	font-size: 11px;
	font-weight: 500;
	border-radius: 4px;
	cursor: pointer;
	border: 1px solid #1e242c;
	background: #111519;
	color: #8b949e;
}

.bc-btn:hover {
	border-color: #58a6ff;
	color: #58a6ff;
}

.bc-btn.danger:hover {
	border-color: #ff3b30;
	color: #ff3b30;
}

.bot-add-btn {
	width: 100%;
	padding: 8px;
	border-radius: 4px;
	cursor: pointer;
	font-size: 12px;
	color: #58a6ff;
	border: 1px dashed rgba(88, 166, 255, 0.3);
	background: rgba(88, 166, 255, 0.05);
	margin-top: 4px;
}

.bot-add-btn:hover {
	background: rgba(88, 166, 255, 0.1);
}

.bottom-panel {
	height: 220px;
	background: #0f1318;
	border-top: 1px solid #1c2128;
	display: flex;
	flex-direction: column;
	flex-shrink: 0;
}

.bp-tabs {
	display: flex;
	border-bottom: 1px solid #1c2128;
}

.bp-tab {
	padding: 8px 16px;
	font-size: 12px;
	color: #8b949e;
	cursor: pointer;
	border-bottom: 2px solid transparent;
	white-space: nowrap;
}

.bp-tab.active {
	color: #e6edf3;
	border-bottom-color: #58a6ff;
}

.bp-tab:hover {
	color: #e6edf3;
}

.bp-content {
	flex: 1;
	overflow-y: auto;
}

.bp-table {
	width: 100%;
	border-collapse: collapse;
}

.bp-table th {
	padding: 6px 14px;
	font-size: 11px;
	font-weight: 600;
	color: #484f58;
	text-align: left;
	text-transform: uppercase;
	letter-spacing: 0.4px;
	position: sticky;
	top: 0;
	background: #0f1318;
	border-bottom: 1px solid #1c2128;
	white-space: nowrap;
}

.bp-table td {
	padding: 8px 14px;
	font-size: 12px;
	border-bottom: 1px solid #1a1f26;
	white-space: nowrap;
	color: #e6edf3;
}

.bp-table tr:hover td {
	background: #1c2128;
}

.bp-empty {
	padding: 24px;
	text-align: center;
	color: #484f58;
	font-size: 12px;
}

#chart-wrapper {
	flex: 1;
	display: flex;
	flex-direction: column;
	min-height: 0;
}

#chart-container {
	flex: 1;
	position: relative;
	min-height: 0;
}

#ohlc-bar {
	position: absolute;
	top: 8px;
	left: 10px;
	z-index: 10;
	font-size: 12px;
	background: rgba(15, 19, 24, 0.85);
	padding: 4px 10px;
	border-radius: 4px;
	color: #8b949e;
	pointer-events: none;
}

#ohlc-bar b {
	font-weight: 600;
	color: #e6edf3;
}

#pane-divider {
	height: 4px;
	background: #1c2128;
	cursor: row-resize;
	display: none;
}

#pane-divider:hover {
	background: #58a6ff;
}

#rsi-container {
	height: 150px;
	display: none;
}

.settings-wrap {
    position: relative;
    margin-left: auto;
}

.settings-menu {
    display: none;
    position: absolute;
    top: calc(100% + 6px);
    right: 0;
    background: #1c2128;
    border: 1px solid #30363d;
    border-radius: 8px;
    padding: 8px 0;
    min-width: 220px;
    z-index: 100;
    box-shadow: 0 8px 24px rgba(0,0,0,0.4);
}

.settings-menu.open {
    display: block;
}

.settings-title {
    font-size: 12px;
    color: #8b949e;
    padding: 4px 16px 8px;
    border-bottom: 1px solid #30363d;
    margin-bottom: 4px;
}

.settings-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 8px 16px;
    cursor: pointer;
    gap: 12px;
}

.settings-item:hover {
    background: #2d333b;
}

.settings-label {
    display: flex;
    flex-direction: column;
    gap: 2px;
    font-size: 13px;
    color: #e6edf3;
}

.settings-label small {
    font-size: 11px;
    color: #8b949e;
}

.settings-item input[type="checkbox"] {
    width: 16px;
    height: 16px;
    accent-color: #1f6feb;
    cursor: pointer;
    flex-shrink: 0;
}
</style>
</head>

<body>
    <div class="page">

        <nav>
            <span class="logo">Trade<span>Bot</span></span> <a href="/dashboard" class="nav-item">대시보드</a> <span
                class="nav-item active">차트</span> <span class="nav-item">백테스트</span> <span class="nav-item">자동매매</span>
            <span class="nav-item">로그</span> <span class="nav-item">설정</span>
        </nav>

        <div class="price-header">
            <span class="ph-symbol">BTC / USDT</span> <span class="ph-price up" id="ph-price">-</span>
            <div class="ph-divider"></div>
            <div class="ph-item">
                <span class="ph-label">24h 변동</span> <span class="ph-value" id="ph-change">-</span>
            </div>
            <div class="ph-item">
                <span class="ph-label">24h 고가</span> <span class="ph-value" id="ph-high">-</span>
            </div>
            <div class="ph-item">
                <span class="ph-label">24h 저가</span> <span class="ph-value" id="ph-low">-</span>
            </div>
            <div class="ph-item">
                <span class="ph-label">24h 거래량</span> <span class="ph-value" id="ph-vol">-</span>
            </div>
        </div>

        <div class="toolbar">
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
            <div class="tb-divider"></div>
            <button class="ind-btn" id="ind-ma5" onclick="toggleInd('ma5')">MA5</button>
            <button class="ind-btn" id="ind-ma20" onclick="toggleInd('ma20')">MA20</button>
            <button class="ind-btn" id="ind-ma60" onclick="toggleInd('ma60')">MA60</button>
            <button class="ind-btn" id="ind-bb" onclick="toggleInd('bb')">BB</button>
            <button class="ind-btn" id="ind-ichimoku" onclick="toggleInd('ichimoku')">일목</button>
            <button class="ind-btn" id="ind-rsi" onclick="toggleInd('rsi')">RSI</button>

            <div class="tb-divider"></div>
            <div class="settings-wrap">
                <button class="ind-btn" onclick="toggleSettingsMenu()">⚙ 설정</button>
                <div class="settings-menu" id="settings-menu">
                    <div class="settings-title">차트 설정</div>
                    <label class="settings-item">
                        <span class="settings-label">
                            <span>최고 최저 가격</span>
                        </span>
                        <input type="checkbox" id="set-highlow" onchange="toggleHighLow(this.checked)" checked>
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
                        <input type="checkbox" id="set-countdown" onchange="toggleCountdown(this.checked)" checked>
                    </label>
                </div>
            </div>

        </div>

        <div class="body">

            <div class="chart-area">
                <div id="chart-wrapper">
                    <div id="chart-container">
                        <!-- 최고가 라벨 (캔들 위) -->
                        <!-- 최고가 -->
                        <div id="hl-high"
                            style="position:absolute; display:none; flex-direction:column; align-items:center; pointer-events:none; z-index:10; transform:translateX(-50%);">
                            <span id="hl-high-val"
                                style="font-size:11px; color:#ff3b30; white-space:nowrap; background:rgba(13,17,23,0.8); padding:1px 4px; border-radius:3px;"></span>
                            <span
                                style="color:#ff3b30; font-size:12px; display:block; transform:rotate(90deg); line-height:1;">⇒</span>
                        </div>

                        <!-- 최저가 라벨 (캔들 아래) -->
                        <div id="hl-low"
                            style="position:absolute; display:none; flex-direction:column; align-items:center; pointer-events:none; z-index:10; transform:translateX(-50%);">
                            <span
                                style="color:#007aff; font-size:12px; display:block; transform:rotate(-90deg); line-height:1;">⇒</span>
                            <span id="hl-low-val"
                                style="font-size:11px; color:#007aff; white-space:nowrap; background:rgba(13,17,23,0.8); padding:1px 4px; border-radius:3px;"></span>
                        </div>
                        <div id="ohlc-bar">
                            <span>O: <b id="val-o">-</b></span>&nbsp; <span>H: <b id="val-h"
                                    style="color: #ff3b30">-</b></span>&nbsp; <span>L: <b id="val-l"
                                    style="color: #007aff">-</b></span>&nbsp; <span>C: <b id="val-c">-</b></span>
                        </div>
                    </div>
                    <div id="pane-divider"></div>
                    <div id="rsi-container"></div>
                </div>
            </div>

            <div class="right-panel">
                <div class="rp-tabs">
                    <div class="rp-tab active" onclick="switchRpTab(0)">수동 주문</div>
                    <div class="rp-tab" onclick="switchRpTab(1)">봇 관리</div>
                </div>

                <div class="order-panel" id="panel-order">
                    <div style="display:flex; margin-bottom:10px;">
                        <button id="tab-buy" onclick="switchOrderTab('buy')"
                            style="flex:1; padding:8px; background:#ff3b30; color:#fff; border:none; cursor:pointer; border-radius:4px 0 0 4px; font-weight:bold;">매수</button>
                        <button id="tab-sell" onclick="switchOrderTab('sell')"
                            style="flex:1; padding:8px; background:#1c2128; color:#8b949e; border:none; cursor:pointer; border-radius:0 4px 4px 0;">매도</button>
                    </div>
                    <div class="order-type-row">
                        <button class="order-type-btn sel" onclick="selectOrderType(this)">지정가</button>
                        <button class="order-type-btn" onclick="selectOrderType(this)">시장가</button>
                    </div>
                    <div class="order-section-label">가격 (USDT)</div>
                    <div class="order-input-row">
                        <input class="order-input" id="trade-price-input" type="number" placeholder="0.00"> <span
                            class="order-input-unit">USDT</span>
                    </div>
                    <div class="order-section-label">수량 (BTC)</div>
                    <div class="order-input-row">
                        <input class="order-input" id="trade-qty" type="number" placeholder="0.000" step="0.001"
                            oninput="calcAmount()">
                        <span class="order-input-unit">BTC</span>
                    </div>
                    <div class="pct-row">
                        <button class="pct-btn" onclick="setPercent(25)">25%</button>
                        <button class="pct-btn" onclick="setPercent(50)">50%</button>
                        <button class="pct-btn" onclick="setPercent(75)">75%</button>
                        <button class="pct-btn" onclick="setPercent(100)">최대</button>
                    </div>
                    <div class="order-section-label">주문금액 (USDT)</div>
                    <div class="order-input-row" style="margin-bottom: 14px">
                        <input class="order-input" id="trade-amount" type="number" readonly style="background: #0d1117">
                        <span class="order-input-unit">USDT</span>
                    </div>
                    <div class="order-avail">
                        가용 잔고 <span>- USDT</span>
                    </div>
                    <button id="order-submit-btn" class="btn-long" onclick="submitOrder(orderSide)">매수 주문</button>
                </div>

                <div class="bot-panel" id="panel-bot">
                    <div class="bot-card">
                        <div class="bc-header">
                            <span class="bc-name">준비 중</span><span class="bc-dot off"></span>
                        </div>
                        <div class="bc-row">
                            <span>봇 기능은 추후 지원 예정입니다.</span>
                        </div>
                    </div>
                    <button class="bot-add-btn">+ 새 봇 추가</button>
                </div>
            </div>

        </div>

        <div class="bottom-panel">
            <div class="bp-tabs">
                <div class="bp-tab active" onclick="switchBpTab(this)">오픈 포지션</div>
                <div class="bp-tab" onclick="switchBpTab(this)">오픈 오더</div>
                <div class="bp-tab" onclick="switchBpTab(this)">거래 기록</div>
            </div>
            <div class="bp-content" id="bp-content">
                <div class="bp-empty" id="bp-empty">포지션이 없습니다.</div>
                <table class="bp-table" id="bp-holdings-table" style="display: none">
                    <thead>
                        <tr>
                            <th>코인</th>
                            <th>보유수량</th>
                            <th>평균단가</th>
                            <th>현재가</th>
                            <th>평가손익</th>
                        </tr>
                    </thead>
                    <tbody id="bp-holdings-body"></tbody>
                </table>
            </div>
        </div>

    </div>

    <script>

        let showHighLow = true;

        function updateHighLow() {
            if (!showHighLow) return;
            const lr = chart.timeScale().getVisibleLogicalRange();
            if (!lr || allData.length === 0) return;

            const from = Math.max(0, Math.floor(lr.from));
            const to = Math.min(allData.length - 1, Math.ceil(lr.to));
            const visible = allData.slice(from, to + 1);
            if (visible.length === 0) return;

            let highVal = -Infinity, lowVal = Infinity;
            let highCandle, lowCandle;

            visible.forEach(d => {
                if (d.high > highVal) { highVal = d.high; highCandle = d; }
                if (d.low < lowVal) { lowVal = d.low; lowCandle = d; }
            });

            const highX = chart.timeScale().timeToCoordinate(highCandle.time);
            const highY = candleSeries.priceToCoordinate(highVal);
            const lowX = chart.timeScale().timeToCoordinate(lowCandle.time);
            const lowY = candleSeries.priceToCoordinate(lowVal);

            const highEl = document.getElementById('hl-high');
            const lowEl = document.getElementById('hl-low');

            if (highX != null && highY != null) {
                highEl.style.display = 'flex';
                highEl.style.left = highX + 'px';
                // 최고가
                highEl.style.top = (highY - 48) + 'px';  // 기존 -22 → -48 (더 위로)
                document.getElementById('hl-high-val').textContent = highVal.toLocaleString() + ' USDT';
            }
            if (lowX != null && lowY != null) {
                lowEl.style.display = 'flex';
                lowEl.style.left = lowX + 'px';
                // 최저가
                lowEl.style.top = (lowY + 10) + 'px';  // 기존 +6 → +10 (더 아래로)
                document.getElementById('hl-low-val').textContent = lowVal.toLocaleString() + ' USDT';
            }
        }

        function toggleHighLow(enabled) {
            showHighLow = enabled;
            document.getElementById('hl-high').style.display = enabled ? 'flex' : 'none';
            document.getElementById('hl-low').style.display = enabled ? 'flex' : 'none';
            if (enabled) updateHighLow();
        }

        // 설정 메뉴 토글
        function toggleSettingsMenu() {
            document.getElementById('settings-menu').classList.toggle('open');
        }

        // 외부 클릭시 닫기
        document.addEventListener('click', function (e) {
            if (!e.target.closest('.settings-wrap')) {
                document.getElementById('settings-menu').classList.remove('open');
            }
        });




        let countdownPrimitive = null;
        // 봉 카운트다운 on/off
        function startCountdown() {
            if (!countdownPrimitive) {
                countdownPrimitive = new CountdownToClose.CountdownToClose({
                    customLastPriceLine: true,
                    timeframeInSeconds: currentTfSeconds,
                    timeLabelFormatter: (ttcc) => {
                        // 총 남은 초 계산
                        const totalSecs = ttcc.days * 86400 + ttcc.hours * 3600 + ttcc.minutes * 60 + ttcc.seconds;
                        const h = Math.floor(totalSecs / 3600);
                        const m = Math.floor((totalSecs % 3600) / 60);
                        const s = totalSecs % 60;

                        // 12H, 1D - 항상 HH:MM:SS
                        if (currentTfSeconds >= 43200) {
                            return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
                        }

                        // 1분 ~ 6H - 남은시간 기준
                        if (h > 0) {
                            return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
                        }
                        return String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
                    }
                });
                candleSeries.applyOptions({ lastValueVisible: false, priceLineVisible: false });
                candleSeries.attachPrimitive(countdownPrimitive);
            }
        }

        function toggleCountdown(enabled) {
            showCountdown = enabled;
            if (enabled) {
                startCountdown();
                countdownPrimitive.applyOptions({ showLabels: true });
            } else {
                if (countdownPrimitive) countdownPrimitive.applyOptions({ showLabels: false });
                candleSeries.applyOptions({ lastValueVisible: true, priceLineVisible: true });
            }
        }

        // --- 패널 드래그 리사이즈 ---
        let isDragging = false, dragStartY = 0, dragStartRsiHeight = 0;
        document.getElementById('pane-divider').addEventListener('mousedown', (e) => {
            isDragging = true;
            dragStartY = e.clientY;
            dragStartRsiHeight = document.getElementById('rsi-container').clientHeight;
            document.body.style.cursor = 'row-resize';
            document.body.style.userSelect = 'none';
        });
        document.addEventListener('mousemove', (e) => {
            if (!isDragging) return;
            const delta = dragStartY - e.clientY;
            const newHeight = Math.max(80, Math.min(400, dragStartRsiHeight + delta));
            document.getElementById('rsi-container').style.height = newHeight + 'px';
        });
        document.addEventListener('mouseup', () => {
            isDragging = false;
            document.body.style.cursor = '';
            document.body.style.userSelect = '';
        });

        // --- 상태 ---
        let currentGranularity = '1min';
        let currentChannel = 'candle1m';
        let currentWs = null;
        let lastPrice = 0;
        let orderSide = 'buy';
        let walletBalance = 0;
        let allData = [];
        let isLoadingMore = false;
        let isLog = false;
        let currentTfSeconds = 60;
        let showCountdown = true;

        const TF_MAP = {
            '1min': { channel: 'candle1m', restGran: '1min', label: '1분', seconds: 60 },
            '3min': { channel: 'candle3m', restGran: '3min', label: '3분', seconds: 180 },
            '5min': { channel: 'candle5m', restGran: '5min', label: '5분', seconds: 300 },
            '15min': { channel: 'candle15m', restGran: '15min', label: '15분', seconds: 900 },
            '30min': { channel: 'candle30m', restGran: '30min', label: '30분', seconds: 1800 },
            '1h': { channel: 'candle1H', restGran: '1h', label: '1H', seconds: 3600 },
            '4h': { channel: 'candle4H', restGran: '4h', label: '4H', seconds: 14400 },
            '6h': { channel: 'candle6H', restGran: '6h', label: '6H', seconds: 21600 },
            '12h': { channel: 'candle12H', restGran: '12h', label: '12H', seconds: 43200 },
            '1day': { channel: 'candle1D', restGran: '1day', label: '1D', seconds: 86400 },
            '3day': { channel: 'candle3D', restGran: '3day', label: '3D', seconds: 259200 },
            '1week': { channel: 'candle1W', restGran: '1week', label: '1W', seconds: 604800 },
            '1month': { channel: 'candle1M', restGran: '1M', label: '1M', seconds: 2592000 },
        };

        // --- 차트 생성 ---
        const container = document.getElementById('chart-container');
        const chart = LightweightCharts.createChart(container, {
            autoSize: true,
            layout: { background: { color: '#0d1117' }, textColor: '#8b949e' },
            grid: { vertLines: { color: '#1c2128' }, horzLines: { color: '#1c2128' } },
            timeScale: { timeVisible: true, secondsVisible: false, borderColor: '#1c2128' },
            rightPriceScale: { borderColor: '#1c2128' },
            crosshair: { mode: LightweightCharts.CrosshairMode.Normal, vertLine: { color: '#484f58' }, horzLine: { color: '#484f58' } },
        });

        // 캔들 (한국식: 상승=빨강, 하락=파랑)
        const candleSeries = chart.addSeries(LightweightCharts.CandlestickSeries, {
            upColor: '#ff3b30', downColor: '#007aff',
            borderUpColor: '#ff3b30', borderDownColor: '#007aff',
            wickUpColor: '#ff3b30', wickDownColor: '#007aff',
        });

        // 이동평균선
        const ma5Series = chart.addSeries(LightweightCharts.LineSeries, { color: '#FF9800', lineWidth: 1, title: 'MA5', visible: false, priceLineVisible: false });
        const ma20Series = chart.addSeries(LightweightCharts.LineSeries, { color: '#58a6ff', lineWidth: 1, title: 'MA20', visible: false, priceLineVisible: false });
        const ma60Series = chart.addSeries(LightweightCharts.LineSeries, { color: '#9C27B0', lineWidth: 1, title: 'MA60', visible: false, priceLineVisible: false });

        // 볼린저밴드
        const bbUpperSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#FF5722', lineWidth: 1, lineStyle: LightweightCharts.LineStyle.Dashed, title: 'BB↑', visible: false, priceLineVisible: false });
        const bbMiddleSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#FF572288', lineWidth: 1, title: 'BB', visible: false, priceLineVisible: false });
        const bbLowerSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#FF5722', lineWidth: 1, lineStyle: LightweightCharts.LineStyle.Dashed, title: 'BB↓', visible: false, priceLineVisible: false });

        // 일목균형표
        const ichiTenkanSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#E91E63', lineWidth: 1, title: '전환', visible: false, priceLineVisible: false });
        const ichiKijunSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#58a6ff', lineWidth: 1, title: '기준', visible: false, priceLineVisible: false });
        const ichiSpanASeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#4CAF50', lineWidth: 1, title: '선행A', visible: false, priceLineVisible: false });
        const ichiSpanBSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#FF9800', lineWidth: 1, title: '선행B', visible: false, priceLineVisible: false });
        const ichiChikouSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#9E9E9E', lineWidth: 1, title: '후행', visible: false, priceLineVisible: false });
        // 거래량
        const volumeSeries = chart.addSeries(LightweightCharts.HistogramSeries, {
            priceFormat: { type: 'volume' }, priceScaleId: 'volume', priceLineVisible: false,
        });
        chart.priceScale('volume').applyOptions({ scaleMargins: { top: 0.8, bottom: 0 } });

        // RSI 차트
        const rsiContainer = document.getElementById('rsi-container');
        const rsiChart = LightweightCharts.createChart(rsiContainer, {
            autoSize: true,
            layout: { background: { color: '#0d1117' }, textColor: '#8b949e' },
            grid: { vertLines: { color: '#1c2128' }, horzLines: { color: '#1c2128' } },
            timeScale: {
                timeVisible: true,
                secondsVisible: false,
                borderColor: '#1c2128',
                tickMarkFormatter: (time) => {
                    const d = new Date((time) * 1000);
                    return d.toISOString().slice(11, 16);
                }
            },
            rightPriceScale: { borderColor: '#1c2128', scaleMargins: { top: 0.1, bottom: 0.1 } },
            crosshair: { mode: LightweightCharts.CrosshairMode.Normal, vertLine: { color: '#484f58' }, horzLine: { color: '#484f58' } },
        });
        const rsiSeries = rsiChart.addSeries(LightweightCharts.LineSeries, { color: '#9C27B0', lineWidth: 1, title: 'RSI', priceLineVisible: false });
        const rsiOverbought = rsiChart.addSeries(LightweightCharts.LineSeries, { color: '#ff3b3066', lineWidth: 1, lineStyle: LightweightCharts.LineStyle.Dashed, priceLineVisible: false });
        const rsiOversold = rsiChart.addSeries(LightweightCharts.LineSeries, { color: '#007aff66', lineWidth: 1, lineStyle: LightweightCharts.LineStyle.Dashed, priceLineVisible: false });

        // --- 인디케이터 상태 ---
        const indState = { ma5: false, ma20: false, ma60: false, bb: false, ichimoku: false, rsi: false };

        // 초기 활성 버튼 표시
        // setIndBtnStyle('ma5', true);
        // setIndBtnStyle('ma20', true);

        function setIndBtnStyle(name, on) {
            const btn = document.getElementById('ind-' + name);
            const colors = { ma5: '#FF9800', ma20: '#58a6ff', ma60: '#9C27B0', bb: '#FF5722', ichimoku: '#E91E63', rsi: '#9C27B0' };
            const c = colors[name];
            if (on) {
                btn.style.borderColor = c;
                btn.style.color = c;
                btn.style.background = c + '18';
            } else {
                btn.style.borderColor = '';
                btn.style.color = '';
                btn.style.background = '';
            }
        }

        // --- 지표 계산 및 차트 반영 ---
        function ichiAvg(arr, i, period) {
            const sl = arr.slice(Math.max(0, i - period + 1), i + 1);
            return (Math.max(...sl.map(d => d.high)) + Math.min(...sl.map(d => d.low))) / 2;
        }

        function updateAllSeries(data) {
            candleSeries.setData(data);
            window.currentDataLength = data.length;
            window.lastCandleTime = data[data.length - 1].time;

            volumeSeries.setData(data.map(d => ({
                time: d.time, value: d.volume,
                color: d.close >= d.open ? '#ff3b3055' : '#007aff55'
            })));

            const ma5Data = [], ma20Data = [], ma60Data = [];
            data.forEach((d, i) => {
                if (i >= 5) ma5Data.push({ time: d.time, value: data.slice(i - 5, i).reduce((s, c) => s + c.close, 0) / 5 });
                if (i >= 20) ma20Data.push({ time: d.time, value: data.slice(i - 20, i).reduce((s, c) => s + c.close, 0) / 20 });
                if (i >= 60) ma60Data.push({ time: d.time, value: data.slice(i - 60, i).reduce((s, c) => s + c.close, 0) / 60 });
            });
            ma5Series.setData(ma5Data);
            ma20Series.setData(ma20Data);
            ma60Series.setData(ma60Data);

            const bbUpper = [], bbMiddle = [], bbLower = [];
            data.forEach((d, i) => {
                if (i < 20) return;
                const sl = data.slice(i - 20, i);
                const avg = sl.reduce((s, c) => s + c.close, 0) / 20;
                const std = Math.sqrt(sl.reduce((s, c) => s + Math.pow(c.close - avg, 2), 0) / 20);
                bbUpper.push({ time: d.time, value: avg + 2 * std });
                bbMiddle.push({ time: d.time, value: avg });
                bbLower.push({ time: d.time, value: avg - 2 * std });
            });
            bbUpperSeries.setData(bbUpper);
            bbMiddleSeries.setData(bbMiddle);
            bbLowerSeries.setData(bbLower);

            const tenkan = [], kijun = [], spanA = [], spanB = [], chikou = [];
            data.forEach((d, i) => {
                if (i >= 8) tenkan.push({ time: d.time, value: ichiAvg(data, i, 9) });
                if (i >= 25) {
                    kijun.push({ time: d.time, value: ichiAvg(data, i, 26) });
                    spanA.push({ time: d.time, value: (ichiAvg(data, i, 9) + ichiAvg(data, i, 26)) / 2 });
                    spanB.push({ time: d.time, value: ichiAvg(data, i, 52) });
                }
                if (i + 26 < data.length) chikou.push({ time: data[i + 26].time, value: d.close });
            });
            ichiTenkanSeries.setData(tenkan);
            ichiKijunSeries.setData(kijun);
            ichiSpanASeries.setData(spanA);
            ichiSpanBSeries.setData(spanB);
            ichiChikouSeries.setData(chikou);

            const rsiData = [];
            for (let i = 14; i < data.length; i++) {
                let gain = 0, loss = 0;
                for (let j = i - 13; j <= i; j++) {
                    const diff = data[j].close - data[j - 1].close;
                    if (diff > 0) gain += diff; else loss -= diff;
                }
                rsiData.push({ time: data[i].time, value: 100 - 100 / (1 + gain / (loss || 1)) });
            }
            rsiSeries.setData(rsiData);
            if (indState.rsi && rsiData.length > 0) {
                rsiSeries.setData(rsiData);
                rsiOverbought.setData(rsiData.map(d => ({ time: d.time, value: 70 })));
                rsiOversold.setData(rsiData.map(d => ({ time: d.time, value: 30 })));
            } else {
                rsiSeries.setData([]);
                rsiOverbought.setData([]);
                rsiOversold.setData([]);
            }
            setTimeout(() => {
                const lr = chart.timeScale().getVisibleLogicalRange();
                if (lr) { try { rsiChart.timeScale().setVisibleLogicalRange(lr); } catch (e) { } }
            }, 50);
        }

        // --- 데이터 로드 ---
        async function loadData() {
            const res = await fetch(
                'https://api.bitget.com/api/v2/spot/market/candles?symbol=BTCUSDT&granularity=' + currentGranularity + '&limit=200'
            ).then(r => r.json());
            if (res.code !== '00000') return;

            allData = res.data.map(item => ({
                time: Math.floor(item[0] / 1000),
                open: parseFloat(item[1]), high: parseFloat(item[2]),
                low: parseFloat(item[3]), close: parseFloat(item[4]),
                volume: parseFloat(item[5])
            })).sort((a, b) => a.time - b.time);
            updateAllSeries(allData);
        }

        // --- 과거 데이터 추가 로드 ---
        let loadMoreTimer = null;
        function loadMoreData() {
            if (isLoadingMore || allData.length === 0) return;
            clearTimeout(loadMoreTimer);
            loadMoreTimer = setTimeout(async () => {
                isLoadingMore = true;
                try {
                    const oldestTime = allData[0].time;
                    const endTimeMs = (oldestTime) * 1000 - 1;
                    const res = await fetch(
                        'https://api.bitget.com/api/v2/spot/market/candles?symbol=BTCUSDT&granularity=' + currentGranularity + '&limit=200&endTime=' + endTimeMs
                    ).then(r => r.json());

                    if (res.code === '00000' && res.data && res.data.length > 0) {
                        const older = res.data.map(item => ({
                            time: Math.floor(item[0] / 1000),
                            open: parseFloat(item[1]), high: parseFloat(item[2]),
                            low: parseFloat(item[3]), close: parseFloat(item[4]),
                            volume: parseFloat(item[5])
                        })).filter(d => d.time > 0 && d.open > 0 && d.close > 0 && d.time < oldestTime);

                        if (older.length > 0) {
                            const lr = chart.timeScale().getVisibleLogicalRange();
                            allData = [...older, ...allData];
                            updateAllSeries(allData);
                            if (lr) chart.timeScale().setVisibleLogicalRange({
                                from: lr.from + older.length,
                                to: lr.to + older.length
                            });
                        }
                    }
                } catch (e) { console.error('loadMoreData:', e); }
                isLoadingMore = false;
            }, 200);
        }

        // --- 타임프레임 전환 ---
        function changeTimeframe(gran) {
            document.querySelectorAll('.tf-btn[data-tf]').forEach(btn => btn.classList.remove('active'));
            event.target.classList.add('active');

            const lr = chart.timeScale().getVisibleLogicalRange();
            const totalBars = window.currentDataLength || 200;
            const rightOffset = lr ? lr.to - totalBars : 10;
            const barCount = lr ? lr.to - lr.from : 50;

            currentGranularity = TF_MAP[gran].restGran;
            currentChannel = TF_MAP[gran].channel;
            currentTfSeconds = TF_MAP[gran].seconds;
            if (countdownPrimitive) {
                countdownPrimitive.applyOptions({
                    timeframeInSeconds: currentTfSeconds,
                    timeLabelFormatter: currentTfSeconds >= 259200
                        ? (ttcc) => {
                            if (ttcc.days > 0) return ttcc.days + 'd ' + ttcc.hours + 'h';
                            if (ttcc.hours > 0) return ttcc.hours + 'h ' + ttcc.minutes + 'm';
                            if (ttcc.minutes > 0) return ttcc.minutes + 'm ' + ttcc.seconds + 's';
                            return ttcc.seconds + 's';
                        }
                        : (ttcc) => {
                            const totalSecs = ttcc.days * 86400 + ttcc.hours * 3600 + ttcc.minutes * 60 + ttcc.seconds;
                            const h = Math.floor(totalSecs / 3600);
                            const m = Math.floor((totalSecs % 3600) / 60);
                            const s = totalSecs % 60;
                            if (currentTfSeconds >= 43200) {
                                return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
                            }
                            if (h > 0) {
                                return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
                            }
                            return String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
                        }
                });
            }
            allData = [];
            // 교체
            if (currentWs) {
                currentWs.onclose = null;  // 재연결 방지
                if (currentWs.readyState === WebSocket.OPEN || currentWs.readyState === WebSocket.CONNECTING) {
                    currentWs.close();
                }
                currentWs = null;
            }

            loadData().then(() => {
                const nb = window.currentDataLength || 200;
                chart.timeScale().setVisibleLogicalRange({ from: nb + rightOffset - barCount, to: nb + rightOffset });
                connectWebSocket();
            });
        }

        // --- 로그 차트 ---
        function toggleLog() {
            isLog = !isLog;
            chart.priceScale('right').applyOptions({ mode: isLog ? 1 : 0 });
            document.getElementById('set-log').checked = isLog;
        }

        // --- 인디케이터 토글 ---
        function toggleInd(name) {
            indState[name] = !indState[name];
            const on = indState[name];
            setIndBtnStyle(name, on);

            if (name === 'ma5') ma5Series.applyOptions({ visible: on });
            else if (name === 'ma20') ma20Series.applyOptions({ visible: on });
            else if (name === 'ma60') ma60Series.applyOptions({ visible: on });
            else if (name === 'bb') {
                bbUpperSeries.applyOptions({ visible: on });
                bbMiddleSeries.applyOptions({ visible: on });
                bbLowerSeries.applyOptions({ visible: on });
            } else if (name === 'ichimoku') {
                [ichiTenkanSeries, ichiKijunSeries, ichiSpanASeries, ichiSpanBSeries, ichiChikouSeries]
                    .forEach(s => s.applyOptions({ visible: on }));
            } else if (name === 'rsi') {
                rsiContainer.style.display = on ? 'block' : 'none';
                document.getElementById('pane-divider').style.display = on ? 'block' : 'none';
                if (on) {
                    setTimeout(() => {
                        const lr = chart.timeScale().getVisibleLogicalRange();
                        if (lr) { try { rsiChart.timeScale().setVisibleLogicalRange(lr); } catch (e) { } }
                    }, 50);
                }
            }
        }

        // --- WebSocket ---
        function connectWebSocket() {
            const ws = new WebSocket('wss://ws.bitget.com/v2/ws/public');
            currentWs = ws;

            ws.onopen = () => {
                ws.send(JSON.stringify({
                    op: 'subscribe',
                    args: [{ instType: 'SPOT', channel: currentChannel, instId: 'BTCUSDT' }]
                }));
                setInterval(() => ws.readyState === 1 && ws.send('ping'), 20000);
            };

            ws.onmessage = (event) => {
                if (ws !== currentWs) return;
                if (event.data === 'pong') return;
                const msg = JSON.parse(event.data);
                if (!msg.data) return;

                const item = msg.data[0];
                const bar = {
                    time: Math.floor(item[0] / 1000),
                    open: parseFloat(item[1]),
                    high: parseFloat(item[2]),
                    low: parseFloat(item[3]),
                    close: parseFloat(item[4])
                };
                if (window.lastCandleTime && bar.time < window.lastCandleTime) return;
                candleSeries.update(bar);
                updateOhlc(bar.open, bar.high, bar.low, bar.close);
                lastPrice = bar.close;
                const priceEl = document.getElementById('holding-price');
                const pnlEl = document.getElementById('holding-pnl');
                if (priceEl && pnlEl) {
                    const avgPrice = parseFloat(priceEl.closest('tr').children[2].textContent);
                    const coinCount = parseFloat(priceEl.closest('tr').children[1].textContent);
                    const pnl = (lastPrice - avgPrice) * coinCount;
                    priceEl.textContent = lastPrice.toFixed(2);
                    pnlEl.textContent = (pnl >= 0 ? '+' : '') + pnl.toFixed(2) + ' USDT';
                    pnlEl.style.color = pnl >= 0 ? '#ff3b30' : '#007aff';
                }
                updatePriceHeader(bar.close);
            };

            ws.onclose = () => {
                if (ws === currentWs) setTimeout(connectWebSocket, 3000);
            };
        }

        function updateOhlc(o, h, l, c) {
            document.getElementById('val-o').textContent = o.toFixed(2);
            document.getElementById('val-h').textContent = h.toFixed(2);
            document.getElementById('val-l').textContent = l.toFixed(2);
            document.getElementById('val-c').textContent = c.toFixed(2);
        }

        function updatePriceHeader(price) {
            const el = document.getElementById('ph-price');
            el.textContent = price.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
            const input = document.getElementById('trade-price-input');
            if (input && !input.value) input.placeholder = price.toFixed(2);
        }

        // 24h 티커 로드
        async function loadTicker() {
            try {
                const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers?symbol=BTCUSDT').then(r => r.json());
                if (res.code === '00000' && res.data && res.data[0]) {
                    const d = res.data[0];
                    const price = parseFloat(d.lastPr);
                    const chgPct = parseFloat(d.change24h) * 100;
                    const high24 = parseFloat(d.high24h);
                    const low24 = parseFloat(d.low24h);
                    const vol24 = parseFloat(d.baseVolume);

                    lastPrice = price;
                    updatePriceHeader(price);
                    document.getElementById('ph-price').className = 'ph-price ' + (chgPct >= 0 ? 'up' : 'down');

                    const chgEl = document.getElementById('ph-change');
                    chgEl.textContent = (chgPct >= 0 ? '+' : '') + chgPct.toFixed(2) + '%';
                    chgEl.className = 'ph-value ' + (chgPct >= 0 ? 'up' : 'down');

                    document.getElementById('ph-high').textContent = high24.toLocaleString();
                    document.getElementById('ph-low').textContent = low24.toLocaleString();
                    document.getElementById('ph-vol').textContent = vol24.toFixed(0) + ' BTC';
                }
            } catch (e) { }
        }

        // --- 크로스헤어 OHLC ---
        chart.subscribeCrosshairMove(param => {
            if (!param.time) return;
            const candle = param.seriesData.get(candleSeries);
            if (!candle) return;
            updateOhlc(candle.open, candle.high, candle.low, candle.close);
        });
        const chartWrapper = document.getElementById('chart-wrapper');
        chartWrapper.addEventListener('mousemove', updateHighLow);
        chartWrapper.addEventListener('mouseup', updateHighLow);

        // --- RSI 동기 + 과거 데이터 lazy load ---
        chart.timeScale().subscribeVisibleLogicalRangeChange((lr) => {
            updateHighLow();
            if (lr) {
                try { rsiChart.timeScale().setVisibleLogicalRange(lr); } catch (e) { }
                if (lr.from < 10) loadMoreData();
            }
        });

        function switchOrderTab(side) {
            orderSide = side;
            const isBuy = side === 'buy';
            // 탭 색상
            document.getElementById('tab-buy').style.background = isBuy ? '#ff3b30' : '#1c2128';
            document.getElementById('tab-buy').style.color = isBuy ? '#fff' : '#8b949e';
            document.getElementById('tab-sell').style.background = isBuy ? '#1c2128' : '#007aff';
            document.getElementById('tab-sell').style.color = isBuy ? '#8b949e' : '#fff';
            // 주문 버튼
            document.getElementById('order-submit-btn').textContent = isBuy ? '매수 주문' : '매도 주문';
            document.getElementById('order-submit-btn').className = isBuy ? 'btn-long' : 'btn-short';
            // 가용 잔고 표시
            const availEl = document.querySelector('.order-avail span');
            if (isBuy) {
                availEl.textContent = walletBalance.toFixed(2) + ' USDT';
            } else {
                const holding = parseFloat(document.getElementById('bp-holdings-body')
                    ?.querySelector('tr')?.children[1]?.textContent) || 0;
                availEl.textContent = holding.toFixed(6) + ' BTC';
            }
            calcAmount();
        }

        // --- 주문 ---
        function selectOrderType(btn) {
            document.querySelectorAll('.order-type-btn').forEach(b => b.classList.remove('sel'));
            btn.classList.add('sel');
        }
        function setPercent(pct) {
            if (orderSide === 'sell') {
                const holding = parseFloat(document.getElementById('bp-holdings-body')
                    ?.querySelector('tr')?.children[1]?.textContent) || 0;
                document.getElementById('trade-qty').value = (holding * pct / 100).toFixed(6);
            } else {
                document.getElementById('trade-qty').value = (walletBalance * pct / 100 / (lastPrice || 1)).toFixed(6);
            }
            calcAmount();
        }
        function calcAmount() {
            const qty = parseFloat(document.getElementById('trade-qty').value) || 0;
            document.getElementById('trade-amount').value = (qty * lastPrice).toFixed(2);
        }
        function submitOrder(side) {
            const qty = document.getElementById('trade-qty').value;
            if (!qty) { alert('수량을 입력하세요'); return; }

            fetch('/coin/' + side, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    username: 'testuser',       // 나중에 세션으로 교체
                    coinCode: 'BTCUSDT',
                    orderPrice: lastPrice,
                    orderCount: qty
                })
            })
                .then(res => res.text())
                .then(result => {
                    if (result === 'success') {
                        alert((side === 'buy' ? '매수' : '매도') + ' 주문 완료!');
                        loadWallet();    // ← 추가
                        loadHoldings();  // ← 추가
                    } else {
                        alert('주문 실패: ' + result);
                    }
                })
                .catch(err => alert('오류: ' + err));
        }

        // --- 탭 전환 ---
        function switchRpTab(idx) {
            document.querySelectorAll('.rp-tab').forEach((t, i) => t.classList.toggle('active', i === idx));
            document.getElementById('panel-order').style.display = idx === 0 ? 'block' : 'none';
            document.getElementById('panel-bot').style.display = idx === 1 ? 'block' : 'none';
        }
        function switchBpTab(el) {
            document.querySelectorAll('.bp-tab').forEach(t => t.classList.remove('active'));
            el.classList.add('active');
        }

        async function loadWallet() {
            const res = await fetch('/coin/wallet?username=testuser').then(r => r.json());
            if (res && res.usdtBalance !== undefined) {
                walletBalance = res.usdtBalance;
                document.querySelector('.order-avail span').textContent = res.usdtBalance.toFixed(2) + ' USDT';
            }
        }

        async function loadHoldings() {
            const res = await fetch('/coin/holdings?username=testuser').then(r => r.json());
            console.log('holdings:', res);  // ← 추가
            const tbody = document.getElementById('bp-holdings-body');
            tbody.innerHTML = '';
            if (res && res.length > 0) {
                document.getElementById('bp-empty').style.display = 'none';
                document.getElementById('bp-holdings-table').style.display = 'table';
                let rows = '';
                res.forEach(h => {
                    const pnl = (lastPrice - h.avgPrice) * h.coinCount;
                    const pnlColor = pnl >= 0 ? '#ff3b30' : '#007aff';
                    rows += `<tr>
    <td>\${h.coinCode}</td>
    <td>\${h.coinCount.toFixed(6)}</td>
    <td>\${h.avgPrice.toFixed(2)}</td>
    <td id="holding-price">\${lastPrice.toFixed(2)}</td>
    <td id="holding-pnl" style="color:\${pnlColor}">\${pnl >= 0 ? '+' : ''}\${pnl.toFixed(2)} USDT</td>
</tr>`;
                });
                console.log('rows string:', rows);       // ← 여기
                tbody.innerHTML = rows;
                console.log('tbody rows count:', tbody.rows.length);  // ← 여기
            } else {
                document.getElementById('bp-empty').style.display = '';
                document.getElementById('bp-holdings-table').style.display = 'none';
            }
        }

        // --- 시작 ---
        loadTicker();
        loadWallet();
        loadData().then(() => {
            connectWebSocket();
            loadHoldings();  // loadData 끝난 후 실행 → lastPrice 설정된 이후
            startCountdown();
        });
    </script>
</body>

</html>