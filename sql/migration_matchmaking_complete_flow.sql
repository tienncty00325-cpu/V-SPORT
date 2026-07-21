-- =====================================================================
-- Migration idempotent: Ghép kèo (Matchmaking) — bổ sung cột metadata tùy chọn
-- và unique index chống double-join. Chạy an toàn nhiều lần.
--
-- SCOPE:
--   Phiên bản UI/Backend hiện tại (2026-07-18) đã hoạt động đầy đủ với
--   schema hiện có của GhepKeo và ChiTietGhepKeo — metadata phụ (số người
--   cần tìm, hình thức duyệt) được encode trong cột MoTa dưới dạng JSON
--   prefix [VS_META]{...}[/VS_META]. Migration này CHỈ cần chạy nếu bạn
--   muốn:
--     (a) Có cột thực để query/thống kê nhanh hơn (thay vì parse chuỗi).
--     (b) Chống double-join ở tầng DB (bổ sung unique index có filter).
--
-- KHÔNG chạy tự động — chỉ chạy khi bạn muốn tối ưu.
-- Đọc kỹ trước khi apply lên production; luôn backup DB trước.
-- =====================================================================

USE QuanLiSport;
GO

-- 1. (Tùy chọn) Cột SoNguoiCanTim: số người CHỦ KÈO cần tìm thêm (không tính chủ).
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.GhepKeo') AND name = N'SoNguoiCanTim'
)
BEGIN
    ALTER TABLE dbo.GhepKeo ADD SoNguoiCanTim INT NULL;
    PRINT N'ADDED GhepKeo.SoNguoiCanTim';
END
ELSE
    PRINT N'SKIP GhepKeo.SoNguoiCanTim (đã tồn tại)';
GO

-- 2. (Tùy chọn) Cột HinhThucDuyet: 'auto' | 'manual'.
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.GhepKeo') AND name = N'HinhThucDuyet'
)
BEGIN
    ALTER TABLE dbo.GhepKeo ADD HinhThucDuyet NVARCHAR(20) NULL;
    PRINT N'ADDED GhepKeo.HinhThucDuyet';
END
ELSE
    PRINT N'SKIP GhepKeo.HinhThucDuyet (đã tồn tại)';
GO

-- 3. (Tùy chọn) Cột CreatedAt để sort theo thời gian tạo.
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.GhepKeo') AND name = N'CreatedAt'
)
BEGIN
    ALTER TABLE dbo.GhepKeo ADD CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME();
    PRINT N'ADDED GhepKeo.CreatedAt (default SYSDATETIME)';
END
ELSE
    PRINT N'SKIP GhepKeo.CreatedAt (đã tồn tại)';
GO

-- 4. Unique index chống double-join ở tầng DB — cùng (KeoID, AccountIDNguoiThamGia)
--    chỉ có tối đa 1 bản ghi Trạng thái đang hoạt động (Chờ duyệt / Đã tham gia).
--    "Đã từ chối" / "Đã rời" bị filter ra để tài khoản có thể xin lại sau khi bị
--    từ chối/rời tự nguyện — chống spam ở tầng application logic nếu cần.
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_ChiTietGhepKeo_Active_Keo_Account'
)
BEGIN
    CREATE UNIQUE INDEX UX_ChiTietGhepKeo_Active_Keo_Account
        ON dbo.ChiTietGhepKeo(KeoID, AccountIDNguoiThamGia)
        WHERE TrangThaiThamGia IN (N'Chờ duyệt', N'Đã tham gia');
    PRINT N'CREATED UX_ChiTietGhepKeo_Active_Keo_Account';
END
ELSE
    PRINT N'SKIP UX_ChiTietGhepKeo_Active_Keo_Account (đã tồn tại)';
GO

-- 5. Index hỗ trợ query listOpenMatches (WHERE TrangThai + JOIN LichDatSan).
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_GhepKeo_TrangThai_DatSan'
)
BEGIN
    CREATE INDEX IX_GhepKeo_TrangThai_DatSan
        ON dbo.GhepKeo(TrangThai, DatSanID);
    PRINT N'CREATED IX_GhepKeo_TrangThai_DatSan';
END
ELSE
    PRINT N'SKIP IX_GhepKeo_TrangThai_DatSan (đã tồn tại)';
GO

PRINT N'=== migration_matchmaking_complete_flow.sql: DONE ===';
