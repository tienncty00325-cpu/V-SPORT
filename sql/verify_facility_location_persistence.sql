-- =====================================================================
-- Verify script — kiểm tra dữ liệu vị trí cơ sở (DiaChi/ViDo/KinhDo) trên
-- dbo.CoSo. CHỈ ĐỌC — không UPDATE/DELETE bất kỳ dòng nào.
-- Chạy thủ công để soát dữ liệu trước/sau khi triển khai fix luồng lưu
-- vị trí cơ sở (đăng ký đối tác + Admin Quản lý Chi nhánh).
-- =====================================================================

USE QuanLiSport;
GO

PRINT N'--- 1. Kiểm tra cột DiaChi/ViDo/KinhDo tồn tại và đúng kiểu dữ liệu ---';
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'CoSo')
BEGIN
    PRINT N'FAIL: Bảng CoSo không tồn tại.';
    RETURN;
END

SELECT
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length AS MaxLength,
    c.precision AS Precision_,
    c.scale AS Scale_,
    c.is_nullable AS IsNullable
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID(N'dbo.CoSo')
  AND c.name IN (N'DiaChi', N'ViDo', N'KinhDo')
ORDER BY c.column_id;

PRINT N'';
PRINT N'--- 2. Cơ sở đang hoạt động ("Đang hoạt động"/"Tạm nghỉ") nhưng thiếu tọa độ (ViDo/KinhDo đều NULL) ---';
SELECT CoSoID, TenCoSo, DiaChi, ViDo, KinhDo, TrangThai
FROM dbo.CoSo
WHERE (IsDeleted = 0 OR IsDeleted IS NULL)
  AND TrangThai IN (N'Đang hoạt động', N'Tạm nghỉ')
  AND ViDo IS NULL
  AND KinhDo IS NULL
ORDER BY CoSoID;

PRINT N'';
PRINT N'--- 3. Dữ liệu chỉ có MỘT trong hai giá trị ViDo/KinhDo (bất thường — cặp phải đi cùng nhau) ---';
SELECT CoSoID, TenCoSo, DiaChi, ViDo, KinhDo, TrangThai
FROM dbo.CoSo
WHERE (ViDo IS NULL) <> (KinhDo IS NULL)
ORDER BY CoSoID;

PRINT N'';
PRINT N'--- 4. Tọa độ ngoài phạm vi hợp lệ (ViDo ngoài [-90,90] hoặc KinhDo ngoài [-180,180]) ---';
SELECT CoSoID, TenCoSo, DiaChi, ViDo, KinhDo, TrangThai
FROM dbo.CoSo
WHERE (ViDo IS NOT NULL AND (ViDo < -90 OR ViDo > 90))
   OR (KinhDo IS NOT NULL AND (KinhDo < -180 OR KinhDo > 180))
ORDER BY CoSoID;

PRINT N'';
PRINT N'--- 5. DiaChi trông giống chuỗi tọa độ thay vì địa chỉ chữ (VD: "10.4873663, 107.1930497") ---';
SELECT CoSoID, TenCoSo, DiaChi, ViDo, KinhDo, TrangThai
FROM dbo.CoSo
WHERE DiaChi IS NOT NULL
  AND DiaChi LIKE '%[0-9].[0-9]%,%[0-9].[0-9]%'
  AND DiaChi NOT LIKE '%[a-zA-ZÀ-ỹ]%'
ORDER BY CoSoID;

PRINT N'';
PRINT N'--- 6. Tổng hợp toàn bộ CoSo chưa xóa mềm ---';
SELECT
    COUNT(*) AS TongSoCoSo,
    SUM(CASE WHEN ViDo IS NOT NULL AND KinhDo IS NOT NULL THEN 1 ELSE 0 END) AS CoDuToaDo,
    SUM(CASE WHEN ViDo IS NULL AND KinhDo IS NULL THEN 1 ELSE 0 END) AS ThieuToaDo,
    SUM(CASE WHEN (ViDo IS NULL) <> (KinhDo IS NULL) THEN 1 ELSE 0 END) AS ThieuMotTrongHai,
    SUM(CASE
            WHEN (ViDo IS NOT NULL AND (ViDo < -90 OR ViDo > 90))
              OR (KinhDo IS NOT NULL AND (KinhDo < -180 OR KinhDo > 180))
            THEN 1 ELSE 0
        END) AS ToaDoKhongHopLe
FROM dbo.CoSo
WHERE (IsDeleted = 0 OR IsDeleted IS NULL);

PRINT N'';
PRINT N'--- 7. Tổng hợp riêng cho cơ sở đang hoạt động/tạm nghỉ (loại "Chờ duyệt"/"Từ chối") ---';
SELECT
    COUNT(*) AS TongSoCoSoHoatDong,
    SUM(CASE WHEN ViDo IS NOT NULL AND KinhDo IS NOT NULL THEN 1 ELSE 0 END) AS CoDuToaDo,
    SUM(CASE WHEN ViDo IS NULL AND KinhDo IS NULL THEN 1 ELSE 0 END) AS ThieuToaDo
FROM dbo.CoSo
WHERE (IsDeleted = 0 OR IsDeleted IS NULL)
  AND TrangThai NOT IN (N'Chờ duyệt', N'Từ chối');
