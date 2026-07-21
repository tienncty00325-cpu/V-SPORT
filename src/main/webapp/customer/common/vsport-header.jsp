<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    boolean isLoggedIn = session.getAttribute("user") != null;
    org.example.model.TaiKhoan user = isLoggedIn ? (org.example.model.TaiKhoan) session.getAttribute("user") : null;
    String displayName = "Tài khoản";
    String rolePath = "/";
    if (isLoggedIn) {
        displayName = (user.getFullName() != null && !user.getFullName().trim().isEmpty()) ? user.getFullName() : "Khách hàng";
        rolePath = org.example.util.RoleRedirectUtil.getHomePathByRoleId(user.getRoleId());
    }
    String ctxPath = request.getContextPath();
%>
<!-- V-SPORT New Theme Styles -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800;900&family=Montserrat:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="<%= ctxPath %>/assets/css/vsport-customer.css">

<!-- Toast Notification Container -->
<div id="toast-container"></div>

<!-- Top Contact Bar -->
<div class="top-bar">
    <div class="container">
        <div class="top-bar-left">
            <span><i class="fa-solid fa-phone"></i> Hỗ trợ: 1900 1234</span>
            <span class="divider">|</span>
            <span><i class="fa-solid fa-envelope"></i> contact@v-sport.vn</span>
        </div>
        <div class="top-bar-right">
            <a href="#">Tải Ứng Dụng</a>
            <span class="divider">|</span>
            <a href="#">Trở thành đối tác</a>
            <span class="divider">|</span>
            <% if (isLoggedIn) { %>
                <div class="user-profile-menu" style="display:inline-flex; align-items:center; gap: 8px;">
                    <i class="fa-solid fa-circle-user" style="font-size: 16px; color: var(--accent-red, #ff2433);"></i>
                    <a href="<%= ctxPath %><%= rolePath %>" style="font-weight: 600;"><%= displayName %></a>
                    <span class="divider">|</span>
                    <a href="<%= ctxPath %>/logout">Đăng xuất</a>
                </div>
            <% } else { %>
                <a href="javascript:void(0)" onclick="openAuthModal('login')">Đăng nhập</a>
                <a href="javascript:void(0)" onclick="openAuthModal('register')" class="btn-register-topbar">Đăng ký</a>
            <% } %>
        </div>
    </div>
</div>

<!-- Main Navbar -->
<header class="navbar">
    <div class="container">
        <div class="logo">
            <a href="<%= ctxPath %>/">
                V<span class="logo-icon"><i class="fa-solid fa-bolt text-red" style="margin: 0 5px;"></i></span>SPORT
            </a>
        </div>
        <nav class="main-menu">
            <ul>
                <li class="<%= request.getRequestURI().endsWith("/index.jsp") || request.getRequestURI().equals(ctxPath + "/") ? "active" : "" %>"><a href="<%= ctxPath %>/">TRANG CHỦ</a></li>
                <li class="<%= request.getRequestURI().contains("/dat-san") ? "active" : "" %>"><a href="<%= ctxPath %>/customer/dat-san">TÌM SÂN</a></li>
                <li class="<%= request.getRequestURI().contains("/ghep-keo") || request.getRequestURI().contains("/doi-nhom") ? "active" : "" %>"><a href="<%= ctxPath %>/customer/ghep-keo">GHÉP TRẬN</a></li>
                <li class="<%= request.getRequestURI().contains("/tai-khoan") || request.getRequestURI().contains("/ho-so") || request.getRequestURI().contains("/lich-su") ? "active" : "" %>"><a href="<%= ctxPath %>/customer/tai-khoan">TÀI KHOẢN</a></li>
                <li><a href="#">BẢNG GIÁ</a></li>
                <li><a href="#">LIÊN HỆ</a></li>
            </ul>
        </nav>
        <div class="nav-actions">
            <a href="<%= ctxPath %>/customer/dat-san" class="action-icon"><i class="fa-solid fa-magnifying-glass"></i></a>
            <a href="<%= ctxPath %>/customer/lich-su-dat-san" class="action-icon cart-icon">
                <i class="fa-solid fa-calendar-check"></i>
            </a>
            <a href="#" class="action-icon menu-icon"><i class="fa-solid fa-bars"></i></a>
        </div>
    </div>
</header>
