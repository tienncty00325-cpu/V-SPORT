package org.example.dao.impl;

import org.example.dao.TeamDAO;
import org.example.dto.TeamDetailDTO;
import org.example.dto.TeamInvitationDTO;
import org.example.dto.TeamJoinRequestDTO;
import org.example.dto.TeamMemberDTO;
import org.example.dto.TeamSummaryDTO;
import org.example.model.Team;
import org.example.model.TeamInvitation;
import org.example.model.TeamJoinRequest;
import org.example.model.TeamMember;
import org.example.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class TeamDAOImpl implements TeamDAO {

    // ============================ Create / read Team ============================

    @Override
    public int createTeamWithCaptain(Team team) throws Exception {
        String sqlTeam = "INSERT INTO dbo.Teams (TeamName, Description, SportID, CaptainAccountID, LocationText, AvatarPath, CoverImagePath, MaxMembers, Status) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        String sqlMember = "INSERT INTO dbo.TeamMembers (TeamID, AccountID, MemberRole, MemberStatus) VALUES (?, ?, ?, ?)";

        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int teamId;
                try (PreparedStatement ps = conn.prepareStatement(sqlTeam, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, team.getTeamName());
                    ps.setString(2, team.getDescription());
                    ps.setInt(3, team.getSportId());
                    ps.setInt(4, team.getCaptainAccountId());
                    ps.setString(5, team.getLocationText());
                    ps.setString(6, team.getAvatarPath());
                    ps.setString(7, team.getCoverImagePath());
                    ps.setInt(8, team.getMaxMembers());
                    ps.setString(9, Team.STATUS_ACTIVE);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (!rs.next()) {
                            conn.rollback();
                            throw new IllegalStateException("Không thể tạo đội.");
                        }
                        teamId = rs.getInt(1);
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement(sqlMember)) {
                    ps.setInt(1, teamId);
                    ps.setInt(2, team.getCaptainAccountId());
                    ps.setString(3, TeamMember.ROLE_CAPTAIN);
                    ps.setString(4, TeamMember.STATUS_ACTIVE);
                    ps.executeUpdate();
                }
                conn.commit();
                return teamId;
            } catch (Exception ex) {
                try { conn.rollback(); } catch (SQLException ignored) {}
                throw ex;
            }
        }
    }

    @Override
    public Team getTeamById(int teamId) {
        String sql = "SELECT TeamID, TeamName, Description, SportID, CaptainAccountID, LocationText, AvatarPath, CoverImagePath, " +
                "MaxMembers, Status, CreatedAt, UpdatedAt, IsDeleted, DeletedAt, DeletedBy FROM dbo.Teams WHERE TeamID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, teamId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapTeam(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi truy vấn Team ID " + teamId, e);
        }
        return null;
    }

    @Override
    public boolean isTeamNameTakenForCaptain(int captainAccountId, String teamName, Integer excludeTeamId) {
        StringBuilder sql = new StringBuilder(
                "SELECT COUNT(*) FROM dbo.Teams WHERE CaptainAccountID = ? AND LOWER(TeamName) = LOWER(?) " +
                        "AND Status = 'ACTIVE' AND (IsDeleted = 0 OR IsDeleted IS NULL)");
        if (excludeTeamId != null) sql.append(" AND TeamID <> ?");
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            ps.setInt(1, captainAccountId);
            ps.setString(2, teamName);
            if (excludeTeamId != null) ps.setInt(3, excludeTeamId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi kiểm tra trùng tên đội", e);
        }
    }

    @Override
    public boolean updateTeam(Team team) {
        String sql = "UPDATE dbo.Teams SET TeamName = ?, Description = ?, SportID = ?, LocationText = ?, MaxMembers = ?, UpdatedAt = SYSUTCDATETIME() " +
                "WHERE TeamID = ? AND (IsDeleted = 0 OR IsDeleted IS NULL)";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, team.getTeamName());
            ps.setString(2, team.getDescription());
            ps.setInt(3, team.getSportId());
            ps.setString(4, team.getLocationText());
            ps.setInt(5, team.getMaxMembers());
            ps.setInt(6, team.getTeamId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi cập nhật đội ID " + team.getTeamId(), e);
        }
    }

    @Override
    public boolean updateAvatarPath(int teamId, String avatarPath) {
        return updatePathColumn(teamId, "AvatarPath", avatarPath);
    }

    @Override
    public boolean updateCoverImagePath(int teamId, String coverImagePath) {
        return updatePathColumn(teamId, "CoverImagePath", coverImagePath);
    }

    private boolean updatePathColumn(int teamId, String column, String value) {
        String sql = "UPDATE dbo.Teams SET " + column + " = ?, UpdatedAt = SYSUTCDATETIME() WHERE TeamID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, value);
            ps.setInt(2, teamId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi cập nhật " + column + " cho đội ID " + teamId, e);
        }
    }

    // ============================ Listing ============================

    @Override
    public List<TeamSummaryDTO> getMyTeams(int accountId) {
        String sql = "SELECT t.TeamID, t.TeamName, t.Description, t.SportID, mt.TenMon AS SportName, t.LocationText, t.AvatarPath, " +
                "t.MaxMembers, t.Status, tm.MemberRole, " +
                "(SELECT COUNT(*) FROM dbo.TeamMembers x WHERE x.TeamID = t.TeamID AND x.MemberStatus = 'ACTIVE') AS MemberCount " +
                "FROM dbo.Teams t " +
                "JOIN dbo.TeamMembers tm ON tm.TeamID = t.TeamID AND tm.AccountID = ? AND tm.MemberStatus = 'ACTIVE' " +
                "LEFT JOIN MonTheThao mt ON mt.MonTheThaoID = t.SportID " +
                "WHERE (t.IsDeleted = 0 OR t.IsDeleted IS NULL) " +
                "ORDER BY t.CreatedAt DESC";
        List<TeamSummaryDTO> result = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    TeamSummaryDTO dto = mapSummary(rs);
                    dto.setMyRole(rs.getString("MemberRole"));
                    result.add(dto);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi truy vấn danh sách đội của tôi", e);
        }
        return result;
    }

    @Override
    public List<TeamSummaryDTO> discoverTeams(int accountId, String keyword, Integer sportId, boolean onlyOpenSlots) {
        StringBuilder sql = new StringBuilder(
                "SELECT t.TeamID, t.TeamName, t.Description, t.SportID, mt.TenMon AS SportName, t.LocationText, t.AvatarPath, " +
                        "t.MaxMembers, t.Status, " +
                        "(SELECT COUNT(*) FROM dbo.TeamMembers x WHERE x.TeamID = t.TeamID AND x.MemberStatus = 'ACTIVE') AS MemberCount, " +
                        "CASE WHEN EXISTS (SELECT 1 FROM dbo.TeamJoinRequests jr WHERE jr.TeamID = t.TeamID AND jr.RequesterAccountID = ? AND jr.Status = 'PENDING') " +
                        "     THEN 1 ELSE 0 END AS HasPendingJoinRequest " +
                        "FROM dbo.Teams t " +
                        "LEFT JOIN MonTheThao mt ON mt.MonTheThaoID = t.SportID " +
                        "WHERE t.Status = 'ACTIVE' AND (t.IsDeleted = 0 OR t.IsDeleted IS NULL) " +
                        "  AND NOT EXISTS (SELECT 1 FROM dbo.TeamMembers tm WHERE tm.TeamID = t.TeamID AND tm.AccountID = ? AND tm.MemberStatus = 'ACTIVE')");
        boolean hasKeyword = keyword != null && !keyword.trim().isEmpty();
        if (hasKeyword) {
            sql.append(" AND (LOWER(t.TeamName) LIKE ? ESCAPE '\\' OR LOWER(t.LocationText) LIKE ? ESCAPE '\\')");
        }
        if (sportId != null) {
            sql.append(" AND t.SportID = ?");
        }
        if (onlyOpenSlots) {
            sql.append(" AND (SELECT COUNT(*) FROM dbo.TeamMembers x WHERE x.TeamID = t.TeamID AND x.MemberStatus = 'ACTIVE') < t.MaxMembers");
        }
        sql.append(" ORDER BY t.CreatedAt DESC");

        List<TeamSummaryDTO> result = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int idx = 1;
            ps.setInt(idx++, accountId);
            ps.setInt(idx++, accountId);
            if (hasKeyword) {
                String escaped = keyword.trim().toLowerCase()
                        .replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
                String pattern = "%" + escaped + "%";
                ps.setString(idx++, pattern);
                ps.setString(idx++, pattern);
            }
            if (sportId != null) {
                ps.setInt(idx++, sportId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    TeamSummaryDTO dto = mapSummary(rs);
                    dto.setHasPendingJoinRequest(rs.getInt("HasPendingJoinRequest") == 1);
                    result.add(dto);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi tìm kiếm đội", e);
        }
        return result;
    }

    @Override
    public TeamDetailDTO getTeamDetail(int teamId, int viewerAccountId) {
        String sql = "SELECT t.TeamID, t.TeamName, t.Description, t.SportID, mt.TenMon AS SportName, t.LocationText, t.AvatarPath, " +
                "t.CoverImagePath, t.MaxMembers, t.Status, t.CreatedAt, t.CaptainAccountID, cap.FullName AS CaptainName, " +
                "(SELECT COUNT(*) FROM dbo.TeamMembers x WHERE x.TeamID = t.TeamID AND x.MemberStatus = 'ACTIVE') AS MemberCount, " +
                "viewer.MemberRole AS ViewerRole " +
                "FROM dbo.Teams t " +
                "LEFT JOIN MonTheThao mt ON mt.MonTheThaoID = t.SportID " +
                "LEFT JOIN Accounts cap ON cap.AccountID = t.CaptainAccountID " +
                "LEFT JOIN dbo.TeamMembers viewer ON viewer.TeamID = t.TeamID AND viewer.AccountID = ? AND viewer.MemberStatus = 'ACTIVE' " +
                "WHERE t.TeamID = ? AND (t.IsDeleted = 0 OR t.IsDeleted IS NULL)";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, viewerAccountId);
            ps.setInt(2, teamId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                TeamDetailDTO dto = new TeamDetailDTO();
                dto.setTeamId(rs.getInt("TeamID"));
                dto.setTeamName(rs.getString("TeamName"));
                dto.setDescription(rs.getString("Description"));
                dto.setSportId(rs.getInt("SportID"));
                dto.setSportName(rs.getString("SportName"));
                dto.setLocationText(rs.getString("LocationText"));
                dto.setAvatarPath(rs.getString("AvatarPath"));
                dto.setCoverImagePath(rs.getString("CoverImagePath"));
                dto.setMaxMembers(rs.getInt("MaxMembers"));
                dto.setStatus(rs.getString("Status"));
                Timestamp createdAt = rs.getTimestamp("CreatedAt");
                dto.setCreatedAt(createdAt != null ? createdAt.toLocalDateTime().toString() : null);
                dto.setCaptainAccountId(rs.getInt("CaptainAccountID"));
                dto.setCaptainName(rs.getString("CaptainName"));
                dto.setMemberCount(rs.getInt("MemberCount"));
                String viewerRole = rs.getString("ViewerRole");
                dto.setMyRole(viewerRole);
                dto.setCaptain(TeamMember.ROLE_CAPTAIN.equals(viewerRole));
                dto.setCoCaptain(TeamMember.ROLE_CO_CAPTAIN.equals(viewerRole));
                dto.setMembers(getMembers(teamId));
                return dto;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi truy vấn chi tiết đội ID " + teamId, e);
        }
    }

    // ============================ Membership ============================

    @Override
    public TeamMember getActiveMembership(int teamId, int accountId) {
        String sql = "SELECT TeamMemberID, TeamID, AccountID, MemberRole, MemberStatus, JoinedAt, LeftAt, AddedBy " +
                "FROM dbo.TeamMembers WHERE TeamID = ? AND AccountID = ? AND MemberStatus = 'ACTIVE'";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, teamId);
            ps.setInt(2, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapMember(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi kiểm tra thành viên", e);
        }
        return null;
    }

    @Override
    public int countActiveMembers(int teamId) {
        String sql = "SELECT COUNT(*) FROM dbo.TeamMembers WHERE TeamID = ? AND MemberStatus = 'ACTIVE'";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, teamId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi đếm thành viên đội ID " + teamId, e);
        }
    }

    @Override
    public List<TeamMemberDTO> getMembers(int teamId) {
        String sql = "SELECT tm.TeamMemberID, tm.AccountID, a.FullName, a.AvatarUrl, tm.MemberRole, tm.MemberStatus, tm.JoinedAt " +
                "FROM dbo.TeamMembers tm JOIN Accounts a ON a.AccountID = tm.AccountID " +
                "WHERE tm.TeamID = ? AND tm.MemberStatus = 'ACTIVE' " +
                "ORDER BY CASE tm.MemberRole WHEN 'CAPTAIN' THEN 0 WHEN 'CO_CAPTAIN' THEN 1 ELSE 2 END, tm.JoinedAt ASC";
        List<TeamMemberDTO> result = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, teamId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    TeamMemberDTO dto = new TeamMemberDTO();
                    dto.setTeamMemberId(rs.getInt("TeamMemberID"));
                    dto.setAccountId(rs.getInt("AccountID"));
                    dto.setFullName(rs.getString("FullName"));
                    dto.setAvatarUrl(rs.getString("AvatarUrl"));
                    dto.setMemberRole(rs.getString("MemberRole"));
                    dto.setMemberStatus(rs.getString("MemberStatus"));
                    Timestamp joinedAt = rs.getTimestamp("JoinedAt");
                    dto.setJoinedAt(joinedAt != null ? joinedAt.toLocalDateTime().toString() : null);
                    result.add(dto);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi truy vấn danh sách thành viên đội ID " + teamId, e);
        }
        return result;
    }

    @Override
    public boolean updateMemberRole(int teamId, int accountId, String newRole) {
        String sql = "UPDATE dbo.TeamMembers SET MemberRole = ? WHERE TeamID = ? AND AccountID = ? AND MemberStatus = 'ACTIVE'";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, newRole);
            ps.setInt(2, teamId);
            ps.setInt(3, accountId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi đổi vai trò thành viên", e);
        }
    }

    @Override
    public boolean deactivateMember(int teamId, int accountId, String newStatus) {
        String sql = "UPDATE dbo.TeamMembers SET MemberStatus = ?, LeftAt = SYSUTCDATETIME() " +
                "WHERE TeamID = ? AND AccountID = ? AND MemberStatus = 'ACTIVE'";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, newStatus);
            ps.setInt(2, teamId);
            ps.setInt(3, accountId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi cập nhật trạng thái thành viên", e);
        }
    }

    @Override
    public boolean transferCaptain(int teamId, int fromAccountId, int toAccountId) throws Exception {
        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                // Khóa cả 2 hàng thành viên liên quan để tránh race condition khi chuyển quyền đồng thời.
                String sqlLock = "SELECT AccountID, MemberRole FROM dbo.TeamMembers WITH (UPDLOCK, ROWLOCK) " +
                        "WHERE TeamID = ? AND AccountID IN (?, ?) AND MemberStatus = 'ACTIVE'";
                int found = 0;
                try (PreparedStatement ps = conn.prepareStatement(sqlLock)) {
                    ps.setInt(1, teamId);
                    ps.setInt(2, fromAccountId);
                    ps.setInt(3, toAccountId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) found++;
                    }
                }
                if (found < 2) {
                    conn.rollback();
                    throw new IllegalStateException("Không tìm thấy đủ 2 thành viên active để chuyển quyền.");
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE dbo.TeamMembers SET MemberRole = ? WHERE TeamID = ? AND AccountID = ? AND MemberStatus = 'ACTIVE'")) {
                    ps.setString(1, TeamMember.ROLE_MEMBER);
                    ps.setInt(2, teamId);
                    ps.setInt(3, fromAccountId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE dbo.TeamMembers SET MemberRole = ? WHERE TeamID = ? AND AccountID = ? AND MemberStatus = 'ACTIVE'")) {
                    ps.setString(1, TeamMember.ROLE_CAPTAIN);
                    ps.setInt(2, teamId);
                    ps.setInt(3, toAccountId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE dbo.Teams SET CaptainAccountID = ?, UpdatedAt = SYSUTCDATETIME() WHERE TeamID = ?")) {
                    ps.setInt(1, toAccountId);
                    ps.setInt(2, teamId);
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
    public boolean disbandTeam(int teamId, int actorAccountId) throws Exception {
        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE dbo.Teams SET Status = ?, IsDeleted = 1, DeletedAt = SYSUTCDATETIME(), DeletedBy = ?, UpdatedAt = SYSUTCDATETIME() " +
                                "WHERE TeamID = ? AND (IsDeleted = 0 OR IsDeleted IS NULL)")) {
                    ps.setString(1, Team.STATUS_DISBANDED);
                    ps.setInt(2, actorAccountId);
                    ps.setInt(3, teamId);
                    int updated = ps.executeUpdate();
                    if (updated == 0) {
                        conn.rollback();
                        return false;
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE dbo.TeamMembers SET MemberStatus = 'REMOVED', LeftAt = SYSUTCDATETIME() WHERE TeamID = ? AND MemberStatus = 'ACTIVE'")) {
                    ps.setInt(1, teamId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE dbo.TeamInvitations SET Status = 'CANCELLED', RespondedAt = SYSUTCDATETIME() WHERE TeamID = ? AND Status = 'PENDING'")) {
                    ps.setInt(1, teamId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE dbo.TeamJoinRequests SET Status = 'CANCELLED', ReviewedAt = SYSUTCDATETIME(), ReviewedByAccountID = ? WHERE TeamID = ? AND Status = 'PENDING'")) {
                    ps.setInt(1, actorAccountId);
                    ps.setInt(2, teamId);
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

    // ============================ Invitations ============================

    @Override
    public int createInvitation(TeamInvitation invitation) {
        String sql = "INSERT INTO dbo.TeamInvitations (TeamID, InvitedAccountID, InvitedByAccountID, ProposedRole, Status, Message, ExpiresAt) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, invitation.getTeamId());
            ps.setInt(2, invitation.getInvitedAccountId());
            ps.setInt(3, invitation.getInvitedByAccountId());
            ps.setString(4, invitation.getProposedRole());
            ps.setString(5, TeamInvitation.STATUS_PENDING);
            ps.setString(6, invitation.getMessage());
            if (invitation.getExpiresAt() != null) {
                ps.setTimestamp(7, Timestamp.valueOf(invitation.getExpiresAt()));
            } else {
                ps.setNull(7, Types.TIMESTAMP);
            }
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                return rs.next() ? rs.getInt(1) : -1;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi tạo lời mời tham gia đội", e);
        }
    }

    @Override
    public boolean hasPendingInvitation(int teamId, int invitedAccountId) {
        String sql = "SELECT COUNT(*) FROM dbo.TeamInvitations WHERE TeamID = ? AND InvitedAccountID = ? AND Status = 'PENDING'";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, teamId);
            ps.setInt(2, invitedAccountId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi kiểm tra lời mời đang chờ", e);
        }
    }

    @Override
    public List<TeamInvitationDTO> getPendingInvitationsForAccount(int accountId) {
        String sql = "SELECT inv.InvitationID, inv.TeamID, t.TeamName, t.AvatarPath AS TeamAvatarPath, " +
                "inv.InvitedByAccountID, a.FullName AS InvitedByName, inv.ProposedRole, inv.Status, inv.Message, inv.CreatedAt, inv.ExpiresAt " +
                "FROM dbo.TeamInvitations inv " +
                "JOIN dbo.Teams t ON t.TeamID = inv.TeamID " +
                "JOIN Accounts a ON a.AccountID = inv.InvitedByAccountID " +
                "WHERE inv.InvitedAccountID = ? AND inv.Status = 'PENDING' AND (t.IsDeleted = 0 OR t.IsDeleted IS NULL) " +
                "ORDER BY inv.CreatedAt DESC";
        List<TeamInvitationDTO> result = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    TeamInvitationDTO dto = new TeamInvitationDTO();
                    dto.setInvitationId(rs.getInt("InvitationID"));
                    dto.setTeamId(rs.getInt("TeamID"));
                    dto.setTeamName(rs.getString("TeamName"));
                    dto.setTeamAvatarPath(rs.getString("TeamAvatarPath"));
                    dto.setInvitedByAccountId(rs.getInt("InvitedByAccountID"));
                    dto.setInvitedByName(rs.getString("InvitedByName"));
                    dto.setProposedRole(rs.getString("ProposedRole"));
                    dto.setStatus(rs.getString("Status"));
                    dto.setMessage(rs.getString("Message"));
                    Timestamp createdAt = rs.getTimestamp("CreatedAt");
                    dto.setCreatedAt(createdAt != null ? createdAt.toLocalDateTime().toString() : null);
                    Timestamp expiresAt = rs.getTimestamp("ExpiresAt");
                    dto.setExpiresAt(expiresAt != null ? expiresAt.toLocalDateTime().toString() : null);
                    result.add(dto);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi truy vấn lời mời đang chờ", e);
        }
        return result;
    }

    @Override
    public TeamInvitation getInvitationById(int invitationId) {
        String sql = "SELECT InvitationID, TeamID, InvitedAccountID, InvitedByAccountID, ProposedRole, Status, Message, CreatedAt, ExpiresAt, RespondedAt " +
                "FROM dbo.TeamInvitations WHERE InvitationID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, invitationId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapInvitation(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi truy vấn lời mời ID " + invitationId, e);
        }
        return null;
    }

    @Override
    public boolean acceptInvitation(int invitationId, int accountId) throws Exception {
        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int teamId;
                String sqlLockInv = "SELECT TeamID, InvitedAccountID, ProposedRole, Status FROM dbo.TeamInvitations WITH (UPDLOCK, ROWLOCK) WHERE InvitationID = ?";
                String proposedRole;
                try (PreparedStatement ps = conn.prepareStatement(sqlLockInv)) {
                    ps.setInt(1, invitationId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) { conn.rollback(); throw new IllegalStateException("Lời mời không tồn tại."); }
                        if (rs.getInt("InvitedAccountID") != accountId) { conn.rollback(); throw new IllegalStateException("Lời mời này không dành cho bạn."); }
                        if (!TeamInvitation.STATUS_PENDING.equals(rs.getString("Status"))) { conn.rollback(); throw new IllegalStateException("Lời mời đã được xử lý trước đó."); }
                        teamId = rs.getInt("TeamID");
                        proposedRole = rs.getString("ProposedRole");
                    }
                }

                // Khóa hàng Teams để kiểm tra MaxMembers dưới điều kiện đua (race-safe).
                int maxMembers;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT MaxMembers, Status FROM dbo.Teams WITH (UPDLOCK, ROWLOCK) WHERE TeamID = ?")) {
                    ps.setInt(1, teamId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) { conn.rollback(); throw new IllegalStateException("Đội không còn tồn tại."); }
                        if (!Team.STATUS_ACTIVE.equals(rs.getString("Status"))) { conn.rollback(); throw new IllegalStateException("Đội hiện không hoạt động."); }
                        maxMembers = rs.getInt("MaxMembers");
                    }
                }

                int currentCount;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM dbo.TeamMembers WHERE TeamID = ? AND MemberStatus = 'ACTIVE'")) {
                    ps.setInt(1, teamId);
                    try (ResultSet rs = ps.executeQuery()) {
                        currentCount = rs.next() ? rs.getInt(1) : 0;
                    }
                }
                if (currentCount >= maxMembers) { conn.rollback(); throw new IllegalStateException("Đội đã đủ thành viên."); }

                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM dbo.TeamMembers WHERE TeamID = ? AND AccountID = ? AND MemberStatus = 'ACTIVE'")) {
                    ps.setInt(1, teamId);
                    ps.setInt(2, accountId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && rs.getInt(1) > 0) { conn.rollback(); throw new IllegalStateException("Bạn đã là thành viên của đội này."); }
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO dbo.TeamMembers (TeamID, AccountID, MemberRole, MemberStatus, AddedBy) VALUES (?, ?, ?, 'ACTIVE', ?)")) {
                    ps.setInt(1, teamId);
                    ps.setInt(2, accountId);
                    ps.setString(3, proposedRole != null ? proposedRole : TeamMember.ROLE_MEMBER);
                    ps.setInt(4, accountId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE dbo.TeamInvitations SET Status = 'ACCEPTED', RespondedAt = SYSUTCDATETIME() WHERE InvitationID = ?")) {
                    ps.setInt(1, invitationId);
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
    public boolean rejectInvitation(int invitationId, int accountId) {
        String sql = "UPDATE dbo.TeamInvitations SET Status = 'REJECTED', RespondedAt = SYSUTCDATETIME() " +
                "WHERE InvitationID = ? AND InvitedAccountID = ? AND Status = 'PENDING'";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, invitationId);
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi từ chối lời mời", e);
        }
    }

    @Override
    public boolean cancelInvitation(int invitationId, int teamId) {
        String sql = "UPDATE dbo.TeamInvitations SET Status = 'CANCELLED', RespondedAt = SYSUTCDATETIME() " +
                "WHERE InvitationID = ? AND TeamID = ? AND Status = 'PENDING'";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, invitationId);
            ps.setInt(2, teamId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi hủy lời mời", e);
        }
    }

    // ============================ Join requests ============================

    @Override
    public int createJoinRequest(TeamJoinRequest joinRequest) {
        String sql = "INSERT INTO dbo.TeamJoinRequests (TeamID, RequesterAccountID, Message, Status) VALUES (?, ?, ?, ?)";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, joinRequest.getTeamId());
            ps.setInt(2, joinRequest.getRequesterAccountId());
            ps.setString(3, joinRequest.getMessage());
            ps.setString(4, TeamJoinRequest.STATUS_PENDING);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                return rs.next() ? rs.getInt(1) : -1;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi tạo yêu cầu tham gia đội", e);
        }
    }

    @Override
    public boolean hasPendingJoinRequest(int teamId, int accountId) {
        String sql = "SELECT COUNT(*) FROM dbo.TeamJoinRequests WHERE TeamID = ? AND RequesterAccountID = ? AND Status = 'PENDING'";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, teamId);
            ps.setInt(2, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi kiểm tra yêu cầu tham gia đang chờ", e);
        }
    }

    @Override
    public List<TeamJoinRequestDTO> getPendingJoinRequests(int teamId) {
        String sql = "SELECT jr.JoinRequestID, jr.TeamID, jr.RequesterAccountID, a.FullName AS RequesterName, a.AvatarUrl AS RequesterAvatarUrl, " +
                "jr.Message, jr.Status, jr.CreatedAt " +
                "FROM dbo.TeamJoinRequests jr JOIN Accounts a ON a.AccountID = jr.RequesterAccountID " +
                "WHERE jr.TeamID = ? AND jr.Status = 'PENDING' ORDER BY jr.CreatedAt ASC";
        List<TeamJoinRequestDTO> result = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, teamId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    TeamJoinRequestDTO dto = new TeamJoinRequestDTO();
                    dto.setJoinRequestId(rs.getInt("JoinRequestID"));
                    dto.setTeamId(rs.getInt("TeamID"));
                    dto.setRequesterAccountId(rs.getInt("RequesterAccountID"));
                    dto.setRequesterName(rs.getString("RequesterName"));
                    dto.setRequesterAvatarUrl(rs.getString("RequesterAvatarUrl"));
                    dto.setMessage(rs.getString("Message"));
                    dto.setStatus(rs.getString("Status"));
                    Timestamp createdAt = rs.getTimestamp("CreatedAt");
                    dto.setCreatedAt(createdAt != null ? createdAt.toLocalDateTime().toString() : null);
                    result.add(dto);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi truy vấn yêu cầu tham gia đội ID " + teamId, e);
        }
        return result;
    }

    @Override
    public TeamJoinRequest getJoinRequestById(int joinRequestId) {
        String sql = "SELECT JoinRequestID, TeamID, RequesterAccountID, Message, Status, CreatedAt, ReviewedAt, ReviewedByAccountID " +
                "FROM dbo.TeamJoinRequests WHERE JoinRequestID = ?";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, joinRequestId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapJoinRequest(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi truy vấn yêu cầu tham gia ID " + joinRequestId, e);
        }
        return null;
    }

    @Override
    public boolean approveJoinRequest(int joinRequestId, int reviewerAccountId) throws Exception {
        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int teamId;
                int requesterAccountId;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT TeamID, RequesterAccountID, Status FROM dbo.TeamJoinRequests WITH (UPDLOCK, ROWLOCK) WHERE JoinRequestID = ?")) {
                    ps.setInt(1, joinRequestId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) { conn.rollback(); throw new IllegalStateException("Yêu cầu tham gia không tồn tại."); }
                        if (!TeamJoinRequest.STATUS_PENDING.equals(rs.getString("Status"))) { conn.rollback(); throw new IllegalStateException("Yêu cầu đã được xử lý trước đó."); }
                        teamId = rs.getInt("TeamID");
                        requesterAccountId = rs.getInt("RequesterAccountID");
                    }
                }

                int maxMembers;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT MaxMembers, Status FROM dbo.Teams WITH (UPDLOCK, ROWLOCK) WHERE TeamID = ?")) {
                    ps.setInt(1, teamId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) { conn.rollback(); throw new IllegalStateException("Đội không còn tồn tại."); }
                        if (!Team.STATUS_ACTIVE.equals(rs.getString("Status"))) { conn.rollback(); throw new IllegalStateException("Đội hiện không hoạt động."); }
                        maxMembers = rs.getInt("MaxMembers");
                    }
                }
                int currentCount;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM dbo.TeamMembers WHERE TeamID = ? AND MemberStatus = 'ACTIVE'")) {
                    ps.setInt(1, teamId);
                    try (ResultSet rs = ps.executeQuery()) {
                        currentCount = rs.next() ? rs.getInt(1) : 0;
                    }
                }
                if (currentCount >= maxMembers) { conn.rollback(); throw new IllegalStateException("Đội đã đủ thành viên, không thể duyệt thêm."); }

                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM dbo.TeamMembers WHERE TeamID = ? AND AccountID = ? AND MemberStatus = 'ACTIVE'")) {
                    ps.setInt(1, teamId);
                    ps.setInt(2, requesterAccountId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && rs.getInt(1) > 0) { conn.rollback(); throw new IllegalStateException("Người này đã là thành viên của đội."); }
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO dbo.TeamMembers (TeamID, AccountID, MemberRole, MemberStatus, AddedBy) VALUES (?, ?, 'MEMBER', 'ACTIVE', ?)")) {
                    ps.setInt(1, teamId);
                    ps.setInt(2, requesterAccountId);
                    ps.setInt(3, reviewerAccountId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE dbo.TeamJoinRequests SET Status = 'APPROVED', ReviewedAt = SYSUTCDATETIME(), ReviewedByAccountID = ? WHERE JoinRequestID = ?")) {
                    ps.setInt(1, reviewerAccountId);
                    ps.setInt(2, joinRequestId);
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
    public boolean rejectJoinRequest(int joinRequestId, int reviewerAccountId) {
        String sql = "UPDATE dbo.TeamJoinRequests SET Status = 'REJECTED', ReviewedAt = SYSUTCDATETIME(), ReviewedByAccountID = ? " +
                "WHERE JoinRequestID = ? AND Status = 'PENDING'";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, reviewerAccountId);
            ps.setInt(2, joinRequestId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi từ chối yêu cầu tham gia", e);
        }
    }

    @Override
    public boolean cancelJoinRequest(int joinRequestId, int requesterAccountId) {
        String sql = "UPDATE dbo.TeamJoinRequests SET Status = 'CANCELLED', ReviewedAt = SYSUTCDATETIME() " +
                "WHERE JoinRequestID = ? AND RequesterAccountID = ? AND Status = 'PENDING'";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, joinRequestId);
            ps.setInt(2, requesterAccountId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("Lỗi hủy yêu cầu tham gia", e);
        }
    }

    // ============================ Mappers ============================

    private Team mapTeam(ResultSet rs) throws SQLException {
        Team t = new Team();
        t.setTeamId(rs.getInt("TeamID"));
        t.setTeamName(rs.getString("TeamName"));
        t.setDescription(rs.getString("Description"));
        t.setSportId(rs.getInt("SportID"));
        t.setCaptainAccountId(rs.getInt("CaptainAccountID"));
        t.setLocationText(rs.getString("LocationText"));
        t.setAvatarPath(rs.getString("AvatarPath"));
        t.setCoverImagePath(rs.getString("CoverImagePath"));
        t.setMaxMembers(rs.getInt("MaxMembers"));
        t.setStatus(rs.getString("Status"));
        t.setCreatedAt(toLocalDateTime(rs.getTimestamp("CreatedAt")));
        t.setUpdatedAt(toLocalDateTime(rs.getTimestamp("UpdatedAt")));
        t.setDeleted(rs.getBoolean("IsDeleted"));
        t.setDeletedAt(toLocalDateTime(rs.getTimestamp("DeletedAt")));
        int deletedBy = rs.getInt("DeletedBy");
        t.setDeletedBy(rs.wasNull() ? null : deletedBy);
        return t;
    }

    private TeamSummaryDTO mapSummary(ResultSet rs) throws SQLException {
        TeamSummaryDTO dto = new TeamSummaryDTO();
        dto.setTeamId(rs.getInt("TeamID"));
        dto.setTeamName(rs.getString("TeamName"));
        dto.setDescription(rs.getString("Description"));
        dto.setSportId(rs.getInt("SportID"));
        dto.setSportName(rs.getString("SportName"));
        dto.setLocationText(rs.getString("LocationText"));
        dto.setAvatarPath(rs.getString("AvatarPath"));
        dto.setMemberCount(rs.getInt("MemberCount"));
        dto.setMaxMembers(rs.getInt("MaxMembers"));
        dto.setStatus(rs.getString("Status"));
        return dto;
    }

    private TeamMember mapMember(ResultSet rs) throws SQLException {
        TeamMember m = new TeamMember();
        m.setTeamMemberId(rs.getInt("TeamMemberID"));
        m.setTeamId(rs.getInt("TeamID"));
        m.setAccountId(rs.getInt("AccountID"));
        m.setMemberRole(rs.getString("MemberRole"));
        m.setMemberStatus(rs.getString("MemberStatus"));
        m.setJoinedAt(toLocalDateTime(rs.getTimestamp("JoinedAt")));
        m.setLeftAt(toLocalDateTime(rs.getTimestamp("LeftAt")));
        int addedBy = rs.getInt("AddedBy");
        m.setAddedBy(rs.wasNull() ? null : addedBy);
        return m;
    }

    private TeamInvitation mapInvitation(ResultSet rs) throws SQLException {
        TeamInvitation inv = new TeamInvitation();
        inv.setInvitationId(rs.getInt("InvitationID"));
        inv.setTeamId(rs.getInt("TeamID"));
        inv.setInvitedAccountId(rs.getInt("InvitedAccountID"));
        inv.setInvitedByAccountId(rs.getInt("InvitedByAccountID"));
        inv.setProposedRole(rs.getString("ProposedRole"));
        inv.setStatus(rs.getString("Status"));
        inv.setMessage(rs.getString("Message"));
        inv.setCreatedAt(toLocalDateTime(rs.getTimestamp("CreatedAt")));
        inv.setExpiresAt(toLocalDateTime(rs.getTimestamp("ExpiresAt")));
        inv.setRespondedAt(toLocalDateTime(rs.getTimestamp("RespondedAt")));
        return inv;
    }

    private TeamJoinRequest mapJoinRequest(ResultSet rs) throws SQLException {
        TeamJoinRequest jr = new TeamJoinRequest();
        jr.setJoinRequestId(rs.getInt("JoinRequestID"));
        jr.setTeamId(rs.getInt("TeamID"));
        jr.setRequesterAccountId(rs.getInt("RequesterAccountID"));
        jr.setMessage(rs.getString("Message"));
        jr.setStatus(rs.getString("Status"));
        jr.setCreatedAt(toLocalDateTime(rs.getTimestamp("CreatedAt")));
        jr.setReviewedAt(toLocalDateTime(rs.getTimestamp("ReviewedAt")));
        int reviewedBy = rs.getInt("ReviewedByAccountID");
        jr.setReviewedByAccountId(rs.wasNull() ? null : reviewedBy);
        return jr;
    }

    private LocalDateTime toLocalDateTime(Timestamp ts) {
        return ts != null ? ts.toLocalDateTime() : null;
    }
}
