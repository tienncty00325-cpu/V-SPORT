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
