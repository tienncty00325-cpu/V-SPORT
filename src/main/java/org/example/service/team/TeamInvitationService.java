package org.example.service.team;

import org.example.dao.TeamDAO;
import org.example.dto.TeamInvitationDTO;
import org.example.model.Team;
import org.example.model.TeamInvitation;
import org.example.model.TeamMember;

import java.util.List;
import java.util.regex.Pattern;

/**
 * Business rules cho lời mời vào đội (captain/co-captain mời một account cụ
 * thể). Tách riêng khỏi TeamService theo đúng yêu cầu — dùng chung TeamDAO,
 * không tự viết SQL ở đây.
 */
public class TeamInvitationService {

    private static final Pattern HTML_TAG_CHARS = Pattern.compile("[<>]");

    private final TeamDAO teamDAO;

    public TeamInvitationService(TeamDAO teamDAO) {
        this.teamDAO = teamDAO;
    }

    public static class Result {
        public final boolean success;
        public final String message;
        public final Integer id;

        private Result(boolean success, String message, Integer id) {
            this.success = success;
            this.message = message;
            this.id = id;
        }

        public static Result ok(String message, Integer id) { return new Result(true, message, id); }
        public static Result fail(String message) { return new Result(false, message, null); }
    }

    public Result inviteMember(int teamId, int actorAccountId, int invitedAccountId, String proposedRole, String message) {
        Team team = teamDAO.getTeamById(teamId);
        if (team == null || team.isDeleted() || !Team.STATUS_ACTIVE.equals(team.getStatus())) {
            return Result.fail("Đội không tồn tại hoặc không còn hoạt động.");
        }
        if (!isCaptainOrCoCaptain(teamId, actorAccountId)) {
            return Result.fail("Bạn không có quyền mời thành viên vào đội này.");
        }
        if (actorAccountId == invitedAccountId) return Result.fail("Không thể tự mời chính mình.");
        if (teamDAO.getActiveMembership(teamId, invitedAccountId) != null) {
            return Result.fail("Người này đã là thành viên của đội.");
        }
        if (teamDAO.countActiveMembers(teamId) >= team.getMaxMembers()) {
            return Result.fail("Đội đã đủ thành viên, không thể mời thêm.");
        }
        if (teamDAO.hasPendingInvitation(teamId, invitedAccountId)) {
            return Result.fail("Đã có lời mời đang chờ phản hồi cho người này.");
        }

        String role = TeamMember.ROLE_CO_CAPTAIN.equals(proposedRole) ? TeamMember.ROLE_CO_CAPTAIN : TeamMember.ROLE_MEMBER;
        String msg = message == null ? null : message.trim();
        if (msg != null) {
            if (msg.length() > 225) return Result.fail("Lời nhắn tối đa 225 ký tự.");
            if (HTML_TAG_CHARS.matcher(msg).find()) return Result.fail("Lời nhắn không được chứa ký tự '<' hoặc '>'.");
            if (msg.isEmpty()) msg = null;
        }

        TeamInvitation inv = new TeamInvitation();
        inv.setTeamId(teamId);
        inv.setInvitedAccountId(invitedAccountId);
        inv.setInvitedByAccountId(actorAccountId);
        inv.setProposedRole(role);
        inv.setMessage(msg);

        int id = teamDAO.createInvitation(inv);
        return id > 0 ? Result.ok("Đã gửi lời mời.", id) : Result.fail("Không thể gửi lời mời. Vui lòng thử lại.");
    }

    public List<TeamInvitationDTO> getMyPendingInvitations(int accountId) {
        return teamDAO.getPendingInvitationsForAccount(accountId);
    }

    public Result acceptInvitation(int invitationId, int accountId) {
        TeamInvitation inv = teamDAO.getInvitationById(invitationId);
        if (inv == null) return Result.fail("Lời mời không tồn tại.");
        if (inv.getInvitedAccountId() != accountId) return Result.fail("Lời mời này không dành cho bạn.");
        try {
            boolean ok = teamDAO.acceptInvitation(invitationId, accountId);
            return ok ? Result.ok("Đã chấp nhận lời mời.", inv.getTeamId()) : Result.fail("Không thể chấp nhận lời mời.");
        } catch (IllegalStateException ise) {
            return Result.fail(ise.getMessage());
        } catch (Exception e) {
            return Result.fail("Không thể chấp nhận lời mời lúc này. Vui lòng thử lại.");
        }
    }

    public Result rejectInvitation(int invitationId, int accountId) {
        boolean ok = teamDAO.rejectInvitation(invitationId, accountId);
        return ok ? Result.ok("Đã từ chối lời mời.", null) : Result.fail("Không thể từ chối lời mời (có thể đã được xử lý).");
    }

    public Result cancelInvitation(int invitationId, int actorAccountId) {
        TeamInvitation inv = teamDAO.getInvitationById(invitationId);
        if (inv == null) return Result.fail("Lời mời không tồn tại.");
        if (!isCaptainOrCoCaptain(inv.getTeamId(), actorAccountId)) return Result.fail("Bạn không có quyền hủy lời mời này.");
        boolean ok = teamDAO.cancelInvitation(invitationId, inv.getTeamId());
        return ok ? Result.ok("Đã hủy lời mời.", null) : Result.fail("Không thể hủy lời mời.");
    }

    private boolean isCaptainOrCoCaptain(int teamId, int accountId) {
        TeamMember m = teamDAO.getActiveMembership(teamId, accountId);
        return m != null && (TeamMember.ROLE_CAPTAIN.equals(m.getMemberRole()) || TeamMember.ROLE_CO_CAPTAIN.equals(m.getMemberRole()));
    }
}
