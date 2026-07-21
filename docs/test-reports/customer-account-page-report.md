# Báo cáo: Xây dựng trang "Tài khoản khách hàng" (`/customer/tai-khoan`)

**Ngày:** 2026-07-16
**Phạm vi:** Route `/customer/tai-khoan`, backend hồ sơ/đổi mật khẩu, JSP giao diện, dropdown tài khoản Customer.

## 1. Root cause của lỗi 404

`/customer/tai-khoan` chưa từng được map tới bất kỳ servlet nào. `DatSanServlet` (org.example.controller.customer) chỉ khai báo:

```java
@WebServlet(urlPatterns = { "/customer/dat-san", "/customer/dat_san", "/customer/lich-su-dat-san",
    "/customer/huy-dat-san", "/customer/dat-dich-vu", "/customer/chi-tiet-san",
    "/customer/payos-return", "/customer/payos-cancel", "/customer/payos-status" })
```

Không có `/customer/tai-khoan` trong danh sách này, và không có servlet nào khác claim route đó. Dropdown ở cả `common/header.jsp` (dòng 764) và `index.jsp` (dòng 605, dùng scriptlet `<%= ctx %>`) **đã link đúng** tới `${pageContext.request.contextPath}/customer/tai-khoan` từ trước — phần liên kết dropdown không phải nguyên nhân. Root cause thuần túy là thiếu servlet/controller cho route này → Tomcat trả `HTTP 404`.

## 2. Route/servlet mapping đã sửa

Tạo mới `CustomerAccountServlet` ([src/main/java/org/example/controller/customer/CustomerAccountServlet.java](../../src/main/java/org/example/controller/customer/CustomerAccountServlet.java)):

```java
@WebServlet("/customer/tai-khoan")
public class CustomerAccountServlet extends HttpServlet { ... }
```

`GET /customer/tai-khoan` forward tới `/customer/TaiKhoan.jsp` (nằm ngoài `WEB-INF`, cùng khu vực với `DatSan.jsp`, `LichSuDatSan.jsp` — đúng convention hiện tại của project, không có servlet nào khác forward sai/redirect vòng lặp).

Cập nhật/mở rộng logic (không tạo servlet trùng) trên `UpdateProfileServlet` đã có sẵn ([src/main/java/org/example/controller/UpdateProfileServlet.java](../../src/main/java/org/example/controller/UpdateProfileServlet.java), map `/account/update-profile`) để hỗ trợ thêm `birthday`/`gender` và validation chặt hơn — servlet này vốn đã phục vụ Admin/Manager/Staff/Customer dùng chung (`{"/admin/update-profile", "/manager/update-profile", "/staff/update-profile", "/account/update-profile"}`).

## 3. Session AccountID được lấy thế nào

Session lưu object `TaiKhoan` đầy đủ dưới key **`user`** (đặt tại `DangNhapServlet.java` dòng 122: `session.setAttribute("user", taiKhoan)`), cùng các key phụ `roleId`, `accountId`, `fullName`, `email`. `CustomerAccountServlet` chỉ đọc `((TaiKhoan) session.getAttribute("user")).getAccountId()` để xác định người dùng, **không** nhận `accountId` từ query string — `/customer/tai-khoan?accountId=13` không có hiệu lực gì vì servlet không đọc request parameter này.

Sau khi lấy `AccountID` từ session, servlet **luôn nạp lại bản ghi mới nhất từ DB** qua `TaiKhoanDAO.getAccountById()` thay vì tin dữ liệu cũ trong session, và chặn nếu tài khoản `IsDeleted=1` hoặc `IsLocked=1` (invalidate session, redirect `/dangnhap`).

RoleID Customer xác nhận qua hằng số có sẵn `RoleRedirectUtil.ROLE_CUSTOMER = 3` (bảng `Roles`: 1=Admin, 2=Manager, 3=Customer, 4=Lễ tân, 5=Bảo vệ) — không hard-code số 3 rời rạc trong code mới.

## 4. Giao diện trang tài khoản

`src/main/webapp/customer/TaiKhoan.jsp` — layout 2 cột trong khung `max-w-[1180px]`, dùng Tailwind (đã có sẵn qua CDN ở `common/head.jsp`), font/màu theo design token thật của Customer Portal (không dùng tím lớn — primary action dùng `emerald-600`, đúng convention đã thấy ở `LichSuDatSan.jsp` sibling page; card bo góc `14px`, border mỏng `#e2e8f0`, không shadow nặng, không banner gradient lớn):

- Breadcrumb "Trang chủ / Tài khoản"
- Page header: tiêu đề + mô tả + nút "Đặt sân mới"
- Profile summary: avatar (ảnh thật hoặc initials), họ tên, email, số điện thoại, badge "Đang hoạt động", ngày tham gia (`CreatedAt`)
- Quick statistics: 4 thẻ — Lịch sắp tới / Đã hoàn thành / Đã hủy / Tổng lịch đặt (chỉ số liệu thật từ DB, không có điểm thưởng/hạng VIP vì schema không có nghiệp vụ này)
- Upcoming booking: 1 lịch sắp tới gần nhất (tên sân, cơ sở, loại sân, ngày/giờ, trạng thái, mã đơn) hoặc Empty State "Bạn chưa có lịch đặt sân sắp tới." + nút "Đặt sân ngay"
- Personal information: View mode / Edit mode (form ẩn/hiện, không dùng input disabled xám)
- Security: mô tả BCrypt + nút mở modal đổi mật khẩu
- Quick links: Đặt sân mới / Lịch sử đặt sân / Trang chủ (không thêm "Liên hệ hỗ trợ" vì header hiện tại chưa có route thật cho mục này — tránh tạo link chết)

## 5. Hồ sơ cá nhân

Field: Họ và tên, Email, Số điện thoại, Ngày sinh (`NgaySinh`), Giới tính (`GioiTinh`) — đúng tên cột thật trong bảng `Accounts`. Nút "Chỉnh sửa" chuyển form sang Edit mode tại chỗ (không reload trang), gọi AJAX `POST /account/update-profile?action=updateInfo`. Sau khi lưu thành công: cập nhật DOM (view mode + profile summary) và `session.setAttribute("user", account)` để header/dropdown đổi tên ngay — không cần logout/login lại.

Nếu đổi Email: giữ nguyên luồng OTP email đã có sẵn của hệ thống (gửi mã 6 số, TTL 5 phút) — modal xác thực OTP được thêm vào trang, cùng phong cách nhẹ/sáng với phần còn lại.

## 6. Validation

Toàn bộ validate ở server (`UpdateProfileServlet`), client chỉ là UX phụ trợ:

- Họ tên: bắt buộc, trim, 2–100 ký tự, cho phép tiếng Việt có dấu
- Email: bắt buộc, đúng định dạng, unique loại trừ chính tài khoản hiện tại (`emailChanged && kiemtraEmail(email)` — cho phép giữ nguyên email cũ)
- Số điện thoại: bắt buộc, đúng định dạng VN (`ValidationUtil.isValidVNPhone`) — **không** kiểm tra unique vì cột `PhoneNumber VARCHAR(15)` trong schema **không có `UNIQUE` constraint** (đã xác minh trực tiếp từ `Tài nguyên/QuanLiSport_V4.sql`), giữ đúng theo dữ liệu thật thay vì tự đặt luật không có trong DB
- Ngày sinh: không được ở tương lai, không tự thêm giới hạn tuổi (không có trong nghiệp vụ)
- Giới tính: whitelist `Nam` / `Nữ` / `Khác` (đúng theo `DangKy.jsp`/`AuthModal.jsp` hiện dùng)

Lỗi trả JSON có `code: "VALIDATION_ERROR"` và `fieldErrors` gắn đúng field, không trả HTML lỗi Tomcat cho request AJAX.

## 7. Đổi mật khẩu

Modal riêng trong `TaiKhoan.jsp`, gọi `POST /account/update-profile?action=changePassword`:

1. Mật khẩu hiện tại bắt buộc, verify bằng `BCrypt.checkpw()`
2. Mật khẩu mới theo policy có sẵn (`ValidationUtil.isStrongPassword`: ≥8 ký tự, hoa/thường/số/ký tự đặc biệt)
3. **[Mới bổ sung]** Mật khẩu mới không được trùng mật khẩu hiện tại (`BCrypt.checkpw(newPassword, hash)` phải `false`)
4. **[Mới bổ sung]** Xác nhận mật khẩu mới phải khớp — kiểm tra cả client và server (tham số `confirmPassword`)
5. Hash bằng `BCrypt.hashpw(newPassword, BCrypt.gensalt(12))` trước khi lưu, không lưu plaintext, không log password, không trả hash về JSON
6. Sai mật khẩu hiện tại → thông báo rõ, không tiết lộ thông tin tài khoản khác
7. Sau thành công: giữ nguyên phiên đăng nhập (đúng hành vi cũ), hiện toast "Mật khẩu đã được cập nhật.", xóa toàn bộ input password khỏi form (`form.reset()` + gán rỗng thủ công trong `finally`)

## 8. Booking statistics

Tính từ `LichDatSanDAO.getLichByAccountId(accountId)` (đã tự động lọc `IsDeleted=0` và sweep các đơn hết hạn) — không dùng dữ liệu mẫu:

- **Lịch sắp tới**: trạng thái khác "Đã hủy"/"Đã hoàn thành" và thời điểm kết thúc (`NgayDat` + `GioKetThuc`) còn ở tương lai
- **Đã hoàn thành**: `TrangThai = 'Đã hoàn thành'`
- **Đã hủy**: `TrangThai = 'Đã hủy'`
- **Tổng lịch đặt**: tổng số bản ghi

## 9. Upcoming booking

Chọn bản ghi "sắp tới" có `NgayDat`+`GioBatDau` sớm nhất. Resolve tên sân/cơ sở/loại sân qua `SanDAO.getSanById`, `CoSoDAO.getCoSoById`, `LoaiSanDAO.getLoaiSanById` — có fallback "Sân #ID" nếu sân đã bị xóa. Badge trạng thái dùng đúng bảng màu đã thiết lập ở `LichSuDatSan.jsp` (Chờ duyệt=amber, Đã xác nhận=emerald, Đang sử dụng=purple, mở rộng thêm "Chờ thanh toán"/"Đã thanh toán"/"Đã cọc" theo đúng các giá trị `TrangThai` thật đang tồn tại trong DAO — không phát minh cột "trạng thái thanh toán" riêng vì schema không có cột này).

## 10. Dropdown account

Phát hiện **2 header riêng biệt** dùng song song trong dự án: `common/header.jsp` (dùng cho các trang con Customer như `DatSan.jsp`) và một header inline khác ngay trong `index.jsp` (trang chủ, dùng Java scriptlet). Cả hai **đã link đúng** `/customer/tai-khoan` từ trước; đã chỉnh sửa cả hai:

- Chuẩn hóa nhãn: "Tài Khoản" → "Tài khoản", "Lịch Sử Đặt Sân" → "Lịch sử đặt sân", "Đăng Xuất" → "Đăng xuất"
- Thêm `aria-haspopup="true"`, `aria-expanded` (đồng bộ true/false khi mở/đóng) trên nút trigger ở cả 2 header
- Thêm đóng bằng phím Escape ở header của `index.jsp` (header.jsp con đã có sẵn)
- Click ngoài đóng dropdown: đã có sẵn ở cả hai, giữ nguyên
- Vá lỗ hổng XSS tiềm ẩn: `<%= displayName %>` và `<%= avatarChar %>` trong `index.jsp` trước đây in thẳng ra HTML không escape — thêm `displayNameSafe`/`avatarCharSafe` (escape `& < > " '`) và thay thế tại 2 vị trí render (dropdown + drawer mobile). `header.jsp` cũng chuyển `${user.fullName}`/`${user.username}` sang `${fn:escapeXml(...)}`.

## 11. Responsive

`TaiKhoan.jsp` dùng lưới Tailwind chuẩn: `grid-cols-1 lg:grid-cols-3` (desktop 2 cột chính + 1 cột phụ), `grid-cols-2 sm:grid-cols-4` cho thống kê nhanh, modal đổi mật khẩu/OTP căn giữa với `p-4` lề an toàn trên mobile, nút hành động dùng `w-full` trên breakpoint nhỏ. Chưa test được bằng tài khoản thật (xem mục 18); đã review code không có phần tử cố định chiều rộng lớn hơn viewport (không dùng `<table>` cho lịch gần nhất, chỉ dùng card).

## 12. Accessibility

- `aria-haspopup`, `aria-expanded` trên nút mở dropdown tài khoản (cả 2 header)
- Đóng dropdown bằng Escape (cả 2 header)
- Nhãn `for`/`id` khớp cho toàn bộ input trong form hồ sơ và đổi mật khẩu
- `aria-label="Breadcrumb"` cho nav breadcrumb

## 13. Security

- `PreparedStatement`/JPA `EntityManager` cho toàn bộ truy vấn (tái sử dụng DAO có sẵn, không viết SQL mới)
- JSTL/EL cho toàn bộ `TaiKhoan.jsp` (không scriptlet Java)
- GET không thay đổi dữ liệu — chỉ đọc; mọi thay đổi đi qua `POST /account/update-profile`
- Không tin `AccountID` từ client — luôn lấy từ session, nạp lại từ DB
- Không lộ stack trace ra JSON (catch generic, chỉ trả `e.getMessage()` đã qua hàm `json()` escape)
- Không log password ở bất kỳ đâu
- XSS: `fn:escapeXml()` cho toàn bộ field do người dùng nhập khi render trong `TaiKhoan.jsp` (FullName, Email, Phone, GioiTinh, tên sân/cơ sở/loại sân, TrangThai) và đã vá thêm 2 vị trí tương tự trong `index.jsp` (mục 10)

## 14. File đã sửa

| File | Thay đổi |
|---|---|
| `src/main/java/org/example/controller/customer/CustomerAccountServlet.java` | **Mới** — route `/customer/tai-khoan` |
| `src/main/java/org/example/controller/UpdateProfileServlet.java` | Thêm field `birthday`/`gender`, validation chặt hơn (độ dài họ tên, `fieldErrors`), mật khẩu mới không trùng mật khẩu cũ, xác nhận mật khẩu khớp |
| `src/main/webapp/customer/TaiKhoan.jsp` | **Mới** — giao diện trang tài khoản |
| `src/main/webapp/common/header.jsp` | Chuẩn hóa nhãn dropdown, `aria-expanded`, escape `fn:escapeXml` |
| `src/main/webapp/index.jsp` | Chuẩn hóa nhãn dropdown, `aria-expanded`, Escape-to-close, vá XSS `displayName`/`avatarChar` |

## 15. Build/test

- `mvn clean compile` — **BUILD SUCCESS**
- `mvn test` — 73/80 test pass; 7 fail đều là script tiện ích cần `DB_URL`/`DB_PASSWORD` (biến môi trường không có sẵn trong shell của agent), không liên quan tới code mới, không phải regression (đã xác nhận bằng cách đọc log lỗi: toàn bộ là `IllegalStateException: Cấu hình bắt buộc bị thiếu: env DB_URL`)
- `mvn -DskipTests clean package` — **BUILD SUCCESS**
- Deploy: SmartTomcat của IntelliJ (`docBase` trỏ thẳng `src/main/webapp`, `PreResources` trỏ `target/classes`) đã chạy sẵn khi bắt đầu — không kill tiến trình của IDE (không có `DB_PASSWORD` để tự khởi động lại an toàn). Kích hoạt Tomcat context reload không phá hoại bằng cách `touch WEB-INF/web.xml` (watched resource mặc định của Tomcat, không cần khởi động lại thủ công) để nạp servlet Java mới.

## 16. Playwright / xác nhận runtime

Không có Playwright trong dự án (chỉ có `node_modules/playwright*` do dependency gián tiếp, không có test suite Playwright thật). Đã dùng Browser tool để xác nhận qua HTTP thật:

- `GET /customer/tai-khoan` (chưa đăng nhập) → trước: `404 Not Found`; sau: redirect `→ /dangnhap → /index.jsp?auth=login` (đúng hành vi "chưa đăng nhập → redirect login")
- Console/Network trên trang chủ sau khi sửa: không có lỗi JS, không có request 404 mới
- `aria-expanded`/`aria-haspopup` xuất hiện đúng trên nút tài khoản ở trang chủ sau khi sửa

**Chưa test được** (do người dùng chọn bỏ qua bước cung cấp tài khoản Customer thật để giữ an toàn dữ liệu — xem mục 18): xem hồ sơ với dữ liệu thật, sửa hồ sơ, đổi mật khẩu, hiển thị lịch sắp tới/empty state, responsive trên các viewport cụ thể, RoleID khác (Manager/Staff) nhận 403.

## 17. Screenshots

Không chụp được ảnh trang `/customer/tai-khoan` đã đăng nhập vì không có tài khoản test. Đã xác nhận bằng `get_page_text`/`read_network_requests`/`read_console_messages` thay cho ảnh chụp màn hình.

## 18. Hạn chế còn lại

1. **Chưa verify bằng tài khoản Customer thật** (login, sửa hồ sơ, đổi mật khẩu, xem lịch sắp tới, responsive 5 viewport) — cần một tài khoản Customer test cô lập để hoàn tất Test 1, 4–19 trong yêu cầu gốc.
2. `/customer/lich-su-dat-san` (GET) hiện vẫn `redirect` sang `/customer/dat-san?openHistory=true` thay vì render trực tiếp `LichSuDatSan.jsp` — hành vi này **không đổi**, giữ nguyên như trước khi có thay đổi này (không nằm trong phạm vi yêu cầu).
3. Trang `TaiKhoan.jsp` chưa có ô "Liên hệ hỗ trợ" trong Quick Links vì header hiện tại chưa có route thật cho mục này (tránh tạo link chết theo đúng yêu cầu).
4. Đã mở rộng `UpdateProfileServlet` (dùng chung cho Admin/Manager/Staff/Customer) để hỗ trợ `birthday`/`gender` — các trang Admin/Manager hiện tại không gửi 2 field này nên không bị ảnh hưởng, nhưng nên được các đội Admin/Manager review nếu muốn tận dụng field mới.
