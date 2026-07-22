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
    <jsp:include page="/common/xtra-head.jsp" />
    <title>Tìm kiếm sân - V-SPORT</title>
    <style>
        body { background-color: var(--background); }
        
        .main-content {
            padding: 40px 0 80px;
        }

        /* Chips */
        .filter-chips {
            display: flex;
            gap: 12px;
            overflow-x: auto;
            padding-bottom: 20px;
            margin-bottom: 20px;
        }
        .filter-chips::-webkit-scrollbar { display: none; }
        .chip {
            padding: 10px 24px;
            border-radius: 50px;
            border: 1px solid var(--border);
            background-color: var(--surface);
            color: var(--body-text);
            font-family: 'Outfit', sans-serif;
            font-weight: 600;
            cursor: pointer;
            transition: var(--transition);
            white-space: nowrap;
        }
        .chip:hover {
            border-color: var(--navy);
            color: var(--navy);
        }
        .chip.active {
            background-color: var(--navy);
            border-color: var(--navy);
            color: var(--surface);
        }

        .active-filters {
            display: flex;
            gap: 10px;
            align-items: center;
            margin-bottom: 30px;
        }
        .active-chip {
            background-color: rgba(18, 45, 64, 0.1);
            color: var(--navy);
            padding: 6px 16px;
            border-radius: 50px;
            font-size: 13px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .active-chip a { color: var(--navy); }
        .active-chip a:hover { opacity: 0.7; }
        .clear-filters {
            font-size: 14px;
            color: var(--muted-text);
            text-decoration: underline;
        }
        .clear-filters:hover { color: var(--danger); }

        /* Facility Card */
        .facility-card {
            background-color: var(--surface);
            border-radius: var(--radius-large);
            overflow: hidden;
            box-shadow: var(--shadow-small);
            transition: var(--transition);
            display: flex;
            flex-direction: column;
            height: 100%;
            cursor: pointer;
        }
        .facility-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--shadow-large);
        }
        .facility-card:focus-visible {
            outline: 3px solid var(--primary);
            outline-offset: 2px;
        }
        .fc-image {
            position: relative;
            height: 200px;
            overflow: hidden;
        }
        .fc-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transition: transform 0.5s ease;
        }
        .facility-card:hover .fc-image img {
            transform: scale(1.05);
        }
        .fc-badge {
            position: absolute;
            top: 15px;
            left: 15px;
            background-color: var(--primary);
            color: var(--navy);
            font-size: 12px;
            font-weight: 700;
            padding: 4px 12px;
            border-radius: 20px;
            box-shadow: var(--shadow-small);
        }
        .fc-content {
            padding: 20px;
            flex: 1;
            display: flex;
            flex-direction: column;
        }
        .fc-title {
            font-size: 18px;
            font-weight: 700;
            margin-bottom: 10px;
            color: var(--navy);
            line-height: 1.4;
        }
        .fc-address {
            font-size: 14px;
            color: var(--muted-text);
            margin-bottom: 15px;
            display: flex;
            align-items: flex-start;
            gap: 8px;
        }
        .fc-address i { margin-top: 3px; color: var(--primary); }
        .fc-footer {
            margin-top: auto;
            padding-top: 15px;
            border-top: 1px dashed var(--border);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .fc-time {
            font-size: 13px;
            font-weight: 600;
            color: var(--body-text);
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .fc-time i { color: var(--primary); }
        
        /* Empty State */
        .empty-state {
            text-align: center;
            padding: 80px 20px;
            background: var(--surface);
            border-radius: var(--radius-large);
            margin-bottom: 60px;
        }
        .empty-state i {
            font-size: 64px;
            color: var(--border);
            margin-bottom: 20px;
        }
        .empty-state h3 {
            font-size: 24px;
            color: var(--navy);
            margin-bottom: 10px;
        }
        .empty-state p {
            color: var(--muted-text);
            margin-bottom: 20px;
        }

        /* Modal */
        .modal-overlay {
            position: fixed; inset: 0; background: rgba(18, 45, 64, 0.8);
            backdrop-filter: blur(4px); z-index: 1000;
            display: flex; align-items: center; justify-content: center;
            opacity: 0; visibility: hidden; transition: var(--transition);
        }
        .modal-overlay.is-open { opacity: 1; visibility: visible; }
        .modal-panel {
            background: var(--surface); width: 100%; max-width: 450px;
            border-radius: var(--radius-large); padding: 30px;
            transform: translateY(20px); transition: var(--transition);
        }
        .modal-overlay.is-open .modal-panel { transform: translateY(0); }
        .modal-close {
            position: absolute; top: 20px; right: 20px;
            background: none; border: none; font-size: 20px;
            color: var(--muted-text); cursor: pointer;
        }
        .modal-close:hover { color: var(--danger); }
        
        .modal-title { font-size: 24px; color: var(--navy); margin-bottom: 25px; }
        .form-group { margin-bottom: 20px; }
        .form-label { display: block; font-size: 14px; font-weight: 700; color: var(--navy); margin-bottom: 15px; }
        
        .radio-list { display: flex; flex-direction: column; gap: 10px; }
        .radio-label {
            display: flex; align-items: center; gap: 10px; padding: 12px 16px;
            border: 1px solid var(--border); border-radius: var(--radius-medium);
            cursor: pointer; font-size: 15px; font-weight: 500; transition: var(--transition);
        }
        .radio-label:hover { border-color: var(--primary); }
        .radio-label:has(input:checked) { border-color: var(--primary); background-color: rgba(1,226,129,0.05); }
        
        .switch-wrapper { display: flex; justify-content: space-between; align-items: center; padding-top: 15px; border-top: 1px solid var(--border); }
        .modal-actions { display: flex; gap: 15px; margin-top: 30px; }
        
    </style>
</head>
<body>
    <jsp:include page="/common/header-xtra.jsp" />

    <main class="main-content container">
        <div class="products-header">
            <h2 class="section-title">Khám Phá Sân</h2>
        </div>
        
        <form id="tkSearchForm" action="${ctx}/customer/tim-kiem" method="GET">
            <input type="hidden" name="q" value="<c:out value='${query}'/>">
            
            <div class="filter-chips">
                <button type="button" class="chip <c:if test='${empty sportId}'>active</c:if>" onclick="selectSport('')">
                    Tất cả
                </button>
                <c:forEach var="m" items="${dsMon}">
                    <button type="button" class="chip <c:if test='${sportId == m.monTheThaoID}'>active</c:if>" onclick="selectSport('${m.monTheThaoID}')">
                        <c:out value="${m.tenMon}"/>
                    </button>
                </c:forEach>
            </div>

            <c:if test="${not empty sportId or openNow}">
                <div class="active-filters">
                    <c:if test="${not empty sportId}">
                        <c:forEach var="m" items="${dsMon}">
                            <c:if test="${m.monTheThaoID == sportId}">
                                <div class="active-chip">
                                    Môn: <c:out value="${m.tenMon}"/>
                                    <a href="javascript:void(0)" onclick="removeSportFilter()"><i class="fa-solid fa-xmark"></i></a>
                                </div>
                            </c:if>
                        </c:forEach>
                    </c:if>
                    <c:if test="${openNow}">
                        <div class="active-chip">
                            Đang mở cửa
                            <a href="javascript:void(0)" onclick="removeOpenNowFilter()"><i class="fa-solid fa-xmark"></i></a>
                        </div>
                    </c:if>
                    <a href="javascript:void(0)" class="clear-filters" onclick="clearAllFilters()">Xóa bộ lọc</a>
                </div>
            </c:if>

            <input type="hidden" name="sportId" id="tkSportIdInput" value="<c:out value='${sportId}'/>"/>
            <input type="hidden" name="openNow" id="tkOpenNowInput" value="<c:if test='${openNow}'>true</c:if>"/>
        </form>

        <c:choose>
            <c:when test="${searchError}">
                <div class="empty-state">
                    <i class="fa-solid fa-triangle-exclamation" style="color: var(--danger);"></i>
                    <h3>Đã có lỗi xảy ra</h3>
                    <p>Không thể tải dữ liệu tìm kiếm. Vui lòng thử lại sau.</p>
                    <a href="${ctx}/customer/tim-kiem" class="btn btn-primary">Tải lại trang</a>
                </div>
            </c:when>
            <c:when test="${empty results}">
                <div class="empty-state">
                    <i class="fa-solid fa-magnifying-glass-minus"></i>
                    <h3>Không tìm thấy kết quả</h3>
                    <p>Thử điều chỉnh bộ lọc hoặc từ khóa tìm kiếm của bạn.</p>
                    <a href="${ctx}/customer/tim-kiem" class="btn btn-primary">Xóa bộ lọc</a>
                </div>
            </c:when>
            <c:otherwise>
                <div class="product-grid" id="facilityGrid">
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
                    <div class="facility-card" tabindex="0" role="button"
                         aria-label="Xem chi tiết <%= csNameSafe %>"
                         data-coso-id="<%= cs.getCoSoID() %>"
                         data-facility-name="<%= csNameSafe %>"
                         data-card-image="<%= cardImgUrl %>">
                        <div class="fc-image">
                            <img src="<%= cardImgUrl %>" onerror="this.onerror=null;this.src='<%= fbImgUrl %>';" alt="<%= csNameSafe %>">
                            <% if (!firstSport.isEmpty()) { %>
                                <div class="fc-badge"><i class="fa-solid fa-medal"></i> <%= firstSportSafe %></div>
                            <% } %>
                        </div>
                        <div class="fc-content">
                            <h3 class="fc-title"><%= csNameSafe %></h3>
                            <p class="fc-address"><i class="fa-solid fa-location-dot"></i> <span><%= csAddrSafe %></span></p>

                            <div class="fc-footer">
                                <div class="fc-time"><i class="fa-solid fa-clock"></i> <%= csOpen %> - <%= csClose %></div>
                                <button type="button" class="btn btn-primary" style="padding: 8px 16px; font-size: 13px;"
                                        data-book-trigger
                                        data-coso-id="<%= cs.getCoSoID() %>"
                                        data-facility-name="<%= csNameSafe %>">Đặt lịch</button>
                            </div>
                        </div>
                    </div>
                    <% } } %>
                </div>
            </c:otherwise>
        </c:choose>
    </main>

    <!-- Footer -->
    <footer class="footer">
        <div class="container">
            <div class="footer-grid">
                <!-- Col 1 -->
                <div class="footer-col">
                    <a href="${ctx}/" class="logo" style="margin-bottom: 25px;">
                        <i class="fa-solid fa-basket-shopping"></i>
                        V-<span>SPORT</span>
                    </a>
                    <p>Nền tảng đặt sân thể thao trực tuyến, kết nối bạn với hàng trăm cơ sở uy tín trên toàn quốc.</p>
                    <div class="social-icons">
                        <a href="#"><i class="fab fa-facebook-f"></i></a>
                        <a href="#"><i class="fab fa-twitter"></i></a>
                        <a href="#"><i class="fab fa-instagram"></i></a>
                        <a href="#"><i class="fab fa-youtube"></i></a>
                    </div>
                </div>

                <!-- Col 2 -->
                <div class="footer-col">
                    <h4>Liên kết hữu ích</h4>
                    <ul class="footer-links">
                        <li><a href="#">Về chúng tôi</a></li>
                        <li><a href="#">Câu hỏi thường gặp</a></li>
                        <li><a href="#">Trung tâm hỗ trợ</a></li>
                        <li><a href="#">Điều khoản dịch vụ</a></li>
                        <li><a href="#">Chính sách bảo mật</a></li>
                        <li><a href="#">Chính sách hoàn tiền</a></li>
                    </ul>
                </div>

                <!-- Col 3 -->
                <div class="footer-col">
                    <h4>Liên hệ</h4>
                    <ul class="contact-info">
                        <li>
                            <i class="fas fa-phone-alt"></i>
                            <div>
                                <span style="font-size: 13px; display: block;">Gọi cho chúng tôi 24/7</span>
                                <a href="tel:8185556788">818-555 67 88</a>
                            </div>
                        </li>
                        <li>
                            <i class="fas fa-envelope"></i>
                            <div>
                                <span style="font-size: 13px; display: block;">Email cho chúng tôi</span>
                                <a href="mailto:info@vsport.com" style="font-size: 15px; font-weight: 400; font-family: 'Inter', sans-serif;">info@vsport.com</a>
                            </div>
                        </li>
                    </ul>
                </div>

                <!-- Col 4 -->
                <div class="footer-col">
                    <h4>Hợp tác kinh doanh</h4>
                    <p>Bạn có sân thể thao? Hãy trở thành đối tác của V-SPORT.</p>
                    <a href="#" class="btn btn-primary">Trở thành đối tác</a>
                </div>
            </div>

            <div class="footer-bottom">
                <div class="copyright">
                    &copy; 2026 V-SPORT. All Rights Reserved.
                </div>
                <div class="payments">
                    <div class="payment-card"><i class="fab fa-cc-visa" style="color: #1434CB; font-size: 24px;"></i></div>
                    <div class="payment-card"><i class="fab fa-cc-mastercard" style="color: #EB001B; font-size: 24px;"></i></div>
                    <div class="payment-card"><i class="fab fa-cc-paypal" style="color: #00457C; font-size: 24px;"></i></div>
                    <div class="payment-card"><i class="fab fa-cc-discover" style="color: #F9A021; font-size: 24px;"></i></div>
                </div>
            </div>
        </div>
    </footer>

    <!-- Modal -->
    <div class="modal-overlay" id="filterModal">
        <div class="modal-panel">
            <button class="modal-close" onclick="closeFilterModal()"><i class="fa-solid fa-xmark"></i></button>
            <h2 class="modal-title">Bộ lọc chuyên sâu</h2>
            
            <div class="form-group">
                <label class="form-label">Môn thể thao</label>
                <div class="radio-list">
                    <label class="radio-label">
                        <input type="radio" name="modalSportId" value="" <c:if test="${empty sportId}">checked</c:if>>
                        Tất cả môn
                    </label>
                    <c:forEach var="m" items="${dsMon}">
                        <label class="radio-label">
                            <input type="radio" name="modalSportId" value="<c:out value='${m.monTheThaoID}'/>" <c:if test="${sportId == m.monTheThaoID}">checked</c:if>>
                            <c:out value="${m.tenMon}"/>
                        </label>
                    </c:forEach>
                </div>
            </div>

            <div class="switch-wrapper">
                <label class="form-label" style="margin-bottom:0;">Chỉ hiển thị sân đang mở cửa</label>
                <input type="checkbox" id="modalOpenNow" style="width: 20px; height: 20px; accent-color: var(--primary);" <c:if test="${openNow}">checked</c:if>>
            </div>

            <div class="modal-actions">
                <button type="button" class="btn btn-outline" style="border-color: var(--border); color: var(--navy); width: 100%;" onclick="resetFilterModal()">Thiết lập lại</button>
                <button type="button" class="btn btn-primary" style="width: 100%;" onclick="applyFilterModal()">Áp dụng</button>
            </div>
        </div>
    </div>

    <script>
        const searchForm = document.getElementById('tkSearchForm');
        const sportIdInput = document.getElementById('tkSportIdInput');
        const openNowInput = document.getElementById('tkOpenNowInput');
        const filterModal = document.getElementById('filterModal');

        function selectSport(id) {
            sportIdInput.value = id;
            searchForm.submit();
        }
        function removeSportFilter() { sportIdInput.value = ''; searchForm.submit(); }
        function removeOpenNowFilter() { openNowInput.value = ''; searchForm.submit(); }
        function clearAllFilters() { sportIdInput.value = ''; openNowInput.value = ''; searchForm.submit(); }

        function openFilterModal() { filterModal.classList.add('is-open'); document.body.style.overflow = 'hidden'; }
        function closeFilterModal() { filterModal.classList.remove('is-open'); document.body.style.overflow = ''; }
        filterModal.addEventListener('click', (e) => { if (e.target === filterModal) closeFilterModal(); });

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
    </script>

    <jsp:include page="/customer/common/facility-interactions.jsp" />

    <script>
        // Deep link: /customer/tim-kiem?coSoId=7 reopens the facility detail sheet
        // on load, reusing the exact same open path as a card click (so history
        // push/pop stays consistent). Silently no-ops if the id isn't on this page.
        (function () {
            var coSoId = new URLSearchParams(window.location.search).get('coSoId');
            if (!coSoId) return;
            var grid = document.getElementById('facilityGrid');
            if (!grid) return;
            var card = grid.querySelector('.facility-card[data-coso-id="' + CSS.escape(coSoId) + '"]');
            if (card && typeof window.openFacilitySheet === 'function') {
                window.openFacilitySheet(card);
            }
        })();
    </script>
</body>
</html>
