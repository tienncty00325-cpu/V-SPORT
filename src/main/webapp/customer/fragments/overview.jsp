<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
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
        <div class="stat-icon" style="background: rgba(255, 71, 87, 0.1); color: var(--danger);"><i class="fas fa-star"></i></div>
        <div class="stat-info">
            <h3>${account.diemUyTin}</h3>
            <p>Điểm uy tín</p>
        </div>
    </div>
</div>

<div class="section-header">
    <h2>Lịch đặt sân gần nhất</h2>
    <a href="${pageContext.request.contextPath}/customer/lich-su-dat-san" class="btn btn-outline" style="color: var(--navy); border-color: var(--border);">Xem tất cả <i class="fas fa-arrow-right" style="margin-left: 5px;"></i></a>
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
                        <a href="${pageContext.request.contextPath}/customer/lich-su-dat-san" class="btn btn-outline" style="color: var(--navy); border-color: var(--border);">Xem chi tiết</a>
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
    <a href="${pageContext.request.contextPath}/customer/ghep-keo?tab=kham-pha" class="action-card">
        <div class="action-icon"><i class="fas fa-search"></i></div>
        <div class="action-title">Tìm người chơi</div>
    </a>
</div>
