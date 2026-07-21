-- Migration idempotent cho bảng lịch sử gia hạn ca chơi (BookingExtension)
USE QuanLiSport;
GO

IF OBJECT_ID(N'BookingExtension', N'U') IS NULL
BEGIN
    CREATE TABLE BookingExtension (
        ExtensionID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_BookingExtension PRIMARY KEY,
        DatSanID INT NOT NULL,
        OldGioKetThuc TIME NOT NULL,
        NewGioKetThuc TIME NOT NULL,
        OldGioKetThucDateTime DATETIME2 NULL,
        NewGioKetThucDateTime DATETIME2 NULL,
        AdditionalAmount DECIMAL(18,2) NOT NULL,
        OperatorAccountID INT NOT NULL,
        CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_BookingExtension_CreatedAt DEFAULT GETDATE(),
        CONSTRAINT FK_BookingExtension_LichDatSan FOREIGN KEY (DatSanID) REFERENCES LichDatSan(DatSanID),
        CONSTRAINT FK_BookingExtension_Operator FOREIGN KEY (OperatorAccountID) REFERENCES Accounts(AccountID)
    );
END
GO
