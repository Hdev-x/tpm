<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>공지사항 - 커뮤니티</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/chart-toss-coin.css">
    <link rel="stylesheet" href="/css/coinCommunity.css">
    <style>
        .notice-community-page .notice-header {
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

        .notice-community-page .notice-title {
            margin: 0;
            font-size: 28px;
            font-weight: 800;
            color: var(--text);
            letter-spacing: 0;
        }

        .notice-community-page .notice-subtitle {
            margin: 8px 0 0;
            font-size: 14px;
            color: var(--text3);
        }

        .notice-community-page .main-layout {
            display: grid;
            grid-template-columns: minmax(560px, 1fr) 360px;
            gap: var(--gap);
            padding: var(--gap) 50px 70px;
            overflow: hidden;
        }

        .notice-feed-panel {
            min-width: 0;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            border: 0;
        }

        .notice-toolbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 18px;
            padding: 16px 28px 14px;
            flex-shrink: 0;
        }

        .notice-tab {
            font-size: 14px;
            font-weight: 700;
            color: var(--text);
            padding: 7px 10px;
            border-radius: 7px;
            background: rgba(255, 255, 255, 0.04);
        }

        .notice-write-btn {
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

        .notice-list-wrap {
            position: relative;
            padding: 0 28px 22px;
            overflow-y: auto;
            min-height: 0;
            flex: 1 1 auto;
        }

        .notice-list-wrap::before,
        .notice-list-wrap::after {
            content: "";
            position: absolute;
            left: 28px;
            right: 28px;
            height: 1px;
            background: var(--border);
            pointer-events: none;
        }

        .notice-list-wrap::before {
            top: 0;
        }

        .notice-list-wrap::after {
            bottom: 0;
        }

        .notice-table {
            width: 100%;
            border-collapse: collapse;
        }

        .notice-table th {
            padding: 10px 12px;
            color: var(--text3);
            font-size: 12px;
            font-weight: 500;
            text-align: left;
            border-bottom: 0;
        }

        .notice-table th:last-child,
        .notice-table td:last-child {
            text-align: right;
        }

        .notice-table td {
            height: 64px;
            padding: 0 12px;
            border-bottom: 1px solid var(--border);
            color: var(--text2);
            font-size: 13px;
        }

        .notice-table tbody tr:last-child td {
            border-bottom: 0;
        }

        .notice-row {
            cursor: pointer;
            transition: background 0.12s;
        }

        .notice-row:hover {
            background: rgba(255, 255, 255, 0.03);
        }

        .notice-no {
            width: 72px;
            color: var(--text3);
        }

        .notice-post-title {
            font-size: 15px;
            font-weight: 700;
            color: var(--text);
        }

        .notice-writer {
            width: 120px;
            white-space: nowrap;
        }

        .notice-date {
            width: 180px;
            color: var(--text3);
            white-space: nowrap;
        }

        .notice-view {
            width: 88px;
            color: var(--blue);
            font-weight: 700;
        }

        .notice-table td.notice-empty {
            height: 360px;
            text-align: center;
            color: var(--text3);
            border-bottom: 0;
        }

        .notice-empty-inner {
            min-height: 360px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .notice-news-panel {
            width: auto;
            min-width: 0;
            max-width: none;
            flex-basis: auto;
        }

        @media (max-width: 1080px) {
            .notice-community-page .main-layout {
                grid-template-columns: 1fr;
                padding: var(--gap) 18px 28px;
            }

            .notice-community-page .notice-header {
                padding: 0 18px;
            }
        }
    </style>
</head>
<body class="chart-page community-page notice-community-page" data-sidebar-tab="invest" data-sidebar-invest-tab="stock">
    <div class="app-wrapper">
        <div class="page">
            <%@ include file="../common/nav.jsp" %>

            <div class="notice-header">
                <h1 class="notice-title">공지사항</h1>
                <p class="notice-subtitle">중요한 소식과 업데이트를 확인하세요</p>
            </div>

            <div class="main-layout">
                <div class="card notice-feed-panel">
                    <div class="notice-toolbar">
                        <span class="notice-tab">전체 공지</span>
                        <c:if test="${not empty member.roles && member.roles[0].roleNo eq 1}">
                            <a href="./create" class="notice-write-btn">공지 작성</a>
                        </c:if>
                    </div>

                    <div class="notice-list-wrap">
                        <table class="notice-table">
                            <thead>
                                <tr>
                                    <th class="notice-no">번호</th>
                                    <th>제목</th>
                                    <th class="notice-writer">작성자</th>
                                    <th class="notice-date">날짜</th>
                                    <th class="notice-view">조회수</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:choose>
                                    <c:when test="${not empty list}">
                                        <c:forEach items="${list}" var="dto">
                                            <tr class="notice-row" onclick="location.href='./detail?noticeNo=${dto.noticeNo}'">
                                                <td class="notice-no">${dto.noticeNo}</td>
                                                <td><div class="notice-post-title">${dto.noticeTitle}</div></td>
                                                <td class="notice-writer">${dto.noticeWriter}</td>
                                                <td class="notice-date">${dto.noticeDate}</td>
                                                <td class="notice-view">${dto.noticeView}</td>
                                            </tr>
                                        </c:forEach>
                                    </c:when>
                                    <c:otherwise>
                                        <tr>
                                            <td colspan="5" class="notice-empty">
                                                <div class="notice-empty-inner">등록된 공지사항이 없습니다.</div>
                                            </td>
                                        </tr>
                                    </c:otherwise>
                                </c:choose>
                            </tbody>
                        </table>
                    </div>
                </div>

                <div class="card panel-chat cm-news-panel notice-news-panel">
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

    <script src="/js/common.js"></script>
    <script src="/js/board.js"></script>
</body>
</html>
