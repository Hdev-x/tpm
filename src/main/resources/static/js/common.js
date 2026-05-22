/* =====================================================
   common.js
   모든 페이지에서 공통으로 사용하는 JS
   nav, sidebar 관련 함수 등
   ===================================================== */

/* ====================================================
   달러 / 원 통화 토글
   ==================================================== */
let currencyMode = localStorage.getItem('currencyMode') || 'usd';
let usdToKrw = 1;

// 전역 상태 변수가 이미 선언되어 있는지 확인 후 초기화 (shadowing 방지)
if (typeof window.currentSymbol === 'undefined') window.currentSymbol = null;
if (typeof window.lastPrice === 'undefined') window.lastPrice = 0;

async function fetchExchangeRate() {
    try {
        const res = await fetch('https://open.er-api.com/v6/latest/USD').then(r => r.json());
        if (res && res.rates && res.rates.KRW) {
            usdToKrw = res.rates.KRW;
            const rateEl = document.getElementById('ex-current-rate');
            if (rateEl) rateEl.textContent = `현재 환율: 1$ = ${usdToKrw.toLocaleString()}원`;
            // 환율 로드 완료 후 의존 함수 재실행 (defer 로딩 경쟁 조건 해소)
            if (typeof updateAsset === 'function') updateAsset();
            if (typeof updateExchangeUI === 'function') updateExchangeUI();
        }
    } catch (e) {}
}

function setCurrency(mode) {
    if (currencyMode === mode) return;
    currencyMode = mode;
    localStorage.setItem('currencyMode', mode);
    document.getElementById('cur-switch')?.classList.toggle('krw', mode === 'krw');
    renderWatchlistCoins('watchlist-coin-list', watchlistCoins);
    renderWatchlistCoins('watchlist-coin-all-list', watchlistCoins);
    renderRecentCoins(recentCoins);
}

function fmtCoinPrice(price) {
    if (currencyMode === 'krw') {
        const krw = price * usdToKrw;
        return krw.toLocaleString(undefined, { maximumFractionDigits: 0 }) + '원';
    }
    return '$' + price.toLocaleString(undefined, { maximumFractionDigits: 2 });
}

function fmtCoinChange(price, change) {
    if (change === null) return '-';
    const sign = change >= 0 ? '+' : '';
    const changeAmt = price - price / (1 + change / 100);
    if (currencyMode === 'krw') {
        const krwAmt = changeAmt * usdToKrw;
        return sign + krwAmt.toLocaleString(undefined, { maximumFractionDigits: 0 }) + '원 (' + sign + change.toFixed(2) + '%)';
    }
    return sign + '$' + Math.abs(changeAmt).toFixed(2) + ' (' + sign + change.toFixed(2) + '%)';
}

function fmtNum(n) {
    if (n >= 1_000_000_000) return (n / 1_000_000_000).toFixed(2) + 'B';
    if (n >= 1_000_000) return (n / 1_000_000).toFixed(2) + 'M';
    if (n >= 1_000) return (n / 1_000).toFixed(2) + 'K';
    return n.toFixed(2);
}


/* ====================================================
   사이드바 슬라이드 토글
   ==================================================== */
const SIDEBAR_TITLES = { invest: '내 투자현황', interest: '관심 종목', recent: '최근 본', live: '실시간' };
let sidebarActiveTab = null;
let lastSidebarTab = null;
let sidebarReady = false;

function toggleSidebar(tab) {
    const panel = document.getElementById('sidebar-panel');
    if (sidebarActiveTab === tab) { closeSidebar(); return; }

    const prevSection = sidebarActiveTab ? document.getElementById('sidebar-' + sidebarActiveTab) : null;
    sidebarActiveTab = tab;
    panel.classList.add('open');
    document.querySelectorAll('.si-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('si-' + tab).classList.add('active');
    document.getElementById('sidebar-title').textContent = SIDEBAR_TITLES[tab] || tab;
    const subTitle = document.getElementById('sidebar-title-sub');
    if (subTitle) {
        if (tab === 'live') {
            const now = new Date();
            const hh = String(now.getHours()).padStart(2, '0');
            const mm = String(now.getMinutes()).padStart(2, '0');
            subTitle.textContent = '오늘 ' + hh + ':' + mm + ' 기준';
            subTitle.style.display = '';
        } else {
            subTitle.style.display = 'none';
        }
    }
    localStorage.setItem('sidebar', tab);

    document.getElementById('si-fold-btn')?.classList.remove('folded');
    const curSwitch = document.getElementById('cur-switch');
    if (curSwitch) curSwitch.style.display = tab === 'invest' ? 'none' : '';
    const nextSection = document.getElementById('sidebar-' + tab);

    document.querySelectorAll('.sidebar-section').forEach(s => {
        s.style.display = 'none';
        s.classList.remove('sb-entering');
    });

    nextSection.style.display = '';

    if (tab === 'interest') {
        const firstTab = nextSection.querySelector('.si-type-tab');
        if (firstTab) switchInterestTab(firstTab, 'all');
    }
    if (tab === 'recent') {
        const firstTab = nextSection.querySelector('.si-type-tab');
        if (firstTab) switchRecentTab(firstTab, 'all');
    }
    if (tab === 'invest') {
        updateExchangeUI();
    }

    if (sidebarReady) {
        void nextSection.offsetWidth;
        nextSection.classList.add('sb-entering');
        setTimeout(() => nextSection.classList.remove('sb-entering'), 200);
    }
}

function closeSidebar() {
    lastSidebarTab = sidebarActiveTab;
    if (sidebarActiveTab) localStorage.setItem('lastSidebarTab', sidebarActiveTab);
    sidebarActiveTab = null;
    document.getElementById('sidebar-panel').classList.remove('open');
    document.querySelectorAll('.si-btn').forEach(b => b.classList.remove('active'));
    localStorage.removeItem('sidebar');
    document.getElementById('si-fold-btn')?.classList.add('folded');
}

function restoreSidebarNoAnim(tab) {
    const panel = document.getElementById('sidebar-panel');
    panel.style.transition = 'none';
    sidebarActiveTab = tab;
    panel.classList.add('open');
    document.querySelectorAll('.si-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('si-' + tab)?.classList.add('active');
    if (document.getElementById('sidebar-title'))
        document.getElementById('sidebar-title').textContent = SIDEBAR_TITLES[tab] || tab;
    const subTitle = document.getElementById('sidebar-title-sub');
    if (subTitle) subTitle.style.display = tab === 'live' ? '' : 'none';
    document.getElementById('si-fold-btn')?.classList.remove('folded');
    const curSwitch = document.getElementById('cur-switch');
    if (curSwitch) curSwitch.style.display = tab === 'invest' ? 'none' : '';
    document.querySelectorAll('.sidebar-section').forEach(s => s.style.display = 'none');
    const nextSection = document.getElementById('sidebar-' + tab);
    if (nextSection) nextSection.style.display = '';
    requestAnimationFrame(() => { panel.style.transition = ''; sidebarReady = true; });
}

function toggleFold() {
    const panel = document.getElementById('sidebar-panel');
    if (panel.classList.contains('open')) {
        closeSidebar();
    } else {
        const tab = lastSidebarTab || localStorage.getItem('lastSidebarTab') || localStorage.getItem('sidebar') || 'live';
        toggleSidebar(tab);
    }
}


/* ====================================================
   사이드바 탭 전환 (포지션 / 오더 / 기록)
   ==================================================== */
function swapInterestGroups() {
    const container = document.getElementById('si-all-container');
    const stock = document.getElementById('si-group-stock');
    const coin = document.getElementById('si-group-coin');
    if (stock.nextElementSibling === coin) {
        container.appendChild(stock);
        localStorage.setItem('interestGroupOrder', 'coin');
    } else {
        container.insertBefore(stock, coin);
        localStorage.setItem('interestGroupOrder', 'stock');
    }
}

function switchInterestTab(el, tab) {
    document.querySelectorAll('#sidebar-interest .si-type-tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    document.querySelectorAll('.si-tab-content').forEach(c => c.style.display = 'none');
    document.getElementById('interest-' + tab).style.display = '';
    localStorage.setItem('interestTab2', tab);

    const container = document.getElementById('si-all-container');
    const stock = document.getElementById('si-group-stock');
    const coin = document.getElementById('si-group-coin');
    if (!container || !stock || !coin) return;
    if (tab === 'coin' && container.firstElementChild !== coin) {
        container.insertBefore(coin, stock);
    } else if (tab === 'stock' && container.firstElementChild !== stock) {
        container.insertBefore(stock, coin);
    }
}

function switchInvestTab(el, tab) {
    el.closest('.si-type-tabs').querySelectorAll('.si-type-tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    ['stock', 'coin', 'exchange'].forEach(t => {
        const el = document.getElementById('invest-' + t);
        if (el) el.style.display = t === tab ? 'flex' : 'none';
    });
    localStorage.setItem('investTab', tab);
}

function switchBpTab(el, tab) {
    // 1. 탭 버튼 활성화
    const tabsEl = el.closest('.sb-tabs');
    if (!tabsEl) return;
    tabsEl.querySelectorAll('.sb-tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');

    // 2. 패널 전환 및 클래스 제어
    const contentWrapper = tabsEl.parentElement;
    contentWrapper.querySelectorAll('.sb-content').forEach(panel => {
        panel.classList.remove('active', 'active-panel');
        panel.style.display = 'none'; // 명시적 숨김
    });

    const targetPanel = document.getElementById('tab-' + tab);
    if (targetPanel) {
        targetPanel.classList.add('active', 'active-panel');
        targetPanel.style.display = 'flex';

        // 3. 데이터 갱신 (테이블 표시 여부는 각 render 함수가 결정)
        if (typeof loadMyInvestmentStatus === 'function') {
            loadMyInvestmentStatus();
        }
    }
}


/* ====================================================
   환전 (Exchange) 엔진
   ==================================================== */
let exchangeDirection = 'krw-to-usdt'; // 'krw-to-usdt' or 'usdt-to-krw'

function toggleExchangeDirection() {
    const fromLabel = document.getElementById('ex-from-label');
    const toLabel = document.getElementById('ex-to-label');
    const fromUnit = document.getElementById('ex-from-unit');
    const toUnit = document.getElementById('ex-to-unit');
    const submitBtn = document.getElementById('ex-submit-btn');

    if (exchangeDirection === 'krw-to-usdt') {
        exchangeDirection = 'usdt-to-krw';
        fromLabel.textContent = '보낼 금액 (USDT)';
        toLabel.textContent = '받을 금액 (KRW)';
        fromUnit.textContent = 'USDT';
        toUnit.textContent = '원';
    } else {
        exchangeDirection = 'krw-to-usdt';
        fromLabel.textContent = '보낼 금액 (KRW)';
        toLabel.textContent = '받을 금액 (USDT)';
        fromUnit.textContent = '원';
        toUnit.textContent = 'USDT';
    }

    document.getElementById('ex-amount-input').value = '';
    document.getElementById('ex-result-display').value = '0.00';
    calculateExchange();
}

function calculateExchange() {
    const input = document.getElementById('ex-amount-input');
    const display = document.getElementById('ex-result-display');
    const amount = parseFloat(input.value) || 0;

    if (exchangeDirection === 'krw-to-usdt') {
        display.value = (amount / usdToKrw).toFixed(2);
    } else {
        display.value = Math.floor(amount * usdToKrw).toLocaleString() + ' 원';
    }
}

async function executeExchange() {
    const amount = parseFloat(document.getElementById('ex-amount-input').value);
    if (!amount || amount <= 0) { alert('환전할 금액을 입력하세요.'); return; }

    const url = exchangeDirection === 'krw-to-usdt' ? '/api/exchange/krw-to-usdt' : '/api/exchange/usdt-to-krw';
    const params = new URLSearchParams();

    if (exchangeDirection === 'krw-to-usdt') {
        params.append('krwAmount', amount);
    } else {
        params.append('usdtAmount', amount);
    }
    params.append('rate', usdToKrw);

    try {
        const res = await fetch(url, { method: 'POST', body: params }).then(r => r.json());
        if (res.success) {
            alert('환전이 완료되었습니다.');
            document.getElementById('ex-amount-input').value = '';
            document.getElementById('ex-result-display').value = '';
            updateExchangeUI();                                               // 환전 패널 잔고 갱신
            if (typeof loadMyInvestmentStatus === 'function') loadMyInvestmentStatus();
            if (typeof updateAccountBalanceUI === 'function') updateAccountBalanceUI();
            if (typeof loadWallet === 'function') loadWallet();
            if (typeof updateAsset === 'function') updateAsset();             // 내 계좌 페이지 갱신
        } else {
            alert('환전 실패: ' + res.message);
        }
    } catch (e) {
        console.error('환전 에러', e);
        alert('환전 처리 중 오류가 발생했습니다.');
    }
}

function updateExchangeUI() {
    const rateEl = document.getElementById('ex-current-rate');
    // usdToKrw 변수가 정의되어 있는지 안전하게 확인 후 출력
    if (rateEl && typeof usdToKrw !== 'undefined') {
        rateEl.textContent = `현재 환율: 1$ = ${usdToKrw.toLocaleString()}원`;
    }

    const availKrwEl = document.getElementById('ex-avail-krw');
    const availUsdtEl = document.getElementById('ex-avail-usdt');

    // 1. 예수금 (KRW) 업데이트
    fetch('/stock/account-balance')
        .then(r => {
            if (!r.ok) throw new Error('KRW 잔액 조회 실패');
            return r.text(); // json() 대신 text()로 먼저 받기
        })
        .then(text => text ? JSON.parse(text) : {}) // 비어있으면 빈 객체 반환
        .then(data => {
            if (availKrwEl && data && typeof data.balance !== 'undefined') {
                availKrwEl.textContent = Math.floor(data.balance).toLocaleString() + ' 원';
            } else if (availKrwEl) {
                availKrwEl.textContent = '0 원';
            }
        })
        .catch(err => console.error("예수금 조회 오류:", err));

    // 2. 투자금 (USDT) 업데이트
    fetch('/coin/wallet') // 👈 깔끔하게 파라미터(?username=...)를 제거했습니다!
        .then(r => {
            if (!r.ok) throw new Error('USDT 잔액 조회 실패');
            return r.text(); // 빈 응답 체크를 위해 text()로 먼저 받기
        })
        .then(text => text ? JSON.parse(text) : {}) // 서버 응답이 비어있으면 빈 객체({}) 반환
        .then(data => {
            // 성공적으로 데이터를 받았고, usdtBalance 필드가 존재하는 경우
            if (availUsdtEl && data && typeof data.usdtBalance !== 'undefined') {
                availUsdtEl.textContent = Number(data.usdtBalance).toFixed(2) + ' USDT';
            } else if (availUsdtEl) {
                // 데이터가 없거나 로그아웃 상태일 때 기본값 처리
                availUsdtEl.textContent = '0.00 USDT';
            }
        })
        .catch(err => console.error("코인 지갑 조회 오류:", err));
}

let holdingsData = [];
let holdingsWs = null;
let holdingsPingTimer = null;
let cachedPrices = JSON.parse(localStorage.getItem('holdingPrices') || '{}');

function skeletonCard() {
    return '<div class="holding-card hc-main skeleton-card">'
        + '<div class="hc-main-header">'
        + '<div class="hc-main-id">'
        + '<div class="hc-logo skeleton" style="background:transparent;"></div>'
        + '<div class="hc-main-name-col">'
        + '<span class="skeleton" style="width:70px;height:13px;display:block;"></span>'
        + '<span class="skeleton" style="width:90px;height:11px;display:block;margin-top:4px;"></span>'
        + '</div>'
        + '</div>'
        + '<div class="hc-main-right">'
        + '<span class="skeleton" style="width:80px;height:13px;display:block;"></span>'
        + '<span class="skeleton" style="width:100px;height:11px;display:block;margin-top:4px;"></span>'
        + '</div>'
        + '</div>'
        + '<div class="hc-divider"></div>'
        + '<div class="hc-main-grid">'
        + '<div class="hc-main-row"><span class="skeleton" style="width:50px;height:11px;"></span><span class="skeleton" style="width:60px;height:11px;"></span></div>'
        + '<div class="hc-main-row"><span class="skeleton" style="width:50px;height:11px;"></span><span class="skeleton" style="width:60px;height:11px;"></span></div>'
        + '<div class="hc-main-row"><span class="skeleton" style="width:50px;height:11px;"></span><span class="skeleton" style="width:60px;height:11px;"></span></div>'
        + '<div class="hc-main-row"><span class="skeleton" style="width:50px;height:11px;"></span><span class="skeleton" style="width:60px;height:11px;"></span></div>'
        + '</div>'
        + '</div>';
}

function coinLogoColor(code) {
    const colors = ['#F7931A', '#627EEA', '#00AAC1', '#E84142', '#2775CA', '#26A17B', '#9945FF', '#E6007A'];
    let h = 0;
    for (let i = 0;i < code.length;i++) h = (h * 31 + code.charCodeAt(i)) & 0xffff;
    return colors[h % colors.length];
}

function coinLogoHtml(ticker) {
    const fallback = ticker.slice(0, 3);
    const color = coinLogoColor(ticker);
    const url = 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/' + ticker.toLowerCase() + '.png';
    return '<div class="hc-logo hc-logo-wrap">'
        + '<img src="' + url + '" alt="' + ticker + '" class="hc-logo-img"'
        + ' onerror="this.parentElement.style.background=\'' + color + '\';this.parentElement.textContent=\'' + fallback + '\'">'
        + '</div>';
}

function renderHoldings(data) {
    const container = document.getElementById('bp-holdings-body');
    if (!container) return;

    const sellAllWrap = document.getElementById('bp-sell-all-wrap');
    if (data.length > 0) {
        document.getElementById('bp-empty').style.display = 'none';
        if (sellAllWrap) sellAllWrap.style.display = '';

        data.forEach(h_raw => {
            // 키 정규화
            const h = Object.keys(h_raw).reduce((acc, k) => { acc[k.toLowerCase().replace(/_/g, '')] = h_raw[k]; return acc; }, {});

            const coinCode = h.coincode;
            const coinCount = h.coincount;
            const avgPrice = h.avgprice;

            const price = cachedPrices[coinCode] || null;
            const evalAmt = price !== null ? price * coinCount : null;
            const buyAmt = avgPrice * coinCount;
            const pnl = evalAmt !== null ? evalAmt - buyAmt : null;
            const pct = pnl !== null && buyAmt > 0 ? (pnl / buyAmt * 100) : null;
            const cls = pnl !== null ? (pnl >= 0 ? 'up' : 'down') : '';
            const sign = pnl !== null && pnl >= 0 ? '+' : '';
            const arrow = pnl !== null ? (pnl >= 0 ? '▲' : '▼') : '';

            let card = container.querySelector('[data-coin="' + coinCode + '"]');
            if (card) {
                if (price !== null) {
                    card.querySelector('.hc-main-eval').textContent = evalAmt.toLocaleString(undefined, { maximumFractionDigits: 2 }) + ' USDT';
                    const pnlEl = card.querySelector('.hc-main-pnl');
                    pnlEl.textContent = arrow + Math.abs(pnl).toFixed(2) + ' (' + sign + pct.toFixed(2) + '%)';
                    pnlEl.className = 'hc-main-pnl ' + cls;
                    card.querySelector('.hc-price-val').textContent = price.toLocaleString(undefined, { maximumFractionDigits: 6 });
                    card.querySelector('.hc-eval-val').textContent = (evalAmt !== null ? evalAmt.toLocaleString(undefined, { maximumFractionDigits: 2 }) : '-') + ' USDT';
                }
            } else {
                const ticker = coinCode.replace(/USDT$/, '').replace('_SPBL', '');
                const div = document.createElement('div');
                div.className = 'holding-card hc-main';
                div.dataset.coin = coinCode;
                div.style.cursor = 'pointer';
                div.onclick = () => location.href = '/coin/chart?symbol=' + coinCode;
                div.innerHTML =
                    '<div class="hc-main-header">'
                    + '<div class="hc-main-id">'
                    + coinLogoHtml(ticker)
                    + '<div class="hc-main-name-col">'
                    + '<div style="display:flex; align-items:center; gap:6px;">'
                    + '<span class="hc-main-ticker">' + ticker + '</span>'
                    + '<button onclick="event.stopPropagation(); sellCoinMarket(\'' + coinCode + '\', ' + coinCount + ')" '
                    + 'style="padding:2px 8px; border:1px solid rgba(240,68,82,0.4); border-radius:5px; background:transparent; color:#f04452; font-size:11px; font-weight:600; cursor:pointer; line-height:1.4;" '
                    + 'onmouseover="this.style.background=\'rgba(240,68,82,0.1)\'" onmouseout="this.style.background=\'transparent\'">매도</button>'
                    + '</div>'
                    + '<span class="hc-main-sub">' + ticker + '/USDT | ' + coinCount.toFixed(4) + '개</span>'
                    + '</div>'
                    + '</div>'
                    + '<div class="hc-main-right">'
                    + '<span class="hc-main-eval">' + (evalAmt !== null ? evalAmt.toLocaleString(undefined, { maximumFractionDigits: 2 }) : '-') + ' USDT</span>'
                    + '<span class="hc-main-pnl ' + cls + '">' + (pnl !== null ? arrow + Math.abs(pnl).toFixed(2) + ' (' + sign + pct.toFixed(2) + '%)' : '-') + '</span>'
                    + '</div>'
                    + '</div>'
                    + '<div class="hc-divider"></div>'
                    + '<div class="hc-main-grid">'
                    + '<div class="hc-main-row"><span class="hc-label">매수금액</span><span class="hc-value">' + buyAmt.toLocaleString(undefined, { maximumFractionDigits: 2 }) + ' USDT</span></div>'
                    + '<div class="hc-main-row"><span class="hc-label">평균단가</span><span class="hc-value">' + avgPrice.toLocaleString(undefined, { maximumFractionDigits: 6 }) + '</span></div>'
                    + '<div class="hc-main-row"><span class="hc-label">평가금액</span><span class="hc-value hc-eval-val">' + (evalAmt !== null ? evalAmt.toLocaleString(undefined, { maximumFractionDigits: 2 }) : '-') + ' USDT</span></div>'
                    + '<div class="hc-main-row"><span class="hc-label">현재가</span><span class="hc-value hc-price-val">' + (price !== null ? price.toLocaleString(undefined, { maximumFractionDigits: 6 }) : '-') + '</span></div>'
                    + '</div>';
                const skel = container.querySelector('.skeleton-card');
                if (skel) container.replaceChild(div, skel);
                else container.appendChild(div);
            }
        });
        container.querySelectorAll('.skeleton-card').forEach(r => r.remove());
    } else {
        document.getElementById('bp-empty').style.display = '';
        if (sellAllWrap) sellAllWrap.style.display = 'none';
        container.innerHTML = '';
    }
}

/** 개별 코인 시장가 즉시 매도 */
async function sellCoinMarket(coinCode, coinCount) {
    const ticker = coinCode.replace(/USDT$/, '');
    const price = cachedPrices[coinCode] || 0;
    if (!confirm(ticker + ' ' + coinCount.toFixed(4) + '개를 시장가로 즉시 매도하시겠습니까?')) return;

    try {
        const res = await fetch('/coin/sell', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams({ coinCode, orderPrice: price, orderCount: coinCount, orderType: 'SELL' })
        }).then(r => r.text());

        if (res === 'success') {
            if (typeof loadCoinHoldings === 'function') loadCoinHoldings();
            if (typeof loadWallet === 'function') loadWallet();
            if (typeof loadHoldings === 'function') loadHoldings();
        } else {
            alert('매도 실패: ' + res);
        }
    } catch (e) { alert('매도 중 오류가 발생했습니다.'); }
}

/** 전체 코인 시장가 즉시 매도 */
async function sellAllCoins() {
    if (!holdingsData || holdingsData.length === 0) { alert('보유 코인이 없습니다.'); return; }
    if (!confirm('보유한 코인 ' + holdingsData.length + '종목 전체를 시장가로 즉시 매도하시겠습니까?')) return;

    let failed = 0;
    for (const h of holdingsData) {
        const code = h.coinCode || h.coincode;
        const count = h.coinCount || h.coincount;
        const price = cachedPrices[code] || h.avgPrice || h.avgprice || 0;
        try {
            const res = await fetch('/coin/sell', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({ coinCode: code, orderPrice: price, orderCount: count, orderType: 'SELL' })
            }).then(r => r.text());
            if (res !== 'success') failed++;
        } catch (e) { failed++; }
    }

    if (failed > 0) alert(failed + '종목 매도에 실패했습니다.');
    if (typeof loadCoinHoldings === 'function') loadCoinHoldings();
    if (typeof loadWallet === 'function') loadWallet();
    if (typeof loadHoldings === 'function') loadHoldings();
}

async function loadHoldings() {
    const tbody = document.getElementById('bp-holdings-body');
    if (!tbody) return;

    const cached = localStorage.getItem('holdings');
    if (cached) {
        /* 캐시 있으면 즉시 실제 데이터 표시 */
        holdingsData = JSON.parse(cached);
        renderHoldings(holdingsData);
        connectHoldingsWs();
    } else {
        /* 캐시 없으면 스켈레톤 표시 */
        document.getElementById('bp-empty').style.display = 'none';
        document.getElementById('bp-holdings-body').innerHTML = skeletonCard() + skeletonCard() + skeletonCard();
    }

    /* 서버에서 최신 데이터 fetch → 캐시 갱신 후 in-place 업데이트 */
    const res = await fetch('/coin/holdings').then(r => r.json());
    holdingsData = res || [];
    localStorage.setItem('holdings', JSON.stringify(holdingsData));
    renderHoldings(holdingsData);
    connectHoldingsWs();
}

async function loadOrders() {
    const container = document.getElementById('history-cards');
    if (!container) return;

    try {
        // 1. [수정] 세션 방식을 사용하므로 파라미터(?username=testuser)를 지우고 호출합니다.
        const res = await fetch('/coin/orders').then(r => r.json());
        const emptyEl = document.getElementById('history-empty');

        if (!res || res.length === 0) {
            if (emptyEl) emptyEl.style.display = '';
            container.innerHTML = ''; // 기존 카드 비우기
            return;
        }

        if (emptyEl) emptyEl.style.display = 'none';
        container.className = 'history-list';
        
        container.innerHTML = res.map(o => {
            // 코인 코드 안전 장치 (혹시나 코인 코드도 안 넘어올 경우를 대비)
            const coinCode = o.coinCode || 'UNKNOWN';
            const ticker = coinCode.replace(/USDT$/, '').replace('_SPBL', '');
            
            const typeLabel = o.orderType === 'BUY' ? '매수' : '매도';
            const typeCls = o.orderType === 'BUY' ? 'up' : 'down';
            const total = (o.orderPrice * o.orderCount).toLocaleString(undefined, { maximumFractionDigits: 2 });
            
            // 2. [문제 해결 핵심] orderDate가 null이거나 비어있을 때 터지지 않도록 안전망을 씌웁니다.
            const date = o.orderDate ? o.orderDate.slice(0, 16).replace('T', ' ') : '날짜 없음';

            let rightHtml = '';
            if (o.orderType === 'SELL' && o.avgPrice) {
                const pnl = (o.orderPrice - o.avgPrice) * o.orderCount;
                const pct = (o.orderPrice - o.avgPrice) / o.avgPrice * 100;
                const pnlCls = pnl >= 0 ? 'up' : 'down';
                const sign = pnl >= 0 ? '+' : '';
                rightHtml = `<div class="hr-right">
                    <span class="hr-total ${pnlCls}">${sign}${pnl.toFixed(2)} USDT</span>
                    <span class="hr-pnl ${pnlCls}">${sign}${pct.toFixed(2)}%</span>
                </div>`;
            } else {
                rightHtml = `<div class="hr-right">
                    <span class="hr-total">${total} USDT</span>
                    <span class="hr-pnl ${typeCls}">${typeLabel}</span>
                </div>`;
            }

            const pnlDetailRow = (o.orderType === 'SELL' && o.avgPrice) ? `
                <div class="hr-detail-row">
                    <span class="hr-dlabel">평균단가</span>
                    <span class="hr-dvalue">${Number(o.avgPrice).toLocaleString(undefined, { maximumFractionDigits: 6 })}</span>
                </div>
                <div class="hr-detail-row">
                    <span class="hr-dlabel">총금액</span>
                    <span class="hr-dvalue">${total} USDT</span>
                </div>` : `
                <div class="hr-detail-row">
                    <span class="hr-dlabel">총금액</span>
                    <span class="hr-dvalue">${total} USDT</span>
                </div>`;

            // orderType이 없을 때 클래스 오류 방지용 기본값 처리
            const orderTypeLower = o.orderType ? o.orderType.toLowerCase() : 'buy';

            return `<div class="history-card hc-${orderTypeLower}" onclick="if(this.classList.contains('open')){this.classList.add('closing');this.classList.remove('open');setTimeout(()=>this.classList.remove('closing'),250);}else{this.classList.remove('closing');this.classList.add('open');}">
                <div class="hr-header">
                    <div class="hr-left">
                        ${coinLogoHtml(ticker)}
                        <div class="hr-info">
                            <span class="hr-ticker">${ticker}</span>
                            <span class="hr-meta">${date} · ${typeLabel}</span>
                        </div>
                    </div>
                    ${rightHtml}
                </div>
                <div class="hr-detail">
                    <div class="hr-detail-row">
                        <span class="hr-dlabel">체결가</span>
                        <span class="hr-dvalue">${Number(o.orderPrice).toLocaleString(undefined, { maximumFractionDigits: 6 })}</span>
                    </div>
                    <div class="hr-detail-row">
                        <span class="hr-dlabel">수량</span>
                        <span class="hr-dvalue">${o.orderCount}</span>
                    </div>
                    ${pnlDetailRow}
                </div>
            </div>`;
        }).join('');
        
    } catch (err) {
        console.error("주문 목록을 그리는 중 오류가 발생했습니다:", err);
    }
}


function connectHoldingsWs() {
    if (holdingsPingTimer) { clearInterval(holdingsPingTimer); holdingsPingTimer = null; }
    if (holdingsWs) holdingsWs.close();
    const ws = new WebSocket('wss://ws.bitget.com/v2/ws/public');
    holdingsWs = ws;

    ws.onopen = () => {
        const args = holdingsData.map(h => ({
            instType: 'SPOT', channel: 'ticker', instId: h.coinCode
        }));
        ws.send(JSON.stringify({ op: 'subscribe', args }));
        holdingsPingTimer = setInterval(() => ws.readyState === 1 && ws.send('ping'), 20000);
    };

    ws.onmessage = (event) => {
        if (event.data === 'pong') return;
        let msg;
        try { msg = JSON.parse(event.data); } catch { return; }
        if (!msg.data || !msg.arg || msg.arg.channel !== 'ticker') return;

        const coinCode = msg.arg.instId;
        const price = parseFloat(msg.data[0].lastPr);
        updateHoldingPrice(coinCode, price);
    };

    ws.onclose = () => {
        if (ws === holdingsWs && holdingsData.length > 0) setTimeout(connectHoldingsWs, 3000);
    };
}

function updateHoldingPrice(coinCode, price) {
    const card = document.querySelector('#bp-holdings-body [data-coin="' + coinCode + '"]');
    if (!card) return;
    const h = holdingsData.find(h => h.coinCode === coinCode);
    if (!h) return;

    const evalAmt = price * h.coinCount;
    const buyAmt = h.avgPrice * h.coinCount;
    const pnl = evalAmt - buyAmt;
    const pct = buyAmt > 0 ? (pnl / buyAmt * 100) : 0;
    const cls = pnl >= 0 ? 'up' : 'down';
    const sign = pnl >= 0 ? '+' : '';
    const arrow = pnl >= 0 ? '▲' : '▼';

    card.querySelector('.hc-main-eval').textContent = evalAmt.toLocaleString(undefined, { maximumFractionDigits: 2 }) + ' USDT';
    const pnlEl = card.querySelector('.hc-main-pnl');
    pnlEl.textContent = arrow + Math.abs(pnl).toFixed(2) + ' (' + sign + pct.toFixed(2) + '%)';
    pnlEl.className = 'hc-main-pnl ' + cls;
    card.querySelector('.hc-price-val').textContent = price.toLocaleString(undefined, { maximumFractionDigits: 6 });
    card.querySelector('.hc-eval-val').textContent = evalAmt.toLocaleString(undefined, { maximumFractionDigits: 2 }) + ' USDT';

    cachedPrices[coinCode] = price;
    localStorage.setItem('holdingPrices', JSON.stringify(cachedPrices));
}


