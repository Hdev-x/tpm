<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>TradeBot · 주식 커뮤니티</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/market/common.css">
    <link rel="stylesheet" href="/css/market/chart.css">
    <link rel="stylesheet" href="/css/community.css">
    <link rel="stylesheet" href="/css/market/community.css">
</head>
<body class="chart-page community-page" data-sidebar-tab="invest" data-sidebar-invest-tab="stock">

    <div class="app-wrapper">
        <div class="page">
            <%@ include file="../common/nav.jsp" %>

            <!-- 가격 헤더 -->
            <div class="price-header">
                <div class="ph-left">
                    <div class="ph-name-row search-trigger" id="search-trigger">
                        <div class="ph-name-group">
                            <span class="ph-name" id="ph-display-name">${stockName}</span>
                            <span class="ph-ticker">${code}</span>
                            <span class="ph-arrow">▾</span>
                        </div>
                        <div class="search-dropdown" id="search-dropdown">
                            <div class="sd-input-wrap">
                                <div class="sd-search-box">
                                    <svg class="sd-search-icon" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
                                    <input type="text" id="sd-input" placeholder="종목 검색" autocomplete="off">
                                </div>
                            </div>
                            <div class="sd-content">
                                <div class="sd-label" id="sd-label">인기 검색</div>
                                <div class="sd-list" id="sd-list"></div>
                            </div>
                        </div>
                    </div>
                    <div class="ph-price-row">
                        <span class="ph-price" id="ph-price">-</span>
                        <span style="width:1px;height:16px;background:var(--border2);margin:0 6px;flex-shrink:0;align-self:center;"></span>
                        <span style="font-size:13px;color:var(--text3);font-weight:500;line-height:1;">전일대비</span>
                        <span class="ph-change" id="ph-change-abs">-</span>
                        <span class="ph-change" id="ph-change">-</span>
                    </div>
                </div>
                <div class="ph-right">
                    <div class="ph-group">
                        <div class="ph-item">
                            <span class="ph-label">전일 종가</span>
                            <span class="ph-value" id="ph-prev-close">-</span>
                        </div>
                        <div class="ph-item">
                            <span class="ph-label">당일 시가</span>
                            <span class="ph-value" id="ph-open">-</span>
                        </div>
                    </div>
                    <div class="ph-vdivider"></div>
                    <div class="ph-group">
                        <div class="ph-item">
                            <span class="ph-label">고가</span>
                            <span class="ph-value" id="ph-high">-</span>
                        </div>
                        <div class="ph-item">
                            <span class="ph-label">저가</span>
                            <span class="ph-value" id="ph-low">-</span>
                        </div>
                    </div>
                    <div class="ph-vdivider"></div>
                    <div class="ph-group">
                        <div class="ph-item">
                            <span class="ph-label">거래량</span>
                            <span class="ph-value" id="ph-vol">-</span>
                        </div>
                        <div class="ph-item">
                            <span class="ph-label">거래대금</span>
                            <span class="ph-value" id="ph-turnover">-</span>
                        </div>
                    </div>
                    <div class="ph-vdivider"></div>
                    <div class="ph-group">
                        <div class="ph-item">
                            <span class="ph-label">시가총액</span>
                            <span class="ph-value" id="ph-mktcap">-</span>
                        </div>
                    </div>
                </div>
                <div class="ph-actions">
                    <button class="ph-like-btn" id="watchlist-btn" onclick="toggleWatchlist(currentCode)">
                        <svg viewBox="0 0 24 24">
                            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                        </svg>
                        관심
                    </button>
                </div>
            </div>

            <!-- 본문 레이아웃 -->
            <div class="main-layout">

                <!-- 뉴스 패널 -->
                <div class="card panel-chat cm-news-panel" id="panel-chat">
                    <div class="cm-panel-title">뉴스</div>
                    <div class="cm-news-list">
                        <div class="cm-news-item">
                            <span class="cm-news-source">한국경제</span>
                            <span class="cm-news-time">5분 전</span>
                            <p class="cm-news-text">코스피, 기관 매수세에 강보합 마감...외국인 순매도 지속</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">머니투데이</span>
                            <span class="cm-news-time">23분 전</span>
                            <p class="cm-news-text">삼성전자, HBM 수주 소식에 장중 상승 전환</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">연합인포맥스</span>
                            <span class="cm-news-time">1시간 전</span>
                            <p class="cm-news-text">美 연준 금리 동결에 국내 증시 일제히 반등</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">서울경제</span>
                            <span class="cm-news-time">2시간 전</span>
                            <p class="cm-news-text">반도체 업종 강세...SK하이닉스 52주 신고가 경신</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">이데일리</span>
                            <span class="cm-news-time">3시간 전</span>
                            <p class="cm-news-text">2차전지 관련주 일제히 하락...수급 이탈 우려</p>
                        </div>
                        <div class="cm-news-item">
                            <span class="cm-news-source">파이낸셜뉴스</span>
                            <span class="cm-news-time">5시간 전</span>
                            <p class="cm-news-text">코스닥 바이오 섹터 강세, 임상 결과 기대감 반영</p>
                        </div>
                    </div>
                </div>

                <div class="resize-h" id="rh-0"></div>

                <!-- 피드 패널 -->
                <div class="card panel-chart cm-feed-panel" id="panel-chart">

                    <div class="cm-input-wrap" onclick="openPostModal()">
                        <div class="cm-input-avatar" id="cm-my-avatar">
                            <c:choose>
                                <c:when test="${not empty profileFileName}">
                                    <img src="/files/profile/${profileFileName}" alt="프로필" style="width:100%;height:100%;object-fit:cover;border-radius:50%;">
                                </c:when>
                                <c:otherwise>익</c:otherwise>
                            </c:choose>
                        </div>
                        <div class="cm-input-placeholder">
                            <span>지금 무슨 생각을 하고 있나요?</span>
                            <div class="cm-placeholder-icons">
                                <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.6"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
                            </div>
                        </div>
                    </div>

                    <!-- 글쓰기 모달 -->
                    <div class="cm-modal-overlay" id="cmModalOverlay" onclick="closePostModal()"></div>
                    <div class="cm-modal" id="cmModal">
                        <div class="cm-modal-header">
                            <span class="cm-modal-title"><span id="cmModalCode">${stockName}</span> <span class="cm-modal-arrow">›</span> 에 글 남기기</span>
                            <button class="cm-modal-close" onclick="closePostModal()">✕</button>
                        </div>
                        <input type="file" id="cmImageInput" accept="image/*" style="display:none" onchange="previewModalImage(this)">
                        <div class="cm-modal-body">
                            <div class="cm-modal-user">
                                <div class="cm-modal-avatar" id="cm-modal-avatar">
                                <c:choose>
                                    <c:when test="${not empty profileFileName}">
                                        <img src="/files/profile/${profileFileName}" alt="프로필" style="width:100%;height:100%;object-fit:cover;border-radius:50%;">
                                    </c:when>
                                    <c:otherwise>익</c:otherwise>
                                </c:choose>
                            </div>
                                <span class="cm-modal-username" id="cm-modal-username">${member.username}</span>
                            </div>
                            <textarea class="cm-modal-textarea" id="cm-modal-textarea" placeholder="지금 무슨 생각을 하고 있나요?" maxlength="2000" oninput="updateCharCount()"></textarea>
                            <div class="cm-modal-preview" id="cmImagePreview" style="display:none;">
                                <img id="cmPreviewImg" src="" alt="">
                                <button class="cm-preview-remove" onclick="removeModalImage()">✕</button>
                            </div>
                        </div>
                        <div class="cm-modal-footer">
                            <div class="cm-modal-tools">
                                <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.6" style="cursor:pointer" onclick="document.getElementById('cmImageInput').click()"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
                                <span class="cm-char-count"><span id="cmCharCount">0</span> / 2000</span>
                            </div>
                            <div class="cm-modal-bottom">
                                <button class="cm-modal-submit" onclick="submitComment()">남기기</button>
                            </div>
                        </div>
                    </div>

                    <!-- 나가기 확인 다이얼로그 -->
                    <div class="cm-confirm-overlay" id="cmConfirmOverlay"></div>
                    <div class="cm-confirm" id="cmConfirm">
                        <div class="cm-confirm-title">다음에 남길까요?</div>
                        <div class="cm-confirm-desc">지금까지 쓴 내용은 저장되지 않아요.</div>
                        <div class="cm-confirm-btns">
                            <button class="cm-confirm-keep" onclick="continueWriting()">이어 쓰기</button>
                            <button class="cm-confirm-leave" onclick="confirmLeave()">나가기</button>
                        </div>
                    </div>

                    <div class="cm-feed-filter">
                        <button class="cm-filter-btn active" id="btn-sort-latest" onclick="setSortMode('latest')">최신순</button>
                        <button class="cm-filter-btn" id="btn-sort-popular" onclick="setSortMode('popular')">인기순</button>
                    </div>

                    <div class="cm-feed-list" id="cmFeedList">
                        <div class="chat-empty">
                            <span class="chat-empty-icon">💬</span>
                            <span>첫 댓글을 남겨보세요</span>
                        </div>
                    </div>
                </div>

                <div class="resize-h" id="rh-1"></div>

                <!-- 주문 패널 -->
                <div class="panel-middle cm-order-panel" id="panel-middle">
                    <%
                        request.setAttribute("orderMarket", "stock");
                        request.setAttribute("orderPriceUnit", "원");
                        request.setAttribute("orderQtyUnit", "주");
                        request.setAttribute("orderQtyLabel", "수량 (주)");
                        request.setAttribute("orderQtyStep", "1");
                        request.setAttribute("orderPricePlaceholder", "0");
                        request.setAttribute("orderQtyPlaceholder", "0");
                        request.setAttribute("orderAmountUnit", "원");
                        request.setAttribute("orderAvailText", "- 원");
                    %>
                    <%@ include file="../common/market-order-panel.jsp" %>
                </div>

            </div><!-- /.main-layout -->

            <div class="ticker-bar">
                <div class="ticker-track" id="ticker-track"></div>
            </div>

        </div><!-- /.page -->

        <%@ include file="../common/sidebar.jsp" %>
        <%@ include file="../common/sidebar-icons.jsp" %>

    </div><!-- /.app-wrapper -->

    <div class="cm-image-modal" id="cmImageModal" onclick="this.classList.remove('open')">
        <img id="cmImageModalImg" src="" alt="">
    </div>

<script src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js"></script>
<script src="/js/common.js" defer></script>
<script src="/js/sidebar-data.js" defer></script>
<script>
    const currentCode   = "${code}";
    const isLoggedIn    = ${not empty member};
    const currentUser   = "${not empty member ? member.username : ''}";
    let orderSide = 'buy';
    window.currentSymbol = currentCode;
    window.lastPrice = 0;

    /* ── 아바타 초기화 ── */
    if (isLoggedIn && currentUser) {
        ['cm-my-avatar', 'cm-modal-avatar'].forEach(id => {
            const el = document.getElementById(id);
            if (el && !el.querySelector('img')) {
                el.textContent = currentUser.charAt(0).toUpperCase();
                el.style.background = cmAvatarColor(currentUser);
            }
        });
    }

    if (!isLoggedIn) {
        const wrap = document.querySelector('.cm-input-wrap');
        if (wrap) {
            wrap.innerHTML = '<div style="display:flex;align-items:center;gap:10px;padding:14px 16px;color:var(--text-sub);font-size:13px;">'
                + '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>'
                + '<span>댓글을 작성하려면 로그인이 필요합니다</span>'
                + '<a href="/member/login?redirect=' + encodeURIComponent(location.pathname + location.search) + '" style="margin-left:auto;padding:5px 14px;background:var(--blue);color:#fff;border-radius:6px;font-size:12px;text-decoration:none;">로그인</a>'
                + '</div>';
        }
    }

    /* ── 주식 가격 헤더 ── */
    async function loadStockTicker() {
        try {
            const res = await fetch('/stock/ticker?code=' + currentCode).then(r => r.json());
            const output = res.output;
            if (!output) return;

            const price = parseFloat(output.stck_prpr.replace(/,/g, '')) || 0;
            const diff  = parseFloat(output.prdy_vrss.replace(/,/g, '')) || 0;
            const rate  = parseFloat(output.prdy_ctrt) || 0;
            const cls   = rate >= 0 ? 'up' : 'down';
            const sign  = rate >= 0 ? '+' : '';

            document.getElementById('ph-display-name').textContent = output.hts_kor_isnm || '${stockName}';
            document.getElementById('ph-price').textContent = price.toLocaleString() + '원';
            const absEl = document.getElementById('ph-change-abs');
            const pctEl = document.getElementById('ph-change');
            if (absEl) { absEl.textContent = sign + diff.toLocaleString(); absEl.className = 'ph-change ' + cls; }
            if (pctEl) { pctEl.textContent = '(' + sign + rate.toFixed(2) + '%)'; pctEl.className = 'ph-change ' + cls; }

            window.lastPrice = price;
            document.getElementById('trade-price-input').value = price;
            calcAmount();
        } catch (e) {}
    }

    loadStockTicker();
    setInterval(loadStockTicker, 10000);

    /* ── 잔고 조회 ── */
    async function loadBalance() {
        try {
            const res = await fetch('/stock/account-balance').then(r => r.json());
            const bal = res.balance || 0;
            document.getElementById('avail-balance').textContent = bal.toLocaleString() + '원';
        } catch (e) {}
    }
    if (isLoggedIn) loadBalance();

    /* ── 주문 패널 ── */
    function switchOrderTab(side) {
        orderSide = side;
        const isBuy = side === 'buy';
        document.getElementById('tab-buy').classList.toggle('active', isBuy);
        document.getElementById('tab-sell').classList.toggle('active', !isBuy);
        const btn = document.getElementById('order-submit-btn');
        btn.textContent = isBuy ? '매수 주문' : '매도 주문';
        btn.className   = isBuy ? 'btn-buy' : 'btn-sell';
    }

    function selectOrderType(btn) {
        document.querySelectorAll('.order-type-btn').forEach(el => el.classList.remove('sel'));
        btn.classList.add('sel');
        const isMarket = btn.textContent.trim() === '시장가';
        const priceInput = document.getElementById('trade-price-input');
        priceInput.disabled = isMarket;
        priceInput.placeholder = isMarket ? '시장가' : '0';
        if (isMarket) priceInput.value = '';
        calcAmount();
    }

    function togglePctDrop() {
        const menu = document.getElementById('pct-drop-menu');
        if (menu) menu.style.display = menu.style.display === 'block' ? 'none' : 'block';
    }

    function setPercent(pct) {
        const label = document.getElementById('pct-drop-label');
        if (label) label.textContent = pct === 100 ? '최대' : pct + '%';
        const menu = document.getElementById('pct-drop-menu');
        if (menu) menu.style.display = 'none';

        const priceInput = document.getElementById('trade-price-input');
        const price = priceInput.disabled ? window.lastPrice : (parseFloat(priceInput.value) || window.lastPrice);
        const balText = document.getElementById('avail-balance').textContent.replace(/[^0-9]/g, '');
        const bal = parseInt(balText) || 0;
        if (price <= 0 || bal <= 0) return;
        document.getElementById('trade-qty').value = Math.floor(bal * pct / 100 / price);
        calcAmount();
    }

    function calcAmount() {
        const priceInput = document.getElementById('trade-price-input');
        const price = priceInput.disabled ? window.lastPrice : (parseFloat(priceInput.value) || window.lastPrice);
        const qty   = parseFloat(document.getElementById('trade-qty').value) || 0;
        document.getElementById('trade-amount').textContent = Math.floor(price * qty).toLocaleString();
    }

    function submitOrder(side) {
        if (!isLoggedIn) {
            location.href = '/member/login?redirect=' + encodeURIComponent(location.pathname + location.search);
            return;
        }

        const qtyInput = document.getElementById('trade-qty');
        const orderCount = parseInt(qtyInput.value);
        if (!orderCount || orderCount <= 0) {
            alert('수량을 정확히 입력하세요.');
            return;
        }

        const priceInput = document.getElementById('trade-price-input');
        const isMarket = priceInput.disabled;
        let orderPrice = isMarket ? window.lastPrice : parseInt((priceInput.value || '').replace(/[^0-9]/g, ''));
        if (!orderPrice || orderPrice <= 0) orderPrice = window.lastPrice;
        if (!orderPrice || orderPrice <= 0) {
            alert('현재 가격 또는 입력된 가격 정보를 가져오지 못했습니다.');
            return;
        }

        const sideText = side === 'sell' ? 'SELL' : 'BUY';
        const orderData = {
            orderType: sideText,
            orderPrice: orderPrice,
            orderCount: orderCount,
            stockNo: parseInt(window.currentSymbol) || 0,
            stockCode: String(window.currentSymbol || '').padStart(6, '0'),
            status: isMarket ? 'COMPLETED' : 'PENDING',
            targetPrice: isMarket ? 0 : orderPrice
        };

        if (!confirm('[주문 접수]\n구분: ' + (sideText === 'BUY' ? '매수' : '매도') + '\n가격: ' + orderPrice.toLocaleString() + '원\n수량: ' + orderCount + '주\n진행하시겠습니까?')) return;

        fetch('/stock/order?side=' + sideText, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(orderData)
        })
            .then(response => {
                if (!response.ok) throw new Error('서버 응답 오류');
                return response.json();
            })
            .then(data => {
                if (data.success === true || data.success === 'true') {
                    alert(data.message || '주문이 성공적으로 처리되었습니다.');
                    loadBalance();
                    if (typeof loadMyInvestmentStatus === 'function') loadMyInvestmentStatus();
                    if (typeof updateAccountBalanceUI === 'function') updateAccountBalanceUI();
                } else {
                    alert('주문 실패: ' + (data.message || '알 수 없는 오류'));
                }
            })
            .catch(err => {
                console.error('주식 커뮤니티 주문 전송 오류:', err);
                alert('주문 처리 중 통신 오류가 발생했습니다.');
            });
    }

    /* ── 종목 검색 드롭다운 ── */
    async function initSearchMenu() {
        const trigger  = document.getElementById('search-trigger');
        const dropdown = document.getElementById('search-dropdown');
        const input    = document.getElementById('sd-input');
        if (!trigger || !dropdown || !input) return;

        trigger.addEventListener('click', e => {
            e.stopPropagation();
            dropdown.classList.toggle('active');
            if (dropdown.classList.contains('active')) { input.value = ''; input.focus(); }
        });
        document.addEventListener('click', () => dropdown.classList.remove('active'));
        dropdown.addEventListener('click', e => e.stopPropagation());

        try {
            const res = await fetch('/stock/db-list?limit=40').then(r => r.json());
            const list = res.slice(0, 40);
            const container = document.getElementById('sd-list');

            const render = (items) => {
                container.innerHTML = items.map(s =>
                    '<div class="sd-item" onclick="location.href=\'/stock/community?code=' + encodeURIComponent(s.code || s.STOCK_CODE) + '\'">' +
                    '<div class="sd-info"><div class="sd-name-row"><span class="sd-name">' + (s.name || s.STOCK_NAME) + '</span><span class="sd-symbol">' + (s.code || s.STOCK_CODE) + '</span></div></div>' +
                    '</div>'
                ).join('');
            };

            render(list);

            input.addEventListener('input', () => {
                const kw = input.value.trim().toLowerCase();
                if (!kw) { render(list); return; }
                render(list.filter(s => (s.name || s.STOCK_NAME || '').toLowerCase().includes(kw) || (s.code || s.STOCK_CODE || '').includes(kw)));
            });
        } catch (e) {}
    }

    initSearchMenu();

    /* ── 커뮤니티 피드 ── */
    let _stompClient = null;
    let currentSort  = 'latest';

    function setSortMode(mode) {
        currentSort = mode;
        document.getElementById('btn-sort-latest').classList.toggle('active', mode === 'latest');
        document.getElementById('btn-sort-popular').classList.toggle('active', mode === 'popular');
        loadCommunityFeedHistory(currentCode);
    }

    function cmFeedAvatarColor(name) {
        const palette = ['#4caf50','#2196f3','#e91e63','#ff9800','#9c27b0','#00bcd4','#f44336','#3f51b5','#009688','#795548'];
        let h = 0;
        for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) & 0x7fffffff;
        return palette[h % palette.length];
    }

    function cmFeedRelTime(createdAt) {
        if (!createdAt) return '';
        const diff = Date.now() - new Date(createdAt).getTime();
        const m = Math.floor(diff / 60000);
        if (m < 1) return '방금';
        if (m < 60) return m + '분';
        const h = Math.floor(m / 60);
        if (h < 24) return h + '시간';
        return Math.floor(h / 24) + '일';
    }

    function appendFeedMsg(commentNo, username, content, createdAt, scroll, imageUrl, profileFileName, likeCount, likedByMe) {
        const feed = document.getElementById('cmFeedList');
        const empty = feed.querySelector('.chat-empty');
        if (empty) empty.remove();

        const safe = s => String(s).replace(/</g, '&lt;');
        const color = cmFeedAvatarColor(username);
        const initial = username.charAt(0).toUpperCase();
        const avatarHtml = profileFileName
            ? '<img src="/files/profile/' + profileFileName + '" style="width:100%;height:100%;object-fit:cover;border-radius:50%;">'
            : initial;
        const time = cmFeedRelTime(createdAt);
        const MAX = 100;
        const isTrunc = content.length > MAX;
        const preview = isTrunc ? safe(content.slice(0, MAX)) + '...' : safe(content);
        const full = safe(content);
        const imgHtml = imageUrl ? '<img class="cm-image" src="' + imageUrl + '" alt="" onclick="cmOpenImage(this)">' : '';
        const isOwn = isLoggedIn && username === currentUser;
        const ownerBtns = isOwn
            ? '<button class="cm-action-btn cm-edit-btn" onclick="startEditComment(this)">수정</button>'
            + '<button class="cm-action-btn cm-delete-btn" onclick="deleteComment(this)">삭제</button>'
            : '';

        const div = document.createElement('div');
        div.className = 'cm-feed-item';
        div.dataset.commentNo = commentNo;
        div.innerHTML =
            '<div class="cm-left">' +
                '<div class="cm-avatar" style="background:' + (profileFileName ? 'transparent' : color) + '">' + avatarHtml + '</div>' +
                '<span class="cm-rank">주주</span>' +
            '</div>' +
            '<div class="cm-right">' +
                '<div class="cm-meta"><span class="cm-name">' + safe(username) + '</span><span class="cm-time">' + time + '</span></div>' +
                '<div class="cm-text" data-full="' + full.replace(/"/g, '&quot;') + '" data-trunc="' + (isTrunc ? '1' : '0') + '">' +
                    preview + (isTrunc ? ' <button class="cm-more-btn" onclick="cmFeedToggleMore(this)">더 보기</button>' : '') +
                '</div>' +
                imgHtml +
                '<div class="cm-feed-actions">' +
                    '<button class="cm-action-btn cm-like-btn' + (likedByMe ? ' liked' : '') + '" data-liked="' + (likedByMe ? '1' : '0') + '">' +
                        '<svg viewBox="0 0 24 24" fill="' + (likedByMe ? '#e91e63' : 'none') + '" stroke="' + (likedByMe ? '#e91e63' : 'currentColor') + '" stroke-width="1.8" width="16" height="16"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>' +
                        '<span>' + (likeCount || 0) + '</span>' +
                    '</button>' +
                    ownerBtns +
                '</div>' +
            '</div>';

        const likeBtn = div.querySelector('.cm-like-btn');
        likeBtn.addEventListener('click', async function () {
            if (!isLoggedIn) { location.href = '/member/login?redirect=' + encodeURIComponent(location.pathname + location.search); return; }
            const res = await fetch('/api/market/comment/' + commentNo + '/like', { method: 'POST' });
            if (!res.ok) return;
            const data = await res.json();
            this.querySelector('span').textContent = data.count;
            const svg = this.querySelector('svg');
            svg.style.fill   = data.liked ? '#e91e63' : 'none';
            svg.style.stroke = data.liked ? '#e91e63' : 'currentColor';
        });

        if (scroll) feed.prepend(div); else feed.appendChild(div);
    }

    function cmFeedToggleMore(btn) {
        const textEl = btn.parentElement;
        textEl.innerHTML = textEl.dataset.full + ' <button class="cm-more-btn" onclick="cmFeedToggleLess(this)">접기</button>';
    }

    function cmFeedToggleLess(btn) {
        const textEl = btn.parentElement;
        const MAX = 100;
        const preview = textEl.dataset.full.slice(0, MAX) + '...';
        textEl.innerHTML = preview + ' <button class="cm-more-btn" onclick="cmFeedToggleMore(this)">더 보기</button>';
    }

    /* ── 댓글 작성/수정/삭제 ── */
    function openPostModal() {
        if (!isLoggedIn) { location.href = '/member/login?redirect=' + encodeURIComponent(location.pathname + location.search); return; }
        document.getElementById('cmModal').classList.add('open');
        document.getElementById('cmModalOverlay').classList.add('open');
        document.getElementById('cm-modal-textarea').focus();
        const avatarEl = document.getElementById('cm-modal-avatar');
        if (avatarEl && !avatarEl.querySelector('img') && currentUser) {
            avatarEl.textContent = currentUser.charAt(0).toUpperCase();
            avatarEl.style.background = cmFeedAvatarColor(currentUser);
        }
        if (currentUser) document.getElementById('cm-modal-username').textContent = currentUser;
    }

    function closePostModal() {
        const textarea = document.getElementById('cm-modal-textarea');
        if (textarea.value.trim()) {
            document.getElementById('cmConfirmOverlay').classList.add('open');
            document.getElementById('cmConfirm').classList.add('open');
        } else {
            _forceCloseModal();
        }
    }

    function continueWriting() {
        document.getElementById('cmConfirmOverlay').classList.remove('open');
        document.getElementById('cmConfirm').classList.remove('open');
    }

    function confirmLeave() {
        document.getElementById('cm-modal-textarea').value = '';
        document.getElementById('cmCharCount').textContent = '0';
        document.getElementById('cmConfirmOverlay').classList.remove('open');
        document.getElementById('cmConfirm').classList.remove('open');
        _forceCloseModal();
    }

    function _forceCloseModal() {
        document.getElementById('cmModal').classList.remove('open');
        document.getElementById('cmModalOverlay').classList.remove('open');
    }

    function updateCharCount() {
        document.getElementById('cmCharCount').textContent = document.getElementById('cm-modal-textarea').value.length;
    }

    function previewModalImage(input) {
        const file = input.files[0];
        if (!file) return;
        const reader = new FileReader();
        reader.onload = e => {
            document.getElementById('cmPreviewImg').src = e.target.result;
            document.getElementById('cmImagePreview').style.display = 'block';
        };
        reader.readAsDataURL(file);
    }

    function removeModalImage() {
        document.getElementById('cmImageInput').value = '';
        document.getElementById('cmPreviewImg').src = '';
        document.getElementById('cmImagePreview').style.display = 'none';
    }

    function submitComment() {
        const content = document.getElementById('cm-modal-textarea').value.trim();
        if (!content) return;

        const form = new FormData();
        form.append('marketType', 'STOCK');
        form.append('marketCode', currentCode);
        form.append('content', content);
        const fileInput = document.getElementById('cmImageInput');
        if (fileInput.files[0]) form.append('file', fileInput.files[0]);

        fetch('/api/market/comment', { method: 'POST', body: form })
            .then(r => {
                if (r.status === 401) { location.href = '/member/login?redirect=' + encodeURIComponent(location.pathname + location.search); return; }
                document.getElementById('cm-modal-textarea').value = '';
                document.getElementById('cmCharCount').textContent = '0';
                removeModalImage();
                _forceCloseModal();
            }).catch(() => {});
    }

    function deleteComment(btn) {
        if (!confirm('댓글을 삭제할까요?')) return;
        const item = btn.closest('.cm-feed-item');
        const commentNo = item.dataset.commentNo;
        const form = new FormData();
        form.append('marketType', 'STOCK');
        form.append('marketCode', currentCode);
        fetch('/api/market/comment/' + commentNo, { method: 'DELETE', body: form })
            .then(r => { if (r.ok) item.remove(); }).catch(() => {});
    }

    function startEditComment(btn) {
        const item = btn.closest('.cm-feed-item');
        const textEl = item.querySelector('.cm-text');
        const existingImg = item.querySelector('.cm-image');
        const existingUrl = existingImg ? existingImg.src : '';
        const original = textEl.dataset.full.replace(/&lt;/g, '<').replace(/&quot;/g, '"');
        if (existingImg) existingImg.style.display = 'none';

        const imgPreviewHtml = existingUrl
            ? '<div class="cm-edit-img-preview" style="position:relative;margin-top:6px;display:inline-block;">' +
              '<img src="' + existingUrl + '" style="max-width:100%;max-height:160px;border-radius:8px;display:block;">' +
              '<button onclick="removeEditImage(this)" style="position:absolute;top:4px;right:4px;background:rgba(0,0,0,0.6);border:none;color:#fff;width:22px;height:22px;border-radius:50%;cursor:pointer;font-size:12px;">✕</button>' +
              '</div>' : '';

        textEl.innerHTML =
            '<textarea class="cm-edit-textarea">' + original + '</textarea>' +
            imgPreviewHtml +
            '<div style="display:flex;align-items:center;gap:6px;margin-top:6px;">' +
            '<label style="cursor:pointer;color:var(--text3);font-size:12px;display:flex;align-items:center;gap:4px;">' +
            '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.6"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>' +
            '이미지<input type="file" class="cm-edit-file-input" accept="image/*" style="display:none" onchange="previewEditImage(this)"></label>' +
            '<input type="hidden" class="cm-edit-remove-flag" value="0">' +
            '<button class="cm-submit-btn" onclick="saveEditComment(this)">저장</button>' +
            '<button class="cm-action-btn" onclick="cancelEditComment(this)" data-original="' + textEl.dataset.full.replace(/"/g, '&quot;') + '" data-trunc="' + textEl.dataset.trunc + '">취소</button>' +
            '</div>';
    }

    function cancelEditComment(btn) {
        const textEl = btn.closest('.cm-text');
        const full = textEl.dataset.full;
        const MAX = 100;
        const isTrunc = textEl.dataset.trunc === '1';
        textEl.innerHTML = (isTrunc ? full.slice(0, MAX) + '...' : full) + (isTrunc ? ' <button class="cm-more-btn" onclick="cmFeedToggleMore(this)">더 보기</button>' : '');
        const item = btn.closest('.cm-feed-item');
        const img = item.querySelector('.cm-image');
        if (img) img.style.display = '';
    }

    function removeEditImage(btn) {
        const item = btn.closest('.cm-feed-item');
        item.querySelector('.cm-edit-remove-flag').value = '1';
        btn.closest('.cm-edit-img-preview').remove();
    }

    function previewEditImage(input) {
        const file = input.files[0];
        if (!file) return;
        const item = input.closest('.cm-feed-item');
        item.querySelector('.cm-edit-remove-flag').value = '0';
        let preview = item.querySelector('.cm-edit-img-preview');
        const actionsDiv = input.closest('div[style]');
        if (!preview) {
            preview = document.createElement('div');
            preview.className = 'cm-edit-img-preview';
            preview.style.cssText = 'position:relative;margin-top:6px;margin-bottom:6px;display:inline-block;';
            actionsDiv.before(preview);
        }
        const reader = new FileReader();
        reader.onload = e => {
            preview.innerHTML = '<img src="' + e.target.result + '" style="max-width:100%;max-height:160px;border-radius:8px;display:block;">' +
                '<button onclick="removeEditImage(this)" style="position:absolute;top:4px;right:4px;background:rgba(0,0,0,0.6);border:none;color:#fff;width:22px;height:22px;border-radius:50%;cursor:pointer;font-size:12px;">✕</button>';
        };
        reader.readAsDataURL(file);
    }

    function saveEditComment(btn) {
        const item = btn.closest('.cm-feed-item');
        const commentNo = item.dataset.commentNo;
        const textarea = item.querySelector('.cm-edit-textarea');
        const content = textarea.value.trim();
        if (!content) return;

        const fileInput = item.querySelector('.cm-edit-file-input');
        const removeFlag = item.querySelector('.cm-edit-remove-flag');
        const form = new FormData();
        form.append('marketType', 'STOCK');
        form.append('marketCode', currentCode);
        form.append('content', content);
        if (fileInput && fileInput.files[0]) form.append('file', fileInput.files[0]);
        if (removeFlag && removeFlag.value === '1') form.append('removeImage', 'true');

        fetch('/api/market/comment/' + commentNo, { method: 'PUT', body: form })
            .then(r => r.ok ? r.json() : null)
            .then(dto => {
                if (!dto) return;
                const textEl = item.querySelector('.cm-text');
                const safe = s => String(s).replace(/</g, '&lt;');
                const MAX = 100;
                const isTrunc = dto.content.length > MAX;
                const full = safe(dto.content);
                textEl.dataset.full = full;
                textEl.dataset.trunc = isTrunc ? '1' : '0';
                textEl.innerHTML = (isTrunc ? full.slice(0, MAX) + '...' : full) + (isTrunc ? ' <button class="cm-more-btn" onclick="cmFeedToggleMore(this)">더 보기</button>' : '');
                const existingImg = item.querySelector('.cm-image');
                if (dto.imageUrl) {
                    if (existingImg) { existingImg.src = dto.imageUrl; existingImg.style.display = ''; }
                    else {
                        const img = document.createElement('img');
                        img.className = 'cm-image';
                        img.src = dto.imageUrl;
                        img.alt = '';
                        img.setAttribute('onclick', 'cmOpenImage(this)');
                        textEl.after(img);
                    }
                } else if (existingImg) {
                    existingImg.remove();
                }
            }).catch(() => {});
    }

    /* ── STOMP 연결 ── */
    function loadCommunityFeedHistory(code) {
        fetch('/market/comments/STOCK/' + code + '?sort=' + currentSort)
            .then(r => r.json())
            .then(list => {
                const feed = document.getElementById('cmFeedList');
                feed.innerHTML = '';
                if (!list.length) {
                    feed.innerHTML = '<div class="chat-empty"><span class="chat-empty-icon">💬</span><span>첫 댓글을 남겨보세요</span></div>';
                    return;
                }
                list.forEach(dto => appendFeedMsg(dto.commentNo, dto.username, dto.content, dto.createdAt, false, dto.imageUrl, dto.profileFileName, dto.likeCount, dto.likedByMe));
            }).catch(() => {});
    }

    function connectCommunityFeed(code) {
        if (_stompClient) _stompClient.disconnect();
        const socket = new SockJS('/ws-stock');
        _stompClient = Stomp.over(socket);
        _stompClient.debug = null;
        _stompClient.connect({}, () => {
            _stompClient.subscribe('/topic/market/STOCK/' + code, msg => {
                const dto = JSON.parse(msg.body);
                if (dto.type === 'DELETE') {
                    const item = document.querySelector('.cm-feed-item[data-comment-no="' + dto.commentNo + '"]');
                    if (item) item.remove();
                } else if (dto.type === 'UPDATE') {
                    const item = document.querySelector('.cm-feed-item[data-comment-no="' + dto.commentNo + '"]');
                    if (item) {
                        const safe = s => String(s).replace(/</g, '&lt;');
                        const textEl = item.querySelector('.cm-text');
                        const full = safe(dto.content);
                        const MAX = 100;
                        const isTrunc = dto.content.length > MAX;
                        textEl.dataset.full = full;
                        textEl.innerHTML = (isTrunc ? full.slice(0, MAX) + '...' : full) + (isTrunc ? ' <button class="cm-more-btn" onclick="cmFeedToggleMore(this)">더 보기</button>' : '');
                    }
                } else {
                    appendFeedMsg(dto.commentNo, dto.username, dto.content, dto.createdAt, true, dto.imageUrl, dto.profileFileName, 0, false);
                }
            });
            loadCommunityFeedHistory(code);
        });
    }

    connectCommunityFeed(currentCode);
</script>
</body>
</html>
