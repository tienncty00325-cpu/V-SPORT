<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ page import="org.example.model.CoSo" %>
<%@ page import="org.example.model.MonTheThao" %>
<%@ page import="java.util.List" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"/>
    <title>Tìm kiếm sân - V-SPORT</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet"/>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"/>
    <jsp:include page="/customer/common/vsport-theme.jsp" />

    <style>
        :root {
            --vs-red: #ff2433;
            --vs-red-hover: #d91b26;
            --vs-black: #111827;
            --vs-gray-900: #1f2937;
            --vs-gray-800: #374151;
            --vs-gray-500: #6b7280;
            --vs-gray-200: #e5e7eb;
            --vs-gray-100: #f3f4f6;
            --vs-gray-50: #f9fafb;
            --vs-bg: #f8f9fa;
        }

        body {
            background-color: var(--vs-bg);
            font-family: 'Poppins', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            margin: 0;
            padding: 0;
            color: var(--vs-black);
        }

        * { box-sizing: border-box; }

        /* HEADER */
        .vs-search-header {
            /* Removed sticky top 0 to not overlap with the global navbar */
            background: #fff;
            display: flex; align-items: center; justify-content: space-between;
            padding: 12px 20px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
        }
        .vsh-left { display: flex; align-items: center; gap: 12px; }
        .vsh-back {
            display: flex; align-items: center; justify-content: center;
            width: 40px; height: 40px; border-radius: 50%; border: none;
            background: var(--vs-gray-50); color: var(--vs-black); cursor: pointer;
            transition: background 0.2s; text-decoration: none;
        }
        .vsh-back:hover { background: var(--vs-gray-200); }
        .vsh-title { font-size: 18px; font-weight: 700; color: var(--vs-black); margin: 0; }
        
        .vsh-right { display: flex; align-items: center; gap: 8px; }
        .vsh-btn {
            display: flex; align-items: center; justify-content: center;
            width: 40px; height: 40px; border-radius: 50%; border: none;
            background: var(--vs-gray-50); color: var(--vs-black); cursor: pointer;
            transition: all 0.2s ease; text-decoration: none; position: relative;
        }
        .vsh-btn:hover { background: #fff; color: var(--vs-red); box-shadow: 0 4px 12px rgba(0,0,0,0.08); transform: translateY(-1px); }
        .vsh-btn i { font-size: 16px; }
        .vsh-btn-highlight { background: rgba(255, 36, 51, 0.08); color: var(--vs-red); }
        .vsh-btn-highlight:hover { background: rgba(255, 36, 51, 0.15); }

        /* SEARCH BAR */
        .vs-search-container {
            padding: 20px;
            background: #fff;
            border-bottom: 1px solid var(--vs-gray-200);
        }
        .vs-search-wrapper {
            position: relative;
            max-width: 800px;
            margin: 0 auto;
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .vs-search-input-box {
            flex: 1;
            display: flex; align-items: center; gap: 12px;
            background: var(--vs-gray-50);
            border: 1px solid var(--vs-gray-200);
            border-radius: 16px;
            padding: 0 16px;
            height: 52px;
            transition: all 0.2s ease;
        }
        .vs-search-input-box:focus-within {
            background: #fff;
            border-color: var(--vs-red);
            box-shadow: 0 0 0 3px rgba(255,36,51,0.1);
        }
        .vs-search-input-box i { color: var(--vs-gray-500); font-size: 18px; }
        .vs-search-input {
            flex: 1; border: none; outline: none; background: transparent;
            font-size: 15px; font-weight: 500; color: var(--vs-black); height: 100%;
        }
        .vs-search-input::placeholder { color: #9ca3af; font-weight: 400; }
        
        .vs-search-clear {
            background: transparent; border: none; color: var(--vs-gray-500);
            cursor: pointer; padding: 4px; display: none;
        }
        .vs-search-clear:hover { color: var(--vs-black); }
        
        .vs-filter-btn {
            display: flex; align-items: center; justify-content: center; gap: 8px;
            height: 52px; padding: 0 20px; border-radius: 16px; border: none;
            background: var(--vs-gray-900); color: #fff; font-size: 14px; font-weight: 600;
            cursor: pointer; transition: all 0.2s ease; white-space: nowrap;
        }
        .vs-filter-btn:hover { background: var(--vs-black); box-shadow: 0 4px 12px rgba(0,0,0,0.15); }
        .vs-filter-btn.has-active { background: var(--vs-red); }
        .vs-filter-btn.has-active:hover { background: var(--vs-red-hover); box-shadow: 0 4px 12px rgba(255,36,51,0.2); }

        /* FILTER CHIPS (SPORT TYPES) */
        .vs-chips-container {
            padding: 16px 20px;
            background: #fff;
            border-bottom: 1px solid var(--vs-gray-200);
            overflow-x: auto;
            scrollbar-width: none;
        }
        .vs-chips-container::-webkit-scrollbar { display: none; }
        .vs-chips-wrapper {
            display: flex; gap: 10px; max-width: 1200px; margin: 0 auto;
        }
        .vs-chip {
            display: inline-flex; align-items: center; gap: 6px;
            padding: 10px 16px; border-radius: 99px;
            border: 1px solid var(--vs-gray-200); background: #fff;
            color: var(--vs-gray-800); font-size: 14px; font-weight: 600;
            cursor: pointer; white-space: nowrap; transition: all 0.2s ease;
        }
        .vs-chip:hover { border-color: var(--vs-gray-500); background: var(--vs-gray-50); }
        .vs-chip.is-active {
            background: var(--vs-red); border-color: var(--vs-red); color: #fff;
            box-shadow: 0 4px 10px rgba(255,36,51,0.2);
        }

        /* ACTIVE FILTER BAR */
        .vs-active-filters {
            padding: 12px 20px; max-width: 1200px; margin: 0 auto;
            display: flex; flex-wrap: wrap; gap: 10px; align-items: center;
        }
        .vs-active-chip {
            display: inline-flex; align-items: center; gap: 6px;
            background: rgba(255,36,51,0.1); border: 1px solid rgba(255,36,51,0.2);
            color: var(--vs-red); font-size: 13px; font-weight: 600;
            padding: 6px 12px; border-radius: 99px;
        }
        .vs-active-chip a { color: inherit; display: flex; align-items: center; margin-left: 4px; }
        .vs-active-chip a:hover { opacity: 0.7; }
        .vs-clear-all { font-size: 13px; font-weight: 600; color: var(--vs-gray-500); text-decoration: none; margin-left: 8px; }
        .vs-clear-all:hover { color: var(--vs-black); text-decoration: underline; }

        /* RESULTS GRID */
        .vs-results-container {
            padding: 24px 20px; max-width: 1200px; margin: 0 auto;
        }
        .vs-results-count {
            font-size: 15px; font-weight: 600; color: var(--vs-gray-500);
            margin-bottom: 20px;
        }
        .vs-grid {
            display: grid; grid-template-columns: repeat(1, 1fr); gap: 24px;
        }
        @media(min-width: 640px) { .vs-grid { grid-template-columns: repeat(2, 1fr); } }
        @media(min-width: 900px) { .vs-grid { grid-template-columns: repeat(3, 1fr); } }
        @media(min-width: 1200px) { .vs-grid { grid-template-columns: repeat(4, 1fr); } }

        /* FACILITY CARD */
        .vs-card {
            background: #fff; border-radius: 20px; overflow: hidden;
            border: 1px solid var(--vs-gray-200);
            box-shadow: 0 4px 20px rgba(0,0,0,0.03);
            transition: all 0.3s cubic-bezier(0.25,0.8,0.25,1);
            display: flex; flex-direction: column; cursor: pointer; text-decoration: none;
            position: relative;
        }
        .vs-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 12px 30px rgba(0,0,0,0.08);
            border-color: var(--vs-gray-200);
        }
        .vs-card-img-wrap {
            position: relative; width: 100%; aspect-ratio: 4/3;
            background: var(--vs-gray-100); overflow: hidden;
        }
        .vs-card-img-wrap img {
            width: 100%; height: 100%; object-fit: cover;
            transition: transform 0.5s ease;
        }
        .vs-card:hover .vs-card-img-wrap img { transform: scale(1.05); }
        
        .vs-card-badge {
            position: absolute; top: 12px; left: 12px;
            background: rgba(255,255,255,0.95); color: var(--vs-black);
            font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 99px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .vs-card-actions {
            position: absolute; top: 12px; right: 12px;
            display: flex; gap: 8px;
        }
        .vs-card-btn {
            width: 32px; height: 32px; border-radius: 50%; border: none;
            background: rgba(255,255,255,0.95); color: var(--vs-gray-500);
            display: flex; align-items: center; justify-content: center; cursor: pointer;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1); transition: all 0.2s;
        }
        .vs-card-btn:hover { color: var(--vs-red); transform: scale(1.1); }
        
        .vs-card-content { padding: 16px; display: flex; flex-direction: column; flex: 1; }
        .vs-card-title {
            font-size: 16px; font-weight: 700; color: var(--vs-black);
            margin: 0 0 6px; line-height: 1.4;
            display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
        }
        .vs-card-address {
            font-size: 13px; color: var(--vs-gray-500); margin: 0 0 12px;
            display: flex; align-items: flex-start; gap: 6px; line-height: 1.5;
        }
        .vs-card-address i { margin-top: 3px; color: var(--vs-gray-500); }
        
        .vs-card-footer {
            margin-top: auto; padding-top: 12px; border-top: 1px solid var(--vs-gray-100);
            display: flex; align-items: center; justify-content: space-between;
        }
        .vs-card-time { font-size: 12px; font-weight: 600; color: var(--vs-gray-800); display: flex; align-items: center; gap: 6px; }
        .vs-card-time i { color: #10b981; }
        
        .vs-btn-book {
            background: var(--vs-red); color: #fff; border: none; border-radius: 10px;
            padding: 8px 14px; font-size: 13px; font-weight: 700; cursor: pointer;
            transition: background 0.2s; text-decoration: none;
        }
        .vs-btn-book:hover { background: var(--vs-red-hover); }

        /* EMPTY STATE */
        .vs-empty-state {
            text-align: center; padding: 60px 20px;
            background: #fff; border-radius: 24px; border: 1px dashed var(--vs-gray-200);
            max-width: 500px; margin: 40px auto;
        }
        .vs-empty-state i { font-size: 48px; color: var(--vs-gray-200); margin-bottom: 16px; }
        .vs-empty-state h3 { font-size: 18px; font-weight: 700; color: var(--vs-black); margin: 0 0 8px; }
        .vs-empty-state p { font-size: 14px; color: var(--vs-gray-500); margin: 0 0 20px; }
        .vs-empty-btn {
            display: inline-flex; align-items: center; justify-content: center;
            background: var(--vs-gray-900); color: #fff; padding: 10px 20px; border-radius: 12px;
            font-size: 14px; font-weight: 600; text-decoration: none; transition: background 0.2s;
        }
        .vs-empty-btn:hover { background: var(--vs-black); }

        /* MODAL OVERLAY */
        .vs-modal-overlay {
            position: fixed; inset: 0; background: rgba(17,24,39,0.7); backdrop-filter: blur(4px);
            z-index: 100; display: flex; align-items: center; justify-content: center;
            opacity: 0; visibility: hidden; transition: all 0.2s ease;
        }
        .vs-modal-overlay.is-open { opacity: 1; visibility: visible; }
        .vs-modal-panel {
            background: #fff; width: 100%; max-width: 440px; border-radius: 24px;
            padding: 24px; transform: translateY(20px); transition: all 0.3s cubic-bezier(0.25,0.8,0.25,1);
            position: relative; margin: 20px;
        }
        .vs-modal-overlay.is-open .vs-modal-panel { transform: translateY(0); }
        .vs-modal-close {
            position: absolute; top: 16px; right: 16px; width: 32px; height: 32px;
            border-radius: 50%; border: none; background: var(--vs-gray-100); cursor: pointer;
            display: flex; align-items: center; justify-content: center; color: var(--vs-gray-500);
        }
        .vs-modal-close:hover { background: var(--vs-gray-200); color: var(--vs-black); }
        .vs-modal-title { font-size: 18px; font-weight: 800; color: var(--vs-black); margin: 0 0 20px; }
        
        .vs-form-group { margin-bottom: 20px; }
        .vs-form-label { display: block; font-size: 13px; font-weight: 700; color: var(--vs-gray-800); margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.5px; }
        
        .vs-radio-list { display: flex; flex-direction: column; gap: 10px; }
        .vs-radio-label {
            display: flex; align-items: center; gap: 10px; padding: 12px 16px;
            border: 1px solid var(--vs-gray-200); border-radius: 12px; cursor: pointer;
            font-size: 14px; font-weight: 600; color: var(--vs-black); transition: all 0.2s;
        }
        .vs-radio-label:hover { background: var(--vs-gray-50); }
        .vs-radio-label:has(input:checked) { border-color: var(--vs-red); background: rgba(255,36,51,0.04); }
        .vs-radio-label input { width: 18px; height: 18px; accent-color: var(--vs-red); }

        .vs-switch-wrapper { display: flex; align-items: center; justify-content: space-between; padding: 12px 0; border-top: 1px solid var(--vs-gray-100); }
        .vs-switch-label { font-size: 14px; font-weight: 600; color: var(--vs-black); }
        .vs-switch { position: relative; display: inline-block; width: 44px; height: 24px; }
        .vs-switch input { opacity: 0; width: 0; height: 0; }
        .vs-slider { position: absolute; cursor: pointer; inset: 0; background-color: #ccc; transition: .4s; border-radius: 24px; }
        .vs-slider:before { position: absolute; content: ""; height: 18px; width: 18px; left: 3px; bottom: 3px; background-color: white; transition: .4s; border-radius: 50%; }
        input:checked + .vs-slider { background-color: var(--vs-red); }
        input:checked + .vs-slider:before { transform: translateX(20px); }

        .vs-modal-actions { display: flex; gap: 12px; margin-top: 24px; }
        .vs-btn-reset { flex: 1; padding: 12px; background: var(--vs-gray-100); color: var(--vs-black); border: none; border-radius: 12px; font-size: 14px; font-weight: 700; cursor: pointer; }
        .vs-btn-reset:hover { background: var(--vs-gray-200); }
        .vs-btn-apply { flex: 2; padding: 12px; background: var(--vs-black); color: #fff; border: none; border-radius: 12px; font-size: 14px; font-weight: 700; cursor: pointer; }
        .vs-btn-apply:hover { background: var(--vs-gray-900); }

    </style>
</head>
<body>
    <jsp:include page="/customer/common/vsport-header.jsp" />

    <!-- PAGE TITLE BAR -->
    <header class="vs-search-header">
        <div class="vsh-left">
            <button class="vsh-back" onclick="goBackOrHome()" aria-label="Quay lại">
                <i class="fa-solid fa-arrow-left"></i>
            </button>
            <h1 class="vsh-title">Khám Phá Sân</h1>
        </div>
        <div class="vsh-right">
            <!-- HISTORY BUTTON -->
            <a href="${ctx}/customer/lich-su-dat-san" class="vsh-btn" title="Lịch sử đặt sân">
                <i class="fa-solid fa-clock-rotate-left"></i>
            </a>
            <!-- MAP BUTTON -->
            <a href="${ctx}/customer/BanDo.jsp" class="vsh-btn vsh-btn-highlight" title="Xem trên bản đồ">
                <i class="fa-solid fa-map-location-dot"></i>
            </a>
        </div>
    </header>

    <!-- SEARCH & FILTER -->
    <form id="tkSearchForm" action="${ctx}/customer/tim-kiem" method="GET">
        <div class="vs-search-container">
            <div class="vs-search-wrapper">
                <div class="vs-search-input-box">
                    <i class="fa-solid fa-magnifying-glass"></i>
                    <input type="text" class="vs-search-input" id="tkSearchInput" name="q" value="<c:out value='${query}'/>" placeholder="Tìm tên sân, cơ sở, địa chỉ..." autocomplete="off">
                    <button type="button" class="vs-search-clear" id="tkClearBtn" <c:if test="${empty query}">style="display:none;"</c:if>>
                        <i class="fa-solid fa-circle-xmark"></i>
                    </button>
                </div>
                <button type="button" class="vs-filter-btn <c:if test='${not empty sportId or openNow}'>has-active</c:if>" onclick="openFilterModal()">
                    <i class="fa-solid fa-sliders"></i> Bộ lọc
                </button>
            </div>
        </div>
        <input type="hidden" name="sportId" id="tkSportIdInput" value="<c:out value='${sportId}'/>"/>
        <input type="hidden" name="openNow" id="tkOpenNowInput" value="<c:if test='${openNow}'>true</c:if>"/>
    </form>

    <!-- CHIPS -->
    <div class="vs-chips-container">
        <div class="vs-chips-wrapper">
            <button type="button" class="vs-chip <c:if test='${empty sportId}'>is-active</c:if>" onclick="selectSport('')">
                <i class="fa-solid fa-border-all"></i> Tất cả
            </button>
            <c:forEach var="m" items="${dsMon}">
                <button type="button" class="vs-chip <c:if test='${sportId == m.monTheThaoID}'>is-active</c:if>" onclick="selectSport('${m.monTheThaoID}')">
                    <c:out value="${m.tenMon}"/>
                </button>
            </c:forEach>
        </div>
    </div>

    <!-- ACTIVE FILTERS -->
    <c:if test="${not empty sportId or openNow}">
        <div class="vs-active-filters">
            <c:if test="${not empty sportId}">
                <c:forEach var="m" items="${dsMon}">
                    <c:if test="${m.monTheThaoID == sportId}">
                        <div class="vs-active-chip">
                            Môn: <c:out value="${m.tenMon}"/>
                            <a href="javascript:void(0)" onclick="removeSportFilter()"><i class="fa-solid fa-xmark"></i></a>
                        </div>
                    </c:if>
                </c:forEach>
            </c:if>
            <c:if test="${openNow}">
                <div class="vs-active-chip">
                    Đang mở cửa
                    <a href="javascript:void(0)" onclick="removeOpenNowFilter()"><i class="fa-solid fa-xmark"></i></a>
                </div>
            </c:if>
            <a href="javascript:void(0)" class="vs-clear-all" onclick="clearAllFilters()">Xóa bộ lọc</a>
        </div>
    </c:if>

    <!-- MAIN RESULTS -->
    <main class="vs-results-container">
        <c:choose>
            <c:when test="${searchError}">
                <div class="vs-empty-state">
                    <i class="fa-solid fa-triangle-exclamation text-red-500"></i>
                    <h3>Không thể tải dữ liệu</h3>
                    <p>Có lỗi xảy ra trong quá trình tìm kiếm. Vui lòng thử lại sau.</p>
                    <a href="${ctx}/customer/tim-kiem" class="vs-empty-btn">Tải lại trang</a>
                </div>
            </c:when>
            <c:when test="${empty results}">
                <div class="vs-empty-state">
                    <i class="fa-solid fa-magnifying-glass-minus"></i>
                    <h3>Không tìm thấy kết quả</h3>
                    <p>Không có sân hoặc cơ sở nào phù hợp với bộ lọc của bạn.</p>
                    <a href="${ctx}/customer/tim-kiem" class="vs-empty-btn">Xóa bộ lọc</a>
                </div>
            </c:when>
            <c:otherwise>
                <div class="vs-results-count">Hiển thị <c:out value="${fn:length(results)}"/> cơ sở phù hợp</div>
                
                <div class="vs-grid">
                    <%
                        @SuppressWarnings("unchecked")
                        List<CoSo> tkResults = (List<CoSo>) request.getAttribute("results");
                        String ctx2 = request.getContextPath();
                        if (tkResults != null) {
                            for (CoSo cs : tkResults) {
                                String csImg = cs.getHinhAnh() != null ? cs.getHinhAnh().trim() : "";
                                String csOpen = cs.getGioMoCua() != null ? cs.getGioMoCua().toString().substring(0,5) : "06:00";
                                String csClose = cs.getGioDongCua() != null ? cs.getGioDongCua().toString().substring(0,5) : "23:00";
                                String businessType = cs.getLoaiHinhKinhDoanh() != null ? cs.getLoaiHinhKinhDoanh() : "";
                                String csName = cs.getTenCoSo() != null ? cs.getTenCoSo() : "";
                                String csNameSafe = csName.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
                                String csAddr = cs.getDiaChi() != null ? cs.getDiaChi() : "Chưa cập nhật địa chỉ";
                                String csAddrSafe = csAddr.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");

                                String fbImgUrl = ctx2 + "/assets/images/home/hero-sports-facility.webp";
                                String cardImgUrl = fbImgUrl;
                                if (csImg.startsWith("http")) {
                                    cardImgUrl = csImg;
                                } else if (csImg.contains("/")) {
                                    String rel = csImg.startsWith("/") ? csImg : "/" + csImg;
                                    cardImgUrl = ctx2 + rel;
                                }

                                String firstSport = businessType.contains(",") ? businessType.substring(0, businessType.indexOf(',')).trim() : businessType.trim();
                                String firstSportSafe = firstSport.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
                    %>
                    <a href="${ctx}/customer/dat-lich-truc-quan?coSoId=<%= cs.getCoSoID() %>" class="vs-card">
                        <div class="vs-card-img-wrap">
                            <img src="<%= cardImgUrl %>" onerror="this.onerror=null;this.src='<%= fbImgUrl %>';" alt="<%= csNameSafe %>">
                            <% if (!firstSport.isEmpty()) { %>
                                <div class="vs-card-badge"><i class="fa-solid fa-medal text-red-500 mr-1"></i> <%= firstSportSafe %></div>
                            <% } %>
                            <div class="vs-card-actions">
                                <button type="button" class="vs-card-btn" title="Yêu thích" onclick="event.preventDefault();"><i class="fa-solid fa-heart"></i></button>
                            </div>
                        </div>
                        <div class="vs-card-content">
                            <h3 class="vs-card-title"><%= csNameSafe %></h3>
                            <p class="vs-card-address"><i class="fa-solid fa-location-dot"></i> <span><%= csAddrSafe %></span></p>
                            
                            <div class="vs-card-footer">
                                <div class="vs-card-time"><i class="fa-solid fa-clock"></i> <%= csOpen %> - <%= csClose %></div>
                                <button type="button" class="vs-btn-book">Đặt lịch</button>
                            </div>
                        </div>
                    </a>
                    <% } } %>
                </div>
            </c:otherwise>
        </c:choose>
    </main>

    <!-- FILTER MODAL -->
    <div class="vs-modal-overlay" id="filterModal">
        <div class="vs-modal-panel">
            <button class="vs-modal-close" onclick="closeFilterModal()"><i class="fa-solid fa-xmark"></i></button>
            <h2 class="vs-modal-title">Bộ lọc chuyên sâu</h2>
            
            <div class="vs-form-group">
                <label class="vs-form-label">Môn thể thao</label>
                <div class="vs-radio-list">
                    <label class="vs-radio-label">
                        <input type="radio" name="modalSportId" value="" <c:if test="${empty sportId}">checked</c:if>>
                        Tất cả môn
                    </label>
                    <c:forEach var="m" items="${dsMon}">
                        <label class="vs-radio-label">
                            <input type="radio" name="modalSportId" value="<c:out value='${m.monTheThaoID}'/>" <c:if test="${sportId == m.monTheThaoID}">checked</c:if>>
                            <c:out value="${m.tenMon}"/>
                        </label>
                    </c:forEach>
                </div>
            </div>

            <div class="vs-switch-wrapper">
                <span class="vs-switch-label">Chỉ hiển thị sân đang mở cửa</span>
                <label class="vs-switch">
                    <input type="checkbox" id="modalOpenNow" <c:if test="${openNow}">checked</c:if>>
                    <span class="vs-slider"></span>
                </label>
            </div>

            <div class="vs-modal-actions">
                <button type="button" class="vs-btn-reset" onclick="resetFilterModal()">Thiết lập lại</button>
                <button type="button" class="vs-btn-apply" onclick="applyFilterModal()">Áp dụng kết quả</button>
            </div>
        </div>
    </div>

    <!-- SCRIPTS -->
    <script>
        const CTX = "${ctx}";
        const searchForm = document.getElementById('tkSearchForm');
        const searchInput = document.getElementById('tkSearchInput');
        const clearBtn = document.getElementById('tkClearBtn');
        const sportIdInput = document.getElementById('tkSportIdInput');
        const openNowInput = document.getElementById('tkOpenNowInput');
        const filterModal = document.getElementById('filterModal');

        // Back button logic
        function goBackOrHome() {
            try {
                if (document.referrer && new URL(document.referrer).origin === window.location.origin) {
                    history.back(); return;
                }
            } catch(e) {}
            window.location.href = CTX + '/index.jsp';
        }

        // Search Input Logic
        searchInput.addEventListener('input', () => {
            clearBtn.style.display = searchInput.value ? 'block' : 'none';
        });
        clearBtn.addEventListener('click', () => {
            searchInput.value = '';
            clearBtn.style.display = 'none';
            searchInput.focus();
        });

        // Quick chip selection
        function selectSport(id) {
            sportIdInput.value = id;
            searchForm.submit();
        }

        // Remove active filters
        function removeSportFilter() { sportIdInput.value = ''; searchForm.submit(); }
        function removeOpenNowFilter() { openNowInput.value = ''; searchForm.submit(); }
        function clearAllFilters() { sportIdInput.value = ''; openNowInput.value = ''; searchForm.submit(); }

        // Modal Logic
        function openFilterModal() { filterModal.classList.add('is-open'); document.body.style.overflow = 'hidden'; }
        function closeFilterModal() { filterModal.classList.remove('is-open'); document.body.style.overflow = ''; }
        
        filterModal.addEventListener('click', (e) => {
            if (e.target === filterModal) closeFilterModal();
        });

        function resetFilterModal() {
            document.querySelector('input[name="modalSportId"][value=""]').checked = true;
            document.getElementById('modalOpenNow').checked = false;
        }

        function applyFilterModal() {
            const selectedSport = document.querySelector('input[name="modalSportId"]:checked');
            sportIdInput.value = selectedSport ? selectedSport.value : '';
            openNowInput.value = document.getElementById('modalOpenNow').checked ? 'true' : '';
            searchForm.submit();
        }

        // Auto submit on typing (debounced)
        let debounceTimer;
        searchInput.addEventListener('input', () => {
            clearTimeout(debounceTimer);
            debounceTimer = setTimeout(() => { searchForm.submit(); }, 600);
        });
    </script>
    <jsp:include page="/customer/common/vsport-footer.jsp" />
</body>
</html>
