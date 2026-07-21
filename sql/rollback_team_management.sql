-- =====================================================================
-- rollback_team_management.sql
-- Hoàn tác migration_team_management.sql: xóa 4 bảng Team* và 2 cột
-- tích hợp GhepKeo/ChiTietGhepKeo (+ FK của chúng).
--
-- Không có tiền lệ "rollback_*.sql" nào khác trong repo tại thời điểm
-- viết script này — file này dựa theo khung "diagnose_and_repair_*.sql"
-- hiện có: PHẦN 1 chỉ SELECT/PRINT (luôn an toàn để chạy), PHẦN 2 mới
-- thực sự DROP và CHỈ chạy khi người vận hành chủ động bật cờ an toàn
-- @ConfirmRollback = 1 bên dưới.
--
-- CẢNH BÁO: PHẦN 2 xóa vĩnh viễn toàn bộ dữ liệu Teams/TeamMembers/
-- TeamInvitations/TeamJoinRequests. Không có soft-delete cho việc này.
-- Hãy backup hoặc chạy PHẦN 1 trước để chắc chắn không còn dữ liệu quan
-- trọng, rồi mới bật cờ.
-- =====================================================================

USE QuanLiSport;
GO

SET XACT_ABORT ON;
GO

-- ================= PHẦN 1: DIAGNOSTIC (luôn an toàn) =================
PRINT N'--- PHẦN 1: Dữ liệu hiện có trước khi rollback ---';
IF OBJECT_ID(N'dbo.Teams', N'U') IS NOT NULL
    SELECT COUNT(*) AS TeamsCount FROM dbo.Teams;
IF OBJECT_ID(N'dbo.TeamMembers', N'U') IS NOT NULL
    SELECT COUNT(*) AS TeamMembersCount FROM dbo.TeamMembers;
IF OBJECT_ID(N'dbo.TeamInvitations', N'U') IS NOT NULL
    SELECT COUNT(*) AS TeamInvitationsCount FROM dbo.TeamInvitations;
IF OBJECT_ID(N'dbo.TeamJoinRequests', N'U') IS NOT NULL
    SELECT COUNT(*) AS TeamJoinRequestsCount FROM dbo.TeamJoinRequests;
IF OBJECT_ID(N'dbo.GhepKeo', N'U') IS NOT NULL AND COL_LENGTH('dbo.GhepKeo', 'TeamIDNguoiTao') IS NOT NULL
    SELECT COUNT(*) AS GhepKeoTaggedWithTeam FROM dbo.GhepKeo WHERE TeamIDNguoiTao IS NOT NULL;
GO

-- ============ PHẦN 2: ROLLBACK THẬT (mặc định TẮT) ============
-- Đổi 0 -> 1 ở dòng dưới rồi chạy lại toàn bộ file để thực sự rollback.
DECLARE @ConfirmRollback BIT = 0;

IF @ConfirmRollback = 1
BEGIN
    BEGIN TRANSACTION;

    -- 2.1 Gỡ 2 cột tích hợp GhepKeo/ChiTietGhepKeo (và FK của chúng) trước,
    --     vì chúng tham chiếu tới Teams.
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ChiTietGhepKeo_TeamNguoiThamGia')
        ALTER TABLE dbo.ChiTietGhepKeo DROP CONSTRAINT FK_ChiTietGhepKeo_TeamNguoiThamGia;
    IF COL_LENGTH('dbo.ChiTietGhepKeo', 'TeamIDNguoiThamGia') IS NOT NULL
        ALTER TABLE dbo.ChiTietGhepKeo DROP COLUMN TeamIDNguoiThamGia;

    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_GhepKeo_TeamNguoiTao')
        ALTER TABLE dbo.GhepKeo DROP CONSTRAINT FK_GhepKeo_TeamNguoiTao;
    IF COL_LENGTH('dbo.GhepKeo', 'TeamIDNguoiTao') IS NOT NULL
        ALTER TABLE dbo.GhepKeo DROP COLUMN TeamIDNguoiTao;

    -- 2.2 Xóa các bảng phụ thuộc trước, Teams sau cùng (thứ tự ngược FK).
    IF OBJECT_ID(N'dbo.TeamJoinRequests', N'U') IS NOT NULL DROP TABLE dbo.TeamJoinRequests;
    IF OBJECT_ID(N'dbo.TeamInvitations', N'U') IS NOT NULL DROP TABLE dbo.TeamInvitations;
    IF OBJECT_ID(N'dbo.TeamMembers', N'U') IS NOT NULL DROP TABLE dbo.TeamMembers;
    IF OBJECT_ID(N'dbo.Teams', N'U') IS NOT NULL DROP TABLE dbo.Teams;

    COMMIT TRANSACTION;
    PRINT N'ROLLBACK hoàn tất: đã xóa toàn bộ schema Team management.';
END
ELSE
    PRINT N'Bỏ qua PHẦN 2: @ConfirmRollback = 0 (mặc định an toàn). Đổi thành 1 trong file để thực sự rollback.';
GO
