<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <title><c:choose><c:when test="${editMode}">Chỉnh sửa đội</c:when><c:otherwise>Tạo đội mới</c:otherwise></c:choose> - V-SPORT</title>
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

        .dt-appbar { position: sticky; top: 0; z-index: 50; height: 52px; display: flex; align-items: center; justify-content: center; background: var(--vs-primary-900); color: #fff; }
        .dt-back { position: absolute; left: 8px; top: 50%; transform: translateY(-50%); width: 40px; height: 40px; border-radius: 50%; border: none; background: transparent; color: #fff; display: flex; align-items: center; justify-content: center; cursor: pointer; }
        .dt-back:hover { background: rgba(255,255,255,.12); }
        .dt-appbar h1 { font-size: 16px; font-weight: 700; margin: 0; }

        .dt-wrap { max-width: 640px; margin: 0 auto; padding: 28px 16px calc(var(--vs-bottomnav-h) + 40px); }
        @media (min-width: 1024px) { .dt-wrap { padding-bottom: calc(var(--vs-bottomnav-h-desktop) + 40px); } }

        .dt-avatar-uploader { display: flex; justify-content: center; margin-bottom: 22px; }
        .dt-avatar-btn { position: relative; width: 72px; height: 72px; border-radius: 50%; border: 2px solid var(--vs-cyan-500); background: var(--vs-cyan-50); cursor: pointer; display: flex; align-items: center; justify-content: center; overflow: visible; padding: 0; }
        .dt-avatar-btn img { width: 100%; height: 100%; border-radius: 50%; object-fit: cover; display: none; }
        .dt-avatar-btn.has-image img { display: block; }
        .dt-avatar-btn.has-image svg.dt-avatar-placeholder { display: none; }
        .dt-avatar-placeholder { width: 28px; height: 28px; color: var(--vs-primary-600); }
        .dt-avatar-cam { position: absolute; right: -2px; bottom: -2px; width: 26px; height: 26px; border-radius: 50%; background: var(--vs-orange-500); color: #fff; display: flex; align-items: center; justify-content: center; border: 2px solid #fff; }
        .dt-avatar-cam svg { width: 13px; height: 13px; }

        .dt-card { background: var(--vs-card); border: 1px solid var(--vs-border); border-radius: var(--vs-r-card); padding: 22px 20px; }
        .dt-card h2 { font-size: 16px; font-weight: 700; margin: 0 0 18px; color: var(--vs-text); }
        .dt-field { margin-bottom: 20px; }
        .dt-field:last-child { margin-bottom: 0; }
        .dt-label { display: flex; align-items: baseline; justify-content: space-between; font-size: 13.5px; font-weight: 700; color: var(--vs-text); margin-bottom: 7px; }
        .dt-label .req { color: var(--vs-danger); }
        .dt-counter { font-size: 11.5px; font-weight: 600; color: var(--vs-muted); }
        .dt-input, .dt-select, .dt-textarea {
            width: 100%; padding: 11px 13px; border-radius: var(--vs-r-btn); border: 1px solid var(--vs-border);
            font-size: 14px; color: var(--vs-text); background: #fff; font-family: inherit;
        }
        .dt-input:focus, .dt-select:focus, .dt-textarea:focus { border-color: var(--vs-cyan-500); }
        .dt-textarea { resize: vertical; min-height: 76px; line-height: 1.5; }
        .dt-help { font-size: 12px; color: var(--vs-text-secondary); margin-top: 6px; }
        .dt-error { font-size: 12px; color: var(--vs-danger); margin-top: 6px; display: none; }
        .dt-error.is-visible { display: block; }
        .dt-field.has-error .dt-input, .dt-field.has-error .dt-select, .dt-field.has-error .dt-textarea { border-color: var(--vs-danger); }

        .dt-cover-upload {
            border: 1.5px dashed var(--vs-border); border-radius: var(--vs-r-card); background: var(--vs-surface-soft);
            height: 116px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 8px;
            cursor: pointer; color: var(--vs-text-secondary); text-align: center; position: relative; overflow: hidden;
        }
        .dt-cover-upload svg { width: 26px; height: 26px; color: var(--vs-muted); }
        .dt-cover-upload span { font-size: 13px; font-weight: 600; }
        .dt-cover-upload img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; display: none; }
        .dt-cover-upload.has-image img { display: block; }
        .dt-cover-upload.has-image svg, .dt-cover-upload.has-image span.dt-cover-hint { display: none; }
        .dt-cover-actions { display: none; gap: 8px; margin-top: 8px; }
        .dt-cover-actions.is-visible { display: flex; }
        .dt-cover-actions button { flex: 1; padding: 8px; border-radius: var(--vs-r-btn); border: 1px solid var(--vs-border); background: #fff; font-size: 12.5px; font-weight: 600; cursor: pointer; }
        .dt-cover-actions button:hover { border-color: var(--vs-cyan-500); }

        .dt-submit {
            width: 100%; margin-top: 22px; padding: 14px; border-radius: var(--vs-r-btn); border: none; cursor: pointer;
            background: var(--vs-orange-500); color: #fff; font-size: 15px; font-weight: 700;
            display: flex; align-items: center; justify-content: center; gap: 8px;
            transition: background-color .15s ease, opacity .15s ease;
        }
        .dt-submit:hover { background: var(--vs-orange-600); }
        .dt-submit:disabled { opacity: .65; cursor: not-allowed; }
        .dt-spinner { width: 16px; height: 16px; border-radius: 50%; border: 2px solid rgba(255,255,255,.4); border-top-color: #fff; animation: dtspin .8s linear infinite; display: none; }
        .dt-submit.is-loading .dt-spinner { display: inline-block; }
        @keyframes dtspin { to { transform: rotate(360deg); } }

        .dt-toast {
            position: fixed; left: 50%; bottom: calc(var(--vs-bottomnav-h, 70px) + 18px);
            transform: translateX(-50%) translateY(12px); z-index: 1300;
            background: var(--vs-primary-900); color: #fff; padding: 10px 18px; border-radius: 9999px;
            font-size: 13px; font-weight: 600; opacity: 0; visibility: hidden;
            transition: opacity .2s ease, transform .2s ease; box-shadow: 0 8px 22px rgba(7,29,56,.3);
            max-width: 88vw; text-align: center;
        }
        .dt-toast.is-open { opacity: 1; visibility: visible; transform: translateX(-50%) translateY(0); }
        .dt-toast.is-danger { background: var(--vs-danger); }
        .dt-toast.is-success { background: var(--vs-success); }
    </style>
</head>
<body>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<header class="dt-appbar">
    <button type="button" class="dt-back" onclick="history.length > 1 ? history.back() : (window.location.href='${ctx}/customer/doi-nhom')" aria-label="Quay lại">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
    </button>
    <h1><c:choose><c:when test="${editMode}">Chỉnh sửa đội</c:when><c:otherwise>Tạo đội mới</c:otherwise></c:choose></h1>
</header>

<div class="dt-wrap">
    <form id="dtForm" novalidate>
        <c:if test="${editMode}"><input type="hidden" name="teamId" value="${team.teamId}"/></c:if>

        <div class="dt-avatar-uploader">
            <button type="button" class="dt-avatar-btn<c:if test="${editMode && not empty team.avatarPath}"> has-image</c:if>" id="dtAvatarBtn" aria-label="Chọn ảnh đại diện đội">
                <svg class="dt-avatar-placeholder" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="18" height="18" x="3" y="3" rx="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/></svg>
                <img id="dtAvatarPreview" src="<c:if test="${editMode}">${team.avatarPath}</c:if>" alt=""/>
                <span class="dt-avatar-cam" aria-hidden="true">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/></svg>
                </span>
            </button>
            <input type="file" id="dtAvatarFile" name="avatarFile" accept="image/jpeg,image/png,image/webp,image/gif" hidden/>
        </div>

        <div class="dt-card">
            <h2>Thông tin đội</h2>

            <div class="dt-field" id="fTeamName">
                <label class="dt-label" for="dtTeamName">Tên đội <span class="req">*</span><span class="dt-counter" id="dtTeamNameCounter">0/50</span></label>
                <input class="dt-input" type="text" id="dtTeamName" name="teamName" maxlength="50" placeholder="Tên đội" value="${editMode ? team.teamName : ''}" required/>
                <p class="dt-error" id="eTeamName">Tên đội phải có 3-50 ký tự.</p>
            </div>

            <div class="dt-field">
                <label class="dt-label">Hình ảnh bìa trước</label>
                <div class="dt-cover-upload<c:if test="${editMode && not empty team.coverImagePath}"> has-image</c:if>" id="dtCoverUpload">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/></svg>
                    <span class="dt-cover-hint">Nhấn để chọn ảnh từ thư viện</span>
                    <img id="dtCoverPreview" src="<c:if test="${editMode}">${team.coverImagePath}</c:if>" alt=""/>
                </div>
                <input type="file" id="dtCoverFile" name="coverFile" accept="image/jpeg,image/png,image/webp,image/gif" hidden/>
                <div class="dt-cover-actions<c:if test="${editMode && not empty team.coverImagePath}"> is-visible</c:if>" id="dtCoverActions">
                    <button type="button" id="dtCoverChange">Thay ảnh</button>
                    <button type="button" id="dtCoverRemove">Xóa ảnh</button>
                </div>
            </div>

            <div class="dt-field" id="fLocation">
                <label class="dt-label" for="dtLocation">Khu vực</label>
                <input class="dt-input" type="text" id="dtLocation" name="locationText" maxlength="255" placeholder="Số nhà, đường, phường/xã, tỉnh/thành" value="${editMode ? team.locationText : ''}"/>
            </div>

            <div class="dt-field">
                <label class="dt-label" for="dtDescription">Mô tả đội<span class="dt-counter" id="dtDescCounter">0/225</span></label>
                <textarea class="dt-textarea" id="dtDescription" name="description" maxlength="225" placeholder="Mô tả về đội của bạn"><c:if test="${editMode}">${team.description}</c:if></textarea>
            </div>

            <div class="dt-field" id="fSport">
                <label class="dt-label" for="dtSport">Loại thể thao <span class="req">*</span></label>
                <select class="dt-select" id="dtSport" name="sportId" required>
                    <option value="" disabled ${editMode ? '' : 'selected'}>Chọn loại thể thao</option>
                    <c:forEach var="mon" items="${dsMon}">
                        <option value="${mon.monTheThaoID}" <c:if test="${editMode && team.sportId == mon.monTheThaoID}">selected</c:if>>${mon.tenMon}</option>
                    </c:forEach>
                </select>
                <p class="dt-error" id="eSport">Vui lòng chọn loại thể thao.</p>
            </div>

            <div class="dt-field" id="fMaxMembers">
                <label class="dt-label" for="dtMaxMembers">Số thành viên tối đa <span class="req">*</span></label>
                <input class="dt-input" type="number" id="dtMaxMembers" name="maxMembers" min="2" max="30" step="1"
                       placeholder="Nhập số thành viên tối đa" value="${editMode ? team.maxMembers : ''}" required/>
                <p class="dt-help">Xin lưu ý: Số lượng thành viên tối đa có thể từ 2 đến 30 người.</p>
                <p class="dt-error" id="eMaxMembers">Số thành viên tối đa phải từ 2 đến 30.</p>
            </div>
        </div>

        <button type="submit" class="dt-submit" id="dtSubmit">
            <span class="dt-spinner" aria-hidden="true"></span>
            <span id="dtSubmitLabel"><c:choose><c:when test="${editMode}">Lưu thay đổi</c:when><c:otherwise>Tạo đội</c:otherwise></c:choose></span>
        </button>
    </form>
</div>

<div id="dtToast" class="dt-toast" role="status" aria-live="polite"></div>

<jsp:include page="/customer/common/bottom-nav.jsp" />

<script>
(function () {
    'use strict';
    var CTX = "${ctx}";
    var EDIT_MODE = ${editMode ? 'true' : 'false'};
    var TEAM_ID = EDIT_MODE ? ${editMode ? team.teamId : 0} : null;

    var toastTimer = null;
    function toast(msg, kind) {
        var el = document.getElementById('dtToast');
        el.className = 'dt-toast is-open' + (kind === 'danger' ? ' is-danger' : kind === 'success' ? ' is-success' : '');
        el.textContent = msg;
        clearTimeout(toastTimer);
        toastTimer = setTimeout(function () { el.classList.remove('is-open'); }, 3200);
    }

    // ================= Counters =================
    function bindCounter(inputId, counterId, max) {
        var el = document.getElementById(inputId);
        var counter = document.getElementById(counterId);
        function update() { counter.textContent = el.value.length + '/' + max; }
        el.addEventListener('input', update);
        update();
    }
    bindCounter('dtTeamName', 'dtTeamNameCounter', 50);
    bindCounter('dtDescription', 'dtDescCounter', 225);

    // ================= Avatar =================
    var avatarBtn = document.getElementById('dtAvatarBtn');
    var avatarFile = document.getElementById('dtAvatarFile');
    var avatarPreview = document.getElementById('dtAvatarPreview');
    avatarBtn.addEventListener('click', function () { avatarFile.click(); });
    avatarFile.addEventListener('change', function () {
        var f = avatarFile.files[0];
        if (!f) return;
        if (f.size > 5 * 1024 * 1024) { toast('Ảnh đại diện tối đa 5MB.', 'danger'); avatarFile.value = ''; return; }
        avatarPreview.src = URL.createObjectURL(f);
        avatarBtn.classList.add('has-image');
    });

    // ================= Cover =================
    var coverUpload = document.getElementById('dtCoverUpload');
    var coverFile = document.getElementById('dtCoverFile');
    var coverPreview = document.getElementById('dtCoverPreview');
    var coverActions = document.getElementById('dtCoverActions');
    function openCoverPicker() { coverFile.click(); }
    coverUpload.addEventListener('click', openCoverPicker);
    document.getElementById('dtCoverChange').addEventListener('click', function (e) { e.stopPropagation(); openCoverPicker(); });
    document.getElementById('dtCoverRemove').addEventListener('click', function (e) {
        e.stopPropagation();
        coverFile.value = ''; coverPreview.src = '';
        coverUpload.classList.remove('has-image'); coverActions.classList.remove('is-visible');
    });
    coverFile.addEventListener('change', function () {
        var f = coverFile.files[0];
        if (!f) return;
        if (f.size > 8 * 1024 * 1024) { toast('Ảnh bìa tối đa 8MB.', 'danger'); coverFile.value = ''; return; }
        coverPreview.src = URL.createObjectURL(f);
        coverUpload.classList.add('has-image');
        coverActions.classList.add('is-visible');
    });

    // ================= Validation =================
    function setError(fieldId, errorId, show) {
        document.getElementById(fieldId).classList.toggle('has-error', show);
        document.getElementById(errorId).classList.toggle('is-visible', show);
    }
    function validate() {
        var ok = true;
        var name = document.getElementById('dtTeamName').value.trim();
        if (name.length < 3 || name.length > 50) { setError('fTeamName', 'eTeamName', true); ok = false; } else setError('fTeamName', 'eTeamName', false);

        var sport = document.getElementById('dtSport').value;
        if (!sport) { setError('fSport', 'eSport', true); ok = false; } else setError('fSport', 'eSport', false);

        var max = parseInt(document.getElementById('dtMaxMembers').value, 10);
        if (!max || max < 2 || max > 30) { setError('fMaxMembers', 'eMaxMembers', true); ok = false; } else setError('fMaxMembers', 'eMaxMembers', false);

        return ok;
    }

    // ================= Submit =================
    var form = document.getElementById('dtForm');
    var submitBtn = document.getElementById('dtSubmit');
    var submitLabel = document.getElementById('dtSubmitLabel');
    var submitting = false;

    form.addEventListener('submit', function (e) {
        e.preventDefault();
        if (submitting) return;
        if (!validate()) { toast('Vui lòng kiểm tra lại các trường bắt buộc.', 'danger'); return; }

        submitting = true;
        submitBtn.disabled = true;
        submitBtn.classList.add('is-loading');
        submitLabel.textContent = EDIT_MODE ? 'Đang lưu...' : 'Đang tạo đội...';

        var formData = new FormData(form);
        var url = CTX + (EDIT_MODE ? '/customer/doi-nhom/chinh-sua' : '/customer/doi-nhom/tao');

        fetch(url, { method: 'POST', body: formData, headers: { 'Accept': 'application/json' } })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (data.success) {
                    toast(data.message || 'Thành công.', 'success');
                    var targetId = data.teamId || TEAM_ID;
                    setTimeout(function () { window.location.href = CTX + '/customer/doi-nhom/chi-tiet?id=' + targetId; }, 500);
                } else {
                    toast(data.message || 'Có lỗi xảy ra.', 'danger');
                    submitting = false;
                    submitBtn.disabled = false;
                    submitBtn.classList.remove('is-loading');
                    submitLabel.textContent = EDIT_MODE ? 'Lưu thay đổi' : 'Tạo đội';
                }
            })
            .catch(function () {
                toast('Không thể kết nối máy chủ. Vui lòng thử lại.', 'danger');
                submitting = false;
                submitBtn.disabled = false;
                submitBtn.classList.remove('is-loading');
                submitLabel.textContent = EDIT_MODE ? 'Lưu thay đổi' : 'Tạo đội';
            });
    });
})();
</script>
</body>
</html>
