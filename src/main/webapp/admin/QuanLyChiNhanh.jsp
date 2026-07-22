<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Quản lý Cơ Sở — V-SPORT</title>
<script src="https://cdn.tailwindcss.com"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/dist/tabler-icons.min.css"/>
<style>
body { font-family: 'Inter', sans-serif; }
  .badge { display:inline-flex;align-items:center;padding:3px 10px;border-radius:99px;font-size:11px;font-weight:700;letter-spacing:.02em; }
  .badge-green  { background:#dcfce7;color:#15803d; }
  .badge-red    { background:#fee2e2;color:#b91c1c; }
  .badge-amber  { background:#fef3c7;color:#b45309; }
  .badge-gray   { background:#f4f4f5;color:#52525b; }

  /* Card */
  .cs-card {
    background:#fff;border:1px solid #e4e4e7;border-radius:18px;
    transition:box-shadow .22s,transform .22s;
    position:relative;overflow:hidden;
  }
  .cs-card::before {
    content:'';position:absolute;top:0;left:0;right:0;height:3px;
    background:linear-gradient(90deg,#2563eb,#60a5fa);
    opacity:0;transition:opacity .22s;
  }
  .cs-card:hover { box-shadow:0 8px 32px -8px rgba(37,99,235,.15); transform:translateY(-2px); }
  .cs-card:hover::before { opacity:1; }

  /* Avatar */
  .cs-avatar {
    width:72px;height:72px;border-radius:16px;object-fit:cover;
    border:3px solid #fff;box-shadow:0 4px 16px rgba(0,0,0,.08);
    background:#f1f5f9;flex-shrink:0;
  }
  .cs-avatar-placeholder {
    width:72px;height:72px;border-radius:16px;
    background:linear-gradient(135deg,#dbeafe,#bfdbfe);
    display:flex;align-items:center;justify-content:center;
    border:3px solid #fff;box-shadow:0 4px 16px rgba(0,0,0,.08);
    flex-shrink:0;
  }

  /* Sport tag */
  .sport-tag {
    display:inline-flex;align-items:center;gap:4px;padding:3px 8px;
    border-radius:99px;font-size:10px;font-weight:600;
    background:#eff6ff;color:#2563eb;border:1px solid #bfdbfe;
  }

  /* Info row */
  .info-row { display:flex;align-items:center;gap:6px;font-size:12px;color:#64748b; }
  .info-row .ti { font-size:14px;color:#94a3b8;flex-shrink:0; }

  /* Scroll reveal */
  .reveal{opacity:0;transform:translateY(20px);transition:opacity .5s cubic-bezier(.22,1,.36,1),transform .5s cubic-bezier(.22,1,.36,1)}
  .reveal.visible{opacity:1;transform:translateY(0)}
  .d0{transition-delay:0ms}.d1{transition-delay:60ms}.d2{transition-delay:120ms}.d3{transition-delay:180ms}
  .d4{transition-delay:240ms}.d5{transition-delay:300ms}

  @keyframes contentZoomIn { from{opacity:0;transform:scale(.97)} to{opacity:1;transform:scale(1)} }
  main { animation:contentZoomIn .35s cubic-bezier(.34,1.56,.64,1) forwards; transform-origin:center top; }

  ::-webkit-scrollbar{width:5px;height:5px}::-webkit-scrollbar-track{background:transparent}
  ::-webkit-scrollbar-thumb{background:#cbd5e1;border-radius:99px}

  /* Stat badge */
  .stat-chip {
    display:inline-flex;align-items:center;gap:5px;padding:6px 14px;
    border-radius:99px;font-size:12px;font-weight:600;
  }

  /* Tab pills */
  .tab-pill {
    display:inline-flex;align-items:center;gap:6px;padding:7px 16px;
    border-radius:12px;font-size:13px;font-weight:600;
    border:1px solid #e4e4e7;background:#fff;color:#71717a;
    cursor:pointer;transition:all .18s;
  }
  .tab-pill:hover { background:#f4f4f5;color:#3f3f46; }
  .tab-pill.active { background:#2563eb;color:#fff;border-color:#2563eb;box-shadow:0 2px 8px rgba(37,99,235,.25); }

  /* Request card */
  .req-card {
    background:#fff;border:1px solid #e4e4e7;border-radius:16px;
    padding:18px;cursor:pointer;transition:all .18s;
  }
  .req-card:hover { box-shadow:0 4px 20px -4px rgba(0,0,0,.12);border-color:#cbd5e1; }
  .req-card.selected { border-color:#2563eb;box-shadow:0 0 0 2px rgba(37,99,235,.15); }

  /* Drawer */
  #detailDrawer {
    position:fixed;top:64px;right:0;bottom:0;width:420px;
    background:#fff;border-left:1px solid #e4e4e7;
    box-shadow:-8px 0 32px rgba(0,0,0,.08);
    transform:translateX(100%);transition:transform .28s cubic-bezier(.4,0,.2,1);
    z-index:60;display:flex;flex-direction:column;overflow:hidden;
  }
  #detailDrawer.open { transform:translateX(0); }

  /* Capability chip */
  .cap-chip {
    display:inline-flex;align-items:center;gap:4px;padding:3px 10px;
    border-radius:8px;font-size:11px;font-weight:600;
    background:#eff6ff;color:#2563eb;border:1px solid #bfdbfe;
  }
  .cap-chip.pending { background:#fffbeb;color:#92400e;border-color:#fde68a; }
  .cap-chip.approved { background:#f0fdf4;color:#166534;border-color:#bbf7d0; }
  .cap-chip.rejected { background:#fef2f2;color:#991b1b;border-color:#fecaca; }
</style>
</head>
<body class="bg-zinc-50 text-zinc-900 min-h-screen">

<!-- Sidebar -->
<jsp:include page="/admin/common/sidebar.jsp" />

<!-- Header -->
<jsp:include page="/admin/common/header.jsp">
  <jsp:param name="pageTitle" value="Cấu hình Cơ Sở"/>
</jsp:include>

<!-- Main Content -->
<main class="lg:ml-[260px] mt-[64px] p-4 lg:p-6 flex flex-col gap-6">

  <!-- Alert Messages -->
  <c:if test="${not empty sessionScope.error}">
    <div class="flex items-start gap-3 p-4 bg-red-50 border border-red-100 rounded-2xl text-red-600 text-sm">
      <i class="ti ti-alert-circle text-xl shrink-0 mt-0.5"></i>
      <div>
        <span class="font-bold block text-red-700">Lỗi thao tác</span>
        <span class="text-red-600/90 mt-0.5 block">${sessionScope.error}</span>
      </div>
    </div>
    <% session.removeAttribute("error"); %>
  </c:if>
  <c:if test="${not empty sessionScope.message}">
    <div class="flex items-start gap-3 p-4 bg-green-50 border border-green-100 rounded-2xl text-green-600 text-sm">
      <i class="ti ti-circle-check text-xl shrink-0 mt-0.5"></i>
      <div>
        <span class="font-bold block text-green-700">Thành công</span>
        <span class="text-green-600/90 mt-0.5 block">${sessionScope.message}</span>
      </div>
    </div>
    <% session.removeAttribute("message"); %>
  </c:if>

  <!-- ── Tiêu đề ── -->
  <section class="reveal d0">
    <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
      <div>
        <h2 class="text-xl font-black text-zinc-900 tracking-tight">Quản lý Cơ Sở</h2>
        <p class="text-xs text-zinc-500 mt-0.5">Quản lý tất cả cơ sở thể thao, duyệt yêu cầu đăng ký đối tác.</p>
      </div>
      <div class="flex items-center gap-2">
        <button onclick="document.getElementById('modalThem').classList.remove('hidden')"
                class="flex items-center gap-2 h-10 px-5 rounded-xl bg-blue-600 text-white text-sm font-semibold hover:bg-blue-700 transition-all shadow-lg shadow-blue-200">
          <i class="ti ti-map-pin-plus text-base"></i>Thêm Cơ Sở
        </button>
      </div>
    </div>
  </section>

  <!-- ── Tab bar ── -->
  <section class="reveal d1 flex items-center gap-2 flex-wrap">
    <button id="tab-btn-all" onclick="switchTab('all')"
            class="tab-pill active">
      <i class="ti ti-building-stadium text-sm"></i>
      Tất cả cơ sở
      <span class="ml-1 bg-blue-100 text-blue-700 rounded-md px-2 py-0.5 text-[10px] font-bold">${dsChiNhanh.size()}</span>
    </button>
    <button id="tab-btn-pending" onclick="switchTab('pending')"
            class="tab-pill relative">
      <i class="ti ti-clock-hour-4 text-sm"></i>
      Chờ duyệt
      <c:if test="${pendingCount > 0}">
        <span class="ml-1 bg-amber-100 text-amber-700 rounded-md px-2 py-0.5 text-[10px] font-bold">${pendingCount}</span>
      </c:if>
    </button>
    <button id="tab-btn-rejected" onclick="switchTab('rejected')"
            class="tab-pill">
      <i class="ti ti-circle-x text-sm"></i>
      Đã từ chối
      <c:if test="${not empty rejectedRequests}">
        <span class="ml-1 bg-zinc-100 text-zinc-600 rounded-md px-2 py-0.5 text-[10px] font-bold">${rejectedRequests.size()}</span>
      </c:if>
    </button>
    <a href="${pageContext.request.contextPath}/admin/thung-rac?loai=OwnerRequest"
       class="ml-auto flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold text-zinc-500 hover:text-zinc-700 hover:bg-zinc-100 transition-all">
      <i class="ti ti-trash text-sm"></i>Thùng rác đăng ký
    </a>
  </section>

  <!-- ══ TAB: Tất cả cơ sở ══ -->
  <div id="tab-all">
  <!-- ── Grid Cards ── -->
  <section class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
    <c:forEach var="cn" items="${dsChiNhanh}" varStatus="st">
      <c:set var="delay" value="${st.index < 6 ? st.index : 5}"/>
      <div class="cs-card reveal d${delay} p-5 flex flex-col gap-4">

        <!-- Top row: avatar + name + status -->
        <div class="flex items-start gap-4">
          <c:choose>
            <c:when test="${not empty cn.hinhAnh}">
              <img src="${cn.hinhAnh}" alt="${cn.tenCoSo}" class="cs-avatar">
            </c:when>
            <c:otherwise>
              <div class="cs-avatar-placeholder">
                <i class="ti ti-building-stadium text-blue-500 text-3xl"></i>
              </div>
            </c:otherwise>
          </c:choose>
          <div class="flex-1 min-w-0">
            <div class="flex items-start justify-between gap-2">
              <div class="min-w-0">
                <p class="font-bold text-zinc-900 text-base leading-tight truncate">${cn.tenCoSo}</p>
                <c:if test="${not empty cn.loaiHinhKinhDoanh}">
                  <div class="flex flex-wrap gap-1 mt-1.5">
                    <c:forTokens items="${cn.loaiHinhKinhDoanh}" delims="," var="sport">
                      <span class="sport-tag">
                        <i class="ti ti-ball-football text-[10px]"></i>${sport.trim()}
                      </span>
                    </c:forTokens>
                  </div>
                </c:if>
              </div>
              <span class="badge ${cn.trangThai == 'Đang hoạt động' ? 'badge-green' : 'badge-red'} shrink-0">
                ${cn.trangThai}
              </span>
            </div>
          </div>
        </div>

        <!-- Divider -->
        <div class="border-t border-zinc-100"></div>

        <!-- Info rows -->
        <div class="flex flex-col gap-2">
          <c:if test="${not empty cn.diaChi}">
            <div class="info-row">
              <i class="ti ti-map-pin ti"></i>
              <span class="line-clamp-2 leading-relaxed">${cn.diaChi}</span>
            </div>
          </c:if>
          <c:if test="${not empty cn.soDienThoai}">
            <div class="info-row">
              <i class="ti ti-phone ti"></i>
              <span>${cn.soDienThoai}</span>
            </div>
          </c:if>
          <c:if test="${not empty cn.gioMoCua && not empty cn.gioDongCua}">
            <div class="info-row">
              <i class="ti ti-clock ti"></i>
              <span>${cn.gioMoCua} – ${cn.gioDongCua}</span>
            </div>
          </c:if>
        </div>

        <!-- PayOS status row -->
        <div class="flex items-center justify-between pt-1">
          <div class="flex items-center gap-1.5 text-xs">
            <i class="ti ti-credit-card text-sm text-zinc-400"></i>
            <span class="text-zinc-500">PayOS:</span>
            <c:choose>
              <c:when test="${payosStatusMap[cn.coSoID] == 'CONFIGURED'}">
                <span id="payosBadge${cn.coSoID}" class="badge badge-green">Đã cấu hình</span>
              </c:when>
              <c:when test="${payosStatusMap[cn.coSoID] == 'PARTIAL'}">
                <span id="payosBadge${cn.coSoID}" class="badge badge-amber">Thiếu thông tin</span>
              </c:when>
              <c:otherwise>
                <span id="payosBadge${cn.coSoID}" class="badge badge-gray">Chưa cấu hình</span>
              </c:otherwise>
            </c:choose>
          </div>
          <button type="button" onclick="openPayOSModal(${cn.coSoID}, '${cn.tenCoSo}')"
                  class="flex items-center gap-1 px-2.5 py-1 rounded-lg text-[11px] font-semibold text-zinc-600 bg-zinc-50 hover:bg-zinc-100 border border-zinc-200 transition-all">
            <i class="ti ti-settings text-xs"></i>Cấu hình
          </button>
        </div>

        <!-- Action buttons -->
        <div class="flex items-center justify-end gap-2 pt-1 border-t border-zinc-100 mt-auto">
          <button onclick="confirmDelete(${cn.coSoID}, '${cn.tenCoSo}')"
                  class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold text-red-500 bg-red-50 hover:bg-red-100 transition-all">
            <i class="ti ti-trash text-sm"></i>Xóa
          </button>
        </div>

      </div>
    </c:forEach>

    <!-- Empty state -->
    <c:if test="${empty dsChiNhanh}">
      <div class="md:col-span-2 xl:col-span-3 flex flex-col items-center justify-center py-20 text-zinc-400">
        <i class="ti ti-building-stadium text-6xl mb-4 opacity-30"></i>
        <p class="text-base font-semibold">Chưa có cơ sở nào</p>
        <p class="text-sm mt-1">Nhấn "Thêm Cơ Sở" để tạo chi nhánh đầu tiên</p>
      </div>
    </c:if>
  </section>
  </div><!-- /tab-all -->

  <!-- ══ TAB: Yêu cầu chờ duyệt ══ -->
  <div id="tab-pending" style="display:none">
    <c:choose>
      <c:when test="${empty pendingRequests}">
        <div class="flex flex-col items-center justify-center py-24 text-zinc-400">
          <i class="ti ti-clock-check text-6xl mb-4 opacity-30"></i>
          <p class="text-base font-semibold">Không có yêu cầu chờ duyệt</p>
          <p class="text-sm mt-1">Tất cả yêu cầu đăng ký đối tác đã được xử lý</p>
        </div>
      </c:when>
      <c:otherwise>
        <div class="flex flex-col gap-3">
          <c:forEach var="row" items="${pendingRequests}" varStatus="st">
            <c:set var="cs" value="${row.coSo}"/>
            <c:set var="mgr" value="${row.manager}"/>
            <div class="req-card" id="req-pending-${cs.coSoID}"
                 onclick="openDrawer(${cs.coSoID}, 'pending')">
              <div class="flex items-start gap-4">
                <!-- Avatar -->
                <div class="w-12 h-12 rounded-xl bg-amber-50 border border-amber-100 flex items-center justify-center shrink-0">
                  <i class="ti ti-user-circle text-amber-500 text-2xl"></i>
                </div>
                <!-- Info -->
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 flex-wrap">
                    <p class="font-bold text-zinc-900 text-sm truncate">${cs.tenCoSo}</p>
                    <span class="badge badge-amber">Chờ duyệt</span>
                  </div>
                  <p class="text-xs text-zinc-500 mt-0.5 truncate">
                    <i class="ti ti-user text-zinc-400 mr-1"></i>${mgr.fullName} &bull; ${mgr.email}
                  </p>
                  <p class="text-xs text-zinc-500 mt-0.5 truncate">
                    <i class="ti ti-map-pin text-zinc-400 mr-1"></i>${cs.diaChi}
                  </p>
                  <div class="flex flex-wrap gap-1 mt-2">
                    <c:forEach var="cap" items="${row.capabilities}">
                      <span class="cap-chip ${cap.trangThai == 'APPROVED' ? 'approved' : cap.trangThai == 'REJECTED' ? 'rejected' : 'pending'}">
                        <i class="ti ti-check-circle text-[10px]"></i>${cap.capabilityType}
                      </span>
                    </c:forEach>
                  </div>
                </div>
                <!-- Arrow -->
                <i class="ti ti-chevron-right text-zinc-300 text-xl shrink-0 mt-1"></i>
              </div>
            </div>
          </c:forEach>
        </div>
      </c:otherwise>
    </c:choose>
  </div><!-- /tab-pending -->

  <!-- ══ TAB: Đã từ chối ══ -->
  <div id="tab-rejected" style="display:none">
    <c:choose>
      <c:when test="${empty rejectedRequests}">
        <div class="flex flex-col items-center justify-center py-24 text-zinc-400">
          <i class="ti ti-circle-x text-6xl mb-4 opacity-30"></i>
          <p class="text-base font-semibold">Chưa có yêu cầu bị từ chối</p>
        </div>
      </c:when>
      <c:otherwise>
        <div class="flex flex-col gap-3">
          <c:forEach var="row" items="${rejectedRequests}">
            <c:set var="cs" value="${row.coSo}"/>
            <c:set var="mgr" value="${row.manager}"/>
            <div class="req-card" id="req-rejected-${cs.coSoID}"
                 onclick="openDrawer(${cs.coSoID}, 'rejected')">
              <div class="flex items-start gap-4">
                <div class="w-12 h-12 rounded-xl bg-red-50 border border-red-100 flex items-center justify-center shrink-0">
                  <i class="ti ti-circle-x text-red-400 text-2xl"></i>
                </div>
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 flex-wrap">
                    <p class="font-bold text-zinc-900 text-sm truncate">${cs.tenCoSo}</p>
                    <span class="badge badge-red">Từ chối</span>
                  </div>
                  <p class="text-xs text-zinc-500 mt-0.5 truncate">
                    <i class="ti ti-user text-zinc-400 mr-1"></i>${mgr.fullName} &bull; ${mgr.email}
                  </p>
                  <p class="text-xs text-zinc-500 mt-0.5 truncate">
                    <i class="ti ti-map-pin text-zinc-400 mr-1"></i>${cs.diaChi}
                  </p>
                </div>
                <i class="ti ti-chevron-right text-zinc-300 text-xl shrink-0 mt-1"></i>
              </div>
            </div>
          </c:forEach>
        </div>
      </c:otherwise>
    </c:choose>
  </div><!-- /tab-rejected -->

</main>

<!-- ═══ Detail Drawer ═══ -->
<div id="detailDrawer">
  <!-- Header -->
  <div class="flex items-center justify-between px-5 py-4 border-b border-zinc-100 shrink-0">
    <h3 class="font-bold text-zinc-900 text-sm" id="drawerTitle">Chi tiết yêu cầu</h3>
    <button onclick="closeDrawer()" class="w-8 h-8 rounded-lg hover:bg-zinc-100 flex items-center justify-center transition-all">
      <i class="ti ti-x text-zinc-500"></i>
    </button>
  </div>

  <!-- Body (scrollable) -->
  <div class="flex-1 overflow-y-auto p-5 flex flex-col gap-5" id="drawerBody">
    <!-- Populated by JS from hidden data -->
  </div>

  <!-- Actions (fixed bottom) -->
  <div class="shrink-0 px-5 py-4 border-t border-zinc-100 flex gap-3" id="drawerActions">
  </div>
</div>

<!-- Hidden data store for drawer (JSTL renders all rows, JS reads on click) -->
<script>
var DRAWER_DATA = {};
</script>
<c:forEach var="row" items="${pendingRequests}">
  <c:set var="cs" value="${row.coSo}"/>
  <c:set var="mgr" value="${row.manager}"/>
  <script>
  DRAWER_DATA[${cs.coSoID}] = {
    coSoId: ${cs.coSoID},
    status: "pending",
    tenCoSo: "${fn:escapeXml(cs.tenCoSo)}",
    diaChi: "${fn:escapeXml(cs.diaChi)}",
    sdtCoSo: "${fn:escapeXml(cs.soDienThoai)}",
    mgrId: ${mgr.accountId},
    mgrName: "${fn:escapeXml(mgr.fullName)}",
    mgrEmail: "${fn:escapeXml(mgr.email)}",
    mgrSdt: "${fn:escapeXml(mgr.phoneNumber)}",
    capabilities: [<c:forEach var="cap" items="${row.capabilities}" varStatus="cs2">"${cap.capabilityType}"<c:if test="${!cs2.last}">,</c:if></c:forEach>]
  };
  </script>
</c:forEach>
<c:forEach var="row" items="${rejectedRequests}">
  <c:set var="cs" value="${row.coSo}"/>
  <c:set var="mgr" value="${row.manager}"/>
  <script>
  DRAWER_DATA[${cs.coSoID}] = {
    coSoId: ${cs.coSoID},
    status: "rejected",
    tenCoSo: "${fn:escapeXml(cs.tenCoSo)}",
    diaChi: "${fn:escapeXml(cs.diaChi)}",
    sdtCoSo: "${fn:escapeXml(cs.soDienThoai)}",
    mgrId: ${mgr.accountId},
    mgrName: "${fn:escapeXml(mgr.fullName)}",
    mgrEmail: "${fn:escapeXml(mgr.email)}",
    mgrSdt: "${fn:escapeXml(mgr.phoneNumber)}",
    capabilities: [<c:forEach var="cap" items="${row.capabilities}" varStatus="cs2">"${cap.capabilityType}"<c:if test="${!cs2.last}">,</c:if></c:forEach>]
  };
  </script>
</c:forEach>

<!-- ═══ Modal Xác nhận Xóa ═══ -->
<div id="modalDelete" class="hidden fixed inset-0 z-[90] flex items-center justify-center p-4">
  <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" onclick="closeDelete()"></div>
  <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-[380px] p-6 text-center">
    <div class="w-14 h-14 rounded-2xl bg-red-50 flex items-center justify-center mx-auto mb-4">
      <i class="ti ti-trash text-red-500 text-3xl"></i>
    </div>
    <h3 class="text-base font-bold text-zinc-900 mb-1">Ngừng hoạt động cơ sở?</h3>
    <p class="text-sm text-zinc-500 mb-6 text-left" id="deleteMsg">Khi xác nhận:
      <ul class="list-disc pl-5 mt-1.5 space-y-1">
        <li>Quản lý, nhân viên và bảo vệ của cơ sở sẽ không thể đăng nhập.</li>
        <li>Phiên đăng nhập hiện tại của họ sẽ bị vô hiệu ở lần thao tác tiếp theo.</li>
        <li>Dữ liệu sân, lịch đặt và hóa đơn vẫn được giữ nguyên để khôi phục sau này.</li>
      </ul>
    </p>
    <div class="flex gap-3">
      <button onclick="closeDelete()" class="flex-1 h-10 rounded-xl border border-zinc-200 text-sm font-semibold text-zinc-600 hover:bg-zinc-50 transition-all">Hủy</button>
      <a id="deleteBtn" href="#" class="flex-1 h-10 rounded-xl bg-red-500 text-white text-sm font-semibold hover:bg-red-600 transition-all flex items-center justify-center gap-1.5 shadow-md shadow-red-200">
        <i class="ti ti-trash text-sm"></i>Ngừng hoạt động
      </a>
    </div>
  </div>
</div>

<!-- ═══ Modal Thêm Cơ Sở (3 bước) ═══ -->
<div id="modalThem" class="hidden fixed inset-0 z-[80] flex items-center justify-center p-4">
  <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" onclick="closeModalThem()"></div>
  <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-[560px] max-h-[92vh] flex flex-col">

    <!-- Header cố định -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-zinc-100 shrink-0">
      <div class="flex items-center gap-3">
        <h3 class="text-base font-bold text-zinc-900">Thêm Cơ Sở mới</h3>
        <!-- Step bar -->
        <div class="flex items-center gap-1">
          <span id="sDot1" class="w-6 h-1.5 rounded-full bg-blue-600 transition-all"></span>
          <span id="sDot2" class="w-6 h-1.5 rounded-full bg-zinc-200 transition-all"></span>
          <span id="sDot3" class="w-6 h-1.5 rounded-full bg-zinc-200 transition-all"></span>
        </div>
        <span id="sLabel" class="text-xs text-zinc-400 font-medium">Bước 1 / 3</span>
      </div>
      <button onclick="closeModalThem()" class="p-1.5 rounded-lg hover:bg-zinc-100 text-zinc-400">
        <i class="ti ti-x text-lg"></i>
      </button>
    </div>

    <!-- ══ BƯỚC 1: Thông tin cơ bản ══ -->
    <div id="aStep1" class="overflow-y-auto p-6 flex flex-col gap-4">
      <div id="adminAddError" class="hidden px-4 py-3 bg-red-50 border border-red-200 rounded-xl text-sm text-red-600 font-medium"></div>

      <div>
        <p class="text-sm font-semibold text-zinc-800 mb-1">Thông tin cơ bản</p>
        <p class="text-xs text-zinc-400">Nhập thông tin cơ sở. OTP sẽ được gửi đến email để xác minh.</p>
      </div>

      <!-- Tên cơ sở -->
      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-semibold text-zinc-700">Tên Cơ Sở <span class="text-red-500">*</span></label>
        <input type="text" id="adminTenCoSo" placeholder="VD: V-Sport Vũng Tàu"
               class="h-10 px-3 rounded-xl border border-zinc-200 text-sm focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-100 transition-all font-medium">
      </div>

      <!-- Email + SĐT -->
      <div class="grid grid-cols-2 gap-4">
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-zinc-700">Email liên hệ <span class="text-red-500">*</span></label>
          <input type="email" id="adminEmail" placeholder="email@example.com"
                 class="h-10 px-3 rounded-xl border border-zinc-200 text-sm focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-100 transition-all font-medium">
        </div>
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-zinc-700">Số điện thoại <span class="text-red-500">*</span></label>
          <input type="tel" id="adminPhone" placeholder="0912 345 678"
                 class="h-10 px-3 rounded-xl border border-zinc-200 text-sm focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-100 transition-all font-medium">
        </div>
      </div>

      <!-- Địa chỉ -->
      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-semibold text-zinc-700 flex items-center justify-between">
          <span>Địa chỉ <span class="text-red-500">*</span></span>
          <button type="button" onclick="autoFillAddress()" class="flex items-center gap-1.5 text-[10px] font-bold text-blue-600 hover:text-blue-700 bg-blue-50 border border-blue-150 px-2 py-0.5 rounded-lg transition-all normal-case">
            <i class="ti ti-map-pin text-[11px]"></i> Định vị địa chỉ / Tọa độ GG Map
          </button>
        </label>
        <input type="text" id="adminDiaChi" placeholder="Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành"
               class="h-10 px-3 rounded-xl border border-zinc-200 text-sm focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-100 transition-all font-medium">
        <input type="hidden" id="adminViDo">
        <input type="hidden" id="adminKinhDo">
        <p id="adminGeoStatus" class="text-[11px] font-semibold mt-0.5 text-amber-600">
          <i class="ti ti-map-pin-off text-sm align-[-2px]"></i> Chưa xác định tọa độ — nhấn "Định vị địa chỉ / Tọa độ GG Map"
        </p>
      </div>

      <div class="flex justify-end gap-3 pt-3 border-t border-zinc-50">
        <button type="button" onclick="closeModalThem()" class="h-10 px-5 rounded-xl border border-zinc-200 text-sm font-bold text-zinc-600 hover:bg-zinc-50 transition-all">Hủy</button>
        <button type="button" onclick="adminSendOtp()" id="btnSendOtp"
                class="h-10 px-6 rounded-xl bg-blue-600 text-white text-sm font-bold hover:bg-blue-700 transition-all shadow-md shadow-blue-200 flex items-center gap-2">
          <i class="ti ti-send text-sm"></i> Tiếp tục — Xác thực Email
        </button>
      </div>
    </div>

    <!-- ══ BƯỚC 2: Xác thực OTP ══ -->
    <div id="aStep2" class="hidden p-6 flex flex-col gap-5">
      <div class="text-center">
        <div class="w-14 h-14 rounded-2xl bg-blue-50 flex items-center justify-center mx-auto mb-3">
          <i class="ti ti-mail-check text-blue-600 text-3xl"></i>
        </div>
        <h4 class="text-base font-bold text-zinc-900 mb-1">Xác thực Email</h4>
        <p class="text-sm text-zinc-500">Mã OTP 6 chữ số đã được gửi đến</p>
        <p class="text-sm font-semibold text-blue-600 mt-0.5" id="adminOtpEmailDisplay"></p>
      </div>

      <div class="flex justify-center gap-2">
        <input type="text" maxlength="1" class="adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="0"/>
        <input type="text" maxlength="1" class="adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="1"/>
        <input type="text" maxlength="1" class="adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="2"/>
        <input type="text" maxlength="1" class="adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="3"/>
        <input type="text" maxlength="1" class="adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="4"/>
        <input type="text" maxlength="1" class="adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="5"/>
      </div>

      <div id="adminOtpErr" class="hidden text-center text-sm text-red-500 font-medium -mt-2"></div>
      <p class="text-center text-xs text-zinc-400">Số lần nhập sai: <span id="adminOtpFails" class="font-bold text-red-500">0</span>/5</p>

      <button type="button" onclick="adminVerifyOtp()" id="btnVerifyOtp"
              class="w-full h-11 rounded-xl bg-zinc-900 text-white text-sm font-bold hover:bg-zinc-800 transition-all flex items-center justify-center gap-2">
        <i class="ti ti-shield-check text-sm"></i> Xác thực OTP
      </button>
      <div class="flex items-center justify-between -mt-1">
        <button type="button" onclick="adminGoStep(1)" class="text-zinc-400 hover:text-zinc-700 text-sm flex items-center gap-1 bg-transparent border-none cursor-pointer">
          <i class="ti ti-arrow-left text-sm"></i> Quay lại
        </button>
        <button type="button" onclick="adminResendOtp()" id="btnResend"
                class="text-blue-500 hover:text-blue-700 text-sm disabled:opacity-40 bg-transparent border-none cursor-pointer" disabled>
          Gửi lại mã (<span id="admResendCd">60</span>s)
        </button>
      </div>
    </div>

    <!-- ══ BƯỚC 3: Cấu hình sân & Lưu ══ -->
    <div id="aStep3" class="hidden overflow-y-auto">
      <form id="formThemCoSo" action="${pageContext.request.contextPath}/admin/chi-nhanh/them" method="post" class="p-6 flex flex-col gap-4">
        <!-- hidden fields từ bước 1 -->
        <input type="hidden" name="tenCoSo"    id="hTenCoSo">
        <input type="hidden" name="email"       id="hEmail">
        <input type="hidden" name="soDienThoai" id="hPhone">
        <input type="hidden" name="diaChi"      id="hDiaChi">
        <input type="hidden" name="viDo"        id="hViDo">
        <input type="hidden" name="kinhDo"      id="hKinhDo">

        <div>
          <p class="text-sm font-semibold text-zinc-800 mb-0.5">Cấu hình cơ sở <span class="text-green-600 text-xs font-normal">✓ Email đã xác thực</span></p>
          <p class="text-xs text-zinc-400">Chọn môn thể thao, số sân và giờ hoạt động.</p>
        </div>

        <!-- Trạng thái -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-zinc-700">Trạng thái <span class="text-red-500">*</span></label>
          <select name="trangThai" class="h-10 px-3 rounded-xl border border-zinc-200 text-sm focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-100 transition-all font-medium">
            <option value="Đang hoạt động">Đang hoạt động</option>
            <option value="Tạm nghỉ">Tạm nghỉ</option>
          </select>
        </div>

        <!-- Môn thể thao -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-zinc-700">Môn thể thao cung cấp <span class="text-red-500">*</span></label>
          <div class="flex flex-col p-3 bg-zinc-50 rounded-xl border border-zinc-100 gap-0">
            <div class="flex items-center justify-between py-2 border-b border-zinc-200/60">
              <label class="flex items-center gap-2.5 text-sm text-zinc-600 cursor-pointer hover:text-zinc-900 select-none">
                <input type="checkbox" name="loaiHinhKinhDoanh" value="Bóng đá" onchange="toggleSportCount(this,'soLuongSan_BongDa')" class="sport-checkbox w-4 h-4 rounded border-zinc-300 text-blue-600">
                <span class="font-medium">Bóng đá</span>
              </label>
              <div class="flex items-center gap-2">
                <span class="text-xs text-zinc-500">Số sân:</span>
                <input type="number" id="soLuongSan_BongDa" name="soLuongSan_BongDa" value="1" min="1" disabled oninput="updateTotalCourts()"
                       class="sport-count w-16 h-8 px-2 rounded-lg border border-zinc-200 text-sm font-semibold bg-white text-center disabled:bg-zinc-100 disabled:text-zinc-400 focus:outline-none">
              </div>
            </div>
            <div class="flex items-center justify-between py-2 border-b border-zinc-200/60">
              <label class="flex items-center gap-2.5 text-sm text-zinc-600 cursor-pointer hover:text-zinc-900 select-none">
                <input type="checkbox" name="loaiHinhKinhDoanh" value="Cầu lông" onchange="toggleSportCount(this,'soLuongSan_CauLong')" class="sport-checkbox w-4 h-4 rounded border-zinc-300 text-blue-600">
                <span class="font-medium">Cầu lông</span>
              </label>
              <div class="flex items-center gap-2">
                <span class="text-xs text-zinc-500">Số sân:</span>
                <input type="number" id="soLuongSan_CauLong" name="soLuongSan_CauLong" value="1" min="1" disabled oninput="updateTotalCourts()"
                       class="sport-count w-16 h-8 px-2 rounded-lg border border-zinc-200 text-sm font-semibold bg-white text-center disabled:bg-zinc-100 disabled:text-zinc-400 focus:outline-none">
              </div>
            </div>
            <div class="flex items-center justify-between py-2 border-b border-zinc-200/60">
              <label class="flex items-center gap-2.5 text-sm text-zinc-600 cursor-pointer hover:text-zinc-900 select-none">
                <input type="checkbox" name="loaiHinhKinhDoanh" value="Tennis" onchange="toggleSportCount(this,'soLuongSan_Tennis')" class="sport-checkbox w-4 h-4 rounded border-zinc-300 text-blue-600">
                <span class="font-medium">Tennis</span>
              </label>
              <div class="flex items-center gap-2">
                <span class="text-xs text-zinc-500">Số sân:</span>
                <input type="number" id="soLuongSan_Tennis" name="soLuongSan_Tennis" value="1" min="1" disabled oninput="updateTotalCourts()"
                       class="sport-count w-16 h-8 px-2 rounded-lg border border-zinc-200 text-sm font-semibold bg-white text-center disabled:bg-zinc-100 disabled:text-zinc-400 focus:outline-none">
              </div>
            </div>
            <div class="flex items-center justify-between py-2">
              <label class="flex items-center gap-2.5 text-sm text-zinc-600 cursor-pointer hover:text-zinc-900 select-none">
                <input type="checkbox" name="loaiHinhKinhDoanh" value="Pickleball" onchange="toggleSportCount(this,'soLuongSan_Pickleball')" class="sport-checkbox w-4 h-4 rounded border-zinc-300 text-blue-600">
                <span class="font-medium">Pickleball</span>
              </label>
              <div class="flex items-center gap-2">
                <span class="text-xs text-zinc-500">Số sân:</span>
                <input type="number" id="soLuongSan_Pickleball" name="soLuongSan_Pickleball" value="1" min="1" disabled oninput="updateTotalCourts()"
                       class="sport-count w-16 h-8 px-2 rounded-lg border border-zinc-200 text-sm font-semibold bg-white text-center disabled:bg-zinc-100 disabled:text-zinc-400 focus:outline-none">
              </div>
            </div>
          </div>
        </div>

        <!-- Giờ mở / đóng cửa -->
        <div class="grid grid-cols-2 gap-4">
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-semibold text-zinc-700">Giờ mở cửa <span class="text-red-500">*</span></label>
            <input type="time" name="gioMoCua" required
                   class="h-10 px-3 rounded-xl border border-zinc-200 text-sm focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-100 transition-all font-medium">
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-semibold text-zinc-700">Giờ đóng cửa <span class="text-red-500">*</span></label>
            <input type="time" name="gioDongCua" required
                   class="h-10 px-3 rounded-xl border border-zinc-200 text-sm focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-100 transition-all font-medium">
          </div>
        </div>

        <!-- Tổng số sân -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-zinc-700">Tổng số lượng sân dự kiến</label>
          <input type="number" id="soLuongSanDuKienDisplay" readonly value="0"
                 class="w-full h-10 px-4 rounded-xl border border-zinc-200 text-sm font-bold text-zinc-500 bg-zinc-100 focus:outline-none select-none">
          <input type="hidden" name="soLuongSanDuKien" id="soLuongSanDuKien" value="0">
          <p class="text-[10px] text-zinc-400 italic">* Tự động tính từ số sân của các môn đã chọn.</p>
        </div>

        <!-- Buttons bước 3 -->
        <div class="flex justify-between gap-3 pt-3 border-t border-zinc-50">
          <button type="button" onclick="adminGoStep(1)"
                  class="h-10 px-4 rounded-xl border border-zinc-200 text-sm font-semibold text-zinc-500 hover:bg-zinc-50 transition-all flex items-center gap-1">
            <i class="ti ti-arrow-left text-sm"></i> Quay lại
          </button>
          <div class="flex gap-3">
            <button type="button" onclick="closeModalThem()" class="h-10 px-5 rounded-xl border border-zinc-200 text-sm font-bold text-zinc-600 hover:bg-zinc-50 transition-all">Hủy</button>
            <button type="submit" onclick="return finalValidate()"
                    class="h-10 px-7 rounded-xl bg-zinc-900 text-white text-sm font-bold hover:bg-zinc-800 transition-all shadow-lg shadow-zinc-900/10 flex items-center gap-2">
              <i class="ti ti-device-floppy text-sm"></i> Lưu Cơ Sở
            </button>
          </div>
        </div>
      </form>
    </div>

  </div>
</div>

<script>
  // ── Mobile menu ──
  document.getElementById('mobileMenuBtn').addEventListener('click', () => {
    document.getElementById('sidebar').classList.toggle('-translate-x-full');
  });

  // ── Delete confirmation ──
  function confirmDelete(id, name) {
    document.getElementById('deleteMsg').textContent = 'Bạn chắc chắn muốn chuyển cơ sở "' + name + '" vào thùng rác? Bạn có thể thu hồi lại trong trang Thùng rác.';
    document.getElementById('deleteBtn').href = '${pageContext.request.contextPath}/admin/chi-nhanh/xoa?id=' + id;
    document.getElementById('modalDelete').classList.remove('hidden');
  }
  function closeDelete() { document.getElementById('modalDelete').classList.add('hidden'); }

  // ── Scroll reveal ──
  (function() {
    var io = new IntersectionObserver(function(entries) {
      entries.forEach(function(e) { if (e.isIntersecting) { e.target.classList.add('visible'); io.unobserve(e.target); }});
    }, { threshold: 0.06 });
    document.querySelectorAll('.reveal').forEach(function(el) { io.observe(el); });
  })();

  // ═══════════ ADD MODAL STATE ═══════════
  let admOtpFails = 0, admResendCount = 0, admResendTimer = null;

  function adminGoStep(n) {
    document.getElementById('aStep1').classList.toggle('hidden', n !== 1);
    document.getElementById('aStep2').classList.toggle('hidden', n !== 2);
    document.getElementById('aStep3').classList.toggle('hidden', n !== 3);
    const dots = ['sDot1','sDot2','sDot3'];
    dots.forEach((id, i) => {
      const el = document.getElementById(id);
      el.className = 'w-6 h-1.5 rounded-full transition-all ' +
        (i < n - 1 ? 'bg-green-500' : i === n - 1 ? 'bg-blue-600' : 'bg-zinc-200');
    });
    document.getElementById('sLabel').textContent = 'Bước ' + n + ' / 3';
    if (n === 2) setTimeout(() => document.querySelector('.adm-otp[data-index="0"]').focus(), 100);
  }

  function closeModalThem() {
    document.getElementById('modalThem').classList.add('hidden');
    adminGoStep(1);
    document.getElementById('formThemCoSo').reset();
    ['adminTenCoSo','adminEmail','adminPhone','adminDiaChi','adminViDo','adminKinhDo'].forEach(id => document.getElementById(id).value = '');
    setGeoStatus('adminGeoStatus', 'none');
    updateTotalCourts();
    admOtpFails = 0; admResendCount = 0;
    clearInterval(admResendTimer);
    document.getElementById('adminAddError').classList.add('hidden');
    document.getElementById('adminOtpErr').classList.add('hidden');
    document.querySelectorAll('.adm-otp').forEach(b => b.value = '');
    document.querySelectorAll('.sport-checkbox').forEach(c => {
      c.checked = false;
      const id = c.getAttribute('onchange').match(/'([^']+)'/)[1];
      const inp = document.getElementById(id);
      if (inp) { inp.setAttribute('disabled','true'); inp.value = 1; }
    });
  }

  function showAdminError(msg) {
    const el = document.getElementById('adminAddError');
    el.textContent = msg;
    el.classList.remove('hidden');
  }

  function adminSendOtp() {
    document.getElementById('adminAddError').classList.add('hidden');
    const name  = document.getElementById('adminTenCoSo').value.trim();
    const email = document.getElementById('adminEmail').value.trim();
    const phone = document.getElementById('adminPhone').value.trim();
    const addr  = document.getElementById('adminDiaChi').value.trim();

    if (!name)  return showAdminError('Vui lòng nhập tên cơ sở.');
    if (!email) return showAdminError('Vui lòng nhập email liên hệ.');
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return showAdminError('Email không hợp lệ.');
    if (!phone) return showAdminError('Vui lòng nhập số điện thoại.');
    if (!/^(0|\+84)[35789][0-9]{8}$/.test(phone)) return showAdminError('Số điện thoại không hợp lệ.');
    if (!addr)  return showAdminError('Vui lòng nhập địa chỉ.');

    const btn = document.getElementById('btnSendOtp');
    btn.disabled = true;
    btn.innerHTML = '<span class="animate-spin inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full mr-1"></span> Đang gửi OTP...';

    fetch('${pageContext.request.contextPath}/owner/send-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'email=' + encodeURIComponent(email) + '&phone=' + encodeURIComponent(phone)
    })
    .then(r => r.json())
    .then(data => {
      btn.disabled = false;
      btn.innerHTML = '<i class="ti ti-send text-sm"></i> Tiếp tục — Xác thực Email';
      if (data.success) {
        admOtpFails = 0; admResendCount = 0;
        document.getElementById('adminOtpFails').textContent = '0';
        document.getElementById('adminOtpEmailDisplay').textContent = email;
        document.getElementById('adminOtpErr').classList.add('hidden');
        document.querySelectorAll('.adm-otp').forEach(b => b.value = '');
        adminGoStep(2);
        admStartCountdown();
      } else {
        showAdminError(data.message || 'Không thể gửi OTP. Thử lại.');
      }
    })
    .catch(() => {
      btn.disabled = false;
      btn.innerHTML = '<i class="ti ti-send text-sm"></i> Tiếp tục — Xác thực Email';
      showAdminError('Lỗi kết nối. Vui lòng thử lại.');
    });
  }

  // OTP Inputs
  document.querySelectorAll('.adm-otp').forEach(box => {
    box.addEventListener('input', e => {
      const v = e.target.value.replace(/\D/g, '');
      e.target.value = v ? v[0] : '';
      if (v && +e.target.dataset.index < 5)
        document.querySelector('.adm-otp[data-index="' + (+e.target.dataset.index + 1) + '"]').focus();
    });
    box.addEventListener('keydown', e => {
      if (e.key === 'Backspace' && !e.target.value) {
        const p = document.querySelector('.adm-otp[data-index="' + (+e.target.dataset.index - 1) + '"]');
        if (p) { p.focus(); p.value = ''; }
      }
      if (e.key === 'Enter') adminVerifyOtp();
    });
    box.addEventListener('paste', e => {
      e.preventDefault();
      const d = (e.clipboardData||window.clipboardData).getData('text').replace(/\D/g,'').split('');
      document.querySelectorAll('.adm-otp').forEach((b,i) => b.value = d[i]||'');
      document.querySelector('.adm-otp[data-index="' + Math.min(d.length-1,5) + '"]').focus();
    });
  });

  function adminVerifyOtp() {
    const err = document.getElementById('adminOtpErr');
    err.classList.add('hidden');
    let otp = '';
    document.querySelectorAll('.adm-otp').forEach(b => otp += b.value);
    if (otp.length < 6) { err.textContent = 'Vui lòng nhập đủ 6 chữ số.'; err.classList.remove('hidden'); return; }

    const email = document.getElementById('adminEmail').value.trim();
    const btn = document.getElementById('btnVerifyOtp');
    btn.disabled = true;
    btn.innerHTML = '<span class="animate-spin inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full mr-1"></span> Đang xác thực...';

    fetch('${pageContext.request.contextPath}/owner/verify-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'email=' + encodeURIComponent(email) + '&otp=' + encodeURIComponent(otp)
    })
    .then(r => r.json())
    .then(data => {
      btn.disabled = false;
      btn.innerHTML = '<i class="ti ti-shield-check text-sm"></i> Xác thực OTP';
      if (data.success) {
        clearInterval(admResendTimer);
        document.getElementById('hTenCoSo').value = document.getElementById('adminTenCoSo').value.trim();
        document.getElementById('hEmail').value   = document.getElementById('adminEmail').value.trim();
        document.getElementById('hPhone').value   = document.getElementById('adminPhone').value.trim();
        document.getElementById('hDiaChi').value  = document.getElementById('adminDiaChi').value.trim();
        document.getElementById('hViDo').value    = document.getElementById('adminViDo').value;
        document.getElementById('hKinhDo').value  = document.getElementById('adminKinhDo').value;
        adminGoStep(3);
      } else {
        admOtpFails++;
        document.getElementById('adminOtpFails').textContent = admOtpFails;
        document.querySelectorAll('.adm-otp').forEach(b => b.value = '');
        document.querySelector('.adm-otp[data-index="0"]').focus();
        if (admOtpFails >= 5) {
          err.textContent = 'Sai OTP quá 5 lần. Vui lòng thử lại từ đầu.';
          err.classList.remove('hidden');
          setTimeout(() => adminGoStep(1), 2000);
          admOtpFails = 0;
        } else {
          err.textContent = 'Mã OTP không đúng. Còn ' + (5 - admOtpFails) + ' lần thử.';
          err.classList.remove('hidden');
        }
      }
    })
    .catch(() => {
      btn.disabled = false;
      btn.innerHTML = '<i class="ti ti-shield-check text-sm"></i> Xác thực OTP';
      err.textContent = 'Lỗi kết nối. Vui lòng thử lại.';
      err.classList.remove('hidden');
    });
  }

  function admStartCountdown() {
    let s = 60;
    const btn = document.getElementById('btnResend');
    const cd  = document.getElementById('admResendCd');
    btn.disabled = true;
    clearInterval(admResendTimer);
    admResendTimer = setInterval(() => {
      s--; cd.textContent = s;
      if (s <= 0) { clearInterval(admResendTimer); btn.disabled = false; }
    }, 1000);
  }

  function adminResendOtp() {
    if (++admResendCount >= 3) {
      document.getElementById('adminOtpErr').textContent = 'Đã gửi lại quá 3 lần. Vui lòng thử lại từ đầu.';
      document.getElementById('adminOtpErr').classList.remove('hidden');
      setTimeout(() => adminGoStep(1), 2000);
      return;
    }
    const email = document.getElementById('adminEmail').value.trim();
    const phone = document.getElementById('adminPhone').value.trim();
    fetch('${pageContext.request.contextPath}/owner/send-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'email=' + encodeURIComponent(email) + '&phone=' + encodeURIComponent(phone)
    }).then(r => r.json()).then(data => {
      if (data.success) {
        document.querySelectorAll('.adm-otp').forEach(b => b.value = '');
        admOtpFails = 0;
        document.getElementById('adminOtpFails').textContent = '0';
        document.querySelector('.adm-otp[data-index="0"]').focus();
        admStartCountdown();
      }
    });
  }

  function finalValidate() {
    updateTotalCourts();
    const total = parseInt(document.getElementById('soLuongSanDuKien').value) || 0;
    if (total <= 0) {
      alert('Vui lòng chọn ít nhất một môn thể thao và nhập số sân lớn hơn 0.');
      return false;
    }
    const viDo = document.getElementById('hViDo').value;
    const kinhDo = document.getElementById('hKinhDo').value;
    if (!viDo || !kinhDo) {
      alert('Vị trí cơ sở chưa hợp lệ. Vui lòng chọn lại vị trí trên bản đồ hoặc nhập đầy đủ tọa độ.');
      return false;
    }
    return true;
  }

  function toggleSportCount(checkbox, inputId) {
    const input = document.getElementById(inputId);
    if (checkbox.checked) {
      input.removeAttribute('disabled');
      if (!parseInt(input.value)) input.value = 1;
    } else {
      input.setAttribute('disabled', 'true');
      input.value = 0;
    }
    updateTotalCourts();
  }

  function updateTotalCourts() {
    let total = 0;
    document.querySelectorAll('.sport-count').forEach(i => {
      if (!i.hasAttribute('disabled')) total += parseInt(i.value) || 0;
    });
    const d = document.getElementById('soLuongSanDuKienDisplay');
    const h = document.getElementById('soLuongSanDuKien');
    if (d) d.value = total;
    if (h) h.value = total;
  }

  // ==========================================
  // GEOLOCATION LOOKUP SCRIPTS
  // ==========================================
  let activeGeoTargetId = 'adminDiaChi';

  // Mỗi form (Thêm/Sửa) có bộ 3 field riêng: input địa chỉ hiển thị, hidden viDo/kinhDo,
  // và dòng trạng thái. Tra theo id input địa chỉ đang active để biết ghi vào đâu.
  const GEO_FIELD_MAP = {
    adminDiaChi: { viDo: 'adminViDo', kinhDo: 'adminKinhDo', status: 'adminGeoStatus' }
  };

  function autoFillAddress(targetId) {
    activeGeoTargetId = targetId || 'adminDiaChi';
    document.getElementById('geoInput').value = "";
    document.getElementById('geoModal').classList.remove('hidden');
    document.getElementById('geoInput').focus();
  }

  function closeGeoModal() {
    document.getElementById('geoModal').classList.add('hidden');
  }

  // Parse tọa độ từ nhiều định dạng: decimal "lat, lon", DMS "10°23'07.3\"N 107°07'20.4\"E",
  // hoặc Google Maps URL chứa "@lat,lon" hay "q=lat,lon". Trả về {lat, lon} hoặc null.
  function parseCoordInput(raw) {
    const input = raw.trim();

    let m = input.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/)
        || input.match(/[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)/)
        || input.match(/!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)/);
    if (m) return { lat: parseFloat(m[1]), lon: parseFloat(m[2]) };

    const dms = /(\d+)[°\s](\d+)['’′]\s*([\d.]+)[\"”″]?\s*([NSns])[,\s]+(\d+)[°\s](\d+)['’′]\s*([\d.]+)[\"”″]?\s*([EWew])/;
    m = input.match(dms);
    if (m) {
      const toDec = (deg, min, sec, dir) => {
        let v = parseInt(deg, 10) + parseInt(min, 10) / 60 + parseFloat(sec) / 3600;
        if (/[SsWw]/.test(dir)) v = -v;
        return v;
      };
      return { lat: toDec(m[1], m[2], m[3], m[4]), lon: toDec(m[5], m[6], m[7], m[8]) };
    }

    m = input.match(/(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)/);
    if (m) return { lat: parseFloat(m[1]), lon: parseFloat(m[2]) };

    return null;
  }

  function isValidLatLon(lat, lon) {
    return Number.isFinite(lat) && Number.isFinite(lon) && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }

  function submitGeoInput() {
    const input = document.getElementById('geoInput').value.trim();
    if (!input) {
      alert("Vui lòng dán tọa độ hoặc link Google Map.");
      return;
    }
    const coord = parseCoordInput(input);
    if (coord && isValidLatLon(coord.lat, coord.lon)) {
      closeGeoModal();
      fetchAddressFromCoords(coord.lat, coord.lon);
    } else {
      alert("Không tìm thấy tọa độ hợp lệ. Ví dụ: 10.7626, 106.6601 hoặc link Google Maps.");
    }
  }

  function useCurrentGps() {
    if (!navigator.geolocation) {
      alert("Trình duyệt không hỗ trợ định vị GPS tự động.");
      return;
    }
    const btn = document.getElementById('btnUseGps');
    const originalText = btn.innerHTML;
    btn.disabled = true;
    btn.innerHTML = '<span class="animate-spin inline-block w-4 h-4 border-2 border-zinc-700 border-t-transparent rounded-full mr-2"></span> Đang định vị GPS...';

    navigator.geolocation.getCurrentPosition(
      function(pos) {
        btn.disabled = false;
        btn.innerHTML = originalText;
        closeGeoModal();
        fetchAddressFromCoords(pos.coords.latitude, pos.coords.longitude);
      },
      function(err) {
        btn.disabled = false;
        btn.innerHTML = originalText;
        let errorMsg = "Lỗi lấy vị trí.";
        if (err.code === err.PERMISSION_DENIED) {
          errorMsg = "Quyền định vị bị từ chối. Vui lòng cấp quyền hoặc nhập tọa độ thủ công.";
        } else if (err.code === err.POSITION_UNAVAILABLE) {
          errorMsg = "Không tìm thấy GPS. Vui lòng dán tọa độ Google Map.";
        } else if (err.code === err.TIMEOUT) {
          errorMsg = "Hết thời gian định vị GPS.";
        }
        alert(errorMsg);
      },
      { enableHighAccuracy: true, timeout: 8000 }
    );
  }

  // Debounce guard: tránh spam Nominatim nếu người dùng bấm định vị liên tục.
  let geoFetchInFlight = false;

  function setGeoStatus(statusId, state, lat, lon) {
    const status = document.getElementById(statusId);
    if (!status) return;
    if (state === 'ok') {
      status.className = 'text-[11px] font-semibold mt-0.5 text-emerald-600';
      status.innerHTML = '<i class="ti ti-map-pin-check text-sm align-[-2px]"></i> Đã xác định vị trí (' + lat.toFixed(7) + ', ' + lon.toFixed(7) + ')';
    } else if (state === 'partial') {
      status.className = 'text-[11px] font-semibold mt-0.5 text-amber-600';
      status.innerHTML = '<i class="ti ti-map-pin-check text-sm align-[-2px]"></i> Đã lưu tọa độ (' + lat.toFixed(7) + ', ' + lon.toFixed(7) + ') — chưa lấy được địa chỉ chữ, vui lòng nhập tay.';
    } else {
      status.className = 'text-[11px] font-semibold mt-0.5 text-amber-600';
      status.innerHTML = '<i class="ti ti-map-pin-off text-sm align-[-2px]"></i> Chưa xác định tọa độ — nhấn "Định vị địa chỉ / Tọa độ GG Map"';
    }
  }

  function fetchAddressFromCoords(lat, lon) {
    if (!isValidLatLon(lat, lon)) {
      alert("Tọa độ không hợp lệ (vĩ độ -90..90, kinh độ -180..180).");
      return;
    }
    if (geoFetchInFlight) return;
    geoFetchInFlight = true;

    const fields = GEO_FIELD_MAP[activeGeoTargetId] || GEO_FIELD_MAP.adminDiaChi;
    const addrInput = document.getElementById(activeGeoTargetId);

    // Lưu tọa độ ngay — dù reverse geocode thất bại vẫn không mất vị trí đã xác định.
    const viDoEl = document.getElementById(fields.viDo);
    const kinhDoEl = document.getElementById(fields.kinhDo);
    if (viDoEl) viDoEl.value = lat;
    if (kinhDoEl) kinhDoEl.value = lon;
    setGeoStatus(fields.status, 'partial', lat, lon);

    const originalPlaceholder = addrInput.placeholder || "";
    addrInput.disabled = true;
    addrInput.value = "";
    addrInput.placeholder = "Đang lấy địa chỉ từ tọa độ [" + parseFloat(lat).toFixed(4) + ", " + parseFloat(lon).toFixed(4) + "]...";

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 8000);

    fetch('https://nominatim.openstreetmap.org/reverse?format=json&lat=' + lat + '&lon=' + lon + '&accept-language=vi',
          { signal: controller.signal })
      .then(r => r.json())
      .then(data => {
        clearTimeout(timeoutId);
        addrInput.disabled = false;
        addrInput.placeholder = originalPlaceholder;
        if (data && data.display_name) {
          addrInput.value = data.display_name;
          setGeoStatus(fields.status, 'ok', lat, lon);
        } else {
          setGeoStatus(fields.status, 'partial', lat, lon);
          alert("Không thể chuyển đổi tọa độ này thành địa chỉ. Tọa độ vẫn được lưu — vui lòng nhập địa chỉ thủ công.");
        }
      })
      .catch(err => {
        clearTimeout(timeoutId);
        addrInput.disabled = false;
        addrInput.placeholder = originalPlaceholder;
        setGeoStatus(fields.status, 'partial', lat, lon);
        const msg = (err && err.name === 'AbortError')
          ? "Hết thời gian chờ dịch vụ địa chỉ. Tọa độ vẫn được lưu — vui lòng nhập địa chỉ thủ công."
          : "Lỗi kết nối dịch vụ địa chỉ. Tọa độ vẫn được lưu — vui lòng nhập địa chỉ thủ công.";
        alert(msg);
      })
      .finally(() => { geoFetchInFlight = false; });
  }

  // ==========================================
  // EDIT: đã khóa — Admin không còn quyền chỉnh sửa cơ sở (chỉ Duyệt/Từ chối/Xóa).
  // ==========================================

  // ═══════════ PAYOS CONFIG MODAL ═══════════
  let payosCurrentCoSoId = null;
  let payosSaving = false;

  function openPayOSModal(coSoId, coSoName) {
    payosCurrentCoSoId = coSoId;
    document.getElementById('payosModalSubtitle').textContent = coSoName + ' · Cơ sở #' + coSoId;
    document.getElementById('payosForm').classList.add('hidden');
    document.getElementById('payosLoading').classList.remove('hidden');
    document.getElementById('payosFormError').classList.add('hidden');
    ['payosClientId', 'payosApiKey', 'payosChecksumKey'].forEach(id => {
      const el = document.getElementById(id);
      el.value = '';
      el.type = 'password';
    });
    document.getElementById('modalPayOS').classList.remove('hidden');

    fetch('${pageContext.request.contextPath}/admin/chi-nhanh/payos?coSoId=' + coSoId)
      .then(r => r.json())
      .then(data => {
        document.getElementById('payosLoading').classList.add('hidden');
        document.getElementById('payosForm').classList.remove('hidden');
        if (!data.success) {
          showPayOSFormError(data.message || 'Không thể tải cấu hình PayOS.');
          return;
        }
        const cfg = data.configuration;
        setPayOSFieldHint('payosClientIdHint', cfg.clientIdConfigured, cfg.clientIdMasked);
        setPayOSFieldHint('payosApiKeyHint', cfg.apiKeyConfigured, cfg.apiKeyMasked);
        setPayOSFieldHint('payosChecksumKeyHint', cfg.checksumKeyConfigured, cfg.checksumKeyMasked);
        document.getElementById('payosClientId').placeholder = cfg.clientIdConfigured ? 'Đã cấu hình — để trống nếu không thay đổi' : 'Nhập Client ID';
        document.getElementById('payosApiKey').placeholder = cfg.apiKeyConfigured ? 'Đã cấu hình — để trống nếu không thay đổi' : 'Nhập API Key';
        document.getElementById('payosChecksumKey').placeholder = cfg.checksumKeyConfigured ? 'Đã cấu hình — để trống nếu không thay đổi' : 'Nhập Checksum Key';
      })
      .catch(() => {
        document.getElementById('payosLoading').classList.add('hidden');
        document.getElementById('payosForm').classList.remove('hidden');
        showPayOSFormError('Lỗi kết nối. Vui lòng thử lại.');
      });
  }

  function setPayOSFieldHint(hintId, configured, masked) {
    document.getElementById(hintId).textContent = configured ? ('Hiện tại: ' + masked) : 'Chưa cấu hình';
  }

  function togglePayOSVisibility(inputId) {
    const el = document.getElementById(inputId);
    el.type = el.type === 'password' ? 'text' : 'password';
  }

  function showPayOSFormError(msg) {
    const el = document.getElementById('payosFormError');
    el.textContent = msg;
    el.classList.remove('hidden');
  }

  function closePayOSModal() {
    if (payosSaving) return;
    document.getElementById('modalPayOS').classList.add('hidden');
    document.getElementById('modalPayOSOtp').classList.add('hidden');
    clearInterval(payosResendTimer);
    payosCurrentCoSoId = null;
  }

  function setPayOSFormDisabled(disabled) {
    document.getElementById('payosCancelBtn').disabled = disabled;
    document.getElementById('payosCloseBtn').disabled = disabled;
    document.querySelectorAll('.payos-input').forEach(i => i.disabled = disabled);
  }

  function submitPayOSConfig(event) {
    event.preventDefault();
    if (payosSaving) return false;
    payosSaving = true;

    document.getElementById('payosFormError').classList.add('hidden');
    const btn = document.getElementById('payosSaveBtn');
    const originalHtml = btn.innerHTML;
    btn.disabled = true;
    btn.innerHTML = '<span class="animate-spin inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full"></span> Đang lưu...';
    setPayOSFormDisabled(true);

    const body = new URLSearchParams();
    body.set('coSoId', payosCurrentCoSoId);
    body.set('clientId', document.getElementById('payosClientId').value);
    body.set('apiKey', document.getElementById('payosApiKey').value);
    body.set('checksumKey', document.getElementById('payosChecksumKey').value);

    fetch('${pageContext.request.contextPath}/admin/chi-nhanh/payos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: body.toString()
    })
      .then(r => r.json())
      .then(data => {
        payosSaving = false;
        btn.disabled = false;
        btn.innerHTML = originalHtml;
        setPayOSFormDisabled(false);

        if (!data.success) {
          showPayOSFormError(data.message || 'Không thể lưu cấu hình PayOS.');
          return;
        }
        if (data.requiresOtp) {
          openPayOSOtpModal(data.maskedEmail, data.resendWaitSeconds);
          return;
        }
        updatePayOSBadge(payosCurrentCoSoId, data.configuration.status);
        showPayOSToast(data.message || 'Đã cập nhật cấu hình PayOS.');
        closePayOSModal();
      })
      .catch(() => {
        payosSaving = false;
        btn.disabled = false;
        btn.innerHTML = originalHtml;
        setPayOSFormDisabled(false);
        showPayOSFormError('Lỗi kết nối. Vui lòng thử lại.');
      });

    return false;
  }

  // ═══════════ PAYOS OTP MODAL ═══════════
  let payosOtpFails = 0, payosResendTimer = null;

  function openPayOSOtpModal(maskedEmail, resendWaitSeconds) {
    document.getElementById('payosOtpEmailDisplay').textContent = maskedEmail || '';
    document.getElementById('payosOtpErr').classList.add('hidden');
    payosOtpFails = 0;
    document.getElementById('payosOtpFails').textContent = '0';
    document.querySelectorAll('.payos-otp').forEach(b => b.value = '');
    document.getElementById('modalPayOSOtp').classList.remove('hidden');
    setTimeout(() => document.querySelector('.payos-otp[data-index="0"]').focus(), 100);
    payosStartResendCountdown(resendWaitSeconds || 60);
  }

  function closePayOSOtpModal() {
    document.getElementById('modalPayOSOtp').classList.add('hidden');
    clearInterval(payosResendTimer);
  }

  document.querySelectorAll('.payos-otp').forEach(box => {
    box.addEventListener('input', e => {
      const v = e.target.value.replace(/\D/g, '');
      e.target.value = v ? v[0] : '';
      if (v && +e.target.dataset.index < 5)
        document.querySelector('.payos-otp[data-index="' + (+e.target.dataset.index + 1) + '"]').focus();
    });
    box.addEventListener('keydown', e => {
      if (e.key === 'Backspace' && !e.target.value) {
        const p = document.querySelector('.payos-otp[data-index="' + (+e.target.dataset.index - 1) + '"]');
        if (p) { p.focus(); p.value = ''; }
      }
      if (e.key === 'Enter') submitPayOSOtp();
    });
    box.addEventListener('paste', e => {
      e.preventDefault();
      const d = (e.clipboardData||window.clipboardData).getData('text').replace(/\D/g,'').split('');
      document.querySelectorAll('.payos-otp').forEach((b,i) => b.value = d[i]||'');
      document.querySelector('.payos-otp[data-index="' + Math.min(d.length-1,5) + '"]').focus();
    });
  });

  function submitPayOSOtp() {
    const err = document.getElementById('payosOtpErr');
    err.classList.add('hidden');
    let otp = '';
    document.querySelectorAll('.payos-otp').forEach(b => otp += b.value);
    if (otp.length < 6) { err.textContent = 'Vui lòng nhập đủ 6 chữ số.'; err.classList.remove('hidden'); return; }

    const btn = document.getElementById('btnPayOSOtpVerify');
    btn.disabled = true;
    btn.innerHTML = '<span class="animate-spin inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full mr-1"></span> Đang xác thực...';

    const body = new URLSearchParams();
    body.set('action', 'verify-otp');
    body.set('coSoId', payosCurrentCoSoId);
    body.set('otp', otp);

    fetch('${pageContext.request.contextPath}/admin/chi-nhanh/payos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: body.toString()
    })
      .then(r => r.json())
      .then(data => {
        btn.disabled = false;
        btn.innerHTML = '<i class="ti ti-shield-check text-sm"></i> Xác thực OTP';
        if (data.success) {
          clearInterval(payosResendTimer);
          updatePayOSBadge(payosCurrentCoSoId, data.configuration.status);
          showPayOSToast(data.message || 'Đã cập nhật cấu hình PayOS.');
          document.getElementById('modalPayOSOtp').classList.add('hidden');
          closePayOSModal();
        } else {
          payosOtpFails++;
          document.getElementById('payosOtpFails').textContent = Math.min(payosOtpFails, 5);
          document.querySelectorAll('.payos-otp').forEach(b => b.value = '');
          document.querySelector('.payos-otp[data-index="0"]').focus();
          err.textContent = data.message || 'Mã OTP không đúng.';
          err.classList.remove('hidden');
          if (payosOtpFails >= 5) {
            setTimeout(() => { document.getElementById('modalPayOSOtp').classList.add('hidden'); }, 2000);
          }
        }
      })
      .catch(() => {
        btn.disabled = false;
        btn.innerHTML = '<i class="ti ti-shield-check text-sm"></i> Xác thực OTP';
        err.textContent = 'Lỗi kết nối. Vui lòng thử lại.';
        err.classList.remove('hidden');
      });
  }

  function payosStartResendCountdown(seconds) {
    let s = Math.max(seconds, 0);
    const btn = document.getElementById('btnPayOSResend');
    const cd = document.getElementById('payosResendCd');
    cd.textContent = s;
    btn.disabled = s > 0;
    clearInterval(payosResendTimer);
    payosResendTimer = setInterval(() => {
      s--; cd.textContent = s;
      if (s <= 0) { clearInterval(payosResendTimer); btn.disabled = false; }
    }, 1000);
  }

  function resendPayOSOtp() {
    const body = new URLSearchParams();
    body.set('action', 'resend-otp');
    body.set('coSoId', payosCurrentCoSoId);

    fetch('${pageContext.request.contextPath}/admin/chi-nhanh/payos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: body.toString()
    })
      .then(r => r.json())
      .then(data => {
        const err = document.getElementById('payosOtpErr');
        if (data.success) {
          document.querySelectorAll('.payos-otp').forEach(b => b.value = '');
          payosOtpFails = 0;
          document.getElementById('payosOtpFails').textContent = '0';
          err.classList.add('hidden');
          document.querySelector('.payos-otp[data-index="0"]').focus();
        } else {
          err.textContent = data.message || 'Không thể gửi lại mã.';
          err.classList.remove('hidden');
        }
        payosStartResendCountdown(data.resendWaitSeconds || 60);
      });
  }

  function updatePayOSBadge(coSoId, status) {
    const badge = document.getElementById('payosBadge' + coSoId);
    if (!badge) return;
    const cls = status === 'CONFIGURED' ? 'badge-green' : status === 'PARTIAL' ? 'badge-amber' : 'badge-gray';
    const label = status === 'CONFIGURED' ? 'Đã cấu hình' : status === 'PARTIAL' ? 'Thiếu thông tin' : 'Chưa cấu hình';
    badge.className = 'badge ' + cls;
    badge.textContent = label;
  }

  let payosToastTimer = null;
  function showPayOSToast(msg) {
    const toast = document.getElementById('payosToast');
    document.getElementById('payosToastMsg').textContent = msg;
    toast.classList.remove('hidden');
    clearTimeout(payosToastTimer);
    payosToastTimer = setTimeout(() => toast.classList.add('hidden'), 3000);
  }
</script>

<!-- ═══ Modal Cấu hình PayOS ═══ -->
<div id="modalPayOS" class="hidden fixed inset-0 z-[95] flex items-center justify-center p-4">
  <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" onclick="closePayOSModal()"></div>
  <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-[480px] flex flex-col">

    <div class="flex items-center justify-between px-6 py-4 border-b border-zinc-100 shrink-0">
      <div>
        <h3 class="text-base font-bold text-zinc-900">Cấu hình PayOS</h3>
        <p class="text-xs text-zinc-500 mt-0.5" id="payosModalSubtitle"></p>
      </div>
      <button type="button" id="payosCloseBtn" onclick="closePayOSModal()" class="p-1.5 rounded-lg hover:bg-zinc-100 text-zinc-400">
        <i class="ti ti-x text-lg"></i>
      </button>
    </div>

    <!-- LOADING state -->
    <div id="payosLoading" class="p-6 flex flex-col gap-3">
      <div class="h-10 rounded-xl bg-zinc-100 animate-pulse"></div>
      <div class="h-10 rounded-xl bg-zinc-100 animate-pulse"></div>
      <div class="h-10 rounded-xl bg-zinc-100 animate-pulse"></div>
    </div>

    <!-- EDITING / SAVING / ERROR states -->
    <form id="payosForm" class="hidden p-6 flex flex-col gap-4" onsubmit="return submitPayOSConfig(event)">
      <div id="payosFormError" class="hidden px-4 py-3 bg-red-50 border border-red-200 rounded-xl text-sm text-red-600 font-medium"></div>

      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-semibold text-zinc-700">Client ID</label>
        <div class="relative">
          <input type="password" id="payosClientId" autocomplete="new-password"
                 class="payos-input h-10 w-full pl-3 pr-10 rounded-xl border border-zinc-200 text-sm focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-100 transition-all font-medium">
          <button type="button" onclick="togglePayOSVisibility('payosClientId')" class="absolute right-2.5 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-zinc-600">
            <i class="ti ti-eye text-base"></i>
          </button>
        </div>
        <p class="text-[11px] text-zinc-400" id="payosClientIdHint"></p>
      </div>

      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-semibold text-zinc-700">API Key</label>
        <div class="relative">
          <input type="password" id="payosApiKey" autocomplete="new-password"
                 class="payos-input h-10 w-full pl-3 pr-10 rounded-xl border border-zinc-200 text-sm focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-100 transition-all font-medium">
          <button type="button" onclick="togglePayOSVisibility('payosApiKey')" class="absolute right-2.5 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-zinc-600">
            <i class="ti ti-eye text-base"></i>
          </button>
        </div>
        <p class="text-[11px] text-zinc-400" id="payosApiKeyHint"></p>
      </div>

      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-semibold text-zinc-700">Checksum Key</label>
        <div class="relative">
          <input type="password" id="payosChecksumKey" autocomplete="new-password"
                 class="payos-input h-10 w-full pl-3 pr-10 rounded-xl border border-zinc-200 text-sm focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-100 transition-all font-medium">
          <button type="button" onclick="togglePayOSVisibility('payosChecksumKey')" class="absolute right-2.5 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-zinc-600">
            <i class="ti ti-eye text-base"></i>
          </button>
        </div>
        <p class="text-[11px] text-zinc-400" id="payosChecksumKeyHint"></p>
      </div>

      <div class="flex justify-end gap-3 pt-2 border-t border-zinc-50">
        <button type="button" onclick="closePayOSModal()" id="payosCancelBtn" class="h-10 px-5 rounded-xl border border-zinc-200 text-sm font-bold text-zinc-600 hover:bg-zinc-50 transition-all">Hủy</button>
        <button type="submit" id="payosSaveBtn" class="h-10 px-6 rounded-xl bg-zinc-900 text-white text-sm font-bold hover:bg-zinc-800 transition-all shadow-lg shadow-zinc-900/10 flex items-center gap-2">
          <i class="ti ti-device-floppy text-sm"></i>Lưu cấu hình
        </button>
      </div>
    </form>

  </div>
</div>

<!-- ═══ Modal Xác thực OTP — Cấu hình PayOS ═══ -->
<div id="modalPayOSOtp" class="hidden fixed inset-0 z-[96] flex items-center justify-center p-4">
  <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" onclick="closePayOSOtpModal()"></div>
  <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-[420px] p-6 flex flex-col gap-5">
    <div class="text-center">
      <div class="w-14 h-14 rounded-2xl bg-blue-50 flex items-center justify-center mx-auto mb-3">
        <i class="ti ti-mail-check text-blue-600 text-3xl"></i>
      </div>
      <h4 class="text-base font-bold text-zinc-900 mb-1">Xác thực thay đổi PayOS</h4>
      <p class="text-sm text-zinc-500">Mã OTP 6 chữ số đã được gửi đến</p>
      <p class="text-sm font-semibold text-blue-600 mt-0.5" id="payosOtpEmailDisplay"></p>
    </div>

    <div class="flex justify-center gap-2">
      <input type="text" maxlength="1" class="payos-otp adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="0"/>
      <input type="text" maxlength="1" class="payos-otp adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="1"/>
      <input type="text" maxlength="1" class="payos-otp adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="2"/>
      <input type="text" maxlength="1" class="payos-otp adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="3"/>
      <input type="text" maxlength="1" class="payos-otp adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="4"/>
      <input type="text" maxlength="1" class="payos-otp adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="5"/>
    </div>

    <div id="payosOtpErr" class="hidden text-center text-sm text-red-500 font-medium -mt-2"></div>
    <p class="text-center text-xs text-zinc-400">Số lần nhập sai: <span id="payosOtpFails" class="font-bold text-red-500">0</span>/5</p>

    <button type="button" onclick="submitPayOSOtp()" id="btnPayOSOtpVerify"
            class="w-full h-11 rounded-xl bg-zinc-900 text-white text-sm font-bold hover:bg-zinc-800 transition-all flex items-center justify-center gap-2">
      <i class="ti ti-shield-check text-sm"></i> Xác thực OTP
    </button>
    <div class="flex items-center justify-between -mt-1">
      <button type="button" onclick="closePayOSOtpModal()" class="text-zinc-400 hover:text-zinc-700 text-sm flex items-center gap-1 bg-transparent border-none cursor-pointer">
        <i class="ti ti-arrow-left text-sm"></i> Quay lại
      </button>
      <button type="button" onclick="resendPayOSOtp()" id="btnPayOSResend"
              class="text-blue-500 hover:text-blue-700 text-sm disabled:opacity-40 bg-transparent border-none cursor-pointer" disabled>
        Gửi lại mã (<span id="payosResendCd">60</span>s)
      </button>
    </div>
  </div>
</div>

<!-- Toast -->
<div id="payosToast" class="hidden fixed bottom-6 right-6 z-[110] px-4 py-3 rounded-xl bg-zinc-900 text-white text-sm font-semibold shadow-xl flex items-center gap-2">
  <i class="ti ti-circle-check text-emerald-400"></i>
  <span id="payosToastMsg"></span>
</div>

<!-- Custom Geolocation Modal -->
<div id="geoModal" class="hidden fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 geo-animate-fade">
  <div class="bg-white rounded-3xl p-6 md:p-8 w-full max-w-md shadow-2xl relative geo-animate-scale">
    <!-- Close button -->
    <button type="button" onclick="closeGeoModal()" class="absolute top-4 right-4 text-zinc-450 hover:text-zinc-800 transition-all bg-transparent border-none cursor-pointer focus:outline-none">
      <i class="ti ti-x text-xl"></i>
    </button>
    
    <div class="flex items-center gap-3 mb-4">
      <div class="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center shrink-0 border border-blue-100">
        <i class="ti ti-map-pin text-2xl"></i>
      </div>
      <h3 class="text-lg font-black text-zinc-900">Định vị vị trí Cơ Sở</h3>
    </div>
    
    <p class="text-xs text-zinc-500 mb-6 leading-relaxed">
      Dán tọa độ Google Map (vĩ độ, kinh độ, VD: <code class="text-blue-600 font-bold bg-blue-50 px-1.5 py-0.5 rounded">10.7626, 106.6601</code>) hoặc link bản đồ chứa tọa độ để tự động lấy địa chỉ.
    </p>
    
    <div class="space-y-4 mb-6">
      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-bold text-zinc-700" for="geoInput">Tọa độ hoặc Link Google Map</label>
        <input type="text" id="geoInput" placeholder="Dán tọa độ hoặc link tại đây..." class="w-full px-4 h-11 border border-zinc-200 rounded-xl bg-zinc-50 focus:outline-none focus:ring-2 focus:ring-blue-500/10 focus:border-blue-500 transition-all placeholder:text-zinc-400 text-sm font-medium" />
      </div>
    </div>
    
    <div class="flex flex-col gap-3">
      <button type="button" onclick="submitGeoInput()" class="w-full py-3 text-sm flex justify-center items-center gap-2 text-white bg-blue-600 hover:bg-blue-700 transition-all rounded-xl font-bold shadow-md shadow-blue-100 border-none cursor-pointer">
        <i class="ti ti-search text-base"></i> Xác nhận & Tìm địa chỉ
      </button>
      <button type="button" onclick="useCurrentGps()" id="btnUseGps" class="w-full py-3 text-sm flex justify-center items-center gap-2 text-zinc-700 hover:text-zinc-900 border border-zinc-200 hover:border-zinc-350 bg-zinc-50 hover:bg-zinc-100 transition-all rounded-xl font-bold cursor-pointer">
        <i class="ti ti-device-gps text-base"></i> Sử dụng vị trí GPS hiện tại
      </button>
    </div>
  </div>
</div>

<!-- ═══ Modal Từ chối yêu cầu ═══ -->
<div id="modalTuChoi" class="hidden fixed inset-0 z-[100] flex items-center justify-center p-4">
  <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" onclick="closeTuChoiModal()"></div>
  <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-[420px] p-6">
    <div class="w-12 h-12 rounded-xl bg-red-50 border border-red-100 flex items-center justify-center mb-4">
      <i class="ti ti-circle-x text-red-500 text-2xl"></i>
    </div>
    <h3 class="text-base font-bold text-zinc-900 mb-1">Từ chối yêu cầu</h3>
    <p class="text-sm text-zinc-500 mb-4">Nhập lý do từ chối để thông báo cho chủ cơ sở.</p>
    <input type="hidden" id="tuChoiCoSoId" value="">
    <div class="mb-4">
      <label class="text-xs font-semibold text-zinc-700 mb-1 block">Lý do từ chối <span class="text-red-500">*</span></label>
      <textarea id="tuChoiReason" rows="3" placeholder="Ví dụ: Thiếu giấy tờ pháp lý, thông tin không hợp lệ..."
                class="w-full px-4 py-3 border border-zinc-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-red-500/10 focus:border-red-400 resize-none"></textarea>
      <p class="text-xs text-red-500 mt-1 hidden" id="tuChoiReasonErr">Vui lòng nhập lý do từ chối.</p>
    </div>
    <div class="flex gap-3">
      <button onclick="closeTuChoiModal()" class="flex-1 h-10 rounded-xl border border-zinc-200 text-sm font-semibold text-zinc-600 hover:bg-zinc-50 transition-all">Hủy</button>
      <button onclick="submitTuChoi()" class="flex-1 h-10 rounded-xl bg-red-500 text-white text-sm font-semibold hover:bg-red-600 transition-all shadow-md shadow-red-100">
        <i class="ti ti-circle-x mr-1"></i>Xác nhận từ chối
      </button>
    </div>
  </div>
</div>

<script>
// ── Tab switching ──────────────────────────────────────────────
function switchTab(tab) {
  ['all','pending','rejected'].forEach(function(t) {
    var panel = document.getElementById('tab-' + t);
    var btn   = document.getElementById('tab-btn-' + t);
    if (!panel || !btn) return;
    panel.style.display = (t === tab) ? '' : 'none';
    if (t === tab) { btn.classList.add('active'); }
    else           { btn.classList.remove('active'); }
  });
  closeDrawer();
}

// Auto-switch if ?tab= param present
(function() {
  var params = new URLSearchParams(window.location.search);
  var tab = params.get('tab');
  if (tab === 'pending' || tab === 'rejected') {
    switchTab(tab);
  }
})();

// ── Drawer ─────────────────────────────────────────────────────
var currentDrawerCoSoId = null;

function openDrawer(coSoId, status) {
  var data = DRAWER_DATA[coSoId];
  if (!data) return;

  currentDrawerCoSoId = coSoId;

  // Mark selected card
  document.querySelectorAll('.req-card').forEach(function(c) { c.classList.remove('selected'); });
  var card = document.getElementById('req-' + status + '-' + coSoId);
  if (card) card.classList.add('selected');

  // Title
  document.getElementById('drawerTitle').textContent = data.tenCoSo;

  // Build body HTML
  var capHtml = '';
  if (data.capabilities && data.capabilities.length > 0) {
    data.capabilities.forEach(function(c) { capHtml += '<span class="cap-chip">' + escHtml(c) + '</span> '; });
  } else {
    capHtml = '<span class="text-xs text-zinc-400">Chưa đăng ký</span>';
  }

  document.getElementById('drawerBody').innerHTML = [
    '<div class="p-4 bg-zinc-50 rounded-xl border border-zinc-100">',
      '<p class="text-[10px] font-bold text-zinc-400 uppercase tracking-widest mb-3">Thông tin cơ sở</p>',
      infoRow('ti-building-stadium', 'Tên cơ sở', data.tenCoSo),
      infoRow('ti-map-pin', 'Địa chỉ', data.diaChi),
      infoRow('ti-phone', 'Điện thoại', data.sdtCoSo || '—'),
    '</div>',
    '<div class="p-4 bg-zinc-50 rounded-xl border border-zinc-100">',
      '<p class="text-[10px] font-bold text-zinc-400 uppercase tracking-widest mb-3">Thông tin quản lý</p>',
      infoRow('ti-user', 'Họ tên', data.mgrName),
      infoRow('ti-mail', 'Email', data.mgrEmail),
      infoRow('ti-phone', 'SĐT', data.mgrSdt || '—'),
    '</div>',
    '<div class="p-4 bg-zinc-50 rounded-xl border border-zinc-100">',
      '<p class="text-[10px] font-bold text-zinc-400 uppercase tracking-widest mb-2">Loại dịch vụ đăng ký</p>',
      '<div class="flex flex-wrap gap-1.5 mt-1">' + capHtml + '</div>',
    '</div>'
  ].join('');

  // Build action buttons
  var actionsEl = document.getElementById('drawerActions');
  if (status === 'pending') {
    actionsEl.innerHTML = [
      '<button onclick="submitDuyet(' + coSoId + ')"',
        ' class="flex-1 h-10 rounded-xl bg-green-600 text-white text-sm font-semibold hover:bg-green-700 transition-all shadow-md shadow-green-100 flex items-center justify-center gap-1.5">',
        '<i class="ti ti-circle-check"></i>Duyệt yêu cầu',
      '</button>',
      '<button onclick="openTuChoiModal(' + coSoId + ')"',
        ' class="flex-1 h-10 rounded-xl border border-red-300 text-red-600 text-sm font-semibold hover:bg-red-50 transition-all flex items-center justify-center gap-1.5">',
        '<i class="ti ti-circle-x"></i>Từ chối',
      '</button>'
    ].join('');
  } else {
    actionsEl.innerHTML = [
      '<p class="text-xs text-zinc-500 flex-1">Yêu cầu đã bị từ chối.</p>',
      '<button onclick="submitDuyet(' + coSoId + ')"',
        ' class="h-10 px-5 rounded-xl bg-green-600 text-white text-sm font-semibold hover:bg-green-700 transition-all flex items-center justify-center gap-1.5">',
        '<i class="ti ti-circle-check"></i>Duyệt lại',
      '</button>'
    ].join('');
  }

  document.getElementById('detailDrawer').classList.add('open');
  // Shift main content slightly to accommodate drawer
  document.querySelector('main').style.paddingRight = '436px';
}

function closeDrawer() {
  document.getElementById('detailDrawer').classList.remove('open');
  document.querySelector('main').style.paddingRight = '';
  document.querySelectorAll('.req-card').forEach(function(c) { c.classList.remove('selected'); });
  currentDrawerCoSoId = null;
}

function infoRow(icon, label, value) {
  return '<div class="flex items-start gap-2 py-1.5">' +
    '<i class="ti ' + icon + ' text-zinc-400 text-sm mt-0.5 w-4 shrink-0"></i>' +
    '<div><p class="text-[10px] text-zinc-400 leading-none">' + escHtml(label) + '</p>' +
    '<p class="text-xs font-semibold text-zinc-800 mt-0.5">' + escHtml(value || '—') + '</p></div>' +
    '</div>';
}

function escHtml(str) {
  if (!str) return '';
  return String(str).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// ── Approve ────────────────────────────────────────────────────
function submitDuyet(coSoId) {
  if (!confirm('Xác nhận duyệt yêu cầu này? Cơ sở sẽ được kích hoạt và quản lý có thể đăng nhập.')) return;
  var form = document.createElement('form');
  form.method = 'POST';
  form.action = contextPath + '/admin/chi-nhanh';
  addField(form, 'action', 'duyet');
  addField(form, 'id', coSoId);
  document.body.appendChild(form);
  form.submit();
}

// ── Reject ─────────────────────────────────────────────────────
function openTuChoiModal(coSoId) {
  document.getElementById('tuChoiCoSoId').value = coSoId;
  document.getElementById('tuChoiReason').value = '';
  document.getElementById('tuChoiReasonErr').classList.add('hidden');
  document.getElementById('modalTuChoi').classList.remove('hidden');
}

function closeTuChoiModal() {
  document.getElementById('modalTuChoi').classList.add('hidden');
}

function submitTuChoi() {
  var reason = document.getElementById('tuChoiReason').value.trim();
  if (!reason) {
    document.getElementById('tuChoiReasonErr').classList.remove('hidden');
    return;
  }
  var coSoId = document.getElementById('tuChoiCoSoId').value;
  var form = document.createElement('form');
  form.method = 'POST';
  form.action = contextPath + '/admin/chi-nhanh';
  addField(form, 'action', 'tu-choi');
  addField(form, 'id', coSoId);
  addField(form, 'reason', reason);
  document.body.appendChild(form);
  form.submit();
}

function addField(form, name, value) {
  var el = document.createElement('input');
  el.type = 'hidden';
  el.name = name;
  el.value = value;
  form.appendChild(el);
}

var contextPath = '${pageContext.request.contextPath}';
</script>

</body>
</html>
