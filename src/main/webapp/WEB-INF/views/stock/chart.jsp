<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>TradeBot · 주식 차트</title>
<script
	src="https://unpkg.com/lightweight-charts@5.2.0/dist/lightweight-charts.standalone.production.js"></script>
<link rel="stylesheet"
	href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
<link rel="stylesheet" href="/css/common.css">
<link rel="stylesheet" href="/css/market/common.css">
<link rel="stylesheet" href="/css/market/chart.css">
<link rel="stylesheet" href="/css/market/stock/chart.css">
</head>

<body class="chart-page" data-sidebar-tab="invest">

	<div class="app-wrapper">

		<div class="page">
			<%@ include file="../common/nav.jsp"%> 
			<!--  -->

			<div class="price-header">
				<div class="ph-left">
					<div class="ph-name-row search-trigger" id="search-trigger">
						<div class="ph-name-group">
							<span class="ph-name" id="displayTitle">삼성전자</span>
							<span class="ph-ticker" id="displayCode">(005930)</span>
							<span class="ph-arrow">▾</span>
						</div>

						<div class="search-dropdown" id="search-dropdown">
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
								<div class="sd-label" id="sd-label">주요 종목</div>
								<div class="sd-list" id="sd-list"></div>
							</div>
						</div>
					</div>
					<div class="ph-price-row">
						<span class="ph-price" id="ph-price">-</span> <span
							style="width: 1px; height: 16px; background: var(--border2); margin: 0 6px; flex-shrink: 0; align-self: center;"></span>
						<span
							style="font-size: 13px; color: var(--text3); font-weight: 500; line-height: 1;">전일대비</span>
						<span class="ph-change" id="ph-change-abs">-</span> <span
							class="ph-change" id="ph-change">-</span>
					</div>
				</div>

				<div class="ph-right">
					<div class="ph-group">
						<div class="ph-item">
							<span class="ph-label">시가</span> <span class="ph-value"
								id="ph-open">-</span>
						</div>
						<div class="ph-item">
							<span class="ph-label">전일종가</span> <span class="ph-value"
								id="ph-prev">-</span>
						</div>
					</div>
					<div class="ph-vdivider"></div>
					<div class="ph-group">
						<div class="ph-item">
							<span class="ph-label">고가</span> <span class="ph-value up"
								id="ph-high">-</span>
						</div>
						<div class="ph-item">
							<span class="ph-label">저가</span> <span class="ph-value down"
								id="ph-low">-</span>
						</div>
					</div>
					<div class="ph-vdivider"></div>
					<div class="ph-group">
						<div class="ph-item">
							<span class="ph-label">거래량</span> <span class="ph-value"
								id="ph-vol">-</span>
						</div>
						<div class="ph-item">
							<span class="ph-label">거래대금</span> <span class="ph-value"
								id="ph-turnover">-</span>
						</div>
					</div>
				</div>

				<div class="ph-actions">
					<button class="ph-like-btn" id="watchlist-btn">
						<svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
						관심
					</button>
				</div>
			</div>

			<div class="main-layout">

				<!-- ① 차트 패널 -->
				<div class="card panel-chart" id="panel-chart">
					<div class="chart-toolbar">
						<button class="tf-btn" data-tf onclick="fetchChart('min',this)">1분</button>
<button class="tf-btn active" data-tf onclick="fetchChart('1y',this)">1D</button>
						<button class="tf-btn" data-tf onclick="fetchChart('3y',this)">1W</button>
						<button class="tf-btn" data-tf onclick="fetchChart('10y',this)">1M</button>

						<div class="tb-divider"></div>

						<button class="ind-btn" id="ind-ma5" onclick="toggleInd('ma5')">MA5</button>
						<button class="ind-btn" id="ind-ma20" onclick="toggleInd('ma20')">MA20</button>

						<div class="tb-divider"></div>

						<div class="settings-wrap">
							<button class="ind-btn" onclick="toggleSettingsMenu(event)">
								<span style="font-size: 24px;">⚙</span>
							</button>
							<div class="settings-menu" id="settings-menu">
								<div class="settings-title">차트 설정</div>
								<label class="settings-item"> <span
									class="settings-label"><span>최고 최저 가격</span></span> <input
									type="checkbox" id="set-highlow" checked
									onchange="toggleHighLow(this.checked)">
								</label> <label class="settings-item"> <span
									class="settings-label"> <span>로그 스케일</span> <small>변화율
											기준으로 차트 보기</small>
								</span> <input type="checkbox" id="set-log" onchange="toggleLog()">
								</label>
							</div>
						</div>
					</div>

					<div id="chart-wrapper">
						<div id="hl-high"
							style="position: absolute; display: none; flex-direction: column; align-items: center; pointer-events: none; z-index: 10; transform: translateX(-50%);">
							<span id="hl-high-val"
								style="font-size: 12px; color: var(--up); white-space: nowrap;"></span>
							<span
								style="color: var(--up); font-size: 12px; display: block; transform: rotate(90deg); line-height: 1;">⇒</span>
						</div>
						<div id="hl-low"
							style="position: absolute; display: none; flex-direction: column; align-items: center; pointer-events: none; z-index: 10; transform: translateX(-50%);">
							<span
								style="color: var(--down); font-size: 12px; display: block; transform: rotate(-90deg); line-height: 1;">⇒</span>
							<span id="hl-low-val"
								style="font-size: 12px; color: var(--down); white-space: nowrap;"></span>
						</div>
						<div id="chart-container">
							<div id="ohlc-bar">
								<span>O: <b id="val-o">-</b></span>&nbsp; <span>H: <b
									id="val-h">-</b></span>&nbsp; <span>L: <b id="val-l">-</b></span>&nbsp;
								<span>C: <b id="val-c">-</b></span>
							</div>
						</div>
					</div>
				</div>

				<div class="resize-h" id="rh-1"></div>

				<!-- ② 주문/호가 패널 -->
				<div class="panel-middle" id="panel-middle">
					<div class="card panel-order-wrap" id="panel-order-wrap">
						<div class="order-tabs">
							<div class="order-tab buy active" id="tab-buy"
								onclick="switchOrderTab('buy')">매수</div>
							<div class="order-tab sell" id="tab-sell"
								onclick="switchOrderTab('sell')">매도</div>
						</div>
						<div class="order-panel" id="panel-order">
							<div class="order-type-row">
								<button class="order-type-btn sel"
									onclick="selectOrderType(this)">지정가</button>
								<button class="order-type-btn" onclick="selectOrderType(this)">시장가</button>
							</div>
							<div class="order-section-label">가격 (원)</div>
							<div class="order-input-row">
								<input class="order-input" id="trade-price-input" type="number"
									placeholder="가격 입력" oninput="calcAmount()"> <span
									class="order-input-unit">원</span>
							</div>
							<div class="order-section-label">수량 (주)</div>
							<div class="order-input-row">
								<input class="order-input" id="trade-qty" type="number"
									placeholder="0" step="1" oninput="calcAmount()">
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
								<span class="order-avail">가용 <span id="avail-balance">- 원</span></span>
								<span class="order-amount-label">주문금액 <span id="trade-amount">0</span> 원</span>
							</div>
							<button id="order-submit-btn" class="btn-buy"
								onclick="submitOrder(orderSide)">매수 주문</button>
						</div>
					</div>

					<div class="resize-v" id="rh-v"></div>

					<div class="card panel-hoga" id="panel-hoga">
						<div class="hoga-header-row">
							<span>호가</span> <span>수량(주)</span> <span>총량</span>
						</div>
						<div class="hoga-body">
							<div class="hoga-top">
								<table class="hoga-table">
									<tbody id="hoga-asks">
										<tr class="hoga-skel">
											<td class="hoga-ask">--,---</td>
											<td>---</td>
											<td>---</td>
										</tr>
										<tr class="hoga-skel">
											<td class="hoga-ask">--,---</td>
											<td>---</td>
											<td>---</td>
										</tr>
										<tr class="hoga-skel">
											<td class="hoga-ask">--,---</td>
											<td>---</td>
											<td>---</td>
										</tr>
										<tr class="hoga-skel">
											<td class="hoga-ask">--,---</td>
											<td>---</td>
											<td>---</td>
										</tr>
										<tr class="hoga-skel">
											<td class="hoga-ask">--,---</td>
											<td>---</td>
											<td>---</td>
										</tr>
									</tbody>
								</table>
							</div>
							<div class="hoga-mid" id="hoga-mid">
								<span id="hoga-cur-price">-</span> <span class="hoga-mid-change"
									id="hoga-cur-change"></span>
							</div>
							<div class="hoga-bot">
								<table class="hoga-table">
									<tbody id="hoga-bids">
										<tr class="hoga-skel">
											<td class="hoga-bid">--,---</td>
											<td>---</td>
											<td>---</td>
										</tr>
										<tr class="hoga-skel">
											<td class="hoga-bid">--,---</td>
											<td>---</td>
											<td>---</td>
										</tr>
										<tr class="hoga-skel">
											<td class="hoga-bid">--,---</td>
											<td>---</td>
											<td>---</td>
										</tr>
										<tr class="hoga-skel">
											<td class="hoga-bid">--,---</td>
											<td>---</td>
											<td>---</td>
										</tr>
										<tr class="hoga-skel">
											<td class="hoga-bid">--,---</td>
											<td>---</td>
											<td>---</td>
										</tr>
									</tbody>
								</table>
							</div>
						</div>
					</div>
				</div>

				<div class="resize-h" id="rh-2"></div>

				<!-- ③ 댓글 패널 -->
				<div class="card panel-chat" id="panel-chat">
					<div class="panel-title-row">
						<span class="panel-title">실시간 댓글</span>
						<div class="chat-sort-tabs">
							<button class="chat-sort-btn active" data-sort="latest">최신순</button>
							<button class="chat-sort-btn" data-sort="popular">인기순</button>
						</div>
					</div>
					<div class="chat-messages" id="chat-messages">
						<div class="chat-empty">
							<span class="chat-empty-icon">💬</span><span>첫 댓글을 남겨보세요</span>
						</div>
					</div>
					<div class="chat-view-all" id="community-view-all" role="link" tabindex="0">전체 보기 ›</div>
				</div>

			</div>
			<!-- /.main-layout -->

			<div class="ticker-bar">
				<div class="ticker-track" id="ticker-track"></div>
			</div>

		</div>
		<!-- /.page -->

		<%@ include file="../common/sidebar.jsp"%>
		<%@ include file="../common/sidebar-icons.jsp"%>

	</div>
	<!-- /.app-wrapper -->


	<script src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
	<script src="https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js"></script>
	<script src="/js/market/market-common.js"></script>
	<script src="/js/market/stock/stock.js"></script>
	<script src="/js/common.js" defer></script>
	<script src="/js/sidebar-data.js" defer></script>

</body>
</html>
