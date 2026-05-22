/* =====================================================
   stock.js - 주식 개별 차트 및 실시간 호가/주문 인터페이스 엔진
   ===================================================== */

/* ── 1. 전역 상태 관리 ── */
let chart, candlestickSeries, volumeSeries, ma5Series, ma20Series;

// URL 파라미터에서 종목 코드 추출 및 전역 공유 변수 설정
const urlParams = new URLSearchParams(window.location.search);
window.currentSymbol = urlParams.get('code') || '005930';
window.lastPrice = window.lastPrice || 0;

let orderSide = 'buy';
let showHighLow = true;
let isLog = false;
let allCandles = [];
const indState = { ma5: false, ma20: false };
let allStockSearchList = [];
let popularStockSearchList = [];

/* ── 2. 초기화 구동 (DOM 로드 완료 시 캔버스 빌드) ── */
document.addEventListener('DOMContentLoaded', function() {
    const _chartBg = getComputedStyle(document.documentElement).getPropertyValue('--chart-bg').trim() || '#16161A';
    const container = document.getElementById('chart-container');
    if (!container) return; // 차트 컨테이너가 없는 페이지 레이아웃 예외 가드

    chart = LightweightCharts.createChart(container, {
        autoSize: true,
        layout: {
            background: { color: _chartBg },
            textColor: 'rgba(255,255,255,0.5)',
            fontFamily: 'Pretendard, -apple-system, BlinkMacSystemFont, sans-serif',
        },
        grid: {
            vertLines: { color: 'rgba(255,255,255,0.04)' },
            horzLines: { color: 'rgba(255,255,255,0.04)' },
        },
        crosshair: {
            mode: LightweightCharts.CrosshairMode.Normal,
            vertLine: { color: 'rgba(255,255,255,0.2)', labelBackgroundColor: '#3182F6' },
            horzLine: { color: 'rgba(255,255,255,0.2)', labelBackgroundColor: '#3182F6' },
        },
        timeScale: {
            timeVisible: true,
            secondsVisible: false,
            borderColor: 'rgba(255,255,255,0.07)',
            fixLeftEdge: true,
            rightOffset: 15,
        },
        rightPriceScale: {
            borderColor: 'rgba(255,255,255,0.07)',
            entireTextOnly: true,
            autoScale: true,
        },
        localization: {
            priceFormatter: price => Math.floor(price).toLocaleString() + '원',
        },
    });

    candlestickSeries = chart.addSeries(LightweightCharts.CandlestickSeries, {
        upColor: '#F04452', downColor: '#2563EB',
        borderUpColor: '#F04452', borderDownColor: '#2563EB',
        wickUpColor: '#F04452', wickDownColor: '#2563EB',
    });

    volumeSeries = chart.addSeries(LightweightCharts.HistogramSeries, {
        priceFormat: { type: 'volume' },
        priceScaleId: 'volume',
        priceLineVisible: false,
    });
    chart.priceScale('volume').applyOptions({ scaleMargins: { top: 0.8, bottom: 0 } });

    ma5Series = chart.addSeries(LightweightCharts.LineSeries, { color: '#FF9800', lineWidth: 1, title: 'MA5', visible: false, priceLineVisible: false });
    ma20Series = chart.addSeries(LightweightCharts.LineSeries, { color: '#3182F6', lineWidth: 1, title: 'MA20', visible: false, priceLineVisible: false });

    /* OHLC 바 크로스헤어 인터랙션 맵핑 */
    chart.subscribeCrosshairMove(param => {
        if (!param.time) return;
        const c = param.seriesData.get(candlestickSeries);
        if (!c) return;
        const oEl = document.getElementById('val-o');
        const hEl = document.getElementById('val-h');
        const lEl = document.getElementById('val-l');
        const cEl = document.getElementById('val-c');
        if (oEl) oEl.textContent = c.open.toLocaleString();
        if (hEl) hEl.textContent = c.high.toLocaleString();
        if (lEl) lEl.textContent = c.low.toLocaleString();
        if (cEl) cEl.textContent = c.close.toLocaleString();
    });

    /* 최고/최저 가격 라벨 트래킹 */
    const chartWrapper = document.getElementById('chart-wrapper');
    if (chartWrapper) {
        chartWrapper.addEventListener('mousemove', updateHighLow);
    }
    chart.timeScale().subscribeVisibleLogicalRangeChange(updateHighLow);

    // 초기 진입 시 1D(일봉) 차트 기준 엔진 런칭
    fetchChart('1y');
    initStockSearchMenu();
});

/* ── 3. 종목 조회 및 검색 기능 ── */
function searchStock() {
    const input = document.getElementById('symbolInput')?.value.trim();
    if (!input) { alert('종목명 또는 코드를 입력하세요.'); return; }
    window.currentSymbol = input;
    fetchChart('1y');
}

// 엔터키 검색 이벤트 리스너 가드
document.addEventListener('DOMContentLoaded', () => {
    const symbolInput = document.getElementById('symbolInput');
    if (symbolInput) {
        symbolInput.addEventListener('keypress', e => {
            if (e.key === 'Enter') searchStock();
        });
    }
});

async function initStockSearchMenu() {
    const trigger = document.getElementById('search-trigger');
    const dropdown = document.getElementById('search-dropdown');
    const input = document.getElementById('sd-input');
    const label = document.getElementById('sd-label');

    if (!trigger || !dropdown || !input) return;

    trigger.addEventListener('click', (e) => {
        e.stopPropagation();
        const isActive = dropdown.classList.toggle('active');
        if (isActive) {
            input.value = '';
            input.focus();
            if (label) label.textContent = '주요 종목';
            renderStockSearchList(popularStockSearchList);
        }
    });

    document.addEventListener('click', () => dropdown.classList.remove('active'));
    dropdown.addEventListener('click', (e) => e.stopPropagation());

    try {
        const res = await fetch('/stock/db-list');
        const data = await res.json();
        allStockSearchList = (Array.isArray(data) ? data : [])
            .map(item => ({
                code: String(item.code || item.STOCK_CODE || '').trim(),
                name: String(item.name || item.STOCK_NAME || '').trim()
            }))
            .filter(item => item.code && item.name);
        popularStockSearchList = allStockSearchList.slice(0, 5);
        renderStockSearchList(popularStockSearchList);
    } catch (e) {
        renderStockSearchList([]);
    }

    input.addEventListener('input', () => {
        const keyword = input.value.trim().toLowerCase();
        if (!keyword) {
            if (label) label.textContent = '주요 종목';
            renderStockSearchList(popularStockSearchList);
            return;
        }

        const filtered = allStockSearchList
            .filter(item =>
                item.code.includes(keyword) ||
                item.name.toLowerCase().includes(keyword)
            )
            .slice(0, 20);

        if (label) label.textContent = '검색 결과';
        renderStockSearchList(filtered);
    });
}

function renderStockSearchList(list) {
    const container = document.getElementById('sd-list');
    if (!container) return;

    if (!list || list.length === 0) {
        container.innerHTML = '<div class="sd-item"><div class="sd-info"><span class="sd-symbol">표시할 종목이 없습니다</span></div></div>';
        return;
    }

    container.innerHTML = list.map((stock, i) => {
        const initials = (stock.name || stock.code || '  ').slice(0, 2);
        return `
               <div class="sd-item" onclick="location.href='/stock/view?code=${encodeURIComponent(stock.code)}'">
                   <span class="sd-rank">${i + 1}</span>
                   <div class="sd-coin-logo"><span style="font-size:12px;font-weight:700;color:var(--text);">${initials}</span></div>
                   <div class="sd-info">
                       <div class="sd-name-row">
                           <span class="sd-name">${stock.name}</span>
                           <span class="sd-symbol">${stock.code}</span>
                       </div>
                   </div>
               </div>
           `;
    }).join('');
}

/* ── 4. 이동평균선(MA) 테크니컬 지표 연산 기술 ── */
function calculateMA(data, period) {
    return data.reduce((acc, d, i) => {
        if (i >= period - 1) {
            const sum = data.slice(i - period + 1, i + 1).reduce((s, c) => s + c.close, 0);
            acc.push({ time: d.time, value: sum / period });
        }
        return acc;
    }, []);
}

/* ── 5. 실시간 차트 코어 데이터 파이프라인 수급 ── */
function fetchChart(range, btnEl, isAutoRefresh = false) {
    if (!isAutoRefresh) {
        document.querySelectorAll('.tf-btn[data-tf]').forEach(b => b.classList.remove('active'));
        if (btnEl) btnEl.classList.add('active');
    }

    fetch('/stock/chart?code=' + encodeURIComponent(window.currentSymbol) + '&range=' + range)
        .then(r => r.json())
        .then(data => {
            console.log("📡 [프론트엔드 수신 데이터] :", data);

            if (data.stockName) {
                const titleEl = document.getElementById('displayTitle');
                if (titleEl) titleEl.innerText = data.stockName;
            }
            if (data.stockCode) {
                const codeEl = document.getElementById('displayCode');
                if (codeEl) codeEl.innerText = '(' + data.stockCode + ')';
                window.currentSymbol = data.stockCode;
            }
            window.currentSymbol = data.stockCode || window.currentSymbol;

            const actualList = data.output2 || data.Output2 || data.candles || [];

            if (!actualList || actualList.length === 0) {
                console.warn("⚠️ 시세 히스토리 버퍼가 비어있습니다.", data);
                return;
            }

            const candles = actualList.map(d => {
                if (!d) return null;

                let timeValue = d.time;
                if (d.time && (typeof d.time === 'string') && (d.time.includes(':') || d.time.includes(' '))) {
                    timeValue = Math.floor(new Date(d.time.replace(/-/g, '/')).getTime() / 1000);
                }

                const fallbackPrice = parseFloat(d.close || d.mkstat_prpr || d.stck_prpr || d.nv || window.lastPrice || 0);

                return {
                    time: timeValue,
                    open: parseFloat(d.open || fallbackPrice),
                    high: parseFloat(d.high || fallbackPrice),
                    low: parseFloat(d.low || fallbackPrice),
                    close: parseFloat(d.close || fallbackPrice),
                    volume: parseFloat(d.volume || 0)
                };
            })
                .filter(c => c !== null && !isNaN(c.close))
                .sort((a, b) => a.time - b.time);

            if (candles.length === 0) return;

            allCandles = candles;
            candlestickSeries.setData(candles);

            volumeSeries.setData(candles.map(c => ({
                time: c.time, value: c.volume,
                color: c.close >= c.open ? 'rgba(240,68,82,0.44)' : 'rgba(37,99,235,0.44)'
            })));

            ma5Series.setData(calculateMA(candles, 5));
            ma20Series.setData(calculateMA(candles, 20));

            if (!isAutoRefresh) {
                chart.timeScale().fitContent();
            }

            /* 상단 전일대비 지표 레이블 및 호가창 갱신 */
            const last = candles[candles.length - 1];
            const prev = candles.length > 1 ? candles[candles.length - 2].close : last.close;
            window.lastPrice = last.close;

            updatePriceHeader(last, prev);
            renderMockHoga(last.close);
            updateHighLow();

            // 상위 컨텍스트의 함수 존재 시 실시간 UI 갱신 호출 구조 가드
            if (typeof updateSidebarRealtimeUI === 'function') updateSidebarRealtimeUI();

            console.log("✅ 차트 데이터 파이프라인 동기화 완수");
        })
        .catch(err => {
            console.error("❌ 차트 피드 엔진 장애:", err);
        });
}

function updatePriceHeader(last, prev) {
    const priceEl = document.getElementById('ph-price');
    if (priceEl) priceEl.textContent = last.close.toLocaleString();
    
    const abs = last.close - prev;
    const pct = prev > 0 ? (abs / prev * 100) : 0;
    const cls = abs >= 0 ? 'up' : 'down';
    const sign = abs >= 0 ? '+' : '';

    const absEl = document.getElementById('ph-change-abs');
    if (absEl) {
        absEl.textContent = sign + abs.toLocaleString() + '원';
        absEl.className = 'ph-change ' + cls;
    }

    const pctEl = document.getElementById('ph-change');
    if (pctEl) {
        pctEl.textContent = '(' + sign + pct.toFixed(2) + '%)';
        pctEl.className = 'ph-change ' + cls;
    }

    const openEl = document.getElementById('ph-open');
    if (openEl) openEl.textContent = last.open.toLocaleString();
    
    const highEl = document.getElementById('ph-high');
    if (highEl) highEl.textContent = last.high.toLocaleString();
    
    const lowEl = document.getElementById('ph-low');
    if (lowEl) lowEl.textContent = last.low.toLocaleString();
    
    const volEl = document.getElementById('ph-vol');
    if (volEl) volEl.textContent = last.volume.toLocaleString() + '주';
}

/* ── 6. 보조 지표 및 차트 튜닝 제어 ── */
function toggleInd(name) {
    indState[name] = !indState[name];
    const on = indState[name];
    const colors = { ma5: '#FF9800', ma20: '#3182F6' };
    const btn = document.getElementById('ind-' + name);
    if (btn) {
        if (on) {
            btn.style.borderColor = colors[name];
            btn.style.color = colors[name];
            btn.style.background = colors[name] + '18';
        } else {
            btn.style.borderColor = '';
            btn.style.color = '';
            btn.style.background = '';
        }
    }
    if (name === 'ma5') ma5Series.applyOptions({ visible: on });
    if (name === 'ma20') ma20Series.applyOptions({ visible: on });
}

function toggleSettingsMenu(e) {
    if (e) { e.stopPropagation(); }
    const menu = document.getElementById('settings-menu');
    if (menu) { menu.classList.toggle('open'); }
}

document.addEventListener('click', e => {
    const menu = document.getElementById('settings-menu');
    if (menu && !e.target.closest('.settings-wrap')) {
        menu.classList.remove('open');
    }
});

// 로그 스케일 변환 기능
function toggleLog() {
    isLog = !isLog;
    if (chart) chart.priceScale('right').applyOptions({ mode: isLog ? 1 : 0 });
}

/* ── 7. 최고/최저 가격 스마트 트래커 ── */
function updateHighLow() {
    if (!showHighLow || !chart || allCandles.length === 0) return;
    const lr = chart.timeScale().getVisibleLogicalRange();
    if (!lr) return;
    const from = Math.max(0, Math.floor(lr.from));
    const to = Math.min(allCandles.length - 1, Math.ceil(lr.to));
    const vis = allCandles.slice(from, to + 1);
    if (!vis.length) return;

    let hV = -Infinity, lV = Infinity, hC, lC;
    vis.forEach(d => {
        if (d.high > hV) { hV = d.high; hC = d; }
        if (d.low < lV) { lV = d.low; lC = d; }
    });

    const hX = chart.timeScale().timeToCoordinate(hC.time);
    const hY = candlestickSeries.priceToCoordinate(hV);
    const lX = chart.timeScale().timeToCoordinate(lC.time);
    const lY = candlestickSeries.priceToCoordinate(lV);

    const hEl = document.getElementById('hl-high');
    const lEl = document.getElementById('hl-low');
    const hValEl = document.getElementById('hl-high-val');
    const lValEl = document.getElementById('hl-low-val');

    if (hX != null && hY != null && hEl) {
        hEl.style.display = 'flex';
        hEl.style.left = hX + 'px';
        hEl.style.top = (hY - 48) + 'px';
        if (hValEl) hValEl.textContent = hV.toLocaleString() + '원';
    }
    if (lX != null && lY != null && lEl) {
        lEl.style.display = 'flex';
        lEl.style.left = lX + 'px';
        lEl.style.top = (lY + 10) + 'px';
        if (lValEl) lValEl.textContent = lV.toLocaleString() + '원';
    }
}

function toggleHighLow(enabled) {
    showHighLow = enabled;
    const hEl = document.getElementById('hl-high');
    const lEl = document.getElementById('hl-low');
    if (hEl) hEl.style.display = enabled ? 'flex' : 'none';
    if (lEl) lEl.style.display = enabled ? 'flex' : 'none';
    if (enabled) updateHighLow();
}

/* ── 8. 시뮬레이션 주문 연동 서브 시스템 ── */
function switchOrderTab(side) {
    orderSide = side;
    const isBuy = side === 'buy';

    const tabBuy = document.getElementById('tab-buy');
    const tabSell = document.getElementById('tab-sell');
    const submitBtn = document.getElementById('order-submit-btn');

    if (tabBuy) tabBuy.classList.toggle('active', isBuy);
    if (tabSell) tabSell.classList.toggle('active', !isBuy);

    if (submitBtn) {
        submitBtn.textContent = isBuy ? '매수 주문' : '매도 주문';
        submitBtn.className = isBuy ? 'btn-buy' : 'btn-sell';
    }
    calcAmount();
}

/**
 * 지정가 / 시장가 선택 제어
 */
function selectOrderType(btn) {
    if (!btn) return;
    document.querySelectorAll('.order-type-btn').forEach(b => b.classList.remove('sel'));
    btn.classList.add('sel');

    const isMarket = btn.textContent.trim() === '시장가';
    const priceInput = document.getElementById('trade-price-input');

    if (priceInput) {
        priceInput.disabled = isMarket;
        priceInput.placeholder = isMarket ? '시장가' : '가격 입력';
        if (isMarket) {
            priceInput.value = '';
            const qtyInput = document.getElementById('trade-qty');
            if (qtyInput) qtyInput.value = '';
        }
    }
    calcAmount();
}

/**
 * 총 주문 금액 실시간 연산 기술
 */
function calcAmount() {
    const priceInput = document.getElementById('trade-price-input');
    const qtyInput = document.getElementById('trade-qty');
    const amountEl = document.getElementById('trade-amount');

    if (!amountEl) return;

    // 시장가일 때는 전역 변수에 저장된 실시간 최종 체결가(window.lastPrice)를 기준 삼음
    const isMarket = priceInput ? priceInput.disabled : false;
    const price = isMarket ? window.lastPrice : (parseFloat(priceInput?.value) || window.lastPrice);
    const qty = qtyInput ? (parseFloat(qtyInput.value) || 0) : 0;

    amountEl.textContent = Math.floor(price * qty).toLocaleString();
}

/**
 * 투자 잔고 기반 수량 퍼센트(%) 자동 설정 플러그인
 */
function setPercent(pct) {
    const priceInput = document.getElementById('trade-price-input');
    const qtyInput = document.getElementById('trade-qty');
    if (!qtyInput) return;

    const isMarket = priceInput ? priceInput.disabled : false;
    const price = isMarket ? window.lastPrice : (parseFloat(priceInput?.value) || window.lastPrice);

    if (price <= 0) {
        alert('현재 가격 정보가 유효하지 않아 수량을 계산할 수 없습니다.');
        return;
    }

    // DOM 자산 파싱 알고리즘 가드
    const availText = document.getElementById('avail-balance')?.textContent || "0";
    const avail = parseInt(availText.replace(/[^0-9]/g, '')) || 0;

    if (orderSide === 'buy') {
        qtyInput.value = Math.floor((avail * (pct / 100)) / price);
    } else {
        // 매도 시에는 보유 주식 수량(Holdings) 기준 퍼센트로 작동하는 것이 금융 도메인 표준 인터페이스입니다.
        const holdingQtyText = document.getElementById('holding-qty')?.textContent || "0";
        const holdingQty = parseInt(holdingQtyText.replace(/[^0-9]/g, '')) || 0;
        qtyInput.value = Math.floor(holdingQty * (pct / 100));
    }

    calcAmount();

    // 비율 선택 완료 후 드롭다운 닫기
    const menu = document.getElementById('pct-drop-menu');
    if (menu) menu.style.display = 'none';
}

/**
 * 수량 비율(%) 설정 드롭다운 메뉴 토글 (순수 인터페이스 제어 역할로 복원)
 */
function togglePctDrop() {
    const menu = document.getElementById('pct-drop-menu');
    if (!menu) return;

    if (menu.style.display === 'block') {
        menu.style.display = 'none';
    } else {
        menu.style.display = 'block';
    }
}

/**
 * 백엔드 API 연동 실시간 모의 투자 주문 전송 엔진
 */
function submitOrder(side) {
    const qtyInput = document.getElementById('trade-qty');
    if (!qtyInput || !qtyInput.value) {
        alert('수량을 입력하세요.');
        return;
    }

    const orderCount = parseInt(qtyInput.value);
    if (isNaN(orderCount) || orderCount <= 0) {
        alert('수량을 정확히 입력하세요.');
        return;
    }

    const priceInputEl = document.getElementById('trade-price-input');
    const priceInputValue = priceInputEl ? priceInputEl.value.trim() : "";
    const isMarket = priceInputEl ? priceInputEl.disabled : false;

    // 무결성 가격 연산 메커니즘
    let orderPrice = isMarket ? window.lastPrice : parseInt(priceInputValue.replace(/[^0-9]/g, ''));
    if (isNaN(orderPrice) || orderPrice <= 0) {
        orderPrice = window.lastPrice;
    }

    if (!orderPrice || orderPrice <= 0) {
        alert('현재 가격 또는 입력된 가격 정보를 가져오지 못했습니다.');
        return;
    }

    const sideText = (side === 'buy' || side === 'BUY' || orderSide === 'buy') ? 'BUY' : 'SELL';
    const orderData = {
        orderType: sideText,
        orderPrice: orderPrice,
        orderCount: orderCount,
        stockNo: parseInt(window.currentSymbol) || 0,
        stockCode: String(window.currentSymbol || '').padStart(6, '0'),
        status: isMarket ? "COMPLETED" : "PENDING",
        targetPrice: isMarket ? 0 : orderPrice
    };

    if (!confirm(`[주문 접수]\n구분: ${sideText === 'BUY' ? '매수' : '매도'}\n가격: ${orderPrice.toLocaleString()}원\n수량: ${orderCount}주\n진행하시겠습니까?`)) return;

    fetch(`/stock/order?side=${sideText}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(orderData)
    })
        .then(response => {
            if (!response.ok) throw new Error("서버 응답 오류 (HTTP Status Error)");
            return response.json();
        })
        .then(data => {
            if (data.success === true || data.success === "true") {
                alert(data.message || '주문이 성공적으로 처리되었습니다.');

                // 전역/상위 자산 UI 실시간 컴포넌트 동기화 가드
                if (typeof loadMyInvestmentStatus === 'function') loadMyInvestmentStatus();
                if (typeof updateAccountBalanceUI === 'function') updateAccountBalanceUI();
            } else {
                alert('주문 실패: ' + (data.message || '알 수 없는 오류'));
            }
        })
        .catch(err => {
            console.error('❌ 모의투자 주문 전송 엔진 트랜잭션 장애:', err);
            alert('주문 처리 중 통신 오류가 발생했습니다.');
        });
}

/* ── 9. 호가 오더북 가상 체결 엔진 (오더북 렌더링) ── */
function renderMockHoga(basePrice) {
    const maxQty = 50000;
    const asks = [], bids = [];

    for (let i = 5;i >= 1;i--) {
        const qty = Math.floor(Math.random() * maxQty) + 1000;
        asks.push({ price: basePrice + i * 100, qty });
    }
    for (let i = 1;i <= 5;i++) {
        const qty = Math.floor(Math.random() * maxQty) + 1000;
        bids.push({ price: basePrice - i * 100, qty });
    }

    let askCumul = 0;
    const askMax = asks.reduce((s, r) => s + r.qty, 0);
    const asksContainer = document.getElementById('hoga-asks');
    if (asksContainer) {
        asksContainer.innerHTML = asks.map(r => {
            askCumul += r.qty;
            const pct = (askCumul / askMax * 100).toFixed(1);
            return `<tr style="background:linear-gradient(to left,rgba(37,99,235,0.12) ${pct}%,transparent ${pct}%)">
                   <td class="hoga-ask">${r.price.toLocaleString()}</td>
                   <td>${r.qty.toLocaleString()}</td>
                   <td>${askCumul.toLocaleString()}</td>
               </tr>`;
        }).join('');
    }

    let bidCumul = 0;
    const bidMax = bids.reduce((s, r) => s + r.qty, 0);
    const bidsContainer = document.getElementById('hoga-bids');
    if (bidsContainer) {
        bidsContainer.innerHTML = bids.map(r => {
            bidCumul += r.qty;
            const pct = (bidCumul / bidMax * 100).toFixed(1);
            return `<tr style="background:linear-gradient(to left,rgba(240,68,82,0.12) ${pct}%,transparent ${pct}%)">
                   <td class="hoga-bid">${r.price.toLocaleString()}</td>
                   <td>${r.qty.toLocaleString()}</td>
                   <td>${bidCumul.toLocaleString()}</td>
               </tr>`;
        }).join('');
    }

    const curPriceEl = document.getElementById('hoga-cur-price');
    if (curPriceEl) {
        curPriceEl.textContent = basePrice.toLocaleString() + '원';
    }
}

/* ── 10. 실시간 댓글 뷰어 (STOMP/WebSocket) ── */
let stockChartChatClient = null;
let stockChartChatSub = null;
let currentChatCode = null;
let currentChatSort = 'latest';

function connectStockChat(code) {
    currentChatCode = code;
    loadStockChatHistory(code);

    if (stockChartChatClient && stockChartChatClient.connected) {
        if (stockChartChatSub) stockChartChatSub.unsubscribe();
        stockChartChatSub = stockChartChatClient.subscribe('/topic/market/STOCK/' + code, msg => {
            const dto = JSON.parse(msg.body);
            if (dto.type === 'DELETE') {
                const el = document.querySelector('.chat-msg[data-no="' + dto.commentNo + '"]');
                if (el) el.remove();
            } else {
                cmAppendChatMsg(dto.username, dto.content, dto.createdAt, true, dto.imageUrl, dto.profileFileName, dto.commentNo, dto.likeCount, dto.likedByMe);
            }
        });
        return;
    }

    const socket = new SockJS('/ws-stock');
    stockChartChatClient = Stomp.over(socket);
    stockChartChatClient.debug = null;
    stockChartChatClient.connect({}, () => {
        if (stockChartChatSub) stockChartChatSub.unsubscribe();
        stockChartChatSub = stockChartChatClient.subscribe('/topic/market/STOCK/' + currentChatCode, msg => {
            const dto = JSON.parse(msg.body);
            if (dto.type === 'DELETE') {
                const el = document.querySelector('.chat-msg[data-no="' + dto.commentNo + '"]');
                if (el) el.remove();
            } else {
                cmAppendChatMsg(dto.username, dto.content, dto.createdAt, true, dto.imageUrl, dto.profileFileName, dto.commentNo, dto.likeCount, dto.likedByMe);
            }
        });
    });
}

function loadStockChatHistory(code, sort) {
    const s = sort || currentChatSort;
    fetch('/market/comments/STOCK/' + code + '?sort=' + s)
        .then(r => r.json())
        .then(list => {
            const msgs = document.getElementById('chat-messages');
            if (!msgs) return;
            msgs.innerHTML = '';
            if (!list.length) {
                msgs.innerHTML = '<div class="chat-empty"><span class="chat-empty-icon">💬</span><span>첫 댓글을 남겨보세요</span></div>';
                return;
            }
            list.forEach(dto => cmAppendChatMsg(dto.username, dto.content, dto.createdAt, false, dto.imageUrl, dto.profileFileName, dto.commentNo, dto.likeCount, dto.likedByMe));
        }).catch(() => {});
}

/* ── 11. 인터페이스 동적 리사이저 플러그인 ── */
function makeHResizer(handleId, rightPanelId, minW, maxW) {
    const h = document.getElementById(handleId);
    const rp = document.getElementById(rightPanelId);
    if (!h || !rp) return;
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
        rp.style.width = w; rp.style.flexBasis = w;
    });
    document.addEventListener('mouseup', () => {
        if (!drag) return;
        drag = false; h.classList.remove('dragging');
        document.body.style.cursor = ''; document.body.style.userSelect = '';
    });
}

function makeVResizer(handleId, topId, botId) {
    const h = document.getElementById(handleId);
    const tp = document.getElementById(topId);
    const bp = document.getElementById(botId);
    if (!h || !tp || !bp) return;
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
        tp.style.height = Math.max(150, startTH + d) + 'px';
        bp.style.height = Math.max(80, startBH - d) + 'px';
    });
    document.addEventListener('mouseup', () => {
        if (!drag) return;
        drag = false; h.classList.remove('dragging');
        document.body.style.cursor = ''; document.body.style.userSelect = '';
    });
}

// 리사이저 엔진 가동 및 초기화
document.addEventListener('DOMContentLoaded', () => {
    makeHResizer('rh-1', 'panel-middle', 340, 340);
    makeHResizer('rh-2', 'panel-chat', 270, 380);
    makeVResizer('rh-v', 'panel-order-wrap', 'panel-hoga');

    // 페이지가 처음 켜졌을 때 우측 사이드바 자산 목록 자동 렌더링 호출
    if (typeof loadMyInvestmentStatus === 'function') loadMyInvestmentStatus();

    // 실시간 댓글 연결
    if (window.currentSymbol) connectStockChat(window.currentSymbol);

    // 정렬 버튼
    document.querySelectorAll('.chat-sort-tabs .chat-sort-btn').forEach(btn => {
        btn.addEventListener('click', function () {
            if (this.dataset.sort === currentChatSort) return;
            document.querySelectorAll('.chat-sort-tabs .chat-sort-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            currentChatSort = this.dataset.sort;
            if (currentChatCode) loadStockChatHistory(currentChatCode, currentChatSort);
        });
    });

    // 전체 보기
    const viewAll = document.getElementById('community-view-all');
    if (viewAll && window.currentSymbol) {
        viewAll.addEventListener('click', () => {
            location.href = '/stock/community?code=' + encodeURIComponent(window.currentSymbol);
        });
    }

    // 댓글 좋아요 이벤트 (이벤트 위임)
    const chatMsgs = document.getElementById('chat-messages');
    if (chatMsgs) {
        chatMsgs.addEventListener('click', e => {
            const btn = e.target.closest('.cm-like-btn');
            if (!btn) return;
            fetch('/api/market/comment/' + btn.dataset.commentNo + '/like', { method: 'POST' })
                .then(r => r.json())
                .then(data => {
                    const svg = btn.querySelector('svg');
                    svg.style.fill   = data.liked ? '#e91e63' : 'none';
                    svg.style.stroke = data.liked ? '#e91e63' : 'currentColor';
                    btn.querySelector('.cm-like-count').textContent = data.count;
                });
        });
    }
});

window.addEventListener('resize', () => {
    if (window.innerWidth <= 1100) {
        ['panel-middle', 'panel-order-wrap', 'panel-hoga', 'panel-chart'].forEach(id => {
            const el = document.getElementById(id);
            if (el) { el.style.width = ''; el.style.height = ''; }
        });
    }
});

// ⏰ 10초 주기 실시간 데이터 갱신 타이머 실행
setInterval(() => {
    const activeBtn = document.querySelector('.chart-toolbar .tf-btn.active');
    let currentRange = '1y';

    if (activeBtn) {
        const onclickAttr = activeBtn.getAttribute('onclick');
        if (onclickAttr && onclickAttr.includes("'min'")) currentRange = 'min';
        else if (onclickAttr && onclickAttr.includes("'3y'")) currentRange = '3y';
        else if (onclickAttr && onclickAttr.includes("'10y'")) currentRange = '10y';
    }

    if (typeof fetchChart === 'function' && window.currentSymbol) {
        fetchChart(currentRange, null, true);
    }
}, 10000);
