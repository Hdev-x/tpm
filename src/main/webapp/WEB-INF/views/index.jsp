<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>
<body class="app-wrapper">
	<div class="page">
		<nav>
			<div class="logo">
				<span>B</span>조
			</div>
			<a href="/board/list" class="nav-item">커뮤니티</a> <a
				href="/notice/list" class="nav-item">공지사항</a>

			<div class="nav-right">
				<c:choose>
					<c:when test="${empty member}">
						<a href="/member/login" class="nav-item">로그인</a>
						<a href="/member/create" class="nav-login-btn"
							style="text-decoration: none;">회원가입</a>
					</c:when>

					<c:otherwise>
						<span class="ph-label"
							style="margin-right: 12px; color: var(--text2);"> <strong>${member.username}</strong>님
							환영합니다
						</span>
						<a href="/member/logout" class="nav-item">로그아웃</a>
						<button class="nav-login-btn" onclick="toggleSidebar('invest')">내
							지갑</button>
					</c:otherwise>
				</c:choose>
			</div>
		</nav>

		<main class="main-layout">
			<div class="card board-card"
				style="padding: 40px; text-align: center;">
				<h2 class="ph-price" style="margin-bottom: 30px;">환영합니다!</h2>

				<div style="display: flex; gap: 15px; justify-content: center;">
					<a href="/board/list" class="order-type-btn sel"
						style="text-decoration: none; max-width: 200px;">게시글 보기</a> <a
						href="/stock/view" class="order-type-btn"
						style="text-decoration: none; max-width: 200px;">주식 시장 보기</a>
				</div>
			</div>
		</main>
	</div>

	<div id="sidebar-panel" class="sidebar-panel">
		<div class="sidebar-header">
			<span id="sidebar-title">내 투자현황</span>
			<button class="sb-fold-btn" onclick="closeSidebar()">접기</button>
		</div>
		<div class="order-panel">
			<c:if test="${not empty member}">
				<div class="ph-item" style="margin-bottom: 20px;">
					<span class="ph-label">가용 자산</span> <span class="ph-price"
						style="font-size: 20px;">${member.cash} 원</span>
				</div>
				<button class="btn-buy" onclick="location.href='/member/read'">내
					정보 상세 보기</button>
			</c:if>
			<c:if test="${empty member}">
				<div class="chat-empty">
					<div class="chat-empty-icon">🔒</div>
					로그인이 필요한 서비스입니다.
				</div>
			</c:if>
		</div>
	</div>

	<div class="sidebar-icons">
		<button id="si-invest" class="si-btn"
			onclick="toggleSidebar('invest')">
			<span>자산</span>
		</button>
	</div>
</body>

<link rel="stylesheet" href="/css/chart-toss.css">
</body>
</html>