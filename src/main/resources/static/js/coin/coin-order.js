/* =====================================================
   coin-order.js - 코인 차트 화면의 주문, 지갑, 미체결 주문을 담당한다.
   chart-toss-coin.js에서 분리된 주문 관련 함수 모음이다.
   ===================================================== */

/* =====================================================
   [이 파일을 읽는 법]

   1. 역할
      주문 패널의 매수/매도 탭, 지정가/시장가 선택, 수량 계산,
      주문 제출, 지갑 잔고, 미체결 주문 목록을 처리한다.

   2. 중심 함수
      submitOrder()
      - 주문 입력값을 검사한다.
      - 지정가/시장가에 따라 다른 API로 POST 요청을 보낸다.
      - 성공 후 지갑, 보유 수량, 미체결 주문을 다시 불러온다.

   3. 전체 흐름
      사용자가 주문 조건 입력
      -> 수량/금액 계산
      -> submitOrder(side) 실행
      -> 서버에 주문 요청
      -> 지갑/보유/미체결/주문내역 새로고침
      -> 지정가 주문은 현재가가 조건을 만족하면 체결 요청

   4. 보조 함수
      switchOrderTab()             매수/매도 탭과 가용 잔고 표시 전환
      selectOrderType()            지정가/시장가 버튼 상태 전환
      setPercent()                 잔고나 보유 수량 기준으로 주문 수량 자동 입력
      loadWallet()                 서버에서 USDT 잔고 조회
      loadPendingOrders()          서버에서 미체결 주문 목록 조회
      renderPendingOrders()        미체결 주문 목록을 테이블로 렌더링
      checkPendingOrders()         현재가 기준으로 지정가 체결 조건 검사
      cancelPendingOrder()         미체결 주문 취소 요청

   5. 주의해서 볼 값
      orderSide                    현재 주문 방향. chart-toss-coin.js 전역 변수
      walletBalance                주문 가능 USDT 잔고. loadWallet()이 갱신
      currentSymbol                현재 선택된 코인 심볼
      lastPrice                    현재가. 주문 금액과 지정가 체결 조건에 사용
      pendingOrders                서버에서 가져온 미체결 지정가 주문 목록
      checkingPending              중복 체결 요청을 막는 플래그
   ===================================================== */

// [전역 상태] 서버에서 가져온 미체결 주문과 체결 검사 진행 여부를 파일 안에서 공유한다.
let pendingOrders = [];
let checkingPending = false;

/**
 * 매수/매도 탭을 전환하고 주문 버튼과 가용 잔고 표시를 갱신한다.
 *
 * @param {string} side 'buy' 또는 'sell'
 */
function switchOrderTab(side) {
    // [실행 흐름] orderSide는 주문 제출 시 submitOrder(orderSide)로 다시 사용되는 전역 상태다.
    orderSide = side;
    const isBuy = side === 'buy';

    // [DOM 연결] chart.jsp의 #tab-buy, #tab-sell 버튼에 active 클래스를 번갈아 적용한다.
    document.getElementById('tab-buy').classList.toggle('active', isBuy);
    document.getElementById('tab-sell').classList.toggle('active', !isBuy);
    document.getElementById('order-submit-btn').textContent = isBuy ? '매수 주문' : '매도 주문';
    document.getElementById('order-submit-btn').className = isBuy ? 'btn-buy' : 'btn-sell';

    const av = document.querySelector('.order-avail span');
    if (isBuy) {
        // [실행 흐름] 매수 탭에서는 주문에 사용할 수 있는 USDT 잔고를 보여준다.
        av.textContent = walletBalance.toFixed(2) + ' USDT';
    } else {
        // [실행 흐름] 매도 탭에서는 현재 코인의 보유 수량을 찾아 보여준다.
        const holding = holdingsData.find(h => h.coinCode === currentSymbol);
        const qty = holding ? holding.coinCount : 0;
        const ticker = currentSymbol.replace(/USDT$/, '').replace('_SPBL', '');
        av.textContent = qty.toFixed(6) + ' ' + ticker;
    }

    // [실행 흐름] 탭이 바뀌면 같은 수량이라도 의미가 달라질 수 있으므로 주문 금액 표시를 다시 계산한다.
    calcAmount();
}

/**
 * 지정가/시장가 버튼 선택 상태와 가격 입력 가능 여부를 바꾼다.
 *
 * @param {HTMLElement} btn 사용자가 클릭한 주문 유형 버튼
 */
function selectOrderType(btn) {
    // [DOM 연결] .order-type-btn 버튼들에서 sel 클래스를 제거한 뒤 클릭한 버튼에만 다시 붙인다.
    document.querySelectorAll('.order-type-btn').forEach(b => b.classList.remove('sel'));
    btn.classList.add('sel');

    // [코드 읽기] 버튼에 표시된 글자가 '지정가'인지 확인해서 주문 유형을 판단한다.
    const isLimit = btn.textContent.trim() === '지정가';
    const priceInput = document.getElementById('trade-price-input');

    // [실행 흐름] 시장가는 사용자가 가격을 직접 정하지 않으므로 현재가를 넣고 입력을 잠근다.
    priceInput.readOnly = !isLimit;
    priceInput.style.background = isLimit ? '' : 'var(--bg)';
    if (!isLimit) priceInput.value = lastPrice ? lastPrice.toFixed(2) : '';
}

/**
 * 비율 선택 드롭다운을 열거나 닫는다.
 */
function togglePctDrop() {
    const menu = document.getElementById('pct-drop-menu');

    // [DOM 연결] display 값만 바꿔 같은 메뉴를 보였다가 숨긴다.
    menu.style.display = menu.style.display === 'none' ? 'block' : 'none';
}

/**
 * 선택한 비율에 맞춰 주문 수량 입력값을 자동으로 채운다.
 *
 * @param {number} pct 사용할 비율. 예: 25, 50, 75, 100
 */
function setPercent(pct) {
    // [DOM 연결] 드롭다운 라벨은 100%일 때만 '최대'로 보여준다.
    const label = document.getElementById('pct-drop-label');
    if (label) label.textContent = pct === 100 ? '최대' : pct + '%';
    const menu = document.getElementById('pct-drop-menu');
    if (menu) menu.style.display = 'none';

    if (orderSide === 'sell') {
        // [실행 흐름] 매도는 보유 수량을 기준으로 pct%만큼 팔 수량을 계산한다.
        const holding = holdingsData.find(h => h.coinCode === currentSymbol);
        const h = holding ? holding.coinCount : 0;
        document.getElementById('trade-qty').value = (h * pct / 100).toFixed(6);
    } else {
        // [실행 흐름] 매수는 USDT 잔고를 현재가로 나눠 살 수 있는 코인 수량을 계산한다.
        // [주의] lastPrice가 0이면 나누기 오류가 나므로 lastPrice || 1로 최소 분모를 만든다.
        document.getElementById('trade-qty').value =
            (walletBalance * pct / 100 / (lastPrice || 1)).toFixed(6);
    }

    calcAmount();
}

/**
 * 현재 입력된 수량과 현재가를 곱해 주문 금액을 표시한다.
 */
function calcAmount() {
    const el = document.getElementById('trade-amount');

    // [코드 읽기] parseFloat 결과가 NaN이면 || 0으로 0 수량처럼 처리한다.
    if (el) el.textContent =
        ((parseFloat(document.getElementById('trade-qty').value) || 0) * lastPrice).toFixed(2);
}

/**
 * 주문 제출 버튼 클릭 시 서버에 매수/매도 요청을 보낸다.
 *
 * @param {string} side 'buy' 또는 'sell'
 */
function submitOrder(side) {
    const qty = document.getElementById('trade-qty').value;

    // [실행 흐름] 서버 요청 전에 수량이 비어 있거나 0 이하인지 먼저 검사한다.
    if (!qty || parseFloat(qty) <= 0) { alert('수량을 입력하세요'); return; }

    // [코드 읽기] sel 클래스가 붙은 주문 유형 버튼의 텍스트로 지정가 여부를 판단한다.
    const isLimit = document.querySelector('.order-type-btn.sel')?.textContent.trim() === '지정가';
    const targetPrice = parseFloat(document.getElementById('trade-price-input').value);

    // [실행 흐름] 지정가 주문은 사용자가 원하는 목표 가격이 반드시 필요하다.
    if (isLimit && (!targetPrice || targetPrice <= 0)) { alert('지정가를 입력하세요'); return; }

    // [실행 흐름] 지정가는 통합 API, 시장가는 매수/매도 API로 나뉜다.
    const url = isLimit ? '/coin/limitOrder' : '/coin/' + side;
    const params = {
        username: 'testuser',
        coinCode: currentSymbol,
        orderPrice: lastPrice,
        orderCount: qty,
        orderType: side.toUpperCase()
    };
    if (isLimit) params.targetPrice = targetPrice;

    // [실행 흐름] URLSearchParams는 객체를 application/x-www-form-urlencoded 본문으로 바꿔준다.
    fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams(params)
    })
        .then(r => r.text())
        .then(result => {
            if (result === 'success') {
                alert(isLimit
                    ? (side === 'buy' ? '매수' : '매도') + ' 지정가 주문 등록!'
                    : (side === 'buy' ? '매수' : '매도') + ' 주문 완료!');

                // [실행 흐름] 주문 성공 후 화면에 보이는 자산 관련 정보를 다시 서버 기준으로 맞춘다.
                loadWallet();
                loadHoldings();

                // [실행 흐름] 지정가 주문은 등록 직후 현재가 조건을 만족할 수 있어 미체결 조회 뒤 즉시 검사한다.
                loadPendingOrders().then(() => {
                    if (isLimit) checkPendingOrders(lastPrice);
                });
            } else {
                alert('주문 실패: ' + result);
            }
        })
        .catch(err => alert('오류: ' + err));
}

/**
 * 서버에서 USDT 지갑 잔고를 가져와 전역 잔고와 화면 표시를 갱신한다.
 */
async function loadWallet() {
    // [실행 흐름] username=testuser 기준의 지갑 정보를 JSON으로 받는다.
    const res = await fetch('/coin/wallet?username=testuser').then(r => r.json());
    if (res && res.usdtBalance !== undefined) {
        walletBalance = res.usdtBalance;

        // [DOM 연결] 주문 패널의 가용 잔고 영역을 최신 USDT 값으로 바꾼다.
        document.querySelector('.order-avail span').textContent = res.usdtBalance.toFixed(2) + ' USDT';
    }
}

/**
 * 서버에서 미체결 지정가 주문 목록을 가져오고 화면을 다시 그린다.
 *
 * @return {Promise<Array>} 미체결 주문 배열
 */
async function loadPendingOrders() {
    // [실행 흐름] 서버 응답을 pendingOrders 전역 배열에 저장해 렌더링과 체결 검사에서 함께 쓴다.
    const res = await fetch('/coin/pending?username=testuser').then(r => r.json());
    pendingOrders = res || [];
    renderPendingOrders();
    return pendingOrders;
}

/**
 * pendingOrders 배열을 미체결 주문 테이블에 표시한다.
 */
function renderPendingOrders() {
    // [DOM 연결] 미체결 탭의 빈 상태, 테이블, tbody를 찾아 표시 상태와 행 내용을 바꾼다.
    const emptyEl = document.querySelector('#tab-coin-pending .sb-empty');
    const tableEl = document.getElementById('orders-table');
    const tbody = document.getElementById('orders-body');
    if (!tbody) return;

    // [실행 흐름] 주문이 없으면 빈 상태를 보이고 테이블은 숨긴다.
    if (pendingOrders.length === 0) {
        if (emptyEl) emptyEl.style.display = '';
        if (tableEl) tableEl.style.display = 'none';
        return;
    }
    if (emptyEl) emptyEl.style.display = 'none';
    if (tableEl) tableEl.style.display = '';

    const ticker = currentSymbol.replace(/USDT$/, '').replace('_SPBL', '');

    // [DOM 연결] 각 주문은 tr 한 줄로 바뀌며, 취소 버튼은 cancelPendingOrder(orderNo)를 호출한다.
    tbody.innerHTML = pendingOrders.map(o => `
        <tr>
            <td>${ticker}</td>
            <td class="${o.orderType === 'BUY' ? 'up' : 'down'}">${o.orderType === 'BUY' ? '매수' : '매도'}</td>
            <td>${Number(o.targetPrice).toLocaleString()}</td>
            <td>${o.orderCount}</td>
            <td><button onclick="cancelPendingOrder(${o.orderNo})" style="background:none;border:1px solid var(--border);color:var(--text3);padding:2px 8px;border-radius:4px;cursor:pointer;font-size:11px;">취소</button></td>
        </tr>
    `).join('');
}

/**
 * 현재가가 미체결 지정가 주문의 체결 조건을 만족하는지 검사하고 서버에 체결 요청을 보낸다.
 *
 * @param {number} price 현재 체결가
 */
function checkPendingOrders(price) {
    // [주의] 실시간 가격이 자주 들어오므로 checkingPending으로 중복 요청을 막는다.
    if (checkingPending || pendingOrders.length === 0) return;

    // [코드 읽기] 매수는 현재가가 지정가 이하일 때, 매도는 현재가가 지정가 이상일 때 체결 대상이 된다.
    const toExecute = pendingOrders.filter(o =>
        o.targetPrice &&
        ((o.orderType === 'BUY' && price <= o.targetPrice) ||
         (o.orderType === 'SELL' && price >= o.targetPrice))
    );
    if (toExecute.length === 0) return;

    checkingPending = true;

    // [실행 흐름] 체결 가능한 주문이 여러 개면 Promise.all로 동시에 서버에 체결 요청을 보낸다.
    Promise.all(toExecute.map(o =>
        fetch('/coin/executePending', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams({ orderNo: o.orderNo, username: o.username, coinCode: o.coinCode, orderType: o.orderType, orderPrice: price, orderCount: o.orderCount })
        }).then(r => r.ok ? r.text() : Promise.reject(r.status))
    )).then(() => {
        checkingPending = false;

        // [실행 흐름] 체결 후 미체결, 보유 수량, 지갑, 주문 내역을 모두 서버 기준으로 다시 불러온다.
        pendingOrders = pendingOrders.filter(o => !toExecute.includes(o));
        loadPendingOrders();
        loadHoldings();
        loadWallet();
        loadOrders();
    }).catch(() => {
        // [주의] 실패해도 다음 가격 변화 때 다시 검사할 수 있도록 플래그를 반드시 해제한다.
        checkingPending = false;
        pendingOrders = pendingOrders.filter(o => !toExecute.includes(o));
    });
}

/**
 * 미체결 주문 취소 버튼 클릭 시 서버에 취소 요청을 보낸다.
 *
 * @param {number} orderNo 취소할 주문 번호
 */
async function cancelPendingOrder(orderNo) {
    // [실행 흐름] 버튼에 들어 있던 orderNo와 현재 사용자 이름을 서버로 보낸다.
    const res = await fetch('/coin/cancelOrder', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({ orderNo, username: 'testuser' })
    }).then(r => r.text());

    // [실행 흐름] 취소 성공 시 미체결 목록, 보유 현황, 지갑 잔고를 다시 불러온다.
    if (res === 'success') { loadPendingOrders(); loadHoldings(); loadWallet(); }
}
