-- Diagnostic SQL read-only script to verify V-SPORT Accounts reputation schema
-- Only SELECT/PRINT statements allowed. No ALTER/UPDATE/DELETE/INSERT.

USE QuanLiSport;
GO

PRINT 'Checking columns in dbo.Accounts...';
SELECT 
    COL_LENGTH('dbo.Accounts', 'DiemUyTin') AS DiemUyTinExists,
    COL_LENGTH('dbo.Accounts', 'LateCancelCount') AS LateCancelCountExists,
    COL_LENGTH('dbo.Accounts', 'NoShowCount') AS NoShowCountExists,
    COL_LENGTH('dbo.Accounts', 'CompletedBookingCount') AS CompletedBookingCountExists;
GO

PRINT 'Checking existence of CustomerReputationHistory table...';
SELECT OBJECT_ID('dbo.CustomerReputationHistory') AS CustomerReputationHistoryExists;
GO
