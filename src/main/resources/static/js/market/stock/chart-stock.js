/* =====================================================
   chart-toss.js
   차트 페이지 전용 JavaScript
   - Bitget API로 캔들 데이터 로드
   - LightweightCharts 라이브러리로 차트 렌더링
   - WebSocket으로 실시간 가격 수신
   - 주문·지갑·보유 내역 처리
   ===================================================== */
   
/* 전역 상태 변수 */
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
   [주식 버전] 타임프레임 매핑 테이블
   - period: 한국투자증권 API의 FID_PERIOD_DIV_CODE (D:일, W:주, M:월)
   - type: 분봉/일봉 구분 (분봉은 별도 API 호출을 위해 필요)
   - seconds: 초 단위 길이
   ==================================================== */
const TF_MAP = {
    // 일/주/월 데이터
    'day': { period: 'D', type: 'daily', seconds: 86400 },
    'week': { period: 'W', type: 'daily', seconds: 604800 },
    'month': { period: 'M', type: 'daily', seconds: 2592000 },

    // 분봉 데이터 (필요 시 확장)
    '1min': { period: '1', type: 'minute', seconds: 60 },
    '5min': { period: '5', type: 'minute', seconds: 300 },
    '30min': { period: '30', type: 'minute', seconds: 1800 },
    '60min': { period: '60', type: 'minute', seconds: 3600 },
};

/* ====================================================
   [주식 버전] 차트 생성 (LightweightCharts)
   ==================================================== */
const container = document.getElementById('chart-container');
const chart = LightweightCharts.createChart(container, {
    autoSize: true,
    layout: {
        background: { color: '#16161A' },
        textColor: 'rgba(255,255,255,0.5)',
        // 주식 차트용 폰트 설정 (Pretendard 등)
        fontFamily: 'Pretendard, -apple-system, BlinkMacSystemFont, sans-serif',
    },
    grid: {
        vertLines: { color: 'rgba(255,255,255,0.04)' },
        horzLines: { color: 'rgba(255,255,255,0.04)' }
    },
    // 주식은 9시~15시 30분 장이므로 시간 표시 최적화
    timeScale: {
        timeVisible: true,
        secondsVisible: false,
        borderColor: 'rgba(255,255,255,0.07)',
        fixLeftEdge: true, // 데이터가 적을 때 왼쪽 여백 방지
    },
    rightPriceScale: {
        borderColor: 'rgba(255,255,255,0.07)',
        // 주식 가격은 코인보다 크므로(예: 2,500,000원) 여유 공간 확보
        entireTextOnly: true,
        autoScale: true,
    },
    /* 가격 포맷 설정: 주식은 보통 소수점이 없으므로 정수로 표시 */
    localization: {
        priceFormatter: price => {
            return Math.floor(price).toLocaleString() + '원';
        },
    },
    crosshair: {
        mode: LightweightCharts.CrosshairMode.Normal,
        vertLine: {
            color: 'rgba(255,255,255,0.2)',
            labelBackgroundColor: '#3182F6', // 십자선 라벨을 토스 블루 색상으로 강조
        },
        horzLine: {
            color: 'rgba(255,255,255,0.2)',
            labelBackgroundColor: '#3182F6',
        }
    },
});

/* ====================================================
   [주식 버전] 캔들 시리즈 설정
   - 한국 주식 시장 표준 색상 적용
   - 가격 라인 및 가독성 옵션 추가
   ==================================================== */
const candleSeries = chart.addSeries(LightweightCharts.CandlestickSeries, {
    // 상승봉: 토스 레드 (#F04452)
    upColor: '#F04452',
    borderUpColor: '#F04452',
    wickUpColor: '#F04452',

    // 하락봉: 토스 블루 (#2563EB)
    downColor: '#2563EB',
    borderDownColor: '#2563EB',
    wickDownColor: '#2563EB',

    // 가격 라인 설정 (우측 축에 현재가 표시선)
    priceLineVisible: true,      // 현재가 선 표시
    priceLineWidth: 1,           // 선 두께
    priceLineColor: '#F04452',   // 현재가 선 색상 (보통 현재가에 맞춰 변하게 처리 가능)
    priceLineStyle: LightweightCharts.LineStyle.Dashed, // 점선 스타일

    // 가독성 설정
    lastValueVisible: true,      // 우측 축에 최종값 라벨 표시
    title: '현재가',              // 시리즈 이름
});

/* ====================================================
   [주식 버전] 보조 지표 시리즈 설정
   - 이동평균선(MA): 주식 시장 관례 색상 적용
   - 볼린저 밴드(BB) & 일목균형표: 코인 버전 유지
   ==================================================== */

/* 1. 이동평균선 (MA5, MA20, MA60)
   - 주식은 5(황), 20(적), 60(녹) 혹은 5(분홍), 20(황) 등을 많이 쓰지만 
   - 팀원의 기존 디자인 톤을 해치지 않는 선에서 직관적인 색상 유지 */
const ma5Series = chart.addSeries(LightweightCharts.LineSeries, {
    color: '#FF9800', lineWidth: 1, title: '5일선', visible: false, priceLineVisible: false
});
const ma20Series = chart.addSeries(LightweightCharts.LineSeries, {
    color: '#F04452', lineWidth: 1, title: '20일선', visible: false, priceLineVisible: false
});
const ma60Series = chart.addSeries(LightweightCharts.LineSeries, {
    color: '#4CAF50', lineWidth: 1, title: '60일선', visible: false, priceLineVisible: false
});

/* 2. 볼린저 밴드 (상단·중간·하단)
   - 변동성 확인용 점선 스타일 유지 */
const bbUpperSeries = chart.addSeries(LightweightCharts.LineSeries, {
    color: '#FF5722', lineWidth: 1, lineStyle: LightweightCharts.LineStyle.Dashed, title: 'BB 상단', visible: false, priceLineVisible: false
});
const bbMiddleSeries = chart.addSeries(LightweightCharts.LineSeries, {
    color: '#FF572288', lineWidth: 1, title: 'BB 중심', visible: false, priceLineVisible: false
});
const bbLowerSeries = chart.addSeries(LightweightCharts.LineSeries, {
    color: '#FF5722', lineWidth: 1, lineStyle: LightweightCharts.LineStyle.Dashed, title: 'BB 하단', visible: false, priceLineVisible: false
});

/* 3. 일목균형표 (전환선·기준선·선행A·선행B·후행)
   - 전문적인 분석을 위한 지표 세트 유지 */
const ichiTenkanSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#E91E63', lineWidth: 1, title: '전환', visible: false, priceLineVisible: false });
const ichiKijunSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#3182F6', lineWidth: 1, title: '기준', visible: false, priceLineVisible: false });
const ichiSpanASeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#4CAF5066', lineWidth: 1, title: '선행A', visible: false, priceLineVisible: false });
const ichiSpanBSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#FF980066', lineWidth: 1, title: '선행B', visible: false, priceLineVisible: false });
const ichiChikouSeries = chart.addSeries(LightweightCharts.LineSeries, { color: '#9E9E9E', lineWidth: 1, title: '후행', visible: false, priceLineVisible: false });


/* ====================================================
   [주식 버전] 거래량 히스토그램 시리즈
   - priceScaleId: 'volume' (가격과 겹치지 않게 별도 축 사용)
   - 한국 주식 시장 특성에 맞는 수치 단위 적용
   ==================================================== */
const volumeSeries = chart.addSeries(LightweightCharts.HistogramSeries, {
    priceFormat: {
        type: 'volume',
        // 주식은 거래량이 수백만 단위이므로 가독성 있게 표시
    },
    priceScaleId: 'volume',
    priceLineVisible: false,
    title: '거래량'
});

/* 거래량 차트 위치 설정
   - top: 0.8 (상단 80% 비우고 하단 20%만 사용)
   - 가격 캔들과 겹쳐 보이지만 아래쪽에 깔리게 설정 */
chart.priceScale('volume').applyOptions({
    scaleMargins: {
        top: 0.8,
        bottom: 0
    }
});


/* ====================================================
   [주식 버전] RSI 차트 (별도 인스턴스)
   - 메인 차트와 디자인 톤앤매너 일치
   - 과매수(70)/과매도(30) 기준선 가독성 강화
   ==================================================== */
const rsiContainer = document.getElementById('rsi-container');
const rsiChart = LightweightCharts.createChart(rsiContainer, {
    autoSize: true,
    layout: {
        background: { color: '#16161A' },
        textColor: 'rgba(255,255,255,0.5)',
        fontFamily: 'Pretendard, sans-serif',
    },
    grid: {
        vertLines: { color: 'rgba(255,255,255,0.04)' },
        horzLines: { color: 'rgba(255,255,255,0.04)' }
    },
    // 하단 시간축 설정 (메인 차트와 동기화될 예정)
    timeScale: {
        timeVisible: true,
        secondsVisible: false,
        borderColor: 'rgba(255,255,255,0.07)',
    },
    rightPriceScale: {
        borderColor: 'rgba(255,255,255,0.07)',
        scaleMargins: { top: 0.2, bottom: 0.2 }, // RSI 값(0~100)이 위아래 꽉 차지 않게 여백
        entireTextOnly: true,
    },
    crosshair: { mode: LightweightCharts.CrosshairMode.Normal },
});

/* RSI 지표선 (보라색 계열 유지) */
const rsiSeries = rsiChart.addSeries(LightweightCharts.LineSeries, {
    color: '#9C27B0',
    lineWidth: 1.5, // 지표선은 조금 더 선명하게
    title: 'RSI(14)',
    priceLineVisible: false
});

/* 과매수/과매도 기준선 (주식 시장 표준 70/30) */
const rsiOverbought = rsiChart.addSeries(LightweightCharts.LineSeries, {
    color: '#F04452', // 과매수(경고)는 빨간색 점선
    lineWidth: 1,
    lineStyle: LightweightCharts.LineStyle.Dashed,
    priceLineVisible: false,
    lastValueVisible: true, // 우측에 '70' 라벨 표시
});

const rsiOversold = rsiChart.addSeries(LightweightCharts.LineSeries, {
    color: '#2563EB', // 과매도(기회)는 파란색 점선
    lineWidth: 1,
    lineStyle: LightweightCharts.LineStyle.Dashed,
    priceLineVisible: false,
    lastValueVisible: true, // 우측에 '30' 라벨 표시
});


/* ====================================================
   [주식 버전] 지표 활성화 상태 관리
   ==================================================== */
// 상태값은 동일하게 유지합니다.
const indState = { ma5: false, ma20: false, ma60: false, bb: false, ichimoku: false, rsi: false };

/* 지표 버튼 스타일 변경 (on: 해당 지표 색상으로 강조 / off: 초기화)
   - 색상 매핑을 앞서 설정한 주식용 시리즈 색상과 일치시켰습니다. */
function setIndBtnStyle(name, on) {
    const btn = document.getElementById('ind-' + name);
    if (!btn) return; // 버튼이 없는 경우 방어 코드

    const colors = {
        ma5: '#FF9800',      // 5일선 (황금색)
        ma20: '#F04452',     // 20일선 (생명선 - 토스 레드)
        ma60: '#4CAF50',     // 60일선 (수급선 - 녹색)
        bb: '#FF5722',       // 볼린저 밴드 (오렌지)
        ichimoku: '#E91E63', // 일목균형표 (진분홍)
        rsi: '#9C27B0'       // RSI (보라)
    };

    const c = colors[name];

    if (on) {
        // 활성화 시: 테두리, 글자색 변경 및 배경에 살짝 색상 투입 (투명도 10% 정도)
        btn.style.borderColor = c;
        btn.style.color = c;
        btn.style.background = c + '18';
        btn.style.fontWeight = '700';
    } else {
        // 비활성화 시: 초기화 (CSS 클래스 기본값으로)
        btn.style.borderColor = '';
        btn.style.color = '';
        btn.style.background = '';
        btn.style.fontWeight = '';
    }
}


/* ====================================================
   [주식 버전] 일목균형표 계산 헬퍼
   - 특정 기간 내 (최고가 + 최저가) / 2 반환
   - 데이터 부족 시 예외 처리 추가
   ==================================================== */
function ichiAvg(arr, i, period) {
    // 1. 계산할 데이터 범위(슬라이스) 추출
    const sl = arr.slice(Math.max(0, i - period + 1), i + 1);

    // 2. 데이터가 아예 없거나 기간이 부족할 경우 방어 처리
    if (sl.length === 0) return null;

    // 3. 최고가와 최저가의 중간값 계산
    const high = Math.max(...sl.map(d => d.high));
    const low = Math.min(...sl.map(d => d.low));

    // 4. 숫자가 유효하지 않을 경우(NaN 등) 방어 처리
    if (isNaN(high) || isNaN(low)) return null;

    return (high + low) / 2;
}


/* ====================================================
   [주식 버전] 전체 지표 계산 및 차트 반영
   - 캔들, 거래량, 이동평균선 등을 일괄 계산하여 렌더링
   ==================================================== */
function updateAllSeries(data) {
    if (!data || data.length === 0) return;

    // 1. 메인 캔들 시리즈 데이터 설정
    candleSeries.setData(data);

    // 전역 변수 업데이트 (실시간 데이터 비교용)
    window.currentDataLength = data.length;
    window.lastCandleTime = data[data.length - 1].time;

    // 2. 거래량 시리즈 설정
    // 주식은 전일 종가 대비가 아닌 '당일 시가 vs 종가'로 색상을 결정하는 경우가 많습니다.
    volumeSeries.setData(data.map(d => ({
        time: d.time,
        value: d.volume,
        // 양봉이면 토스 레드, 음봉이면 토스 블루 (투명도 44 적용)
        color: d.close >= d.open ? '#F0445244' : '#2563EB44'
    })));

    /* --- 이어서 이동평균선(MA) 계산 로직 시작 --- */

    /* [주식 버전] 이동평균선 계산
           - i번째 봉의 MA = 직전 N개 봉 종가(close)의 산술 평균
           - 주식 가격은 원 단위이므로 최종 평균값에 Math.floor 적용 권장 */
    const ma5D = [], ma20D = [], ma60D = [];

    data.forEach((d, i) => {
        // 5일 이평선 (단기 추세)
        if (i >= 5) {
            const avg = data.slice(i - 5, i).reduce((s, c) => s + c.close, 0) / 5;
            ma5D.push({ time: d.time, value: Math.floor(avg) });
        }
        // 20일 이평선 (심리선/수급선)
        if (i >= 20) {
            const avg = data.slice(i - 20, i).reduce((s, c) => s + c.close, 0) / 20;
            ma20D.push({ time: d.time, value: Math.floor(avg) });
        }
        // 60일 이평선 (중기 추세/분기선)
        if (i >= 60) {
            const avg = data.slice(i - 60, i).reduce((s, c) => s + c.close, 0) / 60;
            ma60D.push({ time: d.time, value: Math.floor(avg) });
        }
    });

    // 계산된 데이터를 각 시리즈에 반영
    ma5Series.setData(ma5D);
    ma20Series.setData(ma20D);
    ma60Series.setData(ma60D);


    /* [주식 버전] 볼린저 밴드 계산
           - 20일 이동평균(중심선)과 표준편차의 2배수를 이용해 상/하단선 산출
           - 주식 가격 특성에 맞춰 정수 처리(Math.floor) 적용 */
    const bbU = [], bbM = [], bbL = [];

    data.forEach((d, i) => {
        if (i < 20) return; // 최소 20개의 데이터가 쌓인 시점부터 계산

        const sl = data.slice(i - 20, i);
        // 1. 20일 이동평균(평균값) 계산
        const avg = sl.reduce((s, c) => s + c.close, 0) / 20;

        // 2. 표준편차(Standard Deviation) 계산
        // 분산(Variance)의 제곱근
        const std = Math.sqrt(sl.reduce((s, c) => s + Math.pow(c.close - avg, 2), 0) / 20);

        // 3. 상단, 중간, 하단 밴드 데이터 생성
        // 주식 가격 가독성을 위해 정수로 내림 처리
        bbU.push({ time: d.time, value: Math.floor(avg + 2 * std) }); // 상단선
        bbM.push({ time: d.time, value: Math.floor(avg) });           // 중심선
        bbL.push({ time: d.time, value: Math.floor(avg - 2 * std) }); // 하단선
    });

    // 계산된 데이터를 차트 시리즈에 반영
    bbUpperSeries.setData(bbU);
    bbMiddleSeries.setData(bbM);
    bbLowerSeries.setData(bbL);

    /* [주식 버전] 일목균형표 계산
           - 전환선(9), 기준선(26), 선행스팬A/B, 후행스팬 산출
           - 주식 가격 특성에 맞게 Math.floor 적용 및 구름대 가독성 확보 */
    const tk = [], kj = [], sA = [], sB = [], ck = [];

    data.forEach((d, i) => {
        // 1. 전환선 (9일간 최고/최저의 평균)
        if (i >= 8) {
            const val = ichiAvg(data, i, 9);
            if (val) tk.push({ time: d.time, value: Math.floor(val) });
        }

        // 2. 기준선 (26일간 최고/최저의 평균)
        if (i >= 25) {
            const valKj = ichiAvg(data, i, 26);
            const valTk = ichiAvg(data, i, 9); // 선행A 계산용

            if (valKj) {
                kj.push({ time: d.time, value: Math.floor(valKj) });

                // 3. 선행스팬A (전환선+기준선의 평균을 26봉 앞에 표시해야 하지만, 
                // 라이브러리 구조상 현재 시간에 데이터를 넣고 나중에 시각적으로 밀어주는 방식이 일반적입니다.)
                if (valTk) {
                    sA.push({ time: d.time, value: Math.floor((valTk + valKj) / 2) });
                }
            }

            // 4. 선행스팬B (52일간 최고/최저의 평균)
            const valSb = ichiAvg(data, i, 52);
            if (valSb) sB.push({ time: d.time, value: Math.floor(valSb) });
        }

        // 5. 후행스팬 (현재 종가를 26봉 뒤 과거 시간에 표시)
        // i+26 위치의 시간값을 가져와서 현재의 close를 매핑
        if (i + 26 < data.length) {
            ck.push({ time: data[i + 26].time, value: d.close });
        }
    });

    // 계산된 데이터를 각 시리즈에 반영
    ichiTenkanSeries.setData(tk);
    ichiKijunSeries.setData(kj);
    ichiSpanASeries.setData(sA);
    ichiSpanBSeries.setData(sB);
    ichiChikouSeries.setData(ck);

    /* [주식 버전] RSI 계산 (14일 기준)
           - 과매수/과매도 판단을 위한 상대강도지수 산출
           - 메인 차트와의 데이터 정합성 유지 */
    const rsiD = [];

    for (let i = 14;i < data.length;i++) {
        let g = 0; // gain (상승폭 합계)
        let l = 0; // loss (하락폭 합계)

        for (let j = i - 13;j <= i;j++) {
            const diff = data[j].close - data[j - 1].close;
            if (diff > 0) g += diff;
            else l -= diff;
        }

        // RSI 공식 적용 (분모가 0이 되는 것 방지: l || 1)
        const rs = g / (l || 1);
        const rsiValue = 100 - (100 / (1 + rs));

        rsiD.push({
            time: data[i].time,
            value: parseFloat(rsiValue.toFixed(2)) // RSI는 소수점 2자리까지 표시가 가독성이 좋음
        });
    }

    /* ----------------------------------------------------
       최종 반영: 지표 활성화 상태에 따른 렌더링
       ---------------------------------------------------- */
    if (indState.rsi && rsiD.length > 0) {
        rsiSeries.setData(rsiD);
        // 과매수(70) / 과매도(30) 기준선도 데이터 길이에 맞춰 쫙 그려줍니다.
        rsiOverbought.setData(rsiD.map(d => ({ time: d.time, value: 70 })));
        rsiOversold.setData(rsiD.map(d => ({ time: d.time, value: 30 })));
    } else {
        rsiSeries.setData([]);
        rsiOverbought.setData([]);
        rsiOversold.setData([]);
    }

    /* 메인 차트와 RSI 차트의 시간축(TimeScale) 동기화
       - 메인 차트를 움직이면 RSI 차트도 같이 움직이게 합니다. */
    setTimeout(() => {
        const lr = chart.timeScale().getVisibleLogicalRange();
        if (lr) {
            try { rsiChart.timeScale().setVisibleLogicalRange(lr); }
            catch (e) { /* 초기 로딩 시 에러 방지 */ }
        }
    }, 50);
}

/* ====================================================
   [주식 버전] 캔들 데이터 로드 (서버 API 호출)
   - 한국투자증권 일봉 데이터를 가져와 차트에 표시
   ==================================================== */
async function loadData() {
    // 1. URL 파라미터에서 종목코드(code) 추출 (없으면 삼성전자 005930)
    const urlParams = new URLSearchParams(window.location.search);
    currentStockCode = urlParams.get('code') || '005930';

    try {
        // 2. 태준님의 서버 API 호출 (DailyChart 전용 컨트롤러)
        // 예: @GetMapping("/api/stock/chart/daily")
        const response = await fetch(`/api/stock/chart/daily?code=${currentStockCode}`);
        const res = await response.json();

        if (!res || !res.output2 || res.output2.length === 0) {
            console.error("주식 데이터를 가져오지 못했습니다.");
            return;
        }

        /* 3. 데이터 파싱
           - 한국투자증권 필드명을 차트 필드명(time, open, high, low, close, volume)으로 매핑
           - stck_bsop_date: "20260514" 형태를 parseStockDate 함수로 변환 */
        allData = res.output2.map(item => ({
            time: parseStockDate(item.stck_bsop_date),
            open: parseFloat(item.stck_oprc),
            high: parseFloat(item.stck_hgpr),
            low: parseFloat(item.stck_lwpr),
            close: parseFloat(item.stck_clpr),
            volume: parseFloat(item.acml_vol)
        })).sort((a, b) => a.time - b.time); // 날짜 오름차순 정렬

        // 4. 차트에 데이터 반영 및 지표 계산 실행
        updateAllSeries(allData);

        // 5. 상단 헤더 현재가 및 등락률 초기 설정
        const lastBar = allData[allData.length - 1];
        lastPrice = lastBar.close;
        updatePriceHeader(lastPrice);

    } catch (e) {
        console.error("데이터 로딩 중 에러 발생:", e);
    }
}

/* ====================================================
   [주식 버전] 캔들 데이터 로드 (서버 API 호출)
   - 한국투자증권 데이터를 태준님의 서버를 통해 로드
   ==================================================== */
async function loadData() {
    // 1. URL 파라미터에서 종목코드 추출 (없으면 삼성전자 005930)
    const urlParams = new URLSearchParams(window.location.search);
    currentStockCode = urlParams.get('code') || '005930';

    try {
        // 2. 태준님의 스프링 컨트롤러 API 호출
        // 예: @GetMapping("/api/stock/chart/daily")
        const response = await fetch(`/api/stock/chart/daily?code=${currentStockCode}`);
        const res = await response.json();

        // 한국투자증권 응답 성공 코드는 보통 '0' 또는 데이터 존재 여부로 판단
        if (!res || !res.output2 || res.output2.length === 0) {
            console.error("데이터 로드 실패");
            return;
        }

        /* 3. 데이터 파싱 및 정렬
           - 주식 API는 [배열]이 아닌 {객체} 형태로 오기 때문에 필드명을 명시해야 합니다.
           - stck_bsop_date: "20260514" -> Unix Seconds 변환 */
        allData = res.output2.map(item => ({
            time: parseStockDate(item.stck_bsop_date),
            open: parseFloat(item.stck_oprc),
            high: parseFloat(item.stck_hgpr),
            low: parseFloat(item.stck_lwpr),
            close: parseFloat(item.stck_clpr),
            volume: parseFloat(item.acml_vol)
        })).sort((a, b) => a.time - b.time);

        // 4. 차트 반영 및 지표 계산
        updateAllSeries(allData);
        
        // 5. 현재가 상태 업데이트
        if (allData.length > 0) {
            lastPrice = allData[allData.length - 1].close;
            updatePriceHeader(lastPrice);
        }

    } catch (e) {
        console.error("주식 데이터 로딩 에러:", e);
    }
}

/* ====================================================
   [주식 버전] 과거 데이터 추가 로드 (무한 스크롤)
   - 가장 오래된 데이터의 날짜 이전 데이터를 서버에 요청
   ==================================================== */
let loadMoreTimer = null;

function loadMoreData() {
    if (isLoadingMore || allData.length === 0) return;

    /* 200ms 디바운스 처리 */
    clearTimeout(loadMoreTimer);
    loadMoreTimer = setTimeout(async () => {
        isLoadingMore = true;
        try {
            // 1. 현재 차트에 표시된 가장 오래된 데이터의 시간
            const oldestTime = allData[0].time;
            
            // 2. 서버에 보낼 종료 날짜 형식 변환 (Unix Seconds -> "YYYYMMDD")
            const date = new Date(oldestTime * 1000);
            date.setDate(date.getDate() - 1); // 가장 오래된 날의 하루 전부터 가져옴
            const endDateStr = date.toISOString().split('T')[0].replace(/-/g, '');

            // 3. 태준님의 서버 API 호출 (종료일 파라미터 추가)
            const response = await fetch(
                `/api/stock/chart/daily?code=${currentStockCode}&endDate=${endDateStr}`
            );
            const res = await response.json();

            if (res && res.output2 && res.output2.length > 0) {
                // 4. 주식 데이터 규격에 맞게 파싱
                const older = res.output2.map(item => ({
                    time: parseStockDate(item.stck_bsop_date),
                    open: parseFloat(item.stck_oprc),
                    high: parseFloat(item.stck_hgpr),
                    low: parseFloat(item.stck_lwpr),
                    close: parseFloat(item.stck_clpr),
                    volume: parseFloat(item.acml_vol)
                }))
                // 중복 방지 및 유효성 검사 (현재 가장 오래된 봉보다 이전인 데이터만)
                .filter(d => d.time < oldestTime)
                .sort((a, b) => a.time - b.time);

                if (older.length > 0) {
                    // 5. 차트 가시 범위 유지 로직
                    const lr = chart.timeScale().getVisibleLogicalRange();
                    
                    // 기존 데이터 앞에 추가
                    allData = [...older, ...allData];
                    updateAllSeries(allData);

                    /* 데이터가 앞에 추가되어도 현재 보고 있는 위치가 튀지 않게 보정 */
                    if (lr) {
                        chart.timeScale().setVisibleLogicalRange({
                            from: lr.from + older.length,
                            to: lr.to + older.length
                        });
                    }
                }
            }
        } catch (e) {
            console.error("과거 데이터 로드 중 오류:", e);
        }
        isLoadingMore = false;
    }, 200);
}

/* ====================================================
   [주식 버전] 타임프레임 전환
   - 일/주/월/분봉 버튼 클릭 시 데이터 재로드
   - 주식은 WebSocket 대신 REST API 폴링을 제어함
   ==================================================== */
function changeTimeframe(gran) {
    /* 1. UI 처리: 모든 버튼에서 active 제거 후 현재 버튼에 추가 */
    document.querySelectorAll('.tf-btn[data-tf]').forEach(b => b.classList.remove('active'));
    if (event) {
        event.target.classList.add('active');
    }

    /* 2. 현재 가시 범위 기억 (전환 후에도 비슷한 위치를 보여주기 위함) */
    const lr = chart.timeScale().getVisibleLogicalRange();
    const totalBars = window.currentDataLength || 200;
    const rightOffset = lr ? lr.to - totalBars : 10;
    const barCount = lr ? lr.to - lr.from : 50;

    /* 3. 주식용 TF_MAP 설정 적용 */
    const tf = TF_MAP[gran];
    if (!tf) return;

    currentTimeFrame = tf.period;   // 'D', 'W', 'M' 등
    currentTfSeconds = tf.seconds;  // 초 단위 (카운트다운용)
    // tf.type ('daily' 또는 'minute')에 따라 API 분기 처리가 가능하도록 저장

    /* 4. 카운트다운 플러그인 업데이트 (주식 장 마감 시간에 맞춰 설정) */
    if (countdownPrimitive) {
        countdownPrimitive.applyOptions({
            timeframeInSeconds: currentTfSeconds,
            // 주식은 3:30 장마감 기준이므로 포맷터는 코인 버전 유지 가능
        });
    }

    // 데이터 초기화
    allData = [];

    /* 5. 주식은 WebSocket 대신 데이터 로드 후 실시간 폴링(setInterval)을 다시 세팅 */
    loadData().then(() => {
        const nb = window.currentDataLength || 200;
        // 기억해둔 범위로 다시 포커싱
        chart.timeScale().setVisibleLogicalRange({ 
            from: nb + rightOffset - barCount, 
            to: nb + rightOffset 
        });
        
        // 실시간 현재가 업데이트 함수 실행 (이미 돌고 있다면 중복 방지 처리 필요)
        startRealTimeUpdate(); 
    });
}

/* ====================================================
   [주식 버전] 설정 메뉴 토글 / 로그 스케일
   - UI 상호작용 로직은 팀원 버전과 동일하게 유지하여 디자인 통일
   ==================================================== */

/* 1. 설정 메뉴 열기/닫기
   - 톱니바퀴 아이콘 클릭 시 드롭다운 메뉴 표시
   - event.stopPropagation: 메뉴 내부 클릭 시 닫히는 현상 방지 */
function toggleSettingsMenu() {
    if (event) event.stopPropagation();
    const menu = document.getElementById('settings-menu');
    if (menu) menu.classList.toggle('open');
}

/* 2. 메뉴 외부 클릭 시 닫기
   - 사용자 편의를 위한 전역 클릭 이벤트 감지 */
document.addEventListener('click', e => {
    const menu = document.getElementById('settings-menu');
    if (menu && !e.target.closest('.settings-wrap')) {
        menu.classList.remove('open');
    }
});

/* 3. 로그 스케일 토글
   - mode 0: 가격 절대 수치 기준 (Normal)
   - mode 1: 가격 등락 비율 기준 (Logarithmic)
   - 급등주나 장기 추세를 분석할 때 주식 투자자들이 자주 사용합니다. */
function toggleLog() {
    isLog = !isLog;
    chart.priceScale('right').applyOptions({ 
        mode: isLog ? 1 : 0 
    });
    
    // 버튼 스타일 피드백 (필요 시 추가)
    const logBtn = document.getElementById('btn-log-scale');
    if (logBtn) {
        logBtn.classList.toggle('active', isLog);
    }
}

/* ====================================================
   [주식 버전] 최고/최저가 마커 (hl-high, hl-low)
   - 현재 화면 내 최고가/최저가 지점에 라벨 표시
   ==================================================== */
function updateHighLow() {
    if (!showHighLow) return;

    const lr = chart.timeScale().getVisibleLogicalRange();
    if (!lr || allData.length === 0) return;

    /* 1. 현재 화면에 보이는 데이터 범위 계산 */
    const from = Math.max(0, Math.floor(lr.from));
    const to = Math.min(allData.length - 1, Math.ceil(lr.to));
    const visible = allData.slice(from, to + 1);
    if (!visible.length) return;

    /* 2. 보이는 범위에서 최고가(hV)·최저가(lV) 및 해당 캔들(hC, lC) 찾기 */
    let hV = -Infinity, lV = Infinity, hC, lC;
    visible.forEach(d => {
        if (d.high > hV) { hV = d.high; hC = d; }
        if (d.low < lV) { lV = d.low; lC = d; }
    });

    /* 3. 차트 좌표 계산 (시간 → X픽셀, 가격 → Y픽셀) */
    const hX = chart.timeScale().timeToCoordinate(hC.time);
    const hY = candleSeries.priceToCoordinate(hV);
    const lX = chart.timeScale().timeToCoordinate(lC.time);
    const lY = candleSeries.priceToCoordinate(lV);

    const hEl = document.getElementById('hl-high');
    const lEl = document.getElementById('hl-low');

    /* 4. 등락률 계산 (전일 마감가 기준) */
    const hPct = prevClose > 0 ? ((hV - prevClose) / prevClose * 100) : 0;
    const lPct = prevClose > 0 ? ((lV - prevClose) / prevClose * 100) : 0;

    /* 5. 엘리먼트 위치 및 텍스트 업데이트 */
    if (hX != null && hY != null && hEl) {
        hEl.style.display = 'flex';
        hEl.style.left = hX + 'px';
        hEl.style.top = (hY - 48) + 'px'; // 봉 위쪽 여백
        const valEl = document.getElementById('hl-high-val');
        if (valEl) {
            valEl.textContent = `${Math.floor(hV).toLocaleString()}원 (${hPct >= 0 ? '+' : ''}${hPct.toFixed(2)}%)`;
        }
    }
    
    if (lX != null && lY != null && lEl) {
        lEl.style.display = 'flex';
        lEl.style.left = lX + 'px';
        lEl.style.top = (lY + 10) + 'px'; // 봉 아래쪽 여백
        const valEl = document.getElementById('hl-low-val');
        if (valEl) {
            valEl.textContent = `${Math.floor(lV).toLocaleString()}원 (${lPct >= 0 ? '+' : ''}${lPct.toFixed(2)}%)`;
        }
    }
}

/* 마커 표시 여부 토글 함수 */
function toggleHighLow(enabled) {
    showHighLow = enabled;
    const hEl = document.getElementById('hl-high');
    const lEl = document.getElementById('hl-low');
    if (hEl) hEl.style.display = enabled ? 'flex' : 'none';
    if (lEl) lEl.style.display = enabled ? 'flex' : 'none';
    if (enabled) updateHighLow();
}

/* ====================================================
   [주식 버전] 봉 카운트다운 (다음 봉 생성까지 남은 시간)
   - lwc-plugin-countdown-to-close 라이브러리 연동
   - 분봉 단타 매매 시 다음 봉 예측을 돕는 기능
   ==================================================== */
function startCountdown() {
    // 주식 차트가 일봉(D) 이상일 때는 사실상 카운트다운이 큰 의미가 없으므로 
    // 주로 분봉 모드에서 활성화되도록 유도하는 것이 좋습니다.
    
    if (!countdownPrimitive) {
        countdownPrimitive = new CountdownToClose.CountdownToClose({
            customLastPriceLine: true, // 라이브러리가 그리는 커스텀 가격선 사용
            timeframeInSeconds: currentTfSeconds,
            timeLabelFormatter: (ttcc) => {
                // 총 남은 초 계산
                const t = ttcc.days * 86400 + ttcc.hours * 3600 + ttcc.minutes * 60 + ttcc.seconds;
                const h = Math.floor(t / 3600);
                const m = Math.floor((t % 3600) / 60);
                const s = t % 60;

                // 1. 일봉(86400초) 이상이거나 시간이 1시간 이상 남은 경우 (HH:MM:SS)
                if (currentTfSeconds >= 3600 || h > 0) {
                    return String(h).padStart(2, '0') + ':' + 
                           String(m).padStart(2, '0') + ':' + 
                           String(s).padStart(2, '0');
                }
                // 2. 그 외 분봉 모드 (MM:SS)
                return String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
            }
        });

        /* 플러그인이 현재가 선을 직접 그리므로, 중복 방지를 위해 기본 시리즈 선은 숨깁니다. */
        candleSeries.applyOptions({ 
            lastValueVisible: false, 
            priceLineVisible: false 
        });
        
        candleSeries.attachPrimitive(countdownPrimitive);
    }
}

/* 카운트다운 표시 여부 토글 */
function toggleCountdown(enabled) {
    showCountdown = enabled;
    if (enabled) {
        startCountdown();
        if (countdownPrimitive) countdownPrimitive.applyOptions({ showLabels: true });
    } else {
        if (countdownPrimitive) countdownPrimitive.applyOptions({ showLabels: false });
        // 다시 기본 현재가 라벨과 선을 복구시킵니다.
        candleSeries.applyOptions({ 
            lastValueVisible: true, 
            priceLineVisible: true 
        });
    }
}

/* ====================================================
   [주식 버전] 지표 토글
   - 버튼 클릭 시 해당 시리즈의 visible 옵션을 제어
   - RSI 토글 시 차트 레이아웃 리사이즈 대응
   ==================================================== */
function toggleInd(name) {
    // 1. 상태 반전 및 버튼 UI 업데이트
    indState[name] = !indState[name];
    const on = indState[name];
    setIndBtnStyle(name, on);

    // 2. 개별 지표 시리즈 가시성 제어
    if (name === 'ma5') ma5Series.applyOptions({ visible: on });
    else if (name === 'ma20') ma20Series.applyOptions({ visible: on });
    else if (name === 'ma60') ma60Series.applyOptions({ visible: on });
    else if (name === 'bb') {
        [bbUpperSeries, bbMiddleSeries, bbLowerSeries].forEach(s => s.applyOptions({ visible: on }));
    }
    else if (name === 'ichimoku') {
        [ichiTenkanSeries, ichiKijunSeries, ichiSpanASeries, ichiSpanBSeries, ichiChikouSeries]
            .forEach(s => s.applyOptions({ visible: on }));
    }
    else if (name === 'rsi') {
        /* RSI 컨테이너 및 구분선(Divider) 제어 */
        const rsiCont = document.getElementById('rsi-container');
        const divider = document.getElementById('pane-divider');
        
        if (rsiCont) rsiCont.style.display = on ? 'block' : 'none';
        if (divider) divider.style.display = on ? 'block' : 'none';

        if (on) {
            /* RSI가 켜질 때: 메인 차트와 RSI 차트의 크기를 다시 계산(Resize) */
            setTimeout(() => {
                chart.resize(container.clientWidth, container.clientHeight);
                rsiChart.resize(rsiContainer.clientWidth, rsiContainer.clientHeight);
                
                // 시간축 동기화
                const lr = chart.timeScale().getVisibleLogicalRange();
                if (lr) { 
                    try { rsiChart.timeScale().setVisibleLogicalRange(lr); } 
                    catch (e) { } 
                }
            }, 50);
        }
    }
}

/* ====================================================
   [주식 버전] 실시간 데이터 업데이트 (REST Polling 방식)
   - 웹소켓 대신 3초마다 현재가 및 호가를 서버에서 가져옴
   ==================================================== */
let pollingTimer = null;

function startRealTimeUpdate() {
    if (pollingTimer) clearInterval(pollingTimer);

    // 3초 주기로 현재가 및 호가 갱신
    pollingTimer = setInterval(async () => {
        try {
            const response = await fetch(`/api/stock/realtime?code=${currentStockCode}`);
            const data = await response.json();

            if (!data) return;

            /* 1. 캔들(현재가) 업데이트 */
            const bar = {
                time: window.lastCandleTime, // 현재 봉에 덮어쓰기
                open: parseFloat(data.open),
                high: parseFloat(data.high),
                low: parseFloat(data.low),
                close: parseFloat(data.close)
            };
            
            candleSeries.update(bar);
            lastPrice = bar.close;
            updatePriceHeader(bar.close);

            /* 2. 호가창 업데이트 */
            if (data.hoga) {
                updateHoga(data.hoga);
            }
            
            // 보유 주식 수익률 실시간 계산
            updateHoldingsPnl();

        } catch (e) {
            console.error("실시간 업데이트 오류:", e);
        }
    }, 3000);
}

/* [주식 버전] 호가창 렌더링
   - 매도호가(Asks): 파란색, 매수호가(Bids): 빨간색
   - 주식 호가 잔량 비율 계산 및 가로 바 차트 효과 적용 */
function updateHoga(hogaData) {
    const askBody = document.getElementById('hoga-asks');
    const bidBody = document.getElementById('hoga-bids');
    if (!askBody || !bidBody) return;

    // 한국투자증권 응답 구조에 맞게 매도/매수 호가 정렬
    const asks = hogaData.asks; // 보통 가격 높은 순
    const bids = hogaData.bids; // 보통 가격 낮은 순

    let maxVol = Math.max(...asks.map(a => a.vol), ...bids.map(b => b.vol));

    // 매도 호가 (파란색 계열)
    askBody.innerHTML = asks.map(a => {
        const pct = (a.vol / maxVol * 100).toFixed(1);
        return `
            <tr style="background:linear-gradient(to left, rgba(37,99,235,0.08) ${pct}%, transparent ${pct}%)">
                <td class="hoga-ask">${parseInt(a.price).toLocaleString()}</td>
                <td>${parseInt(a.vol).toLocaleString()}</td>
            </tr>`;
    }).join('');

    // 매수 호가 (빨간색 계열)
    bidBody.innerHTML = bids.map(b => {
        const pct = (b.vol / maxVol * 100).toFixed(1);
        return `
            <tr style="background:linear-gradient(to left, rgba(240,68,82,0.08) ${pct}%, transparent ${pct}%)">
                <td class="hoga-bid">${parseInt(b.price).toLocaleString()}</td>
                <td>${parseInt(b.vol).toLocaleString()}</td>
            </tr>`;
    }).join('');
}

/* ====================================================
   [주식 버전] UI 업데이트 함수들
   - 주식 가격 특성(정수, 원 단위)에 맞춰 포맷팅 변경
   ==================================================== */

/* 1. 시/고/저/종(OHLC) 바 업데이트 
   - 캔들에 마우스를 올렸을 때 상단에 표시되는 수치 */
function updateOhlc(o, h, l, c) {
    document.getElementById('val-o').textContent = Math.floor(o).toLocaleString();
    document.getElementById('val-h').textContent = Math.floor(h).toLocaleString();
    document.getElementById('val-l').textContent = Math.floor(l).toLocaleString();
    document.getElementById('val-c').textContent = Math.floor(c).toLocaleString();
}

/* 2. 상단 현재가 헤더 업데이트
   - 큰 글씨로 나오는 현재가와 호가창 중앙 가격 동기화 */
function updatePriceHeader(price) {
    const formattedPrice = Math.floor(price).toLocaleString();
    
    // 메인 가격 헤더
    const phPrice = document.getElementById('ph-price');
    if (phPrice) phPrice.textContent = formattedPrice;

    // 주문창 가격 입력칸 placeholder
    const inp = document.getElementById('trade-price-input');
    if (inp) inp.placeholder = Math.floor(price);

    // 호가창 중앙 현재가 표시
    const hm = document.getElementById('hoga-cur-price');
    if (hm) hm.textContent = formattedPrice;
}

/* 3. 보유 종목 손익 실시간 업데이트
   - USDT 단위를 '원'으로 변경하고, 한국식 등락 색상 적용 */
function updateHoldingsPnl() {
    const pEl = document.getElementById('holding-price');
    const pnlEl = document.getElementById('holding-pnl');
    if (!pEl || !pnlEl || !lastPrice) return;

    // 테이블 구조에서 평단가와 수량 추출 (태준님의 HTML 구조에 맞게 조정 필요)
    const avg = parseFloat(pEl.dataset.avgPrice) || 0; // 데이터 속성 활용 권장
    const cnt = parseFloat(pEl.dataset.quantity) || 0;
    
    const pnl = (lastPrice - avg) * cnt; // 실시간 손익 금액
    const pnlRate = avg > 0 ? ((lastPrice - avg) / avg * 100).toFixed(2) : "0.00";

    // 현재가 및 수익금 업데이트
    pEl.textContent = Math.floor(lastPrice).toLocaleString();
    pnlEl.textContent = `${pnl >= 0 ? '+' : ''}${Math.floor(pnl).toLocaleString()}원 (${pnlRate}%)`;
    
    // 수익률에 따른 색상 변경 (토스 레드 / 토스 블루)
    pnlEl.style.color = pnl >= 0 ? '#F04452' : '#2563EB';
}

/* ====================================================
   [주식 버전] 티커 로드 (현재가 및 변동 정보)
   - 전일 대비 등락액, 등락률, 고가, 저가, 거래량 정보 업데이트
   ==================================================== */
async function loadTicker() {
    try {
        // 태준님의 서버 API 호출 (현재가 요약 정보)
        const response = await fetch(`/api/stock/ticker?code=${currentStockCode}`);
        const res = await response.json();

        // 한국투자증권 주식현재가 시세 응답(output) 기준
        if (res && res.output) {
            const d = res.output;
            const price = parseFloat(d.stck_prpr);       // 현재가
            const prdyVrss = parseFloat(d.prdy_vrss);    // 전일 대비 등락액
            const prdyCtrt = parseFloat(d.prdy_ctrt);    // 전일 대비 등락률

            lastPrice = price;
            // 전일 종가 계산 (현재가 - 전일대비액)
            prevClose = price - prdyVrss;

            // 1. 메인 가격 헤더 업데이트
            updatePriceHeader(price);

            // 2. 전일대비 절대금액 (예: +1,500원)
            const absEl = document.getElementById('ph-change-abs');
            if (absEl) {
                absEl.textContent = `${prdyVrss >= 0 ? '▲' : '▼'} ${Math.abs(prdyVrss).toLocaleString()}원`;
                absEl.className = 'ph-change ' + (prdyVrss >= 0 ? 'up' : 'down');
            }

            // 3. 전일대비 퍼센트 (예: +2.45%)
            const cEl = document.getElementById('ph-change');
            if (cEl) {
                cEl.textContent = `(${prdyCtrt >= 0 ? '+' : ''}${prdyCtrt.toFixed(2)}%)`;
                cEl.className = 'ph-change ' + (prdyCtrt >= 0 ? 'up' : 'down');
            }

            // 4. 고가 / 저가 / 거래량 (주식 단위에 맞춰 포맷팅)
            const highEl = document.getElementById('ph-high');
            if (highEl) highEl.textContent = Math.floor(d.stck_hgpr).toLocaleString();

            const lowEl = document.getElementById('ph-low');
            if (lowEl) lowEl.textContent = Math.floor(d.stck_lwpr).toLocaleString();

            const volEl = document.getElementById('ph-vol');
            if (volEl) {
                // 거래량은 보통 '주' 단위로 표시
                volEl.textContent = parseInt(d.acml_vol).toLocaleString() + ' 주';
            }
        }
    } catch (e) {
        console.error("티커 로드 중 에러 발생:", e);
    }
}

/* ====================================================
   [주식 버전] RSI 패널 세로 리사이즈 (드래그 핸들)
   - pane-divider를 잡고 위아래로 끌어 RSI 차트 높이 조절
   - 드래그 중 실시간으로 차트 레이아웃 리사이즈 대응
   ==================================================== */
let rsiDrag = false, rsiDragY = 0, rsiDragH = 0;

const paneDivider = document.getElementById('pane-divider');
const rsiCont = document.getElementById('rsi-container');
const mainCont = document.getElementById('chart-container');

if (paneDivider && rsiCont) {
    // 1. 드래그 시작 (mousedown)
    paneDivider.addEventListener('mousedown', e => {
        rsiDrag = true;
        rsiDragY = e.clientY;
        rsiDragH = rsiCont.clientHeight;
        
        // 스타일 적용: 마우스 커서 고정 및 텍스트 선택 방지
        document.body.style.cursor = 'row-resize';
        document.body.style.userSelect = 'none';
    });

    // 2. 드래그 중 (mousemove)
    document.addEventListener('mousemove', e => {
        if (!rsiDrag) return;

        // 새로운 높이 계산 (위로 끌면 +양수, 아래로 끌면 -음수)
        const newHeight = Math.max(80, Math.min(400, rsiDragH + (rsiDragY - e.clientY)));
        rsiCont.style.height = newHeight + 'px';

        /* [핵심] 높이가 변할 때마다 캔버스 리사이즈 호출
           - 이 코드가 없으면 RSI 차트의 선이 늘어지거나 깨져 보입니다. */
        rsiChart.resize(rsiCont.clientWidth, newHeight);
        
        // 메인 차트도 영향이 있을 수 있으므로 함께 리사이즈 (컨테이너 구조에 따라 선택)
        chart.resize(mainCont.clientWidth, mainCont.clientHeight);
    });

    // 3. 드래그 종료 (mouseup)
    document.addEventListener('mouseup', () => {
        if (rsiDrag) {
            rsiDrag = false;
            document.body.style.cursor = '';
            document.body.style.userSelect = '';
            
            // 드래그 종료 후 최종적으로 시간축 동기화 재확인
            const lr = chart.timeScale().getVisibleLogicalRange();
            if (lr) {
                try { rsiChart.timeScale().setVisibleLogicalRange(lr); } catch (e) {}
            }
        }
    });
}

/* ====================================================
   [주식 버전] 패널 리사이즈 (가로/세로 드래그)
   - 패널 크기 변경 시 차트 및 호가창 레이아웃 리사이즈 강제
   ==================================================== */

/**
 * 가로 리사이즈: 패널 너비 조절
 */
function makeHResizer(handleId, rightPanelId, minW = 200, maxW = 600) {
    const h = document.getElementById(handleId);
    const rp = document.getElementById(rightPanelId);
    if (!h || !rp) return;

    let drag = false, startX = 0, startW = 0;

    h.addEventListener('mousedown', e => {
        drag = true; 
        startX = e.clientX; 
        startW = rp.getBoundingClientRect().width;
        h.classList.add('dragging');
        document.body.style.cursor = 'col-resize';
        document.body.style.userSelect = 'none';
    });

    document.addEventListener('mousemove', e => {
        if (!drag) return;
        const w = Math.max(minW, Math.min(maxW, startW + (startX - e.clientX))) + 'px';
        rp.style.width = w;
        rp.style.flexBasis = w;

        /* [주식 차트 필수] 가로 너비가 변하면 메인 차트 리사이즈 */
        const mainContainer = document.getElementById('chart-container');
        if (mainContainer && typeof chart !== 'undefined') {
            chart.resize(mainContainer.clientWidth, mainContainer.clientHeight);
            if (indState.rsi && typeof rsiChart !== 'undefined') {
                const rsiContainer = document.getElementById('rsi-container');
                rsiChart.resize(rsiContainer.clientWidth, rsiContainer.clientHeight);
            }
        }
    });

    document.addEventListener('mouseup', () => {
        if (!drag) return;
        drag = false;
        h.classList.remove('dragging');
        document.body.style.cursor = '';
        document.body.style.userSelect = '';
    });
}

/**
 * 세로 리사이즈: 위/아래 패널 높이 조절 (주문창 vs 호가창)
 */
function makeVResizer(handleId, topId, botId) {
    const h = document.getElementById(handleId);
    const tp = document.getElementById(topId);
    const bp = document.getElementById(botId);
    if (!h || !tp || !bp) return;

    let drag = false, startY = 0, startTH = 0, startBH = 0;

    h.addEventListener('mousedown', e => {
        drag = true; 
        startY = e.clientY;
        startTH = tp.getBoundingClientRect().height;
        startBH = bp.getBoundingClientRect().height;
        h.classList.add('dragging');
        document.body.style.cursor = 'row-resize';
        document.body.style.userSelect = 'none';
    });

    document.addEventListener('mousemove', e => {
        if (!drag) return;
        const d = e.clientY - startY;
        
        // Flex 설정을 해제하고 고정 높이로 변환
        tp.style.flex = 'none';
        
        const nextTH = Math.max(150, startTH + d);
        const nextBH = Math.max(80, startBH - d);
        
        tp.style.height = nextTH + 'px';
        bp.style.height = nextBH + 'px';

        /* [주식 호가창 필수] 높이가 변하면 호가창에 표시할 행 개수 재계산 */
        if (typeof updateHoga === 'function' && window.lastHogaData) {
            updateHoga(window.lastHogaData);
        }
    });

    document.addEventListener('mouseup', () => {
        if (!drag) return;
        drag = false;
        h.classList.remove('dragging');
        document.body.style.cursor = '';
        document.body.style.userSelect = '';
    });
}

/* ====================================================
   레이아웃 초기화 호출
   ==================================================== */
// 1. 주문/호가 패널: 340px 고정 (필요 시 범위를 300~450으로 넓히는 것 추천)
makeHResizer('rh-1', 'panel-middle', 330, 450); 

// 2. 댓글/커뮤니티 패널: 270~380px
makeHResizer('rh-2', 'panel-chat', 270, 380); 

// 3. 우측 내부 세로 리사이즈 (주문창/호가창 비율)
makeVResizer('rh-v', 'panel-order-wrap', 'panel-hoga');

/* ====================================================
   [주식 버전] 주문 관련 함수
   - 통화 단위: USDT -> 원
   - 수량 단위: BTC -> 주 (Integer)
   - 서버 경로: /coin/buy -> /stock/buy (예시)
   ==================================================== */

/* 1. 매수/매도 탭 전환 */
function switchOrderTab(side) {
    orderSide = side;
    const isBuy = side === 'buy';
    
    // UI 활성화 상태 변경
    document.getElementById('tab-buy').classList.toggle('active', isBuy);
    document.getElementById('tab-sell').classList.toggle('active', !isBuy);
    
    const btn = document.getElementById('order-submit-btn');
    if (btn) {
        btn.textContent = isBuy ? '매수 주문' : '매도 주문';
        btn.className = isBuy ? 'btn-buy' : 'btn-sell';
    }

    const avLabel = document.querySelector('.order-avail-label'); // "주문가능" 라벨
    const avVal = document.querySelector('.order-avail span');     // 실제 수치
    
    if (isBuy) {
        if (avLabel) avLabel.textContent = '주문가능 금액';
        // walletBalance는 서버에서 받아온 현금 잔고 (원)
        avVal.textContent = Math.floor(walletBalance).toLocaleString() + ' 원';
    } else {
        if (avLabel) avLabel.textContent = '매도가능 수량';
        /* 매도 시: 보유 종목 리스트에서 해당 종목 수량 추출 */
        const holdingQty = parseInt(document.getElementById('holding-qty')?.textContent) || 0;
        avVal.textContent = holdingQty.toLocaleString() + ' 주';
    }
    calcAmount();
}

/* 2. 잔고 비율로 수량 자동 계산 (25%, 50%, 100% 버튼) */
function togglePctDrop() {
    const menu = document.getElementById('pct-drop-menu');
    menu.style.display = menu.style.display === 'none' ? 'block' : 'none';
}

function setPercent(pct) {
    const label = document.getElementById('pct-drop-label');
    if (label) label.textContent = pct === 100 ? '최대' : pct + '%';
    const menu = document.getElementById('pct-drop-menu');
    if (menu) menu.style.display = 'none';

    const qtyInput = document.getElementById('trade-qty');
    if (orderSide === 'sell') {
        const holdingQty = parseInt(document.getElementById('holding-qty')?.textContent) || 0;
        qtyInput.value = Math.floor(holdingQty * pct / 100);
    } else {
        if (lastPrice > 0) {
            qtyInput.value = Math.floor((walletBalance * pct / 100) / lastPrice);
        }
    }
    calcAmount();
}

/* 3. 수량 × 현재가 = 예상 주문금액 계산 */
function calcAmount() {
    const qty = parseInt(document.getElementById('trade-qty').value) || 0;
    const el = document.getElementById('trade-amount');
    if (el) el.textContent = Math.floor(qty * lastPrice).toLocaleString();
}

/* 4. 주문 제출 - 태준님의 스프링 부트 서버 REST API 호출 */
function submitOrder() {
    const qty = document.getElementById('trade-qty').value;
    if (!qty || qty <= 0) { 
        alert('주문 수량을 입력하세요.'); 
        return; 
    }

    // 전송할 데이터 구성 (코인 경로가 아닌 주식 경로로 변경)
    const url = orderSide === 'buy' ? '/stock/buy' : '/stock/sell';
    
    fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
            stockCode: currentStockCode, // '005930' 등
            orderPrice: lastPrice,       // 현재가로 주문 (시장가 컨셉)
            orderCount: qty,             // 주식 수
            username: 'taejun'           // 세션 정보가 있다면 생략 가능
        })
    })
    .then(r => r.text())
    .then(result => {
        if (result === 'success') {
            alert(`${orderSide === 'buy' ? '매수' : '매도'} 주문이 정상적으로 접수되었습니다.`);
            // 잔고 및 보유 현황 새로고침
            if (typeof loadWallet === 'function') loadWallet();
            if (typeof loadHoldings === 'function') loadHoldings();
        } else {
            alert('주문 실패: ' + result);
        }
    })
    .catch(err => alert('서버 통신 오류: ' + err));
}

/* ====================================================
   [주식 버전] 지갑 / 보유 내역 로드
   - 통화: USDT -> 원 (KRW)
   - 수량: 소수점 6자리 -> 정수 (주)
   - 서버 경로: /coin/wallet -> /stock/wallet (예시)
   ==================================================== */

/* 1. 서버에서 예수금(현금 잔고) 가져오기 */
async function loadWallet() {
    try {
        // 태준님의 서버 엔드포인트에 맞춰 수정 (예: /api/account/balance)
        const res = await fetch('/stock/wallet?username=taejun').then(r => r.json());
        
        if (res && res.balance !== undefined) {
            walletBalance = res.balance;
            
            // UI 업데이트: "주문가능 금액" 영역
            const availSpan = document.querySelector('.order-avail span');
            if (availSpan) {
                availSpan.textContent = Math.floor(res.balance).toLocaleString() + ' 원';
            }
        }
    } catch (e) {
        console.error("지갑 정보 로드 실패:", e);
    }
}

/* 2. 서버에서 보유 주식 목록 가져와 테이블에 렌더링 */
async function loadHoldings() {
    try {
        const res = await fetch('/stock/holdings?username=taejun').then(r => r.json());
        const tbody = document.getElementById('bp-holdings-body');
        const emptyDiv = document.getElementById('bp-empty');
        const table = document.getElementById('bp-holdings-table');
        
        if (!tbody) return;
        tbody.innerHTML = '';

        if (res && res.length > 0) {
            if (emptyDiv) emptyDiv.style.display = 'none';
            if (table) table.style.display = 'table';
            
            let rows = '';
            res.forEach(h => {
                // 수익금 계산: (현재가 - 평단가) * 보유수량
                const pnl = (lastPrice - h.avgPrice) * h.stockCount;
                // 수익률 계산
                const pnlRate = h.avgPrice > 0 ? ((lastPrice - h.avgPrice) / h.avgPrice * 100).toFixed(2) : "0.00";
                
                // 한국 주식 스타일 색상 (상승 빨강, 하락 파랑)
                const pnlColor = pnl >= 0 ? '#F04452' : '#2563EB';
                const pnlSign = pnl >= 0 ? '+' : '';

                rows += `
                    <tr>
                        <td><strong>${h.stockName || h.stockCode}</strong></td>
                        <td id="holding-qty">${parseInt(h.stockCount).toLocaleString()}</td>
                        <td>${Math.floor(h.avgPrice).toLocaleString()}</td>
                        <td id="holding-price">${Math.floor(lastPrice).toLocaleString()}</td>
                        <td id="holding-pnl" style="color: ${pnlColor}; font-weight: bold;">
                            ${pnlSign}${Math.floor(pnl).toLocaleString()}원<br/>
                            <span style="font-size: 0.85em;">(${pnlSign}${pnlRate}%)</span>
                        </td>
                    </tr>
                `;
            });
            tbody.innerHTML = rows;
        } else {
            if (emptyDiv) emptyDiv.style.display = 'block';
            if (table) table.style.display = 'none';
        }
    } catch (e) {
        console.error("보유 내역 로드 실패:", e);
    }
}

/* ====================================================
   [주식 버전] 실시간 댓글 (토론방 UI 스타일)
   - XSS 방지 및 시간 표시 추가
   - 추후 서버 연동을 고려한 구조
   ==================================================== */

function sendChat() {
    const inp = document.getElementById('chat-input');
    const text = inp.value.trim();
    if (!text) return;

    const msgs = document.getElementById('chat-messages');
    
    // 1. 처음 메시지 작성 시 "댓글이 없습니다" 안내 문구 제거
    const empty = msgs.querySelector('.chat-empty');
    if (empty) empty.remove();

    // 2. 현재 시간 생성 (HH:mm 형식)
    const now = new Date();
    const timeStr = now.getHours().toString().padStart(2, '0') + ':' + 
                    now.getMinutes().toString().padStart(2, '0');

    // 3. 메시지 엘리먼트 생성
    const div = document.createElement('div');
    div.className = 'chat-msg';
    
    /* [XSS 방지 및 UI 구성]
       - 닉네임: 태준 (주식 투자자 컨셉)
       - 내용: 특수문자 이스케이프
       - 시간: 우측 하단 작게 표시
    */
    const escapedText = text.replace(/</g, '&lt;').replace(/>/g, '&gt;');
    
    div.innerHTML = `
        <div class="cm-info">
            <span class="cm-name">태준</span>
            <span class="cm-time">${timeStr}</span>
        </div>
        <div class="cm-text">${escapedText}</div>
    `;

    // 4. 메시지 추가 및 자동 스크롤
    msgs.appendChild(div);
    msgs.scrollTop = msgs.scrollHeight;
    
    // 5. 입력창 초기화 및 포커스 유지
    inp.value = '';
    inp.focus();
}

/* 엔터 키 입력 이벤트 리스너 */
const chatInput = document.getElementById('chat-input');
if (chatInput) {
    chatInput.addEventListener('keydown', e => {
        // 한글 입력 시 엔터 중복 이벤트 방지 (isComposing)
        if (e.isComposing) return;
        if (e.key === 'Enter') {
            sendChat();
        }
    });
}

/* ====================================================
   [주식 버전] 초기 실행 (Launcher)
   - 페이지 로드 시 데이터 로드 및 실시간 엔진 가동
   ==================================================== */

async function initChartProject() {
    try {
        // 1. 기본 정보 로드 (비동기 병렬 실행으로 속도 향상)
        await Promise.all([
            loadTicker(), // 상단 현재가/등락률 정보
            loadWallet()  // 예수금(잔액) 정보
        ]);

        // 2. 메인 차트 데이터 로드
        await loadData();

        // 3. 실시간 엔진 및 부가 기능 가동
        startRealTimeUpdate(); // 주식용 REST Polling 시작
        loadHoldings();        // 보유 주식 및 실시간 수익률 계산
        startCountdown();      // 분봉 모드용 카운트다운 가동

        // 4. 기본 지표 활성화 (주식 차트의 정석: 5일/20일 이평선)
        if (typeof toggleInd === 'function') {
            toggleInd('ma5');
            toggleInd('ma20');
        }

        console.log("주식 차트 시스템 엔진 가동 완료 🚀");
    } catch (e) {
        console.error("초기화 중 오류 발생:", e);
    }
}

// 스크립트 로드 즉시 실행
initChartProject();

/* ====================================================
   [반응형 대응] 창 크기 변경 시 인라인 스타일 초기화
   - 드래그로 고정된 px 값이 미디어쿼리(CSS)를 방해하지 않도록 처리
   ==================================================== */
window.addEventListener('resize', () => {
    const mid = document.getElementById('panel-middle');
    const order = document.getElementById('panel-order-wrap');
    const hoga = document.getElementById('panel-hoga');
    const chat = document.getElementById('panel-chat');

    // 화면 너비가 1100px 이하(태블릿/모바일)로 줄어들면
    // 사용자가 드래그해서 고정했던 높이/너비 값을 제거하여 CSS를 따르게 합니다.
    if (window.innerWidth <= 1100) {
        if (mid) { mid.style.width = ''; mid.style.flexBasis = ''; }
        if (order) order.style.height = '';
        if (hoga) hoga.style.height = '';
        if (chat) { chat.style.width = ''; chat.style.flexBasis = ''; }
        
        /* [핵심] 레이아웃 초기화 후 차트 리사이즈 강제 호출 */
        const mainContainer = document.getElementById('chart-container');
        if (mainContainer && typeof chart !== 'undefined') {
            chart.resize(mainContainer.clientWidth, mainContainer.clientHeight);
        }
    }
});

/* ====================================================
   [주식 버전] 하단 티커 바 - 주요 종목 실시간 시세 로드
   - 15초마다 관심 종목 가격 갱신 및 무한 스크롤 애니메이션
   ==================================================== */

// 1. 표시할 주식 종목 코드 (삼성전자, SK하이닉스, 카카오, 현대차, NAVER, LG엔솔 등)
const STOCK_SYMBOLS = [
    { code: '005930', name: '삼성전자' },
    { code: '000660', name: 'SK하이닉스' },
    { code: '035720', name: '카카오' },
    { code: '005380', name: '현대차' },
    { code: '035420', name: 'NAVER' },
    { code: '373220', name: 'LG에너지솔루션' },
    { code: '000270', name: '기아' },
    { code: '068270', name: '셀트리온' }
];

async function loadTickerBar() {
    try {
        // 태준님의 서버 API 호출 (여러 종목의 현재가 요약 정보를 가져오는 엔드포인트)
        const response = await fetch('/api/stock/tickers/summary');
        const res = await response.json();

        if (!res || !res.data) return;

        const track = document.getElementById('ticker-track');
        if (!track) return;

        /* 최초 1회: HTML 구조 생성 (무한 스크롤용 세트 구성) */
        if (!track.children.length) {
            const items = res.data.map(d => {
                const changePct = parseFloat(d.prdy_ctrt); // 전일 대비 등락률
                const cls = changePct >= 0 ? 'up' : 'down';
                const sign = changePct >= 0 ? '+' : '';
                
                return `
                    <div class="ticker-item">
                        <span class="ticker-name">${d.stock_name}</span>
                        <span class="ticker-price">${Math.floor(d.stck_prpr).toLocaleString()}</span>
                        <span class="ticker-change ${cls}">${sign}${changePct.toFixed(2)}%</span>
                    </div>`;
            }).join('');

            // 끊김 없는 무한 스크롤을 위해 4세트 반복 배치
            track.innerHTML = items + items + items + items;
            
            setTimeout(() => {
                tickerHalfWidth = track.scrollWidth / 2;
                tickerTrackEl = track;
            }, 500);
            return;
        }

        /* 이후 갱신: 가격·변동률 텍스트만 교체하여 깜빡임 방지 */
        const allItems = track.querySelectorAll('.ticker-item');
        const groupSize = res.data.length;

        res.data.forEach((d, i) => {
            const changePct = parseFloat(d.prdy_ctrt);
            const cls = changePct >= 0 ? 'up' : 'down';
            const sign = changePct >= 0 ? '+' : '';
            const priceStr = Math.floor(d.stck_prpr).toLocaleString();

            // 모든 반복 세트의 동일 인덱스 아이템들 업데이트
            for (let j = 0; j < 4; j++) {
                const targetIdx = i + (j * groupSize);
                const el = allItems[targetIdx];
                if (!el) continue;

                el.querySelector('.ticker-price').textContent = priceStr;
                const changeEl = el.querySelector('.ticker-change');
                changeEl.textContent = `${sign}${changePct.toFixed(2)}%`;
                changeEl.className = `ticker-change ${cls}`;
            }
        });
    } catch (e) {
        console.error("티커 바 로드 실패:", e);
    }
}

/* JS 기반 부드러운 스크롤 제어 엔진 */
let tickerX = 0;
let tickerPaused = false;
let tickerHalfWidth = 0;
let tickerTrackEl = null;

function animateTicker() {
    if (!tickerPaused && tickerHalfWidth > 0 && tickerTrackEl) {
        tickerX -= 0.8; // 스크롤 속도 조절
        // 절반 지점에 도달하면 자연스럽게 처음으로 리셋 (무한 루프)
        if (Math.abs(tickerX) >= tickerHalfWidth) {
            tickerX = 0;
        }
        tickerTrackEl.style.transform = `translateX(${tickerX}px)`;
    }
    requestAnimationFrame(animateTicker);
}

// 마우스 오버 시 일시 정지 기능
const tickerContainer = document.getElementById('ticker-track');
if (tickerContainer) {
    tickerContainer.addEventListener('mouseenter', () => tickerPaused = true);
    tickerContainer.addEventListener('mouseleave', () => tickerPaused = false);
}

// 실행 및 인터벌 설정 (15초 주기)
animateTicker();
loadTickerBar();
setInterval(loadTickerBar, 15000);

document.addEventListener('click', function(e) {
    if (!e.target.closest('#pct-drop-wrap')) {
        const m = document.getElementById('pct-drop-menu');
        if (m) m.style.display = 'none';
    }
});


