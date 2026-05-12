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
    <h2>Bithumb BTC/KRW 전문 차트</h2>

    <div id="chart-container"></div>

    <script>



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

        // --- [C] 데이터 로드 및 가공 단계 ---
        async function loadData() {
            // 7. 빗썸 API 호출 (BTC 일봉 데이터)
            const res = await fetch('https://api.bithumb.com/public/candlestick/BTC_KRW/1m').then(r => r.json());

            if (res.status === "0000") {
                // 8. 빗썸 데이터 형식을 차트 라이브러리 형식으로 변환
                // [시간, 시가, 종가, 고가, 저가, 거래량] 순서를 객체 형태로 맵핑
                const data = res.data.map(item => ({
                    time: item[0] / 1000,           // 초 단위 타임스탬프
                    open: parseFloat(item[1]),      // 시가
                    high: parseFloat(item[3]),      // 고가
                    low: parseFloat(item[4]),       // 저가
                    close: parseFloat(item[2])      // 종가
                }));

                // 9. 캔들 차트에 데이터 주입
                candleSeries.setData(data);
                console.log('마지막 캔들 time:', data[data.length - 1].time);

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

                // 12. 화면에 데이터가 꽉 차도록 줌(Zoom) 조절
                chart.timeScale().fitContent();
            }
        }

        loadData();
	
        let currentCandle = null;
        let currentMinute = null;
        // WebSocket 실시간 연결
        function connectWebSocket() {
            const ws = new WebSocket('wss://pubwss.bithumb.com/pub/ws');

            ws.onopen = () => {
                console.log('WebSocket 연결됨');
                ws.send(JSON.stringify({
                    type: 'ticker',
                    symbols: ['BTC_KRW'],
                    tickTypes: ['MID']
                }));
            };

            ws.onerror = (e) => console.log('WebSocket 에러:', e);

            ws.onclose = (e) => console.log('WebSocket 닫힘:', e.code, e.reason);

            ws.onmessage = (event) => {
                const msg = JSON.parse(event.data);
                if (msg.type !== 'ticker') return;

                const c = msg.content;
                const price = parseFloat(c.closePrice);
                const minute = Math.floor(Date.now() / 60000) * 60;

                if (currentMinute !== minute) {
                    currentMinute = minute;
                    currentCandle = {
                        time: minute,
                        open: price,
                        high: price,
                        low: price,
                        close: price
                    };
                } else {
                    currentCandle.high = Math.max(currentCandle.high, price);
                    currentCandle.low = Math.min(currentCandle.low, price);
                    currentCandle.close = price;
                }

                candleSeries.update(currentCandle);
                console.log('tick:', new Date().toLocaleTimeString());
            };

            ws.onclose = () => setTimeout(connectWebSocket, 3000);
        }

        connectWebSocket();
        

        // 13. 반응형 처리: 브라우저 창 크기가 변하면 차트 너비도 자동 조절
        window.addEventListener('resize', () => chart.applyOptions({ width: container.clientWidth }));
    </script>
</body>

</html>