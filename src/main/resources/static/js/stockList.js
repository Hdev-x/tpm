/* =====================================================
   stockList.js - 주식 리스트 데이터 로딩 및 UI 렌더링
   ===================================================== */

let allStocks = [];
let currentFilter = '전체';
let currentDetailCode = null;

/* ── 관심종목 (로컬스토리지) ── */
function getWatchlist() {
    try { return JSON.parse(localStorage.getItem('stock_watchlist') || '[]'); } catch { return []; }
}
function toggleWatchlist(code) {
    const list = getWatchlist();
    const idx = list.indexOf(code);
    if (idx >= 0) list.splice(idx, 1);
    else list.push(code);
    localStorage.setItem('stock_watchlist', JSON.stringify(list));
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
    const n = parseFloat(val.toString().replace(/[+%]/g, ''));
    if (isNaN(n)) return { text: val, cls: 'neutral' };
    return { text: (n >= 0 ? '+' : '') + n.toFixed(2) + '%', cls: n >= 0 ? 'up' : 'down' };
}

function fmtDiff(val) {
    if (!val || val === '-') return '-';
    const n = parseFloat(val.toString().replace(/,/g, '').replace(/[^0-9.\-]/g, ''));
    if (isNaN(n) || n === 0) return '-';
    return (n > 0 ? '+' : '') + n.toLocaleString() + '원';
}

/* ── API 데이터 정규화 ── */
function normalizeStock(item) {
    if (item.hts_kor_isnm !== undefined) {
        // rank API 응답
        return {
            name: item.hts_kor_isnm || '-',
            code: item.mkstat_shrn_iscd || '',
            price: item.mkstat_prpr || '-',
            changeRate: item.prdy_ctrt || '-',
            changeDiff: item.prdy_vrss || '-',
        };
    }
    if (item.code !== undefined) {
        // db-list API 응답
        return {
            name: item.name || '-',
            code: item.code || '',
            price: '-',
            changeRate: '-',
            changeDiff: '-',
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
        const res = await fetch('/stock/db-list');
        const data = await res.json();
        return (Array.isArray(data) ? data : []).map(normalizeStock);
    } catch (e) {
        return [];
    }
}

/* ── 보이는 행 현재가 조회 ── */
let priceObserver = null;
const fetchingCodes = new Set();

function observeVisibleRows() {
    if (priceObserver) priceObserver.disconnect();
    fetchingCodes.clear();

    priceObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (!entry.isIntersecting) return;
            const row = entry.target;
            const code = row.dataset.code;
            if (!code || fetchingCodes.has(code)) return;
            fetchingCodes.add(code);
            fetchRowPrice(row, code);
        });
    }, { threshold: 0.1 });

    document.querySelectorAll('#stockTableBody .stock-row').forEach(row => {
        priceObserver.observe(row);
    });
}

async function fetchRowPrice(row, code) {
    try {
        const res = await fetch('/stock/ticker?code=' + encodeURIComponent(code));
        if (!res.ok) return;
        const json = await res.json();
        const out = json.output;
        if (!out) return;

        const priceCell = row.querySelector('.td-price');
        const changeCell = row.querySelector('.td-change .badge');
        const diffCell = row.querySelector('.td-diff');

        if (priceCell) priceCell.textContent = fmtPrice(out.stck_prpr);

        if (changeCell && out.prdy_ctrt) {
            const rate = fmtRate(out.prdy_ctrt);
            changeCell.textContent = rate.text;
            changeCell.className = 'badge ' + rate.cls;
        }

        if (diffCell && out.prdy_vrss) {
            diffCell.textContent = fmtDiff(out.prdy_vrss);
        }

        // allStocks 캐시도 업데이트
        const stock = allStocks.find(s => s.code === code);
        if (stock) {
            stock.price = out.stck_prpr;
            stock.changeRate = out.prdy_ctrt;
            stock.changeDiff = out.prdy_vrss;
        }
    } catch (e) {}
}

/* ── 테이블 행 생성 ── */
function makeRow(stock, rank) {
    const rate = fmtRate(stock.changeRate);
    const isLiked = getWatchlist().includes(stock.code || stock.name);
    const key = stock.code || stock.name;
    const initials = (stock.name || '  ').slice(0, 2);

    const tr = document.createElement('tr');
    tr.className = 'stock-row';
    tr.dataset.code = key;
    tr.dataset.name = stock.name;

    tr.innerHTML =
        '<td class="td-rank">'
        + '<div class="rank-inner">'
        + '<button class="like-btn' + (isLiked ? ' liked' : '') + '" data-code="' + key + '">'
        + '<svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>'
        + '</button>'
        + '<span class="rank-num">' + rank + '</span>'
        + '<div class="coin-logo" style="background:#3a3a4a;">'
        + '<span style="font-size:9px;font-weight:700;color:#fff;">' + initials + '</span>'
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
        + '<td class="td-high">-</td>'
        + '<td class="td-low">-</td>';

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
    if (currentFilter === '전체') observeVisibleRows();
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
        toggleWatchlist(code);
        likeBtn.classList.toggle('liked', getWatchlist().includes(code));
        return;
    }
    const row = e.target.closest('.stock-row');
    if (!row) return;
    location.href = '/stock/view?code=' + encodeURIComponent(row.dataset.code);
});

document.getElementById('stockTableBody').addEventListener('mouseover', function (e) {
    if (e.target.closest('.like-btn')) return;
    const row = e.target.closest('.stock-row');
    if (!row || row.classList.contains('active')) return;
    document.querySelectorAll('.stock-row').forEach(r => r.classList.remove('active'));
    row.classList.add('active');
    loadDetailPanel(row.dataset.code, row.dataset.name);
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
    if (logoImg) logoImg.style.display = 'none';
    logoWrap.style.background = '#3a3a4a';
    const existingFb = logoWrap.querySelector('.logo-fb');
    if (existingFb) existingFb.remove();
    const fb = document.createElement('span');
    fb.className = 'logo-fb';
    fb.style.cssText = 'color:#fff;font-size:13px;font-weight:700;';
    fb.textContent = (name || '  ').slice(0, 2);
    logoWrap.appendChild(fb);

    const stock = allStocks.find(s => (s.code || s.name) === code);
    if (stock) {
        const rate = fmtRate(stock.changeRate);
        document.getElementById('detailPrice').textContent = fmtPrice(stock.price);
        const changeEl = document.getElementById('detailChange');
        changeEl.textContent = rate.text;
        changeEl.className = 'hc-main-pnl ' + rate.cls;
    }

    const wlBtn = document.getElementById('detail-watchlist-btn');
    if (wlBtn) wlBtn.classList.toggle('active', getWatchlist().includes(code));

    loadDetailChart(code, name);
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
        const res = await fetch('/stock/chart?code=' + encodeURIComponent(searchKey) + '&range=1y');
        const json = await res.json();
        const candles = json.output2 || [];
        if (candles.length < 2) return;

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

/* ── 초기화 ── */
document.addEventListener('DOMContentLoaded', function () {
    refresh();
    loadMarketIndex();
    setInterval(refresh, 15000);
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
