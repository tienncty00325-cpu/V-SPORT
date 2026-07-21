<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Đặt lại mật khẩu Cổng vận hành - V-SPORT</title>
    <%@ include file="common/auth-theme.jsp" %>
    <style>
        body.auth-body--internal {
            background-color: #052e20;
            background-image:
                linear-gradient(170deg, rgba(6, 52, 36, .90) 0%, rgba(4, 38, 26, .88) 55%, rgba(3, 26, 18, .93) 100%),
                url('${ctx}/resources/background-hero.jpg');
            background-size: cover;
            background-position: center;
            background-attachment: fixed;
        }
        .auth-main--internal { padding-top: clamp(28px, 13vh, 158px); }
        .auth-card--reset { width: min(560px, 100%); border-radius: 12px; }
        .auth-card--reset .auth-card-body { padding: 30px 28px 28px; }

        .internal-badge {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 5px 12px;
            border-radius: 999px;
            background: #edf6f0;
            border: 1px solid #cbe4d6;
            color: var(--vs-green-800);
            font-size: 12.5px;
            font-weight: 700;
            letter-spacing: .04em;
            margin-bottom: 14px;
        }
        .internal-badge .material-symbols-outlined { font-size: 16px; }

        .reset-title {
            margin: 0 0 8px;
            font-size: 21px;
            font-weight: 700;
            color: var(--vs-ink);
            letter-spacing: -.01em;
        }
        .reset-desc {
            margin: 0 0 22px;
            font-size: 14px;
            line-height: 1.5;
            color: var(--vs-ink-soft);
        }

        .reset-submit { margin-top: 6px; position: relative; }
        .btn-spinner { display: none; }
        .reset-submit.is-loading .btn-label { visibility: hidden; }
        .reset-submit.is-loading .btn-spinner {
            position: absolute;
            inset: 0;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .btn-spinner::after {
            content: '';
            width: 24px;
            height: 24px;
            border-radius: 50%;
            border: 3px solid rgba(255, 255, 255, .35);
            border-top-color: #fff;
            animation: vs-rotate .8s linear infinite;
        }
        @keyframes vs-rotate { to { transform: rotate(360deg); } }

        @media (max-width: 640px) {
            .auth-card--reset .auth-card-body { padding: 22px 16px 22px; }
        }
        @media (prefers-reduced-motion: reduce) {
            .btn-spinner::after { animation-duration: 2.4s; }
        }
    </style>
</head>
<body class="auth-body auth-body--internal" data-portal="internal">

    <header class="auth-topbar">
        <h1>Đặt lại mật khẩu</h1>
    </header>

    <main class="auth-main auth-main--internal">
        <div class="auth-card auth-card--reset">
            <div class="auth-card-body">
                <span class="internal-badge">
                    <span class="material-symbols-outlined" aria-hidden="true">shield_person</span>
                    OPERATIONS PORTAL
                </span>
                <h2 class="reset-title">Tạo mật khẩu mới</h2>
                <p class="reset-desc">Mật khẩu tối thiểu 8 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt.</p>

                <c:if test="${not empty loi}">
                    <div class="auth-alert auth-alert-error" role="alert" aria-live="assertive">
                        <span class="material-symbols-outlined" aria-hidden="true">error</span>
                        <span><c:out value="${loi}"/></span>
                    </div>
                </c:if>

                <form id="reset-form" action="${ctx}/he-thong/dat-lai-mat-khau" method="POST" autocomplete="off" novalidate>
                    <div class="auth-field">
                        <label class="auth-label" for="new-pass">Mật khẩu mới</label>
                        <div class="auth-input-wrap">
                            <input class="auth-input" type="password" name="password" id="new-pass"
                                   autocomplete="new-password" placeholder="Nhập mật khẩu mới"
                                   aria-describedby="new-pass-error"/>
                            <button type="button" class="auth-input-btn" data-toggle-password="new-pass"
                                    aria-label="Hiện mật khẩu" title="Hiện mật khẩu">
                                <span class="material-symbols-outlined" aria-hidden="true">visibility_off</span>
                            </button>
                        </div>
                        <p class="auth-field-error" id="new-pass-error"></p>
                    </div>

                    <div class="auth-field">
                        <label class="auth-label" for="confirm-pass">Nhập lại mật khẩu</label>
                        <div class="auth-input-wrap">
                            <input class="auth-input" type="password" name="confirm_password" id="confirm-pass"
                                   autocomplete="new-password" placeholder="Nhập lại mật khẩu mới"
                                   aria-describedby="confirm-pass-error"/>
                            <button type="button" class="auth-input-btn" data-toggle-password="confirm-pass"
                                    aria-label="Hiện mật khẩu" title="Hiện mật khẩu">
                                <span class="material-symbols-outlined" aria-hidden="true">visibility_off</span>
                            </button>
                        </div>
                        <p class="auth-field-error" id="confirm-pass-error"></p>
                    </div>

                    <button type="submit" id="reset-submit" class="auth-btn-primary reset-submit" aria-busy="false">
                        <span class="btn-label">CẬP NHẬT MẬT KHẨU</span>
                        <span class="btn-spinner" aria-hidden="true"></span>
                    </button>
                </form>
            </div>
        </div>
    </main>

    <script>
        (function () {
            'use strict';

            var form = document.getElementById('reset-form');
            var passInput = document.getElementById('new-pass');
            var confirmInput = document.getElementById('confirm-pass');
            var btn = document.getElementById('reset-submit');

            function setFieldError(input, msg) {
                var errorEl = document.getElementById(input.id + '-error');
                var wrap = input.closest('.auth-input-wrap');
                if (msg) {
                    errorEl.textContent = msg;
                    errorEl.classList.add('show');
                    if (wrap) wrap.classList.add('is-invalid');
                } else {
                    errorEl.textContent = '';
                    errorEl.classList.remove('show');
                    if (wrap) wrap.classList.remove('is-invalid');
                }
            }

            function setLoading(on) {
                btn.classList.toggle('is-loading', on);
                btn.disabled = on;
                btn.setAttribute('aria-busy', on ? 'true' : 'false');
                if (!on) form.dataset.submitted = '';
            }

            form.addEventListener('submit', function (e) {
                if (form.dataset.submitted === 'true') { e.preventDefault(); return; }
                setFieldError(passInput, null);
                setFieldError(confirmInput, null);
                var pw = passInput.value.trim();
                var strong = pw.length >= 8 && /[A-Z]/.test(pw) && /[a-z]/.test(pw)
                        && /[0-9]/.test(pw) && /[^A-Za-z0-9]/.test(pw);
                if (!strong) {
                    e.preventDefault();
                    setFieldError(passInput, 'Mật khẩu tối thiểu 8 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt.');
                    passInput.focus();
                    return;
                }
                if (pw !== confirmInput.value.trim()) {
                    e.preventDefault();
                    setFieldError(confirmInput, 'Mật khẩu xác nhận không khớp.');
                    confirmInput.focus();
                    return;
                }
                form.dataset.submitted = 'true';
                setLoading(true);
            });

            window.addEventListener('pageshow', function () {
                setLoading(false);
            });
        })();
    </script>
</body>
</html>
