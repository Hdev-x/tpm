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
<h2>게시글 작성페이지</h2>

<form action="./create" method="post" enctype="multpart/form-data">
<div>
<label for="boardTitle">제목</label>
<input type="text" id= "boardTitle" name="boardTitle">
</div>

<div>
<label>작성자</label>
<input tabindex="text" value="${member.username}" readonly="readonly">
</div>

<div>
<label for="boardContent">내용</label>
<textarea rows="12" cols="" name="boardContent" id="boardContent"></textarea>
</div>

<div>
<label for="attach">첨부파일</label>
<input type="file" id="attach" name="attach" multiple="multiple">
</div>

<div>
<button type="submit">등록하기</button>
            <a href="./list">취소</a>
</div>
</form>

</body>
</html>