package org.example.dao;

import org.example.util.DBUtil;
import org.example.model.San;
import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.Duration;
import java.util.List;
import java.util.ArrayList;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Data Access Object (DAO) xử lý nghiệp vụ Mở Sân và Check-in.
 * Sử dụng JDBC thuần, kiểm soát Transaction thủ công và khóa bi quan để chống tranh chấp dữ liệu.
 */
public class CheckInDAO {
    private static final Logger logger = LogManager.getLogger(CheckInDAO.class);

    private boolean columnExists(Connection conn, String tableName, String columnName) throws SQLException {
        String sql = "SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(?) AND name = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setNString(1, tableName);
            ps.setNString(2, columnName);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private String mainInvoiceWhereClause(Connection conn, String datSanColumnExpression) throws SQLException {
        if (columnExists(conn, "HoaDon", "LoaiHoaDon")) {
            return datSanColumnExpression + " = ? AND (LoaiHoaDon = N'MAIN' OR LoaiHoaDon IS NULL)";
        }
        return datSanColumnExpression + " = ?";
    }

    private String mainInvoiceJoinCondition(Connection conn) throws SQLException {
        if (columnExists(conn, "HoaDon", "LoaiHoaDon")) {
            return "lds.DatSanID = hd.DatSanID AND (hd.LoaiHoaDon = N'MAIN' OR hd.LoaiHoaDon IS NULL)";
        }
        return "lds.DatSanID = hd.DatSanID";
    }

    // Định nghĩa các hằng số trạng thái
    public static final String FIELD_STATUS_AVAILABLE = "Sẵn sàng";
    public static final String FIELD_STATUS_OCCUPIED = "Đang sử dụng";
    
    public static final String BOOKING_STATUS_CONFIRMED = "Đã xác nhận";
    public static final String BOOKING_STATUS_IN_USE = "Đang sử dụng";
    
    public static final String PAYMENT_STATUS_UNPAID = "Chưa thanh toán";
    public static final String PAYMENT_STATUS_PAID = "Đã thanh toán";
    
    // Quy định thời gian đến trễ tối đa (phút)
    private static final int LATE_THRESHOLD_MINUTES = 15;
    // Quy định thời gian đến sớm tối thiểu để bắt đầu tính phí phụ thu (phút)
    private static final int EARLY_THRESHOLD_MINUTES = 10;
    // Đơn giá phụ thu đến sớm mỗi phút (VND)
    private static final double EARLY_SURCHARGE_PER_MINUTE = 2000.0; 

    // Các exception nội bộ phục vụ báo lỗi chi tiết cho Servlet
    public static class CheckInException extends Exception {
        public CheckInException(String message) { super(message); }
    }
    
    public static class FieldOccupiedException extends CheckInException {
        public FieldOccupiedException(String message) { super(message); }
    }
    
    public static class BookingConflictException extends CheckInException {
        public BookingConflictException(String message) { super(message); }
    }
    
    public static class PaymentRequiredException extends CheckInException {
        public PaymentRequiredException(String message) { super(message); }
    }
    
    public static class ConcurrencyConflictException extends CheckInException {
        public ConcurrencyConflictException(String message) { super(message); }
    }

    /**
     * Nghiệp vụ 1: Check-in cho khách hàng ĐÃ ĐẶT TRƯỚC (Pre-booked Check-in)
     * 
     * @param datSanId ID đơn đặt sân
     * @param staffAccountId ID nhân viên thực hiện check-in
     * @param forcePaymentCheck Bắt buộc kiểm tra thanh toán (Nếu chưa thanh toán/chưa cọc thì cảnh báo/chặn)
     * @param daThuTienMat Lễ tân xác nhận đã thu tiền mặt tại quầy (dành cho đơn chưa thanh toán)
     * @throws CheckInException nếu có lỗi nghiệp vụ xảy ra
     */
    public void checkInKhachDatTruoc(int datSanId, int staffAccountId, int requiredCoSoId, boolean forcePaymentCheck, boolean daThuTienMat) throws CheckInException {
        Connection conn = null;
        PreparedStatement psSelectBooking = null;
        PreparedStatement psSelectField = null;
        PreparedStatement psCheckPayment = null;
        PreparedStatement psUpdateBooking = null;
        PreparedStatement psUpdateField = null;
        PreparedStatement psUpdateInvoice = null;
        PreparedStatement psInsertInvoice = null;
        ResultSet rsBooking = null;
        ResultSet rsField = null;
        ResultSet rsPayment = null;

        try {
            conn = DBUtil.getConnection();
            // BẮT BUỘC: Tắt auto-commit để quản lý Transaction thủ công
            conn.setAutoCommit(false);

            // 1. Lấy thông tin đơn đặt lịch + join San để xác minh cơ sở
            String sqlSelectBooking = "SELECT l.SanID, l.NgayDat, l.GioBatDau, l.GioKetThuc, l.TrangThai, l.TongTienDuKien, l.GhiChu, l.AccountID, s.CoSoID " +
                    "FROM LichDatSan l WITH (UPDLOCK, ROWLOCK) JOIN San s ON s.SanID = l.SanID WHERE l.DatSanID = ?";
            psSelectBooking = conn.prepareStatement(sqlSelectBooking);
            psSelectBooking.setInt(1, datSanId);
            rsBooking = psSelectBooking.executeQuery();

            if (!rsBooking.next()) {
                throw new CheckInException("Không tìm thấy thông tin đơn đặt sân có ID: " + datSanId);
            }

            int bookingCoSoId = rsBooking.getInt("CoSoID");
            if (bookingCoSoId != requiredCoSoId) {
                throw new SecurityException("Đơn đặt sân không thuộc cơ sở của bạn.");
            }

            int sanId = rsBooking.getInt("SanID");
            int khachHangAccountId = rsBooking.getInt("AccountID");
            Date ngayDat = rsBooking.getDate("NgayDat");
            Time gioBatDau = rsBooking.getTime("GioBatDau");
            Time gioKetThuc = rsBooking.getTime("GioKetThuc");
            String trangThaiBooking = rsBooking.getString("TrangThai");
            BigDecimal tongTienDuKien = rsBooking.getBigDecimal("TongTienDuKien");
            String ghiChu = rsBooking.getString("GhiChu");

            LocalDate localNgayDat = ngayDat.toLocalDate();
            LocalTime localGioBatDau = gioBatDau.toLocalTime();
            LocalTime localGioKetThuc = gioKetThuc.toLocalTime();

            java.time.LocalDateTime nowDateTime = java.time.LocalDateTime.now();
            LocalDate today = nowDateTime.toLocalDate();
            LocalTime now = nowDateTime.toLocalTime();

            // Kiểm tra ngày đặt có trùng ngày hôm nay không
            if (!localNgayDat.equals(today)) {
                throw new CheckInException("Không thể check-in cho đơn đặt sân của ngày khác (Ngày đặt: " + localNgayDat + ")");
            }

            // Kiểm tra trạng thái đơn đặt sân - CHỈ cho phép "Đã xác nhận", KHÔNG cho "Chờ xác nhận"
            // (đơn chưa được quản lý duyệt không được vào sân).
            if (BOOKING_STATUS_IN_USE.equals(trangThaiBooking)) {
                throw new CheckInException("Đơn đặt sân này đã được check-in và đang sử dụng.");
            }
            if (!BOOKING_STATUS_CONFIRMED.equals(trangThaiBooking)) {
                throw new CheckInException("Chỉ được check-in đơn đã ở trạng thái 'Đã xác nhận' (hiện tại: " + trangThaiBooking + ").");
            }

            // Cửa sổ thời gian check-in hợp lệ: tối đa 30 phút trước giờ bắt đầu, trễ tối đa theo
            // policy no-show (NO_SHOW_GRACE_MINUTES) - quá mốc đó nên xử lý bằng no-show.
            org.example.service.checkin.CheckInWindow.Result window =
                    org.example.service.checkin.CheckInWindow.check(localNgayDat, localGioBatDau, nowDateTime);
            if (!window.allowed()) {
                throw new CheckInException(window.message());
            }

            // 2. Kiểm tra trạng thái thanh toán (Payment Lock)
            String sqlCheckPayment = "SELECT HoaDonID, TrangThaiThanhToan, TongThanhToan FROM HoaDon WHERE " + mainInvoiceWhereClause(conn, "DatSanID");
            psCheckPayment = conn.prepareStatement(sqlCheckPayment);
            psCheckPayment.setInt(1, datSanId);
            rsPayment = psCheckPayment.executeQuery();

            int hoaDonId = -1;
            String trangThaiThanhToan = PAYMENT_STATUS_UNPAID;
            BigDecimal tongThanhToan = BigDecimal.ZERO;

            if (rsPayment.next()) {
                hoaDonId = rsPayment.getInt("HoaDonID");
                trangThaiThanhToan = rsPayment.getString("TrangThaiThanhToan");
                tongThanhToan = rsPayment.getBigDecimal("TongThanhToan");
            }

            // Nếu đơn chưa thanh toán hoặc chưa cọc
            if (forcePaymentCheck && (trangThaiThanhToan == null || PAYMENT_STATUS_UNPAID.equals(trangThaiThanhToan) || "Chưa cọc".equals(trangThaiThanhToan))) {
                if (!daThuTienMat) {
                    throw new PaymentRequiredException("Đơn đặt sân này yêu cầu thanh toán/cọc nhưng chưa hoàn tất. Lễ tân phải thu tiền mặt trước khi mở sân.");
                } else if (hoaDonId == -1) {
                    // Dữ liệu cũ chưa có MAIN invoice - tạo transactionally bằng dữ liệu server.
                    // KHÔNG được tiếp tục với sentinel -1 (UPDATE ... WHERE HoaDonID = -1 trước đây
                    // no-op nhưng vẫn báo "đã thanh toán" dù hóa đơn không hề tồn tại).
                    BigDecimal amount = tongTienDuKien != null ? tongTienDuKien : BigDecimal.ZERO;
                    boolean hasLoaiHoaDon = columnExists(conn, "HoaDon", "LoaiHoaDon");
                    String sqlInsertInvoice = "INSERT INTO HoaDon (DatSanID, AccountID_KhachHang, AccountID_NhanVien, NgayLap, " +
                            "TongTienSan, TongTienDichVu, PhiGuiXe, GiamGia, TongThanhToan, PhuongThucThanhToan, TrangThaiThanhToan" +
                            (hasLoaiHoaDon ? ", LoaiHoaDon" : "") + ") VALUES (?, ?, ?, GETDATE(), ?, 0, 0, 0, ?, N'Tiền mặt', ?" +
                            (hasLoaiHoaDon ? ", N'MAIN'" : "") + ")";
                    psInsertInvoice = conn.prepareStatement(sqlInsertInvoice, Statement.RETURN_GENERATED_KEYS);
                    psInsertInvoice.setInt(1, datSanId);
                    psInsertInvoice.setInt(2, khachHangAccountId);
                    psInsertInvoice.setInt(3, staffAccountId);
                    psInsertInvoice.setBigDecimal(4, amount);
                    psInsertInvoice.setBigDecimal(5, amount);
                    psInsertInvoice.setString(6, PAYMENT_STATUS_PAID);
                    psInsertInvoice.executeUpdate();
                    try (ResultSet genKeys = psInsertInvoice.getGeneratedKeys()) {
                        if (genKeys.next()) hoaDonId = genKeys.getInt(1);
                    }
                    tongThanhToan = amount;
                    trangThaiThanhToan = PAYMENT_STATUS_PAID;
                    logger.info("Đã tạo MAIN invoice mới ID " + hoaDonId + " cho đơn đặt sân #" + datSanId + " (thu tiền mặt tại check-in, dữ liệu cũ chưa có hóa đơn).");
                } else {
                    // Nếu lễ tân tích chọn đã thu tiền mặt, cập nhật trạng thái hóa đơn ngay lập tức
                    String sqlUpdateInvoiceStatus = "UPDATE HoaDon SET TrangThaiThanhToan = ?, AccountID_NhanVien = ?, NgayLap = GETDATE() WHERE HoaDonID = ?";
                    psUpdateInvoice = conn.prepareStatement(sqlUpdateInvoiceStatus);
                    psUpdateInvoice.setString(1, PAYMENT_STATUS_PAID);
                    psUpdateInvoice.setInt(2, staffAccountId);
                    psUpdateInvoice.setInt(3, hoaDonId);
                    psUpdateInvoice.executeUpdate();
                    logger.info("Đã cập nhật trạng thái hóa đơn ID " + hoaDonId + " thành Đã thanh toán (Thu tiền mặt tại quầy).");
                    trangThaiThanhToan = PAYMENT_STATUS_PAID;
                }
            }

            // 3. Kiểm tra trạng thái sân bãi thực tế
            String sqlSelectField = "SELECT TenSan, TrangThai FROM San WHERE SanID = ?";
            psSelectField = conn.prepareStatement(sqlSelectField);
            psSelectField.setInt(1, sanId);
            rsField = psSelectField.executeQuery();

            if (!rsField.next()) {
                throw new CheckInException("Không tìm thấy thông tin sân có ID: " + sanId);
            }
            
            String tenSan = rsField.getString("TenSan");
            String trangThaiSan = rsField.getString("TrangThai");

            // Kiểm tra xem sân có đang bị chiếm dụng không
            if (!FIELD_STATUS_AVAILABLE.equals(trangThaiSan)) {
                throw new FieldOccupiedException("Sân '" + tenSan + "' hiện tại không sẵn sàng (Trạng thái: " + trangThaiSan + "). Không thể mở sân!");
            }

            // 4. Xử lý logic thời gian (Đến sớm / Đến trễ)
            Duration durationToStart = Duration.between(now, localGioBatDau);
            long minutesEarly = durationToStart.toMinutes(); // Dương: Đến sớm, Âm: Đến trễ
            
            String logGhiChu = ghiChu != null ? ghiChu : "";
            BigDecimal phuThu = BigDecimal.ZERO;

            if (minutesEarly > EARLY_THRESHOLD_MINUTES) {
                // Kịch bản Khách đến sớm (Early Check-in): Khách đến sớm hơn 10 phút
                logger.info("Khách đến sớm " + minutesEarly + " phút. Tiến hành mở sân sớm.");
                // Tính toán phụ thu thêm tiền giờ (nếu đến sớm hơn 10 phút)
                double surchargeVal = minutesEarly * EARLY_SURCHARGE_PER_MINUTE;
                phuThu = BigDecimal.valueOf(surchargeVal);
                logGhiChu += " [Check-in sớm " + minutesEarly + " phút, Phụ thu: " + phuThu + "đ]";
            } else if (minutesEarly < -LATE_THRESHOLD_MINUTES) {
                // Kịch bản Khách đến trễ (Late Check-in): Khách đến trễ quá 15 phút
                long minutesLate = -minutesEarly;
                logger.info("Khách đến trễ " + minutesLate + " phút. Vẫn cho phép nhận sân nhưng giữ nguyên giờ kết thúc.");
                logGhiChu += " [Check-in trễ " + minutesLate + " phút, giữ nguyên giờ kết thúc lúc " + localGioKetThuc + "]";
            } else {
                logGhiChu += " [Check-in đúng giờ]";
            }

            long durationMinutes = Duration.between(localGioBatDau, localGioKetThuc).toMinutes();
            if (durationMinutes < 0) {
                durationMinutes += 24 * 60;
            }

            // 5. Thực hiện cập nhật trạng thái đơn đặt sân - giữ điều kiện WHERE TrangThai nguồn để
            // affected-row check phát hiện race (đơn vừa bị đổi trạng thái bởi request khác).
            String sqlUpdateBooking = "UPDATE LichDatSan SET TrangThai = ?, actual_start_time = ?, TongTienDuKien = TongTienDuKien + ?, GhiChu = ?, TimeMode = ?, ReservedDurationMinutes = ? WHERE DatSanID = ? AND TrangThai = N'Đã xác nhận'";
            psUpdateBooking = conn.prepareStatement(sqlUpdateBooking);
            psUpdateBooking.setString(1, BOOKING_STATUS_IN_USE);
            psUpdateBooking.setTime(2, Time.valueOf(now));
            psUpdateBooking.setBigDecimal(3, phuThu);
            psUpdateBooking.setString(4, logGhiChu.trim());
            psUpdateBooking.setString(5, "FIXED_BOOKING");
            psUpdateBooking.setInt(6, (int) durationMinutes);
            psUpdateBooking.setInt(7, datSanId);
            if (psUpdateBooking.executeUpdate() != 1) {
                throw new ConcurrencyConflictException("Trạng thái đơn đặt sân vừa thay đổi bởi một thao tác khác. Vui lòng tải lại.");
            }

            // Cập nhật lại số tiền trên hóa đơn (nếu có phụ thu đến sớm)
            if (phuThu.compareTo(BigDecimal.ZERO) > 0 && hoaDonId != -1) {
                String sqlUpdateInvoiceAmount = "UPDATE HoaDon SET TongTienSan = TongTienSan + ?, TongThanhToan = TongThanhToan + ? WHERE HoaDonID = ?";
                try (PreparedStatement psUpdateInvAmt = conn.prepareStatement(sqlUpdateInvoiceAmount)) {
                    psUpdateInvAmt.setBigDecimal(1, phuThu);
                    psUpdateInvAmt.setBigDecimal(2, phuThu);
                    psUpdateInvAmt.setInt(3, hoaDonId);
                    psUpdateInvAmt.executeUpdate();
                }
            }

            // 6. Cập nhật trạng thái sân (Điều kiện UPDATE ngặt nghèo - Optimistic/Pessimistic Concurrency Check)
            // Câu lệnh cập nhật trạng thái Sân phải có điều kiện WHERE TrangThai = 'Sẵn sàng'
            String sqlUpdateField = "UPDATE San SET TrangThai = ? WHERE SanID = ? AND TrangThai = ?";
            psUpdateField = conn.prepareStatement(sqlUpdateField);
            psUpdateField.setString(1, FIELD_STATUS_OCCUPIED);
            psUpdateField.setInt(2, sanId);
            psUpdateField.setString(3, FIELD_STATUS_AVAILABLE);
            
            int affectedRows = psUpdateField.executeUpdate();
            if (affectedRows == 0) {
                // Nếu số dòng bị ảnh hưởng = 0, tức là trạng thái sân đã bị thay đổi bởi luồng khác ngay trước đó
                throw new ConcurrencyConflictException("Sân vừa bị thay đổi trạng thái bởi một giao dịch khác. Vui lòng làm tươi giao diện và thử lại.");
            }

            // 7. Commit Transaction thành công
            conn.commit();
            logger.info("Check-in cho đơn đặt sân ID " + datSanId + " hoàn thành thành công.");

        } catch (Exception e) {
            // Rollback toàn bộ nếu có bất kỳ lỗi nào xảy ra
            if (conn != null) {
                try {
                    conn.rollback();
                    logger.warn("Transaction rolled back due to error: " + e.getMessage());
                } catch (SQLException ex) {
                    logger.error("Failed to rollback transaction", ex);
                }
            }
            if (e instanceof SecurityException) {
                throw (SecurityException) e;
            } else if (e instanceof CheckInException) {
                throw (CheckInException) e;
            } else {
                throw new CheckInException("Lỗi hệ thống trong quá trình check-in: " + e.getMessage());
            }
        } finally {
            // Đóng toàn bộ resource đúng chuẩn JDBC thuần
            closeResource(rsBooking);
            closeResource(rsField);
            closeResource(rsPayment);
            closeResource(psSelectBooking);
            closeResource(psSelectField);
            closeResource(psInsertInvoice);
            closeResource(psCheckPayment);
            closeResource(psUpdateBooking);
            closeResource(psUpdateField);
            closeResource(psUpdateInvoice);
            if (conn != null) {
                try {
                    conn.setAutoCommit(true); // Trả lại trạng thái mặc định
                    conn.close();
                } catch (SQLException e) {
                    logger.error("Failed to close connection", e);
                }
            }
        }
    }

    public void checkInKhachVangLai(int sanId, int durationMinutes, int staffAccountId, double donGiaSan, String ghiChu, String playMode) throws CheckInException {
        Connection conn = null;
        PreparedStatement psCheckConflict = null;
        PreparedStatement psSelectField = null;
        PreparedStatement psInsertBooking = null;
        PreparedStatement psInsertInvoice = null;
        PreparedStatement psUpdateField = null;
        ResultSet rsConflict = null;
        ResultSet rsField = null;

        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false); // Quản lý Transaction thủ công

            LocalDate today = LocalDate.now();
            LocalTime now = LocalTime.now();
            LocalTime endTime = now.plusMinutes(durationMinutes);

            // 1. Kiểm tra trạng thái sân bãi thực tế trước
            String sqlSelectField = "SELECT TenSan, TrangThai FROM San WITH (UPDLOCK, ROWLOCK) WHERE SanID = ?";
            psSelectField = conn.prepareStatement(sqlSelectField);
            psSelectField.setInt(1, sanId);
            rsField = psSelectField.executeQuery();

            if (!rsField.next()) {
                throw new CheckInException("Không tìm thấy thông tin sân có ID: " + sanId);
            }
            
            String tenSan = rsField.getString("TenSan");
            String trangThaiSan = rsField.getString("TrangThai");

            if (!FIELD_STATUS_AVAILABLE.equals(trangThaiSan)) {
                throw new FieldOccupiedException("Sân '" + tenSan + "' đang bận hoặc bảo trì (Trạng thái: " + trangThaiSan + "). Không thể mở cho khách vãng lai.");
            }

            // 2. Kịch bản Khách vãng lai bị kẹt lịch sắp tới (Walk-in Conflict Check)
            // Hệ thống kiểm tra xem trong khoảng thời gian khách chơi [now, endTime] có lịch đặt nào đã xác nhận không.
            // Công thức: GioBatDau < endTime AND GioKetThuc > now
            String sqlCheckConflict = "SELECT DatSanID, GioBatDau, GioKetThuc, TrangThai FROM LichDatSan " +
                                      "WHERE SanID = ? AND NgayDat = ? " +
                                      "AND (TrangThai IN (?, ?) OR (TrangThai = ? AND DATEDIFF(minute, CreatedTime, GETDATE()) <= " + org.example.util.Constants.PENDING_PAYMENT_TIMEOUT_MINUTES + ")) " +
                                      "AND GioBatDau < CAST(? AS time) AND GioKetThuc > CAST(? AS time)";
            psCheckConflict = conn.prepareStatement(sqlCheckConflict);
            psCheckConflict.setInt(1, sanId);
            psCheckConflict.setDate(2, Date.valueOf(today));
            psCheckConflict.setString(3, BOOKING_STATUS_CONFIRMED);
            psCheckConflict.setString(4, "Chờ xác nhận");
            psCheckConflict.setString(5, "Chờ thanh toán");
            psCheckConflict.setString(6, endTime.toString());
            psCheckConflict.setString(7, now.toString());

            rsConflict = psCheckConflict.executeQuery();
            if (rsConflict.next()) {
                Time conflictStart = rsConflict.getTime("GioBatDau");
                Time conflictEnd = rsConflict.getTime("GioKetThuc");
                throw new BookingConflictException("Sân '" + tenSan + "' đã có khách đặt online từ " + 
                        conflictStart.toLocalTime().toString().substring(0, 5) + " đến " + 
                        conflictEnd.toLocalTime().toString().substring(0, 5) + ". Không thể mở cho khách vãng lai lúc này!");
            }

            // Tính tiền dự kiến cho thời lượng chơi (durationMinutes)
            double hours = (double) durationMinutes / 60.0;
            BigDecimal totalAmount = BigDecimal.valueOf(hours * donGiaSan);

            // 3. Tạo mới lịch đặt sân cho khách vãng lai
            // Đối với giờ không cố định, ta gán GioKetThuc trong database lớn (ví dụ: cộng thêm 12 giờ) để tránh việc
            // updateExpiredBookingsAndFields() tự động kết thúc phiên chơi khi quá hạn ban đầu.
            LocalTime insertEndTime = endTime;
            if (ghiChu != null && ghiChu.contains("Không cố định")) {
                insertEndTime = now.plusHours(12);
                if (insertEndTime.isBefore(now)) {
                    insertEndTime = LocalTime.of(23, 59, 59);
                }
            }

            String timeMode = "FIXED_DURATION";
            Integer reservedMinutes = durationMinutes;
            if ("OPEN".equals(playMode)) {
                timeMode = "OPEN_ENDED";
                reservedMinutes = null;
            }

            String sqlInsertBooking = "INSERT INTO LichDatSan (AccountID, SanID, NgayDat, GioBatDau, GioKetThuc, actual_start_time, TrangThai, GhiChu, NguonDatSan, TongTienDuKien, TimeMode, ReservedDurationMinutes) " +
                                      "VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            psInsertBooking = conn.prepareStatement(sqlInsertBooking, Statement.RETURN_GENERATED_KEYS);
            psInsertBooking.setInt(1, sanId);
            psInsertBooking.setDate(2, Date.valueOf(today));
            psInsertBooking.setTime(3, Time.valueOf(now));
            psInsertBooking.setTime(4, Time.valueOf(insertEndTime));
            psInsertBooking.setTime(5, Time.valueOf(now));
            psInsertBooking.setString(6, BOOKING_STATUS_IN_USE);
            psInsertBooking.setString(7, ghiChu != null ? ghiChu : ("Khách vãng lai chơi " + durationMinutes + " phút"));
            psInsertBooking.setString(8, "Walk-in");
            psInsertBooking.setBigDecimal(9, totalAmount);
            psInsertBooking.setString(10, timeMode);
            if (reservedMinutes != null) {
                psInsertBooking.setInt(11, reservedMinutes);
            } else {
                psInsertBooking.setNull(11, java.sql.Types.INTEGER);
            }
            psInsertBooking.executeUpdate();

            // Lấy ID tự sinh của đơn đặt sân
            ResultSet rsKeys = psInsertBooking.getGeneratedKeys();
            int newDatSanId = -1;
            if (rsKeys.next()) {
                newDatSanId = rsKeys.getInt(1);
            } else {
                throw new CheckInException("Lỗi hệ thống: Không thể khởi tạo đơn đặt sân vãng lai.");
            }

            // 4. Khởi tạo Hóa đơn MAIN ngay tại quầy cho khách vãng lai.
            // Lưu ý: luôn để Chưa thanh toán cho đến khi thao tác trả sân/thanh toán hoàn tất.
            boolean hasLoaiHoaDon = columnExists(conn, "HoaDon", "LoaiHoaDon");
            String sqlInsertInvoice = hasLoaiHoaDon
                    ? "INSERT INTO HoaDon (DatSanID, AccountID_KhachHang, AccountID_NhanVien, NgayLap, TongTienSan, TongTienDichVu, PhiGuiXe, GiamGia, TongThanhToan, TrangThaiThanhToan, PhuongThucThanhToan, LoaiHoaDon) " +
                      "VALUES (?, NULL, ?, GETDATE(), ?, 0, 0, 0, ?, ?, NULL, N'MAIN')"
                    : "INSERT INTO HoaDon (DatSanID, AccountID_KhachHang, AccountID_NhanVien, NgayLap, TongTienSan, TongTienDichVu, PhiGuiXe, GiamGia, TongThanhToan, TrangThaiThanhToan, PhuongThucThanhToan) " +
                      "VALUES (?, NULL, ?, GETDATE(), ?, 0, 0, 0, ?, ?, NULL)";
            psInsertInvoice = conn.prepareStatement(sqlInsertInvoice);
            psInsertInvoice.setInt(1, newDatSanId);
            psInsertInvoice.setInt(2, staffAccountId);
            psInsertInvoice.setBigDecimal(3, totalAmount);
            psInsertInvoice.setBigDecimal(4, totalAmount);
            psInsertInvoice.setString(5, PAYMENT_STATUS_UNPAID); // Sẽ thanh toán khi check-out trả sân
            psInsertInvoice.executeUpdate();

            // 5. Cập nhật trạng thái sân (Điều kiện UPDATE ngặt nghèo chống Race Conditions)
            String sqlUpdateField = "UPDATE San SET TrangThai = ? WHERE SanID = ? AND TrangThai = ?";
            psUpdateField = conn.prepareStatement(sqlUpdateField);
            psUpdateField.setString(1, FIELD_STATUS_OCCUPIED);
            psUpdateField.setInt(2, sanId);
            psUpdateField.setString(3, FIELD_STATUS_AVAILABLE);

            int affectedRows = psUpdateField.executeUpdate();
            if (affectedRows == 0) {
                throw new ConcurrencyConflictException("Sân vừa bị thay đổi trạng thái bởi một giao dịch khác. Vui lòng làm tươi trang.");
            }

            // 6. Commit Transaction thành công
            conn.commit();
            logger.info("Đã mở sân thành công cho khách vãng lai tại sân ID: " + sanId);

        } catch (Exception e) {
            // Rollback nếu gặp bất cứ sự cố nào
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    logger.error("Failed to rollback walk-in transaction", ex);
                }
            }
            if (e instanceof CheckInException) {
                throw (CheckInException) e;
            } else {
                throw new CheckInException("Lỗi hệ thống khi mở sân cho khách vãng lai: " + e.getMessage());
            }
        } finally {
            closeResource(rsConflict);
            closeResource(rsField);
            closeResource(psCheckConflict);
            closeResource(psSelectField);
            closeResource(psInsertBooking);
            closeResource(psInsertInvoice);
            closeResource(psUpdateField);
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    logger.error("Failed to close connection", e);
                }
            }
        }
    }

    /**
     * Nghiệp vụ 3: Hủy đơn đặt sân do khách bùng / không đến sân (No-show Cancel)
     * 
     * @param datSanId ID đơn đặt sân cần hủy
     * @param staffAccountId ID nhân viên thực hiện hủy đơn
     * @throws CheckInException nếu có lỗi nghiệp vụ xảy ra
     */
    /**
     * Đánh dấu "khách bùng" (no-show) cho một đơn đặt trước. requiredCoSoId phải khớp cơ sở của
     * sân - khác cơ sở ném SecurityException (servlet trả 403), chống IDOR. Điều kiện đủ để
     * no-show do org.example.service.checkin.NoShowEligibility quyết định (trạng thái Đã xác nhận,
     * đúng ngày hôm nay, đã qua thời gian ân hạn NO_SHOW_GRACE_MINUTES). Dùng trạng thái riêng
     * "Không đến" (KHÔNG dùng lại "Đã hủy") và ghi NoShowAt. Không giải phóng sân - một booking
     * "Đã xác nhận" (chưa check-in) không hề chiếm sân, nên không có gì để giải phóng, và không
     * bao giờ được đụng vào San của một ca khác đang chơi. Không tự hủy hóa đơn nếu đã thanh
     * toán/cọc - chỉ tự hủy khi hóa đơn thực sự chưa thu tiền gì (an toàn, không mất dấu vết cần
     * hoàn tiền/giữ cọc thủ công).
     */
    public void huyLichKhachBung(int datSanId, int staffAccountId, int requiredCoSoId, String ipAddress) throws CheckInException {
        Connection conn = null;
        PreparedStatement psSelect = null;
        PreparedStatement psUpdateBooking = null;
        PreparedStatement psSelectInvoice = null;
        PreparedStatement psUpdateInvoice = null;
        ResultSet rs = null;
        ResultSet rsInvoice = null;

        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false); // Quản lý Transaction thủ công

            // 1. Khóa đơn đặt lịch + join San để xác minh cơ sở
            String sqlSelect = "SELECT l.TrangThai, l.GhiChu, l.NgayDat, l.GioBatDau, l.AccountID, s.CoSoID " +
                    "FROM LichDatSan l WITH (UPDLOCK, ROWLOCK) JOIN San s ON s.SanID = l.SanID WHERE l.DatSanID = ?";
            psSelect = conn.prepareStatement(sqlSelect);
            psSelect.setInt(1, datSanId);
            rs = psSelect.executeQuery();

            if (!rs.next()) {
                throw new CheckInException("Không tìm thấy thông tin đơn đặt sân có ID: " + datSanId);
            }

            int bookingCoSoId = rs.getInt("CoSoID");
            if (bookingCoSoId != requiredCoSoId) {
                throw new SecurityException("Đơn đặt sân không thuộc cơ sở của bạn.");
            }

            String trangThaiBooking = rs.getString("TrangThai");
            int customerAccountId = rs.getInt("AccountID");
            boolean hasCustomerAccount = !rs.wasNull();
            String ghiChu = rs.getString("GhiChu");
            java.time.LocalDate ngayDat = rs.getDate("NgayDat").toLocalDate();
            java.time.LocalTime gioBatDau = rs.getTime("GioBatDau").toLocalTime();

            org.example.service.checkin.NoShowEligibility.Result eligibility =
                    org.example.service.checkin.NoShowEligibility.check(trangThaiBooking, ngayDat, gioBatDau, java.time.LocalDateTime.now());
            if (!eligibility.eligible()) {
                throw new CheckInException(eligibility.message());
            }

            String logGhiChu = (ghiChu != null ? ghiChu.trim() : "") + " [Lễ tân đánh dấu khách không đến]";

            // 2. Cập nhật đơn đặt sân thành 'Không đến' - điều kiện WHERE giữ nguyên trạng thái nguồn
            // để chống race (đơn có thể vừa được check-in/hủy bởi request khác giữa lúc SELECT và UPDATE).
            String sqlUpdateBooking = "UPDATE LichDatSan SET TrangThai = ?, NoShowAt = GETDATE(), GhiChu = ? " +
                    "WHERE DatSanID = ? AND TrangThai = N'Đã xác nhận'";
            psUpdateBooking = conn.prepareStatement(sqlUpdateBooking);
            psUpdateBooking.setString(1, org.example.util.Constants.TRANG_THAI_DAT_SAN_KHONG_DEN);
            psUpdateBooking.setString(2, logGhiChu.trim());
            psUpdateBooking.setInt(3, datSanId);
            if (psUpdateBooking.executeUpdate() != 1) {
                throw new CheckInException("Trạng thái đơn đặt sân vừa thay đổi bởi một thao tác khác. Vui lòng tải lại.");
            }

            // 2b. Trừ điểm uy tín NO_SHOW - chỉ chạy khi booking thực sự vừa được đánh dấu ở bước trên
            // (nếu executeUpdate() != 1 đã throw ở trên, nên tới đây chắc chắn là lần đánh dấu đầu tiên).
            if (hasCustomerAccount) {
                org.example.service.reputation.CustomerReputationService.applyDelta(conn, customerAccountId, datSanId,
                        org.example.util.Constants.REPUTATION_ACTION_NO_SHOW, org.example.util.Constants.NO_SHOW_PENALTY,
                        "Khách không đến (No Show)", staffAccountId, ipAddress);
            }

            // 3. Hóa đơn MAIN: chỉ tự hủy nếu THỰC SỰ chưa thu tiền gì - nếu đã thanh toán/cọc,
            // không được tự đổi trạng thái, chỉ ghi chú để xử lý hoàn tiền/giữ cọc thủ công.
            String sqlSelectInvoice = "SELECT HoaDonID, TrangThaiThanhToan, GhiChu FROM HoaDon WHERE " + mainInvoiceWhereClause(conn, "DatSanID");
            psSelectInvoice = conn.prepareStatement(sqlSelectInvoice);
            psSelectInvoice.setInt(1, datSanId);
            rsInvoice = psSelectInvoice.executeQuery();
            if (rsInvoice.next()) {
                int hoaDonId = rsInvoice.getInt("HoaDonID");
                String invoiceStatus = rsInvoice.getString("TrangThaiThanhToan");
                String invoiceGhiChu = rsInvoice.getString("GhiChu");
                boolean unpaid = invoiceStatus == null
                        || PAYMENT_STATUS_UNPAID.equals(invoiceStatus)
                        || "Chưa cọc".equals(invoiceStatus);
                if (unpaid) {
                    String sqlCancelInvoice = "UPDATE HoaDon SET TrangThaiThanhToan = N'Đã hủy', AccountID_NhanVien = ?, NgayLap = GETDATE() WHERE HoaDonID = ?";
                    psUpdateInvoice = conn.prepareStatement(sqlCancelInvoice);
                    psUpdateInvoice.setInt(1, staffAccountId);
                    psUpdateInvoice.setInt(2, hoaDonId);
                    psUpdateInvoice.executeUpdate();
                } else {
                    String sqlFlagInvoice = "UPDATE HoaDon SET GhiChu = ? WHERE HoaDonID = ?";
                    psUpdateInvoice = conn.prepareStatement(sqlFlagInvoice);
                    psUpdateInvoice.setString(1, ((invoiceGhiChu != null ? invoiceGhiChu.trim() : "") +
                            " [Khách bùng - đã thu tiền, cần xử lý hoàn tiền/giữ cọc thủ công]").trim());
                    psUpdateInvoice.setInt(2, hoaDonId);
                    psUpdateInvoice.executeUpdate();

                    try (PreparedStatement psFlagBooking = conn.prepareStatement(
                            "UPDATE LichDatSan SET RequiresRefundReview = 1 WHERE DatSanID = ?")) {
                        psFlagBooking.setInt(1, datSanId);
                        psFlagBooking.executeUpdate();
                    }
                }
            }

            conn.commit();
            logger.info("Đã đánh dấu khách bùng cho đơn đặt sân ID " + datSanId);
        } catch (Exception e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    logger.error("Failed to rollback no-show transaction", ex);
                }
            }
            if (e instanceof SecurityException) {
                throw (SecurityException) e;
            } else if (e instanceof CheckInException) {
                throw (CheckInException) e;
            } else {
                throw new CheckInException("Lỗi hệ thống khi đánh dấu khách bùng: " + e.getMessage());
            }
        } finally {
            closeResource(rsInvoice);
            closeResource(rs);
            closeResource(psSelect);
            closeResource(psUpdateBooking);
            closeResource(psSelectInvoice);
            closeResource(psUpdateInvoice);
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    logger.error("Failed to close connection", e);
                }
            }
        }
    }

    /**
     * Lấy danh sách toàn bộ sân theo chi nhánh để hiển thị trên giao diện Lễ tân
     */
    public List<San> getDanhSachSan(int coSoId) {
        org.example.dao.impl.LichDatSanDAOImpl.updateExpiredBookingsAndFields();
        org.example.service.BookingLifecycleService.runExpirySweep();
        List<San> list = new ArrayList<>();
        // Ngưỡng "sắp có lịch đặt" dùng chung với cửa sổ check-in hợp lệ (CheckInWindow.MAX_EARLY_MINUTES) -
        // một sân không được coi là AVAILABLE nếu có booking "Đã xác nhận" sắp bắt đầu trong ngưỡng này.
        int upcomingWindowMinutes = org.example.service.checkin.CheckInWindow.MAX_EARLY_MINUTES;
        String sql = "SELECT s.SanID, s.TenSan, s.LoaiSanID, s.CoSoID, s.TrangThai, s.MoTa, s.HinhAnh, " +
                     "ls.TenLoai AS TenLoaiSan, ls.GiaKhongDen, ls.GiaCoDen, ls.GioBatDauLenDen, ls.GioKetThucLenDen, " +
                     "(SELECT TOP 1 lds.DatSanID FROM LichDatSan lds WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đang sử dụng') AS DatSanIDActive, " +
                     "(SELECT TOP 1 CONVERT(VARCHAR(5), COALESCE(lds.actual_start_time, lds.GioBatDau), 108) FROM LichDatSan lds WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đang sử dụng') AS GioBatDauActive, " +
                     "(SELECT TOP 1 CONVERT(VARCHAR(5), lds.GioKetThuc, 108) FROM LichDatSan lds WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đang sử dụng') AS GioKetThucActive, " +
                     "(SELECT TOP 1 lds.GhiChu FROM LichDatSan lds WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đang sử dụng') AS GhiChuActive, " +
                     "(SELECT TOP 1 CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioKetThuc AS DATETIME) FROM LichDatSan lds WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đang sử dụng') AS ScheduledEndActive, " +
                     "(SELECT TOP 1 CAST(lds.NgayDat AS DATETIME) + CAST(COALESCE(lds.actual_start_time, lds.GioBatDau) AS DATETIME) FROM LichDatSan lds WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đang sử dụng') AS ActualStartActive, " +
                     "(SELECT TOP 1 lds.NguonDatSan FROM LichDatSan lds WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đang sử dụng') AS NguonDatSanActive, " +
                     "(SELECT TOP 1 acc.FullName FROM LichDatSan lds LEFT JOIN Accounts acc ON lds.AccountID = acc.AccountID WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đang sử dụng') AS TenKhachHangActive, " +
                     "(SELECT TOP 1 acc.PhoneNumber FROM LichDatSan lds LEFT JOIN Accounts acc ON lds.AccountID = acc.AccountID WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đang sử dụng') AS SoDienThoaiActive, " +
                     "(SELECT TOP 1 lds.DatSanID FROM LichDatSan lds WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đã xác nhận' " +
                     "   AND lds.NgayDat = CAST(GETDATE() AS DATE) AND CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioBatDau AS DATETIME) >= GETDATE() " +
                     "   AND DATEDIFF(MINUTE, GETDATE(), CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioBatDau AS DATETIME)) <= " + upcomingWindowMinutes +
                     "   ORDER BY lds.GioBatDau ASC) AS NextDatSanId, " +
                     "(SELECT TOP 1 COALESCE(acc.FullName, N'Khách vãng lai') FROM LichDatSan lds LEFT JOIN Accounts acc ON lds.AccountID = acc.AccountID " +
                     "   WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đã xác nhận' AND lds.NgayDat = CAST(GETDATE() AS DATE) " +
                     "   AND CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioBatDau AS DATETIME) >= GETDATE() " +
                     "   AND DATEDIFF(MINUTE, GETDATE(), CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioBatDau AS DATETIME)) <= " + upcomingWindowMinutes +
                     "   ORDER BY lds.GioBatDau ASC) AS NextTenKhachHang, " +
                     "(SELECT TOP 1 acc.PhoneNumber FROM LichDatSan lds LEFT JOIN Accounts acc ON lds.AccountID = acc.AccountID " +
                     "   WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đã xác nhận' AND lds.NgayDat = CAST(GETDATE() AS DATE) " +
                     "   AND CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioBatDau AS DATETIME) >= GETDATE() " +
                     "   AND DATEDIFF(MINUTE, GETDATE(), CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioBatDau AS DATETIME)) <= " + upcomingWindowMinutes +
                     "   ORDER BY lds.GioBatDau ASC) AS NextSoDienThoai, " +
                     "(SELECT TOP 1 lds.NguonDatSan FROM LichDatSan lds WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đã xác nhận' " +
                     "   AND lds.NgayDat = CAST(GETDATE() AS DATE) AND CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioBatDau AS DATETIME) >= GETDATE() " +
                     "   AND DATEDIFF(MINUTE, GETDATE(), CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioBatDau AS DATETIME)) <= " + upcomingWindowMinutes +
                     "   ORDER BY lds.GioBatDau ASC) AS NextNguonDatSan, " +
                     "(SELECT TOP 1 CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioBatDau AS DATETIME) FROM LichDatSan lds WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đã xác nhận' " +
                     "   AND lds.NgayDat = CAST(GETDATE() AS DATE) AND CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioBatDau AS DATETIME) >= GETDATE() " +
                     "   AND DATEDIFF(MINUTE, GETDATE(), CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioBatDau AS DATETIME)) <= " + upcomingWindowMinutes +
                     "   ORDER BY lds.GioBatDau ASC) AS NextGioBatDau, " +
                     "(SELECT TOP 1 CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioKetThuc AS DATETIME) FROM LichDatSan lds WHERE lds.SanID = s.SanID AND lds.TrangThai = N'Đã xác nhận' " +
                     "   AND lds.NgayDat = CAST(GETDATE() AS DATE) AND CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioBatDau AS DATETIME) >= GETDATE() " +
                     "   AND DATEDIFF(MINUTE, GETDATE(), CAST(lds.NgayDat AS DATETIME) + CAST(lds.GioBatDau AS DATETIME)) <= " + upcomingWindowMinutes +
                     "   ORDER BY lds.GioBatDau ASC) AS NextGioKetThuc " +
                     "FROM San s " +
                     "LEFT JOIN LoaiSan ls ON s.LoaiSanID = ls.LoaiSanID " +
                     "WHERE s.CoSoID = ? AND s.IsDeleted = 0 " +
                     "ORDER BY s.SanID";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, coSoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    San s = new San();
                    s.setSanID(rs.getInt("SanID"));
                    s.setTenSan(rs.getString("TenSan"));
                    s.setLoaiSanID(rs.getInt("LoaiSanID"));
                    s.setCoSoID(rs.getInt("CoSoID"));
                    s.setTrangThai(rs.getString("TrangThai"));
                    s.setMoTa(rs.getString("MoTa"));
                    s.setHinhAnh(rs.getString("HinhAnh"));
                    s.setTenLoaiSan(rs.getString("TenLoaiSan"));
                    s.setGiaKhongDen(rs.getDouble("GiaKhongDen"));
                    s.setGiaCoDen(rs.getDouble("GiaCoDen"));
                    s.setGioBatDauLenDen(rs.getTime("GioBatDauLenDen") != null ? rs.getTime("GioBatDauLenDen").toLocalTime() : null);
                    s.setGioKetThucLenDen(rs.getTime("GioKetThucLenDen") != null ? rs.getTime("GioKetThucLenDen").toLocalTime() : null);
                    s.setDatSanIdActive(rs.getObject("DatSanIDActive") != null ? rs.getInt("DatSanIDActive") : null);
                    s.setGioBatDauActive(rs.getString("GioBatDauActive"));
                    s.setGioKetThucActive(rs.getString("GioKetThucActive"));
                    s.setGhiChuActive(rs.getString("GhiChuActive"));
                    s.setScheduledEndActive(rs.getTimestamp("ScheduledEndActive") != null ? rs.getTimestamp("ScheduledEndActive").toLocalDateTime() : null);
                    s.setActualStartActive(rs.getTimestamp("ActualStartActive") != null ? rs.getTimestamp("ActualStartActive").toLocalDateTime() : null);
                    s.setNguonDatSanActive(rs.getString("NguonDatSanActive"));
                    s.setTenKhachHangActive(rs.getString("TenKhachHangActive"));
                    s.setSoDienThoaiActive(rs.getString("SoDienThoaiActive"));
                    s.setNextDatSanId(rs.getObject("NextDatSanId") != null ? rs.getInt("NextDatSanId") : null);
                    s.setNextTenKhachHang(rs.getString("NextTenKhachHang"));
                    s.setNextSoDienThoai(rs.getString("NextSoDienThoai"));
                    s.setNextNguonDatSan(rs.getString("NextNguonDatSan"));
                    s.setNextGioBatDau(rs.getTimestamp("NextGioBatDau") != null ? rs.getTimestamp("NextGioBatDau").toLocalDateTime() : null);
                    s.setNextGioKetThuc(rs.getTimestamp("NextGioKetThuc") != null ? rs.getTimestamp("NextGioKetThuc").toLocalDateTime() : null);
                    list.add(s);
                }
            }
        } catch (Exception e) {
            logger.error("Error in getDanhSachSan: ", e);
        }
        return list;
    }

    /**
     * Lấy danh sách lịch đặt sân trong ngày hôm nay phục vụ check-in của chi nhánh
     */
    public List<BookingViewDTO> getDanhSachLichCheckInHomNay(int coSoId) {
        org.example.dao.impl.LichDatSanDAOImpl.updateExpiredBookingsAndFields();
        org.example.service.BookingLifecycleService.runExpirySweep();
        List<BookingViewDTO> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection()) {
            String invoiceJoin = columnExists(conn, "HoaDon", "LoaiHoaDon")
                    ? "LEFT JOIN HoaDon hd ON lds.DatSanID = hd.DatSanID AND (hd.LoaiHoaDon = N'MAIN' OR hd.LoaiHoaDon IS NULL) "
                    : "LEFT JOIN HoaDon hd ON lds.DatSanID = hd.DatSanID ";
            String sql = "SELECT lds.DatSanID, s.SanID, s.TenSan, acc.FullName AS TenKhachHang, acc.PhoneNumber AS SoDienThoai, " +
                         "ls.TenLoai AS TenLoaiSan, " +
                         "lds.NgayDat, lds.GioBatDau, lds.GioKetThuc, lds.TongTienDuKien, " +
                         "lds.TrangThai, lds.GhiChu, hd.TrangThaiThanhToan, lds.NguonDatSan, " +
                         "acc.DiemUyTin, acc.LateCancelCount, acc.NoShowCount " +
                         "FROM LichDatSan lds " +
                         "INNER JOIN San s ON lds.SanID = s.SanID " +
                         "LEFT JOIN LoaiSan ls ON s.LoaiSanID = ls.LoaiSanID " +
                         "LEFT JOIN Accounts acc ON lds.AccountID = acc.AccountID " +
                         invoiceJoin +
                         "WHERE lds.NgayDat = ? AND s.CoSoID = ? " +
                         // Check-in chỉ hiển thị đơn đủ điều kiện vận hành. LOẠI TRỪ triệt để:
                         //  - N'Chờ thanh toán' (PayOS chưa xác nhận qua webhook) — không được lộ ở quầy.
                         //  - N'Đã hủy' và N'Quá hạn' — đơn đã kết thúc, không có gì để check-in.
                         // GIỮ N'Chờ xác nhận' (trả tại quầy) để nhân viên mở sân/duyệt tại chỗ theo luồng hiện có.
                         "AND lds.TrangThai IN (" +
                         "N'" + org.example.util.Constants.TRANG_THAI_DAT_SAN_CHO_XAC_NHAN + "', " +
                         "N'" + org.example.util.Constants.TRANG_THAI_DAT_SAN_DA_XAC_NHAN + "', " +
                         "N'" + org.example.util.Constants.TRANG_THAI_DAT_SAN_DANG_SU_DUNG + "', " +
                         "N'" + org.example.util.Constants.TRANG_THAI_DAT_SAN_DA_HOAN_THANH + "', " +
                         "N'" + org.example.util.Constants.TRANG_THAI_DAT_SAN_KHONG_DEN + "') " +
                         "ORDER BY lds.GioBatDau ASC";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setDate(1, java.sql.Date.valueOf(LocalDate.now()));
                ps.setInt(2, coSoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    BookingViewDTO dto = new BookingViewDTO();
                    dto.setDatSanId(rs.getInt("DatSanID"));
                    dto.setSanId(rs.getInt("SanID"));
                    dto.setTenSan(rs.getString("TenSan"));
                    String guestName = rs.getString("TenKhachHang");
                    dto.setTenKhachHang(guestName != null ? guestName : "Khách vãng lai");
                    dto.setSoDienThoai(rs.getString("SoDienThoai"));
                    dto.setTenLoaiSan(rs.getString("TenLoaiSan"));
                    dto.setNgayDat(rs.getDate("NgayDat").toLocalDate());
                    dto.setGioBatDau(rs.getTime("GioBatDau").toLocalTime());
                    dto.setGioKetThuc(rs.getTime("GioKetThuc").toLocalTime());
                    dto.setTongTien(rs.getBigDecimal("TongTienDuKien"));
                    dto.setTrangThai(rs.getString("TrangThai"));
                    dto.setGhiChu(rs.getString("GhiChu"));
                    String paymentStatus = rs.getString("TrangThaiThanhToan");
                    dto.setTrangThaiThanhToan(paymentStatus != null ? paymentStatus : PAYMENT_STATUS_UNPAID);
                    String nguonDat = rs.getString("NguonDatSan");
                    dto.setNguonDatSan(nguonDat != null ? nguonDat : "Walk-in");
                    int diemUyTin = rs.getInt("DiemUyTin");
                    if (!rs.wasNull()) {
                        dto.setReputationScore(diemUyTin);
                        dto.setReputationLabel(org.example.service.reputation.ReputationLabel.of(diemUyTin));
                        dto.setLateCancelCount(rs.getInt("LateCancelCount"));
                        dto.setNoShowCount(rs.getInt("NoShowCount"));
                    }
                    list.add(dto);
                }
            }
            }
        } catch (Exception e) {
            logger.error("Error in getDanhSachLichCheckInHomNay: ", e);
        }
        return list;
    }

    /**
     * DTO hiển thị danh sách lịch đặt trên giao diện lễ tân
     */
    public static class BookingViewDTO {
        private int datSanId;
        private int sanId;
        private String tenSan;
        private String tenKhachHang;
        private String soDienThoai;
        private String tenLoaiSan;
        private LocalDate ngayDat;
        private LocalTime gioBatDau;
        private LocalTime gioKetThuc;
        private BigDecimal tongTien;
        private String trangThai;
        private String ghiChu;
        private String trangThaiThanhToan;
        private String nguonDatSan;

        public int getDatSanId() { return datSanId; }
        public void setDatSanId(int datSanId) { this.datSanId = datSanId; }

        public int getSanId() { return sanId; }
        public void setSanId(int sanId) { this.sanId = sanId; }

        public String getTenSan() { return tenSan; }
        public void setTenSan(String tenSan) { this.tenSan = tenSan; }

        public String getTenKhachHang() { return tenKhachHang; }
        public void setTenKhachHang(String tenKhachHang) { this.tenKhachHang = tenKhachHang; }

        public String getSoDienThoai() { return soDienThoai; }
        public void setSoDienThoai(String soDienThoai) { this.soDienThoai = soDienThoai; }

        public String getTenLoaiSan() { return tenLoaiSan; }
        public void setTenLoaiSan(String tenLoaiSan) { this.tenLoaiSan = tenLoaiSan; }

        public LocalDate getNgayDat() { return ngayDat; }
        public void setNgayDat(LocalDate ngayDat) { this.ngayDat = ngayDat; }

        public LocalTime getGioBatDau() { return gioBatDau; }
        public void setGioBatDau(LocalTime gioBatDau) { this.gioBatDau = gioBatDau; }

        public LocalTime getGioKetThuc() { return gioKetThuc; }
        public void setGioKetThuc(LocalTime gioKetThuc) { this.gioKetThuc = gioKetThuc; }

        public BigDecimal getTongTien() { return tongTien; }
        public void setTongTien(BigDecimal tongTien) { this.tongTien = tongTien; }

        public String getTrangThai() { return trangThai; }
        public void setTrangThai(String trangThai) { this.trangThai = trangThai; }

        public String getGhiChu() { return ghiChu; }
        public void setGhiChu(String ghiChu) { this.ghiChu = ghiChu; }

        public String getTrangThaiThanhToan() { return trangThaiThanhToan; }
        public void setTrangThaiThanhToan(String trangThaiThanhToan) { this.trangThaiThanhToan = trangThaiThanhToan; }

        public String getNguonDatSan() { return nguonDatSan; }
        public void setNguonDatSan(String nguonDatSan) { this.nguonDatSan = nguonDatSan; }

        private Integer reputationScore;
        private String reputationLabel;
        private Integer lateCancelCount;
        private Integer noShowCount;

        public Integer getReputationScore() { return reputationScore; }
        public void setReputationScore(Integer reputationScore) { this.reputationScore = reputationScore; }

        public String getReputationLabel() { return reputationLabel; }
        public void setReputationLabel(String reputationLabel) { this.reputationLabel = reputationLabel; }

        public Integer getLateCancelCount() { return lateCancelCount; }
        public void setLateCancelCount(Integer lateCancelCount) { this.lateCancelCount = lateCancelCount; }

        public Integer getNoShowCount() { return noShowCount; }
        public void setNoShowCount(Integer noShowCount) { this.noShowCount = noShowCount; }
    }

    /**
     * Tạo hóa đơn tách (split bill) riêng biệt cho dịch vụ, không ảnh hưởng hóa đơn sân chính.
     * Yêu cầu DB đã có cột LoaiHoaDon, ParentHoaDonID, GhiChu trên bảng HoaDon.
     *
     * @return HoaDonID của split bill vừa tạo
     */
    public int addServicesSplitBill(int datSanId, int[] productIds, int[] quantities,
                                     boolean payNow, String paymentMethod, int staffAccountId,
                                     int requiredCoSoId) throws Exception {
        if (productIds == null || quantities == null || productIds.length != quantities.length) {
            throw new CheckInException("Dữ liệu đầu vào không hợp lệ.");
        }
        if (productIds.length == 0) {
            throw new CheckInException("Vui lòng chọn ít nhất một sản phẩm.");
        }

        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // 1. Xác minh booking đang sử dụng và thuộc chi nhánh
            int coSoIdFromDB;
            Integer customerAccountId = null;
            String sqlBooking = "SELECT s.CoSoID, lds.AccountID, lds.TrangThai " +
                                "FROM LichDatSan lds INNER JOIN San s ON lds.SanID = s.SanID " +
                                "WHERE lds.DatSanID = ?";
            try (PreparedStatement ps = conn.prepareStatement(sqlBooking)) {
                ps.setInt(1, datSanId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new CheckInException("Không tìm thấy đơn đặt sân.");
                    coSoIdFromDB = rs.getInt("CoSoID");
                    if (coSoIdFromDB != requiredCoSoId) {
                        throw new CheckInException("Đơn đặt sân không thuộc cơ sở của bạn.");
                    }
                    if (!"Đang sử dụng".equals(rs.getString("TrangThai"))) {
                        throw new CheckInException("Chỉ thêm dịch vụ khi sân đang sử dụng.");
                    }
                    int accId = rs.getInt("AccountID");
                    if (!rs.wasNull()) customerAccountId = accId;
                }
            }

            // 2. Lấy HoaDonID của main invoice để làm ParentHoaDonID
            int parentHoaDonId = -1;
            boolean hasLoaiHoaDon = columnExists(conn, "HoaDon", "LoaiHoaDon");
            boolean hasParentHoaDonID = columnExists(conn, "HoaDon", "ParentHoaDonID");
            boolean hasGhiChu = columnExists(conn, "HoaDon", "GhiChu");
            if (!hasLoaiHoaDon) {
                throw new CheckInException("Database chưa có cột LoaiHoaDon nên chưa hỗ trợ tách bill dịch vụ. Vui lòng chạy script /sql/migration_hoadon_loai.sql hoặc thêm dịch vụ vào hóa đơn chính.");
            }

            String sqlMain = "SELECT HoaDonID FROM HoaDon WHERE " + mainInvoiceWhereClause(conn, "DatSanID");
            try (PreparedStatement ps = conn.prepareStatement(sqlMain)) {
                ps.setInt(1, datSanId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) parentHoaDonId = rs.getInt("HoaDonID");
                }
            }

            // 3. Lấy đơn giá và kiểm tra tồn kho sản phẩm
            double totalDichVu = 0.0;
            int[][] validItems = new int[productIds.length][2]; // [qty, confirmed]
            double[] donGias = new double[productIds.length];

            String sqlGetProduct = "SELECT TenSanPham, DonGia, SoLuongTon, CoSoID, TrangThai " +
                                   "FROM SanPham_DichVu WITH (UPDLOCK, ROWLOCK) WHERE SanPhamID = ?";
            try (PreparedStatement psGetProd = conn.prepareStatement(sqlGetProduct)) {
                for (int i = 0; i < productIds.length; i++) {
                    int qty = quantities[i];
                    if (qty <= 0) continue;
                    psGetProd.setInt(1, productIds[i]);
                    try (ResultSet rs = psGetProd.executeQuery()) {
                        if (!rs.next()) throw new CheckInException("Không tìm thấy sản phẩm ID: " + productIds[i]);
                        String tenSp = rs.getNString("TenSanPham");
                        if (rs.getInt("CoSoID") != coSoIdFromDB)
                            throw new CheckInException("Sản phẩm '" + tenSp + "' không thuộc chi nhánh này.");
                        if (!"Đang kinh doanh".equals(rs.getString("TrangThai")))
                            throw new CheckInException("Sản phẩm '" + tenSp + "' ngừng kinh doanh.");
                        int stock = rs.getInt("SoLuongTon");
                        if (stock < qty)
                            throw new CheckInException("Sản phẩm '" + tenSp + "' không đủ tồn kho (còn: " + stock + ").");
                        donGias[i] = rs.getDouble("DonGia");
                        totalDichVu += qty * donGias[i];
                        validItems[i][0] = qty;
                        validItems[i][1] = 1;
                    }
                }
            }

            if (totalDichVu <= 0) throw new CheckInException("Không có sản phẩm hợp lệ để lập hóa đơn tách.");

            // 4. Tạo split HoaDon
            String trangThai = payNow ? "Đã thanh toán" : "Chưa thanh toán";
            String phuongThuc = (payNow && paymentMethod != null) ? paymentMethod : null;
            String ghiChu = "Tách bill dịch vụ";

            String sqlInsertHD;
            if (parentHoaDonId > 0 && hasParentHoaDonID && hasGhiChu) {
                sqlInsertHD = "INSERT INTO HoaDon (DatSanID, AccountID_KhachHang, AccountID_NhanVien, NgayLap, " +
                              "TongTienSan, TongTienDichVu, PhiGuiXe, GiamGia, TongThanhToan, " +
                              "TrangThaiThanhToan, PhuongThucThanhToan, LoaiHoaDon, ParentHoaDonID, GhiChu) " +
                              "VALUES (?, ?, ?, GETDATE(), 0, ?, 0, 0, ?, ?, ?, N'SPLIT', ?, ?)";
            } else if (hasGhiChu) {
                sqlInsertHD = "INSERT INTO HoaDon (DatSanID, AccountID_KhachHang, AccountID_NhanVien, NgayLap, " +
                              "TongTienSan, TongTienDichVu, PhiGuiXe, GiamGia, TongThanhToan, " +
                              "TrangThaiThanhToan, PhuongThucThanhToan, LoaiHoaDon, GhiChu) " +
                              "VALUES (?, ?, ?, GETDATE(), 0, ?, 0, 0, ?, ?, ?, N'SPLIT', ?)";
            } else {
                sqlInsertHD = "INSERT INTO HoaDon (DatSanID, AccountID_KhachHang, AccountID_NhanVien, NgayLap, " +
                              "TongTienSan, TongTienDichVu, PhiGuiXe, GiamGia, TongThanhToan, " +
                              "TrangThaiThanhToan, PhuongThucThanhToan, LoaiHoaDon) " +
                              "VALUES (?, ?, ?, GETDATE(), 0, ?, 0, 0, ?, ?, ?, N'SPLIT')";
            }

            int splitHoaDonId;
            try (PreparedStatement psHD = conn.prepareStatement(sqlInsertHD, Statement.RETURN_GENERATED_KEYS)) {
                psHD.setInt(1, datSanId);
                if (customerAccountId != null) psHD.setInt(2, customerAccountId);
                else psHD.setNull(2, Types.INTEGER);
                psHD.setInt(3, staffAccountId);
                psHD.setDouble(4, totalDichVu);
                psHD.setDouble(5, totalDichVu);
                psHD.setNString(6, trangThai);
                if (phuongThuc != null) psHD.setString(7, phuongThuc);
                else psHD.setNull(7, Types.NVARCHAR);
                if (parentHoaDonId > 0 && hasParentHoaDonID && hasGhiChu) {
                    psHD.setInt(8, parentHoaDonId);
                    psHD.setNString(9, ghiChu);
                } else if (hasGhiChu) {
                    psHD.setNString(8, ghiChu);
                }
                psHD.executeUpdate();
                try (ResultSet keys = psHD.getGeneratedKeys()) {
                    if (!keys.next()) throw new CheckInException("Không thể tạo hóa đơn tách.");
                    splitHoaDonId = keys.getInt(1);
                }
            }

            // 5. Thêm chi tiết và giảm tồn kho
            String sqlInsertCT = "INSERT INTO ChiTietHoaDon (HoaDonID, SanPhamID, SoLuong, DonGiaTaiThoiDiemBan, ThanhTien) " +
                                  "VALUES (?, ?, ?, ?, ?)";
            String sqlStock = "UPDATE SanPham_DichVu SET SoLuongTon = SoLuongTon - ? WHERE SanPhamID = ?";
            try (PreparedStatement psInsertCT = conn.prepareStatement(sqlInsertCT);
                 PreparedStatement psStock = conn.prepareStatement(sqlStock)) {
                for (int i = 0; i < productIds.length; i++) {
                    if (validItems[i][1] != 1) continue;
                    int qty = validItems[i][0];
                    psStock.setInt(1, qty);
                    psStock.setInt(2, productIds[i]);
                    psStock.executeUpdate();

                    psInsertCT.setInt(1, splitHoaDonId);
                    psInsertCT.setInt(2, productIds[i]);
                    psInsertCT.setInt(3, qty);
                    psInsertCT.setDouble(4, donGias[i]);
                    psInsertCT.setDouble(5, qty * donGias[i]);
                    psInsertCT.executeUpdate();
                }
            }

            conn.commit();
            return splitHoaDonId;
        } catch (Exception e) {
            if (conn != null) { try { conn.rollback(); } catch (Exception ignored) {} }
            logger.error("Lỗi addServicesSplitBill datSanId={}: {}", datSanId, e.getMessage(), e);
            throw e;
        } finally {
            if (conn != null) { try { conn.setAutoCommit(true); conn.close(); } catch (Exception ignored) {} }
        }
    }

    /**
     * Thanh toán một hóa đơn cụ thể (dùng cho split bills).
     * Xác minh hóa đơn thuộc chi nhánh và chưa thanh toán trước khi cập nhật.
     */
    public void payInvoice(int hoaDonId, int staffAccountId, String paymentMethod, int requiredCoSoId) throws Exception {
        if (paymentMethod == null || paymentMethod.trim().isEmpty()) {
            throw new CheckInException("Phương thức thanh toán không được để trống.");
        }
        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // Xác minh hóa đơn thuộc chi nhánh, chưa thanh toán và là SPLIT bill dịch vụ.
            // Hóa đơn MAIN của tiền sân phải đi qua processPayment để cập nhật đồng bộ booking + sân.
            boolean hasLoaiHoaDon = columnExists(conn, "HoaDon", "LoaiHoaDon");
            String sqlCheck = "SELECT hd.TrangThaiThanhToan, s.CoSoID, " +
                              (hasLoaiHoaDon ? "hd.LoaiHoaDon" : "CAST(NULL AS NVARCHAR(50))") + " AS LoaiHoaDon " +
                              "FROM HoaDon hd " +
                              "INNER JOIN LichDatSan lds ON hd.DatSanID = lds.DatSanID " +
                              "INNER JOIN San s ON lds.SanID = s.SanID " +
                              "WHERE hd.HoaDonID = ?";
            try (PreparedStatement ps = conn.prepareStatement(sqlCheck)) {
                ps.setInt(1, hoaDonId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new CheckInException("Không tìm thấy hóa đơn #" + hoaDonId);
                    if (rs.getInt("CoSoID") != requiredCoSoId)
                        throw new CheckInException("Hóa đơn không thuộc cơ sở của bạn.");
                    if ("Đã thanh toán".equals(rs.getString("TrangThaiThanhToan")))
                        throw new CheckInException("Hóa đơn này đã được thanh toán.");
                    String loaiHoaDon = rs.getString("LoaiHoaDon");
                    if (!hasLoaiHoaDon || loaiHoaDon == null || !"SPLIT".equalsIgnoreCase(loaiHoaDon)) {
                        throw new CheckInException("Hóa đơn sân chính phải thanh toán bằng nút Trả sân/Thanh toán để cập nhật đồng bộ trạng thái sân và lịch đặt.");
                    }
                }
            }

            String sqlPay = "UPDATE HoaDon SET TrangThaiThanhToan = N'Đã thanh toán', " +
                            "PhuongThucThanhToan = ?, AccountID_NhanVien = ?, NgayLap = GETDATE() " +
                            "WHERE HoaDonID = ?";
            try (PreparedStatement ps = conn.prepareStatement(sqlPay)) {
                ps.setString(1, paymentMethod.trim());
                ps.setInt(2, staffAccountId);
                ps.setInt(3, hoaDonId);
                if (ps.executeUpdate() == 0) throw new CheckInException("Cập nhật hóa đơn thất bại.");
            }

            conn.commit();
        } catch (Exception e) {
            if (conn != null) { try { conn.rollback(); } catch (Exception ignored) {} }
            logger.error("Lỗi payInvoice hoaDonId={}: {}", hoaDonId, e.getMessage(), e);
            throw e;
        } finally {
            if (conn != null) { try { conn.setAutoCommit(true); conn.close(); } catch (Exception ignored) {} }
        }
    }

    /**
     * Kiểm tra xem có hóa đơn tách chưa thanh toán thuộc đơn đặt sân này không.
     * Dùng để chặn checkout khi còn split bill chưa trả.
     */
    public boolean hasUnpaidSplitBills(int datSanId) {
        try (Connection conn = DBUtil.getConnection()) {
            if (!columnExists(conn, "HoaDon", "LoaiHoaDon")) {
                return false;
            }
            String sql = "SELECT COUNT(*) FROM HoaDon WHERE DatSanID = ? AND LoaiHoaDon = N'SPLIT' AND TrangThaiThanhToan = N'Chưa thanh toán'";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, datSanId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) > 0;
            }
            }
        } catch (Exception e) {
            logger.error("Lỗi hasUnpaidSplitBills datSanId={}: {}", datSanId, e.getMessage(), e);
        }
        return false;
    }

    public void applyEarlyCheckoutAdjustment(int datSanId, double discountAmount, String reason, int staffAccountId, int coSoId) throws CheckInException {
        Connection conn = null;
        PreparedStatement psSelect = null;
        PreparedStatement psUpdateBooking = null;
        PreparedStatement psUpdateInvoice = null;
        ResultSet rs = null;

        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // 1. Kiểm tra ca chơi và cơ sở
            String sqlSelect = "SELECT lds.SanID, lds.TrangThai, lds.TongTienDuKien, s.CoSoID " +
                               "FROM LichDatSan lds " +
                               "INNER JOIN San s ON lds.SanID = s.SanID " +
                               "WHERE lds.DatSanID = ?";
            psSelect = conn.prepareStatement(sqlSelect);
            psSelect.setInt(1, datSanId);
            rs = psSelect.executeQuery();

            if (!rs.next()) {
                throw new CheckInException("Không tìm thấy ca chơi có ID: " + datSanId);
            }

            String trangThai = rs.getString("TrangThai");
            int sanCoSoId = rs.getInt("CoSoID");
            BigDecimal tongTienDuKien = rs.getBigDecimal("TongTienDuKien");

            if (sanCoSoId != coSoId) {
                throw new CheckInException("Bạn không có quyền quản lý ca chơi thuộc cơ sở khác.");
            }
            if (!"Đang sử dụng".equals(trangThai)) {
                throw new CheckInException("Chỉ được áp dụng giảm trừ cho ca chơi đang ở trạng thái 'Đang sử dụng'.");
            }
            if (discountAmount < 0) {
                throw new CheckInException("Số tiền giảm trừ không hợp lệ.");
            }
            if (discountAmount > tongTienDuKien.doubleValue()) {
                throw new CheckInException("Số tiền giảm trừ không được lớn hơn tổng số tiền của ca chơi.");
            }

            // 2. Cập nhật giảm trừ trong LichDatSan
            String sqlUpdateBooking = "UPDATE LichDatSan SET EarlyCheckoutDiscount = ?, EarlyCheckoutReason = ?, TongTienDuKien = TongTienDuKien - ? WHERE DatSanID = ?";
            psUpdateBooking = conn.prepareStatement(sqlUpdateBooking);
            psUpdateBooking.setBigDecimal(1, BigDecimal.valueOf(discountAmount));
            psUpdateBooking.setNString(2, reason);
            psUpdateBooking.setBigDecimal(3, BigDecimal.valueOf(discountAmount));
            psUpdateBooking.setInt(4, datSanId);
            psUpdateBooking.executeUpdate();

            // 3. Cập nhật tổng tiền trong HoaDon
            String sqlUpdateInvoice = "UPDATE HoaDon SET TongTienSan = TongTienSan - ?, GiamGia = GiamGia + ?, TongThanhToan = TongThanhToan - ? WHERE " + mainInvoiceWhereClause(conn, "DatSanID");
            psUpdateInvoice = conn.prepareStatement(sqlUpdateInvoice);
            psUpdateInvoice.setBigDecimal(1, BigDecimal.valueOf(discountAmount));
            psUpdateInvoice.setBigDecimal(2, BigDecimal.valueOf(discountAmount));
            psUpdateInvoice.setBigDecimal(3, BigDecimal.valueOf(discountAmount));
            psUpdateInvoice.setInt(4, datSanId);
            psUpdateInvoice.executeUpdate();

            conn.commit();
        } catch (Exception e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { logger.error("Failed to rollback early checkout adjustment", ex); }
            }
            if (e instanceof CheckInException) {
                throw (CheckInException) e;
            } else {
                throw new CheckInException("Lỗi hệ thống khi giảm trừ trả sân sớm: " + e.getMessage());
            }
        } finally {
            closeResource(rs);
            closeResource(psSelect);
            closeResource(psUpdateBooking);
            closeResource(psUpdateInvoice);
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    logger.error("Failed to close connection", e);
                }
            }
        }
    }

    /**
     * Phương thức phụ trợ đóng Resource JDBC
     */
    private void closeResource(AutoCloseable resource) {
        if (resource != null) {
            try {
                resource.close();
            } catch (Exception e) {
                logger.error("Error closing JDBC resource", e);
            }
        }
    }
}
