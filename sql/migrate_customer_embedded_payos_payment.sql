/* =====================================================================================
   Migration: Embedded PayOS QR for the CUSTOMER booking flow (V-SPORT)
   File     : sql/migrate_customer_embedded_payos_payment.sql
   Target   : Microsoft SQL Server
   Author   : (run manually — this script is NOT executed automatically)

   PURPOSE
   -------
   The customer booking→PayOS flow keys the PayOS payment link by orderCode = DatSanID and
   confirms it idempotently from the webhook (PayOSLegacyBookingFinalizationService). Until now
   the QR payload PayOS returns was only forwarded to the browser transiently, so the QR could
   not be re-rendered on reload / in a second tab / from "Lịch của tôi".

   This migration adds a small PayOS QR *cache* onto LichDatSan so V-SPORT can render its OWN
   embedded QR page (VietQR → PNG via ZXing, server-side) and let the customer resume payment.
   We intentionally EXTEND the existing booking row instead of creating a duplicate payment
   table: the customer flow already uses DatSanID as the single order key, HoldExpiresAt as the
   hold clock, and LichDatSan.TrangThai as the single booking state. Booking state stays the
   source of truth (WAITING_PAYMENT = N'Chờ thanh toán', CONFIRMED = N'Đã xác nhận',
   EXPIRED = N'Quá hạn', CANCELLED = N'Đã hủy'); these columns are a render cache only, never a
   second status field.

   (The separate PayOSPaymentAttempt table remains dedicated to the Manager/Staff HoaDon flow
   and is untouched here.)

   SAFETY
   ------
   - Idempotent: every ALTER is guarded by a sys.columns existence check; re-running is a no-op.
   - No secrets. No data destruction. Adds NULLable columns only (no default backfill needed).
   - Rollback notes at the bottom. Verify section at the bottom.
   ===================================================================================== */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'--- migrate_customer_embedded_payos_payment.sql : START ---';
GO

/* -- PayosOrderCode: explicit order key (= DatSanID today; stored for clarity/future) -------- */
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'PayosOrderCode')
BEGIN
    ALTER TABLE LichDatSan ADD PayosOrderCode BIGINT NULL;
    PRINT N'  + added LichDatSan.PayosOrderCode';
END
ELSE PRINT N'  = LichDatSan.PayosOrderCode already exists, skipped';
GO

/* -- PayosPaymentLinkId: PayOS payment-link id for the active PENDING link -------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'PayosPaymentLinkId')
BEGIN
    ALTER TABLE LichDatSan ADD PayosPaymentLinkId VARCHAR(255) NULL;
    PRINT N'  + added LichDatSan.PayosPaymentLinkId';
END
ELSE PRINT N'  = LichDatSan.PayosPaymentLinkId already exists, skipped';
GO

/* -- PayosQrPayload: raw VietQR string PayOS returns (rendered to PNG server-side by ZXing) --- */
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'PayosQrPayload')
BEGIN
    ALTER TABLE LichDatSan ADD PayosQrPayload NVARCHAR(MAX) NULL;
    PRINT N'  + added LichDatSan.PayosQrPayload';
END
ELSE PRINT N'  = LichDatSan.PayosQrPayload already exists, skipped';
GO

/* -- PayosCheckoutUrl: fallback only (NOT the default flow) ----------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'PayosCheckoutUrl')
BEGIN
    ALTER TABLE LichDatSan ADD PayosCheckoutUrl NVARCHAR(1024) NULL;
    PRINT N'  + added LichDatSan.PayosCheckoutUrl';
END
ELSE PRINT N'  = LichDatSan.PayosCheckoutUrl already exists, skipped';
GO

/* -- Bank display fields (from PayOS CreatePaymentLinkResponse) ------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'PayosBin')
BEGIN
    ALTER TABLE LichDatSan ADD PayosBin VARCHAR(20) NULL;
    PRINT N'  + added LichDatSan.PayosBin';
END
ELSE PRINT N'  = LichDatSan.PayosBin already exists, skipped';
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'PayosAccountNumber')
BEGIN
    ALTER TABLE LichDatSan ADD PayosAccountNumber VARCHAR(64) NULL;
    PRINT N'  + added LichDatSan.PayosAccountNumber';
END
ELSE PRINT N'  = LichDatSan.PayosAccountNumber already exists, skipped';
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'PayosAccountName')
BEGIN
    ALTER TABLE LichDatSan ADD PayosAccountName NVARCHAR(255) NULL;
    PRINT N'  + added LichDatSan.PayosAccountName';
END
ELSE PRINT N'  = LichDatSan.PayosAccountName already exists, skipped';
GO

/* -- PayosAmount / PayosDescription: exact values sent to PayOS (display + copy on QR page) --- */
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'PayosAmount')
BEGIN
    ALTER TABLE LichDatSan ADD PayosAmount DECIMAL(18,2) NULL;
    PRINT N'  + added LichDatSan.PayosAmount';
END
ELSE PRINT N'  = LichDatSan.PayosAmount already exists, skipped';
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'PayosDescription')
BEGIN
    ALTER TABLE LichDatSan ADD PayosDescription NVARCHAR(255) NULL;
    PRINT N'  + added LichDatSan.PayosDescription';
END
ELSE PRINT N'  = LichDatSan.PayosDescription already exists, skipped';
GO

/* -- PayosExpiresAt: QR/link expiry PayOS reported (used for the countdown + expired state) ---
   NOTE: HoldExpiresAt (added by migration_reservation_hold.sql) remains the authoritative slot
   hold clock. PayosExpiresAt is the PayOS link expiry and is only a display convenience. */
IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'PayosExpiresAt')
BEGIN
    ALTER TABLE LichDatSan ADD PayosExpiresAt DATETIME2 NULL;
    PRINT N'  + added LichDatSan.PayosExpiresAt';
END
ELSE PRINT N'  = LichDatSan.PayosExpiresAt already exists, skipped';
GO

/* -- Helpful (non-unique) index for looking up a booking by its PayOS order key --------------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'IX_LichDatSan_PayosOrderCode')
BEGIN
    CREATE INDEX IX_LichDatSan_PayosOrderCode ON LichDatSan (PayosOrderCode) WHERE PayosOrderCode IS NOT NULL;
    PRINT N'  + created filtered index IX_LichDatSan_PayosOrderCode';
END
ELSE PRINT N'  = IX_LichDatSan_PayosOrderCode already exists, skipped';
GO

PRINT N'--- migrate_customer_embedded_payos_payment.sql : DONE ---';
GO

/* =====================================================================================
   VERIFY (run after migration; all rows below should print / return the new columns)
   ===================================================================================== */
PRINT N'--- VERIFY: new columns on LichDatSan ---';
SELECT c.name AS column_name, t.name AS data_type, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types  t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'LichDatSan')
  AND c.name IN (N'PayosOrderCode', N'PayosPaymentLinkId', N'PayosQrPayload', N'PayosCheckoutUrl',
                 N'PayosBin', N'PayosAccountNumber', N'PayosAccountName', N'PayosAmount',
                 N'PayosDescription', N'PayosExpiresAt')
ORDER BY c.name;
GO

/* =====================================================================================
   ROLLBACK (safe — drops only the render-cache columns added above; booking data untouched)
   Run ONLY if you need to revert. Uncomment and execute:

   IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'LichDatSan') AND name = N'IX_LichDatSan_PayosOrderCode')
       DROP INDEX IX_LichDatSan_PayosOrderCode ON LichDatSan;
   ALTER TABLE LichDatSan DROP COLUMN
       PayosOrderCode, PayosPaymentLinkId, PayosQrPayload, PayosCheckoutUrl,
       PayosBin, PayosAccountNumber, PayosAccountName, PayosAmount, PayosDescription, PayosExpiresAt;
   ===================================================================================== */
