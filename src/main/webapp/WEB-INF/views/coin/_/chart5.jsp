<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>

<head>
    <title>TradingView 전문 차트</title>
    <script src="https://unpkg.com/lightweight-charts@4.1.1/dist/lightweight-charts.standalone.production.js"></script>
    <style>
body {
	margin: 0;
	padding: 20px;
	font-family: sans-serif;
}
/* 3. 차트가 그려질 영역의 크기와 테두리를 설정합니다. */
#chart-container {
	width: 100%;
	height: 500px;
	border: 1px solid #eee;
	position: relative;
}
</style>
</head>

<body>
    <div style="display:flex; gap:0; height:100vh; margin:0; padding:0;">

        <!-- 왼쪽: 차트 영역 -->
        <div style="flex:1; display:flex; flex-direction:column; padding:10px;">
            <h3 style="margin:0 0 8px 0">BTC/USDT</h3>
            <div id="tf-buttons">
                <button onclick="changeTimeframe('1')">1분</button>
                <button onclick="changeTimeframe('3')">3분</button>
                <button onclick="changeTimeframe('5')">5분</button>
                <button onclick="changeTimeframe('10')">10분</button>
                <button onclick="changeTimeframe('15')">15분</button>
                <button onclick="changeTimeframe('30')">30분</button>
                <button onclick="changeTimeframe('60')">1시간</button>
                <button id="log-btn" onclick="toggleLog()">로그차트</button>
            </div>
            <div id="chart-container" style="flex:1; position:relative; border:1px solid #eee;">
                <div id="ohlc-bar" style="position:absolute; top:8px; left:10px; z-index:10;
                font-size:13px; background:rgba(255,255,255,0.85); padding:4px 8px; border-radius:4px;">
                    <span>O: <b id="val-o">-</b></span>&nbsp;
                    <span style="color:red">H: <b id="val-h">-</b></span>&nbsp;
                    <span style="color:#007aff">L: <b id="val-l">-</b></span>&nbsp;
                    <span>C: <b id="val-c">-</b></span>
                </div>
            </div>
        </div>

        <!-- 오른쪽: 거래 패널 (항상 표시) -->
        <div
            style="width:280px; border-left:1px solid #ddd; padding:20px; background:#fafafa; display:flex; flex-direction:column; gap:12px;">
            <h3 style="margin:0">BTC/USDT 거래</h3>
            <div style="font-size:14px">현재가: <b id="trade-price" style="font-size:18px; color:#ff3b30">-</b> USDT</div>
            <hr style="margin:0">

            <!-- 매수/매도 탭 -->
            <div style="display:flex; gap:4px;">
                <button id="btn-buy" onclick="setOrder('buy')"
                    style="flex:1; padding:10px; background:#ff3b30; color:#fff; border:none; border-radius:4px; cursor:pointer; font-size:14px;">매수</button>
                <button id="btn-sell" onclick="setOrder('sell')"
                    style="flex:1; padding:10px; background:#007aff; color:#fff; border:none; border-radius:4px; cursor:pointer; font-size:14px;">매도</button>
            </div>

            <!-- 주문 유형 -->
            <select style="width:100%; padding:8px; border:1px solid #ddd; border-radius:4px;">
                <option>지정가</option>
                <option>시장가</option>
            </select>

            <!-- 수량 -->
            <label style="font-size:13px; color:#666">수량 (BTC)
                <input id="trade-qty" type="number" placeholder="0.001" step="0.001" oninput="calcAmount()"
                    style="width:100%; padding:8px; margin-top:4px; border:1px solid #ddd; border-radius:4px; box-sizing:border-box;">
            </label>

            <!-- 비율 버튼 -->
            <div style="display:flex; gap:4px;">
                <button onclick="setPercent(10)"
                    style="flex:1; padding:6px; font-size:12px; cursor:pointer">10%</button>
                <button onclick="setPercent(25)"
                    style="flex:1; padding:6px; font-size:12px; cursor:pointer">25%</button>
                <button onclick="setPercent(50)"
                    style="flex:1; padding:6px; font-size:12px; cursor:pointer">50%</button>
                <button onclick="setPercent(100)"
                    style="flex:1; padding:6px; font-size:12px; cursor:pointer">최대</button>
            </div>

            <!-- 주문금액 -->
            <label style="font-size:13px; color:#666">주문금액 (USDT)
                <input id="trade-amount" type="number" readonly
                    style="width:100%; padding:8px; margin-top:4px; border:1px solid #ddd; border-radius:4px; background:#f5f5f5; box-sizing:border-box;">
            </label>

            <!-- 주문 버튼 -->
            <button id="order-btn" onclick="submitOrder()"
                style="width:100%; padding:14px; font-size:16px; background:#ff3b30; color:#fff; border:none; border-radius:4px; cursor:pointer; margin-top:auto;">
                매수 주문
            </button>
        </div>

    </div>


    <script>
        var token = '${token}';
        let currentGranularity = '1';
        let currentSymbol = '005930';
        let currentWs = null;

        const TF_MAP = {
            '1': { label: '1분' },
            '3': { label: '3분' },
            '5': { label: '5분' },
            '10': { label: '10분' },
            '15': { label: '15분' },
            '30': { label: '30분' },
            '60': { label: '1시간' },
        };

        let isLog = false;
        function toggleLog() {
            isLog = !isLog;
            chart.priceScale('right').applyOptions({ mode: isLog ? 1 : 0 });
            document.getElementById('log-btn').style.fontWeight = isLog ? 'bold' : 'normal';
        }
        // --- [A] 차트 초기화 단계 ---
        const container = document.getElementById('chart-container');
        const chart = LightweightCharts.createChart(container, {
            width: container.clientWidth, // 컨테이너 너비에 맞춤
            height: 500,
            layout: { background: { color: '#ffffff' }, textColor: '#333' }, // 배경색 및 글자색
            grid: {
                vertLines: { color: '#f0f0f0' }, // 세로 격자선
                horzLines: { color: '#f0f0f0' }  // 가로 격자선
            },
        });

        // --- [B] 시리즈(데이터 줄기) 생성 단계 ---
        // 5. 캔들스틱(봉차트) 설정: 한국식 빨강(상승)/파랑(하락) 컬러 적용
        const candleSeries = chart.addCandlestickSeries({
            upColor: '#ff3b30', downColor: '#007aff',
            borderDownColor: '#007aff', borderUpColor: '#ff3b30',
            wickDownColor: '#007aff', wickUpColor: '#ff3b30',
        });

        // 6. 이동평균선(MA 20) 설정: 선의 색상과 굵기를 정의
        const ma20Series = chart.addLineSeries({
            color: '#2196F3',
            lineWidth: 2,
            title: 'MA 20',
        });
        const ma5Series = chart.addLineSeries({
            color: '#FF9800', lineWidth: 1, title: 'MA 5',
        });

        const volumeSeries = chart.addHistogramSeries({
            priceFormat: { type: 'volume' },
            priceScaleId: 'volume',
        });
        chart.priceScale('volume').applyOptions({
            scaleMargins: { top: 0.8, bottom: 0 },
        });

        // --- [C] 데이터 로드 및 가공 단계 ---
        async function loadData() {
            const res = await fetch('/coin/kisdata?symbol=' + currentSymbol + '&interval=' + currentGranularity)
                .then(r => r.json());

            if (res.output2 && res.output2.length > 0) {
                const data = res.output2.reverse().map(item => {
                    const dateStr = item.stck_bsop_date; // 20260512
                    const timeStr = item.stck_cntg_hour; // 093000
                    const dt = new Date(
                        dateStr.slice(0, 4), dateStr.slice(4, 6) - 1, dateStr.slice(6, 8),
                        timeStr.slice(0, 2), timeStr.slice(2, 4), timeStr.slice(4, 6)
                    );
                    return {
                        time: Math.floor(dt.getTime() / 1000),
                        open: parseFloat(item.stck_oprc),
                        high: parseFloat(item.stck_hgpr),
                        low: parseFloat(item.stck_lwpr),
                        close: parseFloat(item.stck_prpr),
                        volume: parseFloat(item.cntg_vol)
                    };
                });

                candleSeries.setData(data);

                const ma5Data = [];
                data.forEach((d, i) => {
                    if (i < 5) return;
                    const avg = data.slice(i - 5, i).reduce((s, c) => s + c.close, 0) / 5;
                    ma5Data.push({ time: d.time, value: avg });
                });
                ma5Series.setData(ma5Data);

                const maData = [];
                data.forEach((d, i) => {
                    if (i < 20) return;
                    const avg = data.slice(i - 20, i).reduce((s, c) => s + c.close, 0) / 20;
                    maData.push({ time: d.time, value: avg });
                });
                ma20Series.setData(maData);

                const volData = data.map(d => ({
                    time: d.time,
                    value: d.volume,
                    color: d.close >= d.open ? '#ff3b3055' : '#007aff55'
                }));
                volumeSeries.setData(volData);

                window.lastCandleTime = Math.max(...data.map(d => d.time));
            }
        }


        function changeTimeframe(gran) {
            document.querySelectorAll('#tf-buttons button').forEach(btn => {
                btn.style.background = '';
                btn.style.color = '';
            });
            event.target.style.background = '#333';
            event.target.style.color = '#fff';

            // 시간 범위 말고 논리적 범위(캔들 개수) 저장
            const logicalRange = chart.timeScale().getVisibleLogicalRange();

            currentGranularity = gran;
            if (currentWs) currentWs.close();

            loadData().then(() => {
                if (logicalRange) {
                    chart.timeScale().setVisibleLogicalRange(logicalRange);
                }
                // connectWebSocket();
            });
        }

        // WebSocket 실시간 연결
        

        loadData();

        let orderSide = 'buy';
        let lastPrice = 0;

        function setOrder(side) {
            orderSide = side;
            const orderBtn = document.getElementById('order-btn');
            if (side === 'buy') {
                orderBtn.textContent = '매수 주문';
                orderBtn.style.background = '#ff3b30';
            } else {
                orderBtn.textContent = '매도 주문';
                orderBtn.style.background = '#007aff';
            }
        }
        function setPercent(pct) {
            // 보유 USDT가 있다면 그걸로 계산, 지금은 예시로 1000 USDT 가정
            const budget = 1000;
            const qty = (budget * pct / 100 / lastPrice);
            document.getElementById('trade-qty').value = qty.toFixed(6);
            calcAmount();
        }

        function calcAmount() {
            const qty = parseFloat(document.getElementById('trade-qty').value) || 0;
            document.getElementById('trade-amount').value = (qty * lastPrice).toFixed(2);
        }

        function submitOrder() {
            const qty = document.getElementById('trade-qty').value;
            if (!qty) { alert('수량을 입력하세요'); return; }
            const side = orderSide === 'buy' ? '매수' : '매도';
            alert(side + ' 주문: ' + qty + ' BTC @ ' + lastPrice + ' USDT');
        }
    </script>

</body>

</html>