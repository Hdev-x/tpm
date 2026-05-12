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
                <button onclick="changeTimeframe('1m')">1분</button>
                <button onclick="changeTimeframe('3m')">3분</button>
                <button onclick="changeTimeframe('5m')">5분</button>
                <button onclick="changeTimeframe('15m')">15분</button>
                <button onclick="changeTimeframe('30m')">30분</button>
                <button onclick="changeTimeframe('1h')">1시간</button>
                <button onclick="changeTimeframe('4h')">4시간</button>
                <button onclick="changeTimeframe('6h')">6시간</button>
                <button onclick="changeTimeframe('12h')">12시간</button>
                <button onclick="changeTimeframe('1d')">일봉</button>
                <button onclick="changeTimeframe('3d')">3일봉</button>
                <button onclick="changeTimeframe('1w')">주봉</button>
                <button onclick="changeTimeframe('1M')">월봉</button>
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
        let currentGranularity = '1m';
        let currentChannel = '1m';

        const TF_MAP = {
            '1m': { channel: '1m', label: '1분' },
            '3m': { channel: '3m', label: '3분' },
            '5m': { channel: '5m', label: '5분' },
            '15m': { channel: '15m', label: '15분' },
            '30m': { channel: '30m', label: '30분' },
            '1h': { channel: '1h', label: '1시간' },
            '4h': { channel: '4h', label: '4시간' },
            '6h': { channel: '6h', label: '6시간' },
            '12h': { channel: '12h', label: '12시간' },
            '1d': { channel: '1d', label: '일봉' },
            '3d': { channel: '3d', label: '3일봉' },
            '1w': { channel: '1w', label: '주봉' },
            '1M': { channel: '1M', label: '월봉' },
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
            const res = await fetch(
                'https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=' + currentGranularity + '&limit=200'
            ).then(r => r.json());

            // 응답 형식도 바뀌어요
            if (Array.isArray(res)) {
                const data = res.map(item => ({
                    time: Math.floor(item[0] / 1000),
                    open: parseFloat(item[1]),
                    high: parseFloat(item[2]),
                    low: parseFloat(item[3]),
                    close: parseFloat(item[4]),
                    volume: parseFloat(item[5])
                }));
                // 9. 캔들 차트에 데이터 주입
                console.log('첫번째 캔들:', data[0]);
                console.log('마지막 캔들:', data[data.length - 1]);
                candleSeries.setData(data);
                // MA5
                const ma5Data = [];
                data.forEach((d, i) => {
                    if (i < 5) return;
                    const avg = data.slice(i - 5, i).reduce((s, c) => s + c.close, 0) / 5;
                    ma5Data.push({ time: d.time, value: avg });
                });
                ma5Series.setData(ma5Data);

                // 거래량
                const volData = data.map(d => ({
                    time: d.time,
                    value: d.volume,
                    color: d.close >= d.open ? '#ff3b3055' : '#007aff55'
                }));
                volumeSeries.setData(volData);
                window.lastCandleTime = Math.max(...data.map(d => d.time));

                // --- [D] 보조지표 계산 로직 ---
                // 10. MA 20 계산: 현재 시점 기준 앞선 20개 종가의 평균을 구함
                const maData = [];
                data.forEach((d, i) => {
                    if (i < 20) return;
                    const avg = data.slice(i - 20, i).reduce((sum, curr) => sum + curr.close, 0) / 20;
                    maData.push({ time: d.time, value: avg });
                });
                // 11. 계산된 MA 데이터를 선 차트에 주입
                ma20Series.setData(maData);

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
            currentChannel = TF_MAP[gran].channel;
            if (currentWs) currentWs.close();

            loadData().then(() => {
                if (logicalRange) {
                    chart.timeScale().setVisibleLogicalRange(logicalRange);
                }
                connectWebSocket();
            });
        }

        // WebSocket 실시간 연결
        function connectWebSocket() {
            const ws = new WebSocket('wss://stream.binance.com:9443/ws/btcusdt@kline_' + currentChannel);
            currentWs = ws;

            ws.onmessage = (event) => {
                if (ws !== currentWs) return;
                const msg = JSON.parse(event.data);
                if (msg.e !== 'kline') return;
                const k = msg.k;
                const bar = {
                    time: Math.floor(k.t / 1000),
                    open: parseFloat(k.o),
                    high: parseFloat(k.h),
                    low: parseFloat(k.l),
                    close: parseFloat(k.c)
                };
                if (window.lastCandleTime && bar.time < window.lastCandleTime) return;
                candleSeries.update(bar);
                document.getElementById('val-o').textContent = bar.open.toFixed(2);
                document.getElementById('val-h').textContent = bar.high.toFixed(2);
                document.getElementById('val-l').textContent = bar.low.toFixed(2);
                document.getElementById('val-c').textContent = bar.close.toFixed(2);
                lastPrice = bar.close;
                document.getElementById('trade-price').textContent = bar.close.toFixed(2);
            };

            ws.onclose = () => {
                if (ws === currentWs) setTimeout(connectWebSocket, 3000);
            };
        }

        loadData().then(() => connectWebSocket());
        document.querySelector('#tf-buttons button').style.background = '#333';
        document.querySelector('#tf-buttons button').style.color = '#fff';

        // 13. 반응형 처리: 브라우저 창 크기가 변하면 차트 너비도 자동 조절
        window.addEventListener('resize', () => chart.applyOptions({ width: container.clientWidth }));
        chart.subscribeCrosshairMove(param => {
            if (!param.time) return;
            const candle = param.seriesData.get(candleSeries);
            if (!candle) return;
            document.getElementById('val-o').textContent = candle.open.toFixed(2);
            document.getElementById('val-h').textContent = candle.high.toFixed(2);
            document.getElementById('val-l').textContent = candle.low.toFixed(2);
            document.getElementById('val-c').textContent = candle.close.toFixed(2);
        });

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