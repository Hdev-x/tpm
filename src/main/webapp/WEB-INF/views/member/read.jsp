<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>TradeBot · 마이페이지</title>
<link rel="stylesheet"
	href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
<link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/member/member.css">
<style>
.member-content-wrapper {
	display: flex;
	align-items: center;
	justify-content: center;
	padding: 40px 20px;
	min-height: calc(100vh - 70px);
}

.profile-card {
	width: 100%;
	max-width: 440px;
	padding: 40px;
	background: var(--bg);
	border: 1px solid var(--border);
	border-radius: 20px;
	box-shadow: 0 12px 40px rgba(0, 0, 0, 0.3);
}

.profile-header {
	display: flex;
	align-items: center;
	gap: 24px;
	margin-bottom: 30px;
}

.profile-avatar {
	width: 90px;
	height: 90px;
	border-radius: 24px;
	background: var(--surface);
	display: flex;
	align-items: center;
	justify-content: center;
	color: var(--text3);
	flex-shrink: 0;
	cursor: pointer;
	position: relative;
	overflow: hidden;
	border: 1px solid var(--border2);
}

.profile-avatar img {
	width: 100%;
	height: 100%;
	object-fit: cover;
}

.profile-avatar:hover::after {
	content: '변경';
	position: absolute;
	inset: 0;
	background: rgba(0, 0, 0, 0.6);
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 13px;
	color: #fff;
	font-weight: 600;
}

.profile-info {
	flex: 1;
	display: flex;
	flex-direction: column;
	gap: 6px;
}

.profile-name {
	font-size: 20px;
	font-weight: 700;
	color: var(--text);
}

.profile-id {
	font-size: 14px;
	color: var(--text3);
}

.asset-section {
	display: flex;
	flex-direction: column;
	gap: 12px;
	margin-bottom: 30px;
}

.asset-item {
	background: var(--surface2);
	padding: 20px;
	border-radius: 16px;
	display: flex;
	flex-direction: column;
	gap: 8px;
	border: 1px solid transparent;
	transition: all 0.2s;
}

.asset-item:hover {
	border-color: var(--border2);
	transform: translateY(-2px);
}

.asset-label {
	font-size: 13px;
	color: var(--text3);
	font-weight: 500;
}

.asset-value {
	font-size: 22px;
	font-weight: 800;
	color: var(--text);
	display: flex;
	align-items: baseline;
	gap: 4px;
}

.asset-value small {
	font-size: 14px;
	font-weight: 500;
	color: var(--text3);
}

.total-asset {
	background: rgba(49, 130, 246, 0.05);
	border: 1px solid rgba(49, 130, 246, 0.15);
}

.total-asset .asset-value {
	color: var(--blue);
}

/* 💡 버튼 그룹 스타일 개선 */
.action-group {
	display: flex;
	flex-direction: column;
	gap: 12px;
}

.btn-primary-block {
	width: 100%;
	padding: 14px;
	background: var(--blue);
	color: #fff;
	border: none;
	border-radius: 12px;
	font-size: 15px;
	font-weight: 600;
	cursor: pointer;
	transition: opacity 0.2s;
}

.btn-primary-block:hover {
	opacity: 0.9;
}

.btn-sub-group {
	display: flex;
	gap: 10px;
}

.btn-sub-item {
	flex: 1;
	height: 46px;
	background: var(--surface2);
	border: 1px solid var(--border);
	color: var(--text2);
	border-radius: 12px;
	font-size: 14px;
	font-weight: 600;
	cursor: pointer;
	transition: all 0.2s;
}

.btn-sub-item:hover {
	background: var(--surface);
	border-color: var(--border2);
}

.btn-sub-item.logout {
	color: var(--down);
}
</style>
</head>
<body>

	<div class="app-wrapper">
		<div class="page">
			<!-- 1. 상단 네비게이션 탑바 -->
			<%@ include file="/WEB-INF/views/common/nav.jsp"%>

			<div class="main-content" style="flex: 1; overflow-y: auto;">
				<div class="member-content-wrapper">
					<div class="profile-card">
						<div class="logo"
							style="font-size: 22px; margin-bottom: 30px; letter-spacing: -0.5px;">
							<span>M</span>y Page
						</div>

						<input type="file" id="profileFileInput" accept="image/*"
							style="display: none;">

						<div class="profile-header">
							<div class="profile-avatar" id="profileAvatar"
								onclick="document.getElementById('profileFileInput').click()">
								<c:choose>
									<c:when test="${not empty profile}">
										<img id="profileImg" src="/files/profile/${profile.fileName}"
											alt="프로필">
									</c:when>
									<c:otherwise>
										<svg id="profilePlaceholder" viewBox="0 0 24 24" width="40"
											height="40" fill="none" stroke="currentColor" stroke-width="1.8"
											style="opacity: 0.5;">
				                            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
				                            <circle cx="12" cy="7" r="4"></circle>
				                        </svg>
									</c:otherwise>
								</c:choose>
							</div>
							<div class="profile-info">
								<div class="profile-name">${dto.name}님</div>
								<div class="profile-id">@${dto.username}</div>
							</div>
						</div>

						<div class="asset-section">
							<a href="/stock/asset" style="text-decoration: none; color: inherit;">
								<div class="asset-item total-asset">
									<div class="asset-label"
										style="display: flex; justify-content: space-between; align-items: center;">
										<span>총 평가 자산</span>
										<svg viewBox="0 0 24 24" width="16" height="16"
											stroke="currentColor" stroke-width="2.5" fill="none"
											style="opacity: 0.5;">
				                            <polyline points="9 18 15 12 9 6"></polyline>
				                        </svg>
									</div>
									<div id="totalAssetVal" class="asset-value">
										<span style="font-size: 16px; font-weight: 500; opacity: 0.5;">계산 중...</span>
									</div>
								</div>
							</a>
						</div>

						<!-- 💡 깔끔하게 정리된 버튼 컴포넌트 구조 -->
						<div class="action-group">
							<button class="btn-primary-block" onclick="location.href='./update'">
								정보 수정하기
							</button>
							<div class="btn-sub-group">
								<button class="btn-sub-item" onclick="location.href='/'">
									메인으로
								</button>
								<button class="btn-sub-item logout" onclick="location.href='/member/logout'">
									로그아웃
								</button>
							</div>
						</div>
						
					</div> <!-- /.profile-card -->
				</div> <!-- /.member-content-wrapper -->
			</div> <!-- /.main-content -->
		</div> <!-- /.page -->

		<!-- 3. 우측 사이드바 구조 -->
		<%@ include file="/WEB-INF/views/common/sidebar.jsp"%>
		<%@ include file="/WEB-INF/views/common/sidebar-icons.jsp"%>
	</div> <!-- /.app-wrapper -->

	<script src="/js/common.js" defer></script>
	<script src="/js/sidebar-data.js" defer></script>
	<script>
        async function fetchTotalAsset() {
            try {
                const [stockVal, coinWallet] = await Promise.all([
                    fetch('/stock/my-asset').then(r => r.json()).catch(() => 0),
                    fetch('/coin/wallet').then(r => r.json()).catch(() => ({ usdtBalance: 0 }))
                ]);
                const rate = (typeof usdToKrw !== 'undefined' && usdToKrw > 1) ? usdToKrw : 1400;
                const coinKrw = Math.floor((coinWallet?.usdtBalance || 0) * rate);
                const total = (stockVal || 0) + coinKrw;
                const el = document.getElementById('totalAssetVal');
                if (el) el.innerHTML = Number(total).toLocaleString() + ' <small>원</small>';
            } catch (e) {
                console.error("자산 정보 로드 실패", e);
            }
        }

        document.addEventListener('DOMContentLoaded', () => {
            fetchTotalAsset();
            setInterval(fetchTotalAsset, 15000);
        });

        const profileFileInput = document.getElementById('profileFileInput');
        if (profileFileInput) {
            profileFileInput.addEventListener('change', function() {
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
        }

        function showToast(msg) {
            const card = document.querySelector('.profile-card');
            const rect = card ? card.getBoundingClientRect() : null;
            const cx = rect ? rect.left + rect.width / 2 : window.innerWidth / 2;
            const ty = rect ? rect.top - 12 : 80;

            const toast = document.createElement('div');
            toast.textContent = msg;
            Object.assign(toast.style, {
                position: 'fixed',
                left: cx + 'px',
                top: ty + 'px',
                transform: 'translateX(-50%) translateY(calc(-100% - 8px))',
                background: '#1e1e22',
                color: '#fff',
                padding: '12px 22px',
                borderRadius: '12px',
                fontSize: '14px',
                whiteSpace: 'nowrap',
                boxShadow: '0 4px 16px rgba(0,0,0,0.4)',
                zIndex: '9999',
                opacity: '0',
                transition: 'opacity 0.25s, transform 0.25s',
                pointerEvents: 'none'
            });
            document.body.appendChild(toast);
            requestAnimationFrame(() => requestAnimationFrame(() => {
                toast.style.opacity = '1';
                toast.style.transform = 'translateX(-50%) translateY(-100%)';
            }));
            setTimeout(() => {
                toast.style.opacity = '0';
                toast.style.transform = 'translateX(-50%) translateY(calc(-100% - 8px))';
                setTimeout(() => toast.remove(), 250);
            }, 2500);
        }
    </script>
</body>
</html>