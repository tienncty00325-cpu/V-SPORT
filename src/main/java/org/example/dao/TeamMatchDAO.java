package org.example.dao;

import org.example.dto.TeamChallengeDTO;
import org.example.dto.TeamMatchSummaryDTO;

import java.util.List;

/**
 * Tích hợp Team với domain Ghép kèo (GhepKeo/ChiTietGhepKeo) hiện có, thông
 * qua 2 cột nullable TeamIDNguoiTao/TeamIDNguoiThamGia (xem
 * migration_team_management.sql). KHÔNG đụng tới GhepKeoDAO/GhepKeoDAOImpl/
 * GhepKeoService — mọi thao tác kèo cá nhân (TeamID* = NULL) giữ nguyên hành
 * vi cũ 100%. Đây là một domain object khác: "kèo đội" là thách đấu 1-đội-
 * đối-1-đội (đội tạo chấp nhận đúng một đội thách đấu), không phải ghép nhiều
 * cá nhân theo sức chứa như GhepKeo cá nhân.
 */
public interface TeamMatchDAO {

    /** Tạo 1 kèo GhepKeo gắn TeamIDNguoiTao = teamId. Trả về KeoID mới. */
    int createTeamMatch(int teamId, int captainAccountId, int datSanId, Integer monTheThaoId, String trinhDo, String note) throws Exception;

    /** Danh sách kèo đội đang mở (TrangThai = 'Đang mở'), loại trừ kèo do chính excludeTeamId tạo nếu truyền vào. */
    List<TeamMatchSummaryDTO> listOpenTeamMatches(Integer sportId, Integer excludeTeamId);

    /** Danh sách kèo đội do teamId tạo (mọi trạng thái). */
    List<TeamMatchSummaryDTO> listMyTeamMatches(int teamId);

    TeamMatchSummaryDTO getTeamMatchDetail(int keoId);

    /** Đội challengerTeamId thách đấu kèo keoId. Trả về ChiTietKeoID mới. */
    int challengeTeamMatch(int keoId, int challengerTeamId, int captainAccountId) throws Exception;

    List<TeamChallengeDTO> getPendingChallenges(int keoId);

    /**
     * Chấp nhận đúng 1 lượt thách đấu: set challenge đó JOINED, tất cả challenge
     * PENDING khác của cùng keoId chuyển REJECTED, GhepKeo.TrangThai = FULL.
     * Trong 1 transaction. Quyền hạn (là captain/co-captain của ownerTeamId) đã
     * được kiểm ở Service — DAO chỉ xác nhận chiTietKeoId thực sự thuộc 1 kèo
     * do ownerTeamId tạo (chống IDOR đổi id).
     */
    boolean acceptChallenge(int chiTietKeoId, int ownerTeamId) throws Exception;

    boolean rejectChallenge(int chiTietKeoId, int ownerTeamId);

    boolean cancelTeamMatch(int keoId, int ownerTeamId);
}
