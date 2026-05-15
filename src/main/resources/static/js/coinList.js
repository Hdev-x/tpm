/* coinList.js - 최소 기능만 구현 */

// ── 메인 탭 전환 ──
document.querySelectorAll('.main-tab').forEach(tab => {
    tab.addEventListener('click', function () {
        document.querySelectorAll('.main-tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.add('hidden'));
        this.classList.add('active');
        document.getElementById('tab-' + this.dataset.tab).classList.remove('hidden');
    });
});

// ── 필터 버튼 그룹 토글 ──
document.querySelectorAll('.filter-group').forEach(group => {
    group.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', function () {
            group.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
        });
    });
});

// ── 테이블 행 클릭 → 우측 패널 active 표시 ──
document.querySelectorAll('.stock-row').forEach(row => {
    row.addEventListener('click', function () {
        document.querySelectorAll('.stock-row').forEach(r => r.classList.remove('active'));
        this.classList.add('active');
    });
});
