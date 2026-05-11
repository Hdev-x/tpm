<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>	
<table border="1">
    <thead>
        <tr>
            <th>종목명</th>
            <th>보유수량</th>
            <th>매수단가</th>
            <th>현재가</th>
            <th>평가금액</th>
            <th>수익률</th>
        </tr>
    </thead>
    <tbody>
        <tr th:each="asset : ${assetList}">
            <td th:text="${asset.stockName}">삼성전자</td>
            <td th:text="${asset.quantity}">10</td>
            <td th:text="${#numbers.formatInteger(asset.purchasePrice, 3, 'COMMA')}">70,000</td>
            <td th:text="${#numbers.formatInteger(asset.currentPrice, 3, 'COMMA')}">75,000</td>
            <td th:text="${#numbers.formatInteger(asset.evaluationAmount, 3, 'COMMA')}">750,000</td>
            <td th:text="${asset.profitRate + '%'}" 
                th:style="${asset.profitRate > 0 ? 'color:red' : 'color:blue'}">5.5%</td>
        </tr>
    </tbody>
</table>


</body>
</html>