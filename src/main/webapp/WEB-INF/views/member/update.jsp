<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<link rel="stylesheet" href="/css/common.css">
<link rel="stylesheet" href="/css/member/member.css">
<link rel="stylesheet" href="/css/board/board.css">
<style>
.member-container {
	display: flex;
	align-items: center;
	justify-content: center;
	min-height: 100vh;
	padding: 20px;
}

.form-group {
	display: flex;
	flex-direction: column;
	gap: 20px;
	margin: 25px 0;
}

.input-item {
	display: flex;
	flex-direction: column;
	gap: 8px;
}
/* chart-toss.css의 order-input 스타일을 참고한 입력창 스타일 */
.toss-input {
	background: var(--surface2);
	border: 1px solid var(--border2);
	color: var(--text);
	font-size: 14px;
	padding: 12px 15px;
	border-radius: 10px;
	outline: none;
	transition: border-color 0.15s;
}

.toss-input:focus {
	border-color: var(--blue);
}

.toss-input[readonly] {
	color: var(--text3);
	background: var(--bg);
	border-color: var(--border);
	cursor: not-allowed;
}
</style>
</head>
<body class="member-container">

	<div class="card" style="width: 100%; max-width: 450px; padding: 40px;">

		<div class="logo"
			style="font-size: 24px; text-align: center; margin-bottom: 10px;">
			<span>E</span>dit Profile
		</div>
		<p style="color: var(--text3); text-align: center; font-size: 13px;">변경하실
			정보를 입력해주세요.</p>

		<form action="./update" method="post">
			<div class="form-group">
				<div class="input-item">
					<label class="ph-label">아이디 (변경 불가)</label> <input type="text"
						name="username" value="${dto.username}" class="toss-input"
						readonly>
				</div>

				<div class="input-item">
					<label class="ph-label">이름</label> <input type="text" name="name"
						value="${dto.name}" class="toss-input" placeholder="이름을 입력하세요"
						required>
				</div>

				<div class="input-item">
					<label class="ph-label">보유 자산 (원)</label> <input type="number"
						name="cash" value="${dto.cash}" class="toss-input"
						placeholder="자산을 입력하세요">
				</div>
			</div>

			<div
				style="display: flex; flex-direction: column; gap: 10px; margin-top: 30px;">
				<button type="submit" class="btn-action btn-submit"
					style="width: 100%; height: auto; padding: 14px 0;">수정 완료</button>

				<button type="button" class="btn-action btn-list"
					onclick="location.href='./read'"
					style="width: 100%; height: auto; padding: 14px 0;">취소</button>
			</div>
		</form>
	</div>

	<script src="/js/common.js" defer></script>
	<script src="/js/sidebar-data.js" defer></script>
</body>
</html>