package org.example.service.reputation;

import org.example.util.Constants;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

/**
 * Sổ cái điểm uy tín khách hàng (mục 3, 12 spec). Mọi thay đổi DiemUyTin PHẢI đi qua đây
 * để không có nguồn tính điểm thứ hai rải rác ở các Servlet khác nhau.
 *
 * Quan trọng: applyDelta() KHÔNG tự quản lý transaction (không gọi commit/rollback/setAutoCommit) -
 * caller phải mở sẵn Connection ở chế độ transaction thủ công và tự commit/rollback. Điều này đảm bảo
 * tính idempotent: caller chỉ gọi applyDelta() SAU KHI UPDATE trạng thái booking (với WHERE guard trạng
 * thái nguồn) đã ảnh hưởng đúng 1 dòng - double-click/retry sẽ thấy 0 dòng và không bao giờ gọi tới đây.
 */
public final class CustomerReputationService {

    private static final Logger logger = LogManager.getLogger(CustomerReputationService.class);

    private CustomerReputationService() {
    }

    /** Logic thuần: cộng delta vào điểm hiện tại rồi kẹp trong [MIN_REPUTATION_SCORE, MAX_REPUTATION_SCORE]. */
    public static int clamp(int scoreBefore, int delta) {
        int raw = scoreBefore + delta;
        return Math.max(Constants.MIN_REPUTATION_SCORE, Math.min(Constants.MAX_REPUTATION_SCORE, raw));
    }

    /**
     * Áp dụng một thay đổi điểm uy tín + ghi lịch sử, trong transaction của caller.
     *
     * @param conn       Connection đã mở transaction (autoCommit=false) - KHÔNG commit/rollback ở đây.
     * @param accountId  Tài khoản khách hàng bị/được thay đổi điểm.
     * @param datSanId   Booking liên quan (nullable - null cho MANUAL_ADJUST không gắn với booking cụ thể).
     * @param actionType Constants.REPUTATION_ACTION_* - dùng để tăng đúng bộ đếm (LateCancelCount/NoShowCount/CompletedBookingCount).
     * @param scoreDelta Số điểm cộng/trừ (âm = trừ).
     * @param reason     Lý do hiển thị trong lịch sử (vd "Khách hủy sát giờ").
     * @param actorId    Người thực hiện (khách tự hủy = accountId của khách; staff no-show = accountId nhân viên; null nếu hệ thống).
     * @param ipAddress  IP của actor nếu có (nullable).
     * @return Điểm uy tín sau khi áp dụng (đã kẹp).
     */
    public static int applyDelta(Connection conn, int accountId, Integer datSanId, String actionType,
                                  int scoreDelta, String reason, Integer actorId, String ipAddress) throws SQLException {
        int scoreBefore;
        try (PreparedStatement lock = conn.prepareStatement(
                "SELECT DiemUyTin FROM Accounts WITH (UPDLOCK, ROWLOCK) WHERE AccountID = ?")) {
            lock.setInt(1, accountId);
            try (ResultSet rs = lock.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException("Không tìm thấy tài khoản khách hàng AccountID=" + accountId);
                }
                scoreBefore = rs.getInt("DiemUyTin");
            }
        }

        int scoreAfter = clamp(scoreBefore, scoreDelta);

        String counterColumn = counterColumnFor(actionType);
        String updateSql = counterColumn != null
                ? "UPDATE Accounts SET DiemUyTin = ?, " + counterColumn + " = " + counterColumn + " + 1 WHERE AccountID = ?"
                : "UPDATE Accounts SET DiemUyTin = ? WHERE AccountID = ?";
        try (PreparedStatement update = conn.prepareStatement(updateSql)) {
            update.setInt(1, scoreAfter);
            update.setInt(2, accountId);
            update.executeUpdate();
        }

        try (PreparedStatement insert = conn.prepareStatement(
                "INSERT INTO CustomerReputationHistory " +
                "(AccountID, DatSanID, ActionType, ScoreDelta, ScoreBefore, ScoreAfter, Reason, CreatedBy, IpAddress) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")) {
            insert.setInt(1, accountId);
            if (datSanId != null) {
                insert.setInt(2, datSanId);
            } else {
                insert.setNull(2, Types.INTEGER);
            }
            insert.setString(3, actionType);
            insert.setInt(4, scoreDelta);
            insert.setInt(5, scoreBefore);
            insert.setInt(6, scoreAfter);
            insert.setString(7, reason);
            if (actorId != null) {
                insert.setInt(8, actorId);
            } else {
                insert.setNull(8, Types.INTEGER);
            }
            insert.setString(9, ipAddress);
            insert.executeUpdate();
        }

        logger.info("Reputation adjust: AccountID={}, action={}, delta={}, before={}, after={}",
                accountId, actionType, scoreDelta, scoreBefore, scoreAfter);
        return scoreAfter;
    }

    private static String counterColumnFor(String actionType) {
        if (Constants.REPUTATION_ACTION_LATE_CANCEL.equals(actionType)) {
            return "LateCancelCount";
        }
        if (Constants.REPUTATION_ACTION_NO_SHOW.equals(actionType)) {
            return "NoShowCount";
        }
        if (Constants.REPUTATION_ACTION_COMPLETED_BOOKING.equals(actionType)) {
            return "CompletedBookingCount";
        }
        return null;
    }
}
