<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>TradeBot · 코인 리스트</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
    <link rel="stylesheet" href="/css/common.css">
    <link rel="stylesheet" href="/css/coinList.css">
</head>
<body data-sidebar-animate="true">

<div class="app-wrapper">

    <div class="page">

        <%@ include file="../common/nav.jsp" %>

        <div class="main-content">

            <!-- 상단 티커 바 -->
            <div class="ticker-bar">
                <div class="ticker-left">
                    <div class="ticker-today">
                        <div class="ticker-today-label">오늘</div>
                        <div class="ticker-today-content">
                            <div class="ticker-today-title">증시캘린더</div>
                            <div class="ticker-today-sub">주간 신규실업수당 청구건수...</div>
                        </div>
                    </div>
                </div>
                <div class="ticker-items">
                    <div class="ticker-item">
                        <div class="ticker-item-chart down-chart">
                            <svg viewBox="0 0 60 28" preserveAspectRatio="none"><polyline points="0,8 15,10 30,14 45,18 60,22"/></svg>
                        </div>
                        <div class="ticker-item-info">
                            <div class="ticker-item-name">달러 환율</div>
                            <div class="ticker-item-price">1,493.25 <span class="down">-1.85 (0.12%)</span></div>
                        </div>
                    </div>
                    <div class="ticker-item">
                        <div class="ticker-item-chart up-chart">
                            <svg viewBox="0 0 60 28" preserveAspectRatio="none"><polyline points="0,20 15,18 30,14 45,10 60,6"/></svg>
                        </div>
                        <div class="ticker-item-info">
                            <div class="ticker-item-name">코스피</div>
                            <div class="ticker-item-price">7,860.98 <span class="up">+16.97 (0.21%)</span></div>
                        </div>
                    </div>
                    <div class="ticker-item">
                        <div class="ticker-item-chart down-chart">
                            <svg viewBox="0 0 60 28" preserveAspectRatio="none"><polyline points="0,8 15,12 30,16 45,20 60,22"/></svg>
                        </div>
                        <div class="ticker-item-info">
                            <div class="ticker-item-name">코스닥</div>
                            <div class="ticker-item-price">1,165.77 <span class="down">-11.16 (0.94%)</span></div>
                        </div>
                    </div>
                    <div class="ticker-item">
                        <div class="ticker-item-chart up-chart">
                            <svg viewBox="0 0 60 28" preserveAspectRatio="none"><polyline points="0,22 15,18 30,14 45,10 60,4"/></svg>
                        </div>
                        <div class="ticker-item-info">
                            <div class="ticker-item-name">나스닥</div>
                            <div class="ticker-item-price">26,402.34 <span class="up">+314.14 (1.20%)</span></div>
                        </div>
                    </div>
                </div>
                <div class="ticker-right">
                    <button class="ticker-arrow">›</button>
                </div>
            </div>

            <!-- 메인 탭 -->
            <div class="main-tabs">
                <button class="main-tab active" data-tab="realtime">실시간 차트</button>
                <button class="main-tab" data-tab="category">지금 뜨는 카테고리</button>
                <button class="main-tab" data-tab="investor">국내 투자자 동향</button>
            </div>

            <!-- 탭 컨텐츠 -->
            <div class="tab-content" id="tab-realtime">

                <!-- 필터 버튼 행 -->
                <div class="filter-row">
                    <div class="filter-group">
                        <button class="filter-btn active">전체</button>
                        <button class="filter-btn">국내</button>
                        <button class="filter-btn">해외</button>
                    </div>
                    <div class="filter-divider"></div>
                    <div class="filter-group">
                        <button class="filter-btn active">토스증권 거래대금</button>
                        <button class="filter-btn">토스증권 거래량</button>
                        <button class="filter-btn">거래대금</button>
                        <button class="filter-btn">거래량</button>
                        <button class="filter-btn">급상승</button>
                        <button class="filter-btn">급하락</button>
                    </div>
                    <div class="filter-divider"></div>
                    <div class="filter-group">
                        <button class="filter-btn time active">실시간</button>
                        <button class="filter-btn time">1일</button>
                        <button class="filter-btn time">1주일</button>
                        <button class="filter-btn time">1개월</button>
                        <button class="filter-btn time">3개월</button>
                        <button class="filter-btn time">6개월</button>
                        <button class="filter-btn time">1년</button>
                    </div>
                    <button class="risk-hide-btn">
                        <svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="10" stroke="var(--blue)" stroke-width="2"/><polyline points="7 12 10.5 15.5 17 9" stroke="var(--blue)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
                        투자위험 주식 숨기기
                    </button>
                </div>

                <div class="content-layout">

                    <!-- 좌측: 테이블 -->
                    <div class="list-panel">

                        <!-- 테이블 헤더 -->
                        <div class="stock-table-wrap">
                            <table class="stock-table">
                                <thead>
                                    <tr>
                                        <th class="th-rank">순위 · 오늘 12:49 기준</th>
                                        <th class="th-price">현재가</th>
                                        <th class="th-change">등락률</th>
                                        <th class="th-volume">거래대금 순</th>
                                        <th class="th-ratio">토스증권 거래 비율 <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg></th>
                                        <th class="th-ai">토스증권 AI 요약 <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg></th>
                                    </tr>
                                </thead>
                                <tbody id="stockTableBody">
                                    <tr class="stock-row active" data-idx="0">
                                        <td class="td-rank">
                                            <div class="rank-inner">
                                            <button class="like-btn liked"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                                            <span class="rank-num">1</span>
                                            <div class="stock-icon red-icon">SK</div>
                                            <span class="stock-name">SK하이닉스</span>
                                            </div>
                                        </td>
                                        <td class="td-price">1,944,000원</td>
                                        <td class="td-change"><span class="badge down">-1.61%</span></td>
                                        <td class="td-volume">631억원</td>
                                        <td class="td-ratio">
                                            <div class="ratio-wrap">
                                                <div class="ratio-bar">
                                                    <div class="ratio-sell" style="width:27%"></div>
                                                    <div class="ratio-buy" style="width:73%"></div>
                                                </div>
                                                <div class="ratio-nums"><span>27</span><span>73</span></div>
                                            </div>
                                        </td>
                                        <td class="td-ai">차익실현 매물 출회</td>
                                    </tr>
                                    <tr class="stock-row" data-idx="1" onclick="location.href='/coin/chart3-toss'" style="cursor:pointer">
                                        <td class="td-rank">
                                            <div class="rank-inner">
                                            <button class="like-btn liked"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                                            <span class="rank-num">2</span>
                                            <div class="stock-icon blue-icon">삼</div>
                                            <span class="stock-name">삼성전자</span>
                                            </div>
                                        </td>
                                        <td class="td-price">290,000원</td>
                                        <td class="td-change"><span class="badge up">+2.11%</span></td>
                                        <td class="td-volume">257억원</td>
                                        <td class="td-ratio">
                                            <div class="ratio-wrap">
                                                <div class="ratio-bar">
                                                    <div class="ratio-sell" style="width:40%"></div>
                                                    <div class="ratio-buy" style="width:60%"></div>
                                                </div>
                                                <div class="ratio-nums"><span>40</span><span>60</span></div>
                                            </div>
                                        </td>
                                        <td class="td-ai">AI 반도체 랠리</td>
                                    </tr>
                                    <tr class="stock-row" data-idx="2">
                                        <td class="td-rank">
                                            <div class="rank-inner">
                                            <button class="like-btn"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                                            <span class="rank-num">3</span>
                                            <div class="stock-icon blue-icon">2x</div>
                                            <span class="stock-name">KODEX 레버리지</span>
                                            </div>
                                        </td>
                                        <td class="td-price">172,685원</td>
                                        <td class="td-change"><span class="badge up">+0.45%</span></td>
                                        <td class="td-volume">78억원</td>
                                        <td class="td-ratio">
                                            <div class="ratio-wrap">
                                                <div class="ratio-bar">
                                                    <div class="ratio-sell" style="width:50%"></div>
                                                    <div class="ratio-buy" style="width:50%"></div>
                                                </div>
                                                <div class="ratio-nums"><span>50</span><span>50</span></div>
                                            </div>
                                        </td>
                                        <td class="td-ai">반도체주 강세 영향</td>
                                    </tr>
                                    <tr class="stock-row" data-idx="3">
                                        <td class="td-rank">
                                            <div class="rank-inner">
                                            <button class="like-btn"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                                            <span class="rank-num">4</span>
                                            <div class="stock-icon cyan-icon">현</div>
                                            <span class="stock-name">현대차</span>
                                            </div>
                                        </td>
                                        <td class="td-price">696,000원</td>
                                        <td class="td-change"><span class="badge down">-1.97%</span></td>
                                        <td class="td-volume">78억원</td>
                                        <td class="td-ratio">
                                            <div class="ratio-wrap">
                                                <div class="ratio-bar">
                                                    <div class="ratio-sell" style="width:37%"></div>
                                                    <div class="ratio-buy" style="width:63%"></div>
                                                </div>
                                                <div class="ratio-nums"><span>37</span><span>63</span></div>
                                            </div>
                                        </td>
                                        <td class="td-ai"></td>
                                    </tr>
                                    <tr class="stock-row" data-idx="4">
                                        <td class="td-rank">
                                            <div class="rank-inner">
                                            <button class="like-btn"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                                            <span class="rank-num">5</span>
                                            <div class="stock-icon orange-icon">3x</div>
                                            <span class="stock-name">SOXL</span>
                                            </div>
                                        </td>
                                        <td class="td-price">273,229원</td>
                                        <td class="td-change"><span class="badge down">-0.80%</span></td>
                                        <td class="td-volume">73억원</td>
                                        <td class="td-ratio">
                                            <div class="ratio-wrap">
                                                <div class="ratio-bar">
                                                    <div class="ratio-sell" style="width:66%"></div>
                                                    <div class="ratio-buy" style="width:34%"></div>
                                                </div>
                                                <div class="ratio-nums"><span>66</span><span>34</span></div>
                                            </div>
                                        </td>
                                        <td class="td-ai">AI 반도체 투자</td>
                                    </tr>
                                    <tr class="stock-row" data-idx="5">
                                        <td class="td-rank">
                                            <div class="rank-inner">
                                            <button class="like-btn liked"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                                            <span class="rank-num">6</span>
                                            <div class="stock-icon red-icon">LG</div>
                                            <span class="stock-name">LG씨엔에스</span>
                                            </div>
                                        </td>
                                        <td class="td-price">83,600원</td>
                                        <td class="td-change"><span class="badge up">+13.74%</span></td>
                                        <td class="td-volume">54억원</td>
                                        <td class="td-ratio">
                                            <div class="ratio-wrap">
                                                <div class="ratio-bar">
                                                    <div class="ratio-sell" style="width:55%"></div>
                                                    <div class="ratio-buy" style="width:45%"></div>
                                                </div>
                                                <div class="ratio-nums"><span>55</span><span>45</span></div>
                                            </div>
                                        </td>
                                        <td class="td-ai">실적 성장</td>
                                    </tr>
                                    <tr class="stock-row" data-idx="6">
                                        <td class="td-rank">
                                            <div class="rank-inner">
                                            <button class="like-btn"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                                            <span class="rank-num">7</span>
                                            <div class="stock-icon blue-icon">2x</div>
                                            <span class="stock-name">SNXX</span>
                                            </div>
                                        </td>
                                        <td class="td-price">238,468원</td>
                                        <td class="td-change"><span class="badge down">-4.14%</span></td>
                                        <td class="td-volume">52억원</td>
                                        <td class="td-ratio">
                                            <div class="ratio-wrap">
                                                <div class="ratio-bar">
                                                    <div class="ratio-sell" style="width:39%"></div>
                                                    <div class="ratio-buy" style="width:61%"></div>
                                                </div>
                                                <div class="ratio-nums"><span>39</span><span>61</span></div>
                                            </div>
                                        </td>
                                        <td class="td-ai"></td>
                                    </tr>
                                    <tr class="stock-row" data-idx="7">
                                        <td class="td-rank">
                                            <div class="rank-inner">
                                            <button class="like-btn liked"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                                            <span class="rank-num">8</span>
                                            <div class="stock-icon teal-icon">대</div>
                                            <span class="stock-name">대한광통신</span>
                                            </div>
                                        </td>
                                        <td class="td-price">23,400원</td>
                                        <td class="td-change"><span class="badge down">-5.45%</span></td>
                                        <td class="td-volume">50억원</td>
                                        <td class="td-ratio">
                                            <div class="ratio-wrap">
                                                <div class="ratio-bar">
                                                    <div class="ratio-sell" style="width:41%"></div>
                                                    <div class="ratio-buy" style="width:59%"></div>
                                                </div>
                                                <div class="ratio-nums"><span>41</span><span>59</span></div>
                                            </div>
                                        </td>
                                        <td class="td-ai"></td>
                                    </tr>
                                    <tr class="stock-row" data-idx="8">
                                        <td class="td-rank">
                                            <div class="rank-inner">
                                            <button class="like-btn liked"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                                            <span class="rank-num">9</span>
                                            <div class="stock-icon red-icon">LG</div>
                                            <span class="stock-name">LG전자</span>
                                            </div>
                                        </td>
                                        <td class="td-price">208,500원</td>
                                        <td class="td-change"><span class="badge up">+8.93%</span></td>
                                        <td class="td-volume">38억원</td>
                                        <td class="td-ratio">
                                            <div class="ratio-wrap">
                                                <div class="ratio-bar">
                                                    <div class="ratio-sell" style="width:48%"></div>
                                                    <div class="ratio-buy" style="width:52%"></div>
                                                </div>
                                                <div class="ratio-nums"><span>48</span><span>52</span></div>
                                            </div>
                                        </td>
                                        <td class="td-ai">로봇 신사업 기대감</td>
                                    </tr>
                                    <tr class="stock-row" data-idx="9">
                                        <td class="td-rank">
                                            <div class="rank-inner">
                                            <button class="like-btn"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                                            <span class="rank-num">10</span>
                                            <div class="stock-icon purple-icon">D</div>
                                            <span class="stock-name">대우건설</span>
                                            </div>
                                        </td>
                                        <td class="td-price">31,250원</td>
                                        <td class="td-change"><span class="badge up">+7.94%</span></td>
                                        <td class="td-volume">26억원</td>
                                        <td class="td-ratio">
                                            <div class="ratio-wrap">
                                                <div class="ratio-bar">
                                                    <div class="ratio-sell" style="width:51%"></div>
                                                    <div class="ratio-buy" style="width:49%"></div>
                                                </div>
                                                <div class="ratio-nums"><span>51</span><span>49</span></div>
                                            </div>
                                        </td>
                                        <td class="td-ai"></td>
                                    </tr>
                                    <tr class="stock-row" data-idx="10">
                                        <td class="td-rank">
                                            <div class="rank-inner">
                                            <button class="like-btn liked"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                                            <span class="rank-num">11</span>
                                            <div class="stock-icon red-icon">빛</div>
                                            <span class="stock-name">빛샘전자</span>
                                            </div>
                                        </td>
                                        <td class="td-price">17,760원</td>
                                        <td class="td-change"><span class="badge up">+16.15%</span></td>
                                        <td class="td-volume">24억원</td>
                                        <td class="td-ratio">
                                            <div class="ratio-wrap">
                                                <div class="ratio-bar">
                                                    <div class="ratio-sell" style="width:51%"></div>
                                                    <div class="ratio-buy" style="width:49%"></div>
                                                </div>
                                                <div class="ratio-nums"><span>51</span><span>49</span></div>
                                            </div>
                                        </td>
                                        <td class="td-ai"></td>
                                    </tr>
                                    <tr class="stock-row" data-idx="11">
                                        <td class="td-rank">
                                            <div class="rank-inner">
                                            <button class="like-btn"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                                            <span class="rank-num">12</span>
                                            <div class="stock-icon red-icon">한</div>
                                            <span class="stock-name">한국전력</span>
                                            </div>
                                        </td>
                                        <td class="td-price">38,850원</td>
                                        <td class="td-change"><span class="badge down">-4.66%</span></td>
                                        <td class="td-volume">24억원</td>
                                        <td class="td-ratio">
                                            <div class="ratio-wrap">
                                                <div class="ratio-bar">
                                                    <div class="ratio-sell" style="width:14%"></div>
                                                    <div class="ratio-buy" style="width:86%"></div>
                                                </div>
                                                <div class="ratio-nums"><span>14</span><span>86</span></div>
                                            </div>
                                        </td>
                                        <td class="td-ai">실적 기대치 하회</td>
                                    </tr>
                                    <tr class="stock-row" data-idx="12">
                                        <td class="td-rank">
                                            <div class="rank-inner">
                                            <button class="like-btn"><svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg></button>
                                            <span class="rank-num">13</span>
                                            <div class="stock-icon gray-icon">두</div>
                                            <span class="stock-name">두산에너빌리티</span>
                                            </div>
                                        </td>
                                        <td class="td-price">116,300원</td>
                                        <td class="td-change"><span class="badge down">-3.08%</span></td>
                                        <td class="td-volume">22억원</td>
                                        <td class="td-ratio">
                                            <div class="ratio-wrap">
                                                <div class="ratio-bar">
                                                    <div class="ratio-sell" style="width:32%"></div>
                                                    <div class="ratio-buy" style="width:68%"></div>
                                                </div>
                                                <div class="ratio-nums"><span>32</span><span>68</span></div>
                                            </div>
                                        </td>
                                        <td class="td-ai">외국인 순매도 확대</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- 우측: 종목 상세 패널 -->
                    <div class="detail-panel">
                        <div class="detail-header">
                            <div class="detail-icon red-icon">SK</div>
                            <div class="detail-title-wrap">
                                <div class="detail-name">SK하이닉스</div>
                                <div class="detail-price">1,944,000원 <span class="down">-1.61%</span></div>
                            </div>
                        </div>

                        <!-- 차트 영역 (빈 박스) -->
                        <div class="detail-chart-area">
                            <canvas id="detailChart"></canvas>
                        </div>

                        <!-- 왜 떨어졌을까? -->
                        <div class="detail-reason-section">
                            <div class="detail-reason-title">왜 떨어졌을까?</div>
                            <div class="detail-reason-time">39분 전</div>
                        </div>
                        <div class="detail-reason-content">
                            <div class="detail-reason-icon">
                                <svg viewBox="0 0 24 24"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
                            </div>
                            <div class="detail-reason-text">
                                <div class="detail-reason-main">차익실현 매물 출회로 SK하이닉스 <span class="down">-0.71% 하락</span> <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg></div>
                                <div class="detail-reason-sub">SK하이닉스는 최근 급등 이후 외국인과 기관의 차익실현 매물이 출회되며 약세를 보이고 있어요</div>
                            </div>
                        </div>
                        <button class="detail-login-btn">로그인하고 이유 보기</button>

                        <!-- 한 줄 요약 -->
                        <div class="detail-summary-section">
                            <div class="detail-summary-title">한 줄 요약</div>
                        </div>
                        <div class="detail-summary-item">
                            <div class="detail-summary-badge">호재</div>
                            <div class="detail-summary-text">최근 1년 사이 가장 높은 애널리스트 목표주가가 나왔어요.</div>
                            <div class="detail-summary-date">2일 전</div>
                        </div>

                        <!-- 커뮤니티 -->
                        <div class="detail-community-section">
                            <div class="detail-community-title">커뮤니티</div>
                        </div>
                        <div class="detail-community-item">
                            <div class="detail-community-avatar">영</div>
                            <div class="detail-community-content">
                                <div class="detail-community-meta"><span class="community-tag">주주</span> <span class="community-name">영끌영차</span> <span class="community-time">9분</span></div>
                                <div class="detail-community-text">사나이 테스트~ 시작합니다</div>
                            </div>
                        </div>
                        <div class="detail-community-item">
                            <div class="detail-community-avatar">호</div>
                            <div class="detail-community-content">
                                <div class="detail-community-meta"><span class="community-name">호원한수형</span> <span class="community-time">5분</span></div>
                                <div class="detail-community-text">...</div>
                            </div>
                        </div>
                    </div>

                </div>
            </div>

            <div class="tab-content hidden" id="tab-category">
                <div class="empty-tab">지금 뜨는 카테고리</div>
            </div>
            <div class="tab-content hidden" id="tab-investor">
                <div class="empty-tab">국내 투자자 동향</div>
            </div>

        </div>

    </div>

    <%@ include file="../common/sidebar.jsp" %>

    <%@ include file="../common/sidebar-icons.jsp" %>

</div>

<script src="/js/common.js"></script>
<script src="/js/coinList.js"></script>
</body>
</html>
