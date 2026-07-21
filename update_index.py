import sys

file_path = "/home/nhan/Downloads/V-SPORT/src/main/webapp/index.jsp"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Hero visual
hero_img_old = """<div class="hero-image reveal">
                <img src="assets/images/vsport/hero/hero-player.jpg" alt="Thể thao" class="hero-img" style="border-radius: 20px; border: 5px solid #222; box-shadow: 0 10px 30px rgba(0,0,0,0.5);">
            </div>"""
hero_img_new = """<div class="hero-image reveal" style="position: relative;">
                <img src="assets/images/vsport/hero/hero-player.jpg" alt="Thể thao" class="hero-img" style="border-radius: 20px; border: 5px solid #222; box-shadow: 0 10px 30px rgba(0,0,0,0.5);">
                
                <div class="floating-card fc-1">
                    <div class="floating-icon"><i class="fa-solid fa-check"></i></div>
                    Sân còn trống hôm nay
                </div>
                <div class="floating-card fc-2">
                    <div class="floating-icon"><i class="fa-solid fa-users"></i></div>
                    Ghép trận 5v5
                </div>
                <div class="floating-card fc-3">
                    <div class="floating-icon"><i class="fa-solid fa-star"></i></div>
                    Uy tín 98/100
                </div>
            </div>"""
content = content.replace(hero_img_old, hero_img_new)

# Hero background update
content = content.replace("""<section class="hero-banner">""", """<section class="hero-banner" style="background: linear-gradient(135deg, rgba(17, 17, 17, 0.95) 0%, rgba(135, 15, 23, 0.85) 100%), url('assets/images/vsport/hero/hero-bg.jpg') center/cover no-repeat; background-attachment: fixed;">""")

# 2. Quick booking bar
content = content.replace("<label>Môn Thể Thao</label>", "<label><i class=\"fa-solid fa-volleyball\" style=\"margin-right:5px; color:var(--accent-red);\"></i>Môn Thể Thao</label>")
content = content.replace("<label>Khu Vực</label>", "<label><i class=\"fa-solid fa-location-dot\" style=\"margin-right:5px; color:var(--accent-red);\"></i>Khu Vực</label>")
content = content.replace("<label>Ngày Chơi</label>", "<label><i class=\"fa-solid fa-calendar-day\" style=\"margin-right:5px; color:var(--accent-red);\"></i>Ngày Chơi</label>")
content = content.replace("<label>Giờ Bắt Đầu</label>", "<label><i class=\"fa-solid fa-clock\" style=\"margin-right:5px; color:var(--accent-red);\"></i>Giờ Bắt Đầu</label>")

# 3. Featured Courts
content = content.replace("assets/images/vsport/courts/court-01.jpg", "assets/images/vsport/courts/court-football.jpg")
content = content.replace("assets/images/vsport/courts/court-02.jpg", "assets/images/vsport/courts/court-badminton.jpg")
content = content.replace("assets/images/vsport/courts/court-03.jpg", "assets/images/vsport/courts/court-tennis.jpg")
content = content.replace("assets/images/vsport/courts/court-04.jpg", "assets/images/vsport/courts/court-pickleball.jpg")

# 4. Trải Nghiệm V-Sport
exp_section = """
    <!-- Experience Section -->
    <section class="section-padding">
        <div class="container">
            <div class="section-heading reveal">
                <div class="sub-title">
                    <span class="line"></span>
                    <span class="text">TRẢI NGHIỆM</span>
                    <span class="line"></span>
                </div>
                <h2>Trải Nghiệm V-Sport Từ Lúc Đặt Sân Đến Khi Ra Sân</h2>
            </div>
            <div class="experience-grid reveal">
                <div class="exp-main">
                    <img src="assets/images/vsport/experience/experience-playing.jpg" alt="Ra sân">
                    <div class="exp-overlay">
                        <h3>Trải nghiệm thi đấu tuyệt vời</h3>
                    </div>
                </div>
                <div class="exp-side">
                    <div class="exp-item">
                        <img src="assets/images/vsport/experience/experience-booking.jpg" alt="Đặt sân">
                        <div class="exp-overlay"><h4>Tìm sân trống</h4></div>
                    </div>
                    <div class="exp-item">
                        <img src="assets/images/vsport/experience/experience-payment.jpg" alt="Thanh toán">
                        <div class="exp-overlay"><h4>Thanh toán linh hoạt</h4></div>
                    </div>
                    <div class="exp-item">
                        <img src="assets/images/vsport/experience/experience-checkin.jpg" alt="Checkin">
                        <div class="exp-overlay"><h4>Check-in tại sân</h4></div>
                    </div>
                    <div class="exp-item">
                        <img src="assets/images/vsport/experience/experience-matchmaking.jpg" alt="Ghép trận">
                        <div class="exp-overlay"><h4>Ghép trận cùng trình độ</h4></div>
                    </div>
                </div>
            </div>
        </div>
    </section>
"""
content = content.replace("""<!-- Live Available Slots -->""", exp_section + "\n    <!-- Live Available Slots -->")

# 5. Khung giờ trống
content = content.replace("""<section class="section-padding" style="background: var(--bg-body);">""", """<section class="section-padding pattern-bg">""")

# 6. Ghép trận avatars
content = content.replace("""<img src="assets/images/vsport/players/person-05.jpg" alt="Avatar">""", """<img src="assets/images/vsport/matches/match-avatar-01.jpg" alt="Avatar" style="width:50px; height:50px; border-radius:50%; object-fit:cover; border:2px solid var(--accent-red);">""")
content = content.replace("""<img src="assets/images/vsport/players/person-03.jpg" alt="Avatar">""", """<img src="assets/images/vsport/matches/match-avatar-02.jpg" alt="Avatar" style="width:50px; height:50px; border-radius:50%; object-fit:cover; border:2px solid var(--accent-red);">""")
content = content.replace("""<img src="assets/images/vsport/players/person-04.jpg" alt="Avatar">""", """<img src="assets/images/vsport/matches/match-avatar-03.jpg" alt="Avatar" style="width:50px; height:50px; border-radius:50%; object-fit:cover; border:2px solid var(--accent-red);">""")

# 8. Reviews
for name in ["Trần Đăng Khoa", "Nguyễn Thị Mai", "Lê Minh Trí"]:
    content = content.replace(f"<h4>{name}</h4>", f"<h4>{name}</h4><div style='font-size:12px; color:#888; margin-bottom:5px;'><i class='fa-solid fa-location-dot text-red'></i> Sân Chảo Lửa • 2 ngày trước</div>")

# 9. Stats
content = content.replace("""<section class="stats-section">""", """<section class="stats-section" style="background: linear-gradient(rgba(17, 17, 17, 0.9), rgba(135, 15, 23, 0.8)), url('assets/images/vsport/hero/hero-bg.jpg') center/cover; background-attachment: fixed;">""")
content = content.replace("""data-target="0.0">0</h3>""", """data-target="4.8">0</h3>""")

# 10. Newsletter
content = content.replace("""<section class="newsletter-section">""", """<section class="newsletter-section pattern-bg">""")

# 11. Footer gallery
content = content.replace("assets/images/vsport/gallery/gallery-football-01.jpg", "assets/images/vsport/gallery/gallery-01.jpg")
content = content.replace("assets/images/vsport/gallery/gallery-football-02.jpg", "assets/images/vsport/gallery/gallery-02.jpg")
content = content.replace("assets/images/vsport/gallery/gallery-football-03.jpg", "assets/images/vsport/gallery/gallery-03.jpg")
content = content.replace("assets/images/vsport/gallery/gallery-football-04.jpg", "assets/images/vsport/gallery/gallery-04.jpg")

# 12. V-Sport Dành Cho Ai
features_section = """
    <!-- Features -->
    <section class="section-padding" style="background:#fff;">
        <div class="container">
            <div class="section-heading reveal">
                <h2>V-Sport Dành Cho Mọi Người Chơi Thể Thao</h2>
            </div>
            <div class="features-grid reveal">
                <div class="feature-card">
                    <img src="assets/images/vsport/features/feature-01.jpg" alt="Feature">
                    <h3>Người muốn đặt sân nhanh</h3>
                    <p>Tìm và đặt sân trong 1 phút, không cần gọi điện hỏi lịch.</p>
                </div>
                <div class="feature-card">
                    <img src="assets/images/vsport/features/feature-02.jpg" alt="Feature">
                    <h3>Đội bóng/CLB</h3>
                    <p>Quản lý lịch thi đấu, chi phí và tìm kiếm đối thủ dễ dàng.</p>
                </div>
                <div class="feature-card">
                    <img src="assets/images/vsport/features/feature-03.jpg" alt="Feature">
                    <h3>Người chơi đơn</h3>
                    <p>Tham gia các kèo mở, kết bạn và nâng cao trình độ.</p>
                </div>
                <div class="feature-card">
                    <img src="assets/images/vsport/features/feature-04.jpg" alt="Feature">
                    <h3>Chủ sân thể thao</h3>
                    <p>Tăng tỷ lệ lấp đầy sân, quản lý lịch thông minh.</p>
                </div>
            </div>
        </div>
    </section>
"""
content = content.replace("""<!-- Footer -->""", features_section + "\n    <!-- Footer -->")

# 13. Map preview
map_section = """
    <!-- Map Preview -->
    <section class="section-padding pattern-bg">
        <div class="container">
            <div class="map-preview reveal">
                <div class="map-info">
                    <div class="sub-title" style="justify-content: flex-start;">
                        <span class="text">BẢN ĐỒ SÂN</span>
                        <span class="line"></span>
                    </div>
                    <h2>Tìm Sân Gần Nhất Quanh Bạn</h2>
                    <ul>
                        <li><i class="fa-solid fa-map-location-dot"></i> Hàng trăm sân thể thao trên toàn quốc</li>
                        <li><i class="fa-solid fa-filter"></i> Lọc nhanh theo môn thể thao & tiện ích</li>
                        <li><i class="fa-solid fa-route"></i> Xem khoảng cách và chỉ đường đi nhanh nhất</li>
                    </ul>
                    <a href="#" class="btn-primary" style="margin-top: 15px;"><i class="fa-solid fa-map"></i> Xem Bản Đồ</a>
                </div>
                <div class="map-img">
                    <img src="assets/images/vsport/map/map-preview.jpg" alt="Bản đồ">
                </div>
            </div>
        </div>
    </section>
"""
content = content.replace("""<!-- Footer -->""", map_section + "\n    <!-- Footer -->")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
