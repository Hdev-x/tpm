<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<link rel="stylesheet" href="/css/common.css">
<link rel="stylesheet" href="/css/chart-toss.css">
</head>
<body>

<body style="overflow: auto;">
    <%@ include file="../common/nav.jsp" %>

    <!-- margin-top: 60px 추가하여 내비바와 겹침 방지 -->
    <div class="app-wrapper" style="margin-top: 60px; min-height: calc(100vh - 60px); background: var(--bg); display: flex;">
        
        <!-- open 클래스가 있어야 width: 380px가 적용됨 -->
<%@ include file="../common/sidebar.jsp" %>



		<div style="flex: 7;">
			<div class="notice-summary" style="margin-bottom: 30px;">
				<h3 class="ph-price" style="font-size: 28px;">공지사항</h3>
				<p class="ph-label">투자자들과 실시간으로 정보를 공유해보세요</p>
			</div>

			<table class="sb-table"
				style="width: 100%; border-collapse: separate; border-spacing: 0 10px;">
				<thead>
					<tr style="background: transparent;">
						<th style="padding: 10px 20px; border: none;">번호</th>
						<th style="padding: 10px 20px; border: none;">제목</th>
						<th style="padding: 10px 20px; border: none;">작성자</th>
						<th style="padding: 10px 20px; border: none;">날짜</th>
						<th style="padding: 10px 20px; border: none; text-align: right;">조회수</th>
					</tr>
				</thead>
				<tbody>
					<c:choose>
						<c:when test="${not empty list}">
							<c:forEach items="${list}" var="dto">
								<tr onclick="location.href='./detail?noticeNo=${dto.noticeNo}'"
									style="background: var(--surface); cursor: pointer; transition: transform 0.1s;">
									<td
										style="padding: 20px; border-radius: 12px 0 0 12px; color: var(--text3); font-size: 12px;">
										${dto.noticeNo}</td>
									<td style="padding: 20px;">
										<div
											style="font-size: 15px; font-weight: 600; color: var(--text);">${dto.noticeTitle}</div>
									</td>
									<td style="padding: 20px; color: var(--text2);">${dto.noticeWriter}</td>
									<td
										style="padding: 20px; color: var(--text3); font-size: 12px;">${dto.noticeDate}</td>
									<td
										style="padding: 20px; border-radius: 0 12px 12px 0; text-align: right; font-weight: 600; color: var(--blue);">
										${dto.noticeView}</td>
								</tr>
							</c:forEach>
						</c:when>
					</c:choose>
				</tbody>
			</table>

			<div class="card notice-main-card"
				style="border: none; background: transparent;">
				<div class="list-filter"
					style="display: flex; justify-content: space-between; align-items: center; padding-bottom: 20px;">
					<div style="display: flex; gap: 20px;">
						<span class="active"
							style="font-size: 16px; font-weight: 700; color: var(--text); border-bottom: 2px solid var(--text); padding-bottom: 5px;">전체글</span>
					</div>
					
					<div class="list-filter"
						style="display: flex; justify-content: space-between; align-items: center; padding-bottom: 20px;">
						<div style="display: flex; gap: 20px;">
							<span class="active"
								style="font-size: 16px; font-weight: 700; color: var(--text); border-bottom: 2px solid var(--text); padding-bottom: 5px;">전체글</span>
						</div>

						<c:if test="${member.roles eq 1}">
							<a href="./create" class="nav-login-btn"
								style="text-decoration: none;">글쓰기</a>
						</c:if>
					</div>
				</div>

				<table class="sb-table"
					style="width: 100%; border-collapse: separate; border-spacing: 0 10px;">
				</table>
			</div>
		</div>

		<div
			style="flex: 3; display: flex; flex-direction: column; gap: 20px; position: sticky; top: 100px;">



		</div>
	</main>
	
	</div>

	<script src="/js/common.js"></script>
	<!--  board.js는 board와 notice공유 -->
	<script src="/js/board.js"></script>
</body>
</html>