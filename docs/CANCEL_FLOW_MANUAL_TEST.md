# Checklist kiểm thử thủ công — Luồng hủy sân + Điểm uy tín

Chạy dự án bằng `.\start_server.bat` (Windows), đăng nhập bằng tài khoản tương ứng từng vai trò.
Mỗi test case ghi: Role / URL / Dữ liệu chuẩn bị / Các bước / Kết quả mong đợi / SQL kiểm tra / PASS-FAIL.

## 1. Customer hủy sớm
- Role: Khách hàng
- URL: `/customer/dat-san` (mở tab Lịch sử)
- Chuẩn bị: 1 booking trạng thái "Chờ xác nhận" hoặc "Đã xác nhận", giờ chơi còn > 6 tiếng nữa.
- Bước: Bấm "Hủy" → modal hiện không có cảnh báo sát giờ → nhập lý do (tùy chọn) → "Xác nhận hủy".
- Kỳ vọng: Booking chuyển "Đã hủy". Thông báo "Đã hủy đơn đặt sân #X thành công." Điểm uy tín KHÔNG đổi.
- SQL kiểm tra: `SELECT TrangThai, CancelType, CancelledAt FROM LichDatSan WHERE DatSanID = X;`
  `SELECT DiemUyTin, LateCancelCount FROM Accounts WHERE AccountID = Y;` (không đổi so với trước)
- PASS/FAIL: ____

## 2. Customer hủy sát giờ (Late Cancel)
- Role: Khách hàng
- Chuẩn bị: booking còn ≤ 6 tiếng nữa tới giờ chơi, trạng thái "Chờ xác nhận"/"Đã xác nhận".
- Bước: Bấm "Hủy" → modal PHẢI hiện cảnh báo "Bạn vẫn có thể hủy, nhưng đây là hủy sát giờ..." → xác nhận.
- Kỳ vọng: Booking → "Đã hủy", CancelType = LATE_CANCEL. Thông báo nêu rõ đã trừ 10 điểm.
- SQL: `SELECT TrangThai, CancelType FROM LichDatSan WHERE DatSanID = X;`
  `SELECT DiemUyTin, LateCancelCount FROM Accounts WHERE AccountID = Y;` (điểm giảm 10, count +1)
  `SELECT TOP 1 * FROM CustomerReputationHistory WHERE AccountID = Y ORDER BY CreatedAt DESC;`
- PASS/FAIL: ____

## 3. Customer hủy booking đã thanh toán (PayOS)
- Role: Khách hàng
- Chuẩn bị: booking "Đã xác nhận" đã được PayOS webhook xác nhận thanh toán.
- Bước: Bấm "Hủy" → xác nhận.
- Kỳ vọng: Bị chặn với thông báo "Đơn này đã thanh toán PayOS. Vui lòng liên hệ sân...". Booking KHÔNG đổi trạng thái.
- PASS/FAIL: ____

## 4. Customer hủy booking của người khác (IDOR)
- Role: Khách hàng A
- Chuẩn bị: DatSanID thuộc về khách hàng B.
- Bước: Gọi trực tiếp `POST /customer/huy-dat-san` với `id` của booking B (vd qua devtools/curl khi đã đăng nhập A).
- Kỳ vọng: "Bạn không có quyền hủy đơn này." Booking B không đổi.
- PASS/FAIL: ____

## 5. Staff đánh dấu No Show hợp lệ
- Role: Staff (Lễ tân/Bảo vệ)
- URL: `/staff/checkin`
- Chuẩn bị: booking "Đã xác nhận" hôm nay, đã qua giờ bắt đầu + 15 phút, thuộc đúng CoSoID của staff.
- Bước: Bấm nút hủy (icon) trên card booking → modal xác nhận No Show hiện ra, có cảnh báo ảnh hưởng điểm uy tín → "Xác nhận Không đến".
- Kỳ vọng: Booking → "Không đến", NoShowAt được ghi. Điểm uy tín trừ 20, NoShowCount +1.
- SQL: `SELECT TrangThai, NoShowAt FROM LichDatSan WHERE DatSanID = X;`
  `SELECT DiemUyTin, NoShowCount FROM Accounts WHERE AccountID = Y;`
- PASS/FAIL: ____

## 6. Staff cơ sở khác đánh dấu No Show
- Role: Staff cơ sở B
- Chuẩn bị: booking thuộc cơ sở A.
- Bước: Gọi `POST /staff/checkin?action=cancelNoShow&datSanId=X` với booking X thuộc cơ sở A.
- Kỳ vọng: 403 / lỗi "Đơn đặt sân không thuộc cơ sở của bạn." Booking không đổi.
- PASS/FAIL: ____

## 7. Double-click hủy (Customer)
- Role: Khách hàng
- Bước: Mở 2 tab cùng booking, bấm "Xác nhận hủy" gần như đồng thời ở cả 2 tab (hoặc double-click nhanh nút submit).
- Kỳ vọng: Chỉ 1 request thành công. Request thứ hai nhận "Booking đã được hủy trước đó hoặc không còn ở trạng thái có thể hủy." Điểm uy tín CHỈ trừ một lần (nếu là late cancel).
- SQL: `SELECT COUNT(*) FROM CustomerReputationHistory WHERE DatSanID = X;` → phải = 1 (không phải 2).
- PASS/FAIL: ____

## 8. Double-click No Show (Staff)
- Role: Staff
- Bước: Bấm "Xác nhận Không đến" 2 lần liên tiếp thật nhanh (hoặc 2 tab).
- Kỳ vọng: Request thứ hai thất bại với thông báo trạng thái đã thay đổi. Điểm uy tín CHỈ trừ 20 một lần.
- SQL: `SELECT COUNT(*) FROM CustomerReputationHistory WHERE DatSanID = X AND ActionType = 'NO_SHOW';` → = 1.
- PASS/FAIL: ____

## 9. Manager xem điểm uy tín khi duyệt
- Role: Manager
- URL: `/manager/dat-san`
- Chuẩn bị: một khách có DiemUyTin=90 (Uy tín tốt), một khách có 65 (Cần theo dõi), một khách có 40 (Rủi ro cao).
- Bước: Mở trang danh sách đặt sân.
- Kỳ vọng: Mỗi dòng hiện đúng nhãn theo điểm; dòng khách điểm 40 hiện thêm dòng cảnh báo "Khách hàng này có lịch sử bùng kèo...". Manager vẫn bấm Duyệt được bình thường.
- PASS/FAIL: ____

## 10. Booking sau khi hủy không còn chặn khung giờ
- Role: Khách hàng
- Bước: Hủy 1 booking ở một khung giờ/sân cụ thể → thử đặt lại đúng khung giờ/sân đó.
- Kỳ vọng: Đặt lại thành công, không báo trùng lịch (đã hủy nên `TrangThai <> N'Đã hủy'` filter loại nó ra khỏi check trùng — logic có sẵn, không đổi trong đợt này).
- PASS/FAIL: ____

## 11. Booking No Show không cho check-in nữa
- Role: Staff
- Bước: Sau khi đánh dấu No Show ở test 5, thử check-in lại chính booking đó.
- Kỳ vọng: Không check-in được (không còn ở trạng thái "Đã xác nhận" để `NoShowEligibility`/check-in chấp nhận).
- PASS/FAIL: ____

## 12. Audit log ghi nhận thao tác
- Role: Admin/Manager (bất kỳ ai xem được audit log)
- Bước: Sau test 1, 2, 5 — tra bảng AuditLog.
- SQL: `SELECT TOP 10 Action, EntityType, EntityId, Details, CreatedAt FROM AuditLog WHERE EntityType = 'LichDatSan' ORDER BY CreatedAt DESC;`
- Kỳ vọng: Có dòng `CANCEL` cho test 1 và 2, dòng `NO_SHOW` cho test 5, với `Details` mô tả đúng loại hủy.
- PASS/FAIL: ____
