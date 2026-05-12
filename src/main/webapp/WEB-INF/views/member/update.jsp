<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>

    <h2>내 정보 수정</h2>
    
    <form action="./update" method="post">
        <table>
            <tr>
                <td>아이디</td>
                <td><input type="text" name="username" value="${dto.username}" readonly></td>
            </tr>
            <tr>
                <td>이름</td>
                <td><input type="text" name="name" value="${dto.name}"></td>
            </tr>
            <tr>
                <td>보유 자산</td>
                <td><input type="number" name="cash" value="${dto.cash}"></td>
            </tr>
            <tr>
                <td colspan="2" align="center">
                    <button type="submit">수정 완료</button>
                    <a href="./read"><button type="button">취소</button></a>
                </td>
            </tr>
        </table>
    </form>

</body>
</html>