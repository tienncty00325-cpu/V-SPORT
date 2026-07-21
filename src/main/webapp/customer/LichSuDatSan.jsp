<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="vi" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lịch Sử Đặt Sân - V-SPORT Elite Arena</title>
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <jsp:include page="/common/head.jsp" />
    <jsp:include page="/customer/common/vsport-theme.jsp" />
    <style>
        /* Ghi đè triệt để màu nền ấm (beige) và màu chữ mặc định từ head.jsp */
        body {
            font-family: 'Inter', system-ui, -apple-system, sans-serif !important;
            background-color: #f1f5f9 !important;
            color: #0f172a !important;
        }
        .premium-card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 16px;
        }
        .hs-hero {
            position: relative; overflow: hidden; color: #fff; border-radius: 20px;
            background: linear-gradient(135deg, #111111 0%, #4a0005 55%, #e3000f 100%);
        }
        .hs-hero::after {
            content: ""; position: absolute; right: -60px; top: -60px; width: 220px; height: 220px;
            background: radial-gradient(circle, rgba(255,255,255,.14), transparent 68%); pointer-events: none;
        }
        .hs-filter-chip {
            display:inline-flex; align-items:center; gap:6px; padding:7px 14px; border-radius:9999px;
            font-size:12.5px; font-weight:700; color:#475569; background:#fff; border:1px solid #e2e8f0;
            cursor:pointer; white-space:nowrap; transition:all .15s ease;
        }
        .hs-filter-chip:hover { border-color:#e3000f; color:#0f172a; }
        .hs-filter-chip.is-active { background:#e3000f; border-color:#e3000f; color:#fff; }

        /* Booking card: one responsive layout, no table, no horizontal overflow */
        .hs-card {
            background:#fff; border:1px solid #e2e8f0; border-radius:16px; padding:16px 18px;
            display:flex; flex-direction:column; gap:12px; transition: border-color .15s ease;
        }
        .hs-card:hover { border-color:#a7f3d0; }
        .hs-card-top { display:flex; items-align:flex-start; justify-content:space-between; gap:12px; flex-wrap:wrap; }
        .hs-badge { display:inline-block; padding:3px 10px; border-radius:8px; font-size:10.5px; font-weight:800; white-space:nowrap; }
        .hs-meta { display:flex; flex-wrap:wrap; gap-column: 14px; gap:6px 14px; font-size:12.5px; color:#475569; font-weight:600; }
        .hs-meta .material-symbols-outlined { font-size:15px; color:#94a3b8; vertical-align:-3px; margin-right:3px; }
        .hs-actions { display:flex; flex-wrap:wrap; gap:8px; padding-top:10px; border-top:1px dashed #e2e8f0; }
        .hs-action-btn {
            display:inline-flex; align-items:center; gap:5px; padding:7px 13px; border-radius:9px;
            font-size:11.5px; font-weight:700; transition:all .15s ease; white-space:nowrap;
        }
    </style>
</head>
<body class="min-h-screen flex flex-col antialiased">

    <!-- Header Navigation -->
    <jsp:include page="/customer/common/vsport-header.jsp" />

    <!-- Main Content Area -->
    <main class="flex-grow pt-20 md:pt-24 pb-10">
        <div class="max-w-[1300px] mx-auto px-4 sm:px-6 lg:px-8">

            <!-- Breadcrumb -->
            <nav class="text-xs text-slate-500 mb-3 flex items-center gap-1.5" aria-label="Breadcrumb">
                <a href="${pageContext.request.contextPath}/index.jsp" class="hover:text-red-600 transition-colors">Trang chủ</a>
                <span class="material-symbols-outlined text-[13px] text-slate-300">chevron_right</span>
                <span class="text-slate-700 font-semibold">Lịch sử đặt sân</span>
            </nav>

            <!-- Hero -->
            <div class="hs-hero mb-5 p-5 sm:p-7">
                <div class="relative z-10 max-w-2xl">
                    <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/15 border border-white/25 text-[11px] font-bold uppercase tracking-wider mb-3">
                        <span class="material-symbols-outlined text-[14px]">history</span> Hoạt động của bạn
                    </span>
                    <h1 class="text-2xl sm:text-3xl font-black tracking-tight mb-2">Lịch sử đặt sân</h1>
                    <p class="text-white/80 text-xs sm:text-sm leading-relaxed">
                        Theo dõi các đơn đặt sân, trạng thái duyệt lịch và tác động điểm uy tín của bạn.
                    </p>
                </div>
            </div>

            <!-- Success Alert Message -->
            <c:if test="${not empty sessionScope.message}">
                <div class="mb-5 p-4 bg-emerald-50 border border-emerald-100 rounded-2xl text-emerald-800 text-xs font-bold flex items-center gap-3 shadow-sm animate-fade-in-up">
                    <span class="material-symbols-outlined text-emerald-600 text-[20px]">check_circle</span>
                    <span>${sessionScope.message}</span>
                    <% session.removeAttribute("message"); %>
                </div>
            </c:if>

            <!-- Responsive layout -->
            <div class="grid grid-cols-1 lg:grid-cols-4 gap-5">

                <!-- Sidebar: User Stats & Quick Links -->
                <div class="lg:col-span-1 space-y-5 lg:sticky lg:top-24 lg:self-start">
                    <div class="premium-card p-6 flex flex-col items-center text-center">
                        <!-- User Initial Avatar -->
                        <div class="w-16 h-16 rounded-full bg-red-50 text-red-600 flex items-center justify-center font-extrabold text-2xl shadow-inner mb-4">
                            <c:choose>
                                <c:when test="${not empty user.fullName}">
                                    ${fn:substring(user.fullName, 0, 1).toUpperCase()}
                                </c:when>
                                <c:otherwise>
                                    ${fn:substring(user.username, 0, 1).toUpperCase()}
                                </c:otherwise>
                            </c:choose>
                        </div>
                        <h3 class="font-extrabold text-slate-800 text-base leading-tight">${user.fullName}</h3>
                        <p class="text-slate-450 text-xs mt-1 font-medium">${user.email}</p>

                        <div class="w-full border-t border-slate-100 my-5"></div>

                        <!-- Simple stats -->
                        <div class="w-full grid grid-cols-2 gap-3">
                            <div class="text-center bg-slate-50 rounded-xl p-3 border border-slate-100">
                                <span class="text-[10px] text-slate-400 font-bold block uppercase tracking-wide">Đặt Sân</span>
                                <span class="text-lg font-black text-red-600 mt-1 block">${dsLich.size()}</span>
                            </div>
                            <div class="text-center bg-slate-50 rounded-xl p-3 border border-slate-100">
                                <span class="text-[10px] text-slate-400 font-bold block uppercase tracking-wide">Điểm Uy Tín</span>
                                <span class="text-lg font-black text-slate-700 mt-1 block">${user.diemUyTin != null ? user.diemUyTin : 100}</span>
                            </div>
                        </div>

                        <a href="${pageContext.request.contextPath}/customer/tai-khoan#uyTinCuaToi" class="w-full mt-4 text-red-600 text-[11px] font-bold text-center hover:underline">
                            Xem chi tiết điểm uy tín &rarr;
                        </a>

                        <a href="${pageContext.request.contextPath}/customer/dat-san" class="w-full mt-3 bg-[#e3000f] hover:bg-[#c2000d] text-white font-extrabold text-xs py-3 rounded-xl flex items-center justify-center gap-1.5 transition-all shadow-sm shadow-red-600/10 active:scale-95 duration-200">
                            <span class="material-symbols-outlined text-[16px]">add_circle</span>
                            Đặt sân mới ngay
                        </a>
                    </div>

                    <!-- Reputation impact legend -->
                    <div class="premium-card p-5">
                        <h4 class="text-[11px] font-extrabold text-slate-500 uppercase tracking-wide mb-3">Uy tín & hủy lịch</h4>
                        <p class="text-xs text-slate-600 flex items-start gap-2 mb-2"><span class="material-symbols-outlined text-[#16A36A] text-[15px] mt-0.5">check_circle</span> Hủy sớm (trước 6 tiếng) không bị trừ điểm.</p>
                        <p class="text-xs text-slate-600 flex items-start gap-2 mb-2"><span class="material-symbols-outlined text-amber-500 text-[15px] mt-0.5">warning</span> Hủy sát giờ có thể ảnh hưởng điểm uy tín.</p>
                        <p class="text-xs text-slate-600 flex items-start gap-2"><span class="material-symbols-outlined text-rose-500 text-[15px] mt-0.5">error</span> Không đến sân trừ điểm nhiều hơn hủy sát giờ.</p>
                    </div>
                </div>

                <!-- Main Content: booking cards -->
                <div class="lg:col-span-3">
                    <div class="premium-card p-5 sm:p-6">
                        <div class="flex flex-col gap-4 mb-5">
                            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                                <h2 class="text-sm font-extrabold text-slate-900 tracking-tight flex items-center gap-2">
                                    <span class="material-symbols-outlined text-red-600 text-[19px]">calendar_month</span>
                                    Danh sách đơn đặt sân
                                </h2>
                                <div class="relative w-full sm:max-w-xs">
                                    <span class="absolute left-3 top-1/2 -translate-y-1/2 material-symbols-outlined text-[16px] text-slate-400">search</span>
                                    <input type="search" id="historySearchInput" autocomplete="off" placeholder="Tìm theo mã, tên sân..."
                                           class="h-9 w-full pl-9 pr-3 rounded-xl border border-slate-200 bg-white text-xs focus:outline-none focus:ring-2 focus:ring-red-500/20 focus:border-red-500 transition-all">
                                </div>
                            </div>
                            <!-- Status filter chips (client-side, layered on top of existing search/pagination) -->
                            <div class="flex items-center gap-2 overflow-x-auto pb-1" id="historyStatusChips">
                                <button type="button" class="hs-filter-chip is-active" data-status-filter="all">Tất cả</button>
                                <button type="button" class="hs-filter-chip" data-status-filter="upcoming">Sắp tới</button>
                                <button type="button" class="hs-filter-chip" data-status-filter="completed">Đã hoàn thành</button>
                                <button type="button" class="hs-filter-chip" data-status-filter="cancelled">Đã hủy / Không đến</button>
                            </div>
                        </div>

                        <div id="historyTableBody" class="flex flex-col gap-3">
                            <c:forEach var="lich" items="${dsLich}">
                                <c:set var="tenSanHienThi" value="Sân #${lich.sanId}" />
                                <c:set var="branchHienThi" value="" />
                                <c:forEach var="s" items="${dsSan}">
                                    <c:if test="${s.sanID == lich.sanId}">
                                        <c:set var="tenSanHienThi" value="${s.tenSan}" />
                                        <c:forEach var="cs" items="${dsCoSo}">
                                            <c:if test="${cs.coSoID == s.coSoID}">
                                                <c:set var="branchHienThi" value="${cs.tenCoSo}" />
                                            </c:if>
                                        </c:forEach>
                                    </c:if>
                                </c:forEach>

                                <c:set var="hsStatusGroup" value="other" />
                                <c:if test="${lich.trangThai == 'Chờ thanh toán' || lich.trangThai == 'Chờ xác nhận' || lich.trangThai == 'Đã xác nhận' || lich.trangThai == 'Đã đặt' || lich.trangThai == 'Đang sử dụng'}"><c:set var="hsStatusGroup" value="upcoming" /></c:if>
                                <c:if test="${lich.trangThai == 'Đã hoàn thành'}"><c:set var="hsStatusGroup" value="completed" /></c:if>
                                <c:if test="${lich.trangThai == 'Đã hủy' || lich.trangThai == 'Không đến'}"><c:set var="hsStatusGroup" value="cancelled" /></c:if>

                                <div class="hs-card history-row" data-status-group="${hsStatusGroup}">
                                    <div class="hs-card-top">
                                        <div class="min-w-0">
                                            <div class="flex items-center gap-2 flex-wrap mb-1">
                                                <span class="font-extrabold text-sm text-slate-900">${tenSanHienThi}</span>
                                                <c:choose>
                                                    <c:when test="${lich.trangThai == 'Chờ thanh toán'}">
                                                        <span class="hs-badge bg-orange-50 text-orange-700 border border-orange-200">Chờ thanh toán</span>
                                                    </c:when>
                                                    <c:when test="${lich.trangThai == 'Chờ xác nhận'}">
                                                        <span class="hs-badge bg-amber-50 text-amber-700 border border-amber-200">Chờ duyệt</span>
                                                    </c:when>
                                                    <c:when test="${lich.trangThai == 'Đã xác nhận' || lich.trangThai == 'Đã đặt'}">
                                                        <span class="hs-badge bg-green-50 text-green-700 border border-green-200">Đã duyệt</span>
                                                    </c:when>
                                                    <c:when test="${lich.trangThai == 'Đang sử dụng'}">
                                                        <span class="hs-badge bg-purple-50 text-purple-700 border border-purple-200">Đang đá</span>
                                                    </c:when>
                                                    <c:when test="${lich.trangThai == 'Đã hủy'}">
                                                        <span class="hs-badge bg-red-50 text-red-700 border border-red-200">Đã hủy</span>
                                                    </c:when>
                                                    <c:when test="${lich.trangThai == 'Không đến'}">
                                                        <span class="hs-badge bg-rose-50 text-rose-700 border border-rose-200">Không đến</span>
                                                    </c:when>
                                                    <c:when test="${lich.trangThai == 'Đã hoàn thành'}">
                                                        <span class="hs-badge bg-emerald-50 text-emerald-700 border border-emerald-200">Hoàn thành</span>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <span class="hs-badge bg-slate-100 text-slate-500 border border-slate-200">${lich.trangThai}</span>
                                                    </c:otherwise>
                                                </c:choose>
                                            </div>
                                            <div class="hs-meta">
                                                <c:if test="${not empty branchHienThi}">
                                                    <span><span class="material-symbols-outlined">location_on</span>${branchHienThi}</span>
                                                </c:if>
                                                <span><span class="material-symbols-outlined">tag</span>Mã #${lich.datSanId}</span>
                                                <span><span class="material-symbols-outlined">calendar_month</span>${lich.ngayDat}</span>
                                                <span class="text-red-700 font-mono"><span class="material-symbols-outlined">schedule</span>${lich.gioBatDau.toString().substring(0,5)} - ${lich.gioKetThuc.toString().substring(0,5)}</span>
                                            </div>
                                        </div>
                                        <div class="text-right shrink-0">
                                            <p class="text-[10px] font-bold text-slate-400 uppercase tracking-wide">Tổng chi phí</p>
                                            <p class="font-extrabold text-slate-900 text-base"><fmt:formatNumber value="${lich.tongTienDuKien}" type="currency" currencySymbol="đ" maxFractionDigits="0" /></p>
                                        </div>
                                    </div>

                                    <!-- Reputation impact -->
                                    <c:set var="repHist" value="${reputationByDatSanId[lich.datSanId]}" />
                                    <c:choose>
                                        <c:when test="${lich.trangThai == 'Đã hoàn thành'}">
                                            <span class="text-[#16A36A] text-[11px] font-bold inline-flex items-center gap-1 w-fit">
                                                <span class="material-symbols-outlined text-[14px]">add_circle</span> Đã cộng điểm uy tín
                                            </span>
                                        </c:when>
                                        <c:when test="${not empty repHist && repHist.actionType == 'LATE_CANCEL'}">
                                            <span class="text-amber-600 text-[11px] font-bold inline-flex items-center gap-1 w-fit">
                                                <span class="material-symbols-outlined text-[14px]">warning</span> Hủy sát giờ &middot; ${repHist.scoreDelta} điểm uy tín
                                            </span>
                                        </c:when>
                                        <c:when test="${not empty repHist && repHist.actionType == 'NO_SHOW'}">
                                            <span class="text-rose-600 text-[11px] font-bold inline-flex items-center gap-1 w-fit">
                                                <span class="material-symbols-outlined text-[14px]">error</span> Không đến sân &middot; ${repHist.scoreDelta} điểm uy tín
                                            </span>
                                        </c:when>
                                        <c:when test="${lich.trangThai == 'Đã hủy'}">
                                            <span class="text-slate-400 text-[11px] font-bold inline-flex items-center gap-1 w-fit">
                                                <span class="material-symbols-outlined text-[14px]">check_circle</span> Hủy sớm, không trừ điểm
                                            </span>
                                        </c:when>
                                    </c:choose>

                                    <!-- Cancellation reason, when present -->
                                    <c:if test="${(lich.trangThai == 'Đã hủy' || lich.trangThai == 'Không đến') && not empty lich.ghiChu}">
                                        <p class="text-[11px] text-slate-500 bg-slate-50 border border-slate-100 rounded-lg px-3 py-2">
                                            <span class="font-bold text-slate-600">Lý do:</span> ${fn:escapeXml(lich.ghiChu)}
                                        </p>
                                    </c:if>

                                    <!-- Actions -->
                                    <c:if test="${lich.trangThai == 'Chờ thanh toán'}">
                                        <div class="hs-actions">
                                            <a href="${pageContext.request.contextPath}/customer/thanh-toan-qr?datSanId=${lich.datSanId}"
                                               class="hs-action-btn text-white active:scale-95" style="background: var(--vs-primary-500, #e3000f); border: 1px solid var(--vs-primary-500, #e3000f);">
                                                <span class="material-symbols-outlined text-[14px]">qr_code_2</span> Tiếp tục thanh toán
                                            </a>
                                            <a href="${pageContext.request.contextPath}/customer/payos-cancel?datSanId=${lich.datSanId}"
                                               onclick="return confirm('Hủy đơn thanh toán này? Khung giờ sẽ được giải phóng.');"
                                               class="hs-action-btn border border-red-200 text-red-500 hover:bg-red-50 hover:border-red-300 active:scale-95">
                                                <span class="material-symbols-outlined text-[14px]">cancel</span> Hủy thanh toán
                                            </a>
                                        </div>
                                    </c:if>
                                    <c:if test="${lich.trangThai == 'Chờ xác nhận' || lich.trangThai == 'Đã xác nhận' || lich.trangThai == 'Đang sử dụng'}">
                                        <div class="hs-actions">
                                            <c:if test="${lich.trangThai == 'Chờ xác nhận' || lich.trangThai == 'Đã xác nhận'}">
                                                <button type="button"
                                                        onclick="openCancelBookingModal(${lich.datSanId}, '${lich.ngayDat}', '${lich.gioBatDau}')"
                                                        class="hs-action-btn border border-red-200 text-red-500 hover:bg-red-50 hover:border-red-300 active:scale-95">
                                                    <span class="material-symbols-outlined text-[14px]">cancel</span> Hủy đặt sân
                                                </button>
                                            </c:if>
                                            <button type="button" onclick="openCustomerServiceModal(${lich.datSanId})" class="hs-action-btn border border-slate-200 bg-slate-50 text-red-700 hover:bg-slate-100 active:scale-95">
                                                <span class="material-symbols-outlined text-[14px]">coffee</span> Thêm dịch vụ
                                            </button>
                                            <c:if test="${lich.trangThai == 'Đã xác nhận'}">
                                                <button type="button" onclick="openUrgentOpponentModal()" class="hs-action-btn border border-amber-300 bg-amber-50 text-amber-700 hover:bg-amber-100 active:scale-95">
                                                    <span class="material-symbols-outlined text-[14px]">bolt</span> Tìm người chơi gấp
                                                </button>
                                            </c:if>
                                        </div>
                                    </c:if>
                                </div>
                            </c:forEach>
                            <c:if test="${empty dsLich}">
                                <div class="p-14 text-center">
                                    <span class="material-symbols-outlined text-[40px] text-slate-200 block mb-4">event_busy</span>
                                    <p class="text-slate-400 text-[11px] font-extrabold uppercase tracking-widest">Chưa có dữ liệu lịch sử đặt sân</p>
                                    <a href="${pageContext.request.contextPath}/customer/dat-san" class="btn-primary inline-flex mt-5">
                                        <span class="material-symbols-outlined text-[16px]">add</span> Đặt sân ngay
                                    </a>
                                </div>
                            </c:if>
                        </div>

                        <div id="historyPagination" class="hidden px-1 pt-4 mt-2 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
                            <span id="historyPaginationInfo">Hiển thị...</span>
                            <div class="flex items-center gap-1" id="historyPaginationBtns"></div>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </main>

    <!-- Footer -->
    <jsp:include page="/common/footer.jsp" />

    <script>
        // Active link highlight
        const navHistory = document.getElementById('nav-history');
        if (navHistory) {
            navHistory.classList.add('active');
        }

        // Search + status-filter + pagination script
        document.addEventListener('DOMContentLoaded', () => {
            const tableBody = document.getElementById('historyTableBody');
            const pagPanel = document.getElementById('historyPagination');
            const searchInput = document.getElementById('historySearchInput');
            const statusChips = document.querySelectorAll('#historyStatusChips [data-status-filter]');
            if (!tableBody || !pagPanel) return;

            const rows = Array.from(tableBody.querySelectorAll('.history-row'));
            if (rows.length === 0) return;

            const pageSize = 5;
            let currentPage = 1;
            let activeStatus = 'all';

            function applyFilters(resetPage = true) {
                if (resetPage) {
                    currentPage = 1;
                }
                const searchValue = searchInput ? searchInput.value.toLowerCase().trim() : '';
                const matchedRows = [];

                rows.forEach(row => {
                    const text = row.innerText.toLowerCase();
                    const statusOk = activeStatus === 'all' || row.getAttribute('data-status-group') === activeStatus;
                    if (statusOk && text.includes(searchValue)) {
                        matchedRows.push(row);
                    } else {
                        row.style.display = 'none';
                    }
                });

                const totalPages = Math.ceil(matchedRows.length / pageSize);
                const start = (currentPage - 1) * pageSize;
                const end = start + pageSize;

                matchedRows.forEach((row, index) => {
                    if (index >= start && index < end) {
                        row.style.display = '';
                    } else {
                        row.style.display = 'none';
                    }
                });

                // Update Pagination Panel visibility
                if (matchedRows.length === 0 || totalPages <= 1) {
                    pagPanel.classList.add('hidden');
                    pagPanel.classList.remove('flex');
                } else {
                    pagPanel.classList.remove('hidden');
                    pagPanel.classList.add('flex');
                }

                // Update info text
                const actualEnd = Math.min(end, matchedRows.length);
                const infoSpan = document.getElementById('historyPaginationInfo');
                if (infoSpan) {
                    if (matchedRows.length > 0) {
                        infoSpan.innerText = `Hiển thị \${start + 1}-\${actualEnd} trong \${matchedRows.length} đơn đặt sân`;
                    } else {
                        infoSpan.innerText = `Không tìm thấy đơn đặt sân nào`;
                    }
                }

                renderButtons(totalPages);
            }

            function renderButtons(totalPages) {
                const btnContainer = document.getElementById('historyPaginationBtns');
                if (!btnContainer) return;
                btnContainer.innerHTML = '';

                if (totalPages <= 1) return;

                // Left arrow button
                const prevBtn = document.createElement('button');
                prevBtn.type = 'button';
                prevBtn.className = 'px-2 py-1 rounded hover:bg-slate-100 text-slate-400 disabled:opacity-40 flex items-center justify-center transition-colors';
                prevBtn.disabled = currentPage === 1;
                prevBtn.innerHTML = '<span class="material-symbols-outlined text-[14px]">chevron_left</span>';
                prevBtn.onclick = () => {
                    currentPage--;
                    applyFilters(false);
                };
                btnContainer.appendChild(prevBtn);

                // Page number buttons
                for (let i = 1; i <= totalPages; i++) {
                    const btn = document.createElement('button');
                    btn.type = 'button';
                    btn.innerText = i;
                    if (i === currentPage) {
                        btn.className = 'px-2.5 py-1 rounded bg-slate-900 text-white font-semibold transition-all';
                    } else {
                        btn.className = 'px-2.5 py-1 rounded hover:bg-slate-100 text-slate-650 transition-colors';
                    }
                    btn.onclick = () => {
                        currentPage = i;
                        applyFilters(false);
                    };
                    btnContainer.appendChild(btn);
                }

                // Right arrow button
                const nextBtn = document.createElement('button');
                nextBtn.type = 'button';
                nextBtn.className = 'px-2 py-1 rounded hover:bg-slate-100 text-slate-400 disabled:opacity-40 flex items-center justify-center transition-colors';
                nextBtn.disabled = currentPage === totalPages;
                nextBtn.innerHTML = '<span class="material-symbols-outlined text-[14px]">chevron_right</span>';
                nextBtn.onclick = () => {
                    currentPage++;
                    applyFilters(false);
                };
                btnContainer.appendChild(nextBtn);
            }

            if (searchInput) {
                searchInput.addEventListener('input', () => applyFilters(true));
            }

            statusChips.forEach(chip => {
                chip.addEventListener('click', () => {
                    statusChips.forEach(c => c.classList.remove('is-active'));
                    chip.classList.add('is-active');
                    activeStatus = chip.getAttribute('data-status-filter');
                    applyFilters(true);
                });
            });

            applyFilters(true);
        });
    </script>

    <!-- CUSTOMER SERVICE BOOKING MODAL -->
    <div id="customerServiceModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[60] hidden flex items-center justify-center opacity-0 transition-opacity duration-300 overflow-y-auto py-10 px-4">
        <div class="bg-white w-full max-w-2xl rounded-3xl shadow-2xl overflow-hidden transform scale-95 transition-all duration-300 relative my-auto">
            <div class="bg-gradient-to-r from-[#111111] to-[#e3000f] px-6 py-4 flex items-center justify-between text-white">
                <h3 class="font-bold text-lg flex items-center gap-2">
                    <span class="material-symbols-outlined">coffee</span> Đặt thêm Dịch vụ / Nước uống
                </h3>
                <button onclick="closeCustomerServiceModal()" class="text-white/80 hover:text-white transition-colors p-1">
                    <span class="material-symbols-outlined">close</span>
                </button>
            </div>

            <div class="p-6 md:p-8 max-h-[70vh] overflow-y-auto">
                <form id="customer-service-form" action="${pageContext.request.contextPath}/customer/dat-dich-vu" method="post" class="space-y-6">
                    <input type="hidden" name="datSanId" id="customer-service-datsan-id">

                    <div id="customer-service-loading" class="text-center py-10 text-slate-500">
                        <span class="material-symbols-outlined animate-spin text-[32px] text-red-600 mb-2">sync</span>
                        <p class="text-sm font-medium">Đang tải danh sách dịch vụ...</p>
                    </div>

                    <div id="customer-service-container" class="hidden space-y-4">
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4" id="customer-products-grid">
                            <!-- Populated dynamically via JS -->
                        </div>
                    </div>

                    <div class="pt-6 border-t border-slate-100 flex justify-between items-center">
                        <div>
                            <span class="text-xs font-bold text-slate-400 uppercase block">Tổng tiền dịch vụ thêm</span>
                            <span class="text-xl font-bold text-red-600" id="customer-service-total">0 đ</span>
                        </div>
                        <div class="flex gap-3">
                            <button type="button" onclick="closeCustomerServiceModal()" class="px-6 py-3 rounded-xl font-bold text-slate-600 bg-slate-100 hover:bg-slate-200 transition-colors">
                                Hủy
                            </button>
                            <button type="submit" class="px-8 py-3 rounded-xl font-bold text-white bg-[#e3000f] hover:bg-[#c2000d] transition-all shadow-md hover:shadow-red-600/20 active:scale-95 duration-200">
                                Xác nhận đặt
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- CANCEL BOOKING MODAL -->
    <div id="cancelBookingModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[60] hidden flex items-center justify-center opacity-0 transition-opacity duration-300 overflow-y-auto py-10 px-4">
        <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md scale-95 transition-transform duration-300">
            <div class="bg-red-600 rounded-t-2xl px-6 py-4 flex items-center justify-between">
                <h3 class="text-white font-bold text-sm">Xác nhận hủy đặt sân</h3>
                <button onclick="closeCancelBookingModal()" class="text-white/80 hover:text-white transition-colors p-1">
                    <span class="material-symbols-outlined text-[20px]">close</span>
                </button>
            </div>
            <form id="cancelBookingForm" action="${pageContext.request.contextPath}/customer/huy-dat-san" method="post">
                <input type="hidden" name="id" id="cancelBookingDatSanId" value="">
                <div class="p-6 space-y-4">
                    <p class="text-sm text-slate-600">Bạn có chắc chắn muốn hủy yêu cầu đặt sân này không?</p>
                    <div id="cancelBookingLateWarning" class="hidden bg-amber-50 border border-amber-200 rounded-xl p-3 text-[12px] text-amber-800 font-semibold leading-snug">
                        Bạn vẫn có thể hủy, nhưng đây là hủy sát giờ và sẽ ảnh hưởng điểm uy tín của bạn.
                    </div>
                    <div>
                        <label class="block text-[11px] font-bold text-slate-500 uppercase tracking-wide mb-1.5">Lý do hủy (không bắt buộc)</label>
                        <textarea name="reason" rows="2" maxlength="255" placeholder="Ví dụ: bận việc đột xuất..." class="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-red-200"></textarea>
                    </div>
                </div>
                <div class="px-6 pb-6 flex items-center justify-end gap-3">
                    <button type="button" onclick="closeCancelBookingModal()" class="px-5 py-2.5 rounded-xl font-bold text-slate-600 bg-slate-100 hover:bg-slate-200 transition-colors text-sm">
                        Đóng
                    </button>
                    <button type="submit" class="px-5 py-2.5 rounded-xl font-bold text-white bg-red-600 hover:bg-red-700 transition-colors text-sm">
                        Xác nhận hủy
                    </button>
                </div>
            </form>
        </div>
    </div>

    <script>
        let customerProducts = [];
        let customerOrdered = [];

        function openCustomerServiceModal(datSanId) {
            document.getElementById("customer-service-datsan-id").value = datSanId;

            const modal = document.getElementById("customerServiceModal");
            const loading = document.getElementById("customer-service-loading");
            const container = document.getElementById("customer-service-container");
            const grid = document.getElementById("customer-products-grid");

            modal.classList.remove("hidden");
            modal.classList.add("flex");
            loading.classList.remove("hidden");
            container.classList.add("hidden");

            setTimeout(() => {
                modal.classList.remove("opacity-0");
                modal.querySelector(".bg-white").classList.remove("scale-95");
            }, 10);

            // Fetch data
            fetch(`${pageContext.request.contextPath}/customer/dat-dich-vu?datSanId=${datSanId}`)
                .then(res => res.json())
                .then(data => {
                    customerProducts = data.products || [];
                    customerOrdered = data.ordered || [];

                    loading.classList.add("hidden");
                    container.classList.remove("hidden");

                    grid.innerHTML = "";
                    if (customerProducts.length === 0) {
                        grid.innerHTML = `<div class="col-span-2 text-center text-slate-400 py-8 italic">Cơ sở này hiện không có sản phẩm/dịch vụ nào đang kinh doanh.</div>`;
                        return;
                    }

                    customerProducts.forEach(prod => {
                        const ord = customerOrdered.find(o => o.SanPhamID === prod.SanPhamID);
                        const qty = ord ? ord.SoLuong : 0;

                        const itemHtml = `
                            <div class="p-4 bg-slate-50 border border-slate-100 rounded-2xl flex items-center justify-between shadow-sm">
                                <div class="flex-grow min-w-0 pr-4">
                                    <h4 class="font-bold text-slate-800 text-sm truncate">${prod.TenSanPham}</h4>
                                    <p class="text-xs text-slate-500 mt-0.5">${prod.DonGia.toLocaleString('vi-VN')} đ / ${prod.DonViTinh || 'cái'}</p>
                                    <p class="text-[10px] text-slate-400 italic mt-0.5 truncate">${prod.MoTa || 'Sản phẩm phục vụ tại sân'}</p>
                                    <p class="text-[10px] text-slate-500 font-semibold mt-1">Còn lại: ${prod.SoLuongTon} ${prod.DonViTinh || 'cái'}</p>
                                </div>
                                <div class="flex items-center gap-2 shrink-0">
                                    <input type="hidden" name="productId" value="${prod.SanPhamID}">
                                    <button type="button" onclick="adjustCustomerQty(${prod.SanPhamID}, -1)" class="w-8 h-8 rounded-lg bg-slate-200 hover:bg-slate-300 text-slate-700 font-bold flex items-center justify-center transition-colors select-none">-</button>
                                    <input type="number" name="quantity" id="cust-qty-${prod.SanPhamID}" value="${qty}" min="0" max="${prod.SoLuongTon}" class="w-12 text-center bg-white border border-slate-200 rounded-lg py-1 text-sm font-bold" readonly>
                                    <button type="button" onclick="adjustCustomerQty(${prod.SanPhamID}, 1)" class="w-8 h-8 rounded-lg bg-slate-200 hover:bg-slate-300 text-slate-700 font-bold flex items-center justify-center transition-colors select-none">+</button>
                                </div>
                            </div>
                        `;
                        grid.insertAdjacentHTML("beforeend", itemHtml);
                    });

                    recalculateCustomerTotal();
                })
                .catch(err => {
                    grid.innerHTML = `<div class="col-span-2 text-center text-red-500 py-8 italic">Có lỗi xảy ra khi tải dữ liệu: ${err.message}</div>`;
                    loading.classList.add("hidden");
                    container.classList.remove("hidden");
                });
        }

        function adjustCustomerQty(spId, delta) {
            const input = document.getElementById(`cust-qty-${spId}`);
            if (!input) return;

            const prod = customerProducts.find(p => p.SanPhamID === spId);
            if (!prod) return;

            let val = parseInt(input.value) || 0;
            val += delta;

            if (val < 0) val = 0;
            if (val > prod.SoLuongTon) {
                alert(`Không thể chọn vượt quá số lượng tồn kho (${prod.SoLuongTon})`);
                val = prod.SoLuongTon;
            }

            input.value = val;
            recalculateCustomerTotal();
        }

        function recalculateCustomerTotal() {
            let total = 0;
            customerProducts.forEach(prod => {
                const input = document.getElementById(`cust-qty-${prod.SanPhamID}`);
                const qty = input ? (parseInt(input.value) || 0) : 0;
                total += qty * prod.DonGia;
            });
            document.getElementById("customer-service-total").textContent = total.toLocaleString('vi-VN') + " đ";
        }

        function closeCustomerServiceModal() {
            const modal = document.getElementById("customerServiceModal");
            modal.classList.add("opacity-0");
            modal.querySelector(".bg-white").classList.add("scale-95");
            setTimeout(() => {
                modal.classList.add("hidden");
                modal.classList.remove("flex");
            }, 300);
        }

        function openCancelBookingModal(datSanId, ngayDatStr, gioBatDauStr) {
            document.getElementById("cancelBookingDatSanId").value = datSanId;

            // Cảnh báo hủy sát giờ chỉ là gợi ý hiển thị phía client — quyết định EARLY/LATE
            // chính thức và việc trừ điểm luôn do server (BookingCancellationService) quyết định.
            var warningEl = document.getElementById("cancelBookingLateWarning");
            try {
                var bookingStart = new Date(ngayDatStr + "T" + gioBatDauStr);
                var hoursUntilStart = (bookingStart.getTime() - Date.now()) / (1000 * 60 * 60);
                warningEl.classList.toggle("hidden", hoursUntilStart > 6);
            } catch (e) {
                warningEl.classList.add("hidden");
            }

            var modal = document.getElementById("cancelBookingModal");
            modal.classList.remove("hidden");
            modal.classList.add("flex");
            requestAnimationFrame(function () {
                modal.classList.remove("opacity-0");
                modal.querySelector(".bg-white").classList.remove("scale-95");
            });
        }

        function closeCancelBookingModal() {
            var modal = document.getElementById("cancelBookingModal");
            modal.classList.add("opacity-0");
            modal.querySelector(".bg-white").classList.add("scale-95");
            setTimeout(function () {
                modal.classList.add("hidden");
                modal.classList.remove("flex");
            }, 300);
        }
    </script>

    <jsp:include page="/customer/common/urgent-opponent-modal.jsp" />
    <jsp:include page="/customer/common/bottom-nav.jsp" />
</body>
</html>
