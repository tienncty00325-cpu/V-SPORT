<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>Đội nhóm - V-SPORT</title>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover"/>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet" crossorigin="anonymous">
    <jsp:include page="/customer/common/vsport-theme.jsp" />
    <style>
        html, body { margin: 0; padding-bottom: 0 !important; background: var(--vs-background); font-family: 'Inter', system-ui, -apple-system, sans-serif; color: var(--vs-text); }
        * { box-sizing: border-box; }
        button { font-family: inherit; }
        a:focus-visible, button:focus-visible, input:focus-visible, [tabindex]:focus-visible {
            outline: 2.5px solid var(--vs-cyan-500) !important; outline-offset: 2px;
        }

        .dn-appbar {
            position: sticky; top: 0; z-index: 50;
            height: 52px; display: flex; align-items: center; justify-content: center;
            background: var(--vs-primary-900); color: #fff;
        }
        .dn-back {
            position: absolute; left: 8px; top: 50%; transform: translateY(-50%);
            width: 40px; height: 40px; border-radius: 50%; border: none; background: transparent; color: #fff;
            display: flex; align-items: center; justify-content: center; cursor: pointer;
        }
        .dn-back:hover { background: rgba(255,255,255,.12); }
        .dn-appbar h1 { font-size: 16px; font-weight: 700; margin: 0; }

        .dn-wrap { max-width: 960px; margin: 0 auto; padding: 16px 16px calc(var(--vs-bottomnav-h) + 96px); }
        @media (min-width: 1024px) { .dn-wrap { padding-bottom: calc(var(--vs-bottomnav-h-desktop) + 96px); } }

        .dn-tabs {
            display: flex; gap: 4px; background: var(--vs-surface-soft);
            border-radius: 10px; padding: 4px; margin: 0 auto 20px; max-width: 630px;
        }
        .dn-tab {
            flex: 1; border: none; background: transparent; cursor: pointer;
            padding: 10px 12px; border-radius: 8px; font-size: 13.5px; font-weight: 700;
            color: var(--vs-text-secondary); transition: background-color .18s ease, color .18s ease, box-shadow .18s ease;
        }
        .dn-tab.is-active { background: #fff; color: var(--vs-primary-900); box-shadow: 0 1px 3px rgba(15,23,42,.12); }

        .dn-panel { display: none; }
        .dn-panel.is-active { display: block; }

        .dn-filters { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 16px; }
        .dn-filters input[type="text"] {
            flex: 1 1 220px; min-width: 0; padding: 10px 14px; border-radius: var(--vs-r-btn);
            border: 1px solid var(--vs-border); font-size: 14px; background: #fff;
        }
        .dn-filters select {
            padding: 10px 12px; border-radius: var(--vs-r-btn); border: 1px solid var(--vs-border);
            background: #fff; font-size: 13.5px; color: var(--vs-text);
        }
        .dn-filter-toggle {
            display: inline-flex; align-items: center; gap: 6px; padding: 10px 14px;
            border-radius: var(--vs-r-btn); border: 1px solid var(--vs-border); background: #fff;
            font-size: 13.5px; font-weight: 600; color: var(--vs-text); cursor: pointer;
        }
        .dn-filter-toggle input { margin: 0; }

        .dn-grid { display: grid; grid-template-columns: 1fr; gap: 12px; }
        @media (min-width: 720px) { .dn-grid { grid-template-columns: repeat(2, 1fr); } }
        @media (min-width: 1024px) { .dn-grid { grid-template-columns: repeat(3, 1fr); } }

        .dn-card {
            background: var(--vs-card); border: 1px solid var(--vs-border); border-radius: var(--vs-r-card);
            padding: 14px; display: flex; flex-direction: column; gap: 10px;
        }
        .dn-card-top { display: flex; gap: 12px; align-items: flex-start; }
        .dn-avatar {
            width: 52px; height: 52px; border-radius: 50%; object-fit: cover; flex-shrink: 0;
            background: var(--vs-cyan-100); border: 1px solid var(--vs-border);
        }
        .dn-card-name { font-size: 15px; font-weight: 700; color: var(--vs-text); line-height: 1.3; margin: 0; }
        .dn-card-meta { font-size: 12.5px; color: var(--vs-text-secondary); margin-top: 2px; display: flex; flex-wrap: wrap; gap: 6px 10px; }
        .dn-card-desc { font-size: 13px; color: var(--vs-text-secondary); line-height: 1.5; margin: 0; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
        .dn-badge { display: inline-flex; align-items: center; gap: 4px; padding: 3px 9px; border-radius: 9999px; font-size: 11px; font-weight: 700; }
        .dn-badge.role { background: var(--vs-cyan-100); color: var(--vs-primary-700); }
        .dn-badge.slots { background: var(--vs-surface-soft); color: var(--vs-text-secondary); }
        .dn-badge.slots.full { background: var(--vs-danger-bg); color: var(--vs-danger); }
        .dn-card-actions { display: flex; gap: 8px; margin-top: auto; }
        .dn-btn {
            flex: 1; text-align: center; padding: 9px 10px; border-radius: var(--vs-r-btn); font-size: 13px; font-weight: 700;
            border: 1px solid var(--vs-border); background: #fff; color: var(--vs-text); cursor: pointer; text-decoration: none;
            transition: background-color .15s ease, opacity .15s ease;
        }
        .dn-btn:hover { border-color: var(--vs-cyan-500); color: var(--vs-primary-700); }
        .dn-btn.primary { background: var(--vs-orange-500); border-color: var(--vs-orange-500); color: #fff; }
        .dn-btn.primary:hover { background: var(--vs-orange-600); border-color: var(--vs-orange-600); color: #fff; }
        .dn-btn.secondary { background: var(--vs-primary-600); border-color: var(--vs-primary-600); color: #fff; }
        .dn-btn.secondary:hover { background: var(--vs-primary-700); border-color: var(--vs-primary-700); color: #fff; }
        .dn-btn:disabled { opacity: .55; cursor: not-allowed; }

        .dn-empty { text-align: center; padding: 64px 20px 40px; max-width: 380px; margin: 0 auto; }
        .dn-empty svg { width: 76px; height: 76px; color: var(--vs-cyan-500); margin: 0 auto 18px; }
        .dn-empty h2 { font-size: 16px; font-weight: 700; margin: 0 0 6px; color: var(--vs-text); }
        .dn-empty p { font-size: 13.5px; color: var(--vs-text-secondary); margin: 0 0 20px; line-height: 1.5; }
        .dn-empty-ctas { display: flex; gap: 10px; justify-content: center; flex-wrap: wrap; }
        .dn-empty-ctas .dn-btn { flex: 0 0 auto; padding: 10px 18px; }

        .dn-inv-card { display: flex; gap: 12px; align-items: flex-start; }
        .dn-inv-body { flex: 1; min-width: 0; }
        .dn-inv-meta { font-size: 12px; color: var(--vs-text-secondary); margin-top: 2px; }
        .dn-inv-msg { font-size: 12.5px; color: var(--vs-text-secondary); margin-top: 6px; background: var(--vs-surface-soft); border-radius: 8px; padding: 8px 10px; }

        .dn-fab {
            position: fixed; right: 20px; z-index: 60;
            bottom: calc(var(--vs-bottomnav-h) + env(safe-area-inset-bottom, 0px) + 18px);
            display: inline-flex; align-items: center; gap: 8px; height: 48px; padding: 0 18px 0 16px;
            border-radius: 10px; border: none; cursor: pointer;
            background: var(--vs-orange-500); color: #fff; font-size: 14px; font-weight: 700;
            box-shadow: 0 8px 20px rgba(249,115,22,.32);
            transition: background-color .15s ease, transform .1s ease;
        }
        .dn-fab:hover { background: var(--vs-orange-600); }
        .dn-fab:active { transform: translateY(1px) scale(0.98); }
        .dn-fab svg { width: 20px; height: 20px; }
        @media (min-width: 1024px) { .dn-fab { bottom: calc(var(--vs-bottomnav-h-desktop) + 20px); } }

        .dn-toast {
            position: fixed; left: 50%; bottom: calc(var(--vs-bottomnav-h, 70px) + 18px);
            transform: translateX(-50%) translateY(12px); z-index: 1300;
            background: var(--vs-primary-900); color: #fff; padding: 10px 18px; border-radius: 9999px;
            font-size: 13px; font-weight: 600; opacity: 0; visibility: hidden;
            transition: opacity .2s ease, transform .2s ease; box-shadow: 0 8px 22px rgba(7,29,56,.3);
            max-width: 88vw; text-align: center;
        }
        .dn-toast.is-open { opacity: 1; visibility: visible; transform: translateX(-50%) translateY(0); }
        .dn-toast.is-danger { background: var(--vs-danger); }
        .dn-toast.is-success { background: var(--vs-success); }

        .dn-skeleton { text-align: center; padding: 40px 0; color: var(--vs-text-secondary); font-size: 13px; }

        .dn-notice {
            display: flex; gap: 10px; align-items: flex-start; margin: 0 auto 16px; max-width: 630px;
            background: var(--vs-warning-bg); border: 1px solid var(--vs-warning); border-radius: var(--vs-r-card);
            padding: 12px 14px; color: #8a6116; font-size: 13px; line-height: 1.5;
        }
        .dn-notice svg { width: 20px; height: 20px; flex-shrink: 0; margin-top: 1px; color: var(--vs-warning); }
    </style>
</head>
<body>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<header class="dn-appbar">
    <button type="button" class="dn-back" onclick="history.length > 1 ? history.back() : (window.location.href='${ctx}/customer/tai-khoan')" aria-label="Quay lại">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
    </button>
    <h1>Đội nhóm</h1>
</header>

<div class="dn-wrap">
    <c:if test="${teamsFeaturePending}">
        <div class="dn-notice" role="status">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>
            <span>Chức năng Đội nhóm đang được cấu hình. Vui lòng thử lại sau.</span>
        </div>
    </c:if>
    <div class="dn-tabs" role="tablist" aria-label="Chuyển tab đội nhóm">
        <button type="button" class="dn-tab" data-tab="my-teams" role="tab">Đội của bạn</button>
        <button type="button" class="dn-tab" data-tab="discover" role="tab">Tham gia</button>
        <button type="button" class="dn-tab" data-tab="invitations" role="tab">Lời mời</button>
    </div>

    <!-- ===================== Tab: Đội của bạn ===================== -->
    <section class="dn-panel" data-panel="my-teams">
        <div id="dnMyTeamsGrid" class="dn-grid"></div>
        <div id="dnMyTeamsEmpty" class="dn-empty" style="display:none;">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M6 21v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/><path d="M2.5 21a8.5 8.5 0 0 1 1.9-5.4"/><path d="M21.5 21a8.5 8.5 0 0 0-1.9-5.4"/></svg>
            <h2>Bạn chưa tham gia đội nào</h2>
            <p>Tạo đội mới hoặc tìm một đội phù hợp để bắt đầu.</p>
            <div class="dn-empty-ctas">
                <a class="dn-btn primary" href="${ctx}/customer/doi-nhom/tao">Tạo đội</a>
                <button type="button" class="dn-btn" data-goto-tab="discover">Tìm đội</button>
            </div>
        </div>
    </section>

    <!-- ===================== Tab: Tham gia (khám phá) ===================== -->
    <section class="dn-panel" data-panel="discover">
        <div class="dn-filters">
            <input type="text" id="dnDiscoverKeyword" placeholder="Tìm theo tên đội hoặc khu vực..." aria-label="Tìm kiếm đội"/>
            <select id="dnDiscoverSport" aria-label="Lọc theo môn thể thao">
                <option value="">Tất cả môn thể thao</option>
                <c:forEach var="mon" items="${dsMon}">
                    <option value="${mon.monTheThaoID}">${mon.tenMon}</option>
                </c:forEach>
            </select>
            <label class="dn-filter-toggle">
                <input type="checkbox" id="dnDiscoverOpenOnly"/> Còn chỗ trống
            </label>
        </div>
        <div id="dnDiscoverGrid" class="dn-grid"></div>
        <div id="dnDiscoverEmpty" class="dn-empty" style="display:none;">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.35-4.35"/></svg>
            <h2>Không tìm thấy đội phù hợp</h2>
            <p>Hãy thử từ khóa khác hoặc bỏ bớt bộ lọc.</p>
        </div>
    </section>

    <!-- ===================== Tab: Lời mời ===================== -->
    <section class="dn-panel" data-panel="invitations">
        <div id="dnInvitationsList" class="dn-grid" style="grid-template-columns:1fr;max-width:560px;margin:0 auto;"></div>
        <div id="dnInvitationsEmpty" class="dn-empty" style="display:none;">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="M3.3 7 12 12l8.7-5"/><path d="M12 22V12"/></svg>
            <h2>Chưa có lời mời nào</h2>
            <p>Khi đội trưởng một đội mời bạn, lời mời sẽ hiện ở đây.</p>
        </div>
    </section>
</div>

<a class="dn-fab" href="${ctx}/customer/doi-nhom/tao">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
    Tạo đội
</a>

<div id="dnToast" class="dn-toast" role="status" aria-live="polite"></div>

<jsp:include page="/customer/common/bottom-nav.jsp" />

<script>
(function () {
    'use strict';
    var CTX = "${ctx}";
    var FALLBACK_AVATAR = CTX + '/assets/images/vsport-fallback.svg';

    var initial = {
        myTeams: ${myTeamsJson},
        discover: ${discoverJson},
        invitations: ${invitationsJson}
    };
    var activeTab = "${activeTab}";

    // ================= Toast =================
    var toastTimer = null;
    window.dnToast = function (msg, kind) {
        var el = document.getElementById('dnToast');
        el.className = 'dn-toast is-open' + (kind === 'danger' ? ' is-danger' : kind === 'success' ? ' is-success' : '');
        el.textContent = msg;
        clearTimeout(toastTimer);
        toastTimer = setTimeout(function () { el.classList.remove('is-open'); }, 3000);
    };

    function esc(s) { return (s == null ? '' : String(s)).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
    function avatarSrc(path) { return path ? path : FALLBACK_AVATAR; }

    // ================= Tabs =================
    function setActiveTab(tab, pushState) {
        activeTab = tab;
        document.querySelectorAll('.dn-tab').forEach(function (t) { t.classList.toggle('is-active', t.getAttribute('data-tab') === tab); });
        document.querySelectorAll('.dn-panel').forEach(function (p) { p.classList.toggle('is-active', p.getAttribute('data-panel') === tab); });
        if (pushState !== false) {
            var url = CTX + '/customer/doi-nhom?tab=' + tab;
            history.replaceState({ tab: tab }, '', url);
        }
    }
    document.querySelectorAll('.dn-tab').forEach(function (btn) {
        btn.addEventListener('click', function () { setActiveTab(btn.getAttribute('data-tab')); });
    });
    document.querySelectorAll('[data-goto-tab]').forEach(function (btn) {
        btn.addEventListener('click', function () { setActiveTab(btn.getAttribute('data-goto-tab')); });
    });

    // ================= My teams =================
    function renderMyTeams(list) {
        var grid = document.getElementById('dnMyTeamsGrid');
        var empty = document.getElementById('dnMyTeamsEmpty');
        grid.innerHTML = '';
        if (!list || !list.length) { grid.style.display = 'none'; empty.style.display = 'block'; return; }
        grid.style.display = 'grid'; empty.style.display = 'none';
        list.forEach(function (t) {
            var roleLabel = t.myRole === 'CAPTAIN' ? 'Đội trưởng' : t.myRole === 'CO_CAPTAIN' ? 'Đội phó' : 'Thành viên';
            var full = t.memberCount >= t.maxMembers;
            var card = document.createElement('div');
            card.className = 'dn-card';
            card.innerHTML =
                '<div class="dn-card-top">' +
                    '<img class="dn-avatar" src="' + esc(avatarSrc(t.avatarPath)) + '" alt="" onerror="this.onerror=null;this.src=\'' + FALLBACK_AVATAR + '\';"/>' +
                    '<div style="min-width:0;flex:1;">' +
                        '<p class="dn-card-name">' + esc(t.teamName) + '</p>' +
                        '<div class="dn-card-meta">' +
                            '<span>' + esc(t.sportName || '') + '</span>' +
                            (t.locationText ? '<span>&middot; ' + esc(t.locationText) + '</span>' : '') +
                        '</div>' +
                    '</div>' +
                '</div>' +
                '<div class="dn-card-meta">' +
                    '<span class="dn-badge role">' + roleLabel + '</span>' +
                    '<span class="dn-badge slots' + (full ? ' full' : '') + '">' + t.memberCount + '/' + t.maxMembers + ' thành viên</span>' +
                '</div>' +
                '<div class="dn-card-actions">' +
                    '<a class="dn-btn secondary" href="' + CTX + '/customer/doi-nhom/chi-tiet?id=' + t.teamId + '">Xem đội</a>' +
                    (t.myRole === 'CAPTAIN' ? '<a class="dn-btn primary" href="' + CTX + '/customer/doi-nhom/tao-keo?teamId=' + t.teamId + '">Tạo kèo</a>' : '') +
                '</div>';
            grid.appendChild(card);
        });
    }

    // ================= Discover =================
    function renderDiscover(list) {
        var grid = document.getElementById('dnDiscoverGrid');
        var empty = document.getElementById('dnDiscoverEmpty');
        grid.innerHTML = '';
        if (!list || !list.length) { grid.style.display = 'none'; empty.style.display = 'block'; return; }
        grid.style.display = 'grid'; empty.style.display = 'none';
        list.forEach(function (t) {
            var full = t.memberCount >= t.maxMembers;
            var card = document.createElement('div');
            card.className = 'dn-card';
            var actionHtml;
            if (t.hasPendingJoinRequest) {
                actionHtml = '<button type="button" class="dn-btn" disabled>Đã gửi yêu cầu</button>';
            } else if (full) {
                actionHtml = '<button type="button" class="dn-btn" disabled>Đã đủ người</button>';
            } else {
                actionHtml = '<button type="button" class="dn-btn primary" data-join-team="' + t.teamId + '">Xin tham gia</button>';
            }
            card.innerHTML =
                '<div class="dn-card-top">' +
                    '<img class="dn-avatar" src="' + esc(avatarSrc(t.avatarPath)) + '" alt="" onerror="this.onerror=null;this.src=\'' + FALLBACK_AVATAR + '\';"/>' +
                    '<div style="min-width:0;flex:1;">' +
                        '<p class="dn-card-name">' + esc(t.teamName) + '</p>' +
                        '<div class="dn-card-meta"><span>' + esc(t.sportName || '') + '</span>' + (t.locationText ? '<span>&middot; ' + esc(t.locationText) + '</span>' : '') + '</div>' +
                    '</div>' +
                '</div>' +
                (t.description ? '<p class="dn-card-desc">' + esc(t.description) + '</p>' : '') +
                '<div class="dn-card-meta"><span class="dn-badge slots' + (full ? ' full' : '') + '">' + t.memberCount + '/' + t.maxMembers + ' thành viên</span></div>' +
                '<div class="dn-card-actions">' +
                    '<a class="dn-btn" href="' + CTX + '/customer/doi-nhom/chi-tiet?id=' + t.teamId + '">Xem đội</a>' +
                    actionHtml +
                '</div>';
            grid.appendChild(card);
        });
        grid.querySelectorAll('[data-join-team]').forEach(function (btn) {
            btn.addEventListener('click', function () { sendJoinRequest(btn); });
        });
    }

    function sendJoinRequest(btn) {
        var teamId = btn.getAttribute('data-join-team');
        btn.disabled = true; btn.textContent = 'Đang gửi...';
        var form = new FormData(); form.append('teamId', teamId);
        fetch(CTX + '/customer/doi-nhom/xin-tham-gia', { method: 'POST', body: form, headers: { 'Accept': 'application/json' } })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                dnToast(data.message || (data.success ? 'Đã gửi.' : 'Lỗi.'), data.success ? 'success' : 'danger');
                if (data.success) { btn.textContent = 'Đã gửi yêu cầu'; } else { btn.disabled = false; btn.textContent = 'Xin tham gia'; }
            })
            .catch(function () { dnToast('Không thể gửi yêu cầu. Thử lại.', 'danger'); btn.disabled = false; btn.textContent = 'Xin tham gia'; });
    }

    var discoverDebounce = null;
    function reloadDiscover() {
        var params = new URLSearchParams();
        params.set('tab', 'discover');
        var kw = document.getElementById('dnDiscoverKeyword').value.trim();
        if (kw) params.set('keyword', kw);
        var sport = document.getElementById('dnDiscoverSport').value;
        if (sport) params.set('sportId', sport);
        if (document.getElementById('dnDiscoverOpenOnly').checked) params.set('onlyOpenSlots', 'true');
        fetch(CTX + '/customer/api/teams?' + params.toString(), { headers: { 'Accept': 'application/json' } })
            .then(function (r) { return r.json(); })
            .then(renderDiscover)
            .catch(function () { dnToast('Không thể tải danh sách đội. Thử lại.', 'danger'); });
    }
    document.getElementById('dnDiscoverKeyword').addEventListener('input', function () {
        clearTimeout(discoverDebounce);
        discoverDebounce = setTimeout(reloadDiscover, 350);
    });
    document.getElementById('dnDiscoverSport').addEventListener('change', reloadDiscover);
    document.getElementById('dnDiscoverOpenOnly').addEventListener('change', reloadDiscover);

    // ================= Invitations =================
    function renderInvitations(list) {
        var wrap = document.getElementById('dnInvitationsList');
        var empty = document.getElementById('dnInvitationsEmpty');
        wrap.innerHTML = '';
        if (!list || !list.length) { wrap.style.display = 'none'; empty.style.display = 'block'; return; }
        wrap.style.display = 'grid'; empty.style.display = 'none';
        list.forEach(function (inv) {
            var card = document.createElement('div');
            card.className = 'dn-card dn-inv-card';
            card.innerHTML =
                '<img class="dn-avatar" src="' + esc(avatarSrc(inv.teamAvatarPath)) + '" alt="" onerror="this.onerror=null;this.src=\'' + FALLBACK_AVATAR + '\';"/>' +
                '<div class="dn-inv-body">' +
                    '<p class="dn-card-name">' + esc(inv.teamName) + '</p>' +
                    '<div class="dn-inv-meta">' + esc(inv.invitedByName) + ' đã mời bạn làm ' + (inv.proposedRole === 'CO_CAPTAIN' ? 'đội phó' : 'thành viên') + '</div>' +
                    (inv.message ? '<div class="dn-inv-msg">' + esc(inv.message) + '</div>' : '') +
                    '<div class="dn-card-actions" style="margin-top:10px;">' +
                        '<button type="button" class="dn-btn primary" data-accept-inv="' + inv.invitationId + '">Chấp nhận</button>' +
                        '<button type="button" class="dn-btn" data-reject-inv="' + inv.invitationId + '">Từ chối</button>' +
                    '</div>' +
                '</div>';
            wrap.appendChild(card);
        });
        wrap.querySelectorAll('[data-accept-inv]').forEach(function (btn) {
            btn.addEventListener('click', function () { respondInvitation(btn, btn.getAttribute('data-accept-inv'), 'chap-nhan-loi-moi'); });
        });
        wrap.querySelectorAll('[data-reject-inv]').forEach(function (btn) {
            btn.addEventListener('click', function () { respondInvitation(btn, btn.getAttribute('data-reject-inv'), 'tu-choi-loi-moi'); });
        });
    }

    function respondInvitation(btn, invitationId, action) {
        var card = btn.closest('.dn-inv-card');
        card.querySelectorAll('button').forEach(function (b) { b.disabled = true; });
        var form = new FormData(); form.append('invitationId', invitationId);
        fetch(CTX + '/customer/doi-nhom/' + action, { method: 'POST', body: form, headers: { 'Accept': 'application/json' } })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                dnToast(data.message || (data.success ? 'Đã xử lý.' : 'Lỗi.'), data.success ? 'success' : 'danger');
                if (data.success) {
                    card.remove();
                    if (data.teamId) { window.location.href = CTX + '/customer/doi-nhom/chi-tiet?id=' + data.teamId; }
                } else {
                    card.querySelectorAll('button').forEach(function (b) { b.disabled = false; });
                }
            })
            .catch(function () { dnToast('Không thể xử lý. Thử lại.', 'danger'); card.querySelectorAll('button').forEach(function (b) { b.disabled = false; }); });
    }

    // ================= Boot =================
    renderMyTeams(initial.myTeams);
    renderDiscover(initial.discover);
    renderInvitations(initial.invitations);
    setActiveTab(activeTab, false);
})();
</script>
</body>
</html>
