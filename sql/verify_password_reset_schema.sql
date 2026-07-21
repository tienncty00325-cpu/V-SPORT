-- READ-ONLY: Kiểm tra hạ tầng phục vụ reset mật khẩu.
--
-- LƯU Ý KIẾN TRÚC HIỆN TẠI:
-- Luồng quên mật khẩu V-SPORT KHÔNG dùng bảng DB cho OTP challenge.
-- Challenge (hash OTP + expiry 10 phút + attempt limit 5 + resend cooldown 60s
-- + one-time-use) được giữ trong HTTP session qua lớp
-- org.example.service.reset.PasswordResetChallenge — nhất quán với kiến trúc
-- OTP-in-session sẵn có của luồng đăng ký. Vì vậy KHÔNG có bảng
-- PasswordResetChallenge để kiểm tra; script này xác nhận điều đó và kiểm tra
-- các cột Accounts mà luồng reset phụ thuộc.

-- 1) Xác nhận không có (hoặc có) bảng reset trong DB
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%Reset%' OR TABLE_NAME LIKE '%OTP%' OR TABLE_NAME LIKE '%Otp%';

-- 2) Cột Accounts mà luồng reset dùng (Email lookup + Password update)
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Accounts'
  AND COLUMN_NAME IN ('AccountID', 'Email', 'PhoneNumber', 'Password', 'RoleID', 'IsLocked', 'IsDeleted');

-- 3) Password phải là BCrypt hash (bắt đầu bằng $2a$/$2b$/$2y$) — liệt kê ngoại lệ
SELECT AccountID, Username, RoleID
FROM dbo.Accounts
WHERE Password IS NOT NULL
  AND Password NOT LIKE '$2a$%' AND Password NOT LIKE '$2b$%' AND Password NOT LIKE '$2y$%';

-- 4) Index hỗ trợ lookup Email/Phone
SELECT i.name AS IndexName, c.name AS ColumnName, i.is_unique
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('dbo.Accounts')
  AND c.name IN ('Email', 'PhoneNumber', 'Username');
