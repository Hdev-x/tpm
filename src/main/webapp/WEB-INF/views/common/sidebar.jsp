<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!-- ================================================================
             ④ 내 투자 사이드바 (.sidebar-panel)
             - .app-wrapper 의 직계 자식으로 .page 오른쪽에 위치
             - 기본: width:0; overflow:hidden → 숨겨진 상태
             - toggleSidebar() 호출 시 width가 펼쳐지며 슬라이드 인
             - 탭: 포지션 / 오더 / 기록
        ================================================================ -->
<div class="sidebar-panel" id="sidebar-panel">

    <!-- 사이드바 헤더: 제목 + 접기/확장 버튼 -->
    <div class="sidebar-header">
        <!-- id="sidebar-title" : 어떤 탭이 열렸는지에 따라 JS에서 텍스트 변경 가능 -->
        <span id="sidebar-title">내 투자</span>
        <div class="sidebar-header-btns">
            <!-- closeSidebar() : 사이드바를 다시 width:0으로 닫음 -->
            <button class="sb-fold-btn" onclick="closeSidebar()">접기</button>
            <button class="sb-expand-btn">&gt;&gt;</button>
        </div>
    </div>

    <!-- 탭 버튼
                 - switchBpTab(this, 'positions') : 클릭한 탭에 .active, 해당 콘텐츠 표시
                 - 각 탭에 대응하는 #tab-포지션/orders/history div가 아래에 있음
            -->
    <div class="sb-tabs">
        <div class="sb-tab active" onclick="switchBpTab(this,'positions')">포지션</div>
        <div class="sb-tab" onclick="switchBpTab(this,'orders')">오더</div>
        <div class="sb-tab" onclick="switchBpTab(this,'history')">기록</div>
    </div>

    <!-- 포지션 탭 콘텐츠
                 - 보유 중인 포지션 없을 때: .sb-empty (아이콘 + 메시지)
                 - 보유 포지션 있을 때: #bp-holdings-table 테이블 표시 (display:none → block)
            -->
    <div class="sb-content" id="tab-positions">
        <div class="sb-empty" id="bp-empty">
            <span class="sb-empty-icon">📊</span>
            <span>포지션이 없습니다.</span>
        </div>
        <!-- 포지션 테이블: JS에서 포지션 데이터가 있을 때 display:'table'로 변경
                     thead: 고정 헤더, tbody: JS로 행 추가 -->
        <table class="sb-table" id="bp-holdings-table" style="display:none">
            <thead>
                <tr>
                    <th>코인</th>
                    <th>수량</th>
                    <th>평균단가</th>
                    <th>현재가</th>
                    <th>손익</th>
                </tr>
            </thead>
            <tbody id="bp-holdings-body"></tbody>
        </table>
    </div>

    <!-- 오더 탭 콘텐츠 (기본: 숨김)
                 - 현재 미체결 주문 목록 표시
            -->
    <div class="sb-content" id="tab-orders" style="display:none">
        <div class="sb-empty">
            <span class="sb-empty-icon">📋</span>
            <span>오픈 오더가 없습니다.</span>
        </div>
        <table class="sb-table" id="orders-table" style="display:none">
            <thead>
                <tr>
                    <th>코인</th>
                    <th>유형</th>
                    <th>가격</th>
                    <th>수량</th>
                    <th>취소</th>
                </tr>
            </thead>
            <tbody id="orders-body"></tbody>
        </table>
    </div>

    <!-- 기록 탭 콘텐츠 (기본: 숨김)
                 - 체결된 거래 내역 표시
            -->
    <div class="sb-content" id="tab-history" style="display:none">
        <div class="sb-empty">
            <span class="sb-empty-icon">🕐</span>
            <span>거래 기록이 없습니다.</span>
        </div>
        <table class="sb-table" id="history-table" style="display:none">
            <thead>
                <tr>
                    <th>일시</th>
                    <th>유형</th>
                    <th>가격</th>
                    <th>수량</th>
                    <th>금액</th>
                </tr>
            </thead>
            <tbody id="history-body"></tbody>
        </table>
    </div>
</div><!-- /.sidebar-panel -->