-- V-SPORT CoSo Geolocation Migration Script (Idempotent)
-- Adds ViDo and KinhDo columns to the CoSo table if not already present.
-- Provides fallback coordinates for existing facilities in HCMC.

USE QuanLiSport;
GO

PRINT 'Starting facility geolocation migration...';

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.CoSo') AND name = 'ViDo'
)
BEGIN
    PRINT 'Adding ViDo column to CoSo...';
    ALTER TABLE dbo.CoSo ADD ViDo DECIMAL(12, 9) NULL;
END
ELSE
BEGIN
    PRINT 'ViDo column already exists in CoSo.';
END;

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.CoSo') AND name = 'KinhDo'
)
BEGIN
    PRINT 'Adding KinhDo column to CoSo...';
    ALTER TABLE dbo.CoSo ADD KinhDo DECIMAL(12, 9) NULL;
END
ELSE
BEGIN
    PRINT 'KinhDo column already exists in CoSo.';
END;
GO

-- Seed sample coordinates (HCMC-based) for active facilities that don't have them
PRINT 'Seeding sample coordinates for facilities...';

UPDATE dbo.CoSo
SET ViDo = 10.772561, KinhDo = 106.698021
WHERE (ViDo IS NULL OR KinhDo IS NULL) AND (TenCoSo LIKE N'%Quận 1%' OR TenCoSo LIKE N'%Bến Thành%' OR TenCoSo LIKE N'%Swin%' OR TenCoSo LIKE N'%SWIN%');

UPDATE dbo.CoSo
SET ViDo = 10.762622, KinhDo = 106.660172
WHERE (ViDo IS NULL OR KinhDo IS NULL) AND (TenCoSo LIKE N'%Quận 10%' OR TenCoSo LIKE N'%Kỳ Hòa%');

UPDATE dbo.CoSo
SET ViDo = 10.801867, KinhDo = 106.640165
WHERE (ViDo IS NULL OR KinhDo IS NULL) AND TenCoSo LIKE N'%Tân Bình%';

UPDATE dbo.CoSo
SET ViDo = 10.7882, KinhDo = 106.7025
WHERE (ViDo IS NULL OR KinhDo IS NULL) AND TenCoSo LIKE N'%Bình Thạnh%';

-- Fallback for any other facilities
UPDATE dbo.CoSo
SET ViDo = 10.782500, KinhDo = 106.689700
WHERE (ViDo IS NULL OR KinhDo IS NULL);

PRINT 'Facility geolocation migration completed successfully.';
GO
