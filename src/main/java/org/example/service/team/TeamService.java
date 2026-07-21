package org.example.service.team;

import org.example.dao.TeamDAO;
import org.example.dto.TeamDetailDTO;
import org.example.dto.TeamJoinRequestDTO;
import org.example.dto.TeamSummaryDTO;
import org.example.model.Team;
import org.example.model.TeamJoinRequest;
import org.example.model.TeamMember;

import java.util.Collections;
import java.util.List;
import java.util.regex.Pattern;

/**
 * Business rules cho vòng đời Team: tạo, cập nhật, khám phá, thành viên,
 * yêu cầu tham gia, chuyển quyền, giải tán. Không đặt SQL ở đây — mọi
 * truy vấn/transaction nằm trong TeamDAOImpl. Lời mời (invite/accept/reject)
 * nằm ở TeamInvitationService riêng.
 */
public class TeamService {

    private static final int NAME_MIN = 3;
    private static final int NAME_MAX = 50;
    private static final int DESC_MAX = 225;
    private static final int MEMBERS_MIN = 2;
    private static final int MEMBERS_MAX = 30;
    // Chặn thô các ký tự mở đầu thẻ HTML/script ngay ở tầng service — c:out ở
    // JSP đã escape khi hiển thị, đây là lớp phòng thủ bổ sung theo yêu cầu.
    private static final Pattern HTML_TAG_CHARS = Pattern.compile("[<>]");

    private final TeamDAO teamDAO;

    public TeamService(TeamDAO teamDAO) {
        this.teamDAO = teamDAO;
    }

    public static class CreateRequest {
        public int accountId;
        public String teamName;
        public String description;
        public int sportId;
        public String locationText;
        public int maxMembers;
        public String avatarPath;
        public String coverImagePath;
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

    public Result createTeam(CreateRequest req) {
        if (req == null || req.accountId <= 0) return Result.fail("Vui lòng đăng nhập.");

        String name = req.teamName == null ? "" : req.teamName.trim();
        if (name.isEmpty() || name.length() < NAME_MIN) {
            return Result.fail("Tên đội phải có ít nhất " + NAME_MIN + " ký tự.");
        }
        if (name.length() > NAME_MAX) {
            return Result.fail("Tên đội tối đa " + NAME_MAX + " ký tự.");
        }
        if (HTML_TAG_CHARS.matcher(name).find()) {
            return Result.fail("Tên đội không được chứa ký tự '<' hoặc '>'.");
        }

        String description = req.description == null ? null : req.description.trim();
        if (description != null) {
            if (description.length() > DESC_MAX) return Result.fail("Mô tả đội tối đa " + DESC_MAX + " ký tự.");
            if (HTML_TAG_CHARS.matcher(description).find()) return Result.fail("Mô tả đội không được chứa ký tự '<' hoặc '>'.");
            if (description.isEmpty()) description = null;
        }

        if (req.sportId <= 0) return Result.fail("Vui lòng chọn loại thể thao.");
        if (req.maxMembers < MEMBERS_MIN || req.maxMembers > MEMBERS_MAX) {
            return Result.fail("Số thành viên tối đa phải trong khoảng " + MEMBERS_MIN + " đến " + MEMBERS_MAX + ".");
        }

        String location = req.locationText == null ? null : req.locationText.trim();
        if (location != null) {
            if (location.length() > 255) return Result.fail("Khu vực quá dài.");
            if (HTML_TAG_CHARS.matcher(location).find()) return Result.fail("Khu vực không được chứa ký tự '<' hoặc '>'.");
            if (location.isEmpty()) location = null;
        }

        if (teamDAO.isTeamNameTakenForCaptain(req.accountId, name, null)) {
            return Result.fail("Bạn đã có một đội đang hoạt động trùng tên này.");
        }

        Team team = new Team();
        team.setTeamName(name);
        team.setDescription(description);
        team.setSportId(req.sportId);
        team.setCaptainAccountId(req.accountId);
        team.setLocationText(location);
        team.setMaxMembers(req.maxMembers);
        team.setAvatarPath(req.avatarPath);
        team.setCoverImagePath(req.coverImagePath);

        try {
            int teamId = teamDAO.createTeamWithCaptain(team);
            if (teamId <= 0) return Result.fail("Không thể tạo đội. Vui lòng thử lại.");
            return Result.ok("Tạo đội thành công.", teamId);
        } catch (Exception e) {
            return Result.fail("Không thể tạo đội lúc này. Vui lòng thử lại.");
        }
    }

    public Result updateTeam(int teamId, int actorAccountId, String teamName, String description, Integer sportId, String locationText, Integer maxMembers) {
        Team existing = teamDAO.getTeamById(teamId);
        if (existing == null || existing.isDeleted()) return Result.fail("Đội không tồn tại.");
        if (existing.getCaptainAccountId() != actorAccountId) return Result.fail("Chỉ đội trưởng mới có thể chỉnh sửa đội.");

        String name = teamName == null ? "" : teamName.trim();
        if (name.length() < NAME_MIN || name.length() > NAME_MAX || HTML_TAG_CHARS.matcher(name).find()) {
            return Result.fail("Tên đội không hợp lệ.");
        }
        String desc = description == null ? null : description.trim();
        if (desc != null && (desc.length() > DESC_MAX || HTML_TAG_CHARS.matcher(desc).find())) {
            return Result.fail("Mô tả đội không hợp lệ.");
        }
        int finalSportId = sportId != null ? sportId : existing.getSportId();
        if (finalSportId <= 0) return Result.fail("Vui lòng chọn loại thể thao.");

        int finalMax = maxMembers != null ? maxMembers : existing.getMaxMembers();
        if (finalMax < MEMBERS_MIN || finalMax > MEMBERS_MAX) {
            return Result.fail("Số thành viên tối đa phải trong khoảng " + MEMBERS_MIN + " đến " + MEMBERS_MAX + ".");
        }
        int currentMembers = teamDAO.countActiveMembers(teamId);
        if (finalMax < currentMembers) {
            return Result.fail("Số thành viên tối đa không được nhỏ hơn số thành viên hiện tại (" + currentMembers + ").");
        }

        String loc = locationText == null ? null : locationText.trim();
        if (loc != null && (loc.length() > 255 || HTML_TAG_CHARS.matcher(loc).find())) return Result.fail("Khu vực không hợp lệ.");

        if (!name.equalsIgnoreCase(existing.getTeamName()) && teamDAO.isTeamNameTakenForCaptain(actorAccountId, name, teamId)) {
            return Result.fail("Bạn đã có một đội đang hoạt động trùng tên này.");
        }

        Team toSave = new Team();
        toSave.setTeamId(teamId);
        toSave.setTeamName(name);
        toSave.setDescription(desc != null && !desc.isEmpty() ? desc : null);
        toSave.setSportId(finalSportId);
        toSave.setLocationText(loc != null && !loc.isEmpty() ? loc : null);
        toSave.setMaxMembers(finalMax);

        boolean updated = teamDAO.updateTeam(toSave);
        return updated ? Result.ok("Cập nhật đội thành công.", teamId) : Result.fail("Không thể cập nhật đội.");
    }

    public List<TeamSummaryDTO> getMyTeams(int accountId) {
        return teamDAO.getMyTeams(accountId);
    }

    public List<TeamSummaryDTO> discoverTeams(int accountId, String keyword, Integer sportId, boolean onlyOpenSlots) {
        return teamDAO.discoverTeams(accountId, keyword, sportId, onlyOpenSlots);
    }

    public TeamDetailDTO getTeamDetail(int teamId, int viewerAccountId) {
        return teamDAO.getTeamDetail(teamId, viewerAccountId);
    }

    // ============================ Join requests ============================

    public Result sendJoinRequest(int teamId, int accountId, String message) {
        Team team = teamDAO.getTeamById(teamId);
        if (team == null || team.isDeleted() || !Team.STATUS_ACTIVE.equals(team.getStatus())) {
            return Result.fail("Đội không tồn tại hoặc không còn hoạt động.");
        }
        if (teamDAO.getActiveMembership(teamId, accountId) != null) {
            return Result.fail("Bạn đã là thành viên của đội này.");
        }
        if (teamDAO.countActiveMembers(teamId) >= team.getMaxMembers()) {
            return Result.fail("Đội đã đủ thành viên.");
        }
        if (teamDAO.hasPendingJoinRequest(teamId, accountId)) {
            return Result.fail("Bạn đã gửi yêu cầu tham gia đội này và đang chờ duyệt.");
        }
        String msg = message == null ? null : message.trim();
        if (msg != null) {
            if (msg.length() > 225) return Result.fail("Lời nhắn tối đa 225 ký tự.");
            if (HTML_TAG_CHARS.matcher(msg).find()) return Result.fail("Lời nhắn không được chứa ký tự '<' hoặc '>'.");
            if (msg.isEmpty()) msg = null;
        }
        TeamJoinRequest jr = new TeamJoinRequest();
        jr.setTeamId(teamId);
        jr.setRequesterAccountId(accountId);
        jr.setMessage(msg);
        int id = teamDAO.createJoinRequest(jr);
        return id > 0 ? Result.ok("Đã gửi yêu cầu tham gia.", id) : Result.fail("Không thể gửi yêu cầu. Vui lòng thử lại.");
    }

    public Result cancelJoinRequest(int joinRequestId, int accountId) {
        boolean ok = teamDAO.cancelJoinRequest(joinRequestId, accountId);
        return ok ? Result.ok("Đã hủy yêu cầu.", null) : Result.fail("Không thể hủy yêu cầu (có thể đã được xử lý).");
    }

    public List<TeamJoinRequestDTO> getPendingJoinRequests(int teamId, int actorAccountId) {
        if (!isCaptainOrCoCaptain(teamId, actorAccountId)) return Collections.emptyList();
        return teamDAO.getPendingJoinRequests(teamId);
    }

    public Result approveJoinRequest(int joinRequestId, int reviewerAccountId) {
        TeamJoinRequest jr = teamDAO.getJoinRequestById(joinRequestId);
        if (jr == null) return Result.fail("Yêu cầu tham gia không tồn tại.");
        if (!isCaptainOrCoCaptain(jr.getTeamId(), reviewerAccountId)) return Result.fail("Bạn không có quyền duyệt yêu cầu này.");
        try {
            boolean ok = teamDAO.approveJoinRequest(joinRequestId, reviewerAccountId);
            return ok ? Result.ok("Đã duyệt yêu cầu tham gia.", null) : Result.fail("Không thể duyệt yêu cầu.");
        } catch (IllegalStateException ise) {
            return Result.fail(ise.getMessage());
        } catch (Exception e) {
            return Result.fail("Không thể duyệt yêu cầu lúc này. Vui lòng thử lại.");
        }
    }

    public Result rejectJoinRequest(int joinRequestId, int reviewerAccountId) {
        TeamJoinRequest jr = teamDAO.getJoinRequestById(joinRequestId);
        if (jr == null) return Result.fail("Yêu cầu tham gia không tồn tại.");
        if (!isCaptainOrCoCaptain(jr.getTeamId(), reviewerAccountId)) return Result.fail("Bạn không có quyền từ chối yêu cầu này.");
        boolean ok = teamDAO.rejectJoinRequest(joinRequestId, reviewerAccountId);
        return ok ? Result.ok("Đã từ chối yêu cầu tham gia.", null) : Result.fail("Không thể từ chối yêu cầu.");
    }

    // ============================ Members ============================

    public Result removeMember(int teamId, int actorAccountId, int targetAccountId) {
        if (actorAccountId == targetAccountId) return Result.fail("Không thể tự xóa chính mình khỏi đội bằng chức năng này — hãy dùng 'Rời đội'.");
        if (!isCaptainOrCoCaptain(teamId, actorAccountId)) return Result.fail("Bạn không có quyền xóa thành viên.");
        TeamMember target = teamDAO.getActiveMembership(teamId, targetAccountId);
        if (target == null) return Result.fail("Người này không phải thành viên của đội.");
        if (TeamMember.ROLE_CAPTAIN.equals(target.getMemberRole())) return Result.fail("Không thể xóa đội trưởng.");
        boolean ok = teamDAO.deactivateMember(teamId, targetAccountId, TeamMember.STATUS_REMOVED);
        return ok ? Result.ok("Đã xóa thành viên khỏi đội.", null) : Result.fail("Không thể xóa thành viên.");
    }

    public Result leaveTeam(int teamId, int accountId) {
        TeamMember membership = teamDAO.getActiveMembership(teamId, accountId);
        if (membership == null) return Result.fail("Bạn không phải thành viên của đội này.");
        if (TeamMember.ROLE_CAPTAIN.equals(membership.getMemberRole())) {
            return Result.fail("Đội trưởng phải chuyển quyền cho người khác hoặc giải tán đội trước khi rời đội.");
        }
        boolean ok = teamDAO.deactivateMember(teamId, accountId, TeamMember.STATUS_LEFT);
        return ok ? Result.ok("Đã rời đội.", null) : Result.fail("Không thể rời đội lúc này.");
    }

    public Result transferCaptain(int teamId, int actorAccountId, int newCaptainAccountId) {
        Team team = teamDAO.getTeamById(teamId);
        if (team == null || team.isDeleted()) return Result.fail("Đội không tồn tại.");
        if (team.getCaptainAccountId() != actorAccountId) return Result.fail("Chỉ đội trưởng mới có thể chuyển quyền.");
        if (actorAccountId == newCaptainAccountId) return Result.fail("Bạn đã là đội trưởng.");
        TeamMember target = teamDAO.getActiveMembership(teamId, newCaptainAccountId);
        if (target == null) return Result.fail("Người được chọn không phải thành viên của đội.");
        try {
            boolean ok = teamDAO.transferCaptain(teamId, actorAccountId, newCaptainAccountId);
            return ok ? Result.ok("Đã chuyển quyền đội trưởng.", null) : Result.fail("Không thể chuyển quyền đội trưởng.");
        } catch (IllegalStateException ise) {
            return Result.fail(ise.getMessage());
        } catch (Exception e) {
            return Result.fail("Không thể chuyển quyền lúc này. Vui lòng thử lại.");
        }
    }

    public Result disbandTeam(int teamId, int actorAccountId) {
        Team team = teamDAO.getTeamById(teamId);
        if (team == null || team.isDeleted()) return Result.fail("Đội không tồn tại.");
        if (team.getCaptainAccountId() != actorAccountId) return Result.fail("Chỉ đội trưởng mới có thể giải tán đội.");
        try {
            boolean ok = teamDAO.disbandTeam(teamId, actorAccountId);
            return ok ? Result.ok("Đã giải tán đội.", null) : Result.fail("Không thể giải tán đội.");
        } catch (Exception e) {
            return Result.fail("Không thể giải tán đội lúc này. Vui lòng thử lại.");
        }
    }

    // ============================ Helpers ============================

    public boolean isCaptainOrCoCaptain(int teamId, int accountId) {
        TeamMember m = teamDAO.getActiveMembership(teamId, accountId);
        return m != null && (TeamMember.ROLE_CAPTAIN.equals(m.getMemberRole()) || TeamMember.ROLE_CO_CAPTAIN.equals(m.getMemberRole()));
    }

    public boolean isCaptain(int teamId, int accountId) {
        Team team = teamDAO.getTeamById(teamId);
        return team != null && team.getCaptainAccountId() == accountId;
    }

    public boolean isActiveMember(int teamId, int accountId) {
        return teamDAO.getActiveMembership(teamId, accountId) != null;
    }
}
