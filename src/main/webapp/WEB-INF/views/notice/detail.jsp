<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>${detail.noticeTitle} - 공지사항</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/chart-toss-coin.css">
    <link rel="stylesheet" href="/css/coinCommunity.css"> </head>

<body class="chart-page community-page board-community-page" style="overflow: auto;">
    
    <div class="app-wrapper">
        <div class="page">
            <%@ include file="../common/nav.jsp"%>

            <div class="board-header">
                <div style="max-width: 1400px; margin: 0 auto; width: 100%;">
                    <h1 class="board-title">공지사항</h1>
                    <p class="board-subtitle">중요한 플랫폼 소식과 안내 사항을 확인하세요.</p>
                </div>
            </div>

            <div class="main-layout" style="display: block; padding: 40px 50px 80px; height: calc(100vh - 140px); overflow-y: auto; box-sizing: border-box;">
                <div class="card" style="max-width: 900px; margin: 0 auto; padding: 48px; border-radius: 24px; background: var(--surface); border: 1px solid var(--border); box-shadow: 0 4px 20px rgba(0,0,0,0.1);">
                    
                    <div class="detail-header" style="margin-bottom: 32px; border-bottom: 1px solid var(--border); padding-bottom: 32px;">
                        <span class="badge badge-notice" style="margin-bottom: 16px; display: inline-block;">공지사항</span>
                        <h1 style="font-size: 36px; font-weight: 800; color: var(--text); margin: 0; line-height: 1.3;">${detail.noticeTitle}</h1>
                        
                        <div class="detail-meta" style="display: flex; gap: 24px; margin-top: 24px; align-items: center;">
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <div style="width: 32px; height: 32px; background: rgba(240, 68, 82, 0.1); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700; color: #F04452;">
                                    A
                                </div>
                                <span style="font-weight: 600; color: var(--text);">관리자</span>
                            </div>
                            <div style="color: var(--text-grey); font-size: 14px; display: flex; gap: 16px;">
                                <span>${detail.noticeDate}</span>
                                <span>조회수 ${detail.noticeView}</span>
                            </div>
                        </div>
                    </div>

                    <div class="detail-body" style="padding: 16px 0 48px 0; font-size: 18px; line-height: 1.8; color: var(--text);">
                        ${detail.noticeContent}
                    </div>

                    <c:if test="${not empty detail.list}">
                        <div class="detail-images" style="display: flex; flex-direction: column; gap: 24px; align-items: center; margin-bottom: 48px;">
                            <c:forEach items="${detail.list}" var="file">
                                <img src="/files/${file.fileName}" alt="첨부이미지"
                                    style="max-width: 100%; border-radius: 20px; border: 1px solid var(--border); box-shadow: 0 10px 30px rgba(0,0,0,0.1);">
                            </c:forEach>
                        </div>
                    </c:if>

                    <div class="detail-actions" style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid var(--border); padding-top: 32px;">
                        <button type="button" class="order-type-btn" onclick="location.href='./list'" style="width: 120px; padding: 10px 0;">
                            ← 목록으로
                        </button>

                        <c:if test="${member.username eq detail.noticeWriter}">
                            <div style="display: flex; gap: 12px;">
                                <button type="button" class="order-type-btn" onclick="location.href='./update?noticeNo=${detail.noticeNo}'" style="width: 100px; padding: 10px 0;">수정</button>
                                <form action="./delete" method="post" onsubmit="return confirm('정말 삭제하시겠습니까?');" style="margin: 0;">
                                    <input type="hidden" name="noticeNo" value="${detail.noticeNo}">
                                    <button type="submit" class="btn-sell" style="width: 100px; border-radius: 12px; padding: 10px 0; font-weight: 600;">삭제</button>
                                </form>
                            </div>
                        </c:if>
                    </div>
                </div>
            </div>
        </div> <%@ include file="../common/sidebar.jsp" %>
        <%@ include file="../common/sidebar-icons.jsp" %>
    </div>
    <script src="/js/common.js"></script>
    <script src="/js/board.js"></script>
</body>
</html>