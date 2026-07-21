<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%--
    V-SPORT customer bottom navigation. Visible at all viewport widths.
    5 items: Trang chu, Ban do, Ghep tran (raised center, white/green outline —
    only styled solid-active when the current route is /customer/ghep-keo),
    Noi bat, Tai khoan.
    Icons: Lucide (inline SVG, no external script). Requires
    customer/common/vsport-theme.jsp for styling.

    Route /customer/noi-bat is built in Phase 4. Until then it shows a
    "Sap ra mat" toast instead of a 404.
    TODO(P4): point Noi bat at /customer/noi-bat.
--%>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<nav class="vs-bottomnav" aria-label="Điều hướng chính">
    <a class="vs-bn-item" data-nav="home" href="${ctx}/index.jsp" aria-label="Trang chủ" title="Trang chủ">
        <svg class="vs-bn-ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"/><path d="M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>
        <span>Trang chủ</span>
    </a>
    <a class="vs-bn-item" data-nav="map" href="${ctx}/customer/ban-do" aria-label="Bản đồ" title="Bản đồ">
        <svg class="vs-bn-ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14.106 5.553a2 2 0 0 0 1.788 0l3.659-1.83A1 1 0 0 1 21 4.619v12.764a1 1 0 0 1-.553.894l-4.553 2.277a2 2 0 0 1-1.788 0l-4.212-2.106a2 2 0 0 0-1.788 0l-3.659 1.83A1 1 0 0 1 3 19.381V6.618a1 1 0 0 1 .553-.894l4.553-2.277a2 2 0 0 1 1.788 0z"/><path d="M15 5.764v15"/><path d="M9 3.236v15"/></svg>
        <span>Bản đồ</span>
    </a>
    <a class="vs-bn-item vs-bn-center" data-nav="match" href="${ctx}/customer/ghep-keo" aria-label="Ghép trận" title="Ghép trận">
        <span class="vs-bn-fab">
            <svg class="vs-bn-ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="14.5 17.5 3 6 3 3 6 3 17.5 14.5"/><line x1="13" x2="19" y1="19" y2="13"/><line x1="16" x2="20" y1="16" y2="20"/><line x1="19" x2="21" y1="21" y2="19"/><polyline points="14.5 6.5 18 3 21 3 21 6 17.5 10"/><line x1="5" x2="9" y1="14" y2="18"/><line x1="7" x2="4" y1="17" y2="20"/><line x1="3" x2="5" y1="19" y2="21"/></svg>
        </span>
        <span class="vs-bn-fablabel">Ghép trận</span>
    </a>
    <button type="button" class="vs-bn-item" data-nav="featured" data-soon="Nổi bật" aria-label="Nổi bật (sắp ra mắt)" title="Nổi bật (sắp ra mắt)">
        <svg class="vs-bn-ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"/></svg>
        <span>Nổi bật</span>
    </button>
    <a class="vs-bn-item" data-nav="account" href="${ctx}/customer/tai-khoan" aria-label="Tài khoản" title="Tài khoản">
        <svg class="vs-bn-ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="5"/><path d="M20 21a8 8 0 0 0-16 0"/></svg>
        <span>Tài khoản</span>
    </a>
</nav>

<div id="vsToast" role="status" aria-live="polite" style="position:fixed;left:50%;bottom:calc(var(--vs-bottomnav-h) + 18px);transform:translateX(-50%) translateY(12px);z-index:1300;background:var(--vs-ink);color:#fff;padding:10px 16px;border-radius:9999px;font-size:13px;font-weight:600;opacity:0;visibility:hidden;transition:opacity .2s ease,transform .2s ease;box-shadow:0 6px 18px rgba(15,23,42,.25);"></div>

<script>
(function () {
    // Active state from current path.
    var path = window.location.pathname;
    var key = 'home';
    if (path.indexOf('/customer/ghep-keo') > -1 || path.indexOf('/customer/ghep-tran') > -1) key = 'match';
    else if (path.indexOf('/customer/ban-do') > -1) key = 'map';
    else if (path.indexOf('/customer/noi-bat') > -1) key = 'featured';
    else if (path.indexOf('/customer/tai-khoan') > -1) key = 'account';
    else if (path.indexOf('/index.jsp') > -1 || path === '/' || path.endsWith('/')) key = 'home';
    var active = document.querySelector('.vs-bottomnav [data-nav="' + key + '"]');
    if (active) {
        active.classList.add('is-active');
        active.setAttribute('aria-current', 'page');
    }

    // "Coming soon" toast for not-yet-built destinations.
    var toast = document.getElementById('vsToast');
    var toastTimer = null;
    function showToast(msg) {
        if (!toast) return;
        toast.textContent = msg;
        toast.style.opacity = '1';
        toast.style.visibility = 'visible';
        toast.style.transform = 'translateX(-50%) translateY(0)';
        clearTimeout(toastTimer);
        toastTimer = setTimeout(function () {
            toast.style.opacity = '0';
            toast.style.transform = 'translateX(-50%) translateY(12px)';
            setTimeout(function () { toast.style.visibility = 'hidden'; }, 220);
        }, 2000);
    }
    document.querySelectorAll('.vs-bottomnav [data-soon]').forEach(function (btn) {
        btn.addEventListener('click', function () {
            showToast(btn.getAttribute('data-soon') + ' sắp ra mắt');
        });
    });
})();
</script>
