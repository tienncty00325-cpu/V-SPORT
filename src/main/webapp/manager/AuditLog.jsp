<%-- src/main/webapp/manager/AuditLog.jsp --%>
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="vi">
<head>
<title>Nhật Ký Thao Tác — Manager Portal</title>
<jsp:include page="/manager/common/manager_head.jsp" />
</head>
<body class="text-zinc-900 min-h-screen">

<!-- Sidebar Manager -->
<jsp:include page="/manager/common/sidebar.jsp" />

<!-- Header -->
<c:set var="headerTitle" value="Nhật ký thao tác chi nhánh" scope="page" />
<c:set var="headerSubtitle" value="Chi nhánh cơ sở CS${sessionScope.user.coSoId}" scope="page" />
<c:set var="headerIcon" value="schedule" scope="page" />
<jsp:include page="/manager/common/header.jsp" />

<!-- Main Content -->
<main class="lg:ml-[248px] mt-[64px] p-4 lg:p-6 flex flex-col gap-5">

  <!-- Overview Section -->
  <section class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
    <div>
      <h2 class="text-2xl font-black tracking-tight text-purple-950 flex items-center gap-2">
        <span class="material-symbols-outlined text-purple-750">history</span>Nhật Ký Thao Tác
      </h2>
      <p class="text-sm text-zinc-500 mt-0.5">Giám sát các thao tác cập nhật cấu hình, nhân sự và quản trị cơ sở tại chi nhánh</p>
    </div>
    <span class="bg-purple-700 text-white text-xs font-bold px-3 py-1.5 rounded-xl shadow-sm self-start">
      Tổng cộng: ${total} bản ghi
    </span>
  </section>

  <!-- Flash Messages -->
  <c:if test="${not empty sessionScope.successMsg}">
    <div class="p-4 bg-green-50 border border-green-200 text-green-800 rounded-2xl flex items-start gap-3 shadow-sm animation-fade">
      <span class="material-symbols-outlined text-green-600 mt-0.5">check_circle</span>
      <div>
        <p class="text-sm font-bold">Thành công</p>
        <p class="text-xs text-green-700 mt-0.5"><c:out value="${sessionScope.successMsg}"/></p>
      </div>
    </div>
    <c:remove var="successMsg" scope="session"/>
  </c:if>

  <c:if test="${not empty sessionScope.errorMsg}">
    <div class="p-4 bg-red-50 border border-red-200 text-red-800 rounded-2xl flex items-start gap-3 shadow-sm animation-fade">
      <span class="material-symbols-outlined text-red-600 mt-0.5">error</span>
      <div>
        <p class="text-sm font-bold">Lỗi hệ thống</p>
        <p class="text-xs text-red-700 mt-0.5"><c:out value="${sessionScope.errorMsg}"/></p>
      </div>
    </div>
    <c:remove var="errorMsg" scope="session"/>
  </c:if>

  <!-- Filter Panel -->
  <section class="card p-5 border border-purple-100 bg-white shadow-sm rounded-2xl">
    <form method="get" action="${pageContext.request.contextPath}/manager/audit-log" class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-5 gap-4 items-end" autocomplete="off">
      <div class="flex flex-col gap-1">
        <label class="text-xs font-semibold text-zinc-500">Loại đối tượng</label>
        <select name="entityType" class="h-10 px-3 rounded-xl border border-purple-100 bg-white text-xs text-zinc-700 focus:outline-none focus:ring-2 focus:ring-purple-300 focus:border-purple-500 transition-all">
          <option value="">-- Tất cả --</option>
          <option value="TaiKhoan" <c:if test="${entityType == 'TaiKhoan'}">selected</c:if>>Tài khoản</option>
          <option value="San" <c:if test="${entityType == 'San'}">selected</c:if>>Sân</option>
          <option value="LoaiSan" <c:if test="${entityType == 'LoaiSan'}">selected</c:if>>Loại sân</option>
          <option value="SanPham" <c:if test="${entityType == 'SanPham'}">selected</c:if>>Sản phẩm / Dịch vụ</option>
          <option value="YeuCauNghi" <c:if test="${entityType == 'YeuCauNghi'}">selected</c:if>>Yêu cầu nghỉ</option>
          <option value="HoaDon" <c:if test="${entityType == 'HoaDon'}">selected</c:if>>Hóa đơn</option>
        </select>
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-xs font-semibold text-zinc-500">Hành động</label>
        <select name="action" class="h-10 px-3 rounded-xl border border-purple-100 bg-white text-xs text-zinc-700 focus:outline-none focus:ring-2 focus:ring-purple-300 focus:border-purple-500 transition-all">
          <option value="">-- Tất cả --</option>
          <option value="CREATE" <c:if test="${action == 'CREATE'}">selected</c:if>>Tạo mới</option>
          <option value="UPDATE" <c:if test="${action == 'UPDATE'}">selected</c:if>>Cập nhật</option>
          <option value="SOFT_DELETE" <c:if test="${action == 'SOFT_DELETE'}">selected</c:if>>Xóa mềm</option>
          <option value="RESTORE" <c:if test="${action == 'RESTORE'}">selected</c:if>>Khôi phục</option>
          <option value="PERMANENT_DELETE" <c:if test="${action == 'PERMANENT_DELETE'}">selected</c:if>>Xóa vĩnh viễn</option>
          <option value="ADD_STAFF" <c:if test="${action == 'ADD_STAFF'}">selected</c:if>>Thêm nhân sự</option>
          <option value="APPROVE" <c:if test="${action == 'APPROVE'}">selected</c:if>>Phê duyệt</option>
          <option value="REJECT" <c:if test="${action == 'REJECT'}">selected</c:if>>Từ chối</option>
        </select>
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-xs font-semibold text-zinc-500">Từ ngày</label>
        <input type="date" name="dateFrom" value="<c:out value='${dateFrom}'/>" class="h-10 px-3 rounded-xl border border-purple-100 bg-white text-xs text-zinc-700 focus:outline-none focus:ring-2 focus:ring-purple-300 focus:border-purple-500 transition-all">
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-xs font-semibold text-zinc-500">Đến ngày</label>
        <input type="date" name="dateTo" value="<c:out value='${dateTo}'/>" class="h-10 px-3 rounded-xl border border-purple-100 bg-white text-xs text-zinc-700 focus:outline-none focus:ring-2 focus:ring-purple-300 focus:border-purple-500 transition-all">
      </div>
      <div class="flex gap-2">
        <button type="submit" class="flex-1 bg-purple-700 hover:bg-purple-800 text-white rounded-xl h-10 px-4 flex items-center justify-center gap-1.5 text-xs font-bold shadow transition-all active:scale-95 cursor-pointer">
          <span class="material-symbols-outlined text-[16px]">filter_alt</span>Lọc
        </button>
        <a href="${pageContext.request.contextPath}/manager/audit-log" class="flex-1 text-center bg-purple-50 text-purple-700 rounded-xl border border-purple-100 h-10 px-4 flex items-center justify-center gap-1.5 text-xs font-bold hover:bg-purple-100 transition-all active:scale-95">
          Xóa lọc
        </a>
      </div>
    </form>
  </section>

  <!-- Logs Table Card -->
  <section class="card overflow-hidden border border-purple-100 bg-white rounded-2xl shadow-sm">
    <div class="overflow-x-auto">
      <table class="w-full text-sm">
        <thead class="bg-purple-50/50 border-b border-purple-100 text-purple-950 font-bold text-xs uppercase tracking-wider">
          <tr>
            <th class="px-5 py-3 text-left">Thời gian</th>
            <th class="px-5 py-3 text-left">Người thực hiện</th>
            <th class="px-5 py-3 text-left">Hành động</th>
            <th class="px-5 py-3 text-left">Đối tượng tác động</th>
            <th class="px-5 py-3 text-left">Mô tả chi tiết</th>
            <th class="px-5 py-3 text-left">IP</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-purple-50 text-xs">
          <c:choose>
            <c:when test="${empty logs}">
              <tr>
                <td colspan="6" class="text-center py-16 text-purple-300">
                  <span class="material-symbols-outlined text-[36px] block mb-2 text-purple-200">history</span>
                  <p class="font-semibold text-xs text-purple-400">Không tìm thấy bản ghi nhật ký thao tác nào</p>
                </td>
              </tr>
            </c:when>
            <c:otherwise>
              <c:forEach var="log" items="${logs}">
                <tr class="hover:bg-purple-50/20 transition-colors">
                  <td class="px-5 py-4 whitespace-nowrap text-zinc-500 font-medium">
                    <c:if test="${not empty log.createdAt}">
                      <fmt:parseDate value="${log.createdAt.toString().substring(0,16)}" pattern="yyyy-MM-dd'T'HH:mm" var="parsedDate" />
                      <fmt:formatDate value="${parsedDate}" pattern="dd/MM/yyyy HH:mm" var="formattedDate" />
                      ${formattedDate}
                    </c:if>
                  </td>
                  <td class="px-5 py-4">
                    <div class="flex items-center gap-2.5">
                      <div class="w-7 h-7 rounded-full bg-purple-700 text-white flex items-center justify-center font-black text-[10px] uppercase shadow-sm">
                        ${log.actorName.substring(0,1)}
                      </div>
                      <div>
                        <p class="font-extrabold text-zinc-900 text-xs"><c:out value="${log.actorName}"/></p>
                        <p class="text-[9px] text-purple-500 font-bold uppercase tracking-wider">
                          <c:choose>
                            <c:when test="${log.actorRole == 1}">Admin</c:when>
                            <c:when test="${log.actorRole == 2}">Manager</c:when>
                            <c:otherwise>Nhân viên</c:otherwise>
                          </c:choose>
                        </p>
                      </div>
                    </div>
                  </td>
                  <td class="px-5 py-4 whitespace-nowrap">
                    <c:choose>
                      <c:when test="${log.action == 'CREATE' || log.action == 'ADD_STAFF'}">
                        <span class="badge badge-green"><span class="w-1.5 h-1.5 rounded-full bg-green-600 mr-1.5"></span>Tạo mới</span>
                      </c:when>
                      <c:when test="${log.action == 'UPDATE' || log.action == 'APPROVE'}">
                        <span class="badge badge-purple"><span class="w-1.5 h-1.5 rounded-full bg-purple-600 mr-1.5"></span>Cập nhật</span>
                      </c:when>
                      <c:when test="${log.action == 'SOFT_DELETE' || log.action == 'REJECT'}">
                        <span class="badge badge-amber"><span class="w-1.5 h-1.5 rounded-full bg-amber-600 mr-1.5"></span>Xóa mềm</span>
                      </c:when>
                      <c:when test="${log.action == 'PERMANENT_DELETE'}">
                        <span class="badge badge-red"><span class="w-1.5 h-1.5 rounded-full bg-red-600 mr-1.5"></span>Xóa vĩnh viễn</span>
                      </c:when>
                      <c:otherwise>
                        <span class="badge badge-gray"><span class="w-1.5 h-1.5 rounded-full bg-zinc-500 mr-1.5"></span>Thao tác khác</span>
                      </c:otherwise>
                    </c:choose>
                  </td>
                  <td class="px-5 py-4">
                    <div class="font-semibold text-purple-950 text-xs js-entity-name"><c:out value="${log.entityName}"/></div>
                    <div class="text-[10px] text-purple-400 mt-0.5">
                      <c:choose>
                        <c:when test="${log.entityType == 'TaiKhoan'}">Tài khoản</c:when>
                        <c:when test="${log.entityType == 'San'}">Sân</c:when>
                        <c:when test="${log.entityType == 'LoaiSan'}">Loại sân</c:when>
                        <c:when test="${log.entityType == 'SanPham'}">Sản phẩm</c:when>
                        <c:when test="${log.entityType == 'CoSo'}">Chi nhánh</c:when>
                        <c:when test="${log.entityType == 'CaLamViec'}">Ca làm việc</c:when>
                        <c:when test="${log.entityType == 'YeuCauNghi'}">Yêu cầu nghỉ</c:when>
                        <c:when test="${log.entityType == 'HoaDon'}">Hóa đơn</c:when>
                        <c:when test="${not empty log.entityType}"><c:out value="${log.entityType}"/></c:when>
                      </c:choose>
                    </div>
                  </td>
                  <td class="px-5 py-4 text-zinc-650 max-w-xs md:max-w-md break-words leading-relaxed">
                    <c:out value="${log.details}"/>
                  </td>
                  <td class="px-5 py-4 whitespace-nowrap">
                    <span class="text-[11px] font-mono text-purple-400 bg-purple-50 border border-purple-100/60 px-2.5 py-1 rounded-lg">
                      <c:out value="${log.ipAddress}" default="—"/>
                    </span>
                  </td>
                </tr>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </tbody>
      </table>
    </div>

    <!-- Pagination Footer -->
    <c:if test="${totalPages > 1}">
      <div class="px-5 py-4 border-t border-purple-100 flex items-center justify-between bg-purple-50/20">
        <span class="text-xs text-zinc-500">Hiển thị trang <span class="font-bold text-purple-950">${currentPage}</span> trong <span class="font-bold text-purple-950">${totalPages}</span> trang</span>
        <div class="flex items-center gap-1">
          <c:if test="${currentPage > 1}">
            <c:url var="prevPageUrl" value="">
              <c:param name="page" value="${currentPage - 1}"/>
              <c:param name="entityType" value="${entityType}"/>
              <c:param name="action" value="${action}"/>
              <c:param name="dateFrom" value="${dateFrom}"/>
              <c:param name="dateTo" value="${dateTo}"/>
            </c:url>
            <a href="${prevPageUrl}" class="px-2 py-1 rounded hover:bg-purple-100 text-purple-400 flex items-center justify-center transition-colors">
              <span class="material-symbols-outlined text-[14px]">chevron_left</span>
            </a>
          </c:if>
          <c:forEach begin="1" end="${totalPages}" var="p">
            <c:if test="${p >= currentPage - 2 && p <= currentPage + 2}">
              <c:url var="pageUrl" value="">
                <c:param name="page" value="${p}"/>
                <c:param name="entityType" value="${entityType}"/>
                <c:param name="action" value="${action}"/>
                <c:param name="dateFrom" value="${dateFrom}"/>
                <c:param name="dateTo" value="${dateTo}"/>
              </c:url>
              <a href="${pageUrl}" class="px-2.5 py-1 rounded text-xs transition-all ${p == currentPage ? 'bg-purple-700 text-white font-semibold' : 'hover:bg-purple-100 text-purple-750'}">
                ${p}
              </a>
            </c:if>
          </c:forEach>
          <c:if test="${currentPage < totalPages}">
            <c:url var="nextPageUrl" value="">
              <c:param name="page" value="${currentPage + 1}"/>
              <c:param name="entityType" value="${entityType}"/>
              <c:param name="action" value="${action}"/>
              <c:param name="dateFrom" value="${dateFrom}"/>
              <c:param name="dateTo" value="${dateTo}"/>
            </c:url>
            <a href="${nextPageUrl}" class="px-2 py-1 rounded hover:bg-purple-100 text-purple-400 flex items-center justify-center transition-colors">
              <span class="material-symbols-outlined text-[14px]">chevron_right</span>
            </a>
          </c:if>
        </div>
      </div>
    </c:if>
  </section>
</main>

<script>
  // Clean up raw DB-style entity names stored in old audit records
  document.querySelectorAll('.js-entity-name').forEach(function(el) {
    var t = el.textContent;
    // "AccountID=42 ngay=2026-07-08" → "Ca làm ngày 08/07/2026"
    var m = t.match(/AccountID=\d+\s+ngay=(\d{4})-(\d{2})-(\d{2})/);
    if (m) { el.textContent = 'Ca làm ngày ' + m[3] + '/' + m[2] + '/' + m[1]; return; }
    // Any remaining raw "KEY=value" pairs → strip keys, keep values
    if (/\w+=/.test(t)) {
      el.textContent = t.replace(/\w+=/g, '').replace(/\s+/g, ' ').trim();
    }
  });

  // Mobile sidebar menu toggler
  const mobileMenuBtn = document.getElementById('mobileMenuBtn');
  const sidebar = document.getElementById('sidebar');
  if (mobileMenuBtn && sidebar) {
    mobileMenuBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      sidebar.classList.toggle('-translate-x-full');
    });
    document.addEventListener('click', (e) => {
      if (!sidebar.contains(e.target) && !mobileMenuBtn.contains(e.target)) {
        sidebar.classList.add('-translate-x-full');
      }
    });
  }
</script>
</body>
</html>
