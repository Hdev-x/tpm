// 1. 서버에서 주식 데이터 100개를 가져오는 함수
async function refreshStockPrices() {
    try {
        const response = await fetch('/api/stocks/top100'); // 서버에 만든 API 경로
        const stocks = await response.json();
        
        const listBody = document.getElementById('stock-list-body');
        const now = new Date().toLocaleTimeString();
        document.getElementById('update-time').innerText = now + " 기준";

        stocks.forEach(stock => {
            let row = document.getElementById(`stock-${stock.code}`);
            
            // 기존에 행이 없으면 생성, 있으면 가격만 업데이트
            if (!row) {
                row = createStockRow(stock);
                listBody.appendChild(row);
            } else {
                updatePriceEffect(row, stock);
            }
        });
    } catch (e) {
        console.error("데이터 로드 실패", e);
    }
}

// 2. 가격이 변할 때 깜빡이는 효과 함수
function updatePriceEffect(row, data) {
    const priceCell = row.querySelector('.price-cell');
    const oldPrice = priceCell.innerText;
    const newPrice = data.price.toLocaleString() + "원";

    if (oldPrice !== newPrice) {
        priceCell.innerText = newPrice;
        // 가격이 오르면 빨간색, 내리면 파란색으로 잠시 깜빡임 (토스 스타일)
        const flashColor = data.change > 0 ? 'rgba(239, 83, 80, 0.2)' : 'rgba(41, 98, 255, 0.2)';
        priceCell.style.backgroundColor = flashColor;
        setTimeout(() => priceCell.style.backgroundColor = 'transparent', 500);
    }
}

// 2~3초마다 자동으로 데이터 갱신
setInterval(refreshStockPrices, 3000);