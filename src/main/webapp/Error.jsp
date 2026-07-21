<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" isErrorPage="true" %>
<%@ page import="jakarta.servlet.http.HttpServletResponse" %>
<%
    response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>V-SPORT - Da co loi xay ra</title>
<style>
    body { font-family: -apple-system, "Segoe UI", Roboto, Arial, sans-serif; background: #f4f6f8; margin: 0; padding: 0; }
    .wrap { max-width: 480px; margin: 12vh auto 0; padding: 32px 24px; text-align: center; }
    .icon { font-size: 48px; margin-bottom: 16px; }
    h1 { font-size: 20px; color: #1f2937; margin: 0 0 12px; }
    p { color: #6b7280; font-size: 15px; line-height: 1.5; margin: 0 0 24px; }
    a.btn { display: inline-block; background: #16a34a; color: #fff; text-decoration: none; padding: 10px 24px; border-radius: 8px; font-weight: 600; }
</style>
</head>
<body>
<div class="wrap">
    <div class="icon">&#9888;</div>
    <h1>Da co loi xay ra</h1>
    <p>Chuc nang nay dang duoc cau hinh. Vui long thu lai sau.</p>
    <a class="btn" href="<%= ctx %>/customer/tai-khoan">Quay lai Tai khoan</a>
</div>
</body>
</html>
