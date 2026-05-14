<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Insert title here</title>
    <link rel="stylesheet" href="/css/chart-toss.css">
    <link rel="stylesheet" href="/css/board.css">
</head>
<body>
<c:import url="/WEB-INF/views/temp/topbar.jsp" />
    <c:import url="/WEB-INF/views/temp/sidebar.jsp" />

<main class="main-layout" style="display: flex; gap: 30px; padding: 40px 50px; align-items: flex-start;">
    
    <div style="flex: 7;">
        <div class="board-summary" style="margin-bottom: 30px;">
            <h2 class="ph-price" style="font-size: 28px;">커뮤니티</h2>
            <p class="ph-label">투자자들과 실시간으로 정보를 공유해보세요</p>
        </div>

        <div class="card board-main-card" style="border: none; background: transparent;">
            <div class="list-filter" style="display: flex; justify-content: space-between; align-items: center; padding-bottom: 20px;">
                <div style="display: flex; gap: 20px;">
                    <span class="active" style="font-size: 16px; font-weight: 700; color: var(--text); border-bottom: 2px solid var(--text); padding-bottom: 5px;">전체글</span>
                    <span style="font-size: 16px; font-weight: 700; color: var(--text3);">인기글</span>
                </div>
                <a href="./create" class="nav-login-btn" style="text-decoration:none;">글쓰기</a>
            </div>

            <table class="sb-table" style="width: 100%; border-collapse: separate; border-spacing: 0 10px;">
                </table>
        </div>
    </div>

    <div style="flex: 3; display: flex; flex-direction: column; gap: 20px; position: sticky; top: 100px;">
        
        <div class="card" style="padding: 24px;">
            <h3 class="ph-name" style="font-size: 16px; margin-bottom: 15px;">실시간 인기 종목</h3>
            <div class="stock-item" style="display: flex; justify-content: space-between; margin-bottom: 12px;">
                <span class="ph-label">1. 삼성전자</span>
                <span style="color:var(--red)">+1.2%</span>
            </div>
            <div class="stock-item" style="display: flex; justify-content: space-between; margin-bottom: 12px;">
                <span class="ph-label">2. SK하이닉스</span>
                <span style="color:var(--red)">+3.5%</span>
            </div>
            <div class="stock-item" style="display: flex; justify-content: space-between;">
                <span class="ph-label">3. 에코프로</span>
                <span style="color:var(--blue)">-2.1%</span>
            </div>
        </div>

        <div class="card" style="padding: 24px; background: linear-gradient(135deg, #1e2227 0%, #252a30 100%);">
            <h3 class="ph-name" style="font-size: 16px; margin-bottom: 10px;">📊 투자 원칙</h3>
            <p class="ph-label" style="font-size: 13px; line-height: 1.6;">
                근거 없는 비방이나 허위 사실 유포 시 이용이 제한될 수 있습니다. 깨끗한 커뮤니티를 함께 만들어요.
            </p>
        </div>

    </div>
</main>


    <script src="/js/common-ui.js"></script>
    <script src="/js/board.js"></script>
</body>
</html>