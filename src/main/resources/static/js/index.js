/* =====================================================
   index.js - 코스피 가상/실제 파이프라인 및 비트코인 빗썸 직통 분리 버전
   ===================================================== */

/* 1. 유틸리티 함수: 한국투자증권 날짜 및 분봉 시간 파싱 */
function parseStockDate(dateStr, timeStr) {
    if (!dateStr) return Math.floor(Date.now() / 1000);
    const y = parseInt(dateStr.substring(0, 4));
    const m = parseInt(dateStr.substring(4, 6)) - 1;
    const d = parseInt(dateStr.substring(6, 8));

    if (timeStr && timeStr.length >= 4) {
        const hh = parseInt(timeStr.substring(0, 2));
        const mm = parseInt(timeStr.substring(2, 4));
        return new Date(y, m, d, hh, mm, 0).getTime() / 1000;
    }
    return new Date(y, m, d, 9, 0, 0).getTime() / 1000;
}

/* 2. 미니 차트 생성 함수 */
function createMiniChart(containerId, lineColor) {
    const container = document.getElementById(containerId);
    if (!container) return null;

    const chart = LightweightCharts.createChart(container, {
        width: container.clientWidth,
        height: 180,
        layout: {
            background: { color: 'transparent' },
            textColor: 'rgba(255, 255, 255, 0.4)',
            fontFamily: 'Pretendard, sans-serif',
        },
        grid: {
            vertLines: { visible: false },
            horzLines: { color: 'rgba(255,255,255,0.03)' }
        },
        rightPriceScale: {
            borderVisible: false,
            scaleMargins: { top: 0.2, bottom: 0.1 }
        },
        timeScale: {
            visible: true,
            borderVisible: false,
            timeVisible: true,
            secondsVisible: false
        },
        handleScale: false,
        handleScroll: false,
    });

    const series = chart.addSeries(LightweightCharts.AreaSeries, {
        lineColor: lineColor,
        topColor: lineColor + '33',
        bottomColor: lineColor + '00',
        lineWidth: 2,
        priceLineVisible: false,
        lastValueVisible: false,
    });

    window.addEventListener('resize', () => {
        chart.resize(container.clientWidth, 180);
    });

    return { chart, series };
}

/* 3. 전역 변수 동기화 및 백업용 데이터 생성기 */
let kospiChartObj = null, btcChartObj = null;
let kospiSeries = null, btcSeries = null;

// 💡 [현실 지수 반영] 전역 변수 디폴트 베이스라인을 현실 스펙(7552)으로 리셋!
currentKospiPrice = typeof currentKospiPrice !== 'undefined' ? currentKospiPrice : 7552.39;
currentBtcPrice = typeof currentBtcPrice !== 'undefined' ? currentBtcPrice : 114000000;

function generateBaseHistory(basePrice, variance) {
    const data = [];
    const timeNow = Math.floor(Date.now() / 1000);
    for (let i = 20; i >= 0; i--) {
        data.push({
            time: timeNow - (i * 60),
            value: basePrice + (Math.random() * variance - (variance / 2))
        });
    }
    return data;
}

/* 4. 초기화 구동 */
document.addEventListener("DOMContentLoaded", () => {
    const kRes = createMiniChart('kospi-mini-chart', '#F04452');
    if (kRes) { kospiChartObj = kRes.chart; kospiSeries = kRes.series; }

    const bRes = createMiniChart('btc-mini-chart', '#3182F6');
    if (bRes) { btcChartObj = bRes.chart; btcSeries = bRes.series; }

    kospiSeries.setData(generateBaseHistory(currentKospiPrice, 10));
    btcSeries.setData(generateBaseHistory(currentBtcPrice, 200000));

    initDashboardData().then(() => {
        startRealTimeEngine();
        setInterval(startRealTimeEngine, 4000); // 4초 주기 리프레시 엔진 작동
    });
});

/* 5. 최초 데이터 매핑 */
async function initDashboardData() {
    let isChartLoaded = false; 

    // A. 코스피 진짜 당일 분봉 차트 연동 시도
    try {
        const response = await fetch('/stock/chart?code=0001&range=min');
        const resData = await response.json();

        if (resData && resData.output2 && resData.output2.length > 0) {
            const rawList = resData.output2;
            const chartData = [];

            for (let i = rawList.length - 1; i >= 0; i--) {
                const item = rawList[i];
                const timestamp = parseStockDate(item.stck_bsop_date, item.stck_cntg_hour);
                
                chartData.push({
                    time: timestamp,
                    value: parseFloat(item.stck_clpr)
                });
            }
            kospiSeries.setData(chartData);
            isChartLoaded = true; 
            console.log("✅ 코스피 실제 분봉 차트 빌드 성공");
        }
    } catch (e) {
        console.warn("⚠️ 코스피 초기 차트 빌드 실패, 기본 가상 대역 유지");
    }

    // B. 한투 백엔드 요약 정보 수급
    try {
        const response = await fetch('/stock/tickers/summary');
        const resData = await response.json();

        if (resData && resData.data && resData.data.length > 0) {
            const allMarketData = resData.data;
            const kospiItem = allMarketData.find(item => item.stock_name.includes("코스피"));
            if (kospiItem) {
                // 🔴 [보정 완료] 백엔드가 정제해서 준 7552.39 그대로 파싱하며 나누기 100 완전 삭제!
                currentKospiPrice = parseFloat(kospiItem.stck_prpr);

                if (!isChartLoaded) {
                    kospiSeries.setData(generateBaseHistory(currentKospiPrice, 15));
                    console.log("🛡️ 대체 가상 히스토리 동기화");
                }

                document.getElementById('idx-kospi-price').textContent = currentKospiPrice.toLocaleString(undefined, {minimumFractionDigits: 2});

                const changeEl = document.getElementById('idx-kospi-change');
                const rate = parseFloat(kospiItem.prdy_ctrt);
                changeEl.textContent = (rate >= 0 ? '+' : '') + kospiItem.prdy_ctrt + '%';
                changeEl.style.color = rate >= 0 ? '#F04452' : '#3182F6';
                console.log("✅ 코스피 실전 현재가 초기화 성공:", currentKospiPrice);
            }
        }
    } catch (e) {
        console.warn("⚠️ 네이버 기반 백엔드 요약 시세 수급 실패");
    }

    // C. 비트코인 빗썸 퍼블릭 API 단독 호출 전개
    try {
        const response = await fetch('https://api.bithumb.com/public/ticker/BTC_KRW');
        const resData = await response.json();

        if (resData && resData.status === "0000" && resData.data) {
            currentBtcPrice = parseFloat(resData.data.closing_price);
            const rate = parseFloat(resData.data.fluctate_rate_24H);
            const changeEl = document.getElementById('idx-btc-change');
            changeEl.textContent = (rate >= 0 ? '+' : '') + rate + '%';
            changeEl.style.color = rate >= 0 ? '#F04452' : '#3182F6';

            const newHistory = generateBaseHistory(currentBtcPrice, 400000);
            btcSeries.setData(newHistory);
            document.getElementById('idx-btc-price').textContent = Math.floor(currentBtcPrice).toLocaleString();
            console.log("✅ 빗썸 비트코인 실제 현재가 싱크 완료");
        }
    } catch (e) {
        console.warn("⚠️ 빗썸 API 통신 오류:", e);
    }
}

/* =====================================================
   6. 실시간 동기화 엔진 (실전 시세 반영)
   ===================================================== */
async function startRealTimeEngine() {
    const currentTime = Math.floor(Date.now() / 1000);

    // 코스피 실시간 루틴 (백엔드가 포워딩한 네이버 실전 주가 반영)
    try {
        const response = await fetch('/stock/tickers/summary');
        const resData = await response.json();

        if (resData && resData.data && resData.data.length > 0) {
            const kospiItem = resData.data.find(item => item.stock_name.includes("코스피"));
            if (kospiItem && kospiItem.stck_prpr) {
                
                // 🔴 [보정 완료] 실시간 동기화 루프에서도 나누기 100 완전 척결! 순정 7500선 수급!
                currentKospiPrice = parseFloat(kospiItem.stck_prpr);

                const changeEl = document.getElementById('idx-kospi-change');
                const rate = parseFloat(kospiItem.prdy_ctrt);
                changeEl.textContent = (rate >= 0 ? '+' : '') + kospiItem.prdy_ctrt + '%';
                changeEl.style.color = rate >= 0 ? '#F04452' : '#3182F6';

                console.log("📊 [실시간 싱크] KOSPI 현재 지수:", currentKospiPrice);
            }
        }
    } catch (e) {
        console.warn("⚠️ 백엔드 시세 파이프라인 통신 대기 중");
    }

    // 데이터가 변환 없이 정상 공급되므로 차트 라인이 왜곡 없이 똑바로 그려집니다.
    kospiSeries.update({ time: currentTime, value: currentKospiPrice });
    document.getElementById('idx-kospi-price').textContent = currentKospiPrice.toLocaleString(undefined, { minimumFractionDigits: 2 });

    // 비트코인 실시간 루틴
    try {
        const response = await fetch('https://api.bithumb.com/public/ticker/BTC_KRW');
        const resData = await response.json();

        if (resData && resData.status === "0000" && resData.data) {
            currentBtcPrice = parseFloat(resData.data.closing_price);
            const rate = parseFloat(resData.data.fluctate_rate_24H);
            const changeEl = document.getElementById('idx-btc-change');
            changeEl.textContent = (rate >= 0 ? '+' : '') + rate + '%';
            changeEl.style.color = rate >= 0 ? '#F04452' : '#3182F6';
        }
    } catch (e) {
        currentBtcPrice += Math.floor(Math.random() * 10000 - 5000);
    }
    btcSeries.update({ time: currentTime, value: currentBtcPrice });
    document.getElementById('idx-btc-price').textContent = Math.floor(currentBtcPrice).toLocaleString();
}