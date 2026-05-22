/* =====================================================
   index.js - 통합 대시보드 스크립트
   ===================================================== */

/* 1. 글로벌 상태 및 초기화 */
let kospiChartObj = null, btcChartObj = null;
let kospiSeries = null, btcSeries = null;

// 시세 베이스라인 초기값
currentKospiPrice = typeof currentKospiPrice !== 'undefined' ? currentKospiPrice : 7552.39;
currentBtcPrice = typeof currentBtcPrice !== 'undefined' ? currentBtcPrice : 114000000;

document.addEventListener("DOMContentLoaded", async () => {
    console.log("🚀 대시보드 엔진 가동...");

    // A. 차트 엔진 초기화
    initCharts();

    // B. 데이터 로드 루틴 (병렬 실행)
    await Promise.all([
        initDashboardData(),    // 지수 및 비트코인 초기가
        loadGlobalTicker(),     // 상단 티커
        loadRecentContents(),   // 최근 공지/게시글
        loadHeroAsset(),        // 내 자산 (로그인 시)
        loadStockNews("삼성전자"), // 뉴스
        loadMarketHotTrends()    // 급등락 랭킹
    ]);

    // C. 실시간 업데이트 루프 시작
    startRealTimeEngine();
    setInterval(startRealTimeEngine, 4000); 

    // D. 이벤트 리스너 등록
    initEventListeners();
});

/* 2. 유틸리티 & 차트 함수 */
function initCharts() {
    const kRes = createMiniChart('kospi-mini-chart', '#F04452');
    if (kRes) { kospiChartObj = kRes.chart; kospiSeries = kRes.series; }

    const bRes = createMiniChart('btc-mini-chart', '#3182F6');
    if (bRes) { btcChartObj = bRes.chart; btcSeries = bRes.series; }

    if (kospiSeries) kospiSeries.setData(generateBaseHistory(currentKospiPrice, 10));
    if (btcSeries) btcSeries.setData(generateBaseHistory(currentBtcPrice, 200000));
}

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
        grid: { vertLines: { visible: false }, horzLines: { color: 'rgba(255,255,255,0.03)' } },
        rightPriceScale: { borderVisible: false, scaleMargins: { top: 0.2, bottom: 0.1 } },
        timeScale: { visible: true, borderVisible: false, timeVisible: true, secondsVisible: false },
        handleScale: false, handleScroll: false,
    });

    const series = chart.addSeries(LightweightCharts.AreaSeries, {
        lineColor: lineColor,
        topColor: lineColor + '33',
        bottomColor: lineColor + '00',
        lineWidth: 2,
        priceLineVisible: false, lastValueVisible: false,
    });

    window.addEventListener('resize', () => chart.resize(container.clientWidth, 180));
    return { chart, series };
}

function generateBaseHistory(basePrice, variance) {
    const data = [];
    const timeNow = Math.floor(Date.now() / 1000) + 32400;
    for (let i = 120; i >= 0; i--) {
        data.push({
            time: timeNow - (i * 60),
            value: basePrice + (Math.random() * variance - (variance / 2))
        });
    }
    return data;
}

/* 3. 데이터 패치 함수군 */

async function loadGlobalTicker() {
    const tickerContainer = document.getElementById('global-ticker');
    if (!tickerContainer) return;

    try {
        const response = await fetch('/api/market-index');
        const data = await response.json();
        
        if (data && data.length > 0) {
            tickerContainer.innerHTML = data.map(idx => {
                const isUp = idx.up;
                const color = isUp ? '#F04452' : '#3182F6';
                let emoji = '📈';
                if (idx.name.includes('환율')) emoji = '💵';
                else if (idx.name.includes('비트코인')) emoji = '₿';
                else if (idx.name.includes('나스닥') || idx.name.includes('S&P')) emoji = '🇺🇸';
                
                return `
                    <div class="ticker-item">
                        <span class="ticker-label">${emoji} ${idx.name}</span>
                        <span class="ticker-price">${idx.price}</span>
                        <span class="ticker-change" style="color: ${color}">${idx.change} (${idx.rate})</span>
                    </div>
                `;
            }).join('');
        }
    } catch (e) {
        console.warn("⚠️ 글로벌 지수 로드 실패", e);
    }
}

async function loadRecentContents() {
    // 1. 공지사항
    const noticeDiv = document.getElementById('recent-notices');
    if (noticeDiv) {
        try {
            const res = await fetch('/api/market-index/recent-notice');
            const data = await res.json();
            noticeDiv.innerHTML = data.length > 0 ? data.map(n => `
                <a href="/notice/detail?noticeNo=${n.noticeNo}" class="list-item">
                    <span class="item-title"><span class="badge badge-notice">공지</span>${n.noticeTitle}</span>
                    <span class="item-date">${formatDate(n.noticeDate)}</span>
                </a>
            `).join('') : '<p style="color: var(--text-grey); font-size: 13px; text-align: center; padding: 20px;">공지사항이 없습니다.</p>';
        } catch (e) { console.error("공지사항 패치 실패", e); }
    }

    // 2. 게시판
    const boardDiv = document.getElementById('recent-boards');
    if (boardDiv) {
        try {
            const res = await fetch('/api/market-index/recent-board');
            const data = await res.json();
            boardDiv.innerHTML = data.length > 0 ? data.map(b => `
                <a href="/board/detail?boardNo=${b.boardNo}" class="list-item">
                    <span class="item-title"><span class="badge badge-new">New</span>${b.boardTitle}</span>
                    <span class="item-date">${formatDate(b.boardDate)}</span>
                </a>
            `).join('') : '<p style="color: var(--text-grey); font-size: 13px; text-align: center; padding: 20px;">게시글이 없습니다.</p>';
        } catch (e) { console.error("게시판 패치 실패", e); }
    }
}

function formatDate(dateObj) {
    if (!dateObj) return "";
    // ISO String "2023-10-27T10:00:00" 또는 Jackson Array [2023, 10, 27...] 대응
    if (Array.isArray(dateObj)) {
        return `${String(dateObj[1]).padStart(2, '0')}-${String(dateObj[2]).padStart(2, '0')}`;
    }
    if (typeof dateObj === 'string') {
        return dateObj.substring(5, 10); // "10-27"
    }
    return "";
}

async function loadHeroAsset() {
    const assetEl = document.getElementById('hero-total-asset');
    if (!assetEl) return;

    try {
        const res = await fetch('/stock/my-asset');
        const val = await res.json();
        if (val !== null && val !== undefined) {
            assetEl.textContent = Number(val).toLocaleString() + ' 원';
        }
    } catch (e) {
        assetEl.textContent = '로그인이 필요합니다';
    }
}

async function initDashboardData() {
    // 코스피 초기화
    try {
        const response = await fetch('/stock/tickers/summary');
        const resData = await response.json();
        if (resData?.data?.length > 0) {
            const kospiItem = resData.data.find(item => item.stock_name.includes("코스피"));
            if (kospiItem) {
                currentKospiPrice = parseFloat(kospiItem.stck_prpr);
                if (kospiSeries) kospiSeries.setData(generateBaseHistory(currentKospiPrice, 15));
                updateIndexUI('idx-kospi', currentKospiPrice, kospiItem.prdy_ctrt);
            }
        }
    } catch (e) { console.warn("KOSPI 초기화 실패"); }

    // 비트코인 초기화
    try {
        const response = await fetch('/coin/api/bithumb/ticker?order=BTC&payment=KRW');
        const resData = await response.json();
        if (resData?.status === "0000" && resData.data) {
            currentBtcPrice = parseFloat(resData.data.closing_price);
            if (btcSeries) btcSeries.setData(generateBaseHistory(currentBtcPrice, 400000));
            updateIndexUI('idx-btc', currentBtcPrice, resData.data.fluctate_rate_24H);
        }
    } catch (e) { console.warn("BTC 초기화 실패"); }
}

function updateIndexUI(idPrefix, price, rate) {
    const priceEl = document.getElementById(`${idPrefix}-price`);
    const changeEl = document.getElementById(`${idPrefix}-change`);
    if (priceEl) priceEl.textContent = idPrefix.includes('btc') ? Math.floor(price).toLocaleString() : price.toLocaleString(undefined, {minimumFractionDigits: 2});
    if (changeEl) {
        const r = parseFloat(rate);
        changeEl.textContent = (r >= 0 ? '+' : '') + rate + '%';
        changeEl.style.color = r >= 0 ? '#F04452' : '#3182F6';
    }
}

/* 4. 실시간 엔진 */
async function startRealTimeEngine() {
    const currentTime = Math.floor(Date.now() / 1000) + 32400;

    // KOSPI 실시간
    try {
        const res = await fetch('/stock/tickers/summary');
        const resData = await res.json();
        const kospiItem = resData?.data?.find(item => item.stock_name.includes("코스피"));
        if (kospiItem) {
            currentKospiPrice = parseFloat(kospiItem.stck_prpr);
            updateIndexUI('idx-kospi', currentKospiPrice, kospiItem.prdy_ctrt);
        }
    } catch (e) {}
    if (kospiSeries) kospiSeries.update({ time: currentTime, value: currentKospiPrice });

    // BTC 실시간
    try {
        const res = await fetch('/coin/api/bithumb/ticker?order=BTC&payment=KRW');
        const resData = await res.json();
        if (resData?.status === "0000" && resData.data) {
            currentBtcPrice = parseFloat(resData.data.closing_price);
            updateIndexUI('idx-btc', currentBtcPrice, resData.data.fluctate_rate_24H);
        }
    } catch (e) {
        currentBtcPrice += (Math.random() * 10000 - 5000);
    }
    if (btcSeries) btcSeries.update({ time: currentTime, value: currentBtcPrice });
}

/* 5. 뉴스 및 랭킹 */
async function loadStockNews(keyword) {
    const newsListDiv = document.getElementById("naver-news-list");
    if(!newsListDiv) return;
    
    try {
        const response = await fetch("/news?keyword=" + encodeURIComponent(keyword || "삼성전자"));
        const data = await response.json();
        newsListDiv.innerHTML = "";
        
        if (!data.items || data.items.length === 0) {
            newsListDiv.innerHTML = `<p style="color: #848e9c; text-align: center; padding: 20px;">관련 뉴스가 없습니다.</p>`;
            return;
        }
        
        data.items.forEach(item => {
            const div = document.createElement("div");
            div.style.borderBottom = "1px solid #222634";
            div.style.padding = "12px 0";
            div.innerHTML = `
                <a href="${item.link}" target="_blank" style="color: #e9ecf0; text-decoration: none; font-weight: bold; font-size: 13px;">${item.title}</a>
                <div style="color: #848e9c; font-size: 11px; margin-top: 4px;">${item.description}</div>
            `;
            newsListDiv.appendChild(div);
        });
    } catch (error) {
        newsListDiv.innerHTML = `<p style="color: #f23645; text-align: center; padding: 10px;">뉴스 수급 지연 중...</p>`;
    }
}

async function loadMarketHotTrends() {
    const rankListTbody = document.getElementById("market-rank-list");
    if(!rankListTbody) return;
    
    const mode = typeof currentRankMode !== 'undefined' ? currentRankMode : 'UP';
    
    try {
        const response = await fetch(`/stock/rank?mode=${mode}`);
        const data = await response.json();
        rankListTbody.innerHTML = "";
        
        if (!data || data.length === 0) {
            rankListTbody.innerHTML = `<tr><td colspan="4" style="color: #848e9c; text-align: center; padding: 40px 0;">실시간 데이터를 준비 중입니다...</td></tr>`;
            return;
        }
        
        data.forEach((stock, index) => {
            const row = document.createElement("tr");
            row.style.borderBottom = "1px solid #222634";
            row.style.cursor = "pointer";
            
            // 💡 [안전 조치] 문자열인지 숫자인지 모를 데이터를 안전하게 가공합니다.
            const rawRate = stock.rate ? String(stock.rate).replace(/%/g, '') : "0";
            const rawPrice = stock.price ? String(stock.price).replace(/,/g, '') : "0";
            
            const rate = parseFloat(rawRate);
            const price = parseFloat(rawPrice);
            const rateColor = rate >= 0 ? "#f23645" : "#2962ff";
            
            row.innerHTML = `
                <td style="padding: 12px 4px; color: #848e9c;">${index + 1}</td>
                <td style="padding: 12px 4px; font-weight: bold; color: #e9ecf0;">${stock.name || '알 수 없음'}</td>
                <td style="padding: 12px 4px; text-align: right;">${isNaN(price) ? '0' : price.toLocaleString()}</td>
                <td style="padding: 12px 4px; text-align: right; font-weight: bold; color: ${rateColor};">${rate > 0 ? '+' : ''}${rate}%</td>
            `;
            row.onclick = () => loadStockNews(stock.name);
            rankListTbody.appendChild(row);
        });
    } catch (e) {
        console.warn("⚠️ 랭킹 데이터 렌더링 실패", e);
        rankListTbody.innerHTML = `<tr><td colspan="4" style="color: #f23645; text-align: center; padding: 40px 0;">데이터 가공 중 오류 발생</td></tr>`;
    }
}

function initEventListeners() {
    const mainNewsInput = document.getElementById("main-news-search");
    if (mainNewsInput) {
        mainNewsInput.addEventListener("keypress", (e) => {
            if (e.key === "Enter") {
                const keyword = mainNewsInput.value.trim();
                if (keyword) {
                    mainNewsInput.blur();
                    loadStockNews(keyword);
                }
            }
        });
    }
}
