-- Migration: Thêm cột HinhAnh (ảnh đại diện, tùy chọn) vào SanPham_DichVu.
-- Cho phép Manager gán ảnh sản phẩm/dịch vụ, tránh Customer nhìn thấy ảnh giả hoặc
-- ảnh mẫu dùng chung cho mọi sản phẩm ở khu vực Cửa hàng (bottom sheet Customer).
-- Chạy một lần trên DB thực. An toàn khi chạy lại (kiểm tra IF NOT EXISTS).

USE QuanLiSport;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'SanPham_DichVu') AND name = N'HinhAnh'
)
BEGIN
    ALTER TABLE SanPham_DichVu
    ADD HinhAnh NVARCHAR(500) NULL;
    PRINT N'Đã thêm cột HinhAnh vào SanPham_DichVu.';
END
ELSE
    PRINT N'Cột HinhAnh đã tồn tại, bỏ qua.';
GO

-- Rollback: ALTER TABLE SanPham_DichVu DROP COLUMN HinhAnh;
