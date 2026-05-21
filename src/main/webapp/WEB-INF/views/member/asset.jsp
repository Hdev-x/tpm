<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>TradeBot · 자산 상세</title>
<link rel="stylesheet"
	href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
<link rel="stylesheet" href="/css/common.css">
<link rel="stylesheet" href="/css/chart-toss-coin.css">
<style>
.asset-detail-card {
	width: 100%;
	max-width: 800px;
	margin: 40px auto;
	padding: 30px;
	background: var(--bg);
	border: 1px solid var(--border);
	border-radius: 16px;
	box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
}

.detail-header {
	margin-bottom: 30px;
	display: flex;
	justify-content: space-between;
	align-items: center;
}

.detail-header h2 {
	font-size: 24px;
	font-weight: 700;
	color: var(--text);
}

.asset-table {
	width: 100%;
	border-collapse: collapse;
}

.asset-table th {
	padding: 15px;
	text-align: left;
	color: var(--text3);
	font-size: 14px;
	font-weight: 500;
	border-bottom: 1px solid var(--border);
}

.asset-table td {
	padding: 20px 15px;
	font-size: 16px;
	border-bottom: 1px solid rgba(255, 255, 255, 0.03);
}

.asset-table tr:last-child td {
	border-bottom: none;
}

.stock-name-cell {
	display: flex;
	align-items: center;
	gap: 12px;
}

.stock-logo-mini {
	width: 32px;
	height: 32px;
	border-radius: 50%;
	background: var(--surface2);
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 11px;
	font-weight: 700;
	color: var(--text2);
}

.val-eval {
	font-weight: 600;
	color: var(--text);
}

.val-rate {
	font-weight: 600;
}

.val-rate.up {
	color: var(--up);
}

.val-rate.down {
	color: var(--down);
}

.empty-asset {
	padding: 60px 0;
	text-align: center;
	color: var(--text3);
}
</style>
</head>
<body>

	<div class="app-wrapper">
		<div class="page">
			<%@ include file="/WEB-INF/views/common/nav.jsp"%>

			<div class="main-content" style="flex: 1; overflow-y: auto;">
				<div class="asset-detail-card">
					<div class="detail-header">
						<h2>보유 자산 내역</h2>
						<button class="tf-btn" onclick="updateAsset()"
							style="padding: 6px 12px; border: 1px solid var(--border2);">새로고침</button>
					</div>

					<table class="asset-table">
						<thead>
							<tr>
								<th>종목</th>
								<th style="text-align: right;">수량</th>
								<th style="text-align: right;">평균단가</th>
								<th style="text-align: right;">평가금액</th>
								<th style="text-align: right;">수익률</th>
							</tr>
						</thead>
						<tbody id="assetDetailBody">
							<!-- JS 렌더링 -->
						</tbody>
					</table>

					<div id="emptyMsg" class="empty-asset" style="display: none;">
						📊 보유 중인 주식이 없습니다.</div>

					<div style="margin-top: 40px; display: flex; gap: 12px;">
						<button class="btn-buy"
							style="flex: 1; padding: 14px; background: var(--blue);"
							onclick="history.back()">뒤로가기</button>
						<button class="btn-list" style="flex: 1; padding: 14px;"
							onclick="location.href='/'">메인으로</button>
					</div>
				</div>
			</div>
		</div>

		<%@ include file="/WEB-INF/views/common/sidebar.jsp"%>
		<%@ include file="/WEB-INF/views/common/sidebar-icons.jsp"%>
	</div>

	<script src="/js/common.js" defer></script>
	<script>
    function updateAsset() {
        fetch('/stock/asset-detail-data')
            .then(res => res.json())
            .then(data => {
                const tbody = document.getElementById('assetDetailBody');
                const emptyMsg = document.getElementById('emptyMsg');
                if (!tbody) return;
                
                if (!data || data.length === 0) {
                    tbody.innerHTML = '';
                    emptyMsg.style.display = 'block';
                    return;
                }
                
                emptyMsg.style.display = 'none';
                tbody.innerHTML = data.map(item => {
                    const rate = parseFloat(item.rate);
                    const rateCls = rate > 0 ? 'up' : (rate < 0 ? 'down' : '');
                    const sign = rate > 0 ? '+' : '';
                    
                    return `
                    <tr>
                        <td>
                            <div class="stock-name-cell">
                                <div class="stock-logo-mini">\$ {item.name.slice(0,2)}</div>
                                <div>
                                    <div style="font-weight:600;">\$ {item.name}</div>
                                    <div style="font-size:12px; color:var(--text3);">주식</div>
                                </div>
                            </div>
                        </td>
                        <td style="text-align: right;">\$ {Number(item.count).toLocaleString()}주</td>
                        <td style="text-align: right;">\$ {Number(item.buyPrice).toLocaleString()}원</td>
                        <td style="text-align: right;" class="val-eval">\$ {Number(item.eval).toLocaleString()}원</td>
                        <td style="text-align: right;" class="val-rate \$ {rateCls}">\$ {sign}\$ {item.rate}%</td>
                    </tr>`;
                }).join('');
            })
            .catch(err => console.error("상세 정보 로드 실패:", err));
    }

    document.addEventListener('DOMContentLoaded', () => {
        updateAsset();
        // 10초마다 자동 갱신
        setInterval(updateAsset, 10000);
    });
</script>
</body>
</html>