-- Migration: Thêm bảng CoSoCapability (Phần E/F/G - đăng ký & phê duyệt loại hình
-- kinh doanh của cơ sở: bán sản phẩm, cho thuê dụng cụ, đồ ăn/nước uống, huấn luyện
-- viên, lớp học...). Mỗi capability có vòng đời trạng thái riêng, tách biệt với
-- CoSo.TrangThai (trạng thái duyệt cơ sở tổng thể).
-- Chạy một lần trên DB thực. Script có kiểm tra IF NOT EXISTS nên an toàn khi chạy lại.
-- Áp dụng cho: V-SPORT QuanLiSport_V4 trở lên. Không xóa dữ liệu hiện có.

USE QuanLiSport;
GO

IF OBJECT_ID('dbo.CoSoCapability', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.CoSoCapability (
        CapabilityID    INT IDENTITY(1,1) PRIMARY KEY,
        CoSoID          INT NOT NULL,
        -- SAN (cho thuê sân - mặc định), SAN_PHAM, THUE_DUNG_CU, DO_AN_NUOC_UONG,
        -- HUAN_LUYEN_VIEN, LOP_HOC, KHAC.
        CapabilityType  NVARCHAR(50)  NOT NULL,
        -- PENDING, APPROVED, REJECTED, SUSPENDED, DISABLED
        TrangThai       NVARCHAR(20)  NOT NULL CONSTRAINT DF_CoSoCapability_TrangThai DEFAULT N'PENDING',
        RequestedAt     DATETIME2     NOT NULL CONSTRAINT DF_CoSoCapability_RequestedAt DEFAULT SYSUTCDATETIME(),
        ApprovedBy      INT NULL,
        ApprovedAt      DATETIME2 NULL,
        RejectReason    NVARCHAR(500) NULL,
        Note            NVARCHAR(500) NULL,
        UpdatedAt       DATETIME2     NOT NULL CONSTRAINT DF_CoSoCapability_UpdatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_CoSoCapability_CoSo FOREIGN KEY (CoSoID) REFERENCES dbo.CoSo(CoSoID),
        CONSTRAINT FK_CoSoCapability_ApprovedBy FOREIGN KEY (ApprovedBy) REFERENCES dbo.Accounts(AccountID),
        -- Một cơ sở chỉ có duy nhất 1 bản ghi cho mỗi loại capability (lịch sử duyệt
        -- được lưu qua AuditLog, không qua nhiều dòng trùng CapabilityType).
        CONSTRAINT UQ_CoSoCapability_CoSo_Type UNIQUE (CoSoID, CapabilityType)
    );

    CREATE INDEX IX_CoSoCapability_CoSoID ON dbo.CoSoCapability (CoSoID);
    CREATE INDEX IX_CoSoCapability_TrangThai ON dbo.CoSoCapability (TrangThai);

    PRINT N'Đã tạo bảng CoSoCapability.';
END
ELSE
    PRINT N'Bảng CoSoCapability đã tồn tại, bỏ qua.';
GO

-- ─────────────────────────────────────────────────────────────────────────
-- Grandfathering: hệ thống capability này ra đời SAU KhoDichVuManagerServlet /
-- SanPham_DichVu (module bán sản phẩm/dịch vụ đã chạy thật từ trước). Nếu không
-- backfill, mọi cơ sở đang hoạt động sẽ mất quyền truy cập module đó ngay khi
-- Phase 3 gắn cổng kiểm tra capability - một hồi quy nghiêm trọng, không phải
-- dữ liệu mẫu. Chỉ áp dụng cho CoSo đang "Đang hoạt động" và chưa xóa mềm.
-- An toàn khi chạy lại: dùng WHERE NOT EXISTS, không tạo trùng dòng.
-- ─────────────────────────────────────────────────────────────────────────

-- SAN (cho thuê sân) = chức năng nền tảng, mọi cơ sở đang hoạt động coi như đã duyệt.
INSERT INTO dbo.CoSoCapability (CoSoID, CapabilityType, TrangThai, RequestedAt, ApprovedAt, Note)
SELECT c.CoSoID, N'SAN', N'APPROVED', SYSUTCDATETIME(), SYSUTCDATETIME(),
       N'Tự động duyệt khi migrate - cơ sở đã hoạt động trước khi có hệ thống capability.'
FROM dbo.CoSo c
WHERE c.TrangThai = N'Đang hoạt động'
  AND (c.isDeleted = 0 OR c.isDeleted IS NULL)
  AND NOT EXISTS (
      SELECT 1 FROM dbo.CoSoCapability cc WHERE cc.CoSoID = c.CoSoID AND cc.CapabilityType = N'SAN'
  );
PRINT N'Đã grandfather capability SAN cho các cơ sở đang hoạt động.';
GO

-- SAN_PHAM (bán sản phẩm thể thao) = grandfather cho mọi cơ sở đang hoạt động, vì
-- module KhoDichVu/SanPham_DichVu vốn đã dùng được không cần duyệt trước đây.
-- (SHOP_MODULE_CAPABILITIES ở Java dùng OR giữa SAN_PHAM/THUE_DUNG_CU/DO_AN_NUOC_UONG,
-- nên chỉ cần duyệt sẵn 1 loại là đủ để không ai bị mất quyền đang có.)
INSERT INTO dbo.CoSoCapability (CoSoID, CapabilityType, TrangThai, RequestedAt, ApprovedAt, Note)
SELECT c.CoSoID, N'SAN_PHAM', N'APPROVED', SYSUTCDATETIME(), SYSUTCDATETIME(),
       N'Tự động duyệt khi migrate - cơ sở đã dùng module Kho dịch vụ trước khi có hệ thống capability.'
FROM dbo.CoSo c
WHERE c.TrangThai = N'Đang hoạt động'
  AND (c.isDeleted = 0 OR c.isDeleted IS NULL)
  AND NOT EXISTS (
      SELECT 1 FROM dbo.CoSoCapability cc WHERE cc.CoSoID = c.CoSoID AND cc.CapabilityType = N'SAN_PHAM'
  );
PRINT N'Đã grandfather capability SAN_PHAM cho các cơ sở đang hoạt động.';
GO

-- Rollback (thủ công, chỉ chạy nếu cần gỡ migration này và chưa có dữ liệu quan trọng):
--   DROP TABLE dbo.CoSoCapability;
