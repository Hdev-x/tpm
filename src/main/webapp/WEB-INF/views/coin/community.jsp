<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>TradeBot · 커뮤니티</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/chart-toss-coin.css">
    <link rel="stylesheet" href="/css/coinCommunity.css">
</head>
<body class="chart-page" data-sidebar-tab="invest" data-sidebar-invest-tab="coin">

<div class="app-wrapper">
    <div class="page">

        <%@ include file="../common/nav.jsp" %>

        <!-- 코인 심볼 헤더 -->
        <div class="price-header">
            <div class="ph-left">
                <div class="ph-name-row search-trigger" id="search-trigger">
                    <div class="ph-name-group">
                        <span class="ph-name" id="ph-display-name">-</span>
                        <span class="ph-ticker">${symbol}</span>
                        <span class="ph-arrow">▾</span>
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
                        <span class="ph-label">전날 종가</span>
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
                        <span class="ph-label">24h 고가</span>
                        <span class="ph-value" id="ph-high">-</span>
                    </div>
                    <div class="ph-item">
                        <span class="ph-label">24h 저가</span>
                        <span class="ph-value" id="ph-low">-</span>
                    </div>
                </div>

                <div class="ph-vdivider"></div>

                <div class="ph-group">
                    <div class="ph-item">
                        <span class="ph-label">24h 거래량</span>
                        <span class="ph-value" id="ph-vol">-</span>
                    </div>
                    <div class="ph-item">
                        <span class="ph-label">24h 거래대금</span>
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
                <button class="ph-like-btn" id="watchlist-btn" onclick="toggleWatchlist(currentSymbol)">
                    <svg viewBox="0 0 24 24">
                        <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                    </svg>
                    관심
                </button>
            </div>
        </div>

        <!-- 3단 레이아웃 -->
        <div class="main-layout cm-page-layout">

            <!-- ── 왼쪽: 뉴스 ── -->
            <div class="card panel-chat cm-left-panel">
                <div class="cm-panel-title">뉴스</div>
                <div class="cm-news-list">
                    <div class="cm-news-item">
                        <span class="cm-news-source">코인데스크</span>
                        <span class="cm-news-time">5분 전</span>
                        <p class="cm-news-text">비트코인, 사상 최고가 경신 눈앞…기관 매수세 지속</p>
                    </div>
                    <div class="cm-news-item">
                        <span class="cm-news-source">블록미디어</span>
                        <span class="cm-news-time">23분 전</span>
                        <p class="cm-news-text">이더리움 ETF 순유입 3일 연속 증가…투자심리 회복</p>
                    </div>
                    <div class="cm-news-item">
                        <span class="cm-news-source">디지털애셋</span>
                        <span class="cm-news-time">1시간 전</span>
                        <p class="cm-news-text">연준 금리 동결에 암호화폐 시장 일제히 상승</p>
                    </div>
                    <div class="cm-news-item">
                        <span class="cm-news-source">코인니스</span>
                        <span class="cm-news-time">2시간 전</span>
                        <p class="cm-news-text">솔라나 네트워크 업그레이드 완료, 처리 속도 30% 향상</p>
                    </div>
                    <div class="cm-news-item">
                        <span class="cm-news-source">코인텔레그래프</span>
                        <span class="cm-news-time">3시간 전</span>
                        <p class="cm-news-text">글로벌 암호화폐 시총 3조 달러 돌파…강세장 진입 신호</p>
                    </div>
                    <div class="cm-news-item">
                        <span class="cm-news-source">블록미디어</span>
                        <span class="cm-news-time">5시간 전</span>
                        <p class="cm-news-text">바이낸스, 신규 코인 상장 발표…24시간 거래량 폭증</p>
                    </div>
                </div>
            </div>

            <div class="resize-h cm-resize" aria-hidden="true"></div>

            <!-- ── 가운데: 커뮤니티 피드 ── -->
            <div class="card panel-chart cm-feed-panel">

                <!-- 댓글 입력 -->
                <div class="cm-input-wrap">
                    <div class="cm-input-avatar">익</div>
                    <div class="cm-input-inner">
                        <textarea class="cm-input-box" placeholder="지금 무슨 생각을 하고 있나요?"></textarea>
                        <div class="cm-input-actions">
                            <button class="cm-input-icon-btn" title="이미지 업로드">
                                <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18">
                                    <path d="M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-1.1 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z"/>
                                </svg>
                            </button>
                            <button class="cm-submit-btn">등록</button>
                        </div>
                    </div>
                </div>

                <!-- 정렬 필터 -->
                <div class="cm-feed-filter">
                    <button class="cm-filter-btn active">인기순</button>
                    <button class="cm-filter-btn">최신순</button>
                </div>

                <!-- 댓글 목록 -->
                <div class="cm-feed-list" id="cmFeedList">

                    <div class="cm-feed-item">
                        <div class="cm-left">
                            <div class="cm-avatar" style="background:#4caf50">비</div>
                            <span class="cm-rank">주주</span>
                        </div>
                        <div class="cm-right">
                            <div class="cm-meta">
                                <span class="cm-name">비트코인매니아</span>
                                <span class="cm-time">5분</span>
                                <button class="cm-follow-btn">팔로우</button>
                            </div>
                            <div class="cm-text">지금 이 가격에 못 사면 평생 후회할 듯. 올해 안에 10만 달러 간다</div>
                            <div class="cm-feed-actions">
                                <button class="cm-action-btn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg> 24</button>
                                <button class="cm-action-btn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg> 7</button>
                                <button class="cm-action-btn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/></svg></button>
                            </div>
                        </div>
                    </div>

                    <div class="cm-feed-item">
                        <div class="cm-left">
                            <div class="cm-avatar" style="background:#2196f3">소</div>
                            <span class="cm-rank">주주</span>
                        </div>
                        <div class="cm-right">
                            <div class="cm-meta">
                                <span class="cm-name">소액투자자</span>
                                <span class="cm-time">13분</span>
                                <button class="cm-follow-btn">팔로우</button>
                            </div>
                            <div class="cm-text">커피 한 잔 값으로 비트 얼마나 살 수 있지</div>
                            <div class="cm-feed-actions">
                                <button class="cm-action-btn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg> 13</button>
                                <button class="cm-action-btn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg> 3</button>
                                <button class="cm-action-btn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/></svg></button>
                            </div>
                        </div>
                    </div>

                    <div class="cm-feed-item">
                        <div class="cm-left">
                            <div class="cm-avatar" style="background:#e91e63">호</div>
                            <span class="cm-rank">주주</span>
                        </div>
                        <div class="cm-right">
                            <div class="cm-meta">
                                <span class="cm-name">호들러123</span>
                                <span class="cm-time">27분</span>
                                <button class="cm-follow-btn">팔로우</button>
                            </div>
                            <div class="cm-text">멘탈 관리가 진짜 답이다. 떨어진다고 팔면 안 되고 오른다고 더 사면 안 되고. 그냥 존버가 답</div>
                            <div class="cm-feed-actions">
                                <button class="cm-action-btn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg> 6</button>
                                <button class="cm-action-btn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg> 4</button>
                                <button class="cm-action-btn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="15" height="15"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/></svg></button>
                            </div>
                        </div>
                    </div>

                </div>
            </div>

            <div class="resize-h cm-resize" aria-hidden="true"></div>

            <!-- ── 오른쪽: 주문하기 ── -->
            <div class="panel-middle cm-right-panel">
                <div class="card panel-order-wrap" id="panel-order-wrap">
                    <div class="order-tabs">
                        <div class="order-tab buy active" id="tab-buy" onclick="switchOrderTab('buy')">매수</div>
                        <div class="order-tab sell" id="tab-sell" onclick="switchOrderTab('sell')">매도</div>
                    </div>
                    <div class="order-panel" id="panel-order">
                        <div class="order-type-row">
                            <button class="order-type-btn sel" onclick="selectOrderType(this)">지정가</button>
                            <button class="order-type-btn" onclick="selectOrderType(this)">시장가</button>
                        </div>
                        <div class="order-section-label">가격 (USDT)</div>
                        <div class="order-input-row">
                            <input class="order-input" id="trade-price-input" type="number" placeholder="0.00" oninput="calcAmount()">
                            <span class="order-input-unit">USDT</span>
                        </div>
                        <div class="order-section-label">수량</div>
                        <div class="order-input-row">
                            <input class="order-input" id="trade-qty" type="number" placeholder="0.000" step="0.001" oninput="calcAmount()">
                            <span class="order-input-unit" id="cm-qty-unit">${symbol}</span>
                        </div>
                        <div class="pct-row">
                            <button class="pct-btn" onclick="setPercent(25)">25%</button>
                            <button class="pct-btn" onclick="setPercent(50)">50%</button>
                            <button class="pct-btn" onclick="setPercent(75)">75%</button>
                            <button class="pct-btn" onclick="setPercent(100)">최대</button>
                        </div>
                        <div class="order-section-label">주문금액 (USDT)</div>
                        <div class="order-input-row" style="margin-bottom:14px">
                            <input class="order-input" id="trade-amount" type="number" readonly style="background:var(--bg)">
                            <span class="order-input-unit">USDT</span>
                        </div>
                        <div class="order-avail">가용 잔고 <span>- USDT</span></div>
                        <button id="order-submit-btn" class="btn-buy" onclick="submitCommunityOrder()">매수 주문</button>
                    </div>
                </div>
            </div>

        </div><!-- /.cm-page-layout -->

    </div><!-- /.page -->

    <%@ include file="../common/sidebar.jsp" %>
    <%@ include file="../common/sidebar-icons.jsp" %>

</div><!-- /.app-wrapper -->

<div class="cm-image-modal" id="cmImageModal" onclick="this.classList.remove('open')">
    <img id="cmImageModalImg" src="" alt="">
</div>

<script src="/js/common.js"></script>
<script>
    const currentSymbol = "${symbol}";
    let orderSide = 'buy';

    function formatCommunityNumber(value) {
        if (!Number.isFinite(value)) return '-';
        if (Math.abs(value) >= 1_000_000_000) return (value / 1_000_000_000).toFixed(2) + 'B';
        if (Math.abs(value) >= 1_000_000) return (value / 1_000_000).toFixed(2) + 'M';
        if (Math.abs(value) >= 1_000) return value.toLocaleString(undefined, { maximumFractionDigits: 2 });
        return value.toLocaleString(undefined, { maximumFractionDigits: 6 });
    }

    async function loadCommunityTicker() {
        const tickerName = currentSymbol.replace(/USDT$/, '').replace(/USDC$/, '').replace(/_SPBL$/, '');
        document.getElementById('ph-display-name').textContent = tickerName;
        document.querySelector('.ph-ticker').textContent = currentSymbol;
        document.getElementById('cm-qty-unit').textContent = tickerName;

        try {
            const res = await fetch('https://api.bitget.com/api/v2/spot/market/tickers?symbol=' + encodeURIComponent(currentSymbol)).then(r => r.json());
            const d = res && res.data && res.data[0];
            if (!d) return;

            const price = parseFloat(d.lastPr);
            const open = parseFloat(d.openUtc);
            const changeAbs = price - open;
            const changePct = open > 0 ? changeAbs / open * 100 : 0;
            const changeClass = changeAbs >= 0 ? 'up' : 'down';
            const sign = changeAbs >= 0 ? '+' : '';

            document.getElementById('ph-price').textContent = '$' + price.toLocaleString(undefined, { maximumFractionDigits: 6 });
            document.getElementById('ph-change-abs').textContent = sign + changeAbs.toLocaleString(undefined, { maximumFractionDigits: 6 });
            document.getElementById('ph-change-abs').className = 'ph-change ' + changeClass;
            document.getElementById('ph-change').textContent = '(' + sign + changePct.toFixed(2) + '%)';
            document.getElementById('ph-change').className = 'ph-change ' + changeClass;
            document.getElementById('ph-prev-close').textContent = '$' + open.toLocaleString(undefined, { maximumFractionDigits: 6 });
            document.getElementById('ph-open').textContent = '$' + open.toLocaleString(undefined, { maximumFractionDigits: 6 });
            document.getElementById('ph-high').textContent = '$' + parseFloat(d.high24h).toLocaleString(undefined, { maximumFractionDigits: 6 });
            document.getElementById('ph-low').textContent = '$' + parseFloat(d.low24h).toLocaleString(undefined, { maximumFractionDigits: 6 });
            document.getElementById('ph-vol').textContent = formatCommunityNumber(parseFloat(d.baseVolume)) + ' ' + tickerName;
            document.getElementById('ph-turnover').textContent = formatCommunityNumber(parseFloat(d.quoteVolume)) + ' USDT';
            document.getElementById('trade-price-input').value = Number.isFinite(price) ? price : '';
            calcAmount();
        } catch (e) {
            console.error('커뮤니티 티커 로딩 실패:', e);
        }
    }

    async function loadCommunityMarketCap() {
        const ticker = currentSymbol.replace(/USDT$/, '').replace(/USDC$/, '').replace(/_SPBL$/, '').toLowerCase();
        try {
            const res = await fetch('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&symbols=' + encodeURIComponent(ticker) + '&order=market_cap_desc&per_page=1&page=1&sparkline=false').then(r => r.json());
            const mktcap = Array.isArray(res) && res[0] ? Number(res[0].market_cap) : NaN;
            document.getElementById('ph-mktcap').textContent = Number.isFinite(mktcap) ? '$' + formatCommunityNumber(mktcap) : '-';
        } catch (e) {
            document.getElementById('ph-mktcap').textContent = '-';
        }
    }

    function switchOrderTab(side) {
        orderSide = side;
        const isBuy = side === 'buy';
        document.getElementById('tab-buy').classList.toggle('active', isBuy);
        document.getElementById('tab-sell').classList.toggle('active', !isBuy);
        const submitBtn = document.getElementById('order-submit-btn');
        submitBtn.textContent = isBuy ? '매수 주문' : '매도 주문';
        submitBtn.className = isBuy ? 'btn-buy' : 'btn-sell';
    }

    function selectOrderType(btn) {
        document.querySelectorAll('.order-type-btn').forEach(el => el.classList.remove('sel'));
        btn.classList.add('sel');
        const priceInput = document.getElementById('trade-price-input');
        const isLimit = btn.textContent.trim() === '지정가';
        priceInput.readOnly = !isLimit;
        if (!isLimit && !priceInput.value) priceInput.value = document.getElementById('ph-price').textContent.replace(/[^0-9.]/g, '');
        calcAmount();
    }

    function setPercent(pct) {
        const price = parseFloat(document.getElementById('trade-price-input').value) || 0;
        if (price <= 0) return;
        const mockBalance = 10000;
        document.getElementById('trade-qty').value = (mockBalance * pct / 100 / price).toFixed(6);
        calcAmount();
    }

    function calcAmount() {
        const price = parseFloat(document.getElementById('trade-price-input').value) || 0;
        const qty = parseFloat(document.getElementById('trade-qty').value) || 0;
        document.getElementById('trade-amount').value = (price * qty).toFixed(2);
    }

    function submitCommunityOrder() {
        const qty = document.getElementById('trade-qty').value;
        if (!qty || parseFloat(qty) <= 0) {
            alert('수량을 입력하세요');
            return;
        }
        alert((orderSide === 'buy' ? '매수' : '매도') + ' 주문 기능은 준비 중입니다.');
    }

    loadCommunityTicker();
    loadCommunityMarketCap();
</script>

</body>
</html>
