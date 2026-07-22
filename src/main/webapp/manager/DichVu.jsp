<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="vi">
<head>
<title>${pageTitle}</title>
<jsp:include page="/manager/common/manager_head.jsp" />
<style>
  body { background-color: #f8fafc !important; }
  .svc-card { background:#fff; border:1px solid #e2e8f0; border-radius:14px; padding:16px 18px; box-shadow:0 1px 2px rgba(0,0,0,.03); cursor:pointer; transition:.15s; }
  .svc-card:hover { border-color:#94a3b8; box-shadow:0 4px 10px rgba(0,0,0,.06); }
  .badge { display:inline-flex; align-items:center; gap:4px; font-size:11px; font-weight:700; padding:2px 8px; border-radius:999px; }
  .badge-green { background:#dcfce7; color:#166534; }
  .badge-amber { background:#fef3c7; color:#92400e; }
  .badge-zinc { background:#f1f5f9; color:#475569; }
  .drawer-overlay { position:fixed; inset:0; background:rgba(15,23,42,.45); z-index:60; display:none; }
  .drawer-panel { position:fixed; top:0; right:0; height:100vh; width:100%; max-width:560px; background:#fff; z-index:61;
    box-shadow:-10px 0 30px rgba(0,0,0,.15); transform:translateX(100%); transition:transform .25s ease; overflow-y:auto; }
  .drawer-panel.open, .drawer-overlay.open { display:block; }
  .drawer-panel.open { transform:translateX(0); }
  .field label { font-size:12px; font-weight:700; color:#475569; margin-bottom:4px; display:block; }
  .field input, .field select, .field textarea {
    width:100%; border:1px solid #e2e8f0; border-radius:10px; padding:8px 10px; font-size:13.5px; outline:none;
  }
  .field input:focus, .field select:focus, .field textarea:focus { border-color:#0f766e; }
  .tab-btn { padding:8px 14px; border-radius:10px; font-size:13px; font-weight:700; color:#64748b; cursor:pointer; }
  .tab-btn.active { background:#0f172a; color:#fff; }
</style>
</head>
<body class="text-zinc-900 min-h-screen">

<jsp:include page="/manager/common/sidebar.jsp" />

<c:set var="headerTitle" value="Quản lý dịch vụ" scope="page" />
<c:set var="headerSubtitle" value="Chi nhánh CS${sessionScope.user.coSoId}" scope="page" />
<c:set var="headerIcon" value="handyman" scope="page" />
<jsp:include page="/manager/common/header.jsp" />

<main class="lg:ml-[248px] mt-[64px] p-4 lg:p-6 flex flex-col gap-5">

  <c:if test="${not empty successMsg}">
    <div class="flex items-center gap-3 p-4 bg-emerald-50 border border-emerald-100 text-emerald-800 rounded-2xl shadow-sm">
      <span class="material-symbols-outlined text-emerald-600 text-[20px]">check_circle</span>
      <p class="text-sm font-semibold">${successMsg}</p>
    </div>
  </c:if>
  <c:if test="${not empty errorMsg}">
    <div class="flex items-center gap-3 p-4 bg-rose-50 border border-rose-100 text-rose-800 rounded-2xl shadow-sm">
      <span class="material-symbols-outlined text-rose-600 text-[20px]">error</span>
      <p class="text-sm font-semibold">${errorMsg}</p>
    </div>
  </c:if>

  <section class="flex items-center justify-between gap-4 flex-wrap">
    <div>
      <h1 class="text-2xl font-extrabold text-slate-900 tracking-tight">Quản lý dịch vụ</h1>
      <p class="text-[13.5px] text-slate-500 mt-1">Căng lưới, thay quấn cán, sửa chữa, huấn luyện viên và các dịch vụ thể thao khác tại cơ sở.</p>
    </div>
    <button onclick="openServiceDrawer()" class="px-4 py-2.5 rounded-xl bg-teal-700 text-white text-sm font-bold hover:bg-teal-800 flex items-center gap-2">
      <span class="material-symbols-outlined text-[18px]">add</span>Thêm dịch vụ
    </button>
  </section>

  <section class="flex items-center gap-2 border-b border-slate-200 pb-0">
    <div class="tab-btn active" data-tab="services" onclick="switchTab('services')">Dịch vụ</div>
    <div class="tab-btn" data-tab="materials" onclick="switchTab('materials')">Vật tư dịch vụ</div>
  </section>

  <%-- ═══ TAB: DỊCH VỤ ═══ --%>
  <section id="tab-services" class="flex flex-col gap-3">
    <c:choose>
      <c:when test="${empty services}">
        <div class="svc-card text-center py-10 text-slate-400 text-sm" style="cursor:default;">
          Chưa có dịch vụ nào. Nhấn "Thêm dịch vụ" để bắt đầu.
        </div>
      </c:when>
      <c:otherwise>
        <c:forEach var="s" items="${services}">
          <div class="svc-card flex items-center justify-between gap-4 js-service-row"
               data-id="${s.serviceID}"
               data-service-name="${fn:escapeXml(s.serviceName)}"
               data-service-type="${fn:escapeXml(s.serviceType)}"
               data-sport-type="${fn:escapeXml(s.sportType)}"
               data-description="${fn:escapeXml(s.description)}"
               data-base-price="${s.basePrice}"
               data-unit="${fn:escapeXml(s.unit)}"
               data-estimated-minutes="${s.estimatedMinutes}"
               data-max-requests-per-day="${s.maxRequestsPerDay}"
               data-receive-time-start="${s.receiveTimeStart}"
               data-receive-time-end="${s.receiveTimeEnd}"
               data-image-url="${fn:escapeXml(s.imageUrl)}"
               data-accepting-requests="${s.acceptingRequests}"
               data-policy="${fn:escapeXml(s.policy)}"
               data-customer-note="${fn:escapeXml(s.customerNote)}"
               onclick="openServiceDrawer(this.dataset.id, this.dataset)">
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-2 flex-wrap">
                <p class="font-bold text-slate-900 text-sm truncate">${s.serviceName}</p>
                <c:choose>
                  <c:when test="${s.acceptingRequests}"><span class="badge badge-green">Đang nhận</span></c:when>
                  <c:otherwise><span class="badge badge-zinc">Tạm dừng</span></c:otherwise>
                </c:choose>
              </div>
              <p class="text-[12.5px] text-slate-500 mt-1">
                <c:choose>
                  <c:when test="${s.serviceType == 'CANG_LUOI'}">Căng lưới vợt</c:when>
                  <c:when test="${s.serviceType == 'THAY_QUAN_CAN'}">Thay quấn cán</c:when>
                  <c:when test="${s.serviceType == 'SUA_VOT'}">Sửa chữa vợt</c:when>
                  <c:when test="${s.serviceType == 'BAO_DUONG'}">Bảo dưỡng dụng cụ</c:when>
                  <c:when test="${s.serviceType == 'HUAN_LUYEN_VIEN'}">Huấn luyện viên</c:when>
                  <c:otherwise>Dịch vụ khác</c:otherwise>
                </c:choose>
                <c:if test="${not empty s.sportType}"> · ${s.sportType}</c:if>
                · Giá từ <fmt:formatNumber value="${s.basePrice}" pattern="#,##0"/>đ
                · ~${s.estimatedMinutes} phút
              </p>
            </div>
            <span class="material-symbols-outlined text-slate-300">chevron_right</span>
          </div>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </section>

  <%-- ═══ TAB: VẬT TƯ ═══ --%>
  <section id="tab-materials" class="flex-col gap-3" style="display:none;">
    <div class="flex justify-end">
      <button onclick="openMaterialDrawer()" class="px-4 py-2.5 rounded-xl bg-slate-900 text-white text-sm font-bold hover:bg-slate-800 flex items-center gap-2">
        <span class="material-symbols-outlined text-[18px]">add</span>Thêm vật tư
      </button>
    </div>
    <c:choose>
      <c:when test="${empty materials}">
        <div class="svc-card text-center py-10 text-slate-400 text-sm" style="cursor:default;">Chưa có vật tư nào.</div>
      </c:when>
      <c:otherwise>
        <c:forEach var="m" items="${materials}">
          <div class="svc-card flex items-center justify-between gap-4 js-material-row"
               data-id="${m.materialID}"
               data-name="${fn:escapeXml(m.name)}"
               data-brand="${fn:escapeXml(m.brand)}"
               data-code="${fn:escapeXml(m.code)}"
               data-color="${fn:escapeXml(m.color)}"
               data-sport-type="${fn:escapeXml(m.sportType)}"
               data-price="${m.price}"
               data-extra-fee="${m.extraFee}"
               data-status="${fn:escapeXml(m.status)}"
               data-description="${fn:escapeXml(m.description)}"
               onclick="openMaterialDrawer(this.dataset.id, this.dataset)">
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-2 flex-wrap">
                <p class="font-bold text-slate-900 text-sm truncate">${m.name}</p>
                <c:choose>
                  <c:when test="${m.status == 'DANG_CO'}"><span class="badge badge-green">Đang có</span></c:when>
                  <c:when test="${m.status == 'TAM_HET'}"><span class="badge badge-amber">Tạm hết</span></c:when>
                  <c:otherwise><span class="badge badge-zinc">Ngừng sử dụng</span></c:otherwise>
                </c:choose>
              </div>
              <p class="text-[12.5px] text-slate-500 mt-1">
                <c:if test="${not empty m.brand}">${m.brand} · </c:if>
                <fmt:formatNumber value="${m.price}" pattern="#,##0"/>đ
                <c:if test="${m.extraFee > 0}"> (+<fmt:formatNumber value="${m.extraFee}" pattern="#,##0"/>đ phụ phí)</c:if>
              </p>
            </div>
            <span class="material-symbols-outlined text-slate-300">chevron_right</span>
          </div>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </section>
</main>

<%-- ═══ DRAWER: DỊCH VỤ ═══ --%>
<div class="drawer-overlay" id="serviceOverlay" onclick="closeServiceDrawer()"></div>
<div class="drawer-panel" id="serviceDrawer">
  <form method="post" action="${pageContext.request.contextPath}/manager/dich-vu" class="flex flex-col h-full">
    <input type="hidden" name="action" id="serviceFormAction" value="add-service"/>
    <input type="hidden" name="serviceId" id="serviceIdInput" value=""/>
    <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100">
      <h3 class="font-extrabold text-lg" id="serviceDrawerTitle">Thêm dịch vụ</h3>
      <button type="button" onclick="closeServiceDrawer()" class="w-8 h-8 rounded-lg hover:bg-slate-100 flex items-center justify-center">
        <span class="material-symbols-outlined">close</span>
      </button>
    </div>
    <div class="flex-1 overflow-y-auto px-5 py-4 flex flex-col gap-3.5">
      <div class="field"><label>Tên dịch vụ *</label><input type="text" name="serviceName" id="f_serviceName" maxlength="150" required/></div>
      <div class="grid grid-cols-2 gap-3">
        <div class="field">
          <label>Loại dịch vụ *</label>
          <select name="serviceType" id="f_serviceType" onchange="onServiceTypeChange()" required>
            <option value="CANG_LUOI">Căng lưới vợt</option>
            <option value="THAY_QUAN_CAN">Thay quấn cán</option>
            <option value="SUA_VOT">Sửa chữa vợt</option>
            <option value="BAO_DUONG">Bảo dưỡng dụng cụ</option>
            <option value="HUAN_LUYEN_VIEN">Huấn luyện viên</option>
            <option value="KHAC">Dịch vụ khác</option>
          </select>
        </div>
        <div class="field"><label>Môn thể thao</label><input type="text" name="sportType" id="f_sportType" placeholder="Cầu lông, Tennis..."/></div>
      </div>
      <div class="field"><label>Mô tả ngắn</label><textarea name="description" id="f_description" rows="2"></textarea></div>
      <div class="grid grid-cols-3 gap-3">
        <div class="field"><label>Giá cơ bản (đ) *</label><input type="number" min="0" step="1000" name="basePrice" id="f_basePrice" required/></div>
        <div class="field"><label>Đơn vị tính</label><input type="text" name="unit" id="f_unit" placeholder="vợt, lần..."/></div>
        <div class="field"><label>Thời gian (phút) *</label><input type="number" min="1" name="estimatedMinutes" id="f_estimatedMinutes" required/></div>
      </div>
      <div class="grid grid-cols-3 gap-3">
        <div class="field"><label>Số đơn tối đa/ngày</label><input type="number" min="1" name="maxRequestsPerDay" id="f_maxRequestsPerDay"/></div>
        <div class="field"><label>Giờ nhận từ</label><input type="time" name="receiveTimeStart" id="f_receiveTimeStart"/></div>
        <div class="field"><label>Giờ nhận đến</label><input type="time" name="receiveTimeEnd" id="f_receiveTimeEnd"/></div>
      </div>
      <div class="field"><label>Ảnh đại diện (URL)</label><input type="text" name="imageUrl" id="f_imageUrl"/></div>
      <label class="flex items-center gap-2 text-sm font-semibold text-slate-700">
        <input type="checkbox" name="acceptingRequests" id="f_acceptingRequests" checked/> Đang nhận yêu cầu
      </label>
      <div class="field"><label>Chính sách</label><textarea name="policy" id="f_policy" rows="2"></textarea></div>
      <div class="field"><label>Ghi chú dành cho khách</label><textarea name="customerNote" id="f_customerNote" rows="2"></textarea></div>

      <div id="racketConfigBlock" class="border-t border-slate-100 pt-3.5 mt-1 flex flex-col gap-3.5">
        <p class="text-xs font-bold text-teal-700 uppercase tracking-wide">Cấu hình căng lưới</p>
        <div class="field"><label>Loại vợt nhận (CSV)</label><input type="text" name="racketTypes" id="f_racketTypes" placeholder="Cầu lông,Tennis"/></div>
        <div class="grid grid-cols-2 gap-3">
          <div class="field"><label>Giá công căng (đ) *</label><input type="number" min="0" step="1000" name="stringingPrice" id="f_stringingPrice"/></div>
          <div class="field">
            <label>Đơn vị mức căng</label>
            <select name="tensionUnit" id="f_tensionUnit"><option value="kg">kg</option><option value="lbs">lbs</option></select>
          </div>
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div class="field"><label>Mức căng tối thiểu *</label><input type="number" min="0" step="0.5" name="minTension" id="f_minTension"/></div>
          <div class="field"><label>Mức căng tối đa *</label><input type="number" min="0" step="0.5" name="maxTension" id="f_maxTension"/></div>
        </div>
        <label class="flex items-center gap-2 text-sm font-semibold text-slate-700">
          <input type="checkbox" name="allowCustomerString" id="f_allowCustomerString" checked/> Cho khách tự mang dây
        </label>
        <label class="flex items-center gap-2 text-sm font-semibold text-slate-700">
          <input type="checkbox" name="sellsString" id="f_sellsString" checked/> Có bán dây tại cơ sở
        </label>
        <div class="grid grid-cols-2 gap-3">
          <div class="field"><label>Thời gian hoàn thành TB (phút)</label><input type="number" min="1" name="avgCompletionMinutes" id="f_avgCompletionMinutes"/></div>
          <div class="field"><label>Số vợt tối đa/đơn</label><input type="number" min="1" name="maxRacketsPerOrder" id="f_maxRacketsPerOrder"/></div>
        </div>
        <div class="field"><label>Chính sách vợt cũ/hư hỏng</label><textarea name="oldRacketPolicy" id="f_oldRacketPolicy" rows="2"></textarea></div>
        <div class="field"><label>Chính sách dây đứt khi căng</label><textarea name="stringBreakPolicy" id="f_stringBreakPolicy" rows="2"></textarea></div>
      </div>
    </div>
    <div class="px-5 py-4 border-t border-slate-100 flex gap-2">
      <button type="submit" class="flex-1 py-2.5 rounded-xl bg-teal-700 text-white text-sm font-bold hover:bg-teal-800">Lưu dịch vụ</button>
      <button type="button" id="deleteServiceBtn" onclick="submitDeleteService()" class="hidden py-2.5 px-4 rounded-xl bg-rose-50 text-rose-700 text-sm font-bold hover:bg-rose-100">Tắt dịch vụ</button>
    </div>
  </form>
</div>

<%-- ═══ DRAWER: VẬT TƯ ═══ --%>
<div class="drawer-overlay" id="materialOverlay" onclick="closeMaterialDrawer()"></div>
<div class="drawer-panel" id="materialDrawer" style="max-width:440px;">
  <form method="post" action="${pageContext.request.contextPath}/manager/dich-vu" class="flex flex-col h-full">
    <input type="hidden" name="action" id="materialFormAction" value="add-material"/>
    <input type="hidden" name="materialId" id="materialIdInput" value=""/>
    <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100">
      <h3 class="font-extrabold text-lg" id="materialDrawerTitle">Thêm vật tư</h3>
      <button type="button" onclick="closeMaterialDrawer()" class="w-8 h-8 rounded-lg hover:bg-slate-100 flex items-center justify-center">
        <span class="material-symbols-outlined">close</span>
      </button>
    </div>
    <div class="flex-1 overflow-y-auto px-5 py-4 flex flex-col gap-3.5">
      <div class="field"><label>Tên vật tư *</label><input type="text" name="materialName" id="m_name" maxlength="150" required/></div>
      <div class="grid grid-cols-2 gap-3">
        <div class="field"><label>Thương hiệu</label><input type="text" name="materialBrand" id="m_brand"/></div>
        <div class="field"><label>Mã dây</label><input type="text" name="materialCode" id="m_code"/></div>
      </div>
      <div class="grid grid-cols-2 gap-3">
        <div class="field"><label>Màu</label><input type="text" name="materialColor" id="m_color"/></div>
        <div class="field"><label>Môn thể thao</label><input type="text" name="materialSportType" id="m_sportType"/></div>
      </div>
      <div class="grid grid-cols-2 gap-3">
        <div class="field"><label>Giá vật tư (đ) *</label><input type="number" min="0" step="1000" name="materialPrice" id="m_price" required/></div>
        <div class="field"><label>Phụ phí (đ)</label><input type="number" min="0" step="1000" name="materialExtraFee" id="m_extraFee"/></div>
      </div>
      <div class="field">
        <label>Trạng thái</label>
        <select name="materialStatus" id="m_status">
          <option value="DANG_CO">Đang có</option>
          <option value="TAM_HET">Tạm hết</option>
          <option value="NGUNG_SU_DUNG">Ngừng sử dụng</option>
        </select>
      </div>
      <div class="field"><label>Mô tả ngắn</label><textarea name="materialDescription" id="m_description" rows="2"></textarea></div>
    </div>
    <div class="px-5 py-4 border-t border-slate-100 flex gap-2">
      <button type="submit" class="flex-1 py-2.5 rounded-xl bg-slate-900 text-white text-sm font-bold hover:bg-slate-800">Lưu vật tư</button>
      <button type="button" id="deleteMaterialBtn" onclick="submitDeleteMaterial()" class="hidden py-2.5 px-4 rounded-xl bg-rose-50 text-rose-700 text-sm font-bold hover:bg-rose-100">Xóa</button>
    </div>
  </form>
</div>

<script>
  function switchTab(tab) {
    document.getElementById('tab-services').style.display = tab === 'services' ? 'flex' : 'none';
    document.getElementById('tab-materials').style.display = tab === 'materials' ? 'flex' : 'none';
    document.querySelectorAll('.tab-btn').forEach(function(b){ b.classList.toggle('active', b.dataset.tab === tab); });
  }

  function onServiceTypeChange() {
    var t = document.getElementById('f_serviceType').value;
    document.getElementById('racketConfigBlock').style.display = (t === 'CANG_LUOI') ? 'flex' : 'none';
  }

  function openServiceDrawer(id, d) {
    var form = document.querySelector('#serviceDrawer form');
    form.reset();
    document.getElementById('serviceIdInput').value = id || '';
    document.getElementById('serviceFormAction').value = id ? 'update-service' : 'add-service';
    document.getElementById('serviceDrawerTitle').textContent = id ? 'Chỉnh sửa dịch vụ' : 'Thêm dịch vụ';
    document.getElementById('deleteServiceBtn').classList.toggle('hidden', !id);
    if (id && d) {
      document.getElementById('f_serviceName').value = d.serviceName || '';
      document.getElementById('f_serviceType').value = d.serviceType || 'KHAC';
      document.getElementById('f_sportType').value = d.sportType || '';
      document.getElementById('f_description').value = d.description || '';
      document.getElementById('f_basePrice').value = d.basePrice || 0;
      document.getElementById('f_unit').value = d.unit || '';
      document.getElementById('f_estimatedMinutes').value = d.estimatedMinutes || 60;
      document.getElementById('f_maxRequestsPerDay').value = d.maxRequestsPerDay || '';
      document.getElementById('f_receiveTimeStart').value = (d.receiveTimeStart && d.receiveTimeStart !== 'null') ? d.receiveTimeStart : '';
      document.getElementById('f_receiveTimeEnd').value = (d.receiveTimeEnd && d.receiveTimeEnd !== 'null') ? d.receiveTimeEnd : '';
      document.getElementById('f_imageUrl').value = d.imageUrl || '';
      document.getElementById('f_acceptingRequests').checked = (d.acceptingRequests === 'true');
      document.getElementById('f_policy').value = d.policy || '';
      document.getElementById('f_customerNote').value = d.customerNote || '';
    }
    onServiceTypeChange();
    document.getElementById('serviceOverlay').classList.add('open');
    document.getElementById('serviceDrawer').classList.add('open');
  }
  function closeServiceDrawer() {
    document.getElementById('serviceOverlay').classList.remove('open');
    document.getElementById('serviceDrawer').classList.remove('open');
  }
  function submitDeleteService() {
    if (!confirm('Tắt dịch vụ này? Khách sẽ không còn thấy dịch vụ trong danh sách.')) return;
    document.getElementById('serviceFormAction').value = 'delete-service';
    document.querySelector('#serviceDrawer form').submit();
  }

  function openMaterialDrawer(id, d) {
    var form = document.querySelector('#materialDrawer form');
    form.reset();
    document.getElementById('materialIdInput').value = id || '';
    document.getElementById('materialFormAction').value = id ? 'update-material' : 'add-material';
    document.getElementById('materialDrawerTitle').textContent = id ? 'Chỉnh sửa vật tư' : 'Thêm vật tư';
    document.getElementById('deleteMaterialBtn').classList.toggle('hidden', !id);
    if (id && d) {
      document.getElementById('m_name').value = d.name || '';
      document.getElementById('m_brand').value = d.brand || '';
      document.getElementById('m_code').value = d.code || '';
      document.getElementById('m_color').value = d.color || '';
      document.getElementById('m_sportType').value = d.sportType || '';
      document.getElementById('m_price').value = d.price || 0;
      document.getElementById('m_extraFee').value = d.extraFee || 0;
      document.getElementById('m_status').value = d.status || 'DANG_CO';
      document.getElementById('m_description').value = d.description || '';
    }
    document.getElementById('materialOverlay').classList.add('open');
    document.getElementById('materialDrawer').classList.add('open');
  }
  function closeMaterialDrawer() {
    document.getElementById('materialOverlay').classList.remove('open');
    document.getElementById('materialDrawer').classList.remove('open');
  }
  function submitDeleteMaterial() {
    if (!confirm('Xóa vật tư này?')) return;
    document.getElementById('materialFormAction').value = 'delete-material';
    document.querySelector('#materialDrawer form').submit();
  }

  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') { closeServiceDrawer(); closeMaterialDrawer(); }
  });
</script>

</body>
</html>
