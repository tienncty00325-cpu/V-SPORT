<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Bản đồ Sân Thể Thao - V-SPORT</title>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover"/>
    <jsp:include page="/common/xtra-head.jsp" />
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet" crossorigin="anonymous">

    <!-- Leaflet -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>

    <style>
        /* ===== V-SPORT Map palette (scoped to this page) ===== */
        :root {
            --vsm-navy: #0B2E59;
            --vsm-navy-dark: #071D38;
            --vsm-cyan: #12B8FF;
            --vsm-cyan-light: #DDF6FF;
            --vsm-orange: #FF8A1F;
            --vsm-bg: #F5F8FC;
            --vsm-surface: #FFFFFF;
            --vsm-text: #10233E;
            --vsm-text-secondary: #64748B;
            --vsm-border: #DCE5EF;
            --vsm-success: #16A36A;
            --vsm-danger: #EF4444;
        }

        html, body {
            height: 100%;
            margin: 0;
            padding: 0 !important;
            overflow: hidden;
            overscroll-behavior: none;
            background: var(--vsm-bg);
            font-family: 'Outfit', 'Inter', system-ui, -apple-system, sans-serif;
            color: var(--vsm-text);
            display: flex;
            flex-direction: column;
        }
        * { box-sizing: border-box; }
        button { font-family: inherit; }

        /* Ensure global header does not shrink */
        .header { flex-shrink: 0; }

        .vsm-app {
            position: relative;
            display: flex;
            flex-direction: column;
            flex: 1;
            min-height: 0;
            background: var(--vsm-bg);
        }

        .vsm-map-layer {
            position: relative;
            flex: 1 1 auto;
            min-height: 0;
        }
        #vsmMap {
            position: absolute;
            inset: 0;
            z-index: 0;
            background: var(--vsm-bg);
        }

        /* ===================== Command bar (search + chips) ===================== */
        .vsm-command {
            position: absolute;
            top: 14px; left: 14px; right: 14px;
            z-index: 500;
            display: flex;
            flex-direction: column;
            gap: 10px;
            pointer-events: none;
        }
        .vsm-command > * { pointer-events: auto; }
        @media (min-width: 1024px) {
            /* Desktop: search bar and sport chips share one horizontal row
               (matches reference layout) instead of stacking in a narrow column. */
            .vsm-command { left: 20px; right: 82px; top: 20px; width: auto; flex-direction: row; align-items: center; gap: 16px; }
            .vsm-searchbar { width: 460px; flex: 0 0 460px; height: 50px; border-radius: 24px; }
            .vsm-chiprow { flex: 1 1 auto; min-width: 0; padding: 3px 2px; }
        }

        .vsm-searchbar {
            display: flex; align-items: center; gap: 10px;
            background: var(--vsm-surface);
            border-radius: 20px;
            box-shadow: 0 8px 24px rgba(11, 46, 89, 0.14);
            padding: 6px 8px 6px 16px;
            height: 52px;
        }
        .vsm-searchbar:focus-within { box-shadow: 0 0 0 3px var(--vsm-cyan-light), 0 8px 24px rgba(11, 46, 89, 0.14); }
        .vsm-search-ic { color: var(--vsm-navy); flex-shrink: 0; width: 20px; height: 20px; }
        .vsm-searchbar input {
            flex: 1; min-width: 0; border: none; outline: none; background: transparent;
            font-size: 15px; font-weight: 500; color: var(--vsm-text);
        }
        .vsm-searchbar input::placeholder { color: var(--vsm-text-secondary); font-weight: 400; }
        .vsm-search-clear {
            display: none; align-items: center; justify-content: center;
            width: 30px; height: 30px; border-radius: 50%; border: none; background: #EEF2F7;
            color: var(--vsm-text-secondary); cursor: pointer; flex-shrink: 0;
        }
        .vsm-search-clear.is-visible { display: flex; }
        .vsm-search-clear:hover { background: #E2E8F0; }
        .vsm-search-btn {
            display: flex; align-items: center; justify-content: center;
            width: 40px; height: 40px; border-radius: 14px; border: none; flex-shrink: 0;
            background: var(--vsm-navy); color: #fff; cursor: pointer;
            transition: background-color .15s ease;
        }
        .vsm-search-btn:hover { background: var(--vsm-navy-dark); }
        .vsm-search-btn svg { width: 18px; height: 18px; }

        .vsm-chiprow {
            display: flex; gap: 8px; overflow-x: auto; scrollbar-width: none; -ms-overflow-style: none;
            padding: 2px 2px 4px;
        }
        .vsm-chiprow::-webkit-scrollbar { display: none; }
        .vsm-chip {
            display: inline-flex; align-items: center; gap: 6px; flex-shrink: 0;
            padding: 9px 15px; border-radius: 9999px; border: 1px solid var(--vsm-border);
            background: var(--vsm-surface); color: var(--vsm-text);
            font-size: 13px; font-weight: 600; white-space: nowrap; cursor: pointer;
            box-shadow: 0 2px 8px rgba(11, 46, 89, 0.08);
            transition: background-color .15s ease, color .15s ease, border-color .15s ease;
        }
        .vsm-chip svg { width: 15px; height: 15px; flex-shrink: 0; }
        .vsm-chip.is-active { background: var(--vsm-navy); border-color: var(--vsm-navy); color: #fff; }
        .vsm-chip:hover:not(.is-active) { border-color: var(--vsm-cyan); color: var(--vsm-navy); }

        /* ===================== Floating action buttons ===================== */
        .vsm-fab {
            display: flex; align-items: center; justify-content: center;
            width: 46px; height: 46px; border-radius: 50%; border: none;
            background: var(--vsm-surface); color: var(--vsm-navy); cursor: pointer;
            box-shadow: 0 6px 18px rgba(11, 46, 89, 0.16);
            transition: background-color .15s ease, color .15s ease, transform .1s ease;
            position: relative;
        }
        .vsm-fab:hover { color: var(--vsm-cyan); }
        .vsm-fab:active { transform: scale(0.96); }
        .vsm-fab svg { width: 21px; height: 21px; }
        .vsm-fab.is-active { background: var(--vsm-navy); color: #fff; }

        .vsm-layers-btn {
            position: absolute; top: 14px; right: 14px; z-index: 500;
        }
        @media (min-width: 1024px) { .vsm-layers-btn { top: 20px; right: 20px; } }

        .vsm-corner-stack {
            position: absolute; right: 14px; z-index: 500;
            display: flex; flex-direction: column; gap: 10px;
            bottom: calc(env(safe-area-inset-bottom, 0px) + 20px);
        }
        @media (min-width: 1024px) {
            .vsm-corner-stack { right: 20px; bottom: 30px; }
        }

        .leaflet-bottom { bottom: calc(env(safe-area-inset-bottom, 0px) + 20px) !important; }
        @media (min-width: 1024px) {
            .leaflet-bottom { bottom: 30px !important; }
        }

        .vsm-spinner-ring {
            width: 18px; height: 18px; border-radius: 50%;
            border: 2.5px solid rgba(11,46,89,.18); border-top-color: var(--vsm-navy);
            animation: vsmSpin .8s linear infinite;
        }
        @keyframes vsmSpin { to { transform: rotate(360deg); } }

        /* ===================== Filter sheet ===================== */
        .vsm-filter-panel {
            position: absolute; top: 78px; left: 14px; z-index: 520;
            width: min(320px, calc(100vw - 28px));
            background: var(--vsm-surface); border-radius: 18px;
            box-shadow: 0 16px 40px rgba(11, 46, 89, 0.22);
            padding: 18px;
            opacity: 0; visibility: hidden; transform: translateY(-8px);
            transition: opacity .16s ease, transform .16s ease, visibility .16s;
        }
        .vsm-filter-panel.is-open { opacity: 1; visibility: visible; transform: translateY(0); }
        @media (min-width: 1024px) { .vsm-filter-panel { top: 78px; left: 20px; } }
        .vsm-filter-title { font-size: 13px; font-weight: 700; color: var(--vsm-text-secondary); text-transform: uppercase; letter-spacing: .04em; margin: 0 0 10px; }
        .vsm-radius-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; margin-bottom: 16px; }
        .vsm-radius-opt {
            padding: 9px 4px; border-radius: 10px; border: 1px solid var(--vsm-border);
            background: #fff; color: var(--vsm-text); font-size: 12.5px; font-weight: 600;
            cursor: pointer; text-align: center; transition: all .12s ease;
        }
        .vsm-radius-opt.is-active { background: var(--vsm-navy); border-color: var(--vsm-navy); color: #fff; }
        .vsm-filter-row { display: flex; align-items: center; justify-content: space-between; padding: 10px 0; border-top: 1px solid #EEF2F7; }
        .vsm-switch { position: relative; width: 40px; height: 23px; flex-shrink: 0; }
        .vsm-switch input { position: absolute; opacity: 0; width: 100%; height: 100%; margin: 0; cursor: pointer; }
        .vsm-switch-track { position: absolute; inset: 0; background: #CBD5E1; border-radius: 9999px; transition: background-color .15s ease; pointer-events: none; }
        .vsm-switch-track::after {
            content: ''; position: absolute; top: 2.5px; left: 2.5px; width: 18px; height: 18px;
            border-radius: 50%; background: #fff; transition: transform .15s ease;
            box-shadow: 0 1px 3px rgba(0,0,0,.2);
        }
        .vsm-switch input:checked ~ .vsm-switch-track { background: var(--vsm-navy); }
        .vsm-switch input:checked ~ .vsm-switch-track::after { transform: translateX(17px); }
        .vsm-switch input:focus-visible ~ .vsm-switch-track { outline: 2.5px solid var(--vsm-cyan); outline-offset: 2px; }
        .vsm-filter-actions { display: flex; gap: 8px; margin-top: 14px; }
        .vsm-filter-reset {
            flex: 1; padding: 10px; border-radius: 10px; border: 1px solid var(--vsm-border);
            background: #fff; color: var(--vsm-text); font-size: 13px; font-weight: 700; cursor: pointer;
        }
        .vsm-filter-reset:hover { border-color: var(--vsm-navy); }
        .vsm-filter-apply {
            flex: 1; padding: 10px; border-radius: 10px; border: none;
            background: var(--vsm-navy); color: #fff; font-size: 13px; font-weight: 700; cursor: pointer;
        }
        .vsm-filter-apply:hover { background: var(--vsm-navy-dark); }

        /* ===================== Results count pill ===================== */
        .vsm-results-pill {
            position: absolute; left: 50%; transform: translateX(-50%);
            top: 14px; z-index: 490;
            background: rgba(11, 46, 89, 0.92); color: #fff;
            padding: 7px 16px; border-radius: 9999px; font-size: 12.5px; font-weight: 600;
            opacity: 0; visibility: hidden; transition: opacity .18s ease;
            pointer-events: none; white-space: nowrap;
        }
        .vsm-results-pill.is-visible { opacity: 1; visibility: visible; }
        @media (min-width: 1024px) { .vsm-results-pill { top: 82px; } }

        /* ===================== Markers ===================== */
        .vsm-marker {
            width: 38px; height: 38px;
            display: flex; align-items: center; justify-content: center;
            position: relative;
            transition: transform .12s ease;
        }
        .vsm-marker-pin {
            width: 34px; height: 34px; border-radius: 50% 50% 50% 0;
            background: var(--vsm-navy); transform: rotate(-45deg);
            display: flex; align-items: center; justify-content: center;
            box-shadow: 0 3px 10px rgba(11, 46, 89, 0.35);
            border: 2.5px solid #fff;
        }
        .vsm-marker-pin svg { transform: rotate(45deg); width: 16px; height: 16px; color: #fff; }
        .vsm-marker.is-closed .vsm-marker-pin { background: #94A3B8; }
        .vsm-marker-dot {
            position: absolute; top: -1px; right: 2px;
            width: 10px; height: 10px; border-radius: 50%;
            background: var(--vsm-success); border: 2px solid #fff;
        }
        .vsm-marker.is-closed .vsm-marker-dot { background: #94A3B8; }
        .vsm-marker:hover { transform: scale(1.06); z-index: 10; }
        .vsm-marker.is-focused { transform: scale(1.14); z-index: 20; }

        .vsm-self-marker {
            width: 22px; height: 22px; border-radius: 50%;
            background: var(--vsm-cyan); border: 3px solid #fff;
            box-shadow: 0 0 0 6px rgba(18, 184, 255, 0.28);
            position: relative;
        }
        .vsm-self-marker::after {
            content: ''; position: absolute; inset: -8px; border-radius: 50%;
            border: 2px solid rgba(18, 184, 255, 0.45);
            animation: vsmPulse 2.2s ease-out infinite;
        }
        @keyframes vsmPulse {
            0% { transform: scale(0.6); opacity: .9; }
            100% { transform: scale(2.2); opacity: 0; }
        }
        @media (prefers-reduced-motion: reduce) {
            .vsm-self-marker::after { animation: none; }
            .vsm-spinner-ring { animation-duration: 2s; }
        }

        .leaflet-popup, .leaflet-marker-shadow { display: none !important; }

        /* ===================== Backdrop (sheets) ===================== */
        .vsm-backdrop {
            position: fixed; inset: 0; z-index: 800;
            background: rgba(7, 29, 56, 0.4);
            opacity: 0; visibility: hidden; transition: opacity .22s ease;
        }
        .vsm-backdrop.is-open { opacity: 1; visibility: visible; }

        /* ===================== Detail bottom sheet ===================== */
        .vsm-sheet {
            position: fixed; z-index: 850;
            left: 0; right: 0;
            bottom: 0;
            background: var(--vsm-surface);
            border-radius: 22px 22px 0 0;
            box-shadow: 0 -12px 40px rgba(11, 46, 89, 0.24);
            transform: translateY(100%);
            transition: transform .26s cubic-bezier(.22,1,.36,1);
            max-height: 72dvh;
            display: flex; flex-direction: column;
        }
        .vsm-sheet.is-open { transform: translateY(0); }
        @media (min-width: 1024px) {
            .vsm-sheet {
                left: 20px; right: auto;
                bottom: 20px;
                width: min(480px, calc(100vw - 40px));
                border-radius: 20px;
                max-height: calc(100dvh - 120px);
            }
        }
        .vsm-sheet-handle-wrap { padding: 10px 0 4px; display: flex; justify-content: center; flex-shrink: 0; cursor: grab; touch-action: none; }
        @media (min-width: 1024px) { .vsm-sheet-handle-wrap { display: none; } }
        .vsm-sheet-handle { width: 42px; height: 5px; border-radius: 9999px; background: #D8E0EA; }
        .vsm-sheet-close {
            position: absolute; top: 12px; right: 12px; z-index: 2;
            width: 36px; height: 36px; border-radius: 50%; border: none;
            background: rgba(255,255,255,.92); color: var(--vsm-navy); cursor: pointer;
            display: flex; align-items: center; justify-content: center;
            box-shadow: 0 2px 8px rgba(11,46,89,.16);
        }
        .vsm-sheet-close svg { width: 18px; height: 18px; }
        .vsm-sheet-scroll { overflow-y: auto; min-height: 0; flex: 1; }
        .vsm-sheet-hero { position: relative; width: 100%; aspect-ratio: 16/9; background: var(--vsm-cyan-light); overflow: hidden; }
        .vsm-sheet-hero img { width: 100%; height: 100%; object-fit: cover; display: block; }
        .vsm-sheet-status {
            position: absolute; left: 14px; bottom: 12px;
            display: inline-flex; align-items: center; gap: 5px;
            padding: 5px 11px; border-radius: 9999px; font-size: 11.5px; font-weight: 700;
            background: rgba(255,255,255,.95); color: var(--vsm-success);
        }
        .vsm-sheet-status .dot { width: 7px; height: 7px; border-radius: 50%; background: currentColor; }
        .vsm-sheet-status.is-closed { color: var(--vsm-text-secondary); }
        .vsm-sheet-body { padding: 16px 20px 20px; }
        .vsm-sheet-title { font-size: 19px; font-weight: 800; color: var(--vsm-text); margin: 0 0 6px; line-height: 1.25; }
        .vsm-sheet-meta-row { display: flex; align-items: flex-start; gap: 8px; font-size: 13.5px; color: var(--vsm-text-secondary); margin-top: 7px; line-height: 1.45; }
        .vsm-sheet-meta-row svg { width: 16px; height: 16px; flex-shrink: 0; margin-top: 1px; color: var(--vsm-navy); }
        .vsm-sheet-chips { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 12px; }
        .vsm-sheet-chip { font-size: 11.5px; font-weight: 700; padding: 4px 10px; border-radius: 9999px; background: var(--vsm-cyan-light); color: var(--vsm-navy); }
        .vsm-sheet-divider { height: 1px; background: #EEF2F7; margin: 16px 0; }
        .vsm-sheet-stats { display: flex; align-items: center; justify-content: space-between; }
        .vsm-sheet-price-label { font-size: 11px; font-weight: 700; color: var(--vsm-text-secondary); text-transform: uppercase; letter-spacing: .04em; }
        .vsm-sheet-price { font-size: 17px; font-weight: 800; color: var(--vsm-navy); margin-top: 2px; }
        .vsm-sheet-courts { font-size: 12px; font-weight: 700; color: var(--vsm-success); background: #E5F7EF; padding: 4px 10px; border-radius: 9999px; }
        .vsm-sheet-ctas { display: flex; flex-direction: column; gap: 8px; margin-top: 18px; }
        .vsm-cta-primary {
            display: flex; align-items: center; justify-content: center; gap: 8px;
            padding: 13px; border-radius: 12px; border: none; cursor: pointer; text-decoration: none;
            background: var(--vsm-orange); color: #fff; font-size: 14.5px; font-weight: 800;
        }
        .vsm-cta-primary:hover { background: #E67512; }
        .vsm-cta-primary svg { width: 17px; height: 17px; }
        .vsm-cta-row { display: flex; gap: 8px; }
        .vsm-cta-secondary {
            flex: 1; display: flex; align-items: center; justify-content: center; gap: 7px;
            padding: 12px; border-radius: 12px; border: 1px solid var(--vsm-border); cursor: pointer; text-decoration: none;
            background: #fff; color: var(--vsm-text); font-size: 13.5px; font-weight: 700;
        }
        .vsm-cta-secondary:hover { border-color: var(--vsm-navy); color: var(--vsm-navy); }
        .vsm-cta-secondary svg { width: 16px; height: 16px; }
        .vsm-cta-secondary:disabled { opacity: .5; cursor: not-allowed; }

        /* ===================== List sheet ===================== */
        .vsm-list-sheet {
            position: fixed; z-index: 850; left: 0; right: 0;
            bottom: 0;
            background: var(--vsm-surface); border-radius: 22px 22px 0 0;
            box-shadow: 0 -12px 40px rgba(11, 46, 89, 0.24);
            transform: translateY(100%); transition: transform .26s cubic-bezier(.22,1,.36,1);
            max-height: 76dvh; display: flex; flex-direction: column;
        }
        .vsm-list-sheet.is-open { transform: translateY(0); }
        @media (min-width: 1024px) {
            .vsm-list-sheet {
                left: auto; right: 20px;
                bottom: 20px; top: 180px;
                width: min(400px, calc(100vw - 40px));
                border-radius: 20px; max-height: none;
            }
        }
        .vsm-list-head { display: flex; align-items: center; justify-content: space-between; padding: 16px 18px 10px; flex-shrink: 0; }
        .vsm-list-title { font-size: 16px; font-weight: 800; color: var(--vsm-text); margin: 0; }
        .vsm-list-scroll { overflow-y: auto; min-height: 0; flex: 1; padding: 4px 14px 18px; }
        .vsm-list-card {
            display: flex; gap: 12px; padding: 12px; border-radius: 14px;
            border: 1px solid var(--vsm-border); cursor: pointer; background: #fff;
            transition: border-color .12s ease, background-color .12s ease;
        }
        .vsm-list-card + .vsm-list-card { margin-top: 8px; }
        .vsm-list-card:hover { border-color: var(--vsm-cyan); background: var(--vsm-cyan-light); }
        .vsm-list-card-img { width: 64px; height: 64px; border-radius: 10px; object-fit: cover; background: var(--vsm-cyan-light); flex-shrink: 0; }
        .vsm-list-card-name { font-size: 14px; font-weight: 700; color: var(--vsm-text); line-height: 1.3; }
        .vsm-list-card-addr { font-size: 12px; color: var(--vsm-text-secondary); margin-top: 2px; line-height: 1.4; overflow: hidden; text-overflow: ellipsis; display: -webkit-box; -webkit-line-clamp: 1; -webkit-box-orient: vertical; }
        .vsm-list-card-meta { display: flex; align-items: center; gap: 8px; margin-top: 6px; flex-wrap: wrap; }
        .vsm-list-card-badge { font-size: 10.5px; font-weight: 700; padding: 2px 8px; border-radius: 9999px; }
        .vsm-list-card-badge.dist { background: var(--vsm-cyan-light); color: var(--vsm-navy); }
        .vsm-list-card-badge.price { background: #FFF1E5; color: var(--vsm-orange); }

        /* ===================== Empty / error states ===================== */
        .vsm-inline-empty {
            position: absolute; left: 50%; top: 50%; transform: translate(-50%, -50%);
            z-index: 480; background: rgba(255,255,255,.97);
            border-radius: 16px; padding: 20px 24px; text-align: center;
            box-shadow: 0 10px 30px rgba(11,46,89,.16); max-width: 280px;
            display: none;
        }
        .vsm-inline-empty.is-visible { display: block; }
        .vsm-inline-empty svg { width: 30px; height: 30px; color: var(--vsm-text-secondary); margin: 0 auto 10px; }
        .vsm-inline-empty p { margin: 0; font-size: 13.5px; font-weight: 700; color: var(--vsm-text); }
        .vsm-inline-empty p.sub { font-weight: 500; color: var(--vsm-text-secondary); margin-top: 4px; font-size: 12.5px; }
        .vsm-inline-empty button {
            margin-top: 12px; padding: 8px 16px; border-radius: 9999px; border: none;
            background: var(--vsm-navy); color: #fff; font-size: 12.5px; font-weight: 700; cursor: pointer;
        }

        .vsm-toast {
            position: fixed; left: 50%; bottom: 30px;
            transform: translateX(-50%) translateY(12px); z-index: 1300;
            background: var(--vsm-navy-dark); color: #fff; padding: 10px 18px; border-radius: 9999px;
            font-size: 13px; font-weight: 600; opacity: 0; visibility: hidden;
            transition: opacity .2s ease, transform .2s ease; box-shadow: 0 8px 22px rgba(7,29,56,.3);
            max-width: 88vw; text-align: center;
        }
        .vsm-toast.is-visible { opacity: 1; visibility: visible; transform: translateX(-50%) translateY(0); }

        /* Skeleton shimmer for initial tile load */
        .vsm-loading-veil {
            position: absolute; inset: 0; z-index: 400;
            background: var(--vsm-bg);
            display: flex; align-items: center; justify-content: center;
            transition: opacity .25s ease;
        }
        .vsm-loading-veil.is-hidden { opacity: 0; pointer-events: none; }

        @media (max-width: 1023px) {
            body { overflow: hidden; }
        }
    </style>
</head>
<body>
<jsp:include page="/common/header-xtra.jsp" />

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<div class="vsm-app">
    <div class="vsm-map-layer">
        <div id="vsmMap"></div>

        <div id="vsmLoadingVeil" class="vsm-loading-veil">
            <div class="vsm-spinner-ring" style="width:30px;height:30px;border-width:3px;"></div>
        </div>

        <!-- Command bar: search + sport chips -->
        <div class="vsm-command">
            <div class="vsm-searchbar" role="search">
                <svg class="vsm-search-ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/></svg>
                <input type="search" id="vsmSearchInput" placeholder="Tìm sân quanh đây..." aria-label="Tìm sân quanh đây" autocomplete="off" />
                <button type="button" id="vsmSearchClear" class="vsm-search-clear" aria-label="Xóa tìm kiếm">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
                </button>
                <button type="button" id="vsmFilterToggle" class="vsm-search-btn" aria-label="Bộ lọc nâng cao" aria-expanded="false" aria-controls="vsmFilterPanel">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="4" x2="4" y1="21" y2="14"/><line x1="4" x2="4" y1="10" y2="3"/><line x1="12" x2="12" y1="21" y2="12"/><line x1="12" x2="12" y1="8" y2="3"/><line x1="20" x2="20" y1="21" y2="16"/><line x1="20" x2="20" y1="12" y2="3"/><line x1="2" x2="6" y1="14" y2="14"/><line x1="10" x2="14" y1="8" y2="8"/><line x1="18" x2="22" y1="16" y2="16"/></svg>
                </button>
            </div>

            <div class="vsm-chiprow" id="vsmChipRow" role="tablist" aria-label="Lọc theo môn thể thao">
                <button type="button" class="vsm-chip is-active" data-sport-id="" role="tab" aria-selected="true">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/></svg>
                    Tất cả
                </button>
                <c:forEach var="mon" items="${dsMon}">
                    <button type="button" class="vsm-chip" data-sport-id="${mon.monTheThaoID}" role="tab" aria-selected="false">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/></svg>
                        ${mon.tenMon}
                    </button>
                </c:forEach>
            </div>

            <!-- Advanced filter panel -->
            <div id="vsmFilterPanel" class="vsm-filter-panel" role="dialog" aria-label="Bộ lọc nâng cao">
                <p class="vsm-filter-title">Bán kính tìm kiếm</p>
                <div class="vsm-radius-grid" id="vsmRadiusGrid">
                    <button type="button" class="vsm-radius-opt" data-radius="">Toàn khu vực</button>
                    <button type="button" class="vsm-radius-opt" data-radius="2">2 km</button>
                    <button type="button" class="vsm-radius-opt" data-radius="5">5 km</button>
                    <button type="button" class="vsm-radius-opt" data-radius="10">10 km</button>
                    <button type="button" class="vsm-radius-opt" data-radius="20">20 km</button>
                    <button type="button" class="vsm-radius-opt" data-radius="50">50 km</button>
                </div>
                <div class="vsm-filter-row">
                    <span style="font-size:13.5px;font-weight:600;color:var(--vsm-text);">Chỉ hiển thị đang mở cửa</span>
                    <label class="vsm-switch">
                        <input type="checkbox" id="vsmOpenNowCheck" aria-label="Chỉ hiển thị cơ sở đang mở cửa" />
                        <span class="vsm-switch-track" aria-hidden="true"></span>
                    </label>
                </div>
                <div class="vsm-filter-actions">
                    <button type="button" class="vsm-filter-reset" id="vsmFilterReset">Đặt lại</button>
                    <button type="button" class="vsm-filter-apply" id="vsmFilterApply">Áp dụng</button>
                </div>
            </div>
        </div>

        <!-- Layers control -->
        <button type="button" id="vsmLayersBtn" class="vsm-fab vsm-layers-btn" aria-label="Chuyển kiểu bản đồ">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z"/><path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65"/><path d="m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65"/></svg>
        </button>

        <!-- Results pill (shown briefly after each fetch) -->
        <div id="vsmResultsPill" class="vsm-results-pill"></div>

        <!-- Bottom-right stack: list + GPS -->
        <div class="vsm-corner-stack">
            <button type="button" id="vsmListBtn" class="vsm-fab" aria-label="Xem danh sách cơ sở" aria-haspopup="dialog">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="8" x2="21" y1="6" y2="6"/><line x1="8" x2="21" y1="12" y2="12"/><line x1="8" x2="21" y1="18" y2="18"/><line x1="3" x2="3.01" y1="6" y2="6"/><line x1="3" x2="3.01" y1="12" y2="12"/><line x1="3" x2="3.01" y1="18" y2="18"/></svg>
            </button>
            <button type="button" id="vsmGpsBtn" class="vsm-fab" aria-label="Định vị vị trí của tôi">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 2v3"/><path d="M12 19v3"/><path d="M2 12h3"/><path d="M19 12h3"/><circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2"/></svg>
            </button>
        </div>

        <!-- Empty state (inline, doesn't cover whole map) -->
        <div id="vsmEmptyState" class="vsm-inline-empty">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><path d="m9.5 8.5 5 5"/><path d="m14.5 8.5-5 5"/></svg>
            <p>Không tìm thấy cơ sở phù hợp</p>
            <p class="sub">Hãy thử tăng bán kính hoặc đổi bộ lọc.</p>
            <button type="button" id="vsmEmptyReset">Đặt lại bộ lọc</button>
        </div>
    </div>
</div>

<!-- Detail bottom sheet -->
<div id="vsmBackdrop" class="vsm-backdrop"></div>
<section id="vsmSheet" class="vsm-sheet" role="dialog" aria-modal="true" aria-labelledby="vsmSheetTitle" aria-hidden="true">
    <div class="vsm-sheet-handle-wrap" id="vsmSheetHandle"><span class="vsm-sheet-handle"></span></div>
    <button type="button" id="vsmSheetClose" class="vsm-sheet-close" aria-label="Đóng">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
    </button>
    <div class="vsm-sheet-scroll">
        <div class="vsm-sheet-hero">
            <img id="vsmSheetImg" src="" alt="" />
            <span id="vsmSheetStatus" class="vsm-sheet-status"><span class="dot" aria-hidden="true"></span><span id="vsmSheetStatusText">Đang mở</span></span>
        </div>
        <div class="vsm-sheet-body">
            <h2 id="vsmSheetTitle" class="vsm-sheet-title"></h2>

            <div class="vsm-sheet-meta-row">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/></svg>
                <span id="vsmSheetAddr"></span>
            </div>
            <div class="vsm-sheet-meta-row" id="vsmSheetDistanceRow" hidden>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14.106 5.553a2 2 0 0 0 1.788 0l3.659-1.83A1 1 0 0 1 21 4.619v12.764a1 1 0 0 1-.553.894l-4.553 2.277a2 2 0 0 1-1.788 0l-4.212-2.106a2 2 0 0 0-1.788 0l-3.659 1.83A1 1 0 0 1 3 19.381V6.618a1 1 0 0 1 .553-.894l4.553-2.277a2 2 0 0 1 1.788 0z"/></svg>
                <span id="vsmSheetDistance"></span>
            </div>
            <div class="vsm-sheet-meta-row">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                <span id="vsmSheetHours"></span>
            </div>
            <div class="vsm-sheet-meta-row" id="vsmSheetPhoneRow" hidden>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384"/></svg>
                <span id="vsmSheetPhone"></span>
            </div>

            <div id="vsmSheetSports" class="vsm-sheet-chips"></div>

            <div class="vsm-sheet-divider"></div>
            <div class="vsm-sheet-stats">
                <div>
                    <div class="vsm-sheet-price-label">Giá từ</div>
                    <div id="vsmSheetPrice" class="vsm-sheet-price">—</div>
                </div>
                <div id="vsmSheetCourts" class="vsm-sheet-courts">0 sân sẵn sàng</div>
            </div>

            <div class="vsm-sheet-ctas">
                <a id="vsmCtaBook" href="#" class="vsm-cta-primary">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/></svg>
                    Đặt sân ngay
                </a>
                <div class="vsm-cta-row">
                    <a id="vsmCtaView" href="#" class="vsm-cta-secondary">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0"/><circle cx="12" cy="12" r="3"/></svg>
                        Xem sân
                    </a>
                    <a id="vsmCtaCall" href="#" class="vsm-cta-secondary">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384"/></svg>
                        Gọi điện
                    </a>
                    <a id="vsmCtaDirections" href="#" target="_blank" rel="noopener noreferrer" class="vsm-cta-secondary">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polygon points="3 11 22 2 13 21 11 13 3 11"/></svg>
                        Chỉ đường
                    </a>
                </div>
            </div>
        </div>
    </div>
</section>

<!-- List bottom sheet -->
<section id="vsmListSheet" class="vsm-list-sheet" role="dialog" aria-modal="true" aria-labelledby="vsmListTitle" aria-hidden="true">
    <div class="vsm-sheet-handle-wrap" id="vsmListHandle"><span class="vsm-sheet-handle"></span></div>
    <div class="vsm-list-head">
        <h2 id="vsmListTitle" class="vsm-list-title">Danh sách cơ sở</h2>
        <button type="button" id="vsmListClose" class="vsm-sheet-close" style="position:static;" aria-label="Đóng danh sách">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>
    </div>
    <div id="vsmListScroll" class="vsm-list-scroll"></div>
</section>

<div id="vsmToast" class="vsm-toast" role="status" aria-live="polite"></div>



<script>
(function () {
    'use strict';
    const CTX = "${ctx}";
    const MAPTILER_KEY = "${maptilerApiKey != null ? maptilerApiKey : ''}";
    const INITIAL_FACILITY_ID = "${not empty param.facilityId ? param.facilityId : ''}";
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    const DEFAULT_CENTER = [10.772561, 106.698021];
    const DEFAULT_ZOOM = 12;

    let map;
    let markerLayer;         // L.layerGroup holding facility markers
    let selfMarker = null;
    let userLocation = null; // {lat, lon}
    let currentSportId = '';
    let currentRadiusKm = '';
    let currentOpenNow = false;
    let currentKeyword = '';
    let facilitiesCache = []; // last successful fetch result
    let markerById = new Map();
    let focusedFacilityId = null;
    let fetchAbort = null;
    let searchDebounceTimer = null;
    let usingOsmTiles = false;

    // ================= Map init =================
    function initMap() {
        map = L.map('vsmMap', { zoomControl: false, attributionControl: true });
        map.setView(DEFAULT_CENTER, DEFAULT_ZOOM);
        L.control.zoom({ position: 'bottomleft' }).addTo(map);
        markerLayer = L.layerGroup().addTo(map);

        addTileLayer(!!MAPTILER_KEY);

        map.on('click', () => {
            closeSheet();
        });

        // Reveal map once first tiles start loading — never leave a blank white page.
        setTimeout(() => document.getElementById('vsmLoadingVeil').classList.add('is-hidden'), 260);
    }

    function addTileLayer(preferMapTiler) {
        if (window.vsmActiveTileLayer) {
            map.removeLayer(window.vsmActiveTileLayer);
        }
        let url, attribution;
        if (preferMapTiler && MAPTILER_KEY) {
            url = 'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=' + MAPTILER_KEY;
            attribution = '&copy; <a href="https://www.maptiler.com/" target="_blank" rel="noopener">MapTiler</a> &copy; OpenStreetMap';
            usingOsmTiles = false;
        } else {
            url = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
            attribution = '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">OpenStreetMap</a> contributors';
            usingOsmTiles = true;
        }
        const layer = L.tileLayer(url, { maxZoom: 19, attribution: attribution });
        // Fallback to OSM automatically if MapTiler tiles fail (bad/missing key) —
        // never leave a blank page just because a key is absent or invalid.
        let tileErrorCount = 0;
        layer.on('tileerror', function () {
            if (usingOsmTiles) return;
            tileErrorCount++;
            if (tileErrorCount > 3) {
                addTileLayer(false);
            }
        });
        layer.addTo(map);
        window.vsmActiveTileLayer = layer;
    }

    document.getElementById('vsmLayersBtn').addEventListener('click', function () {
        addTileLayer(usingOsmTiles); // toggle: if currently OSM, try MapTiler (and vice versa)
        showToast(usingOsmTiles ? 'Đã chuyển sang bản đồ OpenStreetMap' : 'Đã chuyển sang bản đồ MapTiler');
    });

    // ================= Toast =================
    let toastTimer = null;
    function showToast(msg) {
        const el = document.getElementById('vsmToast');
        el.textContent = msg;
        el.classList.add('is-visible');
        clearTimeout(toastTimer);
        toastTimer = setTimeout(() => el.classList.remove('is-visible'), 2600);
    }

    // ================= Fetch facilities =================
    function buildUrl(extra) {
        const params = new URLSearchParams();
        if (currentSportId) params.set('sportId', currentSportId);
        if (currentOpenNow) params.set('openNow', 'true');
        if (currentKeyword) params.set('keyword', currentKeyword);
        if (userLocation) {
            params.set('lat', userLocation.lat);
            params.set('lng', userLocation.lon);
            if (currentRadiusKm) params.set('radiusKm', currentRadiusKm);
        }
        if (extra && extra.facilityId) params.set('facilityId', extra.facilityId);
        return CTX + '/api/customer/facilities/map?' + params.toString();
    }

    function fetchFacilities(extra) {
        if (fetchAbort) fetchAbort.abort();
        fetchAbort = new AbortController();
        const url = buildUrl(extra);

        return fetch(url, { signal: fetchAbort.signal, headers: { 'Accept': 'application/json' } })
            .then(function (r) {
                return r.json().then(function (data) { return { ok: r.ok, status: r.status, data: data }; });
            })
            .then(function (res) {
                // JSON contract: success -> flat array. Error -> object {success:false,...}.
                if (!res.ok || !Array.isArray(res.data)) {
                    const msg = (res.data && (res.data.message || res.data.error)) || 'Không thể tải dữ liệu bản đồ.';
                    throw new Error(msg);
                }
                return res.data;
            })
            .catch(function (err) {
                if (err && err.name === 'AbortError') return null;
                console.error('Fetch facilities error:', err);
                showToast('Không thể tải dữ liệu bản đồ. Vui lòng thử lại.');
                return null;
            });
    }

    function refreshFacilities(opts) {
        opts = opts || {};
        fetchFacilities().then(function (data) {
            if (data === null) return; // aborted or errored (toast already shown)
            facilitiesCache = data;
            renderMarkers(data);
            updateResultsPill(data.length);
            toggleEmptyState(data.length === 0);
            if (opts.fitBounds !== false && data.length > 0) {
                fitToMarkers(data);
            }
        });
    }

    let resultsPillTimer = null;
    function updateResultsPill(count) {
        const pill = document.getElementById('vsmResultsPill');
        pill.textContent = count === 0 ? 'Không có cơ sở nào' : ('Tìm thấy ' + count + ' cơ sở');
        pill.classList.add('is-visible');
        clearTimeout(resultsPillTimer);
        resultsPillTimer = setTimeout(() => pill.classList.remove('is-visible'), 2200);
    }

    function toggleEmptyState(show) {
        document.getElementById('vsmEmptyState').classList.toggle('is-visible', !!show);
    }

    // ================= Markers =================
    const SPORT_ICON_PATH = '<path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/>';

    function buildMarkerIcon(fac, isFocused) {
        const isOpen = !!fac.moCuaHienTai;
        const cls = 'vsm-marker' + (isOpen ? '' : ' is-closed') + (isFocused ? ' is-focused' : '');
        const html = '<div class="' + cls + '">' +
            '<div class="vsm-marker-pin"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + SPORT_ICON_PATH + '</svg></div>' +
            '<span class="vsm-marker-dot" aria-hidden="true"></span>' +
            '</div>';
        return L.divIcon({ className: '', html: html, iconSize: [38, 38], iconAnchor: [19, 34], popupAnchor: [0, -30] });
    }

    function renderMarkers(list) {
        markerLayer.clearLayers();
        markerById = new Map();

        list.forEach(function (fac) {
            if (typeof fac.viDo !== 'number' || typeof fac.kinhDo !== 'number') return;
            const marker = L.marker([fac.viDo, fac.kinhDo], {
                icon: buildMarkerIcon(fac, fac.coSoId === focusedFacilityId),
                keyboard: true,
                alt: fac.tenCoSo || ''
            });
            marker.on('click', function () {
                focusMarker(fac.coSoId, { pan: true });
                openDetailSheet(fac);
            });
            marker.addTo(markerLayer);
            markerById.set(fac.coSoId, { marker: marker, fac: fac });
        });
    }

    function focusMarker(coSoId, opts) {
        opts = opts || {};
        focusedFacilityId = coSoId;
        markerById.forEach(function (entry, id) {
            entry.marker.setIcon(buildMarkerIcon(entry.fac, id === coSoId));
        });
        const entry = markerById.get(coSoId);
        if (entry && opts.pan) {
            // Pan so the marker stays clear of the bottom sheet (sheet covers
            // bottom ~78dvh on mobile, left column on desktop).
            const isDesktop = window.innerWidth >= 1024;
            const offsetY = isDesktop ? 0 : -140;
            const offsetX = isDesktop ? -160 : 0;
            const targetPoint = map.project(entry.marker.getLatLng(), map.getZoom()).add([offsetX, offsetY]);
            const targetLatLng = map.unproject(targetPoint, map.getZoom());
            map.setView(targetLatLng, Math.max(map.getZoom(), 15), { animate: !reduceMotion });
        }
    }

    function fitToMarkers(list) {
        const pts = list.filter(function (f) { return typeof f.viDo === 'number' && typeof f.kinhDo === 'number'; })
            .map(function (f) { return [f.viDo, f.kinhDo]; });
        if (userLocation) pts.push([userLocation.lat, userLocation.lon]);
        if (!pts.length) return;
        if (pts.length === 1) {
            map.setView(pts[0], 15, { animate: !reduceMotion });
            return;
        }
        map.fitBounds(L.latLngBounds(pts), { padding: [64, 64], maxZoom: 16, animate: !reduceMotion });
    }

    // ================= Search =================
    const searchInput = document.getElementById('vsmSearchInput');
    const searchClear = document.getElementById('vsmSearchClear');

    function runSearch() {
        currentKeyword = searchInput.value.trim();
        searchClear.classList.toggle('is-visible', currentKeyword.length > 0);
        refreshFacilities();
    }
    searchInput.addEventListener('input', function () {
        searchClear.classList.toggle('is-visible', searchInput.value.trim().length > 0);
        clearTimeout(searchDebounceTimer);
        searchDebounceTimer = setTimeout(runSearch, 400);
    });
    searchInput.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') {
            e.preventDefault();
            clearTimeout(searchDebounceTimer);
            runSearch();
        }
    });
    document.querySelector('.vsm-search-btn').addEventListener('click', function () {
        clearTimeout(searchDebounceTimer);
        runSearch();
    });
    searchClear.addEventListener('click', function () {
        searchInput.value = '';
        searchClear.classList.remove('is-visible');
        currentKeyword = '';
        refreshFacilities();
        searchInput.focus();
    });

    // ================= Sport chips =================
    document.getElementById('vsmChipRow').addEventListener('click', function (e) {
        const chip = e.target.closest('.vsm-chip');
        if (!chip) return;
        document.querySelectorAll('#vsmChipRow .vsm-chip').forEach(function (c) {
            c.classList.remove('is-active');
            c.setAttribute('aria-selected', 'false');
        });
        chip.classList.add('is-active');
        chip.setAttribute('aria-selected', 'true');
        currentSportId = chip.getAttribute('data-sport-id') || '';
        refreshFacilities();
    });

    // ================= Advanced filter panel =================
    const filterToggle = document.getElementById('vsmFilterToggle');
    const filterPanel = document.getElementById('vsmFilterPanel');
    let filterOpen = false;
    function setFilterOpen(open) {
        filterOpen = open;
        filterPanel.classList.toggle('is-open', open);
        filterToggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    }
    filterToggle.addEventListener('click', function () { setFilterOpen(!filterOpen); });
    document.addEventListener('click', function (e) {
        if (!filterOpen) return;
        if (filterPanel.contains(e.target) || filterToggle.contains(e.target)) return;
        setFilterOpen(false);
    });

    document.getElementById('vsmRadiusGrid').addEventListener('click', function (e) {
        const opt = e.target.closest('.vsm-radius-opt');
        if (!opt) return;
        document.querySelectorAll('.vsm-radius-opt').forEach(function (o) { o.classList.remove('is-active'); });
        opt.classList.add('is-active');
    });
    document.querySelector('.vsm-radius-opt[data-radius=""]').classList.add('is-active');

    document.getElementById('vsmFilterApply').addEventListener('click', function () {
        const activeRadius = document.querySelector('.vsm-radius-opt.is-active');
        currentRadiusKm = activeRadius ? activeRadius.getAttribute('data-radius') : '';
        currentOpenNow = document.getElementById('vsmOpenNowCheck').checked;
        setFilterOpen(false);
        if (currentRadiusKm && !userLocation) {
            showToast('Hãy bật định vị (GPS) để lọc theo bán kính.');
        }
        refreshFacilities();
    });
    document.getElementById('vsmFilterReset').addEventListener('click', resetAllFilters);
    document.getElementById('vsmEmptyReset').addEventListener('click', resetAllFilters);

    function resetAllFilters() {
        currentSportId = ''; currentRadiusKm = ''; currentOpenNow = false; currentKeyword = '';
        searchInput.value = ''; searchClear.classList.remove('is-visible');
        document.querySelectorAll('#vsmChipRow .vsm-chip').forEach(function (c, i) {
            c.classList.toggle('is-active', i === 0);
            c.setAttribute('aria-selected', i === 0 ? 'true' : 'false');
        });
        document.querySelectorAll('.vsm-radius-opt').forEach(function (o) {
            o.classList.toggle('is-active', o.getAttribute('data-radius') === '');
        });
        document.getElementById('vsmOpenNowCheck').checked = false;
        setFilterOpen(false);
        refreshFacilities();
    }

    // ================= GPS =================
    const gpsBtn = document.getElementById('vsmGpsBtn');
    function setGpsLoading(loading) {
        gpsBtn.innerHTML = loading
            ? '<span class="vsm-spinner-ring"></span>'
            : '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 2v3"/><path d="M12 19v3"/><path d="M2 12h3"/><path d="M19 12h3"/><circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2"/></svg>';
    }
    gpsBtn.addEventListener('click', function () {
        if (userLocation) {
            userLocation = null;
            gpsBtn.classList.remove('is-active');
            if (selfMarker) { map.removeLayer(selfMarker); selfMarker = null; }
            refreshFacilities();
            return;
        }
        if (!navigator.geolocation) {
            showToast('Trình duyệt không hỗ trợ định vị GPS.');
            return;
        }
        setGpsLoading(true);
        navigator.geolocation.getCurrentPosition(
            function (pos) {
                setGpsLoading(false);
                gpsBtn.classList.add('is-active');
                userLocation = { lat: pos.coords.latitude, lon: pos.coords.longitude };
                placeSelfMarker(userLocation.lat, userLocation.lon);
                map.setView([userLocation.lat, userLocation.lon], 14, { animate: !reduceMotion });
                refreshFacilities({ fitBounds: false });
            },
            function (err) {
                setGpsLoading(false);
                if (err && err.code === err.PERMISSION_DENIED) {
                    showToast('Bạn đã từ chối quyền định vị. Bản đồ vẫn hoạt động bình thường.');
                } else if (err && err.code === err.TIMEOUT) {
                    showToast('Định vị quá thời gian chờ. Vui lòng thử lại.');
                } else {
                    showToast('Không thể lấy vị trí của bạn. Vui lòng thử lại.');
                }
            },
            { enableHighAccuracy: true, timeout: 8000, maximumAge: 0 }
        );
    });

    function placeSelfMarker(lat, lon) {
        const html = '<div class="vsm-self-marker" aria-hidden="true"></div>';
        const icon = L.divIcon({ className: '', html: html, iconSize: [22, 22], iconAnchor: [11, 11] });
        if (selfMarker) {
            selfMarker.setLatLng([lat, lon]);
        } else {
            selfMarker = L.marker([lat, lon], { icon: icon, keyboard: false, zIndexOffset: -100, alt: 'Vị trí của bạn' }).addTo(map);
        }
    }

    // ================= Detail sheet =================
    const sheet = document.getElementById('vsmSheet');
    const backdrop = document.getElementById('vsmBackdrop');
    const listSheet = document.getElementById('vsmListSheet');
    let sheetOpen = false;
    let listSheetOpen = false;
    let sheetReturnFocus = null;

    function fmtVnd(n) {
        if (typeof n !== 'number' || !isFinite(n) || n <= 0) return null;
        return new Intl.NumberFormat('vi-VN').format(Math.round(n)) + 'đ/giờ';
    }

    function openDetailSheet(fac) {
        if (listSheetOpen) closeListSheet();
        sheetReturnFocus = document.activeElement;

        document.getElementById('vsmSheetTitle').textContent = fac.tenCoSo || '';
        document.getElementById('vsmSheetAddr').textContent = fac.diaChi || fac.address || 'Chưa cập nhật địa chỉ';

        const distRow = document.getElementById('vsmSheetDistanceRow');
        if (typeof fac.distanceKm === 'number') {
            distRow.hidden = false;
            document.getElementById('vsmSheetDistance').textContent = fac.distanceKm.toFixed(1) + ' km từ vị trí của bạn';
        } else {
            distRow.hidden = true;
        }

        const gioMo = fac.gioMoCua || '--:--';
        const gioDong = fac.gioDongCua || '--:--';
        document.getElementById('vsmSheetHours').textContent = gioMo + ' - ' + gioDong;

        const phoneRow = document.getElementById('vsmSheetPhoneRow');
        if (fac.soDienThoai) {
            phoneRow.hidden = false;
            document.getElementById('vsmSheetPhone').textContent = fac.soDienThoai;
        } else {
            phoneRow.hidden = true;
        }

        const statusEl = document.getElementById('vsmSheetStatus');
        const statusText = document.getElementById('vsmSheetStatusText');
        const isOpen = !!fac.moCuaHienTai;
        statusEl.classList.toggle('is-closed', !isOpen);
        statusText.textContent = isOpen ? 'Đang mở' : 'Đã đóng';

        const sportsEl = document.getElementById('vsmSheetSports');
        sportsEl.innerHTML = '';
        (Array.isArray(fac.sports) ? fac.sports : []).forEach(function (s) {
            const chip = document.createElement('span');
            chip.className = 'vsm-sheet-chip';
            chip.textContent = s;
            sportsEl.appendChild(chip);
        });

        const price = fmtVnd(fac.minPrice);
        document.getElementById('vsmSheetPrice').textContent = price || 'Liên hệ';
        document.getElementById('vsmSheetCourts').textContent = (fac.readyCourtCount || 0) + ' sân sẵn sàng';

        const img = document.getElementById('vsmSheetImg');
        img.onerror = function () { this.onerror = null; this.src = CTX + '/assets/images/vsport-fallback.svg'; };
        img.src = fac.hinhAnh || (CTX + '/assets/images/vsport-fallback.svg');
        img.alt = fac.tenCoSo || '';

        document.getElementById('vsmCtaBook').href = CTX + '/customer/dat-lich-truc-quan?coSoId=' + encodeURIComponent(fac.coSoId);
        document.getElementById('vsmCtaView').href = CTX + '/customer/dat-lich-truc-quan?coSoId=' + encodeURIComponent(fac.coSoId);

        const callBtn = document.getElementById('vsmCtaCall');
        if (fac.soDienThoai) {
            callBtn.href = 'tel:' + String(fac.soDienThoai).replace(/[^+\d]/g, '');
            callBtn.removeAttribute('aria-disabled');
            callBtn.style.pointerEvents = '';
            callBtn.style.opacity = '';
        } else {
            callBtn.href = '#';
            callBtn.setAttribute('aria-disabled', 'true');
            callBtn.style.pointerEvents = 'none';
            callBtn.style.opacity = '.5';
        }

        const dirBtn = document.getElementById('vsmCtaDirections');
        if (typeof fac.viDo === 'number' && typeof fac.kinhDo === 'number') {
            dirBtn.href = 'https://www.google.com/maps/dir/?api=1&destination=' + fac.viDo + ',' + fac.kinhDo;
            dirBtn.removeAttribute('aria-disabled');
            dirBtn.style.pointerEvents = '';
            dirBtn.style.opacity = '';
        } else {
            dirBtn.href = '#';
            dirBtn.setAttribute('aria-disabled', 'true');
            dirBtn.style.pointerEvents = 'none';
            dirBtn.style.opacity = '.5';
        }

        sheet.classList.add('is-open');
        sheet.setAttribute('aria-hidden', 'false');
        backdrop.classList.add('is-open');
        sheetOpen = true;
        lockScroll();
        document.getElementById('vsmSheetClose').focus();
    }

    function closeSheet() {
        if (!sheetOpen) return;
        sheetOpen = false;
        sheet.classList.remove('is-open');
        sheet.setAttribute('aria-hidden', 'true');
        if (!listSheetOpen) backdrop.classList.remove('is-open');
        unlockScroll();
        if (sheetReturnFocus && document.contains(sheetReturnFocus)) sheetReturnFocus.focus();
        sheetReturnFocus = null;
    }
    document.getElementById('vsmSheetClose').addEventListener('click', closeSheet);
    document.getElementById('vsmSheetHandle').addEventListener('click', closeSheet);
    backdrop.addEventListener('click', function () { closeSheet(); closeListSheet(); });
    sheet.addEventListener('keydown', function (e) { trapTab(sheet, e); });

    // ================= List sheet =================
    function openListSheet() {
        if (sheetOpen) closeSheet();
        sheetReturnFocus = document.activeElement;
        const scroll = document.getElementById('vsmListScroll');
        scroll.innerHTML = '';

        const items = facilitiesCache.slice(0, 30);
        if (!items.length) {
            const empty = document.createElement('p');
            empty.style.cssText = 'padding:24px 8px;text-align:center;color:var(--vsm-text-secondary);font-size:13.5px;';
            empty.textContent = 'Không có cơ sở nào trong khu vực hiện tại.';
            scroll.appendChild(empty);
        } else {
            items.forEach(function (fac) {
                const card = document.createElement('div');
                card.className = 'vsm-list-card';
                card.setAttribute('role', 'button');
                card.setAttribute('tabindex', '0');
                card.setAttribute('aria-label', 'Xem ' + (fac.tenCoSo || '') + ' trên bản đồ');

                const img = document.createElement('img');
                img.className = 'vsm-list-card-img';
                img.loading = 'lazy';
                img.alt = '';
                img.src = fac.hinhAnh || (CTX + '/assets/images/vsport-fallback.svg');
                img.onerror = function () { this.onerror = null; this.src = CTX + '/assets/images/vsport-fallback.svg'; };
                card.appendChild(img);

                const info = document.createElement('div');
                info.style.cssText = 'min-width:0;flex:1;';
                const name = document.createElement('div');
                name.className = 'vsm-list-card-name';
                name.textContent = fac.tenCoSo || '';
                info.appendChild(name);
                const addr = document.createElement('div');
                addr.className = 'vsm-list-card-addr';
                addr.textContent = fac.diaChi || fac.address || '';
                info.appendChild(addr);

                const meta = document.createElement('div');
                meta.className = 'vsm-list-card-meta';
                if (typeof fac.distanceKm === 'number') {
                    const dist = document.createElement('span');
                    dist.className = 'vsm-list-card-badge dist';
                    dist.textContent = fac.distanceKm.toFixed(1) + ' km';
                    meta.appendChild(dist);
                }
                const hours = document.createElement('span');
                hours.className = 'vsm-list-card-badge dist';
                hours.textContent = (fac.gioMoCua || '--:--') + '-' + (fac.gioDongCua || '--:--');
                meta.appendChild(hours);
                const price = fmtVnd(fac.minPrice);
                if (price) {
                    const priceBadge = document.createElement('span');
                    priceBadge.className = 'vsm-list-card-badge price';
                    priceBadge.textContent = price;
                    meta.appendChild(priceBadge);
                }
                info.appendChild(meta);
                card.appendChild(info);

                function activate() {
                    closeListSheet();
                    focusMarker(fac.coSoId, { pan: true });
                    openDetailSheet(fac);
                }
                card.addEventListener('click', activate);
                card.addEventListener('keydown', function (e) {
                    if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); activate(); }
                });
                scroll.appendChild(card);
            });
        }

        listSheet.classList.add('is-open');
        listSheet.setAttribute('aria-hidden', 'false');
        backdrop.classList.add('is-open');
        listSheetOpen = true;
        lockScroll();
        document.getElementById('vsmListClose').focus();
    }

    function closeListSheet() {
        if (!listSheetOpen) return;
        listSheetOpen = false;
        listSheet.classList.remove('is-open');
        listSheet.setAttribute('aria-hidden', 'true');
        if (!sheetOpen) backdrop.classList.remove('is-open');
        unlockScroll();
        if (sheetReturnFocus && document.contains(sheetReturnFocus)) sheetReturnFocus.focus();
        sheetReturnFocus = null;
    }
    document.getElementById('vsmListBtn').addEventListener('click', openListSheet);
    document.getElementById('vsmListClose').addEventListener('click', closeListSheet);
    document.getElementById('vsmListHandle').addEventListener('click', closeListSheet);
    listSheet.addEventListener('keydown', function (e) { trapTab(listSheet, e); });

    // ================= Shared sheet helpers =================
    let scrollLocks = 0;
    function lockScroll() { scrollLocks++; document.body.style.overflow = 'hidden'; }
    function unlockScroll() { scrollLocks = Math.max(0, scrollLocks - 1); if (!scrollLocks) document.body.style.overflow = ''; }

    function focusables(container) {
        return Array.from(container.querySelectorAll('a[href], button:not([disabled]), input, [tabindex]:not([tabindex="-1"])'))
            .filter(function (el) { return el.offsetParent !== null; });
    }
    function trapTab(container, e) {
        if (e.key === 'Escape') { closeSheet(); closeListSheet(); return; }
        if (e.key !== 'Tab') return;
        const list = focusables(container);
        if (!list.length) return;
        const first = list[0], last = list[list.length - 1];
        if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
        else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
    }
    document.addEventListener('keydown', function (e) {
        if (e.key !== 'Escape') return;
        if (sheetOpen) closeSheet();
        else if (listSheetOpen) closeListSheet();
        else if (filterOpen) setFilterOpen(false);
    });

    // Drag-down to close on mobile (both sheets share the pattern).
    (function initDrag(handleId, sheetEl, closeFn) {
        [['vsmSheetHandle', sheet, closeSheet], ['vsmListHandle', listSheet, closeListSheet]].forEach(function (cfg) {
            const handle = document.getElementById(cfg[0]);
            const targetSheet = cfg[1];
            const close = cfg[2];
            let startY = null, delta = 0, dragging = false;
            function onStart(e) { dragging = true; startY = (e.touches ? e.touches[0] : e).clientY; delta = 0; targetSheet.style.transition = 'none'; }
            function onMove(e) {
                if (!dragging || startY == null) return;
                const y = (e.touches ? e.touches[0] : e).clientY;
                delta = Math.max(0, y - startY);
                targetSheet.style.transform = 'translateY(' + delta + 'px)';
            }
            function onEnd() {
                if (!dragging) return;
                dragging = false;
                targetSheet.style.transition = '';
                if (delta > 110) { close(); } else { targetSheet.style.transform = ''; }
                startY = null;
            }
            handle.addEventListener('touchstart', onStart, { passive: true });
            handle.addEventListener('touchmove', onMove, { passive: true });
            handle.addEventListener('touchend', onEnd);
            handle.addEventListener('mousedown', function (e) { onStart(e); e.preventDefault(); });
            document.addEventListener('mousemove', onMove);
            document.addEventListener('mouseup', onEnd);
        });
    })();

    // ================= facilityId deep link =================
    function loadInitialFacility() {
        if (!INITIAL_FACILITY_ID) {
            refreshFacilities();
            return;
        }
        fetchFacilities({ facilityId: INITIAL_FACILITY_ID }).then(function (data) {
            if (data === null) { refreshFacilities(); return; }
            if (!data.length) {
                showToast('Không tìm thấy cơ sở hoặc cơ sở chưa cập nhật vị trí.');
                refreshFacilities();
                return;
            }
            const fac = data[0];
            facilitiesCache = data;
            // Load the full surrounding set too, so the map isn't just one pin.
            refreshFacilities({ fitBounds: false });
            renderMarkers([fac]);
            map.setView([fac.viDo, fac.kinhDo], 16, { animate: false });
            focusMarker(fac.coSoId, { pan: false });
            openDetailSheet(fac);
        });
    }

    // ================= Boot =================
    document.addEventListener('DOMContentLoaded', function () {
        initMap();
        loadInitialFacility();
        window.addEventListener('resize', function () { if (map) map.invalidateSize(); });
    });
})();
</script>
</body>
</html>
