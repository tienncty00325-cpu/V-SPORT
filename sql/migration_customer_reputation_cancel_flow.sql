-- Migration: Hủy sân linh hoạt + Điểm uy tín khách hàng (Reputation)
-- Chạy một lần trên DB thực. Script có kiểm tra IF NOT EXISTS nên an toàn khi chạy lại.
-- Áp dụng cho: V-SPORT QuanLiSport_V4 trở lên
-- Liên quan: docs/reputation_cancel_flow.md

USE QuanLiSport;
GO

-- ========== 1. Accounts: bộ đếm uy tín (DiemUyTin đã có sẵn, KHÔNG tạo cột điểm mới) ==========

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'Accounts') AND name = N'LateCancelCount'
)
BEGIN
    ALTER TABLE Accounts
    ADD LateCancelCount INT NOT NULL DEFAULT 0;
    PRINT N'Đã thêm cột LateCancelCount vào Accounts.';
END
ELSE
    PRINT N'Cột LateCancelCount đã tồn tại, bỏ qua.';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'Accounts') AND name = N'NoShowCount'
)
BEGIN
    ALTER TABLE Accounts
    ADD NoShowCount INT NOT NULL DEFAULT 0;
    PRINT N'Đã thêm cột NoShowCount vào Accounts.';
END
ELSE
    PRINT N'Cột NoShowCount đã tồn tại, bỏ qua.';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'Accounts') AND name = N'CompletedBookingCount'
)
BEGIN
    ALTER TABLE Accounts
    ADD CompletedBookingCount INT NOT NULL DEFAULT 0;
    PRINT N'Đã thêm cột CompletedBookingCount vào Accounts.';
END
ELSE
    PRINT N'Cột CompletedBookingCount đã tồn tại, bỏ qua.';
GO

-- ========== 2. LichDatSan: thông tin hủy / cần xử lý hoàn tiền ==========
-- (NoShowAt và HoldExpiresAt đã có sẵn từ migration_reservation_hold.sql, KHÔNG tạo lại)

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'CancelType'
)
BEGIN
    ALTER TABLE LichDatSan
    ADD CancelType NVARCHAR(20) NULL;
    PRINT N'Đã thêm cột CancelType vào LichDatSan.';
END
ELSE
    PRINT N'Cột CancelType đã tồn tại, bỏ qua.';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'CancelReason'
)
BEGIN
    ALTER TABLE LichDatSan
    ADD CancelReason NVARCHAR(255) NULL;
    PRINT N'Đã thêm cột CancelReason vào LichDatSan.';
END
ELSE
    PRINT N'Cột CancelReason đã tồn tại, bỏ qua.';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'CancelledAt'
)
BEGIN
    ALTER TABLE LichDatSan
    ADD CancelledAt DATETIME2 NULL;
    PRINT N'Đã thêm cột CancelledAt vào LichDatSan.';
END
ELSE
    PRINT N'Cột CancelledAt đã tồn tại, bỏ qua.';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'CancelledBy'
)
BEGIN
    ALTER TABLE LichDatSan
    ADD CancelledBy INT NULL;
    PRINT N'Đã thêm cột CancelledBy vào LichDatSan.';
END
ELSE
    PRINT N'Cột CancelledBy đã tồn tại, bỏ qua.';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_LichDatSan_CancelledBy' AND parent_object_id = OBJECT_ID(N'LichDatSan')
)
BEGIN
    ALTER TABLE LichDatSan
    ADD CONSTRAINT FK_LichDatSan_CancelledBy
        FOREIGN KEY (CancelledBy) REFERENCES Accounts(AccountID);
    PRINT N'Đã thêm FK CancelledBy.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'RequiresRefundReview'
)
BEGIN
    ALTER TABLE LichDatSan
    ADD RequiresRefundReview BIT NOT NULL DEFAULT 0;
    PRINT N'Đã thêm cột RequiresRefundReview vào LichDatSan.';
END
ELSE
    PRINT N'Cột RequiresRefundReview đã tồn tại, bỏ qua.';
GO

-- ========== 3. Bảng lịch sử điểm uy tín (audit trail cho DiemUyTin) ==========

IF OBJECT_ID(N'CustomerReputationHistory', N'U') IS NULL
BEGIN
    CREATE TABLE CustomerReputationHistory (
        ReputationHistoryID BIGINT IDENTITY(1,1) PRIMARY KEY,
        AccountID            INT             NOT NULL,
        DatSanID              INT             NULL,
        ActionType            NVARCHAR(30)    NOT NULL,
        ScoreDelta            INT             NOT NULL,
        ScoreBefore           INT             NOT NULL,
        ScoreAfter            INT             NOT NULL,
        Reason                NVARCHAR(255)   NULL,
        CreatedAt             DATETIME2       NOT NULL DEFAULT GETDATE(),
        CreatedBy             INT             NULL,
        IpAddress             NVARCHAR(50)    NULL,
        CONSTRAINT FK_ReputationHistory_Account FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID),
        CONSTRAINT FK_ReputationHistory_DatSan  FOREIGN KEY (DatSanID)  REFERENCES LichDatSan(DatSanID),
        CONSTRAINT FK_ReputationHistory_Actor   FOREIGN KEY (CreatedBy) REFERENCES Accounts(AccountID)
    );
    PRINT N'Đã tạo bảng CustomerReputationHistory.';
END
ELSE
    PRINT N'Bảng CustomerReputationHistory đã tồn tại, bỏ qua.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ReputationHistory_Account' AND object_id = OBJECT_ID(N'CustomerReputationHistory'))
BEGIN
    CREATE INDEX IX_ReputationHistory_Account ON CustomerReputationHistory(AccountID, CreatedAt DESC);
    PRINT N'Đã tạo index IX_ReputationHistory_Account.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ReputationHistory_DatSan' AND object_id = OBJECT_ID(N'CustomerReputationHistory'))
BEGIN
    CREATE INDEX IX_ReputationHistory_DatSan ON CustomerReputationHistory(DatSanID);
    PRINT N'Đã tạo index IX_ReputationHistory_DatSan.';
END
GO

PRINT N'Migration customer-reputation-cancel-flow hoàn tất.';
GO
