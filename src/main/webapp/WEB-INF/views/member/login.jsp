<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Insert title here</title>
    
<link rel="stylesheet" href="/css/common.css">
<link rel="stylesheet" href="/css/chart-toss.css">
</head>
<body class="member-layout">

    <div class="card member-card">
        <div class="member-logo" onclick="location.href='/'" style="cursor:pointer;"><span>B</span>조</div>
        
        <form action="./login" method="post" id="loginForm">
            <div class="input-group">
                <label class="input-label">아이디</label>
                <input type="text" name="username" class="member-input" placeholder="아이디를 입력하세요" required>
            </div>
            
            <div class="input-group">
                <label class="input-label">비밀번호</label>
                <input type="password" name="password" class="member-input" placeholder="비밀번호를 입력하세요" required>
            </div>
            
            <button type="submit" class="member-btn">로그인</button>
        </form>

        <div class="member-footer">
            계정이 없으신가요? <a href="/member/create">회원가입</a>
        </div>
    </div>

	<script src="/js/common.js"></script>
    <script src="/js/member.js"></script>
</body>
</html>