/* =====================================================
   stockList.js - 주식 리스트 데이터 로딩 및 UI 렌더링
   ===================================================== */

let allStocks = [];
let currentFilter = '전체';
let currentDetailCode = null;
let detailChartTimer = null;
let miniChartsLoaded = false;

/* ── 관심종목 (로컬스토리지) ── */
function toggleStockWatchlistRow(code) {
    const list = getStockWatchlist();
    const idx = list.indexOf(code);
    const isAdding = idx < 0;
    if (idx >= 0) list.splice(idx, 1);
    else list.push(code);
    localStorage.setItem('stock_watchlist', JSON.stringify(list));

    if (typeof updateStockWatchlistHeartBtn === 'function') updateStockWatchlistHeartBtn(code, isAdding);
    if (isAdding) {
        if (typeof toggleSidebar === 'function' && sidebarActiveTab !== 'interest') toggleSidebar('interest');
        if (typeof sidebarStockMap !== 'undefined' && sidebarStockMap[code]) {
            watchlistStockPrices[code] = { ...sidebarStockMap[code] };
        }
        if (typeof renderWatchlistStocks === 'function') renderWatchlistStocks();
    } else {
        if (typeof watchlistStockPrices !== 'undefined') delete watchlistStockPrices[code];
        let pending = 0;
        ['watchlist-stock-list', 'watchlist-stock-all-list'].forEach(listId => {
            const item = document.querySelector('#' + listId + ' [data-watchlist-stock="' + code + '"]');
            if (!item) return;
            pending++;
            if (typeof animateRemoveItem === 'function') {
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
            }
        });
    }
}

/* ── 포맷 헬퍼 ── */
function fmtPrice(val) {
    const s = (val || '').toString().replace(/,/g, '').replace(/[^0-9.\-]/g, '');
    const n = parseFloat(s);
    if (isNaN(n) || n === 0) return val || '-';
    return n.toLocaleString() + '원';
}

function fmtRate(val) {
    if (!val || val === '-') return { text: '-', cls: 'neutral' };
    
    // %, + 기호를 제거하고 순수 숫자로 변환
    const n = parseFloat(val.toString().replace(/[+%]/g, ''));
    if (isNaN(n)) return { text: val, cls: 'neutral' };
    
    let cls = 'neutral';
    let text = n.toFixed(2) + '%';

    if (n > 0) {
        cls = 'up';
        text = '+' + text; // 양수일 때만 + 붙임
    } else if (n < 0) {
        cls = 'down';
        // n이 이미 음수이므로 n.toFixed(2) 결과에 -가 포함되어 나옵니다.
    }

    return { text: text, cls: cls };
}

function fmtDiff(val) {
    if (!val || val === '-') return '-';
    const n = parseFloat(val.toString().replace(/,/g, '').replace(/[^0-9.\-]/g, ''));
    if (isNaN(n) || n === 0) return '-';
    return (n > 0 ? '+' : '') + n.toLocaleString() + '원';
}

/* ── API 데이터 정규화 ── */
function normalizeStock(item) {
    if (item.code !== undefined) {
        // db-list 및 rank API 응답
        return {
            name: item.name || '-',
            code: item.code || '',
            price: item.price || '-',
            changeRate: item.rate || '-',
            changeDiff: item.diff || '-',
            high: item.high || '-',
            low: item.low || '-',
            volume: item.volume || '0',
        };
    }
    // summary API 응답
    return {
        name: item.stock_name || '-',
        code: '',
        price: item.stck_prpr || '-',
        changeRate: item.prdy_ctrt || '-',
        changeDiff: '-',
    };
}

/* ── API 호출 ── */
async function loadStocks() {
    try {
        if (currentFilter === '급상승') {
            const res = await fetch('/stock/rank?mode=UP');
            const data = await res.json();
            return (Array.isArray(data) ? data : []).map(normalizeStock);
        }
        if (currentFilter === '급하락') {
            const res = await fetch('/stock/rank?mode=DOWN');
            const data = await res.json();
            return (Array.isArray(data) ? data : []).map(normalizeStock);
        }
        const res = await fetch('/stock/db-list?limit=40');
        const data = await res.json();
        return (Array.isArray(data) ? data : []).map(normalizeStock);
    } catch (e) {
        return [];
    }
}

/* ── KIS WebSocket 실시간 연결 ── */
let stockStompClient = null;

async function connectStockWs() {
    if (typeof SockJS === 'undefined') {
        if (typeof loadScriptAsync === 'function') {
            await loadScriptAsync('https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js');
        }
    }
    if (typeof Stomp === 'undefined') {
        if (typeof loadScriptAsync === 'function') {
            await loadScriptAsync('https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js');
        }
    }
    if (typeof SockJS === 'undefined' || typeof Stomp === 'undefined') {
        setTimeout(connectStockWs, 3000);
        return;
    }

    const socket = new SockJS('/ws-stock');
    stockStompClient = Stomp.over(socket);
    stockStompClient.debug = null;

    stockStompClient.connect({}, () => {
        stockStompClient.subscribe('/topic/stock/price', msg => {
            const d = JSON.parse(msg.body);
            updateRowPrice(d);
        });
    }, () => {
        // 연결 끊기면 3초 후 재연결
        setTimeout(connectStockWs, 3000);
    });
}

function updateRowPrice(d) {
    const row = document.querySelector('tr[data-code="' + d.code + '"]');
    if (!row) return;

    const priceCell  = row.querySelector('.td-price');
    const badge      = row.querySelector('.td-change .badge');
    const diffCell   = row.querySelector('.td-diff');
    const highCell   = row.querySelector('.td-high');
    const lowCell    = row.querySelector('.td-low');

    if (priceCell) priceCell.textContent = fmtPrice(d.price);
    if (diffCell)  diffCell.textContent  = fmtDiff(d.diff);
    if (highCell)  highCell.textContent  = fmtPrice(d.high);
    if (lowCell)   lowCell.textContent   = fmtPrice(d.low);

    if (badge) {
        const rate = fmtRate(d.rate);
        const prev = badge.textContent;
        badge.textContent = rate.text;
        badge.className = 'badge ' + rate.cls;
        // 변동 시 배지 깜빡 효과
        if (prev !== rate.text) {
            badge.style.transition = 'none';
            badge.style.background = rate.cls === 'up'
                ? 'rgba(240,68,82,0.15)' : 'rgba(37,99,235,0.15)';
            void badge.offsetWidth;
            badge.style.transition = 'background 2s ease-out';
            clearTimeout(badge._flash);
            badge._flash = setTimeout(() => { badge.style.background = ''; }, 200);
        }
    }

    // 상세 패널도 같은 종목이면 함께 갱신
    if (d.code === currentDetailCode) {
        const rate = fmtRate(d.rate);
        document.getElementById('detailPrice').textContent = fmtPrice(d.price);
        const changeEl = document.getElementById('detailChange');
        changeEl.textContent = rate.text;
        changeEl.className = 'hc-main-pnl ' + rate.cls;
    }

    // allStocks 캐시 동기화
    const stock = allStocks.find(s => s.code === d.code);
    if (stock) {
        stock.price      = d.price;
        stock.changeRate = d.rate;
        stock.changeDiff = d.diff;
        stock.high       = d.high;
        stock.low        = d.low;
        stock.volume     = d.volume || '0';
    }
}

/* ── 테이블 행 생성 ── */
function makeRow(stock, rank) {
    const rate = fmtRate(stock.changeRate);
    const isLiked = getStockWatchlist().includes(stock.code || stock.name);
    const key = stock.code || stock.name;
    const initials = (stock.name || '  ').slice(0, 2);

    const tr = document.createElement('tr');
    tr.className = 'stock-row';
    tr.dataset.code = key;
    tr.dataset.name = stock.name;

    const logoHtml = stock.code
        ? '<img src="https://file.alphasquare.co.kr/media/images/stock_logo/kr/' + stock.code + '.png"'
            + ' style="width:100%;height:100%;object-fit:contain;"'
            + ' onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'\';">'
            + '<span style="display:none;font-size:9px;font-weight:700;color:#fff;">' + initials + '</span>'
        : '<span style="font-size:9px;font-weight:700;color:#fff;">' + initials + '</span>';

    tr.innerHTML =
        '<td class="td-rank">'
        + '<div class="rank-inner">'
        + '<button class="like-btn' + (isLiked ? ' liked' : '') + '" data-code="' + key + '">'
        + '<svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>'
        + '</button>'
        + '<span class="rank-num">' + rank + '</span>'
        + '<div class="coin-logo" style="background:#3a3a4a;overflow:hidden;">'
        + logoHtml
        + '</div>'
        + '<div class="coin-name-col">'
        + '<span class="coin-ticker">' + (stock.name || '-') + '</span>'
        + (stock.code ? '<span class="coin-pair">' + stock.code + '</span>' : '')
        + '</div>'
        + '</div>'
        + '</td>'
        + '<td class="td-price">' + fmtPrice(stock.price) + '</td>'
        + '<td class="td-change"><span class="badge ' + rate.cls + '">' + rate.text + '</span></td>'
        + '<td class="td-diff">' + fmtDiff(stock.changeDiff) + '</td>'
        + '<td class="td-high">' + fmtPrice(stock.high) + '</td>'
        + '<td class="td-low">' + fmtPrice(stock.low) + '</td>';

    return tr;
}

/* ── 테이블 렌더링 ── */
function renderTable(stocks) {
    allStocks = stocks;
    const tbody = document.getElementById('stockTableBody');
    tbody.innerHTML = '';
    if (!stocks.length) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:40px;color:var(--text3);font-size:14px;">장 마감 또는 API 수급 제한 중입니다</td></tr>';
        return;
    }
    stocks.forEach((s, i) => tbody.appendChild(makeRow(s, i + 1)));
}

async function refresh() {
    const stocks = await loadStocks();
    renderTable(stocks);
    loadMiniCharts();
    // 필터 변경 후 현재 선택 종목이 새 목록에 없으면 리셋
    if (currentDetailCode && !stocks.find(s => (s.code || s.name) === currentDetailCode)) {
        currentDetailCode = null;
    }
    if (currentDetailCode) {
        const row = document.querySelector('tr[data-code="' + currentDetailCode + '"]');
        if (row) row.classList.add('active');
    } else if (stocks.length > 0) {
        const firstRow = document.querySelector('#stockTableBody .stock-row');
        if (firstRow) {
            firstRow.classList.add('active');
            loadDetailPanel(firstRow.dataset.code, firstRow.dataset.name);
        }
    }
}

/* ── 필터 버튼 ── */
document.querySelectorAll('.filter-group .filter-btn').forEach(btn => {
    btn.addEventListener('click', function () {
        document.querySelectorAll('.filter-group .filter-btn').forEach(b => b.classList.remove('active'));
        this.classList.add('active');
        currentFilter = this.textContent.trim();
        refresh();
    });
});

/* ── 테이블 이벤트 (위임) ── */
document.getElementById('stockTableBody').addEventListener('click', function (e) {
    const likeBtn = e.target.closest('.like-btn');
    if (likeBtn) {
        e.stopPropagation();
        const code = likeBtn.dataset.code;
        toggleStockWatchlistRow(code);
        likeBtn.classList.toggle('liked', getStockWatchlist().includes(code));
        return;
    }
    const row = e.target.closest('.stock-row');
    if (!row) return;
    if (typeof addToRecent === 'function') addToRecent(row.dataset.code);
    location.href = '/stock/view?code=' + encodeURIComponent(row.dataset.code);
});

document.getElementById('stockTableBody').addEventListener('mouseover', function (e) {
    if (e.target.closest('.like-btn')) return;
    const row = e.target.closest('.stock-row');
    if (!row || row.classList.contains('active')) return;
    document.querySelectorAll('.stock-row').forEach(r => r.classList.remove('active'));
    row.classList.add('active');
    clearTimeout(detailChartTimer);
    detailChartTimer = setTimeout(() => {
        loadDetailPanel(row.dataset.code, row.dataset.name);
    }, 250);
});

/* ── 상세 패널 ── */
async function loadDetailPanel(code, name) {
    currentDetailCode = code;

    document.getElementById('detailEmpty').style.display = 'none';
    document.getElementById('detailBody').style.display = 'block';

    document.getElementById('detailName').textContent = name;
    document.getElementById('detailSub').textContent = code || name;

    const logoWrap = document.getElementById('detailLogoWrap');
    const logoImg = document.getElementById('detailLogoImg');
    logoWrap.style.background = '#3a3a4a';
    const existingFb = logoWrap.querySelector('.logo-fb');
    if (existingFb) existingFb.remove();

    if (code && logoImg) {
        logoImg.src = 'https://file.alphasquare.co.kr/media/images/stock_logo/kr/' + code + '.png';
        logoImg.style.cssText = 'display:block;width:100%;height:100%;object-fit:contain;';
        logoImg.onerror = function () {
            this.style.display = 'none';
            const fb = document.createElement('span');
            fb.className = 'logo-fb';
            fb.style.cssText = 'color:#fff;font-size:13px;font-weight:700;';
            fb.textContent = (name || '  ').slice(0, 2);
            logoWrap.appendChild(fb);
        };
    } else {
        if (logoImg) logoImg.style.display = 'none';
        const fb = document.createElement('span');
        fb.className = 'logo-fb';
        fb.style.cssText = 'color:#fff;font-size:13px;font-weight:700;';
        fb.textContent = (name || '  ').slice(0, 2);
        logoWrap.appendChild(fb);
    }

    const stock = allStocks.find(s => (s.code || s.name) === code);
    if (stock) {
        const rate = fmtRate(stock.changeRate);
        document.getElementById('detailPrice').textContent = fmtPrice(stock.price);
        const changeEl = document.getElementById('detailChange');
        changeEl.textContent = rate.text;
        changeEl.className = 'hc-main-pnl ' + rate.cls;
    }

    const wlBtn = document.getElementById('detail-watchlist-btn');
    if (wlBtn) wlBtn.classList.toggle('active', getStockWatchlist().includes(code));

    loadDetailChart(code, name);
}

const chartCache = {};

async function loadMiniCharts() {
    if (miniChartsLoaded) return;
    miniChartsLoaded = true;

    try {
        const res = await fetch('/stock/mini-charts?limit=40');
        const data = await res.json();
        Object.keys(data || {}).forEach(code => {
            if (Array.isArray(data[code]) && data[code].length >= 2) {
                chartCache[code] = data[code];
            }
        });

        if (currentDetailCode && chartCache[currentDetailCode]) {
            drawDetailChart(currentDetailCode, chartCache[currentDetailCode]);
        }
    } catch (e) {}
}

async function loadDetailChart(code, name) {
    // 코스피/코스닥 지수는 개별 차트 없음
    if (name === '코스피' || name === '코스닥') {
        document.getElementById('detailChartArea').innerHTML =
            '<div style="display:flex;align-items:center;justify-content:center;height:100%;color:var(--text3);font-size:13px;">지수는 차트를 지원하지 않습니다</div>';
        return;
    }
    try {
        const searchKey = code || name;
        const candles = chartCache[searchKey];
        if (!candles || candles.length < 2) {
            document.getElementById('detailChartArea').innerHTML =
                '<div style="display:flex;align-items:center;justify-content:center;height:100%;color:var(--text3);font-size:13px;">미니차트 데이터를 준비 중입니다</div>';
            return;
        }

        drawDetailChart(searchKey, candles);
    } catch (e) {}
}

function drawDetailChart(code, candles) {
    if (code !== currentDetailCode || !candles || candles.length < 2) return;

    try {
        const prices = candles.map(c => parseFloat(c.close) || 0).filter(p => p > 0);
        if (prices.length < 2) return;

        const area = document.getElementById('detailChartArea');
        const W = area.clientWidth || 300;
        const H = area.clientHeight || 180;
        const padL = 8, padR = 8, padTop = 10, padBottom = 4;
        const chartH = H - padTop - padBottom;

        const minP = Math.min(...prices);
        const maxP = Math.max(...prices);
        const range = maxP - minP || 1;

        const xOf = i => padL + (i / (prices.length - 1)) * (W - padL - padR);
        const yOf = p => padTop + chartH - ((p - minP) / range) * chartH;

        const linePoints = prices.map((p, i) => xOf(i).toFixed(1) + ',' + yOf(p).toFixed(1)).join(' ');
        const fillPoints = linePoints
            + ' ' + xOf(prices.length - 1).toFixed(1) + ',' + (padTop + chartH)
            + ' ' + padL + ',' + (padTop + chartH);

        const isUp = prices[prices.length - 1] >= prices[0];
        const color = isUp ? '#F04452' : '#2563EB';
        const fillId = 'sg-' + Math.random().toString(36).slice(2, 8);

        area.innerHTML = '<svg width="100%" height="100%" viewBox="0 0 ' + W + ' ' + H + '" preserveAspectRatio="none" style="display:block">'
            + '<defs><linearGradient id="' + fillId + '" x1="0" y1="0" x2="0" y2="1">'
            + '<stop offset="0%" stop-color="' + color + '" stop-opacity="0.25"/>'
            + '<stop offset="100%" stop-color="' + color + '" stop-opacity="0"/>'
            + '</linearGradient></defs>'
            + '<polygon points="' + fillPoints + '" fill="url(#' + fillId + ')"/>'
            + '<polyline points="' + linePoints + '" fill="none" stroke="' + color + '" stroke-width="1.5" stroke-linejoin="round"/>'
            + '</svg>';
    } catch (e) {}
}

/* ── 시장 지수 티커 바 ── */
function buildSparkline(prices, isUp) {
    if (!prices || prices.length < 2) {
        const pts = isUp ? '0,38 15,28 30,20 45,12 60,4' : '0,4 15,12 30,20 45,28 60,38';
        return '<polyline points="' + pts + '" fill="none" stroke="' + (isUp ? '#F04452' : '#2563EB') + '" stroke-width="1"/>';
    }
    const W = 60, H = 40, pad = 2;
    const min = Math.min(...prices), max = Math.max(...prices);
    const range = max - min || 1;
    const xOf = i => pad + (i / (prices.length - 1)) * (W - pad * 2);
    const yOf = p => H - pad - ((p - min) / range) * (H - pad * 2);
    const linePoints = prices.map((p, i) => xOf(i).toFixed(1) + ',' + yOf(p).toFixed(1)).join(' ');
    const fillPoints = linePoints
        + ' ' + xOf(prices.length - 1).toFixed(1) + ',' + (H - pad)
        + ' ' + xOf(0).toFixed(1) + ',' + (H - pad);
    const color = isUp ? '#F04452' : '#2563EB';
    const gradId = 'sg' + Math.random().toString(36).slice(2, 6);
    return '<defs><linearGradient id="' + gradId + '" x1="0" y1="0" x2="0" y2="1">'
        + '<stop offset="0%" stop-color="' + color + '" stop-opacity="0.3"/>'
        + '<stop offset="100%" stop-color="' + color + '" stop-opacity="0"/>'
        + '</linearGradient></defs>'
        + '<polygon points="' + fillPoints + '" fill="url(#' + gradId + ')"/>'
        + '<polyline points="' + linePoints + '" fill="none" stroke="' + color + '" stroke-width="1" stroke-linejoin="round"/>';
}

async function loadMarketIndex() {
    try {
        const list = await fetch('/api/market-index').then(r => r.json());
        const container = document.getElementById('marketIndexItems');
        if (!container || !list.length) return;
        container.innerHTML = list.map((item, i) => {
            const cls = item.up ? 'up' : 'down';
            const sparkSvg = buildSparkline(item.prices, item.up);
            const delay = (i * 0.07).toFixed(2) + 's';
            return '<div class="ticker-item" style="animation-delay:' + delay + '">'
                + '<div class="ticker-item-chart">'
                + '<svg viewBox="0 0 60 40" preserveAspectRatio="none">' + sparkSvg + '</svg>'
                + '</div>'
                + '<div class="ticker-item-info">'
                + '<div class="ticker-item-name">' + item.name + '</div>'
                + '<div class="ticker-item-price">' + item.price
                + ' <span class="' + cls + '">' + (item.change === '-' ? '-' : item.change + ' (' + item.changeRate + '%)') + '</span>'
                + '</div></div></div>';
        }).join('');
    } catch (e) {}
}

document.addEventListener('DOMContentLoaded', function () {
    refresh();
    loadMarketIndex();
    connectStockWs();
    setInterval(loadMarketIndex, 30000);

    const tickerBtn = document.getElementById('tickerArrowBtn');
    if (tickerBtn) {
        tickerBtn.addEventListener('click', function () {
            const items = document.getElementById('marketIndexItems');
            const maxScroll = items.scrollWidth - items.clientWidth;
            if (items.scrollLeft >= maxScroll - 4) {
                items.scrollTo({ left: 0, behavior: 'smooth' });
            } else {
                items.scrollBy({ left: 300, behavior: 'smooth' });
            }
        });
    }

    const panel = document.getElementById('detailPanel');
    if (panel) {
        panel.addEventListener('mouseenter', () => panel.classList.add('scrollbar-visible'));
        panel.addEventListener('mouseleave', () => panel.classList.remove('scrollbar-visible'));
    }
    const tableWrap = document.querySelector('.stock-table-wrap');
    if (tableWrap) {
        tableWrap.addEventListener('mouseenter', () => tableWrap.classList.add('scrollbar-visible'));
        tableWrap.addEventListener('mouseleave', () => tableWrap.classList.remove('scrollbar-visible'));
    }
});
