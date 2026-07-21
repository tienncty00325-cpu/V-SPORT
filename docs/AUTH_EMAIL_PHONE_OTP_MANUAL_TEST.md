# Manual Test — Đăng ký/Đăng nhập Email·Phone + Forgot Password OTP

Chạy app: `.\start_server.bat` (hoặc SmartTomcat) rồi mở `http://localhost:8080/Backend_java/`.

Routes chính:
- Customer login `GET/POST /dangnhap` · Internal login `/he-thong/dang-nhap`
- Register `GET/POST /dangky`
- Customer forgot `/quenmatkhau` → OTP `/nhapma` → mật khẩu mới `/nhapmatkhaumoi`
- Internal forgot `/he-thong/quen-mat-khau` → OTP `/he-thong/xac-thuc-otp` → mật khẩu mới `/he-thong/dat-lai-mat-khau`
- Resend OTP: `/resend-otp`

## REGISTER
1. [ ] Đăng ký Customer mới với Email + Phone hợp lệ → nhận OTP đăng ký, tạo tài khoản thành công.
2. [ ] Email đã tồn tại → báo lỗi, không tạo.
3. [ ] Phone đã tồn tại (thử cả dạng 0/ +84/ 84) → báo lỗi.
4. [ ] Email sai định dạng → lỗi validate.
5. [ ] Phone sai định dạng → lỗi validate.

## LOGIN
6. [ ] Customer đăng nhập bằng Email (tab Email).
7. [ ] Customer đăng nhập bằng Phone dạng `0786041209`.
8. [ ] Customer đăng nhập bằng Phone dạng `+84786041209`.
9. [ ] Sai mật khẩu → "…không đúng", không lộ tài khoản tồn tại.
10. [ ] Email không tồn tại → message generic.
11. [ ] Phone không tồn tại → message generic.
12. [ ] Staff đăng nhập bằng Email tại `/he-thong/dang-nhap` → redirect trang Staff.
13. [ ] Manager đăng nhập bằng Email → trang Manager.
14. [ ] Admin đăng nhập bằng Email → trang Admin.
15. [ ] Internal đăng nhập bằng Phone: CHƯA hỗ trợ tại form nội bộ (form nội bộ nhận username/email) — ghi nhận.
16. [ ] Username cũ vẫn đăng nhập được (backward-compatible fallback, cả 2 cổng).

## CUSTOMER FORGOT PASSWORD
17. [ ] Email Customer hợp lệ → spinner trong nút → nhận email OTP thật → redirect `/nhapma` (card OTP, email được hiển thị).
18. [ ] Email không tồn tại → ở lại trang, "Không thể gửi mã đến email này…", KHÔNG chuyển OTP.
19. [ ] Email của Admin/Manager/Staff nhập tại cổng Customer → như mục 18, không lộ role.
20. [ ] Phone Customer hợp lệ → OTP gửi tới email liên kết, hiển thị email đã che.
21. [ ] Phone không tồn tại → như mục 18.
22. [ ] Account có phone nhưng không có email hợp lệ → không chuyển OTP, message an toàn.
23. [ ] SMTP lỗi (tắt mạng / sai app password) → "Hiện chưa thể gửi mã xác thực…", spinner reset, không chuyển OTP.

## INTERNAL FORGOT PASSWORD
24. [ ] Email Staff hợp lệ → redirect `/he-thong/xac-thuc-otp`, card OTP theme Operations Portal, badge OPERATIONS PORTAL, email che dạng `n***@gmail.com`.
25. [ ] Email Manager hợp lệ → như trên.
26. [ ] Email Admin hợp lệ → như trên.
27. [ ] Email Customer nhập tại Internal → ở lại form, message generic, KHÔNG chuyển OTP.
28. [ ] Email không tồn tại → như mục 27.
29. [ ] SMTP lỗi → ở lại form với lỗi an toàn.

## OTP (cả 2 cổng)
30. [ ] OTP đúng → chuyển trang tạo mật khẩu mới (customer: `/auth/NhapMatKauMoi.jsp`; internal: card "Tạo mật khẩu mới" Operations theme).
31. [ ] OTP sai → "Mã xác thực không chính xác.", spinner reset, focus lại ô mã.
32. [ ] OTP quá 10 phút → "không hợp lệ hoặc đã hết hạn".
33. [ ] OTP đúng dùng lần 2 (back + resubmit) → bị từ chối (one-time-use).
34. [ ] Resend: countdown 60s hiển thị; sau 60s bấm "Gửi lại mã" → email mới, mã cũ vô hiệu; gửi lỗi SMTP → mã cũ VẪN còn hiệu lực.
35. [ ] Gõ trực tiếp `/nhapma` hoặc `/he-thong/xac-thuc-otp` khi không có challenge → redirect về trang quên mật khẩu đúng cổng.
36. [ ] Đặt mật khẩu mới (đủ policy: ≥8, hoa, thường, số, ký tự đặc biệt) → thành công, redirect Login đúng cổng.
37. [ ] Đăng nhập bằng mật khẩu CŨ → thất bại.
38. [ ] Đăng nhập bằng mật khẩu MỚI → thành công, redirect đúng dashboard theo role.
39. [ ] "Đổi email" tại trang OTP → quay lại form, challenge cũ bị hủy (OTP cũ không dùng được nữa).
40. [ ] Kiểm tra log: không có OTP raw / password / SMTP password.

## SMTP config (tùy chọn)
Đặt env trước khi chạy Tomcat để override: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD` (Gmail App Password), `SMTP_FROM`. Không đặt thì dùng cấu hình dev sẵn có.
