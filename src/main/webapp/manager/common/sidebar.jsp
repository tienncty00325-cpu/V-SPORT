<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ page import="org.example.model.TaiKhoan" %>
<%@ page import="org.example.dao.impl.CoSoCapabilityDAOImpl" %>
<%@ page import="org.example.util.Constants" %>
<%
    // Menu "Kho & Dịch Vụ" chỉ hiện khi cơ sở đã được duyệt ít nhất 1 capability liên
    // quan (SAN_PHAM/THUE_DUNG_CU/DO_AN_NUOC_UONG). Backend (FilterQuyenManager) đã
    // chặn truy cập servlet - đây chỉ là ẩn menu cho gọn giao diện, không phải chốt an ninh.
    TaiKhoan sidebarUser = (TaiKhoan) session.getAttribute("user");
    boolean shopModuleApproved = sidebarUser != null
            && new CoSoCapabilityDAOImpl().isApprovedAny(sidebarUser.getCoSoId(), Constants.SHOP_MODULE_CAPABILITIES);
    request.setAttribute("shopModuleApproved", shopModuleApproved);
    // Menu "Quản lý dịch vụ" (Giai đoạn 1 - căng lưới...) chỉ hiện khi capability
    // DICH_VU_THE_THAO đã APPROVED. Backend (FilterQuyenManager) là chốt an ninh thật sự.
    boolean serviceModuleApproved = sidebarUser != null
            && new CoSoCapabilityDAOImpl().isApprovedAny(sidebarUser.getCoSoId(), Constants.SERVICE_MODULE_CAPABILITIES);
    request.setAttribute("serviceModuleApproved", serviceModuleApproved);
%>
<%-- Tabler Icons --%>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/dist/tabler-icons.min.css"/>

<!-- Mobile sidebar overlay -->
<div id="sidebarOverlay" class="fixed inset-0 bg-black/40 z-20 hidden"></div>

<!-- ═══ MANAGER SHARED CSS ═══ -->
<style id="manager-shared-css">

  /* ── Nav links ── */
  .nav-link {
    display: flex;
    align-items: center;
    gap: 11px;
    padding: 10px 14px;
    border-radius: 10px;
    color: #6b7280;
    font-size: 14px;
    font-weight: 500;
    text-decoration: none;
    transition: background-color .15s ease, color .15s ease, transform .15s ease, box-shadow .15s ease;
    white-space: nowrap;
    position: relative;
    cursor: pointer;
  }
  .nav-link:hover { background: #f5f3ff; color: #6d28d9; transform: translateX(2px); }
  .nav-link.active {
    background: #ede9fe;
    color: #6d28d9;
    font-weight: 600;
  }
  .nav-link.is-navigating {
    background: linear-gradient(90deg, #ddd6fe, #ede9fe);
    color: #6d28d9;
    box-shadow: inset 0 0 0 1px rgba(124,58,237,.1);
  }
  .nav-link.active::before {
    content: '';
    position: absolute;
    left: 0;
    top: 8px;
    bottom: 8px;
    width: 3px;
    background: #7c3aed;
    border-radius: 0 3px 3px 0;
  }

  /* ── Scroll reveal ── */
  .reveal       { opacity:0; transform:translateY(14px);   transition:opacity .42s cubic-bezier(.22,1,.36,1),transform .42s cubic-bezier(.22,1,.36,1); }
  .reveal-left  { opacity:0; transform:translateX(-14px);  transition:opacity .42s cubic-bezier(.22,1,.36,1),transform .42s cubic-bezier(.22,1,.36,1); }
  .reveal-scale { opacity:0; transform:scale(.98);         transition:opacity .38s cubic-bezier(.22,1,.36,1),transform .38s cubic-bezier(.22,1,.36,1); }
  .reveal.visible, .reveal-left.visible, .reveal-scale.visible { opacity:1; transform:none; }
  /* stagger delays */
  .d0{transition-delay:0ms}   .d1{transition-delay:45ms}  .d2{transition-delay:90ms}
  .d3{transition-delay:135ms} .d4{transition-delay:180ms} .d5{transition-delay:225ms}

  /* ── Page enter/exit motion ── */
  body.mgr-motion main {
    opacity: 0;
    transform: translateY(10px) scale(.995);
    filter: blur(1px);
    animation: none !important;         /* suppress manager_head.jsp contentZoomIn */
  }
  body.mgr-motion.mgr-page-ready main {
    opacity: 1;
    transform: translateY(0) scale(1);
    filter: blur(0);
    transition: opacity .34s cubic-bezier(.22,1,.36,1),
                transform .34s cubic-bezier(.22,1,.36,1),
                filter .34s ease;
  }
  body.mgr-page-exiting main {
    opacity: 0 !important;
    transform: translateY(-8px) scale(.992) !important;
    filter: blur(2px) !important;
    transition: opacity .2s ease, transform .2s ease, filter .2s ease !important;
  }

  /* ── Transition scrim overlay ── */
  .mgr-transition-scrim {
    position: fixed;
    inset: 0;
    z-index: 60;
    pointer-events: none;
    background: linear-gradient(180deg, rgba(250,245,255,.72), rgba(243,232,255,.88));
    opacity: 0;
    backdrop-filter: blur(0);
    transition: opacity .2s ease, backdrop-filter .2s ease;
  }
  body.mgr-page-exiting .mgr-transition-scrim {
    opacity: 1;
    backdrop-filter: blur(3px);
  }
  /* Progress line animation on exit */
  .mgr-transition-scrim::after {
    content: '';
    position: absolute;
    left: 248px; right: 0; top: 64px;
    height: 2px;
    background: linear-gradient(90deg, transparent, #7c3aed, #a78bfa, transparent);
    transform: scaleX(0);
    transform-origin: left;
  }
  body.mgr-page-exiting .mgr-transition-scrim::after {
    animation: mgrRouteLine .42s cubic-bezier(.22,1,.36,1) forwards;
  }
  @keyframes mgrRouteLine { to { transform: scaleX(1); } }

  @media (max-width: 1023px) { .mgr-transition-scrim::after { left: 0; } }
  @media (prefers-reduced-motion: reduce) {
    body.mgr-motion main,
    body.mgr-motion.mgr-page-ready main,
    body.mgr-page-exiting main { opacity:1!important; transform:none!important; filter:none!important; transition:none!important; }
    .mgr-transition-scrim { display: none !important; }
  }
</style>

<!-- ═══ SIDEBAR ═══ -->
<aside id="sidebar"
  class="w-[248px] h-screen fixed left-0 top-0 bg-white border-r border-purple-100 z-30 flex flex-col transition-transform duration-300 -translate-x-full lg:translate-x-0">

  <!-- Logo -->
  <div class="px-5 py-4 border-b border-purple-50 flex items-center gap-3">
    <div class="w-9 h-9 rounded-xl bg-gradient-to-br from-purple-600 to-indigo-800 flex items-center justify-center shrink-0 shadow-md shadow-purple-200">
      <i class="ti ti-ball-tennis text-white text-[18px]"></i>
    </div>
    <div>
      <p class="text-sm font-bold text-purple-900 leading-tight tracking-tight">V-SPORT</p>
      <p class="text-[10px] text-purple-500 font-semibold uppercase tracking-wider">Manager Portal</p>
    </div>
  </div>

  <!-- Navigation -->
  <nav class="flex-1 overflow-y-auto px-3 py-4 flex flex-col gap-1">
    <c:set var="uri" value="${pageContext.request.requestURI}" />

    <!-- Tổng quan -->
    <p class="text-[10px] font-bold uppercase tracking-widest text-purple-400 px-3 mb-1.5">Tổng quan</p>
    <a href="${pageContext.request.contextPath}/manager/dashboard"
      class="nav-link ${uri.contains('/manager/dashboard') || uri.contains('/Dashboard.jsp') ? 'active' : ''}">
      <i class="ti ti-layout-dashboard text-[19px]"></i>Tổng quan
    </a>

    <!-- Vận hành sân bãi -->
    <p class="text-[10px] font-bold uppercase tracking-widest text-purple-400 px-3 mt-4 mb-1.5">Vận hành sân bãi</p>
    <a href="${pageContext.request.contextPath}/manager/quan-ly-san"
      class="nav-link ${uri.contains('/manager/quan-ly-san') || uri.contains('/QuanLySan.jsp') ? 'active' : ''}">
      <i class="ti ti-building-stadium text-[19px]"></i>Quản lý sân
    </a>
    <a href="${pageContext.request.contextPath}/staff/checkin"
      class="nav-link ${uri.contains('/staff/checkin') || uri.contains('/CheckIn.jsp') ? 'active' : ''}">
      <i class="ti ti-door-enter text-[19px]"></i>Mở sân / Check-in
    </a>
    <a href="${pageContext.request.contextPath}/manager/dat-san"
      class="nav-link ${uri.contains('/manager/dat-san') || uri.contains('/QuanLyDatSan.jsp') ? 'active' : ''}">
      <i class="ti ti-calendar-check text-[19px]"></i>Duyệt đặt sân
    </a>

    <!-- Kinh doanh & Dịch vụ -->
    <p class="text-[10px] font-bold uppercase tracking-widest text-purple-400 px-3 mt-4 mb-1.5">Kinh doanh &amp; Dịch vụ</p>
    <c:if test="${shopModuleApproved}">
    <a href="${pageContext.request.contextPath}/manager/kho-dich-vu"
      class="nav-link ${uri.contains('/manager/kho-dich-vu') || uri.contains('/KhoDichVu.jsp') ? 'active' : ''}">
      <i class="ti ti-package text-[19px]"></i>Kho &amp; Dịch Vụ
    </a>
    </c:if>
    <c:if test="${serviceModuleApproved}">
    <a href="${pageContext.request.contextPath}/manager/dich-vu"
      class="nav-link ${uri.contains('/manager/dich-vu') ? 'active' : ''}">
      <i class="ti ti-tools text-[19px]"></i>Quản lý dịch vụ
    </a>
    <a href="${pageContext.request.contextPath}/manager/yeu-cau-dich-vu"
      class="nav-link ${uri.contains('/yeu-cau-dich-vu') ? 'active' : ''}">
      <i class="ti ti-clipboard-list text-[19px]"></i>Yêu cầu dịch vụ
    </a>
    </c:if>
    <a href="${pageContext.request.contextPath}/manager/hoa-don"
      class="nav-link ${uri.contains('/manager/hoa-don') || uri.contains('/QuanLyHoaDon.jsp') ? 'active' : ''}">
      <i class="ti ti-receipt text-[19px]"></i>Quản lý hóa đơn
    </a>

    <!-- Nhân sự -->
    <p class="text-[10px] font-bold uppercase tracking-widest text-purple-400 px-3 mt-4 mb-1.5">Quản lý nhân sự</p>
    <a href="${pageContext.request.contextPath}/manager/nhan-su"
      class="nav-link ${uri.contains('/manager/nhan-su') || uri.contains('/NhanSu.jsp') ? 'active' : ''}">
      <i class="ti ti-users-group text-[19px]"></i>Nhân sự
    </a>
    <a href="${pageContext.request.contextPath}/manager/ca-lam"
      class="nav-link ${uri.contains('/manager/ca-lam') || uri.contains('/CaLamViec.jsp') ? 'active' : ''}">
      <i class="ti ti-calendar-time text-[19px]"></i>Lịch làm việc
    </a>

    <!-- Khách hàng -->
    <p class="text-[10px] font-bold uppercase tracking-widest text-purple-400 px-3 mt-4 mb-1.5">Khách hàng</p>
    <a href="${pageContext.request.contextPath}/manager/khach-hang"
      class="nav-link ${uri.contains('/manager/khach-hang') || uri.contains('/KhachHang.jsp') ? 'active' : ''}">
      <i class="ti ti-user text-[19px]"></i>Quản lý khách hàng
    </a>

    <!-- Hệ thống -->
    <p class="text-[10px] font-bold uppercase tracking-widest text-purple-400 px-3 mt-4 mb-1.5">Hệ thống</p>
    <a href="${pageContext.request.contextPath}/manager/thung-rac"
      class="nav-link ${uri.contains('/manager/thung-rac') || uri.contains('/ThungRac.jsp') ? 'active' : ''}">
      <i class="ti ti-trash text-[19px]"></i>Thùng rác
    </a>
    <a href="${pageContext.request.contextPath}/manager/audit-log"
      class="nav-link ${uri.contains('/manager/audit-log') ? 'active' : ''}">
      <i class="ti ti-history text-[19px]"></i>Nhật Ký Thao Tác
    </a>
  </nav>

  <!-- Logout -->
  <div class="px-3 py-3 border-t border-purple-50 shrink-0">
    <a href="${pageContext.request.contextPath}/logout"
      class="nav-link text-red-500 hover:bg-red-50 hover:text-red-600 text-xs font-semibold">
      <i class="ti ti-logout text-[16px] text-red-500"></i>Đăng xuất
    </a>
  </div>
</aside>

<!-- ═══ SIDEBAR JS ═══ -->
<script>
(function () {
  'use strict';

  /* ── 1. Page motion (enter / exit) ── */
  document.body.classList.add('mgr-motion');

  function initPageMotion() {
    var scrim = document.createElement('div');
    scrim.className = 'mgr-transition-scrim';
    document.body.appendChild(scrim);

    /* enter: reveal main on next frame */
    requestAnimationFrame(function () {
      document.body.classList.add('mgr-page-ready');
    });

    /* bfcache restore */
    window.addEventListener('pageshow', function (e) {
      if (e.persisted) {
        document.body.classList.remove('mgr-page-exiting');
        requestAnimationFrame(function () {
          document.body.classList.add('mgr-page-ready');
        });
      }
    });

    /* intercept clicks → exit animation → navigate */
    document.addEventListener('click', function (event) {
      var link = event.target.closest('a[href]');
      if (!link || event.defaultPrevented) return;
      if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button !== 0) return;
      if (link.target && link.target !== '_self') return;
      if (link.hasAttribute('download')) return;

      var href = link.getAttribute('href') || '';
      if (!href || href.charAt(0) === '#' ||
          href.indexOf('javascript:') === 0 ||
          href.indexOf('mailto:') === 0 ||
          href.indexOf('tel:') === 0) return;

      var url;
      try { url = new URL(href, window.location.href); } catch (e) { return; }
      if (url.origin !== window.location.origin) return;
      if (url.pathname === window.location.pathname &&
          url.search === window.location.search &&
          url.hash) return;
      if (url.href === window.location.href) return;

      /* only intercept manager / staff / logout routes */
      var appPath = '${pageContext.request.contextPath}';
      var pathname = url.pathname;
      var isManagerRoute = appPath
        ? (pathname.indexOf(appPath + '/manager') === 0 ||
           pathname.indexOf(appPath + '/staff')   === 0 ||
           pathname.indexOf(appPath + '/logout')  === 0)
        : (pathname.indexOf('/manager') === 0 ||
           pathname.indexOf('/staff')   === 0 ||
           pathname.indexOf('/logout')  === 0);
      if (!isManagerRoute) return;

      event.preventDefault();
      link.classList.add('is-navigating');
      document.body.classList.add('mgr-page-exiting');
      window.setTimeout(function () {
        window.location.href = url.href;
      }, 170);
    });
  }

  /* ── 2. Sidebar open/close (mobile) ── */
  function initSidebar() {
    var sidebar  = document.getElementById('sidebar');
    var overlay  = document.getElementById('sidebarOverlay');
    if (!sidebar) return;

    function open()  { sidebar.classList.remove('-translate-x-full'); if (overlay) overlay.classList.remove('hidden'); }
    function close() { sidebar.classList.add('-translate-x-full');    if (overlay) overlay.classList.add('hidden'); }

    /* toggle buttons: data-sidebar-toggle, #mobileMenuBtn, #sidebarToggle */
    document.querySelectorAll('[data-sidebar-toggle], #mobileMenuBtn, #sidebarToggle').forEach(function (btn) {
      btn.addEventListener('click', function () {
        sidebar.classList.contains('-translate-x-full') ? open() : close();
      });
    });

    if (overlay) overlay.addEventListener('click', close);
    window.addEventListener('resize', function () {
      if (window.innerWidth >= 1024) { if (overlay) overlay.classList.add('hidden'); }
    });
  }

  /* ── 3. Scroll reveal (.reveal, .reveal-left, .reveal-scale, .reveal-on-scroll) ── */
  function initReveal() {
    var els = document.querySelectorAll('.reveal, .reveal-left, .reveal-scale, .reveal-on-scroll');
    if (!els.length) return;
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) {
          e.target.classList.add('visible');
          e.target.classList.add('revealed'); /* compat with reveal-on-scroll */
          io.unobserve(e.target);
        }
      });
    }, { threshold: 0.06, rootMargin: '0px 0px -8px 0px' });
    els.forEach(function (el) { io.observe(el); });
  }

  /* ── 4. 24h time inputs ── */
  function init24hTime() {
    document.querySelectorAll('input[type="time"]').forEach(function (inp) {
      var val   = inp.value || '00:00';
      var parts = val.split(':');
      var initH = parseInt(parts[0] || 0, 10);
      var initM = parseInt(parts[1] || 0, 10);
      var steps = [0, 15, 30, 45];
      var closestM = steps.reduce(function (a, b) { return Math.abs(b - initM) < Math.abs(a - initM) ? b : a; });

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
      steps.forEach(function (m) {
        var o = document.createElement('option');
        o.value = String(m).padStart(2, '0');
        o.textContent = String(m).padStart(2, '0');
        if (m === closestM) o.selected = true;
        mSel.appendChild(o);
      });

      function sync() {
        inp.value = hSel.value + ':' + mSel.value + ':00';
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

  /* ── Boot ── */
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () {
      initPageMotion();
      initSidebar();
      initReveal();
      init24hTime();
    });
  } else {
    initPageMotion();
    initSidebar();
    initReveal();
    init24hTime();
  }
})();
</script>

<!-- ═══ CUSTOM CONFIRM / TOAST (shared across all manager pages) ═══ -->
<div id="customConfirmModal" class="fixed inset-0 z-[100] flex items-center justify-center p-4 hidden">
  <div class="absolute inset-0 bg-black/40 backdrop-blur-sm transition-opacity duration-300" onclick="closeCustomConfirm()"></div>
  <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-[400px] p-6 text-center transform scale-95 transition-all duration-300 border border-purple-100">
    <div class="w-14 h-14 rounded-full bg-purple-50 flex items-center justify-center mx-auto mb-4">
      <i class="ti ti-trash text-[28px] text-purple-600"></i>
    </div>
    <h3 class="text-base font-bold text-zinc-900 mb-2">Xác nhận xóa</h3>
    <p class="text-xs text-zinc-500 mb-6 leading-relaxed px-2" id="customConfirmMessage">Bạn có chắc chắn muốn xóa mục này?</p>
    <div class="flex gap-3 justify-center">
      <button onclick="closeCustomConfirm()"
              class="flex-1 py-2.5 bg-zinc-100 hover:bg-zinc-200 text-zinc-700 rounded-xl text-xs font-semibold transition-all">
        Hủy bỏ
      </button>
      <button id="customConfirmSubmitBtn"
              class="flex-1 py-2.5 bg-purple-600 hover:bg-purple-700 text-white rounded-xl text-xs font-semibold transition-all shadow-md shadow-purple-200">
        Xác nhận xóa
      </button>
    </div>
  </div>
</div>

<script>
  var customConfirmCallback = null;

  function showCustomConfirm(message, callback) {
    document.getElementById('customConfirmMessage').textContent = message;
    customConfirmCallback = callback;
    var modal = document.getElementById('customConfirmModal');
    modal.classList.remove('hidden');
    var box = modal.querySelector('.relative');
    setTimeout(function () { box.classList.remove('scale-95'); box.classList.add('scale-100'); }, 10);
  }

  function closeCustomConfirm() {
    var modal = document.getElementById('customConfirmModal');
    if (!modal) return;
    var box = modal.querySelector('.relative');
    box.classList.remove('scale-100');
    box.classList.add('scale-95');
    setTimeout(function () { modal.classList.add('hidden'); }, 150);
  }

  function showToast(message, type) {
    type = type || 'success';
    var container = document.getElementById('global-toast-container');
    if (!container) {
      container = document.createElement('div');
      container.id = 'global-toast-container';
      container.className = 'fixed bottom-5 right-5 z-[200] flex flex-col gap-2 max-w-sm w-full';
      document.body.appendChild(container);
    }
    var toast = document.createElement('div');
    var bg = 'bg-purple-50 border border-purple-150 text-purple-900';
    var icon = 'check_circle';
    var iconColor = 'text-purple-600';
    if (type === 'error') {
      bg = 'bg-red-50 border border-red-200 text-red-900';
      icon = 'error';
      iconColor = 'text-red-600';
    } else if (type === 'info') {
      bg = 'bg-blue-50 border border-blue-200 text-blue-900';
      icon = 'info';
      iconColor = 'text-blue-600';
    }
    toast.className = 'p-4 rounded-xl shadow-lg text-xs font-semibold flex items-center gap-3 transition-all duration-300 transform translate-y-2 opacity-0 ' + bg;
    toast.innerHTML = '<span class="material-symbols-outlined ' + iconColor + ' text-[20px] shrink-0" style="font-variation-settings:\'FILL\' 1">' + icon + '</span>'
                    + '<div class="flex-1">' + message + '</div>';
    container.appendChild(toast);
    setTimeout(function () { toast.classList.remove('translate-y-2', 'opacity-0'); }, 10);
    setTimeout(function () {
      toast.classList.add('translate-y-2', 'opacity-0');
      setTimeout(function () { toast.remove(); }, 300);
    }, 4000);
  }

  document.addEventListener('DOMContentLoaded', function () {
    var submitBtn = document.getElementById('customConfirmSubmitBtn');
    if (submitBtn) {
      submitBtn.addEventListener('click', function () {
        if (customConfirmCallback) customConfirmCallback();
        closeCustomConfirm();
      });
    }
  });
</script>
