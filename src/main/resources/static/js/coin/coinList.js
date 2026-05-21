/* =====================================================
   coinList.js - 코인 리스트 화면의 테이블, 필터, 실시간 가격을 담당한다.
   우측 상세 패널의 실제 차트/댓글 로직은 coin-detail.js에 분리되어 있다.
   ===================================================== */

/* =====================================================
   [이 파일을 읽는 법]

   1. 역할
      Bitget/CoinGecko 데이터를 가져와 코인 리스트 테이블을 그리고,
      필터/정렬/무한 스크롤/WebSocket 실시간 갱신을 처리한다.

   2. 중심 함수
      initializeCoinList()
      - 로고 맵과 ticker 목록을 동시에 불러온다.
      - USDT/USDC 마켓만 골라 거래대금 순으로 정렬한다.
      - 첫 페이지를 렌더링하고 WebSocket을 연결한다.
      - 첫 번째 코인의 상세 패널을 loadDetailChart()로 표시한다.

   3. 전체 흐름
      DOMContentLoaded
      -> initializeCoinList()
      -> loadLogoMap() + loadTickers()
      -> renderTable() / connectListWs()
      -> 필터, 정렬, 스크롤, 행 hover/click 이벤트로 화면 갱신

   4. 보조 함수
      makeRow()                    ticker 객체 하나를 테이블 행으로 변환
      renderTable()                첫 페이지를 새로 그림
      appendRows()                 무한 스크롤로 다음 행 추가
      connectListWs()              Bitget WebSocket으로 실시간 가격 수신
      applyFilters()               마켓/정렬/시간 필터를 반영해 다시 렌더링
      calcChange()                 기준가 대비 등락률 계산
      getDisplayChange()           현재 시간 필터에 맞는 등락률 선택

   5. 주의해서 볼 값
      allTickers                   API로 받은 전체 코인 목록 원본
      renderIndex                  현재 몇 개 행까지 화면에 그렸는지 나타내는 위치
      PAGE_SIZE                    한 번에 렌더링할 행 수
      logoMap                      티커와 로고 URL을 연결하는 객체
      currentMarket/currentSort    현재 선택된 마켓 필터와 정렬 기준
      currentTimeFilter            등락률 표시 기준
      listWs                       현재 연결된 Bitget 리스트 WebSocket
   ===================================================== */

// [전역 상태] 리스트 렌더링, 필터, 로고, 실시간 연결에서 함께 사용하는 화면 상태다.
let allTickers = [];
let renderIndex = 0;
const PAGE_SIZE = 50;
let logoMap = {};
let currentSort = '거래대금';

/**
 * ticker의 기준가 대비 현재가 등락률을 계산한다.
 *
 * @param {Object} t Bitget ticker 데이터
 * @return {number} 퍼센트 단위 등락률
 */
function calcChange(t) {
    const open = parseFloat(t.openUtc);
    return open > 0 ? (parseFloat(t.lastPr) - open) / open * 100 : parseFloat(t.change24h) * 100;
}

/**
 * 현재 시간 필터에 맞춰 화면에 보여줄 등락률을 선택한다.
 *
 * @param {Object} t Bitget ticker 데이터
 * @return {number} 퍼센트 단위 등락률
 */
function getDisplayChange(t) {
    // [실행 흐름] 1일 필터는 Bitget의 24시간 등락률을 그대로 쓰고, 나머지는 openUtc 기준으로 계산한다.
    return currentTimeFilter === '1일' ? parseFloat(t.change24h) * 100 : calcChange(t);
}

// [DOM 연결] .main-tab의 data-tab 값과 #tab-{값} 콘텐츠 id를 연결해 탭 화면을 바꾼다.
document.querySelectorAll('.main-tab').forEach(tab => {
    tab.addEventListener('click', function () {
        document.querySelectorAll('.main-tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.add('hidden'));
        this.classList.add('active');
        document.getElementById('tab-' + this.dataset.tab).classList.remove('hidden');
    });
});

// [DOM 연결] 각 .filter-group 안에서만 active 버튼을 바꿔 마켓/정렬/시간 필터가 서로 간섭하지 않게 한다.
document.querySelectorAll('.filter-group').forEach(group => {
    group.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', function () {
            group.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
        });
    });
});

/**
 * CoinGecko에서 여러 페이지의 코인 로고 정보를 가져와 logoMap을 채운다.
 *
 * @return {Promise<void>}
 */
async function loadLogoMap() {
    const pages = [1, 2, 3];

    // [실행 흐름] Promise.all은 1~3페이지 요청을 동시에 보내고 모두 끝날 때까지 기다린다.
    const results = await Promise.all(
        pages.map(p => fetch(`https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&per_page=250&page=${p}`)
            .then(r => r.json()).catch(() => []))
    );

    // [코드 읽기] flat()으로 페이지별 배열을 하나로 합친 뒤, BTC 같은 대문자 티커를 키로 저장한다.
    results.flat().forEach(coin => {
        if (coin && coin.symbol && coin.image) {
            logoMap[coin.symbol.toUpperCase()] = coin.image;
        }
    });
}

/**
 * Bitget REST API에서 현물 ticker 목록을 가져온다.
 *
 * @return {Promise<Array>} Bitget ticker 배열
 */
async function loadTickers() {
    const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers');
    const json = await res.json();
    return json.data || [];
}

/**
 * ticker 객체 하나를 테이블에 들어갈 tr 요소로 만든다.
 *
 * @param {Object} t Bitget ticker 데이터
 * @param {number} rank 화면에 보여줄 순위
 * @return {HTMLTableRowElement} tbody에 붙일 행 요소
 */
function makeRow(t, rank) {
    // [실행 흐름] 화면에 보여줄 티커/등락률/로고/마켓 표시값을 먼저 준비한다.
    const ticker = t.symbol.replace(/USDT$/, '').replace(/USDC$/, '').replace('_SPBL', '') || t.symbol;
    const change = getDisplayChange(t);
    const cls = change >= 0 ? 'up' : 'down';
    const sign = change >= 0 ? '+' : '';
    const logoUrl = logoMap[ticker] || 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/' + ticker.toLowerCase() + '.png';
    const fallback = ticker.slice(0, 3);
    const market = t.symbol.endsWith('USDC') ? '/ USDC' : '/ USDT';

    const isLiked = getWatchlist().includes(t.symbol);
    const tr = document.createElement('tr');
    tr.className = 'stock-row';

    // [DOM 연결] data-symbol은 이후 WebSocket 업데이트, hover 상세 패널, 클릭 이동에서 이 행의 코인을 찾는 기준이다.
    tr.dataset.symbol = t.symbol;

    // [DOM 연결] 행 구조: 관심 버튼/순위/로고/이름 + 가격 + 등락률 + 거래대금 + 고가/저가.
    // [주의] 로고 이미지가 실패하면 onerror에서 부모 .coin-logo 안에 fallback 티커 텍스트를 넣는다.
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
 * ticker 배열을 기준으로 테이블 첫 화면을 다시 그린다.
 *
 * @param {Array} tickers 화면에 새로 그릴 ticker 배열
 */
function renderTable(tickers) {
    const tbody = document.getElementById('stockTableBody');

    // [실행 흐름] 필터/정렬이 바뀐 경우 기존 행을 모두 비우고 처음부터 다시 그린다.
    tbody.innerHTML = '';
    tickers.forEach((t, i) => tbody.appendChild(makeRow(t, i + 1)));

    // [DOM 연결] sentinel은 스크롤 끝을 표시하는 1px짜리 기준 행이다.
    const sentinel = document.createElement('tr');
    sentinel.id = 'scroll-sentinel';
    sentinel.innerHTML = '<td colspan="6" style="height:1px;padding:0;"></td>';
    tbody.appendChild(sentinel);
}

/**
 * 무한 스크롤에서 다음 페이지 행만 테이블 뒤에 추가한다.
 *
 * @param {Array} tickers 추가로 표시할 ticker 배열
 */
function appendRows(tickers) {
    const tbody = document.getElementById('stockTableBody');

    // [실행 흐름] 기존 sentinel을 잠깐 제거하고 새 행을 붙인 뒤 다시 맨 아래에 붙인다.
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
 * 현재 화면에 렌더링된 코인 목록을 Bitget WebSocket ticker 채널에 구독한다.
 *
 * @param {string[]} symbols 실시간 가격을 받을 코인 심볼 목록
 */
function connectListWs(symbols) {
    // [주의] 필터/스크롤로 구독 대상이 바뀌면 이전 WebSocket을 닫고 새 구독으로 교체한다.
    if (listWs) listWs.close();
    const ws = new WebSocket('wss://ws.bitget.com/v2/ws/public');
    listWs = ws;

    ws.onopen = () => {
        // [실행 흐름] symbols 배열을 Bitget 구독 요청 형식으로 바꿔 보낸다.
        const args = symbols.map(s => ({ instType: 'SPOT', channel: 'ticker', instId: s }));
        ws.send(JSON.stringify({ op: 'subscribe', args }));

        // [주의] 연결 유지를 위해 20초마다 ping을 보낸다. readyState 1은 OPEN 상태다.
        setInterval(() => ws.readyState === 1 && ws.send('ping'), 20000);
    };

    ws.onmessage = (e) => {
        if (e.data === 'pong') return;
        let msg;
        try { msg = JSON.parse(e.data); } catch { return; }
        if (!msg.data || !msg.arg || msg.arg.channel !== 'ticker') return;

        // [실행 흐름] WebSocket 메시지에서 심볼, 현재가, 등락률 계산에 필요한 값을 뽑는다.
        const symbol = msg.arg.instId;
        const price = parseFloat(msg.data[0].lastPr);
        const openUtc = parseFloat(msg.data[0].openUtc);
        const changeUtc = openUtc > 0 ? (price - openUtc) / openUtc * 100 : (parseFloat(msg.data[0].change24h) * 100);
        const change = currentTimeFilter === '1일' ? parseFloat(msg.data[0].change24h) * 100 : changeUtc;

        // [DOM 연결] makeRow()가 tr에 넣어둔 data-symbol과 메시지 symbol을 맞춰 갱신할 행을 찾는다.
        const row = document.querySelector(`tr[data-symbol="${symbol}"]`);
        if (!row) return;

        const cls = change >= 0 ? 'up' : 'down';
        const sign = change >= 0 ? '+' : '';
        const badge = row.querySelector('.badge');
        const prevChange = badge.textContent;
        const newChange = sign + change.toFixed(2) + '%';

        // [실행 흐름] 가격, 거래대금, 고가/저가는 매 메시지마다 최신 값으로 바꾼다.
        row.querySelector('.td-price').textContent = '$' + price.toLocaleString();
        if (currentTimeFilter === '실시간' || currentTimeFilter === '1일') {
            badge.textContent = newChange;
            badge.className = 'badge ' + cls;

            // [실행 흐름] 등락률 텍스트가 바뀌면 배경색을 잠깐 넣었다가 빼서 변화가 보이게 한다.
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

        // [DOM 연결] 현재 상세 패널이 같은 심볼을 보고 있으면 상세 가격/등락률도 같이 갱신한다.
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
        // [주의] 닫힌 소켓이 현재 사용 중인 listWs일 때만 재연결한다. 오래된 소켓의 재연결을 막기 위해서다.
        if (ws === listWs) setTimeout(() => connectListWs(symbols), 3000);
    };
}

// [DOM 연결] .stock-table-wrap은 실제 스크롤 컨테이너다.
document.querySelector('.stock-table-wrap').addEventListener('scroll', function () {
    if (renderIndex >= allTickers.length) return;
    if (this.scrollTop + this.clientHeight >= this.scrollHeight - 200) {
        // [실행 흐름] 아래쪽 200px 근처까지 내려오면 다음 PAGE_SIZE만큼 행을 추가한다.
        const next = allTickers.slice(renderIndex, renderIndex + PAGE_SIZE);
        renderIndex += PAGE_SIZE;
        appendRows(next);

        // [실행 흐름] 화면에 새로 보이는 코인까지 WebSocket 구독 범위를 넓힌다.
        connectListWs(allTickers.slice(0, renderIndex).map(d => d.symbol));
    }
});

let currentMarket = '전체';

/**
 * 현재 선택된 마켓/정렬/시간 필터 상태를 반영해 테이블 첫 페이지를 다시 그린다.
 */
function applyFilters() {
    // [주의] allTickers 원본 배열은 유지하고, 화면에 쓸 filtered 배열만 새로 만든다.
    let filtered = allTickers;
    if (currentMarket === 'USDT') filtered = allTickers.filter(t => t.symbol.endsWith('USDT'));
    if (currentMarket === 'USDC') filtered = allTickers.filter(t => t.symbol.endsWith('USDC'));
    if (sortFns[currentSort]) filtered = [...filtered].sort(sortFns[currentSort]);

    // [실행 흐름] 필터가 바뀌면 무한 스크롤 위치를 처음으로 되돌리고 첫 페이지부터 다시 구독한다.
    renderIndex = 0;
    renderTable(filtered.slice(0, PAGE_SIZE));
    renderIndex = PAGE_SIZE;
    connectListWs(filtered.slice(0, PAGE_SIZE).map(d => d.symbol));
}

// [DOM 연결] 첫 번째 필터 그룹은 마켓 필터다. 버튼 텍스트가 currentMarket 값이 된다.
document.querySelectorAll('.filter-group:nth-child(1) .filter-btn').forEach(btn => {
    btn.addEventListener('click', function () {
        currentMarket = this.textContent.trim();
        applyFilters();
    });
});

const sortFns = {
    '거래대금': (a, b) => parseFloat(b.quoteVolume) - parseFloat(a.quoteVolume),
    '급상승': (a, b) => getDisplayChange(b) - getDisplayChange(a),
    '급하락': (a, b) => getDisplayChange(a) - getDisplayChange(b),
};

// [DOM 연결] 세 번째 필터 그룹은 정렬 필터다. sortFns에 있는 라벨만 실제 정렬을 수행한다.
document.querySelectorAll('.filter-group:nth-child(3) .filter-btn').forEach(btn => {
    btn.addEventListener('click', function () {
        const label = this.textContent.trim();

        // [주의] sortFns에 없는 버튼은 아직 동작이 없는 버튼이므로 정렬을 실행하지 않는다.
        if (!sortFns[label]) return;
        currentSort = label;
        applyFilters();
    });
});

let currentTimeFilter = '실시간';

// [DOM 연결] 다섯 번째 필터 그룹은 등락률 기준 시간 필터다.
document.querySelectorAll('.filter-group:nth-child(5) .filter-btn').forEach(btn => {
    btn.addEventListener('click', function () {
        currentTimeFilter = this.textContent.trim();
        applyFilters();
    });
});

// [이벤트 위임] like-btn은 makeRow()가 동적으로 만든 버튼이라 tbody에서 클릭을 받아 처리한다.
document.getElementById('stockTableBody').addEventListener('click', function (e) {
    const btn = e.target.closest('.like-btn');
    if (!btn) return;
    e.stopPropagation();

    // [DOM 연결] 버튼이 들어 있는 tr의 data-symbol로 관심 등록할 코인을 찾는다.
    const symbol = btn.closest('tr').dataset.symbol;
    toggleWatchlist(symbol);
    btn.classList.toggle('liked', getWatchlist().includes(symbol));
});

// [이벤트 위임] 행에 마우스를 올리면 우측 상세 패널을 해당 코인으로 미리 갱신한다.
document.getElementById('stockTableBody').addEventListener('mouseover', function (e) {
    if (e.target.closest('.like-btn')) return;
    const row = e.target.closest('.stock-row');
    if (!row || row.classList.contains('active')) return;

    document.querySelectorAll('.stock-row').forEach(r => r.classList.remove('active'));
    row.classList.add('active');

    // [실행 흐름] loadDetailChart()는 coin-detail.js에 정의되어 있으며 상세 차트와 댓글을 갱신한다.
    loadDetailChart(row.dataset.symbol);
});

// [이벤트 위임] 행 자체를 클릭하면 코인 차트 상세 페이지로 이동한다.
document.getElementById('stockTableBody').addEventListener('click', function (e) {
    if (e.target.closest('.like-btn')) return;
    const row = e.target.closest('.stock-row');
    if (!row) return;

    const symbol = row.dataset.symbol;
    addToRecent(symbol);
    location.href = '/coin/chart?symbol=' + symbol;
});

// [전역 상태] 우측 상세 패널이 현재 표시 중인 코인 심볼이다. coin-detail.js와 WebSocket 갱신이 함께 사용한다.
let currentDetailSymbol = null;

/**
 * 코인 리스트 초기 데이터를 불러오고 첫 화면을 구성한다.
 *
 * @return {Promise<void>}
 */
async function initializeCoinList() {
    // [실행 흐름] 로고 API와 ticker API를 동시에 요청해 초기 로딩 시간을 줄인다.
    const [, data] = await Promise.all([loadLogoMap(), loadTickers()]);

    // [실행 흐름] USDT/USDC 현물만 남긴 뒤 거래대금이 큰 순서로 정렬한다.
    const filtered = data
        .filter(t => t.symbol.endsWith('USDT') || t.symbol.endsWith('USDC'))
        .sort((a, b) => parseFloat(b.quoteVolume) - parseFloat(a.quoteVolume));

    allTickers = filtered;
    renderIndex = 0;
    renderTable(allTickers.slice(0, PAGE_SIZE));
    renderIndex = PAGE_SIZE;
    connectListWs(allTickers.slice(0, PAGE_SIZE).map(d => d.symbol));

    if (allTickers.length === 0) return;

    // [실행 흐름] 첫 번째 행을 active로 표시하고, 우측 상세 패널도 첫 번째 코인으로 채운다.
    const firstRow = document.querySelector('#stockTableBody .stock-row');
    if (firstRow) firstRow.classList.add('active');
    loadDetailChart(allTickers[0].symbol);
}

document.addEventListener('DOMContentLoaded', () => {
    // [실행 흐름] DOM이 준비된 뒤 API 로딩과 이벤트 보조 기능을 시작한다.
    initializeCoinList();

    // [DOM 연결] 댓글 정렬 버튼은 coin-detail.js의 currentChatSort와 loadListChatHistory()를 사용한다.
    document.querySelectorAll('.chat-sort-btn').forEach(btn => {
        btn.addEventListener('click', function () {
            if (this.dataset.sort === currentChatSort) return;
            document.querySelectorAll('.chat-sort-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            currentChatSort = this.dataset.sort;
            if (currentChatSymbol) loadListChatHistory(currentChatSymbol);
        });
    });

    // [DOM 연결] 마우스가 상세 패널 위에 있을 때만 커스텀 스크롤바를 보이게 한다.
    const panel = document.getElementById('detailPanel');
    if (panel) {
        panel.addEventListener('mouseenter', () => panel.classList.add('scrollbar-visible'));
        panel.addEventListener('mouseleave', () => panel.classList.remove('scrollbar-visible'));
    }

    const chatMsgs = document.getElementById('chat-messages');
    if (chatMsgs) {
        chatMsgs.addEventListener('mouseenter', () => chatMsgs.classList.add('scrollbar-visible'));
        chatMsgs.addEventListener('mouseleave', () => chatMsgs.classList.remove('scrollbar-visible'));

        // [이벤트 위임] 댓글 좋아요 버튼은 coin-common.js가 동적으로 만들기 때문에 부모에서 클릭을 잡는다.
        chatMsgs.addEventListener('click', e => {
            const btn = e.target.closest('.cm-like-btn');
            if (!btn) return;
            const commentNo = btn.dataset.commentNo;

            // [실행 흐름] 좋아요 API 응답으로 버튼 하트 색과 카운트를 즉시 갱신한다.
            fetch('/api/coin/comment/' + commentNo + '/like', { method: 'POST' })
                .then(r => r.json())
                .then(data => {
                    const svg = btn.querySelector('svg');
                    svg.style.fill   = data.liked ? '#e91e63' : 'none';
                    svg.style.stroke = data.liked ? '#e91e63' : 'currentColor';
                    btn.querySelector('.cm-like-count').textContent = data.count;
                });
        });
    }

    // [DOM 연결] 코인 테이블도 hover 중에만 스크롤바를 보이게 한다.
    const tableWrap = document.querySelector('.stock-table-wrap');
    if (tableWrap) {
        tableWrap.addEventListener('mouseenter', () => tableWrap.classList.add('scrollbar-visible'));
        tableWrap.addEventListener('mouseleave', () => tableWrap.classList.remove('scrollbar-visible'));
    }
});
