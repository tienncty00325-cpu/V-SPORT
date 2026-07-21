<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<% String ctxPath = request.getContextPath(); %>
    <!-- Footer -->
    <footer class="site-footer">
        <div class="container footer-grid">
            <!-- Column 1 -->
            <div class="footer-col widget-about">
                <div class="footer-logo">
                    <a href="<%= ctxPath %>/">
                        V<span class="logo-icon"><i class="fa-solid fa-bolt text-red" style="margin: 0 5px;"></i></span>SPORT
                    </a>
                </div>
                <p class="about-text">Nền tảng đặt sân online, quản lý lịch sân và ghép trận thể thao lớn nhất dành cho cộng đồng người chơi.</p>
                <div class="contact-info">
                    <div class="contact-item">
                        <span class="label text-red">TỔNG ĐÀI HỖ TRỢ</span>
                        <a href="tel:19001234" class="value">1900 1234</a>
                    </div>
                    <div class="contact-item">
                        <span class="label text-red">EMAIL LIÊN HỆ</span>
                        <a href="mailto:contact@v-sport.vn" class="value">contact@v-sport.vn</a>
                    </div>
                </div>
            </div>

            <!-- Column 2 -->
            <div class="footer-col widget-links">
                <h3 class="widget-title">Truy cập nhanh</h3>
                <ul>
                    <li><a href="<%= ctxPath %>/"><i class="fa-solid fa-angle-right"></i> Trang chủ</a></li>
                    <li><a href="<%= ctxPath %>/customer/dat-san"><i class="fa-solid fa-angle-right"></i> Tìm sân trống</a></li>
                    <li><a href="<%= ctxPath %>/customer/ghep-keo"><i class="fa-solid fa-angle-right"></i> Ghép trận</a></li>
                    <li><a href="#"><i class="fa-solid fa-angle-right"></i> Bảng giá</a></li>
                    <li><a href="#"><i class="fa-solid fa-angle-right"></i> Tin tức thể thao</a></li>
                    <li><a href="#"><i class="fa-solid fa-angle-right"></i> Liên hệ</a></li>
                </ul>
            </div>

            <!-- Column 3 -->
            <div class="footer-col widget-links">
                <h3 class="widget-title">Dịch vụ</h3>
                <ul>
                    <li><a href="<%= ctxPath %>/customer/dat-san"><i class="fa-solid fa-angle-right"></i> Đặt sân online</a></li>
                    <li><a href="#"><i class="fa-solid fa-angle-right"></i> Quản lý CLB</a></li>
                    <li><a href="#"><i class="fa-solid fa-angle-right"></i> Tổ chức giải đấu</a></li>
                    <li><a href="<%= ctxPath %>/customer/ghep-keo"><i class="fa-solid fa-angle-right"></i> Tìm người chơi</a></li>
                    <li><a href="#"><i class="fa-solid fa-angle-right"></i> Đánh giá sân bãi</a></li>
                    <li><a href="#"><i class="fa-solid fa-angle-right"></i> Thanh toán linh hoạt</a></li>
                </ul>
            </div>

            <!-- Column 4 -->
            <div class="footer-col widget-gallery">
                <h3 class="widget-title">Thư viện ảnh</h3>
                <div class="gallery-grid">
                    <a href="#" class="gallery-item"><img src="<%= ctxPath %>/assets/images/vsport/gallery/gallery-football-01.jpg" alt="Gallery" onerror="this.src='<%= ctxPath %>/assets/images/home/sport-football.webp'"></a>
                    <a href="#" class="gallery-item"><img src="<%= ctxPath %>/assets/images/vsport/gallery/gallery-football-02.jpg" alt="Gallery" onerror="this.src='<%= ctxPath %>/assets/images/home/sport-badminton.webp'"></a>
                    <a href="#" class="gallery-item"><img src="<%= ctxPath %>/assets/images/vsport/gallery/gallery-football-03.jpg" alt="Gallery" onerror="this.src='<%= ctxPath %>/assets/images/home/sport-tennis.webp'"></a>
                    <a href="#" class="gallery-item"><img src="<%= ctxPath %>/assets/images/vsport/gallery/gallery-football-04.jpg" alt="Gallery" onerror="this.src='<%= ctxPath %>/assets/images/home/sport-pickleball.webp'"></a>
                </div>
            </div>
        </div>

        <div class="footer-bottom">
            <div class="container bottom-content">
                <div class="copyright">
                    <p>&copy; Copyright 2026 <span class="text-red">V-SPORT</span>. All Rights Reserved.</p>
                </div>
                <div class="social-links">
                    <a href="#"><i class="fa-brands fa-facebook-f"></i></a>
                    <a href="#"><i class="fa-brands fa-twitter"></i></a>
                    <a href="#"><i class="fa-brands fa-linkedin-in"></i></a>
                    <a href="#"><i class="fa-brands fa-instagram"></i></a>
                </div>
            </div>
        </div>
    </footer>

    <!-- Custom JS -->
    <script src="<%= ctxPath %>/assets/js/vsport-customer.js"></script>
    <jsp:include page="/auth/AuthModal.jsp" />
</body>
</html>
