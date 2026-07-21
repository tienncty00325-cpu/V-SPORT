<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="isManager" value="${sessionScope.user.roleId == 2}" />
<c:set var="themeBg" value="${isManager ? 'bg-purple-600' : 'bg-orange-600'}" />
<c:set var="themeBgHover" value="${isManager ? 'hover:bg-purple-700' : 'hover:bg-orange-700'}" />
<c:set var="themeTextMedium" value="${isManager ? 'text-purple-700' : 'text-orange-700'}" />
<c:set var="themeBorder" value="${isManager ? 'border-purple-200' : 'border-orange-200'}" />
<c:set var="themeBgLight" value="${isManager ? 'bg-purple-50' : 'bg-orange-50'}" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Hóa đơn ${invoice.invoiceCode} | V-SPORT</title>
    <jsp:include page="/staff/common/staff_head.jsp" />
    <style>
        body { background: #f8f9ff; }

        .toolbar-btn { white-space: nowrap; }

        .receipt-shell {
            background: #ffffff;
            border-radius: 16px;
            box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04), 0 1px 12px rgba(15, 23, 42, 0.03);
        }

        .receipt {
            width: 400px;
            max-width: 100%;
            margin: 0 auto;
            background: #ffffff;
            color: #1f2937;
            font-size: 13px;
            line-height: 1.55;
            padding: 20px 22px;
            box-sizing: border-box;
            word-break: break-word;
        }

        .receipt-row { display: flex; justify-content: space-between; gap: 10px; }
        .receipt-row + .receipt-row { margin-top: 4px; }
        .receipt-money { text-align: right; white-space: nowrap; font-variant-numeric: tabular-nums; }
        .receipt hr { border: none; border-top: 1px dashed #cbd5e1; margin: 13px 0; }
        .receipt .center { text-align: center; }
        .receipt .bold { font-weight: 700; }
        .receipt .muted { color: #6b7280; }
        .receipt .small { font-size: 11px; color: #6b7280; }
        .receipt .mono { font-variant-numeric: tabular-nums; }

        .receipt .total-row { font-size: 16px; font-weight: 800; }

        .receipt .section-label {
            font-size: 10.5px; font-weight: 800; color: #9ca3af;
            letter-spacing: .06em; text-transform: uppercase; margin-bottom: 6px;
        }
        .receipt .printed-at { text-align: right; font-size: 10px; color: #9ca3af; margin-top: 2px; }
        .receipt .subtotal-row { color: #4b5563; }

        .receipt table.dv-table { width: 100%; border-collapse: collapse; margin-top: 6px; }
        .receipt table.dv-table th {
            text-align: left; font-size: 11px; font-weight: 700; color: #6b7280;
            border-bottom: 1px solid #e5e7eb; padding-bottom: 5px;
        }
        .receipt table.dv-table th.qty, .receipt table.dv-table th.money { text-align: right; }
        .receipt table.dv-table td { padding: 5px 0; vertical-align: top; }
        .receipt table.dv-table td.qty, .receipt table.dv-table td.money {
            text-align: right; white-space: nowrap; font-variant-numeric: tabular-nums;
        }

        .segment-card {
            border: 1px solid #e5e7eb;
            border-radius: 10px;
            padding: 8px 10px;
            margin-top: 8px;
        }
        .segment-tag {
            display: inline-flex; align-items: center; gap: 3px;
            font-size: 10.5px; font-weight: 700; padding: 1px 8px; border-radius: 999px;
        }
        .segment-tag.light { background: #fef3c7; color: #92400e; }
        .segment-tag.no-light { background: #f4f4f5; color: #52525b; }

        .min-charge-note {
            font-size: 11px; color: #92400e; background: #fffbeb;
            border: 1px solid #fde68a; border-radius: 8px; padding: 6px 9px; margin-top: 6px;
        }

        @media print {
            .no-print { display: none !important; }
            body { margin: 0; background: #ffffff; }
            .receipt-shell { box-shadow: none !important; border: none !important; border-radius: 0 !important; padding: 0 !important; }
            .receipt { width: 80mm; max-width: 80mm; }
        }

        @page { size: 80mm auto; margin: 3mm; }
    </style>
</head>
<body class="min-h-screen py-8 px-4">

    <div class="no-print max-w-2xl mx-auto mb-5 flex flex-wrap items-center justify-between gap-2">
        <div class="flex flex-wrap items-center gap-2">
            <a href="${pageContext.request.contextPath}/staff/checkin"
               class="toolbar-btn px-4 py-2.5 rounded-lg border border-zinc-200 bg-white text-zinc-600 font-semibold text-sm hover:bg-zinc-50 transition-all">
                &larr; Quay lại Check-in
            </a>
            <a href="${invoice.invoiceManagementUrl}"
               class="toolbar-btn px-4 py-2.5 rounded-lg border ${themeBorder} ${themeBgLight} ${themeTextMedium} font-semibold text-sm hover:brightness-95 transition-all">
                Quản lý hóa đơn
            </a>
        </div>
        <div class="flex items-center gap-2">
            <button type="button" onclick="window.close()"
                    class="toolbar-btn px-4 py-2.5 rounded-lg border border-zinc-200 bg-white text-zinc-500 font-semibold text-sm hover:bg-zinc-50 transition-all">
                Đóng
            </button>
            <button type="button" onclick="window.print()"
                    class="toolbar-btn ${themeBg} ${themeBgHover} px-5 py-2.5 rounded-lg text-white font-semibold text-sm transition-all active:scale-95 flex items-center gap-1.5">
                <span class="material-symbols-outlined text-[18px]">print</span>
                In hóa đơn
            </button>
        </div>
    </div>

    <c:if test="${not empty invoice.splitHoaDonIds}">
        <div class="no-print max-w-2xl mx-auto mb-4 p-3 rounded-lg border border-amber-200 bg-amber-50 text-amber-800 text-xs">
            Hóa đơn này còn có
            <c:forEach var="sid" items="${invoice.splitHoaDonIds}" varStatus="st">
                <a class="font-bold underline" target="_blank"
                   href="${pageContext.request.contextPath}/staff/hoa-don/in?id=${sid}">hóa đơn tách dịch vụ #${sid}</a><c:if test="${!st.last}">, </c:if>
            </c:forEach>
            — vui lòng in riêng nếu cần.
        </div>
    </c:if>

    <div class="receipt-shell max-w-[440px] mx-auto">
        <div class="receipt" id="invoice-receipt">
            <!-- PHẦN ĐẦU -->
            <div class="center small" style="letter-spacing:.1em; color:#9ca3af; font-weight:700;">V-SPORT</div>
            <div class="center bold" style="font-size:16px; margin-top:2px;">${invoice.facilityName}</div>
            <c:if test="${not empty invoice.facilityAddress}">
                <div class="center small">${invoice.facilityAddress}</div>
            </c:if>
            <c:if test="${not empty invoice.facilityPhone}">
                <div class="center small">ĐT: ${invoice.facilityPhone}</div>
            </c:if>
            <div class="center bold ${themeTextMedium}" style="margin-top:10px; font-size:13.5px; letter-spacing:.02em;">
                ${invoice.split ? 'HÓA ĐƠN DỊCH VỤ (TÁCH)' : 'HÓA ĐƠN THANH TOÁN'}
            </div>
            <div class="printed-at">In lúc: <span id="printedAtNow">-</span></div>
            <hr/>

            <div class="section-label">Thông tin hóa đơn</div>
            <div class="receipt-row"><span class="muted">Mã hóa đơn:</span><span class="receipt-money bold mono">${invoice.invoiceCode}</span></div>
            <c:if test="${invoice.split && not empty invoice.parentHoaDonId}">
                <div class="receipt-row"><span class="muted">Tách từ HĐ:</span><span class="receipt-money mono">#${invoice.parentHoaDonId}</span></div>
            </c:if>
            <div class="receipt-row"><span class="muted">Ngày lập:</span><span class="receipt-money">${invoice.paidAtLabel}</span></div>
            <div class="receipt-row"><span class="muted">Thu ngân:</span><span class="receipt-money">${invoice.cashierName}</span></div>
            <div class="receipt-row"><span class="muted">PT thanh toán:</span><span class="receipt-money">${not empty invoice.paymentMethod ? invoice.paymentMethod : '-'}</span></div>
            <c:if test="${not empty invoice.transactionCode}">
                <div class="receipt-row"><span class="muted">Mã giao dịch:</span><span class="receipt-money mono">${invoice.transactionCode}</span></div>
            </c:if>
            <c:if test="${not empty invoice.confirmedByName}">
                <div class="receipt-row"><span class="muted">NV xác nhận:</span><span class="receipt-money">${invoice.confirmedByName}</span></div>
            </c:if>
            <c:if test="${not empty invoice.confirmedAtLabel}">
                <div class="receipt-row"><span class="muted">TG xác nhận:</span><span class="receipt-money">${invoice.confirmedAtLabel}</span></div>
            </c:if>
            <div class="receipt-row">
                <span class="muted">Trạng thái:</span>
                <span class="receipt-money bold" style="${invoice.paid ? 'color:#15803d' : 'color:#b45309'}">${invoice.paymentStatus}</span>
            </div>
            <hr/>

            <div class="section-label">Thông tin sân &amp; lịch chơi</div>
            <div class="receipt-row"><span class="muted">Sân:</span><span class="receipt-money">${invoice.courtName}</span></div>
            <div class="receipt-row"><span class="muted">Loại sân:</span><span class="receipt-money">${invoice.courtTypeName}</span></div>
            <div class="receipt-row"><span class="muted">Khách:</span><span class="receipt-money">${invoice.customerName}</span></div>
            <c:if test="${not empty invoice.customerPhone}">
                <div class="receipt-row"><span class="muted">SĐT khách:</span><span class="receipt-money mono">${invoice.customerPhone}</span></div>
            </c:if>
            <div class="receipt-row"><span class="muted">Chế độ:</span><span class="receipt-money">${invoice.playModeLabel}</span></div>
            <div class="receipt-row"><span class="muted">Bắt đầu:</span><span class="receipt-money">${invoice.actualStartLabel}</span></div>
            <div class="receipt-row"><span class="muted">Kết thúc:</span><span class="receipt-money">${invoice.actualEndLabel}<c:if test="${invoice.crossesMidnight}"> (hôm sau)</c:if></span></div>
            <div class="receipt-row"><span class="muted">Thời gian thực tế:</span><span class="receipt-money">${invoice.actualDurationLabel}</span></div>
            <div class="receipt-row"><span class="muted">Thời lượng tính phí:</span><span class="receipt-money bold">${invoice.chargedDurationLabel}</span></div>
            <c:if test="${invoice.minimumChargeApplied}">
                <div class="min-charge-note">Áp dụng thời lượng tính phí tối thiểu ${invoice.chargedDurationLabel}.</div>
            </c:if>

            <c:if test="${!invoice.split}">
                <c:forEach var="seg" items="${invoice.courtSegments}">
                    <div class="segment-card">
                        <div class="receipt-row">
                            <span class="segment-tag ${seg.rateType == 'WITH_LIGHT' ? 'light' : 'no-light'}">
                                <span class="material-symbols-outlined" style="font-size:12px;">${seg.rateType == 'WITH_LIGHT' ? 'bolt' : 'bedtime'}</span>
                                ${seg.rateLabel}
                            </span>
                            <span class="small">${seg.durationMinutes} phút</span>
                        </div>
                        <div class="receipt-row small" style="margin-top:4px;">
                            <span>${seg.startAt.toLocalTime()} - ${seg.endAt.toLocalTime()}</span>
                            <span><fmt:formatNumber value="${seg.hourlyRate}" maxFractionDigits="0"/> đ/giờ</span>
                        </div>
                        <div class="receipt-row bold" style="margin-top:4px;">
                            <span>Thành tiền đoạn</span>
                            <span><fmt:formatNumber value="${seg.amount}" maxFractionDigits="0"/> đ</span>
                        </div>
                    </div>
                </c:forEach>
                <div class="receipt-row" style="margin-top:10px;"><span class="muted">Thành tiền sân:</span><span class="receipt-money bold"><fmt:formatNumber value="${invoice.courtAmount}" type="number" maxFractionDigits="0"/> đ</span></div>
            </c:if>
            <hr/>

            <div class="section-label">Dịch vụ đi kèm</div>
            <c:choose>
                <c:when test="${not empty invoice.services}">
                    <table class="dv-table">
                        <thead>
                            <tr>
                                <th>Tên dịch vụ</th>
                                <th class="qty">SL</th>
                                <th class="money">Đơn giá</th>
                                <th class="money">T.Tiền</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="dv" items="${invoice.services}">
                                <tr>
                                    <td>${dv.name}</td>
                                    <td class="qty">${dv.quantity}</td>
                                    <td class="money"><fmt:formatNumber value="${dv.unitPrice}" type="number" maxFractionDigits="0"/></td>
                                    <td class="money"><fmt:formatNumber value="${dv.amount}" type="number" maxFractionDigits="0"/></td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </c:when>
                <c:otherwise>
                    <div class="small">Không có dịch vụ.</div>
                </c:otherwise>
            </c:choose>
            <hr/>

            <div class="section-label">Thanh toán</div>
            <c:if test="${!invoice.split}">
                <div class="receipt-row"><span class="muted">Tiền sân:</span><span class="receipt-money"><fmt:formatNumber value="${invoice.courtAmount}" type="number" maxFractionDigits="0"/> đ</span></div>
            </c:if>
            <div class="receipt-row"><span class="muted">Tiền dịch vụ:</span><span class="receipt-money"><fmt:formatNumber value="${invoice.serviceAmount}" type="number" maxFractionDigits="0"/> đ</span></div>
            <c:if test="${invoice.parkingFee > 0}">
                <div class="receipt-row"><span class="muted">Phí gửi xe:</span><span class="receipt-money"><fmt:formatNumber value="${invoice.parkingFee}" type="number" maxFractionDigits="0"/> đ</span></div>
            </c:if>
            <c:if test="${invoice.discountAmount > 0}">
                <c:set var="subtotalAmount" value="${(invoice.split ? 0 : invoice.courtAmount) + invoice.serviceAmount + invoice.parkingFee}" />
                <div class="receipt-row subtotal-row" style="margin-top:2px; padding-top:6px; border-top:1px dashed #e5e7eb;"><span>Tạm tính:</span><span class="receipt-money"><fmt:formatNumber value="${subtotalAmount}" type="number" maxFractionDigits="0"/> đ</span></div>
                <div class="receipt-row"><span class="muted">Giảm giá:</span><span class="receipt-money">-<fmt:formatNumber value="${invoice.discountAmount}" type="number" maxFractionDigits="0"/> đ</span></div>
            </c:if>
            <hr/>
            <div class="receipt-row total-row"><span>TỔNG THANH TOÁN:</span><span class="receipt-money ${themeTextMedium}"><fmt:formatNumber value="${invoice.totalAmount}" type="number" maxFractionDigits="0"/> đ</span></div>

            <hr/>
            <!-- PHẦN CUỐI -->
            <div class="center small" style="margin-top:10px;">Cảm ơn quý khách đã sử dụng dịch vụ V-SPORT.</div>
        </div>
    </div>

    <script>
        // Chỉ hiển thị thời điểm xem/in trên máy khách — không phải dữ liệu kế toán,
        // không lưu DB, không ảnh hưởng Ngày lập (invoice.paidAtLabel).
        (function () {
            var el = document.getElementById('printedAtNow');
            if (!el) return;
            var now = new Date();
            var pad = function (n) { return String(n).padStart(2, '0'); };
            el.textContent = pad(now.getHours()) + ':' + pad(now.getMinutes()) + ' ' +
                pad(now.getDate()) + '/' + pad(now.getMonth() + 1) + '/' + now.getFullYear();
        })();
    </script>
</body>
</html>
