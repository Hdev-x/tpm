<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Professional Stock Chart</title>
<script
	src="https://unpkg.com/lightweight-charts/dist/lightweight-charts.standalone.production.js"></script>
<style>
body {
	background-color: #131722;
	margin: 0;
	padding: 20px;
	color: white;
	font-family: 'Malgun Gothic', sans-serif;
}

#chart-container {
	width: 100%;
	height: 600px;
	border: 1px solid #2a2e39;
}

.info {
	margin-bottom: 15px;
	background: #1e222d;
	padding: 20px;
	border-radius: 8px;
	box-shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
}

.symbol-info {
	display: flex;
	align-items: baseline;
	gap: 10px;
	margin-bottom: 10px;
}

.symbol-name {
	font-size: 28px;
	font-weight: bold;
	color: #ffffff;
}

.symbol-code {
	font-size: 18px;
	color: #848e9c;
}

button {
	padding: 8px 15px;
	cursor: pointer;
	background: #2a2e39;
	color: white;
	border: 1px solid #485c7b;
	border-radius: 4px;
	transition: 0.2s;
}

button:hover {
	background: #363a45;
	border-color: #2962ff;
}

button.active {
	background: #2962ff;
	border-color: #2962ff;
}

input {
	padding: 10px;
	width: 250px;
	border-radius: 4px;
	border: 1px solid #485c7b;
	background: #2a2e39;
	color: white;
	outline: none;
}

input:focus {
	border-color: #2962ff;
}
</style>
</head>
<body>

	<div class="info">
		<div style="margin-bottom: 15px;">
			<input type="text" id="symbolInput"
				placeholder="종목명 또는 코드 (예: SK하이닉스)">
			<button onclick="searchStock()"
				style="background: #2962ff; border: none; font-weight: bold;">조회</button>
		</div>
		<div class="symbol-info">
			<span class="symbol-name" id="displayTitle">삼성전자</span> <span
				class="symbol-code" id="displayCode">(005930)</span>
		</div>
		<div class="period-buttons">
			<button onclick="fetchChart('min')" id="btn-min">1분봉</button>
			<button onclick="fetchChart('1y')" id="btn-1y">1년(일봉)</button>
			<button onclick="fetchChart('3y')" id="btn-3y">3년(주봉)</button>
			<button onclick="fetchChart('10y')" id="btn-10y">10년(월봉)</button>
		</div>
	</div>

	<div id="chart-container"></div>

	<script>
    let chart;
    let candlestickSeries;
    let volumeSeries;
    let ma5Series;
    let ma20Series;
    let currentSymbol = "005930"; 

    function searchStock() {
        const input = document.getElementById('symbolInput').value.trim();
        if (!input) {
            alert("종목명 또는 코드를 입력하세요.");
            return;
        }
        currentSymbol = input; 
        fetchChart('1y'); 
    }

    function calculateMA(data, period) {
        const maData = [];
        for (let i = 0; i < data.length; i++) {
            if (i < period - 1) continue;
            let sum = 0;
            for (let j = 0; j < period; j++) {
                sum += data[i - j].close;
            }
            maData.push({ time: data[i].time, value: sum / period });
        }
        return maData;
    }

    function fetchChart(range) {
        document.querySelectorAll('.period-buttons button').forEach(btn => btn.classList.remove('active'));
        const activeBtn = document.getElementById('btn-' + range);
        if(activeBtn) activeBtn.classList.add('active');

        // ✅ URL 경로 확인: /stock/chart
        fetch("/stock/chart?code=" + encodeURIComponent(currentSymbol) + "&range=" + range)
            .then(res => res.json())
            .then(data => {
    console.log("받은 데이터 전체:", data);

    // 1. 이름 업데이트 (콘솔에 stockName이 있으니 무조건 바뀝니다)
    if (data.stockName) {
        document.getElementById('displayTitle').innerText = data.stockName;
    }

    // 2. 코드 업데이트 (컨트롤러 수정 후 stockCode가 들어오면 바뀝니다)
    if (data.stockCode) {
        document.getElementById('displayCode').innerText = "(" + data.stockCode + ")";
        currentSymbol = data.stockCode; // 다음 검색을 위해 코드 동기화
    } else {
        // 만약 stockCode가 안 들어오면, 입력창에 친 값을 강제로라도 넣습니다.
        const inputVal = document.getElementById('symbolInput').value.trim();
        if(inputVal && !isNaN(inputVal)) {
            document.getElementById('displayCode').innerText = "(" + inputVal + ")";
            currentSymbol = inputVal;
        }
    }

             // 1. 글자부터 무조건 바꿉니다.
             if (data.stockCode) {
                 document.getElementById('displayCode').innerText = "(" + data.stockCode + ")";
             }
             if (data.stockName) {
                 document.getElementById('displayTitle').innerText = data.stockName;
             }
             // 2. 전역 변수도 바꿉니다.
             currentSymbol = data.stockCode || currentSymbol;

                // 2. 데이터 변환 (한투 API -> 차트 라이브러리 규격)
                const candles = data.output2.map(d => {
                    const rawDate = d.stck_bsop_date;
                    const formattedDate = rawDate.substring(0, 4) + '-' + rawDate.substring(4, 6) + '-' + rawDate.substring(6, 8);
                    return {
                        time: formattedDate,
                        open: parseFloat(d.stck_oprc),
                        high: parseFloat(d.stck_hgpr),
                        low: parseFloat(d.stck_lwpr),
                        close: parseFloat(d.stck_clpr),
                        volume: parseFloat(d.acml_vol)
                    };
                }).sort((a, b) => a.time > b.time ? 1 : -1);

                // 3. 차트 시리즈에 데이터 주입
                candlestickSeries.setData(candles);

                const volumeData = candles.map(c => ({
                    time: c.time,
                    value: c.volume,
                    color: c.close > c.open ? 'rgba(239, 83, 80, 0.5)' : 'rgba(38, 166, 154, 0.5)'
                }));
                volumeSeries.setData(volumeData);

                ma5Series.setData(calculateMA(candles, 5));
                ma20Series.setData(calculateMA(candles, 20));

                chart.timeScale().fitContent();
            })
            .catch(err => {
                console.error("Error:", err);
                alert("데이터 로드 중 오류가 발생했습니다.");
            });
    }

    document.addEventListener("DOMContentLoaded", function() {
        const container = document.getElementById('chart-container');
        
        chart = LightweightCharts.createChart(container, {
            layout: { background: { color: '#131722' }, textColor: '#d1d4dc' },
            grid: { vertLines: { color: '#2a2e39' }, horzLines: { color: '#2a2e39' } },
            crosshair: { mode: LightweightCharts.CrosshairMode.Normal },
            timeScale: { borderColor: '#485c7b' },
        });

        candlestickSeries = chart.addSeries(LightweightCharts.CandlestickSeries, {
            upColor: '#ef5350', downColor: '#26a69a',
            borderVisible: false,
            wickUpColor: '#ef5350', wickDownColor: '#26a69a',
        });

        volumeSeries = chart.addSeries(LightweightCharts.HistogramSeries, {
            color: '#26a69a',
            priceFormat: { type: 'volume' },
            priceScaleId: '', 
        });
        volumeSeries.priceScale().applyOptions({ scaleMargins: { top: 0.8, bottom: 0 } });

        ma5Series = chart.addSeries(LightweightCharts.LineSeries, { color: '#FFD700', lineWidth: 1, title: 'MA5' });
        ma20Series = chart.addSeries(LightweightCharts.LineSeries, { color: '#FF00FF', lineWidth: 1, title: 'MA20' });

        fetchChart('1y');
    });

    document.getElementById('symbolInput').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') searchStock();
    });
</script>
</body>
</html>