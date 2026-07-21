# Admin Cơ Sở Trim + PayOS OTP + Audit Log IP — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** (1) Stop Admin from editing sports/court-count on an existing Cơ Sở and fix the opening/closing-hour display bug (currently shows `00h`/`00` for facilities with NULL hours and can silently persist `00:00`); (2) require OTP verification before any PayOS Client ID / API Key / Checksum Key change is persisted; (3) confirm and close IP-logging gaps in AuditLog for Admin CoSo actions and Manager invoice actions.

**Architecture:** No schema changes. The CoSo edit path stops touching `LoaiHinhKinhDoanh`/`SoLuongSanDuKien`/courts entirely (sports/courts stay owned by the "Thêm Cơ Sở" wizard and Manager's "Quản lý Sân" page). The PayOS OTP challenge is a new session-scoped, hashed-OTP class (`PayOSConfigChallenge`) modeled directly on the existing `PasswordResetChallenge` pattern — no new DB table, same "hash-only, TTL, attempt-lock, resend-cooldown" design already proven in this codebase. `PayOSConfigurationService.updateConfiguration` splits into `prepareUpdate` (merge/validate, no I/O) + `persistPrepared`/`persistChallenge` (DB write + audit log), so the servlet can decide "OTP needed?" before writing anything. Audit IP capture already works everywhere that passes `HttpServletRequest` into `AuditLogService.log(...)`; the one real gap found is `HoaDonManagerServlet`, which never calls `AuditLogService` at all.

**Tech Stack:** Jakarta Servlets, JSP + JSTL, Tailwind (CDN, inline utility classes), vanilla JS (fetch), JUnit 5 for pure-logic unit tests.

## Global Constraints

- No SQL migration in this plan — no schema change is needed anywhere (verified: `AuditLog.IpAddress` column already exists and is already populated by every `AuditLogService.log(req, ...)` call site; OTP state lives in `HttpSession`, same as the existing forgot-password and add-branch OTP flows).
- Do not touch `syncCourtsForBranch`, `buildSportCounts`, or the "Thêm Cơ Sở" (create) modal's sports/court fields — those stay exactly as-is; only the **edit** path changes.
- Reuse `.adm-otp` CSS classes and the zinc-900 (primary "Save") / blue-600 (secondary "add/continue") button convention already used in `QuanLyChiNhanh.jsp` — no new CSS files.
- `FilterQuyenAdmin.java:28` already special-cases `path.contains("/chi-nhanh/payos")` for JSON-403 — all new PayOS OTP actions must stay on the existing `/admin/chi-nhanh/payos` URL (dispatched by an `action` request parameter), not a new URL, so this filter rule keeps covering them automatically.
- Never persist a PayOS secret without going through OTP verification when any of the 3 fields actually changed; never require OTP when nothing changed (blank submission = keep old values, already existing behavior).

---

### Task 1: `PayOSConfigChallenge` — session-scoped hashed-OTP challenge for PayOS key changes

**Files:**
- Create: `src/main/java/org/example/service/PayOSConfigChallenge.java`
- Test: `src/test/java/org/example/service/PayOSConfigChallengeTest.java`

**Interfaces:**
- Produces: `PayOSConfigChallenge.create(int coSoId, int adminAccountId, String maskedDestination, String pendingClientId, String pendingApiKey, String pendingChecksumKey, List<String> fieldsChanged, String otp, long now)`, instance methods `verify(String input, long now) -> VerifyResult`, `canResend(long now)`, `resendWaitSeconds(long now)`, `applyResend(String newOtp, long now)`, getters `getCoSoId()`, `getAdminAccountId()`, `getMaskedDestination()`, `getPendingClientId()`, `getPendingApiKey()`, `getPendingChecksumKey()`, `getFieldsChanged()`, `isUsed()`, `getAttemptCount()`, `getSendCount()`. Constants `TTL_MS`, `RESEND_COOLDOWN_MS`, `MAX_ATTEMPTS`, `MAX_SENDS`. Enum `VerifyResult { OK, INVALID, EXPIRED, LOCKED, USED }`.
- Consumes: `org.example.service.reset.ResetSecurityUtil` (`generateOtp()`, `newSalt()`, `hashOtp(salt, otp)`, `hashEquals(a, b)`) — already exists, used unchanged.

- [ ] **Step 1: Write the failing test**

Create `src/test/java/org/example/service/PayOSConfigChallengeTest.java`:

```java
package org.example.service;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PayOSConfigChallengeTest {

    private static final long T0 = 1_000_000_000L;

    private PayOSConfigChallenge real() {
        return PayOSConfigChallenge.create(7, 42, "a***@vsport.vn",
                "client-new", "api-new", "checksum-new",
                List.of("CLIENT_ID", "API_KEY", "CHECKSUM_KEY"), "123456", T0);
    }

    @Test
    void otpDungThiOkVaOneTimeUse() {
        PayOSConfigChallenge c = real();
        assertEquals(PayOSConfigChallenge.VerifyResult.OK, c.verify("123456", T0 + 1000));
        assertTrue(c.isUsed());
        assertEquals(PayOSConfigChallenge.VerifyResult.USED, c.verify("123456", T0 + 2000));
    }

    @Test
    void otpSaiThiInvalidVaTangAttempt() {
        PayOSConfigChallenge c = real();
        assertEquals(PayOSConfigChallenge.VerifyResult.INVALID, c.verify("000000", T0 + 1000));
        assertEquals(1, c.getAttemptCount());
        assertEquals(PayOSConfigChallenge.VerifyResult.OK, c.verify("123456", T0 + 2000));
    }

    @Test
    void qua5LanSaiThiLocked() {
        PayOSConfigChallenge c = real();
        for (int i = 0; i < 4; i++) {
            assertEquals(PayOSConfigChallenge.VerifyResult.INVALID, c.verify("000000", T0 + i));
        }
        assertEquals(PayOSConfigChallenge.VerifyResult.LOCKED, c.verify("000000", T0 + 10));
        assertEquals(PayOSConfigChallenge.VerifyResult.LOCKED, c.verify("123456", T0 + 11));
    }

    @Test
    void het5PhutThiExpired() {
        PayOSConfigChallenge c = real();
        assertEquals(PayOSConfigChallenge.VerifyResult.EXPIRED,
                c.verify("123456", T0 + PayOSConfigChallenge.TTL_MS + 1));
    }

    @Test
    void resendCooldown60s() {
        PayOSConfigChallenge c = real();
        assertFalse(c.canResend(T0 + 30_000));
        assertEquals(30, c.resendWaitSeconds(T0 + 30_000));
        assertTrue(c.canResend(T0 + 60_000));
        assertThrows(IllegalStateException.class, () -> c.applyResend("654321", T0 + 30_000));
    }

    @Test
    void resendInvalidateMaCuVaResetAttempt() {
        PayOSConfigChallenge c = real();
        c.verify("000000", T0 + 1000);
        c.applyResend("654321", T0 + 61_000);
        assertEquals(0, c.getAttemptCount());
        assertEquals(2, c.getSendCount());
        assertEquals(PayOSConfigChallenge.VerifyResult.INVALID, c.verify("123456", T0 + 62_000));
        assertEquals(PayOSConfigChallenge.VerifyResult.OK, c.verify("654321", T0 + 63_000));
    }

    @Test
    void pendingValuesAndFieldsChangedArePreserved() {
        PayOSConfigChallenge c = real();
        assertEquals(7, c.getCoSoId());
        assertEquals(42, c.getAdminAccountId());
        assertEquals("client-new", c.getPendingClientId());
        assertEquals("api-new", c.getPendingApiKey());
        assertEquals("checksum-new", c.getPendingChecksumKey());
        assertEquals(List.of("CLIENT_ID", "API_KEY", "CHECKSUM_KEY"), c.getFieldsChanged());
    }
}
```

- [ ] **Step 2: Run test to verify it fails (class does not exist yet)**

Run: `mvn -q -Dtest=PayOSConfigChallengeTest test`
Expected: COMPILE ERROR — `cannot find symbol: class PayOSConfigChallenge`

- [ ] **Step 3: Write the implementation**

Create `src/main/java/org/example/service/PayOSConfigChallenge.java`:

```java
package org.example.service;

import org.example.service.reset.ResetSecurityUtil;

import java.io.Serializable;
import java.util.List;

/**
 * Challenge xác thực OTP trước khi lưu thay đổi Client ID/API Key/Checksum Key
 * PayOS của một Cơ Sở. Lưu trong HTTP session (nhất quán với PasswordResetChallenge
 * và luồng OTP thêm chi nhánh hiện có). Chỉ giữ HASH của OTP; OTP raw chỉ tồn tại
 * trong email gửi cho Admin. Giá trị khóa mới (pending) được giữ tạm để commit khi
 * OTP đúng — độ nhạy cảm tương đương dữ liệu đã lưu plaintext trong CoSo.PayOS_*.
 */
public class PayOSConfigChallenge implements Serializable {

    private static final long serialVersionUID = 1L;

    public static final long TTL_MS = 5 * 60_000L;           // OTP hết hạn sau 5 phút
    public static final long RESEND_COOLDOWN_MS = 60_000L;   // 60s giữa 2 lần gửi
    public static final int MAX_ATTEMPTS = 5;                // tối đa 5 lần nhập sai
    public static final int MAX_SENDS = 5;                   // tối đa 5 lần gửi mã

    public enum VerifyResult { OK, INVALID, EXPIRED, LOCKED, USED }

    private final int coSoId;
    private final int adminAccountId;
    private final String maskedDestination;
    private final String pendingClientId;
    private final String pendingApiKey;
    private final String pendingChecksumKey;
    private final List<String> fieldsChanged;

    private String salt;
    private String otpHash;
    private long expiresAt;
    private long lastSentAt;
    private int sendCount;
    private int attemptCount;
    private boolean used;

    private PayOSConfigChallenge(int coSoId, int adminAccountId, String maskedDestination,
                                  String pendingClientId, String pendingApiKey, String pendingChecksumKey,
                                  List<String> fieldsChanged) {
        this.coSoId = coSoId;
        this.adminAccountId = adminAccountId;
        this.maskedDestination = maskedDestination;
        this.pendingClientId = pendingClientId;
        this.pendingApiKey = pendingApiKey;
        this.pendingChecksumKey = pendingChecksumKey;
        this.fieldsChanged = fieldsChanged;
    }

    public static PayOSConfigChallenge create(int coSoId, int adminAccountId, String maskedDestination,
                                               String pendingClientId, String pendingApiKey,
                                               String pendingChecksumKey, List<String> fieldsChanged,
                                               String otp, long now) {
        PayOSConfigChallenge c = new PayOSConfigChallenge(coSoId, adminAccountId, maskedDestination,
                pendingClientId, pendingApiKey, pendingChecksumKey, fieldsChanged);
        c.applyNewOtp(otp, now);
        return c;
    }

    private void applyNewOtp(String otp, long now) {
        this.salt = ResetSecurityUtil.newSalt();
        this.otpHash = ResetSecurityUtil.hashOtp(this.salt, otp);
        this.expiresAt = now + TTL_MS;
        this.lastSentAt = now;
        this.sendCount++;
        this.attemptCount = 0;
        this.used = false;
    }

    /** Xác thực OTP; tăng attempt khi sai; one-time-use khi đúng. */
    public VerifyResult verify(String input, long now) {
        if (used) return VerifyResult.USED;
        if (now > expiresAt) return VerifyResult.EXPIRED;
        if (attemptCount >= MAX_ATTEMPTS) return VerifyResult.LOCKED;
        attemptCount++;
        if (input == null || !input.matches("\\d{6}")) {
            return attemptCount >= MAX_ATTEMPTS ? VerifyResult.LOCKED : VerifyResult.INVALID;
        }
        String actual = ResetSecurityUtil.hashOtp(salt, input);
        if (ResetSecurityUtil.hashEquals(otpHash, actual)) {
            used = true;
            return VerifyResult.OK;
        }
        return attemptCount >= MAX_ATTEMPTS ? VerifyResult.LOCKED : VerifyResult.INVALID;
    }

    public boolean canResend(long now) {
        return !used && sendCount < MAX_SENDS && (now - lastSentAt) >= RESEND_COOLDOWN_MS;
    }

    /** Số giây còn phải chờ trước khi được gửi lại (0 nếu được gửi ngay). */
    public long resendWaitSeconds(long now) {
        long wait = (RESEND_COOLDOWN_MS - (now - lastSentAt) + 999) / 1000;
        return Math.max(0, wait);
    }

    /** Gửi lại: OTP mới thay OTP cũ (invalidate mã cũ), reset attempts, gia hạn expiry. */
    public void applyResend(String newOtp, long now) {
        if (!canResend(now)) {
            throw new IllegalStateException("Chưa đủ điều kiện gửi lại mã");
        }
        applyNewOtp(newOtp, now);
    }

    public int getCoSoId() { return coSoId; }
    public int getAdminAccountId() { return adminAccountId; }
    public String getMaskedDestination() { return maskedDestination; }
    public String getPendingClientId() { return pendingClientId; }
    public String getPendingApiKey() { return pendingApiKey; }
    public String getPendingChecksumKey() { return pendingChecksumKey; }
    public List<String> getFieldsChanged() { return fieldsChanged; }
    public boolean isUsed() { return used; }
    public int getAttemptCount() { return attemptCount; }
    public int getSendCount() { return sendCount; }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mvn -q -Dtest=PayOSConfigChallengeTest test`
Expected: PASS (8 tests, 0 failures)

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/service/PayOSConfigChallenge.java src/test/java/org/example/service/PayOSConfigChallengeTest.java
git commit -m "feat: add PayOSConfigChallenge for OTP-gated PayOS key updates"
```

---

### Task 2: Refactor `PayOSConfigurationService` — split validate-only from persist, add challenge persistence

**Files:**
- Modify: `src/main/java/org/example/service/PayOSConfigurationService.java`
- Test: `src/test/java/org/example/service/PayOSConfigurationServiceTest.java` (existing file — verify it still passes unmodified; it only tests the untouched `mergeAndValidate` static method)

**Interfaces:**
- Produces: `PayOSConfigurationService.PreparedUpdate` (public static nested class: fields `coSo`, `finalClientId`, `finalApiKey`, `finalChecksumKey`, `fieldsChanged`), `prepareUpdate(int coSoId, String newClientId, String newApiKey, String newChecksumKey) -> PreparedUpdate` (throws `PayOSConfigurationException` on invalid input — no DB write), `persistPrepared(PreparedUpdate prepared, HttpServletRequest req, TaiKhoan admin) -> PayOSConfigurationUpdateResult` (does the DB write + audit log), `persistChallenge(PayOSConfigChallenge challenge, HttpServletRequest req, TaiKhoan admin) -> PayOSConfigurationUpdateResult` (reloads the CoSo, builds a `PreparedUpdate` from the challenge's pending values, delegates to `persistPrepared`).
- Consumes: `PayOSConfigChallenge` (Task 1).

- [ ] **Step 1: Confirm the existing test still compiles/passes as a baseline**

Run: `mvn -q -Dtest=PayOSConfigurationServiceTest test`
Expected: PASS (6 tests) — this baseline must stay green after the refactor since it only exercises `mergeAndValidate`, which is not being changed.

- [ ] **Step 2: Replace `updateConfiguration` with `prepareUpdate` + `persistPrepared`, add `persistChallenge`**

In `src/main/java/org/example/service/PayOSConfigurationService.java`, replace the entire `updateConfiguration` method (lines 62–98) with:

```java
    public PayOSConfigurationUpdateResult updateConfiguration(int coSoId, String newClientId, String newApiKey,
                                                                String newChecksumKey, HttpServletRequest req,
                                                                TaiKhoan admin) {
        PreparedUpdate prepared;
        try {
            prepared = prepareUpdate(coSoId, newClientId, newApiKey, newChecksumKey);
        } catch (PayOSConfigurationException e) {
            return PayOSConfigurationUpdateResult.fail(e.getHttpStatus(), e.getMessage());
        }
        return persistPrepared(prepared, req, admin);
    }

    /** Merge + validate CHỈ, KHÔNG ghi DB, KHÔNG ghi audit log — dùng để quyết định có cần OTP hay không. */
    public PreparedUpdate prepareUpdate(int coSoId, String newClientId, String newApiKey, String newChecksumKey) {
        CoSo coSo = loadActiveCoSoOrThrow(coSoId);
        PayOSCredentials current = payOSConfigDAO.findPayOSConfigurationStatusByCoSoId(coSoId);
        if (current == null) current = new PayOSCredentials(null, null, null);

        MergeOutcome merged = mergeAndValidate(current, newClientId, newApiKey, newChecksumKey);
        if (!merged.valid) {
            throw new PayOSConfigurationException(400, merged.errorMessage);
        }
        return new PreparedUpdate(coSo, merged.finalClientId, merged.finalApiKey, merged.finalChecksumKey,
                merged.fieldsChanged);
    }

    /** Ghi DB + audit log cho một PreparedUpdate đã được validate (và đã xác thực OTP nếu cần). */
    public PayOSConfigurationUpdateResult persistPrepared(PreparedUpdate prepared, HttpServletRequest req,
                                                           TaiKhoan admin) {
        int coSoId = prepared.coSo.getCoSoID();
        PayOSCredentials current = payOSConfigDAO.findPayOSConfigurationStatusByCoSoId(coSoId);
        if (current == null) current = new PayOSCredentials(null, null, null);
        boolean wasConfiguredBefore = current.toState() != PayOSConfigState.NOT_CONFIGURED;

        if (prepared.fieldsChanged.isEmpty()) {
            return PayOSConfigurationUpdateResult.ok(buildStatus(prepared.coSo, current), prepared.fieldsChanged);
        }

        boolean updated = payOSConfigDAO.updatePayOSConfiguration(
                coSoId, prepared.finalClientId, prepared.finalApiKey, prepared.finalChecksumKey);
        if (!updated) {
            return PayOSConfigurationUpdateResult.fail(500, "Không thể cập nhật cấu hình PayOS. Vui lòng thử lại.");
        }

        String action = wasConfiguredBefore ? AuditLogService.ACTION_UPDATE : AuditLogService.ACTION_CREATE;
        String details = "Admin cập nhật cấu hình PayOS cho cơ sở #" + coSoId +
                " (đã xác thực OTP). Fields changed: " + String.join(", ", prepared.fieldsChanged) + ".";
        AuditLogService.log(req, admin, coSoId, action, AuditLogService.ENTITY_PAYOS_CONFIG,
                String.valueOf(coSoId), prepared.coSo.getTenCoSo(), details);

        PayOSCredentials finalRaw = new PayOSCredentials(prepared.finalClientId, prepared.finalApiKey,
                prepared.finalChecksumKey);
        return PayOSConfigurationUpdateResult.ok(buildStatus(prepared.coSo, finalRaw), prepared.fieldsChanged);
    }

    /** Sau khi OTP xác thực OK: nạp lại CoSo mới nhất rồi persist các giá trị pending trong challenge. */
    public PayOSConfigurationUpdateResult persistChallenge(PayOSConfigChallenge challenge, HttpServletRequest req,
                                                            TaiKhoan admin) {
        CoSo coSo;
        try {
            coSo = loadActiveCoSoOrThrow(challenge.getCoSoId());
        } catch (PayOSConfigurationException e) {
            return PayOSConfigurationUpdateResult.fail(e.getHttpStatus(), e.getMessage());
        }
        PreparedUpdate prepared = new PreparedUpdate(coSo, challenge.getPendingClientId(),
                challenge.getPendingApiKey(), challenge.getPendingChecksumKey(), challenge.getFieldsChanged());
        return persistPrepared(prepared, req, admin);
    }

    public static final class PreparedUpdate {
        public final CoSo coSo;
        public final String finalClientId;
        public final String finalApiKey;
        public final String finalChecksumKey;
        public final List<String> fieldsChanged;

        PreparedUpdate(CoSo coSo, String finalClientId, String finalApiKey, String finalChecksumKey,
                       List<String> fieldsChanged) {
            this.coSo = coSo;
            this.finalClientId = finalClientId;
            this.finalApiKey = finalApiKey;
            this.finalChecksumKey = finalChecksumKey;
            this.fieldsChanged = fieldsChanged;
        }
    }
```

Add the import at the top of the file, alongside the existing imports:

```java
import jakarta.servlet.http.HttpServletRequest;
```

(already present — no change needed there; just confirm `PayOSConfigChallenge` needs no import since it lives in the same package `org.example.service`.)

- [ ] **Step 3: Run both PayOS test files to confirm nothing broke**

Run: `mvn -q -Dtest=PayOSConfigurationServiceTest,PayOSConfigChallengeTest test`
Expected: PASS (14 tests total, 0 failures) — `updateConfiguration`'s public signature and behavior are unchanged (it's now a thin wrapper), so the existing test (which never calls `updateConfiguration` directly, only `mergeAndValidate`) is unaffected.

- [ ] **Step 4: Compile the whole project to catch any call-site issues**

Run: `mvn -q compile`
Expected: BUILD SUCCESS (the only current caller of `updateConfiguration`, `PayOSConfigAdminServlet.doPost`, keeps compiling since the method signature didn't change — it'll be rewired in Task 4).

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/service/PayOSConfigurationService.java
git commit -m "refactor: split PayOSConfigurationService.updateConfiguration into prepareUpdate/persistPrepared/persistChallenge"
```

---

### Task 3: `PayOSConfigAdminServlet` — OTP-gated save flow (request / verify / resend)

**Files:**
- Modify: `src/main/java/org/example/controller/admin/PayOSConfigAdminServlet.java`

**Interfaces:**
- Consumes: `PayOSConfigurationService.prepareUpdate/persistPrepared/persistChallenge` (Task 2), `PayOSConfigChallenge` (Task 1), `org.example.service.reset.ResetSecurityUtil.generateOtp()/maskEmail()`, `org.example.util.EmailUtil.sendEmail(to, subject, body)`.
- Produces (unchanged URL `/admin/chi-nhanh/payos`, POST, dispatched by `action` param): `action` absent or `save` → `{success, requiresOtp, maskedEmail?, resendWaitSeconds?, message?, configuration?}`; `action=verify-otp` → `{success, message?, configuration?, attemptsLeft?}`; `action=resend-otp` → `{success, resendWaitSeconds, message?}`.

- [ ] **Step 1: Replace `doPost` with an action dispatcher and the three handlers**

In `src/main/java/org/example/controller/admin/PayOSConfigAdminServlet.java`, replace imports (add these lines after the existing `import java.io.IOException;`):

```java
import org.example.model.CoSo;
import org.example.service.PayOSConfigChallenge;
import org.example.service.reset.ResetSecurityUtil;
import org.example.util.EmailUtil;
```

Replace the whole existing `doPost` method (lines 47–84) with:

```java
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan admin = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        if (admin == null) {
            writeJson(resp, 403, errorJson("Bạn không có quyền thực hiện thao tác này."));
            return;
        }

        String action = req.getParameter("action");
        if ("verify-otp".equals(action)) {
            handleVerifyOtp(req, resp, admin);
        } else if ("resend-otp".equals(action)) {
            handleResendOtp(req, resp, admin);
        } else {
            handleRequestSave(req, resp, admin);
        }
    }

    /** Bước 1: merge/validate. Không đổi gì thật sự -> lưu ngay. Có đổi khóa -> gửi OTP, chưa ghi DB. */
    private void handleRequestSave(HttpServletRequest req, HttpServletResponse resp, TaiKhoan admin)
            throws IOException {
        Integer coSoId = parseCoSoId(req.getParameter("coSoId"));
        if (coSoId == null) {
            writeJson(resp, 400, errorJson("CoSoID không hợp lệ."));
            return;
        }
        String clientId = req.getParameter("clientId");
        String apiKey = req.getParameter("apiKey");
        String checksumKey = req.getParameter("checksumKey");

        PayOSConfigurationService.PreparedUpdate prepared;
        try {
            prepared = payOSConfigurationService.prepareUpdate(coSoId, clientId, apiKey, checksumKey);
        } catch (PayOSConfigurationService.PayOSConfigurationException e) {
            writeJson(resp, e.getHttpStatus(), errorJson(e.getMessage()));
            return;
        } catch (Exception e) {
            logger.error("Lỗi khi kiểm tra cấu hình PayOS cho CoSoID {}: {}", coSoId, e.getMessage());
            writeJson(resp, 500, errorJson("Lỗi hệ thống khi kiểm tra cấu hình PayOS."));
            return;
        }

        if (prepared.fieldsChanged.isEmpty()) {
            PayOSConfigurationUpdateResult result = payOSConfigurationService.persistPrepared(prepared, req, admin);
            JsonObject body = new JsonObject();
            body.addProperty("success", result.isSuccess());
            body.addProperty("requiresOtp", false);
            if (result.isSuccess()) {
                body.addProperty("message", "Không có thay đổi nào cần lưu.");
                body.add("configuration", toJson(result.getStatus()));
                writeJson(resp, 200, body);
            } else {
                writeJson(resp, result.getHttpStatus(), errorJson(result.getMessage()));
            }
            return;
        }

        String otp = ResetSecurityUtil.generateOtp();
        String maskedEmail = ResetSecurityUtil.maskEmail(admin.getEmail());
        PayOSConfigChallenge challenge = PayOSConfigChallenge.create(
                coSoId, admin.getAccountId(), maskedEmail,
                prepared.finalClientId, prepared.finalApiKey, prepared.finalChecksumKey,
                prepared.fieldsChanged, otp, System.currentTimeMillis());

        try {
            sendOtpEmail(admin, prepared.coSo, otp, "V-SPORT — Mã xác thực cập nhật PayOS");
        } catch (Exception e) {
            logger.error("Lỗi gửi email OTP cấu hình PayOS cho CoSoID {}: {}", coSoId, e.getMessage());
            writeJson(resp, 502, errorJson("Không thể gửi mã xác thực. Vui lòng thử lại sau."));
            return;
        }

        req.getSession(true).setAttribute("payosChallenge", challenge);

        JsonObject body = new JsonObject();
        body.addProperty("success", true);
        body.addProperty("requiresOtp", true);
        body.addProperty("maskedEmail", maskedEmail);
        body.addProperty("resendWaitSeconds", challenge.resendWaitSeconds(System.currentTimeMillis()));
        writeJson(resp, 200, body);
    }

    /** Bước 2: xác thực OTP. Đúng -> ghi DB + audit log. Sai/hết hạn/khóa -> không đổi DB. */
    private void handleVerifyOtp(HttpServletRequest req, HttpServletResponse resp, TaiKhoan admin)
            throws IOException {
        Integer coSoId = parseCoSoId(req.getParameter("coSoId"));
        HttpSession session = req.getSession(false);
        PayOSConfigChallenge challenge = session != null
                ? (PayOSConfigChallenge) session.getAttribute("payosChallenge") : null;

        if (challenge == null || coSoId == null || challenge.getCoSoId() != coSoId
                || challenge.getAdminAccountId() != admin.getAccountId()) {
            writeJson(resp, 400, errorJson("Phiên xác thực OTP đã hết hạn hoặc không hợp lệ. Vui lòng thao tác lại từ đầu."));
            return;
        }

        String otp = req.getParameter("otp");
        PayOSConfigChallenge.VerifyResult result = challenge.verify(otp, System.currentTimeMillis());

        if (result == PayOSConfigChallenge.VerifyResult.OK) {
            PayOSConfigurationUpdateResult updateResult = payOSConfigurationService.persistChallenge(challenge, req, admin);
            session.removeAttribute("payosChallenge");
            if (!updateResult.isSuccess()) {
                writeJson(resp, updateResult.getHttpStatus(), errorJson(updateResult.getMessage()));
                return;
            }
            JsonObject body = new JsonObject();
            body.addProperty("success", true);
            body.addProperty("message", updateResult.getMessage());
            body.add("configuration", toJson(updateResult.getStatus()));
            writeJson(resp, 200, body);
            return;
        }

        if (result == PayOSConfigChallenge.VerifyResult.EXPIRED) {
            session.removeAttribute("payosChallenge");
            writeJson(resp, 400, errorJson("Mã OTP đã hết hạn. Vui lòng đóng và thao tác lại từ đầu."));
            return;
        }
        if (result == PayOSConfigChallenge.VerifyResult.LOCKED) {
            session.removeAttribute("payosChallenge");
            writeJson(resp, 429, errorJson("Bạn đã nhập sai quá 5 lần. Vui lòng đóng và thao tác lại từ đầu."));
            return;
        }
        if (result == PayOSConfigChallenge.VerifyResult.USED) {
            writeJson(resp, 400, errorJson("Mã OTP này đã được sử dụng."));
            return;
        }

        int attemptsLeft = PayOSConfigChallenge.MAX_ATTEMPTS - challenge.getAttemptCount();
        JsonObject body = new JsonObject();
        body.addProperty("success", false);
        body.addProperty("message", "Mã OTP không đúng. Còn " + attemptsLeft + " lần thử.");
        body.addProperty("attemptsLeft", attemptsLeft);
        writeJson(resp, 200, body);
    }

    /** Gửi lại OTP cho challenge đang mở, tôn trọng cooldown 60s và giới hạn 5 lần gửi. */
    private void handleResendOtp(HttpServletRequest req, HttpServletResponse resp, TaiKhoan admin)
            throws IOException {
        Integer coSoId = parseCoSoId(req.getParameter("coSoId"));
        HttpSession session = req.getSession(false);
        PayOSConfigChallenge challenge = session != null
                ? (PayOSConfigChallenge) session.getAttribute("payosChallenge") : null;

        if (challenge == null || coSoId == null || challenge.getCoSoId() != coSoId
                || challenge.getAdminAccountId() != admin.getAccountId()) {
            writeJson(resp, 400, errorJson("Phiên xác thực OTP đã hết hạn. Vui lòng thao tác lại từ đầu."));
            return;
        }

        long now = System.currentTimeMillis();
        if (!challenge.canResend(now)) {
            JsonObject body = new JsonObject();
            body.addProperty("success", false);
            body.addProperty("message", "Vui lòng chờ trước khi gửi lại mã.");
            body.addProperty("resendWaitSeconds", challenge.resendWaitSeconds(now));
            writeJson(resp, 429, body);
            return;
        }

        String otp = ResetSecurityUtil.generateOtp();
        CoSo coSo = null;
        try {
            coSo = payOSConfigurationService.prepareUpdate(coSoId, null, null, null).coSo;
        } catch (Exception ignored) {
            // best-effort chỉ để lấy tên cơ sở cho nội dung email; không chặn resend nếu lỗi
        }
        try {
            sendOtpEmail(admin, coSo, otp, "V-SPORT — Mã xác thực cập nhật PayOS (gửi lại)");
        } catch (Exception e) {
            logger.error("Lỗi gửi lại email OTP PayOS cho CoSoID {}: {}", coSoId, e.getMessage());
            writeJson(resp, 502, errorJson("Không thể gửi lại mã. Vui lòng thử lại sau."));
            return;
        }
        challenge.applyResend(otp, now);

        JsonObject body = new JsonObject();
        body.addProperty("success", true);
        body.addProperty("resendWaitSeconds", challenge.resendWaitSeconds(now));
        writeJson(resp, 200, body);
    }

    private void sendOtpEmail(TaiKhoan admin, CoSo coSo, String otp, String subject) throws Exception {
        String coSoName = coSo != null ? coSo.getTenCoSo() : "cơ sở đã chọn";
        EmailUtil.sendEmail(admin.getEmail(), subject,
                "Chào " + (admin.getFullName() != null ? admin.getFullName() : admin.getUsername()) + ",\n\n"
                + "Mã xác thực để cập nhật cấu hình PayOS cho \"" + coSoName + "\" là: " + otp + "\n\n"
                + "Mã có hiệu lực trong 5 phút và chỉ dùng được một lần.\n"
                + "Không chia sẻ mã này với bất kỳ ai, kể cả nhân viên V-SPORT.\n\n"
                + "Nếu bạn không yêu cầu thao tác này, vui lòng bỏ qua email này và kiểm tra lại tài khoản quản trị của bạn.");
    }
```

Note: `handleRequestSave`'s no-op branch (`prepared.fieldsChanged.isEmpty()`) reuses `payOSConfigurationService.persistPrepared(...)`, which for an empty `fieldsChanged` list returns `ok(...)` without touching the DB or writing an audit log — this is existing, unchanged behavior from before the refactor (see Task 2 Step 2), so a blank submit is still a true no-op.

- [ ] **Step 2: Compile**

Run: `mvn -q compile`
Expected: BUILD SUCCESS

- [ ] **Step 3: Commit**

```bash
git add src/main/java/org/example/controller/admin/PayOSConfigAdminServlet.java
git commit -m "feat: require OTP verification before persisting changed PayOS credentials"
```

---

### Task 4: `AuditLogService` — add `ENTITY_HOA_DON`; wire audit logging into `HoaDonManagerServlet`

**Files:**
- Modify: `src/main/java/org/example/service/AuditLogService.java`
- Modify: `src/main/java/org/example/controller/manager/HoaDonManagerServlet.java`

**Interfaces:**
- Produces: `AuditLogService.ENTITY_HOA_DON = "HoaDon"` constant.
- Consumes: existing `AuditLogService.log(HttpServletRequest req, TaiKhoan actor, String action, String entityType, String entityId, String entityName, String details)` overload (already captures IP internally via `getClientIp(req)` — no new overload needed).

- [ ] **Step 1: Add the entity constant**

In `src/main/java/org/example/service/AuditLogService.java`, in the "Các hằng số loại thực thể" block (after line 58 `public static final String ENTITY_DAT_SAN = "LichDatSan";`), add:

```java
    public static final String ENTITY_HOA_DON   = "HoaDon";
```

- [ ] **Step 2: Wire logging calls into `HoaDonManagerServlet.doPost`**

In `src/main/java/org/example/controller/manager/HoaDonManagerServlet.java`, add the import after the existing `org.example.model.TaiKhoan` import:

```java
import org.example.service.AuditLogService;
```

Replace the three action branches inside `doPost` (lines 213–225) with:

```java
            if ("payInvoice".equals(action)) {
                int hoaDonId        = Integer.parseInt(req.getParameter("hoaDonId"));
                String paymentMethod = req.getParameter("phuongThucThanhToan");
                if (paymentMethod == null || paymentMethod.trim().isEmpty()) paymentMethod = "Tiền mặt";
                payInvoice(hoaDonId, user, paymentMethod);
                AuditLogService.log(req, user, AuditLogService.ACTION_UPDATE, AuditLogService.ENTITY_HOA_DON,
                        String.valueOf(hoaDonId), "Hóa đơn #" + hoaDonId,
                        "Manager thanh toán hóa đơn bằng " + paymentMethod + ".");
                resp.getWriter().write("{\"ok\":true,\"msg\":\"Đã thanh toán hóa đơn #" + hoaDonId + " thành công.\"}");
            } else if ("createServiceInvoice".equals(action)) {
                int newHoaDonId = createServiceInvoice(req, user);
                AuditLogService.log(req, user, AuditLogService.ACTION_CREATE, AuditLogService.ENTITY_HOA_DON,
                        String.valueOf(newHoaDonId), "Hóa đơn #" + newHoaDonId,
                        "Manager tạo hóa đơn dịch vụ.");
                resp.getWriter().write("{\"ok\":true,\"msg\":\"Đã tạo hóa đơn dịch vụ #" + newHoaDonId + ".\",\"hoaDonId\":" + newHoaDonId + "}");
            } else if ("cancelInvoice".equals(action)) {
                int hoaDonId = Integer.parseInt(req.getParameter("hoaDonId"));
                cancelInvoice(hoaDonId, user);
                AuditLogService.log(req, user, AuditLogService.ACTION_CANCEL, AuditLogService.ENTITY_HOA_DON,
                        String.valueOf(hoaDonId), "Hóa đơn #" + hoaDonId,
                        "Manager hủy hóa đơn.");
                resp.getWriter().write("{\"ok\":true,\"msg\":\"Đã hủy hóa đơn #" + hoaDonId + ".\"}");
            } else {
```

(The `else { ... }` closing the "Hành động không hợp lệ" branch and the surrounding `try`/`catch` stay unchanged — only the 3 success paths gain a logging call each, placed after the private helper succeeds and before the JSON response is written, so a thrown exception from `payInvoice`/`createServiceInvoice`/`cancelInvoice` still skips logging exactly like it skips the success response today.)

- [ ] **Step 3: Compile**

Run: `mvn -q compile`
Expected: BUILD SUCCESS

- [ ] **Step 4: Commit**

```bash
git add src/main/java/org/example/service/AuditLogService.java src/main/java/org/example/controller/manager/HoaDonManagerServlet.java
git commit -m "feat: audit-log manager invoice pay/create/cancel actions with IP"
```

---

### Task 5: `manager/AuditLog.jsp` — show IP column, add "Hóa đơn" entity filter

**Files:**
- Modify: `src/main/webapp/manager/AuditLog.jsp`

- [ ] **Step 1: Add "Hóa đơn" to the entity-type filter dropdown**

In `src/main/webapp/manager/AuditLog.jsp`, inside the `<select name="entityType">` block (after the `YeuCauNghi` option, line 72), add:

```jsp
          <option value="HoaDon" <c:if test="${entityType == 'HoaDon'}">selected</c:if>>Hóa đơn</option>
```

- [ ] **Step 2: Add "Hóa đơn" to the entity-type display mapping**

In the table body's entity-type `<c:choose>` block (after the `YeuCauNghi` case, line 187), add:

```jsp
                        <c:when test="${log.entityType == 'HoaDon'}">Hóa đơn</c:when>
```

- [ ] **Step 3: Add an IP column to the table**

Add a new `<th>` after "Mô tả chi tiết" in the `<thead>` (line 118):

```jsp
            <th class="px-5 py-3 text-left">IP</th>
```

Add the matching `<td>` after the "Mô tả chi tiết" `<td>` in the row loop (after line 194, before `</tr>`):

```jsp
                  <td class="px-5 py-4 whitespace-nowrap">
                    <span class="text-[11px] font-mono text-purple-400 bg-purple-50 border border-purple-100/60 px-2.5 py-1 rounded-lg">
                      <c:out value="${log.ipAddress}" default="—"/>
                    </span>
                  </td>
```

Update the empty-state `colspan` from `5` to `6` (line 125):

```jsp
                <td colspan="6" class="text-center py-16 text-purple-300">
```

- [ ] **Step 4: Manual check**

Deploy and open `/manager/audit-log` as a Manager account; confirm the table renders 6 columns including an "IP" column with a real IP (e.g. `127.0.0.1` or `0:0:0:0:0:0:0:1` on localhost), and that filtering by "Hóa đơn" (after Task 4 is deployed and at least one invoice action has been performed) returns those rows.

- [ ] **Step 5: Commit**

```bash
git add src/main/webapp/manager/AuditLog.jsp
git commit -m "feat: show IP column and Hóa đơn entity filter in manager audit log"
```

---

### Task 6: `QuanLyChiNhanhServlet` — fix opening/closing-hour NULL handling; stop touching sports/courts on edit

**Files:**
- Modify: `src/main/java/org/example/controller/admin/QuanLyChiNhanhServlet.java`

- [ ] **Step 1: Stop defaulting NULL hours to `"00:00"` in the JSON GET branch**

In the `doGet` method's `format=json` branch, replace lines 164–165:

```java
                    String gioMo = chiNhanh.getGioMoCua() != null ? chiNhanh.getGioMoCua().toString() : "00:00";
                    String gioDong = chiNhanh.getGioDongCua() != null ? chiNhanh.getGioDongCua().toString() : "00:00";
```

with:

```java
                    String gioMo = chiNhanh.getGioMoCua() != null ? chiNhanh.getGioMoCua().toString() : null;
                    String gioDong = chiNhanh.getGioDongCua() != null ? chiNhanh.getGioDongCua().toString() : null;
```

Then replace the JSON-building lines 176–177:

```java
                        + "\"gioMoCua\":\"" + gioMo + "\","
                        + "\"gioDongCua\":\"" + gioDong + "\","
```

with (emit real JSON `null`, not the string `"null"`, so the frontend can distinguish "no value" from an actual time string):

```java
                        + "\"gioMoCua\":" + (gioMo != null ? "\"" + gioMo + "\"" : "null") + ","
                        + "\"gioDongCua\":" + (gioDong != null ? "\"" + gioDong + "\"" : "null") + ","
```

- [ ] **Step 2: Stop the edit path from overwriting hours with a hardcoded 8:00/22:00 default**

In `doPost`, inside the `path.equals("/admin/chi-nhanh/sua")` branch, replace:

```java
            chiNhanh.setGioMoCua(gioMo);
            chiNhanh.setGioDongCua(gioDong);
```

with:

```java
            // Chỉ ghi đè giờ hoạt động khi form thực sự gửi giá trị — không tự gán
            // mặc định 8:00/22:00 (đó chỉ dùng cho "Thêm Cơ Sở"). Nếu form để trống,
            // giữ nguyên giá trị đã nạp từ DB ở trên (kể cả khi giá trị đó là NULL).
            if (gioMoStr != null && !gioMoStr.isEmpty()) {
                chiNhanh.setGioMoCua(LocalTime.parse(gioMoStr));
            }
            if (gioDongStr != null && !gioDongStr.isEmpty()) {
                chiNhanh.setGioDongCua(LocalTime.parse(gioDongStr));
            }
```

(`gioMo`/`gioDong`, the pre-computed `LocalTime` values with the 8:00/22:00 fallback, remain used as-is in the `/admin/chi-nhanh/them` branch a few lines above — that fallback stays correct there since "Thêm Cơ Sở" marks both time inputs `required` client-side and is creating a brand-new record.)

- [ ] **Step 3: Stop the edit path from touching sports/court fields at all**

Still inside the `path.equals("/admin/chi-nhanh/sua")` branch, remove these two lines entirely:

```java
            chiNhanh.setLoaiHinhKinhDoanh(loaiHinh);
            chiNhanh.setSoLuongSanDuKien(totalCourts);
```

And remove this line (a few lines below, right after `chiNhanhDAO.updateCoSo(chiNhanh);`):

```java
            // Dynamic court synchronization for edited branch
            syncCourtsForBranch(id, sportCounts);
```

After this step, the `sua` branch no longer reads or writes `LoaiHinhKinhDoanh`/`SoLuongSanDuKien`/courts at all — `chiNhanh` was loaded fresh via `chiNhanhDAO.getCoSoById(id)` a few lines above and those two fields were never reassigned, so `chiNhanhDAO.updateCoSo(chiNhanh)` persists them unchanged. This is required, not optional: once Task 7 removes the sport checkboxes from the edit form, `loaiHinhArray` would be `null` on submit, and without this change `totalCourts` would compute to `0`, wiping `LoaiHinhKinhDoanh` to `""` and (via the untouched `syncCourtsForBranch` call) deleting every court and booking for that facility.

The top-of-method computation of `loaiHinhArray`/`sportCounts`/`totalCourts`/`loaiHinh` (lines 265–288) stays unchanged — it is still needed by the `them` (create) branch.

- [ ] **Step 4: Compile**

Run: `mvn -q compile`
Expected: BUILD SUCCESS

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/controller/admin/QuanLyChiNhanhServlet.java
git commit -m "fix: stop admin edit from overwriting hours with 00:00 default or touching sports/courts"
```

---

### Task 7: `QuanLyChiNhanh.jsp` — trim edit modal, null-safe hour display, PayOS OTP modal UI

**Files:**
- Modify: `src/main/webapp/admin/QuanLyChiNhanh.jsp`

- [ ] **Step 1: Remove the sports/court-count block from `#modalSua`**

Delete the entire "Môn thể thao" `<div>` block inside `#modalSua` (lines 1209–1258, from `<!-- Môn thể thao -->` through its closing `</div>` right before `<!-- Địa chỉ định vị GPS -->`).

In its place, insert a short read-only info line so admins understand why the fields are gone:

```jsp
        <div class="flex items-center gap-2 px-3 py-2.5 rounded-xl bg-blue-50/60 border border-blue-100 text-xs text-blue-700">
          <i class="ti ti-info-circle text-sm shrink-0"></i>
          <span>Môn thể thao và số sân do Quản lý cơ sở cấu hình tại trang "Quản lý Sân" của chi nhánh — Admin không chỉnh tại đây.</span>
        </div>
```

- [ ] **Step 2: Remove the "Tổng số lượng sân dự kiến" block from `#modalSua`**

Delete this block (originally lines 1298–1304):

```jsp
        <!-- Tổng số sân -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold text-zinc-700">Tổng số lượng sân dự kiến</label>
          <input type="number" id="sua_soLuongSanDuKienDisplay" readonly value="0"
                 class="w-full h-10 px-4 rounded-xl border border-zinc-200 text-sm font-bold text-zinc-500 bg-zinc-100 focus:outline-none select-none">
          <input type="hidden" name="soLuongSanDuKien" id="sua_soLuongSanDuKien" value="0">
        </div>
```

- [ ] **Step 3: Add a null-hours warning line under the Giờ mở/đóng cửa inputs**

In the "Giờ mở / đóng cửa" grid (originally lines 1284–1296), add a warning paragraph right after the closing `</div>` of that grid:

```jsp
        <p id="suaGioWarning" class="hidden text-[11px] font-semibold text-amber-600 -mt-2">
          <i class="ti ti-clock-exclamation text-sm align-[-2px]"></i> Giờ hoạt động chưa được thiết lập cho cơ sở này — vui lòng nhập giờ thực tế trước khi lưu.
        </p>
```

- [ ] **Step 4: Fix `openModalSua` to load real hours (or blank) instead of the old `"00:00"` string, and drop the dead sports-checkbox calls**

Replace the whole `openModalSua` function (originally lines 956–988) with:

```js
  function openModalSua(id) {
    fetch('${pageContext.request.contextPath}/admin/chi-nhanh/sua?format=json&id=' + id)
      .then(r => r.json())
      .then(data => {
        document.getElementById('suaCoSoID').value = data.coSoID;
        document.getElementById('suaTenCoSo').value = data.tenCoSo;
        document.getElementById('suaTrangThai').value = data.trangThai;
        document.getElementById('suaPhone').value = data.soDienThoai;
        document.getElementById('suaDiaChi').value = data.diaChi;

        const gioMoInput = document.getElementById('suaGioMoCua');
        const gioDongInput = document.getElementById('suaGioDongCua');
        gioMoInput.value = data.gioMoCua ? data.gioMoCua.substring(0, 5) : '';
        gioDongInput.value = data.gioDongCua ? data.gioDongCua.substring(0, 5) : '';
        document.getElementById('suaGioWarning').classList.toggle('hidden', !!(data.gioMoCua && data.gioDongCua));

        document.getElementById('suaViDo').value = data.viDo || '';
        document.getElementById('suaKinhDo').value = data.kinhDo || '';
        if (data.viDo && data.kinhDo) {
          setGeoStatus('suaGeoStatus', 'ok', parseFloat(data.viDo), parseFloat(data.kinhDo));
        } else {
          setGeoStatus('suaGeoStatus', 'none');
        }

        document.getElementById('modalSua').classList.remove('hidden');
      })
      .catch(err => {
        alert('Lỗi tải thông tin chi nhánh: ' + err);
      });
  }
```

(`data.coSoID`/`data.countBongDa`/etc. from the JSON payload keep being emitted by the servlet unchanged — this JS simply stops reading the now-removed sport-count fields.)

- [ ] **Step 5: Delete the now-dead edit-only sports helper functions**

Delete the `setupSportCheckbox` function (originally lines 990–1002) and the `updateTotalCourtsEdit` function (originally lines 1009–1018) entirely — nothing in the trimmed `#modalSua` calls them anymore. (`toggleSportCount`, used by the still-untouched "Thêm Cơ Sở" modal, stays.)

- [ ] **Step 6: Simplify `finalValidateEdit` to drop the total-courts check**

Replace the `finalValidateEdit` function (originally lines 1020–1034) with:

```js
  function finalValidateEdit() {
    const viDo = document.getElementById('suaViDo').value;
    const kinhDo = document.getElementById('suaKinhDo').value;
    if (!viDo || !kinhDo) {
      alert('Vị trí cơ sở chưa hợp lệ. Vui lòng chọn lại vị trí trên bản đồ hoặc nhập đầy đủ tọa độ.');
      return false;
    }
    return true;
  }
```

(The `required` attribute already present on `#suaGioMoCua`/`#suaGioDongCua` still blocks native submit when either is left blank — including the case where Step 4 just cleared them because the DB value was NULL — so an admin can no longer silently re-save a facility with unset hours.)

- [ ] **Step 7: Add the OTP branch to `submitPayOSConfig` and the OTP modal open/close helpers**

Replace the `.then(data => { ... })` success-handling block inside `submitPayOSConfig` (originally lines 1128–1141) with:

```js
      .then(data => {
        payosSaving = false;
        btn.disabled = false;
        btn.innerHTML = originalHtml;
        setPayOSFormDisabled(false);

        if (!data.success) {
          showPayOSFormError(data.message || 'Không thể lưu cấu hình PayOS.');
          return;
        }
        if (data.requiresOtp) {
          openPayOSOtpModal(data.maskedEmail, data.resendWaitSeconds);
          return;
        }
        updatePayOSBadge(payosCurrentCoSoId, data.configuration.status);
        showPayOSToast(data.message || 'Đã cập nhật cấu hình PayOS.');
        closePayOSModal();
      })
```

Then, right after the `submitPayOSConfig` function's closing `}` (and before `function updatePayOSBadge`), insert the new OTP-modal JS:

```js
  // ═══════════ PAYOS OTP MODAL ═══════════
  let payosOtpFails = 0, payosResendTimer = null;

  function openPayOSOtpModal(maskedEmail, resendWaitSeconds) {
    document.getElementById('payosOtpEmailDisplay').textContent = maskedEmail || '';
    document.getElementById('payosOtpErr').classList.add('hidden');
    payosOtpFails = 0;
    document.getElementById('payosOtpFails').textContent = '0';
    document.querySelectorAll('.payos-otp').forEach(b => b.value = '');
    document.getElementById('modalPayOSOtp').classList.remove('hidden');
    setTimeout(() => document.querySelector('.payos-otp[data-index="0"]').focus(), 100);
    payosStartResendCountdown(resendWaitSeconds || 60);
  }

  function closePayOSOtpModal() {
    document.getElementById('modalPayOSOtp').classList.add('hidden');
    clearInterval(payosResendTimer);
  }

  document.querySelectorAll('.payos-otp').forEach(box => {
    box.addEventListener('input', e => {
      const v = e.target.value.replace(/\D/g, '');
      e.target.value = v ? v[0] : '';
      if (v && +e.target.dataset.index < 5)
        document.querySelector('.payos-otp[data-index="' + (+e.target.dataset.index + 1) + '"]').focus();
    });
    box.addEventListener('keydown', e => {
      if (e.key === 'Backspace' && !e.target.value) {
        const p = document.querySelector('.payos-otp[data-index="' + (+e.target.dataset.index - 1) + '"]');
        if (p) { p.focus(); p.value = ''; }
      }
      if (e.key === 'Enter') submitPayOSOtp();
    });
    box.addEventListener('paste', e => {
      e.preventDefault();
      const d = (e.clipboardData||window.clipboardData).getData('text').replace(/\D/g,'').split('');
      document.querySelectorAll('.payos-otp').forEach((b,i) => b.value = d[i]||'');
      document.querySelector('.payos-otp[data-index="' + Math.min(d.length-1,5) + '"]').focus();
    });
  });

  function submitPayOSOtp() {
    const err = document.getElementById('payosOtpErr');
    err.classList.add('hidden');
    let otp = '';
    document.querySelectorAll('.payos-otp').forEach(b => otp += b.value);
    if (otp.length < 6) { err.textContent = 'Vui lòng nhập đủ 6 chữ số.'; err.classList.remove('hidden'); return; }

    const btn = document.getElementById('btnPayOSOtpVerify');
    btn.disabled = true;
    btn.innerHTML = '<span class="animate-spin inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full mr-1"></span> Đang xác thực...';

    const body = new URLSearchParams();
    body.set('action', 'verify-otp');
    body.set('coSoId', payosCurrentCoSoId);
    body.set('otp', otp);

    fetch('${pageContext.request.contextPath}/admin/chi-nhanh/payos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: body.toString()
    })
      .then(r => r.json())
      .then(data => {
        btn.disabled = false;
        btn.innerHTML = '<i class="ti ti-shield-check text-sm"></i> Xác thực OTP';
        if (data.success) {
          clearInterval(payosResendTimer);
          updatePayOSBadge(payosCurrentCoSoId, data.configuration.status);
          showPayOSToast(data.message || 'Đã cập nhật cấu hình PayOS.');
          document.getElementById('modalPayOSOtp').classList.add('hidden');
          closePayOSModal();
        } else {
          payosOtpFails++;
          document.getElementById('payosOtpFails').textContent = Math.min(payosOtpFails, 5);
          document.querySelectorAll('.payos-otp').forEach(b => b.value = '');
          document.querySelector('.payos-otp[data-index="0"]').focus();
          err.textContent = data.message || 'Mã OTP không đúng.';
          err.classList.remove('hidden');
          if (payosOtpFails >= 5) {
            setTimeout(() => { document.getElementById('modalPayOSOtp').classList.add('hidden'); }, 2000);
          }
        }
      })
      .catch(() => {
        btn.disabled = false;
        btn.innerHTML = '<i class="ti ti-shield-check text-sm"></i> Xác thực OTP';
        err.textContent = 'Lỗi kết nối. Vui lòng thử lại.';
        err.classList.remove('hidden');
      });
  }

  function payosStartResendCountdown(seconds) {
    let s = Math.max(seconds, 0);
    const btn = document.getElementById('btnPayOSResend');
    const cd = document.getElementById('payosResendCd');
    cd.textContent = s;
    btn.disabled = s > 0;
    clearInterval(payosResendTimer);
    payosResendTimer = setInterval(() => {
      s--; cd.textContent = s;
      if (s <= 0) { clearInterval(payosResendTimer); btn.disabled = false; }
    }, 1000);
  }

  function resendPayOSOtp() {
    const body = new URLSearchParams();
    body.set('action', 'resend-otp');
    body.set('coSoId', payosCurrentCoSoId);

    fetch('${pageContext.request.contextPath}/admin/chi-nhanh/payos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: body.toString()
    })
      .then(r => r.json())
      .then(data => {
        const err = document.getElementById('payosOtpErr');
        if (data.success) {
          document.querySelectorAll('.payos-otp').forEach(b => b.value = '');
          payosOtpFails = 0;
          document.getElementById('payosOtpFails').textContent = '0';
          err.classList.add('hidden');
          document.querySelector('.payos-otp[data-index="0"]').focus();
        } else {
          err.textContent = data.message || 'Không thể gửi lại mã.';
          err.classList.remove('hidden');
        }
        payosStartResendCountdown(data.resendWaitSeconds || 60);
      });
  }
```

- [ ] **Step 8: Reset the OTP modal whenever the PayOS modal itself is closed**

In `closePayOSModal()` (originally lines 1092–1096), add the two OTP-cleanup lines:

```js
  function closePayOSModal() {
    if (payosSaving) return;
    document.getElementById('modalPayOS').classList.add('hidden');
    document.getElementById('modalPayOSOtp').classList.add('hidden');
    clearInterval(payosResendTimer);
    payosCurrentCoSoId = null;
  }
```

- [ ] **Step 9: Add the `#modalPayOSOtp` markup**

Insert this new modal block right after the closing `</div>` of `#modalPayOS` (after line 1390) and before `<!-- Toast -->`:

```jsp
<!-- ═══ Modal Xác thực OTP — Cấu hình PayOS ═══ -->
<div id="modalPayOSOtp" class="hidden fixed inset-0 z-[96] flex items-center justify-center p-4">
  <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" onclick="closePayOSOtpModal()"></div>
  <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-[420px] p-6 flex flex-col gap-5">
    <div class="text-center">
      <div class="w-14 h-14 rounded-2xl bg-blue-50 flex items-center justify-center mx-auto mb-3">
        <i class="ti ti-mail-check text-blue-600 text-3xl"></i>
      </div>
      <h4 class="text-base font-bold text-zinc-900 mb-1">Xác thực thay đổi PayOS</h4>
      <p class="text-sm text-zinc-500">Mã OTP 6 chữ số đã được gửi đến</p>
      <p class="text-sm font-semibold text-blue-600 mt-0.5" id="payosOtpEmailDisplay"></p>
    </div>

    <div class="flex justify-center gap-2">
      <input type="text" maxlength="1" class="payos-otp adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="0"/>
      <input type="text" maxlength="1" class="payos-otp adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="1"/>
      <input type="text" maxlength="1" class="payos-otp adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="2"/>
      <input type="text" maxlength="1" class="payos-otp adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="3"/>
      <input type="text" maxlength="1" class="payos-otp adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="4"/>
      <input type="text" maxlength="1" class="payos-otp adm-otp w-11 h-12 text-center text-xl font-bold border-2 border-zinc-200 rounded-xl bg-white text-zinc-900 focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all" data-index="5"/>
    </div>

    <div id="payosOtpErr" class="hidden text-center text-sm text-red-500 font-medium -mt-2"></div>
    <p class="text-center text-xs text-zinc-400">Số lần nhập sai: <span id="payosOtpFails" class="font-bold text-red-500">0</span>/5</p>

    <button type="button" onclick="submitPayOSOtp()" id="btnPayOSOtpVerify"
            class="w-full h-11 rounded-xl bg-zinc-900 text-white text-sm font-bold hover:bg-zinc-800 transition-all flex items-center justify-center gap-2">
      <i class="ti ti-shield-check text-sm"></i> Xác thực OTP
    </button>
    <div class="flex items-center justify-between -mt-1">
      <button type="button" onclick="closePayOSOtpModal()" class="text-zinc-400 hover:text-zinc-700 text-sm flex items-center gap-1 bg-transparent border-none cursor-pointer">
        <i class="ti ti-arrow-left text-sm"></i> Quay lại
      </button>
      <button type="button" onclick="resendPayOSOtp()" id="btnPayOSResend"
              class="text-blue-500 hover:text-blue-700 text-sm disabled:opacity-40 bg-transparent border-none cursor-pointer" disabled>
        Gửi lại mã (<span id="payosResendCd">60</span>s)
      </button>
    </div>
  </div>
</div>
```

- [ ] **Step 10: Manual verification (JSP has no unit tests — verify by deploying and clicking through)**

Deploy and open `/admin/chi-nhanh`:
1. Open "Chỉnh sửa Cơ Sở" for any facility — confirm the sport checkboxes and "Tổng số lượng sân dự kiến" box are gone, and the info line about "Quản lý Sân" is visible.
2. Open "Chỉnh sửa Cơ Sở" for a facility with real hours set — confirm both time fields show the real value, not blank or `00:00`.
3. (If a facility with NULL hours exists, or after clearing one via direct DB update for testing) open its edit modal — confirm both time fields are blank and the amber "Giờ hoạt động chưa được thiết lập" warning shows; confirm the Save button is blocked by the browser's native required-field validation until both are filled.
4. Open "Cấu hình PayOS" for a facility, leave all 3 fields blank, click "Lưu cấu hình" — confirm it saves immediately with no OTP modal (message: "Không có thay đổi nào cần lưu.").
5. Open "Cấu hình PayOS" again, type a new Client ID, click "Lưu cấu hình" — confirm the OTP modal opens, an email arrives at the admin's account email, entering the correct 6-digit code saves and closes both modals with a success toast, and the badge updates.
6. Repeat step 5 but enter a wrong code 5 times — confirm it locks and closes the OTP modal after the 5th wrong attempt without saving (reopen "Cấu hình PayOS" afterward and confirm the Client ID is unchanged from before step 5's attempt).

- [ ] **Step 11: Commit**

```bash
git add src/main/webapp/admin/QuanLyChiNhanh.jsp
git commit -m "feat: trim admin edit-branch modal, fix null-hours display, add PayOS OTP modal"
```

---

### Task 8: `SuaChiNhanh.jsp` — trim the legacy full-page edit form to match

**Files:**
- Modify: `src/main/webapp/admin/SuaChiNhanh.jsp`

This page is reached via `GET /admin/chi-nhanh/sua?id=<id>` (without `&format=json`) — it is not linked from anywhere in the current UI (the only "Chỉnh sửa" trigger is `openModalSua()` in `QuanLyChiNhanh.jsp`, which always passes `format=json`), but the route is still live, so leaving its sport/court fields in place would let anyone who knows/bookmarks the URL bypass the Task 7 restriction and still trigger a destructive court/booking wipe via `syncCourtsForBranch`. Task 6 already made the shared servlet ignore `loaiHinhKinhDoanh`/`soLuongSan_*` on the `sua` path entirely, so removing them here is just about not showing controls that no longer do anything.

- [ ] **Step 1: Remove the "Môn thể thao" block**

Delete the entire block (originally lines 88–167, the `<div class="flex flex-col gap-1.5 col-span-1 md:col-span-2">` containing the "Môn thể thao (Cung cấp tại Cơ Sở)" label through its closing `</div>`).

In its place, insert the same read-only info line used in Task 7:

```jsp
            <div class="flex items-center gap-2 px-4 py-3 rounded-xl bg-blue-50/60 border border-blue-100 text-xs text-blue-700 col-span-1 md:col-span-2">
                <i class="ti ti-info-circle text-sm shrink-0"></i>
                <span>Môn thể thao và số sân do Quản lý cơ sở cấu hình tại trang "Quản lý Sân" của chi nhánh — Admin không chỉnh tại đây.</span>
            </div>
```

- [ ] **Step 2: Remove the "Tổng số lượng sân dự kiến" field**

Delete this block (originally lines 197–201):

```jsp
            <div class="flex flex-col gap-1.5">
                <label class="text-xs font-bold text-zinc-500 uppercase tracking-widest">Tổng số lượng sân dự kiến</label>
                <input type="number" id="soLuongSanDuKienDisplay" readonly value="${chiNhanh.soLuongSanDuKien}" class="h-10 px-4 rounded-xl border border-zinc-200 text-sm focus:outline-none bg-zinc-100 font-black text-zinc-500 select-none">
                <input type="hidden" name="soLuongSanDuKien" id="soLuongSanDuKien" value="${chiNhanh.soLuongSanDuKien}">
            </div>
```

- [ ] **Step 3: Simplify `validateForm()` to drop the total-courts check**

Replace the `validateForm` function (originally lines 294–308) with:

```js
    function validateForm() {
        const viDo = document.getElementById('viDoInput').value;
        const kinhDo = document.getElementById('kinhDoInput').value;
        if (!viDo || !kinhDo) {
            alert('Vị trí cơ sở chưa hợp lệ. Vui lòng chọn lại vị trí trên bản đồ hoặc nhập đầy đủ tọa độ.');
            return false;
        }
        return true;
    }
```

- [ ] **Step 4: Remove the now-dead `toggleSportCount`/`updateTotalCourts` functions and their `DOMContentLoaded` call**

Delete the `toggleSportCount` function (originally lines 265–277), the `updateTotalCourts` function (originally lines 279–292), and the `window.addEventListener('DOMContentLoaded', ...)` block (originally lines 310–313) that called `updateTotalCourts()` on load — none of the remaining markup on this page references them anymore.

- [ ] **Step 5: Manual check**

Deploy and navigate directly to `/admin/chi-nhanh/sua?id=<a real CoSoID>` — confirm the page loads without JS errors (check browser console), shows no sport/court fields, shows the real (or blank, for NULL) opening/closing hours since `${chiNhanh.gioMoCua}`/`${chiNhanh.gioDongCua}` are already null-safe via JSTL EL, and successfully submits an update.

- [ ] **Step 6: Commit**

```bash
git add src/main/webapp/admin/SuaChiNhanh.jsp
git commit -m "fix: trim legacy SuaChiNhanh.jsp to match the restricted edit-branch modal"
```

---

### Task 9: Full-project build + regression pass

**Files:** none (verification only)

- [ ] **Step 1: Full test suite**

Run: `mvn -q test`
Expected: BUILD SUCCESS, all tests pass including the new `PayOSConfigChallengeTest` (Task 1) and the untouched `PayOSConfigurationServiceTest` (Task 2 baseline).

- [ ] **Step 2: Full compile/package**

Run: `mvn -q package -DskipTests`
Expected: BUILD SUCCESS, WAR artifact produced with no compile errors across all touched files.

- [ ] **Step 3: Deploy locally and smoke-test the golden paths from Tasks 7 and 8's manual-check steps**

Follow Task 7 Step 10 and Task 8 Step 5 end-to-end against a running local deployment (Tomcat, as used elsewhere in this project per `http://localhost:8080/Backend_java/admin/chi-nhanh` in the current session).

- [ ] **Step 4: No commit needed — this task is verification-only.**

---

## Self-review notes (spec coverage)

- **Yêu cầu 1.1/1.2** (bỏ môn thể thao/số sân khỏi edit, giữ tên/trạng thái/địa chỉ/SĐT/tọa độ/giờ) → Tasks 6, 7, 8.
- **Yêu cầu 1.3/1.4/1.5** (load giờ thật, không mặc định 00:00, không lưu đè, placeholder rõ ràng khi NULL) → Task 6 (servlet) + Task 7 Steps 3–4, 6 (JSP/JS).
- **Yêu cầu 2.1–2.4** (OTP bắt buộc khi đổi key PayOS, gửi tới email xác thực, tái sử dụng luồng OTP hiện có, style đồng bộ, audit log có mask) → Tasks 1–3 (backend), Task 7 Steps 7–9 (UI); masking already handled — the audit `details` string only ever contains `fieldsChanged` tags (`CLIENT_ID`/`API_KEY`/`CHECKSUM_KEY`), never the raw values (see Task 2 Step 2's `persistPrepared`), and `PayOSCredentials.toString()` is already redacted so nothing raw can leak via incidental logging.
- **Yêu cầu 3.1–3.5** (IP cho tạo/sửa/xóa mềm/khôi phục CoSo + PayOS: already verified correct in the research phase, no code change needed; manager actions missing IP → HoaDonManagerServlet) → Task 4, 5.
- **UI constraints** (sạch/hiện đại/đồng bộ màu, không xấu hơn) → reused `.adm-otp` class and zinc-900/blue-600 conventions verbatim throughout Task 7.
- **No migration SQL** — confirmed not needed anywhere in this plan (see Global Constraints).
