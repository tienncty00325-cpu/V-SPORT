<%--
    V-SPORT Transition Screen — overlay dùng chung cho hai cổng đăng nhập.
    Include tĩnh ngay sau <body> (sau auth-waves): <%@ include file="common/auth-transition.jsp" %>
    Trang include phải đặt data-portal="customer|internal" trên <body>.

    JS API:
        showAuthTransition({ destination: 'internal'|'customer'|'authenticate', message: '...' })

    Hành vi:
      - Link đổi cổng: a[data-portal-link="internal|customer"] → overlay + điều hướng sau ~180ms.
      - Form đăng nhập: form[data-auth-transition] → overlay "Đang xác thực tài khoản" khi submit hợp lệ.
      - Trang đích: nếu sessionStorage 'vsportAuthTransition' khớp portal của trang → splash ngắn rồi fade.
      - prefers-reduced-motion: tắt orbit/glow, chỉ fade ngắn.
      - pageshow (bfcache) → luôn ẩn overlay, không bao giờ kẹt.
--%>
<style>
    .vs-transition {
        position: fixed;
        inset: 0;
        z-index: 2000;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 0;
        background:
            radial-gradient(90% 70% at 50% 30%, rgba(24, 200, 232, .35), transparent 70%),
            linear-gradient(170deg, #123A63 0%, #0B2545 55%, #071A2F 100%);
        background-color: #071A2F;
        opacity: 0;
        visibility: hidden;
        transition: opacity .28s ease, visibility .28s ease;
    }
    .vs-transition.show { opacity: 1; visibility: visible; }

    /* Lưới + đường kẻ sân mờ */
    .vs-transition::before {
        content: "";
        position: absolute;
        inset: 0;
        background-image:
            linear-gradient(rgba(255,255,255,.03) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,255,255,.03) 1px, transparent 1px);
        background-size: 56px 56px;
        pointer-events: none;
    }
    .vs-transition-court {
        position: absolute;
        inset: 0;
        width: 100%;
        height: 100%;
        pointer-events: none;
        opacity: .5;
    }

    .vs-transition-stage {
        position: relative;
        width: 240px;
        height: 240px;
        display: flex;
        align-items: center;
        justify-content: center;
    }
    .vs-transition-logo {
        width: 118px;
        height: 118px;
        border-radius: 26px;
        background: #fff;
        display: flex;
        align-items: center;
        justify-content: center;
        box-shadow: 0 0 0 10px rgba(255,255,255,.06), 0 0 60px rgba(24, 200, 232, .40);
        animation: vs-glow 3s ease-in-out infinite;
    }
    .vs-transition-logo .material-symbols-outlined {
        font-size: 56px;
        color: #185A9D;
    }
    @keyframes vs-glow {
        0%, 100% { box-shadow: 0 0 0 10px rgba(255,255,255,.06), 0 0 46px rgba(24,200,232,.32); }
        50%      { box-shadow: 0 0 0 10px rgba(255,255,255,.09), 0 0 72px rgba(24,200,232,.50); }
    }

    /* Vòng orbit icon thể thao */
    .vs-transition-orbit {
        position: absolute;
        inset: 0;
        border: 1px dashed rgba(255,255,255,.14);
        border-radius: 50%;
        animation: vs-orbit 26s linear infinite;
    }
    .vs-transition-orbit .vs-orbit-icon {
        position: absolute;
        width: 40px;
        height: 40px;
        margin: -20px;
        border-radius: 50%;
        background: rgba(255,255,255,.09);
        border: 1px solid rgba(255,255,255,.14);
        display: flex;
        align-items: center;
        justify-content: center;
        color: rgba(255,255,255,.85);
        animation: vs-orbit-counter 26s linear infinite;
    }
    .vs-orbit-icon .material-symbols-outlined { font-size: 21px; }
    .vs-orbit-icon:nth-child(1) { top: 0;    left: 50%; }
    .vs-orbit-icon:nth-child(2) { top: 33%;  left: 97%; }
    .vs-orbit-icon:nth-child(3) { top: 88%;  left: 79%; }
    .vs-orbit-icon:nth-child(4) { top: 88%;  left: 21%; }
    .vs-orbit-icon:nth-child(5) { top: 33%;  left: 3%;  }
    @keyframes vs-orbit         { to { transform: rotate(360deg); } }
    @keyframes vs-orbit-counter { to { transform: rotate(-360deg); } }

    .vs-transition-title {
        margin: 34px 0 0;
        color: #fff;
        font-size: 34px;
        font-weight: 800;
        letter-spacing: .42em;
        text-indent: .42em;
        text-align: center;
    }
    .vs-transition-sub {
        margin: 14px 0 0;
        color: rgba(255,255,255,.72);
        font-size: 15px;
        font-weight: 500;
        text-align: center;
        padding: 0 24px;
    }
    .vs-transition-dots {
        display: flex;
        gap: 8px;
        margin-top: 22px;
    }
    .vs-transition-dots span {
        width: 7px;
        height: 7px;
        border-radius: 50%;
        background: rgba(255,255,255,.75);
        animation: vs-dot 1.2s ease-in-out infinite;
    }
    .vs-transition-dots span:nth-child(2) { animation-delay: .18s; }
    .vs-transition-dots span:nth-child(3) { animation-delay: .36s; }
    @keyframes vs-dot {
        0%, 100% { opacity: .3; transform: translateY(0); }
        50%      { opacity: 1;  transform: translateY(-4px); }
    }

    @media (max-width: 640px) {
        .vs-transition-stage { width: 190px; height: 190px; }
        .vs-transition-logo { width: 92px; height: 92px; border-radius: 20px; }
        .vs-transition-logo .material-symbols-outlined { font-size: 44px; }
        .vs-transition-title { font-size: 25px; }
        .vs-orbit-icon:nth-child(4), .vs-orbit-icon:nth-child(5) { display: none; }
    }

    @media (prefers-reduced-motion: reduce) {
        .vs-transition { transition: opacity .15s ease, visibility .15s ease; }
        .vs-transition-orbit,
        .vs-transition-orbit .vs-orbit-icon,
        .vs-transition-logo,
        .vs-transition-dots span { animation: none !important; }
    }
</style>
<div class="vs-transition" id="vs-transition" role="status" aria-live="polite" aria-label="Đang chuyển trang V-SPORT" aria-hidden="true">
    <svg class="vs-transition-court" viewBox="0 0 1440 900" preserveAspectRatio="xMidYMid slice" aria-hidden="true" focusable="false">
        <circle cx="720" cy="450" r="260" fill="none" stroke="rgba(255,255,255,0.05)" stroke-width="2"/>
        <line x1="720" y1="0" x2="720" y2="900" stroke="rgba(255,255,255,0.04)" stroke-width="2"/>
        <rect x="-40" y="290" width="300" height="320" fill="none" stroke="rgba(255,255,255,0.04)" stroke-width="2"/>
        <rect x="1180" y="290" width="300" height="320" fill="none" stroke="rgba(255,255,255,0.04)" stroke-width="2"/>
    </svg>
    <div class="vs-transition-stage">
        <div class="vs-transition-orbit" aria-hidden="true">
            <span class="vs-orbit-icon"><span class="material-symbols-outlined">sports_soccer</span></span>
            <span class="vs-orbit-icon"><span class="material-symbols-outlined">sports_tennis</span></span>
            <span class="vs-orbit-icon"><span class="material-symbols-outlined">sports_basketball</span></span>
            <span class="vs-orbit-icon"><span class="material-symbols-outlined">calendar_month</span></span>
            <span class="vs-orbit-icon"><span class="material-symbols-outlined">stadium</span></span>
        </div>
        <div class="vs-transition-logo">
            <span class="material-symbols-outlined" aria-hidden="true">sports_tennis</span>
        </div>
    </div>
    <p class="vs-transition-title">V-SPORT</p>
    <p class="vs-transition-sub" id="vs-transition-sub">Đang xử lý</p>
    <div class="vs-transition-dots" aria-hidden="true"><span></span><span></span><span></span></div>
</div>
<script>
    (function () {
        'use strict';

        var overlay = document.getElementById('vs-transition');
        var subEl = document.getElementById('vs-transition-sub');
        var STORAGE_KEY = 'vsportAuthTransition';
        var NAV_DELAY = 180;   // ms trước khi điều hướng khi đổi cổng
        var ARRIVE_MS = 550;   // splash ngắn ở trang đích

        var DEFAULT_MESSAGES = {
            internal: 'Đang chuyển đến Cổng vận hành',
            customer: 'Đang chuyển về Cổng khách hàng',
            authenticate: 'Đang xác thực tài khoản'
        };

        function show(opts) {
            opts = opts || {};
            subEl.textContent = opts.message || DEFAULT_MESSAGES[opts.destination] || 'Đang xử lý';
            overlay.setAttribute('aria-hidden', 'false');
            overlay.classList.add('show');
        }

        function hide() {
            overlay.classList.remove('show');
            overlay.setAttribute('aria-hidden', 'true');
        }

        window.showAuthTransition = show;
        window.hideAuthTransition = hide;

        function initTransition() {
            // Link đổi cổng: hiển thị overlay rồi điều hướng (không delay giả dài).
            document.querySelectorAll('a[data-portal-link]').forEach(function (link) {
                link.addEventListener('click', function (e) {
                    if (e.metaKey || e.ctrlKey || e.shiftKey || e.button !== 0) return;
                    e.preventDefault();
                    var dest = link.getAttribute('data-portal-link') === 'internal' ? 'internal' : 'customer';
                    try { sessionStorage.setItem(STORAGE_KEY, dest); } catch (err) { /* private mode */ }
                    show({ destination: dest });
                    var href = link.href;
                    setTimeout(function () { window.location.href = href; }, NAV_DELAY);
                });
            });

            // Submit form đăng nhập: overlay "Đang xác thực tài khoản".
            // Đăng ký listener ở DOMContentLoaded nên chạy SAU validation inline của trang;
            // nếu validation preventDefault thì không hiển thị overlay.
            document.querySelectorAll('form[data-auth-transition]').forEach(function (form) {
                form.addEventListener('submit', function (e) {
                    if (e.defaultPrevented) return;
                    show({ destination: 'authenticate' });
                });
            });

            // Trang đích của portal transition: splash ngắn rồi fade out.
            var portal = document.body.getAttribute('data-portal');
            var pending = null;
            try { pending = sessionStorage.getItem(STORAGE_KEY); } catch (err) { /* ignore */ }
            if (pending && pending === portal) {
                try { sessionStorage.removeItem(STORAGE_KEY); } catch (err) { /* ignore */ }
                var reduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
                show({ message: portal === 'internal' ? 'Cổng vận hành V-SPORT' : 'Cổng khách hàng V-SPORT' });
                setTimeout(hide, reduced ? 150 : ARRIVE_MS);
            } else if (pending) {
                try { sessionStorage.removeItem(STORAGE_KEY); } catch (err) { /* ignore */ }
            }
        }

        // Không bao giờ để overlay kẹt khi back/forward (bfcache) hoặc server render lại trang.
        window.addEventListener('pageshow', function (e) {
            if (e.persisted) hide();
        });

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initTransition);
        } else {
            initTransition();
        }
    })();
</script>
