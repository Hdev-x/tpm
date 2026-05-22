/* =====================================================
   coin-detail.js - 코인 리스트의 우측 상세 패널을 담당한다.
   coinList.js에서 코인을 선택했을 때 이 파일의 loadDetailChart()가 호출된다.
   ===================================================== */

/* =====================================================
   [이 파일을 읽는 법]

   1. 역할
      선택한 코인의 상세 차트, 가격 정보, 댓글 목록을 한 번에 갱신한다.
      coin/list.jsp의 우측 상세 패널 DOM 요소들과 직접 연결된다.

   2. 중심 함수
      loadDetailChart()
      - Bitget에서 주봉 데이터를 가져온다.
      - SVG 차트를 만들어 #detailChartArea에 넣는다.
      - 로고, 가격, 등락률, 관심 버튼 상태를 갱신한다.
      - 마지막에 connectChat()으로 댓글 영역을 연결한다.

   3. 전체 흐름
      코인 선택
      -> loadDetailChart(symbol) 실행
      -> 차트 데이터 fetch
      -> SVG 차트와 상세 정보 DOM 갱신
      -> 기존 댓글 목록 fetch
      -> WebSocket/STOMP 댓글 구독

   4. 보조 함수
      connectChat()                댓글 WebSocket 연결과 토픽 구독
      loadListChatHistory()        서버에서 기존 댓글 목록 조회
      appendListChatMsg()          coin-common.js의 댓글 렌더링 함수 호출

   5. 주의해서 볼 값
      currentChatSymbol            비동기 연결 중에도 현재 코인 심볼을 기억
      listChatSubscription         코인이 바뀔 때 기존 댓글 구독을 해제하기 위한 객체
      scroll                       실시간 댓글은 위, 히스토리 댓글은 아래에 붙이는 기준
      currentTimeFilter            리스트에서 선택한 기간에 따라 등락률 계산 방식 변경
   ===================================================== */

// [전역 상태] STOMP 연결과 현재 댓글 화면 상태를 파일 안에서 공유한다.
let listStompClient = null;
let listChatSubscription = null;
let currentChatSort = 'latest';
let currentChatSymbol = null;

/**
 * 선택한 코인의 주봉 차트와 상세 패널 정보를 갱신한다.
 *
 * @param {string} symbol Bitget 코인 심볼. 예: BTCUSDT
 */
async function loadDetailChart(symbol) {
    // [실행 흐름] 다른 파일의 관심 버튼 로직이 현재 상세 코인을 알 수 있도록 전역 값을 갱신한다.
    currentDetailSymbol = symbol;

    // [코드 읽기] BTCUSDT/BTCUSDC에서 거래 통화 접미사를 제거해 화면용 티커(BTC)를 만든다.
    const ticker = symbol.replace(/USDT$/, '').replace(/USDC$/, '') || symbol;

    // [실행 흐름] 서버 프록시(/coin/api/candles)를 통해 CORS/429 문제를 방지한다.
    // 1Wutc 주봉 52개 = 약 1년치 캔들을 요청한다.
    const res = await fetch(`/coin/api/candles?symbol=${symbol}&granularity=1Wutc&limit=52`);
    const json = await res.json();
    if (!json.data || json.data.length === 0) return;

    // [코드 읽기] Bitget 캔들 배열에서 차트에 필요한 타임스탬프, 종가, 거래량만 객체로 뽑는다.
    // [주의] 응답은 최신 데이터가 먼저 오므로 reverse()로 오래된 데이터 -> 최신 데이터 순서로 바꾼다.
    const candles = json.data.map(d => ({
        ts: parseInt(d[0]),
        close: parseFloat(d[4]),
        vol: parseFloat(d[5]),
    })).reverse();

    const prices = candles.map(d => d.close);
    const vols = candles.map(d => d.vol);

    // [DOM 연결] #detailChartArea는 coin/list.jsp의 우측 상세 패널 안에 있는 차트 영역이다.
    const area = document.getElementById('detailChartArea');
    const W = area.clientWidth || 300;
    const H = area.clientHeight || 180;
    const padL = 8, padR = 8, padTop = 10, padBottom = 22;
    const volH = 16;
    const chartH = H - padTop - padBottom - volH - 4;

    // [코드 읽기] 가격은 로그 스케일로 바꾼 뒤 좌표를 계산한다. 큰 가격 변동도 차트 안에 덜 눌려 보인다.
    const logPrices = prices.map(p => Math.log(p));
    const logMin = Math.min(...logPrices);
    const logMax = Math.max(...logPrices);
    const logRange = logMax - logMin || 1;
    const maxVol = Math.max(...vols);

    // [코드 읽기] xOf는 데이터 순번을 x좌표로, yOf는 가격을 y좌표로 바꾸는 짧은 변환 함수다.
    // [주의] SVG는 위쪽이 y=0이라서 높은 가격일수록 더 작은 y좌표가 되도록 chartH에서 빼준다.
    const xOf = i => padL + (i / (prices.length - 1)) * (W - padL - padR);
    const yOf = p => padTop + chartH - ((Math.log(p) - logMin) / logRange) * chartH;

    // [실행 흐름] polyline에 넣을 "x,y x,y ..." 형식의 좌표 문자열을 만든다.
    const linePoints = prices.map((p, i) => `${xOf(i).toFixed(1)},${yOf(p).toFixed(1)}`).join(' ');

    // [코드 읽기] fillPoints는 선 아래 영역을 채우기 위해 선 좌표 끝에 오른쪽 아래와 왼쪽 아래 좌표를 추가한다.
    const fillPoints = linePoints + ` ${xOf(prices.length - 1).toFixed(1)},${(padTop + chartH).toFixed(1)} ${padL},${(padTop + chartH).toFixed(1)}`;

    const isUp = prices[prices.length - 1] >= prices[0];
    const color = isUp ? '#F04452' : '#2563EB';

    // [주의] SVG gradient id는 문서 전체에서 겹치면 안 되므로 심볼 이름을 섞어 고유하게 만든다.
    const fillId = 'grad-' + symbol.replace(/[^a-zA-Z0-9]/g, '');

    // [코드 읽기] 거래량 막대는 최대 거래량 대비 비율로 높이를 계산한다.
    const barW = Math.max(1, (W - padL - padR) / prices.length - 1);
    const volBars = vols.map((v, i) => {
        const x = xOf(i) - barW / 2;
        const bh = (v / maxVol) * volH;
        const y = H - padBottom - bh;
        return `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${barW.toFixed(1)}" height="${bh.toFixed(1)}" fill="#555" opacity="0.5"/>`;
    }).join('');

    // [코드 읽기] x축에는 첫 주, 중간 주, 마지막 주만 표시해 레이블이 겹치지 않게 한다.
    const labelIdxs = [0, Math.floor(prices.length / 2), prices.length - 1];

    // [DOM 연결] 아래 HTML 문자열은 SVG 차트와 날짜 라벨을 #detailChartArea 안에 새로 그린다.
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

    // [DOM 연결] 빈 안내 문구를 숨기고 실제 상세 패널 본문을 보이게 한다.
    document.getElementById('detailEmpty').style.display = 'none';
    document.getElementById('detailBody').style.display = 'block';

    // [DOM 연결] 관심 버튼은 common.js의 watchlist 값에 따라 active 클래스를 켜거나 끈다.
    const wlBtn = document.getElementById('detail-watchlist-btn');
    if (wlBtn) wlBtn.classList.toggle('active', getWatchlist().includes(symbol));
    document.getElementById('detailName').textContent = ticker;
    document.getElementById('detailSub').textContent = symbol.endsWith('USDC') ? ticker + ' / USDC' : ticker + ' / USDT';

    // [실행 흐름] 로고 이미지를 먼저 시도하고, 실패하면 글자 fallback을 보여준다.
    const logoWrap = document.getElementById('detailLogoWrap');
    const logoImg = document.getElementById('detailLogoImg');
    const logoUrl = logoMap[ticker] || 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/' + ticker.toLowerCase() + '.png';
    const fallback = ticker.slice(0, 3);

    // [주의] coinLogoColor는 chart-toss-coin.js에만 있을 수 있으므로 함수 존재 여부를 확인하고 호출한다.
    const logoFallbackColor = typeof coinLogoColor === 'function' ? coinLogoColor(ticker) : '#3a3a4a';
    logoWrap.style.background = '';
    logoImg.style.display = '';
    const existingFallback = logoWrap.querySelector('.logo-fb');
    if (existingFallback) existingFallback.remove();
    if (!logoWrap.contains(logoImg)) logoWrap.appendChild(logoImg);
    logoImg.src = logoUrl;
    logoImg.alt = ticker;
    logoImg.onerror = function () {
        // [실행 흐름] 이미지 로딩 실패 콜백이다. this는 실패한 img 요소인 logoImg를 가리킨다.
        logoWrap.style.background = logoFallbackColor;
        this.style.display = 'none';
        const fb = document.createElement('span');
        fb.className = 'logo-fb';
        fb.style.cssText = 'color:#fff;font-size:11px;font-weight:700;';
        fb.textContent = fallback;
        logoWrap.appendChild(fb);
    };

    // [DOM 연결] allTickers는 coinList.js가 들고 있는 실시간 코인 목록이고, 여기서 현재 심볼의 가격을 찾는다.
    const t = allTickers.find(t => t.symbol === symbol);
    if (t) {
        // [실행 흐름] 기간 필터가 1일이면 API의 24시간 등락률을 쓰고, 그 외에는 calcChange()로 계산한다.
        const change = currentTimeFilter === '1일' ? parseFloat(t.change24h) * 100 : calcChange(t);
        const sign = change >= 0 ? '+' : '';
        const cls = change >= 0 ? 'up' : 'down';
        document.getElementById('detailPrice').textContent = parseFloat(t.lastPr).toLocaleString() + ' USDT';
        const changeEl = document.getElementById('detailChange');
        changeEl.textContent = sign + change.toFixed(2) + '%';
        changeEl.className = 'hc-main-pnl ' + cls;
    }

    // [실행 흐름] 상세 패널 갱신이 끝나면 해당 코인의 댓글 히스토리와 실시간 구독을 연결한다.
    connectChat(symbol);
}

/**
 * 선택한 코인의 댓글 목록을 불러오고 실시간 댓글 토픽을 구독한다.
 *
 * @param {string} symbol 댓글을 연결할 코인 심볼
 */
function connectChat(symbol) {
    // [실행 흐름] WebSocket 연결 콜백이 늦게 실행될 수 있으므로 현재 심볼을 따로 저장한다.
    currentChatSymbol = symbol;

    // [실행 흐름] 실시간 구독 전에 기존 댓글 목록을 먼저 서버에서 가져온다.
    loadListChatHistory(symbol);

    // [코드 읽기] 이미 연결된 STOMP 클라이언트가 있으면 소켓을 새로 만들지 않고 구독 대상만 바꾼다.
    if (listStompClient && listStompClient.connected) {
        if (listChatSubscription) listChatSubscription.unsubscribe();
        listChatSubscription = listStompClient.subscribe('/topic/market/COIN/' + symbol, msg => {
            // [실행 흐름] 토픽 메시지의 body 문자열을 댓글 DTO 객체로 바꿔 화면에 추가한다.
            const dto = JSON.parse(msg.body);
            appendListChatMsg(dto.username, dto.content, dto.createdAt, true, dto.imageUrl, dto.profileFileName, dto.commentNo, dto.likeCount, dto.likedByMe);
        });
        return;
    }

    // [실행 흐름] SockJS로 /ws-coin 엔드포인트에 연결하고, 그 위에 STOMP 구독 기능을 얹는다.
    const socket = new SockJS('/ws-coin');
    listStompClient = Stomp.over(socket);
    listStompClient.debug = null;

    listStompClient.connect({}, () => {
        if (listChatSubscription) listChatSubscription.unsubscribe();

        // [주의] connect 콜백은 비동기라서 그 사이 사용자가 다른 코인을 선택했을 수 있다.
        // 그래서 함수 인자 symbol 대신 최신 값인 currentChatSymbol로 구독한다.
        listChatSubscription = listStompClient.subscribe('/topic/market/COIN/' + currentChatSymbol, msg => {
            const dto = JSON.parse(msg.body);
            appendListChatMsg(dto.username, dto.content, dto.createdAt, true, dto.imageUrl, dto.profileFileName, dto.commentNo, dto.likeCount, dto.likedByMe);
        });
    });
}

/**
 * 서버에서 현재 코인의 기존 댓글 목록을 가져와 댓글 영역을 다시 그린다.
 *
 * @param {string} symbol 코인 심볼
 * @param {string} [sort] 정렬 기준. 없으면 currentChatSort를 사용한다.
 */
function loadListChatHistory(symbol, sort) {
    const s = sort || currentChatSort;

    // [실행 흐름] 정렬 기준을 쿼리스트링으로 보내 latest/popular 댓글 목록을 요청한다.
    fetch('/market/comments/COIN/' + symbol + '?sort=' + s)
        .then(r => r.json())
        .then(list => {
            // [DOM 연결] #chat-messages는 coin/list.jsp의 댓글 목록 영역이다.
            const msgs = document.getElementById('chat-messages');
            msgs.innerHTML = '';

            // [실행 흐름] 댓글이 없으면 빈 상태 안내만 넣고 여기서 끝낸다.
            if (!list.length) {
                msgs.innerHTML = '<div class="chat-empty"><span class="chat-empty-icon">💬</span><span>첫 댓글을 남겨보세요</span></div>';
                return;
            }

            // [코드 읽기] scroll=false는 기존 히스토리 댓글을 아래쪽에 순서대로 붙이라는 뜻이다.
            list.forEach(dto => appendListChatMsg(dto.username, dto.content, dto.createdAt, false, dto.imageUrl, dto.profileFileName, dto.commentNo, dto.likeCount, dto.likedByMe));
        });
}

/**
 * 리스트 상세 패널에서 받은 댓글 데이터를 공통 댓글 렌더링 함수로 넘긴다.
 *
 * @param {string} username 작성자 이름
 * @param {string} content 댓글 본문
 * @param {string} createdAt 작성 시각
 * @param {boolean} scroll true면 위에, false면 아래에 붙인다
 * @param {string|null} imageUrl 첨부 이미지 주소
 * @param {string|null} profileFileName 프로필 이미지 파일명
 * @param {number|null} commentNo 댓글 번호
 * @param {number} likeCount 좋아요 수
 * @param {boolean} likedByMe 현재 사용자의 좋아요 여부
 */
function appendListChatMsg(username, content, createdAt, scroll, imageUrl, profileFileName, commentNo, likeCount, likedByMe) {
    // [실행 흐름] 실제 댓글 DOM 생성은 coin-common.js의 cmAppendChatMsg()가 담당한다.
    cmAppendChatMsg(username, content, createdAt, scroll, imageUrl, profileFileName, commentNo, likeCount, likedByMe);
}
