-- =====================================================================
-- verify_team_management.sql
-- Kiểm tra schema module Đội nhóm sau khi chạy migration_team_management.sql.
-- Chỉ đọc (SELECT/PRINT) — không thay đổi dữ liệu.
-- =====================================================================

USE QuanLiSport;
GO

PRINT N'--- 1. Kiểm tra bảng Teams ---';
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Teams')
BEGIN
    PRINT N'FAIL: Bảng Teams không tồn tại.';
    RETURN;
END
SELECT c.name AS ColumnName, t.name AS DataType, c.is_nullable AS IsNullable
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID(N'dbo.Teams')
ORDER BY c.column_id;
GO

PRINT N'--- 2. Kiểm tra bảng TeamMembers + unique index chống trùng membership ACTIVE ---';
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'TeamMembers')
BEGIN
    PRINT N'FAIL: Bảng TeamMembers không tồn tại.';
    RETURN;
END
SELECT c.name AS ColumnName, t.name AS DataType, c.is_nullable AS IsNullable
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID(N'dbo.TeamMembers')
ORDER BY c.column_id;

SELECT i.name AS IndexName, i.is_unique AS IsUnique, i.filter_definition AS FilterDefinition
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID(N'dbo.TeamMembers') AND i.name = N'UX_TeamMembers_Active_Team_Account';
GO

PRINT N'--- 3. Kiểm tra bảng TeamInvitations + unique index chống trùng PENDING ---';
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'TeamInvitations')
BEGIN
    PRINT N'FAIL: Bảng TeamInvitations không tồn tại.';
    RETURN;
END
SELECT i.name AS IndexName, i.is_unique AS IsUnique, i.filter_definition AS FilterDefinition
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID(N'dbo.TeamInvitations') AND i.name = N'UX_TeamInvitations_Pending_Team_Account';
GO

PRINT N'--- 4. Kiểm tra bảng TeamJoinRequests + unique index chống trùng PENDING ---';
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'TeamJoinRequests')
BEGIN
    PRINT N'FAIL: Bảng TeamJoinRequests không tồn tại.';
    RETURN;
END
SELECT i.name AS IndexName, i.is_unique AS IsUnique, i.filter_definition AS FilterDefinition
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID(N'dbo.TeamJoinRequests') AND i.name = N'UX_TeamJoinRequests_Pending_Team_Account';
GO

PRINT N'--- 5. Kiểm tra cột tích hợp GhepKeo/ChiTietGhepKeo (TeamID*, nullable) ---';
SELECT
    'GhepKeo.TeamIDNguoiTao' AS ColumnRef,
    COL_LENGTH('dbo.GhepKeo', 'TeamIDNguoiTao') AS ColLength,
    (SELECT is_nullable FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.GhepKeo') AND name = N'TeamIDNguoiTao') AS IsNullable
UNION ALL
SELECT
    'ChiTietGhepKeo.TeamIDNguoiThamGia',
    COL_LENGTH('dbo.ChiTietGhepKeo', 'TeamIDNguoiThamGia'),
    (SELECT is_nullable FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.ChiTietGhepKeo') AND name = N'TeamIDNguoiThamGia');
GO

PRINT N'--- 6. Đếm dữ liệu hiện có (kỳ vọng 0 ngay sau migration lần đầu) ---';
SELECT
    (SELECT COUNT(*) FROM dbo.Teams) AS TotalTeams,
    (SELECT COUNT(*) FROM dbo.TeamMembers) AS TotalTeamMembers,
    (SELECT COUNT(*) FROM dbo.TeamInvitations) AS TotalInvitations,
    (SELECT COUNT(*) FROM dbo.TeamJoinRequests) AS TotalJoinRequests,
    (SELECT COUNT(*) FROM dbo.GhepKeo WHERE TeamIDNguoiTao IS NOT NULL) AS TeamKeoCount,
    (SELECT COUNT(*) FROM dbo.GhepKeo WHERE TeamIDNguoiTao IS NULL) AS IndividualKeoCount_KhongDoi;
GO

PRINT N'--- 7. Xác nhận mỗi Team ACTIVE có đúng 1 thành viên CAPTAIN ACTIVE ---';
SELECT t.TeamID, t.TeamName,
       (SELECT COUNT(*) FROM dbo.TeamMembers m
        WHERE m.TeamID = t.TeamID AND m.MemberRole = N'CAPTAIN' AND m.MemberStatus = N'ACTIVE') AS CaptainCount
FROM dbo.Teams t
WHERE t.Status = N'ACTIVE' AND (t.IsDeleted = 0 OR t.IsDeleted IS NULL);
GO

PRINT N'--- verify_team_management.sql: DONE ---';
