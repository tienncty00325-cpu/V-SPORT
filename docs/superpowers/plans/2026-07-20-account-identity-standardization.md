# Account Identity Standardization (Email/Phone login, Username → internal-only) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove Username as a user-facing concept everywhere in V-SPORT — no user ever types, sees, or logs in with a Username again — while keeping the `Accounts.Username` DB column as an opaque internal identifier so existing schema/legacy queries keep working. Email and Phone become the only login identifiers, both mandatory and unique at account creation, across Customer, Admin, Manager, Staff/Lễ tân, Owner, and every account-creation entry point (admin add-staff, manager add-staff, owner self-registration, admin add-branch).

**Architecture:** Two small new shared utilities (`AccountInternalIdGenerator`, `DisplayNameUtil`) plus two derived getters on the `TaiKhoan` model (`getDisplayName()`, `getAvatarInitial()`) replace every hand-rolled `fullName != null ? fullName : username` fallback and every username-uniqueness-driven account creation path. Login queries drop the `OR a.username = :val` clause. A separate, idempotent SQL Server migration adds filtered unique indexes on `Email`/`PhoneNumber` after a data-safety check — it is NOT run automatically.

**Tech Stack:** Java 17, Jakarta Servlet/JSP, JSTL/EL, JPA/Hibernate (`SQLServerDialect`, `hibernate.hbm2ddl.auto=none` — schema is hand-migrated only), plain JDBC in a few DAOs, SQL Server, Maven WAR, Tomcat 10.1, BCrypt (jbcrypt), Jakarta Mail OTP, JUnit 5 + Mockito (existing `src/test/java/org/example/**`).

## Global Constraints

- Do not create a new project, change the tech stack, or reset/discard any uncommitted changes already in the working tree.
- `Accounts.Username` column is **never dropped, renamed, or made login-capable** in this plan — it becomes a write-only internal identifier, auto-generated, never read from a request parameter, never rendered to any user.
- Email and Phone become the two login identifiers; both are mandatory and must be validated + duplicate-checked before any new account (staff, manager, owner) is persisted.
- Preserve exactly as-is (do not refactor): BCrypt hashing (`BCrypt.gensalt(12)`), the dummy-BCrypt-hash timing-attack mitigation, `SimpleRateLimiter` rate limiting, the single generic login-failure message, session invalidate-then-recreate on login, `AuthPortalPolicy` portal/role checks, `RoleRedirectUtil` redirect-by-role, `isLocked`/facility-active checks, and the existing OTP-gated account-creation flow (`XacThucOTPServlet`).
- Never log or email a raw password anywhere it isn't already sent (the existing activation emails already include the password by design — do not add new logging of it).
- Error copy for duplicate/invalid identifiers must read exactly: "Email này đã được sử dụng bởi một tài khoản khác.", "Số điện thoại này đã được sử dụng bởi một tài khoản khác.", "Email không đúng định dạng.", "Số điện thoại không hợp lệ." — never "Tên đăng nhập đã tồn tại" in any new/edited code path.
- Email normalization is always `email.trim().toLowerCase(java.util.Locale.ROOT)` before validation, duplicate-check, and persistence. Phone normalization is always via the existing `org.example.util.PhoneUtil` (`normalizeVN` + `lookupVariants`), never the looser ad-hoc regexes in `ValidationUtil`/`ValidationUtils`.
- The SQL migration (Phase 6) is a script the operator runs by hand — it must never execute automatically, must be idempotent, and must refuse (print + skip, not fail) to create a unique index while duplicate Email/Phone data still exists.
- No hard-coded `AccountID`s. No silent auto-fixing of production data. No destructive `git` operations.

---

## Phase 0 — Shared identity infrastructure

### Task 1: `AccountInternalIdGenerator` utility

**Files:**
- Create: `src/main/java/org/example/util/AccountInternalIdGenerator.java`
- Test: `src/test/java/org/example/util/AccountInternalIdGeneratorTest.java`

**Interfaces:**
- Produces: `AccountInternalIdGenerator.generate() : String` and `AccountInternalIdGenerator.generateUnique(java.util.function.Predicate<String> alreadyExists) : String` — consumed by every account-creation call site in Phases 2–4 in place of `setUsername(request.getParameter("username"))`.

- [ ] **Step 1: Write the failing test**

```java
package org.example.util;

import org.junit.jupiter.api.Test;

import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AccountInternalIdGeneratorTest {

    @Test
    void generateCoDinhDangDungVaDoDaiHopLe() {
        String id = AccountInternalIdGenerator.generate();
        assertNotNull(id);
        assertTrue(id.length() <= 50, "internal id phải tối đa 50 ký tự");
        assertTrue(id.matches("^acct_[0-9a-f]{12}$"), "internal id phải đúng dạng acct_<12 hex>: " + id);
    }

    @Test
    void generateKhongTrungLapTrenNhieuLanGoi() {
        String a = AccountInternalIdGenerator.generate();
        String b = AccountInternalIdGenerator.generate();
        assertTrue(!a.equals(b), "hai lần generate liên tiếp không được trùng nhau");
    }

    @Test
    void generateUniqueThuLaiKhiTrungRoiTraVeKhiKhongTrung() {
        AtomicInteger callCount = new AtomicInteger(0);
        String result = AccountInternalIdGenerator.generateUnique(candidate -> callCount.incrementAndGet() <= 2);
        assertEquals(3, callCount.get(), "phải thử lại đúng 2 lần trước khi có candidate không trùng");
        assertTrue(result.matches("^acct_[0-9a-f]{12}$"));
    }

    @Test
    void generateUniqueKhongLapVoHanKhiLuonTrung() {
        AtomicInteger callCount = new AtomicInteger(0);
        String result = AccountInternalIdGenerator.generateUnique(candidate -> {
            callCount.incrementAndGet();
            return true;
        });
        assertEquals(6, callCount.get(), "phải dừng sau MAX_ATTEMPTS=5 lần thử lại (6 lần kiểm tra tổng cộng)");
        assertNotNull(result);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn test -Dtest=AccountInternalIdGeneratorTest`
Expected: FAIL — compile error, `AccountInternalIdGenerator` does not exist.

- [ ] **Step 3: Write minimal implementation**

```java
package org.example.util;

import java.security.SecureRandom;
import java.util.function.Predicate;

/**
 * Sinh mã định danh nội bộ cho Accounts.Username khi username không còn là
 * một trường người dùng tự nhập. Giá trị hoàn toàn ngẫu nhiên, không suy ra
 * từ email/số điện thoại/tên để tránh rò rỉ thông tin cá nhân qua Username,
 * và không được hiển thị ra bất kỳ giao diện nào.
 */
public final class AccountInternalIdGenerator {

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final String PREFIX = "acct_";
    private static final int RANDOM_HEX_CHARS = 12;
    private static final int MAX_ATTEMPTS = 5;

    private AccountInternalIdGenerator() {
    }

    public static String generate() {
        byte[] bytes = new byte[(RANDOM_HEX_CHARS + 1) / 2];
        RANDOM.nextBytes(bytes);
        StringBuilder hex = new StringBuilder();
        for (byte b : bytes) {
            hex.append(String.format("%02x", b));
        }
        return PREFIX + hex.substring(0, RANDOM_HEX_CHARS);
    }

    /**
     * Sinh id nội bộ và kiểm tra trùng qua {@code alreadyExists} (thường là
     * {@code taiKhoanDAO::kiemtraUsername}); thử lại tối đa MAX_ATTEMPTS lần
     * nếu trùng trước khi trả về candidate cuối cùng.
     */
    public static String generateUnique(Predicate<String> alreadyExists) {
        String candidate = generate();
        int attempts = 0;
        while (alreadyExists.test(candidate) && attempts < MAX_ATTEMPTS) {
            candidate = generate();
            attempts++;
        }
        return candidate;
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mvn test -Dtest=AccountInternalIdGeneratorTest`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/util/AccountInternalIdGenerator.java src/test/java/org/example/util/AccountInternalIdGeneratorTest.java
git commit -m "feat: add AccountInternalIdGenerator for opaque internal Username values"
```

---

### Task 2: `DisplayNameUtil` utility

**Files:**
- Create: `src/main/java/org/example/util/DisplayNameUtil.java`
- Test: `src/test/java/org/example/util/DisplayNameUtilTest.java`

**Interfaces:**
- Produces: `DisplayNameUtil.displayName(String fullName, String email, String phoneNumber) : String` (fallback: fullName → email → masked phone → `"Người dùng"`), and `DisplayNameUtil.avatarInitial(String fullName, String email) : String` (fallback: first char of fullName → first char of email → `"U"`). Consumed by `TaiKhoan.getDisplayName()`/`getAvatarInitial()` (Task 16), `NhanSuService.NhanSuDTO` (Task 12), `AuditLogService` (Task 19), and the JSON-API tasks (Task 20).

- [ ] **Step 1: Write the failing test**

```java
package org.example.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class DisplayNameUtilTest {

    @Test
    void displayNameUuTienFullName() {
        assertEquals("Nguyễn Thiện Nhân",
                DisplayNameUtil.displayName("Nguyễn Thiện Nhân", "nhan@example.com", "0786041209"));
    }

    @Test
    void displayNameRoiXuongEmailKhiFullNameTrong() {
        assertEquals("nhan@example.com", DisplayNameUtil.displayName(null, "nhan@example.com", "0786041209"));
        assertEquals("nhan@example.com", DisplayNameUtil.displayName("   ", "nhan@example.com", "0786041209"));
    }

    @Test
    void displayNameRoiXuongPhoneDaCheKhiFullNameVaEmailTrong() {
        assertEquals("078****209", DisplayNameUtil.displayName(null, null, "0786041209"));
        assertEquals("078****209", DisplayNameUtil.displayName("", "  ", "0786041209"));
    }

    @Test
    void displayNameTraVeNguoiDungKhiTatCaTrong() {
        assertEquals("Người dùng", DisplayNameUtil.displayName(null, null, null));
        assertEquals("Người dùng", DisplayNameUtil.displayName("", "", ""));
    }

    @Test
    void maskPhoneNganKhongDuDeChe() {
        assertEquals("***", DisplayNameUtil.displayName(null, null, "12345"));
    }

    @Test
    void avatarInitialUuTienFullNameRoiEmailRoiU() {
        assertEquals("N", DisplayNameUtil.avatarInitial("nguyễn Thiện Nhân", "nhan@example.com"));
        assertEquals("N", DisplayNameUtil.avatarInitial(null, "nhan@example.com"));
        assertEquals("U", DisplayNameUtil.avatarInitial(null, null));
        assertEquals("U", DisplayNameUtil.avatarInitial("  ", "  "));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn test -Dtest=DisplayNameUtilTest`
Expected: FAIL — compile error, `DisplayNameUtil` does not exist.

- [ ] **Step 3: Write minimal implementation**

```java
package org.example.util;

/**
 * Chuỗi fallback hiển thị tên/avatar dùng chung toàn hệ thống, thay cho việc
 * mỗi JSP/servlet tự viết `fullName != null ? fullName : username`. Không
 * bao giờ rơi xuống Username nội bộ — Username không còn là thông tin hiển
 * thị được cho người dùng.
 */
public final class DisplayNameUtil {

    private DisplayNameUtil() {
    }

    public static String displayName(String fullName, String email, String phoneNumber) {
        if (fullName != null && !fullName.trim().isEmpty()) {
            return fullName.trim();
        }
        if (email != null && !email.trim().isEmpty()) {
            return email.trim();
        }
        String masked = maskPhone(phoneNumber);
        if (masked != null) {
            return masked;
        }
        return "Người dùng";
    }

    public static String avatarInitial(String fullName, String email) {
        if (fullName != null && !fullName.trim().isEmpty()) {
            return fullName.trim().substring(0, 1).toUpperCase();
        }
        if (email != null && !email.trim().isEmpty()) {
            return email.trim().substring(0, 1).toUpperCase();
        }
        return "U";
    }

    /** "0786041209" -> "078****209". Trả null nếu không có gì để mask. */
    private static String maskPhone(String phoneNumber) {
        if (phoneNumber == null || phoneNumber.trim().isEmpty()) {
            return null;
        }
        String trimmed = phoneNumber.trim();
        if (trimmed.length() < 7) {
            return "***";
        }
        String head = trimmed.substring(0, 3);
        String tail = trimmed.substring(trimmed.length() - 3);
        int maskedLen = trimmed.length() - 6;
        StringBuilder stars = new StringBuilder();
        for (int i = 0; i < maskedLen; i++) {
            stars.append('*');
        }
        return head + stars + tail;
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mvn test -Dtest=DisplayNameUtilTest`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/util/DisplayNameUtil.java src/test/java/org/example/util/DisplayNameUtilTest.java
git commit -m "feat: add DisplayNameUtil for fullName/email/phone display fallback"
```

---

### Task 3: Drop Username from `validateStaffCreate`, make phone mandatory (both validator classes)

**Files:**
- Modify: `src/main/java/org/example/util/ValidationUtils.java:207-244`
- Modify: `src/main/java/org/example/util/ValidationUtil.java:269-306`
- Modify: `src/main/java/org/example/service/manager/NhanSuService.java:328-334` (call-site signature update, keeps this dead-code method compiling)
- Test: `src/test/java/org/example/util/ValidationUtilsStaffCreateTest.java`

**Interfaces:**
- Produces: `validateStaffCreate(String email, String phone, String fullName, int roleId) : Map<String,String>` (username param removed, phone now always validated) in **both** `ValidationUtils` and `ValidationUtil`. Consumed by `NhanSuManagerServlet` (Task 11) and `NhanSuService.createStaff` (dead code, updated here only to keep it compiling).

- [ ] **Step 1: Write the failing test**

```java
package org.example.util;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ValidationUtilsStaffCreateTest {

    @Test
    void hopLeKhiCoDayDuEmailVaPhone() {
        Map<String, String> errors = ValidationUtils.validateStaffCreate(
                "nhan@example.com", "0786041209", "Nguyễn Thiện Nhân", 4);
        assertTrue(errors.isEmpty(), errors.toString());
    }

    @Test
    void baoLoiKhiThieuPhone() {
        Map<String, String> errors = ValidationUtils.validateStaffCreate(
                "nhan@example.com", "", "Nguyễn Thiện Nhân", 4);
        assertTrue(errors.containsKey("phone"), "phone rỗng phải bị từ chối vì giờ là bắt buộc");
    }

    @Test
    void baoLoiKhiPhoneSaiDinhDang() {
        Map<String, String> errors = ValidationUtils.validateStaffCreate(
                "nhan@example.com", "123", "Nguyễn Thiện Nhân", 4);
        assertTrue(errors.containsKey("phone"));
    }

    @Test
    void khongConTruongUsernameTrongLoi() {
        Map<String, String> errors = ValidationUtils.validateStaffCreate(
                "invalid-email", "", "", 4);
        assertFalse(errors.containsKey("username"), "validateStaffCreate không còn kiểm tra username");
    }

    @Test
    void tuChoiVaiTroAdminVaManager() {
        Map<String, String> errors1 = ValidationUtils.validateStaffCreate(
                "nhan@example.com", "0786041209", "Nguyễn Thiện Nhân", 1);
        Map<String, String> errors2 = ValidationUtils.validateStaffCreate(
                "nhan@example.com", "0786041209", "Nguyễn Thiện Nhân", 2);
        assertTrue(errors1.containsKey("role"));
        assertTrue(errors2.containsKey("role"));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn test -Dtest=ValidationUtilsStaffCreateTest`
Expected: FAIL — compile error (current signature still takes `username` as first param).

- [ ] **Step 3: Update `ValidationUtils.java`**

Replace `src/main/java/org/example/util/ValidationUtils.java:207-244`:

```java
    // ========== COMBINED VALIDATIONS ==========
    public static Map<String, String> validateStaffCreate(
        String email, String phone, String fullName, int roleId
    ) {
        Map<String, String> errors = new HashMap<>();

        try {
            validateEmail(email);
        } catch (IllegalArgumentException e) {
            errors.put("email", e.getMessage());
        }

        try {
            validateVietnamPhone(phone);
        } catch (IllegalArgumentException e) {
            errors.put("phone", e.getMessage());
        }

        try {
            validateRequiredString(fullName, "fullName");
        } catch (IllegalArgumentException e) {
            errors.put("fullName", e.getMessage());
        }

        // Role check
        if (roleId == 1 || roleId == 2) {
            errors.put("role", "Không thể tạo tài khoản có quyền Quản trị hoặc Quản lý");
        }

        return errors;
    }
```

- [ ] **Step 4: Update `ValidationUtil.java`**

Replace `src/main/java/org/example/util/ValidationUtil.java:264-306`:

```java
    // ==================== COMBINED VALIDATIONS ====================
    /**
     * Validate tất cả fields cho việc tạo staff mới
     * @return Map của errors, empty nếu không có lỗi
     */
    public static Map<String, String> validateStaffCreate(
        String email, String phone, String fullName, int roleId
    ) {
        Map<String, String> errors = new HashMap<>();

        try {
            validateEmail(email);
        } catch (IllegalArgumentException e) {
            errors.put("email", e.getMessage());
        }

        try {
            validateVietnamPhone(phone);
        } catch (IllegalArgumentException e) {
            errors.put("phone", e.getMessage());
        }

        try {
            validateRequiredString(fullName, "Họ và tên");
        } catch (IllegalArgumentException e) {
            errors.put("fullName", e.getMessage());
        }

        // Role check
        if (roleId == 1 || roleId == 2) {
            errors.put("role", "Không thể tạo tài khoản có quyền Quản trị hoặc Quản lý");
        }

        return errors;
    }
```

- [ ] **Step 5: Fix the dead-code call site so the project still compiles**

In `src/main/java/org/example/service/manager/NhanSuService.java:319-348`, `createStaff(...)` is unused in production (confirmed: no caller anywhere in the codebase) but must still compile. Replace lines 327-344:

```java
        // Kiểm tra tính hợp lệ dữ liệu đầu vào
        Map<String, String> errors = ValidationUtils.validateStaffCreate(
            request.getEmail(),
            request.getPhoneNumber(),
            request.getFullName(),
            request.getRoleId()
        );

        // Kiểm tra email đã tồn tại
        if (taiKhoanDAO.kiemtraEmail(request.getEmail())) {
            errors.put("email", "Email đã tồn tại trên hệ thống");
        }

        // Kiểm tra số điện thoại đã tồn tại
        String normalizedPhone = org.example.util.PhoneUtil.normalizeVN(request.getPhoneNumber());
        if (normalizedPhone != null && taiKhoanDAO.kiemtraPhone(org.example.util.PhoneUtil.lookupVariants(normalizedPhone))) {
            errors.put("phone", "Số điện thoại đã tồn tại trên hệ thống");
        }

        if (!errors.isEmpty()) {
            throw new IllegalArgumentException(errors.toString());
        }
```

And replace line 360 (`newAcc.setUsername(request.getUsername());`) with:

```java
        newAcc.setUsername(org.example.util.AccountInternalIdGenerator.generateUnique(taiKhoanDAO::kiemtraUsername));
```

This keeps `StaffCreateRequest.username`/`getUsername()`/`setUsername()` in place unused (harmless, dead-code-on-dead-code) rather than touching its public shape — no other file reads `StaffCreateRequest.getUsername()`.

- [ ] **Step 6: Run test to verify it passes**

Run: `mvn test -Dtest=ValidationUtilsStaffCreateTest`
Expected: PASS (5 tests)

- [ ] **Step 7: Full compile check (other callers of validateStaffCreate)**

Run: `mvn -q compile`
Expected: BUILD SUCCESS. (Confirms no other call site still passes a `username` argument — the only two call sites are `NhanSuManagerServlet.java:133`, updated in Task 12, and `NhanSuService.java:328`, updated above.)

- [ ] **Step 8: Commit**

```bash
git add src/main/java/org/example/util/ValidationUtils.java src/main/java/org/example/util/ValidationUtil.java src/main/java/org/example/service/manager/NhanSuService.java src/test/java/org/example/util/ValidationUtilsStaffCreateTest.java
git commit -m "refactor: drop username from validateStaffCreate, require phone"
```

---

## Phase 1 — Login: Email or Phone only

### Task 4: Drop Username from the account-login DAO query

**Files:**
- Modify: `src/main/java/org/example/dao/impl/TaiKhoanDAOImpl.java:324-347`
- Modify: `src/main/java/org/example/dao/TaiKhoanDAO.java:15` (javadoc only, signature unchanged)

No test file — this method has no existing unit-test harness (no DAO tests exist in the repo; they'd require a live SQL Server connection). Verified instead in Task 26's manual CASE 4 checklist.

- [ ] **Step 1: Update the interface javadoc**

In `src/main/java/org/example/dao/TaiKhoanDAO.java`, replace line 15:

```java
    /** Đăng nhập bằng Email (KHÔNG còn chấp nhận Username). */
    TaiKhoan dangNhapKhachHang(String email, String password);
```

- [ ] **Step 2: Drop the Username clause from the JPQL**

In `src/main/java/org/example/dao/impl/TaiKhoanDAOImpl.java`, the current method (lines ~324-347) reads:

```java
    public TaiKhoan dangNhapKhachHang(String usernameOrEmail, String password) {
        ...
        List<TaiKhoan> accounts = em.createQuery(
                "SELECT a FROM TaiKhoan a WHERE (a.username = :val OR a.email = :val) AND a.isLocked = false AND (a.isDeleted = false OR a.isDeleted IS NULL)",
                TaiKhoan.class)
                .setParameter("val", usernameOrEmail)
                .getResultList();
        ...
```

Replace the method signature and query with:

```java
    public TaiKhoan dangNhapKhachHang(String email, String password) {
        ...
        List<TaiKhoan> accounts = em.createQuery(
                "SELECT a FROM TaiKhoan a WHERE a.email = :email AND a.isLocked = false AND (a.isDeleted = false OR a.isDeleted IS NULL)",
                TaiKhoan.class)
                .setParameter("email", email)
                .getResultList();
        ...
```

(Keep the rest of the method — the BCrypt check and dummy-hash fallback — byte-for-byte unchanged; only the query string, the parameter name, and the method's own parameter name change.)

- [ ] **Step 3: Compile check**

Run: `mvn -q compile`
Expected: BUILD SUCCESS.

- [ ] **Step 4: Commit**

```bash
git add src/main/java/org/example/dao/TaiKhoanDAO.java src/main/java/org/example/dao/impl/TaiKhoanDAOImpl.java
git commit -m "fix: drop Username from account-login query, email-only"
```

---

### Task 5: `DangNhapServlet` — read/normalize `email`, not `username`

**Files:**
- Modify: `src/main/java/org/example/controller/DangNhapServlet.java`

- [ ] **Step 1: Rename the parameter read and normalize email**

Replace line 95:

```java
        String usernameOrEmail = req.getParameter("username");
```

with:

```java
        String email = req.getParameter("email");
        if (email != null) {
            email = email.trim().toLowerCase(java.util.Locale.ROOT);
        }
```

- [ ] **Step 2: Update every remaining reference to `usernameOrEmail` in this file**

Rename every other occurrence of the local variable `usernameOrEmail` to `email` in the same file: line 103 (`String identifier = isPhoneLogin ? rawPhone : usernameOrEmail;`), line 144 (`: (usernameOrEmail == null ? "" : usernameOrEmail.trim().toLowerCase());` — this normalization is now redundant since `email` is pre-normalized in Step 1, simplify to `: email;`), line 150, 189, 224, 310, 333/339 (`maskIdentifier` parameter), and 346. Concretely:

Line 142-144, replace:
```java
        String normalizedIdentifierForKey = isPhoneLogin
                ? normalizedPhone
                : (usernameOrEmail == null ? "" : usernameOrEmail.trim().toLowerCase());
```
with:
```java
        String normalizedIdentifierForKey = isPhoneLogin ? normalizedPhone : (email == null ? "" : email);
```

Line 149-150, replace `usernameOrEmail` with `email` in the `maskIdentifier(...)` call.

Line 189, replace:
```java
                taiKhoan = TaiKhoanDAO.dangNhapKhachHang(usernameOrEmail, password);
```
with:
```java
                taiKhoan = TaiKhoanDAO.dangNhapKhachHang(email, password);
```

Lines 157, 213, 251, 269, 319 — every `req.setAttribute("username", usernameOrEmail);` becomes `req.setAttribute("email", email);` (this attribute repopulates the JSP form field on a failed attempt; Task 6/7 renames the JSP field to read `${email}` instead of `${username}`).

Line 310, replace `usernameOrEmail` with `email` in the `maskIdentifier(isPhoneLogin, usernameOrEmail, normalizedPhone)` call.

Line 333, rename the `maskIdentifier` parameter itself:
```java
    private String maskIdentifier(boolean isPhone, String email, String normalizedPhone) {
```
and inside it, line 339, replace `String v = usernameOrEmail != null ? usernameOrEmail.trim() : "";` with `String v = email != null ? email : "";` (already normalized, no need to `.trim()` again).

- [ ] **Step 3: Compile check**

Run: `mvn -q compile`
Expected: BUILD SUCCESS — this confirms no stray `usernameOrEmail` reference remains in the file.

Run: `grep -n "usernameOrEmail" src/main/java/org/example/controller/DangNhapServlet.java`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add src/main/java/org/example/controller/DangNhapServlet.java
git commit -m "refactor: DangNhapServlet reads/normalizes email, drops username param"
```

---

### Task 6: `DangNhap.jsp` (customer portal) — rename field, fix copy

**Files:**
- Modify: `src/main/webapp/auth/DangNhap.jsp`

- [ ] **Step 1: Rename the input and fix the mismatched placeholder**

Replace (around `DangNhap.jsp:172-179`):

```html
<label class="auth-label" for="login-username">Email của bạn?</label>
...
<input class="auth-input" type="text" name="username" id="login-username"
       autocomplete="username"
       placeholder="Nhập email hoặc tên đăng nhập"
       ...
       value="<c:out value='${username}'/>"
```

with:

```html
<label class="auth-label" for="login-email">Email của bạn?</label>
...
<input class="auth-input" type="email" name="email" id="login-email"
       autocomplete="email"
       placeholder="Nhập email đã đăng ký"
       ...
       value="<c:out value='${email}'/>"
```

- [ ] **Step 2: Update the inline JS to reference the renamed field/id**

Wherever the script (around `DangNhap.jsp:229-318`) does `document.getElementById('login-username')` or holds a `usernameInput` variable, rename to `login-email` / `emailInput`. Update the validation message:

```js
    } else if (!usernameInput.value.trim()) {
        setFieldError(usernameInput, 'Vui lòng nhập email hoặc tên đăng nhập.');
        ok = false;
    }
```

becomes:

```js
    } else if (!emailInput.value.trim()) {
        setFieldError(emailInput, 'Vui lòng nhập email.');
        ok = false;
    }
```

- [ ] **Step 3: Manual verification**

Run: `mvn -q package` then deploy/redeploy the WAR to Tomcat (or use the project's existing `run`/dev-server workflow).
In a browser: open `/dangnhap`, switch to the "Email" tab, submit with an empty email — confirm the inline error reads "Vui lòng nhập email." (not "...hoặc tên đăng nhập"). Submit with a valid email + wrong password — confirm the generic failure message shows and the email value is retained in the field (proves `req.setAttribute("email", email)` from Task 5 round-trips into `${email}` here).

- [ ] **Step 4: Commit**

```bash
git add src/main/webapp/auth/DangNhap.jsp
git commit -m "fix: DangNhap.jsp login field is email-only, drop username copy"
```

---

### Task 7: `DangNhapNoiBo.jsp` (internal portal) — rename field, fix copy

**Files:**
- Modify: `src/main/webapp/auth/DangNhapNoiBo.jsp`

- [ ] **Step 1: Rename the input and label**

Replace (around `DangNhapNoiBo.jsp:147-153`):

```html
<label class="auth-label" for="internal-username">Tên đăng nhập hoặc email</label>
...
<input class="auth-input" type="text" name="username" id="internal-username"
       autocomplete="username"
       placeholder="Nhập tên đăng nhập hoặc email"
       aria-describedby="internal-username-error"
       value="<c:out value='${username}'/>" required/>
```

with:

```html
<label class="auth-label" for="internal-email">Email</label>
...
<input class="auth-input" type="email" name="email" id="internal-email"
       autocomplete="email"
       placeholder="Nhập email đã đăng ký"
       aria-describedby="internal-email-error"
       value="<c:out value='${email}'/>" required/>
```

Also rename any `id="internal-username-error"` error-message container to `internal-email-error` to match the new `aria-describedby`.

- [ ] **Step 2: Update the inline JS**

Around `DangNhapNoiBo.jsp:196-236`, rename the `usernameInput` variable/`getElementById('internal-username')` to `emailInput`/`internal-email`, and change:

```js
    if (!usernameInput.value.trim()) {
        setFieldError(usernameInput, 'Vui lòng nhập tên đăng nhập hoặc email.');
        ok = false;
    }
```

to:

```js
    if (!emailInput.value.trim()) {
        setFieldError(emailInput, 'Vui lòng nhập email.');
        ok = false;
    }
```

- [ ] **Step 3: Manual verification**

Deploy and open `/he-thong/dang-nhap`. Confirm the label reads "Email" (not "Tên đăng nhập hoặc email"), the placeholder reads "Nhập email đã đăng ký", and submitting an old Username value + correct password for a real internal (Admin/Manager/Staff) account **fails** with the generic message (this is CASE 4's "Username cũ + password đúng: phải thất bại" — proven by Task 4's query no longer matching on username).

- [ ] **Step 4: Commit**

```bash
git add src/main/webapp/auth/DangNhapNoiBo.jsp
git commit -m "fix: DangNhapNoiBo.jsp login field is email-only, drop username copy"
```

*(`src/main/webapp/auth/AuthModal.jsp` still contains a `name="username"` login field but is confirmed dead code — no JSP includes it and no servlet forwards to it. Left untouched in this plan; flagged in the final report for a follow-up cleanup/deletion decision.)*

---

## Phase 2 — Admin add/edit staff: remove Username, require Email + Phone

### Task 8: `admin/NhanSu.jsp` — remove the Username field

**Files:**
- Modify: `src/main/webapp/admin/NhanSu.jsp`

- [ ] **Step 1: Remove the Username input from the shared add/edit form**

Delete the block at `admin/NhanSu.jsp:179-183`:

```html
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-semibold text-zinc-600">Tên đăng nhập <span class="text-red-500">*</span></label>
              <input type="text" id="staffUsername" required class="h-9 px-3 rounded-lg border border-zinc-200 text-sm focus:ring-2 focus:ring-blue-400 focus:border-blue-500 focus:outline-none transition-all">
            </div>
```

Since this was the second cell of a `grid-cols-2` row (paired with "Họ và tên"), replace the now-single-column row wrapper at lines 174-183 so "Họ và tên" spans full width, and move phone's `required` marker in ahead of schedule (phone becomes required below in Step 2). Full replacement for `admin/NhanSu.jsp:174-183`:

```html
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-semibold text-zinc-600">Họ và tên <span class="text-red-500">*</span></label>
            <input type="text" id="staffName" required class="h-9 px-3 rounded-lg border border-zinc-200 text-sm focus:ring-2 focus:ring-blue-400 focus:border-blue-500 focus:outline-none transition-all">
          </div>
```

- [ ] **Step 2: Make Phone required with its own error slot**

Replace `admin/NhanSu.jsp:210-213`:

```html
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-semibold text-zinc-600">Điện thoại</label>
              <input type="tel" id="staffPhone" class="h-9 px-3 rounded-lg border border-zinc-200 text-sm focus:ring-2 focus:ring-blue-400 focus:border-blue-500 focus:outline-none transition-all">
            </div>
```

with:

```html
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-semibold text-zinc-600">Điện thoại <span class="text-red-500">*</span></label>
              <input type="tel" id="staffPhone" required placeholder="0786041209" class="h-9 px-3 rounded-lg border border-zinc-200 text-sm focus:ring-2 focus:ring-blue-400 focus:border-blue-500 focus:outline-none transition-all">
              <span id="staffPhoneError" class="text-xs text-red-500 hidden"></span>
            </div>
```

Also add a matching error slot under Email — replace `admin/NhanSu.jsp:206-208`:

```html
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-semibold text-zinc-600">Email <span class="text-red-500">*</span></label>
            <input type="email" id="staffEmail" required class="h-9 px-3 rounded-lg border border-zinc-200 text-sm focus:ring-2 focus:ring-blue-400 focus:border-blue-500 focus:outline-none transition-all">
          </div>
```

with:

```html
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-semibold text-zinc-600">Email <span class="text-red-500">*</span></label>
            <input type="email" id="staffEmail" required placeholder="name@example.com" class="h-9 px-3 rounded-lg border border-zinc-200 text-sm focus:ring-2 focus:ring-blue-400 focus:border-blue-500 focus:outline-none transition-all">
            <span id="staffEmailError" class="text-xs text-red-500 hidden"></span>
          </div>
```

- [ ] **Step 3: Stop sending `username`, stop disabling phone on edit**

Replace `admin/NhanSu.jsp:750-767` (`handleStaffSubmit`) — remove the username append and clear any previous field errors up front:

```js
async function handleStaffSubmit(e) {
  e.preventDefault();
  document.getElementById('staffEmailError').classList.add('hidden');
  document.getElementById('staffPhoneError').classList.add('hidden');
  const editId = document.getElementById('staffEditId').value;

  const params = new URLSearchParams();
  params.append('action', editId ? 'update' : 'add');
  if (editId) params.append('accountId', editId);

  params.append('fullName', document.getElementById('staffName').value);
  params.append('email', document.getElementById('staffEmail').value);
  params.append('phoneNumber', document.getElementById('staffPhone').value);
  params.append('roleId', document.getElementById('staffRole').value);
  if (document.getElementById('staffRole').value == '2') {
    params.append('coSoId', document.getElementById('staffCoSo').value);
  }
  params.append('password', document.getElementById('staffPassword').value);
```

(Only the `username`-appending `else` branch at old line 757 is removed; everything else in this function is unchanged — do not touch the fetch call or response handling below it.)

Since phone is now required and editable on both add and edit, remove the line that disables it in `editStaff()`. Replace `admin/NhanSu.jsp:661-671`:

```js
function editStaff(id) {
  const s = staffList.find(x => x.id == id);
  if (!s) return;
  document.getElementById('staffModalTitle').innerText = 'Chỉnh sửa tài khoản';
  document.getElementById('staffEditId').value = s.id;
  document.getElementById('staffName').value = s.name;
  document.getElementById('staffEmail').value = s.email;
  document.getElementById('staffPhone').value = s.phone;
```

(Drop the `staffUsername.value = s.username` / `staffUsername.disabled = true` lines and the `staffPhone.disabled = true` line — phone can now be edited, subject to the server-side duplicate check added in Task 9.)

In `openAddStaff()`, replace `admin/NhanSu.jsp:629-633`:

```js
function openAddStaff() {
  document.getElementById('staffForm').reset();
  document.getElementById('staffModalTitle').innerText = 'Thêm nhân sự mới';
  document.getElementById('staffEditId').value = '';
}
```

(Drop the `staffUsername.disabled = false` line — the element no longer exists.)

- [ ] **Step 4: Remove `username` from the client-side data model, fallback, and search**

Replace `admin/NhanSu.jsp:276-293` (`staffList` construction) — drop the `username:` field and switch the name/initial fallback to the server-computed `displayName`/`initial` fields (wired up server-side in Task 19):

```jsp
let staffList = [
  <c:forEach items="${accounts}" var="acc" varStatus="loop">
    {
      id: '${acc.accountId}',
      name: '<c:out value="${acc.displayName}" />',
      email: '<c:out value="${acc.email}" />',
      phone: '<c:out value="${acc.phoneNumber}" />',
      initial: '<c:out value="${acc.avatarInitial}" />',
```

(Keep every other field on this object as-is; only the `username:` line is removed and `name`/`initial` now read `${acc.displayName}`/`${acc.avatarInitial}` — these two getters are added onto the `TaiKhoan` model in Task 16, so this task depends on Task 16 landing first, or on a placeholder EL expression `${acc.fullName != null && !acc.fullName.trim().isEmpty() ? acc.fullName : acc.email}` /`${(acc.fullName != null && !acc.fullName.trim().isEmpty()) ? acc.fullName.substring(0,1).toUpperCase() : acc.email.substring(0,1).toUpperCase()}` if executed before Task 16 — prefer sequencing Task 16 first to avoid writing this fallback twice.)

Apply the identical `username:` removal to the deleted-accounts list at `admin/NhanSu.jsp:295-306`.

Replace the search filter at `admin/NhanSu.jsp:378-385`, dropping the username clause:

```js
  const searchValue = document.getElementById('adminSearchInput') ? document.getElementById('adminSearchInput').value.toLowerCase().trim() : '';
  const filtered = staffList.filter(s => {
    return s.name.toLowerCase().includes(searchValue) ||
           (s.email && s.email.toLowerCase().includes(searchValue)) ||
           (s.phone && s.phone.toLowerCase().includes(searchValue)) ||
           s.VaiTro.toLowerCase().includes(searchValue);
  });
```

- [ ] **Step 5: Manual verification**

Deploy, open `/admin/nhan-su`, click "Thêm nhân sự mới" — confirm there is no "Tên đăng nhập" field, confirm Email and Phone both show a red `*` and browser-level `required`. Search the staff grid by a known staff member's email substring and phone substring — confirm both find the row (search-by-username is gone but search-by-email/phone still works).

- [ ] **Step 6: Commit**

```bash
git add src/main/webapp/admin/NhanSu.jsp
git commit -m "feat: admin add/edit-staff modal drops Username, requires Phone"
```

---

### Task 9: `QuanLyNguoiDungServlet` — drop username, require+dedupe phone

**Files:**
- Modify: `src/main/java/org/example/controller/admin/QuanLyNguoiDungServlet.java:92-362`

- [ ] **Step 1: Add branch — replace the username block with auto-generated internal id, switch phone to mandatory+PhoneUtil**

Replace `QuanLyNguoiDungServlet.java:207-265`:

```java
        } else if ("add".equals(action)) {
            boolean isAjax = "XMLHttpRequest".equals(req.getHeader("X-Requested-With"));
            String email = req.getParameter("email");
            String phoneNumber = req.getParameter("phoneNumber");

            if (email != null) email = email.trim().toLowerCase(java.util.Locale.ROOT);
            if (phoneNumber != null) phoneNumber = phoneNumber.trim();

            if (email == null || email.isEmpty()) {
                String msg = "Email không được để trống!";
                if (isAjax) { sendJsonError(resp, msg); return; }
                req.getSession().setAttribute("error", msg);
                resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                return;
            }

            if (!org.example.util.ValidationUtil.isValidEmail(email)) {
                String msg = "Email không đúng định dạng.";
                if (isAjax) { sendJsonError(resp, msg); return; }
                req.getSession().setAttribute("error", msg);
                resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                return;
            }

            if (TaiKhoanDAO.kiemtraEmail(email)) {
                String msg = "Email này đã được sử dụng bởi một tài khoản khác.";
                if (isAjax) { sendJsonError(resp, msg); return; }
                req.getSession().setAttribute("error", msg);
                resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                return;
            }

            String normalizedPhone = org.example.util.PhoneUtil.normalizeVN(phoneNumber);
            if (normalizedPhone == null) {
                String msg = "Số điện thoại không hợp lệ.";
                if (isAjax) { sendJsonError(resp, msg); return; }
                req.getSession().setAttribute("error", msg);
                resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                return;
            }

            if (TaiKhoanDAO.kiemtraPhone(org.example.util.PhoneUtil.lookupVariants(normalizedPhone))) {
                String msg = "Số điện thoại này đã được sử dụng bởi một tài khoản khác.";
                if (isAjax) { sendJsonError(resp, msg); return; }
                req.getSession().setAttribute("error", msg);
                resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                return;
            }
            phoneNumber = normalizedPhone;
```

(This drops the old `username`-read/validate/`kiemtraUsername` block at old lines 209/213/217-231, keeps the old email-empty/format/duplicate checks at old lines 233-255 but with updated copy, and replaces the old "format-only-if-present" phone check at old lines 257-265 with a mandatory normalize+duplicate check.)

Replace `QuanLyNguoiDungServlet.java:270-274` (account construction — was `newAcc.setUsername(username);`):

```java
            TaiKhoan newAcc = new TaiKhoan();
            newAcc.setUsername(org.example.util.AccountInternalIdGenerator.generateUnique(TaiKhoanDAO::kiemtraUsername));
            newAcc.setFullName(fullName);
            newAcc.setEmail(email);
            newAcc.setPhoneNumber(phoneNumber);
```

(`fullName` is still read at old line 267-268, unchanged — only the block above it changes.)

- [ ] **Step 2: Update branch — add a symmetric phone-duplicate check**

Replace `QuanLyNguoiDungServlet.java:100-128`:

```java
                    String email = req.getParameter("email");
                    String phone = req.getParameter("phoneNumber");
                    String fullName = req.getParameter("fullName");
                    if (email != null) email = email.trim().toLowerCase(java.util.Locale.ROOT);
                    if (phone != null) phone = phone.trim();
                    if (fullName != null) fullName = fullName.trim();

                    if (!org.example.util.ValidationUtil.isValidEmail(email)) {
                        req.getSession().setAttribute("error", "Email không đúng định dạng.");
                        resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                        return;
                    }

                    // Check if email has changed
                    boolean isEmailChanged = (email != null && !email.equalsIgnoreCase(acc.getEmail()));
                    if (isEmailChanged) {
                        if (TaiKhoanDAO.kiemtraEmail(email)) {
                            req.getSession().setAttribute("error", "Email này đã được sử dụng bởi một tài khoản khác.");
                            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                            return;
                        }
                    }

                    boolean isPhoneChanged = (phone != null && !phone.equals(acc.getPhoneNumber()));
                    if (isPhoneChanged) {
                        String normalizedPhone = org.example.util.PhoneUtil.normalizeVN(phone);
                        if (normalizedPhone == null) {
                            req.getSession().setAttribute("error", "Số điện thoại không hợp lệ.");
                            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                            return;
                        }
                        if (TaiKhoanDAO.kiemtraPhone(org.example.util.PhoneUtil.lookupVariants(normalizedPhone))) {
                            req.getSession().setAttribute("error", "Số điện thoại này đã được sử dụng bởi một tài khoản khác.");
                            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                            return;
                        }
                        phone = normalizedPhone;
                    }
```

(This replaces the old format-only `ValidationUtil.isValidVNPhone(phone)` check at old lines 112-118 with a normalize+duplicate-check pair, mirroring the email branch. `acc.setPhoneNumber(phone)` a few lines below at old line 131 is unchanged — `phone` now holds the normalized value when it changed.)

- [ ] **Step 3: Compile check**

Run: `mvn -q compile`
Expected: BUILD SUCCESS.

- [ ] **Step 4: Manual verification (CASE 2 from the spec)**

Deploy. As Admin, create a Manager/Staff with a phone number that already belongs to another account — confirm rejection with "Số điện thoại này đã được sử dụng bởi một tài khoản khác." Create one with a brand-new email+phone — confirm OTP is sent, and after OTP confirmation the account logs in successfully with either the email or the phone (CASE 2's "Đăng nhập email/phone thành công").

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/controller/admin/QuanLyNguoiDungServlet.java
git commit -m "feat: admin staff create/update drops username, requires+dedupes phone"
```

---

## Phase 3 — Manager add/edit staff: remove Username, require Email + Phone

### Task 10: `manager/NhanSu.jsp` — remove the Username field

**Files:**
- Modify: `src/main/webapp/manager/NhanSu.jsp`

- [ ] **Step 1: Remove the Username input**

Delete `manager/NhanSu.jsp:209-212`:

```html
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-semibold text-violet-900">Tên đăng nhập <span class="text-red-500">*</span></label>
              <input type="text" id="staffUsername" required class="h-9 px-3 rounded-lg border border-violet-100 text-sm focus:ring-2 focus:ring-violet-400 focus:outline-none">
            </div>
```

and collapse the `grid-cols-2` row at lines 204-213 to a single full-width "Họ và tên" field, matching Task 8 Step 1's treatment of the admin JSP.

- [ ] **Step 2: Make Phone required**

Replace `manager/NhanSu.jsp:226-229`:

```html
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-semibold text-violet-900">Điện thoại</label>
              <input type="tel" id="staffPhone" class="h-9 px-3 rounded-lg border border-violet-100 text-sm focus:ring-2 focus:ring-violet-400 focus:outline-none">
            </div>
```

with:

```html
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-semibold text-violet-900">Điện thoại <span class="text-red-500">*</span></label>
              <input type="tel" id="staffPhone" required placeholder="0786041209" class="h-9 px-3 rounded-lg border border-violet-100 text-sm focus:ring-2 focus:ring-violet-400 focus:outline-none">
              <span id="staffPhoneError" class="text-xs text-red-500 hidden"></span>
            </div>
```

Add the same `id="staffEmailError"` error slot under the Email field at `manager/NhanSu.jsp:222-224`, add `placeholder="name@example.com"`, matching Task 8 Step 2.

- [ ] **Step 3: Stop sending `username`, stop disabling username/phone in JS**

Replace the params-building block at `manager/NhanSu.jsp:546-558`:

```js
    const editId = document.getElementById('staffEditId').value;
    const params = new URLSearchParams();
    params.append('action', editId ? 'update' : 'add');
    if (editId) {
        params.append('accountId', editId);
    }
    params.append('fullName', document.getElementById('staffName').value);
    params.append('email', document.getElementById('staffEmail').value);
    params.append('phoneNumber', document.getElementById('staffPhone').value);
    params.append('roleId', document.getElementById('staffRole').value);
    params.append('password', document.getElementById('staffPassword').value);
```

(Drops the `else { params.append('username', ...) }` branch entirely.)

In `openAddStaff()` (`manager/NhanSu.jsp:454-468`), delete the `document.getElementById('staffUsername').disabled = false;` line (element no longer exists).

In `editStaff()` (`manager/NhanSu.jsp:470-488`), delete `document.getElementById('staffUsername').value = s.username;` and `document.getElementById('staffUsername').disabled = true;`.

- [ ] **Step 4: Drop the username display in the leave-request caption**

Replace `manager/NhanSu.jsp:817-820`:

```js
            +     '<div>'
            +       '<div class="text-sm font-semibold text-zinc-800">' + req.tenNhanVien + '</div>'
            +       '<div class="text-xs text-zinc-400 font-mono mt-0.5">' + req.username + '</div>'
            +     '</div>'
```

with:

```js
            +     '<div>'
            +       '<div class="text-sm font-semibold text-zinc-800">' + req.tenNhanVien + '</div>'
            +     '</div>'
```

(No replacement caption — `tenNhanVien` is always present per the earlier research finding; there is nothing useful left to show once username is gone.)

- [ ] **Step 5: Manual verification**

Deploy, open `/manager/nhan-su`, confirm "Thêm nhân viên mới" has no Username field and Phone is required. Confirm the leave-request tab no longer shows a stray mono-font line under employee names.

- [ ] **Step 6: Commit**

```bash
git add src/main/webapp/manager/NhanSu.jsp
git commit -m "feat: manager add/edit-staff modal drops Username, requires Phone"
```

---

### Task 11: `NhanSuManagerServlet` — drop username, require+dedupe phone

**Files:**
- Modify: `src/main/java/org/example/controller/manager/NhanSuManagerServlet.java:117-239`

- [ ] **Step 1: Add branch — auto-generate internal id, add phone dedupe, drop username param**

Replace `NhanSuManagerServlet.java:117-152`:

```java
            if ("add".equals(action)) {
                String fullName = req.getParameter("fullName");
                String email = req.getParameter("email");
                String phoneNumber = req.getParameter("phoneNumber");
                int roleId = Integer.parseInt(req.getParameter("roleId"));
                String password = req.getParameter("password");

                // Trim/normalize inputs
                if (fullName != null) fullName = fullName.trim();
                if (email != null) email = email.trim().toLowerCase(java.util.Locale.ROOT);
                if (phoneNumber != null) phoneNumber = phoneNumber.trim();
                if (password != null) password = password.trim();

                // Validate fields (username no longer part of staff creation)
                java.util.Map<String, String> errors = org.example.util.ValidationUtils.validateStaffCreate(email, phoneNumber, fullName, roleId);
                org.example.dao.TaiKhoanDAO taiKhoanDAO = new org.example.dao.impl.TaiKhoanDAOImpl();
                if (taiKhoanDAO.kiemtraEmail(email)) errors.put("email", "Email này đã được sử dụng bởi một tài khoản khác.");
                String normalizedPhone = org.example.util.PhoneUtil.normalizeVN(phoneNumber);
                if (normalizedPhone == null) {
                    errors.put("phone", "Số điện thoại không hợp lệ.");
                } else if (taiKhoanDAO.kiemtraPhone(org.example.util.PhoneUtil.lookupVariants(normalizedPhone))) {
                    errors.put("phone", "Số điện thoại này đã được sử dụng bởi một tài khoản khác.");
                }
                if (password == null || password.isEmpty()) errors.put("password", "Mật khẩu không được để trống");
                if (!errors.isEmpty()) throw new IllegalArgumentException(errors.toString());

                // Validate strong password
                org.example.util.ValidationUtils.validateStrongPassword(password);

                // Build TaiKhoan (but do NOT save yet – wait for OTP)
                TaiKhoan newAcc = new TaiKhoan();
                newAcc.setUsername(org.example.util.AccountInternalIdGenerator.generateUnique(taiKhoanDAO::kiemtraUsername));
                newAcc.setFullName(fullName);
                newAcc.setEmail(email);
                newAcc.setPhoneNumber(normalizedPhone);
                newAcc.setRoleId(roleId);
                newAcc.setCoSoId(managerCoSoId);
                newAcc.setIsLocked(false);
                newAcc.setPassword(org.mindrot.jbcrypt.BCrypt.hashpw(password, org.mindrot.jbcrypt.BCrypt.gensalt(12)));
```

(Everything from the original "Send OTP..." comment onward, old lines 154-172, is unchanged.)

- [ ] **Step 2: Update branch — add symmetric phone-duplicate check**

Replace `NhanSuManagerServlet.java:184-206`:

```java
                    updateReq.setFullName(req.getParameter("fullName"));
                    updateReq.setEmail(req.getParameter("email"));
                    updateReq.setPhoneNumber(req.getParameter("phoneNumber"));
                    updateReq.setRoleId(Integer.parseInt(req.getParameter("roleId")));
                    updateReq.setPassword(req.getParameter("password"));

                    TaiKhoan account = nhanSuService.getStaffById(accountId, managerCoSoId);
                    org.example.util.BranchSecurityUtils.checkBranchAccess(account.getCoSoId(), managerCoSoId);
                    String newEmail = updateReq.getEmail();
                    if (newEmail != null) newEmail = newEmail.trim().toLowerCase(java.util.Locale.ROOT);

                    String newPhone = updateReq.getPhoneNumber();
                    if (newPhone != null) newPhone = newPhone.trim();
                    boolean isPhoneChanged = (newPhone != null && !newPhone.equals(account.getPhoneNumber()));
                    if (isPhoneChanged) {
                        String normalizedNewPhone = org.example.util.PhoneUtil.normalizeVN(newPhone);
                        if (normalizedNewPhone == null) {
                            throw new IllegalArgumentException("Số điện thoại không hợp lệ.");
                        }
                        if (new org.example.dao.impl.TaiKhoanDAOImpl().kiemtraPhone(org.example.util.PhoneUtil.lookupVariants(normalizedNewPhone))) {
                            throw new IllegalArgumentException("Số điện thoại này đã được sử dụng bởi một tài khoản khác.");
                        }
                        updateReq.setPhoneNumber(normalizedNewPhone);
                    }

                    boolean isEmailChanged = (newEmail != null && !newEmail.equalsIgnoreCase(account.getEmail()));
                    if (isEmailChanged) {
                        org.example.util.ValidationUtils.validateEmail(newEmail);
                        if (new org.example.dao.impl.TaiKhoanDAOImpl().kiemtraEmail(newEmail)) {
                            throw new IllegalArgumentException("Email này đã được sử dụng bởi một tài khoản khác.");
                        }
```

(The rest of the `isEmailChanged`/`else` branches at old lines 203-239 are unchanged — only the phone handling is added ahead of the email block, and `updateReq.getEmail()`'s normalization now lowercases too.)

- [ ] **Step 3: Compile check**

Run: `mvn -q compile`
Expected: BUILD SUCCESS.

- [ ] **Step 4: Manual verification (CASE 1 from the spec)**

As Manager, add a Staff/Lễ tân with duplicate email — rejected. Duplicate phone — rejected. Valid new email+phone — OTP sent to email, verify OTP, account created, and the new staff can log in with either their email or their phone. Confirm no internal Username string appears anywhere in the UI.

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/controller/manager/NhanSuManagerServlet.java
git commit -m "feat: manager staff create/update drops username, requires+dedupes phone"
```

---

### Task 12: `NhanSuManagerServlet.buildStaffListJson` + `NhanSuService.NhanSuDTO` — drop username, use `DisplayNameUtil`

**Files:**
- Modify: `src/main/java/org/example/controller/manager/NhanSuManagerServlet.java:309-326`
- Modify: `src/main/java/org/example/service/manager/NhanSuService.java:104-135` (`NhanSuDTO.getInitial`)

**Interfaces:**
- Consumes: `DisplayNameUtil.displayName(fullName, email, phone)` / `DisplayNameUtil.avatarInitial(fullName, email)` from Task 2.

- [ ] **Step 1: Fix `NhanSuDTO`'s internal fallback**

Replace `NhanSuService.java:104-109`:

```java
        private String getInitial(String fullName, String email) {
            return org.example.util.DisplayNameUtil.avatarInitial(fullName, email);
        }
```

Update the two constructors (`NhanSuService.java:84-102`) that call `getInitial(fullName, username)` to call `getInitial(fullName, email)` instead:

```java
        public NhanSuDTO(int accountId, String username, String fullName, String email,
                        String phoneNumber, int roleId, String roleName, boolean locked) {
            this.accountId = accountId;
            this.username = username;
            this.fullName = fullName;
            this.email = email;
            this.phoneNumber = phoneNumber;
            this.roleId = roleId;
            this.roleName = roleName;
            this.locked = locked;
            this.initial = getInitial(fullName, email);
            this.statusDisplay = locked ? "Bị khóa" : "Đang làm";
        }
```

(`username` stays on the DTO as an internal field populated from the DAO row — it is simply never read for display anymore. This keeps `getStaffListByBranch`/`getDeletedStaffListByBranch`, which still pass `acc.getUsername()` positionally into this constructor, compiling unchanged.)

- [ ] **Step 2: Drop `username` from the JSON payload, add a `displayName`/`initial`-consistent `name`**

Replace `NhanSuManagerServlet.java:309-326`:

```java
    private String buildStaffListJson(List<NhanSuDTO> staffList) {
        java.util.List<java.util.Map<String, Object>> mappedList = new java.util.ArrayList<>();
        for (NhanSuDTO s : staffList) {
            java.util.Map<String, Object> map = new java.util.HashMap<>();
            map.put("id", String.valueOf(s.getAccountId()));
            map.put("name", org.example.util.DisplayNameUtil.displayName(s.getFullName(), s.getEmail(), s.getPhoneNumber()));
            map.put("email", s.getEmail() != null ? s.getEmail() : "");
            map.put("phone", s.getPhoneNumber() != null ? s.getPhoneNumber() : "");
            map.put("roleId", s.getRoleId());
            map.put("VaiTro", s.getRoleName());
            map.put("status", s.isLocked() ? "Bị khóa" : "Đang làm");
            map.put("initial", s.getInitial());
            map.put("avatarUrl", s.getAvatarUrl() != null ? s.getAvatarUrl() : "");
            mappedList.add(map);
        }
        return new com.google.gson.Gson().toJson(mappedList);
    }
```

- [ ] **Step 3: Compile check**

Run: `mvn -q compile`
Expected: BUILD SUCCESS.

- [ ] **Step 4: Manual verification**

Reload `/manager/nhan-su`'s staff grid (JSON-backed) — confirm names/initials render identically to before for staff who have a `fullName`, and now fall back to email (not a raw username string) for any staff missing `fullName`.

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/controller/manager/NhanSuManagerServlet.java src/main/java/org/example/service/manager/NhanSuService.java
git commit -m "refactor: manager staff JSON API drops username, uses DisplayNameUtil"
```

---

### Task 13: `XacThucOTPServlet` MANAGER_ADD activation email — stop naming Username

**Files:**
- Modify: `src/main/java/org/example/controller/XacThucOTPServlet.java:272-287`

- [ ] **Step 1: Replace the email body**

Replace `XacThucOTPServlet.java:272-287`:

```java
                // Gửi email thông báo kích hoạt kèm mật khẩu
                String rawPwd = (String) session.getAttribute("tempRawPassword");
                final String finalEmail = tempAccount.getEmail();
                final String finalPhone = tempAccount.getPhoneNumber();
                final String finalName = org.example.util.DisplayNameUtil.displayName(
                        tempAccount.getFullName(), finalEmail, finalPhone);
                final String finalPwd = rawPwd != null ? rawPwd : "(đã được thiết lập)";
                new Thread(() -> {
                    try {
                        org.example.util.EmailUtil.sendEmail(finalEmail, "Kích hoạt tài khoản V-SPORT",
                            "Chào " + finalName + ",\n\n" +
                            "Tài khoản nhân viên của bạn đã được tạo bởi Quản lý.\n" +
                            "Email đăng nhập: " + finalEmail + "\n" +
                            "Số điện thoại đăng nhập: " + finalPhone + "\n" +
                            "Mật khẩu: " + finalPwd + "\n\n" +
                            "Vui lòng đăng nhập và đổi mật khẩu ngay sau lần đầu tiên.");
                    } catch (Exception ignored) {}
                }).start();
```

(This removes `finalUsername = tempAccount.getUsername()` entirely and the "Tên đăng nhập: " line.)

- [ ] **Step 2: Compile check**

Run: `mvn -q compile`
Expected: BUILD SUCCESS.

- [ ] **Step 3: Manual verification**

Trigger a manager-add-staff flow through OTP confirmation; check the received activation email — it must show "Email đăng nhập: ..." and "Số điện thoại đăng nhập: ..." and must NOT contain the word "Tên đăng nhập" or any `acct_...` value.

- [ ] **Step 4: Commit**

```bash
git add src/main/java/org/example/controller/XacThucOTPServlet.java
git commit -m "fix: manager-add-staff activation email states Email/Phone, not Username"
```

---

## Phase 4 — Owner registration & branch creation

### Task 14: `OwnerRegisterServlet` — internal id instead of `username=email`, add phone dedupe

**Files:**
- Modify: `src/main/java/org/example/controller/OwnerRegisterServlet.java:130-145, 265-283, 352-368`

- [ ] **Step 1: Normalize email and add a phone-uniqueness check at the send-OTP step**

Locate the send-OTP handler (around `OwnerRegisterServlet.java:130-145`, which currently does `taiKhoanDAO.kiemtraEmail(email)` at line 138). Immediately after the existing email-format/duplicate checks, insert a phone check:

```java
        String normalizedPhone = org.example.util.PhoneUtil.normalizeVN(phone);
        if (normalizedPhone == null) {
            out.print("{\"success\":false,\"message\":\"Số điện thoại không hợp lệ.\"}");
            return;
        }
        if (taiKhoanDAO.kiemtraPhone(org.example.util.PhoneUtil.lookupVariants(normalizedPhone))) {
            out.print("{\"success\":false,\"message\":\"Số điện thoại này đã được sử dụng bởi một tài khoản khác.\"}");
            return;
        }
```

(Match this to the exact JSON-error-writing convention already used a few lines above for the email checks in this method — same `out.print(...)` pattern, same early `return`.)

- [ ] **Step 2: Drop the `OR a.username = :username` dedupe query**

Replace `OwnerRegisterServlet.java:279-283`:

```java
            Long existingCount = em.createQuery(
                    "SELECT COUNT(a) FROM TaiKhoan a WHERE a.email = :email", Long.class)
                    .setParameter("email", email)
                    .getSingleResult();
```

(Do the same for the other raw-JPQL duplicate at `OwnerRegisterServlet.java:409,429` if it repeats this `OR a.username = :email` pattern — drop the `OR` clause and the now-unused `username` parameter binding there too.)

- [ ] **Step 3: Auto-generate the internal Username instead of mirroring email**

Replace `OwnerRegisterServlet.java:352-368`:

```java
            } else {
                // First-time registration: create new Account
                managerAcc = new TaiKhoan();
                managerAcc.setUsername(org.example.util.AccountInternalIdGenerator.generateUnique(
                        candidate -> taiKhoanDAO.kiemtraUsername(candidate)));
                managerAcc.setPassword(org.mindrot.jbcrypt.BCrypt.hashpw("123456", org.mindrot.jbcrypt.BCrypt.gensalt(12)));
                managerAcc.setFullName(ownerName);
                managerAcc.setPhoneNumber(normalizedPhone);
                managerAcc.setEmail(email);
                managerAcc.setRoleId(2);
                managerAcc.setCoSoId(coSo.getCoSoID());
                managerAcc.setIsLocked(true);
                managerAcc.setDiemUyTin(100);
                managerAcc.setDiemTrinhDo(1000);
                managerAcc.setNhanThongBaoSos(true);
                em.persist(managerAcc);
                em.flush();
            }
```

(`normalizedPhone` here is the value computed and validated in Step 1 — confirm it is in scope at this point in the method; if the phone was re-read from a request parameter at this later stage instead of threaded through from Step 1, normalize it again the same way before this block runs.)

- [ ] **Step 4: Compile check**

Run: `mvn -q compile`
Expected: BUILD SUCCESS.

- [ ] **Step 5: Manual verification (CASE 3 from the spec)**

Run the owner self-registration flow end-to-end with a phone number that already belongs to another account — confirm rejection before OTP is even sent. Complete a fresh registration with a new email+phone — confirm the CoSo + Account are both created (or both rolled back on a forced failure), and the new owner can log in with either email or phone once an admin approves the branch.

- [ ] **Step 6: Commit**

```bash
git add src/main/java/org/example/controller/OwnerRegisterServlet.java
git commit -m "feat: owner registration dedupes phone, generates internal Username"
```

---

### Task 15: `QuanLyChiNhanhServlet` — approval email states Email/Phone, not "Tên đăng nhập"

**Files:**
- Modify: `src/main/java/org/example/controller/admin/QuanLyChiNhanhServlet.java:504-522`

- [ ] **Step 1: Update the approval email body**

Replace `QuanLyChiNhanhServlet.java:504-522`:

```java
    private void sendApprovalEmail(TaiKhoan account) {
        new Thread(() -> {
            try {
                EmailUtil.sendEmail(
                    account.getEmail(),
                    "Tài khoản đối tác V-SPORT đã được phê duyệt",
                    "Chào " + account.getFullName() + ",\n\n" +
                    "Cơ sở thể thao của bạn đã được quản trị viên phê duyệt thành công.\n" +
                    "Bạn hiện có thể đăng nhập vào hệ thống quản lý V-SPORT bằng tài khoản sau:\n" +
                    "- Email đăng nhập: " + account.getEmail() + "\n" +
                    "- Số điện thoại đăng nhập: " + account.getPhoneNumber() + "\n" +
                    "- Mật khẩu mặc định: 123456\n\n" +
                    "Vui lòng đổi mật khẩu sau khi đăng nhập lần đầu tiên để bảo mật tài khoản.\n\n" +
                    "Trân trọng,\nBan quản trị V-SPORT"
                );
            } catch (Exception e) {
                logger.error("Lỗi gửi email phê duyệt đến {}", account.getEmail(), e);
            }
        }).start();
    }
```

- [ ] **Step 2: Compile check**

Run: `mvn -q compile`
Expected: BUILD SUCCESS.

- [ ] **Step 3: Manual verification**

Approve a pending owner-registered branch as Admin; check the approval email shows both "Email đăng nhập" and "Số điện thoại đăng nhập" lines and no longer says "Tên đăng nhập".

- [ ] **Step 4: Commit**

```bash
git add src/main/java/org/example/controller/admin/QuanLyChiNhanhServlet.java
git commit -m "fix: branch-approval email states Email/Phone, not Tên đăng nhập"
```

*(Note: `QuanLyChiNhanhServlet`'s admin "add branch" endpoint does not create any Manager account today — confirmed no `TaiKhoan`/`TaiKhoanDAO` usage in that code path — so there is no Username-generation site to touch there. Also note `syncCourtsForBranch` in this same file runs on a separate, non-transactional JDBC connection from `CoSoDAOImpl.addCoSo`'s JPA transaction, which is a pre-existing orphaned-`CoSo`-on-partial-failure risk unrelated to Username/login and out of scope for this plan — flagged in the final report, not fixed here.)*

---

## Phase 5 — Display cleanup: remove every Username fallback

### Task 16: Add `getDisplayName()`/`getAvatarInitial()` to `TaiKhoan`, apply to dashboards/header/profile-dropdown

**Files:**
- Modify: `src/main/java/org/example/model/TaiKhoan.java` (add two methods near `getUsername()`/`setUsername()`, `TaiKhoan.java:195-201`)
- Modify: `src/main/webapp/admin/TongQuan.jsp:46,53,294,299,301`
- Modify: `src/main/webapp/manager/Dashboard.jsp:30,33,120,125`
- Modify: `src/main/webapp/staff/Dashboard.jsp:43,46,132,137`
- Modify: `src/main/webapp/common/header.jsp:758,918,929`
- Modify: `src/main/webapp/admin/common/profile_dropdown.jsp:4,26,54`
- Modify: `src/main/webapp/manager/common/profile_dropdown.jsp:4,26,48`
- Modify: `src/main/java/org/example/controller/manager/DashboardServlet.java:71`

**Interfaces:**
- Consumes: `DisplayNameUtil.displayName(...)`/`.avatarInitial(...)` (Task 2). Produces: `TaiKhoan#getDisplayName()`/`#getAvatarInitial()`, callable directly from JSP EL as `${x.displayName}`/`${x.avatarInitial}` for any `x` that is a `TaiKhoan` instance (`sessionScope.user`, or any `TaiKhoan` row pulled from a DAO list), consumed by every JSP task in this phase and by Task 17.

- [ ] **Step 1: Add the two derived getters to the model**

In `src/main/java/org/example/model/TaiKhoan.java`, immediately after the existing `getUsername()`/`setUsername()` pair (`TaiKhoan.java:195-201`), add:

```java
    public String getDisplayName() {
        return org.example.util.DisplayNameUtil.displayName(fullName, email, phoneNumber);
    }

    public String getAvatarInitial() {
        return org.example.util.DisplayNameUtil.avatarInitial(fullName, email);
    }
```

- [ ] **Step 2: `admin/TongQuan.jsp`**

Replace line 46 (avatar initial fallback):
```jsp
${sessionScope.user.username.substring(0,1).toUpperCase()}
```
with:
```jsp
${sessionScope.user.avatarInitial}
```

Replace line 53 (greeting fallback) — the surrounding `fullName != null ? fullName : username` ternary — with `${sessionScope.user.displayName}`.

Replace lines 294, 299, 301 (staff-card loop: initial fallback, name fallback, raw Username line) so the card shows `${acc.avatarInitial}` for the initial, `${acc.displayName}` for the name, and the separate raw `<c:out value="${acc.username}"/>` line under the name is deleted entirely (nothing replaces it — a staff card doesn't need a second identity line once Username isn't meaningful to show).

- [ ] **Step 3: `manager/Dashboard.jsp` and `staff/Dashboard.jsp`**

In both files, replace the avatar-URL `name=` param and welcome-heading fallback (lines 30,33 / 43,46 respectively) with `${sessionScope.user.displayName}` (and `${sessionScope.user.avatarInitial}` wherever the avatar URL's `name=` query param is really computing an initial rather than a full name — check the exact usage at that line before choosing which getter fits; if it's feeding a "generate avatar from name" service that wants the full display name, use `displayName`, not `avatarInitial`).

Replace the upcoming-shift widget fallback (lines 120,125 / 132,137) — `lich.account.username` fallback for avatar initial and display name — with `${lich.account.avatarInitial}` / `${lich.account.displayName}` (this only works if `lich.account` is a `TaiKhoan` instance; confirm via the backing servlet/DAO before editing — if `lich.account` is instead a lightweight DTO without these getters, fall back to computing `DisplayNameUtil.displayName(...)`/`.avatarInitial(...)` server-side in that DTO's constructor as done for `NhanSuDTO` in Task 12).

- [ ] **Step 4: `common/header.jsp`**

Replace line 758 (dropdown title fallback) with `${fn:escapeXml(user.displayName)}`.
Replace lines 918, 929 (mobile drawer avatar-initial and display-name fallback) with `${user.avatarInitial}` and `${user.displayName}` respectively.

- [ ] **Step 5: `admin/common/profile_dropdown.jsp` and `manager/common/profile_dropdown.jsp`**

Replace the three-spot `sessionScope.user.fullName != null ? sessionScope.user.fullName : sessionScope.user.username` pattern (lines 4,26,54 in the admin file; 4,26,48 in the manager file) with `${sessionScope.user.displayName}` (and the avatar-name-var spot specifically, if it's used for an initial rather than the full string, with `${sessionScope.user.avatarInitial}` — verify per-line before choosing).

- [ ] **Step 6: `manager/DashboardServlet.java`**

Replace line 71:
```java
        req.setAttribute("userFullName", user.getUsername());
```
with:
```java
        req.setAttribute("userFullName", user.getDisplayName());
```

(Confirmed dead/unused downstream — `userFullName` is read by zero JSPs — but fixing it for consistency costs one line and removes a lingering direct `getUsername()` call from this servlet.)

- [ ] **Step 7: Manual verification**

Log in as a test account that has `fullName = null` (or temporarily null it out on a test row) and confirm every page above shows the account's email (not a raw Username) as the greeting/dropdown name, and the avatar circle shows the first letter of the email.

- [ ] **Step 8: Commit**

```bash
git add src/main/java/org/example/model/TaiKhoan.java src/main/webapp/admin/TongQuan.jsp src/main/webapp/manager/Dashboard.jsp src/main/webapp/staff/Dashboard.jsp src/main/webapp/common/header.jsp src/main/webapp/admin/common/profile_dropdown.jsp src/main/webapp/manager/common/profile_dropdown.jsp src/main/java/org/example/controller/manager/DashboardServlet.java
git commit -m "feat: TaiKhoan.getDisplayName/getAvatarInitial, apply to dashboards/header"
```

---

### Task 17: Apply `displayName`/`avatarInitial` to staff-list JS arrays and customer booking/profile pages

**Files:**
- Modify: `src/main/webapp/admin/NhanSu.jsp` (finish the `staffList`/`deletedList` fallback wiring started in Task 8 Step 4)
- Modify: `src/main/webapp/customer/HoSo.jsp:209`
- Modify: `src/main/webapp/customer/TaiKhoan.jsp:494`
- Modify: `src/main/webapp/customer/DatSan.jsp:784,786`
- Modify: `src/main/webapp/customer/XacNhanDatSan.jsp:232`
- Modify: `src/main/webapp/customer/LichSuDatSan.jsp:107,111`

- [ ] **Step 1: Confirm Task 8/Task 16 ordering**

If Task 8 was executed before Task 16 landed, its `${acc.displayName}`/`${acc.avatarInitial}` references in `admin/NhanSu.jsp:276-293,295-306` will not compile against a `TaiKhoan` bean until Task 16 Step 1 adds the getters. Re-run `mvn -q compile` now; if it fails on those lines, Task 16 hasn't landed yet — do not proceed until it has.

- [ ] **Step 2: Customer-facing avatar/name fallbacks**

In each of `customer/HoSo.jsp:209`, `customer/TaiKhoan.jsp:494`, `customer/DatSan.jsp:784,786`, `customer/LichSuDatSan.jsp:107,111`, replace the `fn:substring(account.fullName,0,1)` / `fn:substring(account.username,0,1)` two-branch `<c:when>`/`<c:otherwise>` pattern with a single `${account.avatarInitial}` (or `${sessionScope.user.avatarInitial}`, matching whichever variable name the surrounding scriptlet/EL actually uses at that line — confirm the variable name in place before editing, since some of these reference `account` and others `sessionScope.user`).

In `customer/XacNhanDatSan.jsp:232`, replace the readonly "Họ tên" field's `sessionScope.user.fullName ... : sessionScope.user.username` value expression with `${sessionScope.user.displayName}`.

- [ ] **Step 3: Manual verification**

As a customer test account with `fullName = null`, open Hồ sơ, Tài khoản, Đặt sân (booking history modal), Xác nhận đặt sân, and Lịch sử đặt sân — confirm every avatar circle and name field falls back to the account's email, never to a raw Username.

- [ ] **Step 4: Commit**

```bash
git add src/main/webapp/admin/NhanSu.jsp src/main/webapp/customer/HoSo.jsp src/main/webapp/customer/TaiKhoan.jsp src/main/webapp/customer/DatSan.jsp src/main/webapp/customer/XacNhanDatSan.jsp src/main/webapp/customer/LichSuDatSan.jsp
git commit -m "feat: customer-facing pages fall back to email, not username, for display"
```

---

### Task 18: `manager/ThungRac.jsp` — replace the Username column with Email/Phone

**Files:**
- Modify: `src/main/webapp/manager/ThungRac.jsp:212,229`

- [ ] **Step 1: Swap the column header**

Replace `manager/ThungRac.jsp:212`:
```html
<th class="pb-3 pl-2">Username</th>
```
with two columns:
```html
<th class="pb-3 pl-2">Email</th>
<th class="pb-3 pl-2">Số điện thoại</th>
```

- [ ] **Step 2: Swap the cell value**

Replace `manager/ThungRac.jsp:229`:
```jsp
<td class="pl-2">${st.username}</td>
```
with:
```jsp
<td class="pl-2">${st.email}</td>
<td class="pl-2">${st.phoneNumber}</td>
```

(Confirm `st` here is the same `TaiKhoan`/`NhanSuDTO`-shaped object that already exposes `email`/`phoneNumber` elsewhere on this page before committing — it is, per the existing `NhanSuDTO`/`TaiKhoan` fields used throughout this file.)

- [ ] **Step 3: Manual verification**

Open the Manager "Thùng rác" (trash) → "Nhân sự" tab; confirm the table now shows Email and Số điện thoại columns instead of a raw Username column, for both active-looking rows and any test soft-deleted staff row.

- [ ] **Step 4: Commit**

```bash
git add src/main/webapp/manager/ThungRac.jsp
git commit -m "feat: staff trash-bin table shows Email/Phone instead of Username"
```

---

### Task 19: `AuditLogService` — fallback to email, not username

**Files:**
- Modify: `src/main/java/org/example/service/AuditLogService.java:71,93`

- [ ] **Step 1: Replace both fallback sites**

Replace both occurrences of:
```java
entry.setActorName(actor.getFullName() != null ? actor.getFullName() : actor.getUsername());
```
(at `AuditLogService.java:71` and `:93`) with:
```java
entry.setActorName(org.example.util.DisplayNameUtil.displayName(actor.getFullName(), actor.getEmail(), actor.getPhoneNumber()));
```

- [ ] **Step 2: Compile check**

Run: `mvn -q compile`
Expected: BUILD SUCCESS.

- [ ] **Step 3: Manual verification**

Perform any audited action (e.g. Manager adds a staff member) with an actor account that has `fullName = null`; open the Audit Log page and confirm the actor name shown is the actor's email, not a raw Username string.

- [ ] **Step 4: Commit**

```bash
git add src/main/java/org/example/service/AuditLogService.java
git commit -m "fix: audit log actor-name fallback uses email, not username"
```

---

### Task 20: JSON APIs and leave-request list — drop `username` field

**Files:**
- Modify: `src/main/java/org/example/controller/staff/StaffCaLamServlet.java:200-201`
- Modify: `src/main/java/org/example/controller/manager/YeuCauNghiManagerServlet.java:271`
- Modify: `src/main/webapp/manager/yeuCauNghi_list.jsp:81-84`

- [ ] **Step 1: `StaffCaLamServlet` coworkers JSON**

Replace `StaffCaLamServlet.java:200-201` (currently `m.put("username", c.getUsername())` plus a fullName fallback) with:
```java
m.put("name", org.example.util.DisplayNameUtil.displayName(c.getFullName(), c.getEmail(), c.getPhoneNumber()));
```
(drop the separate `username` key from the map entirely — confirm no other key in this map already carries the display name before adding a duplicate `"name"` key; if one already exists, update its value expression in place instead of adding a new key.)

- [ ] **Step 2: `YeuCauNghiManagerServlet` leave-request JSON**

Replace `YeuCauNghiManagerServlet.java:271`:
```java
map.put("username", r.getUsername() != null ? r.getUsername() : "");
```
Delete this line entirely (drop the key) — confirm no JS consumer on the other end (`manager/NhanSu.jsp`'s leave-table renderer, already fixed in Task 10 Step 4) still reads `req.username` after this change; `grep -rn "req.username" src/main/webapp/manager/` should return nothing once Task 10 and this task have both landed.

- [ ] **Step 3: `yeuCauNghi_list.jsp`**

Replace `yeuCauNghi_list.jsp:81-84`:
```jsp
                    <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm font-medium text-gray-900">${req.tenNhanVien}</div>
                        <div class="text-xs text-gray-500">${req.username}</div>
                    </td>
```
with:
```jsp
                    <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm font-medium text-gray-900">${req.tenNhanVien}</div>
                    </td>
```

- [ ] **Step 4: Compile check**

Run: `mvn -q compile`
Expected: BUILD SUCCESS.

Run: `grep -rn "\.username\b" src/main/java/org/example/controller/staff/StaffCaLamServlet.java src/main/java/org/example/controller/manager/YeuCauNghiManagerServlet.java`
Expected: no output (confirms both JSON builders no longer reference username).

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/controller/staff/StaffCaLamServlet.java src/main/java/org/example/controller/manager/YeuCauNghiManagerServlet.java src/main/webapp/manager/yeuCauNghi_list.jsp
git commit -m "fix: drop username from coworker/leave-request JSON payloads and views"
```

---

### Task 21 (flagged — confirm scope before executing): `DoiNhomServlet` team-invite by Username → by Email

**Why this is flagged:** once Username is never displayed anywhere, a customer has no way to know a teammate's Username to type into the invite box — `DoiNhomServlet.handleInviteMember()` (`DoiNhomServlet.java:385-390`, `findByUsername(username.trim())`) and `DoiNhomChiTiet.jsp:256`'s "Tên đăng nhập" invite-dialog field would silently stop working for any teammate created after this refactor ships. This wasn't in the original file list the user provided — **confirm with the user whether to include this task before executing it**, since it's a functional change to the team-invite feature, not just a display/login cleanup.

**Files:**
- Modify: `src/main/java/org/example/controller/customer/DoiNhomServlet.java:385-390`
- Modify: `src/main/webapp/customer/DoiNhomChiTiet.jsp:256`

- [ ] **Step 1: Read the full `handleInviteMember` method** in `DoiNhomServlet.java` before editing — confirm the exact surrounding error-handling/response shape (not fully captured in this plan's research pass), then replace the lookup:
```java
taiKhoanDAO.findByUsername(username.trim())
```
with:
```java
taiKhoanDAO.timTaiKhoanTheoEmail(email.trim().toLowerCase(java.util.Locale.ROOT))
```
renaming the inbound request parameter from `username` to `email` to match, and updating any "không tìm thấy tài khoản" error copy that mentions "tên đăng nhập" to mention "email".

- [ ] **Step 2:** In `DoiNhomChiTiet.jsp:256`, change the invite dialog's label from "Tên đăng nhập" to "Email" and its input `id="dcInviteUsername"` to something like `id="dcInviteEmail"`, `type="email"`, updating the JS that reads this field's value to match.

- [ ] **Step 3: Manual verification**

Invite a teammate to a team by their email address; confirm the invite is created and the invitee sees it.

- [ ] **Step 4: Commit**

```bash
git add src/main/java/org/example/controller/customer/DoiNhomServlet.java src/main/webapp/customer/DoiNhomChiTiet.jsp
git commit -m "feat: team invite by email instead of internal username"
```

---

## Phase 6 — Database migration (email/phone uniqueness)

### Task 22: Write the idempotent unique-index migration + rollback + run-book

**Files:**
- Create: `sql/migration_account_login_identifiers_unique.sql`
- Create: `sql/rollback_account_login_identifiers_unique.sql`
- Create: `docs/RUN_ACCOUNT_LOGIN_IDENTIFIERS_MIGRATION.md`
- (Existing, unchanged, run first as a prerequisite: `sql/verify_account_login_identifiers.sql` — already in the repo, read-only, lists missing/duplicate Email and Phone among active accounts.)

- [ ] **Step 1: Write the migration**, following this repo's existing idempotent-migration conventions (`sql/migration_court_checkout.sql`'s "check for duplicates, skip with PRINT if found" pattern; `sql/migration_team_management.sql`'s filtered-unique-index pattern):

```sql
-- =====================================================================
-- migration_account_login_identifiers_unique.sql
-- Thêm unique filtered index cho Accounts.Email và Accounts.PhoneNumber,
-- chỉ áp dụng cho tài khoản đang hoạt động (IsDeleted = 0 hoặc NULL).
-- Không đụng đến cột Username — Username vẫn là mã nội bộ, không unique
-- thêm ở migration này (đã UNIQUE sẵn từ schema gốc nếu có).
--
-- Idempotent: chạy lại nhiều lần không lỗi. TỪ CHỐI tạo index nếu dữ
-- liệu hiện tại còn Email hoặc Phone trùng — chạy sql/verify_account_login_identifiers.sql
-- trước để biết chính xác các dòng trùng cần xử lý thủ công.
--
-- Không tự động thực thi — người vận hành phải tự chạy tay trên
-- SQL Server (database QuanLiSport). Backup DB trước khi chạy.
-- =====================================================================

USE QuanLiSport;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1) Unique index cho Email (bỏ qua NULL/rỗng, chỉ tài khoản chưa xóa mềm)
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Accounts') AND name = N'UX_Accounts_Email_Active')
    BEGIN
        IF NOT EXISTS (
            SELECT LOWER(LTRIM(RTRIM(Email)))
            FROM dbo.Accounts
            WHERE Email IS NOT NULL AND LTRIM(RTRIM(Email)) <> ''
              AND (IsDeleted = 0 OR IsDeleted IS NULL)
            GROUP BY LOWER(LTRIM(RTRIM(Email)))
            HAVING COUNT(*) > 1
        )
        BEGIN
            EXEC(N'CREATE UNIQUE INDEX UX_Accounts_Email_Active ON dbo.Accounts(Email)
                   WHERE Email IS NOT NULL AND (IsDeleted = 0 OR IsDeleted IS NULL);');
            PRINT N'ADDED UX_Accounts_Email_Active';
        END
        ELSE
            PRINT N'SKIP UX_Accounts_Email_Active — còn Email trùng ở tài khoản đang hoạt động; chạy sql/verify_account_login_identifiers.sql để xem danh sách, xử lý thủ công rồi chạy lại migration này.';
    END
    ELSE
        PRINT N'SKIP UX_Accounts_Email_Active (đã tồn tại)';

    -- 2) Unique index cho PhoneNumber (bỏ qua NULL/rỗng, chỉ tài khoản chưa xóa mềm)
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Accounts') AND name = N'UX_Accounts_PhoneNumber_Active')
    BEGIN
        IF NOT EXISTS (
            SELECT CASE
                       WHEN PhoneNumber LIKE '+84%' THEN '0' + SUBSTRING(LTRIM(RTRIM(PhoneNumber)), 4, 20)
                       WHEN PhoneNumber LIKE '84%'  THEN '0' + SUBSTRING(LTRIM(RTRIM(PhoneNumber)), 3, 20)
                       ELSE LTRIM(RTRIM(PhoneNumber))
                   END AS NormalizedPhone
            FROM dbo.Accounts
            WHERE PhoneNumber IS NOT NULL AND LTRIM(RTRIM(PhoneNumber)) <> ''
              AND (IsDeleted = 0 OR IsDeleted IS NULL)
            GROUP BY CASE
                       WHEN PhoneNumber LIKE '+84%' THEN '0' + SUBSTRING(LTRIM(RTRIM(PhoneNumber)), 4, 20)
                       WHEN PhoneNumber LIKE '84%'  THEN '0' + SUBSTRING(LTRIM(RTRIM(PhoneNumber)), 3, 20)
                       ELSE LTRIM(RTRIM(PhoneNumber))
                     END
            HAVING COUNT(*) > 1
        )
        BEGIN
            EXEC(N'CREATE UNIQUE INDEX UX_Accounts_PhoneNumber_Active ON dbo.Accounts(PhoneNumber)
                   WHERE PhoneNumber IS NOT NULL AND (IsDeleted = 0 OR IsDeleted IS NULL);');
            PRINT N'ADDED UX_Accounts_PhoneNumber_Active';
        END
        ELSE
            PRINT N'SKIP UX_Accounts_PhoneNumber_Active — còn PhoneNumber trùng (sau chuẩn hóa 0/84/+84) ở tài khoản đang hoạt động; xử lý thủ công rồi chạy lại migration này.';
    END
    ELSE
        PRINT N'SKIP UX_Accounts_PhoneNumber_Active (đã tồn tại)';

    -- Lưu ý quan trọng: index này KHÔNG unique trên PhoneNumber thô, chỉ trên giá trị
    -- lưu trong cột — nếu DB còn lưu cùng một số ở cả 3 dạng (0..., 84..., +84...)
    -- cho các account KHÁC NHAU, index này sẽ không bắt được. Chạy
    -- sql/verify_account_login_identifiers.sql mục (4) trước để xác nhận không còn
    -- trường hợp đó trước khi coi migration này là đủ.

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
```

- [ ] **Step 2: Write the rollback**, mirroring the repo's existing confirm-flag rollback convention:

```sql
-- =====================================================================
-- rollback_account_login_identifiers_unique.sql
-- Gỡ 2 unique index đã tạo bởi migration_account_login_identifiers_unique.sql.
-- Phải tự đặt @ConfirmRollback = 1 trước khi chạy — an toàn chống chạy nhầm.
-- =====================================================================

USE QuanLiSport;
GO

DECLARE @ConfirmRollback BIT = 0; -- Đổi thành 1 để thực sự rollback

IF @ConfirmRollback = 1
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Accounts') AND name = N'UX_Accounts_Email_Active')
        DROP INDEX UX_Accounts_Email_Active ON dbo.Accounts;
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Accounts') AND name = N'UX_Accounts_PhoneNumber_Active')
        DROP INDEX UX_Accounts_PhoneNumber_Active ON dbo.Accounts;
    PRINT N'Rolled back Email/PhoneNumber unique indexes.';
END
ELSE
    PRINT N'ConfirmRollback = 0 — không làm gì. Đổi thành 1 nếu chắc chắn muốn rollback.';
GO
```

- [ ] **Step 3: Write the run-book**, mirroring `docs/RUN_REPUTATION_MIGRATION.md`'s structure:

```markdown
# Chạy migration: Email/Phone unique cho Accounts

1. Backup database `QuanLiSport`.
2. Chạy `sql/verify_account_login_identifiers.sql` trên DB đích — đọc kỹ mục (2) tài khoản
   thiếu Email/Phone, mục (3) Email trùng, mục (4) Phone trùng (sau chuẩn hóa).
3. Nếu mục (3)/(4) có kết quả: xử lý thủ công (liên hệ chủ tài khoản, gộp, hoặc xóa mềm
   tài khoản trùng lặp/rác) — migration sẽ tự SKIP và không tạo index nếu còn trùng, KHÔNG
   tự động sửa dữ liệu.
4. Chạy `sql/migration_account_login_identifiers_unique.sql`. Đọc output PRINT: mỗi index
   phải in "ADDED" hoặc "SKIP (đã tồn tại)" — nếu in "SKIP — còn ... trùng", quay lại bước 3.
5. Chạy lại `sql/verify_account_login_identifiers.sql` để xác nhận không còn dữ liệu trùng
   mới phát sinh trong lúc xử lý.
6. Không cần restart Tomcat — đây chỉ là index, không đổi schema logic ứng dụng.
7. Smoke-test: đăng nhập bằng Email và bằng Số điện thoại cho ít nhất một tài khoản mỗi vai
   trò (Admin, Manager, Staff, Customer, Owner).
```

- [ ] **Step 4: Do not run this migration** as part of this plan — flag it to the user with the exact duplicate/missing-identifier findings from running `sql/verify_account_login_identifiers.sql` against the real dev/staging DB, and let them decide when/how to clean up any duplicates before it's safe to run.

- [ ] **Step 5: Commit**

```bash
git add sql/migration_account_login_identifiers_unique.sql sql/rollback_account_login_identifiers_unique.sql docs/RUN_ACCOUNT_LOGIN_IDENTIFIERS_MIGRATION.md
git commit -m "docs: add Email/PhoneNumber unique-index migration, rollback, run-book"
```

---

## Phase 7 — Final build and verification

### Task 23: Full build + the spec's CASE 1–6 manual checklist

**Files:** none (verification only)

- [ ] **Step 1: Full test suite**

Run: `mvn -q test`
Expected: BUILD SUCCESS, all existing tests plus the new `AccountInternalIdGeneratorTest`, `DisplayNameUtilTest`, `ValidationUtilsStaffCreateTest` pass.

- [ ] **Step 2: Full package**

Run: `mvn -q package`
Expected: BUILD SUCCESS, WAR produced.

- [ ] **Step 3: Deploy and run the spec's manual checklist**, in order, against a real Tomcat 10.1 deployment:
  - CASE 1 (Manager adds Staff): no Username field; Email+Phone both mandatory; duplicate Email rejected; duplicate Phone rejected; OTP goes to the entered email; account only persists after OTP verification; new staff logs in with email; new staff logs in with phone; no internal Username string appears anywhere in the UI.
  - CASE 2 (Admin adds Manager/Staff): no Username field; branch (`coSoId`) assignment still works for Manager role; Email/Phone uniqueness enforced; login by email and by phone both succeed; role-based redirect correct.
  - CASE 3 (Owner registers a branch): no Username field; Email and Phone both become login identifiers; multi-step OTP form still works; account+branch creation is transactionally safe (verified already true in Task 14/research — re-confirm by forcing a failure after `em.persist(coSo)` and observing rollback).
  - CASE 4 (Login): email+password succeeds; phone+password succeeds; an old Username+correct password **fails**; wrong password gives the generic error; a locked account cannot log in; an internal-role account cannot log in via the Customer portal.
  - CASE 5 (Edit account): changing email to one already in use is rejected; changing phone to one already in use is rejected; keeping your own current email/phone is allowed; the internal Username is never altered by any edit path (confirm via a direct DB check that `Accounts.Username` is unchanged after an edit).
  - CASE 6 (Display): no "Tên đăng nhập" label remains in any account-creation form; no `acct_...` string is rendered anywhere in the UI; staff search works by name/email/phone; dashboards/profile pages don't error for an account with `fullName IS NULL`.

- [ ] **Step 4: Report results** — do not mark this plan complete until every CASE above has been exercised and its outcome recorded (pass/fail with repro steps for any failure).

---

## Summary of what stays untouched (legacy `getUsername()` call sites kept deliberately)

- `Accounts.Username` DB column: kept, now populated exclusively by `AccountInternalIdGenerator`.
- `TaiKhoanDAO.kiemtraUsername` / `findByUsername`: kept — still used for (a) internal-id uniqueness checks by the generator's `generateUnique(...)` callback, and (b) `DoiNhomServlet`'s team-invite lookup (converted to email-based in the flagged Task 21, if approved).
- `TaiKhoan.getUsername()`/`setUsername()`: kept on the model — every remaining caller after this plan either (a) feeds the generator's uniqueness check, or (b) is genuinely dead code (`NhanSuService.createStaff`) kept compiling for safety rather than deleted, since deleting an unused-but-still-referenced-elsewhere DTO shape was explicitly out of scope for this refactor.
- `DangKyServlet.java` (customer self-registration): **not touched by this plan** — it already auto-generates a username from the email local-part and never exposes a Username field to the user; it satisfies the spec's principles today. If you want it switched to `AccountInternalIdGenerator` for consistency (instead of its bespoke `generateUniqueUsername(email)`), that is a small optional follow-up, not required for the spec's stated goals.
- `src/main/webapp/auth/AuthModal.jsp`: contains a dead `name="username"` login field but is unreferenced by any other file — left as-is; recommend a follow-up cleanup/deletion decision outside this plan.
- `QuenMatKhauServlet.java` and `DatLaiMatKhauServlet.java` (forgot-password request + set-new-password steps, spec section 8): **not touched by this plan** — verified during research that both already accept only Email or Phone (never Username), already mask the destination in user-facing copy, and already preserve rate-limiting/anti-enumeration via `PasswordResetChallenge`/`SimpleRateLimiter`. No code change needed; they already satisfy the spec as written.
- `QuanLyChiNhanhServlet`'s non-transactional `syncCourtsForBranch` orphan-`CoSo` risk: pre-existing, unrelated to Username/login, flagged but not fixed here.
