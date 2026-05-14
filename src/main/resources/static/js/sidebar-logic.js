// 전역 상태 관리
window.sidebarActiveTab = null;

// 사이드바 토글 함수
function toggleSidebar(tab) {
    const panel = document.getElementById('sidebar-panel');
    
    if (window.sidebarActiveTab === tab) {
        closeSidebar();
        return;
    }
    
    window.sidebarActiveTab = tab;
    panel.classList.add('open');
    
    // 아이콘 활성화 스타일 처리
    document.querySelectorAll('.si-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    const activeBtn = document.getElementById('si-' + tab);
    if(activeBtn) activeBtn.classList.add('active');
}

function closeSidebar() {
    window.sidebarActiveTab = null;
    const panel = document.getElementById('sidebar-panel');
    if(panel) panel.classList.remove('open');
    document.querySelectorAll('.si-btn').forEach(btn => btn.classList.remove('active'));
}
	
// ESC 키를 누르면 사이드바 닫기
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeSidebar();
});