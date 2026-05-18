<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Dashboard</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/chart-toss-coin.css">
</head>
<body>

<div class="app-wrapper">
    <div class="page">
        <%@ include file="common/nav.jsp" %>

        <div class="main-content">
            <main class="main-layout">
                <div class="card board-card" style="padding: 30px; margin-bottom: 20px;">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <h2 class="ph-price" style="font-size: 24px;">안녕하세요</h2>
                            <p style="color: var(--text-grey); margin-top: 8px;">오늘의 시장 상황을 확인해보세요.</p>
                        </div>
                        <div style="display: flex; gap: 10px;">
                            <a href="/board/list" class="order-type-btn sel">커뮤니티</a>
                            <a href="/stock/view" class="order-type-btn">거래소 가기</a>
                        </div>
                    </div>
                </div>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                    <div class="card" style="padding: 20px;">
                        <div class="chart-header" style="display: flex; justify-content: space-between; margin-bottom: 15px;">
                            <div>
                                <span style="font-size: 14px; color: var(--text-grey);">KOSPI</span>
                                <h3 id="idx-kospi-price" style="font-size: 20px; margin-top: 5px;">2,500.00</h3>
                            </div>
                            <span id="idx-kospi-change" class="ph-change" style="font-size: 14px; color: #F04452;">0.00%</span>
                        </div>
                        <div id="kospi-mini-chart" style="height: 180px;"></div>
                    </div>

                    <div class="card" style="padding: 20px;">
                        <div class="chart-header" style="display: flex; justify-content: space-between; margin-bottom: 15px;">
                            <div>
                                <span style="font-size: 14px; color: var(--text-grey);">BITCOIN</span>
                                <h3 id="idx-btc-price" style="font-size: 20px; margin-top: 5px;">90,000,000</h3>
                            </div>
                            <span id="idx-btc-change" class="ph-change" style="font-size: 14px; color: #3182F6;">0.00%</span>
                        </div>
                        <div id="btc-mini-chart" style="height: 180px;"></div>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <%@ include file="common/sidebar.jsp" %>
    <%@ include file="common/sidebar-icons.jsp" %>
</div>

<script>
    // 1. 사이드바 최초 방문 기록 제어 (가장 먼저 실행)
    if (!sessionStorage.getItem('visited')) {
        sessionStorage.setItem('visited', 'true');
        document.body.setAttribute('data-sidebar-closed', 'true');
    }

    // 2. index.js에서 사용할 전역 금융 변수 명시적 선언 (Uncaught ReferenceError 방지)
let currentKospiPrice = 7500.00;
    let currentBtcPrice = 90000000;
</script>

<script src="https://unpkg.com/lightweight-charts/dist/lightweight-charts.standalone.production.js"></script>
<script src="/js/common.js"></script>
<script src="/js/index.js"></script>

</body>
</html>