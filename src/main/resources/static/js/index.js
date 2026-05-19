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
    const timeNow = Math.floor(Date.now() / 1000) + 32400;
    for (let i = 120; i >= 0; i--) {
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
    const currentTime = Math.floor(Date.now() / 1000) + 32400;

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
    
    // 키워드 텍스트 변경 가드
    const keywordSpan = document.getElementById("current-news-keyword");
    if(keywordSpan) keywordSpan.innerText = keyword;
    
    const newsListDiv = document.getElementById("naver-news-list");
    if(!newsListDiv) return;
    
    // 📡 백엔드 뉴스 API 정밀 타격
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

document.addEventListener("DOMContentLoaded", function() {
    // 최초 실행구동
    loadStockNews("삼성전자");
    if (typeof loadMarketHotTrends === "function") loadMarketHotTrends();

    // 🌟 [엔터 감지 엔진] 이벤트 리스너는 함수 바깥인 여기에 독립적으로 존재해야 합니다.
    const mainNewsInput = document.getElementById("main-news-search");
    if (mainNewsInput) {
        mainNewsInput.addEventListener("keypress", function(e) {
            if (e.key === "Enter") {
                const keyword = mainNewsInput.value.trim();
                if (keyword) {
                    mainNewsInput.blur(); // 인풋창 포커스 아웃 효과
                    
                    // 📡 갱신된 키워드로 뉴스 페치 함수 원격 가동!
                    console.log(`🔍 메인 대시보드 뉴스 타겟 전환: ${keyword}`);
                    loadStockNews(keyword);
                }
            }
        });
    }
});

/**
 * 📈 2. 실시간 급상승 / 급등락 종목 렌더링 (JSP EL태그 충돌 완벽 방어)
 */
function loadMarketHotTrends() {
    const rankListTbody = document.getElementById("market-rank-list");
    if(!rankListTbody) return;
    
    // 💡 전역 변수로 관리 중인 모드('UP' 또는 'DOWN')를 동적으로 읽어옵니다.
    // 만약 변수가 안 잡혀있다면 기본값 'UP'으로 방어합니다.
    const mode = typeof currentRankMode !== 'undefined' ? currentRankMode : 'UP';
    
    // 📡 방금 컨트롤러에 새로 뚫은 따끈따끈한 실전 랭킹 API 창구를 직격합니다!
    fetch(`/stock/rank?mode=${mode}`)
        .then(response => {
            if (!response.ok) throw new Error("시세 엔진 통신 대기");
            return response.json();
        })
        .then(data => {
            rankListTbody.innerHTML = "";
            
            // 🛡️ 백엔드 캐시가 아직 준비되지 않았거나 비어있을 때 예외 가드
            if (!data || data.length === 0) {
                rankListTbody.innerHTML = `<tr><td colspan="4" style="color: #848e9c; text-align: center; padding: 20px 0;">실시간 데이터를 파싱 중입니다...</td></tr>`;
                return;
            }
            
            // 백엔드 자바 스트림이 정렬해서 준 최상위 5개 종목을 그대로 순회 렌더링
            data.forEach((stock, index) => {
                const row = document.createElement("tr");
                row.style.borderBottom = "1px solid #222634";
                row.style.cursor = "pointer";
                
                // 🔴 [한투 순정 DTO 파이프라인] 백엔드 StockListOutput 필드명 매싱 완료!
                const stockName = stock.hts_kor_isnm; // HTS 한글 종목명
                const priceStr = stock.stck_prpr;     // 주식 현재가 (문자열 혹은 숫자)
                const rateStr = stock.prdy_ctrt;      // 전일 대비 등락률
                
                // 현재가 포맷팅 (콤마 추가)
                const price = typeof priceStr !== 'undefined' ? parseFloat(priceStr).toLocaleString() : '-';
                
                // 부호 결정을 위한 변수 치환
                const rate = parseFloat(rateStr);
                const isUp = rate >= 0;
                const rateColor = isUp ? "#f23645" : "#2962ff";
                const sign = isUp ? "+" : ""; // 백엔드가 부호를 안 붙여줬을 때를 대비한 가드
                
                // 종목 클릭 시 해당 종목 실시간 네이버 뉴스 수급 링크 연동
                row.addEventListener("click", () => {
                    if (typeof loadStockNews === "function") loadStockNews(stockName);
                });
                
                // 외부 js 파일 전용 순정 템플릿 리터럴 렌더링
                row.innerHTML = `
                    <td style="padding: 12px 4px; font-weight: bold; color: #848e9c;">${index + 1}</td>
                    <td style="padding: 12px 4px; font-weight: bold; color: #e9ecf0; text-align: left;">${stockName}</td>
                    <td style="padding: 12px 4px; text-align: right; color: #e9ecf0;">${price}</td>
                    <td style="padding: 12px 4px; text-align: right; font-weight: bold; color: ${rateColor};">${sign}${rateStr}%</td>
                `;
                rankListTbody.appendChild(row);
            });
        })
        .catch(error => {
            console.warn("⚠️ 백엔드 실시간 랭킹 서블릿 통신 대기 중...", error);
        });
}

// 최초 구동부 연동
document.addEventListener("DOMContentLoaded", function() {
    loadStockNews("삼성전자");
    loadMarketHotTrends();
});