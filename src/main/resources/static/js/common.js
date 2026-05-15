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

function switchBpTab(el, tab) {
    document.querySelectorAll('.sb-tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    document.getElementById('tab-positions').style.display = tab === 'positions' ? 'flex' : 'none';
    document.getElementById('tab-orders').style.display = tab === 'orders' ? 'flex' : 'none';
    document.getElementById('tab-history').style.display = tab === 'history' ? 'flex' : 'none';
}


/* ====================================================
   보유 내역 로드 + 실시간 가격 WebSocket (모든 페이지)
   ==================================================== */
let holdingsData = [];
let holdingsWs = null;
let cachedPrices = JSON.parse(localStorage.getItem('holdingPrices') || '{}');

function skeletonRow() {
    return '<tr class="skeleton-row">'
        + '<td><span class="skeleton" style="width:55px"></span></td>'
        + '<td><span class="skeleton" style="width:65px"></span></td>'
        + '<td><span class="skeleton" style="width:65px"></span></td>'
        + '<td><span class="skeleton" style="width:55px"></span></td>'
        + '<td><span class="skeleton" style="width:75px"></span></td>'
        + '</tr>';
}

function renderHoldings(data) {
    const tbody = document.getElementById('bp-holdings-body');
    if (!tbody) return;

    if (data.length > 0) {
        document.getElementById('bp-empty').style.display = 'none';
        document.getElementById('bp-holdings-table').style.display = 'table';

        data.forEach(h => {
            const price = cachedPrices[h.coinCode] || null;
            const pnl = price !== null ? (price - h.avgPrice) * h.coinCount : null;
            const pc = pnl !== null ? (pnl >= 0 ? 'var(--up)' : 'var(--down)') : '';

            /* 이미 행이 있으면 in-place 업데이트 (재렌더 깜빡임 방지) */
            let row = tbody.querySelector('tr[data-coin="' + h.coinCode + '"]');
            if (row) {
                row.children[1].textContent = h.coinCount.toFixed(6);
                row.children[2].textContent = h.avgPrice.toFixed(2);
                if (price !== null) {
                    row.querySelector('.holding-price').textContent = price.toFixed(2);
                    const pnlEl = row.querySelector('.holding-pnl');
                    pnlEl.textContent = (pnl >= 0 ? '+' : '') + pnl.toFixed(2) + ' USDT';
                    pnlEl.style.color = pc;
                }
            } else {
                const tr = document.createElement('tr');
                tr.dataset.coin = h.coinCode;
                tr.innerHTML = '<td>' + h.coinCode + '</td>'
                    + '<td>' + h.coinCount.toFixed(6) + '</td>'
                    + '<td>' + h.avgPrice.toFixed(2) + '</td>'
                    + '<td class="holding-price">' + (price !== null ? price.toFixed(2) : '-') + '</td>'
                    + '<td class="holding-pnl" style="color:' + pc + '">'
                    + (pnl !== null ? (pnl >= 0 ? '+' : '') + pnl.toFixed(2) + ' USDT' : '-') + '</td>';
                /* 스켈레톤 행 교체 또는 추가 */
                const skelRow = tbody.querySelector('.skeleton-row');
                if (skelRow) tbody.replaceChild(tr, skelRow);
                else tbody.appendChild(tr);
            }
        });
        /* 남은 스켈레톤 행 제거 */
        tbody.querySelectorAll('.skeleton-row').forEach(r => r.remove());
    } else {
        document.getElementById('bp-empty').style.display = '';
        document.getElementById('bp-holdings-table').style.display = 'none';
        tbody.innerHTML = '';
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
        document.getElementById('bp-holdings-table').style.display = 'table';
        tbody.innerHTML = skeletonRow() + skeletonRow() + skeletonRow();
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
    const row = document.querySelector('#bp-holdings-body tr[data-coin="' + coinCode + '"]');
    if (!row) return;
    const h = holdingsData.find(h => h.coinCode === coinCode);
    if (!h) return;
    const pnl = (price - h.avgPrice) * h.coinCount;
    row.querySelector('.holding-price').textContent = price.toFixed(2);
    const pnlEl = row.querySelector('.holding-pnl');
    pnlEl.textContent = (pnl >= 0 ? '+' : '') + pnl.toFixed(2) + ' USDT';
    pnlEl.style.color = pnl >= 0 ? 'var(--up)' : 'var(--down)';

    cachedPrices[coinCode] = price;
    localStorage.setItem('holdingPrices', JSON.stringify(cachedPrices));
}


document.addEventListener('DOMContentLoaded', () => {
    const animate = document.body.dataset.sidebarAnimate === 'true';
    const fixedTab = document.body.dataset.sidebarTab;

    if (animate) {
        /* list.jsp: 항상 애니메이션으로 열기 */
        requestAnimationFrame(() => requestAnimationFrame(() => toggleSidebar('interest')));
    } else {
        /* 다른 페이지: 인라인 스크립트가 DOM·localStorage 처리 → JS 변수만 동기화 */
        const tab = fixedTab || localStorage.getItem('sidebar');
        if (tab) sidebarActiveTab = tab;
    }

    loadHoldings();
});
