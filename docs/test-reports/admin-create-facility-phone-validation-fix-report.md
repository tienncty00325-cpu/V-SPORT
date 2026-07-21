# Báo Cáo Sửa Lỗi Xác Thực Số Điện Thoại Khi Thêm Cơ Sở Mới (Role Admin)

## 1. Mô tả lỗi (Bug Description)
Trong giao diện quản lý chi nhánh dành cho Admin (`/admin/chi-nhanh`), khi mở modal **"Thêm Cơ Sở mới"** (Bước 1/3), Admin nhập đầy đủ thông tin:
*   **Tên cơ sở:** *sân haven*
*   **Email liên hệ:** *nguyenthien13334@gmail.com*
*   **Số điện thoại:** *0848554039*
*   **Địa chỉ:** *bà rịa*

Tuy nhiên, khi nhấn nút **"Tiếp tục — Xác thực Email"**, hệ thống xuất hiện thông báo lỗi bằng tiếng Việt:
> **"Số điện thoại không được để trống."**

Mặc dù ô nhập liệu "Số điện thoại" đang hiển thị giá trị đầy đủ và không hề bị khóa (disabled) hay trống.

---

## 2. Phân tích nguyên nhân gốc rễ (Root Cause Analysis)

### Luồng gọi API gửi OTP
1. Khi bấm nút **"Tiếp tục — Xác thực Email"**, hàm JavaScript `adminSendOtp()` trong `QuanLyChiNhanh.jsp` được thực thi.
2. Hàm này thu thập dữ liệu nhập từ các ô Input:
   ```javascript
   const name  = document.getElementById('adminTenCoSo').value.trim();
   const email = document.getElementById('adminEmail').value.trim();
   const phone = document.getElementById('adminPhone').value.trim();
   const addr  = document.getElementById('adminDiaChi').value.trim();
   ```
3. Sau đó, nó gửi một yêu cầu HTTP POST bằng Fetch API đến endpoint `/owner/send-otp` (do `OwnerRegisterServlet.java` đảm nhận):
   ```javascript
   fetch('${pageContext.request.contextPath}/owner/send-otp', {
     method: 'POST',
     headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
     body: 'email=' + encodeURIComponent(email) // <--- Chỉ gửi duy nhất tham số email!
   })
   ```
   **Vấn đề:** Tham số `phone` (Số điện thoại) hoàn toàn không được truyền vào chuỗi `body` gửi đi.

### Xử lý phía Backend (`OwnerRegisterServlet.java`)
Trong servlet xử lý `/owner/send-otp`, phương thức `handleSendOtp` thực hiện kiểm tra bắt buộc cả `email` và `phone`:
```java
String email = req.getParameter("email");
String phone = req.getParameter("phone");
...
if (phone == null || phone.isEmpty()) {
    out.print("{\"success\":false,\"message\":\"Số điện thoại không được để trống.\"}");
    return;
}
if (!ValidationUtil.isValidVNPhone(phone)) {
    out.print("{\"success\":false,\"message\":\"Số điện thoại không hợp lệ.\"}");
    return;
}
```
Vì phía Frontend không truyền tham số `phone`, servlet nhận giá trị `null` và lập tức trả về phản hồi JSON lỗi:
`{"success":false,"message":"Số điện thoại không được để trống."}`

Lỗi tương tự cũng xảy ra tại hàm gửi lại mã OTP `adminResendOtp()` khi gọi lại `/owner/send-otp` mà không truyền kèm số điện thoại.

---

## 3. Giải pháp khắc phục (Resolution)

Chúng tôi đã tiến hành cập nhật tệp JSP [QuanLyChiNhanh.jsp](file:///home/nhan/Downloads/V-SPORT/src/main/webapp/admin/QuanLyChiNhanh.jsp):

1.  **Cập nhật `adminSendOtp()`**:
    *   Thêm kiểm tra định dạng số điện thoại Việt Nam hợp lệ ở Frontend trước khi gửi:
        ```javascript
        if (!/^(0|\+84)[35789][0-9]{8}$/.test(phone)) return showAdminError('Số điện thoại không hợp lệ.');
        ```
    *   Truyền cả tham số `phone` trong phần body của yêu cầu fetch:
        ```javascript
        body: 'email=' + encodeURIComponent(email) + '&phone=' + encodeURIComponent(phone)
        ```

2.  **Cập nhật `adminResendOtp()`**:
    *   Lấy giá trị số điện thoại từ ô input `#adminPhone` và đính kèm vào body của fetch:
        ```javascript
        const phone = document.getElementById('adminPhone').value.trim();
        fetch('${pageContext.request.contextPath}/owner/send-otp', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: 'email=' + encodeURIComponent(email) + '&phone=' + encodeURIComponent(phone)
        })
        ```

---

## 4. Chi tiết thay đổi (Diff Block)

```diff
diff --git a/src/main/webapp/admin/QuanLyChiNhanh.jsp b/src/main/webapp/admin/QuanLyChiNhanh.jsp
index 3a51f7e..7e82b7c 100644
--- a/src/main/webapp/admin/QuanLyChiNhanh.jsp
+++ b/src/main/webapp/admin/QuanLyChiNhanh.jsp
@@ -580,2 +580,3 @@
     if (!email) return showAdminError('Vui lòng nhập email liên hệ.');
     if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return showAdminError('Email không hợp lệ.');
     if (!phone) return showAdminError('Vui lòng nhập số điện thoại.');
+    if (!/^(0|\+84)[35789][0-9]{8}$/.test(phone)) return showAdminError('Số điện thoại không hợp lệ.');
     if (!addr)  return showAdminError('Vui lòng nhập địa chỉ.');
 
     const btn = document.getElementById('btnSendOtp');
@@ -588,3 +589,3 @@
     fetch('${pageContext.request.contextPath}/owner/send-otp', {
       method: 'POST',
       headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
-      body: 'email=' + encodeURIComponent(email)
+      body: 'email=' + encodeURIComponent(email) + '&phone=' + encodeURIComponent(phone)
     })
@@ -711,2 +712,3 @@
     const email = document.getElementById('adminEmail').value.trim();
+    const phone = document.getElementById('adminPhone').value.trim();
     fetch('${pageContext.request.contextPath}/owner/send-otp', {
       method: 'POST',
       headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
-      body: 'email=' + encodeURIComponent(email)
+      body: 'email=' + encodeURIComponent(email) + '&phone=' + encodeURIComponent(phone)
     }).then(r => r.json()).then(data => {
```

---

## 5. Kết luận và Kiểm thử (Verification)
*   **Trạng thái:** Đã sửa lỗi (Fixed).
*   **Kiểm thử:** Sau khi áp dụng thay đổi, luồng xác thực 3 bước hoạt động trơn tru:
    1.  Admin điền đầy đủ 4 trường ở bước 1 và bấm **"Tiếp tục — Xác thực Email"** -> Không còn báo lỗi số điện thoại trống, hệ thống gửi OTP thành công và chuyển sang bước 2.
    2.  Nhập mã OTP đúng -> Lưu các giá trị vào hidden fields và chuyển sang cấu hình cơ sở (Bước 3).
    3.  Lưu cơ sở mới -> Tạo cơ sở thành công trong cơ sở dữ liệu.
