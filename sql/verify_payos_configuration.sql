-- =====================================================================
-- verify_payos_configuration.sql
-- Chẩn đoán cấu hình PayOS theo từng cơ sở (CoSo) và tình trạng payment.
-- CHỈ ĐỌC (SELECT/PRINT) — không UPDATE/DELETE/INSERT bất kỳ dòng nào.
-- Không bao giờ SELECT nguyên văn PayOS_ClientID/PayOS_ApiKey/PayOS_ChecksumKey —
-- chỉ trả về trạng thái BIT (đã cấu hình / chưa cấu hình).
-- =====================================================================

USE QuanLiSport;
GO

PRINT N'--- 1. Xác nhận 3 cột PayOS thực tế trên bảng CoSo ---';
SELECT c.name AS ColumnName, t.name AS DataType, c.max_length AS MaxLength, c.is_nullable AS IsNullable
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID(N'dbo.CoSo')
  AND c.name IN (N'PayOS_ClientID', N'PayOS_ApiKey', N'PayOS_ChecksumKey')
ORDER BY c.column_id;
GO

PRINT N'--- 2. Danh sách cơ sở đang hoạt động (chưa xóa mềm) ---';
SELECT CoSoID, TenCoSo, IsDeleted
FROM dbo.CoSo
WHERE IsDeleted = 0 OR IsDeleted IS NULL
ORDER BY CoSoID;
GO

PRINT N'--- 3. Trạng thái cấu hình PayOS theo từng cơ sở (không lộ giá trị thật) ---';
-- Coi là "chỉ chứa khoảng trắng" là CHƯA cấu hình (khớp đúng PayOSCredentials.isXConfigured() ở tầng service).
SELECT
    CoSoID,
    TenCoSo,
    IsDeleted,
    CAST(CASE WHEN PayOS_ClientID IS NOT NULL AND LTRIM(RTRIM(PayOS_ClientID)) <> N'' THEN 1 ELSE 0 END AS BIT) AS ClientIdConfigured,
    CAST(CASE WHEN PayOS_ApiKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ApiKey)) <> N'' THEN 1 ELSE 0 END AS BIT) AS ApiKeyConfigured,
    CAST(CASE WHEN PayOS_ChecksumKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ChecksumKey)) <> N'' THEN 1 ELSE 0 END AS BIT) AS ChecksumKeyConfigured,
    CASE
        WHEN PayOS_ClientID IS NOT NULL AND LTRIM(RTRIM(PayOS_ClientID)) <> N''
         AND PayOS_ApiKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ApiKey)) <> N''
         AND PayOS_ChecksumKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ChecksumKey)) <> N''
            THEN N'CONFIGURED'
        WHEN (PayOS_ClientID IS NULL OR LTRIM(RTRIM(PayOS_ClientID)) = N'')
         AND (PayOS_ApiKey IS NULL OR LTRIM(RTRIM(PayOS_ApiKey)) = N'')
         AND (PayOS_ChecksumKey IS NULL OR LTRIM(RTRIM(PayOS_ChecksumKey)) = N'')
            THEN N'NOT_CONFIGURED'
        ELSE N'INCOMPLETE'
    END AS ConfigurationStatus
FROM dbo.CoSo
ORDER BY CoSoID;
GO

PRINT N'--- 4. Cơ sở còn hoạt động nhưng thiếu ÍT NHẤT một key (chặn tạo payment link) ---';
SELECT CoSoID, TenCoSo,
    CAST(CASE WHEN PayOS_ClientID IS NOT NULL AND LTRIM(RTRIM(PayOS_ClientID)) <> N'' THEN 1 ELSE 0 END AS BIT) AS ClientIdConfigured,
    CAST(CASE WHEN PayOS_ApiKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ApiKey)) <> N'' THEN 1 ELSE 0 END AS BIT) AS ApiKeyConfigured,
    CAST(CASE WHEN PayOS_ChecksumKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ChecksumKey)) <> N'' THEN 1 ELSE 0 END AS BIT) AS ChecksumKeyConfigured
FROM dbo.CoSo
WHERE (IsDeleted = 0 OR IsDeleted IS NULL)
  AND NOT (
        PayOS_ClientID IS NOT NULL AND LTRIM(RTRIM(PayOS_ClientID)) <> N''
    AND PayOS_ApiKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ApiKey)) <> N''
    AND PayOS_ChecksumKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ChecksumKey)) <> N''
  )
ORDER BY CoSoID;
GO

PRINT N'--- 5. Cơ sở có key CHỈ CHỨA khoảng trắng (khác NULL, dễ bị bỏ sót khi kiểm tra IS NULL) ---';
SELECT CoSoID, TenCoSo,
    CASE WHEN PayOS_ClientID IS NOT NULL AND LTRIM(RTRIM(PayOS_ClientID)) = N'' THEN 1 ELSE 0 END AS ClientIdWhitespaceOnly,
    CASE WHEN PayOS_ApiKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ApiKey)) = N'' THEN 1 ELSE 0 END AS ApiKeyWhitespaceOnly,
    CASE WHEN PayOS_ChecksumKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ChecksumKey)) = N'' THEN 1 ELSE 0 END AS ChecksumKeyWhitespaceOnly
FROM dbo.CoSo
WHERE (PayOS_ClientID IS NOT NULL AND LTRIM(RTRIM(PayOS_ClientID)) = N'')
   OR (PayOS_ApiKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ApiKey)) = N'')
   OR (PayOS_ChecksumKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ChecksumKey)) = N'');
GO

PRINT N'--- 6. Cơ sở có PayOS key nhưng ĐÃ bị xóa mềm (config mồ côi, không còn dùng được) ---';
SELECT CoSoID, TenCoSo, IsDeleted,
    CAST(CASE WHEN PayOS_ClientID IS NOT NULL AND LTRIM(RTRIM(PayOS_ClientID)) <> N'' THEN 1 ELSE 0 END AS BIT) AS ClientIdConfigured,
    CAST(CASE WHEN PayOS_ApiKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ApiKey)) <> N'' THEN 1 ELSE 0 END AS BIT) AS ApiKeyConfigured,
    CAST(CASE WHEN PayOS_ChecksumKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ChecksumKey)) <> N'' THEN 1 ELSE 0 END AS BIT) AS ChecksumKeyConfigured
FROM dbo.CoSo
WHERE IsDeleted = 1
  AND (
        (PayOS_ClientID IS NOT NULL AND LTRIM(RTRIM(PayOS_ClientID)) <> N'')
     OR (PayOS_ApiKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ApiKey)) <> N'')
     OR (PayOS_ChecksumKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ChecksumKey)) <> N'')
  );
GO

PRINT N'--- 7. Booking gần nhất của khách (luồng đặt sân trả trước — orderCode = DatSanID) ---';
SELECT TOP 20
    l.DatSanID AS OrderCode,
    l.AccountID, l.TrangThai, l.NgayDat, l.GioBatDau, l.GioKetThuc,
    l.TongTienDuKien, l.HoldExpiresAt, s.CoSoID, l.CreatedTime
FROM dbo.LichDatSan l
JOIN dbo.San s ON s.SanID = l.SanID
WHERE l.TrangThai IN (N'Chờ thanh toán', N'Đã xác nhận')
ORDER BY l.CreatedTime DESC;
GO

PRINT N'--- 8. Payment attempt gần nhất (luồng Staff checkout — bảng PayOSPaymentAttempt) ---';
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'PayOSPaymentAttempt')
BEGIN
    SELECT TOP 20 AttemptID, HoaDonID, DatSanID, CoSoID, OrderCode, Status, Amount, CreatedAt
    FROM dbo.PayOSPaymentAttempt
    ORDER BY AttemptID DESC;
END
ELSE
    PRINT N'SKIP: Bảng PayOSPaymentAttempt chưa tồn tại (chạy sql/migration_payos_payment_attempt.sql trước).';
GO

PRINT N'--- 9. Kiểm tra OrderCode trùng lặp trong PayOSPaymentAttempt (phải luôn 0 dòng nhờ unique index) ---';
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'PayOSPaymentAttempt')
BEGIN
    SELECT OrderCode, COUNT(*) AS DuplicateCount
    FROM dbo.PayOSPaymentAttempt
    GROUP BY OrderCode
    HAVING COUNT(*) > 1;
END
GO

PRINT N'--- 10. Booking "Chờ thanh toán" bất thường: đã hết hạn giữ chỗ nhưng vẫn chưa hủy/xác nhận ---';
SELECT l.DatSanID, l.AccountID, s.CoSoID, l.TrangThai, l.HoldExpiresAt, l.CreatedTime,
    DATEDIFF(MINUTE, l.HoldExpiresAt, GETDATE()) AS MinutesPastExpiry
FROM dbo.LichDatSan l
JOIN dbo.San s ON s.SanID = l.SanID
WHERE l.TrangThai = N'Chờ thanh toán'
  AND l.HoldExpiresAt IS NOT NULL
  AND l.HoldExpiresAt < GETDATE()
ORDER BY l.HoldExpiresAt ASC;
GO

PRINT N'--- 11. Tổng hợp cấu hình PayOS theo cơ sở (đếm nhanh) ---';
SELECT
    (SELECT COUNT(*) FROM dbo.CoSo WHERE IsDeleted = 0 OR IsDeleted IS NULL) AS TotalActiveFacilities,
    (SELECT COUNT(*) FROM dbo.CoSo WHERE (IsDeleted = 0 OR IsDeleted IS NULL)
        AND PayOS_ClientID IS NOT NULL AND LTRIM(RTRIM(PayOS_ClientID)) <> N''
        AND PayOS_ApiKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ApiKey)) <> N''
        AND PayOS_ChecksumKey IS NOT NULL AND LTRIM(RTRIM(PayOS_ChecksumKey)) <> N'') AS FullyConfiguredFacilities,
    (SELECT COUNT(*) FROM dbo.CoSo WHERE (IsDeleted = 0 OR IsDeleted IS NULL)
        AND (PayOS_ClientID IS NULL OR LTRIM(RTRIM(PayOS_ClientID)) = N'')
        AND (PayOS_ApiKey IS NULL OR LTRIM(RTRIM(PayOS_ApiKey)) = N'')
        AND (PayOS_ChecksumKey IS NULL OR LTRIM(RTRIM(PayOS_ChecksumKey)) = N'')) AS NotConfiguredFacilities;
GO

PRINT N'--- verify_payos_configuration.sql: DONE ---';
