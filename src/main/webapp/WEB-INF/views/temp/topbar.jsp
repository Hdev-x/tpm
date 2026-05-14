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

<nav class="main-nav" style="display: flex; align-items: center; justify-content: space-between; padding: 15px 50px; background: var(--bg); border-bottom: 1px solid var(--border); position: sticky; top: 0; z-index: 1000;">
    <div style="display: flex; align-items: center; gap: 40px;">
        <div class="logo" onclick="location.href='/'" style="cursor:pointer; font-size: 22px; font-weight: 900; color: var(--text);">
            <span style="color: var(--blue);">B</span>조
        </div>
        
        <div class="search-bar" style="position: relative;">
            <input type="text" placeholder="관심 종목을 검색해보세요" 
                   style="width: 300px; background: var(--surface2); border: none; border-radius: 10px; padding: 10px 15px 10px 40px; color: var(--text); outline: none;">
            <span style="position: absolute; left: 15px; top: 50%; transform: translateY(-50%); color: var(--text3);">🔍</span>
        </div>
    </div>

    <div style="display: flex; align-items: center; gap: 25px;">
        <a href="/stock/view" style="text-decoration:none; color: var(--text2); font-weight: 600;">주식</a>
               <a href="/coin/list" style="text-decoration:none; color: var(--text2); font-weight: 600;">코인</a>
        <a href="/board/list" style="text-decoration:none; color: var(--text); font-weight: 600;">커뮤니티</a>
        <div style="width: 1px; height: 20px; background: var(--border);"></div>
        <c:choose>
            <c:when test="${empty member}">
                <a href="/member/login" style="text-decoration:none; color: var(--text3);">로그인</a>
                <button class="nav-login-btn" onclick="location.href='/member/join'">회원가입</button>
            </c:when>
            <c:otherwise>
                <span class="ph-label"><b>${member.username}</b>님</span>
                <button class="nav-login-btn" onclick="toggleSidebar()">내 자산</button>
            </c:otherwise>
        </c:choose>
    </div>
</nav>

</body>
</html>