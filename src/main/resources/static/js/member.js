/* member.js */
document.addEventListener('DOMContentLoaded', () => {
    const joinForm = document.getElementById('joinForm');
    
    if (joinForm) {
        joinForm.addEventListener('submit', (e) => {
            const pwd = document.getElementById('password').value;
            
            if (pwd.length < 8) {
                e.preventDefault(); // 제출 중단
                alert("비밀번호는 최소 8자 이상이어야 합니다.");
            }
        });
    }
});