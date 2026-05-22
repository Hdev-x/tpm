<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>${detail.boardTitle}-커뮤니티</title>
<link rel="stylesheet"
	href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
<link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/board/board.css">
</head>

<body style="overflow: auto;">
	<%@ include file="../common/nav.jsp"%>
	<div
		style="display: flex; min-height: 100vh; background: var(--background);">
		<%@ include file="../common/sidebar.jsp"%>

		<main class="main-layout" style="flex: 1; padding: 40px 20px;">
			<div class="card detail-main-card"
				style="max-width: 900px; margin: 0 auto;">

				<div class="detail-header">
					<span class="ph-ticker"
						style="color: var(--blue); font-size: 14px;">자유게시판</span>
					<h1 style="font-size: 36px; margin: 15px 0;">${detail.boardTitle}</h1>
					<div class="detail-info"
						style="display: flex; gap: 20px; border-bottom: 1px solid var(--border); padding-bottom: 20px;">
						<span class="ph-label">작성자: <b style="color: var(--text);">${detail.boardWriter}</b></span>
						<span class="ph-label">날짜: ${detail.boardDate}</span> <span
							class="ph-label">조회수: ${detail.boardView}</span>
					</div>
				</div>

				<div class="detail-body"
					style="padding: 30px 0; min-height: 200px; font-size: 18px; line-height: 1.8;">
					${detail.boardContent}</div>

				<div class="detail-images"
					style="text-align: center; margin-bottom: 40px;">
					<c:forEach items="${detail.list}" var="file">
						<div style="display: inline-block; margin-bottom: 20px;">
							<img src="/files/${file.fileName}"
								style="max-width: 70%; height: auto; border-radius: 16px; border: 1px solid var(--border2); box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);">
						</div>
					</c:forEach>
				</div>

				<div class="detail-actions">
					<div class="btn-group-left">
						<button type="button" class="btn-action btn-list"
							onclick="location.href='./list'">
							<span class="icon">←</span> 목록으로
						</button>
					</div>

					<c:if test="${member.username eq detail.boardWriter}">
						<div class="btn-group-right">
							<button type="button" class="btn-action btn-edit"
								onclick="location.href='./update?boardNo=${detail.boardNo}'">수정</button>
							<form action="./delete" method="post"
								onsubmit="return confirm('정말 삭제하시겠습니까?');" style="margin: 0;">
								<input type="hidden" name="boardNo" value="${detail.boardNo}">
								<button type="submit" class="btn-action btn-delete">삭제</button>
							</form>
						</div>
					</c:if>
				</div>

				<div class="like-section"
					style="display: flex; align-items: center; gap: 12px; margin: 30px 0; padding: 15px 20px; background: var(--surface2); border-radius: 16px; width: fit-content;">
					<button type="button" id="like-btn"
						data-board-no="${detail.boardNo}"
						style="background: none; border: none; cursor: pointer; display: flex; align-items: center; gap: 8px; transition: transform 0.2s ease;">
						<span id="like-icon" style="font-size: 24px;">${myLike != null ? '❤️' : '🤍'}</span>
						<span
							style="font-size: 16px; font-weight: 600; color: var(--text);">좋아요</span>
					</button>
					<span id="like-count"
						style="font-size: 18px; font-weight: 700; color: var(--blue); min-width: 20px;">${likeCount}</span>
				</div>

				<div class="comment-section"
					style="border-top: 1px solid var(--border); padding-top: 40px;">
					<h3 class="ph-name" style="font-size: 20px; margin-bottom: 24px;">
						댓글 <span style="color: var(--blue)">${replyList != null ? replyList.size() : 0}</span>
					</h3>

					<form action="/reply/create" method="post">
						<input type="hidden" name="boardNo" value="${detail.boardNo}">
						<div class="comment-write"
							style="background: var(--surface2); padding: 20px; border-radius: 16px; border: 1px solid var(--border);">
							<textarea name="replyContent" placeholder="댓글을 작성해주세요"
								style="width: 100%; background: transparent; border: none; color: var(--text); outline: none; resize: none; height: 80px; font-size: 15px;"></textarea>
							<div
								style="display: flex; justify-content: flex-end; margin-top: 12px;">
								<button type="submit" class="nav-login-btn"
									style="width: 80px; padding: 10px 0;">등록</button>
							</div>
						</div>
					</form>

					<div class="comment-list" style="margin-top: 20px;">
						<c:choose>
							<c:when test="${not empty replyList}">
								<c:forEach items="${replyList}" var="reply">
									<div class="comment-item"
										style="padding: 24px 0; border-bottom: 1px solid var(--border);">
										<div
											style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
											<div style="display: flex; align-items: center; gap: 8px;">
												<div
													style="width: 32px; height: 32px; background: var(--surface2); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 12px; color: var(--blue);">
													${reply.username.substring(0,1).toUpperCase()}</div>
												<span
													style="font-weight: 600; color: var(--text); font-size: 15px;">${reply.username}</span>
											</div>

											<div style="display: flex; align-items: center; gap: 12px;">
												<fmt:parseDate value="${reply.replyDate}"
													pattern="yyyy-MM-dd'T'HH:mm" var="parsedReplyDate"
													type="both" />
												<fmt:formatDate value="${parsedReplyDate}"
													pattern="MM.dd HH:mm" />
												<c:if test="${member.username eq reply.username}">
													<form action="/reply/delete" method="post"
														style="margin: 0;"
														onsubmit="return confirm('댓글을 삭제하시겠습니까?');">
														<input type="hidden" name="replyNo"
															value="${reply.replyNo}"> <input type="hidden"
															name="boardNo" value="${detail.boardNo}">
														<button type="submit"
															style="background: none; border: none; color: var(--blue); cursor: pointer; font-size: 13px; padding: 0;">삭제</button>
													</form>
												</c:if>
											</div>
										</div>
										<div
											style="color: var(--text2); font-size: 15px; line-height: 1.6; padding-left: 40px;">
											${reply.replyContent}</div>
									</div>
								</c:forEach>
							</c:when>
							<c:otherwise>
								<div class="ph-label"
									style="text-align: center; padding: 60px 0; color: var(--text3);">
									아직 댓글이 없습니다.<br>첫 번째 의견을 남겨보세요! 📈
								</div>
							</c:otherwise>
						</c:choose>
					</div>
				</div>
			</div>
		</main>
		<%@ include file="../common/sidebar-icons.jsp"%>
	</div>
	<script src="/js/common.js" defer></script>
	<script src="/js/sidebar-data.js" defer></script>
	<script src="/js/board/board.js"></script>
</body>
</html>