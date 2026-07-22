-- Verify: kiểm tra 6 bảng module dịch vụ thể thao đã tạo đúng, có FK/CHECK constraint.
USE QuanLiSport;
GO

SELECT t.name AS TableName, COUNT(c.column_id) AS ColumnCount
FROM sys.tables t
JOIN sys.columns c ON c.object_id = t.object_id
WHERE t.name IN (N'SportService', N'RacketStringingConfig', N'ServiceMaterial',
                  N'ServiceOrder', N'RacketStringingOrderDetail', N'ServiceOrderStatusHistory')
GROUP BY t.name
ORDER BY t.name;
GO

SELECT fk.name AS ForeignKey, tp.name AS ParentTable, tr.name AS RefTable
FROM sys.foreign_keys fk
JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
WHERE tp.name IN (N'SportService', N'RacketStringingConfig', N'ServiceMaterial',
                    N'ServiceOrder', N'RacketStringingOrderDetail', N'ServiceOrderStatusHistory')
ORDER BY tp.name;
GO

SELECT cc.name AS CheckConstraint, t.name AS TableName
FROM sys.check_constraints cc
JOIN sys.tables t ON cc.parent_object_id = t.object_id
WHERE t.name IN (N'SportService', N'RacketStringingConfig', N'ServiceMaterial',
                   N'ServiceOrder', N'RacketStringingOrderDetail')
ORDER BY t.name;
GO
