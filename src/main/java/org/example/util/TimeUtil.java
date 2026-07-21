package org.example.util;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

/**
 * Chuẩn hóa xử lý thời gian "mốc tuyệt đối" (instant) cho các cột DATETIME2 kiểu hết-hạn
 * (HoldExpiresAt, PayosExpiresAt...) trong V-SPORT.
 *
 * QUY ƯỚC DUY NHẤT (không cộng cứng offset ở bất kỳ đâu):
 *  - Các cột này được GHI bằng SYSUTCDATETIME() phía SQL Server ⇒ luôn là giờ UTC (không phụ
 *    thuộc timezone của máy chủ DB).
 *  - JDBC đọc lên thành LocalDateTime/Timestamp "trần" (không mang zone) = đúng wall-clock UTC đã lưu.
 *  - Vì vậy: diễn giải giá trị trần đó là UTC ⇒ Instant, rồi SO SÁNH với Instant.now() (cũng UTC).
 *  - CHỈ đổi sang Asia/Ho_Chi_Minh khi HIỂN THỊ (thực tế trang QR truyền epoch-millis xuống trình
 *    duyệt và để trình duyệt tự hiển thị theo giờ địa phương của khách).
 *
 * KHÔNG dùng cho NgayDat/GioBatDau — đó là ngày/giờ theo lịch (wall-clock địa phương), không phải instant.
 */
public final class TimeUtil {

    private TimeUtil() {}

    /** Diễn giải một LocalDateTime "trần" (đọc từ cột UTC) thành Instant UTC. Null-safe. */
    public static Instant fromUtcNaive(LocalDateTime utcWallClock) {
        return utcWallClock == null ? null : utcWallClock.toInstant(ZoneOffset.UTC);
    }

    /** Diễn giải một java.sql.Timestamp (đọc từ cột UTC) thành Instant UTC. Null-safe. */
    public static Instant fromDb(Timestamp ts) {
        return ts == null ? null : ts.toLocalDateTime().toInstant(ZoneOffset.UTC);
    }

    /** Chuyển Instant về Timestamp để GHI vào cột UTC (lưu đúng wall-clock UTC, không lệ thuộc zone JVM). */
    public static Timestamp toDb(Instant instant) {
        return instant == null ? null : Timestamp.valueOf(LocalDateTime.ofInstant(instant, ZoneOffset.UTC));
    }

    /** true nếu mốc hết hạn (đọc từ cột UTC) đã ở quá khứ so với hiện tại. Null ⇒ không hết hạn. */
    public static boolean isPastUtc(LocalDateTime utcWallClock) {
        Instant i = fromUtcNaive(utcWallClock);
        return i != null && i.isBefore(Instant.now());
    }

    /** Số giây còn lại tới mốc (>= 0). Null hoặc đã qua ⇒ 0. */
    public static long secondsUntilUtc(LocalDateTime utcWallClock) {
        Instant i = fromUtcNaive(utcWallClock);
        if (i == null) return 0L;
        long s = i.getEpochSecond() - Instant.now().getEpochSecond();
        return Math.max(0L, s);
    }
}
