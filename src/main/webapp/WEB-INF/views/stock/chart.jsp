<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>TradeBot · 주식 차트</title>
    <script src="https://unpkg.com/lightweight-charts@5.2.0/dist/lightweight-charts.standalone.production.js"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/chart-toss-coin.css">
    <link rel="stylesheet" href="/css/chart-stock.css">
</head>

<body class="chart-page" data-sidebar-tab="invest">

<div class="app-wrapper">

    <div class="page">
        <%@ include file="../common/nav.jsp" %>

        <div class="price-header">
            <div class="ph-left">
                <div class="ph-name-row">
                    <span class="ph-name" id="displayTitle">삼성전자</span>
                    <span class="ph-ticker" id="displayCode">(005930)</span>
                </div>
                <div class="ph-price-row">
                    <span class="ph-price" id="ph-price">-</span>
                    <span style="width:1px;height:16px;background:var(--border2);margin:0 6px;flex-shrink:0;align-self:center;"></span>
                    <span style="font-size:13px;color:var(--text3);font-weight:500;line-height:1;">전일대비</span>
                    <span class="ph-change" id="ph-change-abs">-</span>
                    <span class="ph-change" id="ph-change">-</span>
                </div>
            </div>

            <div class="ph-right">
                <div class="ph-group">
                    <div class="ph-item">
                        <span class="ph-label">시가</span>
                        <span class="ph-value" id="ph-open">-</span>
                    </div>
                    <div class="ph-item">
                        <span class="ph-label">전일종가</span>
                        <span class="ph-value" id="ph-prev">-</span>
                    </div>
                </div>
                <div class="ph-vdivider"></div>
                <div class="ph-group">
                    <div class="ph-item">
                        <span class="ph-label">고가</span>
                        <span class="ph-value up" id="ph-high">-</span>
                    </div>
                    <div class="ph-item">
                        <span class="ph-label">저가</span>
                        <span class="ph-value down" id="ph-low">-</span>
                    </div>
                </div>
                <div class="ph-vdivider"></div>
                <div class="ph-group">
                    <div class="ph-item">
                        <span class="ph-label">거래량</span>
                        <span class="ph-value" id="ph-vol">-</span>
                    </div>
                    <div class="ph-item">
                        <span class="ph-label">거래대금</span>
                        <span class="ph-value" id="ph-turnover">-</span>
                    </div>
                </div>
            </div>

            <div class="ph-actions">
                <input type="text" id="symbolInput" placeholder="종목명 또는 코드">
                <button onclick="searchStock()" class="nav-login-btn">조회</button>
            </div>
        </div>

        <div class="main-layout">

            <!-- ① 차트 패널 -->
            <div class="card panel-chart" id="panel-chart">
                <div class="chart-toolbar">
                    <button class="tf-btn active" data-tf onclick="fetchChart('min',this)">1분</button>
                    <button class="tf-btn" data-tf onclick="fetchChart('1y',this)">1D</button>
                    <button class="tf-btn" data-tf onclick="fetchChart('3y',this)">1W</button>
                    <button class="tf-btn" data-tf onclick="fetchChart('10y',this)">1M</button>

                    <div class="tb-divider"></div>

                    <button class="ind-btn" id="ind-ma5" onclick="toggleInd('ma5')">MA5</button>
                    <button class="ind-btn" id="ind-ma20" onclick="toggleInd('ma20')">MA20</button>

                    <div class="tb-divider"></div>

                    <div class="settings-wrap">
                        <button class="ind-btn" onclick="toggleSettingsMenu()">
                            <span style="font-size:24px;">⚙</span>
                        </button>
                        <div class="settings-menu" id="settings-menu">
                            <div class="settings-title">차트 설정</div>
                            <label class="settings-item">
                                <span class="settings-label"><span>최고 최저 가격</span></span>
                                <input type="checkbox" id="set-highlow" checked onchange="toggleHighLow(this.checked)">
                            </label>
                            <label class="settings-item">
                                <span class="settings-label">
                                    <span>로그 스케일</span>
                                    <small>변화율 기준으로 차트 보기</small>
                                </span>
                                <input type="checkbox" id="set-log" onchange="toggleLog()">
                            </label>
                        </div>
                    </div>
                </div>

                <div id="chart-wrapper">
                    <div id="hl-high" style="position:absolute;display:none;flex-direction:column;align-items:center;pointer-events:none;z-index:10;transform:translateX(-50%);">
                        <span id="hl-high-val" style="font-size:12px;color:var(--up);white-space:nowrap;"></span>
                        <span style="color:var(--up);font-size:12px;display:block;transform:rotate(90deg);line-height:1;">⇒</span>
                    </div>
                    <div id="hl-low" style="position:absolute;display:none;flex-direction:column;align-items:center;pointer-events:none;z-index:10;transform:translateX(-50%);">
                        <span style="color:var(--down);font-size:12px;display:block;transform:rotate(-90deg);line-height:1;">⇒</span>
                        <span id="hl-low-val" style="font-size:12px;color:var(--down);white-space:nowrap;"></span>
                    </div>
                    <div id="chart-container">
                        <div id="ohlc-bar">
                            <span>O: <b id="val-o">-</b></span>&nbsp;
                            <span>H: <b id="val-h">-</b></span>&nbsp;
                            <span>L: <b id="val-l">-</b></span>&nbsp;
                            <span>C: <b id="val-c">-</b></span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="resize-h" id="rh-1"></div>

            <!-- ② 주문/호가 패널 -->
            <div class="panel-middle" id="panel-middle">
                <div class="card panel-order-wrap" id="panel-order-wrap">
                    <div class="order-tabs">
                        <div class="order-tab buy active" id="tab-buy" onclick="switchOrderTab('buy')">매수</div>
                        <div class="order-tab sell" id="tab-sell" onclick="switchOrderTab('sell')">매도</div>
                    </div>
                    <div class="order-panel" id="panel-order">
                        <div class="order-type-row">
                            <button class="order-type-btn sel" onclick="selectOrderType(this)">지정가</button>
                            <button class="order-type-btn" onclick="selectOrderType(this)">시장가</button>
                        </div>
                        <div class="order-section-label">가격 (원)</div>
                        <div class="order-input-row">
                            <input class="order-input" id="trade-price-input" type="number" placeholder="가격 입력" oninput="calcAmount()">
                            <span class="order-input-unit">원</span>
                        </div>
                        <div class="order-section-label">수량 (주)</div>
                        <div class="order-input-row">
                            <input class="order-input" id="trade-qty" type="number" placeholder="0" step="1" oninput="calcAmount()">
                            <span class="order-input-unit">주</span>
                        </div>
                        <div class="pct-row">
                            <button class="pct-btn" onclick="setPercent(25)">25%</button>
                            <button class="pct-btn" onclick="setPercent(50)">50%</button>
                            <button class="pct-btn" onclick="setPercent(75)">75%</button>
                            <button class="pct-btn" onclick="setPercent(100)">최대</button>
                        </div>
                        <div class="order-section-label">주문금액 (원)</div>
                        <div class="order-input-row" style="margin-bottom:14px">
                            <input class="order-input" id="trade-amount" type="number" readonly style="background:var(--surface2)">
                            <span class="order-input-unit">원</span>
                        </div>
                        <div class="order-avail">가용 잔고 <span id="avail-balance">- 원</span></div>
                        <button id="order-submit-btn" class="btn-buy" onclick="submitOrder(orderSide)">매수 주문</button>
                    </div>
                </div>

                <div class="resize-v" id="rh-v"></div>

                <div class="card panel-hoga" id="panel-hoga">
                    <div class="hoga-header-row">
                        <span>호가</span>
                        <span>수량(주)</span>
                        <span>총량</span>
                    </div>
                    <div class="hoga-body">
                        <div class="hoga-top">
                            <table class="hoga-table">
                                <tbody id="hoga-asks">
                                    <tr class="hoga-skel"><td class="hoga-ask">--,---</td><td>---</td><td>---</td></tr>
                                    <tr class="hoga-skel"><td class="hoga-ask">--,---</td><td>---</td><td>---</td></tr>
                                    <tr class="hoga-skel"><td class="hoga-ask">--,---</td><td>---</td><td>---</td></tr>
                                    <tr class="hoga-skel"><td class="hoga-ask">--,---</td><td>---</td><td>---</td></tr>
                                    <tr class="hoga-skel"><td class="hoga-ask">--,---</td><td>---</td><td>---</td></tr>
                                </tbody>
                            </table>
                        </div>
                        <div class="hoga-mid" id="hoga-mid">
                            <span id="hoga-cur-price">-</span>
                            <span class="hoga-mid-change" id="hoga-cur-change"></span>
                        </div>
                        <div class="hoga-bot">
                            <table class="hoga-table">
                                <tbody id="hoga-bids">
                                    <tr class="hoga-skel"><td class="hoga-bid">--,---</td><td>---</td><td>---</td></tr>
                                    <tr class="hoga-skel"><td class="hoga-bid">--,---</td><td>---</td><td>---</td></tr>
                                    <tr class="hoga-skel"><td class="hoga-bid">--,---</td><td>---</td><td>---</td></tr>
                                    <tr class="hoga-skel"><td class="hoga-bid">--,---</td><td>---</td><td>---</td></tr>
                                    <tr class="hoga-skel"><td class="hoga-bid">--,---</td><td>---</td><td>---</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <div class="resize-h" id="rh-2"></div>

            <!-- ③ 댓글 패널 -->
            <div class="card panel-chat" id="panel-chat">
                <div class="panel-title">실시간 댓글</div>
                <div class="chat-messages" id="chat-messages">
                    <div class="chat-empty">
                        <span class="chat-empty-icon">💬</span>
                        <span>첫 댓글을 남겨보세요</span>
                    </div>
                </div>
                <div class="chat-input-wrap">
                    <input type="text" class="chat-input" id="chat-input" placeholder="댓글 입력...">
                    <button class="chat-send-btn" onclick="sendChat()">전송</button>
                </div>
            </div>

        </div><!-- /.main-layout -->

        <div class="ticker-bar">
            <div class="ticker-track" id="ticker-track"></div>
        </div>

    </div><!-- /.page -->

    <%@ include file="../common/sidebar.jsp" %>
    <%@ include file="../common/sidebar-icons.jsp" %>

</div><!-- /.app-wrapper -->

<script>
    /* ── 전역 상태 ── */
    let chart, candlestickSeries, volumeSeries, ma5Series, ma20Series;
    let currentSymbol = '005930';
    let lastPrice = 0;
    let orderSide = 'buy';
    let showHighLow = true;
    let isLog = false;
    const indState = { ma5: false, ma20: false };

    /* ── 종목 검색 ── */
    function searchStock() {
        const input = document.getElementById('symbolInput').value.trim();
        if (!input) { alert('종목명 또는 코드를 입력하세요.'); return; }
        currentSymbol = input;
        fetchChart('1y');
    }

    document.getElementById('symbolInput').addEventListener('keypress', e => {
        if (e.key === 'Enter') searchStock();
    });

    /* ── MA 계산 ── */
    function calculateMA(data, period) {
        return data.reduce((acc, d, i) => {
            if (i >= period - 1) {
                const sum = data.slice(i - period + 1, i + 1).reduce((s, c) => s + c.close, 0);
                acc.push({ time: d.time, value: sum / period });
            }
            return acc;
        }, []);
    }

    /* ── 차트 데이터 로드 ── */
    function fetchChart(range, btnEl) {
        document.querySelectorAll('.tf-btn[data-tf]').forEach(b => b.classList.remove('active'));
        if (btnEl) btnEl.classList.add('active');

        fetch('/stock/chart?code=' + encodeURIComponent(currentSymbol) + '&range=' + range)
            .then(r => r.json())
            .then(data => {
                if (data.stockName) document.getElementById('displayTitle').innerText = data.stockName;
                if (data.stockCode) {
                    document.getElementById('displayCode').innerText = '(' + data.stockCode + ')';
                    currentSymbol = data.stockCode;
                }
                currentSymbol = data.stockCode || currentSymbol;

                const candles = data.output2.map(d => {
                    const r = d.stck_bsop_date;
                    return {
                        time: r.substring(0,4) + '-' + r.substring(4,6) + '-' + r.substring(6,8),
                        open:   parseFloat(d.stck_oprc),
                        high:   parseFloat(d.stck_hgpr),
                        low:    parseFloat(d.stck_lwpr),
                        close:  parseFloat(d.stck_clpr),
                        volume: parseFloat(d.acml_vol)
                    };
                }).sort((a, b) => a.time > b.time ? 1 : -1);

                candlestickSeries.setData(candles);
                volumeSeries.setData(candles.map(c => ({
                    time: c.time, value: c.volume,
                    color: c.close >= c.open ? 'rgba(240,68,82,0.44)' : 'rgba(37,99,235,0.44)'
                })));
                ma5Series.setData(calculateMA(candles, 5));
                ma20Series.setData(calculateMA(candles, 20));
                chart.timeScale().fitContent();

                /* price header 업데이트 */
                const last = candles[candles.length - 1];
                const prev = candles.length > 1 ? candles[candles.length - 2].close : last.close;
                lastPrice = last.close;
                updatePriceHeader(last, prev);
                renderMockHoga(last.close);
            })
            .catch(err => { console.error(err); alert('데이터 로드 중 오류가 발생했습니다.'); });
    }

    function updatePriceHeader(last, prev) {
        document.getElementById('ph-price').textContent = last.close.toLocaleString();
        const abs = last.close - prev;
        const pct = prev > 0 ? (abs / prev * 100) : 0;
        const cls = abs >= 0 ? 'up' : 'down';
        const sign = abs >= 0 ? '+' : '';
        const absEl = document.getElementById('ph-change-abs');
        absEl.textContent = sign + abs.toLocaleString() + '원';
        absEl.className = 'ph-change ' + cls;
        const pctEl = document.getElementById('ph-change');
        pctEl.textContent = '(' + sign + pct.toFixed(2) + '%)';
        pctEl.className = 'ph-change ' + cls;
        document.getElementById('ph-open').textContent = last.open.toLocaleString();
        document.getElementById('ph-high').textContent = last.high.toLocaleString();
        document.getElementById('ph-low').textContent  = last.low.toLocaleString();
        document.getElementById('ph-vol').textContent  = last.volume.toLocaleString() + '주';
    }

    /* ── 차트 초기화 ── */
    document.addEventListener('DOMContentLoaded', function () {
        const _chartBg = getComputedStyle(document.documentElement).getPropertyValue('--chart-bg').trim() || '#16161A';
        const container = document.getElementById('chart-container');

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

        /* OHLC 바 크로스헤어 연동 */
        chart.subscribeCrosshairMove(param => {
            if (!param.time) return;
            const c = param.seriesData.get(candlestickSeries);
            if (!c) return;
            document.getElementById('val-o').textContent = c.open.toLocaleString();
            document.getElementById('val-h').textContent = c.high.toLocaleString();
            document.getElementById('val-l').textContent = c.low.toLocaleString();
            document.getElementById('val-c').textContent = c.close.toLocaleString();
        });

        /* 최고/최저 마커 */
        const chartWrapper = document.getElementById('chart-wrapper');
        chartWrapper.addEventListener('mousemove', updateHighLow);
        chart.timeScale().subscribeVisibleLogicalRangeChange(updateHighLow);

        fetchChart('1y');
    });

    /* ── 지표 토글 ── */
    function toggleInd(name) {
        indState[name] = !indState[name];
        const on = indState[name];
        const colors = { ma5: '#FF9800', ma20: '#3182F6' };
        const btn = document.getElementById('ind-' + name);
        if (on) {
            btn.style.borderColor = colors[name];
            btn.style.color = colors[name];
            btn.style.background = colors[name] + '18';
        } else {
            btn.style.borderColor = '';
            btn.style.color = '';
            btn.style.background = '';
        }
        if (name === 'ma5')  ma5Series.applyOptions({ visible: on });
        if (name === 'ma20') ma20Series.applyOptions({ visible: on });
    }

    /* ── 설정 메뉴 ── */
    function toggleSettingsMenu() {
        event.stopPropagation();
        document.getElementById('settings-menu').classList.toggle('open');
    }
    document.addEventListener('click', e => {
        if (!e.target.closest('.settings-wrap'))
            document.getElementById('settings-menu').classList.remove('open');
    });

    function toggleLog() {
        isLog = !isLog;
        chart.priceScale('right').applyOptions({ mode: isLog ? 1 : 0 });
    }

    /* ── 최고/최저 마커 ── */
    let allCandles = [];
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
        if (hX != null && hY != null) {
            hEl.style.display = 'flex';
            hEl.style.left = hX + 'px';
            hEl.style.top  = (hY - 48) + 'px';
            document.getElementById('hl-high-val').textContent = hV.toLocaleString() + '원';
        }
        if (lX != null && lY != null) {
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

    /* ── 주문창 ── */
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
        const avail = 1000000; /* 잔고 연동 시 교체 */
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

    /* ── 호가창 (목업) ── */
    function renderMockHoga(basePrice) {
        const maxQty = 50000;
        const asks = [], bids = [];
        for (let i = 5; i >= 1; i--) {
            const qty = Math.floor(Math.random() * maxQty) + 1000;
            let total = 0;
            asks.push({ price: basePrice + i * 100, qty });
        }
        for (let i = 1; i <= 5; i++) {
            const qty = Math.floor(Math.random() * maxQty) + 1000;
            bids.push({ price: basePrice - i * 100, qty });
        }

        let askCumul = 0;
        const askMax = asks.reduce((s, r) => s + r.qty, 0);
        document.getElementById('hoga-asks').innerHTML = asks.map(r => {
            askCumul += r.qty;
            const pct = (askCumul / askMax * 100).toFixed(1);
            return `<tr style="background:linear-gradient(to left,rgba(37,99,235,0.12) ${pct}%,transparent ${pct}%)">
                <td class="hoga-ask">${r.price.toLocaleString()}</td>
                <td>${r.qty.toLocaleString()}</td>
                <td>${askCumul.toLocaleString()}</td>
            </tr>`;
        }).join('');

        let bidCumul = 0;
        const bidMax = bids.reduce((s, r) => s + r.qty, 0);
        document.getElementById('hoga-bids').innerHTML = bids.map(r => {
            bidCumul += r.qty;
            const pct = (bidCumul / bidMax * 100).toFixed(1);
            return `<tr style="background:linear-gradient(to left,rgba(240,68,82,0.12) ${pct}%,transparent ${pct}%)">
                <td class="hoga-bid">${r.price.toLocaleString()}</td>
                <td>${r.qty.toLocaleString()}</td>
                <td>${bidCumul.toLocaleString()}</td>
            </tr>`;
        }).join('');

        document.getElementById('hoga-cur-price').textContent = basePrice.toLocaleString() + '원';
    }

    /* ── 댓글창 ── */
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

    document.getElementById('chat-input').addEventListener('keydown', e => {
        if (e.key === 'Enter') sendChat();
    });

    /* ── 패널 리사이즈 ── */
    function makeHResizer(handleId, rightPanelId, minW, maxW) {
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

    makeHResizer('rh-1', 'panel-middle', 340, 340);
    makeHResizer('rh-2', 'panel-chat', 270, 380);
    makeVResizer('rh-v', 'panel-order-wrap', 'panel-hoga');

    window.addEventListener('resize', () => {
        if (window.innerWidth <= 1100) {
            ['panel-middle','panel-order-wrap','panel-hoga','panel-chart'].forEach(id => {
                const el = document.getElementById(id);
                if (el) { el.style.width = ''; el.style.height = ''; }
            });
        }
    });
</script>

<script src="/js/common.js"></script>
</body>
</html>
