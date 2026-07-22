<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Quản lý Owner – V-SPORT Admin</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/dist/tabler-icons.min.css"/>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200"/>
  <style>
    body { font-family: 'Inter', sans-serif; }
    .badge { display:inline-flex;align-items:center;padding:3px 10px;border-radius:99px;font-size:11px;font-weight:700;letter-spacing:.02em; }
    .badge-amber  { background:#fef3c7;color:#d97706; }
    .badge-green  { background:#dcfce7;color:#15803d; }
    .badge-red    { background:#fee2e2;color:#b91c1c; }

    /* Card styling */
    .owner-card {
      background:#fff;border:1px solid #e4e4e7;border-radius:18px;
      transition:box-shadow .22s,transform .22s;
      position:relative;overflow:hidden;
    }
    .owner-card::before {
      content:'';position:absolute;top:0;left:0;right:0;height:3px;
      opacity:0;transition:opacity .22s;
    }
    .owner-card.card-pending::before { background:linear-gradient(90deg,#f59e0b,#fbbf24); }
    .owner-card.card-approved::before { background:linear-gradient(90deg,#10b981,#34d399); }

    .owner-card:hover { box-shadow:0 10px 30px -10px rgba(0,0,0,.08); transform:translateY(-2px); }
    .owner-card:hover::before { opacity:1; }

    /* Avatar styling */
    .owner-avatar {
      width:48px;height:48px;border-radius:14px;
      background:linear-gradient(135deg,#eff6ff,#dbeafe);
      display:flex;align-items:center;justify-content:center;
      color:#2563eb;font-weight:800;border:1px solid #bfdbfe;
      flex-shrink:0;
    }

    /* Tab styles */
    .tab-pill {
      display:inline-flex;align-items:center;gap:6px;
      padding:8px 18px;border-radius:8px;font-size:13px;font-weight:600;
      border:none;cursor:pointer;transition:all .18s;
    }
    .tab-pill.active { background:#2563eb;color:#fff;box-shadow:0 4px 12px rgba(37,99,235,.25); }
    .tab-pill:not(.active) { background:#fff;color:#64748b;border:1px solid #e2e8f0; }
    .tab-pill:not(.active):hover { background:#f8fafc;color:#1e293b; }

    /* Info text rows */
    .info-row { display:flex;align-items:center;gap:8px;font-size:12.5px;color:#475569; }
    .info-row i { font-size:15px;color:#94a3b8;flex-shrink:0; }

    /* Scroll reveal animation */
    .reveal{opacity:0;transform:translateY(20px);transition:opacity .5s cubic-bezier(.22,1,.36,1),transform .5s cubic-bezier(.22,1,.36,1)}
    .reveal.visible{opacity:1;transform:translateY(0)}
    .d0{transition-delay:0ms}.d1{transition-delay:60ms}.d2{transition-delay:120ms}.d3{transition-delay:180ms}
    .d4{transition-delay:240ms}.d5{transition-delay:300ms}

    @keyframes contentZoomIn { from{opacity:0;transform:scale(.975)} to{opacity:1;transform:scale(1)} }
    main { animation:contentZoomIn .35s cubic-bezier(.34,1.56,.64,1) forwards; transform-origin:center top; }

    ::-webkit-scrollbar{width:5px;height:5px}::-webkit-scrollbar-track{background:transparent}
    ::-webkit-scrollbar-thumb{background:#cbd5e1;border-radius:99px}
  </style>
</head>
<body class="bg-zinc-50 text-zinc-900 min-h-screen">

<jsp:include page="common/sidebar.jsp"/>

<!-- ── TOP BAR ── -->
<jsp:include page="/admin/common/header.jsp">
  <jsp:param name="pageTitle" value="Quản lý Owner / Đối tác"/>
</jsp:include>

<!-- ── MAIN ── -->
<main class="lg:ml-[260px] mt-[64px] p-4 lg:p-6 flex flex-col gap-6">

  <!-- Flash messages -->
  <c:if test="${not empty sessionScope.message}">
    <div class="reveal flex items-start gap-3 p-4 bg-green-50 border border-green-100 rounded-2xl text-green-600 text-sm">
      <i class="ti ti-circle-check text-xl shrink-0 mt-0.5"></i>
      <div>
        <span class="font-bold block text-green-700">Thành công</span>
        <span class="text-green-600/90 mt-0.5 block"><c:out value="${sessionScope.message}"/></span>
      </div>
    </div>
    <c:remove var="message" scope="session"/>
  </c:if>
  <c:if test="${not empty sessionScope.error}">
    <div class="reveal flex items-start gap-3 p-4 bg-red-50 border border-red-100 rounded-2xl text-red-600 text-sm">
      <i class="ti ti-alert-circle text-xl shrink-0 mt-0.5"></i>
      <div>
        <span class="font-bold block text-red-700">Lỗi thao tác</span>
        <span class="text-red-600/90 mt-0.5 block"><c:out value="${sessionScope.error}"/></span>
      </div>
    </div>
    <c:remove var="error" scope="session"/>
  </c:if>

  <!-- Page header -->
  <section class="reveal d0 flex flex-col md:flex-row md:items-center justify-between gap-4">
    <div>
      <h2 class="text-xl font-black text-zinc-900 tracking-tight">Đơn đăng ký đối tác</h2>
      <p class="text-xs text-zinc-500 mt-0.5">Duyệt hoặc từ chối các cơ sở đăng ký qua kênh owner. Quản lý trạng thái tài khoản.</p>
    </div>
  </section>

  <!-- Count cards -->
  <section class="reveal d1 grid grid-cols-1 sm:grid-cols-2 gap-4">
    <div class="bg-white border border-zinc-200/80 rounded-2xl p-4 flex items-center gap-4 hover:shadow-sm transition-all">
      <div class="w-12 h-12 rounded-xl bg-amber-50 text-amber-600 border border-amber-100 flex items-center justify-center shrink-0">
        <i class="ti ti-clock-hour-4 text-2xl"></i>
      </div>
      <div>
        <p class="text-2xl font-black text-zinc-900">${pending.size()}</p>
        <p class="text-xs text-zinc-400 font-semibold tracking-wide uppercase">Chờ duyệt</p>
      </div>
    </div>
    <div class="bg-white border border-zinc-200/80 rounded-2xl p-4 flex items-center gap-4 hover:shadow-sm transition-all">
      <div class="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-600 border border-emerald-100 flex items-center justify-center shrink-0">
        <i class="ti ti-circle-check text-2xl"></i>
      </div>
      <div>
        <p class="text-2xl font-black text-zinc-900">${approved.size()}</p>
        <p class="text-xs text-zinc-400 font-semibold tracking-wide uppercase">Đang hoạt động</p>
      </div>
    </div>
  </section>

  <!-- Tab bar -->
  <section class="reveal d2 flex items-center gap-2">
    <button class="tab-pill active" id="tabPending" onclick="switchTab('pending', this)">
      <i class="ti ti-clock-hour-4 text-sm"></i>
      Chờ duyệt
      <c:if test="${pending.size() > 0}">
        <span class="ml-1 bg-amber-100 text-amber-700 rounded-md px-2 py-0.5 text-[10px] font-bold">${pending.size()}</span>
      </c:if>
    </button>
    <button class="tab-pill" id="tabApproved" onclick="switchTab('approved', this)">
      <i class="ti ti-circle-check text-sm"></i>
      Đang hoạt động
      <c:if test="${approved.size() > 0}">
        <span class="ml-1 bg-emerald-100 text-emerald-700 rounded-md px-2 py-0.5 text-[10px] font-bold">${approved.size()}</span>
      </c:if>
    </button>
    <a href="${pageContext.request.contextPath}/admin/thung-rac?loai=OwnerRequest"
       class="ml-auto flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold text-zinc-500 hover:text-zinc-700 hover:bg-zinc-100 transition-all">
      <i class="ti ti-trash text-sm"></i>Yêu cầu đã từ chối (thùng rác)
    </a>
  </section>

  <!-- ══ TAB: Chờ duyệt ══ -->
  <div id="tab-pending" class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
    <c:choose>
      <c:when test="${empty pending}">
        <div class="col-span-full flex flex-col items-center justify-center py-20 text-zinc-400 bg-white border border-zinc-200 rounded-2xl shadow-xs">
          <i class="ti ti-inbox text-5xl mb-3 opacity-30"></i>
          <p class="text-sm font-semibold">Không có đơn đăng ký nào đang chờ duyệt</p>
        </div>
      </c:when>
      <c:otherwise>
        <c:forEach var="row" items="${pending}" varStatus="st">
          <c:set var="cs"  value="${row.coSo}"/>
          <c:set var="mgr" value="${row.manager}"/>
          <div class="owner-card card-pending reveal d${st.index < 6 ? st.index : 5} p-5 flex flex-col gap-4">
            
            <!-- Top row: Avatar + Facility details -->
            <div class="flex items-start gap-4">
              <div class="owner-avatar">
                <i class="ti ti-building-stadium text-2xl"></i>
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-start justify-between gap-2">
                  <div class="min-w-0">
                    <p class="font-bold text-zinc-900 text-base leading-tight truncate"><c:out value="${cs.tenCoSo}"/></p>
                    <p class="text-[11px] text-amber-600 font-semibold mt-1">
                      <i class="ti ti-user-star mr-0.5"></i>Owner: <c:out value="${mgr.fullName}"/>
                    </p>
                  </div>
                  <span class="badge badge-amber shrink-0">Chờ duyệt</span>
                </div>
              </div>
            </div>

            <!-- Divider -->
            <div class="border-t border-zinc-100"></div>

            <!-- Details -->
            <div class="flex flex-col gap-2">
              <div class="info-row">
                <i class="ti ti-mail"></i>
                <span class="truncate"><c:out value="${mgr.email}"/></span>
              </div>
              <div class="info-row">
                <i class="ti ti-phone"></i>
                <span><c:out value="${cs.soDienThoai}"/></span>
              </div>
              <div class="info-row">
                <i class="ti ti-map-pin"></i>
                <span class="line-clamp-2 leading-relaxed"><c:out value="${cs.diaChi}"/></span>
              </div>
              <c:if test="${not empty cs.loaiHinhKinhDoanh}">
                <div class="info-row">
                  <i class="ti ti-ball-football"></i>
                  <span class="truncate"><c:out value="${cs.loaiHinhKinhDoanh}"/></span>
                </div>
              </c:if>
              <c:if test="${cs.soLuongSanDuKien > 0}">
                <div class="info-row font-semibold">
                  <i class="ti ti-grid-pattern"></i>
                  <span>Quy mô: <strong class="text-zinc-700">${cs.soLuongSanDuKien} sân</strong></span>
                </div>
              </c:if>
            </div>

            <c:if test="${not empty row.capabilities}">
              <div class="border-t border-zinc-100"></div>
              <div class="flex flex-col gap-2">
                <p class="text-[10px] font-bold tracking-wider uppercase text-zinc-400">Loại hình kinh doanh đăng ký thêm</p>
                <c:forEach var="cap" items="${row.capabilities}">
                  <%@ include file="_capability-row.jspf" %>
                </c:forEach>
              </div>
            </c:if>

            <!-- Action buttons -->
            <div class="flex items-center justify-end gap-2 pt-1 border-t border-zinc-100 mt-auto">
              <a href="?action=duyet&id=${cs.coSoID}"
                 onclick="return confirm('Duyệt cơ sở \'${cs.tenCoSo}\' và kích hoạt tài khoản quản lý?')"
                 class="flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 transition-all shadow-md shadow-emerald-100">
                <i class="ti ti-circle-check text-sm"></i>Duyệt đăng ký
              </a>
              <a href="?action=tu-choi&id=${cs.coSoID}"
                 onclick="return confirm('Từ chối đăng ký cơ sở \'${cs.tenCoSo}\'?')"
                 class="flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs font-semibold text-red-500 bg-red-50 hover:bg-red-100 hover:border-red-200 border border-transparent transition-all">
                <i class="ti ti-circle-x text-sm"></i>Từ chối
              </a>
            </div>

          </div>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </div>

  <!-- ══ TAB: Đang hoạt động ══ -->
  <div id="tab-approved" class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5 hidden">
    <c:choose>
      <c:when test="${empty approved}">
        <div class="col-span-full flex flex-col items-center justify-center py-20 text-zinc-400 bg-white border border-zinc-200 rounded-2xl shadow-xs">
          <i class="ti ti-domain-off text-5xl mb-3 opacity-30"></i>
          <p class="text-sm font-semibold">Chưa có cơ sở đối tác nào đang hoạt động</p>
        </div>
      </c:when>
      <c:otherwise>
        <c:forEach var="row" items="${approved}" varStatus="st">
          <c:set var="cs"  value="${row.coSo}"/>
          <c:set var="mgr" value="${row.manager}"/>
          <div class="owner-card card-approved reveal d${st.index < 6 ? st.index : 5} p-5 flex flex-col gap-4">

            <!-- Top row: Avatar + Facility details -->
            <div class="flex items-start gap-4">
              <div class="owner-avatar !bg-emerald-50 !color-emerald-600 !border-emerald-200">
                <i class="ti ti-building-stadium text-2xl text-emerald-600"></i>
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-start justify-between gap-2">
                  <div class="min-w-0">
                    <p class="font-bold text-zinc-900 text-base leading-tight truncate"><c:out value="${cs.tenCoSo}"/></p>
                    <p class="text-[11px] text-emerald-600 font-semibold mt-1">
                      <i class="ti ti-user-check mr-0.5"></i>Owner: <c:out value="${mgr.fullName}"/>
                    </p>
                  </div>
                  <div class="flex flex-col gap-1 items-end shrink-0">
                    <span class="badge badge-green">Hoạt động</span>
                    <c:if test="${mgr.isLocked}">
                      <span class="badge badge-red">Đã khóa</span>
                    </c:if>
                  </div>
                </div>
              </div>
            </div>

            <!-- Divider -->
            <div class="border-t border-zinc-100"></div>

            <!-- Details -->
            <div class="flex flex-col gap-2">
              <div class="info-row">
                <i class="ti ti-mail"></i>
                <span class="truncate"><c:out value="${mgr.email}"/></span>
              </div>
              <div class="info-row">
                <i class="ti ti-phone"></i>
                <span><c:out value="${cs.soDienThoai}"/></span>
              </div>
              <div class="info-row">
                <i class="ti ti-map-pin"></i>
                <span class="line-clamp-2 leading-relaxed"><c:out value="${cs.diaChi}"/></span>
              </div>
              <c:if test="${not empty cs.loaiHinhKinhDoanh}">
                <div class="info-row">
                  <i class="ti ti-ball-football"></i>
                  <span class="truncate"><c:out value="${cs.loaiHinhKinhDoanh}"/></span>
                </div>
              </c:if>
              <c:if test="${cs.soLuongSanDuKien > 0}">
                <div class="info-row font-semibold">
                  <i class="ti ti-grid-pattern"></i>
                  <span>Quy mô: <strong class="text-zinc-700">${cs.soLuongSanDuKien} sân</strong></span>
                </div>
              </c:if>
            </div>

            <c:if test="${not empty row.capabilities}">
              <div class="border-t border-zinc-100"></div>
              <div class="flex flex-col gap-2">
                <p class="text-[10px] font-bold tracking-wider uppercase text-zinc-400">Loại hình kinh doanh</p>
                <c:forEach var="cap" items="${row.capabilities}">
                  <%@ include file="_capability-row.jspf" %>
                </c:forEach>
              </div>
            </c:if>

            <!-- Action buttons -->
            <div class="flex items-center justify-end gap-2 pt-1 border-t border-zinc-100 mt-auto">
              <c:choose>
                <c:when test="${mgr.isLocked}">
                  <a href="?action=mo-khoa&id=${cs.coSoID}"
                     onclick="return confirm('Mở khóa tài khoản owner \'${mgr.fullName}\'?')"
                     class="flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 transition-all shadow-md shadow-blue-100">
                    <i class="ti ti-lock-open text-sm"></i>Mở khóa tài khoản
                  </a>
                </c:when>
                <c:otherwise>
                  <a href="?action=khoa&id=${cs.coSoID}"
                     onclick="return confirm('Khóa tài khoản owner \'${mgr.fullName}\'? Owner sẽ không thể đăng nhập.')"
                     class="flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs font-semibold text-red-500 bg-red-50 hover:bg-red-100 hover:border-red-200 border border-transparent transition-all">
                    <i class="ti ti-lock text-sm"></i>Khóa tài khoản
                  </a>
                </c:otherwise>
              </c:choose>
            </div>

          </div>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </div>


</main>

<script>
  // Mobile sidebar menu toggler
  const mobileMenuBtn = document.getElementById('mobileMenuBtn');
  const sidebar = document.getElementById('sidebar');
  if (mobileMenuBtn && sidebar) {
    mobileMenuBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      sidebar.classList.toggle('-translate-x-full');
    });
  }

  // Duyệt/từ chối/tạm ngưng/kích hoạt lại một capability cụ thể - tách biệt hoàn
  // toàn với duyệt/từ chối cơ sở ở trên (action + id khác nhau).
  function capabilityAction(action, capabilityId, label, needReason) {
    var reason = '';
    if (needReason) {
      reason = window.prompt('Nhập lý do: ' + label);
      if (reason === null) return false;
      if (!reason.trim()) { window.alert('Vui lòng nhập lý do.'); return false; }
    } else if (!window.confirm(label + '?')) {
      return false;
    }
    var params = new URLSearchParams();
    params.set('action', action);
    params.set('capabilityId', capabilityId);
    if (needReason) params.set('reason', reason.trim());
    window.location.href = '?' + params.toString();
    return false;
  }

  // Switch tabs
  function switchTab(name, btn) {
    ['pending','approved'].forEach(function(t) {
      document.getElementById('tab-' + t).classList.add('hidden');
    });
    document.getElementById('tab-' + name).classList.remove('hidden');
    document.querySelectorAll('.tab-pill').forEach(function(b) { b.classList.remove('active'); });
    btn.classList.add('active');
    
    // Trigger scroll-reveal
    var newEls = document.querySelectorAll('#tab-' + name + ' .reveal:not(.visible)');
    newEls.forEach(function(el, i) {
      setTimeout(function() { el.classList.add('visible'); }, i * 60);
    });
  }

  // Initialize scroll reveal
  (function() {
    var io = new IntersectionObserver(function(entries) {
      entries.forEach(function(e) {
        if (e.isIntersecting) {
          e.target.classList.add('visible');
          io.unobserve(e.target);
        }
      });
    }, { threshold: 0.06 });
    document.querySelectorAll('.reveal').forEach(function(el) { io.observe(el); });
  })();
</script>
</body>
</html>
