-- =====================================================================
-- migration_team_management.sql
-- Tạo schema cho module Đội nhóm (Team management): Teams, TeamMembers,
-- TeamInvitations, TeamJoinRequests. Đồng thời bổ sung 2 cột nullable
-- TeamIDNguoiTao / TeamIDNguoiThamGia vào GhepKeo / ChiTietGhepKeo để
-- một đội có thể tạo/nhận kèo dưới danh nghĩa đội mà KHÔNG đổi hành vi
-- ghép kèo cá nhân hiện có (cột mới luôn NULL cho các kèo cá nhân cũ).
--
-- Idempotent: chạy lại nhiều lần không lỗi (kiểm tra OBJECT_ID/COL_LENGTH
-- trước khi CREATE/ALTER, theo đúng phong cách các migration hiện có
-- trong repo, ví dụ migration_matchmaking_complete_flow.sql).
--
-- Không tự động thực thi — người vận hành phải tự chạy tay trên
-- SQL Server (database QuanLiSport).
-- =====================================================================

USE QuanLiSport;
GO

-- ============================== Teams ==============================
IF OBJECT_ID(N'dbo.Teams', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Teams (
        TeamID              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Teams PRIMARY KEY,
        TeamName            NVARCHAR(50)  NOT NULL,
        Description         NVARCHAR(225) NULL,
        SportID             INT NOT NULL,
        CaptainAccountID    INT NOT NULL,
        LocationText        NVARCHAR(255) NULL,
        AvatarPath          NVARCHAR(500) NULL,
        CoverImagePath      NVARCHAR(500) NULL,
        MaxMembers          INT NOT NULL,
        Status              VARCHAR(30) NOT NULL CONSTRAINT DF_Teams_Status DEFAULT ('ACTIVE'),
        CreatedAt           DATETIME2   NOT NULL CONSTRAINT DF_Teams_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt           DATETIME2   NULL,
        IsDeleted           BIT         NOT NULL CONSTRAINT DF_Teams_IsDeleted DEFAULT (0),
        DeletedAt           DATETIME2   NULL,
        DeletedBy           INT         NULL,
        CONSTRAINT FK_Teams_Sport   FOREIGN KEY (SportID) REFERENCES dbo.MonTheThao(MonTheThaoID),
        CONSTRAINT FK_Teams_Captain FOREIGN KEY (CaptainAccountID) REFERENCES dbo.Accounts(AccountID),
        CONSTRAINT CK_Teams_MaxMembers CHECK (MaxMembers BETWEEN 2 AND 30),
        CONSTRAINT CK_Teams_Status CHECK (Status IN (N'ACTIVE', N'INACTIVE', N'DISBANDED', N'SUSPENDED'))
    );
    CREATE INDEX IX_Teams_Captain ON dbo.Teams(CaptainAccountID);
    CREATE INDEX IX_Teams_Sport   ON dbo.Teams(SportID);
    CREATE INDEX IX_Teams_Status  ON dbo.Teams(Status);
    PRINT N'CREATED TABLE Teams';
END
ELSE
    PRINT N'SKIP TABLE Teams (đã tồn tại)';
GO

-- ========================== TeamMembers =============================
IF OBJECT_ID(N'dbo.TeamMembers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TeamMembers (
        TeamMemberID  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TeamMembers PRIMARY KEY,
        TeamID        INT NOT NULL,
        AccountID     INT NOT NULL,
        MemberRole    VARCHAR(30) NOT NULL,
        MemberStatus  VARCHAR(30) NOT NULL CONSTRAINT DF_TeamMembers_Status DEFAULT ('ACTIVE'),
        JoinedAt      DATETIME2   NOT NULL CONSTRAINT DF_TeamMembers_JoinedAt DEFAULT (SYSUTCDATETIME()),
        LeftAt        DATETIME2   NULL,
        AddedBy       INT         NULL,
        CONSTRAINT FK_TeamMembers_Team    FOREIGN KEY (TeamID) REFERENCES dbo.Teams(TeamID),
        CONSTRAINT FK_TeamMembers_Account FOREIGN KEY (AccountID) REFERENCES dbo.Accounts(AccountID),
        CONSTRAINT CK_TeamMembers_Role   CHECK (MemberRole IN (N'CAPTAIN', N'CO_CAPTAIN', N'MEMBER')),
        CONSTRAINT CK_TeamMembers_Status CHECK (MemberStatus IN (N'ACTIVE', N'LEFT', N'REMOVED'))
    );
    -- Một AccountID chỉ có một membership ACTIVE trong cùng TeamID.
    CREATE UNIQUE INDEX UX_TeamMembers_Active_Team_Account
        ON dbo.TeamMembers(TeamID, AccountID)
        WHERE MemberStatus = N'ACTIVE';
    CREATE INDEX IX_TeamMembers_Account ON dbo.TeamMembers(AccountID, MemberStatus);
    PRINT N'CREATED TABLE TeamMembers';
END
ELSE
    PRINT N'SKIP TABLE TeamMembers (đã tồn tại)';
GO

-- ========================= TeamInvitations ===========================
IF OBJECT_ID(N'dbo.TeamInvitations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TeamInvitations (
        InvitationID        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TeamInvitations PRIMARY KEY,
        TeamID               INT NOT NULL,
        InvitedAccountID     INT NOT NULL,
        InvitedByAccountID   INT NOT NULL,
        ProposedRole         VARCHAR(30) NOT NULL CONSTRAINT DF_TeamInvitations_Role DEFAULT ('MEMBER'),
        Status               VARCHAR(30) NOT NULL CONSTRAINT DF_TeamInvitations_Status DEFAULT ('PENDING'),
        Message              NVARCHAR(255) NULL,
        CreatedAt            DATETIME2   NOT NULL CONSTRAINT DF_TeamInvitations_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ExpiresAt            DATETIME2   NULL,
        RespondedAt          DATETIME2   NULL,
        CONSTRAINT FK_TeamInvitations_Team      FOREIGN KEY (TeamID) REFERENCES dbo.Teams(TeamID),
        CONSTRAINT FK_TeamInvitations_Invited   FOREIGN KEY (InvitedAccountID) REFERENCES dbo.Accounts(AccountID),
        CONSTRAINT FK_TeamInvitations_InvitedBy FOREIGN KEY (InvitedByAccountID) REFERENCES dbo.Accounts(AccountID),
        CONSTRAINT CK_TeamInvitations_Role   CHECK (ProposedRole IN (N'CO_CAPTAIN', N'MEMBER')),
        CONSTRAINT CK_TeamInvitations_Status CHECK (Status IN (N'PENDING', N'ACCEPTED', N'REJECTED', N'CANCELLED', N'EXPIRED'))
    );
    -- Không cho nhiều invitation PENDING cho cùng TeamID + InvitedAccountID.
    CREATE UNIQUE INDEX UX_TeamInvitations_Pending_Team_Account
        ON dbo.TeamInvitations(TeamID, InvitedAccountID)
        WHERE Status = N'PENDING';
    CREATE INDEX IX_TeamInvitations_Invited ON dbo.TeamInvitations(InvitedAccountID, Status);
    PRINT N'CREATED TABLE TeamInvitations';
END
ELSE
    PRINT N'SKIP TABLE TeamInvitations (đã tồn tại)';
GO

-- ========================= TeamJoinRequests ==========================
IF OBJECT_ID(N'dbo.TeamJoinRequests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TeamJoinRequests (
        JoinRequestID         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TeamJoinRequests PRIMARY KEY,
        TeamID                 INT NOT NULL,
        RequesterAccountID     INT NOT NULL,
        Message                NVARCHAR(255) NULL,
        Status                 VARCHAR(30) NOT NULL CONSTRAINT DF_TeamJoinRequests_Status DEFAULT ('PENDING'),
        CreatedAt              DATETIME2   NOT NULL CONSTRAINT DF_TeamJoinRequests_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ReviewedAt             DATETIME2   NULL,
        ReviewedByAccountID    INT         NULL,
        CONSTRAINT FK_TeamJoinRequests_Team      FOREIGN KEY (TeamID) REFERENCES dbo.Teams(TeamID),
        CONSTRAINT FK_TeamJoinRequests_Requester FOREIGN KEY (RequesterAccountID) REFERENCES dbo.Accounts(AccountID),
        CONSTRAINT FK_TeamJoinRequests_Reviewer  FOREIGN KEY (ReviewedByAccountID) REFERENCES dbo.Accounts(AccountID),
        CONSTRAINT CK_TeamJoinRequests_Status CHECK (Status IN (N'PENDING', N'APPROVED', N'REJECTED', N'CANCELLED'))
    );
    -- Không cho nhiều request PENDING cùng TeamID + RequesterAccountID.
    CREATE UNIQUE INDEX UX_TeamJoinRequests_Pending_Team_Account
        ON dbo.TeamJoinRequests(TeamID, RequesterAccountID)
        WHERE Status = N'PENDING';
    CREATE INDEX IX_TeamJoinRequests_Requester ON dbo.TeamJoinRequests(RequesterAccountID, Status);
    PRINT N'CREATED TABLE TeamJoinRequests';
END
ELSE
    PRINT N'SKIP TABLE TeamJoinRequests (đã tồn tại)';
GO

-- ===================================================================
-- Tích hợp Ghép kèo (GhepKeo/ChiTietGhepKeo): 2 cột nullable để một
-- kèo/lượt tham gia có thể được gắn nhãn "dưới danh nghĩa đội" mà
-- không đổi bất kỳ ràng buộc NOT NULL / hành vi nào hiện có. Các kèo
-- cá nhân cũ và mới đều để 2 cột này NULL, không bị ảnh hưởng.
-- ===================================================================
IF OBJECT_ID(N'dbo.GhepKeo', N'U') IS NOT NULL AND COL_LENGTH('dbo.GhepKeo', 'TeamIDNguoiTao') IS NULL
BEGIN
    ALTER TABLE dbo.GhepKeo ADD TeamIDNguoiTao INT NULL;
    PRINT N'ADDED GhepKeo.TeamIDNguoiTao';
END
ELSE
    PRINT N'SKIP GhepKeo.TeamIDNguoiTao (đã tồn tại hoặc bảng GhepKeo chưa có)';
GO

IF OBJECT_ID(N'dbo.GhepKeo', N'U') IS NOT NULL
   AND COL_LENGTH('dbo.GhepKeo', 'TeamIDNguoiTao') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_GhepKeo_TeamNguoiTao')
BEGIN
    ALTER TABLE dbo.GhepKeo ADD CONSTRAINT FK_GhepKeo_TeamNguoiTao FOREIGN KEY (TeamIDNguoiTao) REFERENCES dbo.Teams(TeamID);
    PRINT N'ADDED FK_GhepKeo_TeamNguoiTao';
END
ELSE
    PRINT N'SKIP FK_GhepKeo_TeamNguoiTao (đã tồn tại hoặc điều kiện chưa đủ)';
GO

IF OBJECT_ID(N'dbo.ChiTietGhepKeo', N'U') IS NOT NULL AND COL_LENGTH('dbo.ChiTietGhepKeo', 'TeamIDNguoiThamGia') IS NULL
BEGIN
    ALTER TABLE dbo.ChiTietGhepKeo ADD TeamIDNguoiThamGia INT NULL;
    PRINT N'ADDED ChiTietGhepKeo.TeamIDNguoiThamGia';
END
ELSE
    PRINT N'SKIP ChiTietGhepKeo.TeamIDNguoiThamGia (đã tồn tại hoặc bảng ChiTietGhepKeo chưa có)';
GO

IF OBJECT_ID(N'dbo.ChiTietGhepKeo', N'U') IS NOT NULL
   AND COL_LENGTH('dbo.ChiTietGhepKeo', 'TeamIDNguoiThamGia') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ChiTietGhepKeo_TeamNguoiThamGia')
BEGIN
    ALTER TABLE dbo.ChiTietGhepKeo ADD CONSTRAINT FK_ChiTietGhepKeo_TeamNguoiThamGia FOREIGN KEY (TeamIDNguoiThamGia) REFERENCES dbo.Teams(TeamID);
    PRINT N'ADDED FK_ChiTietGhepKeo_TeamNguoiThamGia';
END
ELSE
    PRINT N'SKIP FK_ChiTietGhepKeo_TeamNguoiThamGia (đã tồn tại hoặc điều kiện chưa đủ)';
GO

PRINT N'=== migration_team_management.sql: DONE ===';
GO
