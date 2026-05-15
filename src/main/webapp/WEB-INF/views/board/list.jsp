<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Insert title here</title>
<link rel="stylesheet" href="/css/common.css">
<link rel="stylesheet" href="/css/chart-toss.css">
</head>

<body style="overflow: auto;">
    <%@ include file="../common/nav.jsp" %>

    <!-- margin-top: 60px 추가하여 내비바와 겹침 방지 -->
    <div class="app-wrapper" style="margin-top: 60px; min-height: calc(100vh - 60px); background: var(--bg); display: flex;">
        
        <!-- open 클래스가 있어야 width: 380px가 적용됨 -->
<%@ include file="../common/sidebar.jsp" %>

        <main class="page" style="flex: 1; padding: 40px; display: flex; flex-direction: column;">
            <div class="board-summary" style="margin-bottom: 32px;">
                <h2 class="ph-price" style="font-size: 28px;">커뮤니티</h2>
                <p class="ph-label">투자자들과 실시간으로 정보를 공유해보세요</p>
            </div>

            <!-- 데이터 출력부 -->
            <div class="card" style="padding: 24px;">
                <table class="sb-table">
                    <thead>
                        <tr>
                            <th>번호</th>
                            <th>제목</th>
                            <th>작성자</th>
                            <th style="text-align: right;">조회수</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty list}">
                                <c:forEach items="${list}" var="dto">
                                    <tr onclick="location.href='./detail?boardNo=${dto.boardNo}'" style="cursor: pointer;">
                                        <td style="color: var(--text3);">${dto.boardNo}</td>
                                        <td style="font-weight: 600;">${dto.boardTitle}</td>
                                        <td>${dto.boardWriter}</td>
                                        <td style="text-align: right; color: var(--blue);">${dto.boardView}</td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td colspan="4" style="text-align:center; padding: 40px; color: var(--text3);">게시글이 없습니다.</td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </main>
    </div>
    
    <script src="/js/common.js"></script>
</body>
</html>