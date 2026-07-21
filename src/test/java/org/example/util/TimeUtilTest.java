package org.example.util;

import org.junit.jupiter.api.Test;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Khóa lại fix timezone của HoldExpiresAt/PayosExpiresAt (bug row DatSanID=193):
 * cột lưu UTC, phải so sánh bằng Instant UTC — KHÔNG dùng LocalDateTime.now() (giờ JVM/VN)
 * nếu không sẽ kết luận hết hạn sai ~7 giờ.
 */
class TimeUtilTest {

    /** Mốc giữ chỗ CÒN hạn (UTC now + 7 phút) — dù đọc lên là LocalDateTime "trần" vẫn KHÔNG được coi là hết hạn. */
    @Test
    void validUtcHold_isNotPast() {
        // Giả lập giá trị đọc từ cột UTC: wall-clock UTC của (bây giờ + 7 phút).
        LocalDateTime utcNaive = LocalDateTime.ofInstant(Instant.now().plusSeconds(420), ZoneOffset.UTC);
        assertFalse(TimeUtil.isPastUtc(utcNaive), "Hold còn hạn không được coi là hết hạn");
        long remain = TimeUtil.secondsUntilUtc(utcNaive);
        assertTrue(remain > 300 && remain <= 420, "Còn ~7 phút, nhận được: " + remain);
    }

    /** Mốc đã qua (UTC now - 1 phút) phải là hết hạn. */
    @Test
    void pastUtcHold_isPast() {
        LocalDateTime utcNaive = LocalDateTime.ofInstant(Instant.now().minusSeconds(60), ZoneOffset.UTC);
        assertTrue(TimeUtil.isPastUtc(utcNaive));
        assertEquals(0L, TimeUtil.secondsUntilUtc(utcNaive));
    }

    /** null (PayosExpiresAt = NULL) KHÔNG được coi là hết hạn và còn lại = 0. */
    @Test
    void nullHold_isNotPast() {
        assertFalse(TimeUtil.isPastUtc(null));
        assertEquals(0L, TimeUtil.secondsUntilUtc(null));
    }

    /** toDb/fromDb round-trip đúng Instant (UTC), độc lập timezone JVM. */
    @Test
    void utcRoundTrip_preservesInstant() {
        Instant original = Instant.ofEpochSecond(1_752_853_616L); // ví dụ epoch cố định
        Timestamp db = TimeUtil.toDb(original);
        Instant back = TimeUtil.fromDb(db);
        assertEquals(original, back, "Ghi rồi đọc lại phải giữ nguyên Instant UTC");
    }

    /**
     * Bằng chứng cốt lõi của bug: khi JVM chạy ở múi giờ KHÁC UTC (vd Asia/Ho_Chi_Minh),
     * so sánh naive-UTC với LocalDateTime.now() cho kết quả SAI, còn TimeUtil (Instant UTC) đúng.
     * Mô phỏng bằng chênh lệch offset thay vì đổi zone toàn cục.
     */
    @Test
    void demonstratesOldBug_localNowComparisonIsWrongAcrossZones() {
        // Hold còn hạn thật: UTC now + 7 phút.
        Instant realExpiry = Instant.now().plusSeconds(420);
        LocalDateTime utcNaive = LocalDateTime.ofInstant(realExpiry, ZoneOffset.UTC);

        // Cách CŨ (sai) mô phỏng ở JVM +7h: so naive-UTC với "now" theo giờ VN.
        LocalDateTime vnNow = LocalDateTime.ofInstant(Instant.now(), ZoneOffset.ofHours(7));
        boolean buggyExpired = utcNaive.isBefore(vnNow); // sẽ true (kết luận hết hạn SAI)

        // Cách MỚI (đúng): so bằng Instant UTC.
        boolean correctExpired = TimeUtil.isPastUtc(utcNaive); // false

        assertTrue(buggyExpired, "Tái hiện được kết luận SAI của cách cũ khi JVM lệch UTC");
        assertFalse(correctExpired, "Cách mới bằng Instant UTC cho kết quả ĐÚNG: chưa hết hạn");
    }
}
