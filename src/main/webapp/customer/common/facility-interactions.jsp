<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%--
    V-SPORT shared facility interactions (Customer Portal).
    Bundles: home toast, "Chọn hình thức đặt" modal, facility-detail bottom sheet,
    and all their CSS + JS. Extracted from index.jsp so any customer page listing
    facility cards can reuse the exact same interaction instead of re-implementing it.

    Requires on the including page:
      - a container with id="facilityGrid" holding .facility-card elements, each with
        data-coso-id / data-facility-name / data-card-image attributes, and a
        [data-book-trigger] button with data-coso-id / data-facility-name.
      - jsp:include of customer/common/vsport-theme.jsp (design tokens).
    Provides to the including page: window.showHomeToast(msg), window.VSPORT_CONTEXT_PATH.
--%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<style>
    :root {
        --vsx-font: 'Be Vietnam Pro', 'Inter', system-ui, -apple-system, sans-serif;
        --vs-mint-100: var(--vs-cyan-100, #DDF8FC);
        --vs-mint-50: var(--vs-cyan-50, #F0FCFE);
        --vs-pink-100: #fae8f8;
        --vs-pink-600: #c83db3;
        --vs-overlay: rgba(7, 26, 47, 0.68);
        --vsx-border: var(--vs-border, #DCE5EF);
        --vsx-text: var(--vs-text, #102A43);
        --vsx-muted: var(--vs-text-secondary, #486581);
    }
    .lci { width: 20px; height: 20px; flex-shrink: 0; }

    /* [hidden] phải thắng cả các class có display:flex/inline-flex */
    [hidden] { display: none !important; }

    .vsx-overlay {
        position: fixed; inset: 0; background: var(--vs-overlay);
        z-index: 1240; opacity: 0; transition: opacity 220ms ease;
    }
    .vsx-overlay.is-open { opacity: 1; }

    /* ---- Modal "Chọn hình thức đặt" ---- */
    .vsbc-backdrop {
        position: fixed; inset: 0; z-index: 1249;
        background: rgba(3, 19, 36, 0.66);
        backdrop-filter: blur(1.5px); -webkit-backdrop-filter: blur(1.5px);
        opacity: 0; transition: opacity 220ms ease;
    }
    .vsbc-backdrop.is-open { opacity: 1; }
    .vsbc-modal-layer {
        position: fixed; inset: 0; z-index: 1250;
        display: flex; align-items: center; justify-content: center;
        padding: 16px; pointer-events: none;
    }
    .vsbc-modal-layer .vsbc-modal { pointer-events: auto; }
    .vsbc-modal {
        width: 750px; max-width: calc(100vw - 32px);
        max-height: calc(100dvh - 32px); overflow-y: auto;
        background: #fff; border-radius: 22px;
        padding: 28px 20px 24px;
        opacity: 0; transform: scale(.96);
        box-shadow: 0 24px 70px rgba(7, 29, 54, 0.28);
        transition: opacity 200ms ease, transform 200ms ease;
        font-family: var(--vsx-font); color: var(--vsx-text);
        position: relative;
    }
    .vsbc-modal.is-open { opacity: 1; transform: scale(1); }
    @media (max-width: 767px) {
        .vsbc-modal-layer { padding: 12px; }
        .vsbc-modal { width: calc(100vw - 24px); padding: 18px 14px 16px; border-radius: 18px; }
    }
    .vsbc-head { margin-bottom: 28px; }
    .vsbc-title {
        font-family: 'Inter', 'Be Vietnam Pro', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        font-size: 26px; line-height: 1.25; font-weight: 700; letter-spacing: 0;
        color: var(--vs-primary-900, #0B2D52);
        text-align: center; margin: 0; padding: 0 44px;
    }
    @media (max-width: 389px) { .vsbc-title { font-size: 21px; } }
    .vsbc-sub {
        text-align: center; font-size: 13px; color: var(--vsx-muted);
        margin: 8px 0 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }
    .vsbc-sub:empty { display: none; }
    .vsbc-x {
        position: absolute; top: 14px; right: 14px;
        width: 44px; height: 44px; border-radius: 50%; border: none; cursor: pointer;
        background: transparent; color: var(--vs-primary-900, #0B2D52);
        display: flex; align-items: center; justify-content: center; flex-shrink: 0;
        transition: background-color .15s ease;
    }
    .vsbc-x .lci { width: 26px; height: 26px; }
    .vsbc-x:hover { background: rgba(11, 45, 82, 0.08); }
    .vsbc-x:focus-visible { outline: 3px solid var(--vs-focus-ring, rgba(24, 200, 232, 0.35)); outline-offset: 2px; }
    .vsbc-option {
        display: flex; flex-direction: column; justify-content: center;
        width: 100%; min-height: 124px; padding: 18px 76px 18px 16px;
        border-radius: 16px; border: 1px solid transparent;
        text-decoration: none; cursor: pointer; text-align: left; user-select: none;
        position: relative; overflow: hidden;
        transform: none;
        transition: border-color 120ms ease, filter 110ms ease,
                    box-shadow 110ms ease, transform 110ms ease;
    }
    .vsbc-option + .vsbc-option { margin-top: 20px; }
    /* Hover: chỉ đổi màu viền — tuyệt đối không chuyển động/scale/shadow animation. */
    .vsbc-option:hover { transform: none; }
    .vsbc-option-direct:hover { border-color: var(--vs-primary-600, #1677D2); }
    .vsbc-option-match:hover { border-color: var(--vs-orange-500, #F07820); }
    /* Press: card lún nhẹ xuống với inset shadow (giữ hiệu ứng qua class, không chỉ :active). */
    .vsbc-option:active,
    .vsbc-option.is-pressed {
        transform: translateY(3px) scale(0.985);
        box-shadow: inset 0 4px 9px rgba(7, 29, 54, 0.20), 0 2px 5px rgba(7, 29, 54, 0.08);
        filter: brightness(0.97);
    }
    @media (prefers-reduced-motion: reduce) {
        .vsbc-option:active, .vsbc-option.is-pressed { transform: none; }
    }
    .vsbc-option:focus-visible { outline: 3px solid var(--vs-focus-ring, rgba(24, 200, 232, 0.35)); outline-offset: 2px; }

    /* ---- V-SPORT step-transition loading (full viewport, Navy) ---- */
    .vsx-loading {
        position: fixed; inset: 0; z-index: 99999;
        background: var(--vs-primary-950, #0B2E59);
        display: flex; align-items: center; justify-content: center; overflow: hidden;
        color: #fff; opacity: 0; visibility: hidden; pointer-events: none;
        transition: opacity 150ms ease;
    }
    .vsx-loading.is-visible { opacity: 1; visibility: visible; pointer-events: all; }
    .vsx-loading-title {
        position: absolute; top: 26px; left: 50%; transform: translateX(-50%);
        font-family: var(--vsx-font); font-size: 16px; font-weight: 700; color: #fff;
        text-align: center; white-space: nowrap;
    }
    .vsx-loading-ring {
        width: 32px; height: 32px; border-radius: 50%;
        border: 4px solid rgba(255, 255, 255, .30);
        border-top-color: #fff;
        animation: vsxSpin 0.8s linear infinite;
    }
    @keyframes vsxSpin { to { transform: rotate(360deg); } }
    @media (prefers-reduced-motion: reduce) {
        .vsx-loading-ring { animation-duration: 2.4s; }
    }
    .vsbc-option-direct { background: #E3F4FF; border-color: rgba(22, 119, 210, 0.15); }
    .vsbc-option-direct .vsbc-opt-title { color: #1677D2; }
    .vsbc-option-match { background: #FFF0E5; border-color: rgba(240, 120, 32, 0.16); }
    .vsbc-option-match .vsbc-opt-title { color: #F07820; }
    .vsbc-opt-title { font-size: 22px; font-weight: 700; line-height: 1.25; margin-bottom: 12px; display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
    .vsbc-opt-desc { font-size: 17px; font-weight: 500; color: #48604f; line-height: 1.4; }
    .vsbc-badge {
        font-size: 10.5px; font-weight: 800; text-transform: uppercase; letter-spacing: .04em;
        background: var(--vs-orange-500, #F07820); color: #fff; padding: 2px 8px; border-radius: 9999px;
    }
    .vsbc-arrow {
        width: 74px; height: 42px; border-radius: 16px 0 16px 0;
        position: absolute; right: 0; bottom: 0;
        display: flex; align-items: center; justify-content: center; color: #fff;
    }
    .vsbc-arrow .lci { width: 27px; height: 27px; }
    .vsbc-option-direct .vsbc-arrow { background: var(--vs-primary-600, #1677D2); }
    .vsbc-option-match .vsbc-arrow { background: var(--vs-orange-500, #F07820); }
    @media (max-width: 389px) {
        .vsbc-opt-title { font-size: 17px; }
        .vsbc-opt-desc { font-size: 14px; }
    }

    /* ---- Facility detail bottom sheet ---- */
    .vsfs-sheet {
        position: fixed; left: 0; right: 0; bottom: 0; width: 100%;
        max-height: 82dvh;
        background: #fff; border-radius: 24px 24px 0 0;
        z-index: 1250; transform: translateY(100%);
        transition: transform 300ms cubic-bezier(.22, 1, .36, 1);
        box-shadow: 0 -18px 50px rgba(7, 26, 47, 0.30);
        display: flex; flex-direction: column;
        font-family: var(--vsx-font); color: var(--vsx-text);
    }
    .vsfs-sheet.is-open { transform: translateY(0); }
    .vsfs-handle-wrap { padding: 8px 0 2px; display: flex; justify-content: center; cursor: grab; touch-action: none; flex-shrink: 0; }
    .vsfs-handle { width: 48px; height: 5px; border-radius: 9999px; background: #d5e2db; }
    .vsfs-topbar { display: flex; align-items: center; justify-content: flex-end; gap: 8px; padding: 2px 16px 8px; flex-shrink: 0; }
    .vsfs-iconbtn {
        width: 44px; height: 44px; border-radius: 50%; border: 1px solid var(--vsx-border);
        background: #fff; color: var(--vsx-text); cursor: pointer;
        display: flex; align-items: center; justify-content: center;
        transition: background-color .15s ease, color .15s ease;
    }
    .vsfs-iconbtn:hover { background: var(--vs-mint-50); }
    .vsfs-iconbtn:focus-visible { outline: 3px solid var(--vs-focus-ring, rgba(24, 200, 232, 0.35)); outline-offset: 2px; }
    .vsfs-iconbtn.is-fav { color: #e11d48; border-color: #fecdd3; background: #fff1f2; }
    .vsfs-scroll { overflow-y: auto; min-height: 0; flex: 1; -webkit-overflow-scrolling: touch; overscroll-behavior: contain; }
    .vsfs-inner { width: 100%; max-width: 1360px; margin: 0 auto; padding: 0 16px 18px; }
    @media (min-width: 1024px) { .vsfs-inner { padding: 0 28px 24px; } }
    .vsfs-cols { display: grid; grid-template-columns: 1fr; gap: 18px; }
    @media (min-width: 1024px) { .vsfs-cols { grid-template-columns: 42% minmax(0, 1fr); gap: 26px; align-items: start; } }
    .vsfs-hero {
        position: relative; border-radius: 16px; overflow: hidden; background: #eef4f1;
        aspect-ratio: 16 / 10;
    }
    .vsfs-hero img { width: 100%; height: 100%; object-fit: cover; display: block; }
    .vsfs-name { font-size: 24px; font-weight: 800; line-height: 1.25; }
    @media (min-width: 1024px) { .vsfs-name { font-size: 28px; } }
    .vsfs-chips { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
    .vsfs-chip {
        display: inline-flex; align-items: center; gap: 5px;
        font-size: 12px; font-weight: 700; padding: 4px 11px; border-radius: 9999px;
        background: var(--vs-cyan-100, #DDF8FC); color: var(--vs-primary-700, #185A9D); border: 1px solid var(--vs-cyan-100, #DDF8FC);
    }
    .vsfs-chip.is-warn { background: #fff7e6; color: #b45309; border-color: #fde4b8; }
    .vsfs-chip.is-ready { background: var(--vs-success-bg, #E5F7EF); color: var(--vs-success, #16A36A); border-color: var(--vs-success-bg, #E5F7EF); }
    .vsfs-meta { margin-top: 12px; display: flex; flex-direction: column; gap: 8px; }
    .vsfs-meta-row { display: flex; align-items: flex-start; gap: 9px; font-size: 14px; color: #3c5a4b; }
    .vsfs-meta-row .lci { width: 18px; height: 18px; color: var(--vs-primary-600, #1677D2); margin-top: 1px; }
    .vsfs-price { font-size: 15px; font-weight: 800; color: var(--vs-primary-700, #185A9D); margin-top: 10px; }
    .vsfs-tabs {
        display: flex; gap: 4px; margin-top: 18px; border-bottom: 1px solid var(--vsx-border);
        overflow-x: auto; scrollbar-width: none; -ms-overflow-style: none;
    }
    .vsfs-tabs::-webkit-scrollbar { display: none; }
    .vsfs-tab {
        border: none; background: transparent; cursor: pointer;
        padding: 10px 14px; font-family: inherit; font-size: 14px; font-weight: 700;
        color: var(--vsx-muted); border-bottom: 2.5px solid transparent;
        white-space: nowrap; transition: color .15s ease, border-color .15s ease;
        min-height: 44px;
    }
    .vsfs-tab:hover { color: var(--vsx-text); }
    .vsfs-tab:focus-visible { outline: 3px solid var(--vs-focus-ring, rgba(24, 200, 232, 0.35)); outline-offset: -2px; }
    .vsfs-tab[aria-selected="true"] { color: var(--vs-primary-600, #1677D2); border-bottom-color: var(--vs-primary-600, #1677D2); }
    .vsfs-panel { padding: 14px 2px 4px; font-size: 14px; line-height: 1.6; color: #3c5a4b; }
    .vsfs-court {
        display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap;
        border: 1px solid var(--vsx-border); border-radius: 12px; padding: 12px 14px;
    }
    .vsfs-court + .vsfs-court { margin-top: 8px; }
    .vsfs-court-name { font-size: 14.5px; font-weight: 800; color: var(--vsx-text); }
    .vsfs-court-sub { font-size: 12.5px; color: var(--vsx-muted); margin-top: 2px; }
    .vsfs-court-price { font-size: 13.5px; font-weight: 800; color: var(--vs-primary-700, #185A9D); white-space: nowrap; }
    .vsfs-status {
        display: inline-block; font-size: 11px; font-weight: 700; padding: 2px 9px;
        border-radius: 9999px; margin-left: 8px; vertical-align: 2px;
    }
    .vsfs-status.is-ready { background: var(--vs-success-bg, #E5F7EF); color: var(--vs-success, #16A36A); }
    .vsfs-status.is-other { background: #f1f5f9; color: #64748b; }
    .vsfs-court-cta {
        display: inline-flex; align-items: center; gap: 6px;
        font-size: 12.5px; font-weight: 800; text-decoration: none;
        color: #fff; border: 1px solid var(--vs-orange-500, #FF8A24); background: var(--vs-orange-500, #FF8A24);
        padding: 8px 14px; border-radius: 8px; white-space: nowrap;
        transition: background-color .15s ease; min-height: 38px;
    }
    .vsfs-court-cta:hover { background: var(--vs-orange-600, #F97316); border-color: var(--vs-orange-600, #F97316); }
    .vsfs-service { display: flex; justify-content: space-between; gap: 12px; padding: 9px 2px; border-bottom: 1px solid #edf4f0; font-size: 13.5px; }
    .vsfs-service b { font-weight: 800; color: var(--vs-primary-700, #185A9D); white-space: nowrap; }
    .vsfs-imggrid { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 8px; }
    .vsfs-imggrid img { width: 100%; aspect-ratio: 4 / 3; object-fit: cover; border-radius: 10px; background: #eef4f1; }

    /* ---- Cửa hàng (Phase 4) ---- */
    .vsfs-shop-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 12px; }
    .vsfs-product { border: 1px solid var(--vsx-border); border-radius: 12px; overflow: hidden; background: #fff; display: flex; flex-direction: column; }
    .vsfs-product-img { aspect-ratio: 1 / 1; background: var(--vs-mint-50); display: flex; align-items: center; justify-content: center; color: var(--vsx-muted); overflow: hidden; }
    .vsfs-product-img img { width: 100%; height: 100%; object-fit: cover; display: block; }
    .vsfs-product-img .lci { width: 34px; height: 34px; }
    .vsfs-product-body { padding: 10px 11px 11px; display: flex; flex-direction: column; gap: 4px; flex: 1; }
    .vsfs-product-cat { font-size: 10.5px; font-weight: 700; text-transform: uppercase; letter-spacing: .03em; color: var(--vsx-muted); }
    .vsfs-product-name { font-size: 13.5px; font-weight: 800; color: var(--vsx-text); line-height: 1.3; }
    .vsfs-product-price { font-size: 13.5px; font-weight: 800; color: var(--vs-primary-700, #185A9D); margin-top: auto; }
    .vsfs-product-stock { font-size: 11px; font-weight: 700; padding: 2px 8px; border-radius: 9999px; align-self: flex-start; }
    .vsfs-product-stock.is-in { background: var(--vs-success-bg, #E5F7EF); color: var(--vs-success, #16A36A); }
    .vsfs-product-stock.is-low { background: #fff7e6; color: #b45309; }
    .vsfs-product-stock.is-out { background: #f1f5f9; color: #64748b; }
    .vsfs-product-contact {
        display: inline-flex; align-items: center; justify-content: center;
        margin-top: 6px; padding: 7px 10px; border-radius: 8px;
        font-size: 12px; font-weight: 700; text-align: center; text-decoration: none;
        color: var(--vs-primary-700, #185A9D); background: var(--vs-mint-50);
        border: 1px solid var(--vs-cyan-100, #DDF8FC);
    }
    a.vsfs-product-contact:hover { background: var(--vs-cyan-100, #DDF8FC); }
    .vsfs-policy-item { display: flex; gap: 9px; align-items: flex-start; }
    .vsfs-policy-item + .vsfs-policy-item { margin-top: 9px; }
    .vsfs-policy-item .lci { width: 17px; height: 17px; color: var(--vs-primary-600, #1677D2); margin-top: 2px; }
    .vsfs-actionbar {
        flex-shrink: 0; border-top: 1px solid var(--vsx-border); background: #fff;
        padding: 12px 16px calc(12px + env(safe-area-inset-bottom, 0px));
    }
    .vsfs-actionbar-inner { width: 100%; max-width: 1360px; margin: 0 auto; display: flex; gap: 10px; justify-content: flex-end; flex-wrap: wrap; }
    .vsfs-btn {
        display: inline-flex; align-items: center; justify-content: center; gap: 8px;
        min-height: 46px; padding: 0 22px; border-radius: 10px; cursor: pointer;
        font-family: inherit; font-size: 14.5px; font-weight: 800; text-decoration: none;
        border: 1px solid transparent; transition: background-color .15s ease;
    }
    .vsfs-btn:focus-visible { outline: 3px solid var(--vs-focus-ring, rgba(24, 200, 232, 0.35)); outline-offset: 2px; }
    .vsfs-btn-primary { background: var(--vs-green-500, #01E281); color: var(--vs-navy, #122D40); }
    .vsfs-btn-primary:hover { background: var(--vs-green-600, #01C771); }
    .vsfs-btn-ghost { background: #fff; color: var(--vs-navy, #122D40); border-color: var(--vs-navy, #122D40); }
    .vsfs-btn-ghost:hover { background: var(--vs-mint-50); }
    @media (max-width: 767px) {
        .vsfs-sheet { max-height: 92dvh; border-radius: 22px 22px 0 0; }
        .vsfs-actionbar-inner { justify-content: stretch; }
        .vsfs-actionbar .vsfs-btn-primary { flex: 1; }
    }

    /* Skeleton shimmer */
    .vsx-skel {
        background: linear-gradient(90deg, #eef4f1 25%, #e2ece7 37%, #eef4f1 63%);
        background-size: 400% 100%; animation: vsxShimmer 1.4s ease infinite;
        border-radius: 8px;
    }
    @keyframes vsxShimmer { 0% { background-position: 100% 50%; } 100% { background-position: 0 50%; } }

    .vsfs-error { text-align: center; padding: 34px 16px; }
    .vsfs-error p { font-size: 14.5px; font-weight: 600; color: var(--vsx-muted); margin-bottom: 14px; }

    @media (prefers-reduced-motion: reduce) {
        .vsx-overlay, .vsbc-modal, .vsfs-sheet { transition: none !important; }
        .vsx-skel { animation: none; }
    }
</style>

<div id="vsBookingLoading" class="vsx-loading" role="status" aria-live="polite">
    <p id="vsBookingLoadingTitle" class="vsx-loading-title"></p>
    <div class="vsx-loading-ring" aria-hidden="true"></div>
    <span id="vsBookingLoadingText" style="position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;">Đang chuyển đến trang đặt lịch</span>
</div>

<div id="vsHomeToast" role="status" aria-live="polite" style="position:fixed;left:50%;bottom:calc(var(--vs-bottomnav-h, 62px) + 26px);transform:translateX(-50%) translateY(12px);z-index:1300;background:#0f172a;color:#fff;padding:10px 16px;border-radius:9999px;font-size:13px;font-weight:600;opacity:0;visibility:hidden;transition:opacity .2s ease,transform .2s ease;box-shadow:0 6px 18px rgba(15,23,42,.25);"></div>

<!-- ============ Modal "Chọn hình thức đặt" (một instance dùng chung) ============ -->
<div id="bookingChoiceBackdrop" class="vsbc-backdrop" hidden></div>
<div class="vsbc-modal-layer">
<div id="bookingChoiceModal" class="vsbc-modal" role="dialog" aria-modal="true" aria-labelledby="bookingChoiceTitle" hidden>
    <div class="vsbc-head">
        <h2 id="bookingChoiceTitle" class="vsbc-title">Chọn hình thức đặt</h2>
        <button type="button" id="bcCloseBtn" class="vsbc-x" aria-label="Đóng">
            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>
    </div>
    <p id="bcFacilityName" class="vsbc-sub"></p>

    <a id="bcOptionDirect" class="vsbc-option vsbc-option-direct" href="#" data-loading-label="Đặt lịch ngay trực quan">
        <span class="vsbc-opt-title">Đặt lịch ngay trực quan</span>
        <span class="vsbc-opt-desc">Đặt lịch ngay khi khách chơi nhiều khung giờ, nhiều sân.</span>
        <span class="vsbc-arrow" aria-hidden="true">
            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
        </span>
    </a>

    <a id="bcOptionMatch" class="vsbc-option vsbc-option-match" href="#" data-loading-label="Tạo kèo / Tìm người chơi">
        <span class="vsbc-opt-title">Tạo kèo / Tìm người chơi <span class="vsbc-badge">Mới</span></span>
        <span class="vsbc-opt-desc">Tạo một trận mới hoặc tìm thêm người chơi phù hợp tại sân này.</span>
        <span class="vsbc-arrow" aria-hidden="true">
            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
        </span>
    </a>
</div>
</div>

<!-- ============ Facility detail bottom sheet (một instance dùng chung) ============ -->
<div id="facilitySheetOverlay" class="vsx-overlay" hidden></div>
<section id="facilitySheet" class="vsfs-sheet" role="dialog" aria-modal="true" aria-labelledby="fsName" hidden>
    <div class="vsfs-handle-wrap" id="fsHandle" aria-hidden="true"><span class="vsfs-handle"></span></div>
    <div class="vsfs-topbar">
        <button type="button" id="fsFavBtn" class="vsfs-iconbtn" aria-label="Lưu cơ sở yêu thích">
            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/></svg>
        </button>
        <button type="button" id="fsShareBtn" class="vsfs-iconbtn" aria-label="Chia sẻ cơ sở">
            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" x2="15.42" y1="13.51" y2="17.49"/><line x1="15.41" x2="8.59" y1="6.51" y2="10.49"/></svg>
        </button>
        <a id="fsMapBtn" class="vsfs-iconbtn" href="#" aria-label="Xem trên bản đồ" hidden>
            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 8c0 3.613-3.869 7.429-5.393 8.795a1 1 0 0 1-1.214 0C9.87 15.429 6 11.613 6 8a6 6 0 0 1 12 0"/><circle cx="12" cy="8" r="2"/><path d="M8.714 14h-3.71a1 1 0 0 0-.948.683l-2.004 6A1 1 0 0 0 3 22h18a1 1 0 0 0 .948-1.316l-2-6a1 1 0 0 0-.949-.684h-3.712"/></svg>
        </a>
        <button type="button" id="fsCloseBtn" class="vsfs-iconbtn" aria-label="Đóng chi tiết sân">
            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>
    </div>

    <div class="vsfs-scroll" id="fsScroll">
        <div class="vsfs-inner">
            <!-- Skeleton state -->
            <div id="fsSkeleton" class="vsfs-cols">
                <div class="vsx-skel" style="aspect-ratio:16/10;border-radius:16px;"></div>
                <div>
                    <div class="vsx-skel" style="height:30px;width:62%;"></div>
                    <div class="vsx-skel" style="height:15px;width:88%;margin-top:14px;"></div>
                    <div class="vsx-skel" style="height:15px;width:74%;margin-top:9px;"></div>
                    <div class="vsx-skel" style="height:15px;width:52%;margin-top:9px;"></div>
                </div>
            </div>

            <!-- Error state -->
            <div id="fsError" class="vsfs-error" hidden>
                <p>Không thể tải thông tin sân. Vui lòng thử lại.</p>
                <button type="button" id="fsRetryBtn" class="vsfs-btn vsfs-btn-ghost">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/></svg>
                    Thử lại
                </button>
            </div>

            <!-- Loaded content -->
            <div id="fsContent" hidden>
                <div class="vsfs-cols">
                    <div class="vsfs-hero"><img id="fsHeroImg" src="" alt=""></div>
                    <div style="min-width:0;">
                        <h2 class="vsfs-name" id="fsName"></h2>
                        <div class="vsfs-chips" id="fsChips"></div>
                        <div class="vsfs-meta" id="fsMeta"></div>
                        <p class="vsfs-price" id="fsPrice" hidden></p>
                    </div>
                </div>

                <div class="vsfs-tabs" role="tablist" aria-label="Thông tin chi tiết cơ sở" id="fsTablist">
                    <button type="button" class="vsfs-tab" role="tab" id="fsTab-overview" aria-controls="fsPanel-overview" aria-selected="true" data-fstab="overview">Tổng quan</button>
                    <button type="button" class="vsfs-tab" role="tab" id="fsTab-courts" aria-controls="fsPanel-courts" aria-selected="false" data-fstab="courts">Sân &amp; bảng giá</button>
                    <button type="button" class="vsfs-tab" role="tab" id="fsTab-services" aria-controls="fsPanel-services" aria-selected="false" data-fstab="services">Dịch vụ</button>
                    <button type="button" class="vsfs-tab" role="tab" id="fsTab-shop" aria-controls="fsPanel-shop" aria-selected="false" data-fstab="shop" hidden>Cửa hàng</button>
                    <button type="button" class="vsfs-tab" role="tab" id="fsTab-images" aria-controls="fsPanel-images" aria-selected="false" data-fstab="images">Hình ảnh</button>
                    <button type="button" class="vsfs-tab" role="tab" id="fsTab-policy" aria-controls="fsPanel-policy" aria-selected="false" data-fstab="policy">Chính sách</button>
                </div>
                <div class="vsfs-panel" role="tabpanel" id="fsPanel-overview" aria-labelledby="fsTab-overview" tabindex="0"></div>
                <div class="vsfs-panel" role="tabpanel" id="fsPanel-courts" aria-labelledby="fsTab-courts" tabindex="0" hidden></div>
                <div class="vsfs-panel" role="tabpanel" id="fsPanel-services" aria-labelledby="fsTab-services" tabindex="0" hidden></div>
                <div class="vsfs-panel" role="tabpanel" id="fsPanel-shop" aria-labelledby="fsTab-shop" tabindex="0" hidden>
                    <div id="fsShopLoading" class="vsfs-shop-grid">
                        <div class="vsx-skel" style="height:160px;border-radius:12px;"></div>
                        <div class="vsx-skel" style="height:160px;border-radius:12px;"></div>
                    </div>
                    <div id="fsShopEmpty" hidden><p>Cơ sở đang cập nhật sản phẩm. Vui lòng quay lại sau.</p></div>
                    <div id="fsShopError" hidden>
                        <p>Không thể tải danh sách sản phẩm.</p>
                        <button type="button" id="fsShopRetryBtn" class="vsfs-btn vsfs-btn-ghost">Thử lại</button>
                    </div>
                    <div id="fsShopGrid" class="vsfs-shop-grid" hidden></div>
                </div>
                <div class="vsfs-panel" role="tabpanel" id="fsPanel-images" aria-labelledby="fsTab-images" tabindex="0" hidden></div>
                <div class="vsfs-panel" role="tabpanel" id="fsPanel-policy" aria-labelledby="fsTab-policy" tabindex="0" hidden>
                    <p style="font-size:12px;font-weight:800;text-transform:uppercase;letter-spacing:.04em;color:var(--vsx-muted);margin-bottom:10px;">Chính sách chung của V-SPORT</p>
                    <div class="vsfs-policy-item">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/></svg>
                        <span>Hủy sân miễn phí khi hủy trước giờ bắt đầu ít nhất 6 tiếng (áp dụng cho đơn chờ xác nhận).</span>
                    </div>
                    <div class="vsfs-policy-item">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                        <span>Thanh toán online qua PayOS: sân được giữ chỗ trong 10 phút chờ thanh toán.</span>
                    </div>
                    <div class="vsfs-policy-item">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1 1 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="m9 12 2 2 4-4"/></svg>
                        <span>Hủy sát giờ hoặc không đến sân sẽ ảnh hưởng điểm uy tín người chơi của bạn.</span>
                    </div>
                    <div class="vsfs-policy-item">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/></svg>
                        <span>Mỗi tài khoản đặt tối đa 3 ca hoạt động trong cùng một ngày trên toàn hệ thống.</span>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="vsfs-actionbar">
        <div class="vsfs-actionbar-inner">
            <a id="fsCallBtn" class="vsfs-btn vsfs-btn-ghost" href="#" hidden>
                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384"/></svg>
                Gọi cơ sở
            </a>
            <a id="fsMapActionBtn" class="vsfs-btn vsfs-btn-ghost" href="${ctx}/customer/ban-do">
                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14.106 5.553a2 2 0 0 0 1.788 0l3.659-1.83A1 1 0 0 1 21 4.619v12.764a1 1 0 0 1-.553.894l-4.553 2.277a2 2 0 0 1-1.788 0l-4.212-2.106a2 2 0 0 0-1.788 0l-3.659 1.83A1 1 0 0 1 3 19.381V6.618a1 1 0 0 1 .553-.894l4.553-2.277a2 2 0 0 1 1.788 0z"/><path d="M15 5.764v15"/><path d="M9 3.236v15"/></svg>
                Xem bản đồ
            </a>
            <button type="button" id="fsBookBtn" class="vsfs-btn vsfs-btn-primary">
                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="m9 16 2 2 4-4"/></svg>
                Đặt sân
            </button>
        </div>
    </div>
</section>

<script>
    window.VSPORT_CONTEXT_PATH = window.VSPORT_CONTEXT_PATH || '${ctx}';
    (function () {
        'use strict';
        const CTX = window.VSPORT_CONTEXT_PATH;
        const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

        // ---- Shared toast (exposed globally so host pages can reuse it) ----
        let vsHomeToastTimer = null;
        function showHomeToast(msg) {
            const toast = document.getElementById('vsHomeToast');
            if (!toast) return;
            toast.textContent = msg;
            toast.style.opacity = '1';
            toast.style.visibility = 'visible';
            toast.style.transform = 'translateX(-50%) translateY(0)';
            clearTimeout(vsHomeToastTimer);
            vsHomeToastTimer = setTimeout(() => {
                toast.style.opacity = '0';
                toast.style.transform = 'translateX(-50%) translateY(12px)';
                setTimeout(() => { toast.style.visibility = 'hidden'; }, 220);
            }, 2000);
        }
        window.showHomeToast = showHomeToast;

        // ---- Shared helpers -------------------------------------------------
        let scrollLocks = 0;
        function lockScroll()   { scrollLocks++; document.body.style.overflow = 'hidden'; }
        function unlockScroll() { scrollLocks = Math.max(0, scrollLocks - 1); if (!scrollLocks) document.body.style.overflow = ''; }

        function focusables(container) {
            return Array.from(container.querySelectorAll(
                'a[href], button:not([disabled]), input, select, textarea, [tabindex]:not([tabindex="-1"])'
            )).filter(el => !el.hidden && el.offsetParent !== null);
        }
        function trapTab(container, e) {
            if (e.key !== 'Tab') return;
            const list = focusables(container);
            if (!list.length) { e.preventDefault(); return; }
            const first = list[0], last = list[list.length - 1];
            if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
            else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
        }
        function fmtVnd(n) {
            if (typeof n !== 'number' || !isFinite(n) || n <= 0) return null;
            return new Intl.NumberFormat('vi-VN').format(Math.round(n)) + 'đ';
        }
        function resolveImg(v) {
            if (!v) return null;
            if (v.startsWith('http://') || v.startsWith('https://')) return v;
            return CTX + (v.startsWith('/') ? v : '/' + v);
        }

        // ================= Booking-choice modal =============================
        const bcBackdrop = document.getElementById('bookingChoiceBackdrop');
        const bcModal = document.getElementById('bookingChoiceModal');
        const bcClose = document.getElementById('bcCloseBtn');
        const bcDirect = document.getElementById('bcOptionDirect');
        const bcMatch = document.getElementById('bcOptionMatch');
        const bcName = document.getElementById('bcFacilityName');
        let bcReturnFocus = null;
        let bcOpen = false;

        function openBookingChoice(cosoId, facilityName, triggerEl) {
            if (bcOpen) return;
            bcOpen = true;
            bcReturnFocus = triggerEl || document.activeElement;
            // Option 1 hướng người dùng thẳng đến trang "Đặt lịch trực quan" theo đúng cơ sở
            // vừa chọn — timetable court×time thay cho danh sách phẳng cũ.
            bcDirect.href = CTX + '/customer/dat-lich-truc-quan?coSoId=' + encodeURIComponent(cosoId);
            bcMatch.href = CTX + '/customer/ghep-keo?tab=tao-keo&coSoId=' + encodeURIComponent(cosoId);
            bcName.textContent = facilityName || '';
            bcBackdrop.hidden = false;
            bcModal.hidden = false;
            requestAnimationFrame(() => {
                bcBackdrop.classList.add('is-open');
                bcModal.classList.add('is-open');
            });
            lockScroll();
            bcDirect.focus();
        }
        function closeBookingChoice() {
            if (!bcOpen) return;
            bcOpen = false;
            bcBackdrop.classList.remove('is-open');
            bcModal.classList.remove('is-open');
            const done = () => { bcBackdrop.hidden = true; bcModal.hidden = true; };
            reduceMotion ? done() : setTimeout(done, 210);
            unlockScroll();
            if (bcReturnFocus && document.contains(bcReturnFocus)) bcReturnFocus.focus();
            bcReturnFocus = null;
        }
        window.openBookingChoice = openBookingChoice;
        bcClose.addEventListener('click', closeBookingChoice);
        bcBackdrop.addEventListener('click', closeBookingChoice);
        bcModal.addEventListener('keydown', e => trapTab(bcModal, e));

        // ---- Step-transition loading overlay (full màn hình, chỉ hiện sau khi user
        // thật sự chọn một option — không hiện khi mở modal/hover/focus/đóng modal). ----
        function showStepLoading(title) {
            const el = document.getElementById('vsBookingLoading');
            if (!el) return;
            document.getElementById('vsBookingLoadingTitle').textContent = title || '';
            document.body.style.overflow = 'hidden';
            el.classList.add('is-visible');
            el.setAttribute('aria-busy', 'true');
        }
        window.vsHideStepLoading = function () {
            const el = document.getElementById('vsBookingLoading');
            if (el) { el.classList.remove('is-visible'); el.removeAttribute('aria-busy'); }
            document.body.style.overflow = '';
        };

        // Khôi phục hai option về trạng thái bấm được (dùng cho fallback lỗi + Back).
        let vsNavFallbackTimer = null;
        function enableBookingOptions() {
            clearTimeout(vsNavFallbackTimer);
            [bcDirect, bcMatch].forEach(el => {
                delete el.dataset.navigating;
                el.classList.remove('is-pressed');
                el.removeAttribute('aria-disabled');
                el.style.pointerEvents = '';
            });
        }
        window.enableBookingOptions = enableBookingOptions;

        // Khi trang được hiển thị lại (bấm Back, kể cả bfcache) — không để loader kẹt
        // và cho phép chọn lại option. pageshow luôn chạy khi trang quay lại tiền cảnh.
        window.addEventListener('pageshow', function () {
            window.vsHideStepLoading();
            enableBookingOptions();
        });

        // Luồng nhấn: press ngay lập tức -> khóa chống double-click -> giữ trạng thái
        // lún ~130ms để người dùng thấy -> hiện loader toàn màn hình -> giữ thêm
        // ~220ms -> điều hướng. Tổng thời gian trước khi chuyển trang ~350ms.
        function pressThenNavigate(el, loadingTitle) {
            if (el.dataset.navigating === '1') return;
            el.dataset.navigating = '1';
            el.classList.add('is-pressed');
            // Khóa cả hai option ngay để chống double-click tạo nhiều request.
            [bcDirect, bcMatch].forEach(o => { o.setAttribute('aria-disabled', 'true'); o.style.pointerEvents = 'none'; });
            const href = el.href;
            const pressDelay = reduceMotion ? 0 : 130;
            const loaderDelay = reduceMotion ? 0 : 220;
            setTimeout(() => {
                el.classList.remove('is-pressed');
                showStepLoading(loadingTitle);
                setTimeout(() => {
                    window.location.assign(href);
                    // Fallback: nếu điều hướng không xảy ra (lỗi mạng/route) trong ~8s,
                    // ẩn loader, mở lại option và báo lỗi ngắn thay vì để màn hình treo.
                    clearTimeout(vsNavFallbackTimer);
                    vsNavFallbackTimer = setTimeout(function () {
                        window.vsHideStepLoading();
                        enableBookingOptions();
                        if (window.showHomeToast) window.showHomeToast('Không thể mở trang. Vui lòng thử lại.');
                    }, 8000);
                }, loaderDelay);
            }, pressDelay);
        }
        bcDirect.addEventListener('click', e => { e.preventDefault(); pressThenNavigate(bcDirect, bcDirect.dataset.loadingLabel); });
        bcMatch.addEventListener('click', e => { e.preventDefault(); pressThenNavigate(bcMatch, bcMatch.dataset.loadingLabel); });
        [bcDirect, bcMatch].forEach(el => {
            el.addEventListener('keydown', e => {
                if (e.key === ' ') { e.preventDefault(); el.click(); }
            });
        });

        // ================= Facility detail bottom sheet =====================
        const fsOverlay = document.getElementById('facilitySheetOverlay');
        const fsSheet = document.getElementById('facilitySheet');
        const fsSkeleton = document.getElementById('fsSkeleton');
        const fsErrorBox = document.getElementById('fsError');
        const fsContent = document.getElementById('fsContent');
        const detailCache = new Map();
        const shopCache = new Map();
        let fsOpen = false;
        let fsReturnFocus = null;
        let fsAbort = null;
        let fsShopAbort = null;
        let fsCurrentId = null;
        let fsCurrentName = '';
        let fsCardImage = null;
        let fsCurrentPhone = null;
        let fsPushedState = false;

        function openFacilitySheet(card) {
            const cosoId = card.getAttribute('data-coso-id');
            if (!cosoId) return;
            fsReturnFocus = card;
            fsCurrentId = cosoId;
            fsCurrentName = card.getAttribute('data-facility-name') || '';
            fsCardImage = card.getAttribute('data-card-image') || null;
            fsOpen = true;
            fsOverlay.hidden = false;
            fsSheet.hidden = false;
            fsSheet.style.transform = '';
            requestAnimationFrame(() => {
                fsOverlay.classList.add('is-open');
                fsSheet.classList.add('is-open');
            });
            lockScroll();
            document.getElementById('fsCloseBtn').focus();
            try {
                history.pushState({ vsFacilitySheet: true }, '');
                fsPushedState = true;
            } catch (e) { fsPushedState = false; }
            loadFacilityDetail(cosoId);
        }
        window.openFacilitySheet = openFacilitySheet;

        function closeFacilitySheet(fromPopstate) {
            if (!fsOpen) return;
            fsOpen = false;
            if (fsAbort) { fsAbort.abort(); fsAbort = null; }
            if (fsShopAbort) { fsShopAbort.abort(); fsShopAbort = null; }
            fsOverlay.classList.remove('is-open');
            fsSheet.classList.remove('is-open');
            fsSheet.style.transform = '';
            const done = () => { fsOverlay.hidden = true; fsSheet.hidden = true; };
            reduceMotion ? done() : setTimeout(done, 320);
            unlockScroll();
            if (fsReturnFocus && document.contains(fsReturnFocus)) fsReturnFocus.focus();
            fsReturnFocus = null;
            if (fsPushedState && !fromPopstate) {
                fsPushedState = false;
                try { history.back(); } catch (e) { /* noop */ }
            } else {
                fsPushedState = false;
            }
        }
        window.addEventListener('popstate', () => { if (fsOpen) closeFacilitySheet(true); });

        function showSheetState(state) {
            fsSkeleton.hidden = state !== 'loading';
            fsErrorBox.hidden = state !== 'error';
            fsContent.hidden = state !== 'content';
        }

        function loadFacilityDetail(cosoId) {
            showSheetState('loading');
            if (detailCache.has(cosoId)) {
                renderFacilityDetail(detailCache.get(cosoId));
                return;
            }
            if (fsAbort) fsAbort.abort();
            fsAbort = new AbortController();
            fetch(CTX + '/api/customer/facilities/detail?coSoId=' + encodeURIComponent(cosoId), { signal: fsAbort.signal })
                .then(r => {
                    if (!r.ok) throw new Error('HTTP ' + r.status);
                    return r.json();
                })
                .then(data => {
                    detailCache.set(cosoId, data);
                    if (fsOpen && fsCurrentId === cosoId) renderFacilityDetail(data);
                })
                .catch(err => {
                    if (err && err.name === 'AbortError') return;
                    if (fsOpen && fsCurrentId === cosoId) showSheetState('error');
                });
        }
        document.getElementById('fsRetryBtn').addEventListener('click', () => {
            if (fsCurrentId) { detailCache.delete(fsCurrentId); loadFacilityDetail(fsCurrentId); }
        });

        // ---- Rendering (textContent only, no innerHTML with server data) ----
        function el(tag, className, text) {
            const node = document.createElement(tag);
            if (className) node.className = className;
            if (text != null) node.textContent = text;
            return node;
        }
        function metaRow(iconPath, text) {
            const row = el('div', 'vsfs-meta-row');
            const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
            svg.setAttribute('class', 'lci');
            svg.setAttribute('viewBox', '0 0 24 24');
            svg.setAttribute('fill', 'none');
            svg.setAttribute('stroke', 'currentColor');
            svg.setAttribute('stroke-width', '2');
            svg.setAttribute('stroke-linecap', 'round');
            svg.setAttribute('stroke-linejoin', 'round');
            svg.setAttribute('aria-hidden', 'true');
            iconPath.split('|').forEach(d => {
                const p = document.createElementNS('http://www.w3.org/2000/svg', 'path');
                p.setAttribute('d', d);
                svg.appendChild(p);
            });
            row.appendChild(svg);
            row.appendChild(el('span', null, text));
            return row;
        }
        const IC_PIN = 'M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0|M15 10a3 3 0 1 1-6 0 3 3 0 0 1 6 0';
        const IC_CLOCK = 'M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20|M12 6v6l4 2';
        const IC_PHONE = 'M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384';
        const IC_INFO = 'M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20|M12 16v-4|M12 8h.01';

        function renderFacilityDetail(data) {
            const hero = document.getElementById('fsHeroImg');
            const heroSrc = resolveImg(data.imageUrl) || fsCardImage;
            hero.onerror = fsCardImage ? function () { this.onerror = null; this.src = fsCardImage; } : null;
            hero.src = heroSrc || '';
            hero.alt = data.tenCoSo || '';

            document.getElementById('fsName').textContent = data.tenCoSo || '';

            const chips = document.getElementById('fsChips');
            chips.textContent = '';
            if (typeof data.openNow === 'boolean') {
                chips.appendChild(el('span', 'vsfs-chip' + (data.openNow ? '' : ' is-warn'), data.openNow ? 'Đang mở' : 'Ngoài giờ mở cửa'));
            }
            if (typeof data.readyCourtCount === 'number' && data.readyCourtCount > 0) {
                chips.appendChild(el('span', 'vsfs-chip is-ready', 'Còn ' + data.readyCourtCount + ' sân sẵn sàng'));
            }
            (Array.isArray(data.sports) ? data.sports : []).forEach(s => chips.appendChild(el('span', 'vsfs-chip', s)));
            if (Array.isArray(data.services) && data.services.length) {
                chips.appendChild(el('span', 'vsfs-chip', 'Có dịch vụ'));
            }

            const meta = document.getElementById('fsMeta');
            meta.textContent = '';
            if (data.address) meta.appendChild(metaRow(IC_PIN, data.address));
            if (data.openingTime && data.closingTime) meta.appendChild(metaRow(IC_CLOCK, data.openingTime + ' - ' + data.closingTime));
            if (data.phone) meta.appendChild(metaRow(IC_PHONE, data.phone));

            const priceEl = document.getElementById('fsPrice');
            const minPrice = fmtVnd(data.minPrice);
            priceEl.hidden = !minPrice;
            if (minPrice) priceEl.textContent = 'Giá từ ' + minPrice + '/giờ';

            const ov = document.getElementById('fsPanel-overview');
            ov.textContent = '';
            ov.appendChild(el('p', null, data.description || 'Thông tin này đang được cơ sở cập nhật.'));
            const ovMeta = el('div', 'vsfs-meta');
            ovMeta.style.marginTop = '12px';
            if (data.address) ovMeta.appendChild(metaRow(IC_PIN, data.address));
            if (data.openingTime && data.closingTime) ovMeta.appendChild(metaRow(IC_CLOCK, 'Giờ hoạt động: ' + data.openingTime + ' - ' + data.closingTime));
            if (data.phone) ovMeta.appendChild(metaRow(IC_PHONE, 'Liên hệ: ' + data.phone));
            if (Array.isArray(data.sports) && data.sports.length) ovMeta.appendChild(metaRow(IC_INFO, 'Môn thể thao: ' + data.sports.join(', ')));
            ov.appendChild(ovMeta);
            const ovHasCoords = typeof data.latitude === 'number' && typeof data.longitude === 'number'
                && (data.latitude !== 0 || data.longitude !== 0);
            const mapLink = el('a', 'vsfs-court-cta', 'Xem trên bản đồ');
            mapLink.href = ovHasCoords
                ? CTX + '/customer/ban-do?facilityId=' + encodeURIComponent(fsCurrentId)
                : CTX + '/customer/ban-do';
            mapLink.style.marginTop = '14px';
            mapLink.style.display = 'inline-flex';
            ov.appendChild(mapLink);

            const courtsPanel = document.getElementById('fsPanel-courts');
            courtsPanel.textContent = '';
            const courts = Array.isArray(data.courts) ? data.courts : [];
            if (courts.length) {
                courts.forEach(c => {
                    const row = el('div', 'vsfs-court');
                    const left = el('div');
                    left.style.minWidth = '0';
                    const nameLine = el('div', 'vsfs-court-name', c.tenSan || '');
                    if (c.trangThai) {
                        nameLine.appendChild(el('span',
                            'vsfs-status ' + (c.trangThai === 'Sẵn sàng' ? 'is-ready' : 'is-other'), c.trangThai));
                    }
                    left.appendChild(nameLine);
                    const subParts = [];
                    if (c.loaiSan) subParts.push(c.loaiSan);
                    if (c.monTheThao) subParts.push(c.monTheThao);
                    if (subParts.length) left.appendChild(el('div', 'vsfs-court-sub', subParts.join(' · ')));
                    row.appendChild(left);

                    const right = el('div');
                    right.style.display = 'flex';
                    right.style.alignItems = 'center';
                    right.style.gap = '12px';
                    const gia = fmtVnd(c.giaKhongDen);
                    const giaDen = fmtVnd(c.giaCoDen);
                    if (gia) {
                        right.appendChild(el('span', 'vsfs-court-price',
                            giaDen && giaDen !== gia ? gia + ' - ' + giaDen + '/giờ' : gia + '/giờ'));
                    }
                    const cta = el('a', 'vsfs-court-cta', 'Đặt sân');
                    cta.href = CTX + '/customer/chi-tiet-san?id=' + encodeURIComponent(c.sanId);
                    right.appendChild(cta);
                    row.appendChild(right);
                    courtsPanel.appendChild(row);
                });
            } else {
                courtsPanel.appendChild(el('p', null, 'Thông tin này đang được cơ sở cập nhật.'));
            }

            const services = Array.isArray(data.services) ? data.services : [];
            const svTab = document.getElementById('fsTab-services');
            const svPanel = document.getElementById('fsPanel-services');
            svPanel.textContent = '';
            svTab.hidden = !services.length;
            services.forEach(s => {
                const row = el('div', 'vsfs-service');
                row.appendChild(el('span', null, s.tenSanPham || ''));
                const price = fmtVnd(s.donGia);
                row.appendChild(el('b', null, price ? price + (s.donViTinh ? '/' + s.donViTinh : '') : (s.donViTinh || '')));
                svPanel.appendChild(row);
            });

            const images = (Array.isArray(data.images) ? data.images : []).map(resolveImg).filter(Boolean);
            const imgTab = document.getElementById('fsTab-images');
            const imgPanel = document.getElementById('fsPanel-images');
            imgPanel.textContent = '';
            imgTab.hidden = !images.length;
            if (images.length) {
                const grid = el('div', 'vsfs-imggrid');
                images.forEach(src => {
                    const img = document.createElement('img');
                    img.loading = 'lazy';
                    img.alt = data.tenCoSo || '';
                    img.onerror = function () { this.remove(); };
                    img.src = src;
                    grid.appendChild(img);
                });
                imgPanel.appendChild(grid);
            }

            const mapBtn = document.getElementById('fsMapBtn');
            const hasCoords = typeof data.latitude === 'number' && typeof data.longitude === 'number'
                && (data.latitude !== 0 || data.longitude !== 0);
            mapBtn.hidden = !hasCoords;
            mapBtn.href = CTX + '/customer/ban-do?facilityId=' + encodeURIComponent(fsCurrentId);

            const mapActionBtn = document.getElementById('fsMapActionBtn');
            if (mapActionBtn) {
                mapActionBtn.href = hasCoords
                    ? CTX + '/customer/ban-do?facilityId=' + encodeURIComponent(fsCurrentId)
                    : CTX + '/customer/ban-do';
                mapActionBtn.title = hasCoords ? '' : 'Cơ sở chưa cập nhật vị trí';
            }

            const callBtn = document.getElementById('fsCallBtn');
            callBtn.hidden = !data.phone;
            if (data.phone) callBtn.href = 'tel:' + String(data.phone).replace(/[^+\d]/g, '');
            fsCurrentPhone = data.phone || null;

            // Tab Cửa hàng chỉ hiện khi backend xác nhận capability đã duyệt. Sản phẩm
            // thật được lazy-load riêng (loadShopProducts) khi Customer bấm vào tab -
            // không tải kèm ở đây để tránh phí request cho cơ sở không bán hàng.
            document.getElementById('fsTab-shop').hidden = !data.shopAvailable;

            selectSheetTab('overview');
            showSheetState('content');
        }

        // ---- Cửa hàng (Phase 4, lazy-loaded) --------------------------------
        function showShopState(state) {
            document.getElementById('fsShopLoading').hidden = state !== 'loading';
            document.getElementById('fsShopEmpty').hidden = state !== 'empty';
            document.getElementById('fsShopError').hidden = state !== 'error';
            document.getElementById('fsShopGrid').hidden = state !== 'content';
        }

        function loadShopProducts(cosoId) {
            if (shopCache.has(cosoId)) {
                renderShopProducts(shopCache.get(cosoId));
                return;
            }
            showShopState('loading');
            if (fsShopAbort) fsShopAbort.abort();
            fsShopAbort = new AbortController();
            fetch(CTX + '/api/customer/facilities/shop?coSoId=' + encodeURIComponent(cosoId), { signal: fsShopAbort.signal })
                .then(r => { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); })
                .then(data => {
                    shopCache.set(cosoId, data);
                    if (fsOpen && fsCurrentId === cosoId) renderShopProducts(data);
                })
                .catch(err => {
                    if (err && err.name === 'AbortError') return;
                    if (fsOpen && fsCurrentId === cosoId) showShopState('error');
                });
        }
        document.getElementById('fsShopRetryBtn').addEventListener('click', () => {
            if (fsCurrentId) { shopCache.delete(fsCurrentId); loadShopProducts(fsCurrentId); }
        });

        const STOCK_LABEL = { CON_HANG: 'Còn hàng', SAP_HET: 'Sắp hết hàng', HET_HANG: 'Hết hàng' };
        const STOCK_CLASS = { CON_HANG: 'is-in', SAP_HET: 'is-low', HET_HANG: 'is-out' };
        const IC_BAG = 'M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z|M3 6h18|M16 10a4 4 0 0 1-8 0';

        function renderShopProducts(data) {
            const products = (data && Array.isArray(data.products)) ? data.products : [];
            const grid = document.getElementById('fsShopGrid');
            grid.textContent = '';
            if (!data || !data.available) { showShopState('empty'); return; }
            if (!products.length) { showShopState('empty'); return; }

            products.forEach(p => {
                const card = el('div', 'vsfs-product');

                const imgWrap = el('div', 'vsfs-product-img');
                const imgSrc = resolveImg(p.image);
                if (imgSrc) {
                    const img = document.createElement('img');
                    img.loading = 'lazy';
                    img.alt = p.name || '';
                    img.onerror = function () { this.remove(); imgWrap.appendChild(bagIcon()); };
                    img.src = imgSrc;
                    imgWrap.appendChild(img);
                } else {
                    imgWrap.appendChild(bagIcon());
                }
                card.appendChild(imgWrap);

                const body = el('div', 'vsfs-product-body');
                if (p.category) body.appendChild(el('span', 'vsfs-product-cat', p.category));
                body.appendChild(el('span', 'vsfs-product-name', p.name || ''));
                const stockKey = STOCK_LABEL[p.stockStatus] ? p.stockStatus : 'HET_HANG';
                body.appendChild(el('span', 'vsfs-product-stock ' + STOCK_CLASS[stockKey], STOCK_LABEL[stockKey]));
                const price = fmtVnd(p.price);
                if (price) body.appendChild(el('span', 'vsfs-product-price', price + (p.unit ? '/' + p.unit : '')));

                // Giai đoạn 1 (liên hệ mua tại cơ sở) - chưa có giỏ hàng/thanh toán online
                // thật, nên KHÔNG hiện nút "Mua ngay" giả. Chỉ đưa số điện thoại cơ sở.
                if (p.stockStatus !== 'HET_HANG') {
                    const contactBtn = document.createElement(fsCurrentPhone ? 'a' : 'span');
                    contactBtn.className = 'vsfs-product-contact';
                    contactBtn.textContent = fsCurrentPhone ? 'Liên hệ đặt mua' : 'Đến trực tiếp cơ sở để mua';
                    if (fsCurrentPhone) {
                        contactBtn.href = 'tel:' + String(fsCurrentPhone).replace(/[^+\d]/g, '');
                        contactBtn.setAttribute('aria-label', 'Gọi cơ sở để đặt mua ' + (p.name || 'sản phẩm này'));
                    }
                    body.appendChild(contactBtn);
                }
                card.appendChild(body);

                grid.appendChild(card);
            });
            showShopState('content');
        }

        function bagIcon() {
            const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
            svg.setAttribute('class', 'lci');
            svg.setAttribute('viewBox', '0 0 24 24');
            svg.setAttribute('fill', 'none');
            svg.setAttribute('stroke', 'currentColor');
            svg.setAttribute('stroke-width', '2');
            svg.setAttribute('stroke-linecap', 'round');
            svg.setAttribute('stroke-linejoin', 'round');
            svg.setAttribute('aria-hidden', 'true');
            IC_BAG.split('|').forEach(d => {
                const p = document.createElementNS('http://www.w3.org/2000/svg', 'path');
                p.setAttribute('d', d);
                svg.appendChild(p);
            });
            return svg;
        }

        // ---- Tabs -----------------------------------------------------------
        const tabButtons = Array.from(document.querySelectorAll('.vsfs-tab'));
        function selectSheetTab(key) {
            tabButtons.forEach(btn => {
                const selected = btn.getAttribute('data-fstab') === key;
                btn.setAttribute('aria-selected', selected ? 'true' : 'false');
                document.getElementById('fsPanel-' + btn.getAttribute('data-fstab')).hidden = !selected;
            });
            if (key === 'shop' && fsCurrentId) loadShopProducts(fsCurrentId);
        }
        tabButtons.forEach((btn, idx) => {
            btn.addEventListener('click', () => selectSheetTab(btn.getAttribute('data-fstab')));
            btn.addEventListener('keydown', e => {
                if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return;
                e.preventDefault();
                const visible = tabButtons.filter(b => !b.hidden);
                const pos = visible.indexOf(btn);
                const next = visible[(pos + (e.key === 'ArrowRight' ? 1 : visible.length - 1)) % visible.length];
                next.focus();
                selectSheetTab(next.getAttribute('data-fstab'));
            });
        });

        // ---- Sheet header buttons ------------------------------------------
        document.getElementById('fsCloseBtn').addEventListener('click', () => closeFacilitySheet(false));
        fsOverlay.addEventListener('click', () => closeFacilitySheet(false));
        fsSheet.addEventListener('keydown', e => trapTab(fsSheet, e));
        document.getElementById('fsFavBtn').addEventListener('click', function () {
            this.classList.toggle('is-fav');
            showHomeToast(this.classList.contains('is-fav') ? 'Đã thêm vào danh sách yêu thích' : 'Đã bỏ lưu cơ sở');
        });
        document.getElementById('fsShareBtn').addEventListener('click', function () {
            const url = window.location.origin + CTX + '/customer/dat-lich-truc-quan?coSoId=' + encodeURIComponent(fsCurrentId || '');
            if (navigator.clipboard) {
                navigator.clipboard.writeText(url)
                    .then(() => showHomeToast('Đã sao chép liên kết chia sẻ cơ sở ' + fsCurrentName))
                    .catch(() => showHomeToast('Không thể sao chép liên kết'));
            } else {
                showHomeToast('Trình duyệt không hỗ trợ sao chép liên kết');
            }
        });
        document.getElementById('fsBookBtn').addEventListener('click', function () {
            const cosoId = fsCurrentId;
            const name = fsCurrentName;
            const returnTo = fsReturnFocus;
            closeFacilitySheet(false);
            const wait = reduceMotion ? 0 : 240;
            setTimeout(() => openBookingChoice(cosoId, name, returnTo), wait);
        });

        // ---- Escape closes topmost layer -----------------------------------
        document.addEventListener('keydown', e => {
            if (e.key !== 'Escape') return;
            if (bcOpen) { closeBookingChoice(); return; }
            if (fsOpen) closeFacilitySheet(false);
        });

        // ---- Drag-down to close (mobile) -----------------------------------
        (function initDrag() {
            const handle = document.getElementById('fsHandle');
            let startY = null, delta = 0, dragging = false;
            function onStart(e) {
                dragging = true;
                startY = (e.touches ? e.touches[0] : e).clientY;
                delta = 0;
                fsSheet.style.transition = 'none';
            }
            function onMove(e) {
                if (!dragging || startY == null) return;
                const y = (e.touches ? e.touches[0] : e).clientY;
                delta = Math.max(0, y - startY);
                fsSheet.style.transform = 'translateY(' + delta + 'px)';
            }
            function onEnd() {
                if (!dragging) return;
                dragging = false;
                fsSheet.style.transition = '';
                if (delta > 110) {
                    closeFacilitySheet(false);
                } else {
                    fsSheet.style.transform = '';
                }
                startY = null;
            }
            handle.addEventListener('touchstart', onStart, { passive: true });
            handle.addEventListener('touchmove', onMove, { passive: true });
            handle.addEventListener('touchend', onEnd);
            handle.addEventListener('mousedown', e => { onStart(e); e.preventDefault(); });
            document.addEventListener('mousemove', onMove);
            document.addEventListener('mouseup', onEnd);
        })();

        // ---- Wire up cards (delegation; no per-card modal instances) --------
        const grid = document.getElementById('facilityGrid');
        if (grid) {
            grid.addEventListener('click', e => {
                const bookBtn = e.target.closest('[data-book-trigger]');
                if (bookBtn) {
                    e.stopPropagation();
                    openBookingChoice(bookBtn.getAttribute('data-coso-id'), bookBtn.getAttribute('data-facility-name'), bookBtn);
                    return;
                }
                if (e.target.closest('button, a')) return; // favorite/share/other controls
                const card = e.target.closest('.facility-card');
                if (card) openFacilitySheet(card);
            });
            grid.addEventListener('keydown', e => {
                if (e.key !== 'Enter' && e.key !== ' ') return;
                const card = e.target.closest('.facility-card');
                if (card && e.target === card) {
                    e.preventDefault();
                    openFacilitySheet(card);
                }
            });
        }
    })();
</script>
