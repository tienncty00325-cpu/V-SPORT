# Hướng dẫn kiểm thử thủ công Bản đồ V-SPORT (MAP_MANUAL_TEST.md)

Tài liệu hướng dẫn kiểm thử các kịch bản liên quan đến Bản đồ Full-screen và API định vị.

## 1. Kiểm thử API `/api/customer/facilities/map`

### Kịch bản 1: Lấy danh sách mặc định
- **URL:** `GET /api/customer/facilities/map`
- **Kết quả mong muốn:** Trả về JSON chứa danh sách toàn bộ cơ sở đang hoạt động. Các trường `latitude`, `longitude`, `sports`, `minPrice`, `readyCourtCount` có giá trị chính xác. Không có lỗi 500.

### Kịch bản 2: Truy vấn với bộ lọc Định vị & Bán kính (Haversine)
- **URL:** `GET /api/customer/facilities/map?latitude=10.762622&longitude=106.660172&radiusKm=5`
- **Kết quả mong muốn:** Chỉ trả về các cơ sở nằm trong phạm vi bán kính 5km tính từ điểm (10.762622, 106.660172). Kết quả được sắp xếp tự động theo khoảng cách tăng dần (`distanceKm` từ nhỏ đến lớn).

### Kịch bản 3: Lọc cơ sở đang mở cửa (`openNow`)
- **URL:** `GET /api/customer/facilities/map?openNow=true`
- **Kết quả mong muốn:** API tự động so sánh giờ hiện tại (múi giờ `Asia/Ho_Chi_Minh`) với giờ mở/đóng cửa của cơ sở. Chỉ những nơi đang trong giờ hoạt động mới hiển thị. Hỗ trợ đầy đủ cả khung giờ bình thường (ví dụ: 06:00 - 22:00) và qua đêm (22:00 - 06:00).

### Kịch bản 4: Xác thực đầu vào (Validation Checks)
- **Thiếu 1 trong 2 tọa độ:** `GET /api/customer/facilities/map?latitude=10.762622`
  - **Kết quả mong muốn:** Trả về mã lỗi HTTP 400 Bad Request kèm JSON: `{"success":false,"error":"Cần cung cấp cả vĩ độ (latitude) và kinh độ (longitude)."}`.
- **Tọa độ ngoài phạm vi hợp lệ:** `GET /api/customer/facilities/map?latitude=95.0&longitude=106.660172`
  - **Kết quả mong muốn:** Trả về mã lỗi HTTP 400 Bad Request kèm thông điệp báo lỗi vĩ độ phải nằm trong khoảng [-90, 90].
- **Bán kính không hợp lệ:** `GET /api/customer/facilities/map?latitude=10.7&longitude=106.6&radiusKm=-5`
  - **Kết quả mong muốn:** Trả về mã lỗi HTTP 400 Bad Request báo bán kính phải lớn hơn 0.

---

## 2. Kiểm thử Giao diện Bản đồ (`/customer/ban-do`)

### Kịch bản 1: Bản đồ Full-screen & OSM Fallback
- Nếu không cấu hình `MAPTILER_API_KEY`, truy cập `/customer/ban-do` và kiểm tra xem bản đồ có hiển thị bình thường bằng các ô bản đồ OpenStreetMap hay không. Kiểm tra console log xem có bị lỗi API Key hay không.
- Thử cấu hình `MAPTILER_API_KEY` trong Java system property hoặc `web.xml`, tải lại trang và kiểm tra xem giao diện có chuyển sang MapTiler map hay không.

### Kịch bản 2: Tương tác Mobile Bottom Sheet & Popups
- **Desktop:** Nhấp vào một Marker, kiểm tra xem popup thông tin chi tiết (tên, khoảng cách, số sân sẵn sàng, giá rẻ nhất, nút đặt sân) có hiển thị đẹp mắt ngay tại vị trí Marker đó hay không.
- **Mobile:** Nhấp vào một Marker, kiểm tra xem thay vì hiển thị popup nhỏ, nó sẽ đẩy một Bottom Sheet trượt mượt mà từ dưới màn hình lên chứa đầy đủ thông tin cơ sở và nút Đặt Sân, tạo cảm giác native app.

### Kịch bản 3: Định vị GPS người dùng
- Nhấp vào nút GPS (biểu tượng tâm ngắm) ở góc trên bên phải bản đồ.
- Đồng ý cấp quyền định vị trong popup trình duyệt.
- Kiểm tra xem bản đồ có tự động vẽ marker vị trí của bạn (màu xanh dương nhạt hoặc biểu tượng radar) và tự động lọc danh sách cơ sở theo khoảng cách gần bạn nhất hay không.
