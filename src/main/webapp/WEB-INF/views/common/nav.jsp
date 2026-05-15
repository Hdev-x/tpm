<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<nav style="
    position: fixed; 
    top: 0; 
    left: 0; 
    width: 100%; 
    height: 60px; 
    display: flex; 
    align-items: center; 
    background: var(--surface);
    z-index: 1000; 
    padding: 0 50px; 
    box-sizing: border-box; 
    border-bottom: 1px solid var(--border);">

    <span class="logo" onclick="location.href='/'" style="cursor:pointer;"><span>B</span>조</span>

 	<a href="../" class="nav-item">홈</a>
    <a href="/stock/view" class="nav-item">주식</a>
    <a href="/board/list" class="nav-item">커뮤니티</a>
    <a href="/notice/list" class="nav-item">공지사항</a>
    <span class="nav-item">백테스트</span>
    <span class="nav-item">자동매매</span>
    <span class="nav-item">로그</span>
    <span class="nav-item">설정</span>

    <div class="nav-right" style="margin-left: auto; display: flex; align-items: center; gap: 20px;">
        <div class="nav-search">
            <svg viewBox="0 0 24 24" style="width: 18px; height: 18px; fill: none; stroke: currentColor; stroke-width: 2;">
                <circle cx="11" cy="11" r="8" />
                <path d="M21 21l-4.35-4.35" />
            </svg>
            <span>검색</span>
        </div>
        <button class="nav-login-btn">로그인</button>
        <div class="nav-right">
                <c:choose>
                    <c:when test="${empty member}">
                        <a href="/member/login" class="nav-item">로그인</a>
                        <a href="/member/create" class="nav-login-btn" style="text-decoration: none;">회원가입</a>
                    </c:when>
                    <c:otherwise>
                        <span class="ph-label" style="margin-right: 12px; color: var(--text2);">
                            <strong>${member.username}</strong>님 환영합니다
                        </span>
                        <a href="/member/logout" class="nav-item">로그아웃</a>
                        <button class="nav-login-btn" onclick="toggleSidebar('invest')">내 지갑</button>
                    </c:otherwise>
                </c:choose>
            </div>
        
    </div>
</nav>