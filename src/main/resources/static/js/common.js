/* =====================================================
   common.js
   모든 페이지에서 공통으로 사용하는 JS
   nav, sidebar 관련 함수 등
   ===================================================== */


/* ====================================================
   사이드바 슬라이드 토글
   ==================================================== */
const SIDEBAR_TITLES = { invest: '내 투자현황', interest: '관심 종목', recent: '최근 본', live: '실시간' };
let sidebarActiveTab = null;

function toggleSidebar(tab) {
    const panel = document.getElementById('sidebar-panel');
    if (sidebarActiveTab === tab) { closeSidebar(); return; }
    sidebarActiveTab = tab;
    panel.classList.add('open');
    document.querySelectorAll('.si-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('si-' + tab).classList.add('active');
    document.getElementById('sidebar-title').textContent = SIDEBAR_TITLES[tab] || tab;
    document.querySelectorAll('.sidebar-section').forEach(s => s.style.display = 'none');
    document.getElementById('sidebar-' + tab).style.display = '';
    localStorage.setItem('sidebar', tab);
}

function closeSidebar() {
    sidebarActiveTab = null;
    document.getElementById('sidebar-panel').classList.remove('open');
    document.querySelectorAll('.si-btn').forEach(b => b.classList.remove('active'));
    localStorage.removeItem('sidebar');
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
    } else {
        container.insertBefore(stock, coin);
    }
}

function switchInterestTab(el, tab) {
    document.querySelectorAll('.si-type-tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    document.querySelectorAll('.si-tab-content').forEach(c => c.style.display = 'none');
    document.getElementById('interest-' + tab).style.display = '';
}

function switchInvestTab(el, tab) {
    el.closest('.si-type-tabs').querySelectorAll('.si-type-tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    ['stock', 'coin'].forEach(t => {
        const el = document.getElementById('invest-' + t);
        if (el) el.style.display = t === tab ? 'flex' : 'none';
    });
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
        +   '<div class="hc-main-id">'
        +     '<div class="hc-logo skeleton" style="background:transparent;"></div>'
        +     '<div class="hc-main-name-col">'
        +       '<span class="skeleton" style="width:70px;height:13px;display:block;"></span>'
        +       '<span class="skeleton" style="width:90px;height:11px;display:block;margin-top:4px;"></span>'
        +     '</div>'
        +   '</div>'
        +   '<div class="hc-main-right">'
        +     '<span class="skeleton" style="width:80px;height:13px;display:block;"></span>'
        +     '<span class="skeleton" style="width:100px;height:11px;display:block;margin-top:4px;"></span>'
        +   '</div>'
        + '</div>'
        + '<div class="hc-divider"></div>'
        + '<div class="hc-main-grid">'
        +   '<div class="hc-main-row"><span class="skeleton" style="width:50px;height:11px;"></span><span class="skeleton" style="width:60px;height:11px;"></span></div>'
        +   '<div class="hc-main-row"><span class="skeleton" style="width:50px;height:11px;"></span><span class="skeleton" style="width:60px;height:11px;"></span></div>'
        +   '<div class="hc-main-row"><span class="skeleton" style="width:50px;height:11px;"></span><span class="skeleton" style="width:60px;height:11px;"></span></div>'
        +   '<div class="hc-main-row"><span class="skeleton" style="width:50px;height:11px;"></span><span class="skeleton" style="width:60px;height:11px;"></span></div>'
        + '</div>'
        + '</div>';
}

function coinLogoColor(code) {
    const colors = ['#F7931A','#627EEA','#00AAC1','#E84142','#2775CA','#26A17B','#9945FF','#E6007A'];
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
                    card.querySelector('.hc-main-eval').textContent = evalAmt.toLocaleString(undefined, {maximumFractionDigits: 2}) + ' USDT';
                    const pnlEl = card.querySelector('.hc-main-pnl');
                    pnlEl.textContent = arrow + Math.abs(pnl).toFixed(2) + ' (' + sign + pct.toFixed(2) + '%)';
                    pnlEl.className = 'hc-main-pnl ' + cls;
                    card.querySelector('.hc-price-val').textContent = price.toLocaleString(undefined, {maximumFractionDigits: 6});
                    card.querySelector('.hc-eval-val').textContent = (evalAmt !== null ? evalAmt.toLocaleString(undefined, {maximumFractionDigits: 2}) : '-') + ' USDT';
                }
            } else {
                const ticker = h.coinCode.replace(/USDT$/, '').replace('_SPBL', '');
                const div = document.createElement('div');
                div.className = 'holding-card hc-main';
                div.dataset.coin = h.coinCode;
                div.innerHTML =
                    '<div class="hc-main-header">'
                    +   '<div class="hc-main-id">'
                    +     coinLogoHtml(ticker)
                    +     '<div class="hc-main-name-col">'
                    +       '<span class="hc-main-ticker">' + ticker + '</span>'
                    +       '<span class="hc-main-sub">' + ticker + '/USDT | ' + h.coinCount.toFixed(4) + '개</span>'
                    +     '</div>'
                    +   '</div>'
                    +   '<div class="hc-main-right">'
                    +     '<span class="hc-main-eval">' + (evalAmt !== null ? evalAmt.toLocaleString(undefined, {maximumFractionDigits: 2}) : '-') + ' USDT</span>'
                    +     '<span class="hc-main-pnl ' + cls + '">' + (pnl !== null ? arrow + Math.abs(pnl).toFixed(2) + ' (' + sign + pct.toFixed(2) + '%)' : '-') + '</span>'
                    +   '</div>'
                    + '</div>'
                    + '<div class="hc-divider"></div>'
                    + '<div class="hc-main-grid">'
                    +   '<div class="hc-main-row"><span class="hc-label">매수금액</span><span class="hc-value">' + buyAmt.toLocaleString(undefined, {maximumFractionDigits: 2}) + ' USDT</span></div>'
                    +   '<div class="hc-main-row"><span class="hc-label">평균단가</span><span class="hc-value">' + h.avgPrice.toLocaleString(undefined, {maximumFractionDigits: 6}) + '</span></div>'
                    +   '<div class="hc-main-row"><span class="hc-label">평가금액</span><span class="hc-value hc-eval-val">' + (evalAmt !== null ? evalAmt.toLocaleString(undefined, {maximumFractionDigits: 2}) : '-') + ' USDT</span></div>'
                    +   '<div class="hc-main-row"><span class="hc-label">현재가</span><span class="hc-value hc-price-val">' + (price !== null ? price.toLocaleString(undefined, {maximumFractionDigits: 6}) : '-') + '</span></div>'
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

    card.querySelector('.hc-main-eval').textContent = evalAmt.toLocaleString(undefined, {maximumFractionDigits: 2}) + ' USDT';
    const pnlEl = card.querySelector('.hc-main-pnl');
    pnlEl.textContent = arrow + Math.abs(pnl).toFixed(2) + ' (' + sign + pct.toFixed(2) + '%)';
    pnlEl.className = 'hc-main-pnl ' + cls;
    card.querySelector('.hc-price-val').textContent = price.toLocaleString(undefined, {maximumFractionDigits: 6});
    card.querySelector('.hc-eval-val').textContent = evalAmt.toLocaleString(undefined, {maximumFractionDigits: 2}) + ' USDT';

    cachedPrices[coinCode] = price;
    localStorage.setItem('holdingPrices', JSON.stringify(cachedPrices));
}


document.addEventListener('DOMContentLoaded', () => {
    const animate = document.body.dataset.sidebarAnimate === 'true';
    const fixedTab = document.body.dataset.sidebarTab;

    if (document.body.dataset.sidebarClosed === 'true') { loadHoldings(); return; }

    if (animate) {
        /* list.jsp: 항상 애니메이션으로 열기 */
        requestAnimationFrame(() => requestAnimationFrame(() => toggleSidebar('interest')));
    } else {
        const tab = fixedTab || localStorage.getItem('sidebar');
        if (tab) {
            requestAnimationFrame(() => requestAnimationFrame(() => toggleSidebar(tab)));
        }
    }

    loadHoldings();
});
