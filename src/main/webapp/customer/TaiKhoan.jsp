<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<jsp:include page="/common/xtra-head.jsp" />
<style>
/* Add the specific styles for Account page here, inheriting from XtraMarket theme */
.account-wrapper {
    padding: 60px 0;
    background-color: var(--background);
}
.account-container {
    display: flex;
    gap: 30px;
    width: 100%;
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 20px;
}
.account-sidebar {
    width: 280px;
    flex-shrink: 0;
}
.account-main {
    flex: 1;
    min-width: 0;
}
.profile-card {
    background: var(--surface);
    border-radius: var(--radius-medium);
    padding: 25px;
    text-align: center;
    box-shadow: var(--shadow-small);
    margin-bottom: 20px;
}
.profile-avatar {
    width: 80px;
    height: 80px;
    border-radius: 50%;
    background: var(--primary);
    color: var(--surface);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 32px;
    font-weight: 700;
    margin: 0 auto 15px;
}
.profile-name {
    font-size: 20px;
    font-weight: 700;
    color: var(--navy);
    margin-bottom: 5px;
}
.profile-email {
    font-size: 14px;
    color: var(--muted-text);
    margin-bottom: 15px;
}
.profile-rep {
    display: inline-block;
    padding: 5px 12px;
    background: rgba(1, 226, 129, 0.1);
    color: var(--primary-hover);
    border-radius: 50px;
    font-size: 13px;
    font-weight: 600;
    margin-bottom: 20px;
}
.menu-card {
    background: var(--surface);
    border-radius: var(--radius-medium);
    box-shadow: var(--shadow-small);
    overflow: hidden;
}
.menu-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 15px 20px;
    color: var(--body-text);
    font-weight: 500;
    border-left: 3px solid transparent;
    transition: var(--transition);
}
.menu-item:hover {
    background: var(--background);
    color: var(--primary-hover);
}
.menu-item.active {
    background: rgba(1, 226, 129, 0.05);
    color: var(--primary-hover);
    border-left-color: var(--primary);
    font-weight: 600;
}
.menu-item i {
    font-size: 18px;
    width: 20px;
    text-align: center;
}
.menu-item.danger {
    color: var(--danger);
}
.menu-item.danger:hover {
    background: rgba(255, 71, 87, 0.05);
    color: var(--danger);
}
.breadcrumb {
    font-size: 14px;
    color: var(--muted-text);
    margin-bottom: 20px;
}
.breadcrumb a {
    color: var(--navy);
}
.breadcrumb a:hover {
    color: var(--primary);
}
.page-title {
    font-size: 32px;
    margin-bottom: 5px;
}
.page-desc {
    color: var(--muted-text);
    margin-bottom: 30px;
}
.stats-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 20px;
    margin-bottom: 30px;
}
.stat-card {
    background: var(--surface);
    border-radius: var(--radius-medium);
    padding: 20px;
    box-shadow: var(--shadow-small);
    border: 1px solid var(--border);
    display: flex;
    align-items: flex-start;
    gap: 15px;
}
.stat-icon {
    width: 48px;
    height: 48px;
    border-radius: 50%;
    background: rgba(1, 226, 129, 0.1);
    color: var(--primary-hover);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 20px;
}
.stat-info h3 {
    font-size: 24px;
    margin-bottom: 0;
    color: var(--navy);
}
.stat-info p {
    font-size: 13px;
    color: var(--muted-text);
    margin: 0;
}
.section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}
.section-header h2 {
    font-size: 22px;
}
.booking-list {
    display: flex;
    flex-direction: column;
    gap: 15px;
    margin-bottom: 30px;
}
.booking-item {
    background: var(--surface);
    border-radius: var(--radius-medium);
    padding: 20px;
    box-shadow: var(--shadow-small);
    border: 1px solid var(--border);
    display: flex;
    justify-content: space-between;
    align-items: center;
}
.booking-info {
    display: flex;
    flex-direction: column;
    gap: 5px;
}
.booking-title {
    font-size: 18px;
    font-weight: 700;
    color: var(--navy);
    display: flex;
    align-items: center;
    gap: 10px;
}
.booking-meta {
    font-size: 14px;
    color: var(--muted-text);
    display: flex;
    align-items: center;
    gap: 15px;
}
.badge-status {
    padding: 4px 10px;
    border-radius: 6px;
    font-size: 12px;
    font-weight: 600;
}
.status-wait { background: #fff3cd; color: #856404; border: 1px solid #ffeeba; }
.status-ok { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
.status-live { background: #cce5ff; color: #004085; border: 1px solid #b8daff; }
.status-cancel { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
.quick-actions {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 15px;
}
.action-card {
    background: var(--surface);
    border-radius: var(--radius-medium);
    padding: 20px;
    text-align: center;
    box-shadow: var(--shadow-small);
    border: 1px solid var(--border);
    transition: var(--transition);
}
.action-card:hover {
    border-color: var(--primary);
    transform: translateY(-2px);
}
.action-icon {
    width: 50px;
    height: 50px;
    border-radius: 50%;
    background: var(--background);
    color: var(--navy);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 20px;
    margin: 0 auto 10px;
    transition: var(--transition);
}
.action-card:hover .action-icon {
    background: var(--primary);
    color: var(--surface);
}
.action-title {
    font-size: 14px;
    font-weight: 600;
    color: var(--navy);
}

@media (max-width: 1024px) {
    .account-container { flex-direction: column; }
    .account-sidebar { width: 100%; }
    .stats-grid { grid-template-columns: repeat(2, 1fr); }
    .quick-actions { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 768px) {
    .stats-grid { grid-template-columns: 1fr; }
    .booking-item { flex-direction: column; align-items: flex-start; gap: 15px; }
}
</style>
</head>
<body>

<jsp:include page="/common/header-xtra.jsp" />

<div class="account-wrapper">
    <div class="account-container">
        <!-- Sidebar -->
        <aside class="account-sidebar">
            <div class="profile-card">
                <div class="profile-avatar">
                    <c:choose>
                        <c:when test="${not empty account.fullName}">${fn:escapeXml(fn:substring(account.fullName, 0, 1).toUpperCase())}</c:when>
                        <c:otherwise>${fn:escapeXml(fn:substring(account.username, 0, 1).toUpperCase())}</c:otherwise>
                    </c:choose>
                </div>
                <div class="profile-name">${fn:escapeXml(not empty account.fullName ? account.fullName : account.username)}</div>
                <div class="profile-email">${not empty account.email ? fn:escapeXml(account.email) : 'Chưa cập nhật email'}</div>
                <c:if test="${not empty account.phoneNumber}">
                    <div class="profile-email" style="margin-top: -10px;">${fn:escapeXml(account.phoneNumber)}</div>
                </c:if>
                <div class="profile-rep">
                    <i class="fas fa-star" style="margin-right: 5px;"></i> Uy tín: ${account.diemUyTin}/100
                </div>
                <div>
                    <a href="${pageContext.request.contextPath}/customer/ho-so" class="btn btn-outline" style="color: var(--navy); border-color: var(--border); width: 100%; margin-bottom: 10px;">Chỉnh sửa hồ sơ</a>
                </div>
            </div>

            
            <div class="menu-card">
                <a href="${pageContext.request.contextPath}/customer/tai-khoan" class="menu-item active">
                    <i class="fas fa-home"></i> Tổng quan
                </a>
                <a href="${pageContext.request.contextPath}/customer/ghep-keo?tab=cua-toi" class="menu-item">
                    <i class="fas fa-futbol"></i> Kèo của tôi
                </a>
                <a href="${pageContext.request.contextPath}/customer/dich-vu-cua-toi" class="menu-item">
                    <i class="fas fa-screwdriver-wrench"></i> Dịch vụ của tôi
                </a>
                <a href="${pageContext.request.contextPath}/customer/doi-nhom" class="menu-item">
                    <i class="fas fa-users"></i> Nhóm của tôi
                </a>
                <a href="${pageContext.request.contextPath}/customer/doi-mat-khau" class="menu-item">
                    <i class="fas fa-lock"></i> Đổi mật khẩu
                </a>
                <a href="${pageContext.request.contextPath}/customer/notification-settings" class="menu-item">
                    <i class="fas fa-bell"></i> Cài đặt thông báo
                </a>
                <a href="${pageContext.request.contextPath}/logout" class="menu-item danger">
                    <i class="fas fa-sign-out-alt"></i> Đăng xuất
                </a>
            </div>
</aside>

        <!-- Main Content -->
        <main class="account-main">
            <jsp:include page="/customer/fragments/overview.jsp" />
        </main>
    </div>
</div>

</body>
</html>
