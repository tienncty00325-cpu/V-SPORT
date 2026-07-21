<%--
    Shared theme cho các trang auth toàn màn hình (DangNhap.jsp, DangKy.jsp).
    Chứa: font, nền sóng xanh, thanh tiêu đề, card trắng, form controls,
    nút chính, password toggle, alert lỗi/thành công và JS dùng chung.
    Include tĩnh bên trong <head>: <%@ include file="common/auth-theme.jsp" %>
--%>
<link rel="preconnect" href="https://fonts.googleapis.com"/>
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
<link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,300..600,0..1,0&display=swap" rel="stylesheet"/>
<style>
    :root {
        --vs-green-900: #071A2F;
        --vs-green-800: #0B2545;
        --vs-green-700: #123A63;
        --vs-green-600: #1677D2;
        --vs-green-500: #18C8E8;
        --vs-ink: #102A43;
        --vs-ink-soft: #486581;
        --vs-line: #DCE5EF;
        --vs-danger: #c0392b;
        --vs-danger-soft: #fdecec;
        --vs-danger-line: #f3bcb6;
        --vs-orange-600: #F97316;
        --vs-orange-500: #FF8A24;
    }

    * { box-sizing: border-box; }

    html, body { margin: 0; padding: 0; }

    body.auth-body {
        font-family: 'Be Vietnam Pro', Inter, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        min-height: 100dvh;
        width: 100%;
        overflow-x: hidden;
        color: var(--vs-ink);
        background-color: #0B2545;
        background-image: linear-gradient(168deg, #123A63 0%, #185A9D 46%, #0B2545 100%);
        -webkit-font-smoothing: antialiased;
    }

    .material-symbols-outlined {
        font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
        user-select: none;
    }

    /* ===== Nền sóng cong mềm (SVG riêng của V-SPORT, không dùng asset ngoài) ===== */
    .auth-waves {
        position: fixed;
        inset: 0;
        z-index: 0;
        pointer-events: none;
        overflow: hidden;
    }
    .auth-waves svg {
        position: absolute;
        inset: 0;
        width: 100%;
        height: 100%;
    }

    /* ===== Thanh tiêu đề trên cùng ===== */
    .auth-topbar {
        position: relative;
        z-index: 5;
        height: 60px;
        display: flex;
        align-items: center;
        padding: 0 22px;
    }
    .auth-back {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 42px;
        height: 42px;
        margin-left: -8px;
        border: none;
        border-radius: 50%;
        background: transparent;
        color: #fff;
        cursor: pointer;
        transition: background-color .15s ease;
        text-decoration: none;
    }
    .auth-back:hover { background: rgba(255, 255, 255, .14); }
    .auth-back:focus-visible { outline: 2px solid #fff; outline-offset: 2px; }
    .auth-back .material-symbols-outlined { font-size: 24px; }
    .auth-topbar h1 {
        position: absolute;
        left: 50%;
        transform: translateX(-50%);
        margin: 0;
        color: #fff;
        font-size: 19px;
        font-weight: 700;
        letter-spacing: .01em;
        white-space: nowrap;
    }

    /* ===== Khối nội dung chính ===== */
    .auth-main {
        position: relative;
        z-index: 5;
        display: flex;
        flex-direction: column;
        align-items: center;
        padding: clamp(28px, 16.5vh, 196px) 12px 56px;
    }

    .auth-card {
        width: min(600px, 100%);
        background: #fff;
        border-radius: 6px;
        box-shadow: 0 14px 38px rgba(4, 46, 30, .20), 0 2px 8px rgba(4, 46, 30, .10);
        overflow: hidden;
    }

    .auth-card-body { padding: 28px 24px 26px; }

    /* ===== Form controls ===== */
    .auth-field { margin-bottom: 26px; }
    .auth-label {
        display: block;
        margin-bottom: 9px;
        font-size: 16px;
        font-weight: 600;
        color: var(--vs-ink);
    }
    .auth-input-wrap {
        position: relative;
        display: flex;
        align-items: center;
        height: 52px;
        background: #fff;
        border: 1px solid var(--vs-line);
        border-radius: 6px;
        transition: border-color .15s ease, box-shadow .15s ease;
    }
    .auth-input-wrap:focus-within {
        border-color: var(--vs-green-500);
        box-shadow: 0 0 0 3px rgba(24, 200, 232, .22);
    }
    .auth-input-wrap.is-invalid { border-color: #e08c84; }
    .auth-input-wrap.is-invalid:focus-within {
        border-color: var(--vs-danger);
        box-shadow: 0 0 0 3px rgba(192, 57, 43, .12);
    }
    .auth-input {
        flex: 1;
        min-width: 0;
        height: 100%;
        border: none;
        outline: none;
        background: transparent;
        padding: 0 14px;
        font-family: inherit;
        font-size: 15px;
        font-weight: 500;
        color: var(--vs-ink);
    }
    .auth-input::placeholder { color: #a7b3ac; font-weight: 400; }

    /* Chip cờ VN + mã vùng trong ô số điện thoại */
    .auth-phone-prefix {
        display: inline-flex;
        align-items: center;
        gap: 7px;
        padding: 0 4px 0 14px;
        flex-shrink: 0;
        color: var(--vs-ink);
        font-size: 15px;
        font-weight: 600;
    }
    .auth-phone-prefix .vn-flag { width: 24px; height: 24px; display: block; }
    .auth-phone-prefix .material-symbols-outlined {
        font-size: 20px;
        color: #8d9992;
        margin-left: -3px;
    }

    /* Nút icon trong input (eye / clear) */
    .auth-input-btn {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 44px;
        height: 44px;
        margin-right: 4px;
        flex-shrink: 0;
        border: none;
        border-radius: 6px;
        background: transparent;
        cursor: pointer;
        color: var(--vs-green-700);
        transition: color .15s ease;
    }
    .auth-input-btn:hover { color: var(--vs-green-900); }
    .auth-input-btn:focus-visible { outline: 2px solid var(--vs-green-500); outline-offset: -2px; }
    .auth-input-btn .material-symbols-outlined { font-size: 22px; }
    .auth-input-btn.auth-clear-btn { color: var(--vs-green-700); }

    .auth-field-error {
        margin-top: 7px;
        font-size: 13px;
        font-weight: 500;
        color: var(--vs-danger);
        display: none;
    }
    .auth-field-error.show { display: block; }

    .auth-hint {
        margin-top: 7px;
        font-size: 13px;
        color: var(--vs-ink-soft);
    }

    /* ===== Nút chính ===== */
    .auth-btn-primary {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 100%;
        height: 52px;
        border: none;
        border-radius: 5px;
        background: var(--vs-orange-500);
        color: #fff;
        font-family: inherit;
        font-size: 15px;
        font-weight: 700;
        letter-spacing: .08em;
        cursor: pointer;
        transition: background-color .15s ease, transform .1s ease;
    }
    .auth-btn-primary:hover { background: var(--vs-orange-600); }
    .auth-btn-primary:active { transform: scale(.99); }
    .auth-btn-primary:focus-visible { outline: 3px solid rgba(24, 200, 232, .45); outline-offset: 2px; }
    .auth-btn-primary[disabled] { opacity: .75; cursor: default; }

    /* ===== Alert trong card ===== */
    .auth-alert {
        display: flex;
        align-items: flex-start;
        gap: 10px;
        padding: 12px 14px;
        margin-bottom: 22px;
        border-radius: 6px;
        font-size: 14px;
        font-weight: 500;
        line-height: 1.45;
    }
    .auth-alert .material-symbols-outlined { font-size: 20px; flex-shrink: 0; margin-top: 1px; }
    .auth-alert-error {
        background: var(--vs-danger-soft);
        border: 1px solid var(--vs-danger-line);
        color: #9f2f2d;
    }
    .auth-alert-success {
        background: #E5F7EF;
        border: 1px solid #9BE0BF;
        color: #16A36A;
    }
    .auth-alert-info {
        background: #F0FCFE;
        border: 1px solid #B7ECF5;
        color: #08657D;
    }
    .auth-alert-info a {
        display: inline-block;
        margin-top: 4px;
        color: var(--vs-green-800);
        font-weight: 700;
        text-decoration: underline;
        text-underline-offset: 3px;
    }

    .auth-submit-gap { margin-top: 6px; }

    /* ===== Dòng phụ dưới nút ===== */
    .auth-subline {
        margin-top: 26px;
        text-align: center;
        font-size: 14px;
        color: var(--vs-ink-soft);
    }
    .auth-subline a {
        color: var(--vs-green-800);
        font-weight: 700;
        text-decoration: underline;
        text-underline-offset: 3px;
    }
    .auth-subline a:hover { color: var(--vs-green-900); }

    /* Dòng chuyển trang bên ngoài card */
    .auth-switch-line {
        margin-top: 30px;
        text-align: center;
        font-size: 15px;
        color: rgba(255, 255, 255, .92);
    }
    .auth-switch-line a {
        color: #fff;
        font-weight: 700;
        text-decoration: none;
    }
    .auth-switch-line a:hover { text-decoration: underline; text-underline-offset: 3px; }

    @media (max-width: 640px) {
        .auth-main { padding-left: 12px; padding-right: 12px; }
        .auth-card { width: calc(100% - 0px); }
        .auth-card-body { padding: 22px 16px 22px; }
        .auth-label { font-size: 15px; }
        .auth-topbar h1 { font-size: 17px; }
    }
</style>
<script>
    (function () {
        'use strict';

        function initAuthShared() {
            // Password visibility toggle: button[data-toggle-password="<inputId>"]
            document.querySelectorAll('[data-toggle-password]').forEach(function (btn) {
                var input = document.getElementById(btn.getAttribute('data-toggle-password'));
                if (!input) return;
                btn.addEventListener('click', function () {
                    var show = input.type === 'password';
                    input.type = show ? 'text' : 'password';
                    btn.setAttribute('aria-label', show ? 'Ẩn mật khẩu' : 'Hiện mật khẩu');
                    btn.setAttribute('title', show ? 'Ẩn mật khẩu' : 'Hiện mật khẩu');
                    var icon = btn.querySelector('.material-symbols-outlined');
                    if (icon) icon.textContent = show ? 'visibility' : 'visibility_off';
                    input.focus({ preventScroll: true });
                });
            });

            // Clear button: button[data-clear-for="<inputId>"]
            document.querySelectorAll('[data-clear-for]').forEach(function (btn) {
                var input = document.getElementById(btn.getAttribute('data-clear-for'));
                if (!input) return;
                btn.addEventListener('click', function () {
                    input.value = '';
                    input.focus({ preventScroll: true });
                });
            });

            // Back button: cùng origin và không quay lại vòng lặp auth thì history.back,
            // ngược lại về Customer Home theo href (đã chứa context path).
            var backBtn = document.querySelector('[data-auth-back]');
            if (backBtn) {
                backBtn.addEventListener('click', function (e) {
                    try {
                        var ref = document.referrer;
                        if (ref && history.length > 1) {
                            var refUrl = new URL(ref);
                            var sameOrigin = refUrl.origin === window.location.origin;
                            var isAuthPage = /\/(dangnhap|dangky|quenmatkhau|nhapma|nhapmatkhaumoi)(\?|$)/.test(refUrl.pathname);
                            if (sameOrigin && !isAuthPage) {
                                e.preventDefault();
                                history.back();
                            }
                        }
                    } catch (err) { /* fallback: theo href */ }
                });
            }

            // Chống double-submit: form[data-auth-form] + nút [data-loading-text]
            document.querySelectorAll('form[data-auth-form]').forEach(function (form) {
                form.addEventListener('submit', function (e) {
                    if (e.defaultPrevented) return;
                    if (form.dataset.submitted === 'true') { e.preventDefault(); return; }
                    form.dataset.submitted = 'true';
                    var btn = form.querySelector('button[type="submit"]');
                    if (btn) {
                        btn.disabled = true;
                        var loading = btn.getAttribute('data-loading-text');
                        if (loading) btn.textContent = loading;
                    }
                });
            });
        }

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initAuthShared);
        } else {
            initAuthShared();
        }
    })();
</script>
