# Hướng dẫn Chạy Migration Thêm Cột Uy Tín (Reputation Schema)

Tài liệu này hướng dẫn cách chạy migration để sửa lỗi schema mismatch (`Invalid column name 'CompletedBookingCount'`) giữa Java Entity (`TaiKhoan.java`) và bảng `dbo.Accounts` trong SQL Server.

## Các bước thực hiện

### Bước 1: Sao lưu database
Trước khi chạy bất kỳ script migration nào, vui lòng thực hiện sao lưu (backup) database `QuanLiSport` để đề phòng sự cố ngoài ý muốn.

### Bước 2: Chạy script kiểm tra hiện trạng (Verify Script)
Chạy script chẩn đoán read-only dưới đây để xem cột/bảng nào đang bị thiếu trong database của bạn:
- Đường dẫn file: [verify_accounts_reputation_schema.sql](../sql/verify_accounts_reputation_schema.sql)
- Câu lệnh kiểm tra:
  ```sql
  USE QuanLiSport;
  GO
  SELECT 
      COL_LENGTH('dbo.Accounts', 'DiemUyTin') AS DiemUyTinExists,
      COL_LENGTH('dbo.Accounts', 'LateCancelCount') AS LateCancelCountExists,
      COL_LENGTH('dbo.Accounts', 'NoShowCount') AS NoShowCountExists,
      COL_LENGTH('dbo.Accounts', 'CompletedBookingCount') AS CompletedBookingCountExists;
  GO
  SELECT OBJECT_ID('dbo.CustomerReputationHistory') AS CustomerReputationHistoryExists;
  GO
  ```
- *Lưu ý*: Nếu kết quả trả về của bất kỳ cột nào hoặc bảng `CustomerReputationHistory` là `NULL`, nghĩa là schema của bạn đang bị thiếu phần tương ứng.

### Bước 3: Chạy migration chính (Reputation & Cancel Flow)
Hãy chạy lần lượt các script sau trên SQL Server để cập nhật schema:

1. **Chạy file migration chính của luồng hủy/uy tín:**
   - Đường dẫn file: [migration_customer_reputation_cancel_flow.sql](../sql/migration_customer_reputation_cancel_flow.sql)
   - Tác dụng: Thêm các cột cho luồng hủy vào `LichDatSan` và tạo bảng lịch sử điểm uy tín `CustomerReputationHistory`.

2. **Chạy file sửa đổi cột Accounts (Fix Columns):**
   - Đường dẫn file: [migration_fix_accounts_reputation_columns.sql](../sql/migration_fix_accounts_reputation_columns.sql)
   - Tác dụng: Đảm bảo đầy đủ 4 cột uy tín (`DiemUyTin`, `LateCancelCount`, `NoShowCount`, `CompletedBookingCount`) tồn tại trong bảng `dbo.Accounts`, đồng thời thực hiện backfill giá trị mặc định cho các dòng dữ liệu cũ nếu cột bị `NULL`.

### Bước 4: Kiểm tra lại schema
Chạy lại script kiểm tra ở **Bước 2** để chắc chắn rằng các cột và bảng đã tồn tại đầy đủ (kết quả trả về khác `NULL`).

### Bước 5: Restart Tomcat
Restart application server (Tomcat 10.1) để Hibernate cập nhật lại metadata schema mới.

### Bước 6: Thử nghiệm đăng nhập các role
Hãy thử đăng nhập bằng trình duyệt với các tài khoản tương ứng với các role khác nhau:
- **Khách hàng** (Customer)
- **Nhân viên** (Staff)
- **Quản lý** (Manager)
- **Quản trị viên** (Admin)

Xác nhận không còn xuất hiện lỗi `Invalid column name 'CompletedBookingCount'` trong log server, và việc đăng nhập diễn ra thành công.
