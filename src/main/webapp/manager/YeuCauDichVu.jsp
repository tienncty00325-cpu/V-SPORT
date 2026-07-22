<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
<title>${pageTitle}</title>
<jsp:include page="/manager/common/manager_head.jsp" />
<style>
  body { background-color: #f8fafc !important; }
  .tabs { display:flex; gap:4px; overflow-x:auto; border-bottom:1px solid #e2e8f0; }
  .tab-btn { padding:10px 16px; font-size:13px; font-weight:700; color:#64748b; cursor:pointer; white-space:nowrap; border-bottom:2px solid transparent; display:flex; align-items:center; gap:6px; }
  .tab-btn.active { color:#0f172a; border-bottom-color:#0f172a; }
  .tab-count { background:#f1f5f9; color:#475569; font-size:11px; font-weight:800; padding:1px 7px; border-radius:999px; }
  .tab-btn.active .tab-count { background:#0f172a; color:#fff; }
  .yc-card { background:#fff; border:1px solid #e2e8f0; border-radius:14px; padding:14px 18px; cursor:pointer; transition:.15s; }
  .yc-card:hover { border-color:#94a3b8; box-shadow:0 4px 10px rgba(0,0,0,.05); }
  .yc-badge { display:inline-flex; font-size:11px; font-weight:800; padding:2px 9px; border-radius:999px; }
  .yc-b-pending { background:#fef3c7; color:#92400e; }
  .yc-b-confirmed { background:#dbeafe; color:#1d4ed8; }
  .yc-b-progress { background:#e0e7ff; color:#4338ca; }
  .yc-b-ready { background:#dcfce7; color:#166534; }
  .yc-b-done { background:#f1f5f9; color:#475569; }
  .yc-b-cancel { background:#fee2e2; color:#b91c1c; }
  .yc-empty { text-align:center; padding:60px 20px; color:#94a3b8; }

  .drawer-overlay { position:fixed; inset:0; background:rgba(15,23,42,.45); z-index:70; display:none; }
  .drawer-overlay.open { display:block; }
  .drawer-panel { position:fixed; top:0; right:0; height:100vh; width:100%; max-width:560px; background:#fff; z-index:71;
    transform:translateX(100%); transition:transform .25s ease; overflow-y:auto; box-shadow:-10px 0 30px rgba(0,0,0,.15); display:flex; flex-direction:column; }
  .drawer-panel.open { transform:translateX(0); }
  .dsec-label { font-size:11px; font-weight:800; color:#94a3b8; text-transform:uppercase; letter-spacing:.03em; margin: 14px 0 6px; }
  .drow { display:flex; justify-content:space-between; font-size:13.5px; padding:6px 0; border-bottom:1px dashed #f1f5f9; }
  .drow span:first-child { color:#64748b; }
  .drow span:last-child { font-weight:700; color:#0f172a; text-align:right; max-width:60%; }
  .tl-item { display:flex; gap:10px; padding:6px 0; font-size:12.5px; }
  .tl-dot { width:8px; height:8px; border-radius:999px; background:#0f172a; margin-top:5px; flex-shrink:0; }
  .action-bar { border-top:1px solid #f1f5f9; padding:14px 20px; display:flex; gap:8px; position:sticky; bottom:0; background:#fff; }
  .act-btn { flex:1; padding:11px; border-radius:10px; font-weight:800; font-size:13.5px; border:none; cursor:pointer; }
  .act-primary { background:#0f172a; color:#fff; }
  .act-danger { background:#fef2f2; color:#b91c1c; }

  .modal-overlay { position:fixed; inset:0; background:rgba(15,23,42,.5); z-index:90; display:none; align-items:center; justify-content:center; }
  .modal-overlay.open { display:flex; }
  .modal-box { background:#fff; border-radius:16px; padding:22px; width:100%; max-width:420px; margin:16px; }
  .field label { font-size:12px; font-weight:700; color:#475569; margin-bottom:4px; display:block; }
  .field input, .field textarea { width:100%; border:1px solid #e2e8f0; border-radius:10px; padding:8px 10px; font-size:13.5px; outline:none; }
  .field { margin-bottom:12px; }
</style>
</head>
<body class="text-zinc-900 min-h-screen">

<jsp:include page="/manager/common/sidebar.jsp" />

<c:set var="headerTitle" value="Yêu cầu dịch vụ" scope="page" />
<c:set var="headerSubtitle" value="Chi nhánh CS${sessionScope.user.coSoId}" scope="page" />
<c:set var="headerIcon" value="clipboard_list" scope="page" />
<jsp:include page="/manager/common/header.jsp" />

<main class="lg:ml-[248px] mt-[64px] p-4 lg:p-6 flex flex-col gap-4">
  <section>
    <h1 class="text-2xl font-extrabold text-slate-900 tracking-tight">Yêu cầu dịch vụ</h1>
    <p class="text-[13.5px] text-slate-500 mt-1">Xử lý đơn căng lưới, thay quấn cán và các dịch vụ khác của khách hàng.</p>
  </section>

  <section class="tabs" id="ycTabs">
    <div class="tab-btn active" data-tab="moi">Yêu cầu mới <span class="tab-count" id="cnt-moi">0</span></div>
    <div class="tab-btn" data-tab="da-xac-nhan">Đã xác nhận <span class="tab-count" id="cnt-da-xac-nhan">0</span></div>
    <div class="tab-btn" data-tab="dang-xu-ly">Đang xử lý <span class="tab-count" id="cnt-dang-xu-ly">0</span></div>
    <div class="tab-btn" data-tab="san-sang">Sẵn sàng nhận <span class="tab-count" id="cnt-san-sang">0</span></div>
    <div class="tab-btn" data-tab="hoan-thanh">Hoàn thành <span class="tab-count" id="cnt-hoan-thanh">0</span></div>
    <div class="tab-btn" data-tab="da-huy">Đã hủy <span class="tab-count" id="cnt-da-huy">0</span></div>
  </section>

  <section id="ycList" class="flex flex-col gap-3"></section>
  <div id="ycEmpty" class="yc-empty" style="display:none;">Chưa có đơn dịch vụ nào trong mục này.</div>
</main>

<%-- ═══ DRAWER CHI TIẾT ═══ --%>
<div class="drawer-overlay" id="ycOverlay" onclick="closeDrawer()"></div>
<div class="drawer-panel" id="ycDrawer">
  <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100">
    <h3 class="font-extrabold text-lg" id="ycDrawerTitle">Chi tiết đơn</h3>
    <button type="button" onclick="closeDrawer()" class="w-8 h-8 rounded-lg hover:bg-slate-100 flex items-center justify-center">
      <span class="material-symbols-outlined">close</span>
    </button>
  </div>
  <div class="flex-1 overflow-y-auto px-5 py-2" id="ycDrawerBody"></div>
  <div class="action-bar" id="ycActionBar"></div>
</div>

<%-- ═══ MODAL XÁC NHẬN ═══ --%>
<div class="modal-overlay" id="confirmModal">
  <div class="modal-box">
    <h3 class="font-extrabold text-lg mb-1">Xác nhận yêu cầu</h3>
    <p class="text-xs text-slate-500 mb-4" id="confirmEstimateHint"></p>
    <div class="field"><label>Giá xác nhận (đ) *</label><input type="number" min="0" step="1000" id="cf_price"/></div>
    <div class="field"><label>Thời gian dự kiến hoàn thành</label><input type="datetime-local" id="cf_pickup"/></div>
    <div class="field"><label>Ghi chú cho khách</label><textarea id="cf_note" rows="2"></textarea></div>
    <div id="cf_error" style="color:#c0392b;font-size:12.5px;display:none;margin-bottom:8px;"></div>
    <div class="flex gap-2">
      <button type="button" class="act-btn" style="background:#f1f5f9;color:#475569;" onclick="closeModal('confirmModal')">Hủy</button>
      <button type="button" class="act-btn act-primary" onclick="submitConfirm()">Xác nhận</button>
    </div>
  </div>
</div>

<%-- ═══ MODAL TỪ CHỐI/HỦY (dùng chung) ═══ --%>
<div class="modal-overlay" id="reasonModal">
  <div class="modal-box">
    <h3 class="font-extrabold text-lg mb-1" id="reasonModalTitle">Từ chối yêu cầu</h3>
    <div class="field">
      <label>Lý do *</label>
      <textarea id="rs_reason" rows="3" placeholder="VD: Không còn vật tư phù hợp, không nhận mức căng yêu cầu..."></textarea>
    </div>
    <div id="rs_error" style="color:#c0392b;font-size:12.5px;display:none;margin-bottom:8px;"></div>
    <div class="flex gap-2">
      <button type="button" class="act-btn" style="background:#f1f5f9;color:#475569;" onclick="closeModal('reasonModal')">Đóng</button>
      <button type="button" class="act-btn act-danger" onclick="submitReason()">Xác nhận</button>
    </div>
  </div>
</div>

<script>
  var ctxPath = '${pageContext.request.contextPath}';
  var currentTab = 'moi';
  var currentOrderId = null;
  var reasonAction = null; // 'tu-choi' | 'huy'

  var TAB_LABEL = { moi: 'Yêu cầu mới', 'da-xac-nhan': 'Đã xác nhận', 'dang-xu-ly': 'Đang xử lý',
                     'san-sang': 'Sẵn sàng nhận', 'hoan-thanh': 'Hoàn thành', 'da-huy': 'Đã hủy' };

  function statusBadge(status) {
    switch (status) {
      case 'PENDING_CONFIRMATION': return '<span class="yc-badge yc-b-pending">Chờ xác nhận</span>';
      case 'CONFIRMED': return '<span class="yc-badge yc-b-confirmed">Đã xác nhận</span>';
      case 'ITEM_RECEIVED': return '<span class="yc-badge yc-b-progress">Đã nhận vợt</span>';
      case 'IN_PROGRESS': return '<span class="yc-badge yc-b-progress">Đang xử lý</span>';
      case 'READY_FOR_PICKUP': return '<span class="yc-badge yc-b-ready">Sẵn sàng nhận</span>';
      case 'COMPLETED': return '<span class="yc-badge yc-b-done">Hoàn thành</span>';
      case 'REJECTED': return '<span class="yc-badge yc-b-cancel">Đã từ chối</span>';
      case 'CANCELLED': return '<span class="yc-badge yc-b-cancel">Đã hủy</span>';
      default: return status;
    }
  }

  function fmtMoney(v) { return v == null ? '—' : Number(v).toLocaleString('vi-VN') + 'đ'; }
  function escapeHtml(s) { if (!s) return ''; var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }

  function loadCounts() {
    fetch(ctxPath + '/api/manager/yeu-cau-dich-vu?tab=moi')
      .then(function(r){ return r.json(); })
      .then(function(data){
        if (!data.success) return;
        Object.keys(data.counts).forEach(function(k){
          var el = document.getElementById('cnt-' + k);
          if (el) el.textContent = data.counts[k];
        });
      });
  }

  function loadList() {
    fetch(ctxPath + '/api/manager/yeu-cau-dich-vu?tab=' + currentTab)
      .then(function(r){ return r.json(); })
      .then(function(data){
        if (!data.success) return;
        renderList(data.orders || []);
      });
  }

  function renderList(orders) {
    var list = document.getElementById('ycList');
    var empty = document.getElementById('ycEmpty');
    list.innerHTML = '';
    if (!orders.length) { empty.style.display = 'block'; return; }
    empty.style.display = 'none';
    orders.forEach(function(o) {
      var card = document.createElement('div');
      card.className = 'yc-card';
      card.onclick = function(){ openDrawer(o.orderId); };
      card.innerHTML =
        '<div class="flex items-center justify-between gap-3 flex-wrap">' +
          '<div class="min-w-0">' +
            '<div class="flex items-center gap-2 flex-wrap mb-1">' +
              '<span class="font-extrabold text-sm text-slate-900">#' + o.orderId + '</span>' +
              statusBadge(o.status) +
            '</div>' +
            '<p class="text-[13px] text-slate-600">' + escapeHtml(o.customerName) + ' · ' + escapeHtml(o.serviceName) +
              (o.racketType ? (' · ' + escapeHtml(o.racketType)) : '') +
              (o.tensionValue ? (' · ' + o.tensionValue + o.tensionUnit) : '') + '</p>' +
            '<p class="text-[12px] text-slate-400 mt-0.5">Mang đến: ' + (o.appointmentDate || '—') + '</p>' +
          '</div>' +
          '<div class="text-right shrink-0">' +
            '<p class="font-extrabold text-sm text-slate-900">' + fmtMoney(o.confirmedPrice != null ? o.confirmedPrice : o.estimatedPrice) + '</p>' +
            '<p class="text-[11px] text-slate-400">' + (o.confirmedPrice != null ? 'Giá xác nhận' : 'Giá dự kiến') + '</p>' +
          '</div>' +
        '</div>';
      list.appendChild(card);
    });
  }

  document.querySelectorAll('.tab-btn').forEach(function(btn) {
    btn.addEventListener('click', function() {
      document.querySelectorAll('.tab-btn').forEach(function(b){ b.classList.remove('active'); });
      btn.classList.add('active');
      currentTab = btn.dataset.tab;
      loadList();
    });
  });

  function openDrawer(orderId) {
    currentOrderId = orderId;
    fetch(ctxPath + '/api/manager/yeu-cau-dich-vu?action=detail&orderId=' + orderId)
      .then(function(r){ return r.json(); })
      .then(function(data){
        if (!data.success) { alert(data.message || 'Không tải được chi tiết đơn.'); return; }
        renderDrawer(data.order);
        document.getElementById('ycOverlay').classList.add('open');
        document.getElementById('ycDrawer').classList.add('open');
      });
  }
  function closeDrawer() {
    document.getElementById('ycOverlay').classList.remove('open');
    document.getElementById('ycDrawer').classList.remove('open');
  }

  function row(label, value) {
    if (value == null || value === '') return '';
    return '<div class="drow"><span>' + label + '</span><span>' + escapeHtml(String(value)) + '</span></div>';
  }

  function renderDrawer(o) {
    document.getElementById('ycDrawerTitle').textContent = 'Đơn #' + o.orderId;
    var html = '';
    html += '<div class="dsec-label">Thông tin đơn</div>';
    html += row('Trạng thái', '') ; // placeholder replaced below with badge
    html = html.replace(row('Trạng thái', ''), '<div class="drow"><span>Trạng thái</span><span>' + statusBadge(o.status) + '</span></div>');
    html += row('Ngày gửi', o.requestedAt ? o.requestedAt.replace('T', ' ').substring(0, 16) : null);
    html += row('Booking liên quan', o.bookingId ? ('#' + o.bookingId) : 'Không có');

    html += '<div class="dsec-label">Khách hàng</div>';
    html += row('Họ tên', o.customerName);
    html += row('Số điện thoại', o.customerPhone);

    html += '<div class="dsec-label">Dịch vụ</div>';
    html += row('Dịch vụ', o.serviceName);
    if (o.racketDetail) {
      var rd = o.racketDetail;
      html += row('Loại vợt', rd.racketType);
      html += row('Thương hiệu', rd.racketBrand);
      html += row('Model', rd.racketModel);
      html += row('Mức căng', rd.tensionValue ? (rd.tensionValue + ' ' + rd.tensionUnit) : null);
      html += row('Màu dây', rd.stringColor);
      html += row('Số lượng', rd.quantity);
      html += row('Tự mang dây', rd.customerBringsString ? 'Có' : 'Không');
      if (rd.materialName) html += row('Loại dây', rd.materialName + ' (' + fmtMoney(rd.materialPrice) + ')');
      if (rd.technicalNote) html += row('Ghi chú kỹ thuật', rd.technicalNote);
    }

    html += '<div class="dsec-label">Lịch hẹn</div>';
    html += row('Ngày mang đến', o.appointmentDate);
    html += row('Khung giờ mang đến', o.dropOffTime);
    html += row('Thời gian dự kiến nhận', o.expectedPickupTime ? o.expectedPickupTime.replace('T',' ').substring(0,16) : null);

    html += '<div class="dsec-label">Giá</div>';
    html += row('Giá dự kiến', fmtMoney(o.estimatedPrice));
    html += row('Giá xác nhận', o.confirmedPrice != null ? fmtMoney(o.confirmedPrice) : 'Chưa xác nhận');

    if (o.customerNote || o.managerNote || o.cancellationReason) {
      html += '<div class="dsec-label">Ghi chú</div>';
      html += row('Ghi chú khách hàng', o.customerNote);
      html += row('Ghi chú cơ sở', o.managerNote);
      html += row('Lý do hủy/từ chối', o.cancellationReason);
    }

    if (o.timeline && o.timeline.length) {
      html += '<div class="dsec-label">Timeline</div>';
      o.timeline.forEach(function(t) {
        html += '<div class="tl-item"><div class="tl-dot"></div><div>' +
          '<div style="font-weight:700;">' + statusBadgeText(t.toStatus) + '</div>' +
          '<div style="color:#94a3b8;">' + (t.changedAt ? t.changedAt.replace('T',' ').substring(0,16) : '') +
          (t.note ? (' · ' + escapeHtml(t.note)) : '') + '</div></div></div>';
      });
    }

    document.getElementById('ycDrawerBody').innerHTML = html;
    renderActionBar(o);
  }

  function statusBadgeText(s) {
    var map = { PENDING_CONFIRMATION: 'Đã gửi yêu cầu', CONFIRMED: 'Cơ sở xác nhận', ITEM_RECEIVED: 'Cơ sở nhận vợt',
      IN_PROGRESS: 'Đang xử lý', READY_FOR_PICKUP: 'Sẵn sàng nhận', COMPLETED: 'Hoàn thành', REJECTED: 'Từ chối', CANCELLED: 'Đã hủy' };
    return map[s] || s;
  }

  function renderActionBar(o) {
    var bar = document.getElementById('ycActionBar');
    bar.innerHTML = '';
    var actions = o.allowedActions || [];
    if (actions.indexOf('CONFIRMED') !== -1) {
      bar.innerHTML += '<button class="act-btn act-primary" onclick="openConfirmModal(' + o.estimatedPrice + ')">Xác nhận yêu cầu</button>';
      bar.innerHTML += '<button class="act-btn act-danger" onclick="openReasonModal(\'tu-choi\', \'Từ chối yêu cầu\')">Từ chối</button>';
    } else if (actions.indexOf('ITEM_RECEIVED') !== -1) {
      bar.innerHTML += '<button class="act-btn act-primary" onclick="runSimpleAction(\'da-nhan\')">Đã nhận vợt</button>';
      bar.innerHTML += '<button class="act-btn act-danger" onclick="openReasonModal(\'huy\', \'Hủy đơn\')">Hủy đơn</button>';
    } else if (actions.indexOf('IN_PROGRESS') !== -1) {
      bar.innerHTML += '<button class="act-btn act-primary" onclick="runSimpleAction(\'bat-dau\')">Bắt đầu xử lý</button>';
    } else if (actions.indexOf('READY_FOR_PICKUP') !== -1) {
      bar.innerHTML += '<button class="act-btn act-primary" onclick="runSimpleAction(\'san-sang\')">Sẵn sàng giao khách</button>';
    } else if (actions.indexOf('COMPLETED') !== -1) {
      bar.innerHTML += '<button class="act-btn act-primary" onclick="runSimpleAction(\'hoan-thanh\')">Hoàn thành đơn</button>';
    }
    if (!bar.innerHTML) bar.style.display = 'none'; else bar.style.display = 'flex';
  }

  function doAction(action, extraParams) {
    var p = new URLSearchParams(extraParams || {});
    p.set('action', action);
    p.set('orderId', currentOrderId);
    return fetch(ctxPath + '/api/manager/yeu-cau-dich-vu/action', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: p.toString()
    }).then(function(r){ return r.json().then(function(data){ return { status: r.status, data: data }; }); });
  }

  var actionInFlight = false;
  function runSimpleAction(action) {
    if (actionInFlight) return;
    actionInFlight = true;
    var btns = document.querySelectorAll('#ycActionBar button');
    btns.forEach(function(b){ b.disabled = true; });
    doAction(action).then(function(res) {
      actionInFlight = false;
      btns.forEach(function(b){ b.disabled = false; });
      if (res.data.success) {
        afterActionSuccess(res.data.message);
      } else {
        alert(res.data.message || 'Không thể thực hiện thao tác.');
      }
    }).catch(function() {
      actionInFlight = false;
      btns.forEach(function(b){ b.disabled = false; });
      alert('Lỗi kết nối. Vui lòng thử lại.');
    });
  }

  function afterActionSuccess(msg) {
    closeModal('confirmModal');
    closeModal('reasonModal');
    closeDrawer();
    loadCounts();
    loadList();
    alert(msg);
  }

  function openConfirmModal(estimatedPrice) {
    document.getElementById('confirmEstimateHint').textContent = 'Giá dự kiến khách đã thấy: ' + fmtMoney(estimatedPrice);
    document.getElementById('cf_price').value = estimatedPrice || '';
    document.getElementById('cf_pickup').value = '';
    document.getElementById('cf_note').value = '';
    document.getElementById('cf_error').style.display = 'none';
    document.getElementById('confirmModal').classList.add('open');
  }

  function submitConfirm() {
    var price = document.getElementById('cf_price').value;
    var err = document.getElementById('cf_error');
    if (price === '' || Number(price) < 0) {
      err.textContent = 'Vui lòng nhập giá xác nhận hợp lệ.';
      err.style.display = 'block';
      return;
    }
    var pickup = document.getElementById('cf_pickup').value;
    doAction('xac-nhan', {
      confirmedPrice: price,
      expectedPickupTime: pickup,
      managerNote: document.getElementById('cf_note').value
    }).then(function(res) {
      if (res.data.success) {
        afterActionSuccess(res.data.message);
      } else {
        err.textContent = res.data.message || 'Không thể xác nhận.';
        err.style.display = 'block';
      }
    });
  }

  function openReasonModal(action, title) {
    reasonAction = action;
    document.getElementById('reasonModalTitle').textContent = title;
    document.getElementById('rs_reason').value = '';
    document.getElementById('rs_error').style.display = 'none';
    document.getElementById('reasonModal').classList.add('open');
  }

  function submitReason() {
    var reason = document.getElementById('rs_reason').value;
    var err = document.getElementById('rs_error');
    if (!reason || !reason.trim()) {
      err.textContent = 'Vui lòng nhập lý do.';
      err.style.display = 'block';
      return;
    }
    doAction(reasonAction, { reason: reason }).then(function(res) {
      if (res.data.success) {
        afterActionSuccess(res.data.message);
      } else {
        err.textContent = res.data.message || 'Không thể thực hiện.';
        err.style.display = 'block';
      }
    });
  }

  function closeModal(id) { document.getElementById(id).classList.remove('open'); }

  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') { closeModal('confirmModal'); closeModal('reasonModal'); closeDrawer(); }
  });

  loadCounts();
  loadList();
</script>

</body>
</html>
