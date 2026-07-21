-- =====================================================================
-- rollback_customer_profile.sql
-- Hoàn tác migration_customer_profile.sql: xóa constraint rồi cột đã
-- thêm vào Accounts.
--
-- PHẦN 1 chỉ SELECT/PRINT (luôn an toàn). PHẦN 2 mới thực sự DROP và
-- CHỈ chạy khi người vận hành chủ động bật cờ @ConfirmRollback = 1.
--
-- CẢNH BÁO: PHẦN 2 xóa vĩnh viễn dữ liệu hồ sơ mở rộng đã nhập
-- (CoverImageUrl, ChieuCaoCm, CanNangKg, GhiChuDacBiet, ViTriYeuThich,
-- MonTheThaoYeuThichID, TrinhDoChoi, MucTieuChoi, TanSuatChoi). Không có
-- soft-delete cho việc này.
-- =====================================================================

USE QuanLiSport;
GO

SET XACT_ABORT ON;
GO

PRINT N'--- PHẦN 1: Dữ liệu hiện có trước khi rollback ---';
SELECT
    COUNT(CASE WHEN CoverImageUrl IS NOT NULL THEN 1 END) AS CoCoverPhoto,
    COUNT(CASE WHEN ChieuCaoCm IS NOT NULL THEN 1 END) AS CoChieuCao,
    COUNT(CASE WHEN CanNangKg IS NOT NULL THEN 1 END) AS CoCanNang
FROM dbo.Accounts;
GO

DECLARE @ConfirmRollback BIT = 0; -- Đổi thành 1 để thực sự rollback.

IF @ConfirmRollback = 1
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Accounts_MonTheThaoYeuThich')
            ALTER TABLE dbo.Accounts DROP CONSTRAINT FK_Accounts_MonTheThaoYeuThich;

        IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_ChieuCaoCm')
            ALTER TABLE dbo.Accounts DROP CONSTRAINT CK_Accounts_ChieuCaoCm;
        IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_CanNangKg')
            ALTER TABLE dbo.Accounts DROP CONSTRAINT CK_Accounts_CanNangKg;
        IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_TrinhDoChoi')
            ALTER TABLE dbo.Accounts DROP CONSTRAINT CK_Accounts_TrinhDoChoi;
        IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_TanSuatChoi')
            ALTER TABLE dbo.Accounts DROP CONSTRAINT CK_Accounts_TanSuatChoi;

        IF COL_LENGTH('dbo.Accounts', 'CoverImageUrl') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN CoverImageUrl;
        IF COL_LENGTH('dbo.Accounts', 'ChieuCaoCm') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN ChieuCaoCm;
        IF COL_LENGTH('dbo.Accounts', 'CanNangKg') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN CanNangKg;
        IF COL_LENGTH('dbo.Accounts', 'GhiChuDacBiet') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN GhiChuDacBiet;
        IF COL_LENGTH('dbo.Accounts', 'ViTriYeuThich') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN ViTriYeuThich;
        IF COL_LENGTH('dbo.Accounts', 'MonTheThaoYeuThichID') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN MonTheThaoYeuThichID;
        IF COL_LENGTH('dbo.Accounts', 'TrinhDoChoi') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN TrinhDoChoi;
        IF COL_LENGTH('dbo.Accounts', 'MucTieuChoi') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN MucTieuChoi;
        IF COL_LENGTH('dbo.Accounts', 'TanSuatChoi') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN TanSuatChoi;

        COMMIT TRANSACTION;
        PRINT N'=== rollback_customer_profile.sql: DONE ===';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END
ELSE
    PRINT N'PHẦN 2 bị bỏ qua — đặt @ConfirmRollback = 1 để thực sự rollback.';
GO
