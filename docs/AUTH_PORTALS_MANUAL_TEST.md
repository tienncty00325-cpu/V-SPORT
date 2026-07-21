# Manual Test — Hai cổng đăng nhập V-SPORT + Transition Screen

Routes:

- Customer Login: `GET/POST /dangnhap` (portal=customer)
- Internal Login: `GET/POST /he-thong/dang-nhap` (portal=internal)
- Cùng một `DangNhapServlet`, cùng pipeline BCrypt/session/role redirect.
- Policy: `AuthPortalPolicy` — customer portal chỉ role 3; internal portal chỉ role 1/2/4/5.
- Portal parameter chỉ chọn allowed-role policy + JSP; không bao giờ cấp role.

## Checklist

1. [ ] Mở `/dangnhap` — nền sóng xanh, tab Số điện thoại/Email, callout "Chuyển sang Cổng vận hành" dưới link Đăng ký.
2. [ ] Mở `/he-thong/dang-nhap` — nền ảnh thể thao + overlay emerald đậm, card lớn "Đăng nhập Cổng vận hành", callout "Quay về Cổng khách hàng".
3. [ ] Click "Chuyển sang Cổng vận hành" — overlay V-SPORT hiện ngay, subtitle "Đang chuyển đến Cổng vận hành", điều hướng sau ~180ms, trang đích splash ~550ms rồi fade.
4. [ ] Click "Quay về Cổng khách hàng" — tương tự, subtitle "Đang chuyển về Cổng khách hàng".
5. [ ] Bật `prefers-reduced-motion` (DevTools → Rendering) — orbit/glow/dots đứng yên, chỉ fade ngắn.
6. [ ] Customer hợp lệ đăng nhập tại `/dangnhap` (email hoặc phone) → về Customer Home.
7. [ ] Customer hợp lệ đăng nhập tại `/he-thong/dang-nhap` → KHÔNG tạo session, alert info "Tài khoản này thuộc Cổng khách hàng..." + CTA "Quay về Cổng khách hàng".
8. [ ] Staff hợp lệ tại Internal → `/staff/dashboard`.
9. [ ] Staff hợp lệ tại Customer Portal → bị chặn, alert "Tài khoản này thuộc Cổng vận hành..." + CTA "Đi đến Cổng vận hành".
10. [ ] Manager hợp lệ tại Internal → `/manager/dashboard`.
11. [ ] Admin hợp lệ tại Internal → `/admin/tong-quan`.
12. [ ] Sai mật khẩu ở cả hai cổng → thông báo generic "…không đúng.", không lộ role, overlay không kẹt (trang render lại).
13. [ ] Tài khoản bị khóa/inactive → không đăng nhập được (query lọc isLocked; cơ sở ngừng hoạt động → thông báo riêng).
14. [ ] Eye toggle hoạt động độc lập ở cả hai cổng; aria-label đổi Hiện/Ẩn mật khẩu.
15. [ ] "Quên mật khẩu" ở cả hai cổng → `/quenmatkhau`.
16. [ ] Double-submit: bấm ĐĂNG NHẬP nhiều lần nhanh — chỉ 1 request, nút disabled + "ĐANG XÁC THỰC...".
17. [ ] Mobile 390×844: card `calc(100% - 24px)`, không overflow ngang, orbit icon giảm còn 3, form scroll được.
18. [ ] Desktop 1366×768: hai trang căn giữa, card không bị cắt.
19. [ ] Overlay không bao giờ kẹt: submit lỗi validation client (không hiện overlay), server error (trang mới render), Back/Forward bfcache (pageshow → ẩn).
20. [ ] Back button ở topbar: quay lại trang trước cùng origin (không phải trang auth), fallback về Customer Home.

Ghi chú: không tạo tài khoản thật / không sửa dữ liệu trên DB dùng chung khi test.
Các case 6–11 cần tài khoản thật của từng role — dùng tài khoản dev sẵn có.
