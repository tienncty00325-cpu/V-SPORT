# Luồng hủy sân + Điểm uy tín khách hàng

## 1. Luồng hủy sân (khách tự thao tác)

`customer/LichSuDatSan.jsp` → `POST /customer/huy-dat-san` (`DatSanServlet.handleHuyDatSan`)
→ `BookingCancellationService.cancelByCustomer(...)`:

1. Load booking, kiểm tra `AccountID` khớp (chống IDOR).
2. Chặn hủy đơn "Đã xác nhận" đã thanh toán PayOS (giữ nguyên rule cũ — chưa có refund tự động).
3. Chỉ cho hủy từ trạng thái: `Chờ xác nhận`, `Đã xác nhận`, `Chờ thanh toán` (còn hạn giữ chỗ).
4. `CancelDecision.decide(now, bookingStart, LATE_CANCEL_HOURS=6)` → `EARLY_CANCEL` hoặc `LATE_CANCEL`
   (đúng bằng 6 tiếng tính là `LATE_CANCEL`).
5. `LichDatSanDAO.cancelByCustomer(...)` — một UPDATE atomic với `WHERE TrangThai IN (...)` làm cổng
   idempotent: 0 dòng nghĩa là đã hủy/đổi trạng thái từ trước (double-click, network retry, hai tab).
6. Nếu `LATE_CANCEL`: `CustomerReputationService.applyDelta(...)` trừ `LATE_CANCEL_PENALTY` (-10) điểm,
   tăng `Accounts.LateCancelCount`, ghi 1 dòng `CustomerReputationHistory`. Chạy trong CÙNG transaction
   với bước 5 — nếu bước 5 rollback, điểm không bị trừ.
7. Ghi `AuditLog` (`ACTION_CANCEL`).
8. Trả thông báo cho khách:
   - Sớm: "Đã hủy đơn đặt sân #X thành công."
   - Sát giờ: "Bạn đã hủy sát giờ. Hệ thống đã ghi nhận và điểm uy tín của bạn bị trừ 10 điểm."

## 2. Luồng No Show (Staff/Manager)

`staff/CheckIn.jsp` → `POST /staff/checkin?action=cancelNoShow` (`CheckInServlet`)
→ `CheckInDAO.huyLichKhachBung(datSanId, staffAccountId, coSoId, ipAddress)`:

1. Khóa dòng booking + join `San` để xác minh đúng `CoSoID` của staff/manager (403 nếu không khớp).
2. `NoShowEligibility.check(...)` — chỉ cho phép khi: trạng thái `Đã xác nhận`, đúng ngày hôm nay, đã
   qua `NO_SHOW_GRACE_MINUTES` (15 phút) sau giờ bắt đầu.
3. UPDATE atomic `SET TrangThai=N'Không đến', NoShowAt=GETDATE() WHERE ... AND TrangThai=N'Đã xác nhận'`
   — cùng cơ chế idempotent-qua-rowcount như trên.
4. Trừ `NO_SHOW_PENALTY` (-20) điểm, tăng `Accounts.NoShowCount`, ghi `CustomerReputationHistory`.
5. Hóa đơn: nếu MAIN invoice thực sự chưa thu tiền → tự hủy. Nếu đã thanh toán/cọc → KHÔNG tự hủy,
   chỉ đặt `LichDatSan.RequiresRefundReview = 1` + ghi chú hóa đơn cần xử lý hoàn tiền/giữ cọc thủ công.
6. Ghi `AuditLog` (`ACTION_NO_SHOW`).

## 3. Cách tính điểm uy tín

Mỗi tài khoản khách có `Accounts.DiemUyTin` (mặc định 100 — cột này đã tồn tại từ trước, KHÔNG tạo cột
điểm thứ hai). Quy tắc (`Constants.java`):

| Sự kiện | Delta | Bộ đếm tăng |
|---|---|---|
| Hủy sớm (còn > 6 tiếng) | 0 | — |
| Hủy sát giờ (còn ≤ 6 tiếng) | -10 | `LateCancelCount` |
| No Show | -20 | `NoShowCount` |
| Hoàn thành booking | +2 (tối đa 100) | `CompletedBookingCount` |

Điểm luôn được kẹp trong `[MIN_REPUTATION_SCORE=0, MAX_REPUTATION_SCORE=100]`
(`CustomerReputationService.clamp`).

Nhãn hiển thị (`ReputationLabel.of`):
- ≥ 80: "Uy tín tốt"
- 50–79: "Cần theo dõi"
- < 50: "Rủi ro cao" (Manager thấy cảnh báo "Khách hàng này có lịch sử bùng kèo" khi duyệt)

`CustomerReputationHistory` là sổ cái đầy đủ (mọi thay đổi điểm, kèm before/after/reason/actor/ip) —
đây là nguồn giải thích "vì sao điểm bị trừ", tách biệt khỏi bảng `AuditLog` chung (AuditLog ghi lại
*hành động nghiệp vụ* — hủy/no-show — còn CustomerReputationHistory ghi lại *hệ quả điểm số* của hành
động đó; không trùng lặp, hai bảng phục vụ hai câu hỏi khác nhau).

## 4. Idempotency

Mọi thao tác đổi trạng thái là MỘT UPDATE atomic với `WHERE <trạng thái nguồn>`. Phần trừ/cộng điểm chỉ
chạy nếu UPDATE đó ảnh hưởng đúng 1 dòng, trong cùng transaction. Double-click, network retry, hai tab
cùng thao tác một booking → request "thua" thấy 0 dòng ảnh hưởng → không trừ điểm lần hai, trả về thông
báo "đã được hủy/đánh dấu từ trước".

## 5. Nền dữ liệu cho ghép kèo / tìm đối thủ gấp (tương lai)

Chưa code chức năng ghép kèo trong đợt này. Dữ liệu đã sẵn sàng để dùng sau:

- `Accounts.DiemUyTin` — lọc người chơi uy tín khi ghép kèo (vd chỉ ghép với điểm ≥ 50).
- `Accounts.LateCancelCount` / `Accounts.NoShowCount` — cảnh báo người hay bùng kèo trước khi ghép.
- `CustomerReputationHistory` — giải thích chi tiết lịch sử từng lần bị trừ điểm khi hiển thị hồ sơ
  người chơi trong tính năng ghép kèo.
