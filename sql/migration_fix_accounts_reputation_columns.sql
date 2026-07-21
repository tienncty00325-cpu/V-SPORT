-- Migration: Fix schema mismatch for Accounts table (Reputation Columns)
-- Idempotent script using SQL Server logic to add missing columns and backfill existing NULL fields.

USE QuanLiSport;
GO

-- 1. CompletedBookingCount
IF COL_LENGTH('dbo.Accounts', 'CompletedBookingCount') IS NULL
BEGIN
    ALTER TABLE dbo.Accounts
    ADD CompletedBookingCount INT NOT NULL
        CONSTRAINT DF_Accounts_CompletedBookingCount DEFAULT 0;
    PRINT 'Added column CompletedBookingCount to Accounts table.';
END
ELSE
BEGIN
    PRINT 'Column CompletedBookingCount already exists.';
END
GO

-- 2. LateCancelCount
IF COL_LENGTH('dbo.Accounts', 'LateCancelCount') IS NULL
BEGIN
    ALTER TABLE dbo.Accounts
    ADD LateCancelCount INT NOT NULL
        CONSTRAINT DF_Accounts_LateCancelCount DEFAULT 0;
    PRINT 'Added column LateCancelCount to Accounts table.';
END
ELSE
BEGIN
    PRINT 'Column LateCancelCount already exists.';
END
GO

-- 3. NoShowCount
IF COL_LENGTH('dbo.Accounts', 'NoShowCount') IS NULL
BEGIN
    ALTER TABLE dbo.Accounts
    ADD NoShowCount INT NOT NULL
        CONSTRAINT DF_Accounts_NoShowCount DEFAULT 0;
    PRINT 'Added column NoShowCount to Accounts table.';
END
ELSE
BEGIN
    PRINT 'Column NoShowCount already exists.';
END
GO

-- 4. DiemUyTin
IF COL_LENGTH('dbo.Accounts', 'DiemUyTin') IS NULL
BEGIN
    ALTER TABLE dbo.Accounts
    ADD DiemUyTin INT NOT NULL
        CONSTRAINT DF_Accounts_DiemUyTin DEFAULT 100;
    PRINT 'Added column DiemUyTin to Accounts table.';
END
ELSE
BEGIN
    PRINT 'Column DiemUyTin already exists.';
END
GO

-- Safe backfill for existing NULL values
UPDATE dbo.Accounts SET CompletedBookingCount = 0 WHERE CompletedBookingCount IS NULL;
UPDATE dbo.Accounts SET LateCancelCount = 0 WHERE LateCancelCount IS NULL;
UPDATE dbo.Accounts SET NoShowCount = 0 WHERE NoShowCount IS NULL;
UPDATE dbo.Accounts SET DiemUyTin = 100 WHERE DiemUyTin IS NULL;
GO

PRINT 'Migration fix_accounts_reputation_columns completed successfully.';
GO
