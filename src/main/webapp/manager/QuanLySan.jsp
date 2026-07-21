<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="vi">
<head>
<title>Quản lý sân chi nhánh — V-SPORT</title>
<jsp:include page="/manager/common/manager_head.jsp" />
</head>
<body class="text-zinc-900 min-h-screen">

<!-- Sidebar -->
<jsp:include page="/manager/common/sidebar.jsp" />

<!-- Header -->
<c:set var="headerTitle" value="Quản lý sân thi đấu" scope="page" />
<c:set var="headerSubtitle" value="Cơ sở CS${managerCoSoId}" scope="page" />
<c:set var="headerIcon" value="storefront" scope="page" />
<jsp:include page="/manager/common/header.jsp" />

<main class="lg:ml-[248px] mt-[64px] p-4 lg:p-6 flex flex-col gap-5">

  <!-- Header section -->
  <section class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
    <div>
      <h2 class="text-2xl font-black tracking-tight text-purple-950">Sân thi đấu chi nhánh</h2>
    </div>
    <div class="flex items-center gap-2">
      <button id="mainActionBtn" onclick="openCreateModal()" class="flex items-center gap-1.5 h-10 px-4 rounded-xl bg-purple-600 text-white text-sm font-semibold shadow-md shadow-purple-200 hover:bg-purple-700">
        <span class="material-symbols-outlined text-[16px]">add</span>Thêm sân mới
      </button>
    </div>
  </section>

  <!-- Navigation Tabs -->
  <section class="flex border-b border-purple-100 gap-6">
    <button id="btnTabCourts" onclick="switchTab('courts')" class="pb-3 text-sm font-bold border-b-2 border-purple-600 text-purple-600 flex items-center gap-2 transition-all">
      <span class="material-symbols-outlined text-[18px]">stadium</span>Danh sách sân thi đấu
    </button>
    <button id="btnTabTypes" onclick="switchTab('types')" class="pb-3 text-sm font-medium border-b-2 border-transparent text-purple-500 hover:text-purple-800 flex items-center gap-2 transition-all">
      <span class="material-symbols-outlined text-[18px]">payments</span>Cấu hình loại sân & Bảng giá
    </button>
  </section>

  <!-- Alert Messages -->
  <c:if test="${not empty sessionScope.error}">
    <div class="p-4 bg-red-50 border border-red-100 rounded-xl text-red-650 text-sm flex items-start gap-3 animate-fade-in-up shadow-sm">
      <span class="material-symbols-outlined text-[20px] shrink-0">error</span>
      <div>
        <span class="font-bold block text-red-700">Lỗi thực thi</span>
        <span class="text-red-650/95 leading-normal block mt-0.5">${sessionScope.error}</span>
      </div>
      <% session.removeAttribute("error"); %>
    </div>
  </c:if>
  <c:if test="${not empty sessionScope.message}">
    <div class="p-4 bg-purple-50 border border-purple-100 rounded-xl text-purple-700 text-sm flex items-start gap-3 animate-fade-in-up shadow-sm">
      <span class="material-symbols-outlined text-[20px] shrink-0">check_circle</span>
      <div>
        <span class="font-bold block text-purple-800">Thành công</span>
        <span class="text-purple-700/95 leading-normal block mt-0.5">${sessionScope.message}</span>
      </div>
      <% session.removeAttribute("message"); %>
    </div>
  </c:if>

  <!-- Stats Grid -->
  <section id="statsSection" class="grid grid-cols-2 sm:grid-cols-4 gap-3">
    <div class="card p-4 hover:shadow-md transition-shadow">
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 rounded-xl bg-purple-50 flex items-center justify-center"><span class="material-symbols-outlined text-[20px] text-purple-700">stadium</span></div>
        <div>
          <p class="text-[11px] text-zinc-500 font-medium">Tổng số sân</p>
          <p id="statTotal" class="text-2xl font-black text-purple-950">0</p>
        </div>
      </div>
    </div>
    <div class="card p-4 hover:shadow-md transition-shadow">
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 rounded-xl bg-green-50 flex items-center justify-center"><span class="material-symbols-outlined text-[20px] text-green-700">check_circle</span></div>
        <div>
          <p class="text-[11px] text-zinc-500 font-medium">Đang sẵn sàng</p>
          <p id="statReady" class="text-2xl font-black text-green-650">0</p>
        </div>
      </div>
    </div>
    <div class="card p-4 hover:shadow-md transition-shadow">
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 rounded-xl bg-amber-50 flex items-center justify-center"><span class="material-symbols-outlined text-[20px] text-amber-700">build</span></div>
        <div>
          <p class="text-[11px] text-zinc-500 font-medium">Đang bảo trì</p>
          <p id="statMaintenance" class="text-2xl font-black text-amber-600">0</p>
        </div>
      </div>
    </div>
    <div class="card p-4 hover:shadow-md transition-shadow">
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 rounded-xl bg-red-50 flex items-center justify-center"><span class="material-symbols-outlined text-[20px] text-red-600">block</span></div>
        <div>
          <p class="text-[11px] text-zinc-500 font-medium">Tạm đóng</p>
          <p id="statClosed" class="text-2xl font-black text-red-500">0</p>
        </div>
      </div>
    </div>
  </section>

  <!-- Toolbar Section -->
  <section id="toolbarSection" class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3">
    <div class="flex items-center gap-2 flex-wrap">
      <!-- View mode switch -->
      <div class="flex rounded-xl border border-purple-250 overflow-hidden bg-white">
        <button id="btnViewGrid" onclick="setViewMode('grid')" class="px-3 py-2 text-sm flex items-center gap-1.5 bg-purple-600 text-white font-semibold">
          <span class="material-symbols-outlined text-[15px]">grid_view</span>Lưới
        </button>
        <button id="btnViewList" onclick="setViewMode('list')" class="px-3 py-2 text-sm flex items-center gap-1.5 text-purple-600 hover:bg-purple-50">
          <span class="material-symbols-outlined text-[15px]">list</span>Danh sách
        </button>
      </div>
      <!-- Type Filter -->
      <select id="filterType" onchange="applyFilters()" class="h-10 pl-3 pr-8 rounded-xl border border-purple-200 bg-white text-sm text-purple-850 focus:outline-none focus:ring-2 focus:ring-purple-500/30">
        <option value="all">Tất cả môn thể thao</option>
      </select>
      <!-- Status Filter -->
      <select id="filterStatus" onchange="applyFilters()" class="h-10 pl-3 pr-8 rounded-xl border border-purple-200 bg-white text-sm text-purple-850 focus:outline-none focus:ring-2 focus:ring-purple-500/30">
        <option value="all">Tất cả trạng thái</option>
        <option value="Sẵn sàng">Sẵn sàng</option>
        <option value="Đang dùng">Đang dùng</option>
        <option value="Bảo trì">Bảo trì</option>
        <option value="Tạm đóng">Tạm đóng</option>
      </select>
    </div>
    <!-- Search Bar -->
    <div class="relative max-w-xs flex-1">
      <span class="absolute left-3 top-1/2 -translate-y-1/2 material-symbols-outlined text-[16px] text-purple-400">search</span>
      <input type="search" id="searchInput" autocomplete="off" oninput="applyFilters()" placeholder="Tìm sân theo tên..." class="h-10 w-full pl-9 pr-3 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400">
    </div>
  </section>

  <!-- Court List & Types Grid Layout Containers -->
  <section class="min-h-[400px]">
    <!-- Court Cards (Grid View) -->
    <div id="mainCourtGrid" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
      <!-- Generated Dynamically -->
    </div>

    <!-- Court Table (List View) - hidden by default -->
    <div id="mainCourtList" class="hidden card overflow-hidden bg-white border border-purple-200 shadow-sm rounded-2xl">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="border-b border-purple-200 text-xs font-bold text-purple-800 uppercase tracking-wider bg-purple-50/50">
              <th class="px-5 py-3.5">Tên sân</th>
              <th class="px-5 py-3.5">Loại sân / Bộ môn</th>
              <th class="px-5 py-3.5">Giá ngày / tối (giờ đèn)</th>
              <th class="px-5 py-3.5">Trạng thái</th>
              <th class="px-5 py-3.5 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody id="courtListTableBody" class="divide-y divide-purple-50 text-xs text-zinc-700">
            <!-- Generated Dynamically -->
          </tbody>
        </table>
      </div>
    </div>

    <!-- Pricing and Court Types View (Tab 2) - hidden by default -->
    <div id="pricingTypesView" class="hidden card overflow-hidden bg-white border border-purple-200 shadow-sm rounded-2xl">
      <div class="p-4 border-b border-purple-150 flex items-center justify-between">
        <div>
          <h3 class="text-sm font-bold text-purple-950 font-sans">Cấu hình Loại sân & Bảng giá giờ lên đèn</h3>
          <p class="text-[11px] text-purple-550">Điều chỉnh biểu phí giờ bật đèn riêng cho từng môn thể thao</p>
        </div>
        <button onclick="openCreateTypeModal()" class="flex items-center gap-1.5 h-8 px-3 rounded-lg bg-purple-600 hover:bg-purple-750 text-white text-[11px] font-bold transition-all shadow-sm">
          <span class="material-symbols-outlined text-[14px]">add</span>Thêm loại sân mới
        </button>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="border-b border-purple-200 text-xs font-bold text-purple-800 uppercase tracking-wider bg-purple-50/50">
              <th class="px-5 py-3.5">Mã Loại</th>
              <th class="px-5 py-3.5">Tên Loại Sân</th>
              <th class="px-5 py-3.5">Bộ môn</th>
              <th class="px-5 py-3.5">Giá không đèn (Tiêu chuẩn)</th>
              <th class="px-5 py-3.5">Giá tối (Có đèn)</th>
              <th class="px-5 py-3.5">Giờ bắt đầu lên đèn</th>
              <th class="px-5 py-3.5">Giờ kết thúc bật đèn</th>
              <th class="px-5 py-3.5 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody id="typeListTableBody" class="divide-y divide-purple-50 text-xs text-zinc-700">
            <!-- Generated Dynamically -->
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <!-- Empty State Placeholder -->
  <section id="emptyState" class="hidden flex-col items-center justify-center p-12 text-center bg-white rounded-3xl border border-dashed border-purple-200">
    <span class="material-symbols-outlined text-[48px] text-purple-300">stadium</span>
    <p class="text-sm font-bold text-purple-900 mt-2">Không tìm thấy sân thi đấu nào</p>
    <p class="text-xs text-purple-500 mt-0.5">Vui lòng điều chỉnh bộ lọc hoặc tạo thêm sân thi đấu mới.</p>
  </section>

</main>

<!-- Modal 1: Thêm/Sửa sân (`courtModal`) -->
<div id="courtModal" class="hidden fixed inset-0 z-[80] flex items-center justify-center p-4">
  <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" onclick="closeCourtModal()"></div>
  <div class="relative bg-white rounded-3xl shadow-2xl w-full max-w-[480px] max-h-[92vh] overflow-y-auto border border-purple-100">
    <div class="flex items-center justify-between px-6 py-4 border-b border-purple-50">
      <div>
        <h2 id="courtModalTitle" class="text-base font-bold text-purple-950 font-sans">Thêm sân mới</h2>
        <p id="courtModalSubtitle" class="text-xs text-purple-500 mt-0.5">Tạo sân thi đấu mới cho chi nhánh</p>
      </div>
      <button onclick="closeCourtModal()" class="p-1.5 rounded-lg hover:bg-purple-50"><span class="material-symbols-outlined text-[18px] text-zinc-500">close</span></button>
    </div>

    <!-- Banner: chưa có loại sân -->
    <div id="courtNoTypesBanner" class="hidden mx-6 mt-4 flex items-start gap-3 rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3">
      <span class="material-symbols-outlined text-[20px] text-amber-500 mt-0.5 shrink-0">warning</span>
      <div>
        <p class="text-sm font-semibold text-amber-800">Chưa có loại sân nào</p>
        <p class="text-xs text-amber-700 mt-0.5">Cần tạo ít nhất một loại sân trước khi thêm sân thi đấu.</p>
        <button type="button" onclick="closeCourtModal(); switchTab('types')"
                class="mt-2 text-xs font-bold text-amber-700 underline underline-offset-2">
          → Đến tab Cấu hình loại sân &amp; Bảng giá
        </button>
      </div>
    </div>

    <form id="courtForm" class="px-6 py-4 flex flex-col gap-4" method="POST" action="${pageContext.request.contextPath}/manager/quan-ly-san" enctype="multipart/form-data" novalidate>
      <input type="hidden" name="action" id="courtAction" value="add">
      <input type="hidden" name="sanID" id="courtEditId">
      <input type="hidden" name="existingHinhAnh" id="existingCourtImage" value="">

      <!-- Warning: Sân đang sử dụng -->
      <div id="courtOccupiedWarning" class="hidden p-3 bg-amber-50 border border-amber-200 text-amber-800 text-xs rounded-xl flex items-start gap-2">
        <span class="material-symbols-outlined text-[16px] shrink-0">warning</span>
        <span>Sân này đang có trận đấu diễn ra (Đang sử dụng/Đang dùng). Bạn không thể thay đổi tên, loại sân hoặc trạng thái lúc này.</span>
      </div>

      <!-- Tên sân -->
      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-semibold text-purple-900">Tên sân *</label>
        <input type="text" name="tenSan" id="courtName"
               placeholder="Tên hiển thị (VD: Sân Bóng Đá 1)"
               oninput="courtNameEdited = true; clearFieldError('courtName'); updateBulkNamePreview(); updateCardPreview()"
               class="h-10 px-3 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400 transition-colors">
        <span id="err-courtName" class="hidden text-[11px] text-red-500 font-medium flex items-center gap-1">
          <span class="material-symbols-outlined text-[13px]">error</span><span id="err-courtName-msg"></span>
        </span>
      </div>

      <!-- Loại sân + Trạng thái cùng hàng -->
      <div class="grid grid-cols-2 gap-3">
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-purple-900">Loại sân &amp; Bảng giá *</label>
          <select name="loaiSanID" id="courtTypeSelect"
                  onchange="onCourtTypeChange(); clearFieldError('courtTypeSelect')"
                  class="h-10 px-3 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400 transition-colors">
          </select>
          <span id="err-courtTypeSelect" class="hidden text-[11px] text-red-500 font-medium flex items-center gap-1">
            <span class="material-symbols-outlined text-[13px]">error</span><span id="err-courtTypeSelect-msg"></span>
          </span>
        </div>
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-purple-900">Trạng thái sân *</label>
          <select name="trangThai" id="courtStatus" onchange="updateCardPreview()"
                  class="h-10 px-3 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400">
            <!-- Populated by JS depending on create/edit mode -->
          </select>
        </div>
      </div>

      <!-- Mô tả -->
      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-semibold text-purple-900">Mô tả chi tiết</label>
        <textarea name="moTa" id="courtDesc" rows="3"
                  placeholder="Sân cỏ nhân tạo chất lượng cao, lưới bao đầy đủ..."
                  class="px-3 py-2 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400 resize-none"></textarea>
      </div>

      <!-- Ảnh sân -->
      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-semibold text-purple-900">
          Link ảnh sân <span class="font-normal text-zinc-400">(Tùy chọn)</span>
        </label>
        <input type="file" name="courtImageFile" id="courtImageFile"
               accept="image/png,image/jpeg,image/webp,image/gif"
               onchange="updateImagePreview(); updateCardPreview()"
               class="hidden">
        <div class="flex items-center gap-2">
          <button type="button" onclick="document.getElementById('courtImageFile').click()"
                  class="h-10 px-4 rounded-xl border border-purple-200 bg-white text-sm font-semibold text-purple-700 hover:bg-purple-50">
            Chọn ảnh từ máy
          </button>
          <button type="button" id="clearCourtImageBtn" onclick="clearCourtImageSelection()"
                  class="hidden h-10 px-3 rounded-xl border border-zinc-200 text-sm font-medium text-zinc-600 hover:bg-zinc-50">
            Bỏ ảnh
          </button>
        </div>
        <p id="courtImageFileName" class="text-[11px] text-zinc-500">Chưa chọn ảnh nào.</p>
        <div id="courtImagePreviewWrap" class="hidden relative rounded-xl overflow-hidden border border-purple-100 bg-zinc-50" style="height:130px">
          <img id="courtImagePreview" src="" alt="preview" class="w-full h-full object-cover"
               onload="document.getElementById('courtImageError').classList.add('hidden')"
               onerror="document.getElementById('courtImageError').classList.remove('hidden')">
          <div id="courtImageError" class="hidden absolute inset-0 flex items-center justify-center bg-red-50">
            <div class="flex flex-col items-center gap-1 text-red-400">
              <span class="material-symbols-outlined text-[28px]">broken_image</span>
              <span class="text-[11px] font-semibold">URL ảnh không hợp lệ</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Mini-card preview: sân sẽ hiển thị như thế nào -->
      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-semibold text-purple-900 flex items-center gap-1">
          <span class="material-symbols-outlined text-[14px]">visibility</span>Xem trước hiển thị
        </label>
        <div class="rounded-2xl border border-purple-100 overflow-hidden bg-white shadow-sm">
          <div class="relative h-24 bg-zinc-100">
            <img id="cardPrevImg" src="" alt="" class="w-full h-full object-cover">
            <span id="cardPrevStatus" class="absolute top-2 right-2 badge badge-green text-[10px]">Sẵn sàng</span>
            <span id="cardPrevSport" class="absolute bottom-2 left-2 bg-black/60 backdrop-blur-sm px-2 py-0.5 rounded text-[9px] font-bold text-white uppercase">—</span>
          </div>
          <div class="p-3">
            <h4 id="cardPrevName" class="font-bold text-purple-950 text-sm">Tên sân...</h4>
            <p id="cardPrevType" class="text-[10px] text-purple-500 font-semibold mt-0.5">Loại sân</p>
            <div class="flex items-center justify-between text-[11px] mt-1.5">
              <span id="cardPrevPrice" class="font-bold text-zinc-800">—</span>
              <span id="cardPrevLightHours" class="text-zinc-400 text-[10px]">—</span>
            </div>
          </div>
        </div>
      </div>

      <div class="flex justify-end gap-2 pt-3 border-t border-purple-50">
        <button type="button" onclick="closeCourtModal()" class="h-10 px-4 rounded-xl border border-purple-200 text-sm font-semibold text-purple-700 hover:bg-purple-50">Hủy</button>
        <button type="button" onclick="submitCourtForm()" id="saveCourtBtn"
                class="h-10 px-5 rounded-xl bg-purple-600 text-white text-sm font-semibold hover:bg-purple-700 shadow shadow-purple-200">Lưu lại</button>
      </div>
    </form>
  </div>
</div>

<!-- Modal 2: Thêm/Sửa loại sân & Bảng giá (`typeModal`) -->
<div id="typeModal" class="hidden fixed inset-0 z-[80] flex items-center justify-center p-4">
  <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" onclick="closeTypeModal()"></div>
  <div class="relative bg-white rounded-3xl shadow-2xl w-full max-w-[480px] max-h-[92vh] overflow-y-auto border border-purple-100">
    <div class="flex items-center justify-between px-6 py-4 border-b border-purple-50">
      <div>
        <h2 id="typeModalTitle" class="text-base font-bold text-purple-950 font-sans">Thêm loại sân mới</h2>
        <p class="text-xs text-purple-500 mt-0.5">Thiết lập bộ môn, bảng giá và giờ lên đèn cho chi nhánh</p>
      </div>
      <button onclick="closeTypeModal()" class="p-1.5 rounded-lg hover:bg-purple-50"><span class="material-symbols-outlined text-[18px] text-zinc-500">close</span></button>
    </div>
    <form id="typeForm" class="px-6 py-4 flex flex-col gap-4" method="POST" action="${pageContext.request.contextPath}/manager/quan-ly-san">
      <input type="hidden" name="action" id="typeAction" value="addType">
      <input type="hidden" name="loaiSanID" id="typeEditId">

      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-semibold text-purple-900">Môn thể thao *</label>
        <select name="monTheThaoID" id="typeSportSelect" required class="h-10 px-3 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400">
          <!-- Populated dynamically -->
        </select>
      </div>

      <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-purple-900">Tên loại hình sân *</label>
        <input type="text" name="tenLoai" id="typeName" required placeholder="VD: Sân cỏ nhân tạo 5 người" class="h-10 px-3 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400">
      </div>

      <!-- Hidden input gửi lên backend -->
      <input type="hidden" name="khongDungDen" id="typeKhongDungDenHidden" value="false">

      <!-- Checkbox: Sân không dùng đèn -->
      <label class="flex items-center gap-3 px-3 py-2.5 rounded-xl border border-purple-200 cursor-pointer hover:bg-purple-50/60 select-none transition-colors"
             title="Tích vào nếu sân dùng ánh sáng tự nhiên hoặc đã tính đèn vào giá — không phụ thu thêm buổi tối.">
        <input type="checkbox" id="typeNoLight" onchange="toggleTypeNoLight()" class="w-4 h-4 accent-purple-600 shrink-0">
        <span class="text-xs font-semibold text-purple-900">Sân không dùng đèn (không phụ thu buổi tối)</span>
      </label>

      <div class="grid grid-cols-2 gap-3">
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-purple-900">Giá ban ngày *</label>
          <div class="relative">
            <input type="text" name="giaKhongDen" id="typePriceNoLight" required placeholder="150,000"
                   class="h-10 w-full pl-3 pr-10 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400">
            <span class="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-semibold text-purple-400">đ</span>
          </div>
        </div>
        <div id="priceWithLightWrap" class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-purple-900">Giá có bật đèn *</label>
          <div class="relative">
            <input type="text" name="giaCoDen" id="typePriceWithLight" placeholder="200,000" class="h-10 w-full pl-3 pr-10 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400">
            <span class="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-semibold text-purple-400">đ</span>
          </div>
        </div>
      </div>

      <!-- Giờ lên đèn — ẩn khi chọn "không dùng đèn" -->
      <div id="lightTimeSection">
        <div class="grid grid-cols-2 gap-3">
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-semibold text-purple-900">Giờ bắt đầu bật đèn *</label>
            <input type="time" name="gioBatDauLenDen" id="typeLightStart" value="17:30" class="h-10 px-3 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400">
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-semibold text-purple-900">Giờ kết thúc bật đèn *</label>
            <input type="time" name="gioKetThucLenDen" id="typeLightEnd" value="22:00" class="h-10 px-3 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400">
          </div>
        </div>
        <p class="mt-2 text-[10px] text-purple-500 flex items-center gap-1"
           title="Có thể cấu hình qua ngày (VD 17:00–05:00). Nếu giờ bắt đầu = giờ kết thúc, giá có đèn áp dụng toàn thời gian (phù hợp sân trong nhà như Cầu lông).">
          <span class="material-symbols-outlined text-[12px]">info</span>Hỗ trợ khung giờ qua đêm &amp; sân trong nhà — di chuột để biết thêm
        </p>
      </div>

      <div class="flex justify-end gap-2 pt-3 border-t border-purple-50">
        <button type="button" onclick="closeTypeModal()" class="h-10 px-4 rounded-xl border border-purple-200 text-sm font-semibold text-purple-700 hover:bg-purple-50">Hủy</button>
        <button type="button" onclick="submitTypeForm()" id="saveTypeBtn" class="h-10 px-5 rounded-xl bg-purple-600 text-white text-sm font-semibold hover:bg-purple-700 shadow shadow-purple-200">Lưu bảng giá</button>
      </div>
    </form>
  </div>
</div>

<!-- Modal 3: Cấu hình giá cho từng sân (`priceConfigModal`) -->
<div id="priceConfigModal" class="hidden fixed inset-0 z-[80] flex items-center justify-center p-4">
  <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" onclick="closePriceConfigModal()"></div>
  <div class="relative bg-white rounded-3xl shadow-2xl w-full max-w-[480px] max-h-[92vh] overflow-y-auto border border-purple-100">
    <div class="flex items-center justify-between px-6 py-4 border-b border-purple-50">
      <div>
        <h2 id="priceConfigModalTitle" class="text-base font-bold text-purple-950 font-sans">Cấu hình giá sân</h2>
        <p id="priceConfigModalSubtitle" class="text-xs text-purple-500 mt-0.5">Thiết lập đơn giá theo khung giờ lên đèn</p>
      </div>
      <button onclick="closePriceConfigModal()" class="p-1.5 rounded-lg hover:bg-purple-50"><span class="material-symbols-outlined text-[18px] text-zinc-500">close</span></button>
    </div>
    <form id="priceConfigForm" class="px-6 py-4 flex flex-col gap-4" method="POST" action="${pageContext.request.contextPath}/manager/quan-ly-san">
      <input type="hidden" name="action" value="updateType">
      <input type="hidden" name="loaiSanID" id="priceConfigLoaiSanId">
      <input type="hidden" name="monTheThaoID" id="priceConfigSportId">
      <input type="hidden" name="tenLoai" id="priceConfigTypeName">

      <!-- Warning/Notice Banner for Shared Court Types -->
      <div id="sharedCourtsWarning" class="p-3 bg-amber-50 border border-amber-100 rounded-xl text-amber-800 text-[11px] flex items-start gap-2">
        <span class="material-symbols-outlined text-[16px] text-amber-600 shrink-0">warning</span>
        <div>
          <span class="font-bold">Lưu ý:</span> 
          Thay đổi giá sẽ áp dụng cho tất cả các sân thuộc cấu hình loại sân này: 
          <span id="sharedCourtsList" class="font-semibold text-amber-900"></span>.
        </div>
      </div>

      <div class="grid grid-cols-2 gap-3">
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-purple-900">Giá ngày (Không đèn) *</label>
          <div class="relative">
            <input type="text" name="giaKhongDen" id="priceConfigPriceNoLight" required placeholder="150,000" class="h-10 w-full pl-3 pr-10 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400">
            <span class="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-semibold text-purple-400">đ</span>
          </div>
        </div>
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-purple-900">Giá tối (Có bật đèn) *</label>
          <div class="relative">
            <input type="text" name="giaCoDen" id="priceConfigPriceWithLight" required placeholder="200,000" class="h-10 w-full pl-3 pr-10 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400">
            <span class="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-semibold text-purple-400">đ</span>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-3">
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-purple-900">Giờ bắt đầu bật đèn *</label>
          <input type="time" name="gioBatDauLenDen" id="priceConfigLightStart" required class="h-10 px-3 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400">
        </div>
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-purple-900">Giờ kết thúc bật đèn *</label>
          <input type="time" name="gioKetThucLenDen" id="priceConfigLightEnd" required class="h-10 px-3 rounded-xl border border-purple-200 text-sm focus:outline-none focus:ring-2 focus:ring-purple-500/30 focus:border-purple-400">
        </div>
      </div>

      <div class="flex justify-end gap-2 pt-3 border-t border-purple-50">
        <button type="button" onclick="closePriceConfigModal()" class="h-10 px-4 rounded-xl border border-purple-200 text-sm font-semibold text-purple-700 hover:bg-purple-50">Hủy</button>
        <button type="submit" class="h-10 px-5 rounded-xl bg-purple-600 text-white text-sm font-semibold hover:bg-purple-700 shadow shadow-purple-200">Cập nhật giá</button>
      </div>
    </form>
  </div>
</div>

<script>
  // Mobile menu toggle
  document.getElementById('mobileMenuBtn').addEventListener('click', () => {
    document.getElementById('sidebar').classList.toggle('-translate-x-full');
  });

  const contextPath = '${pageContext.request.contextPath}';

  // DATA SERIALIZATION
  const mockSports = [
    <c:forEach items="${dsMonTheThao}" var="m" varStatus="loop">
    { id: ${m.monTheThaoID}, name: '${m.tenMon}', icon: '${m.tenMon == "Bóng đá" ? "sports_soccer" : (m.tenMon == "Cầu lông" ? "sports_tennis" : (m.tenMon == "Pickleball" ? "sports_kabaddi" : "sports_tennis"))}' }${!loop.last ? ',' : ''}
    </c:forEach>
  ];

  let mockLoaiSan = [
    <c:forEach items="${dsLoaiSan}" var="l" varStatus="loop">
    { id: ${l.loaiSanID}, sportId: ${l.monTheThaoID}, name: '${l.tenLoai}', priceNoLight: ${l.giaKhongDen}, priceWithLight: ${l.giaCoDen}, lightStart: '${l.gioBatDauLenDen != null ? l.gioBatDauLenDen : ""}', lightEnd: '${l.gioKetThucLenDen != null ? l.gioKetThucLenDen : ""}', coSoId: ${l.coSoID != null ? l.coSoID : 'null'} }${!loop.last ? ',' : ''}
    </c:forEach>
  ];

  let mockSan = [
    <c:forEach items="${dsSan}" var="s" varStatus="loop">
    { id: ${s.sanID}, typeId: ${s.loaiSanID}, coSoId: ${s.coSoID}, code: 'SAN' + ${s.sanID}, name: '${s.tenSan}', status: '${s.trangThai}', desc: '${s.moTa}', image: '${s.hinhAnh}' }${!loop.last ? ',' : ''}
    </c:forEach>
  ];

  const sportImages = {
    1: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=500&h=300&fit=crop',
    2: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=500&h=300&fit=crop',
    3: 'https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?w=500&h=300&fit=crop',
    4: 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=500&h=300&fit=crop'
  };

  let currentTab = 'courts';
  let viewMode = 'grid';

  function normalizeCourtImageUrl(url) {
    if (!url) return '';
    if (url.startsWith('/uploads/')) return contextPath + url;
    return url;
  }

  function initCurrencyFormatter(inputId) {
    const input = document.getElementById(inputId);
    if (!input) return;
    input.addEventListener('input', (e) => {
      let value = e.target.value.replace(/,/g, '').replace(/[^0-9]/g, '');
      if (value === '') { e.target.value = ''; return; }
      let num = parseInt(value, 10);
      const cursorBefore = e.target.selectionStart;
      const lenBefore = e.target.value.length;
      const formatted = num.toLocaleString('en-US');
      e.target.value = formatted;
      const lenAfter = formatted.length;
      const newCursor = Math.max(0, cursorBefore + (lenAfter - lenBefore));
      e.target.setSelectionRange(newCursor, newCursor);
    });
  }

  function formatCurrency(val) {
    return val.toLocaleString('vi-VN') + 'đ';
  }

  // POPULATE DROPDOWNS
  function populateSportDropdowns() {
    const filterType = document.getElementById('filterType');
    const typeSportSelect = document.getElementById('typeSportSelect');
    
    mockSports.forEach(s => {
      const opt1 = document.createElement('option');
      opt1.value = s.id;
      opt1.textContent = s.name;
      filterType.appendChild(opt1);

      const opt2 = document.createElement('option');
      opt2.value = s.id;
      opt2.textContent = s.name;
      typeSportSelect.appendChild(opt2);
    });
  }

  function populateCourtTypeDropdown(selectedId) {
    const select = document.getElementById('courtTypeSelect');
    if (!select) return;
    select.innerHTML = '<option value="">-- Chọn loại sân --</option>';
    mockLoaiSan.forEach(t => {
      const opt = document.createElement('option');
      opt.value = t.id;
      opt.textContent = t.name;
      select.appendChild(opt);
    });
    if (selectedId) {
      select.value = selectedId;
    } else if (mockLoaiSan.length > 0) {
      select.value = mockLoaiSan[0].id;
    }
    onCourtTypeChange();
  }

  function onCourtTypeChange() {
    const select = document.getElementById('courtTypeSelect');
    const typeId = parseInt(select.value);
    const type = mockLoaiSan.find(t => t.id === typeId);
    if (!type) { updateCardPreview(); return; }

    // Gợi ý tên tự động (chỉ khi tạo mới và manager chưa tự gõ tên)
    if (document.getElementById('courtAction').value === 'add' && !courtNameEdited) {
      document.getElementById('courtName').value = suggestCourtName(type);
      updateBulkNamePreview();
    }
    updateCardPreview();
  }

  // Đề xuất tên dựa trên số sân cùng loại đang có: "Sân Bóng Đá 5 người" -> "Sân Bóng Đá 5 người - Sân 3"
  function suggestCourtName(type) {
    const countSameType = mockSan.filter(s => s.typeId === type.id).length;
    return type.name + ' - Sân ' + (countSameType + 1);
  }

  let courtNameEdited = false;
  function updateBulkNamePreview() {
    // no-op: field đã xóa
  }

  function escapeHtml(s) {
    const d = document.createElement('div');
    d.textContent = s;
    return d.innerHTML;
  }

  // Card action menu (⋯) — chỉ 1 menu mở tại 1 thời điểm
  function toggleCardMenu(event, id) {
    event.stopPropagation();
    const menu = document.getElementById('cardMenu-' + id);
    const wasOpen = !menu.classList.contains('hidden');
    document.querySelectorAll('[id^="cardMenu-"]').forEach(m => m.classList.add('hidden'));
    if (!wasOpen) menu.classList.remove('hidden');
  }
  document.addEventListener('click', () => {
    document.querySelectorAll('[id^="cardMenu-"]').forEach(m => m.classList.add('hidden'));
  });

  // Mini-card preview: mô phỏng card sân trên danh sách
  function updateCardPreview() {
    const name = document.getElementById('courtName').value.trim();
    const typeId = parseInt(document.getElementById('courtTypeSelect').value);
    const type = mockLoaiSan.find(t => t.id === typeId) || {};
    const sport = mockSports.find(s => s.id === type.sportId) || {};
    const status = document.getElementById('courtStatus').value || 'Sẵn sàng';
    const imgUrl = getCurrentCourtImagePreviewSource();

    document.getElementById('cardPrevName').textContent = name || 'Tên sân...';
    document.getElementById('cardPrevType').textContent = type.name || 'Loại sân';
    document.getElementById('cardPrevSport').textContent = sport.name || '—';

    const priceEl = document.getElementById('cardPrevPrice');
    priceEl.textContent = (type.priceNoLight != null)
      ? formatCurrency(type.priceNoLight) + ' / ' + formatCurrency(type.priceWithLight)
      : '—';

    const lightHoursEl = document.getElementById('cardPrevLightHours');
    lightHoursEl.textContent = (type.lightStart && type.lightEnd) ? (type.lightStart + '-' + type.lightEnd) : '';

    const statusEl = document.getElementById('cardPrevStatus');
    statusEl.textContent = status;
    statusEl.className = 'absolute top-2 right-2 badge text-[10px] ' +
      (status === 'Sẵn sàng' ? 'badge-green' : status === 'Đang dùng' ? 'badge-blue' : status === 'Bảo trì' ? 'badge-amber' : 'badge-red');

    const defaultImg = sportImages[type.sportId] || sportImages[1];
    document.getElementById('cardPrevImg').src = imgUrl || defaultImg;
  }

  // Nhân bản sân: mở modal tạo mới với dữ liệu copy từ sân gốc
  function duplicateCourt(id) {
    const c = mockSan.find(x => x.id === id);
    if (!c) return;

    openCreateModal();
    document.getElementById('courtModalTitle').textContent = 'Nhân bản sân thi đấu';
    document.getElementById('courtModalSubtitle').textContent = 'Sao chép cấu hình từ "' + c.name + '" — chỉ cần đổi tên';

    document.getElementById('courtTypeSelect').value = c.typeId;
    document.getElementById('courtDesc').value = c.desc || '';
    document.getElementById('existingCourtImage').value = c.image || '';
    updateImagePreview();

    // Tên gợi ý theo loại sân của sân gốc, cho phép manager sửa
    courtNameEdited = false;
    onCourtTypeChange();
    document.getElementById('courtName').focus();
    document.getElementById('courtName').select();
  }

  // Inline validation helpers
  function showFieldError(fieldId, msg) {
    const el = document.getElementById(fieldId);
    if (el) el.classList.add('!border-red-400');
    const errWrap = document.getElementById('err-' + fieldId);
    const errMsg = document.getElementById('err-' + fieldId + '-msg');
    if (errWrap) errWrap.classList.remove('hidden');
    if (errMsg) errMsg.textContent = msg;
  }
  function clearFieldError(fieldId) {
    const el = document.getElementById(fieldId);
    if (el) el.classList.remove('!border-red-400');
    const errWrap = document.getElementById('err-' + fieldId);
    if (errWrap) errWrap.classList.add('hidden');
  }

  // Image preview
  function getCurrentCourtImagePreviewSource() {
    const fileInput = document.getElementById('courtImageFile');
    const existingImage = document.getElementById('existingCourtImage').value.trim();
    if (fileInput && fileInput.files && fileInput.files[0]) {
      return URL.createObjectURL(fileInput.files[0]);
    }
    return normalizeCourtImageUrl(existingImage);
  }

  function clearCourtImageSelection() {
    const fileInput = document.getElementById('courtImageFile');
    const existingImage = document.getElementById('existingCourtImage');
    if (fileInput) fileInput.value = '';
    if (existingImage) existingImage.value = '';
    updateImagePreview();
    updateCardPreview();
  }

  function updateImagePreview() {
    const url = getCurrentCourtImagePreviewSource();
    const wrap = document.getElementById('courtImagePreviewWrap');
    const img = document.getElementById('courtImagePreview');
    const errDiv = document.getElementById('courtImageError');
    const fileInput = document.getElementById('courtImageFile');
    const fileName = document.getElementById('courtImageFileName');
    const clearBtn = document.getElementById('clearCourtImageBtn');
    const existingImage = document.getElementById('existingCourtImage').value.trim();

    if (fileInput && fileInput.files && fileInput.files[0]) {
      fileName.textContent = fileInput.files[0].name;
    } else if (existingImage) {
      fileName.textContent = 'Dang dung anh da luu cua san.';
    } else {
      fileName.textContent = 'Chua chon anh nao.';
    }

    if (clearBtn) {
      if ((fileInput && fileInput.files && fileInput.files[0]) || existingImage) clearBtn.classList.remove('hidden');
      else clearBtn.classList.add('hidden');
    }

    if (!url) { wrap.classList.add('hidden'); return; }
    wrap.classList.remove('hidden');
    errDiv.classList.add('hidden');
    img.src = url;
  }

  // Status options per mode
  function setStatusOptions(isEdit, currentStatus) {
    const sel = document.getElementById('courtStatus');
    sel.innerHTML = '';
    const createOpts = [{ v: 'Sẵn sàng', l: 'Sẵn sàng' }, { v: 'Tạm đóng', l: 'Tạm đóng (chưa khai thác)' }];
    const editOpts = [
      { v: 'Sẵn sàng', l: 'Sẵn sàng' }, { v: 'Đang dùng', l: 'Đang dùng' },
      { v: 'Bảo trì', l: 'Bảo trì' }, { v: 'Tạm đóng', l: 'Tạm đóng' }
    ];
    (isEdit ? editOpts : createOpts).forEach(o => {
      const opt = document.createElement('option');
      opt.value = o.v; opt.textContent = o.l;
      sel.appendChild(opt);
    });
    if (currentStatus) sel.value = currentStatus;
  }

  // Form validation + submit
  function submitCourtForm() {
    let valid = true;
    const name = document.getElementById('courtName').value.trim();
    const typeVal = document.getElementById('courtTypeSelect').value;
    const isAdd = document.getElementById('courtAction').value === 'add';

    clearFieldError('courtName'); clearFieldError('courtTypeSelect');

    if (!name) { showFieldError('courtName', 'Tên sân không được để trống'); valid = false; }
    if (!typeVal) { showFieldError('courtTypeSelect', 'Vui lòng chọn loại sân'); valid = false; }

    if (!valid) return;

    // Gỡ bỏ disabled để đảm bảo dữ liệu được gửi lên Servlet
    document.getElementById('courtName').removeAttribute('disabled');
    document.getElementById('courtTypeSelect').removeAttribute('disabled');
    document.getElementById('courtStatus').removeAttribute('disabled');

    document.getElementById('courtForm').submit();
  }

  // TAB SWITCHING
  function switchTab(tab) {
    currentTab = tab;
    const btnTabCourts = document.getElementById('btnTabCourts');
    const btnTabTypes = document.getElementById('btnTabTypes');
    const mainActionBtn = document.getElementById('mainActionBtn');
    
    const toolbar = document.getElementById('toolbarSection');
    const stats = document.getElementById('statsSection');
    const gridContainer = document.getElementById('mainCourtGrid');
    const listContainer = document.getElementById('mainCourtList');
    const pricingView = document.getElementById('pricingTypesView');

    if (tab === 'courts') {
      btnTabCourts.className = 'pb-3 text-sm font-bold border-b-2 border-purple-600 text-purple-600 flex items-center gap-2 transition-all';
      btnTabTypes.className = 'pb-3 text-sm font-medium border-b-2 border-transparent text-purple-500 hover:text-purple-800 flex items-center gap-2 transition-all';
      mainActionBtn.innerHTML = `<span class="material-symbols-outlined text-[16px]">add</span>Thêm sân mới`;
      mainActionBtn.setAttribute('onclick', 'openCreateModal()');
      
      toolbar.classList.remove('hidden');
      stats.classList.remove('hidden');
      pricingView.classList.add('hidden');
      setViewMode(viewMode);
    } else {
      btnTabTypes.className = 'pb-3 text-sm font-bold border-b-2 border-purple-600 text-purple-600 flex items-center gap-2 transition-all';
      btnTabCourts.className = 'pb-3 text-sm font-medium border-b-2 border-transparent text-purple-500 hover:text-purple-800 flex items-center gap-2 transition-all';
      mainActionBtn.innerHTML = `<span class="material-symbols-outlined text-[16px]">playlist_add</span>Thêm loại sân`;
      mainActionBtn.setAttribute('onclick', 'openCreateTypeModal()');

      toolbar.classList.add('hidden');
      stats.classList.add('hidden');
      gridContainer.classList.add('hidden');
      listContainer.classList.add('hidden');
      pricingView.classList.remove('hidden');
      document.getElementById('emptyState').classList.add('hidden');
      renderTypesList();
    }
  }

  function setViewMode(mode) {
    viewMode = mode;
    const btnGrid = document.getElementById('btnViewGrid');
    const btnList = document.getElementById('btnViewList');
    const mainCourtGrid = document.getElementById('mainCourtGrid');
    const mainCourtList = document.getElementById('mainCourtList');

    if (currentTab !== 'courts') return;

    if (mode === 'grid') {
      btnGrid.className = 'px-3 py-2 text-sm flex items-center gap-1.5 bg-purple-600 text-white font-semibold';
      btnList.className = 'px-3 py-2 text-sm flex items-center gap-1.5 text-purple-600 hover:bg-purple-50';
      mainCourtGrid.classList.remove('hidden');
      mainCourtList.classList.add('hidden');
    } else {
      btnList.className = 'px-3 py-2 text-sm flex items-center gap-1.5 bg-purple-600 text-white font-semibold';
      btnGrid.className = 'px-3 py-2 text-sm flex items-center gap-1.5 text-purple-600 hover:bg-purple-50';
      mainCourtGrid.classList.add('hidden');
      mainCourtList.classList.remove('hidden');
    }
    applyFilters();
  }

  // RENDER DYNAMIC LISTS
  function renderCourts(courts) {
    const grid = document.getElementById('mainCourtGrid');
    const listBody = document.getElementById('courtListTableBody');
    const emptyState = document.getElementById('emptyState');

    if (courts.length === 0) {
      grid.classList.add('hidden');
      document.getElementById('mainCourtList').classList.add('hidden');
      emptyState.classList.remove('hidden');
      return;
    } else {
      emptyState.classList.add('hidden');
      if (viewMode === 'grid') grid.classList.remove('hidden');
      else document.getElementById('mainCourtList').classList.remove('hidden');
    }

    // Render Grid
    grid.innerHTML = courts.map(c => {
      const type = mockLoaiSan.find(t => t.id === c.typeId) || {};
      const sport = mockSports.find(s => s.id === type.sportId) || {};
      const defaultImg = sportImages[type.sportId] || sportImages[1];
      const img = c.image && c.image.trim() ? normalizeCourtImageUrl(c.image) : defaultImg;
      
      let badgeColor = 'badge-purple';
      if (c.status === 'Sẵn sàng') badgeColor = 'badge-green';
      else if (c.status === 'Đang dùng') badgeColor = 'badge-blue';
      else if (c.status === 'Bảo trì') badgeColor = 'badge-amber';
      else if (c.status === 'Tạm đóng') badgeColor = 'badge-red';

      return `
        <div class="card card-hover overflow-hidden flex flex-col">
          <div class="relative h-32 bg-zinc-100">
            <img src="\${img}" class="w-full h-full object-cover" alt="\${c.name}">
            <div class="absolute top-2.5 right-2.5">
              <span class="badge \${badgeColor}">\${c.status}</span>
            </div>
            <div class="absolute bottom-2.5 left-2.5 bg-black/60 backdrop-blur-sm px-2 py-0.5 rounded text-[9px] font-bold text-white flex items-center gap-1 uppercase">
              <span class="material-symbols-outlined text-[11px]">\${sport.icon || 'sports'}</span>\${sport.name || 'Bộ môn'}
            </div>
          </div>
          <div class="p-3.5 flex-1 flex flex-col gap-2.5">
            <div>
              <h4 class="font-bold text-purple-950 text-sm tracking-tight leading-tight">\${c.name}</h4>
              <p class="text-[10px] text-purple-500 font-semibold mt-0.5">\${type.name || 'Loại sân'}</p>
            </div>
            <div class="flex items-center justify-between text-[11px] bg-purple-50/40 px-2.5 py-1.5 rounded-lg">
              <span class="font-bold text-zinc-800">\${formatCurrency(type.priceNoLight || 0)}</span>
              <span class="text-purple-300">/</span>
              <span class="font-bold text-purple-700">\${formatCurrency(type.priceWithLight || 0)}</span>
              <span class="text-zinc-400 text-[10px]">\${type.lightStart || '17:30'}-\${type.lightEnd || '22:00'}</span>
            </div>
            <div class="relative flex items-center gap-1.5 mt-auto pt-2.5 border-t border-purple-50">
              <button onclick="openEditModal(\${c.id})" class="flex-1 h-8 text-[11px] font-bold text-purple-700 bg-purple-50 hover:bg-purple-100 rounded-lg flex items-center justify-center gap-1 transition-colors">
                <span class="material-symbols-outlined text-[13px]">edit</span>Sửa
              </button>
              <button onclick="openPriceConfigModal(\${c.id})" class="flex-1 h-8 text-[11px] font-bold text-emerald-700 bg-emerald-50 hover:bg-emerald-100 rounded-lg flex items-center justify-center gap-1 transition-colors">
                <span class="material-symbols-outlined text-[13px]">payments</span>Giá
              </button>
              <button onclick="toggleCardMenu(event, \${c.id})" class="h-8 w-8 text-zinc-500 hover:bg-zinc-100 rounded-lg flex items-center justify-center transition-colors" title="Thêm thao tác">
                <span class="material-symbols-outlined text-[16px]">more_vert</span>
              </button>
              <div id="cardMenu-\${c.id}" class="hidden absolute right-0 bottom-10 z-10 w-36 bg-white rounded-xl shadow-lg border border-zinc-100 py-1">
                <button onclick="duplicateCourt(\${c.id}); toggleCardMenu(event, \${c.id})" class="w-full flex items-center gap-2 px-3 py-2 text-[11px] font-semibold text-sky-700 hover:bg-sky-50">
                  <span class="material-symbols-outlined text-[14px]">content_copy</span>Nhân bản
                </button>
                <button onclick="deleteCourt(\${c.id})" class="w-full flex items-center gap-2 px-3 py-2 text-[11px] font-semibold text-red-600 hover:bg-red-50">
                  <span class="material-symbols-outlined text-[14px]">delete</span>Xóa
                </button>
              </div>
            </div>
          </div>
        </div>
      `;
    }).join('');

    // Render List
    listBody.innerHTML = courts.map(c => {
      const type = mockLoaiSan.find(t => t.id === c.typeId) || {};
      const sport = mockSports.find(s => s.id === type.sportId) || {};
      
      let badgeColor = 'badge-purple';
      if (c.status === 'Sẵn sàng') badgeColor = 'badge-green';
      else if (c.status === 'Đang dùng') badgeColor = 'badge-blue';
      else if (c.status === 'Bảo trì') badgeColor = 'badge-amber';
      else if (c.status === 'Tạm đóng') badgeColor = 'badge-red';

      return `
        <tr class="hover:bg-purple-50/20 transition-colors">
          <td class="px-5 py-4 font-bold text-zinc-800">\${c.name}</td>
          <td class="px-5 py-4">
            <div class="flex flex-col">
              <span class="font-semibold text-zinc-700">\${type.name || 'Loại sân'}</span>
              <span class="text-[10px] text-purple-500 mt-0.5 font-medium flex items-center gap-0.5">
                <span class="material-symbols-outlined text-[11px]">\${sport.icon || 'sports'}</span>\${sport.name || 'Bộ môn'}
              </span>
            </div>
          </td>
          <td class="px-5 py-4 font-medium">
            <span class="text-zinc-700 font-semibold">\${formatCurrency(type.priceNoLight || 0)}</span> /
            <span class="text-purple-700 font-bold">\${formatCurrency(type.priceWithLight || 0)}</span>
            <span class="text-zinc-400 text-[10px] block mt-0.5">\${type.lightStart || '17:30'} - \${type.lightEnd || '22:00'}</span>
          </td>
          <td class="px-5 py-4"><span class="badge \${badgeColor}">\${c.status}</span></td>
          <td class="px-5 py-4 text-right">
            <div class="flex items-center justify-end gap-1">
              <button onclick="openEditModal(\${c.id})" class="p-1 hover:bg-purple-50 text-purple-700 rounded-lg transition-colors" title="Chỉnh sửa"><span class="material-symbols-outlined text-[16px]">edit</span></button>
              <button onclick="openPriceConfigModal(\${c.id})" class="p-1 hover:bg-emerald-50 text-emerald-700 rounded-lg transition-colors" title="Cấu hình giá"><span class="material-symbols-outlined text-[16px]">payments</span></button>
              <button onclick="duplicateCourt(\${c.id})" class="p-1 hover:bg-sky-50 text-sky-600 rounded-lg transition-colors" title="Nhân bản sân"><span class="material-symbols-outlined text-[16px]">content_copy</span></button>
              <button onclick="deleteCourt(\${c.id})" class="p-1 hover:bg-red-50 text-red-500 rounded-lg transition-colors" title="Xóa"><span class="material-symbols-outlined text-[16px]">delete</span></button>
            </div>
          </td>
        </tr>
      `;
    }).join('');

    // Update stats counters
    document.getElementById('statTotal').textContent = mockSan.length;
    document.getElementById('statReady').textContent = mockSan.filter(s => s.status === 'Sẵn sàng').length;
    document.getElementById('statMaintenance').textContent = mockSan.filter(s => s.status === 'Bảo trì').length;
    document.getElementById('statClosed').textContent = mockSan.filter(s => s.status === 'Tạm đóng').length;
  }

  function renderTypesList() {
    const listBody = document.getElementById('typeListTableBody');
    if (!listBody) return;
    
    listBody.innerHTML = mockLoaiSan.map(t => {
      const sport = mockSports.find(s => s.id === t.sportId) || {};
      return `
        <tr class="hover:bg-purple-50/20 transition-colors">
          <td class="px-5 py-4 font-mono font-bold text-purple-900">TYPE\${t.id}</td>
          <td class="px-5 py-4 font-bold text-zinc-800">\${t.name}</td>
          <td class="px-5 py-4">
            <span class="text-[10px] font-bold text-purple-700 bg-purple-50 px-2 py-0.5 rounded-full inline-flex items-center gap-1">
              <span class="material-symbols-outlined text-[11px]">\${sport.icon || 'sports'}</span>\${sport.name}
            </span>
          </td>
          <td class="px-5 py-4 font-semibold text-zinc-700">\${formatCurrency(t.priceNoLight)}</td>
          <td class="px-5 py-4 font-bold text-purple-700">\${formatCurrency(t.priceWithLight)}</td>
          <td class="px-5 py-4 text-zinc-500 font-semibold">\${t.lightStart}</td>
          <td class="px-5 py-4 text-zinc-500 font-semibold">\${t.lightEnd || 'Chưa thiết lập'}</td>
          <td class="px-5 py-4 text-right">
            <div class="flex items-center justify-end gap-1">
              <button onclick="openEditTypeModal(\${t.id})" class="p-1 hover:bg-purple-50 text-purple-700 rounded-lg transition-colors"><span class="material-symbols-outlined text-[16px]">edit</span></button>
              <button onclick="deleteType(\${t.id})" class="p-1 hover:bg-red-50 text-red-500 rounded-lg transition-colors"><span class="material-symbols-outlined text-[16px]">delete</span></button>
            </div>
          </td>
        </tr>
      `;
    }).join('');
  }

  // FILTERING LOGIC
  function applyFilters() {
    const sportFilter = document.getElementById('filterType').value;
    const statusFilter = document.getElementById('filterStatus').value;
    const searchVal = document.getElementById('searchInput').value.toLowerCase().trim();

    let filtered = mockSan;

    // Filter by sport (via LoaiSan)
    if (sportFilter !== 'all') {
      const allowedTypeIds = mockLoaiSan.filter(t => t.sportId == sportFilter).map(t => t.id);
      filtered = filtered.filter(c => allowedTypeIds.includes(c.typeId));
    }

    // Filter by status
    if (statusFilter !== 'all') {
      filtered = filtered.filter(c => c.status === statusFilter);
    }

    // Filter by search query
    if (searchVal) {
      filtered = filtered.filter(c => c.name.toLowerCase().includes(searchVal));
    }

    renderCourts(filtered);
  }

  // COURT MODAL ACTIONS
  function openCreateModal() {
    document.getElementById('courtForm').reset();
    document.getElementById('existingCourtImage').value = '';
    document.getElementById('courtImageFile').value = '';
    courtNameEdited = false;
    clearFieldError('courtName'); clearFieldError('courtTypeSelect');
    document.getElementById('courtModalTitle').textContent = 'Thêm sân thi đấu mới';
    document.getElementById('courtModalSubtitle').textContent = 'Tạo sân thi đấu mới cho chi nhánh';
    document.getElementById('courtAction').value = 'add';
    document.getElementById('courtEditId').value = '';
    document.getElementById('courtImagePreviewWrap').classList.add('hidden');
    updateImagePreview();

    document.getElementById('courtName').removeAttribute('disabled');
    document.getElementById('courtTypeSelect').removeAttribute('disabled');
    document.getElementById('courtStatus').removeAttribute('disabled');
    document.getElementById('courtOccupiedWarning').classList.add('hidden');

    // Empty state banner
    const banner = document.getElementById('courtNoTypesBanner');
    const form = document.getElementById('courtForm');
    if (mockLoaiSan.length === 0) {
      banner.classList.remove('hidden'); form.classList.add('hidden');
    } else {
      banner.classList.add('hidden'); form.classList.remove('hidden');
      setStatusOptions(false, 'Sẵn sàng');
      populateCourtTypeDropdown();
    }
    document.getElementById('courtModal').classList.remove('hidden');
  }

  function openEditModal(id) {
    const c = mockSan.find(x => x.id === id);
    if (!c) return;

    courtNameEdited = true;
    clearFieldError('courtName'); clearFieldError('courtTypeSelect');
    document.getElementById('courtModalTitle').textContent = 'Chỉnh sửa sân thi đấu';
    document.getElementById('courtModalSubtitle').textContent = 'Cập nhật thông tin sân #' + c.id;
    document.getElementById('courtAction').value = 'update';
    document.getElementById('courtEditId').value = c.id;
    document.getElementById('courtImageFile').value = '';
    document.getElementById('courtName').value = c.name;
    document.getElementById('courtDesc').value = c.desc || '';
    document.getElementById('existingCourtImage').value = c.image || '';
    setStatusOptions(true, c.status);
    populateCourtTypeDropdown(c.typeId);
    updateImagePreview();

    const isOccupied = c.status === 'Đang dùng' || c.status === 'Đang sử dụng';
    const warning = document.getElementById('courtOccupiedWarning');
    const nameInput = document.getElementById('courtName');
    const typeSelect = document.getElementById('courtTypeSelect');
    const statusSelect = document.getElementById('courtStatus');

    if (isOccupied) {
      warning.classList.remove('hidden');
      nameInput.setAttribute('disabled', 'disabled');
      typeSelect.setAttribute('disabled', 'disabled');
      statusSelect.setAttribute('disabled', 'disabled');
    } else {
      warning.classList.add('hidden');
      nameInput.removeAttribute('disabled');
      typeSelect.removeAttribute('disabled');
      statusSelect.removeAttribute('disabled');
    }

    document.getElementById('courtNoTypesBanner').classList.add('hidden');
    document.getElementById('courtForm').classList.remove('hidden');
    document.getElementById('courtModal').classList.remove('hidden');
  }

  function closeCourtModal() {
    document.getElementById('courtModal').classList.add('hidden');
  }

  function deleteCourt(id) {
    showCustomConfirm("Bạn có chắc chắn muốn xóa sân thi đấu này? Sân sẽ được chuyển vào Thùng rác.", () => {
      showToast("Đang thực hiện xóa... Bạn có thể vào Thùng rác để khôi phục.", "success");
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = '${pageContext.request.contextPath}/manager/quan-ly-san';
      
      const act = document.createElement('input'); act.type = 'hidden'; act.name = 'action'; act.value = 'delete';
      const sId = document.createElement('input'); sId.type = 'hidden'; sId.name = 'sanID'; sId.value = id;
      
      form.appendChild(act);
      form.appendChild(sId);
      document.body.appendChild(form);
      setTimeout(() => {
        form.submit();
      }, 1200);
    });
  }


  // TYPE MODAL ACTIONS
  function toggleTypeNoLight() {
    const noLight = document.getElementById('typeNoLight').checked;
    const lightSection = document.getElementById('lightTimeSection');
    const priceWithWrap = document.getElementById('priceWithLightWrap');
    const priceWithInput = document.getElementById('typePriceWithLight');
    document.getElementById('typeKhongDungDenHidden').value = noLight ? 'true' : 'false';
    if (noLight) {
      lightSection.classList.add('hidden');
      priceWithWrap.classList.add('opacity-40', 'pointer-events-none');
      priceWithInput.value = '';
      priceWithInput.removeAttribute('required');
    } else {
      lightSection.classList.remove('hidden');
      priceWithWrap.classList.remove('opacity-40', 'pointer-events-none');
      priceWithInput.setAttribute('required', '');
    }
  }

  function submitTypeForm() {
    const noLight = document.getElementById('typeNoLight').checked;
    const name = document.getElementById('typeName').value.trim();
    const priceNoLight = document.getElementById('typePriceNoLight').value.trim();
    if (!name) { alert('Vui lòng nhập tên loại sân.'); return; }
    if (!priceNoLight) { alert('Vui lòng nhập giá ban ngày.'); return; }
    if (!noLight) {
      const priceWithLight = document.getElementById('typePriceWithLight').value.trim();
      const lightStart = document.getElementById('typeLightStart').value;
      const lightEnd = document.getElementById('typeLightEnd').value;
      if (!priceWithLight || !lightStart || !lightEnd) {
        alert('Vui lòng nhập đầy đủ giá và thời gian áp dụng giá có đèn.');
        return;
      }
    }
    document.getElementById('typeForm').submit();
  }

  function openCreateTypeModal() {
    document.getElementById('typeForm').reset();
    document.getElementById('typeModalTitle').textContent = 'Thêm loại cấu hình sân mới';
    document.getElementById('typeAction').value = 'addType';
    document.getElementById('typeEditId').value = '';
    document.getElementById('typeNoLight').checked = false;
    document.getElementById('typeKhongDungDenHidden').value = 'false';
    document.getElementById('lightTimeSection').classList.remove('hidden');
    document.getElementById('priceWithLightWrap').classList.remove('opacity-40', 'pointer-events-none');
    document.getElementById('typePriceWithLight').setAttribute('required', '');
    document.getElementById('typeLightStart').value = '17:30';
    document.getElementById('typeLightEnd').value = '22:00';
    document.getElementById('typeModal').classList.remove('hidden');
  }

  function openEditTypeModal(id) {
    const t = mockLoaiSan.find(x => x.id === id);
    if (!t) return;

    document.getElementById('typeModalTitle').textContent = 'Chỉnh sửa loại cấu hình sân';
    document.getElementById('typeAction').value = 'updateType';
    document.getElementById('typeEditId').value = t.id;
    document.getElementById('typeSportSelect').value = t.sportId;
    document.getElementById('typeName').value = t.name;

    document.getElementById('typePriceNoLight').value = t.priceNoLight ? t.priceNoLight.toLocaleString('en-US') : '';

    // Detect không dùng đèn: giaCoDen null/0 hoặc không có giờ đèn
    const isNoLight = !t.priceWithLight || t.priceWithLight === 0 || (!t.lightStart && !t.lightEnd);
    document.getElementById('typeNoLight').checked = isNoLight;
    document.getElementById('typeKhongDungDenHidden').value = isNoLight ? 'true' : 'false';

    if (!isNoLight) {
      document.getElementById('typePriceWithLight').value = t.priceWithLight ? t.priceWithLight.toLocaleString('en-US') : '';
      let timeStr = t.lightStart || '';
      if (timeStr.length > 5) timeStr = timeStr.substring(0, 5);
      document.getElementById('typeLightStart').value = timeStr;
      let endTimeStr = t.lightEnd || '';
      if (endTimeStr.length > 5) endTimeStr = endTimeStr.substring(0, 5);
      document.getElementById('typeLightEnd').value = endTimeStr || '22:00';
    }

    toggleTypeNoLight();
    document.getElementById('typeModal').classList.remove('hidden');
  }

  function closeTypeModal() {
    document.getElementById('typeModal').classList.add('hidden');
  }

  function deleteType(id) {
    showCustomConfirm("Bạn có chắc chắn muốn xóa cấu hình loại sân này? Loại sân sẽ được chuyển vào Thùng rác.", () => {
      showToast("Đang thực hiện xóa... Bạn có thể vào Thùng rác để khôi phục.", "success");
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = '${pageContext.request.contextPath}/manager/quan-ly-san';
      
      const act = document.createElement('input'); act.type = 'hidden'; act.name = 'action'; act.value = 'deleteType';
      const tId = document.createElement('input'); tId.type = 'hidden'; tId.name = 'loaiSanID'; tId.value = id;
      
      form.appendChild(act);
      form.appendChild(tId);
      document.body.appendChild(form);
      setTimeout(() => {
        form.submit();
      }, 1200);
    });
  }


  // Tiền xử lý submit typeForm: bỏ dấu phẩy khỏi giá trước khi gửi
  document.getElementById('typeForm').addEventListener('submit', function() {
    const priceNoLight = document.getElementById('typePriceNoLight');
    const priceWithLight = document.getElementById('typePriceWithLight');
    priceNoLight.value = priceNoLight.value.replace(/,/g, '');
    priceWithLight.value = priceWithLight.value.replace(/,/g, '');
  });

  // PRICE CONFIG MODAL ACTIONS
  function openPriceConfigModal(courtId) {
    const c = mockSan.find(x => x.id === courtId);
    if (!c) return;
    const type = mockLoaiSan.find(t => t.id === c.typeId);
    if (!type) return;

    document.getElementById('priceConfigModalTitle').textContent = `Cấu hình giá — \${c.name}`;
    document.getElementById('priceConfigModalSubtitle').textContent = `Thiết lập đơn giá cho loại sân: \${type.name}`;
    
    document.getElementById('priceConfigLoaiSanId').value = type.id;
    document.getElementById('priceConfigSportId').value = type.sportId;
    document.getElementById('priceConfigTypeName').value = type.name;

    // Currency values
    document.getElementById('priceConfigPriceNoLight').value = type.priceNoLight.toLocaleString('en-US');
    document.getElementById('priceConfigPriceWithLight').value = type.priceWithLight.toLocaleString('en-US');

    // Time value
    let timeStr = type.lightStart;
    if (timeStr && timeStr.length > 5) timeStr = timeStr.substring(0, 5);
    document.getElementById('priceConfigLightStart').value = timeStr;

    let endTimeStr = type.lightEnd;
    if (endTimeStr && endTimeStr.length > 5) endTimeStr = endTimeStr.substring(0, 5);
    document.getElementById('priceConfigLightEnd').value = endTimeStr || '22:00';

    // List shared courts
    const sharedCourts = mockSan.filter(x => x.typeId === type.id);
    const sharedNames = sharedCourts.map(x => x.name).join(', ');
    document.getElementById('sharedCourtsList').textContent = sharedNames;

    document.getElementById('priceConfigModal').classList.remove('hidden');
  }

  function closePriceConfigModal() {
    document.getElementById('priceConfigModal').classList.add('hidden');
  }

  // Preprocessing for priceConfigForm submit to strip commas and validate fields
  // Tiền xử lý submit priceConfigForm: bỏ dấu phẩy, cho phép khung giờ qua ngày
  document.getElementById('priceConfigForm').addEventListener('submit', function() {
    const priceNoLight = document.getElementById('priceConfigPriceNoLight');
    const priceWithLight = document.getElementById('priceConfigPriceWithLight');
    priceNoLight.value = priceNoLight.value.replace(/,/g, '');
    priceWithLight.value = priceWithLight.value.replace(/,/g, '');
  });

  // INITIALIZATION ON LOAD
  document.addEventListener('DOMContentLoaded', () => {
    initCurrencyFormatter('typePriceNoLight');
    initCurrencyFormatter('typePriceWithLight');
    initCurrencyFormatter('priceConfigPriceNoLight');
    populateSportDropdowns();
    switchTab('courts'); // sets default view and triggers rendering
  });

  // Reload page when navigated back/forward via bfcache
  window.addEventListener('pageshow', function(event) {
    if (event.persisted) {
      window.location.reload();
    }
  });
</script>
</body>
</html>
