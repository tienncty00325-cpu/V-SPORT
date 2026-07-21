<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="repScoreNav" value="${account.diemUyTin}" />
<c:choose>
    <c:when test="${repScoreNav >= 80}"><c:set var="repLabelNav" value="Uy tín tốt" /><c:set var="repDotNav" value="#10b981" /></c:when>
    <c:when test="${repScoreNav >= 50}"><c:set var="repLabelNav" value="Cần theo dõi" /><c:set var="repDotNav" value="#d99a1b" /></c:when>
    <c:otherwise><c:set var="repLabelNav" value="Cần cải thiện" /><c:set var="repDotNav" value="#e15a5a" /></c:otherwise>
</c:choose>
<!DOCTYPE html>
<html lang="vi" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tài khoản của tôi - V-SPORT</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <jsp:include page="/common/head.jsp" />
    <jsp:include page="/customer/common/vsport-theme.jsp" />
    <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            /* 1024-1199px (tablet tier): ~300-330px. >=1200px: ~376-380px regardless of
               how wide the viewport gets beyond that (target spec is a fixed density,
               not a proportionally-scaling one at large desktop sizes). */
            --account-sidebar-width: clamp(300px, 26vw, 340px);
            --account-header-height: 54px;
            /* V-SPORT navy/blue/cyan account theme. Every color token below is scoped to
               this JSP's own <style>, so it recolors ONLY the customer account page and
               never leaks to other customer pages. Values point at the shared --vs-*
               tokens from vsport-theme.jsp so this page stays in sync with the brand. */
            --sidebar-bg: var(--vs-surface-soft, #EDF4FA);
            --sidebar-surface: #ffffff;
            --sidebar-border: var(--vs-border, #DCE5EF);
            --primary-dark: var(--vs-primary-900, #0B2545);
            --primary-mid: var(--vs-primary-600, #1677D2);
            --primary-bright: var(--vs-cyan-500, #18C8E8);
            --ink-green: var(--vs-text, #102A43);
            --muted-green: var(--vs-muted, #829AB1);
            --content-bg: var(--vs-background, #F4F7FB);
            --settings-icon: var(--vs-primary-600, #1677D2);
            --settings-text: var(--vs-text, #102A43);
            --settings-chev: var(--vs-muted, #829AB1);
            --settings-border: var(--vs-border, #DCE5EF);
        }
        @media (min-width: 1200px) {
            :root { --account-sidebar-width: 378px; }
        }
        body {
            font-family: 'Be Vietnam Pro', 'Inter', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif !important;
            background-color: #ffffff !important;
            color: var(--ink-green) !important;
            font-size: 14px;
            line-height: 1.4;
        }
        h1, h2, h3, h4, h5, h6 { font-family: inherit; }
        [hidden] { display: none !important; }

        /* Lucide inline icons */
        .lci { width: 20px; height: 20px; flex-shrink: 0; }

        /* ===================== App shell ===================== */
        .customer-account-shell {
            display: grid;
            grid-template-columns: minmax(0, 1fr);
            width: 100%;
            min-height: 100dvh;
        }
        @media (min-width: 1024px) {
            .customer-account-shell {
                grid-template-columns: var(--account-sidebar-width) minmax(0, 1fr);
            }
        }

        /* ===================== Sidebar ===================== */
        .account-sidebar {
            background: var(--sidebar-bg);
            border-right: 1px solid var(--sidebar-border);
            min-width: 0;
            /* Clip the decorative wave's ±6% horizontal bleed so it can't cause a
               horizontal scrollbar when the sidebar is full-width on mobile. */
            overflow-x: hidden;
        }
        .account-sidebar-scroll { display: flex; flex-direction: column; }
        @media (min-width: 1024px) {
            .account-sidebar-scroll {
                position: sticky;
                top: 0;
                max-height: calc(100dvh - var(--vs-bottomnav-h-desktop, 80px));
                overflow-y: auto;
            }
        }

        /* Green top section with soft wave bottom */
        .account-sidebar-top {
            position: relative;
            background: linear-gradient(160deg, var(--primary-dark) 0%, var(--primary-mid) 62%, var(--primary-bright) 100%);
            padding: 20px 16px 0;
            height: 230px;
        }
        .account-sidebar-top::after {
            content: "";
            position: absolute;
            left: -6%;
            right: -6%;
            bottom: -1px;
            height: 54px;
            background: var(--sidebar-bg);
            border-radius: 50% 50% 0 0 / 82% 82% 0 0;
        }

        /* Profile row (compact, amber border) */
        .side-profile-row {
            position: relative; z-index: 1;
            display: flex; align-items: center; gap: 10px;
            width: 100%; min-height: 56px; padding: 8px 10px;
            background: rgba(255, 255, 255, 0.15);
            border: 1px solid rgba(255, 255, 255, 0.45);
            border-radius: 8px;
            color: #fff; text-align: left; text-decoration: none; cursor: pointer;
            transition: background-color .15s ease;
        }
        .side-profile-row:hover, .side-profile-row:focus-visible { background: rgba(255, 255, 255, 0.2); }
        .side-profile-row:focus-visible { outline: 2px solid #fff; outline-offset: 2px; }
        .side-avatar {
            width: 42px; height: 42px; border-radius: 50%;
            object-fit: cover; flex-shrink: 0;
            background: rgba(255, 255, 255, 0.22);
            display: flex; align-items: center; justify-content: center;
            font-size: 17px; font-weight: 800; color: #fff;
            border: 2px solid rgba(255, 255, 255, 0.55);
        }
        .side-profile-name {
            font-size: 14.5px; font-weight: 700; line-height: 1.25;
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }
        .side-profile-email {
            font-size: 11px; font-weight: 400; color: rgba(255, 255, 255, 0.85);
            line-height: 1.3; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }
        .side-profile-row .lci-chev { width: 20px; height: 20px; margin-left: auto; color: rgba(255,255,255,.9); }

        /* Reputation row (replaces "membership tier") */
        .side-rep-row {
            position: relative; z-index: 1;
            display: flex; align-items: center; gap: 10px;
            width: 100%; min-height: 44px; padding: 0 14px;
            margin-top: 10px;
            background: rgba(255, 255, 255, 0.13);
            border: 1px solid rgba(255, 255, 255, 0.3);
            border-radius: 8px;
            color: #fff; font-size: 13px; font-weight: 700;
            text-align: left; cursor: pointer;
            transition: background-color .15s ease;
        }
        .side-rep-row:hover, .side-rep-row:focus-visible { background: rgba(255, 255, 255, 0.2); }
        .side-rep-row:focus-visible { outline: 2px solid #fff; outline-offset: 2px; }
        .side-rep-row .rep-score { font-weight: 800; }
        .side-rep-row .rep-label { font-size: 12px; font-weight: 600; color: rgba(255,255,255,.88); }
        .side-rep-row .lci-chev { width: 18px; height: 18px; margin-left: auto; color: rgba(255,255,255,.9); }

        /* Quick actions 4-up, overlapping the wave */
        .side-quick {
            position: relative; z-index: 2;
            margin: -34px 16px 0;
            background: var(--sidebar-surface);
            border: 1px solid var(--sidebar-border);
            border-radius: 12px;
            padding: 10px;
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 8px;
            box-shadow: 0 4px 16px rgba(11, 37, 69, 0.08);
        }
        .side-quick-item {
            display: flex; flex-direction: column; align-items: center; justify-content: center;
            gap: 7px; min-height: 84px; padding: 8px 4px;
            background: #fff; border: 1px solid #DCE5EF; border-radius: 8px;
            text-decoration: none; cursor: pointer;
            transition: border-color .15s ease, background-color .15s ease, transform .1s ease;
        }
        .side-quick-item:hover, .side-quick-item:focus-visible { border-color: var(--primary-bright); background: #EAF3FB; }
        .side-quick-item:focus-visible { outline: 2px solid var(--primary-mid); outline-offset: 1px; }
        .side-quick-item:active { transform: translateY(1px); }
        .side-quick-item .lci { width: 22px; height: 22px; }
        .side-quick-item span {
            font-size: 12px; font-weight: 600; color: var(--ink-green);
            text-align: center; line-height: 1.25;
        }
        @media (max-width: 380px) {
            .side-quick { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        }
        .qi-green  { color: var(--vs-primary-700, #185A9D); }
        .qi-amber  { color: #d97706; }
        .qi-blue   { color: var(--vs-cyan-600, #08A9CC); }
        .qi-rose   { color: #e11d48; }

        /* Menu groups */
        .side-group-label {
            font-size: 13px; font-weight: 700; color: var(--primary-dark);
            text-transform: uppercase; letter-spacing: .04em;
            margin: 18px 0 8px 16px; padding: 0 4px;
        }
        .side-group {
            margin: 0 16px;
            background: var(--sidebar-surface);
            border: 1px solid var(--sidebar-border);
            border-radius: 12px;
            overflow: hidden;
        }
        .side-menu-item {
            display: flex; align-items: center; gap: 11px;
            width: 100%; min-height: 44px; padding: 0 13px;
            background: transparent; border: none; border-left: 3px solid transparent;
            font-family: inherit; font-size: 13.5px; font-weight: 600; color: var(--ink-green);
            text-align: left; text-decoration: none; cursor: pointer;
            transition: background-color .15s ease;
        }
        .side-menu-item + .side-menu-item { border-top: 1px solid #E7F1F8; }
        .side-menu-item:hover, .side-menu-item:focus-visible { background: #EAF3FB; }
        .side-menu-item:focus-visible { outline: 2px solid var(--primary-mid); outline-offset: -2px; }
        .side-menu-item .lci { width: 22px; height: 22px; flex-shrink: 0; color: var(--primary-mid); }
        .side-menu-item .lci-chev { width: 18px; height: 18px; margin-left: auto; color: #9db5a8; }
        /* Active item: bolder text/icon only — no blue background, no left border (target). */
        .side-menu-item.is-current {
            background: transparent;
            border-left-color: transparent;
            color: var(--primary-dark);
            font-weight: 700;
        }
        .side-menu-item.is-current .lci { color: var(--primary-dark); }
        .side-menu-item.is-danger { color: #b91c1c; }
        .side-menu-item.is-danger .lci { color: #dc2626; }
        .side-menu-item.is-danger:hover { background: #fef2f2; }

        .side-version {
            margin: 18px 16px 20px;
            text-align: center;
            font-size: 12px; font-weight: 500; color: var(--muted-green);
        }

        /* ===================== Main workspace ===================== */
        .account-main {
            background: var(--content-bg);
            min-width: 0;
            display: flex;
            flex-direction: column;
        }
        .account-header {
            height: var(--account-header-height);
            flex-shrink: 0;
            background: linear-gradient(90deg, var(--primary-dark) 0%, var(--primary-mid) 55%, var(--primary-bright) 100%);
            display: flex; align-items: center; justify-content: center;
        }
        .account-header h1 {
            margin: 0; color: #fff;
            font-size: 18px; font-weight: 700; letter-spacing: .01em;
            line-height: var(--account-header-height);
        }
        .account-body {
            flex: 1;
            display: flex; flex-direction: column;
            padding: 15px 16px 32px;
        }
        @media (min-width: 1024px) { .account-body { padding: 16px 28px 40px; } }

        .acc-toolbar { display: flex; justify-content: flex-end; margin-bottom: 14px; }
        .btn-viewall {
            display: inline-flex; align-items: center; justify-content: center; gap: 8px;
            min-width: 158px; height: 42px; padding: 0 16px;
            background: #fff; color: var(--primary-dark);
            border: 1px solid var(--primary-mid); border-radius: 6px;
            font-size: 14px; font-weight: 700; text-decoration: none;
            transition: background-color .15s ease;
        }
        .btn-viewall:hover { background: #EAF3FB; }
        .btn-viewall .lci { width: 19px; height: 19px; }

        .acc-section { display: flex; flex-direction: column; }
        .acc-section[data-section="datlich"] { flex: 1; }

        /* Empty state, centered inside the MAIN column */
        .acc-empty {
            flex: 1;
            display: flex; flex-direction: column; align-items: center; justify-content: center;
            gap: 12px; min-height: 320px; text-align: center;
        }
        .acc-empty .lci { width: 44px; height: 44px; color: #B9D7EC; }
        .acc-empty p { font-size: 14.5px; font-weight: 600; color: var(--primary-dark); opacity: .75; }

        /* Booking list */
        .booking-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 12px; }
        .booking-item {
            display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 14px;
            padding: 16px 18px;
            background: #fff; border: 1px solid #DCE8F2; border-radius: 12px;
        }
        .booking-name { font-size: 15px; font-weight: 800; color: var(--ink-green); }
        .booking-meta { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; font-size: 13px; color: var(--muted-green); margin-top: 4px; }
        .booking-meta .lci { width: 15px; height: 15px; }
        .booking-time { display: flex; align-items: center; gap: 6px; font-size: 13.5px; font-weight: 700; color: var(--ink-green); margin-top: 6px; }
        .booking-time .lci { width: 16px; height: 16px; color: var(--primary-mid); }
        .booking-chip {
            display: inline-flex; align-items: center; padding: 3px 10px; margin-left: 10px;
            border-radius: 8px; font-size: 11.5px; font-weight: 700; border: 1px solid;
        }
        .chip-wait  { background: #fffbeb; color: #b45309; border-color: #fde68a; }
        .chip-ok    { background: #E5F7EF; color: #16A36A; border-color: #9BE0BF; }
        .chip-live  { background: #f5f3ff; color: #6d28d9; border-color: #ddd6fe; }
        .chip-muted { background: #f8fafc; color: #64748b; border-color: #e2e8f0; }
        .booking-actions { display: flex; gap: 8px; flex-shrink: 0; }
        .btn-urgent {
            display: inline-flex; align-items: center; gap: 6px; padding: 9px 14px;
            background: #fffbeb; color: #b45309; border: 1px solid #fcd34d; border-radius: 8px;
            font-size: 13px; font-weight: 700; cursor: pointer; white-space: nowrap;
            transition: background-color .15s ease;
        }
        .btn-urgent:hover { background: #fef3c7; }
        .btn-urgent .lci { width: 16px; height: 16px; }

        /* Overview (Tổng quan) */
        .ov-stats { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px; max-width: 560px; }
        .ov-stat { background: #fff; border: 1px solid #DCE8F2; border-radius: 12px; padding: 18px 20px; }
        .ov-stat .num { font-size: 30px; font-weight: 800; line-height: 1; color: var(--primary-dark); }
        .ov-stat .lbl { font-size: 12.5px; font-weight: 700; color: var(--muted-green); text-transform: uppercase; letter-spacing: .04em; margin-top: 8px; }
        .ov-actions { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 18px; }

        /* Reputation section (styles used by reputation-card.jsp) */
        .rep-card { background: #fff; border: 1px solid #DCE8F2; border-radius: 12px; padding: 22px; max-width: 860px; }
        .rep-chip { display: inline-flex; align-items: center; gap: 7px; padding: 5px 13px; border-radius: 9999px; font-size: 12.5px; font-weight: 700; }
        .rep-score-big { font-size: 44px; font-weight: 800; line-height: 1; color: var(--ink-green); }
        .rep-bar { width: 100%; height: 8px; border-radius: 9999px; background: #E7F1F8; overflow: hidden; }
        .rep-counts { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 10px; }
        .rep-count { text-align: center; background: #F7FAFC; border: 1px solid #E7F1F8; border-radius: 10px; padding: 12px 8px; }
        .rep-count b { display: block; font-size: 19px; font-weight: 800; color: var(--ink-green); }
        .rep-count span { font-size: 11px; font-weight: 700; color: var(--muted-green); text-transform: uppercase; letter-spacing: .03em; }
        .rep-how { background: #F7FAFC; border: 1px solid #E7F1F8; border-radius: 10px; padding: 14px 16px; }
        .rep-how p { display: flex; align-items: flex-start; gap: 8px; font-size: 13.5px; color: var(--vs-text-secondary, #486581); }
        .rep-how p + p { margin-top: 8px; }
        .rep-how .lci { width: 17px; height: 17px; margin-top: 1px; }

        /* Personal info */
        .info-card { background: #fff; border: 1px solid #DCE5EF; border-radius: 12px; padding: 22px; max-width: 860px; }
        .info-avatar-wrap { display: flex; align-items: center; gap: 16px; margin-bottom: 20px; }
        .info-avatar {
            width: 76px; height: 76px; border-radius: 50%; object-fit: cover;
            background: var(--primary-mid); color: #fff;
            display: flex; align-items: center; justify-content: center;
            font-size: 28px; font-weight: 800; flex-shrink: 0;
            border: 3px solid #DCE5EF;
        }
        .info-avatar-btn {
            display: inline-flex; align-items: center; gap: 7px; padding: 9px 14px;
            background: #fff; color: var(--primary-dark); border: 1px solid var(--primary-mid);
            border-radius: 8px; font-size: 13px; font-weight: 700; cursor: pointer;
            transition: background-color .15s ease;
        }
        .info-avatar-btn:hover { background: #EAF3FB; }
        .info-avatar-btn .lci { width: 17px; height: 17px; }

        .acc-field-view dt { font-size: 12px; font-weight: 700; color: var(--muted-green); text-transform: uppercase; letter-spacing: .03em; margin-bottom: 4px; }
        .acc-field-view dd { font-size: 14.5px; font-weight: 600; color: var(--ink-green); }
        .acc-input {
            width: 100%; height: 44px; padding: 0 14px; border-radius: 8px;
            border: 1px solid #DCE5EF; background: #fff; font-size: 14px; color: var(--ink-green);
            font-family: inherit;
            transition: border-color .15s ease, box-shadow .15s ease;
        }
        .acc-input:focus { outline: none; border-color: var(--primary-bright); box-shadow: 0 0 0 3px rgba(24, 200, 232, .28); }
        .acc-label { display: block; font-size: 12.5px; font-weight: 700; color: var(--vs-text-secondary, #486581); margin-bottom: 6px; }
        .btn-primary {
            display: inline-flex; align-items: center; justify-content: center; gap: 7px;
            background: var(--primary-mid); color: #fff; font-weight: 700; font-size: 14px;
            padding: 11px 18px; border-radius: 8px; text-decoration: none; cursor: pointer;
            font-family: inherit; border: none;
            transition: background-color .15s ease, transform .1s ease;
        }
        .btn-primary:hover { background: var(--primary-dark); }
        .btn-primary:active { transform: scale(.98); }
        .btn-primary:disabled { opacity: .6; cursor: not-allowed; }
        .btn-primary .lci { width: 17px; height: 17px; }
        .btn-secondary {
            display: inline-flex; align-items: center; justify-content: center; gap: 7px;
            background: #fff; color: var(--vs-text-secondary, #486581); font-weight: 700; font-size: 14px;
            padding: 11px 18px; border-radius: 8px; border: 1px solid #DCE5EF;
            text-decoration: none; cursor: pointer; font-family: inherit;
            transition: background-color .15s ease;
        }
        .btn-secondary:hover { background: #F7FAFC; }
        .btn-secondary .lci { width: 17px; height: 17px; }

        #accToast { transition: opacity .25s ease, transform .25s ease; }
        .pw-eye .eye-open { display: none; }
        .pw-eye.is-visible .eye-open { display: block; }
        .pw-eye.is-visible .eye-closed { display: none; }

        /* ===================== Cài đặt (Settings) ===================== */
        /* Each row is its own full-width card with a gap between — not one joined box. */
        .customer-settings-page .settings-card {
            background: transparent; border: none; border-radius: 0; overflow: visible;
            display: flex; flex-direction: column; gap: 15px;
            width: 100%; max-width: 1040px;
        }
        .customer-settings-page .settings-row {
            display: flex; align-items: center; gap: 12px;
            width: 100%; min-height: 46px; height: 46px; padding: 0 14px 0 16px;
            background: #fff; border: 1px solid var(--settings-border); border-radius: 8px;
            font-family: inherit; font-size: 14px; font-weight: 500; color: var(--settings-text);
            text-align: left; text-decoration: none; cursor: pointer;
            transition: border-color .15s ease, background-color .15s ease;
        }
        .customer-settings-page .settings-row:hover,
        .customer-settings-page .settings-row:focus-visible { border-color: var(--primary-bright); }
        .customer-settings-page .settings-row:focus-visible { outline: 2px solid var(--primary-mid); outline-offset: 1px; }
        .customer-settings-page .settings-row .lci { width: 20px; height: 20px; color: var(--settings-icon); stroke-width: 1.9; }
        .customer-settings-page .settings-row .lci-chev { width: 18px; height: 18px; margin-left: auto; color: var(--settings-chev); }
        .customer-settings-page .settings-row.is-danger { color: #FF2D35; }
        .customer-settings-page .settings-row.is-danger .lci,
        .customer-settings-page .settings-row.is-danger .lci-chev { color: #FF2D35; }
        .customer-settings-page .settings-row.is-danger:hover { border-color: #FF2D35; }

        /* ===================== Cài đặt (main list) — mint full-width rows =====================
           Scoped to .vs-account-settings only (the top-level "Cài đặt" list section). Sub-pages
           (Cài đặt thông báo / Ngôn ngữ / etc.) keep the existing .settings-row styling above. */
        .vs-account-settings {
            background: var(--content-bg);
            flex: 1;
            display: flex;
            flex-direction: column;
            box-sizing: border-box;
            /* Cancel the parent .account-body padding so the mint background reaches the
               edges of the content column, then re-apply our own compact padding on top. */
            margin: -15px -16px -32px;
            padding: 18px 16px 28px;
        }
        @media (min-width: 1024px) {
            .vs-account-settings { margin: -16px -28px -40px; padding: 18px 24px 40px; }
        }
        .vs-settings-list {
            width: 100%;
            display: flex;
            flex-direction: column;
            gap: 18px;
        }
        .vs-settings-row {
            width: 100%;
            box-sizing: border-box;
            min-height: 54px;
            background: #fff;
            border: 1px solid var(--settings-border);
            border-radius: 8px;
            display: flex;
            align-items: center;
            gap: 15px;
            padding: 0 24px 0 26px;
            font-family: inherit;
            font-size: 15.5px;
            font-weight: 400;
            line-height: 1.2;
            color: var(--settings-text);
            text-align: left;
            text-decoration: none;
            cursor: pointer;
            transition: border-color .15s ease;
        }
        .vs-settings-row:hover,
        .vs-settings-row:focus-visible { border-color: var(--primary-mid); }
        .vs-settings-row:focus-visible { outline: 2px solid var(--primary-mid); outline-offset: 1px; }
        .vs-settings-row .lci { width: 20px; height: 20px; flex-shrink: 0; color: inherit; stroke-width: 1.9; }
        .vs-settings-row .lci-chev { width: 20px; height: 20px; margin-left: auto; flex-shrink: 0; color: var(--settings-chev); }
        .vs-settings-row.is-danger { color: #ff1f2d; }
        .vs-settings-row.is-danger .lci,
        .vs-settings-row.is-danger .lci-chev { color: #ff1f2d; }
        .vs-settings-row.is-danger:hover,
        .vs-settings-row.is-danger:focus-visible { border-color: rgba(255, 31, 45, .4); }
    </style>
</head>
<body class="antialiased">

<div class="customer-account-shell">

    <!-- ============ SIDEBAR ============ -->
    <aside class="account-sidebar" aria-label="Điều hướng tài khoản">
        <div class="account-sidebar-scroll">

            <div class="account-sidebar-top">
                <!-- Profile row -->
                <a href="${pageContext.request.contextPath}/customer/ho-so" class="side-profile-row" aria-label="Mở hồ sơ cá nhân">
                    <c:choose>
                        <c:when test="${not empty account.avatarUrl}">
                            <img class="side-avatar js-avatar-img" src="${pageContext.request.contextPath}${account.avatarUrl}" alt="Ảnh đại diện">
                        </c:when>
                        <c:otherwise>
                            <span class="side-avatar js-avatar-initial" aria-hidden="true"><c:choose><c:when test="${not empty account.fullName}">${fn:escapeXml(fn:substring(account.fullName, 0, 1))}</c:when><c:otherwise>${fn:escapeXml(fn:substring(account.username, 0, 1))}</c:otherwise></c:choose></span>
                            <img class="side-avatar js-avatar-img" src="" alt="Ảnh đại diện" hidden>
                        </c:otherwise>
                    </c:choose>
                    <span style="min-width:0;">
                        <span id="accSummaryName" class="side-profile-name" style="display:block;">${fn:escapeXml(not empty account.fullName ? account.fullName : account.username)}</span>
                        <span id="accSummaryEmail" class="side-profile-email" style="display:block;">${not empty account.email ? fn:escapeXml(account.email) : 'Chưa cập nhật email'}</span>
                    </span>
                    <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                </a>

                <!-- Reputation row -->
                <button type="button" class="side-rep-row" data-section="uytin" aria-label="Mở điểm uy tín">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1 1 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="m9 12 2 2 4-4"/></svg>
                    <span>Uy tín người chơi</span>
                    <span class="rep-score">${repScoreNav}/100</span>
                    <span class="rep-label">&middot; ${repLabelNav}</span>
                    <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                </button>
            </div>

            <!-- Quick actions -->
            <div class="side-quick">
                <a class="side-quick-item" href="${pageContext.request.contextPath}/customer/lich-su-dat-san">
                    <svg class="lci qi-green" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="m9 16 2 2 4-4"/></svg>
                    <span>Lịch đã đặt</span>
                </a>
                <a class="side-quick-item" href="${pageContext.request.contextPath}/customer/ghep-keo?tab=cua-toi">
                    <svg class="lci qi-amber" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 21a8 8 0 0 0-16 0"/><circle cx="10" cy="8" r="5"/><path d="M22 20c0-3.37-2-6.5-4-8a5 5 0 0 0-.45-8.3"/></svg>
                    <span>Kèo của tôi</span>
                </a>
                <a class="side-quick-item" href="${pageContext.request.contextPath}/customer/ghep-keo?tab=tim-doi-thu">
                    <svg class="lci qi-blue" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="10" cy="7" r="4"/><path d="M10.3 15H7a4 4 0 0 0-4 4v2"/><circle cx="17" cy="17" r="3"/><path d="m21 21-1.9-1.9"/></svg>
                    <span>Tìm đối thủ</span>
                </a>
                <button type="button" class="side-quick-item" data-section="uytin">
                    <svg class="lci qi-rose" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1 1 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="m9 12 2 2 4-4"/></svg>
                    <span>Điểm uy tín</span>
                </button>
            </div>

            <!-- Menu: Hoạt động -->
            <p class="side-group-label" id="groupHoatDong">Hoạt động</p>
            <nav class="side-group" aria-labelledby="groupHoatDong">
                <a class="side-menu-item" href="${pageContext.request.contextPath}/customer/doi-nhom">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
                    Nhóm của tôi
                    <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                </a>
                <a class="side-menu-item" href="${pageContext.request.contextPath}/customer/ghep-keo?tab=cua-toi">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 21a8 8 0 0 0-16 0"/><circle cx="10" cy="8" r="5"/><path d="M22 20c0-3.37-2-6.5-4-8a5 5 0 0 0-.45-8.3"/></svg>
                    Kèo của tôi
                    <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                </a>
                <a class="side-menu-item" href="${pageContext.request.contextPath}/customer/ghep-keo?tab=tim-doi-thu">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="10" cy="7" r="4"/><path d="M10.3 15H7a4 4 0 0 0-4 4v2"/><circle cx="17" cy="17" r="3"/><path d="m21 21-1.9-1.9"/></svg>
                    Tìm đối thủ
                    <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                </a>
            </nav>

            <!-- Menu: Hệ thống -->
            <p class="side-group-label" id="groupHeThong">Hệ thống</p>
            <nav class="side-group" aria-labelledby="groupHeThong" style="margin-bottom:4px;">
                <button type="button" class="side-menu-item" data-section="caidat">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg>
                    Cài đặt
                    <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                </button>
                <button type="button" class="side-menu-item" data-section="phienban">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/></svg>
                    Thông tin phiên bản
                    <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                </button>
                <button type="button" class="side-menu-item" data-section="dieukhoan">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1 1 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/></svg>
                    Điều khoản và chính sách
                    <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                </button>
                <button type="button" class="side-menu-item" data-section="whatsnew">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z"/><path d="M20 3v4"/><path d="M22 5h-4"/><path d="M4 17v2"/><path d="M5 18H3"/></svg>
                    Ứng dụng có gì mới
                    <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                </button>
            </nav>

            <p class="side-version">Phiên bản 1.0-SNAPSHOT</p>
        </div>
    </aside>

    <!-- ============ MAIN WORKSPACE ============ -->
    <section class="account-main">
        <header class="account-header">
            <h1 id="accountHeaderTitle">Danh sách đặt lịch</h1>
        </header>

        <div class="account-body">

            <!-- Toolbar (chỉ hiện ở "Danh sách đặt lịch") -->
            <div class="acc-toolbar" id="accToolbar">
                <a href="${pageContext.request.contextPath}/customer/lich-su-dat-san" class="btn-viewall">
                    Xem tất cả
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="M8 14h.01"/><path d="M12 14h.01"/><path d="M16 14h.01"/><path d="M8 18h.01"/><path d="M12 18h.01"/><path d="M16 18h.01"/></svg>
                </a>
            </div>

            <!-- ===== Section: Danh sách đặt lịch (mặc định) ===== -->
            <section class="acc-section" data-section="datlich" aria-label="Danh sách đặt lịch">
                <c:choose>
                    <c:when test="${not empty upcomingBookings}">
                        <ul class="booking-list">
                            <c:forEach var="lich" items="${upcomingBookings}">
                                <li class="booking-item">
                                    <div style="min-width:0;">
                                        <span class="booking-name"><c:choose><c:when test="${not empty upcomingSanNames[lich.sanId]}">${fn:escapeXml(upcomingSanNames[lich.sanId])}</c:when><c:otherwise>Sân #${lich.sanId}</c:otherwise></c:choose></span><c:choose>
                                            <c:when test="${lich.trangThai == 'Chờ xác nhận' || lich.trangThai == 'Chờ thanh toán'}"><span class="booking-chip chip-wait">${fn:escapeXml(lich.trangThai)}</span></c:when>
                                            <c:when test="${lich.trangThai == 'Đã xác nhận' || lich.trangThai == 'Đã đặt' || lich.trangThai == 'Đã thanh toán' || lich.trangThai == 'Đã cọc'}"><span class="booking-chip chip-ok">${fn:escapeXml(lich.trangThai)}</span></c:when>
                                            <c:when test="${lich.trangThai == 'Đang sử dụng'}"><span class="booking-chip chip-live">Đang sử dụng</span></c:when>
                                            <c:otherwise><span class="booking-chip chip-muted">${fn:escapeXml(lich.trangThai)}</span></c:otherwise>
                                        </c:choose>
                                        <p class="booking-meta">
                                            <c:if test="${not empty upcomingCoSoNames[lich.sanId]}">
                                                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/></svg>
                                                ${fn:escapeXml(upcomingCoSoNames[lich.sanId])} <span>&middot;</span>
                                            </c:if>
                                            Mã #${lich.datSanId}
                                        </p>
                                        <p class="booking-time">
                                            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/></svg>
                                            ${fn:substring(lich.ngayDat, 8, 10)}/${fn:substring(lich.ngayDat, 5, 7)}/${fn:substring(lich.ngayDat, 0, 4)}
                                            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                                            ${fn:substring(lich.gioBatDau, 0, 5)} - ${fn:substring(lich.gioKetThuc, 0, 5)}
                                        </p>
                                    </div>
                                    <div class="booking-actions">
                                        <c:if test="${nearestBookingUrgentEligible and nearestBooking ne null and lich.datSanId eq nearestBooking.datSanId}">
                                            <button type="button" class="btn-urgent" onclick="openUrgentOpponentModal()">
                                                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 0 0 13 10h7a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92-6.02A1 1 0 0 0 11 14z"/></svg>
                                                Tìm đối thủ gấp
                                            </button>
                                        </c:if>
                                        <a href="${pageContext.request.contextPath}/customer/lich-su-dat-san" class="btn-secondary" style="padding:9px 14px;font-size:13px;">Chi tiết</a>
                                    </div>
                                </li>
                            </c:forEach>
                        </ul>
                    </c:when>
                    <c:otherwise>
                        <div class="acc-empty">
                            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="M8 14h.01"/><path d="M12 14h.01"/><path d="M16 14h.01"/><path d="M8 18h.01"/><path d="M12 18h.01"/><path d="M16 18h.01"/></svg>
                            <p>Bạn chưa có lịch đặt</p>
                        </div>
                    </c:otherwise>
                </c:choose>
            </section>

            <!-- ===== Section: Tổng quan tài khoản ===== -->
            <section class="acc-section" data-section="tongquan" aria-label="Tổng quan tài khoản" hidden>
                <div class="ov-stats">
                    <div class="ov-stat">
                        <p class="num">${upcomingCount}</p>
                        <p class="lbl">Lịch sắp tới</p>
                    </div>
                    <div class="ov-stat">
                        <p class="num">${totalBookings}</p>
                        <p class="lbl">Tổng lịch đặt</p>
                    </div>
                </div>
                <div class="ov-actions">
                    <a href="${pageContext.request.contextPath}/customer/dat-san" class="btn-primary">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><path d="M21 13V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h8"/><path d="M3 10h18"/><path d="M16 19h6"/><path d="M19 16v6"/></svg>
                        Đặt sân mới
                    </a>
                    <a href="${pageContext.request.contextPath}/customer/ghep-keo?tab=tao-keo" class="btn-secondary">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m11 17 2 2a1 1 0 1 0 3-3"/><path d="m14 14 2.5 2.5a1 1 0 1 0 3-3l-3.88-3.88a3 3 0 0 0-4.24 0l-.88.88a1 1 0 1 1-3-3l2.81-2.81a5.79 5.79 0 0 1 7.06-.87l.47.28a2 2 0 0 0 1.42.25L21 4"/><path d="m21 3 1 11h-2"/><path d="M3 3 2 14l6.5 6.5a1 1 0 1 0 3-3"/><path d="M3 4h8"/></svg>
                        Tạo kèo ghép trận
                    </a>
                </div>
            </section>

            <!-- ===== Section: Điểm uy tín ===== -->
            <section class="acc-section" data-section="uytin" aria-label="Điểm uy tín" hidden>
                <jsp:include page="/customer/common/reputation-card.jsp" />
            </section>

            <!-- ===== Section: Cài đặt ===== -->
            <section class="acc-section vs-account-settings" data-section="caidat" aria-label="Cài đặt" hidden>
                <div class="vs-settings-list">
                    <a class="vs-settings-row" href="${pageContext.request.contextPath}/customer/notification-settings">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.268 21a2 2 0 0 0 3.464 0"/><path d="M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"/></svg>
                        Cài đặt thông báo
                        <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                    </a>
                    <button type="button" class="vs-settings-row" data-section="ngonngu">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M2 12h20"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>
                        Ngôn ngữ - Tiếng Việt
                        <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                    </button>
                    <a class="vs-settings-row" href="${pageContext.request.contextPath}/customer/doi-mat-khau">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                        Đổi mật khẩu
                        <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                    </a>
                    <a class="vs-settings-row" href="${pageContext.request.contextPath}/logout">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/></svg>
                        Đăng xuất tài khoản
                        <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                    </a>
                    <button type="button" class="vs-settings-row is-danger" onclick="openDeleteAccountModal()">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/><path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" x2="10" y1="11" y2="17"/><line x1="14" x2="14" y1="11" y2="17"/></svg>
                        Xóa tài khoản
                        <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                    </button>
                </div>
            </section>

            <!-- "Cài đặt thông báo" đã tách sang trang riêng full-screen:
                 /customer/notification-settings (CaiDatThongBao.jsp). -->

            <!-- ===== Section: Ngôn ngữ ===== -->
            <section class="acc-section customer-settings-page" data-section="ngonngu" aria-label="Ngôn ngữ" hidden>
                <div class="settings-card" style="max-width:640px;">
                    <div class="settings-row" style="cursor:default;">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 12 2 2 4-4"/><circle cx="12" cy="12" r="10"/></svg>
                        <span style="flex:1;">Tiếng Việt</span>
                        <span style="font-size:12px;font-weight:700;color:var(--primary-mid);">Đang dùng</span>
                    </div>
                </div>
                <p style="font-size:12.5px;color:var(--muted-green);margin:10px 4px 0;max-width:640px;">V-SPORT hiện chỉ hỗ trợ Tiếng Việt.</p>
            </section>

            <!-- ===== Section: Thông tin phiên bản ===== -->
            <section class="acc-section customer-settings-page" data-section="phienban" aria-label="Thông tin phiên bản" hidden>
                <div class="info-card" style="max-width:640px;">
                    <dl class="acc-field-view grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-4">
                        <div>
                            <dt>Ứng dụng</dt>
                            <dd>V-SPORT</dd>
                        </div>
                        <div>
                            <dt>Phiên bản</dt>
                            <dd>1.0-SNAPSHOT</dd>
                        </div>
                    </dl>
                    <p style="font-size:13.5px;color:var(--muted-green);margin-top:16px;line-height:1.6;">Nền tảng đặt sân, ghép trận và quản lý đội nhóm thể thao.</p>
                </div>
            </section>

            <!-- ===== Section: Điều khoản và chính sách ===== -->
            <section class="acc-section customer-settings-page" data-section="dieukhoan" aria-label="Điều khoản và chính sách" hidden>
                <div class="info-card" style="max-width:640px;display:flex;flex-direction:column;gap:16px;">
                    <div>
                        <h3 class="text-[14.5px] font-extrabold mb-1.5" style="color:var(--ink-green);">Quy định đặt sân</h3>
                        <p style="font-size:13.5px;color:var(--muted-green);line-height:1.6;">Khách hàng đặt và giữ đúng khung giờ đã xác nhận. Việc hủy hoặc đổi lịch cần thực hiện trước thời gian quy định tại từng cơ sở.</p>
                    </div>
                    <div>
                        <h3 class="text-[14.5px] font-extrabold mb-1.5" style="color:var(--ink-green);">Bảo mật thông tin</h3>
                        <p style="font-size:13.5px;color:var(--muted-green);line-height:1.6;">Thông tin cá nhân chỉ được dùng để xử lý đặt sân, ghép trận và liên hệ hỗ trợ, không chia sẻ cho bên thứ ba ngoài mục đích vận hành dịch vụ.</p>
                    </div>
                    <div>
                        <h3 class="text-[14.5px] font-extrabold mb-1.5" style="color:var(--ink-green);">Điểm uy tín</h3>
                        <p style="font-size:13.5px;color:var(--muted-green);line-height:1.6;">Hành vi hủy lịch trễ hoặc không đến có thể ảnh hưởng đến điểm uy tín của tài khoản.</p>
                    </div>
                </div>
            </section>

            <!-- ===== Section: Ứng dụng có gì mới ===== -->
            <section class="acc-section customer-settings-page" data-section="whatsnew" aria-label="Ứng dụng có gì mới" hidden>
                <div class="info-card" style="max-width:640px;">
                    <ul style="display:flex;flex-direction:column;gap:14px;list-style:none;margin:0;padding:0;">
                        <li style="display:flex;gap:10px;align-items:flex-start;">
                            <svg class="lci" style="color:var(--primary-mid);margin-top:2px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                            <span style="font-size:13.5px;color:var(--ink-green);line-height:1.55;"><b>Đội nhóm</b> — tạo đội, mời thành viên, duyệt yêu cầu tham gia.</span>
                        </li>
                        <li style="display:flex;gap:10px;align-items:flex-start;">
                            <svg class="lci" style="color:var(--primary-mid);margin-top:2px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 21a8 8 0 0 0-16 0"/><circle cx="10" cy="8" r="5"/></svg>
                            <span style="font-size:13.5px;color:var(--ink-green);line-height:1.55;"><b>Ghép kèo</b> — tìm đối thủ và tạo kèo giao lưu.</span>
                        </li>
                        <li style="display:flex;gap:10px;align-items:flex-start;">
                            <svg class="lci" style="color:var(--primary-mid);margin-top:2px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1 1 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/></svg>
                            <span style="font-size:13.5px;color:var(--ink-green);line-height:1.55;"><b>Điểm uy tín</b> — theo dõi mức độ tin cậy khi đặt sân.</span>
                        </li>
                    </ul>
                </div>
            </section>

        </div>
    </section>
</div>

<!-- Toast -->
<div id="accToast" class="hidden fixed bottom-24 right-6 z-[999] max-w-sm bg-white border border-slate-200 shadow-lg rounded-xl px-4 py-3 flex items-start gap-3 opacity-0 translate-y-3">
    <span id="accToastIconOk" class="mt-0.5 text-emerald-600"><svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/></svg></span>
    <span id="accToastIconErr" class="mt-0.5 text-red-500 hidden"><svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" x2="12" y1="8" y2="12"/><line x1="12" x2="12.01" y1="16" y2="16"/></svg></span>
    <div>
        <p id="accToastTitle" class="text-sm font-bold" style="color:var(--ink-green);">Thành công</p>
        <p id="accToastMessage" class="text-xs mt-0.5" style="color:var(--muted-green);"></p>
    </div>
</div>

<!-- "Đổi mật khẩu" đã tách sang trang riêng full-screen:
     /customer/doi-mat-khau (DoiMatKhau.jsp). -->

<!-- Delete account modal -->
<div id="deleteAccountModal" class="hidden fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[300] flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-[420px] border border-slate-200">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <h3 class="text-sm font-extrabold flex items-center gap-2 text-red-600">
                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/><path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" x2="10" y1="11" y2="17"/><line x1="14" x2="14" y1="11" y2="17"/></svg>
                Xóa tài khoản
            </h3>
            <button type="button" onclick="closeModal('deleteAccountModal')" class="w-8 h-8 rounded-full hover:bg-slate-100 flex items-center justify-center" aria-label="Đóng">
                <svg class="lci text-slate-500" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
        </div>
        <form id="deleteAccountForm" class="px-6 py-5 flex flex-col gap-4" onsubmit="return false;" autocomplete="off">
            <p class="text-sm text-slate-600">Tài khoản của bạn sẽ bị vô hiệu hóa và không thể đăng nhập lại. Nhập mật khẩu hiện tại để xác nhận.</p>
            <div>
                <label class="acc-label" for="deleteAccountPassword">Mật khẩu hiện tại</label>
                <div class="relative">
                    <input type="password" id="deleteAccountPassword" class="acc-input pr-10" autocomplete="new-password">
                    <button type="button" onclick="togglePw('deleteAccountPassword', this)" class="pw-eye absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600" aria-label="Hiện/ẩn mật khẩu">
                        <svg class="lci eye-closed" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49"/><path d="M14.084 14.158a3 3 0 0 1-4.242-4.242"/><path d="M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143"/><path d="m2 2 20 20"/></svg>
                        <svg class="lci eye-open" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0"/><circle cx="12" cy="12" r="3"/></svg>
                    </button>
                </div>
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="deleteAccountPassword"></p>
            </div>
        </form>
        <div class="px-6 pb-5 flex justify-end gap-3">
            <button type="button" onclick="closeModal('deleteAccountModal')" class="btn-secondary">Hủy</button>
            <button type="button" id="deleteAccountBtn" onclick="confirmDeleteAccount()" class="btn-primary" style="background:#E5484D;">Xóa tài khoản</button>
        </div>
    </div>
</div>

<script>
    const CTX = '${pageContext.request.contextPath}';

    // ---- Section router: main workspace chỉ hiển thị một section tại một thời điểm ----
    const SECTION_TITLES = {
        datlich: 'Danh sách đặt lịch',
        tongquan: 'Tổng quan tài khoản',
        uytin: 'Điểm uy tín',
        caidat: 'Cài đặt',
        ngonngu: 'Ngôn ngữ',
        phienban: 'Thông tin phiên bản',
        dieukhoan: 'Điều khoản và chính sách',
        whatsnew: 'Ứng dụng có gì mới'
    };
    // Alias giữ tương thích các anchor cũ (#uyTinCuaToi từ LichSuDatSan.jsp, ...).
    const SECTION_ALIASES = {
        uyTinCuaToi: 'uytin',
        tongQuan: 'tongquan'
    };
    // Các section con của "Cài đặt" vẫn giữ mục sidebar "Cài đặt" ở trạng thái active.
    const SECTION_SIDEBAR_PARENT = { ngonngu: 'caidat' };

    function showAccountSection(key, opts) {
        if (!SECTION_TITLES[key]) key = 'datlich';
        document.querySelectorAll('.acc-section').forEach(function (sec) {
            sec.hidden = sec.dataset.section !== key;
        });
        document.getElementById('accountHeaderTitle').textContent = SECTION_TITLES[key];
        document.getElementById('accToolbar').hidden = key !== 'datlich';
        var highlightKey = SECTION_SIDEBAR_PARENT[key] || key;
        document.querySelectorAll('.side-menu-item[data-section]').forEach(function (item) {
            item.classList.toggle('is-current', item.dataset.section === highlightKey);
        });
        if (history.replaceState) {
            history.replaceState(null, '', key === 'datlich' ? location.pathname : ('#' + key));
        }
        if (opts && opts.scroll && window.innerWidth < 1024) {
            document.querySelector('.account-main').scrollIntoView({ behavior: 'smooth' });
        }
    }

    document.querySelectorAll('[data-section]').forEach(function (el) {
        if (el.classList.contains('acc-section')) return;
        el.addEventListener('click', function () {
            showAccountSection(el.dataset.section, { scroll: true });
        });
    });

    (function initSection() {
        let key = (location.hash || '').replace('#', '');
        if (SECTION_ALIASES[key]) key = SECTION_ALIASES[key];
        showAccountSection(SECTION_TITLES[key] ? key : 'datlich');
    })();

    // ---- Toast ----
    function showToast(title, message, isError) {
        const toast = document.getElementById('accToast');
        document.getElementById('accToastTitle').textContent = title;
        document.getElementById('accToastMessage').textContent = message || '';
        document.getElementById('accToastIconOk').classList.toggle('hidden', !!isError);
        document.getElementById('accToastIconErr').classList.toggle('hidden', !isError);
        toast.classList.remove('hidden');
        requestAnimationFrame(() => { toast.classList.remove('opacity-0', 'translate-y-3'); });
        clearTimeout(window.__accToastTimer);
        window.__accToastTimer = setTimeout(() => {
            toast.classList.add('opacity-0', 'translate-y-3');
            setTimeout(() => toast.classList.add('hidden'), 250);
        }, 4000);
    }

    function openModal(id) {
        document.getElementById(id).classList.remove('hidden');
    }
    function closeModal(id) {
        document.getElementById(id).classList.add('hidden');
    }
    document.querySelectorAll('#deleteAccountModal').forEach(overlay => {
        overlay.addEventListener('click', (e) => { if (e.target === overlay) closeModal(overlay.id); });
    });
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            closeModal('deleteAccountModal');
        }
    });

    // ---- Xóa tài khoản ----
    function openDeleteAccountModal() {
        document.getElementById('deleteAccountForm').reset();
        clearFieldErrors(document.getElementById('deleteAccountForm'));
        openModal('deleteAccountModal');
    }

    function confirmDeleteAccount() {
        const password = document.getElementById('deleteAccountPassword').value;
        const errEl = document.querySelector('[data-error-for="deleteAccountPassword"]');
        if (!password) {
            errEl.textContent = 'Vui lòng nhập mật khẩu hiện tại.';
            errEl.classList.remove('hidden');
            return;
        }
        const btn = document.getElementById('deleteAccountBtn');
        btn.disabled = true;
        const originalText = btn.textContent;
        btn.textContent = 'Đang xử lý...';

        const params = new URLSearchParams();
        params.append('action', 'deleteAccount');
        params.append('password', password);

        fetch(CTX + '/customer/tai-khoan', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: params
        })
            .then(r => r.json())
            .then(data => {
                if (data.success) {
                    window.location.href = CTX + '/dangnhap';
                } else {
                    btn.disabled = false;
                    btn.textContent = originalText;
                    errEl.textContent = data.message || 'Không thể xóa tài khoản.';
                    errEl.classList.remove('hidden');
                }
            })
            .catch(() => {
                btn.disabled = false;
                btn.textContent = originalText;
                errEl.textContent = 'Lỗi kết nối. Vui lòng thử lại.';
                errEl.classList.remove('hidden');
            });
    }

    function clearFieldErrors(scopeEl) {
        scopeEl.querySelectorAll('[data-error-for]').forEach(el => { el.textContent = ''; el.classList.add('hidden'); });
    }
    function showFieldErrors(scopeEl, fieldErrors) {
        clearFieldErrors(scopeEl);
        if (!fieldErrors) return;
        Object.keys(fieldErrors).forEach(key => {
            const el = scopeEl.querySelector('[data-error-for="' + key + '"]');
            if (el) { el.textContent = fieldErrors[key]; el.classList.remove('hidden'); }
        });
    }

    // ---- Show/hide mật khẩu (dùng cho modal Xóa tài khoản) ----
    function togglePw(id, btn) {
        const input = document.getElementById(id);
        if (input.type === 'password') { input.type = 'text'; btn.classList.add('is-visible'); }
        else { input.type = 'password'; btn.classList.remove('is-visible'); }
    }

    // ---- Flash message sau khi đổi mật khẩu ở trang /customer/doi-mat-khau ----
    (function showPwFlash() {
        let msg = null;
        try { msg = sessionStorage.getItem('vsport_flash'); } catch (e) { msg = null; }
        if (msg) {
            try { sessionStorage.removeItem('vsport_flash'); } catch (e) { /* ignore */ }
            showToast('Thành công', msg);
        }
    })();
</script>

<jsp:include page="/customer/common/urgent-opponent-modal.jsp" />
<jsp:include page="/customer/common/bottom-nav.jsp" />
</body>
</html>
