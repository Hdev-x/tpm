<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>글 수정 - 커뮤니티</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/board/board.css">
</head>
<body style="overflow: auto;">
    <%@ include file="../common/nav.jsp" %>

    <div style="display: flex; min-height: 100vh; background: var(--background);">
        <%@ include file="../common/sidebar.jsp"%>

        <main class="main-content" style="flex: 1; padding: 40px 24px;">
            <div class="card" style="max-width: 800px; margin: 0 auto; padding: 48px; border-radius: 24px; background: var(--surface);">
                <div class="board-summary" style="margin-bottom: 40px;">
                    <span class="badge badge-new" style="margin-bottom: 12px; display: inline-block;">EDIT</span>
                    <h2 style="font-size: 32px; font-weight: 800; color: var(--text); margin: 0;">게시글 수정</h2>
                    <p style="color: var(--text-grey); margin-top: 12px; font-size: 16px;">내용을 수정하고 완료 버튼을 눌러주세요.</p>
                </div>

                <form action="./update" method="post" enctype="multipart/form-data">
                    <input type="hidden" name="boardNo" value="${detail.boardNo}">

                    <div class="input-group" style="margin-bottom: 32px;">
                        <label style="display: block; margin-bottom: 12px; font-weight: 600; color: var(--text-grey); font-size: 14px;">제목</label>
                        <input type="text" name="boardTitle" value="${detail.boardTitle}" required
                            style="width: 100%; background: var(--surface2); border: 1px solid var(--border); border-radius: 16px; padding: 18px; color: var(--text); outline: none; font-size: 16px;">
                    </div>

                    <div class="input-group" style="margin-bottom: 32px;">
                        <label style="display: block; margin-bottom: 12px; font-weight: 600; color: var(--text-grey); font-size: 14px;">작성자</label>
                        <input type="text" name="boardWriter" value="${detail.boardWriter}" readonly
                            style="width: 100%; background: var(--surface2); border: 1px solid var(--border); border-radius: 16px; padding: 18px; color: var(--text); outline: none; font-size: 16px; opacity: 0.6; cursor: not-allowed;">
                    </div>

                    <div class="input-group" style="margin-bottom: 32px;">
                        <label style="display: block; margin-bottom: 12px; font-weight: 600; color: var(--text-grey); font-size: 14px;">내용</label>
                        <textarea name="boardContent" required
                            style="width: 100%; background: var(--surface2); border: 1px solid var(--border); border-radius: 16px; padding: 18px; color: var(--text); outline: none; font-size: 16px; height: 350px; resize: none; line-height: 1.6;">${detail.boardContent}</textarea>
                    </div>

                    <div class="input-group" style="margin-bottom: 32px;">
                        <label style="display: block; margin-bottom: 12px; font-weight: 600; color: var(--text-grey); font-size: 14px;">현재 첨부파일</label>
                        <div style="background: var(--surface2); padding: 24px; border-radius: 16px; border: 1px solid var(--border); display: flex; gap: 16px; flex-wrap: wrap;">
                            <c:choose>
                                <c:when test="${not empty detail.list}">
                                    <c:forEach items="${detail.list}" var="file">
                                        <img src="/files/${file.fileName}" alt="첨부이미지"
                                            style="width: 120px; height: 120px; object-fit: cover; border-radius: 12px; border: 1px solid var(--border);">
                                    </c:forEach>
                                </c:when>
                                <c:otherwise>
                                    <span style="color: var(--text-grey); font-size: 14px;">첨부된 파일이 없습니다.</span>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>

                    <div class="input-group" style="margin-bottom: 48px;">
                        <label style="display: block; margin-bottom: 12px; font-weight: 600; color: var(--text-grey); font-size: 14px;">새 파일 추가 <span style="font-weight: 400; opacity: 0.7;">(기존 파일은 유지됩니다)</span></label>
                        <input type="file" name="attach" multiple
                            style="width: 100%; background: var(--surface2); border: 1px solid var(--border); border-radius: 16px; padding: 16px; color: var(--text); font-size: 14px;">
                    </div>

                    <div style="display: flex; gap: 16px;">
                        <button type="submit" class="btn-action btn-submit" style="flex: 2; height: auto; padding: 18px 0;">수정 완료</button>
                        <button type="button" class="btn-action btn-list" onclick="history.back()" style="flex: 1; height: auto; padding: 18px 0;">취소</button>
                    </div>
                </form>
            </div>
        </main>
    </div>

    <script src="/js/common.js" defer></script>
    <script src="/js/sidebar-data.js" defer></script>
    <script src="/js/board/board.js"></script>
</body>
</html>
