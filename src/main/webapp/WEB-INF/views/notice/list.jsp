<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>공지사항 - 커뮤니티</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/board/board.css">
    <link rel="stylesheet" href="/css/community.css">
    <style>
        .notice-community-page .notice-header {
            min-height: 140px;
            padding: 40px 50px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            background: linear-gradient(135deg, #1c2030 0%, #3d252a 100%);
            border-bottom: 1px solid var(--border);
            margin-bottom: 0;
        }

        .notice-community-page .notice-title {
            margin: 0;
            font-size: 32px;
            font-weight: 800;
            color: var(--text);
            letter-spacing: -0.5px;
        }

        .notice-community-page .notice-subtitle {
            margin: 12px 0 0;
            font-size: 16px;
            color: var(--text-grey);
            opacity: 0.8;
        }

        .notice-community-page .main-layout {
            display: grid;
            grid-template-columns: 1fr 340px;
            gap: 24px;
            padding: 32px 50px 80px;
            max-width: 1400px;
            margin: 0 auto;
        }

        .notice-feed-panel {
            background: var(--surface);
            border-radius: 24px;
            border: 1px solid var(--border);
            overflow: hidden;
            display: flex;
            flex-direction: column;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }

        .notice-toolbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 24px 32px;
            border-bottom: 1px solid var(--border);
        }

        .notice-tab {
            font-size: 15px;
            font-weight: 700;
            color: var(--text);
            padding: 8px 16px;
            border-radius: 12px;
            background: rgba(240, 68, 82, 0.1);
            color: #F04452;
            border: 1px solid rgba(240, 68, 82, 0.2);
        }

        .notice-write-btn {
            height: 44px;
            padding: 0 24px;
            background: #F04452;
            color: white;
            border-radius: 12px;
            font-weight: 700;
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: transform 0.2s;
        }
        .notice-write-btn:hover { transform: translateY(-2px); }

        .notice-list-wrap {
            padding: 0;
        }

        .notice-table {
            width: 100%;
            border-collapse: collapse;
        }

        .notice-table th {
            padding: 16px 24px;
            background: rgba(255,255,255,0.02);
            color: var(--text-grey);
            font-size: 13px;
            font-weight: 600;
            text-align: left;
            border-bottom: 1px solid var(--border);
        }

        .notice-table td {
            padding: 20px 24px;
            border-bottom: 1px solid var(--border);
            color: var(--text);
            font-size: 15px;
        }

        .notice-row {
            cursor: pointer;
            transition: all 0.2s;
        }

        .notice-row:hover {
            background: rgba(240, 68, 82, 0.03);
        }

        .notice-post-title {
            font-weight: 700;
            color: var(--text);
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .notice-badge {
            background: rgba(240, 68, 82, 0.1);
            color: #F04452;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 800;
        }

        .notice-view {
            font-weight: 700;
            color: #F04452;
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
<body class="chart-page community-page notice-community-page">
    <div class="app-wrapper">
        <div class="page">
            <%@ include file="../common/nav.jsp" %>

            <div style="height: calc(100vh - 70px); overflow-y: auto; scrollbar-width: none;">
            <div class="notice-header">
                <div style="max-width: 1400px; margin: 0 auto; width: 100%;">
                    <h1 class="notice-title">공지사항</h1>
                    <p class="notice-subtitle">중요한 소식과 업데이트를 확인하세요</p>
                </div>
            </div>

            <div class="main-layout">
                <div class="notice-feed-panel">
                    <div class="notice-toolbar">
                        <span class="notice-tab">📢 전체 공지</span>
                        <c:if test="${not empty member.roles && member.roles[0].roleNo eq 1}">
                            <a href="./create" class="notice-write-btn">
                                <span>+</span> 공지 작성
                            </a>
                        </c:if>
                    </div>

                    <div class="notice-list-wrap">
                        <table class="notice-table">
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
                                            <tr class="notice-row" onclick="location.href='./detail?noticeNo=${dto.noticeNo}'">
                                                <td style="text-align: center; color: var(--text-grey); font-size: 13px;">${dto.noticeNo}</td>
                                                <td>
                                                    <div class="notice-post-title">
                                                        <span class="notice-badge">공지</span>
                                                        ${dto.noticeTitle}
                                                    </div>
                                                </td>
                                                <td>
                                                    <div style="display: flex; align-items: center; gap: 8px;">
                                                        <div style="width: 24px; height: 24px; background: rgba(240, 68, 82, 0.1); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 10px; font-weight: 700; color: #F04452;">A</div>
                                                        <span style="font-weight: 600;">관리자</span>
                                                    </div>
                                                </td>
                                                <td style="text-align: center; color: var(--text-grey); font-size: 13px;">
                                                    ${dto.noticeDate.toString().substring(0, 10)}
                                                </td>
                                                <td style="text-align: center;" class="notice-view">${dto.noticeView}</td>
                                            </tr>
                                        </c:forEach>
                                    </c:when>
                                    <c:otherwise>
                                        <tr>
                                            <td colspan="5" style="height: 400px; text-align: center; color: var(--text-grey);">
                                                <div style="font-size: 48px; margin-bottom: 16px;">📢</div>
                                                등록된 공지사항이 없습니다.
                                            </td>
                                        </tr>
                                    </c:otherwise>
                                </c:choose>
                            </tbody>
                        </table>
                    </div>
                </div>

                <div class="cm-news-panel">
                    <h3 style="font-size: 18px; font-weight: 800; margin-bottom: 24px; display: flex; align-items: center; gap: 8px;">
                        🔔 시스템 알림
                    </h3>
                    <div style="padding: 16px; background: rgba(240, 68, 82, 0.05); border-radius: 16px; border: 1px solid rgba(240, 68, 82, 0.1);">
                        <p style="font-size: 14px; color: var(--text); line-height: 1.6;">
                            모의투자 시스템은 <strong>매일 04:00 ~ 05:00</strong>에 정기 점검이 진행됩니다.
                        </p>
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
