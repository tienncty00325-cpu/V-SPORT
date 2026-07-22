<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="org.example.model.TaiKhoan" %>
<!DOCTYPE html>
<html lang="en">
<jsp:include page="/common/xtra-head.jsp" />
<body>

    <!-- Header -->
    <jsp:include page="/common/header-xtra.jsp" />

    <main>
        <div id="homeView" class="page-view active">
        <!-- Hero Section -->
        <section class="hero">
            <div class="hero-pattern"></div>
            <div class="container">
                <div class="hero-inner">
                    <div class="hero-content">
                        <h1><span class="highlight">Đặt sân</span><br>&amp; Ghép kèo ngay</h1>
                        <p>Kết nối đam mê thể thao, tìm sân và đối thủ dễ dàng chỉ với vài thao tác.</p>
                        <div class="hero-actions">
                            <a href="${pageContext.request.contextPath}/customer/dat-san" class="btn btn-primary">
                                Đặt sân ngay <i class="fas fa-calendar-alt" style="margin-left: 8px;"></i>
                            </a>
                            <a href="${pageContext.request.contextPath}/customer/ghep-keo" class="btn btn-outline">
                                Ghép kèo ngay
                            </a>
                        </div>
                    </div>
                    <div class="hero-image">
                        <img src="${pageContext.request.contextPath}/assets/images/vsport-hero-booking-match.webp" alt="V-SPORT Booking Match">
                    </div>
                </div>
            </div>
        </section>

        <!-- Service Benefits -->
        <div class="benefits-wrapper">
            <div class="container">
                <div class="benefits">
                    <div class="benefit-item">
                        <div class="benefit-icon">
                            <i class="fas fa-calendar-check"></i>
                        </div>
                        <div class="benefit-text">
                            <h4>Đặt sân nhanh chóng</h4>
                            <p>Chọn sân và khung giờ phù hợp chỉ trong vài phút.</p>
                        </div>
                    </div>
                    <div class="benefit-item">
                        <div class="benefit-icon">
                            <i class="fas fa-rotate-left"></i>
                        </div>
                        <div class="benefit-text">
                            <h4>Linh hoạt thay đổi</h4>
                            <p>Theo dõi, quản lý và thay đổi lịch theo chính sách của sân.</p>
                        </div>
                    </div>
                    <div class="benefit-item">
                        <div class="benefit-icon">
                            <i class="fas fa-shield-halved"></i>
                        </div>
                        <div class="benefit-text">
                            <h4>Thanh toán an toàn</h4>
                            <p>Hỗ trợ tiền mặt và thanh toán trực tuyến bảo mật.</p>
                        </div>
                    </div>
                    <div class="benefit-item">
                        <div class="benefit-icon">
                            <i class="fas fa-headset"></i>
                        </div>
                        <div class="benefit-text">
                            <h4>Hỗ trợ tận tâm</h4>
                            <p>Đội ngũ V-SPORT sẵn sàng hỗ trợ khi bạn cần.</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Promotional Banners -->
        <section class="promotions">
            <div class="container">
                <div class="promo-banners">
                    <!-- Banner 1 -->
                    <div class="promo-banner banner-red">
                        <div class="banner-content">
                            <div class="banner-discount">ƯU ĐÃI 20%</div>
                            <h3>Đặt sân lần đầu</h3>
                            <a href="${pageContext.request.contextPath}/customer/dat-san" class="btn-banner">Đặt ngay <i class="fas fa-arrow-right"></i></a>
                        </div>
                        <img src="${pageContext.request.contextPath}/assets/images/vsport/courts/court-pickleball.jpg" alt="Đặt sân lần đầu" class="banner-image" style="border-radius: 50%; right: -40px; bottom: -40px; width: 70%;">
                    </div>
                    <!-- Banner 2 -->
                    <div class="promo-banner banner-light">
                        <div class="banner-content">
                            <div class="banner-discount" style="color: var(--primary);">COMBO TIẾT KIỆM</div>
                            <h3>Thuê sân &amp; dụng cụ</h3>
                            <a href="${pageContext.request.contextPath}/customer/tim-kiem" class="btn-banner" style="background: var(--primary);">Khám phá <i class="fas fa-arrow-right"></i></a>
                        </div>
                        <img src="${pageContext.request.contextPath}/assets/images/vsport/courts/court-badminton.jpg" alt="Thuê sân và dụng cụ" class="banner-image" style="border-radius: 50%; right: -40px; bottom: -40px; width: 70%;">
                    </div>
                    <!-- Banner 3 -->
                    <div class="promo-banner banner-green">
                        <div class="banner-content">
                            <div class="banner-discount">GIẢM ĐẾN 30%</div>
                            <h3>Đồ thể thao<br>chính hãng</h3>
                            <a href="${pageContext.request.contextPath}/customer/tim-kiem" class="btn-banner">Xem sản phẩm <i class="fas fa-arrow-right"></i></a>
                        </div>
                        <img src="${pageContext.request.contextPath}/assets/images/vsport/players/person-03.jpg" alt="Đồ thể thao chính hãng" class="banner-image" style="border-radius: 50%; right: -40px; bottom: -40px; width: 80%;">
                    </div>
                    <!-- Banner 4 -->
                    <div class="promo-banner banner-navy">
                        <div class="banner-content">
                            <div class="banner-discount">KẾT NỐI MIỄN PHÍ</div>
                            <h3>Tìm đồng đội<br>ghép kèo</h3>
                            <a href="${pageContext.request.contextPath}/customer/ghep-keo" class="btn-banner">Ghép kèo <i class="fas fa-arrow-right"></i></a>
                        </div>
                        <img src="${pageContext.request.contextPath}/assets/images/vsport/community/community-01.jpg" alt="Tìm đồng đội ghép kèo" class="banner-image" style="border-radius: 50%; right: -40px; bottom: -40px; width: 80%;">
                    </div>
                </div>
            </div>
        </section>

        <!-- Categories Section -->
        <section class="categories">
            <div class="container">
                <h2 class="section-title">Khám phá <span class="highlight">môn thể thao</span></h2>
                <div class="category-grid">
                    <a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Bóng đá" class="category-card">
                        <div class="category-icon"><i class="fas fa-futbol"></i></div>
                        <h4>Bóng đá</h4>
                    </a>
                    <a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Cầu lông" class="category-card">
                        <div class="category-icon"><i class="fas fa-table-tennis-paddle-ball"></i></div>
                        <h4>Cầu lông</h4>
                    </a>
                    <a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Pickleball" class="category-card">
                        <div class="category-icon"><i class="fas fa-table-tennis-paddle-ball"></i></div>
                        <h4>Pickleball</h4>
                    </a>
                    <a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Tennis" class="category-card">
                        <div class="category-icon"><i class="fas fa-baseball-bat-ball"></i></div>
                        <h4>Tennis</h4>
                    </a>
                    <a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Bóng rổ" class="category-card">
                        <div class="category-icon"><i class="fas fa-basketball"></i></div>
                        <h4>Bóng rổ</h4>
                    </a>
                    <a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Gym" class="category-card">
                        <div class="category-icon"><i class="fas fa-dumbbell"></i></div>
                        <h4>Gym &amp; Fitness</h4>
                    </a>
                </div>
            </div>
        </section>

        <!-- Featured Products & Services Section -->
        <section class="products">
            <div class="container">
                <div class="products-header">
                    <h2 class="section-title">Sản phẩm &amp; <span class="highlight">dịch vụ nổi bật</span></h2>
                    <a href="${pageContext.request.contextPath}/customer/tim-kiem" class="btn btn-primary">Xem tất cả</a>
                </div>
                
                <div class="product-grid">
                    <!-- Product 1 -->
                    <div class="product-card">
                        <div class="product-badges">
                            <!-- No badge -->
                        </div>
                        <div class="product-actions">
                            <div class="action-icon" title="Thêm vào yêu thích"><i class="far fa-heart"></i></div>
                            <div class="action-icon" title="Xem chi tiết"><i class="fas fa-search"></i></div>
                            <div class="action-icon" title="Xem cơ sở cung cấp"><i class="fas fa-arrow-up-right-from-square"></i></div>
                        </div>
                        <div class="product-image">
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/categories/pickleball.jpg" alt="Vợt Pickleball Carbon Pro">
                        </div>
                        <div class="product-info">
                            <div class="product-category">Pickleball</div>
                            <h3 class="product-title"><a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Pickleball">Vợt Pickleball Carbon Pro</a></h3>
                            <div class="product-rating">
                                <i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star-half-alt"></i>
                            </div>
                            <div class="product-price-wrapper">
                                <div class="product-price">1.290.000đ</div>
                            </div>
                            <a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Pickleball" class="add-to-cart"><i class="fas fa-eye"></i> Xem chi tiết</a>
                        </div>
                    </div>

                    <!-- Product 2 -->
                    <div class="product-card">
                        <div class="product-badges">
                            <!-- No badge -->
                        </div>
                        <div class="product-actions">
                            <div class="action-icon" title="Thêm vào yêu thích"><i class="far fa-heart"></i></div>
                            <div class="action-icon" title="Xem chi tiết"><i class="fas fa-search"></i></div>
                            <div class="action-icon" title="Xem cơ sở cung cấp"><i class="fas fa-arrow-up-right-from-square"></i></div>
                        </div>
                        <div class="product-image">
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/categories/badminton.jpg" alt="Giày cầu lông chống trượt">
                        </div>
                        <div class="product-info">
                            <div class="product-category">Cầu lông</div>
                            <h3 class="product-title"><a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Cầu lông">Giày cầu lông chống trượt</a></h3>
                            <div class="product-rating">
                                <i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star-half-alt"></i>
                            </div>
                            <div class="product-price-wrapper">
                                <div class="product-price">890.000đ</div>
                            </div>
                            <a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Cầu lông" class="add-to-cart"><i class="fas fa-eye"></i> Xem chi tiết</a>
                        </div>
                    </div>

                    <!-- Product 3 -->
                    <div class="product-card">
                        <div class="product-badges">
                            <!-- No badge -->
                        </div>
                        <div class="product-actions">
                            <div class="action-icon" title="Thêm vào yêu thích"><i class="far fa-heart"></i></div>
                            <div class="action-icon" title="Xem chi tiết"><i class="fas fa-search"></i></div>
                            <div class="action-icon" title="Xem cơ sở cung cấp"><i class="fas fa-arrow-up-right-from-square"></i></div>
                        </div>
                        <div class="product-image">
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/categories/football.jpg" alt="Bóng đá tiêu chuẩn Size 5">
                        </div>
                        <div class="product-info">
                            <div class="product-category">Bóng đá</div>
                            <h3 class="product-title"><a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Bóng đá">Bóng đá tiêu chuẩn Size 5</a></h3>
                            <div class="product-rating">
                                <i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="far fa-star"></i>
                            </div>
                            <div class="product-price-wrapper">
                                <div class="product-price">350.000đ</div>
                            </div>
                            <a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Bóng đá" class="add-to-cart"><i class="fas fa-eye"></i> Xem chi tiết</a>
                        </div>
                    </div>

                    <!-- Product 4 -->
                    <div class="product-card">
                        <div class="product-badges">
                            <!-- No badge -->
                        </div>
                        <div class="product-actions">
                            <div class="action-icon" title="Thêm vào yêu thích"><i class="far fa-heart"></i></div>
                            <div class="action-icon" title="Xem chi tiết"><i class="fas fa-search"></i></div>
                            <div class="action-icon" title="Xem cơ sở cung cấp"><i class="fas fa-arrow-up-right-from-square"></i></div>
                        </div>
                        <div class="product-image">
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/players/person-04.jpg" alt="Áo thể thao V-SPORT Dry Fit">
                        </div>
                        <div class="product-info">
                            <div class="product-category">Trang phục</div>
                            <h3 class="product-title"><a href="${pageContext.request.contextPath}/customer/tim-kiem">Áo thể thao V-SPORT Dry Fit</a></h3>
                            <div class="product-rating">
                                <i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star-half-alt"></i>
                            </div>
                            <div class="product-price-wrapper">
                                <div class="product-price">249.000đ</div>
                            </div>
                            <a href="${pageContext.request.contextPath}/customer/tim-kiem" class="add-to-cart"><i class="fas fa-eye"></i> Xem chi tiết</a>
                        </div>
                    </div>

                    <!-- Product 5 -->
                    <div class="product-card">
                        <div class="product-badges">
                            <!-- No badge -->
                        </div>
                        <div class="product-actions">
                            <div class="action-icon" title="Thêm vào yêu thích"><i class="far fa-heart"></i></div>
                            <div class="action-icon" title="Xem chi tiết"><i class="fas fa-search"></i></div>
                            <div class="action-icon" title="Xem cơ sở cung cấp"><i class="fas fa-arrow-up-right-from-square"></i></div>
                        </div>
                        <div class="product-image">
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/categories/tennis.jpg" alt="Túi đựng vợt đa năng">
                        </div>
                        <div class="product-info">
                            <div class="product-category">Phụ kiện</div>
                            <h3 class="product-title"><a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Tennis">Túi đựng vợt đa năng</a></h3>
                            <div class="product-rating">
                                <i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="far fa-star"></i>
                            </div>
                            <div class="product-price-wrapper">
                                <div class="product-price">459.000đ</div>
                            </div>
                            <a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Tennis" class="add-to-cart"><i class="fas fa-eye"></i> Xem chi tiết</a>
                        </div>
                    </div>

                    <!-- Product 6 -->
                    <div class="product-card">
                        <div class="product-badges">
                            <!-- No badge -->
                        </div>
                        <div class="product-actions">
                            <div class="action-icon" title="Thêm vào yêu thích"><i class="far fa-heart"></i></div>
                            <div class="action-icon" title="Xem chi tiết"><i class="fas fa-search"></i></div>
                            <div class="action-icon" title="Xem cơ sở cung cấp"><i class="fas fa-arrow-up-right-from-square"></i></div>
                        </div>
                        <div class="product-image">
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/courts/court-pickleball.jpg" alt="Thuê vợt tại cơ sở">
                        </div>
                        <div class="product-info">
                            <div class="product-category">Dịch vụ</div>
                            <h3 class="product-title"><a href="${pageContext.request.contextPath}/customer/tim-kiem">Thuê vợt tại cơ sở</a></h3>
                            <div class="product-rating">
                                <i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star-half-alt"></i>
                            </div>
                            <div class="product-price-wrapper">
                                <div class="product-price">Từ 30.000đ</div>
                            </div>
                            <a href="${pageContext.request.contextPath}/customer/tim-kiem" class="add-to-cart"><i class="fas fa-eye"></i> Xem tại cơ sở</a>
                        </div>
                    </div>

                    <!-- Product 7 -->
                    <div class="product-card">
                        <div class="product-badges">
                            <!-- No badge -->
                        </div>
                        <div class="product-actions">
                            <div class="action-icon" title="Thêm vào yêu thích"><i class="far fa-heart"></i></div>
                            <div class="action-icon" title="Xem chi tiết"><i class="fas fa-search"></i></div>
                            <div class="action-icon" title="Xem cơ sở cung cấp"><i class="fas fa-arrow-up-right-from-square"></i></div>
                        </div>
                        <div class="product-image">
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/players/person-05.jpg" alt="Huấn luyện viên cá nhân">
                        </div>
                        <div class="product-info">
                            <div class="product-category">Dịch vụ</div>
                            <h3 class="product-title"><a href="${pageContext.request.contextPath}/customer/tim-kiem">Huấn luyện viên cá nhân</a></h3>
                            <div class="product-rating">
                                <i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star-half-alt"></i>
                            </div>
                            <div class="product-price-wrapper">
                                <div class="product-price">Từ 200.000đ/buổi</div>
                            </div>
                            <a href="${pageContext.request.contextPath}/customer/tim-kiem" class="add-to-cart"><i class="fas fa-eye"></i> Xem tại cơ sở</a>
                        </div>
                    </div>

                    <!-- Product 8 -->
                    <div class="product-card">
                        <div class="product-badges">
                            <!-- No badge -->
                        </div>
                        <div class="product-actions">
                            <div class="action-icon" title="Thêm vào yêu thích"><i class="far fa-heart"></i></div>
                            <div class="action-icon" title="Xem chi tiết"><i class="fas fa-search"></i></div>
                            <div class="action-icon" title="Xem cơ sở cung cấp"><i class="fas fa-arrow-up-right-from-square"></i></div>
                        </div>
                        <div class="product-image">
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/categories/basketball.jpg" alt="Bình nước thể thao 750ml">
                        </div>
                        <div class="product-info">
                            <div class="product-category">Phụ kiện</div>
                            <h3 class="product-title"><a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Bóng rổ">Bình nước thể thao 750ml</a></h3>
                            <div class="product-rating">
                                <i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star-half-alt"></i>
                            </div>
                            <div class="product-price-wrapper">
                                <div class="product-price">159.000đ</div>
                            </div>
                            <a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Bóng rổ" class="add-to-cart"><i class="fas fa-eye"></i> Xem chi tiết</a>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Mobile App Banner -->
        <section class="app-section">
            <div class="container">
                <div class="mobile-app">
                    <div class="app-content">
                        <h4>V-SPORT</h4>
                        <h2>Thể thao trong tầm tay</h2>
                        <p>Tìm sân gần bạn, đặt lịch theo khung giờ thuận tiện và kết nối với cộng đồng người chơi cùng đam mê.</p>
                        <div class="app-buttons">
                            <a href="${pageContext.request.contextPath}/customer/BanDo.jsp" class="app-btn">
                                <i class="fas fa-location-dot"></i>
                                <div class="app-btn-text">
                                    <span>Bản đồ sân gần bạn</span>
                                    <strong>Tìm sân gần bạn</strong>
                                </div>
                            </a>
                            <a href="${pageContext.request.contextPath}/customer/ghep-keo" class="app-btn">
                                <i class="fas fa-people-arrows"></i>
                                <div class="app-btn-text">
                                    <span>Kết nối cộng đồng</span>
                                    <strong>Ghép kèo ngay</strong>
                                </div>
                            </a>
                        </div>
                    </div>
                    <img src="${pageContext.request.contextPath}/assets/images/vsport/community/community-02.jpg" alt="Cộng đồng V-SPORT" class="app-image" style="border-radius: 20px;">
                </div>
            </div>
        </section>

        <!-- News and Blog Section -->
        <section class="blog">
            <div class="container">
                <div class="blog-header">
                    <h2 class="section-title">Tin tức &amp; <span class="highlight">kinh nghiệm thể thao</span></h2>
                    <div class="blog-nav">
                        <button class="prev-blog"><i class="fas fa-arrow-left"></i></button>
                        <button class="next-blog"><i class="fas fa-arrow-right"></i></button>
                    </div>
                </div>
                
                <div class="blog-grid" id="blogSlider">
                    <!-- Blog 1 -->
                    <div class="blog-card">
                        <div class="blog-image">
                            <span class="blog-badge">Kinh nghiệm</span>
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/gallery/gallery-01.jpg" alt="5 lưu ý giúp bạn chọn sân phù hợp">
                        </div>
                        <div class="blog-content">
                            <span class="blog-date">10/06/2026</span>
                            <h3 class="blog-title"><a href="${pageContext.request.contextPath}/customer/tim-kiem">5 lưu ý giúp bạn chọn sân phù hợp</a></h3>
                        </div>
                    </div>

                    <!-- Blog 2 -->
                    <div class="blog-card">
                        <div class="blog-image">
                            <span class="blog-badge">Pickleball</span>
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/categories/pickleball.jpg" alt="Cách chọn vợt Pickleball cho người mới">
                        </div>
                        <div class="blog-content">
                            <span class="blog-date">10/06/2026</span>
                            <h3 class="blog-title"><a href="${pageContext.request.contextPath}/customer/tim-kiem?q=Pickleball">Cách chọn vợt Pickleball cho người mới</a></h3>
                        </div>
                    </div>

                    <!-- Blog 3 -->
                    <div class="blog-card">
                        <div class="blog-image">
                            <span class="blog-badge">Sức khỏe</span>
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/experience/experience-playing.jpg" alt="Khởi động đúng cách trước khi thi đấu">
                        </div>
                        <div class="blog-content">
                            <span class="blog-date">10/06/2026</span>
                            <h3 class="blog-title"><a href="${pageContext.request.contextPath}/customer/tim-kiem">Khởi động đúng cách trước khi thi đấu</a></h3>
                        </div>
                    </div>

                    <!-- Blog 4 -->
                    <div class="blog-card">
                        <div class="blog-image">
                            <span class="blog-badge">Cộng đồng</span>
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/community/community-03.jpg" alt="Làm thế nào để tìm đồng đội hợp trình độ?">
                        </div>
                        <div class="blog-content">
                            <span class="blog-date">10/06/2026</span>
                            <h3 class="blog-title"><a href="${pageContext.request.contextPath}/customer/ghep-keo">Làm thế nào để tìm đồng đội hợp trình độ?</a></h3>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Customer Reviews -->
        <section class="reviews">
            <div class="container">
                <div class="reviews-header">
                    <div>
                        <h2 class="section-title">Khách hàng nói gì về <span class="highlight">V-SPORT</span></h2>
                        <p class="reviews-subtitle">Những trải nghiệm thực tế từ cộng đồng đặt sân và ghép kèo trên V-SPORT.</p>
                    </div>
                    <div class="reviews-nav">
                        <button class="prev-review"><i class="fas fa-arrow-left"></i></button>
                        <button class="next-review"><i class="fas fa-arrow-right"></i></button>
                    </div>
                </div>

                <div class="reviews-grid" id="reviewsSlider">
                    <!-- Review 1 -->
                    <div class="review-card">
                        <div class="review-top">
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/reviews/review-01.jpg" alt="Minh Anh" class="review-avatar">
                            <div class="review-identity">
                                <h4>Minh Anh</h4>
                                <span class="review-sport">Pickleball</span>
                            </div>
                        </div>
                        <div class="review-rating">
                            <i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i>
                        </div>
                        <p class="review-text">Tôi tìm được sân gần nhà rất nhanh, thông tin khung giờ rõ ràng và quá trình đặt sân chỉ mất vài phút.</p>
                        <div class="review-meta">
                            <div>
                                <div class="review-venue">Sân Pickleball Long Điền</div>
                                <span class="review-date">10/06/2026</span>
                            </div>
                            <span class="review-badge"><i class="fas fa-circle-check"></i> Đã đặt sân</span>
                        </div>
                    </div>

                    <!-- Review 2 -->
                    <div class="review-card">
                        <div class="review-top">
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/reviews/review-02.jpg" alt="Hoàng Nam" class="review-avatar">
                            <div class="review-identity">
                                <h4>Hoàng Nam</h4>
                                <span class="review-sport">Cầu lông</span>
                            </div>
                        </div>
                        <div class="review-rating">
                            <i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i>
                        </div>
                        <p class="review-text">Tính năng ghép kèo giúp tôi tìm được nhóm chơi phù hợp trình độ. Mọi người đều thân thiện và đúng giờ.</p>
                        <div class="review-meta">
                            <div>
                                <div class="review-venue">Trung tâm Cầu lông Vũng Tàu</div>
                                <span class="review-date">08/06/2026</span>
                            </div>
                            <span class="review-badge"><i class="fas fa-circle-check"></i> Đã đặt sân</span>
                        </div>
                    </div>

                    <!-- Review 3 -->
                    <div class="review-card">
                        <div class="review-top">
                            <img src="${pageContext.request.contextPath}/assets/images/vsport/reviews/review-03.jpg" alt="Thu Trang" class="review-avatar">
                            <div class="review-identity">
                                <h4>Thu Trang</h4>
                                <span class="review-sport">Bóng đá</span>
                            </div>
                        </div>
                        <div class="review-rating">
                            <i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star-half-alt"></i>
                        </div>
                        <p class="review-text">Sân hiển thị đúng hình ảnh và giá. Tôi cũng có thể thuê thêm bóng và áo bib ngay tại cơ sở.</p>
                        <div class="review-meta">
                            <div>
                                <div class="review-venue">Sân bóng Thành Công</div>
                                <span class="review-date">02/06/2026</span>
                            </div>
                            <span class="review-badge"><i class="fas fa-circle-check"></i> Đã đặt sân</span>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Newsletter -->
        <div class="newsletter-wrapper">
            <div class="container">
                <div class="newsletter">
                    <div class="newsletter-content">
                        <h2>Nhận ưu đãi từ <span style="color: var(--primary);">V-SPORT</span></h2>
                        <p>Cập nhật sân mới, chương trình ưu đãi và hoạt động thể thao nổi bật.</p>
                    </div>
                    <form class="newsletter-form" id="newsletterForm">
                        <input type="email" placeholder="Nhập địa chỉ email của bạn" required>
                        <button type="submit">Đăng ký</button>
                    </form>
                </div>
            </div>
        </div>
        </div> <!-- End of homeView -->

        <!-- Auth View -->
        <div id="authView" class="page-view">
            <!-- Auth Header -->
            <div class="auth-header">
                <div class="container">
                    <div class="auth-header-inner">
                        <h1 class="auth-title">Tài khoản của tôi</h1>
                        <div class="breadcrumb">
                            <a href="#home" id="breadcrumbHome"><i class="fas fa-home"></i> Trang chủ</a>
                            <span><i class="fas fa-chevron-right" style="font-size: 10px; margin: 0 5px;"></i></span>
                            <span>Tài khoản</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Auth Container -->
            <div class="container">
                <div class="auth-tabs">
                    <button class="auth-tab-btn active" data-target="loginCol">Đăng nhập</button>
                    <button class="auth-tab-btn" data-target="registerCol">Đăng ký</button>
                </div>

                <div class="auth-container">
                    <!-- Login Column -->
                    <div class="auth-col active" id="loginCol">
                        <h3>Đăng nhập</h3>
                        <form id="loginForm" novalidate>
                            <div class="form-group">
                                <label for="loginEmail">Email hoặc số điện thoại <span>*</span></label>
                                <input type="text" id="loginEmail" class="form-control" placeholder="Nhập email hoặc số điện thoại..." required aria-describedby="loginEmailError">
                                <div id="loginEmailError" class="error-message"><i class="fas fa-exclamation-circle"></i> Vui lòng nhập email hoặc số điện thoại</div>
                            </div>
                            
                            <div class="form-group">
                                <label for="loginPassword">Mật khẩu <span>*</span></label>
                                <div class="password-input-wrap">
                                    <input type="password" id="loginPassword" class="form-control" placeholder="Nhập mật khẩu..." required aria-describedby="loginPasswordError">
                                    <button type="button" class="password-toggle" aria-label="Hiện/ẩn mật khẩu">
                                        <i class="far fa-eye-slash"></i>
                                    </button>
                                </div>
                                <div id="loginPasswordError" class="error-message"><i class="fas fa-exclamation-circle"></i> Vui lòng nhập mật khẩu</div>
                            </div>
                            
                            <div class="form-check">
                                <input type="checkbox" id="rememberMe">
                                <label for="rememberMe">Ghi nhớ đăng nhập</label>
                            </div>
                            
                            <div class="auth-actions">
                                <button type="submit" class="btn btn-primary btn-auth" id="loginSubmitBtn">
                                    <i class="fas fa-spinner"></i>
                                    <span class="btn-text">Đăng nhập</span>
                                </button>
                                <a href="#" class="forgot-link" id="forgotBtn">Quên mật khẩu?</a>
                            </div>
                        </form>
                    </div>

                    <!-- Register Column -->
                    <div class="auth-col" id="registerCol">
                        <h3>Đăng ký</h3>
                        <form id="registerForm" novalidate>
                            <div style="display: flex; gap: 20px;">
                                <div class="form-group" style="flex: 1;">
                                    <label for="regName">Họ và tên <span>*</span></label>
                                    <input type="text" id="regName" class="form-control" placeholder="Nhập họ và tên..." required aria-describedby="regNameError">
                                    <div id="regNameError" class="error-message"><i class="fas fa-exclamation-circle"></i> Vui lòng nhập họ và tên</div>
                                </div>
                                <div class="form-group" style="flex: 1;">
                                    <label for="regPhone">Số điện thoại <span>*</span></label>
                                    <input type="tel" id="regPhone" class="form-control" placeholder="Nhập số điện thoại..." required aria-describedby="regPhoneError">
                                    <div id="regPhoneError" class="error-message"><i class="fas fa-exclamation-circle"></i> Số điện thoại không hợp lệ</div>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="regEmail">Email <span>*</span></label>
                                <input type="email" id="regEmail" class="form-control" placeholder="Nhập email..." required aria-describedby="regEmailError">
                                <div id="regEmailError" class="error-message"><i class="fas fa-exclamation-circle"></i> Email không hợp lệ</div>
                            </div>
                            
                            <div class="form-group">
                                <label for="regPassword">Mật khẩu <span>*</span></label>
                                <div class="password-input-wrap">
                                    <input type="password" id="regPassword" class="form-control" placeholder="Nhập mật khẩu..." required aria-describedby="regPasswordError">
                                    <button type="button" class="password-toggle" aria-label="Hiện/ẩn mật khẩu">
                                        <i class="far fa-eye-slash"></i>
                                    </button>
                                </div>
                                <div class="password-helper">Mật khẩu tối thiểu 8 ký tự, gồm chữ và số.</div>
                                <div id="regPasswordError" class="error-message"><i class="fas fa-exclamation-circle"></i> Mật khẩu chưa đạt yêu cầu</div>
                            </div>
                            
                            <div class="form-group">
                                <label for="regConfirmPassword">Xác nhận mật khẩu <span>*</span></label>
                                <div class="password-input-wrap">
                                    <input type="password" id="regConfirmPassword" class="form-control" placeholder="Nhập lại mật khẩu..." required aria-describedby="regConfirmPasswordError">
                                    <button type="button" class="password-toggle" aria-label="Hiện/ẩn mật khẩu">
                                        <i class="far fa-eye-slash"></i>
                                    </button>
                                </div>
                                <div id="regConfirmPasswordError" class="error-message"><i class="fas fa-exclamation-circle"></i> Mật khẩu xác nhận không khớp</div>
                            </div>
                            
                            <div class="form-check">
                                <input type="checkbox" id="agreeTerms" required>
                                <label for="agreeTerms">Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật</label>
                                <div id="agreeTermsError" class="error-message" style="position: absolute; bottom: -20px;"><i class="fas fa-exclamation-circle"></i> Vui lòng đồng ý với điều khoản</div>
                            </div>
                            
                            <div class="auth-actions">
                                <button type="submit" class="btn btn-primary btn-auth" id="registerSubmitBtn" style="width: 100%;">
                                    <i class="fas fa-spinner"></i>
                                    <span class="btn-text">Tạo tài khoản</span>
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
            
            <!-- Forgot Password Modal -->
            <div class="modal-overlay" id="forgotModal" role="dialog" aria-modal="true" aria-labelledby="modalTitle">
                <div class="modal-content">
                    <button class="modal-close" aria-label="Đóng" id="closeModalBtn"><i class="fas fa-times"></i></button>
                    <h3 id="modalTitle">Khôi phục mật khẩu</h3>
                    <p>Nhập email của bạn và chúng tôi sẽ gửi cho bạn một liên kết để đặt lại mật khẩu.</p>
                    
                    <form id="forgotForm" novalidate>
                        <div class="form-group">
                            <label for="forgotEmail">Email <span>*</span></label>
                            <input type="email" id="forgotEmail" class="form-control" placeholder="Nhập email..." required aria-describedby="forgotEmailError">
                            <div id="forgotEmailError" class="error-message"><i class="fas fa-exclamation-circle"></i> Email không hợp lệ</div>
                        </div>
                        
                        <div class="auth-actions">
                            <button type="submit" class="btn btn-primary btn-auth" id="forgotSubmitBtn" style="width: 100%;">
                                <i class="fas fa-spinner"></i>
                                <span class="btn-text">Gửi liên kết khôi phục</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
            
            <!-- Success Toast -->
            <div class="success-toast" id="successToast">
                <i class="fas fa-check-circle" style="margin-right: 8px;"></i> <span id="toastMessage">Thành công!</span>
            </div>
        </div>
    </main>

    <!-- Footer -->
    <footer class="footer">
        <div class="container">
            <div class="footer-grid">
                <!-- Col 1 -->
                <div class="footer-col">
                    <a href="${pageContext.request.contextPath}/" class="logo" style="margin-bottom: 25px;">
                        <i class="fa-solid fa-basket-shopping"></i>
                        V-<span>SPORT</span>
                    </a>
                    <p>Nền tảng giúp bạn tìm sân, đặt lịch và kết nối với cộng đồng thể thao một cách nhanh chóng, thuận tiện.</p>
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
                        <li><a href="${pageContext.request.contextPath}/">Về V-SPORT</a></li>
                        <li><a href="${pageContext.request.contextPath}/customer/tim-kiem">Tìm sân</a></li>
                        <li><a href="${pageContext.request.contextPath}/customer/ghep-keo">Ghép kèo</a></li>
                        <li><a href="${pageContext.request.contextPath}/customer/tim-kiem">Tin tức</a></li>
                        <li><a href="#">Điều khoản sử dụng</a></li>
                        <li><a href="#">Chính sách quyền riêng tư</a></li>
                        <li><a href="#">Chính sách đặt và hủy sân</a></li>
                    </ul>
                </div>

                <!-- Col 3 -->
                <div class="footer-col">
                    <h4>Liên hệ</h4>
                    <ul class="contact-info">
                        <li>
                            <i class="fas fa-phone-alt"></i>
                            <div>
                                <span style="font-size: 13px; display: block;">Hotline hỗ trợ</span>
                                <a href="tel:8185556788">818-555 67 88</a>
                            </div>
                        </li>
                        <li>
                            <i class="fas fa-envelope"></i>
                            <div>
                                <span style="font-size: 13px; display: block;">Email hỗ trợ</span>
                                <a href="mailto:support@vsport.vn" style="font-size: 15px; font-weight: 400; font-family: 'Inter', sans-serif;">support@vsport.vn</a>
                            </div>
                        </li>
                        <li>
                            <i class="fas fa-clock"></i>
                            <div>
                                <span style="font-size: 13px; display: block;">Thời gian hỗ trợ</span>
                                <span style="font-size: 15px; font-weight: 400;">7:00 - 22:00 hằng ngày</span>
                            </div>
                        </li>
                    </ul>
                </div>

                <!-- Col 4 -->
                <div class="footer-col">
                    <h4>Dành cho đối tác</h4>
                    <p>Bạn đang sở hữu một cơ sở thể thao? Hãy đưa sân của mình đến gần hơn với cộng đồng người chơi.</p>
                    <a href="${pageContext.request.contextPath}/owner/register" class="btn btn-primary">Đăng ký cơ sở</a>
                </div>
            </div>

            <div class="footer-bottom">
                <div class="copyright">
                    &copy; 2026 V-SPORT. Bảo lưu mọi quyền.
                </div>
                <div class="payments">
                    <div class="payment-card" title="Tiền mặt"><i class="fas fa-money-bill-wave" style="color: #1a8f4c; font-size: 22px;"></i></div>
                    <div class="payment-card" title="PayOS / QR ngân hàng"><i class="fas fa-qrcode" style="color: #185A9D; font-size: 22px;"></i></div>
                </div>
            </div>
        </div>
    </footer>

    <!-- Floating Scroll Top -->
    <div class="scroll-top" id="scrollTop">
        <i class="fas fa-arrow-up"></i>
    </div>

    <!-- JavaScript -->
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Scroll to top functionality
            const scrollTopBtn = document.getElementById('scrollTop');
            
            window.addEventListener('scroll', function() {
                if (window.pageYOffset > 300) {
                    scrollTopBtn.classList.add('active');
                } else {
                    scrollTopBtn.classList.remove('active');
                }
            });
            
            scrollTopBtn.addEventListener('click', function() {
                window.scrollTo({
                    top: 0,
                    behavior: 'smooth'
                });
            });

            // Simple Blog Slider mock functionality
            const prevBtn = document.querySelector('.prev-blog');
            const nextBtn = document.querySelector('.next-blog');
            const blogGrid = document.getElementById('blogSlider');
            
            if (prevBtn && nextBtn && blogGrid) {
                // In a real app, this would shift cards
                // Since we only have 4 cards and they are all visible on desktop,
                // we'll just add a small visual effect for demonstration
                nextBtn.addEventListener('click', () => {
                    blogGrid.style.transform = 'translateX(-10px)';
                    setTimeout(() => {
                        blogGrid.style.transform = 'translateX(0)';
                    }, 300);
                });
                
                prevBtn.addEventListener('click', () => {
                    blogGrid.style.transform = 'translateX(10px)';
                    setTimeout(() => {
                        blogGrid.style.transform = 'translateX(0)';
                    }, 300);
                });
            }
        });
            // --- AUTH LOGIC ---
            
            const homeView = document.getElementById('homeView');
            const authView = document.getElementById('authView');
            const accountBtns = document.querySelectorAll('.icon-btn');
            
            // Find auth button
            const accountBtn = document.getElementById('authBtn');
            
            // Routing
            function handleRoute() {
                const hash = window.location.hash;
                if (hash === '#auth') {
                    homeView.classList.remove('active');
                    authView.classList.add('active');
                } else {
                    authView.classList.remove('active');
                    homeView.classList.add('active');
                }
                window.scrollTo({ top: 0, behavior: 'instant' });
            }
            
            window.addEventListener('hashchange', handleRoute);
            
            // Initial route check
            if (window.location.hash === '#auth') {
                handleRoute();
            }
            
            if (accountBtn) {
                accountBtn.addEventListener('click', (e) => {
                    e.preventDefault();
                    window.location.hash = '#auth';
                });
            }
            
            // Breadcrumb and Logo click to home
            const breadcrumbHome = document.getElementById('breadcrumbHome');
            if (breadcrumbHome) {
                breadcrumbHome.addEventListener('click', (e) => {
                    e.preventDefault();
                    window.location.hash = '#home';
                });
            }
            
            const mainLogo = document.querySelector('.logo');
            if (mainLogo) {
                mainLogo.addEventListener('click', (e) => {
                    // Only prevent default if we're in auth view to go back, otherwise let it be
                    if (window.location.hash === '#auth') {
                        e.preventDefault();
                        window.location.hash = '#home';
                    }
                });
            }
            
            // Auth Tabs (Mobile)
            const tabBtns = document.querySelectorAll('.auth-tab-btn');
            const authCols = document.querySelectorAll('.auth-col');
            
            tabBtns.forEach(btn => {
                btn.addEventListener('click', () => {
                    tabBtns.forEach(b => b.classList.remove('active'));
                    authCols.forEach(c => c.classList.remove('active'));
                    
                    btn.classList.add('active');
                    const targetId = btn.getAttribute('data-target');
                    document.getElementById(targetId).classList.add('active');
                });
            });
            
            // Password Toggle
            const toggleBtns = document.querySelectorAll('.password-toggle');
            toggleBtns.forEach(btn => {
                btn.addEventListener('click', () => {
                    const input = btn.previousElementSibling;
                    const icon = btn.querySelector('i');
                    
                    if (input.type === 'password') {
                        input.type = 'text';
                        icon.classList.remove('fa-eye-slash');
                        icon.classList.add('fa-eye');
                    } else {
                        input.type = 'password';
                        icon.classList.remove('fa-eye');
                        icon.classList.add('fa-eye-slash');
                    }
                });
            });
            
            // Modal Logic
            const forgotModal = document.getElementById('forgotModal');
            const forgotBtn = document.getElementById('forgotBtn');
            const closeModalBtn = document.getElementById('closeModalBtn');
            const forgotEmail = document.getElementById('forgotEmail');
            
            function openModal() {
                forgotModal.classList.add('active');
                document.body.style.overflow = 'hidden';
                setTimeout(() => forgotEmail.focus(), 100);
            }
            
            function closeModal() {
                forgotModal.classList.remove('active');
                document.body.style.overflow = '';
                forgotBtn.focus();
            }
            
            if (forgotBtn) {
                forgotBtn.addEventListener('click', (e) => {
                    e.preventDefault();
                    openModal();
                });
            }
            
            if (closeModalBtn) {
                closeModalBtn.addEventListener('click', closeModal);
            }
            
            window.addEventListener('click', (e) => {
                if (e.target === forgotModal) {
                    closeModal();
                }
            });
            
            window.addEventListener('keydown', (e) => {
                if (e.key === 'Escape' && forgotModal.classList.contains('active')) {
                    closeModal();
                }
            });
            
            // Toast functionality
            const successToast = document.getElementById('successToast');
            const toastMessage = document.getElementById('toastMessage');
            
            function showToast(msg) {
                toastMessage.textContent = msg;
                successToast.classList.add('active');
                setTimeout(() => {
                    successToast.classList.remove('active');
                }, 3000);
            }

            // Newsletter signup - backend chưa sẵn sàng, chỉ validate và báo đang phát triển
            const newsletterForm = document.getElementById('newsletterForm');
            if (newsletterForm) {
                newsletterForm.addEventListener('submit', function (e) {
                    e.preventDefault();
                    const emailInput = newsletterForm.querySelector('input[type="email"]');
                    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                    if (!emailInput || !emailRegex.test(emailInput.value.trim())) {
                        showToast('Vui lòng nhập một địa chỉ email hợp lệ.');
                        return;
                    }
                    showToast('Chức năng đăng ký nhận ưu đãi đang được phát triển.');
                    newsletterForm.reset();
                });
            }
            
            // Validation Helpers
            const showError = (input, show) => {
                const errorMsg = document.getElementById(input.id + 'Error');
                if (show) {
                    input.setAttribute('aria-invalid', 'true');
                    if (errorMsg) errorMsg.style.display = 'block';
                } else {
                    input.removeAttribute('aria-invalid');
                    if (errorMsg) errorMsg.style.display = 'none';
                }
            };
            
            // Clear errors on input
            document.querySelectorAll('.form-control, .form-check input').forEach(input => {
                input.addEventListener('input', () => showError(input, false));
                input.addEventListener('change', () => showError(input, false));
            });
            
            // Form Submissions
            
            // Login Form
            const loginForm = document.getElementById('loginForm');
            const loginSubmitBtn = document.getElementById('loginSubmitBtn');
            
            if (loginForm) {
                loginForm.addEventListener('submit', (e) => {
                    e.preventDefault();
                    let isValid = true;
                    let firstError = null;
                    
                    const email = document.getElementById('loginEmail');
                    const password = document.getElementById('loginPassword');
                    
                    if (!email.value.trim()) {
                        showError(email, true);
                        isValid = false;
                        if (!firstError) firstError = email;
                    }
                    
                    if (!password.value.trim()) {
                        showError(password, true);
                        isValid = false;
                        if (!firstError) firstError = password;
                    }
                    
                    if (!isValid) {
                        firstError.focus();
                        return;
                    }
                    
                    // Connect to Backend API
                    loginSubmitBtn.disabled = true;
                    loginSubmitBtn.classList.add('loading');
                    const btnText = loginSubmitBtn.querySelector('.btn-text');
                    const originalText = btnText.textContent;
                    btnText.textContent = 'Đang đăng nhập...';
                    
                    const formData = new URLSearchParams();
                    const loginIdentifier = email.value.trim();
                    const isPhone = /^(0|\+84|84)[0-9]{8,9}$/.test(loginIdentifier);
                    formData.append('username', loginIdentifier);
                    formData.append('phone', loginIdentifier);
                    formData.append('password', password.value);
                    formData.append('loginMethod', isPhone ? 'phone' : 'account');

                    fetch('dangnhap', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded',
                            'X-Requested-With': 'XMLHttpRequest'
                        },
                        body: formData.toString()
                    })
                    .then(response => response.json())
                    .then(data => {
                        loginSubmitBtn.disabled = false;
                        loginSubmitBtn.classList.remove('loading');
                        btnText.textContent = originalText;
                        
                        if (data.success) {
                            showToast('Đăng nhập thành công!');
                            setTimeout(() => {
                                window.location.href = data.redirectUrl;
                            }, 500);
                        } else {
                            showToast('Lỗi: ' + (data.loi || 'Đăng nhập thất bại'));
                        }
                    })
                    .catch(error => {
                        loginSubmitBtn.disabled = false;
                        loginSubmitBtn.classList.remove('loading');
                        btnText.textContent = originalText;
                        showToast('Lỗi kết nối máy chủ');
                        console.error('Error:', error);
                    });
                });
            }
            
            // Register Form
            const registerForm = document.getElementById('registerForm');
            const registerSubmitBtn = document.getElementById('registerSubmitBtn');
            
            if (registerForm) {
                registerForm.addEventListener('submit', (e) => {
                    e.preventDefault();
                    let isValid = true;
                    let firstError = null;
                    
                    const name = document.getElementById('regName');
                    const phone = document.getElementById('regPhone');
                    const email = document.getElementById('regEmail');
                    const password = document.getElementById('regPassword');
                    const confirm = document.getElementById('regConfirmPassword');
                    const terms = document.getElementById('agreeTerms');
                    
                    if (!name.value.trim()) { showError(name, true); isValid = false; if (!firstError) firstError = name; }
                    
                    const phoneRegex = /(84|0[3|5|7|8|9])+([0-9]{8})\b/;
                    if (!phoneRegex.test(phone.value.trim())) { showError(phone, true); isValid = false; if (!firstError) firstError = phone; }
                    
                    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                    if (!emailRegex.test(email.value.trim())) { showError(email, true); isValid = false; if (!firstError) firstError = email; }
                    
                    const passRegex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$/;
                    if (!passRegex.test(password.value)) { showError(password, true); isValid = false; if (!firstError) firstError = password; }
                    
                    if (password.value !== confirm.value || !confirm.value) { showError(confirm, true); isValid = false; if (!firstError) firstError = confirm; }
                    
                    if (!terms.checked) { showError(terms, true); isValid = false; if (!firstError) firstError = terms; }
                    
                    if (!isValid) {
                        if (firstError) firstError.focus();
                        return;
                    }
                    
                    // Simulate API Call
                    registerSubmitBtn.disabled = true;
                    registerSubmitBtn.classList.add('loading');
                    const btnText = registerSubmitBtn.querySelector('.btn-text');
                    const originalText = btnText.textContent;
                    btnText.textContent = 'Đang tạo tài khoản...';
                    
                    setTimeout(() => {
                        registerSubmitBtn.disabled = false;
                        registerSubmitBtn.classList.remove('loading');
                        btnText.textContent = originalText;
                        showToast('Tạo tài khoản thành công!');
                        registerForm.reset();
                    }, 800);
                });
            }
            
            // Forgot Form
            const forgotForm = document.getElementById('forgotForm');
            const forgotSubmitBtn = document.getElementById('forgotSubmitBtn');
            
            if (forgotForm) {
                forgotForm.addEventListener('submit', (e) => {
                    e.preventDefault();
                    
                    const email = document.getElementById('forgotEmail');
                    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                    
                    if (!emailRegex.test(email.value.trim())) {
                        showError(email, true);
                        email.focus();
                        return;
                    }
                    
                    // Simulate API Call
                    forgotSubmitBtn.disabled = true;
                    forgotSubmitBtn.classList.add('loading');
                    const btnText = forgotSubmitBtn.querySelector('.btn-text');
                    const originalText = btnText.textContent;
                    btnText.textContent = 'Đang gửi...';
                    
                    setTimeout(() => {
                        forgotSubmitBtn.disabled = false;
                        forgotSubmitBtn.classList.remove('loading');
                        btnText.textContent = originalText;
                        closeModal();
                        showToast('Liên kết khôi phục mật khẩu đã được gửi đến email của bạn.');
                        forgotForm.reset();
                    }, 800);
                });
            }
    </script>
</body>
</html>
