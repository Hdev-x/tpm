<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>새 글 쓰기 - 커뮤니티</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/chart-toss-coin.css">
    <link rel="stylesheet" href="/css/coinCommunity.css">
</head>
<body class="chart-page community-page board-community-page" style="overflow: auto;">
    
    <div class="app-wrapper">
        <div class="page">
            <%@ include file="../common/nav.jsp"%>
            
            <div class="board-header">
                <div style="max-width: 1400px; margin: 0 auto; width: 100%;">
                    <h1 class="board-title">새 글 쓰기</h1>
                    <p class="board-subtitle">투자자들과 자유롭게 의견을 나누어보세요.</p>
                </div>
            </div>

            <div class="main-layout" style="display: block; padding: 40px 50px 80px; height: calc(100vh - 140px); overflow-y: auto; box-sizing: border-box;">
                <div class="card" style="max-width: 800px; margin: 0 auto; padding: 48px; border-radius: 24px; background: var(--surface); border: 1px solid var(--border); box-shadow: 0 4px 20px rgba(0,0,0,0.1);">
                    
                    <form action="./create" method="post" enctype="multipart/form-data" id="boardForm">
                        <div class="input-group" style="margin-bottom: 32px;">
                            <label style="display: block; margin-bottom: 12px; font-weight: 600; color: var(--text-grey); font-size: 14px;">제목</label>
                            <input type="text" name="boardTitle" placeholder="제목을 입력해주세요" required
                                style="width: 100%; background: var(--surface2); border: 1px solid var(--border); border-radius: 16px; padding: 18px; color: var(--text); outline: none; font-size: 16px; box-sizing: border-box; transition: border-color 0.2s;">
                        </div>

                        <div class="input-group" style="margin-bottom: 32px;">
                            <label style="display: block; margin-bottom: 12px; font-weight: 600; color: var(--text-grey); font-size: 14px;">내용</label>
                            <textarea name="boardContent" placeholder="여기에 내용을 입력하세요" required
                                style="width: 100%; background: var(--surface2); border: 1px solid var(--border); border-radius: 16px; padding: 18px; color: var(--text); outline: none; font-size: 16px; min-height: 350px; resize: none; line-height: 1.6; box-sizing: border-box; transition: border-color 0.2s;"></textarea>
                        </div>

                        <div class="input-group" style="margin-bottom: 48px;">
                            <label style="display: block; margin-bottom: 12px; font-weight: 600; color: var(--text-grey); font-size: 14px;">사진 첨부</label>
                            <div style="background: var(--surface2); border: 2px dashed var(--border); border-radius: 16px; padding: 32px; text-align: center; transition: background 0.2s;">
                                <input type="file" name="files" multiple id="fileInput" style="display: none;" accept="image/*">
                                <label for="fileInput" style="cursor: pointer; color: var(--text-grey); display: block;">
                                    <div style="font-size: 40px; margin-bottom: 8px; color: var(--blue);">+</div>
                                    <div style="font-weight: 500;">클릭하여 사진을 추가하세요</div>
                                    <div style="font-size: 13px; margin-top: 4px; opacity: 0.7;">(여러 장 선택 가능)</div>
                                </label>

                                <div id="image-preview-container" style="display: flex; gap: 12px; flex-wrap: wrap; margin-top: 24px; justify-content: center;"></div>
                                <div id="file-list" style="margin-top: 16px; font-size: 13px; color: var(--blue); font-weight: 500;"></div>
                            </div>
                        </div>

                        <div class="create-actions" style="display: flex; gap: 16px; justify-content: flex-end;">
                            <button type="button" class="order-type-btn" style="width: 120px; padding: 16px 0;" onclick="history.back()">취소</button>
                            <button type="submit" class="nav-login-btn" style="width: 180px; padding: 16px 0; font-weight: 700;">등록하기</button>
                        </div>
                    </form>
                </div>
            </div>
        </div> <%@ include file="../common/sidebar.jsp" %>
        <%@ include file="../common/sidebar-icons.jsp" %>
    </div>

    <script src="/js/common.js"></script>
    <script src="/js/board.js"></script>
</body>
</html>