<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%--
    V-SPORT Customer Design System (Color Rebrand)
    Scope: CUSTOMER pages only. Do NOT include from admin/manager/staff.
    - Brand identity: Navy + Sport Blue + Electric Cyan + Orange CTA.
    - Green is reserved exclusively for Success semantics (paid, active, confirmed, in-stock).
    - One radius scale. Flat surfaces, restrained shadows (minimalist-skill discipline).
    - Tokens are namespaced --vs-* to avoid clashing with page-level vars.
    - Also re-themes the shared header.jsp accent to V-SPORT blue ON CUSTOMER PAGES ONLY
      (targeted !important overrides; admin/manager never load this file).
    - Typography: ONE font system for customer pages (--vs-font-sans == --vs-font-heading).
      Overrides the GLOBAL `h1..h6 { Barlow Condensed }` rule from common/head.jsp — but
      SCOPED to customer pages only (this file is never included by admin/manager/staff).
--%>
<link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet" crossorigin="anonymous">
<style>
    :root {
        /* ---- Typography tokens (customer design system) ----
           Single sans family, tuned for Vietnamese; headings share it (no condensed/display). */
        --vs-font-sans: 'Be Vietnam Pro', 'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
        --vs-font-heading: var(--vs-font-sans);
        --vs-text-primary: #111111;

        /* ---- Brand Black/Dark (formerly navy) ---- */
        --vs-primary-950: #000000;
        --vs-primary-900: #111111;
        --vs-primary-800: #222222;
        --vs-primary-700: #333333;
        --vs-primary-600: #e3000f; /* Red as primary action */
        --vs-primary-500: #ff1a2b;

        /* ---- Accent (Red instead of cyan) ---- */
        --vs-cyan-600: #c2000d;
        --vs-cyan-500: #e3000f;
        --vs-cyan-100: #ffe5e6;
        --vs-cyan-50: #fff0f1;

        /* ---- Main CTA (Red instead of orange) ---- */
        --vs-orange-600: #c2000d;
        --vs-orange-500: #e3000f;
        --vs-orange-100: #ffe5e6;

        /* ---- Back-compat aliases used across existing customer/auth markup ---- */
        --vs-primary: var(--vs-primary-600);        /* solid buttons / white-text surfaces (AA on white) */
        --vs-primary-strong: var(--vs-primary-900);  /* hover / pressed / deep navy */
        --vs-accent: var(--vs-cyan-500);             /* icons, active accents, focus */
        --vs-primary-50: var(--vs-cyan-50);          /* chip / tint backgrounds */
        --vs-primary-100: var(--vs-cyan-100);

        /* ---- neutrals / surfaces ---- */
        --vs-background: #f8f9fa; /* Light gray background */
        --vs-ink: #111111;
        --vs-text: #111111;
        --vs-text-secondary: #444444;
        --vs-muted: #777777;
        --vs-surface: #f8f9fa;
        --vs-surface-soft: #eeeeee;
        --vs-card: #FFFFFF;
        --vs-border: #dddddd;

        /* ---- semantic (Green stays Success only; never rebranded) ---- */
        --vs-success: #16A36A;
        --vs-success-bg: #E5F7EF;
        --vs-warning: #F4B740;
        --vs-warning-bg: #FFF7DA;
        --vs-danger: #e3000f;
        --vs-danger-bg: #ffe5e6;

        /* legacy semantic aliases kept so existing markup keeps working */
        --vs-danger-legacy: var(--vs-danger);
        --vs-warn: var(--vs-warning);
        --vs-warn-bg: var(--vs-warning-bg);
        --vs-ok-bg: var(--vs-success-bg);

        /* ---- interaction ---- */
        --vs-focus-ring: rgba(227, 0, 15, 0.35); /* Red focus ring */
        --vs-overlay: rgba(0, 0, 0, 0.68);

        /* ---- radius scale (one system) ---- */
        --vs-r-card: 14px;
        --vs-r-btn: 10px;
        --vs-r-chip: 9999px;

        /* ---- shell heights ---- */
        --vs-bottomnav-h: 70px;
        --vs-bottomnav-h-desktop: 80px;

        /* Re-point the shared header's var-driven accent to V-SPORT blue. */
        --primary: var(--vs-primary-600) !important;
        --primary-hover: var(--vs-primary-900) !important;
    }

    /* ===== Typography normalisation (customer pages only) =====
       common/head.jsp sets a GLOBAL `body { Barlow }` + `h1..h6 { Barlow Condensed }`.
       On customer pages we unify onto the V-SPORT sans stack. This file is included AFTER
       head.jsp, so equal-specificity selectors here win; individual pages that set their own
       font in a later <style> still override (intentional per-page choices are preserved). */
    body { font-family: var(--vs-font-sans); }
    h1, h2, h3, h4, h5, h6 { font-family: var(--vs-font-heading); }

    /* Reserve space so the fixed bottom nav never covers content, at every width. */
    body { padding-bottom: calc(var(--vs-bottomnav-h) + env(safe-area-inset-bottom, 0px) + 6px); }
    @media (min-width: 1024px) {
        body { padding-bottom: calc(var(--vs-bottomnav-h-desktop) + env(safe-area-inset-bottom, 0px) + 6px); }
    }

    /* ================= Header accent unification (customer pages only) ============= */
    .navbar .nav-links a::after { background-color: var(--vs-primary-600) !important; }
    .navbar .header-icon-badge,
    .side-drawer .avatar-circle { background-color: var(--vs-primary-600) !important; }
    .side-drawer .drawer-link:hover { color: var(--vs-primary-600) !important; }
    .btn-register-shimmer {
        background: linear-gradient(135deg, var(--vs-orange-500) 0%, var(--vs-orange-600) 100%) !important;
        color: #ffffff !important;
        box-shadow: 0 4px 14px rgba(249, 115, 22, 0.25) !important;
    }
    .user-avatar { color: #ffffff !important; }

    /* ============================ Reusable components ============================== */
    .vs-card {
        background: var(--vs-card);
        border: 1px solid var(--vs-border);
        border-radius: var(--vs-r-card);
        box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
    }

    .vs-btn {
        display: inline-flex; align-items: center; justify-content: center; gap: 8px;
        font-family: 'Poppins', 'Inter', system-ui, sans-serif;
        font-weight: 600; font-size: 14px; line-height: 1;
        padding: 12px 18px; border-radius: var(--vs-r-btn);
        border: 1px solid transparent; cursor: pointer; text-decoration: none;
        transition: background-color .18s ease, transform .1s ease, border-color .18s ease;
        white-space: nowrap;
    }
    .vs-btn:active { transform: translateY(1px); }
    .vs-btn:focus-visible { outline: 3px solid var(--vs-focus-ring); outline-offset: 2px; }
    .vs-btn:disabled { opacity: .55; cursor: not-allowed; }

    /* Primary CTA (booking / payment / confirm actions) -> Orange */
    .vs-btn-primary { background: var(--vs-orange-500); color: #fff; }
    .vs-btn-primary:hover { background: var(--vs-orange-600); color: #fff; }

    /* Secondary action -> Blue */
    .vs-btn-secondary { background: var(--vs-primary-600); color: #fff; }
    .vs-btn-secondary:hover { background: var(--vs-primary-700); color: #fff; }

    .vs-btn-ghost { background: #fff; color: var(--vs-text); border-color: var(--vs-border); }
    .vs-btn-ghost:hover { border-color: var(--vs-cyan-500); color: var(--vs-primary-600); }

    /* Category / filter chips */
    .vs-chip {
        display: inline-flex; align-items: center; gap: 6px;
        padding: 8px 14px; border-radius: var(--vs-r-chip);
        background: #fff; border: 1px solid var(--vs-border);
        color: var(--vs-text); font-size: 13.5px; font-weight: 600;
        cursor: pointer; white-space: nowrap; text-decoration: none;
        transition: all .16s ease;
    }
    .vs-chip:hover { border-color: var(--vs-cyan-500); color: var(--vs-primary-600); }
    .vs-chip.is-active { background: var(--vs-primary-600); border-color: var(--vs-primary-600); color: #fff; }

    /* Search bar */
    .vs-search {
        display: flex; align-items: center; gap: 10px;
        background: #fff; border: 1px solid var(--vs-border);
        border-radius: var(--vs-r-btn); padding: 12px 14px;
    }
    .vs-search:focus-within { border-color: var(--vs-cyan-500); box-shadow: 0 0 0 3px var(--vs-focus-ring); }
    .vs-search input {
        flex: 1; border: none; outline: none; background: transparent;
        font-size: 15px; color: var(--vs-text); min-width: 0;
    }
    .vs-search input::placeholder { color: var(--vs-muted); }

    /* Reputation badge (Success/Warning/Danger stay semantic — never rebranded) */
    .vs-rep { display: inline-flex; align-items: center; gap: 6px; padding: 5px 12px; border-radius: 9999px; font-size: 12.5px; font-weight: 700; }
    .vs-rep-good  { background: var(--vs-success-bg);  color: var(--vs-success); }
    .vs-rep-watch { background: var(--vs-warning-bg); color: #8a6116; }
    .vs-rep-bad   { background: var(--vs-danger-bg); color: var(--vs-danger); }

    /* Generic status utility classes for use across customer pages */
    .vs-status-success { background: var(--vs-success-bg); color: var(--vs-success); }
    .vs-status-warning { background: var(--vs-warning-bg); color: #8a6116; }
    .vs-status-danger  { background: var(--vs-danger-bg); color: var(--vs-danger); }

    /* ============================== Bottom navigation ============================== */
    /* Visible at every width, full-width, no side margins. Bar height IS the full
       visual envelope (70px mobile / 84px desktop) so the raised center circle pokes
       out of the white bar itself — no gray page background gap above the bar. */
    .vs-bottomnav {
        position: fixed; left: 0; right: 0; bottom: 0; z-index: 1200;
        display: grid; grid-template-columns: repeat(5, 1fr);
        align-items: stretch;
        background: #fff; border-top: 1px solid var(--vs-border);
        height: calc(var(--vs-bottomnav-h) + env(safe-area-inset-bottom, 0px));
        padding-bottom: env(safe-area-inset-bottom, 0px);
        box-shadow: 0 -1px 4px rgba(15, 23, 42, 0.04);
    }
    .vs-bn-item {
        display: flex; flex-direction: column; align-items: center; justify-content: center;
        gap: 5px; height: 100%; min-width: 44px; min-height: 44px;
        color: var(--vs-muted); text-decoration: none; font-size: 13px; font-weight: 500;
        line-height: 1.15; border: none; background: transparent; cursor: pointer;
    }
    .vs-bn-item .vs-bn-ic { font-size: 24px; line-height: 1; }
    /* Lucide inline SVG icons (bottom-nav.jsp) size via width/height, not font-size. */
    svg.vs-bn-ic { width: 25px; height: 25px; flex-shrink: 0; }
    .vs-bn-item.is-active { color: var(--vs-primary-600); font-weight: 700; }
    .vs-bn-item.is-active .vs-bn-ic { color: var(--vs-primary-600); }
    .vs-bn-item:focus-visible { outline: 2px solid var(--vs-cyan-500); outline-offset: -2px; border-radius: 6px; }

    /* Center raised action: Ghép trận. White fill, navy outline by default —
       only intensifies (darker border) when the route is actually active. */
    .vs-bn-center { position: relative; justify-content: flex-end; padding-bottom: 10px; }
    .vs-bn-fab {
        position: absolute; top: -20px; left: 50%; transform: translateX(-50%);
        width: 64px; height: 64px; border-radius: 50%;
        background: var(--vs-primary-900); color: #fff;
        display: flex; align-items: center; justify-content: center;
        box-shadow: 0 0 0 5px var(--vs-cyan-100), 0 3px 10px rgba(15, 23, 42, 0.10);
        border: 2px solid var(--vs-cyan-500);
    }
    .vs-bn-fab .vs-bn-ic { font-size: 27px; color: #fff; }
    .vs-bn-fab svg.vs-bn-ic { width: 28px; height: 28px; }
    .vs-bn-center .vs-bn-fablabel { font-size: 13px; font-weight: 500; color: var(--vs-muted); line-height: 1.15; }
    .vs-bn-center.is-active .vs-bn-fab { border-color: var(--vs-orange-500); border-width: 2.5px; }
    .vs-bn-center.is-active .vs-bn-fablabel { color: var(--vs-primary-600); font-weight: 700; }

    /* Desktop: taller bar (80px envelope), larger circle, larger touch targets. */
    @media (min-width: 1024px) {
        .vs-bottomnav { height: var(--vs-bottomnav-h-desktop); }
        .vs-bn-item { font-size: 14px; gap: 6px; }
        .vs-bn-item .vs-bn-ic { font-size: 26px; }
        svg.vs-bn-ic { width: 27px; height: 27px; }
        .vs-bn-center { padding-bottom: 12px; }
        .vs-bn-fab { width: 72px; height: 72px; top: -22px; }
        .vs-bn-fab .vs-bn-ic { font-size: 29px; }
        .vs-bn-fab svg.vs-bn-ic { width: 31px; height: 31px; }
        .vs-bn-center .vs-bn-fablabel { font-size: 14px; }
    }
</style>
