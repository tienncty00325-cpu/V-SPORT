<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

<!-- Load FontAwesome and Google Fonts for consistent styling -->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:wght@600;700&family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>

<style>
    :root {
        --primary: #AFD639; 
        --primary-hover: #AEDB2B;
        --secondary-blue: #427CF0;
        --secondary-blue-hover: #2763DB;
        --dark: #111827;
        --white: #ffffff;
        --transition: all 0.3s ease;
    }
    
    .navbar {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 0 32px;
        background: #ffffff;
        position: sticky;
        top: 0;
        z-index: 100;
        border-bottom: 1px solid #c5c9b0;
        box-sizing: border-box;
        height: 64px;
    }
    .navbar * {
        box-sizing: border-box;
    }
    .logo-container {
        text-decoration: none;
        display: flex;
        align-items: center;
        gap: 10px;
        transition: transform 0.2s ease;
    }
    .logo-container:hover {
        transform: scale(1.03);
    }
    .logo-img {
        height: 36px;
        width: 36px;
        object-fit: cover;
        border-radius: 6px;
        border: 1px solid #f0f0f0;
        box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }
    .logo-text {
        font-family: 'Poppins', sans-serif;
        font-weight: 700;
        font-size: 24px;
        text-transform: uppercase;
        letter-spacing: -0.5px;
        color: var(--dark);
    }
    .logo-text span {
        color: var(--primary);
    }
    .nav-links {
        list-style: none;
        display: flex;
        gap: 8px;
        margin: 0;
        padding: 0;
        align-items: center;
    }
    .nav-links a {
        text-decoration: none;
        color: #4b5563;
        font-family: 'Poppins', sans-serif;
        font-size: 15px;
        text-transform: none;
        letter-spacing: -0.1px;
        font-weight: 500;
        padding: 8px 16px;
        border-radius: 9999px;
        transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
        position: relative;
        display: inline-block;
    }
    .nav-links a:hover, .nav-links a.active {
        color: #000000;
    }
    .nav-links a::after {
        content: '';
        position: absolute;
        bottom: 4px;
        left: 50%;
        width: 0;
        height: 2px;
        background-color: #afd639;
        transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
        transform: translateX(-50%);
    }
    .nav-links a:hover::after, .nav-links a.active::after {
        width: 30%;
    }
    .nav-links a:hover {
        background-color: #f3f4f6;
    }
    .nav-links a.active {
        font-weight: 600;
        background-color: #f3f4f6;
    }

    /* Actions Container */
    .header-icons {
        display: flex;
        align-items: center;
        gap: 24px;
    }
    .header-icon-btn {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 32px;
        height: 32px;
        color: #0F0F0F;
        background: transparent;
        border: none;
        cursor: pointer;
        transition: transform 0.2s ease, opacity 0.2s ease;
        position: relative;
        padding: 0;
    }
    .header-icon-btn:hover {
        transform: scale(1.05);
        opacity: 0.85;
    }
    .header-icon-btn:active {
        transform: scale(0.95);
    }
    .header-icon-badge {
        position: absolute;
        bottom: -2px;
        right: -2px;
        width: 15px;
        height: 15px;
        background-color: #9dc93c;
        border-radius: 50%;
        border: 1.5px solid #ffffff;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 9px;
        font-weight: 700;
        color: #ffffff;
        line-height: 1;
    }
    
    /* Elegant dropdown menu */
    .menu-grid-container {
        position: relative;
    }
    .menu-grid-dropdown {
        position: absolute;
        right: 0;
        top: 100%;
        margin-top: 10px;
        width: 192px;
        background-color: #ffffff;
        box-shadow: 0 10px 25px rgba(0,0,0,0.1);
        border-radius: 6px;
        overflow: hidden;
        opacity: 0;
        visibility: hidden;
        transition: all 0.2s ease;
        z-index: 1000;
        border: 1px solid #f0f0f0;
    }
    .menu-grid-container:hover .menu-grid-dropdown,
    .menu-grid-dropdown.show {
        opacity: 1;
        visibility: visible;
    }
    .menu-grid-header {
        padding: 10px 16px;
        background-color: #f9f9f9;
        border-bottom: 1px solid #f0f0f0;
    }
    .menu-grid-header .title {
        font-size: 11px;
        color: #999999;
        margin: 0;
        text-transform: uppercase;
        font-weight: 600;
    }
    .menu-grid-header .name {
        font-size: 13px;
        font-weight: 700;
        color: #0F0F0F;
        margin: 2px 0 0 0;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }
    .menu-grid-item {
        display: block;
        padding: 10px 16px;
        font-size: 13.5px;
        font-weight: 600;
        color: #444444;
        text-decoration: none;
        transition: background-color 0.2s ease, color 0.2s ease;
    }
    .menu-grid-item:hover {
        background-color: #f9f9f9;
        color: #000000;
    }
    .menu-grid-item.logout {
        color: #dc2626;
        border-top: 1px solid #f0f0f0;
    }
    .menu-grid-item.logout:hover {
        background-color: #fef2f2;
    }

    /* Actions Container */
    .header-actions {
        display: flex;
        align-items: center;
        gap: 15px;
    }

    /* Shimmering Register Button */
    .btn-register-shimmer {
        position: relative;
        padding: 10px 24px;
        background: linear-gradient(135deg, var(--primary) 0%, var(--primary-hover) 100%);
        color: var(--dark) !important;
        font-size: 0.9rem;
        font-weight: 750;
        border-radius: 4px;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        overflow: hidden;
        border: none;
        box-shadow: 0 4px 15px rgba(175, 214, 57, 0.2);
        transition: all 0.4s cubic-bezier(0.25, 1, 0.5, 1);
        cursor: pointer;
    }

    .btn-register-shimmer::before {
        content: '';
        position: absolute;
        top: 0;
        left: -150%;
        width: 50%;
        height: 100%;
        background: linear-gradient(
            90deg,
            rgba(255, 255, 255, 0) 0%,
            rgba(255, 255, 255, 0.4) 50%,
            rgba(255, 255, 255, 0) 100%
        );
        transform: skewX(-20deg);
        transition: none;
    }

    .btn-register-shimmer:hover::before { animation: shimmerEffect 1.5s infinite; }
    .btn-register-shimmer:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 20px rgba(175, 214, 57, 0.4);
        color: var(--dark) !important;
    }
    .btn-register-shimmer:active {
        transform: translateY(-1px);
        box-shadow: 0 4px 12px rgba(175, 214, 57, 0.3);
    }
    .btn-register-shimmer i {
        font-size: 1rem;
        transition: transform 0.3s ease;
    }
    .btn-register-shimmer:hover i { transform: translateX(4px); }

    @keyframes shimmerEffect {
        0% { left: -150%; }
        100% { left: 150%; }
    }
    
    /* User dropdown styling to match the new green theme */
    .user-menu-container {
        position: relative;
    }
    .user-menu-btn {
        display: flex;
        align-items: center;
        gap: 9px;
        padding: 5px 10px 5px 5px;
        border-radius: 999px;
        background: #ffffff;
        border: 1px solid #e2e8f0;
        cursor: pointer;
        transition: var(--transition);
        min-height: 42px;
    }
    .user-menu-btn:hover {
        background-color: #f8fafc;
        border-color: #cbd5e1;
    }
    .user-avatar {
        width: 32px;
        height: 32px;
        border-radius: 50%;
        background-color: var(--primary);
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--dark);
        font-weight: 700;
        font-size: 12px;
    }
    .user-name {
        font-size: 13px;
        font-weight: 900;
        color: var(--dark);
    }
    .user-menu-caret {
        color: rgba(17, 24, 39, 0.6);
        transition: transform 0.2s ease;
    }
    .user-menu-btn[aria-expanded="true"] .user-menu-caret {
        transform: rotate(180deg);
    }
    .user-dropdown-menu {
        position: absolute;
        right: 0;
        top: 100%;
        margin-top: 10px;
        width: 240px;
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 16px;
        box-shadow: 0 10px 25px rgba(0,0,0,0.08);
        z-index: 110;
        overflow: hidden;
        opacity: 0;
        visibility: hidden;
        transform: translateY(10px);
        transition: var(--transition);
    }
    .user-dropdown-menu.show {
        opacity: 1;
        visibility: visible;
        transform: translateY(0);
    }
    .user-info-header {
        padding: 16px;
        background-color: rgba(175, 214, 57, 0.08);
        border-bottom: 1px solid #e2e8f0;
    }
    .user-info-name {
        display: block;
        font-size: 0.9rem;
        font-weight: 700;
        color: var(--dark);
    }
    .user-info-email {
        display: block;
        font-size: 0.75rem;
        color: var(--text-muted);
        margin-top: 2px;
    }
    .user-dropdown-item {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 12px 16px;
        color: var(--dark);
        text-decoration: none;
        font-size: 0.85rem;
        transition: var(--transition);
    }
    .user-dropdown-item:hover {
        background-color: rgba(175, 214, 57, 0.08);
        color: var(--dark);
    }
    .user-dropdown-item.logout {
        color: #ef4444;
        border-top: 1px solid #f1f5f9;
    }
    .user-dropdown-item.logout:hover {
        background-color: #fef2f2;
        color: #dc2626;
    }

    .fade-down { animation: fadeDown 1s cubic-bezier(0.1, 0.8, 0.2, 1); }
    @keyframes fadeDown {
        from { opacity: 0; transform: translateY(-30px); }
        to { opacity: 1; transform: translateY(0); }
    }

    .mobile-menu-btn {
        display: none;
        background: none;
        border: none;
        cursor: pointer;
        padding: 8px;
        color: var(--dark);
        font-size: 1.4rem;
        line-height: 1;
    }
    .mobile-nav {
        display: none;
        position: fixed;
        top: 69px;
        left: 0;
        right: 0;
        background: #ffffff;
        z-index: 99;
        box-shadow: 0 8px 24px rgba(0,0,0,0.08);
        flex-direction: column;
        padding: 12px 16px 16px;
        gap: 2px;
        border-top: 1px solid #e2e8f0;
    }
    .mobile-nav.open { display: flex; }
    .mobile-nav-link {
        display: flex;
        align-items: center;
        padding: 12px 14px;
        border-radius: 10px;
        color: var(--dark);
        text-decoration: none;
        font-size: 0.95rem;
        font-weight: 500;
        transition: var(--transition);
    }
    .mobile-nav-link:hover, .mobile-nav-link.active {
        background-color: #f1f5f9;
        color: var(--primary);
        font-weight: 600;
    }

    /* Book a Court Button */
    .btn-header-book {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        background-color: var(--secondary-blue);
        color: var(--white) !important;
        font-family: 'Poppins', sans-serif;
        font-weight: 700;
        font-size: 13px;
        letter-spacing: 1px;
        text-transform: uppercase;
        padding: 10px 24px;
        border-radius: 4px;
        transition: var(--transition);
        box-shadow: 0 4px 10px rgba(66, 124, 240, 0.2);
        text-decoration: none;
    }
    .btn-header-book:hover {
        background-color: var(--secondary-blue-hover);
        box-shadow: 0 6px 15px rgba(66, 124, 240, 0.3);
        transform: translateY(-1px);
    }

    @media (max-width: 1023px) {
        .btn-header-book {
            display: none;
        }
    }

    @media (max-width: 768px) {
        .nav-links { display: none; }
        .mobile-menu-btn { display: flex; align-items: center; justify-content: center; }
    }

    /* Side Drawer Offcanvas CSS */
    .side-drawer {
        position: fixed;
        top: 0;
        left: 0;
        width: 100vw;
        height: 100vh;
        z-index: 9999;
        visibility: hidden;
        transition: visibility 0.3s ease;
    }
    .side-drawer.open {
        visibility: visible;
    }
    .side-drawer-overlay {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-color: rgba(0, 0, 0, 0.4);
        opacity: 0;
        transition: opacity 0.3s ease;
    }
    .side-drawer.open .side-drawer-overlay {
        opacity: 1;
    }
    .side-drawer-content {
        position: absolute;
        top: 0;
        right: -360px;
        width: 360px;
        height: 100%;
        background-color: #ffffff;
        box-shadow: -5px 0 25px rgba(0,0,0,0.15);
        display: flex;
        flex-direction: column;
        transition: right 0.3s ease;
        padding: 24px;
        box-sizing: border-box;
        overflow-y: auto;
    }
    .side-drawer.open .side-drawer-content {
        right: 0;
    }
    .side-drawer-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        border-bottom: 1px solid #f0f0f0;
        padding-bottom: 16px;
        margin-bottom: 24px;
    }
    .side-drawer-close {
        background: none;
        border: none;
        font-size: 28px;
        cursor: pointer;
        color: #999999;
        transition: color 0.2s;
        line-height: 1;
    }
    .side-drawer-close:hover {
        color: #333333;
    }
    .side-drawer-section {
        margin-bottom: 30px;
    }
    .section-title {
        font-family: 'Barlow Condensed', sans-serif;
        font-size: 14px;
        font-weight: 700;
        color: #999999;
        letter-spacing: 0.1em;
        margin-bottom: 16px;
        margin-top: 0;
        text-transform: uppercase;
    }
    .user-section {
        background-color: #f9f9f9;
        padding: 16px;
        border-radius: 8px;
        border: 1px solid #f0f0f0;
    }
    .drawer-user-info {
        display: flex;
        align-items: center;
        gap: 12px;
        margin-bottom: 16px;
    }
    .avatar-circle {
        width: 44px;
        height: 44px;
        border-radius: 50%;
        background-color: #9dc93c;
        color: #ffffff;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 18px;
        font-weight: 700;
    }
    .user-details {
        flex: 1;
    }
    .user-name {
        font-weight: 600;
        color: #333333;
        margin: 0;
        font-size: 15px;
    }
    .user-role {
        font-size: 12px;
        color: #999999;
        margin: 0;
    }
    .drawer-user-actions {
        display: flex;
        flex-direction: column;
        gap: 8px;
    }
    .btn-drawer-action {
        display: flex;
        align-items: center;
        gap: 8px;
        color: #444444;
        text-decoration: none;
        font-size: 14px;
        padding: 8px;
        border-radius: 4px;
        transition: background-color 0.2s, color 0.2s;
    }
    .btn-drawer-action:hover {
        background-color: #f0f0f0;
        color: #000000;
    }
    .drawer-guest-info {
        text-align: center;
        padding: 8px 0;
    }
    .guest-msg {
        font-size: 13px;
        color: #666666;
        margin-bottom: 14px;
    }
    .btn-drawer-login {
        background-color: #333333;
        color: #ffffff;
        border: none;
        padding: 10px 20px;
        border-radius: 4px;
        font-weight: 600;
        cursor: pointer;
        font-size: 13px;
        transition: background-color 0.2s;
        width: 100%;
    }
    .btn-drawer-login:hover {
        background-color: #000000;
    }
    .drawer-link {
        display: flex;
        align-items: center;
        gap: 12px;
        color: #333333;
        text-decoration: none;
        font-size: 16px;
        font-weight: 600;
        padding: 10px 0;
        border-bottom: 1px solid #f9f9f9;
        transition: color 0.2s, padding-left 0.2s;
    }
    .drawer-link:hover {
        color: #9dc93c;
        padding-left: 6px;
    }
    .support-channels {
        display: flex;
        flex-direction: column;
        gap: 12px;
    }
    .channel-btn {
        display: flex;
        align-items: center;
        gap: 12px;
        text-decoration: none;
        color: #333333;
        font-weight: 600;
        font-size: 14px;
        padding: 12px;
        border-radius: 6px;
        border: 1px solid #e0e0e0;
        transition: all 0.2s;
    }
    .channel-btn:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 10px rgba(0,0,0,0.05);
    }
    .zalo-btn {
        background-color: #f4f8ff;
        border-color: #cbdcff;
    }
    .zalo-btn:hover {
        background-color: #e8f1ff;
        border-color: #a3c3ff;
    }
    .messenger-btn {
        background-color: #fff2f9;
        border-color: #ffdceb;
    }
    .messenger-btn:hover {
        background-color: #ffe6f3;
        border-color: #ffb8d9;
    }
    .channel-icon {
        width: 24px;
        height: 24px;
    }
    .side-drawer-footer {
        margin-top: auto;
        border-top: 1px solid #f0f0f0;
        padding-top: 20px;
    }
    .contact-item {
        display: flex;
        flex-direction: column;
        margin-bottom: 12px;
    }
    .contact-item .label {
        font-size: 12px;
        color: #999999;
    }
    .contact-item .value {
        font-size: 15px;
        font-weight: 700;
        color: #333333;
    }
</style>

<nav class="navbar fade-down">
    <a href="${pageContext.request.contextPath}/index.jsp" class="logo-container">
        <img src="${pageContext.request.contextPath}/resources/logo.png" alt="V-SPORT Logo" class="logo-img" />
        <span class="logo-text">V-SPORT<span>.</span></span>
    </a>
    <ul class="nav-links">
        <li><a href="${pageContext.request.contextPath}/index.jsp" id="nav-home">Trang chủ</a></li>
        <li><a href="${pageContext.request.contextPath}/customer/dat-san" id="nav-booking">Đặt sân</a></li>
        <li><a href="${pageContext.request.contextPath}/customer/ghep-keo" id="nav-ghepkeo">Ghép kèo</a></li>
        <li><a href="${pageContext.request.contextPath}/customer/lich-su-dat-san" id="nav-history">Lịch của tôi</a></li>
        <li><a href="${pageContext.request.contextPath}/customer/tai-khoan" id="nav-account">Tài khoản</a></li>
    </ul>
    
    <div class="header-icons">
        <!-- Cart / Booking Bag -->
        <a href="${pageContext.request.contextPath}/customer/dat-san" class="header-icon-btn">
            <svg width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
                <path d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"/>
            </svg>
            <span class="header-icon-badge">0</span>
        </a>
        
        <!-- User Icon -->
        <div class="menu-grid-container" style="position: relative;">
            <button id="header-user-btn" class="header-icon-btn" onclick="handleUserClick(this)" aria-haspopup="true" aria-expanded="false" aria-label="Tài khoản">
                <svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
                    <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/>
                    <circle cx="12" cy="7" r="4"/>
                </svg>
            </button>
            <c:if test="${user != null}">
                <div id="user-profile-dropdown" class="menu-grid-dropdown">
                    <div class="menu-grid-header">
                        <p class="title">Tài khoản</p>
                        <p class="name">
                            <c:choose>
                                <c:when test="${not empty user.fullName}">
                                    ${fn:escapeXml(user.fullName)}
                                </c:when>
                                <c:otherwise>
                                    ${fn:escapeXml(user.username)}
                                </c:otherwise>
                            </c:choose>
                        </p>
                    </div>
                    <a href="${pageContext.request.contextPath}/customer/tai-khoan" class="menu-grid-item">Tài khoản</a>
                    <a href="${pageContext.request.contextPath}/customer/lich-su-dat-san" class="menu-grid-item">Lịch của tôi</a>
                    <a href="${pageContext.request.contextPath}/customer/ghep-keo" class="menu-grid-item">Ghép kèo</a>
                    <a href="${pageContext.request.contextPath}/logout" class="menu-grid-item logout">Đăng xuất</a>
                </div>
            </c:if>
        </div>
        
        <!-- Search Icon -->
        <button class="header-icon-btn">
            <svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
                <circle cx="11" cy="11" r="8"></circle>
                <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
            </svg>
        </button>
        
        <!-- Nine-dots grid -->
        <button onclick="openSideDrawer()" class="header-icon-btn">
            <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
                <rect x="3" y="3" width="4" height="4" rx="0.5" />
                <rect x="10" y="3" width="4" height="4" rx="0.5" />
                <rect x="17" y="3" width="4" height="4" rx="0.5" />
                <rect x="3" y="10" width="4" height="4" rx="0.5" />
                <rect x="10" y="10" width="4" height="4" rx="0.5" />
                <rect x="17" y="10" width="4" height="4" rx="0.5" />
                <rect x="3" y="17" width="4" height="4" rx="0.5" />
                <rect x="10" y="17" width="4" height="4" rx="0.5" />
                <rect x="17" y="17" width="4" height="4" rx="0.5" />
            </svg>
        </button>
        
        <!-- Mobile Hamburger Button -->
        <button id="mobileNavBtn" class="mobile-menu-btn" aria-label="Mở menu">
            <i class="fa-solid fa-bars"></i>
        </button>
    </div>
</nav>

<!-- Mobile Navigation Drawer -->
<div id="mobileNav" class="mobile-nav">
    <a href="${pageContext.request.contextPath}/index.jsp" class="mobile-nav-link" id="mnav-home"><i class="fa-solid fa-house" style="width:20px;margin-right:10px;color:var(--primary)"></i>Trang Chủ</a>
    <a href="${pageContext.request.contextPath}/customer/dat-san" class="mobile-nav-link" id="mnav-booking"><i class="fa-solid fa-magnifying-glass" style="width:20px;margin-right:10px;color:var(--primary)"></i>Đặt sân</a>
    <a href="${pageContext.request.contextPath}/customer/ghep-keo" class="mobile-nav-link" id="mnav-ghepkeo"><i class="fa-solid fa-people-group" style="width:20px;margin-right:10px;color:var(--primary)"></i>Ghép kèo</a>
    <a href="${pageContext.request.contextPath}/customer/lich-su-dat-san" class="mobile-nav-link" id="mnav-history"><i class="fa-solid fa-calendar-check" style="width:20px;margin-right:10px;color:var(--primary)"></i>Lịch của tôi</a>
    <a href="${pageContext.request.contextPath}/customer/tai-khoan" class="mobile-nav-link" id="mnav-account"><i class="fa-solid fa-user" style="width:20px;margin-right:10px;color:var(--primary)"></i>Tài khoản</a>
</div>

<script>
    // User Dropdown Toggle
    (function() {
        const userMenuBtn = document.getElementById('header-user-btn');
        const userDropdown = document.getElementById('user-profile-dropdown');
        
        window.handleUserClick = function(btn) {
            const isLoggedIn = ${user != null ? "true" : "false"};
            if (isLoggedIn) {
                if (userDropdown) {
                    userDropdown.classList.toggle('show');
                    if (userMenuBtn) userMenuBtn.setAttribute('aria-expanded', userDropdown.classList.contains('show') ? 'true' : 'false');
                }
            } else {
                window.location.href = "${pageContext.request.contextPath}/dangnhap";
            }
        };

        if (userMenuBtn && userDropdown) {
            document.addEventListener('click', (e) => {
                if (!userDropdown.contains(e.target) && !userMenuBtn.contains(e.target)) {
                    userDropdown.classList.remove('show');
                    userMenuBtn.setAttribute('aria-expanded', 'false');
                }
            });

            document.addEventListener('keydown', (e) => {
                if (e.key === 'Escape') {
                    userDropdown.classList.remove('show');
                    userMenuBtn.setAttribute('aria-expanded', 'false');
                }
            });
        }
        
        // Mobile nav toggle
        const mobileNavBtn = document.getElementById('mobileNavBtn');
        const mobileNav = document.getElementById('mobileNav');
        if (mobileNavBtn && mobileNav) {
            mobileNavBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                mobileNav.classList.toggle('open');
                mobileNavBtn.querySelector('i').className =
                    mobileNav.classList.contains('open') ? 'fa-solid fa-xmark' : 'fa-solid fa-bars';
            });
            document.addEventListener('click', (e) => {
                if (!mobileNav.contains(e.target) && !mobileNavBtn.contains(e.target)) {
                    mobileNav.classList.remove('open');
                    mobileNavBtn.querySelector('i').className = 'fa-bars';
                }
            });
            mobileNav.querySelectorAll('a').forEach(a => {
                a.addEventListener('click', () => {
                    mobileNav.classList.remove('open');
                    mobileNavBtn.querySelector('i').className = 'fa-solid fa-bars';
                });
            });
        }

        // Auto active link based on URL
        const currentPath = window.location.pathname;

        function pickActiveId(prefixes) {
            if (currentPath.includes('/customer/ghep-keo')) return prefixes.ghepkeo;
            if (currentPath.includes('/customer/lich-su-dat-san')) return prefixes.history;
            if (currentPath.includes('/customer/tai-khoan')) return prefixes.account;
            if (currentPath.includes('dat-san') || currentPath.includes('ChiTietSan')) return prefixes.booking;
            if (currentPath.endsWith('index.jsp') || currentPath.endsWith('/')) return prefixes.home;
            return null;
        }

        const desktopActiveId = pickActiveId({ ghepkeo: 'nav-ghepkeo', history: 'nav-history', account: 'nav-account', booking: 'nav-booking', home: 'nav-home' });
        if (desktopActiveId) {
            const el = document.getElementById(desktopActiveId);
            if (el) el.classList.add('active');
        }

        const mobileActiveId = pickActiveId({ ghepkeo: 'mnav-ghepkeo', history: 'mnav-history', account: 'mnav-account', booking: 'mnav-booking', home: 'mnav-home' });
        if (mobileActiveId) {
            const el = document.getElementById(mobileActiveId);
            if (el) el.classList.add('active');
        }
    })();
</script>

<!-- Right Sidebar Drawer (Offcanvas Menu) -->
<div id="side-drawer" class="side-drawer">
    <div class="side-drawer-overlay" onclick="closeSideDrawer()"></div>
    <div class="side-drawer-content">
        <!-- Close button & Logo -->
        <div class="side-drawer-header">
            <a href="${pageContext.request.contextPath}/index.jsp" class="side-drawer-logo" style="display: flex; align-items: center; gap: 10px; text-decoration: none;">
                <img alt="V-SPORT Logo" style="height: 36px; border-radius: 4px;" src="${pageContext.request.contextPath}/resources/logo.png"/>
                <span style="font-family: 'Poppins', sans-serif; font-weight: 700; font-size: 20px; text-transform: uppercase; color: #111827; letter-spacing: -0.5px;">V-SPORT<span style="color: #afd639;">.</span></span>
            </a>
            <button class="side-drawer-close" onclick="closeSideDrawer()">&times;</button>
        </div>

        <!-- User Profile Section -->
        <div class="side-drawer-section user-section">
            <c:choose>
                <c:when test="${user != null}">
                    <div class="drawer-user-info">
                        <div class="avatar-circle">
                            <c:choose>
                                <c:when test="${not empty user.fullName}">
                                    ${user.fullName.substring(0,1).toUpperCase()}
                                </c:when>
                                <c:otherwise>
                                    ${user.username.substring(0,1).toUpperCase()}
                                </c:otherwise>
                            </c:choose>
                        </div>
                        <div class="user-details">
                            <p class="user-name">
                                <c:choose>
                                    <c:when test="${not empty user.fullName}">
                                        ${user.fullName}
                                    </c:when>
                                    <c:otherwise>
                                        ${user.username}
                                    </c:otherwise>
                                </c:choose>
                            </p>
                            <p class="user-role">Thành viên</p>
                        </div>
                    </div>
                    <div class="drawer-user-actions">
                        <a href="${pageContext.request.contextPath}/customer/tai-khoan" class="btn-drawer-action"><i class="fa-regular fa-user"></i> Chỉnh sửa Profile</a>
                        <a href="${pageContext.request.contextPath}/customer/lich-su-dat-san" class="btn-drawer-action"><i class="fa-regular fa-calendar-check"></i> Lịch của tôi</a>
                        <a href="${pageContext.request.contextPath}/customer/ghep-keo" class="btn-drawer-action"><i class="fa-solid fa-people-group"></i> Ghép kèo</a>
                    </div>
                </c:when>
                <c:otherwise>
                    <div class="drawer-guest-info">
                        <p class="guest-msg">Đăng nhập để xem lịch sử đặt sân và quản lý hồ sơ của bạn.</p>
                        <button class="btn-drawer-login" onclick="closeSideDrawer(); window.location.href = '${pageContext.request.contextPath}/dangnhap'">Đăng Nhập Ngay</button>
                    </div>
                </c:otherwise>
            </c:choose>
        </div>

        <!-- Navigation Menu -->
        <div class="side-drawer-section links-section">
            <h4 class="section-title">TIỆN ÍCH HỆ THỐNG</h4>
            <a href="${pageContext.request.contextPath}/index.jsp" class="drawer-link"><i class="fa-solid fa-house"></i> Trang Chủ</a>
            <a href="${pageContext.request.contextPath}/customer/dat-san" class="drawer-link"><i class="fa-solid fa-calendar-days"></i> Tìm Sân Đặt Lịch</a>
            <a href="${pageContext.request.contextPath}/customer/ghep-keo" class="drawer-link"><i class="fa-solid fa-people-group"></i> Ghép Kèo</a>
            <a href="${pageContext.request.contextPath}/index.jsp#pricing" class="drawer-link"><i class="fa-solid fa-tags"></i> Bảng Giá Dịch Vụ</a>
        </div>

        <!-- Support Channels (Zalo & Messenger) -->
        <div class="side-drawer-section support-section">
            <h4 class="section-title">HỖ TRỢ TRỰC TUYẾN</h4>
            <div class="support-channels">
                <a href="https://zalo.me/0987654321" target="_blank" class="channel-btn zalo-btn">
                    <img src="https://upload.wikimedia.org/wikipedia/commons/9/91/Icon_of_Zalo.svg" alt="Zalo" class="channel-icon" />
                    <span>Hỗ trợ qua Zalo</span>
                </a>
                <a href="https://m.me/vsport" target="_blank" class="channel-btn messenger-btn">
                    <img src="https://upload.wikimedia.org/wikipedia/commons/b/be/Facebook_Messenger_logo_2020.svg" alt="Messenger" class="channel-icon" />
                    <span>Hỗ trợ qua Messenger</span>
                </a>
            </div>
        </div>

        <!-- Footer / Contact Info -->
        <div class="side-drawer-footer">
            <div class="contact-item">
                <span class="label">Hotline hỗ trợ:</span>
                <span class="value">1900 1234</span>
            </div>
            <div class="contact-item">
                <span class="label">Email liên hệ:</span>
                <span class="value">support@vsport.vn</span>
            </div>
        </div>
    </div>
</div>

<script>
    window.openSideDrawer = function() {
        const drawer = document.getElementById('side-drawer');
        if (drawer) drawer.classList.add('open');
    };
    window.closeSideDrawer = function() {
        const drawer = document.getElementById('side-drawer');
        if (drawer) drawer.classList.remove('open');
    };
</script>
