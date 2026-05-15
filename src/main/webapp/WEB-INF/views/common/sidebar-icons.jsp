<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<div class="sidebar-icons">

    <button class="si-btn" id="si-invest" onclick="toggleSidebar('invest')">
        <svg viewBox="0 0 24 24" fill="currentColor"><path d="M5 9.2h3V19H5V9.2zM10.6 5h2.8v14h-2.8V5zm5.6 8H19v6h-2.8v-6z"/></svg>
        <span>내 투자</span>
    </button>

    <div class="si-divider"></div>

    <button class="si-btn" id="si-interest" onclick="toggleSidebar('interest')">
        <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
        <span>관심</span>
    </button>

    <button class="si-btn" id="si-recent" onclick="toggleSidebar('recent')">
        <svg viewBox="0 0 24 24" fill="currentColor"><path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67V7z"/></svg>
        <span>최근 본</span>
    </button>

    <button class="si-btn" id="si-live" onclick="toggleSidebar('live')">
        <svg viewBox="0 0 24 24" fill="currentColor"><path d="M19.48 12.35c-1.57-4.08-7.16-4.3-5.81-10.23.1-.44-.37-.78-.75-.55C9.29 3.71 6.68 8 8.87 13.62c.18.46-.36.89-.75.59-1.81-1.37-2-3.34-1.84-4.75.06-.52-.62-.77-.91-.34C4.69 10.16 4 11.84 4 14c0 4.22 3.8 7.99 8 8 4.28.02 7.96-3.77 8-8.02.03-1.81-.35-3.9-0.52-1.63z"/></svg>
        <span>실시간</span>
    </button>

</div>
<script>
(function () {
    if (document.body.dataset.sidebarAnimate === 'true') return;
    if (document.body.dataset.sidebarClosed === 'true') return;

    var tab = document.body.dataset.sidebarTab || localStorage.getItem('sidebar');
    if (!tab) return;

    var TITLES = { invest: '내 투자현황', interest: '관심 종목', recent: '최근 본', live: '실시간' };

    /* UI 세팅 (버튼·타이틀·섹션) */
    var btn = document.getElementById('si-' + tab);
    if (btn) btn.classList.add('active');
    var titleEl = document.getElementById('sidebar-title');
    if (titleEl) titleEl.textContent = TITLES[tab] || tab;
    document.querySelectorAll('.sidebar-section').forEach(function (s) { s.style.display = 'none'; });
    var sec = document.getElementById('sidebar-' + tab);
    if (sec) sec.style.display = '';

    var panel = document.getElementById('sidebar-panel');
    if (!panel) return;

    if (document.body.dataset.sidebarTab) {
        /* 고정 탭 페이지(차트 등): 항상 애니메이션으로 열기 */
        localStorage.setItem('sidebar', tab);
        setTimeout(function () { requestAnimationFrame(function () { requestAnimationFrame(function () { panel.classList.add('open'); }); }); });
    } else {
        /* 다른 페이지: localStorage 상태 즉시 복원 */
        panel.style.transition = 'none';
        panel.classList.add('open');
        requestAnimationFrame(function () { requestAnimationFrame(function () { panel.style.transition = ''; }); });
    }
})();
</script>
