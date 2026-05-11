<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>TradingView Style Chart</title>
<!-- TradingView Lightweight Charts CDN -->
<script
	src="https://unpkg.com/lightweight-charts/dist/lightweight-charts.standalone.production.js"></script>
<style>
body {
	background-color: #131722;
	margin: 0;
	padding: 20px;
	color: white;
	font-family: sans-serif;
}

#chart-container {
	width: 100%;
	height: 500px;
}

.info {
	margin-bottom: 15px;
}

.symbol {
	font-size: 24px;
	font-weight: bold;
}
</style>
</head>
<body>

	<div class="info">
		<span class="symbol">삼성전자 (005930)</span> <span>1분봉 차트</span>
	</div>
	<div id="chart-container"></div>

	<div class="info">
		<span class="symbol">종목 코드: ${symbol}</span>
		<div class="period-buttons" style="margin-top: 10px;">
			<button onclick="fetchPeriod(1)">1일</button>
			<button onclick="fetchPeriod(5)">5일</button>
			<button onclick="fetchPeriod(30)">1개월</button>
			<button onclick="fetchPeriod(365)">1년</button>
			<button onclick="fetchPeriod(1095)">3년</button>
		</div>
	</div>

	<script>
    // 전역 변수로 선언하여 어디서든 접근 가능하게 합니다.
    let candlestickSeries;
    let chart;

    // 1. 날짜 포맷 함수 (YYYYMMDD)
    function formatDate(date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}${month}${day}`;
    }

    // 2. 버튼 클릭 시 호출될 함수 (이게 정의되어 있어야 에러가 안 납니다!)
   function fetchPeriod(days) {
    // 1. 현재 URL에서 symbol 가져오기
    const urlParams = new URLSearchParams(window.location.search);
    let symbol = urlParams.get('symbol');

    // 🔴 중요: symbol이 null이거나 빈 문자열이면 기본값(삼성전자) 부여
    if (!symbol || symbol.trim() === "") {
        symbol = "005930"; 
    }

    // 2. 타입 설정
    const type = (days <= 1) ? 'min' : 'day';

    // 3. 날짜 계산 함수
    const today = new Date();
    const start = new Date();
    start.setDate(today.getDate() - days);

    const endDate = formatDate(today);
    const startDate = formatDate(start);

    // 로그 확인 (여기서 값이 제대로 찍히는지 반드시 확인하세요)
    console.log(`🚀 요청 전송 -> 종목: ${symbol}, 타입: ${type}, 시작일: ${startDate}`);

    // 4. fetch 호출
    fetch(`/stock/chart?symbol=${symbol}&type=${type}&startDate=${startDate}`)
        .then(res => {
            if (!res.ok) throw new Error('서버 응답 에러 (500)');
            return res.json();
        })
        .then(data => {
            if (!data.candles || data.candles.length === 0) {
                console.warn("데이터가 비어있습니다.");
                return;
            }
            chart.applyOptions({
                timeScale: { timeVisible: data.isMinute }
            });
            candlestickSeries.setData(data.candles);
            chart.timeScale().fitContent();
        })
        .catch(err => console.error("❌ 데이터 로드 실패:", err));
}

    // 3. 페이지 초기 로드 설정
    document.addEventListener("DOMContentLoaded", function() {
        const chartOptions = {
            layout: { backgroundColor: '#131722', textColor: '#d1d4dc' },
            grid: {
                vertLines: { color: 'rgba(42, 46, 57, 0.5)' },
                horzLines: { color: 'rgba(42, 46, 57, 0.5)' },
            },
            rightPriceScale: { borderColor: 'rgba(197, 203, 206, 0.8)' },
            timeScale: { borderColor: 'rgba(197, 203, 206, 0.8)', timeVisible: true },
        };

        const container = document.getElementById('chart-container');
        chart = LightweightCharts.createChart(container, chartOptions);
        
        candlestickSeries = chart.addSeries(LightweightCharts.CandlestickSeries, {
            upColor: '#ef5350', downColor: '#26a69a',
            borderVisible: false,
            wickUpColor: '#ef5350', wickDownColor: '#26a69a',
        });

        // 처음 로드 시 기본 1년치 보여주기
        fetchPeriod(365);
    });
</script>

</body>
</html>