<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Insert title here</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
</head>
<body>

<main class="main-layout" style="max-width: 800px; margin: 0 auto; padding-top: 50px;">
    <div class="card" style="padding: 40px;">
        <div class="notice-summary" style="margin-bottom: 30px;">
            <h2 class="ph-price" style="font-size: 24px;">게시글 수정</h2>
            <p class="ph-label">내용을 수정하고 완료 버튼을 눌러주세요.</p>
        </div>

        <form action="./update" method="post" enctype="multipart/form-data">
            <input type="hidden" name="noticeNo" value="${detail.noticeNo}">

            <div class="input-group">
                <label class="input-label">제목</label>
                <input type="text" name="noticeTitle" class="member-input" 
                       value="${detail.noticeTitle}" style="width: 100%;">
            </div>

            <div class="input-group">
                <label class="input-label">작성자</label>
                <input type="text" name="noticeWriter" class="member-input" 
                       value="${detail.noticeWriter}" readonly style="width: 100%; opacity: 0.6; cursor: not-allowed;">
            </div>

            <div class="input-group">
                <label class="input-label">내용</label>
                <textarea name="noticeContent" class="member-input" 
                          style="width: 100%; height: 250px; resize: none; line-height: 1.6; padding: 15px;">${detail.noticeContent}</textarea>
            </div>

            <div class="input-group">
                <label class="input-label">현재 첨부파일</label>
                <div style="background: var(--surface2); padding: 15px; border-radius: 12px; display: flex; gap: 10px; flex-wrap: wrap;">
                    <c:choose>
                        <c:when test="${not empty detail.list}">
                            <c:forEach items="${detail.list}" var="file">
                                <div style="position: relative;">
                                    <img src="/files/${file.fileName}" 
                                         style="width: 100px; height: 100px; object-fit: cover; border-radius: 8px; border: 1px solid var(--border2);">
                                </div>
                            </c:forEach>
                        </c:when>
                        <c:otherwise>
                            <span style="color: var(--text3); font-size: 13px;">첨부된 파일이 없습니다.</span>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>

            <div class="input-group" style="margin-top: 20px;">
                <label class="input-label">새 파일 추가 (기존 파일은 유지됩니다)</label>
                <input type="file" name="attach" multiple class="member-input" style="width: 100%; font-size: 13px;">
            </div>

            <div style="display: flex; gap: 10px; margin-top: 40px;">
                <button type="submit" class="nav-login-btn" style="flex: 2; height: 50px;">수정 완료</button>
                <button type="button" class="order-type-btn" onclick="history.back()" style="flex: 1; height: 50px;">취소</button>
            </div>
        </form>
    </div>
</main>

<script src="/js/common.js" defer></script>
	<script src="/js/sidebar-data.js" defer></script>
</body>
</html>