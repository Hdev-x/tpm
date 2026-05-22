<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>TradeBot · 마이페이지</title>
<link rel="stylesheet"
	href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
<link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/member/member.css">

<style>
.asset-container {
	width: 100%;
	max-width: 900px;
	margin: 40px auto;
	display: flex;
	flex-direction: column;
	gap: 40px;
}

.asset-section-card {
	padding: 30px;
	background: var(--bg);
	border: 1px solid var(--border);
	border-radius: 20px;
	box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
}

.section-header {
	margin-bottom: 24px;
	display: flex;
	justify-content: space-between;
	align-items: center;
}

.section-header h2 {
	font-size: 22px;
	font-weight: 700;
	display: flex;
	align-items: center;
	gap: 10px;
}

.summary-grid {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
	gap: 16px;
	margin-bottom: 24px;
}

.summary-item {
	background: var(--surface);
	padding: 16px;
	border-radius: 12px;
	border: 1px solid var(--border2);
}

.summary-label {
	font-size: 12px;
	color: var(--text3);
	margin-bottom: 6px;
}

.summary-value {
	font-size: 18px;
	font-weight: 800;
	color: var(--text);
}

.asset-table {
	width: 100%;
	border-collapse: collapse;
}

.asset-table th {
	padding: 12px;
	text-align: left;
	color: var(--text3);
	font-size: 13px;
	border-bottom: 1px solid var(--border);
}

.asset-table td {
	padding: 16px 12px;
	font-size: 15px;
	border-bottom: 1px solid rgba(255, 255, 255, 0.03);
}

.val-rate {
	font-weight: 700;
}

.val-rate.up {
	color: var(--up);
}

.val-rate.down {
	color: var(--down);
}

.badge-stock {
	color: var(--blue);
}

.badge-coin {
	color: #8B5CF6;
}
</style>
</head>
<body>

	<div class="app-wrapper">
		<div class="page">
			<%@ include file="/WEB-INF/views/common/nav.jsp"%>

			<div class="main-content"
				style="flex: 1; overflow-y: auto; padding: 0 20px;">
				<div class="asset-container">

					<div class="asset-section-card"
						style="background: linear-gradient(135deg, rgba(49, 130, 246, 0.1) 0%, rgba(139, 92, 246, 0.1) 100%); border: 1px solid var(--border);">
						<div class="section-header" style="margin-bottom: 16px;">
							<h2 style="font-size: 24px;">💰 내 모든 자산</h2>
							<span style="font-size: 12px; color: var(--text3);">KRW 통합
								기준 (예수금/투자금 포함)</span>
						</div>
						<div class="summary-grid"
							style="grid-template-columns: repeat(3, 1fr); margin-bottom: 0;">
							<div class="summary-item"
								style="background: transparent; border: none; padding: 0;">
								<div class="summary-label" style="font-size: 14px;">총 보유
									자산</div>
								<div class="summary-value" id="grand-total-asset"
									style="font-size: 28px;">0원</div>
							</div>
							<div class="summary-item"
								style="background: transparent; border: none; padding: 0;">
								<div class="summary-label" style="font-size: 14px;">통합
									평가손익</div>
								<div class="summary-value" id="grand-total-pnl"
									style="font-size: 28px;">0원</div>
							</div>
							<div class="summary-item"
								style="background: transparent; border: none; padding: 0;">
								<div class="summary-label" style="font-size: 14px;">통합 수익률</div>
								<div class="summary-value" id="grand-total-rate"
									style="font-size: 28px;">0.00%</div>
							</div>
						</div>
					</div>

					<div class="asset-section-card">
						<div class="section-header">
							<h2 class="badge-stock">📈 주식 포트폴리오</h2>
							<span style="font-size: 12px; color: var(--text3);">KRW 기준</span>
						</div>
						<div class="summary-grid" id="stockSummary">
							<div class="summary-item">
								<div class="summary-label">총 평가금액</div>
								<div class="summary-value" id="s-total-eval">0원</div>
								<div id="s-cash-hint" style="font-size: 12px; color: var(--text3); margin-top: 4px;">예수금 0원 포함</div>
							</div>
							<div class="summary-item">
								<div class="summary-label">총 손익</div>
								<div class="summary-value" id="s-total-pnl">0원</div>
							</div>
							<div class="summary-item">
								<div class="summary-label">수익률</div>
								<div class="summary-value" id="s-total-rate">0.00%</div>
							</div>
						</div>
						<div style="max-height: 380px; overflow-y: auto; scrollbar-width: none;">
						<table class="asset-table">
							<thead style="position: sticky; top: 0; background: var(--bg); z-index: 1;">
								<tr>
									<th>종목명</th>
									<th style="text-align: right;">수량</th>
									<th style="text-align: right;">평단가</th>
									<th style="text-align: right;">평가액</th>
									<th style="text-align: right;">수익률</th>
								</tr>
							</thead>
							<tbody id="stockTableBody"></tbody>
						</table>
						</div>
					</div>

					<div class="asset-section-card">
						<div class="section-header">
							<h2 class="badge-coin">₿ 코인 포트폴리오</h2>
							<div style="display:flex; align-items:center; gap:10px;">
								<span id="coin-currency-label" style="font-size: 12px; color: var(--text3);">USDT 기준</span>
								<div class="cur-switch" id="asset-cur-switch"
									onclick="setCurrency(currencyMode === 'usd' ? 'krw' : 'usd'); updateAsset();">
									<span class="cur-switch-label">$</span>
									<span class="cur-switch-label">원</span>
									<div class="cur-switch-thumb"></div>
								</div>
							</div>
						</div>
						<div class="summary-grid" id="coinSummary">
							<div class="summary-item">
								<div class="summary-label">총 평가금액</div>
								<div class="summary-value" id="c-total-eval">0 USDT</div>
								<div id="c-cash-hint" style="font-size: 12px; color: var(--text3); margin-top: 4px;">가용 잔고 0 USDT 포함</div>
							</div>
							<div class="summary-item">
								<div class="summary-label">총 손익</div>
								<div class="summary-value" id="c-total-pnl">0 USDT</div>
							</div>
							<div class="summary-item">
								<div class="summary-label">수익률</div>
								<div class="summary-value" id="c-total-rate">0.00%</div>
							</div>
						</div>
						<div style="max-height: 380px; overflow-y: auto; scrollbar-width: none;">
						<table class="asset-table">
							<thead style="position: sticky; top: 0; background: var(--bg); z-index: 1;">
								<tr>
									<th>코인명</th>
									<th style="text-align: right;">수량</th>
									<th style="text-align: right;">평단가</th>
									<th style="text-align: right;">평가액</th>
									<th style="text-align: right;">수익률</th>
								</tr>
							</thead>
							<tbody id="coinTableBody"></tbody>
						</table>
						</div>
					</div>

					<div style="display: flex; gap: 12px; margin-bottom: 60px;">
						<button onclick="history.back()"
							style="flex:1; padding:14px; border-radius:12px; border:1px solid var(--border); background:transparent; color:var(--text); font-size:15px; font-weight:600; cursor:pointer; transition:background .15s;"
							onmouseover="this.style.background='var(--surface)'" onmouseout="this.style.background='transparent'">
							← 뒤로가기
						</button>
						<button onclick="location.href='/'"
							style="flex:1; padding:14px; border-radius:12px; border:none; background:var(--blue); color:#fff; font-size:15px; font-weight:700; cursor:pointer; transition:opacity .15s;"
							onmouseover="this.style.opacity='.85'" onmouseout="this.style.opacity='1'">
							🏠 메인으로
						</button>
					</div>

				</div>
			</div>
		</div>
		<%@ include file="/WEB-INF/views/common/sidebar.jsp"%>
		<%@ include file="/WEB-INF/views/common/sidebar-icons.jsp"%>
	</div>

	<script src="/js/common.js" defer></script>
	<script src="/js/sidebar-data.js" defer></script>
	<script>
async function updateAsset() {
    const EXCHANGE_RATE = (typeof usdToKrw !== 'undefined' && usdToKrw > 1) ? usdToKrw : 1400;
    const isKrw = (typeof currencyMode !== 'undefined') && currencyMode === 'krw';

    // asset-cur-switch 토글 상태 동기화
    const assetSwitch = document.getElementById('asset-cur-switch');
    if (assetSwitch) assetSwitch.classList.toggle('krw', isKrw);
    const currLabel = document.getElementById('coin-currency-label');
    if (currLabel) currLabel.textContent = isKrw ? 'KRW 기준' : 'USDT 기준';

    try {
        const res = await fetch('/stock/asset-detail-data');
        if (!res.ok) return;
        const data = await res.json();
        if (!data || !Array.isArray(data)) return;

        const stockWalletRes = await fetch('/stock/account-balance').then(r => r.ok ? r.json() : { balance: 0 });
        const coinWalletRes = await fetch('/coin/wallet').then(r => r.ok ? r.json() : { usdtBalance: 0 });

        const stockCash = stockWalletRes ? (stockWalletRes.balance || 0) : 0;
        const coinCash = coinWalletRes ? (coinWalletRes.usdtBalance || 0) : 0;

        // 1. 코인 라이브 시세 가져오기
        const coinItems = data.filter(item => item && item.type === 'coin');
        const coinTickers = coinItems.map(item => (item.name || '') + 'USDT');
        let livePrices = {};

        if (coinTickers.length > 0) {
            const tickerRes = await fetch('/coin/api/tickers').then(r => r.ok ? r.json() : null);
            if (tickerRes && tickerRes.data && Array.isArray(tickerRes.data)) {
                tickerRes.data.forEach(t => {
                    if(t && coinTickers.includes(t.symbol)) {
                        livePrices[t.symbol] = parseFloat(t.lastPr) || 0;
                    }
                });
            }
        }

        // 2. 주식 렌더링 & 요약
        const stockItems = data.filter(item => item && item.type === 'stock');
        let sEval = 0, sBuy = 0;

        const stockTableBody = document.getElementById('stockTableBody');
        if (stockTableBody) {
            stockTableBody.innerHTML = stockItems.map(item => {
                const count = parseFloat(item.count) || 0;
                const buyPrice = parseFloat(item.buyPrice) || 0;
                const buy = buyPrice * count;
                const evalVal = parseFloat(item.eval) || buy;
                sEval += evalVal;
                sBuy += buy;
                const r = parseFloat(item.rate) || 0;
                return `<tr>
                    <td><b>\${item.name || '알 수 없는 종목'}</b></td>
                    <td style="text-align:right;">\${Number(count).toLocaleString()}주</td>
                    <td style="text-align:right;">\${Number(buyPrice).toLocaleString()}원</td>
                    <td style="text-align:right; font-weight:600;">\${Number(evalVal).toLocaleString()}원</td>
                    <td style="text-align:right;" class="val-rate \${r > 0 ? 'up' : r < 0 ? 'down' : ''}">\${r > 0 ? '+' : ''}\${r.toFixed(2)}%</td>
                </tr>`;
            }).join('') || '<tr><td colspan="5" style="text-align:center; padding:40px; color:var(--text3);">보유 주식이 없습니다.</td></tr>';
        }

        const sPnl = sEval - sBuy;
        const sRate = sBuy > 0 ? (sPnl / sBuy * 100) : 0;

        if(document.getElementById('s-total-eval')) document.getElementById('s-total-eval').textContent = Math.floor(stockCash + sEval).toLocaleString() + '원';
        if(document.getElementById('s-cash-hint')) document.getElementById('s-cash-hint').textContent = '예수금 ' + Math.floor(stockCash).toLocaleString() + '원 포함';

        const sPnlEl = document.getElementById('s-total-pnl');
        if (sPnlEl) {
            sPnlEl.textContent = (sPnl >= 0 ? '+' : '') + Math.floor(sPnl).toLocaleString() + '원';
            sPnlEl.className = 'summary-value ' + (sPnl > 0 ? 'up' : sPnl < 0 ? 'down' : '');
        }

        const sRateEl = document.getElementById('s-total-rate');
        if (sRateEl) {
            sRateEl.textContent = (sRate >= 0 ? '+' : '') + sRate.toFixed(2) + '%';
            sRateEl.className = 'summary-value ' + (sRate > 0 ? 'up' : sRate < 0 ? 'down' : '');
        }

        // 3. 코인 렌더링 & 요약 (currencyMode에 따라 USDT / KRW 전환)
        let cEval = 0, cBuy = 0;

        const coinTableBody = document.getElementById('coinTableBody');
        if (coinTableBody) {
            coinTableBody.innerHTML = coinItems.map(item => {
                const coinName = item.name || '';
                const ticker = coinName + 'USDT';
                const count = parseFloat(item.count) || 0;
                const buyPrice = parseFloat(item.buyPrice) || 0;
                const curPrice = livePrices[ticker] || buyPrice;
                const buy = buyPrice * count;
                const evalVal = curPrice * count;
                cEval += evalVal;
                cBuy += buy;
                const r = buy > 0 ? ((evalVal - buy) / buy * 100) : 0;

                if (isKrw) {
                    return `<tr>
                        <td><b>\${coinName}</b></td>
                        <td style="text-align:right;">\${count.toFixed(4)}</td>
                        <td style="text-align:right;">\${Math.floor(buyPrice * EXCHANGE_RATE).toLocaleString()}원</td>
                        <td style="text-align:right; font-weight:600;">\${Math.floor(evalVal * EXCHANGE_RATE).toLocaleString()}원</td>
                        <td style="text-align:right;" class="val-rate \${r > 0 ? 'up' : r < 0 ? 'down' : ''}">\${r > 0 ? '+' : ''}\${r.toFixed(2)}%</td>
                    </tr>`;
                } else {
                    return `<tr>
                        <td><b>\${coinName}</b></td>
                        <td style="text-align:right;">\${count.toFixed(4)}</td>
                        <td style="text-align:right;">$\${buyPrice.toLocaleString(undefined, {maximumFractionDigits: 4})}</td>
                        <td style="text-align:right; font-weight:600;">$\${evalVal.toLocaleString(undefined, {maximumFractionDigits:2})}</td>
                        <td style="text-align:right;" class="val-rate \${r > 0 ? 'up' : r < 0 ? 'down' : ''}">\${r > 0 ? '+' : ''}\${r.toFixed(2)}%</td>
                    </tr>`;
                }
            }).join('') || '<tr><td colspan="5" style="text-align:center; padding:40px; color:var(--text3);">보유 코인이 없습니다.</td></tr>';
        }

        const cPnl = cEval - cBuy;
        const cRate = cBuy > 0 ? (cPnl / cBuy * 100) : 0;

        if (isKrw) {
            if(document.getElementById('c-total-eval')) document.getElementById('c-total-eval').textContent = Math.floor((coinCash + cEval) * EXCHANGE_RATE).toLocaleString() + '원';
            if(document.getElementById('c-cash-hint')) document.getElementById('c-cash-hint').textContent = '가용 잔고 ' + Math.floor(coinCash * EXCHANGE_RATE).toLocaleString() + '원 포함';
            const cPnlEl = document.getElementById('c-total-pnl');
            if (cPnlEl) {
                const cPnlKrw = Math.floor(cPnl * EXCHANGE_RATE);
                cPnlEl.textContent = (cPnlKrw >= 0 ? '+' : '') + cPnlKrw.toLocaleString() + '원';
                cPnlEl.className = 'summary-value ' + (cPnl > 0 ? 'up' : cPnl < 0 ? 'down' : '');
            }
        } else {
            if(document.getElementById('c-total-eval')) document.getElementById('c-total-eval').textContent = (coinCash + cEval).toLocaleString(undefined,{maximumFractionDigits:2}) + ' USDT';
            if(document.getElementById('c-cash-hint')) document.getElementById('c-cash-hint').textContent = '가용 잔고 ' + Number(coinCash).toLocaleString(undefined,{maximumFractionDigits:2}) + ' USDT 포함';
            const cPnlEl = document.getElementById('c-total-pnl');
            if (cPnlEl) {
                cPnlEl.textContent = (cPnl >= 0 ? '+' : '') + cPnl.toFixed(2) + ' USDT';
                cPnlEl.className = 'summary-value ' + (cPnl > 0 ? 'up' : cPnl < 0 ? 'down' : '');
            }
        }

        const cRateEl = document.getElementById('c-total-rate');
        if (cRateEl) {
            cRateEl.textContent = (cRate >= 0 ? '+' : '') + cRate.toFixed(2) + '%';
            cRateEl.className = 'summary-value ' + (cRate > 0 ? 'up' : cRate < 0 ? 'down' : '');
        }

        // 4. 통합 자산 — 백엔드와 동일한 소스(/stock/my-asset)로 총액 표시
        const myAssetRes = await fetch('/stock/my-asset').then(r => r.ok ? r.json() : null);
        const grandTotalAsset = myAssetRes !== null ? myAssetRes
                                                    : (stockCash + sEval) + ((coinCash + cEval) * EXCHANGE_RATE);

        // P&L / 수익률은 보유 종목 기준으로 계산
        const grandTotalPrincipal = (stockCash + sBuy) + ((coinCash + cBuy) * EXCHANGE_RATE);
        const grandTotalPnl = grandTotalAsset - grandTotalPrincipal;
        const grandTotalRate = grandTotalPrincipal > 0 ? (grandTotalPnl / grandTotalPrincipal) * 100 : 0;

        if(document.getElementById('grand-total-asset')) document.getElementById('grand-total-asset').textContent = Math.floor(grandTotalAsset).toLocaleString() + '원';

        const gPnlEl = document.getElementById('grand-total-pnl');
        if (gPnlEl) {
            gPnlEl.textContent = (grandTotalPnl >= 0 ? '+' : '') + Math.floor(grandTotalPnl).toLocaleString() + '원';
            gPnlEl.className = 'summary-value ' + (grandTotalPnl > 0 ? 'up' : grandTotalPnl < 0 ? 'down' : '');
        }

        const gRateEl = document.getElementById('grand-total-rate');
        if (gRateEl) {
            gRateEl.textContent = (grandTotalRate >= 0 ? '+' : '') + grandTotalRate.toFixed(2) + '%';
            gRateEl.className = 'summary-value ' + (grandTotalRate > 0 ? 'up' : grandTotalRate < 0 ? 'down' : '');
        }

    } catch (e) {
        console.error("자산 실시간 업데이트 중 예외 발생:", e);
    }
}

// 초기화 실행 및 10초 주기 폴링 설정
document.addEventListener('DOMContentLoaded', () => {
    // asset-cur-switch 초기 상태 동기화 (localStorage 기준)
    const initMode = localStorage.getItem('currencyMode') || 'usd';
    const assetSwitch = document.getElementById('asset-cur-switch');
    if (assetSwitch) assetSwitch.classList.toggle('krw', initMode === 'krw');

    updateAsset();
    setInterval(updateAsset, 10000);
});
</script>
</body>
</html>