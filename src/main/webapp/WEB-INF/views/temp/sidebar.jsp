<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>

<div id="right-sidebar" class="card" style="position: fixed; right: -400px; top: 0; width: 350px; height: 100vh; background: var(--surface); z-index: 2000; transition: 0.3s; padding: 30px; box-shadow: -10px 0 30px rgba(0,0,0,0.5);">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 40px;">
        <h3 class="ph-price" style="font-size: 20px;">내 자산</h3>
        <button onclick="toggleSidebar()" style="background:none; border:none; color:var(--text3); cursor:pointer; font-size: 20px;">✕</button>
    </div>

    <div style="margin-bottom: 30px;">
        <p class="ph-label">총 평가액</p>
        <h2 style="font-size: 28px; margin-top: 5px;">124,500,000원</h2>
        <p style="color: var(--red); font-size: 14px; margin-top: 5px;">▲ 1,240,000 (1.2%)</p>
    </div>

    <div class="mini-stock-list" style="display: flex; flex-direction: column; gap: 20px;">
        <p class="ph-label">관심 종목</p>
        <div style="display: flex; justify-content: space-between;">
            <span>삼성전자</span>
            <span style="color: var(--red);">78,400</span>
        </div>
        <div style="display: flex; justify-content: space-between;">
            <span>비트코인</span>
            <span style="color: var(--blue);">98,120,000</span>
        </div>
    </div>
</div>

<script>
    function toggleSidebar() {
        const sb = document.getElementById('right-sidebar');
        if (sb.style.right === '0px') {
            sb.style.right = '-400px';
        } else {
            sb.style.right = '0px';
        }
    }
</script>

</body>
</html>