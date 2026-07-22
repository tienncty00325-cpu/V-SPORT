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
<link rel="stylesheet" href="<%= ctxPath %>/assets/css/vsport-customer.css?v=2">

<!-- Toast Notification Container -->
<div id="toast-container"></div>

<style>
    :root {
        --primary-blue: #2563eb;
    }
    
    .new-header {
        background-color: #ffffff;
        padding: 12px 0;
        position: sticky;
        top: 0;
        z-index: 1000;
        box-shadow: 0 1px 10px rgba(0,0,0,0.05);
        font-family: 'Poppins', sans-serif;
    }

    .new-header .container {
        max-width: 1440px;
        width: 100%;
        margin: 0 auto;
        padding: 0 20px;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .new-header .logo a {
        display: flex;
        align-items: center;
        gap: 10px;
        text-decoration: none;
        color: #111;
    }

    .new-header .logo-icon {
        background-color: var(--primary-blue);
        color: white;
        width: 32px;
        height: 32px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 600;
        font-size: 16px;
    }

    .new-header .logo-text {
        font-size: 20px;
        font-weight: 700;
    }

    .new-header .main-menu ul {
        display: flex;
        gap: 24px;
        list-style: none;
        margin: 0;
        padding: 0;
    }

    .new-header .main-menu a {
        color: #4b5563;
        text-decoration: none;
        font-weight: 500;
        font-size: 14px;
        text-transform: none !important;
        transition: color 0.2s;
    }

    .new-header .main-menu a:hover {
        color: var(--primary-blue);
    }
    
    .new-header .header-left {
        display: flex;
        align-items: center;
        gap: 40px;
    }

    .new-header .nav-actions {
        display: flex;
        align-items: center;
        gap: 20px;
    }

    .new-header .location {
        display: flex;
        align-items: center;
        gap: 6px;
        color: #4b5563;
        font-size: 14px;
        font-weight: 500;
    }

    .new-header .location i {
        color: var(--primary-blue);
    }

    .new-header .action-icon {
        color: #4b5563;
        font-size: 18px;
        text-decoration: none;
        transition: color 0.2s;
        display: flex;
        align-items: center;
    }

    .new-header .action-icon:hover {
        color: var(--primary-blue);
    }

    .new-header .notification-icon {
        position: relative;
        color: #4b5563;
        font-size: 18px;
        cursor: pointer;
        transition: color 0.2s;
        display: flex;
        align-items: center;
    }

    .new-header .notification-icon:hover {
        color: var(--primary-blue);
    }

    .new-header .notification-dot {
        position: absolute;
        top: 0px;
        right: 0px;
        width: 8px;
        height: 8px;
        background-color: #f97316;
        border-radius: 50%;
        border: 1px solid #fff;
    }

    .new-header .user-profile {
        display: flex;
        align-items: center;
        gap: 8px;
        cursor: pointer;
        text-decoration: none;
    }

    .new-header .user-profile img {
        width: 32px;
        height: 32px;
        border-radius: 50%;
        object-fit: cover;
    }

    .new-header .user-profile span {
        font-weight: 600;
        font-size: 14px;
        color: #111827;
    }

    .new-header .btn-primary {
        background-color: var(--primary-blue);
        color: white;
        padding: 8px 16px;
        border-radius: 8px;
        text-decoration: none;
        font-weight: 500;
        font-size: 14px;
        border: none;
        transition: background-color 0.2s;
    }

    .new-header .btn-primary:hover {
        background-color: #1d4ed8;
        color: white;
    }
</style>

<!-- Main Navbar -->
<header class="new-header">
    <div class="container">
        <div class="header-left">
            <div class="logo">
                <a href="<%= ctxPath %>/">
                    <div class="logo-icon">S</div>
                    <span class="logo-text">Sânzy</span>
                </a>
            </div>
            
            <nav class="main-menu">
                <ul>
                    <li><a href="<%= ctxPath %>/">Khám phá</a></li>
                    <li><a href="<%= ctxPath %>/customer/tim-kiem">Tìm sân</a></li>
                    <li><a href="<%= ctxPath %>/customer/ghep-keo">Gắn bạn</a></li>
                    <li><a href="#">Cộng đồng</a></li>
                    <li><a href="#">Ưu đãi</a></li>
                </ul>
            </nav>
        </div>
        
        <div class="nav-actions">
            <div class="location">
                <i class="fa-solid fa-location-dot"></i> Hà Nội
            </div>
            
            <a href="#" class="action-icon"><i class="fa-regular fa-heart"></i></a>
            
            <div class="notification-icon">
                <i class="fa-regular fa-bell"></i>
                <span class="notification-dot"></span>
            </div>
            
            <% if (isLoggedIn) { %>
                <a href="<%= ctxPath %><%= rolePath %>" class="user-profile">
                    <img src="<%= ctxPath %>/assets/images/default-avatar.png" alt="Avatar" onerror="this.src='https://ui-avatars.com/api/?name=<%= displayName %>&background=random'">
                    <span><%= displayName %></span>
                    <i class="fa-solid fa-chevron-down" style="font-size: 10px; color: #6b7280;"></i>
                </a>
            <% } else { %>
                <div class="user-profile" onclick="toggleAuthDropdown('login')">
                    <img src="https://ui-avatars.com/api/?name=Hiền&background=f3f4f6&color=333" alt="Avatar">
                    <span>Hiền</span>
                    <i class="fa-solid fa-chevron-down" style="font-size: 10px; color: #6b7280;"></i>
                </div>
                <div class="auth-dropdown-wrapper" id="authDropdownWrapper" style="display:none;">
                    <jsp:include page="/auth/AuthDropdown.jsp" />
                </div>
            <% } %>
            
            <a href="<%= ctxPath %>/customer/dat-san" class="btn-primary">Đặt sân</a>
        </div>
    </div>
</header>
