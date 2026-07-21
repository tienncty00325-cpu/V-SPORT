package org.example.service.checkin;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.service.pricing.CourtPricingService;
import org.example.service.pricing.CourtPriceResult;
import org.example.util.DBUtil;

import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

public class BookingExtensionService {
    private static final Logger logger = LogManager.getLogger(BookingExtensionService.class);
    private final CourtPricingService courtPricingService = new CourtPricingService();

    public static class ExtensionPreview {
        public int datSanId;
        public int sanId;
        public String tenSan;
        public LocalTime oldGioKetThuc;
        public LocalTime newGioKetThuc;
        public LocalDateTime oldPlannedEnd;
        public LocalDateTime newPlannedEnd;
        public BigDecimal oldTotalCourtAmount;
        public BigDecimal newTotalCourtAmount;
        public BigDecimal additionalAmount;
        public LocalDateTime limitDateTime;
        public long maxExtendableMinutes;
        public boolean canExtend;
        public String message;
    }

    public static class ExtensionResult {
        public boolean success;
        public String message;
        public BigDecimal additionalAmount;
        public LocalTime newGioKetThuc;
    }

    public ExtensionPreview previewExtension(int datSanId, Integer extendMinutes, LocalTime proposedNewEndTime, int coSoId) {
        ExtensionPreview preview = new ExtensionPreview();
        preview.datSanId = datSanId;
        preview.canExtend = false;

        String sqlBooking = "SELECT l.DatSanID, l.SanID, l.NgayDat, l.GioBatDau, l.GioKetThuc, l.TrangThai, l.TimeMode, " +
                "l.actual_start_time, l.ActualStartAt, l.ReservedDurationMinutes, " +
                "s.TenSan, s.CoSoID, s.TrangThai AS SanTrangThai, ls.GiaKhongDen, ls.GiaCoDen, ls.GioBatDauLenDen, ls.GioKetThucLenDen " +
                "FROM LichDatSan l " +
                "JOIN San s ON l.SanID = s.SanID " +
                "JOIN LoaiSan ls ON s.LoaiSanID = ls.LoaiSanID " +
                "WHERE l.DatSanID = ? AND l.IsDeleted = 0";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sqlBooking)) {
            ps.setInt(1, datSanId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    preview.message = "Không tìm thấy thông tin đơn đặt sân.";
                    return preview;
                }

                int bookingCoSoId = rs.getInt("CoSoID");
                if (bookingCoSoId != coSoId) {
                    preview.message = "Đơn đặt sân không thuộc cơ sở của bạn.";
                    return preview;
                }

                String bookingTrangThai = rs.getString("TrangThai");
                if (!"Đang sử dụng".equals(bookingTrangThai)) {
                    preview.message = "Chỉ ca chơi ở trạng thái 'Đang sử dụng' mới có thể gia hạn.";
                    return preview;
                }

                String timeMode = rs.getString("TimeMode");
                if ("OPEN_ENDED".equals(timeMode)) {
                    preview.message = "Walk-in không cố định chạy đến khi dừng, không cần gia hạn.";
                    return preview;
                }

                int sanId = rs.getInt("SanID");
                preview.sanId = sanId;
                preview.tenSan = rs.getString("TenSan");
                LocalDate date = rs.getDate("NgayDat").toLocalDate();
                LocalTime oldGioKetThuc = rs.getTime("GioKetThuc").toLocalTime();
                preview.oldGioKetThuc = oldGioKetThuc;

                // 1. Xác định startAt
                LocalDateTime startAt = null;
                Timestamp ts = rs.getTimestamp("ActualStartAt");
                if (ts != null) {
                    startAt = ts.toLocalDateTime();
                }
                if (startAt == null) {
                    Time t = rs.getTime("actual_start_time");
                    if (t != null) {
                        startAt = date.atTime(t.toLocalTime());
                    }
                }
                if (startAt == null) {
                    startAt = date.atTime(rs.getTime("GioBatDau").toLocalTime());
                }

                // 2. Xác định oldPlannedEnd
                LocalDateTime oldPlannedEnd = date.atTime(oldGioKetThuc);
                if (!oldPlannedEnd.isAfter(startAt)) {
                    oldPlannedEnd = oldPlannedEnd.plusDays(1);
                }
                preview.oldPlannedEnd = oldPlannedEnd;

                // 3. Tìm limitDateTime (booking tiếp theo hoặc đóng cửa)
                LocalDateTime nextBookingStart = null;
                String sqlNext = "SELECT DatSanID, NgayDat, GioBatDau, GioKetThuc, TrangThai, HoldExpiresAt FROM LichDatSan " +
                        "WHERE SanID = ? AND IsDeleted = 0 AND DatSanID <> ? " +
                        "AND (NgayDat = ? OR NgayDat = ?) " +
                        "AND (TrangThai IN (N'Đã xác nhận', N'Chờ xác nhận', N'Đang sử dụng') " +
                        "     OR (TrangThai = N'Chờ thanh toán' AND HoldExpiresAt > SYSUTCDATETIME()))";
                try (PreparedStatement psNext = conn.prepareStatement(sqlNext)) {
                    psNext.setInt(1, sanId);
                    psNext.setInt(2, datSanId);
                    psNext.setDate(3, Date.valueOf(date));
                    psNext.setDate(4, Date.valueOf(date.plusDays(1)));
                    try (ResultSet rsNext = psNext.executeQuery()) {
                        while (rsNext.next()) {
                            LocalDate nextDate = rsNext.getDate("NgayDat").toLocalDate();
                            LocalTime nextStartTime = rsNext.getTime("GioBatDau").toLocalTime();
                            LocalDateTime startTemp = nextDate.atTime(nextStartTime);
                            if (!startTemp.isBefore(oldPlannedEnd)) {
                                if (nextBookingStart == null || startTemp.isBefore(nextBookingStart)) {
                                    nextBookingStart = startTemp;
                                }
                            }
                        }
                    }
                }

                LocalDateTime closeTime = null;
                String sqlCoSo = "SELECT GioDongCua FROM CoSo WHERE CoSoID = ?";
                try (PreparedStatement psCoSo = conn.prepareStatement(sqlCoSo)) {
                    psCoSo.setInt(1, coSoId);
                    try (ResultSet rsCoSo = psCoSo.executeQuery()) {
                        if (rsCoSo.next()) {
                            Time dbClose = rsCoSo.getTime("GioDongCua");
                            if (dbClose != null) {
                                closeTime = date.atTime(dbClose.toLocalTime());
                                if (dbClose.toLocalTime().isBefore(startAt.toLocalTime())) {
                                    closeTime = closeTime.plusDays(1);
                                }
                            }
                        }
                    }
                }

                LocalDateTime limitDateTime = null;
                if (nextBookingStart != null && closeTime != null) {
                    limitDateTime = nextBookingStart.isBefore(closeTime) ? nextBookingStart : closeTime;
                } else if (nextBookingStart != null) {
                    limitDateTime = nextBookingStart;
                } else if (closeTime != null) {
                    limitDateTime = closeTime;
                } else {
                    limitDateTime = oldPlannedEnd.plusHours(6); // Fallback limit
                }
                preview.limitDateTime = limitDateTime;

                // 4. Xác định baseEnd cho gia hạn (overtime check)
                LocalDateTime nowDateTime = LocalDateTime.now();
                LocalDateTime baseEnd = oldPlannedEnd;
                if (nowDateTime.isAfter(oldPlannedEnd)) {
                    baseEnd = nowDateTime;
                }

                // 5. Tính maxExtendableMinutes
                long maxExtendableMinutes = 0;
                if (limitDateTime.isAfter(baseEnd)) {
                    maxExtendableMinutes = Duration.between(baseEnd, limitDateTime).toMinutes();
                }
                preview.maxExtendableMinutes = maxExtendableMinutes;

                if (extendMinutes == null && proposedNewEndTime == null) {
                    preview.canExtend = maxExtendableMinutes > 0;
                    preview.message = preview.canExtend ? "Có thể gia hạn chơi thêm." : "Sân đã có lịch đặt tiếp theo hoặc đã đóng cửa.";
                    return preview;
                }

                // 6. Tính newPlannedEnd
                LocalDateTime newPlannedEnd = null;
                if (extendMinutes != null) {
                    newPlannedEnd = baseEnd.plusMinutes(extendMinutes);
                } else {
                    newPlannedEnd = date.atTime(proposedNewEndTime);
                    if (!newPlannedEnd.isAfter(baseEnd)) {
                        newPlannedEnd = newPlannedEnd.plusDays(1);
                    }
                }
                preview.newPlannedEnd = newPlannedEnd;
                preview.newGioKetThuc = newPlannedEnd.toLocalTime();

                // 7. Validations
                if (!newPlannedEnd.isAfter(baseEnd)) {
                    preview.message = "Giờ kết thúc mới phải sau thời điểm hiện tại và giờ kết thúc cũ.";
                    return preview;
                }
                if (newPlannedEnd.isAfter(limitDateTime)) {
                    preview.message = "Gia hạn thất bại: Vượt quá giới hạn cho phép (Giới hạn tối đa đến: " +
                            limitDateTime.toLocalTime().toString().substring(0, 5) + ").";
                    return preview;
                }

                // 8. Tính tiền
                LocalTime lightingStart = rs.getTime("GioBatDauLenDen") != null ? rs.getTime("GioBatDauLenDen").toLocalTime() : null;
                LocalTime lightingEnd = rs.getTime("GioKetThucLenDen") != null ? rs.getTime("GioKetThucLenDen").toLocalTime() : null;
                BigDecimal rateWithoutLight = rs.getBigDecimal("GiaKhongDen");
                BigDecimal rateWithLight = rs.getBigDecimal("GiaCoDen");

                CourtPriceResult oldPricing = courtPricingService.calculate(startAt, oldPlannedEnd, lightingStart, lightingEnd, rateWithoutLight, rateWithLight);
                CourtPriceResult newPricing = courtPricingService.calculate(startAt, newPlannedEnd, lightingStart, lightingEnd, rateWithoutLight, rateWithLight);

                preview.oldTotalCourtAmount = oldPricing.totalCourtAmount();
                preview.newTotalCourtAmount = newPricing.totalCourtAmount();
                preview.additionalAmount = newPricing.totalCourtAmount().subtract(oldPricing.totalCourtAmount());

                preview.canExtend = true;
                preview.message = "Hợp lệ";
                return preview;
            }
        } catch (SQLException e) {
            logger.error("Lỗi khi xem trước gia hạn ca chơi ID {}: {}", datSanId, e.getMessage(), e);
            preview.message = "Lỗi hệ thống khi tính toán gia hạn: " + e.getMessage();
            return preview;
        }
    }

    public ExtensionResult extendSession(int datSanId, Integer extendMinutes, LocalTime proposedNewEndTime, int operatorAccountId, int coSoId) {
        ExtensionResult result = new ExtensionResult();
        result.success = false;

        // Bắt đầu transaction
        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // 1. Khóa hàng LichDatSan
            String sqlLockBooking = "SELECT l.DatSanID, l.SanID, l.NgayDat, l.GioBatDau, l.GioKetThuc, l.TrangThai, l.TimeMode, " +
                    "l.actual_start_time, l.ActualStartAt, l.ReservedDurationMinutes, " +
                    "s.TenSan, s.CoSoID, s.TrangThai AS SanTrangThai, ls.GiaKhongDen, ls.GiaCoDen, ls.GioBatDauLenDen, ls.GioKetThucLenDen " +
                    "FROM LichDatSan l WITH (UPDLOCK, ROWLOCK) " +
                    "JOIN San s ON l.SanID = s.SanID " +
                    "JOIN LoaiSan ls ON s.LoaiSanID = ls.LoaiSanID " +
                    "WHERE l.DatSanID = ? AND l.IsDeleted = 0";

            int sanId;
            LocalDate date;
            LocalTime oldGioKetThuc;
            LocalDateTime startAt = null;
            LocalDateTime oldPlannedEnd;
            LocalTime lightingStart;
            LocalTime lightingEnd;
            BigDecimal rateWithoutLight;
            BigDecimal rateWithLight;
            Integer oldReservedMinutes = null;

            try (PreparedStatement ps = conn.prepareStatement(sqlLockBooking)) {
                ps.setInt(1, datSanId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        result.message = "Không tìm thấy thông tin đơn đặt sân.";
                        conn.rollback();
                        return result;
                    }

                    int bookingCoSoId = rs.getInt("CoSoID");
                    if (bookingCoSoId != coSoId) {
                        result.message = "Đơn đặt sân không thuộc cơ sở của bạn.";
                        conn.rollback();
                        return result;
                    }

                    String bookingTrangThai = rs.getString("TrangThai");
                    if (!"Đang sử dụng".equals(bookingTrangThai)) {
                        result.message = "Chỉ ca chơi ở trạng thái 'Đang sử dụng' mới có thể gia hạn.";
                        conn.rollback();
                        return result;
                    }

                    String timeMode = rs.getString("TimeMode");
                    if ("OPEN_ENDED".equals(timeMode)) {
                        result.message = "Walk-in không cố định chạy đến khi dừng, không cần gia hạn.";
                        conn.rollback();
                        return result;
                    }

                    sanId = rs.getInt("SanID");
                    date = rs.getDate("NgayDat").toLocalDate();
                    oldGioKetThuc = rs.getTime("GioKetThuc").toLocalTime();

                    Timestamp ts = rs.getTimestamp("ActualStartAt");
                    if (ts != null) {
                        startAt = ts.toLocalDateTime();
                    }
                    if (startAt == null) {
                        Time t = rs.getTime("actual_start_time");
                        if (t != null) {
                            startAt = date.atTime(t.toLocalTime());
                        }
                    }
                    if (startAt == null) {
                        startAt = date.atTime(rs.getTime("GioBatDau").toLocalTime());
                    }

                    oldPlannedEnd = date.atTime(oldGioKetThuc);
                    if (!oldPlannedEnd.isAfter(startAt)) {
                        oldPlannedEnd = oldPlannedEnd.plusDays(1);
                    }

                    lightingStart = rs.getTime("GioBatDauLenDen") != null ? rs.getTime("GioBatDauLenDen").toLocalTime() : null;
                    lightingEnd = rs.getTime("GioKetThucLenDen") != null ? rs.getTime("GioKetThucLenDen").toLocalTime() : null;
                    rateWithoutLight = rs.getBigDecimal("GiaKhongDen");
                    rateWithLight = rs.getBigDecimal("GiaCoDen");

                    int resMin = rs.getInt("ReservedDurationMinutes");
                    if (!rs.wasNull()) {
                        oldReservedMinutes = resMin;
                    }
                }
            }

            // 2. Khóa hàng Sân
            String sqlLockSan = "SELECT TrangThai FROM San WITH (UPDLOCK, ROWLOCK) WHERE SanID = ?";
            try (PreparedStatement psSan = conn.prepareStatement(sqlLockSan)) {
                psSan.setInt(1, sanId);
                try (ResultSet rsSan = psSan.executeQuery()) {
                    if (rsSan.next()) {
                        String sanStatus = rsSan.getString("TrangThai");
                        if ("Bảo trì".equals(sanStatus) || "Tạm đóng".equals(sanStatus)) {
                            result.message = "Không thể gia hạn chơi vì sân đang ở trạng thái: " + sanStatus;
                            conn.rollback();
                            return result;
                        }
                    }
                }
            }

            // 3. Tìm limitDateTime
            LocalDateTime nextBookingStart = null;
            String sqlNext = "SELECT DatSanID, NgayDat, GioBatDau, GioKetThuc, TrangThai, HoldExpiresAt FROM LichDatSan " +
                    "WHERE SanID = ? AND IsDeleted = 0 AND DatSanID <> ? " +
                    "AND (NgayDat = ? OR NgayDat = ?) " +
                    "AND (TrangThai IN (N'Đã xác nhận', N'Chờ xác nhận', N'Đang sử dụng') " +
                    "     OR (TrangThai = N'Chờ thanh toán' AND HoldExpiresAt > SYSUTCDATETIME()))";
            try (PreparedStatement psNext = conn.prepareStatement(sqlNext)) {
                psNext.setInt(1, sanId);
                psNext.setInt(2, datSanId);
                psNext.setDate(3, Date.valueOf(date));
                psNext.setDate(4, Date.valueOf(date.plusDays(1)));
                try (ResultSet rsNext = psNext.executeQuery()) {
                    while (rsNext.next()) {
                        LocalDate nextDate = rsNext.getDate("NgayDat").toLocalDate();
                        LocalTime nextStartTime = rsNext.getTime("GioBatDau").toLocalTime();
                        LocalDateTime startTemp = nextDate.atTime(nextStartTime);
                        if (!startTemp.isBefore(oldPlannedEnd)) {
                            if (nextBookingStart == null || startTemp.isBefore(nextBookingStart)) {
                                nextBookingStart = startTemp;
                            }
                        }
                    }
                }
            }

            LocalDateTime closeTime = null;
            String sqlCoSo = "SELECT GioDongCua FROM CoSo WHERE CoSoID = ?";
            try (PreparedStatement psCoSo = conn.prepareStatement(sqlCoSo)) {
                psCoSo.setInt(1, coSoId);
                try (ResultSet rsCoSo = psCoSo.executeQuery()) {
                    if (rsCoSo.next()) {
                        Time dbClose = rsCoSo.getTime("GioDongCua");
                        if (dbClose != null) {
                            closeTime = date.atTime(dbClose.toLocalTime());
                            if (dbClose.toLocalTime().isBefore(startAt.toLocalTime())) {
                                closeTime = closeTime.plusDays(1);
                            }
                        }
                    }
                }
            }

            LocalDateTime limitDateTime = null;
            if (nextBookingStart != null && closeTime != null) {
                limitDateTime = nextBookingStart.isBefore(closeTime) ? nextBookingStart : closeTime;
            } else if (nextBookingStart != null) {
                limitDateTime = nextBookingStart;
            } else if (closeTime != null) {
                limitDateTime = closeTime;
            } else {
                limitDateTime = oldPlannedEnd.plusHours(6);
            }

            LocalDateTime nowDateTime = LocalDateTime.now();
            LocalDateTime baseEnd = oldPlannedEnd;
            if (nowDateTime.isAfter(oldPlannedEnd)) {
                baseEnd = nowDateTime;
            }

            // 4. Tính newPlannedEnd
            LocalDateTime newPlannedEnd = null;
            if (extendMinutes != null) {
                newPlannedEnd = baseEnd.plusMinutes(extendMinutes);
            } else {
                newPlannedEnd = date.atTime(proposedNewEndTime);
                if (!newPlannedEnd.isAfter(baseEnd)) {
                    newPlannedEnd = newPlannedEnd.plusDays(1);
                }
            }

            // 5. Validations
            if (!newPlannedEnd.isAfter(baseEnd)) {
                result.message = "Giờ kết thúc mới phải sau thời điểm hiện tại và giờ kết thúc cũ.";
                conn.rollback();
                return result;
            }
            if (newPlannedEnd.isAfter(limitDateTime)) {
                result.message = "Gia hạn thất bại: Vượt quá giới hạn cho phép do trùng lịch hoặc vượt quá giờ đóng cửa.";
                conn.rollback();
                return result;
            }

            // 6. Tính tiền
            CourtPriceResult oldPricing = courtPricingService.calculate(startAt, oldPlannedEnd, lightingStart, lightingEnd, rateWithoutLight, rateWithLight);
            CourtPriceResult newPricing = courtPricingService.calculate(startAt, newPlannedEnd, lightingStart, lightingEnd, rateWithoutLight, rateWithLight);

            BigDecimal oldTotalCourtAmount = oldPricing.totalCourtAmount();
            BigDecimal newTotalCourtAmount = newPricing.totalCourtAmount();
            BigDecimal additionalAmount = newTotalCourtAmount.subtract(oldTotalCourtAmount);

            // 7. Cập nhật booking
            long extendDurationMin = Duration.between(oldPlannedEnd, newPlannedEnd).toMinutes();
            Integer newReservedMinutes = null;
            if (oldReservedMinutes != null) {
                newReservedMinutes = oldReservedMinutes + (int) extendDurationMin;
            }

            String sqlUpdateBooking = "UPDATE LichDatSan SET GioKetThuc = ?, TongTienDuKien = ?" +
                    (newReservedMinutes != null ? ", ReservedDurationMinutes = ?" : "") +
                    " WHERE DatSanID = ?";
            try (PreparedStatement psUpdateB = conn.prepareStatement(sqlUpdateBooking)) {
                psUpdateB.setTime(1, Time.valueOf(newPlannedEnd.toLocalTime()));
                psUpdateB.setBigDecimal(2, newTotalCourtAmount);
                if (newReservedMinutes != null) {
                    psUpdateB.setInt(3, newReservedMinutes);
                    psUpdateB.setInt(4, datSanId);
                } else {
                    psUpdateB.setInt(3, datSanId);
                }
                psUpdateB.executeUpdate();
            }

            // 8. Cập nhật hóa đơn chính (MAIN)
            String sqlSelectInvoice = "SELECT HoaDonID, TongTienSan, TongTienDichVu, PhiGuiXe, GiamGia, TongThanhToan, TrangThaiThanhToan FROM HoaDon WITH (UPDLOCK, ROWLOCK) " +
                    "WHERE DatSanID = ? AND (LoaiHoaDon = N'MAIN' OR LoaiHoaDon IS NULL)";
            try (PreparedStatement psSelInv = conn.prepareStatement(sqlSelectInvoice)) {
                psSelInv.setInt(1, datSanId);
                try (ResultSet rsInv = psSelInv.executeQuery()) {
                    if (rsInv.next()) {
                        int hoaDonId = rsInv.getInt("HoaDonID");
                        BigDecimal serviceAmt = rsInv.getBigDecimal("TongTienDichVu");
                        BigDecimal parkingAmt = rsInv.getBigDecimal("PhiGuiXe");
                        BigDecimal discountAmt = rsInv.getBigDecimal("GiamGia");

                        BigDecimal newTotalInvoice = newTotalCourtAmount.add(serviceAmt != null ? serviceAmt : BigDecimal.ZERO)
                                .add(parkingAmt != null ? parkingAmt : BigDecimal.ZERO)
                                .subtract(discountAmt != null ? discountAmt : BigDecimal.ZERO);
                        if (newTotalInvoice.compareTo(BigDecimal.ZERO) < 0) {
                            newTotalInvoice = BigDecimal.ZERO;
                        }

                        // Cập nhật hóa đơn và chuyển về Chưa thanh toán
                        String sqlUpdateInvoice = "UPDATE HoaDon SET TongTienSan = ?, TongThanhToan = ?, TrangThaiThanhToan = N'Chưa thanh toán' WHERE HoaDonID = ?";
                        try (PreparedStatement psUpInv = conn.prepareStatement(sqlUpdateInvoice)) {
                            psUpInv.setBigDecimal(1, newTotalCourtAmount);
                            psUpInv.setBigDecimal(2, newTotalInvoice);
                            psUpInv.setInt(3, hoaDonId);
                            psUpInv.executeUpdate();
                        }
                    }
                }
            }

            // 9. Ghi lịch sử gia hạn
            String sqlHistory = "INSERT INTO BookingExtension (DatSanID, OldGioKetThuc, NewGioKetThuc, OldGioKetThucDateTime, NewGioKetThucDateTime, AdditionalAmount, OperatorAccountID, CreatedAt) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, GETDATE())";
            try (PreparedStatement psHist = conn.prepareStatement(sqlHistory)) {
                psHist.setInt(1, datSanId);
                psHist.setTime(2, Time.valueOf(oldPlannedEnd.toLocalTime()));
                psHist.setTime(3, Time.valueOf(newPlannedEnd.toLocalTime()));
                psHist.setTimestamp(4, Timestamp.valueOf(oldPlannedEnd));
                psHist.setTimestamp(5, Timestamp.valueOf(newPlannedEnd));
                psHist.setBigDecimal(6, additionalAmount);
                psHist.setInt(7, operatorAccountId);
                psHist.executeUpdate();
            }

            conn.commit();
            result.success = true;
            result.additionalAmount = additionalAmount;
            result.newGioKetThuc = newPlannedEnd.toLocalTime();
            result.message = "Gia hạn chơi thành công thêm " + extendDurationMin + " phút.";
            return result;

        } catch (Exception e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    logger.error("Lỗi rollback transaction: {}", ex.getMessage(), ex);
                }
            }
            logger.error("Lỗi khi gia hạn ca chơi ID {}: {}", datSanId, e.getMessage(), e);
            result.message = "Lỗi hệ thống: " + e.getMessage();
            return result;
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ex) {
                    logger.error("Lỗi đóng kết nối database: {}", ex.getMessage(), ex);
                }
            }
        }
    }
}
