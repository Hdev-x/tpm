<div class="news-container" style="background-color: #16171a; color: #ffffff; padding: 20px; border-radius: 8px; margin-top: 20px;">
    <h3 style="border-bottom: 1px solid #2a2e39; padding-bottom: 10px; margin-top: 0;">
        📰 실시간 <span id="current-news-keyword" style="color: #2962ff;">삼성전자</span> 뉴스
    </h3>
    
    <div id="naver-news-list" class="news-list">
        <p style="color: #848e9c;">뉴스를 불러오는 중입니다...</p>
    </div>
</div>

<script>
/**
 * ⚡ 특정 종목의 네이버 실시간 뉴스를 가져와 JSP 화면에 강제 점등하는 함수
 */
function loadStockNews(keyword) {
    if (!keyword) keyword = "삼성전자";
    
    // 타이틀 텍스트 변경
    document.getElementById("current-news-keyword").innerText = keyword;
    
    const newsListDiv = document.getElementById("naver-news-list");
    
    // 📡 아까 만든 NewsController 엔드포인트를 비동기로 호출
    fetch(`/stock/news?keyword=\${encodeURIComponent(keyword)}`)
        .then(response => {
            if (!response.ok) throw new Error("뉴스 수급 제한 단계");
            return response.json();
        })
        .then(data => {
            newsListDiv.innerHTML = ""; // 기존 뉴스 밀어버리기
            
            if (!data.items || data.items.length === 0) {
                newsListDiv.innerHTML = `<p style="color: #848e9c;">관련 뉴스가 존재하지 않습니다.</p>`;
                return;
            }
            
            // 🔄 네이버 뉴스 10개 카드 레이아웃 루프 가동
            data.items.forEach(item => {
                const card = document.createElement("div");
                card.style.borderBottom = "1px solid #2a2e39";
                card.style.padding = "12px 0";
                
                // 💡 [핵심] innerHTML을 써야 네이버가 준 <b>태그가 폰트 굵게(Bold)로 정상 표현됩니다.
                card.innerHTML = `
                    <div style="margin-bottom: 6px;">
                        <a href="\${item.link}" target="_blank" style="color: #e9ecf0; text-decoration: none; font-weight: bold; font-size: 15px; hover: text-decoration: underline;">
                            \${item.title}
                        </a>
                    </div>
                    <div style="color: #848e9c; font-size: 13px; line-height: 1.5; margin-bottom: 4px;">
                        \${item.description}
                    </div>
                    <div style="color: #474d57; font-size: 11px;">
                        \${formatNewsDate(item.pubDate)}
                    </div>
                `;
                newsListDiv.appendChild(card);
            });
        })
        .catch(error => {
            console.error("❌ 뉴스 동기화 실패:", error);
            newsListDiv.innerHTML = `<p style="color: #f23645;">⚠️ 뉴스 피드를 일시적으로 수급할 수 없습니다.</p>`;
        });
}

/**
 * ⏰ 네이버의 영문 날짜 규격(Mon, 18 May 2026...)을 보기 편하게 정제하는 헬퍼 함수
 */
function formatNewsDate(pubDateStr) {
    try {
        const date = new Date(pubDateStr);
        return date.toLocaleString('ko-KR', { 
            year: 'numeric', month: '2-digit', day: '2-digit', 
            hour: '2-digit', minute: '2-digit' 
        });
    } catch (e) {
        return pubDateStr; // 파싱 실패 시 원본 그대로 노출
    }
}

// 🚀 [최초 실행] JSP 페이지가 처음 로딩될 때 기본값(삼성전자)으로 뉴스 페치
document.addEventListener("DOMContentLoaded", function() {
    loadStockNews("삼성전자");
});