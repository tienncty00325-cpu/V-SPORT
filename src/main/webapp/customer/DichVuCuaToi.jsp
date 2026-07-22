<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<jsp:include page="/common/xtra-head.jsp" />
<style>
  .account-wrapper { padding: 60px 0; background-color: var(--background); }
  .account-container { display:flex; gap:30px; width:100%; max-width:1200px; margin:0 auto; padding:0 20px; }
  .account-sidebar { width:280px; flex-shrink:0; }
  .account-main { flex:1; min-width:0; }
  .profile-card { background: var(--surface); border-radius: var(--radius-medium); padding:25px; text-align:center; box-shadow: var(--shadow-small); margin-bottom:20px; }
  .profile-avatar { width:80px; height:80px; border-radius:50%; background: var(--primary); color:#fff; display:flex; align-items:center; justify-content:center; font-size:32px; font-weight:700; margin:0 auto 15px; }
  .profile-name { font-size:20px; font-weight:700; color: var(--navy); margin-bottom:5px; }
  .profile-email { font-size:14px; color: var(--muted-text); margin-bottom:15px; }
  .profile-rep { background:#eafff5; color:#0a7a4e; border-radius:999px; padding:6px 14px; font-size:13px; font-weight:700; display:inline-block; }
  .menu-card { background: var(--surface); border-radius: var(--radius-medium); box-shadow: var(--shadow-small); overflow:hidden; }
  .menu-item { display:flex; align-items:center; gap:12px; padding:14px 20px; color: var(--body-text); text-decoration:none; font-size:14.5px; font-weight:600; border-bottom:1px solid var(--border); transition: var(--transition); }
  .menu-item:last-child { border-bottom:none; }
  .menu-item:hover { background:#f8f9fa; }
  .menu-item.active { background:#eafff5; color: var(--navy); border-left:3px solid var(--primary); }
  .menu-item i { width:18px; text-align:center; color: var(--primary); }
  .menu-item.danger i { color: var(--danger); }
  .menu-item.danger:hover { background:#fff5f5; }

  .dvct-title { font-size:24px; font-weight:800; color: var(--navy); margin:0 0 4px; }
  .dvct-subtitle { color: var(--body-text); font-size:14px; margin:0 0 20px; }
  .dvct-stats { display:grid; grid-template-columns:repeat(3,1fr); gap:14px; margin-bottom:20px; }
  .dvct-stat { background: var(--surface); border:1px solid var(--border); border-radius: var(--radius-medium); padding:16px; box-shadow: var(--shadow-small); }
  .dvct-stat .num { font-size:24px; font-weight:800; color: var(--navy); }
  .dvct-stat .label { font-size:12.5px; color: var(--muted-text); margin-top:2px; }

  .dvct-tabs { display:flex; gap:4px; overflow-x:auto; border-bottom:1px solid var(--border); margin-bottom:16px; }
  .dvct-tab { padding:9px 14px; font-size:13px; font-weight:700; color: var(--muted-text); cursor:pointer; white-space:nowrap; border-bottom:2px solid transparent; display:flex; align-items:center; gap:6px; }
  .dvct-tab.active { color: var(--navy); border-bottom-color: var(--primary); }
  .dvct-tab-count { background:#f1f5f9; color: var(--body-text); font-size:11px; font-weight:800; padding:1px 7px; border-radius:999px; }
  .dvct-tab.active .dvct-tab-count { background: var(--navy); color:#fff; }

  .dvct-filters { display:flex; gap:8px; flex-wrap:wrap; margin-bottom:18px; align-items:end; }
  .dvct-filters .field { display:flex; flex-direction:column; gap:4px; }
  .dvct-filters label { font-size:11px; font-weight:700; color: var(--muted-text); }
  .dvct-filters input { border:1px solid var(--border); border-radius:10px; padding:8px 10px; font-size:13px; }
  .dvct-btn { padding:8px 16px; border-radius:10px; font-size:13px; font-weight:700; border:1px solid var(--border); background: var(--surface); cursor:pointer; }
  .dvct-btn-primary { background: var(--navy); color:#fff; border-color: var(--navy); }

  .dvct-card { background: var(--surface); border:1px solid var(--border); border-radius: var(--radius-medium); padding:16px 18px; margin-bottom:12px; cursor:pointer; transition: var(--transition); }
  .dvct-card:hover { box-shadow: var(--shadow-medium); }
  .dvct-card.ready { border-color:#86efac; background:#f0fdf4; }
  .dvct-badge { display:inline-flex; font-size:11px; font-weight:800; padding:2px 9px; border-radius:999px; }
  .b-pending { background:#fef3c7; color:#92400e; }
  .b-confirmed { background:#dbeafe; color:#1d4ed8; }
  .b-progress { background:#e0e7ff; color:#4338ca; }
  .b-ready { background:#dcfce7; color:#166534; }
  .b-done { background:#f1f5f9; color:#475569; }
  .b-cancel { background:#fee2e2; color:#b91c1c; }
  .dvct-booking-badge { display:inline-flex; align-items:center; gap:4px; font-size:11px; font-weight:700; color: var(--navy); background:#f1f5f9; padding:2px 9px; border-radius:999px; }

  .dvct-skeleton { background: var(--surface); border:1px solid var(--border); border-radius: var(--radius-medium); padding:16px 18px; margin-bottom:12px; height:76px; }
  .dvct-skeleton .sk-line { background:#eef1f4; border-radius:6px; height:12px; margin-bottom:8px; animation: sk-pulse 1.2s ease-in-out infinite; }
  @keyframes sk-pulse { 0%,100%{opacity:1;} 50%{opacity:.5;} }

  .dvct-empty { text-align:center; padding:60px 20px; }
  .dvct-empty i { font-size:40px; color: var(--muted-text); opacity:.4; margin-bottom:12px; }
  .dvct-empty p { color: var(--body-text); margin:4px 0; }
  .dvct-empty .desc { color: var(--muted-text); font-size:13px; }

  .dvct-pagination { display:flex; justify-content:center; gap:8px; margin-top:16px; }
  .dvct-page-btn { width:34px; height:34px; border-radius:8px; border:1px solid var(--border); background:#fff; cursor:pointer; font-size:13px; font-weight:700; }
  .dvct-page-btn.active { background: var(--navy); color:#fff; border-color: var(--navy); }
  .dvct-page-btn:disabled { opacity:.4; cursor:not-allowed; }

  .dvct-overlay { position:fixed; inset:0; background:rgba(18,45,64,.5); z-index:80; display:none; }
  .dvct-overlay.open { display:block; }
  .dvct-drawer { position:fixed; top:0; right:0; height:100vh; width:100%; max-width:600px; background:#fff; z-index:81;
    transform:translateX(100%); transition:transform .25s ease; overflow-y:auto; box-shadow:-10px 0 30px rgba(0,0,0,.15); display:flex; flex-direction:column; }
  .dvct-drawer.open { transform:translateX(0); }
  .dvct-sec-label { font-size:11px; font-weight:800; color: var(--muted-text); text-transform:uppercase; letter-spacing:.03em; margin:14px 0 6px; }
  .dvct-row { display:flex; justify-content:space-between; font-size:13.5px; padding:6px 0; border-bottom:1px dashed var(--border); gap:12px; }
  .dvct-row span:first-child { color: var(--body-text); flex-shrink:0; }
  .dvct-row span:last-child { font-weight:700; color: var(--navy); text-align:right; }
  .dvct-tl-item { display:flex; gap:10px; padding:6px 0; font-size:12.5px; }
  .dvct-tl-dot { width:8px; height:8px; border-radius:999px; background: var(--primary); margin-top:5px; flex-shrink:0; }
  .dvct-tl-dot.future { background:#e2e8f0; }
  .dvct-action-bar { border-top:1px solid var(--border); padding:14px 20px; display:flex; gap:8px; position:sticky; bottom:0; background:#fff; }
  .dvct-act-btn { flex:1; padding:11px; border-radius:10px; font-weight:800; font-size:13.5px; border:none; cursor:pointer; }
  .dvct-act-danger { background:#fef2f2; color: var(--danger); }

  .dvct-modal-overlay { position:fixed; inset:0; background:rgba(18,45,64,.5); z-index:90; display:none; align-items:center; justify-content:center; }
  .dvct-modal-overlay.open { display:flex; }
  .dvct-modal-box { background:#fff; border-radius:16px; padding:22px; width:100%; max-width:420px; margin:16px; }
  .dvct-modal-box textarea { width:100%; border:1px solid var(--border); border-radius:10px; padding:8px 10px; font-size:13.5px; }

  @media (max-width: 1024px) { .account-container { flex-direction:column; } .account-sidebar { width:100%; } .dvct-stats { grid-template-columns:1fr; } }
  @media (max-width: 768px) { .dvct-drawer { max-width:100%; } }
</style>

<jsp:include page="/common/header-xtra.jsp" />

<div class="account-wrapper">
  <div class="account-container">
    <aside class="account-sidebar">
      <div class="profile-card">
        <div class="profile-avatar">
          <c:choose>
            <c:when test="${not empty sessionScope.user.fullName}">${fn:escapeXml(fn:substring(sessionScope.user.fullName, 0, 1).toUpperCase())}</c:when>
            <c:otherwise>${fn:escapeXml(fn:substring(sessionScope.user.username, 0, 1).toUpperCase())}</c:otherwise>
          </c:choose>
        </div>
        <div class="profile-name">${fn:escapeXml(not empty sessionScope.user.fullName ? sessionScope.user.fullName : sessionScope.user.username)}</div>
        <div class="profile-email">${not empty sessionScope.user.email ? fn:escapeXml(sessionScope.user.email) : 'Chưa cập nhật email'}</div>
        <div class="profile-rep"><i class="fas fa-star" style="margin-right:5px;"></i> Uy tín: ${sessionScope.user.diemUyTin}/100</div>
      </div>
      <div class="menu-card">
        <a href="${pageContext.request.contextPath}/customer/tai-khoan" class="menu-item"><i class="fas fa-home"></i> Tổng quan</a>
        <a href="${pageContext.request.contextPath}/customer/ghep-keo?tab=cua-toi" class="menu-item"><i class="fas fa-futbol"></i> Kèo của tôi</a>
        <a href="${pageContext.request.contextPath}/customer/dich-vu-cua-toi" class="menu-item active"><i class="fas fa-screwdriver-wrench"></i> Dịch vụ của tôi</a>
        <a href="${pageContext.request.contextPath}/customer/doi-nhom" class="menu-item"><i class="fas fa-users"></i> Nhóm của tôi</a>
        <a href="${pageContext.request.contextPath}/customer/doi-mat-khau" class="menu-item"><i class="fas fa-lock"></i> Đổi mật khẩu</a>
        <a href="${pageContext.request.contextPath}/customer/notification-settings" class="menu-item"><i class="fas fa-bell"></i> Cài đặt thông báo</a>
        <a href="${pageContext.request.contextPath}/logout" class="menu-item danger"><i class="fas fa-sign-out-alt"></i> Đăng xuất</a>
      </div>
    </aside>

    <main class="account-main">
      <h1 class="dvct-title">Dịch vụ của tôi</h1>
      <p class="dvct-subtitle">Theo dõi các yêu cầu dịch vụ, thời gian xử lý và trạng thái nhận dụng cụ tại cơ sở.</p>

      <section class="dvct-stats">
        <div class="dvct-stat"><div class="num" id="statPending">—</div><div class="label">Đang chờ xác nhận</div></div>
        <div class="dvct-stat"><div class="num" id="statProgress">—</div><div class="label">Đang xử lý</div></div>
        <div class="dvct-stat"><div class="num" id="statReady">—</div><div class="label">Sẵn sàng nhận</div></div>
      </section>

      <div class="dvct-tabs" id="dvctTabs" role="tablist">
        <div class="dvct-tab active" data-group="tat-ca" role="tab">Tất cả <span class="dvct-tab-count" id="cnt-tat-ca">0</span></div>
        <div class="dvct-tab" data-group="cho-xac-nhan" role="tab">Chờ xác nhận <span class="dvct-tab-count" id="cnt-cho-xac-nhan">0</span></div>
        <div class="dvct-tab" data-group="da-xac-nhan" role="tab">Đã xác nhận <span class="dvct-tab-count" id="cnt-da-xac-nhan">0</span></div>
        <div class="dvct-tab" data-group="dang-xu-ly" role="tab">Đang xử lý <span class="dvct-tab-count" id="cnt-dang-xu-ly">0</span></div>
        <div class="dvct-tab" data-group="san-sang" role="tab">Sẵn sàng nhận <span class="dvct-tab-count" id="cnt-san-sang">0</span></div>
        <div class="dvct-tab" data-group="hoan-thanh" role="tab">Hoàn thành <span class="dvct-tab-count" id="cnt-hoan-thanh">0</span></div>
        <div class="dvct-tab" data-group="da-huy" role="tab">Đã hủy <span class="dvct-tab-count" id="cnt-da-huy">0</span></div>
      </div>

      <div class="dvct-filters">
        <div class="field"><label>Mã đơn</label><input type="text" id="f_q" placeholder="VD: DV000012"/></div>
        <div class="field"><label>Từ ngày</label><input type="date" id="f_from"/></div>
        <div class="field"><label>Đến ngày</label><input type="date" id="f_to"/></div>
        <button class="dvct-btn dvct-btn-primary" onclick="applyServiceOrderFilters()">Lọc</button>
        <button class="dvct-btn" onclick="clearServiceOrderFilters()">Xóa lọc</button>
      </div>

      <div id="dvctList"></div>
      <div id="dvctPagination" class="dvct-pagination"></div>
    </main>
  </div>
</div>

<%-- ═══ DRAWER CHI TIẾT ═══ --%>
<div class="dvct-overlay" id="dvctOverlay" onclick="closeServiceOrderDrawer()"></div>
<div class="dvct-drawer" id="dvctDrawer" role="dialog" aria-modal="true" aria-label="Chi tiết đơn dịch vụ">
  <div style="display:flex;align-items:center;justify-content:space-between;padding:18px 20px;border-bottom:1px solid var(--border);">
    <h3 id="dvctDrawerTitle" style="font-weight:800;font-size:17px;color:var(--navy);margin:0;">Chi tiết đơn</h3>
    <button type="button" onclick="closeServiceOrderDrawer()" aria-label="Đóng" style="border:none;background:none;font-size:20px;cursor:pointer;color:var(--muted-text);">
      <i class="fa-solid fa-xmark"></i>
    </button>
  </div>
  <div style="flex:1;overflow-y:auto;padding:6px 20px 20px;" id="dvctDrawerBody"></div>
  <div class="dvct-action-bar" id="dvctActionBar" style="display:none;"></div>
</div>

<%-- ═══ MODAL HỦY ═══ --%>
<div class="dvct-modal-overlay" id="dvctCancelModal">
  <div class="dvct-modal-box">
    <h3 style="font-weight:800;font-size:17px;margin:0 0 4px;">Hủy yêu cầu dịch vụ</h3>
    <p style="font-size:12.5px;color:var(--muted-text);margin:0 0 12px;">Yêu cầu sẽ bị hủy và không thể hoàn tác. Cơ sở sẽ được thông báo.</p>
    <label style="font-size:12px;font-weight:700;color:var(--body-text);display:block;margin-bottom:4px;">Lý do hủy *</label>
    <textarea id="dvctCancelReason" rows="3" placeholder="VD: Tôi đổi lịch, không cần dịch vụ nữa..."></textarea>
    <div id="dvctCancelError" style="color:#c0392b;font-size:12.5px;display:none;margin-top:6px;"></div>
    <div style="display:flex;gap:8px;margin-top:14px;">
      <button type="button" class="dvct-act-btn" style="flex:1;padding:11px;border-radius:10px;border:1px solid var(--border);background:#fff;font-weight:700;cursor:pointer;" onclick="closeCancelModal()">Giữ lại yêu cầu</button>
      <button type="button" class="dvct-act-btn dvct-act-danger" onclick="submitCancelServiceOrder()">Xác nhận hủy</button>
    </div>
  </div>
</div>

<script>
  var ctxPath = '${pageContext.request.contextPath}';
  var currentGroup = 'tat-ca';
  var currentPage = 1;
  var currentOrderId = null;
  var listAbortController = null;
  var cancelInFlight = false;

  function fmtMoney(v) { return (v === null || v === undefined) ? null : Number(v).toLocaleString('vi-VN') + 'đ'; }
  function escapeHtml(s) { if (s === null || s === undefined) return ''; var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }
  function fmtDateTime(s) { return s ? s.replace('T', ' ').substring(0, 16) : null; }

  function statusBadge(status) {
    switch (status) {
      case 'PENDING_CONFIRMATION': return '<span class="dvct-badge b-pending">Chờ xác nhận</span>';
      case 'CONFIRMED': return '<span class="dvct-badge b-confirmed">Đã xác nhận</span>';
      case 'ITEM_RECEIVED': return '<span class="dvct-badge b-confirmed">Cơ sở đã nhận đồ</span>';
      case 'IN_PROGRESS': return '<span class="dvct-badge b-progress">Đang xử lý</span>';
      case 'READY_FOR_PICKUP': return '<span class="dvct-badge b-ready">Sẵn sàng nhận</span>';
      case 'COMPLETED': return '<span class="dvct-badge b-done">Hoàn thành</span>';
      case 'REJECTED': return '<span class="dvct-badge b-cancel">Từ chối</span>';
      case 'CANCELLED': return '<span class="dvct-badge b-cancel">Đã hủy</span>';
      default: return status;
    }
  }

  function priceLine(item) {
    if (item.confirmedPrice != null) {
      if (item.estimatedPrice != null && Math.abs(item.confirmedPrice - item.estimatedPrice) > 0.5) {
        return 'Đã xác nhận ' + fmtMoney(item.confirmedPrice) + ' <span style="color:var(--muted-text);font-weight:500;">(dự kiến ' + fmtMoney(item.estimatedPrice) + ')</span>';
      }
      return 'Đã xác nhận ' + fmtMoney(item.confirmedPrice);
    }
    if (item.estimatedPrice != null) return 'Dự kiến ' + fmtMoney(item.estimatedPrice);
    return '—';
  }

  function loadServiceOrders() {
    if (listAbortController) listAbortController.abort();
    listAbortController = new AbortController();

    var list = document.getElementById('dvctList');
    list.innerHTML = skeletonHtml(3);
    document.getElementById('dvctPagination').innerHTML = '';

    var p = new URLSearchParams();
    p.set('group', currentGroup);
    p.set('page', currentPage);
    p.set('pageSize', 10);
    var q = document.getElementById('f_q').value.trim();
    var from = document.getElementById('f_from').value;
    var to = document.getElementById('f_to').value;
    if (q) p.set('q', q);
    if (from) p.set('dateFrom', from);
    if (to) p.set('dateTo', to);

    fetch(ctxPath + '/api/customer/dich-vu-cua-toi?' + p.toString(), { signal: listAbortController.signal })
      .then(function(r) {
        if (r.status === 401) { window.location.href = ctxPath + '/he-thong/dang-nhap'; return null; }
        return r.json();
      })
      .then(function(data) {
        if (!data) return;
        if (!data.success) { renderError(); return; }
        refreshServiceOrderCounts(data.counts);
        renderList(data.items || []);
        renderPagination(data.page, data.totalPages);
      })
      .catch(function(err) {
        if (err.name === 'AbortError') return;
        renderError();
      });
  }

  function skeletonHtml(n) {
    var h = '';
    for (var i = 0; i < n; i++) {
      h += '<div class="dvct-skeleton"><div class="sk-line" style="width:40%;"></div><div class="sk-line" style="width:70%;"></div><div class="sk-line" style="width:30%;"></div></div>';
    }
    return h;
  }

  function renderError() {
    document.getElementById('dvctList').innerHTML =
      '<div class="dvct-empty"><i class="fa-solid fa-triangle-exclamation"></i>' +
      '<p>Không thể tải danh sách dịch vụ của bạn.</p>' +
      '<button class="dvct-btn dvct-btn-primary" onclick="loadServiceOrders()">Thử lại</button></div>';
  }

  function renderList(items) {
    var list = document.getElementById('dvctList');
    if (!items.length) {
      var isFiltered = currentGroup !== 'tat-ca' || document.getElementById('f_q').value || document.getElementById('f_from').value;
      list.innerHTML = isFiltered
        ? '<div class="dvct-empty"><i class="fa-solid fa-filter-circle-xmark"></i><p>Không tìm thấy đơn dịch vụ phù hợp với bộ lọc hiện tại.</p></div>'
        : '<div class="dvct-empty"><i class="fa-solid fa-clipboard-list"></i><p>Bạn chưa có yêu cầu dịch vụ nào.</p>' +
          '<p class="desc">Khám phá các cơ sở có dịch vụ căng lưới, thay quấn cán và hỗ trợ dụng cụ thể thao.</p>' +
          '<a href="' + ctxPath + '/customer/dich-vu" class="dvct-btn dvct-btn-primary" style="display:inline-block;margin-top:10px;text-decoration:none;">Khám phá dịch vụ</a></div>';
      return;
    }
    list.innerHTML = '';
    items.forEach(function(item) {
      var card = document.createElement('div');
      card.className = 'dvct-card' + (item.status === 'READY_FOR_PICKUP' ? ' ready' : '');
      card.onclick = function() { openServiceOrderDrawer(item.orderId); };
      var bookingBadge = item.bookingId
        ? '<span class="dvct-booking-badge"><i class="fa-solid fa-calendar-check"></i> Đi kèm lịch đặt #' + item.bookingId + '</span>' : '';
      card.innerHTML =
        '<div style="display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap;">' +
          '<div style="min-width:0;">' +
            '<div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin-bottom:4px;">' +
              '<span style="font-weight:800;font-size:13.5px;color:var(--navy);">' + escapeHtml(item.displayCode) + '</span>' +
              statusBadge(item.status) + bookingBadge +
            '</div>' +
            '<p style="font-size:13.5px;color:var(--body-text);margin:0;">' + escapeHtml(item.serviceName) + ' · ' + escapeHtml(item.coSoName) + '</p>' +
            '<p style="font-size:12px;color:var(--muted-text);margin:4px 0 0;">Gửi yêu cầu: ' + fmtDateTime(item.requestedAt) + ' · Mang đến: ' + (item.appointmentDate || '—') + '</p>' +
          '</div>' +
          '<div style="text-align:right;flex-shrink:0;">' +
            '<p style="font-weight:800;font-size:13.5px;color:var(--navy);margin:0;">' + priceLine(item) + '</p>' +
            '<button class="dvct-btn" style="margin-top:8px;font-size:12px;padding:6px 12px;" onclick="event.stopPropagation();openServiceOrderDrawer(' + item.orderId + ')">Xem chi tiết</button>' +
          '</div>' +
        '</div>';
      list.appendChild(card);
    });
  }

  function refreshServiceOrderCounts(counts) {
    var total = 0;
    Object.keys(counts).forEach(function(k) {
      total += counts[k];
      var el = document.getElementById('cnt-' + k);
      if (el) el.textContent = counts[k];
    });
    document.getElementById('cnt-tat-ca').textContent = total;
    document.getElementById('statPending').textContent = counts['cho-xac-nhan'] || 0;
    document.getElementById('statProgress').textContent = counts['dang-xu-ly'] || 0;
    document.getElementById('statReady').textContent = counts['san-sang'] || 0;
  }

  function renderPagination(page, totalPages) {
    var el = document.getElementById('dvctPagination');
    el.innerHTML = '';
    if (totalPages <= 1) return;
    var prev = document.createElement('button');
    prev.className = 'dvct-page-btn'; prev.textContent = '‹'; prev.disabled = page <= 1;
    prev.onclick = function() { currentPage = page - 1; loadServiceOrders(); };
    el.appendChild(prev);
    for (var i = 1; i <= totalPages; i++) {
      var btn = document.createElement('button');
      btn.className = 'dvct-page-btn' + (i === page ? ' active' : '');
      btn.textContent = i;
      btn.onclick = (function(pg) { return function() { currentPage = pg; loadServiceOrders(); }; })(i);
      el.appendChild(btn);
    }
    var next = document.createElement('button');
    next.className = 'dvct-page-btn'; next.textContent = '›'; next.disabled = page >= totalPages;
    next.onclick = function() { currentPage = page + 1; loadServiceOrders(); };
    el.appendChild(next);
  }

  document.querySelectorAll('.dvct-tab').forEach(function(tab) {
    tab.addEventListener('click', function() {
      document.querySelectorAll('.dvct-tab').forEach(function(t) { t.classList.remove('active'); });
      tab.classList.add('active');
      currentGroup = tab.dataset.group;
      currentPage = 1;
      loadServiceOrders();
    });
  });

  function applyServiceOrderFilters() { currentPage = 1; loadServiceOrders(); }
  function clearServiceOrderFilters() {
    document.getElementById('f_q').value = '';
    document.getElementById('f_from').value = '';
    document.getElementById('f_to').value = '';
    currentPage = 1;
    loadServiceOrders();
  }

  var lastFocusedCard = null;
  function openServiceOrderDrawer(orderId) {
    currentOrderId = orderId;
    lastFocusedCard = document.activeElement;
    fetch(ctxPath + '/api/customer/dich-vu-cua-toi?action=detail&orderId=' + orderId)
      .then(function(r) { return r.json(); })
      .then(function(data) {
        if (!data.success) { alert(data.message || 'Không tải được chi tiết đơn.'); return; }
        renderServiceOrderDetail(data.order);
        document.getElementById('dvctOverlay').classList.add('open');
        document.getElementById('dvctDrawer').classList.add('open');
        document.body.style.overflow = 'hidden';
        document.getElementById('dvctDrawer').focus();
      });
  }
  function closeServiceOrderDrawer() {
    document.getElementById('dvctOverlay').classList.remove('open');
    document.getElementById('dvctDrawer').classList.remove('open');
    document.body.style.overflow = '';
    if (lastFocusedCard) lastFocusedCard.focus();
  }

  function drow(label, value) {
    if (value === null || value === undefined || value === '') return '';
    return '<div class="dvct-row"><span>' + label + '</span><span>' + value + '</span></div>';
  }
  function drowText(label, value) { return drow(label, value != null ? escapeHtml(String(value)) : null); }

  var TIMELINE_CONTENT = {
    PENDING_CONFIRMATION: { title: 'Đã gửi yêu cầu', desc: 'Cơ sở đang kiểm tra thông tin và khả năng tiếp nhận dịch vụ.' },
    CONFIRMED: { title: 'Cơ sở đã xác nhận', desc: 'Giá và thời gian hoàn thành dự kiến đã được xác nhận.' },
    ITEM_RECEIVED: { title: 'Cơ sở đã nhận dụng cụ', desc: 'Dụng cụ của bạn đã được bàn giao cho cơ sở.' },
    IN_PROGRESS: { title: 'Đang thực hiện dịch vụ', desc: 'Kỹ thuật viên đang xử lý yêu cầu của bạn.' },
    READY_FOR_PICKUP: { title: 'Sẵn sàng nhận', desc: 'Dịch vụ đã hoàn thành. Bạn có thể đến cơ sở để nhận dụng cụ.' },
    COMPLETED: { title: 'Đã hoàn thành', desc: 'Bạn đã nhận lại dụng cụ và đơn dịch vụ đã kết thúc.' },
    REJECTED: { title: 'Cơ sở không thể tiếp nhận', desc: '' },
    CANCELLED: { title: 'Đơn đã hủy', desc: '' }
  };
  var TIMELINE_ORDER = ['PENDING_CONFIRMATION', 'CONFIRMED', 'ITEM_RECEIVED', 'IN_PROGRESS', 'READY_FOR_PICKUP', 'COMPLETED'];

  function renderServiceOrderTimeline(order) {
    var reached = {};
    (order.timeline || []).forEach(function(t) { reached[t.toStatus] = t; });
    var html = '';

    if (order.status === 'REJECTED' || order.status === 'CANCELLED') {
      var t = TIMELINE_CONTENT[order.status];
      var actorTxt = order.cancellationReason ? escapeHtml(order.cancellationReason) : '';
      html += '<div class="dvct-tl-item"><div class="dvct-tl-dot"></div><div><div style="font-weight:700;">' + t.title + '</div>' +
        (actorTxt ? '<div style="color:var(--muted-text);">' + actorTxt + '</div>' : '') + '</div></div>';
      return html;
    }

    TIMELINE_ORDER.forEach(function(status) {
      var hit = reached[status];
      var content = TIMELINE_CONTENT[status];
      var dotClass = hit ? 'dvct-tl-dot' : 'dvct-tl-dot future';
      var textColor = hit ? '' : 'color:var(--muted-text);';
      html += '<div class="dvct-tl-item"><div class="' + dotClass + '"></div><div>' +
        '<div style="font-weight:700;' + textColor + '">' + content.title + '</div>' +
        '<div style="color:var(--muted-text);font-size:11.5px;">' + (hit ? fmtDateTime(hit.changedAt) : content.desc) + '</div>' +
        '</div></div>';
    });
    return html;
  }

  function renderServiceOrderDetail(o) {
    document.getElementById('dvctDrawerTitle').textContent = o.displayCode;
    var html = '';

    html += '<div class="dvct-row"><span>Trạng thái</span><span>' + statusBadge(o.status) + '</span></div>';
    html += drowText('Ngày gửi yêu cầu', fmtDateTime(o.requestedAt));
    if (o.bookingId) html += drow('Booking liên quan', '<span class="dvct-booking-badge">#' + o.bookingId + '</span>');

    if (o.status === 'READY_FOR_PICKUP') {
      html += '<div style="background:#f0fdf4;border:1px solid #86efac;border-radius:12px;padding:12px 14px;margin:10px 0;">' +
        '<p style="font-weight:800;color:#166534;margin:0 0 4px;">Dụng cụ đã sẵn sàng</p>' +
        (o.coSoAddress ? '<p style="font-size:12.5px;color:#166534;margin:2px 0;"><i class="fa-solid fa-location-dot"></i> ' + escapeHtml(o.coSoAddress) + '</p>' : '') +
        (o.coSoGioMoCua ? '<p style="font-size:12.5px;color:#166534;margin:2px 0;"><i class="fa-solid fa-clock"></i> ' + o.coSoGioMoCua + ' - ' + o.coSoGioDongCua + '</p>' : '') +
        '<a href="' + ctxPath + '/customer/BanDo.jsp" style="font-size:12.5px;font-weight:700;color:#166534;">Xem chỉ đường →</a></div>';
    }

    html += '<div class="dvct-sec-label">Dịch vụ</div>';
    html += drowText('Dịch vụ', o.serviceName);
    html += drowText('Cơ sở', o.coSoName);
    html += drowText('Địa chỉ', o.coSoAddress);
    html += drowText('Điện thoại', o.coSoPhone);

    if (o.racketDetail) {
      var rd = o.racketDetail;
      html += '<div class="dvct-sec-label">Thông số căng lưới</div>';
      html += drowText('Loại vợt', rd.racketType);
      html += drowText('Thương hiệu', rd.racketBrand);
      html += drowText('Model', rd.racketModel);
      html += drowText('Mức căng', rd.tensionValue ? (rd.tensionValue + ' ' + rd.tensionUnit) : null);
      html += drowText('Màu dây', rd.stringColor);
      html += drowText('Số lượng', rd.quantity);
      html += drowText('Tự mang dây', rd.customerBringsString ? 'Có' : 'Không');
      if (rd.materialName) html += drowText('Loại dây', rd.materialName + ' (' + fmtMoney(rd.materialPrice) + ')');
    }

    html += '<div class="dvct-sec-label">Lịch hẹn</div>';
    html += drowText('Ngày mang đến', o.appointmentDate);
    html += drowText('Khung giờ mang đến', o.dropOffTime);
    html += drowText('Thời gian dự kiến nhận', fmtDateTime(o.expectedPickupTime));
    html += drowText('Cơ sở đã nhận lúc', fmtDateTime(o.actualReceivedTime));
    html += drowText('Sẵn sàng nhận lúc', fmtDateTime(o.completedTime));

    html += '<div class="dvct-sec-label">Giá</div>';
    if (o.priceChanged) {
      html += '<div style="background:#fffbeb;border:1px solid #fde68a;border-radius:10px;padding:8px 12px;margin-bottom:6px;font-size:12.5px;color:#92400e;font-weight:700;">Giá đã được cơ sở cập nhật</div>';
    }
    html += drowText('Giá dự kiến', fmtMoney(o.estimatedPrice));
    html += drow('Giá xác nhận', o.confirmedPrice != null ? fmtMoney(o.confirmedPrice) : 'Chưa xác nhận');

    if (o.customerNote || o.cancellationReason) {
      html += '<div class="dvct-sec-label">Ghi chú</div>';
      html += drowText('Ghi chú của bạn', o.customerNote);
      if (o.cancellationReason) {
        html += drowText(o.status === 'REJECTED' ? 'Lý do từ chối' : 'Lý do hủy', o.cancellationReason);
      }
    }

    html += '<div class="dvct-sec-label">Timeline</div>';
    html += renderServiceOrderTimeline(o);

    document.getElementById('dvctDrawerBody').innerHTML = html;

    var bar = document.getElementById('dvctActionBar');
    if (o.cancellable) {
      bar.style.display = 'flex';
      bar.innerHTML = '<button class="dvct-act-btn dvct-act-danger" style="flex:1;" onclick="openCancelServiceOrderModal()">Hủy yêu cầu dịch vụ</button>';
    } else {
      bar.style.display = 'none';
      bar.innerHTML = '';
    }
  }

  function openCancelServiceOrderModal() {
    document.getElementById('dvctCancelReason').value = '';
    document.getElementById('dvctCancelError').style.display = 'none';
    document.getElementById('dvctCancelModal').classList.add('open');
  }
  function closeCancelModal() { document.getElementById('dvctCancelModal').classList.remove('open'); }

  function submitCancelServiceOrder() {
    if (cancelInFlight) return;
    var reason = document.getElementById('dvctCancelReason').value;
    var err = document.getElementById('dvctCancelError');
    if (!reason || !reason.trim()) {
      err.textContent = 'Vui lòng nhập lý do hủy.';
      err.style.display = 'block';
      return;
    }
    cancelInFlight = true;
    var p = new URLSearchParams();
    p.set('orderId', currentOrderId);
    p.set('reason', reason);
    fetch(ctxPath + '/api/customer/dich-vu-cua-toi/huy', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: p.toString()
    })
      .then(function(r) { return r.json().then(function(data) { return { status: r.status, data: data }; }); })
      .then(function(res) {
        cancelInFlight = false;
        if (res.data.success) {
          closeCancelModal();
          closeServiceOrderDrawer();
          loadServiceOrders();
        } else {
          err.textContent = res.data.message || 'Không thể hủy đơn.';
          err.style.display = 'block';
        }
      })
      .catch(function() {
        cancelInFlight = false;
        err.textContent = 'Lỗi kết nối. Vui lòng thử lại.';
        err.style.display = 'block';
      });
  }

  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
      if (document.getElementById('dvctCancelModal').classList.contains('open')) closeCancelModal();
      else closeServiceOrderDrawer();
    }
  });

  loadServiceOrders();
</script>
