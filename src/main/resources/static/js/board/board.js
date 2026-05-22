document.addEventListener('DOMContentLoaded', () => {
    
 	//  1. 게시글 작성 시 이미지 미리보기 로직
    const fileInput = document.getElementById('fileInput');
    const fileList = document.getElementById('file-list');
    const previewContainer = document.getElementById('image-preview-container');

    if (fileInput) {
        fileInput.addEventListener('change', (e) => {
            const files = e.target.files;
            previewContainer.innerHTML = ''; // 초기화
            
            if (files && files.length > 0) {
                fileList.innerText = `${files.length}개의 파일이 선택되었습니다.`;

                Array.from(files).forEach((file) => {
                    if (!file.type.startsWith('image/')) return;

                    const reader = new FileReader();
                    reader.onload = (event) => {
                        const imgDiv = document.createElement('div');
                        imgDiv.style.cssText = `
                            width: 100px; height: 100px; border-radius: 10px; 
                            overflow: hidden; border: 1px solid var(--border2);
                            box-shadow: 0 2px 8px rgba(0,0,0,0.2);
                        `;

                        const img = document.createElement('img');
                        img.src = event.target.result;
                        img.style.cssText = `width: 100%; height: 100%; object-fit: cover;`;

                        imgDiv.appendChild(img);
                        previewContainer.appendChild(imgDiv);
                    };
                    reader.readAsDataURL(file);
                });
            } else {
                fileList.innerText = "";
            }
        });
    }

  	// 2. 좋아요(Like) 실시간 토글 로직
    const likeBtn = document.getElementById('like-btn');
    const likeIcon = document.getElementById('like-icon');
    const likeCount = document.getElementById('like-count');

    if (likeBtn) {
        likeBtn.addEventListener('click', () => {
            const boardNo = likeBtn.dataset.boardNo;

            fetch('/like/toggle', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: `boardNo=${boardNo}`
            })
            .then(res => res.json())
            .then(data => {
                if (data === -1) {
                    alert('로그인이 필요한 기능입니다. 📈');
                    location.href = '/member/login';
                } else {
                    // 현재 숫자 가져오기 (비어있으면 0)
                    let currentCount = parseInt(likeCount.innerText) || 0;
                    
                    if (data === 1) {
                        // 좋아요 성공
                        likeIcon.innerText = '❤️';
                        likeCount.innerText = currentCount + 1;
                    } else if (data === 0) {
                        // 좋아요 취소
                        likeIcon.innerText = '🤍';
                        likeCount.innerText = currentCount - 1;
                    }
                }
            })
            .catch(err => console.error('좋아요 처리 중 오류 발생:', err));
        });
    }

    // 3. 댓글(Reply) 실시간 등록 로직 (AJAX)
    const replyForm = document.querySelector('form[action="/reply/create"]');
    
    if (replyForm) {
        replyForm.addEventListener('submit', function(e) {
            e.preventDefault();

            // JSP에서 넘겨받은 member 존재 여부 확인 (필요시 상세 페이지에서 변수 처리)
            const formData = new FormData(this);
            
            fetch('/reply/create', {
                method: 'POST',
                body: new URLSearchParams(formData)
            })
            .then(res => res.text())
            .then(result => {
                if(result === "1") {
                    // 댓글 등록 성공 시 새로고침 (추후 비동기 리스트 업데이트로 교체 가능)
                    location.reload(); 
                } else if(result === "not_logged_in") {
                    alert("로그인이 필요한 기능입니다. 📈");
                    location.href = "/member/login";
                } else {
                    alert("댓글 등록에 실패했습니다.");
                }
            })
            .catch(err => console.error('댓글 등록 중 오류 발생:', err));
        });
    }
});