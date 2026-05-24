<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%!
    private String orderValue(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
%>
<%
    String orderMarket = orderValue((String) request.getAttribute("orderMarket"), "stock");
    String orderPriceUnit = orderValue((String) request.getAttribute("orderPriceUnit"), "원");
    String orderQtyUnit = orderValue((String) request.getAttribute("orderQtyUnit"), "주");
    String orderQtyLabel = orderValue((String) request.getAttribute("orderQtyLabel"), "수량 (" + orderQtyUnit + ")");
    String orderQtyStep = orderValue((String) request.getAttribute("orderQtyStep"), "1");
    String orderPricePlaceholder = orderValue((String) request.getAttribute("orderPricePlaceholder"), "가격 입력");
    String orderQtyPlaceholder = orderValue((String) request.getAttribute("orderQtyPlaceholder"), "0");
    String orderAmountUnit = orderValue((String) request.getAttribute("orderAmountUnit"), orderPriceUnit);
    String orderAvailText = orderValue((String) request.getAttribute("orderAvailText"), "- " + orderPriceUnit);
    String orderQtyUnitId = orderValue((String) request.getAttribute("orderQtyUnitId"), "");
    String orderQtyUnitIdAttr = orderQtyUnitId.isBlank() ? "" : " id=\"" + orderQtyUnitId + "\"";
%>
<div class="card panel-order-wrap market-order-panel market-order-panel-<%= orderMarket %>" id="panel-order-wrap">
    <!-- 차트와 커뮤니티가 같은 주문 DOM을 공유하므로 주문 JS는 페이지별 데이터만 다르게 주입받는다. -->
    <div class="order-tabs">
        <div class="order-tab buy active" id="tab-buy" onclick="switchOrderTab('buy')">매수</div>
        <div class="order-tab sell" id="tab-sell" onclick="switchOrderTab('sell')">매도</div>
    </div>

    <div class="order-panel" id="panel-order">
        <div class="order-type-row">
            <button class="order-type-btn sel" onclick="selectOrderType(this)">지정가</button>
            <button class="order-type-btn" onclick="selectOrderType(this)">시장가</button>
        </div>

        <div class="order-section-label">가격 (<%= orderPriceUnit %>)</div>
        <div class="order-input-row">
            <input class="order-input" id="trade-price-input" type="number"
                   placeholder="<%= orderPricePlaceholder %>" oninput="calcAmount()">
            <span class="order-input-unit"><%= orderPriceUnit %></span>
        </div>

        <div class="order-section-label"><%= orderQtyLabel %></div>
        <div class="order-input-row">
            <input class="order-input" id="trade-qty" type="number"
                   placeholder="<%= orderQtyPlaceholder %>" step="<%= orderQtyStep %>" oninput="calcAmount()">
            <div class="pct-drop-wrap" id="pct-drop-wrap">
                <div class="pct-drop-menu" id="pct-drop-menu" style="display:none;">
                    <div class="pct-drop-item" onclick="setPercent(25)">25%</div>
                    <div class="pct-drop-item" onclick="setPercent(50)">50%</div>
                    <div class="pct-drop-item" onclick="setPercent(75)">75%</div>
                    <div class="pct-drop-item" onclick="setPercent(100)">최대</div>
                </div>
                <button class="pct-drop-btn" onclick="togglePctDrop()">
                    <span id="pct-drop-label">비율</span>
                    <svg width="10" height="10" viewBox="0 0 10 10"><path d="M2 3.5l3 3 3-3" stroke="currentColor" stroke-width="1.4" fill="none" stroke-linecap="round"/></svg>
                </button>
            </div>
            <% if (!orderQtyUnitId.isBlank()) { %>
                <span class="order-input-unit order-qty-unit"<%= orderQtyUnitIdAttr %>><%= orderQtyUnit %></span>
            <% } %>
        </div>

        <div class="order-info-row">
            <span class="order-avail">가용 <span id="avail-balance"><%= orderAvailText %></span></span>
            <span class="order-amount-label">주문금액 <span id="trade-amount">0</span> <%= orderAmountUnit %></span>
        </div>

        <button id="order-submit-btn" class="btn-buy" onclick="submitOrder(orderSide)">매수 주문</button>
    </div>
</div>
