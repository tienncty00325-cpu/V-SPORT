package org.example.dao.impl;

import org.example.dao.GhepKeoDAO;
import org.example.model.GhepKeo;
import org.example.util.DBUtil;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * JDBC impl cho GhepKeoDAO — dùng schema hiện có (GhepKeo, ChiTietGhepKeo) mà không cần migration bắt buộc.
 * Metadata phụ (số người cần tìm, hình thức duyệt) được encode trong cột MoTa dưới dạng
 * JSON prefix `[VS_META]{...}[/VS_META]` để tránh phụ thuộc vào cột mới.
 */
public class GhepKeoDAOImpl implements GhepKeoDAO {

    private static final Logger LOGGER = Logger.getLogger(GhepKeoDAOImpl.class.getName());

    // Trạng thái GhepKeo
    public static final String STATUS_OPEN = "Đang mở";
    public static final String STATUS_FULL = "Đã đủ người";
    public static final String STATUS_CANCELLED = "Đã hủy";
    public static final String STATUS_COMPLETED = "Đã hoàn thành";
    public static final String STATUS_CLOSED = "Đã đóng";

    // Trạng thái ChiTietGhepKeo
    public static final String P_STATUS_PENDING = "Chờ duyệt";
    public static final String P_STATUS_JOINED = "Đã tham gia";
    public static final String P_STATUS_REJECTED = "Đã từ chối";
    public static final String P_STATUS_LEFT = "Đã rời";

    private static final String META_PREFIX = "[VS_META]";
    private static final String META_SUFFIX = "[/VS_META]";

    // =========================================================================
    // Metadata encode/decode
    // =========================================================================

    /** Bọc metadata (soNguoiCanTim, hinhThucDuyet) + note thành chuỗi MoTa lưu DB. */
    public static String encodeMoTa(int soNguoiCanTim, String hinhThucDuyet, String note) {
        String approve = (hinhThucDuyet == null || hinhThucDuyet.isBlank()) ? "auto" : hinhThucDuyet;
        String safeNote = note == null ? "" : note;
        String meta = "{\"cap\":" + soNguoiCanTim + ",\"approve\":\"" + jsonEscape(approve) + "\"}";
        return META_PREFIX + meta + META_SUFFIX + safeNote;
    }

    private static String jsonEscape(String s) {
        return s == null ? "" : s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    /** Bóc metadata từ MoTa; đổ vào view. Nếu không có prefix → default cap=2, approve=auto. */
    public static void decodeMoTaInto(String moTa, GhepKeoView view) {
        view.soNguoiCanTim = 2;
        view.hinhThucDuyet = "auto";
        view.actualNote = moTa == null ? "" : moTa;
        if (moTa == null) return;
        int p1 = moTa.indexOf(META_PREFIX);
        int p2 = moTa.indexOf(META_SUFFIX);
        if (p1 == 0 && p2 > p1) {
            String json = moTa.substring(META_PREFIX.length(), p2);
            view.actualNote = moTa.substring(p2 + META_SUFFIX.length());
            // Parse tối giản — chỉ đọc cap và approve. Không dùng full JSON parser để giảm phụ thuộc.
            view.soNguoiCanTim = readIntField(json, "cap", 2);
            String approve = readStringField(json, "approve", "auto");
            if (!"auto".equalsIgnoreCase(approve) && !"manual".equalsIgnoreCase(approve)) approve = "auto";
            view.hinhThucDuyet = approve.toLowerCase();
        }
    }

    private static int readIntField(String json, String field, int def) {
        String key = "\"" + field + "\":";
        int idx = json.indexOf(key);
        if (idx < 0) return def;
        int start = idx + key.length();
        StringBuilder sb = new StringBuilder();
        while (start < json.length() && (Character.isDigit(json.charAt(start)) || json.charAt(start) == '-')) {
            sb.append(json.charAt(start)); start++;
        }
        if (sb.length() == 0) return def;
        try { return Integer.parseInt(sb.toString()); } catch (NumberFormatException e) { return def; }
    }

    private static String readStringField(String json, String field, String def) {
        String key = "\"" + field + "\":\"";
        int idx = json.indexOf(key);
        if (idx < 0) return def;
        int start = idx + key.length();
        int end = json.indexOf('"', start);
        while (end > 0 && json.charAt(end - 1) == '\\') end = json.indexOf('"', end + 1);
        if (end <= start) return def;
        return json.substring(start, end).replace("\\\"", "\"").replace("\\\\", "\\");
    }

    // =========================================================================
    // CRUD
    // =========================================================================

    @Override
    public int create(GhepKeo keo) {
        String sql = "INSERT INTO GhepKeo(DatSanID, AccountIDNguoiTao, MonTheThaoID, MoTa, TrinhDo, TrangThai) " +
                "VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, keo.getDatSanId());
            ps.setInt(2, keo.getAccountIdNguoiTao());
            if (keo.getMonTheThaoId() != null) ps.setInt(3, keo.getMonTheThaoId()); else ps.setNull(3, java.sql.Types.INTEGER);
            ps.setNString(4, keo.getMoTa() != null ? keo.getMoTa() : "");
            ps.setNString(5, keo.getTrinhDo() != null ? keo.getTrinhDo() : "");
            ps.setNString(6, keo.getTrangThai() != null ? keo.getTrangThai() : STATUS_OPEN);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "create GhepKeo failed", e);
        }
        return -1;
    }

    private static final String SELECT_VIEW_BASE =
            "SELECT g.KeoID, g.DatSanID, g.AccountIDNguoiTao, g.MonTheThaoID, g.MoTa, g.TrinhDo, g.TrangThai, " +
            "       tk.FullName AS TenNguoiTao, tk.DiemUyTin AS DiemUyTinNguoiTao, " +
            "       mtt.TenMon AS TenMonTheThao, " +
            "       l.NgayDat, l.GioBatDau, l.GioKetThuc, l.TrangThai AS TrangThaiBooking, " +
            "       s.SanID, s.TenSan, s.CoSoID, " +
            "       cs.TenCoSo, cs.DiaChi AS DiaChiCoSo, " +
            "       ls.TenLoai AS TenLoaiSan, " +
            "       (SELECT COUNT(*) FROM ChiTietGhepKeo p WHERE p.KeoID = g.KeoID AND p.TrangThaiThamGia = N'" + P_STATUS_JOINED + "') AS SoNguoiThamGia " +
            "FROM GhepKeo g " +
            "LEFT JOIN TaiKhoan tk ON g.AccountIDNguoiTao = tk.AccountID " +
            "LEFT JOIN LichDatSan l ON g.DatSanID = l.DatSanID " +
            "LEFT JOIN San s ON l.SanID = s.SanID " +
            "LEFT JOIN CoSo cs ON s.CoSoID = cs.CoSoID " +
            "LEFT JOIN LoaiSan ls ON s.LoaiSanID = ls.LoaiSanID " +
            "LEFT JOIN MonTheThao mtt ON g.MonTheThaoID = mtt.MonTheThaoID ";

    private GhepKeoView mapView(ResultSet rs) throws SQLException {
        GhepKeoView v = new GhepKeoView();
        v.keoId = rs.getInt("KeoID");
        v.datSanId = rs.getInt("DatSanID");
        v.accountIdNguoiTao = rs.getInt("AccountIDNguoiTao");
        Object monVal = rs.getObject("MonTheThaoID");
        v.monTheThaoId = monVal == null ? null : (int) monVal;
        v.tenMonTheThao = rs.getString("TenMonTheThao");
        v.moTa = rs.getString("MoTa");
        v.trinhDo = rs.getString("TrinhDo");
        v.trangThai = rs.getString("TrangThai");
        v.tenNguoiTao = rs.getString("TenNguoiTao");
        Object dutVal = rs.getObject("DiemUyTinNguoiTao");
        v.diemUyTinNguoiTao = dutVal == null ? null : (int) dutVal;
        java.sql.Date ngay = rs.getDate("NgayDat");
        v.ngayDat = ngay == null ? null : ngay.toLocalDate();
        java.sql.Time bd = rs.getTime("GioBatDau");
        v.gioBatDau = bd == null ? null : bd.toString().substring(0, 5);
        java.sql.Time kt = rs.getTime("GioKetThuc");
        v.gioKetThuc = kt == null ? null : kt.toString().substring(0, 5);
        v.trangThaiBooking = rs.getString("TrangThaiBooking");
        v.sanId = rs.getInt("SanID");
        v.tenSan = rs.getString("TenSan");
        v.coSoId = rs.getInt("CoSoID");
        v.tenCoSo = rs.getString("TenCoSo");
        v.diaChiCoSo = rs.getString("DiaChiCoSo");
        v.tenLoaiSan = rs.getString("TenLoaiSan");
        v.soNguoiThamGia = rs.getInt("SoNguoiThamGia");
        decodeMoTaInto(v.moTa, v);
        return v;
    }

    @Override
    public GhepKeoView getViewById(int keoId) {
        String sql = SELECT_VIEW_BASE + " WHERE g.KeoID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, keoId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapView(rs);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "getViewById failed keoId=" + keoId, e);
        }
        return null;
    }

    @Override
    public List<GhepKeoView> listOpenMatches(Integer coSoId, Integer monTheThaoId, LocalDate fromDate, LocalDate toDate) {
        StringBuilder sql = new StringBuilder(SELECT_VIEW_BASE);
        sql.append(" WHERE g.TrangThai = N'").append(STATUS_OPEN).append("' ");
        // Chỉ kèo có booking hợp lệ + booking không bị hủy + ngày chưa qua
        sql.append(" AND l.DatSanID IS NOT NULL AND l.TrangThai <> N'Đã hủy' AND l.NgayDat >= CAST(GETDATE() AS DATE) ");
        List<Object> params = new ArrayList<>();
        if (coSoId != null) { sql.append(" AND s.CoSoID = ?"); params.add(coSoId); }
        if (monTheThaoId != null) { sql.append(" AND g.MonTheThaoID = ?"); params.add(monTheThaoId); }
        if (fromDate != null) { sql.append(" AND l.NgayDat >= ?"); params.add(Date.valueOf(fromDate)); }
        if (toDate != null) { sql.append(" AND l.NgayDat <= ?"); params.add(Date.valueOf(toDate)); }
        sql.append(" ORDER BY l.NgayDat ASC, l.GioBatDau ASC");

        List<GhepKeoView> out = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                Object p = params.get(i);
                if (p instanceof Integer) ps.setInt(i + 1, (Integer) p);
                else if (p instanceof Date) ps.setDate(i + 1, (Date) p);
                else ps.setObject(i + 1, p);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    GhepKeoView v = mapView(rs);
                    // Loại bỏ kèo đã đủ người (server-side filter dựa trên soNguoiCanTim)
                    if (v.soNguoiThamGia < v.soNguoiCanTim) {
                        out.add(v);
                    }
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "listOpenMatches failed", e);
        }
        return out;
    }

    @Override
    public List<GhepKeoView> listByCreator(int accountId) {
        String sql = SELECT_VIEW_BASE + " WHERE g.AccountIDNguoiTao = ? ORDER BY g.KeoID DESC";
        return runViewQuery(sql, ps -> ps.setInt(1, accountId));
    }

    @Override
    public List<GhepKeoView> listByParticipant(int accountId) {
        String sql = SELECT_VIEW_BASE +
                " WHERE g.KeoID IN (SELECT p.KeoID FROM ChiTietGhepKeo p WHERE p.AccountIDNguoiThamGia = ? AND p.TrangThaiThamGia <> N'" + P_STATUS_LEFT + "') " +
                " ORDER BY l.NgayDat DESC";
        return runViewQuery(sql, ps -> ps.setInt(1, accountId));
    }

    private interface PsSetter { void set(PreparedStatement ps) throws SQLException; }
    private List<GhepKeoView> runViewQuery(String sql, PsSetter setter) {
        List<GhepKeoView> out = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            setter.set(ps);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) out.add(mapView(rs));
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "runViewQuery failed", e);
        }
        return out;
    }

    @Override
    public boolean updateStatusIfOwner(int keoId, String newStatus, int ownerAccountId) {
        String sql = "UPDATE GhepKeo SET TrangThai = ? WHERE KeoID = ? AND AccountIDNguoiTao = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setNString(1, newStatus);
            ps.setInt(2, keoId);
            ps.setInt(3, ownerAccountId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "updateStatusIfOwner failed keoId=" + keoId, e);
            return false;
        }
    }

    @Override
    public int addParticipant(int keoId, int accountId, String status, String position) throws Exception {
        // 1 transaction: lock (SELECT ... WITH UPDLOCK) → check trạng thái + capacity → insert
        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                // Bước 1: khoá row GhepKeo để tránh race condition
                int capacity;
                int accepted;
                String trangThaiKeo;
                int accountIdOwner;
                String sqlLock = "SELECT g.AccountIDNguoiTao, g.MoTa, g.TrangThai, " +
                        "       (SELECT COUNT(*) FROM ChiTietGhepKeo p WHERE p.KeoID = g.KeoID AND p.TrangThaiThamGia = N'" + P_STATUS_JOINED + "') AS Accepted " +
                        "FROM GhepKeo g WITH (UPDLOCK, ROWLOCK) WHERE g.KeoID = ?";
                try (PreparedStatement psLock = conn.prepareStatement(sqlLock)) {
                    psLock.setInt(1, keoId);
                    try (ResultSet rs = psLock.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            throw new IllegalStateException("Kèo không tồn tại.");
                        }
                        accountIdOwner = rs.getInt("AccountIDNguoiTao");
                        trangThaiKeo = rs.getString("TrangThai");
                        accepted = rs.getInt("Accepted");
                        String moTa = rs.getString("MoTa");
                        GhepKeoView tmp = new GhepKeoView();
                        decodeMoTaInto(moTa, tmp);
                        capacity = tmp.soNguoiCanTim;
                    }
                }

                if (accountId == accountIdOwner) {
                    conn.rollback();
                    throw new IllegalStateException("Bạn là chủ kèo, không cần xin tham gia.");
                }
                if (!STATUS_OPEN.equals(trangThaiKeo)) {
                    conn.rollback();
                    throw new IllegalStateException("Kèo hiện không nhận thêm người.");
                }
                if (accepted >= capacity) {
                    conn.rollback();
                    throw new IllegalStateException("Kèo đã đủ người.");
                }

                // Bước 2: kiểm tra đã tồn tại participant active của account này chưa
                String sqlCheck = "SELECT ChiTietKeoID, TrangThaiThamGia FROM ChiTietGhepKeo " +
                        "WHERE KeoID = ? AND AccountIDNguoiThamGia = ? AND TrangThaiThamGia IN (N'" + P_STATUS_JOINED + "', N'" + P_STATUS_PENDING + "')";
                try (PreparedStatement psCheck = conn.prepareStatement(sqlCheck)) {
                    psCheck.setInt(1, keoId); psCheck.setInt(2, accountId);
                    try (ResultSet rs = psCheck.executeQuery()) {
                        if (rs.next()) {
                            int existingId = rs.getInt("ChiTietKeoID");
                            conn.rollback();
                            throw new IllegalStateException("Bạn đã tham gia hoặc đang chờ duyệt kèo này (mã " + existingId + ").");
                        }
                    }
                }

                // Bước 3: insert
                String sqlIns = "INSERT INTO ChiTietGhepKeo(KeoID, AccountIDNguoiThamGia, TrangThaiThamGia, ViTriThamGia) VALUES (?, ?, ?, ?)";
                int newId = -1;
                try (PreparedStatement psIns = conn.prepareStatement(sqlIns, Statement.RETURN_GENERATED_KEYS)) {
                    psIns.setInt(1, keoId);
                    psIns.setInt(2, accountId);
                    psIns.setNString(3, status != null ? status : P_STATUS_JOINED);
                    psIns.setNString(4, position != null ? position : "");
                    psIns.executeUpdate();
                    try (ResultSet rs = psIns.getGeneratedKeys()) {
                        if (rs.next()) newId = rs.getInt(1);
                    }
                }

                // Bước 4: nếu vừa đủ người → set TrangThai = "Đã đủ người"
                if (P_STATUS_JOINED.equals(status) && (accepted + 1) >= capacity) {
                    try (PreparedStatement psUp = conn.prepareStatement(
                            "UPDATE GhepKeo SET TrangThai = ? WHERE KeoID = ? AND TrangThai = ?")) {
                        psUp.setNString(1, STATUS_FULL);
                        psUp.setInt(2, keoId);
                        psUp.setNString(3, STATUS_OPEN);
                        psUp.executeUpdate();
                    }
                }

                conn.commit();
                return newId;
            } catch (Exception ex) {
                try { conn.rollback(); } catch (SQLException ignored) {}
                throw ex;
            }
        }
    }

    @Override
    public boolean updateParticipantStatus(int chiTietKeoId, String newStatus, int actorAccountId, boolean actorIsOwner) {
        String sql;
        if (actorIsOwner) {
            // Chủ kèo có thể duyệt/từ chối bất kỳ participant của kèo mình
            sql = "UPDATE ChiTietGhepKeo SET TrangThaiThamGia = ? " +
                  "WHERE ChiTietKeoID = ? AND KeoID IN (SELECT KeoID FROM GhepKeo WHERE AccountIDNguoiTao = ?)";
        } else {
            // Người chơi chỉ có thể tự đổi trạng thái của chính mình sang "Đã rời"
            sql = "UPDATE ChiTietGhepKeo SET TrangThaiThamGia = ? WHERE ChiTietKeoID = ? AND AccountIDNguoiThamGia = ?";
        }
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setNString(1, newStatus);
            ps.setInt(2, chiTietKeoId);
            ps.setInt(3, actorAccountId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "updateParticipantStatus failed", e);
            return false;
        }
    }

    @Override
    public int countAcceptedParticipants(int keoId) {
        String sql = "SELECT COUNT(*) FROM ChiTietGhepKeo WHERE KeoID = ? AND TrangThaiThamGia = N'" + P_STATUS_JOINED + "'";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, keoId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "countAcceptedParticipants failed", e);
        }
        return 0;
    }

    @Override
    public List<ChiTietGhepKeoView> listParticipants(int keoId) {
        String sql = "SELECT p.ChiTietKeoID, p.KeoID, p.AccountIDNguoiThamGia, p.TrangThaiThamGia, p.ViTriThamGia, " +
                "       tk.FullName AS TenNguoiChoi, tk.DiemUyTin AS DiemUyTin " +
                "FROM ChiTietGhepKeo p LEFT JOIN TaiKhoan tk ON p.AccountIDNguoiThamGia = tk.AccountID " +
                "WHERE p.KeoID = ? ORDER BY p.ChiTietKeoID ASC";
        List<ChiTietGhepKeoView> out = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, keoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ChiTietGhepKeoView v = new ChiTietGhepKeoView();
                    v.chiTietKeoId = rs.getInt("ChiTietKeoID");
                    v.keoId = rs.getInt("KeoID");
                    v.accountId = rs.getInt("AccountIDNguoiThamGia");
                    v.trangThaiThamGia = rs.getString("TrangThaiThamGia");
                    v.viTriThamGia = rs.getString("ViTriThamGia");
                    v.tenNguoiChoi = rs.getString("TenNguoiChoi");
                    Object dut = rs.getObject("DiemUyTin");
                    v.diemUyTin = dut == null ? null : (int) dut;
                    out.add(v);
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "listParticipants failed", e);
        }
        return out;
    }

    @Override
    public ChiTietGhepKeoView getActiveParticipant(int keoId, int accountId) {
        String sql = "SELECT p.ChiTietKeoID, p.KeoID, p.AccountIDNguoiThamGia, p.TrangThaiThamGia, p.ViTriThamGia, " +
                "       tk.FullName AS TenNguoiChoi, tk.DiemUyTin AS DiemUyTin " +
                "FROM ChiTietGhepKeo p LEFT JOIN TaiKhoan tk ON p.AccountIDNguoiThamGia = tk.AccountID " +
                "WHERE p.KeoID = ? AND p.AccountIDNguoiThamGia = ? AND p.TrangThaiThamGia IN (N'" + P_STATUS_PENDING + "', N'" + P_STATUS_JOINED + "') " +
                "ORDER BY p.ChiTietKeoID DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, keoId); ps.setInt(2, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    ChiTietGhepKeoView v = new ChiTietGhepKeoView();
                    v.chiTietKeoId = rs.getInt("ChiTietKeoID");
                    v.keoId = rs.getInt("KeoID");
                    v.accountId = rs.getInt("AccountIDNguoiThamGia");
                    v.trangThaiThamGia = rs.getString("TrangThaiThamGia");
                    v.viTriThamGia = rs.getString("ViTriThamGia");
                    v.tenNguoiChoi = rs.getString("TenNguoiChoi");
                    Object dut = rs.getObject("DiemUyTin");
                    v.diemUyTin = dut == null ? null : (int) dut;
                    return v;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "getActiveParticipant failed", e);
        }
        return null;
    }
}
