<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="vi" class="scroll-smooth">
<head>
    <title>${san.tenSan} - V-SPORT</title>
    <jsp:include page="/common/head.jsp" />
    <jsp:include page="/customer/common/vsport-theme.jsp" />
    <style>
        .material-symbols-outlined {
            font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
        }
        .material-symbols-outlined.filled {
            font-variation-settings: 'FILL' 1, 'wght' 400, 'GRAD' 0, 'opsz' 24;
        }
        #tl-bar {
            position: relative;
            height: 44px;
            border-radius: 8px;
            background: var(--vs-cyan-50, #F0FCFE);
            border: 1.5px solid var(--vs-cyan-100, #DDF8FC);
            cursor: crosshair;
            user-select: none;
            overflow: visible;
        }
        .tl-drag-handle {
            position: absolute;
            top: 50%;
            transform: translate(-50%, -50%);
            width: 22px;
            height: 22px;
            background: white;
            border: 2.5px solid var(--vs-primary-600, #1677D2);
            border-radius: 50%;
            cursor: ew-resize;
            z-index: 3;
            box-shadow: 0 1px 4px rgba(0,0,0,.2);
            touch-action: none;
            transition: transform 0.1s;
        }
        .tl-drag-handle:hover {
            transform: translate(-50%, -50%) scale(1.2);
        }
    </style>
</head>
<body class="bg-[#f7f9fb] text-[#191c1e] font-sans antialiased min-h-screen flex flex-col">

    <jsp:include page="/customer/common/vsport-header.jsp" />

    <main class="flex-grow pt-[80px] pb-24 lg:pb-16">
        <div class="w-full max-w-7xl mx-auto px-4 md:px-8 lg:px-12 py-6 md:py-8">

            <!-- Breadcrumbs -->
            <div class="flex flex-wrap items-center gap-1.5 text-[#3d4a3d] text-xs font-semibold mb-5">
                <a href="${pageContext.request.contextPath}/customer/dat-san" class="hover:text-[#1677D2] transition-colors whitespace-nowrap">Tìm Sân</a>
                <span class="material-symbols-outlined text-[14px]">chevron_right</span>
                <a href="${pageContext.request.contextPath}/customer/dat-san" class="hover:text-[#1677D2] transition-colors whitespace-nowrap">Danh sách sân</a>
                <span class="material-symbols-outlined text-[14px]">chevron_right</span>
                <span class="text-[#191c1e] font-bold truncate max-w-[160px] sm:max-w-none">${san.tenSan}</span>
            </div>

            <!-- Hero Gallery Bento -->
            <section class="grid grid-cols-1 md:grid-cols-4 md:grid-rows-2 gap-2 md:gap-3 h-[240px] md:h-[340px] mb-8 rounded-xl overflow-hidden">
                <div class="md:col-span-3 md:row-span-2 relative group cursor-pointer">
                    <img src="${not empty san.hinhAnh ? san.hinhAnh : 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?q=80&w=1400'}"
                         alt="${san.tenSan}"
                         class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105">
                    <div class="absolute inset-0 bg-black/10 group-hover:bg-transparent transition-colors"></div>
                    <div class="absolute top-4 left-4">
                        <span class="px-3 py-1.5 rounded-full text-xs font-extrabold uppercase tracking-wider shadow backdrop-blur-md flex items-center gap-1.5
                              ${san.trangThai == 'Sẵn sàng' ? 'text-white' : 'bg-amber-500/90 text-white'}"
                              style="${san.trangThai == 'Sẵn sàng' ? 'background-color: rgba(22,163,106,0.9);' : ''}">
                            <span class="w-1.5 h-1.5 rounded-full bg-white animate-pulse"></span>
                            ${san.trangThai == 'Sẵn sàng' ? 'Trống sân' : 'Đang dùng'}
                        </span>
                    </div>
                    <button class="absolute bottom-4 right-4 bg-white/90 backdrop-blur-sm px-4 py-2 rounded-full text-xs font-semibold flex items-center gap-1.5 hover:bg-white transition-colors shadow-sm text-[#191c1e]">
                        <span class="material-symbols-outlined text-[16px]">photo_library</span>
                        Xem tất cả ảnh
                    </button>
                </div>
                <div class="hidden md:block relative overflow-hidden group cursor-pointer">
                    <img src="${not empty san.hinhAnh ? san.hinhAnh : 'https://images.unsplash.com/photo-1544698310-74ea9d1c8258?q=80&w=600'}"
                         alt="${san.tenSan} - ảnh 2"
                         class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110 brightness-90">
                    <div class="absolute inset-0 bg-black/10 group-hover:bg-transparent transition-colors"></div>
                </div>
                <div class="hidden md:block relative overflow-hidden group cursor-pointer">
                    <img src="https://images.unsplash.com/photo-1528972042015-f4b8a57c5c3c?q=80&w=600"
                         alt="${san.tenSan} - ảnh 3"
                         class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110 brightness-90">
                    <div class="absolute inset-0 bg-black/10 group-hover:bg-transparent transition-colors"></div>
                </div>
            </section>

            <!-- Main Content — info first on mobile, booking widget second -->
            <div class="flex flex-col lg:flex-row gap-6 lg:gap-12">

                <!-- INFO COLUMN — full width sau khi xóa booking widget -->
                <div class="w-full flex flex-col gap-8 lg:gap-10">

                    <!-- Header Info -->
                    <div>
                        <h1 class="text-xl sm:text-2xl md:text-3xl font-bold text-[#191c1e] leading-tight mb-3">${san.tenSan}</h1>
                        <div class="flex flex-wrap items-center gap-x-3 gap-y-1.5 text-[#3d4a3d] text-sm font-medium mb-4">
                            <div class="flex items-center gap-1">
                                <span class="material-symbols-outlined text-[16px] text-[#1677D2] filled">star</span>
                                <span class="text-[#6d7b6c] text-xs sm:text-sm">${coSo.tenCoSo}</span>
                            </div>
                            <span class="text-[#bccbb9] hidden sm:inline">•</span>
                            <div class="flex items-center gap-1 w-full sm:w-auto">
                                <span class="material-symbols-outlined text-[16px]">location_on</span>
                                <span class="text-xs sm:text-sm truncate">${coSo.diaChi}</span>
                            </div>
                        </div>
                        <div class="flex flex-wrap gap-1.5">
                            <span class="px-2.5 py-1 bg-[#1677D2]/10 text-[#185A9D] rounded font-semibold text-[11px] sm:text-xs">${tenMon}</span>
                            <span class="px-2.5 py-1 bg-[#1677D2]/10 text-[#185A9D] rounded font-semibold text-[11px] sm:text-xs">${loai.tenLoai}</span>
                            <span class="px-2.5 py-1 bg-[#1677D2]/10 text-[#185A9D] rounded font-semibold text-[11px] sm:text-xs">
                                ${coSo.gioMoCua != null ? coSo.gioMoCua : '06:00'} – ${coSo.gioDongCua != null ? coSo.gioDongCua : '23:00'}
                            </span>
                            <span class="px-2.5 py-1 bg-[#1677D2]/10 text-[#185A9D] rounded font-semibold text-[11px] sm:text-xs">${totalSimilarCourts} sân tương tự</span>
                        </div>
                    </div>

                    <hr class="border-[#e6e8ea]">

                    <!-- Description -->
                    <div>
                        <h2 class="text-lg sm:text-xl font-semibold text-[#191c1e] mb-3">Giới thiệu sân</h2>
                        <p class="text-sm sm:text-base text-[#3d4a3d] leading-relaxed">
                            ${not empty san.moTa ? san.moTa : 'Hệ thống sân đấu tiêu chuẩn với mặt sân cao cấp, hệ thống thoát nước tối ưu đảm bảo sân luôn khô ráo và bám tốt. Sân được trang bị hệ thống chiếu sáng LED chuyên nghiệp phục vụ thi đấu vào ban đêm. Thích hợp cho cả tập luyện phong trào và tổ chức các giải đấu quy mô vừa.'}
                        </p>
                    </div>

                    <hr class="border-[#e6e8ea]">

                    <!-- Amenities -->
                    <div>
                        <h2 class="text-lg sm:text-xl font-semibold text-[#191c1e] mb-4 sm:mb-6">Tiện ích</h2>
                        <div class="grid grid-cols-2 md:grid-cols-3 gap-y-4 sm:gap-y-6 gap-x-3 sm:gap-x-4">
                            <div class="flex items-center gap-3 text-[#3d4a3d]">
                                <span class="material-symbols-outlined text-[24px] text-[#1677D2]">wifi</span>
                                <span class="text-base">Wifi miễn phí</span>
                            </div>
                            <div class="flex items-center gap-3 text-[#3d4a3d]">
                                <span class="material-symbols-outlined text-[24px] text-[#1677D2]">local_parking</span>
                                <span class="text-base">Bãi đỗ xe</span>
                            </div>
                            <div class="flex items-center gap-3 text-[#3d4a3d]">
                                <span class="material-symbols-outlined text-[24px] text-[#1677D2]">lightbulb</span>
                                <span class="text-base">Đèn chiếu sáng</span>
                            </div>
                            <div class="flex items-center gap-3 text-[#3d4a3d]">
                                <span class="material-symbols-outlined text-[24px] text-[#1677D2]">shower</span>
                                <span class="text-base">Phòng tắm</span>
                            </div>
                            <div class="flex items-center gap-3 text-[#3d4a3d]">
                                <span class="material-symbols-outlined text-[24px] text-[#1677D2]">local_drink</span>
                                <span class="text-base">Nước uống</span>
                            </div>
                            <div class="flex items-center gap-3 text-[#3d4a3d]">
                                <span class="material-symbols-outlined text-[24px] text-[#1677D2]">security</span>
                                <span class="text-base">Bảo vệ 24/7</span>
                            </div>
                        </div>
                    </div>

                    <hr class="border-[#e6e8ea]">

                    <!-- Location / Map -->
                    <div>
                        <h2 class="text-lg sm:text-xl font-semibold text-[#191c1e] mb-2">Vị trí</h2>
                        <p class="text-base text-[#3d4a3d] mb-4 flex items-center gap-1.5">
                            <span class="material-symbols-outlined text-[18px] text-[#18C8E8]">location_on</span>
                            ${coSo.diaChi}
                        </p>
                        <div class="w-full h-44 sm:h-56 bg-[#eceef0] rounded-xl overflow-hidden border border-[#e0e3e5] shadow-sm">
                            <iframe
                                src="https://maps.google.com/maps?q=${coSo.diaChi}&output=embed&z=15"
                                class="w-full h-full border-0"
                                allowfullscreen=""
                                loading="lazy"
                                referrerpolicy="no-referrer-when-downgrade"
                                title="Bản đồ ${coSo.tenCoSo}">
                            </iframe>
                        </div>
                    </div>

                </div>

            </div><!-- end main content -->

        </div><!-- end container -->

        <!-- OTHER COURTS SECTION -->
        <div class="w-full max-w-7xl mx-auto px-4 md:px-8 lg:px-12 mt-10 md:mt-16">
            <div class="bg-white p-4 sm:p-6 md:p-8 rounded-xl border border-[#e0e3e5] shadow-sm">
                <h2 class="text-lg sm:text-xl font-bold text-[#191c1e] mb-4 sm:mb-6 flex items-center gap-2">
                    <span class="material-symbols-outlined text-[22px] text-[#1677D2]">sports_tennis</span>
                    Các sân đấu khác dành cho bạn
                </h2>
                <!-- Horizontal scroll on mobile, grid on larger -->
                <div class="flex gap-4 overflow-x-auto pb-2 sm:pb-0 sm:grid sm:grid-cols-2 lg:grid-cols-4 sm:gap-5 -mx-4 px-4 sm:mx-0 sm:px-0 snap-x snap-mandatory">
                    <c:forEach var="os" items="${otherSans}" varStatus="loop">
                        <c:if test="${loop.index < 4}">
                            <c:set var="osCoSoName" value="Cơ Sở" />
                            <c:forEach var="cs" items="${dsCoSo}">
                                <c:if test="${cs.coSoID == os.coSoID}">
                                    <c:set var="osCoSoName" value="${cs.tenCoSo}" />
                                </c:if>
                            </c:forEach>
                            <c:set var="osTypeName" value="Chưa phân loại" />
                            <c:set var="osPrice" value="0" />
                            <c:set var="osSportId" value="0" />
                            <c:forEach var="ls" items="${dsLoaiSan}">
                                <c:if test="${ls.loaiSanID == os.loaiSanID}">
                                    <c:set var="osTypeName" value="${ls.tenLoai}" />
                                    <c:set var="osPrice" value="${ls.giaKhongDen}" />
                                    <c:set var="osSportId" value="${ls.monTheThaoID}" />
                                </c:if>
                            </c:forEach>
                            <c:set var="osSportName" value="Khác" />
                            <c:forEach var="m" items="${dsMon}">
                                <c:if test="${m.monTheThaoID == osSportId}">
                                    <c:set var="osSportName" value="${m.tenMon}" />
                                </c:if>
                            </c:forEach>

                            <div class="bg-[#f7f9fb] border border-[#e0e3e5] rounded-xl overflow-hidden flex flex-col transition-all duration-300 hover:shadow-md hover:-translate-y-1 shrink-0 w-[220px] sm:w-auto snap-start">
                                <a href="${pageContext.request.contextPath}/customer/chi-tiet-san?id=${os.sanID}" class="block group hover:no-underline">
                                    <div class="relative h-[130px] overflow-hidden bg-[#eceef0]">
                                        <img src="${not empty os.hinhAnh ? os.hinhAnh : 'https://images.unsplash.com/photo-1544698310-74ea9d1c8258?q=80&w=600'}"
                                             alt="${os.tenSan}"
                                             class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105">
                                        <span class="absolute top-2 right-2 px-2 py-0.5 rounded bg-black/60 text-white text-[9px] font-bold uppercase tracking-wider backdrop-blur-sm">${osSportName}</span>
                                    </div>
                                    <div class="p-4 space-y-1.5">
                                        <h4 class="font-bold text-[#191c1e] text-sm truncate group-hover:text-[#1677D2] transition-colors">${os.tenSan}</h4>
                                        <p class="text-xs text-[#6d7b6c] flex items-center gap-1">
                                            <span class="material-symbols-outlined text-[13px]">location_on</span>
                                            ${osCoSoName}
                                        </p>
                                        <p class="text-[11px] text-[#6d7b6c] italic truncate">${osTypeName}</p>
                                    </div>
                                </a>
                                <div class="px-4 pb-4 pt-0 flex items-center justify-between border-t border-[#e6e8ea] mt-auto">
                                    <span class="text-sm font-bold text-[#1677D2]"><fmt:formatNumber value="${osPrice}" pattern="#,##0"/> đ<span class="text-[10px] font-normal text-[#6d7b6c]">/h</span></span>
                                    <a href="${pageContext.request.contextPath}/customer/chi-tiet-san?id=${os.sanID}"
                                       class="px-3 py-1.5 bg-[#1677D2] text-white rounded-lg text-[11px] font-semibold hover:bg-[#185A9D] hover:no-underline transition-all">
                                        Xem sân
                                    </a>
                                </div>
                            </div>
                        </c:if>
                    </c:forEach>
                </div>
            </div>
        </div>

    </main>

    <!-- Sticky bottom CTA -->
    <div class="fixed bottom-0 left-0 right-0 bg-white/95 backdrop-blur-sm border-t border-[#e0e3e5] px-4 py-3 flex items-center justify-between z-40 shadow-[0_-2px_12px_rgba(0,0,0,0.08)]">
        <div class="flex flex-col">
            <span class="text-base font-bold text-[#191c1e]"><fmt:formatNumber value="${loai.giaKhongDen}" pattern="#,##0"/> đ<span class="text-xs font-normal text-[#6d7b6c]">/giờ</span></span>
            <span class="text-[10px] text-[#6d7b6c]">${san.trangThai == 'Sẵn sàng' ? 'Còn trống' : 'Đang dùng'}</span>
        </div>
        <a href="${pageContext.request.contextPath}/customer/dat-lich-truc-quan?coSoId=${san.coSoID}&sanId=${san.sanID}"
           class="px-5 py-2.5 bg-[#FF8A24] text-white font-semibold text-sm rounded-xl hover:bg-[#F97316] active:scale-95 transition-all shadow-sm flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[16px]">sports_soccer</span>
            Đặt Sân
        </a>
    </div>

    <jsp:include page="/common/footer.jsp" />

    <script>
        const branchOpenTime  = "${coSo.gioMoCua  != null ? coSo.gioMoCua  : '06:00'}";
        const branchCloseTime = "${coSo.gioDongCua != null ? coSo.gioDongCua : '23:00'}";
        const pricePerHour    = parseFloat("${loai.giaKhongDen != null ? loai.giaKhongDen : 0}");

        const activeBookings = [
            <c:forEach var="b" items="${activeBookings}">
                <c:if test="${b.sanId == san.sanID && b.trangThai != 'Đã hủy'}">
                    { id: ${b.datSanId}, date: "${b.ngayDat}", start: "${b.gioBatDau}", end: "${b.gioKetThuc}", status: "${b.trangThai}" },
                </c:if>
            </c:forEach>
        ];

        // ── Constants ──────────────────────────────────────────────────
        const openMin  = timeToMinutes(branchOpenTime);
        const closeMin = timeToMinutes(branchCloseTime);

        // ── Date state ─────────────────────────────────────────────────
        const todayBase = new Date();
        todayBase.setHours(0, 0, 0, 0);
        const todayStr = fmtDateStr(todayBase);

        let currentDate = new Date(todayBase);

        // ── Time-picker state ──────────────────────────────────────────
        let selectedStartMin = null;
        let selectedEndMin   = null;

        // ── Timeline drag state ────────────────────────────────────────
        let tlDragging = false;
        let tlDragSide = null; // 'start' | 'end'

        // ── Helpers ────────────────────────────────────────────────────
        function timeToMinutes(t) {
            const p = t.split(":");
            return parseInt(p[0], 10) * 60 + parseInt(p[1], 10);
        }

        function minToStr(m) {
            return String(Math.floor(m / 60)).padStart(2, "0") + ":" + String(m % 60).padStart(2, "0");
        }

        function formatDuration(mins) {
            const h = Math.floor(mins / 60), m = mins % 60;
            return (h > 0 ? h + " tiếng " : "") + (m > 0 ? m + " phút" : "");
        }

        function fmtDateStr(d) {
            return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
        }

        function fmtDateDisplay(d) {
            const days = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];
            return days[d.getDay()] + ", " + String(d.getDate()).padStart(2, "0") + "/" +
                   String(d.getMonth() + 1).padStart(2, "0") + "/" + d.getFullYear();
        }

        // ── Date navigation ────────────────────────────────────────────
        function updateDateUI() {
            document.getElementById("date-display").textContent = fmtDateDisplay(currentDate);
            document.getElementById("ngayDat").value = fmtDateStr(currentDate);
            document.getElementById("prev-day-btn").disabled = fmtDateStr(currentDate) === todayStr;
        }

        function prevDay() {
            const d = new Date(currentDate);
            d.setDate(d.getDate() - 1);
            if (fmtDateStr(d) < todayStr) return;
            currentDate = d;
            resetSelection();
            updateDateUI();
            renderTimeline();
        }

        function nextDay() {
            const d = new Date(currentDate);
            d.setDate(d.getDate() + 1);
            currentDate = d;
            resetSelection();
            updateDateUI();
            renderTimeline();
        }

        // ── Selection ──────────────────────────────────────────────────
        function resetSelection() {
            selectedStartMin = null;
            selectedEndMin   = null;
            document.getElementById("gioBatDau").value = "";
            document.getElementById("gioKetThuc").value = "";
            renderTimeline();
            updatePriceBreakdown();
            checkSchedule();
        }

        function commitSelection() {
            document.getElementById("gioBatDau").value = selectedStartMin !== null ? minToStr(selectedStartMin) : "";
            document.getElementById("gioKetThuc").value = selectedEndMin !== null ? minToStr(selectedEndMin) : "";
        }

        // ── Timeline: coordinate ↔ minute ─────────────────────────────
        function minToPct(min) {
            return ((min - openMin) / (closeMin - openMin)) * 100;
        }

        function pctToMin(pct) {
            const raw = openMin + Math.max(0, Math.min(1, pct)) * (closeMin - openMin);
            return Math.round(raw / 30) * 30;
        }

        function getBarPct(e) {
            const bar  = document.getElementById("tl-bar");
            const rect = bar.getBoundingClientRect();
            const clientX = e.touches ? e.touches[0].clientX : e.clientX;
            return (clientX - rect.left) / rect.width;
        }

        function getConflicts() {
            return activeBookings.filter(b => b.date === fmtDateStr(currentDate));
        }

        function isMinBooked(min) {
            return getConflicts().some(b => min >= timeToMinutes(b.start) && min < timeToMinutes(b.end));
        }

        function isMinPast(min) {
            if (fmtDateStr(currentDate) !== todayStr) return false;
            const n = new Date();
            return min < n.getHours() * 60 + n.getMinutes();
        }

        function hasRangeConflict(startM, endM) {
            return getConflicts().some(b => {
                const bs = timeToMinutes(b.start), be = timeToMinutes(b.end);
                return startM < be && endM > bs;
            });
        }

        // ── Timeline render ────────────────────────────────────────────
        function renderTimeline() {
            const bar = document.getElementById("tl-bar");
            bar.innerHTML = "";

            // Past overlay (today only)
            if (fmtDateStr(currentDate) === todayStr) {
                const n = new Date();
                const nowMin = n.getHours() * 60 + n.getMinutes();
                if (nowMin > openMin) {
                    const w = minToPct(Math.min(nowMin, closeMin));
                    const el = mkDiv("position:absolute;top:0;bottom:0;left:0;width:" + w + "%;background:rgba(0,0,0,0.07);border-radius:6px 0 0 6px;pointer-events:none;");
                    bar.appendChild(el);
                }
            }

            // Booked segments
            getConflicts().forEach(function(b) {
                const bs   = timeToMinutes(b.start), be = timeToMinutes(b.end);
                const left = minToPct(bs);
                const w    = minToPct(be) - left;
                const el   = mkDiv("position:absolute;top:2px;bottom:2px;left:" + left + "%;width:" + w + "%;background:#fecaca;border-radius:4px;pointer-events:none;");
                el.title   = "Đã đặt: " + b.start + " – " + b.end;
                bar.appendChild(el);
            });

            // Hour tick marks
            for (var m = openMin; m <= closeMin; m += 60) {
                const tick = mkDiv("position:absolute;top:0;bottom:0;left:" + minToPct(m) + "%;width:1px;background:rgba(0,0,0,0.06);pointer-events:none;");
                bar.appendChild(tick);
            }

            // Selection or pending-start marker
            if (selectedStartMin !== null && selectedEndMin !== null) {
                const left = minToPct(selectedStartMin);
                const w    = minToPct(selectedEndMin) - left;

                const sel = mkDiv("position:absolute;top:0;bottom:0;left:" + left + "%;width:" + w + "%;background:#1677D2;border-radius:6px;opacity:0.85;pointer-events:none;");
                bar.appendChild(sel);

                // Drag handles
                [["start", left], ["end", left + w]].forEach(function(pair) {
                    const h = document.createElement("div");
                    h.className    = "tl-drag-handle";
                    h.style.left   = pair[1] + "%";
                    h.dataset.side = pair[0];
                    bar.appendChild(h);
                });

            } else if (selectedStartMin !== null) {
                // Pending-start: show vertical marker + tooltip
                const left = minToPct(selectedStartMin);

                const marker = mkDiv("position:absolute;top:0;bottom:0;left:" + left + "%;width:3px;background:#1677D2;border-radius:2px;transform:translateX(-50%);pointer-events:none;");
                bar.appendChild(marker);

                const tip = mkDiv("position:absolute;bottom:calc(100% + 5px);left:" + left + "%;transform:translateX(-50%);background:#1677D2;color:white;font-size:10px;padding:2px 7px;border-radius:4px;white-space:nowrap;pointer-events:none;");
                tip.textContent = minToStr(selectedStartMin);
                bar.appendChild(tip);
            }

            updateHint();
            updateSelectionDisplay();
        }

        function mkDiv(css) {
            const d = document.createElement("div");
            d.style.cssText = css;
            return d;
        }

        function updateHint() {
            const hint = document.getElementById("tl-hint");
            if (selectedStartMin === null) {
                hint.textContent = "Nhấn vào thanh để chọn giờ bắt đầu";
            } else if (selectedEndMin === null) {
                hint.textContent = "Nhấn tiếp để chọn giờ kết thúc";
            } else {
                hint.textContent = "Kéo hai đầu để điều chỉnh";
            }
        }

        function updateSelectionDisplay() {
            const disp = document.getElementById("tl-selection-display");
            if (selectedStartMin !== null && selectedEndMin !== null) {
                const dur = selectedEndMin - selectedStartMin;
                document.getElementById("tl-sel-text").textContent =
                    minToStr(selectedStartMin) + " – " + minToStr(selectedEndMin) + " · " + formatDuration(dur);
                disp.classList.remove("hidden");
            } else {
                disp.classList.add("hidden");
            }
        }

        // ── Timeline interaction ───────────────────────────────────────
        function onBarPointerDown(e) {
            // If clicking on a drag handle, start handle drag
            if (e.target.classList.contains("tl-drag-handle")) {
                tlDragSide  = e.target.dataset.side;
                tlDragging  = true;
                if (e.cancelable) e.preventDefault();
                return;
            }

            const clickedMin = pctToMin(getBarPct(e));

            // Ignore clicks outside valid range or on blocked slots
            if (clickedMin < openMin || clickedMin >= closeMin) return;
            if (isMinBooked(clickedMin) || isMinPast(clickedMin)) return;

            if (selectedStartMin === null || selectedEndMin !== null) {
                // New selection: set start only
                selectedStartMin = clickedMin;
                selectedEndMin   = null;
            } else {
                // Second click: set end
                if (clickedMin <= selectedStartMin) {
                    // Clicked at or before start → move start
                    selectedStartMin = clickedMin;
                } else {
                    // Clamp to first booked slot after start
                    let end = clickedMin;
                    getConflicts().forEach(b => {
                        const bs = timeToMinutes(b.start);
                        if (bs > selectedStartMin && bs < end) end = bs;
                    });
                    selectedEndMin = end;
                }
            }

            commitSelection();
            renderTimeline();
            updatePriceBreakdown();
            checkSchedule();
            if (e.cancelable) e.preventDefault();
        }

        function onDocPointerMove(e) {
            if (!tlDragging) return;
            const newMin = Math.max(openMin, Math.min(closeMin, pctToMin(getBarPct(e))));

            if (tlDragSide === "start") {
                if (selectedEndMin !== null && newMin < selectedEndMin - 30 &&
                    !hasRangeConflict(newMin, selectedEndMin) && !isMinPast(newMin)) {
                    selectedStartMin = newMin;
                }
            } else if (tlDragSide === "end") {
                if (newMin > selectedStartMin + 30 &&
                    !hasRangeConflict(selectedStartMin, newMin)) {
                    selectedEndMin = newMin;
                }
            }

            commitSelection();
            renderTimeline();
            updatePriceBreakdown();
            if (e.cancelable) e.preventDefault();
        }

        function onDocPointerUp() {
            if (!tlDragging) return;
            tlDragging = false;
            tlDragSide = null;
            checkSchedule();
        }

        // ── Hour labels ────────────────────────────────────────────────
        function renderTlLabels() {
            const container = document.getElementById("tl-labels");
            container.innerHTML = "";
            const step = window.innerWidth < 480 ? 120 : window.innerWidth < 640 ? 90 : 60;
            for (let m = openMin; m <= closeMin; m += step) {
                const span = document.createElement("span");
                span.textContent = minToStr(m);
                container.appendChild(span);
            }
        }
        window.addEventListener("resize", renderTlLabels);

        // ── Price breakdown ────────────────────────────────────────────
        function updatePriceBreakdown() {
            const breakdown = document.getElementById("price-breakdown");
            if (selectedStartMin === null || selectedEndMin === null || !pricePerHour) {
                breakdown.classList.add("hidden");
                breakdown.classList.remove("flex");
                return;
            }
            const hours = (selectedEndMin - selectedStartMin) / 60;
            const total = Math.round(pricePerHour * hours);
            document.getElementById("price-line-desc").textContent =
                pricePerHour.toLocaleString("vi-VN") + " đ × " +
                (hours % 1 === 0 ? hours : hours.toFixed(1)) + " giờ";
            document.getElementById("price-line-amount").textContent = total.toLocaleString("vi-VN") + " đ";
            document.getElementById("price-total").textContent       = total.toLocaleString("vi-VN") + " đ";
            breakdown.classList.remove("hidden");
            breakdown.classList.add("flex");
        }

        // ── Overlap validation ─────────────────────────────────────────
        function checkSchedule() {
            const btnSubmit  = document.getElementById("btn-submit-booking");
            const warningBox = document.getElementById("overlap-warning");

            if (selectedStartMin === null || selectedEndMin === null) {
                if (btnSubmit) btnSubmit.disabled = true;
                warningBox.classList.add("hidden");
                return;
            }

            if (hasRangeConflict(selectedStartMin, selectedEndMin)) {
                warningBox.classList.remove("hidden");
                if (btnSubmit) btnSubmit.disabled = true;
            } else {
                warningBox.classList.add("hidden");
                if (btnSubmit) btnSubmit.disabled = false;
            }
        }

        // ── Payment method toggle ──────────────────────────────────────
        function changePayMethod(method) {
            const activeClass   = "pay-opt border-2 border-[#1677D2] bg-[#1677D2]/10 rounded-lg p-2.5 flex items-center justify-center cursor-pointer font-semibold text-xs text-[#1677D2] active:scale-95 transition-all";
            const inactiveClass = "pay-opt border-2 border-[#e0e3e5] rounded-lg p-2.5 flex items-center justify-center cursor-pointer font-semibold text-xs text-[#6d7b6c] hover:border-[#bccbb9] active:scale-95 transition-all";
            document.getElementById("lbl-opt-sau").className   = method === "sau"   ? activeClass : inactiveClass;
            document.getElementById("lbl-opt-payos").className = method === "payos" ? activeClass : inactiveClass;
        }

        // ── Init ───────────────────────────────────────────────────────
        updateDateUI();
        renderTlLabels();
        renderTimeline();

        const tlBar = document.getElementById("tl-bar");
        tlBar.addEventListener("mousedown",  onBarPointerDown);
        tlBar.addEventListener("touchstart", onBarPointerDown, { passive: false });
        document.addEventListener("mousemove",  onDocPointerMove);
        document.addEventListener("mouseup",    onDocPointerUp);
        document.addEventListener("touchmove",  onDocPointerMove, { passive: false });
        document.addEventListener("touchend",   onDocPointerUp);
    </script>
<jsp:include page="/customer/common/bottom-nav.jsp" />
</body>
</html>
