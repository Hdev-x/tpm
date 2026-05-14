/* =====================================================
   common.js
   모든 페이지에서 공통으로 사용하는 JS
   nav, sidebar 관련 함수 등
   ===================================================== */


/* ====================================================
   사이드바 슬라이드 토글
   ==================================================== */
const SIDEBAR_TITLES = { invest: '내 투자현황', interest: '관심 종목', recent: '최근 본', live: '실시간' };
let sidebarActiveTab = null;

/* 같은 탭 클릭 시 닫기, 다른 탭 클릭 시 열고 제목 변경 */
function toggleSidebar(tab) {
    const panel = document.getElementById('sidebar-panel');
    if (sidebarActiveTab === tab) { closeSidebar(); return; }
    sidebarActiveTab = tab;
    panel.classList.add('open');
    document.querySelectorAll('.si-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('si-' + tab).classList.add('active');
    document.getElementById('sidebar-title').textContent = SIDEBAR_TITLES[tab] || tab;
}

function closeSidebar() {
    sidebarActiveTab = null;
    document.getElementById('sidebar-panel').classList.remove('open');
    document.querySelectorAll('.si-btn').forEach(b => b.classList.remove('active'));
}


/* ====================================================
   사이드바 탭 전환 (포지션 / 오더 / 기록)
   ==================================================== */
function switchBpTab(el, tab) {
    document.querySelectorAll('.sb-tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    document.getElementById('tab-positions').style.display = tab === 'positions' ? 'flex' : 'none';
    document.getElementById('tab-orders').style.display = tab === 'orders' ? 'flex' : 'none';
    document.getElementById('tab-history').style.display = tab === 'history' ? 'flex' : 'none';
}
