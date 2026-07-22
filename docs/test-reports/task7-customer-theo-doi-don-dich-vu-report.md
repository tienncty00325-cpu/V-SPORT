# Task 7 — Customer theo dõi đơn dịch vụ và timeline trạng thái

## Phạm vi

Customer xem danh sách đơn dịch vụ của mình (`/customer/dich-vu-cua-toi`), xem
chi tiết + timeline trạng thái, và hủy đơn còn ở trạng thái cho phép hủy.
Tái sử dụng `ServiceOrder`, `ServiceOrderStatusHistory` từ Task 5/6, không tạo
bảng mới.

## File liên quan

- `ServiceOrderService.java` — thêm `listForCustomer`, `getDetailForCustomer`,
  `cancelOrderByCustomer` (+ `CancelResult`/`CancelErrorCode`).
- `DichVuCuaToiServlet.java` — servlet trang, forward sang JSP.
- `DichVuCuaToiApiServlet.java` — API list + detail (JSON).
- `DichVuCuaToiCancelApiServlet.java` — API hủy đơn (JSON).
- `DichVuCuaToi.jsp` — giao diện danh sách + chi tiết + timeline.
- `TaiKhoan.jsp` — thêm mục menu "Dịch vụ của tôi" giữa "Kèo của tôi" và
  "Đổi mật khẩu".

## Bug phát hiện và đã sửa trong phiên này

1. **JPQL sai tên field (crash khi gọi list)** — `ServiceOrderService.
   listForCustomer` dùng `c.tenCoSo` (chữ thường) trong khi field thực tế
   trên entity `CoSo` là `TenCoSo` (viết hoa chữ T). Hibernate resolve
   attribute theo tên field Java, không theo tên cột DB, nên câu query này
   sẽ luôn ném `UnknownPathException` — tức là API list sẽ lỗi 100% nếu gọi
   thật. Phát hiện qua smoke test TC2, đã sửa thành `c.TenCoSo`.
2. **Thiếu auth check ở trang servlet** — `DichVuCuaToiServlet.doGet` forward
   thẳng sang JSP mà không kiểm tra session, khác với pattern chuẩn đã dùng ở
   các servlet trang Customer khác (`CustomerAccountServlet` và tương tự):
   kiểm tra `session.getAttribute("user")`, redirect `/dangnhap` nếu chưa
   đăng nhập, chặn nếu không phải role Customer. Đã thêm đúng pattern này.
   Trước khi sửa: gọi trực tiếp trang khi chưa đăng nhập trả về HTTP 200 và
   render JSP (JSP tự phụ thuộc dữ liệu tải qua API nên không lộ dữ liệu
   thật, nhưng vẫn là lệch chuẩn bảo mật của cả dự án và có thể gây lỗi JSP
   không được kiểm soát khi `user` null).

## Service-layer smoke test (14/14 PASS)

Chạy qua đúng `JPAUtil`/Hibernate, không mock, kết nối `.env.local` thật.

File: `src/main/java/org/example/test/DichVuCuaToiSmokeTest.java`
Lệnh: `mvn -q -o compile exec:java -Dexec.mainClass=org.example.test.DichVuCuaToiSmokeTest`

DB thực tế lúc kiểm tra không có sẵn `ServiceOrder`/`SportService` nào — test
tự seed tối thiểu (2 `ServiceOrder` cho 2 `TaiKhoan` khác nhau + 1
`SportService` nếu cần) trong transaction riêng, chạy xong tự dọn sạch lại
(đã xác nhận DB về đúng 0 `ServiceOrder` sau khi chạy).

Kết quả:

```
[PASS] TC1_has_seed_data
[PASS] TC2_list_not_null
[PASS] TC3_list_has_items
[PASS] TC4_list_items_wellformed
[PASS] TC5_pagination_consistent
[PASS] TC6_counts_present
[PASS] TC7_filter_by_uiGroup
[PASS] TC8_detail_owner_ok
[PASS] TC9_detail_has_orderId
[PASS] TC10_detail_nonexistent_order_null
[PASS] TC11_detail_wrong_owner_null
[PASS] TC12_cancel_empty_reason_rejected
[PASS] TC13_cancel_nonexistent_not_found
[PASS] TC14_cancel_wrong_owner_not_found

=== 14 PASS / 0 FAIL ===
```

TC10/TC11/TC13/TC14 xác nhận IDOR policy: sai chủ sở hữu hoặc order không tồn
tại đều trả về cùng một kết quả "không tìm thấy" (null / `NOT_FOUND`), không
phân biệt hai trường hợp để tránh lộ thông tin tồn tại của đơn.

## HTTP gate (Tomcat 10.1.55, context `/Backend_java`)

Build WAR (`mvn -o package -DskipTests`), copy vào
`~/Downloads/apache-tomcat-10.1.55/webapps/Backend_java.war`, Tomcat tự động
redeploy. Không có exception lúc khởi động.

| Endpoint | Không có session | Kỳ vọng |
|---|---|---|
| `GET /customer/dich-vu-cua-toi` | `302 → /Backend_java/dangnhap` | PASS (sau khi sửa bug thiếu auth check) |
| `GET /api/customer/dich-vu-cua-toi` | `401` + `{"success":false,"message":"Vui lòng đăng nhập."}` | PASS |
| `POST /api/customer/dich-vu-cua-toi/huy` | `401` + cùng message | PASS |

Không test luồng có session thật qua curl trong phiên này để tránh phải xử lý
thủ công mật khẩu tài khoản test qua terminal output. Luồng có session được
verify gián tiếp qua 14 smoke test ở tầng Service (dùng đúng session logic
tương đương — so sánh `customerId` với `TaiKhoan.getAccountId()`) và qua việc
servlet trang giờ dùng đúng pattern check-session giống các servlet Customer
khác đã được test trong `AUTH_PORTALS_MANUAL_TEST.md`.

## CSRF — technical debt toàn hệ thống, không tự tạo riêng cho Task 7

Xác nhận lại: dự án hiện chưa có CSRF filter/token ở bất kỳ đâu, không chỉ
riêng Task 7. `DichVuCuaToiCancelApiServlet` (POST, có side-effect) cũng
không có CSRF token, giống toàn bộ các API POST khác trong dự án. Đây là nợ
kỹ thuật có sẵn, không thuộc phạm vi Task 7 để tự ý vá riêng lẻ.

## Việc chưa làm / hạn chế đã biết

- Chưa test UI/responsive bằng trình duyệt thật (không có Chrome/browser
  tool khả dụng ổn định trong phiên này) — JSP đã qua kiểm tra tĩnh, forward
  không lỗi runtime, nhưng chưa xác nhận bằng mắt trên nhiều kích thước màn
  hình.
- Chưa login bằng tài khoản test thật qua HTTP để chụp toàn bộ luồng
  list → detail → cancel end-to-end qua trình duyệt.
