package org.example.dao.impl;

import org.example.dao.TeamMatchDAO;
import org.example.dto.TeamChallengeDTO;
import org.example.dto.TeamMatchSummaryDTO;
import org.example.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

/**
 * Xem javadoc TeamMatchDAO. Các hằng trạng thái dưới đây PHẢI khớp đúng
 * literal Vietnamese string mà GhepKeoDAOImpl đang dùng cho GhepKeo.TrangThai
 * / ChiTietGhepKeo.TrangThaiThamGia — không có CHECK constraint ở DB, so
 * khớp là bắt buộc để 2 domain (kèo cá nhân / kèo đội) đọc chung một cột.
 */
public class TeamMatchDAOImpl implements TeamMatchDAO {

    private static final String KEO_STATUS_OPEN = "Đang mở";
    private static final String KEO_STATUS_FULL = "Đã đủ người";
    private static final String KEO_STATUS_CANCELLED = "Đã hủy";

    private static final String P_STATUS_PENDING = "Chờ duyệt";
    private static final String P_STATUS_JOINED = "Đã tham gia";
    private static final String P_STATUS_REJECTED = "Đã từ chối";

    private static final String SELECT_SUMMARY_BASE =
            "SELECT g.KeoID, g.TeamIDNguoiTao, t.TeamName AS TeamNameNguoiTao, g.DatSanID, " +
                    "l.NgayDat, l.GioBatDau, l.GioKetThuc, s.TenSan, c.TenCoSo, c.DiaChi, " +
                    "g.MonTheThaoID, mt.TenMon, g.TrinhDo, g.TrangThai, g.MoTa AS Note, " +
                    "opp.TeamID AS OpponentTeamId, opp.TeamName AS OpponentTeamName, " +
                    "(SELECT COUNT(*) FROM ChiTietGhepKeo p WHERE p.KeoID = g.KeoID AND p.TrangThaiThamGia = N'" + P_STATUS_PENDING + "') AS PendingChallengeCount " +
                    "FROM GhepKeo g " +
                    "JOIN Teams t ON t.TeamID = g.TeamIDNguoiTao " +
                    "JOIN LichDatSan l ON l.DatSanID = g.DatSanID " +
                    "JOIN San s ON s.SanID = l.SanID " +
                    "JOIN CoSo c ON c.CoSoID = s.CoSoID " +
                    "LEFT JOIN MonTheThao mt ON mt.MonTheThaoID = g.MonTheThaoID " +
                    "LEFT JOIN ChiTietGhepKeo matched ON matched.KeoID = g.KeoID AND matched.TrangThaiThamGia = N'" + P_STATUS_JOINED + "' " +
                    "LEFT JOIN Teams opp ON opp.TeamID = matched.TeamIDNguoiThamGia ";

    @Override
    public int createTeamMatch(int teamId, int captainAccountId, int datSanId, Integer monTheThaoId, String trinhDo, String note) throws Exception {
        String sql = "INSERT INTO GhepKeo (DatSanID, AccountIDNguoiTao, MonTheThaoID, MoTa, TrinhDo, TrangThai, TeamIDNguoiTao) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, datSanId);
            ps.setInt(2, captainAccountId);
            if (monTheThaoId != null) ps.setInt(3, monTheThaoId); else ps.setNull(3, Types.INTEGER);
            ps.setString(4, note);
            ps.setString(5, trinhDo);
            ps.setString(6, KEO_STATUS_OPEN);
            ps.setInt(7, teamId);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (!rs.next()) throw new IllegalStateException("Không thể tạo kèo đội.");
                return rs.getInt(1);
            }
        }
    }

    @Override
    public List<TeamMatchSummaryDTO> listOpenTeamMatches(Integer sportId, Integer excludeTeamId) {
        StringBuilder sql = new StringBuilder(SELECT_SUMMARY_BASE);
        sql.append("WHERE g.TeamIDNguoiTao IS NOT NULL AND g.TrangThai = N'").append(KEO_STATUS_OPEN).append("'");
        if (sportId != null) sql.append(" AND g.MonTheThaoID = ?");
        if (excludeTeamId != null) sql.append(" AND g.TeamIDNguoiTao <> ?");
        sql.append(" ORDER BY l.NgayDat ASC, l.GioBatDau ASC");

        List<TeamMatchSummaryDTO> result = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int idx = 1;
            if (sportId != null) ps.setInt(idx++, sportId);
            if (excludeTeamId != null) ps.setInt(idx++, excludeTeamId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapSummary(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi truy vấn danh sách kèo đội đang mở", e);
        }
        return result;
    }

    @Override
    public List<TeamMatchSummaryDTO> listMyTeamMatches(int teamId) {
        String sql = SELECT_SUMMARY_BASE + "WHERE g.TeamIDNguoiTao = ? ORDER BY g.KeoID DESC";
        List<TeamMatchSummaryDTO> result = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, teamId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapSummary(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi truy vấn kèo đội của đội ID " + teamId, e);
        }
        return result;
    }

    @Override
    public TeamMatchSummaryDTO getTeamMatchDetail(int keoId) {
        String sql = SELECT_SUMMARY_BASE + "WHERE g.KeoID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, keoId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapSummary(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi truy vấn kèo đội ID " + keoId, e);
        }
        return null;
    }

    @Override
    public int challengeTeamMatch(int keoId, int challengerTeamId, int captainAccountId) throws Exception {
        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int ownerTeamId;
                Integer sportId;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT TeamIDNguoiTao, MonTheThaoID, TrangThai FROM GhepKeo WITH (UPDLOCK, ROWLOCK) WHERE KeoID = ?")) {
                    ps.setInt(1, keoId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) { conn.rollback(); throw new IllegalStateException("Kèo đội không tồn tại."); }
                        ownerTeamId = rs.getInt("TeamIDNguoiTao");
                        if (rs.wasNull()) { conn.rollback(); throw new IllegalStateException("Đây không phải kèo đội."); }
                        int sid = rs.getInt("MonTheThaoID");
                        sportId = rs.wasNull() ? null : sid;
                        if (!KEO_STATUS_OPEN.equals(rs.getString("TrangThai"))) { conn.rollback(); throw new IllegalStateException("Kèo hiện không nhận thách đấu."); }
                    }
                }
                if (ownerTeamId == challengerTeamId) { conn.rollback(); throw new IllegalStateException("Đội không thể tự thách đấu chính mình."); }

                if (sportId != null) {
                    try (PreparedStatement ps = conn.prepareStatement("SELECT SportID FROM Teams WHERE TeamID = ?")) {
                        ps.setInt(1, challengerTeamId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next() && rs.getInt("SportID") != sportId) {
                                conn.rollback();
                                throw new IllegalStateException("Môn thể thao của đội bạn không khớp với kèo này.");
                            }
                        }
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM ChiTietGhepKeo WHERE KeoID = ? AND TeamIDNguoiThamGia = ? AND TrangThaiThamGia IN (N'" + P_STATUS_PENDING + "', N'" + P_STATUS_JOINED + "')")) {
                    ps.setInt(1, keoId);
                    ps.setInt(2, challengerTeamId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && rs.getInt(1) > 0) { conn.rollback(); throw new IllegalStateException("Đội bạn đã gửi thách đấu cho kèo này rồi."); }
                    }
                }

                int newId;
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO ChiTietGhepKeo (KeoID, AccountIDNguoiThamGia, TrangThaiThamGia, ViTriThamGia, TeamIDNguoiThamGia) VALUES (?, ?, ?, ?, ?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, keoId);
                    ps.setInt(2, captainAccountId);
                    ps.setNString(3, P_STATUS_PENDING);
                    ps.setNString(4, "");
                    ps.setInt(5, challengerTeamId);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (!rs.next()) { conn.rollback(); throw new IllegalStateException("Không thể gửi thách đấu."); }
                        newId = rs.getInt(1);
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
    public List<TeamChallengeDTO> getPendingChallenges(int keoId) {
        String sql = "SELECT c.ChiTietKeoID, c.KeoID, c.TeamIDNguoiThamGia, t.TeamName, t.AvatarPath, c.TrangThaiThamGia " +
                "FROM ChiTietGhepKeo c JOIN Teams t ON t.TeamID = c.TeamIDNguoiThamGia " +
                "WHERE c.KeoID = ? AND c.TrangThaiThamGia = N'" + P_STATUS_PENDING + "' ORDER BY c.ChiTietKeoID ASC";
        List<TeamChallengeDTO> result = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, keoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    TeamChallengeDTO dto = new TeamChallengeDTO();
                    dto.setChiTietKeoId(rs.getInt("ChiTietKeoID"));
                    dto.setKeoId(rs.getInt("KeoID"));
                    dto.setChallengerTeamId(rs.getInt("TeamIDNguoiThamGia"));
                    dto.setChallengerTeamName(rs.getString("TeamName"));
                    dto.setChallengerTeamAvatarPath(rs.getString("AvatarPath"));
                    dto.setStatus(rs.getString("TrangThaiThamGia"));
                    result.add(dto);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi truy vấn thách đấu đang chờ cho kèo ID " + keoId, e);
        }
        return result;
    }

    @Override
    public boolean acceptChallenge(int chiTietKeoId, int ownerTeamId) throws Exception {
        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int keoId;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT KeoID, TrangThaiThamGia FROM ChiTietGhepKeo WITH (UPDLOCK, ROWLOCK) WHERE ChiTietKeoID = ?")) {
                    ps.setInt(1, chiTietKeoId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) { conn.rollback(); throw new IllegalStateException("Thách đấu không tồn tại."); }
                        if (!P_STATUS_PENDING.equals(rs.getString("TrangThaiThamGia"))) { conn.rollback(); throw new IllegalStateException("Thách đấu đã được xử lý trước đó."); }
                        keoId = rs.getInt("KeoID");
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT TeamIDNguoiTao, TrangThai FROM GhepKeo WITH (UPDLOCK, ROWLOCK) WHERE KeoID = ?")) {
                    ps.setInt(1, keoId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) { conn.rollback(); throw new IllegalStateException("Kèo đội không tồn tại."); }
                        if (rs.getInt("TeamIDNguoiTao") != ownerTeamId) { conn.rollback(); throw new IllegalStateException("Thách đấu này không thuộc kèo của đội bạn."); }
                        if (!KEO_STATUS_OPEN.equals(rs.getString("TrangThai"))) { conn.rollback(); throw new IllegalStateException("Kèo đã được xử lý (đã đủ đội hoặc đã hủy)."); }
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE ChiTietGhepKeo SET TrangThaiThamGia = ? WHERE ChiTietKeoID = ?")) {
                    ps.setNString(1, P_STATUS_JOINED);
                    ps.setInt(2, chiTietKeoId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE ChiTietGhepKeo SET TrangThaiThamGia = ? WHERE KeoID = ? AND ChiTietKeoID <> ? AND TrangThaiThamGia = ?")) {
                    ps.setNString(1, P_STATUS_REJECTED);
                    ps.setInt(2, keoId);
                    ps.setInt(3, chiTietKeoId);
                    ps.setNString(4, P_STATUS_PENDING);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE GhepKeo SET TrangThai = ? WHERE KeoID = ?")) {
                    ps.setNString(1, KEO_STATUS_FULL);
                    ps.setInt(2, keoId);
                    ps.executeUpdate();
                }
                conn.commit();
                return true;
            } catch (Exception ex) {
                try { conn.rollback(); } catch (SQLException ignored) {}
                throw ex;
            }
        }
    }

    @Override
    public boolean rejectChallenge(int chiTietKeoId, int ownerTeamId) {
        String sql = "UPDATE c SET c.TrangThaiThamGia = ? " +
                "FROM ChiTietGhepKeo c JOIN GhepKeo g ON g.KeoID = c.KeoID " +
                "WHERE c.ChiTietKeoID = ? AND g.TeamIDNguoiTao = ? AND c.TrangThaiThamGia = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setNString(1, P_STATUS_REJECTED);
            ps.setInt(2, chiTietKeoId);
            ps.setInt(3, ownerTeamId);
            ps.setNString(4, P_STATUS_PENDING);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi từ chối thách đấu", e);
        }
    }

    @Override
    public boolean cancelTeamMatch(int keoId, int ownerTeamId) {
        String sql = "UPDATE GhepKeo SET TrangThai = ? WHERE KeoID = ? AND TeamIDNguoiTao = ? AND TrangThai = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setNString(1, KEO_STATUS_CANCELLED);
            ps.setInt(2, keoId);
            ps.setInt(3, ownerTeamId);
            ps.setNString(4, KEO_STATUS_OPEN);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi hủy kèo đội", e);
        }
    }

    private TeamMatchSummaryDTO mapSummary(ResultSet rs) throws SQLException {
        TeamMatchSummaryDTO dto = new TeamMatchSummaryDTO();
        dto.setKeoId(rs.getInt("KeoID"));
        dto.setTeamIdNguoiTao(rs.getInt("TeamIDNguoiTao"));
        dto.setTeamNameNguoiTao(rs.getString("TeamNameNguoiTao"));
        dto.setDatSanId(rs.getInt("DatSanID"));
        java.sql.Date ngayDat = rs.getDate("NgayDat");
        dto.setNgayDat(ngayDat != null ? ngayDat.toLocalDate().toString() : null);
        java.sql.Time gioBatDau = rs.getTime("GioBatDau");
        dto.setGioBatDau(gioBatDau != null ? gioBatDau.toLocalTime().toString().substring(0, 5) : null);
        java.sql.Time gioKetThuc = rs.getTime("GioKetThuc");
        dto.setGioKetThuc(gioKetThuc != null ? gioKetThuc.toLocalTime().toString().substring(0, 5) : null);
        dto.setTenSan(rs.getString("TenSan"));
        dto.setTenCoSo(rs.getString("TenCoSo"));
        dto.setDiaChi(rs.getString("DiaChi"));
        int monTheThaoId = rs.getInt("MonTheThaoID");
        dto.setMonTheThaoId(rs.wasNull() ? null : monTheThaoId);
        dto.setTenMon(rs.getString("TenMon"));
        dto.setTrinhDo(rs.getString("TrinhDo"));
        dto.setTrangThai(rs.getString("TrangThai"));
        dto.setNote(rs.getString("Note"));
        int opponentTeamId = rs.getInt("OpponentTeamId");
        dto.setOpponentTeamId(rs.wasNull() ? null : opponentTeamId);
        dto.setOpponentTeamName(rs.getString("OpponentTeamName"));
        dto.setPendingChallengeCount(rs.getInt("PendingChallengeCount"));
        return dto;
    }
}
