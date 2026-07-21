-- =====================================================================
-- verify_customer_profile.sql
-- Kiểm tra schema hồ sơ cá nhân mở rộng sau khi chạy
-- migration_customer_profile.sql. Chỉ đọc (SELECT/PRINT) — không thay
-- đổi dữ liệu.
-- =====================================================================

USE QuanLiSport;
GO

PRINT N'--- 1. Database hiện tại ---';
SELECT DB_NAME() AS CurrentDatabase;
GO

PRINT N'--- 2. Cột mới trên Accounts ---';
SELECT
    COL_LENGTH('dbo.Accounts', 'CoverImageUrl')        AS CoverImageUrl_ColLength,
    COL_LENGTH('dbo.Accounts', 'ChieuCaoCm')            AS ChieuCaoCm_ColLength,
    COL_LENGTH('dbo.Accounts', 'CanNangKg')             AS CanNangKg_ColLength,
    COL_LENGTH('dbo.Accounts', 'GhiChuDacBiet')         AS GhiChuDacBiet_ColLength,
    COL_LENGTH('dbo.Accounts', 'ViTriYeuThich')         AS ViTriYeuThich_ColLength,
    COL_LENGTH('dbo.Accounts', 'MonTheThaoYeuThichID')  AS MonTheThaoYeuThichID_ColLength,
    COL_LENGTH('dbo.Accounts', 'TrinhDoChoi')           AS TrinhDoChoi_ColLength,
    COL_LENGTH('dbo.Accounts', 'MucTieuChoi')           AS MucTieuChoi_ColLength,
    COL_LENGTH('dbo.Accounts', 'TanSuatChoi')           AS TanSuatChoi_ColLength;
GO

PRINT N'--- 3. Check constraints ---';
SELECT name FROM sys.check_constraints
WHERE name IN (N'CK_Accounts_ChieuCaoCm', N'CK_Accounts_CanNangKg', N'CK_Accounts_TrinhDoChoi', N'CK_Accounts_TanSuatChoi');
GO

PRINT N'--- 4. Foreign key MonTheThaoYeuThich ---';
SELECT name FROM sys.foreign_keys WHERE name = N'FK_Accounts_MonTheThaoYeuThich';
GO

PRINT N'--- 5. Số tài khoản đã điền hồ sơ mở rộng (kỳ vọng 0 ngay sau migration lần đầu) ---';
SELECT
    COUNT(CASE WHEN CoverImageUrl IS NOT NULL THEN 1 END) AS CoCoverPhoto,
    COUNT(CASE WHEN ChieuCaoCm IS NOT NULL THEN 1 END) AS CoChieuCao,
    COUNT(CASE WHEN CanNangKg IS NOT NULL THEN 1 END) AS CoCanNang,
    COUNT(CASE WHEN MonTheThaoYeuThichID IS NOT NULL THEN 1 END) AS CoMonYeuThich
FROM dbo.Accounts;
GO

PRINT N'--- verify_customer_profile.sql: DONE ---';
