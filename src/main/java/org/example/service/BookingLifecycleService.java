package org.example.service;

import org.example.util.Constants;
import org.example.util.DBUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

/**
 * Tên tiếng Việt: Dịch vụ xử lý vòng đời đặt sân.
 *
 * Nhiệm vụ:
 * - Quét lịch đặt sân quá hạn giữ chỗ thanh toán.
 * - Chuyển trạng thái từ "Chờ thanh toán" sang "Quá hạn".
 *
 * Được gọi bởi:
 * - CheckInDAO.java
 * - LichDatSanDAOImpl.java
 *
 * Lưu ý:
 * - Hiện tại lớp này còn sử dụng câu lệnh SQL trực tiếp và tự quản lý JDBC connection.
 * - TODO(sau-đánh-giá): Tách SQL này xuống DAO để Service chỉ xử lý nghiệp vụ.
 */
public class BookingLifecycleService {

    private static final Logger logger = LoggerFactory.getLogger(BookingLifecycleService.class);

    private BookingLifecycleService() {
    }

    /**
     * Nghĩa tiếng Việt: Chạy quét các đơn giữ chỗ hết hạn.
     *
     * Mục đích:
     * - Tự động chuyển các đơn đặt sân đang giữ chỗ "Chờ thanh toán" nhưng đã quá thời hạn thanh toán sang trạng thái "Quá hạn".
     *
     * Input:
     * - Không có (Sử dụng thời gian hệ thống của SQL Server làm chuẩn)
     *
     * Output:
     * - Không có (Cập nhật trực tiếp xuống Database)
     *
     * Rủi ro:
     * - Thấp. Chỉ tác động tới những bản ghi thỏa mãn điều kiện quá hạn.
     */
    public static void runExpirySweep() {
        String sql = "UPDATE LichDatSan " +
                "SET TrangThai = ?, " +
                "    GhiChu = CONCAT(ISNULL(GhiChu, N''), N' [Tự động: Quá hạn giữ chỗ thanh toán]') " +
                "WHERE TrangThai = ? " +
                "AND HoldExpiresAt IS NOT NULL " +
                "AND HoldExpiresAt < SYSUTCDATETIME()";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setNString(1, Constants.TRANG_THAI_DAT_SAN_QUA_HAN);
            ps.setNString(2, Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN);
            int affected = ps.executeUpdate();
            if (affected > 0) {
                logger.info("runExpirySweep: đã chuyển {} booking 'Chờ thanh toán' quá hạn sang 'Quá hạn'.", affected);
            }
        } catch (SQLException e) {
            logger.error("Lỗi khi chạy BookingLifecycleService.runExpirySweep(): {}", e.getMessage(), e);
        }

        // Dữ liệu legacy: booking "Chờ thanh toán" không có HoldExpiresAt (tạo trước khi cơ chế
        // giữ chỗ có hạn được thêm vào) không bao giờ được sweep ở trên nên kẹt vĩnh viễn, vô hình
        // với Manager. Không chặn overlap (HoldExpiresAt IS NULL đã bị loại ở mọi query overlap),
        // nhưng vẫn cần dọn để không tồn đọng mãi - dùng giờ kết thúc theo lịch làm mốc hết hạn dự phòng.
        String legacySql = "UPDATE LichDatSan " +
                "SET TrangThai = ?, " +
                "    GhiChu = CONCAT(ISNULL(GhiChu, N''), N' [Tự động: Quá hạn giữ chỗ thanh toán - dữ liệu cũ không có HoldExpiresAt]') " +
                "WHERE TrangThai = ? " +
                "AND HoldExpiresAt IS NULL " +
                "AND CAST(NgayDat AS DATETIME) + CAST(GioKetThuc AS DATETIME) < GETDATE()";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(legacySql)) {
            ps.setNString(1, Constants.TRANG_THAI_DAT_SAN_QUA_HAN);
            ps.setNString(2, Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN);
            int affected = ps.executeUpdate();
            if (affected > 0) {
                logger.info("runExpirySweep: đã chuyển {} booking 'Chờ thanh toán' legacy (không HoldExpiresAt) đã qua giờ sang 'Quá hạn'.", affected);
            }
        } catch (SQLException e) {
            logger.error("Lỗi khi chạy BookingLifecycleService.runExpirySweep() (legacy sweep): {}", e.getMessage(), e);
        }
    }
}
