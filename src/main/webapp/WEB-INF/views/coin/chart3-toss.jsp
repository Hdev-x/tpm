<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>TradeBot · 차트</title>
<script src="https://unpkg.com/lightweight-charts@5.2.0/dist/lightweight-charts.standalone.production.js"></script>
<script src="https://unpkg.com/lwc-plugin-countdown-to-close@2.0.0/dist/lwc-plugin-countdown-to-close.umd.cjs"></script>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }

:root {
    --bg:        #0C0C0F;
    --surface:   #16161A;
    --surface2:  #1C1C22;
    --border:    rgba(255,255,255,0.07);
    --border2:   rgba(255,255,255,0.12);
    --text:      #FFFFFF;
    --text2:     rgba(255,255,255,0.55);
    --text3:     rgba(255,255,255,0.3);
    --blue:      #3182F6;
    --up:        #F04452;
    --down:      #2563EB;
    --radius:    12px;
    --gap:       15px;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, "Pretendard", "Segoe UI", sans-serif;
    background: var(--bg);
    color: var(--text);
    font-size: 13px;
    height: 100vh;
    overflow: hidden;
    font-variant-numeric: tabular-nums;
}

/* ── NAV ── */
nav {
    height: 56px;
    background: var(--bg);
    border-bottom: 1px solid var(--bg);
    display: flex;
    align-items: center;
    padding: 0 50px;
    flex-shrink: 0;
    gap: 4px;
}
.logo {
    font-size: 17px;
    font-weight: 800;
    color: var(--text);
    margin-right: 24px;
    letter-spacing: -0.3px;
}
.logo span { color: var(--blue); }
.nav-item {
    color: var(--text2);
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    padding: 6px 14px;
    border-radius: 8px;
    text-decoration: none;
    transition: background 0.15s, color 0.15s;
}
.nav-item:hover { background: rgba(255,255,255,0.06); color: var(--text); }
.nav-item.active { color: var(--text); background: rgba(255,255,255,0.06); }
.nav-right { margin-left: auto; display: flex; align-items: center; gap: 8px; }
.nav-search {
    display: flex; align-items: center; gap: 8px;
    background: var(--surface); border: 1px solid var(--border2);
    border-radius: 10px; padding: 7px 14px; cursor: pointer;
    color: var(--text3); font-size: 13px; width: 200px;
    transition: border-color 0.15s;
}
.nav-search:hover { border-color: var(--blue); }
.nav-search svg { width: 14px; height: 14px; stroke: currentColor; fill: none; stroke-width: 2; flex-shrink: 0; }
.nav-login-btn {
    padding: 8px 18px; background: var(--blue); color: #fff;
    border: none; border-radius: 10px; font-size: 14px; font-weight: 700;
    cursor: pointer; transition: opacity 0.15s; white-space: nowrap;
}
.nav-login-btn:hover { opacity: 0.88; }
.nav-right { margin-left: auto; display: flex; align-items: center; gap: 8px; }
.nav-search {
    display: flex; align-items: center; gap: 8px;
    background: var(--surface); border: 1px solid var(--border2);
    border-radius: 10px; padding: 7px 14px; cursor: pointer;
    color: var(--text3); font-size: 13px; width: 200px;
    transition: border-color 0.15s;
}
.nav-search:hover { border-color: var(--blue); }
.nav-search svg { width: 14px; height: 14px; stroke: currentColor; fill: none; stroke-width: 2; flex-shrink: 0; }
.nav-login-btn {
    padding: 8px 18px; background: var(--blue); color: #fff;
    border: none; border-radius: 10px; font-size: 14px; font-weight: 700;
    cursor: pointer; transition: opacity 0.15s; white-space: nowrap;
}
.nav-login-btn:hover { opacity: 0.88; }

/* ── PRICE HEADER ── */
.price-header {
    background: var(--bg);
    border-bottom: 1px solid var(--bg);
    display: flex;
    align-items: center;
    padding: 10px 50px;
    gap: 0;
    flex-shrink: 0;
}
.ph-left { display: flex; flex-direction: column; gap: 4px; margin-right: 40px; flex-shrink: 0; }
.ph-name-row { display: flex; align-items: center; gap: 8px; }
.ph-name { font-size: 15px; font-weight: 700; color: var(--text); }
.ph-ticker { font-size: 12px; font-weight: 500; color: var(--text3); background: var(--surface2); padding: 2px 7px; border-radius: 5px; }
.ph-price-row { display: flex; align-items: center; gap: 6px; }
.ph-price { font-size: 26px; font-weight: 800; letter-spacing: -0.8px; color: var(--text); line-height: 1; }
.ph-change { font-size: 15px; font-weight: 600; line-height: 1; }
.ph-right { display: flex; align-items: center; margin-left: auto; }
.ph-group { display: flex; gap: 20px; padding: 0 20px; }
.ph-item { display: flex; flex-direction: column; gap: 3px; }
.ph-label { font-size: 11px; color: var(--text3); font-weight: 500; white-space: nowrap; }
.ph-value { font-size: 13px; color: var(--text2); font-weight: 600; white-space: nowrap; }
.ph-vdivider { width: 1px; height: 30px; background: var(--border2); flex-shrink: 0; align-self: center; }
.ph-actions { display: flex; align-items: center; gap: 8px; margin-left: 20px; flex-shrink: 0; }
.ph-like-btn {
    display: flex; align-items: center; gap: 6px;
    padding: 7px 14px; border-radius: 10px; border: 1px solid var(--border2);
    background: transparent; color: var(--text2); font-size: 13px; font-weight: 600;
    cursor: pointer; transition: all 0.15s;
}
.ph-like-btn:hover { border-color: var(--up); color: var(--up); background: rgba(240,68,82,0.08); }
.ph-like-btn svg { width: 15px; height: 15px; stroke: currentColor; fill: none; stroke-width: 2; }
.up   { color: var(--up); }
.down { color: var(--down); }

/* ── APP WRAPPER (최상위) ── */
.app-wrapper { display: flex; height: 100vh; overflow: hidden; }

/* ── PAGE ── */
.page { flex: 1; min-width: 0; display: flex; flex-direction: column; overflow: hidden; }

/* ── MAIN LAYOUT ── */
.main-layout {
    display: flex;
    flex: 1;
    min-height: 0;
    padding: var(--gap) 50px 120px;
    gap: 0;
    background: var(--bg);
}

/* ── CARD BASE ── */
.card {
    background: var(--surface);
    border-radius: var(--radius);
    border: 1px solid var(--border);
    overflow: hidden;
    display: flex;
    flex-direction: column;
}

/* ── RESIZE HANDLES ── */
.resize-h {
    width: var(--gap);
    flex-shrink: 0;
    cursor: col-resize;
    background: var(--bg);
    position: relative;
    z-index: 10;
}
.resize-h::after {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 2px;
    height: 32px;
    border-radius: 2px;
    background: transparent;
    transition: background 0.15s;
}
.resize-h:hover::after, .resize-h.dragging::after { background: var(--blue); }

.resize-v {
    height: var(--gap);
    flex-shrink: 0;
    cursor: row-resize;
    background: var(--bg);
    position: relative;
}
.resize-v::after {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    height: 2px;
    width: 32px;
    border-radius: 2px;
    background: transparent;
    transition: background 0.15s;
}
.resize-v:hover::after, .resize-v.dragging::after { background: var(--blue); }

/* ── CHART PANEL ── */
.panel-chart {
    flex: 1;
    min-width: 200px;
    display: flex;
    flex-direction: column;
}

.chart-toolbar {
    display: flex;
    align-items: center;
    padding: 0 12px;
    height: 40px;
    border-bottom: 1px solid var(--border);
    gap: 2px;
    flex-shrink: 0;
    background: var(--surface);
}
.tf-btn {
    padding: 4px 8px;
    border-radius: 6px;
    font-size: 12px;
    font-weight: 500;
    color: var(--text2);
    cursor: pointer;
    border: none;
    background: none;
    transition: background 0.12s, color 0.12s;
}
.tf-btn:hover { background: rgba(255,255,255,0.07); color: var(--text); }
.tf-btn.active { background: var(--blue); color: #fff; }
.tb-divider { width: 1px; height: 16px; background: var(--border2); margin: 0 6px; flex-shrink: 0; }
.ind-btn {
    padding: 4px 8px;
    border-radius: 6px;
    font-size: 12px;
    font-weight: 500;
    color: var(--text2);
    cursor: pointer;
    border: 1px solid transparent;
    background: none;
    transition: background 0.12s, color 0.12s;
}
.ind-btn:hover { background: rgba(255,255,255,0.07); color: var(--text); }
.settings-wrap { position: relative; margin-left: auto; }
.settings-menu {
    display: none;
    position: absolute;
    top: calc(100% + 8px);
    right: 0;
    background: var(--surface2);
    border: 1px solid var(--border2);
    border-radius: 12px;
    padding: 8px 0;
    min-width: 230px;
    z-index: 200;
    box-shadow: 0 8px 32px rgba(0,0,0,0.5);
}
.settings-menu.open { display: block; }
.settings-title {
    font-size: 11px;
    color: var(--text3);
    padding: 4px 16px 8px;
    border-bottom: 1px solid var(--border);
    margin-bottom: 4px;
    font-weight: 600;
    letter-spacing: 0.4px;
    text-transform: uppercase;
}
.settings-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 9px 16px;
    cursor: pointer;
    gap: 12px;
}
.settings-item:hover { background: rgba(255,255,255,0.04); }
.settings-label { display: flex; flex-direction: column; gap: 2px; font-size: 13px; color: var(--text); }
.settings-label small { font-size: 11px; color: var(--text3); }
.settings-item input[type="checkbox"] { width: 16px; height: 16px; accent-color: var(--blue); cursor: pointer; flex-shrink: 0; }

#chart-wrapper { flex: 1; display: flex; flex-direction: column; min-height: 0; position: relative; }
#chart-container { flex: 1; position: relative; min-height: 0; }
#ohlc-bar {
    position: absolute; top: 10px; left: 12px; z-index: 10;
    font-size: 11px; background: rgba(22,22,26,0.88);
    padding: 4px 10px; border-radius: 6px; color: var(--text2); pointer-events: none;
    border: 1px solid var(--border);
}
#ohlc-bar b { font-weight: 700; color: var(--text); }
#pane-divider {
    height: 4px; background: var(--border); cursor: row-resize; display: none;
    transition: background 0.15s;
}
#pane-divider:hover { background: var(--blue); }
#rsi-container { height: 150px; display: none; }

/* ── MIDDLE PANEL ── */
.panel-middle {
    flex: 0 0 340px;
    min-width: 340px;
    max-width: 340px;
    display: flex;
    flex-direction: column;
}

/* 주문창 */
.panel-order-wrap {
    flex: 0 0 auto;
    display: flex;
    flex-direction: column;
    overflow: hidden;
}
.order-tabs {
    display: flex;
    border-bottom: 1px solid var(--border);
    flex-shrink: 0;
}
.order-tab {
    flex: 1;
    padding: 12px 0;
    text-align: center;
    font-size: 13px;
    font-weight: 700;
    cursor: pointer;
    border-bottom: 2px solid transparent;
    color: var(--text2);
    transition: color 0.15s;
}
.order-tab.buy.active  { color: var(--up);   border-bottom-color: var(--up); }
.order-tab.sell.active { color: var(--down); border-bottom-color: var(--down); }
.order-tab:hover { color: var(--text); }
.order-panel { padding: 16px; overflow-y: auto; flex: 1; }

.order-type-row { display: flex; gap: 6px; margin-bottom: 14px; }
.order-type-btn {
    flex: 1; padding: 8px 0; text-align: center; font-size: 13px; font-weight: 600;
    border-radius: 8px; cursor: pointer; border: 1px solid var(--border2);
    background: transparent; color: var(--text2); transition: all 0.12s;
}
.order-type-btn.sel { background: rgba(49,130,246,0.12); color: var(--blue); border-color: rgba(49,130,246,0.3); }
.order-section-label {
    font-size: 11px; color: var(--text3);
    margin-bottom: 7px; margin-top: 14px; font-weight: 600;
}
.order-input-row { display: flex; gap: 6px; margin-bottom: 8px; }
.order-input {
    flex: 1; background: var(--surface2); border: 1px solid var(--border2);
    color: var(--text); font-size: 13px; font-weight: 500;
    padding: 9px 11px; border-radius: 8px; outline: none; transition: border-color 0.15s;
}
.order-input:focus { border-color: var(--blue); }
.order-input-unit {
    background: var(--surface2); border: 1px solid var(--border2); color: var(--text3);
    font-size: 12px; font-weight: 600; padding: 9px 10px; border-radius: 8px; white-space: nowrap;
}
.pct-row { display: flex; gap: 4px; margin-bottom: 14px; }
.pct-btn {
    flex: 1; padding: 6px 0; text-align: center; font-size: 12px; font-weight: 600;
    border-radius: 6px; cursor: pointer; border: 1px solid var(--border2);
    background: transparent; color: var(--text3); transition: all 0.12s;
}
.pct-btn:hover { border-color: var(--blue); color: var(--blue); background: rgba(49,130,246,0.08); }
.order-avail { font-size: 12px; color: var(--text3); margin-bottom: 16px; }
.order-avail span { color: var(--text); font-weight: 600; }
.btn-buy {
    width: 100%; padding: 11px; border-radius: 10px; cursor: pointer;
    font-size: 14px; font-weight: 700; border: none; margin-bottom: 6px;
    background: var(--up); color: #fff; transition: opacity 0.15s;
}
.btn-buy:hover { opacity: 0.88; }
.btn-sell {
    width: 100%; padding: 11px; border-radius: 10px; cursor: pointer;
    font-size: 14px; font-weight: 700; border: none;
    background: var(--down); color: #fff; transition: opacity 0.15s;
}
.btn-sell:hover { opacity: 0.88; }

/* 호가 */
.panel-hoga {
    flex: 1;
    min-height: 80px;
    display: flex;
    flex-direction: column;
    overflow: hidden;
}
.hoga-header-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 9px 12px;
    font-size: 12px;
    font-weight: 600;
    color: var(--text3);
    border-bottom: 1px solid var(--border);
    flex-shrink: 0;
}
.hoga-body { flex: 1; overflow-y: auto; display: flex; flex-direction: column; }
.hoga-table { width: 100%; border-collapse: collapse; font-size: 12px; }
.hoga-table td { padding: 4px 10px; text-align: right; }
.hoga-table td:first-child { text-align: left; font-weight: 600; }
.hoga-bar-cell { width: 40px; padding: 3px 8px 3px 0; }
.hoga-bar { height: 100%; min-height: 10px; border-radius: 2px; opacity: 0.2; }
.ask-bar { background: var(--down); }
.bid-bar { background: var(--up); }
.hoga-skel td { color: var(--surface2); }
.hoga-ask { color: var(--down) !important; }
.hoga-bid { color: var(--up)   !important; }
.hoga-mid {
    display: flex; align-items: center; justify-content: space-between;
    padding: 6px 12px; font-size: 13px; font-weight: 800;
    border-top: 1px solid var(--border); border-bottom: 1px solid var(--border);
    background: var(--surface2); flex-shrink: 0; color: var(--text);
    letter-spacing: -0.2px;
}
.hoga-mid-change { font-size: 11px; font-weight: 500; color: var(--text3); }

/* ── CHAT PANEL ── */
.panel-chat {
    flex: 0 1 360px;
    min-width: 180px;
    max-width: 600px;
    display: flex;
    flex-direction: column;
}
.panel-title {
    padding: 13px 16px;
    font-size: 13px;
    font-weight: 700;
    color: var(--text);
    border-bottom: 1px solid var(--border);
    flex-shrink: 0;
}
.chat-messages {
    flex: 1; overflow-y: auto; padding: 12px;
    display: flex; flex-direction: column; gap: 10px;
}
.chat-empty {
    flex: 1; display: flex; align-items: center; justify-content: center;
    color: var(--text3); font-size: 13px; flex-direction: column; gap: 6px;
}
.chat-empty-icon { font-size: 28px; opacity: 0.4; }
.chat-msg { font-size: 13px; line-height: 1.55; }
.chat-msg .cm-name { color: var(--blue); font-weight: 700; margin-right: 6px; }
.chat-msg .cm-text { color: var(--text); }
.chat-input-wrap {
    display: flex; gap: 6px; padding: 10px 12px;
    border-top: 1px solid var(--border); flex-shrink: 0;
}
.chat-input {
    flex: 1; background: var(--surface2); border: 1px solid var(--border2);
    color: var(--text); font-size: 13px; padding: 8px 11px; border-radius: 8px; outline: none;
    transition: border-color 0.15s;
}
.chat-input:focus { border-color: var(--blue); }
.chat-send-btn {
    padding: 8px 13px; background: var(--blue); color: #fff;
    border: none; border-radius: 8px; font-size: 13px; font-weight: 700; cursor: pointer;
    transition: opacity 0.15s;
}
.chat-send-btn:hover { opacity: 0.85; }

/* ── SIDEBAR PANEL (전체 높이, 슬라이드) ── */
.sidebar-panel {
    width: 0;
    min-width: 0;
    overflow: hidden;
    transition: width 0.22s ease;
    flex-shrink: 0;
    background: var(--surface);
    border-left: 1px solid var(--border);
    display: flex;
    flex-direction: column;
}
.sidebar-panel.open { width: 380px; }

/* ── 아이콘 스트립 (전체 높이, 항상 표시) ── */
.sidebar-icons {
    width: 56px;
    background: var(--surface);
    border-left: 1px solid var(--border);
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 12px 0;
    gap: 2px;
    flex-shrink: 0;
}
.si-btn {
    width: 48px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 4px;
    padding: 12px 0;
    border-radius: 10px;
    cursor: pointer;
    color: var(--text3);
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.1px;
    border: none;
    background: none;
    transition: background 0.14s, color 0.14s;
    user-select: none;
}
.si-btn:hover { background: rgba(255,255,255,0.06); color: var(--text2); }
.si-btn.active { color: var(--blue); background: rgba(49,130,246,0.12); }
.si-btn svg { width: 20px; height: 20px; stroke: currentColor; fill: none; stroke-width: 1.7; stroke-linecap: round; stroke-linejoin: round; }
.si-divider { width: 28px; height: 1px; background: var(--border); margin: 6px 0; flex-shrink: 0; }

.sidebar-header {
    padding: 14px 12px 14px 16px;
    font-size: 14px;
    font-weight: 700;
    color: var(--text);
    border-bottom: 1px solid var(--border);
    flex-shrink: 0;
    display: flex;
    align-items: center;
    justify-content: space-between;
    white-space: nowrap;
}
.sidebar-header-btns { display: flex; align-items: center; gap: 4px; }
.sb-fold-btn, .sb-expand-btn {
    height: 26px; padding: 0 8px; border-radius: 6px; border: 1px solid var(--border2);
    background: transparent; color: var(--text2); font-size: 11px; font-weight: 600;
    cursor: pointer; transition: background 0.14s, color 0.14s; white-space: nowrap;
}
.sb-fold-btn:hover, .sb-expand-btn:hover { background: rgba(255,255,255,0.08); color: var(--text); }

/* ── TABS (사이드바) ── */
.sb-tabs { display: flex; border-bottom: 1px solid var(--border); flex-shrink: 0; }
.sb-tab {
    flex: 1; padding: 11px 0; text-align: center; font-size: 13px; font-weight: 600;
    color: var(--text3); cursor: pointer; border-bottom: 2px solid transparent;
    transition: color 0.12s;
}
.sb-tab.active { color: var(--text); border-bottom-color: var(--blue); }
.sb-tab:hover { color: var(--text2); }

/* ── TABLE ── */
.sb-content { flex: 1; overflow-y: auto; display: flex; flex-direction: column; }
.sb-empty {
    flex: 1; display: flex; flex-direction: column; align-items: center;
    justify-content: center; color: var(--text3); font-size: 13px; gap: 8px; padding: 20px;
}
.sb-empty-icon { font-size: 30px; opacity: 0.35; }
.sb-table { width: 100%; border-collapse: collapse; }
.sb-table th {
    padding: 8px 14px; font-size: 11px; font-weight: 600; color: var(--text3);
    text-align: left;
    position: sticky; top: 0; background: var(--surface);
    border-bottom: 1px solid var(--border); white-space: nowrap;
}
.sb-table td {
    padding: 10px 14px; font-size: 12px; font-weight: 500;
    border-bottom: 1px solid rgba(255,255,255,0.04); white-space: nowrap; color: var(--text);
}
.sb-table tr:hover td { background: rgba(255,255,255,0.03); }
</style>
</head>

<body>
<div class="app-wrapper">
<div class="page">

<!-- NAV -->
<nav>
    <span class="logo">Trade<span>Bot</span></span>
    <a href="/dashboard" class="nav-item">대시보드</a>
    <span class="nav-item active">차트</span>
    <span class="nav-item">백테스트</span>
    <span class="nav-item">자동매매</span>
    <span class="nav-item">로그</span>
    <span class="nav-item">설정</span>
    <div class="nav-right">
        <div class="nav-search">
            <svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
            <span>검색</span>
        </div>
        <button class="nav-login-btn">로그인</button>
    </div>
</nav>

<!-- PRICE HEADER -->
<div class="price-header">
    <div class="ph-left">
        <div class="ph-name-row">
            <span class="ph-name">Bitcoin</span>
            <span class="ph-ticker">BTCUSDT</span>
        </div>
        <div class="ph-price-row">
            <span class="ph-price" id="ph-price">-</span>
            <span style="width:1px;height:16px;background:var(--border2);margin:0 6px;flex-shrink:0;align-self:center;"></span>
            <span style="font-size:13px;color:var(--text3);font-weight:500;line-height:1;">전일대비</span>
            <span class="ph-change" id="ph-change-abs">-</span>
            <span class="ph-change" id="ph-change">-</span>
        </div>
    </div>
    <div class="ph-right">
        <div class="ph-group">
            <div class="ph-item"><span class="ph-label">24h 고가</span><span class="ph-value" id="ph-high">-</span></div>
            <div class="ph-item"><span class="ph-label">24h 저가</span><span class="ph-value" id="ph-low">-</span></div>
        </div>
        <div class="ph-vdivider"></div>
        <div class="ph-group">
            <div class="ph-item"><span class="ph-label">24h 거래량 (BTC)</span><span class="ph-value" id="ph-vol">-</span></div>
            <div class="ph-item"><span class="ph-label">24h 거래대금 (USDT)</span><span class="ph-value" id="ph-turnover">-</span></div>
        </div>
        <div class="ph-vdivider"></div>
        <div class="ph-group">
            <div class="ph-item"><span class="ph-label">펀딩비</span><span class="ph-value" id="ph-funding">-</span></div>
            <div class="ph-item"><span class="ph-label">미결제약정</span><span class="ph-value" id="ph-oi">-</span></div>
        </div>
        <div class="ph-vdivider"></div>
        <div class="ph-group">
            <div class="ph-item"><span class="ph-label">시가총액</span><span class="ph-value" id="ph-mktcap">-</span></div>
            <div class="ph-item"><span class="ph-label">도미넌스</span><span class="ph-value" id="ph-dominance">-</span></div>
        </div>
    </div>
    <div class="ph-actions">
        <button class="ph-like-btn">
            <svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
            관심
        </button>
    </div>
</div>

<!-- MAIN LAYOUT -->
<div class="main-layout">

    <!-- ① 차트 카드 -->
    <div class="card panel-chart" id="panel-chart">
        <!-- 툴바 (차트 카드 내부) -->
        <div class="chart-toolbar">
            <button class="tf-btn active" data-tf onclick="changeTimeframe('1min')">1분</button>
            <button class="tf-btn" data-tf onclick="changeTimeframe('3min')">3분</button>
            <button class="tf-btn" data-tf onclick="changeTimeframe('5min')">5분</button>
            <button class="tf-btn" data-tf onclick="changeTimeframe('15min')">15분</button>
            <button class="tf-btn" data-tf onclick="changeTimeframe('30min')">30분</button>
            <button class="tf-btn" data-tf onclick="changeTimeframe('1h')">1H</button>
            <button class="tf-btn" data-tf onclick="changeTimeframe('4h')">4H</button>
            <button class="tf-btn" data-tf onclick="changeTimeframe('6h')">6H</button>
            <button class="tf-btn" data-tf onclick="changeTimeframe('12h')">12H</button>
            <button class="tf-btn" data-tf onclick="changeTimeframe('1day')">1D</button>
            <button class="tf-btn" data-tf onclick="changeTimeframe('3day')">3D</button>
            <button class="tf-btn" data-tf onclick="changeTimeframe('1week')">1W</button>
            <button class="tf-btn" data-tf onclick="changeTimeframe('1month')">1M</button>
            <div class="tb-divider"></div>
            <button class="ind-btn" id="ind-ma5" onclick="toggleInd('ma5')">MA5</button>
            <button class="ind-btn" id="ind-ma20" onclick="toggleInd('ma20')">MA20</button>
            <button class="ind-btn" id="ind-ma60" onclick="toggleInd('ma60')">MA60</button>
            <button class="ind-btn" id="ind-bb" onclick="toggleInd('bb')">BB</button>
            <button class="ind-btn" id="ind-ichimoku" onclick="toggleInd('ichimoku')">일목</button>
            <button class="ind-btn" id="ind-rsi" onclick="toggleInd('rsi')">RSI</button>
            <div class="tb-divider"></div>
            <div class="settings-wrap">
                <button class="ind-btn" onclick="toggleSettingsMenu()"><span style="font-size:24px;">⚙</span></button>
                <div class="settings-menu" id="settings-menu">
                    <div class="settings-title">차트 설정</div>
                    <label class="settings-item">
                        <span class="settings-label"><span>최고 최저 가격</span></span>
                        <input type="checkbox" id="set-highlow" onchange="toggleHighLow(this.checked)" checked>
                    </label>
                    <label class="settings-item">
                        <span class="settings-label"><span>로그 스케일</span><small>변화율 기준으로 차트 보기</small></span>
                        <input type="checkbox" id="set-log" onchange="toggleLog()">
                    </label>
                    <label class="settings-item">
                        <span class="settings-label"><span>봉 카운트다운</span><small>다음 봉까지 남은 시간 표시</small></span>
                        <input type="checkbox" id="set-countdown" onchange="toggleCountdown(this.checked)" checked>
                    </label>
                </div>
            </div>
        </div>

        <!-- 차트 영역 -->
        <div id="chart-wrapper">
            <div id="hl-high" style="position:absolute;display:none;flex-direction:column;align-items:center;pointer-events:none;z-index:10;transform:translateX(-50%);">
                <span id="hl-high-val" style="font-size:12px;color:var(--up);white-space:nowrap;"></span>
                <span style="color:var(--up);font-size:12px;display:block;transform:rotate(90deg);line-height:1;">⇒</span>
            </div>
            <div id="hl-low" style="position:absolute;display:none;flex-direction:column;align-items:center;pointer-events:none;z-index:10;transform:translateX(-50%);">
                <span style="color:var(--down);font-size:12px;display:block;transform:rotate(-90deg);line-height:1;">⇒</span>
                <span id="hl-low-val" style="font-size:12px;color:var(--down);white-space:nowrap;"></span>
            </div>
            <div id="chart-container">
                <div id="ohlc-bar"><span>O: <b id="val-o">-</b></span>&nbsp; <span>H: <b id="val-h">-</b></span>&nbsp; <span>L: <b id="val-l">-</b></span>&nbsp; <span>C: <b id="val-c">-</b></span></div>
            </div>
            <div id="pane-divider"></div>
            <div id="rsi-container"></div>
        </div>
    </div>

    <!-- resize: 차트 | 주문 -->
    <div class="resize-h" id="rh-1"></div>

    <!-- ② 주문/호가 카드 -->
    <div class="panel-middle" id="panel-middle">

        <!-- 주문창 (위) -->
        <div class="card panel-order-wrap" id="panel-order-wrap">
            <div class="order-tabs">
                <div class="order-tab buy active" id="tab-buy" onclick="switchOrderTab('buy')">매수</div>
                <div class="order-tab sell" id="tab-sell" onclick="switchOrderTab('sell')">매도</div>
            </div>
            <div class="order-panel" id="panel-order">
                <div class="order-type-row">
                    <button class="order-type-btn sel" onclick="selectOrderType(this)">지정가</button>
                    <button class="order-type-btn" onclick="selectOrderType(this)">시장가</button>
                </div>
                <div class="order-section-label">가격 (USDT)</div>
                <div class="order-input-row">
                    <input class="order-input" id="trade-price-input" type="number" placeholder="0.00">
                    <span class="order-input-unit">USDT</span>
                </div>
                <div class="order-section-label">수량 (BTC)</div>
                <div class="order-input-row">
                    <input class="order-input" id="trade-qty" type="number" placeholder="0.000" step="0.001" oninput="calcAmount()">
                    <span class="order-input-unit">BTC</span>
                </div>
                <div class="pct-row">
                    <button class="pct-btn" onclick="setPercent(25)">25%</button>
                    <button class="pct-btn" onclick="setPercent(50)">50%</button>
                    <button class="pct-btn" onclick="setPercent(75)">75%</button>
                    <button class="pct-btn" onclick="setPercent(100)">최대</button>
                </div>
                <div class="order-section-label">주문금액 (USDT)</div>
                <div class="order-input-row" style="margin-bottom:14px">
                    <input class="order-input" id="trade-amount" type="number" readonly style="background:var(--bg)">
                    <span class="order-input-unit">USDT</span>
                </div>
                <div class="order-avail">가용 잔고 <span>- USDT</span></div>
                <button id="order-submit-btn" class="btn-buy" onclick="submitOrder(orderSide)">매수 주문</button>
            </div>
        </div>

        <!-- resize: 주문 | 호가 -->
        <div class="resize-v" id="rh-v"></div>

        <!-- 호가 (아래) -->
        <div class="card panel-hoga" id="panel-hoga">
            <div class="hoga-header-row">
                <span>호가</span>
                <span>수량(BTC)</span>
            </div>
            <div class="hoga-body">
                <table class="hoga-table">
                    <tbody id="hoga-asks">
                        <tr class="hoga-skel"><td class="hoga-ask">--,---.--</td><td>-.------</td><td class="hoga-bar-cell"><div class="hoga-bar ask-bar" style="width:55%"></div></td></tr>
                        <tr class="hoga-skel"><td class="hoga-ask">--,---.--</td><td>-.------</td><td class="hoga-bar-cell"><div class="hoga-bar ask-bar" style="width:40%"></div></td></tr>
                        <tr class="hoga-skel"><td class="hoga-ask">--,---.--</td><td>-.------</td><td class="hoga-bar-cell"><div class="hoga-bar ask-bar" style="width:75%"></div></td></tr>
                        <tr class="hoga-skel"><td class="hoga-ask">--,---.--</td><td>-.------</td><td class="hoga-bar-cell"><div class="hoga-bar ask-bar" style="width:30%"></div></td></tr>
                        <tr class="hoga-skel"><td class="hoga-ask">--,---.--</td><td>-.------</td><td class="hoga-bar-cell"><div class="hoga-bar ask-bar" style="width:60%"></div></td></tr>
                    </tbody>
                </table>
                <div class="hoga-mid" id="hoga-mid">
                    <span id="hoga-cur-price">-</span>
                    <span class="hoga-mid-change" id="hoga-cur-change"></span>
                </div>
                <table class="hoga-table">
                    <tbody id="hoga-bids">
                        <tr class="hoga-skel"><td class="hoga-bid">--,---.--</td><td>-.------</td><td class="hoga-bar-cell"><div class="hoga-bar bid-bar" style="width:65%"></div></td></tr>
                        <tr class="hoga-skel"><td class="hoga-bid">--,---.--</td><td>-.------</td><td class="hoga-bar-cell"><div class="hoga-bar bid-bar" style="width:45%"></div></td></tr>
                        <tr class="hoga-skel"><td class="hoga-bid">--,---.--</td><td>-.------</td><td class="hoga-bar-cell"><div class="hoga-bar bid-bar" style="width:90%"></div></td></tr>
                        <tr class="hoga-skel"><td class="hoga-bid">--,---.--</td><td>-.------</td><td class="hoga-bar-cell"><div class="hoga-bar bid-bar" style="width:35%"></div></td></tr>
                        <tr class="hoga-skel"><td class="hoga-bid">--,---.--</td><td>-.------</td><td class="hoga-bar-cell"><div class="hoga-bar bid-bar" style="width:55%"></div></td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- resize: 주문 | 댓글 -->
    <div class="resize-h" id="rh-2"></div>

    <!-- ③ 실시간 댓글 카드 -->
    <div class="card panel-chat" id="panel-chat">
        <div class="panel-title">실시간 댓글</div>
        <div class="chat-messages" id="chat-messages">
            <div class="chat-empty">
                <span class="chat-empty-icon">💬</span>
                <span>첫 댓글을 남겨보세요</span>
            </div>
        </div>
        <div class="chat-input-wrap">
            <input type="text" class="chat-input" id="chat-input" placeholder="댓글 입력...">
            <button class="chat-send-btn" onclick="sendChat()">전송</button>
        </div>
    </div>

</div><!-- /.main-layout -->
</div><!-- /.page -->

<!-- ④ 내 투자 사이드바 (전체 높이, 슬라이드) -->
<div class="sidebar-panel" id="sidebar-panel">
    <div class="sidebar-header">
        <span id="sidebar-title">내 투자</span>
        <div class="sidebar-header-btns">
            <button class="sb-fold-btn" onclick="closeSidebar()">접기</button>
            <button class="sb-expand-btn">&gt;&gt;</button>
        </div>
    </div>
    <div class="sb-tabs">
        <div class="sb-tab active" onclick="switchBpTab(this,'positions')">포지션</div>
        <div class="sb-tab" onclick="switchBpTab(this,'orders')">오더</div>
        <div class="sb-tab" onclick="switchBpTab(this,'history')">기록</div>
    </div>
    <div class="sb-content" id="tab-positions">
        <div class="sb-empty" id="bp-empty">
            <span class="sb-empty-icon">📊</span>
            <span>포지션이 없습니다.</span>
        </div>
        <table class="sb-table" id="bp-holdings-table" style="display:none">
            <thead><tr><th>코인</th><th>수량</th><th>평균단가</th><th>현재가</th><th>손익</th></tr></thead>
            <tbody id="bp-holdings-body"></tbody>
        </table>
    </div>
    <div class="sb-content" id="tab-orders" style="display:none">
        <div class="sb-empty">
            <span class="sb-empty-icon">📋</span>
            <span>오픈 오더가 없습니다.</span>
        </div>
        <table class="sb-table" id="orders-table" style="display:none">
            <thead><tr><th>코인</th><th>유형</th><th>가격</th><th>수량</th><th>취소</th></tr></thead>
            <tbody id="orders-body"></tbody>
        </table>
    </div>
    <div class="sb-content" id="tab-history" style="display:none">
        <div class="sb-empty">
            <span class="sb-empty-icon">🕐</span>
            <span>거래 기록이 없습니다.</span>
        </div>
        <table class="sb-table" id="history-table" style="display:none">
            <thead><tr><th>일시</th><th>유형</th><th>가격</th><th>수량</th><th>금액</th></tr></thead>
            <tbody id="history-body"></tbody>
        </table>
    </div>
</div>

<!-- 아이콘 스트립 (항상 표시, 전체 높이) -->
<div class="sidebar-icons">
    <button class="si-btn" id="si-invest" onclick="toggleSidebar('invest')">
        <svg viewBox="0 0 24 24"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>
        <span>내 투자</span>
    </button>
    <div class="si-divider"></div>
    <button class="si-btn" id="si-interest" onclick="toggleSidebar('interest')">
        <svg viewBox="0 0 24 24"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
        <span>관심</span>
    </button>
    <button class="si-btn" id="si-recent" onclick="toggleSidebar('recent')">
        <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
        <span>최근 본</span>
    </button>
    <button class="si-btn" id="si-live" onclick="toggleSidebar('live')">
        <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="2"/><path d="M16.24 7.76a6 6 0 0 1 0 8.49M7.76 16.24a6 6 0 0 1 0-8.49M20.49 3.51a12 12 0 0 1 0 16.97M3.51 20.49a12 12 0 0 1 0-16.97"/></svg>
        <span>실시간</span>
    </button>
</div>

</div><!-- /.app-wrapper -->

<script>
    // ── 상태 ──
    let showHighLow = true, countdownPrimitive = null;
    let currentGranularity = '1min', currentChannel = 'candle1m';
    let currentWs = null, lastPrice = 0, prevClose = 0, orderSide = 'buy';
    let walletBalance = 0, allData = [], isLoadingMore = false;
    let isLog = false, currentTfSeconds = 60, showCountdown = true;

    const TF_MAP = {
        '1min':  { channel:'candle1m',  restGran:'1min',  seconds:60 },
        '3min':  { channel:'candle3m',  restGran:'3min',  seconds:180 },
        '5min':  { channel:'candle5m',  restGran:'5min',  seconds:300 },
        '15min': { channel:'candle15m', restGran:'15min', seconds:900 },
        '30min': { channel:'candle30m', restGran:'30min', seconds:1800 },
        '1h':    { channel:'candle1H',  restGran:'1h',    seconds:3600 },
        '4h':    { channel:'candle4H',  restGran:'4h',    seconds:14400 },
        '6h':    { channel:'candle6H',  restGran:'6h',    seconds:21600 },
        '12h':   { channel:'candle12H', restGran:'12h',   seconds:43200 },
        '1day':  { channel:'candle1D',  restGran:'1day',  seconds:86400 },
        '3day':  { channel:'candle3D',  restGran:'3day',  seconds:259200 },
        '1week': { channel:'candle1W',  restGran:'1week', seconds:604800 },
        '1month':{ channel:'candle1M',  restGran:'1M',    seconds:2592000 },
    };

    // ── 차트 생성 ──
    const container = document.getElementById('chart-container');
    const chart = LightweightCharts.createChart(container, {
        autoSize: true,
        layout: { background: { color: '#16161A' }, textColor: 'rgba(255,255,255,0.5)' },
        grid: { vertLines: { color: 'rgba(255,255,255,0.04)' }, horzLines: { color: 'rgba(255,255,255,0.04)' } },
        timeScale: { timeVisible: true, secondsVisible: false, borderColor: 'rgba(255,255,255,0.07)' },
        rightPriceScale: { borderColor: 'rgba(255,255,255,0.07)' },
        crosshair: { mode: LightweightCharts.CrosshairMode.Normal, vertLine: { color: 'rgba(255,255,255,0.2)' }, horzLine: { color: 'rgba(255,255,255,0.2)' } },
    });

    const candleSeries = chart.addSeries(LightweightCharts.CandlestickSeries, {
        upColor:'#F04452', downColor:'#2563EB',
        borderUpColor:'#F04452', borderDownColor:'#2563EB',
        wickUpColor:'#F04452', wickDownColor:'#2563EB',
    });
    const ma5Series    = chart.addSeries(LightweightCharts.LineSeries, { color:'#FF9800', lineWidth:1, title:'MA5',  visible:false, priceLineVisible:false });
    const ma20Series   = chart.addSeries(LightweightCharts.LineSeries, { color:'#3182F6', lineWidth:1, title:'MA20', visible:false, priceLineVisible:false });
    const ma60Series   = chart.addSeries(LightweightCharts.LineSeries, { color:'#9C27B0', lineWidth:1, title:'MA60', visible:false, priceLineVisible:false });
    const bbUpperSeries  = chart.addSeries(LightweightCharts.LineSeries, { color:'#FF5722', lineWidth:1, lineStyle:LightweightCharts.LineStyle.Dashed, title:'BB↑', visible:false, priceLineVisible:false });
    const bbMiddleSeries = chart.addSeries(LightweightCharts.LineSeries, { color:'#FF572288', lineWidth:1, title:'BB', visible:false, priceLineVisible:false });
    const bbLowerSeries  = chart.addSeries(LightweightCharts.LineSeries, { color:'#FF5722', lineWidth:1, lineStyle:LightweightCharts.LineStyle.Dashed, title:'BB↓', visible:false, priceLineVisible:false });
    const ichiTenkanSeries = chart.addSeries(LightweightCharts.LineSeries, { color:'#E91E63', lineWidth:1, title:'전환', visible:false, priceLineVisible:false });
    const ichiKijunSeries  = chart.addSeries(LightweightCharts.LineSeries, { color:'#3182F6', lineWidth:1, title:'기준', visible:false, priceLineVisible:false });
    const ichiSpanASeries  = chart.addSeries(LightweightCharts.LineSeries, { color:'#4CAF50', lineWidth:1, title:'선행A', visible:false, priceLineVisible:false });
    const ichiSpanBSeries  = chart.addSeries(LightweightCharts.LineSeries, { color:'#FF9800', lineWidth:1, title:'선행B', visible:false, priceLineVisible:false });
    const ichiChikouSeries = chart.addSeries(LightweightCharts.LineSeries, { color:'#9E9E9E', lineWidth:1, title:'후행', visible:false, priceLineVisible:false });
    const volumeSeries = chart.addSeries(LightweightCharts.HistogramSeries, { priceFormat:{type:'volume'}, priceScaleId:'volume', priceLineVisible:false });
    chart.priceScale('volume').applyOptions({ scaleMargins:{top:0.8, bottom:0} });

    const rsiContainer = document.getElementById('rsi-container');
    const rsiChart = LightweightCharts.createChart(rsiContainer, {
        autoSize: true,
        layout: { background:{color:'#16161A'}, textColor:'rgba(255,255,255,0.5)' },
        grid: { vertLines:{color:'rgba(255,255,255,0.04)'}, horzLines:{color:'rgba(255,255,255,0.04)'} },
        timeScale: { timeVisible:true, secondsVisible:false, borderColor:'rgba(255,255,255,0.07)' },
        rightPriceScale: { borderColor:'rgba(255,255,255,0.07)', scaleMargins:{top:0.1, bottom:0.1} },
        crosshair: { mode:LightweightCharts.CrosshairMode.Normal },
    });
    const rsiSeries     = rsiChart.addSeries(LightweightCharts.LineSeries, { color:'#9C27B0', lineWidth:1, title:'RSI', priceLineVisible:false });
    const rsiOverbought = rsiChart.addSeries(LightweightCharts.LineSeries, { color:'#F0445266', lineWidth:1, lineStyle:LightweightCharts.LineStyle.Dashed, priceLineVisible:false });
    const rsiOversold   = rsiChart.addSeries(LightweightCharts.LineSeries, { color:'#2563EB66', lineWidth:1, lineStyle:LightweightCharts.LineStyle.Dashed, priceLineVisible:false });

    const indState = { ma5:false, ma20:false, ma60:false, bb:false, ichimoku:false, rsi:false };

    function setIndBtnStyle(name, on) {
        const btn = document.getElementById('ind-'+name);
        const colors = { ma5:'#FF9800', ma20:'#3182F6', ma60:'#9C27B0', bb:'#FF5722', ichimoku:'#E91E63', rsi:'#9C27B0' };
        const c = colors[name];
        if (on) { btn.style.borderColor=c; btn.style.color=c; btn.style.background=c+'18'; }
        else { btn.style.borderColor=''; btn.style.color=''; btn.style.background=''; }
    }

    function ichiAvg(arr, i, period) {
        const sl = arr.slice(Math.max(0,i-period+1), i+1);
        return (Math.max(...sl.map(d=>d.high)) + Math.min(...sl.map(d=>d.low))) / 2;
    }

    function updateAllSeries(data) {
        candleSeries.setData(data);
        window.currentDataLength = data.length;
        window.lastCandleTime = data[data.length-1].time;
        volumeSeries.setData(data.map(d=>({ time:d.time, value:d.volume, color:d.close>=d.open?'#F0445244':'#2563EB44' })));
        const ma5D=[],ma20D=[],ma60D=[];
        data.forEach((d,i)=>{
            if(i>=5)  ma5D.push({time:d.time,value:data.slice(i-5,i).reduce((s,c)=>s+c.close,0)/5});
            if(i>=20) ma20D.push({time:d.time,value:data.slice(i-20,i).reduce((s,c)=>s+c.close,0)/20});
            if(i>=60) ma60D.push({time:d.time,value:data.slice(i-60,i).reduce((s,c)=>s+c.close,0)/60});
        });
        ma5Series.setData(ma5D); ma20Series.setData(ma20D); ma60Series.setData(ma60D);
        const bbU=[],bbM=[],bbL=[];
        data.forEach((d,i)=>{
            if(i<20) return;
            const sl=data.slice(i-20,i), avg=sl.reduce((s,c)=>s+c.close,0)/20;
            const std=Math.sqrt(sl.reduce((s,c)=>s+Math.pow(c.close-avg,2),0)/20);
            bbU.push({time:d.time,value:avg+2*std}); bbM.push({time:d.time,value:avg}); bbL.push({time:d.time,value:avg-2*std});
        });
        bbUpperSeries.setData(bbU); bbMiddleSeries.setData(bbM); bbLowerSeries.setData(bbL);
        const tk=[],kj=[],sA=[],sB=[],ck=[];
        data.forEach((d,i)=>{
            if(i>=8)  tk.push({time:d.time,value:ichiAvg(data,i,9)});
            if(i>=25) { kj.push({time:d.time,value:ichiAvg(data,i,26)}); sA.push({time:d.time,value:(ichiAvg(data,i,9)+ichiAvg(data,i,26))/2}); sB.push({time:d.time,value:ichiAvg(data,i,52)}); }
            if(i+26<data.length) ck.push({time:data[i+26].time,value:d.close});
        });
        ichiTenkanSeries.setData(tk); ichiKijunSeries.setData(kj); ichiSpanASeries.setData(sA); ichiSpanBSeries.setData(sB); ichiChikouSeries.setData(ck);
        const rsiD=[];
        for(let i=14;i<data.length;i++){
            let g=0,l=0;
            for(let j=i-13;j<=i;j++){const d=data[j].close-data[j-1].close; if(d>0)g+=d; else l-=d;}
            rsiD.push({time:data[i].time,value:100-100/(1+g/(l||1))});
        }
        if(indState.rsi&&rsiD.length>0){rsiSeries.setData(rsiD);rsiOverbought.setData(rsiD.map(d=>({time:d.time,value:70})));rsiOversold.setData(rsiD.map(d=>({time:d.time,value:30})));}
        else{rsiSeries.setData([]);rsiOverbought.setData([]);rsiOversold.setData([]);}
        setTimeout(()=>{const lr=chart.timeScale().getVisibleLogicalRange();if(lr){try{rsiChart.timeScale().setVisibleLogicalRange(lr);}catch(e){}}},50);
    }

    async function loadData() {
        const res = await fetch('https://api.bitget.com/api/v2/spot/market/candles?symbol=BTCUSDT&granularity='+currentGranularity+'&limit=200').then(r=>r.json());
        if(res.code!=='00000') return;
        allData = res.data.map(item=>({ time:Math.floor(item[0]/1000), open:parseFloat(item[1]), high:parseFloat(item[2]), low:parseFloat(item[3]), close:parseFloat(item[4]), volume:parseFloat(item[5]) })).sort((a,b)=>a.time-b.time);
        updateAllSeries(allData);
    }

    let loadMoreTimer=null;
    function loadMoreData() {
        if(isLoadingMore||allData.length===0) return;
        clearTimeout(loadMoreTimer);
        loadMoreTimer=setTimeout(async()=>{
            isLoadingMore=true;
            try{
                const oldestTime=allData[0].time, endTimeMs=oldestTime*1000-1;
                const res=await fetch('https://api.bitget.com/api/v2/spot/market/candles?symbol=BTCUSDT&granularity='+currentGranularity+'&limit=200&endTime='+endTimeMs).then(r=>r.json());
                if(res.code==='00000'&&res.data&&res.data.length>0){
                    const older=res.data.map(item=>({time:Math.floor(item[0]/1000),open:parseFloat(item[1]),high:parseFloat(item[2]),low:parseFloat(item[3]),close:parseFloat(item[4]),volume:parseFloat(item[5])}))
                        .filter(d=>d.time>0&&d.open>0&&d.close>0&&d.time<oldestTime).sort((a,b)=>a.time-b.time);
                    if(older.length>0){const lr=chart.timeScale().getVisibleLogicalRange();allData=[...older,...allData];updateAllSeries(allData);if(lr)chart.timeScale().setVisibleLogicalRange({from:lr.from+older.length,to:lr.to+older.length});}
                }
            }catch(e){console.error(e);}
            isLoadingMore=false;
        },200);
    }

    function changeTimeframe(gran) {
        document.querySelectorAll('.tf-btn[data-tf]').forEach(b=>b.classList.remove('active'));
        event.target.classList.add('active');
        const lr=chart.timeScale().getVisibleLogicalRange();
        const totalBars=window.currentDataLength||200, rightOffset=lr?lr.to-totalBars:10, barCount=lr?lr.to-lr.from:50;
        currentGranularity=TF_MAP[gran].restGran; currentChannel=TF_MAP[gran].channel; currentTfSeconds=TF_MAP[gran].seconds;
        if(countdownPrimitive){
            countdownPrimitive.applyOptions({timeframeInSeconds:currentTfSeconds,
                timeLabelFormatter:currentTfSeconds>=259200
                    ?(ttcc)=>{if(ttcc.days>0)return ttcc.days+'d '+ttcc.hours+'h';if(ttcc.hours>0)return ttcc.hours+'h '+ttcc.minutes+'m';if(ttcc.minutes>0)return ttcc.minutes+'m '+ttcc.seconds+'s';return ttcc.seconds+'s';}
                    :(ttcc)=>{const t=ttcc.days*86400+ttcc.hours*3600+ttcc.minutes*60+ttcc.seconds,h=Math.floor(t/3600),m=Math.floor((t%3600)/60),s=t%60;if(currentTfSeconds>=43200)return String(h).padStart(2,'0')+':'+String(m).padStart(2,'0')+':'+String(s).padStart(2,'0');if(h>0)return String(h).padStart(2,'0')+':'+String(m).padStart(2,'0')+':'+String(s).padStart(2,'0');return String(m).padStart(2,'0')+':'+String(s).padStart(2,'0');}
            });
        }
        allData=[];
        if(currentWs){currentWs.onclose=null;if(currentWs.readyState===WebSocket.OPEN||currentWs.readyState===WebSocket.CONNECTING)currentWs.close();currentWs=null;}
        loadData().then(()=>{const nb=window.currentDataLength||200;chart.timeScale().setVisibleLogicalRange({from:nb+rightOffset-barCount,to:nb+rightOffset});connectWebSocket();});
    }

    function toggleSettingsMenu(){event.stopPropagation();document.getElementById('settings-menu').classList.toggle('open');}
    document.addEventListener('click',e=>{if(!e.target.closest('.settings-wrap'))document.getElementById('settings-menu').classList.remove('open');});
    function toggleLog(){isLog=!isLog;chart.priceScale('right').applyOptions({mode:isLog?1:0});}

    function updateHighLow() {
        if(!showHighLow) return;
        const lr=chart.timeScale().getVisibleLogicalRange();
        if(!lr||allData.length===0) return;
        const from=Math.max(0,Math.floor(lr.from)), to=Math.min(allData.length-1,Math.ceil(lr.to));
        const visible=allData.slice(from,to+1);
        if(!visible.length) return;
        let hV=-Infinity,lV=Infinity,hC,lC;
        visible.forEach(d=>{if(d.high>hV){hV=d.high;hC=d;}if(d.low<lV){lV=d.low;lC=d;}});
        const hX=chart.timeScale().timeToCoordinate(hC.time), hY=candleSeries.priceToCoordinate(hV);
        const lX=chart.timeScale().timeToCoordinate(lC.time), lY=candleSeries.priceToCoordinate(lV);
        const hEl=document.getElementById('hl-high'), lEl=document.getElementById('hl-low');
        const hPct=prevClose>0?((hV-prevClose)/prevClose*100):0;
        const lPct=prevClose>0?((lV-prevClose)/prevClose*100):0;
        if(hX!=null&&hY!=null){hEl.style.display='flex';hEl.style.left=hX+'px';hEl.style.top=(hY-48)+'px';document.getElementById('hl-high-val').textContent=hV.toLocaleString()+' USDT (전일마감기준 '+(hPct>=0?'+':'')+hPct.toFixed(2)+'%)';}
        if(lX!=null&&lY!=null){lEl.style.display='flex';lEl.style.left=lX+'px';lEl.style.top=(lY+10)+'px';document.getElementById('hl-low-val').textContent=lV.toLocaleString()+' USDT (전일마감기준 '+(lPct>=0?'+':'')+lPct.toFixed(2)+'%)';}

    }
    function toggleHighLow(enabled){showHighLow=enabled;document.getElementById('hl-high').style.display=enabled?'flex':'none';document.getElementById('hl-low').style.display=enabled?'flex':'none';if(enabled)updateHighLow();}

    function startCountdown(){
        if(!countdownPrimitive){
            countdownPrimitive=new CountdownToClose.CountdownToClose({customLastPriceLine:true,timeframeInSeconds:currentTfSeconds,
                timeLabelFormatter:(ttcc)=>{const t=ttcc.days*86400+ttcc.hours*3600+ttcc.minutes*60+ttcc.seconds,h=Math.floor(t/3600),m=Math.floor((t%3600)/60),s=t%60;if(currentTfSeconds>=43200)return String(h).padStart(2,'0')+':'+String(m).padStart(2,'0')+':'+String(s).padStart(2,'0');if(h>0)return String(h).padStart(2,'0')+':'+String(m).padStart(2,'0')+':'+String(s).padStart(2,'0');return String(m).padStart(2,'0')+':'+String(s).padStart(2,'0');}
            });
            candleSeries.applyOptions({lastValueVisible:false,priceLineVisible:false});
            candleSeries.attachPrimitive(countdownPrimitive);
        }
    }
    function toggleCountdown(enabled){showCountdown=enabled;if(enabled){startCountdown();countdownPrimitive.applyOptions({showLabels:true});}else{if(countdownPrimitive)countdownPrimitive.applyOptions({showLabels:false});candleSeries.applyOptions({lastValueVisible:true,priceLineVisible:true});}}

    function toggleInd(name){
        indState[name]=!indState[name];const on=indState[name];setIndBtnStyle(name,on);
        if(name==='ma5')ma5Series.applyOptions({visible:on});
        else if(name==='ma20')ma20Series.applyOptions({visible:on});
        else if(name==='ma60')ma60Series.applyOptions({visible:on});
        else if(name==='bb'){bbUpperSeries.applyOptions({visible:on});bbMiddleSeries.applyOptions({visible:on});bbLowerSeries.applyOptions({visible:on});}
        else if(name==='ichimoku'){[ichiTenkanSeries,ichiKijunSeries,ichiSpanASeries,ichiSpanBSeries,ichiChikouSeries].forEach(s=>s.applyOptions({visible:on}));}
        else if(name==='rsi'){rsiContainer.style.display=on?'block':'none';document.getElementById('pane-divider').style.display=on?'block':'none';if(on){setTimeout(()=>{const lr=chart.timeScale().getVisibleLogicalRange();if(lr){try{rsiChart.timeScale().setVisibleLogicalRange(lr);}catch(e){}}},50);}}
    }

    function connectWebSocket(){
        const ws=new WebSocket('wss://ws.bitget.com/v2/ws/public');currentWs=ws;
        ws.onopen=()=>{ws.send(JSON.stringify({op:'subscribe',args:[{instType:'SPOT',channel:currentChannel,instId:'BTCUSDT'}]}));setInterval(()=>ws.readyState===1&&ws.send('ping'),20000);};
        ws.onmessage=(event)=>{
            if(ws!==currentWs)return;if(event.data==='pong')return;
            const msg=JSON.parse(event.data);if(!msg.data)return;
            const item=msg.data[0];
            const bar={time:Math.floor(item[0]/1000),open:parseFloat(item[1]),high:parseFloat(item[2]),low:parseFloat(item[3]),close:parseFloat(item[4])};
            if(window.lastCandleTime&&bar.time<window.lastCandleTime)return;
            candleSeries.update(bar);updateOhlc(bar.open,bar.high,bar.low,bar.close);lastPrice=bar.close;updatePriceHeader(bar.close);updateHoldingsPnl();
        };
        ws.onclose=()=>{if(ws===currentWs)setTimeout(connectWebSocket,3000);};
    }

    function updateOhlc(o,h,l,c){document.getElementById('val-o').textContent=o.toFixed(2);document.getElementById('val-h').textContent=h.toFixed(2);document.getElementById('val-l').textContent=l.toFixed(2);document.getElementById('val-c').textContent=c.toFixed(2);}
    function updatePriceHeader(price){
        document.getElementById('ph-price').textContent=price.toLocaleString('en-US',{minimumFractionDigits:2,maximumFractionDigits:2});
        const inp=document.getElementById('trade-price-input');if(inp&&!inp.value)inp.placeholder=price.toFixed(2);
        const hm=document.getElementById('hoga-cur-price');if(hm)hm.textContent=price.toLocaleString('en-US',{minimumFractionDigits:2,maximumFractionDigits:2});
    }
    function updateHoldingsPnl(){
        const pEl=document.getElementById('holding-price'),pnlEl=document.getElementById('holding-pnl');if(!pEl||!pnlEl)return;
        const avg=parseFloat(pEl.closest('tr').children[2].textContent),cnt=parseFloat(pEl.closest('tr').children[1].textContent);
        const pnl=(lastPrice-avg)*cnt;pEl.textContent=lastPrice.toFixed(2);pnlEl.textContent=(pnl>=0?'+':'')+pnl.toFixed(2)+' USDT';pnlEl.style.color=pnl>=0?'var(--up)':'var(--down)';
    }

    async function loadTicker(){
        try{
            const res=await fetch('https://api.bitget.com/api/v2/spot/market/tickers?symbol=BTCUSDT').then(r=>r.json());
            if(res.code==='00000'&&res.data&&res.data[0]){
                const d=res.data[0],price=parseFloat(d.lastPr),chgPct=parseFloat(d.change24h)*100;
                const absChange=price*parseFloat(d.change24h)/(1+parseFloat(d.change24h));
                prevClose=price/(1+parseFloat(d.change24h));
                lastPrice=price;updatePriceHeader(price);
                document.getElementById('ph-price').className='ph-price';
                const absEl=document.getElementById('ph-change-abs');absEl.textContent=(chgPct>=0?'+':'')+absChange.toFixed(2)+' USDT';absEl.className='ph-change '+(chgPct>=0?'up':'down');
                const cEl=document.getElementById('ph-change');cEl.textContent='('+( chgPct>=0?'+':'')+chgPct.toFixed(2)+'%)';cEl.className='ph-change '+(chgPct>=0?'up':'down');
document.getElementById('ph-high').textContent=parseFloat(d.high24h).toLocaleString();
                document.getElementById('ph-low').textContent=parseFloat(d.low24h).toLocaleString();
                document.getElementById('ph-vol').textContent=parseFloat(d.baseVolume).toFixed(0)+' BTC';
            }
        }catch(e){}
    }

    chart.subscribeCrosshairMove(param=>{if(!param.time)return;const c=param.seriesData.get(candleSeries);if(!c)return;updateOhlc(c.open,c.high,c.low,c.close);});
    const chartWrapper=document.getElementById('chart-wrapper');
    chartWrapper.addEventListener('mousemove',updateHighLow);
    chartWrapper.addEventListener('mouseup',updateHighLow);
    chart.timeScale().subscribeVisibleLogicalRangeChange(lr=>{updateHighLow();if(lr){try{rsiChart.timeScale().setVisibleLogicalRange(lr);}catch(e){}if(lr.from<10)loadMoreData();}});

    // RSI pane divider
    let rsiDrag=false,rsiDragY=0,rsiDragH=0;
    document.getElementById('pane-divider').addEventListener('mousedown',e=>{rsiDrag=true;rsiDragY=e.clientY;rsiDragH=document.getElementById('rsi-container').clientHeight;document.body.style.cursor='row-resize';document.body.style.userSelect='none';});
    document.addEventListener('mousemove',e=>{if(!rsiDrag)return;document.getElementById('rsi-container').style.height=Math.max(80,Math.min(400,rsiDragH+(rsiDragY-e.clientY)))+'px';});
    document.addEventListener('mouseup',()=>{rsiDrag=false;document.body.style.cursor='';document.body.style.userSelect='';});

    // ── 패널 리사이즈 ──
    function makeHResizer(handleId, rightPanelId, minW=200, maxW=600) {
        const h=document.getElementById(handleId), rp=document.getElementById(rightPanelId);
        let drag=false,startX=0,startW=0;
        h.addEventListener('mousedown',e=>{drag=true;startX=e.clientX;startW=rp.getBoundingClientRect().width;h.classList.add('dragging');document.body.style.cursor='col-resize';document.body.style.userSelect='none';});
        document.addEventListener('mousemove',e=>{if(!drag)return;const w=Math.max(minW,Math.min(maxW,startW+(startX-e.clientX)))+'px';rp.style.width=w;rp.style.flexBasis=w;});
        document.addEventListener('mouseup',()=>{if(!drag)return;drag=false;h.classList.remove('dragging');document.body.style.cursor='';document.body.style.userSelect='';});
    }
    function makeVResizer(handleId, topId, botId) {
        const h=document.getElementById(handleId),tp=document.getElementById(topId),bp=document.getElementById(botId);
        let drag=false,startY=0,startTH=0,startBH=0;
        h.addEventListener('mousedown',e=>{drag=true;startY=e.clientY;startTH=tp.getBoundingClientRect().height;startBH=bp.getBoundingClientRect().height;h.classList.add('dragging');document.body.style.cursor='row-resize';document.body.style.userSelect='none';});
        document.addEventListener('mousemove',e=>{if(!drag)return;const d=e.clientY-startY;tp.style.flex='none';tp.style.height=Math.max(150,startTH+d)+'px';bp.style.height=Math.max(80,startBH-d)+'px';});
        document.addEventListener('mouseup',()=>{if(!drag)return;drag=false;h.classList.remove('dragging');document.body.style.cursor='';document.body.style.userSelect='';});
    }
    makeHResizer('rh-1','panel-middle', 340, 340);  // 주문/호가: 340px 고정
    makeHResizer('rh-2','panel-chat',   270, 380);  // 실시간댓글: 270~380px
    makeVResizer('rh-v','panel-order-wrap','panel-hoga');

    // ── 주문 ──
    function switchOrderTab(side){
        orderSide=side;const isBuy=side==='buy';
        document.getElementById('tab-buy').classList.toggle('active',isBuy);
        document.getElementById('tab-sell').classList.toggle('active',!isBuy);
        document.getElementById('order-submit-btn').textContent=isBuy?'매수 주문':'매도 주문';
        document.getElementById('order-submit-btn').className=isBuy?'btn-buy':'btn-sell';
        const av=document.querySelector('.order-avail span');
        if(isBuy){av.textContent=walletBalance.toFixed(2)+' USDT';}
        else{const h=parseFloat(document.getElementById('bp-holdings-body')?.querySelector('tr')?.children[1]?.textContent)||0;av.textContent=h.toFixed(6)+' BTC';}
        calcAmount();
    }
    function selectOrderType(btn){document.querySelectorAll('.order-type-btn').forEach(b=>b.classList.remove('sel'));btn.classList.add('sel');}
    function setPercent(pct){if(orderSide==='sell'){const h=parseFloat(document.getElementById('bp-holdings-body')?.querySelector('tr')?.children[1]?.textContent)||0;document.getElementById('trade-qty').value=(h*pct/100).toFixed(6);}else{document.getElementById('trade-qty').value=(walletBalance*pct/100/(lastPrice||1)).toFixed(6);}calcAmount();}
    function calcAmount(){document.getElementById('trade-amount').value=((parseFloat(document.getElementById('trade-qty').value)||0)*lastPrice).toFixed(2);}
    function submitOrder(side){
        const qty=document.getElementById('trade-qty').value;if(!qty){alert('수량을 입력하세요');return;}
        fetch('/coin/'+side,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({username:'testuser',coinCode:'BTCUSDT',orderPrice:lastPrice,orderCount:qty})})
            .then(r=>r.text()).then(result=>{if(result==='success'){alert((side==='buy'?'매수':'매도')+' 주문 완료!');loadWallet();loadHoldings();}else alert('주문 실패: '+result);}).catch(err=>alert('오류: '+err));
    }

    // ── 사이드바 슬라이드 토글 ──
    const SIDEBAR_TITLES = { invest:'내 투자현황', interest:'관심 종목', recent:'최근 본', live:'실시간' };
    let sidebarActiveTab = null;

    function toggleSidebar(tab) {
        const panel = document.getElementById('sidebar-panel');
        if (sidebarActiveTab === tab) { closeSidebar(); return; }
        sidebarActiveTab = tab;
        panel.classList.add('open');
        document.querySelectorAll('.si-btn').forEach(b => b.classList.remove('active'));
        document.getElementById('si-' + tab).classList.add('active');
        document.getElementById('sidebar-title').textContent = SIDEBAR_TITLES[tab] || tab;
    }
    function closeSidebar() {
        sidebarActiveTab = null;
        document.getElementById('sidebar-panel').classList.remove('open');
        document.querySelectorAll('.si-btn').forEach(b => b.classList.remove('active'));
    }

    // ── 사이드바 탭 ──
    function switchBpTab(el, tab){
        document.querySelectorAll('.sb-tab').forEach(t=>t.classList.remove('active'));el.classList.add('active');
        document.getElementById('tab-positions').style.display=tab==='positions'?'flex':'none';
        document.getElementById('tab-orders').style.display=tab==='orders'?'flex':'none';
        document.getElementById('tab-history').style.display=tab==='history'?'flex':'none';
    }

    // ── 지갑/보유 ──
    async function loadWallet(){const res=await fetch('/coin/wallet?username=testuser').then(r=>r.json());if(res&&res.usdtBalance!==undefined){walletBalance=res.usdtBalance;document.querySelector('.order-avail span').textContent=res.usdtBalance.toFixed(2)+' USDT';}}
    async function loadHoldings(){
        const res=await fetch('/coin/holdings?username=testuser').then(r=>r.json());
        const tbody=document.getElementById('bp-holdings-body');tbody.innerHTML='';
        if(res&&res.length>0){
            document.getElementById('bp-empty').style.display='none';document.getElementById('bp-holdings-table').style.display='table';
            let rows='';res.forEach(h=>{const pnl=(lastPrice-h.avgPrice)*h.coinCount,pc=pnl>=0?'var(--up)':'var(--down)';rows+='<tr><td>'+h.coinCode+'</td><td>'+h.coinCount.toFixed(6)+'</td><td>'+h.avgPrice.toFixed(2)+'</td><td id="holding-price">'+lastPrice.toFixed(2)+'</td><td id="holding-pnl" style="color:'+pc+'">'+(pnl>=0?'+':'')+pnl.toFixed(2)+' USDT</td></tr>';});
            tbody.innerHTML=rows;
        }else{document.getElementById('bp-empty').style.display='';document.getElementById('bp-holdings-table').style.display='none';}
    }

    // ── 댓글 ──
    function sendChat(){
        const inp=document.getElementById('chat-input'),text=inp.value.trim();if(!text)return;
        const msgs=document.getElementById('chat-messages');
        const empty=msgs.querySelector('.chat-empty');if(empty)empty.remove();
        const div=document.createElement('div');div.className='chat-msg';
        div.innerHTML='<span class="cm-name">나</span><span class="cm-text">'+text.replace(/</g,'&lt;')+'</span>';
        msgs.appendChild(div);msgs.scrollTop=msgs.scrollHeight;inp.value='';
    }
    document.getElementById('chat-input').addEventListener('keydown',e=>{if(e.key==='Enter')sendChat();});

    // ── 시작 ──
    loadTicker();loadWallet();
    loadData().then(()=>{connectWebSocket();loadHoldings();startCountdown();});
</script>
</body>
</html>
