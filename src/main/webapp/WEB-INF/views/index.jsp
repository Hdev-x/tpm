<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
<link rel="stylesheet" href="/css/common.css">
<link rel="stylesheet" href="/css/chart-toss.css">
</head>
<body>

<div class="app-wrapper">
    <div class="page">
        <%@ include file="common/nav.jsp" %>

        <div class="main-content">
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
    </div>

    <%@ include file="common/sidebar.jsp" %>
    <%@ include file="common/sidebar-icons.jsp" %>

</div>

<script>
if (!sessionStorage.getItem('visited')) {
    sessionStorage.setItem('visited', 'true');
    document.body.setAttribute('data-sidebar-closed', 'true');
}
</script>
<script src="/js/common.js"></script>
</body>
</html>
