<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!-- ────────────────────────────────────────────────────────
     NAV (상단 내비게이션 바)
     - <nav> 태그는 HTML5 시맨틱 태그: "이 영역은 탐색 링크"임을 명시
     - display:flex; align-items:center 로 로고/메뉴/검색이 한 줄로 배치
     ──────────────────────────────────────────────────────── -->
<nav>
    <!-- 로고: "Trade"는 일반 텍스트, "Bot"은 <span>으로 감싸 색상을 다르게 적용 -->
    <span class="logo">Trade<span>Bot</span></span>

    <!-- 메뉴 아이템들
                     - <a href>  : 실제 페이지 이동 링크 (대시보드만 구현됨)
                     - <span>    : 아직 미구현된 메뉴는 클릭 불가 텍스트로만 표시
                     - .active   : 현재 페이지임을 표시 (CSS에서 색상/밑줄 강조)
                -->
    <a href="/dashboard" class="nav-item">대시보드</a>
    <span class="nav-item active">차트</span>
    <span class="nav-item">백테스트</span>
    <span class="nav-item">자동매매</span>
    <span class="nav-item">로그</span>
    <span class="nav-item">설정</span>

    <!-- 오른쪽 영역: margin-left:auto 로 오른쪽 끝에 밀려남 -->
    <div class="nav-right">
        <!-- 검색 버튼: SVG 돋보기 아이콘 + "검색" 텍스트
                         SVG: circle(원)=렌즈, path(선)=손잡이 -->
        <div class="nav-search">
            <svg viewBox="0 0 24 24">
                <circle cx="11" cy="11" r="8" />
                <path d="M21 21l-4.35-4.35" />
            </svg>
            <span>검색</span>
        </div>
        <button class="nav-login-btn">로그인</button>
    </div>
</nav>