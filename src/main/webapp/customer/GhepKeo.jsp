<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Ghép trận - V-SPORT</title>
    <jsp:include page="/common/head.jsp" />
    <jsp:include page="/customer/common/vsport-theme.jsp" />
    <style>
        /* =====================================================================
           V-SPORT · Trang Ghép trận (Customer)
           Mọi rule đều được scope dưới .vs-matchmaking-page để không rò rỉ sang
           các trang khác. Không dùng selector trần (button{}, input{}, .card{}).
           Màu lấy từ design system --vs-* (customer/common/vsport-theme.jsp);
           giá trị fallback chỉ dùng khi token chưa tồn tại.
           Font: kế thừa từ design system (Be Vietnam Pro) — KHÔNG override.
           ===================================================================== */

        body.vs-matchmaking-page {
            background: var(--vs-surface, #F4F7FB);
            color: var(--vs-text, #102A43);
            padding-bottom: calc(110px + env(safe-area-inset-bottom, 0px));
        }
        .vs-matchmaking-page :is(h1, h2, h3, h4) {
            font-family: inherit;
            text-transform: none;
            letter-spacing: normal;
        }
        /* Mọi khối của trang này khai báo height kèm padding, nên cần border-box.
           Chỉ áp cho class `match-*` để không đụng tới header/bottom-nav dùng chung. */
        .vs-matchmaking-page [class^="match-"],
        .vs-matchmaking-page [class*=" match-"] {
            box-sizing: border-box;
        }
        /* Các khối trạng thái được bật/tắt bằng thuộc tính `hidden`. Lớp CSS của
           chúng khai báo display:grid/flex, vốn thắng `[hidden]` của trình duyệt,
           nên phải ép lại ở đây — nếu không skeleton sẽ hiển thị vĩnh viễn. */
        .vs-matchmaking-page [hidden] {
            display: none !important;
        }

        /* ---- Hiệu ứng nhấn dùng chung (P19) ---------------------------------- */
        .vs-matchmaking-page :is(.match-tab, .match-action, .match-filter-button, .match-chip, .match-hero-back, .match-hero-mine) {
            transition: transform .12s ease, box-shadow .12s ease,
                        background-color .12s ease, border-color .12s ease, color .12s ease;
        }
        /* head.jsp declares `* { outline: none !important; }`, which defeats any
           outline-based focus ring. Use a box-shadow ring so focus stays visible. */
        .vs-matchmaking-page :is(.match-tab, .match-action, .match-filter-button,
                                 .match-chip, .match-hero-back, .match-hero-mine):focus-visible {
            box-shadow: 0 0 0 3px var(--vs-card, #fff),
                        0 0 0 6px var(--vs-cyan-500, #18C8E8);
        }
        /* Sau :focus-visible để hiệu ứng nhấn thắng khi đang giữ chuột. */
        .vs-matchmaking-page :is(.match-tab, .match-action, .match-filter-button, .match-chip, .match-hero-back, .match-hero-mine):active:not(:disabled) {
            transform: translateY(2px) scale(0.985);
            box-shadow: inset 0 3px 8px rgba(7, 31, 58, .20);
        }

        /* ---- Hero (P5) -------------------------------------------------------- */
        .match-hero {
            background: linear-gradient(135deg,
                        var(--vs-primary-950, #071A2F) 0%,
                        var(--vs-primary-900, #0B2545) 38%,
                        var(--vs-primary-700, #185A9D) 78%,
                        var(--vs-cyan-600, #08A9CC) 100%);
            color: #fff;
            position: relative;
            overflow: hidden;
        }
        .match-hero::after {
            content: "";
            position: absolute; right: -70px; top: -80px;
            width: 300px; height: 300px; pointer-events: none;
            background: radial-gradient(circle, rgba(255, 255, 255, .13), transparent 68%);
        }
        .match-hero-inner {
            width: min(1280px, calc(100% - 40px));
            margin: 0 auto;
            min-height: 124px;
            display: flex;
            align-items: center;
            gap: 16px;
            padding: 20px 0;
            position: relative;
            z-index: 1;
        }
        .match-hero-back {
            width: 42px; height: 42px; flex-shrink: 0;
            display: inline-flex; align-items: center; justify-content: center;
            border-radius: 999px; border: 1px solid rgba(255, 255, 255, .22);
            background: rgba(255, 255, 255, .12); color: #fff; cursor: pointer;
        }
        .match-hero-back:hover { background: rgba(255, 255, 255, .22); }
        .match-hero-icon {
            width: 52px; height: 52px; flex-shrink: 0;
            display: inline-flex; align-items: center; justify-content: center;
            border-radius: 16px;
            background: rgba(255, 255, 255, .14);
            border: 1px solid rgba(255, 255, 255, .22);
        }
        .match-hero-text { min-width: 0; flex: 1; }
        .match-hero-title { font-size: 24px; font-weight: 800; margin: 0; line-height: 1.2; }
        .match-hero-sub {
            font-size: 14px; margin: 5px 0 0;
            color: rgba(255, 255, 255, .82); line-height: 1.45;
        }
        .match-hero-mine {
            display: inline-flex; align-items: center; gap: 8px; flex-shrink: 0;
            padding: 11px 18px; border-radius: 999px;
            background: rgba(255, 255, 255, .12);
            border: 1px solid rgba(255, 255, 255, .26);
            color: #fff; font-size: 14px; font-weight: 700;
            font-family: inherit; cursor: pointer;
        }
        .match-hero-mine:hover { background: rgba(255, 255, 255, .22); }
        .match-hero-badge {
            display: inline-flex; align-items: center; justify-content: center;
            min-width: 20px; padding: 2px 7px; border-radius: 999px;
            background: var(--vs-orange-500, #FF8A24); color: #fff;
            font-size: 11px; font-weight: 800;
        }

        /* ---- Container (P6) --------------------------------------------------- */
        .match-container {
            width: min(1280px, calc(100% - 40px));
            margin: 0 auto;
            padding: 22px 0 130px;
        }

        /* ---- Thẻ nền dùng chung ---------------------------------------------- */
        .match-card-surface {
            background: var(--vs-card, #fff);
            border: 1px solid var(--vs-border, #DCE5EF);
            border-radius: 16px;
            box-shadow: 0 1px 3px rgba(11, 37, 69, .05);
        }

        /* ---- Thẻ cơ sở (context) --------------------------------------------- */
        .match-facility {
            display: flex; align-items: center; gap: 14px;
            padding: 14px 18px; margin-bottom: 16px;
        }
        .match-facility-icon {
            width: 46px; height: 46px; border-radius: 14px; flex-shrink: 0;
            background: var(--vs-cyan-100, #DDF8FC); color: var(--vs-primary-700, #185A9D);
            display: inline-flex; align-items: center; justify-content: center;
            font-weight: 800; font-size: 18px;
        }
        .match-facility-name { font-size: 15px; font-weight: 800; color: var(--vs-text, #102A43); }
        .match-facility-addr { font-size: 13px; color: var(--vs-text-secondary, #486581); margin-top: 2px; }

        /* ---- Tabs (P7) -------------------------------------------------------- */
        .match-tabs {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 6px;
            height: 58px;
            padding: 6px;
            margin-bottom: 16px;
            background: var(--vs-card, #fff);
            border: 1px solid var(--vs-border, #DCE5EF);
            border-radius: 16px;
            box-shadow: 0 1px 3px rgba(11, 37, 69, .05);
        }
        .match-tab {
            height: 44px;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px;
            border: none; background: transparent; border-radius: 11px;
            font-family: inherit; font-size: 14px; font-weight: 700;
            color: var(--vs-primary-900, #0B2545);
            cursor: pointer; white-space: nowrap; overflow: hidden;
        }
        .match-tab:hover:not(.is-active) { background: var(--vs-cyan-50, #F0FCFE); }
        .match-tab.is-active {
            background: linear-gradient(135deg, var(--vs-primary-600, #1677D2) 0%, var(--vs-cyan-500, #18C8E8) 100%);
            color: #fff;
            box-shadow: 0 4px 12px rgba(22, 119, 210, .28);
        }
        .match-tab-label { overflow: hidden; text-overflow: ellipsis; }

        /* ---- Bộ lọc (P8) ------------------------------------------------------ */
        .match-filters { padding: 18px; margin-bottom: 16px; }
        .match-filter-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr)) auto auto;
            gap: 14px;
            align-items: end;
        }
        .match-field { min-width: 0; }
        .match-field-label {
            display: flex; align-items: center; gap: 6px;
            font-size: 12px; font-weight: 700;
            color: var(--vs-text-secondary, #486581);
            margin-bottom: 7px;
        }
        .match-field-label svg { color: var(--vs-primary-600, #1677D2); flex-shrink: 0; }
        .match-input {
            width: 100%; height: 46px; padding: 0 13px;
            background: #fff; color: var(--vs-text, #102A43);
            border: 1px solid var(--vs-border, #DCE5EF); border-radius: 11px;
            font-family: inherit; font-size: 14px; font-weight: 600;
            transition: border-color .12s ease, box-shadow .12s ease;
        }
        .match-input:focus {
            outline: none;
            border-color: var(--vs-primary-600, #1677D2);
            box-shadow: 0 0 0 3px var(--vs-focus-ring, rgba(24, 200, 232, .35));
        }
        .match-filter-button {
            height: 46px; padding: 0 20px;
            display: inline-flex; align-items: center; justify-content: center; gap: 7px;
            border-radius: 11px; border: 1px solid transparent;
            font-family: inherit; font-size: 14px; font-weight: 700;
            cursor: pointer; white-space: nowrap;
        }
        .match-filter-button.is-search {
            background: var(--vs-primary-600, #1677D2); color: #fff;
        }
        .match-filter-button.is-search:hover { background: var(--vs-primary-700, #185A9D); }
        .match-filter-button.is-clear {
            background: #fff; color: var(--vs-text-secondary, #486581);
            border-color: var(--vs-border, #DCE5EF);
        }
        .match-filter-button.is-clear:hover {
            border-color: var(--vs-primary-600, #1677D2);
            color: var(--vs-primary-600, #1677D2);
        }

        /* ---- Dải tóm tắt + sắp xếp (P9) --------------------------------------- */
        .match-summary {
            display: flex; align-items: center; justify-content: space-between;
            gap: 14px; flex-wrap: wrap; margin-bottom: 14px;
        }
        .match-summary-left { display: flex; align-items: baseline; gap: 9px; flex-wrap: wrap; }
        .match-summary-title { font-size: 17px; font-weight: 800; color: var(--vs-primary-900, #0B2545); margin: 0; }
        .match-summary-count { font-size: 13px; font-weight: 600; color: var(--vs-text-secondary, #486581); }
        .match-summary-right { display: flex; align-items: center; gap: 9px; }
        .match-summary-right label { font-size: 13px; font-weight: 600; color: var(--vs-text-secondary, #486581); }
        .match-sort {
            height: 40px; padding: 0 12px;
            background: #fff; color: var(--vs-text, #102A43);
            border: 1px solid var(--vs-border, #DCE5EF); border-radius: 10px;
            font-family: inherit; font-size: 13px; font-weight: 700; cursor: pointer;
        }
        .match-sort:focus {
            outline: none; border-color: var(--vs-primary-600, #1677D2);
            box-shadow: 0 0 0 3px var(--vs-focus-ring, rgba(24, 200, 232, .35));
        }

        /* ---- Chip lọc trạng thái (P13) ---------------------------------------- */
        .match-chip-row { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 16px; }
        .match-chip {
            display: inline-flex; align-items: center; gap: 6px;
            height: 38px; padding: 0 15px; border-radius: 999px;
            background: #fff; border: 1px solid var(--vs-border, #DCE5EF);
            color: var(--vs-text-secondary, #486581);
            font-family: inherit; font-size: 13px; font-weight: 700; cursor: pointer;
        }
        .match-chip:hover:not(.is-active) {
            border-color: var(--vs-primary-600, #1677D2);
            color: var(--vs-primary-600, #1677D2);
        }
        .match-chip.is-active {
            background: var(--vs-primary-600, #1677D2);
            border-color: var(--vs-primary-600, #1677D2);
            color: #fff;
        }

        /* ---- Lưới thẻ kèo (P11) ----------------------------------------------- */
        .match-grid {
            display: grid;
            grid-template-columns: minmax(0, 1fr);
            gap: 16px;
        }
        @media (min-width: 768px)  { .match-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
        @media (min-width: 1560px) { .match-grid { grid-template-columns: repeat(3, minmax(0, 1fr)); } }

        .match-item {
            background: var(--vs-card, #fff);
            border: 1px solid var(--vs-border, #DCE5EF);
            border-radius: 18px;
            padding: 18px;
            display: flex; flex-direction: column; gap: 12px;
            box-shadow: 0 1px 3px rgba(11, 37, 69, .05);
            transition: transform .16s ease, box-shadow .16s ease, border-color .16s ease;
        }
        @media (hover: hover) and (min-width: 1024px) {
            .match-item:hover {
                transform: translateY(-2px);
                border-color: var(--vs-cyan-500, #18C8E8);
                box-shadow: 0 8px 22px rgba(11, 37, 69, .10);
            }
        }
        .match-item-top { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .match-item-title {
            font-size: 16px; font-weight: 800; margin: 0;
            color: var(--vs-primary-900, #0B2545); line-height: 1.35;
        }
        .match-item-addr { font-size: 13px; color: var(--vs-text-secondary, #486581); margin: 2px 0 0; }
        .match-item-meta {
            display: flex; flex-wrap: wrap; gap: 7px 16px;
            font-size: 13.5px; font-weight: 600; color: var(--vs-text-secondary, #486581);
        }
        .match-item-meta span { display: inline-flex; align-items: center; gap: 5px; }
        .match-item-meta svg { color: var(--vs-muted, #829AB1); flex-shrink: 0; }
        .match-item-note {
            margin: 0; font-size: 13px; line-height: 1.5;
            color: var(--vs-text-secondary, #486581);
            background: var(--vs-surface-soft, #EDF4FA);
            border-radius: 10px; padding: 9px 12px;
        }
        .match-badge {
            display: inline-flex; align-items: center; gap: 5px;
            padding: 4px 11px; border-radius: 999px;
            font-size: 11.5px; font-weight: 800; white-space: nowrap;
        }
        .match-badge.is-sport  { background: var(--vs-cyan-100, #DDF8FC); color: var(--vs-primary-700, #185A9D); }
        .match-badge.is-open   { background: var(--vs-cyan-50, #F0FCFE); color: var(--vs-primary-600, #1677D2); border: 1px solid var(--vs-cyan-100, #DDF8FC); }
        .match-badge.is-full   { background: var(--vs-warning-bg, #FFF7DA); color: #8a6116; }
        .match-badge.is-cancel { background: var(--vs-danger-bg, #FDEBEC); color: var(--vs-danger, #E5484D); }
        .match-badge.is-closed { background: #EEF2F6; color: var(--vs-text-secondary, #486581); }
        .match-badge.is-joined { background: var(--vs-primary-600, #1677D2); color: #fff; }
        .match-badge.is-rep-good  { background: var(--vs-success-bg, #E5F7EF); color: var(--vs-success, #16A36A); }
        .match-badge.is-rep-watch { background: var(--vs-warning-bg, #FFF7DA); color: #8a6116; }
        .match-badge.is-rep-bad   { background: var(--vs-danger-bg, #FDEBEC); color: var(--vs-danger, #E5484D); }
        .match-badge-spacer { margin-left: auto; }

        .match-slots { display: flex; flex-direction: column; gap: 6px; }
        .match-slot-bar { height: 8px; border-radius: 999px; background: #EEF2F6; overflow: hidden; }
        .match-slot-fill {
            height: 100%; border-radius: 999px;
            background: linear-gradient(90deg, var(--vs-primary-600, #1677D2), var(--vs-cyan-500, #18C8E8));
        }
        .match-slot-text {
            display: flex; justify-content: space-between; gap: 10px;
            font-size: 12.5px; font-weight: 700; color: var(--vs-text-secondary, #486581);
        }

        .match-item-actions {
            display: flex; gap: 9px; flex-wrap: wrap;
            margin-top: auto; padding-top: 13px;
            border-top: 1px solid var(--vs-border, #DCE5EF);
        }
        .match-action {
            display: inline-flex; align-items: center; justify-content: center; gap: 6px;
            min-height: 42px; padding: 0 16px; border-radius: 11px;
            border: 1px solid transparent;
            font-family: inherit; font-size: 13.5px; font-weight: 700;
            cursor: pointer; white-space: nowrap; text-decoration: none;
        }
        .match-action.is-primary { background: var(--vs-orange-500, #FF8A24); color: #fff; }
        .match-action.is-primary:hover:not(:disabled) { background: var(--vs-orange-600, #F97316); }
        .match-action.is-blue { background: var(--vs-primary-600, #1677D2); color: #fff; }
        .match-action.is-blue:hover:not(:disabled) { background: var(--vs-primary-700, #185A9D); }
        .match-action.is-ghost {
            background: #fff; color: var(--vs-text, #102A43);
            border-color: var(--vs-border, #DCE5EF);
        }
        .match-action.is-ghost:hover:not(:disabled) {
            border-color: var(--vs-primary-600, #1677D2);
            color: var(--vs-primary-600, #1677D2);
        }
        .match-action.is-danger {
            background: #fff; color: var(--vs-danger, #E5484D);
            border-color: var(--vs-danger, #E5484D);
        }
        .match-action.is-danger:hover:not(:disabled) { background: var(--vs-danger-bg, #FDEBEC); }
        .match-action.is-block { flex: 1 1 auto; }
        .match-action:disabled { opacity: .5; cursor: not-allowed; }

        /* ---- Empty state (P10) ------------------------------------------------ */
        .match-empty-state {
            width: min(700px, 100%);
            margin: 26px auto;
            padding: 40px 32px;
            text-align: center;
            background: var(--vs-card, #fff);
            border: 1px solid var(--vs-cyan-100, #DDF8FC);
            border-radius: 22px;
            box-shadow: 0 6px 24px rgba(11, 37, 69, .07);
        }
        .match-empty-icon {
            width: 104px; height: 104px; margin: 0 auto 20px;
            border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            background: linear-gradient(135deg, var(--vs-primary-600, #1677D2) 0%, var(--vs-cyan-500, #18C8E8) 100%);
            color: #fff;
            box-shadow: 0 10px 26px rgba(22, 119, 210, .26);
        }
        .match-empty-title {
            font-size: 20px; font-weight: 800; margin: 0 0 9px;
            color: var(--vs-primary-900, #0B2545);
        }
        .match-empty-text {
            font-size: 14px; line-height: 1.6; margin: 0 auto 22px;
            max-width: 460px; color: var(--vs-text-secondary, #486581);
        }
        .match-empty-actions {
            display: flex; gap: 11px; justify-content: center; flex-wrap: wrap;
            margin-bottom: 26px;
        }
        .match-empty-hints {
            display: flex; flex-wrap: wrap; justify-content: center; gap: 10px 22px;
            padding-top: 20px;
            border-top: 1px dashed var(--vs-border, #DCE5EF);
        }
        .match-empty-hints span {
            display: inline-flex; align-items: center; gap: 7px;
            font-size: 12.5px; font-weight: 600; color: var(--vs-text-secondary, #486581);
        }
        .match-empty-hints svg { color: var(--vs-cyan-600, #08A9CC); flex-shrink: 0; }

        /* Empty state phụ (nhỏ hơn) cho "Kèo của tôi" */
        .match-empty-mini {
            padding: 34px 20px; text-align: center;
            color: var(--vs-text-secondary, #486581); font-size: 14px;
            background: var(--vs-card, #fff);
            border: 1px dashed var(--vs-border, #DCE5EF);
            border-radius: 16px;
        }

        /* ---- Loading / error (P14) -------------------------------------------- */
        .match-skeleton-grid {
            display: grid; gap: 16px;
            grid-template-columns: minmax(0, 1fr);
        }
        @media (min-width: 768px)  { .match-skeleton-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
        @media (min-width: 1560px) { .match-skeleton-grid { grid-template-columns: repeat(3, minmax(0, 1fr)); } }
        .match-skeleton {
            height: 208px; border-radius: 18px;
            border: 1px solid var(--vs-border, #DCE5EF);
            background: linear-gradient(90deg, #F1F5F9 25%, #E2EAF2 37%, #F1F5F9 63%);
            background-size: 400% 100%;
            animation: matchShimmer 1.5s ease infinite;
        }
        @keyframes matchShimmer {
            0%   { background-position: 100% 50%; }
            100% { background-position: 0 50%; }
        }
        .match-error {
            padding: 34px 22px; text-align: center;
            background: var(--vs-danger-bg, #FDEBEC);
            border: 1px solid var(--vs-danger, #E5484D);
            border-radius: 16px;
        }
        .match-error p {
            margin: 0 0 14px; font-size: 14px; font-weight: 600;
            color: var(--vs-danger, #E5484D);
        }

        /* ---- Form tạo kèo (P12) ----------------------------------------------- */
        .match-create-layout {
            display: grid;
            grid-template-columns: minmax(0, 1fr);
            gap: 18px;
            align-items: start;
        }
        @media (min-width: 1100px) {
            /* Cột chính giới hạn 900px để form không bị quá rộng, phần dư dồn cho khoảng trắng. */
            .match-create-layout {
                grid-template-columns: minmax(0, 900px) 340px;
                justify-content: center;
            }
        }
        .match-create-main { padding: 22px; }
        .match-section { padding-bottom: 20px; margin-bottom: 20px; border-bottom: 1px solid var(--vs-border, #DCE5EF); }
        .match-section:last-of-type { border-bottom: none; margin-bottom: 0; padding-bottom: 0; }
        .match-section-head { display: flex; align-items: center; gap: 11px; margin-bottom: 16px; }
        .match-section-num {
            width: 30px; height: 30px; flex-shrink: 0; border-radius: 9px;
            display: inline-flex; align-items: center; justify-content: center;
            background: var(--vs-cyan-100, #DDF8FC); color: var(--vs-primary-700, #185A9D);
            font-size: 13px; font-weight: 800;
        }
        .match-section-title { font-size: 16px; font-weight: 800; color: var(--vs-primary-900, #0B2545); margin: 0; }
        .match-form-grid {
            display: grid; gap: 16px;
            grid-template-columns: minmax(0, 1fr);
        }
        @media (min-width: 700px) { .match-form-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
        .match-form-grid .is-wide { grid-column: 1 / -1; }
        .match-textarea {
            width: 100%; min-height: 104px; padding: 11px 13px; resize: vertical;
            background: #fff; color: var(--vs-text, #102A43);
            border: 1px solid var(--vs-border, #DCE5EF); border-radius: 11px;
            font-family: inherit; font-size: 14px; line-height: 1.55;
        }
        .match-textarea:focus {
            outline: none; border-color: var(--vs-primary-600, #1677D2);
            box-shadow: 0 0 0 3px var(--vs-focus-ring, rgba(24, 200, 232, .35));
        }
        .match-help { font-size: 12.5px; color: var(--vs-text-secondary, #486581); margin: 6px 0 0; }
        .match-invalid { border-color: var(--vs-danger, #E5484D) !important; }
        .match-error-text {
            display: none; margin: 6px 0 0;
            font-size: 12.5px; font-weight: 700; color: var(--vs-danger, #E5484D);
        }
        .match-error-text.is-shown { display: block; }
        .match-required { color: var(--vs-danger, #E5484D); }
        .match-radio-row { display: flex; gap: 11px; flex-wrap: wrap; }
        .match-radio {
            display: inline-flex; align-items: center; gap: 9px;
            padding: 12px 16px; min-height: 46px;
            background: #fff; border: 1px solid var(--vs-border, #DCE5EF); border-radius: 11px;
            font-size: 14px; font-weight: 700; color: var(--vs-text-secondary, #486581);
            cursor: pointer; transition: border-color .12s ease, background-color .12s ease, color .12s ease;
        }
        .match-radio input { accent-color: var(--vs-primary-600, #1677D2); }
        .match-radio.is-selected {
            border-color: var(--vs-primary-600, #1677D2);
            background: var(--vs-cyan-50, #F0FCFE);
            color: var(--vs-primary-700, #185A9D);
        }
        .match-submit-row {
            display: flex; gap: 11px; justify-content: flex-end; flex-wrap: wrap;
            padding-top: 20px; border-top: 1px solid var(--vs-border, #DCE5EF); margin-top: 20px;
        }
        .match-aside { display: flex; flex-direction: column; gap: 16px; }
        @media (min-width: 1100px) { .match-aside { position: sticky; top: 84px; } }
        .match-aside-card { padding: 18px; }
        .match-aside-title { font-size: 14px; font-weight: 800; color: var(--vs-primary-900, #0B2545); margin: 0 0 12px; }
        .match-preview-empty {
            text-align: center; padding: 26px 8px;
            font-size: 13px; color: var(--vs-text-secondary, #486581);
        }
        .match-steps { display: grid; gap: 11px; }
        .match-step { display: flex; gap: 10px; font-size: 13px; line-height: 1.5; color: var(--vs-text-secondary, #486581); }
        .match-step b { color: var(--vs-primary-600, #1677D2); flex-shrink: 0; }

        /* ---- Panels ----------------------------------------------------------- */
        .match-panel { display: none; }
        .match-panel.is-active { display: block; }
        .match-subhead {
            font-size: 15px; font-weight: 800; color: var(--vs-primary-900, #0B2545);
            margin: 0 0 13px;
        }
        .match-subhead-spaced { margin-top: 30px; }

        /* ---- Toast (P14) ------------------------------------------------------ */
        .match-toast {
            position: fixed; left: 50%; z-index: 1400;
            bottom: calc(100px + env(safe-area-inset-bottom, 0px));
            transform: translateX(-50%) translateY(16px);
            max-width: 92vw; padding: 13px 20px; border-radius: 999px;
            background: var(--vs-primary-900, #0B2545); color: #fff;
            font-size: 14px; font-weight: 700; text-align: center;
            box-shadow: 0 12px 32px rgba(11, 37, 69, .32);
            opacity: 0; visibility: hidden;
            transition: opacity .2s ease, transform .2s ease;
        }
        .match-toast.is-open { opacity: 1; visibility: visible; transform: translateX(-50%) translateY(0); }
        .match-toast.is-success { background: var(--vs-success, #16A36A); }
        .match-toast.is-danger  { background: var(--vs-danger, #E5484D); }

        /* ---- Sheet chi tiết ---------------------------------------------------- */
        .match-overlay {
            position: fixed; inset: 0; z-index: 1200;
            background: var(--vs-overlay, rgba(7, 26, 47, .68));
            opacity: 0; visibility: hidden; transition: opacity .2s ease;
        }
        .match-overlay.is-open { opacity: 1; visibility: visible; }
        .match-sheet {
            position: fixed; left: 0; right: 0; bottom: 0; z-index: 1210;
            display: flex; flex-direction: column;
            max-height: 90dvh;
            background: #fff; border-radius: 22px 22px 0 0;
            box-shadow: 0 -20px 60px rgba(11, 37, 69, .32);
            transform: translateY(100%);
            transition: transform .28s cubic-bezier(.22, 1, .36, 1);
        }
        .match-sheet.is-open { transform: translateY(0); }
        .match-sheet-handle { padding: 9px 0; display: flex; justify-content: center; }
        .match-sheet-handle span { width: 44px; height: 5px; border-radius: 999px; background: #CBD5E1; }
        .match-sheet-head {
            display: flex; align-items: center; justify-content: space-between; gap: 12px;
            padding: 4px 20px 14px; border-bottom: 1px solid var(--vs-border, #DCE5EF);
        }
        .match-sheet-title { margin: 0; font-size: 17px; font-weight: 800; color: var(--vs-primary-900, #0B2545); }
        .match-sheet-close {
            width: 38px; height: 38px; flex-shrink: 0; border-radius: 50%;
            display: inline-flex; align-items: center; justify-content: center;
            background: #fff; border: 1px solid var(--vs-border, #DCE5EF);
            color: var(--vs-text, #102A43); cursor: pointer;
        }
        .match-sheet-close:hover { border-color: var(--vs-primary-600, #1677D2); color: var(--vs-primary-600, #1677D2); }
        .match-sheet-body { flex: 1; overflow-y: auto; padding: 20px; }
        .match-sheet-bar {
            display: flex; gap: 10px; flex-wrap: wrap;
            padding: 14px 20px calc(14px + env(safe-area-inset-bottom, 0px));
            border-top: 1px solid var(--vs-border, #DCE5EF);
        }
        @media (min-width: 768px) {
            .match-sheet {
                left: 50%; right: auto; bottom: 40px;
                max-width: 660px; width: calc(100% - 40px);
                border-radius: 22px; transform: translate(-50%, calc(100% + 60px));
            }
            .match-sheet.is-open { transform: translate(-50%, 0); }
        }
        .match-detail-block {
            display: grid; gap: 7px; padding: 14px;
            background: var(--vs-surface-soft, #EDF4FA); border-radius: 12px;
            font-size: 14px; color: var(--vs-text, #102A43); line-height: 1.5;
        }
        .match-person {
            display: flex; align-items: center; gap: 11px;
            padding: 11px 0; border-bottom: 1px solid #EEF2F6;
        }
        .match-person:last-child { border-bottom: none; }
        .match-avatar {
            width: 38px; height: 38px; flex-shrink: 0; border-radius: 999px;
            display: inline-flex; align-items: center; justify-content: center;
            background: var(--vs-cyan-100, #DDF8FC); color: var(--vs-primary-700, #185A9D);
            font-size: 13px; font-weight: 800;
        }
        .match-person-name { font-size: 14px; font-weight: 700; color: var(--vs-text, #102A43); }
        .match-person-sub { font-size: 12.5px; color: var(--vs-text-secondary, #486581); margin-top: 1px; }
        .match-person-actions { margin-left: auto; display: flex; gap: 7px; flex-shrink: 0; }
        .match-mini {
            padding: 7px 12px; border-radius: 9px; min-height: 34px;
            background: #fff; border: 1px solid var(--vs-border, #DCE5EF);
            font-family: inherit; font-size: 12.5px; font-weight: 700; cursor: pointer;
            transition: background-color .12s ease, border-color .12s ease;
        }
        .match-mini.is-approve { border-color: var(--vs-success, #16A36A); color: var(--vs-success, #16A36A); }
        .match-mini.is-approve:hover { background: var(--vs-success-bg, #E5F7EF); }
        .match-mini.is-reject { border-color: var(--vs-danger, #E5484D); color: var(--vs-danger, #E5484D); }
        .match-mini.is-reject:hover { background: var(--vs-danger-bg, #FDEBEC); }

        /* ---- Hộp xác nhận (thay confirm() của trình duyệt, P14) ---------------- */
        .match-confirm {
            position: fixed; left: 50%; top: 50%; z-index: 1310;
            transform: translate(-50%, -46%);
            width: min(420px, calc(100% - 40px)); padding: 26px;
            background: #fff; border-radius: 20px; text-align: center;
            box-shadow: 0 24px 60px rgba(11, 37, 69, .34);
            opacity: 0; visibility: hidden;
            transition: opacity .18s ease, transform .18s ease;
        }
        .match-confirm.is-open { opacity: 1; visibility: visible; transform: translate(-50%, -50%); }
        .match-confirm-icon {
            width: 56px; height: 56px; margin: 0 auto 15px; border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            background: var(--vs-danger-bg, #FDEBEC); color: var(--vs-danger, #E5484D);
        }
        .match-confirm-title { font-size: 17px; font-weight: 800; margin: 0 0 8px; color: var(--vs-primary-900, #0B2545); }
        .match-confirm-text { font-size: 14px; line-height: 1.55; margin: 0 0 22px; color: var(--vs-text-secondary, #486581); }
        .match-confirm-actions { display: flex; gap: 10px; }
        .match-confirm-actions .match-action { flex: 1; }

        /* ---- Responsive (P15) -------------------------------------------------- */
        @media (max-width: 1099px) {
            .match-filter-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .match-filter-grid .match-filter-button { grid-column: span 1; }
        }
        @media (max-width: 767px) {
            .match-hero-inner { min-height: 96px; padding: 16px 0; gap: 12px; }
            .match-hero-icon { display: none; }
            .match-hero-title { font-size: 20px; }
            .match-hero-sub { font-size: 13px; }
            .match-hero-mine { padding: 10px 13px; font-size: 13px; }
            .match-hero-mine .match-hero-mine-label { display: none; }
            .match-container { width: calc(100% - 32px); padding: 18px 0 130px; }
            .match-hero-inner { width: calc(100% - 32px); }
            .match-tabs { height: 54px; }
            .match-tab { font-size: 13px; gap: 5px; padding: 0 4px; }
            .match-tab svg { display: none; }
            .match-filters { padding: 16px; }
            .match-filter-grid { grid-template-columns: minmax(0, 1fr); }
            .match-empty-state { padding: 32px 20px; }
            .match-empty-actions .match-action { width: 100%; }
            .match-item-actions .match-action { flex: 1 1 100%; }
            .match-submit-row .match-action { flex: 1 1 100%; }
        }

        /* ---- Giảm chuyển động (P19/P16) ---------------------------------------- */
        @media (prefers-reduced-motion: reduce) {
            .vs-matchmaking-page *,
            .vs-matchmaking-page *::before,
            .vs-matchmaking-page *::after {
                animation-duration: .001ms !important;
                animation-iteration-count: 1 !important;
                transition-duration: .001ms !important;
                scroll-behavior: auto !important;
            }
            .vs-matchmaking-page :is(.match-tab, .match-action, .match-filter-button, .match-chip, .match-item):active,
            .vs-matchmaking-page .match-item:hover {
                transform: none;
            }
            .match-skeleton { animation: none; background: #EEF2F6; }
        }
    </style>
</head>
<body class="vs-matchmaking-page">

<jsp:include page="/customer/common/vsport-header.jsp" />

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%-- ============================ HERO (P5) ============================ --%>
<div class="match-hero">
    <div class="match-hero-inner">
        <button type="button" class="match-hero-back" onclick="gkGoBack()" aria-label="Quay lại trang trước">
            <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
        </button>
        <span class="match-hero-icon" aria-hidden="true">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        </span>
        <div class="match-hero-text">
            <h1 class="match-hero-title">Ghép trận</h1>
            <p class="match-hero-sub">Tìm người chơi hoặc tạo trận phù hợp với lịch của bạn.</p>
        </div>
        <button type="button" class="match-hero-mine" onclick="gkOpenTab('cua-toi')" aria-label="Xem kèo của tôi">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/></svg>
            <span class="match-hero-mine-label">Kèo của tôi</span>
            <span class="match-hero-badge" id="gkMineBadge" hidden>0</span>
        </button>
    </div>
</div>

<main class="match-container">

    <%-- Toast từ session (giữ tương thích session message/error) --%>
    <c:if test="${not empty sessionScope.message}">
        <script>window.addEventListener('DOMContentLoaded', function () { gkToast('${fn:escapeXml(sessionScope.message)}', 'success'); });</script>
        <% session.removeAttribute("message"); %>
    </c:if>
    <c:if test="${not empty sessionScope.error}">
        <script>window.addEventListener('DOMContentLoaded', function () { gkToast('${fn:escapeXml(sessionScope.error)}', 'danger'); });</script>
        <% session.removeAttribute("error"); %>
    </c:if>

    <%-- Thẻ cơ sở: chỉ hiện khi tới từ modal "Chọn hình thức đặt" --%>
    <c:if test="${not empty coSoIdParam}">
        <c:forEach var="cs" items="${dsCoSo}">
            <c:if test="${cs.coSoID == coSoIdParam}">
                <div class="match-card-surface match-facility">
                    <div class="match-facility-icon" aria-hidden="true">${fn:substring(cs.tenCoSo, 0, 1)}</div>
                    <div style="min-width:0; flex:1;">
                        <div class="match-facility-name">${fn:escapeXml(cs.tenCoSo)}</div>
                        <c:if test="${not empty cs.diaChi}">
                            <div class="match-facility-addr">${fn:escapeXml(cs.diaChi)}</div>
                        </c:if>
                    </div>
                    <a href="${ctx}/customer/dat-lich-truc-quan?coSoId=${cs.coSoID}" class="match-action is-ghost">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/></svg>
                        Đặt sân
                    </a>
                </div>
            </c:if>
        </c:forEach>
    </c:if>

    <%-- ============================ TABS (P7) ============================ --%>
    <div class="match-tabs" role="tablist" aria-label="Chế độ ghép trận">
        <button type="button" class="match-tab" role="tab" data-tab="kham-pha"
                id="gkTabKhamPha" aria-controls="gkPanelKhamPha" aria-selected="false"
                onclick="gkOpenTab('kham-pha')">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <span class="match-tab-label">Tìm người chơi</span>
        </button>
        <button type="button" class="match-tab" role="tab" data-tab="tao-keo"
                id="gkTabTaoKeo" aria-controls="gkPanelTaoKeo" aria-selected="false"
                onclick="gkOpenTab('tao-keo')">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M8 12h8"/><path d="M12 8v8"/></svg>
            <span class="match-tab-label">Tạo kèo mới</span>
        </button>
        <button type="button" class="match-tab" role="tab" data-tab="cua-toi"
                id="gkTabCuaToi" aria-controls="gkPanelCuaToi" aria-selected="false"
                onclick="gkOpenTab('cua-toi')">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/></svg>
            <span class="match-tab-label">Kèo của tôi</span>
        </button>
    </div>

    <%-- ==================== PANEL: Tìm người chơi ==================== --%>
    <div class="match-panel" id="gkPanelKhamPha" role="tabpanel" aria-labelledby="gkTabKhamPha">

        <%-- Bộ lọc (P8) --%>
        <section class="match-card-surface match-filters" aria-label="Bộ lọc kèo">
            <div class="match-filter-grid">
                <div class="match-field">
                    <label class="match-field-label" for="gkFilterCoSo">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/></svg>
                        Cơ sở
                    </label>
                    <select id="gkFilterCoSo" class="match-input">
                        <option value="">Tất cả cơ sở</option>
                        <c:forEach var="cs" items="${dsCoSo}">
                            <option value="${cs.coSoID}" ${cs.coSoID == coSoIdParam ? 'selected' : ''}>${fn:escapeXml(cs.tenCoSo)}</option>
                        </c:forEach>
                    </select>
                </div>
                <div class="match-field">
                    <label class="match-field-label" for="gkFilterSport">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/></svg>
                        Môn thể thao
                    </label>
                    <select id="gkFilterSport" class="match-input">
                        <option value="">Tất cả môn</option>
                        <c:forEach var="m" items="${dsMon}">
                            <option value="${m.monTheThaoID}">${fn:escapeXml(m.tenMon)}</option>
                        </c:forEach>
                    </select>
                </div>
                <div class="match-field">
                    <label class="match-field-label" for="gkFilterFrom">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/></svg>
                        Từ ngày
                    </label>
                    <input type="date" lang="vi" id="gkFilterFrom" class="match-input" aria-label="Lọc từ ngày" />
                </div>
                <div class="match-field">
                    <label class="match-field-label" for="gkFilterTo">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="m9 16 2 2 4-4"/></svg>
                        Đến ngày
                    </label>
                    <input type="date" lang="vi" id="gkFilterTo" class="match-input" aria-label="Lọc đến ngày" />
                </div>
                <button type="button" class="match-filter-button is-search" onclick="gkLoadDiscover()">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
                    Tìm kèo
                </button>
                <button type="button" class="match-filter-button is-clear" onclick="gkClearFilters()">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
                    Xóa lọc
                </button>
            </div>
        </section>

        <%-- Dải tóm tắt + sắp xếp (P9) --%>
        <div class="match-summary" id="gkSummaryStrip" hidden>
            <div class="match-summary-left">
                <h2 class="match-summary-title">Kèo đang mở</h2>
                <span class="match-summary-count" id="gkResultCount">0 kèo</span>
            </div>
            <div class="match-summary-right">
                <label for="gkSortSelect">Sắp xếp</label>
                <select id="gkSortSelect" class="match-sort" onchange="gkRenderDiscover()">
                    <option value="soonest">Sắp diễn ra</option>
                    <option value="newest">Mới nhất</option>
                    <option value="slots">Còn nhiều chỗ</option>
                </select>
            </div>
        </div>

        <%-- Trạng thái: loading --%>
        <div id="gkDiscoverLoading" class="match-skeleton-grid" aria-live="polite" aria-busy="true">
            <div class="match-skeleton"></div>
            <div class="match-skeleton"></div>
            <div class="match-skeleton"></div>
            <div class="match-skeleton"></div>
        </div>

        <%-- Trạng thái: lỗi --%>
        <div id="gkDiscoverError" class="match-error" role="alert" hidden>
            <p>Không thể tải danh sách kèo. Vui lòng kiểm tra kết nối và thử lại.</p>
            <button type="button" class="match-action is-blue" onclick="gkLoadDiscover()">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/></svg>
                Thử lại
            </button>
        </div>

        <%-- Trạng thái: rỗng (P10) --%>
        <div id="gkDiscoverEmpty" class="match-empty-state" hidden>
            <div class="match-empty-icon" aria-hidden="true">
                <svg width="50" height="50" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
            </div>
            <h2 class="match-empty-title">Chưa tìm thấy kèo phù hợp</h2>
            <p class="match-empty-text">Thử điều chỉnh cơ sở, môn thể thao hoặc khoảng ngày. Bạn cũng có thể chủ động tạo một kèo mới.</p>
            <div class="match-empty-actions">
                <button type="button" class="match-action is-primary" onclick="gkOpenTab('tao-keo')">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 5v14"/><path d="M5 12h14"/></svg>
                    Tạo kèo mới
                </button>
                <button type="button" class="match-action is-ghost" onclick="gkClearFilters()">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
                    Xóa bộ lọc
                </button>
            </div>
            <div class="match-empty-hints">
                <span>
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/></svg>
                    Chọn cơ sở gần bạn
                </span>
                <span>
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/></svg>
                    Mở rộng khoảng ngày
                </span>
                <span>
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M8 12h8"/><path d="M12 8v8"/></svg>
                    Tạo kèo để người khác tham gia
                </span>
            </div>
        </div>

        <%-- Trạng thái: có dữ liệu (P11) --%>
        <div id="gkDiscoverList" class="match-grid"></div>
    </div>

    <%-- ==================== PANEL: Tạo kèo mới (P12) ==================== --%>
    <div class="match-panel" id="gkPanelTaoKeo" role="tabpanel" aria-labelledby="gkTabTaoKeo">

        <div id="gkBookingsLoading" class="match-skeleton-grid" aria-busy="true">
            <div class="match-skeleton" style="height:150px;"></div>
            <div class="match-skeleton" style="height:150px;"></div>
        </div>

        <div id="gkNoBookings" class="match-empty-state" hidden>
            <div class="match-empty-icon" aria-hidden="true">
                <svg width="50" height="50" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="M12 14v4"/><path d="M10 16h4"/></svg>
            </div>
            <h2 class="match-empty-title">Bạn chưa có ca đặt sân nào</h2>
            <p class="match-empty-text">Kèo luôn gắn với một ca đặt sân sắp diễn ra do chính bạn đặt. Hãy đặt sân trước, sau đó quay lại đây để mở kèo tìm người chơi.</p>
            <div class="match-empty-actions">
                <a href="${ctx}/customer/dat-lich-truc-quan${not empty coSoIdParam ? '?coSoId='.concat(coSoIdParam) : ''}" class="match-action is-primary">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/></svg>
                    Đặt sân ngay
                </a>
                <button type="button" class="match-action is-ghost" onclick="gkOpenTab('kham-pha')">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
                    Tìm kèo có sẵn
                </button>
            </div>
        </div>

        <div class="match-create-layout" id="gkCreateLayout" hidden>
            <form id="gkCreateForm" class="match-card-surface match-create-main" novalidate onsubmit="return gkSubmitCreate(event)">

                <section class="match-section">
                    <div class="match-section-head">
                        <span class="match-section-num" aria-hidden="true">1</span>
                        <h2 class="match-section-title">Thông tin lịch chơi</h2>
                    </div>
                    <div class="match-form-grid">
                        <div class="is-wide">
                            <label class="match-field-label" for="gkBookingSelect">
                                Chọn ca đặt sân của bạn <span class="match-required">*</span>
                            </label>
                            <select id="gkBookingSelect" class="match-input" required
                                    aria-describedby="gkBookingHelp" onchange="gkOnBookingChange()"></select>
                            <p class="match-error-text" id="gkBookingError">Vui lòng chọn một ca đặt sân.</p>
                            <p class="match-help" id="gkBookingHelp">Sân, giờ và môn thể thao được lấy tự động từ ca đặt bạn chọn.</p>
                        </div>
                    </div>
                </section>

                <section class="match-section">
                    <div class="match-section-head">
                        <span class="match-section-num" aria-hidden="true">2</span>
                        <h2 class="match-section-title">Yêu cầu người tham gia</h2>
                    </div>
                    <div class="match-form-grid">
                        <div>
                            <label class="match-field-label" for="gkSoNguoi">
                                Số người cần tìm thêm <span class="match-required">*</span>
                            </label>
                            <input type="number" id="gkSoNguoi" class="match-input" min="1" max="20" value="3" required
                                   aria-describedby="gkSoNguoiHelp" />
                            <p class="match-error-text" id="gkSoNguoiError">Số người cần tìm phải trong khoảng 1–20.</p>
                            <p class="match-help" id="gkSoNguoiHelp">Không tính bạn (chủ kèo).</p>
                        </div>
                        <div>
                            <label class="match-field-label" for="gkTrinhDo">Trình độ mong muốn</label>
                            <select id="gkTrinhDo" class="match-input">
                                <option>Không yêu cầu</option>
                                <option>Mới chơi</option>
                                <option>Cơ bản</option>
                                <option>Trung bình</option>
                                <option>Khá</option>
                                <option>Nâng cao</option>
                            </select>
                            <p class="match-help">Chỉ mang tính gợi ý cho người xem kèo.</p>
                        </div>
                        <div class="is-wide">
                            <span class="match-field-label" id="gkApproveLabel">Hình thức duyệt</span>
                            <div class="match-radio-row" role="radiogroup" aria-labelledby="gkApproveLabel">
                                <label class="match-radio is-selected">
                                    <input type="radio" name="approve" value="auto" checked /> Tự động chấp nhận
                                </label>
                                <label class="match-radio">
                                    <input type="radio" name="approve" value="manual" /> Chủ kèo duyệt từng người
                                </label>
                            </div>
                        </div>
                    </div>
                </section>

                <section class="match-section">
                    <div class="match-section-head">
                        <span class="match-section-num" aria-hidden="true">3</span>
                        <h2 class="match-section-title">Mô tả và ghi chú</h2>
                    </div>
                    <div class="match-form-grid">
                        <div class="is-wide">
                            <label class="match-field-label" for="gkNote">Ghi chú ngắn</label>
                            <textarea id="gkNote" class="match-textarea" maxlength="240"
                                      placeholder="Ví dụ: mang theo bóng, chơi vui vẻ, giao lưu là chính..."></textarea>
                            <p class="match-help"><span id="gkNoteCount">0</span>/240 ký tự</p>
                        </div>
                    </div>
                </section>

                <section class="match-section">
                    <div class="match-section-head">
                        <span class="match-section-num" aria-hidden="true">4</span>
                        <h2 class="match-section-title">Xác nhận</h2>
                    </div>
                    <p class="match-help" style="margin-top:0;">
                        Sau khi đăng, kèo sẽ xuất hiện ở tab “Tìm người chơi” để người khác xin tham gia.
                        Bạn có thể dừng nhận người hoặc hủy kèo bất cứ lúc nào trong “Kèo của tôi”.
                    </p>
                    <div class="match-submit-row">
                        <button type="button" class="match-action is-ghost" onclick="gkOpenTab('kham-pha')">Hủy</button>
                        <button type="submit" class="match-action is-primary" id="gkCreateSubmit">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 5v14"/><path d="M5 12h14"/></svg>
                            <span id="gkCreateSubmitLabel">Xác nhận tạo kèo</span>
                        </button>
                    </div>
                </section>
            </form>

            <aside class="match-aside">
                <div class="match-card-surface match-aside-card">
                    <h2 class="match-aside-title">Xem trước thẻ kèo</h2>
                    <div id="gkPreviewBox">
                        <div class="match-preview-empty">Chọn ca đặt sân để xem trước thẻ kèo.</div>
                    </div>
                </div>
                <div class="match-card-surface match-aside-card">
                    <h2 class="match-aside-title">Kèo hoạt động thế nào?</h2>
                    <div class="match-steps">
                        <div class="match-step"><b>1.</b><span>Bạn đặt sân trước qua trang “Đặt lịch trực quan”.</span></div>
                        <div class="match-step"><b>2.</b><span>Quay lại đây, chọn ca đặt của bạn và điền số người cần tìm.</span></div>
                        <div class="match-step"><b>3.</b><span>Kèo hiển thị ở tab “Tìm người chơi” cho người khác thấy.</span></div>
                        <div class="match-step"><b>4.</b><span>Nếu chọn “Chủ kèo duyệt”, yêu cầu tham gia sẽ nằm trong “Kèo của tôi”.</span></div>
                    </div>
                </div>
            </aside>
        </div>
    </div>

    <%-- ==================== PANEL: Kèo của tôi (P13) ==================== --%>
    <div class="match-panel" id="gkPanelCuaToi" role="tabpanel" aria-labelledby="gkTabCuaToi">

        <div class="match-chip-row" role="group" aria-label="Lọc theo trạng thái">
            <button type="button" class="match-chip is-active" data-status="all"      onclick="gkFilterMine('all', this)">Tất cả</button>
            <button type="button" class="match-chip" data-status="open"     onclick="gkFilterMine('open', this)">Đang mở</button>
            <button type="button" class="match-chip" data-status="full"     onclick="gkFilterMine('full', this)">Đã đủ người</button>
            <button type="button" class="match-chip" data-status="upcoming" onclick="gkFilterMine('upcoming', this)">Sắp diễn ra</button>
            <button type="button" class="match-chip" data-status="ended"    onclick="gkFilterMine('ended', this)">Đã kết thúc</button>
            <button type="button" class="match-chip" data-status="cancel"   onclick="gkFilterMine('cancel', this)">Đã hủy</button>
        </div>

        <div id="gkMineLoading" class="match-skeleton-grid" aria-busy="true" hidden>
            <div class="match-skeleton"></div>
            <div class="match-skeleton"></div>
        </div>

        <div id="gkMineError" class="match-error" role="alert" hidden>
            <p>Không thể tải kèo của bạn. Vui lòng thử lại.</p>
            <button type="button" class="match-action is-blue" onclick="gkLoadMine()">Thử lại</button>
        </div>

        <div id="gkMineContent">
            <h2 class="match-subhead">Kèo bạn tạo</h2>
            <div id="gkMineCreatedList" class="match-grid"></div>
            <div id="gkMineCreatedEmpty" class="match-empty-mini" hidden>Không có kèo nào khớp bộ lọc này.</div>

            <h2 class="match-subhead match-subhead-spaced">Kèo bạn tham gia</h2>
            <div id="gkMineJoinedList" class="match-grid"></div>
            <div id="gkMineJoinedEmpty" class="match-empty-mini" hidden>Không có kèo nào khớp bộ lọc này.</div>
        </div>
    </div>

</main>

<%-- ==================== Sheet chi tiết kèo ==================== --%>
<div id="gkOverlay" class="match-overlay" onclick="gkCloseSheet()"></div>
<div id="gkSheet" class="match-sheet" role="dialog" aria-modal="true" aria-labelledby="gkSheetTitle">
    <div class="match-sheet-handle" aria-hidden="true"><span></span></div>
    <div class="match-sheet-head">
        <h2 id="gkSheetTitle" class="match-sheet-title">Chi tiết kèo</h2>
        <button type="button" class="match-sheet-close" onclick="gkCloseSheet()" aria-label="Đóng chi tiết kèo">
            <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>
    </div>
    <div class="match-sheet-body" id="gkSheetBody"></div>
    <div class="match-sheet-bar" id="gkSheetBar"></div>
</div>

<%-- ==================== Hộp xác nhận (thay confirm()) ==================== --%>
<div id="gkConfirmOverlay" class="match-overlay" onclick="gkCloseConfirm()"></div>
<div id="gkConfirm" class="match-confirm" role="alertdialog" aria-modal="true" aria-labelledby="gkConfirmTitle" aria-describedby="gkConfirmText">
    <div class="match-confirm-icon" aria-hidden="true">
        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>
    </div>
    <h2 class="match-confirm-title" id="gkConfirmTitle">Xác nhận</h2>
    <p class="match-confirm-text" id="gkConfirmText"></p>
    <div class="match-confirm-actions">
        <button type="button" class="match-action is-ghost" onclick="gkCloseConfirm()">Quay lại</button>
        <button type="button" class="match-action is-danger" id="gkConfirmOk">Đồng ý</button>
    </div>
</div>

<div class="match-toast" id="gkToast" role="status" aria-live="polite"></div>

<%-- ==================== Server data + Script ==================== --%>
<script id="gkServerData" type="application/json">
{
  "contextPath": "${ctx}",
  "initialTab": "${initialTab}",
  "preCoSoId": <c:choose><c:when test="${not empty coSoIdParam}">${coSoIdParam}</c:when><c:otherwise>null</c:otherwise></c:choose>,
  "preSanId":  <c:choose><c:when test="${not empty sanIdParam}">${sanIdParam}</c:when><c:otherwise>null</c:otherwise></c:choose>,
  "accountId": <c:choose><c:when test="${not empty sessionScope.user}">${sessionScope.user.accountId}</c:when><c:otherwise>null</c:otherwise></c:choose>
}
</script>
<script>
(function () {
    var server = JSON.parse(document.getElementById('gkServerData').textContent);
    var CTX = server.contextPath;
    var ME_ID = server.accountId;

    var STATUS_OPEN = 'Đang mở';
    var STATUS_FULL = 'Đã đủ người';
    var STATUS_CANCEL = 'Đã hủy';

    /* ------------------------------- Helpers ------------------------------- */
    function fmtVnd(n) {
        var v = parseFloat(n);
        if (isNaN(v) || v <= 0) return '';
        return new Intl.NumberFormat('vi-VN').format(Math.round(v)) + ' đ';
    }
    function fmtDateVi(iso) {
        if (!iso) return '';
        var d = new Date(iso + 'T00:00:00');
        if (isNaN(d.getTime())) return '';
        var days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
        return days[d.getDay()] + ' ' + String(d.getDate()).padStart(2, '0') + '/' + String(d.getMonth() + 1).padStart(2, '0');
    }
    function escapeHtml(s) {
        if (s == null) return '';
        return String(s).replace(/[&<>"']/g, function (c) {
            return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
        });
    }
    function initials(name) {
        if (!name) return '?';
        return name.trim().split(/\s+/).map(function (p) { return p[0]; }).slice(-2).join('').toUpperCase();
    }
    function reputationClass(score) {
        if (score == null) return 'is-closed';
        if (score >= 80) return 'is-rep-good';
        if (score >= 50) return 'is-rep-watch';
        return 'is-rep-bad';
    }
    function reputationLabel(score) {
        if (score == null) return 'Chưa có uy tín';
        if (score >= 80) return 'Uy tín tốt';
        if (score >= 50) return 'Cần theo dõi';
        return 'Rủi ro cao';
    }
    function statusClass(trangThai) {
        if (trangThai === STATUS_OPEN) return 'is-open';
        if (trangThai === STATUS_FULL) return 'is-full';
        if (trangThai === STATUS_CANCEL) return 'is-cancel';
        return 'is-closed';
    }
    function todayIso() {
        var d = new Date();
        return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
    }
    function isPast(m) { return !!m.ngayDat && m.ngayDat < todayIso(); }

    function icon(kind) {
        var open = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">';
        if (kind === 'pin')   return open + '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/></svg>';
        if (kind === 'clock') return open + '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>';
        if (kind === 'date')  return open + '<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/></svg>';
        if (kind === 'level') return open + '<path d="M3 3v18h18"/><path d="m7 15 3-3 4 4 6-6"/></svg>';
        if (kind === 'user')  return open + '<circle cx="12" cy="8" r="4"/><path d="M20 21a8 8 0 0 0-16 0"/></svg>';
        return '';
    }

    /* -------------------------------- Toast -------------------------------- */
    var toastTimer = null;
    window.gkToast = function (msg, kind) {
        var el = document.getElementById('gkToast');
        el.className = 'match-toast';
        if (kind === 'danger') el.classList.add('is-danger');
        if (kind === 'success') el.classList.add('is-success');
        el.textContent = msg;
        el.classList.add('is-open');
        clearTimeout(toastTimer);
        toastTimer = setTimeout(function () { el.classList.remove('is-open'); }, 3200);
    };

    /* ------------------- Hộp xác nhận (thay confirm()) --------------------- */
    var confirmHandler = null;
    function gkOpenConfirm(title, text, okLabel, onOk) {
        document.getElementById('gkConfirmTitle').textContent = title;
        document.getElementById('gkConfirmText').textContent = text;
        var ok = document.getElementById('gkConfirmOk');
        ok.textContent = okLabel;
        confirmHandler = onOk;
        document.getElementById('gkConfirmOverlay').classList.add('is-open');
        document.getElementById('gkConfirm').classList.add('is-open');
        ok.focus();
    }
    window.gkCloseConfirm = function () {
        document.getElementById('gkConfirmOverlay').classList.remove('is-open');
        document.getElementById('gkConfirm').classList.remove('is-open');
        confirmHandler = null;
    };
    document.getElementById('gkConfirmOk').addEventListener('click', function () {
        var fn = confirmHandler;
        window.gkCloseConfirm();
        if (fn) fn();
    });

    /* ----------------------------- Chuyển tab ------------------------------ */
    window.gkOpenTab = function (name) {
        document.querySelectorAll('.match-tab').forEach(function (b) {
            var on = b.dataset.tab === name;
            b.classList.toggle('is-active', on);
            b.setAttribute('aria-selected', on ? 'true' : 'false');
        });
        document.querySelectorAll('.match-panel').forEach(function (p) { p.classList.remove('is-active'); });
        var map = { 'kham-pha': 'gkPanelKhamPha', 'tao-keo': 'gkPanelTaoKeo', 'cua-toi': 'gkPanelCuaToi' };
        var el = document.getElementById(map[name] || 'gkPanelKhamPha');
        if (el) el.classList.add('is-active');

        var url = new URL(window.location.href);
        url.searchParams.set('tab', name);
        history.replaceState(null, '', url.toString());

        if (name === 'kham-pha') gkLoadDiscover();
        if (name === 'tao-keo')  gkLoadBookingsForCreate();
        if (name === 'cua-toi')  gkLoadMine();
    };

    window.gkGoBack = function () {
        if (history.length > 1) history.back();
        else window.location.href = CTX + '/index.jsp';
    };

    window.gkClearFilters = function () {
        document.getElementById('gkFilterCoSo').value = '';
        document.getElementById('gkFilterSport').value = '';
        document.getElementById('gkFilterFrom').value = '';
        document.getElementById('gkFilterTo').value = '';
        gkLoadDiscover();
    };

    /* -------------------- Tìm người chơi: tải danh sách -------------------- */
    var discoverData = [];

    window.gkLoadDiscover = function () {
        var coSo  = document.getElementById('gkFilterCoSo').value;
        var sport = document.getElementById('gkFilterSport').value;
        var from  = document.getElementById('gkFilterFrom').value;
        var to    = document.getElementById('gkFilterTo').value;

        var params = new URLSearchParams();
        if (coSo)  params.set('coSoId', coSo);
        if (sport) params.set('monTheThaoId', sport);
        if (from)  params.set('from', from);
        if (to)    params.set('to', to);

        document.getElementById('gkDiscoverLoading').hidden = false;
        document.getElementById('gkDiscoverError').hidden = true;
        document.getElementById('gkDiscoverEmpty').hidden = true;
        document.getElementById('gkSummaryStrip').hidden = true;
        document.getElementById('gkDiscoverList').innerHTML = '';

        fetch(CTX + '/customer/api/matches?' + params.toString(), { headers: { 'Accept': 'application/json' } })
            .then(function (r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); })
            .then(function (data) {
                document.getElementById('gkDiscoverLoading').hidden = true;
                if (!data.success) throw new Error('unavailable');
                discoverData = data.matches || [];
                gkRenderDiscover();
            })
            .catch(function (err) {
                console.error(err);
                document.getElementById('gkDiscoverLoading').hidden = true;
                document.getElementById('gkDiscoverError').hidden = false;
            });
    };

    window.gkRenderDiscover = function () {
        var box = document.getElementById('gkDiscoverList');
        var strip = document.getElementById('gkSummaryStrip');
        box.innerHTML = '';

        if (!discoverData.length) {
            strip.hidden = true;
            document.getElementById('gkDiscoverEmpty').hidden = false;
            return;
        }
        document.getElementById('gkDiscoverEmpty').hidden = true;
        strip.hidden = false;
        document.getElementById('gkResultCount').textContent = discoverData.length + ' kèo phù hợp';

        var mode = document.getElementById('gkSortSelect').value;
        var list = discoverData.slice();
        if (mode === 'soonest') {
            list.sort(function (a, b) {
                var d = String(a.ngayDat || '').localeCompare(String(b.ngayDat || ''));
                return d !== 0 ? d : String(a.gioBatDau || '').localeCompare(String(b.gioBatDau || ''));
            });
        } else if (mode === 'newest') {
            list.sort(function (a, b) { return (b.keoId || 0) - (a.keoId || 0); });
        } else if (mode === 'slots') {
            list.sort(function (a, b) {
                return ((b.soNguoiCanTim || 0) - (b.soNguoiThamGia || 0)) - ((a.soNguoiCanTim || 0) - (a.soNguoiThamGia || 0));
            });
        }
        list.forEach(function (m) { box.appendChild(matchCard(m, false)); });
    };

    /* ---------------------------- Thẻ kèo (P11) ---------------------------- */
    /* ownerView: kèo do mình tạo. joinedView: kèo mình đã tham gia — không được
       mời tham gia lần nữa (P13: không hiện nút sai trạng thái). Muốn rời kèo thì
       vào "Xem chi tiết", vì API rời kèo cần chiTietKeoId mà danh sách không trả về. */
    function matchCard(m, ownerView, joinedView) {
        var card = document.createElement('article');
        card.className = 'match-item';

        var capacity = m.soNguoiCanTim || 1;
        var joined = m.soNguoiThamGia || 0;
        var percent = Math.min(100, Math.round((joined / capacity) * 100));
        var trangThai = m.trangThai || STATUS_OPEN;
        var ended = isPast(m);
        var canJoin = !ownerView && !joinedView && trangThai === STATUS_OPEN && !ended && joined < capacity;

        var statusLabel = ended && trangThai !== STATUS_CANCEL ? 'Đã kết thúc' : trangThai;
        var statusCls = ended && trangThai !== STATUS_CANCEL ? 'is-closed' : statusClass(trangThai);

        var html =
            '<div class="match-item-top">'
              + '<span class="match-badge is-sport">' + escapeHtml(m.tenMonTheThao || 'Thể thao') + '</span>'
              + '<span class="match-badge ' + statusCls + '">' + escapeHtml(statusLabel) + '</span>'
              + (joinedView ? '<span class="match-badge is-joined">Bạn đã tham gia</span>' : '')
              + '<span class="match-badge ' + reputationClass(m.diemUyTinNguoiTao) + ' match-badge-spacer" title="Điểm uy tín chủ kèo">'
                + escapeHtml(reputationLabel(m.diemUyTinNguoiTao))
                + (m.diemUyTinNguoiTao != null ? (' · ' + m.diemUyTinNguoiTao + '/100') : '')
              + '</span>'
            + '</div>'
            + '<div>'
              + '<h3 class="match-item-title">' + escapeHtml(m.tenCoSo || 'Cơ sở') + ' · ' + escapeHtml(m.tenSan || 'Sân') + '</h3>'
              + (m.diaChiCoSo ? '<p class="match-item-addr">' + escapeHtml(m.diaChiCoSo) + '</p>' : '')
            + '</div>'
            + '<div class="match-item-meta">'
              + '<span>' + icon('date') + fmtDateVi(m.ngayDat) + '</span>'
              + '<span>' + icon('clock') + escapeHtml(m.gioBatDau || '') + '–' + escapeHtml(m.gioKetThuc || '') + '</span>'
              + (m.trinhDo ? '<span>' + icon('level') + escapeHtml(m.trinhDo) + '</span>' : '')
              + '<span>' + icon('user') + escapeHtml(m.tenNguoiTao || '—') + '</span>'
            + '</div>'
            + (m.actualNote ? '<p class="match-item-note">' + escapeHtml(m.actualNote) + '</p>' : '')
            + '<div class="match-slots">'
              + '<div class="match-slot-bar"><div class="match-slot-fill" style="width:' + percent + '%"></div></div>'
              + '<div class="match-slot-text">'
                + '<span>' + joined + '/' + capacity + ' người đã tham gia</span>'
                + '<span>' + (joined >= capacity ? 'Đã đủ người' : 'Còn ' + (capacity - joined) + ' chỗ') + '</span>'
              + '</div>'
            + '</div>';

        // Hành động theo vai trò + trạng thái (P13): không bao giờ hiện nút sai trạng thái.
        var actions = '<div class="match-item-actions">'
            + '<button type="button" class="match-action is-ghost is-block" data-action="detail" data-keoid="' + m.keoId + '">'
              + 'Xem chi tiết</button>';

        if (ownerView) {
            if (trangThai === STATUS_OPEN && !ended) {
                actions += '<button type="button" class="match-action is-blue" data-action="close" data-keoid="' + m.keoId + '">Đóng kèo</button>';
            }
            if ((trangThai === STATUS_OPEN || trangThai === STATUS_FULL) && !ended) {
                actions += '<button type="button" class="match-action is-danger" data-action="cancel" data-keoid="' + m.keoId + '">Hủy kèo</button>';
            }
        } else if (canJoin) {
            actions += '<button type="button" class="match-action is-primary" data-action="join" data-keoid="' + m.keoId + '">Tham gia kèo</button>';
        }
        actions += '</div>';

        card.innerHTML = html + actions;

        card.querySelectorAll('[data-action]').forEach(function (btn) {
            btn.addEventListener('click', function () {
                var action = btn.dataset.action;
                var keoId = btn.dataset.keoid;
                if (action === 'detail') openMatchSheet(keoId);
                if (action === 'join')   requestJoin(keoId, btn);
                if (action === 'close')  gkOpenConfirm('Đóng kèo?', 'Kèo sẽ chuyển sang trạng thái "Đã đủ người" và không nhận thêm người tham gia.', 'Đóng kèo', function () { ownerActionById(keoId, 'close'); });
                if (action === 'cancel') gkOpenConfirm('Hủy kèo này?', 'Kèo sẽ bị hủy và không còn hiển thị cho người chơi khác. Thao tác này không thể hoàn tác.', 'Hủy kèo', function () { ownerActionById(keoId, 'cancel'); });
            });
        });
        return card;
    }

    function requestJoin(keoId, btn) {
        if (!ME_ID) { gkToast('Vui lòng đăng nhập để tham gia kèo.', 'danger'); return; }
        if (btn.disabled) return;
        var original = btn.innerHTML;
        btn.disabled = true;
        btn.textContent = 'Đang gửi...';
        var form = new FormData();
        form.append('keoId', keoId);
        fetch(CTX + '/customer/api/matches/join', { method: 'POST', body: form, headers: { 'Accept': 'application/json' } })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                gkToast(data.message || (data.success ? 'Đã gửi yêu cầu.' : 'Không thể tham gia.'), data.success ? 'success' : 'danger');
                if (data.success) { gkLoadDiscover(); gkLoadMine(); }
                else { btn.disabled = false; btn.innerHTML = original; }
            })
            .catch(function () {
                gkToast('Không thể gửi yêu cầu. Vui lòng thử lại.', 'danger');
                btn.disabled = false;
                btn.innerHTML = original;
            });
    }

    /* --------------------------- Sheet chi tiết ---------------------------- */
    var currentDetailKeoId = null;
    var lastFocused = null;

    function openMatchSheet(keoId) {
        currentDetailKeoId = keoId;
        lastFocused = document.activeElement;
        document.getElementById('gkSheetBody').innerHTML =
            '<div class="match-skeleton" style="height:90px;margin-bottom:12px;"></div>'
          + '<div class="match-skeleton" style="height:130px;"></div>';
        document.getElementById('gkSheetBar').innerHTML = '';
        document.getElementById('gkOverlay').classList.add('is-open');
        document.getElementById('gkSheet').classList.add('is-open');
        document.body.style.overflow = 'hidden';

        fetch(CTX + '/customer/api/matches/detail?keoId=' + encodeURIComponent(keoId))
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (!data.success) throw new Error('unavailable');
                renderSheet(data);
            })
            .catch(function () {
                document.getElementById('gkSheetBody').innerHTML =
                    '<div class="match-error"><p>Không thể tải chi tiết kèo. Vui lòng thử lại.</p></div>';
            });
    }

    window.gkCloseSheet = function () {
        document.getElementById('gkOverlay').classList.remove('is-open');
        document.getElementById('gkSheet').classList.remove('is-open');
        document.body.style.overflow = '';
        currentDetailKeoId = null;
        if (lastFocused && lastFocused.focus) lastFocused.focus();
    };

    function renderSheet(data) {
        var m = data.match;
        var participants = data.participants || [];
        var me = data.me;
        var isOwner = !!data.isOwner;
        var capacity = m.soNguoiCanTim || 1;
        var joined = m.soNguoiThamGia || 0;
        var ended = isPast(m);

        var body = document.getElementById('gkSheetBody');
        body.innerHTML =
            '<div style="display:flex;flex-wrap:wrap;gap:8px;margin-bottom:14px;">'
              + '<span class="match-badge is-sport">' + escapeHtml(m.tenMonTheThao || 'Thể thao') + '</span>'
              + '<span class="match-badge ' + statusClass(m.trangThai) + '">' + escapeHtml(m.trangThai || '') + '</span>'
              + '<span class="match-badge ' + reputationClass(m.diemUyTinNguoiTao) + '">'
                + escapeHtml(reputationLabel(m.diemUyTinNguoiTao))
                + (m.diemUyTinNguoiTao != null ? (' · ' + m.diemUyTinNguoiTao + '/100') : '')
              + '</span>'
            + '</div>'
            + '<h3 style="margin:0 0 5px;font-size:17px;font-weight:800;color:var(--vs-primary-900,#0B2545);">'
              + escapeHtml(m.tenCoSo || '') + ' · ' + escapeHtml(m.tenSan || '') + '</h3>'
            + '<p style="margin:0 0 14px;font-size:13px;color:var(--vs-text-secondary,#486581);">' + escapeHtml(m.diaChiCoSo || '') + '</p>'
            + '<div class="match-detail-block">'
              + '<div><b>Thời gian:</b> ' + fmtDateVi(m.ngayDat) + ' · ' + escapeHtml(m.gioBatDau || '') + '–' + escapeHtml(m.gioKetThuc || '') + '</div>'
              + '<div><b>Loại sân:</b> ' + escapeHtml(m.tenLoaiSan || '—') + '</div>'
              + '<div><b>Trình độ:</b> ' + escapeHtml(m.trinhDo || 'Không yêu cầu') + '</div>'
              + '<div><b>Hình thức duyệt:</b> ' + (m.hinhThucDuyet === 'manual' ? 'Chủ kèo duyệt từng người' : 'Tự động chấp nhận') + '</div>'
              + '<div><b>Tình trạng:</b> ' + joined + '/' + capacity + ' người'
                + (joined < capacity ? (' · Còn ' + (capacity - joined) + ' chỗ') : ' · Đã đủ') + '</div>'
            + '</div>'
            + (m.actualNote ? '<p style="margin:14px 0 0;font-size:14px;line-height:1.55;color:var(--vs-text,#102A43);"><b>Ghi chú:</b> ' + escapeHtml(m.actualNote) + '</p>' : '')
            + '<h3 style="margin:20px 0 8px;font-size:14px;font-weight:800;color:var(--vs-primary-900,#0B2545);">Chủ kèo</h3>'
            + '<div class="match-person">'
              + '<div class="match-avatar" aria-hidden="true">' + escapeHtml(initials(m.tenNguoiTao)) + '</div>'
              + '<div>'
                + '<div class="match-person-name">' + escapeHtml(m.tenNguoiTao || '—') + '</div>'
                + '<div class="match-person-sub">Uy tín: ' + (m.diemUyTinNguoiTao != null ? m.diemUyTinNguoiTao + '/100' : '—') + '</div>'
              + '</div>'
            + '</div>'
            + '<h3 style="margin:20px 0 8px;font-size:14px;font-weight:800;color:var(--vs-primary-900,#0B2545);">Người tham gia (' + participants.length + ')</h3>'
            + (participants.length ? '' : '<p class="match-person-sub">Chưa có ai xin tham gia.</p>');

        participants.forEach(function (p) {
            var row = document.createElement('div');
            row.className = 'match-person';
            var statusText = p.trangThaiThamGia || '';
            row.innerHTML =
                '<div class="match-avatar" aria-hidden="true">' + escapeHtml(initials(p.tenNguoiChoi)) + '</div>'
              + '<div>'
                + '<div class="match-person-name">' + escapeHtml(p.tenNguoiChoi || 'Người chơi') + '</div>'
                + '<div class="match-person-sub">Uy tín: ' + (p.diemUyTin != null ? p.diemUyTin + '/100' : '—') + ' · ' + escapeHtml(statusText) + '</div>'
              + '</div>';
            var actions = document.createElement('div');
            actions.className = 'match-person-actions';
            if (isOwner && statusText === 'Chờ duyệt') {
                var bA = document.createElement('button');
                bA.type = 'button'; bA.className = 'match-mini is-approve'; bA.textContent = 'Duyệt';
                bA.onclick = function () { participantAction(p.chiTietKeoId, 'approve'); };
                var bR = document.createElement('button');
                bR.type = 'button'; bR.className = 'match-mini is-reject'; bR.textContent = 'Từ chối';
                bR.onclick = function () { participantAction(p.chiTietKeoId, 'reject'); };
                actions.appendChild(bA); actions.appendChild(bR);
            } else if (me && me.chiTietKeoId === p.chiTietKeoId && (statusText === 'Chờ duyệt' || statusText === 'Đã tham gia')) {
                var bL = document.createElement('button');
                bL.type = 'button'; bL.className = 'match-mini is-reject'; bL.textContent = 'Rời kèo';
                bL.onclick = function () { participantAction(p.chiTietKeoId, 'leave'); };
                actions.appendChild(bL);
            }
            row.appendChild(actions);
            body.appendChild(row);
        });

        var bar = document.getElementById('gkSheetBar');
        bar.innerHTML = '';
        if (isOwner) {
            if (m.trangThai === STATUS_OPEN && !ended) {
                var btnClose = document.createElement('button');
                btnClose.type = 'button'; btnClose.className = 'match-action is-ghost is-block';
                btnClose.textContent = 'Dừng nhận người';
                btnClose.onclick = function () {
                    gkOpenConfirm('Dừng nhận người?', 'Kèo sẽ chuyển sang "Đã đủ người" và không nhận thêm yêu cầu tham gia.', 'Dừng nhận', function () { ownerAction('close'); });
                };
                bar.appendChild(btnClose);
            }
            if ((m.trangThai === STATUS_OPEN || m.trangThai === STATUS_FULL) && !ended) {
                var btnCancel = document.createElement('button');
                btnCancel.type = 'button'; btnCancel.className = 'match-action is-danger is-block';
                btnCancel.textContent = 'Hủy kèo';
                btnCancel.onclick = function () {
                    gkOpenConfirm('Hủy kèo này?', 'Kèo sẽ bị hủy và không còn hiển thị cho người chơi khác. Thao tác này không thể hoàn tác.', 'Hủy kèo', function () { ownerAction('cancel'); });
                };
                bar.appendChild(btnCancel);
            }
        } else if (!data.isLoggedIn) {
            var a = document.createElement('a');
            a.href = CTX + '/dangnhap';
            a.className = 'match-action is-primary is-block';
            a.textContent = 'Đăng nhập để tham gia';
            bar.appendChild(a);
        } else if (!me && m.trangThai === STATUS_OPEN && !ended && joined < capacity) {
            var btnJoin = document.createElement('button');
            btnJoin.type = 'button'; btnJoin.className = 'match-action is-primary is-block';
            btnJoin.textContent = m.hinhThucDuyet === 'manual' ? 'Gửi yêu cầu tham gia' : 'Tham gia ngay';
            btnJoin.onclick = function () { requestJoin(m.keoId, btnJoin); };
            bar.appendChild(btnJoin);
        } else if (me) {
            var btnLeave = document.createElement('button');
            btnLeave.type = 'button'; btnLeave.className = 'match-action is-danger is-block';
            btnLeave.textContent = 'Rời kèo';
            btnLeave.onclick = function () {
                gkOpenConfirm('Rời kèo?', 'Bạn sẽ không còn nằm trong danh sách người tham gia của kèo này.', 'Rời kèo', function () { participantAction(me.chiTietKeoId, 'leave'); });
            };
            bar.appendChild(btnLeave);
        }
    }

    function participantAction(chiTietKeoId, action) {
        var form = new FormData();
        form.append('chiTietKeoId', chiTietKeoId);
        fetch(CTX + '/customer/api/matches/' + action, { method: 'POST', body: form })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                gkToast(data.message || (data.success ? 'Đã cập nhật.' : 'Không thể cập nhật.'), data.success ? 'success' : 'danger');
                if (data.success && currentDetailKeoId) openMatchSheet(currentDetailKeoId);
                if (data.success) gkLoadMine();
            })
            .catch(function () { gkToast('Không thể cập nhật. Vui lòng thử lại.', 'danger'); });
    }

    function postOwner(keoId, action) {
        var form = new FormData();
        form.append('keoId', keoId);
        return fetch(CTX + '/customer/api/matches/' + action, { method: 'POST', body: form })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                gkToast(data.message || (data.success ? 'Đã cập nhật.' : 'Không thể cập nhật.'), data.success ? 'success' : 'danger');
                if (data.success) { gkLoadMine(); gkLoadDiscover(); }
                return data;
            })
            .catch(function () { gkToast('Không thể cập nhật. Vui lòng thử lại.', 'danger'); });
    }
    function ownerAction(action) {
        if (!currentDetailKeoId) return;
        var id = currentDetailKeoId;
        postOwner(id, action).then(function (data) { if (data && data.success) gkCloseSheet(); });
    }
    function ownerActionById(keoId, action) { postOwner(keoId, action); }

    /* --------------------- Tạo kèo: tải ca đặt sân ------------------------- */
    var myBookings = [];

    window.gkLoadBookingsForCreate = function () {
        document.getElementById('gkBookingsLoading').hidden = false;
        document.getElementById('gkNoBookings').hidden = true;
        document.getElementById('gkCreateLayout').hidden = true;

        fetch(CTX + '/customer/api/matches/my-bookings')
            .then(function (r) { return r.json(); })
            .then(function (data) {
                document.getElementById('gkBookingsLoading').hidden = true;
                if (!data.success) throw new Error('unavailable');
                myBookings = data.bookings || [];
                if (!myBookings.length) {
                    document.getElementById('gkNoBookings').hidden = false;
                    return;
                }
                document.getElementById('gkCreateLayout').hidden = false;
                var sel = document.getElementById('gkBookingSelect');
                sel.innerHTML = '<option value="">-- Chọn ca đặt sân --</option>';
                myBookings.forEach(function (b) {
                    var opt = document.createElement('option');
                    opt.value = b.datSanId;
                    opt.textContent = fmtDateVi(b.ngayDat) + ' · ' + b.gioBatDau + '–' + b.gioKetThuc
                        + ' · ' + b.tenSan + ' (' + b.tenCoSo + ') · ' + b.trangThai;
                    sel.appendChild(opt);
                });
                if (server.preSanId) {
                    var found = myBookings.find(function (b) { return b.sanId === server.preSanId; });
                    if (found) { sel.value = found.datSanId; gkOnBookingChange(); }
                }
            })
            .catch(function () {
                document.getElementById('gkBookingsLoading').hidden = true;
                document.getElementById('gkNoBookings').hidden = false;
            });
    };

    window.gkOnBookingChange = function () {
        var id = document.getElementById('gkBookingSelect').value;
        var b = myBookings.find(function (x) { return x.datSanId == id; });
        var box = document.getElementById('gkPreviewBox');
        if (id) setFieldError('gkBookingSelect', 'gkBookingError', false);
        if (!b) {
            box.innerHTML = '<div class="match-preview-empty">Chọn ca đặt sân để xem trước thẻ kèo.</div>';
            return;
        }
        var cap = parseInt(document.getElementById('gkSoNguoi').value, 10) || 1;
        var trinhDo = document.getElementById('gkTrinhDo').value || 'Không yêu cầu';
        var note = document.getElementById('gkNote').value || '';
        box.innerHTML =
            '<div style="display:flex;flex-wrap:wrap;gap:7px;margin-bottom:10px;">'
              + '<span class="match-badge is-sport">' + escapeHtml(b.tenLoaiSan || 'Thể thao') + '</span>'
              + '<span class="match-badge is-open">Đang mở</span>'
            + '</div>'
            + '<h4 style="margin:0 0 4px;font-size:15px;font-weight:800;color:var(--vs-primary-900,#0B2545);">'
              + escapeHtml(b.tenCoSo) + ' · ' + escapeHtml(b.tenSan) + '</h4>'
            + '<p style="margin:0;font-size:13px;line-height:1.55;color:var(--vs-text-secondary,#486581);">'
              + fmtDateVi(b.ngayDat) + ' · ' + escapeHtml(b.gioBatDau) + '–' + escapeHtml(b.gioKetThuc)
              + '<br>Cần thêm ' + cap + ' người · Trình độ: ' + escapeHtml(trinhDo)
            + '</p>'
            + (note ? '<p style="margin:8px 0 0;font-size:13px;color:var(--vs-text,#102A43);">' + escapeHtml(note) + '</p>' : '')
            + (b.tongTienDuKien ? '<p style="margin:8px 0 0;font-size:12.5px;color:var(--vs-text-secondary,#486581);">Tiền sân dự kiến (chủ kèo trả): ' + fmtVnd(b.tongTienDuKien) + '</p>' : '');
    };

    function setFieldError(fieldId, errorId, show, message) {
        var field = document.getElementById(fieldId);
        var err = document.getElementById(errorId);
        if (field) field.classList.toggle('match-invalid', !!show);
        if (field) field.setAttribute('aria-invalid', show ? 'true' : 'false');
        if (err) {
            if (message) err.textContent = message;
            err.classList.toggle('is-shown', !!show);
        }
    }

    document.addEventListener('input', function (e) {
        if (!e.target || !e.target.id) return;
        if (e.target.id === 'gkSoNguoi' || e.target.id === 'gkTrinhDo' || e.target.id === 'gkNote') gkOnBookingChange();
        if (e.target.id === 'gkNote') document.getElementById('gkNoteCount').textContent = e.target.value.length;
        if (e.target.id === 'gkSoNguoi') {
            var n = parseInt(e.target.value, 10);
            setFieldError('gkSoNguoi', 'gkSoNguoiError', !(n >= 1 && n <= 20));
        }
    });
    document.addEventListener('change', function (e) {
        if (e.target && e.target.id === 'gkTrinhDo') gkOnBookingChange();
    });
    document.querySelectorAll('.match-radio input').forEach(function (r) {
        r.addEventListener('change', function () {
            document.querySelectorAll('.match-radio').forEach(function (l) {
                l.classList.toggle('is-selected', l.querySelector('input').checked);
            });
        });
    });

    window.gkSubmitCreate = function (evt) {
        evt.preventDefault();
        var btn = document.getElementById('gkCreateSubmit');
        var label = document.getElementById('gkCreateSubmitLabel');
        if (btn.disabled) return false;   // chống double-submit

        var datSanId = document.getElementById('gkBookingSelect').value;
        var soNguoi = parseInt(document.getElementById('gkSoNguoi').value, 10);
        var valid = true;

        if (!datSanId) { setFieldError('gkBookingSelect', 'gkBookingError', true); valid = false; }
        else setFieldError('gkBookingSelect', 'gkBookingError', false);

        if (!(soNguoi >= 1 && soNguoi <= 20)) { setFieldError('gkSoNguoi', 'gkSoNguoiError', true); valid = false; }
        else setFieldError('gkSoNguoi', 'gkSoNguoiError', false);

        if (!valid) {
            gkToast('Vui lòng kiểm tra lại thông tin đã nhập.', 'danger');
            var firstBad = document.querySelector('#gkCreateForm .match-invalid');
            if (firstBad) firstBad.focus();
            return false;
        }

        var b = myBookings.find(function (x) { return x.datSanId == datSanId; });
        var form = new FormData();
        form.append('datSanId', datSanId);
        if (b && b.monTheThaoId != null) form.append('monTheThaoId', b.monTheThaoId);
        form.append('soNguoiCanTim', soNguoi);
        form.append('trinhDo', document.getElementById('gkTrinhDo').value);
        var approveEl = document.querySelector('.match-radio input[name="approve"]:checked');
        form.append('hinhThucDuyet', approveEl ? approveEl.value : 'auto');
        form.append('note', document.getElementById('gkNote').value);

        btn.disabled = true;
        label.textContent = 'Đang tạo kèo...';

        fetch(CTX + '/customer/ghep-keo', {
            method: 'POST',
            body: form,
            headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' }
        })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                gkToast(data.message || (data.success ? 'Đã tạo kèo.' : 'Không thể tạo kèo.'), data.success ? 'success' : 'danger');
                btn.disabled = false;
                label.textContent = 'Xác nhận tạo kèo';
                if (data.success) {
                    document.getElementById('gkNote').value = '';
                    document.getElementById('gkNoteCount').textContent = '0';
                    gkOpenTab('cua-toi');
                }
            })
            .catch(function () {
                btn.disabled = false;
                label.textContent = 'Xác nhận tạo kèo';
                gkToast('Không thể tạo kèo. Vui lòng thử lại.', 'danger');
            });
        return false;
    };

    /* ----------------------------- Kèo của tôi ----------------------------- */
    var mineCreated = [];
    var mineJoined = [];
    var mineFilter = 'all';

    function matchesFilter(m) {
        if (mineFilter === 'all') return true;
        var ended = isPast(m);
        var st = m.trangThai;
        if (mineFilter === 'cancel')   return st === STATUS_CANCEL;
        if (mineFilter === 'ended')    return ended && st !== STATUS_CANCEL;
        if (mineFilter === 'open')     return st === STATUS_OPEN && !ended;
        if (mineFilter === 'full')     return st === STATUS_FULL && !ended;
        if (mineFilter === 'upcoming') return !ended && st !== STATUS_CANCEL;
        return true;
    }

    window.gkFilterMine = function (status, btn) {
        mineFilter = status;
        document.querySelectorAll('.match-chip').forEach(function (c) { c.classList.remove('is-active'); });
        if (btn) btn.classList.add('is-active');
        renderMine();
    };

    function renderMine() {
        var createdBox = document.getElementById('gkMineCreatedList');
        var joinedBox = document.getElementById('gkMineJoinedList');
        createdBox.innerHTML = '';
        joinedBox.innerHTML = '';

        var c = mineCreated.filter(matchesFilter);
        var j = mineJoined.filter(matchesFilter);

        document.getElementById('gkMineCreatedEmpty').hidden = c.length > 0;
        document.getElementById('gkMineJoinedEmpty').hidden = j.length > 0;

        c.forEach(function (m) { createdBox.appendChild(matchCard(m, true)); });
        j.forEach(function (m) { joinedBox.appendChild(matchCard(m, false, true)); });
    }

    window.gkLoadMine = function () {
        var badge = document.getElementById('gkMineBadge');
        var loading = document.getElementById('gkMineLoading');
        var errBox = document.getElementById('gkMineError');
        var content = document.getElementById('gkMineContent');

        if (!ME_ID) {
            mineCreated = []; mineJoined = [];
            loading.hidden = true; errBox.hidden = true; content.hidden = false;
            renderMine();
            badge.hidden = true;
            return;
        }

        loading.hidden = false;
        errBox.hidden = true;
        content.hidden = true;

        fetch(CTX + '/customer/api/matches/mine')
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (!data.success) throw new Error('unavailable');
                mineCreated = data.created || [];
                mineJoined = data.joined || [];
                loading.hidden = true;
                content.hidden = false;
                renderMine();
                var total = mineCreated.length + mineJoined.length;
                if (total > 0) { badge.hidden = false; badge.textContent = total; }
                else { badge.hidden = true; }
            })
            .catch(function () {
                loading.hidden = true;
                content.hidden = true;
                errBox.hidden = false;
            });
    };

    /* -------------------------------- Init --------------------------------- */
    document.addEventListener('keydown', function (e) {
        if (e.key !== 'Escape') return;
        if (document.getElementById('gkConfirm').classList.contains('is-open')) { window.gkCloseConfirm(); return; }
        if (document.getElementById('gkSheet').classList.contains('is-open')) { gkCloseSheet(); }
    });

    gkOpenTab(server.initialTab || 'kham-pha');
    gkLoadMine(); // nạp sẵn badge "Kèo của tôi"
})();
</script>

<jsp:include page="/customer/common/bottom-nav.jsp" />
</body>
</html>
