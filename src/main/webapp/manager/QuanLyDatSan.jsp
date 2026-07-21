<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <title>Duyệt đặt sân — Manager Portal</title>
  <jsp:include page="/manager/common/manager_head.jsp" />
</head>
<body class="text-zinc-900 min-h-screen">

  <!-- Sidebar Manager -->
  <jsp:include page="/manager/common/sidebar.jsp" />

  <!-- Header -->
  <c:set var="headerTitle" value="Duyệt yêu cầu đặt sân" scope="page" />
  <c:set var="headerSubtitle" value="Chi nhánh cơ sở CS${sessionScope.user.coSoId}" scope="page" />
  <c:set var="headerIcon" value="schedule" scope="page" />
  <jsp:include page="/manager/common/header.jsp" />

  <!-- Main Content -->
  <main class="lg:ml-[248px] mt-[64px] p-4 lg:p-6 flex flex-col gap-5">

    <!-- Alert Messages -->
    <c:if test="${not empty sessionScope.message}">
      <div class="p-4 bg-green-50 border border-green-200 text-green-800 rounded-2xl flex items-start gap-3 shadow-sm animation-fade">
        <span class="material-symbols-outlined text-green-600 mt-0.5">check_circle</span>
        <div>
          <p class="text-sm font-bold">Thành công</p>
          <p class="text-xs text-green-700 mt-0.5">${sessionScope.message}</p>
        </div>
      </div>
      <c:remove var="message" scope="session" />
    </c:if>

    <c:if test="${not empty sessionScope.error}">
      <div class="p-4 bg-red-50 border border-red-200 text-red-800 rounded-2xl flex items-start gap-3 shadow-sm animation-fade">
        <span class="material-symbols-outlined text-red-600 mt-0.5">error</span>
        <div>
          <p class="text-sm font-bold">Lỗi xử lý</p>
          <p class="text-xs text-red-700 mt-0.5">${sessionScope.error}</p>
        </div>
      </div>
      <c:remove var="error" scope="session" />
    </c:if>

    <c:if test="${not empty sessionScope.priceChangeWarning}">
      <div class="p-4 bg-amber-50 border border-amber-200 text-amber-950 rounded-2xl flex flex-col gap-3 shadow-sm animation-fade">
        <div class="flex items-start gap-3">
          <span class="material-symbols-outlined text-amber-600 mt-0.5">warning</span>
          <div>
            <p class="text-sm font-bold">Cảnh báo thay đổi giá</p>
            <p class="text-xs text-amber-700 mt-0.5">${sessionScope.priceChangeWarning}</p>
          </div>
        </div>
        <div class="flex gap-2 justify-end">
          <form action="${pageContext.request.contextPath}/manager/dat-san" method="POST" class="inline" autocomplete="off">
            <input type="hidden" name="action" value="approve">
            <input type="hidden" name="id" value="${sessionScope.priceChangeId}">
            <input type="hidden" name="confirmPriceChange" value="true">
            <button type="submit" class="px-3 py-1.5 rounded-lg bg-amber-600 hover:bg-amber-700 text-white text-xs font-semibold shadow-sm transition-all active:scale-95">
              Đồng ý duyệt
            </button>
          </form>
          <a href="${pageContext.request.contextPath}/manager/dat-san" class="px-3 py-1.5 rounded-lg bg-zinc-150 hover:bg-zinc-200 text-zinc-700 text-xs font-semibold text-center transition-all active:scale-95">
            Hủy bỏ
          </a>
        </div>
      </div>
      <c:remove var="priceChangeWarning" scope="session" />
      <c:remove var="priceChangeId" scope="session" />
    </c:if>

    <!-- Header Title section -->
    <section class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
      <div>
        <h2 class="text-2xl font-black tracking-tight text-purple-950">Duyệt đặt sân trả sau</h2>
        <p class="text-sm text-purple-550 mt-0.5">Tiếp nhận, phê duyệt hoặc từ chối các yêu cầu đặt lịch của khách hàng</p>
      </div>
    </section>

    <!-- Stats summary widgets -->
    <section class="grid grid-cols-2 sm:grid-cols-5 gap-3">
      <div class="card p-4 hover:shadow-md transition-shadow">
        <div class="flex items-center gap-3">
          <div class="w-9 h-9 rounded-xl bg-purple-50 flex items-center justify-center">
            <span class="material-symbols-outlined text-[18px] text-purple-700">event</span>
          </div>
          <div>
            <p class="text-[10px] text-zinc-500 font-semibold uppercase">Tổng số đơn</p>
            <p class="text-xl font-black text-purple-950" id="stat-total">0</p>
          </div>
        </div>
      </div>
      <div class="card p-4 hover:shadow-md transition-shadow ring-2 ring-purple-100">
        <div class="flex items-center gap-3">
          <div class="w-9 h-9 rounded-xl bg-amber-50 flex items-center justify-center">
            <span class="material-symbols-outlined text-[18px] text-amber-700">pending</span>
          </div>
          <div>
            <p class="text-[10px] text-amber-600 font-semibold uppercase">Chờ duyệt</p>
            <p class="text-xl font-black text-amber-700" id="stat-pending">0</p>
          </div>
        </div>
      </div>
      <div class="card p-4 hover:shadow-md transition-shadow">
        <div class="flex items-center gap-3">
          <div class="w-9 h-9 rounded-xl bg-green-50 flex items-center justify-center">
            <span class="material-symbols-outlined text-[18px] text-green-700">check_circle</span>
          </div>
          <div>
            <p class="text-[10px] text-green-600 font-semibold uppercase">Đã xác nhận</p>
            <p class="text-xl font-black text-green-700" id="stat-approved">0</p>
          </div>
        </div>
      </div>
      <div class="card p-4 hover:shadow-md transition-shadow">
        <div class="flex items-center gap-3">
          <div class="w-9 h-9 rounded-xl bg-red-50 flex items-center justify-center">
            <span class="material-symbols-outlined text-[18px] text-red-600">cancel</span>
          </div>
          <div>
            <p class="text-[10px] text-red-500 font-semibold uppercase">Đã hủy</p>
            <p class="text-xl font-black text-red-600" id="stat-canceled">0</p>
          </div>
        </div>
      </div>
      <div class="card p-4 hover:shadow-md transition-shadow">
        <div class="flex items-center gap-3">
          <div class="w-9 h-9 rounded-xl bg-blue-50 flex items-center justify-center">
            <span class="material-symbols-outlined text-[18px] text-blue-700">play_circle</span>
          </div>
          <div>
            <p class="text-[10px] text-blue-600 font-semibold uppercase">Đang chơi/Xong</p>
            <p class="text-xl font-black text-blue-800" id="stat-active">0</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Filter + Table Section -->
    <section class="card overflow-hidden">
      <!-- Filter Bar -->
      <div class="px-5 py-4 border-b border-purple-50 flex flex-col lg:flex-row lg:items-center gap-3 bg-purple-50/10">
        <div class="relative flex-1 max-w-md">
          <span class="absolute left-3 top-1/2 -translate-y-1/2 material-symbols-outlined text-[18px] text-zinc-400">search</span>
          <input type="search" id="searchInput" autocomplete="off" placeholder="Tìm theo tên khách, số điện thoại, tên sân..."
                 class="h-10 w-full pl-10 pr-3 rounded-xl border border-purple-100 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400">
        </div>
        <div class="flex items-center gap-2">
          <button id="refreshBtn" onclick="location.reload();" class="flex items-center gap-1.5 h-10 px-4 rounded-xl bg-white border border-purple-100 text-sm font-semibold text-purple-700 hover:bg-purple-50">
            <span class="material-symbols-outlined text-[16px]">refresh</span> Làm mới dữ liệu
          </button>
        </div>
      </div>

      <!-- State Navigation Tabs -->
      <div class="px-5 pt-3 border-b border-purple-50 flex items-center gap-1 overflow-x-auto bg-purple-50/10">
        <button onclick="filterTab('all', this)" class="tab-btn px-4 py-2.5 text-sm font-bold whitespace-nowrap border-b-2 border-purple-700 text-purple-700 -mb-px">
          Tất cả <span id="badge-all" class="ml-1 text-xs bg-purple-100 text-purple-700 px-1.5 py-0.5 rounded font-bold">0</span>
        </button>
        <button onclick="filterTab('pending', this)" class="tab-btn px-4 py-2.5 text-sm font-medium whitespace-nowrap text-zinc-500 hover:text-purple-700 border-b-2 border-transparent">
          Chờ duyệt <span id="badge-pending" class="ml-1 text-xs bg-amber-100 text-amber-700 px-1.5 py-0.5 rounded font-bold">0</span>
        </button>
        <button onclick="filterTab('approved', this)" class="tab-btn px-4 py-2.5 text-sm font-medium whitespace-nowrap text-zinc-500 hover:text-purple-700 border-b-2 border-transparent">
          Đã xác nhận <span id="badge-approved" class="ml-1 text-xs bg-green-100 text-green-700 px-1.5 py-0.5 rounded font-bold">0</span>
        </button>
        <button onclick="filterTab('active', this)" class="tab-btn px-4 py-2.5 text-sm font-medium whitespace-nowrap text-zinc-500 hover:text-purple-700 border-b-2 border-transparent">
          Đang sử dụng/Xong <span id="badge-active" class="ml-1 text-xs bg-blue-100 text-blue-700 px-1.5 py-0.5 rounded font-bold">0</span>
        </button>
        <button onclick="filterTab('canceled', this)" class="tab-btn px-4 py-2.5 text-sm font-medium whitespace-nowrap text-zinc-500 hover:text-purple-700 border-b-2 border-transparent">
          Đã hủy <span id="badge-canceled" class="ml-1 text-xs bg-red-100 text-red-700 px-1.5 py-0.5 rounded font-bold">0</span>
        </button>
      </div>

      <!-- Table Container -->
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead class="bg-purple-50/20 border-b border-purple-50">
            <tr>
              <th class="px-5 py-3 text-left text-[11px] font-bold uppercase tracking-wider text-purple-600">Mã ĐS</th>
              <th class="px-5 py-3 text-left text-[11px] font-bold uppercase tracking-wider text-purple-600">Khách hàng</th>
              <th class="px-5 py-3 text-left text-[11px] font-bold uppercase tracking-wider text-purple-600">Sân bóng</th>
              <th class="px-5 py-3 text-left text-[11px] font-bold uppercase tracking-wider text-purple-600">Thời gian đặt</th>
              <th class="px-5 py-3 text-right text-[11px] font-bold uppercase tracking-wider text-purple-600">Tổng tiền</th>
              <th class="px-5 py-3 text-left text-[11px] font-bold uppercase tracking-wider text-purple-600">Trạng thái</th>
              <th class="px-5 py-3 text-left text-[11px] font-bold uppercase tracking-wider text-purple-600">Ghi chú</th>
              <th class="px-5 py-3 text-right text-[11px] font-bold uppercase tracking-wider text-purple-600">Thao tác</th>
            </tr>
          </thead>
          <tbody id="bookingTableBody" class="divide-y divide-purple-50">
            <c:forEach var="item" items="${dsLich}">
              <tr class="hover:bg-purple-50/10 transition-colors booking-row"
                  data-status="${item.trangThai}"
                  data-customer="${item.account != null ? item.account.fullName : 'Khách vãng lai'}"
                  data-phone="${item.account != null ? item.account.phoneNumber : ''}"
                  data-court="${item.san.tenSan}"
                  data-created="${item.createdTime}">

                <td class="px-5 py-4">
                  <div class="flex items-center gap-1.5">
                    <span class="font-mono text-xs text-purple-800 font-bold">#${item.datSanId}</span>
                    <span class="new-order-badge hidden px-1.5 py-0.5 rounded-full bg-amber-100 text-amber-700 text-[9px] font-bold uppercase tracking-wide">Mới</span>
                  </div>
                  <c:if test="${not empty item.createdTime}">
                    <fmt:parseDate value="${item.createdTime.toString().substring(0,16)}" pattern="yyyy-MM-dd'T'HH:mm" var="createdParsed"/>
                    <p class="text-[9px] text-zinc-400 mt-0.5 whitespace-nowrap">Đặt lúc <fmt:formatDate value="${createdParsed}" pattern="dd/MM HH:mm"/></p>
                  </c:if>
                </td>
                
                <td class="px-5 py-4">
                  <div class="flex items-center gap-2.5">
                    <div class="w-8 h-8 rounded-full bg-purple-100 flex items-center justify-center text-purple-700 text-xs font-bold uppercase">
                      ${item.account != null ? item.account.fullName.substring(0,1) : 'K'}
                    </div>
                    <div>
                      <p class="text-xs font-semibold text-zinc-900">${item.account != null ? item.account.fullName : 'Khách vãng lai'}</p>
                      <p class="text-[10px] text-zinc-400">${item.account != null ? item.account.phoneNumber : 'N/A'}</p>
                      <c:if test="${item.account != null}">
                        <c:choose>
                          <c:when test="${item.account.diemUyTin >= 80}">
                            <span class="inline-block mt-0.5 px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-700 text-[9px] font-bold">Uy tín: ${item.account.diemUyTin}/100 — Uy tín tốt</span>
                          </c:when>
                          <c:when test="${item.account.diemUyTin >= 50}">
                            <span class="inline-block mt-0.5 px-1.5 py-0.5 rounded bg-amber-50 text-amber-700 text-[9px] font-bold">Uy tín: ${item.account.diemUyTin}/100 — Cần theo dõi</span>
                          </c:when>
                          <c:otherwise>
                            <span class="inline-block mt-0.5 px-1.5 py-0.5 rounded bg-red-50 text-red-700 text-[9px] font-bold">Uy tín: ${item.account.diemUyTin}/100 — Rủi ro cao</span>
                          </c:otherwise>
                        </c:choose>
                        <c:if test="${item.account.lateCancelCount > 0 || item.account.noShowCount > 0}">
                          <p class="text-[9px] text-zinc-400 mt-0.5">${item.account.lateCancelCount} lần hủy sát giờ, ${item.account.noShowCount} lần không đến</p>
                        </c:if>
                        <c:if test="${item.account.diemUyTin < 50}">
                          <p class="text-[9px] text-red-600 font-bold mt-0.5">⚠ Khách hàng này có lịch sử bùng kèo. Vui lòng cân nhắc trước khi duyệt.</p>
                        </c:if>
                      </c:if>
                    </div>
                  </div>
                </td>
                
                <td class="px-5 py-4">
                  <div class="flex items-center gap-1.5">
                    <span class="material-symbols-outlined text-[15px] text-purple-600">stadium</span>
                    <span class="text-xs font-medium text-zinc-900">${item.san.tenSan}</span>
                  </div>
                </td>
                
                <td class="px-5 py-4">
                  <p class="text-xs font-semibold text-zinc-900">${item.ngayDat}</p>
                  <p class="text-[10px] text-zinc-400">${item.gioBatDau} – ${item.gioKetThuc}</p>
                </td>
                
                <td class="px-5 py-4 text-right">
                  <p class="text-xs font-bold text-purple-950">
                    <fmt:formatNumber value="${item.tongTienDuKien}" type="currency" currencySymbol="đ" maxFractionDigits="0"/>
                  </p>
                  <p class="text-[10px] text-zinc-400">Trả sau</p>
                </td>
                
                <td class="px-5 py-4">
                  <c:choose>
                    <c:when test="${item.trangThai eq 'Chờ xác nhận'}">
                      <span class="badge badge-amber">Chờ duyệt</span>
                    </c:when>
                    <c:when test="${item.trangThai eq 'Đã xác nhận'}">
                      <span class="badge badge-green">Đã duyệt</span>
                    </c:when>
                    <c:when test="${item.trangThai eq 'Đã hủy'}">
                      <span class="badge badge-red">Đã hủy</span>
                    </c:when>
                    <c:when test="${item.trangThai eq 'Đang sử dụng'}">
                      <span class="badge badge-purple flex items-center gap-1">
                        <span class="w-1.5 h-1.5 rounded-full bg-purple-700 live-dot"></span>Đang chơi
                      </span>
                    </c:when>
                    <c:when test="${item.trangThai eq 'Chờ thanh toán'}">
                      <span class="badge badge-amber flex items-center gap-1">
                        <span class="w-1.5 h-1.5 rounded-full bg-amber-600 live-dot"></span>Đang giữ chỗ
                      </span>
                      <c:if test="${not empty item.holdExpiresAt}">
                        <p class="text-[9px] text-amber-600 font-semibold mt-0.5">Hết hạn giữ chỗ: ${item.holdExpiresAt.toString().substring(11,16)}</p>
                      </c:if>
                    </c:when>
                    <c:when test="${item.trangThai eq 'Quá hạn'}">
                      <span class="badge badge-gray">Hết hạn giữ chỗ</span>
                    </c:when>
                    <c:when test="${item.trangThai eq 'Không đến'}">
                      <span class="badge badge-gray">Khách không đến</span>
                    </c:when>
                    <c:otherwise>
                      <span class="badge badge-gray">${item.trangThai}</span>
                    </c:otherwise>
                  </c:choose>
                </td>
                
                <td class="px-5 py-4">
                  <p class="text-[11px] text-zinc-500 max-w-[150px] truncate" title="${item.ghiChu}">${not empty item.ghiChu ? item.ghiChu : '-'}</p>
                </td>
                
                <td class="px-5 py-4 text-right">
                  <c:if test="${item.trangThai eq 'Chờ xác nhận'}">
                    <div class="flex items-center justify-end gap-1">
                      <!-- Form Approve -->
                      <form action="${pageContext.request.contextPath}/manager/dat-san" method="POST" class="inline" autocomplete="off" onsubmit="return confirm('Bạn có chắc chắn muốn duyệt yêu cầu đặt sân này?');">
                        <input type="hidden" name="action" value="approve">
                        <input type="hidden" name="id" value="${item.datSanId}">
                        <button type="submit" class="px-2.5 py-1.5 rounded-lg bg-green-600 text-white text-xs font-semibold hover:bg-green-700 shadow-sm transition-transform active:scale-95" title="Duyệt đơn">
                          Duyệt
                        </button>
                      </form>
                      
                      <!-- Button to Open Reject Modal -->
                      <button onclick="openRejectModal(${item.datSanId})" class="px-2.5 py-1.5 rounded-lg bg-red-650 text-red-600 bg-red-50 text-xs font-semibold hover:bg-red-100 hover:text-red-700 transition-transform active:scale-95" title="Từ chối">
                        Từ chối
                      </button>
                    </div>
                  </c:if>
                </td>
              </tr>
            </c:forEach>
            <c:if test="${empty dsLich}">
              <tr>
                <td colspan="8" class="text-center py-8 text-zinc-400">Không có yêu cầu đặt sân nào được ghi nhận.</td>
              </tr>
            </c:if>
          </tbody>
        </table>
      </div>
      <div id="bookingPagination" class="px-5 py-3 border-t border-purple-50 flex items-center justify-between text-xs text-zinc-500 bg-purple-50/5">
        <span id="bookingPaginationInfo">Hiển thị...</span>
        <div class="flex items-center gap-1" id="bookingPaginationBtns"></div>
      </div>
    </section>
  </main>

  <!-- Reject Modal (Tailwind CSS Popup) -->
  <div id="rejectModal" class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center hidden">
    <div class="w-full max-w-md bg-white rounded-2xl p-6 shadow-2xl animation-pop mx-4">
      <div class="flex items-center justify-between pb-3 border-b border-purple-50">
        <h3 class="text-md font-bold text-purple-950">Từ chối yêu cầu đặt sân</h3>
        <button onclick="closeRejectModal()" class="p-1 rounded-lg hover:bg-purple-50 text-zinc-400 hover:text-zinc-600">
          <span class="material-symbols-outlined text-[20px]">close</span>
        </button>
      </div>
      
      <form action="${pageContext.request.contextPath}/manager/dat-san" method="POST" class="mt-4" autocomplete="off">
        <input type="hidden" name="action" value="reject">
        <input type="hidden" id="rejectId" name="id" value="">
        
        <div>
          <label for="rejectReason" class="block text-xs font-bold text-purple-900 uppercase">Lý do từ chối</label>
          <textarea id="rejectReason" name="reason" rows="3" required maxlength="255" placeholder="Nhập lý do từ chối đơn đặt sân..." 
                    class="mt-1.5 w-full p-3 border border-purple-100 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400 resize-none"></textarea>
        </div>
        
        <div class="mt-5 flex items-center justify-end gap-2.5">
          <button type="button" onclick="closeRejectModal()" class="h-10 px-4 rounded-xl border border-purple-100 text-sm font-semibold text-purple-700 hover:bg-purple-50">
            Hủy bỏ
          </button>
          <button type="submit" class="h-10 px-4 rounded-xl bg-red-600 text-white text-sm font-semibold hover:bg-red-700 shadow-md shadow-red-200">
            Xác nhận Từ chối
          </button>
        </div>
      </form>
    </div>
  </div>

  <script>
    let currentTab = 'all';
    
    // Tab Filter Logic
    function filterTab(tab, element) {
      currentTab = tab;
      
      // Update Tab CSS
      document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('border-purple-700', 'text-purple-700', 'font-bold');
        btn.classList.add('border-transparent', 'text-zinc-500', 'font-medium');
      });
      element.classList.remove('border-transparent', 'text-zinc-500', 'font-medium');
      element.classList.add('border-purple-700', 'text-purple-700', 'font-bold');

      applyFilters();
    }

    let currentPage = 1;
    const pageSize = 5;

    // Apply Filter & Search logic with pagination support
    function applyFilters(resetPage = true) {
      if (resetPage) {
        currentPage = 1;
      }
      const searchValue = document.getElementById('searchInput').value.toLowerCase().trim();
      const rows = Array.from(document.querySelectorAll('.booking-row'));
      
      const matchedRows = [];
      
      rows.forEach(row => {
        const status = row.getAttribute('data-status');
        const customer = row.getAttribute('data-customer').toLowerCase();
        const phone = row.getAttribute('data-phone').toLowerCase();
        const court = row.getAttribute('data-court').toLowerCase();
        
        // Check Tab
        let matchTab = false;
        if (currentTab === 'all') matchTab = true;
        else if (currentTab === 'pending' && status === 'Chờ xác nhận') matchTab = true;
        else if (currentTab === 'approved' && status === 'Đã xác nhận') matchTab = true;
        else if (currentTab === 'active' && (status === 'Đang sử dụng' || status === 'Đã hoàn thành')) matchTab = true;
        else if (currentTab === 'canceled' && status === 'Đã hủy') matchTab = true;
        
        // Check Search
        const matchSearch = customer.includes(searchValue) || phone.includes(searchValue) || court.includes(searchValue);
        
        if (matchTab && matchSearch) {
          matchedRows.push(row);
        } else {
          row.style.display = 'none';
        }
      });

      // Paginate matched rows
      const totalPages = Math.ceil(matchedRows.length / pageSize);
      const start = (currentPage - 1) * pageSize;
      const end = start + pageSize;

      matchedRows.forEach((row, index) => {
        if (index >= start && index < end) {
          row.style.display = '';
        } else {
          row.style.display = 'none';
        }
      });

      // Update Pagination Panel
      const pagPanel = document.getElementById('bookingPagination');
      if (pagPanel) {
        if (matchedRows.length === 0 || totalPages <= 1) {
          pagPanel.classList.add('hidden');
        } else {
          pagPanel.classList.remove('hidden');
          pagPanel.classList.add('flex');
        }
      }

      // Update Pagination Info
      const infoSpan = document.getElementById('bookingPaginationInfo');
      if (infoSpan) {
        const actualEnd = Math.min(end, matchedRows.length);
        if (matchedRows.length > 0) {
          infoSpan.innerText = `Hiển thị \${start + 1}-\${actualEnd} trong \${matchedRows.length} yêu cầu`;
        } else {
          infoSpan.innerText = `Không có yêu cầu nào`;
        }
      }

      // Render Pagination Buttons
      renderPaginationButtons(totalPages);
    }

    function renderPaginationButtons(totalPages) {
      const btnContainer = document.getElementById('bookingPaginationBtns');
      if (!btnContainer) return;
      btnContainer.innerHTML = '';

      if (totalPages <= 1) return;

      // Left arrow
      const prevBtn = document.createElement('button');
      prevBtn.type = 'button';
      prevBtn.className = 'px-2 py-1 rounded hover:bg-purple-100 text-purple-400 disabled:opacity-40 flex items-center justify-center transition-colors';
      prevBtn.disabled = currentPage === 1;
      prevBtn.innerHTML = '<span class="material-symbols-outlined text-[14px]">chevron_left</span>';
      prevBtn.onclick = () => {
        currentPage--;
        applyFilters(false);
      };
      btnContainer.appendChild(prevBtn);

      // Page buttons
      for (let i = 1; i <= totalPages; i++) {
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.innerText = i;
        if (i === currentPage) {
          btn.className = 'px-2.5 py-1 rounded bg-purple-700 text-white font-semibold transition-all';
        } else {
          btn.className = 'px-2.5 py-1 rounded hover:bg-purple-100 text-purple-700 transition-colors';
        }
        btn.onclick = () => {
          currentPage = i;
          applyFilters(false);
        };
        btnContainer.appendChild(btn);
      }

      // Right arrow
      const nextBtn = document.createElement('button');
      nextBtn.type = 'button';
      nextBtn.className = 'px-2 py-1 rounded hover:bg-purple-100 text-purple-400 disabled:opacity-40 flex items-center justify-center transition-colors';
      nextBtn.disabled = currentPage === totalPages;
      nextBtn.innerHTML = '<span class="material-symbols-outlined text-[14px]">chevron_right</span>';
      nextBtn.onclick = () => {
        currentPage++;
        applyFilters(false);
      };
      btnContainer.appendChild(nextBtn);
    }

    // Real-time search listener
    document.getElementById('searchInput').addEventListener('input', () => applyFilters(true));

    // Modal Control
    function openRejectModal(id) {
      document.getElementById('rejectId').value = id;
      document.getElementById('rejectModal').classList.remove('hidden');
    }
    
    function closeRejectModal() {
      document.getElementById('rejectModal').classList.add('hidden');
      document.getElementById('rejectReason').value = '';
    }

    // Calculate Dashboard Statistics from DOM
    function calculateStats() {
      const rows = document.querySelectorAll('.booking-row');
      let total = rows.length;
      let pending = 0;
      let approved = 0;
      let canceled = 0;
      let active = 0;
      
      rows.forEach(row => {
        const status = row.getAttribute('data-status');
        if (status === 'Chờ xác nhận') pending++;
        else if (status === 'Đã xác nhận') approved++;
        else if (status === 'Đã hủy') canceled++;
        else if (status === 'Đang sử dụng' || status === 'Đã hoàn thành') active++;
      });
      
      // Update Widgets
      document.getElementById('stat-total').innerText = total;
      document.getElementById('stat-pending').innerText = pending;
      document.getElementById('stat-approved').innerText = approved;
      document.getElementById('stat-canceled').innerText = canceled;
      document.getElementById('stat-active').innerText = active;
      
      // Update Tab Badges
      document.getElementById('badge-all').innerText = total;
      document.getElementById('badge-pending').innerText = pending;
      document.getElementById('badge-approved').innerText = approved;
      document.getElementById('badge-active').innerText = active;
      document.getElementById('badge-canceled').innerText = canceled;
    }

    // Highlight recently created bookings ("Mới") theo CreatedTime — chỉ hiển thị, không đổi dữ liệu/logic duyệt.
    function highlightNewOrders() {
      const NEW_THRESHOLD_MS = 60 * 60 * 1000; // 60 phút
      const now = Date.now();
      document.querySelectorAll('.booking-row').forEach(row => {
        const createdRaw = row.getAttribute('data-created');
        if (!createdRaw) return;
        const createdMs = new Date(createdRaw).getTime();
        if (!isNaN(createdMs) && now - createdMs >= 0 && now - createdMs <= NEW_THRESHOLD_MS) {
          row.classList.add('bg-amber-50/40');
          const badge = row.querySelector('.new-order-badge');
          if (badge) badge.classList.remove('hidden');
        }
      });
    }

    // Run on load
    window.addEventListener('DOMContentLoaded', () => {
      calculateStats();
      applyFilters(true);
      highlightNewOrders();
    });
  </script>
</body>
</html>
