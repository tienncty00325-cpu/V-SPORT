# Customer Profile Full-Screen Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the sidebar's in-page `#thongtin` toggle section with a standalone, full-screen `/customer/ho-so` profile page matching the target reference layout (cover hero, overlay profile card, Tổng quan/Liên kết tabs, physical info, personalization), backed by real database data with a safe migration path for new fields.

**Architecture:** New `CustomerProfileServlet` (plain JDBC via a new `CustomerProfileDAO`, isolated from the JPA `TaiKhoan` entity to avoid breaking existing `updateAccount()` callers) renders a new standalone `HoSo.jsp`. The existing base-info edit form (name/email/phone/birthday/gender + avatar, with its working email-OTP flow) is relocated verbatim from `TaiKhoan.jsp` into `HoSo.jsp`, keeping its existing backend contract (`/account/update-profile`) untouched. The sidebar's profile card becomes a real link to the new route; the now-dead `#thongtin` section and its JS are removed from `TaiKhoan.jsp`.

**Tech Stack:** Java servlets (Jakarta EE 10, Tomcat 10), JSP + JSTL, plain JDBC (`DBUtil`/HikariCP) for new DAO, existing JPA/Hibernate for unchanged `TaiKhoan` reads, vanilla JS + Tailwind CDN + Be Vietnam Pro font (matching existing customer pages), SQL Server migration scripts.

## Global Constraints

- Do not add `@Column` fields for new profile data to `TaiKhoan.java` (JPA entity) — breaks `updateAccount()` app-wide via `EntityManager.merge()` before migration runs. Use a separate plain-JDBC DAO instead.
- All new SQL must be schema-qualified (`dbo.`), idempotent (`COL_LENGTH`/`OBJECT_ID`/`sys.foreign_keys` guards), wrapped in `SET XACT_ABORT ON` + try/catch transaction, no DROP, no auto-execution.
- No `@Column`/entity changes to `Accounts` mapping.
- Never hard-code `/Backend_java` — always `${pageContext.request.contextPath}`.
- No fabricated data: missing DB values render `-`, never `null`, never a placeholder value implying it's real.
- No RoleID changes, no booking/map/PayOS changes, no git commit unless explicitly asked, no automatic SQL execution against the live DB.
- Uploads: validate MIME type + magic bytes + size limit, UUID filenames, no path traversal, matching `DoiNhomServlet.handleImageUpload`/`UpdateProfileServlet.saveAvatarFile` patterns.
- Font: `'Be Vietnam Pro', 'Inter', system-ui, -apple-system, sans-serif` — no other fonts introduced.
- CSS must be scoped under `.customer-profile-*` classes — no bare `.card`/`button`/`input` selectors.

---

## Task 1: Migration and verify SQL scripts

**Files:**
- Create: `sql/migration_customer_profile.sql`
- Create: `sql/verify_customer_profile.sql`
- Create: `sql/rollback_customer_profile.sql`

**Interfaces:**
- Consumes: existing `dbo.Accounts` table (columns: `AccountID`, plus all columns confirmed present via earlier DB probe: `FullName`, `Email`, `PhoneNumber`, `AvatarUrl`, `NgaySinh`, `GioiTinh`, etc.), existing `dbo.MonTheThao(MonTheThaoID)`.
- Produces: 9 new nullable columns on `dbo.Accounts` that `CustomerProfileDAOImpl` (Task 2) will read/write: `CoverImageUrl`, `ChieuCaoCm`, `CanNangKg`, `GhiChuDacBiet`, `ViTriYeuThich`, `MonTheThaoYeuThichID`, `TrinhDoChoi`, `MucTieuChoi`, `TanSuatChoi`.

- [ ] **Step 1: Write `sql/migration_customer_profile.sql`**

```sql
-- =====================================================================
-- migration_customer_profile.sql
-- Bổ sung các cột hồ sơ cá nhân mở rộng cho Customer (trang /customer/ho-so):
-- cover photo, chiều cao/cân nặng, ghi chú đặc biệt, cá nhân hóa (vị trí
-- yêu thích, môn thể thao + trình độ, mục tiêu, tần suất chơi).
--
-- Idempotent: chạy lại nhiều lần không lỗi (COL_LENGTH/OBJECT_ID/
-- sys.foreign_keys guard trước khi ALTER, theo đúng phong cách các
-- migration hiện có trong repo, vd. migration_team_management.sql).
--
-- Không tự động thực thi — người vận hành phải tự chạy tay trên
-- SQL Server (database QuanLiSport).
-- =====================================================================

USE QuanLiSport;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH('dbo.Accounts', 'CoverImageUrl') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD CoverImageUrl NVARCHAR(500) NULL;
        PRINT N'ADDED Accounts.CoverImageUrl';
    END
    ELSE
        PRINT N'SKIP Accounts.CoverImageUrl (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'ChieuCaoCm') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD ChieuCaoCm INT NULL;
        PRINT N'ADDED Accounts.ChieuCaoCm';
    END
    ELSE
        PRINT N'SKIP Accounts.ChieuCaoCm (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'ChieuCaoCm') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_ChieuCaoCm')
    BEGIN
        ALTER TABLE dbo.Accounts ADD CONSTRAINT CK_Accounts_ChieuCaoCm
            CHECK (ChieuCaoCm IS NULL OR ChieuCaoCm BETWEEN 50 AND 260);
        PRINT N'ADDED CK_Accounts_ChieuCaoCm';
    END
    ELSE
        PRINT N'SKIP CK_Accounts_ChieuCaoCm (đã tồn tại hoặc điều kiện chưa đủ)';

    IF COL_LENGTH('dbo.Accounts', 'CanNangKg') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD CanNangKg INT NULL;
        PRINT N'ADDED Accounts.CanNangKg';
    END
    ELSE
        PRINT N'SKIP Accounts.CanNangKg (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'CanNangKg') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_CanNangKg')
    BEGIN
        ALTER TABLE dbo.Accounts ADD CONSTRAINT CK_Accounts_CanNangKg
            CHECK (CanNangKg IS NULL OR CanNangKg BETWEEN 20 AND 300);
        PRINT N'ADDED CK_Accounts_CanNangKg';
    END
    ELSE
        PRINT N'SKIP CK_Accounts_CanNangKg (đã tồn tại hoặc điều kiện chưa đủ)';

    IF COL_LENGTH('dbo.Accounts', 'GhiChuDacBiet') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD GhiChuDacBiet NVARCHAR(500) NULL;
        PRINT N'ADDED Accounts.GhiChuDacBiet';
    END
    ELSE
        PRINT N'SKIP Accounts.GhiChuDacBiet (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'ViTriYeuThich') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD ViTriYeuThich NVARCHAR(255) NULL;
        PRINT N'ADDED Accounts.ViTriYeuThich';
    END
    ELSE
        PRINT N'SKIP Accounts.ViTriYeuThich (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'MonTheThaoYeuThichID') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD MonTheThaoYeuThichID INT NULL;
        PRINT N'ADDED Accounts.MonTheThaoYeuThichID';
    END
    ELSE
        PRINT N'SKIP Accounts.MonTheThaoYeuThichID (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'MonTheThaoYeuThichID') IS NOT NULL
       AND OBJECT_ID(N'dbo.MonTheThao', N'U') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Accounts_MonTheThaoYeuThich')
    BEGIN
        ALTER TABLE dbo.Accounts ADD CONSTRAINT FK_Accounts_MonTheThaoYeuThich
            FOREIGN KEY (MonTheThaoYeuThichID) REFERENCES dbo.MonTheThao(MonTheThaoID);
        PRINT N'ADDED FK_Accounts_MonTheThaoYeuThich';
    END
    ELSE
        PRINT N'SKIP FK_Accounts_MonTheThaoYeuThich (đã tồn tại hoặc điều kiện chưa đủ)';

    IF COL_LENGTH('dbo.Accounts', 'TrinhDoChoi') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD TrinhDoChoi VARCHAR(30) NULL;
        PRINT N'ADDED Accounts.TrinhDoChoi';
    END
    ELSE
        PRINT N'SKIP Accounts.TrinhDoChoi (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'TrinhDoChoi') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_TrinhDoChoi')
    BEGIN
        ALTER TABLE dbo.Accounts ADD CONSTRAINT CK_Accounts_TrinhDoChoi
            CHECK (TrinhDoChoi IS NULL OR TrinhDoChoi IN (N'Mới chơi', N'Cơ bản', N'Trung bình', N'Khá', N'Nâng cao'));
        PRINT N'ADDED CK_Accounts_TrinhDoChoi';
    END
    ELSE
        PRINT N'SKIP CK_Accounts_TrinhDoChoi (đã tồn tại hoặc điều kiện chưa đủ)';

    IF COL_LENGTH('dbo.Accounts', 'MucTieuChoi') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD MucTieuChoi NVARCHAR(255) NULL;
        PRINT N'ADDED Accounts.MucTieuChoi';
    END
    ELSE
        PRINT N'SKIP Accounts.MucTieuChoi (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'TanSuatChoi') IS NULL
    BEGIN
        ALTER TABLE dbo.Accounts ADD TanSuatChoi VARCHAR(30) NULL;
        PRINT N'ADDED Accounts.TanSuatChoi';
    END
    ELSE
        PRINT N'SKIP Accounts.TanSuatChoi (đã tồn tại)';

    IF COL_LENGTH('dbo.Accounts', 'TanSuatChoi') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_TanSuatChoi')
    BEGIN
        ALTER TABLE dbo.Accounts ADD CONSTRAINT CK_Accounts_TanSuatChoi
            CHECK (TanSuatChoi IS NULL OR TanSuatChoi IN (N'1 lần/tuần', N'2-3 lần/tuần', N'4+ lần/tuần', N'Không cố định'));
        PRINT N'ADDED CK_Accounts_TanSuatChoi';
    END
    ELSE
        PRINT N'SKIP CK_Accounts_TanSuatChoi (đã tồn tại hoặc điều kiện chưa đủ)';

    COMMIT TRANSACTION;
    PRINT N'=== migration_customer_profile.sql: DONE ===';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
```

- [ ] **Step 2: Write `sql/verify_customer_profile.sql`**

```sql
-- =====================================================================
-- verify_customer_profile.sql
-- Kiểm tra schema hồ sơ cá nhân mở rộng sau khi chạy
-- migration_customer_profile.sql. Chỉ đọc (SELECT/PRINT) — không thay
-- đổi dữ liệu.
-- =====================================================================

USE QuanLiSport;
GO

PRINT N'--- 1. Database hiện tại ---';
SELECT DB_NAME() AS CurrentDatabase;
GO

PRINT N'--- 2. Cột mới trên Accounts ---';
SELECT
    COL_LENGTH('dbo.Accounts', 'CoverImageUrl')        AS CoverImageUrl_ColLength,
    COL_LENGTH('dbo.Accounts', 'ChieuCaoCm')            AS ChieuCaoCm_ColLength,
    COL_LENGTH('dbo.Accounts', 'CanNangKg')             AS CanNangKg_ColLength,
    COL_LENGTH('dbo.Accounts', 'GhiChuDacBiet')         AS GhiChuDacBiet_ColLength,
    COL_LENGTH('dbo.Accounts', 'ViTriYeuThich')         AS ViTriYeuThich_ColLength,
    COL_LENGTH('dbo.Accounts', 'MonTheThaoYeuThichID')  AS MonTheThaoYeuThichID_ColLength,
    COL_LENGTH('dbo.Accounts', 'TrinhDoChoi')           AS TrinhDoChoi_ColLength,
    COL_LENGTH('dbo.Accounts', 'MucTieuChoi')           AS MucTieuChoi_ColLength,
    COL_LENGTH('dbo.Accounts', 'TanSuatChoi')           AS TanSuatChoi_ColLength;
GO

PRINT N'--- 3. Check constraints ---';
SELECT name FROM sys.check_constraints
WHERE name IN (N'CK_Accounts_ChieuCaoCm', N'CK_Accounts_CanNangKg', N'CK_Accounts_TrinhDoChoi', N'CK_Accounts_TanSuatChoi');
GO

PRINT N'--- 4. Foreign key MonTheThaoYeuThich ---';
SELECT name FROM sys.foreign_keys WHERE name = N'FK_Accounts_MonTheThaoYeuThich';
GO

PRINT N'--- 5. Số tài khoản đã điền hồ sơ mở rộng (kỳ vọng 0 ngay sau migration lần đầu) ---';
SELECT
    COUNT(CASE WHEN CoverImageUrl IS NOT NULL THEN 1 END) AS CoCoverPhoto,
    COUNT(CASE WHEN ChieuCaoCm IS NOT NULL THEN 1 END) AS CoChieuCao,
    COUNT(CASE WHEN CanNangKg IS NOT NULL THEN 1 END) AS CoCanNang,
    COUNT(CASE WHEN MonTheThaoYeuThichID IS NOT NULL THEN 1 END) AS CoMonYeuThich
FROM dbo.Accounts;
GO

PRINT N'--- verify_customer_profile.sql: DONE ---';
```

- [ ] **Step 3: Write `sql/rollback_customer_profile.sql`**

```sql
-- =====================================================================
-- rollback_customer_profile.sql
-- Hoàn tác migration_customer_profile.sql: xóa constraint rồi cột đã
-- thêm vào Accounts.
--
-- PHẦN 1 chỉ SELECT/PRINT (luôn an toàn). PHẦN 2 mới thực sự DROP và
-- CHỈ chạy khi người vận hành chủ động bật cờ @ConfirmRollback = 1.
--
-- CẢNH BÁO: PHẦN 2 xóa vĩnh viễn dữ liệu hồ sơ mở rộng đã nhập
-- (CoverImageUrl, ChieuCaoCm, CanNangKg, GhiChuDacBiet, ViTriYeuThich,
-- MonTheThaoYeuThichID, TrinhDoChoi, MucTieuChoi, TanSuatChoi). Không có
-- soft-delete cho việc này.
-- =====================================================================

USE QuanLiSport;
GO

SET XACT_ABORT ON;
GO

PRINT N'--- PHẦN 1: Dữ liệu hiện có trước khi rollback ---';
SELECT
    COUNT(CASE WHEN CoverImageUrl IS NOT NULL THEN 1 END) AS CoCoverPhoto,
    COUNT(CASE WHEN ChieuCaoCm IS NOT NULL THEN 1 END) AS CoChieuCao,
    COUNT(CASE WHEN CanNangKg IS NOT NULL THEN 1 END) AS CoCanNang
FROM dbo.Accounts;
GO

DECLARE @ConfirmRollback BIT = 0; -- Đổi thành 1 để thực sự rollback.

IF @ConfirmRollback = 1
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Accounts_MonTheThaoYeuThich')
            ALTER TABLE dbo.Accounts DROP CONSTRAINT FK_Accounts_MonTheThaoYeuThich;

        IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_ChieuCaoCm')
            ALTER TABLE dbo.Accounts DROP CONSTRAINT CK_Accounts_ChieuCaoCm;
        IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_CanNangKg')
            ALTER TABLE dbo.Accounts DROP CONSTRAINT CK_Accounts_CanNangKg;
        IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_TrinhDoChoi')
            ALTER TABLE dbo.Accounts DROP CONSTRAINT CK_Accounts_TrinhDoChoi;
        IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Accounts_TanSuatChoi')
            ALTER TABLE dbo.Accounts DROP CONSTRAINT CK_Accounts_TanSuatChoi;

        IF COL_LENGTH('dbo.Accounts', 'CoverImageUrl') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN CoverImageUrl;
        IF COL_LENGTH('dbo.Accounts', 'ChieuCaoCm') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN ChieuCaoCm;
        IF COL_LENGTH('dbo.Accounts', 'CanNangKg') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN CanNangKg;
        IF COL_LENGTH('dbo.Accounts', 'GhiChuDacBiet') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN GhiChuDacBiet;
        IF COL_LENGTH('dbo.Accounts', 'ViTriYeuThich') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN ViTriYeuThich;
        IF COL_LENGTH('dbo.Accounts', 'MonTheThaoYeuThichID') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN MonTheThaoYeuThichID;
        IF COL_LENGTH('dbo.Accounts', 'TrinhDoChoi') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN TrinhDoChoi;
        IF COL_LENGTH('dbo.Accounts', 'MucTieuChoi') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN MucTieuChoi;
        IF COL_LENGTH('dbo.Accounts', 'TanSuatChoi') IS NOT NULL
            ALTER TABLE dbo.Accounts DROP COLUMN TanSuatChoi;

        COMMIT TRANSACTION;
        PRINT N'=== rollback_customer_profile.sql: DONE ===';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END
ELSE
    PRINT N'PHẦN 2 bị bỏ qua — đặt @ConfirmRollback = 1 để thực sự rollback.';
GO
```

- [ ] **Step 4: Verify SQL syntax by eye (no DB execution)**

Read back all three files, confirm every `ALTER`/`CREATE CONSTRAINT` is guarded, `USE QuanLiSport` matches the app's real database (confirmed earlier via live probe), and no `DROP` runs outside the `@ConfirmRollback = 1` gate in `rollback_customer_profile.sql`. Do not execute any of these files.

- [ ] **Step 5: Commit**

```bash
git add sql/migration_customer_profile.sql sql/verify_customer_profile.sql sql/rollback_customer_profile.sql
git commit -m "$(cat <<'EOF'
sql: add idempotent migration for extended customer profile fields

Adds nullable cover/height/weight/note/personalization columns to
Accounts for the new /customer/ho-so page. Not auto-executed — the
user runs this manually against QuanLiSport.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: CustomerProfileDTO, CustomerProfileDAO, CustomerProfileDAOImpl

**Files:**
- Create: `src/main/java/org/example/dto/CustomerProfileExtraDTO.java`
- Create: `src/main/java/org/example/dao/CustomerProfileDAO.java`
- Create: `src/main/java/org/example/dao/impl/CustomerProfileDAOImpl.java`

**Interfaces:**
- Consumes: `org.example.util.DBUtil.getConnection()` (existing, returns `java.sql.Connection` from HikariCP pool).
- Produces (used by Task 4's `CustomerProfileServlet`):
  - `CustomerProfileExtraDTO CustomerProfileDAO#getExtra(int accountId)` — returns populated DTO, or a DTO with all fields null/zero if no row (never returns `null` itself — `AccountID` always exists).
  - `boolean CustomerProfileDAO#updatePhysical(int accountId, Integer heightCm, Integer weightKg)`
  - `boolean CustomerProfileDAO#updateNote(int accountId, String note)`
  - `boolean CustomerProfileDAO#updatePersonalization(int accountId, String location, Integer sportId, String level, String goal, String frequency)`
  - `boolean CustomerProfileDAO#updateCoverPath(int accountId, String coverPath)`
  - All methods throw `java.sql.SQLException` declared (checked), so the servlet can catch `SQLServerException`/`SQLException` specifically around "migration not run yet" (`Invalid column name`) vs. genuine failures.

- [ ] **Step 1: Write `CustomerProfileExtraDTO.java`**

```java
package org.example.dto;

public class CustomerProfileExtraDTO {
    private String coverImageUrl;
    private Integer heightCm;
    private Integer weightKg;
    private String specialNote;
    private String preferredLocation;
    private Integer favoriteSportId;
    private String favoriteSportName;
    private String skillLevel;
    private String goal;
    private String playFrequency;

    public String getCoverImageUrl() { return coverImageUrl; }
    public void setCoverImageUrl(String coverImageUrl) { this.coverImageUrl = coverImageUrl; }

    public Integer getHeightCm() { return heightCm; }
    public void setHeightCm(Integer heightCm) { this.heightCm = heightCm; }

    public Integer getWeightKg() { return weightKg; }
    public void setWeightKg(Integer weightKg) { this.weightKg = weightKg; }

    public String getSpecialNote() { return specialNote; }
    public void setSpecialNote(String specialNote) { this.specialNote = specialNote; }

    public String getPreferredLocation() { return preferredLocation; }
    public void setPreferredLocation(String preferredLocation) { this.preferredLocation = preferredLocation; }

    public Integer getFavoriteSportId() { return favoriteSportId; }
    public void setFavoriteSportId(Integer favoriteSportId) { this.favoriteSportId = favoriteSportId; }

    public String getFavoriteSportName() { return favoriteSportName; }
    public void setFavoriteSportName(String favoriteSportName) { this.favoriteSportName = favoriteSportName; }

    public String getSkillLevel() { return skillLevel; }
    public void setSkillLevel(String skillLevel) { this.skillLevel = skillLevel; }

    public String getGoal() { return goal; }
    public void setGoal(String goal) { this.goal = goal; }

    public String getPlayFrequency() { return playFrequency; }
    public void setPlayFrequency(String playFrequency) { this.playFrequency = playFrequency; }
}
```

- [ ] **Step 2: Write `CustomerProfileDAO.java` interface**

```java
package org.example.dao;

import org.example.dto.CustomerProfileExtraDTO;

import java.sql.SQLException;

/**
 * DAO riêng cho các trường hồ sơ Customer mở rộng (cover, thể chất, cá nhân
 * hóa) sống trên các cột mới của Accounts do sql/migration_customer_profile.sql
 * thêm vào. Cố tình KHÔNG dùng chung JPA entity TaiKhoan — TaiKhoanDAOImpl.
 * updateAccount() dùng EntityManager.merge() cập nhật toàn bộ entity, nên nếu
 * thêm cột mới vào entity đó sẽ làm hỏng mọi luồng cập nhật tài khoản hiện có
 * (admin/manager/staff/customer) trước khi migration được chạy. DAO này dùng
 * JDBC thuần, độc lập hoàn toàn với luồng đó.
 */
public interface CustomerProfileDAO {
    CustomerProfileExtraDTO getExtra(int accountId) throws SQLException;
    boolean updatePhysical(int accountId, Integer heightCm, Integer weightKg) throws SQLException;
    boolean updateNote(int accountId, String note) throws SQLException;
    boolean updatePersonalization(int accountId, String location, Integer sportId, String level, String goal, String frequency) throws SQLException;
    boolean updateCoverPath(int accountId, String coverPath) throws SQLException;
}
```

- [ ] **Step 3: Write `CustomerProfileDAOImpl.java`**

```java
package org.example.dao.impl;

import org.example.dao.CustomerProfileDAO;
import org.example.dto.CustomerProfileExtraDTO;
import org.example.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

public class CustomerProfileDAOImpl implements CustomerProfileDAO {

    @Override
    public CustomerProfileExtraDTO getExtra(int accountId) throws SQLException {
        String sql = "SELECT a.CoverImageUrl, a.ChieuCaoCm, a.CanNangKg, a.GhiChuDacBiet, a.ViTriYeuThich, " +
                "a.MonTheThaoYeuThichID, mt.TenMon AS FavoriteSportName, a.TrinhDoChoi, a.MucTieuChoi, a.TanSuatChoi " +
                "FROM dbo.Accounts a " +
                "LEFT JOIN dbo.MonTheThao mt ON mt.MonTheThaoID = a.MonTheThaoYeuThichID " +
                "WHERE a.AccountID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                CustomerProfileExtraDTO dto = new CustomerProfileExtraDTO();
                if (rs.next()) {
                    dto.setCoverImageUrl(rs.getString("CoverImageUrl"));
                    int height = rs.getInt("ChieuCaoCm");
                    dto.setHeightCm(rs.wasNull() ? null : height);
                    int weight = rs.getInt("CanNangKg");
                    dto.setWeightKg(rs.wasNull() ? null : weight);
                    dto.setSpecialNote(rs.getString("GhiChuDacBiet"));
                    dto.setPreferredLocation(rs.getString("ViTriYeuThich"));
                    int sportId = rs.getInt("MonTheThaoYeuThichID");
                    dto.setFavoriteSportId(rs.wasNull() ? null : sportId);
                    dto.setFavoriteSportName(rs.getString("FavoriteSportName"));
                    dto.setSkillLevel(rs.getString("TrinhDoChoi"));
                    dto.setGoal(rs.getString("MucTieuChoi"));
                    dto.setPlayFrequency(rs.getString("TanSuatChoi"));
                }
                return dto;
            }
        }
    }

    @Override
    public boolean updatePhysical(int accountId, Integer heightCm, Integer weightKg) throws SQLException {
        String sql = "UPDATE dbo.Accounts SET ChieuCaoCm = ?, CanNangKg = ? WHERE AccountID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            if (heightCm != null) ps.setInt(1, heightCm); else ps.setNull(1, Types.INTEGER);
            if (weightKg != null) ps.setInt(2, weightKg); else ps.setNull(2, Types.INTEGER);
            ps.setInt(3, accountId);
            return ps.executeUpdate() > 0;
        }
    }

    @Override
    public boolean updateNote(int accountId, String note) throws SQLException {
        String sql = "UPDATE dbo.Accounts SET GhiChuDacBiet = ? WHERE AccountID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            if (note != null) ps.setString(1, note); else ps.setNull(1, Types.NVARCHAR);
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        }
    }

    @Override
    public boolean updatePersonalization(int accountId, String location, Integer sportId, String level, String goal, String frequency) throws SQLException {
        String sql = "UPDATE dbo.Accounts SET ViTriYeuThich = ?, MonTheThaoYeuThichID = ?, TrinhDoChoi = ?, MucTieuChoi = ?, TanSuatChoi = ? WHERE AccountID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            if (location != null) ps.setString(1, location); else ps.setNull(1, Types.NVARCHAR);
            if (sportId != null) ps.setInt(2, sportId); else ps.setNull(2, Types.INTEGER);
            if (level != null) ps.setString(3, level); else ps.setNull(3, Types.VARCHAR);
            if (goal != null) ps.setString(4, goal); else ps.setNull(4, Types.NVARCHAR);
            if (frequency != null) ps.setString(5, frequency); else ps.setNull(5, Types.VARCHAR);
            ps.setInt(6, accountId);
            return ps.executeUpdate() > 0;
        }
    }

    @Override
    public boolean updateCoverPath(int accountId, String coverPath) throws SQLException {
        String sql = "UPDATE dbo.Accounts SET CoverImageUrl = ? WHERE AccountID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, coverPath);
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        }
    }
}
```

- [ ] **Step 4: Compile check**

Run: `mvn -q compile 2>&1 | tail -100`
Expected: no output (clean compile). If errors reference `CustomerProfileDAO`/`Impl`/`DTO`, fix signatures to match exactly what's shown above before proceeding.

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/dto/CustomerProfileExtraDTO.java \
        src/main/java/org/example/dao/CustomerProfileDAO.java \
        src/main/java/org/example/dao/impl/CustomerProfileDAOImpl.java
git commit -m "$(cat <<'EOF'
feat: add CustomerProfileDAO for extended profile fields

Plain-JDBC DAO isolated from the JPA TaiKhoan entity so reads/writes
against the new Accounts columns never interfere with existing
updateAccount() callers before the migration has run.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Global error page reuse check (no new code — verification only)

**Files:** none created or modified.

**Interfaces:**
- Consumes: `src/main/webapp/Error.jsp` and the `<error-page>` entries in `src/main/webapp/WEB-INF/web.xml` (both already exist from the earlier Team-module fix).

- [ ] **Step 1: Confirm the existing global error page is still in place**

Run: `grep -n "error-page" -A2 src/main/webapp/WEB-INF/web.xml`
Expected: two `<error-page>` blocks pointing at `/Error.jsp` (one for `java.lang.Throwable`, one for error-code `500`). If present, no action needed — Task 5's servlet will rely on this as the last-resort safety net, matching `DoiNhomServlet`'s existing pattern of catching `RuntimeException` itself first and only letting truly unexpected errors reach `Error.jsp`.

---

## Task 4: HoSo.jsp — page shell, cover hero, overlay profile card (base info, no personalization yet)

**Files:**
- Create: `src/main/webapp/customer/HoSo.jsp`

**Interfaces:**
- Consumes (request attributes set by `CustomerProfileServlet` in Task 5): `account` (`org.example.model.TaiKhoan`), `profileExtra` (`org.example.dto.CustomerProfileExtraDTO`, may have all-null fields if migration hasn't run), `dsMon` (`List<org.example.model.MonTheThao>`), `myTeams` (`List<org.example.dto.TeamSummaryDTO>`).
- Produces: standalone page reachable at `/customer/ho-so`, with `data-error-for`/`id` contracts documented inline for Task 5 (JS `fetch` targets) and Task 6 (personalization tab content, added into the same file).

This task builds the page shell + hero + overlay card + relocated base-info edit
form. Task 6 (same file) adds the tab switcher content. Splitting this way keeps
each edit self-contained and testable: after this task, the page must load and
show read/edit of base info; after Task 6, physical/note/personalization/teams
render too.

- [ ] **Step 1: Write `HoSo.jsp` (page shell + hero + overlay card + relocated edit form)**

```jsp
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html lang="vi" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hồ sơ cá nhân - V-SPORT</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <jsp:include page="/common/head.jsp" />
    <jsp:include page="/customer/common/vsport-theme.jsp" />
    <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Be Vietnam Pro', 'Inter', system-ui, -apple-system, sans-serif !important;
            background-color: #F4F7FB !important;
            color: #102A43 !important;
            margin: 0;
        }
        .customer-profile-page { max-width: 1648px; margin: 0 auto; padding-bottom: 32px; }
        .customer-profile-hero {
            position: relative;
            width: 100%;
            height: 170px;
            background: linear-gradient(135deg, var(--vs-primary-900, #0B2545), var(--vs-cyan-500, #18C8E8));
            border-radius: 0 0 18px 18px;
            overflow: hidden;
        }
        .customer-profile-hero-img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; }
        .customer-profile-hero-overlay { position: absolute; inset: 0; background: rgba(11, 37, 69, 0.28); }
        .customer-profile-icon-btn {
            position: absolute; top: 12px; width: 36px; height: 36px; border-radius: 50%;
            background: rgba(11, 37, 69, 0.55); color: #fff; display: flex; align-items: center; justify-content: center;
            border: none; cursor: pointer; z-index: 2;
        }
        .customer-profile-icon-btn:hover { background: rgba(11, 37, 69, 0.75); }
        .customer-profile-icon-btn .lci { width: 18px; height: 18px; }
        #chpBackBtn { left: 12px; }
        #chpCoverBtn { right: 12px; }

        .customer-profile-card {
            position: relative; z-index: 3;
            margin: -60px 12px 0;
            background: rgba(255, 255, 255, 0.92);
            backdrop-filter: blur(6px);
            border: 1px solid rgba(220, 229, 239, 0.8);
            border-radius: 12px;
            min-height: 100px;
            padding: 16px 20px;
            display: flex; align-items: center; gap: 20px; flex-wrap: wrap;
        }
        .customer-profile-avatar-wrap { position: relative; flex-shrink: 0; }
        .customer-profile-avatar {
            width: 52px; height: 52px; border-radius: 50%; object-fit: cover;
            background: var(--vs-primary-600, #1677D2); color: #fff;
            display: flex; align-items: center; justify-content: center;
            font-size: 20px; font-weight: 800; border: 2px solid #fff;
        }
        .customer-profile-avatar-cam {
            position: absolute; bottom: -2px; right: -2px; width: 22px; height: 22px; border-radius: 50%;
            background: var(--vs-primary-600, #1677D2); color: #fff; border: 2px solid #fff;
            display: flex; align-items: center; justify-content: center; cursor: pointer;
        }
        .customer-profile-avatar-cam .lci { width: 12px; height: 12px; }
        .customer-profile-identity { min-width: 0; }
        .customer-profile-name { font-size: 19px; font-weight: 700; color: #102A43; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 260px; }
        .customer-profile-email-pill {
            display: inline-flex; align-items: center; gap: 5px; margin-top: 4px;
            background: #EEF7FC; border-radius: 999px; padding: 3px 10px;
            font-size: 10.5px; color: #33544a; max-width: 240px;
        }
        .customer-profile-email-pill span { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .customer-profile-email-pill .lci { width: 12px; height: 12px; flex-shrink: 0; }
        .customer-profile-facts { display: flex; gap: 28px; margin-left: auto; flex-wrap: wrap; }
        .customer-profile-fact { text-align: center; min-width: 72px; }
        .customer-profile-fact .lci { width: 15px; height: 15px; color: var(--vs-primary-600, #1677D2); }
        .customer-profile-fact-label { font-size: 10.5px; font-weight: 700; color: #829AB1; text-transform: uppercase; letter-spacing: .03em; margin-top: 2px; }
        .customer-profile-fact-value { font-size: 13px; font-weight: 700; color: #102A43; margin-top: 1px; }
        .customer-profile-edit-btn {
            display: inline-flex; align-items: center; gap: 6px; padding: 7px 12px;
            background: #fff; border: 1px solid var(--vs-primary-600, #1677D2); color: var(--vs-primary-900, #0B2545);
            border-radius: 8px; font-size: 12.5px; font-weight: 700; cursor: pointer; font-family: inherit;
        }
        .customer-profile-edit-btn:hover { background: #F0FCFE; }
        .customer-profile-edit-btn .lci { width: 14px; height: 14px; }

        .customer-profile-tabs {
            display: flex; margin: 14px 12px 0; background: var(--vs-primary-900, #0B2545);
            border-radius: 8px; padding: 3px; gap: 3px; height: 36px;
        }
        .customer-profile-tab {
            flex: 1; border: none; background: transparent; color: rgba(255,255,255,.85);
            font-family: inherit; font-size: 13.5px; font-weight: 700; border-radius: 7px; cursor: pointer;
        }
        .customer-profile-tab.is-active { background: #fff; color: var(--vs-primary-900, #0B2545); }

        .customer-profile-section-wrap { margin: 12px; background: #fff; border-radius: 12px; padding: 22px; min-height: 320px; }
        .customer-profile-section + .customer-profile-section { margin-top: 26px; }
        .customer-profile-section-header { display: flex; align-items: center; justify-content: between; margin-bottom: 10px; }
        .customer-profile-section-title { font-size: 14.5px; font-weight: 700; color: var(--vs-primary-900, #0B2545); flex: 1; }
        .customer-profile-section-edit { background: none; border: none; cursor: pointer; color: #829AB1; padding: 4px; }
        .customer-profile-section-edit .lci { width: 16px; height: 16px; }
        .customer-profile-divider { border: none; border-top: 1px solid #EEF1F5; margin: 10px 0 16px; }

        .customer-profile-physical-row { display: flex; }
        .customer-profile-physical-col { flex: 1; text-align: center; padding: 10px 0; }
        .customer-profile-physical-col + .customer-profile-physical-col { border-left: 1px solid #EEF1F5; }
        .customer-profile-physical-label { font-size: 11px; color: #829AB1; font-weight: 700; }
        .customer-profile-physical-value { font-size: 18px; font-weight: 700; color: #102A43; margin-top: 4px; }

        .customer-profile-note-row { display: flex; align-items: flex-start; gap: 10px; padding: 4px 0; }
        .customer-profile-note-row .lci { width: 17px; height: 17px; color: var(--vs-primary-600, #1677D2); margin-top: 2px; flex-shrink: 0; }
        .customer-profile-note-text { font-size: 13px; color: #33544a; }
        .customer-profile-note-placeholder { font-size: 13px; color: #829AB1; }

        .customer-profile-perso-row { display: flex; align-items: center; gap: 12px; padding: 9px 0; border-bottom: 1px solid #F6F8FA; }
        .customer-profile-perso-row:last-child { border-bottom: none; }
        .customer-profile-perso-row .lci { width: 17px; height: 17px; color: var(--vs-primary-600, #1677D2); flex-shrink: 0; }
        .customer-profile-perso-label { font-size: 13px; color: #33544a; flex: 1; }
        .customer-profile-perso-value { font-size: 13px; font-weight: 600; color: #102A43; }

        .customer-profile-team-item { display: flex; align-items: center; gap: 12px; padding: 12px; border: 1px solid #EEF1F5; border-radius: 10px; }
        .customer-profile-team-item + .customer-profile-team-item { margin-top: 10px; }
        .customer-profile-team-avatar { width: 40px; height: 40px; border-radius: 50%; object-fit: cover; background: var(--vs-primary-600, #1677D2); color: #fff; display: flex; align-items: center; justify-content: center; font-weight: 700; flex-shrink: 0; }
        .customer-profile-team-name { font-size: 13.5px; font-weight: 700; color: #102A43; }
        .customer-profile-team-meta { font-size: 11.5px; color: #829AB1; }
        .customer-profile-empty { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 48px 0; color: #829AB1; }
        .customer-profile-empty .lci { width: 40px; height: 40px; margin-bottom: 10px; }
        .customer-profile-empty p { font-size: 13.5px; }

        @media (max-width: 767px) {
            .customer-profile-hero { height: 200px; }
            .customer-profile-card { flex-direction: column; align-items: flex-start; margin-top: -70px; }
            .customer-profile-facts { margin-left: 0; width: 100%; justify-content: space-between; }
        }

        /* Relocated from TaiKhoan.jsp: base-info view/edit form styling */
        .info-card { background: #fff; border-radius: 0; padding: 0; }
        .acc-field-view dt { font-size: 12px; font-weight: 700; color: #829AB1; text-transform: uppercase; letter-spacing: .03em; margin-bottom: 4px; }
        .acc-field-view dd { font-size: 14.5px; font-weight: 600; color: #102A43; }
        .acc-input {
            width: 100%; height: 44px; padding: 0 14px; border-radius: 8px;
            border: 1px solid #DCE5EF; background: #fff; font-size: 14px; color: #102A43;
            font-family: inherit;
        }
        .acc-input:focus { outline: none; border-color: #18C8E8; box-shadow: 0 0 0 3px rgba(24, 200, 232, .22); }
        .acc-label { display: block; font-size: 12.5px; font-weight: 700; color: #33544a; margin-bottom: 6px; }
        .btn-primary {
            display: inline-flex; align-items: center; justify-content: center; gap: 7px;
            background: var(--vs-primary-600, #1677D2); color: #fff; font-weight: 700; font-size: 14px;
            padding: 11px 18px; border-radius: 8px; text-decoration: none; cursor: pointer;
            font-family: inherit; border: none;
        }
        .btn-primary:hover { background: var(--vs-primary-700, #185A9D); }
        .btn-primary:disabled { opacity: .6; cursor: not-allowed; }
        .btn-secondary {
            display: inline-flex; align-items: center; justify-content: center; gap: 7px;
            background: #fff; color: #33544a; font-weight: 700; font-size: 14px;
            padding: 11px 18px; border-radius: 8px; border: 1px solid #DCE5EF;
            cursor: pointer; font-family: inherit;
        }
        .btn-secondary:hover { background: #f8fbf9; }
    </style>
</head>
<body class="antialiased">

<div class="customer-profile-page">

    <div class="customer-profile-hero">
        <c:if test="${not empty profileExtra.coverImageUrl}">
            <img class="customer-profile-hero-img" src="${pageContext.request.contextPath}${profileExtra.coverImageUrl}" alt="Ảnh bìa">
        </c:if>
        <div class="customer-profile-hero-overlay"></div>
        <button type="button" id="chpBackBtn" class="customer-profile-icon-btn" aria-label="Quay lại tài khoản" onclick="location.href = CTX + '/customer/tai-khoan';">
            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
        </button>
        <button type="button" id="chpCoverBtn" class="customer-profile-icon-btn" aria-label="Đổi ảnh bìa" onclick="document.getElementById('chpCoverInput').click();">
            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/></svg>
        </button>
        <input id="chpCoverInput" type="file" accept="image/jpeg,image/png,image/webp" class="hidden">
    </div>

    <div class="customer-profile-card">
        <div class="customer-profile-avatar-wrap">
            <c:choose>
                <c:when test="${not empty account.avatarUrl}">
                    <img id="chpAvatarPreview" class="customer-profile-avatar js-avatar-img" src="${pageContext.request.contextPath}${account.avatarUrl}" alt="Ảnh đại diện">
                </c:when>
                <c:otherwise>
                    <span id="chpAvatarInitial" class="customer-profile-avatar js-avatar-initial" aria-hidden="true"><c:choose><c:when test="${not empty account.fullName}">${fn:escapeXml(fn:substring(account.fullName, 0, 1))}</c:when><c:otherwise>${fn:escapeXml(fn:substring(account.username, 0, 1))}</c:otherwise></c:choose></span>
                    <img id="chpAvatarPreview" class="customer-profile-avatar js-avatar-img" src="" alt="Ảnh đại diện" hidden>
                </c:otherwise>
            </c:choose>
            <label for="accAvatarInput" class="customer-profile-avatar-cam" aria-label="Đổi ảnh đại diện">
                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/><circle cx="12" cy="13" r="3"/></svg>
            </label>
            <input id="accAvatarInput" type="file" accept="image/jpeg,image/png,image/webp,image/gif" class="hidden">
        </div>
        <div class="customer-profile-identity">
            <div id="chpName" class="customer-profile-name">${fn:escapeXml(not empty account.fullName ? account.fullName : account.username)}</div>
            <div class="customer-profile-email-pill">
                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>
                <span id="chpEmail">${not empty account.email ? fn:escapeXml(account.email) : 'Chưa cập nhật email'}</span>
            </div>
        </div>
        <div class="customer-profile-facts">
            <div class="customer-profile-fact">
                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384"/></svg>
                <div class="customer-profile-fact-label">Điện thoại</div>
                <div id="chpPhone" class="customer-profile-fact-value">${not empty account.phoneNumber ? fn:escapeXml(account.phoneNumber) : '-'}</div>
            </div>
            <div class="customer-profile-fact">
                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/></svg>
                <div class="customer-profile-fact-label">Năm sinh</div>
                <div id="chpBirthYear" class="customer-profile-fact-value">
                    <c:choose>
                        <c:when test="${account.ngaySinh != null}"><fmt:formatDate value="${account.ngaySinh}" pattern="yyyy"/></c:when>
                        <c:otherwise>-</c:otherwise>
                    </c:choose>
                </div>
            </div>
            <div class="customer-profile-fact">
                <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="5"/><path d="M20 21a8 8 0 0 0-16 0"/></svg>
                <div class="customer-profile-fact-label">Giới tính</div>
                <div id="chpGender" class="customer-profile-fact-value">${not empty account.gioiTinh ? fn:escapeXml(account.gioiTinh) : '-'}</div>
            </div>
        </div>
        <button type="button" class="customer-profile-edit-btn" onclick="openBaseInfoEdit()">
            <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/></svg>
            Chỉnh sửa
        </button>
    </div>

    <div class="customer-profile-tabs" role="tablist">
        <button type="button" class="customer-profile-tab is-active" id="chpTabOverviewBtn" role="tab" aria-selected="true" onclick="chpSwitchTab('overview')">Tổng quan</button>
        <button type="button" class="customer-profile-tab" id="chpTabLinksBtn" role="tab" aria-selected="false" onclick="chpSwitchTab('links')">Liên kết</button>
    </div>

    <!-- Tổng quan tab content is added in Task 6 -->
    <div id="chpTabOverview" class="customer-profile-tab-panel"></div>
    <div id="chpTabLinks" class="customer-profile-tab-panel hidden"></div>

</div>

<!-- Base info edit modal (relocated from TaiKhoan.jsp #thongtin section) -->
<div id="chpBaseInfoModal" class="hidden fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[300] flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-[560px] border border-slate-200 max-h-[90vh] overflow-y-auto">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <h3 class="text-sm font-extrabold" style="color:#102A43;">Chỉnh sửa thông tin cá nhân</h3>
            <button type="button" onclick="closeModal('chpBaseInfoModal')" class="w-8 h-8 rounded-full hover:bg-slate-100 flex items-center justify-center" aria-label="Đóng">
                <svg class="lci text-slate-500" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
        </div>
        <form id="infoEditForm" class="px-6 py-5 grid grid-cols-1 sm:grid-cols-2 gap-4" onsubmit="return false;" autocomplete="off">
            <div>
                <label class="acc-label" for="editFullName">Họ và tên</label>
                <input id="editFullName" type="text" class="acc-input" value="${fn:escapeXml(account.fullName)}" maxlength="100">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="fullName"></p>
            </div>
            <div>
                <label class="acc-label" for="editEmail">Email</label>
                <input id="editEmail" type="email" class="acc-input" value="${fn:escapeXml(account.email)}">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="email"></p>
            </div>
            <div>
                <label class="acc-label" for="editPhone">Số điện thoại</label>
                <input id="editPhone" type="tel" class="acc-input" value="${fn:escapeXml(account.phoneNumber)}">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="phone"></p>
            </div>
            <div>
                <label class="acc-label" for="editBirthday">Ngày sinh</label>
                <input id="editBirthday" type="date" class="acc-input" value="<c:if test="${account.ngaySinh != null}"><fmt:formatDate value="${account.ngaySinh}" pattern="yyyy-MM-dd"/></c:if>">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="birthday"></p>
            </div>
            <div>
                <label class="acc-label" for="editGender">Giới tính</label>
                <select id="editGender" class="acc-input">
                    <option value="" ${empty account.gioiTinh ? 'selected' : ''}>-- Không chọn --</option>
                    <option value="Nam" ${account.gioiTinh == 'Nam' ? 'selected' : ''}>Nam</option>
                    <option value="Nữ" ${account.gioiTinh == 'Nữ' ? 'selected' : ''}>Nữ</option>
                    <option value="Khác" ${account.gioiTinh == 'Khác' ? 'selected' : ''}>Khác</option>
                </select>
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="gender"></p>
            </div>
            <div class="sm:col-span-2 flex justify-end gap-3 pt-2">
                <button type="button" onclick="closeModal('chpBaseInfoModal')" class="btn-secondary">Hủy</button>
                <button type="button" id="saveInfoBtn" onclick="saveProfileInfo()" class="btn-primary">Lưu thay đổi</button>
            </div>
        </form>
    </div>
</div>

<!-- Email OTP modal (relocated from TaiKhoan.jsp) -->
<div id="emailOtpModal" class="hidden fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[300] flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-[400px] border border-slate-200">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <h3 class="text-sm font-extrabold flex items-center gap-2" style="color:#102A43;">
                <svg class="lci" style="color:#1677D2;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 13V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v12c0 1.1.9 2 2 2h8"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/><path d="m16 19 2 2 4-4"/></svg>
                Xác thực email mới
            </h3>
            <button type="button" onclick="closeModal('emailOtpModal')" class="w-8 h-8 rounded-full hover:bg-slate-100 flex items-center justify-center" aria-label="Đóng">
                <svg class="lci text-slate-500" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
        </div>
        <div class="px-6 py-5">
            <p class="text-sm text-slate-600">Mã OTP đã được gửi đến <strong id="otpTargetEmail" class="text-slate-900"></strong>. Nhập mã để hoàn tất thay đổi.</p>
            <input id="otpInput" type="text" maxlength="6" inputmode="numeric" placeholder="••••••" class="acc-input mt-4 text-center text-xl font-black tracking-[0.3em]">
            <p id="otpError" class="hidden mt-2 text-[12px] font-semibold text-red-600"></p>
        </div>
        <div class="px-6 pb-5 flex justify-end gap-3">
            <button type="button" onclick="closeModal('emailOtpModal')" class="btn-secondary">Hủy</button>
            <button type="button" id="otpConfirmBtn" onclick="verifyEmailOtp()" class="btn-primary">Xác thực</button>
        </div>
    </div>
</div>

<!-- Toast (relocated from TaiKhoan.jsp) -->
<div id="accToast" class="hidden fixed bottom-6 right-6 z-[999] max-w-sm bg-white border border-slate-200 shadow-lg rounded-xl px-4 py-3 flex items-start gap-3 opacity-0 translate-y-3">
    <span id="accToastIconOk" class="mt-0.5 text-emerald-600"><svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/></svg></span>
    <span id="accToastIconErr" class="mt-0.5 text-red-500 hidden"><svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" x2="12" y1="8" y2="12"/><line x1="12" x2="12.01" y1="16" y2="16"/></svg></span>
    <div>
        <p id="accToastTitle" class="text-sm font-bold" style="color:#102A43;">Thành công</p>
        <p id="accToastMessage" class="text-xs mt-0.5" style="color:#829AB1;"></p>
    </div>
</div>

<script>
    const CTX = '${pageContext.request.contextPath}';
    const birthdayInput = document.getElementById('editBirthday');
    if (birthdayInput) birthdayInput.max = new Date().toISOString().split('T')[0];

    function chpSwitchTab(tab) {
        document.getElementById('chpTabOverviewBtn').classList.toggle('is-active', tab === 'overview');
        document.getElementById('chpTabOverviewBtn').setAttribute('aria-selected', tab === 'overview');
        document.getElementById('chpTabLinksBtn').classList.toggle('is-active', tab === 'links');
        document.getElementById('chpTabLinksBtn').setAttribute('aria-selected', tab === 'links');
        document.getElementById('chpTabOverview').classList.toggle('hidden', tab !== 'overview');
        document.getElementById('chpTabLinks').classList.toggle('hidden', tab !== 'links');
    }

    function openModal(id) { document.getElementById(id).classList.remove('hidden'); }
    function closeModal(id) { document.getElementById(id).classList.add('hidden'); }
    document.querySelectorAll('#chpBaseInfoModal, #emailOtpModal').forEach(overlay => {
        overlay.addEventListener('click', (e) => { if (e.target === overlay) closeModal(overlay.id); });
    });
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') { closeModal('chpBaseInfoModal'); closeModal('emailOtpModal'); }
    });

    function openBaseInfoEdit() { openModal('chpBaseInfoModal'); }

    // ---- Toast ----
    function showToast(title, message, isError) {
        const toast = document.getElementById('accToast');
        document.getElementById('accToastTitle').textContent = title;
        document.getElementById('accToastMessage').textContent = message || '';
        document.getElementById('accToastIconOk').classList.toggle('hidden', !!isError);
        document.getElementById('accToastIconErr').classList.toggle('hidden', !isError);
        toast.classList.remove('hidden');
        requestAnimationFrame(() => { toast.classList.remove('opacity-0', 'translate-y-3'); });
        clearTimeout(window.__accToastTimer);
        window.__accToastTimer = setTimeout(() => {
            toast.classList.add('opacity-0', 'translate-y-3');
            setTimeout(() => toast.classList.add('hidden'), 250);
        }, 4000);
    }

    function clearFieldErrors(scopeEl) {
        scopeEl.querySelectorAll('[data-error-for]').forEach(el => { el.textContent = ''; el.classList.add('hidden'); });
    }
    function showFieldErrors(scopeEl, fieldErrors) {
        clearFieldErrors(scopeEl);
        if (!fieldErrors) return;
        Object.keys(fieldErrors).forEach(key => {
            const el = scopeEl.querySelector('[data-error-for="' + key + '"]');
            if (el) { el.textContent = fieldErrors[key]; el.classList.remove('hidden'); }
        });
    }

    function formatDateVn(iso) {
        const parts = iso.split('-');
        return parts.length === 3 ? (parts[2] + '/' + parts[1] + '/' + parts[0]) : iso;
    }

    // ---- Save base profile info (relocated from TaiKhoan.jsp saveProfileInfo) ----
    function saveProfileInfo() {
        const fullName = document.getElementById('editFullName').value;
        const email = document.getElementById('editEmail').value;
        const phone = document.getElementById('editPhone').value;
        const birthday = document.getElementById('editBirthday').value;
        const gender = document.getElementById('editGender').value;

        const btn = document.getElementById('saveInfoBtn');
        btn.disabled = true;
        const originalText = btn.textContent;
        btn.textContent = 'Đang lưu...';

        const params = new URLSearchParams();
        params.append('action', 'updateInfo');
        params.append('fullName', fullName);
        params.append('email', email);
        params.append('phoneNumber', phone);
        params.append('birthday', birthday);
        params.append('gender', gender);

        fetch(CTX + '/account/update-profile', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: params
        })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                btn.textContent = originalText;
                if (data.success) {
                    if (data.requiresOtp) {
                        document.getElementById('otpTargetEmail').textContent = data.email || email;
                        document.getElementById('otpInput').value = '';
                        document.getElementById('otpError').classList.add('hidden');
                        openModal('emailOtpModal');
                        showToast('Đã gửi mã OTP', data.message);
                        return;
                    }
                    syncProfileUi(data);
                    closeModal('chpBaseInfoModal');
                    showToast('Thành công', 'Đã cập nhật thông tin cá nhân.');
                } else if (data.code === 'VALIDATION_ERROR') {
                    showFieldErrors(document.getElementById('infoEditForm'), data.fieldErrors);
                } else {
                    showToast('Không thể cập nhật', data.message, true);
                }
            })
            .catch(() => {
                btn.disabled = false;
                btn.textContent = originalText;
                showToast('Lỗi kết nối', 'Không thể kết nối máy chủ. Vui lòng thử lại.', true);
            });
    }

    function verifyEmailOtp() {
        const otp = document.getElementById('otpInput').value.trim();
        const err = document.getElementById('otpError');
        if (!/^\d{6}$/.test(otp)) {
            err.textContent = 'Vui lòng nhập mã OTP gồm 6 chữ số.';
            err.classList.remove('hidden');
            return;
        }
        const btn = document.getElementById('otpConfirmBtn');
        btn.disabled = true;

        const params = new URLSearchParams();
        params.append('action', 'verifyEmailOtp');
        params.append('otp', otp);

        fetch(CTX + '/account/update-profile', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: params
        })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                if (data.success) {
                    syncProfileUi(data);
                    closeModal('emailOtpModal');
                    closeModal('chpBaseInfoModal');
                    showToast('Thành công', 'Đã cập nhật thông tin cá nhân.');
                } else {
                    err.textContent = data.message || 'Không thể xác thực OTP.';
                    err.classList.remove('hidden');
                }
            })
            .catch(() => {
                btn.disabled = false;
                err.textContent = 'Lỗi kết nối. Vui lòng thử lại.';
                err.classList.remove('hidden');
            });
    }

    function syncProfileUi(data) {
        document.getElementById('chpName').textContent = data.fullName || '-';
        document.getElementById('chpEmail').textContent = data.email || 'Chưa cập nhật email';
        document.getElementById('chpPhone').textContent = data.phoneNumber || '-';
        document.getElementById('chpBirthYear').textContent = data.birthday ? data.birthday.split('-')[0] : '-';
        document.getElementById('chpGender').textContent = data.gender || '-';

        document.getElementById('editFullName').value = data.fullName || '';
        document.getElementById('editEmail').value = data.email || '';
        document.getElementById('editPhone').value = data.phoneNumber || '';
        document.getElementById('editBirthday').value = data.birthday || '';
        document.getElementById('editGender').value = data.gender || '';
    }

    // ---- Avatar upload (relocated from TaiKhoan.jsp) ----
    document.getElementById('accAvatarInput').addEventListener('change', function () {
        const file = this.files && this.files[0];
        if (!file) return;

        if (file.size > 2 * 1024 * 1024) {
            showToast('Ảnh quá lớn', 'Vui lòng chọn ảnh dưới 2MB.', true);
            this.value = '';
            return;
        }
        if (!['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(file.type)) {
            showToast('Định dạng không hỗ trợ', 'Chỉ hỗ trợ định dạng JPG, PNG, WEBP hoặc GIF.', true);
            this.value = '';
            return;
        }

        const fd = new FormData();
        fd.append('action', 'updateAvatar');
        fd.append('avatar', file);

        fetch(CTX + '/account/update-profile', { method: 'POST', body: fd })
            .then(r => r.json())
            .then(data => {
                if (data.success) {
                    document.querySelectorAll('.js-avatar-img').forEach(img => { img.src = data.avatarUrl; img.hidden = false; img.classList.remove('hidden'); });
                    document.querySelectorAll('.js-avatar-initial').forEach(el => { el.hidden = true; });
                    showToast('Thành công', 'Đã cập nhật ảnh đại diện.');
                } else {
                    showToast('Không thể tải ảnh lên', data.message, true);
                }
            })
            .catch(() => {
                showToast('Lỗi kết nối', 'Không thể tải ảnh lên. Vui lòng thử lại.', true);
            });
    });

    // ---- Cover upload ----
    document.getElementById('chpCoverInput').addEventListener('change', function () {
        const file = this.files && this.files[0];
        if (!file) return;
        if (file.size > 5 * 1024 * 1024) {
            showToast('Ảnh quá lớn', 'Vui lòng chọn ảnh dưới 5MB.', true);
            this.value = '';
            return;
        }
        if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
            showToast('Định dạng không hỗ trợ', 'Chỉ hỗ trợ định dạng JPG, PNG hoặc WEBP.', true);
            this.value = '';
            return;
        }
        const btn = document.getElementById('chpCoverBtn');
        btn.disabled = true;
        const fd = new FormData();
        fd.append('cover', file);
        fetch(CTX + '/customer/ho-so/doi-cover', { method: 'POST', body: fd })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                if (data.success) {
                    let img = document.querySelector('.customer-profile-hero-img');
                    if (!img) {
                        img = document.createElement('img');
                        img.className = 'customer-profile-hero-img';
                        document.querySelector('.customer-profile-hero').prepend(img);
                    }
                    img.src = CTX + data.coverUrl;
                    showToast('Thành công', 'Đã cập nhật ảnh bìa.');
                } else {
                    showToast('Không thể tải ảnh lên', data.message, true);
                }
            })
            .catch(() => {
                btn.disabled = false;
                showToast('Lỗi kết nối', 'Không thể tải ảnh lên. Vui lòng thử lại.', true);
            });
    });
</script>

</body>
</html>
```

- [ ] **Step 2: Sanity-check JSP syntax**

Run: `grep -c '<%@' src/main/webapp/customer/HoSo.jsp` — expect `4` (page + 3 taglibs). Run: `grep -c 'jsp:include' src/main/webapp/customer/HoSo.jsp` — expect `2`. These are cheap structural sanity checks; full validation happens at `mvn package` (Task 8) when the WAR is built, and at runtime testing (Task 9).

- [ ] **Step 3: Commit**

```bash
git add src/main/webapp/customer/HoSo.jsp
git commit -m "$(cat <<'EOF'
feat: add HoSo.jsp profile page shell with hero, overlay card, base-info edit

Standalone full-screen profile page shell (no sidebar): cover hero with
back/camera buttons, overlay profile card, tab switcher scaffold, and
the base-info edit form + email-OTP flow relocated verbatim from
TaiKhoan.jsp's #thongtin section (same /account/update-profile backend
contract, unchanged).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: CustomerProfileServlet

**Files:**
- Create: `src/main/java/org/example/controller/customer/CustomerProfileServlet.java`

**Interfaces:**
- Consumes: `org.example.dao.TaiKhoanDAO#getAccountById(int)` (existing), `org.example.dao.CustomerProfileDAO` (Task 2), `org.example.dao.LoaiSanDAO#getAllMonTheThao()` (existing), `org.example.service.team.TeamService#getMyTeams(int)` (existing, from `org.example.dao.impl.TeamDAOImpl`), request attribute `user` on session (existing convention, `TaiKhoan`), `org.example.util.RoleRedirectUtil.ROLE_CUSTOMER` (existing constant).
- Produces: route `GET /customer/ho-so` (renders `HoSo.jsp` with attributes `account`, `profileExtra`, `dsMon`, `myTeams`); routes `POST /customer/ho-so/cap-nhat-the-chat`, `POST /customer/ho-so/cap-nhat-ghi-chu`, `POST /customer/ho-so/cap-nhat-ca-nhan-hoa`, `POST /customer/ho-so/doi-cover` (all JSON responses `{"success":bool,"message":string,...}`, consumed by Task 6's JS).

- [ ] **Step 1: Write `CustomerProfileServlet.java`**

```java
package org.example.controller.customer;

import com.google.gson.Gson;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.dao.CustomerProfileDAO;
import org.example.dao.LoaiSanDAO;
import org.example.dao.TaiKhoanDAO;
import org.example.dao.TeamDAO;
import org.example.dao.impl.CustomerProfileDAOImpl;
import org.example.dao.impl.LoaiSanDAOImpl;
import org.example.dao.impl.TaiKhoanDAOImpl;
import org.example.dao.impl.TeamDAOImpl;
import org.example.dto.CustomerProfileExtraDTO;
import org.example.dto.TeamSummaryDTO;
import org.example.model.TaiKhoan;
import org.example.service.team.TeamService;
import org.example.util.RoleRedirectUtil;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Paths;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Trang hồ sơ cá nhân full-screen (/customer/ho-so) — thay thế section
 * #thongtin cũ trong TaiKhoan.jsp. Đọc thông tin cơ bản qua TaiKhoanDAO
 * (JPA, không đổi) và các trường mở rộng (cover/thể chất/cá nhân hóa) qua
 * CustomerProfileDAO (JDBC thuần, độc lập hoàn toàn khỏi entity TaiKhoan —
 * xem ghi chú trong CustomerProfileDAO).
 */
@WebServlet(urlPatterns = {
        "/customer/ho-so",
        "/customer/ho-so/cap-nhat-the-chat",
        "/customer/ho-so/cap-nhat-ghi-chu",
        "/customer/ho-so/cap-nhat-ca-nhan-hoa",
        "/customer/ho-so/doi-cover"
})
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 5 * 1024 * 1024,
        maxRequestSize = 6 * 1024 * 1024
)
public class CustomerProfileServlet extends HttpServlet {

    private static final Logger logger = LogManager.getLogger(CustomerProfileServlet.class);
    private static final Set<String> ALLOWED_COVER_TYPES = Set.of("image/jpeg", "image/png", "image/webp");
    private static final Set<String> ALLOWED_LEVELS = Set.of("Mới chơi", "Cơ bản", "Trung bình", "Khá", "Nâng cao");
    private static final Set<String> ALLOWED_FREQUENCIES = Set.of("1 lần/tuần", "2-3 lần/tuần", "4+ lần/tuần", "Không cố định");

    private final TaiKhoanDAO taiKhoanDAO = new TaiKhoanDAOImpl();
    private final CustomerProfileDAO profileDAO = new CustomerProfileDAOImpl();
    private final LoaiSanDAO loaiSanDAO = new LoaiSanDAOImpl();
    private final TeamDAO teamDAO = new TeamDAOImpl();
    private final TeamService teamService = new TeamService(teamDAO);
    private static final Gson GSON = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();
        if (!"/customer/ho-so".equals(path)) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        TaiKhoan user = requireCustomer(req, resp);
        if (user == null) return;

        TaiKhoan account = taiKhoanDAO.getAccountById(user.getAccountId());
        if (account == null || Boolean.TRUE.equals(account.isDeleted()) || account.isLocked()) {
            req.getSession().invalidate();
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        CustomerProfileExtraDTO profileExtra;
        try {
            profileExtra = profileDAO.getExtra(account.getAccountId());
        } catch (SQLException e) {
            logger.error("Không thể tải hồ sơ mở rộng cho accountId={} — có thể migration_customer_profile.sql chưa chạy: {}",
                    account.getAccountId(), e.getMessage(), e);
            profileExtra = new CustomerProfileExtraDTO();
        }

        List<org.example.model.MonTheThao> dsMon;
        try {
            dsMon = loaiSanDAO.getAllMonTheThao();
        } catch (Exception e) {
            logger.error("Không thể tải danh sách môn thể thao cho trang hồ sơ: {}", e.getMessage(), e);
            dsMon = List.of();
        }

        List<TeamSummaryDTO> myTeams;
        try {
            myTeams = teamService.getMyTeams(account.getAccountId());
        } catch (RuntimeException e) {
            logger.error("Không thể tải danh sách đội nhóm cho trang hồ sơ, accountId={}: {}",
                    account.getAccountId(), e.getMessage(), e);
            myTeams = List.of();
        }

        req.setAttribute("account", account);
        req.setAttribute("profileExtra", profileExtra);
        req.setAttribute("dsMon", dsMon);
        req.setAttribute("myTeams", myTeams);
        req.getRequestDispatcher("/customer/HoSo.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getServletPath();
        switch (path) {
            case "/customer/ho-so/cap-nhat-the-chat": handleUpdatePhysical(req, resp); return;
            case "/customer/ho-so/cap-nhat-ghi-chu": handleUpdateNote(req, resp); return;
            case "/customer/ho-so/cap-nhat-ca-nhan-hoa": handleUpdatePersonalization(req, resp); return;
            case "/customer/ho-so/doi-cover": handleUpdateCover(req, resp); return;
            default: resp.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    private void handleUpdatePhysical(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;

        Integer height = parseIntSafe(req.getParameter("heightCm"));
        Integer weight = parseIntSafe(req.getParameter("weightKg"));
        if (height != null && (height < 50 || height > 260)) {
            writeJson(resp, 400, Map.of("success", false, "message", "Chiều cao phải trong khoảng 50-260cm."));
            return;
        }
        if (weight != null && (weight < 20 || weight > 300)) {
            writeJson(resp, 400, Map.of("success", false, "message", "Cân nặng phải trong khoảng 20-300kg."));
            return;
        }

        try {
            boolean ok = profileDAO.updatePhysical(user.getAccountId(), height, weight);
            writeJson(resp, ok ? 200 : 400, Map.of("success", ok, "message", ok ? "Đã cập nhật thông tin thể chất." : "Không thể cập nhật."));
        } catch (SQLException e) {
            logger.error("Lỗi cập nhật thông tin thể chất accountId={}: {}", user.getAccountId(), e.getMessage(), e);
            writeJson(resp, 503, Map.of("success", false, "message", "Chức năng đang được cấu hình. Vui lòng thử lại sau."));
        }
    }

    private void handleUpdateNote(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;

        String note = req.getParameter("note");
        if (note != null) {
            note = note.trim();
            if (note.length() > 500) {
                writeJson(resp, 400, Map.of("success", false, "message", "Ghi chú tối đa 500 ký tự."));
                return;
            }
            if (note.isEmpty()) note = null;
        }

        try {
            boolean ok = profileDAO.updateNote(user.getAccountId(), note);
            writeJson(resp, ok ? 200 : 400, Map.of("success", ok, "message", ok ? "Đã cập nhật ghi chú." : "Không thể cập nhật."));
        } catch (SQLException e) {
            logger.error("Lỗi cập nhật ghi chú accountId={}: {}", user.getAccountId(), e.getMessage(), e);
            writeJson(resp, 503, Map.of("success", false, "message", "Chức năng đang được cấu hình. Vui lòng thử lại sau."));
        }
    }

    private void handleUpdatePersonalization(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;

        String location = trimToNull(req.getParameter("location"));
        Integer sportId = parseIntSafe(req.getParameter("sportId"));
        String level = trimToNull(req.getParameter("level"));
        String goal = trimToNull(req.getParameter("goal"));
        String frequency = trimToNull(req.getParameter("frequency"));

        if (location != null && location.length() > 255) {
            writeJson(resp, 400, Map.of("success", false, "message", "Vị trí yêu thích tối đa 255 ký tự."));
            return;
        }
        if (level != null && !ALLOWED_LEVELS.contains(level)) {
            writeJson(resp, 400, Map.of("success", false, "message", "Trình độ không hợp lệ."));
            return;
        }
        if (goal != null && goal.length() > 255) {
            writeJson(resp, 400, Map.of("success", false, "message", "Mục tiêu tối đa 255 ký tự."));
            return;
        }
        if (frequency != null && !ALLOWED_FREQUENCIES.contains(frequency)) {
            writeJson(resp, 400, Map.of("success", false, "message", "Tần suất chơi không hợp lệ."));
            return;
        }

        try {
            boolean ok = profileDAO.updatePersonalization(user.getAccountId(), location, sportId, level, goal, frequency);
            writeJson(resp, ok ? 200 : 400, Map.of("success", ok, "message", ok ? "Đã cập nhật cá nhân hóa." : "Không thể cập nhật."));
        } catch (SQLException e) {
            logger.error("Lỗi cập nhật cá nhân hóa accountId={}: {}", user.getAccountId(), e.getMessage(), e);
            writeJson(resp, 503, Map.of("success", false, "message", "Chức năng đang được cấu hình. Vui lòng thử lại sau."));
        }
    }

    private void handleUpdateCover(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;

        Part coverPart;
        try {
            coverPart = req.getPart("cover");
        } catch (Exception e) {
            writeJson(resp, 400, Map.of("success", false, "message", "Vui lòng chọn ảnh bìa."));
            return;
        }
        if (coverPart == null || coverPart.getSize() <= 0) {
            writeJson(resp, 400, Map.of("success", false, "message", "Vui lòng chọn ảnh bìa."));
            return;
        }
        String contentType = coverPart.getContentType();
        if (contentType == null || !ALLOWED_COVER_TYPES.contains(contentType)) {
            writeJson(resp, 400, Map.of("success", false, "message", "Chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP."));
            return;
        }
        byte[] header = new byte[12];
        int read;
        try (InputStream is = coverPart.getInputStream()) {
            read = is.readNBytes(header, 0, header.length);
        }
        if (!looksLikeImage(header, read)) {
            writeJson(resp, 400, Map.of("success", false, "message", "Tệp không phải ảnh hợp lệ."));
            return;
        }

        String extension = getSafeImageExtension(coverPart.getSubmittedFileName(), contentType);
        String fileName = "cover-" + user.getAccountId() + "-" + UUID.randomUUID() + extension;
        String uploadPath = getServletContext().getRealPath("/uploads/covers");
        if (uploadPath == null) {
            uploadPath = new File(System.getProperty("user.home"), "v-sport/uploads/covers").getAbsolutePath();
        }
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists() && !uploadDir.mkdirs()) {
            writeJson(resp, 500, Map.of("success", false, "message", "Không thể tạo thư mục lưu ảnh bìa."));
            return;
        }
        File target = new File(uploadDir, fileName);
        coverPart.write(target.getAbsolutePath());
        String coverUrl = "/uploads/covers/" + fileName;

        try {
            boolean ok = profileDAO.updateCoverPath(user.getAccountId(), coverUrl);
            if (ok) {
                writeJson(resp, 200, Map.of("success", true, "message", "Đã cập nhật ảnh bìa.", "coverUrl", coverUrl));
            } else {
                writeJson(resp, 400, Map.of("success", false, "message", "Không thể lưu ảnh bìa."));
            }
        } catch (SQLException e) {
            logger.error("Lỗi cập nhật ảnh bìa accountId={}: {}", user.getAccountId(), e.getMessage(), e);
            writeJson(resp, 503, Map.of("success", false, "message", "Chức năng đang được cấu hình. Vui lòng thử lại sau."));
        }
    }

    private boolean looksLikeImage(byte[] b, int len) {
        if (len >= 3 && (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF) return true;
        if (len >= 8 && (b[0] & 0xFF) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G') return true;
        if (len >= 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') return true;
        return false;
    }

    private String getSafeImageExtension(String submittedFileName, String contentType) {
        String ext = null;
        if (submittedFileName != null && !submittedFileName.isBlank()) {
            String name = Paths.get(submittedFileName).getFileName().toString().toLowerCase();
            int dot = name.lastIndexOf('.');
            if (dot >= 0) {
                String candidate = name.substring(dot);
                if (Set.of(".jpg", ".jpeg", ".png", ".webp").contains(candidate)) ext = candidate;
            }
        }
        if (ext == null) {
            if ("image/png".equals(contentType)) ext = ".png";
            else if ("image/webp".equals(contentType)) ext = ".webp";
            else ext = ".jpg";
        }
        return ext;
    }

    private TaiKhoan requireCustomer(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan user = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return null;
        }
        if (user.getRoleId() != RoleRedirectUtil.ROLE_CUSTOMER) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Trang này chỉ dành cho tài khoản Khách hàng.");
            return null;
        }
        return user;
    }

    private TaiKhoan requireCustomerJson(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan user = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        if (user == null) {
            writeJson(resp, 401, Map.of("success", false, "message", "Vui lòng đăng nhập."));
            return null;
        }
        if (user.getRoleId() != RoleRedirectUtil.ROLE_CUSTOMER) {
            writeJson(resp, 403, Map.of("success", false, "message", "Trang này chỉ dành cho tài khoản Khách hàng."));
            return null;
        }
        return user;
    }

    private void writeJson(HttpServletResponse resp, int status, Map<String, Object> payload) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json; charset=UTF-8");
        resp.getWriter().write(GSON.toJson(payload));
    }

    private Integer parseIntSafe(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return null; }
    }

    private String trimToNull(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }
}
```

- [ ] **Step 2: Compile check**

Run: `mvn -q compile 2>&1 | tail -150`
Expected: no output. If `TeamSummaryDTO`/`TeamService`/`TeamDAO` import errors appear, re-check exact package names against `src/main/java/org/example/service/team/TeamService.java` and `src/main/java/org/example/dao/TeamDAO.java` (both already exist from the Team module).

- [ ] **Step 3: Commit**

```bash
git add src/main/java/org/example/controller/customer/CustomerProfileServlet.java
git commit -m "$(cat <<'EOF'
feat: add CustomerProfileServlet for /customer/ho-so

Renders the new profile page and handles physical-info/note/
personalization/cover-photo updates via CustomerProfileDAO. Falls back
to a friendly 503 JSON message (never a raw stack trace or a silent
empty payload) if the profile migration hasn't run yet.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: HoSo.jsp tab content — Tổng quan (physical/note/personalization) and Liên kết (teams)

**Files:**
- Modify: `src/main/webapp/customer/HoSo.jsp` (fill in `#chpTabOverview` and `#chpTabLinks`, add their edit modals and JS)

**Interfaces:**
- Consumes: request attributes `profileExtra` (`CustomerProfileExtraDTO`), `dsMon` (`List<MonTheThao>`), `myTeams` (`List<TeamSummaryDTO>`) set by Task 5's servlet. POST endpoints from Task 5: `/customer/ho-so/cap-nhat-the-chat`, `/customer/ho-so/cap-nhat-ghi-chu`, `/customer/ho-so/cap-nhat-ca-nhan-hoa`.
- Produces: fully working Tổng quan/Liên kết tab content, completing the page from Task 4.

- [ ] **Step 1: Replace the two empty tab-panel divs in `HoSo.jsp`**

Find:
```jsp
    <!-- Tổng quan tab content is added in Task 6 -->
    <div id="chpTabOverview" class="customer-profile-tab-panel"></div>
    <div id="chpTabLinks" class="customer-profile-tab-panel hidden"></div>
```

Replace with:
```jsp
    <div id="chpTabOverview" class="customer-profile-tab-panel">
        <div class="customer-profile-section-wrap">

            <div class="customer-profile-section">
                <div class="customer-profile-section-header">
                    <span class="customer-profile-section-title">Thông tin thể chất</span>
                    <button type="button" class="customer-profile-section-edit" aria-label="Chỉnh sửa thông tin thể chất" onclick="openModal('chpPhysicalModal')">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/></svg>
                    </button>
                </div>
                <hr class="customer-profile-divider">
                <div class="customer-profile-physical-row">
                    <div class="customer-profile-physical-col">
                        <div class="customer-profile-physical-label">CHIỀU CAO (CM)</div>
                        <div id="chpHeightValue" class="customer-profile-physical-value">${not empty profileExtra.heightCm ? profileExtra.heightCm : '-'}</div>
                    </div>
                    <div class="customer-profile-physical-col">
                        <div class="customer-profile-physical-label">CÂN NẶNG (KG)</div>
                        <div id="chpWeightValue" class="customer-profile-physical-value">${not empty profileExtra.weightKg ? profileExtra.weightKg : '-'}</div>
                    </div>
                </div>
            </div>

            <div class="customer-profile-section">
                <div class="customer-profile-section-header">
                    <span class="customer-profile-section-title">Ghi chú đặc biệt</span>
                    <button type="button" class="customer-profile-section-edit" aria-label="Chỉnh sửa ghi chú đặc biệt" onclick="openNoteEdit()">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/></svg>
                    </button>
                </div>
                <hr class="customer-profile-divider">
                <div class="customer-profile-note-row">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><rect width="8" height="4" x="8" y="2" rx="1"/></svg>
                    <c:choose>
                        <c:when test="${not empty profileExtra.specialNote}">
                            <span id="chpNoteText" class="customer-profile-note-text">${fn:escapeXml(profileExtra.specialNote)}</span>
                        </c:when>
                        <c:otherwise>
                            <span id="chpNoteText" class="customer-profile-note-placeholder">Chưa có ghi chú</span>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>

            <div class="customer-profile-section">
                <div class="customer-profile-section-header">
                    <span class="customer-profile-section-title">Cá nhân hoá</span>
                    <button type="button" class="customer-profile-section-edit" aria-label="Chỉnh sửa cá nhân hóa" onclick="openModal('chpPersoModal')">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/></svg>
                    </button>
                </div>
                <hr class="customer-profile-divider">
                <div class="customer-profile-perso-row">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/></svg>
                    <span class="customer-profile-perso-label">Vị trí yêu thích</span>
                    <span id="chpLocationValue" class="customer-profile-perso-value">${not empty profileExtra.preferredLocation ? fn:escapeXml(profileExtra.preferredLocation) : '-'}</span>
                </div>
                <div class="customer-profile-perso-row">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="6"/><path d="M15.477 12.89 17 22l-5-3-5 3 1.523-9.11"/></svg>
                    <span class="customer-profile-perso-label">Môn thể thao và trình độ</span>
                    <span id="chpSportLevelValue" class="customer-profile-perso-value">
                        <c:choose>
                            <c:when test="${not empty profileExtra.favoriteSportName}">${fn:escapeXml(profileExtra.favoriteSportName)}<c:if test="${not empty profileExtra.skillLevel}"> - ${fn:escapeXml(profileExtra.skillLevel)}</c:if></c:when>
                            <c:otherwise>-</c:otherwise>
                        </c:choose>
                    </span>
                </div>
                <div class="customer-profile-perso-row">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/></svg>
                    <span class="customer-profile-perso-label">Mục tiêu</span>
                    <span id="chpGoalValue" class="customer-profile-perso-value">${not empty profileExtra.goal ? fn:escapeXml(profileExtra.goal) : '-'}</span>
                </div>
                <div class="customer-profile-perso-row">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/></svg>
                    <span class="customer-profile-perso-label">Tần suất chơi</span>
                    <span id="chpFrequencyValue" class="customer-profile-perso-value">${not empty profileExtra.playFrequency ? fn:escapeXml(profileExtra.playFrequency) : '-'}</span>
                </div>
            </div>

        </div>
    </div>

    <div id="chpTabLinks" class="customer-profile-tab-panel hidden">
        <div class="customer-profile-section-wrap">
            <c:choose>
                <c:when test="${not empty myTeams}">
                    <c:forEach var="team" items="${myTeams}">
                        <div class="customer-profile-team-item">
                            <c:choose>
                                <c:when test="${not empty team.avatarPath}">
                                    <img class="customer-profile-team-avatar" src="${pageContext.request.contextPath}${team.avatarPath}" alt="${fn:escapeXml(team.teamName)}">
                                </c:when>
                                <c:otherwise>
                                    <span class="customer-profile-team-avatar">${fn:escapeXml(fn:substring(team.teamName, 0, 1))}</span>
                                </c:otherwise>
                            </c:choose>
                            <div>
                                <div class="customer-profile-team-name">${fn:escapeXml(team.teamName)}</div>
                                <div class="customer-profile-team-meta">${fn:escapeXml(team.myRole)} &middot; ${team.memberCount}/${team.maxMembers} thành viên</div>
                            </div>
                        </div>
                    </c:forEach>
                </c:when>
                <c:otherwise>
                    <div class="customer-profile-empty">
                        <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
                        <p>Bạn chưa tham gia đội nhóm nào.</p>
                    </div>
                </c:otherwise>
            </c:choose>
        </div>
    </div>
```

- [ ] **Step 2: Add the physical-info and personalization edit modals**

Find (in the same file, right before the closing `</body>`):
```jsp
<script>
    const CTX = '${pageContext.request.contextPath}';
```

Replace with (inserting the two new modals before the `<script>` tag):
```jsp
<!-- Physical info edit modal -->
<div id="chpPhysicalModal" class="hidden fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[300] flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-[400px] border border-slate-200">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <h3 class="text-sm font-extrabold" style="color:#102A43;">Chỉnh sửa thông tin thể chất</h3>
            <button type="button" onclick="closeModal('chpPhysicalModal')" class="w-8 h-8 rounded-full hover:bg-slate-100 flex items-center justify-center" aria-label="Đóng">
                <svg class="lci text-slate-500" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
        </div>
        <form id="chpPhysicalForm" class="px-6 py-5 flex flex-col gap-4" onsubmit="return false;">
            <div>
                <label class="acc-label" for="chpHeightInput">Chiều cao (cm)</label>
                <input id="chpHeightInput" type="number" min="50" max="260" class="acc-input" value="${profileExtra.heightCm}">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="heightCm"></p>
            </div>
            <div>
                <label class="acc-label" for="chpWeightInput">Cân nặng (kg)</label>
                <input id="chpWeightInput" type="number" min="20" max="300" class="acc-input" value="${profileExtra.weightKg}">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="weightKg"></p>
            </div>
            <div class="flex justify-end gap-3 pt-2">
                <button type="button" onclick="closeModal('chpPhysicalModal')" class="btn-secondary">Hủy</button>
                <button type="button" id="chpPhysicalSaveBtn" onclick="chpSavePhysical()" class="btn-primary">Lưu thay đổi</button>
            </div>
        </form>
    </div>
</div>

<!-- Special note edit modal -->
<div id="chpNoteModal" class="hidden fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[300] flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-[440px] border border-slate-200">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <h3 class="text-sm font-extrabold" style="color:#102A43;">Chỉnh sửa ghi chú đặc biệt</h3>
            <button type="button" onclick="closeModal('chpNoteModal')" class="w-8 h-8 rounded-full hover:bg-slate-100 flex items-center justify-center" aria-label="Đóng">
                <svg class="lci text-slate-500" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
        </div>
        <form id="chpNoteForm" class="px-6 py-5 flex flex-col gap-4" onsubmit="return false;">
            <div>
                <label class="acc-label" for="chpNoteInput">Ghi chú đặc biệt</label>
                <textarea id="chpNoteInput" maxlength="500" rows="4" class="acc-input" style="height:auto;padding:10px 14px;">${fn:escapeXml(profileExtra.specialNote)}</textarea>
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="note"></p>
            </div>
            <div class="flex justify-end gap-3 pt-2">
                <button type="button" onclick="closeModal('chpNoteModal')" class="btn-secondary">Hủy</button>
                <button type="button" id="chpNoteSaveBtn" onclick="chpSaveNote()" class="btn-primary">Lưu thay đổi</button>
            </div>
        </form>
    </div>
</div>

<!-- Personalization edit modal -->
<div id="chpPersoModal" class="hidden fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[300] flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-[460px] border border-slate-200 max-h-[90vh] overflow-y-auto">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <h3 class="text-sm font-extrabold" style="color:#102A43;">Chỉnh sửa cá nhân hoá</h3>
            <button type="button" onclick="closeModal('chpPersoModal')" class="w-8 h-8 rounded-full hover:bg-slate-100 flex items-center justify-center" aria-label="Đóng">
                <svg class="lci text-slate-500" style="width:18px;height:18px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
            </button>
        </div>
        <form id="chpPersoForm" class="px-6 py-5 flex flex-col gap-4" onsubmit="return false;">
            <div>
                <label class="acc-label" for="chpLocationInput">Vị trí yêu thích</label>
                <input id="chpLocationInput" type="text" maxlength="255" class="acc-input" value="${fn:escapeXml(profileExtra.preferredLocation)}">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="location"></p>
            </div>
            <div>
                <label class="acc-label" for="chpSportInput">Môn thể thao yêu thích</label>
                <select id="chpSportInput" class="acc-input">
                    <option value="">-- Không chọn --</option>
                    <c:forEach var="mon" items="${dsMon}">
                        <option value="${mon.monTheThaoID}" ${mon.monTheThaoID == profileExtra.favoriteSportId ? 'selected' : ''}>${fn:escapeXml(mon.tenMon)}</option>
                    </c:forEach>
                </select>
            </div>
            <div>
                <label class="acc-label" for="chpLevelInput">Trình độ</label>
                <select id="chpLevelInput" class="acc-input">
                    <option value="">-- Không chọn --</option>
                    <option value="Mới chơi" ${profileExtra.skillLevel == 'Mới chơi' ? 'selected' : ''}>Mới chơi</option>
                    <option value="Cơ bản" ${profileExtra.skillLevel == 'Cơ bản' ? 'selected' : ''}>Cơ bản</option>
                    <option value="Trung bình" ${profileExtra.skillLevel == 'Trung bình' ? 'selected' : ''}>Trung bình</option>
                    <option value="Khá" ${profileExtra.skillLevel == 'Khá' ? 'selected' : ''}>Khá</option>
                    <option value="Nâng cao" ${profileExtra.skillLevel == 'Nâng cao' ? 'selected' : ''}>Nâng cao</option>
                </select>
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="level"></p>
            </div>
            <div>
                <label class="acc-label" for="chpGoalInput">Mục tiêu</label>
                <input id="chpGoalInput" type="text" maxlength="255" class="acc-input" value="${fn:escapeXml(profileExtra.goal)}">
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="goal"></p>
            </div>
            <div>
                <label class="acc-label" for="chpFrequencyInput">Tần suất chơi</label>
                <select id="chpFrequencyInput" class="acc-input">
                    <option value="">-- Không chọn --</option>
                    <option value="1 lần/tuần" ${profileExtra.playFrequency == '1 lần/tuần' ? 'selected' : ''}>1 lần/tuần</option>
                    <option value="2-3 lần/tuần" ${profileExtra.playFrequency == '2-3 lần/tuần' ? 'selected' : ''}>2-3 lần/tuần</option>
                    <option value="4+ lần/tuần" ${profileExtra.playFrequency == '4+ lần/tuần' ? 'selected' : ''}>4+ lần/tuần</option>
                    <option value="Không cố định" ${profileExtra.playFrequency == 'Không cố định' ? 'selected' : ''}>Không cố định</option>
                </select>
                <p class="hidden text-[12px] text-red-600 font-semibold mt-1" data-error-for="frequency"></p>
            </div>
            <div class="flex justify-end gap-3 pt-2">
                <button type="button" onclick="closeModal('chpPersoModal')" class="btn-secondary">Hủy</button>
                <button type="button" id="chpPersoSaveBtn" onclick="chpSavePersonalization()" class="btn-primary">Lưu thay đổi</button>
            </div>
        </form>
    </div>
</div>

<script>
    const CTX = '${pageContext.request.contextPath}';
```

- [ ] **Step 3: Add the tab-content JS functions**

Find (near the end of the `<script>` block):
```jsp
    // ---- Cover upload ----
    document.getElementById('chpCoverInput').addEventListener('change', function () {
```

Insert immediately before it:
```jsp
    // ---- Physical info ----
    function chpSavePhysical() {
        const heightVal = document.getElementById('chpHeightInput').value.trim();
        const weightVal = document.getElementById('chpWeightInput').value.trim();
        const form = document.getElementById('chpPhysicalForm');
        clearFieldErrors(form);

        const btn = document.getElementById('chpPhysicalSaveBtn');
        btn.disabled = true;
        const originalText = btn.textContent;
        btn.textContent = 'Đang lưu...';

        const params = new URLSearchParams();
        if (heightVal) params.append('heightCm', heightVal);
        if (weightVal) params.append('weightKg', weightVal);

        fetch(CTX + '/customer/ho-so/cap-nhat-the-chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: params
        })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                btn.textContent = originalText;
                if (data.success) {
                    document.getElementById('chpHeightValue').textContent = heightVal || '-';
                    document.getElementById('chpWeightValue').textContent = weightVal || '-';
                    closeModal('chpPhysicalModal');
                    showToast('Thành công', 'Đã cập nhật thông tin thể chất.');
                } else {
                    showToast('Không thể cập nhật', data.message, true);
                }
            })
            .catch(() => {
                btn.disabled = false;
                btn.textContent = originalText;
                showToast('Lỗi kết nối', 'Không thể kết nối máy chủ. Vui lòng thử lại.', true);
            });
    }

    // ---- Special note ----
    function openNoteEdit() { openModal('chpNoteModal'); }

    function chpSaveNote() {
        const note = document.getElementById('chpNoteInput').value;
        const form = document.getElementById('chpNoteForm');
        clearFieldErrors(form);

        const btn = document.getElementById('chpNoteSaveBtn');
        btn.disabled = true;
        const originalText = btn.textContent;
        btn.textContent = 'Đang lưu...';

        const params = new URLSearchParams();
        params.append('note', note);

        fetch(CTX + '/customer/ho-so/cap-nhat-ghi-chu', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: params
        })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                btn.textContent = originalText;
                if (data.success) {
                    const textEl = document.getElementById('chpNoteText');
                    if (note.trim()) {
                        textEl.textContent = note.trim();
                        textEl.className = 'customer-profile-note-text';
                    } else {
                        textEl.textContent = 'Chưa có ghi chú';
                        textEl.className = 'customer-profile-note-placeholder';
                    }
                    closeModal('chpNoteModal');
                    showToast('Thành công', 'Đã cập nhật ghi chú.');
                } else {
                    showToast('Không thể cập nhật', data.message, true);
                }
            })
            .catch(() => {
                btn.disabled = false;
                btn.textContent = originalText;
                showToast('Lỗi kết nối', 'Không thể kết nối máy chủ. Vui lòng thử lại.', true);
            });
    }

    // ---- Personalization ----
    function chpSavePersonalization() {
        const location = document.getElementById('chpLocationInput').value;
        const sportId = document.getElementById('chpSportInput').value;
        const sportName = sportId ? document.getElementById('chpSportInput').selectedOptions[0].textContent : '';
        const level = document.getElementById('chpLevelInput').value;
        const goal = document.getElementById('chpGoalInput').value;
        const frequency = document.getElementById('chpFrequencyInput').value;
        const form = document.getElementById('chpPersoForm');
        clearFieldErrors(form);

        const btn = document.getElementById('chpPersoSaveBtn');
        btn.disabled = true;
        const originalText = btn.textContent;
        btn.textContent = 'Đang lưu...';

        const params = new URLSearchParams();
        params.append('location', location);
        if (sportId) params.append('sportId', sportId);
        params.append('level', level);
        params.append('goal', goal);
        params.append('frequency', frequency);

        fetch(CTX + '/customer/ho-so/cap-nhat-ca-nhan-hoa', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: params
        })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                btn.textContent = originalText;
                if (data.success) {
                    document.getElementById('chpLocationValue').textContent = location.trim() || '-';
                    document.getElementById('chpSportLevelValue').textContent = sportId ? (sportName + (level ? ' - ' + level : '')) : '-';
                    document.getElementById('chpGoalValue').textContent = goal.trim() || '-';
                    document.getElementById('chpFrequencyValue').textContent = frequency || '-';
                    closeModal('chpPersoModal');
                    showToast('Thành công', 'Đã cập nhật cá nhân hoá.');
                } else if (data.code === 'VALIDATION_ERROR') {
                    showFieldErrors(form, data.fieldErrors);
                } else {
                    showToast('Không thể cập nhật', data.message, true);
                }
            })
            .catch(() => {
                btn.disabled = false;
                btn.textContent = originalText;
                showToast('Lỗi kết nối', 'Không thể kết nối máy chủ. Vui lòng thử lại.', true);
            });
    }

```

- [ ] **Step 4: Structural sanity check**

Run: `grep -c 'id="chpPhysicalModal"\|id="chpNoteModal"\|id="chpPersoModal"' src/main/webapp/customer/HoSo.jsp` — expect `3`.
Run: `grep -c 'function chpSavePhysical\|function chpSaveNote\|function chpSavePersonalization' src/main/webapp/customer/HoSo.jsp` — expect `3`.

- [ ] **Step 5: Commit**

```bash
git add src/main/webapp/customer/HoSo.jsp
git commit -m "$(cat <<'EOF'
feat: complete HoSo.jsp Tổng quan and Liên kết tab content

Physical info, special note, and personalization sections with edit
modals wired to CustomerProfileServlet's POST endpoints; Liên kết tab
renders real team memberships via TeamService.getMyTeams with an empty
state when none exist.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Sidebar wiring — link profile card to /customer/ho-so, remove dead #thongtin section

**Files:**
- Modify: `src/main/webapp/customer/TaiKhoan.jsp`

**Interfaces:**
- Consumes: nothing new — pure removal/link-swap within the existing file.
- Produces: sidebar profile card and "Thông tin cá nhân" menu item both navigate to `/customer/ho-so`; `#thongtin` section and its now-orphaned JS are removed; `TaiKhoan.jsp`'s remaining sections (password modal, delete-account modal, other tabs) are untouched and still work.

- [ ] **Step 1: Convert the sidebar profile card to a real link**

Find (around line 391):
```jsp
                <button type="button" class="side-profile-row" data-section="thongtin" aria-label="Mở thông tin cá nhân">
                    <c:choose>
                        <c:when test="${not empty account.avatarUrl}">
                            <img class="side-avatar js-avatar-img" src="${pageContext.request.contextPath}${account.avatarUrl}" alt="Ảnh đại diện">
                        </c:when>
                        <c:otherwise>
                            <span class="side-avatar js-avatar-initial" aria-hidden="true"><c:choose><c:when test="${not empty account.fullName}">${fn:escapeXml(fn:substring(account.fullName, 0, 1))}</c:when><c:otherwise>${fn:escapeXml(fn:substring(account.username, 0, 1))}</c:otherwise></c:choose></span>
                            <img class="side-avatar js-avatar-img" src="" alt="Ảnh đại diện" hidden>
                        </c:otherwise>
                    </c:choose>
                    <span style="min-width:0;">
                        <span id="accSummaryName" class="side-profile-name" style="display:block;">${fn:escapeXml(not empty account.fullName ? account.fullName : account.username)}</span>
                        <span id="accSummaryEmail" class="side-profile-email" style="display:block;">${not empty account.email ? fn:escapeXml(account.email) : 'Chưa cập nhật email'}</span>
                    </span>
                    <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                </button>
```

Replace with:
```jsp
                <a href="${pageContext.request.contextPath}/customer/ho-so" class="side-profile-row" aria-label="Mở hồ sơ cá nhân">
                    <c:choose>
                        <c:when test="${not empty account.avatarUrl}">
                            <img class="side-avatar js-avatar-img" src="${pageContext.request.contextPath}${account.avatarUrl}" alt="Ảnh đại diện">
                        </c:when>
                        <c:otherwise>
                            <span class="side-avatar js-avatar-initial" aria-hidden="true"><c:choose><c:when test="${not empty account.fullName}">${fn:escapeXml(fn:substring(account.fullName, 0, 1))}</c:when><c:otherwise>${fn:escapeXml(fn:substring(account.username, 0, 1))}</c:otherwise></c:choose></span>
                            <img class="side-avatar js-avatar-img" src="" alt="Ảnh đại diện" hidden>
                        </c:otherwise>
                    </c:choose>
                    <span style="min-width:0;">
                        <span id="accSummaryName" class="side-profile-name" style="display:block;">${fn:escapeXml(not empty account.fullName ? account.fullName : account.username)}</span>
                        <span id="accSummaryEmail" class="side-profile-email" style="display:block;">${not empty account.email ? fn:escapeXml(account.email) : 'Chưa cập nhật email'}</span>
                    </span>
                    <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                </a>
```

(Note: `.side-profile-row` CSS already applies `display:flex; text-align:left; cursor:pointer` etc. and doesn't set `text-decoration`, so add one rule so the anchor doesn't show an underline — see Step 2.)

- [ ] **Step 2: Add `text-decoration: none` to `.side-profile-row` now that it's an anchor**

Find (around line 99-108):
```jsp
        .side-profile-row {
            position: relative; z-index: 1;
            display: flex; align-items: center; gap: 10px;
            width: 100%; min-height: 58px; padding: 8px 12px;
            background: rgba(255, 255, 255, 0.13);
            border: 1px solid #e8c25a;
            border-radius: 8px;
            color: #fff; text-align: left; cursor: pointer;
            transition: background-color .15s ease;
        }
```

Replace with:
```jsp
        .side-profile-row {
            position: relative; z-index: 1;
            display: flex; align-items: center; gap: 10px;
            width: 100%; min-height: 58px; padding: 8px 12px;
            background: rgba(255, 255, 255, 0.13);
            border: 1px solid #e8c25a;
            border-radius: 8px;
            color: #fff; text-align: left; text-decoration: none; cursor: pointer;
            transition: background-color .15s ease;
        }
```

- [ ] **Step 3: Convert the sidebar menu item "Thông tin cá nhân" to a real link**

Find (around line 461-465):
```jsp
                <button type="button" class="side-menu-item" data-section="thongtin">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 10h2"/><path d="M16 14h2"/><path d="M6.17 15a3 3 0 0 1 5.66 0"/><circle cx="9" cy="11" r="2"/><rect x="2" y="5" width="20" height="14" rx="2"/></svg>
                    Thông tin cá nhân
                    <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                </button>
```

Replace with:
```jsp
                <a href="${pageContext.request.contextPath}/customer/ho-so" class="side-menu-item">
                    <svg class="lci" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 10h2"/><path d="M16 14h2"/><path d="M6.17 15a3 3 0 0 1 5.66 0"/><circle cx="9" cy="11" r="2"/><rect x="2" y="5" width="20" height="14" rx="2"/></svg>
                    Thông tin cá nhân
                    <svg class="lci lci-chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg>
                </a>
```

(Check: run `grep -n "\.side-menu-item {" -A5 src/main/webapp/customer/TaiKhoan.jsp` first — if that rule doesn't already set `text-decoration: none`, add it the same way as Step 2. `<a>` elements default to underlined text and browser default link color, which would look wrong in this sidebar otherwise.)

- [ ] **Step 4: Delete the `#thongtin` section block**

Find the entire block starting at `<!-- ===== Section: Thông tin cá nhân ===== -->` (around line 577) through its closing `</section>` (around line 679) — this is the `<section class="acc-section" data-section="thongtin" ...>` block containing `#personalInfoCard`, `#infoViewMode`, `#infoEditForm`. Delete the whole block (comment + section + its closing tag), leaving the `<!-- ===== Section: Điểm uy tín ===== -->` section directly followed by the closing `</div></section>` of the main content wrapper.

- [ ] **Step 5: Remove the dead `personalInfoCard: 'thongtin'` alias and the crashing `editBirthday.max` line**

Find (around line 964):
```jsp
    const CTX = '${pageContext.request.contextPath}';
    document.getElementById('editBirthday').max = new Date().toISOString().split('T')[0];
```

Replace with:
```jsp
    const CTX = '${pageContext.request.contextPath}';
```

Find (around line 980-984):
```jsp
    const SECTION_ALIASES = {
        uyTinCuaToi: 'uytin',
        personalInfoCard: 'thongtin',
        tongQuan: 'tongquan'
    };
```

Replace with:
```jsp
    const SECTION_ALIASES = {
        uyTinCuaToi: 'uytin',
        tongQuan: 'tongquan'
    };
```

Find (around line 967-978), remove the now-dead `thongtin` key from `SECTION_TITLES`:
```jsp
    const SECTION_TITLES = {
        datlich: 'Danh sách đặt lịch',
        tongquan: 'Tổng quan tài khoản',
        uytin: 'Điểm uy tín',
        thongtin: 'Thông tin cá nhân',
        caidat: 'Cài đặt',
        thongbao: 'Cài đặt thông báo',
        ngonngu: 'Ngôn ngữ',
        phienban: 'Thông tin phiên bản',
        dieukhoan: 'Điều khoản và chính sách',
        whatsnew: 'Ứng dụng có gì mới'
    };
```

Replace with:
```jsp
    const SECTION_TITLES = {
        datlich: 'Danh sách đặt lịch',
        tongquan: 'Tổng quan tài khoản',
        uytin: 'Điểm uy tín',
        caidat: 'Cài đặt',
        thongbao: 'Cài đặt thông báo',
        ngonngu: 'Ngôn ngữ',
        phienban: 'Thông tin phiên bản',
        dieukhoan: 'Điều khoản và chính sách',
        whatsnew: 'Ứng dụng có gì mới'
    };
```

- [ ] **Step 6: Delete the now-orphaned JS functions**

Delete these blocks entirely from the `<script>` section (they only exist to serve the now-deleted `#thongtin` section and its form, and reference IDs that no longer exist on this page):
1. `function enterEditMode(on) { ... }` (was calling `showAccountSection('thongtin')`, references `infoViewMode`/`infoEditForm`/`editToggleBtn`)
2. `function saveProfileInfo() { ... }` (references `editFullName`/`editEmail`/`editPhone`/`editBirthday`/`editGender`/`saveInfoBtn`/`infoEditForm`)
3. `function verifyEmailOtp() { ... }` (references `otpInput`/`otpTargetEmail`/`otpConfirmBtn`, calls `enterEditMode(false)`)
4. `function syncProfileUi(data) { ... }` (references `viewFullName`/`viewEmail`/`viewPhone`/`viewBirthday`/`viewGender`/`editFullName`/etc., but note it ALSO updates `accSummaryName`/`accSummaryEmail`/`accSummaryPhone` which are sidebar elements that DO still exist — see Step 7 for the replacement)
5. `function formatDateVn(iso) { ... }`
6. The `document.getElementById('accAvatarInput').addEventListener('change', function () { ... });` block (avatar upload — this logic now lives independently in `HoSo.jsp`; `TaiKhoan.jsp` no longer has an `accAvatarInput` element after Step 4's deletion, since it was inside the deleted section)
7. Remove `'emailOtpModal'` from the two remaining references in `TaiKhoan.jsp`'s modal-close wiring:
   ```jsp
    document.querySelectorAll('#pwModal, #emailOtpModal, #deleteAccountModal').forEach(overlay => {
   ```
   becomes:
   ```jsp
    document.querySelectorAll('#pwModal, #deleteAccountModal').forEach(overlay => {
   ```
   and
   ```jsp
        if (e.key === 'Escape') {
            closeModal('pwModal');
            closeModal('emailOtpModal');
            closeModal('deleteAccountModal');
        }
   ```
   becomes:
   ```jsp
        if (e.key === 'Escape') {
            closeModal('pwModal');
            closeModal('deleteAccountModal');
        }
   ```
   Also delete the `<!-- Email OTP modal -->` `<div id="emailOtpModal">...</div>` block itself (it has no opener left in `TaiKhoan.jsp` after this task — the OTP flow now lives entirely in `HoSo.jsp`).

- [ ] **Step 7: Keep the sidebar-summary sync path alive for other flows that still call it**

Check whether anything else in `TaiKhoan.jsp` (outside the deleted section) still calls `syncProfileUi` or references `accSummaryName`/`accSummaryEmail` expecting them to be live-updated after an edit. Run:

```bash
grep -n "syncProfileUi\|accSummaryName\|accSummaryEmail\|accSummaryPhone" src/main/webapp/customer/TaiKhoan.jsp
```

Expected: only the two static `<span id="accSummaryName">`/`<span id="accSummaryEmail">` declarations inside the profile card (now an `<a>`, from Step 1) should remain — no JS calls referencing them, since `saveProfileInfo`/`verifyEmailOtp`/`syncProfileUi` were all deleted in Step 6 and base-info editing no longer happens on this page. This is correct: `TaiKhoan.jsp` now only *displays* the account summary (fed by the JSP `${account.fullName}`/`${account.email}` expressions, refreshed on next page load), it no longer needs to live-sync those spans via JS, because editing now happens on `/customer/ho-so` and a normal navigation back to `/customer/tai-khoan` re-renders the JSP with fresh data. If the grep shows any other JS still referencing these functions/ids, stop and inspect it before proceeding — do not delete something still in use elsewhere.

- [ ] **Step 8: Compile/package check (JSP is validated by the servlet container at deploy time, not by mvn compile)**

Run: `mvn -q compile 2>&1 | tail -50` — expected: no output (this task only touches `.jsp`, so this mainly confirms nothing else broke).
Run: `grep -c 'data-section="thongtin"' src/main/webapp/customer/TaiKhoan.jsp` — expected: `0`.
Run: `grep -c 'id="infoEditForm"\|id="editFullName"\|id="emailOtpModal"' src/main/webapp/customer/TaiKhoan.jsp` — expected: `0`.
Run: `grep -c 'id="pwModal"\|id="deleteAccountModal"' src/main/webapp/customer/TaiKhoan.jsp` — expected: `2` (unchanged, still present).

- [ ] **Step 9: Commit**

```bash
git add src/main/webapp/customer/TaiKhoan.jsp
git commit -m "$(cat <<'EOF'
refactor: point sidebar profile card at /customer/ho-so, remove dead #thongtin section

Profile card and "Thông tin cá nhân" menu item now navigate to the new
standalone profile page instead of toggling an in-page section. The
now-unreachable #thongtin section, its edit form, email-OTP modal, and
associated JS (enterEditMode/saveProfileInfo/verifyEmailOtp/
syncProfileUi/formatDateVn/avatar-input listener) are removed — fully
relocated to HoSo.jsp. Password-change and delete-account modals are
untouched.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Build verification

**Files:** none created or modified — verification only.

**Interfaces:** none.

- [ ] **Step 1: Full compile**

Run: `mvn clean compile 2>&1 | tail -150`
Expected: `BUILD SUCCESS`, no errors. If `CustomerProfileServlet`/`CustomerProfileDAO`/`CustomerProfileDAOImpl`/`CustomerProfileExtraDTO` fail to resolve, re-check package names (`org.example.controller.customer`, `org.example.dao`, `org.example.dao.impl`, `org.example.dto`) exactly match Tasks 2 and 5.

- [ ] **Step 2: Test compile**

Run: `mvn test-compile 2>&1 | tail -100`
Expected: `BUILD SUCCESS`.

- [ ] **Step 3: Package**

Run: `mvn package -DskipTests 2>&1 | tail -150`
Expected: `BUILD SUCCESS`, `target/*.war` produced. This is also the first point JSP syntax errors in `HoSo.jsp`/`TaiKhoan.jsp` would surface if the build is configured to precompile JSPs; if not precompiled, JSP errors only appear at first request in Task 9.

- [ ] **Step 4: No commit needed** (verification-only task, nothing changed)

---

## Task 9: Manual runtime verification

**Files:** none created or modified — manual testing only, following `superpowers:verification-before-completion`.

**Interfaces:** none.

This task requires a running Tomcat + live database connection. If the environment used to execute this plan cannot reach both, **stop here and report explicitly that runtime testing was not performed** — do not claim success without having run these steps.

- [ ] **Step 1: Confirm current DB state before migration**

Run `sql/verify_customer_profile.sql` (read-only) against the real database. Expected: all `COL_LENGTH` values `NULL` (columns don't exist yet) — page must still work in this state (Step 4 below).

- [ ] **Step 2: Deploy and smoke-test WITHOUT the migration run yet**

Restart Tomcat with the freshly packaged WAR. Login as a Customer. Navigate to `/customer/tai-khoan`, then:
- Click the profile card background (not avatar/name/chevron specifically) → confirm it navigates to `/customer/ho-so`.
- Go back, click the avatar → confirm same route.
- Go back, click the name text → confirm same route.
- Go back, click the chevron → confirm same route.
- On `/customer/ho-so`: confirm no sidebar is visible, cover hero renders (gradient, since no cover set), overlay card shows real name/email/phone/gender, "Năm sinh" shows either a real year or `-`.
- Confirm "Thông tin thể chất" shows `-`/`-`, "Ghi chú đặc biệt" shows "Chưa có ghi chú", "Cá nhân hoá" rows all show `-` — this is the pre-migration state and must render cleanly, not 500.
- Check server log (`logs/` or console) for the expected `"Không thể tải hồ sơ mở rộng..."` warning logged by `CustomerProfileServlet` — confirms the SQLException was caught, not swallowed silently and not shown to the user.
- Click "Liên kết" tab → confirm it shows either real teams or the empty state, no error.
- Click back button → confirm it returns to `/customer/tai-khoan`.
- Refresh `/customer/ho-so` directly (paste URL) → confirm HTTP 200, not 404/500.
- Logout, then try to load `/customer/ho-so` directly → confirm redirect to `/dangnhap`, not an error page or exposed data.

- [ ] **Step 3: Run the migration**

Run `sql/migration_customer_profile.sql` against the real database (`QuanLiSport`) manually. Confirm via console/`PRINT` output that all 9 columns and their constraints were added (`ADDED Accounts.CoverImageUrl`, etc.).

- [ ] **Step 4: Run verify again**

Run `sql/verify_customer_profile.sql`. Expected: all `COL_LENGTH` values now non-null, check constraints and FK present, row counts all `0` (no data yet).

- [ ] **Step 5: Restart Tomcat, re-test full functionality**

- Avatar upload: choose a JPG under 2MB → confirm it updates immediately on the page and no page reload is required.
- Cover upload: choose a JPG/PNG/WEBP under 5MB → confirm the hero background updates immediately.
- Cover upload: try a >5MB file → confirm a clear error toast, no crash.
- Cover upload: try a `.txt` file renamed to `.jpg` → confirm rejected (magic-byte check catches it).
- Physical info: set height=175, weight=70, save → confirm values reflect immediately on the page; reload the page → confirm values persist.
- Physical info: try height=10 (below 50) → confirm rejected with a clear message.
- Special note: type a note, save → confirm it replaces the "Chưa có ghi chú" placeholder; reload → confirm it persists.
- Personalization: pick a real sport from the dropdown (confirm the list matches what's in the DB `MonTheThao` table, not hardcoded), pick a level, set a goal and frequency, save → confirm all four values render correctly; reload → confirm persistence.
- Base info edit ("Chỉnh sửa" on the overlay card): change phone number, save → confirm it updates on the card immediately, no OTP required (only email changes trigger OTP).
- Base info edit: change email → confirm OTP modal opens, confirm a real OTP email is sent (check inbox or logs), confirm entering the correct OTP completes the update and the card reflects the new email.
- Liên kết tab: if the test account is on a team (from the already-fixed Team module), confirm it now lists that team with correct role/member count.

- [ ] **Step 6: Responsive check**

Using browser devtools device toolbar (or resizing the window):
- Desktop ≥1200px: confirm profile card is horizontal, three fact fields are evenly spaced right-aligned, no sidebar, content fills the width.
- Tablet 768-1199px: confirm the card wraps without overlapping text, tabs remain full width.
- Mobile <768px: confirm hero is taller (~200px), profile card stacks vertically, no horizontal scrollbar anywhere on the page.

- [ ] **Step 7: Console/network check**

Open browser devtools Console and Network tabs while repeating Step 5's actions. Confirm zero JavaScript console errors and zero HTTP 404/500 responses across all requests triggered by this page.

- [ ] **Step 8: Report results**

Summarize, in the final report to the user: whether each of Steps 1-7 above was actually executed (not assumed), and the outcome of each. If any step could not be run (no DB/Tomcat access in this environment), say so explicitly rather than claiming the feature was fully verified.

---

## Self-Review Notes

- **Spec coverage:** cover hero (Task 4), back/camera buttons (Task 4), overlay card with avatar/name/email/phone/year/gender (Task 4), tab switcher (Task 4/6), Thông tin thể chất + edit (Task 6), Ghi chú đặc biệt + edit (Task 6), Cá nhân hoá 4 fields + edit with real MonTheThao dropdown (Task 6), Liên kết tab with real team data (Task 6/5), migration/verify/rollback SQL (Task 1), JPA-isolation decision (Task 2), sidebar click contract — row/avatar/name/chevron via one anchor (Task 7), back button real link not `history.back()` (Task 4), no `/Backend_java` hardcoding (all — every link uses `${pageContext.request.contextPath}`), responsive behavior (Task 9 verification), build + runtime verification (Tasks 8-9). All spec sections have a corresponding task.
- **Placeholder scan:** no TBD/TODO; every step has complete code or an exact command with expected output.
- **Type consistency:** `CustomerProfileExtraDTO` field names (`heightCm`, `weightKg`, `specialNote`, `preferredLocation`, `favoriteSportId`, `favoriteSportName`, `skillLevel`, `goal`, `playFrequency`, `coverImageUrl`) are used identically across Task 2 (definition), Task 5 (servlet sets `profileExtra` attribute), and Task 4/6 (JSP EL expressions `${profileExtra.heightCm}` etc.) — verified consistent. `CustomerProfileDAO` method signatures match between interface (Task 2 Step 2) and implementation (Task 2 Step 3) and servlet call sites (Task 5).
