let allTickers = [];
let renderIndex = 0;
const PAGE_SIZE = 50;
let logoMap = {};
let currentSort = '거래대금';


// ── 메인 탭 전환 ──
document.querySelectorAll('.main-tab').forEach(tab => {
    tab.addEventListener('click', function () {
        document.querySelectorAll('.main-tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.add('hidden'));
        this.classList.add('active');
        document.getElementById('tab-' + this.dataset.tab).classList.remove('hidden');
    });
});

// ── 필터 버튼 그룹 토글 ──
document.querySelectorAll('.filter-group').forEach(group => {
    group.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', function () {
            group.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
        });
    });
});

// ── 테이블 행 클릭 → 우측 패널 active 표시 ──
document.querySelectorAll('.stock-row').forEach(row => {
    row.addEventListener('click', function () {
        document.querySelectorAll('.stock-row').forEach(r => r.classList.remove('active'));
        this.classList.add('active');
    });
});


// ── 숫자 축약 (1,234,567 → 1.23M) ──
function fmtNum(n) {
    if (n >= 1_000_000_000) return (n / 1_000_000_000).toFixed(2) + 'B';
    if (n >= 1_000_000) return (n / 1_000_000).toFixed(2) + 'M';
    if (n >= 1_000) return (n / 1_000).toFixed(2) + 'K';
    return n.toFixed(2);
}

// ── CoinGecko 로고 매핑 ──
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

// ── 코인 목록 fetch ──
async function loadTickers() {
    const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers');
    const json = await res.json();
    return json.data || [];
}


// ── 행 HTML 생성 ──
function makeRow(t, rank) {
    const ticker = t.symbol.replace(/USDT$/, '').replace(/USDC$/, '').replace('_SPBL', '') || t.symbol;
    const change = parseFloat(t.change24h) * 100;
    const cls = change >= 0 ? 'up' : 'down';
    const sign = change >= 0 ? '+' : '';
    const logoUrl = logoMap[ticker] || 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/' + ticker.toLowerCase() + '.png';
    const fallback = ticker.slice(0, 3);
    const market = t.symbol.endsWith('USDC') ? '/ USDC' : '/ USDT';

    const tr = document.createElement('tr');
    tr.className = 'stock-row';
    tr.dataset.symbol = t.symbol;
    tr.innerHTML =
        '<td class="td-rank">'
        + '<div class="rank-inner">'
        + '<button class="like-btn"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>'
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
        + '<td class="td-price">' + parseFloat(t.lastPr).toLocaleString() + '</td>'
        + '<td class="td-change"><span class="badge ' + cls + '">' + sign + change.toFixed(2) + '%</span></td>'
        + '<td class="td-quote">' + fmtNum(parseFloat(t.quoteVolume)) + ' USDT</td>'
        + '<td class="td-high">' + parseFloat(t.high24h).toLocaleString() + '</td>'
        + '<td class="td-low">' + parseFloat(t.low24h).toLocaleString() + '</td>';
    return tr;
}

// ── 테이블 렌더링 ──
function renderTable(tickers) {
    const tbody = document.getElementById('stockTableBody');
    tbody.innerHTML = '';
    tickers.forEach((t, i) => tbody.appendChild(makeRow(t, i + 1)));
    const sentinel = document.createElement('tr');
    sentinel.id = 'scroll-sentinel';
    sentinel.innerHTML = '<td colspan="6" style="height:1px;padding:0;"></td>';
    tbody.appendChild(sentinel);
}

// ── 추가 로드 ──
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

// ── 초기 로드 ──
Promise.all([loadLogoMap(), loadTickers()]).then(([, data]) => {
    data = data.filter(t => t.symbol.endsWith('USDT') || t.symbol.endsWith('USDC'));
    data.sort((a, b) => parseFloat(b.quoteVolume) - parseFloat(a.quoteVolume));
    allTickers = data;
    renderIndex = 0;
    renderTable(allTickers.slice(0, PAGE_SIZE));
    renderIndex = PAGE_SIZE;
    connectListWs(allTickers.slice(0, PAGE_SIZE).map(d => d.symbol));
    if (allTickers.length > 0) {
        const firstRow = document.querySelector('#stockTableBody .stock-row');
        if (firstRow) firstRow.classList.add('active');
        loadDetailChart(allTickers[0].symbol);
    }
});


// ── 실시간 WebSocket ──
let listWs = null;

function connectListWs(symbols) {
    if (listWs) listWs.close();
    const ws = new WebSocket('wss://ws.bitget.com/v2/ws/public');
    listWs = ws;

    ws.onopen = () => {
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
        const change = parseFloat(msg.data[0].change24h) * 100;
        const row = document.querySelector(`tr[data-symbol="${symbol}"]`);
        if (!row) return;

        const cls = change >= 0 ? 'up' : 'down';
        const sign = change >= 0 ? '+' : '';
        const badge = row.querySelector('.badge');
        const prevChange = badge.textContent;
        const newChange = sign + change.toFixed(2) + '%';
        row.querySelector('.td-price').textContent = price.toLocaleString();
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
        row.querySelector('.td-quote').textContent = fmtNum(parseFloat(msg.data[0].quoteVolume)) + ' USDT';
        row.querySelector('.td-high').textContent = parseFloat(msg.data[0].high24h).toLocaleString();
        row.querySelector('.td-low').textContent = parseFloat(msg.data[0].low24h).toLocaleString();

        if (symbol === currentDetailSymbol) {
            const sign = change >= 0 ? '+' : '';
            const cls = change >= 0 ? 'up' : 'down';
            document.getElementById('detailPrice').textContent = price.toLocaleString() + ' USDT';
            const changeEl = document.getElementById('detailChange');
            changeEl.textContent = sign + change.toFixed(2) + '%';
            changeEl.className = 'hc-main-pnl ' + cls;
        }
    };

    ws.onclose = () => {
        if (ws === listWs) setTimeout(() => connectListWs(symbols), 3000);
    };
}


// ── 무한 스크롤 ──
document.querySelector('.stock-table-wrap').addEventListener('scroll', function () {
    if (renderIndex >= allTickers.length) return;
    if (this.scrollTop + this.clientHeight >= this.scrollHeight - 200) {
        const next = allTickers.slice(renderIndex, renderIndex + PAGE_SIZE);
        renderIndex += PAGE_SIZE;
        appendRows(next);
        connectListWs(allTickers.slice(0, renderIndex).map(d => d.symbol));
    }
});


// ── 마켓 필터 ──
let currentMarket = '전체';

function applyFilters() {
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
        currentMarket = this.textContent.trim();
        applyFilters();
    });
});

// ── 정렬 필터 ──
const sortFns = {
    '거래대금': (a, b) => parseFloat(b.quoteVolume) - parseFloat(a.quoteVolume),
    '급상승': (a, b) => parseFloat(b.change24h) - parseFloat(a.change24h),
    '급하락': (a, b) => parseFloat(a.change24h) - parseFloat(b.change24h),
};

document.querySelectorAll('.filter-group:nth-child(3) .filter-btn').forEach(btn => {
    btn.addEventListener('click', function () {
        const label = this.textContent.trim();
        if (!sortFns[label]) return;
        currentSort = label;
        applyFilters();
    });
});

// ── 시간 필터 ──
let currentTimeFilter = '실시간';

document.querySelectorAll('.filter-group:nth-child(5) .filter-btn').forEach(btn => {
    btn.addEventListener('click', function () {
        const label = this.textContent.trim();
        currentTimeFilter = label;
        document.querySelectorAll('#stockTableBody .stock-row').forEach(row => {
            const t = allTickers.find(t => t.symbol === row.dataset.symbol);
            if (!t) return;
            const change = parseFloat(t.change24h) * 100;
            const cls = change >= 0 ? 'up' : 'down';
            const sign = change >= 0 ? '+' : '';
            const badge = row.querySelector('.badge');
            badge.textContent = sign + change.toFixed(2) + '%';
            badge.className = 'badge ' + cls;
        });
    });
});

// ── 하트 클릭 ──
document.getElementById('stockTableBody').addEventListener('click', function (e) {
    const btn = e.target.closest('.like-btn');
    if (!btn) return;
    e.stopPropagation();
    btn.classList.toggle('liked');
});

// ── 상세 패널 ──
let currentDetailSymbol = null;

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

    const linePoints = prices.map((p, i) => `${xOf(i).toFixed(1)},${yOf(p).toFixed(1)}`).join(' ');
    const fillPoints = linePoints + ` ${xOf(prices.length - 1).toFixed(1)},${(padTop + chartH).toFixed(1)} ${padL},${(padTop + chartH).toFixed(1)}`;

    const isUp = prices[prices.length - 1] >= prices[0];
    const color = isUp ? '#F04452' : '#2563EB';
    const fillId = 'grad-' + symbol.replace(/[^a-zA-Z0-9]/g, '');

    // 볼륨 바 (회색)
    const barW = Math.max(1, (W - padL - padR) / prices.length - 1);
    const volBars = vols.map((v, i) => {
        const x = xOf(i) - barW / 2;
        const bh = (v / maxVol) * volH;
        const y = H - padBottom - bh;
        return `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${barW.toFixed(1)}" height="${bh.toFixed(1)}" fill="#555" opacity="0.5"/>`;
    }).join('');

    const labelIdxs = [0, Math.floor(prices.length / 2), prices.length - 1];

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
    document.getElementById('detailName').textContent = ticker;
    document.getElementById('detailSub').textContent = symbol.endsWith('USDC') ? ticker + ' / USDC' : ticker + ' / USDT';

    // 로고
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
        const change = parseFloat(t.change24h) * 100;
        const sign = change >= 0 ? '+' : '';
        const cls = change >= 0 ? 'up' : 'down';
        document.getElementById('detailPrice').textContent = parseFloat(t.lastPr).toLocaleString() + ' USDT';
        const changeEl = document.getElementById('detailChange');
        changeEl.textContent = sign + change.toFixed(2) + '%';
        changeEl.className = 'hc-main-pnl ' + cls;
    }
}

document.getElementById('stockTableBody').addEventListener('click', function (e) {
    if (e.target.closest('.like-btn')) return;
    const row = e.target.closest('.stock-row');
    if (!row) return;
    document.querySelectorAll('.stock-row').forEach(r => r.classList.remove('active'));
    row.classList.add('active');
    loadDetailChart(row.dataset.symbol);
});

/* ====================================================
   커뮤니티 댓글 무한스크롤 (목업)
   ==================================================== */
const MOCK_COMMENTS = [
    { name: '오니들마미',   color: '#4caf50', time: '2분',  text: '최회장님 이렇게 긴 파격세일기간은 원하지않습니다' },
    { name: '홈그리',       color: '#2196f3', time: '3분',  text: 'tsmc시총은 따라잡겠지 아몰랑' },
    { name: '사버지',       color: '#78909c', time: '7분',  text: '주식은 공포에 사라', badge: '1억대 자산가' },
    { name: '김하은여신',   color: '#e53935', time: '8분',  text: '6시지나고 급등예상!' },
    { name: '지리산범고래', color: '#8d6e63', time: '6분',  text: '하닉 실적발표 나왔네요 ^^ 월요일 떡상각입니다~ 다들 얼릉 탑승 하세요', badge: '1억대 자산가' },
    { name: '이민준',       color: '#7b1fa2', time: '11분', text: '저점 다진 것 같은데 슬슬 들어가봐야겠다' },
    { name: '강민서',       color: '#f57c00', time: '14분', text: '볼린저 밴드 하단 터치했네요' },
    { name: '정태양',       color: '#00897b', time: '18분', text: '나스닥이랑 같이 움직이는 중' },
    { name: '윤하늘',       color: '#5e35b1', time: '22분', text: '단타는 좀 위험할듯 스윙으로 가야지' },
    { name: '임도현',       color: '#c0392b', time: '25분', text: '거래량이 터지면 진짜 가는데...' },
    { name: '송지우',       color: '#1565c0', time: '30분', text: '주봉 차트 보니까 아직 추세 살아있음' },
    { name: '박민재',       color: '#2e7d32', time: '33분', text: 'RSI 과매도 구간이에요', badge: '5천만대 자산가' },
    { name: '최유진',       color: '#6d4c41', time: '37분', text: '고래들이 쓸어담는 중 ㅋㅋ' },
    { name: '한지원',       color: '#37474f', time: '41분', text: '지지선 깨지면 손절각 봐야할 듯' },
    { name: '노을빛',       color: '#ad1457', time: '45분', text: '매물대 돌파하면 한 번 가즈아~' },
    { name: '김태현',       color: '#0277bd', time: '48분', text: '이 가격이면 충분히 살만하지 않나요?' },
    { name: '박서연',       color: '#558b2f', time: '51분', text: '단기 저항선 돌파 시도 중이에요' },
    { name: '최준호',       color: '#6a1b9a', time: '55분', text: '저도 조금 담았습니다 같이 가시죠' },
    { name: '이지은',       color: '#d84315', time: '58분', text: '차트 패턴 좋은데 눌림 한 번 더 올 수도', badge: '1억대 자산가' },
    { name: '황민철',       color: '#00695c', time: '1시간', text: '거래소별 차이 확인해보니까 여기가 제일 싸네요' },
    { name: '신보람',       color: '#4527a0', time: '1시간', text: '롱 포지션 잡았습니다 ㄱㄱ' },
    { name: '류재원',       color: '#bf360c', time: '1시간', text: '전고점 돌파하면 진짜 신고가 가나요?' },
    { name: '안소희',       color: '#01579b', time: '1시간', text: '너무 빨리 올라온 느낌인데 조정 한 번 오면 살 예정' },
    { name: '조민우',       color: '#1b5e20', time: '1시간', text: '고점 대비 얼마나 빠진 건지 알아요?', badge: '5천만대 자산가' },
    { name: '윤지수',       color: '#880e4f', time: '1시간', text: '눌리면 더 살 예정 기다리는 중' },
    { name: '임현준',       color: '#3e2723', time: '2시간', text: '이 종목 커뮤니티 사람들 다 같이 물린 건지 ㅋㅋ' },
    { name: '강예빈',       color: '#263238', time: '2시간', text: '기관이 매수하고 있다는데 호재 아닌가요', badge: '1억대 자산가' },
    { name: '정성훈',       color: '#827717', time: '2시간', text: '이거 들어간 거 후회 없음 장기로 갑니다' },
    { name: '배지현',       color: '#e65100', time: '2시간', text: '알트 시즌 올 때 이거 제일 먼저 튄다' },
    { name: '오태양',       color: '#4a148c', time: '2시간', text: '매집 구간인 것 같아서 분할 매수 중' },
    { name: '한수진',       color: '#006064', time: '2시간', text: '비트 눌릴 때마다 얘는 버텨주네요 신기' },
    { name: '권도윤',       color: '#b71c1c', time: '3시간', text: '지금이라도 들어가야 하나 고민됩니다' },
    { name: '문예진',       color: '#212121', time: '3시간', text: '반등 구간에서 단타 쳤다가 수익 냄 ㅎ', badge: '5천만대 자산가' },
    { name: '서민혁',       color: '#1a237e', time: '3시간', text: '차트가 너무 예쁘다 이건 가야지' },
    { name: '채소희',       color: '#33691e', time: '3시간', text: '주봉 기준으로 보면 아직 충분히 상승 여력 있음' },
    { name: '김준서',       color: '#4e342e', time: '3시간', text: 'MACD 골든크로스 났어요 진입 신호!', badge: '1억대 자산가' },
    { name: '박하연',       color: '#880e4f', time: '4시간', text: '개인적으로 이번 사이클 가장 기대되는 코인' },
    { name: '이찬호',       color: '#0d47a1', time: '4시간', text: '전 이미 평단 훨씬 아래라서 느긋하게 존버 중' },
    { name: '정유나',       color: '#37474f', time: '4시간', text: '세력이 모아가고 있는 거 보임 바닥 다지는 중' },
    { name: '홍성민',       color: '#558b2f', time: '4시간', text: '저 이거 1년째 홀딩 중인데 이제 빛 보나요 ㅠ' },
    { name: '최아름',       color: '#6a1b9a', time: '5시간', text: '여기서 손절하면 무조건 오른다는 법칙 있잖아요 ㅋㅋ' },
    { name: '남도현',       color: '#004d40', time: '5시간', text: '전략적으로 분할 매수 완료 이제 기다립니다', badge: '1억대 자산가' },
    { name: '양지원',       color: '#bf360c', time: '5시간', text: '비트 5만불 때부터 담은 사람인데 지금도 괜찮음' },
    { name: '고민준',       color: '#283593', time: '5시간', text: '커뮤니티 분위기 보니까 바닥 맞는 것 같아요' },
    { name: '전소윤',       color: '#ad1457', time: '5시간', text: '기다림이 답이죠 저도 장기 홀드' },
];

let chatPage = 0;
const CHAT_PAGE_SIZE = 10;
let chatLoading = false;

function makeChatMsg(c) {
    const badge = c.badge ? `<span class="cm-badge">${c.badge}</span>` : '';
    return `<div class="chat-msg">
        <div class="cm-avatar-col">
            <div class="cm-avatar" style="background:${c.color};">${c.name[0]}</div>
            <span class="cm-rank">주주</span>
        </div>
        <div class="cm-content">
            <div class="cm-meta"><span class="cm-name">${c.name}</span>${badge}<span class="cm-time">${c.time}</span></div>
            <div class="cm-text">${c.text}</div>
        </div>
    </div>`;
}

function loadMoreComments() {
    if (chatLoading) return;
    const msgs = document.getElementById('chat-messages');
    if (!msgs) return;
    const start = chatPage * CHAT_PAGE_SIZE;
    const slice = MOCK_COMMENTS.slice(start % MOCK_COMMENTS.length, (start % MOCK_COMMENTS.length) + CHAT_PAGE_SIZE)
        .concat(MOCK_COMMENTS.slice(0, Math.max(0, ((start % MOCK_COMMENTS.length) + CHAT_PAGE_SIZE) - MOCK_COMMENTS.length)));
    chatLoading = true;
    setTimeout(() => {
        const empty = msgs.querySelector('.chat-empty');
        if (empty) empty.remove();
        slice.forEach(c => msgs.insertAdjacentHTML('beforeend', makeChatMsg(c)));
        chatPage++;
        chatLoading = false;
    }, 300);
}

document.addEventListener('DOMContentLoaded', () => {
    const panel = document.getElementById('detailPanel');
    if (panel) {
        panel.addEventListener('scroll', function() {
            if (this.scrollTop + this.clientHeight >= this.scrollHeight - 100) loadMoreComments();
        });
        panel.addEventListener('mouseenter', () => panel.classList.add('scrollbar-visible'));
        panel.addEventListener('mouseleave', () => panel.classList.remove('scrollbar-visible'));
    }
    const tableWrap = document.querySelector('.stock-table-wrap');
    if (tableWrap) {
        tableWrap.addEventListener('mouseenter', () => tableWrap.classList.add('scrollbar-visible'));
        tableWrap.addEventListener('mouseleave', () => tableWrap.classList.remove('scrollbar-visible'));
    }
    loadMoreComments();
});


