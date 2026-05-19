<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>자유게시판 - 커뮤니티</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/chart-toss-coin.css">
    <style>
        /* 페이징 네비게이션용 마우스 호버 및 액티브 디자인 정의 */
        .pager-btn {
            padding: 8px 14px;
            text-decoration: none;
            border-radius: 8px;
            font-size: 13px;
            font-weight: bold;
            transition: all 0.2s;
            background: #1c2030;
            border: 1px solid #2a2e39;
            color: #848e9c;
        }
        .pager-btn:hover {
            border-color: #3182f6 !important;
            color: #ffffff !important;
        }
        .pager-btn.active {
            background: #2962ff !important;
            color: #ffffff !important;
            border-color: #2962ff !important;
        }
        
        /* 테이블 행 호버 효과 보강 */
        .sb-table tbody tr:hover {
            background: #222634 !important;
            transform: translateY(-2px);
        }
    </style>
</head>
<body>

<div class="app-wrapper">
    <div class="page">
        <%@ include file="../common/nav.jsp" %>
        
<div class="main-content" style="padding: 40px 20px; max-width: 1200px; margin: 0 auto; font-family: 'Pretendard', sans-serif;">
    
    <div class="notice-summary" style="margin-bottom: 30px;">
        <h3 class="ph-price" style="font-size: 28px;">자유게시판</h3>
        <p class="ph-label" style="color: var(--text-grey); margin-top: 6px;">주식 투자 정보와 일상을 자유롭게 공유하세요 📈</p>
    </div>

    <div class="list-filter" style="display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: 15px; border-bottom: 1px solid var(--border); padding-bottom: 15px;">
        
        <div style="display: flex; gap: 20px;">
            <span class="active" style="font-size: 16px; font-weight: 700; color: var(--text); border-bottom: 2px solid var(--blue); padding-bottom: 13px; margin-bottom: -16px;">
                전체글 <span style="font-size: 13px; font-weight: normal; color: var(--text3); margin-left: 4px;">(${pager.page} page)</span>
            </span>
        </div>
        
        <div style="display: flex; align-items: center; gap: 12px;">
            <form action="./list" method="get" style="display: flex; align-items: center; gap: 8px; margin: 0;">
                <input type="hidden" name="page" value="1">
                
                <select name="kind" style="background: #131722; border: 1px solid var(--border); color: var(--text); padding: 8px 12px; border-radius: 6px; outline: none; font-size: 13px; cursor: pointer; font-family: 'Pretendard', sans-serif;">
                    <option value="v1" ${pager.kind == 'v1' ? 'selected' : ''}>제목</option>
                    <option value="v2" ${pager.kind == 'v2' ? 'selected' : ''}>내용</option>
                    <option value="v3" ${pager.kind == 'v3' ? 'selected' : ''}>작성자</option>
                </select>
                
                <div style="position: relative; display: flex; align-items: center;">
                    <input type="text" name="search" value="${pager.search}" placeholder="검색어 입력" 
                           style="width: 160px; background: #131722; border: 1px solid var(--border); color: var(--text); padding: 8px 12px; border-radius: 6px; outline: none; font-size: 13px; transition: all 0.2s;"
                           onfocus="this.style.width='220px'; this.style.borderColor='var(--blue)';"
                           onblur="if(this.value==='') { this.style.width='160px'; } this.style.borderColor='var(--border)';">
                    <button type="submit" style="position: absolute; right: 10px; background: transparent; border: none; color: #848e9c; cursor: pointer; font-size: 13px; padding: 0;">
                        🔍
                    </button>
                </div>
            </form>
            
            <c:if test="${not empty member}">
                <a href="./create" class="nav-login-btn" style="text-decoration: none; padding: 8px 16px; font-size: 13px; border-radius: 6px; line-height: 1.4;">글쓰기</a>
            </c:if>
        </div>
    </div>

    <c:if test="${not empty pager.search}">
        <div style="margin-bottom: 15px; text-align: right;">
            <a href="./list" style="color: var(--blue); font-size: 12px; text-decoration: none; background: #131722; padding: 4px 10px; border-radius: 4px; border: 1px solid var(--border);">
                🔄 '${pager.search}' 검색 해제
            </a>
        </div>
    </c:if>

    <table class="sb-table" style="width: 100%; border-collapse: separate; border-spacing: 0 12px;">
        <thead>
            <tr style="background: transparent;">
                <th style="padding: 10px 20px; border: none; color: var(--text3); font-weight: 400; text-align: left; width: 80px;">번호</th>
                <th style="padding: 10px 20px; border: none; color: var(--text3); font-weight: 400; text-align: left;">제목</th>
                <th style="padding: 10px 20px; border: none; color: var(--text3); font-weight: 400; text-align: left; width: 120px;">작성자</th>
                <th style="padding: 10px 20px; border: none; color: var(--text3); font-weight: 400; text-align: left; width: 200px;">날짜</th>
                <th style="padding: 10px 20px; border: none; color: var(--text3); font-weight: 400; text-align: right; width: 100px;">조회수</th>
            </tr>
        </thead>
        <tbody>
            <c:choose>
                <c:when test="${not empty list}">
                    <c:forEach items="${list}" var="dto">
                        <tr onclick="location.href='./detail?boardNo=${dto.boardNo}'"
                            style="background: var(--surface); cursor: pointer; transition: all 0.2s ease;">
                            <td style="padding: 20px; border-radius: 16px 0 0 16px; color: var(--text3); font-size: 13px;">
                                ${dto.boardNo}
                            </td>
                            <td style="padding: 20px;">
                                <div style="font-size: 16px; font-weight: 600; color: var(--text);">${dto.boardTitle}</div>
                            </td>
                            <td style="padding: 20px; color: var(--text2); font-size: 14px;">${dto.boardWriter}</td>
                            <td style="padding: 20px; color: var(--text3); font-size: 13px;">${dto.boardDate}</td>
                            <td style="padding: 20px; border-radius: 0 16px 16px 0; text-align: right; font-weight: 600; color: var(--blue);">
                                ${dto.boardView}
                            </td>
                        </tr>
                    </c:forEach>
                </c:when>
                <c:otherwise>
                    <tr>
                        <td colspan="5" style="text-align: center; padding: 100px 0; color: var(--text3);">
                            첫 번째 게시글의 주인공이 되어보세요! 🚀
                        </td>
                    </tr>
                </c:otherwise>
            </c:choose>
        </tbody>
    </table>

    <div style="display: flex; justify-content: center; margin-top: 30px; gap: 6px;">
        <c:if test="${pager.pre}">
            <a href="./list?page=${pager.start - 1}&kind=${pager.kind}&search=${pager.search}" class="pager-btn">이전</a>
        </c:if>

        <c:forEach var="idx" begin="${pager.start}" end="${pager.end}">
            <a href="./list?page=${idx}&kind=${pager.kind}&search=${pager.search}" 
               class="pager-btn ${pager.page == idx ? 'active' : ''}">
                ${idx}
            </a>
        </c:forEach>

        <c:if test="${pager.next}">
            <a href="./list?page=${pager.end + 1}&kind=${pager.kind}&search=${pager.search}" class="pager-btn">다음</a>
        </c:if>
    </div>
</div>
            
    </div>
    <%@ include file="../common/sidebar.jsp" %>
    <%@ include file="../common/sidebar-icons.jsp" %>
</div>
<script src="/js/common.js"></script>
<script src="/js/board.js"></script>
</body>
</html>