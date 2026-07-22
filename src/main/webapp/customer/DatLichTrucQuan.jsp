<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%--
    Booking workspace — bước "Chọn lịch" (court × time timetable, bố cục ALO-style).
    KHÔNG include header.jsp / bottom-nav.jsp: trang này là workspace độc lập.
    Cấu trúc: header navy (back + tiêu đề + chọn ngày + legend) → dòng lưu ý
    → bảng lịch full-width (sticky court col + sticky time row) → footer cố định
    (Tổng giờ / Tổng tiền + nút TIẾP THEO lớn).
    Contract giữ nguyên:
      POST /customer/dat-lich-truc-quan/xac-nhan (coSoId, sanId, ngayDat, gioBatDau, gioKetThuc)
      GET  /customer/api/timetable-availability?coSoId&date
      GET  /customer/api/timetable-price?sanId&date&start&end
--%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Đặt lịch ngay trực quan - V-SPORT</title>
    <jsp:include page="/common/xtra-head.jsp" />
    <style>
        [hidden] { display: none !important; }
        :root {
            --ttv-slot-w: 52px;
            --ttv-row-h: 40px;
            --ttv-head-h: 30px;
            --ttv-court-col: 150px;
        }
        @media (max-width: 767px) {
            :root { --ttv-court-col: 122px; --ttv-slot-w: 46px; --ttv-row-h: 38px; }
        }
        html, body { background: var(--surface); color: var(--navy); font-family: 'Inter', 'Barlow', system-ui, sans-serif; }
        /* Workspace grid: header / lưu ý / TIMELINE (1fr) / footer. Không khoảng trắng thừa. */
        body {
            margin: 0;
            padding-bottom: 0 !important;
            height: 100dvh;
            display: grid;
            grid-template-rows: auto auto minmax(0, 1fr) auto;
            overflow: hidden;
        }

        /* ============ Header navy (compact, 2 tầng, cao ~110px) ============ */
        .ttv-header { background: var(--navy); color: var(--surface); }
        .ttv-header-top {
            display: grid; grid-template-columns: 1fr auto 1fr; align-items: center;
            gap: 10px; padding: 14px 12px 8px; min-height: 64px;
        }
        @media (min-width: 1024px) { .ttv-header-top { padding: 14px 20px 8px; } }
        .ttv-back {
            justify-self: start;
            width: 34px; height: 34px; flex-shrink: 0;
            display: inline-flex; align-items: center; justify-content: center;
            border-radius: 8px; background: transparent; color: var(--surface); border: none; cursor: pointer;
            transition: background-color 100ms ease;
        }
        .ttv-back:hover { background: rgba(255,255,255,.12); }
        .ttv-back:active { transform: translateY(1px) scale(0.99); }
        .ttv-title {
            font-family: 'Inter', 'Barlow', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            font-size: 15px; font-weight: 700; margin: 0; line-height: 1.25; text-align: center;
            letter-spacing: 0; text-transform: none; white-space: nowrap;
        }
        @media (min-width: 768px) { .ttv-title { font-size: 16px; } }
        .ttv-title small { display: block; font-size: 11px; font-weight: 500; color: #c5c9b0; opacity: .72; letter-spacing: 0; text-transform: none; }
        @media (min-width: 768px) { .ttv-title small { font-size: 12px; } }
        .ttv-date-group { justify-self: end; display: inline-flex; align-items: center; gap: 4px; }
        .ttv-icon-btn {
            display: inline-flex; align-items: center; justify-content: center;
            width: 30px; height: 30px; background: rgba(255,255,255,.1); border: none; border-radius: 7px;
            color: var(--surface); cursor: pointer; transition: background-color 100ms ease;
        }
        .ttv-icon-btn:hover { background: rgba(255,255,255,.2); }
        .ttv-icon-btn:active { transform: translateY(1px) scale(0.99); }
        .ttv-icon-btn:disabled { opacity: .35; cursor: not-allowed; }
        .ttv-date-input {
            padding: 4px 8px; height: 30px; background: var(--surface); border: none; border-radius: 7px;
            font-size: 14px; font-weight: 600; color: var(--navy);
            font-family: 'Inter', 'Barlow', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        }
        .ttv-date-input:focus { outline: none; box-shadow: 0 0 0 3px var(--vs-focus-ring, rgba(1,226,129,.35)); }

        /* Tầng dưới header: legend một hàng ngang. */
        .ttv-header-legend {
            display: flex; flex-wrap: nowrap; align-items: center; gap: 14px;
            padding: 6px 12px 12px; font-size: 11.5px;
            overflow-x: auto; scrollbar-width: none;
        }
        .ttv-header-legend::-webkit-scrollbar { display: none; }
        @media (min-width: 1024px) { .ttv-header-legend { padding: 6px 20px 12px; } }
        .ttv-legend-item {
            display: inline-flex; align-items: center; gap: 5px; color: #e0e3e5; font-weight: 600;
            font-family: 'Inter', 'Barlow', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            font-size: 13px; white-space: nowrap; flex-shrink: 0;
        }
        .ttv-legend-swatch { width: 13px; height: 13px; border-radius: 3px; border: 1px solid rgba(255,255,255,.4); flex-shrink: 0; }
        .ttv-legend-swatch.is-avail  { background: var(--surface); }
        .ttv-legend-swatch.is-select { background: var(--primary); border-color: var(--primary); }
        .ttv-legend-swatch.is-booked { background: #94a3b8; border-color: #94a3b8; }
        .ttv-legend-swatch.is-hold   { background: #fcd34d; border-color: #fcd34d; }
        .ttv-legend-swatch.is-locked { background: #e2e8f0; border-color: #e2e8f0; }

        /* ============ Dòng lưu ý ============ */
        .ttv-note {
            padding: 6px 14px; background: var(--background);
            border-bottom: 1px solid var(--vs-border, #e0e3e5);
            font-size: 11.5px; text-align: center; color: var(--vs-text-secondary, #486581); font-weight: 600;
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }
        .ttv-note b { color: var(--danger); font-weight: 800; }

        /* ============ Timetable — full-bleed, cuộn bên trong ============ */
        .ttv-tt-wrapper { display: flex; flex-direction: column; min-height: 0; min-width: 0; max-width: 100vw; background: var(--surface); }
        .ttv-tt-scroll {
            overflow: auto; flex: 1 1 auto; min-height: 160px;
            -webkit-overflow-scrolling: touch; overscroll-behavior: contain;
            /* head.jsp ẩn scrollbar toàn cục — bật lại ở đây để kéo ngang được. */
            scrollbar-width: thin; -ms-overflow-style: auto;
        }
        .ttv-tt-scroll::-webkit-scrollbar { display: block; width: 8px; height: 8px; }
        .ttv-tt-scroll::-webkit-scrollbar-thumb { background: #e0e3e5; border-radius: 4px; }
        .ttv-tt-scroll::-webkit-scrollbar-track { background: #f2f4f6; }
        .ttv-tt { display: grid; font-size: 12px; user-select: none; }
        .ttv-tt-head-cell {
            position: sticky; top: 0; z-index: 5; background: var(--background);
            border-bottom: 1px solid var(--vs-border, #e0e3e5); border-right: 1px solid #eceef0;
            display: flex; align-items: center; justify-content: center;
            font-weight: 800; font-size: 11px; color: var(--vs-text-secondary, #486581); height: var(--ttv-head-h);
            position: sticky;
        }
        .ttv-court-label {
            position: sticky; left: 0; z-index: 4; background: var(--surface);
            padding: 3px 8px; display: flex; flex-direction: column; justify-content: center;
            border-right: 2px solid var(--vs-border, #e0e3e5); border-bottom: 1px solid #eceef0;
            overflow: hidden; height: var(--ttv-row-h);
            box-shadow: 2px 0 6px -4px rgba(15,23,42,.24);
        }
        .ttv-court-label-head { background: var(--background); z-index: 6; height: var(--ttv-head-h); justify-content: center; font-weight: 800; font-size: 11px; color: var(--vs-text-secondary, #486581); border-bottom: 1px solid var(--vs-border, #e0e3e5); }
        .ttv-court-name {
            font-size: 12px; font-weight: 800; color: var(--navy); line-height: 1.2;
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }
        .ttv-court-price { font-size: 10px; color: var(--primary); font-weight: 700; line-height: 1.2; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .ttv-head-minor { font-size: 9.5px; font-weight: 600; color: #94a3b8; }
        .ttv-slot {
            background: var(--surface); border-right: 1px solid #eceef0; border-bottom: 1px solid #eceef0;
            display: flex; align-items: center; justify-content: center; cursor: pointer;
            height: var(--ttv-row-h); position: relative;
            transition: background-color 90ms ease;
        }
        /* Hover: chỉ đổi nền nhẹ, không chuyển động. */
        .ttv-slot:hover:not(.is-blocked):not(.is-selected) { background: var(--background); }
        /* Press: lún nhẹ. */
        .ttv-slot:active:not(.is-blocked) { transform: translateY(1px) scale(0.99); }
        .ttv-slot.is-selected { background: var(--primary); border-color: var(--primary-hover); color: var(--surface); }
        .ttv-slot.is-selected.is-selected-start { border-top-left-radius: 6px; border-bottom-left-radius: 6px; }
        .ttv-slot.is-selected.is-selected-end   { border-top-right-radius: 6px; border-bottom-right-radius: 6px; }
        .ttv-slot.is-hover { background: rgba(1,226,129,.14); }
        .ttv-slot.is-blocked { cursor: not-allowed; }
        .ttv-slot.is-past   { background: #EDF0F3; color: #9aa4b0; }
        .ttv-slot.is-booked { background: #94a3b8; color: var(--surface); }
        .ttv-slot.is-hold   { background: #fcd34d; color: #6b4d00; }
        /* Đơn CHỜ THANH TOÁN của CHÍNH khách đang xem — cam nhạt, bấm được để tiếp tục thanh toán. */
        .ttv-slot.is-hold_self { background: rgba(1,226,129,0.1); color: #8a4b12; cursor: pointer; box-shadow: inset 0 0 0 1.5px var(--primary); }
        .ttv-slot.is-hold_self:hover { background: #ffe6cf; }
        .ttv-slot.is-locked { background: #e2e8f0; color: #3f4750; }
        .ttv-slot:focus-visible { outline: 3px solid var(--vs-focus-ring, rgba(1,226,129,.35)); outline-offset: -3px; z-index: 2; }
        .ttv-slot.is-merged { padding: 0 6px; }
        .ttv-slot-run-label {
            font-size: 10.5px; font-weight: 800; white-space: nowrap;
            overflow: hidden; text-overflow: ellipsis; max-width: 100%;
        }
        /* Kẻ đậm hơn ở mốc mỗi giờ tròn. */
        .ttv-slot.is-hour-start, .ttv-tt-head-cell.is-hour-start { border-left: 1px solid #d6dee8; }
        .ttv-now-marker { position: absolute; top: 0; bottom: 0; width: 2px; background: var(--primary); pointer-events: none; z-index: 3; }
        .ttv-now-chip {
            position: absolute; top: 1px; left: 50%; transform: translateX(-50%);
            background: var(--primary); color: var(--surface);
            font-size: 9px; font-weight: 800; padding: 0 6px; border-radius: 999px;
            pointer-events: none; z-index: 7; white-space: nowrap;
        }
        .ttv-tt-empty { padding: 48px 24px; text-align: center; color: var(--vs-text-secondary, #486581); font-size: 13px; }
        .ttv-btn-ghost {
            display: inline-flex; align-items: center; justify-content: center; gap: 6px;
            padding: 7px 14px; min-height: 36px; background: var(--surface); border: 1px solid var(--vs-border, #e0e3e5); border-radius: 8px;
            color: var(--navy); font-size: 12.5px; font-weight: 700; cursor: pointer; text-decoration: none;
            transition: border-color 100ms ease, color 100ms ease;
        }
        .ttv-btn-ghost:hover { border-color: var(--primary); color: var(--primary); }
        .ttv-btn-ghost:active { transform: translateY(1px) scale(0.99); }

        /* ============ Footer cố định: Tổng giờ / Tổng tiền + CTA lớn ============ */
        .ttv-summary {
            background: var(--navy); color: var(--surface);
            box-shadow: 0 -8px 24px rgba(7,26,47,.24);
            padding: 8px 10px calc(10px + env(safe-area-inset-bottom, 0px));
        }
        .ttv-summary-row {
            display: flex; align-items: baseline; justify-content: space-between;
            gap: 12px; padding: 0 4px 8px; min-height: 24px;
        }
        .ttv-summary-stat { display: inline-flex; align-items: baseline; gap: 7px; min-width: 0; }
        .ttv-summary-stat span { font-size: 10.5px; color: #c5c9b0; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; }
        .ttv-summary-stat strong { font-size: 15px; font-weight: 800; color: var(--surface); white-space: nowrap; }
        .ttv-summary-stat.is-total strong { font-size: 18px; font-weight: 900; color: var(--primary); }
        .ttv-summary-sel { flex: 1 1 auto; min-width: 0; text-align: center; font-size: 11.5px; color: #b6c2d4; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        @media (max-width: 639px) { .ttv-summary-sel { display: none; } }
        .ttv-summary-cta {
            display: flex; align-items: center; justify-content: center; gap: 10px;
            width: 100%; min-height: 50px;
            border-radius: 9px; border: none; cursor: pointer;
            background: var(--primary); color: var(--surface); font-weight: 900; font-size: 15.5px;
            letter-spacing: .04em; text-transform: uppercase; font-family: inherit;
            transition: background-color 100ms ease, transform 90ms ease;
        }
        .ttv-summary-cta:hover:not(:disabled) { background: var(--primary-hover); }
        .ttv-summary-cta:active:not(:disabled) { transform: translateY(1px) scale(0.99); }
        .ttv-summary-cta:disabled { background: #5c6f88; color: #cdd8e4; cursor: not-allowed; opacity: 1; }
        .ttv-summary-cta:focus-visible { outline: 3px solid var(--vs-focus-ring, rgba(1,226,129,.35)); outline-offset: 2px; }
        .ttv-summary-cta .ttv-btn-spinner {
            width: 18px; height: 18px; border-radius: 50%;
            border: 2.5px solid rgba(255,255,255,.35); border-top-color: var(--surface);
            animation: ttvSpin .8s linear infinite;
        }
        @keyframes ttvSpin { to { transform: rotate(360deg); } }

        /* ============ Toast ============ */
        .ttv-inline-alert {
            position: fixed; left: 50%; bottom: 118px; transform: translateX(-50%);
            background: var(--navy); color: var(--surface); padding: 10px 16px; border-radius: 999px;
            font-size: 13px; font-weight: 700; box-shadow: 0 12px 30px rgba(0,0,0,.32);
            opacity: 0; visibility: hidden; transition: opacity .18s ease;
            z-index: 60; max-width: 92vw; text-align: center;
        }
        .ttv-inline-alert.is-open { opacity: 1; visibility: visible; }
        .ttv-inline-alert.is-danger { background: var(--danger); }
        .ttv-inline-alert.is-warn   { background: var(--vs-warning, #F4B740); color: #1f2937; }

        /* ============ Loading / skeleton / error / empty ============ */
        @keyframes ttvShim { 0% { background-position: 100% 50%; } 100% { background-position: 0 50%; } }
        .ttv-skel { background: linear-gradient(90deg, #eceef0 25%, #dfe6ec 37%, #eceef0 63%); background-size: 400% 100%; animation: ttvShim 1.4s ease infinite; border-radius: 6px; }
        .ttv-loading-box { padding: 16px; }
        .ttv-loading-box .row { height: 34px; margin-bottom: 6px; }
        .ttv-error { padding: 40px 24px; text-align: center; }
        .ttv-error p { color: var(--vs-text-secondary, #486581); font-weight: 600; margin-bottom: 12px; font-size: 13.5px; }
        .ttv-empty-facility { padding: 60px 24px; text-align: center; }
        .ttv-empty-facility h2 { font-size: 19px; font-weight: 800; margin-bottom: 8px; }
        .ttv-empty-facility p { color: var(--vs-text-secondary, #486581); margin-bottom: 16px; font-size: 13.5px; }

        /* ============ Full-screen step loading (Navy) ============ */
        .ttv-step-loading {
            position: fixed; inset: 0; z-index: 2000;
            background: var(--vs-primary-950, #000000);
            display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 18px; color: var(--surface);
        }
        .ttv-step-loading-brand { font-size: 26px; font-weight: 900; letter-spacing: .14em; font-family: 'Barlow Condensed', sans-serif; }
        .ttv-step-loading-brand span { color: var(--primary); }
        .ttv-step-loading-ring {
            width: 44px; height: 44px; border-radius: 50%;
            border: 4px solid rgba(255,255,255,.16); border-top-color: var(--primary);
            animation: ttvSpin .9s linear infinite;
        }
        .ttv-step-loading p { font-size: 14px; font-weight: 600; color: #cbd5e1; margin: 0; }

        @media (prefers-reduced-motion: reduce) {
            .ttv-skel { animation: none; }
            .ttv-step-loading-ring { animation-duration: 2.4s; }
            .ttv-slot:active:not(.is-blocked),
            .ttv-summary-cta:active:not(:disabled),
            .ttv-icon-btn:active, .ttv-back:active, .ttv-btn-ghost:active { transform: none; }
        }
    </style>
</head>
<body>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- ============ Header navy: back + tiêu đề + chọn ngày + legend ============ --%>
<div class="ttv-header">
    <div class="ttv-header-top">
        <button type="button" class="ttv-back" aria-label="Quay lại" onclick="ttvGoBack()">
            <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
        </button>
        <h1 class="ttv-title">
            Đặt lịch ngay trực quan
            <c:if test="${not empty coSo}"><small>${fn:escapeXml(coSo.tenCoSo)}</small></c:if>
        </h1>
        <div class="ttv-date-group">
            <c:if test="${not empty coSo}">
                <button type="button" class="ttv-icon-btn" id="ttvPrevDayBtn" aria-label="Ngày trước" onclick="ttvChangeDate(-1)">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>
                </button>
                <input type="date" id="ttvDateInput" class="ttv-date-input" onchange="ttvOnDateChange()" aria-label="Chọn ngày" />
                <button type="button" class="ttv-icon-btn" aria-label="Ngày sau" onclick="ttvChangeDate(1)">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 18 6-6-6-6"/></svg>
                </button>
            </c:if>
        </div>
    </div>
    <div class="ttv-header-legend" role="list" aria-label="Chú thích trạng thái">
        <span class="ttv-legend-item" role="listitem"><span class="ttv-legend-swatch is-avail"></span>Trống</span>
        <span class="ttv-legend-item" role="listitem"><span class="ttv-legend-swatch is-select"></span>Đang chọn</span>
        <span class="ttv-legend-item" role="listitem"><span class="ttv-legend-swatch is-booked"></span>Đã đặt</span>
        <span class="ttv-legend-item" role="listitem"><span class="ttv-legend-swatch is-hold"></span>Giữ chỗ</span>
        <span class="ttv-legend-item" role="listitem"><span class="ttv-legend-swatch is-locked"></span>Khóa / đã qua</span>
    </div>
</div>

<c:if test="${emptyState eq 'no_facility'}">
    <div class="ttv-empty-facility">
        <h2>Chưa có cơ sở nào khả dụng</h2>
        <p>Vui lòng quay lại sau hoặc liên hệ tổng đài để được hỗ trợ.</p>
        <a href="${ctx}/index.jsp" class="ttv-btn-ghost">Về trang chủ</a>
    </div>
</c:if>

<c:if test="${not empty coSo}">

<%-- ============ Dòng lưu ý ============ --%>
<div class="ttv-note">
    <b>Lưu ý:</b> Chọn các khung giờ liền nhau trên cùng một sân. Các khung giờ đã đặt, đã qua hoặc đang bảo trì không thể chọn.
</div>

<%-- ============ Timetable ============ --%>
<div class="ttv-tt-wrapper" id="ttvTableWrapper">
    <div class="ttv-tt-scroll" id="ttvTableScroll">
        <div id="ttvLoading" class="ttv-loading-box" aria-hidden="true">
            <div class="ttv-skel row" style="width: 60%;"></div>
            <div class="ttv-skel row"></div>
            <div class="ttv-skel row"></div>
            <div class="ttv-skel row"></div>
            <div class="ttv-skel row"></div>
            <div class="ttv-skel row"></div>
        </div>
        <div id="ttvErrorState" class="ttv-error" hidden role="alert">
            <p>Không thể tải lịch sân. Vui lòng thử lại.</p>
            <button type="button" class="ttv-btn-ghost" onclick="ttvReload()">Thử lại</button>
        </div>
        <div id="ttvEmpty" class="ttv-tt-empty" hidden>
            Không có sân khả dụng trong ngày đã chọn.
        </div>
        <div id="ttvTable" class="ttv-tt" hidden></div>
    </div>
</div>

<%-- ============ Footer cố định + CTA lớn ============ --%>
<form id="ttvBookingForm" action="${ctx}/customer/dat-lich-truc-quan/xac-nhan" method="post" class="ttv-summary" novalidate>
    <input type="hidden" name="coSoId" value="${coSo.coSoID}" />
    <input type="hidden" name="sanId" id="ttvInputSanId" />
    <input type="hidden" name="ngayDat" id="ttvInputNgayDat" />
    <input type="hidden" name="gioBatDau" id="ttvInputGioBatDau" />
    <input type="hidden" name="gioKetThuc" id="ttvInputGioKetThuc" />

    <div class="ttv-summary-row">
        <div class="ttv-summary-stat">
            <span>Tổng giờ</span>
            <strong id="ttvSummaryDuration">0h00</strong>
        </div>
        <div class="ttv-summary-sel" id="ttvSummaryLine1">Chưa chọn khung giờ</div>
        <div class="ttv-summary-stat is-total">
            <span>Tổng tiền</span>
            <strong id="ttvSummaryTotal">0 đ</strong>
        </div>
    </div>
    <button type="submit" class="ttv-summary-cta" id="ttvNextBtn" disabled>
        <span id="ttvNextLabel">Chọn khung giờ để tiếp tục</span>
    </button>
</form>

<%-- ============ Toast ============ --%>
<div class="ttv-inline-alert" id="ttvAlert" role="alert" aria-live="assertive"></div>

<%-- ============ Full-screen step loading ============ --%>
<div class="ttv-step-loading" id="ttvStepLoading" hidden role="status" aria-live="polite" aria-busy="true">
    <div class="ttv-step-loading-brand">V-<span>SPORT</span></div>
    <div class="ttv-step-loading-ring" aria-hidden="true"></div>
    <p id="ttvStepLoadingText">Đang chuẩn bị lịch đặt…</p>
</div>

<%-- ============ Session error/message ============ --%>
<c:if test="${not empty sessionScope.error}">
    <script>window.addEventListener('DOMContentLoaded', function(){ ttvAlertShow('${fn:escapeXml(sessionScope.error)}', 'danger'); });</script>
    <% session.removeAttribute("error"); %>
</c:if>
<c:if test="${not empty sessionScope.message}">
    <script>window.addEventListener('DOMContentLoaded', function(){ ttvAlertShow('${fn:escapeXml(sessionScope.message)}', ''); });</script>
    <% session.removeAttribute("message"); %>
</c:if>

<%-- ============ SERVER DATA + SCRIPT ============ --%>
<script id="ttvServerData" type="application/json">
{
  "contextPath": "${ctx}",
  "coSoId": ${coSo.coSoID},
  "initialDate": "${initialDate}",
  "openTime": "${openTime}",
  "closeTime": "${closeTime}",
  "slotMinutes": ${slotMinutes},
  "minDurationMinutes": ${minDurationMinutes},
  "maxDurationMinutes": ${maxDurationMinutes},
  "maxDaysAhead": ${maxDaysAhead},
  "preSanId": <c:choose><c:when test="${not empty preSanId}">${preSanId}</c:when><c:otherwise>null</c:otherwise></c:choose>,
  "isLoggedIn": <c:choose><c:when test="${not empty sessionScope.user}">true</c:when><c:otherwise>false</c:otherwise></c:choose>
}
</script>
<script>
(function () {
    const serverData = JSON.parse(document.getElementById('ttvServerData').textContent);
    const CTX = serverData.contextPath;
    const COSO_ID = serverData.coSoId;
    const SLOT_MIN = serverData.slotMinutes || 30;
    const MIN_DUR = serverData.minDurationMinutes || 30;
    const MAX_DUR = serverData.maxDurationMinutes || 240;
    const MAX_AHEAD = serverData.maxDaysAhead || 30;

    const state = {
        date: serverData.initialDate,
        openMin: hhmmToMin(serverData.openTime.substring(0, 5)),
        closeMin: hhmmToMin(serverData.closeTime.substring(0, 5)),
        courts: [],
        nowMinutes: -1,
        selectedSanId: serverData.preSanId || null,
        selectedStart: null,
        selectedEnd: null,
        hoverEnd: null,
        priceResult: null,
        abortCtrl: null,
        pendingSubmit: false
    };

    function hhmmToMin(s) { const p = s.split(':'); return (+p[0]) * 60 + (+p[1]); }
    function minToHhmm(m) { return String(Math.floor(m / 60)).padStart(2, '0') + ':' + String(m % 60).padStart(2, '0'); }
    function fmtVnd(n) {
        if (n == null || isNaN(n) || n <= 0) return '0 đ';
        return new Intl.NumberFormat('vi-VN').format(Math.round(n)) + ' đ';
    }
    function todayStr() { const d = new Date(); return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0'); }

    // ---- Step loading overlay (chỉ hiện khi request > 150ms, có timeout an toàn) ----
    let stepLoadingTimer = null;
    let stepLoadingSafety = null;
    function showStepLoading(text) {
        clearTimeout(stepLoadingTimer);
        stepLoadingTimer = setTimeout(function () {
            document.getElementById('ttvStepLoadingText').textContent = text;
            document.getElementById('ttvStepLoading').hidden = false;
        }, 150);
        // Nếu sau 20s vẫn chưa điều hướng (server treo) → gỡ loading, cho phép thao tác lại.
        clearTimeout(stepLoadingSafety);
        stepLoadingSafety = setTimeout(function () {
            hideStepLoading();
            state.pendingSubmit = false;
            updateSummary();
            ttvAlertShow('Máy chủ phản hồi chậm. Vui lòng thử lại.', 'warn');
        }, 20000);
    }
    function hideStepLoading() {
        clearTimeout(stepLoadingTimer);
        clearTimeout(stepLoadingSafety);
        document.getElementById('ttvStepLoading').hidden = true;
    }
    // pageshow chạy cả khi Back (bfcache lẫn reload) — luôn gỡ loader và
    // dựng lại trạng thái CTA, không để nút kẹt ở "Đang kiểm tra lịch...".
    window.addEventListener('pageshow', function () {
        hideStepLoading();
        state.pendingSubmit = false;
        updateSummary();
    });

    // ---- Date controls ----
    const dateInput = document.getElementById('ttvDateInput');
    dateInput.value = state.date;
    dateInput.min = todayStr();
    const maxDate = new Date(); maxDate.setDate(maxDate.getDate() + MAX_AHEAD);
    // Format theo giờ ĐỊA PHƯƠNG — toISOString() là UTC, buổi tối lệch mất một ngày.
    dateInput.max = maxDate.getFullYear() + '-' + String(maxDate.getMonth() + 1).padStart(2, '0') + '-' + String(maxDate.getDate()).padStart(2, '0');
    updatePrevDayBtn();

    window.ttvOnDateChange = function () {
        const v = dateInput.value;
        if (!v) return;
        if (v < todayStr()) { ttvAlertShow('Không thể đặt khung giờ đã qua.', 'warn'); dateInput.value = state.date; return; }
        if (v > dateInput.max) { ttvAlertShow('Chỉ đặt được trong vòng ' + MAX_AHEAD + ' ngày tới.', 'warn'); dateInput.value = state.date; return; }
        state.date = v;
        clearSelection(); updatePrevDayBtn(); loadAvailability();
    };
    window.ttvChangeDate = function (delta) {
        const d = new Date(state.date + 'T00:00:00');
        d.setDate(d.getDate() + delta);
        // Local format — toISOString() (UTC) làm lệch 1 ngày ở múi giờ VN.
        const s = d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
        if (s < todayStr() || s > dateInput.max) return;
        state.date = s; dateInput.value = s;
        clearSelection(); updatePrevDayBtn(); loadAvailability();
    };
    window.ttvGoBack = function () {
        if (history.length > 1) history.back();
        else window.location.href = CTX + '/customer/dat-san';
    };
    window.ttvReload = function () { loadAvailability(); };

    function updatePrevDayBtn() {
        document.getElementById('ttvPrevDayBtn').disabled = (state.date === todayStr());
    }

    // ---- Availability ----
    function loadAvailability() {
        if (state.abortCtrl) state.abortCtrl.abort();
        state.abortCtrl = new AbortController();
        document.getElementById('ttvLoading').hidden = false;
        document.getElementById('ttvErrorState').hidden = true;
        document.getElementById('ttvEmpty').hidden = true;
        document.getElementById('ttvTable').hidden = true;
        document.getElementById('ttvTableScroll').setAttribute('aria-busy', 'true');

        fetch(CTX + '/customer/api/timetable-availability?coSoId=' + encodeURIComponent(COSO_ID) + '&date=' + encodeURIComponent(state.date),
              { signal: state.abortCtrl.signal, headers: { 'Accept': 'application/json' } })
            .then(function (r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); })
            .then(function (data) {
                if (!data.success) throw new Error(data.error || 'load-failed');
                state.courts = data.courts || [];
                state.openMin = hhmmToMin(data.openTime);
                state.closeMin = hhmmToMin(data.closeTime);
                state.nowMinutes = data.nowMinutes;
                document.getElementById('ttvLoading').hidden = true;
                document.getElementById('ttvTableScroll').removeAttribute('aria-busy');
                if (!state.courts.length) {
                    document.getElementById('ttvEmpty').hidden = false;
                } else {
                    renderTable();
                    document.getElementById('ttvTable').hidden = false;
                    if (state.selectedSanId && !state.courts.find(function (c) { return c.sanId == state.selectedSanId; })) {
                        state.selectedSanId = null;
                    }
                    refreshSelectionVisual();
                }
            })
            .catch(function (err) {
                if (err && err.name === 'AbortError') return;
                document.getElementById('ttvLoading').hidden = true;
                document.getElementById('ttvTableScroll').removeAttribute('aria-busy');
                document.getElementById('ttvErrorState').hidden = false;
            });
    }

    // ---- Render ----
    function renderTable() {
        const table = document.getElementById('ttvTable');
        table.innerHTML = '';
        const slotCount = Math.floor((state.closeMin - state.openMin) / SLOT_MIN);
        table.style.gridTemplateColumns = 'var(--ttv-court-col) repeat(' + slotCount + ', minmax(var(--ttv-slot-w), 1fr))';

        const headLabel = document.createElement('div');
        headLabel.className = 'ttv-court-label ttv-court-label-head';
        headLabel.textContent = 'Sân / Giờ';
        table.appendChild(headLabel);

        for (let i = 0; i < slotCount; i++) {
            const min = state.openMin + i * SLOT_MIN;
            const cell = document.createElement('div');
            cell.className = 'ttv-tt-head-cell';
            if (min % 60 === 0) cell.classList.add('is-hour-start');
            cell.dataset.minute = min;
            // Nhãn cả mốc 30 phút (mốc giờ tròn đậm, mốc :30 nhạt hơn).
            if (min % 60 === 0) {
                cell.textContent = minToHhmm(min);
            } else {
                const minor = document.createElement('span');
                minor.className = 'ttv-head-minor';
                minor.textContent = minToHhmm(min);
                cell.appendChild(minor);
            }
            addNowMarker(cell, min, SLOT_MIN, true);
            table.appendChild(cell);
        }

        state.courts.forEach(function (court) {
            const label = document.createElement('div');
            label.className = 'ttv-court-label';
            const nameEl = document.createElement('div');
            nameEl.className = 'ttv-court-name';
            nameEl.textContent = court.tenSan || ('Sân #' + court.sanId);
            nameEl.title = nameEl.textContent + (court.tenLoai ? ' · ' + court.tenLoai : '');
            label.appendChild(nameEl);
            if (court.giaKhongDen) {
                const priceEl = document.createElement('div');
                priceEl.className = 'ttv-court-price';
                priceEl.textContent = fmtVnd(court.giaKhongDen) + '/giờ';
                label.appendChild(priceEl);
            }
            table.appendChild(label);

            // Render theo RUN: các slot bị chặn liên tiếp cùng trạng thái được gộp
            // thành MỘT block liền (grid-column: span N) đúng như booking thật.
            let i = 0;
            while (i < court.slots.length) {
                const slot = court.slots[i];
                if (slot.status === 'AVAILABLE') {
                    table.appendChild(buildAvailableCell(court, slot));
                    i++;
                    continue;
                }
                let j = i + 1;
                while (j < court.slots.length && court.slots[j].status === slot.status) j++;
                table.appendChild(buildBlockedRun(court, court.slots.slice(i, j)));
                i = j;
            }
        });
    }

    function addNowMarker(cell, startMinute, spanMinutes, withChip) {
        if (state.nowMinutes < startMinute || state.nowMinutes >= startMinute + spanMinutes) return;
        const marker = document.createElement('div');
        marker.className = 'ttv-now-marker';
        marker.style.left = ((state.nowMinutes - startMinute) / spanMinutes * 100) + '%';
        cell.appendChild(marker);
        if (withChip) {
            const chip = document.createElement('span');
            chip.className = 'ttv-now-chip';
            chip.style.left = ((state.nowMinutes - startMinute) / spanMinutes * 100) + '%';
            chip.textContent = 'Hiện tại';
            cell.appendChild(chip);
        }
    }

    function buildAvailableCell(court, slot) {
        const cell = document.createElement('div');
        cell.className = 'ttv-slot';
        if (slot.startMinute % 60 === 0) cell.classList.add('is-hour-start');
        cell.dataset.sanId = court.sanId;
        cell.dataset.start = slot.start;
        cell.dataset.end = slot.end;
        cell.dataset.startMinute = slot.startMinute;
        cell.dataset.status = slot.status;
        cell.setAttribute('role', 'button');
        cell.setAttribute('tabindex', '0');
        cell.setAttribute('aria-label',
            (court.tenSan || ('Sân ' + court.sanId)) + ' – ' + slot.start + ' đến ' + slot.end + ' – Trống');
        cell.addEventListener('click', function () { onSlotClick(court.sanId, slot); });
        cell.addEventListener('mouseenter', function () { onSlotHover(court.sanId, slot); });
        cell.addEventListener('keydown', function (e) {
            if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onSlotClick(court.sanId, slot); }
        });
        addNowMarker(cell, slot.startMinute, SLOT_MIN, false);
        return cell;
    }

    function buildBlockedRun(court, run) {
        const first = run[0], last = run[run.length - 1];
        const span = run.length;
        const cell = document.createElement('div');
        cell.className = 'ttv-slot is-blocked is-' + first.status.toLowerCase();
        if (span > 1) cell.classList.add('is-merged');
        if (first.startMinute % 60 === 0) cell.classList.add('is-hour-start');
        cell.style.gridColumn = 'span ' + span;
        cell.dataset.sanId = court.sanId;
        cell.dataset.start = first.start;
        cell.dataset.end = last.end;
        cell.dataset.startMinute = first.startMinute;
        cell.dataset.status = first.status;
        cell.setAttribute('role', 'button');
        cell.setAttribute('tabindex', '-1');
        cell.setAttribute('aria-label',
            (court.tenSan || ('Sân ' + court.sanId)) + ' – ' + first.start + ' đến ' + last.end + ' – ' + statusLabel(first.status));
        cell.title = (first.reason || statusLabel(first.status)) + ' · ' + first.start + '–' + last.end;
        // Label trong block khi đủ rộng; block hẹp không nhồi chữ.
        if (span >= 3) {
            const lbl = document.createElement('span');
            lbl.className = 'ttv-slot-run-label';
            lbl.textContent = statusLabel(first.status) + ' · ' + first.start + '–' + last.end;
            cell.appendChild(lbl);
        } else if (span === 2) {
            const lbl = document.createElement('span');
            lbl.className = 'ttv-slot-run-label';
            lbl.textContent = statusLabel(first.status);
            cell.appendChild(lbl);
        }
        cell.addEventListener('click', function () { onSlotClick(court.sanId, first); });
        if (first.status === 'HOLD_SELF') {
            cell.setAttribute('tabindex', '0');
            cell.addEventListener('keydown', function (e) {
                if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onSlotClick(court.sanId, first); }
            });
        }
        addNowMarker(cell, first.startMinute, span * SLOT_MIN, false);
        return cell;
    }

    function statusLabel(s) {
        switch (s) {
            case 'AVAILABLE': return 'Trống';
            case 'BOOKED': return 'Đã đặt';
            case 'HOLD': return 'Đang được giữ';
            case 'HOLD_SELF': return 'Chờ thanh toán · bấm để tiếp tục';
            case 'LOCKED': return 'Khoá / bảo trì';
            case 'PAST': return 'Đã qua';
            default: return s;
        }
    }

    // ---- Selection ----
    function clearSelection() {
        state.selectedSanId = null;
        state.selectedStart = null;
        state.selectedEnd = null;
        state.priceResult = null;
        refreshSelectionVisual();
        updateSummary();
    }

    function onSlotClick(sanId, slot) {
        // Đơn CHỜ THANH TOÁN của chính khách → mở lại trang QR để tiếp tục thanh toán (không tạo đơn mới).
        if (slot.status === 'HOLD_SELF' && slot.datSanId) {
            window.location.href = CTX + '/customer/thanh-toan-qr?datSanId=' + slot.datSanId;
            return;
        }
        if (slot.status !== 'AVAILABLE') {
            let msg = 'Khung giờ này không khả dụng.';
            if (slot.status === 'BOOKED') msg = 'Khung giờ này không còn trống.';
            else if (slot.status === 'PAST') msg = 'Không thể chọn thời gian đã qua.';
            else if (slot.status === 'HOLD') msg = 'Khung giờ đang được người khác giữ chỗ.';
            else if (slot.status === 'LOCKED') msg = 'Sân tạm ngưng hoạt động trong thời gian này.';
            ttvAlertShow(msg, slot.status === 'BOOKED' ? 'danger' : 'warn');
            return;
        }
        if (state.selectedSanId && state.selectedSanId != sanId && state.selectedStart != null) {
            // Đổi sân: xóa lựa chọn cũ, chọn sân mới ngay.
            state.selectedSanId = null;
            state.selectedStart = null;
            state.selectedEnd = null;
            state.priceResult = null;
            ttvAlertShow('Đã chuyển sang sân khác. Lựa chọn cũ được bỏ.', 'warn');
        }
        const startM = slot.startMinute;
        const endM = startM + SLOT_MIN;

        if (state.selectedSanId == null || state.selectedSanId != sanId) {
            state.selectedSanId = sanId;
            state.selectedStart = startM;
            state.selectedEnd = endM;
        } else if (startM >= state.selectedStart && startM < state.selectedEnd) {
            state.selectedEnd = startM;
            if (state.selectedEnd - state.selectedStart <= 0) { clearSelection(); return; }
        } else if (startM === state.selectedEnd) {
            if (checkContiguous(sanId, state.selectedEnd, endM)) state.selectedEnd = endM;
            else { ttvAlertShow('Chỉ chọn các khung giờ liền nhau trên cùng một sân.', 'warn'); return; }
        } else if (startM === state.selectedStart - SLOT_MIN) {
            if (checkContiguous(sanId, startM, state.selectedStart)) state.selectedStart = startM;
            else { ttvAlertShow('Chỉ chọn các khung giờ liền nhau trên cùng một sân.', 'warn'); return; }
        } else {
            state.selectedStart = startM;
            state.selectedEnd = endM;
        }

        if (state.selectedEnd - state.selectedStart > MAX_DUR) {
            state.selectedEnd = state.selectedStart + MAX_DUR;
            ttvAlertShow('Thời lượng tối đa ' + (MAX_DUR / 60) + ' giờ. Đã tự cắt bớt.', 'warn');
        }
        if (!isSelectionValid(sanId, state.selectedStart, state.selectedEnd)) {
            ttvAlertShow('Khoảng chọn chứa khung giờ không khả dụng. Hãy chọn lại.', 'warn');
            clearSelection();
            return;
        }
        refreshSelectionVisual();
        state.priceResult = null;
        updateSummary();
        fetchPrice();
    }

    function onSlotHover(sanId, slot) {
        if (!state.selectedSanId || state.selectedSanId != sanId || state.selectedStart == null) return;
        if (slot.status !== 'AVAILABLE') return;
        const hoverEndM = slot.startMinute + SLOT_MIN;
        if (hoverEndM <= state.selectedEnd) return;
        if (!isSelectionValid(sanId, state.selectedStart, hoverEndM)) return;
        state.hoverEnd = hoverEndM;
        document.querySelectorAll('.ttv-slot.is-hover').forEach(function (c) { c.classList.remove('is-hover'); });
        document.querySelectorAll('.ttv-slot[data-san-id="' + sanId + '"]').forEach(function (cell) {
            const m = parseInt(cell.dataset.startMinute, 10);
            if (m >= state.selectedEnd && m < state.hoverEnd) cell.classList.add('is-hover');
        });
    }

    function checkContiguous(sanId, fromMin, toMin) {
        const court = state.courts.find(function (c) { return c.sanId == sanId; });
        if (!court) return false;
        for (let m = fromMin; m < toMin; m += SLOT_MIN) {
            const s = court.slots.find(function (sl) { return sl.startMinute === m; });
            if (!s || s.status !== 'AVAILABLE') return false;
        }
        return true;
    }
    function isSelectionValid(sanId, startM, endM) {
        return checkContiguous(sanId, startM, endM) && (endM - startM) >= SLOT_MIN;
    }

    function refreshSelectionVisual() {
        document.querySelectorAll('.ttv-slot').forEach(function (cell) {
            cell.classList.remove('is-selected', 'is-selected-start', 'is-selected-end', 'is-hover');
        });
        if (!state.selectedSanId || state.selectedStart == null) return;
        document.querySelectorAll('.ttv-slot[data-san-id="' + state.selectedSanId + '"]').forEach(function (cell) {
            const m = parseInt(cell.dataset.startMinute, 10);
            if (m >= state.selectedStart && m < state.selectedEnd) {
                cell.classList.add('is-selected');
                if (m === state.selectedStart) cell.classList.add('is-selected-start');
                if (m + SLOT_MIN === state.selectedEnd) cell.classList.add('is-selected-end');
            }
        });
    }

    // ---- Price preview (server-side pricing) ----
    let priceAbort = null;
    function fetchPrice() {
        if (!state.selectedSanId || state.selectedStart == null || state.selectedEnd == null) {
            state.priceResult = null; updateSummary(); return;
        }
        if (priceAbort) priceAbort.abort();
        priceAbort = new AbortController();
        const params = new URLSearchParams();
        params.set('sanId', state.selectedSanId);
        params.set('date', state.date);
        params.set('start', minToHhmm(state.selectedStart));
        params.set('end', minToHhmm(state.selectedEnd));
        fetch(CTX + '/customer/api/timetable-price?' + params.toString(),
              { signal: priceAbort.signal, headers: { 'Accept': 'application/json' } })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (!data.success) {
                    state.priceResult = null;
                    ttvAlertShow(data.error || 'Không thể tính giá.', 'warn');
                } else {
                    state.priceResult = data;
                }
                updateSummary();
            })
            .catch(function (err) {
                if (err && err.name === 'AbortError') return;
                state.priceResult = null;
                updateSummary();
            });
    }

    // CTA hai trạng thái: disabled → "Chọn khung giờ để tiếp tục", hợp lệ → "Tiếp theo".
    // Luôn dựng lại nội dung nút (spinner có thể đã thay innerHTML khi submit).
    function setCtaState(disabled, label, withSpinner) {
        const btn = document.getElementById('ttvNextBtn');
        btn.disabled = disabled;
        btn.innerHTML = '';
        if (withSpinner) {
            const sp = document.createElement('span');
            sp.className = 'ttv-btn-spinner';
            sp.setAttribute('aria-hidden', 'true');
            btn.appendChild(sp);
        }
        const span = document.createElement('span');
        span.id = 'ttvNextLabel';
        span.textContent = label;
        btn.appendChild(span);
    }

    function updateSummary() {
        const line1 = document.getElementById('ttvSummaryLine1');
        const totalEl = document.getElementById('ttvSummaryTotal');
        const durEl = document.getElementById('ttvSummaryDuration');

        const hasSelection = state.selectedSanId && state.selectedStart != null && state.selectedEnd != null;
        const dur = hasSelection ? (state.selectedEnd - state.selectedStart) : 0;

        if (!hasSelection) {
            line1.textContent = 'Chưa chọn khung giờ';
            durEl.textContent = '0h00';
            totalEl.textContent = '0 đ';
            setCtaState(true, 'Chọn khung giờ để tiếp tục', false);
            return;
        }
        const court = state.courts.find(function (c) { return c.sanId == state.selectedSanId; });
        const courtLabel = court ? court.tenSan : ('Sân #' + state.selectedSanId);
        line1.textContent = courtLabel + ' · ' + minToHhmm(state.selectedStart) + '–' + minToHhmm(state.selectedEnd) + ' · ' + state.date;
        durEl.textContent = formatDurationVi(dur);

        if (dur < MIN_DUR) {
            totalEl.textContent = '0 đ';
            setCtaState(true, 'Chọn thêm thời gian', false);
            return;
        }
        if (state.priceResult) {
            totalEl.textContent = fmtVnd(parseFloat(state.priceResult.totalAmount));
            if (state.pendingSubmit) {
                setCtaState(true, 'Đang kiểm tra lịch...', true);
            } else {
                setCtaState(false, 'Tiếp theo', false);
            }
        } else {
            totalEl.textContent = '...';
            setCtaState(true, 'Đang tính giá...', false);
        }
    }

    function formatDurationVi(mins) {
        const h = Math.floor(mins / 60), m = mins % 60;
        return h + 'h' + String(m).padStart(2, '0');
    }

    // ---- Submit → bước xác nhận ----
    document.getElementById('ttvBookingForm').addEventListener('submit', function (e) {
        if (state.pendingSubmit) { e.preventDefault(); return; }
        if (!state.selectedSanId || state.selectedStart == null || state.selectedEnd == null) {
            e.preventDefault(); ttvAlertShow('Vui lòng chọn khung giờ.', 'warn'); return;
        }
        document.getElementById('ttvInputSanId').value = state.selectedSanId;
        document.getElementById('ttvInputNgayDat').value = state.date;
        document.getElementById('ttvInputGioBatDau').value = minToHhmm(state.selectedStart);
        document.getElementById('ttvInputGioKetThuc').value = minToHhmm(state.selectedEnd);
        state.pendingSubmit = true;
        setCtaState(true, 'Đang kiểm tra lịch...', true);
        showStepLoading('Đang chuẩn bị lịch đặt…');
        // browser submit form thật → server re-check + pricing thật
    });

    // ---- Alert toast ----
    let alertTimer = null;
    window.ttvAlertShow = function (msg, kind) {
        const el = document.getElementById('ttvAlert');
        el.className = 'ttv-inline-alert';
        if (kind === 'danger') el.classList.add('is-danger');
        if (kind === 'warn') el.classList.add('is-warn');
        el.textContent = msg;
        el.classList.add('is-open');
        clearTimeout(alertTimer);
        alertTimer = setTimeout(function () { el.classList.remove('is-open'); }, 3200);
    };

    // Init
    loadAvailability();
})();
</script>

</c:if>

<c:if test="${empty coSo and emptyState ne 'no_facility'}">
    <div class="ttv-empty-facility">
        <h2>Không tải được dữ liệu</h2>
        <p>Vui lòng thử lại.</p>
        <a href="${ctx}/index.jsp" class="ttv-btn-ghost">Về trang chủ</a>
    </div>
</c:if>

</body>
</html>
