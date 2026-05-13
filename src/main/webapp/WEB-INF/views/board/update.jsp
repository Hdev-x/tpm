<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>
	<h2>수정 페이지</h2>

	<form action="./update" method="post" enctype="multipart/form-data">
		<input type="hidden" name="boardNo" value="${detail.boardNo}">

		<table>
			<tr>
				<th>제목</th>
				<td><input type="text" name="boardTitle"
					value="${detail.boardTitle}"></td>
			</tr>
			<tr>
				<th>작성자</th>
				<td><input type="text" name="boardWriter"
					value="${detail.boardWriter}" readonly></td>
			</tr>
			<tr>
				<th>내용</th>
				<td><textarea name="boardContent" rows="10">${detail.boardContent}</textarea>
				</td>
			</tr>

			<tr>
				<th>첨부파일</th>
				<td><c:choose>
						<c:when test="${not empty detail.list}">
							<c:forEach items="${detail.list}" var="file">

							</c:forEach>
						</c:when>
						<c:otherwise>
							<span style="color: #ccc;">첨부된 파일이 없습니다.</span>
						</c:otherwise>
					</c:choose></td>
			</tr>
			
			<tr>
				<th>새 파일 추가</th>
				<td><input type="file" name="attach" multiple></td>
			</tr>
		</table>

		<div>
			<button type="submit">수정 완료</button>
			<button type="button" onclick="history.back()">취소</button>
		</div>
	</form>
	</div>

</body>
</html>