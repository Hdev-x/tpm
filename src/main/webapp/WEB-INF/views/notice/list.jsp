<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>공지사항 - 커뮤니티</title>
<link rel="stylesheet"
	href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
<link rel="stylesheet" href="/css/common.css">
<link rel="stylesheet" href="/css/chart-toss-coin.css">
</head>
<body>

	<div class="app-wrapper">
		<div class="page">
			<%@ include file="../common/nav.jsp"%>

			<div class="main-content"
				style="display: flex; gap: 30px; padding: 40px 20px;">
				<div style="flex: 7;">
					<div class="notice-summary" style="margin-bottom: 30px;">
						<h3 class="ph-price" style="font-size: 28px;">공지사항</h3>
						<p class="ph-label">중요한 소식과 업데이트를 확인하세요</p>
					</div>

					<div class="list-filter"
						style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; border-bottom: 1px solid var(--border); padding-bottom: 15px;">
						<div style="display: flex; gap: 20px;">
							<span class="active"
								style="font-size: 16px; font-weight: 700; color: var(--text); border-bottom: 2px solid var(--blue); padding-bottom: 13px; margin-bottom: -16px;">전체
								공지</span>
						</div>

						<c:if
							test="${not empty member.roles && member.roles[0].roleNo eq 1}">
							<a href="./create" class="nav-login-btn"
								style="text-decoration: none;">공지 작성</a>
						</c:if>
					</div>

					<table class="sb-table"
						style="width: 100%; border-collapse: separate; border-spacing: 0 12px;">
						<thead>
							<tr style="background: transparent;">
								<th
									style="padding: 10px 20px; border: none; color: var(--text3); font-weight: 400; text-align: left;">번호</th>
								<th
									style="padding: 10px 20px; border: none; color: var(--text3); font-weight: 400; text-align: left;">제목</th>
								<th
									style="padding: 10px 20px; border: none; color: var(--text3); font-weight: 400; text-align: left;">작성자</th>
								<th
									style="padding: 10px 20px; border: none; color: var(--text3); font-weight: 400; text-align: left;">날짜</th>
								<th
									style="padding: 10px 20px; border: none; color: var(--text3); font-weight: 400; text-align: right;">조회수</th>
							</tr>
						</thead>
						<tbody>
							<c:choose>
								<c:when test="${not empty list}">
									<c:forEach items="${list}" var="dto">
										<tr
											onclick="location.href='./detail?noticeNo=${dto.noticeNo}'"
											style="background: var(--surface); cursor: pointer; transition: all 0.2s ease;">
											<td
												style="padding: 20px; border-radius: 16px 0 0 16px; color: var(--text3); font-size: 13px;">
												${dto.noticeNo}</td>
											<td style="padding: 20px;">
												<div
													style="font-size: 16px; font-weight: 600; color: var(--text);">${dto.noticeTitle}</div>
											</td>
											<td
												style="padding: 20px; color: var(--text2); font-size: 14px;">${dto.noticeWriter}</td>
											<td
												style="padding: 20px; color: var(--text3); font-size: 13px;">${dto.noticeDate}</td>
											<td
												style="padding: 20px; border-radius: 0 16px 16px 0; text-align: right; font-weight: 600; color: var(--blue);">
												${dto.noticeView}</td>
										</tr>
									</c:forEach>
								</c:when>
								<c:otherwise>
									<tr>
										<td colspan="5"
											style="text-align: center; padding: 100px 0; color: var(--text3);">
											등록된 공지사항이 없습니다.</td>
									</tr>
								</c:otherwise>
							</c:choose>
						</tbody>
					</table>
				</div>

				<div style="flex: 3; position: sticky; top: 100px;"></div>
			</div>
		</div><%@ include file="../common/sidebar.jsp"%>
		<%@ include file="../common/sidebar-icons.jsp"%>
	</div>
	<script src="/js/common.js"></script>
	<script src="/js/board.js"></script>
</body>
</html>