/* =====================================================
   chart-coin.js
   차트 페이지 전용 JavaScript
   - Bitget API로 캔들 데이터 로드
   - LightweightCharts 라이브러리로 차트 렌더링
   - WebSocket으로 실시간 가격 수신
   - 주문·지갑·보유 내역 처리
   ===================================================== */


/* ====================================================
   전역 상태 변수
   ==================================================== */
let showHighLow = true;          // 최고/최저가 마커 표시 여부
let countdownTimer = null;   // 봉 카운트다운 플러그인 인스턴스

let currentGranularity = '1Dutc'; // 현재 타임프레임 (REST API 파라미터)
let currentChannel = 'candle1D'; // 현재 WebSocket 구독 채널명

let currentWs = null;    // 현재 WebSocket 연결 객체
let lastPrice = 0;       // 마지막으로 수신된 현재가
let prevClose = 0;       // 전일 마감가 (전일대비 % 계산에 사용)
let orderSide = 'buy';   // 현재 주문 방향 ('buy' 또는 'sell')

let walletBalance = 0;   // 가용 USDT 잔고
let allData = [];         // 전체 캔들 데이터 배열
let isLoadingMore = false; // 과거 데이터 추가 로드 중 여부 (중복 요청 방지)

let isLog = false;           // 로그 스케일 여부
let currentTfSeconds = 86400;   // 현재 타임프레임의 초 단위 길이 (카운트다운에 사용)
let showCountdown = true;    // 봉 카운트다운 표시 여부

/* 검색 드롭다운 관련 변수 */
let allCoinList = [];      // 전체 코인 목록
let popularCoins = [];     // 인기 코인 상위 5개


/* ====================================================
   타임프레임 매핑 테이블
   각 타임프레임별로 WebSocket 채널명, REST API 파라미터, 초 단위를 정의
   ==================================================== */
const TF_MAP = {
    '1min': { channel: 'candle1m', restGran: '1min', seconds: 60 },
    '3min': { channel: 'candle3m', restGran: '3min', seconds: 180 },
    '5min': { channel: 'candle5m', restGran: '5min', seconds: 300 },
    '15min': { channel: 'candle15m', restGran: '15min', seconds: 900 },
    '30min': { channel: 'candle30m', restGran: '30min', seconds: 1800 },
    '1h': { channel: 'candle1H', restGran: '1h', seconds: 3600 },
    '4h': { channel: 'candle4H', restGran: '4h', seconds: 14400 },
    '6h': { channel: 'candle6H', restGran: '6h', seconds: 21600 },
    '12h': { channel: 'candle12H', restGran: '12h', seconds: 43200 },
    '1day': { channel: 'candle1D', restGran: '1Dutc', seconds: 86400 },
    '3day': { channel: 'candle3D', restGran: '3Dutc', seconds: 259200 },
    '1week': { channel: 'candle1W', restGran: '1Wutc', seconds: 604800 },
    '1month': { channel: 'candle1M', restGran: '1Mutc', seconds: 2592000 },
};


/* ====================================================
   차트 생성 (LightweightCharts)
   ==================================================== */
const _chartBg = getComputedStyle(document.documentElement).getPropertyValue('--chart-bg').trim() || '#16161A';
const container = document.getElementById('chart-container');
const chart = LightweightCharts.createChart(container, {
    autoSize: true, // 컨테이너 크기에 맞게 자동 리사이즈
    layout: { background: { color: _chartBg }, textColor: 'rgba(255,255,255,0.5)' },
    grid: {
        vertLines: { color: 'rgba(255,255,255,0.04)' },
        horzLines: { color: 'rgba(255,255,255,0.04)' }
    },
    timeScale: { timeVisible: true, secondsVisible: false, borderColor: 'rgba(255,255,255,0.07)', rightOffset: 15 },
    rightPriceScale: { borderColor: 'rgba(255,255,255,0.07)' },
    crosshair: {
        mode: LightweightCharts.CrosshairMode.Normal,
        vertLine: { color: 'rgba(255,255,255,0.2)' },
        horzLine: { color: 'rgba(255,255,255,0.2)' }
    },
});

/* 캔들 시리즈 (한국식: 상승=빨강, 하락=파랑) */
const candleSeries = chart.addSeries(LightweightCharts.CandlestickSeries, {
    upColor: '#F04452', downColor: '#2563EB',
    borderUpColor: '#F04452', borderDownColor: '#2563EB',
    wickUpColor: '#F04452', wickDownColor: '#2563EB',
});

/* 이동평균선 시리즈 (MA5, MA20, MA60) - 초기에는 숨김 */
const ma5Series = chart.addSeries(LightweightCharts.LineSeries, { color: '#FF9800', lineWidth: 1, title: 'MA5', visible: false, priceLineVisible: false });
const ma20Series = chart.addSeries(LightweightCharts.LineSeries, { color: '#3182F6', lineWidth: 1, title: 'MA20', visible: false, priceLineVisible: false });
const ma60Series = chart.addSeries(LightweightCharts.LineSeries, { color: '#9C27B0', lineWidth: 1, title: 'MA60', visible: false, priceLineVisible: false });

/* 볼린저 밴드 시리즈 (상단·중간·하단) - 초기에는 숨김 */
const bbUpperSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#FF5722', lineWidth: 1, lineStyle: LightweightCharts.LineStyle.Dashed, title: 'BB↑', visible: false, priceLineVisible: false });
const bbMiddleSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#FF572288', lineWidth: 1, title: 'BB', visible: false, priceLineVisible: false });
const bbLowerSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#FF5722', lineWidth: 1, lineStyle: LightweightCharts.LineStyle.Dashed, title: 'BB↓', visible: false, priceLineVisible: false });

/* 일목균형표 시리즈 (전환선·기준선·선행A·선행B·후행) - 초기에는 숨김 */
const ichiTenkanSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#E91E63', lineWidth: 1, title: '전환', visible: false, priceLineVisible: false });
const ichiKijunSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#3182F6', lineWidth: 1, title: '기준', visible: false, priceLineVisible: false });
const ichiSpanASeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#4CAF50', lineWidth: 1, title: '선행A', visible: false, priceLineVisible: false });
const ichiSpanBSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#FF9800', lineWidth: 1, title: '선행B', visible: false, priceLineVisible: false });
const ichiChikouSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#9E9E9E', lineWidth: 1, title: '후행', visible: false, priceLineVisible: false });

/* 거래량 히스토그램 시리즈
   priceScaleId: 'volume' → 별도 가격축 사용
   scaleMargins: top 0.8 → 차트 하단 20% 영역에만 표시 */
const volumeSeries = chart.addSeries(LightweightCharts.HistogramSeries, {
    priceFormat: { type: 'volume' },
    priceScaleId: 'volume',
    priceLineVisible: false
});
chart.priceScale('volume').applyOptions({ scaleMargins: { top: 0.8, bottom: 0 } });


/* ====================================================
   RSI 차트 (별도 차트 인스턴스 - 메인 차트 아래에 위치)
   ==================================================== */
const rsiContainer = document.getElementById('rsi-container');
const rsiChart = LightweightCharts.createChart(rsiContainer, {
    autoSize: true,
    layout: { background: { color: _chartBg }, textColor: 'rgba(255,255,255,0.5)' },
    grid: { vertLines: { color: 'rgba(255,255,255,0.04)' }, horzLines: { color: 'rgba(255,255,255,0.04)' } },
    timeScale: { timeVisible: true, secondsVisible: false, borderColor: 'rgba(255,255,255,0.07)' },
    rightPriceScale: { borderColor: 'rgba(255,255,255,0.07)', scaleMargins: { top: 0.1, bottom: 0.1 } },
    crosshair: { mode: LightweightCharts.CrosshairMode.Normal },
});

const rsiSeries = rsiChart.addSeries(LightweightCharts.LineSeries, { color: '#9C27B0', lineWidth: 1, title: 'RSI', priceLineVisible: false });
const rsiOverbought = rsiChart.addSeries(LightweightCharts.LineSeries, { color: '#F0445266', lineWidth: 1, lineStyle: LightweightCharts.LineStyle.Dashed, priceLineVisible: false }); // 과매수선 (70)
const rsiOversold = rsiChart.addSeries(LightweightCharts.LineSeries, { color: '#2563EB66', lineWidth: 1, lineStyle: LightweightCharts.LineStyle.Dashed, priceLineVisible: false }); // 과매도선 (30)


/* ====================================================
   지표 활성화 상태 관리
   ==================================================== */
const indState = { ma5: false, ma20: false, ma60: false, bb: false, ichimoku: false, rsi: false };

/* 지표 버튼 스타일 변경 (on: 해당 지표 색상으로 강조 / off: 초기화) */
function setIndBtnStyle(name, on) {
    const btn = document.getElementById('ind-' + name);
    const colors = { ma5: '#FF9800', ma20: '#3182F6', ma60: '#9C27B0', bb: '#FF5722', ichimoku: '#E91E63', rsi: '#9C27B0' };
    const c = colors[name];
    if (on) {
        btn.style.borderColor = c;
        btn.style.color = c;
        btn.style.background = c + '18'; // 색상 + 투명도 10% 배경
    } else {
        btn.style.borderColor = '';
        btn.style.color = '';
        btn.style.background = '';
    }
}


/* ====================================================
   일목균형표 계산 헬퍼
   특정 기간의 (최고가 + 최저가) / 2 를 반환
   ==================================================== */
function ichiAvg(arr, i, period) {
    const sl = arr.slice(Math.max(0, i - period + 1), i + 1);
    return (Math.max(...sl.map(d => d.high)) + Math.min(...sl.map(d => d.low))) / 2;
}


/* ====================================================
   전체 지표 계산 및 차트 반영
   캔들 데이터(data)를 받아 모든 시리즈를 한 번에 업데이트
   ==================================================== */
function updateAllSeries(data) {
    candleSeries.setData(data);
    window.currentDataLength = data.length;
    window.lastCandleTime = data[data.length - 1].time;

    /* 거래량: 상승봉은 빨간색, 하락봉은 파란색 (44 = 투명도 약 27%) */
    volumeSeries.setData(data.map(d => ({
        time: d.time,
        value: d.volume,
        color: d.close >= d.open ? '#F0445244' : '#2563EB44'
    })));

    /* 이동평균선 계산
       i번째 봉의 MA5 = 직전 5개 봉 종가의 평균
       slice(i-5, i): i-5 ~ i-1 인덱스 5개 */
    const ma5D = [], ma20D = [], ma60D = [];
    data.forEach((d, i) => {
        if (i >= 5) ma5D.push({ time: d.time, value: data.slice(i - 5, i).reduce((s, c) => s + c.close, 0) / 5 });
        if (i >= 20) ma20D.push({ time: d.time, value: data.slice(i - 20, i).reduce((s, c) => s + c.close, 0) / 20 });
        if (i >= 60) ma60D.push({ time: d.time, value: data.slice(i - 60, i).reduce((s, c) => s + c.close, 0) / 60 });
    });
    ma5Series.setData(ma5D);
    ma20Series.setData(ma20D);
    ma60Series.setData(ma60D);

    /* 볼린저 밴드 계산
       20일 이동평균(avg) ± 2 × 표준편차(std)
       상단: avg + 2*std / 중간: avg / 하단: avg - 2*std */
    const bbU = [], bbM = [], bbL = [];
    data.forEach((d, i) => {
        if (i < 20) return;
        const sl = data.slice(i - 20, i);
        const avg = sl.reduce((s, c) => s + c.close, 0) / 20;
        const std = Math.sqrt(sl.reduce((s, c) => s + Math.pow(c.close - avg, 2), 0) / 20);
        bbU.push({ time: d.time, value: avg + 2 * std });
        bbM.push({ time: d.time, value: avg });
        bbL.push({ time: d.time, value: avg - 2 * std });
    });
    bbUpperSeries.setData(bbU);
    bbMiddleSeries.setData(bbM);
    bbLowerSeries.setData(bbL);

    /* 일목균형표 계산
       전환선(9) / 기준선(26) / 선행A=(전환+기준)/2 / 선행B(52) / 후행(26봉 앞에 표시) */
    const tk = [], kj = [], sA = [], sB = [], ck = [];
    data.forEach((d, i) => {
        if (i >= 8) tk.push({ time: d.time, value: ichiAvg(data, i, 9) });
        if (i >= 25) {
            kj.push({ time: d.time, value: ichiAvg(data, i, 26) });
            sA.push({ time: d.time, value: (ichiAvg(data, i, 9) + ichiAvg(data, i, 26)) / 2 });
            sB.push({ time: d.time, value: ichiAvg(data, i, 52) });
        }
        // 후행선: 현재 종가를 26봉 뒤 시간에 표시
        if (i + 26 < data.length) ck.push({ time: data[i + 26].time, value: d.close });
    });
    ichiTenkanSeries.setData(tk);
    ichiKijunSeries.setData(kj);
    ichiSpanASeries.setData(sA);
    ichiSpanBSeries.setData(sB);
    ichiChikouSeries.setData(ck);

    /* RSI 계산 (14일 기준)
       RSI = 100 - 100 / (1 + RS)
       RS = 평균상승폭 / 평균하락폭 */
    const rsiD = [];
    for (let i = 14; i < data.length; i++) {
        let g = 0, l = 0;
        for (let j = i - 13; j <= i; j++) {
            const diff = data[j].close - data[j - 1].close;
            if (diff > 0) g += diff; else l -= diff;
        }
        rsiD.push({ time: data[i].time, value: 100 - 100 / (1 + g / (l || 1)) });
    }

    /* RSI 활성화 상태일 때만 데이터 표시, 비활성화 시 빈 배열로 초기화 */
    if (indState.rsi && rsiD.length > 0) {
        rsiSeries.setData(rsiD);
        rsiOverbought.setData(rsiD.map(d => ({ time: d.time, value: 70 }))); // 과매수 기준선
        rsiOversold.setData(rsiD.map(d => ({ time: d.time, value: 30 })));   // 과매도 기준선
    } else {
        rsiSeries.setData([]);
        rsiOverbought.setData([]);
        rsiOversold.setData([]);
    }

    /* RSI 차트 타임스케일을 메인 차트와 동기화 (50ms 딜레이로 렌더링 후 실행) */
    setTimeout(() => {
        const lr = chart.timeScale().getVisibleLogicalRange();
        if (lr) { try { rsiChart.timeScale().setVisibleLogicalRange(lr); } catch (e) { } }
    }, 50);
}


/* ====================================================
   캔들 데이터 로드 (Bitget REST API)
   캐시 데이터가 있으면 먼저 표시 후 API 응답으로 업데이트
   ==================================================== */
async function loadData() {
    /* localStorage 캐시가 있으면 즉시 차트 렌더링 */
    const cacheKey = 'chart_' + currentGranularity;
    const cached = localStorage.getItem(cacheKey);
    if (cached) {
        allData = JSON.parse(cached);
        updateAllSeries(allData);
    }

    /* API 호출 */
    const res = await fetch(
        'https://api.bitget.com/api/v2/spot/market/candles?symbol=' + currentSymbol + '&granularity=' + currentGranularity + '&limit=200'
    ).then(r => r.json());
    if (res.code !== '00000') return;

    /* API 응답: [타임스탬프(ms), 시가, 고가, 저가, 종가, 거래량]
       타임스탬프를 초 단위로 변환 (LightweightCharts는 Unix 초 단위 사용) */
    allData = res.data.map(item => ({
        time: Math.floor(item[0] / 1000) + 32400,
        open: parseFloat(item[1]),
        high: parseFloat(item[2]),
        low: parseFloat(item[3]),
        close: parseFloat(item[4]),
        volume: parseFloat(item[5])
    })).sort((a, b) => a.time - b.time);

    /* 캐시 저장 후 최신 데이터로 차트 업데이트 */
    localStorage.setItem(cacheKey, JSON.stringify(allData));
    updateAllSeries(allData);
}

/* ====================================================
   과거 데이터 추가 로드 (무한 스크롤)
   차트를 왼쪽으로 스크롤하면 더 오래된 데이터를 로드
   ==================================================== */
let loadMoreTimer = null;
function loadMoreData() {
    if (isLoadingMore || allData.length === 0) return;

    /* 200ms 디바운스: 스크롤 이벤트가 연속으로 발생해도 한 번만 실행 */
    clearTimeout(loadMoreTimer);
    loadMoreTimer = setTimeout(async () => {
        isLoadingMore = true;
        try {
            const oldestTime = allData[0].time;
            const endTimeMs = (oldestTime - 32400) * 1000 - 1; // 현재 가장 오래된 봉 바로 이전 시간 (KST→UTC 변환)

            const res = await fetch(
                'https://api.bitget.com/api/v2/spot/market/candles?symbol=' + currentSymbol + '&granularity=' + currentGranularity + '&limit=200&endTime=' + endTimeMs
            ).then(r => r.json());

            if (res.code === '00000' && res.data && res.data.length > 0) {
                const older = res.data.map(item => ({
                    time: Math.floor(item[0] / 1000) + 32400,
                    open: parseFloat(item[1]),
                    high: parseFloat(item[2]),
                    low: parseFloat(item[3]),
                    close: parseFloat(item[4]),
                    volume: parseFloat(item[5])
                })).filter(d => d.time > 0 && d.open > 0 && d.close > 0 && d.time < oldestTime)
                    .sort((a, b) => a.time - b.time);

                if (older.length > 0) {
                    const lr = chart.timeScale().getVisibleLogicalRange();
                    allData = [...older, ...allData]; // 앞에 붙이기
                    updateAllSeries(allData);
                    /* 데이터가 앞에 추가됐으므로 보이는 범위를 동일하게 유지 */
                    if (lr) chart.timeScale().setVisibleLogicalRange({
                        from: lr.from + older.length,
                        to: lr.to + older.length
                    });
                }
            }
        } catch (e) { console.error(e); }
        isLoadingMore = false;
    }, 200);
}


/* ====================================================
   타임프레임 전환
   버튼 클릭 시 호출 - 데이터 재로드 + WebSocket 재연결
   ==================================================== */
function changeTimeframe(gran) {
    /* 모든 타임프레임 버튼에서 active 제거 후 클릭된 버튼에만 추가 */
    document.querySelectorAll('.tf-btn[data-tf]').forEach(b => b.classList.remove('active'));
    const clickedBtn = event.currentTarget;
    clickedBtn.classList.add('active');

    /* 드롭다운 버튼 텍스트 업데이트 */
    const displayBtn = document.getElementById('current-tf-display');
    if (clickedBtn.closest('.tf-dropdown-content')) {
        displayBtn.textContent = clickedBtn.textContent;
        displayBtn.classList.add('active');
    } else {
        displayBtn.classList.remove('active');
    }

    /* 현재 보이는 범위를 기억해서 타임프레임 변경 후에도 비슷한 위치 유지 */
    const lr = chart.timeScale().getVisibleLogicalRange();
    const totalBars = window.currentDataLength || 200;
    const rightOffset = lr ? lr.to - totalBars : 10;
    const barCount = lr ? lr.to - lr.from : 50;

    currentGranularity = TF_MAP[gran].restGran;
    currentChannel = TF_MAP[gran].channel;
    currentTfSeconds = TF_MAP[gran].seconds;

    if (showCountdown) startCountdown();

    allData = [];

    /* 기존 WebSocket 연결 안전하게 종료 (재연결 루프 방지) */
    if (currentWs) {
        currentWs.onclose = null;
        if (currentWs.readyState === WebSocket.OPEN || currentWs.readyState === WebSocket.CONNECTING) {
            currentWs.close();
        }
        currentWs = null;
    }

    loadData().then(() => {
        const nb = window.currentDataLength || 200;
        chart.timeScale().setVisibleLogicalRange({ from: nb + rightOffset - barCount, to: nb + rightOffset });
    });
    connectWebSocket();
}


/* ====================================================
   설정 메뉴 토글 / 로그 스케일
   ==================================================== */

/* 설정 메뉴 열기/닫기 (event.stopPropagation: 바깥 클릭 이벤트 차단) */
function toggleSettingsMenu() {
    event.stopPropagation();
    document.getElementById('settings-menu').classList.toggle('open');
}

/* 메뉴 외부 클릭 시 닫기 */
document.addEventListener('click', e => {
    if (!e.target.closest('.settings-wrap'))
        document.getElementById('settings-menu').classList.remove('open');
});

/* 로그 스케일 토글 (mode 0: 일반, mode 1: 로그) */
function toggleLog() {
    isLog = !isLog;
    chart.priceScale('right').applyOptions({ mode: isLog ? 1 : 0 });
}


/* ====================================================
   최고/최저가 마커 (hl-high, hl-low)
   현재 화면에 보이는 범위의 최고가·최저가 위치에 표시
   ==================================================== */
function updateHighLow() {
    if (!showHighLow) return;

    const lr = chart.timeScale().getVisibleLogicalRange();
    if (!lr || allData.length === 0) return;

    /* 현재 화면에 보이는 데이터 범위 계산 */
    const from = Math.max(0, Math.floor(lr.from));
    const to = Math.min(allData.length - 1, Math.ceil(lr.to));
    const visible = allData.slice(from, to + 1);
    if (!visible.length) return;

    /* 보이는 범위에서 최고가·최저가 찾기 */
    let hV = -Infinity, lV = Infinity, hC, lC;
    visible.forEach(d => {
        if (d.high > hV) { hV = d.high; hC = d; }
        if (d.low < lV) { lV = d.low; lC = d; }
    });

    /* 차트 좌표 계산 (시간 → X픽셀, 가격 → Y픽셀) */
    const hX = chart.timeScale().timeToCoordinate(hC.time);
    const hY = candleSeries.priceToCoordinate(hV);
    const lX = chart.timeScale().timeToCoordinate(lC.time);
    const lY = candleSeries.priceToCoordinate(lV);

    const hEl = document.getElementById('hl-high');
    const lEl = document.getElementById('hl-low');

    /* 전일 마감가 기준 등락률 계산
       prevClose가 0이면 (아직 loadTicker 미완료) 0으로 표시 */
    const hPct = prevClose > 0 ? ((hV - prevClose) / prevClose * 100) : 0;
    const lPct = prevClose > 0 ? ((lV - prevClose) / prevClose * 100) : 0;

    if (hX != null && hY != null) {
        hEl.style.display = 'flex';
        hEl.style.left = hX + 'px';
        hEl.style.top = (hY - 48) + 'px'; // 봉 위쪽에 표시 (-48px)
        document.getElementById('hl-high-val').textContent =
            hV.toLocaleString() + ' USDT (전일마감기준 ' + (hPct >= 0 ? '+' : '') + hPct.toFixed(2) + '%)';
    }
    if (lX != null && lY != null) {
        lEl.style.display = 'flex';
        lEl.style.left = lX + 'px';
        lEl.style.top = (lY + 10) + 'px'; // 봉 아래쪽에 표시 (+10px)
        document.getElementById('hl-low-val').textContent =
            lV.toLocaleString() + ' USDT (전일마감기준 ' + (lPct >= 0 ? '+' : '') + lPct.toFixed(2) + '%)';
    }
}

/* 최고/최저가 마커 표시 여부 토글 */
function toggleHighLow(enabled) {
    showHighLow = enabled;
    document.getElementById('hl-high').style.display = enabled ? 'flex' : 'none';
    document.getElementById('hl-low').style.display = enabled ? 'flex' : 'none';
    if (enabled) updateHighLow();
}


/* ====================================================
   봉 카운트다운 (다음 봉까지 남은 시간 표시)
   ==================================================== */
function getNextCloseSeconds() {
    const now = Math.floor(Date.now() / 1000);
    if (currentTfSeconds === 604800) {
        // 주봉: 다음 월요일 00:00 UTC
        const day = new Date().getUTCDay(); // 0=일, 1=월
        const toMonday = day === 0 ? 1 : (8 - day) % 7 || 7;
        const nextMonday = new Date();
        nextMonday.setUTCDate(nextMonday.getUTCDate() + toMonday);
        nextMonday.setUTCHours(0, 0, 0, 0);
        return Math.floor(nextMonday.getTime() / 1000) - now;
    }
    if (currentTfSeconds === 2592000) {
        // 월봉: 다음 달 1일 00:00 UTC
        const d = new Date();
        const nextMonth = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 1));
        return Math.floor(nextMonth.getTime() / 1000) - now;
    }
    // 분봉/시봉/일봉: epoch 기준 나머지
    return currentTfSeconds - (now % currentTfSeconds);
}

function formatCountdown(secs) {
    const d = Math.floor(secs / 86400);
    const h = Math.floor((secs % 86400) / 3600);
    const m = Math.floor((secs % 3600) / 60);
    const s = secs % 60;
    if (currentTfSeconds >= 259200 && d > 0) return d + 'd ' + h + 'h';
    if (currentTfSeconds >= 43200 || h > 0)
        return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
    return String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
}

function startCountdown() {
    if (countdownTimer) clearInterval(countdownTimer);

    const tick = () => {
        if (!showCountdown) return;
        const remaining = getNextCloseSeconds();
        candleSeries.applyOptions({
            lastValueVisible: true,
            priceLineVisible: true,
            title: formatCountdown(remaining)
        });
    };
    tick();
    countdownTimer = setInterval(tick, 1000);
}

function toggleCountdown(enabled) {
    showCountdown = enabled;
    if (enabled) {
        startCountdown();
    } else {
        if (countdownTimer) clearInterval(countdownTimer);
        candleSeries.applyOptions({ title: '', lastValueVisible: true, priceLineVisible: true });
    }
}


/* ====================================================
   지표 토글
   버튼 클릭 시 해당 지표 활성화/비활성화
   ==================================================== */
function toggleInd(name) {
    indState[name] = !indState[name];
    const on = indState[name];
    setIndBtnStyle(name, on);

    if (name === 'ma5') ma5Series.applyOptions({ visible: on });
    else if (name === 'ma20') ma20Series.applyOptions({ visible: on });
    else if (name === 'ma60') ma60Series.applyOptions({ visible: on });
    else if (name === 'bb') {
        bbUpperSeries.applyOptions({ visible: on });
        bbMiddleSeries.applyOptions({ visible: on });
        bbLowerSeries.applyOptions({ visible: on });
    }
    else if (name === 'ichimoku') {
        [ichiTenkanSeries, ichiKijunSeries, ichiSpanASeries, ichiSpanBSeries, ichiChikouSeries]
            .forEach(s => s.applyOptions({ visible: on }));
    }
    else if (name === 'rsi') {
        /* RSI는 별도 차트 컨테이너를 보이거나 숨김 */
        rsiContainer.style.display = on ? 'block' : 'none';
        document.getElementById('pane-divider').style.display = on ? 'block' : 'none';
        if (on) {
            /* RSI 차트 표시 후 타임스케일 동기화 */
            setTimeout(() => {
                const lr = chart.timeScale().getVisibleLogicalRange();
                if (lr) { try { rsiChart.timeScale().setVisibleLogicalRange(lr); } catch (e) { } }
            }, 50);
        }
    }
}


/* ====================================================
   WebSocket - 실시간 캔들 데이터 수신 (Bitget)
   ==================================================== */
function connectWebSocket() {
    const ws = new WebSocket('wss://ws.bitget.com/v2/ws/public');
    currentWs = ws;

    ws.onopen = () => {
        ws.send(JSON.stringify({
            op: 'subscribe',
            args: [
                { instType: 'SPOT', channel: currentChannel, instId: currentSymbol },
                { instType: 'SPOT', channel: 'books15', instId: currentSymbol },
                { instType: 'SPOT', channel: 'ticker', instId: currentSymbol }
            ]
        }));
        setInterval(() => ws.readyState === 1 && ws.send('ping'), 20000);
    };

    ws.onmessage = (event) => {
        if (ws !== currentWs) return;
        if (event.data === 'pong') return;
        const msg = JSON.parse(event.data);
        if (!msg.data) return;

        /* 호가 채널 */
        if (msg.arg && (msg.arg.channel === 'books5' || msg.arg.channel === 'books15')) {
            updateHoga(msg.data[0]);
            return;
        }

        /* ticker 채널 - 현재 봉 실시간 갱신 + 미체결 자동 체결 */
        if (msg.arg && msg.arg.channel === 'ticker') {
            const price = parseFloat(msg.data[0].lastPr);
            if (!price || !allData.length) return;
            checkPendingOrders(price);
            const currentBar = allData[allData.length - 1];
            const bar = {
                time: currentBar.time,
                open: currentBar.open,
                high: Math.max(currentBar.high, price),
                low: Math.min(currentBar.low, price),
                close: price
            };
            currentBar.high = bar.high;
            currentBar.low = bar.low;
            currentBar.close = price;
            candleSeries.update(bar);
            updateOhlc(bar.open, bar.high, bar.low, bar.close);
            lastPrice = price;
            updatePriceHeader(price);
            updateHoldingsPnl();
            return;
        }

        /* 캔들 채널 */
        const item = msg.data[0];
        const bar = {
            time: Math.floor(item[0] / 1000) + 32400,
            open: parseFloat(item[1]),
            high: parseFloat(item[2]),
            low: parseFloat(item[3]),
            close: parseFloat(item[4])
        };

        if (window.lastCandleTime && bar.time < window.lastCandleTime) return;

        candleSeries.update(bar);
        updateOhlc(bar.open, bar.high, bar.low, bar.close);
        lastPrice = bar.close;
        updatePriceHeader(bar.close);
        updateHoldingsPnl();
    };

    /* 연결 종료 시 3초 후 재연결 */
    ws.onclose = () => {
        if (ws === currentWs) setTimeout(connectWebSocket, 3000);
    };
}

function updateHoga(data) {
    /* 각 절반 영역 높이 기준으로 표시 행 수 계산 (행 높이 24px) */
    const topEl = document.querySelector('.hoga-top');
    const rowCount = topEl ? Math.max(5, Math.floor(topEl.clientHeight / 24)) : 15;

    /* asks: API는 오름차순(낮은 가격 먼저) → 역순으로 최대 rowCount개 → 내림차순(높은 가격 위) */
    const asks = [...data.asks].slice(0, rowCount).reverse();
    const bids = data.bids.slice(0, rowCount);

    /* 누적 합계 계산 */
    let askTotal = 0, bidTotal = 0;
    const asksWithTotal = asks.map(([p, q]) => { askTotal += parseFloat(q); return [p, q, askTotal]; });
    const bidsWithTotal = bids.map(([p, q]) => { bidTotal += parseFloat(q); return [p, q, bidTotal]; });

    const maxTotal = Math.max(askTotal, bidTotal);

    document.getElementById('hoga-asks').innerHTML = asksWithTotal.map(([price, qty, total]) => {
        const pct = (total / maxTotal * 100).toFixed(1);
        return `<tr style="background:linear-gradient(to left, rgba(37,99,235,0.12) ${pct}%, transparent ${pct}%)">
            <td class="hoga-ask">${parseFloat(price).toLocaleString()}</td>
            <td>${parseFloat(qty).toFixed(4)}</td>
            <td>${total.toFixed(4)}</td>
        </tr>`;
    }).join('');

    document.getElementById('hoga-bids').innerHTML = bidsWithTotal.map(([price, qty, total]) => {
        const pct = (total / maxTotal * 100).toFixed(1);
        return `<tr style="background:linear-gradient(to left, rgba(240,68,82,0.12) ${pct}%, transparent ${pct}%)">
            <td class="hoga-bid">${parseFloat(price).toLocaleString()}</td>
            <td>${parseFloat(qty).toFixed(4)}</td>
            <td>${total.toFixed(4)}</td>
        </tr>`;
    }).join('');
}


/* ====================================================
   UI 업데이트 함수들
   ==================================================== */

/* 시고저종 바 업데이트 (소수점 2자리 고정) */
function updateOhlc(o, h, l, c) {
    document.getElementById('val-o').textContent = o.toFixed(2);
    document.getElementById('val-h').textContent = h.toFixed(2);
    document.getElementById('val-l').textContent = l.toFixed(2);
    document.getElementById('val-c').textContent = c.toFixed(2);
    const diff = c - o;
    const pct = (diff / o) * 100;
    const sign = diff >= 0 ? '+' : '';
    const cls = diff >= 0 ? 'up' : 'down';
    const absEl = document.getElementById('val-oc-abs');
    const pctEl = document.getElementById('val-oc-pct');
    if (absEl) { absEl.textContent = sign + diff.toFixed(2); absEl.className = cls; }
    if (pctEl) { pctEl.textContent = '(' + sign + pct.toFixed(2) + '%)'; pctEl.className = cls; }
}

/* 상단 현재가 헤더 업데이트 */
function updatePriceHeader(price) {
    document.getElementById('ph-price').textContent =
        price.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    const inp = document.getElementById('trade-price-input');
    if (inp && !inp.value) inp.placeholder = price.toFixed(2);
    const hm = document.getElementById('hoga-cur-price');
    if (hm) hm.textContent = price.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

/* 보유 종목 손익 실시간 업데이트 */
function updateHoldingsPnl() {
    document.querySelectorAll('#bp-holdings-body tr[data-coin]').forEach(row => {
        const coinCode = row.dataset.coin;
        if (typeof updateHoldingPrice === 'function') {
            updateHoldingPrice(coinCode, lastPrice);
        }
    });
}


/* ====================================================
   24h 티커 로드 (Bitget REST API)
   현재가·변동률·고가·저가·거래량 정보 가져오기
   ==================================================== */
async function loadTicker() {
    try {
        const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers?symbol=' + currentSymbol).then(r => r.json());
        if (res.code === '00000' && res.data && res.data[0]) {
            const d = res.data[0];
            const price = parseFloat(d.lastPr);

            /* 전일 마감가 계산: price = prevClose × (1 + change24h)
               → prevClose = price / (1 + change24h) */
            // 변경 (전날 종가를 일봉 API에서 직접 가져옴)
            const candleRes = await fetch('https://api.bitget.com/api/v2/spot/market/candles?symbol=' + currentSymbol + '&granularity=1Dutc&limit=2').then(r => r.json());
            prevClose = parseFloat(candleRes.data[0][4]); // [0]번 캔들(어제)의 close (오름차순)
            const todayOpen = parseFloat(candleRes.data[1][1]); // [1]번 캔들(오늘)의 시가
            const absChange = price - prevClose;
            const chgPct = (absChange / prevClose) * 100;

            lastPrice = price;
            updatePriceHeader(price);

            /* 가격은 항상 흰색 고정 (up/down 클래스 미적용) */
            document.getElementById('ph-price').className = 'ph-price';

            /* 전일대비 절대금액 (+1234.56 USDT) */
            const absEl = document.getElementById('ph-change-abs');
            absEl.textContent = (chgPct >= 0 ? '+' : '') + absChange.toFixed(2) + ' USDT';
            absEl.className = 'ph-change ' + (chgPct >= 0 ? 'up' : 'down');

            /* 전일대비 퍼센트 (+8.28%) */
            const cEl = document.getElementById('ph-change');
            cEl.textContent = '(' + (chgPct >= 0 ? '+' : '') + chgPct.toFixed(2) + '%)';
            cEl.className = 'ph-change ' + (chgPct >= 0 ? 'up' : 'down');

            const prevCloseEl = document.getElementById('ph-prev-close');
            if (prevCloseEl) prevCloseEl.textContent = '$' + prevClose.toLocaleString();
            const openEl = document.getElementById('ph-open');
            if (openEl) openEl.textContent = '$' + todayOpen.toLocaleString();
            document.getElementById('ph-high').textContent = '$' + parseFloat(d.high24h).toLocaleString();
            document.getElementById('ph-low').textContent = '$' + parseFloat(d.low24h).toLocaleString();
            document.getElementById('ph-vol').textContent = parseFloat(d.baseVolume).toLocaleString(undefined, { maximumFractionDigits: 0 }) + ' ' + tickerName;
            document.getElementById('ph-turnover').textContent = fmtNum(parseFloat(d.quoteVolume)) + ' USDT';

        }
    } catch (e) { }
}

async function loadExtraStats() {
    try {
        const ticker = currentSymbol.replace('USDT', '').replace('USDC', '').replace('_SPBL', '').toLowerCase();
        const res = await fetch(`https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&symbols=${ticker}&order=market_cap_desc&per_page=1&page=1&sparkline=false`)
            .then(r => r.json());

        if (res && res[0]) {
            const data = res[0];
            const mktcap = data.market_cap;
            document.getElementById('ph-mktcap').textContent = '$' + fmtNum(mktcap);
        }
    } catch (e) {
        console.error("추가 정보 로드 실패", e);
    }
}


/* ====================================================
   이벤트 구독
   ==================================================== */

/* 크로스헤어 이동 시 OHLC 바 업데이트 */
chart.subscribeCrosshairMove(param => {
    if (!param.time) return;
    const c = param.seriesData.get(candleSeries);
    if (!c) return;
    updateOhlc(c.open, c.high, c.low, c.close);
});

const chartWrapper = document.getElementById('chart-wrapper');
chartWrapper.addEventListener('mousemove', updateHighLow);
chartWrapper.addEventListener('mouseup', updateHighLow);

/* 차트 범위 변경 시 최고/최저 마커 업데이트 + RSI 동기화 + 과거 데이터 로드 */
chart.timeScale().subscribeVisibleLogicalRangeChange(lr => {
    updateHighLow();
    if (lr) {
        try { rsiChart.timeScale().setVisibleLogicalRange(lr); } catch (e) { }
        if (lr.from < 10) loadMoreData(); // 왼쪽 끝 근처면 과거 데이터 추가 로드
    }
});


/* ====================================================
   RSI 패널 세로 리사이즈 드래그
   ==================================================== */
let rsiDrag = false, rsiDragY = 0, rsiDragH = 0;
document.getElementById('pane-divider').addEventListener('mousedown', e => {
    rsiDrag = true;
    rsiDragY = e.clientY;
    rsiDragH = document.getElementById('rsi-container').clientHeight;
    document.body.style.cursor = 'row-resize';
    document.body.style.userSelect = 'none';
});
document.addEventListener('mousemove', e => {
    if (!rsiDrag) return;
    /* 위로 드래그 → RSI 높아짐, 아래로 드래그 → RSI 낮아짐 (최소 80, 최대 400) */
    document.getElementById('rsi-container').style.height =
        Math.max(80, Math.min(400, rsiDragH + (rsiDragY - e.clientY))) + 'px';
});
document.addEventListener('mouseup', () => {
    rsiDrag = false;
    document.body.style.cursor = '';
    document.body.style.userSelect = '';
});


/* ====================================================
   패널 리사이즈 (가로/세로 드래그)
   ==================================================== */

/* 가로 리사이즈: 핸들을 드래그해서 오른쪽 패널 너비 조절
   startX - e.clientX: 왼쪽으로 드래그 시 패널이 넓어지는 방향 */
function makeHResizer(handleId, rightPanelId, minW = 200, maxW = 600) {
    const h = document.getElementById(handleId);
    const rp = document.getElementById(rightPanelId);
    let drag = false, startX = 0, startW = 0;

    h.addEventListener('mousedown', e => {
        drag = true; startX = e.clientX; startW = rp.getBoundingClientRect().width;
        h.classList.add('dragging');
        document.body.style.cursor = 'col-resize';
        document.body.style.userSelect = 'none';
    });
    document.addEventListener('mousemove', e => {
        if (!drag) return;
        const w = Math.max(minW, Math.min(maxW, startW + (startX - e.clientX))) + 'px';
        rp.style.width = w;
        rp.style.flexBasis = w;
    });
    document.addEventListener('mouseup', () => {
        if (!drag) return;
        drag = false;
        h.classList.remove('dragging');
        document.body.style.cursor = '';
        document.body.style.userSelect = '';
    });
}

/* 세로 리사이즈: 핸들을 드래그해서 위/아래 패널 높이 조절 */
function makeVResizer(handleId, topId, botId) {
    const h = document.getElementById(handleId);
    const tp = document.getElementById(topId);
    const bp = document.getElementById(botId);
    let drag = false, startY = 0, startTH = 0, startBH = 0;

    h.addEventListener('mousedown', e => {
        drag = true; startY = e.clientY;
        startTH = tp.getBoundingClientRect().height;
        startBH = bp.getBoundingClientRect().height;
        h.classList.add('dragging');
        document.body.style.cursor = 'row-resize';
        document.body.style.userSelect = 'none';
    });
    document.addEventListener('mousemove', e => {
        if (!drag) return;
        const d = e.clientY - startY;
        tp.style.flex = 'none';
        tp.style.height = Math.max(150, startTH + d) + 'px'; // 주문창 최소 150px
        bp.style.height = Math.max(80, startBH - d) + 'px'; // 호가창 최소 80px
    });
    document.addEventListener('mouseup', () => {
        if (!drag) return;
        drag = false;
        h.classList.remove('dragging');
        document.body.style.cursor = '';
        document.body.style.userSelect = '';
    });
}

makeHResizer('rh-1', 'panel-middle', 340, 340); // 주문/호가 패널: 340px 고정
makeHResizer('rh-2', 'panel-chat', 270, 380); // 댓글 패널: 270~380px
makeVResizer('rh-v', 'panel-order-wrap', 'panel-hoga');


/* ====================================================
   주문 관련 함수
   ==================================================== */

/* 매수/매도 탭 전환 */
function switchOrderTab(side) {
    orderSide = side;
    const isBuy = side === 'buy';
    document.getElementById('tab-buy').classList.toggle('active', isBuy);
    document.getElementById('tab-sell').classList.toggle('active', !isBuy);
    document.getElementById('order-submit-btn').textContent = isBuy ? '매수 주문' : '매도 주문';
    document.getElementById('order-submit-btn').className = isBuy ? 'btn-buy' : 'btn-sell';

    const av = document.querySelector('.order-avail span');
    if (isBuy) {
        av.textContent = walletBalance.toFixed(2) + ' USDT';
    } else {
        /* 매도 시: 보유 수량 표시 */
        const holding = holdingsData.find(h => h.coinCode === currentSymbol);
        const qty = holding ? holding.coinCount : 0;
        const ticker = currentSymbol.replace(/USDT$/, '').replace('_SPBL', '');
        av.textContent = qty.toFixed(6) + ' ' + ticker;
    }
    calcAmount();
}

/* 지정가/시장가 선택 */
function selectOrderType(btn) {
    document.querySelectorAll('.order-type-btn').forEach(b => b.classList.remove('sel'));
    btn.classList.add('sel');
    const isLimit = btn.textContent.trim() === '지정가';
    const priceInput = document.getElementById('trade-price-input');
    priceInput.readOnly = !isLimit;
    priceInput.style.background = isLimit ? '' : 'var(--bg)';
    if (!isLimit) priceInput.value = lastPrice ? lastPrice.toFixed(2) : '';
}

/* 잔고 비율로 수량 자동 계산 */
function setPercent(pct) {
    if (orderSide === 'sell') {
        const holding = holdingsData.find(h => h.coinCode === currentSymbol);
        const h = holding ? holding.coinCount : 0;
        document.getElementById('trade-qty').value = (h * pct / 100).toFixed(6);
    } else {
        document.getElementById('trade-qty').value =
            (walletBalance * pct / 100 / (lastPrice || 1)).toFixed(6);
    }
    calcAmount();
}

/* 수량 × 현재가 = 주문금액 자동 계산 */
function calcAmount() {
    document.getElementById('trade-amount').value =
        ((parseFloat(document.getElementById('trade-qty').value) || 0) * lastPrice).toFixed(2);
}

/* 주문 제출 - 서버 REST API 호출 */
function submitOrder(side) {
    const qty = document.getElementById('trade-qty').value;
    if (!qty || parseFloat(qty) <= 0) { alert('수량을 입력하세요'); return; }

    const isLimit = document.querySelector('.order-type-btn.sel')?.textContent.trim() === '지정가';
    const targetPrice = parseFloat(document.getElementById('trade-price-input').value);
    if (isLimit && (!targetPrice || targetPrice <= 0)) { alert('지정가를 입력하세요'); return; }

    const url = isLimit ? '/coin/limitOrder' : '/coin/' + side;
    const params = {
        username: 'testuser',
        coinCode: currentSymbol,
        orderPrice: lastPrice,
        orderCount: qty,
        orderType: side.toUpperCase()
    };
    if (isLimit) params.targetPrice = targetPrice;

    fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams(params)
    })
        .then(r => r.text())
        .then(result => {
            if (result === 'success') {
                alert(isLimit
                    ? (side === 'buy' ? '매수' : '매도') + ' 지정가 주문 등록!'
                    : (side === 'buy' ? '매수' : '매도') + ' 주문 완료!');
                loadWallet();
                loadHoldings();
                loadPendingOrders().then(() => {
                    if (isLimit) checkPendingOrders(lastPrice);
                });
            } else {
                alert('주문 실패: ' + result);
            }
        })
        .catch(err => alert('오류: ' + err));
}


/* 사이드바 관련 함수는 common.js 참고 */


/* ====================================================
   지갑 / 보유 내역 로드
   ==================================================== */

/* 서버에서 USDT 잔고 가져오기 */
async function loadWallet() {
    const res = await fetch('/coin/wallet?username=testuser').then(r => r.json());
    if (res && res.usdtBalance !== undefined) {
        walletBalance = res.usdtBalance;
        document.querySelector('.order-avail span').textContent = res.usdtBalance.toFixed(2) + ' USDT';
    }
}

/* loadHoldings()는 common.js로 이동 */


/* ====================================================
   미체결 주문 자동 체결 체크
   ==================================================== */
let pendingOrders = [];
let checkingPending = false;

async function loadPendingOrders() {
    const res = await fetch('/coin/pending?username=testuser').then(r => r.json());
    pendingOrders = res || [];
    renderPendingOrders();
    return pendingOrders;
}

function renderPendingOrders() {
    const emptyEl = document.querySelector('#tab-coin-pending .sb-empty');
    const tableEl = document.getElementById('orders-table');
    const tbody = document.getElementById('orders-body');
    if (!tbody) return;

    if (pendingOrders.length === 0) {
        if (emptyEl) emptyEl.style.display = '';
        if (tableEl) tableEl.style.display = 'none';
        return;
    }
    if (emptyEl) emptyEl.style.display = 'none';
    if (tableEl) tableEl.style.display = '';

    const ticker = currentSymbol.replace(/USDT$/, '').replace('_SPBL', '');
    tbody.innerHTML = pendingOrders.map(o => `
        <tr>
            <td>${ticker}</td>
            <td class="${o.orderType === 'BUY' ? 'up' : 'down'}">${o.orderType === 'BUY' ? '매수' : '매도'}</td>
            <td>${Number(o.targetPrice).toLocaleString()}</td>
            <td>${o.orderCount}</td>
            <td><button onclick="cancelPendingOrder(${o.orderNo})" style="background:none;border:1px solid var(--border);color:var(--text3);padding:2px 8px;border-radius:4px;cursor:pointer;font-size:11px;">취소</button></td>
        </tr>
    `).join('');
}

function checkPendingOrders(price) {
    if (checkingPending || pendingOrders.length === 0) return;
    const toExecute = pendingOrders.filter(o =>
        o.targetPrice &&
        ((o.orderType === 'BUY' && price <= o.targetPrice) ||
         (o.orderType === 'SELL' && price >= o.targetPrice))
    );
    if (toExecute.length === 0) return;
    checkingPending = true;
    Promise.all(toExecute.map(o =>
        fetch('/coin/executePending', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams({ orderNo: o.orderNo, username: o.username, coinCode: o.coinCode, orderType: o.orderType, orderPrice: price, orderCount: o.orderCount })
        }).then(r => r.ok ? r.text() : Promise.reject(r.status))
    )).then(() => {
        checkingPending = false;
        pendingOrders = pendingOrders.filter(o => !toExecute.includes(o));
        loadPendingOrders();
        loadHoldings();
        loadWallet();
        loadOrders();
    }).catch(() => {
        checkingPending = false;
        pendingOrders = pendingOrders.filter(o => !toExecute.includes(o));
    });
}

async function cancelPendingOrder(orderNo) {
    const res = await fetch('/coin/cancelOrder', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({ orderNo, username: 'testuser' })
    }).then(r => r.text());
    if (res === 'success') { loadPendingOrders(); loadHoldings(); loadWallet(); }
}

/* ====================================================
   실시간 댓글 - WebSocket(STOMP)
   ==================================================== */
let stompClient = null;

function connectChat(symbol) {
    if (stompClient && stompClient.connected) {
        stompClient.disconnect();
    }

    const socket = new SockJS('/ws-coin');
    stompClient = Stomp.over(socket);
    stompClient.debug = null;

    stompClient.connect({}, () => {
        stompClient.subscribe('/topic/coin/' + symbol, msg => {
            const dto = JSON.parse(msg.body);
            appendChatMsg(dto.username, dto.content, dto.createdAt, true, dto.imageUrl);
        });
        loadChatHistory(symbol);
    });
}

function loadChatHistory(symbol) {
    fetch('/coin/comments/' + symbol)
        .then(r => r.json())
        .then(list => {
            const msgs = document.getElementById('chat-messages');
            msgs.innerHTML = '';
            if (!list.length) {
                msgs.innerHTML = '<div class="chat-empty"><span class="chat-empty-icon">💬</span><span>첫 댓글을 남겨보세요</span></div>';
                return;
            }
            /* 최신순으로 내려오므로 역순 렌더링 */
            list.slice().reverse().forEach(dto => appendChatMsg(dto.username, dto.content, dto.createdAt, false, dto.imageUrl));
            msgs.scrollTop = msgs.scrollHeight;
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

function appendChatMsg(username, content, createdAt, scroll = true, imageUrl = null) {
    const msgs = document.getElementById('chat-messages');
    const empty = msgs.querySelector('.chat-empty');
    if (empty) empty.remove();

    const safe = s => s.replace(/</g, '&lt;');
    const color = cmAvatarColor(username);
    const initial = username.charAt(0).toUpperCase();
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
            '<div class="cm-avatar" style="background:' + color + '">' + initial + '</div>' +
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
    msgs.appendChild(div);
    if (scroll) msgs.scrollTop = msgs.scrollHeight;
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

connectChat(currentSymbol);

const _chatMsgs = document.getElementById('chat-messages');
if (_chatMsgs) {
    _chatMsgs.addEventListener('mouseenter', () => _chatMsgs.classList.add('scrollbar-visible'));
    _chatMsgs.addEventListener('mouseleave', () => _chatMsgs.classList.remove('scrollbar-visible'));
}


/* ====================================================
   페이지 로드 시 병렬 실행
   ==================================================== */
// 헤더 종목명/티커 업데이트
const tickerName = currentSymbol.replace('USDT', '').replace('USDC', '').replace('_SPBL', '');
const nameEl = document.querySelector('.ph-name');
const tickerEl = document.querySelector('.ph-ticker');
if (nameEl) nameEl.textContent = tickerName;
if (tickerEl) tickerEl.textContent = currentSymbol;

Promise.all([loadTicker(), loadWallet(), loadData(), initSearchMenu(), loadExtraStats()]).then(() => {
    connectWebSocket();
    loadHoldings();
    loadPendingOrders();
    startCountdown();
    updateWatchlistHeartBtn(currentSymbol);
    addToRecent(currentSymbol);
});

/* ====================================================
   종목 검색 및 인기 순위 드롭다운 로직
   ==================================================== */
async function initSearchMenu() {
    const trigger = document.getElementById('search-trigger');
    const dropdown = document.getElementById('search-dropdown');
    const input = document.getElementById('sd-input');

    if (!trigger || !dropdown || !input) return;

    // 1. 트리거 클릭 시 토글
    trigger.addEventListener('click', (e) => {
        e.stopPropagation();
        const isActive = dropdown.classList.toggle('active');
        if (isActive) {
            input.value = '';
            input.focus();
            renderSearchList(popularCoins, true); // 열 때 인기 순위 먼저 표시
        }
    });

    // 2. 외부 클릭 시 닫기
    document.addEventListener('click', () => dropdown.classList.remove('active'));
    dropdown.addEventListener('click', (e) => e.stopPropagation());

    // 3. 전체 코인 데이터 로드 (인기 순위용)
    try {
        const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers');
        const json = await res.json();
        if (json.data) {
            allCoinList = json.data.filter(c => c.symbol.endsWith('USDT'));
            // 거래대금 순으로 정렬하여 상위 5개 추출
            popularCoins = [...allCoinList]
                .sort((a, b) => parseFloat(b.quoteVolume) - parseFloat(a.quoteVolume))
                .slice(0, 5);
        }
    } catch (e) { console.error("코인 목록 로드 실패", e); }

    // 4. 검색 필터링 이벤트
    input.addEventListener('input', () => {
        const keyword = input.value.trim().toUpperCase();
        if (!keyword) {
            document.getElementById('sd-label').textContent = '인기 검색';
            renderSearchList(popularCoins, true);
            return;
        }

        const filtered = allCoinList.filter(c =>
            c.symbol.includes(keyword) || 
            c.symbol.replace('USDT', '').includes(keyword)
        ).slice(0, 20); // 최대 20개만 표시

        document.getElementById('sd-label').textContent = '검색 결과';
        renderSearchList(filtered, false);
    });
}

function renderSearchList(list, isPopular) {
    const container = document.getElementById('sd-list');
    if (!container) return;

    container.innerHTML = list.map((c, i) => {
        const ticker = c.symbol.replace('USDT', '');
        const change = parseFloat(c.change24h) * 100;
        const cls = change >= 0 ? 'up' : 'down';
        const sign = change >= 0 ? '+' : '';
        const logoUrl = `https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/${ticker.toLowerCase()}.png`;

        return `
            <div class="sd-item" onclick="location.href='/coin/chart?symbol=${c.symbol}'">
                ${isPopular ? `<span class="sd-rank">${i + 1}</span>` : ''}
                <div class="sd-coin-logo">
                    <img src="${logoUrl}" alt="${ticker}" onerror="this.style.display='none';this.parentElement.textContent='${ticker.slice(0, 2)}'">
                </div>
                <div class="sd-info">
                    <div class="sd-name-row">
                        <span class="sd-name">${ticker}</span>
                        <span class="sd-symbol">${c.symbol}</span>
                    </div>
                </div>
                <div class="sd-change ${cls}">${sign}${change.toFixed(2)}%</div>
            </div>
        `;
    }).join('');
}

/* 창 크기 변경 시 인라인 스타일 초기화
   드래그로 설정된 고정 높이/너비가 미디어쿼리를 막는 문제 해결 */
window.addEventListener('resize', () => {
    const mid = document.getElementById('panel-middle');
    const order = document.getElementById('panel-order-wrap');
    const hoga = document.getElementById('panel-hoga');
    const chart = document.getElementById('panel-chart');

    if (window.innerWidth <= 1100) {
        mid.style.width = '';
        order.style.height = '';
        hoga.style.height = '';
        chart.style.height = '';
    }
});


/* ====================================================
   하단 티커 바 - 15초마다 종목 가격 갱신
   ==================================================== */
const TICKER_SYMBOLS = [currentSymbol, 'ETHUSDT', 'XRPUSDT', 'SOLUSDT', 'DOGEUSDT', 'ADAUSDT', 'AVAXUSDT', 'DOTUSDT'];

async function loadTickerBar() {
    const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers')
        .then(r => r.json()).catch(() => null);
    if (!res || !res.data) return;

    const filtered = res.data.filter(d => TICKER_SYMBOLS.includes(d.symbol));
    const track = document.getElementById('ticker-track');

    /* 최초 1회: HTML 구조 생성 (무한 스크롤용 2세트)
       이후 갱신 시에는 텍스트만 교체해서 끊김 방지 */
    if (!track.children.length) {
        const items = filtered.map(d => {
            const change = parseFloat(d.change24h) * 100;
            const cls = change >= 0 ? 'up' : 'down';
            const sign = change >= 0 ? '+' : '';
            return `<div class="ticker-item">
                <span class="ticker-name">${d.symbol.replace('USDT', '')}</span>
                <span class="ticker-price">${parseFloat(d.lastPr).toLocaleString()}</span>
                <span class="ticker-change ${cls}">${sign}${change.toFixed(2)}%</span>
            </div>`;
        }).join('');
        track.innerHTML = items + items + items + items;
        /* 두 번째 세트 첫 아이템의 offsetLeft = 정확한 첫 세트 너비 */
        setTimeout(() => {
            const secondSet = track.children[filtered.length];
            tickerHalfWidth = track.scrollWidth / 2;
            tickerTrackEl = track;
        }, 500);
        return;
    }

    /* 이후 갱신: 가격·변동률 텍스트만 교체 (애니메이션 유지) */
    const allItems = track.querySelectorAll('.ticker-item');
    filtered.forEach((d, i) => {
        const change = parseFloat(d.change24h) * 100;
        const cls = change >= 0 ? 'up' : 'down';
        const sign = change >= 0 ? '+' : '';
        [allItems[i], allItems[i + filtered.length]].forEach(el => {
            if (!el) return;
            el.querySelector('.ticker-price').textContent = parseFloat(d.lastPr).toLocaleString();
            const changeEl = el.querySelector('.ticker-change');
            changeEl.textContent = `${sign}${change.toFixed(2)}%`;
            changeEl.className = `ticker-change ${cls}`;
        });
    });
}

/* CSS 애니메이션 대신 JS로 스크롤 제어 */
let tickerX = 0;
let tickerPaused = false;
let tickerHalfWidth = 0;
let tickerTrackEl = null;

function animateTicker() {
    if (!tickerPaused && tickerHalfWidth > 0 && tickerTrackEl) {
        tickerX -= 0.6;
        console.log(tickerHalfWidth, document.getElementById('ticker-track').scrollWidth)
        if (Math.abs(tickerX) >= tickerHalfWidth) tickerX += tickerHalfWidth;
        tickerTrackEl.style.transform = `translateX(${tickerX}px)`;
    }
    requestAnimationFrame(animateTicker);
}

const _tickerEl = document.getElementById('ticker-track');
_tickerEl.addEventListener('mouseenter', () => tickerPaused = true);
_tickerEl.addEventListener('mouseleave', () => tickerPaused = false);

animateTicker();

loadTickerBar();
setInterval(loadTickerBar, 15000);