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
  /* ── Page-specific overrides for Premium B2B Dashboard ── */
  body {
    background-color: #f8fafc !important;
  }
  
  /* Glassmorphic/elevated dashboard cards */
  .stat-card {
    background: #ffffff;
    border: 1px solid #f1f5f9;
    border-radius: 16px;
    padding: 24px;
    box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.05), 0 1px 2px -1px rgba(0, 0, 0, 0.05);
    transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  }
  .stat-card:hover {
    box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
    transform: translateY(-3px);
    border-color: #e2e8f0;
  }
  .stat-icon {
    width: 48px;
    height: 48px;
    border-radius: 14px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }
  
  /* Modern Form Field Styling */
  .form-input {
    height: 40px;
    width: 100%;
    padding: 0 14px;
    border-radius: 10px;
    border: 1px solid #e2e8f0;
    font-size: 13.5px;
    color: #1e293b;
    background: #ffffff;
    transition: all 0.15s ease;
    outline: none;
  }
  .form-input:focus {
    border-color: #7c3aed;
    box-shadow: 0 0 0 4px rgba(124, 58, 237, 0.08);
    background: #ffffff;
  }
  .form-select {
    height: 40px;
    padding: 0 34px 0 14px;
    border-radius: 10px;
    border: 1px solid #e2e8f0;
    font-size: 13.5px;
    color: #1e293b;
    background: #ffffff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='14' height='14' viewBox='0 0 24 24' fill='none' stroke='%2364748b' stroke-width='2'%3E%3Cpath d='m6 9 6 6 6-6'/%3E%3C/svg%3E") no-repeat right 12px center;
    appearance: none;
    outline: none;
    transition: all 0.15s ease;
    cursor: pointer;
  }
  .form-select:focus {
    border-color: #7c3aed;
    box-shadow: 0 0 0 4px rgba(124, 58, 237, 0.08);
  }
  
  /* Visual hierarchy buttons */
  .btn-primary {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    height: 40px;
    padding: 0 18px;
    border-radius: 10px;
    background: #7c3aed;
    color: #ffffff;
    font-size: 13.5px;
    font-weight: 600;
    border: none;
    cursor: pointer;
    box-shadow: 0 4px 12px -2px rgba(124, 58, 237, 0.3);
    transition: all 0.15s ease;
  }
  .btn-primary:hover {
    background: #6d28d9;
    box-shadow: 0 6px 16px -2px rgba(124, 58, 237, 0.4);
  }
  .btn-secondary {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    height: 40px;
    padding: 0 16px;
    border-radius: 10px;
    background: #f5f3ff;
    color: #7c3aed;
    font-size: 13.5px;
    font-weight: 600;
    border: 1px solid #ddd6fe;
    cursor: pointer;
    transition: all 0.15s ease;
  }
  .btn-secondary:hover {
    background: #ede9fe;
    border-color: #c084fc;
  }
  .btn-ghost {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    height: 40px;
    padding: 0 16px;
    border-radius: 10px;
    background: #ffffff;
    color: #475569;
    font-size: 13.5px;
    font-weight: 600;
    border: 1px solid #e2e8f0;
    cursor: pointer;
    transition: all 0.15s ease;
  }
  .btn-ghost:hover {
    background: #f8fafc;
    color: #1e293b;
    border-color: #cbd5e1;
  }
  
  /* Modals Refined */
  .modal-overlay {
    position: fixed;
    inset: 0;
    background: rgba(15, 23, 42, 0.35);
    backdrop-filter: blur(8px);
    -webkit-backdrop-filter: blur(8px);
    z-index: 80;
  }
  .modal-box {
    background: #ffffff;
    border-radius: 24px;
    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.15), 0 0 0 1px rgba(0, 0, 0, 0.05);
    border: none;
    animation: pop 0.25s cubic-bezier(0.16, 1, 0.3, 1) both;
  }
  .modal-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 24px 28px 20px;
    border-bottom: 1px solid #f1f5f9;
  }
  .modal-icon {
    width: 44px;
    height: 44px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }
  .modal-close {
    width: 36px;
    height: 36px;
    border-radius: 50%;
    border: none;
    background: transparent;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #94a3b8;
    cursor: pointer;
    transition: all 0.15s ease;
  }
  .modal-close:hover {
    background: #f1f5f9;
    color: #475569;
  }
  .field-label {
    display: block;
    font-size: 12px;
    font-weight: 700;
    color: #475569;
    margin-bottom: 6px;
    letter-spacing: 0.02em;
    text-transform: uppercase;
  }
  .field-req {
    color: #ef4444;
  }
  .section-sep {
    font-size: 11px;
    font-weight: 800;
    color: #94a3b8;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    padding: 6px 0 12px;
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .section-sep::after {
    content: '';
    flex: 1;
    height: 1px;
    background: #e2e8f0;
  }
  
  /* Tables & Rows */
  tr.row-hover:hover td {
    background: #f8fafc;
  }
  .stock-bar {
    height: 4px;
    border-radius: 2px;
    background: #e2e8f0;
    overflow: hidden;
    margin-top: 4px;
  }
  .stock-bar-fill {
    height: 100%;
    border-radius: 2px;
    transition: width 0.4s ease;
  }
  
  /* Custom Preset Card */
  .preset-card {
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    padding: 14px 16px;
    background: #ffffff;
    transition: all 0.2s ease;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 12px;
  }
  .preset-card:hover {
    border-color: #c084fc;
    background: #faf5ff;
    box-shadow: 0 4px 12px rgba(124, 58, 237, 0.04);
  }
  .preset-card.active {
    border-color: #7c3aed;
    background: #f5f3ff;
    box-shadow: 0 4px 12px rgba(124, 58, 237, 0.06);
  }
  
  @keyframes pop {
    from {
      opacity: 0;
      transform: scale(0.96) translateY(10px);
    }
    to {
      opacity: 1;
      transform: scale(1) translateY(0);
    }
  }
</style>
</head>
<body class="text-zinc-900 min-h-screen">

<jsp:include page="/manager/common/sidebar.jsp" />

<c:set var="headerTitle" value="Kho & Dịch vụ" scope="page" />
<c:set var="headerSubtitle" value="Chi nhánh CS${sessionScope.user.coSoId}" scope="page" />
<c:set var="headerIcon" value="inventory_2" scope="page" />
<jsp:include page="/manager/common/header.jsp" />

<main class="lg:ml-[248px] mt-[64px] p-4 lg:p-6 flex flex-col gap-5">

  <%-- ── A. STATUS ALERTS ── --%>
  <c:if test="${not empty successMsg}">
    <div class="flex items-center gap-3 p-4 bg-emerald-50 border border-emerald-100 text-emerald-800 rounded-2xl shadow-sm animation-fadeUp">
      <span class="material-symbols-outlined text-emerald-600 text-[20px]" style="font-variation-settings:'FILL' 1">check_circle</span>
      <p class="text-sm font-semibold">${successMsg}</p>
    </div>
  </c:if>
  <c:if test="${not empty errorMsg}">
    <div class="flex items-center gap-3 p-4 bg-rose-50 border border-rose-100 text-rose-800 rounded-2xl shadow-sm animation-fadeUp">
      <span class="material-symbols-outlined text-rose-600 text-[20px]" style="font-variation-settings:'FILL' 1">error</span>
      <p class="text-sm font-semibold">${errorMsg}</p>
    </div>
  </c:if>

  <%-- ── B. PAGE HEADER ── --%>
  <section class="mb-2">
    <nav class="flex items-center gap-1.5 text-[11px] text-slate-400 font-medium mb-3 select-none">
      <span class="material-symbols-outlined text-[14px]">home</span>
      <span class="material-symbols-outlined text-[12px] text-slate-300">chevron_right</span>
      <span>Kinh doanh & Dịch vụ</span>
      <span class="material-symbols-outlined text-[12px] text-slate-300">chevron_right</span>
      <span class="font-semibold text-slate-600">Kho & Dịch vụ</span>
    </nav>
    <div class="flex items-center justify-between gap-4 flex-wrap">
      <div>
        <h1 class="text-2xl font-extrabold text-slate-900 tracking-tight">Kho &amp; Dịch vụ</h1>
        <p class="text-[13.5px] text-slate-500 mt-1">Quản lý mặt hàng, dịch vụ bán tại chi nhánh và theo dõi tồn kho.</p>
      </div>
      <div class="flex items-center gap-2 px-3 py-1.5 bg-emerald-50/60 rounded-xl border border-emerald-100/60 shrink-0 shadow-sm">
        <span class="w-2.5 h-2.5 rounded-full bg-emerald-500 live-dot shrink-0"></span>
        <span class="text-[11.5px] font-bold text-emerald-700">CS${sessionScope.user.coSoId} — Đang hoạt động</span>
      </div>
    </div>
  </section>

  <%-- ── C. STAT CARDS ── --%>
  <section class="grid grid-cols-2 lg:grid-cols-4 gap-4 stagger">
    <!-- Card 1: Tổng mặt hàng -->
    <div class="stat-card">
      <div class="flex items-start justify-between mb-4">
        <div class="stat-icon bg-violet-50 text-violet-600">
          <span class="material-symbols-outlined text-[24px]" style="font-variation-settings:'FILL' 1">inventory_2</span>
        </div>
        <span class="text-[11px] font-bold text-slate-400 bg-slate-100 px-2 py-0.5 rounded-md">Mặt hàng</span>
      </div>
      <p class="text-3xl font-extrabold text-slate-900 leading-none">${totalItems}</p>
      <p class="text-sm font-bold text-slate-700 mt-2">Tổng mặt hàng</p>
      <p class="text-[11.5px] text-slate-400 mt-0.5">Mẫu đang quản lý tại kho</p>
    </div>

    <!-- Card 2: Tổng giá trị tồn kho -->
    <div class="stat-card">
      <div class="flex items-start justify-between mb-4">
        <div class="stat-icon bg-emerald-50 text-emerald-600">
          <span class="material-symbols-outlined text-[24px]" style="font-variation-settings:'FILL' 1">payments</span>
        </div>
        <span class="text-[11px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-md">Giá trị</span>
      </div>
      <p class="text-3xl font-extrabold text-slate-900 leading-none">
        <fmt:formatNumber value="${totalInventoryValue}" pattern="#,##0"/>đ
      </p>
      <p class="text-sm font-bold text-slate-700 mt-2">Tổng giá trị tồn kho</p>
      <p class="text-[11.5px] text-slate-400 mt-0.5">Tính theo đơn giá nhập kho</p>
    </div>

    <!-- Card 3: Sắp hết hàng -->
    <div class="stat-card">
      <div class="flex items-start justify-between mb-4">
        <div class="stat-icon bg-amber-50 text-amber-600">
          <span class="material-symbols-outlined text-[24px]" style="font-variation-settings:'FILL' 1">production_quantity_limits</span>
        </div>
        <c:choose>
          <c:when test="${lowStockCount > 0}">
            <span class="text-[11px] font-bold text-amber-700 bg-amber-50 px-2 py-0.5 rounded-md flex items-center gap-1">
              <span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>Cảnh báo
            </span>
          </c:when>
          <c:otherwise>
            <span class="text-[11px] font-bold text-slate-400 bg-slate-100 px-2 py-0.5 rounded-md">Ổn định</span>
          </c:otherwise>
        </c:choose>
      </div>
      <p class="text-3xl font-extrabold leading-none ${lowStockCount > 0 ? 'text-amber-600' : 'text-slate-900'}">${lowStockCount}</p>
      <p class="text-sm font-bold text-slate-700 mt-2">Sắp hết hàng</p>
      <p class="text-[11.5px] text-slate-400 mt-0.5">${lowStockCount > 0 ? 'Số lượng tồn kho dưới 5' : 'Tồn kho nằm trong hạn mức'}</p>
    </div>

    <!-- Card 4: Hết hàng -->
    <div class="stat-card">
      <div class="flex items-start justify-between mb-4">
        <div class="stat-icon bg-rose-50 text-rose-600">
          <span class="material-symbols-outlined text-[24px]" style="font-variation-settings:'FILL' 1">remove_shopping_cart</span>
        </div>
        <c:choose>
          <c:when test="${outOfStockCount > 0}">
            <span class="text-[11px] font-bold text-rose-700 bg-rose-50 px-2 py-0.5 rounded-md flex items-center gap-1 animate-pulse">
              <span class="w-1.5 h-1.5 rounded-full bg-rose-500"></span>Hết hàng
            </span>
          </c:when>
          <c:otherwise>
            <span class="text-[11px] font-bold text-slate-400 bg-slate-100 px-2 py-0.5 rounded-md">Trống</span>
          </c:otherwise>
        </c:choose>
      </div>
      <p class="text-3xl font-extrabold leading-none ${outOfStockCount > 0 ? 'text-rose-600' : 'text-slate-900'}">${outOfStockCount}</p>
      <p class="text-sm font-bold text-slate-700 mt-2">Đã hết hàng</p>
      <p class="text-[11.5px] text-slate-400 mt-0.5">${outOfStockCount > 0 ? 'Cần bổ sung mặt hàng ngay' : 'Không có sản phẩm hết hàng'}</p>
    </div>
  </section>

  <%-- ── D. ACTION BAR ── --%>
  <section class="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-sm">
    <form action="${pageContext.request.contextPath}/manager/kho-dich-vu" method="GET">
      <div class="flex flex-col lg:flex-row items-stretch lg:items-center gap-4">
        <%-- Left: search + filters --%>
        <div class="flex items-center gap-3 flex-wrap flex-1">
          <div class="relative flex-1 min-w-[260px]">
            <span class="absolute left-3.5 top-1/2 -translate-y-1/2 material-symbols-outlined text-[18px] text-slate-400 pointer-events-none">search</span>
            <input type="search" name="search" value="${search}" autocomplete="off"
                   placeholder="Tìm mặt hàng theo tên hoặc mã SKU..."
                   class="form-input pl-10 bg-slate-50/50 hover:bg-slate-50 focus:bg-white border-slate-200">
          </div>
          <select name="category" class="form-select min-w-[160px] max-w-[220px]">
            <option value="">Tất cả nhóm dịch vụ</option>
            <c:forEach items="${categories}" var="cat">
              <option value="${cat.danhMucID}" ${selectedCategory == cat.danhMucID ? 'selected' : ''}>${cat.tenDanhMuc}</option>
            </c:forEach>
          </select>
          <select name="status" class="form-select min-w-[150px]">
            <option value="">Tất cả trạng thái</option>
            <option value="Đang kinh doanh" ${selectedStatus == 'Đang kinh doanh' ? 'selected' : ''}>Đang kinh doanh</option>
            <option value="Tạm hết hàng"    ${selectedStatus == 'Tạm hết hàng'    ? 'selected' : ''}>Tạm hết hàng</option>
            <option value="Ngừng kinh doanh" ${selectedStatus == 'Ngừng kinh doanh'? 'selected' : ''}>Ngừng kinh doanh</option>
          </select>
          <div class="flex items-center gap-2">
            <button type="submit" class="btn-ghost text-sm border-slate-200 hover:bg-slate-50 hover:border-slate-300">
              <span class="material-symbols-outlined text-[18px] text-slate-500">filter_list</span>Lọc
            </button>
            <a href="${pageContext.request.contextPath}/manager/kho-dich-vu" class="btn-ghost text-sm border-slate-200 hover:bg-slate-50" title="Xóa bộ lọc">
              <span class="material-symbols-outlined text-[18px] text-slate-500">restart_alt</span>
            </a>
          </div>
        </div>
        <%-- Right: action buttons with clear B2B hierarchy --%>
        <div class="flex items-center gap-2.5 shrink-0 flex-wrap">
          <button type="button" onclick="openCategoryModal()" class="btn-ghost text-sm text-slate-700 hover:text-slate-900 border-slate-200">
            <span class="material-symbols-outlined text-[18px] text-slate-500">category</span>
            <span>Quản lý nhóm dịch vụ</span>
          </button>
          <button type="button" onclick="openPresetModal()" class="btn-secondary text-sm">
            <span class="material-symbols-outlined text-[18px]">bolt</span>
            <span>Thêm nhanh từ mẫu</span>
          </button>
          <button type="button" onclick="openAddModal()" class="btn-primary text-sm">
            <span class="material-symbols-outlined text-[18px]">add</span>Thêm mặt hàng mới
          </button>
        </div>
      </div>
    </form>

    <%-- Result count + helper strip --%>
    <div class="mt-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3 px-4 py-3 bg-slate-50 border border-slate-100 rounded-xl text-[12px] text-slate-500">
      <div class="flex items-center gap-2">
        <span class="material-symbols-outlined text-violet-500 text-[18px]">info</span>
        <span>Bạn có thể thêm mặt hàng mới từ đầu hoặc dùng mẫu có sẵn để tạo nhanh các dịch vụ thường bán tại sân.</span>
      </div>
      <p class="shrink-0 font-medium">Hiển thị <span class="font-bold text-violet-700">${productList.size()}</span> / <span class="font-bold text-slate-700">${totalItems}</span> mặt hàng</p>
    </div>
  </section>

  <%-- ── E. CONTENT ── --%>
  <c:choose>
    <c:when test="${totalItems == 0}">
      <%-- EMPTY STATE --%>
      <section class="bg-white rounded-2xl border border-dashed border-slate-200 py-16 px-6 flex flex-col items-center text-center reveal-on-scroll shadow-sm">
        <div class="w-16 h-16 rounded-2xl bg-violet-50 text-violet-600 flex items-center justify-center mb-5">
          <span class="material-symbols-outlined text-[36px]" style="font-variation-settings:'FILL' 1">inventory_2</span>
        </div>
        <h3 class="text-lg font-extrabold text-slate-900 mb-2">Kho dịch vụ chưa có mặt hàng nào</h3>
        <p class="text-sm text-slate-500 max-w-md mb-2 leading-relaxed">Bạn có thể thêm các dịch vụ bán tại sân như nước uống, thuê vợt, thuê bóng hoặc khăn lạnh để quản lý doanh thu tiện ích.</p>
        <p class="text-xs text-slate-400 mb-6 italic">Ví dụ: Nước suối, nước ngọt, thuê vợt, thuê bóng, khăn lạnh.</p>
        <div class="flex items-center gap-3 flex-wrap justify-center">
          <button onclick="openPresetModal()" class="btn-secondary">
            <span class="material-symbols-outlined text-[18px]">bolt</span>Thêm nhanh từ mẫu có sẵn
          </button>
          <button onclick="openAddModal()" class="btn-primary">
            <span class="material-symbols-outlined text-[18px]">add</span>Thêm mặt hàng mới
          </button>
        </div>
        <c:if test="${empty categories}">
          <div class="mt-8 p-4 bg-amber-50 border border-amber-100 rounded-2xl max-w-sm text-left flex items-start gap-3">
            <span class="material-symbols-outlined text-amber-600 text-[20px] shrink-0 mt-0.5">warning</span>
            <div>
              <p class="text-xs font-bold text-amber-800">Chưa có nhóm dịch vụ</p>
              <p class="text-[11px] text-amber-600 mt-0.5 mb-2">Nên tạo nhóm dịch vụ trước (Đồ uống, Thuê dụng cụ...) để phân loại mặt hàng và quản lý tốt hơn.</p>
              <button onclick="openCategoryModal()" class="text-xs font-bold text-violet-700 hover:text-violet-900 flex items-center gap-1">
                <span class="material-symbols-outlined text-[14px]">category</span>Quản lý nhóm dịch vụ →
              </button>
            </div>
          </div>
        </c:if>
      </section>
    </c:when>
    <c:when test="${empty productList}">
      <%-- NO FILTER RESULTS --%>
      <section class="bg-white rounded-2xl border border-slate-200 py-16 flex flex-col items-center text-center shadow-sm">
        <span class="material-symbols-outlined text-[44px] text-slate-300 mb-2">search_off</span>
        <h3 class="text-base font-bold text-slate-800">Không tìm thấy mặt hàng nào</h3>
        <p class="text-sm text-slate-400 max-w-xs mt-1">Vui lòng điều chỉnh từ khóa tìm kiếm hoặc thay đổi bộ lọc nhóm/trạng thái.</p>
        <a href="${pageContext.request.contextPath}/manager/kho-dich-vu" class="btn-secondary text-sm mt-5">
          <span class="material-symbols-outlined text-[18px]">restart_alt</span>Xóa bộ lọc
        </a>
      </section>
    </c:when>
    <c:otherwise>
      <%-- PRODUCT TABLE --%>
      <section class="bg-white rounded-2xl border border-slate-200/80 overflow-hidden shadow-sm reveal-on-scroll">
        <div class="overflow-x-auto">
          <table class="w-full text-left text-xs border-collapse">
            <thead class="bg-slate-50 border-b border-slate-200/80">
              <tr>
                <th class="px-5 py-4 text-[11px] font-bold text-slate-500 uppercase tracking-wider w-32">SKU / Mã</th>
                <th class="px-5 py-4 text-[11px] font-bold text-slate-500 uppercase tracking-wider">Tên mặt hàng</th>
                <th class="px-5 py-4 text-[11px] font-bold text-slate-500 uppercase tracking-wider hidden sm:table-cell">Nhóm dịch vụ</th>
                <th class="px-5 py-4 text-[11px] font-bold text-slate-500 uppercase tracking-wider text-right hidden md:table-cell">Giá nhập</th>
                <th class="px-5 py-4 text-[11px] font-bold text-slate-500 uppercase tracking-wider text-right hidden md:table-cell">Giá bán lẻ</th>
                <th class="px-5 py-4 text-[11px] font-bold text-slate-500 uppercase tracking-wider text-center w-28">Tồn kho</th>
                <th class="px-5 py-4 text-[11px] font-bold text-slate-500 uppercase tracking-wider">Trạng thái</th>
                <th class="px-5 py-4 text-[11px] font-bold text-slate-500 uppercase tracking-wider text-right w-32">Thao tác</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <c:forEach items="${productList}" var="sp">
                <c:set var="isOut" value="${sp.soLuongTon == 0}" />
                <c:set var="isLow" value="${sp.soLuongTon > 0 and sp.soLuongTon <= 5}" />
                <tr class="row-hover transition-colors">
                  <td class="px-5 py-4">
                    <span class="font-mono text-[11px] text-slate-500 font-bold bg-slate-50 border border-slate-200 px-2 py-1 rounded-lg">
                      ${sp.skuCode != null ? sp.skuCode : 'N/A'}
                    </span>
                  </td>
                  <td class="px-5 py-4">
                    <div class="flex items-center gap-3">
                      <div class="w-10 h-10 rounded-xl overflow-hidden bg-slate-100 border border-slate-200/60 shrink-0 flex items-center justify-center shadow-xs">
                        <c:choose>
                          <c:when test="${not empty sp.hinhAnh}">
                            <img src="${pageContext.request.contextPath}${sp.hinhAnh}" alt="${fn:escapeXml(sp.tenSanPham)}" class="w-full h-full object-cover">
                          </c:when>
                          <c:otherwise>
                            <span class="material-symbols-outlined text-[20px] text-slate-300">image</span>
                          </c:otherwise>
                        </c:choose>
                      </div>
                      <div>
                        <p class="font-bold text-slate-800 text-[13.5px]">${sp.tenSanPham}</p>
                        <c:if test="${not empty sp.moTa}">
                          <p class="text-[11px] text-slate-400 mt-0.5 max-w-[240px] truncate">${sp.moTa}</p>
                        </c:if>
                      </div>
                    </div>
                  </td>
                  <td class="px-5 py-4 hidden sm:table-cell">
                    <c:forEach items="${categories}" var="cat">
                      <c:if test="${cat.danhMucID == sp.danhMucID}">
                        <span class="badge badge-purple border border-purple-100 text-[11px] py-0.5 px-2 rounded-md font-bold">${cat.tenDanhMuc}</span>
                      </c:if>
                    </c:forEach>
                  </td>
                  <td class="px-5 py-4 text-right text-slate-500 font-semibold hidden md:table-cell">
                    <fmt:formatNumber value="${sp.giaNhap}" pattern="#,##0"/>đ
                  </td>
                  <td class="px-5 py-4 text-right font-extrabold text-slate-900 hidden md:table-cell">
                    <fmt:formatNumber value="${sp.donGia}" pattern="#,##0"/>đ
                  </td>
                  <td class="px-5 py-4 text-center">
                    <c:choose>
                      <c:when test="${isOut}">
                        <span class="inline-flex items-center justify-center gap-1 w-full max-w-[92px] font-bold text-[12px] text-rose-600 bg-rose-50 border border-rose-100 py-1 rounded-lg">
                          <span class="material-symbols-outlined text-[13px]">remove_shopping_cart</span>Hết hàng
                        </span>
                      </c:when>
                      <c:when test="${isLow}">
                        <span class="inline-flex items-center justify-center gap-1 w-full max-w-[92px] font-bold text-[12px] text-amber-700 bg-amber-50 border border-amber-100 py-1 rounded-lg">
                          <span class="material-symbols-outlined text-[13px]">warning</span>${sp.soLuongTon} ${sp.donViTinh != null ? sp.donViTinh : 'cái'}
                        </span>
                      </c:when>
                      <c:otherwise>
                        <span class="inline-block w-full max-w-[92px] font-bold text-[12px] text-slate-700 bg-slate-50 border border-slate-100 py-1 rounded-lg">${sp.soLuongTon} ${sp.donViTinh != null ? sp.donViTinh : 'cái'}</span>
                      </c:otherwise>
                    </c:choose>
                  </td>
                  <td class="px-5 py-4">
                    <span class="badge
                      <c:choose>
                        <c:when test="${sp.trangThai == 'Đang kinh doanh'}">badge-green</c:when>
                        <c:when test="${sp.trangThai == 'Tạm hết hàng'}">badge-amber</c:when>
                        <c:otherwise>badge-gray</c:otherwise>
                      </c:choose>
                      text-[11px] py-1 px-2.5 rounded-full font-bold
                    ">${sp.trangThai}</span>
                  </td>
                  <td class="px-5 py-4">
                    <div class="flex items-center justify-end gap-1.5">
                      <button onclick="openDetailModal(${sp.sanPhamID}, '${sp.skuCode}', '${sp.tenSanPham}', ${sp.danhMucID}, ${sp.donGia}, ${sp.giaNhap}, '${sp.donViTinh}', ${sp.soLuongTon}, '${sp.trangThai}', '${sp.moTa}')"
                              title="Xem chi tiết"
                              class="w-8 h-8 rounded-lg hover:bg-sky-50 text-sky-600 flex items-center justify-center transition-colors">
                        <span class="material-symbols-outlined text-[18px]">visibility</span>
                      </button>
                      <button onclick="openStockModal(${sp.sanPhamID}, '${sp.skuCode}', '${sp.tenSanPham}', ${sp.soLuongTon}, '${sp.donViTinh}')"
                              title="Nhập kho / cập nhật số lượng"
                              class="w-8 h-8 rounded-lg hover:bg-violet-50 text-violet-600 flex items-center justify-center transition-colors">
                        <span class="material-symbols-outlined text-[18px]">add_box</span>
                      </button>
                      <button onclick="openEditModal(${sp.sanPhamID}, '${sp.skuCode}', '${sp.tenSanPham}', ${sp.danhMucID}, ${sp.donGia}, ${sp.giaNhap}, '${sp.donViTinh}', ${sp.soLuongTon}, '${sp.trangThai}', '${sp.moTa}', '${sp.hinhAnh}')"
                              title="Chỉnh sửa"
                              class="w-8 h-8 rounded-lg hover:bg-indigo-50 text-indigo-600 flex items-center justify-center transition-colors">
                        <span class="material-symbols-outlined text-[18px]">edit</span>
                      </button>
                      <button onclick="confirmDelete(${sp.sanPhamID}, '${sp.tenSanPham}')"
                              title="Xóa mềm (khôi phục tại Thùng rác)"
                              class="w-8 h-8 rounded-lg hover:bg-rose-50 text-rose-500 flex items-center justify-center transition-colors">
                        <span class="material-symbols-outlined text-[18px]">delete_outline</span>
                      </button>
                    </div>
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
      </section>
    </c:otherwise>
  </c:choose>

</main>

<%-- ═══════════════════════════════════════════
     MODAL 1: THÊM MẶT HÀNG MỚI
════════════════════════════════════════════ --%>
<div id="addModal" class="modal-overlay hidden z-[80] flex items-start justify-center p-4 pt-10 overflow-y-auto">
  <div class="modal-box relative w-full max-w-[680px] z-10 my-8">
    <div class="modal-header">
      <div class="flex items-center gap-3">
        <div class="modal-icon bg-violet-50 text-violet-600">
          <span class="material-symbols-outlined text-[24px]">inventory_2</span>
        </div>
        <div>
          <h3 class="text-base font-extrabold text-slate-900">Thêm mặt hàng mới</h3>
          <p class="text-xs text-slate-500 mt-0.5">Tạo sản phẩm hoặc dịch vụ bán tại chi nhánh.</p>
        </div>
      </div>
      <button type="button" onclick="closeAddModal()" class="modal-close"><span class="material-symbols-outlined text-[20px]">close</span></button>
    </div>

    <form action="${pageContext.request.contextPath}/manager/kho-dich-vu" method="POST" enctype="multipart/form-data" class="px-8 py-6 flex flex-col gap-6">
      <input type="hidden" name="action" value="add">

      <%-- Group 1: Thông tin cơ bản --%>
      <div>
        <p class="section-sep"><span class="material-symbols-outlined text-[15px] text-slate-400">info</span>Thông tin cơ bản</p>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="field-label">Mã SKU</label>
            <div class="flex gap-2">
              <input type="text" id="addSkuCode" name="skuCode" placeholder="VD: NUOC-LAVIE-500" class="form-input flex-1 font-mono text-[13px]">
              <button type="button" onclick="regenerateAddSku()" title="Tạo mã ngẫu nhiên" class="h-[40px] w-10 border border-slate-200 hover:border-violet-300 rounded-lg hover:bg-violet-50 text-violet-500 flex items-center justify-center shrink-0 transition-colors">
                <span class="material-symbols-outlined text-[18px]">refresh</span>
              </button>
            </div>
          </div>
          <div>
            <label class="field-label">Tên mặt hàng <span class="field-req">*</span></label>
            <input type="text" name="tenSanPham" maxlength="100" required placeholder="Nước suối Lavie 500ml" class="form-input">
          </div>
          <div>
            <label class="field-label">Nhóm dịch vụ <span class="field-req">*</span></label>
            <select name="danhMucID" required class="form-select w-full">
              <option value="">-- Chọn nhóm --</option>
              <c:forEach items="${categories}" var="cat">
                <option value="${cat.danhMucID}">${cat.tenDanhMuc}</option>
              </c:forEach>
            </select>
          </div>
          <div>
            <label class="field-label">Đơn vị tính <span class="field-req">*</span></label>
            <input type="text" name="donViTinh" required placeholder="Chai / Lon / Lượt / Giờ" class="form-input">
          </div>
        </div>
      </div>

      <%-- Group 2: Giá & Tồn kho --%>
      <div>
        <p class="section-sep"><span class="material-symbols-outlined text-[15px] text-slate-400">payments</span>Giá &amp; Tồn kho</p>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label class="field-label">Giá nhập (đ) <span class="field-req">*</span></label>
            <input type="number" step="any" name="giaNhap" min="0" required placeholder="5,000" class="form-input">
          </div>
          <div>
            <label class="field-label">Giá bán lẻ (đ) <span class="field-req">*</span></label>
            <input type="number" step="any" name="donGia" min="0" required placeholder="10,000" class="form-input">
          </div>
          <div>
            <label class="field-label">Số lượng ban đầu</label>
            <input type="number" name="soLuongTon" value="0" min="0" class="form-input">
          </div>
        </div>
        <div class="mt-4">
          <label class="field-label">Trạng thái kinh doanh</label>
          <select name="trangThai" class="form-select w-full">
            <option value="Đang kinh doanh">Đang kinh doanh</option>
            <option value="Tạm hết hàng">Tạm hết hàng</option>
            <option value="Ngừng kinh doanh">Ngừng kinh doanh</option>
          </select>
        </div>
      </div>

      <%-- Group 3: Mô tả & Ảnh --%>
      <div>
        <label class="field-label">Mô tả mặt hàng</label>
        <input type="text" name="moTa" placeholder="Thông tin tóm tắt về mặt hàng..." class="form-input">
      </div>
      <div>
        <label class="field-label">Ảnh sản phẩm</label>
        <input type="file" name="hinhAnhFile" accept="image/jpeg,image/png,image/webp,image/gif" class="form-input">
        <p class="text-[11px] text-slate-400 mt-1">JPG, PNG, WEBP hoặc GIF, tối đa 5MB. Để trống nếu chưa có ảnh — Customer sẽ thấy ảnh mặc định.</p>
      </div>

      <div class="flex items-center justify-between pt-4 border-t border-slate-100 mt-2">
        <p class="text-[12px] text-slate-400 font-medium"><span class="text-red-500">*</span> Trường bắt buộc nhập</p>
        <div class="flex gap-2.5">
          <button type="button" onclick="closeAddModal()" class="btn-ghost text-sm">Hủy</button>
          <button type="submit" class="btn-primary text-sm"><span class="material-symbols-outlined text-[18px]">save</span>Lưu mặt hàng</button>
        </div>
      </div>
    </form>
  </div>
</div>

<%-- ═══════════════════════════════════════════
     MODAL: XEM CHI TIẾT (CHỈ ĐỌC)
════════════════════════════════════════════ --%>
<div id="detailModal" class="modal-overlay hidden z-[80] flex items-center justify-center p-4">
  <div class="modal-box relative w-full max-w-[480px] z-10">
    <div class="modal-header">
      <div class="flex items-center gap-3">
        <div class="modal-icon bg-sky-50 text-sky-600">
          <span class="material-symbols-outlined text-[24px]">visibility</span>
        </div>
        <div>
          <h3 class="text-base font-extrabold text-slate-900">Chi tiết mặt hàng</h3>
          <p class="text-xs text-slate-500 mt-0.5">Thông tin đầy đủ, chỉ xem — không chỉnh sửa tại đây.</p>
        </div>
      </div>
      <button type="button" onclick="closeDetailModal()" class="modal-close"><span class="material-symbols-outlined text-[20px]">close</span></button>
    </div>

    <div class="px-6 py-5 flex flex-col gap-4">
      <div class="flex items-start justify-between gap-3">
        <div>
          <p class="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-1">Tên mặt hàng</p>
          <p class="font-extrabold text-slate-900 text-base" id="detailName">—</p>
        </div>
        <span class="font-mono text-[11px] text-slate-500 font-bold bg-slate-50 border border-slate-200 px-2 py-1 rounded-lg shrink-0" id="detailSku">—</span>
      </div>

      <div class="grid grid-cols-2 gap-3">
        <div class="bg-slate-50 border border-slate-100 rounded-xl px-3 py-2.5">
          <p class="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-0.5">Nhóm dịch vụ</p>
          <p class="font-bold text-slate-800 text-[13px]" id="detailCategory">—</p>
        </div>
        <div class="bg-slate-50 border border-slate-100 rounded-xl px-3 py-2.5">
          <p class="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-0.5">Trạng thái</p>
          <p class="font-bold text-slate-800 text-[13px]" id="detailStatus">—</p>
        </div>
        <div class="bg-slate-50 border border-slate-100 rounded-xl px-3 py-2.5">
          <p class="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-0.5">Giá nhập</p>
          <p class="font-bold text-slate-800 text-[13px]" id="detailGiaNhap">—</p>
        </div>
        <div class="bg-slate-50 border border-slate-100 rounded-xl px-3 py-2.5">
          <p class="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-0.5">Giá bán lẻ</p>
          <p class="font-extrabold text-slate-900 text-[13px]" id="detailGiaBan">—</p>
        </div>
        <div class="bg-slate-50 border border-slate-100 rounded-xl px-3 py-2.5 col-span-2">
          <p class="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-0.5">Tồn kho hiện tại</p>
          <p class="font-bold text-slate-800 text-[13px]" id="detailStock">—</p>
        </div>
      </div>

      <div>
        <p class="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-1">Mô tả</p>
        <p class="text-[13px] text-slate-600 leading-relaxed" id="detailDesc">—</p>
      </div>

      <div class="flex justify-end pt-4 border-t border-slate-100">
        <button type="button" onclick="closeDetailModal()" class="btn-ghost text-sm">Đóng</button>
      </div>
    </div>
  </div>
</div>

<%-- ═══════════════════════════════════════════
     MODAL 2: CHỈNH SỬA MẶT HÀNG
════════════════════════════════════════════ --%>
<div id="editModal" class="modal-overlay hidden z-[80] flex items-start justify-center p-4 pt-10 overflow-y-auto">
  <div class="modal-box relative w-full max-w-[680px] z-10 my-8">
    <div class="modal-header">
      <div class="flex items-center gap-3">
        <div class="modal-icon bg-indigo-50 text-indigo-600">
          <span class="material-symbols-outlined text-[24px]">edit_square</span>
        </div>
        <div>
          <h3 class="text-base font-extrabold text-slate-900">Cập nhật mặt hàng</h3>
          <p class="text-xs text-slate-500 mt-0.5">Chỉnh sửa thông tin mặt hàng trong kho.</p>
        </div>
      </div>
      <button type="button" onclick="closeEditModal()" class="modal-close"><span class="material-symbols-outlined text-[20px]">close</span></button>
    </div>

    <form action="${pageContext.request.contextPath}/manager/kho-dich-vu" method="POST" enctype="multipart/form-data" class="px-8 py-6 flex flex-col gap-6">
      <input type="hidden" name="action" value="update">
      <input type="hidden" id="editSanPhamID" name="sanPhamID">

      <div>
        <p class="section-sep"><span class="material-symbols-outlined text-[15px] text-slate-400">info</span>Thông tin cơ bản</p>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="field-label">Mã SKU <span class="field-req">*</span></label>
            <input type="text" id="editSkuCode" name="skuCode" required class="form-input font-mono text-[13px]">
          </div>
          <div>
            <label class="field-label">Tên mặt hàng <span class="field-req">*</span></label>
            <input type="text" id="editTenSanPham" name="tenSanPham" maxlength="100" required class="form-input">
          </div>
          <div>
            <label class="field-label">Nhóm dịch vụ <span class="field-req">*</span></label>
            <select id="editDanhMucID" name="danhMucID" required class="form-select w-full">
              <c:forEach items="${categories}" var="cat">
                <option value="${cat.danhMucID}">${cat.tenDanhMuc}</option>
              </c:forEach>
            </select>
          </div>
          <div>
            <label class="field-label">Đơn vị tính <span class="field-req">*</span></label>
            <input type="text" id="editDonViTinh" name="donViTinh" required class="form-input">
          </div>
        </div>
      </div>

      <div>
        <p class="section-sep"><span class="material-symbols-outlined text-[15px] text-slate-400">payments</span>Giá &amp; Tồn kho</p>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label class="field-label">Giá nhập (đ) <span class="field-req">*</span></label>
            <input type="number" step="any" id="editGiaNhap" name="giaNhap" min="0" required class="form-input">
          </div>
          <div>
            <label class="field-label">Giá bán lẻ (đ) <span class="field-req">*</span></label>
            <input type="number" step="any" id="editDonGia" name="donGia" min="0" required class="form-input">
          </div>
          <div>
            <label class="field-label">Tồn kho <span class="field-req">*</span></label>
            <input type="number" id="editSoLuongTon" name="soLuongTon" min="0" required class="form-input">
          </div>
        </div>
        <div class="mt-4">
          <label class="field-label">Trạng thái kinh doanh</label>
          <select id="editTrangThai" name="trangThai" class="form-select w-full">
            <option value="Đang kinh doanh">Đang kinh doanh</option>
            <option value="Tạm hết hàng">Tạm hết hàng</option>
            <option value="Ngừng kinh doanh">Ngừng kinh doanh</option>
          </select>
        </div>
      </div>

      <div>
        <label class="field-label">Mô tả mặt hàng</label>
        <input type="text" id="editMoTa" name="moTa" class="form-input">
      </div>
      <div>
        <label class="field-label">Ảnh sản phẩm</label>
        <div class="flex items-center gap-3">
          <div class="w-14 h-14 rounded-xl overflow-hidden bg-slate-100 border border-slate-200/60 shrink-0 flex items-center justify-center">
            <img id="editHinhAnhPreview" src="" alt="" class="w-full h-full object-cover" style="display:none;">
            <span id="editHinhAnhPlaceholder" class="material-symbols-outlined text-[22px] text-slate-300">image</span>
          </div>
          <div class="flex-1">
            <input type="file" name="hinhAnhFile" accept="image/jpeg,image/png,image/webp,image/gif" class="form-input">
            <p class="text-[11px] text-slate-400 mt-1">Chọn ảnh mới để thay thế. Để trống nếu giữ ảnh hiện tại.</p>
          </div>
        </div>
      </div>

      <div class="flex justify-end gap-2.5 pt-4 border-t border-slate-100 mt-2">
        <button type="button" onclick="closeEditModal()" class="btn-ghost text-sm">Hủy</button>
        <button type="submit" class="btn-primary text-sm" style="background:#4f46e5; box-shadow:0 4px 12px -2px rgba(79, 70, 229, 0.3)"><span class="material-symbols-outlined text-[18px]">save</span>Lưu thay đổi</button>
      </div>
    </form>
  </div>
</div>

<%-- ═══════════════════════════════════════════
     MODAL 3: NHẬP / XUẤT KHO
════════════════════════════════════════════ --%>
<div id="stockModal" class="modal-overlay hidden z-[80] flex items-center justify-center p-4">
  <div class="modal-box relative w-full max-w-[420px] z-10">
    <div class="modal-header">
      <div class="flex items-center gap-3">
        <div class="modal-icon bg-slate-100 text-slate-600">
          <span class="material-symbols-outlined text-[24px]">published_with_changes</span>
        </div>
        <div>
          <h3 class="text-base font-extrabold text-slate-900">Nhập kho</h3>
          <p class="text-xs text-slate-500 mt-0.5">Nhập thêm số lượng tồn kho.</p>
        </div>
      </div>
      <button type="button" onclick="closeStockModal()" class="modal-close"><span class="material-symbols-outlined text-[20px]">close</span></button>
    </div>

    <div class="px-6 py-4 bg-slate-50 border-b border-slate-100">
      <p class="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-1">Mặt hàng được chọn</p>
      <p class="font-extrabold text-slate-800 text-sm" id="stockProdName">—</p>
      <div class="flex gap-4 mt-2 text-xs text-slate-500">
        <span>Mã SKU: <span class="font-mono font-bold text-slate-700 bg-white border border-slate-200 px-1.5 py-0.5 rounded" id="stockProdSku">—</span></span>
        <span>Tồn hiện tại: <span class="font-bold text-violet-700 bg-white border border-slate-200 px-1.5 py-0.5 rounded" id="stockProdQty">—</span> <span id="stockProdUnit" class="text-slate-400"></span></span>
      </div>
    </div>

    <div class="px-6 py-5">
      <form action="${pageContext.request.contextPath}/manager/kho-dich-vu" method="POST" class="flex flex-col gap-4">
        <input type="hidden" name="action" value="nhap-kho">
        <input type="hidden" name="id" id="stockProdId">
        <div>
          <label class="field-label">Số lượng cần nhập thêm <span class="field-req">*</span></label>
          <input type="number" name="amount" min="1" required placeholder="Nhập số lượng..." class="form-input font-bold text-sm">
        </div>
        <div>
          <label class="field-label">Ghi chú điều chỉnh</label>
          <input type="text" name="note" placeholder="Lý do điều chỉnh..." class="form-input">
        </div>
        <div class="flex justify-end gap-2.5 pt-4 border-t border-slate-100 mt-2">
          <button type="button" onclick="closeStockModal()" class="btn-ghost text-sm">Hủy</button>
          <button type="submit" id="btnStockSubmit" class="btn-primary text-sm">Xác nhận nhập kho</button>
        </div>
      </form>
    </div>
  </div>
</div>

<%-- ═══════════════════════════════════════════
     MODAL 4: QUẢN LÝ NHÓM DỊCH VỤ
════════════════════════════════════════════ --%>
<div id="categoryModal" class="modal-overlay hidden z-[80] flex items-center justify-center p-4">
  <div class="modal-box relative w-full max-w-[440px] z-10">
    <div class="modal-header">
      <div class="flex items-center gap-3">
        <div class="modal-icon bg-slate-100 text-slate-600">
          <span class="material-symbols-outlined text-[24px]">category</span>
        </div>
        <div>
          <h3 class="text-base font-extrabold text-slate-900">Quản lý nhóm dịch vụ</h3>
          <p class="text-xs text-slate-500 mt-0.5">Tạo nhóm như Đồ uống, Thuê dụng cụ, Đồ ăn.</p>
        </div>
      </div>
      <button onclick="closeCategoryModal()" class="modal-close"><span class="material-symbols-outlined text-[20px]">close</span></button>
    </div>

    <div class="px-6 py-5 flex flex-col gap-4">
      <div>
        <p class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2.5">Nhóm dịch vụ hiện tại</p>
        <div class="flex flex-col gap-2 max-h-52 overflow-y-auto pr-1">
          <c:choose>
            <c:when test="${empty categories}">
              <div class="bg-slate-50 border border-dashed border-slate-200 rounded-xl p-6 text-center">
                <span class="material-symbols-outlined text-[28px] text-slate-300">category</span>
                <p class="text-xs text-slate-400 mt-1">Chưa có nhóm dịch vụ nào.</p>
              </div>
            </c:when>
            <c:otherwise>
              <c:forEach items="${categories}" var="cat">
                <div class="flex items-center gap-3 px-3 py-2 bg-white rounded-xl border border-slate-100 hover:border-slate-200 hover:bg-slate-50/30 transition-colors shadow-2xs">
                  <div class="w-8 h-8 rounded-lg bg-violet-50 text-violet-600 flex items-center justify-center shrink-0">
                    <span class="material-symbols-outlined text-[16px]">label</span>
                  </div>
                  <span class="text-sm font-bold text-slate-800 flex-1 truncate">${cat.tenDanhMuc}</span>
                  <div class="flex items-center gap-1 shrink-0">
                    <button type="button" onclick="editCategory(${cat.danhMucID}, '${cat.tenDanhMuc}')" title="Sửa nhóm" class="w-7 h-7 rounded hover:bg-slate-100 text-slate-500 hover:text-slate-700 flex items-center justify-center transition-colors">
                      <span class="material-symbols-outlined text-[15px]">edit</span>
                    </button>
                    <button type="button" onclick="deleteCategory(${cat.danhMucID}, '${cat.tenDanhMuc}')" title="Xóa nhóm" class="w-7 h-7 rounded hover:bg-rose-50 text-rose-500 flex items-center justify-center transition-colors">
                      <span class="material-symbols-outlined text-[15px]">delete</span>
                    </button>
                  </div>
                </div>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

      <div class="border-t border-slate-100 pt-4">
        <p class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2.5">Thêm nhóm mới</p>
        <form action="${pageContext.request.contextPath}/manager/kho-dich-vu" method="POST" onsubmit="return handleAddCategory(event)" class="flex gap-2">
          <input type="hidden" name="action" value="add-category">
          <input type="text" name="tenDanhMuc" id="newCatName" required placeholder="VD: Đồ uống" class="form-input flex-1">
          <button type="submit" class="btn-secondary text-sm shrink-0"><span class="material-symbols-outlined text-[18px]">add</span>Thêm</button>
        </form>
      </div>
    </div>
  </div>
</div>

<%-- ═══════════════════════════════════════════
     MODAL 5: THÊM NHANH TỪ MẪU CÓ SẴN
════════════════════════════════════════════ --%>
<div id="presetModal" class="modal-overlay hidden z-[80] flex items-start justify-center p-4 pt-8 overflow-y-auto">
  <div class="modal-box relative w-full max-w-[700px] z-10 flex flex-col max-h-[90vh] my-4 shadow-2xl">
    <div class="modal-header shrink-0">
      <div class="flex items-center gap-3">
        <div class="modal-icon bg-amber-50 text-amber-600">
          <span class="material-symbols-outlined text-[24px]">bolt</span>
        </div>
        <div>
          <h3 class="text-base font-extrabold text-slate-900">Thêm nhanh từ mẫu có sẵn</h3>
          <p class="text-xs text-slate-500 mt-0.5">Chọn các mặt hàng thường bán tại sân để thêm nhanh vào kho.</p>
        </div>
      </div>
      <button type="button" onclick="closePresetModal()" class="modal-close"><span class="material-symbols-outlined text-[20px]">close</span></button>
    </div>

    <form action="${pageContext.request.contextPath}/manager/kho-dich-vu" method="POST" class="flex flex-col flex-1 min-h-0">
      <input type="hidden" name="action" value="add-presets">

      <div class="flex items-center gap-2 px-6 py-3 bg-amber-50/50 border-b border-amber-100/60 shrink-0 text-amber-800 text-[12.5px] font-medium">
        <span class="material-symbols-outlined text-[18px]">info</span>
        <span>Bạn có thể chỉnh lại giá bán và số lượng tồn kho sau khi thêm.</span>
      </div>

      <div class="overflow-y-auto flex-1 px-6 py-5 flex flex-col gap-6">
        <%-- Đồ uống --%>
        <div>
          <p class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-3 flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[16px] text-blue-500">local_cafe</span>Đồ uống
          </p>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div class="preset-card" onclick="handlePresetCardClick(this, event)">
              <input type="checkbox" class="preset-checkbox w-4 h-4 accent-violet-600 rounded shrink-0" onchange="togglePresetRow(this)" onclick="event.stopPropagation()">
              <div class="flex-1 min-w-0">
                <p class="font-bold text-slate-800 text-[13px] truncate">Aquafina 500ml</p>
                <p class="text-[10px] text-slate-400 mt-0.5">Nước uống · chai</p>
              </div>
              <div class="text-right shrink-0">
                <p class="text-[9px] text-slate-400">Gợi ý</p>
                <p class="font-extrabold text-slate-800 text-[12.5px] mt-0.5">10.000đ</p>
              </div>
              <input type="hidden" name="presetNames" value="Nước tinh khiết Aquafina 500ml">
              <input type="hidden" name="presetCatNames" value="Nước uống">
              <input type="hidden" name="presetUnits" value="chai">
              <input type="hidden" name="presetGiaNhaps" value="5000">
              <input type="hidden" name="presetDonGias" value="10000">
              <input type="hidden" name="presetStocks" class="preset-stock-input" value="0">
            </div>

            <div class="preset-card" onclick="handlePresetCardClick(this, event)">
              <input type="checkbox" class="preset-checkbox w-4 h-4 accent-violet-600 rounded shrink-0" onchange="togglePresetRow(this)" onclick="event.stopPropagation()">
              <div class="flex-1 min-w-0">
                <p class="font-bold text-slate-800 text-[13px] truncate">Coca-Cola lon</p>
                <p class="text-[10px] text-slate-400 mt-0.5">Nước uống · lon</p>
              </div>
              <div class="text-right shrink-0">
                <p class="text-[9px] text-slate-400">Gợi ý</p>
                <p class="font-extrabold text-slate-800 text-[12.5px] mt-0.5">12.000đ</p>
              </div>
              <input type="hidden" name="presetNames" value="Nước ngọt Coca-Cola lon">
              <input type="hidden" name="presetCatNames" value="Nước uống">
              <input type="hidden" name="presetUnits" value="lon">
              <input type="hidden" name="presetGiaNhaps" value="8000">
              <input type="hidden" name="presetDonGias" value="12000">
              <input type="hidden" name="presetStocks" class="preset-stock-input" value="0">
            </div>

            <div class="preset-card" onclick="handlePresetCardClick(this, event)">
              <input type="checkbox" class="preset-checkbox w-4 h-4 accent-violet-600 rounded shrink-0" onchange="togglePresetRow(this)" onclick="event.stopPropagation()">
              <div class="flex-1 min-w-0">
                <p class="font-bold text-slate-800 text-[13px] truncate">Trà xanh Không Độ</p>
                <p class="text-[10px] text-slate-400 mt-0.5">Nước uống · chai</p>
              </div>
              <div class="text-right shrink-0">
                <p class="text-[9px] text-slate-400">Gợi ý</p>
                <p class="font-extrabold text-slate-800 text-[12.5px] mt-0.5">12.000đ</p>
              </div>
              <input type="hidden" name="presetNames" value="Trà xanh Không Độ chai">
              <input type="hidden" name="presetCatNames" value="Nước uống">
              <input type="hidden" name="presetUnits" value="chai">
              <input type="hidden" name="presetGiaNhaps" value="8000">
              <input type="hidden" name="presetDonGias" value="12000">
              <input type="hidden" name="presetStocks" class="preset-stock-input" value="0">
            </div>

            <div class="preset-card" onclick="handlePresetCardClick(this, event)">
              <input type="checkbox" class="preset-checkbox w-4 h-4 accent-violet-600 rounded shrink-0" onchange="togglePresetRow(this)" onclick="event.stopPropagation()">
              <div class="flex-1 min-w-0">
                <p class="font-bold text-slate-800 text-[13px] truncate">Revive 500ml</p>
                <p class="text-[10px] text-slate-400 mt-0.5">Nước uống · chai</p>
              </div>
              <div class="text-right shrink-0">
                <p class="text-[9px] text-slate-400">Gợi ý</p>
                <p class="font-extrabold text-slate-800 text-[12.5px] mt-0.5">12.000đ</p>
              </div>
              <input type="hidden" name="presetNames" value="Nước bù khoáng Revive 500ml">
              <input type="hidden" name="presetCatNames" value="Nước uống">
              <input type="hidden" name="presetUnits" value="chai">
              <input type="hidden" name="presetGiaNhaps" value="8000">
              <input type="hidden" name="presetDonGias" value="12000">
              <input type="hidden" name="presetStocks" class="preset-stock-input" value="0">
            </div>
          </div>
        </div>

        <%-- Thuê dụng cụ --%>
        <div>
          <p class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-3 flex items-center gap-1.5 border-t border-slate-100 pt-4">
            <span class="material-symbols-outlined text-[16px] text-violet-500">sports_tennis</span>Thuê dụng cụ
          </p>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div class="preset-card" onclick="handlePresetCardClick(this, event)">
              <input type="checkbox" class="preset-checkbox w-4 h-4 accent-violet-600 rounded shrink-0" onchange="togglePresetRow(this)" onclick="event.stopPropagation()">
              <div class="flex-1 min-w-0">
                <p class="font-bold text-slate-800 text-[13px] truncate">Thuê vợt cầu lông Yonex</p>
                <p class="text-[10px] text-slate-400 mt-0.5">Thuê dụng cụ · lượt</p>
              </div>
              <div class="text-right shrink-0">
                <p class="text-[9px] text-slate-400">Gợi ý</p>
                <p class="font-extrabold text-slate-800 text-[12.5px] mt-0.5">30.000đ</p>
              </div>
              <input type="hidden" name="presetNames" value="Thuê vợt cầu lông Yonex">
              <input type="hidden" name="presetCatNames" value="Thuê dụng cụ">
              <input type="hidden" name="presetUnits" value="lượt">
              <input type="hidden" name="presetGiaNhaps" value="0">
              <input type="hidden" name="presetDonGias" value="30000">
              <input type="hidden" name="presetStocks" class="preset-stock-input" value="0">
            </div>

            <div class="preset-card" onclick="handlePresetCardClick(this, event)">
              <input type="checkbox" class="preset-checkbox w-4 h-4 accent-violet-600 rounded shrink-0" onchange="togglePresetRow(this)" onclick="event.stopPropagation()">
              <div class="flex-1 min-w-0">
                <p class="font-bold text-slate-800 text-[13px] truncate">Thuê quả bóng đá size 5</p>
                <p class="text-[10px] text-slate-400 mt-0.5">Thuê dụng cụ · lượt</p>
              </div>
              <div class="text-right shrink-0">
                <p class="text-[9px] text-slate-400">Gợi ý</p>
                <p class="font-extrabold text-slate-800 text-[12.5px] mt-0.5">40.000đ</p>
              </div>
              <input type="hidden" name="presetNames" value="Thuê quả bóng đá size 5">
              <input type="hidden" name="presetCatNames" value="Thuê dụng cụ">
              <input type="hidden" name="presetUnits" value="lượt">
              <input type="hidden" name="presetGiaNhaps" value="0">
              <input type="hidden" name="presetDonGias" value="40000">
              <input type="hidden" name="presetStocks" class="preset-stock-input" value="0">
            </div>

            <div class="preset-card" onclick="handlePresetCardClick(this, event)">
              <input type="checkbox" class="preset-checkbox w-4 h-4 accent-violet-600 rounded shrink-0" onchange="togglePresetRow(this)" onclick="event.stopPropagation()">
              <div class="flex-1 min-w-0">
                <p class="font-bold text-slate-800 text-[13px] truncate">Thuê giày thể thao</p>
                <p class="text-[10px] text-slate-400 mt-0.5">Thuê dụng cụ · đôi</p>
              </div>
              <div class="text-right shrink-0">
                <p class="text-[9px] text-slate-400">Gợi ý</p>
                <p class="font-extrabold text-slate-800 text-[12.5px] mt-0.5">25.000đ</p>
              </div>
              <input type="hidden" name="presetNames" value="Thuê giày thể thao cơ bản">
              <input type="hidden" name="presetCatNames" value="Thuê dụng cụ">
              <input type="hidden" name="presetUnits" value="đôi">
              <input type="hidden" name="presetGiaNhaps" value="0">
              <input type="hidden" name="presetDonGias" value="25000">
              <input type="hidden" name="presetStocks" class="preset-stock-input" value="0">
            </div>

            <div class="preset-card" onclick="handlePresetCardClick(this, event)">
              <input type="checkbox" class="preset-checkbox w-4 h-4 accent-violet-600 rounded shrink-0" onchange="togglePresetRow(this)" onclick="event.stopPropagation()">
              <div class="flex-1 min-w-0">
                <p class="font-bold text-slate-800 text-[13px] truncate">Thuê áo tập / áo bib</p>
                <p class="text-[10px] text-slate-400 mt-0.5">Thuê dụng cụ · bộ</p>
              </div>
              <div class="text-right shrink-0">
                <p class="text-[9px] text-slate-400">Gợi ý</p>
                <p class="font-extrabold text-slate-800 text-[12.5px] mt-0.5">10.000đ</p>
              </div>
              <input type="hidden" name="presetNames" value="Thuê áo tập / áo bib đấu">
              <input type="hidden" name="presetCatNames" value="Thuê dụng cụ">
              <input type="hidden" name="presetUnits" value="bộ">
              <input type="hidden" name="presetGiaNhaps" value="0">
              <input type="hidden" name="presetDonGias" value="10000">
              <input type="hidden" name="presetStocks" class="preset-stock-input" value="0">
            </div>
          </div>
        </div>

        <%-- Dịch vụ khác --%>
        <div>
          <p class="text-xs font-bold text-slate-400 uppercase tracking-widest mb-3 flex items-center gap-1.5 border-t border-slate-100 pt-4">
            <span class="material-symbols-outlined text-[16px] text-slate-500">more_horiz</span>Dịch vụ khác
          </p>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div class="preset-card" onclick="handlePresetCardClick(this, event)">
              <input type="checkbox" class="preset-checkbox w-4 h-4 accent-violet-600 rounded shrink-0" onchange="togglePresetRow(this)" onclick="event.stopPropagation()">
              <div class="flex-1 min-w-0">
                <p class="font-bold text-slate-800 text-[13px] truncate">Khăn lạnh lau mặt</p>
                <p class="text-[10px] text-slate-400 mt-0.5">Dịch vụ khác · cái</p>
              </div>
              <div class="text-right shrink-0">
                <p class="text-[9px] text-slate-400">Gợi ý</p>
                <p class="font-extrabold text-slate-800 text-[12.5px] mt-0.5">5.000đ</p>
              </div>
              <input type="hidden" name="presetNames" value="Khăn lạnh lau mặt">
              <input type="hidden" name="presetCatNames" value="Dịch vụ khác">
              <input type="hidden" name="presetUnits" value="cái">
              <input type="hidden" name="presetGiaNhaps" value="1500">
              <input type="hidden" name="presetDonGias" value="5000">
              <input type="hidden" name="presetStocks" class="preset-stock-input" value="0">
            </div>

            <div class="preset-card" onclick="handlePresetCardClick(this, event)">
              <input type="checkbox" class="preset-checkbox w-4 h-4 accent-violet-600 rounded shrink-0" onchange="togglePresetRow(this)" onclick="event.stopPropagation()">
              <div class="flex-1 min-w-0">
                <p class="font-bold text-slate-800 text-[13px] truncate">Phí gửi xe máy/ô tô</p>
                <p class="text-[10px] text-slate-400 mt-0.5">Dịch vụ khác · lượt</p>
              </div>
              <div class="text-right shrink-0">
                <p class="text-[9px] text-slate-400">Gợi ý</p>
                <p class="font-extrabold text-slate-800 text-[12.5px] mt-0.5">5.000đ</p>
              </div>
              <input type="hidden" name="presetNames" value="Phí gửi xe máy/ô tô">
              <input type="hidden" name="presetCatNames" value="Dịch vụ khác">
              <input type="hidden" name="presetUnits" value="lượt">
              <input type="hidden" name="presetGiaNhaps" value="0">
              <input type="hidden" name="presetDonGias" value="5000">
              <input type="hidden" name="presetStocks" class="preset-stock-input" value="0">
            </div>

            <div class="preset-card" onclick="handlePresetCardClick(this, event)">
              <input type="checkbox" class="preset-checkbox w-4 h-4 accent-violet-600 rounded shrink-0" onchange="togglePresetRow(this)" onclick="event.stopPropagation()">
              <div class="flex-1 min-w-0">
                <p class="font-bold text-slate-800 text-[13px] truncate">Phụ thu tiền điện</p>
                <p class="text-[10px] text-slate-400 mt-0.5">Dịch vụ khác · ca</p>
              </div>
              <div class="text-right shrink-0">
                <p class="text-[9px] text-slate-400">Gợi ý</p>
                <p class="font-extrabold text-slate-800 text-[12.5px] mt-0.5">50.000đ</p>
              </div>
              <input type="hidden" name="presetNames" value="Phụ thu tiền điện chiếu sáng">
              <input type="hidden" name="presetCatNames" value="Dịch vụ khác">
              <input type="hidden" name="presetUnits" value="ca">
              <input type="hidden" name="presetGiaNhaps" value="0">
              <input type="hidden" name="presetDonGias" value="50000">
              <input type="hidden" name="presetStocks" class="preset-stock-input" value="0">
            </div>
          </div>
        </div>
      </div>

      <div class="px-6 py-4 bg-slate-50 border-t border-slate-100 flex justify-end gap-2.5 shrink-0 rounded-b-2xl">
        <button type="button" onclick="closePresetModal()" class="btn-ghost text-sm">Hủy</button>
        <button type="submit" id="presetSubmitBtn" disabled class="btn-primary text-sm opacity-50 cursor-not-allowed">
          <span class="material-symbols-outlined text-[18px]">add_circle</span>Thêm các mẫu đã chọn
        </button>
      </div>
    </form>
  </div>
</div>

<script>
  // Mobile menu
  document.getElementById('mobileMenuBtn')?.addEventListener('click', () => {
    document.getElementById('sidebar').classList.toggle('-translate-x-full');
  });

  // SKU generator
  function generateRandomSku() {
    const c = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let r = '';
    for (let i = 0; i < 6; i++) r += c.charAt(Math.floor(Math.random() * c.length));
    return 'SKU-' + r;
  }
  function regenerateAddSku() { document.getElementById('addSkuCode').value = generateRandomSku(); }

  // ── Add Modal ──
  function openAddModal() {
    document.getElementById('addModal').classList.remove('hidden');
    document.getElementById('addModal').classList.add('flex');
    regenerateAddSku();
  }
  function closeAddModal() {
    document.getElementById('addModal').classList.add('hidden');
    document.getElementById('addModal').classList.remove('flex');
  }

  // ── Detail Modal (read-only) ──
  const PRODUCT_CATEGORIES = {
    <c:forEach items="${categories}" var="cat" varStatus="catSt">"${cat.danhMucID}": "${fn:escapeXml(cat.tenDanhMuc)}"<c:if test="${!catSt.last}">,</c:if></c:forEach>
  };
  function formatMoney(v) {
    const n = Number(v) || 0;
    return n.toLocaleString('vi-VN') + 'đ';
  }
  function openDetailModal(id, sku, name, catId, donGia, giaNhap, unit, stock, status, desc) {
    document.getElementById('detailSku').innerText = (sku && sku !== 'null') ? sku : 'N/A';
    document.getElementById('detailName').innerText = name;
    document.getElementById('detailCategory').innerText = PRODUCT_CATEGORIES[catId] || '-';
    document.getElementById('detailStatus').innerText = status;
    document.getElementById('detailGiaNhap').innerText = formatMoney(giaNhap);
    document.getElementById('detailGiaBan').innerText = formatMoney(donGia);
    document.getElementById('detailStock').innerText = stock + ' ' + (unit && unit !== 'null' ? unit : 'cái');
    document.getElementById('detailDesc').innerText = (desc && desc !== 'null' && desc.trim()) ? desc : 'Không có mô tả.';
    document.getElementById('detailModal').classList.remove('hidden');
    document.getElementById('detailModal').classList.add('flex');
  }
  function closeDetailModal() {
    document.getElementById('detailModal').classList.add('hidden');
    document.getElementById('detailModal').classList.remove('flex');
  }

  // ── Edit Modal ──
  function openEditModal(id, sku, name, catId, donGia, giaNhap, unit, stock, status, desc, hinhAnh) {
    document.getElementById('editSanPhamID').value = id;
    document.getElementById('editSkuCode').value = sku;
    document.getElementById('editTenSanPham').value = name;
    document.getElementById('editDanhMucID').value = catId;
    document.getElementById('editDonGia').value = donGia;
    document.getElementById('editGiaNhap').value = giaNhap;
    document.getElementById('editDonViTinh').value = unit;
    document.getElementById('editSoLuongTon').value = stock;
    document.getElementById('editTrangThai').value = status;
    document.getElementById('editMoTa').value = desc === 'null' ? '' : desc;

    var preview = document.getElementById('editHinhAnhPreview');
    var placeholder = document.getElementById('editHinhAnhPlaceholder');
    if (hinhAnh && hinhAnh !== 'null' && hinhAnh.trim() !== '') {
      preview.src = '${pageContext.request.contextPath}' + hinhAnh;
      preview.style.display = 'block';
      placeholder.style.display = 'none';
    } else {
      preview.src = '';
      preview.style.display = 'none';
      placeholder.style.display = 'block';
    }

    document.getElementById('editModal').classList.remove('hidden');
    document.getElementById('editModal').classList.add('flex');
  }
  function closeEditModal() {
    document.getElementById('editModal').classList.add('hidden');
    document.getElementById('editModal').classList.remove('flex');
  }

  // ── Stock Modal ──
  function openStockModal(id, sku, name, currentStock, unit) {
    document.getElementById('stockProdId').value = id;
    document.getElementById('stockProdSku').innerText = sku;
    document.getElementById('stockProdName').innerText = name;
    document.getElementById('stockProdQty').innerText = currentStock;
    document.getElementById('stockProdUnit').innerText = unit || 'cái';
    document.getElementById('stockModal').classList.remove('hidden');
    document.getElementById('stockModal').classList.add('flex');
  }
  function closeStockModal() {
    document.getElementById('stockModal').classList.add('hidden');
    document.getElementById('stockModal').classList.remove('flex');
  }

  // ── Category Modal ──
  const existingCategories = [
    <c:forEach items="${categories}" var="cat" varStatus="loop">
      '${cat.tenDanhMuc.trim().toLowerCase()}'${!loop.last ? ',' : ''}
    </c:forEach>
  ];
  function handleAddCategory(event) {
    const input = event.target.querySelector('input[name="tenDanhMuc"]');
    const catName = input.value.trim().toLowerCase();
    if (existingCategories.includes(catName)) { alert('Nhóm "' + input.value.trim() + '" đã tồn tại!'); return false; }
    return true;
  }
  function openCategoryModal() {
    document.getElementById('categoryModal').classList.remove('hidden');
    document.getElementById('categoryModal').classList.add('flex');
  }
  function closeCategoryModal() {
    document.getElementById('categoryModal').classList.add('hidden');
    document.getElementById('categoryModal').classList.remove('flex');
  }

  // ── Preset Modal ──
  function handlePresetCardClick(card, event) {
    if (event.target.type === 'checkbox') return;
    const checkbox = card.querySelector('.preset-checkbox');
    checkbox.checked = !checkbox.checked;
    togglePresetRow(checkbox);
  }
  function togglePresetRow(checkbox) {
    const card = checkbox.closest('.preset-card');
    const stockHidden = card.querySelector('.preset-stock-input');
    const name = card.querySelector('input[name="presetNames"]').value;
    if (checkbox.checked) {
      stockHidden.value = name.includes('Phí gửi') || name.includes('Phụ thu') ? '1' : name.includes('Thuê') ? '5' : '10';
      card.classList.add('active');
    } else {
      stockHidden.value = '0';
      card.classList.remove('active');
    }
    validatePresetSelection();
  }
  function validatePresetSelection() {
    const checkboxes = document.querySelectorAll('.preset-checkbox');
    const submitBtn = document.getElementById('presetSubmitBtn');
    let anyChecked = false;
    checkboxes.forEach(cb => { if (cb.checked) anyChecked = true; });
    submitBtn.disabled = !anyChecked;
    submitBtn.classList.toggle('opacity-50', !anyChecked);
    submitBtn.classList.toggle('cursor-not-allowed', !anyChecked);
    submitBtn.classList.toggle('cursor-pointer', anyChecked);
  }
  function openPresetModal() {
    document.querySelectorAll('.preset-checkbox').forEach(cb => {
      cb.checked = false;
      cb.closest('.preset-card').classList.remove('active');
    });
    document.querySelectorAll('.preset-stock-input').forEach(i => i.value = 0);
    validatePresetSelection();
    document.getElementById('presetModal').classList.remove('hidden');
    document.getElementById('presetModal').classList.add('flex');
  }
  function closePresetModal() {
    document.getElementById('presetModal').classList.add('hidden');
    document.getElementById('presetModal').classList.remove('flex');
  }

  // ── Delete ──
  function confirmDelete(id, name) {
    showCustomConfirm("Bạn có chắc chắn muốn xóa sản phẩm/dịch vụ '" + name + "'? Sản phẩm sẽ được chuyển vào Thùng rác.", () => {
      showToast("Đang xóa... Bạn có thể vào Thùng rác để khôi phục.", "success");
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = '${pageContext.request.contextPath}/manager/kho-dich-vu';
      const a = document.createElement('input'); a.type='hidden'; a.name='action'; a.value='delete'; form.appendChild(a);
      const b = document.createElement('input'); b.type='hidden'; b.name='id'; b.value=id; form.appendChild(b);
      document.body.appendChild(form);
      setTimeout(() => form.submit(), 1200);
    });
  }

  function editCategory(id, currentName) {
    const newName = prompt("Nhập tên mới cho nhóm dịch vụ '" + currentName + "':", currentName);
    if (newName === null) return;
    const trimmed = newName.trim();
    if (trimmed === "") {
      showToast("Tên nhóm dịch vụ không được để trống!", "error");
      return;
    }
    if (trimmed.toLowerCase() === currentName.toLowerCase()) {
      return;
    }
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = '${pageContext.request.contextPath}/manager/kho-dich-vu';
    const a = document.createElement('input'); a.type='hidden'; a.name='action'; a.value='update-category'; form.appendChild(a);
    const b = document.createElement('input'); b.type='hidden'; b.name='danhMucID'; b.value=id; form.appendChild(b);
    const c = document.createElement('input'); c.type='hidden'; c.name='tenDanhMuc'; c.value=trimmed; form.appendChild(c);
    document.body.appendChild(form);
    form.submit();
  }

  function deleteCategory(id, name) {
    showCustomConfirm("Bạn có chắc chắn muốn xóa nhóm dịch vụ '" + name + "'? Thao tác này không thể khôi phục.", () => {
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = '${pageContext.request.contextPath}/manager/kho-dich-vu';
      const a = document.createElement('input'); a.type='hidden'; a.name='action'; a.value='delete-category'; form.appendChild(a);
      const b = document.createElement('input'); b.type='hidden'; b.name='danhMucID'; b.value=id; form.appendChild(b);
      document.body.appendChild(form);
      form.submit();
    });
  }

  // Scroll reveal
  document.addEventListener('DOMContentLoaded', () => {
    const obs = new IntersectionObserver((entries) => {
      entries.forEach((entry, i) => {
        if (entry.isIntersecting) { setTimeout(() => entry.target.classList.add('revealed'), i * 40); obs.unobserve(entry.target); }
      });
    }, { threshold: 0.05, rootMargin: '0px 0px -10px 0px' });
    document.querySelectorAll('.reveal-on-scroll').forEach(el => obs.observe(el));
  });

  // bfcache reload
  window.addEventListener('pageshow', e => { if (e.persisted) window.location.reload(); });
</script>
</body>
</html>
