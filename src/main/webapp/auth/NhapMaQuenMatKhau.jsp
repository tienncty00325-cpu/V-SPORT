<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<c:set var="isInternal" value="${sessionScope.resetPortal eq 'internal'}"/>
<c:set var="forgotUrl" value="${ctx}${isInternal ? '/he-thong/quen-mat-khau' : '/quenmatkhau'}"/>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Nhập mã xác thực - V-SPORT</title>
    <%@ include file="common/auth-theme.jsp" %>
    <style>
        .auth-card--otp { width: min(520px, 100%); border-radius: 10px; }
        .auth-card--otp .auth-card-body { padding: 28px 26px 26px; }

        .otp-title {
            margin: 0 0 8px;
            font-size: 21px;
            font-weight: 700;
            color: var(--vs-ink);
            letter-spacing: -.01em;
        }
        .otp-desc {
            margin: 0 0 22px;
            font-size: 14.5px;
            line-height: 1.5;
            color: var(--vs-ink-soft);
        }
        .otp-desc b { color: var(--vs-ink); font-weight: 600; }

        .otp-single {
            width: 100%;
            height: 58px;
            border: 1.5px solid var(--vs-line);
            border-radius: 8px;
            font-family: inherit;
            font-size: 24px;
            font-weight: 700;
            text-align: center;
            letter-spacing: .45em;
            color: var(--vs-ink);
            outline: none;
            transition: border-color .15s ease, box-shadow .15s ease;
        }
        .otp-single::placeholder { color: #c2ccc6; letter-spacing: .45em; font-weight: 500; }
        .otp-single:focus {
            border-color: var(--vs-green-600);
            box-shadow: 0 0 0 3px rgba(13, 138, 95, .14);
        }
        .otp-single.is-invalid { border-color: var(--vs-danger); }

        .otp-resend {
            margin: 14px 0 0;
            font-size: 13.5px;
            color: var(--vs-ink-soft);
            text-align: center;
        }
        .otp-resend a {
            color: var(--vs-green-800);
            font-weight: 700;
            text-decoration: underline;
            text-underline-offset: 3px;
        }
        .otp-resend a:hover { color: var(--vs-green-900); }

        .otp-verify-btn { margin-top: 22px; position: relative; }
        .btn-spinner { display: none; }
        .otp-verify-btn.is-loading .btn-label { visibility: hidden; }
        .otp-verify-btn.is-loading .btn-spinner {
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

        .otp-change {
            margin: 18px 0 0;
            text-align: center;
            font-size: 13.5px;
        }
        .otp-change a {
            color: var(--vs-ink-soft);
            font-weight: 600;
            text-decoration: underline;
            text-underline-offset: 3px;
        }
        .otp-change a:hover { color: var(--vs-ink); }

        @media (max-width: 640px) {
            .auth-card--otp .auth-card-body { padding: 22px 16px 22px; }
        }
        @media (prefers-reduced-motion: reduce) {
            .btn-spinner::after { animation-duration: 2.4s; }
        }
    </style>
</head>
<body class="auth-body" data-portal="${isInternal ? 'internal' : 'customer'}">
    <%@ include file="common/auth-waves.jsp" %>

    <header class="auth-topbar">
        <a href="${forgotUrl}" class="auth-back" aria-label="Quay lại nhập email">
            <span class="material-symbols-outlined" aria-hidden="true">arrow_back_ios_new</span>
        </a>
        <h1>Quên mật khẩu</h1>
    </header>

    <main class="auth-main">
        <div class="auth-card auth-card--otp">
            <div class="auth-card-body">
                <h2 class="otp-title">Nhập mã xác thực</h2>
                <p class="otp-desc">Mã gồm 6 số đã được gửi đến <b><c:out value="${email}"/></b>.</p>

                <c:if test="${not empty loi}">
                    <div class="auth-alert auth-alert-error" role="alert" aria-live="assertive">
                        <span class="material-symbols-outlined" aria-hidden="true">error</span>
                        <span><c:out value="${loi}"/></span>
                    </div>
                </c:if>
                <c:if test="${not empty thongbao}">
                    <div class="auth-alert auth-alert-success" role="status" aria-live="polite">
                        <span class="material-symbols-outlined" aria-hidden="true">check_circle</span>
                        <span><c:out value="${thongbao}"/></span>
                    </div>
                </c:if>

                <form id="otp-form" action="${ctx}/nhapma" method="POST" autocomplete="off" novalidate>
                    <label class="auth-label" for="otp-input" style="position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);">Mã xác thực 6 chữ số</label>
                    <input class="otp-single" type="text" name="otp" id="otp-input"
                           inputmode="numeric" autocomplete="one-time-code"
                           maxlength="6" pattern="\d{6}" placeholder="••••••"
                           aria-describedby="otp-error"/>
                    <p class="auth-field-error" id="otp-error"></p>

                    <p class="otp-resend" aria-live="polite">
                        <span id="resend-countdown" hidden>Gửi lại mã sau <span id="resend-timer">01:00</span></span>
                        <a id="resend-link" href="${ctx}/resend-otp">Gửi lại mã</a>
                    </p>

                    <button type="submit" id="otp-verify-btn" class="auth-btn-primary otp-verify-btn"
                            aria-busy="false">
                        <span class="btn-label">XÁC NHẬN</span>
                        <span class="btn-spinner" aria-hidden="true"></span>
                    </button>
                </form>

                <p class="otp-change">
                    <a href="${forgotUrl}">Đổi email</a>
                </p>
            </div>
        </div>
    </main>

    <script>
        (function () {
            'use strict';

            var form = document.getElementById('otp-form');
            var input = document.getElementById('otp-input');
            var errorEl = document.getElementById('otp-error');
            var btn = document.getElementById('otp-verify-btn');

            // Chỉ nhận số, tối đa 6 ký tự (kể cả khi paste)
            input.addEventListener('input', function () {
                var digits = input.value.replace(/\D/g, '').slice(0, 6);
                if (input.value !== digits) input.value = digits;
            });

            function setLoading(on) {
                btn.classList.toggle('is-loading', on);
                btn.disabled = on;
                btn.setAttribute('aria-busy', on ? 'true' : 'false');
                if (!on) form.dataset.submitted = '';
            }

            form.addEventListener('submit', function (e) {
                if (form.dataset.submitted === 'true') { e.preventDefault(); return; }
                errorEl.textContent = '';
                errorEl.classList.remove('show');
                input.classList.remove('is-invalid');
                if (!/^\d{6}$/.test(input.value)) {
                    e.preventDefault();
                    errorEl.textContent = 'Vui lòng nhập đủ 6 chữ số.';
                    errorEl.classList.add('show');
                    input.classList.add('is-invalid');
                    input.focus();
                    input.select();
                    return;
                }
                form.dataset.submitted = 'true';
                setLoading(true);
            });

            // Back/Forward/BFCache: nút luôn trở về trạng thái thường
            window.addEventListener('pageshow', function () {
                setLoading(false);
            });

            // Countdown gửi lại mã (hiển thị; server vẫn enforce cooldown 60s)
            var countdownWrap = document.getElementById('resend-countdown');
            var timerEl = document.getElementById('resend-timer');
            var resendLink = document.getElementById('resend-link');
            var remaining = 60;

            function fmt(s) {
                var m = Math.floor(s / 60), r = s % 60;
                return (m < 10 ? '0' : '') + m + ':' + (r < 10 ? '0' : '') + r;
            }

            function tick() {
                if (remaining <= 0) {
                    countdownWrap.hidden = true;
                    resendLink.hidden = false;
                    return;
                }
                timerEl.textContent = fmt(remaining);
                remaining--;
                setTimeout(tick, 1000);
            }

            resendLink.hidden = true;
            countdownWrap.hidden = false;
            tick();

            // Lỗi server render lại trang → focus vào ô mã cho nhập lại nhanh
            <c:if test="${not empty loi}">
            input.focus();
            </c:if>
        })();
    </script>
</body>
</html>
