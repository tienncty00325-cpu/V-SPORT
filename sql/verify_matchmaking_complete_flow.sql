-- =====================================================================
-- Verify script — kiểm tra schema Ghép kèo (matchmaking) sau khi chạy
-- migration_matchmaking_complete_flow.sql. Chỉ đọc, không thay đổi dữ liệu.
-- =====================================================================

USE QuanLiSport;
GO

PRINT N'--- 1. Kiểm tra bảng GhepKeo ---';
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'GhepKeo')
BEGIN
    PRINT N'FAIL: Bảng GhepKeo không tồn tại.';
    RETURN;
END

SELECT
    c.name AS ColumnName,
    t.name AS DataType,
    c.is_nullable AS IsNullable
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID(N'dbo.GhepKeo')
ORDER BY c.column_id;

PRINT N'';
PRINT N'--- 2. Kiểm tra bảng ChiTietGhepKeo ---';
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'ChiTietGhepKeo')
BEGIN
    PRINT N'FAIL: Bảng ChiTietGhepKeo không tồn tại.';
    RETURN;
END

SELECT
    c.name AS ColumnName,
    t.name AS DataType,
    c.is_nullable AS IsNullable
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID(N'dbo.ChiTietGhepKeo')
ORDER BY c.column_id;

PRINT N'';
PRINT N'--- 3. Kiểm tra unique index chống double-join ---';
SELECT name, is_unique, has_filter, filter_definition
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.ChiTietGhepKeo')
  AND name = N'UX_ChiTietGhepKeo_Active_Keo_Account';

PRINT N'';
PRINT N'--- 4. Đếm dữ liệu hiện có ---';
SELECT COUNT(*) AS TotalKeo, SUM(CASE WHEN TrangThai = N'Đang mở' THEN 1 ELSE 0 END) AS DangMo
FROM dbo.GhepKeo;
SELECT COUNT(*) AS TotalParticipant,
       SUM(CASE WHEN TrangThaiThamGia = N'Đã tham gia' THEN 1 ELSE 0 END) AS DaThamGia,
       SUM(CASE WHEN TrangThaiThamGia = N'Chờ duyệt' THEN 1 ELSE 0 END) AS ChoDuyet
FROM dbo.ChiTietGhepKeo;

PRINT N'--- verify_matchmaking_complete_flow.sql: DONE ---';
