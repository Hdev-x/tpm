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
            min-height: 92px;
            padding: 0 50px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            background: var(--sidebar);
            border: 0;
            box-shadow: none;
            margin: 0;
        }

        .board-community-page .board-title {
            margin: 0;
            font-size: 28px;
            font-weight: 800;
            color: var(--text);
            letter-spacing: 0;
        }

        .board-community-page .board-subtitle {
            margin: 8px 0 0;
            font-size: 14px;
            color: var(--text3);
        }

        .board-community-page .main-layout {
            display: grid;
            grid-template-columns: minmax(560px, 1fr) 360px;
            gap: var(--gap);
            padding: var(--gap) 50px 70px;
            overflow: hidden;
        }

        .board-feed-panel {
            min-width: 0;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            border: 0;
        }

        .board-toolbar {
            display: flex;
            justify-content: space-between;
            align-items: flex-end;
            gap: 18px;
            padding: 16px 28px 14px;
            flex-shrink: 0;
        }

        .board-tabs {
            display: flex;
            gap: 6px;
            align-items: center;
        }

        .board-tab {
            font-size: 14px;
            font-weight: 700;
            color: var(--text);
            padding: 7px 10px;
            border-radius: 7px;
            background: rgba(255, 255, 255, 0.04);
        }

        .board-page-chip {
            font-size: 12px;
            color: var(--text3);
        }

        .board-tools {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .board-search-form {
            display: flex;
            align-items: center;
            gap: 8px;
            margin: 0;
        }

        .board-select,
        .board-search-input {
            height: 34px;
            background: var(--surface2);
            border: 1px solid var(--border2);
            color: var(--text);
            border-radius: 7px;
            outline: none;
            font-size: 13px;
            font-family: inherit;
        }

        .board-select {
            padding: 0 10px;
            cursor: pointer;
        }

        .board-search-box {
            position: relative;
            display: flex;
            align-items: center;
        }

        .board-search-input {
            width: 180px;
            padding: 0 34px 0 12px;
            transition: border-color 0.15s, width 0.15s;
        }

        .board-search-input:focus {
            width: 220px;
            border-color: var(--blue);
        }

        .board-search-btn {
            position: absolute;
            right: 9px;
            background: transparent;
            border: 0;
            color: var(--text3);
            cursor: pointer;
            padding: 0;
            font-size: 13px;
        }

        .board-write-btn {
            height: 34px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 14px;
            border-radius: 7px;
            background: var(--blue);
            color: #fff;
            font-size: 13px;
            font-weight: 700;
            text-decoration: none;
            white-space: nowrap;
        }

        .board-search-clear {
            margin: 0 28px 8px;
            display: inline-flex;
            width: fit-content;
            color: var(--blue);
            font-size: 12px;
            text-decoration: none;
            background: var(--surface2);
            padding: 5px 10px;
            border-radius: 6px;
            border: 1px solid var(--border2);
        }

        .board-list-wrap {
            position: relative;
            padding: 0 28px 22px;
            overflow-y: auto;
            min-height: 0;
            flex: 1 1 auto;
        }

        .board-list-wrap::before,
        .board-list-wrap::after {
            content: "";
            position: absolute;
            left: 28px;
            right: 28px;
            height: 1px;
            background: var(--border);
            pointer-events: none;
        }

        .board-list-wrap::before {
            top: 0;
        }

        .board-list-wrap::after {
            bottom: 0;
        }

        .board-table {
            width: 100%;
            border-collapse: collapse;
        }

        .board-table th {
            padding: 10px 12px;
            color: var(--text3);
            font-size: 12px;
            font-weight: 500;
            text-align: left;
            border-bottom: 0;
        }

        .board-table th:last-child,
        .board-table td:last-child {
            text-align: right;
        }

        .board-table td {
            height: 64px;
            padding: 0 12px;
            border-bottom: 1px solid var(--border);
            color: var(--text2);
            font-size: 13px;
        }

        .board-table tbody tr:last-child td {
            border-bottom: 0;
        }

        .board-row {
            cursor: pointer;
            transition: background 0.12s;
        }

        .board-row:hover {
            background: rgba(255, 255, 255, 0.03);
        }

        .board-no {
            width: 72px;
            color: var(--text3);
        }

        .board-post-title {
            font-size: 15px;
            font-weight: 700;
            color: var(--text);
        }

        .board-writer {
            width: 120px;
            white-space: nowrap;
        }

        .board-date {
            width: 180px;
            color: var(--text3);
            white-space: nowrap;
        }

        .board-view {
            width: 88px;
            color: var(--blue);
            font-weight: 700;
        }

        .board-table td.board-empty {
            height: 360px;
            color: var(--text3);
            text-align: center;
            border-bottom: 0;
        }

        .board-empty-inner {
            min-height: 360px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .board-pager {
            display: flex;
            justify-content: center;
            gap: 6px;
            padding: 28px 28px 36px;
            flex-shrink: 0;
            margin-top: auto;
        }

        .pager-btn {
            min-width: 34px;
            height: 34px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 11px;
            text-decoration: none;
            border-radius: 7px;
            font-size: 13px;
            font-weight: 700;
            transition: all 0.15s;
            background: var(--surface2);
            border: 1px solid var(--border2);
            color: var(--text3);
        }

        .pager-btn:hover {
            border-color: var(--blue);
            color: var(--text);
        }

        .pager-btn.active {
            background: var(--blue);
            color: #fff;
            border-color: var(--blue);
        }

        .board-news-panel {
            width: auto;
            min-width: 0;
            max-width: none;
            flex-basis: auto;
        }

        @media (max-width: 1080px) {
            .board-community-page .main-layout {
                grid-template-columns: 1fr;
                padding: var(--gap) 18px 28px;
            }

            .board-community-page .board-header {
                padding: 0 18px;
            }

            .board-toolbar {
                flex-direction: column;
                align-items: stretch;
            }

            .board-tools,
            .board-search-form {
                width: 100%;
            }

            .board-search-box,
            .board-search-input {
                width: 100%;
            }

            .board-search-input:focus {
                width: 100%;
            }
        }
    </style>
</head>
<body class="chart-page community-page board-community-page" data-sidebar-tab="invest" data-sidebar-invest-tab="stock">
    <div class="app-wrapper">
        <div class="page">
            <%@ include file="../common/nav.jsp" %>

            <div class="board-header">
                <h1 class="board-title">자유게시판</h1>
                <p class="board-subtitle">주식 투자 정보와 일상을 자유롭게 공유하세요</p>
            </div>

            <div class="main-layout">
                <div class="card board-feed-panel">
                    <div class="board-toolbar">
                        <div class="board-tabs">
                            <span class="board-tab">전체글</span>
                            <span class="board-page-chip">${pager.page} page</span>
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
                                    <button type="submit" class="board-search-btn">검색</button>
                                </div>
                            </form>

                            <c:if test="${not empty member}">
                                <a href="./create" class="board-write-btn">글쓰기</a>
                            </c:if>
                        </div>
                    </div>

                    <c:if test="${not empty pager.search}">
                        <a href="./list" class="board-search-clear">'${pager.search}' 검색 해제</a>
                    </c:if>

                    <div class="board-list-wrap">
                        <table class="board-table">
                            <thead>
                                <tr>
                                    <th class="board-no">번호</th>
                                    <th>제목</th>
                                    <th class="board-writer">작성자</th>
                                    <th class="board-date">날짜</th>
                                    <th class="board-view">조회수</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:choose>
                                    <c:when test="${not empty list}">
                                        <c:forEach items="${list}" var="dto">
                                            <tr class="board-row" onclick="location.href='./detail?boardNo=${dto.boardNo}'">
                                                <td class="board-no">${dto.boardNo}</td>
                                                <td><div class="board-post-title">${dto.boardTitle}</div></td>
                                                <td class="board-writer">${dto.boardWriter}</td>
                                                <td class="board-date">${dto.boardDate}</td>
                                                <td class="board-view">${dto.boardView}</td>
                                            </tr>
                                        </c:forEach>
                                    </c:when>
                                    <c:otherwise>
                                        <tr>
                                            <td colspan="5" class="board-empty">
                                                <div class="board-empty-inner">첫 번째 게시글의 주인공이 되어보세요</div>
                                            </td>
                                        </tr>
                                    </c:otherwise>
                                </c:choose>
                            </tbody>
                        </table>
                    </div>

                    <div class="board-pager">
                        <c:if test="${pager.pre}">
                            <a href="./list?page=${pager.start - 1}&kind=${pager.kind}&search=${pager.search}" class="pager-btn">이전</a>
                        </c:if>

                        <c:forEach var="idx" begin="${pager.start}" end="${pager.end}">
                            <a href="./list?page=${idx}&kind=${pager.kind}&search=${pager.search}"
                               class="pager-btn ${pager.page == idx ? 'active' : ''}">
                                ${idx}
                            </a>
                        </c:forEach>

                        <c:if test="${pager.next}">
                            <a href="./list?page=${pager.end + 1}&kind=${pager.kind}&search=${pager.search}" class="pager-btn">다음</a>
                        </c:if>
                    </div>
                </div>

                <div class="card panel-chat cm-news-panel board-news-panel">
                    <div class="cm-panel-title">뉴스</div>
                    <div class="cm-news-list">
                        <div class="cm-news-item">
                            <span class="cm-news-source">마켓뉴스</span>
                            <span class="cm-news-time">5분 전</span>
                            <p class="cm-news-text">코스피, 대형 반도체주 변동성 확대 속 약세</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">증권가</span>
                            <span class="cm-news-time">23분 전</span>
                            <p class="cm-news-text">외국인 수급 방향에 따라 장중 등락 반복</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">경제데일리</span>
                            <span class="cm-news-time">1시간 전</span>
                            <p class="cm-news-text">환율 상승 부담에 성장주 투자심리 둔화</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">산업리포트</span>
                            <span class="cm-news-time">2시간 전</span>
                            <p class="cm-news-text">조선, 방산 업종 실적 기대감은 유지</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">리서치센터</span>
                            <span class="cm-news-time">3시간 전</span>
                            <p class="cm-news-text">실적 시즌 앞두고 업종별 차별화 전망</p>
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
