/* =====================================================
   common.js
   모든 페이지에서 공통으로 사용하는 JS
   nav, sidebar 관련 함수 등
   ===================================================== */

/* ====================================================
   달러 / 원 통화 토글
   ==================================================== */
let currencyMode = localStorage.getItem('currencyMode') || 'usd';
let usdToKrw = 1;

async function fetchExchangeRate() {
    try {
        const res = await fetch('https://open.er-api.com/v6/latest/USD').then(r => r.json());
        if (res && res.rates && res.rates.KRW) usdToKrw = res.rates.KRW;
    } catch (e) { }
}

function setCurrency(mode) {
    if (currencyMode === mode) return;
    currencyMode = mode;
    localStorage.setItem('currencyMode', mode);
    document.getElementById('cur-switch')?.classList.toggle('krw', mode === 'krw');
    renderWatchlistCoins('watchlist-coin-list', watchlistCoins);
    renderWatchlistCoins('watchlist-coin-all-list', watchlistCoins);
    renderRecentCoins(recentCoins);
}

function fmtCoinPrice(price) {
    if (currencyMode === 'krw') {
        const krw = price * usdToKrw;
        return krw.toLocaleString(undefined, { maximumFractionDigits: 0 }) + '원';
    }
    return '$' + price.toLocaleString(undefined, { maximumFractionDigits: 2 });
}

function fmtCoinChange(price, change) {
    if (change === null) return '-';
    const sign = change >= 0 ? '+' : '';
    const changeAmt = price - price / (1 + change / 100);
    if (currencyMode === 'krw') {
        const krwAmt = changeAmt * usdToKrw;
        return sign + krwAmt.toLocaleString(undefined, { maximumFractionDigits: 0 }) + '원 (' + sign + change.toFixed(2) + '%)';
    }
    return sign + '$' + Math.abs(changeAmt).toFixed(2) + ' (' + sign + change.toFixed(2) + '%)';
}

function fmtNum(n) {
    if (n >= 1_000_000_000) return (n / 1_000_000_000).toFixed(2) + 'B';
    if (n >= 1_000_000) return (n / 1_000_000).toFixed(2) + 'M';
    if (n >= 1_000) return (n / 1_000).toFixed(2) + 'K';
    return n.toFixed(2);
}


/* ====================================================
   사이드바 슬라이드 토글
   ==================================================== */
const SIDEBAR_TITLES = { invest: '내 투자현황', interest: '관심 종목', recent: '최근 본', live: '실시간' };
let sidebarActiveTab = null;
let lastSidebarTab = null;
let sidebarReady = false;

function toggleSidebar(tab) {
    const panel = document.getElementById('sidebar-panel');
    if (sidebarActiveTab === tab) { closeSidebar(); return; }

    const prevSection = sidebarActiveTab ? document.getElementById('sidebar-' + sidebarActiveTab) : null;
    sidebarActiveTab = tab;
    panel.classList.add('open');
    document.querySelectorAll('.si-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('si-' + tab).classList.add('active');
    document.getElementById('sidebar-title').textContent = SIDEBAR_TITLES[tab] || tab;
    const subTitle = document.getElementById('sidebar-title-sub');
    if (subTitle) {
        if (tab === 'live') {
            const now = new Date();
            const hh = String(now.getHours()).padStart(2, '0');
            const mm = String(now.getMinutes()).padStart(2, '0');
            subTitle.textContent = '오늘 ' + hh + ':' + mm + ' 기준';
            subTitle.style.display = '';
        } else {
            subTitle.style.display = 'none';
        }
    }
    localStorage.setItem('sidebar', tab);

    document.getElementById('si-fold-btn')?.classList.remove('folded');
    const curSwitch = document.getElementById('cur-switch');
    if (curSwitch) curSwitch.style.display = tab === 'invest' ? 'none' : '';
    const nextSection = document.getElementById('sidebar-' + tab);

    document.querySelectorAll('.sidebar-section').forEach(s => {
        s.style.display = 'none';
        s.classList.remove('sb-entering');
    });

    nextSection.style.display = '';

    if (tab === 'interest') {
        const firstTab = nextSection.querySelector('.si-type-tab');
        if (firstTab) switchInterestTab(firstTab, 'all');
    }
    if (tab === 'recent') {
        const firstTab = nextSection.querySelector('.si-type-tab');
        if (firstTab) switchRecentTab(firstTab, 'all');
    }

    if (sidebarReady) {
        void nextSection.offsetWidth;
        nextSection.classList.add('sb-entering');
        setTimeout(() => nextSection.classList.remove('sb-entering'), 200);
    }
}

function closeSidebar() {
    lastSidebarTab = sidebarActiveTab;
    if (sidebarActiveTab) localStorage.setItem('lastSidebarTab', sidebarActiveTab);
    sidebarActiveTab = null;
    document.getElementById('sidebar-panel').classList.remove('open');
    document.querySelectorAll('.si-btn').forEach(b => b.classList.remove('active'));
    localStorage.removeItem('sidebar');
    document.getElementById('si-fold-btn')?.classList.add('folded');
}

function restoreSidebarNoAnim(tab) {
    const panel = document.getElementById('sidebar-panel');
    panel.style.transition = 'none';
    sidebarActiveTab = tab;
    panel.classList.add('open');
    document.querySelectorAll('.si-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('si-' + tab)?.classList.add('active');
    if (document.getElementById('sidebar-title'))
        document.getElementById('sidebar-title').textContent = SIDEBAR_TITLES[tab] || tab;
    const subTitle = document.getElementById('sidebar-title-sub');
    if (subTitle) subTitle.style.display = tab === 'live' ? '' : 'none';
    document.getElementById('si-fold-btn')?.classList.remove('folded');
    const curSwitch = document.getElementById('cur-switch');
    if (curSwitch) curSwitch.style.display = tab === 'invest' ? 'none' : '';
    document.querySelectorAll('.sidebar-section').forEach(s => s.style.display = 'none');
    const nextSection = document.getElementById('sidebar-' + tab);
    if (nextSection) nextSection.style.display = '';
    requestAnimationFrame(() => { panel.style.transition = ''; sidebarReady = true; });
}

function toggleFold() {
    const panel = document.getElementById('sidebar-panel');
    if (panel.classList.contains('open')) {
        closeSidebar();
    } else {
        const tab = lastSidebarTab || localStorage.getItem('lastSidebarTab') || localStorage.getItem('sidebar') || 'live';
        toggleSidebar(tab);
    }
}


/* ====================================================
   사이드바 탭 전환 (포지션 / 오더 / 기록)
   ==================================================== */
function swapInterestGroups() {
    const container = document.getElementById('si-all-container');
    const stock = document.getElementById('si-group-stock');
    const coin = document.getElementById('si-group-coin');
    if (stock.nextElementSibling === coin) {
        container.appendChild(stock);
        localStorage.setItem('interestGroupOrder', 'coin');
    } else {
        container.insertBefore(stock, coin);
        localStorage.setItem('interestGroupOrder', 'stock');
    }
}

function switchInterestTab(el, tab) {
    document.querySelectorAll('#sidebar-interest .si-type-tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    document.querySelectorAll('.si-tab-content').forEach(c => c.style.display = 'none');
    document.getElementById('interest-' + tab).style.display = '';
    localStorage.setItem('interestTab2', tab);

    const container = document.getElementById('si-all-container');
    const stock = document.getElementById('si-group-stock');
    const coin = document.getElementById('si-group-coin');
    if (!container || !stock || !coin) return;
    if (tab === 'coin' && container.firstElementChild !== coin) {
        container.insertBefore(coin, stock);
    } else if (tab === 'stock' && container.firstElementChild !== stock) {
        container.insertBefore(stock, coin);
    }
}

function switchInvestTab(el, tab) {
    el.closest('.si-type-tabs').querySelectorAll('.si-type-tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    ['stock', 'coin'].forEach(t => {
        const el = document.getElementById('invest-' + t);
        if (el) el.style.display = t === tab ? 'flex' : 'none';
    });
    localStorage.setItem('investTab', tab);
}

function switchBpTab(el, tab) {
    const tabsEl = el.closest('.sb-tabs');
    tabsEl.querySelectorAll('.sb-tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    tabsEl.querySelectorAll('.sb-tab').forEach(t => {
        const tid = t.getAttribute('onclick').match(/'([^']+)'/)[1];
        const panel = document.getElementById('tab-' + tid);
        if (panel) panel.style.display = tid === tab ? 'flex' : 'none';
    });
}


/* ====================================================
   보유 내역 로드 + 실시간 가격 WebSocket (모든 페이지)
   ==================================================== */
let holdingsData = [];
let holdingsWs = null;
let cachedPrices = JSON.parse(localStorage.getItem('holdingPrices') || '{}');

function skeletonCard() {
    return '<div class="holding-card hc-main skeleton-card">'
        + '<div class="hc-main-header">'
        + '<div class="hc-main-id">'
        + '<div class="hc-logo skeleton" style="background:transparent;"></div>'
        + '<div class="hc-main-name-col">'
        + '<span class="skeleton" style="width:70px;height:13px;display:block;"></span>'
        + '<span class="skeleton" style="width:90px;height:11px;display:block;margin-top:4px;"></span>'
        + '</div>'
        + '</div>'
        + '<div class="hc-main-right">'
        + '<span class="skeleton" style="width:80px;height:13px;display:block;"></span>'
        + '<span class="skeleton" style="width:100px;height:11px;display:block;margin-top:4px;"></span>'
        + '</div>'
        + '</div>'
        + '<div class="hc-divider"></div>'
        + '<div class="hc-main-grid">'
        + '<div class="hc-main-row"><span class="skeleton" style="width:50px;height:11px;"></span><span class="skeleton" style="width:60px;height:11px;"></span></div>'
        + '<div class="hc-main-row"><span class="skeleton" style="width:50px;height:11px;"></span><span class="skeleton" style="width:60px;height:11px;"></span></div>'
        + '<div class="hc-main-row"><span class="skeleton" style="width:50px;height:11px;"></span><span class="skeleton" style="width:60px;height:11px;"></span></div>'
        + '<div class="hc-main-row"><span class="skeleton" style="width:50px;height:11px;"></span><span class="skeleton" style="width:60px;height:11px;"></span></div>'
        + '</div>'
        + '</div>';
}

function coinLogoColor(code) {
    const colors = ['#F7931A', '#627EEA', '#00AAC1', '#E84142', '#2775CA', '#26A17B', '#9945FF', '#E6007A'];
    let h = 0;
    for (let i = 0; i < code.length; i++) h = (h * 31 + code.charCodeAt(i)) & 0xffff;
    return colors[h % colors.length];
}

function coinLogoHtml(ticker) {
    const fallback = ticker.slice(0, 3);
    const color = coinLogoColor(ticker);
    const url = 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/' + ticker.toLowerCase() + '.png';
    return '<div class="hc-logo hc-logo-wrap">'
        + '<img src="' + url + '" alt="' + ticker + '" class="hc-logo-img"'
        + ' onerror="this.parentElement.style.background=\'' + color + '\';this.parentElement.textContent=\'' + fallback + '\'">'
        + '</div>';
}

function renderHoldings(data) {
    const container = document.getElementById('bp-holdings-body');
    if (!container) return;

    if (data.length > 0) {
        document.getElementById('bp-empty').style.display = 'none';

        data.forEach(h => {
            const price = cachedPrices[h.coinCode] || null;
            const evalAmt = price !== null ? price * h.coinCount : null;
            const buyAmt = h.avgPrice * h.coinCount;
            const pnl = evalAmt !== null ? evalAmt - buyAmt : null;
            const pct = pnl !== null && buyAmt > 0 ? (pnl / buyAmt * 100) : null;
            const cls = pnl !== null ? (pnl >= 0 ? 'up' : 'down') : '';
            const sign = pnl !== null && pnl >= 0 ? '+' : '';
            const arrow = pnl !== null ? (pnl >= 0 ? '▲' : '▼') : '';

            let card = container.querySelector('[data-coin="' + h.coinCode + '"]');
            if (card) {
                if (price !== null) {
                    card.querySelector('.hc-main-eval').textContent = evalAmt.toLocaleString(undefined, { maximumFractionDigits: 2 }) + ' USDT';
                    const pnlEl = card.querySelector('.hc-main-pnl');
                    pnlEl.textContent = arrow + Math.abs(pnl).toFixed(2) + ' (' + sign + pct.toFixed(2) + '%)';
                    pnlEl.className = 'hc-main-pnl ' + cls;
                    card.querySelector('.hc-price-val').textContent = price.toLocaleString(undefined, { maximumFractionDigits: 6 });
                    card.querySelector('.hc-eval-val').textContent = (evalAmt !== null ? evalAmt.toLocaleString(undefined, { maximumFractionDigits: 2 }) : '-') + ' USDT';
                }
            } else {
                const ticker = h.coinCode.replace(/USDT$/, '').replace('_SPBL', '');
                const div = document.createElement('div');
                div.className = 'holding-card hc-main';
                div.dataset.coin = h.coinCode;
                div.style.cursor = 'pointer';
                div.onclick = () => location.href = '/coin/chart?symbol=' + h.coinCode;
                div.innerHTML =
                    '<div class="hc-main-header">'
                    + '<div class="hc-main-id">'
                    + coinLogoHtml(ticker)
                    + '<div class="hc-main-name-col">'
                    + '<span class="hc-main-ticker">' + ticker + '</span>'
                    + '<span class="hc-main-sub">' + ticker + '/USDT | ' + h.coinCount.toFixed(4) + '개</span>'
                    + '</div>'
                    + '</div>'
                    + '<div class="hc-main-right">'
                    + '<span class="hc-main-eval">' + (evalAmt !== null ? evalAmt.toLocaleString(undefined, { maximumFractionDigits: 2 }) : '-') + ' USDT</span>'
                    + '<span class="hc-main-pnl ' + cls + '">' + (pnl !== null ? arrow + Math.abs(pnl).toFixed(2) + ' (' + sign + pct.toFixed(2) + '%)' : '-') + '</span>'
                    + '</div>'
                    + '</div>'
                    + '<div class="hc-divider"></div>'
                    + '<div class="hc-main-grid">'
                    + '<div class="hc-main-row"><span class="hc-label">매수금액</span><span class="hc-value">' + buyAmt.toLocaleString(undefined, { maximumFractionDigits: 2 }) + ' USDT</span></div>'
                    + '<div class="hc-main-row"><span class="hc-label">평균단가</span><span class="hc-value">' + h.avgPrice.toLocaleString(undefined, { maximumFractionDigits: 6 }) + '</span></div>'
                    + '<div class="hc-main-row"><span class="hc-label">평가금액</span><span class="hc-value hc-eval-val">' + (evalAmt !== null ? evalAmt.toLocaleString(undefined, { maximumFractionDigits: 2 }) : '-') + ' USDT</span></div>'
                    + '<div class="hc-main-row"><span class="hc-label">현재가</span><span class="hc-value hc-price-val">' + (price !== null ? price.toLocaleString(undefined, { maximumFractionDigits: 6 }) : '-') + '</span></div>'
                    + '</div>';
                const skel = container.querySelector('.skeleton-card');
                if (skel) container.replaceChild(div, skel);
                else container.appendChild(div);
            }
        });
        container.querySelectorAll('.skeleton-card').forEach(r => r.remove());
    } else {
        document.getElementById('bp-empty').style.display = '';
        container.innerHTML = '';
    }
}

async function loadHoldings() {
    const tbody = document.getElementById('bp-holdings-body');
    if (!tbody) return;

    const cached = localStorage.getItem('holdings');
    if (cached) {
        /* 캐시 있으면 즉시 실제 데이터 표시 */
        holdingsData = JSON.parse(cached);
        renderHoldings(holdingsData);
        connectHoldingsWs();
    } else {
        /* 캐시 없으면 스켈레톤 표시 */
        document.getElementById('bp-empty').style.display = 'none';
        document.getElementById('bp-holdings-body').innerHTML = skeletonCard() + skeletonCard() + skeletonCard();
    }

    /* 서버에서 최신 데이터 fetch → 캐시 갱신 후 in-place 업데이트 */
    const res = await fetch('/coin/holdings?username=testuser').then(r => r.json());
    holdingsData = res || [];
    localStorage.setItem('holdings', JSON.stringify(holdingsData));
    renderHoldings(holdingsData);
    connectHoldingsWs();
}

async function loadOrders() {
    const container = document.getElementById('history-cards');
    if (!container) return;

    const res = await fetch('/coin/orders?username=testuser').then(r => r.json());
    const emptyEl = document.getElementById('history-empty');

    if (!res || res.length === 0) {
        emptyEl.style.display = '';
        return;
    }

    emptyEl.style.display = 'none';
    container.className = 'history-list';
    container.innerHTML = res.map(o => {
        const ticker = o.coinCode.replace(/USDT$/, '').replace('_SPBL', '');
        const typeLabel = o.orderType === 'BUY' ? '매수' : '매도';
        const typeCls = o.orderType === 'BUY' ? 'up' : 'down';
        const total = (o.orderPrice * o.orderCount).toLocaleString(undefined, {maximumFractionDigits: 2});
        const date = o.orderDate.slice(0, 16).replace('T', ' ');

        let rightHtml = '';
        if (o.orderType === 'SELL' && o.avgPrice) {
            const pnl = (o.orderPrice - o.avgPrice) * o.orderCount;
            const pct = (o.orderPrice - o.avgPrice) / o.avgPrice * 100;
            const pnlCls = pnl >= 0 ? 'up' : 'down';
            const sign = pnl >= 0 ? '+' : '';
            rightHtml = `<div class="hr-right">
                <span class="hr-total ${pnlCls}">${sign}${pnl.toFixed(2)} USDT</span>
                <span class="hr-pnl ${pnlCls}">${sign}${pct.toFixed(2)}%</span>
            </div>`;
        } else {
            rightHtml = `<div class="hr-right">
                <span class="hr-total">${total} USDT</span>
                <span class="hr-pnl ${typeCls}">${typeLabel}</span>
            </div>`;
        }

        const pnlDetailRow = (o.orderType === 'SELL' && o.avgPrice) ? `
            <div class="hr-detail-row">
                <span class="hr-dlabel">평균단가</span>
                <span class="hr-dvalue">${Number(o.avgPrice).toLocaleString(undefined, {maximumFractionDigits: 6})}</span>
            </div>
            <div class="hr-detail-row">
                <span class="hr-dlabel">총금액</span>
                <span class="hr-dvalue">${total} USDT</span>
            </div>` : `
            <div class="hr-detail-row">
                <span class="hr-dlabel">총금액</span>
                <span class="hr-dvalue">${total} USDT</span>
            </div>`;

        return `<div class="history-card hc-${o.orderType.toLowerCase()}" onclick="if(this.classList.contains('open')){this.classList.add('closing');this.classList.remove('open');setTimeout(()=>this.classList.remove('closing'),250);}else{this.classList.remove('closing');this.classList.add('open');}">
            <div class="hr-header">
                <div class="hr-left">
                    ${coinLogoHtml(ticker)}
                    <div class="hr-info">
                        <span class="hr-ticker">${ticker}</span>
                        <span class="hr-meta">${date} · ${typeLabel}</span>
                    </div>
                </div>
                ${rightHtml}
            </div>
            <div class="hr-detail">
                <div class="hr-detail-row">
                    <span class="hr-dlabel">체결가</span>
                    <span class="hr-dvalue">${Number(o.orderPrice).toLocaleString(undefined, {maximumFractionDigits: 6})}</span>
                </div>
                <div class="hr-detail-row">
                    <span class="hr-dlabel">수량</span>
                    <span class="hr-dvalue">${o.orderCount}</span>
                </div>
                ${pnlDetailRow}
            </div>
        </div>`;
    }).join('');
}


function connectHoldingsWs() {
    if (holdingsWs) holdingsWs.close();
    const ws = new WebSocket('wss://ws.bitget.com/v2/ws/public');
    holdingsWs = ws;

    ws.onopen = () => {
        const args = holdingsData.map(h => ({
            instType: 'SPOT', channel: 'ticker', instId: h.coinCode
        }));
        ws.send(JSON.stringify({ op: 'subscribe', args }));
        setInterval(() => ws.readyState === 1 && ws.send('ping'), 20000);
    };

    ws.onmessage = (event) => {
        if (event.data === 'pong') return;
        let msg;
        try { msg = JSON.parse(event.data); } catch { return; }
        if (!msg.data || !msg.arg || msg.arg.channel !== 'ticker') return;

        const coinCode = msg.arg.instId;
        const price = parseFloat(msg.data[0].lastPr);
        updateHoldingPrice(coinCode, price);
    };

    ws.onclose = () => {
        if (ws === holdingsWs && holdingsData.length > 0) setTimeout(connectHoldingsWs, 3000);
    };
}

function updateHoldingPrice(coinCode, price) {
    const card = document.querySelector('#bp-holdings-body [data-coin="' + coinCode + '"]');
    if (!card) return;
    const h = holdingsData.find(h => h.coinCode === coinCode);
    if (!h) return;

    const evalAmt = price * h.coinCount;
    const buyAmt = h.avgPrice * h.coinCount;
    const pnl = evalAmt - buyAmt;
    const pct = buyAmt > 0 ? (pnl / buyAmt * 100) : 0;
    const cls = pnl >= 0 ? 'up' : 'down';
    const sign = pnl >= 0 ? '+' : '';
    const arrow = pnl >= 0 ? '▲' : '▼';

    card.querySelector('.hc-main-eval').textContent = evalAmt.toLocaleString(undefined, { maximumFractionDigits: 2 }) + ' USDT';
    const pnlEl = card.querySelector('.hc-main-pnl');
    pnlEl.textContent = arrow + Math.abs(pnl).toFixed(2) + ' (' + sign + pct.toFixed(2) + '%)';
    pnlEl.className = 'hc-main-pnl ' + cls;
    card.querySelector('.hc-price-val').textContent = price.toLocaleString(undefined, { maximumFractionDigits: 6 });
    card.querySelector('.hc-eval-val').textContent = evalAmt.toLocaleString(undefined, { maximumFractionDigits: 2 }) + ' USDT';

    cachedPrices[coinCode] = price;
    localStorage.setItem('holdingPrices', JSON.stringify(cachedPrices));
}


/* ====================================================
   관심 종목 (Watchlist) - localStorage 기반
   ==================================================== */
let watchlistCoins = [];
let watchlistWs = null;
let watchlistPrices = JSON.parse(localStorage.getItem('watchlistPrices') || '{}');
let watchlistSort = '등록순';

/* ── 주식 관심종목 ── */
let watchlistStockPrices = JSON.parse(localStorage.getItem('watchlistStockPrices') || '{}');
let watchlistStockTimer = null;

function getStockWatchlist() {
    return JSON.parse(localStorage.getItem('stock_watchlist') || '[]');
}

function watchlistStockItemHtml(code) {
    const d = watchlistStockPrices[code] || {};
    const name = d.name || code;
    const price = d.price && d.price !== '-' ? Number(d.price).toLocaleString() + '원' : '-';
    const n = parseFloat(d.rate);
    const cls = isNaN(n) ? '' : (n > 0 ? 'up' : n < 0 ? 'down' : '');
    const rateText = isNaN(n) ? '-' : (n > 0 ? '+' : '') + n.toFixed(2) + '%';
    const initials = (name || '  ').slice(0, 2);
    return '<div class="si-stock-item" data-watchlist-stock="' + code + '" onclick="location.href=\'/stock/chart?code=' + code + '\'">'
        + '<div class="si-logo" style="overflow:hidden;cursor:pointer;">'
        + '<img src="https://file.alphasquare.co.kr/media/images/stock_logo/kr/' + code + '.png"'
        + ' style="width:100%;height:100%;object-fit:contain;"'
        + ' onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'\';">'
        + '<span style="display:none;font-size:9px;font-weight:700;color:#fff;">' + initials + '</span>'
        + '</div>'
        + '<span class="si-stock-name">' + name + '</span>'
        + '<div class="si-stock-price">'
        + '<span class="si-price">' + price + '</span>'
        + '<span class="si-change ' + cls + '">' + rateText + '</span>'
        + '</div>'
        + '<button class="si-heart active" onclick="event.stopPropagation();toggleStockWatchlistSidebar(\'' + code + '\')">' + HEART_SVG + '</button>'
        + '</div>';
}

function renderWatchlistStocks() {
    const list = getStockWatchlist();
    ['watchlist-stock-list', 'watchlist-stock-all-list'].forEach(listId => {
        const el = document.getElementById(listId);
        if (!el) return;
        el.innerHTML = list.length === 0
            ? '<div class="si-wl-empty">관심 주식이 없습니다</div>'
            : list.map(watchlistStockItemHtml).join('');
    });
}

async function loadWatchlistStocks() {
    const list = getStockWatchlist();
    if (list.length === 0) { clearInterval(watchlistStockTimer); watchlistStockTimer = null; renderWatchlistStocks(); return; }

    renderWatchlistStocks();

    for (const code of list) {
        const cached = sidebarStockMap[code];
        if (cached && cached.price !== '-') {
            watchlistStockPrices[code] = { name: cached.name, price: cached.price, rate: cached.rate, diff: cached.diff };
        } else {
            try {
                const res = await fetch('/stock/ticker?code=' + code).then(r => r.json());
                if (res.output) {
                    watchlistStockPrices[code] = {
                        name: res.output.hts_kor_isnm || code,
                        price: res.output.stck_prpr,
                        rate: res.output.prdy_ctrt,
                        diff: res.output.prdy_vrss
                    };
                }
            } catch (e) {}
        }
    }
    localStorage.setItem('watchlistStockPrices', JSON.stringify(watchlistStockPrices));
    renderWatchlistStocks();

    clearInterval(watchlistStockTimer);
    watchlistStockTimer = setInterval(loadWatchlistStocks, 30000);
}

function updateStockWatchlistHeartBtn(code, inList) {
    const rowBtn = document.querySelector('#stockTableBody tr[data-code="' + code + '"] .like-btn');
    if (rowBtn) rowBtn.classList.toggle('liked', inList);
    const detailBtn = document.getElementById('detail-watchlist-btn');
    if (detailBtn && typeof currentDetailCode !== 'undefined' && currentDetailCode === code) {
        detailBtn.classList.toggle('active', inList);
    }
}

function toggleStockWatchlistSidebar(code) {
    let list = getStockWatchlist();
    const idx = list.indexOf(code);
    if (idx >= 0) {
        // 제거: 애니메이션 후 DOM 제거
        list.splice(idx, 1);
        localStorage.setItem('stock_watchlist', JSON.stringify(list));
        let pending = 0;
        ['watchlist-stock-list', 'watchlist-stock-all-list'].forEach(listId => {
            const item = document.querySelector('#' + listId + ' [data-watchlist-stock="' + code + '"]');
            if (!item) return;
            pending++;
            animateRemoveItem(item, () => {
                item.remove();
                pending--;
                if (pending === 0) {
                    ['watchlist-stock-list', 'watchlist-stock-all-list'].forEach(id => {
                        const el = document.getElementById(id);
                        if (el && el.querySelectorAll('.si-stock-item').length === 0) {
                            el.innerHTML = '<div class="si-wl-empty">관심 주식이 없습니다</div>';
                        }
                    });
                }
            });
        });
        delete watchlistStockPrices[code];
        localStorage.setItem('watchlistStockPrices', JSON.stringify(watchlistStockPrices));
        updateStockWatchlistHeartBtn(code, false);
    } else {
        // 추가: interest 탭 오픈 + DOM 즉시 append
        list.push(code);
        localStorage.setItem('stock_watchlist', JSON.stringify(list));
        if (sidebarActiveTab !== 'interest') toggleSidebar('interest');
        ['watchlist-stock-list', 'watchlist-stock-all-list'].forEach(listId => {
            const el = document.getElementById(listId);
            if (!el) return;
            const empty = el.querySelector('.si-wl-empty');
            if (empty) empty.remove();
            const div = document.createElement('div');
            div.innerHTML = watchlistStockItemHtml(code);
            el.append(div.firstElementChild);
        });
        // 가격 데이터 로딩
        const cached = sidebarStockMap[code];
        if (cached && cached.price !== '-') {
            watchlistStockPrices[code] = { ...cached };
            localStorage.setItem('watchlistStockPrices', JSON.stringify(watchlistStockPrices));
            renderWatchlistStocks();
        } else {
            fetch('/stock/ticker?code=' + code).then(r => r.json()).then(res => {
                if (res.output) {
                    watchlistStockPrices[code] = {
                        name: res.output.hts_kor_isnm || code,
                        price: res.output.stck_prpr,
                        rate: res.output.prdy_ctrt,
                        diff: res.output.prdy_vrss
                    };
                    localStorage.setItem('watchlistStockPrices', JSON.stringify(watchlistStockPrices));
                    renderWatchlistStocks();
                }
            }).catch(() => {});
        }
        updateStockWatchlistHeartBtn(code, true);
    }
}

/* ── 최근 본 주식 ── */
let recentStockPrices = JSON.parse(localStorage.getItem('recentStockPrices') || '{}');

function recentStockItemHtml(code) {
    const d = recentStockPrices[code] || {};
    const name = d.name || code;
    const price = d.price && d.price !== '-' ? Number(d.price).toLocaleString() + '원' : '-';
    const n = parseFloat(d.rate);
    const cls = isNaN(n) ? '' : (n > 0 ? 'up' : n < 0 ? 'down' : '');
    const rateText = isNaN(n) ? '-' : (n > 0 ? '+' : '') + n.toFixed(2) + '%';
    const initials = (name || '  ').slice(0, 2);
    return '<div class="si-stock-item" data-recent="' + code + '" onclick="location.href=\'/stock/chart?code=' + code + '\'">'
        + '<div class="si-logo" style="overflow:hidden;cursor:pointer;">'
        + '<img src="https://file.alphasquare.co.kr/media/images/stock_logo/kr/' + code + '.png"'
        + ' style="width:100%;height:100%;object-fit:contain;"'
        + ' onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'\';">'
        + '<span style="display:none;font-size:9px;font-weight:700;color:#fff;">' + initials + '</span>'
        + '</div>'
        + '<span class="si-stock-name">' + name + '</span>'
        + '<div class="si-stock-price">'
        + '<span class="si-price">' + price + '</span>'
        + '<span class="si-change ' + cls + '">' + rateText + '</span>'
        + '</div>'
        + '<button onclick="event.stopPropagation();removeFromRecent(\'' + code + '\')" style="background:none;border:none;color:var(--text3);font-size:14px;cursor:pointer;padding:4px;flex-shrink:0;">✕</button>'
        + '</div>';
}

async function loadRecentStocks(stockList) {
    for (const code of stockList) {
        const cached = sidebarStockMap[code];
        if (cached && cached.price !== '-') {
            recentStockPrices[code] = { name: cached.name, price: cached.price, rate: cached.rate };
        } else {
            try {
                const res = await fetch('/stock/ticker?code=' + code).then(r => r.json());
                if (res.output) {
                    recentStockPrices[code] = {
                        name: res.output.hts_kor_isnm || code,
                        price: res.output.stck_prpr,
                        rate: res.output.prdy_ctrt
                    };
                }
            } catch (e) {}
        }
    }
    localStorage.setItem('recentStockPrices', JSON.stringify(recentStockPrices));
}

const WATCHLIST_SORT_FNS = {
    '등록순':     (a, b) => 0,
    '이름순':     (a, b) => a.localeCompare(b),
    '등락률 높은순': (a, b) => (watchlistPrices[b]?.change ?? -Infinity) - (watchlistPrices[a]?.change ?? -Infinity),
    '등락률 낮은순': (a, b) => (watchlistPrices[a]?.change ?? Infinity)  - (watchlistPrices[b]?.change ?? Infinity),
    '가격 높은순':  (a, b) => (watchlistPrices[b]?.price ?? 0) - (watchlistPrices[a]?.price ?? 0),
    '가격 낮은순':  (a, b) => (watchlistPrices[a]?.price ?? 0) - (watchlistPrices[b]?.price ?? 0),
};

const HEART_SVG = '<svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>';

function getWatchlist() {
    return JSON.parse(localStorage.getItem('watchlist') || '[]');
}

function animateRemoveItem(item, onDone) {
    const h = item.offsetHeight;
    item.style.overflow = 'hidden';
    item.style.height = h + 'px';
    item.style.transition = 'height 0.28s ease, opacity 0.18s ease, padding 0.28s ease';
    item.style.pointerEvents = 'none';
    requestAnimationFrame(() => {
        item.style.opacity = '0';
        item.style.height = '0';
        item.style.paddingTop = '0';
        item.style.paddingBottom = '0';
    });
    setTimeout(onDone, 300);
}

function toggleWatchlist(symbol) {
    let list = getWatchlist();
    const idx = list.indexOf(symbol);
    if (idx >= 0) {
        list.splice(idx, 1);
        localStorage.setItem('watchlist', JSON.stringify(list));
        watchlistCoins = list;
        updateWatchlistHeartBtn(symbol);

        let pending = 0;
        ['watchlist-coin-list', 'watchlist-coin-all-list'].forEach(listId => {
            const item = document.querySelector('#' + listId + ' [data-watchlist="' + symbol + '"]');
            if (!item) return;
            pending++;
            animateRemoveItem(item, () => {
                item.remove();
                pending--;
                if (pending === 0) {
                    const lists = ['watchlist-coin-list', 'watchlist-coin-all-list'];
                    lists.forEach(id => {
                        const el = document.getElementById(id);
                        if (el && el.children.length === 0) renderWatchlistCoins(id, []);
                    });
                    if (watchlistWs) { watchlistWs.close(); watchlistWs = null; }
                    connectWatchlistWs();
                }
            });
        });
    } else {
        list.push(symbol);
        localStorage.setItem('watchlist', JSON.stringify(list));
        watchlistCoins = list;
        updateWatchlistHeartBtn(symbol);
        if (sidebarActiveTab !== 'interest') toggleSidebar('interest');
        ['watchlist-coin-list', 'watchlist-coin-all-list'].forEach(listId => {
            const el = document.getElementById(listId);
            if (!el) return;
            const empty = el.querySelector('.si-wl-empty');
            if (empty) empty.remove();
            const div = document.createElement('div');
            div.innerHTML = watchlistItemHtml(symbol);
            el.append(div.firstElementChild);
        });
        connectWatchlistWs();
    }
}

function updateWatchlistHeartBtn(symbol) {
    const inList = getWatchlist().includes(symbol);

    // 차트 페이지 관심 버튼
    const btn = document.getElementById('watchlist-btn');
    if (btn) btn.classList.toggle('active', inList);

    // 리스트 페이지 디테일 패널 관심 버튼
    const detailBtn = document.getElementById('detail-watchlist-btn');
    if (detailBtn && typeof currentDetailSymbol !== 'undefined' && currentDetailSymbol === symbol) {
        detailBtn.classList.toggle('active', inList);
    }

    // 리스트 페이지 종목 테이블 행 하트
    const rowBtn = document.querySelector(`#stockTableBody tr[data-symbol="${symbol}"] .like-btn`);
    if (rowBtn) rowBtn.classList.toggle('liked', inList);
}

function toggleSortDropdown(key) {
    const dd = document.getElementById('wl-sort-dropdown-' + key);
    if (!dd) return;
    const isOpen = dd.classList.contains('open');
    document.querySelectorAll('.wl-sort-dropdown').forEach(d => d.classList.remove('open'));
    if (!isOpen) dd.classList.add('open');
}

function setWatchlistSort(sort, key) {
    watchlistSort = sort;
    document.querySelectorAll('.wl-sort-dropdown').forEach(dd => {
        dd.querySelectorAll('.wl-sort-item').forEach(item => {
            item.classList.toggle('active', item.textContent === sort);
        });
        dd.classList.remove('open');
    });
    document.querySelectorAll('[id^="wl-sort-label-"]').forEach(el => el.textContent = sort);
    renderWatchlistCoins('watchlist-coin-list', watchlistCoins);
    renderWatchlistCoins('watchlist-coin-all-list', watchlistCoins);
}

document.addEventListener('click', e => {
    if (!e.target.closest('.wl-sort-wrap'))
        document.querySelectorAll('.wl-sort-dropdown').forEach(d => d.classList.remove('open'));
});

function getSortedCoins(coins) {
    const fn = WATCHLIST_SORT_FNS[watchlistSort];
    return fn ? [...coins].sort(fn) : coins;
}

function watchlistItemHtml(symbol) {
    const ticker = symbol.replace(/USDT$/, '').replace('_SPBL', '');
    const p = watchlistPrices[symbol];
    const price = p ? p.price : null;
    const change = p ? p.change : null;
    const cls = change !== null ? (change >= 0 ? 'up' : 'down') : '';
    const color = coinLogoColor(ticker);
    const logoUrl = 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/' + ticker.toLowerCase() + '.png';
    return `<div class="si-stock-item" data-watchlist="${symbol}">
        <div class="si-logo" style="cursor:pointer;overflow:hidden;" onclick="location.href='/coin/chart?symbol=${symbol}'">
            <img src="${logoUrl}" alt="${ticker}" style="width:100%;height:100%;object-fit:contain;border-radius:50%;"
                onerror="this.parentElement.style.background='${color}';this.parentElement.textContent='${ticker.slice(0, 3)}'">
        </div>
        <span class="si-stock-name" onclick="location.href='/coin/chart?symbol=${symbol}'" style="cursor:pointer">${ticker}</span>
        <div class="si-stock-price">
            <span class="si-price">${price !== null ? fmtCoinPrice(price) : '-'}</span>
            <span class="si-change ${cls}">${price !== null && change !== null ? fmtCoinChange(price, change) : '-'}</span>
        </div>
        <button class="si-heart active" onclick="toggleWatchlist('${symbol}')">${HEART_SVG}</button>
    </div>`;
}

function renderWatchlistCoins(listId, coins) {
    const el = document.getElementById(listId);
    if (!el) return;
    if (coins.length === 0) {
        el.innerHTML = '<div class="si-wl-empty">관심 코인이 없습니다</div>';
        return;
    }
    el.innerHTML = getSortedCoins(coins).map(watchlistItemHtml).join('');
}

async function loadWatchlist() {
    watchlistCoins = getWatchlist();
    if (watchlistCoins.length === 0) {
        renderWatchlistCoins('watchlist-coin-list', []);
        renderWatchlistCoins('watchlist-coin-all-list', []);
        return;
    }

    renderWatchlistCoins('watchlist-coin-list', watchlistCoins);
    renderWatchlistCoins('watchlist-coin-all-list', watchlistCoins);

    try {
        const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers').then(r => r.json());
        if (res.code === '00000' && res.data) {
            watchlistCoins.forEach(symbol => {
                const d = res.data.find(t => t.symbol === symbol);
                if (d) {
                    const price = parseFloat(d.lastPr);
                    const openUtc = parseFloat(d.openUtc);
                    const change = openUtc > 0 ? (price - openUtc) / openUtc * 100 : 0;
                    watchlistPrices[symbol] = { price, change };
                }
            });
            localStorage.setItem('watchlistPrices', JSON.stringify(watchlistPrices));
        }
    } catch (e) { }

    renderWatchlistCoins('watchlist-coin-list', watchlistCoins);
    renderWatchlistCoins('watchlist-coin-all-list', watchlistCoins);
    connectWatchlistWs();
}

function connectWatchlistWs() {
    if (watchlistWs) watchlistWs.close();
    if (watchlistCoins.length === 0) return;

    const ws = new WebSocket('wss://ws.bitget.com/v2/ws/public');
    watchlistWs = ws;

    ws.onopen = () => {
        ws.send(JSON.stringify({
            op: 'subscribe',
            args: watchlistCoins.map(s => ({ instType: 'SPOT', channel: 'ticker', instId: s }))
        }));
        setInterval(() => ws.readyState === 1 && ws.send('ping'), 20000);
    };

    ws.onmessage = (event) => {
        if (event.data === 'pong') return;
        let msg;
        try { msg = JSON.parse(event.data); } catch { return; }
        if (!msg.data || !msg.arg || msg.arg.channel !== 'ticker') return;

        const symbol = msg.arg.instId;
        const price = parseFloat(msg.data[0].lastPr);
        const openUtc = parseFloat(msg.data[0].openUtc);
        const change = openUtc > 0 ? (price - openUtc) / openUtc * 100 : (watchlistPrices[symbol]?.change ?? 0);
        watchlistPrices[symbol] = { price, change };
        localStorage.setItem('watchlistPrices', JSON.stringify(watchlistPrices));

        ['watchlist-coin-list', 'watchlist-coin-all-list'].forEach(listId => {
            const item = document.querySelector('#' + listId + ' [data-watchlist="' + symbol + '"]');
            if (!item) return;
            const cls = change >= 0 ? 'up' : 'down';
            item.querySelector('.si-price').textContent = fmtCoinPrice(price);
            const changeEl = item.querySelector('.si-change');
            changeEl.textContent = fmtCoinChange(price, change);
            changeEl.className = 'si-change ' + cls;
        });
    };

    ws.onclose = () => {
        if (ws === watchlistWs && watchlistCoins.length > 0) setTimeout(connectWatchlistWs, 3000);
    };
}


/* ====================================================
   최근 본 종목 - localStorage 기반
   ==================================================== */
const RECENT_MAX = 20;
let recentCoins = [];
let recentWs = null;
let recentPrices = JSON.parse(localStorage.getItem('recentPrices') || '{}');

function isCoinSymbol(symbol) {
    return /USDT$/i.test(symbol) || symbol.includes('_SPBL');
}

function switchRecentTab(el, tab) {
    document.querySelectorAll('#sidebar-recent .si-type-tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    document.querySelectorAll('.si-recent-tab').forEach(c => c.style.display = 'none');
    document.getElementById('recent-tab-' + tab).style.display = 'flex';
    localStorage.setItem('recentTab', tab);
}

function addToRecent(symbol) {
    let list = JSON.parse(localStorage.getItem('recentCoins') || '[]');
    list = list.filter(s => s !== symbol);
    list.unshift(symbol);
    // 타입별 최대 20개 제한
    const addedIsCoin = isCoinSymbol(symbol);
    let typeCount = 0;
    list = list.filter(s => {
        if (isCoinSymbol(s) === addedIsCoin) { typeCount++; return typeCount <= RECENT_MAX; }
        return true;
    });
    localStorage.setItem('recentCoins', JSON.stringify(list));
    recentCoins = list;
    if (sidebarActiveTab === 'recent') loadRecent();
}

function clearRecent(type) {
    if (!type || type === 'all') {
        recentCoins = [];
        recentPrices = {};
        recentStockPrices = {};
        localStorage.removeItem('recentCoins');
        localStorage.removeItem('recentPrices');
        localStorage.removeItem('recentStockPrices');
    } else {
        const isCoin = type === 'coin';
        recentCoins.filter(s => isCoin ? isCoinSymbol(s) : !isCoinSymbol(s)).forEach(s => {
            delete recentPrices[s];
            delete recentStockPrices[s];
        });
        recentCoins = recentCoins.filter(s => isCoin ? !isCoinSymbol(s) : isCoinSymbol(s));
        localStorage.setItem('recentCoins', JSON.stringify(recentCoins));
        localStorage.setItem('recentPrices', JSON.stringify(recentPrices));
        localStorage.setItem('recentStockPrices', JSON.stringify(recentStockPrices));
    }
    if (recentWs) { recentWs.close(); recentWs = null; }
    renderRecentCoins(recentCoins);
    if (recentCoins.length > 0) connectRecentWs();
}

function removeFromRecent(symbol) {
    const items = document.querySelectorAll('[data-recent="' + symbol + '"]');
    if (items.length > 0) {
        animateRemoveItem(items[0], () => {
            recentCoins = recentCoins.filter(s => s !== symbol);
            localStorage.setItem('recentCoins', JSON.stringify(recentCoins));
            delete recentPrices[symbol];
            delete recentStockPrices[symbol];
            localStorage.setItem('recentPrices', JSON.stringify(recentPrices));
            localStorage.setItem('recentStockPrices', JSON.stringify(recentStockPrices));
            renderRecentCoins(recentCoins);
        });
    }
}

function recentItemHtml(symbol) {
    const ticker = symbol.replace(/USDT$/, '').replace('_SPBL', '');
    const p = recentPrices[symbol];
    const price = p ? p.price : null;
    const change = p ? p.change : null;
    const cls = change !== null ? (change >= 0 ? 'up' : 'down') : '';
    const color = coinLogoColor(ticker);
    const logoUrl = 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/' + ticker.toLowerCase() + '.png';
    return `<div class="si-stock-item" data-recent="${symbol}">
        <div class="si-logo" style="overflow:hidden;cursor:pointer;" onclick="location.href='/coin/chart?symbol=${symbol}'">
            <img src="${logoUrl}" alt="${ticker}" style="width:100%;height:100%;object-fit:contain;border-radius:50%;"
                onerror="this.parentElement.style.background='${color}';this.parentElement.textContent='${ticker.slice(0, 3)}'">
        </div>
        <span class="si-stock-name" onclick="location.href='/coin/chart?symbol=${symbol}'" style="cursor:pointer;">${ticker}</span>
        <div class="si-stock-price" onclick="location.href='/coin/chart?symbol=${symbol}'" style="cursor:pointer;flex:1;">
            <span class="si-price">${price !== null ? fmtCoinPrice(price) : '-'}</span>
            <span class="si-change ${cls}">${price !== null && change !== null ? fmtCoinChange(price, change) : '-'}</span>
        </div>
        <button onclick="removeFromRecent('${symbol}')" style="background:none;border:none;color:var(--text3);font-size:14px;cursor:pointer;padding:4px;line-height:1;flex-shrink:0;">✕</button>
    </div>`;
}

function renderRecentList(listId, coins, emptyLabel) {
    const el = document.getElementById(listId);
    if (!el) return;
    el.innerHTML = coins.length === 0
        ? `<div class="si-wl-empty">${emptyLabel}</div>`
        : coins.map(recentItemHtml).join('');
}

function renderRecentCoins(coins) {
    const coinList = coins.filter(isCoinSymbol);
    const stockList = coins.filter(s => !isCoinSymbol(s));

    // 전체 탭: 각 10개 제한
    renderRecentList('recent-coin-all', coinList.slice(0, 10), '최근 본 코인이 없습니다');
    // 코인 탭: 최대 20개
    renderRecentList('recent-coin-only', coinList, '최근 본 코인이 없습니다');

    // 전체 탭 주식: 10개 제한
    const el = document.getElementById('recent-stock-all');
    if (el) {
        const limited = stockList.slice(0, 10);
        el.innerHTML = limited.length === 0
            ? '<div class="si-wl-empty">최근 본 주식이 없습니다</div>'
            : limited.map(recentStockItemHtml).join('');
    }
    // 주식 탭: 최대 20개
    const el2 = document.getElementById('recent-stock-only');
    if (el2) {
        el2.innerHTML = stockList.length === 0
            ? '<div class="si-wl-empty">최근 본 주식이 없습니다</div>'
            : stockList.map(recentStockItemHtml).join('');
    }

    const coinGroup = document.getElementById('recent-group-coin');
    const stockGroup = document.getElementById('recent-group-stock');
    if (coinGroup) coinGroup.style.display = coinList.length === 0 && stockList.length > 0 ? 'none' : '';
    if (stockGroup) stockGroup.style.display = stockList.length === 0 && coinList.length > 0 ? 'none' : '';
}

async function loadRecent() {
    recentCoins = JSON.parse(localStorage.getItem('recentCoins') || '[]');
    if (recentCoins.length === 0) { renderRecentCoins([]); return; }

    renderRecentCoins(recentCoins);

    const stockList = recentCoins.filter(s => !isCoinSymbol(s));
    if (stockList.length > 0) await loadRecentStocks(stockList);

    renderRecentCoins(recentCoins);

    try {
        const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers').then(r => r.json());
        if (res.code === '00000' && res.data) {
            recentCoins.forEach(symbol => {
                const d = res.data.find(t => t.symbol === symbol);
                if (d) {
                    const price = parseFloat(d.lastPr);
                    const openUtc = parseFloat(d.openUtc);
                    const change = openUtc > 0 ? (price - openUtc) / openUtc * 100 : 0;
                    recentPrices[symbol] = { price, change };
                }
            });
            localStorage.setItem('recentPrices', JSON.stringify(recentPrices));
        }
    } catch (e) { }

    renderRecentCoins(recentCoins);
    connectRecentWs();
}

function connectRecentWs() {
    if (recentWs) recentWs.close();
    if (recentCoins.length === 0) return;
    const ws = new WebSocket('wss://ws.bitget.com/v2/ws/public');
    recentWs = ws;
    ws.onopen = () => {
        ws.send(JSON.stringify({
            op: 'subscribe',
            args: recentCoins.map(s => ({ instType: 'SPOT', channel: 'ticker', instId: s }))
        }));
        setInterval(() => ws.readyState === 1 && ws.send('ping'), 20000);
    };
    ws.onmessage = (event) => {
        if (event.data === 'pong') return;
        let msg;
        try { msg = JSON.parse(event.data); } catch { return; }
        if (!msg.data || !msg.arg || msg.arg.channel !== 'ticker') return;
        const symbol = msg.arg.instId;
        const price = parseFloat(msg.data[0].lastPr);
        const openUtc = parseFloat(msg.data[0].openUtc);
        const change = openUtc > 0 ? (price - openUtc) / openUtc * 100 : (recentPrices[symbol]?.change ?? 0);
        recentPrices[symbol] = { price, change };
        localStorage.setItem('recentPrices', JSON.stringify(recentPrices));
        ['recent-coin-all', 'recent-coin-only'].forEach(listId => {
            const item = document.querySelector('#' + listId + ' [data-recent="' + symbol + '"]');
            if (!item) return;
            const cls = change >= 0 ? 'up' : 'down';
            item.querySelector('.si-price').textContent = fmtCoinPrice(price);
            const changeEl = item.querySelector('.si-change');
            changeEl.textContent = fmtCoinChange(price, change);
            changeEl.className = 'si-change ' + cls;
        });
    };
    ws.onclose = () => {
        if (ws === recentWs && recentCoins.length > 0) setTimeout(connectRecentWs, 3000);
    };
}


/* ====================================================
   실시간 주식 사이드바
   ==================================================== */
let sidebarStockMap = {};   // code → {name, price, rate, diff}
let sidebarStockOrder = []; // 시가총액 순 코드 배열
let sidebarStompClient = null;

function loadScriptAsync(url) {
    return new Promise(resolve => {
        if (document.querySelector('script[src="' + url + '"]')) { resolve(); return; }
        const s = document.createElement('script');
        s.src = url;
        s.onload = resolve;
        s.onerror = resolve;
        document.head.appendChild(s);
    });
}

async function initSidebarStock() {
    try {
        const res = await fetch('/stock/db-list?limit=40');
        const data = await res.json();
        if (!Array.isArray(data)) return;
        sidebarStockOrder = data.map(s => s.code).filter(Boolean);
        data.forEach(s => {
            if (s.code) {
                sidebarStockMap[s.code] = {
                    name: s.name || '-',
                    price: s.price || '-',
                    rate: s.rate || '-',
                    diff: s.diff || '-',
                    volume: s.volume || '0'
                };
            }
        });
        renderSidebarStockList();
        renderLiveAll();
    } catch (e) {}
    connectSidebarStockWs();
}

async function connectSidebarStockWs() {
    if (typeof SockJS === 'undefined') {
        await loadScriptAsync('https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js');
    }
    if (typeof Stomp === 'undefined') {
        await loadScriptAsync('https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js');
    }
    const socket = new SockJS('/ws-stock');
    sidebarStompClient = Stomp.over(socket);
    sidebarStompClient.debug = null;
    sidebarStompClient.connect({}, () => {
        sidebarStompClient.subscribe('/topic/stock/price', msg => {
            const d = JSON.parse(msg.body);
            if (!sidebarStockMap[d.code]) return;
            sidebarStockMap[d.code].price  = d.price;
            sidebarStockMap[d.code].rate   = d.rate;
            sidebarStockMap[d.code].diff   = d.diff;
            sidebarStockMap[d.code].volume = d.volume || '0';
            updateSidebarStockItem(d);
        });
    }, () => setTimeout(connectSidebarStockWs, 3000));
}

function updateSidebarStockItem(d) {
    const n = parseFloat(d.rate);
    const cls = isNaN(n) ? '' : (n > 0 ? 'up' : n < 0 ? 'down' : '');
    const rateText = isNaN(n) ? '-' : (n > 0 ? '+' : '') + n.toFixed(2) + '%';
    const priceText = d.price ? Number(d.price).toLocaleString() + '원' : '-';

    ['live-stock-list', 'live-all-list'].forEach(listId => {
        const item = document.querySelector('#' + listId + ' [data-live-stock="' + d.code + '"]');
        if (!item) return;
        item.querySelector('.live-pr').textContent = priceText;
        const chEl = item.querySelector('.live-ch');
        chEl.textContent = rateText;
        chEl.className = 'live-ch ' + cls;
    });
}

function getSidebarStockSorted() {
    if (liveSort === '급상승') {
        return [...sidebarStockOrder].sort((a, b) =>
            (parseFloat(sidebarStockMap[b]?.rate) || 0) - (parseFloat(sidebarStockMap[a]?.rate) || 0));
    }
    if (liveSort === '급하락') {
        return [...sidebarStockOrder].sort((a, b) =>
            (parseFloat(sidebarStockMap[a]?.rate) || 0) - (parseFloat(sidebarStockMap[b]?.rate) || 0));
    }
    // 거래대금 순 (기본)
    return [...sidebarStockOrder].sort((a, b) =>
        (parseFloat(sidebarStockMap[b]?.volume) || 0) - (parseFloat(sidebarStockMap[a]?.volume) || 0));
}

function liveStockItemHtml(code, d, rank) {
    const n = parseFloat(d.rate);
    const cls = isNaN(n) ? '' : (n > 0 ? 'up' : n < 0 ? 'down' : '');
    const rateText = isNaN(n) ? '-' : (n > 0 ? '+' : '') + n.toFixed(2) + '%';
    const priceText = d.price && d.price !== '-' ? Number(d.price).toLocaleString() + '원' : '-';
    const initials = (d.name || '  ').slice(0, 2);
    return '<div class="live-item" data-live-stock="' + code + '" onclick="location.href=\'/stock/chart?code=' + code + '\'">'
        + '<span class="live-rank">' + rank + '</span>'
        + '<div class="si-logo" style="overflow:hidden;flex-shrink:0;">'
        + '<img src="https://file.alphasquare.co.kr/media/images/stock_logo/kr/' + code + '.png"'
        + ' style="width:100%;height:100%;object-fit:contain;"'
        + ' onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'\';">'
        + '<span style="display:none;font-size:9px;font-weight:700;color:#fff;">' + initials + '</span>'
        + '</div>'
        + '<span class="live-name">' + d.name + '</span>'
        + '<div class="live-price-col">'
        + '<span class="live-pr">' + priceText + '</span>'
        + '<span class="live-ch ' + cls + '">' + rateText + '</span>'
        + '</div></div>';
}

function renderSidebarStockList() {
    const el = document.getElementById('live-stock-list');
    if (!el) return;
    const sorted = getSidebarStockSorted();
    el.innerHTML = sorted.length === 0
        ? '<div class="si-wl-empty">데이터를 불러오는 중입니다</div>'
        : sorted.map((code, i) => liveStockItemHtml(code, sidebarStockMap[code] || { name: '-', price: '-', rate: '-' }, i + 1)).join('');
}

/* ====================================================
   실시간 TOP 50 코인
   ==================================================== */
let liveCoins = JSON.parse(localStorage.getItem('liveCoins') || '[]');
let livePrices = JSON.parse(localStorage.getItem('livePrices') || '{}');
let liveWs = null;
let liveSort = '거래대금';
let liveTime = '실시간';
let currentLiveTab = 'stock';

function switchLiveTab(el, tab) {
    currentLiveTab = tab;
    localStorage.setItem('liveTab', tab);
    document.querySelectorAll('#sidebar-live .si-type-tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    document.querySelectorAll('.live-tab-panel').forEach(c => c.style.display = 'none');
    document.getElementById('live-tab-' + tab).style.display = '';
    if (tab === 'all') renderLiveAll();
}

function toggleLiveDropdown(key) {
    const dd = document.getElementById('live-' + key + '-dd');
    if (!dd) return;
    const isOpen = dd.classList.contains('open');
    document.querySelectorAll('#sidebar-live .wl-sort-dropdown').forEach(d => d.classList.remove('open'));
    if (!isOpen) dd.classList.add('open');
}

function setLiveSort(sort) {
    liveSort = sort;
    document.getElementById('live-sort-label').textContent = sort;
    document.querySelectorAll('#live-sort-dd .wl-sort-item').forEach(i => i.classList.toggle('active', i.textContent === sort));
    document.getElementById('live-sort-dd').classList.remove('open');
    renderLiveCoins();
    renderSidebarStockList();
    renderLiveAll();
}

function setLiveTime(time) {
    liveTime = time;
    document.getElementById('live-time-label').textContent = time;
    document.querySelectorAll('#live-time-dd .wl-sort-item').forEach(i => i.classList.toggle('active', i.textContent === time));
    document.getElementById('live-time-dd').classList.remove('open');
    renderLiveCoins();
}

function getSortedLiveCoins() {
    return [...liveCoins].sort((a, b) => {
        const pa = livePrices[a], pb = livePrices[b];
        const ca = liveTime === '1일' ? (pa?.change24h ?? 0) : (pa?.change ?? 0);
        const cb = liveTime === '1일' ? (pb?.change24h ?? 0) : (pb?.change ?? 0);
        if (liveSort === '급상승') return cb - ca;
        if (liveSort === '급하락') return ca - cb;
        return (pb?.volume ?? 0) - (pa?.volume ?? 0);
    });
}

function liveItemHtml(symbol, rank) {
    const ticker = symbol.replace(/USDT$/, '').replace('_SPBL', '');
    const p = livePrices[symbol];
    const price = p ? p.price : null;
    const change = p ? (liveTime === '1일' ? p.change24h : p.change) : null;
    const cls = change !== null ? (change >= 0 ? 'up' : 'down') : '';
    const color = coinLogoColor(ticker);
    const logoUrl = 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/' + ticker.toLowerCase() + '.png';
    return `<div class="live-item" data-live="${symbol}" onclick="location.href='/coin/chart?symbol=${symbol}'">
        <span class="live-rank">${rank}</span>
        <div class="si-logo" style="overflow:hidden;flex-shrink:0;">
            <img src="${logoUrl}" alt="${ticker}" style="width:100%;height:100%;object-fit:contain;border-radius:50%;"
                onerror="this.parentElement.style.background='${color}';this.parentElement.style.fontSize='10px';this.parentElement.textContent='${ticker.slice(0,3)}'">
        </div>
        <span class="live-name">${ticker}</span>
        <div class="live-price-col">
            <span class="live-pr">${price !== null ? fmtCoinPrice(price) : '-'}</span>
            <span class="live-ch ${cls}">${price !== null && change !== null ? fmtCoinChange(price, change) : '-'}</span>
        </div>
    </div>`;
}

function liveAllItemHtml(item, rank) {
    const cls = item.rate > 0 ? 'up' : item.rate < 0 ? 'down' : '';
    const rateText = (item.rate > 0 ? '+' : '') + item.rate.toFixed(2) + '%';

    if (item.type === 'coin') {
        const color = coinLogoColor(item.name);
        const logoUrl = 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/' + item.name.toLowerCase() + '.png';
        return '<div class="live-item" data-live="' + item.id + '" onclick="location.href=\'/coin/chart?symbol=' + item.id + '\'">'
            + '<span class="live-rank">' + rank + '</span>'
            + '<div class="si-logo" style="overflow:hidden;flex-shrink:0;">'
            + '<img src="' + logoUrl + '" style="width:100%;height:100%;object-fit:contain;border-radius:50%;"'
            + ' onerror="this.parentElement.style.background=\'' + color + '\';this.parentElement.style.fontSize=\'10px\';this.parentElement.textContent=\'' + item.name.slice(0, 3) + '\'">'
            + '</div>'
            + '<div style="flex:1;min-width:0;overflow:hidden;margin-left:8px;">'
            + '<div style="font-size:16px;font-weight:400;color:var(--text);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">' + item.name + '</div>'
            + '<span style="display:inline-block;padding:1px 5px;border-radius:3px;font-size:10px;font-weight:600;background:rgba(139,92,246,0.12);color:#8B5CF6;border:1px solid rgba(139,92,246,0.25);">코인</span>'
            + '</div>'
            + '<div class="live-price-col">'
            + '<span class="live-pr">' + (item.price !== null ? fmtCoinPrice(item.price) : '-') + '</span>'
            + '<span class="live-ch ' + cls + '">' + rateText + '</span>'
            + '</div></div>';
    }

    const initials = (item.name || '  ').slice(0, 2);
    const priceText = item.price && item.price !== '-' ? Number(item.price).toLocaleString() + '원' : '-';
    return '<div class="live-item" data-live-stock="' + item.id + '" onclick="location.href=\'/stock/chart?code=' + item.id + '\'">'
        + '<span class="live-rank">' + rank + '</span>'
        + '<div class="si-logo" style="overflow:hidden;flex-shrink:0;">'
        + '<img src="https://file.alphasquare.co.kr/media/images/stock_logo/kr/' + item.id + '.png"'
        + ' style="width:100%;height:100%;object-fit:contain;"'
        + ' onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'\';">'
        + '<span style="display:none;font-size:9px;font-weight:700;color:#fff;">' + initials + '</span>'
        + '</div>'
        + '<div style="flex:1;min-width:0;overflow:hidden;margin-left:8px;">'
        + '<div style="font-size:16px;font-weight:400;color:var(--text);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">' + item.name + '</div>'
        + '<span style="display:inline-block;padding:1px 5px;border-radius:3px;font-size:10px;font-weight:600;background:rgba(13,148,136,0.12);color:#0D9488;border:1px solid rgba(13,148,136,0.25);">주식</span>'
        + '</div>'
        + '<div class="live-price-col">'
        + '<span class="live-pr">' + priceText + '</span>'
        + '<span class="live-ch ' + cls + '">' + rateText + '</span>'
        + '</div></div>';
}

function renderLiveAll() {
    const el = document.getElementById('live-all-list');
    if (!el) return;

    const coinItems = liveCoins.map(symbol => {
        const ticker = symbol.replace(/USDT$/, '').replace('_SPBL', '');
        const p = livePrices[symbol];
        return {
            type: 'coin',
            id: symbol,
            name: ticker,
            price: p?.price ?? null,
            rate: p?.change ?? 0,
            volumeKrw: (p?.volume ?? 0) * usdToKrw
        };
    });

    const stockItems = sidebarStockOrder.map(code => {
        const d = sidebarStockMap[code];
        return {
            type: 'stock',
            id: code,
            name: d?.name || '-',
            price: d?.price ?? '-',
            rate: parseFloat(d?.rate) || 0,
            volumeKrw: parseFloat(d?.volume) || 0
        };
    });

    const all = [...coinItems, ...stockItems];

    if (liveSort === '급상승') all.sort((a, b) => b.rate - a.rate);
    else if (liveSort === '급하락') all.sort((a, b) => a.rate - b.rate);
    else all.sort((a, b) => b.volumeKrw - a.volumeKrw);

    el.innerHTML = all.length === 0
        ? '<div class="si-wl-empty">데이터를 불러오는 중입니다</div>'
        : all.map((item, i) => liveAllItemHtml(item, i + 1)).join('');
}

function renderLiveCoins() {
    const sorted = getSortedLiveCoins();
    const el = document.getElementById('live-coin-list');
    if (el) {
        el.innerHTML = sorted.length === 0
            ? '<div class="si-wl-empty">데이터를 불러오는 중입니다</div>'
            : sorted.map((s, i) => liveItemHtml(s, i + 1)).join('');
    }
}

async function loadLiveCoins() {
    if (liveCoins.length > 0) renderLiveCoins();
    try {
        const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers').then(r => r.json());
        if (res.code === '00000' && res.data) {
            const filtered = res.data.filter(t => t.symbol.endsWith('USDT') && !t.symbol.includes('_'));
            filtered.sort((a, b) => parseFloat(b.usdtVolume) - parseFloat(a.usdtVolume));
            const top50 = filtered.slice(0, 50);
            liveCoins = top50.map(t => t.symbol);
            top50.forEach(t => {
                const price = parseFloat(t.lastPr);
                const openUtc = parseFloat(t.openUtc);
                const change = openUtc > 0 ? (price - openUtc) / openUtc * 100 : 0;
                const change24h = parseFloat(t.change24h) * 100;
                livePrices[t.symbol] = { price, change, change24h, volume: parseFloat(t.usdtVolume) };
            });
            localStorage.setItem('liveCoins', JSON.stringify(liveCoins));
            localStorage.setItem('livePrices', JSON.stringify(livePrices));
        }
    } catch (e) { }
    renderLiveCoins();
    renderLiveAll();
    connectLiveWs();
}

function connectLiveWs() {
    if (liveWs) liveWs.close();
    if (liveCoins.length === 0) return;
    const ws = new WebSocket('wss://ws.bitget.com/v2/ws/public');
    liveWs = ws;
    ws.onopen = () => {
        ws.send(JSON.stringify({
            op: 'subscribe',
            args: liveCoins.map(s => ({ instType: 'SPOT', channel: 'ticker', instId: s }))
        }));
        setInterval(() => ws.readyState === 1 && ws.send('ping'), 20000);
    };
    ws.onmessage = (event) => {
        if (event.data === 'pong') return;
        let msg;
        try { msg = JSON.parse(event.data); } catch { return; }
        if (!msg.data || !msg.arg || msg.arg.channel !== 'ticker') return;
        const symbol = msg.arg.instId;
        const price = parseFloat(msg.data[0].lastPr);
        const openUtc = parseFloat(msg.data[0].openUtc);
        const change = openUtc > 0 ? (price - openUtc) / openUtc * 100 : (livePrices[symbol]?.change ?? 0);
        const change24h = parseFloat(msg.data[0].change24h) * 100;
        livePrices[symbol] = { ...livePrices[symbol], price, change, change24h };
        ['live-all-list', 'live-coin-list'].forEach(listId => {
            const item = document.querySelector('#' + listId + ' [data-live="' + symbol + '"]');
            if (!item) return;
            const disp = liveTime === '1일' ? change24h : change;
            const cls = disp >= 0 ? 'up' : 'down';
            item.querySelector('.live-pr').textContent = fmtCoinPrice(price);
            const chEl = item.querySelector('.live-ch');
            chEl.textContent = fmtCoinChange(price, disp);
            chEl.className = 'live-ch ' + cls;
        });
    };
    ws.onclose = () => {
        if (ws === liveWs && liveCoins.length > 0) setTimeout(connectLiveWs, 3000);
    };
}


document.addEventListener('DOMContentLoaded', () => {
    const animate = document.body.dataset.sidebarAnimate === 'true';
    const fixedTab = document.body.dataset.sidebarTab;

    if (document.body.dataset.sidebarClosed === 'true') { loadHoldings(); return; }

    const navType = performance.getEntriesByType('navigation')[0]?.type;
    const legacyNavType = performance.navigation?.type; // 0=navigate, 1=reload, 2=back_forward
    const isFirstLoad = !sessionStorage.getItem('sidebarInit') || navType === 'reload' || legacyNavType === 1;
    sessionStorage.setItem('sidebarInit', '1');

    if (isFirstLoad) {
        localStorage.setItem('liveTab', 'stock');
        requestAnimationFrame(() => requestAnimationFrame(() => { sidebarReady = true; toggleSidebar('live'); }));
    } else {
        /* 페이지 이동: sidebar-icons.jsp 인라인 스크립트가 이미 복원함 */
        sidebarReady = true;
    }

    const investTab = document.body.dataset.sidebarInvestTab || localStorage.getItem('investTab');
    if (investTab) {
        const tabEl = document.querySelector(`.si-type-tab[onclick*="switchInvestTab"][onclick*="${investTab}"]`);
        if (tabEl) switchInvestTab(tabEl, investTab);
    }

    if (!isFirstLoad) {
        const interestTab2 = localStorage.getItem('interestTab2');
        if (interestTab2) {
            const tabEl = document.querySelector(`#sidebar-interest .si-type-tab[onclick*="switchInterestTab"][onclick*="'${interestTab2}'"]`);
            if (tabEl) switchInterestTab(tabEl, interestTab2);
        }

        const recentTab = localStorage.getItem('recentTab');
        if (recentTab) {
            const tabEl = document.querySelector(`#sidebar-recent .si-type-tab[onclick*="switchRecentTab"][onclick*="'${recentTab}'"]`);
            if (tabEl) switchRecentTab(tabEl, recentTab);
        }

        const liveTab = localStorage.getItem('liveTab');
        if (liveTab) {
            const tabEl = document.querySelector(`#sidebar-live .si-type-tab[onclick*="switchLiveTab"][onclick*="'${liveTab}'"]`);
            if (tabEl) switchLiveTab(tabEl, liveTab);
        }
    }

    const groupOrder = localStorage.getItem('interestGroupOrder');
    if (groupOrder) {
        const container = document.getElementById('si-all-container');
        const stock = document.getElementById('si-group-stock');
        const coin = document.getElementById('si-group-coin');
        if (container && stock && coin) {
            if (groupOrder === 'coin' && container.firstElementChild !== coin) {
                container.insertBefore(coin, stock);
            } else if (groupOrder === 'stock' && container.firstElementChild !== stock) {
                container.insertBefore(stock, coin);
            }
        }
    }

    fetchExchangeRate();
    loadHoldings();
    loadOrders();
    loadWatchlist();
    loadWatchlistStocks();
    loadRecent();
    loadLiveCoins();
    initSidebarStock();
});

function cmOpenImage(img) {
    const modal = document.getElementById('cmImageModal');
    const modalImg = document.getElementById('cmImageModalImg');
    if (!modal || !modalImg) return;
    modalImg.src = img.src;
    modal.classList.add('open');
}
