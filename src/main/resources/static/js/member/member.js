/* member.js */
document.addEventListener('DOMContentLoaded', () => {
    // 1. 회원가입 폼 유효성 검사
    const joinForm = document.getElementById('joinForm');
    if (joinForm) {
        joinForm.addEventListener('submit', (e) => {
            const pwd = document.getElementById('password').value;
            if (pwd.length < 8) {
                e.preventDefault(); 
                alert("비밀번호는 최소 8자 이상이어야 합니다.");
            }
        });
    }

    // 2. 마이페이지 실시간 자산 조회
    const assetPriceElement = document.querySelector('.ph-price');
    if (assetPriceElement) {
        fetch('/stock/my-asset')
            .then(res => res.json())
            .then(totalAsset => {
                const formatted = totalAsset.toLocaleString();
                assetPriceElement.innerHTML = `${formatted} <span style="font-size: 14px; color: var(--text2);">원</span>`;
                const label = document.querySelector('.ph-label');
                if (label) label.innerText = '총 평가 자산';
            })
            .catch(err => console.error("자산 정보 불러오기 실패:", err));
    }

    // 3. 마이페이지 프로필 변경 기능
    const profileFileInput = document.getElementById('profileFileInput');
    if (profileFileInput) {
        profileFileInput.addEventListener('change', function() {
            const file = this.files[0];
            if (!file) return;

            const reader = new FileReader();
            reader.onload = function(e) {
                const avatar = document.getElementById('profileAvatar');
                const placeholder = document.getElementById('profilePlaceholder');
                let img = document.getElementById('profileImg');

                if (!img) {
                    img = document.createElement('img');
                    img.id = 'profileImg';
                    if (placeholder) placeholder.remove();
                    avatar.appendChild(img);
                }
                img.src = e.target.result;
            };
            reader.readAsDataURL(file);

            const form = new FormData();
            form.append('file', file);
            fetch('/member/profile', { method: 'POST', body: form })
                .then(res => {
                    if (res.ok) showToast('사진이 업데이트됐어요');
                    else alert('업로드에 실패했습니다.');
                });
        });
    }
});

// Toast 알림 함수 (어디서든 호출 가능)
function showToast(msg) {
    const toast = document.createElement('div');
    toast.textContent = msg;
    toast.style.cssText = 'position:fixed;top:24px;left:50%;transform:translateX(-50%) translateY(-20px);background:#1e1e22;color:#fff;padding:12px 22px;border-radius:12px;font-size:14px;box-shadow:0 4px 16px rgba(0,0,0,0.4);z-index:9999;opacity:0;transition:opacity 0.25s,transform 0.25s;';
    document.body.appendChild(toast);
    requestAnimationFrame(() => {
        toast.style.opacity = '1';
        toast.style.transform = 'translateX(-50%) translateY(0)';
    });
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(-50%) translateY(-20px)';
        setTimeout(() => toast.remove(), 250);
    }, 2500);
}

