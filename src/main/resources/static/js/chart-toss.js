/* =====================================================
   chart-toss.js
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
let countdownPrimitive = null;   // 봉 카운트다운 플러그인 인스턴스

let currentGranularity = '1min'; // 현재 타임프레임 (REST API 파라미터)
let currentChannel = 'candle1m'; // 현재 WebSocket 구독 채널명

let currentWs = null;    // 현재 WebSocket 연결 객체
let lastPrice = 0;       // 마지막으로 수신된 현재가
let prevClose = 0;       // 전일 마감가 (전일대비 % 계산에 사용)
let orderSide = 'buy';   // 현재 주문 방향 ('buy' 또는 'sell')

let walletBalance = 0;   // 가용 USDT 잔고
let allData = [];         // 전체 캔들 데이터 배열
let isLoadingMore = false; // 과거 데이터 추가 로드 중 여부 (중복 요청 방지)

let isLog = false;           // 로그 스케일 여부
let currentTfSeconds = 60;   // 현재 타임프레임의 초 단위 길이 (카운트다운에 사용)
let showCountdown = true;    // 봉 카운트다운 표시 여부


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
    '1day': { channel: 'candle1D', restGran: '1day', seconds: 86400 },
    '3day': { channel: 'candle3D', restGran: '3day', seconds: 259200 },
    '1week': { channel: 'candle1W', restGran: '1week', seconds: 604800 },
    '1month': { channel: 'candle1M', restGran: '1M', seconds: 2592000 },
};


/* ====================================================
   차트 생성 (LightweightCharts)
   ==================================================== */
const container = document.getElementById('chart-container');
const chart = LightweightCharts.createChart(container, {
    autoSize: true, // 컨테이너 크기에 맞게 자동 리사이즈
    layout: { background: { color: '#16161A' }, textColor: 'rgba(255,255,255,0.5)' },
    grid: {
        vertLines: { color: 'rgba(255,255,255,0.04)' },
        horzLines: { color: 'rgba(255,255,255,0.04)' }
    },
    timeScale: { timeVisible: true, secondsVisible: false, borderColor: 'rgba(255,255,255,0.07)' },
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
    layout: { background: { color: '#16161A' }, textColor: 'rgba(255,255,255,0.5)' },
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
   최근 200개 봉 데이터를 가져와 차트에 표시
   ==================================================== */
async function loadData() {
    const res = await fetch(
        'https://api.bitget.com/api/v2/spot/market/candles?symbol=BTCUSDT&granularity=' + currentGranularity + '&limit=200'
    ).then(r => r.json());
    if (res.code !== '00000') return;

    /* API 응답: [타임스탬프(ms), 시가, 고가, 저가, 종가, 거래량]
       타임스탬프를 초 단위로 변환 (LightweightCharts는 Unix 초 단위 사용) */
    allData = res.data.map(item => ({
        time: Math.floor(item[0] / 1000),
        open: parseFloat(item[1]),
        high: parseFloat(item[2]),
        low: parseFloat(item[3]),
        close: parseFloat(item[4]),
        volume: parseFloat(item[5])
    })).sort((a, b) => a.time - b.time); // 시간 오름차순 정렬

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
            const endTimeMs = oldestTime * 1000 - 1; // 현재 가장 오래된 봉 바로 이전 시간

            const res = await fetch(
                'https://api.bitget.com/api/v2/spot/market/candles?symbol=BTCUSDT&granularity=' + currentGranularity + '&limit=200&endTime=' + endTimeMs
            ).then(r => r.json());

            if (res.code === '00000' && res.data && res.data.length > 0) {
                const older = res.data.map(item => ({
                    time: Math.floor(item[0] / 1000),
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
    event.target.classList.add('active');

    /* 현재 보이는 범위를 기억해서 타임프레임 변경 후에도 비슷한 위치 유지 */
    const lr = chart.timeScale().getVisibleLogicalRange();
    const totalBars = window.currentDataLength || 200;
    const rightOffset = lr ? lr.to - totalBars : 10;
    const barCount = lr ? lr.to - lr.from : 50;

    currentGranularity = TF_MAP[gran].restGran;
    currentChannel = TF_MAP[gran].channel;
    currentTfSeconds = TF_MAP[gran].seconds;

    /* 카운트다운 플러그인이 있으면 타임프레임에 맞게 옵션 업데이트 */
    if (countdownPrimitive) {
        countdownPrimitive.applyOptions({
            timeframeInSeconds: currentTfSeconds,
            timeLabelFormatter: currentTfSeconds >= 259200
                /* 3D 이상: "Xd Yh" 형식 */
                ? (ttcc) => {
                    if (ttcc.days > 0) return ttcc.days + 'd ' + ttcc.hours + 'h';
                    if (ttcc.hours > 0) return ttcc.hours + 'h ' + ttcc.minutes + 'm';
                    if (ttcc.minutes > 0) return ttcc.minutes + 'm ' + ttcc.seconds + 's';
                    return ttcc.seconds + 's';
                }
                /* 그 외: "MM:SS" 또는 "HH:MM:SS" 형식 */
                : (ttcc) => {
                    const t = ttcc.days * 86400 + ttcc.hours * 3600 + ttcc.minutes * 60 + ttcc.seconds;
                    const h = Math.floor(t / 3600);
                    const m = Math.floor((t % 3600) / 60);
                    const s = t % 60;
                    if (currentTfSeconds >= 43200 || h > 0)
                        return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
                    return String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
                }
        });
    }

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
        connectWebSocket();
    });
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
   lwc-plugin-countdown-to-close 라이브러리 사용
   ==================================================== */
function startCountdown() {
    if (!countdownPrimitive) {
        countdownPrimitive = new CountdownToClose.CountdownToClose({
            customLastPriceLine: true,
            timeframeInSeconds: currentTfSeconds,
            timeLabelFormatter: (ttcc) => {
                const t = ttcc.days * 86400 + ttcc.hours * 3600 + ttcc.minutes * 60 + ttcc.seconds;
                const h = Math.floor(t / 3600);
                const m = Math.floor((t % 3600) / 60);
                const s = t % 60;
                if (currentTfSeconds >= 43200 || h > 0)
                    return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
                return String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
            }
        });
        /* 카운트다운 플러그인이 마지막 가격선을 커스텀으로 그리므로 기본 가격선 숨김 */
        candleSeries.applyOptions({ lastValueVisible: false, priceLineVisible: false });
        candleSeries.attachPrimitive(countdownPrimitive);
    }
}

function toggleCountdown(enabled) {
    showCountdown = enabled;
    if (enabled) {
        startCountdown();
        countdownPrimitive.applyOptions({ showLabels: true });
    } else {
        if (countdownPrimitive) countdownPrimitive.applyOptions({ showLabels: false });
        candleSeries.applyOptions({ lastValueVisible: true, priceLineVisible: true });
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
        /* 연결 후 구독 메시지 전송 */
        ws.send(JSON.stringify({
            op: 'subscribe',
            args: [
                { instType: 'SPOT', channel: currentChannel, instId: 'BTCUSDT' },
                { instType: 'SPOT', channel: 'books15', instId: 'BTCUSDT' }
            ]
        }));
        /* 20초마다 ping 전송 (연결 유지) */
        setInterval(() => ws.readyState === 1 && ws.send('ping'), 20000);
    };

    ws.onmessage = (event) => {
        if (ws !== currentWs) return; // 이전 연결의 메시지는 무시
        if (event.data === 'pong') return;
        const msg = JSON.parse(event.data);
        if (!msg.data) return;

        /* 호가 채널 */
        if (msg.arg && (msg.arg.channel === 'books5' || msg.arg.channel === 'books15')) {
            updateHoga(msg.data[0]);
            return;
        }

        /* 캔들 채널 (기존 코드) */
        const item = msg.data[0];
        const bar = {
            time: Math.floor(item[0] / 1000),
            open: parseFloat(item[1]),
            high: parseFloat(item[2]),
            low: parseFloat(item[3]),
            close: parseFloat(item[4])
        };

        /* 이전 봉보다 오래된 데이터는 무시 */
        if (window.lastCandleTime && bar.time < window.lastCandleTime) return;

        candleSeries.update(bar); // 차트 실시간 업데이트
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
    const pEl = document.getElementById('holding-price');
    const pnlEl = document.getElementById('holding-pnl');
    if (!pEl || !pnlEl) return;
    const avg = parseFloat(pEl.closest('tr').children[2].textContent);
    const cnt = parseFloat(pEl.closest('tr').children[1].textContent);
    const pnl = (lastPrice - avg) * cnt;
    pEl.textContent = lastPrice.toFixed(2);
    pnlEl.textContent = (pnl >= 0 ? '+' : '') + pnl.toFixed(2) + ' USDT';
    pnlEl.style.color = pnl >= 0 ? 'var(--up)' : 'var(--down)';
}


/* ====================================================
   24h 티커 로드 (Bitget REST API)
   현재가·변동률·고가·저가·거래량 정보 가져오기
   ==================================================== */
async function loadTicker() {
    try {
        const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers?symbol=BTCUSDT').then(r => r.json());
        if (res.code === '00000' && res.data && res.data[0]) {
            const d = res.data[0];
            const price = parseFloat(d.lastPr);
            const chgPct = parseFloat(d.change24h) * 100; // 소수 → 퍼센트 변환

            /* 전일 마감가 계산: price = prevClose × (1 + change24h)
               → prevClose = price / (1 + change24h) */
            const absChange = price * parseFloat(d.change24h) / (1 + parseFloat(d.change24h));
            prevClose = price / (1 + parseFloat(d.change24h));

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

            document.getElementById('ph-high').textContent = parseFloat(d.high24h).toLocaleString();
            document.getElementById('ph-low').textContent = parseFloat(d.low24h).toLocaleString();
            document.getElementById('ph-vol').textContent = parseFloat(d.baseVolume).toFixed(0) + ' BTC';
        }
    } catch (e) { }
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
        const h = parseFloat(document.getElementById('bp-holdings-body')
            ?.querySelector('tr')?.children[1]?.textContent) || 0;
        av.textContent = h.toFixed(6) + ' BTC';
    }
    calcAmount();
}

/* 지정가/시장가 선택 */
function selectOrderType(btn) {
    document.querySelectorAll('.order-type-btn').forEach(b => b.classList.remove('sel'));
    btn.classList.add('sel');
}

/* 잔고 비율로 수량 자동 계산 */
function setPercent(pct) {
    if (orderSide === 'sell') {
        const h = parseFloat(document.getElementById('bp-holdings-body')
            ?.querySelector('tr')?.children[1]?.textContent) || 0;
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
    if (!qty) { alert('수량을 입력하세요'); return; }

    fetch('/coin/' + side, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
            username: 'testuser',
            coinCode: 'BTCUSDT',
            orderPrice: lastPrice,
            orderCount: qty
        })
    })
        .then(r => r.text())
        .then(result => {
            if (result === 'success') {
                alert((side === 'buy' ? '매수' : '매도') + ' 주문 완료!');
                loadWallet();
                loadHoldings();
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

/* 서버에서 보유 코인 목록 가져와 테이블에 렌더링 */
async function loadHoldings() {
    const res = await fetch('/coin/holdings?username=testuser').then(r => r.json());
    const tbody = document.getElementById('bp-holdings-body');
    tbody.innerHTML = '';

    if (res && res.length > 0) {
        document.getElementById('bp-empty').style.display = 'none';
        document.getElementById('bp-holdings-table').style.display = 'table';
        let rows = '';
        res.forEach(h => {
            const pnl = (lastPrice - h.avgPrice) * h.coinCount;
            const pc = pnl >= 0 ? 'var(--up)' : 'var(--down)';
            rows += '<tr>'
                + '<td>' + h.coinCode + '</td>'
                + '<td>' + h.coinCount.toFixed(6) + '</td>'
                + '<td>' + h.avgPrice.toFixed(2) + '</td>'
                + '<td id="holding-price">' + lastPrice.toFixed(2) + '</td>'
                + '<td id="holding-pnl" style="color:' + pc + '">' + (pnl >= 0 ? '+' : '') + pnl.toFixed(2) + ' USDT</td>'
                + '</tr>';
        });
        tbody.innerHTML = rows;
    } else {
        document.getElementById('bp-empty').style.display = '';
        document.getElementById('bp-holdings-table').style.display = 'none';
    }
}


/* ====================================================
   실시간 댓글 (로컬 전용, 서버 미연동)
   ==================================================== */
function sendChat() {
    const inp = document.getElementById('chat-input');
    const text = inp.value.trim();
    if (!text) return;

    const msgs = document.getElementById('chat-messages');
    const empty = msgs.querySelector('.chat-empty');
    if (empty) empty.remove(); // 빈 상태 메시지 제거

    const div = document.createElement('div');
    div.className = 'chat-msg';
    /* XSS 방지: < 를 &lt;로 이스케이프 */
    div.innerHTML = '<span class="cm-name">나</span><span class="cm-text">' + text.replace(/</g, '&lt;') + '</span>';
    msgs.appendChild(div);
    msgs.scrollTop = msgs.scrollHeight; // 스크롤 맨 아래로
    inp.value = '';
}

/* 엔터 키로 전송 */
document.getElementById('chat-input').addEventListener('keydown', e => {
    if (e.key === 'Enter') sendChat();
});


/* ====================================================
   초기 실행
   페이지 로드 시 순서대로 실행
   ==================================================== */
loadTicker();  // 현재가·변동률 로드
loadWallet();  // 지갑 잔고 로드
loadData().then(() => {
    connectWebSocket(); // 데이터 로드 완료 후 WebSocket 연결
    loadHoldings();     // 보유 내역 로드 (lastPrice 설정 이후에 실행)
    startCountdown();   // 봉 카운트다운 시작
});

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
const TICKER_SYMBOLS = ['BTCUSDT', 'ETHUSDT', 'XRPUSDT', 'SOLUSDT', 'DOGEUSDT', 'ADAUSDT', 'AVAXUSDT', 'DOTUSDT'];

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