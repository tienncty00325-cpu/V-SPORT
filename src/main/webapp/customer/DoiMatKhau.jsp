<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>Đổi mật khẩu - V-SPORT</title>
    <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        /* ===== Full-bleed change-password page (V-SPORT navy/cyan) ===== */
        :root {
            --cp-bg: #0B2D4D;
            --cp-bg-2: #0A3F63;
            --cp-bg-3: #0E7490;
            --cp-text: #FFFFFF;
            --cp-input-text: #0B2D4D;
            --cp-eye: #0A3F63;
            --cp-error: #FFE7A3;
            --cp-save: #E8B327;
        }

        * { box-sizing: border-box; }

        html, body { margin: 0; padding: 0; width: 100%; }

        .customer-change-password-page {
            min-height: 100vh;
            min-height: 100dvh;
            background: linear-gradient(180deg, var(--cp-bg) 0%, var(--cp-bg-2) 45%, var(--cp-bg-3) 100%);
            background-attachment: fixed;
            color: var(--cp-text);
            font-family: 'Be Vietnam Pro', 'Inter', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            display: flex;
            flex-direction: column;
            -webkit-font-smoothing: antialiased;
            -webkit-tap-highlight-color: transparent;
        }

        /* ===== Header ===== */
        .change-password-header {
            position: sticky;
            top: 0;
            z-index: 10;
            height: 64px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: var(--cp-bg);
            padding-top: env(safe-area-inset-top, 0px);
        }
        .change-password-back {
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            width: 42px;
            height: 42px;
            border: none;
            border-radius: 999px;
            background: transparent;
            color: var(--cp-text);
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
        }
        .change-password-back svg { width: 26px; height: 26px; }
        .change-password-title {
            margin: 0;
            font-size: 20px;
            font-weight: 700;
            line-height: 1;
            color: var(--cp-text);
        }

        /* ===== Form (full width, không card / không centered) ===== */
        .change-password-form {
            flex: 1;
            padding: 18px 8px calc(72px + env(safe-area-inset-bottom, 0px));
        }
        .password-field { margin-bottom: 18px; }
        .password-label {
            display: block;
            margin-bottom: 10px;
            color: var(--cp-text);
            font-size: 16px;
            font-weight: 500;
        }
        .password-input-wrap { position: relative; width: 100%; }
        .password-input {
            width: 100%;
            height: 48px;
            border: none;
            border-radius: 6px;
            background: #fff;
            color: var(--cp-input-text);
            font-size: 15px;
            font-weight: 500;
            padding: 0 48px 0 16px;
            outline: none;
        }
        .password-input:focus { box-shadow: 0 0 0 3px rgba(34, 211, 238, 0.35); }
        .password-eye {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
            border: none;
            background: transparent;
            color: var(--cp-eye);
            width: 34px;
            height: 34px;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            padding: 0;
        }
        .password-eye svg { width: 20px; height: 20px; }
        .password-eye .eye-open { display: none; }
        .password-eye.is-visible .eye-open { display: block; }
        .password-eye.is-visible .eye-closed { display: none; }

        .password-error {
            display: none;
            margin-top: 7px;
            color: var(--cp-error);
            font-size: 13px;
            line-height: 1.35;
        }
        .password-error.show { display: block; }

        /* ===== Fixed bottom save bar ===== */
        .change-password-submit-bar {
            position: fixed;
            left: 0;
            right: 0;
            bottom: 0;
            padding: 8px 8px calc(8px + env(safe-area-inset-bottom, 0px));
            background: var(--cp-bg);
            z-index: 20;
        }
        .change-password-submit {
            width: 100%;
            height: 48px;
            border: none;
            border-radius: 6px;
            background: var(--cp-save);
            color: #fff;
            font-size: 15px;
            font-weight: 800;
            letter-spacing: 0.4px;
            cursor: pointer;
            transition: transform 120ms ease, filter 120ms ease, opacity 120ms ease;
        }
        .change-password-submit:active {
            transform: translateY(2px) scale(0.995);
            filter: brightness(0.95);
        }
        .change-password-submit:disabled {
            opacity: 0.55;
            cursor: not-allowed;
        }
    </style>
</head>
<body>
<div class="customer-change-password-page">
    <header class="change-password-header">
        <button type="button" class="change-password-back" onclick="goBack()" aria-label="Quay lại">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
        </button>
        <h1 class="change-password-title">Thay đổi mật khẩu</h1>
    </header>

    <%-- autocomplete=off + các input rỗng: KHÔNG bao giờ autofill hay lộ mật khẩu cũ.
         Backend mới là nơi xác thực mật khẩu hiện tại bằng BCrypt. --%>
    <form class="change-password-form" id="cpForm" autocomplete="off" onsubmit="return false;">
        <div class="password-field">
            <label class="password-label" for="currentPassword">Mật khẩu hiện tại</label>
            <div class="password-input-wrap">
                <input type="password" id="currentPassword" name="currentPassword" class="password-input"
                       autocomplete="current-password" placeholder="Nhập mật khẩu hiện tại">
                <button type="button" class="password-eye" onclick="togglePw('currentPassword', this)" aria-label="Hiện/ẩn mật khẩu">
                    <svg class="eye-closed" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49"/><path d="M14.084 14.158a3 3 0 0 1-4.242-4.242"/><path d="M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143"/><path d="m2 2 20 20"/></svg>
                    <svg class="eye-open" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0"/><circle cx="12" cy="12" r="3"/></svg>
                </button>
            </div>
            <p class="password-error" data-error-for="currentPassword"></p>
        </div>

        <div class="password-field">
            <label class="password-label" for="newPassword">Mật khẩu mới</label>
            <div class="password-input-wrap">
                <input type="password" id="newPassword" name="newPassword" class="password-input"
                       autocomplete="new-password" placeholder="Nhập mật khẩu mới">
                <button type="button" class="password-eye" onclick="togglePw('newPassword', this)" aria-label="Hiện/ẩn mật khẩu">
                    <svg class="eye-closed" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49"/><path d="M14.084 14.158a3 3 0 0 1-4.242-4.242"/><path d="M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143"/><path d="m2 2 20 20"/></svg>
                    <svg class="eye-open" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0"/><circle cx="12" cy="12" r="3"/></svg>
                </button>
            </div>
            <p class="password-error" data-error-for="newPassword"></p>
        </div>

        <div class="password-field">
            <label class="password-label" for="confirmPassword">Nhập lại mật khẩu mới</label>
            <div class="password-input-wrap">
                <input type="password" id="confirmPassword" name="confirmPassword" class="password-input"
                       autocomplete="new-password" placeholder="Nhập lại mật khẩu mới">
                <button type="button" class="password-eye" onclick="togglePw('confirmPassword', this)" aria-label="Hiện/ẩn mật khẩu">
                    <svg class="eye-closed" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49"/><path d="M14.084 14.158a3 3 0 0 1-4.242-4.242"/><path d="M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143"/><path d="m2 2 20 20"/></svg>
                    <svg class="eye-open" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0"/><circle cx="12" cy="12" r="3"/></svg>
                </button>
            </div>
            <p class="password-error" data-error-for="confirmPassword"></p>
        </div>
    </form>

    <div class="change-password-submit-bar">
        <button type="button" class="change-password-submit" id="cpSubmit" onclick="submitChangePassword()" disabled>LƯU</button>
    </div>
</div>

<script>
    var CTX = '${pageContext.request.contextPath}';
    var elCurrent = document.getElementById('currentPassword');
    var elNew = document.getElementById('newPassword');
    var elConfirm = document.getElementById('confirmPassword');
    var elSubmit = document.getElementById('cpSubmit');

    // ---- Back: ưu tiên history.back(), fallback về trang Cài đặt ----
    function goBack() {
        var fallback = CTX + '/customer/tai-khoan#caidat';
        if (window.history.length > 1 && document.referrer) {
            window.history.back();
            setTimeout(function () { window.location.href = fallback; }, 400);
        } else {
            window.location.href = fallback;
        }
    }

    // ---- Show/hide mật khẩu ĐANG NHẬP (không phải mật khẩu cũ trong DB) ----
    function togglePw(id, btn) {
        var input = document.getElementById(id);
        if (input.type === 'password') { input.type = 'text'; btn.classList.add('is-visible'); }
        else { input.type = 'password'; btn.classList.remove('is-visible'); }
    }

    // ---- Enable/disable nút LƯU theo mức độ điền form ----
    function refreshSubmitState() {
        elSubmit.disabled = !(elCurrent.value && elNew.value && elConfirm.value);
    }
    [elCurrent, elNew, elConfirm].forEach(function (el) {
        el.addEventListener('input', function () {
            clearErrors();
            refreshSubmitState();
        });
    });

    function setError(field, message) {
        var el = document.querySelector('[data-error-for="' + field + '"]');
        if (el) { el.textContent = message; el.classList.add('show'); }
    }
    function clearErrors() {
        document.querySelectorAll('.password-error').forEach(function (el) {
            el.textContent = '';
            el.classList.remove('show');
        });
    }

    // ---- Validation frontend (backend vẫn kiểm tra lại, không tin frontend) ----
    function validate(current, next, confirm) {
        if (!current) { setError('currentPassword', 'Vui lòng nhập mật khẩu hiện tại.'); return false; }
        if (!next) { setError('newPassword', 'Vui lòng nhập mật khẩu mới.'); return false; }
        if (next.length < 8) { setError('newPassword', 'Mật khẩu mới phải có ít nhất 8 ký tự.'); return false; }
        if (!/[a-z]/.test(next) || !/[A-Z]/.test(next) || !/\d/.test(next) || !/[^A-Za-z0-9]/.test(next)) {
            setError('newPassword', 'Mật khẩu mới cần có chữ hoa, chữ thường, số và ký tự đặc biệt.');
            return false;
        }
        if (next === current) { setError('newPassword', 'Mật khẩu mới không được trùng mật khẩu hiện tại.'); return false; }
        if (!confirm) { setError('confirmPassword', 'Vui lòng nhập lại mật khẩu mới.'); return false; }
        if (confirm !== next) { setError('confirmPassword', 'Mật khẩu nhập lại chưa khớp.'); return false; }
        return true;
    }

    function submitChangePassword() {
        clearErrors();
        var current = elCurrent.value;
        var next = elNew.value;
        var confirm = elConfirm.value;
        if (!validate(current, next, confirm)) return;

        elSubmit.disabled = true;
        var originalText = elSubmit.textContent;
        elSubmit.textContent = 'ĐANG LƯU...';

        var params = new URLSearchParams();
        params.append('action', 'changePassword');
        params.append('currentPassword', current);
        params.append('newPassword', next);
        params.append('confirmPassword', confirm);

        fetch(CTX + '/account/update-profile', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: params
        })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (data.success) {
                    // Xóa nội dung đã nhập khỏi bộ nhớ form rồi chuyển về trang Cài đặt.
                    elCurrent.value = elNew.value = elConfirm.value = '';
                    elSubmit.textContent = 'THÀNH CÔNG';
                    try { sessionStorage.setItem('vsport_flash', 'Đổi mật khẩu thành công.'); } catch (e) { /* ignore */ }
                    window.location.href = CTX + '/customer/tai-khoan#caidat';
                } else {
                    elSubmit.disabled = false;
                    elSubmit.textContent = originalText;
                    // Lỗi mật khẩu hiện tại sai -> gắn dưới ô mật khẩu hiện tại; còn lại gắn ô mật khẩu mới.
                    var msg = data.message || 'Không thể đổi mật khẩu.';
                    if (/hiện tại/i.test(msg)) setError('currentPassword', msg);
                    else setError('newPassword', msg);
                }
            })
            .catch(function () {
                elSubmit.disabled = false;
                elSubmit.textContent = originalText;
                setError('newPassword', 'Lỗi kết nối. Vui lòng thử lại.');
            });
    }
</script>
</body>
</html>
