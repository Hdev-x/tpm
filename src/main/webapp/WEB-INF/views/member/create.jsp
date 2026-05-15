<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<link rel="stylesheet" href="/css/common.css">
<link rel="stylesheet" href="/css/chart-toss-coin.css">
</head>
<body class="member-layout">

	<div class="card member-card">
		<div class="member-logo" onclick="location.href='/'" style="cursor:pointer;"><span>B</span>조</div>

		<form action="./create" method="post" id="joinForm">
			<div class="input-group">
    <label class="input-label">아이디</label> 
    <input type="text" name="username" value="${memberDTO.username}" 
           class="member-input" placeholder="아이디를 입력하세요" required>
    
    <spring:hasBindErrors name="memberDTO">
        <c:if test="${errors.hasFieldErrors('username')}">
            <span style="color: var(--up); font-size: 11px; margin-top: 6px; font-weight: 600;">
                ${errors.getFieldError('username').defaultMessage}
            </span>
        </c:if>
    </spring:hasBindErrors>
</div>

			<div class="input-group">
				<label class="input-label">비밀번호</label> <input type="password"
					name="password" id="password" class="member-input"
					placeholder="비밀번호 (8자 이상)" required>
			</div>

			<div class="input-group">
				<label class="input-label">이름</label> <input type="text" name="name"
					class="member-input" placeholder="이름을 입력하세요" required>
			</div>

			<div class="input-group">
				<label class="input-label">이메일</label> <input type="email"
					name="email" class="member-input" placeholder="kosmo@kosmo.com"
					required>
			</div>

			<button type="submit" class="member-btn">회원가입 완료</button>
		</form>

		<div class="member-footer">
			이미 계정이 있으신가요? <a href="/member/login">로그인하기</a>
		</div>
	</div>

	<script src="/js/common.js"></script>
	<script src="/js/member.js"></script>
</body>
</html>