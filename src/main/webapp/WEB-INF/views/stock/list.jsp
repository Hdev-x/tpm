<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<link rel="stylesheet" href="/css/common.css">
<link rel="stylesheet" href="/css/chart-toss.css">
</head>
<body>

<div class="card board-main-card" style="padding: 0; overflow: hidden; border: none;">
    <div class="list-header" style="padding: 24px; display: flex; justify-content: space-between; align-items: center;">
        <h2 class="ph-price">실시간 종목 시세</h2>
        <span class="ph-label" id="update-time" style="font-size: 12px;">업데이트 중...</span>
    </div>

    <div class="stock-scroll-container" style="max-height: 800px; overflow-y: auto;">
        <table class="sb-table">
            <thead style="position: sticky; top: 0; background: var(--surface2); z-index: 10;">
                <tr>
                    <th style="padding: 15px 24px;">종목명</th>
                    <th style="text-align: right; padding: 15px 24px;">현재가</th>
                    <th style="text-align: right; padding: 15px 24px;">등락률</th>
                </tr>
            </thead>
            <tbody id="stock-list-body">
                </tbody>
        </table>
    </div>
</div>

</body>
</html>