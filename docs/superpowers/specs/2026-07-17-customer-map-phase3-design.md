# Phase 3 — Customer Map (`/customer/ban-do`) Design

Status: proposed, pending user review
Branch: `feature/customer-mobile-map-redesign`
Depends on (already merged/in-branch, DO NOT rebuild): customer portal redesign
(dashboard, reputation UI, booking history, court marketplace, matchmaking UI,
mobile bottom nav, `vsport-theme.jsp`).

## 1. Problem

Customers cannot currently discover facilities geographically. The bottom nav
already has a "Bản đồ" entry but it is a documented placeholder
(`bottom-nav.jsp` lines 8-11, `TODO(P3): point Ban do at /customer/ban-do`)
that shows a "sắp ra mắt" toast. Desktop has no map entry at all. `CoSo` has
had `ViDo`/`KinhDo` (lat/lng) columns in the live DB since a prior commit, but
nothing reads them yet, and no migration file documents them.

## 2. Grounded facts (from codebase inspection)

- `CoSo.java`: `ViDo`/`KinhDo` (`BigDecimal`, getters `getViDo()`/`getKinhDo()`)
  already exist — reuse, do not add duplicate Latitude/Longitude columns.
  Also has `TenCoSo`, `DiaChi`, `GioMoCua`/`GioDongCua` (`LocalTime`),
  `HinhAnh`, `TrangThai`.
- `CoSoDAOImpl.getAllCoSo()` — the existing "active facilities" query
  (excludes `IsDeleted` and `TrangThai IN ('Chờ duyệt','Từ chối')`). Reused
  already by `DatSanServlet` and `GhepKeoServlet`. This is the base query for
  the map endpoint.
- `San.java`: `coSoID` is a plain FK int (not a JPA relation). `SanDAO.
  getSansByCoSo(int)` returns non-deleted courts for a branch; caller must
  filter `trangThai == "Sẵn sàng"` for an "available" count.
- `LoaiSan.java` holds pricing (`giaKhongDen`, `giaCoDen`) and links to
  `MonTheThao` (sport) via `monTheThaoID`. `LoaiSanDAO.getLoaiSansByCoSo(int)`
  gives branch-scoped court types — used to compute `minPrice` and `sports`.
- No DAO method today computes "cheapest price" or "available court count"
  per facility — this is new aggregation logic, added in a service class, not
  a DAO method (keeps DAOs dumb, matches existing layering).
- Auth pattern: `session.getAttribute("user")` cast to `TaiKhoan`. Booking
  page (`DatSanServlet.loadBookingPage`) allows anonymous GET — the map page
  follows the same rule (public browsing, no forced login).
- JSON pattern: Gson (not Jackson) + hand-built `Map<String,Object>` or POJO
  DTOs, never serializing JPA entities raw (`DatSanServlet` comment: "Build
  plain maps to avoid Gson serializing lazy JPA relationships"). `LocalTime`
  needs a registered `JsonSerializer` (see `DatSanServlet.gson`).
- Routing: **every** customer page is `@WebServlet("/customer/xxx")` →
  `req.getRequestDispatcher("/customer/Xxx.jsp").forward(...)` (confirmed in
  `GhepKeoServlet.java:22,46`). No project code uses direct JSP hits. No
  `/api/*` prefix exists anywhere today — this feature introduces the first
  one, per explicit user approval.
- `sql/` convention: `migration_<feature>.sql` + optional `verify_<feature>
  .sql`, idempotent guards (`IF COL_LENGTH(...) IS NULL`), Vietnamese `PRINT`
  status lines. Simple single-table additions (e.g. `migration_avatar_url.
  sql`) skip `USE`/`GO` batching.
- Booking-page branch filter **already exists**: `DatSan.jsp` reads
  `?branchId=X` via `URLSearchParams` client-side and pre-filters the court
  grid (`DatSan.jsp:1366-1368, 1557-1561`). Map CTAs reuse this — no new
  detail page needed.
- `vsport-theme.jsp` is the locked emerald design system for customer pages
  (`--vs-primary:#047857` etc.) with reusable classes `.vs-card`, `.vs-btn`/
  `.vs-btn-primary`/`.vs-btn-ghost`, `.vs-chip`/`.is-active`, `.vs-search`,
  `.vs-bottomnav`/`.vs-bn-item`. New UI must use these, not invent new tokens.
- `bottom-nav.jsp`'s active-state JS already special-cases
  `/customer/ban-do` → `key='map'` (line 45) — no JS change needed there once
  the route is real, only the markup (`<button data-soon>` → `<a href>`).
- `header.jsp` desktop `.nav-links` has **no** map entry and `pickActiveId()`
  has no `map` case — both need a small addition (justified: spec requires
  desktop parity; today desktop has zero path to the map).

## 3. Non-goals (explicitly out of scope per task instructions)

- Real matchmaking backend, Explore/Featured pages — untouched.
- Rewriting any already-redesigned JSP's structure — only the two navigation
  files get small integration edits.
- Migrating to another framework.
- Running the migration against any real database, or committing a real
  MapTiler key.

## 4. Architecture

### 4.1 Database

`sql/migration_facility_geolocation.sql` (idempotent, MS SQL Server, no
`DROP`/`TRUNCATE`):
- `ViDo`/`KinhDo` already exist in the live DB (per user's prior work) but are
  undocumented in `sql/` — the migration adds them via
  `IF COL_LENGTH('CoSo','ViDo') IS NULL ALTER TABLE ... ADD ViDo DECIMAL(9,6)
  NULL` (idempotent no-op if already present, self-documents the schema for
  other environments).
- New columns (do not exist yet): `MapAddress NVARCHAR(255) NULL`,
  `LocationVerified BIT NOT NULL DEFAULT 0`.
- `sql/verify_facility_geolocation.sql` — read-only `SELECT` reporting column
  existence (`sys.columns`) and counts of CoSo rows with/without coordinates.
  Never mutates data. Not run automatically.

### 4.2 Backend

New files under `org.example`:
- `dto/FacilityMapDTO.java` — plain POJO: `coSoId, tenCoSo, address,
  latitude, longitude, imageUrl, sports (List<String>), openingTime,
  closingTime, minPrice, distanceKm, availableCourtCount`. No PayOS, no
  account/employee data, no DB config — matches the spec's explicit
  exclusion list.
- `service/FacilityMapService.java` — aggregation + Haversine:
  1. `coSoDAO.getAllCoSo()`.
  2. Per branch: `sanDAO.getSansByCoSo(id)` filtered to `trangThai=="Sẵn
     sàng"` → `availableCourtCount`; `loaiSanDAO.getLoaiSansByCoSo(id)` →
     `minPrice = min(giaKhongDen)`, `sports = distinct MonTheThao.TenMon`.
  3. `sportId` filter: drop branches with no matching `LoaiSan.
     monTheThaoID`.
  4. Coordinates: if `ViDo`/`KinhDo` null, still include the branch with
     `latitude/longitude/distanceKm = null` (never silently dropped — shows
     in list view, naturally excluded from map pins and radius filtering,
     sorts last in distance order).
  5. If caller supplied lat/lng: Haversine distance per branch with
     coordinates; apply `radiusKm` filter if given; sort ascending
     (no-coordinate branches last).
  6. `openNow`: compare server "now" against `GioMoCua`/`GioDongCua`.
- `controller/customer/FacilityMapApiServlet.java` —
  `@WebServlet("/api/customer/facilities/map")`, GET only. Reads
  `sportId, latitude, longitude, radiusKm, openNow` query params, delegates
  to the service, writes Gson JSON (`LocalTime` adapter reused from
  `DatSanServlet`'s pattern). No session/role check (public data, matches
  booking-page GET).
- `controller/customer/BanDoServlet.java` — `@WebServlet("/customer/ban-do")`,
  GET → forward to `/customer/BanDo.jsp`. No server-side data prep (page is
  populated client-side from the API); mirrors `GhepKeoServlet`'s minimalism.

`web.xml` gets one addition: `<context-param>` `MAPTILER_API_KEY` (empty
placeholder value, never a real key). `BanDoServlet` reads it via
`getServletContext().getInitParameter(...)`, overridable by
`System.getProperty("MAPTILER_API_KEY")` (JVM flag wins), passed to the JSP
as a request attribute.

### 4.3 Frontend

`src/main/webapp/customer/BanDo.jsp` — include skeleton matches every other
customer page (`head.jsp`, `vsport-theme.jsp`, `header.jsp`, `footer.jsp`,
`bottom-nav.jsp`):
- Leaflet + Leaflet.markercluster via CDN `<script>`/`<link>` (matches the
  project's existing CDN-based asset loading for Tailwind/Fonts/Material
  Symbols — no new build tooling).
- Tile provider: MapTiler if `MAPTILER_API_KEY` request attribute is
  non-blank; else OSM public tile server as an explicit, visibly-labeled dev
  fallback (`console.warn` + small on-page "dev tiles" badge — never silently
  presented as production).
- Full-screen map (`min-height: 100dvh` minus header/bottom-nav), floating
  search bar (`.vs-search`), sport chips (`.vs-chip`), radius selector,
  "Vị trí của tôi" button (`.vs-btn-primary`), list/map toggle, custom
  V-SPORT marker icon (emerald, matches `--vs-primary`), clustering via
  Leaflet.markercluster.
- Explicit states: loading (skeleton), permission-denied, no-location
  (browsing without geolocation — default state, not blocking), empty-result,
  error. No fake success states.
- Marker click → popup (desktop) / bottom sheet (mobile) showing: name,
  image, address, distance, sports, opening hours, price-from, available
  court count, "Xem chi tiết" and "Đặt sân" — **both** link to
  `/customer/dat-san?branchId={coSoId}` (existing client-side filter,
  confirmed working end-to-end; no new detail page).
- Geolocation requested only after the user taps "Vị trí của tôi" (never on
  page load). Coordinates used in-memory for the API call only — never
  written to session, DB, or logs.

### 4.4 Navigation integration

- `bottom-nav.jsp`: change
  `<button type="button" class="vs-bn-item" data-nav="map" data-soon="Bản đồ" ...>`
  to `<a class="vs-bn-item" data-nav="map" href="${ctx}/customer/ban-do">`
  (same shape as the `home`/`match`/`account` links). Remove `data-soon`.
  Active-state JS already handles this route — no JS edit needed.
- `header.jsp`: add `<li><a href="${pageContext.request.contextPath}
  /customer/ban-do" id="nav-map">Bản đồ</a></li>` to `.nav-links` (and the
  mobile drawer equivalent `#mnav-map`), plus a `map` branch in
  `pickActiveId()` (`currentPath.includes('/customer/ban-do')`) wired into
  both the desktop and mobile `pickActiveId(...)` call sites.

## 5. Files expected to change / be created

**New:**
- `sql/migration_facility_geolocation.sql`
- `sql/verify_facility_geolocation.sql`
- `src/main/java/org/example/dto/FacilityMapDTO.java`
- `src/main/java/org/example/service/FacilityMapService.java`
- `src/main/java/org/example/controller/customer/FacilityMapApiServlet.java`
- `src/main/java/org/example/controller/customer/BanDoServlet.java`
- `src/main/webapp/customer/BanDo.jsp`
- `docs/MAP_MANUAL_TEST.md`
- `.env.example` (new file, just the `MAPTILER_API_KEY=your_maptiler_api_key`
  placeholder line — none exists today)

**Modified:**
- `src/main/webapp/WEB-INF/web.xml` (add `MAPTILER_API_KEY` context-param)
- `src/main/webapp/customer/common/bottom-nav.jsp` (map link goes live)
- `src/main/webapp/common/header.jsp` (add desktop + mobile-drawer map link,
  extend `pickActiveId`)

No other already-redesigned file is touched.

## 6. Testing / verification plan

- `mvn compile`, `mvn test-compile`, `mvn package -DskipTests` after each
  major step.
- Jasper JspC compilation for `BanDo.jsp` (and re-check `bottom-nav.jsp`,
  `header.jsp` since they're shared includes).
- No DB connection attempted; migration/verify scripts are handed to the user
  to run manually.
- `docs/MAP_MANUAL_TEST.md` — manual Windows/Tomcat checklist covering the 15
  items from the task brief (MapTiler load, OSM fallback, permission
  allow/deny, markers, clustering, filters, sorting, popup/sheet, booking
  CTA, mobile 390×844, desktop 1366×768, no horizontal overflow, API safety).

## 7. Open risks / deferred

- `getAllCoSo()`'s status filter is an exclusion list, not an explicit
  allow-list (`NOT IN ('Chờ duyệt','Từ chối')`) — any other future status
  value would pass through un-audited. Not fixed here (pre-existing
  behavior, out of scope), but flagged.
- Existing `CoSo` rows almost certainly have `NULL` `ViDo`/`KinhDo` unless
  registered after the geocoding-on-register feature landed — the map may
  show few/no pins until branches are backfilled. Backfilling data is
  explicitly out of scope (no DB mutation).
- No pagination on the facilities-map endpoint — acceptable at current scale
  (small number of branches), flagged as a future concern if the branch
  count grows large.
