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
    // 1. 초기 차트 설정 (데이터는 비워둡니다)
    var options = {
        series: [{
            name: 'candle',
            data: [] // 처음에 비워두면 로딩 후 데이터가 들어옵니다.
        }],
        chart: {
            type: 'candlestick',
            height: 350
        },
        title: {
            text: 'Bithumb BTC/KRW 실시간 시세 (24h 봉)',
            align: 'left'
        },
        xaxis: {
            type: 'datetime'
        },
        yaxis: {
            tooltip: { enabled: true }
        }
    };

    var chart = new ApexCharts(document.querySelector("#chart"), options);
    chart.render();

    // 2. 빗썸 Public API 데이터 가져오기
    function getBithumbData() {
        const url = 'https://api.bithumb.com/public/candlestick/BTC_KRW/24h';

        fetch(url)
            .then(response => response.json())
            .then(res => {
                if(res.status !== "0000") {
                    console.error("데이터를 가져오는데 실패했습니다.");
                    return;
                }

                const rawData = res.data; // 빗썸 데이터 리스트
                
                // 3. 빗썸 데이터를 ApexCharts 형식으로 변환
                // 빗썸 순서: [시간, 시가, 종가, 고가, 저가, 거래량]
                // ApexCharts 순서: { x: 시간, y: [시가, 고가, 저가, 종가] }
                const formattedData = rawData.map(item => {
                    return {
                        x: item[0], // Timestamp
                        y: [
                            parseFloat(item[1]), // Open
                            parseFloat(item[3]), // High
                            parseFloat(item[4]), // Low
                            parseFloat(item[2])  // Close
                        ]
                    };
                });

                // 4. 차트에 데이터 넣기
                chart.updateSeries([{
                    data: formattedData
                }]);
            })
            .catch(err => console.error("Fetch 에러:", err));
    }

    // 함수 실행
    getBithumbData();
</script>
</body>
</html>