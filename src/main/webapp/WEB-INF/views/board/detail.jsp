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
	<h2>게시글 세부사항 페이지</h2>
	
	<div>
		작성자: <strong>${detail.boardWriter}</strong> 
		작성일: ${detail.boardDate}
		조회수: ${detail.boardView}
	</div>

	<div>${detail.boardContent}</div>

	<c:if test="${not empty detail.list}">
		<div>
			<strong>첨부파일</strong>
			<c:forEach items="${detail.list}" var="fileDTO">
				<li><a href="/file/download?fileNo=${fileDTO.fileNo}">
						${fileDTO.oriName} </a></li>
			</c:forEach>
		</div>
	</c:if>

	<div>
    <a href="./list">목록으로</a>
    
    <c:if test="${not empty member}">
        <c:if test="${(member.username eq detail.boardWriter)}">
            <a href="./update?boardNo=${detail.boardNo}">수정</a>
            
            <form action="./delete" method="post">
                <input type="hidden" name="boardNo" value="${detail.boardNo}">
                <button type="submit" onclick="return confirm('정말 삭제하시겠습니까?')">삭제</button>
            </form>
        </c:if>
    </c:if>
</div>

</body>
</html>