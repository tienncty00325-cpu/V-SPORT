package org.example.dao.impl;

import org.example.dao.LichDatSanDAO;
import org.example.model.Lichdatsan;
import org.example.util.DBUtil;

import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalTime;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class LichDatSanDAOImpl implements LichDatSanDAO {

    private static final Logger logger = LogManager.getLogger(LichDatSanDAOImpl.class);

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

    /**
     * Đếm số lượt đặt sân "đang hoạt động" (chưa hủy) của một khách trong một ngày, dùng để
     * áp giới hạn tối đa 3 lượt/ngày. Nguồn sự thật duy nhất - dùng chung bởi DatSanServlet
     * (bước submit booking chính thức) và SoftHoldDAOImpl.createHold() (bước giữ chỗ tạm), để
     * một khách đã đạt giới hạn không thể tạo SoftHold chặn slot của người khác dù chưa đặt được.
     * Nhận Connection từ caller để dùng chung transaction khi caller đã mở sẵn.
     */
    public static int countActiveBookingsForAccountAndDate(Connection conn, int accountId, java.time.LocalDate ngayDat)
            throws SQLException {
        String sql = "SELECT COUNT(*) FROM LichDatSan WHERE AccountID = ? AND NgayDat = ? AND TrangThai <> N'Đã hủy'";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setDate(2, Date.valueOf(ngayDat));
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    /**
     * Sweep AN TOÀN, gọi được cả từ scheduler (BookingExpiryScheduler) lẫn lazy từ các hàm đọc
     * danh sách bên dưới. KHÔNG BAO GIỜ được tự hoàn thành một booking "Đang sử dụng" - việc đó
     * chỉ được phép qua transaction checkout chính thức (CheckoutService). Chỉ xử lý:
     *   1. Giải phóng San "mồ côi" (không có LichDatSan "Đang sử dụng" nào tham chiếu tới) -
     *      tự chữa lành trạng thái sân sau sự cố (crash giữa transaction, dữ liệu cũ...), không
     *      đụng tới bất kỳ ca đang chơi nào vì điều kiện NOT IN loại trừ mọi San có ca đang chơi.
     *   2. Tự hủy "Chờ xác nhận" quá hạn duyệt (COD_APPROVAL_EXPIRE_HOURS).
     */
    public static void updateExpiredBookingsAndFields() {
        String sqlUpdateSan = "UPDATE San SET TrangThai = N'Sẵn sàng' " +
                             "WHERE TrangThai = N'Đang sử dụng' " +
                             "AND SanID NOT IN (SELECT DISTINCT SanID FROM LichDatSan WHERE TrangThai = N'Đang sử dụng')";
        String sqlExpirePending = "UPDATE LichDatSan " +
                                  "SET TrangThai = N'Đã hủy', " +
                                  "    GhiChu = CONCAT(ISNULL(GhiChu, N''), N' [Tự động hủy: Hết hạn chờ xác nhận (" +
                                  org.example.util.Constants.COD_APPROVAL_EXPIRE_HOURS + " giờ)]') " +
                                  "WHERE TrangThai = N'Chờ xác nhận' " +
                                  "AND DATEDIFF(hour, CreatedTime, GETDATE()) >= " + org.example.util.Constants.COD_APPROVAL_EXPIRE_HOURS;

        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement psSan = conn.prepareStatement(sqlUpdateSan);
                 PreparedStatement psExpire = conn.prepareStatement(sqlExpirePending)) {
                psSan.executeUpdate();
                psExpire.executeUpdate();
                conn.commit();
            } catch (Exception e) {
                conn.rollback();
                logger.error("Lỗi khi tự động cập nhật đơn đặt sân hết hạn: {}", e.getMessage(), e);
            }
        } catch (Exception e) {
            logger.error("Lỗi kết nối khi tự động cập nhật đơn đặt sân hết hạn: {}", e.getMessage(), e);
        }
    }

    @Override
    public List<Lichdatsan> getAllLichDatSan() {
        updateExpiredBookingsAndFields();
        org.example.service.BookingLifecycleService.runExpirySweep();
        List<Lichdatsan> list = new ArrayList<>();
        String sql = "SELECT * FROM LichDatSan WHERE IsDeleted = 0 ORDER BY NgayDat DESC, GioBatDau DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapResultSetToLichDatSan(rs));
            }
        } catch (SQLException e) {
            logger.error("Lỗi khi lấy tất cả lịch đặt sân: {}", e.getMessage(), e);
        }
        return list;
    }

    @Override
    public List<Lichdatsan> getLichByAccountId(int accountId) {
        updateExpiredBookingsAndFields();
        org.example.service.BookingLifecycleService.runExpirySweep();
        List<Lichdatsan> list = new ArrayList<>();
        String sql = "SELECT * FROM LichDatSan WHERE AccountID = ? AND IsDeleted = 0 ORDER BY ISNULL(CreatedTime, CAST('1900-01-01' AS DATETIME)) DESC, DatSanID DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSetToLichDatSan(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Lỗi khi lấy lịch đặt sân theo account ID {}: {}", accountId, e.getMessage(), e);
        }
        return list;
    }

    @Override
    public Lichdatsan getLichById(int id) {
        String sql = "SELECT * FROM LichDatSan WHERE DatSanID = ? AND IsDeleted = 0";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToLichDatSan(rs);
                }
            }
        } catch (SQLException e) {
            logger.error("Lỗi khi lấy lịch đặt sân theo ID {}: {}", id, e.getMessage(), e);
        }
        return null;
    }

    @Override
    public boolean addLichDatSan(Lichdatsan lich) {
        String sql = "INSERT INTO LichDatSan (AccountID, SanID, NgayDat, GioBatDau, GioKetThuc, ApDungGiaCoDen, TongTienDuKien, TrangThai, GhiChu, NguonDatSan) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, lich.getAccountId());
            ps.setInt(2, lich.getSanId());
            ps.setDate(3, Date.valueOf(lich.getNgayDat()));
            ps.setTime(4, Time.valueOf(lich.getGioBatDau()));
            ps.setTime(5, Time.valueOf(lich.getGioKetThuc()));
            ps.setBoolean(6, lich.isApDungGiaCoDen());
            ps.setBigDecimal(7, lich.getTongTienDuKien());
            ps.setNString(8, lich.getTrangThai());
            ps.setNString(9, lich.getGhiChu());
            ps.setNString(10, lich.getNguonDatSan());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Lỗi khi tạo lịch đặt sân mới, account ID {}: {}", lich.getAccountId(), e.getMessage(), e);
        }
        return false;
    }

    @Override
    public boolean updateTrangThai(int id, String trangThai) {
        String sql = "UPDATE LichDatSan SET TrangThai = ? WHERE DatSanID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setNString(1, trangThai);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Lỗi khi cập nhật trạng thái lịch đặt sân ID {}: {}", id, e.getMessage(), e);
        }
        return false;
    }

    @Override
    public int cancelByCustomer(Connection conn, int datSanId, int accountId, String cancelType, String cancelReason) throws SQLException {
        String sql = "UPDATE LichDatSan SET TrangThai = N'Đã hủy', CancelType = ?, CancelReason = ?, " +
                "CancelledAt = GETDATE(), CancelledBy = ? " +
                "WHERE DatSanID = ? AND AccountID = ? AND (" +
                "TrangThai = N'Chờ xác nhận' " +
                "OR TrangThai = N'Đã xác nhận' " +
                "OR (TrangThai = N'Chờ thanh toán' AND (HoldExpiresAt IS NULL OR HoldExpiresAt > SYSUTCDATETIME())))";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, cancelType);
            ps.setString(2, cancelReason);
            ps.setInt(3, accountId);
            ps.setInt(4, datSanId);
            ps.setInt(5, accountId);
            return ps.executeUpdate();
        }
    }

    @Override
    public boolean updateGhiChu(int id, String ghiChu) {
        String sql = "UPDATE LichDatSan SET GhiChu = ? WHERE DatSanID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setNString(1, ghiChu);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Lỗi khi cập nhật ghi chú lịch đặt sân ID {}: {}", id, e.getMessage(), e);
        }
        return false;
    }

    @Override
    public boolean hardDelete(int id) {
        String sql = "DELETE FROM LichDatSan WHERE DatSanID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Lỗi khi xóa lịch đặt sân ID {}: {}", id, e.getMessage(), e);
        }
        return false;
    }

    @Override
    public boolean softDelete(int id, int actorId) {
        String sql = "UPDATE LichDatSan SET IsDeleted = 1, DeletedAt = GETDATE(), DeletedBy = ? " +
                     "WHERE DatSanID = ? AND IsDeleted = 0";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, actorId);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Lỗi soft delete lịch đặt sân ID {}: {}", id, e.getMessage(), e);
            return false;
        }
    }

    @Override
    public boolean restore(int id) {
        String sql = "UPDATE LichDatSan SET IsDeleted = 0, DeletedAt = NULL, DeletedBy = NULL " +
                     "WHERE DatSanID = ? AND IsDeleted = 1";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Lỗi restore lịch đặt sân ID {}: {}", id, e.getMessage(), e);
            return false;
        }
    }

    @Override
    public List<Lichdatsan> findDeletedByCoSo(int coSoId) {
        List<Lichdatsan> list = new ArrayList<>();
        String sql = "SELECT b.*, s.TenSan, s.CoSoID " +
                     "FROM LichDatSan b JOIN San s ON b.SanID = s.SanID " +
                     "WHERE s.CoSoID = ? AND b.IsDeleted = 1 " +
                     "ORDER BY b.DeletedAt DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, coSoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSetToLichDatSan(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Lỗi findDeletedByCoSo lịch đặt sân coSoId {}: {}", coSoId, e.getMessage(), e);
        }
        return list;
    }

    @Override
    public List<Integer> findDeletedIdsOlderThan(int days) {
        List<Integer> ids = new ArrayList<>();
        String sql = "SELECT DatSanID FROM LichDatSan " +
                     "WHERE IsDeleted = 1 AND DeletedAt < DATEADD(day, -?, GETDATE())";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, days);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ids.add(rs.getInt("DatSanID"));
                }
            }
        } catch (SQLException e) {
            logger.error("Lỗi findDeletedIdsOlderThan lịch đặt sân days {}: {}", days, e.getMessage(), e);
        }
        return ids;
    }

    private Lichdatsan mapResultSetToLichDatSan(ResultSet rs) throws SQLException {
        Lichdatsan lich = new Lichdatsan();
        lich.setDatSanId(rs.getInt("DatSanID"));
        lich.setAccountId(rs.getInt("AccountID"));
        lich.setSanId(rs.getInt("SanID"));
        lich.setNgayDat(rs.getDate("NgayDat").toLocalDate());
        lich.setGioBatDau(rs.getTime("GioBatDau").toLocalTime());
        lich.setGioKetThuc(rs.getTime("GioKetThuc").toLocalTime());
        lich.setApDungGiaCoDen(rs.getBoolean("ApDungGiaCoDen"));
        lich.setTongTienDuKien(rs.getBigDecimal("TongTienDuKien"));
        lich.setTrangThai(rs.getNString("TrangThai"));
        lich.setGhiChu(rs.getNString("GhiChu"));
        lich.setNguonDatSan(rs.getNString("NguonDatSan"));

        Timestamp createdTs = rs.getTimestamp("CreatedTime");
        if (createdTs != null) {
            lich.setCreatedTime(createdTs.toLocalDateTime());
        }

        try {
            lich.setDeleted(rs.getBoolean("IsDeleted"));
            Timestamp deletedAtTs = rs.getTimestamp("DeletedAt");
            if (deletedAtTs != null) {
                lich.setDeletedAt(deletedAtTs.toLocalDateTime());
            }
            int deletedBy = rs.getInt("DeletedBy");
            if (!rs.wasNull()) {
                lich.setDeletedBy(deletedBy);
            }
        } catch (SQLException e) {
            // Soft-delete columns may not be present in all queries
        }

        try {
            lich.setTimeMode(rs.getString("TimeMode"));
            int reserved = rs.getInt("ReservedDurationMinutes");
            if (!rs.wasNull()) {
                lich.setReservedDurationMinutes(reserved);
            }
            Time actualStart = rs.getTime("actual_start_time");
            if (actualStart != null) {
                lich.setActualStartTime(actualStart.toLocalTime());
            }
            Time actualEnd = rs.getTime("actual_end_time");
            if (actualEnd != null) {
                lich.setActualEndTime(actualEnd.toLocalTime());
            }
            lich.setEarlyCheckoutReason(rs.getNString("EarlyCheckoutReason"));
            BigDecimal earlyDisc = rs.getBigDecimal("EarlyCheckoutDiscount");
            if (earlyDisc != null) {
                lich.setEarlyCheckoutDiscount(earlyDisc);
            }
            java.sql.Timestamp holdExpiresTs = rs.getTimestamp("HoldExpiresAt");
            if (holdExpiresTs != null) {
                lich.setHoldExpiresAt(holdExpiresTs.toLocalDateTime());
            }
        } catch (SQLException e) {
            // New columns might not be present in some select statements
        }

        try {
            lich.setCancelType(rs.getNString("CancelType"));
            lich.setCancelReason(rs.getNString("CancelReason"));
            java.sql.Timestamp cancelledAtTs = rs.getTimestamp("CancelledAt");
            if (cancelledAtTs != null) {
                lich.setCancelledAt(cancelledAtTs.toLocalDateTime());
            }
            int cancelledBy = rs.getInt("CancelledBy");
            if (!rs.wasNull()) {
                lich.setCancelledBy(cancelledBy);
            }
            lich.setRequiresRefundReview(rs.getBoolean("RequiresRefundReview"));
        } catch (SQLException e) {
            // New columns might not be present in some select statements
        }

        try {
            String tenSan = rs.getNString("TenSan");
            if (tenSan != null) {
                org.example.model.San san = new org.example.model.San();
                san.setSanID(rs.getInt("SanID"));
                san.setTenSan(tenSan);
                san.setCoSoID(rs.getInt("CoSoID"));
                lich.setSan(san);
            }
        } catch (SQLException e) {
            // Column not found, ignore
        }

        try {
            String fullName = rs.getNString("FullName");
            if (fullName != null) {
                org.example.model.TaiKhoan acc = new org.example.model.TaiKhoan();
                acc.setAccountId(rs.getInt("AccountID"));
                acc.setFullName(fullName);
                acc.setPhoneNumber(rs.getString("PhoneNumber"));
                acc.setEmail(rs.getString("Email"));
                try {
                    acc.setDiemUyTin(rs.getInt("DiemUyTin"));
                    acc.setLateCancelCount(rs.getInt("LateCancelCount"));
                    acc.setNoShowCount(rs.getInt("NoShowCount"));
                } catch (SQLException ignoredReputationCols) {
                    // Query didn't select reputation columns (e.g. getLichDatSanTodayByCoSo) — leave defaults
                }
                lich.setAccount(acc);
            }
        } catch (SQLException e) {
            // Column not found, ignore
        }

        return lich;
    }

    @Override
    public List<Lichdatsan> getLichDatSanTodayByCoSo(int coSoId) {
        updateExpiredBookingsAndFields();
        org.example.service.BookingLifecycleService.runExpirySweep();
        List<Lichdatsan> list = new ArrayList<>();
        String sql = "SELECT l.*, s.TenSan, s.CoSoID " +
                     "FROM LichDatSan l " +
                     "JOIN San s ON l.SanID = s.SanID " +
                     "WHERE s.CoSoID = ? AND l.NgayDat = ? AND l.IsDeleted = 0 " +
                     "ORDER BY l.GioBatDau ASC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, coSoId);
            ps.setDate(2, java.sql.Date.valueOf(java.time.LocalDate.now()));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSetToLichDatSan(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Lỗi khi lấy lịch đặt sân hôm nay theo cơ sở {}: {}", coSoId, e.getMessage(), e);
        }
        return list;
    }

    @Override
    public List<Lichdatsan> getLichDatSanByCoSo(int coSoId) {
        updateExpiredBookingsAndFields();
        org.example.service.BookingLifecycleService.runExpirySweep();
        List<Lichdatsan> list = new ArrayList<>();
        String sql = "SELECT l.*, s.TenSan, s.CoSoID, a.FullName, a.PhoneNumber, a.Email, " +
                     "a.DiemUyTin, a.LateCancelCount, a.NoShowCount " +
                     "FROM LichDatSan l " +
                     "JOIN San s ON l.SanID = s.SanID " +
                     "LEFT JOIN Accounts a ON l.AccountID = a.AccountID " +
                     "WHERE s.CoSoID = ? AND l.IsDeleted = 0 " +
                     // Sắp xếp theo thời điểm TẠO đơn (CreatedTime), không phải ngày/giờ SÂN được đặt (NgayDat/GioBatDau) —
                     // hai khái niệm khác nhau: đơn tạo gần đây cho slot tuần sau phải hiện trên đơn tạo hôm qua cho slot hôm nay.
                     "ORDER BY ISNULL(l.CreatedTime, CAST('1900-01-01' AS DATETIME)) DESC, l.DatSanID DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, coSoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSetToLichDatSan(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Lỗi khi lấy danh sách lịch đặt sân theo cơ sở {}: {}", coSoId, e.getMessage(), e);
        }
        return list;
    }

    @Override
    public boolean duyetLichDatSan(int datSanId, int approvedByAccountId, int coSoId, boolean confirmPriceChange) throws Exception {
        Connection conn = null;
        PreparedStatement psLockSan = null;
        PreparedStatement psSelect = null;
        PreparedStatement psCheckConflict = null;
        PreparedStatement psUpdateApproved = null;
        PreparedStatement psUpdateOverlap = null;
        PreparedStatement psInsertInvoice = null;
        ResultSet rsLockSan = null;
        ResultSet rsSelect = null;
        ResultSet rsConflict = null;

        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // 1. Kiểm tra trạng thái đơn hiện tại
            String sqlSelect = "SELECT SanID, NgayDat, GioBatDau, GioKetThuc, TrangThai, TongTienDuKien, AccountID, GhiChu FROM LichDatSan WITH (UPDLOCK, ROWLOCK) WHERE DatSanID = ?";
            psSelect = conn.prepareStatement(sqlSelect);
            psSelect.setInt(1, datSanId);
            rsSelect = psSelect.executeQuery();

            if (!rsSelect.next()) {
                throw new Exception("Không tìm thấy thông tin đơn đặt sân.");
            }

            int sanId = rsSelect.getInt("SanID");
            Date ngayDat = rsSelect.getDate("NgayDat");
            Time gioBatDau = rsSelect.getTime("GioBatDau");
            Time gioKetThuc = rsSelect.getTime("GioKetThuc");
            String trangThai = rsSelect.getString("TrangThai");
            BigDecimal tongTienDuKien = rsSelect.getBigDecimal("TongTienDuKien");
            String currentGhiChu = rsSelect.getString("GhiChu");
            Integer customerAccountId = rsSelect.getInt("AccountID");
            if (rsSelect.wasNull()) {
                customerAccountId = null;
            }

            if (!"Chờ xác nhận".equals(trangThai)) {
                throw new Exception("Đơn đặt sân đã được xử lý từ trước (Trạng thái hiện tại: " + trangThai + ").");
            }

            // Kiểm tra ngày/giờ booking đã qua - không duyệt đơn hết hạn
            java.time.LocalDate bookingDate = ngayDat.toLocalDate();
            java.time.LocalTime bookingStart = gioBatDau.toLocalTime();
            java.time.LocalDate today = java.time.LocalDate.now();
            java.time.LocalTime now = java.time.LocalTime.now();
            if (bookingDate.isBefore(today) || (bookingDate.equals(today) && bookingStart.isBefore(now))) {
                throw new Exception("Không thể duyệt đơn này vì thời gian đặt sân (" +
                        bookingDate + " " + bookingStart.toString().substring(0, 5) +
                        ") đã qua. Vui lòng hủy đơn thay vì duyệt.");
            }

            // 2. Vá lỗi IDOR & Tránh Race Condition bằng cách khóa hàng Sân (row lock)
            String sqlLockSan = "SELECT CoSoID FROM San WITH (UPDLOCK, ROWLOCK) WHERE SanID = ?";
            psLockSan = conn.prepareStatement(sqlLockSan);
            psLockSan.setInt(1, sanId);
            rsLockSan = psLockSan.executeQuery();
            if (!rsLockSan.next()) {
                throw new Exception("Không tìm thấy thông tin sân bóng tương ứng.");
            }
            int sanCoSoId = rsLockSan.getInt("CoSoID");
            if (sanCoSoId != coSoId) {
                throw new Exception("Bạn không có quyền quản lý đơn đặt sân thuộc cơ sở khác.");
            }

            // 3. Tính lại giá sân thực tế tại thời điểm duyệt để cập nhật/verify (Tránh trượt giá)
            double hourlyPrice = 100_000; // Fallback
            String loaiSanSql = "SELECT GiaKhongDen, GiaCoDen, GioBatDauLenDen FROM LoaiSan WHERE LoaiSanID = (SELECT LoaiSanID FROM San WHERE SanID = ?)";
            try (PreparedStatement psLoai = conn.prepareStatement(loaiSanSql)) {
                psLoai.setInt(1, sanId);
                try (ResultSet rsLoai = psLoai.executeQuery()) {
                    if (rsLoai.next()) {
                        double giaKhongDen = rsLoai.getDouble("GiaKhongDen");
                        double giaCoDen = rsLoai.getDouble("GiaCoDen");
                        LocalTime gioLenDen = LocalTime.of(17, 30);
                        Time sqlLenDen = rsLoai.getTime("GioBatDauLenDen");
                        if (sqlLenDen != null) {
                            gioLenDen = sqlLenDen.toLocalTime();
                        }
                        if (!gioBatDau.toLocalTime().isBefore(gioLenDen)) {
                            hourlyPrice = giaCoDen;
                        } else {
                            hourlyPrice = giaKhongDen;
                        }
                    }
                }
            }
            long durationMinutes = Duration.between(gioBatDau.toLocalTime(), gioKetThuc.toLocalTime()).toMinutes();
            double durationHours = durationMinutes / 60.0;
            BigDecimal currentPriceCalculated = BigDecimal.valueOf(durationHours * hourlyPrice).setScale(0, java.math.RoundingMode.HALF_UP);

            String priceWarning = "";
            if (currentPriceCalculated.compareTo(tongTienDuKien) != 0) {
                if (!confirmPriceChange) {
                    throw new Exception("PRICE_CHANGED:" + tongTienDuKien + ":" + currentPriceCalculated);
                }
                priceWarning = " [Cảnh báo: Giá sân thay đổi từ lúc đặt: " + tongTienDuKien + "đ -> " + currentPriceCalculated + "đ]";
                tongTienDuKien = currentPriceCalculated;
            }

            // 4. Kiểm xem có đơn trùng lịch đã được xác nhận/sử dụng không
            String sqlCheckConflict = "SELECT COUNT(*) FROM LichDatSan " +
                                      "WHERE SanID = ? AND NgayDat = ? AND DatSanID != ? " +
                                      "AND (TrangThai IN (N'Đã xác nhận', N'Đang sử dụng', N'Đã hoàn thành') " +
                                      "     OR (TrangThai = N'Chờ thanh toán' AND DATEDIFF(minute, CreatedTime, GETDATE()) <= " + org.example.util.Constants.PENDING_PAYMENT_TIMEOUT_MINUTES + ")) " +
                                      "AND NOT (GioKetThuc <= CAST(? AS time) OR GioBatDau >= CAST(? AS time))";
            psCheckConflict = conn.prepareStatement(sqlCheckConflict);
            psCheckConflict.setInt(1, sanId);
            psCheckConflict.setDate(2, ngayDat);
            psCheckConflict.setInt(3, datSanId);
            psCheckConflict.setString(4, gioBatDau.toString());
            psCheckConflict.setString(5, gioKetThuc.toString());

            rsConflict = psCheckConflict.executeQuery();
            if (rsConflict.next() && rsConflict.getInt(1) > 0) {
                throw new Exception("Không thể duyệt đơn này vì khung giờ đã bị chiếm bởi một đơn khác đã được xác nhận.");
            }

            // 5. Cập nhật trạng thái đơn hiện tại thành "Đã xác nhận"
            String newApprovedGhiChu = (currentGhiChu != null ? currentGhiChu.trim() : "") + priceWarning;
            String sqlUpdateApproved = "UPDATE LichDatSan SET TrangThai = N'Đã xác nhận', TongTienDuKien = ?, GhiChu = ? WHERE DatSanID = ?";
            psUpdateApproved = conn.prepareStatement(sqlUpdateApproved);
            psUpdateApproved.setBigDecimal(1, tongTienDuKien);
            psUpdateApproved.setNString(2, newApprovedGhiChu.trim());
            psUpdateApproved.setInt(3, datSanId);
            psUpdateApproved.executeUpdate();

            // 6. Khởi tạo hóa đơn "Chưa thanh toán" cho khách hàng đặt trước để tương thích với luồng CheckInDAO
            String sqlCheckInvoice = "SELECT COUNT(*) FROM HoaDon WHERE DatSanID = ?";
            try (PreparedStatement psCheckInv = conn.prepareStatement(sqlCheckInvoice)) {
                psCheckInv.setInt(1, datSanId);
                try (ResultSet rsInv = psCheckInv.executeQuery()) {
                    if (rsInv.next() && rsInv.getInt(1) == 0) {
                        boolean hasLoaiHoaDon = columnExists(conn, "HoaDon", "LoaiHoaDon");
                        String sqlInsertInvoice = hasLoaiHoaDon
                                ? "INSERT INTO HoaDon (DatSanID, AccountID_KhachHang, AccountID_NhanVien, NgayLap, TongTienSan, TongTienDichVu, PhiGuiXe, GiamGia, TongThanhToan, TrangThaiThanhToan, LoaiHoaDon) " +
                                  "VALUES (?, ?, NULL, GETDATE(), ?, 0, 0, 0, ?, N'Chưa thanh toán', N'MAIN')"
                                : "INSERT INTO HoaDon (DatSanID, AccountID_KhachHang, AccountID_NhanVien, NgayLap, TongTienSan, TongTienDichVu, PhiGuiXe, GiamGia, TongThanhToan, TrangThaiThanhToan) " +
                                  "VALUES (?, ?, NULL, GETDATE(), ?, 0, 0, 0, ?, N'Chưa thanh toán')";
                        psInsertInvoice = conn.prepareStatement(sqlInsertInvoice);
                        psInsertInvoice.setInt(1, datSanId);
                        if (customerAccountId != null) {
                            psInsertInvoice.setInt(2, customerAccountId);
                        } else {
                            psInsertInvoice.setNull(2, java.sql.Types.INTEGER);
                        }
                        psInsertInvoice.setBigDecimal(3, tongTienDuKien);
                        psInsertInvoice.setBigDecimal(4, tongTienDuKien);
                        psInsertInvoice.executeUpdate();
                    }
                }
            }

            // 7. Lấy danh sách các đơn trùng lịch để hủy và chuẩn bị thông báo gửi cho khách hàng
            String selectOverlapSql = "SELECT l.DatSanID, l.AccountID, l.NgayDat, l.GioBatDau, l.GioKetThuc, s.TenSan " +
                                      "FROM LichDatSan l " +
                                      "JOIN San s ON l.SanID = s.SanID " +
                                      "WHERE l.SanID = ? AND l.NgayDat = ? AND l.DatSanID != ? AND l.TrangThai = N'Chờ xác nhận' " +
                                      "AND NOT (l.GioKetThuc <= CAST(? AS time) OR l.GioBatDau >= CAST(? AS time))";

            class OverlapNotifInfo {
                int accountId;
                String title;
                String content;
            }
            List<OverlapNotifInfo> overlapNotifs = new ArrayList<>();

            try (PreparedStatement psOverlapSel = conn.prepareStatement(selectOverlapSql)) {
                psOverlapSel.setInt(1, sanId);
                psOverlapSel.setDate(2, ngayDat);
                psOverlapSel.setInt(3, datSanId);
                psOverlapSel.setString(4, gioBatDau.toString());
                psOverlapSel.setString(5, gioKetThuc.toString());
                try (ResultSet rsOverlap = psOverlapSel.executeQuery()) {
                    while (rsOverlap.next()) {
                        int overlapDatSanId = rsOverlap.getInt("DatSanID");
                        int customerId = rsOverlap.getInt("AccountID");
                        String tenSan = rsOverlap.getNString("TenSan");
                        Date oNgayDat = rsOverlap.getDate("NgayDat");
                        Time oStart = rsOverlap.getTime("GioBatDau");
                        Time oEnd = rsOverlap.getTime("GioKetThuc");

                        String title = "Đơn đặt sân #" + overlapDatSanId + " bị hủy";
                        String content = "Đơn đặt sân " + tenSan + " ngày " + oNgayDat + " (" + oStart.toString().substring(0, 5) + " - " + oEnd.toString().substring(0, 5) + ") đã bị tự động hủy do trùng lịch với ca đặt sân #" + datSanId + " đã được phê duyệt.";

                        OverlapNotifInfo info = new OverlapNotifInfo();
                        info.accountId = customerId;
                        info.title = title;
                        info.content = content;
                        overlapNotifs.add(info);
                    }
                }
            }

            // Tự động từ chối (hủy) các đơn Chờ xác nhận bị trùng lịch chéo (Sử dụng CONCAT và ISNULL an toàn)
            String sqlUpdateOverlap = "UPDATE LichDatSan " +
                                      "SET TrangThai = N'Đã hủy', " +
                                      "    GhiChu = CONCAT(ISNULL(GhiChu, N''), N' [Hệ thống tự động hủy do trùng lịch với đơn #', CAST(? AS varchar), N' đã được duyệt]') " +
                                      "WHERE SanID = ? AND NgayDat = ? AND DatSanID != ? AND TrangThai = N'Chờ xác nhận' " +
                                      "AND NOT (GioKetThuc <= CAST(? AS time) OR GioBatDau >= CAST(? AS time))";
            psUpdateOverlap = conn.prepareStatement(sqlUpdateOverlap);
            psUpdateOverlap.setInt(1, datSanId);
            psUpdateOverlap.setInt(2, sanId);
            psUpdateOverlap.setDate(3, ngayDat);
            psUpdateOverlap.setInt(4, datSanId);
            psUpdateOverlap.setString(5, gioBatDau.toString());
            psUpdateOverlap.setString(6, gioKetThuc.toString());
            psUpdateOverlap.executeUpdate();

            // Gửi thông báo bằng cách chèn trực tiếp vào bảng ThongBao
            if (!overlapNotifs.isEmpty()) {
                String insertNotifSql = "INSERT INTO ThongBao (AccountID, TieuDe, NoiDung, LoaiThongBao, DaDoc, ThoiGianGui, MaBanGhi, DuongDan) " +
                                        "VALUES (?, ?, ?, ?, 0, GETDATE(), N'DatSan', N'/customer/dat-san?openHistory=true')";
                try (PreparedStatement psInsNotif = conn.prepareStatement(insertNotifSql)) {
                    for (OverlapNotifInfo tb : overlapNotifs) {
                        psInsNotif.setInt(1, tb.accountId);
                        psInsNotif.setNString(2, tb.title);
                        psInsNotif.setNString(3, tb.content);
                        psInsNotif.setNString(4, "Booking");
                        psInsNotif.executeUpdate();
                    }
                }
            }

            conn.commit();
            return true;
        } catch (Exception e) {
            if (conn != null) {
                conn.rollback();
            }
            logger.error("Lỗi khi duyệt đơn đặt sân ID {}: {}", datSanId, e.getMessage(), e);
            throw e;
        } finally {
            if (rsLockSan != null) rsLockSan.close();
            if (rsSelect != null) rsSelect.close();
            if (rsConflict != null) rsConflict.close();
            if (psLockSan != null) psLockSan.close();
            if (psSelect != null) psSelect.close();
            if (psCheckConflict != null) psCheckConflict.close();
            if (psUpdateApproved != null) psUpdateApproved.close();
            if (psUpdateOverlap != null) psUpdateOverlap.close();
            if (psInsertInvoice != null) psInsertInvoice.close();
            if (conn != null) {
                conn.setAutoCommit(true);
                conn.close();
            }
        }
    }

    @Override
    public boolean tuChoiLichDatSan(int datSanId, String ghiChu, int coSoId) throws Exception {
        Connection conn = null;
        PreparedStatement psSelect = null;
        PreparedStatement psLockSan = null;
        PreparedStatement psUpdate = null;
        ResultSet rsSelect = null;
        ResultSet rsLockSan = null;

        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // 1. Kiểm tra trạng thái hiện tại
            String sqlSelect = "SELECT SanID, TrangThai, GhiChu FROM LichDatSan WHERE DatSanID = ?";
            psSelect = conn.prepareStatement(sqlSelect);
            psSelect.setInt(1, datSanId);
            rsSelect = psSelect.executeQuery();

            if (!rsSelect.next()) {
                throw new Exception("Không tìm thấy thông tin đơn đặt sân.");
            }

            int sanId = rsSelect.getInt("SanID");
            String trangThai = rsSelect.getString("TrangThai");
            String oldGhiChu = rsSelect.getString("GhiChu");
            if (oldGhiChu == null) oldGhiChu = "";

            if (!"Chờ xác nhận".equals(trangThai)) {
                throw new Exception("Đơn đặt sân đã được xử lý từ trước (Trạng thái hiện tại: " + trangThai + ").");
            }

            // 2. Vá lỗi IDOR: Kiểm tra sân có thuộc coSoId của người từ chối không
            String sqlLockSan = "SELECT CoSoID FROM San WITH (UPDLOCK, ROWLOCK) WHERE SanID = ?";
            psLockSan = conn.prepareStatement(sqlLockSan);
            psLockSan.setInt(1, sanId);
            rsLockSan = psLockSan.executeQuery();
            if (!rsLockSan.next()) {
                throw new Exception("Không tìm thấy thông tin sân bóng tương ứng.");
            }
            int sanCoSoId = rsLockSan.getInt("CoSoID");
            if (sanCoSoId != coSoId) {
                throw new Exception("Bạn không có quyền quản lý đơn đặt sân thuộc cơ sở khác.");
            }

            // 3. Cập nhật đơn thành Đã hủy
            String newGhiChu = oldGhiChu + (ghiChu != null && !ghiChu.isEmpty() ? " [Từ chối: " + ghiChu + "]" : " [Bị từ chối bởi quản lý]");
            String sqlUpdate = "UPDATE LichDatSan SET TrangThai = N'Đã hủy', GhiChu = ? WHERE DatSanID = ?";
            psUpdate = conn.prepareStatement(sqlUpdate);
            psUpdate.setNString(1, newGhiChu.trim());
            psUpdate.setInt(2, datSanId);
            psUpdate.executeUpdate();

            // 4. Kiểm tra và cập nhật hóa đơn liên quan nếu có (Tránh nuốt tiền online của khách)
            String sqlCheckInvoice = "SELECT HoaDonID, TrangThaiThanhToan, TongThanhToan, AccountID_KhachHang FROM HoaDon WHERE DatSanID = ?";
            try (PreparedStatement psCheckInv = conn.prepareStatement(sqlCheckInvoice)) {
                psCheckInv.setInt(1, datSanId);
                try (ResultSet rsInv = psCheckInv.executeQuery()) {
                    if (rsInv.next()) {
                        int hoaDonId = rsInv.getInt("HoaDonID");
                        String trangThaiThanhToan = rsInv.getString("TrangThaiThanhToan");
                        BigDecimal tongThanhToan = rsInv.getBigDecimal("TongThanhToan");
                        Integer khachHangId = rsInv.getInt("AccountID_KhachHang");
                        boolean wasNullKhach = rsInv.wasNull();

                        if ("Đã thanh toán".equals(trangThaiThanhToan) || "Đã cọc".equals(trangThaiThanhToan)) {
                            // Tạo yêu cầu Hoàn tiền
                            String sqlInsertRefund = "INSERT INTO HoanTien (HoaDonID, AccountID, SoTienHoan, LyDo, TrangThai, ThoiGianYeuCau) " +
                                                     "VALUES (?, ?, ?, ?, ?, GETDATE())";
                            try (PreparedStatement psRefund = conn.prepareStatement(sqlInsertRefund)) {
                                psRefund.setInt(1, hoaDonId);
                                if (!wasNullKhach && khachHangId != null) {
                                    psRefund.setInt(2, khachHangId);
                                } else {
                                    psRefund.setNull(2, java.sql.Types.INTEGER);
                                }
                                psRefund.setBigDecimal(3, tongThanhToan);
                                psRefund.setNString(4, "Đơn đặt sân bị từ chối bởi quản lý");
                                psRefund.setString(5, "Chờ xử lý");
                                psRefund.executeUpdate();
                            }
                            // Cập nhật hóa đơn thành "Hoàn tiền"
                            String sqlUpdateInvoice = "UPDATE HoaDon SET TrangThaiThanhToan = N'Hoàn tiền', NgayLap = GETDATE() WHERE HoaDonID = ?";
                            try (PreparedStatement psUpdateInv = conn.prepareStatement(sqlUpdateInvoice)) {
                                psUpdateInv.setInt(1, hoaDonId);
                                psUpdateInv.executeUpdate();
                            }
                        } else {
                            // Cập nhật hóa đơn thành "Đã hủy"
                            String sqlUpdateInvoice = "UPDATE HoaDon SET TrangThaiThanhToan = N'Đã hủy', NgayLap = GETDATE() WHERE HoaDonID = ?";
                            try (PreparedStatement psUpdateInv = conn.prepareStatement(sqlUpdateInvoice)) {
                                psUpdateInv.setInt(1, hoaDonId);
                                psUpdateInv.executeUpdate();
                            }
                        }
                    }
                }
            }

            conn.commit();
            return true;
        } catch (Exception e) {
            if (conn != null) {
                conn.rollback();
            }
            logger.error("Lỗi khi từ chối đơn đặt sân ID {}: {}", datSanId, e.getMessage(), e);
            throw e;
        } finally {
            if (rsLockSan != null) rsLockSan.close();
            if (rsSelect != null) rsSelect.close();
            if (psLockSan != null) psLockSan.close();
            if (psSelect != null) psSelect.close();
            if (psUpdate != null) psUpdate.close();
            if (conn != null) {
                conn.setAutoCommit(true);
                conn.close();
            }
        }
    }

    @Override
    public boolean updateDichVuDatSan(int datSanId, int[] productIds, int[] quantities) throws Exception {
        return updateDichVuDatSan(datSanId, productIds, quantities, null);
    }

    @Override
    public boolean updateDichVuDatSan(int datSanId, int[] productIds, int[] quantities, Integer requiredCoSoId) throws Exception {
        if (productIds == null || quantities == null || productIds.length != quantities.length) {
            throw new Exception("Dữ liệu đầu vào không hợp lệ (mảng sản phẩm và số lượng không khớp).");
        }

        Connection conn = null;
        PreparedStatement psSelectBooking = null;
        PreparedStatement psCheckInvoice = null;
        PreparedStatement psInsertInvoice = null;
        PreparedStatement psDeleteChiTiet = null;
        PreparedStatement psInsertChiTiet = null;
        PreparedStatement psUpdateProductStock = null;
        PreparedStatement psGetProductDetails = null;
        PreparedStatement psUpdateInvoiceTotals = null;
        ResultSet rsBooking = null;
        ResultSet rsInv = null;

        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // 1. Lấy thông tin booking và khóa dòng
            String sqlSelectBooking = "SELECT lds.SanID, lds.TongTienDuKien, lds.AccountID, lds.TrangThai, s.CoSoID FROM LichDatSan lds INNER JOIN San s ON lds.SanID = s.SanID WITH (UPDLOCK, ROWLOCK) WHERE lds.DatSanID = ?";
            psSelectBooking = conn.prepareStatement(sqlSelectBooking);
            psSelectBooking.setInt(1, datSanId);
            rsBooking = psSelectBooking.executeQuery();
            if (!rsBooking.next()) {
                throw new Exception("Không tìm thấy thông tin đơn đặt sân.");
            }
            int sanId = rsBooking.getInt("SanID");
            BigDecimal tongTienDuKien = rsBooking.getBigDecimal("TongTienDuKien");
            Integer customerAccountId = rsBooking.getInt("AccountID");
            if (rsBooking.wasNull()) {
                customerAccountId = null;
            }
            String trangThaiBooking = rsBooking.getString("TrangThai");
            int coSoId = rsBooking.getInt("CoSoID");

            if (requiredCoSoId != null && coSoId != requiredCoSoId) {
                throw new SecurityException("Đơn đặt sân không thuộc cơ sở của bạn.");
            }

            if (!"Đang sử dụng".equals(trangThaiBooking)) {
                throw new Exception("Chỉ được phép thêm/cập nhật dịch vụ khi đơn đặt sân ở trạng thái 'Đang sử dụng'.");
            }

            // 2. Kiểm tra/Tạo hóa đơn nếu chưa có
            int hoaDonId = -1;
            String sqlCheckInvoice = "SELECT HoaDonID FROM HoaDon WHERE " + mainInvoiceWhereClause(conn, "DatSanID");
            psCheckInvoice = conn.prepareStatement(sqlCheckInvoice);
            psCheckInvoice.setInt(1, datSanId);
            rsInv = psCheckInvoice.executeQuery();
            if (rsInv.next()) {
                hoaDonId = rsInv.getInt("HoaDonID");
            } else {
                boolean hasLoaiHoaDon = columnExists(conn, "HoaDon", "LoaiHoaDon");
                String sqlInsertInvoice = hasLoaiHoaDon
                        ? "INSERT INTO HoaDon (DatSanID, AccountID_KhachHang, AccountID_NhanVien, NgayLap, TongTienSan, TongTienDichVu, PhiGuiXe, GiamGia, TongThanhToan, TrangThaiThanhToan, LoaiHoaDon) " +
                          "VALUES (?, ?, NULL, GETDATE(), ?, 0, 0, 0, ?, N'Chưa thanh toán', N'MAIN')"
                        : "INSERT INTO HoaDon (DatSanID, AccountID_KhachHang, AccountID_NhanVien, NgayLap, TongTienSan, TongTienDichVu, PhiGuiXe, GiamGia, TongThanhToan, TrangThaiThanhToan) " +
                          "VALUES (?, ?, NULL, GETDATE(), ?, 0, 0, 0, ?, N'Chưa thanh toán')";
                psInsertInvoice = conn.prepareStatement(sqlInsertInvoice, Statement.RETURN_GENERATED_KEYS);
                psInsertInvoice.setInt(1, datSanId);
                if (customerAccountId != null) {
                    psInsertInvoice.setInt(2, customerAccountId);
                } else {
                    psInsertInvoice.setNull(2, java.sql.Types.INTEGER);
                }
                psInsertInvoice.setBigDecimal(3, tongTienDuKien);
                psInsertInvoice.setBigDecimal(4, tongTienDuKien);
                psInsertInvoice.executeUpdate();
                
                try (ResultSet generatedKeys = psInsertInvoice.getGeneratedKeys()) {
                    if (generatedKeys.next()) {
                        hoaDonId = generatedKeys.getInt(1);
                    }
                }
            }

            if (hoaDonId == -1) {
                throw new Exception("Không thể khởi tạo hoặc tìm thấy hóa đơn cho đơn đặt sân này.");
            }

            // 3. Hoàn trả lại số lượng tồn cũ của các chi tiết hóa đơn cũ trước khi xóa
            String sqlGetOldChiTiet = "SELECT SanPhamID, SoLuong FROM ChiTietHoaDon WHERE HoaDonID = ?";
            try (PreparedStatement psOld = conn.prepareStatement(sqlGetOldChiTiet)) {
                psOld.setInt(1, hoaDonId);
                try (ResultSet rsOld = psOld.executeQuery()) {
                    while (rsOld.next()) {
                        int spId = rsOld.getInt("SanPhamID");
                        int qty = rsOld.getInt("SoLuong");
                        String sqlRestoreStock = "UPDATE SanPham_DichVu SET SoLuongTon = SoLuongTon + ? WHERE SanPhamID = ?";
                        try (PreparedStatement psRestore = conn.prepareStatement(sqlRestoreStock)) {
                            psRestore.setInt(1, qty);
                            psRestore.setInt(2, spId);
                            psRestore.executeUpdate();
                        }
                    }
                }
            }

            // 4. Xóa toàn bộ chi tiết hóa đơn cũ của hóa đơn này
            String sqlDeleteChiTiet = "DELETE FROM ChiTietHoaDon WHERE HoaDonID = ?";
            psDeleteChiTiet = conn.prepareStatement(sqlDeleteChiTiet);
            psDeleteChiTiet.setInt(1, hoaDonId);
            psDeleteChiTiet.executeUpdate();

            // 5. Thêm các chi tiết mới, kiểm tra tồn kho và giảm số lượng tồn kho
            double totalDichVu = 0.0;
            String sqlInsertChiTiet = "INSERT INTO ChiTietHoaDon (HoaDonID, SanPhamID, SoLuong, DonGiaTaiThoiDiemBan, ThanhTien) VALUES (?, ?, ?, ?, ?)";
            psInsertChiTiet = conn.prepareStatement(sqlInsertChiTiet);

            String sqlGetProduct = "SELECT TenSanPham, DonGia, SoLuongTon, CoSoID, TrangThai FROM SanPham_DichVu WITH (UPDLOCK, ROWLOCK) WHERE SanPhamID = ?";
            psGetProductDetails = conn.prepareStatement(sqlGetProduct);

            String sqlUpdateStock = "UPDATE SanPham_DichVu SET SoLuongTon = SoLuongTon - ? WHERE SanPhamID = ?";
            psUpdateProductStock = conn.prepareStatement(sqlUpdateStock);

            if (productIds != null && quantities != null) {
                for (int i = 0; i < productIds.length; i++) {
                    int spId = productIds[i];
                    int qty = quantities[i];
                    if (qty <= 0) continue;

                    psGetProductDetails.setInt(1, spId);
                    try (ResultSet rsProd = psGetProductDetails.executeQuery()) {
                        if (!rsProd.next()) {
                            throw new Exception("Không tìm thấy sản phẩm có ID: " + spId);
                        }
                        String tenSp = rsProd.getNString("TenSanPham");
                        double donGia = rsProd.getDouble("DonGia");
                        int stock = rsProd.getInt("SoLuongTon");
                        int prodCoSoId = rsProd.getInt("CoSoID");
                        String prodStatus = rsProd.getString("TrangThai");

                        if (prodCoSoId != coSoId) {
                            throw new Exception("Sản phẩm '" + tenSp + "' không thuộc cùng chi nhánh với sân bóng.");
                        }
                        if (!"Đang kinh doanh".equals(prodStatus)) {
                            throw new Exception("Sản phẩm '" + tenSp + "' hiện tại ngừng kinh doanh.");
                        }

                        if (stock < qty) {
                            throw new Exception("Sản phẩm '" + tenSp + "' không đủ số lượng tồn (Hiện còn: " + stock + ").");
                        }

                        // Giảm tồn kho
                        psUpdateProductStock.setInt(1, qty);
                        psUpdateProductStock.setInt(2, spId);
                        psUpdateProductStock.executeUpdate();

                        // Thêm chi tiết hóa đơn
                        double thanhTien = qty * donGia;
                        totalDichVu += thanhTien;

                        psInsertChiTiet.setInt(1, hoaDonId);
                        psInsertChiTiet.setInt(2, spId);
                        psInsertChiTiet.setInt(3, qty);
                        psInsertChiTiet.setDouble(4, donGia);
                        psInsertChiTiet.setDouble(5, thanhTien);
                        psInsertChiTiet.executeUpdate();
                    }
                }
            }

            // 6. Cập nhật lại tổng tiền trên Hóa đơn
            String sqlUpdateInvoiceTotals = "UPDATE HoaDon SET TongTienDichVu = ?, TongThanhToan = TongTienSan + ? - GiamGia + PhiGuiXe WHERE HoaDonID = ?";
            psUpdateInvoiceTotals = conn.prepareStatement(sqlUpdateInvoiceTotals);
            psUpdateInvoiceTotals.setDouble(1, totalDichVu);
            psUpdateInvoiceTotals.setDouble(2, totalDichVu);
            psUpdateInvoiceTotals.setInt(3, hoaDonId);
            psUpdateInvoiceTotals.executeUpdate();

            // Cập nhật lại tổng tiền dự kiến trong LichDatSan
            String sqlUpdateLichTien = "UPDATE LichDatSan SET TongTienDuKien = ? WHERE DatSanID = ?";
            try (PreparedStatement psLichTien = conn.prepareStatement(sqlUpdateLichTien)) {
                double finalTotal = 0.0;
                String sqlGetTotal = "SELECT TongThanhToan FROM HoaDon WHERE HoaDonID = ?";
                try (PreparedStatement psGetTotal = conn.prepareStatement(sqlGetTotal)) {
                    psGetTotal.setInt(1, hoaDonId);
                    try (ResultSet rsGetTotal = psGetTotal.executeQuery()) {
                        if (rsGetTotal.next()) {
                            finalTotal = rsGetTotal.getDouble("TongThanhToan");
                        }
                    }
                }
                psLichTien.setBigDecimal(1, BigDecimal.valueOf(finalTotal));
                psLichTien.setInt(2, datSanId);
                psLichTien.executeUpdate();
            }

            conn.commit();
            return true;
        } catch (Exception e) {
            if (conn != null) {
                conn.rollback();
            }
            logger.error("Lỗi khi cập nhật dịch vụ đơn đặt sân ID {}: {}", datSanId, e.getMessage(), e);
            throw e;
        } finally {
            if (rsBooking != null) rsBooking.close();
            if (rsInv != null) rsInv.close();
            if (psSelectBooking != null) psSelectBooking.close();
            if (psCheckInvoice != null) psCheckInvoice.close();
            if (psInsertInvoice != null) psInsertInvoice.close();
            if (psDeleteChiTiet != null) psDeleteChiTiet.close();
            if (psInsertChiTiet != null) psInsertChiTiet.close();
            if (psGetProductDetails != null) psGetProductDetails.close();
            if (psUpdateProductStock != null) psUpdateProductStock.close();
            if (psUpdateInvoiceTotals != null) psUpdateInvoiceTotals.close();
            if (conn != null) {
                conn.setAutoCommit(true);
                conn.close();
            }
        }
    }

}
