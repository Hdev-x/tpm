<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>

    <h2>회원가입 페이지</h2>
    <form action="./create" method="post">
        <div>
            <table>
                <tr>
                    <td>아이디</td>
                    <td><input type="text" name="username"></td>
                </tr>
                <tr>
                    <td>비밀번호</td>
                    <td><input type="password" name="password" required></td>
                </tr>
                <tr>
                    <td>이름</td>
                    <td><input type="text" name="name" required></td>
                </tr>
                <tr>
                    <td colspan="2" align="center">
                        <button type="submit">가입하기</button>
                    </td>
                </tr>
            </table>
            
        </div>
    </form>

</body>
</html>