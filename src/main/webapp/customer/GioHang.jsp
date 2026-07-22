<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Giỏ hàng của bạn - V-SPORT</title>
    <jsp:include page="/common/xtra-head.jsp" />
    <style>
        html, body { background: var(--background); color: var(--navy); font-family: 'Outfit', sans-serif; overflow-y: scroll; }
        .cart-header {
            background: var(--navy); color: #fff;
            padding: 20px 0; margin-bottom: 30px;
        }
        .cart-header .container {
            display: flex; align-items: center; justify-content: space-between;
        }
        .cart-title {
            font-size: 24px; font-weight: 800; margin: 0;
            display: flex; align-items: center; gap: 10px;
            color: #ffffff;
        }
        .cart-container {
            max-width: 1000px; margin: 0 auto; padding: 0 15px;
        }
        .cart-item {
            background: #fff; border: 1px solid var(--border);
            border-radius: 12px; padding: 20px; margin-bottom: 20px;
            display: flex; align-items: center; justify-content: space-between;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
        }
        .cart-item-info {
            display: flex; flex-direction: column; gap: 8px;
        }
        .cart-item-title {
            font-size: 18px; font-weight: 800; color: var(--navy);
        }
        .cart-item-detail {
            font-size: 14px; color: var(--muted-text);
            display: flex; align-items: center; gap: 6px;
        }
        .cart-item-price {
            font-size: 20px; font-weight: 800; color: var(--primary);
        }
        .cart-item-status {
            display: inline-flex; align-items: center; padding: 4px 12px;
            border-radius: 999px; font-size: 12px; font-weight: 700;
        }
        .status-pending { background: #FFF7DA; color: #8a6116; }
        .status-payment { background: #ffe6cf; color: #8a4b12; }
        .cart-actions {
            display: flex; flex-direction: column; gap: 10px; align-items: flex-end;
        }
        .btn-cart-action {
            display: inline-flex; align-items: center; gap: 8px;
            padding: 10px 20px; border-radius: 8px; font-weight: 700;
            font-size: 14px; text-decoration: none; cursor: pointer;
            border: none;
        }
        .btn-pay {
            background: var(--primary); color: #fff;
        }
        .btn-pay:hover { background: var(--primary-hover); color: #fff; }
        .btn-cancel {
            background: #ffe5e6; color: #e3000f;
        }
        .btn-cancel:hover { background: #fcd2d4; color: #e3000f; }
        .empty-cart {
            text-align: center; padding: 60px 20px;
            background: #fff; border-radius: 12px; border: 1px solid var(--border);
        }
        .empty-cart i { font-size: 60px; color: var(--border); margin-bottom: 20px; }
        .empty-cart h3 { font-size: 20px; font-weight: 800; color: var(--navy); margin-bottom: 10px; }
        .empty-cart p { color: var(--muted-text); margin-bottom: 20px; }
    </style>
</head>
<body>

<jsp:include page="/common/header-xtra.jsp" />

<div class="cart-header">
    <div class="container">
        <h1 class="cart-title">
            <i class="fas fa-shopping-cart"></i>
            Giỏ hàng của bạn
        </h1>
        <a href="${pageContext.request.contextPath}/customer/dat-san" style="color: #fff; text-decoration: underline;">Tiếp tục đặt sân</a>
    </div>
</div>

<div class="cart-container">
    <c:if test="${not empty sessionScope.error}">
        <div style="background: #ffe5e6; color: #e3000f; padding: 15px; border-radius: 8px; margin-bottom: 20px; font-weight: 600;">
            ${fn:escapeXml(sessionScope.error)}
        </div>
        <% session.removeAttribute("error"); %>
    </c:if>
    <c:if test="${not empty sessionScope.message}">
        <div style="background: #E5F7EF; color: #16A36A; padding: 15px; border-radius: 8px; margin-bottom: 20px; font-weight: 600;">
            ${fn:escapeXml(sessionScope.message)}
        </div>
        <% session.removeAttribute("message"); %>
    </c:if>

    <c:choose>
        <c:when test="${empty cartItems}">
            <div class="empty-cart">
                <i class="fas fa-shopping-basket"></i>
                <h3>Giỏ hàng trống</h3>
                <p>Bạn chưa có sân nào trong giỏ hàng. Hãy đặt sân ngay để trải nghiệm!</p>
                <a href="${pageContext.request.contextPath}/customer/dat-san" class="btn btn-primary">Đặt sân ngay</a>
            </div>
        </c:when>
        <c:otherwise>
            <c:forEach var="item" items="${cartItems}">
                <c:set var="tenSan" value="Sân không xác định" />
                <c:set var="tenCoSo" value="Cơ sở không xác định" />
                <c:forEach var="s" items="${dsSan}">
                    <c:if test="${s.sanID == item.sanId}">
                        <c:set var="tenSan" value="${s.tenSan}" />
                        <c:forEach var="c" items="${dsCoSo}">
                            <c:if test="${c.coSoID == s.coSoID}">
                                <c:set var="tenCoSo" value="${c.tenCoSo}" />
                            </c:if>
                        </c:forEach>
                    </c:if>
                </c:forEach>

                <div class="cart-item">
                    <div class="cart-item-info">
                        <div class="cart-item-title">${fn:escapeXml(tenSan)} - ${fn:escapeXml(tenCoSo)}</div>
                        <div class="cart-item-detail">
                            <i class="far fa-calendar-alt"></i> ${item.ngayDat}
                        </div>
                        <div class="cart-item-detail">
                            <i class="far fa-clock"></i> ${fn:substring(item.gioBatDau, 0, 5)} - ${fn:substring(item.gioKetThuc, 0, 5)}
                        </div>
                        <div>
                            <c:if test="${item.trangThai == 'Chờ xác nhận'}">
                                <span class="cart-item-status status-pending"><i class="fas fa-hourglass-half" style="margin-right:5px;"></i> Chờ xác nhận (Thanh toán tại sân)</span>
                            </c:if>
                            <c:if test="${item.trangThai == 'Chờ thanh toán'}">
                                <span class="cart-item-status status-payment"><i class="fas fa-qrcode" style="margin-right:5px;"></i> Chờ thanh toán</span>
                            </c:if>
                        </div>
                    </div>
                    <div class="cart-actions">
                        <div class="cart-item-price"><fmt:formatNumber value="${item.tongTienDuKien}" pattern="#,##0"/> đ</div>
                        <c:if test="${item.trangThai == 'Chờ thanh toán'}">
                            <a href="${pageContext.request.contextPath}/customer/thanh-toan-qr?datSanId=${item.datSanId}" class="btn-cart-action btn-pay">
                                <i class="fas fa-credit-card"></i> Thanh toán ngay
                            </a>
                        </c:if>
                        <form action="${pageContext.request.contextPath}/customer/huy-dat-san" method="post" style="margin: 0;">
                            <input type="hidden" name="datSanId" value="${item.datSanId}">
                            <input type="hidden" name="source" value="gio-hang">
                            <button type="submit" class="btn-cart-action btn-cancel" onclick="return confirm('Bạn có chắc chắn muốn hủy sân này?');">
                                <i class="fas fa-times"></i> Hủy đặt sân
                            </button>
                        </form>
                    </div>
                </div>
            </c:forEach>
        </c:otherwise>
    </c:choose>
</div>

</body>
</html>
