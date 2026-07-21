# Cancel Booking + Customer Reputation Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hard 6-hour cancel block with a soft policy — customers can always cancel, but a cancel inside the 6-hour window is recorded as a Late Cancel and docks reputation; staff/manager No Show marking already exists and gets the same reputation treatment; Manager/Staff UI surfaces the customer's reputation.

**Architecture:** Two new pure-logic decision classes (`CancelDecision`, `ReputationLabel` — no DB, fast-unit-testable) feed two DB-touching services (`CustomerReputationService` for the score ledger, `BookingCancellationService` for customer-initiated cancel). The existing no-show path (`CheckInDAO.huyLichKhachBung`) and the existing checkout-completion path (`CheckoutService.completeBookingAndReleaseCourtIfNeeded`) are extended in place to call `CustomerReputationService` inside their existing transactions. `AuditLogService` (already built) gets three new action constants and is called from every mutating path. All idempotency is achieved by making the reputation/history mutation conditional on the *same* atomic `UPDATE ... WHERE <status guard>` that flips the booking status — if that UPDATE affects 0 rows (already cancelled / already no-show / double-click / retry), nothing else runs.

**Tech Stack:** Java 17, Jakarta Servlet, raw JDBC (`DBUtil`/HikariCP) against SQL Server, JSP/JSTL/EL + Tailwind-style utility classes, JUnit 5.

## Global Constraints

- Do not change architecture: stay in Servlet/DAO/Service/JSP, no Spring Boot, no new frameworks.
- Do not hard-code test data into production code paths.
- Do not commit secrets — this plan touches no `.env`/credential files. (Separately: `.env.example` in the repo root currently appears to contain live, non-placeholder credentials — flagged to the user, out of scope for this plan, do not touch it here.)
- Every SQL migration in `/sql` must be idempotent: guard every `ALTER TABLE`/`CREATE TABLE` with an existence check, never `DROP`/`TRUNCATE`, never blanket `UPDATE` production data without a `WHERE` that only touches rows that need a default backfilled.
- Never delete a customer's phone number or hard-delete a booking. Reputation is tracked via `Accounts.DiemUyTin` (already exists) + new counters + new `CustomerReputationHistory` ledger — never by erasing customer data.
- IDOR guard: a customer may only cancel their own booking (`AccountID` match). CoSoID guard: staff/manager may only act on bookings whose court belongs to their own `CoSoID` (mirror the existing `SecurityException` → HTTP 403 pattern used throughout the DAO layer).
- Idempotency: every status-changing UPDATE must be a single atomic `UPDATE ... WHERE <current-status guard>`; the reputation/history/audit side-effects only fire when that UPDATE's row count is 1. A second click / retried request / second tab must see row count 0 and get an "already done" message, not a duplicate penalty.
- No automatic refunds. Where money has already moved (paid/deposited invoice) at No-Show or Late Cancel time, only flag `RequiresRefundReview = 1` and leave a note — never flip an invoice to "Đã hủy" automatically when it was already paid.
- Do not touch PayOS webhook logic, check-in payment logic, or checkout pricing logic beyond the single new hook point specified in Task 12.
- Constants belong in `Constants.java` — no new magic numbers/strings scattered across services/servlets.

---

## Task 1: Add cancellation/reputation constants to `Constants.java`

**Files:**
- Modify: `src/main/java/org/example/util/Constants.java`

**Interfaces:**
- Produces: `Constants.LATE_CANCEL_HOURS`, `Constants.LATE_CANCEL_PENALTY`, `Constants.NO_SHOW_PENALTY`, `Constants.COMPLETED_BOOKING_REWARD`, `Constants.MAX_REPUTATION_SCORE`, `Constants.MIN_REPUTATION_SCORE`, `Constants.REPUTATION_GOOD_THRESHOLD`, `Constants.REPUTATION_WATCH_THRESHOLD`, `Constants.CANCEL_TYPE_EARLY`, `Constants.CANCEL_TYPE_LATE`, `Constants.REPUTATION_ACTION_EARLY_CANCEL`, `Constants.REPUTATION_ACTION_LATE_CANCEL`, `Constants.REPUTATION_ACTION_NO_SHOW`, `Constants.REPUTATION_ACTION_COMPLETED_BOOKING`, `Constants.REPUTATION_ACTION_MANUAL_ADJUST`, `Constants.REPUTATION_LABEL_GOOD`, `Constants.REPUTATION_LABEL_WATCH`, `Constants.REPUTATION_LABEL_RISK` — every later task in this plan consumes these by name, do not rename.

This is a pure additive change (no existing behavior touched), so there is no test to write for this task — it's config. Do the edit, then verify it compiles as part of Task 1's own step.

- [ ] **Step 1: Add the new constants block**

Insert immediately after the existing `TRANG_THAI_DAT_SAN_DANG_SU_DUNG` line (Constants.java:29), before the `// ========== TIMEOUT ==========` block:

```java
    // ========== BOOKING CANCELLATION / REPUTATION (Điểm uy tín khách hàng) ==========
    // Ngưỡng phân loại hủy sớm/hủy sát giờ. Nếu đổi số này, đồng thời phải cập nhật
    // sql/migration_customer_reputation_cancel_flow.sql (không có cách nào để SQL đọc hằng số Java).
    public static final int LATE_CANCEL_HOURS = 6;
    public static final int LATE_CANCEL_PENALTY = -10;
    public static final int NO_SHOW_PENALTY = -20;
    public static final int COMPLETED_BOOKING_REWARD = 2;
    public static final int MAX_REPUTATION_SCORE = 100;
    public static final int MIN_REPUTATION_SCORE = 0;
    // Ngưỡng hiển thị nhãn uy tín cho Manager/Staff — dùng lại ở JSP dưới dạng số literal
    // (JSTL EL không gọi được hằng số Java), phải giữ đồng bộ nếu đổi ở đây:
    // - >= REPUTATION_GOOD_THRESHOLD (80): "Uy tín tốt"
    // - >= REPUTATION_WATCH_THRESHOLD (50) và < 80: "Cần theo dõi"
    // - < REPUTATION_WATCH_THRESHOLD (50): "Rủi ro cao"
    public static final int REPUTATION_GOOD_THRESHOLD = 80;
    public static final int REPUTATION_WATCH_THRESHOLD = 50;

    public static final String CANCEL_TYPE_EARLY = "EARLY_CANCEL";
    public static final String CANCEL_TYPE_LATE = "LATE_CANCEL";

    // Giá trị ActionType lưu trong CustomerReputationHistory.ActionType
    public static final String REPUTATION_ACTION_EARLY_CANCEL = "EARLY_CANCEL";
    public static final String REPUTATION_ACTION_LATE_CANCEL = "LATE_CANCEL";
    public static final String REPUTATION_ACTION_NO_SHOW = "NO_SHOW";
    public static final String REPUTATION_ACTION_COMPLETED_BOOKING = "COMPLETED_BOOKING";
    public static final String REPUTATION_ACTION_MANUAL_ADJUST = "MANUAL_ADJUST";

    public static final String REPUTATION_LABEL_GOOD = "Uy tín tốt";
    public static final String REPUTATION_LABEL_WATCH = "Cần theo dõi";
    public static final String REPUTATION_LABEL_RISK = "Rủi ro cao";

```

- [ ] **Step 2: Compile to verify no syntax errors**

Run: `mvn -q compile`
Expected: `BUILD SUCCESS`

- [ ] **Step 3: Commit**

```bash
git add src/main/java/org/example/util/Constants.java
git commit -m "feat: add cancellation/reputation constants"
```

---

## Task 2: Extend `AuditLogService` with new action/entity constants and a public IP helper

**Files:**
- Modify: `src/main/java/org/example/service/AuditLogService.java`

**Interfaces:**
- Produces: `AuditLogService.ACTION_CANCEL`, `AuditLogService.ACTION_NO_SHOW`, `AuditLogService.ACTION_REPUTATION_ADJUST`, `AuditLogService.ENTITY_DAT_SAN`, `AuditLogService.ENTITY_REPUTATION`, and `public static String getClientIp(HttpServletRequest req)` (currently `private`).
- Consumes: nothing new.

No new test — this class already has no unit tests (it's a thin DB-writing wrapper) and this change is additive plus one visibility change.

- [ ] **Step 1: Add action/entity constants**

In `AuditLogService.java`, after line 44 (`public static final String ACTION_REJECT = "REJECT";`), add:

```java
    public static final String ACTION_CANCEL             = "CANCEL";
    public static final String ACTION_NO_SHOW             = "NO_SHOW";
    public static final String ACTION_REPUTATION_ADJUST   = "REPUTATION_ADJUST";
```

After line 54 (`public static final String ENTITY_YEU_CAU_NGHI = "YeuCauNghi";`), add:

```java
    public static final String ENTITY_DAT_SAN    = "LichDatSan";
    public static final String ENTITY_REPUTATION = "CustomerReputation";
```

- [ ] **Step 2: Make `getClientIp` public**

Change (currently around line 127):
```java
    private static String getClientIp(HttpServletRequest req) {
```
to:
```java
    public static String getClientIp(HttpServletRequest req) {
```

This is needed because `BookingCancellationService` (Task 10) needs the same IP-extraction logic for `CustomerReputationHistory.IpAddress`, and duplicating the `X-Forwarded-For` parsing would violate the "no duplicate logic" requirement.

- [ ] **Step 3: Compile**

Run: `mvn -q compile`
Expected: `BUILD SUCCESS`

- [ ] **Step 4: Commit**

```bash
git add src/main/java/org/example/service/AuditLogService.java
git commit -m "feat: add cancel/no-show/reputation audit constants, expose getClientIp"
```

---

## Task 3: Idempotent SQL migration

**Files:**
- Create: `sql/migration_customer_reputation_cancel_flow.sql`

**Interfaces:**
- Produces DB columns: `Accounts.LateCancelCount`, `Accounts.NoShowCount`, `Accounts.CompletedBookingCount` (all `INT NOT NULL DEFAULT 0`); `LichDatSan.CancelType`, `LichDatSan.CancelReason`, `LichDatSan.CancelledAt`, `LichDatSan.CancelledBy`, `LichDatSan.RequiresRefundReview`; new table `CustomerReputationHistory`.
- Reuses without duplicating: `Accounts.DiemUyTin` (already exists, default 100 — this **is** ReputationScore, do not add a second score column), `LichDatSan.NoShowAt` (already exists from `migration_reservation_hold.sql`), `LichDatSan.HoldExpiresAt` (already exists, used to gate "Chờ thanh toán" cancels).

Follow the exact idempotent style already used in `sql/migration_reservation_hold.sql` (`IF NOT EXISTS (SELECT 1 FROM sys.columns ...) BEGIN ALTER TABLE ... ADD ... END`).

- [ ] **Step 1: Write the migration file**

```sql
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
```

- [ ] **Step 2: Ask the user to review before running against any real DB**

Do NOT execute this file against the remote DB yourself. State clearly to the user: "Migration written to `sql/migration_customer_reputation_cancel_flow.sql`. Please review and run it yourself against your DB (e.g. via SSMS or `sqlcmd`) — I will not run migrations against a remote database." Move to the next task without running it.

- [ ] **Step 3: Commit**

```bash
git add sql/migration_customer_reputation_cancel_flow.sql
git commit -m "feat: add idempotent migration for cancel flow + reputation ledger"
```

---

## Task 4: Model updates — `TaiKhoan`, `Lichdatsan`, new `CustomerReputationHistory`

**Files:**
- Modify: `src/main/java/org/example/model/TaiKhoan.java`
- Modify: `src/main/java/org/example/model/Lichdatsan.java`
- Create: `src/main/java/org/example/model/CustomerReputationHistory.java`

**Interfaces:**
- Produces: `TaiKhoan.getLateCancelCount()/setLateCancelCount(int)`, `getNoShowCount()/setNoShowCount(int)`, `getCompletedBookingCount()/setCompletedBookingCount(int)`; `Lichdatsan.getCancelType()/setCancelType(String)`, `getCancelReason()/setCancelReason(String)`, `getCancelledAt()/setCancelledAt(LocalDateTime)`, `getCancelledBy()/setCancelledBy(Integer)`, `getRequiresRefundReview()/setRequiresRefundReview(boolean)`; new `CustomerReputationHistory` POJO with getters/setters for every migration column.
- Consumes: nothing (pure data classes).

No unit test for these — plain POJOs mirroring the existing `TaiKhoan`/`Lichdatsan`/`AuditLog` style (JPA annotations present for documentation/consistency even though this codebase reads/writes them via raw JDBC).

- [ ] **Step 1: Add reputation counters to `TaiKhoan.java`**

After line 68 (`private int diemTrinhDo = 1000;`), add:

```java
    @Column(name = "LateCancelCount", columnDefinition = "int default 0")
    private int lateCancelCount = 0;

    @Column(name = "NoShowCount", columnDefinition = "int default 0")
    private int noShowCount = 0;

    @Column(name = "CompletedBookingCount", columnDefinition = "int default 0")
    private int completedBookingCount = 0;
```

After the existing `getDiemTrinhDo`/`setDiemTrinhDo` methods (around line 328), add:

```java
    public int getLateCancelCount() {
        return lateCancelCount;
    }

    public void setLateCancelCount(int lateCancelCount) {
        this.lateCancelCount = lateCancelCount;
    }

    public int getNoShowCount() {
        return noShowCount;
    }

    public void setNoShowCount(int noShowCount) {
        this.noShowCount = noShowCount;
    }

    public int getCompletedBookingCount() {
        return completedBookingCount;
    }

    public void setCompletedBookingCount(int completedBookingCount) {
        this.completedBookingCount = completedBookingCount;
    }
```

- [ ] **Step 2: Add cancel/refund fields to `Lichdatsan.java`**

After line 108 (`private LocalDateTime noShowAt;`), add:

```java
    @Column(name = "CancelType", length = 20)
    private String cancelType;

    @Column(name = "CancelReason", length = 255)
    private String cancelReason;

    @Column(name = "CancelledAt")
    private LocalDateTime cancelledAt;

    @Column(name = "CancelledBy")
    private Integer cancelledBy;

    @Column(name = "RequiresRefundReview")
    private boolean requiresRefundReview;
```

After the existing `getNoShowAt`/`setNoShowAt` methods (around line 377), add:

```java
    public String getCancelType() {
        return cancelType;
    }

    public void setCancelType(String cancelType) {
        this.cancelType = cancelType;
    }

    public String getCancelReason() {
        return cancelReason;
    }

    public void setCancelReason(String cancelReason) {
        this.cancelReason = cancelReason;
    }

    public LocalDateTime getCancelledAt() {
        return cancelledAt;
    }

    public void setCancelledAt(LocalDateTime cancelledAt) {
        this.cancelledAt = cancelledAt;
    }

    public Integer getCancelledBy() {
        return cancelledBy;
    }

    public void setCancelledBy(Integer cancelledBy) {
        this.cancelledBy = cancelledBy;
    }

    public boolean getRequiresRefundReview() {
        return requiresRefundReview;
    }

    public void setRequiresRefundReview(boolean requiresRefundReview) {
        this.requiresRefundReview = requiresRefundReview;
    }
```

- [ ] **Step 3: Create `CustomerReputationHistory.java`**

```java
package org.example.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "CustomerReputationHistory")
public class CustomerReputationHistory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ReputationHistoryID")
    private long reputationHistoryId;

    @Column(name = "AccountID")
    private int accountId;

    @Column(name = "DatSanID")
    private Integer datSanId;

    @Column(name = "ActionType", length = 30)
    private String actionType;

    @Column(name = "ScoreDelta")
    private int scoreDelta;

    @Column(name = "ScoreBefore")
    private int scoreBefore;

    @Column(name = "ScoreAfter")
    private int scoreAfter;

    @Column(name = "Reason", length = 255)
    private String reason;

    @Column(name = "CreatedAt", insertable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "CreatedBy")
    private Integer createdBy;

    @Column(name = "IpAddress", length = 50)
    private String ipAddress;

    public long getReputationHistoryId() { return reputationHistoryId; }
    public void setReputationHistoryId(long reputationHistoryId) { this.reputationHistoryId = reputationHistoryId; }

    public int getAccountId() { return accountId; }
    public void setAccountId(int accountId) { this.accountId = accountId; }

    public Integer getDatSanId() { return datSanId; }
    public void setDatSanId(Integer datSanId) { this.datSanId = datSanId; }

    public String getActionType() { return actionType; }
    public void setActionType(String actionType) { this.actionType = actionType; }

    public int getScoreDelta() { return scoreDelta; }
    public void setScoreDelta(int scoreDelta) { this.scoreDelta = scoreDelta; }

    public int getScoreBefore() { return scoreBefore; }
    public void setScoreBefore(int scoreBefore) { this.scoreBefore = scoreBefore; }

    public int getScoreAfter() { return scoreAfter; }
    public void setScoreAfter(int scoreAfter) { this.scoreAfter = scoreAfter; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public Integer getCreatedBy() { return createdBy; }
    public void setCreatedBy(Integer createdBy) { this.createdBy = createdBy; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }
}
```

- [ ] **Step 4: Compile**

Run: `mvn -q compile`
Expected: `BUILD SUCCESS`

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/model/TaiKhoan.java src/main/java/org/example/model/Lichdatsan.java src/main/java/org/example/model/CustomerReputationHistory.java
git commit -m "feat: add cancel/refund/reputation fields to booking and account models"
```

---

## Task 5: Pure logic — `ReputationLabel` (unit tested, no DB)

**Files:**
- Create: `src/main/java/org/example/service/reputation/ReputationLabel.java`
- Test: `src/test/java/org/example/service/reputation/ReputationLabelTest.java`

**Interfaces:**
- Consumes: `Constants.REPUTATION_GOOD_THRESHOLD`, `Constants.REPUTATION_WATCH_THRESHOLD`, `Constants.REPUTATION_LABEL_GOOD/WATCH/RISK` (Task 1).
- Produces: `static String ReputationLabel.of(int score)` — used by Task 9 (DAO mapper) and Task 12 (staff DTO).

This mirrors the existing `NoShowEligibility`/`CheckInWindow` pattern: a pure static-logic class with a matching fast unit test, no DB.

- [ ] **Step 1: Write the failing test**

```java
package org.example.service.reputation;

import org.example.util.Constants;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ReputationLabelTest {

    @Test
    void score100IsGood() {
        assertEquals(Constants.REPUTATION_LABEL_GOOD, ReputationLabel.of(100));
    }

    @Test
    void scoreAtGoodThresholdIsGood() {
        assertEquals(Constants.REPUTATION_LABEL_GOOD, ReputationLabel.of(80));
    }

    @Test
    void scoreJustBelowGoodThresholdIsWatch() {
        assertEquals(Constants.REPUTATION_LABEL_WATCH, ReputationLabel.of(79));
    }

    @Test
    void scoreAtWatchThresholdIsWatch() {
        assertEquals(Constants.REPUTATION_LABEL_WATCH, ReputationLabel.of(50));
    }

    @Test
    void scoreJustBelowWatchThresholdIsRisk() {
        assertEquals(Constants.REPUTATION_LABEL_RISK, ReputationLabel.of(49));
    }

    @Test
    void score0IsRisk() {
        assertEquals(Constants.REPUTATION_LABEL_RISK, ReputationLabel.of(0));
    }
}
```

- [ ] **Step 2: Run test to verify it fails (class doesn't exist yet)**

Run: `mvn -q test -Dtest=ReputationLabelTest`
Expected: compile error — `cannot find symbol: class ReputationLabel`

- [ ] **Step 3: Implement `ReputationLabel`**

```java
package org.example.service.reputation;

import org.example.util.Constants;

/**
 * Nhãn hiển thị điểm uy tín cho Manager/Staff (mục 3 spec: 80-100 Uy tín tốt,
 * 50-79 Cần theo dõi, dưới 50 Rủi ro cao). Logic thuần, không đụng DB.
 */
public final class ReputationLabel {

    private ReputationLabel() {
    }

    public static String of(int score) {
        if (score >= Constants.REPUTATION_GOOD_THRESHOLD) {
            return Constants.REPUTATION_LABEL_GOOD;
        }
        if (score >= Constants.REPUTATION_WATCH_THRESHOLD) {
            return Constants.REPUTATION_LABEL_WATCH;
        }
        return Constants.REPUTATION_LABEL_RISK;
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mvn -q test -Dtest=ReputationLabelTest`
Expected: `Tests run: 6, Failures: 0, Errors: 0`

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/service/reputation/ReputationLabel.java src/test/java/org/example/service/reputation/ReputationLabelTest.java
git commit -m "feat: add ReputationLabel pure logic + tests"
```

---

## Task 6: Pure logic — `CancelDecision` (unit tested, no DB)

**Files:**
- Create: `src/main/java/org/example/service/booking/CancelDecision.java`
- Test: `src/test/java/org/example/service/booking/CancelDecisionTest.java`

**Interfaces:**
- Consumes: nothing (takes `lateCancelHours` as a parameter so the test doesn't depend on `Constants`).
- Produces: `CancelDecision.CancelType` enum (`EARLY_CANCEL`, `LATE_CANCEL`) and `static CancelType CancelDecision.decide(LocalDateTime now, LocalDateTime bookingStart, int lateCancelHours)` — used by Task 10 (`BookingCancellationService`).

Exact boundary semantics (must match spec section 2 precisely): "còn trên 6 tiếng" → EARLY; "còn dưới hoặc bằng 6 tiếng" → LATE. So at *exactly* 6 hours remaining, the decision is LATE (not EARLY) — this is the one edge case the test must pin down.

- [ ] **Step 1: Write the failing test**

```java
package org.example.service.booking;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.example.service.booking.CancelDecision.CancelType.EARLY_CANCEL;
import static org.example.service.booking.CancelDecision.CancelType.LATE_CANCEL;
import static org.junit.jupiter.api.Assertions.assertEquals;

class CancelDecisionTest {

    private static final LocalDateTime START = LocalDateTime.of(2026, 7, 20, 18, 0);

    @Test
    void moreThanThresholdHoursRemaining_isEarly() {
        LocalDateTime now = START.minusHours(7);
        assertEquals(EARLY_CANCEL, CancelDecision.decide(now, START, 6));
    }

    @Test
    void exactlyThresholdHoursRemaining_isLate() {
        LocalDateTime now = START.minusHours(6);
        assertEquals(LATE_CANCEL, CancelDecision.decide(now, START, 6));
    }

    @Test
    void oneMinuteInsideThreshold_isLate() {
        LocalDateTime now = START.minusHours(6).plusMinutes(1);
        assertEquals(LATE_CANCEL, CancelDecision.decide(now, START, 6));
    }

    @Test
    void oneMinuteOutsideThreshold_isEarly() {
        LocalDateTime now = START.minusHours(6).minusMinutes(1);
        assertEquals(EARLY_CANCEL, CancelDecision.decide(now, START, 6));
    }

    @Test
    void afterBookingStart_isLate() {
        LocalDateTime now = START.plusHours(1);
        assertEquals(LATE_CANCEL, CancelDecision.decide(now, START, 6));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn -q test -Dtest=CancelDecisionTest`
Expected: compile error — `cannot find symbol: class CancelDecision`

- [ ] **Step 3: Implement `CancelDecision`**

```java
package org.example.service.booking;

import java.time.LocalDateTime;

/**
 * Phân loại hủy sớm/hủy sát giờ (mục 2 spec). Logic thuần, không đụng DB —
 * BookingCancellationService gọi lớp này rồi mới ghi DB.
 */
public final class CancelDecision {

    private CancelDecision() {
    }

    public enum CancelType {
        EARLY_CANCEL,
        LATE_CANCEL
    }

    /**
     * "Còn dưới hoặc bằng lateCancelHours tiếng" => LATE_CANCEL (biên đúng bằng ngưỡng tính là hủy sát giờ).
     */
    public static CancelType decide(LocalDateTime now, LocalDateTime bookingStart, int lateCancelHours) {
        boolean isLate = !now.plusHours(lateCancelHours).isBefore(bookingStart);
        return isLate ? CancelType.LATE_CANCEL : CancelType.EARLY_CANCEL;
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mvn -q test -Dtest=CancelDecisionTest`
Expected: `Tests run: 5, Failures: 0, Errors: 0`

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/service/booking/CancelDecision.java src/test/java/org/example/service/booking/CancelDecisionTest.java
git commit -m "feat: add CancelDecision pure logic + boundary tests"
```

---

## Task 7: `CustomerReputationService` — the reputation ledger (DB-touching)

**Files:**
- Create: `src/main/java/org/example/service/reputation/CustomerReputationService.java`
- Test: `src/test/java/org/example/service/reputation/CustomerReputationServiceClampTest.java`

**Interfaces:**
- Consumes: `Constants.MIN_REPUTATION_SCORE`, `Constants.MAX_REPUTATION_SCORE`, `Constants.REPUTATION_ACTION_LATE_CANCEL/NO_SHOW/COMPLETED_BOOKING` (Task 1).
- Produces: `static int CustomerReputationService.clamp(int scoreBefore, int delta)` (pure, unit-testable) and `static int CustomerReputationService.applyDelta(Connection conn, int accountId, Integer datSanId, String actionType, int scoreDelta, String reason, Integer actorId, String ipAddress) throws SQLException` — used by Task 10 (customer cancel), Task 11 (no-show), Task 13 (completed booking). **Caller-owned transaction**: this method does not call `commit()`/`rollback()`/`setAutoCommit()` — it must run inside a transaction the caller already opened, so that the booking-status UPDATE and the reputation UPDATE either both commit or both roll back together (this is what makes double-click/idempotency work: if the caller's own status-guard UPDATE affected 0 rows, the caller never calls `applyDelta` at all).

Only `clamp()` is DB-free and gets a real unit test. `applyDelta()` itself needs a live SQL Server connection to test end-to-end — that part is **not** unit-tested here (no H2/embedded DB in this repo, and the remote dev DB must not be touched per constraints); it's covered by the manual test checklist in Task 18 instead. State this explicitly rather than faking a test.

- [ ] **Step 1: Write the failing test for the pure clamp logic**

```java
package org.example.service.reputation;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class CustomerReputationServiceClampTest {

    @Test
    void penaltyClampsAtMinimum() {
        assertEquals(0, CustomerReputationService.clamp(5, -20));
    }

    @Test
    void rewardClampsAtMaximum() {
        assertEquals(100, CustomerReputationService.clamp(99, 2));
    }

    @Test
    void normalDeltaIsUnclamped() {
        assertEquals(90, CustomerReputationService.clamp(100, -10));
    }

    @Test
    void exactlyAtFloorStaysAtFloor() {
        assertEquals(0, CustomerReputationService.clamp(0, -20));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn -q test -Dtest=CustomerReputationServiceClampTest`
Expected: compile error — `cannot find symbol: class CustomerReputationService`

- [ ] **Step 3: Implement `CustomerReputationService`**

```java
package org.example.service.reputation;

import org.example.util.Constants;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

/**
 * Sổ cái điểm uy tín khách hàng (mục 3, 12 spec). Mọi thay đổi DiemUyTin PHẢI đi qua đây
 * để không có nguồn tính điểm thứ hai rải rác ở các Servlet khác nhau.
 *
 * Quan trọng: applyDelta() KHÔNG tự quản lý transaction (không gọi commit/rollback/setAutoCommit) -
 * caller phải mở sẵn Connection ở chế độ transaction thủ công và tự commit/rollback. Điều này đảm bảo
 * tính idempotent: caller chỉ gọi applyDelta() SAU KHI UPDATE trạng thái booking (với WHERE guard trạng
 * thái nguồn) đã ảnh hưởng đúng 1 dòng - double-click/retry sẽ thấy 0 dòng và không bao giờ gọi tới đây.
 */
public final class CustomerReputationService {

    private static final Logger logger = LogManager.getLogger(CustomerReputationService.class);

    private CustomerReputationService() {
    }

    /** Logic thuần: cộng delta vào điểm hiện tại rồi kẹp trong [MIN_REPUTATION_SCORE, MAX_REPUTATION_SCORE]. */
    public static int clamp(int scoreBefore, int delta) {
        int raw = scoreBefore + delta;
        return Math.max(Constants.MIN_REPUTATION_SCORE, Math.min(Constants.MAX_REPUTATION_SCORE, raw));
    }

    /**
     * Áp dụng một thay đổi điểm uy tín + ghi lịch sử, trong transaction của caller.
     *
     * @param conn       Connection đã mở transaction (autoCommit=false) - KHÔNG commit/rollback ở đây.
     * @param accountId  Tài khoản khách hàng bị/được thay đổi điểm.
     * @param datSanId   Booking liên quan (nullable - null cho MANUAL_ADJUST không gắn với booking cụ thể).
     * @param actionType Constants.REPUTATION_ACTION_* - dùng để tăng đúng bộ đếm (LateCancelCount/NoShowCount/CompletedBookingCount).
     * @param scoreDelta Số điểm cộng/trừ (âm = trừ).
     * @param reason     Lý do hiển thị trong lịch sử (vd "Khách hủy sát giờ").
     * @param actorId    Người thực hiện (khách tự hủy = accountId của khách; staff no-show = accountId nhân viên; null nếu hệ thống).
     * @param ipAddress  IP của actor nếu có (nullable).
     * @return Điểm uy tín sau khi áp dụng (đã kẹp).
     */
    public static int applyDelta(Connection conn, int accountId, Integer datSanId, String actionType,
                                  int scoreDelta, String reason, Integer actorId, String ipAddress) throws SQLException {
        int scoreBefore;
        try (PreparedStatement lock = conn.prepareStatement(
                "SELECT DiemUyTin FROM Accounts WITH (UPDLOCK, ROWLOCK) WHERE AccountID = ?")) {
            lock.setInt(1, accountId);
            try (ResultSet rs = lock.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException("Không tìm thấy tài khoản khách hàng AccountID=" + accountId);
                }
                scoreBefore = rs.getInt("DiemUyTin");
            }
        }

        int scoreAfter = clamp(scoreBefore, scoreDelta);

        String counterColumn = counterColumnFor(actionType);
        String updateSql = counterColumn != null
                ? "UPDATE Accounts SET DiemUyTin = ?, " + counterColumn + " = " + counterColumn + " + 1 WHERE AccountID = ?"
                : "UPDATE Accounts SET DiemUyTin = ? WHERE AccountID = ?";
        try (PreparedStatement update = conn.prepareStatement(updateSql)) {
            update.setInt(1, scoreAfter);
            update.setInt(2, accountId);
            update.executeUpdate();
        }

        try (PreparedStatement insert = conn.prepareStatement(
                "INSERT INTO CustomerReputationHistory " +
                "(AccountID, DatSanID, ActionType, ScoreDelta, ScoreBefore, ScoreAfter, Reason, CreatedBy, IpAddress) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")) {
            insert.setInt(1, accountId);
            if (datSanId != null) {
                insert.setInt(2, datSanId);
            } else {
                insert.setNull(2, Types.INTEGER);
            }
            insert.setString(3, actionType);
            insert.setInt(4, scoreDelta);
            insert.setInt(5, scoreBefore);
            insert.setInt(6, scoreAfter);
            insert.setString(7, reason);
            if (actorId != null) {
                insert.setInt(8, actorId);
            } else {
                insert.setNull(8, Types.INTEGER);
            }
            insert.setString(9, ipAddress);
            insert.executeUpdate();
        }

        logger.info("Reputation adjust: AccountID={}, action={}, delta={}, before={}, after={}",
                accountId, actionType, scoreDelta, scoreBefore, scoreAfter);
        return scoreAfter;
    }

    private static String counterColumnFor(String actionType) {
        if (Constants.REPUTATION_ACTION_LATE_CANCEL.equals(actionType)) {
            return "LateCancelCount";
        }
        if (Constants.REPUTATION_ACTION_NO_SHOW.equals(actionType)) {
            return "NoShowCount";
        }
        if (Constants.REPUTATION_ACTION_COMPLETED_BOOKING.equals(actionType)) {
            return "CompletedBookingCount";
        }
        return null;
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mvn -q test -Dtest=CustomerReputationServiceClampTest`
Expected: `Tests run: 4, Failures: 0, Errors: 0`

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/service/reputation/CustomerReputationService.java src/test/java/org/example/service/reputation/CustomerReputationServiceClampTest.java
git commit -m "feat: add CustomerReputationService ledger with clamp unit test"
```

---

## Task 8: `LichDatSanDAO`/`Impl` — atomic customer-cancel update + mapper fixes

**Files:**
- Modify: `src/main/java/org/example/dao/LichDatSanDAO.java`
- Modify: `src/main/java/org/example/dao/impl/LichDatSanDAOImpl.java`

**Interfaces:**
- Consumes: nothing new.
- Produces: `int LichDatSanDAO.cancelByCustomer(Connection conn, int datSanId, int accountId, String cancelType, String cancelReason) throws SQLException` — used by Task 10. Also fixes `mapResultSetToLichDatSan` to populate `holdExpiresAt` (existing model field, **never previously mapped** — found during investigation; needed so `BookingCancellationService` can correctly gate "Chờ thanh toán" cancels on hold expiry) and the five new columns from Task 4, plus extends the account-join block to carry `DiemUyTin`/`LateCancelCount`/`NoShowCount` onto the nested `TaiKhoan` for Manager/Staff display (Task 14).

No new unit test — this is a raw-JDBC DAO method against SQL Server; correctness is covered by the manual test checklist (Task 18) since there's no embedded DB in this repo.

- [ ] **Step 1: Add the method to the `LichDatSanDAO` interface**

In `src/main/java/org/example/dao/LichDatSanDAO.java`, add this import at the top if not already present (`java.sql.Connection`, `java.sql.SQLException`), then add near `updateTrangThai`:

```java
    /**
     * Hủy booking do khách tự thao tác — atomic UPDATE với WHERE guard trạng thái nguồn để
     * chống double-click/retry (0 dòng ảnh hưởng nghĩa là đã hủy/đổi trạng thái từ trước, KHÔNG
     * phải lỗi). Chỉ cho phép hủy từ: Chờ xác nhận, Đã xác nhận, hoặc Chờ thanh toán còn hạn giữ chỗ.
     * @return số dòng bị ảnh hưởng (0 hoặc 1).
     */
    boolean cancelByCustomerAvailable(); // placeholder removed below — see actual signature

```

Replace that placeholder block — do not keep it — with the real signature:

```java
    int cancelByCustomer(java.sql.Connection conn, int datSanId, int accountId, String cancelType, String cancelReason) throws java.sql.SQLException;
```

- [ ] **Step 2: Implement it in `LichDatSanDAOImpl.java`**

Add after `updateTrangThai` (after line 183):

```java
    @Override
    public int cancelByCustomer(Connection conn, int datSanId, int accountId, String cancelType, String cancelReason) throws SQLException {
        String sql = "UPDATE LichDatSan SET TrangThai = N'Đã hủy', CancelType = ?, CancelReason = ?, " +
                "CancelledAt = GETDATE(), CancelledBy = ? " +
                "WHERE DatSanID = ? AND AccountID = ? AND (" +
                "TrangThai = N'Chờ xác nhận' " +
                "OR TrangThai = N'Đã xác nhận' " +
                "OR (TrangThai = N'Chờ thanh toán' AND (HoldExpiresAt IS NULL OR HoldExpiresAt > GETDATE())))";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cancelType);
            ps.setString(2, cancelReason);
            ps.setInt(3, accountId);
            ps.setInt(4, datSanId);
            ps.setInt(5, accountId);
            return ps.executeUpdate();
        }
    }
```

- [ ] **Step 3: Fix the mapper to populate `holdExpiresAt` and the new columns**

In `mapResultSetToLichDatSan` (starts at line 281), inside the existing try-block that reads `TimeMode`/`ReservedDurationMinutes` (lines 314-335), add right before the closing `} catch (SQLException e) {` of that block:

```java
            java.sql.Timestamp holdExpiresTs = rs.getTimestamp("HoldExpiresAt");
            if (holdExpiresTs != null) {
                lich.setHoldExpiresAt(holdExpiresTs.toLocalDateTime());
            }
```

Add a new try-block right after that one (before the `FullName`/account try-block at line 350) for the new cancel/refund columns, guarded the same way since not every `SELECT` includes them yet everywhere in the file:

```java
        try {
            lich.setCancelType(rs.getNString("CancelType"));
            lich.setCancelReason(rs.getNString("CancelReason"));
            java.sql.Timestamp cancelledAtTs = rs.getTimestamp("CancelledAt");
            if (cancelledAtTs != null) {
                lich.setCancelledAt(cancelledAtTs.toLocalDateTime());
            }
            int cancelledBy = rs.getInt("CancelledBy");
            if (!rs.wasNull()) {
                lich.setCancelledBy(cancelledBy);
            }
            lich.setRequiresRefundReview(rs.getBoolean("RequiresRefundReview"));
        } catch (SQLException e) {
            // New columns might not be present in some select statements
        }
```

- [ ] **Step 4: Extend the account-join block to carry reputation fields, and extend `getLichDatSanByCoSo`'s SQL**

In the existing `FullName`/account try-block (lines 350-362), change:

```java
        try {
            String fullName = rs.getNString("FullName");
            if (fullName != null) {
                org.example.model.TaiKhoan acc = new org.example.model.TaiKhoan();
                acc.setAccountId(rs.getInt("AccountID"));
                acc.setFullName(fullName);
                acc.setPhoneNumber(rs.getString("PhoneNumber"));
                acc.setEmail(rs.getString("Email"));
                lich.setAccount(acc);
            }
        } catch (SQLException e) {
            // Column not found, ignore
        }
```

to:

```java
        try {
            String fullName = rs.getNString("FullName");
            if (fullName != null) {
                org.example.model.TaiKhoan acc = new org.example.model.TaiKhoan();
                acc.setAccountId(rs.getInt("AccountID"));
                acc.setFullName(fullName);
                acc.setPhoneNumber(rs.getString("PhoneNumber"));
                acc.setEmail(rs.getString("Email"));
                try {
                    acc.setDiemUyTin(rs.getInt("DiemUyTin"));
                    acc.setLateCancelCount(rs.getInt("LateCancelCount"));
                    acc.setNoShowCount(rs.getInt("NoShowCount"));
                } catch (SQLException ignoredReputationCols) {
                    // Query didn't select reputation columns (e.g. getLichDatSanTodayByCoSo) — leave defaults
                }
                lich.setAccount(acc);
            }
        } catch (SQLException e) {
            // Column not found, ignore
        }
```

Then update `getLichDatSanByCoSo` (currently lines 392-415) — change the SQL from:

```java
        String sql = "SELECT l.*, s.TenSan, s.CoSoID, a.FullName, a.PhoneNumber, a.Email " +
                     "FROM LichDatSan l " +
                     "JOIN San s ON l.SanID = s.SanID " +
                     "LEFT JOIN Accounts a ON l.AccountID = a.AccountID " +
                     "WHERE s.CoSoID = ? AND l.IsDeleted = 0 " +
                     "ORDER BY l.NgayDat DESC, l.GioBatDau DESC";
```

to:

```java
        String sql = "SELECT l.*, s.TenSan, s.CoSoID, a.FullName, a.PhoneNumber, a.Email, " +
                     "a.DiemUyTin, a.LateCancelCount, a.NoShowCount " +
                     "FROM LichDatSan l " +
                     "JOIN San s ON l.SanID = s.SanID " +
                     "LEFT JOIN Accounts a ON l.AccountID = a.AccountID " +
                     "WHERE s.CoSoID = ? AND l.IsDeleted = 0 " +
                     "ORDER BY l.NgayDat DESC, l.GioBatDau DESC";
```

(This is the query behind `QuanLyDatSanServlet`'s Manager/Staff booking list — Task 14 reads `item.account.diemUyTin` etc. directly off the nested `TaiKhoan`, no new DTO needed.)

- [ ] **Step 5: Compile**

Run: `mvn -q compile`
Expected: `BUILD SUCCESS`

- [ ] **Step 6: Commit**

```bash
git add src/main/java/org/example/dao/LichDatSanDAO.java src/main/java/org/example/dao/impl/LichDatSanDAOImpl.java
git commit -m "feat: add atomic cancelByCustomer DAO method, fix holdExpiresAt mapping, surface reputation on manager booking list"
```

---

## Task 9: `BookingCancellationService` — customer-initiated cancel orchestration

**Files:**
- Create: `src/main/java/org/example/service/booking/BookingCancellationService.java`
- Test: `src/test/java/org/example/service/booking/BookingCancellationServiceEligibilityTest.java`

**Interfaces:**
- Consumes: `CancelDecision.decide(...)` (Task 6), `LichDatSanDAO.cancelByCustomer(...)` (Task 8), `CustomerReputationService.applyDelta(...)` (Task 7), `AuditLogService.log(...)`/`ACTION_CANCEL`/`ENTITY_DAT_SAN`/`getClientIp(...)` (Task 2), `Constants.LATE_CANCEL_HOURS/LATE_CANCEL_PENALTY/CANCEL_TYPE_EARLY/CANCEL_TYPE_LATE/REPUTATION_ACTION_LATE_CANCEL` (Task 1), `Constants.PT_PAYOS`, `Constants.PAYOS_PAID_GHI_CHU_MARKER` (existing).
- Produces: `BookingCancellationService.CancelResult` (fields: `boolean success`, `boolean alreadyCancelled`, `boolean lateCancel`, `String message`, `Integer newReputationScore`) and `CancelResult cancelByCustomer(int datSanId, int accountId, String reason, HttpServletRequest req, TaiKhoan actor)` — used by Task 15 (`DatSanServlet`). Also exposes the pure eligibility check `static boolean isCancellableStatus(String trangThai)` for the unit test below.

- [ ] **Step 1: Write the failing test for the pure eligibility-status helper**

```java
package org.example.service.booking;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class BookingCancellationServiceEligibilityTest {

    @Test
    void choXacNhanIsCancellable() {
        assertTrue(BookingCancellationService.isCancellableStatus("Chờ xác nhận"));
    }

    @Test
    void daXacNhanIsCancellable() {
        assertTrue(BookingCancellationService.isCancellableStatus("Đã xác nhận"));
    }

    @Test
    void choThanhToanIsCancellable() {
        assertTrue(BookingCancellationService.isCancellableStatus("Chờ thanh toán"));
    }

    @Test
    void dangSuDungIsNotCancellable() {
        assertFalse(BookingCancellationService.isCancellableStatus("Đang sử dụng"));
    }

    @Test
    void daHoanThanhIsNotCancellable() {
        assertFalse(BookingCancellationService.isCancellableStatus("Đã hoàn thành"));
    }

    @Test
    void khongDenIsNotCancellable() {
        assertFalse(BookingCancellationService.isCancellableStatus("Không đến"));
    }

    @Test
    void daHuyIsNotCancellable() {
        assertFalse(BookingCancellationService.isCancellableStatus("Đã hủy"));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn -q test -Dtest=BookingCancellationServiceEligibilityTest`
Expected: compile error — `cannot find symbol: class BookingCancellationService`

- [ ] **Step 3: Implement `BookingCancellationService`**

```java
package org.example.service.booking;

import jakarta.servlet.http.HttpServletRequest;
import org.example.dao.LichDatSanDAO;
import org.example.dao.impl.LichDatSanDAOImpl;
import org.example.model.Lichdatsan;
import org.example.model.TaiKhoan;
import org.example.service.AuditLogService;
import org.example.service.reputation.CustomerReputationService;
import org.example.util.Constants;
import org.example.util.DBUtil;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDateTime;

/**
 * Hủy booking do khách tự thao tác (mục 5, 16 spec). Servlet chỉ nhận request và gọi service này -
 * không được duplicate logic tính hủy sớm/hủy sát giờ hay trừ điểm ở bất kỳ Servlet nào khác.
 */
public class BookingCancellationService {

    private static final Logger logger = LogManager.getLogger(BookingCancellationService.class);

    private final LichDatSanDAO lichDatSanDAO;

    public BookingCancellationService() {
        this(new LichDatSanDAOImpl());
    }

    public BookingCancellationService(LichDatSanDAO lichDatSanDAO) {
        this.lichDatSanDAO = lichDatSanDAO;
    }

    public static class CancelResult {
        public final boolean success;
        public final boolean alreadyCancelled;
        public final boolean lateCancel;
        public final String message;
        public final Integer newReputationScore;

        private CancelResult(boolean success, boolean alreadyCancelled, boolean lateCancel,
                              String message, Integer newReputationScore) {
            this.success = success;
            this.alreadyCancelled = alreadyCancelled;
            this.lateCancel = lateCancel;
            this.message = message;
            this.newReputationScore = newReputationScore;
        }

        static CancelResult ok(boolean lateCancel, String message, Integer newReputationScore) {
            return new CancelResult(true, false, lateCancel, message, newReputationScore);
        }

        static CancelResult alreadyDone(String message) {
            return new CancelResult(false, true, false, message, null);
        }

        static CancelResult fail(String message) {
            return new CancelResult(false, false, false, message, null);
        }
    }

    /** Trạng thái nguồn được phép hủy bởi khách (mục 10 spec). Logic thuần — test riêng, không đụng DB. */
    public static boolean isCancellableStatus(String trangThai) {
        return Constants.TRANG_THAI_DAT_SAN_CHO_XAC_NHAN.equals(trangThai)
                || Constants.TRANG_THAI_DAT_SAN_DA_XAC_NHAN.equals(trangThai)
                || Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN.equals(trangThai);
    }

    public CancelResult cancelByCustomer(int datSanId, int accountId, String reason,
                                          HttpServletRequest req, TaiKhoan actor) {
        Lichdatsan lich = lichDatSanDAO.getLichById(datSanId);
        if (lich == null) {
            return CancelResult.fail("Không tìm thấy đơn đặt sân.");
        }
        if (lich.getAccountId() == null || lich.getAccountId() != accountId) {
            logger.warn("IDOR attempt: AccountID={} co huy don ID={} cua AccountID={}",
                    accountId, datSanId, lich.getAccountId());
            return CancelResult.fail("Bạn không có quyền hủy đơn này.");
        }
        if (Constants.TRANG_THAI_DAT_SAN_DA_XAC_NHAN.equals(lich.getTrangThai())
                && (Constants.PT_PAYOS.equals(lich.getPaymentMethodConfirmed())
                    || (lich.getGhiChu() != null && lich.getGhiChu().contains(Constants.PAYOS_PAID_GHI_CHU_MARKER)))) {
            return CancelResult.fail("Đơn này đã thanh toán PayOS. Vui lòng liên hệ sân để được hỗ trợ hủy/hoàn tiền.");
        }
        if (!isCancellableStatus(lich.getTrangThai())) {
            return CancelResult.fail("Chỉ có thể hủy đơn đang ở trạng thái 'Chờ xác nhận', 'Đã xác nhận' hoặc " +
                    "'Chờ thanh toán'. Đơn của bạn hiện đang ở trạng thái '" + lich.getTrangThai() + "'.");
        }
        if (Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN.equals(lich.getTrangThai())
                && lich.getHoldExpiresAt() != null && !lich.getHoldExpiresAt().isAfter(LocalDateTime.now())) {
            return CancelResult.fail("Đơn giữ chỗ đã hết hạn, không thể hủy (đã tự động giải phóng).");
        }

        LocalDateTime now = LocalDateTime.now();
        LocalDateTime bookingStart = LocalDateTime.of(lich.getNgayDat(), lich.getGioBatDau());
        boolean isLate = CancelDecision.decide(now, bookingStart, Constants.LATE_CANCEL_HOURS)
                == CancelDecision.CancelType.LATE_CANCEL;
        String cancelType = isLate ? Constants.CANCEL_TYPE_LATE : Constants.CANCEL_TYPE_EARLY;

        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            Integer newScore = null;
            try {
                int rows = lichDatSanDAO.cancelByCustomer(conn, datSanId, accountId, cancelType, reason);
                if (rows == 0) {
                    conn.rollback();
                    return CancelResult.alreadyDone("Booking đã được hủy trước đó hoặc không còn ở trạng thái có thể hủy.");
                }
                if (isLate) {
                    newScore = CustomerReputationService.applyDelta(conn, accountId, datSanId,
                            Constants.REPUTATION_ACTION_LATE_CANCEL, Constants.LATE_CANCEL_PENALTY,
                            "Khách hủy sát giờ (dưới " + Constants.LATE_CANCEL_HOURS + " tiếng trước giờ chơi)",
                            accountId, AuditLogService.getClientIp(req));
                }
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }

            AuditLogService.log(req, actor, AuditLogService.ACTION_CANCEL, AuditLogService.ENTITY_DAT_SAN,
                    String.valueOf(datSanId), "Đơn đặt sân #" + datSanId,
                    (isLate ? "Khách hủy sát giờ (Late Cancel)" : "Khách hủy sớm (Early Cancel)")
                            + (reason != null && !reason.isBlank() ? " - Lý do: " + reason.trim() : ""));

            String message = isLate
                    ? "Bạn đã hủy sát giờ. Hệ thống đã ghi nhận và điểm uy tín của bạn bị trừ "
                        + Math.abs(Constants.LATE_CANCEL_PENALTY) + " điểm."
                    : "Đã hủy đơn đặt sân #" + datSanId + " thành công.";
            return CancelResult.ok(isLate, message, newScore);
        } catch (SQLException e) {
            logger.error("Loi khi huy booking #{} cho AccountID={}: {}", datSanId, accountId, e.getMessage(), e);
            return CancelResult.fail("Hệ thống gặp lỗi khi hủy đơn. Vui lòng thử lại.");
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mvn -q test -Dtest=BookingCancellationServiceEligibilityTest`
Expected: `Tests run: 7, Failures: 0, Errors: 0`

- [ ] **Step 5: Compile the whole project (this class touches DAO/servlet-adjacent types)**

Run: `mvn -q compile`
Expected: `BUILD SUCCESS`

- [ ] **Step 6: Commit**

```bash
git add src/main/java/org/example/service/booking/BookingCancellationService.java src/test/java/org/example/service/booking/BookingCancellationServiceEligibilityTest.java
git commit -m "feat: add BookingCancellationService orchestrating late-cancel penalty + audit"
```

---

## Task 10: Rewire `DatSanServlet.handleHuyDatSan` to use `BookingCancellationService`

**Files:**
- Modify: `src/main/java/org/example/controller/customer/DatSanServlet.java`

**Interfaces:**
- Consumes: `BookingCancellationService.cancelByCustomer(...)` (Task 9).
- Produces: same route (`POST /customer/huy-dat-san`), now accepts an optional `reason` form field.

This removes the hard 6-hour block (lines 836-843) and the separate inline "Chờ thanh toán" SQL branch (lines 844-868) — both are now handled uniformly by `BookingCancellationService`, which also covers the PayOS-paid guard and the IDOR guard (previously inline here). This is a pure behavior consolidation; test manually via Task 18's checklist (this method touches session/servlet plumbing that isn't unit-testable without a servlet container, consistent with how the rest of this class is tested today — there are no existing servlet-level unit tests in this codebase to extend).

- [ ] **Step 1: Add a `BookingCancellationService` field**

Find the existing DAO field declaration in `DatSanServlet.java` (near the top of the class, alongside `lichDatSanDAO`), and add:

```java
    private final org.example.service.booking.BookingCancellationService bookingCancellationService =
            new org.example.service.booking.BookingCancellationService();
```

- [ ] **Step 2: Replace `handleHuyDatSan`**

Replace the entire method body (lines 811-880) with:

```java
    private void handleHuyDatSan(HttpServletRequest req, HttpServletResponse resp,
            HttpSession session, TaiKhoan user) throws IOException {
        LOGGER.info(String.format("[huy-dat-san] request nhận: servletPath=%s, pathInfo=%s, accountId=%d, rawId=%s",
                req.getServletPath(), req.getPathInfo(), user.getAccountId(), req.getParameter("id")));
        try {
            int id = Integer.parseInt(req.getParameter("id"));
            String reason = req.getParameter("reason");

            org.example.service.booking.BookingCancellationService.CancelResult result =
                    bookingCancellationService.cancelByCustomer(id, user.getAccountId(), reason, req, user);

            if (result.success) {
                session.setAttribute("message", result.message);
                LOGGER.info(String.format("[huy-dat-san] THANH CONG: AccountID=%d, DatSanID=%d, lateCancel=%s",
                        user.getAccountId(), id, result.lateCancel));
            } else {
                session.setAttribute("error", result.message);
                LOGGER.info(String.format("[huy-dat-san] THAT BAI: AccountID=%d, DatSanID=%d, message=%s",
                        user.getAccountId(), id, result.message));
            }
        } catch (NumberFormatException e) {
            session.setAttribute("error", "Yêu cầu không hợp lệ.");
        }

        resp.sendRedirect(req.getContextPath() + "/customer/dat-san?openHistory=true");
    }
```

- [ ] **Step 3: Compile**

Run: `mvn -q compile`
Expected: `BUILD SUCCESS`

- [ ] **Step 4: Commit**

```bash
git add src/main/java/org/example/controller/customer/DatSanServlet.java
git commit -m "feat: route customer cancel through BookingCancellationService, remove hard 6h block"
```

---

## Task 11: Extend `CheckInDAO.huyLichKhachBung` with reputation penalty + refund-review flag

**Files:**
- Modify: `src/main/java/org/example/dao/CheckInDAO.java`
- Modify: `src/main/java/org/example/controller/staff/CheckInServlet.java`

**Interfaces:**
- Consumes: `CustomerReputationService.applyDelta(...)` (Task 7), `AuditLogService.ACTION_NO_SHOW/ENTITY_DAT_SAN/getClientIp(...)` (Task 2), `Constants.NO_SHOW_PENALTY/REPUTATION_ACTION_NO_SHOW` (Task 1).
- Produces: new signature `void huyLichKhachBung(int datSanId, int staffAccountId, int requiredCoSoId, String ipAddress) throws CheckInException` (added `ipAddress` param — DAO stays servlet-agnostic per project convention "DAO chỉ làm SQL", so the caller computes IP via `AuditLogService.getClientIp(req)` and passes it in).

Not unit-tested (needs live DB + existing transaction machinery); covered by Task 18's manual checklist. This task is a surgical extension of an already-correct, already-idempotent method — do not restructure its transaction handling, only add to it.

- [ ] **Step 1: Change the method signature and fetch `AccountID`**

In `CheckInDAO.java`, change the `huyLichKhachBung` signature (currently `public void huyLichKhachBung(int datSanId, int staffAccountId, int requiredCoSoId) throws CheckInException {`) to:

```java
    public void huyLichKhachBung(int datSanId, int staffAccountId, int requiredCoSoId, String ipAddress) throws CheckInException {
```

Update the initial `SELECT` (currently):
```java
            String sqlSelect = "SELECT l.TrangThai, l.GhiChu, l.NgayDat, l.GioBatDau, s.CoSoID " +
                    "FROM LichDatSan l WITH (UPDLOCK, ROWLOCK) JOIN San s ON s.SanID = l.SanID WHERE l.DatSanID = ?";
```
to also select `AccountID`:
```java
            String sqlSelect = "SELECT l.TrangThai, l.GhiChu, l.NgayDat, l.GioBatDau, l.AccountID, s.CoSoID " +
                    "FROM LichDatSan l WITH (UPDLOCK, ROWLOCK) JOIN San s ON s.SanID = l.SanID WHERE l.DatSanID = ?";
```

Right after the existing `String trangThaiBooking = rs.getString("TrangThai");` line, add:
```java
            int customerAccountId = rs.getInt("AccountID");
            boolean hasCustomerAccount = !rs.wasNull();
```

(Guest/walk-in bookings can have a null `AccountID` — reputation only applies to accounts that exist, matching the existing null-safety pattern used elsewhere in this file for `AccountID`.)

- [ ] **Step 2: Apply the penalty inside the existing transaction, right after the booking UPDATE succeeds**

Immediately after the existing block:
```java
            psUpdateBooking = conn.prepareStatement(sqlUpdateBooking);
            psUpdateBooking.setString(1, org.example.util.Constants.TRANG_THAI_DAT_SAN_KHONG_DEN);
            psUpdateBooking.setString(2, logGhiChu.trim());
            psUpdateBooking.setInt(3, datSanId);
            if (psUpdateBooking.executeUpdate() != 1) {
                throw new CheckInException("Trạng thái đơn đặt sân vừa thay đổi bởi một thao tác khác. Vui lòng tải lại.");
            }
```
add:
```java

            // 2b. Trừ điểm uy tín NO_SHOW - chỉ chạy khi booking thực sự vừa được đánh dấu ở bước trên
            // (nếu executeUpdate() != 1 đã throw ở trên, nên tới đây chắc chắn là lần đánh dấu đầu tiên).
            if (hasCustomerAccount) {
                org.example.service.reputation.CustomerReputationService.applyDelta(conn, customerAccountId, datSanId,
                        org.example.util.Constants.REPUTATION_ACTION_NO_SHOW, org.example.util.Constants.NO_SHOW_PENALTY,
                        "Khách không đến (No Show)", staffAccountId, ipAddress);
            }
```

- [ ] **Step 3: Set `RequiresRefundReview` when the invoice was already paid/deposited**

In the existing "already paid" branch:
```java
                } else {
                    String sqlFlagInvoice = "UPDATE HoaDon SET GhiChu = ? WHERE HoaDonID = ?";
                    psUpdateInvoice = conn.prepareStatement(sqlFlagInvoice);
                    psUpdateInvoice.setString(1, ((invoiceGhiChu != null ? invoiceGhiChu.trim() : "") +
                            " [Khách bùng - đã thu tiền, cần xử lý hoàn tiền/giữ cọc thủ công]").trim());
                    psUpdateInvoice.setInt(2, hoaDonId);
                    psUpdateInvoice.executeUpdate();
                }
```
add, right after `psUpdateInvoice.executeUpdate();` inside that same `else` branch:
```java
                    try (PreparedStatement psFlagBooking = conn.prepareStatement(
                            "UPDATE LichDatSan SET RequiresRefundReview = 1 WHERE DatSanID = ?")) {
                        psFlagBooking.setInt(1, datSanId);
                        psFlagBooking.executeUpdate();
                    }
```

- [ ] **Step 4: Update the call site in `CheckInServlet.java`**

Change (currently around line 343-349):
```java
                checkInDAO.huyLichKhachBung(datSanId, user.getAccountId(), user.getCoSoId());
                org.example.service.AuditLogService.log(req, user,
                    "NO_SHOW",
                    "LichDatSan",
                    String.valueOf(datSanId),
                    "Don dat san #" + datSanId,
                    "Da danh dau khach khong den (no-show)");
```
to:
```java
                checkInDAO.huyLichKhachBung(datSanId, user.getAccountId(), user.getCoSoId(),
                        org.example.service.AuditLogService.getClientIp(req));
                org.example.service.AuditLogService.log(req, user,
                    org.example.service.AuditLogService.ACTION_NO_SHOW,
                    org.example.service.AuditLogService.ENTITY_DAT_SAN,
                    String.valueOf(datSanId),
                    "Đơn đặt sân #" + datSanId,
                    "Đã đánh dấu khách không đến (No Show) - đã trừ điểm uy tín");
```

- [ ] **Step 5: Compile**

Run: `mvn -q compile`
Expected: `BUILD SUCCESS` — this will also surface any other call sites of `huyLichKhachBung` that need the new `ipAddress` parameter; grep for them and fix (`grep -rn "huyLichKhachBung" src/main/java`).

- [ ] **Step 6: Commit**

```bash
git add src/main/java/org/example/dao/CheckInDAO.java src/main/java/org/example/controller/staff/CheckInServlet.java
git commit -m "feat: dock reputation on no-show, flag paid invoices for refund review"
```

---

## Task 12: Surface reputation on the Staff Check-in AJAX list (`BookingViewDTO`)

**Files:**
- Modify: `src/main/java/org/example/dao/CheckInDAO.java`

**Interfaces:**
- Consumes: `ReputationLabel.of(int)` (Task 5).
- Produces: new fields on `BookingViewDTO`: `getReputationScore()/setReputationScore(Integer)`, `getReputationLabel()/setReputationLabel(String)`, `getLateCancelCount()/setLateCancelCount(Integer)`, `getNoShowCount()/setNoShowCount(Integer)`. These are plain fields serialized automatically by Gson (field-reflection based, ignores JPA annotations) in the existing `fetch('.../staff/checkin?ajax=true')` response consumed by `CheckIn.jsp`'s `danhSachLich` JS array — no new endpoint needed.

- [ ] **Step 1: Add fields + accessors to `BookingViewDTO`**

In the `BookingViewDTO` class (starts at line 817), after the existing `nguonDatSan` field/accessors, add:

```java
        private Integer reputationScore;
        private String reputationLabel;
        private Integer lateCancelCount;
        private Integer noShowCount;

        public Integer getReputationScore() { return reputationScore; }
        public void setReputationScore(Integer reputationScore) { this.reputationScore = reputationScore; }

        public String getReputationLabel() { return reputationLabel; }
        public void setReputationLabel(String reputationLabel) { this.reputationLabel = reputationLabel; }

        public Integer getLateCancelCount() { return lateCancelCount; }
        public void setLateCancelCount(Integer lateCancelCount) { this.lateCancelCount = lateCancelCount; }

        public Integer getNoShowCount() { return noShowCount; }
        public void setNoShowCount(Integer noShowCount) { this.noShowCount = noShowCount; }
```

- [ ] **Step 2: Select and populate the new fields in `getDanhSachLichCheckInHomNay`**

Change the SQL (currently):
```java
            String sql = "SELECT lds.DatSanID, s.SanID, s.TenSan, acc.FullName AS TenKhachHang, acc.PhoneNumber AS SoDienThoai, " +
                         "ls.TenLoai AS TenLoaiSan, " +
                         "lds.NgayDat, lds.GioBatDau, lds.GioKetThuc, lds.TongTienDuKien, " +
                         "lds.TrangThai, lds.GhiChu, hd.TrangThaiThanhToan, lds.NguonDatSan " +
```
to:
```java
            String sql = "SELECT lds.DatSanID, s.SanID, s.TenSan, acc.FullName AS TenKhachHang, acc.PhoneNumber AS SoDienThoai, " +
                         "ls.TenLoai AS TenLoaiSan, " +
                         "lds.NgayDat, lds.GioBatDau, lds.GioKetThuc, lds.TongTienDuKien, " +
                         "lds.TrangThai, lds.GhiChu, hd.TrangThaiThanhToan, lds.NguonDatSan, " +
                         "acc.DiemUyTin, acc.LateCancelCount, acc.NoShowCount " +
```

Right after the existing `dto.setNguonDatSan(nguonDat != null ? nguonDat : "Walk-in");` line, add:
```java
                    int diemUyTin = rs.getInt("DiemUyTin");
                    if (!rs.wasNull()) {
                        dto.setReputationScore(diemUyTin);
                        dto.setReputationLabel(org.example.service.reputation.ReputationLabel.of(diemUyTin));
                        dto.setLateCancelCount(rs.getInt("LateCancelCount"));
                        dto.setNoShowCount(rs.getInt("NoShowCount"));
                    }
```

(Guest/walk-in bookings have no matching `Accounts` row via the `LEFT JOIN Accounts acc`, so `DiemUyTin` is `NULL` — `rs.wasNull()` correctly leaves the reputation fields unset for those, and `CheckIn.jsp` should treat missing values as "no reputation data" rather than defaulting to a score.)

- [ ] **Step 3: Compile**

Run: `mvn -q compile`
Expected: `BUILD SUCCESS`

- [ ] **Step 4: Commit**

```bash
git add src/main/java/org/example/dao/CheckInDAO.java
git commit -m "feat: surface customer reputation on staff check-in booking cards"
```

---

## Task 13: Award +2 reputation on booking completion (`CheckoutService`)

**Files:**
- Modify: `src/main/java/org/example/service/checkout/CheckoutService.java`

**Interfaces:**
- Consumes: `CustomerReputationService.applyDelta(...)` (Task 7), `Constants.COMPLETED_BOOKING_REWARD/REPUTATION_ACTION_COMPLETED_BOOKING` (Task 1).
- Produces: no signature change — `completeBookingAndReleaseCourtIfNeeded(Connection, int)` stays `private`, just does one more thing inside its existing idempotent guard.

Not unit-tested (needs live DB); covered by Task 18's manual checklist. The existing method is already idempotent by design ("0 dòng bị ảnh hưởng nghĩa là đã Complete/release từ trước, KHÔNG phải lỗi") — the reward must only fire when the UPDATE actually flipped a row, otherwise re-running an already-completed checkout would double-reward.

- [ ] **Step 1: Extend `completeBookingAndReleaseCourtIfNeeded`**

Replace (currently lines 218-230):
```java
    /** Idempotent: 0 dòng bị ảnh hưởng nghĩa là đã Complete/release từ trước, KHÔNG phải lỗi. */
    private void completeBookingAndReleaseCourtIfNeeded(Connection c, int datSanId) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "UPDATE LichDatSan SET TrangThai=N'Đã hoàn thành' WHERE DatSanID=? AND TrangThai=N'Đang sử dụng'")) {
            ps.setInt(1, datSanId);
            ps.executeUpdate();
        }
        try (PreparedStatement ps = c.prepareStatement(
                "UPDATE San SET TrangThai=N'Sẵn sàng' WHERE SanID=(SELECT SanID FROM LichDatSan WHERE DatSanID=?) AND TrangThai=N'Đang sử dụng'")) {
            ps.setInt(1, datSanId);
            ps.executeUpdate();
        }
    }
```
with:
```java
    /** Idempotent: 0 dòng bị ảnh hưởng nghĩa là đã Complete/release từ trước, KHÔNG phải lỗi. */
    private void completeBookingAndReleaseCourtIfNeeded(Connection c, int datSanId) throws SQLException {
        Integer accountId = null;
        try (PreparedStatement ps = c.prepareStatement("SELECT AccountID FROM LichDatSan WHERE DatSanID = ?")) {
            ps.setInt(1, datSanId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int acc = rs.getInt("AccountID");
                    if (!rs.wasNull()) accountId = acc;
                }
            }
        }

        int rowsUpdated;
        try (PreparedStatement ps = c.prepareStatement(
                "UPDATE LichDatSan SET TrangThai=N'Đã hoàn thành' WHERE DatSanID=? AND TrangThai=N'Đang sử dụng'")) {
            ps.setInt(1, datSanId);
            rowsUpdated = ps.executeUpdate();
        }
        try (PreparedStatement ps = c.prepareStatement(
                "UPDATE San SET TrangThai=N'Sẵn sàng' WHERE SanID=(SELECT SanID FROM LichDatSan WHERE DatSanID=?) AND TrangThai=N'Đang sử dụng'")) {
            ps.setInt(1, datSanId);
            ps.executeUpdate();
        }

        // Cộng điểm uy tín hoàn thành booking - CHỈ khi UPDATE ở trên vừa thực sự chuyển trạng thái
        // (idempotent: nếu đã "Đã hoàn thành" từ trước, rowsUpdated=0, không cộng điểm lần hai).
        if (rowsUpdated > 0 && accountId != null) {
            org.example.service.reputation.CustomerReputationService.applyDelta(c, accountId, datSanId,
                    org.example.util.Constants.REPUTATION_ACTION_COMPLETED_BOOKING,
                    org.example.util.Constants.COMPLETED_BOOKING_REWARD,
                    "Hoàn thành booking thành công", null, null);
        }
    }
```

- [ ] **Step 2: Compile**

Run: `mvn -q compile`
Expected: `BUILD SUCCESS`

- [ ] **Step 3: Commit**

```bash
git add src/main/java/org/example/service/checkout/CheckoutService.java
git commit -m "feat: award +2 reputation on idempotent booking completion"
```

---

## Task 14: Customer JSP — cancel confirmation modal with late-cancel warning

**Files:**
- Modify: `src/main/webapp/customer/LichSuDatSan.jsp`

**Interfaces:**
- Consumes: `${lich.ngayDat}`, `${lich.gioBatDau}`, `${lich.trangThai}`, `${lich.datSanId}` (already available in this loop, from `Lichdatsan`).
- Produces: replaces the bare `confirm()`-dialog cancel form (lines 188-195) with a modal matching the existing `customerServiceModal` open/close pattern already in this file (lines 366-430, 511-518), adds a `reason` textarea, and computes the late-cancel warning client-side from the booking's date/time (no new server round-trip needed to decide "is this late" for the warning banner — the actual authoritative EARLY/LATE decision is still made server-side by `CancelDecision` in Task 6/9; the client-side check here is purely a UI warning heuristic in JavaScript re-implementing the exact same `>6h` rule for display).

Not unit-tested (JSP/JS UI) — verified via Task 18's manual checklist and the `verify` skill in a live browser if the dev server is reachable.

- [ ] **Step 1: Replace the inline cancel form with a button that opens a new modal**

Replace (lines 188-195):
```jsp
                                                    <c:if test="${lich.trangThai == 'Chờ xác nhận' || lich.trangThai == 'Đã xác nhận'}">
                                                        <form action="${pageContext.request.contextPath}/customer/huy-dat-san" method="post" onsubmit="return confirm('Bạn có chắc chắn muốn hủy yêu cầu đặt sân này?');" class="inline-block">
                                                                <input type="hidden" name="id" value="${lich.datSanId}">
                                                                <button type="submit" class="px-3 py-1.5 rounded-lg border border-red-200 text-red-500 font-bold hover:bg-red-50 hover:border-red-300 transition-all active:scale-95 text-[10px]">
                                                                    Hủy
                                                                </button>
                                                            </form>
                                                    </c:if>
```
with:
```jsp
                                                    <c:if test="${lich.trangThai == 'Chờ xác nhận' || lich.trangThai == 'Đã xác nhận'}">
                                                        <button type="button"
                                                                onclick="openCancelBookingModal(${lich.datSanId}, '${lich.ngayDat}', '${lich.gioBatDau}')"
                                                                class="px-3 py-1.5 rounded-lg border border-red-200 text-red-500 font-bold hover:bg-red-50 hover:border-red-300 transition-all active:scale-95 text-[10px]">
                                                            Hủy
                                                        </button>
                                                    </c:if>
```

- [ ] **Step 2: Add the modal markup**

Right after the closing `</div>` of the existing `customerServiceModal` (find it — the block starting `<div id="customerServiceModal" ...>` around line 366, ends before the `<script>` block around line 415), add a new sibling modal:

```jsp
    <div id="cancelBookingModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[60] hidden flex items-center justify-center opacity-0 transition-opacity duration-300 overflow-y-auto py-10 px-4">
        <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md scale-95 transition-transform duration-300">
            <div class="bg-red-600 rounded-t-2xl px-6 py-4 flex items-center justify-between">
                <h3 class="text-white font-bold text-sm">Xác nhận hủy đặt sân</h3>
                <button onclick="closeCancelBookingModal()" class="text-white/80 hover:text-white transition-colors p-1">
                    <span class="material-symbols-outlined text-[20px]">close</span>
                </button>
            </div>
            <form id="cancelBookingForm" action="${pageContext.request.contextPath}/customer/huy-dat-san" method="post">
                <input type="hidden" name="id" id="cancelBookingDatSanId" value="">
                <div class="p-6 space-y-4">
                    <p class="text-sm text-slate-600">Bạn có chắc chắn muốn hủy yêu cầu đặt sân này không?</p>
                    <div id="cancelBookingLateWarning" class="hidden bg-amber-50 border border-amber-200 rounded-xl p-3 text-[12px] text-amber-800 font-semibold leading-snug">
                        Bạn vẫn có thể hủy, nhưng đây là hủy sát giờ và sẽ ảnh hưởng điểm uy tín của bạn.
                    </div>
                    <div>
                        <label class="block text-[11px] font-bold text-slate-500 uppercase tracking-wide mb-1.5">Lý do hủy (không bắt buộc)</label>
                        <textarea name="reason" rows="2" maxlength="255" placeholder="Ví dụ: bận việc đột xuất..." class="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-red-200"></textarea>
                    </div>
                </div>
                <div class="px-6 pb-6 flex items-center justify-end gap-3">
                    <button type="button" onclick="closeCancelBookingModal()" class="px-5 py-2.5 rounded-xl font-bold text-slate-600 bg-slate-100 hover:bg-slate-200 transition-colors text-sm">
                        Đóng
                    </button>
                    <button type="submit" class="px-5 py-2.5 rounded-xl font-bold text-white bg-red-600 hover:bg-red-700 transition-colors text-sm">
                        Xác nhận hủy
                    </button>
                </div>
            </form>
        </div>
    </div>
```

- [ ] **Step 3: Add the open/close/late-check JS functions**

Right after the existing `closeCustomerServiceModal()` function (around line 511-518), add:

```javascript
        function openCancelBookingModal(datSanId, ngayDatStr, gioBatDauStr) {
            document.getElementById("cancelBookingDatSanId").value = datSanId;

            // Cảnh báo hủy sát giờ chỉ là gợi ý hiển thị phía client — quyết định EARLY/LATE
            // chính thức và việc trừ điểm luôn do server (BookingCancellationService) quyết định.
            var warningEl = document.getElementById("cancelBookingLateWarning");
            try {
                var bookingStart = new Date(ngayDatStr + "T" + gioBatDauStr);
                var hoursUntilStart = (bookingStart.getTime() - Date.now()) / (1000 * 60 * 60);
                warningEl.classList.toggle("hidden", hoursUntilStart > 6);
            } catch (e) {
                warningEl.classList.add("hidden");
            }

            var modal = document.getElementById("cancelBookingModal");
            modal.classList.remove("hidden");
            modal.classList.add("flex");
            requestAnimationFrame(function () {
                modal.classList.remove("opacity-0");
                modal.querySelector(".bg-white").classList.remove("scale-95");
            });
        }

        function closeCancelBookingModal() {
            var modal = document.getElementById("cancelBookingModal");
            modal.classList.add("opacity-0");
            modal.querySelector(".bg-white").classList.add("scale-95");
            setTimeout(function () {
                modal.classList.add("hidden");
                modal.classList.remove("flex");
            }, 300);
        }
```

- [ ] **Step 4: Compile the WAR to catch any JSP-breaking typo (JSPs aren't compiled by `mvn compile`, so package instead)**

Run: `mvn -q package -DskipTests`
Expected: `BUILD SUCCESS` (JSP syntax errors would otherwise only surface at Tomcat request time, but a broken `<%@ %>`/EL typo can still fail packaging if it corrupts the file — this is a basic sanity check, not full JSP validation).

- [ ] **Step 5: Commit**

```bash
git add src/main/webapp/customer/LichSuDatSan.jsp
git commit -m "feat: replace hard cancel confirm() with modal + late-cancel warning"
```

---

## Task 15: Manager/Staff JSP — reputation badge and risk warning on booking list

**Files:**
- Modify: `src/main/webapp/manager/QuanLyDatSan.jsp`
- Modify: `src/main/webapp/staff/QuanLyDatSan.jsp`

**Interfaces:**
- Consumes: `${item.account.diemUyTin}`, `${item.account.lateCancelCount}`, `${item.account.noShowCount}` — now populated by Task 8's DAO change, available on the same `item.account` (`TaiKhoan`) object this JSP already dereferences for `fullName`/`phoneNumber`.

Not unit-tested (JSP UI) — verified manually (Task 18).

- [ ] **Step 1: Add the reputation badge next to the customer name cell in `manager/QuanLyDatSan.jsp`**

In the customer-name `<td>` (currently lines 201-211):
```jsp
                <td class="px-5 py-4">
                  <div class="flex items-center gap-2.5">
                    <div class="w-8 h-8 rounded-full bg-purple-100 flex items-center justify-center text-purple-700 text-xs font-bold uppercase">
                      ${item.account != null ? item.account.fullName.substring(0,1) : 'K'}
                    </div>
                    <div>
                      <p class="text-xs font-semibold text-zinc-900">${item.account != null ? item.account.fullName : 'Khách vãng lai'}</p>
                      <p class="text-[10px] text-zinc-400">${item.account != null ? item.account.phoneNumber : 'N/A'}</p>
                    </div>
                  </div>
                </td>
```
replace with:
```jsp
                <td class="px-5 py-4">
                  <div class="flex items-center gap-2.5">
                    <div class="w-8 h-8 rounded-full bg-purple-100 flex items-center justify-center text-purple-700 text-xs font-bold uppercase">
                      ${item.account != null ? item.account.fullName.substring(0,1) : 'K'}
                    </div>
                    <div>
                      <p class="text-xs font-semibold text-zinc-900">${item.account != null ? item.account.fullName : 'Khách vãng lai'}</p>
                      <p class="text-[10px] text-zinc-400">${item.account != null ? item.account.phoneNumber : 'N/A'}</p>
                      <c:if test="${item.account != null}">
                        <c:choose>
                          <c:when test="${item.account.diemUyTin >= 80}">
                            <span class="inline-block mt-0.5 px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-700 text-[9px] font-bold">Uy tín: ${item.account.diemUyTin}/100 — Uy tín tốt</span>
                          </c:when>
                          <c:when test="${item.account.diemUyTin >= 50}">
                            <span class="inline-block mt-0.5 px-1.5 py-0.5 rounded bg-amber-50 text-amber-700 text-[9px] font-bold">Uy tín: ${item.account.diemUyTin}/100 — Cần theo dõi</span>
                          </c:when>
                          <c:otherwise>
                            <span class="inline-block mt-0.5 px-1.5 py-0.5 rounded bg-red-50 text-red-700 text-[9px] font-bold">Uy tín: ${item.account.diemUyTin}/100 — Rủi ro cao</span>
                          </c:otherwise>
                        </c:choose>
                        <c:if test="${item.account.lateCancelCount > 0 || item.account.noShowCount > 0}">
                          <p class="text-[9px] text-zinc-400 mt-0.5">${item.account.lateCancelCount} lần hủy sát giờ, ${item.account.noShowCount} lần không đến</p>
                        </c:if>
                        <c:if test="${item.account.diemUyTin < 50}">
                          <p class="text-[9px] text-red-600 font-bold mt-0.5">⚠ Khách hàng này có lịch sử bùng kèo. Vui lòng cân nhắc trước khi duyệt.</p>
                        </c:if>
                      </c:if>
                    </div>
                  </div>
                </td>
```

(Thresholds `80`/`50` here are literal because JSTL EL cannot reference `Constants.REPUTATION_GOOD_THRESHOLD`/`REPUTATION_WATCH_THRESHOLD` — this duplication is already the established pattern in this codebase for status strings; keep them in sync manually if Task 1's thresholds ever change, same caveat noted in the Constants.java comment from Task 1.)

- [ ] **Step 2: Apply the identical change to `staff/QuanLyDatSan.jsp`**

Locate the equivalent customer-name cell in `src/main/webapp/staff/QuanLyDatSan.jsp` (grep for `item.account != null ? item.account.fullName` to find it — this file mirrors the manager JSP's structure per the earlier investigation) and apply the exact same replacement as Step 1.

- [ ] **Step 3: Package to sanity-check JSP validity**

Run: `mvn -q package -DskipTests`
Expected: `BUILD SUCCESS`

- [ ] **Step 4: Commit**

```bash
git add src/main/webapp/manager/QuanLyDatSan.jsp src/main/webapp/staff/QuanLyDatSan.jsp
git commit -m "feat: show customer reputation badge and risk warning on manager/staff booking list"
```

---

## Task 16: Staff Check-in JSP — No Show confirmation modal with reputation warning

**Files:**
- Modify: `src/main/webapp/staff/CheckIn.jsp`

**Interfaces:**
- Consumes: `b.reputationScore`, `b.reputationLabel`, `b.lateCancelCount`, `b.noShowCount` from the JS-side `danhSachLich` array (now populated per Task 12), and `b.tenKhachHang`/`b.datSanId` (already present in this template).

The existing "cancelNoShow" trigger (line 1048-1054) is a plain `<form>` with a JS `confirm()` — replace it with a real modal per spec section 6/8 ("phải có modal xác nhận... không cho bấm nhầm"). Not unit-tested (JSP/JS UI); verified manually (Task 18).

- [ ] **Step 1: Replace the inline no-show form with a button that opens a modal**

Replace (currently lines 1048-1054):
```jsp
                            <form action="${pageContext.request.contextPath}/staff/checkin" method="post" class="inline-block" onsubmit="return confirm('Bạn có chắc chắn muốn hủy lịch đặt này do khách bùng không?');">
                                <input type="hidden" name="action" value="cancelNoShow">
                                <input type="hidden" name="datSanId" value="\${b.datSanId}">
                                <button type="submit" class="bg-rose-50 hover:bg-rose-100 text-rose-600 font-extrabold text-[10.5px] px-2.5 py-2 rounded-lg transition-all active:scale-95 flex items-center justify-center" title="Hủy ca do khách không đến">
                                    <span class="material-symbols-outlined text-[15px]">cancel</span>
                                </button>
                            </form>
```
with:
```jsp
                            <button type="button" onclick="openNoShowModal(\${b.datSanId}, '\${b.tenKhachHang}', \${b.reputationScore != null ? b.reputationScore : 'null'})"
                                    class="bg-rose-50 hover:bg-rose-100 text-rose-600 font-extrabold text-[10.5px] px-2.5 py-2 rounded-lg transition-all active:scale-95 flex items-center justify-center" title="Hủy ca do khách không đến">
                                <span class="material-symbols-outlined text-[15px]">cancel</span>
                            </button>
```

(This card block is built via JS template literals, hence the `\${...}` escaping already used throughout this file for the JS-side data — matches the existing convention exactly, e.g. line 984/1027/1418.)

- [ ] **Step 2: Add the modal markup**

Add this modal HTML near the other modals in this file (alongside `staffInvoiceModal`, e.g. right before its opening `<div id="staffInvoiceModal" ...>` around line 1625):

```jsp
<div id="noShowModal" role="dialog" aria-modal="true" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 hidden flex items-center justify-center opacity-0 transition-opacity duration-300 p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-sm scale-95 transition-transform duration-300">
        <div class="bg-rose-600 rounded-t-2xl px-5 py-4 flex items-center justify-between">
            <h3 class="text-white font-bold text-sm">Xác nhận đánh dấu Không đến</h3>
            <button onclick="closeNoShowModal()" class="text-white/80 hover:text-white transition-colors p-1">
                <span class="material-symbols-outlined text-[20px]">close</span>
            </button>
        </div>
        <div class="p-5 space-y-3">
            <p class="text-sm text-zinc-700">Khách hàng <strong id="noShowCustomerName">-</strong> sẽ được đánh dấu <strong>Không đến (No Show)</strong> cho đơn <strong id="noShowDatSanLabel">-</strong>.</p>
            <div class="bg-amber-50 border border-amber-200 rounded-xl p-3 text-[12px] text-amber-800 font-semibold leading-snug">
                Thao tác này sẽ trừ điểm uy tín của khách và không thể hoàn tác. Vui lòng kiểm tra kỹ trước khi xác nhận.
            </div>
            <p id="noShowCurrentReputation" class="text-[11px] text-zinc-500 hidden"></p>
        </div>
        <div class="px-5 pb-5 flex items-center justify-end gap-2">
            <button type="button" onclick="closeNoShowModal()" class="px-4 py-2 rounded-xl font-bold text-slate-600 bg-slate-100 hover:bg-slate-200 transition-colors text-sm">
                Hủy thao tác
            </button>
            <form id="noShowForm" action="${pageContext.request.contextPath}/staff/checkin" method="post">
                <input type="hidden" name="action" value="cancelNoShow">
                <input type="hidden" name="datSanId" id="noShowDatSanId" value="">
                <button type="submit" class="px-4 py-2 rounded-xl font-bold text-white bg-rose-600 hover:bg-rose-700 transition-colors text-sm">
                    Xác nhận Không đến
                </button>
            </form>
        </div>
    </div>
</div>
```

- [ ] **Step 3: Add the open/close JS functions**

Add near `openStaffInvoiceModal`/`closeStaffInvoiceModal` (around line 2507+):

```javascript
    function openNoShowModal(datSanId, tenKhachHang, reputationScore) {
        document.getElementById("noShowDatSanId").value = datSanId;
        document.getElementById("noShowCustomerName").textContent = tenKhachHang || "Khách vãng lai";
        document.getElementById("noShowDatSanLabel").textContent = "#" + datSanId;

        var repEl = document.getElementById("noShowCurrentReputation");
        if (reputationScore !== null && reputationScore !== undefined) {
            repEl.textContent = "Điểm uy tín hiện tại: " + reputationScore + "/100";
            repEl.classList.remove("hidden");
        } else {
            repEl.classList.add("hidden");
        }

        var modal = document.getElementById("noShowModal");
        modal.classList.remove("hidden");
        modal.classList.add("flex");
        requestAnimationFrame(function () {
            modal.classList.remove("opacity-0");
            modal.querySelector(".bg-white").classList.remove("scale-95");
        });
    }

    function closeNoShowModal() {
        var modal = document.getElementById("noShowModal");
        modal.classList.add("opacity-0");
        modal.querySelector(".bg-white").classList.add("scale-95");
        setTimeout(function () {
            modal.classList.add("hidden");
            modal.classList.remove("flex");
        }, 300);
    }
```

- [ ] **Step 4: Package to sanity-check JSP validity**

Run: `mvn -q package -DskipTests`
Expected: `BUILD SUCCESS`

- [ ] **Step 5: Commit**

```bash
git add src/main/webapp/staff/CheckIn.jsp
git commit -m "feat: replace no-show confirm() with modal warning about reputation impact"
```

---

## Task 17: Documentation — `docs/reputation_cancel_flow.md`

**Files:**
- Create: `docs/reputation_cancel_flow.md`

- [ ] **Step 1: Write the doc**

```markdown
# Luồng hủy sân + Điểm uy tín khách hàng

## 1. Luồng hủy sân (khách tự thao tác)

`customer/LichSuDatSan.jsp` → `POST /customer/huy-dat-san` (`DatSanServlet.handleHuyDatSan`)
→ `BookingCancellationService.cancelByCustomer(...)`:

1. Load booking, kiểm tra `AccountID` khớp (chống IDOR).
2. Chặn hủy đơn "Đã xác nhận" đã thanh toán PayOS (giữ nguyên rule cũ — chưa có refund tự động).
3. Chỉ cho hủy từ trạng thái: `Chờ xác nhận`, `Đã xác nhận`, `Chờ thanh toán` (còn hạn giữ chỗ).
4. `CancelDecision.decide(now, bookingStart, LATE_CANCEL_HOURS=6)` → `EARLY_CANCEL` hoặc `LATE_CANCEL`
   (đúng bằng 6 tiếng tính là `LATE_CANCEL`).
5. `LichDatSanDAO.cancelByCustomer(...)` — một UPDATE atomic với `WHERE TrangThai IN (...)` làm cổng
   idempotent: 0 dòng nghĩa là đã hủy/đổi trạng thái từ trước (double-click, network retry, hai tab).
6. Nếu `LATE_CANCEL`: `CustomerReputationService.applyDelta(...)` trừ `LATE_CANCEL_PENALTY` (-10) điểm,
   tăng `Accounts.LateCancelCount`, ghi 1 dòng `CustomerReputationHistory`. Chạy trong CÙNG transaction
   với bước 5 — nếu bước 5 rollback, điểm không bị trừ.
7. Ghi `AuditLog` (`ACTION_CANCEL`).
8. Trả thông báo cho khách:
   - Sớm: "Đã hủy đơn đặt sân #X thành công."
   - Sát giờ: "Bạn đã hủy sát giờ. Hệ thống đã ghi nhận và điểm uy tín của bạn bị trừ 10 điểm."

## 2. Luồng No Show (Staff/Manager)

`staff/CheckIn.jsp` → `POST /staff/checkin?action=cancelNoShow` (`CheckInServlet`)
→ `CheckInDAO.huyLichKhachBung(datSanId, staffAccountId, coSoId, ipAddress)`:

1. Khóa dòng booking + join `San` để xác minh đúng `CoSoID` của staff/manager (403 nếu không khớp).
2. `NoShowEligibility.check(...)` — chỉ cho phép khi: trạng thái `Đã xác nhận`, đúng ngày hôm nay, đã
   qua `NO_SHOW_GRACE_MINUTES` (15 phút) sau giờ bắt đầu.
3. UPDATE atomic `SET TrangThai=N'Không đến', NoShowAt=GETDATE() WHERE ... AND TrangThai=N'Đã xác nhận'`
   — cùng cơ chế idempotent-qua-rowcount như trên.
4. Trừ `NO_SHOW_PENALTY` (-20) điểm, tăng `Accounts.NoShowCount`, ghi `CustomerReputationHistory`.
5. Hóa đơn: nếu MAIN invoice thực sự chưa thu tiền → tự hủy. Nếu đã thanh toán/cọc → KHÔNG tự hủy,
   chỉ đặt `LichDatSan.RequiresRefundReview = 1` + ghi chú hóa đơn cần xử lý hoàn tiền/giữ cọc thủ công.
6. Ghi `AuditLog` (`ACTION_NO_SHOW`).

## 3. Cách tính điểm uy tín

Mỗi tài khoản khách có `Accounts.DiemUyTin` (mặc định 100 — cột này đã tồn tại từ trước, KHÔNG tạo cột
điểm thứ hai). Quy tắc (`Constants.java`):

| Sự kiện | Delta | Bộ đếm tăng |
|---|---|---|
| Hủy sớm (còn > 6 tiếng) | 0 | — |
| Hủy sát giờ (còn ≤ 6 tiếng) | -10 | `LateCancelCount` |
| No Show | -20 | `NoShowCount` |
| Hoàn thành booking | +2 (tối đa 100) | `CompletedBookingCount` |

Điểm luôn được kẹp trong `[MIN_REPUTATION_SCORE=0, MAX_REPUTATION_SCORE=100]`
(`CustomerReputationService.clamp`).

Nhãn hiển thị (`ReputationLabel.of`):
- ≥ 80: "Uy tín tốt"
- 50–79: "Cần theo dõi"
- < 50: "Rủi ro cao" (Manager thấy cảnh báo "Khách hàng này có lịch sử bùng kèo" khi duyệt)

`CustomerReputationHistory` là sổ cái đầy đủ (mọi thay đổi điểm, kèm before/after/reason/actor/ip) —
đây là nguồn giải thích "vì sao điểm bị trừ", tách biệt khỏi bảng `AuditLog` chung (AuditLog ghi lại
*hành động nghiệp vụ* — hủy/no-show — còn CustomerReputationHistory ghi lại *hệ quả điểm số* của hành
động đó; không trùng lặp, hai bảng phục vụ hai câu hỏi khác nhau).

## 4. Idempotency

Mọi thao tác đổi trạng thái là MỘT UPDATE atomic với `WHERE <trạng thái nguồn>`. Phần trừ/cộng điểm chỉ
chạy nếu UPDATE đó ảnh hưởng đúng 1 dòng, trong cùng transaction. Double-click, network retry, hai tab
cùng thao tác một booking → request "thua" thấy 0 dòng ảnh hưởng → không trừ điểm lần hai, trả về thông
báo "đã được hủy/đánh dấu từ trước".

## 5. Nền dữ liệu cho ghép kèo / tìm đối thủ gấp (tương lai)

Chưa code chức năng ghép kèo trong đợt này. Dữ liệu đã sẵn sàng để dùng sau:

- `Accounts.DiemUyTin` — lọc người chơi uy tín khi ghép kèo (vd chỉ ghép với điểm ≥ 50).
- `Accounts.LateCancelCount` / `Accounts.NoShowCount` — cảnh báo người hay bùng kèo trước khi ghép.
- `CustomerReputationHistory` — giải thích chi tiết lịch sử từng lần bị trừ điểm khi hiển thị hồ sơ
  người chơi trong tính năng ghép kèo.
```

- [ ] **Step 2: Commit**

```bash
git add docs/reputation_cancel_flow.md
git commit -m "docs: document new cancel/no-show/reputation flow"
```

---

## Task 18: Manual test checklist + final build verification

**Files:**
- Create: `docs/CANCEL_FLOW_MANUAL_TEST.md`

This is the last task. It also runs the full build verification the user requires before anything can be called done — do this LAST, after every prior task's own `mvn compile`/`test` steps have already passed individually.

- [ ] **Step 1: Write the manual test checklist**

```markdown
# Checklist kiểm thử thủ công — Luồng hủy sân + Điểm uy tín

Chạy dự án bằng `.\start_server.bat` (Windows), đăng nhập bằng tài khoản tương ứng từng vai trò.
Mỗi test case ghi: Role / URL / Dữ liệu chuẩn bị / Các bước / Kết quả mong đợi / SQL kiểm tra / PASS-FAIL.

## 1. Customer hủy sớm
- Role: Khách hàng
- URL: `/customer/dat-san` (mở tab Lịch sử)
- Chuẩn bị: 1 booking trạng thái "Chờ xác nhận" hoặc "Đã xác nhận", giờ chơi còn > 6 tiếng nữa.
- Bước: Bấm "Hủy" → modal hiện không có cảnh báo sát giờ → nhập lý do (tùy chọn) → "Xác nhận hủy".
- Kỳ vọng: Booking chuyển "Đã hủy". Thông báo "Đã hủy đơn đặt sân #X thành công." Điểm uy tín KHÔNG đổi.
- SQL kiểm tra: `SELECT TrangThai, CancelType, CancelledAt FROM LichDatSan WHERE DatSanID = X;`
  `SELECT DiemUyTin, LateCancelCount FROM Accounts WHERE AccountID = Y;` (không đổi so với trước)
- PASS/FAIL: ____

## 2. Customer hủy sát giờ (Late Cancel)
- Role: Khách hàng
- Chuẩn bị: booking còn ≤ 6 tiếng nữa tới giờ chơi, trạng thái "Chờ xác nhận"/"Đã xác nhận".
- Bước: Bấm "Hủy" → modal PHẢI hiện cảnh báo "Bạn vẫn có thể hủy, nhưng đây là hủy sát giờ..." → xác nhận.
- Kỳ vọng: Booking → "Đã hủy", CancelType = LATE_CANCEL. Thông báo nêu rõ đã trừ 10 điểm.
- SQL: `SELECT TrangThai, CancelType FROM LichDatSan WHERE DatSanID = X;`
  `SELECT DiemUyTin, LateCancelCount FROM Accounts WHERE AccountID = Y;` (điểm giảm 10, count +1)
  `SELECT TOP 1 * FROM CustomerReputationHistory WHERE AccountID = Y ORDER BY CreatedAt DESC;`
- PASS/FAIL: ____

## 3. Customer hủy booking đã thanh toán (PayOS)
- Role: Khách hàng
- Chuẩn bị: booking "Đã xác nhận" đã được PayOS webhook xác nhận thanh toán.
- Bước: Bấm "Hủy" → xác nhận.
- Kỳ vọng: Bị chặn với thông báo "Đơn này đã thanh toán PayOS. Vui lòng liên hệ sân...". Booking KHÔNG đổi trạng thái.
- PASS/FAIL: ____

## 4. Customer hủy booking của người khác (IDOR)
- Role: Khách hàng A
- Chuẩn bị: DatSanID thuộc về khách hàng B.
- Bước: Gọi trực tiếp `POST /customer/huy-dat-san` với `id` của booking B (vd qua devtools/curl khi đã đăng nhập A).
- Kỳ vọng: "Bạn không có quyền hủy đơn này." Booking B không đổi.
- PASS/FAIL: ____

## 5. Staff đánh dấu No Show hợp lệ
- Role: Staff (Lễ tân/Bảo vệ)
- URL: `/staff/checkin`
- Chuẩn bị: booking "Đã xác nhận" hôm nay, đã qua giờ bắt đầu + 15 phút, thuộc đúng CoSoID của staff.
- Bước: Bấm nút hủy (icon) trên card booking → modal xác nhận No Show hiện ra, có cảnh báo ảnh hưởng điểm uy tín → "Xác nhận Không đến".
- Kỳ vọng: Booking → "Không đến", NoShowAt được ghi. Điểm uy tín trừ 20, NoShowCount +1.
- SQL: `SELECT TrangThai, NoShowAt FROM LichDatSan WHERE DatSanID = X;`
  `SELECT DiemUyTin, NoShowCount FROM Accounts WHERE AccountID = Y;`
- PASS/FAIL: ____

## 6. Staff cơ sở khác đánh dấu No Show
- Role: Staff cơ sở B
- Chuẩn bị: booking thuộc cơ sở A.
- Bước: Gọi `POST /staff/checkin?action=cancelNoShow&datSanId=X` với booking X thuộc cơ sở A.
- Kỳ vọng: 403 / lỗi "Đơn đặt sân không thuộc cơ sở của bạn." Booking không đổi.
- PASS/FAIL: ____

## 7. Double-click hủy (Customer)
- Role: Khách hàng
- Bước: Mở 2 tab cùng booking, bấm "Xác nhận hủy" gần như đồng thời ở cả 2 tab (hoặc double-click nhanh nút submit).
- Kỳ vọng: Chỉ 1 request thành công. Request thứ hai nhận "Booking đã được hủy trước đó hoặc không còn ở trạng thái có thể hủy." Điểm uy tín CHỈ trừ một lần (nếu là late cancel).
- SQL: `SELECT COUNT(*) FROM CustomerReputationHistory WHERE DatSanID = X;` → phải = 1 (không phải 2).
- PASS/FAIL: ____

## 8. Double-click No Show (Staff)
- Role: Staff
- Bước: Bấm "Xác nhận Không đến" 2 lần liên tiếp thật nhanh (hoặc 2 tab).
- Kỳ vọng: Request thứ hai thất bại với thông báo trạng thái đã thay đổi. Điểm uy tín CHỈ trừ 20 một lần.
- SQL: `SELECT COUNT(*) FROM CustomerReputationHistory WHERE DatSanID = X AND ActionType = 'NO_SHOW';` → = 1.
- PASS/FAIL: ____

## 9. Manager xem điểm uy tín khi duyệt
- Role: Manager
- URL: `/manager/dat-san`
- Chuẩn bị: một khách có DiemUyTin=90 (Uy tín tốt), một khách có 65 (Cần theo dõi), một khách có 40 (Rủi ro cao).
- Bước: Mở trang danh sách đặt sân.
- Kỳ vọng: Mỗi dòng hiện đúng nhãn theo điểm; dòng khách điểm 40 hiện thêm dòng cảnh báo "Khách hàng này có lịch sử bùng kèo...". Manager vẫn bấm Duyệt được bình thường.
- PASS/FAIL: ____

## 10. Booking sau khi hủy không còn chặn khung giờ
- Role: Khách hàng
- Bước: Hủy 1 booking ở một khung giờ/sân cụ thể → thử đặt lại đúng khung giờ/sân đó.
- Kỳ vọng: Đặt lại thành công, không báo trùng lịch (đã hủy nên `TrangThai <> N'Đã hủy'` filter loại nó ra khỏi check trùng — logic có sẵn, không đổi trong đợt này).
- PASS/FAIL: ____

## 11. Booking No Show không cho check-in nữa
- Role: Staff
- Bước: Sau khi đánh dấu No Show ở test 5, thử check-in lại chính booking đó.
- Kỳ vọng: Không check-in được (không còn ở trạng thái "Đã xác nhận" để `NoShowEligibility`/check-in chấp nhận).
- PASS/FAIL: ____

## 12. Audit log ghi nhận thao tác
- Role: Admin/Manager (bất kỳ ai xem được audit log)
- Bước: Sau test 1, 2, 5 — tra bảng AuditLog.
- SQL: `SELECT TOP 10 Action, EntityType, EntityId, Details, CreatedAt FROM AuditLog WHERE EntityType = 'LichDatSan' ORDER BY CreatedAt DESC;`
- Kỳ vọng: Có dòng `CANCEL` cho test 1 và 2, dòng `NO_SHOW` cho test 5, với `Details` mô tả đúng loại hủy.
- PASS/FAIL: ____
```

- [ ] **Step 2: Commit the checklist**

```bash
git add docs/CANCEL_FLOW_MANUAL_TEST.md
git commit -m "docs: add manual test checklist for cancel/no-show/reputation flow"
```

- [ ] **Step 3: Full build verification (run in order, stop and fix on first failure)**

```bash
mvn compile
mvn test-compile
mvn test
mvn package -DskipTests
```

Expected for each: `BUILD SUCCESS`. `mvn test` must show all new tests passing (`ReputationLabelTest`, `CancelDecisionTest`, `CustomerReputationServiceClampTest`, `BookingCancellationServiceEligibilityTest`) alongside the pre-existing suite (`NoShowEligibilityTest`, `CheckInWindowTest`, etc.) with no regressions. Do **not** run the DB-hitting ad-hoc classes at the package root (`FindActiveCheckinsTest`, `RunMigrationTest`, etc.) — they touch the remote DB and are out of scope for this verification.

If any step fails, fix the root cause and re-run from that step — do not proceed to report completion until all four commands succeed.
```

---

## Self-Review Notes (for whoever executes this plan)

- **Spec coverage**: sections 1–4 (business flow + reputation design + DB) → Tasks 1–4; section 5 (customer cancel flow) → Tasks 6, 9, 10, 14; section 6 (No Show flow) → Task 11; section 7 (Manager visibility) → Tasks 8, 15; section 8 (UI) → Tasks 14–16; section 9 (audit log) → Tasks 2, 9, 11; section 10–11 (constraints, idempotency) → enforced structurally in Tasks 8–13 via the atomic-UPDATE-gates-side-effects pattern; section 12 (matchmaking data prep) → `CustomerReputationHistory` + counters (Task 3/4), documented in Task 17; section 13 (tests) → Tasks 5, 6, 7, 9 unit tests + Task 18 manual checklist covering the DB-dependent cases that can't be unit tested without touching the remote DB; section 14 → Task 18; section 16 (no duplicate logic, named constants) → single `CustomerReputationService`/`BookingCancellationService`, all thresholds in `Constants.java`; section 17 (build) → Task 18 Step 3; section 18 (final report) → produce this after Task 18 completes, using the "Report" template in the original request.
- **What is NOT built** (explicitly out of scope per the original request): full matchmaking/ghép kèo feature, QR-at-court, nearest-court location, system-wide mobile UI. Only the data foundation for future matchmaking is laid.
