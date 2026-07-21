package org.example.dao.impl;

import org.example.dao.SoftHoldDAO;
import org.example.util.DBUtil;

import java.sql.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class SoftHoldDAOImpl implements SoftHoldDAO {

    private static final Logger logger = LogManager.getLogger(SoftHoldDAOImpl.class);

    public static void deleteExpiredHoldsStatic() {
        String sql = "DELETE FROM SoftHold WHERE DATEDIFF(minute, CreatedTime, GETDATE()) > "
                + org.example.util.Constants.SOFT_HOLD_TIMEOUT_MINUTES;
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.executeUpdate();
        } catch (SQLException e) {
            logger.error("Lỗi khi dọn soft-hold hết hạn: {}", e.getMessage(), e);
        }
    }

    @Override
    public void deleteExpiredHolds() {
        deleteExpiredHoldsStatic();
    }

    @Override
    public HoldResult createHold(int accountId, int sanId, LocalDate ngayDat,
                                  LocalTime gioBatDau, LocalTime gioKetThuc) {
        deleteExpiredHoldsStatic();

        try (Connection conn = DBUtil.getConnection()) {
            if (conn == null) {
                return new HoldResult(false, "Không thể kết nối cơ sở dữ liệu. Vui lòng thử lại.", null);
            }
            conn.setAutoCommit(false);
            try {
                String lockSql = "SELECT SanID FROM San WITH (UPDLOCK, ROWLOCK) WHERE SanID = ?";
                try (PreparedStatement lockPs = conn.prepareStatement(lockSql)) {
                    lockPs.setInt(1, sanId);
                    try (ResultSet rs = lockPs.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            return new HoldResult(false, "Sân không tồn tại.", null);
                        }
                    }
                }

                // Chặn giữ chỗ ngay từ bước này nếu khách đã đạt giới hạn 3 lượt/ngày - trước đây
                // bước này không kiểm tra, nên một tài khoản đã hết lượt vẫn tạo được SoftHold chặn
                // slot của người khác cho tới khi hold tự hết hạn (SOFT_HOLD_TIMEOUT_MINUTES), dù
                // chính request đặt sân thật (DatSanServlet) chắc chắn sẽ bị từ chối sau đó.
                if (org.example.dao.impl.LichDatSanDAOImpl.countActiveBookingsForAccountAndDate(conn, accountId, ngayDat) >= 3) {
                    conn.rollback();
                    return new HoldResult(false,
                            "Bạn đã đạt giới hạn đặt sân tối đa trong ngày hôm nay (tối đa 3 lượt đặt/ngày).",
                            "BOOKING_LIMIT_REACHED", null);
                }

                String checkSql = "SELECT COUNT(*) FROM SoftHold " +
                        "WHERE SanID = ? AND NgayDat = ? AND AccountID <> ? " +
                        "AND DATEDIFF(minute, CreatedTime, GETDATE()) <= " +
                        org.example.util.Constants.SOFT_HOLD_TIMEOUT_MINUTES + " " +
                        "AND NOT (GioKetThuc <= CAST(? AS time) OR GioBatDau >= CAST(? AS time))";
                try (PreparedStatement checkPs = conn.prepareStatement(checkSql)) {
                    checkPs.setInt(1, sanId);
                    checkPs.setDate(2, Date.valueOf(ngayDat));
                    checkPs.setInt(3, accountId);
                    checkPs.setString(4, gioBatDau.toString());
                    checkPs.setString(5, gioKetThuc.toString());
                    try (ResultSet rs = checkPs.executeQuery()) {
                        if (rs.next() && rs.getInt(1) > 0) {
                            conn.rollback();
                            return new HoldResult(false,
                                "Đã có người đang giữ khung giờ này, vui lòng chọn khung giờ khác.",
                                "SLOT_ALREADY_RESERVED", null);
                        }
                    }
                }

                // Overlap chuẩn - PHẢI khớp đúng whitelist trạng thái với DatSanServlet (nguồn sự
                // thật duy nhất): Đã xác nhận/Đang sử dụng/Chờ xác nhận luôn chặn; Chờ thanh toán chỉ
                // chặn khi còn hạn giữ chỗ thật (HoldExpiresAt > SYSUTCDATETIME(), không phải DATEDIFF(CreatedTime)
                // - hold có thể được gia hạn/khác PENDING_PAYMENT_TIMEOUT_MINUTES). Đã hoàn thành/Quá
                // hạn/Đã hủy/Không đến KHÔNG được chặn.
                String checkBookingSql = "SELECT COUNT(*) FROM LichDatSan " +
                        "WHERE SanID = ? AND NgayDat = ? " +
                        "AND (TrangThai IN (N'" + org.example.util.Constants.TRANG_THAI_DAT_SAN_DA_XAC_NHAN + "', " +
                        "N'" + org.example.util.Constants.TRANG_THAI_DAT_SAN_DANG_SU_DUNG + "', " +
                        "N'" + org.example.util.Constants.TRANG_THAI_DAT_SAN_CHO_XAC_NHAN + "') " +
                        "     OR (TrangThai = N'" + org.example.util.Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN + "' AND HoldExpiresAt > SYSUTCDATETIME())) " +
                        "AND NOT (GioKetThuc <= CAST(? AS time) OR GioBatDau >= CAST(? AS time))";
                try (PreparedStatement bkPs = conn.prepareStatement(checkBookingSql)) {
                    bkPs.setInt(1, sanId);
                    bkPs.setDate(2, Date.valueOf(ngayDat));
                    bkPs.setString(3, gioBatDau.toString());
                    bkPs.setString(4, gioKetThuc.toString());
                    try (ResultSet rs = bkPs.executeQuery()) {
                        if (rs.next() && rs.getInt(1) > 0) {
                            conn.rollback();
                            return new HoldResult(false,
                                "Khung giờ này đã có người đặt. Vui lòng chọn khung giờ khác.",
                                "SLOT_ALREADY_RESERVED", null);
                        }
                    }
                }

                String insertSql = "INSERT INTO SoftHold (AccountID, SanID, NgayDat, GioBatDau, GioKetThuc) " +
                        "VALUES (?, ?, ?, ?, ?)";
                try (PreparedStatement insertPs = conn.prepareStatement(insertSql)) {
                    insertPs.setInt(1, accountId);
                    insertPs.setInt(2, sanId);
                    insertPs.setDate(3, Date.valueOf(ngayDat));
                    insertPs.setTime(4, Time.valueOf(gioBatDau));
                    insertPs.setTime(5, Time.valueOf(gioKetThuc));
                    insertPs.executeUpdate();
                }

                conn.commit();
                LocalDateTime expiresAt = LocalDateTime.now()
                        .plusMinutes(org.example.util.Constants.SOFT_HOLD_TIMEOUT_MINUTES);
                return new HoldResult(true, null, expiresAt);

            } catch (SQLException e) {
                try { conn.rollback(); } catch (SQLException ignored) {}
                logger.error("Lỗi khi tạo soft-hold: {}", e.getMessage(), e);
                return new HoldResult(false, "Có lỗi xảy ra, vui lòng thử lại.", null);
            }
        } catch (SQLException e) {
            logger.error("Lỗi kết nối khi tạo soft-hold: {}", e.getMessage(), e);
            return new HoldResult(false, "Không thể kết nối cơ sở dữ liệu.", null);
        }
    }

    @Override
    public void deleteHoldsByAccountAndSan(int accountId, int sanId, LocalDate ngayDat) {
        String sql = "DELETE FROM SoftHold WHERE AccountID = ? AND SanID = ? AND NgayDat = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setInt(2, sanId);
            ps.setDate(3, Date.valueOf(ngayDat));
            ps.executeUpdate();
        } catch (SQLException e) {
            logger.error("Lỗi khi xóa soft-hold của account {}: {}", accountId, e.getMessage(), e);
        }
    }
}
