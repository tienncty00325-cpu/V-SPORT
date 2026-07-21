# Customer Profile Full-Screen Page — Design

Date: 2026-07-18
Status: Approved

## Problem

The customer sidebar's profile card (avatar/name/chevron) currently opens an in-page
JS-toggled section (`data-section="thongtin"`) inside `/customer/tai-khoan`. The
target design (reference: https://datlich.alobo.vn/userProfile, screenshots
provided) is a standalone, full-screen profile page with a cover hero, overlay
profile card, tab switcher (Tổng quan / Liên kết), and richer personalization
fields that don't exist in the current sidebar section or the database.

## Goals

- New route `/customer/ho-so` renders a standalone profile page: no account
  sidebar, no `#thongtin` anchor.
- Profile card in the sidebar (avatar, name, chevron, whole row) navigates to
  this route via context-path-relative links — no hard-coded `/Backend_java`.
- Page shows cover hero, overlay profile card (avatar/name/email/phone/birth
  year/gender), tab switcher, physical info, special note, personalization
  (favorite location/sport+level/goal/frequency), and a real "Liên kết" tab
  backed by `TeamService.getMyTeams()`.
- All data comes from the database. Missing DB fields render "-", never "null",
  never a fabricated value.
- New DB columns ship as an idempotent migration script the user runs manually.
  Page must not break if it hasn't run yet.
- Existing working flows (avatar upload, base-info edit incl. email OTP
  verification, password change) keep working — logic is relocated, not
  rewritten from scratch, to avoid regressions.

## Non-goals

- No changes to RoleID, booking, map, or PayOS flows.
- No admin/manager/staff profile changes.
- No automatic execution of any SQL migration.
- No git commit.

## Key existing-code findings that shape this design

- `TaiKhoan.java` is a JPA `@Entity` mapped to `Accounts`, and
  `TaiKhoanDAOImpl.updateAccount()` uses `EntityManager.merge()` — a full-entity
  update. Adding `@Column` fields for not-yet-migrated columns would break
  `updateAccount()` **everywhere in the app** (admin/manager/staff/customer)
  until the migration runs, because Hibernate would include the missing
  columns in its generated UPDATE. `hibernate.hbm2ddl.auto=none`, so schema is
  never auto-created — confirmed safe from that angle, but the merge risk
  remains.
  **Decision:** new profile fields are read/written through a brand-new,
  plain-JDBC `CustomerProfileDAO` (same style as `TeamDAOImpl`), never added to
  the `TaiKhoan` JPA entity. This fully isolates the new columns from the
  existing JPA-based update paths.
- The sidebar's `data-section="thongtin"` section
  (`TaiKhoan.jsp:578-679` + associated JS `enterEditMode`/`saveProfileInfo`/
  `syncProfileUi`/OTP handlers/avatar-input listener, roughly lines 780-1050)
  is a fully working, self-contained edit form: view/edit toggle, PATCH via
  `/account/update-profile` (`updateInfo`/`verifyEmailOtp`/`updateAvatar`
  actions), with a working email-change OTP flow using a shared `emailOtpModal`
  and shared `openModal`/`closeModal`/toast helpers already present in
  `TaiKhoan.jsp`.
  **Decision:** relocate this block (markup + its own JS functions) into
  `HoSo.jsp` verbatim, adapting only page-level plumbing (no more
  `hidden`/`data-section` toggle — it's a real page section now; no sidebar
  elements to sync, so `syncProfileUi` drops the `accSummaryName`/
  `accSummaryEmail` sidebar-sync lines). The backend contract
  (`/account/update-profile`) is untouched. Delete the now-dead block and its
  JS from `TaiKhoan.jsp`.
- `LoaiSanDAO.getAllMonTheThao()` already returns real `MonTheThao` rows — used
  for the favorite-sport dropdown, no hardcoded list.
- `TeamService.getMyTeams(accountId)` (from the just-fixed Team module) already
  returns real team membership data — used verbatim for the "Liên kết" tab.
- Existing upload validation pattern (magic-byte sniffing, UUID filenames, MIME
  allowlist, size limits) lives in `DoiNhomServlet.handleImageUpload` and
  `UpdateProfileServlet.saveAvatarFile`. Cover upload reuses the same
  validation logic (duplicated as a small private method scoped to the new
  servlet, following the same pattern already used per-servlet in this
  codebase rather than introducing a new shared utility mid-task).

## Data model changes

New file: `sql/migration_customer_profile.sql` — idempotent (guards via
`COL_LENGTH`/`OBJECT_ID`/`sys.foreign_keys`, `SET XACT_ABORT ON`, try/catch
transaction, matching the style of `migration_team_management.sql`). Adds
nullable columns to `dbo.Accounts`:

| Column | Type | Constraint |
|---|---|---|
| `CoverImageUrl` | NVARCHAR(500) NULL | — |
| `ChieuCaoCm` | INT NULL | CHECK (ChieuCaoCm IS NULL OR ChieuCaoCm BETWEEN 50 AND 260) |
| `CanNangKg` | INT NULL | CHECK (CanNangKg IS NULL OR CanNangKg BETWEEN 20 AND 300) |
| `GhiChuDacBiet` | NVARCHAR(500) NULL | — |
| `ViTriYeuThich` | NVARCHAR(255) NULL | — |
| `MonTheThaoYeuThichID` | INT NULL | FK → dbo.MonTheThao(MonTheThaoID) |
| `TrinhDoChoi` | VARCHAR(30) NULL | CHECK IN ('Mới chơi','Cơ bản','Trung bình','Khá','Nâng cao') |
| `MucTieuChoi` | NVARCHAR(255) NULL | — |
| `TanSuatChoi` | VARCHAR(30) NULL | CHECK IN ('1 lần/tuần','2-3 lần/tuần','4+ lần/tuần','Không cố định') |

No DROP, no data loss, no default execution — file is handed to the user to
run manually. A companion `sql/verify_customer_profile.sql` (read-only,
mirrors the Team module's verify script style) checks `DB_NAME()`, column
existence/types, FK, and row counts.

## New Java files

- `org.example.dto.CustomerProfileExtraDTO` — the 9 new fields plus resolved
  `sportName` (joined from `MonTheThao`).
- `org.example.dao.CustomerProfileDAO` (interface) +
  `org.example.dao.impl.CustomerProfileDAOImpl` — plain JDBC via `DBUtil`,
  `dbo.`-qualified queries, `try-with-resources`. Methods:
  - `CustomerProfileExtraDTO getExtra(int accountId)`
  - `boolean updatePhysical(int accountId, Integer heightCm, Integer weightKg)`
  - `boolean updateNote(int accountId, String note)`
  - `boolean updatePersonalization(int accountId, String location, Integer sportId, String level, String goal, String frequency)`
  - `boolean updateCoverPath(int accountId, String coverPath)`

  If the migration hasn't run, `SELECT`/`UPDATE` against the new columns throws
  `SQLServerException: Invalid column name`. The servlet catches this
  specifically at the call site, logs it once via the app logger, and treats
  the extra-profile block as "unavailable" (renders `-` / hides edit affordances
  for that block) — not a silent app-wide empty-list swallow, and not a raw
  stack trace to the browser (relies on the just-added global `Error.jsp` /
  `web.xml` `<error-page>` for anything unexpected elsewhere on the page).

- `org.example.controller.customer.CustomerProfileServlet` — routes:
  - `GET /customer/ho-so` — renders `HoSo.jsp`
  - `POST /customer/ho-so/cap-nhat-the-chat` — height/weight
  - `POST /customer/ho-so/cap-nhat-ghi-chu` — special note
  - `POST /customer/ho-so/cap-nhat-ca-nhan-hoa` — location/sport/level/goal/frequency
  - `POST /customer/ho-so/doi-cover` — cover image upload (multipart, reused
    validation pattern)

  Base-info edits (name/email/phone/birthday/gender/avatar) keep posting to the
  existing `/account/update-profile` servlet — unchanged.

## Page structure (`HoSo.jsp`)

Standalone page: `<jsp:include page="/common/head.jsp">` +
`<jsp:include page="/customer/common/vsport-theme.jsp">`, own `<style>` scoped
under `.customer-profile-page` / `.customer-profile-hero` /
`.customer-profile-card` / `.customer-profile-tabs` / `.customer-profile-section`
— no bare `.card`/`button`/`input` selectors that could leak into other pages.

1. **Cover hero** — full-width, ~170px desktop / ~200px mobile, V-SPORT
   gradient (`--vs-primary-900` → `--vs-cyan-500`) as default, or
   `account`'s cover image if set. Back button (→ `/customer/tai-khoan`,
   real link not `history.back()`) and camera button (opens file picker,
   posts to `doi-cover`) as ~36px translucent circles top-left/top-right.
2. **Overlay profile card** — avatar (with camera overlay button, separate
   file input from cover), name (real `fullName`/`username` fallback, no
   fabricated verified badge), email pill (ellipsis on overflow), phone/year/
   gender as three evenly spaced fields — a "-" placeholder for any missing
   value. "Chỉnh sửa" opens the relocated edit form (from `TaiKhoan.jsp`)
   in a modal/inline panel, backed by the existing `/account/update-profile`
   OTP flow.
3. **Tab switcher** — "Tổng quan" / "Liên kết", client-side toggle (no
   reload), V-SPORT colored bar, active tab white background.
4. **Tổng quan tab**:
   - Thông tin thể chất: height/cm, weight/kg, "-" if null, edit icon opens a
     small modal → `cap-nhat-the-chat`, validates positive integers in range.
   - Ghi chú đặc biệt: label + value/placeholder row, edit icon opens inline
     editor → `cap-nhat-ghi-chu`.
   - Cá nhân hóa: 4 rows (vị trí yêu thích, môn thể thao + trình độ, mục tiêu,
     tần suất chơi) with icons, edit icon opens a modal with a real
     `<select>` sourced from `LoaiSanDAO.getAllMonTheThao()` and a fixed
     level/frequency enum (documented above) → `cap-nhat-ca-nhan-hoa`.
5. **Liên kết tab**: renders `TeamService.getMyTeams(accountId)` as a simple
   list (team name, role, member count) with an empty state (icon + short
   text, no "coming soon", no fake data) if empty.

Loading spinners (V-SPORT colored) appear only during actual upload/save
network calls, always cleared in a `finally`-equivalent (`.then().catch()`
pair restoring button state), matching the pattern already used in
`TaiKhoan.jsp`'s `saveProfileInfo`.

## Sidebar changes (`TaiKhoan.jsp`)

- Profile card (`side-profile-row`, line ~391) becomes
  `<a href="${pageContext.request.contextPath}/customer/ho-so" class="side-profile-row" aria-label="Mở hồ sơ cá nhân">` —
  whole row, avatar, and name are all inside this single anchor (no nested
  `<a>` tags), chevron is purely decorative inside it. Native focus-visible
  and Enter/Space handling come for free from using a real `<a>`.
- Sidebar menu item "Thông tin cá nhân" (line ~461) becomes the same kind of
  link.
- The `data-section="thongtin"` `<section>` block (lines 578-679) and its
  associated JS (`enterEditMode`, `saveProfileInfo`, `syncProfileUi`, OTP
  handlers tied to that section, the `accAvatarInput` listener, the
  `personalInfoCard: 'thongtin'` map entry) are deleted — fully relocated to
  `HoSo.jsp`. Nothing else in `TaiKhoan.jsp` references these IDs (verified by
  grep before this decision).
- Password-change modal, toast system, and other `TaiKhoan.jsp` sections are
  untouched.

## Responsive behavior

- Desktop ≥1200px: profile card horizontal, three info fields evenly spaced,
  full-width content card, no sidebar.
- Tablet 768-1199px: profile card may wrap to two rows without overlapping
  text; tabs remain full width.
- Mobile <768px: hero ~200px, profile card switches to vertical layout
  (avatar+name first, phone/year/gender as a grid below), tabs full width,
  edit surfaces become bottom sheets, no horizontal scroll.

## Testing

- `mvn clean compile`, `mvn test-compile`, `mvn package -DskipTests`.
- Manual runtime walkthrough (documented in the report, not assumed): login,
  click each of the four profile-card entry points (row background, avatar,
  name, chevron), confirm same route; back button; direct URL refresh; logout
  then reload URL; avatar upload; cover upload; physical-info edit;
  personalization edit; both tabs; missing-data rendering; desktop/tablet/
  mobile viewport check.

## Out of scope confirmations

RoleID, booking, map (`BanDo.jsp`/`MapApiServlet`), and PayOS flows are not
touched by this change. No SQL is executed automatically. No git commit is
made as part of this work.
