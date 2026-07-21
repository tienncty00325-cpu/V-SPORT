package org.example.dao;

import org.example.dto.TeamDetailDTO;
import org.example.dto.TeamInvitationDTO;
import org.example.dto.TeamJoinRequestDTO;
import org.example.dto.TeamMemberDTO;
import org.example.dto.TeamSummaryDTO;
import org.example.model.Team;
import org.example.model.TeamInvitation;
import org.example.model.TeamJoinRequest;
import org.example.model.TeamMember;

import java.util.List;

/**
 * DAO cho module Đội nhóm (Team management). Toàn bộ tham số bind qua
 * PreparedStatement — không nối chuỗi SQL bằng input user. Các thao tác
 * nhiều bước (tạo đội + thêm captain, chấp nhận lời mời, duyệt yêu cầu
 * tham gia, chuyển quyền, giải tán đội) chạy trong một transaction duy
 * nhất — xem TeamDAOImpl để biết chi tiết khóa hàng (UPDLOCK/ROWLOCK).
 */
public interface TeamDAO {

    /** Tạo Teams + TeamMembers(CAPTAIN) trong 1 transaction. Trả về TeamID mới. */
    int createTeamWithCaptain(Team team) throws Exception;

    Team getTeamById(int teamId);

    /** true nếu captainAccountId đã có đội ACTIVE khác trùng tên (không phân biệt hoa/thường). */
    boolean isTeamNameTakenForCaptain(int captainAccountId, String teamName, Integer excludeTeamId);

    boolean updateTeam(Team team);

    boolean updateAvatarPath(int teamId, String avatarPath);

    boolean updateCoverImagePath(int teamId, String coverImagePath);

    /** Đội do accountId làm đội trưởng hoặc đang là thành viên ACTIVE. */
    List<TeamSummaryDTO> getMyTeams(int accountId);

    /**
     * Đội có thể tham gia: ACTIVE, chưa xóa, accountId chưa là thành viên,
     * loại trừ theo từ khóa/sportId/vị trí/còn chỗ trống tùy tham số truyền vào.
     */
    List<TeamSummaryDTO> discoverTeams(int accountId, String keyword, Integer sportId, boolean onlyOpenSlots);

    TeamDetailDTO getTeamDetail(int teamId, int viewerAccountId);

    TeamMember getActiveMembership(int teamId, int accountId);

    int countActiveMembers(int teamId);

    List<TeamMemberDTO> getMembers(int teamId);

    boolean updateMemberRole(int teamId, int accountId, String newRole);

    /** Đặt MemberStatus = LEFT/REMOVED + LeftAt, dùng cho rời đội / bị kick (không phải giải tán). */
    boolean deactivateMember(int teamId, int accountId, String newStatus);

    /** Chuyển quyền đội trưởng: đổi role 2 thành viên + Teams.CaptainAccountID trong 1 transaction. */
    boolean transferCaptain(int teamId, int fromAccountId, int toAccountId) throws Exception;

    /** Giải tán đội: Status=DISBANDED, soft-delete, đóng toàn bộ invitation/join-request pending, trong 1 transaction. */
    boolean disbandTeam(int teamId, int actorAccountId) throws Exception;

    // ============================ Invitations ============================

    int createInvitation(TeamInvitation invitation);

    boolean hasPendingInvitation(int teamId, int invitedAccountId);

    List<TeamInvitationDTO> getPendingInvitationsForAccount(int accountId);

    TeamInvitation getInvitationById(int invitationId);

    /** Thêm thành viên + đổi invitation sang ACCEPTED, có kiểm tra MaxMembers dưới khóa hàng, trong 1 transaction. */
    boolean acceptInvitation(int invitationId, int accountId) throws Exception;

    boolean rejectInvitation(int invitationId, int accountId);

    boolean cancelInvitation(int invitationId, int teamId);

    // ============================ Join requests ===========================

    int createJoinRequest(TeamJoinRequest joinRequest);

    boolean hasPendingJoinRequest(int teamId, int accountId);

    List<TeamJoinRequestDTO> getPendingJoinRequests(int teamId);

    TeamJoinRequest getJoinRequestById(int joinRequestId);

    /** Thêm thành viên + đổi request sang APPROVED, có kiểm tra MaxMembers dưới khóa hàng, trong 1 transaction. */
    boolean approveJoinRequest(int joinRequestId, int reviewerAccountId) throws Exception;

    boolean rejectJoinRequest(int joinRequestId, int reviewerAccountId);

    boolean cancelJoinRequest(int joinRequestId, int requesterAccountId);
}
