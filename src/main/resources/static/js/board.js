// board.js 하단에 추가
document.addEventListener('DOMContentLoaded', () => {
    const fileInput = document.getElementById('fileInput');
    const fileList = document.getElementById('file-list');

    if (fileInput) {
        fileInput.addEventListener('change', (e) => {
            const files = e.target.files;
            if (files.length > 0) {
                fileList.innerText = files.length + "개의 파일이 선택되었습니다.";
            } else {
                fileList.innerText = "";
            }
        });
    }
});