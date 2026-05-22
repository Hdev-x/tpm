<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>${detail.noticeTitle} - 공지사항</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/board/board.css">
</head>
<body>

<main class="main-layout">
    <div class="card detail-main-card" style="max-width: 900px; margin: 0 auto;">
        <div class="detail-header">
            <span class="ph-ticker" style="color: var(--blue); font-size: 14px;">자유게시판</span>
            <h1 style="font-size: 36px; margin: 15px 0;">${detail.noticeTitle}</h1>
            <div class="detail-info" style="display: flex; gap: 20px; border-bottom: 1px solid var(--border); padding-bottom: 20px;">
                <span class="ph-label">작성자: <b style="color: var(--text);">${detail.noticeWriter}</b></span>
                <span class="ph-label">날짜: ${detail.noticeDate}</span> 
                <span class="ph-label">조회수: ${detail.noticeView}</span>
            </div>
        </div>

        <div class="detail-body" style="padding: 30px 0; min-height: 200px; font-size: 18px; line-height: 1.8;">
            ${detail.noticeContent}
        </div>

        <div class="detail-images" style="text-align: center; margin-bottom: 40px;">
            <c:forEach items="${detail.list}" var="file">
                <div style="display: inline-block; margin-bottom: 20px;">
                    <img src="/files/${file.fileName}" style="max-width: 70%; height: auto; border-radius: 16px; border: 1px solid var(--border2); box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);">
                </div>
            </c:forEach>
        </div>

        <div class="detail-actions" style="display: flex; justify-content: center; gap: 12px; border-top: 1px solid var(--border); padding-top: 30px; margin-bottom: 40px;">
    <div style="flex: 1;">
        <button class="order-type-btn" style="width: 100px;" onclick="location.href='./list'">목록으로</button>
    </div>

    <c:if test="${member.username eq detail.noticeWriter}">
        <div style="display: flex; gap: 8px;">
            <button class="nav-login-btn" style="width: 100px;" onclick="location.href='./update?noticeNo=${detail.noticeNo}'">수정</button>
            <form action="./delete" method="post" onsubmit="return confirm('정말 삭제하시겠습니까?');">
                <input type="hidden" name="noticeNo" value="${detail.noticeNo}">
                <button type="submit" class="btn-sell" style="width: 100px;">삭제</button>
            </form>
        </div>
    </c:if>
</div>
<!-- 
        <div class="comment-section" style="border-top: 1px solid var(--border); padding-top: 40px;">
            <h3 class="ph-name" style="font-size: 20px; margin-bottom: 24px;">댓글 <span style="color:var(--blue)">0</span></h3>
            
            <div class="comment-write" style="background: var(--surface2); padding: 20px; border-radius: 16px; margin-bottom: 40px;">
                <textarea placeholder="댓글을 작성해주세요" 
                    style="width: 100%; background: transparent; border: none; color: var(--text); outline: none; resize: none; height: 80px; font-size: 15px;"></textarea>
           
            </div>
            <div style="display: flex; justify-content: flex-end; margin-top: 12px;">
                    <button class="nav-login-btn" style="width: 100px;">등록</button>
                </div>

            <div class="comment-list">
                <div class="ph-label" style="text-align: center; padding: 40px 0;">아직 댓글이 없습니다. 첫 댓글을 남겨보세요!</div>
            </div>
        </div> -->
    </div>
</main>

<script src="/js/common.js" defer></script>
	<script src="/js/sidebar-data.js" defer></script>
<script src="/js/board/board.js"></script>
</body>
</html>