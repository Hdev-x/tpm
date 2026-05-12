<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>

<h2>마이페이지</h2>
    
        <table>
            <tr>
                <td>아이디</td>
                <td><input type="text" value="${dto.username}" readonly></td>
            </tr>
            <tr>
                <td>이름</td>
                <td><input type="text" value="${dto.name}"></td>
            </tr>
            <tr>
                <td>보유 예수금</td>
                <td>
                    <span class="cash-amount">${dto.cash}</span> 원
                </td>
            </tr>
        </table>

    <br>
    <a href="./update"><button>정보수정</button></a>
    <a href="./order/history"><button>내 거래 내역 보기</button></a>
    <a href="/"><button>메인으로</button></a>

</body>
</html>