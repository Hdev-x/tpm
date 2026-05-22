<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>자유게시판 - 커뮤니티</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/board/board.css">
    <link rel="stylesheet" href="/css/community.css">
    <style>
        .board-community-page .board-header {
            min-height: 140px;
            padding: 40px 50px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            background: linear-gradient(135deg, #1c2030 0%, #252a3d 100%);
            border-bottom: 1px solid var(--border);
            margin-bottom: 0;
        }

        .board-community-page .board-title {
            margin: 0;
            font-size: 32px;
            font-weight: 800;
            color: var(--text);
            letter-spacing: -0.5px;
        }

        .board-community-page .board-subtitle {
            margin: 12px 0 0;
            font-size: 16px;
            color: var(--text-grey);
            opacity: 0.8;
        }

        .board-community-page .main-layout {
            display: grid;
            grid-template-columns: 1fr 340px;
            gap: 24px;
            padding: 32px 50px 80px;
            max-width: 1400px;
            margin: 0 auto;
        }

        .board-feed-panel {
            background: var(--surface);
            border-radius: 24px;
            border: 1px solid var(--border);
            overflow: hidden;
            display: flex;
            flex-direction: column;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }

        .board-toolbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 24px 32px;
            border-bottom: 1px solid var(--border);
        }

        .board-tabs {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .board-tab {
            font-size: 15px;
            font-weight: 700;
            color: var(--text);
            padding: 8px 16px;
            border-radius: 12px;
            background: var(--surface2);
            border: 1px solid var(--border);
        }

        .board-page-chip {
            font-size: 13px;
            color: var(--text-grey);
            background: rgba(255,255,255,0.05);
            padding: 4px 10px;
            border-radius: 20px;
        }

        .board-tools {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .board-search-form {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .board-select {
            height: 44px;
            background: var(--surface2);
            border: 1px solid var(--border);
            color: var(--text);
            border-radius: 12px;
            padding: 0 12px;
            font-size: 14px;
            outline: none;
        }

        .board-search-box {
            position: relative;
        }

        .board-search-input {
            width: 200px;
            height: 44px;
            background: var(--surface2);
            border: 1px solid var(--border);
            color: var(--text);
            border-radius: 12px;
            padding: 0 44px 0 16px;
            font-size: 14px;
            outline: none;
            transition: all 0.2s;
        }

        .board-search-input:focus {
            width: 260px;
            border-color: var(--blue);
            box-shadow: 0 0 0 3px rgba(49, 130, 246, 0.1);
        }

        .board-search-btn {
            position: absolute;
            right: 12px;
            top: 50%;
            transform: translateY(-50%);
            background: transparent;
            border: none;
            color: var(--text-grey);
            cursor: pointer;
            font-size: 16px;
        }

        .board-write-btn {
            height: 44px;
            padding: 0 24px;
            background: var(--blue);
            color: white;
            border-radius: 12px;
            font-weight: 700;
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: transform 0.2s;
        }
        .board-write-btn:hover { transform: translateY(-2px); }

        .board-list-wrap {
            padding: 0;
        }

        .board-table {
            width: 100%;
            border-collapse: collapse;
        }

        .board-table th {
            padding: 16px 24px;
            background: rgba(255,255,255,0.02);
            color: var(--text-grey);
            font-size: 13px;
            font-weight: 600;
            text-align: left;
            border-bottom: 1px solid var(--border);
        }

        .board-table td {
            padding: 20px 24px;
            border-bottom: 1px solid var(--border);
            color: var(--text);
            font-size: 15px;
        }

        .board-row {
            cursor: pointer;
            transition: all 0.2s;
        }

        .board-row:hover {
            background: rgba(49, 130, 246, 0.03);
        }

        .board-post-title {
            font-weight: 600;
            color: var(--text);
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .board-writer-info {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .writer-avatar {
            width: 24px;
            height: 24px;
            background: var(--surface2);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 10px;
            font-weight: 700;
            color: var(--blue);
        }

        .board-pager {
            display: flex;
            justify-content: center;
            gap: 8px;
            padding: 40px 0;
        }

        .pager-btn {
            min-width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 12px;
            background: var(--surface2);
            border: 1px solid var(--border);
            color: var(--text-grey);
            text-decoration: none;
            font-weight: 600;
            transition: all 0.2s;
        }

        .pager-btn:hover:not(.active) {
            border-color: var(--blue);
            color: var(--text);
        }

        .pager-btn.active {
            background: var(--blue);
            color: white;
            border-color: var(--blue);
            box-shadow: 0 4px 12px rgba(49, 130, 246, 0.3);
        }

        .cm-news-panel {
            background: var(--surface);
            border-radius: 24px;
            border: 1px solid var(--border);
            padding: 24px;
            height: fit-content;
        }
    </style>
</head>
<body class="chart-page community-page board-community-page">
    <div class="app-wrapper">
        <div class="page">
            <%@ include file="../common/nav.jsp" %>

            <div style="height: calc(100vh - 70px); overflow-y: auto; scrollbar-width: none;">
            <div class="board-header">
                <div style="max-width: 1400px; margin: 0 auto; width: 100%;">
                    <h1 class="board-title">자유게시판</h1>
                    <p class="board-subtitle">주식 투자 정보와 일상을 자유롭게 공유하세요</p>
                </div>
            </div>

            <div class="main-layout">
                <div class="board-feed-panel">
                    <div class="board-toolbar">
                        <div class="board-tabs">
                            <span class="board-tab">전체글</span>
                            <span class="board-page-chip">${pager.page} / ${pager.totalPage} Page</span>
                        </div>

                        <div class="board-tools">
                            <form action="./list" method="get" class="board-search-form">
                                <input type="hidden" name="page" value="1">
                                <select name="kind" class="board-select">
                                    <option value="v1" ${pager.kind == 'v1' ? 'selected' : ''}>제목</option>
                                    <option value="v2" ${pager.kind == 'v2' ? 'selected' : ''}>내용</option>
                                    <option value="v3" ${pager.kind == 'v3' ? 'selected' : ''}>작성자</option>
                                </select>
                                <div class="board-search-box">
                                    <input type="text" name="search" value="${pager.search}" placeholder="검색어 입력" class="board-search-input">
                                    <button type="submit" class="board-search-btn">🔍</button>
                                </div>
                            </form>

                            <c:if test="${not empty member}">
                                <a href="./create" class="board-write-btn">
                                    <span>+</span> 글쓰기
                                </a>
                            </c:if>
                        </div>
                    </div>

                    <div class="board-list-wrap">
                        <table class="board-table">
                            <thead>
                                <tr>
                                    <th style="width: 80px; text-align: center;">번호</th>
                                    <th>제목</th>
                                    <th style="width: 140px;">작성자</th>
                                    <th style="width: 120px; text-align: center;">날짜</th>
                                    <th style="width: 100px; text-align: center;">조회수</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:choose>
                                    <c:when test="${not empty list}">
                                        <c:forEach items="${list}" var="dto">
                                            <tr class="board-row" onclick="location.href='./detail?boardNo=${dto.boardNo}'">
                                                <td style="text-align: center; color: var(--text-grey); font-size: 13px;">${dto.boardNo}</td>
                                                <td>
                                                    <div class="board-post-title">
                                                        ${dto.boardTitle}
                                                        <c:if test="${not empty dto.list}">
                                                            <span style="font-size: 12px; color: var(--blue);">🖼️</span>
                                                        </c:if>
                                                    </div>
                                                </td>
                                                <td>
                                                    <div class="board-writer-info">
                                                        <div class="writer-avatar">${dto.boardWriter.substring(0,1).toUpperCase()}</div>
                                                        <span style="font-weight: 500;">${dto.boardWriter}</span>
                                                    </div>
                                                </td>
                                                <td style="text-align: center; color: var(--text-grey); font-size: 13px;">
                                                    ${dto.boardDate.toString().substring(5, 10)}
                                                </td>
                                                <td style="text-align: center; font-weight: 700; color: var(--blue);">${dto.boardView}</td>
                                            </tr>
                                        </c:forEach>
                                    </c:when>
                                    <c:otherwise>
                                        <tr>
                                            <td colspan="5" style="height: 400px; text-align: center; color: var(--text-grey);">
                                                <div style="font-size: 48px; margin-bottom: 16px;">💬</div>
                                                게시글이 없습니다. 첫 번째 주인공이 되어보세요!
                                            </td>
                                        </tr>
                                    </c:otherwise>
                                </c:choose>
                            </tbody>
                        </table>
                    </div>

                    <div class="board-pager">
                        <c:if test="${pager.pre}">
                            <a href="./list?page=${pager.start - 1}&kind=${pager.kind}&search=${pager.search}" class="pager-btn">PREV</a>
                        </c:if>

                        <c:forEach var="idx" begin="${pager.start}" end="${pager.end}">
                            <a href="./list?page=${idx}&kind=${pager.kind}&search=${pager.search}"
                               class="pager-btn ${pager.page == idx ? 'active' : ''}">
                                ${idx}
                            </a>
                        </c:forEach>

                        <c:if test="${pager.next}">
                            <a href="./list?page=${pager.end + 1}&kind=${pager.kind}&search=${pager.search}" class="pager-btn">NEXT</a>
                        </c:if>
                    </div>
                </div>

                <div class="cm-news-panel">
                    <h3 style="font-size: 18px; font-weight: 800; margin-bottom: 24px; display: flex; align-items: center; gap: 8px;">
                        📰 실시간 마켓 뉴스
                    </h3>
                    <div id="side-news-list">
                        <!-- 실시간 뉴스 로드 (index.js의 로직 활용 가능) -->
                        <div style="padding: 16px; background: var(--surface2); border-radius: 16px; margin-bottom: 12px;">
                            <span style="font-size: 11px; color: var(--blue); font-weight: 700;">증권가 소식</span>
                            <p style="font-size: 14px; font-weight: 600; margin-top: 4px; line-height: 1.4;">코스피, 대형 반도체주 변동성 확대 속 약세 흐름</p>
                        </div>
                        <div style="padding: 16px; background: var(--surface2); border-radius: 16px; margin-bottom: 12px;">
                            <span style="font-size: 11px; color: var(--blue); font-weight: 700;">외환 마켓</span>
                            <p style="font-size: 14px; font-weight: 600; margin-top: 4px; line-height: 1.4;">환율 상승 부담에 따른 성장주 투자심리 위축</p>
                        </div>
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
