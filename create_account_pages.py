import os

# Create fragments directory
os.makedirs('src/main/webapp/customer/fragments', exist_ok=True)

# 1. overview.jsp
with open('src/main/webapp/customer/fragments/overview.jsp', 'w', encoding='utf-8') as f:
    f.write('''<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<div class="breadcrumb">
    <a href="${pageContext.request.contextPath}/">Trang chủ</a> / <span>Tài khoản của tôi</span>
</div>

<h1 class="page-title">Tổng quan tài khoản</h1>
<p class="page-desc">Theo dõi lịch đặt sân, hoạt động và thông tin tài khoản của bạn.</p>

<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-icon"><i class="fas fa-calendar-check"></i></div>
        <div class="stat-info">
            <h3>${upcomingCount}</h3>
            <p>Lịch sắp tới</p>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon" style="background: rgba(18, 45, 64, 0.1); color: var(--navy);"><i class="fas fa-history"></i></div>
        <div class="stat-info">
            <h3>${totalBookings}</h3>
            <p>Tổng số lần đặt</p>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon" style="background: rgba(255, 165, 2, 0.1); color: var(--warning);"><i class="fas fa-futbol"></i></div>
        <div class="stat-info">
            <h3>0</h3>
            <p>Kèo đang tham gia</p>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon" style="background: rgba(255, 71, 87, 0.1); color: var(--danger);"><i class="fas fa-star"></i></div>
        <div class="stat-info">
            <h3>${account.diemUyTin}</h3>
            <p>Điểm uy tín</p>
        </div>
    </div>
</div>

<div class="section-header">
    <h2>Lịch đặt sân gần nhất</h2>
    <a href="${pageContext.request.contextPath}/customer/tai-khoan?tab=bookings" class="btn btn-outline" style="color: var(--navy); border-color: var(--border);">Xem tất cả <i class="fas fa-arrow-right" style="margin-left: 5px;"></i></a>
</div>

<div class="booking-list">
    <c:choose>
        <c:when test="${not empty upcomingBookings}">
            <c:forEach var="lich" items="${upcomingBookings}">
                <div class="booking-item">
                    <div class="booking-info">
                        <div class="booking-title">
                            <c:choose>
                                <c:when test="${not empty upcomingSanNames[lich.sanId]}">${fn:escapeXml(upcomingSanNames[lich.sanId])}</c:when>
                                <c:otherwise>Sân #${lich.sanId}</c:otherwise>
                            </c:choose>
                            <c:choose>
                                <c:when test="${lich.trangThai == 'Chờ xác nhận' || lich.trangThai == 'Chờ thanh toán'}"><span class="badge-status status-wait">${fn:escapeXml(lich.trangThai)}</span></c:when>
                                <c:when test="${lich.trangThai == 'Đã xác nhận' || lich.trangThai == 'Đã đặt' || lich.trangThai == 'Đã thanh toán' || lich.trangThai == 'Đã cọc'}"><span class="badge-status status-ok">${fn:escapeXml(lich.trangThai)}</span></c:when>
                                <c:when test="${lich.trangThai == 'Đã hủy'}"><span class="badge-status status-cancel">${fn:escapeXml(lich.trangThai)}</span></c:when>
                                <c:when test="${lich.trangThai == 'Đang sử dụng'}"><span class="badge-status status-live">${fn:escapeXml(lich.trangThai)}</span></c:when>
                                <c:otherwise><span class="badge-status" style="background: #e2e8f0; color: #475569; border: 1px solid #cbd5e1;">${fn:escapeXml(lich.trangThai)}</span></c:otherwise>
                            </c:choose>
                        </div>
                        <div class="booking-meta">
                            <c:if test="${not empty upcomingCoSoNames[lich.sanId]}">
                                <span><i class="fas fa-map-marker-alt" style="margin-right: 5px;"></i> ${fn:escapeXml(upcomingCoSoNames[lich.sanId])}</span>
                            </c:if>
                            <span><i class="fas fa-hashtag" style="margin-right: 5px;"></i> Mã đặt sân #${lich.datSanId}</span>
                        </div>
                        <div class="booking-meta" style="color: var(--navy); font-weight: 600; margin-top: 5px;">
                            <span><i class="far fa-calendar-alt" style="margin-right: 5px; color: var(--primary);"></i> ${lich.ngayDat}</span>
                            <span><i class="far fa-clock" style="margin-right: 5px; color: var(--primary);"></i> ${lich.gioBatDau} - ${lich.gioKetThuc}</span>
                        </div>
                    </div>
                    <div class="booking-actions" style="display: flex; gap: 10px;">
                        <a href="${pageContext.request.contextPath}/customer/tai-khoan?tab=bookings" class="btn btn-outline" style="color: var(--navy); border-color: var(--border);">Xem chi tiết</a>
                    </div>
                </div>
            </c:forEach>
        </c:when>
        <c:otherwise>
            <div style="padding: 40px; text-align: center; background: var(--surface); border-radius: var(--radius-medium); border: 1px solid var(--border);">
                <div style="font-size: 40px; color: var(--border); margin-bottom: 15px;"><i class="fas fa-calendar-times"></i></div>
                <h3 style="margin-bottom: 10px; color: var(--navy);">Chưa có lịch đặt nào</h3>
                <p style="color: var(--muted-text); margin-bottom: 20px;">Bạn hiện không có lịch đặt sân sắp tới.</p>
                <a href="${pageContext.request.contextPath}/customer/dat-san" class="btn btn-primary">Đặt sân ngay</a>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<div class="section-header">
    <h2>Truy cập nhanh</h2>
</div>
<div class="quick-actions">
    <a href="${pageContext.request.contextPath}/customer/dat-san" class="action-card">
        <div class="action-icon"><i class="fas fa-plus-circle"></i></div>
        <div class="action-title">Đặt sân mới</div>
    </a>
    <a href="${pageContext.request.contextPath}/customer/ban-do" class="action-card">
        <div class="action-icon"><i class="fas fa-map-marked-alt"></i></div>
        <div class="action-title">Tìm sân gần nhất</div>
    </a>
    <a href="${pageContext.request.contextPath}/customer/ghep-keo?tab=tao-keo" class="action-card">
        <div class="action-icon"><i class="fas fa-users"></i></div>
        <div class="action-title">Tạo kèo</div>
    </a>
    <a href="${pageContext.request.contextPath}/customer/ghep-keo?tab=tim-doi-thu" class="action-card">
        <div class="action-icon"><i class="fas fa-search"></i></div>
        <div class="action-title">Tìm đối thủ</div>
    </a>
</div>
''')

# 2. bookings.jsp
with open('src/main/webapp/customer/fragments/bookings.jsp', 'w', encoding='utf-8') as f:
    f.write('''<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<div class="breadcrumb">
    <a href="${pageContext.request.contextPath}/">Trang chủ</a> / <a href="${pageContext.request.contextPath}/customer/tai-khoan">Tài khoản</a> / <span>Lịch đặt sân</span>
</div>
<h1 class="page-title">Lịch đặt sân</h1>
<p class="page-desc">Quản lý các lịch đặt sân hiện tại và trước đây.</p>
<div style="padding: 40px; text-align: center; background: var(--surface); border-radius: var(--radius-medium); border: 1px solid var(--border);">
    <div style="font-size: 40px; color: var(--border); margin-bottom: 15px;"><i class="fas fa-clock"></i></div>
    <h3 style="margin-bottom: 10px; color: var(--navy);">Tính năng đang được cập nhật</h3>
    <p style="color: var(--muted-text); margin-bottom: 20px;">Vui lòng quay lại sau.</p>
</div>
''')

# Create empty shells for the rest
tabs = ['matches', 'groups', 'opponents', 'reputation', 'profile', 'password', 'notifications', 'policies']
for tab in tabs:
    with open(f'src/main/webapp/customer/fragments/{tab}.jsp', 'w', encoding='utf-8') as f:
        f.write(f'''<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<div class="breadcrumb">
    <a href="${{pageContext.request.contextPath}}/">Trang chủ</a> / <a href="${{pageContext.request.contextPath}}/customer/tai-khoan">Tài khoản</a> / <span>{tab.capitalize()}</span>
</div>
<h1 class="page-title">{tab.capitalize()}</h1>
<p class="page-desc">Quản lý thông tin tương ứng.</p>
<div style="padding: 40px; text-align: center; background: var(--surface); border-radius: var(--radius-medium); border: 1px solid var(--border);">
    <div style="font-size: 40px; color: var(--border); margin-bottom: 15px;"><i class="fas fa-tools"></i></div>
    <h3 style="margin-bottom: 10px; color: var(--navy);">Chưa có dữ liệu</h3>
    <p style="color: var(--muted-text); margin-bottom: 20px;">Tính năng hoặc lịch sử chưa phát sinh dữ liệu thật.</p>
</div>
''')

print("Created fragments.")
