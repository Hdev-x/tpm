window.searchNewsByKeyword = function(keyword) {
    if (!keyword) return;

    // 1. 타이틀 키워드 텍스트 변경 규칙
    const targetSpan = document.getElementById("news-target-keyword");
    if (targetSpan) targetSpan.innerText = keyword;

    // 2. 왼쪽 인기 키워드 하이라이트 UI 제어
    const chips = document.querySelectorAll("#popular-keywords-box .si-type-tab");
    chips.forEach(chip => {
        if (chip.innerText.includes(keyword)) chip.classList.add("active");
        else chip.classList.remove("active");
    });

    const streamListDiv = document.getElementById("big-news-stream-list");
    if (!streamListDiv) return;

    // 로딩 처리
    streamListDiv.innerHTML = `<p style="color: var(--text3); text-align: center; padding: 40px 0;">🔄 [${keyword}] 관련 실시간 뉴스를 수급 중입니다...</p>`;

    // 📡 백엔드 네이버 뉴스 검색 API 정밀 타격
    fetch("/news?keyword=" + encodeURIComponent(keyword))
        .then(response => {
            if (!response.ok) throw new Error("뉴스 서버 통신 제한");
            return response.json();
        })
        .then(data => {
            streamListDiv.innerHTML = "";

            if (!data.items || data.items.length === 0) {
                streamListDiv.innerHTML = `<p style="color: var(--text3); text-align: center; padding: 40px 0;">⚠️ 관련 실시간 뉴스가 존재하지 않습니다.</p>`;
                return;
            }

            // 뉴스 카드 리스트 서핑 빌드업
            data.items.forEach(item => {
                const article = document.createElement("div");
                article.style.borderBottom = "1px solid var(--border)";
                article.style.padding = "20px 4px";
                article.style.transition = "background 0.2s";
                
                article.addEventListener("mouseenter", () => article.style.background = "rgba(255,255,255,0.01)");
                article.addEventListener("mouseleave", () => article.style.background = "transparent");

                article.innerHTML = `
                    <div style="margin-bottom: 8px; text-align: left;">
                        <a href="${item.link}" target="_blank" style="color: #ffffff; text-decoration: none; font-weight: 700; font-size: 16px; line-height: 1.4;">
                            ${item.title}
                        </a>
                    </div>
                    <div style="color: var(--text2); font-size: 13px; line-height: 1.6; font-weight: 300; text-align: left;">
                        ${item.description}
                    </div>
                `;
                streamListDiv.appendChild(article);
            });
        })
        .catch(error => {
            console.error("❌ 뉴스룸 엔진 장애:", error);
            streamListDiv.innerHTML = `<p style="color: var(--up); text-align: center; padding: 20px 0;">⚠️ 외부 뉴스 API 통신 지연이 발생했습니다. 잠시 후 다시 검색해 주세요.</p>`;
        });
};


/**
 * 📰 전역 뉴스 제어 엔진 (최근 검색어 저장 & 삭제 기능 포함)
 */
document.addEventListener("DOMContentLoaded", () => {
    // 1. 페이지 로드 시 최근 검색어 리스트 화면에 점등
    renderRecentKeywords();

    const searchBtn = document.getElementById("news-search-btn");
    const searchInput = document.getElementById("news-search-input");

    if (searchBtn && searchInput) {
        // 검색 버튼 클릭 시
        searchBtn.addEventListener("click", () => {
            const kw = searchInput.value.trim();
            if (kw) {
                saveRecentKeyword(kw); // 🕒 로컬스토리지에 저장
                searchNewsByKeyword(kw);
            }
        });

        // 검색창 엔터 키 입력 시
        searchInput.addEventListener("keypress", (e) => {
            if (e.key === "Enter") {
                const kw = searchInput.value.trim();
                if (kw) {
                    saveRecentKeyword(kw); // 🕒 로컬스토리지에 저장
                    searchNewsByKeyword(kw);
                }
            }
        });
    }
});

/**
 * 💾 1. 최근 검색어 로컬스토리지 저장 함수
 */
function saveRecentKeyword(keyword) {
    if (!keyword) return;

    // 기존 저장된 리스트 가져오기 (없으면 빈 배열)
    let keywords = JSON.parse(localStorage.getItem("recent_news_keywords")) || [];

    // 중복 검색어 제거 (방금 검색한 걸 맨 앞으로 보내기 위함)
    keywords = keywords.filter(kw => kw !== keyword);

    // 최신 검색어를 배열 맨 앞에 추가
    keywords.unshift(keyword);

    // 최근 검색어는 깔끔하게 최대 8개까지만 유지 관리
    if (keywords.length > 8) {
        keywords.pop();
    }

    // 로컬스토리지에 다시 굽기
    localStorage.setItem("recent_news_keywords", JSON.stringify(keywords));

    // 화면 새로고침 렌더링
    renderRecentKeywords();
}

/**
 * 🖥️ 2. 최근 검색어 화면 렌더링 함수
 */
function renderRecentKeywords() {
    const box = document.getElementById("recent-keywords-box");
    if (!box) return;

    const keywords = JSON.parse(localStorage.getItem("recent_news_keywords")) || [];

    if (keywords.length === 0) {
        box.innerHTML = `<p style="color: var(--text3); font-size: 13px; margin: 5px 0;">최근 검색 기록이 없습니다.</p>`;
        return;
    }

    box.innerHTML = "";
    
    // 저장된 검색어 배열을 돌면서 X버튼이 달린 칩(Chip) UI 생성
    keywords.forEach(kw => {
        const chip = document.createElement("div");
        chip.style.display = "flex";
        chip.style.alignItems = "center";
        chip.style.gap = "6px";
        chip.style.background = "var(--surface2)";
        chip.style.border = "1px solid var(--border2)";
        chip.style.padding = "6px 12px";
        chip.style.borderRadius = "20px";
        chip.style.fontSize = "13px";
        chip.style.color = "var(--text2)";
        chip.style.cursor = "pointer";

        // 글자 영역 클릭 시 해당 키워드로 뉴스 즉시 검색
        chip.innerHTML = `
            <span onclick="searchNewsByKeyword('${kw}')" style="transition: color 0.2s;">${kw}</span>
            <span onclick="deleteRecentKeyword(event, '${kw}')" style="color: var(--text3); font-weight: bold; font-size: 11px; margin-left: 2px; transition: color 0.2s;">✕</span>
        `;

        // 호버 효과 바인딩
        const textSpan = chip.querySelector("span:first-child");
        const xSpan = chip.querySelector("span:last-child");
        
        chip.addEventListener("mouseenter", () => chip.style.borderColor = "var(--blue)");
        chip.addEventListener("mouseleave", () => chip.style.borderColor = "var(--border2)");
        xSpan.addEventListener("mouseenter", () => xSpan.style.color = "var(--up)");
        xSpan.addEventListener("mouseleave", () => xSpan.style.color = "var(--text3)");

        box.appendChild(chip);
    });
}

/**
 * ❌ 3. 특정 키워드 개별 삭제 함수
 */
function deleteRecentKeyword(event, keyword) {
    // 부모 요소인 chip의 검색 이벤트가 터지지 않도록 버블링 막기
    event.stopPropagation();

    let keywords = JSON.parse(localStorage.getItem("recent_news_keywords")) || [];
    keywords = keywords.filter(kw => kw !== keyword);

    localStorage.setItem("recent_news_keywords", JSON.stringify(keywords));
    renderRecentKeywords();
}

/**
 * 🧹 4. 최근 검색어 전체 삭제 함수
 */
function clearAllRecentKeywords() {
    if (confirm("최근 검색 기록을 모두 삭제하시겠습니까?")) {
        localStorage.removeItem("recent_news_keywords");
        renderRecentKeywords();
    }
}

// 🌟 인라인 onclick 호출용 전역 스코프 바인딩 개통
window.clearAllRecentKeywords = clearAllRecentKeywords;
window.deleteRecentKeyword = deleteRecentKeyword;