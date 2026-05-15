<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>
	<script type="text/javascript">
	const options = {method: 'GET', headers: {accept: 'application/json'}};

	fetch('https://api.bithumb.com/v1/market/all?isDetails=false', options)
	  .then(response => response.json())
	  .then(response => console.log(response))
	  .catch(err => console.error(err));
	</script>
</body>
</html>