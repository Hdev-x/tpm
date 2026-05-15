<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<link rel="stylesheet" href="/css/common.css">
<link rel="stylesheet" href="/css/chart-toss.css">
<style>
/* 화면 중앙 정렬을 위한 최소한의 인라인 스타일 */
.member-container {
	display: flex;
	align-items: center;
	justify-content: center;
	min-height: 100vh;
	padding: 20px;
}

.info-group {
	margin: 20px 0;
	display: flex;
	flex-direction: column;
	gap: 12px;
}

.info-row {
	display: flex;
	justify-content: space-between;
	padding: 12px 0;
	border-bottom: 1px solid var(--border);
}

.info-label {
	color: var(--text3);
	font-size: 13px;
}

.info-value {
	color: var(--text);
	font-weight: 600;
}

/* 자산 영역 강조 */
.asset-box {
	background: var(--surface2);
	padding: 20px;
	border-radius: 12px;
	margin-top: 10px;
	text-align: center;
}
</style>
</head>
<body class="member-container">

	<div class="card" style="width: 100%; max-width: 400px; padding: 30px;">

		<div class="logo"
			style="font-size: 24px; text-align: center; margin-bottom: 30px;">
			<span>M</span>y Page
		</div>

		<div class="info-group">
			<div class="info-row">
				<span class="info-label">아이디</span> <span class="info-value">${dto.username}</span>
			</div>
			<div class="info-row">
				<span class="info-label">이름</span> <span class="info-value">${dto.name}</span>
			</div>
		</div>

		<div class="asset-box">
			<div class="ph-label" style="margin-bottom: 8px;">보유 예수금</div>
			<div class="ph-price" style="color: var(--blue); font-size: 24px;">
				${dto.cash} <span style="font-size: 14px; color: var(--text2);">원</span>
			</div>
		</div>

		<div
			style="margin-top: 30px; display: flex; flex-direction: column; gap: 10px;">
			<button class="btn-buy" onclick="location.href='./update'"
				style="background: var(--blue);">정보 수정하기</button>

			<div style="display: flex; gap: 8px;">
				<button class="tf-btn" onclick="location.href='./order/history'"
					style="flex: 1; padding: 10px; border: 1px solid var(--border2);">거래
					내역</button>
				<button class="tf-btn" onclick="location.href='/'"
					style="flex: 1; padding: 10px; border: 1px solid var(--border2);">메인으로</button>
			</div>
		</div>
	</div>

	<script src="/js/common.js"></script>
</body>
</html>