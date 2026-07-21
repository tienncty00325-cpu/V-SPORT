# Sổ Tay Hướng Dẫn Kiểm Thử Thủ Công Giao Diện Khách Hàng (CUSTOMER_PORTAL_REDESIGN_MANUAL_TEST.md)

Tài liệu này cung cấp hướng dẫn kiểm thử chi tiết, tọa độ kiểm thử và các kịch bản tương tác (responsive) cho toàn bộ Customer Portal đã được thiết kế lại của V-SPORT.

---

## 1. Trang Chủ (`index.jsp`)

### Kịch bản kiểm thử:
1. **Header & Navigation:**
   - Kiểm tra Logo V-SPORT hiển thị sắc nét ở bên trái.
   - Di chuột qua các liên kết trên header để kiểm tra hiệu ứng gạch chân màu xanh lục bảo (`#059669`).
2. **Hero Banner & Search Floating Panel:**
   - Truy cập trang chủ, kiểm tra Banner lớn hiển thị tiêu đề và mô tả truyền cảm hứng thể thao.
   - Nhấp vào hộp chọn "Bộ môn" và kiểm tra xem danh sách thả xuống có hiển thị các tùy chọn môn thể thao kèm icon đẹp mắt.
   - Chọn ngày và giờ chơi, nhấp vào nút "Tìm kiếm". Kiểm tra xem trang có chuyển hướng sang `/customer/dat-san` và giữ nguyên các tham số tìm kiếm hay không.
3. **Sport Filter Chips & Facility Grid:**
   - Kiểm tra hàng loạt chip thể thao (Tất cả, Bóng đá, Cầu lông, Pickleball,...) hiển thị ngay dưới thanh tìm kiếm. Nhấp vào các chip để kiểm tra trạng thái kích hoạt (background màu xanh lục, chữ trắng).
   - Kiểm tra lưới thẻ cơ sở (facility cards) hiển thị thông tin dạng compact: hình ảnh thu nhỏ, tên cơ sở, địa chỉ, khoảng cách, số sân trống và giá tối thiểu.
4. **Kiểm thử trên thiết bị di động:**
   - Thu nhỏ trình duyệt về kích thước điện thoại (dưới 1024px).
   - Kiểm tra xem Top Header cũ có ẩn đi và Bottom Navigation Bar (5 nút: Trang chủ, Bản đồ, Ghép trận, Nổi bật, Tài khoản) hiển thị cố định ở chân trang hay không.

---

## 2. Trang Đặt Sân (`customer/DatSan.jsp`)

### Kịch bản kiểm thử:
1. **Lọc tìm kiếm nâng cao:**
   - Kiểm tra thanh tìm kiếm phía trên cùng để lọc theo chi nhánh/cơ sở, ngày chơi và bộ môn thể thao.
   - Bấm nút "Bản đồ" trên thanh công cụ lọc để kiểm tra xem có chuyển hướng mượt mà sang trang `/customer/ban-do` hay không.
2. **Danh sách sân & Chi tiết lịch trống:**
   - Chọn một cơ sở cụ thể. Kiểm tra lưới danh sách sân hiển thị trạng thái "Sẵn sàng".
   - Nhấp vào "Xem lịch trống" của một sân để mở bảng Timetable chia theo các khung giờ (ví dụ: 06:00 - 23:00).
   - Đảm bảo các khung giờ đã được đặt hiển thị màu đỏ (kèm chữ "Đã đặt") và các khung giờ trống hiển thị màu xám/xanh có thể chọn.
3. **Modal Đặt Sân & Quy trình PayOS/COD:**
   - Chọn một khung giờ trống bất kỳ để mở Modal Đặt Sân.
   - Chọn phương thức thanh toán:
     - **Thanh toán tại quầy (COD):** Nhấp đặt sân, kiểm tra xem có chuyển hướng sang trang lịch sử đặt sân kèm thông báo nhắc nhở giữ chỗ tạm thời hay không.
     - **Thanh toán trực tuyến (PayOS QR):** Nhấp thanh toán, kiểm tra xem hệ thống có tạo cổng thanh toán PayOS và chuyển hướng người dùng sang trang hiển thị mã QR thanh toán hoặc hiển thị modal QR PayOS hay không.

---

## 3. Bản đồ Full-screen (`customer/BanDo.jsp`)

*(Tham khảo thêm tài liệu chi tiết tại [docs/MAP_MANUAL_TEST.md](file:///home/nhan/Downloads/V-SPORT/docs/MAP_MANUAL_TEST.md))*

### Kịch bản kiểm thử nhanh:
1. **Hiển thị bản đồ:** Truy cập `/customer/ban-do`. Kiểm tra bản đồ hiển thị chiếm trọn màn hình.
2. **Bộ lọc trên sidebar:**
   - Lọc theo Bộ môn (bấm chip thể thao).
   - Lọc theo Bán kính (2km, 5km, 10km, 20km).
   - Lọc các cơ sở đang mở cửa (`openNow`).
3. **Định vị GPS:** Bấm nút định vị ở góc trên bên phải, đồng ý chia sẻ vị trí. Bản đồ sẽ tự vẽ Marker vị trí của bạn và sắp xếp danh sách cơ sở xung quanh.
4. **Tương tác Marker:**
   - **Desktop:** Nhấp vào marker hiển thị popup thông tin ngay trên bản đồ.
   - **Mobile:** Nhấp vào marker hiển thị Mobile Bottom Sheet trượt mượt mà từ dưới màn hình lên.

---

## 4. Ghép Kèo (`customer/GhepKeo.jsp`)

### Kịch bản kiểm thử:
1. **Các Tab chuyển đổi:**
   - Chuyển đổi qua lại giữa 4 Tab chính: **Kèo đang mở**, **Tạo kèo ghép**, **Tìm đối thủ gần đây**, và **Kèo của tôi**.
   - Kiểm tra xem nội dung của từng tab hiển thị đúng trạng thái.
2. **Danh sách kèo đang mở:**
   - Kiểm tra danh sách hiển thị các thẻ kèo ghép compact, bao gồm: tên người tạo kèo, điểm uy tín của họ, môn thể thao, thời gian, cơ sở và số slot trống còn lại.
   - Nhấp vào "Tham gia kèo" để kiểm tra luồng đăng ký tham gia (hiển thị thông báo xác nhận hoặc modal đăng ký thành công).
3. **Form tạo kèo mới:**
   - Vào tab "Tạo kèo ghép". Chọn lịch đặt sân của bạn, nhập trình độ mong muốn (Mới chơi, Trung bình, Khá, Chuyên nghiệp), viết mô tả ngắn và bấm "Tạo kèo". Đảm bảo form hoạt động ổn định và kiểm tra lỗi validation nếu để trống các trường bắt buộc.

---

## 5. Tài Khoản & Điểm Uy Tín (`customer/TaiKhoan.jsp`)

### Kịch bản kiểm thử:
1. **Bố cục Sidebar Tài Khoản:**
   - Kiểm tra thanh điều hướng tài khoản bên trái (hoặc phía trên trên mobile) hiển thị các danh mục: Thông tin cá nhân, Lịch sử đặt sân, Thống kê uy tín, và Đổi mật khẩu.
2. **Thẻ Điểm Uy Tín (Reputation Card):**
   - Kiểm tra điểm uy tín hiện tại của khách hàng hiển thị nổi bật với màu sắc tương ứng (ví dụ: Xanh lá cho điểm cao > 80, Cam cho điểm trung bình, Đỏ cho điểm cảnh báo < 50).
   - Kiểm tra bảng thống kê số lần hủy lịch muộn (Late cancel count), số lần đặt sân nhưng không đến (No-show count), và số lần hoàn thành lịch đặt (Completed booking count).
3. **Chỉnh sửa thông tin & Đổi mật khẩu:**
   - Cập nhật Họ tên, Số điện thoại và Email. Kiểm tra xem dữ liệu có lưu thành công vào cơ sở dữ liệu và hiển thị thông báo thành công hay không.
   - Điền form đổi mật khẩu với mật khẩu cũ không đúng để kiểm tra tính năng bảo mật mật khẩu.

---

## 6. Lịch Sử Đặt Sân (`customer/LichSuDatSan.jsp`)

### Kịch bản kiểm thử:
1. **Danh sách thẻ lịch đặt:**
   - Kiểm tra danh sách các lượt đặt sân được hiển thị dạng thẻ đẹp mắt, phân loại theo trạng thái rõ ràng (Đã xác nhận, Đã hoàn thành, Chờ thanh toán, Đã hủy).
   - Kiểm tra hiển thị tên sân, địa chỉ cơ sở, thời gian và số tiền đã thanh toán.
2. **Hủy đặt sân & Phạt Uy Tín:**
   - Chọn một lịch đặt sân "Đã xác nhận" sắp diễn ra.
   - Nhấp vào nút "Hủy đặt sân". Kiểm tra xem modal cảnh báo có hiển thị rõ ràng chính sách hủy sân (hủy trước bao nhiêu tiếng, số điểm uy tín bị trừ nếu hủy muộn) hay không.
   - Thực hiện hủy và kiểm tra xem trạng thái của lịch đặt có chuyển ngay thành "Đã hủy" và điểm uy tín trong hồ sơ tài khoản có bị trừ chính xác hay không.

---

## 7. Các trang Đăng Nhập / Đăng Ký (`auth/DangNhap.jsp`, `auth/DangKy.jsp`, `auth/AuthModal.jsp`)

### Kịch bản kiểm thử:
1. **Trang Đăng Nhập:**
   - Nhập tài khoản và mật khẩu để kiểm tra luồng đăng nhập.
   - Kiểm tra thiết kế biểu mẫu đăng nhập nằm giữa màn hình, các nút bấm bo góc 10px đồng bộ theo design system.
2. **Trang Đăng Ký:**
   - Kiểm tra form nhập liệu bao gồm: Họ tên, Số điện thoại, Email, Mật khẩu, Nhập lại mật khẩu.
   - Nhấp đăng ký và kiểm tra xem hệ thống có mã hóa BCrypt chính xác và lưu tài khoản mới vào cơ sở dữ liệu hay không.
