-- Verify: sql/migration_facility_capability.sql
-- Kiểm tra bảng, cột, ràng buộc, index đã tạo đúng như thiết kế. Không sửa dữ liệu.

USE QuanLiSport;
GO

PRINT N'--- 1. Bảng CoSoCapability tồn tại? ---';
SELECT CASE WHEN OBJECT_ID('dbo.CoSoCapability', 'U') IS NOT NULL
            THEN N'OK: bảng tồn tại' ELSE N'FAIL: bảng KHÔNG tồn tại' END AS KetQua;
GO

PRINT N'--- 2. Danh sách cột ---';
SELECT c.name AS ColumnName, t.name AS DataType, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.CoSoCapability')
ORDER BY c.column_id;
GO

PRINT N'--- 3. Khóa ngoại ---';
SELECT fk.name AS ForeignKeyName,
       OBJECT_NAME(fk.parent_object_id) AS TableName,
       OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable
FROM sys.foreign_keys fk
WHERE fk.parent_object_id = OBJECT_ID('dbo.CoSoCapability');
GO

PRINT N'--- 4. Unique constraint (CoSoID, CapabilityType) ---';
SELECT i.name AS IndexName, i.is_unique, i.is_unique_constraint
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('dbo.CoSoCapability') AND i.is_unique = 1;
GO

PRINT N'--- 5. Index tra cứu ---';
SELECT i.name AS IndexName
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('dbo.CoSoCapability') AND i.name IS NOT NULL;
GO

PRINT N'--- 6. Số dòng hiện tại theo trạng thái (kỳ vọng có SAN/SAN_PHAM=APPROVED do grandfathering) ---';
SELECT CapabilityType, TrangThai, COUNT(*) AS SoLuong
FROM dbo.CoSoCapability
GROUP BY CapabilityType, TrangThai
ORDER BY CapabilityType, TrangThai;
GO

PRINT N'--- 7. Mọi CoSo đang hoạt động phải có SAN=APPROVED và SAN_PHAM=APPROVED (grandfathering) ---';
SELECT c.CoSoID, c.TenCoSo,
       MAX(CASE WHEN cc.CapabilityType = N'SAN' AND cc.TrangThai = N'APPROVED' THEN 1 ELSE 0 END) AS CoSAN,
       MAX(CASE WHEN cc.CapabilityType = N'SAN_PHAM' AND cc.TrangThai = N'APPROVED' THEN 1 ELSE 0 END) AS CoSanPham
FROM dbo.CoSo c
LEFT JOIN dbo.CoSoCapability cc ON cc.CoSoID = c.CoSoID
WHERE c.TrangThai = N'Đang hoạt động' AND (c.isDeleted = 0 OR c.isDeleted IS NULL)
GROUP BY c.CoSoID, c.TenCoSo
HAVING MAX(CASE WHEN cc.CapabilityType = N'SAN' AND cc.TrangThai = N'APPROVED' THEN 1 ELSE 0 END) = 0
    OR MAX(CASE WHEN cc.CapabilityType = N'SAN_PHAM' AND cc.TrangThai = N'APPROVED' THEN 1 ELSE 0 END) = 0;
-- Kỳ vọng: 0 dòng trả về (nếu có dòng nào nghĩa là cơ sở đó CHƯA được grandfather đúng).
GO
