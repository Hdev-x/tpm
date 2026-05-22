<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>실시간 뉴스룸 - B조 트레이딩</title>
<link rel="stylesheet"
	href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
<link rel="stylesheet" href="/css/common.css">
</head>
<body>

	<div class="app-wrapper">
		<div class="page">
			<%@ include file="../common/nav.jsp"%>

			<div class="main-content"
				style="display: flex; gap: 24px; padding: 30px; min-height: calc(100vh - 100px); box-sizing: border-box; background: var(--bg); color: var(--text);">

				<div
					style="flex: 3; display: flex; flex-direction: column; gap: 20px; min-width: 280px; max-width: 340px; position: sticky; top: 20px; height: fit-content;">

					<div
						style="background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 20px; box-sizing: border-box;">
						<h4
							style="font-size: 15px; margin-top: 0; margin-bottom: 12px; color: var(--text);">🔍
							뉴스 검색</h4>
						<div style="display: flex; gap: 8px;">
							<input type="text" id="news-search-input"
								placeholder="검색어를 입력하세요"
								style="flex: 1; background: var(--surface2); border: 1px solid var(--border2); color: var(--text); padding: 10px 14px; border-radius: 8px; outline: none; font-size: 13px;">
							<button id="news-search-btn" class="nav-login-btn"
								style="padding: 0 16px; font-size: 13px; border-radius: 8px; cursor: pointer;">검색</button>
						</div>
					</div>

					<div
						style="background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 20px; box-sizing: border-box;">
						<div
							style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
							<h4 style="font-size: 15px; color: var(--text); margin: 0;">🕒
								최근 검색어</h4>
							<button onclick="clearAllRecentKeywords()"
								style="background: transparent; border: none; color: var(--text3); font-size: 11px; cursor: pointer; padding: 0;">
								전체삭제</button>
						</div>
						<div id="recent-keywords-box"
							style="display: flex; flex-wrap: wrap; gap: 8px;"></div>
					</div>

					<div
						style="background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 20px; box-sizing: border-box;">
						<h4
							style="font-size: 15px; margin-top: 0; margin-bottom: 15px; color: var(--text);">🔥
							키워드</h4>
						<div style="display: flex; flex-direction: column; gap: 10px;"
							id="popular-keywords-box">
							<div class="si-type-tab"
								style="text-align: center; padding: 10px; border-radius: 8px; cursor: pointer;"
								onclick="searchNewsByKeyword('삼성전자')">1. 삼성전자</div>
							<div class="si-type-tab"
								style="text-align: center; padding: 10px; border-radius: 8px; cursor: pointer;"
								onclick="searchNewsByKeyword('SK하이닉스')">2. SK하이닉스</div>
							<div class="si-type-tab"
								style="text-align: center; padding: 10px; border-radius: 8px; cursor: pointer;"
								onclick="searchNewsByKeyword('현대차')">3. 현대차</div>
							<div class="si-type-tab"
								style="text-align: center; padding: 10px; border-radius: 8px; cursor: pointer;"
								onclick="searchNewsByKeyword('BTC')">4. BTC</div>
							<div class="si-type-tab"
								style="text-align: center; padding: 10px; border-radius: 8px; cursor: pointer;"
								onclick="searchNewsByKeyword('도지')">5. 도지코인</div>
						</div>
					</div>
				</div>

				<div
					style="flex: 7; background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 30px; box-sizing: border-box; height: fit-content; min-height: 500px;">
					<div
						style="border-bottom: 1px solid var(--border); padding-bottom: 15px; margin-bottom: 20px; display: flex; justify-content: space-between; align-items: center;">
						<h3
							style="font-size: 20px; color: var(--text); margin: 0; display: flex; align-items: center; gap: 8px;">
							📰 실시간 주요 뉴스 <span id="news-target-keyword"
								style="color: #3182f6; font-size: 18px; background: var(--surface2); padding: 2px 8px; border-radius: 4px;"></span>
						</h3>
						<span style="font-size: 12px; color: var(--text3);">네이버 실시간
							뉴스 기준</span>
					</div>

					<div id="big-news-stream-list"
						style="display: flex; flex-direction: column; gap: 4px;"></div>
				</div>



			</div>
		</div>

		<%@ include file="../common/sidebar.jsp"%>
		<%@ include file="../common/sidebar-icons.jsp"%>
	</div>

	<script src="/js/common.js" defer></script>
	<script src="/js/sidebar-data.js" defer></script>
	<script src="/js/news/news.js" defer></script>
	<script>
		window.addEventListener('load', function() {
			if (typeof searchNewsByKeyword === 'function') {
				searchNewsByKeyword('삼성전자');
			}
		});
	</script>
</body>
</html>