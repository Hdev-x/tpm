/* ====================================================
   [전역 상태 읽기]
   이 값들은 여러 함수가 함께 사용하는 화면 상태입니다.
   allTickers는 API로 받은 전체 코인 목록, renderIndex는 현재 몇 개 행까지 그렸는지,
   logoMap은 티커(BTC 등)와 로고 이미지 URL을 연결하는 객체입니다.
   ==================================================== */
let allTickers = [];
let renderIndex = 0;
const PAGE_SIZE = 50;
let logoMap = {};
let currentSort = '거래대금';

function calcChange(t) {
    const open = parseFloat(t.openUtc);
    return open > 0 ? (parseFloat(t.lastPr) - open) / open * 100 : parseFloat(t.change24h) * 100;
}

function getDisplayChange(t) {
    return currentTimeFilter === '1일' ? parseFloat(t.change24h) * 100 : calcChange(t);
}

/* [DOM 연결 읽기]
   .main-tab 버튼의 data-tab 값과 .tab-content의 id를 연결해 탭 화면을 바꿉니다.
   예: data-tab="realtime" -> id="tab-realtime" */
document.querySelectorAll('.main-tab').forEach(tab => {
    tab.addEventListener('click', function () {
        document.querySelectorAll('.main-tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.add('hidden'));
        this.classList.add('active');
        document.getElementById('tab-' + this.dataset.tab).classList.remove('hidden');
    });
});

/* [콜백 읽기]
   .filter-group마다 내부 버튼을 따로 관리합니다.
   그래서 마켓 필터의 active 변경이 정렬 필터 버튼까지 지우지 않습니다. */
document.querySelectorAll('.filter-group').forEach(group => {
    group.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', function () {
            group.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
        });
    });
});

/**
 * [함수 선언부 읽기]
 * function fmtNum(n)
 * 큰 거래대금 숫자를 K/M/B 단위 문자열로 줄여서 테이블에 표시합니다.
 *
 * @param {number} n 줄여서 표시할 숫자
 * @return {string} 축약된 숫자 문자열
 */
function fmtNum(n) {
    if (n >= 1_000_000_000) return (n / 1_000_000_000).toFixed(2) + 'B';
    if (n >= 1_000_000) return (n / 1_000_000).toFixed(2) + 'M';
    if (n >= 1_000) return (n / 1_000).toFixed(2) + 'K';
    return n.toFixed(2);
}

/**
 * [실행 흐름]
 * CoinGecko에서 여러 페이지의 코인 목록을 가져와 logoMap을 채웁니다.
 * Promise.all()은 여러 fetch 요청을 동시에 실행하고, 실패한 페이지는 빈 배열로 처리합니다.
 *
 * @return {Promise<void>} logoMap 전역 객체를 갱신합니다.
 */
async function loadLogoMap() {
    const pages = [1, 2, 3];
    const results = await Promise.all(
        pages.map(p => fetch(`https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&per_page=250&page=${p}`)
            .then(r => r.json()).catch(() => []))
    );
    results.flat().forEach(coin => {
        if (coin && coin.symbol && coin.image) {
            logoMap[coin.symbol.toUpperCase()] = coin.image;
        }
    });
}

/**
 * [실행 흐름]
 * Bitget REST API에서 현재 현물 ticker 목록을 가져옵니다.
 * 반환된 data 배열은 initializeCoinList()에서 필터/정렬 후 테이블에 사용됩니다.
 *
 * @return {Promise<Array>} Bitget ticker 배열
 */
async function loadTickers() {
    const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers');
    const json = await res.json();
    return json.data || [];
}

/**
 * [함수 선언부 읽기]
 * function makeRow(t, rank)
 * ticker 객체 하나를 받아 table 안에 들어갈 tr DOM 요소를 만듭니다.
 *
 * [DOM 연결]
 * tr.dataset.symbol은 HTML의 data-symbol 속성이 됩니다.
 * 이후 WebSocket 업데이트와 mouseover/click 이벤트가 이 값을 기준으로 행을 찾습니다.
 *
 * @param {Object} t Bitget ticker 데이터
 * @param {number} rank 화면에 보여줄 순위
 * @return {HTMLTableRowElement} tbody에 붙일 행 요소
 */
function makeRow(t, rank) {
    const ticker = t.symbol.replace(/USDT$/, '').replace(/USDC$/, '').replace('_SPBL', '') || t.symbol;
    const change = getDisplayChange(t);
    const cls = change >= 0 ? 'up' : 'down';
    const sign = change >= 0 ? '+' : '';
    const logoUrl = logoMap[ticker] || 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/' + ticker.toLowerCase() + '.png';
    const fallback = ticker.slice(0, 3);
    const market = t.symbol.endsWith('USDC') ? '/ USDC' : '/ USDT';

    // [코드 읽기] createElement('tr')은 문자열이 아니라 실제 테이블 행 DOM 노드를 만듭니다.
    const isLiked = getWatchlist().includes(t.symbol);
    const tr = document.createElement('tr');
    tr.className = 'stock-row';
    tr.dataset.symbol = t.symbol;
    tr.innerHTML =
        '<td class="td-rank">'
        + '<div class="rank-inner">'
        + '<button class="like-btn' + (isLiked ? ' liked' : '') + '"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>'
        + '<span class="rank-num">' + rank + '</span>'
        + '<div class="coin-logo">'
        + '<img src="' + logoUrl + '" alt="' + ticker + '"'
        + ' onerror="this.parentElement.style.background=\'#3a3a4a\';this.parentElement.textContent=\'' + fallback + '\'">'
        + '</div>'
        + '<div class="coin-name-col">'
        + '<span class="coin-ticker">' + ticker + '</span>'
        + '<span class="coin-pair">' + market + '</span>'
        + '</div>'
        + '</div>'
        + '</td>'
        + '<td class="td-price">$' + parseFloat(t.lastPr).toLocaleString() + '</td>'
        + '<td class="td-change"><span class="badge ' + cls + '">' + sign + change.toFixed(2) + '%</span></td>'
        + '<td class="td-quote">' + fmtNum(parseFloat(t.quoteVolume)) + '</td>'
        + '<td class="td-high">' + parseFloat(t.high24h).toLocaleString() + '</td>'
        + '<td class="td-low">' + parseFloat(t.low24h).toLocaleString() + '</td>';
    return tr;
}

/**
 * [DOM 연결 읽기]
 * id="stockTableBody"인 tbody를 비우고 ticker 배열을 처음부터 다시 렌더링합니다.
 * 필터나 정렬이 바뀔 때는 기존 행을 모두 지우는 이 함수가 적합합니다.
 *
 * @param {Array} tickers 화면에 새로 그릴 ticker 배열
 */
function renderTable(tickers) {
    const tbody = document.getElementById('stockTableBody');
    tbody.innerHTML = '';
    tickers.forEach((t, i) => tbody.appendChild(makeRow(t, i + 1)));
    const sentinel = document.createElement('tr');
    sentinel.id = 'scroll-sentinel';
    sentinel.innerHTML = '<td colspan="6" style="height:1px;padding:0;"></td>';
    tbody.appendChild(sentinel);
}

/**
 * [실행 흐름]
 * 무한 스크롤에서 다음 페이지의 행만 tbody 뒤에 추가합니다.
 * sentinel 행은 스크롤 끝에 남겨두는 기준점 역할을 하므로 새 행을 붙이기 전에 제거하고 다시 붙입니다.
 *
 * @param {Array} tickers 추가로 표시할 ticker 배열
 */
function appendRows(tickers) {
    const tbody = document.getElementById('stockTableBody');
    const old = document.getElementById('scroll-sentinel');
    if (old) old.remove();
    tickers.forEach((t, i) => tbody.appendChild(makeRow(t, renderIndex - tickers.length + i + 1)));
    const sentinel = document.createElement('tr');
    sentinel.id = 'scroll-sentinel';
    sentinel.innerHTML = '<td colspan="6" style="height:1px;padding:0;"></td>';
    tbody.appendChild(sentinel);
}

let listWs = null;

/**
 * [함수 선언부 읽기]
 * function connectListWs(symbols)
 * 보이는 코인 목록을 Bitget WebSocket ticker 채널에 구독합니다.
 *
 * [실행 흐름]
 * 1. 이전 WebSocket이 있으면 닫습니다.
 * 2. symbols 배열을 구독 요청 객체 배열로 바꿉니다.
 * 3. 수신 메시지의 symbol로 tr[data-symbol="..."] 행을 찾아 가격과 등락률을 갱신합니다.
 * 4. 현재 우측 상세 패널의 symbol과 같으면 상세 가격도 함께 갱신합니다.
 *
 * @param {string[]} symbols 실시간 가격을 받을 코인 심볼 목록
 */
function connectListWs(symbols) {
    if (listWs) listWs.close();
    const ws = new WebSocket('wss://ws.bitget.com/v2/ws/public');
    listWs = ws;

    ws.onopen = () => {
        // [콜백 읽기] map의 s는 symbols 배열에서 하나씩 전달되는 코인 심볼입니다.
        const args = symbols.map(s => ({ instType: 'SPOT', channel: 'ticker', instId: s }));
        ws.send(JSON.stringify({ op: 'subscribe', args }));
        setInterval(() => ws.readyState === 1 && ws.send('ping'), 20000);
    };

    ws.onmessage = (e) => {
        if (e.data === 'pong') return;
        let msg;
        try { msg = JSON.parse(e.data); } catch { return; }
        if (!msg.data || !msg.arg || msg.arg.channel !== 'ticker') return;

        const symbol = msg.arg.instId;
        const price = parseFloat(msg.data[0].lastPr);
        const openUtc = parseFloat(msg.data[0].openUtc);
        const changeUtc = openUtc > 0 ? (price - openUtc) / openUtc * 100 : (parseFloat(msg.data[0].change24h) * 100);
        const change = currentTimeFilter === '1일' ? parseFloat(msg.data[0].change24h) * 100 : changeUtc;

        // [DOM 연결 읽기] makeRow()에서 저장한 data-symbol과 WebSocket 메시지의 symbol을 맞춰 행을 찾습니다.
        const row = document.querySelector(`tr[data-symbol="${symbol}"]`);
        if (!row) return;

        const cls = change >= 0 ? 'up' : 'down';
        const sign = change >= 0 ? '+' : '';
        const badge = row.querySelector('.badge');
        const prevChange = badge.textContent;
        const newChange = sign + change.toFixed(2) + '%';
        row.querySelector('.td-price').textContent = '$' + price.toLocaleString();
        if (currentTimeFilter === '실시간' || currentTimeFilter === '1일') {
            badge.textContent = newChange;
            badge.className = 'badge ' + cls;
            if (prevChange !== newChange) {
                badge.style.transition = 'none';
                badge.style.background = cls === 'up' ? 'rgba(240, 68, 82, 0.15)' : 'rgba(37, 99, 235, 0.15)';
                void badge.offsetWidth;
                badge.style.transition = 'background 2s ease-out';
                clearTimeout(badge._flashTimer);
                badge._flashTimer = setTimeout(() => {
                    badge.style.background = '';
                }, 200);
            }
        }
        row.querySelector('.td-quote').textContent = fmtNum(parseFloat(msg.data[0].quoteVolume));
        row.querySelector('.td-high').textContent = parseFloat(msg.data[0].high24h).toLocaleString();
        row.querySelector('.td-low').textContent = parseFloat(msg.data[0].low24h).toLocaleString();

        if (symbol === currentDetailSymbol) {
            const sign = change >= 0 ? '+' : '';
            const cls = change >= 0 ? 'up' : 'down';
            document.getElementById('detailPrice').textContent = '$' + price.toLocaleString();
            const changeEl = document.getElementById('detailChange');
            changeEl.textContent = sign + change.toFixed(2) + '%';
            changeEl.className = 'hc-main-pnl ' + cls;
        }
    };

    ws.onclose = () => {
        if (ws === listWs) setTimeout(() => connectListWs(symbols), 3000);
    };
}

/* [실행 흐름]
   .stock-table-wrap은 실제 스크롤 컨테이너입니다.
   사용자가 아래쪽 200px 근처까지 내리면 다음 PAGE_SIZE만큼 행을 추가하고 WebSocket 구독 범위도 늘립니다. */
document.querySelector('.stock-table-wrap').addEventListener('scroll', function () {
    if (renderIndex >= allTickers.length) return;
    if (this.scrollTop + this.clientHeight >= this.scrollHeight - 200) {
        const next = allTickers.slice(renderIndex, renderIndex + PAGE_SIZE);
        renderIndex += PAGE_SIZE;
        appendRows(next);
        connectListWs(allTickers.slice(0, renderIndex).map(d => d.symbol));
    }
});

let currentMarket = '전체';

/**
 * [함수 선언부 읽기]
 * function applyFilters()
 * 현재 선택된 마켓/정렬 상태를 allTickers에 적용하고 첫 페이지를 다시 렌더링합니다.
 */
function applyFilters() {
    // [주의] allTickers 원본은 유지하고, 조건에 맞는 filtered 배열만 화면에 사용합니다.
    let filtered = allTickers;
    if (currentMarket === 'USDT') filtered = allTickers.filter(t => t.symbol.endsWith('USDT'));
    if (currentMarket === 'USDC') filtered = allTickers.filter(t => t.symbol.endsWith('USDC'));
    if (sortFns[currentSort]) filtered = [...filtered].sort(sortFns[currentSort]);
    renderIndex = 0;
    renderTable(filtered.slice(0, PAGE_SIZE));
    renderIndex = PAGE_SIZE;
    connectListWs(filtered.slice(0, PAGE_SIZE).map(d => d.symbol));
}

document.querySelectorAll('.filter-group:nth-child(1) .filter-btn').forEach(btn => {
    btn.addEventListener('click', function () {
        // [이벤트 객체 읽기] 여기서 this는 클릭된 마켓 필터 버튼입니다.
        currentMarket = this.textContent.trim();
        applyFilters();
    });
});

const sortFns = {
    '거래대금': (a, b) => parseFloat(b.quoteVolume) - parseFloat(a.quoteVolume),
    '급상승': (a, b) => getDisplayChange(b) - getDisplayChange(a),
    '급하락': (a, b) => getDisplayChange(a) - getDisplayChange(b),
};

document.querySelectorAll('.filter-group:nth-child(3) .filter-btn').forEach(btn => {
    btn.addEventListener('click', function () {
        const label = this.textContent.trim();

        // [주의] sortFns에 없는 버튼은 아직 동작이 없는 버튼이므로 정렬을 실행하지 않습니다.
        if (!sortFns[label]) return;
        currentSort = label;
        applyFilters();
    });
});

let currentTimeFilter = '실시간';

/* [실행 흐름]
   시간 필터 버튼은 현재 표시된 행의 등락률 배지만 다시 계산합니다.
   1주일 이상 버튼은 JSP에서 disabled 상태라 클릭되지 않습니다. */
document.querySelectorAll('.filter-group:nth-child(5) .filter-btn').forEach(btn => {
    btn.addEventListener('click', function () {
        currentTimeFilter = this.textContent.trim();
        applyFilters();
    });
});

/* [이벤트 위임 읽기]
   like-btn은 JS가 동적으로 만든 행 안에 있으므로, 버튼마다 이벤트를 붙이지 않고
   부모 tbody에서 click을 받은 뒤 e.target.closest('.like-btn')로 실제 하트 버튼을 찾습니다. */
document.getElementById('stockTableBody').addEventListener('click', function (e) {
    const btn = e.target.closest('.like-btn');
    if (!btn) return;
    e.stopPropagation();
    const symbol = btn.closest('tr').dataset.symbol;
    toggleWatchlist(symbol);
    btn.classList.toggle('liked', getWatchlist().includes(symbol));
});

/* [실행 흐름]
   테이블 행에 마우스를 올리면 active 행을 바꾸고 우측 상세 패널을 미리 갱신합니다.
   closest('.stock-row')는 마우스가 td/span/img 위에 있어도 가장 가까운 tr 행을 찾아줍니다. */
document.getElementById('stockTableBody').addEventListener('mouseover', function (e) {
    if (e.target.closest('.like-btn')) return;
    const row = e.target.closest('.stock-row');
    if (!row || row.classList.contains('active')) return;

    document.querySelectorAll('.stock-row').forEach(r => r.classList.remove('active'));
    row.classList.add('active');
    loadDetailChart(row.dataset.symbol);
});

/* [실행 흐름]
   행 자체를 클릭하면 차트 상세 페이지로 이동합니다.
   하트 버튼 클릭은 위 이벤트에서 처리되므로 여기서는 무시합니다. */
document.getElementById('stockTableBody').addEventListener('click', function (e) {
    if (e.target.closest('.like-btn')) return;
    const row = e.target.closest('.stock-row');
    if (!row) return;

    const symbol = row.dataset.symbol;
    addToRecent(symbol);
    location.href = '/coin/chart?symbol=' + symbol;
});

let currentDetailSymbol = null;

/**
 * [함수 선언부 읽기]
 * async function loadDetailChart(symbol)
 * 선택된 코인의 주봉 데이터를 가져와 우측 상세 패널을 갱신합니다.
 *
 * [실행 흐름]
 * 1. Bitget 주봉 캔들을 fetch합니다.
 * 2. 종가/거래량 배열을 만들고 SVG 좌표로 변환합니다.
 * 3. detailChartArea에 SVG 차트를 삽입합니다.
 * 4. detailName/detailPrice/detailChange 등 JSP의 id 요소를 업데이트합니다.
 *
 * @param {string} symbol Bitget 코인 심볼
 * @return {Promise<void>} 상세 패널 DOM을 갱신합니다.
 */
async function loadDetailChart(symbol) {
    currentDetailSymbol = symbol;
    const ticker = symbol.replace(/USDT$/, '').replace(/USDC$/, '') || symbol;

    const res = await fetch(`https://api.bitget.com/api/v2/spot/market/candles?symbol=${symbol}&granularity=1Wutc&limit=52`);
    const json = await res.json();
    if (!json.data || json.data.length === 0) return;

    const candles = json.data.map(d => ({
        ts: parseInt(d[0]),
        close: parseFloat(d[4]),
        vol: parseFloat(d[5]),
    })).reverse();

    const prices = candles.map(d => d.close);
    const vols = candles.map(d => d.vol);

    const area = document.getElementById('detailChartArea');
    const W = area.clientWidth || 300;
    const H = area.clientHeight || 180;
    const padL = 8, padR = 8, padTop = 10, padBottom = 22;
    const volH = 16;
    const chartH = H - padTop - padBottom - volH - 4;

    const logPrices = prices.map(p => Math.log(p));
    const logMin = Math.min(...logPrices);
    const logMax = Math.max(...logPrices);
    const logRange = logMax - logMin || 1;
    const maxVol = Math.max(...vols);

    const xOf = i => padL + (i / (prices.length - 1)) * (W - padL - padR);
    const yOf = p => padTop + chartH - ((Math.log(p) - logMin) / logRange) * chartH;

    // [콜백 읽기] prices.map의 p는 종가, i는 순번입니다. 각 가격을 SVG polyline의 "x,y" 문자열로 바꿉니다.
    const linePoints = prices.map((p, i) => `${xOf(i).toFixed(1)},${yOf(p).toFixed(1)}`).join(' ');
    const fillPoints = linePoints + ` ${xOf(prices.length - 1).toFixed(1)},${(padTop + chartH).toFixed(1)} ${padL},${(padTop + chartH).toFixed(1)}`;

    const isUp = prices[prices.length - 1] >= prices[0];
    const color = isUp ? '#F04452' : '#2563EB';
    const fillId = 'grad-' + symbol.replace(/[^a-zA-Z0-9]/g, '');

    // [코드 읽기] 거래량 배열을 SVG rect 문자열로 바꿔 차트 하단 막대 그래프를 만듭니다.
    const barW = Math.max(1, (W - padL - padR) / prices.length - 1);
    const volBars = vols.map((v, i) => {
        const x = xOf(i) - barW / 2;
        const bh = (v / maxVol) * volH;
        const y = H - padBottom - bh;
        return `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${barW.toFixed(1)}" height="${bh.toFixed(1)}" fill="#555" opacity="0.5"/>`;
    }).join('');

    const labelIdxs = [0, Math.floor(prices.length / 2), prices.length - 1];

    // [DOM 연결 읽기] detailChartArea의 기존 내용을 새 SVG 문자열로 교체합니다.
    area.innerHTML = `
        <svg width="100%" height="calc(100% - 18px)" viewBox="0 0 ${W} ${H}" preserveAspectRatio="none" style="display:block">
            <defs>
                <linearGradient id="${fillId}" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="${color}" stop-opacity="0.25"/>
                    <stop offset="100%" stop-color="${color}" stop-opacity="0"/>
                </linearGradient>
            </defs>
            <polygon points="${fillPoints}" fill="url(#${fillId})"/>
            <polyline points="${linePoints}" fill="none" stroke="${color}" stroke-width="1.5" stroke-linejoin="round"/>
            ${volBars}
        </svg>
        <div style="display:flex;justify-content:space-between;padding:2px 8px 0;font-size:12px;color:#555;">
            ${labelIdxs.map(i => {
        const d = new Date(candles[i].ts);
        return `<span>${d.getFullYear() % 100}년 ${d.getMonth() + 1}월</span>`;
    }).join('')}
        </div>`;

    document.getElementById('detailEmpty').style.display = 'none';
    document.getElementById('detailBody').style.display = 'block';

    const wlBtn = document.getElementById('detail-watchlist-btn');
    if (wlBtn) wlBtn.classList.toggle('active', getWatchlist().includes(symbol));
    document.getElementById('detailName').textContent = ticker;
    document.getElementById('detailSub').textContent = symbol.endsWith('USDC') ? ticker + ' / USDC' : ticker + ' / USDT';

    // [실행 흐름] 이미지 로딩에 실패하면 로고 대신 티커 앞 3글자를 원형 배경 안에 표시합니다.
    const logoWrap = document.getElementById('detailLogoWrap');
    const logoImg = document.getElementById('detailLogoImg');
    const logoUrl = logoMap[ticker] || 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/' + ticker.toLowerCase() + '.png';
    const fallback = ticker.slice(0, 3);
    const logoFallbackColor = typeof coinLogoColor === 'function' ? coinLogoColor(ticker) : '#3a3a4a';
    logoWrap.style.background = '';
    logoImg.style.display = '';
    const existingFallback = logoWrap.querySelector('.logo-fb');
    if (existingFallback) existingFallback.remove();
    if (!logoWrap.contains(logoImg)) logoWrap.appendChild(logoImg);
    logoImg.src = logoUrl;
    logoImg.alt = ticker;
    logoImg.onerror = function () {
        logoWrap.style.background = logoFallbackColor;
        this.style.display = 'none';
        const fb = document.createElement('span');
        fb.className = 'logo-fb';
        fb.style.cssText = 'color:#fff;font-size:11px;font-weight:700;';
        fb.textContent = fallback;
        logoWrap.appendChild(fb);
    };

    const t = allTickers.find(t => t.symbol === symbol);
    if (t) {
        const change = currentTimeFilter === '1일' ? parseFloat(t.change24h) * 100 : calcChange(t);
        const sign = change >= 0 ? '+' : '';
        const cls = change >= 0 ? 'up' : 'down';
        document.getElementById('detailPrice').textContent = parseFloat(t.lastPr).toLocaleString() + ' USDT';
        const changeEl = document.getElementById('detailChange');
        changeEl.textContent = sign + change.toFixed(2) + '%';
        changeEl.className = 'hc-main-pnl ' + cls;
    }

    connectChat(symbol);
}

async function initializeCoinList() {
    const [, data] = await Promise.all([loadLogoMap(), loadTickers()]);
    const filtered = data
        .filter(t => t.symbol.endsWith('USDT') || t.symbol.endsWith('USDC'))
        .sort((a, b) => parseFloat(b.quoteVolume) - parseFloat(a.quoteVolume));

    allTickers = filtered;
    renderIndex = 0;
    renderTable(allTickers.slice(0, PAGE_SIZE));
    renderIndex = PAGE_SIZE;
    connectListWs(allTickers.slice(0, PAGE_SIZE).map(d => d.symbol));

    if (allTickers.length === 0) return;

    const firstRow = document.querySelector('#stockTableBody .stock-row');
    if (firstRow) firstRow.classList.add('active');
    loadDetailChart(allTickers[0].symbol);
}

/* ====================================================
   실시간 댓글 - WebSocket(STOMP)
   ==================================================== */
let listStompClient = null;

function connectChat(symbol) {
    if (listStompClient && listStompClient.connected) {
        listStompClient.disconnect();
    }

    const socket = new SockJS('/ws-coin');
    listStompClient = Stomp.over(socket);
    listStompClient.debug = null;

    listStompClient.connect({}, () => {
        listStompClient.subscribe('/topic/coin/' + symbol, msg => {
            const dto = JSON.parse(msg.body);
            appendListChatMsg(dto.username, dto.content, dto.createdAt, true, dto.imageUrl, dto.profileFileName);
        });
        loadListChatHistory(symbol);
    });
}

function loadListChatHistory(symbol) {
    fetch('/coin/comments/' + symbol)
        .then(r => r.json())
        .then(list => {
            const msgs = document.getElementById('chat-messages');
            msgs.innerHTML = '';
            if (!list.length) {
                msgs.innerHTML = '<div class="chat-empty"><span class="chat-empty-icon">💬</span><span>첫 댓글을 남겨보세요</span></div>';
                return;
            }
            list.forEach(dto => appendListChatMsg(dto.username, dto.content, dto.createdAt, false, dto.imageUrl, dto.profileFileName));
        });
}

function cmAvatarColor(name) {
    const palette = ['#4caf50','#2196f3','#e91e63','#ff9800','#9c27b0','#00bcd4','#f44336','#3f51b5','#009688','#795548'];
    let h = 0;
    for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) & 0x7fffffff;
    return palette[h % palette.length];
}

function cmRelTime(createdAt) {
    if (!createdAt) return '';
    const diff = Date.now() - new Date(createdAt).getTime();
    const m = Math.floor(diff / 60000);
    if (m < 1) return '방금';
    if (m < 60) return m + '분';
    const h = Math.floor(m / 60);
    if (h < 24) return h + '시간';
    return Math.floor(h / 24) + '일';
}

function appendListChatMsg(username, content, createdAt, scroll = true, imageUrl = null, profileFileName = null) {
    const msgs = document.getElementById('chat-messages');
    if (!msgs) return;
    const empty = msgs.querySelector('.chat-empty');
    if (empty) empty.remove();

    const safe = s => s.replace(/</g, '&lt;');
    const color = cmAvatarColor(username);
    const initial = username.charAt(0).toUpperCase();
    const avatarHtml = profileFileName
        ? '<img src="/files/profile/' + profileFileName + '" style="width:100%;height:100%;object-fit:cover;border-radius:50%;">'
        : initial;
    const time = cmRelTime(createdAt);
    const MAX = 100;
    const isTrunc = content.length > MAX;
    const preview = isTrunc ? safe(content.slice(0, MAX)) + '...' : safe(content);
    const full = safe(content);
    const imgHtml = imageUrl ? '<img class="cm-image" src="' + imageUrl + '" alt="" onclick="cmOpenImage(this)">' : '';

    const div = document.createElement('div');
    div.className = 'chat-msg';
    div.innerHTML =
        '<div class="cm-left">' +
            '<div class="cm-avatar" style="background:' + (profileFileName ? 'transparent' : color) + '">' + avatarHtml + '</div>' +
            '<span class="cm-rank">주주</span>' +
        '</div>' +
        '<div class="cm-right">' +
            '<div class="cm-meta">' +
                '<span class="cm-name">' + safe(username) + '</span>' +
                '<span class="cm-time">' + time + '</span>' +
            '</div>' +
            '<div class="cm-text" data-full="' + full.replace(/"/g, '&quot;') + '" data-trunc="' + (isTrunc ? '1' : '0') + '">' +
                preview +
                (isTrunc ? ' <button class="cm-more-btn" onclick="cmToggleMore(this)">더 보기</button>' : '') +
            '</div>' +
            imgHtml +
        '</div>';
    if (scroll) msgs.prepend(div);
    else msgs.appendChild(div);
}

function cmToggleMore(btn) {
    const textEl = btn.parentElement;
    const full = textEl.dataset.full;
    textEl.innerHTML = full + ' <button class="cm-more-btn" onclick="cmToggleLess(this)">접기</button>';
}

function cmToggleLess(btn) {
    const textEl = btn.parentElement;
    const full = textEl.dataset.full;
    const MAX = 100;
    const preview = full.slice(0, MAX) + '...';
    textEl.innerHTML = preview + ' <button class="cm-more-btn" onclick="cmToggleMore(this)">더 보기</button>';
}


document.addEventListener('DOMContentLoaded', () => {
    initializeCoinList();

    const panel = document.getElementById('detailPanel');
    if (panel) {
        panel.addEventListener('mouseenter', () => panel.classList.add('scrollbar-visible'));
        panel.addEventListener('mouseleave', () => panel.classList.remove('scrollbar-visible'));
    }

    const chatMsgs = document.getElementById('chat-messages');
    if (chatMsgs) {
        chatMsgs.addEventListener('mouseenter', () => chatMsgs.classList.add('scrollbar-visible'));
        chatMsgs.addEventListener('mouseleave', () => chatMsgs.classList.remove('scrollbar-visible'));
    }
    const tableWrap = document.querySelector('.stock-table-wrap');
    if (tableWrap) {
        tableWrap.addEventListener('mouseenter', () => tableWrap.classList.add('scrollbar-visible'));
        tableWrap.addEventListener('mouseleave', () => tableWrap.classList.remove('scrollbar-visible'));
    }
});
