<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <title>${team.teamName} - Đội nhóm - V-SPORT</title>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover"/>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet" crossorigin="anonymous">
    <jsp:include page="/customer/common/vsport-theme.jsp" />
    <style>
        html, body { margin: 0; padding-bottom: 0 !important; background: var(--vs-background); font-family: 'Inter', system-ui, -apple-system, sans-serif; color: var(--vs-text); }
        * { box-sizing: border-box; }
        button { font-family: inherit; }
        a:focus-visible, button:focus-visible, input:focus-visible, textarea:focus-visible, select:focus-visible {
            outline: 2.5px solid var(--vs-cyan-500) !important; outline-offset: 2px;
        }

        .dc-appbar { position: sticky; top: 0; z-index: 50; height: 52px; display: flex; align-items: center; justify-content: center; background: var(--vs-primary-900); color: #fff; padding: 0 52px; }
        .dc-back, .dc-edit { position: absolute; top: 50%; transform: translateY(-50%); width: 40px; height: 40px; border-radius: 50%; border: none; background: transparent; color: #fff; display: flex; align-items: center; justify-content: center; cursor: pointer; text-decoration: none; }
        .dc-back { left: 8px; } .dc-edit { right: 8px; }
        .dc-back:hover, .dc-edit:hover { background: rgba(255,255,255,.12); }
        .dc-appbar h1 { font-size: 15px; font-weight: 700; margin: 0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

        .dc-wrap { max-width: 760px; margin: 0 auto; padding: 0 0 calc(var(--vs-bottomnav-h) + 40px); }
        @media (min-width: 1024px) { .dc-wrap { padding-bottom: calc(var(--vs-bottomnav-h-desktop) + 40px); } }

        .dc-cover { height: 150px; background: linear-gradient(135deg, var(--vs-primary-800), var(--vs-primary-600)); background-size: cover; background-position: center; position: relative; }
        .dc-header { padding: 0 16px; margin-top: -34px; position: relative; }
        .dc-avatar { width: 76px; height: 76px; border-radius: 50%; border: 3px solid #fff; object-fit: cover; background: var(--vs-cyan-100); box-shadow: 0 2px 8px rgba(15,23,42,.18); }
        .dc-name { font-size: 19px; font-weight: 800; margin: 10px 0 4px; }
        .dc-meta { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; font-size: 12.5px; color: var(--vs-text-secondary); }
        .dc-badge { display: inline-flex; align-items: center; gap: 4px; padding: 3px 10px; border-radius: 9999px; font-size: 11.5px; font-weight: 700; background: var(--vs-cyan-100); color: var(--vs-primary-700); }
        .dc-desc { font-size: 13.5px; color: var(--vs-text-secondary); line-height: 1.55; margin: 12px 0 0; }

        .dc-actions { display: flex; flex-wrap: wrap; gap: 8px; padding: 16px; }
        .dc-btn {
            padding: 10px 16px; border-radius: var(--vs-r-btn); font-size: 13.5px; font-weight: 700; cursor: pointer; border: 1px solid var(--vs-border);
            background: #fff; color: var(--vs-text); text-decoration: none; display: inline-flex; align-items: center; gap: 6px;
        }
        .dc-btn:hover { border-color: var(--vs-cyan-500); color: var(--vs-primary-700); }
        .dc-btn.primary { background: var(--vs-orange-500); border-color: var(--vs-orange-500); color: #fff; }
        .dc-btn.primary:hover { background: var(--vs-orange-600); border-color: var(--vs-orange-600); color: #fff; }
        .dc-btn.secondary { background: var(--vs-primary-600); border-color: var(--vs-primary-600); color: #fff; }
        .dc-btn.secondary:hover { background: var(--vs-primary-700); border-color: var(--vs-primary-700); color: #fff; }
        .dc-btn.danger { color: var(--vs-danger); border-color: var(--vs-danger-bg); }
        .dc-btn.danger:hover { background: var(--vs-danger-bg); border-color: var(--vs-danger); }
        .dc-btn:disabled { opacity: .55; cursor: not-allowed; }

        .dc-section { padding: 4px 16px 20px; }
        .dc-section h2 { font-size: 14.5px; font-weight: 700; margin: 0 0 10px; display: flex; align-items: center; justify-content: space-between; }
        .dc-section h2 .count { font-weight: 600; color: var(--vs-text-secondary); font-size: 12.5px; }

        .dc-member-row { display: flex; align-items: center; gap: 10px; padding: 10px; border: 1px solid var(--vs-border); border-radius: var(--vs-r-btn); background: #fff; }
        .dc-member-row + .dc-member-row { margin-top: 8px; }
        .dc-member-row img { width: 40px; height: 40px; border-radius: 50%; object-fit: cover; background: var(--vs-cyan-100); flex-shrink: 0; }
        .dc-member-info { flex: 1; min-width: 0; }
        .dc-member-name { font-size: 13.5px; font-weight: 700; }
        .dc-member-role { font-size: 11.5px; color: var(--vs-text-secondary); }
        .dc-member-actions { display: flex; gap: 6px; flex-shrink: 0; }
        .dc-mini-btn { padding: 6px 10px; border-radius: 8px; border: 1px solid var(--vs-border); background: #fff; font-size: 11.5px; font-weight: 700; cursor: pointer; }
        .dc-mini-btn:hover { border-color: var(--vs-cyan-500); }
        .dc-mini-btn.danger { color: var(--vs-danger); }
        .dc-mini-btn.danger:hover { border-color: var(--vs-danger); background: var(--vs-danger-bg); }

        .dc-request-card { display: flex; align-items: center; gap: 10px; padding: 10px; border: 1px solid var(--vs-border); border-radius: var(--vs-r-btn); background: #fff; }
        .dc-request-card + .dc-request-card { margin-top: 8px; }
        .dc-request-card img { width: 40px; height: 40px; border-radius: 50%; object-fit: cover; background: var(--vs-cyan-100); flex-shrink: 0; }

        .dc-match-panel { background: #fff; border: 1px solid var(--vs-border); border-radius: var(--vs-r-card); padding: 16px; display: none; margin-bottom: 14px; }
        .dc-match-panel.is-open { display: block; }
        .dc-match-panel .dt-field { margin-bottom: 14px; }
        .dc-match-panel label { display: block; font-size: 12.5px; font-weight: 700; margin-bottom: 6px; }
        .dc-match-panel select, .dc-match-panel textarea, .dc-match-panel input {
            width: 100%; padding: 9px 11px; border-radius: var(--vs-r-btn); border: 1px solid var(--vs-border); font-size: 13.5px; font-family: inherit;
        }
        .dc-match-card { border: 1px solid var(--vs-border); border-radius: var(--vs-r-btn); padding: 12px; background: #fff; }
        .dc-match-card + .dc-match-card { margin-top: 8px; }
        .dc-match-top { display: flex; justify-content: space-between; align-items: flex-start; gap: 8px; }
        .dc-match-title { font-size: 13.5px; font-weight: 700; }
        .dc-match-sub { font-size: 12px; color: var(--vs-text-secondary); margin-top: 2px; }
        .dc-status-pill { font-size: 11px; font-weight: 700; padding: 3px 9px; border-radius: 9999px; white-space: nowrap; }
        .dc-status-pill.open { background: var(--vs-cyan-100); color: var(--vs-primary-700); }
        .dc-status-pill.full { background: var(--vs-success-bg); color: var(--vs-success); }
        .dc-status-pill.cancelled { background: var(--vs-danger-bg); color: var(--vs-danger); }
        .dc-challenge-row { display: flex; align-items: center; gap: 8px; padding: 8px 0; border-top: 1px solid var(--vs-surface-soft); margin-top: 8px; }
        .dc-challenge-row img { width: 28px; height: 28px; border-radius: 50%; object-fit: cover; background: var(--vs-cyan-100); }
        .dc-challenge-row .name { flex: 1; font-size: 12.5px; font-weight: 600; }

        .dc-empty-inline { font-size: 12.5px; color: var(--vs-text-secondary); padding: 10px 0; }

        .dc-toast {
            position: fixed; left: 50%; bottom: calc(var(--vs-bottomnav-h, 70px) + 18px);
            transform: translateX(-50%) translateY(12px); z-index: 1300;
            background: var(--vs-primary-900); color: #fff; padding: 10px 18px; border-radius: 9999px;
            font-size: 13px; font-weight: 600; opacity: 0; visibility: hidden;
            transition: opacity .2s ease, transform .2s ease; box-shadow: 0 8px 22px rgba(7,29,56,.3);
            max-width: 88vw; text-align: center;
        }
        .dc-toast.is-open { opacity: 1; visibility: visible; transform: translateX(-50%) translateY(0); }
        .dc-toast.is-danger { background: var(--vs-danger); }
        .dc-toast.is-success { background: var(--vs-success); }

        /* Confirm dialog (giải tán / rời đội) */
        .dc-confirm-backdrop { position: fixed; inset: 0; z-index: 1100; background: var(--vs-overlay); opacity: 0; visibility: hidden; transition: opacity .18s ease; }
        .dc-confirm-backdrop.is-open { opacity: 1; visibility: visible; }
        .dc-confirm { position: fixed; left: 50%; top: 50%; transform: translate(-50%,-50%); z-index: 1200; width: min(360px, calc(100vw - 40px)); background: #fff; border-radius: var(--vs-r-card); padding: 20px; text-align: center; }
        .dc-confirm p { font-size: 13.5px; color: var(--vs-text-secondary); margin: 8px 0 18px; }
        .dc-confirm .row { display: flex; gap: 10px; }
        .dc-confirm .row button { flex: 1; padding: 10px; border-radius: var(--vs-r-btn); font-size: 13.5px; font-weight: 700; cursor: pointer; border: 1px solid var(--vs-border); background: #fff; }
        .dc-confirm .row button.confirm { background: var(--vs-danger); border-color: var(--vs-danger); color: #fff; }
    </style>
</head>
<body>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="fallbackAvatar" value="${ctx}/assets/images/vsport-fallback.svg" />

<header class="dc-appbar">
    <button type="button" class="dc-back" onclick="history.length > 1 ? history.back() : (window.location.href='${ctx}/customer/doi-nhom')" aria-label="Quay lại">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
    </button>
    <h1><c:out value="${team.teamName}"/></h1>
    <c:if test="${team.captain}">
        <a class="dc-edit" href="${ctx}/customer/doi-nhom/chinh-sua?id=${team.teamId}" aria-label="Chỉnh sửa đội">
            <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/></svg>
        </a>
    </c:if>
</header>

<div class="dc-wrap">
    <div class="dc-cover" style="<c:if test='${not empty team.coverImagePath}'>background-image:url('${team.coverImagePath}');</c:if>"></div>
    <div class="dc-header">
        <img class="dc-avatar" src="${not empty team.avatarPath ? team.avatarPath : fallbackAvatar}" alt="" onerror="this.onerror=null;this.src='${fallbackAvatar}';"/>
        <p class="dc-name"><c:out value="${team.teamName}"/></p>
        <div class="dc-meta">
            <span class="dc-badge"><c:out value="${team.sportName}"/></span>
            <c:if test="${not empty team.locationText}"><span>&middot; <c:out value="${team.locationText}"/></span></c:if>
            <span>&middot; ${team.memberCount}/${team.maxMembers} thành viên</span>
            <span>&middot; Đội trưởng: <c:out value="${team.captainName}"/></span>
        </div>
        <c:if test="${not empty team.description}"><p class="dc-desc"><c:out value="${team.description}"/></p></c:if>
    </div>

    <div class="dc-actions" id="dcActions">
        <c:choose>
            <c:when test="${team.captain}">
                <button type="button" class="dc-btn" id="dcInviteBtn">Mời thành viên</button>
                <button type="button" class="dc-btn primary" id="dcOpenMatchPanel">Tạo kèo đội</button>
                <button type="button" class="dc-btn danger" id="dcDisbandBtn">Giải tán đội</button>
            </c:when>
            <c:when test="${team.coCaptain}">
                <button type="button" class="dc-btn" id="dcInviteBtn">Mời thành viên</button>
                <button type="button" class="dc-btn primary" id="dcOpenMatchPanel">Tạo kèo đội</button>
                <button type="button" class="dc-btn danger" id="dcLeaveBtn">Rời đội</button>
            </c:when>
            <c:when test="${not empty team.myRole}">
                <button type="button" class="dc-btn danger" id="dcLeaveBtn">Rời đội</button>
            </c:when>
            <c:otherwise>
                <button type="button" class="dc-btn primary" id="dcJoinBtn" data-team-id="${team.teamId}">
                    ${team.memberCount >= team.maxMembers ? 'Đã đủ người' : 'Xin tham gia'}
                </button>
            </c:otherwise>
        </c:choose>
    </div>

    <div class="dc-section">
        <h2>Thành viên <span class="count">${team.memberCount}/${team.maxMembers}</span></h2>
        <c:forEach var="m" items="${team.members}">
            <div class="dc-member-row" data-account-id="${m.accountId}">
                <img src="${not empty m.avatarUrl ? m.avatarUrl : fallbackAvatar}" alt="" onerror="this.onerror=null;this.src='${fallbackAvatar}';"/>
                <div class="dc-member-info">
                    <div class="dc-member-name"><c:out value="${m.fullName}"/></div>
                    <div class="dc-member-role">
                        <c:choose><c:when test="${m.memberRole == 'CAPTAIN'}">Đội trưởng</c:when><c:when test="${m.memberRole == 'CO_CAPTAIN'}">Đội phó</c:when><c:otherwise>Thành viên</c:otherwise></c:choose>
                    </div>
                </div>
                <c:if test="${(team.captain || team.coCaptain) && m.memberRole != 'CAPTAIN'}">
                    <div class="dc-member-actions">
                        <c:if test="${team.captain}">
                            <button type="button" class="dc-mini-btn" data-transfer-captain="${m.accountId}">Chuyển đội trưởng</button>
                        </c:if>
                        <button type="button" class="dc-mini-btn danger" data-remove-member="${m.accountId}">Xóa</button>
                    </div>
                </c:if>
            </div>
        </c:forEach>
    </div>

    <c:if test="${team.captain || team.coCaptain}">
        <div class="dc-section">
            <h2>Yêu cầu tham gia đang chờ <span class="count">${fn:length(joinRequests)}</span></h2>
            <c:choose>
                <c:when test="${empty joinRequests}"><p class="dc-empty-inline">Không có yêu cầu nào đang chờ.</p></c:when>
                <c:otherwise>
                    <c:forEach var="jr" items="${joinRequests}">
                        <div class="dc-request-card">
                            <img src="${not empty jr.requesterAvatarUrl ? jr.requesterAvatarUrl : fallbackAvatar}" alt="" onerror="this.onerror=null;this.src='${fallbackAvatar}';"/>
                            <div class="dc-member-info">
                                <div class="dc-member-name"><c:out value="${jr.requesterName}"/></div>
                                <c:if test="${not empty jr.message}"><div class="dc-member-role"><c:out value="${jr.message}"/></div></c:if>
                            </div>
                            <div class="dc-member-actions">
                                <button type="button" class="dc-mini-btn" style="border-color:var(--vs-success);color:var(--vs-success);" data-approve-jr="${jr.joinRequestId}">Duyệt</button>
                                <button type="button" class="dc-mini-btn danger" data-reject-jr="${jr.joinRequestId}">Từ chối</button>
                            </div>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>
    </c:if>

    <div class="dc-section" id="tao-keo">
        <h2>Kèo đội</h2>

        <c:if test="${team.captain || team.coCaptain}">
            <div class="dc-match-panel" id="dcMatchPanel">
                <div class="dt-field">
                    <label for="dcBookingSelect">Ca đặt sân của bạn</label>
                    <select id="dcBookingSelect"><option value="">Đang tải...</option></select>
                </div>
                <div class="dt-field">
                    <label for="dcTrinhDo">Trình độ mong muốn</label>
                    <select id="dcTrinhDo">
                        <option value="">Không yêu cầu</option>
                        <option value="Mới chơi">Mới chơi</option>
                        <option value="Cơ bản">Cơ bản</option>
                        <option value="Trung bình">Trung bình</option>
                        <option value="Khá">Khá</option>
                        <option value="Nâng cao">Nâng cao</option>
                    </select>
                </div>
                <div class="dt-field">
                    <label for="dcNote">Ghi chú</label>
                    <textarea id="dcNote" maxlength="240" rows="2" placeholder="Ghi chú cho đối thủ (tùy chọn)"></textarea>
                </div>
                <button type="button" class="dc-btn primary" id="dcSubmitMatch" style="width:100%;justify-content:center;">Tạo kèo</button>
            </div>
            <p id="dcMyMatchesEmpty" class="dc-empty-inline" style="display:none;">Đội bạn chưa tạo kèo nào.</p>
            <div id="dcMyMatches"></div>
        </c:if>

        <h2 style="margin-top:18px;">Kèo đội đang mở (đội khác)</h2>
        <p id="dcOpenMatchesEmpty" class="dc-empty-inline" style="display:none;">Hiện chưa có kèo đội nào đang mở.</p>
        <div id="dcOpenMatches"></div>
    </div>
</div>

<!-- Invite member -->
<div class="dc-confirm-backdrop" id="dcInviteBackdrop"></div>
<div class="dc-confirm" id="dcInviteDialog" style="display:none;" role="dialog" aria-modal="true" aria-labelledby="dcInviteTitle">
    <p id="dcInviteTitle" style="font-weight:700;font-size:14.5px;margin:0 0 4px;">Mời thành viên</p>
    <div class="dt-field" style="text-align:left;">
        <label style="display:block;font-size:12.5px;font-weight:700;margin:10px 0 6px;">Email</label>
        <input type="email" id="dcInviteUsername" class="dt-input" placeholder="name@example.com" style="width:100%;padding:9px 11px;border-radius:8px;border:1px solid var(--vs-border);"/>
    </div>
    <div class="row" style="margin-top:14px;">
        <button type="button" id="dcInviteCancel">Hủy</button>
        <button type="button" id="dcInviteSend" class="confirm" style="background:var(--vs-orange-500);border-color:var(--vs-orange-500);">Gửi lời mời</button>
    </div>
</div>

<!-- Generic confirm (disband / leave / remove) -->
<div class="dc-confirm-backdrop" id="dcConfirmBackdrop"></div>
<div class="dc-confirm" id="dcConfirmDialog" style="display:none;" role="dialog" aria-modal="true">
    <p id="dcConfirmTitle" style="font-weight:700;font-size:14.5px;margin:0;">Xác nhận</p>
    <p id="dcConfirmMsg">Bạn có chắc chắn?</p>
    <div class="row">
        <button type="button" id="dcConfirmCancel">Hủy</button>
        <button type="button" id="dcConfirmOk" class="confirm">Xác nhận</button>
    </div>
</div>

<div id="dcToast" class="dc-toast" role="status" aria-live="polite"></div>

<jsp:include page="/customer/common/bottom-nav.jsp" />

<script>
(function () {
    'use strict';
    var CTX = "${ctx}";
    var FALLBACK_AVATAR = "${fallbackAvatar}";
    var TEAM_ID = ${team.teamId};
    var SPORT_ID = ${team.sportId};
    var IS_CAPTAIN = ${team.captain};
    var IS_CO_CAPTAIN = ${team.coCaptain};

    var toastTimer = null;
    function toast(msg, kind) {
        var el = document.getElementById('dcToast');
        el.className = 'dc-toast is-open' + (kind === 'danger' ? ' is-danger' : kind === 'success' ? ' is-success' : '');
        el.textContent = msg;
        clearTimeout(toastTimer);
        toastTimer = setTimeout(function () { el.classList.remove('is-open'); }, 3200);
    }
    function esc(s) { return (s == null ? '' : String(s)).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
    function avatarSrc(p) { return p ? p : FALLBACK_AVATAR; }
    function post(url, params) {
        var form = new FormData();
        Object.keys(params).forEach(function (k) { form.append(k, params[k]); });
        return fetch(url, { method: 'POST', body: form, headers: { 'Accept': 'application/json' } }).then(function (r) { return r.json(); });
    }

    // ================= Generic confirm dialog =================
    var confirmBackdrop = document.getElementById('dcConfirmBackdrop');
    var confirmDialog = document.getElementById('dcConfirmDialog');
    var confirmAction = null;
    function openConfirm(title, msg, onConfirm) {
        document.getElementById('dcConfirmTitle').textContent = title;
        document.getElementById('dcConfirmMsg').textContent = msg;
        confirmAction = onConfirm;
        confirmBackdrop.classList.add('is-open'); confirmDialog.style.display = 'block';
    }
    function closeConfirm() { confirmBackdrop.classList.remove('is-open'); confirmDialog.style.display = 'none'; confirmAction = null; }
    document.getElementById('dcConfirmCancel').addEventListener('click', closeConfirm);
    confirmBackdrop.addEventListener('click', closeConfirm);
    document.getElementById('dcConfirmOk').addEventListener('click', function () { if (confirmAction) confirmAction(); closeConfirm(); });

    // ================= Join =================
    var joinBtn = document.getElementById('dcJoinBtn');
    if (joinBtn) {
        joinBtn.addEventListener('click', function () {
            if (joinBtn.disabled) return;
            joinBtn.disabled = true; joinBtn.textContent = 'Đang gửi...';
            post(CTX + '/customer/doi-nhom/xin-tham-gia', { teamId: TEAM_ID }).then(function (data) {
                toast(data.message, data.success ? 'success' : 'danger');
                if (data.success) joinBtn.textContent = 'Đã gửi yêu cầu'; else { joinBtn.disabled = false; joinBtn.textContent = 'Xin tham gia'; }
            }).catch(function () { toast('Không thể gửi yêu cầu.', 'danger'); joinBtn.disabled = false; joinBtn.textContent = 'Xin tham gia'; });
        });
    }

    // ================= Leave =================
    var leaveBtn = document.getElementById('dcLeaveBtn');
    if (leaveBtn) {
        leaveBtn.addEventListener('click', function () {
            openConfirm('Rời đội?', 'Bạn sẽ không còn là thành viên của đội này.', function () {
                post(CTX + '/customer/doi-nhom/roi-doi', { teamId: TEAM_ID }).then(function (data) {
                    toast(data.message, data.success ? 'success' : 'danger');
                    if (data.success) setTimeout(function () { window.location.href = CTX + '/customer/doi-nhom'; }, 500);
                });
            });
        });
    }

    // ================= Disband =================
    var disbandBtn = document.getElementById('dcDisbandBtn');
    if (disbandBtn) {
        disbandBtn.addEventListener('click', function () {
            openConfirm('Giải tán đội?', 'Hành động này không thể hoàn tác. Toàn bộ thành viên, lời mời và yêu cầu đang chờ sẽ bị đóng.', function () {
                post(CTX + '/customer/doi-nhom/giai-tan', { teamId: TEAM_ID }).then(function (data) {
                    toast(data.message, data.success ? 'success' : 'danger');
                    if (data.success) setTimeout(function () { window.location.href = CTX + '/customer/doi-nhom'; }, 500);
                });
            });
        });
    }

    // ================= Members: remove / transfer =================
    document.querySelectorAll('[data-remove-member]').forEach(function (btn) {
        btn.addEventListener('click', function () {
            var accountId = btn.getAttribute('data-remove-member');
            var row = btn.closest('.dc-member-row');
            var name = row.querySelector('.dc-member-name').textContent;
            openConfirm('Xóa thành viên?', 'Xóa "' + name + '" khỏi đội?', function () {
                post(CTX + '/customer/doi-nhom/xoa-thanh-vien', { teamId: TEAM_ID, accountId: accountId }).then(function (data) {
                    toast(data.message, data.success ? 'success' : 'danger');
                    if (data.success) row.remove();
                });
            });
        });
    });
    document.querySelectorAll('[data-transfer-captain]').forEach(function (btn) {
        btn.addEventListener('click', function () {
            var accountId = btn.getAttribute('data-transfer-captain');
            var row = btn.closest('.dc-member-row');
            var name = row.querySelector('.dc-member-name').textContent;
            openConfirm('Chuyển quyền đội trưởng?', 'Chuyển quyền đội trưởng cho "' + name + '"? Bạn sẽ trở thành thành viên thường.', function () {
                post(CTX + '/customer/doi-nhom/chuyen-quyen', { teamId: TEAM_ID, accountId: accountId }).then(function (data) {
                    toast(data.message, data.success ? 'success' : 'danger');
                    if (data.success) setTimeout(function () { window.location.reload(); }, 500);
                });
            });
        });
    });

    // ================= Join requests =================
    document.querySelectorAll('[data-approve-jr]').forEach(function (btn) {
        btn.addEventListener('click', function () {
            var id = btn.getAttribute('data-approve-jr');
            var card = btn.closest('.dc-request-card');
            card.querySelectorAll('button').forEach(function (b) { b.disabled = true; });
            post(CTX + '/customer/doi-nhom/duyet-tham-gia', { joinRequestId: id }).then(function (data) {
                toast(data.message, data.success ? 'success' : 'danger');
                if (data.success) setTimeout(function () { window.location.reload(); }, 500);
                else card.querySelectorAll('button').forEach(function (b) { b.disabled = false; });
            });
        });
    });
    document.querySelectorAll('[data-reject-jr]').forEach(function (btn) {
        btn.addEventListener('click', function () {
            var id = btn.getAttribute('data-reject-jr');
            var card = btn.closest('.dc-request-card');
            card.querySelectorAll('button').forEach(function (b) { b.disabled = true; });
            post(CTX + '/customer/doi-nhom/tu-choi-tham-gia', { joinRequestId: id }).then(function (data) {
                toast(data.message, data.success ? 'success' : 'danger');
                if (data.success) card.remove(); else card.querySelectorAll('button').forEach(function (b) { b.disabled = false; });
            });
        });
    });

    // ================= Invite member =================
    var inviteBtn = document.getElementById('dcInviteBtn');
    var inviteBackdrop = document.getElementById('dcInviteBackdrop');
    var inviteDialog = document.getElementById('dcInviteDialog');
    if (inviteBtn) {
        inviteBtn.addEventListener('click', function () {
            document.getElementById('dcInviteUsername').value = '';
            inviteBackdrop.classList.add('is-open'); inviteDialog.style.display = 'block';
        });
    }
    function closeInvite() { inviteBackdrop.classList.remove('is-open'); inviteDialog.style.display = 'none'; }
    document.getElementById('dcInviteCancel').addEventListener('click', closeInvite);
    inviteBackdrop.addEventListener('click', closeInvite);
    document.getElementById('dcInviteSend').addEventListener('click', function () {
        var username = document.getElementById('dcInviteUsername').value.trim();
        if (!username) { toast('Vui lòng nhập email.', 'danger'); return; }
        post(CTX + '/customer/doi-nhom/moi-thanh-vien', { teamId: TEAM_ID, email: username }).then(function (data) {
            toast(data.message, data.success ? 'success' : 'danger');
            if (data.success) closeInvite();
        });
    });

    // ================= Team match panel =================
    var matchPanel = document.getElementById('dcMatchPanel');
    var openMatchPanelBtn = document.getElementById('dcOpenMatchPanel');
    var bookingsLoaded = false;
    function loadBookings() {
        if (bookingsLoaded) return;
        bookingsLoaded = true;
        fetch(CTX + '/customer/api/team-matches/eligible-bookings', { headers: { 'Accept': 'application/json' } })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                var sel = document.getElementById('dcBookingSelect');
                var bookings = (data && data.bookings) || [];
                if (!bookings.length) { sel.innerHTML = '<option value="">Bạn chưa có ca đặt sân phù hợp</option>'; return; }
                sel.innerHTML = bookings.map(function (b) {
                    return '<option value="' + b.datSanId + '" data-sport="' + (b.monTheThaoId || '') + '">' +
                        esc(b.tenCoSo) + ' - ' + esc(b.tenSan) + ' (' + b.ngayDat + ' ' + b.gioBatDau + '-' + b.gioKetThuc + ')</option>';
                }).join('');
            })
            .catch(function () { document.getElementById('dcBookingSelect').innerHTML = '<option value="">Không thể tải danh sách</option>'; });
    }
    if (openMatchPanelBtn) {
        openMatchPanelBtn.addEventListener('click', function () {
            matchPanel.classList.toggle('is-open');
            if (matchPanel.classList.contains('is-open')) loadBookings();
        });
    }
    if (window.location.hash === '#tao-keo' && matchPanel) { matchPanel.classList.add('is-open'); loadBookings(); }

    var submitMatchBtn = document.getElementById('dcSubmitMatch');
    if (submitMatchBtn) {
        submitMatchBtn.addEventListener('click', function () {
            var datSanId = document.getElementById('dcBookingSelect').value;
            if (!datSanId) { toast('Vui lòng chọn một ca đặt sân.', 'danger'); return; }
            submitMatchBtn.disabled = true; submitMatchBtn.textContent = 'Đang tạo...';
            post(CTX + '/customer/doi-nhom/tao-keo', {
                teamId: TEAM_ID, datSanId: datSanId, monTheThaoId: SPORT_ID,
                trinhDo: document.getElementById('dcTrinhDo').value, note: document.getElementById('dcNote').value
            }).then(function (data) {
                toast(data.message, data.success ? 'success' : 'danger');
                submitMatchBtn.disabled = false; submitMatchBtn.textContent = 'Tạo kèo';
                if (data.success) { matchPanel.classList.remove('is-open'); loadMyMatches(); }
            }).catch(function () { toast('Không thể tạo kèo.', 'danger'); submitMatchBtn.disabled = false; submitMatchBtn.textContent = 'Tạo kèo'; });
        });
    }

    function statusClass(s) {
        if (s === 'Đang mở') return 'open';
        if (s === 'Đã đủ người') return 'full';
        return 'cancelled';
    }

    function renderMatchCard(m, isMine) {
        var div = document.createElement('div');
        div.className = 'dc-match-card';
        var opponent = m.opponentTeamName ? ('Đối thủ: ' + esc(m.opponentTeamName)) : (m.pendingChallengeCount > 0 ? m.pendingChallengeCount + ' thách đấu đang chờ' : 'Chưa có đội thách đấu');
        div.innerHTML =
            '<div class="dc-match-top">' +
                '<div><div class="dc-match-title">' + esc(m.tenCoSo) + ' - ' + esc(m.tenSan) + '</div>' +
                '<div class="dc-match-sub">' + esc(m.ngayDat) + ' &middot; ' + esc(m.gioBatDau) + '-' + esc(m.gioKetThuc) + (m.tenMon ? ' &middot; ' + esc(m.tenMon) : '') + '</div>' +
                (!isMine ? '<div class="dc-match-sub">Đội: ' + esc(m.teamNameNguoiTao) + '</div>' : '') + '</div>' +
                '<span class="dc-status-pill ' + statusClass(m.trangThai) + '">' + esc(m.trangThai) + '</span>' +
            '</div>' +
            '<div class="dc-match-sub" style="margin-top:6px;">' + opponent + '</div>';

        if (isMine && (IS_CAPTAIN || IS_CO_CAPTAIN) && m.pendingChallengeCount > 0 && m.trangThai === 'Đang mở') {
            var challengesWrap = document.createElement('div');
            challengesWrap.className = 'dc-challenges';
            div.appendChild(challengesWrap);
            fetch(CTX + '/customer/api/team-matches/challenges?keoId=' + m.keoId, { headers: { 'Accept': 'application/json' } })
                .then(function (r) { return r.json(); })
                .then(function (challenges) {
                    (challenges || []).forEach(function (c) {
                        var row = document.createElement('div');
                        row.className = 'dc-challenge-row';
                        row.innerHTML = '<img src="' + esc(avatarSrc(c.challengerTeamAvatarPath)) + '" alt="" onerror="this.onerror=null;this.src=\'' + FALLBACK_AVATAR + '\';"/>' +
                            '<span class="name">' + esc(c.challengerTeamName) + '</span>' +
                            '<button type="button" class="dc-mini-btn" style="border-color:var(--vs-success);color:var(--vs-success);" data-accept-ch="' + c.chiTietKeoId + '" data-keo="' + m.keoId + '">Chấp nhận</button>' +
                            '<button type="button" class="dc-mini-btn danger" data-reject-ch="' + c.chiTietKeoId + '" data-keo="' + m.keoId + '">Từ chối</button>';
                        challengesWrap.appendChild(row);
                    });
                    challengesWrap.querySelectorAll('[data-accept-ch]').forEach(function (btn) {
                        btn.addEventListener('click', function () {
                            post(CTX + '/customer/doi-nhom/chap-nhan-thach-dau', { chiTietKeoId: btn.getAttribute('data-accept-ch'), keoId: btn.getAttribute('data-keo') })
                                .then(function (data) { toast(data.message, data.success ? 'success' : 'danger'); if (data.success) { loadMyMatches(); } });
                        });
                    });
                    challengesWrap.querySelectorAll('[data-reject-ch]').forEach(function (btn) {
                        btn.addEventListener('click', function () {
                            post(CTX + '/customer/doi-nhom/tu-choi-thach-dau', { chiTietKeoId: btn.getAttribute('data-reject-ch'), keoId: btn.getAttribute('data-keo') })
                                .then(function (data) { toast(data.message, data.success ? 'success' : 'danger'); if (data.success) { btn.closest('.dc-challenge-row').remove(); } });
                        });
                    });
                });
        }
        return div;
    }

    function loadMyMatches() {
        var wrap = document.getElementById('dcMyMatches');
        var empty = document.getElementById('dcMyMatchesEmpty');
        if (!wrap) return;
        fetch(CTX + '/customer/api/team-matches/mine?teamId=' + TEAM_ID, { headers: { 'Accept': 'application/json' } })
            .then(function (r) { return r.json(); })
            .then(function (list) {
                wrap.innerHTML = '';
                if (!list || !list.length) { empty.style.display = 'block'; return; }
                empty.style.display = 'none';
                list.forEach(function (m) { wrap.appendChild(renderMatchCard(m, true)); });
            });
    }

    function loadOpenMatches() {
        var wrap = document.getElementById('dcOpenMatches');
        var empty = document.getElementById('dcOpenMatchesEmpty');
        fetch(CTX + '/customer/api/team-matches?sportId=' + SPORT_ID + '&excludeTeamId=' + TEAM_ID, { headers: { 'Accept': 'application/json' } })
            .then(function (r) { return r.json(); })
            .then(function (list) {
                wrap.innerHTML = '';
                if (!list || !list.length) { empty.style.display = 'block'; return; }
                empty.style.display = 'none';
                list.forEach(function (m) {
                    var card = renderMatchCard(m, false);
                    if (IS_CAPTAIN || IS_CO_CAPTAIN) {
                        var btn = document.createElement('button');
                        btn.type = 'button'; btn.className = 'dc-btn primary'; btn.style.marginTop = '8px'; btn.style.width = '100%'; btn.style.justifyContent = 'center';
                        btn.textContent = 'Thách đấu';
                        btn.addEventListener('click', function () {
                            btn.disabled = true; btn.textContent = 'Đang gửi...';
                            post(CTX + '/customer/doi-nhom/thach-dau', { keoId: m.keoId, challengerTeamId: TEAM_ID }).then(function (data) {
                                toast(data.message, data.success ? 'success' : 'danger');
                                if (!data.success) { btn.disabled = false; btn.textContent = 'Thách đấu'; }
                            });
                        });
                        card.appendChild(btn);
                    }
                    wrap.appendChild(card);
                });
            });
    }

    loadMyMatches();
    loadOpenMatches();
})();
</script>
</body>
</html>
