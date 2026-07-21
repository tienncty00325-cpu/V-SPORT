package org.example.service.booking;

import jakarta.servlet.http.HttpServletRequest;
import org.example.dao.LichDatSanDAO;
import org.example.dao.impl.LichDatSanDAOImpl;
import org.example.model.Lichdatsan;
import org.example.model.TaiKhoan;
import org.example.service.AuditLogService;
import org.example.service.reputation.CustomerReputationService;
import org.example.util.Constants;
import org.example.util.DBUtil;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDateTime;

/**
 * Hủy booking do khách tự thao tác (mục 5, 16 spec). Servlet chỉ nhận request và gọi service này -
 * không được duplicate logic tính hủy sớm/hủy sát giờ hay trừ điểm ở bất kỳ Servlet nào khác.
 */
public class BookingCancellationService {

    private static final Logger logger = LogManager.getLogger(BookingCancellationService.class);

    private final LichDatSanDAO lichDatSanDAO;

    public BookingCancellationService() {
        this(new LichDatSanDAOImpl());
    }

    public BookingCancellationService(LichDatSanDAO lichDatSanDAO) {
        this.lichDatSanDAO = lichDatSanDAO;
    }

    public static class CancelResult {
        public final boolean success;
        public final boolean alreadyCancelled;
        public final boolean lateCancel;
        public final String message;
        public final Integer newReputationScore;

        private CancelResult(boolean success, boolean alreadyCancelled, boolean lateCancel,
                              String message, Integer newReputationScore) {
            this.success = success;
            this.alreadyCancelled = alreadyCancelled;
            this.lateCancel = lateCancel;
            this.message = message;
            this.newReputationScore = newReputationScore;
        }

        static CancelResult ok(boolean lateCancel, String message, Integer newReputationScore) {
            return new CancelResult(true, false, lateCancel, message, newReputationScore);
        }

        static CancelResult alreadyDone(String message) {
            return new CancelResult(false, true, false, message, null);
        }

        static CancelResult fail(String message) {
            return new CancelResult(false, false, false, message, null);
        }
    }

    /** Trạng thái nguồn được phép hủy bởi khách (mục 10 spec). Logic thuần — test riêng, không đụng DB. */
    public static boolean isCancellableStatus(String trangThai) {
        return Constants.TRANG_THAI_DAT_SAN_CHO_XAC_NHAN.equals(trangThai)
                || Constants.TRANG_THAI_DAT_SAN_DA_XAC_NHAN.equals(trangThai)
                || Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN.equals(trangThai);
    }

    public CancelResult cancelByCustomer(int datSanId, int accountId, String reason,
                                          HttpServletRequest req, TaiKhoan actor) {
        Lichdatsan lich = lichDatSanDAO.getLichById(datSanId);
        if (lich == null) {
            return CancelResult.fail("Không tìm thấy đơn đặt sân.");
        }
        if (lich.getAccountId() == null || lich.getAccountId() != accountId) {
            logger.warn("IDOR attempt: AccountID={} co huy don ID={} cua AccountID={}",
                    accountId, datSanId, lich.getAccountId());
            return CancelResult.fail("Bạn không có quyền hủy đơn này.");
        }
        if (Constants.TRANG_THAI_DAT_SAN_DA_XAC_NHAN.equals(lich.getTrangThai())
                && (Constants.PT_PAYOS.equals(lich.getPaymentMethodConfirmed())
                    || (lich.getGhiChu() != null && lich.getGhiChu().contains(Constants.PAYOS_PAID_GHI_CHU_MARKER)))) {
            return CancelResult.fail("Đơn này đã thanh toán PayOS. Vui lòng liên hệ sân để được hỗ trợ hủy/hoàn tiền.");
        }
        if (!isCancellableStatus(lich.getTrangThai())) {
            return CancelResult.fail("Chỉ có thể hủy đơn đang ở trạng thái 'Chờ xác nhận', 'Đã xác nhận' hoặc " +
                    "'Chờ thanh toán'. Đơn của bạn hiện đang ở trạng thái '" + lich.getTrangThai() + "'.");
        }
        // HoldExpiresAt lưu UTC → so sánh bằng Instant UTC (TimeUtil), không dùng giờ JVM/VN.
        // (NgayDat/GioBatDau bên dưới là giờ theo lịch địa phương — giữ nguyên so sánh local.)
        if (Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN.equals(lich.getTrangThai())
                && org.example.util.TimeUtil.isPastUtc(lich.getHoldExpiresAt())) {
            return CancelResult.fail("Đơn giữ chỗ đã hết hạn, không thể hủy (đã tự động giải phóng).");
        }

        LocalDateTime now = LocalDateTime.now();
        LocalDateTime bookingStart = LocalDateTime.of(lich.getNgayDat(), lich.getGioBatDau());
        boolean isLate = CancelDecision.decide(now, bookingStart, Constants.LATE_CANCEL_HOURS)
                == CancelDecision.CancelType.LATE_CANCEL;
        String cancelType = isLate ? Constants.CANCEL_TYPE_LATE : Constants.CANCEL_TYPE_EARLY;

        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            Integer newScore = null;
            try {
                int rows = lichDatSanDAO.cancelByCustomer(conn, datSanId, accountId, cancelType, reason);
                if (rows == 0) {
                    conn.rollback();
                    return CancelResult.alreadyDone("Booking đã được hủy trước đó hoặc không còn ở trạng thái có thể hủy.");
                }
                if (isLate) {
                    newScore = CustomerReputationService.applyDelta(conn, accountId, datSanId,
                            Constants.REPUTATION_ACTION_LATE_CANCEL, Constants.LATE_CANCEL_PENALTY,
                            "Khách hủy sát giờ (dưới " + Constants.LATE_CANCEL_HOURS + " tiếng trước giờ chơi)",
                            accountId, AuditLogService.getClientIp(req));
                }
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }

            AuditLogService.log(req, actor, AuditLogService.ACTION_CANCEL, AuditLogService.ENTITY_DAT_SAN,
                    String.valueOf(datSanId), "Đơn đặt sân #" + datSanId,
                    (isLate ? "Khách hủy sát giờ (Late Cancel)" : "Khách hủy sớm (Early Cancel)")
                            + (reason != null && !reason.isBlank() ? " - Lý do: " + reason.trim() : ""));

            String message = isLate
                    ? "Bạn đã hủy sát giờ. Hệ thống đã ghi nhận và điểm uy tín của bạn bị trừ "
                        + Math.abs(Constants.LATE_CANCEL_PENALTY) + " điểm."
                    : "Đã hủy đơn đặt sân #" + datSanId + " thành công.";
            return CancelResult.ok(isLate, message, newScore);
        } catch (SQLException e) {
            logger.error("Loi khi huy booking #{} cho AccountID={}: {}", datSanId, accountId, e.getMessage(), e);
            return CancelResult.fail("Hệ thống gặp lỗi khi hủy đơn. Vui lòng thử lại.");
        }
    }
}
