<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>${detail.boardTitle} - 커뮤니티</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/board/board.css">
</head>

<body class="chart-page community-page board-community-page" style="overflow: auto;">

    <div class="app-wrapper">
        <div class="page">
            <%@ include file="../common/nav.jsp"%>

            <div class="board-header">
                <div style="max-width: 1400px; margin: 0 auto; width: 100%;">
                    <h1 class="board-title">자유게시판</h1>
                    <p class="board-subtitle">주식 투자 정보와 일상을 자유롭게 공유하세요</p>
                </div>
            </div>

            <div class="main-layout" style="display: block; padding: 40px 50px 80px; height: calc(100vh - 140px); overflow-y: auto; box-sizing: border-box;">
                <div class="card" style="max-width: 900px; margin: 0 auto; padding: 48px; border-radius: 24px; background: var(--surface); border: 1px solid var(--border); box-shadow: 0 4px 20px rgba(0,0,0,0.1);">

                    <div class="detail-header" style="margin-bottom: 32px; border-bottom: 1px solid var(--border); padding-bottom: 32px;">
                        <span class="badge badge-new" style="margin-bottom: 16px; display: inline-block;">자유게시판</span>
                        <h1 style="font-size: 36px; font-weight: 800; color: var(--text); margin: 0; line-height: 1.3;">${detail.boardTitle}</h1>

                        <div class="detail-meta" style="display: flex; gap: 24px; margin-top: 24px; align-items: center;">
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <div style="width: 32px; height: 32px; background: var(--surface2); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700; color: var(--blue);">
                                    <c:out value="${detail.boardWriter.substring(0,1).toUpperCase()}" />
                                </div>
                                <span style="font-weight: 600; color: var(--text);">${detail.boardWriter}</span>
                            </div>
                            <div style="color: var(--text-grey); font-size: 14px; display: flex; gap: 16px;">
                                <span>${detail.boardDate}</span>
                                <span>조회수 ${detail.boardView}</span>
                            </div>
                        </div>
                    </div>

                    <div class="detail-body" style="padding: 16px 0 48px 0; font-size: 18px; line-height: 1.8; color: var(--text);">
                        ${detail.boardContent}
                    </div>

                    <c:if test="${not empty detail.list}">
                        <div class="detail-images" style="display: flex; flex-direction: column; gap: 24px; align-items: center; margin-bottom: 48px;">
                            <c:forEach items="${detail.list}" var="file">
                                <img src="/files/${file.fileName}" alt="첨부이미지"
                                    style="max-width: 100%; border-radius: 20px; border: 1px solid var(--border); box-shadow: 0 10px 30px rgba(0,0,0,0.1);">
                            </c:forEach>
                        </div>
                    </c:if>

                    <div class="like-section" style="margin-bottom: 48px; display: flex; justify-content: center;">
                        <button type="button" id="like-btn" data-board-no="${detail.boardNo}"
                            style="background: var(--surface2); border: 1px solid var(--border); border-radius: 100px; padding: 12px 32px; display: flex; align-items: center; gap: 12px; cursor: pointer; transition: all 0.2s;">
                            <span id="like-icon" style="font-size: 20px;">${myLike != null ? '❤️' : '🤍'}</span>
                            <span style="font-weight: 700; color: var(--text);">좋아요</span>
                            <span id="like-count" style="color: var(--blue); font-weight: 800;">${likeCount}</span>
                        </button>
                    </div>

                    <div class="detail-actions" style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid var(--border); padding-top: 32px; margin-bottom: 64px;">
                        <button type="button" class="order-type-btn" onclick="location.href='./list'" style="width: 120px; padding: 10px 0;">
                            ← 목록으로
                        </button>

                        <c:if test="${member.username eq detail.boardWriter}">
                            <div style="display: flex; gap: 12px;">
                                <button type="button" class="order-type-btn" onclick="location.href='./update?boardNo=${detail.boardNo}'" style="width: 100px; padding: 10px 0;">수정</button>
                                <form action="./delete" method="post" onsubmit="return confirm('정말 삭제하시겠습니까?');" style="margin: 0;">
                                    <input type="hidden" name="boardNo" value="${detail.boardNo}">
                                    <button type="submit" class="btn-sell" style="width: 100px; border-radius: 12px; padding: 10px 0; font-weight: 600;">삭제</button>
                                </form>
                            </div>
                        </c:if>
                    </div>

                    <div class="comment-section">
                        <h3 style="font-size: 22px; font-weight: 800; margin-bottom: 24px;">
                            댓글 <span style="color: var(--blue)">${replyList != null ? replyList.size() : 0}</span>
                        </h3>

                        <form action="/reply/create" method="post" style="margin-bottom: 40px;">
                            <input type="hidden" name="boardNo" value="${detail.boardNo}">
                            <div style="background: var(--surface2); padding: 24px; border-radius: 20px; border: 1px solid var(--border); position: relative;">
                                <textarea name="replyContent" placeholder="댓글을 작성해주세요" required
                                    style="width: 100%; background: transparent; border: none; color: var(--text); outline: none; resize: none; height: 100px; font-size: 16px; line-height: 1.6;"></textarea>
                                <div style="display: flex; justify-content: flex-end; margin-top: 16px;">
                                    <button type="submit" class="nav-login-btn" style="width: 100px; padding: 12px 0; font-weight: 600;">등록</button>
                                </div>
                            </div>
                        </form>

                        <div class="comment-list">
                            <c:choose>
                                <c:when test="${not empty replyList}">
                                    <c:forEach items="${replyList}" var="reply">
                                        <div class="comment-item" style="padding: 24px 0; border-bottom: 1px solid var(--border);">
                                            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                                                <div style="display: flex; align-items: center; gap: 10px;">
                                                    <div style="width: 36px; height: 36px; background: var(--surface2); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 13px; font-weight: 700; color: var(--blue);">
                                                        ${reply.username.substring(0,1).toUpperCase()}
                                                    </div>
                                                    <span style="font-weight: 700; color: var(--text); font-size: 16px;">${reply.username}</span>
                                                    <span style="color: var(--text-grey); font-size: 13px;">
                                                        <fmt:parseDate value="${reply.replyDate}" pattern="yyyy-MM-dd'T'HH:mm" var="parsedReplyDate" type="both" />
                                                        <fmt:formatDate value="${parsedReplyDate}" pattern="MM.dd HH:mm" />
                                                    </span>
                                                </div>

                                                <c:if test="${member.username eq reply.username}">
                                                    <form action="/reply/delete" method="post" onsubmit="return confirm('댓글을 삭제하시겠습니까?');" style="margin: 0;">
                                                        <input type="hidden" name="replyNo" value="${reply.replyNo}">
                                                        <input type="hidden" name="boardNo" value="${detail.boardNo}">
                                                        <button type="submit" style="background: none; border: none; color: #F04452; cursor: pointer; font-size: 13px; font-weight: 600;">삭제</button>
                                                    </form>
                                                </c:if>
                                            </div>
                                            <div style="color: var(--text); font-size: 16px; line-height: 1.6; padding-left: 46px;">
                                                ${reply.replyContent}
                                            </div>
                                        </div>
                                    </c:forEach>
                                </c:when>
                                <c:otherwise>
                                    <div style="text-align: center; padding: 64px 0; color: var(--text-grey);">
                                        <div style="font-size: 40px; margin-bottom: 16px;">📈</div>
                                        아직 댓글이 없습니다. 첫 번째 의견을 남겨보세요!
                                    </div>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>

                </div>
            </div>
        </div>
        <%@ include file="../common/sidebar.jsp" %>
        <%@ include file="../common/sidebar-icons.jsp" %>
    </div>

    <script src="/js/common.js" defer></script>
    <script src="/js/sidebar-data.js" defer></script>
    <script src="/js/board/board.js"></script>
</body>
</html>
