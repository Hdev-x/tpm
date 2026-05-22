<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>공지사항 작성 - 커뮤니티</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/board/board.css">
</head>
<body style="overflow: auto;">

    <%@ include file="../common/nav.jsp" %>
    
    <div style="display: flex; min-height: 100vh; background: var(--background);">
        <%@ include file="../common/sidebar.jsp" %>

        <main class="main-layout" style="flex: 1; padding: 40px 20px;">
            <div class="card detail-main-card" style="max-width: 800px; margin: 0 auto; padding: 40px; border-radius: 24px;">
                
                <div class="create-header" style="margin-bottom: 40px;">
                    <span class="ph-ticker" style="color: var(--blue); font-size: 14px; font-weight: 600;">ADMIN NOTICE</span>
                    <h2 class="ph-price" style="font-size: 32px; margin-top: 8px;">새 공지 쓰기</h2>
                    <p class="ph-label" style="margin-top: 8px;">투자자들에게 알릴 중요 사항을 입력해주세요.</p>
                </div>

                <form action="./create" method="post" enctype="multipart/form-data" id="noticeForm">
                    <div class="input-group" style="margin-bottom: 30px;">
                        <label class="ph-label" style="display: block; margin-bottom: 10px;">제목</label>
                        <input type="text" name="noticeTitle" placeholder="제목을 입력해주세요" required
                            style="width: 100%; background: var(--surface2); border: 1px solid var(--border); border-radius: 12px; padding: 15px; color: var(--text); outline: none; font-size: 16px;">
                    </div>

                    <div class="input-group" style="margin-bottom: 30px;">
                        <label class="ph-label" style="display: block; margin-bottom: 10px;">내용</label>
                        <textarea name="noticeContent" placeholder="공지 내용을 입력하세요" required
                            style="width: 100%; background: var(--surface2); border: 1px solid var(--border); border-radius: 12px; padding: 15px; color: var(--text); outline: none; font-size: 16px; min-height: 300px; resize: none; line-height: 1.6;"></textarea>
                    </div>

                    <div class="input-group" style="margin-bottom: 40px;">
                        <label class="ph-label" style="display: block; margin-bottom: 10px;">사진 첨부</label>
                        <div style="background: var(--surface2); border: 2px dashed var(--border); border-radius: 12px; padding: 20px; text-align: center;">
                            <input type="file" name="attach" multiple id="fileInput" style="display: none;" accept="image/*">
                            <label for="fileInput" style="cursor: pointer; color: var(--text2); display: block; padding: 20px 0;">
                                <span style="font-size: 30px;">+</span><br>
                                클릭하여 사진을 추가하세요 (여러 장 가능)
                            </label>

                            <div id="image-preview-container" style="display: flex; gap: 12px; flex-wrap: wrap; margin-top: 15px; justify-content: center;"></div>

                            <div id="file-list" style="margin-top: 10px; font-size: 13px; color: var(--blue);"></div>
                        </div>
                    </div>

                    <div class="create-actions" style="display: flex; gap: 12px; justify-content: flex-end;">
                        <button type="button" class="order-type-btn" style="width: 100px; padding: 14px 0;" onclick="history.back()">취소</button>
                        <button type="submit" class="nav-login-btn" style="width: 150px; padding: 14px 0; font-weight: 600;">공지 등록하기</button>
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