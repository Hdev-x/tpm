<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Professional Stock Chart</title>
<script src="https://unpkg.com/lightweight-charts/dist/lightweight-charts.standalone.production.js"></script>
<style>
    body { background-color: #131722; margin: 0; padding: 20px; color: white; font-family: 'Malgun Gothic', sans-serif; }
    #chart-container { width: 100%; height: 600px; border: 1px solid #2a2e39; }
    .info { margin-bottom: 15px; background: #1e222d; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.3); }
    .symbol-info { display: flex; align-items: baseline; gap: 10px; margin-bottom: 10px; }
    .symbol-name { font-size: 28px; font-weight: bold; color: #ffffff; }
    .symbol-code { font-size: 18px; color: #848e9c; }
    button { padding: 8px 15px; cursor: pointer; background: #2a2e39; color: white; border: 1px solid #485c7b; border-radius: 4px; transition: 0.2s; }
    button:hover { background: #363a45; border-color: #2962ff; }
    button.active { background: #2962ff; border-color: #2962ff; }
    input { padding: 10px; width: 250px; border-radius: 4px; border: 1px solid #485c7b; background: #2a2e39; color: white; outline: none; }
    input:focus { border-color: #2962ff; }
</style>
</head>
<body>

    <div class="info">
        <div style="margin-bottom: 15px;">
            <input type="text" id="symbolInput" placeholder="종목명 또는 코드 (예: SK하이닉스)">
            <button onclick="searchStock()" style="background: #2962ff; border: none; font-weight: bold;">조회</button>
        </div>
        <div class="symbol-info">
            <span class="symbol-name" id="displayTitle">삼성전자</span>
            <span class="symbol-code" id="displayCode">(005930)</span>
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
        currentSymbol = input; // 이름 혹은 코드 그대로 전달
        fetchChart('1y'); 
    }

    // 이동평균선 계산 함수
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
        // 버튼 활성화 UI 처리
        document.querySelectorAll('.period-buttons button').forEach(btn => btn.classList.remove('active'));
        const activeBtn = document.getElementById('btn-' + range);
        if(activeBtn) activeBtn.classList.add('active');

        fetch("/stock/chart?symbol=" + encodeURIComponent(currentSymbol) + "&range=" + range)
            .then(res => res.json())
            .then(data => {
                if (data.error) {
                    alert(data.error);
                    return;
                }
                if (!data.candles || data.candles.length === 0) {
                    alert("데이터가 없습니다.");
                    return;
                }

                const candles = data.candles;

                // 1. 캔들 데이터 세팅
                candlestickSeries.setData(candles);

                // 2. 거래량 데이터 세팅
                const volumeData = candles.map(c => ({
                    time: c.time,
                    value: c.volume,
                    color: c.close > c.open ? 'rgba(239, 83, 80, 0.5)' : 'rgba(38, 166, 154, 0.5)'
                }));
                volumeSeries.setData(volumeData);

                // 3. 이동평균선 세팅
                ma5Series.setData(calculateMA(candles, 5));
                ma20Series.setData(calculateMA(candles, 20));

                // 상단 정보 업데이트
                document.getElementById('displayTitle').innerText = data.stockName;
                document.getElementById('displayCode').innerText = "(" + data.stockCode + ")";
                currentSymbol = data.stockCode; // 실제 코드로 동기화

                // 시간축 가시성 조절
                chart.applyOptions({
                    timeScale: { timeVisible: data.isMinute }
                });
                chart.timeScale().fitContent();
            })
            .catch(err => console.error("Error:", err));
    }

    document.addEventListener("DOMContentLoaded", function() {
        const container = document.getElementById('chart-container');
        
        // 1. 차트 초기화
        chart = LightweightCharts.createChart(container, {
            layout: { background: { color: '#131722' }, textColor: '#d1d4dc' },
            grid: { vertLines: { color: '#2a2e39' }, horzLines: { color: '#2a2e39' } },
            crosshair: { mode: LightweightCharts.CrosshairMode.Normal },
            timeScale: { borderColor: '#485c7b' },
        });

        // 2. 캔들 시리즈 추가 (최신 방식)
        candlestickSeries = chart.addSeries(LightweightCharts.CandlestickSeries, {
            upColor: '#ef5350', downColor: '#26a69a',
            borderVisible: false,
            wickUpColor: '#ef5350', wickDownColor: '#26a69a',
        });

        // 3. 거래량 시리즈 추가 (Histogram)
        volumeSeries = chart.addSeries(LightweightCharts.HistogramSeries, {
            color: '#26a69a',
            priceFormat: { type: 'volume' },
            priceScaleId: '', 
        });
        volumeSeries.priceScale().applyOptions({
            scaleMargins: { top: 0.8, bottom: 0 },
        });

        // 4. ✅ 이동평균선 시리즈 추가 (addLineSeries 대신 이 방식을 사용하세요)
        ma5Series = chart.addSeries(LightweightCharts.LineSeries, { 
            color: '#FFD700', 
            lineWidth: 1, 
            title: 'MA5' 
        });
        
        ma20Series = chart.addSeries(LightweightCharts.LineSeries, { 
            color: '#FF00FF', 
            lineWidth: 1, 
            title: 'MA20' 
        });

        // 5. 초기 데이터 로드
        fetchChart('1y');
    });

    // 엔터키 검색 지원
    document.getElementById('symbolInput').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') searchStock();
    });
</script>
</body>
</html>