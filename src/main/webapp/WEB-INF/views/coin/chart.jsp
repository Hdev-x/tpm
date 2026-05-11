<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<title>코인/주식 차트 테스트</title>
<!-- 1. ApexCharts 라이브러리 로드 -->
<script src="https://cdn.jsdelivr.net/npm/apexcharts"></script>
</head>
<body>

	<h2>내 차트 대시보드</h2>

	<!-- 2. 차트가 그려질 공간 -->
	<div id="chart" style="width: 100%; max-width: 800px;"></div>

	<script>
		// 3. 차트 설정 및 데이터
		var options = {
			series : [ {
				name : 'candle',
				data : [
				// { x: 날짜(타임스탬프), y: [시가, 고가, 저가, 종가] }
				{
					x : new Date('2026-05-01').getTime(),
					y : [ 66000, 66500, 65800, 66200 ]
				}, {
					x : new Date('2026-05-02').getTime(),
					y : [ 66200, 67000, 66100, 66800 ]
				}, {
					x : new Date('2026-05-03').getTime(),
					y : [ 66800, 66900, 66200, 66400 ]
				}, {
					x : new Date('2026-05-04').getTime(),
					y : [ 66400, 67500, 66300, 67200 ]
				}, {
					x : new Date('2026-05-05').getTime(),
					y : [ 67200, 67800, 67000, 67500 ]
				} ]
			} ],
			chart : {
				type : 'candlestick', // 캔들 차트 지정
				height : 350
			},
			title : {
				text : 'BTC/USDT 샘플 차트',
				align : 'left'
			},
			xaxis : {
				type : 'datetime'
			},
			yaxis : {
				tooltip : {
					enabled : true
				}
			}
		};

		// 차트 생성 및 렌더링
		var chart = new ApexCharts(document.querySelector("#chart"), options);
		chart.render();
	</script>
</body>
</html>