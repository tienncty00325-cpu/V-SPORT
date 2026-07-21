# Manual Test — Quên mật khẩu / Đặt lại mật khẩu (2 cổng)

Routes:
- Customer request: `GET/POST /quenmatkhau`
- Internal request: `GET/POST /he-thong/quen-mat-khau`
- Verify OTP: `POST /nhapma` · Resend: `GET|POST /resend-otp`
- New password: `GET/POST /nhapmatkhaumoi`

Điều kiện: SMTP hoạt động (EmailUtil), DB dev/test, có tài khoản Customer và Staff/Manager/Admin với email thật kiểm soát được.

## Checklist

1. [ ] Customer — email hợp lệ: nhận OTP qua email, response generic, chuyển trang nhập mã.
2. [ ] Customer — email không tồn tại: response generic y hệt (không lộ tài khoản), sang trang nhập mã, mọi OTP đều bị từ chối (decoy).
3. [ ] Customer — phone hợp lệ (0 / +84 / 84): tìm đúng tài khoản, OTP gửi về email đã đăng ký, UI chỉ hiện "email đã đăng ký của bạn" (không lộ email).
4. [ ] Customer — phone không tồn tại: response generic, decoy challenge.
5. [ ] Customer nhập email của tài khoản Staff/Manager/Admin: response generic, KHÔNG gửi OTP, không lộ role.
6. [ ] Internal — email Staff/Manager/Admin hợp lệ: nhận OTP, flow tiếp tục.
7. [ ] Internal nhập email Customer: response generic, không gửi OTP.
8. [ ] OTP đúng → chuyển trang tạo mật khẩu mới.
9. [ ] OTP sai → "Mã xác thực không chính xác", attempt tăng.
10. [ ] OTP hết hạn (>10 phút) → "không hợp lệ hoặc đã hết hạn".
11. [ ] Nhập sai 5 lần → khóa challenge, buộc yêu cầu mã mới.
12. [ ] Resend trước 60s → thông báo chờ; countdown hiển thị trên UI; resend sau 60s gửi mã MỚI và mã cũ vô hiệu; tối đa 5 lần gửi.
13. [ ] Mật khẩu xác nhận không khớp → lỗi, không đổi mật khẩu.
14. [ ] Mật khẩu yếu (thiếu hoa/thường/số/ký tự đặc biệt/thiếu 8 ký tự) → lỗi policy.
15. [ ] Reset thành công → thông báo, redirect trang đăng nhập đúng portal (Customer → DangNhap, Internal → DangNhapNoiBo), session reset bị xóa.
16. [ ] Đăng nhập bằng mật khẩu CŨ sau reset → thất bại.
17. [ ] Đăng nhập bằng mật khẩu MỚI → thành công.
18. [ ] Customer reset xong đăng nhập tại cổng khách hàng bình thường.
19. [ ] Staff reset xong đăng nhập tại `/he-thong/dang-nhap`, redirect trang Staff.
20. [ ] Manager tương tự → trang Manager.
21. [ ] Admin tương tự → trang Admin.
22. [ ] Gửi >5 request cùng identifier (hoặc >12 cùng IP) trong 15 phút → "Bạn đã yêu cầu quá nhiều lần".
23. [ ] Mobile 390×844: card không tràn, method cards xếp dọc, nút bấm được, trang scroll bình thường.
24. [ ] Bật "Giảm chuyển động" (reduced motion): không animation radio card.
25. [ ] Link chuyển cổng: Customer → `/he-thong/quen-mat-khau`; Internal → `/quenmatkhau`; không có link chết (không có nút Fanpage/Zalo giả).
26. [ ] Kiểm tra log server: KHÔNG chứa OTP raw, mật khẩu, token; chỉ có event PASSWORD_RESET_* với accountId/portal.

## Bổ sung — Bước Email → OTP (spinner + kiểm tra thật)

27. [ ] Email rỗng / sai định dạng → lỗi dưới input, KHÔNG bật spinner, focus lại input.
28. [ ] Email không có trong hệ thống → ở lại trang Email, lỗi "Không thể gửi mã đến email này...", KHÔNG chuyển OTP, KHÔNG gửi mail.
29. [ ] Email thuộc role Internal nhập tại cổng Customer → như mục 28 (không lộ role).
30. [ ] Tài khoản bị khóa (isLocked) → như mục 28.
31. [ ] SMTP lỗi (tắt mạng/đổi pass app) → ở lại trang Email, "Hiện chưa thể gửi mã xác thực. Vui lòng thử lại sau.", spinner reset.
32. [ ] Click "Tiếp tục" 1 lần → spinner nhỏ hiện chính giữa nút, nút giữ nguyên kích thước, disabled.
33. [ ] Double-click / Enter lặp → chỉ 1 request (kiểm tra Network tab).
34. [ ] Nhấn Enter trong ô email → spinner bật giống click.
35. [ ] Thành công → redirect GET /nhapma (refresh không re-POST), màn OTP tối giản hiển thị email đã che.
36. [ ] Truy cập trực tiếp /nhapma khi không có challenge → redirect về trang chủ.
37. [ ] Browser Back về trang Email (bfcache) → nút trở lại bình thường, không kẹt spinner.
38. [ ] OTP nhập thiếu 6 số → lỗi client "Vui lòng nhập đủ 6 chữ số", không submit.
39. [ ] Paste 6 số vào ô OTP → nhận đúng, chỉ giữ chữ số.
40. [ ] "XÁC NHẬN" có spinner trong nút; OTP sai → spinner reset, focus ô mã.
41. [ ] Countdown "Gửi lại mã sau 00:59" đếm về 0 rồi hiện link "Gửi lại mã"; resend lỗi SMTP không vô hiệu mã cũ.
42. [ ] "Đổi email" → quay lại trang Email, challenge cũ bị hủy (OTP cũ không dùng được).

## Truy cập nhanh
- http://localhost:8080/quenmatkhau
- http://localhost:8080/he-thong/quen-mat-khau
