-- Migration: Module "Dịch vụ thể thao tại cơ sở" (Giai đoạn 1 - căng lưới, thay
-- quấn cán, sửa vợt, huấn luyện viên...). Tách hoàn toàn khỏi SanPham_DichVu (module
-- bán sản phẩm bán lẻ Phase 8A) để không lẫn nghiệp vụ dịch vụ với bán lẻ/giỏ hàng.
-- Gồm 6 bảng: SportService, RacketStringingConfig, ServiceMaterial, ServiceOrder,
-- RacketStringingOrderDetail, ServiceOrderStatusHistory.
-- Chạy một lần trên DB thực. Script có kiểm tra IF NOT EXISTS nên an toàn khi chạy lại.
-- Áp dụng cho: V-SPORT QuanLiSport. Không xóa dữ liệu hiện có.

USE QuanLiSport;
GO

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. SportService — dịch vụ cơ sở cung cấp (căng lưới, thay quấn cán, sửa vợt,
--    bảo dưỡng, huấn luyện viên, khác). Chỉ hiển thị public khi CoSo active +
--    CoSoCapability(DICH_VU_THE_THAO) = APPROVED (kiểm tra ở tầng Service/DAO).
-- ═══════════════════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.SportService', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SportService (
        ServiceID           INT IDENTITY(1,1) PRIMARY KEY,
        CoSoID              INT NOT NULL,
        -- CANG_LUOI, THAY_QUAN_CAN, SUA_VOT, BAO_DUONG, HUAN_LUYEN_VIEN, KHAC
        ServiceType         NVARCHAR(30)   NOT NULL,
        ServiceName         NVARCHAR(150)  NOT NULL,
        SportType           NVARCHAR(50)   NULL,      -- Cầu lông, Tennis, ...
        Description         NVARCHAR(1000) NULL,
        BasePrice           DECIMAL(12,2)  NOT NULL CONSTRAINT DF_SportService_BasePrice DEFAULT 0,
        Unit                NVARCHAR(30)   NULL,       -- "vợt", "lần", "giờ"...
        EstimatedMinutes    INT NOT NULL CONSTRAINT DF_SportService_EstMinutes DEFAULT 60,
        MaxRequestsPerDay   INT NULL,
        ReceiveTimeStart    TIME NULL,
        ReceiveTimeEnd      TIME NULL,
        ImageUrl            NVARCHAR(300) NULL,
        IsAcceptingRequests BIT NOT NULL CONSTRAINT DF_SportService_Accepting DEFAULT 1,
        Policy              NVARCHAR(1000) NULL,
        CustomerNote        NVARCHAR(500) NULL,
        IsDeleted           BIT NOT NULL CONSTRAINT DF_SportService_IsDeleted DEFAULT 0,
        CreatedAt           DATETIME2 NOT NULL CONSTRAINT DF_SportService_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt           DATETIME2 NOT NULL CONSTRAINT DF_SportService_UpdatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_SportService_CoSo FOREIGN KEY (CoSoID) REFERENCES dbo.CoSo(CoSoID),
        CONSTRAINT CK_SportService_BasePrice CHECK (BasePrice >= 0),
        CONSTRAINT CK_SportService_EstMinutes CHECK (EstimatedMinutes > 0),
        CONSTRAINT CK_SportService_ServiceType CHECK (ServiceType IN
            (N'CANG_LUOI', N'THAY_QUAN_CAN', N'SUA_VOT', N'BAO_DUONG', N'HUAN_LUYEN_VIEN', N'KHAC'))
    );
    CREATE INDEX IX_SportService_CoSoID ON dbo.SportService (CoSoID);
    CREATE INDEX IX_SportService_ServiceType ON dbo.SportService (ServiceType);
    PRINT N'Đã tạo bảng SportService.';
END
ELSE
    PRINT N'Bảng SportService đã tồn tại, bỏ qua.';
GO

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. RacketStringingConfig — cấu hình riêng khi SportService.ServiceType = CANG_LUOI.
--    1-1 với SportService (UNIQUE ServiceID).
-- ═══════════════════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.RacketStringingConfig', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.RacketStringingConfig (
        ConfigID            INT IDENTITY(1,1) PRIMARY KEY,
        ServiceID           INT NOT NULL,
        RacketTypes         NVARCHAR(300) NULL,   -- CSV loại vợt nhận: "Cầu lông,Tennis"
        StringingPrice      DECIMAL(12,2) NOT NULL CONSTRAINT DF_RacketCfg_StringingPrice DEFAULT 0,
        MinTension          DECIMAL(5,2)  NOT NULL,
        MaxTension          DECIMAL(5,2)  NOT NULL,
        TensionUnit         NVARCHAR(5)   NOT NULL CONSTRAINT DF_RacketCfg_TensionUnit DEFAULT N'kg',
        AllowCustomerString BIT NOT NULL CONSTRAINT DF_RacketCfg_AllowCustomerString DEFAULT 1,
        SellsString         BIT NOT NULL CONSTRAINT DF_RacketCfg_SellsString DEFAULT 1,
        AvgCompletionMinutes INT NOT NULL CONSTRAINT DF_RacketCfg_AvgMinutes DEFAULT 60,
        MaxRacketsPerOrder  INT NOT NULL CONSTRAINT DF_RacketCfg_MaxRackets DEFAULT 5,
        OldRacketPolicy     NVARCHAR(500) NULL,
        StringBreakPolicy   NVARCHAR(500) NULL,
        CONSTRAINT FK_RacketCfg_Service FOREIGN KEY (ServiceID) REFERENCES dbo.SportService(ServiceID),
        CONSTRAINT UQ_RacketCfg_ServiceID UNIQUE (ServiceID),
        CONSTRAINT CK_RacketCfg_TensionUnit CHECK (TensionUnit IN (N'kg', N'lbs')),
        CONSTRAINT CK_RacketCfg_Tension CHECK (MinTension > 0 AND MaxTension >= MinTension),
        CONSTRAINT CK_RacketCfg_StringingPrice CHECK (StringingPrice >= 0),
        CONSTRAINT CK_RacketCfg_MaxRackets CHECK (MaxRacketsPerOrder > 0)
    );
    PRINT N'Đã tạo bảng RacketStringingConfig.';
END
ELSE
    PRINT N'Bảng RacketStringingConfig đã tồn tại, bỏ qua.';
GO

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. ServiceMaterial — vật tư dùng trong dịch vụ (dây cước, quấn cán...). Chỉ phục
--    vụ cấu hình dịch vụ, KHÔNG phải sản phẩm bán lẻ / không quản lý kho chi tiết.
-- ═══════════════════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.ServiceMaterial', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ServiceMaterial (
        MaterialID   INT IDENTITY(1,1) PRIMARY KEY,
        CoSoID       INT NOT NULL,
        Name         NVARCHAR(150) NOT NULL,
        Brand        NVARCHAR(100) NULL,
        Code         NVARCHAR(50)  NULL,
        Color        NVARCHAR(50)  NULL,
        SportType    NVARCHAR(50)  NULL,
        Price        DECIMAL(12,2) NOT NULL CONSTRAINT DF_ServiceMaterial_Price DEFAULT 0,
        ExtraFee     DECIMAL(12,2) NOT NULL CONSTRAINT DF_ServiceMaterial_ExtraFee DEFAULT 0,
        -- DANG_CO, TAM_HET, NGUNG_SU_DUNG (không mô phỏng số lượng tồn chính xác)
        Status       NVARCHAR(20)  NOT NULL CONSTRAINT DF_ServiceMaterial_Status DEFAULT N'DANG_CO',
        Description  NVARCHAR(500) NULL,
        IsDeleted    BIT NOT NULL CONSTRAINT DF_ServiceMaterial_IsDeleted DEFAULT 0,
        CreatedAt    DATETIME2 NOT NULL CONSTRAINT DF_ServiceMaterial_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt    DATETIME2 NOT NULL CONSTRAINT DF_ServiceMaterial_UpdatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_ServiceMaterial_CoSo FOREIGN KEY (CoSoID) REFERENCES dbo.CoSo(CoSoID),
        CONSTRAINT CK_ServiceMaterial_Price CHECK (Price >= 0 AND ExtraFee >= 0),
        CONSTRAINT CK_ServiceMaterial_Status CHECK (Status IN (N'DANG_CO', N'TAM_HET', N'NGUNG_SU_DUNG'))
    );
    CREATE INDEX IX_ServiceMaterial_CoSoID ON dbo.ServiceMaterial (CoSoID);
    PRINT N'Đã tạo bảng ServiceMaterial.';
END
ELSE
    PRINT N'Bảng ServiceMaterial đã tồn tại, bỏ qua.';
GO

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. ServiceOrder — đơn dịch vụ độc lập (không nhồi vào LichDatSan/GhiChu).
--    BookingID nullable: gắn với DatSanID nếu Customer thêm dịch vụ khi đặt sân,
--    nhưng booking và service order có state machine hoàn toàn riêng biệt.
-- ═══════════════════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.ServiceOrder', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ServiceOrder (
        OrderID             INT IDENTITY(1,1) PRIMARY KEY,
        CustomerID          INT NOT NULL,
        CoSoID              INT NOT NULL,
        ServiceID           INT NOT NULL,
        BookingID           INT NULL,
        -- PENDING_CONFIRMATION, CONFIRMED, ITEM_RECEIVED, IN_PROGRESS,
        -- READY_FOR_PICKUP, COMPLETED, CANCELLED, REJECTED
        Status              NVARCHAR(30) NOT NULL CONSTRAINT DF_ServiceOrder_Status DEFAULT N'PENDING_CONFIRMATION',
        RequestedAt         DATETIME2 NOT NULL CONSTRAINT DF_ServiceOrder_RequestedAt DEFAULT SYSUTCDATETIME(),
        AppointmentDate     DATE NOT NULL,
        DropOffTime         NVARCHAR(20) NULL,   -- khung giờ mang đến, vd "08:00-10:00"
        ExpectedPickupTime  DATETIME2 NULL,
        ActualReceivedTime  DATETIME2 NULL,
        CompletedTime       DATETIME2 NULL,
        DeliveredTime       DATETIME2 NULL,
        CancelledTime       DATETIME2 NULL,
        CustomerNote        NVARCHAR(500) NULL,
        ManagerNote         NVARCHAR(500) NULL,
        EstimatedPrice      DECIMAL(12,2) NOT NULL CONSTRAINT DF_ServiceOrder_EstPrice DEFAULT 0,
        ConfirmedPrice      DECIMAL(12,2) NULL,
        CancellationReason  NVARCHAR(500) NULL,
        CreatedAt           DATETIME2 NOT NULL CONSTRAINT DF_ServiceOrder_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt           DATETIME2 NOT NULL CONSTRAINT DF_ServiceOrder_UpdatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_ServiceOrder_Customer FOREIGN KEY (CustomerID) REFERENCES dbo.Accounts(AccountID),
        CONSTRAINT FK_ServiceOrder_CoSo FOREIGN KEY (CoSoID) REFERENCES dbo.CoSo(CoSoID),
        CONSTRAINT FK_ServiceOrder_Service FOREIGN KEY (ServiceID) REFERENCES dbo.SportService(ServiceID),
        CONSTRAINT FK_ServiceOrder_Booking FOREIGN KEY (BookingID) REFERENCES dbo.LichDatSan(DatSanID),
        CONSTRAINT CK_ServiceOrder_Status CHECK (Status IN
            (N'PENDING_CONFIRMATION', N'CONFIRMED', N'ITEM_RECEIVED', N'IN_PROGRESS',
             N'READY_FOR_PICKUP', N'COMPLETED', N'CANCELLED', N'REJECTED')),
        CONSTRAINT CK_ServiceOrder_EstPrice CHECK (EstimatedPrice >= 0),
        CONSTRAINT CK_ServiceOrder_ConfirmedPrice CHECK (ConfirmedPrice IS NULL OR ConfirmedPrice >= 0)
    );
    CREATE INDEX IX_ServiceOrder_CustomerID ON dbo.ServiceOrder (CustomerID);
    CREATE INDEX IX_ServiceOrder_CoSoID ON dbo.ServiceOrder (CoSoID);
    CREATE INDEX IX_ServiceOrder_Status ON dbo.ServiceOrder (Status);
    CREATE INDEX IX_ServiceOrder_BookingID ON dbo.ServiceOrder (BookingID);
    PRINT N'Đã tạo bảng ServiceOrder.';
END
ELSE
    PRINT N'Bảng ServiceOrder đã tồn tại, bỏ qua.';
GO

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. RacketStringingOrderDetail — chi tiết khi ServiceOrder thuộc dịch vụ căng lưới.
-- ═══════════════════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.RacketStringingOrderDetail', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.RacketStringingOrderDetail (
        DetailID          INT IDENTITY(1,1) PRIMARY KEY,
        OrderID           INT NOT NULL,
        RacketType        NVARCHAR(50)  NULL,
        RacketBrand       NVARCHAR(100) NULL,
        RacketModel       NVARCHAR(100) NULL,
        MaterialID        INT NULL,
        CustomerBringsString BIT NOT NULL CONSTRAINT DF_RSOD_CustomerBrings DEFAULT 0,
        TensionValue      DECIMAL(5,2)  NOT NULL,
        TensionUnit       NVARCHAR(5)   NOT NULL CONSTRAINT DF_RSOD_TensionUnit DEFAULT N'kg',
        StringColor       NVARCHAR(50)  NULL,
        Quantity          INT NOT NULL CONSTRAINT DF_RSOD_Quantity DEFAULT 1,
        TechnicalNote     NVARCHAR(500) NULL,
        CONSTRAINT FK_RSOD_Order FOREIGN KEY (OrderID) REFERENCES dbo.ServiceOrder(OrderID),
        CONSTRAINT FK_RSOD_Material FOREIGN KEY (MaterialID) REFERENCES dbo.ServiceMaterial(MaterialID),
        CONSTRAINT UQ_RSOD_OrderID UNIQUE (OrderID),
        CONSTRAINT CK_RSOD_TensionUnit CHECK (TensionUnit IN (N'kg', N'lbs')),
        CONSTRAINT CK_RSOD_Tension CHECK (TensionValue > 0),
        CONSTRAINT CK_RSOD_Quantity CHECK (Quantity > 0)
    );
    PRINT N'Đã tạo bảng RacketStringingOrderDetail.';
END
ELSE
    PRINT N'Bảng RacketStringingOrderDetail đã tồn tại, bỏ qua.';
GO

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. ServiceOrderStatusHistory — timeline nghiệp vụ (khác AuditLog, xem PHẦN 22).
-- ═══════════════════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.ServiceOrderStatusHistory', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ServiceOrderStatusHistory (
        HistoryID    INT IDENTITY(1,1) PRIMARY KEY,
        OrderID      INT NOT NULL,
        FromStatus   NVARCHAR(30) NULL,
        ToStatus     NVARCHAR(30) NOT NULL,
        ChangedBy    INT NULL,
        ChangedAt    DATETIME2 NOT NULL CONSTRAINT DF_SOSH_ChangedAt DEFAULT SYSUTCDATETIME(),
        Note         NVARCHAR(500) NULL,
        CONSTRAINT FK_SOSH_Order FOREIGN KEY (OrderID) REFERENCES dbo.ServiceOrder(OrderID),
        CONSTRAINT FK_SOSH_ChangedBy FOREIGN KEY (ChangedBy) REFERENCES dbo.Accounts(AccountID)
    );
    CREATE INDEX IX_SOSH_OrderID ON dbo.ServiceOrderStatusHistory (OrderID);
    PRINT N'Đã tạo bảng ServiceOrderStatusHistory.';
END
ELSE
    PRINT N'Bảng ServiceOrderStatusHistory đã tồn tại, bỏ qua.';
GO

-- Rollback (thủ công, chỉ chạy nếu cần gỡ migration này và chưa có dữ liệu quan trọng):
--   DROP TABLE dbo.ServiceOrderStatusHistory;
--   DROP TABLE dbo.RacketStringingOrderDetail;
--   DROP TABLE dbo.ServiceOrder;
--   DROP TABLE dbo.ServiceMaterial;
--   DROP TABLE dbo.RacketStringingConfig;
--   DROP TABLE dbo.SportService;
