/* =====================================================
   stock.js - 주식 개별 차트 및 실시간 호가/주문 인터페이스 엔진
   ===================================================== */

/* ── 1. 전역 상태 관리 ── */
let chart, candlestickSeries, volumeSeries, ma5Series, ma20Series;
const _urlCode = new URLSearchParams(window.location.search).get('code');
let currentSymbol = _urlCode || '005930';
let lastPrice = 0;
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
    initStockSearchMenu();
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

    fetch('/stock/chart?code=' + encodeURIComponent(currentSymbol) + '&range=' + range)
        .then(r => r.json())
        .then(data => {
            console.log("📡 [프론트엔드 수신 데이터] :", data);

            if (data.stockName) document.getElementById('displayTitle').innerText = data.stockName;
            if (data.stockCode) {
                document.getElementById('displayCode').innerText = '(' + data.stockCode + ')';
                currentSymbol = data.stockCode;
            }
            currentSymbol = data.stockCode || currentSymbol;

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

                const fallbackPrice = parseFloat(d.close || d.mkstat_prpr || d.stck_prpr || d.nv || lastPrice || 0);

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
            lastPrice = last.close;

            updatePriceHeader(last, prev);
            renderMockHoga(last.close);
            updateHighLow();

            updateSidebarRealtimeUI();

            console.log("✅ 차트 데이터 파이프라인 동기화 완수");
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

    if (document.getElementById('ph-open')) document.getElementById('ph-open').textContent = last.open.toLocaleString();
    if (document.getElementById('ph-high')) document.getElementById('ph-high').textContent = last.high.toLocaleString();
    if (document.getElementById('ph-low')) document.getElementById('ph-low').textContent = last.low.toLocaleString();
    if (document.getElementById('ph-vol')) document.getElementById('ph-vol').textContent = last.volume.toLocaleString() + '주';
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
    chart.priceScale('right').applyOptions({ mode: isLog ? 1 : 0 });
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
    if (hX != null && hY != null && hEl) {
        hEl.style.display = 'flex';
        hEl.style.left = hX + 'px';
        hEl.style.top = (hY - 48) + 'px';
        document.getElementById('hl-high-val').textContent = hV.toLocaleString() + '원';
    }
    if (lX != null && lY != null && lEl) {
        lEl.style.display = 'flex';
        lEl.style.left = lX + 'px';
        lEl.style.top = (lY + 10) + 'px';
        document.getElementById('hl-low-val').textContent = lV.toLocaleString() + '원';
    }
}

function toggleHighLow(enabled) {
    showHighLow = enabled;
    document.getElementById('hl-high').style.display = enabled ? 'flex' : 'none';
    document.getElementById('hl-low').style.display = enabled ? 'flex' : 'none';
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
    const qty = parseFloat(document.getElementById('trade-qty').value) || 0;
    
    const amountEl = document.getElementById('trade-amount');
    if (amountEl) {
        amountEl.textContent = Math.floor(price * qty).toLocaleString();
    }
}

function setPercent(pct) {
    const price = parseFloat(document.getElementById('trade-price-input').value) || lastPrice;
    
    // 가용 자금 텍스트에서 숫자만 파싱해오거나 기본 가상 자금 세팅
    const availText = document.getElementById('avail-balance')?.textContent || "0";
    const avail = parseInt(availText.replace(/[^0-9]/g, '')) || 10000000; // 잔고 파싱 실패 시 1천만원 가드
    
    if (orderSide === 'buy' && price > 0) {
        document.getElementById('trade-qty').value = Math.floor((avail * pct / 100) / price);
        calcAmount();
    }
    
    // 비율 선택 완료 후 드롭다운 자동으로 닫아주기
    const menu = document.getElementById('pct-drop-menu');
    if (menu) menu.style.display = 'none';
}

function togglePctDrop() {
    const menu = document.getElementById('pct-drop-menu');
    if (!menu) return;
    
    if (menu.style.display === 'none' || menu.style.display === '') {
        menu.style.display = 'block';
    } else {
        menu.style.display = 'none';
    }
    
    // 외부 영역 클릭 시 드롭다운 닫히는 이벤트를 보장합니다.
    window.addEventListener('click', function closeMenu(e) {
        if (!e.target.closest('.pct-drop-wrap')) {
            menu.style.display = 'none';
            window.removeEventListener('click', closeMenu);
        }
    });
}

function submitOrder(side) {
    const qtyInput = document.getElementById('trade-qty');
    if (!qtyInput) {
        alert('수량 입력창을 찾을 수 없습니다.');
        return;
    }

    const orderCount = parseInt(qtyInput.value);
    if (!orderCount || orderCount <= 0) {
        alert('수량을 정확히 입력하세요.');
        return;
    }

    const priceInputEl = document.getElementById('trade-price-input');
    let priceInputValue = priceInputEl ? priceInputEl.value.trim() : "";
    // 🟢 [100% 방어] 화면의 '시장가' 버튼에 'sel' 또는 'active' 클래스가 붙어있는지 직접 검사하거나, 글씨를 체크합니다.
    const marketBtn = document.querySelector('.order-type-btn.sel') || document.querySelector('.tab-market.active');
    const isMarketBtnActive = marketBtn ? marketBtn.textContent.includes('시장가') : false;

    const isMarket = (!priceInputValue || priceInputValue === '시장가' || priceInputValue === '' || isMarketBtnActive);

    // 시장가면 전역 변수 lastPrice, 지정가면 인풋 박스의 숫자 파싱
    let orderPrice = isMarket ? lastPrice : parseInt(priceInputValue.replace(/[^0-9]/g, ''));

    // 🟢 최종 예외 가드: 혹시라도 지정가 파싱이 깨져서 NaN이 나오면 실시간 가격으로 구제
    if (isNaN(orderPrice) || orderPrice <= 0) {
        orderPrice = lastPrice;
    }

    if (!orderPrice || orderPrice <= 0) {
        alert('체결할 주식 가격이 모호합니다. 차트 로딩을 확인하세요.');
        return;
    }

    // 지정가 탭 여부 체크 보정
    const activeTabBtn = document.querySelector('.tab-btn.active');
    const isLimitTab = document.querySelector('.tab-limit')?.classList.contains('active')
        || (activeTabBtn && activeTabBtn.textContent.includes("지정가"))
        || !isMarket;

    // URL 파라미터로 보낼 매수/매도 대문자 텍스트 미리 추출
    const sideText = (side === 'buy' || side === 'BUY') ? 'BUY' : 'SELL';
    const sideKr = sideText === 'BUY' ? '매수' : '매도';

    // 🔴 [수정 포인트 2] 팀원 템플릿 호환용 필드(status, targetPrice) 추가 및 주식코드 가공
	const formatStockCode = (code) => {
	    return String(code).padStart(6, '0');
	};

	const orderData = {
	    orderType: sideText,
	    orderPrice: orderPrice,
	    orderCount: orderCount,
	    stockNo: parseInt(currentSymbol) || 0,
	    // 🟢 핵심: String 변환 후 padStart로 6자리 강제 고정 ("660" -> "000660")
	    stockCode: formatStockCode(currentSymbol), 
	    status: isLimitTab ? "PENDING" : "COMPLETED",   
	    targetPrice: isLimitTab ? orderPrice : 0         
	};

    if (!confirm(`[주문 접수]\n종목번호: ${currentSymbol}\n가격: ${orderPrice.toLocaleString()}원\n수량: ${orderCount}주\n\n정말 ${sideKr}하시겠습니까?`)) {
        return;
    }

    // 🔴 [수정 포인트 3] REST 컨트롤러 엔드포인트 맵핑 주소 싱크 맞추기 (/stock/order)
    fetch(`/stock/order?side=${sideText}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(orderData)
    })
        .then(response => {
            if (!response.ok) throw new Error("서버 응답 오류");
            return response.json();
        })
        .then(data => {
            if (data.success === true || data.success === "true") {
                alert(data.message);

                // 💰 체결 성공 즉시 우측 사이드바 자산 카드 실시간 리프레시!
                if (typeof loadMyInvestmentStatus === 'function') {
                    loadMyInvestmentStatus();
                }

                // 💳 하단 가용 잔고 영역 함께 리프레시
                if (typeof updateAccountBalanceUI === 'function') {
                    updateAccountBalanceUI();
                }
            } else {
                alert('주문 실패: ' + data.message);
            }
        })
        .catch(err => {
            console.error('통신 에러:', err);
            alert('주문 처리 중 서버 통신 에러가 발생했습니다.');
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
    loadMyInvestmentStatus();
});

window.addEventListener('resize', () => {
    if (window.innerWidth <= 1100) {
        ['panel-middle', 'panel-order-wrap', 'panel-hoga', 'panel-chart'].forEach(id => {
            const el = document.getElementById(id);
            if (el) { el.style.width = ''; el.style.height = ''; }
        });
    }
});

// ⏰ 3초 주기 실시간 데이터 갱신 타이머 실행
setInterval(() => {
    const activeBtn = document.querySelector('.chart-toolbar .tf-btn.active');
    let currentRange = '1y';

    if (activeBtn) {
        const onclickAttr = activeBtn.getAttribute('onclick');
        if (onclickAttr && onclickAttr.includes("'min'")) currentRange = 'min';
        else if (onclickAttr && onclickAttr.includes("'3y'")) currentRange = '3y';
        else if (onclickAttr && onclickAttr.includes("'10y'")) currentRange = '10y';
    }

    if (typeof fetchChart === 'function' && currentSymbol) {
        fetchChart(currentRange, null, true);
    }
}, 3000);

/* ── 12. 우측 사이드바 '내 투자현황' 3단 탭 통합 동적 렌더링 엔진 ── */
function loadMyInvestmentStatus() {
    // ─────────────────────────────────────────────────
    // [1단계] 보유 자산 카드 목록 렌더링 구역
    // ─────────────────────────────────────────────────
    fetch('/stock/holding-list')
        .then(response => response.json())
        .then(stocks => {
            const container = document.querySelector('#tab-stock-holdings .holding-cards');
            if (!container) return;

            container.innerHTML = '';

            if (!stocks || stocks.length === 0) {
                container.innerHTML = `
                    <div class="sb-empty">
                        <span class="sb-empty-icon">📊</span>
                        <span>보유 주식이 없습니다.</span>
                    </div>`;
                return;
            }

            stocks.forEach(stock => {
				const normalizedStock = Object.keys(stock).reduce((acc, key) => {
				        acc[key.toLowerCase()] = stock[key];
				        return acc;
				    }, {});

				    const count = normalizedStock.stock_count || 0;
				    const purchase = normalizedStock.stock_purchase || 0;
				    
				    // stock.js의 로직에 따라 stock_no 대신 asset_no를 사용하는 것이 DB 스키마상 정확합니다.
				    const stockNo = String(normalizedStock.asset_no || normalizedStock.stock_no || '').trim();
				    const stockName = normalizedStock.stock_name || "보유 종목"; 
				    
				    const logoText = stockName.slice(0, 2);
				    const logoBg = "#343a40";

                // 내가 지금 띄워놓은 종목 화면이면 실시간 시세(lastPrice) 반영, 타 종목이면 평단가 방어
                const currentPrice = (stockNo === currentSymbol || stockNo === "5930") ? lastPrice : purchase;
                const buyAmount = purchase * count;
                const evalAmount = currentPrice * count;
                const pnl = evalAmount - buyAmount;
                const pnlRate = buyAmount > 0 ? ((pnl / buyAmount) * 100).toFixed(2) : "0.00";

                let pnlClass = "";
                let pnlSign = "";
                if (pnl > 0) { pnlClass = "up"; pnlSign = "▲"; }
                else if (pnl < 0) { pnlClass = "down"; pnlSign = "▼"; }

                const html = `
                    <div class="holding-card hc-main">
                        <div class="hc-main-header">
                            <div class="hc-main-id">
                                <div class="hc-logo" style="background:${logoBg};">${logoText}</div>
                                <div class="hc-main-name-col">
                                    <span class="hc-main-ticker">${stockName}</span>
                                    <span class="hc-main-sub">${stockNo} | 현금 ${count}주</span>
                                </div>
                            </div>
                            <div class="hc-main-right">
                                <span class="hc-main-eval">${evalAmount.toLocaleString()} 원</span>
                                <span class="hc-main-pnl ${pnlClass}">${pnlSign}${Math.abs(pnl).toLocaleString()} (${pnlRate}%)</span>
                            </div>
                        </div>
                        <div class="hc-divider"></div>
                        <div class="hc-main-grid">
                            <div class="hc-main-row">
                                <span class="hc-label">매수금액</span>
                                <span class="hc-value">${buyAmount.toLocaleString()} 원</span>
                            </div>
                            <div class="hc-main-row">
                                <span class="hc-label">평균단가</span>
                                <span class="hc-value">${purchase.toLocaleString()} 원</span>
                            </div>
                            <div class="hc-main-row">
                                <span class="hc-label">평가금액</span>
                                <span class="hc-value">${evalAmount.toLocaleString()} 원</span>
                            </div>
                            <div class="hc-main-row">
                                <span class="hc-label">현재가</span>
                                <span class="hc-value">${currentPrice.toLocaleString()} 원</span>
                            </div>
                        </div>
                    </div>`;
                container.insertAdjacentHTML('beforeend', html);
            });
        })
        .catch(err => console.error('자산 사이드바 로드 에러:', err));

    // ─────────────────────────────────────────────────
    // [2단계] 미체결 지정가 예약 오더 목록 렌더링 구역
    // ─────────────────────────────────────────────────
    fetch('/stock/pending-list') // 💡 백엔드에 매핑할 미체결 리스트 API 주소
        .then(response => response.json())
        .then(orders => {
            const emptyEl = document.querySelector('#tab-stock-orders .sb-empty');
            const tableEl = document.querySelector('#tab-stock-orders .sb-table');
            const tbody = document.getElementById('stock-pending-body');
            
            if (!tbody) return;

            if (!orders || orders.length === 0) {
                if (emptyEl) emptyEl.style.display = 'flex';
                if (tableEl) tableEl.style.display = 'none';
                return;
            }

            if (emptyEl) emptyEl.style.display = 'none';
            if (tableEl) tableEl.style.display = 'table';
            
            tbody.innerHTML = orders.map(order => {
                const sideCls = order.ORDER_TYPE === 'BUY' ? 'up' : 'down';
                const sideText = order.ORDER_TYPE === 'BUY' ? '매수' : '매도';
                return `
                    <tr>
                        <td><b>${order.STOCK_NAME || '주식'}</b></td>
                        <td class="${sideCls}">${sideText}</td>
                        <td>${Math.floor(order.ORDER_PRICE).toLocaleString()}원</td>
                        <td>${order.ORDER_COUNT}주</td>
                        <td>
                            <button class="wl-sort-btn" style="color:#F04452; padding:2px 6px;" 
                                    onclick="cancelStockOrder(${order.ORDER_ID})">취소</button>
                        </td>
                    </tr>`;
            }).join('');
        }).catch(e => console.warn("미체결 내역 파이프 통신 공백"));

    // ─────────────────────────────────────────────────
    // [3단계] 거래 내역 히스토리 로그 렌더링 구역
    // ─────────────────────────────────────────────────
    fetch('/stock/history-list') // 💡 백엔드에 매핑할 거래내역 API 주소
        .then(response => response.json())
        .then(history => {
            const emptyEl = document.querySelector('#tab-stock-history .sb-empty');
            const tableEl = document.querySelector('#tab-stock-history .sb-table');
            const tbody = document.getElementById('stock-history-body');

            if (!tbody) return;

            if (!history || history.length === 0) {
                if (emptyEl) emptyEl.style.display = 'flex';
                if (tableEl) tableEl.style.display = 'none';
                return;
            }

            if (emptyEl) emptyEl.style.display = 'none';
            if (tableEl) tableEl.style.display = 'table';

            tbody.innerHTML = history.map(h => {
                const sideCls = h.ORDER_TYPE === 'BUY' ? 'up' : 'down';
                const sideText = h.ORDER_TYPE === 'BUY' ? '매수' : '매도';
                const total = Math.floor(h.ORDER_PRICE * h.ORDER_COUNT);
                const date = new Date(h.ORDER_DATE).toLocaleDateString('ko-KR', {month:'short', day:'numeric', hour:'2-digit', minute:'2-digit'});
                return `
                    <tr>
                        <td style="font-size:11px; color:var(--text3);">${date}</td>
                        <td class="${sideCls}">${sideText}</td>
                        <td>${h.STOCK_NAME || '주식'}</td>
                        <td>${Math.floor(h.ORDER_PRICE).toLocaleString()}원</td>
                        <td>${h.ORDER_COUNT}주</td>
                        <td><b>${total.toLocaleString()}원</b></td>
                    </tr>`;
            }).join('');
        }).catch(e => console.warn("거래내역 파이프 통신 공백"));
}

/* ── 12-2. 미체결 주문 즉시 취소 함수 브릿지 ── */
function cancelStockOrder(orderId) {
    if (!confirm("해당 지정가 예약 주문을 취소하시겠습니까?")) return;
    
    fetch(`/stock/cancel-order?orderNo=${orderId}`, { method: 'POST' })
        .then(r => r.json())
        .then(data => {
            alert("주문이 정상적으로 취소되었습니다.");
            loadMyInvestmentStatus(); // 사이드바 즉시 리프레시
            if (typeof updateAccountBalanceUI === 'function') updateAccountBalanceUI(); // 예수금 복구 리프레시
        }).catch(err => alert("주문 취소 처리 중 오류 발생"));
}

function updateAccountBalanceUI() {
    fetch('/stock/account-balance')
        .then(response => response.json())
        .then(data => {
            // JSP에 적힌 #avail-balance 엘리먼트를 정확하게 타격합니다.
            const balanceEl = document.getElementById('ph-user-balance') || document.querySelector('.user-cash-val');
            const tradeAvailEl = document.getElementById('avail-balance'); 

            if (data && data.balance !== undefined) {
                const formattedBalance = Math.floor(data.balance).toLocaleString() + ' 원';

                if (balanceEl) balanceEl.textContent = formattedBalance;
                if (tradeAvailEl) tradeAvailEl.textContent = formattedBalance;
            }
        })
        .catch(err => console.error('💳 잔고 UI 업데이트 실패:', err));
}

// DOM 로딩이 완료되었을 때 잔고 엔진도 같이 시동 걸기
document.addEventListener('DOMContentLoaded', () => {
    updateAccountBalanceUI();
});

/* ── 15. DB 통신 없는 프론트엔드 전용 실시간 자산 재계산 엔진 ── */
function updateSidebarRealtimeUI() {
    // 우측 사이드바에 떠 있는 주식 카드들을 전부 탐색합니다.
    const cards = document.querySelectorAll('#tab-stock-holdings .holding-card');
    if (!cards || cards.length === 0) return;

    cards.forEach(card => {
        const tickerEl = card.querySelector('.hc-main-ticker');
        if (!tickerEl) return;

        // 현재 화면에서 보고 있는 종목(예: 삼성전자) 카드만 실시간 변동 타격!
        const stockName = tickerEl.textContent.trim();
        const displayTitle = document.getElementById('displayTitle')?.innerText.trim() || "";

        if (stockName === displayTitle || stockName === "삼성전자") {
            // 1. 기존 카드에 적혀있는 서브 텍스트에서 수량(숫자)만 정규식으로 추출
            const subText = card.querySelector('.hc-main-sub')?.textContent || ""; // 예: "5930 | 현금 2주"
            const countMatch = subText.match(/(\d+)주/);
            if (!countMatch) return;
            const count = parseInt(countMatch[1]); // 2주 획득

            // 2. 카드 내부에 적혀있는 매수금액 추출 (숫자만 남기기)
            const buyAmountText = card.querySelectorAll('.hc-main-grid .hc-value')[0]?.textContent || "0";
            const buyAmount = parseInt(buyAmountText.replace(/[^0-9]/g, '')) || 0;

            // 3. 평균단가 추출
            const purchaseText = card.querySelectorAll('.hc-main-grid .hc-value')[1]?.textContent || "0";
            const purchase = parseInt(purchaseText.replace(/[^0-9]/g, '')) || 0;

            // 4. 실시간 변동 가격(lastPrice)을 반영하여 평가금액 및 수익률 연산 실행
            const evalAmount = lastPrice * count;
            const pnl = evalAmount - buyAmount;
            const pnlRate = buyAmount > 0 ? ((pnl / buyAmount) * 100).toFixed(2) : "0.00";

            let pnlClass = "";
            let pnlSign = "";
            if (pnl > 0) { pnlClass = "up"; pnlSign = "▲"; }
            else if (pnl < 0) { pnlClass = "down"; pnlSign = "▼"; }

            // 5. DOM 엘리먼트 실시간 텍스트 및 클래스 전격 교체 (깜빡임 없음)
            const mainEvalEl = card.querySelector('.hc-main-eval');
            if (mainEvalEl) mainEvalEl.textContent = evalAmount.toLocaleString() + ' 원';

            const mainPnlEl = card.querySelector('.hc-main-pnl');
            if (mainPnlEl) {
                mainPnlEl.textContent = `${pnlSign}${Math.abs(pnl).toLocaleString()} (${pnlRate}%)`;
                mainPnlEl.className = `hc-main-pnl ${pnlClass}`;
            }

            // 하단 세부 그리드 영역 영역 매핑 갱신 (평가금액 / 현재가 라벨)
            const gridValues = card.querySelectorAll('.hc-main-grid .hc-value');
            if (gridValues && gridValues.length >= 4) {
                gridValues[2].textContent = evalAmount.toLocaleString() + ' 원'; // 평가금액 갱신
                gridValues[3].textContent = lastPrice.toLocaleString() + ' 원';  // 현재가 실시간 동기화
            }
        }
    });
}

