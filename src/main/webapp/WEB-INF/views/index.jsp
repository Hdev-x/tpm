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
</head> 	
<body class="app-wrapper">
    <div class="page">
        <nav>
            <div class="logo"><span>B</span>조</div>
            <a href="/board/list" class="nav-item">커뮤니티</a>
            <a href="/notice/list" class="nav-item">공지사항</a>
            <div class="nav-right">
                <c:choose>
                    <c:when test="${empty member}">
                        <a href="/member/login" class="nav-item">로그인</a>
                        <a href="/member/create" class="nav-login-btn" style="text-decoration: none;">회원가입</a>
                    </c:when>
                    <c:otherwise>
                        <span class="ph-label" style="margin-right: 12px; color: var(--text2);">
                            <strong>${member.username}</strong>님 환영합니다
                        </span>
                        <a href="/member/logout" class="nav-item">로그아웃</a>
                        <button class="nav-login-btn" onclick="toggleSidebar('invest')">내 지갑</button>
                    </c:otherwise>
                </c:choose>
            </div>
        </nav>

        <main class="main-layout">
            <div class="card board-card" style="padding: 40px; text-align: center; width: 100%;">
                <h2 class="ph-price" style="margin-bottom: 30px;">환영합니다!</h2>
                <div style="display: flex; gap: 15px; justify-content: center;">
                    <a href="/board/list" class="order-type-btn sel" style="text-decoration: none; max-width: 200px;">게시글 보기</a>
                    <a href="/stock/view" class="order-type-btn" style="text-decoration: none; max-width: 200px;">주식 시장 보기</a>
                </div>
            </div>
        </main>
    </div>

    <div id="sidebar-panel" class="sidebar-panel">
        <div class="sidebar-header">
            <span id="sidebar-title">내 투자현황</span>
            <div class="sidebar-header-btns">
                <button class="sb-fold-btn" onclick="closeSidebar()">접기</button>
            </div>
        </div>

        <div class="sb-tabs">
            <div class="sb-tab active" onclick="switchBpTab(this, 'positions')">포지션</div>
            <div class="sb-tab" onclick="switchBpTab(this, 'orders')">주문</div>
            <div class="sb-tab" onclick="switchBpTab(this, 'history')">기록</div>
        </div>

        <div class="sb-content">
            <div id="tab-positions" class="sb-table-wrap">
                <c:if test="${not empty member}">
                    <div style="padding: 16px; border-bottom: 1px solid var(--border);">
                        <span class="ph-label">가용 자산</span>
                        <div class="ph-price" style="font-size: 20px; margin-top: 4px;">${member.cash} 원</div>
                    </div>
                </c:if>
                <table class="sb-table">
                    <thead>
                        <tr><th>종목</th><th>수량</th><th>수익률</th></tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${empty member}">
                                <tr><td colspan="3" class="sb-empty">로그인이 필요합니다.</td></tr>
                            </c:when>
                            <c:otherwise>
                                <tr><td colspan="3" class="sb-empty">보유한 종목이 없습니다.</td></tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
            <div id="tab-orders" style="display: none;"></div>
            <div id="tab-history" style="display: none;"></div>
        </div>
    </div>

    <div class="sidebar-icons">
        <button id="si-invest" class="si-btn" onclick="toggleSidebar('invest')">
            <span>자산</span>
        </button>
    </div>

    <script src="/js/common.js"></script>
</body>
</html>