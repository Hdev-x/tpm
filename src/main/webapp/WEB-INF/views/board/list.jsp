<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>

<body>
	<h2>게시판</h2>
	<table>
		<thead>
			<tr>
				<th>번호</th>
				<th>제목</th>
				<th>작성자</th>
				<th>작성일</th>
				<th>조회수</th>
			</tr>
		</thead>
		<tbody>
			<c:forEach items="${list}" var="dto">
				<tr>
					<td>${dto.boardNo}</td>
					<td><a href="./detail?boardNo=${dto.boardNo}">${dto.boardTitle}</a></td>
					<td>${dto.boardWriter}</td>
					<td>${dto.boardDate}</td>
					<td>${dto.boardView}</td>
				</tr>
			</c:forEach>
			
			<c:if test="${empty list}"></c:if>
		</tbody>
	</table>

	<div class="btn-container">
		<a href="./create" class="write-btn">글쓰기</a>
	</div>

</body>
</html>