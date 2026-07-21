<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>V-SPORT - Nền Tảng Đặt Sân Thể Thao Chuyên Nghiệp</title>
    
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800;900&family=Montserrat:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    
    <!-- FontAwesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <!-- Custom CSS -->
    <link rel="stylesheet" href="assets/css/vsport-customer.css">
    <link rel="stylesheet" href="assets/css/vsport-home-enhanced.css">
</head>
<body>

    <!-- Toast Container -->
    <div id="toast-container"></div>

    <!-- Top Contact Bar -->
    <div class="top-bar">
        <div class="container">
            <div class="top-bar-left">
                <span><i class="fa-solid fa-phone"></i> Hỗ trợ: 1900 1234</span>
                <span class="divider">|</span>
                <span><i class="fa-solid fa-envelope"></i> contact@v-sport.vn</span>
            </div>
            <div class="top-bar-right">
                <a href="#">Tải Ứng Dụng</a>
                <span class="divider">|</span>
                <a href="#">Trở thành đối tác</a>
                <span class="divider">|</span>
                <% if (session != null && session.getAttribute("user") != null) {
                    org.example.model.TaiKhoan user = (org.example.model.TaiKhoan) session.getAttribute("user");
                    String displayName = (user.getFullName() != null && !user.getFullName().trim().isEmpty()) ? user.getFullName() : "Khách hàng";
                    String rolePath = org.example.util.RoleRedirectUtil.getHomePathByRoleId(user.getRoleId());
                %>
                    <div class="user-profile-menu" style="display:inline-flex; align-items:center; gap: 8px;">
                        <i class="fa-solid fa-circle-user" style="font-size: 16px; color: var(--accent-red, #ff2433);"></i>
                        <a href="${pageContext.request.contextPath}<%= rolePath %>" style="font-weight: 600;"><%= displayName %></a>
                        <span class="divider">|</span>
                        <a href="${pageContext.request.contextPath}/logout">Đăng xuất</a>
                    </div>
                <% } else { %>
                    <a href="javascript:void(0)" onclick="openAuthModal('login')">Đăng nhập</a>
                    <a href="javascript:void(0)" onclick="openAuthModal('register')" class="btn-register-topbar">Đăng ký</a>
                <% } %>
            </div>
        </div>
    </div>

    <!-- Main Navbar -->
    <header class="navbar">
        <div class="container">
            <div class="logo">
                <a href="#">
                    V<span class="logo-icon"><i class="fa-solid fa-bolt text-red" style="margin: 0 5px;"></i></span>SPORT
                </a>
            </div>
            <nav class="main-menu">
                <ul>
                    <li class="active"><a href="#">TRANG CHỦ</a></li>
                    <li><a href="${pageContext.request.contextPath}/customer/tim-kiem">TÌM SÂN</a></li>
                    <li><a href="#matchmaking">GHÉP TRẬN</a></li>
                    <li><a href="#trusted-players">CỘNG ĐỒNG</a></li>
                    <li><a href="#">BẢNG GIÁ</a></li>
                </ul>
            </nav>
            <div class="nav-actions">
                <a href="#" class="action-icon"><i class="fa-solid fa-magnifying-glass"></i></a>
                <a href="#" class="action-icon cart-icon">
                    <i class="fa-solid fa-bell"></i>
                    <span class="cart-badge">2</span>
                </a>
                <a href="${pageContext.request.contextPath}/customer/tim-kiem" class="btn-primary btn-ripple" style="padding: 10px 20px; font-size: 13px;">Đặt Sân</a>
            </div>
        </div>
    </header>

    <!-- Marquee Strip -->
    <div class="marquee-container">
        <div class="marquee-content">
            <span><i class="fa-solid fa-bolt"></i> Đặt sân nhanh</span>
            <span><i class="fa-solid fa-users"></i> Ghép trận dễ dàng</span>
            <span><i class="fa-solid fa-shield-check"></i> Uy tín minh bạch</span>
            <span><i class="fa-solid fa-clock"></i> Check-in đúng giờ</span>
            <span><i class="fa-solid fa-fire"></i> Cộng đồng thể thao lớn nhất</span>
            <!-- Repeat for seamless loop -->
            <span><i class="fa-solid fa-bolt"></i> Đặt sân nhanh</span>
            <span><i class="fa-solid fa-users"></i> Ghép trận dễ dàng</span>
            <span><i class="fa-solid fa-shield-check"></i> Uy tín minh bạch</span>
            <span><i class="fa-solid fa-clock"></i> Check-in đúng giờ</span>
            <span><i class="fa-solid fa-fire"></i> Cộng đồng thể thao lớn nhất</span>
        </div>
    </div>

    <!-- Hero Banner (Enhanced) -->
    <section class="hero-banner" style="background: linear-gradient(135deg, rgba(17,17,17,0.95) 0%, rgba(135,15,23,0.85) 100%), url('assets/images/vsport/hero/hero-bg.jpg') center/cover fixed;">
        <div class="hero-overlay"></div>
        <div class="container hero-content">
            <div class="hero-text reveal">
                <h1>Đặt Sân Nhanh,<br><span class="text-red" style="position:relative;">Ghép Trận Dễ Dàng<span style="position:absolute; bottom:-5px; left:0; width:100%; height:4px; background:var(--accent-red); border-radius:2px;"></span></span></h1>
                <p>Nền tảng tìm sân trống theo giờ, xem đánh giá thực tế và kết nối với hàng ngàn người chơi cùng trình độ trong khu vực của bạn.</p>
                <div class="hero-btns">
                    <a href="${pageContext.request.contextPath}/customer/tim-kiem" class="btn-primary btn-ripple">Tìm Sân Trống</a>
                    <a href="#matchmaking" class="btn-secondary btn-ripple">Ghép Trận Ngay</a>
                </div>
            </div>
            
            <div class="hero-visual reveal stagger-1">
                <img src="assets/images/vsport/hero/hero-player.jpg" alt="Thể thao" class="hero-main-img parallax-el" data-speed="2">
                
                <div class="fc-enhanced fc-e1 parallax-el" data-speed="1.5">
                    <div class="fc-icon"><i class="fa-solid fa-check"></i></div>
                    Sân trống gần bạn
                </div>
                <div class="fc-enhanced fc-e2 parallax-el" data-speed="-1">
                    <div class="fc-icon"><i class="fa-solid fa-users"></i></div>
                    Ghép trận 5v5
                </div>
                <div class="fc-enhanced fc-e3 parallax-el" data-speed="2.5">
                    <div class="fc-icon"><i class="fa-solid fa-shield"></i></div>
                    Uy tín 98/100
                </div>
            </div>
        </div>
    </section>

    <!-- Quick Booking Bar -->
    <section id="quick-booking" class="quick-booking-section">
        <div class="container">
            <form action="${pageContext.request.contextPath}/customer/tim-kiem" method="GET" class="quick-booking-bar reveal tilt-card">
                <div class="booking-field">
                    <label><i class="fa-solid fa-volleyball text-red"></i> Môn Thể Thao</label>
                    <select name="sportId">
                        <option value="">Tất cả</option>
                        <option value="1">Bóng đá</option>
                        <option value="2">Cầu lông</option>
                        <option value="3">Tennis</option>
                        <option value="4">Pickleball</option>
                    </select>
                </div>
                <div class="booking-field">
                    <label><i class="fa-solid fa-location-dot text-red"></i> Khu Vực</label>
                    <input type="text" name="q" placeholder="Nhập tên sân, khu vực..." style="border:1px solid #ddd; padding:8px; border-radius:8px; width:100%; outline:none;">
                </div>
                <div class="booking-field">
                    <label><i class="fa-solid fa-calendar-day text-red"></i> Ngày Chơi</label>
                    <input type="date" value="2026-07-21">
                </div>
                <div class="booking-field">
                    <label><i class="fa-solid fa-clock text-red"></i> Giờ Bắt Đầu</label>
                    <select><option>17:00</option><option>18:00</option><option>19:00</option><option>20:00</option></select>
                </div>
                <button type="submit" class="btn-search btn-ripple"><i class="fa-solid fa-magnifying-glass"></i> Tìm Sân Trống</button>
            </form>
        </div>
    </section>

    <!-- Sport Categories -->
    <section class="section-padding">
        <div class="container">
            <div class="section-heading reveal">
                <div class="sub-title"><span class="line"></span><span class="text">DANH MỤC</span><span class="line"></span></div>
                <h2>Bạn Muốn Chơi Môn Gì Hôm Nay?</h2>
            </div>
            <div class="categories-grid reveal">
                <div class="category-card tilt-card">
                    <img src="assets/images/vsport/categories/football.jpg" loading="lazy" alt="Bóng đá">
                    <div class="category-overlay">
                        <i class="fa-regular fa-futbol category-icon"></i>
                        <span class="category-name">Bóng đá</span>
                    </div>
                </div>
                <div class="category-card tilt-card">
                    <img src="assets/images/vsport/categories/badminton.jpg" loading="lazy" alt="Cầu lông">
                    <div class="category-overlay">
                        <i class="fa-solid fa-table-tennis-paddle-ball category-icon"></i>
                        <span class="category-name">Cầu lông</span>
                    </div>
                </div>
                <div class="category-card tilt-card">
                    <img src="assets/images/vsport/categories/tennis.jpg" loading="lazy" alt="Tennis">
                    <div class="category-overlay">
                        <i class="fa-solid fa-baseball category-icon"></i>
                        <span class="category-name">Tennis</span>
                    </div>
                </div>
                <div class="category-card tilt-card">
                    <img src="assets/images/vsport/categories/pickleball.jpg" loading="lazy" alt="Pickleball">
                    <div class="category-overlay">
                        <i class="fa-solid fa-table-tennis category-icon"></i>
                        <span class="category-name">Pickleball</span>
                    </div>
                </div>
                <div class="category-card tilt-card">
                    <img src="assets/images/vsport/categories/basketball.jpg" loading="lazy" alt="Bóng rổ">
                    <div class="category-overlay">
                        <i class="fa-solid fa-basketball category-icon"></i>
                        <span class="category-name">Bóng rổ</span>
                    </div>
                </div>
                <div class="category-card tilt-card">
                    <img src="assets/images/vsport/categories/volleyball.jpg" loading="lazy" alt="Bóng chuyền">
                    <div class="category-overlay">
                        <i class="fa-solid fa-volleyball category-icon"></i>
                        <span class="category-name">Bóng chuyền</span>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Featured Courts -->
    <section class="section-padding section-diagonal pattern-bg">
        <div class="container">
            <div class="section-heading reveal">
                <div class="sub-title"><span class="line"></span><span class="text">SÂN NỔI BẬT</span><span class="line"></span></div>
                <h2>Sân Được Đặt Nhiều Nhất</h2>
            </div>
            
            <div class="courts-grid reveal">
                <div class="court-card tilt-card shine-hover">
                    <div class="court-img-wrapper">
                        <span class="court-tag">Gần bạn</span>
                        <div class="court-rating"><i class="fa-solid fa-star"></i> 4.9</div>
                        <img src="assets/images/vsport/courts/court-football.jpg" loading="lazy" alt="Sân">
                    </div>
                    <div class="court-info">
                        <h3>Sân Bóng Chảo Lửa</h3>
                        <p class="address"><i class="fa-solid fa-location-dot"></i> Tân Bình, TP.HCM</p>
                        <div class="court-facilities"><span><i class="fa-solid fa-parking"></i> Xe</span><span><i class="fa-solid fa-bottle-water"></i> Nước</span></div>
                        <div class="court-footer"><div class="court-price">300k <span>/ giờ</span></div><a href="#" class="btn-book btn-ripple">Xem lịch</a></div>
                    </div>
                </div>
                <div class="court-card tilt-card shine-hover">
                    <div class="court-img-wrapper">
                        <span class="court-tag" style="background:#4caf50;">Còn sân</span>
                        <div class="court-rating"><i class="fa-solid fa-star"></i> 4.8</div>
                        <img src="assets/images/vsport/courts/court-badminton.jpg" loading="lazy" alt="Sân">
                    </div>
                    <div class="court-info">
                        <h3>Sân Cầu Lông V-Star</h3>
                        <p class="address"><i class="fa-solid fa-location-dot"></i> Quận 7, TP.HCM</p>
                        <div class="court-facilities"><span><i class="fa-solid fa-shirt"></i> Đồ</span><span><i class="fa-solid fa-wifi"></i> Wifi</span></div>
                        <div class="court-footer"><div class="court-price">120k <span>/ giờ</span></div><a href="#" class="btn-book btn-ripple">Xem lịch</a></div>
                    </div>
                </div>
                <div class="court-card tilt-card shine-hover">
                    <div class="court-img-wrapper">
                        <span class="court-tag" style="background:#ff9800;">Giảm giá</span>
                        <div class="court-rating"><i class="fa-solid fa-star"></i> 4.7</div>
                        <img src="assets/images/vsport/courts/court-tennis.jpg" loading="lazy" alt="Sân">
                    </div>
                    <div class="court-info">
                        <h3>Sân Tennis Kỳ Hòa</h3>
                        <p class="address"><i class="fa-solid fa-location-dot"></i> Quận 10, TP.HCM</p>
                        <div class="court-facilities"><span><i class="fa-solid fa-parking"></i> Xe</span><span><i class="fa-solid fa-bottle-water"></i> Nước</span></div>
                        <div class="court-footer"><div class="court-price">250k <span>/ giờ</span></div><a href="#" class="btn-book btn-ripple">Xem lịch</a></div>
                    </div>
                </div>
                <div class="court-card tilt-card shine-hover">
                    <div class="court-img-wrapper">
                        <span class="court-tag">Gần bạn</span>
                        <div class="court-rating"><i class="fa-solid fa-star"></i> 5.0</div>
                        <img src="assets/images/vsport/courts/court-pickleball.jpg" loading="lazy" alt="Sân">
                    </div>
                    <div class="court-info">
                        <h3>Pickleball Zone</h3>
                        <p class="address"><i class="fa-solid fa-location-dot"></i> Quận 2, TP.HCM</p>
                        <div class="court-facilities"><span><i class="fa-solid fa-wifi"></i> Wifi</span><span><i class="fa-solid fa-lightbulb"></i> Đèn</span></div>
                        <div class="court-footer"><div class="court-price">150k <span>/ giờ</span></div><a href="#" class="btn-book btn-ripple">Xem lịch</a></div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Why V-SPORT -->
    <section class="section-padding">
        <div class="container">
            <div class="section-heading reveal">
                <h2>Vì Sao Người Chơi Chọn V-SPORT?</h2>
            </div>
            <div class="features-grid reveal">
                <div class="feature-card tilt-card" style="position:relative; overflow:hidden;">
                    <div style="font-size:40px; color:var(--accent-red); margin-bottom:15px;"><i class="fa-solid fa-clock-rotate-left"></i></div>
                    <h3>Tìm Sân Real-time</h3>
                    <p>Xem lịch trống thực tế, không cần gọi điện thoại hỏi chủ sân.</p>
                </div>
                <div class="feature-card tilt-card">
                    <div style="font-size:40px; color:var(--accent-red); margin-bottom:15px;"><i class="fa-solid fa-calendar-check"></i></div>
                    <h3>Đặt Sân Nhanh Chóng</h3>
                    <p>Giữ chỗ chắc chắn chỉ với vài thao tác thanh toán linh hoạt.</p>
                </div>
                <div class="feature-card tilt-card">
                    <div style="font-size:40px; color:var(--accent-red); margin-bottom:15px;"><i class="fa-solid fa-handshake"></i></div>
                    <h3>Ghép Trận Dễ Dàng</h3>
                    <p>Tìm đối thủ hoặc đồng đội cùng trình độ đang ở gần bạn.</p>
                </div>
                <div class="feature-card tilt-card">
                    <div style="font-size:40px; color:var(--accent-red); margin-bottom:15px;"><i class="fa-solid fa-shield-halved"></i></div>
                    <h3>Uy Tín Rõ Ràng</h3>
                    <p>Hệ thống đánh giá người chơi giúp xây dựng môi trường văn minh.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Ecosystem Section -->
    <section class="vs-ecosystem-section">
        <div class="container ecosystem-layout">
            <div class="ecosystem-orbit-wrapper">
                <div class="ecosystem-orbit">
                    <div class="orbit-ring orbit-ring-main"></div>
                    <div class="orbit-ring orbit-ring-secondary"></div>

                    <div class="ecosystem-center">
                        <img src="${pageContext.request.contextPath}/assets/images/vsport/community/ecosystem-center.png" alt="V-SPORT App">
                    </div>

                    <!-- Sports Icons -->
                    <button class="orbit-icon icon-sport" style="top: 4%; left: 48%;" data-tooltip="Bóng đá"><i class="fa-regular fa-futbol"></i></button>
                    <button class="orbit-icon icon-sport" style="top: 14%; left: 18%;" data-tooltip="Cầu lông"><i class="fa-solid fa-table-tennis-paddle-ball"></i></button>
                    <button class="orbit-icon icon-sport" style="top: 20%; right: 8%;" data-tooltip="Tennis"><i class="fa-solid fa-baseball"></i></button>
                    <button class="orbit-icon icon-sport" style="top: 50%; right: -27px; margin-top:-27px;" data-tooltip="Pickleball"><i class="fa-solid fa-table-tennis-paddle-ball"></i></button>
                    <button class="orbit-icon icon-sport" style="bottom: 15%; right: 12%;" data-tooltip="Bóng rổ"><i class="fa-solid fa-basketball"></i></button>
                    <button class="orbit-icon icon-sport" style="bottom: 4%; left: 45%;" data-tooltip="Bóng chuyền"><i class="fa-solid fa-volleyball"></i></button>

                    <!-- Function Icons -->
                    <button class="orbit-icon icon-func" style="bottom: 16%; left: 10%;" data-tooltip="Đặt sân"><i class="fa-solid fa-calendar-check"></i></button>
                    <button class="orbit-icon icon-func" style="top: 50%; left: -27px; margin-top:-27px;" data-tooltip="Ghép kèo"><i class="fa-solid fa-handshake"></i></button>
                    <button class="orbit-icon icon-func" style="top: 10%; right: 28%;" data-tooltip="Bản đồ sân"><i class="fa-solid fa-map-location-dot"></i></button>
                    <button class="orbit-icon icon-func" style="bottom: 8%; right: 35%;" data-tooltip="Thanh toán"><i class="fa-solid fa-credit-card"></i></button>
                    <button class="orbit-icon icon-func" style="top: 35%; left: 5%;" data-tooltip="Check-in"><i class="fa-solid fa-qrcode"></i></button>
                    <button class="orbit-icon icon-func" style="bottom: 35%; left: 2%;" data-tooltip="Uy tín"><i class="fa-solid fa-shield-halved"></i></button>
                    <button class="orbit-icon icon-func" style="top: 25%; right: 0;" data-tooltip="Đánh giá"><i class="fa-solid fa-star"></i></button>
                    <button class="orbit-icon icon-func" style="bottom: 25%; right: -15px;" data-tooltip="Thông báo"><i class="fa-solid fa-bell"></i></button>
                    <button class="orbit-icon icon-func" style="top: -15px; right: 25%;" data-tooltip="Chat"><i class="fa-solid fa-comment-dots"></i></button>
                    <button class="orbit-icon icon-func" style="bottom: -15px; left: 25%;" data-tooltip="Lịch sử"><i class="fa-solid fa-clock-rotate-left"></i></button>
                </div>
            </div>
            <div class="ecosystem-copy">
                <h2>Mọi Trải Nghiệm Thể Thao Trong Một Nơi</h2>
                <p>Từ tìm sân, đặt lịch, ghép kèo, xem bản đồ, thanh toán đến đánh giá sau trận — tất cả được kết nối trong một hệ sinh thái V-SPORT duy nhất.</p>
                <a href="#booking-steps" class="btn-text-arrow">Tìm hiểu cách hoạt động <i class="fa-solid fa-arrow-right"></i></a>
            </div>
        </div>
    </section>

    <!-- Booking Experience 3 Steps -->
    <section class="section-padding booking-experience">
        <div class="container">
            <div class="section-heading reveal">
                <div class="sub-title"><span class="line"></span><span class="text">QUY TRÌNH</span><span class="line"></span></div>
                <h2>Đặt Sân Trong 3 Bước</h2>
            </div>
            <div class="steps-grid reveal">
                <div class="step-item">
                    <div class="step-icon"><i class="fa-solid fa-calendar-check"></i><span class="step-number">1</span></div>
                    <h3>Chọn sân & khung giờ</h3>
                    <p>Tìm kiếm sân trống theo thời gian thực và vị trí của bạn.</p>
                </div>
                <div class="step-item stagger-1">
                    <div class="step-icon"><i class="fa-solid fa-credit-card"></i><span class="step-number">2</span></div>
                    <h3>Thanh toán & Xác nhận</h3>
                    <p>Thanh toán an toàn, nhận thông báo xác nhận đặt sân ngay lập tức.</p>
                </div>
                <div class="step-item stagger-2">
                    <div class="step-icon"><i class="fa-solid fa-medal"></i><span class="step-number">3</span></div>
                    <h3>Ra sân & Trải nghiệm</h3>
                    <p>Đến sân check-in dễ dàng và bắt đầu trận đấu của bạn.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Experience Gallery -->
    <section class="section-padding">
        <div class="container">
            <div class="section-heading reveal">
                <h2>Một Ngày Chơi Thể Thao Cùng V-SPORT</h2>
            </div>
            <div class="experience-grid reveal">
                <a href="assets/images/vsport/experience/experience-playing.jpg" class="exp-main gallery-lightbox-item" data-caption="Trải nghiệm thi đấu tuyệt vời cùng đồng đội">
                    <img src="assets/images/vsport/experience/experience-playing.jpg" loading="lazy" alt="Ra sân">
                    <div class="exp-overlay"><h3>Trải nghiệm thi đấu tuyệt vời</h3></div>
                </a>
                <div class="exp-side">
                    <a href="assets/images/vsport/experience/experience-booking.jpg" class="exp-item gallery-lightbox-item" data-caption="Tìm sân trống theo thời gian thực">
                        <img src="assets/images/vsport/experience/experience-booking.jpg" loading="lazy" alt="Đặt sân">
                        <div class="exp-overlay"><h4>Tìm sân trống</h4></div>
                    </a>
                    <a href="assets/images/vsport/experience/experience-payment.jpg" class="exp-item gallery-lightbox-item" data-caption="Thanh toán an toàn, tiện lợi">
                        <img src="assets/images/vsport/experience/experience-payment.jpg" loading="lazy" alt="Thanh toán">
                        <div class="exp-overlay"><h4>Thanh toán linh hoạt</h4></div>
                    </a>
                    <a href="assets/images/vsport/experience/experience-checkin.jpg" class="exp-item gallery-lightbox-item" data-caption="Check-in nhanh gọn tại sân">
                        <img src="assets/images/vsport/experience/experience-checkin.jpg" loading="lazy" alt="Checkin">
                        <div class="exp-overlay"><h4>Check-in tại sân</h4></div>
                    </a>
                    <a href="assets/images/vsport/experience/experience-matchmaking.jpg" class="exp-item gallery-lightbox-item" data-caption="Ghép trận giao lưu, nâng cao trình độ">
                        <img src="assets/images/vsport/experience/experience-matchmaking.jpg" loading="lazy" alt="Ghép trận">
                        <div class="exp-overlay"><h4>Ghép trận cùng trình độ</h4></div>
                    </a>
                </div>
            </div>
        </div>
    </section>

    <!-- Real-time Court Board -->
    <section class="section-padding pattern-bg">
        <div class="container">
            <div class="section-heading reveal">
                <h2>Bảng Sân Trống Đang Cập Nhật <span class="dot-green status-dot" style="display:inline-block;"></span></h2>
            </div>
            <div class="board-container reveal">
                <div class="board-header">
                    <div>Tên Sân / Cơ Sở</div>
                    <div>17:00</div><div>18:00</div><div>19:00</div><div>20:00</div><div>21:00</div><div>22:00</div>
                </div>
                <div class="board-row">
                    <div class="board-cell" style="font-weight:600;"><i class="fa-regular fa-futbol text-red" style="margin-right:10px;"></i> Sân Chảo Lửa</div>
                    <div class="board-cell"><span class="slot-badge badge-available">Còn 2 sân</span></div>
                    <div class="board-cell"><span class="slot-badge badge-booked">Đã đặt</span></div>
                    <div class="board-cell"><span class="slot-badge badge-booked">Đã đặt</span></div>
                    <div class="board-cell"><span class="slot-badge badge-available">Còn 1 sân</span></div>
                    <div class="board-cell"><span class="slot-badge badge-available">Còn 3 sân</span></div>
                    <div class="board-cell"><span class="slot-badge badge-available">Còn 4 sân</span></div>
                </div>
                <div class="board-row">
                    <div class="board-cell" style="font-weight:600;"><i class="fa-solid fa-table-tennis-paddle-ball text-red" style="margin-right:10px;"></i> V-Star Badminton</div>
                    <div class="board-cell"><span class="slot-badge badge-booked">Đã đặt</span></div>
                    <div class="board-cell"><span class="slot-badge badge-booked">Đã đặt</span></div>
                    <div class="board-cell"><span class="slot-badge badge-available">Còn 1 sân</span></div>
                    <div class="board-cell"><span class="slot-badge badge-available">Còn 2 sân</span></div>
                    <div class="board-cell"><span class="slot-badge badge-available">Còn 5 sân</span></div>
                    <div class="board-cell"><span class="slot-badge badge-available">Còn 5 sân</span></div>
                </div>
                <div class="board-row">
                    <div class="board-cell" style="font-weight:600;"><i class="fa-solid fa-baseball text-red" style="margin-right:10px;"></i> Tennis Kỳ Hòa</div>
                    <div class="board-cell"><span class="slot-badge badge-available">Còn 1 sân</span></div>
                    <div class="board-cell"><span class="slot-badge badge-available">Còn 1 sân</span></div>
                    <div class="board-cell"><span class="slot-badge badge-booked">Đã đặt</span></div>
                    <div class="board-cell"><span class="slot-badge badge-booked">Đã đặt</span></div>
                    <div class="board-cell"><span class="slot-badge badge-available">Còn 2 sân</span></div>
                    <div class="board-cell"><span class="slot-badge badge-available">Còn 2 sân</span></div>
                </div>
            </div>
            <div style="text-align:center; margin-top:30px;" class="reveal">
                <button class="btn-search btn-ripple" style="display:inline-flex; width:auto;"><i class="fa-solid fa-calendar-days"></i> Xem Tất Cả Giờ Trống</button>
            </div>
        </div>
    </section>

    <!-- Enhanced Matchmaking -->
    <section id="matchmaking" class="section-padding matchmaking-section">
        <div class="container">
            <div class="section-heading reveal">
                <div class="sub-title"><span class="line"></span><span class="text">GHÉP TRẬN</span><span class="line"></span></div>
                <h2 style="color:#fff;">Tìm Đối Thủ Cùng Trình Độ</h2>
            </div>
            
            <div class="matchmaking-grid reveal">
                <div class="match-form-box tilt-card">
                    <h3>Tạo Kèo Nhanh</h3>
                    <div class="form-group"><label>Môn Thể Thao</label><select><option>Bóng đá 5v5</option><option>Cầu lông đôi</option></select></div>
                    <div class="form-group"><label>Trình độ mong muốn</label><select><option>Khá</option><option>Giỏi</option></select></div>
                    <div class="form-group"><label>Số người còn thiếu</label><input type="number" min="1" value="1"></div>
                    <button class="btn-search btn-ripple" style="width:100%; justify-content:center; margin-top:10px;" onclick="showEnhancedToast('Đã tạo yêu cầu ghép trận', 'success')">Tạo Trận Phù Hợp</button>
                </div>

                <div class="match-list">
                    <div class="match-card-enhanced">
                        <div class="match-header">
                            <div class="match-creator">
                                <img src="assets/images/vsport/matches/match-avatar-01.jpg" loading="lazy" alt="Avatar">
                                <div><h4 style="margin:0;">FC Hùng Dũng</h4><div style="font-size:12px; color:#aaa;">Uy tín: 95/100</div></div>
                            </div>
                            <div style="text-align:right;">
                                <div style="color:var(--accent-red); font-weight:700; font-size:18px;">Bóng đá 5v5</div>
                                <div style="font-size:12px; color:#aaa;">Trình độ: Trung bình khá</div>
                            </div>
                        </div>
                        <div style="font-size:13px; color:#ccc; margin-bottom:10px;"><i class="fa-solid fa-location-dot"></i> Sân Chảo Lửa • <i class="fa-solid fa-clock"></i> 19:00 Hôm nay</div>
                        <div class="match-badges">
                            <span class="m-badge highlight">Thiếu 2 người</span><span class="m-badge">Gần bạn</span><span class="m-badge">Cần chốt sớm</span>
                        </div>
                        <div class="match-progress"><div class="progress-bar" style="width: 80%;"></div></div>
                        <button class="btn-primary btn-ripple" style="width:100%; text-align:center; padding:10px; border-radius:8px;" onclick="showEnhancedToast('Đã gửi yêu cầu tham gia', 'success')">Xin Tham Gia</button>
                    </div>

                    <div class="match-card-enhanced stagger-1">
                        <div class="match-header">
                            <div class="match-creator">
                                <img src="assets/images/vsport/matches/match-avatar-02.jpg" loading="lazy" alt="Avatar">
                                <div><h4 style="margin:0;">Team Cầu Lông Cuối Tuần</h4><div style="font-size:12px; color:#aaa;">Uy tín: 98/100</div></div>
                            </div>
                            <div style="text-align:right;">
                                <div style="color:var(--accent-red); font-weight:700; font-size:18px;">Cầu lông đôi</div>
                                <div style="font-size:12px; color:#aaa;">Trình độ: Khá</div>
                            </div>
                        </div>
                        <div style="font-size:13px; color:#ccc; margin-bottom:10px;"><i class="fa-solid fa-location-dot"></i> V-Star Badminton • <i class="fa-solid fa-clock"></i> 17:00 Ngày mai</div>
                        <div class="match-badges">
                            <span class="m-badge highlight">Thiếu 1 người</span><span class="m-badge">Cùng trình độ</span>
                        </div>
                        <div class="match-progress"><div class="progress-bar" style="width: 90%;"></div></div>
                        <button class="btn-primary btn-ripple" style="width:100%; text-align:center; padding:10px; border-radius:8px;" onclick="showEnhancedToast('Đã gửi yêu cầu tham gia', 'success')">Xin Tham Gia</button>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Hot Matches Carousel -->
    <section class="section-padding">
        <div class="container">
            <div class="section-heading reveal">
                <h2>Trận Đang Hot Cần Người</h2>
            </div>
            <div class="hot-matches-grid reveal">
                <div class="hot-match-card tilt-card">
                    <div class="hot-match-img">
                        <span class="badge-hot">HOT</span>
                        <img src="assets/images/vsport/courts/court-football.jpg" loading="lazy" alt="Match">
                    </div>
                    <div style="padding: 15px;">
                        <h4 style="margin-bottom:5px;">Giao lưu bóng đá sân 7</h4>
                        <p style="font-size:12px; color:var(--text-sub); margin-bottom:10px;"><i class="fa-solid fa-location-dot"></i> Sân Mini K34</p>
                        <div style="display:flex; justify-content:space-between; font-size:13px; font-weight:600; margin-bottom:15px;">
                            <span class="text-red">Thiếu 3 người</span><span>19:00 Tối nay</span>
                        </div>
                        <button class="btn-primary btn-ripple" style="width:100%; padding:8px; text-align:center;" onclick="showEnhancedToast('Chuyển tới trang chi tiết', 'info')">Tham Gia</button>
                    </div>
                </div>
                <!-- Duplicate for carousel effect -->
                <div class="hot-match-card tilt-card">
                    <div class="hot-match-img">
                        <span class="badge-hot">GẤP</span>
                        <img src="assets/images/vsport/courts/court-tennis.jpg" loading="lazy" alt="Match">
                    </div>
                    <div style="padding: 15px;">
                        <h4 style="margin-bottom:5px;">Đơn Nam Tennis Cấp Độ 3</h4>
                        <p style="font-size:12px; color:var(--text-sub); margin-bottom:10px;"><i class="fa-solid fa-location-dot"></i> Sân Tennis Lan Anh</p>
                        <div style="display:flex; justify-content:space-between; font-size:13px; font-weight:600; margin-bottom:15px;">
                            <span class="text-red">Tìm 1 đối thủ</span><span>08:00 Sáng mai</span>
                        </div>
                        <button class="btn-primary btn-ripple" style="width:100%; padding:8px; text-align:center;" onclick="showEnhancedToast('Chuyển tới trang chi tiết', 'info')">Tham Gia</button>
                    </div>
                </div>
                <div class="hot-match-card tilt-card">
                    <div class="hot-match-img">
                        <span class="badge-hot">HOT</span>
                        <img src="assets/images/vsport/courts/court-pickleball.jpg" loading="lazy" alt="Match">
                    </div>
                    <div style="padding: 15px;">
                        <h4 style="margin-bottom:5px;">Pickleball Đôi Nam Nữ</h4>
                        <p style="font-size:12px; color:var(--text-sub); margin-bottom:10px;"><i class="fa-solid fa-location-dot"></i> Pickleball Zone Q2</p>
                        <div style="display:flex; justify-content:space-between; font-size:13px; font-weight:600; margin-bottom:15px;">
                            <span class="text-red">Thiếu 2 người</span><span>17:00 Chiều nay</span>
                        </div>
                        <button class="btn-primary btn-ripple" style="width:100%; padding:8px; text-align:center;" onclick="showEnhancedToast('Chuyển tới trang chi tiết', 'info')">Tham Gia</button>
                    </div>
                </div>
                <div class="hot-match-card tilt-card">
                    <div class="hot-match-img">
                        <span class="badge-hot" style="background:#4caf50;">NEW</span>
                        <img src="assets/images/vsport/courts/court-badminton.jpg" loading="lazy" alt="Match">
                    </div>
                    <div style="padding: 15px;">
                        <h4 style="margin-bottom:5px;">Hội Lông Thủ Tân Bình</h4>
                        <p style="font-size:12px; color:var(--text-sub); margin-bottom:10px;"><i class="fa-solid fa-location-dot"></i> Sân Viettel</p>
                        <div style="display:flex; justify-content:space-between; font-size:13px; font-weight:600; margin-bottom:15px;">
                            <span class="text-red">Thiếu 4 người</span><span>20:00 Tối CN</span>
                        </div>
                        <button class="btn-primary btn-ripple" style="width:100%; padding:8px; text-align:center;" onclick="showEnhancedToast('Chuyển tới trang chi tiết', 'info')">Tham Gia</button>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Community Matchmaking Section -->
    <section class="vs-community-section">
        <div class="container community-container">
            <div class="community-copy">
                <h2>Chơi Cùng Nhau, Dù Bạn Ở Đâu</h2>
                <p>V-Sport giúp bạn tìm đồng đội, tạo kèo, tham gia trận gần khu vực và kết nối với những người chơi cùng trình độ.</p>
                <a href="#matchmaking" class="btn-text-arrow">Khám phá ghép trận <i class="fa-solid fa-arrow-right"></i></a>
            </div>
            <div class="community-visual">
                <div class="community-collage">
                    <div class="community-photo-card card-left">
                        <img src="${pageContext.request.contextPath}/assets/images/vsport/community/community-01.jpg" alt="Đội bóng">
                    </div>
                    <div class="community-photo-card card-center">
                        <img src="${pageContext.request.contextPath}/assets/images/vsport/community/community-03.jpg" alt="V-SPORT App">
                    </div>
                    <div class="community-photo-card card-right">
                        <img src="${pageContext.request.contextPath}/assets/images/vsport/community/community-02.jpg" alt="Nhóm bạn">
                    </div>
                </div>
                <div class="community-avatar-stack">
                    <img src="${pageContext.request.contextPath}/assets/images/vsport/matches/match-avatar-01.jpg" alt="User">
                    <img src="${pageContext.request.contextPath}/assets/images/vsport/matches/match-avatar-02.jpg" alt="User">
                    <img src="${pageContext.request.contextPath}/assets/images/vsport/players/person-01.jpg" alt="User">
                    <span class="avatar-badge">+98</span>
                </div>
            </div>
        </div>
    </section>

    <!-- Trusted Players -->
    <section id="trusted-players" class="section-padding pattern-bg">
        <div class="container">
            <div class="section-heading reveal">
                <div class="sub-title"><span class="line"></span><span class="text">CỘNG ĐỒNG V-SPORT</span><span class="line"></span></div>
                <h2>Người Chơi Uy Tín & Trình Độ Cao</h2>
            </div>
            
            <div class="player-grid reveal">
                <div class="player-card tilt-card shine-hover">
                    <div style="position:absolute; top:10px; left:10px; background:#ffd700; color:#000; font-size:11px; font-weight:700; padding:3px 8px; border-radius:10px; z-index:10;"><i class="fa-solid fa-crown"></i> TOP 1</div>
                    <div class="player-img-wrapper">
                        <div class="arch-bg"></div>
                        <img src="assets/images/vsport/players/person-01.jpg" loading="lazy" alt="Nguyễn Minh Khang">
                    </div>
                    <div class="player-info">
                        <h3>Nguyễn Minh Khang</h3>
                        <p class="player-sport">Bóng đá - Giỏi</p>
                        <div class="player-stats">
                            <span><i class="fa-solid fa-star"></i> 4.9</span>
                            <span><i class="fa-solid fa-shield-check text-red"></i> 98</span>
                        </div>
                    </div>
                    <a href="javascript:void(0)" class="btn-invite btn-ripple" onclick="showEnhancedToast('Đã gửi lời mời tới Nguyễn Minh Khang')">Mời chơi</a>
                </div>

                <div class="player-card tilt-card shine-hover">
                    <div style="position:absolute; top:10px; left:10px; background:#c0c0c0; color:#000; font-size:11px; font-weight:700; padding:3px 8px; border-radius:10px; z-index:10;"><i class="fa-solid fa-medal"></i> TOP 2</div>
                    <div class="player-img-wrapper">
                        <div class="arch-bg"></div>
                        <img src="assets/images/vsport/players/person-02.jpg" loading="lazy" alt="Trần Hoàng Nam">
                    </div>
                    <div class="player-info">
                        <h3>Trần Hoàng Nam</h3>
                        <p class="player-sport">Bóng đá - Khá</p>
                        <div class="player-stats">
                            <span><i class="fa-solid fa-star"></i> 4.7</span>
                            <span><i class="fa-solid fa-shield-check text-red"></i> 95</span>
                        </div>
                    </div>
                    <a href="javascript:void(0)" class="btn-invite btn-ripple" onclick="showEnhancedToast('Đã gửi lời mời tới Trần Hoàng Nam')">Mời chơi</a>
                </div>

                <div class="player-card tilt-card shine-hover">
                    <div style="position:absolute; top:10px; left:10px; background:#cd7f32; color:#fff; font-size:11px; font-weight:700; padding:3px 8px; border-radius:10px; z-index:10;"><i class="fa-solid fa-award"></i> TOP 3</div>
                    <div class="player-img-wrapper">
                        <div class="arch-bg"></div>
                        <img src="assets/images/vsport/players/person-04.jpg" loading="lazy" alt="Lê Gia Hân">
                    </div>
                    <div class="player-info">
                        <h3>Lê Gia Hân</h3>
                        <p class="player-sport">Cầu lông - Giỏi</p>
                        <div class="player-stats">
                            <span><i class="fa-solid fa-star"></i> 5.0</span>
                            <span><i class="fa-solid fa-shield-check text-red"></i> 97</span>
                        </div>
                    </div>
                    <a href="javascript:void(0)" class="btn-invite btn-ripple" onclick="showEnhancedToast('Đã gửi lời mời tới Lê Gia Hân')">Mời chơi</a>
                </div>

                <div class="player-card tilt-card shine-hover">
                    <div class="player-img-wrapper">
                        <div class="arch-bg"></div>
                        <img src="assets/images/vsport/players/person-05.jpg" loading="lazy" alt="Võ Anh Tuấn">
                    </div>
                    <div class="player-info">
                        <h3>Võ Anh Tuấn</h3>
                        <p class="player-sport">Tennis - Bán chuyên</p>
                        <div class="player-stats">
                            <span><i class="fa-solid fa-star"></i> 5.0</span>
                            <span><i class="fa-solid fa-shield-check text-red"></i> 99</span>
                        </div>
                    </div>
                    <a href="javascript:void(0)" class="btn-invite btn-ripple" onclick="showEnhancedToast('Đã gửi lời mời tới Võ Anh Tuấn')">Mời chơi</a>
                </div>
            </div>
        </div>
    </section>

    <!-- Reputation System -->
    <section class="section-padding" style="background:#fff;">
        <div class="container">
            <div class="section-heading reveal">
                <h2>Chơi Văn Minh Hơn Với Điểm Uy Tín</h2>
            </div>
            <div class="reputation-container reveal">
                <div class="rep-profile tilt-card">
                    <img src="assets/images/vsport/players/person-01.jpg" alt="Profile" class="rep-avatar">
                    <h3 style="margin-bottom:10px;">Điểm Uy Tín Của Bạn</h3>
                    <div class="rep-score counter" data-target="98">0</div>
                    <p style="color:var(--text-sub); margin-top:10px;">Thành viên Kim Cương</p>
                    <div style="margin-top:20px; display:flex; justify-content:space-around; font-size:13px; font-weight:600;">
                        <div><i class="fa-solid fa-clock text-red"></i> 96% Check-in</div>
                        <div><i class="fa-solid fa-thumbs-up text-red"></i> 120 Trận</div>
                    </div>
                </div>
                <div class="rep-timeline">
                    <div class="timeline-item stagger-1">
                        <div class="timeline-dot"></div>
                        <div class="timeline-content"><span>Đến sân đúng giờ</span><span class="point-up">+2 điểm</span></div>
                    </div>
                    <div class="timeline-item stagger-2">
                        <div class="timeline-dot"></div>
                        <div class="timeline-content"><span>Hoàn thành trận đấu</span><span class="point-up">+3 điểm</span></div>
                    </div>
                    <div class="timeline-item stagger-3">
                        <div class="timeline-dot"></div>
                        <div class="timeline-content"><span>Được đối thủ khen ngợi</span><span class="point-up">+5 điểm</span></div>
                    </div>
                    <div class="timeline-item stagger-4">
                        <div class="timeline-dot"></div>
                        <div class="timeline-content"><span>Hủy lịch sát giờ</span><span class="point-down">-10 điểm</span></div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Map Preview -->
    <section class="section-padding pattern-bg">
        <div class="container">
            <div class="map-preview reveal">
                <div class="map-info">
                    <div class="sub-title" style="justify-content: flex-start;"><span class="text">BẢN ĐỒ SÂN</span><span class="line"></span></div>
                    <h2>Tìm Sân Gần Bạn Trong Vài Giây</h2>
                    <ul>
                        <li><i class="fa-solid fa-map-location-dot"></i> Hàng trăm sân thể thao trên toàn quốc</li>
                        <li><i class="fa-solid fa-filter"></i> Lọc nhanh theo môn thể thao & tiện ích</li>
                        <li><i class="fa-solid fa-route"></i> Xem khoảng cách và chỉ đường đi nhanh nhất</li>
                    </ul>
                    <a href="#" class="btn-primary btn-ripple" style="margin-top: 15px;"><i class="fa-solid fa-map"></i> Mở Bản Đồ Sân</a>
                </div>
                <div class="map-img tilt-card" style="position:relative;">
                    <img src="assets/images/vsport/map/map-preview.jpg" loading="lazy" alt="Bản đồ">
                    <div style="position:absolute; top:40%; left:50%; width:20px; height:20px; background:var(--accent-red); border-radius:50%; transform:translate(-50%, -50%); box-shadow:0 0 0 10px rgba(255,31,45,0.3); animation:pulse 1.5s infinite;"></div>
                </div>
            </div>
        </div>
    </section>

    <!-- Deals -->
    <section class="section-padding">
        <div class="container">
            <div class="section-heading reveal">
                <h2>Ưu Đãi Đặt Sân Hôm Nay</h2>
            </div>
            <div class="deals-grid reveal">
                <div class="deal-card shine-hover tilt-card">
                    <div class="deal-discount">10%</div>
                    <h3 style="margin-bottom:10px;">Giờ Thấp Điểm</h3>
                    <p style="font-size:13px; color:#aaa; margin-bottom:20px;">Giảm giá cho các khung giờ từ 9:00 - 15:00 các ngày trong tuần.</p>
                    <button class="btn-primary btn-ripple" onclick="showEnhancedToast('Lưu mã thành công', 'success')">Nhận Mã Giảm</button>
                </div>
                <div class="deal-card shine-hover tilt-card" style="border-left-color:var(--accent-red);">
                    <div class="deal-discount">Free</div>
                    <h3 style="margin-bottom:10px;">Combo Nước Suối</h3>
                    <p style="font-size:13px; color:#aaa; margin-bottom:20px;">Tặng kèm nước suối miễn phí khi đặt sân trên 2 giờ đồng hồ.</p>
                    <button class="btn-primary btn-ripple" onclick="showEnhancedToast('Lưu mã thành công', 'success')">Nhận Mã Giảm</button>
                </div>
                <div class="deal-card shine-hover tilt-card">
                    <div class="deal-discount">20%</div>
                    <h3 style="margin-bottom:10px;">Thành Viên Mới</h3>
                    <p style="font-size:13px; color:#aaa; margin-bottom:20px;">Ưu đãi đặc quyền dành cho người dùng lần đầu tiên đặt sân.</p>
                    <button class="btn-primary btn-ripple" onclick="showEnhancedToast('Lưu mã thành công', 'success')">Nhận Mã Giảm</button>
                </div>
            </div>
        </div>
    </section>

    <!-- App Mockup -->
    <section class="section-padding app-section">
        <div class="container app-container reveal">
            <div class="app-mockup-wrapper">
                <img src="assets/images/vsport/app/app-mockup.png" loading="lazy" alt="App V-SPORT" class="app-phone">
            </div>
            <div>
                <h2 style="font-size:40px; font-family:var(--font-heading); margin-bottom:30px;">Đặt Sân Mọi Lúc,<br>Mọi Nơi</h2>
                <ul class="app-features">
                    <li><i class="fa-solid fa-mobile-screen"></i><div><h4 style="font-size:18px;">App Tối Ưu, Mượt Mà</h4><p style="color:#aaa; font-size:14px;">Trải nghiệm thao tác trên di động tốt nhất.</p></div></li>
                    <li><i class="fa-solid fa-bell"></i><div><h4 style="font-size:18px;">Nhận Thông Báo Push</h4><p style="color:#aaa; font-size:14px;">Không bỏ lỡ lịch thi đấu hay thông báo ghép trận.</p></div></li>
                    <li><i class="fa-solid fa-qrcode"></i><div><h4 style="font-size:18px;">Check-in Bằng QR Code</h4><p style="color:#aaa; font-size:14px;">Đến sân check-in chỉ trong 1 giây nhanh chóng.</p></div></li>
                </ul>
                <div style="display:flex; gap:15px; margin-top:30px;">
                    <a href="#" class="btn-primary btn-ripple"><i class="fa-brands fa-apple"></i> App Store</a>
                    <a href="#" class="btn-secondary btn-ripple"><i class="fa-brands fa-google-play"></i> Google Play</a>
                </div>
            </div>
        </div>
    </section>

    <!-- User Reviews -->
    <section class="section-padding" style="background:#fff;">
        <div class="container">
            <div class="section-heading reveal">
                <h2>Khách Hàng Nói Gì Về V-SPORT</h2>
            </div>
            <div class="reviews-grid reveal">
                <div class="review-card tilt-card">
                    <p class="review-text">"Đặt sân rất nhanh, có thể xem giờ trống rõ ràng. Tính năng ghép trận giúp đội mình luôn tìm được đối thủ vào cuối tuần."</p>
                    <div class="reviewer">
                        <img src="assets/images/vsport/reviews/review-01.jpg" loading="lazy" alt="Reviewer">
                        <div class="reviewer-info">
                            <h4>Trần Đăng Khoa</h4>
                            <div style='font-size:12px; color:#888; margin-bottom:5px;'><i class='fa-solid fa-location-dot text-red'></i> Sân Chảo Lửa • 2 ngày trước</div>
                            <div class="reviewer-rating"><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i></div>
                        </div>
                    </div>
                </div>
                <div class="review-card tilt-card stagger-1">
                    <p class="review-text">"Tính năng ghép trận giúp mình tìm được đội chơi cùng trình độ cầu lông. Sân sạch, check-in nhanh, thanh toán cực kì tiện lợi."</p>
                    <div class="reviewer">
                        <img src="assets/images/vsport/reviews/review-02.jpg" loading="lazy" alt="Reviewer">
                        <div class="reviewer-info">
                            <h4>Nguyễn Thị Mai</h4>
                            <div style='font-size:12px; color:#888; margin-bottom:5px;'><i class='fa-solid fa-location-dot text-red'></i> V-Star Badminton • 3 ngày trước</div>
                            <div class="reviewer-rating"><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star-half-stroke"></i></div>
                        </div>
                    </div>
                </div>
                <div class="review-card tilt-card stagger-2">
                    <p class="review-text">"Hệ thống uy tín rất hay, mình luôn biết trước đối thủ là ai, đá có fairplay hay không. Chắc chắn sẽ sử dụng V-SPORT lâu dài."</p>
                    <div class="reviewer">
                        <img src="assets/images/vsport/reviews/review-03.jpg" loading="lazy" alt="Reviewer">
                        <div class="reviewer-info">
                            <h4>Lê Minh Trí</h4>
                            <div style='font-size:12px; color:#888; margin-bottom:5px;'><i class='fa-solid fa-location-dot text-red'></i> Tennis Kỳ Hòa • 5 ngày trước</div>
                            <div class="reviewer-rating"><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i><i class="fa-solid fa-star"></i></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Stats Section -->
    <section class="stats-section" style="background: linear-gradient(rgba(17, 17, 17, 0.9), rgba(135, 15, 23, 0.8)), url('assets/images/vsport/hero/hero-bg.jpg') center/cover; background-attachment: fixed;">
        <div class="container">
            <div class="stats-grid reveal">
                <div class="stat-item"><h3 class="counter" data-target="12000">0</h3><p>Lượt đặt sân</p></div>
                <div class="stat-item"><h3 class="counter" data-target="4.8">0</h3><p>Điểm đánh giá</p></div>
                <div class="stat-item"><h3 class="counter" data-target="500">0</h3><p>Trận ghép thành công</p></div>
                <div class="stat-item"><h3 class="counter" data-target="98">0</h3><p>% Check-in đúng giờ</p></div>
            </div>
        </div>
    </section>

    <!-- FAQ -->
    <section class="section-padding pattern-bg">
        <div class="container" style="max-width: 800px;">
            <div class="section-heading reveal">
                <h2>Câu Hỏi Thường Gặp</h2>
            </div>
            <div class="faq-container reveal">
                <div class="faq-item" onclick="this.classList.toggle('active')">
                    <div class="faq-question">Đặt sân có cần thanh toán trước không? <i class="fa-solid fa-chevron-down" style="transition:0.3s;"></i></div>
                    <div class="faq-answer">Hầu hết các sân đều yêu cầu thanh toán trước hoặc đặt cọc một phần để giữ chỗ chắc chắn. V-SPORT hỗ trợ nhiều cổng thanh toán linh hoạt.</div>
                </div>
                <div class="faq-item" onclick="this.classList.toggle('active')">
                    <div class="faq-question">Điểm uy tín hoạt động thế nào? <i class="fa-solid fa-chevron-down" style="transition:0.3s;"></i></div>
                    <div class="faq-answer">Điểm uy tín tăng khi bạn đi đúng giờ, hoàn thành trận và được đánh giá tốt. Điểm sẽ giảm nếu bạn hủy sát giờ hoặc không đến (no-show).</div>
                </div>
                <div class="faq-item" onclick="this.classList.toggle('active')">
                    <div class="faq-question">Làm sao để tham gia ghép trận? <i class="fa-solid fa-chevron-down" style="transition:0.3s;"></i></div>
                    <div class="faq-answer">Bạn chỉ cần vào mục Ghép trận, chọn trận có trình độ phù hợp, và bấm "Xin tham gia". Đội trưởng sẽ xét duyệt dựa trên điểm uy tín của bạn.</div>
                </div>
            </div>
        </div>
    </section>

    <!-- Final CTA -->
    <section class="final-cta">
        <div class="container reveal">
            <h2>Sẵn Sàng Cho Trận Đấu Tiếp Theo?</h2>
            <p>Chọn sân, tìm đồng đội, ghép trận và bắt đầu trải nghiệm thể thao thông minh cùng V-SPORT.</p>
            <div style="display:flex; gap:15px; justify-content:center;">
                <a href="#quick-booking" class="btn-primary btn-ripple">Đặt sân ngay</a>
                <a href="#matchmaking" class="btn-secondary btn-ripple">Tìm trận gần tôi</a>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="site-footer">
        <div class="container footer-grid">
            <div class="footer-col widget-about">
                <div class="footer-logo"><a href="#">V<span class="logo-icon"><i class="fa-solid fa-bolt text-red" style="margin: 0 5px;"></i></span>SPORT</a></div>
                <p class="about-text">Nền tảng đặt sân online, quản lý lịch sân và ghép trận thể thao lớn nhất dành cho cộng đồng người chơi.</p>
                <div class="contact-info">
                    <div class="contact-item"><span class="label text-red">TỔNG ĐÀI HỖ TRỢ</span><a href="tel:19001234" class="value">1900 1234</a></div>
                    <div class="contact-item"><span class="label text-red">EMAIL LIÊN HỆ</span><a href="mailto:contact@v-sport.vn" class="value">contact@v-sport.vn</a></div>
                </div>
            </div>
            <div class="footer-col widget-links">
                <h3 class="widget-title">Truy cập nhanh</h3>
                <ul>
                    <li><a href="#"><i class="fa-solid fa-angle-right"></i> Trang chủ</a></li>
                    <li><a href="#"><i class="fa-solid fa-angle-right"></i> Tìm sân trống</a></li>
                    <li><a href="#"><i class="fa-solid fa-angle-right"></i> Ghép trận</a></li>
                    <li><a href="#"><i class="fa-solid fa-angle-right"></i> Bảng giá</a></li>
                </ul>
            </div>
            <div class="footer-col widget-links">
                <h3 class="widget-title">Dịch vụ</h3>
                <ul>
                    <li><a href="#"><i class="fa-solid fa-angle-right"></i> Đặt sân online</a></li>
                    <li><a href="#"><i class="fa-solid fa-angle-right"></i> Tìm người chơi</a></li>
                    <li><a href="#"><i class="fa-solid fa-angle-right"></i> Đánh giá sân bãi</a></li>
                </ul>
            </div>
            <div class="footer-col widget-gallery">
                <h3 class="widget-title">Thư viện ảnh</h3>
                <div class="gallery-grid">
                    <a href="assets/images/vsport/gallery/gallery-01.jpg" class="gallery-item gallery-lightbox-item"><img src="assets/images/vsport/gallery/gallery-01.jpg" loading="lazy" alt="Gallery"></a>
                    <a href="assets/images/vsport/gallery/gallery-02.jpg" class="gallery-item gallery-lightbox-item"><img src="assets/images/vsport/gallery/gallery-02.jpg" loading="lazy" alt="Gallery"></a>
                    <a href="assets/images/vsport/gallery/gallery-03.jpg" class="gallery-item gallery-lightbox-item"><img src="assets/images/vsport/gallery/gallery-03.jpg" loading="lazy" alt="Gallery"></a>
                    <a href="assets/images/vsport/gallery/gallery-04.jpg" class="gallery-item gallery-lightbox-item"><img src="assets/images/vsport/gallery/gallery-04.jpg" loading="lazy" alt="Gallery"></a>
                </div>
            </div>
        </div>
        <div class="footer-bottom">
            <div class="container bottom-content">
                <div class="copyright"><p>&copy; Copyright 2026 <span class="text-red">V-SPORT</span>. All Rights Reserved.</p></div>
                <div class="social-links">
                    <a href="#"><i class="fa-brands fa-facebook-f"></i></a>
                    <a href="#"><i class="fa-brands fa-twitter"></i></a>
                    <a href="#"><i class="fa-brands fa-instagram"></i></a>
                </div>
            </div>
        </div>
    </footer>

    <!-- Mobile Sticky CTA -->
    <div class="mobile-sticky-cta">
        <a href="#quick-booking" class="active"><i class="fa-solid fa-calendar-check"></i> Đặt Sân</a>
        <a href="#matchmaking"><i class="fa-solid fa-users"></i> Ghép Trận</a>
        <a href="#"><i class="fa-solid fa-map-location-dot"></i> Bản Đồ</a>
    </div>

    <!-- Custom JS -->
    <script src="assets/js/vsport-customer.js"></script>
    <script src="assets/js/vsport-home-enhanced.js"></script>
    <jsp:include page="/auth/AuthModal.jsp" />
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            const urlParams = new URLSearchParams(window.location.search);
            const authAction = urlParams.get('auth');
            if (authAction === 'login') {
                openAuthModal('login');
            } else if (authAction === 'register') {
                openAuthModal('register');
            } else if (authAction === 'forgot-password') {
                openAuthModal('forgot-password');
            }
        });
    </script>
</body>
</html>
