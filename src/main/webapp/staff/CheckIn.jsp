<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Quản lý Mở Sân / Check-in | V-SPORT</title>
    <jsp:include page="/staff/common/staff_head.jsp" />
    <!-- Render QR PayOS thật (chuỗi payload EMV từ PayOS) thành ảnh QR ngay trên trình duyệt - asset
         tự host trong project (davidshimjs/qrcodejs, MIT), không gửi dữ liệu giao dịch ra dịch vụ
         ảnh QR bên thứ ba nào, không phụ thuộc CDN ngoài khi chạy local/offline. -->
    <script src="${pageContext.request.contextPath}/assets/js/qrcode.min.js"></script>

    <style>
        body { font-family: 'Inter', sans-serif; }
        .card { 
            background: #fff; 
            border: 1px solid ${sessionScope.user.roleId == 2 ? '#e9d5ff' : '#ffedd5'}; 
            border-radius: 16px; 
            transition: box-shadow .2s, transform .2s; 
        }
        .card-hover:hover { 
            box-shadow: 0 8px 24px -8px ${sessionScope.user.roleId == 2 ? 'rgba(124, 58, 237, 0.15)' : 'rgba(234, 88, 12, 0.12)'}; 
            transform: translateY(-2px); 
        }
        .badge { display: inline-flex; align-items: center; padding: 4px 10px; border-radius: 8px; font-size: 11px; font-weight: 600; }
        .badge-green { background: #dcfce7; color: #15803d; }
        .badge-amber { background: #fef3c7; color: #b45309; }
        .badge-red { background: #fee2e2; color: #b91c1c; }
        .badge-blue { background: #dbeafe; color: #1e40af; }
        .badge-orange { background: #ffedd5; color: #c2410c; }
        .badge-purple { background: #f3e8ff; color: #6d28d9; }
        .badge-gray { background: #f4f4f5; color: #52525b; }
        
        @keyframes pulse-dot {
            0%, 100% { box-shadow: 0 0 0 0 ${sessionScope.user.roleId == 2 ? 'rgba(124, 58, 237, 0.4)' : 'rgba(234, 88, 12, 0.4)'}; }
            50% { box-shadow: 0 0 0 8px rgba(234, 88, 12, 0); }
        }
        .live-dot { animation: pulse-dot 1.6s ease-in-out infinite; }
        
        @keyframes fadeUp {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        main > section { animation: fadeUp .35s ease both; }
        .hero-gradient { 
            background: ${sessionScope.user.roleId == 2 
                ? 'linear-gradient(135deg, #faf5ff 0%, #f3e8ff 60%, #e9d5ff 100%)' 
                : 'linear-gradient(135deg, #fff7ed 0%, #ffedd5 60%, #ffedad 100%)'}; 
        }

        /* POS Product Catalog styles */
        .pos-tab {
            padding: 6px 14px;
            border-radius: 9999px;
            font-size: 11.5px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.15s ease;
            border: 1px solid #e2e8f0;
            background: #ffffff;
            color: #64748b;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            user-select: none;
        }
        .pos-tab:hover {
            border-color: #cbd5e1;
            color: #334155;
            background: #f8fafc;
        }
        .pos-tab.active {
            background: ${sessionScope.user.roleId == 2 ? '#7c3aed' : '#ea580c'};
            color: #ffffff;
            border-color: ${sessionScope.user.roleId == 2 ? '#7c3aed' : '#ea580c'};
        }
        
        .pos-card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 14px;
            padding: 12px;
            transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
            cursor: pointer;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            position: relative;
            user-select: none;
            box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.02);
            min-height: 85px;
        }
        .pos-card:hover:not(.disabled) {
            border-color: ${sessionScope.user.roleId == 2 ? '#7c3aed' : '#ea580c'};
            box-shadow: 0 6px 16px -4px ${sessionScope.user.roleId == 2 ? 'rgba(124, 58, 237, 0.12)' : 'rgba(234, 88, 12, 0.1)'};
            transform: translateY(-1.5px);
        }
        .pos-card:active:not(.disabled) {
            transform: scale(0.97);
        }
        .pos-card.disabled {
            opacity: 0.55;
            cursor: not-allowed;
            background: #f8fafc;
            border-color: #cbd5e1;
            box-shadow: none;
        }

        /* 3-Column POS modal custom styling */
        .pos-grid-container {
            display: grid;
            grid-template-columns: 1fr;
            gap: 1.5rem;
        }
        @media (min-width: 1024px) {
            .pos-grid-container {
                grid-template-columns: 42fr 30fr 28fr;
            }
        }
        
        /* Stepper styles */
        .stepper-btn {
            width: 26px;
            height: 26px;
            border-radius: 8px;
            background: #f1f5f9;
            color: #475569;
            font-weight: 700;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.15s ease;
            user-select: none;
        }
        .stepper-btn:hover {
            background: #e2e8f0;
            color: #1e293b;
        }
        .stepper-btn:active {
            transform: scale(0.92);
        }
        
        /* Ghi chú: .bill-mode-card / .pay-method-card (card lớn kiểu cũ) đã được thay bằng
           .seg-control / .seg-btn (segmented control gọn) - xem định nghĩa bên dưới. */

        /* Segmented control - dùng chung cho Mục đích thao tác / Loại hóa đơn / Phương thức thanh toán */
        .seg-control {
            display: flex;
            background: #eef0f6;
            border-radius: 10px;
            padding: 3px;
            gap: 2px;
        }
        .seg-btn {
            flex: 1;
            border: none;
            background: transparent;
            border-radius: 8px;
            padding: 8px 10px;
            font-size: 12.5px;
            font-weight: 600;
            color: #5d5d67;
            cursor: pointer;
            transition: background-color .15s ease, color .15s ease, box-shadow .15s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 5px;
            white-space: nowrap;
            line-height: 1.2;
        }
        .seg-btn:hover:not(.active) { color: #27272a; }
        .seg-btn.active {
            background: #ffffff;
            color: ${sessionScope.user.roleId == 2 ? '#7c3aed' : '#ea580c'};
            box-shadow: 0 1px 3px rgba(15, 23, 42, 0.12);
        }
        .seg-btn:focus-visible {
            outline: 2px solid ${sessionScope.user.roleId == 2 ? '#7c3aed' : '#ea580c'};
            outline-offset: 1px;
        }
        @media (max-width: 420px) {
            .seg-btn { font-size: 11.5px; padding: 7px 6px; }
        }
        
        /* Cart items styling */
        .cart-item {
            border-bottom: 1px solid #f1f5f9;
            padding: 10px 4px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            transition: background 0.15s ease;
        }
        .cart-item:hover {
            background: rgba(248, 250, 252, 0.5);
        }

        /* ── Payment success view (chung style với hóa đơn in - staff/HoaDonPrint.jsp) ── */
        .success-processing-overlay {
            position: absolute; inset: 0; background: rgba(255,255,255,0.85);
            backdrop-filter: blur(1px); display: flex; flex-direction: column;
            align-items: center; justify-content: center; gap: 10px; z-index: 10;
        }
        .success-banner-icon {
            width: 44px; height: 44px; border-radius: 999px;
            background: #ecfdf5; color: #059669;
            display: flex; align-items: center; justify-content: center; flex-shrink: 0;
        }
        @media (prefers-reduced-motion: no-preference) {
            .success-banner-enter { animation: fadeUp .3s ease both; }
        }

        .receipt {
            width: 400px; max-width: 100%; margin: 0 auto; background: #ffffff; color: #1f2937;
            font-size: 12.5px; line-height: 1.55; padding: 18px 20px; box-sizing: border-box; word-break: break-word;
        }
        .receipt-row { display: flex; justify-content: space-between; gap: 10px; }
        .receipt-row + .receipt-row { margin-top: 4px; }
        .receipt-money { text-align: right; white-space: nowrap; font-variant-numeric: tabular-nums; }
        .receipt hr { border: none; border-top: 1px solid #e5e7eb; margin: 10px 0; }
        .receipt .center { text-align: center; }
        .receipt .bold { font-weight: 700; }
        .receipt .muted { color: #6b7280; }
        .receipt .small { font-size: 11px; color: #6b7280; }
        .receipt .mono { font-variant-numeric: tabular-nums; }
        .receipt .total-row { font-size: 15px; font-weight: 800; }
        .receipt table.dv-table { width: 100%; border-collapse: collapse; margin-top: 6px; }
        .receipt table.dv-table th { text-align: left; font-size: 11px; font-weight: 700; color: #6b7280; border-bottom: 1px solid #e5e7eb; padding-bottom: 5px; }
        .receipt table.dv-table th.qty, .receipt table.dv-table th.money { text-align: right; }
        .receipt table.dv-table td { padding: 5px 0; vertical-align: top; }
        .receipt table.dv-table td.qty, .receipt table.dv-table td.money { text-align: right; white-space: nowrap; font-variant-numeric: tabular-nums; }
        .segment-card { border: 1px solid #e5e7eb; border-radius: 10px; padding: 8px 10px; margin-top: 8px; }
        .segment-tag { display: inline-flex; align-items: center; gap: 3px; font-size: 10.5px; font-weight: 700; padding: 1px 8px; border-radius: 999px; }
        .segment-tag.light { background: #fef3c7; color: #92400e; }
        .segment-tag.no-light { background: #f4f4f5; color: #52525b; }
        .min-charge-note { font-size: 11px; color: #92400e; background: #fffbeb; border: 1px solid #fde68a; border-radius: 8px; padding: 6px 9px; margin-top: 6px; }

        /* QR PayOS: khung cố định để không nhảy layout giữa loading/hiển thị/lỗi; hỗ trợ cả 3 kiểu
           render mà thư viện QR có thể tạo ra tùy trình duyệt (canvas phổ biến nhất, table dự phòng). */
        .payos-qr-container {
            width: 232px;
            min-height: 232px;
            display: grid;
            place-items: center;
            background: #fff;
            border: 1px solid #e4e4e7;
            border-radius: 10px;
        }
        .payos-qr-container canvas,
        .payos-qr-container img,
        .payos-qr-container svg,
        .payos-qr-container table {
            display: block;
            width: 220px;
            height: 220px;
            max-width: 100%;
        }

        @media print {
            body.printing-invoice > *:not(#staff-print-root) { visibility: hidden !important; }
            #staff-print-root { visibility: visible !important; position: fixed !important; inset: 0; background: #fff; z-index: 9999; }
            #staff-print-root .receipt { width: 80mm; max-width: 80mm; margin: 0; }
        }
    </style>
</head>
<body class="text-zinc-900 min-h-screen">

<!-- Khai báo các biến theme động dựa theo Role (Quản lý - Tím | Lễ tân - Cam) -->
<c:set var="isManager" value="${sessionScope.user.roleId == 2}" />
<c:set var="themeBg" value="${isManager ? 'bg-purple-600' : 'bg-orange-600'}" />
<c:set var="themeBgHover" value="${isManager ? 'hover:bg-purple-700' : 'hover:bg-orange-700'}" />
<c:set var="themeText" value="${isManager ? 'text-purple-650' : 'text-orange-650'}" />
<c:set var="themeTextDark" value="${isManager ? 'text-purple-950' : 'text-orange-950'}" />
<c:set var="themeTextMedium" value="${isManager ? 'text-purple-700' : 'text-orange-700'}" />
<c:set var="themeTextLight" value="${isManager ? 'text-purple-500' : 'text-orange-550'}" />
<c:set var="themeBorder" value="${isManager ? 'border-purple-100' : 'border-orange-100'}" />
<c:set var="themeBorderStrong" value="${isManager ? 'border-purple-200' : 'border-orange-200'}" />
<c:set var="themeBgLight" value="${isManager ? 'bg-purple-50/50' : 'bg-orange-50/50'}" />
<c:set var="themeBgLightStrong" value="${isManager ? 'bg-purple-100/50' : 'bg-orange-100/50'}" />
<c:set var="themeIcon" value="${isManager ? 'text-purple-600' : 'text-orange-650'}" />
<c:set var="badgeTheme" value="${isManager ? 'badge-purple' : 'badge-orange'}" />
<c:set var="focusRing" value="${isManager ? 'focus:border-purple-500' : 'focus:border-orange-500'}" />

<!-- Sidebar Navigation -->
<c:choose>
    <c:when test="${isManager}">
        <jsp:include page="/manager/common/sidebar.jsp" />
    </c:when>
    <c:otherwise>
        <jsp:include page="/staff/common/sidebar.jsp" />
    </c:otherwise>
</c:choose>

<!-- Header -->
<header class="h-[64px] fixed top-0 right-0 left-0 lg:left-[248px] bg-white/80 backdrop-blur-lg border-b ${themeBorder} z-20 flex items-center justify-between px-4 lg:px-6">
    <div class="flex items-center gap-3">
        <button id="mobileMenuBtn" class="lg:hidden p-2 rounded-lg ${isManager ? 'hover:bg-purple-50 text-purple-600' : 'hover:bg-orange-50 text-orange-650'}">
            <span class="material-symbols-outlined text-[20px]">menu</span>
        </button>
        <div>
            <h1 class="text-sm font-bold ${themeTextDark} tracking-tight">Hệ thống mở sân / Check-in</h1>
            <p class="text-xs ${themeTextLight} flex items-center gap-1.5">
                <span class="material-symbols-outlined text-[12px]">schedule</span>Chi nhánh cơ sở CS${sessionScope.user.coSoId}
            </p>
        </div>
    </div>
    <div class="flex items-center gap-1.5">
        <div class="text-xs font-semibold px-3 py-1 ${isManager ? 'bg-purple-50 text-purple-750' : 'bg-orange-50 text-orange-700'} rounded-lg">
            Vai trò: ${isManager ? "Quản lý" : "Lễ tân trực ca"}
        </div>
        <div class="w-px h-6 ${themeBorder} mx-1"></div>
        <jsp:include page="/manager/common/profile_dropdown.jsp" />
    </div>
</header>

<!-- Main Content Area -->
<main class="lg:ml-[248px] mt-[64px] p-4 lg:p-6 flex flex-col gap-6">

    <!-- 1. THÔNG BÁO HỆ THỐNG / THÔNG BÁO LỖI -->
    <c:if test="${not empty successMsg}">
        <section class="bg-green-50 border border-green-200 text-green-800 p-4 rounded-xl flex items-center gap-3 shadow-sm">
            <span class="material-symbols-outlined text-green-600 text-[24px]">check_circle</span>
            <div>
                <p class="font-bold text-sm">Thành công</p>
                <p class="text-xs">${successMsg}</p>
            </div>
        </section>
    </c:if>

    <c:if test="${not empty errorMsg and empty paymentRequired}">
        <section class="bg-red-50 border border-red-200 text-red-800 p-4 rounded-xl flex items-center gap-3 shadow-sm">
            <span class="material-symbols-outlined text-red-600 text-[24px]">error</span>
            <div>
                <p class="font-bold text-sm">Lỗi xử lý nghiệp vụ</p>
                <p class="text-xs">${errorMsg}</p>
            </div>
        </section>
    </c:if>

    <!-- HỘP THOẠI CẢNH BÁO THANH TOÁN (Payment Lock Alert) -->
    <c:if test="${paymentRequired}">
        <section class="bg-amber-50 border-2 border-amber-300 text-amber-950 p-5 rounded-2xl flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-md">
            <div class="flex items-start gap-3.5">
                <div class="w-12 h-12 rounded-full bg-amber-100 flex items-center justify-center text-amber-700 shrink-0 shadow-inner">
                    <span class="material-symbols-outlined text-[28px]" style="font-variation-settings: 'FILL' 1">lock</span>
                </div>
                <div class="hidden">
                    <h3 class="font-black text-base text-amber-950 tracking-tight flex items-center gap-1.5">
                        CẢNH BÁO THU TIỀN MẶT <span class="badge badge-red uppercase">Payment Lock</span>
                    </h3>
                    <p class="text-xs text-amber-900 mt-1 leading-relaxed">
                        ${errorMsg}<br>
                        <strong>Yêu cầu:</strong> Lễ tân vui lòng thu tiền mặt của khách tại quầy trước khi kích hoạt trạng thái mở sân.
                    </p>
                </div>
            </div>
            <div class="flex gap-2 shrink-0 self-end md:self-center">
                <form action="${pageContext.request.contextPath}/staff/checkin" method="post">
                    <input type="hidden" name="action" value="checkInPreBooked">
                    <input type="hidden" name="datSanId" value="${datSanIdPending}">
                    <input type="hidden" name="daThuTienMat" value="true">
                    <button type="submit" class="bg-amber-600 hover:bg-amber-700 text-white font-bold text-xs px-4 py-2.5 rounded-xl flex items-center gap-1.5 shadow-sm active:scale-95 transition-all">
                        <span class="material-symbols-outlined text-[16px]">payments</span>
                        Đã thu tiền mặt & Mở sân
                    </button>
                </form>
                <a href="${pageContext.request.contextPath}/staff/checkin" class="bg-zinc-200 hover:bg-zinc-300 text-zinc-800 font-bold text-xs px-4 py-2.5 rounded-xl flex items-center gap-1.5 transition-all">
                    Hủy bỏ
                </a>
            </div>
        </section>
    </c:if>

    <c:set var="availCount" value="0" />
    <c:set var="useCount" value="0" />
    <c:set var="maintCount" value="0" />
    <c:set var="closeCount" value="0" />
    <c:forEach var="s" items="${danhSachSan}">
        <c:choose>
            <c:when test="${s.trangThai == 'Sẵn sàng'}"><c:set var="availCount" value="${availCount + 1}" /></c:when>
            <c:when test="${s.trangThai == 'Đang sử dụng'}"><c:set var="useCount" value="${useCount + 1}" /></c:when>
            <c:when test="${s.trangThai == 'Bảo trì'}"><c:set var="maintCount" value="${maintCount + 1}" /></c:when>
            <c:otherwise><c:set var="closeCount" value="${closeCount + 1}" /></c:otherwise>
        </c:choose>
    </c:forEach>

    <!-- Welcome & Facility Status Bar -->
    <section class="hero-gradient rounded-2xl border ${themeBorderStrong} p-5 flex flex-col md:flex-row justify-between items-start md:items-center gap-4 relative overflow-hidden">
        <div class="absolute -top-12 -right-12 w-64 h-64 ${isManager ? 'bg-purple-300/10' : 'bg-orange-300/10'} rounded-full blur-3xl pointer-events-none"></div>
        <div>
            <span class="text-[10px] font-extrabold uppercase tracking-widest ${themeTextMedium} block mb-0.5">BẢNG ĐIỀU KHIỂN CHI NHÁNH CƠ SỞ</span>
            <h2 class="text-xl font-black ${themeTextDark} tracking-tight">Kích hoạt & Giám sát sân bãi thời gian thực</h2>
            <p class="text-xs ${themeTextMedium} mt-1">Đảm bảo việc mở sân chính xác và xử lý tranh chấp đặt sân online.</p>
        </div>
    </section>

    <!-- Dashboard Stats Grid -->
    <section class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-6 gap-3">
        <div class="card p-3.5 flex flex-col items-center justify-center bg-white border border-zinc-200 shadow-sm text-center">
            <span class="text-[9px] text-zinc-550 font-bold block uppercase tracking-wider">Tổng số sân</span>
            <span id="stat-total" class="text-lg font-black text-zinc-800 mt-1">${danhSachSan.size()}</span>
        </div>
        <div class="card p-3.5 flex flex-col items-center justify-center bg-white border border-green-200 shadow-sm text-center">
            <span class="text-[9px] text-zinc-550 font-bold block uppercase tracking-wider">Sẵn sàng</span>
            <span id="stat-available" class="text-lg font-black text-green-600 mt-1">${availCount}</span>
        </div>
        <div class="card p-3.5 flex flex-col items-center justify-center bg-white border ${themeBorder} shadow-sm text-center">
            <span class="text-[9px] text-zinc-550 font-bold block uppercase tracking-wider">Đang sử dụng</span>
            <span id="stat-in-use" class="text-lg font-black ${themeText} mt-1">${useCount}</span>
        </div>
        <div class="card p-3.5 flex flex-col items-center justify-center bg-white border border-amber-200 shadow-sm text-center">
            <span class="text-[9px] text-zinc-550 font-bold block uppercase tracking-wider">Bảo trì</span>
            <span id="stat-maintenance" class="text-lg font-black text-amber-600 mt-1">${maintCount}</span>
        </div>
        <div class="card p-3.5 flex flex-col items-center justify-center bg-white border border-red-200 shadow-sm text-center">
            <span class="text-[9px] text-zinc-550 font-bold block uppercase tracking-wider">Tạm đóng</span>
            <span id="stat-closed" class="text-lg font-black text-red-650 mt-1">${closeCount}</span>
        </div>
        <div class="card p-3.5 flex flex-col items-center justify-center bg-white border border-zinc-200 shadow-sm text-center">
            <span class="text-[9px] text-zinc-550 font-bold block uppercase tracking-wider">Lịch hôm nay</span>
            <span id="stat-today" class="text-lg font-black ${themeTextMedium} mt-1">${danhSachLich.size()}</span>
        </div>
    </section>

    <!-- 2. HÌNH ẢNH TRẠNG THÁI SÂN BÃI THỰC TẾ (Real-time Field Status Grid) -->
    <section id="field-status-grid" class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
        <c:choose>
            <c:when test="${danhSachSan.size() == 0}">
                <div class="col-span-full py-12 flex flex-col items-center justify-center text-center bg-white rounded-2xl border border-zinc-150 p-6">
                    <span class="material-symbols-outlined text-[48px] text-zinc-300 mb-2">sports_soccer</span>
                    <p class="font-extrabold text-zinc-800 text-sm">Chưa có sân nào trong cơ sở này</p>
                    <p class="text-xs text-zinc-500 mt-1">Hãy tạo sân ở mục Quản lý sân trước.</p>
                </div>
            </c:when>
            <c:otherwise>
                <c:forEach var="san" items="${danhSachSan}">
                    <div class="card p-4 flex flex-col items-center justify-between text-center relative overflow-hidden transition-all duration-200 cursor-pointer card-hover hover:border-zinc-300
                         ${san.trangThai == 'Đang sử dụng' ? (isManager ? 'border-purple-300 shadow-md' : 'border-orange-300 shadow-md') : ''}
                         ${san.trangThai == 'Sẵn sàng' && san.hasUpcomingBooking ? 'border-amber-300 bg-amber-50/30 shadow-md' : ''}
                         ${san.trangThai == 'Bảo trì' ? 'border-amber-200 bg-amber-50/20' : ''}
                         ${san.trangThai == 'Tạm đóng' ? 'border-red-200 bg-red-50/20' : ''}"
                         data-sanid="${san.sanID}"
                         data-tensan="${san.tenSan}"
                         data-loaisan="${san.tenLoaiSan}"
                         data-trangthai="${san.trangThai}"
                         data-mota="${san.moTa}"
                         data-giakhongden="${san.giaKhongDen}"
                         data-giacoden="${san.giaCoDen}"
                         data-giobatdaulenden="${san.gioBatDauLenDen}"
                         data-giokethuclenden="${san.gioKetThucLenDen}"
                         data-datsanidactive="${san.datSanIdActive}"
                         data-giobatdauactive="${san.gioBatDauActive}"
                         data-giokethucactive="${san.gioKetThucActive}"
                         data-ghichuactive="${san.ghiChuActive}"
                         data-nextdatsanid="${san.nextDatSanId}"
                         onclick="onCardClick(event, this)">
                        
                        <div class="w-full flex flex-col items-center">
                            <c:choose>
                                <c:when test="${san.trangThai == 'Đang sử dụng'}">
                                    <span class="absolute top-2.5 right-2.5 w-2 h-2 rounded-full ${isManager ? 'bg-purple-500' : 'bg-orange-500'} live-dot"></span>
                                    <div class="w-12 h-12 rounded-2xl ${isManager ? 'bg-purple-50' : 'bg-orange-50'} flex items-center justify-center ${themeIcon} mb-2 shadow-inner">
                                        <span class="material-symbols-outlined text-[24px]">sports_soccer</span>
                                    </div>
                                    <h4 class="font-bold text-sm text-zinc-800">${san.tenSan}</h4>
                                    <p class="text-[10px] text-zinc-500 font-medium">${san.tenLoaiSan}</p>
                                    <span class="badge ${badgeTheme} mt-2 uppercase text-[10px]">Đang sử dụng</span>
                                    <p class="text-[10px] text-zinc-500 mt-1 flex items-center justify-center gap-1">
                                        <span class="material-symbols-outlined text-[12px]">schedule</span>
                                        <span class="card-timer font-bold text-zinc-700" 
                                              data-start="${san.gioBatDauActive}" 
                                              data-end="${san.gioKetThucActive}" 
                                              data-note="${san.ghiChuActive}">Bắt đầu: ${san.gioBatDauActive}</span>
                                    </p>
                                    
                                    <c:if test="${san.ghiChuActive != null && san.ghiChuActive.contains('Không cố định') && !san.ghiChuActive.contains('Đã chốt giờ thực tế')}">
                                        <form action="${pageContext.request.contextPath}/staff/checkin" method="post" class="w-full mt-2" onsubmit="return confirm('Bạn có chắc chắn muốn dừng chơi và chốt giờ thực tế cho ca này?');">
                                            <input type="hidden" name="action" value="stopOpenSession">
                                            <input type="hidden" name="datSanId" value="${san.datSanIdActive}">
                                            <button type="submit" class="w-full bg-red-550 hover:bg-red-700 text-white font-extrabold text-[10px] py-2 rounded-xl shadow-sm hover:shadow transition-all active:scale-95 flex items-center justify-center gap-1">
                                                <span class="material-symbols-outlined text-[12px]">stop_circle</span>
                                                Dừng chơi & Tính tiền
                                            </button>
                                        </form>
                                    </c:if>
                                    <button type="button" onclick="openStaffInvoiceModal(${san.datSanIdActive})" class="w-full mt-3 ${themeBg} ${themeBgHover} text-white font-extrabold text-[10px] py-2 rounded-xl shadow-sm hover:shadow transition-all active:scale-95">
                                        Dịch vụ & Thanh toán
                                    </button>
                                </c:when>
                                <c:when test="${san.trangThai == 'Sẵn sàng' && san.hasUpcomingBooking}">
                                    <span class="absolute top-2.5 right-2.5 w-2 h-2 rounded-full bg-amber-500 animate-pulse"></span>
                                    <div class="w-12 h-12 rounded-2xl bg-amber-50 flex items-center justify-center text-amber-600 mb-2">
                                        <span class="material-symbols-outlined text-[24px]">event_upcoming</span>
                                    </div>
                                    <h4 class="font-bold text-sm text-zinc-800">${san.tenSan}</h4>
                                    <p class="text-[10px] text-zinc-500 font-medium">${san.tenLoaiSan}</p>
                                    <span class="badge badge-amber mt-2 uppercase text-[10px]">Sắp có lịch đặt</span>

                                    <div class="w-full mt-2 text-left text-[10px] text-zinc-600 space-y-0.5">
                                        <p class="font-bold text-zinc-800 truncate flex items-center gap-1">
                                            <span class="material-symbols-outlined text-[12px]">person</span>${san.nextTenKhachHang}
                                        </p>
                                        <p class="flex items-center gap-1">
                                            <span class="material-symbols-outlined text-[12px]">schedule</span>
                                            ${san.nextGioBatDau.toString().substring(11,16)} – ${san.nextGioKetThuc.toString().substring(11,16)}
                                            <span class="badge badge-gray text-[8px] uppercase ml-1">${san.nextNguonDatSan}</span>
                                        </p>
                                    </div>
                                    <p class="text-[10px] mt-1.5 flex items-center justify-center gap-1">
                                        <span class="material-symbols-outlined text-[12px] text-amber-600">hourglass_top</span>
                                        <span class="upcoming-timer font-bold text-amber-700" data-next-start="${san.nextGioBatDau}">Đang tính...</span>
                                    </p>

                                    <form action="${pageContext.request.contextPath}/staff/checkin" method="post" class="w-full mt-2">
                                        <input type="hidden" name="action" value="checkInPreBooked">
                                        <input type="hidden" name="datSanId" value="${san.nextDatSanId}">
                                        <input type="hidden" name="daThuTienMat" value="false">
                                        <button type="submit" onclick="event.stopPropagation();" class="w-full ${themeBg} ${themeBgHover} text-white font-extrabold text-[10px] py-2 rounded-xl shadow-sm hover:shadow transition-all active:scale-95 flex items-center justify-center gap-1">
                                            <span class="material-symbols-outlined text-[14px]">how_to_reg</span>
                                            Check-in khách
                                        </button>
                                    </form>
                                </c:when>
                                <c:when test="${san.trangThai == 'Sẵn sàng'}">
                                    <span class="absolute top-2.5 right-2.5 w-2 h-2 rounded-full bg-green-500"></span>
                                    <div class="w-12 h-12 rounded-2xl bg-green-50 flex items-center justify-center text-green-600 mb-2">
                                        <span class="material-symbols-outlined text-[24px]">sports_soccer</span>
                                    </div>
                                    <h4 class="font-bold text-sm text-zinc-800">${san.tenSan}</h4>
                                    <p class="text-[10px] text-zinc-500 font-medium">${san.tenLoaiSan}</p>
                                    <span class="badge badge-green mt-2 uppercase text-[10px]">Sẵn sàng</span>

                                    <button type="button" onclick="openCourtDetailDrawer(${san.sanID})" class="w-full mt-3 ${themeBg} ${themeBgHover} text-white font-extrabold text-[10px] py-2 rounded-xl shadow-sm hover:shadow transition-all active:scale-95">
                                        Mở sân
                                    </button>
                                </c:when>
                                <c:when test="${san.trangThai == 'Bảo trì'}">
                                    <span class="absolute top-2.5 right-2.5 w-2 h-2 rounded-full bg-amber-500"></span>
                                    <div class="w-12 h-12 rounded-2xl bg-amber-50 flex items-center justify-center text-amber-600 mb-2">
                                        <span class="material-symbols-outlined text-[24px]">build</span>
                                    </div>
                                    <h4 class="font-bold text-sm text-zinc-850 opacity-60">${san.tenSan}</h4>
                                    <p class="text-[10px] text-zinc-500 font-medium">${san.tenLoaiSan}</p>
                                    <span class="badge badge-amber mt-2 uppercase text-[10px]">Bảo trì</span>
                                    
                                    <button type="button" onclick="openCourtDetailDrawer(${san.sanID})" class="w-full mt-3 bg-zinc-150 text-zinc-600 hover:bg-zinc-200 transition-colors font-extrabold text-[10px] py-2 rounded-xl">
                                        Chi tiết
                                    </button>
                                </c:when>
                                <c:otherwise>
                                    <span class="absolute top-2.5 right-2.5 w-2 h-2 rounded-full bg-red-500"></span>
                                    <div class="w-12 h-12 rounded-2xl bg-red-50 flex items-center justify-center text-red-650 mb-2">
                                        <span class="material-symbols-outlined text-[24px]">block</span>
                                    </div>
                                    <h4 class="font-bold text-sm text-zinc-850 opacity-60">${san.tenSan}</h4>
                                    <p class="text-[10px] text-zinc-500 font-medium">${san.tenLoaiSan}</p>
                                    <span class="badge badge-red mt-2 uppercase text-[10px]">Tạm đóng</span>
                                    
                                    <button type="button" onclick="openCourtDetailDrawer(${san.sanID})" class="w-full mt-3 bg-zinc-150 text-zinc-600 hover:bg-zinc-200 transition-colors font-extrabold text-[10px] py-2 rounded-xl">
                                        Chi tiết
                                    </button>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>
                </c:forEach>
            </c:otherwise>
        </c:choose>
    </section>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <!-- 4. DANH SÁCH LỊCH ĐẶT SÂN TRONG NGÀY (Today's Bookings Schedule Dashboard) -->
        <section class="card p-5 xl:col-span-3 border ${themeBorder} overflow-hidden flex flex-col justify-between">
            <div>
                <!-- Header with Tabs -->
                <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between border-b ${themeBorder} pb-4 mb-5 gap-4">
                    <h3 class="text-base font-black ${themeTextDark} tracking-tight flex items-center gap-2">
                        <span class="material-symbols-outlined ${themeIcon}">calendar_today</span>
                        Vận Hành & Check-in Hôm Nay
                    </h3>
                    
                    <div class="flex bg-zinc-100 p-1 rounded-xl text-xs font-bold gap-1 self-start lg:self-auto shadow-inner">
                        <button type="button" id="tab-btn-playing" onclick="switchBookingTab('playing')" class="flex items-center gap-2 px-4 py-2 rounded-lg transition-all text-zinc-555 hover:text-zinc-800">
                            <span class="material-symbols-outlined text-[16px]">sports_soccer</span>
                            Đang chơi
                            <span id="badge-count-playing" class="bg-emerald-500 text-white px-2 py-0.5 rounded-full text-[10px] font-extrabold">0</span>
                        </button>
                        <button type="button" id="tab-btn-waiting" onclick="switchBookingTab('waiting')" class="flex items-center gap-2 px-4 py-2 rounded-lg transition-all text-zinc-555 hover:text-zinc-800">
                            <span class="material-symbols-outlined text-[16px]">schedule</span>
                            Chờ check-in
                            <span id="badge-count-waiting" class="bg-amber-500 text-white px-2 py-0.5 rounded-full text-[10px] font-extrabold">0</span>
                        </button>
                        <button type="button" id="tab-btn-completed" onclick="switchBookingTab('completed')" class="flex items-center gap-2 px-4 py-2 rounded-lg transition-all text-zinc-500 hover:text-zinc-700">
                            <span class="material-symbols-outlined text-[16px]">check_circle</span>
                            Đã xong hôm nay
                            <span id="badge-count-completed" class="bg-zinc-400 text-white px-2 py-0.5 rounded-full text-[10px] font-extrabold">0</span>
                        </button>
                        <button type="button" id="tab-btn-preorders" onclick="switchBookingTab('preorders')" class="flex items-center gap-2 px-4 py-2 rounded-lg transition-all text-zinc-500 hover:text-zinc-700">
                            <span class="material-symbols-outlined text-[16px]">local_cafe</span>
                            Dịch vụ đặt trước
                            <span id="badge-count-preorders" class="bg-amber-500 text-white px-2 py-0.5 rounded-full text-[10px] font-extrabold">0</span>
                        </button>
                    </div>
                </div>

                <!-- Search Input -->
                <div class="mb-5 relative">
                    <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                        <span class="material-symbols-outlined text-zinc-450 text-[18px]">search</span>
                    </div>
                    <input type="text" id="booking-search-input" oninput="onBookingSearch(this.value)" placeholder="Tìm kiếm nhanh ca chơi theo tên khách, số điện thoại hoặc sân..." class="w-full text-xs pl-10 pr-4 py-2.5 border border-zinc-200 focus:border-zinc-400 rounded-xl bg-white focus:outline-none transition-all placeholder-zinc-400 text-zinc-800">
                </div>

                <!-- Tab Contents -->
                <!-- Tab 1: Playing -->
                <div id="tab-content-playing" class="tab-pane hidden">
                    <div id="list-playing" class="flex flex-col gap-2.5">
                        <!-- Filled by JS -->
                    </div>
                </div>

                <!-- Tab 2: Waiting -->
                <div id="tab-content-waiting" class="tab-pane hidden">
                    <div id="list-waiting" class="flex flex-col gap-2.5">
                        <!-- Filled by JS -->
                    </div>
                </div>

                <!-- Tab 3: Completed -->
                <div id="tab-content-completed" class="tab-pane hidden">
                    <div id="list-completed" class="flex flex-col gap-2.5">
                        <!-- Filled by JS -->
                    </div>
                </div>

                <!-- Tab 4: Dịch vụ khách đặt trước (Phase 8A) -->
                <div id="tab-content-preorders" class="tab-pane hidden">
                    <div id="preorders-loading" class="text-xs text-zinc-400 py-4 text-center hidden">Đang tải...</div>
                    <div id="preorders-empty" class="text-xs text-zinc-400 py-4 text-center hidden">Chưa có dịch vụ nào được khách đặt trước hôm nay.</div>
                    <div id="list-preorders" class="flex flex-col gap-2.5"></div>
                </div>
            </div>

            <!-- Helpful tips -->
            <div class="mt-6 p-3 bg-zinc-50 border border-zinc-200 rounded-xl text-[10px] text-zinc-550 flex items-center gap-2">
                <span class="material-symbols-outlined text-zinc-400 text-[16px]">info</span>
                <span>Mẹo: Staff có thể nhấn vào biểu tượng <span class="material-symbols-outlined text-[12px] inline-block align-middle text-[#630ed4]">content_copy</span> để copy nhanh số điện thoại của khách hàng, hoặc click số điện thoại để gọi.</span>
            </div>
        </section>
    </div>

</main>

<script>
    let drawerTimerInterval = null;

    // Server là source of truth cho thời gian - mọi đồng hồ đếm ngược trên trang tính theo
    // offset này thay vì tin đồng hồ thiết bị. Được resync mỗi lần poll dữ liệu (30s) và khi
    // tab quay lại foreground, nên không lệch nhiều theo thời gian.
    let serverTimeOffsetMs = 0;
    try {
        const sNowStr = "${serverNow}";
        if (sNowStr) {
            const parsedTime = new Date(sNowStr).getTime();
            if (!isNaN(parsedTime)) {
                serverTimeOffsetMs = parsedTime - Date.now();
            }
        }
    } catch (e) {
        console.error("Lỗi đồng bộ thời gian máy chủ:", e);
    }
    function getServerNow() { return new Date(Date.now() + serverTimeOffsetMs); }

    const UPCOMING_BOOKING_WARNING_MINUTES = ${not empty upcomingBookingWarningMinutes ? upcomingBookingWarningMinutes : 15};
    const ENDING_SOON_MINUTES = ${not empty endingSoonMinutes ? endingSoonMinutes : 15};

    const isManager = ${isManager ? 'true' : 'false'};
    const themeBg = '${themeBg}';
    const themeBgHover = '${themeBgHover}';
    const themeText = '${themeText}';
    const themeTextMedium = '${themeTextMedium}';
    const themeBorder = '${themeBorder}';
    const themeBorderStrong = '${themeBorderStrong}';
    const themeBgLight = '${themeBgLight}';
    const themeIcon = '${themeIcon}';
    const badgeTheme = '${badgeTheme}';
    const focusRing = '${focusRing}';
    let localDanhSachLich = [
        <c:forEach var="b" items="${danhSachLich}" varStatus="status">
            {
                datSanId: ${b.datSanId},
                sanId: ${b.sanId},
                tenSan: `${b.tenSan}`,
                tenKhachHang: `${b.tenKhachHang}`,
                soDienThoai: `${b.soDienThoai != null ? b.soDienThoai : ''}`,
                tenLoaiSan: `${b.tenLoaiSan != null ? b.tenLoaiSan : ''}`,
                gioBatDau: "${b.gioBatDau != null ? b.gioBatDau.toString().substring(0,5) : '00:00'}",
                gioKetThuc: "${b.gioKetThuc != null ? b.gioKetThuc.toString().substring(0,5) : '00:00'}",
                tongTien: ${b.tongTien != null ? b.tongTien : 0},
                trangThai: "${b.trangThai}",
                ghiChu: `${b.ghiChu != null ? b.ghiChu : ''}`,
                trangThaiThanhToan: "${b.trangThaiThanhToan}",
                nguonDatSan: "${b.nguonDatSan}"
            }<c:if test="${not status.last}">,</c:if>
        </c:forEach>
    ];

    let activeBookingTab = null;
    let bookingSearchQuery = "";

    function onBookingSearch(val) {
        bookingSearchQuery = val.trim().toLowerCase();
        renderBookings();
    }

    function switchBookingTab(tabName) {
        activeBookingTab = tabName;
        
        // Hide all tab panes
        document.querySelectorAll('.tab-pane').forEach(el => el.classList.add('hidden'));
        
        // Remove active styling from all tab buttons
        document.querySelectorAll('[id^="tab-btn-"]').forEach(btn => {
            btn.className = "flex items-center gap-2 px-4 py-2 rounded-lg transition-all text-zinc-550 hover:text-zinc-800";
        });
        
        // Show current tab pane
        const activePane = document.getElementById("tab-content-" + tabName);
        if (activePane) activePane.classList.remove('hidden');
        
        // Set active styling on current button
        const activeBtn = document.getElementById("tab-btn-" + tabName);
        if (activeBtn) {
            if (tabName === 'playing') {
                activeBtn.className = "flex items-center gap-2 px-4 py-2 rounded-lg transition-all bg-emerald-500 text-white shadow-md";
            } else if (tabName === 'waiting') {
                activeBtn.className = "flex items-center gap-2 px-4 py-2 rounded-lg transition-all " + themeBg + " text-white shadow-md";
            } else if (tabName === 'preorders') {
                activeBtn.className = "flex items-center gap-2 px-4 py-2 rounded-lg transition-all bg-amber-500 text-white shadow-md";
                loadPreOrders();
            } else {
                activeBtn.className = "flex items-center gap-2 px-4 py-2 rounded-lg transition-all bg-zinc-650 text-white shadow-md";
            }
        }
    }

    // ===== Dịch vụ khách đặt trước (Phase 8A) — độc lập với panel "Dịch vụ & Thanh toán" cũ =====
    function loadPreOrders() {
        const loadingEl = document.getElementById("preorders-loading");
        const emptyEl = document.getElementById("preorders-empty");
        const listEl = document.getElementById("list-preorders");
        if (!listEl) return;
        listEl.innerHTML = "";
        emptyEl.classList.add("hidden");
        loadingEl.classList.remove("hidden");
        fetch("<c:url value='/staff/booking-service/update-status'/>?action=list")
            .then(r => r.json())
            .then(data => {
                loadingEl.classList.add("hidden");
                renderPreOrders(data.items || []);
            })
            .catch(() => {
                loadingEl.classList.add("hidden");
                emptyEl.textContent = "Không tải được danh sách dịch vụ đặt trước.";
                emptyEl.classList.remove("hidden");
            });
    }

    function preOrderStatusBadge(status) {
        if (status === 'Đã giao') return '<span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-700">Đã giao</span>';
        if (status === 'Đã hủy') return '<span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-zinc-200 text-zinc-500">Đã hủy</span>';
        return '<span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-100 text-amber-700">Chờ chuẩn bị</span>';
    }

    function renderPreOrders(items) {
        const emptyEl = document.getElementById("preorders-empty");
        const listEl = document.getElementById("list-preorders");
        const badge = document.getElementById("badge-count-preorders");
        const pendingCount = items.filter(it => it.status === 'Chờ chuẩn bị').length;
        if (badge) badge.textContent = pendingCount;

        if (!items.length) {
            listEl.innerHTML = "";
            emptyEl.textContent = "Chưa có dịch vụ nào được khách đặt trước hôm nay.";
            emptyEl.classList.remove("hidden");
            return;
        }
        emptyEl.classList.add("hidden");

        // Gộp theo DatSanID để lễ tân dễ nhìn theo từng đơn
        const grouped = {};
        items.forEach(it => {
            if (!grouped[it.datSanId]) grouped[it.datSanId] = { info: it, lines: [] };
            grouped[it.datSanId].lines.push(it);
        });

        listEl.innerHTML = Object.values(grouped).map(g => {
            const info = g.info;
            const linesHtml = g.lines.map(it => `
                <div class="flex items-center justify-between gap-2 py-1.5 border-b border-zinc-100 last:border-0">
                    <div class="min-w-0">
                        <p class="text-xs font-bold text-zinc-800">\${it.tenSanPham} <span class="text-zinc-400 font-normal">x\${it.quantity}</span></p>
                        <p class="text-[10px] text-zinc-400">\${Math.round(it.totalPrice).toLocaleString('vi-VN')} đ \${preOrderStatusBadge(it.status)}</p>
                    </div>
                    \${it.status === 'Chờ chuẩn bị' ? `
                    <div class="flex items-center gap-1.5 flex-shrink-0">
                        <button type="button" onclick="updatePreOrderStatus(\${it.id}, 'deliver')" class="text-[10px] font-bold px-2.5 py-1.5 rounded-lg bg-emerald-500 text-white hover:bg-emerald-600">Đã giao</button>
                        <button type="button" onclick="updatePreOrderStatus(\${it.id}, 'cancel')" class="text-[10px] font-bold px-2.5 py-1.5 rounded-lg bg-zinc-200 text-zinc-600 hover:bg-zinc-300">Hủy</button>
                    </div>` : ''}
                </div>`).join("");
            return `
            <div class="p-3 border border-zinc-200 rounded-xl bg-white">
                <div class="flex items-center justify-between mb-1.5">
                    <p class="text-xs font-black text-zinc-800">\${info.tenKhachHang} · \${info.tenSan}</p>
                    <p class="text-[10px] text-zinc-400 font-bold">\${info.gioBatDau || ''} - \${info.gioKetThuc || ''}</p>
                </div>
                \${linesHtml}
            </div>`;
        }).join("");
    }

    function updatePreOrderStatus(id, action) {
        if (action === 'cancel' && !confirm('Xác nhận hủy dịch vụ này?')) return;
        fetch("<c:url value='/staff/booking-service/update-status'/>", {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
            body: new URLSearchParams({ action: action, id: id }).toString()
        }).then(r => r.json()).then(data => {
            if (data.success) {
                loadPreOrders();
            } else {
                alert(data.error || "Không thể cập nhật trạng thái dịch vụ.");
            }
        }).catch(() => alert("Có lỗi xảy ra khi cập nhật trạng thái dịch vụ."));
    }

    function copyToClipboard(text, btnEl) {
        if (!navigator.clipboard) {
            const textarea = document.createElement('textarea');
            textarea.value = text;
            textarea.style.position = 'fixed';
            document.body.appendChild(textarea);
            textarea.select();
            try {
                document.execCommand('copy');
                const icon = btnEl.querySelector('.material-symbols-outlined');
                if (icon) {
                    icon.textContent = 'check';
                    icon.classList.remove('text-zinc-450');
                    icon.classList.add('text-green-600');
                    setTimeout(() => {
                        icon.textContent = 'content_copy';
                        icon.classList.remove('text-green-600');
                        icon.classList.add('text-zinc-450');
                    }, 1500);
                }
            } catch (err) {
                console.error('Fallback copy failed', err);
            }
            document.body.removeChild(textarea);
            return;
        }
        navigator.clipboard.writeText(text).then(() => {
            const icon = btnEl.querySelector('.material-symbols-outlined');
            if (icon) {
                icon.textContent = 'check';
                icon.classList.remove('text-zinc-450');
                icon.classList.add('text-green-600');
                setTimeout(() => {
                    icon.textContent = 'content_copy';
                    icon.classList.remove('text-green-600');
                    icon.classList.add('text-zinc-450');
                }, 1500);
            }
        }).catch(err => {
            console.error('Failed to copy: ', err);
        });
    }

    function renderBookings() {
        const playingContainer = document.getElementById('list-playing');
        const waitingContainer = document.getElementById('list-waiting');
        const completedContainer = document.getElementById('list-completed');
        
        if (!playingContainer || !waitingContainer || !completedContainer) return;
        
        playingContainer.innerHTML = '';
        waitingContainer.innerHTML = '';
        completedContainer.innerHTML = '';
        
        // Filter by search query if any
        let list = localDanhSachLich || [];
        if (bookingSearchQuery) {
            list = list.filter(b => 
                (b.tenKhachHang && b.tenKhachHang.toLowerCase().includes(bookingSearchQuery)) ||
                (b.soDienThoai && b.soDienThoai.toLowerCase().includes(bookingSearchQuery)) ||
                (b.tenSan && b.tenSan.toLowerCase().includes(bookingSearchQuery))
            );
        }
        
        let countPlaying = 0;
        let countWaiting = 0;
        let countCompleted = 0;
        
        list.forEach(b => {
            const batDau = b.gioBatDau;
            const ketThuc = b.gioKetThuc;
            const formattedTongTien = formatCurrency(b.tongTien);
            const statusBadgeClass = b.trangThaiThanhToan === 'Đã thanh toán' ? 'badge-green' : 'badge-amber';
            const nguonBadgeClass = b.nguonDatSan === 'Walk-in' ? 'badge-gray' : 'badge-blue';
            
            // Determine booking status badge theme
            let statusTheme = 'badge-gray';
            if (b.trangThai === 'Đang sử dụng' || b.trangThai === 'Đang chơi') {
                statusTheme = 'badge-green';
            } else if (b.trangThai === 'Đã xác nhận') {
                statusTheme = 'badge-green';
            } else if (b.trangThai === 'Chờ xác nhận') {
                statusTheme = 'badge-amber';
            }
            
            const hasPhone = b.soDienThoai && b.soDienThoai.trim().length > 0;
            const phoneActionHtml = hasPhone ? `
                <div class="flex items-center gap-1 font-mono">
                    <a href="tel:\${b.soDienThoai}" class="hover:underline text-[#630ed4] font-bold">\${b.soDienThoai}</a>
                    <button type="button" onclick="copyToClipboard('\${b.soDienThoai}', this)" class="text-zinc-450 hover:text-[#630ed4] transition-colors p-0.5" title="Copy số điện thoại">
                        <span class="material-symbols-outlined text-[13px]">content_copy</span>
                    </button>
                </div>
            ` : '<span class="text-zinc-450">Không có SĐT</span>';
            
            if (b.trangThai === 'Đang sử dụng' || b.trangThai === 'Đang chơi') {
                countPlaying++;
                playingContainer.insertAdjacentHTML('beforeend', `
                    <div class="border border-emerald-200 hover:border-emerald-350 bg-emerald-50/5 rounded-xl px-4 py-2.5 flex flex-col md:flex-row md:items-center justify-between gap-3 shadow-sm transition-all duration-200 group text-xs">
                        <div class="flex flex-wrap items-center gap-x-6 gap-y-2 flex-1 min-w-0">
                            <!-- Sân -->
                            <div class="flex items-center gap-2 min-w-[160px] truncate">
                                <span class="w-2.5 h-2.5 rounded-full bg-emerald-500 shrink-0 animate-pulse"></span>
                                <div>
                                    <div class="font-black text-zinc-800 truncate">\${b.tenSan}</div>
                                    <div class="text-[9px] font-semibold text-emerald-700 px-1 py-0.5 bg-emerald-50 rounded inline-block mt-0.5">\${b.tenLoaiSan || 'Sân bóng'}</div>
                                </div>
                            </div>

                            <!-- Khách hàng -->
                            <div class="flex items-center gap-2 min-w-[180px] truncate">
                                <span class="material-symbols-outlined text-[16px] text-zinc-450 shrink-0">person</span>
                                <div class="truncate">
                                    <div class="font-extrabold text-zinc-800 truncate" title="\${b.tenKhachHang}">\${b.tenKhachHang}</div>
                                    <div class="mt-0.5">\${phoneActionHtml}</div>
                                </div>
                            </div>

                            <!-- Ca chơi -->
                            <div class="flex items-center gap-2 min-w-[130px] font-mono font-bold text-zinc-650">
                                <span class="material-symbols-outlined text-[15px] text-zinc-450 shrink-0">schedule</span>
                                <span>\${batDau} - \${ketThuc}</span>
                            </div>

                            <!-- Trạng thái / Thanh toán -->
                            <div class="flex items-center gap-2 min-w-[160px] shrink-0">
                                <span class="badge \${statusBadgeClass} text-[9px]">\${b.trangThaiThanhToan}</span>
                                <span class="badge \${nguonBadgeClass} text-[8px] uppercase tracking-wider">\${b.nguonDatSan}</span>
                            </div>

                            <!-- Timer -->
                            <div class="flex items-center gap-2 min-w-[150px] bg-emerald-50 border border-emerald-100/80 px-2.5 py-1 rounded-lg text-emerald-800 text-[11px] font-semibold shrink-0">
                                <span class="material-symbols-outlined text-[14px]">play_circle</span>
                                <span class="font-black card-timer animate-pulse" data-start="\${b.gioBatDau}" data-end="\${b.gioKetThuc}" data-note="\${b.ghiChu}">-</span>
                            </div>

                            <!-- Ghi chú (nếu có) -->
                            <div class="min-w-[100px] flex-1 max-w-[200px] truncate text-[10px] text-zinc-400 italic">
                                \${b.ghiChu ? `<span>Ghi chú: \${b.ghiChu}</span>` : ''}
                            </div>
                        </div>

                        <!-- Actions -->
                        <div class="shrink-0 flex items-center justify-end">
                            <button type="button" onclick="openStaffInvoiceModal(\${b.datSanId})" class="\${themeBg} \${themeBgHover} text-white font-extrabold text-[10.5px] px-3.5 py-2 rounded-lg shadow-sm hover:shadow transition-all active:scale-95 flex items-center gap-1">
                                <span class="material-symbols-outlined text-[15px]">receipt_long</span>
                                Dịch vụ &amp; Thanh toán
                            </button>
                        </div>
                    </div>
                `);
            } else if (b.trangThai === 'Đã xác nhận' || b.trangThai === 'Chờ xác nhận') {
                countWaiting++;
                
                let checkinBtnText = b.trangThai === 'Đã xác nhận' ? "Check-in khách" : "Mở sân";
                let checkinAction = "checkInPreBooked";
                
                waitingContainer.insertAdjacentHTML('beforeend', `
                    <div class="border border-zinc-200 hover:border-zinc-300 bg-white rounded-xl px-4 py-2.5 flex flex-col md:flex-row md:items-center justify-between gap-3 shadow-sm transition-all duration-200 group text-xs">
                        <div class="flex flex-wrap items-center gap-x-6 gap-y-2 flex-1 min-w-0">
                            <!-- Sân -->
                            <div class="flex items-center gap-2 min-w-[160px] truncate">
                                <span class="w-2 h-2 rounded-full bg-amber-500 shrink-0"></span>
                                <div>
                                    <div class="font-black text-zinc-800 truncate">\${b.tenSan}</div>
                                    <div class="text-[9px] font-semibold text-zinc-500 px-1 py-0.5 bg-zinc-100 rounded inline-block mt-0.5">\${b.tenLoaiSan || 'Sân bóng'}</div>
                                </div>
                            </div>

                            <!-- Khách hàng -->
                            <div class="flex items-center gap-2 min-w-[180px] truncate">
                                <span class="material-symbols-outlined text-[16px] text-zinc-450 shrink-0">person</span>
                                <div class="truncate">
                                    <div class="font-extrabold text-zinc-800 truncate" title="\${b.tenKhachHang}">\${b.tenKhachHang}</div>
                                    <div class="mt-0.5">\${phoneActionHtml}</div>
                                </div>
                            </div>

                            <!-- Ca chơi -->
                            <div class="flex items-center gap-2 min-w-[130px] font-mono font-bold text-zinc-650">
                                <span class="material-symbols-outlined text-[15px] text-zinc-450 shrink-0">schedule</span>
                                <span>\${batDau} - \${ketThuc}</span>
                            </div>

                            <!-- Trạng thái / Thanh toán -->
                            <div class="flex items-center gap-2 min-w-[200px] shrink-0">
                                <span class="badge \${statusBadgeClass} text-[9px]">\${b.trangThaiThanhToan}</span>
                                <span class="badge \${statusTheme} text-[8px] uppercase font-bold tracking-tight">\${b.trangThai === 'Chờ xác nhận' ? 'Chờ duyệt' : b.trangThai}</span>
                                <span class="badge \${nguonBadgeClass} text-[8px] uppercase tracking-wider">\${b.nguonDatSan}</span>
                            </div>

                            <!-- Ghi chú (nếu có) -->
                            <div class="min-w-[100px] flex-1 max-w-[200px] truncate text-[10px] text-zinc-400 italic">
                                \${b.ghiChu ? `<span>Ghi chú: \${b.ghiChu}</span>` : ''}
                            </div>
                        </div>

                        <!-- Actions -->
                        <div class="shrink-0 flex items-center justify-end gap-2">
                            <form action="${pageContext.request.contextPath}/staff/checkin" method="post" class="inline-block">
                                <input type="hidden" name="action" value="\${checkinAction}">
                                <input type="hidden" name="datSanId" value="\${b.datSanId}">
                                <input type="hidden" name="daThuTienMat" value="false">
                                <button type="submit" class="\${themeBg} \${themeBgHover} text-white font-extrabold text-[10.5px] px-3.5 py-2 rounded-lg shadow-sm hover:shadow transition-all active:scale-95 flex items-center gap-1">
                                    <span class="material-symbols-outlined text-[14px]">power_settings_new</span>
                                    \${checkinBtnText}
                                </button>
                            </form>
                            <button type="button" onclick="openNoShowModal(\${b.datSanId}, '\${escapeForInlineOnclickJsString(b.tenKhachHang)}', \${b.reputationScore != null ? b.reputationScore : 'null'})"
                                    class="bg-rose-50 hover:bg-rose-100 text-rose-600 font-extrabold text-[10.5px] px-2.5 py-2 rounded-lg transition-all active:scale-95 flex items-center justify-center" title="Hủy ca do khách không đến">
                                <span class="material-symbols-outlined text-[15px]">cancel</span>
                            </button>
                        </div>
                    </div>
                `);
            } else {
                countCompleted++;
                completedContainer.insertAdjacentHTML('beforeend', `
                    <div class="border border-zinc-200 bg-zinc-50/50 opacity-90 hover:opacity-100 rounded-xl px-4 py-2.5 flex flex-col md:flex-row md:items-center justify-between gap-3 shadow-sm transition-all duration-200 group text-xs">
                        <div class="flex flex-wrap items-center gap-x-6 gap-y-2 flex-1 min-w-0">
                            <!-- Sân -->
                            <div class="flex items-center gap-2 min-w-[160px] truncate">
                                <span class="w-2 h-2 rounded-full bg-zinc-400 shrink-0"></span>
                                <div>
                                    <div class="font-black text-zinc-700 truncate">\${b.tenSan}</div>
                                    <div class="text-[9px] font-semibold text-zinc-500 px-1 py-0.5 bg-zinc-100 rounded inline-block mt-0.5">\${b.tenLoaiSan || 'Sân bóng'}</div>
                                </div>
                            </div>

                            <!-- Khách hàng -->
                            <div class="flex items-center gap-2 min-w-[180px] truncate">
                                <span class="material-symbols-outlined text-[16px] text-zinc-450 shrink-0">person</span>
                                <div class="truncate">
                                    <div class="font-extrabold text-zinc-700 truncate" title="\${b.tenKhachHang}">\${b.tenKhachHang}</div>
                                    <div class="text-[10px] text-zinc-500 font-mono mt-0.5">\${b.soDienThoai || '---'}</div>
                                </div>
                            </div>

                            <!-- Ca chơi -->
                            <div class="flex items-center gap-2 min-w-[130px] font-mono font-medium text-zinc-500">
                                <span class="material-symbols-outlined text-[15px] text-zinc-400 shrink-0">schedule</span>
                                <span>\${batDau} - \${ketThuc}</span>
                            </div>

                            <!-- Nguồn đặt sân -->
                            <div class="flex items-center gap-2 min-w-[90px] shrink-0">
                                <span class="badge \${nguonBadgeClass} text-[8px] uppercase tracking-wider">\${b.nguonDatSan}</span>
                                <span class="badge badge-gray text-[8px] uppercase font-bold tracking-tight">\${b.trangThai}</span>
                            </div>

                            <!-- Tổng tiền -->
                            <div class="flex items-center gap-2 min-w-[120px] shrink-0 font-extrabold text-zinc-800">
                                <span class="text-zinc-450 text-[10px] font-medium">Tổng tiền:</span>
                                <span>\${formattedTongTien}</span>
                            </div>

                            <!-- Ghi chú (nếu có) -->
                            <div class="min-w-[100px] flex-1 max-w-[200px] truncate text-[10px] text-zinc-400 italic">
                                \${b.ghiChu ? `<span>Ghi chú: \${b.ghiChu}</span>` : ''}
                            </div>
                        </div>

                        <!-- Trạng thái HĐ -->
                        <div class="shrink-0 flex items-center justify-end">
                            <div class="px-3 py-1.5 rounded-lg bg-zinc-100 border border-zinc-200 text-zinc-600 text-[10px] font-semibold">
                                <span class="font-medium text-zinc-450">Trạng thái HD:</span>
                                <span class="font-bold uppercase ml-1 \${b.trangThaiThanhToan === 'Đã thanh toán' ? 'text-emerald-700' : 'text-amber-700'}">\${b.trangThaiThanhToan}</span>
                            </div>
                        </div>
                    </div>
                `);
            }
        });
        
        // Show empty states if counters are 0
        if (countPlaying === 0) {
            playingContainer.innerHTML = `
                <div class="col-span-full py-12 text-center text-xs text-zinc-450 italic bg-zinc-50 rounded-2xl border border-dashed border-zinc-200 flex flex-col items-center justify-center gap-2">
                    <span class="material-symbols-outlined text-[32px] text-zinc-300">sports_soccer</span>
                    Hiện chưa có ca chơi nào đang hoạt động.
                </div>
            `;
        }
        if (countWaiting === 0) {
            waitingContainer.innerHTML = `
                <div class="col-span-full py-12 text-center text-xs text-zinc-450 italic bg-zinc-50 rounded-2xl border border-dashed border-zinc-200 flex flex-col items-center justify-center gap-2">
                    <span class="material-symbols-outlined text-[32px] text-zinc-300">schedule</span>
                    Không có lịch chờ check-in nào trong ngày hôm nay.
                </div>
            `;
        }
        if (countCompleted === 0) {
            completedContainer.innerHTML = `
                <div class="col-span-full py-12 text-center text-xs text-zinc-450 italic bg-zinc-50 rounded-2xl border border-dashed border-zinc-200 flex flex-col items-center justify-center gap-2">
                    <span class="material-symbols-outlined text-[32px] text-zinc-300">check_circle</span>
                    Chưa ghi nhận ca chơi hoàn thành nào hôm nay.
                </div>
            `;
        }
        
        // Update badge counts on tabs
        document.getElementById('badge-count-playing').textContent = countPlaying;
        document.getElementById('badge-count-waiting').textContent = countWaiting;
        document.getElementById('badge-count-completed').textContent = countCompleted;
        
        // Auto-select active tab on initial render
        if (activeBookingTab === null) {
            const hasPlaying = localDanhSachLich.some(b => b.trangThai === 'Đang sử dụng' || b.trangThai === 'Đang chơi');
            switchBookingTab(hasPlaying ? 'playing' : 'waiting');
        } else {
            switchBookingTab(activeBookingTab);
        }
    }

    // Convert time string "HH:MM" or "HH:MM:SS" to a Date object today
    function parseTimeToDate(timeStr) {
        if (!timeStr) return null;
        const parts = timeStr.split(':');
        if (parts.length < 2) return null;
        const d = new Date();
        d.setHours(parseInt(parts[0], 10), parseInt(parts[1], 10), 0, 0);
        return d;
    }

    // Get correct start and end Date objects, handling potential overnight wrap-around
    function getTimerDates(startStr, endStr) {
        const startDate = parseTimeToDate(startStr);
        let endDate = parseTimeToDate(endStr);
        if (startDate && endDate && endDate < startDate) {
            // End time is on the next day
            endDate.setDate(endDate.getDate() + 1);
        }
        return { startDate, endDate };
    }

    // Format millisecond duration into HH:MM:SS
    function formatDuration(ms) {
        const totalSecs = Math.max(0, Math.floor(ms / 1000));
        const hrs = Math.floor(totalSecs / 3600);
        const mins = Math.floor((totalSecs % 3600) / 60);
        const secs = totalSecs % 60;
        
        const pad = (num) => String(num).padStart(2, '0');
        return pad(hrs) + ':' + pad(mins) + ':' + pad(secs);
    }

    // Update all card timers in the court grid
    function updateAllCardTimers() {
        const timers = document.querySelectorAll('.card-timer');
        const now = getServerNow();

        timers.forEach(timer => {
            const startStr = timer.getAttribute('data-start');
            const endStr = timer.getAttribute('data-end');
            const noteStr = timer.getAttribute('data-note') || '';
            if (!startStr) return;
            
            const isOpenMode = noteStr.includes('Không cố định');
            const { startDate, endDate } = getTimerDates(startStr, endStr);
            
            if (isOpenMode) {
                // Count up timer
                if (startDate) {
                    let elapsedMs = now - startDate;
                    if (elapsedMs < 0) elapsedMs += 24 * 60 * 60 * 1000;
                    timer.textContent = "Đã chơi: " + formatDuration(elapsedMs);
                    timer.className = "card-timer font-black text-emerald-650 animate-pulse";
                }
            } else {
                // Countdown timer
                if (startDate && endDate) {
                    if (now < startDate) {
                        timer.textContent = "Chờ bắt đầu";
                        timer.className = "card-timer font-bold text-zinc-500";
                    } else if (now >= endDate) {
                        const overtimeMs = now - endDate;
                        timer.textContent = "QUÁ GIỜ · Quá " + formatDuration(overtimeMs);
                        timer.className = "card-timer font-black text-rose-600 animate-bounce";
                    } else {
                        const remainingMs = endDate - now;
                        const remainingMins = remainingMs / 60000;
                        if (remainingMins <= ENDING_SOON_MINUTES) {
                            timer.textContent = "Sắp hết giờ · Còn " + formatDuration(remainingMs);
                            timer.className = "card-timer font-black text-rose-600 animate-pulse";
                        } else {
                            timer.textContent = "Còn lại: " + formatDuration(remainingMs);
                            timer.className = "card-timer font-bold " + themeText;
                        }
                    }
                }
            }
        });

        // Đồng hồ đếm ngược tới giờ bắt đầu cho các sân đang UPCOMING_BOOKING (đã xác nhận,
        // chưa check-in, sắp tới trong ngưỡng cảnh báo) - dùng chung 1 global timer, không tạo
        // interval riêng cho mỗi card.
        document.querySelectorAll('.upcoming-timer').forEach(timer => {
            const startIso = timer.getAttribute('data-next-start');
            if (!startIso) return;
            const startDate = new Date(startIso);
            if (isNaN(startDate.getTime())) return;

            const remainingMs = startDate - now;
            if (remainingMs <= 0) {
                // Đã tới/qua giờ hẹn mà vẫn chưa check-in - vẫn hiển thị mốc 00:00:00, không âm.
                timer.textContent = "Bắt đầu sau 00:00:00";
                timer.className = "upcoming-timer font-black text-rose-600 animate-pulse";
                return;
            }
            const remainingMins = remainingMs / 60000;
            timer.textContent = "Bắt đầu sau " + formatDuration(remainingMs);
            if (remainingMins <= ENDING_SOON_MINUTES) {
                timer.className = "upcoming-timer font-black text-rose-600 animate-pulse";
            } else {
                timer.className = "upcoming-timer font-bold text-amber-700";
            }
        });
    }

    // Start timer loop for the side drawer
    function startDrawerTimerLoop(startDate, endDate, isOpenMode, ratePerHour, baseCourtPrice) {
        if (drawerTimerInterval) {
            clearInterval(drawerTimerInterval);
        }
        
        const timerValEl = document.getElementById('drawer-active-timer-val');
        const timerRowEl = document.getElementById('drawer-active-timer-row');
        const timerLabelEl = document.getElementById('drawer-active-timer-label');
        const totalPriceEl = document.getElementById('drawer-active-total-price');
        
        function update() {
            const now = getServerNow();
            if (isOpenMode) {
                // Count-up mode
                if (startDate) {
                    let elapsedMs = now - startDate;
                    if (elapsedMs < 0) elapsedMs += 24 * 60 * 60 * 1000;
                    
                    if (timerValEl) timerValEl.textContent = formatDuration(elapsedMs);
                    if (timerLabelEl) timerLabelEl.textContent = "Đang đếm tới:";
                    
                    // Styling
                    if (timerRowEl) {
                        timerRowEl.className = "flex justify-between p-2.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800";
                    }
                    if (timerValEl) {
                        timerValEl.className = "font-black text-sm text-emerald-700 animate-pulse";
                    }
                    
                    // Real-time calculation of accrued price
                    const elapsedHours = (elapsedMs / 1000) / 3600.0;
                    const accruedPrice = elapsedHours * ratePerHour;
                    if (totalPriceEl) totalPriceEl.textContent = formatCurrency(accruedPrice);
                }
            } else {
                // Countdown mode
                if (startDate && endDate) {
                    if (now < startDate) {
                        if (timerValEl) timerValEl.textContent = "Chờ bắt đầu";
                        if (timerLabelEl) timerLabelEl.textContent = "Trạng thái:";
                        if (timerRowEl) timerRowEl.className = "flex justify-between p-2.5 rounded-xl bg-zinc-50 border border-zinc-200 text-zinc-800";
                        if (timerValEl) timerValEl.className = "font-bold text-sm text-zinc-650";
                        if (totalPriceEl) totalPriceEl.textContent = formatCurrency(baseCourtPrice);
                    } else if (now >= endDate) {
                        if (timerValEl) timerValEl.textContent = "Hết giờ chơi";
                        if (timerLabelEl) timerLabelEl.textContent = "Thời gian:";
                        if (timerRowEl) timerRowEl.className = "flex justify-between p-2.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 animate-pulse";
                        if (timerValEl) timerValEl.className = "font-black text-sm text-rose-700";
                        if (totalPriceEl) totalPriceEl.textContent = formatCurrency(baseCourtPrice);
                    } else {
                        const remainingMs = endDate - now;
                        if (timerValEl) timerValEl.textContent = formatDuration(remainingMs);
                        if (timerLabelEl) timerLabelEl.textContent = "Đếm ngược:";
                        
                        const remainingMins = remainingMs / 60000;
                        if (remainingMins <= 15) {
                            if (timerRowEl) timerRowEl.className = "flex justify-between p-2.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 animate-pulse";
                            if (timerValEl) timerValEl.className = "font-black text-sm text-rose-700";
                        } else {
                            if (timerRowEl) timerRowEl.className = `flex justify-between p-2.5 rounded-xl ${themeBgLight} border ${themeBorderStrong} ${themeTextMedium}`;
                            if (timerValEl) timerValEl.className = `font-black text-sm ${themeTextMedium}`;
                        }
                        if (totalPriceEl) totalPriceEl.textContent = formatCurrency(baseCourtPrice);
                    }
                }
            }
        }
        
        update();
        drawerTimerInterval = setInterval(update, 1000);
    }
    
    // Auto start grid timers and render bookings
    document.addEventListener("DOMContentLoaded", () => {
        renderBookings();
        updateAllCardTimers();
        setInterval(updateAllCardTimers, 1000);
    });

    // Responsive Mobile Menu handler
    const mobileMenuBtn = document.getElementById('mobileMenuBtn');
    if (mobileMenuBtn) {
        mobileMenuBtn.addEventListener('click', () => {
            const sidebar = document.querySelector('aside');
            if (sidebar) {
                sidebar.classList.toggle('-translate-x-full');
            }
        });
    }

    async function pollUpdates() {
        try {
            const response = await fetch('${pageContext.request.contextPath}/staff/checkin?ajax=true');
            if (!response.ok) return;
            const data = await response.json();

            // Resync server-time offset mỗi lần poll để tránh lệch dần nếu tab đứng yên lâu.
            if (data.serverNow) {
                serverTimeOffsetMs = new Date(data.serverNow).getTime() - Date.now();
            }

            if (data.danhSachLich) {
                localDanhSachLich = data.danhSachLich;
            }
            
            // Update dynamic stats counters
            if (data.danhSachSan) {
                let total = data.danhSachSan.length;
                let avail = 0, inUse = 0, maint = 0, closed = 0;
                data.danhSachSan.forEach(s => {
                    if (s.trangThai === 'Sẵn sàng') avail++;
                    else if (s.trangThai === 'Đang sử dụng') inUse++;
                    else if (s.trangThai === 'Bảo trì') maint++;
                    else closed++;
                });
                if(document.getElementById('stat-total')) document.getElementById('stat-total').textContent = total;
                if(document.getElementById('stat-available')) document.getElementById('stat-available').textContent = avail;
                if(document.getElementById('stat-in-use')) document.getElementById('stat-in-use').textContent = inUse;
                if(document.getElementById('stat-maintenance')) document.getElementById('stat-maintenance').textContent = maint;
                if(document.getElementById('stat-closed')) document.getElementById('stat-closed').textContent = closed;
            }
            if (data.danhSachLich && document.getElementById('stat-today')) {
                document.getElementById('stat-today').textContent = data.danhSachLich.length;
            }
            
            // 1. Cập nhật Real-time Field Status Grid
            const fieldGrid = document.getElementById('field-status-grid');
            if (fieldGrid && data.danhSachSan) {
                let htmlGrid = '';
                data.danhSachSan.forEach(san => {
                    const tenLoaiSan = san.tenLoaiSan || '';
                    const gioBatDauLenDenStr = san.gioBatDauLenDen || '';
                    const gioKetThucLenDenStr = san.gioKetThucLenDen || '';
                    
                    if (san.trangThai === 'Đang sử dụng') {
                        let stopButtonHtml = '';
                        if (san.ghiChuActive && san.ghiChuActive.includes('Không cố định') && !san.ghiChuActive.includes('Đã chốt giờ thực tế')) {
                            stopButtonHtml = `
                                <form action="${pageContext.request.contextPath}/staff/checkin" method="post" class="w-full mt-2" onsubmit="return confirm('Bạn có chắc chắn muốn dừng chơi và chốt giờ thực tế cho ca này?');">
                                    <input type="hidden" name="action" value="stopOpenSession">
                                    <input type="hidden" name="datSanId" value="\${san.datSanIdActive}">
                                    <button type="submit" class="w-full bg-red-550 hover:bg-red-700 text-white font-extrabold text-[10px] py-2 rounded-xl shadow-sm hover:shadow transition-all active:scale-95 flex items-center justify-center gap-1">
                                        <span class="material-symbols-outlined text-[12px]">stop_circle</span>
                                        Dừng chơi & Tính tiền
                                    </button>
                                </form>
                            `;
                        }
                        htmlGrid += `
                            <div class="card p-4 flex flex-col items-center justify-between text-center relative overflow-hidden transition-all duration-200 cursor-pointer card-hover hover:border-zinc-300 border-${isManager ? 'purple-300' : 'orange-300'} shadow-md"
                                 data-sanid="\${san.sanID}"
                                 data-tensan="\${san.tenSan}"
                                 data-loaisan="\${tenLoaiSan}"
                                 data-trangthai="\${san.trangThai}"
                                 data-mota="\${san.moTa || ''}"
                                 data-giakhongden="\${san.giaKhongDen}"
                                 data-giacoden="\${san.giaCoDen}"
                                 data-giobatdaulenden="\${gioBatDauLenDenStr}"
                                 data-giokethuclenden="\${gioKetThucLenDenStr}"
                                 data-datsanidactive="\${san.datSanIdActive}"
                                 data-giobatdauactive="\${san.gioBatDauActive}"
                                 data-giokethucactive="\${san.gioKetThucActive || ''}"
                                 data-ghichuactive="\${san.ghiChuActive || ''}"
                                 onclick="onCardClick(event, this)">
                                <div class="w-full flex flex-col items-center">
                                    <span class="absolute top-2.5 right-2.5 w-2 h-2 rounded-full ${isManager ? 'bg-purple-500' : 'bg-orange-500'} live-dot"></span>
                                    <div class="w-12 h-12 rounded-2xl ${isManager ? 'bg-purple-50' : 'bg-orange-50'} flex items-center justify-center ${themeIcon} mb-2 shadow-inner">
                                        <span class="material-symbols-outlined text-[24px]">sports_soccer</span>
                                    </div>
                                    <h4 class="font-bold text-sm text-zinc-800">\${san.tenSan}</h4>
                                    <p class="text-[10px] text-zinc-500 font-medium">\${tenLoaiSan}</p>
                                    <span class="badge ${badgeTheme} mt-2 uppercase text-[10px]">Đang sử dụng</span>
                                    <p class="text-[10px] text-zinc-500 mt-1 flex items-center justify-center gap-1">
                                        <span class="material-symbols-outlined text-[12px]">schedule</span>
                                        <span class="card-timer font-bold text-zinc-700" 
                                              data-start="\${san.gioBatDauActive || ''}" 
                                              data-end="\${san.gioKetThucActive || ''}" 
                                              data-note="\${san.ghiChuActive || ''}">Bắt đầu: \${san.gioBatDauActive || ''}</span>
                                    </p>
                                    
                                    \${stopButtonHtml}
                                    <button type="button" onclick="openStaffInvoiceModal(\${san.datSanIdActive})" class="w-full mt-3 \${themeBg} \${themeBgHover} text-white font-extrabold text-[10px] py-2 rounded-xl shadow-sm hover:shadow transition-all active:scale-95">
                                        Dịch vụ & Thanh toán
                                    </button>
                                </div>
                            </div>
                        `;
                    } else if (san.trangThai === 'Sẵn sàng' && san.nextDatSanId != null) {
                        htmlGrid += `
                            <div class="card p-4 flex flex-col items-center justify-between text-center relative overflow-hidden transition-all duration-200 cursor-pointer card-hover hover:border-zinc-300 border-amber-300 bg-amber-50/30 shadow-md"
                                 data-sanid="\${san.sanID}"
                                 data-tensan="\${san.tenSan}"
                                 data-loaisan="\${tenLoaiSan}"
                                 data-trangthai="\${san.trangThai}"
                                 data-mota="\${san.moTa || ''}"
                                 data-giakhongden="\${san.giaKhongDen}"
                                 data-giacoden="\${san.giaCoDen}"
                                 data-giobatdaulenden="\${gioBatDauLenDenStr}"
                                 data-giokethuclenden="\${gioKetThucLenDenStr}"
                                 data-nextdatsanid="\${san.nextDatSanId}"
                                 onclick="onCardClick(event, this)">
                                <div class="w-full flex flex-col items-center">
                                    <span class="absolute top-2.5 right-2.5 w-2 h-2 rounded-full bg-amber-500 animate-pulse"></span>
                                    <div class="w-12 h-12 rounded-2xl bg-amber-50 flex items-center justify-center text-amber-600 mb-2">
                                        <span class="material-symbols-outlined text-[24px]">event_upcoming</span>
                                    </div>
                                    <h4 class="font-bold text-sm text-zinc-800">\${san.tenSan}</h4>
                                    <p class="text-[10px] text-zinc-500 font-medium">\${tenLoaiSan}</p>
                                    <span class="badge badge-amber mt-2 uppercase text-[10px]">Sắp có lịch đặt</span>

                                    <div class="w-full mt-2 text-left text-[10px] text-zinc-600 space-y-0.5">
                                        <p class="font-bold text-zinc-800 truncate flex items-center gap-1">
                                            <span class="material-symbols-outlined text-[12px]">person</span>\${san.nextTenKhachHang || ''}
                                        </p>
                                        <p class="flex items-center gap-1">
                                            <span class="material-symbols-outlined text-[12px]">schedule</span>
                                            \${(san.nextGioBatDau || '').substring(11,16)} – \${(san.nextGioKetThuc || '').substring(11,16)}
                                            <span class="badge badge-gray text-[8px] uppercase ml-1">\${san.nextNguonDatSan || ''}</span>
                                        </p>
                                    </div>
                                    <p class="text-[10px] mt-1.5 flex items-center justify-center gap-1">
                                        <span class="material-symbols-outlined text-[12px] text-amber-600">hourglass_top</span>
                                        <span class="upcoming-timer font-bold text-amber-700" data-next-start="\${san.nextGioBatDau || ''}">Đang tính...</span>
                                    </p>

                                    <form action="${pageContext.request.contextPath}/staff/checkin" method="post" class="w-full mt-2">
                                        <input type="hidden" name="action" value="checkInPreBooked">
                                        <input type="hidden" name="datSanId" value="\${san.nextDatSanId}">
                                        <input type="hidden" name="daThuTienMat" value="false">
                                        <button type="submit" onclick="event.stopPropagation();" class="w-full ${themeBg} ${themeBgHover} text-white font-extrabold text-[10px] py-2 rounded-xl shadow-sm hover:shadow transition-all active:scale-95 flex items-center justify-center gap-1">
                                            <span class="material-symbols-outlined text-[14px]">how_to_reg</span>
                                            Check-in khách
                                        </button>
                                    </form>
                                </div>
                            </div>
                        `;
                    } else if (san.trangThai === 'Sẵn sàng') {
                        htmlGrid += `
                            <div class="card p-4 flex flex-col items-center justify-between text-center relative overflow-hidden transition-all duration-200 cursor-pointer card-hover hover:border-zinc-300"
                                 data-sanid="\${san.sanID}"
                                 data-tensan="\${san.tenSan}"
                                 data-loaisan="\${tenLoaiSan}"
                                 data-trangthai="\${san.trangThai}"
                                 data-mota="\${san.moTa || ''}"
                                 data-giakhongden="\${san.giaKhongDen}"
                                 data-giacoden="\${san.giaCoDen}"
                                 data-giobatdaulenden="\${gioBatDauLenDenStr}"
                                 data-giokethuclenden="\${gioKetThucLenDenStr}"
                                 data-datsanidactive="\${san.datSanIdActive}"
                                 data-giobatdauactive="\${san.gioBatDauActive}"
                                 onclick="onCardClick(event, this)">
                                <div class="w-full flex flex-col items-center">
                                    <span class="absolute top-2.5 right-2.5 w-2 h-2 rounded-full bg-green-500"></span>
                                    <div class="w-12 h-12 rounded-2xl bg-green-50 flex items-center justify-center text-green-600 mb-2">
                                        <span class="material-symbols-outlined text-[24px]">sports_soccer</span>
                                    </div>
                                    <h4 class="font-bold text-sm text-zinc-800">\${san.tenSan}</h4>
                                    <p class="text-[10px] text-zinc-500 font-medium">\${tenLoaiSan}</p>
                                    <span class="badge badge-green mt-2 uppercase text-[10px]">Sẵn sàng</span>

                                    <button type="button" onclick="openCourtDetailDrawer(\${san.sanID})" class="w-full mt-3 ${themeBg} ${themeBgHover} text-white font-extrabold text-[10px] py-2 rounded-xl shadow-sm hover:shadow transition-all active:scale-95">
                                        Mở sân
                                    </button>
                                </div>
                            </div>
                        `;
                    } else if (san.trangThai === 'Bảo trì') {
                        htmlGrid += `
                            <div class="card p-4 flex flex-col items-center justify-between text-center relative overflow-hidden transition-all duration-200 border-amber-200 bg-amber-50/20 cursor-pointer card-hover hover:border-zinc-300"
                                 data-sanid="\${san.sanID}"
                                 data-tensan="\${san.tenSan}"
                                 data-loaisan="\${tenLoaiSan}"
                                 data-trangthai="\${san.trangThai}"
                                 data-mota="\${san.moTa || ''}"
                                 data-giakhongden="\${san.giaKhongDen}"
                                 data-giacoden="\${san.giaCoDen}"
                                 data-giobatdaulenden="\${gioBatDauLenDenStr}"
                                 data-giokethuclenden="\${gioKetThucLenDenStr}"
                                 data-datsanidactive="\${san.datSanIdActive}"
                                 data-giobatdauactive="\${san.gioBatDauActive}"
                                 onclick="onCardClick(event, this)">
                                <div class="w-full flex flex-col items-center">
                                    <span class="absolute top-2.5 right-2.5 w-2 h-2 rounded-full bg-amber-500"></span>
                                    <div class="w-12 h-12 rounded-2xl bg-amber-50 flex items-center justify-center text-amber-600 mb-2">
                                        <span class="material-symbols-outlined text-[24px]">build</span>
                                    </div>
                                    <h4 class="font-bold text-sm text-zinc-850 opacity-60">\${san.tenSan}</h4>
                                    <p class="text-[10px] text-zinc-500 font-medium">\${tenLoaiSan}</p>
                                    <span class="badge badge-amber mt-2 uppercase text-[10px]">Bảo trì</span>
                                    
                                    <button type="button" onclick="openCourtDetailDrawer(\${san.sanID})" class="w-full mt-3 bg-zinc-150 text-zinc-600 hover:bg-zinc-200 transition-colors font-extrabold text-[10px] py-2 rounded-xl">
                                        Chi tiết
                                    </button>
                                </div>
                            </div>
                        `;
                    } else {
                        htmlGrid += `
                            <div class="card p-4 flex flex-col items-center justify-between text-center relative overflow-hidden transition-all duration-200 border-red-200 bg-red-50/20 cursor-pointer card-hover hover:border-zinc-300"
                                 data-sanid="\${san.sanID}"
                                 data-tensan="\${san.tenSan}"
                                 data-loaisan="\${tenLoaiSan}"
                                 data-trangthai="\${san.trangThai}"
                                 data-mota="\${san.moTa || ''}"
                                 data-giakhongden="\${san.giaKhongDen}"
                                 data-giacoden="\${san.giaCoDen}"
                                 data-giobatdaulenden="\${gioBatDauLenDenStr}"
                                 data-giokethuclenden="\${gioKetThucLenDenStr}"
                                 data-datsanidactive="\${san.datSanIdActive}"
                                 data-giobatdauactive="\${san.gioBatDauActive}"
                                 onclick="onCardClick(event, this)">
                                <div class="w-full flex flex-col items-center">
                                    <span class="absolute top-2.5 right-2.5 w-2 h-2 rounded-full bg-red-500"></span>
                                    <div class="w-12 h-12 rounded-2xl bg-red-50 flex items-center justify-center text-red-655 mb-2">
                                        <span class="material-symbols-outlined text-[24px]">block</span>
                                    </div>
                                    <h4 class="font-bold text-sm text-zinc-850 opacity-60">\${san.tenSan}</h4>
                                    <p class="text-[10px] text-zinc-500 font-medium">\${tenLoaiSan}</p>
                                    <span class="badge badge-red mt-2 uppercase text-[10px]">Tạm đóng</span>
                                    
                                    <button type="button" onclick="openCourtDetailDrawer(\${san.sanID})" class="w-full mt-3 bg-zinc-150 text-zinc-600 hover:bg-zinc-200 transition-colors font-extrabold text-[10px] py-2 rounded-xl">
                                        Chi tiết
                                    </button>
                                </div>
                            </div>
                        `;
                    }
                });
                fieldGrid.innerHTML = htmlGrid;
            }
            

            // 3. Cập nhật Today's Bookings Layout
            if (data.danhSachLich) {
                renderBookings();
            }
            
            // Refresh grid card timers immediately
            updateAllCardTimers();

            // Refresh Open Side Drawer details if open
            if (activeDrawerSanId !== null) {
                openCourtDetailDrawer(activeDrawerSanId);
            }
        } catch (err) {
            console.error('Lỗi khi cập nhật trạng thái sân tự động:', err);
        }
    }

    // Chạy cập nhật ngay khi tải trang và thiết lập chu kỳ 30 giây
    setInterval(pollUpdates, 30000);

    // Resync ngay khi tab quay lại foreground - tránh đồng hồ đếm ngược lệch nếu máy vào sleep/đổi tab lâu.
    document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'visible') {
            pollUpdates();
        }
    });
</script>

<div id="noShowModal" role="dialog" aria-modal="true" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 hidden flex items-center justify-center opacity-0 transition-opacity duration-300 p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-sm scale-95 transition-transform duration-300">
        <div class="bg-rose-600 rounded-t-2xl px-5 py-4 flex items-center justify-between">
            <h3 class="text-white font-bold text-sm">Xác nhận đánh dấu Không đến</h3>
            <button onclick="closeNoShowModal()" class="text-white/80 hover:text-white transition-colors p-1">
                <span class="material-symbols-outlined text-[20px]">close</span>
            </button>
        </div>
        <div class="p-5 space-y-3">
            <p class="text-sm text-zinc-700">Khách hàng <strong id="noShowCustomerName">-</strong> sẽ được đánh dấu <strong>Không đến (No Show)</strong> cho đơn <strong id="noShowDatSanLabel">-</strong>.</p>
            <div class="bg-amber-50 border border-amber-200 rounded-xl p-3 text-[12px] text-amber-800 font-semibold leading-snug">
                Thao tác này sẽ trừ điểm uy tín của khách và không thể hoàn tác. Vui lòng kiểm tra kỹ trước khi xác nhận.
            </div>
            <p id="noShowCurrentReputation" class="text-[11px] text-zinc-500 hidden"></p>
        </div>
        <div class="px-5 pb-5 flex items-center justify-end gap-2">
            <button type="button" onclick="closeNoShowModal()" class="px-4 py-2 rounded-xl font-bold text-slate-600 bg-slate-100 hover:bg-slate-200 transition-colors text-sm">
                Hủy thao tác
            </button>
            <form id="noShowForm" action="${pageContext.request.contextPath}/staff/checkin" method="post">
                <input type="hidden" name="action" value="cancelNoShow">
                <input type="hidden" name="datSanId" id="noShowDatSanId" value="">
                <button type="submit" class="px-4 py-2 rounded-xl font-bold text-white bg-rose-600 hover:bg-rose-700 transition-colors text-sm">
                    Xác nhận Không đến
                </button>
            </form>
        </div>
    </div>
</div>

<!-- STAFF INVOICE & SERVICE MODAL -->
<div id="staffInvoiceModal" role="dialog" aria-modal="true" aria-labelledby="staffInvoiceModalTitle" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 hidden flex items-center justify-center opacity-0 transition-opacity duration-300 p-2 sm:p-4">
    <div class="bg-white w-full max-w-[1400px] rounded-lg sm:rounded-xl shadow-2xl overflow-hidden transform scale-95 transition-all duration-300 relative flex flex-col" style="max-height: 96vh;">

        <!-- Header -->
        <header class="bg-[#f8f9ff] border-b border-[#ccc3d8] shrink-0">
            <div class="flex justify-between items-center px-4 lg:px-6 py-2.5 lg:py-3">
                <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-lg bg-[#e5eeff] flex items-center justify-center ${isManager ? 'text-purple-700' : 'text-orange-600'} shrink-0">
                        <span class="material-symbols-outlined text-[18px]">receipt_long</span>
                    </div>
                    <div>
                        <h1 id="staffInvoiceModalTitle" class="text-base font-bold text-[#0b1c30] leading-tight">Thanh toán &amp; Dịch vụ</h1>
                        <p id="staffInvoiceModalSubtitle" class="text-[11px] text-[#5d5d67] leading-tight">Thêm dịch vụ hoặc hoàn tất thanh toán</p>
                    </div>
                </div>
                <button onclick="closeStaffInvoiceModal()" aria-label="Đóng" class="w-8 h-8 flex items-center justify-center rounded-full hover:bg-[#dce9ff] transition-colors text-[#5d5d67] shrink-0">
                    <span class="material-symbols-outlined text-[20px]">close</span>
                </button>
            </div>
            <!-- Dòng thông tin ca chơi compact - thay cho card "Thông tin ca đấu" lớn -->
            <div class="px-4 lg:px-6 pb-2.5 flex items-center gap-2 flex-wrap text-xs">
                <span class="font-bold text-[#0b1c30]" id="staff-invoice-court-name">Tên sân</span>
                <span class="text-[#9291a0]">·</span>
                <span class="badge badge-amber" id="staff-invoice-payment-status">Chưa thanh toán</span>
                <span class="text-[#9291a0]">·</span>
                <span class="text-[#5d5d67]" id="staff-invoice-time-slot">00:00 - 00:00</span>
            </div>
        </header>

        <!-- Flex body: loading + content -->
        <div class="flex-1 min-h-0 overflow-hidden flex flex-col">

            <!-- Loading state -->
            <div id="staff-invoice-loading" class="flex-1 flex flex-col items-center justify-center text-zinc-500">
                <span class="material-symbols-outlined animate-spin text-[32px] ${themeIcon} mb-2">sync</span>
                <p class="text-sm font-medium">Đang tải chi tiết hóa đơn...</p>
            </div>

            <!-- Main 2-column content -->
            <div id="staff-invoice-content" class="hidden flex-1 min-h-0 bg-[#f8f9ff] p-3 lg:p-5 gap-3 lg:gap-5 animate-fadeUp flex flex-col lg:flex-row overflow-y-auto lg:overflow-hidden">

                <!-- LEFT (~60%): Dịch vụ -->
                <section class="flex-none lg:flex-[3] min-w-0 bg-white rounded-xl border border-[#ccc3d8] p-4 lg:p-5 flex flex-col lg:min-h-0">
                    <div class="mb-3 shrink-0">
                        <h2 class="text-sm font-bold uppercase tracking-wide text-[#0b1c30]">Dịch vụ</h2>
                    </div>
                    <!-- Category Filter Tabs -->
                    <div class="flex flex-wrap gap-2 mb-3 shrink-0">
                        <button type="button" onclick="filterStaffCatalog('all', this)" class="pos-tab active"><span class="material-symbols-outlined text-[15px]">apps</span> Tất cả</button>
                        <button type="button" onclick="filterStaffCatalog('drinks', this)" class="pos-tab"><span class="material-symbols-outlined text-[15px]">local_cafe</span> Đồ uống</button>
                        <button type="button" onclick="filterStaffCatalog('rentals', this)" class="pos-tab"><span class="material-symbols-outlined text-[15px]">sports_tennis</span> Thuê dụng cụ</button>
                        <button type="button" onclick="filterStaffCatalog('others', this)" class="pos-tab"><span class="material-symbols-outlined text-[15px]">more_horiz</span> Khác</button>
                    </div>
                    <!-- Search Bar -->
                    <div class="relative mb-3 shrink-0">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <span class="material-symbols-outlined text-[#7b7487] text-[20px]">search</span>
                        </div>
                        <input type="text" id="staff-catalog-search" oninput="searchStaffCatalog(this.value)" placeholder="Tìm nhanh dịch vụ, nước uống..." class="w-full text-sm pl-10 pr-4 py-2.5 rounded-lg border border-[#ccc3d8] bg-white focus:outline-none focus:border-[#630ed4] focus:ring-1 focus:ring-[#630ed4] transition-all text-[#0b1c30] placeholder-[#5d5d67]">
                    </div>
                    <!-- Product Grid -->
                    <div id="staff-product-catalog" class="max-h-[240px] lg:max-h-none lg:flex-1 overflow-y-auto grid grid-cols-2 auto-rows-max gap-2.5 pr-1 lg:min-h-0 content-start">
                        <!-- Populated dynamically via JS -->
                    </div>
                    <!-- Hidden inputs for backward compatibility -->
                    <select id="staff-product-select" class="hidden"></select>
                    <input type="number" id="staff-product-qty" class="hidden" value="1">
                    <button type="button" id="staff-add-service-btn" class="hidden"></button>
                </section>

                <!-- RIGHT (~40%): Đơn hàng -->
                <section class="w-full lg:flex-[2] lg:max-w-[400px] lg:shrink-0 flex flex-col gap-3 lg:overflow-y-auto lg:min-h-0 pr-1">

                    <!-- Mục đích thao tác -->
                    <div class="shrink-0">
                        <h4 class="text-[11px] text-[#5d5d67] uppercase font-semibold tracking-wide mb-2">Mục đích thao tác</h4>
                        <div class="seg-control" role="radiogroup" aria-label="Mục đích thao tác">
                            <button type="button" id="action-mode-btn-add" class="seg-btn active" role="radio" aria-checked="true" onclick="setActionMode(PaymentActionMode.ADD_SERVICES)">
                                <span class="material-symbols-outlined text-[16px]">add_shopping_cart</span> Thêm dịch vụ
                            </button>
                            <button type="button" id="action-mode-btn-checkout" class="seg-btn" role="radio" aria-checked="false" onclick="setActionMode(PaymentActionMode.CHECKOUT)">
                                <span class="material-symbols-outlined text-[16px]">payments</span> Thanh toán &amp; kết thúc
                            </button>
                        </div>
                    </div>

                    <!-- Giỏ dịch vụ -->
                    <div class="bg-white rounded-xl border border-[#ccc3d8] p-3.5 shrink-0 flex flex-col" style="max-height:230px;">
                        <div class="flex justify-between items-center mb-2 shrink-0">
                            <h4 class="text-[11px] text-[#5d5d67] uppercase font-semibold tracking-wide">Đơn hàng</h4>
                            <span class="text-xs font-semibold text-[#0b1c30]" id="staff-cart-item-count">0 mặt hàng</span>
                        </div>
                        <div id="staff-cart-list" class="overflow-y-auto pr-1 space-y-1 flex-1 min-h-0">
                            <!-- Populated dynamically via JS -->
                        </div>
                        <div class="mt-2 pt-2 border-t border-[#ccc3d8] flex justify-between items-center shrink-0">
                            <span class="text-xs text-[#5d5d67] font-medium">Tổng tiền dịch vụ</span>
                            <span class="text-sm font-bold text-[#0b1c30]" id="staff-cart-subtotal">0 đ</span>
                        </div>
                    </div>

                    <!-- Loại hóa đơn dịch vụ (ẩn khi giỏ rỗng) -->
                    <div id="bill-mode-section" class="hidden shrink-0">
                        <h4 class="text-[11px] text-[#5d5d67] uppercase font-semibold tracking-wide mb-2">Loại hóa đơn dịch vụ</h4>
                        <div class="seg-control" role="radiogroup" aria-label="Loại hóa đơn dịch vụ">
                            <button type="button" id="lbl-billmode-main" class="seg-btn active" role="radio" aria-checked="true" onclick="setBillMode('MAIN')">Cộng vào hóa đơn sân</button>
                            <button type="button" id="lbl-billmode-split" class="seg-btn" role="radio" aria-checked="false" onclick="setBillMode('SPLIT')">Tách hóa đơn</button>
                        </div>
                        <p class="text-[11px] text-[#5d5d67] mt-1.5" id="bill-mode-description">Tiền sân và dịch vụ được thanh toán chung.</p>
                        <div id="split-paynow-section" class="hidden items-center gap-2 bg-amber-50 border border-amber-200 rounded-lg px-3 py-2 mt-2">
                            <input type="checkbox" id="split-pay-now-cb" class="${isManager ? 'accent-purple-600' : 'accent-orange-600'}">
                            <label for="split-pay-now-cb" class="text-xs font-bold text-amber-800 cursor-pointer">Thanh toán bill tách ngay bây giờ</label>
                        </div>
                    </div>

                    <!-- Split bills list -->
                    <div id="split-bills-section" class="hidden shrink-0">
                        <h4 class="text-xs text-[#0b1c30] uppercase font-semibold mb-2 flex items-center gap-1">
                            <span class="material-symbols-outlined text-[15px] text-amber-600">receipt</span>
                            Hóa đơn tách dịch vụ
                        </h4>
                        <div id="split-bills-list" class="space-y-2"></div>
                    </div>

                    <!-- Phương thức thanh toán (chỉ hiện ở chế độ Thanh toán & kết thúc) -->
                    <div id="payment-method-section" class="hidden shrink-0">
                        <h4 class="text-[11px] text-[#5d5d67] uppercase font-semibold tracking-wide mb-2">Phương thức thanh toán</h4>
                        <div class="seg-control" role="radiogroup" aria-label="Phương thức thanh toán">
                            <button type="button" id="lbl-pay-cash" class="seg-btn active" role="radio" aria-checked="true" onclick="changeStaffPayMethod('Tiền mặt')">
                                <span class="material-symbols-outlined text-[16px]">payments</span> Tiền mặt
                            </button>
                            <button type="button" id="lbl-pay-transfer" class="seg-btn" role="radio" aria-checked="false" onclick="changeStaffPayMethod('PayOS')">
                                <span class="material-symbols-outlined text-[16px]">qr_code_2</span> PayOS
                            </button>
                        </div>
                        <p class="text-[11px] text-[#5d5d67] mt-1.5">Quét mã QR hoặc mở trang thanh toán PayOS. Hệ thống tự động xác nhận khi khách thanh toán xong.</p>
                    </div>

                    <!-- Cơ sở chưa cấu hình tài khoản ngân hàng -->
                    <div id="bank-not-configured-banner" class="hidden shrink-0 p-3 bg-amber-50 border border-amber-200 rounded-xl text-xs text-amber-800 space-y-2">
                        <p>Cơ sở chưa cấu hình thông tin chuyển khoản.</p>
                        <button type="button" onclick="document.getElementById('bank-not-configured-banner').classList.add('hidden'); changeStaffPayMethod(PaymentMethod.CASH);" class="font-bold underline">Chọn tiền mặt</button>
                    </div>

                    <!-- Cảnh báo trả sân sớm - luôn hiển thị vì cần thao tác, không ẩn trong disclosure -->
                    <div id="staff-detail-early-checkout-warning-panel" class="shrink-0 p-3 bg-amber-50 border border-amber-200 rounded-xl text-xs text-amber-800 space-y-1.5 hidden">
                        <div class="flex items-center gap-1.5 font-bold">
                            <span class="material-symbols-outlined text-[16px]">warning</span>
                            <span>Khách trả sân sớm <span id="staff-detail-early-checkout-minutes">0</span> phút</span>
                        </div>
                        <p class="text-[11px] leading-relaxed">Theo quy định, ca chơi cố định trả sớm vẫn tính đủ tiền giờ đã đăng ký ban đầu.</p>
                        <c:if test="${sessionScope.user.roleId == 1 || sessionScope.user.roleId == 2}">
                            <button type="button" onclick="openEarlyCheckoutAdjustmentModal()" class="mt-2 w-full bg-amber-600 hover:bg-amber-700 text-white font-extrabold text-[10px] py-1.5 rounded-lg transition-all active:scale-95 flex items-center justify-center gap-1">
                                <span class="material-symbols-outlined text-[12px]">local_activity</span>
                                Áp dụng giảm trừ trả sân sớm
                            </button>
                        </c:if>
                    </div>

                    <!-- Gia hạn thời gian chơi -->
                    <div id="staff-extension-panel" class="bg-white rounded-xl border border-[#ccc3d8] p-3.5 shrink-0 hidden">
                        <h4 class="text-[11px] text-[#5d5d67] uppercase font-semibold tracking-wide mb-2 flex items-center gap-1">
                            <span class="material-symbols-outlined text-[15px] ${isManager ? 'text-purple-600' : 'text-orange-600'}">more_time</span>
                            Gia hạn thời gian chơi
                        </h4>
                        <div class="space-y-2.5">
                            <!-- Nút nhanh -->
                            <div class="flex gap-2">
                                <button type="button" onclick="previewExtensionByMinutes(15)" class="flex-1 py-1.5 rounded-lg border border-zinc-200 hover:border-violet-600 hover:bg-violet-50 text-xs font-bold text-zinc-700 hover:text-violet-700 transition-all select-none">
                                    +15 Phút
                                </button>
                                <button type="button" onclick="previewExtensionByMinutes(30)" class="flex-1 py-1.5 rounded-lg border border-zinc-200 hover:border-violet-600 hover:bg-violet-50 text-xs font-bold text-zinc-700 hover:text-violet-700 transition-all select-none">
                                    +30 Phút
                                </button>
                                <button type="button" onclick="previewExtensionByMinutes(60)" class="flex-1 py-1.5 rounded-lg border border-zinc-200 hover:border-violet-600 hover:bg-violet-50 text-xs font-bold text-zinc-700 hover:text-violet-700 transition-all select-none">
                                    +60 Phút
                                </button>
                            </div>
                            <!-- Chọn giờ cụ thể -->
                            <div class="flex items-center gap-2">
                                <label for="extension-new-time" class="text-xs text-[#5d5d67] font-medium whitespace-nowrap">Đến giờ:</label>
                                <input type="time" id="extension-new-time" class="flex-1 text-xs border border-zinc-200 rounded-lg p-1 focus:outline-none focus:border-violet-600" onchange="previewExtensionByTime(this.value)">
                            </div>
                            <!-- Phí phát sinh preview -->
                            <div id="extension-preview-result" class="hidden text-[11px] p-2 rounded-lg bg-zinc-50 border border-zinc-200 space-y-1">
                                <div class="flex justify-between">
                                    <span class="text-zinc-650">Giờ kết thúc mới:</span>
                                    <span class="font-bold text-zinc-800" id="extension-preview-new-end">--:--</span>
                                </div>
                                <div class="flex justify-between">
                                    <span class="text-zinc-650">Phí phát sinh:</span>
                                    <span class="font-bold text-red-650" id="extension-preview-fee">0 đ</span>
                                </div>
                                <div class="text-zinc-550 italic mt-0.5 text-[10px] leading-tight" id="extension-preview-note"></div>
                            </div>
                            <!-- Nút Xác nhận -->
                            <button type="button" id="extension-confirm-btn" onclick="confirmExtension()" disabled class="w-full bg-zinc-300 text-white font-extrabold text-[10.5px] py-2 rounded-xl shadow-sm hover:shadow transition-all active:scale-95 flex items-center justify-center gap-1 select-none cursor-not-allowed">
                                <span class="material-symbols-outlined text-[14px]">done</span>
                                Xác nhận gia hạn
                            </button>
                        </div>
                    </div>

                    <!-- Tổng kết -->
                    <div class="bg-white rounded-xl border border-[#ccc3d8] p-3.5 shrink-0">
                        <div id="summary-row-court" class="hidden flex justify-between items-baseline text-sm mb-1.5 gap-2">
                            <span class="text-[#5d5d67] flex items-center gap-1.5 flex-wrap">
                                Tiền sân
                                <button type="button" class="text-[11px] font-semibold underline ${themeTextMedium}" onclick="toggleCourtPriceDetail()" id="court-detail-toggle" aria-expanded="false" aria-controls="court-price-detail">Xem chi tiết</button>
                            </span>
                            <span class="font-semibold text-[#0b1c30] text-right shrink-0" id="staff-summary-court-price" data-val="0">0 đ</span>
                        </div>
                        <div id="court-price-detail" class="hidden text-xs text-[#5d5d67] bg-[#f8f9ff] rounded-lg p-2.5 mb-2 space-y-1.5">
                            <div class="flex justify-between"><span>Đơn giá sân</span><span class="font-semibold text-[#0b1c30]" id="staff-detail-court-rate">0 đ/giờ</span></div>
                            <div class="flex justify-between"><span>Giờ bắt đầu</span><span class="font-semibold text-[#0b1c30]" id="staff-detail-start-time">00:00</span></div>
                            <div class="flex justify-between"><span>Giờ kết thúc</span><span class="font-semibold text-[#0b1c30]" id="staff-detail-end-time">00:00</span></div>
                            <div id="staff-detail-early-container" class="flex justify-between text-amber-700 hidden">
                                <span>Phụ thu nhận sớm</span>
                                <span class="font-bold" id="staff-detail-early-surcharge">0 đ</span>
                            </div>
                            <div id="staff-detail-late-container" class="flex justify-between text-red-600 hidden">
                                <span>Phụ thu quá giờ (<span id="staff-detail-late-minutes">0</span> phút)</span>
                                <span class="font-bold" id="staff-detail-late-surcharge">0 đ</span>
                            </div>
                            <div id="staff-detail-early-discount-container" class="flex justify-between text-green-700 font-bold hidden">
                                <span>Giảm trừ trả sân sớm</span>
                                <span id="staff-detail-early-discount-value">-0 đ</span>
                            </div>
                        </div>
                        <div id="summary-row-services" class="flex justify-between text-sm mb-1.5">
                            <span class="text-[#5d5d67]">Tiền dịch vụ</span>
                            <span class="font-semibold text-[#0b1c30]" id="staff-summary-services-price">0 đ</span>
                        </div>
                        <div id="summary-row-discount" class="hidden justify-between text-sm mb-1.5 text-green-700">
                            <span>Giảm giá</span><span class="font-semibold" id="staff-summary-discount">0 đ</span>
                        </div>
                        <div id="summary-row-parking" class="hidden justify-between text-sm mb-1.5">
                            <span class="text-[#5d5d67]">Phí gửi xe</span><span class="font-semibold text-[#0b1c30]" id="staff-summary-parking">0 đ</span>
                        </div>
                        <div id="summary-row-total" class="hidden justify-between items-center pt-2.5 mt-1 border-t border-[#ccc3d8]">
                            <span class="text-xs text-[#5d5d67] uppercase font-medium">Tổng thanh toán</span>
                            <span class="text-lg font-bold ${themeTextMedium}" id="staff-summary-total">0 đ</span>
                        </div>
                    </div>

                    <!-- Hidden state inputs (không dùng form/submit - primary button gọi handler trực tiếp) -->
                    <input type="hidden" id="staff-save-datsan-id">
                    <input type="hidden" id="staff-save-billmode" value="MAIN">
                    <input type="hidden" id="staff-save-paynow" value="false">
                    <input type="hidden" id="staff-save-paymethod" value="Tiền mặt">
                    <input type="hidden" id="staff-pay-datsan-id">
                    <input type="hidden" id="staff-pay-method-input" value="Tiền mặt">

                    <div id="staff-payment-error" role="alert" class="hidden p-2.5 rounded-lg bg-red-50 border border-red-200 text-red-700 text-xs font-semibold"></div>

                </section>
            </div><!-- End of staff-invoice-content -->

            <!-- Payment success state -->
            <div id="staff-payment-success" class="hidden flex-1 min-h-0 bg-[#f8f9ff] overflow-y-auto relative">
                <div class="p-4 lg:p-6 success-banner-enter">
                    <!-- Success banner -->
                    <div class="max-w-5xl mx-auto mb-5 flex items-start gap-3 flex-wrap">
                        <div class="success-banner-icon" aria-hidden="true">
                            <span class="material-symbols-outlined">check</span>
                        </div>
                        <div class="flex-1 min-w-[220px]">
                            <h2 id="staff-success-heading" tabindex="-1" class="text-lg font-bold text-[#0b1c30] outline-none">Thanh toán thành công</h2>
                            <p id="staff-success-description" class="text-sm text-[#5d5d67] mt-0.5">Hóa đơn đã được ghi nhận. Sân đã chuyển về trạng thái sẵn sàng.</p>
                        </div>
                        <span id="staff-success-code" class="badge badge-green text-sm px-3 py-1.5 shrink-0"></span>
                    </div>

                    <!-- Loading invoice detail -->
                    <div id="staff-success-body-loading" class="max-w-5xl mx-auto flex flex-col items-center justify-center text-zinc-500 py-10">
                        <span class="material-symbols-outlined animate-spin text-[28px] ${themeIcon} mb-2">sync</span>
                        <p class="text-sm font-medium">Đang chuẩn bị hóa đơn...</p>
                    </div>

                    <!-- Preview failed -->
                    <div id="staff-success-preview-error" class="hidden max-w-5xl mx-auto p-3 rounded-lg border border-amber-200 bg-amber-50 text-amber-800 text-xs flex items-center justify-between gap-3 flex-wrap">
                        <span>Không thể tải bản xem trước hóa đơn.</span>
                        <div class="flex items-center gap-3 shrink-0">
                            <button type="button" onclick="retryLoadSuccessInvoice()" class="font-bold underline">Thử lại</button>
                            <a id="staff-success-fallback-link" href="#" target="_blank" class="font-bold underline">Mở hóa đơn</a>
                        </div>
                    </div>

                    <!-- Two-column success body -->
                    <div id="staff-success-body" class="hidden max-w-5xl mx-auto grid grid-cols-1 lg:grid-cols-2 gap-4 lg:gap-6">
                        <!-- Left: payment info -->
                        <div class="bg-white rounded-xl border border-[#ccc3d8] p-5">
                            <h3 class="text-xs text-[#5d5d67] uppercase font-semibold mb-3">Thông tin thanh toán</h3>
                            <div class="space-y-2.5 text-sm" id="staff-success-info-list"></div>
                            <div class="mt-4 pt-4 border-t border-[#ccc3d8] space-y-2 text-sm" id="staff-success-summary-list"></div>
                        </div>

                        <!-- Right: invoice preview -->
                        <div class="bg-white rounded-xl border border-[#ccc3d8] overflow-hidden">
                            <div class="px-5 pt-4 pb-3 flex items-center gap-2 border-b border-[#ccc3d8]">
                                <span class="material-symbols-outlined text-[#5d5d67] text-[18px]">receipt_long</span>
                                <h3 class="text-xs text-[#5d5d67] uppercase font-semibold">Xem trước hóa đơn</h3>
                            </div>
                            <div class="p-4 lg:p-5 flex justify-center">
                                <div id="staff-print-root" class="receipt" style="border:1px solid #e5e7eb;border-radius:12px;"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div><!-- End of staff-payment-success -->

            <!-- Bank transfer awaiting state -->
            <div id="staff-bank-transfer-panel" class="hidden flex-1 min-h-0 bg-[#f8f9ff] overflow-y-auto">
                <div class="p-4 lg:p-6 max-w-3xl mx-auto">
                    <div class="bg-white rounded-xl border ${themeBorderStrong} overflow-hidden">
                        <div class="px-5 pt-4 pb-3 border-b ${themeBorder}">
                            <h3 class="text-sm font-bold text-[#0b1c30]">Chuyển khoản</h3>
                            <p class="text-xs text-[#5d5d67] mt-0.5">Quét mã hoặc nhập thông tin bên dưới</p>
                        </div>
                        <div class="p-5 flex flex-col lg:flex-row gap-5">
                            <div class="lg:w-2/5 shrink-0" id="bank-transfer-customer-info"></div>
                            <div class="lg:flex-1 min-w-0">
                                <div class="${themeBgLight} rounded-lg p-4 flex flex-col items-center gap-2">
                                    <img id="bank-transfer-qr" src="" alt="QR chuyển khoản" class="w-40 h-40 object-contain bg-white rounded-lg border ${themeBorder}"
                                         onerror="this.style.display='none'; document.getElementById('bank-transfer-qr-error').classList.remove('hidden');">
                                    <p id="bank-transfer-qr-error" class="hidden text-[11px] text-amber-700 text-center">Không tải được QR. Dùng thông tin bên dưới để chuyển khoản thủ công.</p>
                                </div>
                                <div class="mt-3 space-y-1.5 text-sm">
                                    <div class="flex justify-between items-center gap-2">
                                        <span class="text-[#5d5d67]">Ngân hàng</span>
                                        <span class="font-semibold text-[#0b1c30]" id="bank-transfer-bank-name">-</span>
                                    </div>
                                    <div class="flex justify-between items-center gap-2">
                                        <span class="text-[#5d5d67]">Chủ tài khoản</span>
                                        <span class="font-semibold text-[#0b1c30]" id="bank-transfer-account-name">-</span>
                                    </div>
                                    <div class="flex justify-between items-center gap-2">
                                        <span class="text-[#5d5d67]">Số tài khoản</span>
                                        <span class="flex items-center gap-2">
                                            <span class="font-semibold text-[#0b1c30]" id="bank-transfer-account-number">-</span>
                                            <button type="button" aria-label="Sao chép số tài khoản" onclick="copyBankTransferField('bank-transfer-account-number', this)" class="text-[11px] font-semibold ${themeTextMedium} underline">Copy</button>
                                        </span>
                                    </div>
                                    <div class="flex justify-between items-center gap-2 pt-2 mt-1 border-t ${themeBorder}">
                                        <span class="text-[#5d5d67]">Số tiền</span>
                                        <span class="flex items-center gap-2">
                                            <span class="font-bold text-base ${themeTextMedium}" id="bank-transfer-amount">0 đ</span>
                                            <button type="button" aria-label="Sao chép số tiền" onclick="copyBankTransferField('bank-transfer-amount', this)" class="text-[11px] font-semibold ${themeTextMedium} underline">Copy</button>
                                        </span>
                                    </div>
                                    <div class="flex justify-between items-center gap-2">
                                        <span class="text-[#5d5d67]">Nội dung</span>
                                        <span class="flex items-center gap-2">
                                            <span class="font-semibold text-[#0b1c30]" id="bank-transfer-content">-</span>
                                            <button type="button" aria-label="Sao chép nội dung chuyển khoản" onclick="copyBankTransferField('bank-transfer-content', this)" class="text-[11px] font-semibold ${themeTextMedium} underline">Copy</button>
                                        </span>
                                    </div>
                                </div>
                                <div class="mt-4 flex items-center gap-2 px-3 py-2 rounded-lg bg-amber-50 border border-amber-200">
                                    <span class="w-2 h-2 rounded-full bg-amber-500 shrink-0" aria-hidden="true"></span>
                                    <span class="text-xs font-semibold text-amber-800">Chờ khách chuyển khoản</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div><!-- End of staff-bank-transfer-panel -->

            <!-- PayOS awaiting state -->
            <div id="staff-payos-panel" class="hidden flex-1 min-h-0 bg-[#f8f9ff] overflow-y-auto">
                <div class="p-4 lg:p-6 max-w-md mx-auto">
                    <div class="bg-white rounded-xl border ${themeBorderStrong} overflow-hidden">
                        <div class="px-5 pt-4 pb-3 border-b ${themeBorder}">
                            <h3 class="text-sm font-bold text-[#0b1c30]">Thanh toán PayOS</h3>
                            <p class="text-xs text-[#5d5d67] mt-0.5">Quét mã QR hoặc mở trang thanh toán</p>
                        </div>
                        <div class="p-5 flex flex-col items-center gap-3">
                            <div id="staff-payos-qr-container" class="payos-qr-container"></div>
                            <div id="staff-payos-qr-fallback" class="hidden flex flex-col items-center gap-1.5 text-center">
                                <p class="text-[11px] text-amber-700">Không thể hiển thị mã QR trên thiết bị này.<br>Bạn vẫn có thể mở trang thanh toán PayOS.</p>
                                <button type="button" onclick="retryRenderPayOSQr()" class="text-[11px] font-semibold ${themeTextMedium} underline">Thử tải lại mã QR</button>
                            </div>
                            <div class="w-full space-y-1.5 text-sm">
                                <div class="flex justify-between items-center gap-2 pb-2 border-b ${themeBorder}">
                                    <span class="text-[#5d5d67]">Số tiền</span>
                                    <span class="font-bold text-base ${themeTextMedium}" id="staff-payos-amount">0 đ</span>
                                </div>
                                <div class="flex justify-between items-center gap-2">
                                    <span class="text-[#5d5d67]">Nội dung</span>
                                    <span class="font-semibold text-[#0b1c30]" id="staff-payos-description">-</span>
                                </div>
                                <div class="flex justify-between items-center gap-2">
                                    <span class="text-[#5d5d67]">Trạng thái</span>
                                    <span class="font-semibold text-amber-700" id="staff-payos-status-label">Chờ thanh toán</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div><!-- End of staff-payos-panel -->

        </div><!-- End of flex body -->

        <!-- Footer -->
        <footer class="bg-[#f8f9ff] border-t border-[#ccc3d8] flex flex-wrap justify-between items-center gap-2 px-4 lg:px-8 py-3 lg:py-4 shrink-0">
            <!-- EDITING / PROCESSING actions - chỉ một nút hành động chính, đổi theo actionMode -->
            <div id="staff-footer-editing" class="contents">
                <button type="button" onclick="closeStaffInvoiceModal()" class="bg-[#e3e1ed] text-[#64636d] rounded-lg px-5 py-2 text-sm font-semibold hover:brightness-95 transition-all active:scale-95">
                    Đóng
                </button>
                <button type="button" id="staff-payment-submit-btn" onclick="handlePrimaryPaymentAction()" class="${themeBg} ${themeBgHover} text-white rounded-lg px-6 py-2.5 text-sm font-semibold flex items-center gap-2 transition-all active:scale-95 disabled:opacity-60 disabled:cursor-not-allowed">
                    <span class="material-symbols-outlined text-sm" id="staff-payment-submit-icon">save</span>
                    <span id="staff-payment-submit-label">Lưu dịch vụ</span>
                </button>
            </div>
            <!-- AWAITING_TRANSFER / VERIFYING_TRANSFER actions -->
            <div id="staff-footer-awaiting-transfer" class="hidden contents">
                <button type="button" onclick="handleChangePaymentMethodFromAwaiting()" class="bg-[#e3e1ed] text-[#64636d] rounded-lg px-5 py-2 text-sm font-semibold hover:brightness-95 transition-all active:scale-95">
                    Đổi phương thức
                </button>
                <button type="button" id="staff-bank-transfer-confirm-btn" onclick="openBankTransferConfirmDialog()" class="${themeBg} ${themeBgHover} text-white rounded-lg px-6 py-2.5 text-sm font-semibold flex items-center gap-2 transition-all active:scale-95 disabled:opacity-60 disabled:cursor-not-allowed">
                    <span class="material-symbols-outlined text-sm">verified</span>
                    <span id="staff-bank-transfer-confirm-label">Xác nhận đã nhận tiền</span>
                </button>
            </div>
            <!-- AWAITING_PAYOS / VERIFYING_PAYOS actions -->
            <div id="staff-footer-awaiting-payos" class="hidden contents">
                <button type="button" onclick="handleChangePaymentMethodFromAwaitingPayOS()" class="bg-[#e3e1ed] text-[#64636d] rounded-lg px-5 py-2 text-sm font-semibold hover:brightness-95 transition-all active:scale-95">
                    Đổi phương thức
                </button>
                <button type="button" onclick="openPayOSCheckoutUrl()" class="${themeBg} ${themeBgHover} text-white rounded-lg px-6 py-2.5 text-sm font-semibold flex items-center gap-2 transition-all active:scale-95">
                    <span class="material-symbols-outlined text-sm">open_in_new</span>
                    Mở trang PayOS
                </button>
            </div>
            <!-- SUCCESS actions -->
            <div id="staff-footer-success" class="hidden contents">
                <div class="flex flex-wrap gap-2">
                    <button type="button" onclick="closeStaffInvoiceModal()" class="bg-[#e3e1ed] text-[#64636d] rounded-lg px-5 py-2 text-sm font-semibold hover:brightness-95 transition-all active:scale-95">
                        Đóng
                    </button>
                    <button type="button" onclick="openStaffSuccessManagementUrl()" class="bg-white border ${themeBorderStrong} ${themeTextMedium} rounded-lg px-5 py-2 text-sm font-semibold ${isManager ? 'hover:bg-purple-50' : 'hover:bg-orange-50'} transition-all active:scale-95">
                        Quản lý hóa đơn
                    </button>
                </div>
                <button type="button" id="staff-success-print-btn" onclick="printSuccessInvoice()" class="${themeBg} ${themeBgHover} text-white rounded-lg px-6 py-2.5 text-sm font-semibold flex items-center gap-2 transition-all active:scale-95">
                    <span class="material-symbols-outlined text-sm">print</span>
                    In hóa đơn
                </button>
            </div>
        </footer>

    </div><!-- End of modal inner container -->
</div><!-- End of staffInvoiceModal -->

<!-- Court Detail Side Drawer -->
<div id="drawerOverlay" class="fixed inset-0 bg-black/50 backdrop-blur-sm z-40 hidden opacity-0 transition-opacity duration-200" onclick="closeCourtDetailDrawer()"></div>
<div id="courtDetailDrawer" class="fixed inset-0 z-50 hidden p-4 overflow-y-auto" onclick="if (event.target === this) closeCourtDetailDrawer()">
  <div class="min-h-full flex items-center justify-center">
    <div id="courtDetailDrawerPanel" role="dialog" aria-modal="true" aria-labelledby="drawer-court-name" tabindex="-1"
         class="bg-white rounded-2xl shadow-2xl w-full max-w-[880px] max-h-[90vh] flex flex-col overflow-hidden transform scale-95 opacity-0 transition-all duration-200 ease-out">
        <!-- Header -->
        <div class="p-5 sm:p-6 border-b border-zinc-100 flex items-center justify-between shrink-0">
            <div>
                <h3 id="drawer-court-name" class="text-lg sm:text-xl font-black text-zinc-900 tracking-tight">Tên sân</h3>
                <div class="flex items-center gap-1.5 mt-1">
                    <span id="drawer-court-type" class="text-[11px] text-zinc-550 font-bold uppercase">Loại sân</span>
                    <span class="text-zinc-300">•</span>
                    <span id="drawer-court-status-badge" class="badge">Sẵn sàng</span>
                </div>
            </div>
            <button type="button" onclick="closeCourtDetailDrawer()" aria-label="Đóng" class="p-2.5 rounded-xl text-zinc-400 hover:bg-zinc-50 hover:text-zinc-650 transition-colors">
                <span class="material-symbols-outlined text-[22px]">close</span>
            </button>
        </div>

        <!-- Content (Scrollable) -->
        <div class="flex-1 overflow-y-auto p-5 sm:p-6 space-y-6 sm:grid sm:grid-cols-2 sm:gap-6 sm:space-y-0 sm:items-start">
        <div class="space-y-6">
        <!-- Court Specifications -->
        <div class="bg-zinc-50 rounded-2xl p-4 border border-zinc-150 space-y-3">
            <h4 class="text-[11px] font-bold text-zinc-450 uppercase tracking-wider">Thông tin nhanh</h4>
            <div class="grid grid-cols-2 gap-4 text-xs">
                <div>
                    <span class="text-zinc-550 block">Thời gian hiện tại:</span>
                    <span id="drawer-current-time" class="font-extrabold text-zinc-800">-</span>
                </div>
                <div>
                    <span class="text-zinc-550 block">Cơ sở chi nhánh:</span>
                    <span id="drawer-court-coso" class="font-extrabold text-zinc-800">-</span>
                </div>
                <div>
                    <span class="text-zinc-550 block">Giá không đèn:</span>
                    <span id="drawer-price-nolite" class="font-extrabold text-zinc-800">-</span>
                </div>
                <div>
                    <span class="text-zinc-550 block">Giá có đèn:</span>
                    <span id="drawer-price-lite" class="font-extrabold text-zinc-800">-</span>
                </div>
                <div class="col-span-2">
                    <span class="text-zinc-550 block">Khung giờ bật đèn:</span>
                    <span id="drawer-light-time" class="font-extrabold text-zinc-800">-</span>
                </div>
            </div>
            <div id="drawer-desc-container" class="mt-2 pt-2 border-t border-zinc-100 hidden">
                <span class="text-zinc-550 block text-xs">Mô tả:</span>
                <p id="drawer-court-desc" class="text-xs text-zinc-650 mt-1 italic"></p>
            </div>
        </div>

        <!-- Section D: Danh sách đặt lịch hôm nay (Khách đặt trước) -->
        <div id="drawer-action-prebooked" class="hidden space-y-4">
            <div class="flex items-center gap-2 text-zinc-850 font-extrabold text-sm border-b pb-2">
                <span class="material-symbols-outlined ${themeText}">calendar_today</span>
                <span>Khách đã đặt trước & thành công</span>
            </div>
            <div id="drawer-prebooked-list" class="space-y-3">
                <!-- Will be dynamically populated via JS -->
            </div>
        </div>
        </div>

        <!-- Action Sections -->
        <div class="space-y-6">

        <!-- Section A: Sẵn sàng -> Mở sân nhanh -->
        <div id="drawer-action-walkin" class="hidden space-y-4">
            <div class="flex items-center gap-2 text-zinc-850 font-extrabold text-sm">
                <span class="material-symbols-outlined text-green-600">bolt</span>
                <span>Mở sân nhanh cho Khách vãng lai</span>
            </div>
            <form id="drawer-walkin-form" action="${pageContext.request.contextPath}/staff/checkin" method="post" class="space-y-4">
                <input type="hidden" name="action" value="checkInWalkIn">
                <input type="hidden" id="drawer-walkin-san-id" name="sanId">
                <input type="hidden" id="drawer-walkin-duration" name="duration" value="120">

                <div id="drawer-next-booking-info" class="hidden p-3 rounded-xl border border-amber-200 bg-amber-50 text-amber-800 text-[11px] font-semibold flex items-start gap-2">
                    <span class="material-symbols-outlined text-[16px] mt-px">info</span>
                    <span id="drawer-next-booking-text">Lịch tiếp theo bắt đầu lúc --:--.</span>
                </div>

                <div class="space-y-2">
                    <label class="block text-[11px] font-bold text-zinc-500">Chọn kiểu chơi:</label>
                    <div class="grid grid-cols-2 gap-2">
                        <label id="drawer-mode-fixed-label" class="border-2 ${themeBorderStrong} ${themeBgLight} rounded-xl p-3 cursor-pointer text-xs font-bold ${themeTextMedium} transition-all text-center">
                            <input type="radio" class="sr-only" name="playMode" value="FIXED" checked onchange="setDrawerPlayMode('FIXED')">
                            <span class="block text-sm">Giờ cố định</span>
                            <span class="block mt-0.5 text-[10px] font-semibold opacity-80">Chọn trước thời lượng chơi</span>
                        </label>
                        <label id="drawer-mode-open-label" class="border-2 border-zinc-150 rounded-xl p-3 cursor-pointer text-xs font-bold text-zinc-700 hover:border-zinc-300 transition-all text-center">
                            <input type="radio" class="sr-only" name="playMode" value="OPEN" onchange="setDrawerPlayMode('OPEN')">
                            <span class="block text-sm">Giờ linh hoạt</span>
                            <span class="block mt-0.5 text-[10px] font-semibold opacity-70">Bắt đầu ngay, kết thúc khi khách yêu cầu</span>
                        </label>
                    </div>
                    <div id="drawer-fixed-duration-panel" class="space-y-2 mt-2">
                        <label class="block text-[11px] font-bold text-zinc-500">Chọn thời lượng:</label>
                        <div class="grid grid-cols-4 gap-1.5">
                            <button type="button" data-duration-btn="60" onclick="setDrawerDuration(60)" class="drawer-duration-btn py-2.5 px-1 rounded-lg border ${themeBorderStrong} ${themeBgLight} text-xs font-bold ${themeTextMedium}">1 giờ</button>
                            <button type="button" data-duration-btn="120" onclick="setDrawerDuration(120)" class="drawer-duration-btn py-2.5 px-1 rounded-lg border border-zinc-200 text-xs font-bold text-zinc-700 hover:bg-zinc-50">2 giờ</button>
                            <button type="button" data-duration-btn="180" onclick="setDrawerDuration(180)" class="drawer-duration-btn py-2.5 px-1 rounded-lg border border-zinc-200 text-xs font-bold text-zinc-700 hover:bg-zinc-50">3 giờ</button>
                            <button type="button" id="drawer-duration-custom-btn" onclick="showDrawerCustomDuration()" class="py-2.5 px-1 rounded-lg border border-zinc-200 text-xs font-bold text-zinc-700 hover:bg-zinc-50">Khác</button>
                        </div>
                        <div id="drawer-custom-hours-wrap" class="hidden mt-2">
                            <label class="block text-[11px] font-bold text-zinc-500 mb-1">Nhập số giờ chơi:</label>
                            <input type="number" id="drawer-custom-hours" min="0.5" max="12" step="0.5" placeholder="VD: 1.5"
                                   oninput="setDrawerCustomDuration()"
                                   class="w-full text-xs p-2.5 border border-zinc-200 rounded-xl bg-zinc-50 focus:outline-none ${focusRing} focus:bg-white">
                        </div>
                    </div>

                    <div id="drawer-open-duration-note" class="hidden p-3 rounded-xl border ${themeBorder} ${themeBgLight} text-[11px] ${themeTextMedium} font-semibold mt-2">
                        Phiên chơi bắt đầu ngay và chưa có giờ kết thúc. Tạm tính sẽ được cập nhật theo thời gian sử dụng.
                    </div>
                </div>

                <div id="drawer-walkin-overlap-warning" class="hidden p-3 rounded-xl border border-red-200 bg-red-50 text-red-700 text-[11px] font-semibold flex items-start gap-2">
                    <span class="material-symbols-outlined text-[16px] mt-px">error</span>
                    <span id="drawer-walkin-overlap-text"></span>
                </div>

                <div>
                    <label class="block text-[11px] font-bold text-zinc-500 mb-1">Đơn giá tự áp dụng (VND / giờ):</label>
                    <input type="number" id="drawer-walkin-rate" name="donGia" step="10000" class="w-full text-xs p-2.5 border border-zinc-150 rounded-xl bg-zinc-100 cursor-not-allowed focus:outline-none" required readonly oninput="calculateDrawerPrice()">
                    <span id="drawer-walkin-rate-type" class="text-[10px] text-zinc-500 mt-1 block">Áp dụng: Giá không đèn</span>
                </div>

                <div class="p-3.5 bg-zinc-50 rounded-xl border border-zinc-150 space-y-1.5 text-xs">
                    <div class="flex items-center justify-between">
                        <span class="text-zinc-550">Bắt đầu:</span>
                        <span id="drawer-walkin-start-time" class="font-bold text-zinc-800">-</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <span class="text-zinc-550">Kết thúc dự kiến:</span>
                        <span id="drawer-walkin-end-time" class="font-bold text-zinc-800">-</span>
                    </div>
                    <div class="flex items-center justify-between pt-1.5 border-t border-zinc-150">
                        <span class="text-zinc-550 font-bold">Tạm tính tiền sân:</span>
                        <span id="drawer-walkin-total" class="font-extrabold text-sm ${themeTextMedium}">0 đ</span>
                    </div>
                </div>

                <div class="flex items-center gap-3 pt-1">
                    <button type="button" onclick="closeCourtDetailDrawer()" class="shrink-0 px-5 py-3 rounded-xl border border-zinc-200 text-zinc-600 font-extrabold text-xs hover:bg-zinc-50 transition-all active:scale-95">
                        Hủy
                    </button>
                    <button type="submit" id="drawer-walkin-submit-btn" class="flex-1 ${themeBg} ${themeBgHover} text-white font-extrabold text-sm py-3 rounded-xl shadow hover:shadow-md transition-all active:scale-95 flex items-center justify-center gap-1.5 disabled:opacity-60 disabled:cursor-not-allowed">
                        <span class="material-symbols-outlined text-[18px]">play_circle</span>
                        <span id="drawer-walkin-submit-label">Mở sân ngay</span>
                    </button>
                </div>
            </form>
        </div>

        <!-- Section B: Đang sử dụng -> Phiên chơi hiện tại -->
        <div id="drawer-action-active" class="hidden space-y-4">
            <div class="flex items-center gap-2 text-zinc-850 font-extrabold text-sm">
                <span class="material-symbols-outlined ${themeText}">sports_tennis</span>
                <span>Phiên chơi hiện tại</span>
            </div>

            <div class="space-y-3 ${themeBgLight} border ${themeBorder} rounded-2xl p-4 text-xs">
                <div class="flex justify-between">
                    <span class="text-zinc-550">Mã đơn đặt (DatSanID):</span>
                    <span id="drawer-active-id" class="font-bold text-zinc-800">-</span>
                </div>
                <div class="flex justify-between">
                    <span class="text-zinc-550">Giờ bắt đầu:</span>
                    <span id="drawer-active-start" class="font-bold text-zinc-800">-</span>
                </div>
                <div class="flex justify-between">
                    <span class="text-zinc-550">Kiểu giờ chơi:</span>
                    <span id="drawer-active-mode" class="font-bold text-zinc-800">-</span>
                </div>
                <!-- Dynamic Timer display row -->
                <div class="flex justify-between p-2.5 rounded-xl bg-white border ${themeBorder}" id="drawer-active-timer-row">
                    <span class="text-zinc-600 font-semibold" id="drawer-active-timer-label">Thời gian:</span>
                    <span id="drawer-active-timer-val" class="font-black text-sm text-zinc-800">-</span>
                </div>
                <div class="flex justify-between pt-2 border-t ${themeBorder} text-sm font-extrabold">
                    <span class="text-zinc-700">Tổng tiền sân tạm tính:</span>
                    <span id="drawer-active-total-price" class="${themeTextMedium}">0 đ</span>
                </div>
            </div>

            <!-- Stop Session Form (only for OPEN mode) -->
            <form id="drawer-stop-session-form" action="${pageContext.request.contextPath}/staff/checkin" method="post" class="hidden">
                <input type="hidden" name="action" value="stopOpenSession">
                <input type="hidden" id="drawer-stop-datsan-id" name="datSanId">
                <button type="submit" class="w-full bg-rose-600 hover:bg-rose-700 text-white font-black text-xs py-3 rounded-xl shadow-lg hover:shadow-rose-600/20 active:scale-95 transition-all flex items-center justify-center gap-1.5 animate-pulse">
                    <span class="material-symbols-outlined text-[18px]">stop_circle</span>
                    Dừng chơi & Tính tiền
                </button>
            </form>

            <button type="button" id="drawer-btn-invoice" class="w-full ${themeBg} ${themeBgHover} text-white font-extrabold text-xs py-3 rounded-xl shadow hover:shadow-md transition-all active:scale-95 flex items-center justify-center gap-1.5">
                <span class="material-symbols-outlined text-[18px]">payments</span>
                Dịch vụ & Thanh toán
            </button>
        </div>

        <!-- Section C: Bảo trì / Tạm đóng -> Không thể mở -->
        <div id="drawer-action-disabled" class="hidden bg-red-50/40 border border-red-100 text-red-900 rounded-xl p-4 text-xs flex items-center gap-2">
            <span class="material-symbols-outlined text-red-600 text-[18px]">warning</span>
            <span>Sân hiện đang bảo trì hoặc tạm đóng, không thể mở cho khách chơi.</span>
        </div>
        </div>
        </div>
    </div>
  </div>
</div>

<script>
    function formatCurrency(val) {
        if (val === undefined || val === null || isNaN(val)) return '0 đ';
        return Math.round(Number(val)).toLocaleString('vi-VN') + ' đ';
    }

    let staffProducts = [];
    let staffOrdered = [];
    let currentStaffDatSanId = -1;
    let currentProposedEarlyDiscount = 0;

    let currentStaffCatalogCat = "all";
    let currentStaffCatalogSearch = "";

    // ── Payment modal state machine: EDITING -> PROCESSING -> [AWAITING_TRANSFER -> VERIFYING_TRANSFER | CREATING_PAYOS -> AWAITING_PAYOS -> VERIFYING_PAYOS ->] SUCCESS ──
    const PaymentModalState = {
        EDITING: 'EDITING', PROCESSING: 'PROCESSING',
        AWAITING_TRANSFER: 'AWAITING_TRANSFER', VERIFYING_TRANSFER: 'VERIFYING_TRANSFER',
        CREATING_PAYOS: 'CREATING_PAYOS', AWAITING_PAYOS: 'AWAITING_PAYOS', VERIFYING_PAYOS: 'VERIFYING_PAYOS',
        SUCCESS: 'SUCCESS'
    };
    const PaymentMethod = { CASH: 'Tiền mặt', BANK_TRANSFER: 'Chuyển khoản', PAYOS: 'PayOS' };
    let currentPaymentModalState = PaymentModalState.EDITING;
    let staffInvoiceModalTriggerEl = null;
    let staffSuccessHoaDonId = null;
    let staffSuccessPrintUrl = '';
    let staffSuccessManagementUrl = '';
    let currentInvoiceDetailData = null;
    let currentBankTransferPayment = null;
    let currentPayOSPayment = null;
    let payosPollTimer = null;

    function setPaymentModalState(state) {
        currentPaymentModalState = state;
        const content = document.getElementById('staff-invoice-content');
        const success = document.getElementById('staff-payment-success');
        const bankPanel = document.getElementById('staff-bank-transfer-panel');
        const payosPanel = document.getElementById('staff-payos-panel');
        const footerEditing = document.getElementById('staff-footer-editing');
        const footerSuccess = document.getElementById('staff-footer-success');
        const footerAwaiting = document.getElementById('staff-footer-awaiting-transfer');
        const footerPayos = document.getElementById('staff-footer-awaiting-payos');
        const btn = document.getElementById('staff-payment-submit-btn');
        const icon = document.getElementById('staff-payment-submit-icon');
        const label = document.getElementById('staff-payment-submit-label');
        const subtitle = document.getElementById('staffInvoiceModalSubtitle');
        const confirmBtn = document.getElementById('staff-bank-transfer-confirm-btn');
        const confirmLabel = document.getElementById('staff-bank-transfer-confirm-label');
        const isCheckout = typeof currentActionMode !== 'undefined' && currentActionMode === PaymentActionMode.CHECKOUT;
        const isBankTransferMethod = document.getElementById('staff-pay-method-input')?.value === PaymentMethod.BANK_TRANSFER;
        const isPayOSMethod = document.getElementById('staff-pay-method-input')?.value === PaymentMethod.PAYOS;

        content.classList.add('hidden');
        success.classList.add('hidden');
        if (bankPanel) bankPanel.classList.add('hidden');
        if (payosPanel) payosPanel.classList.add('hidden');
        footerEditing.classList.add('hidden');
        footerSuccess.classList.add('hidden');
        if (footerAwaiting) footerAwaiting.classList.add('hidden');
        if (footerPayos) footerPayos.classList.add('hidden');

        if (state === PaymentModalState.SUCCESS) {
            success.classList.remove('hidden');
            footerSuccess.classList.remove('hidden');
            if (subtitle) subtitle.textContent = 'Thanh toán thành công · Xem trước & in hóa đơn';
            return;
        }

        if (state === PaymentModalState.AWAITING_TRANSFER || state === PaymentModalState.VERIFYING_TRANSFER) {
            if (bankPanel) bankPanel.classList.remove('hidden');
            if (footerAwaiting) footerAwaiting.classList.remove('hidden');
            if (subtitle) subtitle.textContent = 'Chờ khách chuyển khoản';
            if (confirmBtn) confirmBtn.disabled = (state === PaymentModalState.VERIFYING_TRANSFER);
            if (confirmLabel) confirmLabel.textContent = state === PaymentModalState.VERIFYING_TRANSFER ? 'Đang xác nhận...' : 'Xác nhận đã nhận tiền';
            return;
        }

        if (state === PaymentModalState.AWAITING_PAYOS || state === PaymentModalState.VERIFYING_PAYOS) {
            if (payosPanel) payosPanel.classList.remove('hidden');
            if (footerPayos) footerPayos.classList.remove('hidden');
            if (subtitle) subtitle.textContent = 'Chờ thanh toán PayOS';
            const statusLabel = document.getElementById('staff-payos-status-label');
            if (statusLabel) statusLabel.textContent = state === PaymentModalState.VERIFYING_PAYOS ? 'Đang xác nhận...' : 'Chờ thanh toán';
            return;
        }

        // EDITING / PROCESSING / CREATING_PAYOS
        content.classList.remove('hidden');
        footerEditing.classList.remove('hidden');
        if (subtitle) subtitle.textContent = 'Thêm dịch vụ hoặc hoàn tất thanh toán';
        if (btn) btn.disabled = (state === PaymentModalState.PROCESSING || state === PaymentModalState.CREATING_PAYOS);
        if (icon) icon.textContent = isCheckout ? ((isBankTransferMethod || isPayOSMethod) ? 'qr_code_2' : 'payments') : 'save';
        if (label) {
            if (state === PaymentModalState.PROCESSING || state === PaymentModalState.CREATING_PAYOS) {
                label.textContent = isCheckout ? (isPayOSMethod ? 'Đang tạo mã...' : isBankTransferMethod ? 'Đang khởi tạo...' : 'Đang thanh toán...') : 'Đang lưu...';
            } else if (isCheckout) {
                label.textContent = isPayOSMethod ? 'Tạo mã thanh toán' : isBankTransferMethod ? 'Tiếp tục chuyển khoản' : 'Thanh toán';
            } else {
                label.textContent = 'Lưu dịch vụ';
            }
        }
    }

    function filterStaffCatalog(cat, button) {
        document.querySelectorAll(".pos-tab").forEach(btn => btn.classList.remove("active"));
        button.classList.add("active");
        currentStaffCatalogCat = cat;
        renderStaffProductCatalog(cat, currentStaffCatalogSearch);
    }

    function searchStaffCatalog(val) {
        currentStaffCatalogSearch = val.trim().toLowerCase();
        renderStaffProductCatalog(currentStaffCatalogCat, currentStaffCatalogSearch);
    }

    function getProductCategory(prod) {
        if (!prod || !prod.TenSanPham) return "others";
        const name = prod.TenSanPham.toLowerCase();
        if (name.includes("nước") || name.includes("coca") || name.includes("sting") || name.includes("revive") || name.includes("trà") || name.includes("aquafina") || name.includes("lon") || name.includes("chai") || name.includes("h2o")) {
            return "drinks";
        }
        if (name.includes("thuê") || name.includes("vợt") || name.includes("bóng") || name.includes("giày") || name.includes("áo") || name.includes("bib") || name.includes("vớ") || name.includes("phục vụ")) {
            return "rentals";
        }
        return "others";
    }

    function renderStaffProductCatalog(filterCat = 'all', keyword = '') {
        const container = document.getElementById("staff-product-catalog");
        if (!container) return;
        container.innerHTML = "";

        let filtered = staffProducts || [];

        // 1. Filter by category tab
        if (filterCat !== 'all') {
            filtered = filtered.filter(p => getProductCategory(p) === filterCat);
        }

        // 2. Filter by search input keyword
        if (keyword) {
            filtered = filtered.filter(p => p.TenSanPham && p.TenSanPham.toLowerCase().includes(keyword));
        }

        if (filtered.length === 0) {
            container.innerHTML = `<div class="col-span-full py-12 text-center text-xs text-zinc-400 italic">Không tìm thấy sản phẩm nào.</div>`;
            return;
        }

        filtered.forEach(prod => {
            const isOutOfStock = prod.SoLuongTon <= 0;
            const cardClass = isOutOfStock ? "pos-card disabled" : "pos-card";
            const stockText = isOutOfStock 
                ? `<span class="px-2 py-0.5 rounded-md bg-red-50 text-red-650 font-bold text-[9px] uppercase tracking-wide">Hết hàng</span>` 
                : `<span class="text-[10px] text-zinc-500 font-semibold">Kho: <strong class="text-zinc-700 font-bold">\${prod.SoLuongTon}</strong></span>`;
            
            const cat = getProductCategory(prod);
            const icon = cat === 'drinks' ? 'local_cafe' : cat === 'rentals' ? 'sports_tennis' : 'grid_view';
            const iconBg = cat === 'drinks' ? 'bg-blue-50 text-blue-600' : cat === 'rentals' ? 'bg-orange-50 text-orange-600' : 'bg-slate-100 text-slate-600';

            const cardHtml = `
                <div class="\${cardClass}" onclick="if(!this.classList.contains('disabled')) quickAddProduct(\${prod.SanPhamID}, 1)">
                    <div class="flex items-start gap-2">
                        <div class="w-8 h-8 rounded-lg \${iconBg} flex items-center justify-center shrink-0">
                            <span class="material-symbols-outlined text-[16px]">\${icon}</span>
                        </div>
                        <div class="min-w-0 flex-1">
                            <p class="font-bold text-zinc-800 text-[12px] truncate leading-tight" title="\${prod.TenSanPham}">\${prod.TenSanPham}</p>
                            <p class="text-[10px] text-zinc-400 mt-0.5 capitalize">\${prod.DonViTinh || 'cái'}</p>
                        </div>
                    </div>
                    <div class="flex items-center justify-between mt-3 pt-1 border-t border-zinc-50">
                        <span class="font-black text-[12.5px] text-zinc-900">\${formatCurrency(prod.DonGia)}</span>
                        \${stockText}
                    </div>
                </div>
            `;
            container.insertAdjacentHTML("beforeend", cardHtml);
        });
    }

    function quickAddProduct(spId, qty) {
        const prod = staffProducts.find(p => p.SanPhamID === spId);
        if (!prod) return;

        if (prod.SoLuongTon <= 0) {
            alert("Sản phẩm này đã hết hàng!");
            return;
        }

        const existing = staffOrdered.find(o => o.SanPhamID === spId);
        if (existing) {
            const newQty = existing.SoLuong + qty;
            if (newQty > prod.SoLuongTon) {
                alert(`Không thể chọn vượt quá số lượng tồn kho (\${prod.SoLuongTon})`);
                return;
            }
            existing.SoLuong = newQty;
            existing.ThanhTien = newQty * existing.DonGiaTaiThoiDiemBan;
        } else {
            staffOrdered.push({
                SanPhamID: spId,
                SoLuong: qty,
                DonGiaTaiThoiDiemBan: prod.DonGia,
                ThanhTien: qty * prod.DonGia
            });
        }
        renderStaffOrderedTable();
    }

    function openStaffInvoiceModal(datSanId) {
        currentStaffDatSanId = datSanId;
        document.getElementById("staff-save-datsan-id").value = datSanId;
        document.getElementById("staff-pay-datsan-id").value = datSanId;
        currentBankTransferPayment = null;
        currentPayOSPayment = null;
        stopPayOSPolling();
        currentInvoiceDetailData = null;
        document.getElementById('bank-not-configured-banner')?.classList.add('hidden');

        staffInvoiceModalTriggerEl = document.activeElement;
        setPaymentModalState(PaymentModalState.EDITING);

        const modal = document.getElementById("staffInvoiceModal");
        const loading = document.getElementById("staff-invoice-loading");
        const content = document.getElementById("staff-invoice-content");

        modal.classList.remove("hidden");
        modal.classList.add("flex");
        loading.classList.remove("hidden");
        content.classList.add("hidden");

        setTimeout(() => {
            modal.classList.remove("opacity-0");
            modal.querySelector(".bg-white").classList.remove("scale-95");
        }, 10);

        fetchAndRenderInvoiceDetails(datSanId, { isInitialLoad: true })
            .then(() => {
                loading.classList.add("hidden");
                content.classList.remove("hidden");
                const searchInput = document.getElementById("staff-catalog-search");
                if (searchInput) searchInput.focus();
            })
            .catch(err => {
                loading.classList.add("hidden");
                // Hiển thị inline error state — không dùng alert(), không đóng modal
                let errorContainer = document.getElementById('staff-invoice-load-error');
                if (!errorContainer) {
                    errorContainer = document.createElement('div');
                    errorContainer.id = 'staff-invoice-load-error';
                    errorContainer.className = 'flex flex-col items-center justify-center gap-4 py-12 px-6 text-center';
                    modal.querySelector('.bg-white').appendChild(errorContainer);
                }
                errorContainer.innerHTML = `
                    <span class="material-symbols-outlined text-red-400 text-5xl">error_outline</span>
                    <div>
                        <p class="font-bold text-zinc-800 text-sm">Không thể tải thông tin thanh toán</p>
                        <p class="text-xs text-zinc-500 mt-1">Dữ liệu ca chơi chưa được tải. Vui lòng thử lại.</p>
                    </div>
                    <div class="flex gap-3">
                        <button type="button" onclick="document.getElementById('staff-invoice-load-error').remove();openStaffInvoiceModal(${datSanId})"
                            class="px-4 py-2 rounded-lg bg-violet-600 text-white text-xs font-bold hover:bg-violet-700 transition-colors">
                            Thử lại
                        </button>
                        <button type="button" onclick="closeStaffInvoiceModal()"
                            class="px-4 py-2 rounded-lg border border-zinc-200 text-zinc-600 text-xs font-bold hover:bg-zinc-50 transition-colors">
                            Đóng
                        </button>
                    </div>
                `;
                errorContainer.classList.remove('hidden');
            });
    }

    // Dùng chung bởi lần mở modal đầu tiên VÀ lần refresh sau khi lưu dịch vụ thành công -
    // một nguồn dữ liệu, một chỗ populate DOM, tránh lệch dữ liệu giữa hai luồng.
    async function fetchAndRenderInvoiceDetails(datSanId, opts) {
        opts = opts || {};
        const res = await fetch('${pageContext.request.contextPath}/staff/checkin?action=getInvoiceDetails&datSanId=' + datSanId);
        if (!res.ok) {
            const text = await res.text();
            try {
                const errData = JSON.parse(text);
                // Nhận cả format cũ {error:...} và mới {success:false, message:...}
                const msg = errData.message || errData.error || ('Lỗi server: ' + res.status);
                throw new Error(msg);
            } catch (parseErr) {
                if (parseErr.message && !parseErr.message.startsWith('Lỗi server')) {
                    throw parseErr;
                }
                throw new Error('Lỗi server (' + res.status + '). Vui lòng tải lại trang.');
            }
        }
        const data = await res.json();

        staffProducts = data.products || [];
        staffOrdered = data.ordered || [];
        currentProposedEarlyDiscount = data.proposedEarlyDiscount || 0;

        document.getElementById("staff-invoice-court-name").textContent = data.tenSan;
        document.getElementById("staff-invoice-time-slot").textContent = data.gioBatDau + ' - ' + data.gioKetThuc;

        const statusBadge = document.getElementById("staff-invoice-payment-status");
        statusBadge.textContent = data.trangThaiThanhToan;
        statusBadge.className = data.trangThaiThanhToan === 'Đã thanh toán' ? "badge badge-green" : "badge badge-amber";

        // Handle split bill state
        currentMainBillPaid = !!data.mainBillPaid;
        const lblMain = document.getElementById('lbl-billmode-main');
        if (currentMainBillPaid) {
            // Main đã thanh toán → khóa chế độ MAIN, ép SPLIT
            lblMain.disabled = true;
            lblMain.classList.add('opacity-40', 'cursor-not-allowed');
            setBillMode('SPLIT');
        } else {
            lblMain.disabled = false;
            lblMain.classList.remove('opacity-40', 'cursor-not-allowed');
            setBillMode('MAIN');
        }
        renderSplitBillsList(data.splitBills || []);

        // Populate court details (disclosure - "Xem chi tiết")
        document.getElementById("staff-detail-court-rate").textContent = formatCurrency(data.donGiaGio) + "/giờ";
        document.getElementById("staff-detail-start-time").textContent = data.gioBatDau;
        document.getElementById("staff-detail-end-time").textContent = data.gioKetThuc;

        const earlyContainer = document.getElementById("staff-detail-early-container");
        if (data.phuThuNhanSom > 0) {
            earlyContainer.classList.remove("hidden");
            document.getElementById("staff-detail-early-surcharge").textContent = formatCurrency(data.phuThuNhanSom);
        } else {
            earlyContainer.classList.add("hidden");
        }

        const lateContainer = document.getElementById("staff-detail-late-container");
        if (data.minutesOver > 10) {
            lateContainer.classList.remove("hidden");
            document.getElementById("staff-detail-late-minutes").textContent = data.minutesOver;
            document.getElementById("staff-detail-late-surcharge").textContent = formatCurrency(data.phuThuQuaGio);
        } else {
            lateContainer.classList.add("hidden");
        }

        // Tiền sân / Giảm giá / Phí gửi xe (backend là nguồn sự thật, không tự tính bằng JS)
        const summaryCourtPriceEl = document.getElementById("staff-summary-court-price");
        summaryCourtPriceEl.textContent = formatCurrency(data.tongTienSan);
        summaryCourtPriceEl.setAttribute("data-val", data.tongTienSan);

        const discountEl = document.getElementById("staff-summary-discount");
        if (discountEl) { discountEl.textContent = formatCurrency(data.giamGia || 0); discountEl.setAttribute('data-val', data.giamGia || 0); }
        const parkingEl = document.getElementById("staff-summary-parking");
        if (parkingEl) { parkingEl.textContent = formatCurrency(data.phiGuiXe || 0); parkingEl.setAttribute('data-val', data.phiGuiXe || 0); }

        renderExtensionPanel(data);

        if (opts.isInitialLoad) {
            // Reset search/category chỉ khi mở modal lần đầu - không reset giữa lúc đang thao tác.
            const searchInput = document.getElementById("staff-catalog-search");
            if (searchInput) searchInput.value = "";
            currentStaffCatalogSearch = "";
            document.querySelectorAll(".pos-tab").forEach(btn => btn.classList.remove("active"));
            const defaultTab = document.querySelector(".pos-tab[onclick*='all']");
            if (defaultTab) defaultTab.classList.add("active");
            currentStaffCatalogCat = "all";

            // Mặc định actionMode dựa trên dữ liệu backend (đã chốt giờ / đã thanh toán / đã qua giờ kết thúc),
            // không dựa trên text hiển thị.
            setActionMode(computeDefaultActionMode(data));
        }

        renderStaffProductCatalog(currentStaffCatalogCat, currentStaffCatalogSearch);

        // Populate products select (for legacy bindings)
        const select = document.getElementById("staff-product-select");
        if (select) {
            select.innerHTML = '<option value="">-- Chọn sản phẩm thêm --</option>';
            staffProducts.forEach(prod => {
                const statusText = prod.SoLuongTon <= 0 ? ' - HẾT HÀNG' : ` - Kho: \${prod.SoLuongTon}`;
                select.insertAdjacentHTML("beforeend", `<option value="\${prod.SanPhamID}">\${prod.TenSanPham} (\${formatCurrency(prod.DonGia)} / \${prod.DonViTinh || 'cái'}\${statusText})</option>`);
            });
        }

        // Update early checkout warning & discount views
        const warningPanel = document.getElementById("staff-detail-early-checkout-warning-panel");
        const earlyMinsEl = document.getElementById("staff-detail-early-checkout-minutes");
        const earlyDiscountContainer = document.getElementById("staff-detail-early-discount-container");
        const earlyDiscountValEl = document.getElementById("staff-detail-early-discount-value");

        if (warningPanel) {
            if (data.isEarly && data.trangThaiThanhToan !== 'Đã thanh toán') {
                warningPanel.classList.remove("hidden");
                if (earlyMinsEl) earlyMinsEl.textContent = data.minutesEarly;
            } else {
                warningPanel.classList.add("hidden");
            }
        }

        if (earlyDiscountContainer) {
            if (data.earlyCheckoutDiscount > 0) {
                earlyDiscountContainer.classList.remove("hidden");
                if (earlyDiscountValEl) earlyDiscountValEl.textContent = "-" + formatCurrency(data.earlyCheckoutDiscount);
            } else {
                earlyDiscountContainer.classList.add("hidden");
            }
        }

        renderStaffOrderedTable();
        currentInvoiceDetailData = data;
        setPaymentModalState(currentPaymentModalState); // refresh nhãn nút chính theo actionMode hiện tại

        // Mở lại modal cho hóa đơn đang chờ chuyển khoản (đóng rồi mở lại): tái dựng panel AWAITING_TRANSFER
        // thay vì EDITING - initBankTransfer ở backend là idempotent, tái dùng nguyên reference/amount cũ.
        if (opts.isInitialLoad && data.trangThaiThanhToan === 'Chờ xác nhận chuyển khoản') {
            setActionMode(PaymentActionMode.CHECKOUT);
            changeStaffPayMethod(PaymentMethod.BANK_TRANSFER);
            handleInitBankTransfer();
        }
        return data;
    }

    // ── Mục đích thao tác: Thêm dịch vụ (ADD_SERVICES) hoặc Thanh toán & kết thúc (CHECKOUT) ──
    const PaymentActionMode = { ADD_SERVICES: 'ADD_SERVICES', CHECKOUT: 'CHECKOUT' };
    let currentActionMode = PaymentActionMode.ADD_SERVICES;

    function parseBookingDateTime(ngayDat, hhmm) {
        if (!ngayDat || !hhmm) return null;
        const dateParts = ngayDat.split('-').map(Number);
        const timeParts = hhmm.split(':').map(Number);
        if (dateParts.length < 3 || timeParts.length < 2) return null;
        const [y, m, d] = dateParts;
        const [hh, mm] = timeParts;
        if (!y || !m || !d || Number.isNaN(hh) || Number.isNaN(mm)) return null;
        return new Date(y, m - 1, d, hh, mm, 0);
    }

    // Chỉ dùng dữ liệu backend (trạng thái thanh toán, đã chốt giờ actualEndAt, giờ kết thúc dự kiến)
    // để chọn mặc định - không dựa vào text hiển thị frontend.
    function computeDefaultActionMode(data) {
        if (data.trangThaiThanhToan === 'Đã thanh toán') return PaymentActionMode.CHECKOUT;
        if (data.actualEndAt) return PaymentActionMode.CHECKOUT; // OPEN_ENDED đã "Dừng chơi & Tính tiền"
        if (data.timeMode !== 'OPEN_ENDED') {
            const plannedEnd = parseBookingDateTime(data.ngayDat, data.gioKetThuc);
            if (plannedEnd && new Date() >= plannedEnd) return PaymentActionMode.CHECKOUT;
        }
        return PaymentActionMode.ADD_SERVICES;
    }

    function setActionMode(mode) {
        currentActionMode = mode;
        const isCheckout = mode === PaymentActionMode.CHECKOUT;

        const btnAdd = document.getElementById('action-mode-btn-add');
        const btnCheckout = document.getElementById('action-mode-btn-checkout');
        if (btnAdd) { btnAdd.classList.toggle('active', !isCheckout); btnAdd.setAttribute('aria-checked', String(!isCheckout)); }
        if (btnCheckout) { btnCheckout.classList.toggle('active', isCheckout); btnCheckout.setAttribute('aria-checked', String(isCheckout)); }

        const paymentMethodSection = document.getElementById('payment-method-section');
        if (paymentMethodSection) paymentMethodSection.classList.toggle('hidden', !isCheckout);

        const discountVal = parseFloat(document.getElementById('staff-summary-discount')?.getAttribute('data-val') || '0');
        const parkingVal = parseFloat(document.getElementById('staff-summary-parking')?.getAttribute('data-val') || '0');
        document.getElementById('summary-row-court')?.classList.toggle('hidden', !isCheckout);
        document.getElementById('summary-row-total')?.classList.toggle('hidden', !isCheckout);
        document.getElementById('summary-row-discount')?.classList.toggle('hidden', !(isCheckout && discountVal > 0));
        document.getElementById('summary-row-parking')?.classList.toggle('hidden', !(isCheckout && parkingVal > 0));
        if (!isCheckout) {
            document.getElementById('court-price-detail')?.classList.add('hidden');
            document.getElementById('court-detail-toggle')?.setAttribute('aria-expanded', 'false');
        }

        const errorBox = document.getElementById('staff-payment-error');
        if (errorBox) errorBox.classList.add('hidden');

        setPaymentModalState(currentPaymentModalState); // cập nhật nhãn/icon nút chính
    }

    function toggleCourtPriceDetail() {
        const panel = document.getElementById('court-price-detail');
        const toggle = document.getElementById('court-detail-toggle');
        if (!panel) return;
        const nowHidden = panel.classList.toggle('hidden');
        if (toggle) toggle.setAttribute('aria-expanded', String(!nowHidden));
    }

    function showStaffPaymentError(message) {
        const errorBox = document.getElementById('staff-payment-error');
        if (!errorBox) return;
        errorBox.textContent = message;
        errorBox.classList.remove('hidden');
    }

    function showStaffToast(message) {
        let toast = document.getElementById('staff-toast');
        if (!toast) {
            toast = document.createElement('div');
            toast.id = 'staff-toast';
            toast.setAttribute('role', 'status');
            toast.className = 'fixed bottom-6 left-1/2 -translate-x-1/2 bg-zinc-900 text-white text-sm font-semibold px-4 py-2.5 rounded-lg shadow-lg z-[70] transition-opacity duration-300';
            toast.style.opacity = '0';
            document.body.appendChild(toast);
        }
        toast.textContent = message;
        requestAnimationFrame(() => { toast.style.opacity = '1'; });
        clearTimeout(toast._hideTimer);
        toast._hideTimer = setTimeout(() => { toast.style.opacity = '0'; }, 2500);
    }

    // Một handler duy nhất cho nút hành động chính - hành vi rẽ theo actionMode + phương thức thanh toán.
    function handlePrimaryPaymentAction() {
        if (currentPaymentModalState !== PaymentModalState.EDITING) return;
        if (currentActionMode === PaymentActionMode.ADD_SERVICES) {
            handleSaveServicesAction();
            return;
        }
        const method = document.getElementById('staff-pay-method-input')?.value || '';
        if (method === PaymentMethod.PAYOS) {
            handleCreatePayOSPayment();
        } else if (method === PaymentMethod.BANK_TRANSFER) {
            handleInitBankTransfer();
        } else {
            handleStaffPaymentSubmit();
        }
    }

    function renderStaffOrderedTable() {
        const cartList = document.getElementById("staff-cart-list");
        if (!cartList) return;
        cartList.innerHTML = "";
        
        let totalItems = 0;
        
        if (staffOrdered.length === 0) {
            cartList.innerHTML = `
                <div class="flex flex-col items-center justify-center text-center py-14 px-4 border-2 border-dashed border-slate-100 rounded-2xl h-full min-h-[300px]">
                    <div class="w-10 h-10 rounded-full bg-slate-50 flex items-center justify-center text-slate-400 mb-2.5">
                        <span class="material-symbols-outlined text-[20px]">shopping_cart</span>
                    </div>
                    <p class="text-xs font-bold text-slate-700">Chưa có dịch vụ nào được thêm</p>
                    <p class="text-[10px] text-slate-400 mt-1 max-w-[200px]">Chọn sản phẩm từ danh sách bên trái để bắt đầu.</p>
                </div>
            `;
        } else {
            staffOrdered.forEach(item => {
                const prod = staffProducts.find(p => p.SanPhamID === item.SanPhamID);
                const prodName = prod ? prod.TenSanPham : ('Sản phẩm #' + item.SanPhamID);
                const unit = prod ? (prod.DonViTinh || 'cái') : 'cái';
                const formattedPrice = item.DonGiaTaiThoiDiemBan.toLocaleString('vi-VN');
                const formattedTotal = item.ThanhTien.toLocaleString('vi-VN');
                
                totalItems += item.SoLuong;
                
                cartList.insertAdjacentHTML("beforeend", `
                    <div class="cart-item">
                        <div class="min-w-0 flex-grow">
                            <p class="font-bold text-slate-800 text-xs truncate" title="\${prodName}">\${prodName}</p>
                            <p class="text-[9px] text-slate-400 mt-0.5 capitalize">\${unit} • \${formattedPrice} đ</p>
                        </div>
                        
                        <!-- Stepper count -->
                        <div class="flex items-center gap-1 shrink-0">
                            <button type="button" onclick="adjustStaffItemQty(\${item.SanPhamID}, -1)" class="stepper-btn">-</button>
                            <span class="font-bold text-xs w-6 text-center text-slate-800">\${item.SoLuong}</span>
                            <button type="button" onclick="adjustStaffItemQty(\${item.SanPhamID}, 1)" class="stepper-btn">+</button>
                        </div>
                        
                        <!-- Line total price & Delete -->
                        <div class="flex items-center gap-2 shrink-0">
                            <span class="font-extrabold text-xs text-slate-800 text-right min-w-[70px]">\${formattedTotal} đ</span>
                            <button type="button" onclick="removeStaffItem(\${item.SanPhamID})" class="p-1 rounded text-red-500 hover:bg-red-50 hover:text-red-650 transition-colors flex items-center justify-center">
                                <span class="material-symbols-outlined text-[16px]">close</span>
                            </button>
                        </div>
                    </div>
                `);
            });
        }

        // Update item count badge in Column 2
        const countText = staffOrdered.length === 1 ? '1 mặt hàng' : `\${staffOrdered.length} mặt hàng`;
        const countEl = document.getElementById("staff-cart-item-count");
        if (countEl) countEl.textContent = countText;

        recalculateStaffTotals();
        updateBillModeSectionVisibility();
    }

    function adjustStaffItemQty(spId, delta) {
        const prod = staffProducts.find(p => p.SanPhamID === spId);
        if (!prod) return;
        
        const item = staffOrdered.find(o => o.SanPhamID === spId);
        if (!item) return;

        let newQty = item.SoLuong + delta;
        if (newQty <= 0) {
            removeStaffItem(spId);
            return;
        }

        if (newQty > prod.SoLuongTon) {
            alert(`Không thể chọn vượt quá số lượng tồn kho (\${prod.SoLuongTon})`);
            newQty = prod.SoLuongTon;
        }

        item.SoLuong = newQty;
        item.ThanhTien = newQty * item.DonGiaTaiThoiDiemBan;
        renderStaffOrderedTable();
    }

    function removeStaffItem(spId) {
        staffOrdered = staffOrdered.filter(o => o.SanPhamID !== spId);
        renderStaffOrderedTable();
    }

    function addServiceToInvoiceList() {
        const select = document.getElementById("staff-product-select");
        const qtyInput = document.getElementById("staff-product-qty");
        
        const spId = parseInt(select.value);
        const qty = parseInt(qtyInput.value) || 1;
        
        if (!spId) {
            alert("Vui lòng chọn sản phẩm.");
            return;
        }

        const prod = staffProducts.find(p => p.SanPhamID === spId);
        if (!prod) return;

        if (qty > prod.SoLuongTon) {
            alert(`Sản phẩm này chỉ còn tồn kho: \${prod.SoLuongTon}`);
            return;
        }

        // Check if already ordered
        const existing = staffOrdered.find(o => o.SanPhamID === spId);
        if (existing) {
            const newQty = existing.SoLuong + qty;
            if (newQty > prod.SoLuongTon) {
                alert(`Không thể thêm vì tổng số lượng vượt quá tồn kho (\${prod.SoLuongTon})`);
                return;
            }
            existing.SoLuong = newQty;
            existing.ThanhTien = newQty * existing.DonGiaTaiThoiDiemBan;
        } else {
            staffOrdered.push({
                SanPhamID: spId,
                SoLuong: qty,
                DonGiaTaiThoiDiemBan: prod.DonGia,
                ThanhTien: qty * prod.DonGia
            });
        }

        select.value = "";
        qtyInput.value = "1";
        renderStaffOrderedTable();
    }

    function openEarlyCheckoutAdjustmentModal() {
        const modal = document.getElementById("earlyCheckoutAdjustmentModal");
        if (!modal) return;
        
        const datSanId = currentStaffDatSanId;
        const courtPriceVal = parseFloat(document.getElementById("staff-summary-court-price").getAttribute("data-val")) || 0;
        
        document.getElementById("early-adjust-datsan-id").value = datSanId;
        document.getElementById("early-adjust-court-total").value = formatCurrency(courtPriceVal);
        document.getElementById("early-adjust-discount-amount").max = courtPriceVal;
        document.getElementById("early-adjust-discount-amount").value = currentProposedEarlyDiscount;
        document.getElementById("early-adjust-reason").value = "Khách trả sân sớm";
        
        modal.classList.remove("hidden");
        modal.classList.add("flex");
        setTimeout(() => {
            modal.classList.remove("opacity-0");
            modal.querySelector(".bg-white").classList.remove("scale-95");
        }, 10);
    }

    function closeEarlyCheckoutAdjustmentModal() {
        const modal = document.getElementById("earlyCheckoutAdjustmentModal");
        if (!modal) return;
        modal.classList.add("opacity-0");
        modal.querySelector(".bg-white").classList.add("scale-95");
        setTimeout(() => {
            modal.classList.add("hidden");
            modal.classList.remove("flex");
        }, 300);
    }

    function recalculateStaffTotals() {
        let serviceTotal = 0;
        staffOrdered.forEach(item => {
            serviceTotal += item.ThanhTien;
        });

        const summaryCourtPriceEl = document.getElementById("staff-summary-court-price");
        const courtPriceVal = parseFloat(summaryCourtPriceEl.getAttribute("data-val")) || 0;
        
        const totalVal = courtPriceVal + serviceTotal;
        
        const cartSubtotalEl = document.getElementById("staff-cart-subtotal");
        if (cartSubtotalEl) cartSubtotalEl.textContent = serviceTotal.toLocaleString('vi-VN') + " đ";
        
        document.getElementById("staff-summary-services-price").textContent = serviceTotal.toLocaleString('vi-VN') + " đ";
        document.getElementById("staff-summary-total").textContent = totalVal.toLocaleString('vi-VN') + " đ";
    }

    function changeStaffPayMethod(method) {
        document.getElementById("staff-pay-method-input").value = method;
        document.getElementById("staff-save-paymethod").value = method;

        const lblCash = document.getElementById("lbl-pay-cash");
        const lblTransfer = document.getElementById("lbl-pay-transfer");

        if (lblCash && lblTransfer) {
            const isCash = method === PaymentMethod.CASH;
            lblCash.classList.toggle("active", isCash);
            lblCash.setAttribute('aria-checked', String(isCash));
            lblTransfer.classList.toggle("active", !isCash);
            lblTransfer.setAttribute('aria-checked', String(!isCash));
        }
        document.getElementById('bank-not-configured-banner')?.classList.add('hidden');
        if (currentPaymentModalState === PaymentModalState.EDITING) setPaymentModalState(PaymentModalState.EDITING);
    }

    let isStaffPaymentSubmitting = false;

    // Trả về true nếu người dùng xác nhận muốn tiếp tục thanh toán (dialog xác nhận thuần phía client).
    function confirmPaymentSubmit() {
        const splitSection = document.getElementById('split-bills-section');
        if (splitSection && !splitSection.classList.contains('hidden')) {
            const unpaidBtns = splitSection.querySelectorAll('button[onclick^="paySplitBill"]');
            if (unpaidBtns.length > 0) {
                return confirm(`⚠️ Có \${unpaidBtns.length} hóa đơn tách dịch vụ CHƯA thanh toán!\nNếu tiếp tục, hệ thống sẽ từ chối yêu cầu kết thúc ca chơi.\n\nBạn vẫn muốn thử?`);
            }
        }
        return confirm("Xác nhận khách đã thanh toán đơn này? Sân bóng sẽ được giải phóng về trạng thái Sẵn sàng.");
    }

    // Chặn submit form truyền thống, thay bằng fetch POST. Sau khi backend xác nhận transaction
    // đã commit thành công, modal chuyển sang PAYMENT_SUCCESS và hiển thị hóa đơn thật ngay tại chỗ -
    // không điều hướng sang /staff/hoa-don/in (route đó vẫn được giữ cho in lại / Quản lý hóa đơn / fallback).
    async function handleStaffPaymentSubmit() {
        if (isStaffPaymentSubmitting || currentPaymentModalState !== PaymentModalState.EDITING) return;

        // Lock flag immediately
        isStaffPaymentSubmitting = true;

        // Show loading state and disable button immediately
        const btn = document.getElementById('staff-payment-submit-btn');
        const label = document.getElementById('staff-payment-submit-label');
        if (btn) btn.disabled = true;
        if (label) label.textContent = 'Đang thanh toán...';

        // Now run the confirm dialog
        if (!confirmPaymentSubmit()) {
            // If cancelled, reset flag and restore state
            isStaffPaymentSubmitting = false;
            if (btn) btn.disabled = false;
            if (label) label.textContent = 'Thanh toán';
            return;
        }

        const datSanIdText = document.getElementById('staff-pay-datsan-id')?.value?.trim() || '';
        const datSanId = Number(datSanIdText);
        const paymentMethod = document.getElementById('staff-pay-method-input')?.value || '';
        if (!Number.isInteger(datSanId) || datSanId <= 0) {
            showStaffPaymentError('Không xác định được phiên chơi cần thanh toán. Vui lòng đóng và mở lại cửa sổ thanh toán.');
            isStaffPaymentSubmitting = false;
            if (btn) btn.disabled = false;
            if (label) label.textContent = 'Thanh toán';
            return;
        }
        if (!['Tiền mặt', 'Chuyển khoản'].includes(paymentMethod)) {
            showStaffPaymentError('Vui lòng chọn phương thức thanh toán.');
            isStaffPaymentSubmitting = false;
            if (btn) btn.disabled = false;
            if (label) label.textContent = 'Thanh toán';
            return;
        }

        const params = new URLSearchParams();
        params.set('action', 'processPayment');
        params.set('datSanId', String(datSanId));
        params.set('phuongThucThanhToan', paymentMethod);
        const paymentUrl = '${pageContext.request.contextPath}/staff/checkin';

        setPaymentModalState(PaymentModalState.PROCESSING);
        document.getElementById('staff-payment-error')?.classList.add('hidden');

        try {
            const response = await fetch(paymentUrl, {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: params.toString()
            });
            const contentType = response.headers.get('content-type') || '';
            const rawText = await response.text();
            if (!contentType.includes('application/json')) {
                console.error('Non-JSON payment response:', {status: response.status, contentType, body: rawText});
                throw new Error(`Máy chủ trả về HTTP \${response.status} nhưng không có JSON. Vui lòng kiểm tra Network và log Tomcat.`);
            }
            let data;
            try { data = JSON.parse(rawText); }
            catch (parseError) { throw new Error(`Máy chủ trả về JSON không hợp lệ (HTTP \${response.status}).`); }
            if (!response.ok || !data.success) {
                throw new Error(data.message || (`Thanh toán không thành công (HTTP \${response.status}).`));
            }
            if (!data.hoaDonId) throw new Error('Thanh toán thành công nhưng máy chủ không trả mã hóa đơn.');
            isStaffPaymentSubmitting = false;
            await showPaymentSuccessInvoice({ hoaDonId: data.hoaDonId, printUrl: data.printUrl });
        } catch (err) {
            isStaffPaymentSubmitting = false;
            setPaymentModalState(PaymentModalState.EDITING);
            showStaffPaymentError(err.message || 'Đã có lỗi xảy ra, vui lòng thử lại.');
        }
    }

    // ── Chuyển khoản: EDITING -> (initBankTransfer) -> AWAITING_TRANSFER -> (confirmBankTransfer) -> SUCCESS ──

    // Chọn "Chuyển khoản" rồi bấm nút chính chỉ khởi tạo yêu cầu chuyển khoản (chốt tiền sân, chuyển
    // hóa đơn sang chờ xác nhận) - KHÔNG đánh dấu đã thanh toán, KHÔNG giải phóng sân, KHÔNG đóng modal.
    async function handleInitBankTransfer() {
        if (isStaffPaymentSubmitting || currentPaymentModalState !== PaymentModalState.EDITING) return;

        isStaffPaymentSubmitting = true;
        const btn = document.getElementById('staff-payment-submit-btn');
        const label = document.getElementById('staff-payment-submit-label');
        if (btn) btn.disabled = true;
        if (label) label.textContent = 'Đang khởi tạo...';

        const datSanIdText = document.getElementById('staff-pay-datsan-id')?.value?.trim() || '';
        const datSanId = Number(datSanIdText);
        if (!Number.isInteger(datSanId) || datSanId <= 0) {
            showStaffPaymentError('Không xác định được phiên chơi cần thanh toán. Vui lòng đóng và mở lại cửa sổ thanh toán.');
            isStaffPaymentSubmitting = false;
            if (btn) btn.disabled = false;
            if (label) label.textContent = 'Tiếp tục chuyển khoản';
            return;
        }

        const params = new URLSearchParams();
        params.set('action', 'initBankTransfer');
        params.set('datSanId', String(datSanId));

        setPaymentModalState(PaymentModalState.PROCESSING);
        document.getElementById('staff-payment-error')?.classList.add('hidden');

        try {
            const response = await fetch('${pageContext.request.contextPath}/staff/checkin', {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: params.toString()
            });
            const rawText = await response.text();
            let data;
            try { data = JSON.parse(rawText); }
            catch (parseError) { throw new Error(`Máy chủ trả về JSON không hợp lệ (HTTP \${response.status}).`); }

            isStaffPaymentSubmitting = false;

            if (!response.ok || !data.success) {
                if (data.code === 'BANK_NOT_CONFIGURED') {
                    document.getElementById('bank-not-configured-banner')?.classList.remove('hidden');
                    setPaymentModalState(PaymentModalState.EDITING);
                    return;
                }
                throw new Error(data.message || 'Không thể khởi tạo yêu cầu chuyển khoản.');
            }

            currentBankTransferPayment = data.payment;
            renderBankTransferPanel(data.payment);
            setPaymentModalState(PaymentModalState.AWAITING_TRANSFER);
        } catch (err) {
            isStaffPaymentSubmitting = false;
            setPaymentModalState(PaymentModalState.EDITING);
            showStaffPaymentError(err.message || 'Đã có lỗi xảy ra, vui lòng thử lại.');
        }
    }

    function renderBankTransferPanel(payment) {
        const qr = document.getElementById('bank-transfer-qr');
        const qrError = document.getElementById('bank-transfer-qr-error');
        if (qr) {
            qr.style.display = '';
            qrError?.classList.add('hidden');
            qr.src = payment.qrImageUrl || '';
        }
        const bankNameEl = document.getElementById('bank-transfer-bank-name');
        if (bankNameEl) bankNameEl.textContent = payment.bankName || '-';
        const accNameEl = document.getElementById('bank-transfer-account-name');
        if (accNameEl) accNameEl.textContent = payment.accountName || '-';
        const accNoEl = document.getElementById('bank-transfer-account-number');
        if (accNoEl) { accNoEl.textContent = payment.accountNumber || '-'; accNoEl.dataset.raw = payment.accountNumber || ''; }
        const amtEl = document.getElementById('bank-transfer-amount');
        if (amtEl) { amtEl.textContent = formatCurrency(payment.amount); amtEl.dataset.raw = String(Math.round(payment.amount || 0)); }
        const contentEl = document.getElementById('bank-transfer-content');
        if (contentEl) { contentEl.textContent = payment.transferContent || '-'; contentEl.dataset.raw = payment.transferContent || ''; }
        renderBankTransferCustomerInfo(payment, currentInvoiceDetailData || {});
    }

    function renderBankTransferCustomerInfo(payment, invoiceData) {
        const el = document.getElementById('bank-transfer-customer-info');
        if (!el) return;
        el.textContent = '';

        function row(label, value, strong) {
            const r = document.createElement('div');
            r.className = 'flex justify-between items-baseline gap-3 py-1.5';
            const l = document.createElement('span');
            l.className = 'text-[#5d5d67] text-xs';
            l.textContent = label;
            const v = document.createElement('span');
            v.className = strong ? ('text-sm font-bold text-right ' + themeTextMedium) : 'text-sm font-semibold text-[#0b1c30] text-right';
            v.textContent = value;
            r.appendChild(l);
            r.appendChild(v);
            return r;
        }

        if (payment.bookingSource === 'PREBOOKED') {
            const badge = document.createElement('span');
            badge.className = 'inline-block text-[10px] font-bold uppercase tracking-wide px-2 py-1 rounded-md ' + (isManager ? 'bg-purple-50 text-purple-700' : 'bg-orange-50 text-orange-700');
            badge.textContent = 'Đặt trước · Trả sau';
            el.appendChild(badge);
            const wrap = document.createElement('div');
            wrap.className = 'mt-2 divide-y divide-[#EAEAEA]';
            wrap.appendChild(row('Mã đặt sân', '#' + (payment.bookingCode || '-')));
            wrap.appendChild(row('Khách hàng', payment.customerName || '-'));
            if (payment.customerPhone) wrap.appendChild(row('Số điện thoại', payment.customerPhone));
            wrap.appendChild(row('Tổng hóa đơn', formatCurrency(invoiceData.tongThanhToan)));
            wrap.appendChild(row('Đã cọc', formatCurrency(payment.paidAmount || 0)));
            wrap.appendChild(row('Còn phải chuyển', formatCurrency(payment.amount), true));
            el.appendChild(wrap);
        } else {
            const wrap = document.createElement('div');
            wrap.className = 'divide-y divide-[#EAEAEA]';
            wrap.appendChild(row('Khách hàng', 'Khách vãng lai'));
            wrap.appendChild(row('Tổng hóa đơn', formatCurrency(invoiceData.tongThanhToan)));
            wrap.appendChild(row('Đã thanh toán', formatCurrency(payment.paidAmount || 0)));
            wrap.appendChild(row('Cần chuyển', formatCurrency(payment.amount), true));
            el.appendChild(wrap);
        }
    }

    // Copy nhỏ, không dùng alert - đổi nhãn nút tạm thời sang "Đã sao chép".
    function copyBankTransferField(elId, btnEl) {
        const el = document.getElementById(elId);
        if (!el) return;
        const text = el.dataset.raw || el.textContent || '';
        if (!navigator.clipboard) return;
        navigator.clipboard.writeText(text).then(() => {
            const original = btnEl.textContent;
            btnEl.textContent = 'Đã sao chép';
            btnEl.disabled = true;
            clearTimeout(btnEl._copyResetTimer);
            btnEl._copyResetTimer = setTimeout(() => { btnEl.textContent = original; btnEl.disabled = false; }, 1500);
        }).catch(() => { showStaffToast('Không thể sao chép, vui lòng chọn thủ công.'); });
    }

    // ── PayOS: EDITING -> (createPayOSPayment) -> AWAITING_PAYOS -> (polling) -> SUCCESS ──

    async function handleCreatePayOSPayment() {
        if (isStaffPaymentSubmitting || currentPaymentModalState !== PaymentModalState.EDITING) return;

        isStaffPaymentSubmitting = true;
        const btn = document.getElementById('staff-payment-submit-btn');
        const label = document.getElementById('staff-payment-submit-label');
        if (btn) btn.disabled = true;
        if (label) label.textContent = 'Đang tạo mã...';

        const datSanIdText = document.getElementById('staff-pay-datsan-id')?.value?.trim() || '';
        const datSanId = Number(datSanIdText);
        if (!Number.isInteger(datSanId) || datSanId <= 0) {
            showStaffPaymentError('Không xác định được phiên chơi cần thanh toán. Vui lòng đóng và mở lại cửa sổ thanh toán.');
            isStaffPaymentSubmitting = false;
            if (btn) btn.disabled = false;
            if (label) label.textContent = 'Tạo mã thanh toán';
            return;
        }

        const params = new URLSearchParams();
        params.set('action', 'createPayOSPayment');
        params.set('datSanId', String(datSanId));

        setPaymentModalState(PaymentModalState.CREATING_PAYOS);
        document.getElementById('staff-payment-error')?.classList.add('hidden');

        try {
            const response = await fetch('${pageContext.request.contextPath}/staff/checkin', {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: params.toString()
            });
            const rawText = await response.text();
            let data;
            try { data = JSON.parse(rawText); }
            catch (parseError) { throw new Error(`Máy chủ trả về JSON không hợp lệ (HTTP \${response.status}).`); }

            isStaffPaymentSubmitting = false;

            if (!response.ok || !data.success) {
                if (data.code === 'PAYOS_NOT_CONFIGURED') {
                    showStaffPaymentError('Cơ sở chưa cấu hình đầy đủ PayOS. Vui lòng chọn Tiền mặt hoặc liên hệ Admin.');
                    setPaymentModalState(PaymentModalState.EDITING);
                    return;
                }
                throw new Error(data.message || 'Không thể tạo mã thanh toán PayOS.');
            }

            currentPayOSPayment = data.payment;
            renderPayOSPanel(data.payment);
            setPaymentModalState(PaymentModalState.AWAITING_PAYOS);
            startPayOSPolling();
        } catch (err) {
            isStaffPaymentSubmitting = false;
            setPaymentModalState(PaymentModalState.EDITING);
            showStaffPaymentError(err.message || 'Đã có lỗi xảy ra, vui lòng thử lại.');
        }
    }

    function renderPayOSPanel(payment) {
        const amtEl = document.getElementById('staff-payos-amount');
        if (amtEl) amtEl.textContent = formatCurrency(payment.amount);
        const descEl = document.getElementById('staff-payos-description');
        if (descEl) descEl.textContent = payment.description || '-';
        renderPayOSQrCode(payment.qrCode);
    }

    // PayOS trả qrCode dưới dạng chuỗi payload EMV (không phải URL ảnh) trong đa số trường hợp,
    // nhưng hỗ trợ luôn URL/data URL để không vỡ nếu SDK/response thay đổi kiểu dữ liệu sau này.
    function detectPayOSQrType(qrCode) {
        if (!qrCode || !String(qrCode).trim()) return 'EMPTY';
        const value = String(qrCode).trim();
        if (value.startsWith('data:image/') || value.startsWith('http://') || value.startsWith('https://')) {
            return 'IMAGE_SOURCE';
        }
        if (value.startsWith('000201') || /^[0-9A-Za-z]+$/.test(value)) {
            return 'EMV_TEXT';
        }
        return 'UNKNOWN';
    }

    // Render QR PayOS thật vào #staff-payos-qr-container. Luôn xóa nội dung cũ trước khi render để
    // không chồng nhiều QR khi gọi lại (reopen modal / thử tải lại). Không dùng innerHTML với dữ liệu
    // server - chỉ tạo phần tử qua DOM API hoặc để thư viện QR tự vẽ vào container.
    function renderPayOSQrCode(qrCode) {
        const container = document.getElementById('staff-payos-qr-container');
        const fallback = document.getElementById('staff-payos-qr-fallback');
        if (!container) return;

        container.replaceChildren();
        fallback?.classList.add('hidden');

        const type = detectPayOSQrType(qrCode);

        if (type === 'IMAGE_SOURCE') {
            const img = document.createElement('img');
            img.alt = 'Mã QR thanh toán PayOS';
            img.decoding = 'async';
            img.onerror = () => { container.replaceChildren(); fallback?.classList.remove('hidden'); };
            img.src = String(qrCode).trim();
            container.appendChild(img);
            return;
        }

        if (type === 'EMV_TEXT') {
            if (typeof window.QRCode !== 'function') {
                fallback?.classList.remove('hidden');
                return;
            }
            try {
                new window.QRCode(container, {
                    text: String(qrCode).trim(),
                    width: 220,
                    height: 220,
                    correctLevel: window.QRCode.CorrectLevel.M
                });
            } catch (err) {
                container.replaceChildren();
                fallback?.classList.remove('hidden');
            }
            return;
        }

        // EMPTY hoặc UNKNOWN - không đoán, chỉ hiển thị fallback gọn kèm nút mở trang PayOS.
        fallback?.classList.remove('hidden');
    }

    // "Thử tải lại mã QR" - chỉ render lại từ dữ liệu attempt đang có, KHÔNG gọi backend tạo payment mới.
    function retryRenderPayOSQr() {
        if (!currentPayOSPayment) return;
        renderPayOSQrCode(currentPayOSPayment.qrCode);
    }

    function openPayOSCheckoutUrl() {
        if (!currentPayOSPayment || !currentPayOSPayment.checkoutUrl) return;
        window.open(currentPayOSPayment.checkoutUrl, '_blank', 'noopener,noreferrer');
    }

    // "Đổi phương thức" trong lúc chờ PayOS: KHÔNG hủy payment link ở backend (khách vẫn có thể
    // trả qua link/QR cũ) - chỉ dừng polling và quay UI về EDITING + Tiền mặt. Nếu bấm lại PayOS,
    // backend tự tái sử dụng đúng attempt PENDING này (mục VII).
    function handleChangePaymentMethodFromAwaitingPayOS() {
        if (currentPaymentModalState !== PaymentModalState.AWAITING_PAYOS) return;
        stopPayOSPolling();
        currentPayOSPayment = null;
        setPaymentModalState(PaymentModalState.EDITING);
        changeStaffPayMethod(PaymentMethod.CASH);
    }

    function startPayOSPolling() {
        stopPayOSPolling();
        payosPollTimer = setInterval(pollPayOSStatus, 4000);
    }

    function stopPayOSPolling() {
        if (payosPollTimer) { clearInterval(payosPollTimer); payosPollTimer = null; }
    }

    async function pollPayOSStatus() {
        if (!currentPayOSPayment || currentPaymentModalState !== PaymentModalState.AWAITING_PAYOS) {
            stopPayOSPolling();
            return;
        }
        try {
            const res = await fetch('${pageContext.request.contextPath}/staff/checkin?action=getPayOSPaymentStatus&orderCode=' + currentPayOSPayment.orderCode, {
                credentials: 'same-origin',
                headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' }
            });
            const data = await res.json();
            if (!data.success) return; // lỗi tạm thời - thử lại ở lần poll kế tiếp, không dừng polling

            if (data.status === 'PAID') {
                stopPayOSPolling();
                setPaymentModalState(PaymentModalState.VERIFYING_PAYOS);
                await showPaymentSuccessInvoice({ hoaDonId: data.hoaDonId, printUrl: data.printUrl });
            } else if (data.status === 'CANCELLED' || data.status === 'EXPIRED') {
                stopPayOSPolling();
                currentPayOSPayment = null;
                setPaymentModalState(PaymentModalState.EDITING);
                showStaffPaymentError(data.status === 'CANCELLED'
                        ? 'Giao dịch PayOS đã bị hủy. Vui lòng tạo mã mới hoặc chọn phương thức khác.'
                        : 'Mã thanh toán PayOS đã hết hạn. Vui lòng tạo mã mới.');
            }
            // PENDING: không làm gì, chờ lần poll kế tiếp
        } catch (err) {
            // Lỗi mạng tạm thời khi polling - im lặng thử lại lần sau, không làm gián đoạn nhân viên.
        }
    }

    // "Đổi phương thức" khi đang chờ chuyển khoản: đưa hóa đơn về Chưa thanh toán, quay lại EDITING + Tiền mặt.
    // Không tạo/xóa invoice, không đổi amount, không đụng sân - best-effort (UI luôn reset về EDITING).
    async function handleChangePaymentMethodFromAwaiting() {
        if (currentPaymentModalState !== PaymentModalState.AWAITING_TRANSFER) return;
        const datSanIdText = document.getElementById('staff-pay-datsan-id')?.value?.trim() || '';
        const datSanId = Number(datSanIdText);
        try {
            if (Number.isInteger(datSanId) && datSanId > 0) {
                const params = new URLSearchParams();
                params.set('action', 'cancelBankTransfer');
                params.set('datSanId', String(datSanId));
                await fetch('${pageContext.request.contextPath}/staff/checkin', {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                        'Accept': 'application/json',
                        'X-Requested-With': 'XMLHttpRequest'
                    },
                    body: params.toString()
                });
            }
        } catch (err) {
            console.error('Không thể đổi phương thức thanh toán:', err);
        } finally {
            currentBankTransferPayment = null;
            setPaymentModalState(PaymentModalState.EDITING);
            changeStaffPayMethod(PaymentMethod.CASH);
        }
    }

    // ── Dialog xác nhận "Xác nhận đã nhận tiền" (modal-trong-modal, không dùng confirm() mặc định) ──

    function openBankTransferConfirmDialog() {
        if (currentPaymentModalState !== PaymentModalState.AWAITING_TRANSFER || !currentBankTransferPayment) return;

        const summary = document.getElementById('bank-transfer-confirm-summary');
        summary.textContent = '';
        function row(label, value) {
            const r = document.createElement('div');
            r.className = 'flex justify-between gap-3';
            const l = document.createElement('span'); l.className = 'text-zinc-500'; l.textContent = label;
            const v = document.createElement('span'); v.className = 'font-bold text-zinc-900 text-right'; v.textContent = value;
            r.appendChild(l); r.appendChild(v);
            return r;
        }
        const p = currentBankTransferPayment;
        summary.appendChild(row('Hóa đơn', '#' + p.hoaDonId));
        summary.appendChild(row('Khách hàng', p.bookingSource === 'PREBOOKED' ? (p.customerName || '-') : 'Khách vãng lai'));
        summary.appendChild(row('Nội dung', p.transferContent));
        summary.appendChild(row('Số tiền', formatCurrency(p.amount)));

        const codeInput = document.getElementById('bank-transfer-transaction-code');
        if (codeInput) codeInput.value = '';
        document.getElementById('bank-transfer-confirm-error')?.classList.add('hidden');
        const submitBtn = document.getElementById('bank-transfer-confirm-submit-btn');
        if (submitBtn) submitBtn.disabled = false;

        const modal = document.getElementById('bankTransferConfirmModal');
        modal.classList.remove('hidden');
        modal.classList.add('flex');
        setTimeout(() => {
            modal.classList.remove('opacity-0');
            modal.querySelector('.bg-white').classList.remove('scale-95');
        }, 10);
    }

    function closeBankTransferConfirmDialog() {
        const modal = document.getElementById('bankTransferConfirmModal');
        modal.classList.add('opacity-0');
        modal.querySelector('.bg-white').classList.add('scale-95');
        setTimeout(() => { modal.classList.add('hidden'); modal.classList.remove('flex'); }, 300);
    }

    let isBankTransferConfirming = false;

    async function submitBankTransferConfirm() {
        if (isBankTransferConfirming || !currentBankTransferPayment) return;
        const datSanIdText = document.getElementById('staff-pay-datsan-id')?.value?.trim() || '';
        const datSanId = Number(datSanIdText);
        const transactionCode = document.getElementById('bank-transfer-transaction-code')?.value?.trim() || '';
        const errorBox = document.getElementById('bank-transfer-confirm-error');
        errorBox?.classList.add('hidden');

        isBankTransferConfirming = true;
        const submitBtn = document.getElementById('bank-transfer-confirm-submit-btn');
        if (submitBtn) submitBtn.disabled = true;
        setPaymentModalState(PaymentModalState.VERIFYING_TRANSFER);

        try {
            const params = new URLSearchParams();
            params.set('action', 'confirmBankTransfer');
            params.set('datSanId', String(datSanId));
            params.set('paymentReference', currentBankTransferPayment.transferContent);
            if (transactionCode) params.set('transactionCode', transactionCode);

            const response = await fetch('${pageContext.request.contextPath}/staff/checkin', {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: params.toString()
            });
            const rawText = await response.text();
            let data;
            try { data = JSON.parse(rawText); }
            catch (parseError) { throw new Error(`Máy chủ trả về JSON không hợp lệ (HTTP \${response.status}).`); }
            if (!response.ok || !data.success) throw new Error(data.message || 'Xác nhận chuyển khoản không thành công.');
            if (!data.hoaDonId) throw new Error('Xác nhận thành công nhưng máy chủ không trả mã hóa đơn.');

            isBankTransferConfirming = false;
            closeBankTransferConfirmDialog();
            await showPaymentSuccessInvoice({ hoaDonId: data.hoaDonId, printUrl: data.printUrl });
        } catch (err) {
            isBankTransferConfirming = false;
            if (submitBtn) submitBtn.disabled = false;
            setPaymentModalState(PaymentModalState.AWAITING_TRANSFER);
            if (errorBox) { errorBox.textContent = err.message || 'Đã có lỗi xảy ra, vui lòng thử lại.'; errorBox.classList.remove('hidden'); }
        }
    }

    // ── PAYMENT_SUCCESS: hiển thị hóa đơn thật ngay trong modal, không rời trang Check-in ──

    async function showPaymentSuccessInvoice({ hoaDonId, printUrl }) {
        staffSuccessHoaDonId = hoaDonId;
        staffSuccessPrintUrl = printUrl || ('${pageContext.request.contextPath}/staff/hoa-don/in?id=' + hoaDonId);
        staffSuccessManagementUrl = '';

        setPaymentModalState(PaymentModalState.SUCCESS);

        const codeEl = document.getElementById('staff-success-code');
        const descEl = document.getElementById('staff-success-description');
        if (codeEl) codeEl.textContent = '#' + hoaDonId;
        if (descEl) {
            const bookingSource = currentInvoiceDetailData ? currentInvoiceDetailData.bookingSource : null;
            const bookingCode = currentInvoiceDetailData ? currentInvoiceDetailData.bookingCode : null;
            descEl.textContent = (bookingSource === 'PREBOOKED')
                ? ('Đã thu đủ số tiền còn lại của đặt sân #' + (bookingCode || hoaDonId) + '.')
                : 'Hóa đơn đã được thanh toán và sân đã chuyển về trạng thái sẵn sàng.';
        }

        const heading = document.getElementById('staff-success-heading');
        if (heading) heading.focus();

        await loadSuccessInvoiceDetail();

        // Cập nhật card sân / bộ đếm dashboard ở nền, không chặn việc xem/in hóa đơn.
        pollUpdates();
    }

    async function loadSuccessInvoiceDetail() {
        const loadingEl = document.getElementById('staff-success-body-loading');
        const bodyEl = document.getElementById('staff-success-body');
        const errorEl = document.getElementById('staff-success-preview-error');
        loadingEl.classList.remove('hidden');
        bodyEl.classList.add('hidden');
        errorEl.classList.add('hidden');

        try {
            const response = await fetch('${pageContext.request.contextPath}/staff/hoa-don/detail?id=' + staffSuccessHoaDonId, {
                credentials: 'same-origin',
                headers: { 'Accept': 'application/json' }
            });
            const contentType = response.headers.get('content-type') || '';
            if (!contentType.includes('application/json')) {
                throw new Error('Máy chủ trả về phản hồi không phải JSON.');
            }
            const data = await response.json();
            if (!response.ok || !data.success) {
                throw new Error(data.message || 'Không thể tải chi tiết hóa đơn.');
            }

            renderStaffSuccessInfo(data.invoice);
            renderStaffSuccessReceipt(data.invoice);
            staffSuccessManagementUrl = data.invoice.invoiceManagementUrl || '';

            loadingEl.classList.add('hidden');
            bodyEl.classList.remove('hidden');
        } catch (err) {
            console.error('Không thể tải bản xem trước hóa đơn:', err);
            loadingEl.classList.add('hidden');
            errorEl.classList.remove('hidden');
            const link = document.getElementById('staff-success-fallback-link');
            if (link) link.href = staffSuccessPrintUrl;
        }
    }

    function retryLoadSuccessInvoice() {
        loadSuccessInvoiceDetail();
    }

    function openStaffSuccessManagementUrl() {
        window.location.assign(staffSuccessManagementUrl || '${pageContext.request.contextPath}/staff/checkin');
    }

    function addStaffInfoRow(container, label, value) {
        const row = document.createElement('div');
        row.className = 'flex justify-between gap-3';
        const labelEl = document.createElement('span');
        labelEl.className = 'text-[#5d5d67]';
        labelEl.textContent = label;
        const valueEl = document.createElement('span');
        valueEl.className = 'font-semibold text-[#0b1c30] text-right';
        valueEl.textContent = value;
        row.appendChild(labelEl);
        row.appendChild(valueEl);
        container.appendChild(row);
    }

    function renderStaffSuccessInfo(invoice) {
        const infoList = document.getElementById('staff-success-info-list');
        const summaryList = document.getElementById('staff-success-summary-list');
        infoList.textContent = '';
        summaryList.textContent = '';

        addStaffInfoRow(infoList, 'Mã hóa đơn:', invoice.invoiceCode);
        addStaffInfoRow(infoList, 'Sân:', invoice.courtName);
        addStaffInfoRow(infoList, 'Loại sân:', invoice.courtTypeName);
        addStaffInfoRow(infoList, 'Khách hàng:', invoice.customerName);
        addStaffInfoRow(infoList, 'Chế độ chơi:', invoice.playModeLabel);
        addStaffInfoRow(infoList, 'Bắt đầu:', invoice.actualStartLabel);
        addStaffInfoRow(infoList, 'Kết thúc:', invoice.actualEndLabel);
        addStaffInfoRow(infoList, 'Thời gian thực tế:', invoice.actualDurationLabel);
        addStaffInfoRow(infoList, 'Thời lượng tính phí:', invoice.chargedDurationLabel);
        addStaffInfoRow(infoList, 'Phương thức thanh toán:', invoice.paymentMethod || '-');
        if (invoice.paymentMethod === 'Chuyển khoản') {
            if (invoice.transactionCode) addStaffInfoRow(infoList, 'Mã giao dịch:', invoice.transactionCode);
            if (invoice.confirmedByName) addStaffInfoRow(infoList, 'NV xác nhận:', invoice.confirmedByName);
            if (invoice.confirmedAtLabel) addStaffInfoRow(infoList, 'TG xác nhận:', invoice.confirmedAtLabel);
        }
        addStaffInfoRow(infoList, 'Nhân viên thu ngân:', invoice.cashierName);
        addStaffInfoRow(infoList, 'Trạng thái:', invoice.paymentStatus);
        if (invoice.minimumChargeApplied) {
            const note = document.createElement('div');
            note.className = 'text-[11px] text-amber-800 bg-amber-50 border border-amber-200 rounded-lg px-2.5 py-1.5 mt-1';
            note.textContent = 'Áp dụng thời lượng tính phí tối thiểu ' + invoice.chargedDurationLabel + '.';
            infoList.appendChild(note);
        }

        addStaffInfoRow(summaryList, 'Tiền sân:', formatCurrency(invoice.courtAmount));
        addStaffInfoRow(summaryList, 'Tiền dịch vụ:', formatCurrency(invoice.serviceAmount));
        if (invoice.discountAmount > 0) addStaffInfoRow(summaryList, 'Giảm giá:', '-' + formatCurrency(invoice.discountAmount));
        if (invoice.parkingFee > 0) addStaffInfoRow(summaryList, 'Phí gửi xe:', formatCurrency(invoice.parkingFee));

        const totalRow = document.createElement('div');
        totalRow.className = 'flex justify-between items-center pt-2 mt-1 border-t border-[#ccc3d8]';
        const totalLabel = document.createElement('span');
        totalLabel.className = 'text-xs text-[#5d5d67] uppercase font-medium';
        totalLabel.textContent = 'Tổng thanh toán';
        const totalValue = document.createElement('span');
        totalValue.className = 'text-lg font-bold ' + (isManager ? 'text-purple-700' : 'text-orange-700');
        totalValue.textContent = formatCurrency(invoice.totalAmount);
        totalRow.appendChild(totalLabel);
        totalRow.appendChild(totalValue);
        summaryList.appendChild(totalRow);
    }

    // Render bill xem trước bằng DOM an toàn (textContent/createElement) - không dùng innerHTML với
    // dữ liệu từ server. Dùng chung class CSS ".receipt"/".receipt-row"/... với staff/HoaDonPrint.jsp
    // để bản xem trước trong modal và trang in thật sự giống nhau.
    function renderStaffSuccessReceipt(invoice) {
        const root = document.getElementById('staff-print-root');
        root.textContent = '';

        function el(tag, className, text) {
            const e = document.createElement(tag);
            if (className) e.className = className;
            if (text !== undefined && text !== null) e.textContent = text;
            return e;
        }
        function row(label, value, opts) {
            opts = opts || {};
            const r = el('div', 'receipt-row' + (opts.rowClass ? ' ' + opts.rowClass : ''));
            r.appendChild(el('span', opts.labelClass || 'muted', label));
            r.appendChild(el('span', 'receipt-money' + (opts.valueClass ? ' ' + opts.valueClass : ''), value));
            return r;
        }

        root.appendChild(el('div', 'center bold', 'V-SPORT'));
        root.appendChild(el('div', 'center bold', invoice.facilityName || ''));
        if (invoice.facilityAddress) root.appendChild(el('div', 'center small', invoice.facilityAddress));
        if (invoice.facilityPhone) root.appendChild(el('div', 'center small', 'ĐT: ' + invoice.facilityPhone));
        const titleEl = el('div', 'center bold ' + (isManager ? 'text-purple-700' : 'text-orange-700'),
            invoice.invoiceType === 'SPLIT' ? 'HÓA ĐƠN DỊCH VỤ (TÁCH)' : 'HÓA ĐƠN THANH TOÁN');
        titleEl.style.marginTop = '8px';
        root.appendChild(titleEl);
        root.appendChild(el('hr'));

        root.appendChild(row('Mã hóa đơn:', invoice.invoiceCode, { valueClass: 'bold mono' }));
        root.appendChild(row('Ngày lập:', invoice.paidAtLabel || '-'));
        root.appendChild(row('Thu ngân:', invoice.cashierName || '-'));
        root.appendChild(row('PT thanh toán:', invoice.paymentMethod || '-'));
        if (invoice.paymentMethod === 'Chuyển khoản') {
            if (invoice.transactionCode) root.appendChild(row('Mã giao dịch:', invoice.transactionCode, { valueClass: 'mono' }));
            if (invoice.confirmedByName) root.appendChild(row('NV xác nhận:', invoice.confirmedByName));
            if (invoice.confirmedAtLabel) root.appendChild(row('TG xác nhận:', invoice.confirmedAtLabel));
        }
        root.appendChild(row('Trạng thái:', invoice.paymentStatus || '-', { valueClass: 'bold' }));
        root.appendChild(el('hr'));

        root.appendChild(row('Sân:', invoice.courtName || '-'));
        root.appendChild(row('Loại sân:', invoice.courtTypeName || '-'));
        root.appendChild(row('Khách:', invoice.customerName || '-'));
        root.appendChild(row('Chế độ:', invoice.playModeLabel || '-'));
        root.appendChild(row('Bắt đầu:', invoice.actualStartLabel || '-'));
        root.appendChild(row('Kết thúc:', invoice.actualEndLabel || '-'));
        root.appendChild(row('Thời gian thực tế:', invoice.actualDurationLabel || '-'));
        root.appendChild(row('Thời lượng tính phí:', invoice.chargedDurationLabel || '-', { valueClass: 'bold' }));
        if (invoice.minimumChargeApplied) {
            root.appendChild(el('div', 'min-charge-note', 'Áp dụng thời lượng tính phí tối thiểu ' + invoice.chargedDurationLabel + '.'));
        }

        if (invoice.invoiceType !== 'SPLIT') {
            (invoice.courtSegments || []).forEach(function (seg) {
                const card = el('div', 'segment-card');
                const head = el('div', 'receipt-row');
                const tag = el('span', 'segment-tag ' + (seg.rateType === 'WITH_LIGHT' ? 'light' : 'no-light'));
                const icon = el('span', 'material-symbols-outlined', seg.rateType === 'WITH_LIGHT' ? 'bolt' : 'bedtime');
                icon.style.fontSize = '12px';
                tag.appendChild(icon);
                tag.appendChild(document.createTextNode(' ' + (seg.rateLabel || '')));
                head.appendChild(tag);
                head.appendChild(el('span', 'small', seg.durationMinutes + ' phút'));
                card.appendChild(head);

                const timeRow = el('div', 'receipt-row small');
                timeRow.style.marginTop = '4px';
                const startTime = seg.startAt ? seg.startAt.substring(11, 16) : '';
                const endTime = seg.endAt ? seg.endAt.substring(11, 16) : '';
                timeRow.appendChild(el('span', null, startTime + ' - ' + endTime));
                timeRow.appendChild(el('span', null, formatCurrency(seg.hourlyRate) + '/giờ'));
                card.appendChild(timeRow);

                const amountRow = el('div', 'receipt-row bold');
                amountRow.style.marginTop = '4px';
                amountRow.appendChild(el('span', null, 'Thành tiền đoạn'));
                amountRow.appendChild(el('span', null, formatCurrency(seg.amount)));
                card.appendChild(amountRow);

                root.appendChild(card);
            });
            const courtRow = row('Thành tiền sân:', formatCurrency(invoice.courtAmount), { valueClass: 'bold' });
            courtRow.style.marginTop = '10px';
            root.appendChild(courtRow);
        }
        root.appendChild(el('hr'));

        root.appendChild(el('div', 'bold small', 'DỊCH VỤ ĐI KÈM'));
        const services = invoice.services || [];
        if (services.length > 0) {
            const table = el('table', 'dv-table');
            const thead = el('thead');
            const headRow = el('tr');
            headRow.appendChild(el('th', null, 'Tên dịch vụ'));
            headRow.appendChild(el('th', 'qty', 'SL'));
            headRow.appendChild(el('th', 'money', 'Đơn giá'));
            headRow.appendChild(el('th', 'money', 'T.Tiền'));
            thead.appendChild(headRow);
            table.appendChild(thead);
            const tbody = el('tbody');
            services.forEach(function (dv) {
                const tr = el('tr');
                tr.appendChild(el('td', null, dv.name));
                tr.appendChild(el('td', 'qty', String(dv.quantity)));
                tr.appendChild(el('td', 'money', formatCurrency(dv.unitPrice).replace(' đ', '')));
                tr.appendChild(el('td', 'money', formatCurrency(dv.amount).replace(' đ', '')));
                tbody.appendChild(tr);
            });
            table.appendChild(tbody);
            root.appendChild(table);
        } else {
            root.appendChild(el('div', 'small', 'Không có dịch vụ.'));
        }
        root.appendChild(el('hr'));

        if (invoice.invoiceType !== 'SPLIT') {
            root.appendChild(row('Tiền sân:', formatCurrency(invoice.courtAmount)));
        }
        root.appendChild(row('Tiền dịch vụ:', formatCurrency(invoice.serviceAmount)));
        if (invoice.discountAmount > 0) root.appendChild(row('Giảm giá:', '-' + formatCurrency(invoice.discountAmount)));
        if (invoice.parkingFee > 0) root.appendChild(row('Phí gửi xe:', formatCurrency(invoice.parkingFee)));
        root.appendChild(el('hr'));

        root.appendChild(row('TỔNG THANH TOÁN:', formatCurrency(invoice.totalAmount), {
            rowClass: 'total-row', labelClass: '', valueClass: isManager ? 'text-purple-700' : 'text-orange-700'
        }));
        root.appendChild(el('hr'));
        root.appendChild(el('div', 'center small', 'Cảm ơn quý khách đã sử dụng dịch vụ V-SPORT.'));
    }

    function printSuccessInvoice() {
        const root = document.getElementById('staff-print-root');
        if (!root) { window.print(); return; }

        // Modal wrapper dùng class "transform" (Tailwind) nên tạo containing block riêng cho
        // position:fixed - nếu in tại chỗ, receipt sẽ bị neo/cắt theo khung modal thay vì toàn trang.
        // Chuyển receipt ra thành con trực tiếp của <body> khi in, rồi trả lại đúng vị trí sau đó.
        const originalParent = root.parentNode;
        const originalNextSibling = root.nextSibling;
        let restored = false;

        function restore() {
            if (restored) return;
            restored = true;
            document.body.classList.remove('printing-invoice');
            if (originalNextSibling && originalNextSibling.parentNode === originalParent) {
                originalParent.insertBefore(root, originalNextSibling);
            } else {
                originalParent.appendChild(root);
            }
        }

        document.body.appendChild(root);
        document.body.classList.add('printing-invoice');

        window.addEventListener('afterprint', restore, { once: true });
        window.print();
        // Fallback nếu trình duyệt không phát afterprint (một số trường hợp hiếm).
        setTimeout(restore, 3000);
    }

    // Mọi nút Dừng sân (kể cả card render động) đều đi qua AJAX, không reload dashboard.
    document.addEventListener('submit', async function (event) {
        const form = event.target;
        if (!(form instanceof HTMLFormElement) || form.querySelector('input[name="action"]')?.value !== 'stopOpenSession') return;
        event.preventDefault();
        event.stopPropagation();
        const button = form.querySelector('button[type="submit"]');
        if (button?.disabled) return;
        const oldText = button ? button.textContent : '';
        if (button) { button.disabled = true; button.textContent = 'Đang chốt giờ...'; }
        try {
            // Không dùng form.action: form có input name="action" nên form.action bị DOM
            // clobbering (named-property access che khuất IDL attribute), trả về chính
            // HTMLInputElement thay vì URL -> fetch gửi "[object HTMLInputElement]".
            const stopSessionUrl = '${pageContext.request.contextPath}/staff/checkin';
            const response = await fetch(stopSessionUrl, {
                method: 'POST',
                credentials: 'same-origin',
                headers: {'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest'},
                body: new URLSearchParams(new FormData(form))
            });
            const contentType = response.headers.get('content-type') || '';
            if (!contentType.includes('application/json')) {
                const text = (await response.text()).slice(0, 300);
                throw new Error(`HTTP \${response.status}: \${text || 'Phản hồi không phải JSON'}`);
            }
            const data = await response.json();
            if (!response.ok || !data.success) throw new Error(data.message || data.error || `HTTP \${response.status}`);
            const datSanId = data.datSanId || new FormData(form).get('datSanId');
            openStaffInvoiceModal(datSanId);
        } catch (error) {
            const box = document.getElementById('staff-payment-error');
            if (box) { box.textContent = error.message; box.classList.remove('hidden'); }
            if (button) { button.disabled = false; button.textContent = oldText; }
        }
    });

    // AJAX handling for Mở sân/Check-in and Bùng kèo
    document.addEventListener('submit', async function (event) {
        const form = event.target;
        if (!(form instanceof HTMLFormElement)) return;
        
        const actionInput = form.querySelector('input[name="action"]');
        const action = actionInput ? actionInput.value : null;
        if (action !== 'checkInPreBooked' && action !== 'cancelNoShow') return;
        
        event.preventDefault();
        event.stopPropagation();
        
        const button = form.querySelector('button[type="submit"]');
        if (button?.disabled) return;
        
        const oldButtonHtml = button.innerHTML;
        button.disabled = true;
        button.innerHTML = '<span class="material-symbols-outlined text-[14.5px] animate-spin">sync</span>';
        
        try {
            const url = '${pageContext.request.contextPath}/staff/checkin';
            const formData = new FormData(form);
            const response = await fetch(url, {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: new URLSearchParams(formData)
            });
            
            const contentType = response.headers.get('content-type') || '';
            let data;
            if (contentType.includes('application/json')) {
                data = await response.json();
            } else {
                throw new Error('Phản hồi từ hệ thống không hợp lệ.');
            }
            
            if (!response.ok || !data.success) {
                if (data.paymentRequired) {
                    if (confirm(data.message + '\n\nBạn có xác nhận đã thu đủ tiền mặt của khách tại quầy không?')) {
                        let cashInput = form.querySelector('input[name="daThuTienMat"]');
                        if (!cashInput) {
                            cashInput = document.createElement('input');
                            cashInput.type = 'hidden';
                            cashInput.name = 'daThuTienMat';
                            form.appendChild(cashInput);
                        }
                        cashInput.value = 'true';
                        button.disabled = false;
                        button.innerHTML = oldButtonHtml;
                        if (typeof form.requestSubmit === 'function') {
                            form.requestSubmit();
                        } else {
                            const submitEvent = new Event('submit', { cancelable: true, bubbles: true });
                            form.dispatchEvent(submitEvent);
                            if (!submitEvent.defaultPrevented) {
                                form.submit();
                            }
                        }
                        return;
                    }
                } else {
                    showStaffToast(data.message || 'Thao tác thất bại.');
                }
                button.disabled = false;
                button.innerHTML = oldButtonHtml;
                return;
            }
            
            showStaffToast(data.message || 'Thao tác thành công.');
            await pollUpdates(); // Cập nhật danh sách, counter và card sân tức thì
            
        } catch (error) {
            showStaffToast(error.message || 'Đã xảy ra lỗi kết nối.');
            button.disabled = false;
            button.innerHTML = oldButtonHtml;
        }
    });

    function closeStaffInvoiceModal() {
        // Không cho đóng modal khi đang gửi/chờ transaction thanh toán commit.
        if (currentPaymentModalState === PaymentModalState.PROCESSING
            || currentPaymentModalState === PaymentModalState.VERIFYING_TRANSFER
            || currentPaymentModalState === PaymentModalState.CREATING_PAYOS
            || currentPaymentModalState === PaymentModalState.VERIFYING_PAYOS) return;

        stopPayOSPolling();
        const wasSuccess = currentPaymentModalState === PaymentModalState.SUCCESS;
        const modal = document.getElementById("staffInvoiceModal");
        const errorBox = document.getElementById('staff-payment-error');
        if (errorBox) errorBox.classList.add('hidden');

        modal.classList.add("opacity-0");
        modal.querySelector(".bg-white").classList.add("scale-95");
        setTimeout(() => {
            modal.classList.add("hidden");
            modal.classList.remove("flex");
            setPaymentModalState(PaymentModalState.EDITING);

            if (staffInvoiceModalTriggerEl && typeof staffInvoiceModalTriggerEl.focus === 'function') {
                staffInvoiceModalTriggerEl.focus();
            }
            staffInvoiceModalTriggerEl = null;

            // Sân vừa thanh toán xong cần cập nhật ngay về Sẵn sàng trên dashboard phía sau modal.
            if (wasSuccess) pollUpdates();
        }, 300);
    }

    function escapeForInlineOnclickJsString(str) {
        return String(str == null ? '' : str)
            .replace(/\\/g, '\\\\')
            .replace(/'/g, "\\'")
            .replace(/&/g, '&amp;')
            .replace(/"/g, '&quot;');
    }

    function openNoShowModal(datSanId, tenKhachHang, reputationScore) {
        document.getElementById("noShowDatSanId").value = datSanId;
        document.getElementById("noShowCustomerName").textContent = tenKhachHang || "Khách vãng lai";
        document.getElementById("noShowDatSanLabel").textContent = "#" + datSanId;

        var repEl = document.getElementById("noShowCurrentReputation");
        if (reputationScore !== null && reputationScore !== undefined) {
            repEl.textContent = "Điểm uy tín hiện tại: " + reputationScore + "/100";
            repEl.classList.remove("hidden");
        } else {
            repEl.classList.add("hidden");
        }

        var modal = document.getElementById("noShowModal");
        modal.classList.remove("hidden");
        modal.classList.add("flex");
        requestAnimationFrame(function () {
            modal.classList.remove("opacity-0");
            modal.querySelector(".bg-white").classList.remove("scale-95");
        });
    }

    function closeNoShowModal() {
        var modal = document.getElementById("noShowModal");
        modal.classList.add("opacity-0");
        modal.querySelector(".bg-white").classList.add("scale-95");
        setTimeout(function () {
            modal.classList.add("hidden");
            modal.classList.remove("flex");
        }, 300);
    }


    // --- Side Drawer Functions ---
    let activeDrawerSanId = null;

    function getLocalTimeString(timeVal) {
        if (!timeVal) return '';
        if (typeof timeVal === 'string') return timeVal;
        if (typeof timeVal === 'object' && timeVal.hour !== undefined) {
            const h = String(timeVal.hour).padStart(2, '0');
            const m = String(timeVal.minute).padStart(2, '0');
            return `\${h}:\${m}:00`;
        }
        return '';
    }

    function onCardClick(event, cardEl) {
        if (event.target.closest('button') || event.target.closest('form')) return;
        const sanId = parseInt(cardEl.getAttribute('data-sanid'));
        openCourtDetailDrawer(sanId);
    }

    // Returns the earliest upcoming (still-pending/confirmed) booking for a court that starts at/after `afterDate`
    function getNextBookingForSan(sanId, afterDate) {
        const candidates = localDanhSachLich.filter(b => b.sanId === sanId && (b.trangThai === 'Đã xác nhận' || b.trangThai === 'Chờ xác nhận'));
        let best = null, bestDate = null;
        candidates.forEach(b => {
            const d = parseTimeToDate(b.gioBatDau);
            if (!d || d < afterDate) return;
            if (!bestDate || d < bestDate) {
                bestDate = d;
                best = b;
            }
        });
        return best ? { booking: best, startDate: bestDate } : null;
    }

    function formatHm(d) {
        return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
    }

    let drawerTriggerEl = null;
    let isDrawerSubmitting = false;

    function openCourtDetailDrawer(sanId) {
        activeDrawerSanId = sanId;
        isDrawerSubmitting = false;
        drawerTriggerEl = document.activeElement;

        const cardEl = document.querySelector('.card[data-sanid="' + sanId + '"]');
        if (!cardEl) return;

        const tenSan = cardEl.getAttribute('data-tensan');
        const tenLoaiSan = cardEl.getAttribute('data-loaisan');
        const trangThai = cardEl.getAttribute('data-trangthai');
        const moTa = cardEl.getAttribute('data-mota') || '';
        const giaKhongDen = parseFloat(cardEl.getAttribute('data-giakhongden')) || 0;
        const giaCoDen = parseFloat(cardEl.getAttribute('data-giacoden')) || 0;
        const gioBatDauLenDen = cardEl.getAttribute('data-giobatdaulenden') || '';
        const gioKetThucLenDen = cardEl.getAttribute('data-giokethuclenden') || '';
        const datSanIdActive = cardEl.getAttribute('data-datsanidactive');
        const gioBatDauActive = cardEl.getAttribute('data-giobatdauactive');

        // Update Drawer elements
        document.getElementById('drawer-court-name').textContent = tenSan;
        document.getElementById('drawer-court-type').textContent = tenLoaiSan;
        document.getElementById('drawer-current-time').textContent = formatHm(new Date());
        document.getElementById('drawer-court-coso').textContent = 'CS' + '${sessionScope.user.coSoId}';
        document.getElementById('drawer-price-nolite').textContent = formatCurrency(giaKhongDen);
        document.getElementById('drawer-price-lite').textContent = formatCurrency(giaCoDen);
        document.getElementById('drawer-light-time').textContent = gioBatDauLenDen && gioKetThucLenDen ? (gioBatDauLenDen.substring(0,5) + ' - ' + gioKetThucLenDen.substring(0,5)) : 'Không có cấu hình';
        
        const descContainer = document.getElementById('drawer-desc-container');
        if (moTa && moTa !== 'null') {
            descContainer.classList.remove('hidden');
            document.getElementById('drawer-court-desc').textContent = moTa;
        } else {
            descContainer.classList.add('hidden');
        }
        
        // Set Status Badge
        const statusBadge = document.getElementById('drawer-court-status-badge');
        statusBadge.textContent = trangThai;
        if (trangThai === 'Sẵn sàng') {
            statusBadge.className = 'badge badge-green';
        } else if (trangThai === 'Đang sử dụng') {
            statusBadge.className = 'badge ' + '${badgeTheme}';
        } else if (trangThai === 'Bảo trì') {
            statusBadge.className = 'badge badge-amber';
        } else {
            statusBadge.className = 'badge badge-red';
        }
        
        // Hide all action blocks first
        document.getElementById('drawer-action-walkin').classList.add('hidden');
        document.getElementById('drawer-action-active').classList.add('hidden');
        document.getElementById('drawer-action-disabled').classList.add('hidden');
        const prebookedSection = document.getElementById('drawer-action-prebooked');
        if (prebookedSection) prebookedSection.classList.add('hidden');
        
        if (trangThai === 'Sẵn sàng') {
            document.getElementById('drawer-action-walkin').classList.remove('hidden');
            document.getElementById('drawer-walkin-san-id').value = sanId;
            
            // Reset playMode selection to FIXED and duration to 120
            const fixedRadio = document.querySelector('#courtDetailDrawer input[name="playMode"][value="FIXED"]');
            if (fixedRadio) {
                fixedRadio.checked = true;
            }
            const customHoursInput = document.getElementById('drawer-custom-hours');
            if (customHoursInput) customHoursInput.value = '';
            const customWrap = document.getElementById('drawer-custom-hours-wrap');
            if (customWrap) customWrap.classList.add('hidden');
            setDrawerPlayMode('FIXED');
            setDrawerDuration(120);

            // Info: next upcoming booking today, if any
            const nextInfo = getNextBookingForSan(sanId, new Date());
            const nextInfoBox = document.getElementById('drawer-next-booking-info');
            const nextInfoText = document.getElementById('drawer-next-booking-text');
            if (nextInfo) {
                nextInfoBox.classList.remove('hidden');
                nextInfoText.textContent = `Lịch tiếp theo bắt đầu lúc \${nextInfo.booking.gioBatDau}.`;
            } else {
                nextInfoBox.classList.add('hidden');
            }

            // Filter bookings for this court today
            const courtBookings = localDanhSachLich.filter(b => b.sanId === sanId && (b.trangThai === 'Đã xác nhận' || b.trangThai === 'Chờ xác nhận'));
            const prebookedList = document.getElementById('drawer-prebooked-list');
            if (prebookedSection && prebookedList) {
                prebookedSection.classList.remove('hidden');
                prebookedList.innerHTML = '';
                if (courtBookings.length === 0) {
                    prebookedList.innerHTML = `
                        <div class="py-4 text-center text-zinc-400 text-xs italic bg-zinc-50 rounded-xl border border-dashed border-zinc-200">
                            Không có lịch đặt trước cho sân này hôm nay.
                        </div>
                    `;
                } else {
                    courtBookings.forEach(b => {
                        const statusBadgeClass = b.trangThaiThanhToan === 'Đã thanh toán' ? 'badge-green' : 'badge-amber';
                        prebookedList.insertAdjacentHTML('beforeend', `
                            <div class="p-3.5 \${themeBgLight} border \${themeBorder} rounded-2xl flex flex-col gap-2 hover:bg-\${isManager ? 'purple' : 'orange'}-100/30 transition-all">
                                <div class="flex justify-between items-start">
                                    <div>
                                        <div class="font-black text-xs text-zinc-800 flex items-center gap-1">
                                            <span class="material-symbols-outlined text-[14px] \${themeIcon}">person</span>
                                            \${b.tenKhachHang}
                                        </div>
                                        <div class="text-[10px] text-zinc-500 mt-1 flex items-center gap-1 font-mono">
                                            <span class="material-symbols-outlined text-[12px] text-zinc-400">schedule</span>
                                            \${b.gioBatDau} - \${b.gioKetThuc}
                                        </div>
                                    </div>
                                    <span class="badge \${statusBadgeClass} text-[9px] font-bold tracking-tight uppercase">\${b.trangThaiThanhToan}</span>
                                </div>
                                <div class="flex justify-between items-center pt-2 border-t \${themeBorder}">
                                    <span class="text-[10px] text-zinc-550 font-semibold uppercase tracking-wider bg-zinc-150 px-2 py-0.5 rounded">Nguồn: \${b.nguonDatSan}</span>
                                    <form action="${pageContext.request.contextPath}/staff/checkin" method="post" class="inline-block">
                                        <input type="hidden" name="action" value="checkInPreBooked">
                                        <input type="hidden" name="datSanId" value="\${b.datSanId}">
                                        <input type="hidden" name="daThuTienMat" value="false">
                                        <button type="submit" class="\${themeBg} \${themeBgHover} text-white font-extrabold text-[10px] px-3.5 py-1.5 rounded-xl shadow-sm hover:shadow transition-all active:scale-95 flex items-center gap-1">
                                            <span class="material-symbols-outlined text-[12px]">power_settings_new</span>
                                            Mở sân ngay
                                        </button>
                                    </form>
                                </div>
                            </div>
                        `);
                    });
                }
            }
            
            // Set base rates
            const now = new Date();
            const currentTimeStr = now.toTimeString().split(' ')[0];
            let rate = giaKhongDen;
            let isLite = false;
            
            if (gioBatDauLenDen && gioKetThucLenDen) {
                if (currentTimeStr >= gioBatDauLenDen && currentTimeStr <= gioKetThucLenDen) {
                    rate = giaCoDen;
                    isLite = true;
                }
            }
            
            const rateInput = document.getElementById('drawer-walkin-rate');
            rateInput.value = rate;
            rateInput.setAttribute('data-base', rate);
            rateInput.setAttribute('data-giakhongden', giaKhongDen);
            rateInput.setAttribute('data-giacoden', giaCoDen);
            rateInput.setAttribute('data-giobatdaulenden', gioBatDauLenDen);
            rateInput.setAttribute('data-giokethuclenden', gioKetThucLenDen);
            
            const rateTypeSpan = document.getElementById('drawer-walkin-rate-type');
            rateTypeSpan.textContent = `Áp dụng: \${isLite ? 'Giá có đèn' : 'Giá không đèn'}`;
            
            calculateDrawerPrice();

        } else if (trangThai === 'Đang sử dụng') {
            document.getElementById('drawer-action-active').classList.remove('hidden');
            document.getElementById('drawer-active-id').textContent = datSanIdActive || '-';
            document.getElementById('drawer-active-start').textContent = gioBatDauActive || '-';
            
            // Set datSanId on the stop session form
            document.getElementById('drawer-stop-datsan-id').value = datSanIdActive || '';
            
            // Determine playing mode
            const gioKetThucActive = cardEl.getAttribute('data-giokethucactive') || '';
            const ghiChuActive = cardEl.getAttribute('data-ghichuactive') || '';
            const isOpenMode = ghiChuActive.includes('Không cố định');
            
            // Display playing mode
            const activeModeEl = document.getElementById('drawer-active-mode');
            if (activeModeEl) {
                activeModeEl.textContent = isOpenMode ? 'Giờ không cố định' : 'Giờ cố định';
            }
            
            // Show/Hide Stop Session button depending on mode
            const stopFormEl = document.getElementById('drawer-stop-session-form');
            if (stopFormEl) {
                if (isOpenMode) {
                    stopFormEl.classList.remove('hidden');
                } else {
                    stopFormEl.classList.add('hidden');
                }
            }

            // Calculate start and end dates
            const { startDate, endDate } = getTimerDates(gioBatDauActive, gioKetThucActive);

            // Determine active hourly rate based on whether current time is in light time
            const now = new Date();
            const currentTimeStr = now.toTimeString().split(' ')[0];
            let rate = giaKhongDen;
            if (gioBatDauLenDen && gioKetThucLenDen) {
                if (currentTimeStr >= gioBatDauLenDen && currentTimeStr <= gioKetThucLenDen) {
                    rate = giaCoDen;
                }
            }

            // Estimate baseCourtPrice for fixed mode
            let baseCourtPrice = 0;
            if (!isOpenMode && startDate && endDate) {
                const plannedMins = Math.max(0, Math.floor((endDate - startDate) / 60000));
                baseCourtPrice = (plannedMins / 60.0) * rate;
            }

            // Start the drawer timer loop
            startDrawerTimerLoop(startDate, endDate, isOpenMode, rate, baseCourtPrice);
            
            const payBtn = document.getElementById('drawer-btn-invoice');
            payBtn.onclick = () => {
                if (datSanIdActive && datSanIdActive !== 'null') {
                    openStaffInvoiceModal(parseInt(datSanIdActive));
                } else {
                    alert("Không tìm thấy phiên chơi đang hoạt động của sân này.");
                }
            };
            
        } else {
            document.getElementById('drawer-action-disabled').classList.remove('hidden');
        }
        
        // Open modal (centered)
        const drawer = document.getElementById('courtDetailDrawer');
        const overlay = document.getElementById('drawerOverlay');
        const panel = document.getElementById('courtDetailDrawerPanel');
        drawer.classList.remove('hidden');
        overlay.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
        setTimeout(() => {
            overlay.classList.remove('opacity-0');
            panel.classList.remove('scale-95', 'opacity-0');
        }, 10);
        setTimeout(() => {
            panel.focus();
        }, 60);
    }

    function setDrawerPlayMode(mode) {
        const lblFixed = document.getElementById('drawer-mode-fixed-label');
        const lblOpen = document.getElementById('drawer-mode-open-label');
        const fixedPanel = document.getElementById('drawer-fixed-duration-panel');
        const openNote = document.getElementById('drawer-open-duration-note');
        const durationInput = document.getElementById('drawer-walkin-duration');

        if (mode === 'FIXED') {
            if (lblFixed) lblFixed.className = `border-2 ${themeBorderStrong} ${themeBgLight} rounded-xl p-3 cursor-pointer text-xs font-bold ${themeTextMedium} transition-all text-center`;
            if (lblOpen) lblOpen.className = "border-2 border-zinc-150 rounded-xl p-3 cursor-pointer text-xs font-bold text-zinc-700 hover:border-zinc-300 transition-all text-center";
            if (fixedPanel) fixedPanel.classList.remove('hidden');
            if (openNote) openNote.classList.add('hidden');

            // Revert duration input to the active button's value
            let activeFixedBtn = document.querySelector(`.drawer-duration-btn.\${themeBorderStrong}`);
            if (activeFixedBtn) {
                const dur = parseInt(activeFixedBtn.getAttribute('data-duration-btn')) || 120;
                if (durationInput) durationInput.value = dur;
            } else if (durationInput) {
                durationInput.value = 120;
            }
        } else {
            if (lblFixed) lblFixed.className = "border-2 border-zinc-150 rounded-xl p-3 cursor-pointer text-xs font-bold text-zinc-700 hover:border-zinc-300 transition-all text-center";
            if (lblOpen) lblOpen.className = `border-2 ${themeBorderStrong} ${themeBgLight} rounded-xl p-3 cursor-pointer text-xs font-bold ${themeTextMedium} transition-all text-center`;
            if (fixedPanel) fixedPanel.classList.add('hidden');
            if (openNote) openNote.classList.remove('hidden');

            // For open mode, duration input is unused for billing but kept at a sane default
            if (durationInput) durationInput.value = 120;

            const customWrap = document.getElementById('drawer-custom-hours-wrap');
            if (customWrap) customWrap.classList.add('hidden');
        }
        calculateDrawerPrice();
    }

    function setDrawerDuration(mins) {
        const durationInput = document.getElementById('drawer-walkin-duration');
        if (durationInput) {
            durationInput.value = mins;
        }

        // Highlight active preset button
        const buttons = document.querySelectorAll('.drawer-duration-btn');
        buttons.forEach(btn => {
            const btnDur = parseInt(btn.getAttribute('data-duration-btn'));
            if (btnDur === mins) {
                btn.className = `drawer-duration-btn py-2.5 px-1 rounded-lg border \${themeBorderStrong} \${themeBgLight} text-xs font-bold \${themeTextMedium}`;
            } else {
                btn.className = "drawer-duration-btn py-2.5 px-1 rounded-lg border border-zinc-200 text-xs font-bold text-zinc-700 hover:bg-zinc-50";
            }
        });

        // Reset "Khác" button and hide the custom input
        const customBtn = document.getElementById('drawer-duration-custom-btn');
        if (customBtn) customBtn.className = "py-2.5 px-1 rounded-lg border border-zinc-200 text-xs font-bold text-zinc-700 hover:bg-zinc-50";
        const customWrap = document.getElementById('drawer-custom-hours-wrap');
        if (customWrap) customWrap.classList.add('hidden');
        const customHoursInput = document.getElementById('drawer-custom-hours');
        if (customHoursInput) customHoursInput.value = '';

        calculateDrawerPrice();
    }

    function showDrawerCustomDuration() {
        const customWrap = document.getElementById('drawer-custom-hours-wrap');
        if (customWrap) customWrap.classList.remove('hidden');

        document.querySelectorAll('.drawer-duration-btn').forEach(btn => {
            btn.className = "drawer-duration-btn py-2.5 px-1 rounded-lg border border-zinc-200 text-xs font-bold text-zinc-700 hover:bg-zinc-50";
        });
        const customBtn = document.getElementById('drawer-duration-custom-btn');
        if (customBtn) customBtn.className = `py-2.5 px-1 rounded-lg border ${themeBorderStrong} ${themeBgLight} text-xs font-bold ${themeTextMedium}`;

        const durationInput = document.getElementById('drawer-walkin-duration');
        const customHoursInput = document.getElementById('drawer-custom-hours');
        if (customHoursInput) {
            if (!customHoursInput.value) {
                const currentMins = parseInt(durationInput ? durationInput.value : 0) || 120;
                customHoursInput.value = currentMins / 60;
            }
            setTimeout(() => customHoursInput.focus(), 50);
        }
    }

    function setDrawerCustomDuration() {
        const customHoursInput = document.getElementById('drawer-custom-hours');
        const durationInput = document.getElementById('drawer-walkin-duration');
        if (!customHoursInput || !durationInput) return;

        const hours = parseFloat(customHoursInput.value);
        if (!isNaN(hours) && hours > 0) {
            durationInput.value = Math.round(hours * 60);
        }
        calculateDrawerPrice();
    }

    let drawerOverlapBlocked = false;

    function calculateDrawerPrice() {
        const durationSelect = document.getElementById('drawer-walkin-duration');
        const rateInput = document.getElementById('drawer-walkin-rate');
        const totalSpan = document.getElementById('drawer-walkin-total');
        const startSpan = document.getElementById('drawer-walkin-start-time');
        const endSpan = document.getElementById('drawer-walkin-end-time');
        const overlapBox = document.getElementById('drawer-walkin-overlap-warning');
        const overlapText = document.getElementById('drawer-walkin-overlap-text');
        const submitBtn = document.getElementById('drawer-walkin-submit-btn');
        const submitLabel = document.getElementById('drawer-walkin-submit-label');
        if (!durationSelect || !rateInput || !totalSpan) return;

        const openRadio = document.querySelector('#courtDetailDrawer input[name="playMode"][value="OPEN"]');
        const isOpen = openRadio && openRadio.checked;

        const now = new Date();
        if (startSpan) startSpan.textContent = formatHm(now);

        drawerOverlapBlocked = false;
        if (overlapBox) overlapBox.classList.add('hidden');

        if (isOpen) {
            totalSpan.textContent = "Tính theo thời gian sử dụng thực tế";
            if (endSpan) endSpan.textContent = "Chưa xác định";
            if (submitLabel) submitLabel.textContent = 'Mở sân linh hoạt';
            if (submitBtn) submitBtn.disabled = false;
            return;
        }

        if (submitLabel) submitLabel.textContent = 'Mở sân ngay';

        const duration = parseInt(durationSelect.value) || 0;
        const rate = parseFloat(rateInput.value) || 0;
        const total = (duration / 60.0) * rate;

        totalSpan.textContent = formatCurrency(total);

        const endDate = new Date(now.getTime() + duration * 60000);
        if (endSpan) {
            let endText = formatHm(endDate);
            if (endDate.toDateString() !== now.toDateString()) {
                endText += ' hôm sau';
            }
            endSpan.textContent = endText;
        }

        // Block submit if the chosen fixed duration overlaps the next booking today
        if (activeDrawerSanId !== null) {
            const next = getNextBookingForSan(activeDrawerSanId, now);
            if (next && endDate > next.startDate) {
                drawerOverlapBlocked = true;
                if (overlapBox) overlapBox.classList.remove('hidden');
                if (overlapText) overlapText.textContent = `Thời lượng đã chọn trùng với lịch đặt lúc \${next.booking.gioBatDau}. Vui lòng chọn thời lượng ngắn hơn.`;
            }
        }

        if (submitBtn) submitBtn.disabled = drawerOverlapBlocked;
    }

    function closeCourtDetailDrawer(force) {
        // Don't allow closing mid-submit unless explicitly forced (e.g. after a successful AJAX-less POST navigates away anyway)
        if (isDrawerSubmitting && force !== true) return;

        if (drawerTimerInterval) {
            clearInterval(drawerTimerInterval);
            drawerTimerInterval = null;
        }
        activeDrawerSanId = null;
        const drawer = document.getElementById('courtDetailDrawer');
        const overlay = document.getElementById('drawerOverlay');
        const panel = document.getElementById('courtDetailDrawerPanel');

        panel.classList.add('scale-95', 'opacity-0');
        overlay.classList.add('opacity-0');
        setTimeout(() => {
            drawer.classList.add('hidden');
            overlay.classList.add('hidden');
            document.body.style.overflow = '';
        }, 200);

        if (drawerTriggerEl && typeof drawerTriggerEl.focus === 'function') {
            drawerTriggerEl.focus();
        }
        drawerTriggerEl = null;
    }

    // Escape-to-close + focus trap while the court detail modal is open
    document.addEventListener('keydown', (e) => {
        const drawer = document.getElementById('courtDetailDrawer');
        if (!drawer || drawer.classList.contains('hidden')) return;

        if (e.key === 'Escape') {
            closeCourtDetailDrawer();
            return;
        }

        if (e.key === 'Tab') {
            const panel = document.getElementById('courtDetailDrawerPanel');
            const focusables = panel.querySelectorAll('button:not([disabled]):not(.hidden), a[href], input:not([disabled]):not([type="hidden"]), select:not([disabled]), textarea:not([disabled])');
            const visible = Array.from(focusables).filter(el => el.offsetParent !== null);
            if (!visible.length) return;
            const first = visible[0];
            const last = visible[visible.length - 1];
            if (e.shiftKey && document.activeElement === first) {
                e.preventDefault();
                last.focus();
            } else if (!e.shiftKey && document.activeElement === last) {
                e.preventDefault();
                first.focus();
            }
        }
    });

    // Escape-to-close cho modal Thanh toán & Quản lý Dịch vụ - chặn đóng khi đang PROCESSING
    // (đang chờ transaction thanh toán commit), cho phép đóng ở EDITING và SUCCESS.
    document.addEventListener('keydown', (e) => {
        if (e.key !== 'Escape') return;
        const modal = document.getElementById('staffInvoiceModal');
        if (!modal || modal.classList.contains('hidden')) return;
        if (currentPaymentModalState === PaymentModalState.PROCESSING
            || currentPaymentModalState === PaymentModalState.CREATING_PAYOS
            || currentPaymentModalState === PaymentModalState.VERIFYING_PAYOS) return;
        closeStaffInvoiceModal();
    });

    // Dừng polling PayOS khi rời trang hoặc chuyển tab ẩn - tránh gọi API PayOS không cần thiết
    // khi nhân viên không còn nhìn màn hình; tiếp tục polling khi quay lại tab nếu vẫn đang chờ.
    window.addEventListener('beforeunload', () => { stopPayOSPolling(); });
    document.addEventListener('visibilitychange', () => {
        if (document.hidden) stopPayOSPolling();
        else if (currentPaymentModalState === PaymentModalState.AWAITING_PAYOS) startPayOSPolling();
    });

    // Prevent double-submit on the walk-in "Mở sân ngay" form
    document.addEventListener('DOMContentLoaded', () => {
        const walkinForm = document.getElementById('drawer-walkin-form');
        if (walkinForm) {
            walkinForm.addEventListener('submit', (e) => {
                if (drawerOverlapBlocked) {
                    e.preventDefault();
                    return;
                }
                isDrawerSubmitting = true;
                const btn = document.getElementById('drawer-walkin-submit-btn');
                const label = document.getElementById('drawer-walkin-submit-label');
                if (btn) btn.disabled = true;
                if (label) label.textContent = 'Đang mở sân...';
            });
        }
    });

    // --- Split Bill ---
    let currentBillMode = 'MAIN';
    let currentMainBillPaid = false;

    function setBillMode(mode) {
        currentBillMode = mode;
        document.getElementById('staff-save-billmode').value = mode;

        const lblMain = document.getElementById('lbl-billmode-main');
        const lblSplit = document.getElementById('lbl-billmode-split');
        const payNowSection = document.getElementById('split-paynow-section');
        const descriptionEl = document.getElementById('bill-mode-description');
        const isMain = mode === 'MAIN';

        lblMain.classList.toggle('active', isMain);
        lblMain.setAttribute('aria-checked', String(isMain));
        lblMain.disabled = currentMainBillPaid;
        lblMain.classList.toggle('opacity-40', currentMainBillPaid);
        lblMain.classList.toggle('cursor-not-allowed', currentMainBillPaid);

        lblSplit.classList.toggle('active', !isMain);
        lblSplit.setAttribute('aria-checked', String(!isMain));

        payNowSection.classList.toggle('hidden', isMain);
        payNowSection.classList.toggle('flex', !isMain);

        if (descriptionEl) {
            descriptionEl.textContent = isMain
                ? 'Tiền sân và dịch vụ được thanh toán chung.'
                : 'Dịch vụ được ghi nhận thành hóa đơn riêng.';
        }
    }

    // Chỉ hiện lựa chọn Loại hóa đơn dịch vụ khi giỏ có sản phẩm - ẩn hoàn toàn nếu giỏ rỗng.
    function updateBillModeSectionVisibility() {
        const section = document.getElementById('bill-mode-section');
        if (section) section.classList.toggle('hidden', staffOrdered.length === 0);
    }

    function renderSplitBillsList(splitBills) {
        const section = document.getElementById('split-bills-section');
        const list = document.getElementById('split-bills-list');
        if (!splitBills || splitBills.length === 0) {
            section.classList.add('hidden');
            return;
        }
        section.classList.remove('hidden');
        list.innerHTML = '';
        splitBills.forEach(sb => {
            const isPaid = sb.trangThai === 'Đã thanh toán';
            const formattedTotal = formatCurrency(sb.tongThanhToan);
            const payBtnHtml = !isPaid ? (
                '<button type="button" onclick="paySplitBill(' + sb.hoaDonId + ')" ' +
                'class="px-3 py-1.5 rounded-lg bg-green-600 hover:bg-green-700 text-white font-bold text-[10px] active:scale-95 transition-all">' +
                'Thanh toán' +
                '</button>'
            ) : '';
            list.insertAdjacentHTML('beforeend', `
                <div class="p-3 rounded-xl border \${isPaid ? 'border-green-200 bg-green-50' : 'border-amber-200 bg-amber-50'} text-xs flex items-center justify-between gap-2">
                    <div>
                        <span class="font-bold text-zinc-800">HĐ Tách #\${sb.hoaDonId}</span>
                        <span class="text-zinc-500 ml-2">\${sb.ngayLap}</span>
                        <span class="ml-2 \${isPaid ? 'text-green-700' : 'text-amber-700'} font-bold">\${isPaid ? '✓ Đã TT' : '⏳ Chưa TT'}</span>
                        <span class="ml-2 font-extrabold text-zinc-800">\${formattedTotal}</span>
                    </div>
                    \${payBtnHtml}
                </div>
            `);
        });
    }

    function paySplitBill(hoaDonId) {
        if (!confirm('Xác nhận thanh toán hóa đơn tách #' + hoaDonId + '?')) return;
        const form = document.createElement('form');
        form.method = 'post';
        form.action = '${pageContext.request.contextPath}/staff/checkin';
        form.innerHTML = '<input type="hidden" name="action" value="payInvoice">' +
            '<input type="hidden" name="hoaDonId" value="' + hoaDonId + '">' +
            '<input type="hidden" name="phuongThucThanhToan" value="Tiền mặt">';
        document.body.appendChild(form);
        form.submit();
    }

    // Chế độ "Thêm dịch vụ": gửi AJAX, không submit form/reload trang, giữ modal mở sau khi lưu.
    let isStaffSavingServices = false;

    async function handleSaveServicesAction() {
        if (isStaffSavingServices || currentPaymentModalState !== PaymentModalState.EDITING) return;

        isStaffSavingServices = true;
        const btn = document.getElementById('staff-payment-submit-btn');
        const label = document.getElementById('staff-payment-submit-label');
        if (btn) btn.disabled = true;
        if (label) label.textContent = 'Đang lưu...';

        const errorBox = document.getElementById('staff-payment-error');
        if (errorBox) errorBox.classList.add('hidden');

        if (staffOrdered.length === 0) {
            showStaffPaymentError('Vui lòng chọn ít nhất một dịch vụ.');
            isStaffSavingServices = false;
            if (btn) btn.disabled = false;
            if (label) label.textContent = 'Lưu dịch vụ';
            return;
        }

        let billMode = currentBillMode;
        if (billMode === 'MAIN' && currentMainBillPaid) {
            if (!confirm('Hóa đơn sân đã được thanh toán. Bạn có muốn tạo hóa đơn tách thay thế không?')) {
                isStaffSavingServices = false;
                if (btn) btn.disabled = false;
                if (label) label.textContent = 'Lưu dịch vụ';
                return;
            }
            billMode = 'SPLIT';
        }

        let payNow = false;
        const paymentMethod = document.getElementById('staff-pay-method-input')?.value || 'Tiền mặt';
        if (billMode === 'SPLIT') {
            const payNowCb = document.getElementById('split-pay-now-cb');
            payNow = !!(payNowCb && payNowCb.checked);
        }

        const params = new URLSearchParams();
        params.set('action', 'addServices');
        params.set('datSanId', String(currentStaffDatSanId));
        params.set('billMode', billMode);
        params.set('payNow', payNow ? 'true' : 'false');
        params.set('phuongThucThanhToan', paymentMethod);
        staffOrdered.forEach(item => {
            params.append('productId', String(item.SanPhamID));
            params.append('quantity', String(item.SoLuong));
        });

        setPaymentModalState(PaymentModalState.PROCESSING);

        try {
            const response = await fetch('${pageContext.request.contextPath}/staff/checkin', {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: params.toString()
            });
            const contentType = response.headers.get('content-type') || '';
            const rawText = await response.text();
            if (!contentType.includes('application/json')) {
                console.error('Non-JSON addServices response:', { status: response.status, contentType, body: rawText });
                throw new Error(`Máy chủ trả về HTTP \${response.status} nhưng không có JSON.`);
            }
            let data;
            try { data = JSON.parse(rawText); }
            catch (parseError) { throw new Error('Phản hồi JSON không hợp lệ.'); }
            if (!response.ok || !data.success) {
                throw new Error(data.message || `Không thể lưu dịch vụ (HTTP \${response.status}).`);
            }

            isStaffSavingServices = false;
            setPaymentModalState(PaymentModalState.EDITING);
            showStaffToast(data.message || 'Đã lưu dịch vụ.');
            // Giữ modal mở, làm mới giỏ/hóa đơn tách/tổng tiền từ dữ liệu backend mới nhất.
            await fetchAndRenderInvoiceDetails(currentStaffDatSanId, { isInitialLoad: false });
        } catch (err) {
            isStaffSavingServices = false;
            setPaymentModalState(PaymentModalState.EDITING);
            showStaffPaymentError(err.message || 'Không thể lưu dịch vụ. Vui lòng thử lại.');
        }
    }

    // Initialize subtotal and event listener for product stock check
    document.addEventListener("DOMContentLoaded", () => {
        calculateDrawerPrice();
        
        const prodSelect = document.getElementById("staff-product-select");
        const addBtn = document.getElementById("staff-add-service-btn");
        if (prodSelect) {
            prodSelect.addEventListener("change", function() {
                const selectedOption = this.options[this.selectedIndex];
                if (!selectedOption || !selectedOption.value) {
                    if (addBtn) {
                        addBtn.removeAttribute("disabled");
                        addBtn.textContent = "Thêm";
                    }
                    return;
                }
                
                const spId = parseInt(selectedOption.value);
                const prod = staffProducts.find(p => p.SanPhamID === spId);
                if (prod && prod.SoLuongTon <= 0) {
                    if (addBtn) {
                        addBtn.setAttribute("disabled", "disabled");
                        addBtn.textContent = "Hết hàng";
                    }
                } else {
                    if (addBtn) {
                        addBtn.removeAttribute("disabled");
                        addBtn.textContent = "Thêm";
                    }
                }
            });
        }
    });

    let currentExtensionMinutes = null;
    let currentExtensionNewTime = null;
    let currentExtensionPreviewData = null;

    function renderExtensionPanel(data) {
        const panel = document.getElementById("staff-extension-panel");
        if (!panel) return;
        const confirmBtn = document.getElementById("extension-confirm-btn");
        const previewResult = document.getElementById("extension-preview-result");
        
        currentExtensionMinutes = null;
        currentExtensionNewTime = null;
        currentExtensionPreviewData = null;
        const timeInput = document.getElementById("extension-new-time");
        if (timeInput) timeInput.value = "";
        if (previewResult) previewResult.classList.add("hidden");
        if (confirmBtn) {
            confirmBtn.disabled = true;
            confirmBtn.className = "w-full bg-zinc-300 text-white font-extrabold text-[10.5px] py-2 rounded-xl shadow-sm hover:shadow transition-all active:scale-95 flex items-center justify-center gap-1 select-none cursor-not-allowed";
        }

        if (data.bookingTrangThai === "Đang sử dụng" && data.timeMode !== "OPEN_ENDED") {
            panel.classList.remove("hidden");
        } else {
            panel.classList.add("hidden");
        }
    }

    function previewExtensionByMinutes(mins) {
        currentExtensionMinutes = mins;
        currentExtensionNewTime = null;
        const timeInput = document.getElementById("extension-new-time");
        if (timeInput) timeInput.value = "";
        runExtensionPreview({ extendMinutes: mins });
    }

    function previewExtensionByTime(timeStr) {
        if (!timeStr) return;
        currentExtensionMinutes = null;
        currentExtensionNewTime = timeStr;
        runExtensionPreview({ newEndTime: timeStr });
    }

    function runExtensionPreview(params) {
        const confirmBtn = document.getElementById("extension-confirm-btn");
        const previewResult = document.getElementById("extension-preview-result");
        const newEndEl = document.getElementById("extension-preview-new-end");
        const feeEl = document.getElementById("extension-preview-fee");
        const noteEl = document.getElementById("extension-preview-note");

        params.datSanId = currentStaffDatSanId;

        const urlParams = new URLSearchParams(params).toString();
        fetch('${pageContext.request.contextPath}/staff/checkin?action=previewSessionExtension&' + urlParams, {
            method: 'POST'
        })
        .then(res => res.json())
        .then(preview => {
            currentExtensionPreviewData = preview;
            if (previewResult) previewResult.classList.remove("hidden");
            if (preview.canExtend) {
                if (newEndEl) newEndEl.textContent = preview.newGioKetThuc ? preview.newGioKetThuc.substring(0, 5) : "--:--";
                if (feeEl) {
                    feeEl.textContent = formatCurrency(preview.additionalAmount || 0);
                    feeEl.className = "font-bold text-red-655";
                }
                if (noteEl) {
                    noteEl.textContent = preview.maxExtendableMinutes > 0 ? ("Khung giờ khả dụng tiếp theo tối đa: " + preview.maxExtendableMinutes + " phút.") : "";
                    noteEl.className = "text-zinc-550 italic mt-0.5 text-[10px] leading-tight";
                }
                if (confirmBtn) {
                    confirmBtn.disabled = false;
                    confirmBtn.className = "w-full bg-violet-600 hover:bg-violet-700 text-white font-extrabold text-[10.5px] py-2 rounded-xl shadow-sm hover:shadow transition-all active:scale-95 flex items-center justify-center gap-1 select-none";
                }
            } else {
                if (newEndEl) newEndEl.textContent = "--:--";
                if (feeEl) {
                    feeEl.textContent = "Không khả dụng";
                    feeEl.className = "font-bold text-red-500";
                }
                if (noteEl) {
                    noteEl.textContent = preview.message || "Không thể gia hạn chơi.";
                    noteEl.className = "text-red-500 font-bold mt-0.5 text-[10px] leading-tight";
                }
                if (confirmBtn) {
                    confirmBtn.disabled = true;
                    confirmBtn.className = "w-full bg-zinc-300 text-white font-extrabold text-[10.5px] py-2 rounded-xl shadow-sm hover:shadow transition-all active:scale-95 flex items-center justify-center gap-1 select-none cursor-not-allowed";
                }
            }
        })
        .catch(err => {
            console.error("Preview extension failed", err);
            if (newEndEl) newEndEl.textContent = "--:--";
            if (feeEl) {
                feeEl.textContent = "Lỗi";
                feeEl.className = "font-bold text-red-500";
            }
            if (noteEl) {
                noteEl.textContent = "Lỗi kết nối hoặc hệ thống khi tải xem trước.";
                noteEl.className = "text-red-500 font-bold mt-0.5 text-[10px] leading-tight";
            }
            if (confirmBtn) {
                confirmBtn.disabled = true;
                confirmBtn.className = "w-full bg-zinc-300 text-white font-extrabold text-[10.5px] py-2 rounded-xl shadow-sm hover:shadow transition-all active:scale-95 flex items-center justify-center gap-1 select-none cursor-not-allowed";
            }
        });
    }

    function confirmExtension() {
        if (!currentExtensionPreviewData || !currentExtensionPreviewData.canExtend) return;
        
        const confirmBtn = document.getElementById("extension-confirm-btn");
        if (confirmBtn) {
            confirmBtn.disabled = true;
            confirmBtn.textContent = "Đang xử lý...";
        }

        const params = {
            datSanId: currentStaffDatSanId
        };
        if (currentExtensionMinutes) params.extendMinutes = currentExtensionMinutes;
        if (currentExtensionNewTime) params.newEndTime = currentExtensionNewTime;

        const urlParams = new URLSearchParams(params).toString();
        fetch('${pageContext.request.contextPath}/staff/checkin?action=extendSession&' + urlParams, {
            method: 'POST'
        })
        .then(res => res.json())
        .then(result => {
            if (result.success) {
                showStaffToast(result.message);
                fetchAndRenderInvoiceDetails(currentStaffDatSanId);
                pollUpdates();
            } else {
                showStaffToast("Gia hạn thất bại: " + result.message);
                if (confirmBtn) {
                    confirmBtn.disabled = false;
                    confirmBtn.innerHTML = '<span class="material-symbols-outlined text-[14px]">done</span> Xác nhận gia hạn';
                }
            }
        })
        .catch(err => {
            console.error("Confirm extension failed", err);
            showStaffToast("Lỗi kết nối khi gửi yêu cầu gia hạn.");
            if (confirmBtn) {
                confirmBtn.disabled = false;
                confirmBtn.innerHTML = '<span class="material-symbols-outlined text-[14px]">done</span> Xác nhận gia hạn';
            }
        });
    }
</script>

<c:if test="${not empty autoOpenInvoiceDatSanId}">
    <script>
        document.addEventListener("DOMContentLoaded", () => {
            setTimeout(() => {
                openStaffInvoiceModal(${autoOpenInvoiceDatSanId});
            }, 600);
        });
    </script>
</c:if>

<!-- Early Checkout Adjustment Modal (Managers only) -->
<c:if test="${sessionScope.user.roleId == 1 || sessionScope.user.roleId == 2}">
<div id="earlyCheckoutAdjustmentModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[60] hidden flex items-center justify-center opacity-0 transition-opacity duration-300 p-4">
    <div class="bg-white w-full max-w-[400px] rounded-2xl shadow-2xl overflow-hidden transform scale-95 transition-all duration-300 relative flex flex-col p-6">
        <div class="flex justify-between items-center pb-3 border-b border-zinc-150 mb-4">
            <h3 class="text-base font-extrabold text-zinc-900 flex items-center gap-2">
                <span class="material-symbols-outlined text-green-600">local_activity</span>
                Giảm trừ trả sân sớm
            </h3>
            <button onclick="closeEarlyCheckoutAdjustmentModal()" class="p-1 rounded-full hover:bg-zinc-100 text-zinc-400">
                <span class="material-symbols-outlined text-[20px]">close</span>
            </button>
        </div>
        <form id="early-checkout-adjustment-form" method="post" action="${pageContext.request.contextPath}/staff/checkin">
            <input type="hidden" name="action" value="applyEarlyCheckoutAdjustment">
            <input type="hidden" name="datSanId" id="early-adjust-datsan-id">
            
            <div class="space-y-4">
                <div>
                    <label class="block text-xs font-bold text-zinc-550 mb-1">Tổng tiền sân ban đầu:</label>
                    <input type="text" id="early-adjust-court-total" class="w-full text-xs p-3 border border-zinc-150 rounded-xl bg-zinc-100 font-bold text-zinc-700" readonly>
                </div>
                <div>
                    <label class="block text-xs font-bold text-zinc-550 mb-1">Số tiền giảm trừ (VND):</label>
                    <input type="number" name="earlyDiscount" id="early-adjust-discount-amount" min="0" step="1000" class="w-full text-xs p-3 border border-zinc-200 rounded-xl focus:outline-none focus:border-green-600 focus:ring-1 focus:ring-green-600" required placeholder="VD: 50000">
                </div>
                <div>
                    <label class="block text-xs font-bold text-[#0b1c30] mb-1">Lý do giảm trừ:</label>
                    <textarea name="reason" id="early-adjust-reason" rows="3" class="w-full text-xs p-3 border border-zinc-200 rounded-xl focus:outline-none focus:border-green-600 focus:ring-1 focus:ring-green-600" required placeholder="Nhập lý do giảm trừ (bắt buộc)..."></textarea>
                </div>
            </div>
            
            <div class="flex gap-3 mt-6">
                <button type="button" onclick="closeEarlyCheckoutAdjustmentModal()" class="flex-1 bg-zinc-100 text-zinc-650 font-bold text-xs py-3 rounded-xl transition-colors hover:bg-zinc-200">Hủy</button>
                <button type="submit" class="flex-1 bg-green-600 hover:bg-green-700 text-white font-extrabold text-xs py-3 rounded-xl shadow transition-all active:scale-95">Xác nhận</button>
            </div>
        </form>
    </div>
</div>
</c:if>

<!-- Bank Transfer Confirm Dialog (xác nhận đã nhận tiền - modal-trong-modal, không dùng confirm() mặc định) -->
<div id="bankTransferConfirmModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[60] hidden flex items-center justify-center opacity-0 transition-opacity duration-300 p-4">
    <div class="bg-white w-full max-w-[420px] rounded-2xl shadow-2xl overflow-hidden transform scale-95 transition-all duration-300 relative flex flex-col p-6">
        <div class="flex justify-between items-center pb-3 border-b border-zinc-150 mb-4">
            <h3 class="text-base font-extrabold text-zinc-900 flex items-center gap-2">
                <span class="material-symbols-outlined text-green-600">verified</span>
                Xác nhận đã nhận tiền
            </h3>
            <button onclick="closeBankTransferConfirmDialog()" class="p-1 rounded-full hover:bg-zinc-100 text-zinc-400">
                <span class="material-symbols-outlined text-[20px]">close</span>
            </button>
        </div>
        <div class="space-y-2 text-sm mb-4 pb-4 border-b border-zinc-150" id="bank-transfer-confirm-summary"></div>
        <div class="mb-4">
            <label class="block text-xs font-bold text-zinc-550 mb-1">Mã giao dịch ngân hàng (tùy chọn)</label>
            <input type="text" id="bank-transfer-transaction-code" maxlength="100" class="w-full text-xs p-3 border border-zinc-200 rounded-xl focus:outline-none focus:border-green-600 focus:ring-1 focus:ring-green-600" placeholder="VD: FT24...">
        </div>
        <div id="bank-transfer-confirm-error" role="alert" class="hidden mb-3 p-2.5 rounded-lg bg-red-50 border border-red-200 text-red-700 text-xs font-semibold"></div>
        <div class="flex gap-3">
            <button type="button" onclick="closeBankTransferConfirmDialog()" class="flex-1 bg-zinc-100 text-zinc-650 font-bold text-xs py-3 rounded-xl transition-colors hover:bg-zinc-200">Hủy</button>
            <button type="button" id="bank-transfer-confirm-submit-btn" onclick="submitBankTransferConfirm()" class="flex-1 bg-green-600 hover:bg-green-700 text-white font-extrabold text-xs py-3 rounded-xl shadow transition-all active:scale-95 disabled:opacity-60">Xác nhận đã nhận đủ</button>
        </div>
    </div>
</div>

</body>
</html>
