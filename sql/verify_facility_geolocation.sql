-- Diagnostic SQL read-only script to verify V-SPORT CoSo geolocation schema and values
-- Only SELECT/PRINT statements allowed. No ALTER/UPDATE/DELETE/INSERT.

USE QuanLiSport;
GO

PRINT 'Checking columns ViDo and KinhDo in dbo.CoSo...';
SELECT 
    COL_LENGTH('dbo.CoSo', 'ViDo') AS ViDoColumnExists,
    COL_LENGTH('dbo.CoSo', 'KinhDo') AS KinhDoColumnExists;
GO

PRINT 'Listing seeded facilities with coordinates...';
SELECT CoSoID, TenCoSo, DiaChi, ViDo, KinhDo, TrangThai
FROM dbo.CoSo
WHERE (isDeleted = 0 OR isDeleted IS NULL);
GO
