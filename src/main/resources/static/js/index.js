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

function loadStockNews(keyword) {
    if (!keyword) keyword = "삼성전자";
    
    const keywordSpan = document.getElementById("current-news-keyword");
    if(keywordSpan) keywordSpan.innerText = keyword;
    
    const newsListDiv = document.getElementById("naver-news-list");
    if(!newsListDiv) return;
    
    // 🌟 [최종 동기화] 방금 데이터 터진 그 주소 그대로 정밀 타격합니다!
    fetch("/news?keyword=" + encodeURIComponent(keyword))
        .then(response => {
            if (!response.ok) throw new Error("뉴스 서버 응답 불능");
            return response.json();
        })
        .then(data => {
            newsListDiv.innerHTML = "";
            
            if (!data.items || data.items.length === 0) {
                newsListDiv.innerHTML = `<p style="color: #848e9c; text-align: center; padding: 20px 0;">관련 뉴스가 존재하지 않습니다.</p>`;
                return;
            }
            
			data.items.forEach(item => {
			    const card = document.createElement("div");
			    card.style.borderBottom = "1px solid #222634";
			    card.style.padding = "12px 0";
			    
			    // 💡 외부 js 파일이므로 역슬래시(\)를 빼고 순정 백틱(` `)으로만 감싸야 합니다!
			    card.innerHTML = `
			        <div style="margin-bottom: 4px; text-align: left;">
			            <a href="${item.link}" target="_blank" style="color: #e9ecf0; text-decoration: none; font-weight: bold; font-size: 13px;">
			                ${item.title}
			            </a>
			        </div>
			        <div style="color: #848e9c; font-size: 11px; line-height: 1.4; text-align: left;">
			            ${item.description}
			        </div>
			    `;
			    newsListDiv.appendChild(card);
			});
        })
        .catch(error => {
            console.error("❌ 뉴스 렌더링 실패:", error);
            newsListDiv.innerHTML = `<p style="color: #f23645; text-align: center; padding: 10px 0; font-size: 12px;">⚠️ 실시간 뉴스 수급이 지연되고 있습니다.</p>`;
        });
}

/**
 * 📈 2. 실시간 급상승 / 급등락 종목 렌더링 (JSP EL태그 충돌 완벽 방어)
 */
function loadMarketHotTrends() {
    const rankListTbody = document.getElementById("market-rank-list");
    if(!rankListTbody) return;
    
    const mockTrends = [
        { rank: 1, name: "삼성전자", price: "76,200", rate: "+3.45%", isUp: true },
        { rank: 2, name: "SK하이닉스", price: "182,300", rate: "+2.81%", isUp: true },
        { rank: 3, name: "카카오", price: "48,900", rate: "-1.75%", isUp: false },
        { rank: 4, name: "현대차", price: "241,500", rate: "+1.20%", isUp: true },
        { rank: 5, name: "네이버", price: "178,200", rate: "-0.95%", isUp: false }
    ];
    
    rankListTbody.innerHTML = "";
    
	mockTrends.forEach(stock => {
	    const row = document.createElement("tr");
	    row.style.borderBottom = "1px solid #222634";
	    row.style.cursor = "pointer";
	    
	    row.addEventListener("click", () => {
	        loadStockNews(stock.name);
	    });
	    
	    const rateColor = stock.isUp ? "#f23645" : "#2962ff";
	    
	    // 💡 외부 js 파일 스펙에 맞게 역슬래시(\) 없는 순정 템플릿 리터럴로 교정
	    row.innerHTML = `
	        <td style="padding: 12px 4px; font-weight: bold; color: #848e9c;">${stock.rank}</td>
	        <td style="padding: 12px 4px; font-weight: bold; color: #e9ecf0; text-align: left;">${stock.name}</td>
	        <td style="padding: 12px 4px; text-align: right; color: #e9ecf0;">${stock.price}</td>
	        <td style="padding: 12px 4px; text-align: right; font-weight: bold; color: ${rateColor};">${stock.rate}</td>
	    `;
	    rankListTbody.appendChild(row);
	});
}

// 최초 구동부 연동
document.addEventListener("DOMContentLoaded", function() {
    loadStockNews("삼성전자");
    loadMarketHotTrends();
});