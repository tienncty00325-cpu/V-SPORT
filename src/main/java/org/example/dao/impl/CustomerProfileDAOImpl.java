package org.example.dao.impl;

import org.example.dao.CustomerProfileDAO;
import org.example.dto.CustomerProfileExtraDTO;
import org.example.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

public class CustomerProfileDAOImpl implements CustomerProfileDAO {

    @Override
    public CustomerProfileExtraDTO getExtra(int accountId) throws SQLException {
        String sql = "SELECT a.CoverImageUrl, a.ChieuCaoCm, a.CanNangKg, a.GhiChuDacBiet, a.ViTriYeuThich, " +
                "a.MonTheThaoYeuThichID, mt.TenMon AS FavoriteSportName, a.TrinhDoChoi, a.MucTieuChoi, a.TanSuatChoi " +
                "FROM dbo.Accounts a " +
                "LEFT JOIN dbo.MonTheThao mt ON mt.MonTheThaoID = a.MonTheThaoYeuThichID " +
                "WHERE a.AccountID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                CustomerProfileExtraDTO dto = new CustomerProfileExtraDTO();
                if (rs.next()) {
                    dto.setCoverImageUrl(rs.getString("CoverImageUrl"));
                    int height = rs.getInt("ChieuCaoCm");
                    dto.setHeightCm(rs.wasNull() ? null : height);
                    int weight = rs.getInt("CanNangKg");
                    dto.setWeightKg(rs.wasNull() ? null : weight);
                    dto.setSpecialNote(rs.getString("GhiChuDacBiet"));
                    dto.setPreferredLocation(rs.getString("ViTriYeuThich"));
                    int sportId = rs.getInt("MonTheThaoYeuThichID");
                    dto.setFavoriteSportId(rs.wasNull() ? null : sportId);
                    dto.setFavoriteSportName(rs.getString("FavoriteSportName"));
                    dto.setSkillLevel(rs.getString("TrinhDoChoi"));
                    dto.setGoal(rs.getString("MucTieuChoi"));
                    dto.setPlayFrequency(rs.getString("TanSuatChoi"));
                }
                return dto;
            }
        }
    }

    @Override
    public boolean updatePhysical(int accountId, Integer heightCm, Integer weightKg) throws SQLException {
        String sql = "UPDATE dbo.Accounts SET ChieuCaoCm = ?, CanNangKg = ? WHERE AccountID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            if (heightCm != null) ps.setInt(1, heightCm); else ps.setNull(1, Types.INTEGER);
            if (weightKg != null) ps.setInt(2, weightKg); else ps.setNull(2, Types.INTEGER);
            ps.setInt(3, accountId);
            return ps.executeUpdate() > 0;
        }
    }

    @Override
    public boolean updateNote(int accountId, String note) throws SQLException {
        String sql = "UPDATE dbo.Accounts SET GhiChuDacBiet = ? WHERE AccountID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            if (note != null) ps.setString(1, note); else ps.setNull(1, Types.NVARCHAR);
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        }
    }

    @Override
    public boolean updatePersonalization(int accountId, String location, Integer sportId, String level, String goal, String frequency) throws SQLException {
        String sql = "UPDATE dbo.Accounts SET ViTriYeuThich = ?, MonTheThaoYeuThichID = ?, TrinhDoChoi = ?, MucTieuChoi = ?, TanSuatChoi = ? WHERE AccountID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            if (location != null) ps.setString(1, location); else ps.setNull(1, Types.NVARCHAR);
            if (sportId != null) ps.setInt(2, sportId); else ps.setNull(2, Types.INTEGER);
            if (level != null) ps.setString(3, level); else ps.setNull(3, Types.VARCHAR);
            if (goal != null) ps.setString(4, goal); else ps.setNull(4, Types.NVARCHAR);
            if (frequency != null) ps.setString(5, frequency); else ps.setNull(5, Types.VARCHAR);
            ps.setInt(6, accountId);
            return ps.executeUpdate() > 0;
        }
    }

    @Override
    public boolean updateCoverPath(int accountId, String coverPath) throws SQLException {
        String sql = "UPDATE dbo.Accounts SET CoverImageUrl = ? WHERE AccountID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, coverPath);
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        }
    }
}
