# Ca Làm Việc (Manager Shift Management) — UI + Logic Hardening Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hardening pass on Manager's "Ca làm việc" feature — close the one real validation gap (employee-declared availability is fetched but never enforced), remove two latent bug risks (silent skip of the facility-hours check, case-sensitive status comparisons at 3 state-machine gates), then clean up the UI (broken Tailwind color classes, native `alert()` popups mixed with the page's own toast system, filters that silently don't apply to the calendar view, an always-open form that clutters the page) without touching the parts that already work well (the week-calendar view, the swap-request approve/reject workflow, and the validation engine's existing 20+ labor-law rules all stay as-is).

**Architecture:** The backend (`CaLamValidationEngine`, `CaLamService`, the swap-request workflow, `CaLamViec_Audit`) is mature and already does the heavy lifting — this is a hardening pass, not a rewrite. `CaLamValidationEngine` currently hardwires concrete DAO implementations in its constructor with no way to inject test doubles; Task 1 adds a package-visible constructor for that (additive, the public no-arg constructor keeps working exactly as before) so Tasks 2–4 can ship with real JUnit tests instead of the fragile non-CI manual harness (`src/main/java/org/example/test/CaLamValidationTest.java`) that currently exists.

**Tech Stack:** Jakarta Servlets, JSP + vanilla JS (fetch-based AJAX, no framework), Tailwind (CDN), Material Symbols Outlined icons, JUnit 5.

## Global Constraints

- Do not touch: the week-calendar rendering algorithm, the swap-request approve/reject business logic, `cloneWeekShifts`/`publishWeekShifts`/`autoScheduleShifts`, or any of the 20+ existing labor-law rules already implemented in `CaLamValidationEngine` (rest hours, daily/weekly/monthly caps, max shifts/day, etc.) — those already work and are explicitly out of scope.
- `CaLamViec_Audit` (the domain-specific shift-lifecycle audit trail) has no IP column and no `HttpServletRequest` in its API by design (it's a pure service-layer object). Per your own instruction ("ưu tiên ghi kèm IP nếu luồng đang có dùng AuditLogService"), no code change is needed here: the only 3 places `QuanLyCaLamManagerServlet` already calls the general `AuditLogService` (create/update/soft-delete a shift) already capture IP automatically via `AuditLogService.log(req, ...)` → `getClientIp(req)`. Task 10 verifies this in the completion report; no task modifies audit/IP plumbing.
- Every status-string constant already exists on `Constants.java` (`SHIFT_STATUS_DRAFT/PUBLISHED/CONFIRMED/CHECKED_IN/CHECKED_OUT/COMPLETED/CANCELLED`) — new/changed comparisons must use those constants, not new string literals.
- New validation rules are additive ValidationItem codes; never remove or renumber an existing rule/error code (JSP/client code and the manual test harness reference codes by string).

---

### Task 1: `CaLamValidationEngine` — add a DI-friendly constructor for testability

**Files:**
- Modify: `src/main/java/org/example/util/CaLamValidationEngine.java`

**Interfaces:**
- Produces: `CaLamValidationEngine(CaLamViecDAO, YeuCauNghiDAO, TaiKhoanDAO, CoSoDAO, CaLamViecAvailabilityDAO)` — package-visible constructor for tests. Public no-arg constructor unchanged in behavior (delegates to the new constructor with real `*DAOImpl()` instances).

- [ ] **Step 1: Add the availability DAO field + DI constructor**

In `src/main/java/org/example/util/CaLamValidationEngine.java`, add these imports after the existing `import org.example.dao.impl.CoSoDAOImpl;` line:

```java
import org.example.dao.CaLamViecAvailabilityDAO;
import org.example.dao.impl.CaLamViecAvailabilityDAOImpl;
import org.example.model.CaLamViecAvailability;
```

Replace the field declarations and constructor (lines 25-35):

```java
    private final CaLamViecDAO caLamViecDAO;
    private final YeuCauNghiDAO yeuCauNghiDAO;
    private final TaiKhoanDAO taiKhoanDAO;
    private final CoSoDAO coSoDAO;

    public CaLamValidationEngine() {
        this.caLamViecDAO = new CaLamViecDAOImpl();
        this.yeuCauNghiDAO = new YeuCauNghiDAOImpl();
        this.taiKhoanDAO = new TaiKhoanDAOImpl();
        this.coSoDAO = new CoSoDAOImpl();
    }
```

with:

```java
    private final CaLamViecDAO caLamViecDAO;
    private final YeuCauNghiDAO yeuCauNghiDAO;
    private final TaiKhoanDAO taiKhoanDAO;
    private final CoSoDAO coSoDAO;
    private final CaLamViecAvailabilityDAO availabilityDAO;

    public CaLamValidationEngine() {
        this(new CaLamViecDAOImpl(), new YeuCauNghiDAOImpl(), new TaiKhoanDAOImpl(), new CoSoDAOImpl(),
                new CaLamViecAvailabilityDAOImpl());
    }

    /** Constructor cho phép inject DAO giả lập trong unit test — không dùng ở code nghiệp vụ. */
    CaLamValidationEngine(CaLamViecDAO caLamViecDAO, YeuCauNghiDAO yeuCauNghiDAO, TaiKhoanDAO taiKhoanDAO,
                          CoSoDAO coSoDAO, CaLamViecAvailabilityDAO availabilityDAO) {
        this.caLamViecDAO = caLamViecDAO;
        this.yeuCauNghiDAO = yeuCauNghiDAO;
        this.taiKhoanDAO = taiKhoanDAO;
        this.coSoDAO = coSoDAO;
        this.availabilityDAO = availabilityDAO;
    }
```

- [ ] **Step 2: Compile**

Run: `mvn -q compile`
Expected: BUILD SUCCESS (nothing else references the old constructor signature since only the no-arg public constructor was public before, and it's preserved).

- [ ] **Step 3: Commit**

```bash
git add src/main/java/org/example/util/CaLamValidationEngine.java
git commit -m "refactor: add DI-friendly constructor to CaLamValidationEngine for unit testing"
```

---

### Task 2: Implement the availability (busy-window) conflict check

**Files:**
- Modify: `src/main/java/org/example/util/CaLamValidationEngine.java`
- Test: `src/test/java/org/example/util/CaLamValidationEngineAvailabilityTest.java`

**Interfaces:**
- Produces: two new `ValidationItem` codes — `AVAILABILITY_UNAVAILABLE_FULLDAY` (blocking, when a busy window has no start/end time = full-day) and `AVAILABILITY_CONFLICT` (blocking, when the shift's time range overlaps an approved busy window).
- Consumes: `CaLamViecAvailabilityDAO.getByAccount(int accountId) -> List<CaLamViecAvailability>` (existing method, already on the interface).

**Business rule:** only an availability row with `trangThai = "Ban"` (busy) **and** `duyetTrangThai = "DaDuyet"` (manager-approved) blocks shift assignment — mirroring the existing approved-leave rule immediately above it in the same method. A pending or rejected busy-declaration must not block (there is no existing UX for a manager to review/approve availability requests inline here, so silently blocking on an un-reviewed self-declaration would be surprising; approved-only matches the leave-conflict precedent exactly).

- [ ] **Step 1: Write the failing test**

Create `src/test/java/org/example/util/CaLamValidationEngineAvailabilityTest.java`:

```java
package org.example.util;

import org.example.dao.CaLamViecAvailabilityDAO;
import org.example.dao.CaLamViecDAO;
import org.example.dao.CoSoDAO;
import org.example.dao.TaiKhoanDAO;
import org.example.dao.YeuCauNghiDAO;
import org.example.model.CaLamViec;
import org.example.model.CaLamViecAvailability;
import org.example.model.TaiKhoan;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class CaLamValidationEngineAvailabilityTest {

    private static final int ACCOUNT_ID = 42;
    private static final LocalDate SHIFT_DATE = LocalDate.now().plusDays(3);

    private CaLamViecAvailabilityDAO availabilityDAO;
    private CaLamValidationEngine engine;

    @BeforeEach
    void setUp() {
        CaLamViecDAO caLamViecDAO = mock(CaLamViecDAO.class);
        when(caLamViecDAO.getShiftsByAccountAndDateRange(anyInt(), org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.any())).thenReturn(new ArrayList<>());

        YeuCauNghiDAO yeuCauNghiDAO = mock(YeuCauNghiDAO.class);
        when(yeuCauNghiDAO.findByAccountIDAndTrangThai(anyInt(), org.mockito.ArgumentMatchers.anyString()))
                .thenReturn(Collections.emptyList());

        TaiKhoan staff = new TaiKhoan();
        staff.setAccountId(ACCOUNT_ID);
        staff.setRoleId(4); // Lễ tân — allowed shift role
        staff.setCoSoId(1);
        TaiKhoanDAO taiKhoanDAO = mock(TaiKhoanDAO.class);
        when(taiKhoanDAO.getAccountById(ACCOUNT_ID)).thenReturn(staff);

        CoSoDAO coSoDAO = mock(CoSoDAO.class);
        when(coSoDAO.getCoSoById(anyInt())).thenReturn(null);

        availabilityDAO = mock(CaLamViecAvailabilityDAO.class);

        engine = new CaLamValidationEngine(caLamViecDAO, yeuCauNghiDAO, taiKhoanDAO, coSoDAO, availabilityDAO);
    }

    private CaLamViecAvailability busyWindow(LocalTime start, LocalTime end, String duyetTrangThai) {
        CaLamViecAvailability a = new CaLamViecAvailability();
        a.setAccountId(ACCOUNT_ID);
        a.setNgay(SHIFT_DATE);
        a.setGioBatDau(start);
        a.setGioKetThuc(end);
        a.setTrangThai("Ban");
        a.setDuyetTrangThai(duyetTrangThai);
        return a;
    }

    @Test
    void approvedBusyWindow_overlappingShift_isBlocked() {
        when(availabilityDAO.getByAccount(ACCOUNT_ID))
                .thenReturn(List.of(busyWindow(LocalTime.of(8, 0), LocalTime.of(12, 0), "DaDuyet")));

        CaLamValidationEngine.ValidationResult result = engine.validateShift(
                ACCOUNT_ID, SHIFT_DATE, LocalTime.of(9, 0), LocalTime.of(17, 0), null);

        assertFalse(result.isValid());
        assertTrue(result.getErrorsItems().stream().anyMatch(e -> "AVAILABILITY_CONFLICT".equals(e.getCode())));
    }

    @Test
    void approvedBusyWindow_nonOverlappingShift_isNotBlocked() {
        when(availabilityDAO.getByAccount(ACCOUNT_ID))
                .thenReturn(List.of(busyWindow(LocalTime.of(6, 0), LocalTime.of(8, 0), "DaDuyet")));

        CaLamValidationEngine.ValidationResult result = engine.validateShift(
                ACCOUNT_ID, SHIFT_DATE, LocalTime.of(9, 0), LocalTime.of(17, 0), null);

        assertTrue(result.getErrorsItems().stream().noneMatch(e -> e.getCode().startsWith("AVAILABILITY_")));
    }

    @Test
    void pendingBusyWindow_doesNotBlock() {
        when(availabilityDAO.getByAccount(ACCOUNT_ID))
                .thenReturn(List.of(busyWindow(LocalTime.of(8, 0), LocalTime.of(18, 0), "ChoDuyet")));

        CaLamValidationEngine.ValidationResult result = engine.validateShift(
                ACCOUNT_ID, SHIFT_DATE, LocalTime.of(9, 0), LocalTime.of(17, 0), null);

        assertTrue(result.getErrorsItems().stream().noneMatch(e -> e.getCode().startsWith("AVAILABILITY_")));
    }

    @Test
    void approvedFullDayBusy_nullTimes_isBlocked() {
        when(availabilityDAO.getByAccount(ACCOUNT_ID))
                .thenReturn(List.of(busyWindow(null, null, "DaDuyet")));

        CaLamValidationEngine.ValidationResult result = engine.validateShift(
                ACCOUNT_ID, SHIFT_DATE, LocalTime.of(9, 0), LocalTime.of(17, 0), null);

        assertFalse(result.isValid());
        assertTrue(result.getErrorsItems().stream()
                .anyMatch(e -> "AVAILABILITY_UNAVAILABLE_FULLDAY".equals(e.getCode())));
    }

    @Test
    void freeAvailability_isIgnored() {
        CaLamViecAvailability free = busyWindow(LocalTime.of(8, 0), LocalTime.of(18, 0), "DaDuyet");
        free.setTrangThai("Ranh");
        when(availabilityDAO.getByAccount(ACCOUNT_ID)).thenReturn(List.of(free));

        CaLamValidationEngine.ValidationResult result = engine.validateShift(
                ACCOUNT_ID, SHIFT_DATE, LocalTime.of(9, 0), LocalTime.of(17, 0), null);

        assertTrue(result.getErrorsItems().stream().noneMatch(e -> e.getCode().startsWith("AVAILABILITY_")));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn -q -Dtest=CaLamValidationEngineAvailabilityTest test`
Expected: FAIL — `approvedBusyWindow_overlappingShift_isBlocked` and `approvedFullDayBusy_nullTimes_isBlocked` fail because no `AVAILABILITY_*` code is ever produced yet.

- [ ] **Step 3: Implement the rule**

In `src/main/java/org/example/util/CaLamValidationEngine.java`, replace the TODO block (lines 449-451):

```java
        // P2-5: TODO — Availability check (nhân viên đăng ký ngày nghỉ / lịch cá nhân).
        // Requires CaLamViecAvailabilityDAO.findByAccountAndDate(accountId, ngayLam).
        // Block nếu nhân viên có đăng ký "Không có sẵn" (UNAVAILABLE) cho ngayLam.
```

with:

```java
        // Rule 25: Xung đột với khung giờ "Bận" nhân viên tự đăng ký, ĐÃ được quản lý duyệt
        // (đăng ký "Bận" chưa duyệt chỉ mang tính tham khảo, không chặn — nhất quán với
        // quy tắc nghỉ phép: PENDING_LEAVE chỉ cảnh báo, LEAVE_FULLDAY mới chặn).
        List<CaLamViecAvailability> busyWindows = availabilityDAO.getByAccount(accountId).stream()
                .filter(a -> ngayLam.equals(a.getNgay()))
                .filter(a -> "Ban".equalsIgnoreCase(a.getTrangThai()))
                .filter(a -> "DaDuyet".equalsIgnoreCase(a.getDuyetTrangThai()))
                .collect(java.util.stream.Collectors.toList());
        for (CaLamViecAvailability busy : busyWindows) {
            if (busy.getGioBatDau() == null || busy.getGioKetThuc() == null) {
                errors.add(new ValidationItem("AVAILABILITY_UNAVAILABLE_FULLDAY",
                        "Xếp ca cho người đã đăng ký không sẵn sàng: Nhân viên đã đăng ký bận cả ngày này (đã được quản lý duyệt).",
                        "ngayLam", busy));
                continue;
            }
            if (shiftsOverlap(ngayLam, gioBatDau, gioKetThuc, ngayLam, busy.getGioBatDau(), busy.getGioKetThuc())) {
                errors.add(new ValidationItem("AVAILABILITY_CONFLICT",
                        String.format("Xếp ca cho người đã đăng ký không sẵn sàng: Nhân viên đã đăng ký bận từ %s đến %s ngày %s (đã được quản lý duyệt).",
                                busy.getGioBatDau(), busy.getGioKetThuc(), ngayLam),
                        "gioBatDau", busy));
            }
        }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mvn -q -Dtest=CaLamValidationEngineAvailabilityTest test`
Expected: PASS (5 tests, 0 failures)

- [ ] **Step 5: Commit**

```bash
git add src/main/java/org/example/util/CaLamValidationEngine.java src/test/java/org/example/util/CaLamValidationEngineAvailabilityTest.java
git commit -m "feat: block shift assignment when employee has an approved 'busy' availability conflict"
```

---

### Task 3: Facility-hours check — surface unresolved `coSoId` instead of silently skipping

**Files:**
- Modify: `src/main/java/org/example/util/CaLamValidationEngine.java`
- Test: `src/test/java/org/example/util/CaLamValidationEngineFacilityHoursTest.java`

**Interfaces:**
- Produces: new `ValidationItem` **warning** code `COSO_UNRESOLVED` (not blocking — see rationale below).

**Rationale for warning, not error:** the facility-hours check today (`if (coSoId != null) { ... }`) silently does nothing when `coSoId` is null, so a shift with no resolvable branch currently gets created without ever being checked against operating hours. Turning this into a hard block would be the "more correct" fix, but several call paths (`cloneWeekShifts`, `autoScheduleShifts`, swap validation) funnel through this same shared method and I could not exhaustively verify none of them ever legitimately hits a null `coSoId` today. A warning makes the gap visible to the manager (closing the "silent" part of "silently skipped") without risking a behavior change that blocks a previously-working flow. Escalate to a blocking error later once you've confirmed in practice that all callers always resolve `coSoId`.

- [ ] **Step 1: Write the failing test**

Create `src/test/java/org/example/util/CaLamValidationEngineFacilityHoursTest.java`:

```java
package org.example.util;

import org.example.dao.CaLamViecAvailabilityDAO;
import org.example.dao.CaLamViecDAO;
import org.example.dao.CoSoDAO;
import org.example.dao.TaiKhoanDAO;
import org.example.dao.YeuCauNghiDAO;
import org.example.model.CoSo;
import org.example.model.TaiKhoan;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Collections;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class CaLamValidationEngineFacilityHoursTest {

    private static final int ACCOUNT_ID = 42;
    private static final int CO_SO_ID = 7;
    private static final LocalDate SHIFT_DATE = LocalDate.now().plusDays(3);

    private CaLamValidationEngine engineWith(CoSo coSo) {
        CaLamViecDAO caLamViecDAO = mock(CaLamViecDAO.class);
        when(caLamViecDAO.getShiftsByAccountAndDateRange(anyInt(), org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.any())).thenReturn(new ArrayList<>());

        YeuCauNghiDAO yeuCauNghiDAO = mock(YeuCauNghiDAO.class);
        when(yeuCauNghiDAO.findByAccountIDAndTrangThai(anyInt(), org.mockito.ArgumentMatchers.anyString()))
                .thenReturn(Collections.emptyList());

        TaiKhoan staff = new TaiKhoan();
        staff.setAccountId(ACCOUNT_ID);
        staff.setRoleId(4);
        staff.setCoSoId(CO_SO_ID);
        TaiKhoanDAO taiKhoanDAO = mock(TaiKhoanDAO.class);
        when(taiKhoanDAO.getAccountById(ACCOUNT_ID)).thenReturn(staff);

        CoSoDAO coSoDAO = mock(CoSoDAO.class);
        when(coSoDAO.getCoSoById(anyInt())).thenReturn(coSo);

        CaLamViecAvailabilityDAO availabilityDAO = mock(CaLamViecAvailabilityDAO.class);
        when(availabilityDAO.getByAccount(anyInt())).thenReturn(Collections.emptyList());

        return new CaLamValidationEngine(caLamViecDAO, yeuCauNghiDAO, taiKhoanDAO, coSoDAO, availabilityDAO);
    }

    @Test
    void nullCoSoId_addsUnresolvedWarning_doesNotBlock() {
        CaLamValidationEngine engine = engineWith(null);

        CaLamValidationEngine.ValidationResult result = engine.validateShift(
                ACCOUNT_ID, SHIFT_DATE, LocalTime.of(9, 0), LocalTime.of(17, 0), 0, null, null);

        assertTrue(result.getWarningsItems().stream().anyMatch(w -> "COSO_UNRESOLVED".equals(w.getCode())));
        assertTrue(result.isValid(), "coSoId=null must warn, not block");
    }

    @Test
    void resolvedCoSoId_withinHours_noUnresolvedWarning() {
        CoSo coSo = new CoSo();
        coSo.setGioMoCua(LocalTime.of(6, 0));
        coSo.setGioDongCua(LocalTime.of(22, 0));
        CaLamValidationEngine engine = engineWith(coSo);

        CaLamValidationEngine.ValidationResult result = engine.validateShift(
                ACCOUNT_ID, SHIFT_DATE, LocalTime.of(9, 0), LocalTime.of(17, 0), 0, null, CO_SO_ID);

        assertTrue(result.getWarningsItems().stream().noneMatch(w -> "COSO_UNRESOLVED".equals(w.getCode())));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mvn -q -Dtest=CaLamValidationEngineFacilityHoursTest test`
Expected: FAIL — `nullCoSoId_addsUnresolvedWarning_doesNotBlock` fails (no `COSO_UNRESOLVED` warning produced yet).

- [ ] **Step 3: Implement the warning**

In `src/main/java/org/example/util/CaLamValidationEngine.java`, replace the Rule 9 block (lines 218-246):

```java
        // Rule 9: Ca nằm trong giờ hoạt động của facility
        if (coSoId != null) {
            CoSo coSo = coSoDAO.getCoSoById(coSoId);
            if (coSo != null) {
```

with:

```java
        // Rule 9: Ca nằm trong giờ hoạt động của facility
        if (coSoId == null) {
            // Trước đây bỏ qua hoàn toàn (không cảnh báo) khi không xác định được cơ sở —
            // nay báo cảnh báo rõ ràng thay vì âm thầm bỏ qua kiểm tra giờ hoạt động.
            warnings.add(new ValidationItem("COSO_UNRESOLVED",
                    "Không xác định được cơ sở của nhân viên nên chưa thể kiểm tra giờ hoạt động — vui lòng kiểm tra thủ công.",
                    "coSoId", null));
        } else {
            CoSo coSo = coSoDAO.getCoSoById(coSoId);
            if (coSo != null) {
```

Then close the newly-added `else` block: find the matching closing braces for the original `if (coSoId != null) { ... }` (the block ending right before `long shiftNet = durationMins - gioNghi;` at line 248) and add one extra closing `}` for the new `else`. Concretely, replace:

```java
                    if (!isWithin) {
                        errors.add(new ValidationItem("FACILITY_HOURS_VIOLATION", 
                            String.format("Ca làm việc phải nằm trong giờ hoạt động của cơ sở (%s - %s).", openTime, closeTime), 
                            "gioBatDau", null));
                    }
                }
            }
        }

        long shiftNet = durationMins - gioNghi;
```

with:

```java
                    if (!isWithin) {
                        errors.add(new ValidationItem("FACILITY_HOURS_VIOLATION", 
                            String.format("Ca làm việc phải nằm trong giờ hoạt động của cơ sở (%s - %s).", openTime, closeTime), 
                            "gioBatDau", null));
                    }
                }
            }
        }

        long shiftNet = durationMins - gioNghi;
```

(unchanged — the brace count already balances: the new `else {` replaces `if (coSo != null) {`'s sibling, and the existing closing `}}}` sequence at the end of the block closes, in order, the `if (openTime != null...)`, the `if (coSo != null)`/`else`, and finally the outer `if/else` on `coSoId`. No extra brace needed since `else` is a 1:1 swap for what was `if (coSoId != null) {`.)

- [ ] **Step 4: Run test to verify it passes**

Run: `mvn -q -Dtest=CaLamValidationEngineFacilityHoursTest test`
Expected: PASS (2 tests, 0 failures)

- [ ] **Step 5: Run the full validation-engine test suite together**

Run: `mvn -q -Dtest=CaLamValidationEngineAvailabilityTest,CaLamValidationEngineFacilityHoursTest test`
Expected: PASS (7 tests total, 0 failures)

- [ ] **Step 6: Commit**

```bash
git add src/main/java/org/example/util/CaLamValidationEngine.java src/test/java/org/example/util/CaLamValidationEngineFacilityHoursTest.java
git commit -m "fix: warn instead of silently skipping facility-hours check when coSoId is unresolved"
```

---

### Task 4: Case-insensitive status checks at the 3 shift state-machine gates

**Files:**
- Modify: `src/main/java/org/example/service/manager/CaLamService.java`

**Rationale:** `confirmShift`, `checkInShift`, `checkOutShift` gate on raw string literals via case-sensitive `.equals()` (`"Published".equals(ca.getTrangThai())`), while `Constants.java`'s own helper methods (`isTerminalStatus`, etc.) and most of `CaLamValidationEngine` already compare status strings with `.equalsIgnoreCase()`. A stray-case value slipping in from anywhere (a manual DB edit, a future code path) would silently make these 3 gates behave as if the shift were in no valid state — the action would just always fail with a generic error rather than the mismatch being visible. Switching to the existing `Constants.SHIFT_STATUS_*` constants + `.equalsIgnoreCase()` matches the codebase's own established defensive pattern.

- [ ] **Step 1: Fix `confirmShift`**

In `src/main/java/org/example/service/manager/CaLamService.java`, replace:

```java
        if (!"Published".equals(ca.getTrangThai())) {
            throw new IllegalArgumentException("Chỉ có thể xác nhận ca làm việc đã được công bố.");
        }

        ca.setTrangThai("Confirmed");
```

with:

```java
        if (!Constants.SHIFT_STATUS_PUBLISHED.equalsIgnoreCase(ca.getTrangThai())) {
            throw new IllegalArgumentException("Chỉ có thể xác nhận ca làm việc đã được công bố.");
        }

        ca.setTrangThai(Constants.SHIFT_STATUS_CONFIRMED);
```

- [ ] **Step 2: Fix `checkInShift`**

Replace:

```java
        if (!"Confirmed".equals(ca.getTrangThai()) && !"Published".equals(ca.getTrangThai())) {
            throw new IllegalArgumentException("Chỉ có thể điểm danh ca làm đã được công bố hoặc xác nhận.");
        }
        if (!ca.getNgayLam().equals(LocalDate.now())) {
            throw new IllegalArgumentException("Chỉ có thể điểm danh ca làm trong ngày hôm nay.");
        }

        ca.setTrangThai("CheckedIn");
```

with:

```java
        if (!Constants.SHIFT_STATUS_CONFIRMED.equalsIgnoreCase(ca.getTrangThai())
                && !Constants.SHIFT_STATUS_PUBLISHED.equalsIgnoreCase(ca.getTrangThai())) {
            throw new IllegalArgumentException("Chỉ có thể điểm danh ca làm đã được công bố hoặc xác nhận.");
        }
        if (!ca.getNgayLam().equals(LocalDate.now())) {
            throw new IllegalArgumentException("Chỉ có thể điểm danh ca làm trong ngày hôm nay.");
        }

        ca.setTrangThai(Constants.SHIFT_STATUS_CHECKED_IN);
```

- [ ] **Step 3: Fix `checkOutShift`**

Replace:

```java
        if (!"CheckedIn".equals(ca.getTrangThai())) {
            throw new IllegalArgumentException("Chỉ có thể kết thúc ca làm khi đang trong trạng thái đã điểm danh.");
        }

        ca.setTrangThai("CheckedOut");
```

with:

```java
        if (!Constants.SHIFT_STATUS_CHECKED_IN.equalsIgnoreCase(ca.getTrangThai())) {
            throw new IllegalArgumentException("Chỉ có thể kết thúc ca làm khi đang trong trạng thái đã điểm danh.");
        }

        ca.setTrangThai(Constants.SHIFT_STATUS_CHECKED_OUT);
```

- [ ] **Step 4: Confirm `Constants` is already imported**

Run: `grep -n "^import org.example.util.Constants;" src/main/java/org/example/service/manager/CaLamService.java`
Expected: one match (the file already uses `Constants.MIN_SHIFT_MINUTES`-style references elsewhere per the codebase survey — if the grep finds nothing, add `import org.example.util.Constants;` alongside the file's other `org.example.util.*` imports).

- [ ] **Step 5: Compile**

Run: `mvn -q compile`
Expected: BUILD SUCCESS

- [ ] **Step 6: Commit**

```bash
git add src/main/java/org/example/service/manager/CaLamService.java
git commit -m "fix: use case-insensitive Constants.SHIFT_STATUS_* comparisons at confirm/check-in/check-out gates"
```

---

### Task 5: Fix non-standard Tailwind color classes in `CaLamViec.jsp`

**Files:**
- Modify: `src/main/webapp/manager/CaLamViec.jsp`

**Rationale:** `purple-650`, `purple-750`, `purple-955` are not valid Tailwind shades (the default palette only defines 50/100/.../900/950) and the page's Tailwind config doesn't extend the palette to add them — these classes generate no CSS rule at all and silently fall back to inherited text color, which is very likely a contributor to "cảm giác rối" (text that should be branded purple instead renders as default black/inherited color in several places). This is a mechanical, safe fix: map each non-standard shade to its nearest real one.

- [ ] **Step 1: Replace all 9 occurrences**

Run this find-and-replace across the file (verify each replacement with `grep -n` before and after):

```bash
sed -i 's/purple-955/purple-950/g; s/purple-750/purple-700/g; s/purple-650/purple-600/g' src/main/webapp/manager/CaLamViec.jsp
```

- [ ] **Step 2: Verify no occurrences remain and nothing else was touched**

Run: `grep -n "purple-650\|purple-750\|purple-955" src/main/webapp/manager/CaLamViec.jsp`
Expected: no output (0 matches).

Run: `git diff --stat src/main/webapp/manager/CaLamViec.jsp`
Expected: exactly 9 lines changed (matching the 9 occurrences found during research), no other content altered.

- [ ] **Step 3: Commit**

```bash
git add src/main/webapp/manager/CaLamViec.jsp
git commit -m "fix: replace non-standard Tailwind purple-650/750/955 classes with valid shades in CaLamViec.jsp"
```

---

### Task 6: Replace native `alert()` popups with the page's existing inline error panel

**Files:**
- Modify: `src/main/webapp/manager/CaLamViec.jsp`

**Rationale:** the page already has a polished inline error/warning box (`#shiftAlertBox`, populated by `runRealtimeValidation()`) plus a toast system (`showToast(type, message)`) — both are used consistently everywhere else on the page. The 8 native `alert()` calls inside `handleInlineShiftSubmit()` (pre-submit field checks) are the one place still using a jarring native browser dialog, breaking the otherwise-consistent UX. This task adds one small helper and swaps every `alert(...)` call for it — no validation logic changes, purely how the message is displayed.

- [ ] **Step 1: Add a `showFieldError(msg)` helper**

Read the JS section around `handleInlineShiftSubmit()` first (`grep -n "function handleInlineShiftSubmit\|function runRealtimeValidation" src/main/webapp/manager/CaLamViec.jsp`) to find the exact insertion point — add the helper immediately before the `handleInlineShiftSubmit` function definition:

```js
  // Hiển thị lỗi kiểm tra trường nhập ngay trong form thay vì alert() — nhất quán với
  // #shiftAlertBox đã dùng cho lỗi xung đột ca (runRealtimeValidation).
  function showFieldError(msg) {
    const box = document.getElementById('shiftAlertBox');
    if (!box) { alert(msg); return; }
    box.classList.remove('hidden');
    box.innerHTML = `<div class="p-3 rounded-xl bg-red-50 border border-red-200 text-red-700 text-sm font-semibold flex items-center gap-2">
      <span class="material-symbols-outlined text-[18px]">error</span>${msg}
    </div>`;
    box.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }
```

- [ ] **Step 2: Replace each `alert(...)` call site**

Within `handleInlineShiftSubmit()`, replace each of the following (matched by their exact message text, confirmed unique per earlier `grep -n "alert("` output):

```js
alert("Đang có lỗi xung đột ca hoặc dữ liệu không hợp lệ. Vui lòng kiểm tra lại!");
```
→
```js
showFieldError("Đang có lỗi xung đột ca hoặc dữ liệu không hợp lệ. Vui lòng kiểm tra lại!");
```

```js
alert("Vui lòng chọn nhân viên!");
```
→
```js
showFieldError("Vui lòng chọn nhân viên!");
```

```js
alert("Vui lòng chọn mẫu ca hệ thống!");
```
→
```js
showFieldError("Vui lòng chọn mẫu ca hệ thống!");
```

```js
alert("Lý do tùy chỉnh giờ làm không được để trống.");
```
→
```js
showFieldError("Lý do tùy chỉnh giờ làm không được để trống.");
```

```js
alert("Lý do tùy chỉnh giờ làm không được vượt quá 255 ký tự.");
```
→
```js
showFieldError("Lý do tùy chỉnh giờ làm không được vượt quá 255 ký tự.");
```

```js
alert("Ca qua ngày chưa được hỗ trợ.");
```
→
```js
showFieldError("Ca qua ngày chưa được hỗ trợ.");
```

```js
alert("Vui lòng nhập giờ bắt đầu và giờ kết thúc!");
```
→
```js
showFieldError("Vui lòng nhập giờ bắt đầu và giờ kết thúc!");
```

```js
alert("Vui lòng chọn ít nhất một ngày làm việc trong tuần!");
```
→
```js
showFieldError("Vui lòng chọn ít nhất một ngày làm việc trong tuần!");
```

- [ ] **Step 3: Verify no `alert(` remains in `handleInlineShiftSubmit`**

Run: `grep -n "alert(" src/main/webapp/manager/CaLamViec.jsp`
Expected: no output (0 matches) — the helper's own internal fallback `alert(msg)` was removed too since Step 1's version doesn't need it once `#shiftAlertBox` is confirmed to exist on this page; if you kept the defensive fallback from Step 1, one match is expected and correct (defensive-only, never hit in practice since `#shiftAlertBox` exists in the form markup already).

- [ ] **Step 4: Manual check**

Open `/manager/ca-lam`, click "Lưu ca làm việc" with the employee field empty — confirm a red inline box appears above the submit button (not a browser `alert()` dialog) with the message, and that it scrolls into view.

- [ ] **Step 5: Commit**

```bash
git add src/main/webapp/manager/CaLamViec.jsp
git commit -m "fix: replace native alert() popups with the existing inline error panel in shift form"
```

---

### Task 7: Make table filters (search/role/date) also apply to the calendar view

**Files:**
- Modify: `src/main/webapp/manager/CaLamViec.jsp`

**Rationale:** `filterShifts()` filters the in-memory `shiftList` and calls `renderTable(filtered)`, but `renderCalendar()` always iterates the full, unfiltered `shiftList` directly — so a manager who searches for an employee or picks a date range sees it apply in table view but the calendar view silently ignores it. This is a real, confusing inconsistency and a direct cause of "cảm giác rối" when switching between the two views.

- [ ] **Step 1: Locate the exact current wiring**

Run: `grep -n "function filterShifts\|function renderCalendar\|renderTable(filtered)\|renderCalendar()" src/main/webapp/manager/CaLamViec.jsp`

Read the full `filterShifts()` function and the full `renderCalendar()` function bodies at the reported line numbers before editing (both were previously read in full during research at `:721-754` and `:1750-1832` respectively — re-read them now since exact line numbers may have shifted slightly after Tasks 5-6's edits).

- [ ] **Step 2: Extract the filtering predicate into a reusable function**

In `filterShifts()`, the per-row filter logic (name/role/date match) currently lives inline inside the `rows.forEach(...)` loop over DOM rows. Refactor so the same predicate can run over the raw `shiftList` array (not DOM rows) for calendar use. Add a new function `getFilteredShiftList()` right before `filterShifts()`:

```js
  // Áp dụng đúng tiêu chí lọc (tên/vai trò/ngày) hiện có của filterShifts() lên mảng
  // dữ liệu gốc — dùng chung cho cả renderTable() (qua DOM) và renderCalendar() (qua mảng),
  // để 2 chế độ xem không còn lệch kết quả lọc với nhau.
  function getFilteredShiftList() {
    const searchValue = (document.getElementById('searchName').value || '').toLowerCase().trim();
    const roleFilter = document.getElementById('filterRole').value;
    const dateOpt = document.getElementById('filterDateOpt').value;
    const startDate = document.getElementById('filterStartDate')?.value;
    const endDate = document.getElementById('filterEndDate')?.value;
    const today = new Date(); today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today); tomorrow.setDate(tomorrow.getDate() + 1);

    return shiftList.filter(s => {
      const staffName = (s.staffName || s.tenNhanVien || '').toLowerCase();
      const staffUsername = (s.username || '').toLowerCase();
      if (searchValue && !staffName.includes(searchValue) && !staffUsername.includes(searchValue)) return false;
      if (roleFilter && String(s.viTri) !== roleFilter && String(s.roleId) !== roleFilter) return false;

      if (dateOpt !== 'all') {
        const shiftDate = new Date(s.ngayLam); shiftDate.setHours(0, 0, 0, 0);
        if (dateOpt === 'today' && shiftDate.getTime() !== today.getTime()) return false;
        if (dateOpt === 'tomorrow' && shiftDate.getTime() !== tomorrow.getTime()) return false;
        if (dateOpt === 'custom' && startDate && endDate) {
          const s0 = new Date(startDate); s0.setHours(0, 0, 0, 0);
          const e0 = new Date(endDate); e0.setHours(23, 59, 59, 999);
          if (shiftDate < s0 || shiftDate > e0) return false;
        }
      }
      return true;
    });
  }
```

(The exact field names read off each `s` — `staffName`/`tenNhanVien`, `viTri`/`roleId`, `ngayLam` — must match whatever `filterShifts()`'s existing DOM-based version actually reads; when implementing, cross-check against the real `filterShifts()` body from Step 1 and adjust field names to match exactly rather than guessing, since the JSON shape returned by the `format=json` endpoint is the authority here, not this plan.)

- [ ] **Step 3: Call the filtered list from `renderCalendar()`**

At the top of `renderCalendar()`, change whatever currently reads the full `shiftList` (e.g. `shiftList.forEach(...)` or similar) to read `getFilteredShiftList()` instead. Keep the rest of the calendar-rendering logic (week math, day-column grouping, block styling) untouched.

- [ ] **Step 4: Re-render the calendar when filters change**

Find where `filterShifts()` currently only calls `renderTable(filtered)` and add a call to also refresh the calendar when it's the active view:

```js
    if (currentView === 'calendar') {
      renderCalendar();
    }
```

(Match `currentView`'s actual variable name from the view-toggle code — confirm it during Step 1's re-read; the view-toggle function name from research is `switchScheduleView('calendar'|'table')`, so the state variable it sets should be reused here rather than introduced fresh.)

- [ ] **Step 5: Manual check**

Open `/manager/ca-lam`, switch to calendar view, type a search term or pick "Hôm nay" in the date filter — confirm the calendar grid now only shows matching shifts, matching what table view would show for the same filter.

- [ ] **Step 6: Commit**

```bash
git add src/main/webapp/manager/CaLamViec.jsp
git commit -m "fix: apply search/role/date filters to calendar view, not just table view"
```

---

### Task 8: Collapse the always-open shift form into a toggleable panel

**Files:**
- Modify: `src/main/webapp/manager/CaLamViec.jsp`

**Rationale:** the "Phân ca làm việc mới" form is always rendered open, permanently occupying significant vertical space above the shift list even when the manager isn't adding/editing anything — a direct contributor to "cảm giác rối, khó rà soát" since the list (the thing being reviewed most often) is pushed below a large form. Converting to a true modal/dialog is higher-risk (backdrop/z-index/focus-trap concerns layered onto 2300+ lines of existing JS) for a page with no such component today; instead, collapse the form to hidden-by-default with a clear "+ Phân ca mới" button to open it, reusing 100% of the existing form markup, fields, and JS (`resetForm()`, `editShift()`, `handleInlineShiftSubmit()`) unchanged — only visibility toggling is added.

- [ ] **Step 1: Wrap the form card in a collapsible container**

Read the exact form card wrapper markup first: `grep -n "id=\"inlineShiftForm\"" src/main/webapp/manager/CaLamViec.jsp` and read a few lines of context around its opening `<div>`/`<form>` tag and its title heading (`Phân ca làm việc mới` / `Chỉnh sửa ca làm việc` per research at `:65-180`).

Add a `hidden` class to the form card's outermost wrapper element (whatever div directly wraps `#inlineShiftForm`), and add a new "toggle" button in its place — a compact bar shown when the form is collapsed:

```html
<div id="shiftFormToggleBar" class="flex items-center justify-between bg-white rounded-2xl border border-purple-100 px-5 py-3.5 shadow-sm">
  <div class="flex items-center gap-2 text-sm font-semibold text-purple-900">
    <span class="material-symbols-outlined text-[18px] text-purple-600">calendar_add_on</span>
    Phân công ca làm việc
  </div>
  <button type="button" onclick="openShiftFormPanel()"
          class="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-purple-600 hover:bg-purple-700 text-white text-sm font-bold transition-all">
    <span class="material-symbols-outlined text-[18px]">add</span>Phân ca mới
  </button>
</div>
```

Place this bar immediately before the (now-hidden-by-default) form card wrapper.

- [ ] **Step 2: Add open/close JS functions**

Add near `resetForm()`:

```js
  function openShiftFormPanel() {
    resetForm();
    document.getElementById('shiftFormToggleBar').classList.add('hidden');
    document.getElementById('inlineShiftFormWrapper').classList.remove('hidden');
    document.getElementById('inlineShiftFormWrapper').scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  function closeShiftFormPanel() {
    document.getElementById('inlineShiftFormWrapper').classList.add('hidden');
    document.getElementById('shiftFormToggleBar').classList.remove('hidden');
  }
```

(Use whatever the actual wrapper element's `id` is from Step 1 — if it doesn't already have one, add `id="inlineShiftFormWrapper"` to it as part of this same edit.)

- [ ] **Step 3: Wire the panel to open automatically when editing an existing shift**

`editShift(id)` (research: `:1256-1318`) already populates the form fields — add the panel-opening calls at its start/end so clicking "Sửa" on a shift in the list still works exactly as before, just now also revealing the (currently-hidden) form:

At the very start of `editShift(id)`, before its existing field-population logic, add:
```js
    document.getElementById('shiftFormToggleBar').classList.add('hidden');
    document.getElementById('inlineShiftFormWrapper').classList.remove('hidden');
```

- [ ] **Step 4: Add a "Hủy" close action, and re-collapse after a successful save**

In the form's existing cancel/reset button (if present) or add one next to the submit button:
```html
<button type="button" onclick="closeShiftFormPanel(); resetForm();" class="btn-ghost text-sm">Hủy</button>
```

In `handleInlineShiftSubmit()`'s success path (where it currently shows `#successResultBanner` and/or a toast after a successful save — locate via `grep -n "successResultBanner" src/main/webapp/manager/CaLamViec.jsp`), add a call to `closeShiftFormPanel()` right after the success banner/toast is triggered, so the form collapses back down once the manager is done, decluttering the page again automatically.

- [ ] **Step 5: Manual check**

Open `/manager/ca-lam` — confirm the page loads with the form collapsed (just the toggle bar visible) and the shift list immediately visible without scrolling past a large form. Click "+ Phân ca mới" — confirm the form opens with fields reset. Click "Sửa" on an existing shift in the list — confirm the form opens pre-filled with that shift's data. Save a shift successfully — confirm the form collapses back to the toggle bar and the list refreshes.

- [ ] **Step 6: Commit**

```bash
git add src/main/webapp/manager/CaLamViec.jsp
git commit -m "feat: collapse the always-open shift form into a toggleable panel to declutter the page"
```

---

### Task 9: Surface swap-request history using already-fetched audit data

**Files:**
- Modify: `src/main/webapp/manager/CaLamViec.jsp`

**Rationale:** the `format=json` endpoint already returns an `audits` array (`CaLamViecAudit` rows, including `SWAP`/`SWAP_REJECT` entries with `thoiGian`/`nguoiThucHien`/`lyDo`), but research confirms this data is fetched and never rendered anywhere in the JSP — "hiển thị lịch sử thao tác" for the swap flow currently has no UI at all. This adds a compact, read-only recent-activity list to the existing swap-requests panel, using data already on the page (no new endpoint, no new servlet code).

- [ ] **Step 1: Locate the swap panel and existing audit data variable**

Run: `grep -n "renderSwapRequests\|data.audits\|_swapList\|loadScheduleData" src/main/webapp/manager/CaLamViec.jsp` and read the full `renderSwapRequests()` function (research: `:2199-2269`) and `loadScheduleData()` (research: `:1432-1452`, which is where `data.audits` is currently received but apparently discarded/unused — confirm exactly what happens to it before editing).

- [ ] **Step 2: Keep a module-level reference to swap-related audit entries**

In `loadScheduleData()`, alongside wherever it currently assigns `_swapList` from `data.swaps`, add:
```js
    window._swapAuditLog = (data.audits || []).filter(a => a.thaoTac === 'SWAP' || a.thaoTac === 'SWAP_REJECT');
```

- [ ] **Step 3: Render a compact history list below the swap-requests table**

Add a new collapsible section immediately after the swap-requests `<table>` in the panel markup (research: swap panel at `:457-475`):

```html
<div class="mt-3">
  <button type="button" onclick="document.getElementById('swapHistoryList').classList.toggle('hidden')"
          class="text-xs font-semibold text-purple-600 hover:text-purple-800 flex items-center gap-1">
    <span class="material-symbols-outlined text-[16px]">history</span>Lịch sử đổi ca gần đây
  </button>
  <div id="swapHistoryList" class="hidden mt-2 flex flex-col gap-1.5 text-xs text-zinc-600"></div>
</div>
```

- [ ] **Step 4: Populate it in `renderSwapRequests()`**

At the end of `renderSwapRequests()`, add:
```js
    const historyEl = document.getElementById('swapHistoryList');
    if (historyEl) {
      const recent = (window._swapAuditLog || []).slice(-10).reverse();
      historyEl.innerHTML = recent.length === 0
        ? '<span class="text-zinc-400 italic">Chưa có lịch sử đổi ca.</span>'
        : recent.map(a => `
            <div class="flex items-center justify-between px-3 py-2 rounded-lg bg-zinc-50 border border-zinc-100">
              <span>${a.thaoTac === 'SWAP' ? '✅ Duyệt đổi ca' : '❌ Từ chối đổi ca'} — ${a.tenNguoiThucHien || 'Quản lý'}</span>
              <span class="text-zinc-400">${a.thoiGian ? new Date(a.thoiGian).toLocaleString('vi-VN') : ''}</span>
            </div>`).join('');
    }
```

- [ ] **Step 5: Manual check**

Open `/manager/ca-lam`, approve or reject a pending swap request, then click "Lịch sử đổi ca gần đây" — confirm the just-completed action shows up in the list with a timestamp and the manager's name.

- [ ] **Step 6: Commit**

```bash
git add src/main/webapp/manager/CaLamViec.jsp
git commit -m "feat: surface swap-request approval/rejection history in the swap panel"
```

---

### Task 10: Full verification pass

**Files:** none (verification only)

- [ ] **Step 1: Full test suite**

Run: `mvn -q test -Dtest='!RunMigrationTest,!ResetSessionStateTest,!FindActiveCheckinsTest,!ListTablesTest,!VerifyCoSoConfigTest,!FindTestAccountsTest,!ResetTestPasswordTest'`
Expected: BUILD SUCCESS, all tests pass including the 7 new `CaLamValidationEngine*Test` cases from Tasks 2–3.

- [ ] **Step 2: Full compile/package**

Run: `mvn -q package -DskipTests`
Expected: BUILD SUCCESS.

- [ ] **Step 3: Manual regression walkthrough on `/manager/ca-lam`**

1. Create a shift for an employee who has an **approved** "Bận" (busy) availability window overlapping the requested time — confirm it's now blocked with a clear message (Task 2).
2. Create/edit a shift normally (no conflicts) — confirm it still saves successfully exactly as before (Tasks 1–4 didn't change the happy path).
3. Approve and reject a swap request — confirm both still work, and confirm the new "Lịch sử đổi ca gần đây" list picks them up (Task 9).
4. Confirm the page heading and "Thành công" banner render in visible purple, not default black (Task 5).
5. Trigger a field-validation error (e.g. submit with no employee selected) — confirm it shows in the red inline box, not a native `alert()` (Task 6).
6. Switch to calendar view and apply a search/date filter — confirm the calendar grid reflects the filter (Task 7).
7. Confirm the page loads with the shift form collapsed, and that "+ Phân ca mới" / "Sửa" both correctly open it pre-filled or blank as appropriate (Task 8).

- [ ] **Step 4: No commit needed — this task is verification-only.**

---

## Self-review notes (spec coverage)

- **Yêu cầu 1** (giao diện dễ dùng theo ngày/tuần, dễ xem ai ở ca nào, dễ thêm/sửa/xóa/đổi ca) → the week-calendar view and swap panel already satisfy this and are explicitly preserved untouched; Task 8 removes the main remaining clutter source (always-open form).
- **Yêu cầu 2** (bộ lọc ngày/nhân viên/trạng thái; danh sách/lịch tuần; modal/form rõ ràng; khu vực đổi ca) → filters already exist and Task 7 fixes their calendar-view gap; "modal/form rõ ràng" addressed via Task 8's collapse-by-default panel rather than a full dialog rebuild (lower risk, same declutter benefit); swap-request area already exists, untouched.
- **Yêu cầu 3** (không trùng ca / ngoài giờ hoạt động / xung đột nghỉ phép-availability / validate chặt / báo lỗi rõ ràng) → overlap and operating-hours and leave-conflict rules already existed and are preserved; Task 2 closes the one real gap (availability); Task 3 removes a silent-skip risk; Task 6 fixes error clarity (no more native `alert()`).
- **Yêu cầu 4** (đổi ca: manager duyệt/từ chối rõ ràng; lịch sử thao tác) → approve/reject already existed and is untouched; Task 9 adds the missing history view.
- **Yêu cầu 5** (audit/IP) → verified already satisfied for the in-scope (AuditLogService-using) call sites; documented in Global Constraints, no code task needed.
- **Yêu cầu 6** ("production-like", không chỉ đổi giao diện) → Tasks 1–4 are pure backend logic/testing work with real JUnit coverage, not cosmetic.
- **No placeholder steps**; **no migration SQL needed** — no schema change anywhere in this plan.
