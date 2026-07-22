<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<%-- Tabler Icons – custom icon set for V-SPORT (injected once via sidebar) --%>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/dist/tabler-icons.min.css"/>

<!-- ═══════════════════════════════════════════════════════
     SHARED ADMIN CSS – included once via sidebar.jsp
════════════════════════════════════════════════════════ -->
<style id="admin-shared-css">
  *,*::before,*::after{box-sizing:border-box}
  html{scroll-behavior:smooth}
  body{font-family:'Inter',sans-serif;background:#f1f5f9;margin:0}
  ::-webkit-scrollbar{width:4px;height:4px}
  ::-webkit-scrollbar-track{background:transparent}
  ::-webkit-scrollbar-thumb{background:#cbd5e1;border-radius:99px}
  ::-webkit-scrollbar-thumb:hover{background:#94a3b8}

  /* ── Sidebar nav-link ── */
  .nav-link{
    display:flex;align-items:center;gap:10px;padding:9px 12px;
    border-radius:10px;font-size:13.5px;font-weight:500;
    color:#475569;text-decoration:none;transition:background-color .17s ease,color .17s ease,transform .17s ease,box-shadow .17s ease;
    position:relative;cursor:pointer;white-space:nowrap;
  }
  .nav-link:hover{background:#f1f5f9;color:#0f172a;transform:translateX(2px)}
  .nav-link.active{
    background:linear-gradient(90deg,#eff6ff,#dbeafe);
    color:#1d4ed8;font-weight:600;
  }
  .nav-link.is-navigating{
    background:linear-gradient(90deg,#dbeafe,#eff6ff);
    color:#1d4ed8;
    box-shadow:inset 0 0 0 1px rgba(37,99,235,.08);
  }
  .nav-link.active::before{
    content:'';position:absolute;left:0;top:6px;bottom:6px;
    width:3px;background:#2563eb;border-radius:0 4px 4px 0;
  }
  .nav-link .ti{font-size:18px;flex-shrink:0}

  /* ── Cards ── */
  .adm-card{
    background:#fff;border:1px solid #e2e8f0;
    border-radius:16px;overflow:hidden;
  }
  .adm-card-hover{transition:box-shadow .2s,transform .2s}
  .adm-card-hover:hover{box-shadow:0 4px 24px rgba(15,23,42,.08);transform:translateY(-2px)}

  /* ── Badges ── */
  .badge{display:inline-flex;align-items:center;border-radius:99px;font-size:11px;font-weight:700;padding:2px 8px}
  .badge-green{background:#dcfce7;color:#166534}
  .badge-amber{background:#fef3c7;color:#92400e}
  .badge-red{background:#fee2e2;color:#991b1b}
  .badge-blue{background:#dbeafe;color:#1e40af}
  .badge-purple{background:#ede9fe;color:#5b21b6}
  .badge-zinc{background:#f1f5f9;color:#475569}

  /* ── Scroll reveal ── */
  .reveal{opacity:0;transform:translateY(14px);transition:opacity .42s cubic-bezier(.22,1,.36,1),transform .42s cubic-bezier(.22,1,.36,1)}
  .reveal.visible{opacity:1;transform:translateY(0)}
  .reveal-left{opacity:0;transform:translateX(-14px);transition:opacity .42s cubic-bezier(.22,1,.36,1),transform .42s cubic-bezier(.22,1,.36,1)}
  .reveal-left.visible{opacity:1;transform:translateX(0)}
  .reveal-scale{opacity:0;transform:scale(.98);transition:opacity .38s cubic-bezier(.22,1,.36,1),transform .38s cubic-bezier(.22,1,.36,1)}
  .reveal-scale.visible{opacity:1;transform:scale(1)}

  /* ── Stagger delays ── */
  .d0{transition-delay:0ms}.d1{transition-delay:45ms}.d2{transition-delay:90ms}.d3{transition-delay:135ms}
  .d4{transition-delay:180ms}.d5{transition-delay:225ms}.d6{transition-delay:270ms}

  /* ── Animate number counter ── */
  @keyframes countUp{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}
  .num-anim{animation:countUp .6s cubic-bezier(.22,1,.36,1) both}

  /* ── Live dot ── */
  @keyframes livePulse{0%,100%{box-shadow:0 0 0 0 rgba(34,197,94,.45)}50%{box-shadow:0 0 0 5px rgba(34,197,94,0)}}
  .live-dot{animation:livePulse 1.8s ease-in-out infinite}

  /* ── Tab buttons ── */
  .tab-pill{
    display:inline-flex;align-items:center;gap:6px;
    padding:7px 16px;border-radius:99px;font-size:13px;font-weight:500;
    border:none;cursor:pointer;transition:all .18s;text-decoration:none;
  }
  .tab-pill.active{background:#2563eb;color:#fff;box-shadow:0 2px 10px rgba(37,99,235,.3)}
  .tab-pill:not(.active){background:#fff;color:#64748b;border:1px solid #e2e8f0}
  .tab-pill:not(.active):hover{background:#f8fafc;color:#1e293b}

  /* ── Page motion ── */
  body.admin-motion main{
    opacity:0;
    transform:translateY(10px) scale(.995);
    filter:blur(1px);
    animation:none !important;
  }
  body.admin-motion.admin-page-ready main{
    opacity:1;
    transform:translateY(0) scale(1);
    filter:blur(0);
    transition:opacity .34s cubic-bezier(.22,1,.36,1),transform .34s cubic-bezier(.22,1,.36,1),filter .34s ease;
  }
  body.admin-page-exiting main{
    opacity:0 !important;
    transform:translateY(-8px) scale(.992) !important;
    filter:blur(2px) !important;
    transition:opacity .2s ease,transform .2s ease,filter .2s ease !important;
  }
  .admin-transition-scrim{
    position:fixed;inset:0;z-index:60;pointer-events:none;
    background:linear-gradient(180deg,rgba(248,250,252,.72),rgba(241,245,249,.88));
    opacity:0;backdrop-filter:blur(0);
    transition:opacity .2s ease,backdrop-filter .2s ease;
  }
  body.admin-page-exiting .admin-transition-scrim{opacity:1;backdrop-filter:blur(3px)}
  .admin-transition-scrim::after{
    content:'';position:absolute;left:260px;right:0;top:64px;height:2px;
    background:linear-gradient(90deg,transparent,#2563eb,#38bdf8,transparent);
    transform:scaleX(0);transform-origin:left;
  }
  body.admin-page-exiting .admin-transition-scrim::after{animation:adminRouteLine .42s cubic-bezier(.22,1,.36,1) forwards}
  @keyframes adminRouteLine{to{transform:scaleX(1)}}
  @media (max-width:1023px){.admin-transition-scrim::after{left:0}}
  @media (prefers-reduced-motion:reduce){
    body.admin-motion main,
    body.admin-motion.admin-page-ready main,
    body.admin-page-exiting main{opacity:1!important;transform:none!important;filter:none!important;transition:none!important}
    .admin-transition-scrim{display:none!important}
  }
</style>

<!-- Mobile overlay -->
<div id="sidebarOverlay" class="fixed inset-0 bg-slate-900/50 z-20 hidden lg:hidden backdrop-blur-sm"></div>

<!-- ═══ SIDEBAR ═══ -->
<aside id="sidebar"
  class="w-[260px] h-screen fixed left-0 top-0 z-30 flex flex-col
         bg-white border-r border-slate-200 shadow-[1px_0_16px_rgba(15,23,42,.06)]
         transition-transform duration-300 -translate-x-full lg:translate-x-0">

  <!-- Logo -->
  <div class="px-5 py-5 border-b border-slate-100 flex items-center gap-3 shrink-0">
    <div class="w-10 h-10 rounded-2xl bg-gradient-to-br from-blue-500 to-blue-700
                flex items-center justify-center shrink-0
                shadow-md shadow-blue-200/60">
      <i class="ti ti-ball-tennis text-white text-[20px]"></i>
    </div>
    <div>
      <p class="text-[15px] font-black text-slate-900 tracking-tight leading-none">V-SPORT</p>
      <p class="text-[10px] text-slate-400 font-semibold uppercase tracking-widest mt-0.5">Admin Portal</p>
    </div>
  </div>

  <!-- Navigation -->
  <nav class="flex-1 overflow-y-auto px-3 py-4 flex flex-col gap-0.5">
    <c:set var="uri" value="${pageContext.request.requestURI}"/>

    <!-- Section: Vận hành -->
    <p class="text-[10px] font-bold uppercase tracking-[.12em] text-slate-400 px-3 pt-1 pb-2">Vận hành</p>

    <a href="${pageContext.request.contextPath}/admin/tong-quan"
       class="nav-link ${uri.contains('/admin/tong-quan') || uri.contains('/TongQuan') ? 'active' : ''}">
      <i class="ti ti-layout-dashboard"></i>
      Tổng quan
    </a>

    <!-- Section: Quản lý -->
    <p class="text-[10px] font-bold uppercase tracking-[.12em] text-slate-400 px-3 pt-5 pb-2">Quản lý</p>

    <a href="${pageContext.request.contextPath}/admin/chi-nhanh"
       class="nav-link ${uri.contains('/admin/chi-nhanh') || uri.contains('/QuanLyChiNhanh') ? 'active' : ''}">
      <i class="ti ti-building-stadium"></i>
      Cơ Sở
      <c:if test="${sessionScope.adminPendingCount != null && sessionScope.adminPendingCount > 0}">
        <span style="margin-left:auto;background:#f59e0b;color:#fff;border-radius:99px;font-size:10px;font-weight:700;padding:1px 7px;line-height:1.6;">${sessionScope.adminPendingCount}</span>
      </c:if>
    </a>

    <a href="${pageContext.request.contextPath}/admin/nhan-su"
       class="nav-link ${uri.contains('/admin/nhan-su') || uri.contains('/NhanSu') ? 'active' : ''}">
      <i class="ti ti-users-group"></i>
      Nhân sự
    </a>

    <a href="${pageContext.request.contextPath}/admin/audit-log"
       class="nav-link ${uri.contains('/admin/audit-log') || uri.contains('/AuditLog') ? 'active' : ''}">
      <i class="ti ti-history"></i>
      Nhật Ký Thao Tác
    </a>

    <a href="${pageContext.request.contextPath}/admin/thung-rac"
       class="nav-link ${uri.contains('/admin/thung-rac') || uri.contains('/ThungRacAdmin') ? 'active' : ''}">
      <i class="ti ti-trash"></i>
      Thùng rác
    </a>
  </nav>

  <!-- Logout -->
  <div class="px-3 pb-4 pt-3 border-t border-slate-100 shrink-0">
    <a href="${pageContext.request.contextPath}/logout"
       class="nav-link text-red-500 hover:bg-red-50 hover:text-red-600 text-[13px] font-semibold">
      <i class="ti ti-logout text-red-400 text-[17px]"></i>
      Đăng xuất
    </a>
  </div>
</aside>

<!-- ═══ SIDEBAR JS (shared) ═══ -->
<script>
(function () {
  document.body.classList.add('admin-motion');

  function initPageMotion() {
    var scrim = document.createElement('div');
    scrim.className = 'admin-transition-scrim';
    document.body.appendChild(scrim);

    requestAnimationFrame(function () {
      document.body.classList.add('admin-page-ready');
    });

    window.addEventListener('pageshow', function () {
      document.body.classList.remove('admin-page-exiting');
      requestAnimationFrame(function () {
        document.body.classList.add('admin-page-ready');
      });
    });

    document.addEventListener('click', function (event) {
      var link = event.target.closest('a[href]');
      if (!link || event.defaultPrevented) return;
      if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button !== 0) return;
      if (link.target && link.target !== '_self') return;
      if (link.hasAttribute('download')) return;

      var href = link.getAttribute('href') || '';
      if (!href || href.charAt(0) === '#' || href.indexOf('javascript:') === 0 || href.indexOf('mailto:') === 0 || href.indexOf('tel:') === 0) return;

      var url;
      try { url = new URL(href, window.location.href); } catch (e) { return; }
      if (url.origin !== window.location.origin) return;
      if (url.pathname === window.location.pathname && url.search === window.location.search && url.hash) return;
      if (url.href === window.location.href) return;

      var appPath = '${pageContext.request.contextPath}';
      if (appPath && url.pathname.indexOf(appPath + '/admin') !== 0 && url.pathname.indexOf(appPath + '/logout') !== 0) return;

      event.preventDefault();
      link.classList.add('is-navigating');
      document.body.classList.add('admin-page-exiting');
      window.setTimeout(function () {
        window.location.href = url.href;
      }, 170);
    });
  }

  function initSidebar() {
    var sidebar  = document.getElementById('sidebar');
    var overlay  = document.getElementById('sidebarOverlay');
    var menuBtns = document.querySelectorAll('[data-sidebar-toggle], #mobileMenuBtn, #sidebarToggle');
    if (!sidebar) return;

    function open()  { sidebar.classList.remove('-translate-x-full'); if (overlay) overlay.classList.remove('hidden'); }
    function close() { sidebar.classList.add('-translate-x-full');    if (overlay) overlay.classList.add('hidden'); }

    menuBtns.forEach(function (btn) { btn.addEventListener('click', function () { sidebar.classList.contains('-translate-x-full') ? open() : close(); }); });
    if (overlay) overlay.addEventListener('click', close);
    window.addEventListener('resize', function () { if (window.innerWidth >= 1024) { overlay && overlay.classList.add('hidden'); } });
  }

  /* ── Scroll-reveal with IntersectionObserver ── */
  function initReveal() {
    var els = document.querySelectorAll('.reveal, .reveal-left, .reveal-scale');
    if (!els.length) return;
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('visible'); io.unobserve(e.target); } });
    }, { threshold: 0.08 });
    els.forEach(function (el) { io.observe(el); });
  }

  /* ── Xác nhận trước khi chuyển vào thùng rác (soft-delete) ── */
  function initSoftDeleteConfirm() {
    document.addEventListener('click', function (event) {
      var trigger = event.target.closest('.js-admin-soft-delete');
      if (!trigger) return;
      var msg = trigger.getAttribute('data-delete-message') ||
                'Bạn chắc chắn muốn chuyển mục này vào thùng rác? Bạn có thể thu hồi lại trong trang Thùng rác.';
      if (!confirm(msg)) {
        event.preventDefault();
        event.stopPropagation();
      }
    }, true);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { initPageMotion(); initSidebar(); initReveal(); init24hTime(); initSoftDeleteConfirm(); });
  } else {
    initPageMotion();
    initSidebar();
    initReveal();
    init24hTime();
    initSoftDeleteConfirm();
  }

  /* ── Force 24h time inputs across all admin pages ── */
  function init24hTime() {
    document.querySelectorAll('input[type="time"]').forEach(function(inp) {
      var val   = inp.value || '00:00';
      var parts = val.split(':');
      var initH = parseInt(parts[0] || 0, 10);
      var initM = parseInt(parts[1] || 0, 10);
      // Round minute to nearest valid step
      var steps = [0, 15, 30, 45];
      var closestM = steps.reduce(function(a, b) { return Math.abs(b - initM) < Math.abs(a - initM) ? b : a; });

      var wrap = document.createElement('div');
      wrap.style.cssText = 'display:flex;align-items:center;gap:4px;width:100%;';

      var selStyle = 'flex:1;min-width:0;height:' + (inp.offsetHeight || 38) + 'px;'
                   + 'padding:4px 8px;border:' + getComputedStyle(inp).border + ';'
                   + 'border-radius:' + getComputedStyle(inp).borderRadius + ';'
                   + 'font-size:' + getComputedStyle(inp).fontSize + ';'
                   + 'background:#fff;cursor:pointer;';

      var hSel = document.createElement('select');
      hSel.style.cssText = selStyle;
      hSel.setAttribute('aria-label', 'Giờ');
      for (var h = 0; h <= 23; h++) {
        var o = document.createElement('option');
        o.value = String(h).padStart(2, '0');
        o.textContent = String(h).padStart(2, '0') + 'h';
        if (h === initH) o.selected = true;
        hSel.appendChild(o);
      }

      var mSel = document.createElement('select');
      mSel.style.cssText = selStyle;
      mSel.setAttribute('aria-label', 'Phút');
      steps.forEach(function(m) {
        var o = document.createElement('option');
        o.value = String(m).padStart(2, '0');
        o.textContent = String(m).padStart(2, '0');
        if (m === closestM) o.selected = true;
        mSel.appendChild(o);
      });

      function sync() {
        inp.value = hSel.value + ':' + mSel.value + ':00';
        // Fire any existing onchange / oninput
        inp.dispatchEvent(new Event('change', { bubbles: true }));
        inp.dispatchEvent(new Event('input',  { bubbles: true }));
      }
      hSel.addEventListener('change', sync);
      mSel.addEventListener('change', sync);

      wrap.appendChild(hSel);
      wrap.appendChild(mSel);
      inp.style.display = 'none';
      inp.parentNode.insertBefore(wrap, inp.nextSibling);
      sync();
    });
  }
})();
</script>
