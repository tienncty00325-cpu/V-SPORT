<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%--
    Focused booking flow — bước "Xác nhận đặt sân".
    Được forward từ POST /customer/dat-lich-truc-quan/xac-nhan (server đã re-check
    availability + tính giá bằng CourtPricingService). CTA cuối submit về contract
    cũ POST /customer/dat-san (sanId/ngayDat/gioBatDau/gioKetThuc/paymentMethod/ghiChu)
    — DatSanServlet re-validate + PayOS/COD như hiện tại, không viết lại.
--%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Xác nhận đặt sân - V-SPORT</title>
    <jsp:include page="/common/xtra-head.jsp" />
    <style>
        [hidden] { display: none !important; }
        html, body { background: var(--background); color: var(--navy); font-family: 'Outfit', sans-serif; }
        body { padding-bottom: 110px !important; }

        .xn-header {
            position: sticky; top: 0; z-index: 40;
            background: var(--navy); color: #fff;
        }
        .xn-header-inner {
            display: flex; align-items: center; gap: 10px;
            padding: 10px 14px; min-height: 56px; max-width: 860px; margin: 0 auto;
        }
        .xn-back {
            width: 38px; height: 38px; flex-shrink: 0;
            display: inline-flex; align-items: center; justify-content: center;
            border-radius: 999px; background: rgba(255,255,255,.08); color: #fff; border: none; cursor: pointer;
            transition: background-color 120ms ease; text-decoration: none;
        }
        .xn-back:hover { background: rgba(255,255,255,.16); }
        .xn-back:active { transform: translateY(1px); }
        .xn-title { font-size: 16px; font-weight: 800; margin: 0; flex: 1; }
        .xn-progress { display: none; font-size: 11.5px; color: #b6c2d4; font-weight: 600; }
        @media (min-width: 640px) { .xn-progress { display: inline; } }
        .xn-progress b { color: var(--primary); font-weight: 800; }

        .xn-shell { max-width: 860px; margin: 0 auto; padding: 14px 14px 0; }
        .xn-card {
            background: var(--surface); border: 1px solid var(--border);
            border-radius: 14px; padding: 16px; margin-bottom: 12px;
        }
        .xn-card h2 {
            font-size: 12px; font-weight: 800; color: var(--muted-text);
            text-transform: uppercase; letter-spacing: .07em; margin: 0 0 10px;
            display: flex; align-items: center; gap: 7px;
        }
        .xn-card h2 svg { color: var(--primary); }
        .xn-facility-name { font-size: 16px; font-weight: 800; color: var(--navy); }
        .xn-facility-addr { font-size: 12.5px; color: var(--muted-text); margin-top: 3px; }
        .xn-chip {
            display: inline-flex; align-items: center; padding: 3px 10px; border-radius: 999px;
            background: rgba(1,226,129,0.1); color: var(--primary);
            font-size: 11px; font-weight: 800; margin-top: 8px; margin-right: 6px;
        }
        .xn-row { display: flex; justify-content: space-between; gap: 12px; padding: 6px 0; font-size: 13.5px; }
        .xn-row .k { color: var(--muted-text); font-weight: 600; }
        .xn-row .v { font-weight: 700; text-align: right; }
        .xn-row.total { border-top: 1px dashed var(--border); margin-top: 6px; padding-top: 10px; }
        .xn-row.total .k { font-weight: 800; color: var(--navy); font-size: 14px; }
        .xn-row.total .v { font-weight: 800; font-size: 17px; color: var(--navy); }
        .xn-promo-empty { font-size: 12.5px; color: var(--muted-text); font-weight: 600; }

        .xn-input, .xn-textarea {
            width: 100%; padding: 10px 12px; min-height: 42px;
            background: #fff; border: 1px solid var(--border); border-radius: 10px;
            font-size: 13.5px; color: var(--navy); font-family: inherit;
        }
        .xn-input[readonly] { background: #f6f9fc; color: var(--muted-text); }
        .xn-textarea { min-height: 74px; resize: vertical; }
        .xn-textarea:focus { outline: none; border-color: var(--primary); box-shadow: 0 0 0 3px rgba(1,226,129,.35); }
        .xn-label { display: block; font-size: 11.5px; font-weight: 800; color: var(--muted-text); margin: 10px 0 5px; text-transform: uppercase; letter-spacing: .05em; }

        /* Payment method cards — không animation hover, chỉ đổi viền; press lún nhẹ */
        .xn-pay-options { display: grid; grid-template-columns: 1fr; gap: 8px; }
        @media (min-width: 560px) { .xn-pay-options { grid-template-columns: 1fr 1fr; } }
        .xn-pay-card {
            display: flex; align-items: flex-start; gap: 10px; padding: 13px 14px;
            background: #fff; border: 1.5px solid var(--border); border-radius: 12px;
            cursor: pointer;
            transform: none;
            transition: background-color 120ms ease, border-color 120ms ease, box-shadow 80ms ease, transform 80ms ease;
        }
        .xn-pay-card:hover { border-color: var(--primary); transform: none; }
        .xn-pay-card:active { transform: translateY(2px) scale(0.985); box-shadow: inset 0 3px 9px rgba(7,26,47,.14); }
        .xn-pay-card.is-selected { border-color: var(--primary); background: rgba(1,226,129,0.05); }
        .xn-pay-card input { margin-top: 3px; accent-color: var(--primary); }
        .xn-pay-name { font-size: 13.5px; font-weight: 800; }
        .xn-pay-desc { font-size: 12px; color: var(--muted-text); margin-top: 2px; line-height: 1.45; }
        .xn-pay-card:focus-within { outline: 3px solid rgba(1,226,129,.35); outline-offset: 2px; }

        .xn-notes { font-size: 12px; color: var(--muted-text); line-height: 1.6; }
        .xn-notes li { margin: 2px 0; }

        /* Sticky CTA bar */
        .xn-ctabar {
            position: fixed; left: 0; right: 0; bottom: 0; z-index: 40;
            background: var(--navy);
            box-shadow: 0 -10px 30px rgba(7,26,47,.28);
            padding: 10px 14px calc(10px + env(safe-area-inset-bottom, 0px));
        }
        .xn-ctabar-inner { max-width: 860px; margin: 0 auto; display: flex; align-items: center; gap: 14px; }
        .xn-ctabar-total { color: #fff; }
        .xn-ctabar-total .lbl { font-size: 10px; color: #b6c2d4; font-weight: 700; text-transform: uppercase; letter-spacing: .08em; }
        .xn-ctabar-total .val { font-size: 19px; font-weight: 800; line-height: 1.15; }
        .xn-cta {
            flex: 1; display: inline-flex; align-items: center; justify-content: center; gap: 8px;
            height: 56px; border-radius: 12px; border: none; cursor: pointer;
            background: var(--primary); color: #fff; font-weight: 800; font-size: 14.5px;
            letter-spacing: .04em; text-transform: uppercase;
            transition: background-color 120ms ease, box-shadow 80ms ease, transform 80ms ease;
        }
        .xn-cta:hover:not(:disabled) { background: var(--primary-hover); }
        .xn-cta:active:not(:disabled) { transform: translateY(2px) scale(0.985); box-shadow: inset 0 3px 9px rgba(7,26,47,.3); }
        .xn-cta:disabled { background: #3a4d63; color: #8a9bb0; cursor: not-allowed; }
        .xn-cta .spinner {
            width: 16px; height: 16px; border-radius: 50%;
            border: 2.5px solid rgba(255,255,255,.35); border-top-color: #fff;
            animation: xnSpin .8s linear infinite;
        }
        @keyframes xnSpin { to { transform: rotate(360deg); } }

        /* Full-screen step loading */
        .xn-step-loading {
            position: fixed; inset: 0; z-index: 2000;
            background: var(--navy);
            display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 18px; color: #fff;
        }
        .xn-step-loading-brand { font-size: 26px; font-weight: 800; letter-spacing: .12em; font-family: 'Outfit', sans-serif; }
        .xn-step-loading-brand span { color: var(--primary); }
        .xn-step-loading-ring {
            width: 44px; height: 44px; border-radius: 50%;
            border: 4px solid rgba(255,255,255,.16); border-top-color: var(--primary);
            animation: xnSpin .9s linear infinite;
        }
        .xn-step-loading p { font-size: 14px; font-weight: 600; color: #cbd5e1; margin: 0; }
        @media (prefers-reduced-motion: reduce) {
            .xn-pay-card:active, .xn-cta:active:not(:disabled) { transform: none; }
            .xn-step-loading-ring, .xn-cta .spinner { animation-duration: 2.4s; }
        }
    </style>
</head>
<body>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<div class="xn-header">
    <div class="xn-header-inner">
        <a class="xn-back" href="${backUrl}" aria-label="Quay lại chọn lịch">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
        </a>
        <h1 class="xn-title">Xác nhận đặt sân</h1>
        <span class="xn-progress">Chọn lịch → <b>Xác nhận</b> → Thanh toán</span>
    </div>
</div>

<div class="xn-shell">

    <%-- A. Thông tin cơ sở --%>
    <div class="xn-card">
        <h2>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/></svg>
            Thông tin sân
        </h2>
        <div class="xn-facility-name">${fn:escapeXml(coSo.tenCoSo)}</div>
        <c:if test="${not empty coSo.diaChi}">
            <div class="xn-facility-addr">${fn:escapeXml(coSo.diaChi)}</div>
        </c:if>
        <div>
            <span class="xn-chip">${fn:escapeXml(san.tenSan)}</span>
            <c:if test="${not empty loai.tenLoai}"><span class="xn-chip">${fn:escapeXml(loai.tenLoai)}</span></c:if>
            <c:if test="${not empty tenMon}"><span class="xn-chip">${fn:escapeXml(tenMon)}</span></c:if>
        </div>
    </div>

    <%-- B. Thông tin lịch đặt + giá --%>
    <div class="xn-card">
        <h2>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/></svg>
            Thông tin lịch đặt
        </h2>
        <div class="xn-row"><span class="k">Ngày</span><span class="v">${ngayDat}</span></div>
        <div class="xn-row"><span class="k">Khung giờ</span><span class="v">${gioBatDau} – ${gioKetThuc}</span></div>
        <div class="xn-row">
            <span class="k">Tổng thời lượng</span>
            <span class="v">
                <c:set var="durH" value="${durationMinutes div 60}" />
                <c:set var="durM" value="${durationMinutes mod 60}" />
                <c:if test="${durH gt 0}"><fmt:formatNumber value="${durH}" maxFractionDigits="0"/> giờ</c:if>
                <c:if test="${durM gt 0}"> ${durM} phút</c:if>
            </span>
        </div>
        <c:forEach var="seg" items="${priceSegments}">
            <div class="xn-row">
                <span class="k">${seg.start} – ${seg.end} · ${seg.withLight ? 'Giá có đèn' : 'Giá không đèn'}
                    (<fmt:formatNumber value="${seg.hourlyRate}" pattern="#,##0"/> đ/giờ)</span>
                <span class="v"><fmt:formatNumber value="${seg.amount}" pattern="#,##0"/> đ</span>
            </div>
        </c:forEach>
        <div class="xn-row total"><span class="k">Tổng tiền</span><span class="v"><fmt:formatNumber value="${totalAmount}" pattern="#,##0"/> đ</span></div>
    </div>

    <%-- C. Ưu đãi (hệ thống chưa có luồng áp mã cho booking này) --%>
    <div class="xn-card">
        <h2>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 12v10H4V12"/><path d="M2 7h20v5H2z"/><path d="M12 22V7"/><path d="M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z"/><path d="M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"/></svg>
            Ưu đãi
        </h2>
        <p class="xn-promo-empty">Chưa áp dụng ưu đãi</p>
    </div>

    <%-- D. Thông tin người đặt --%>
    <form id="xnForm" action="${ctx}/customer/dat-san" method="post">
        <input type="hidden" name="sanId" value="${san.sanID}" />
        <input type="hidden" name="ngayDat" value="${ngayDat}" />
        <input type="hidden" name="gioBatDau" value="${gioBatDau}" />
        <input type="hidden" name="gioKetThuc" value="${gioKetThuc}" />
        <input type="hidden" name="paymentMethod" id="xnPaymentMethod" value="sau" />

        <div class="xn-card">
            <h2>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M20 21a8 8 0 0 0-16 0"/></svg>
                Thông tin người đặt
            </h2>
            <label class="xn-label" for="xnName">Họ tên</label>
            <input class="xn-input" id="xnName" type="text" readonly
                   value="${fn:escapeXml(not empty sessionScope.user.fullName ? sessionScope.user.fullName : sessionScope.user.username)}" />
            <c:if test="${not empty sessionScope.user.phoneNumber}">
                <label class="xn-label" for="xnPhone">Số điện thoại</label>
                <input class="xn-input" id="xnPhone" type="text" readonly value="${fn:escapeXml(sessionScope.user.phoneNumber)}" />
            </c:if>
            <label class="xn-label" for="xnGhiChu">Ghi chú cho chủ sân</label>
            <textarea class="xn-textarea" id="xnGhiChu" name="ghiChu" maxlength="255" placeholder="Nhập ghi chú (không bắt buộc)"></textarea>
        </div>

        <%-- E. Phương thức thanh toán --%>
        <div class="xn-card">
            <h2>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="20" height="14" x="2" y="5" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/></svg>
                Phương thức thanh toán
            </h2>
            <div class="xn-pay-options" role="radiogroup" aria-label="Phương thức thanh toán">
                <label class="xn-pay-card" id="xnPayCardPayos">
                    <input type="radio" name="payChoice" value="payos" />
                    <span>
                        <span class="xn-pay-name">Thanh toán trả trước</span>
                        <span class="xn-pay-desc" style="display:block;">Quét QR PayOS ngay. Sân được giữ chỗ ${bookingHoldMinutes} phút để hoàn tất thanh toán.</span>
                    </span>
                </label>
                <label class="xn-pay-card is-selected" id="xnPayCardSau">
                    <input type="radio" name="payChoice" value="sau" checked />
                    <span>
                        <span class="xn-pay-name">Thanh toán tại sân</span>
                        <span class="xn-pay-desc" style="display:block;">Thanh toán trực tiếp tại cơ sở. Đơn cần cơ sở xác nhận trước giờ chơi.</span>
                    </span>
                </label>
            </div>
        </div>

        <%-- F. Lưu ý (tối đa 3 dòng) --%>
        <div class="xn-card">
            <ul class="xn-notes" style="margin: 0; padding-left: 18px;">
                <li>Hủy miễn phí khi hủy trước giờ bắt đầu ít nhất ${lateCancelHours} tiếng.</li>
                <li>Trả trước qua PayOS: giữ chỗ ${bookingHoldMinutes} phút chờ thanh toán.</li>
                <li>Khung giờ chỉ được giữ chính thức sau khi bạn hoàn tất bước này.</li>
            </ul>
        </div>
    </form>
</div>

<%-- Sticky CTA --%>
<div class="xn-ctabar">
    <div class="xn-ctabar-inner">
        <div class="xn-ctabar-total">
            <div class="lbl">Tổng thanh toán</div>
            <div class="val"><fmt:formatNumber value="${totalAmount}" pattern="#,##0"/> đ</div>
        </div>
        <button type="submit" form="xnForm" class="xn-cta" id="xnSubmitBtn">
            <span id="xnSubmitLabel">Xác nhận đặt sân</span>
        </button>
    </div>
</div>

<div class="xn-step-loading" id="xnStepLoading" hidden role="status" aria-live="polite" aria-busy="true">
    <div class="xn-step-loading-brand">V-<span>SPORT</span></div>
    <div class="xn-step-loading-ring" aria-hidden="true"></div>
    <p id="xnStepLoadingText">Đang xử lý...</p>
</div>

<script>
(function () {
    const form = document.getElementById('xnForm');
    const hiddenMethod = document.getElementById('xnPaymentMethod');
    const btn = document.getElementById('xnSubmitBtn');
    const label = document.getElementById('xnSubmitLabel');
    const cardPayos = document.getElementById('xnPayCardPayos');
    const cardSau = document.getElementById('xnPayCardSau');
    let submitting = false;

    function syncMethod() {
        const chosen = document.querySelector('input[name="payChoice"]:checked');
        const val = chosen ? chosen.value : 'sau';
        hiddenMethod.value = val;
        cardPayos.classList.toggle('is-selected', val === 'payos');
        cardSau.classList.toggle('is-selected', val === 'sau');
        label.textContent = val === 'payos' ? 'Thanh toán & đặt sân' : 'Xác nhận đặt sân';
    }
    document.querySelectorAll('input[name="payChoice"]').forEach(function (r) {
        r.addEventListener('change', syncMethod);
    });
    syncMethod();

    let loadingTimer = null;
    function showStepLoading(text) {
        clearTimeout(loadingTimer);
        loadingTimer = setTimeout(function () {
            document.getElementById('xnStepLoadingText').textContent = text;
            document.getElementById('xnStepLoading').hidden = false;
        }, 150);
    }
    window.addEventListener('pageshow', function (e) {
        if (e.persisted) {
            clearTimeout(loadingTimer);
            document.getElementById('xnStepLoading').hidden = true;
            submitting = false;
            btn.disabled = false;
            syncMethod();
        }
    });

    form.addEventListener('submit', function (e) {
        if (submitting) { e.preventDefault(); return; }
        submitting = true;
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner" aria-hidden="true"></span><span>Đang xử lý...</span>';
        showStepLoading(hiddenMethod.value === 'payos' ? 'Đang chuẩn bị thanh toán...' : 'Đang xử lý...');
        // form submit thật → DatSanServlet re-validate trong transaction (UPDLOCK) + PayOS/COD flow cũ.
    });
})();
</script>

</body>
</html>
