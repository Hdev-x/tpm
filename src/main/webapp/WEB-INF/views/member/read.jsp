<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<link rel="stylesheet" href="/css/common.css">
<link rel="stylesheet" href="/css/chart-toss-coin.css">
<style>
/* 화면 중앙 정렬을 위한 최소한의 인라인 스타일 */
.member-container {
	display: flex;
	align-items: center;
	justify-content: center;
	min-height: 100vh;
	padding: 20px;
}

.profile-row {
	display: flex;
	align-items: center;
	gap: 20px;
	margin-bottom: 8px;
}

.profile-avatar {
	width: 80px;
	height: 80px;
	border-radius: 20px;
	background: #2a2a2e;
	display: flex;
	align-items: center;
	justify-content: center;
	color: #888;
	flex-shrink: 0;
	cursor: pointer;
	position: relative;
	overflow: hidden;
}

.profile-avatar img {
	width: 100%;
	height: 100%;
	object-fit: cover;
	border-radius: 20px;
}

.profile-avatar:hover::after {
	content: '변경';
	position: absolute;
	inset: 0;
	background: rgba(0,0,0,0.5);
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 13px;
	color: #fff;
	border-radius: 20px;
}

.info-group {
	flex: 1;
	margin: 0;
	display: flex;
	flex-direction: column;
	gap: 0;
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
			style="font-size: 24px; text-align: center; margin-bottom: 24px;">
			<span>M</span>y Page
		</div>

		<input type="file" id="profileFileInput" accept="image/*" style="display:none;">
		<div class="profile-row">
			<div class="profile-avatar" id="profileAvatar" onclick="document.getElementById('profileFileInput').click()">
				<c:choose>
					<c:when test="${not empty profile}">
						<img id="profileImg" src="/files/profile/${profile.fileName}" alt="프로필">
					</c:when>
					<c:otherwise>
						<svg id="profilePlaceholder" viewBox="0 0 24 24" width="42" height="42" fill="none" stroke="currentColor" stroke-width="1.6">
							<rect x="3" y="3" width="18" height="18" rx="3"/>
							<circle cx="8.5" cy="8.5" r="1.5"/>
							<polyline points="21 15 16 10 5 21"/>
						</svg>
					</c:otherwise>
				</c:choose>
			</div>
			<div class="info-group">
				<div class="info-row">
					<span class="info-label">아이디</span> <span class="info-value">${dto.username}</span>
				</div>
				<div class="info-row">
					<span class="info-label">이름</span> <span class="info-value">${dto.name}</span>
				</div>
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
	<script>
		document.getElementById('profileFileInput').addEventListener('change', function() {
			const file = this.files[0];
			if (!file) return;

			const reader = new FileReader();
			reader.onload = function(e) {
				const avatar = document.getElementById('profileAvatar');
				const placeholder = document.getElementById('profilePlaceholder');
				let img = document.getElementById('profileImg');

				if (!img) {
					img = document.createElement('img');
					img.id = 'profileImg';
					if (placeholder) placeholder.remove();
					avatar.appendChild(img);
				}
				img.src = e.target.result;
			};
			reader.readAsDataURL(file);

			const form = new FormData();
			form.append('file', file);
			fetch('/member/profile', { method: 'POST', body: form })
				.then(res => {
					if (res.ok) showToast('사진이 업데이트됐어요');
					else alert('업로드에 실패했습니다.');
				});
		});

		function showToast(msg) {
			const toast = document.createElement('div');
			toast.textContent = msg;
			toast.style.cssText = 'position:fixed;top:24px;left:50%;transform:translateX(-50%) translateY(-20px);background:#1e1e22;color:#fff;padding:12px 22px;border-radius:12px;font-size:14px;box-shadow:0 4px 16px rgba(0,0,0,0.4);z-index:9999;opacity:0;transition:opacity 0.25s,transform 0.25s;';
			document.body.appendChild(toast);
			requestAnimationFrame(() => {
				toast.style.opacity = '1';
				toast.style.transform = 'translateX(-50%) translateY(0)';
			});
			setTimeout(() => {
				toast.style.opacity = '0';
				toast.style.transform = 'translateX(-50%) translateY(-20px)';
				setTimeout(() => toast.remove(), 250);
			}, 2500);
		}
	</script>
</body>
</html>