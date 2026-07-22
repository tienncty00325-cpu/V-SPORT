<%@ page contentType="text/html;charset=UTF-8" language="java" %>
    <%@ page import="org.example.model.TaiKhoan" %>
        <%
            String vsNavPath = request.getRequestURI().substring(request.getContextPath().length());
            boolean vsNavBanDo = vsNavPath.startsWith("/customer/BanDo.jsp") || vsNavPath.startsWith("/customer/ban-do");
            boolean vsNavDatSan = vsNavPath.startsWith("/customer/dat-san") || vsNavPath.startsWith("/customer/tim-kiem");
            boolean vsNavGhepKeo = vsNavPath.startsWith("/customer/ghep-keo");
            boolean vsNavDichVu = vsNavPath.startsWith("/customer/dich-vu");
        %>
        <header class="header">
            <div class="top-header">
                <div class="container">
                    <div class="header-main">
                        <a href="${pageContext.request.contextPath}/" class="logo">
                            <i class="fa-solid fa-basket-shopping"></i>
                            V-<span>SPORT</span>
                        </a>

                        <div class="search-bar">
                            <form action="${pageContext.request.contextPath}/customer/tim-kiem" method="GET">
                                <input type="text" name="q" placeholder="Tìm tên sân, cơ sở, địa chỉ..." value="${not empty query ? query : ''}">
                                <button type="submit"><i class="fas fa-search"></i></button>
                            </form>
                        </div>

                        <div class="header-actions">
                            <div class="call-center">
                                <div class="call-icon">
                                    <i class="fas fa-phone-alt"></i>
                                </div>
                                <div class="call-text">
                                    <span>Call Center</span>
                                    <strong>818-555 67 88</strong>
                                </div>
                            </div>

                            <div class="action-icons">
                                <a href="${pageContext.request.contextPath}/customer/gio-hang" class="icon-btn">
                                    <i class="fas fa-shopping-basket"></i>
                                    <span class="badge" id="header-cart-badge" style="opacity: 0; transition: opacity 0.2s;">0</span>
                                </a>
                                <a href="#" class="icon-btn">
                                    <i class="far fa-heart"></i>
                                    <span class="badge">0</span>
                                </a>
                                <% TaiKhoan user=(TaiKhoan) session.getAttribute("user"); if (user !=null) { %>
                                    <a href="${pageContext.request.contextPath}/customer/tai-khoan" class="icon-btn"
                                        style="width: auto; padding: 0 15px; gap: 8px; border-radius: 20px;">
                                        <i class="far fa-user"></i>
                                        <span style="font-size: 14px; font-weight: 600;">
                                            <%= user.getFullName() %>
                                        </span>
                                    </a>
                                    <% } else { %>
                                        <a href="#auth" class="icon-btn" id="authBtn">
                                            <i class="far fa-user"></i>
                                        </a>
                                        <% } %>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Navigation -->
            <div class="bottom-header">
                <div class="container">
                    <div class="nav-inner">
                        <nav class="main-nav">
                            <ul>
                                <li><a href="${pageContext.request.contextPath}/customer/BanDo.jsp" class="nav-category<%= vsNavBanDo ? " nav-active" : "" %>" style="gap: 8px;"><i class="fas fa-map-marked-alt"></i>Bản đồ</a></li>
                                <li><a href="${pageContext.request.contextPath}/customer/dat-san" class="<%= vsNavDatSan ? "nav-active" : "" %>">Đặt sân</a></li>
                                <li><a href="${pageContext.request.contextPath}/customer/ghep-keo" class="<%= vsNavGhepKeo ? "nav-active" : "" %>">Ghép Kèo<span class="hot-badge">HOT</span></a></li>
                                <li><a href="${pageContext.request.contextPath}/customer/dich-vu" class="<%= vsNavDichVu ? "nav-active" : "" %>">Cửa hàng &amp; Dịch vụ</a></li>
                                <li><a href="#">Tin tức <i class="fas fa-angle-down"></i></a></li>
                            </ul>
                        </nav>
                    </div>
                </div>
            </div>
        </header>
        <script>
            document.addEventListener("DOMContentLoaded", function() {
                fetch('${pageContext.request.contextPath}/customer/api/cart-count')
                    .then(response => response.json())
                    .then(data => {
                        if (data && data.count !== undefined) {
                            const badge = document.getElementById('header-cart-badge');
                            if (badge) {
                                badge.textContent = data.count;
                                badge.style.opacity = '1';
                            }
                        }
                    })
                    .catch(e => console.error("Error loading cart count", e));
            });
        </script>