/* =====================================================
   stock.js - 주식 개별 차트 및 실시간 호가/주문 인터페이스 엔진
   ===================================================== */

/* ── 1. 전역 상태 관리 ── */
let chart, candlestickSeries, volumeSeries, ma5Series, ma20Series;
let currentSymbol = '005930';
let lastPrice = 0;
let orderSide = 'buy';
let showHighLow = true;
let isLog = false;
let allCandles = [];
const indState = { ma5: false, ma20: false };

/* ── 2. 초기화 구동 (DOM 로드 완료 시 캔버스 빌드) ── */
document.addEventListener('DOMContentLoaded', function () {
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

    ma5Series  = chart.addSeries(LightweightCharts.LineSeries, { color: '#FF9800', lineWidth: 1, title: 'MA5',  visible: false, priceLineVisible: false });
    ma20Series = chart.addSeries(LightweightCharts.LineSeries, { color: '#3182F6', lineWidth: 1, title: 'MA20', visible: false, priceLineVisible: false });

    /* OHLC 바 크로스헤어 인터랙션 맵핑 */
    chart.subscribeCrosshairMove(param => {
        if (!param.time) return;
        const c = param.seriesData.get(candlestickSeries);
        if (!c) return;
        document.getElementById('val-o').textContent = c.open.toLocaleString();
        document.getElementById('val-h').textContent = c.high.toLocaleString();
        document.getElementById('val-l').textContent = c.low.toLocaleString();
        document.getElementById('val-c').textContent = c.close.toLocaleString();
    });

    /* 최고/최저 가격 라벨 트래킹 */
    const chartWrapper = document.getElementById('chart-wrapper');
    if (chartWrapper) {
        chartWrapper.addEventListener('mousemove', updateHighLow);
    }
    chart.timeScale().subscribeVisibleLogicalRangeChange(updateHighLow);

    // 초기 진입 시 1D(일봉) 차트 기준 엔진 런칭
    fetchChart('1y');
});

/* ── 3. 종목 조회 및 검색 기능 ── */
function searchStock() {
    const input = document.getElementById('symbolInput').value.trim();
    if (!input) { alert('종목명 또는 코드를 입력하세요.'); return; }
    currentSymbol = input;
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
function fetchChart(range, btnEl) {
    document.querySelectorAll('.tf-btn[data-tf]').forEach(b => b.classList.remove('active'));
    if (btnEl) btnEl.classList.add('active');

	fetch('/stock/chart?code=' + encodeURIComponent(currentSymbol) + '&range=' + range)
	    .then(r => r.json())
	    .then(data => {
	        // 🔴 [디버그 토탈 로깅] 백엔드가 던져준 원본 객체를 브라우저 콘솔에 통째로 출력!
	        console.log("📡 [프론트엔드 수신 데이터] :", data);

	        if (data.stockName) document.getElementById('displayTitle').innerText = data.stockName;
	        if (data.stockCode) {
	            document.getElementById('displayCode').innerText = '(' + data.stockCode + ')';
	            currentSymbol = data.stockCode;
	        }
	        currentSymbol = data.stockCode || currentSymbol;

	        // 🔴 [가드 보정] 유연한 필드명 매핑 방어선 구축
	        // 백엔드가 대소문자를 섞어 보냈거나(Output2), 다른 키에 담았을 경우를 대비해 스왑 가드를 칩니다.
	        const actualList = data.output2 || data.Output2 || data.candles || [];

	        if (!actualList || actualList.length === 0) {
	            console.warn("⚠️ 시세 히스토리 버퍼가 비어있습니다. 실제 수신된 객체:", data);
	            return;
	        }

	        // candles 맵핑 타겟을 actualList로 변경
	        const candles = actualList.map(d => {
	            let timeValue = d.time;
	            if (d.time && (d.time.includes(':') || d.time.includes(' '))) {
	                timeValue = Math.floor(new Date(d.time.replace(/-/g, '/')).getTime() / 1000);
	            }
	            
	            return {
	                time:   timeValue, 
	                open:   parseFloat(d.open || 0),
	                high:   parseFloat(d.high || 0),
	                low:    parseFloat(d.low || 0),
	                close:  parseFloat(d.close || 0),
	                volume: parseFloat(d.volume || 0)
	            };
	        }).sort((a, b) => {
	            const timeA = typeof a.time === 'number' ? a.time : new Date(a.time.replace(/-/g, '/')).getTime();
	            const timeB = typeof b.time === 'number' ? b.time : new Date(b.time.replace(/-/g, '/')).getTime();
	            return timeA - timeB;
	        });

            allCandles = candles;
            candlestickSeries.setData(candles);
            
            volumeSeries.setData(candles.map(c => ({
                time: c.time, value: c.volume,
                color: c.close >= c.open ? 'rgba(240,68,82,0.44)' : 'rgba(37,99,235,0.44)'
            })));
            
            ma5Series.setData(calculateMA(candles, 5));
            ma20Series.setData(calculateMA(candles, 20));
            chart.timeScale().fitContent();

            /* 상단 전일대비 지표 레이블 갱신 */
            const last = candles[candles.length - 1];
            const prev = candles.length > 1 ? candles[candles.length - 2].close : last.close;
            lastPrice = last.close;
            
            updatePriceHeader(last, prev);
            renderMockHoga(last.close);
            updateHighLow();
            
            console.log("✅ 외부 스크립트 기반 차트 동기화 완수");
        })
        .catch(err => { 
            console.error("❌ 차트 피드 엔진 장애:", err); 
        });
}

function updatePriceHeader(last, prev) {
    document.getElementById('ph-price').textContent = last.close.toLocaleString();
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
    
    if(document.getElementById('ph-open')) document.getElementById('ph-open').textContent = last.open.toLocaleString();
    if(document.getElementById('ph-high')) document.getElementById('ph-high').textContent = last.high.toLocaleString();
    if(document.getElementById('ph-low')) document.getElementById('ph-low').textContent = last.low.toLocaleString();
    if(document.getElementById('ph-vol')) document.getElementById('ph-vol').textContent = last.volume.toLocaleString() + '주';
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
    if (name === 'ma5')  ma5Series.applyOptions({ visible: on });
    if (name === 'ma20') ma20Series.applyOptions({ visible: on });
}

function toggleSettingsMenu(e) {
    if (e) {
        e.stopPropagation(); // window.event 대신 e를 사용하여 전파 차단
    }
    const menu = document.getElementById('settings-menu');
    if (menu) {
        menu.classList.toggle('open');
    }
}

document.addEventListener('click', e => {
    const menu = document.getElementById('settings-menu');
    if (menu && !e.target.closest('.settings-wrap')) {
        menu.classList.remove('open');
    }
});

function toggleLog() {
    isLog = !isLog;
    chart.priceScale('right').applyOptions({ mode: isLog ? 1 : 0 });
}

/* ── 7. 최고/최저 가격 스마트 트래커 ── */
function updateHighLow() {
    if (!showHighLow || !chart || allCandles.length === 0) return;
    const lr = chart.timeScale().getVisibleLogicalRange();
    if (!lr) return;
    const from = Math.max(0, Math.floor(lr.from));
    const to   = Math.min(allCandles.length - 1, Math.ceil(lr.to));
    const vis  = allCandles.slice(from, to + 1);
    if (!vis.length) return;

    let hV = -Infinity, lV = Infinity, hC, lC;
    vis.forEach(d => {
        if (d.high > hV) { hV = d.high; hC = d; }
        if (d.low  < lV) { lV = d.low;  lC = d; }
    });

    const hX = chart.timeScale().timeToCoordinate(hC.time);
    const hY = candlestickSeries.priceToCoordinate(hV);
    const lX = chart.timeScale().timeToCoordinate(lC.time);
    const lY = candlestickSeries.priceToCoordinate(lV);

    const hEl = document.getElementById('hl-high');
    const lEl = document.getElementById('hl-low');
    if (hX != null && hY != null && hEl) {
        hEl.style.display = 'flex';
        hEl.style.left = hX + 'px';
        hEl.style.top  = (hY - 48) + 'px';
        document.getElementById('hl-high-val').textContent = hV.toLocaleString() + '원';
    }
    if (lX != null && lY != null && lEl) {
        lEl.style.display = 'flex';
        lEl.style.left = lX + 'px';
        lEl.style.top  = (lY + 10) + 'px';
        document.getElementById('hl-low-val').textContent = lV.toLocaleString() + '원';
    }
}

function toggleHighLow(enabled) {
    showHighLow = enabled;
    document.getElementById('hl-high').style.display = enabled ? 'flex' : 'none';
    document.getElementById('hl-low').style.display  = enabled ? 'flex' : 'none';
    if (enabled) updateHighLow();
}

/* ── 8. 시뮬레이션 주문 연동 서브 시스템 ── */
function switchOrderTab(side) {
    orderSide = side;
    const isBuy = side === 'buy';
    document.getElementById('tab-buy').classList.toggle('active', isBuy);
    document.getElementById('tab-sell').classList.toggle('active', !isBuy);
    document.getElementById('order-submit-btn').textContent = isBuy ? '매수 주문' : '매도 주문';
    document.getElementById('order-submit-btn').className = isBuy ? 'btn-buy' : 'btn-sell';
    calcAmount();
}

function selectOrderType(btn) {
    document.querySelectorAll('.order-type-btn').forEach(b => b.classList.remove('sel'));
    btn.classList.add('sel');
    const isMarket = btn.textContent === '시장가';
    const priceInput = document.getElementById('trade-price-input');
    priceInput.disabled = isMarket;
    priceInput.placeholder = isMarket ? '시장가' : '가격 입력';
    if (isMarket) { priceInput.value = ''; document.getElementById('trade-amount').value = ''; }
}

function calcAmount() {
    const price = parseFloat(document.getElementById('trade-price-input').value) || lastPrice;
    const qty   = parseFloat(document.getElementById('trade-qty').value) || 0;
    document.getElementById('trade-amount').value = Math.floor(price * qty).toLocaleString();
}

function setPercent(pct) {
    const price = parseFloat(document.getElementById('trade-price-input').value) || lastPrice;
    const avail = 1000000; 
    if (orderSide === 'buy' && price > 0) {
        document.getElementById('trade-qty').value = Math.floor(avail * pct / 100 / price);
        calcAmount();
    }
}

function submitOrder(side) {
    const qty = document.getElementById('trade-qty').value;
    if (!qty || qty <= 0) { alert('수량을 입력하세요'); return; }
    alert((side === 'buy' ? '매수' : '매도') + ' 주문 기능은 준비 중입니다.');
}

/* ── 9. 호가 오더북 가상 체결 엔진 (오더북 렌더링) ── */
function renderMockHoga(basePrice) {
    const maxQty = 50000;
    const asks = [], bids = [];
    for (let i = 5; i >= 1; i--) {
        const qty = Math.floor(Math.random() * maxQty) + 1000;
        asks.push({ price: basePrice + i * 100, qty });
    }
    for (let i = 1; i <= 5; i++) {
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

    if (document.getElementById('hoga-cur-price')) {
        document.getElementById('hoga-cur-price').textContent = basePrice.toLocaleString() + '원';
    }
}

/* ── 10. 커뮤니티 미니 응원방 댓글 시스템 ── */
function sendChat() {
    const inp = document.getElementById('chat-input');
    const text = inp.value.trim();
    if (!text) return;
    const msgs = document.getElementById('chat-messages');
    const empty = msgs.querySelector('.chat-empty');
    if (empty) empty.remove();
    const div = document.createElement('div');
    div.className = 'chat-msg';
    div.innerHTML = '<span class="cm-name">나</span><span class="cm-text">' + text.replace(/</g, '&lt;') + '</span>';
    msgs.appendChild(div);
    msgs.scrollTop = msgs.scrollHeight;
    inp.value = '';
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
        bp.style.height = Math.max(80,  startBH - d) + 'px';
    });
    document.addEventListener('mouseup', () => {
        if (!drag) return;
        drag = false; h.classList.remove('dragging');
        document.body.style.cursor = ''; document.body.style.userSelect = '';
    });
}

// 리사이저 엔진 초기 가동 분기
document.addEventListener('DOMContentLoaded', () => {
    makeHResizer('rh-1', 'panel-middle', 340, 340);
    makeHResizer('rh-2', 'panel-chat', 270, 380);
    makeVResizer('rh-v', 'panel-order-wrap', 'panel-hoga');
});

window.addEventListener('resize', () => {
    if (window.innerWidth <= 1100) {
        ['panel-middle','panel-order-wrap','panel-hoga','panel-chart'].forEach(id => {
            const el = document.getElementById(id);
            if (el) { el.style.width = ''; el.style.height = ''; }
        });
    }
});