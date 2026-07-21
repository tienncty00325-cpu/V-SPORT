-- =====================================================================
-- migration_customer_profile.sql
-- Bổ sung các cột hồ sơ cá nhân mở rộng cho Customer (trang /customer/ho-so):
-- cover photo, chiều cao/cân nặng, ghi chú đặc biệt, cá nhân hóa (vị trí
-- yêu thích, môn thể thao + trình độ, mục tiêu, tần suất chơi).
--
-- Idempotent: chạy lại nhiều lần không lỗi (COL_LENGTH/OBJECT_ID/
-- sys.foreign_keys guard trước khi ALTER, theo đúng phong cách các
-- migration hiện có trong repo, vd. migration_team_management.sql).
--
-- Không tự động thực thi — người vận hành phải tự chạy tay trên
-- SQL Server (database QuanLiSport).
-- =====================================================================

USE QuanLiSport;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH('dbo.Accounts', 'CoverImageUrl') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD CoverImageUrl NVARCHAR(500) NULL;
        PRINT N'ADDED Accounts.CoverImageUrl';
    END
    ELSE
        PRINT N'SKIP Accounts.CoverImageUrl (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'ChieuCaoCm') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD ChieuCaoCm INT NULL;
        PRINT N'ADDED Accounts.ChieuCaoCm';
    END
    ELSE
        PRINT N'SKIP Accounts.ChieuCaoCm (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'ChieuCaoCm') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_ChieuCaoCm')
    BEGIN
        ALTER TABLE dbo.Accounts ADD CONSTRAINT CK_Accounts_ChieuCaoCm
            CHECK (ChieuCaoCm IS NULL OR ChieuCaoCm BETWEEN 50 AND 260);
        PRINT N'ADDED CK_Accounts_ChieuCaoCm';
    END
    ELSE
        PRINT N'SKIP CK_Accounts_ChieuCaoCm (đã tồn tại hoặc điều kiện chưa đủ)';

    IF COL_LENGTH('dbo.Accounts', 'CanNangKg') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD CanNangKg INT NULL;
        PRINT N'ADDED Accounts.CanNangKg';
    END
    ELSE
        PRINT N'SKIP Accounts.CanNangKg (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'CanNangKg') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_CanNangKg')
    BEGIN
        ALTER TABLE dbo.Accounts ADD CONSTRAINT CK_Accounts_CanNangKg
            CHECK (CanNangKg IS NULL OR CanNangKg BETWEEN 20 AND 300);
        PRINT N'ADDED CK_Accounts_CanNangKg';
    END
    ELSE
        PRINT N'SKIP CK_Accounts_CanNangKg (đã tồn tại hoặc điều kiện chưa đủ)';

    IF COL_LENGTH('dbo.Accounts', 'GhiChuDacBiet') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD GhiChuDacBiet NVARCHAR(500) NULL;
        PRINT N'ADDED Accounts.GhiChuDacBiet';
    END
    ELSE
        PRINT N'SKIP Accounts.GhiChuDacBiet (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'ViTriYeuThich') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD ViTriYeuThich NVARCHAR(255) NULL;
        PRINT N'ADDED Accounts.ViTriYeuThich';
    END
    ELSE
        PRINT N'SKIP Accounts.ViTriYeuThich (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'MonTheThaoYeuThichID') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD MonTheThaoYeuThichID INT NULL;
        PRINT N'ADDED Accounts.MonTheThaoYeuThichID';
    END
    ELSE
        PRINT N'SKIP Accounts.MonTheThaoYeuThichID (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'MonTheThaoYeuThichID') IS NOT NULL
       AND OBJECT_ID(N'dbo.MonTheThao', N'U') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Accounts_MonTheThaoYeuThich')
    BEGIN
        ALTER TABLE dbo.Accounts ADD CONSTRAINT FK_Accounts_MonTheThaoYeuThich
            FOREIGN KEY (MonTheThaoYeuThichID) REFERENCES dbo.MonTheThao(MonTheThaoID);
        PRINT N'ADDED FK_Accounts_MonTheThaoYeuThich';
    END
    ELSE
        PRINT N'SKIP FK_Accounts_MonTheThaoYeuThich (đã tồn tại hoặc điều kiện chưa đủ)';

    IF COL_LENGTH('dbo.Accounts', 'TrinhDoChoi') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD TrinhDoChoi VARCHAR(30) NULL;
        PRINT N'ADDED Accounts.TrinhDoChoi';
    END
    ELSE
        PRINT N'SKIP Accounts.TrinhDoChoi (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'TrinhDoChoi') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_TrinhDoChoi')
    BEGIN
        ALTER TABLE dbo.Accounts ADD CONSTRAINT CK_Accounts_TrinhDoChoi
            CHECK (TrinhDoChoi IS NULL OR TrinhDoChoi IN (N'Mới chơi', N'Cơ bản', N'Trung bình', N'Khá', N'Nâng cao'));
        PRINT N'ADDED CK_Accounts_TrinhDoChoi';
    END
    ELSE
        PRINT N'SKIP CK_Accounts_TrinhDoChoi (đã tồn tại hoặc điều kiện chưa đủ)';

    IF COL_LENGTH('dbo.Accounts', 'MucTieuChoi') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD MucTieuChoi NVARCHAR(255) NULL;
        PRINT N'ADDED Accounts.MucTieuChoi';
    END
    ELSE
        PRINT N'SKIP Accounts.MucTieuChoi (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'TanSuatChoi') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD TanSuatChoi VARCHAR(30) NULL;
        PRINT N'ADDED Accounts.TanSuatChoi';
    END
    ELSE
        PRINT N'SKIP Accounts.TanSuatChoi (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'TanSuatChoi') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_TanSuatChoi')
    BEGIN
        ALTER TABLE dbo.Accounts ADD CONSTRAINT CK_Accounts_TanSuatChoi
            CHECK (TanSuatChoi IS NULL OR TanSuatChoi IN (N'1 lần/tuần', N'2-3 lần/tuần', N'4+ lần/tuần', N'Không cố định'));
        PRINT N'ADDED CK_Accounts_TanSuatChoi';
    END
    ELSE
        PRINT N'SKIP CK_Accounts_TanSuatChoi (đã tồn tại hoặc điều kiện chưa đủ)';

    COMMIT TRANSACTION;
    PRINT N'=== migration_customer_profile.sql: DONE ===';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
