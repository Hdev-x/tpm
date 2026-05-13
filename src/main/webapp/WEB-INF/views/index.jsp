<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>

    <h2>메인 페이지</h2>
    
    <div>
    <a href="/board/list"><button>게시글</button></a>
    <a href="/notice/list"><button>공지사항</button></a>
    </div>

    <div class="nav-bar">
        <c:if test="${empty member}">
            <a href="/member/login"><button>로그인</button></a>
            <a href="/member/create"><button>회원가입</button></a>
        </c:if>

        <c:if test="${not empty member}">
            <p><strong>${member.username}</strong>님, 반갑습니다!</p>
            <p>보유 잔액: <strong>${member.cash}</strong> 원</p>
            
            <a href="/member/read"><button>내 정보 보기</button></a>
            <a href="/stock/list"><button>주식 시장 보기</button></a>
            <a href="/member/logout"><button>로그아웃</button></a>
        </c:if>
    </div>

</body>
</html>