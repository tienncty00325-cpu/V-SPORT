package org.example.service.matchmaking;

import org.example.dao.LichDatSanDAO;
import org.example.dao.TeamDAO;
import org.example.dao.TeamMatchDAO;
import org.example.dto.TeamChallengeDTO;
import org.example.dto.TeamMatchSummaryDTO;
import org.example.model.Lichdatsan;
import org.example.model.Team;

import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.regex.Pattern;

/**
 * Kèo đội (team-vs-team) — lớp mỏng bọc quanh domain Ghép kèo hiện có
 * (GhepKeo/ChiTietGhepKeo, qua TeamMatchDAO) và domain Team (qua TeamDAO,
 * để kiểm tra captain/co-captain). KHÔNG đụng GhepKeoService — kèo cá nhân
 * giữ nguyên hành vi cũ 100%.
 *
 * Giới hạn phạm vi đã biết (ghi rõ trong báo cáo cuối, không che giấu):
 * kèo đội vẫn yêu cầu một DatSanID có sẵn (lịch đặt sân thật của chính đội
 * trưởng), giống hệt ràng buộc DatSanID NOT NULL của GhepKeo cá nhân — chưa
 * hỗ trợ "chưa có lịch đặt sân" để tránh phải nới lỏng NOT NULL trên bảng
 * GhepKeo hiện có (ngoài phạm vi 2 cột TeamID mới). Chưa kiểm tra trùng
 * khung giờ giữa nhiều kèo đội ĐÃ khớp của cùng một đội (time-overlap).
 */
public class TeamMatchService {

    private static final Pattern HTML_TAG_CHARS = Pattern.compile("[<>]");
    private static final List<String> ELIGIBLE_BOOKING_STATUSES =
            List.of("Chờ xác nhận", "Đã xác nhận", "Chờ thanh toán");

    private final TeamMatchDAO teamMatchDAO;
    private final TeamDAO teamDAO;
    private final LichDatSanDAO lichDatSanDAO;

    public TeamMatchService(TeamMatchDAO teamMatchDAO, TeamDAO teamDAO, LichDatSanDAO lichDatSanDAO) {
        this.teamMatchDAO = teamMatchDAO;
        this.teamDAO = teamDAO;
        this.lichDatSanDAO = lichDatSanDAO;
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

    public Result createTeamMatch(int teamId, int actorAccountId, int datSanId, Integer monTheThaoId, String trinhDo, String note) {
        if (!isCaptainOrCoCaptain(teamId, actorAccountId)) {
            return Result.fail("Chỉ đội trưởng hoặc đội phó mới có thể tạo kèo cho đội.");
        }
        Team team = teamDAO.getTeamById(teamId);
        if (team == null || team.isDeleted() || !Team.STATUS_ACTIVE.equals(team.getStatus())) {
            return Result.fail("Đội không tồn tại hoặc không còn hoạt động.");
        }
        if (datSanId <= 0) return Result.fail("Vui lòng chọn một ca đặt sân của bạn để gắn kèo đội.");

        Lichdatsan booking = lichDatSanDAO.getLichById(datSanId);
        if (booking == null) return Result.fail("Ca đặt sân không tồn tại.");
        if (booking.getAccountId() == null || booking.getAccountId() != actorAccountId) {
            return Result.fail("Bạn chỉ có thể gắn kèo đội cho ca đặt sân của chính mình.");
        }
        if (!ELIGIBLE_BOOKING_STATUSES.contains(booking.getTrangThai())) {
            return Result.fail("Ca đặt sân này không ở trạng thái phù hợp để tạo kèo.");
        }
        if (booking.getNgayDat() != null && booking.getNgayDat().isBefore(LocalDate.now())) {
            return Result.fail("Không thể tạo kèo cho ca đặt sân trong quá khứ.");
        }

        String finalNote = note == null ? null : note.trim();
        if (finalNote != null) {
            if (finalNote.length() > 240) return Result.fail("Ghi chú tối đa 240 ký tự.");
            if (HTML_TAG_CHARS.matcher(finalNote).find()) return Result.fail("Ghi chú không được chứa ký tự '<' hoặc '>'.");
            if (finalNote.isEmpty()) finalNote = null;
        }

        try {
            int keoId = teamMatchDAO.createTeamMatch(teamId, actorAccountId, datSanId, monTheThaoId, trinhDo, finalNote);
            return keoId > 0 ? Result.ok("Đã tạo kèo cho đội.", keoId) : Result.fail("Không thể tạo kèo. Vui lòng thử lại.");
        } catch (IllegalStateException ise) {
            return Result.fail(ise.getMessage());
        } catch (Exception e) {
            return Result.fail("Không thể tạo kèo lúc này. Vui lòng thử lại.");
        }
    }

    public List<TeamMatchSummaryDTO> listOpenTeamMatches(Integer sportId, Integer excludeTeamId) {
        return teamMatchDAO.listOpenTeamMatches(sportId, excludeTeamId);
    }

    public List<TeamMatchSummaryDTO> listMyTeamMatches(int teamId) {
        return teamMatchDAO.listMyTeamMatches(teamId);
    }

    public List<TeamChallengeDTO> getPendingChallenges(int keoId, int actorAccountId) {
        TeamMatchSummaryDTO match = teamMatchDAO.getTeamMatchDetail(keoId);
        if (match == null || !isCaptainOrCoCaptain(match.getTeamIdNguoiTao(), actorAccountId)) return Collections.emptyList();
        return teamMatchDAO.getPendingChallenges(keoId);
    }

    public Result challengeTeamMatch(int keoId, int challengerTeamId, int actorAccountId) {
        if (!isCaptainOrCoCaptain(challengerTeamId, actorAccountId)) {
            return Result.fail("Chỉ đội trưởng hoặc đội phó mới có thể gửi thách đấu.");
        }
        Team team = teamDAO.getTeamById(challengerTeamId);
        if (team == null || team.isDeleted() || !Team.STATUS_ACTIVE.equals(team.getStatus())) {
            return Result.fail("Đội của bạn hiện không hoạt động.");
        }
        try {
            int id = teamMatchDAO.challengeTeamMatch(keoId, challengerTeamId, actorAccountId);
            return id > 0 ? Result.ok("Đã gửi thách đấu.", id) : Result.fail("Không thể gửi thách đấu.");
        } catch (IllegalStateException ise) {
            return Result.fail(ise.getMessage());
        } catch (Exception e) {
            return Result.fail("Không thể gửi thách đấu lúc này. Vui lòng thử lại.");
        }
    }

    public Result acceptChallenge(int chiTietKeoId, int keoId, int actorAccountId) {
        TeamMatchSummaryDTO match = teamMatchDAO.getTeamMatchDetail(keoId);
        if (match == null) return Result.fail("Kèo đội không tồn tại.");
        if (!isCaptainOrCoCaptain(match.getTeamIdNguoiTao(), actorAccountId)) {
            return Result.fail("Chỉ đội trưởng hoặc đội phó của đội tạo kèo mới có thể chấp nhận thách đấu.");
        }
        try {
            boolean ok = teamMatchDAO.acceptChallenge(chiTietKeoId, match.getTeamIdNguoiTao());
            return ok ? Result.ok("Đã chấp nhận thách đấu. Trận đấu đã được ghép.", null) : Result.fail("Không thể chấp nhận thách đấu.");
        } catch (IllegalStateException ise) {
            return Result.fail(ise.getMessage());
        } catch (Exception e) {
            return Result.fail("Không thể chấp nhận thách đấu lúc này. Vui lòng thử lại.");
        }
    }

    public Result rejectChallenge(int chiTietKeoId, int keoId, int actorAccountId) {
        TeamMatchSummaryDTO match = teamMatchDAO.getTeamMatchDetail(keoId);
        if (match == null) return Result.fail("Kèo đội không tồn tại.");
        if (!isCaptainOrCoCaptain(match.getTeamIdNguoiTao(), actorAccountId)) {
            return Result.fail("Chỉ đội trưởng hoặc đội phó của đội tạo kèo mới có thể từ chối thách đấu.");
        }
        boolean ok = teamMatchDAO.rejectChallenge(chiTietKeoId, match.getTeamIdNguoiTao());
        return ok ? Result.ok("Đã từ chối thách đấu.", null) : Result.fail("Không thể từ chối thách đấu.");
    }

    public Result cancelTeamMatch(int keoId, int actorAccountId) {
        TeamMatchSummaryDTO match = teamMatchDAO.getTeamMatchDetail(keoId);
        if (match == null) return Result.fail("Kèo đội không tồn tại.");
        if (!isCaptainOrCoCaptain(match.getTeamIdNguoiTao(), actorAccountId)) {
            return Result.fail("Chỉ đội trưởng hoặc đội phó mới có thể hủy kèo.");
        }
        boolean ok = teamMatchDAO.cancelTeamMatch(keoId, match.getTeamIdNguoiTao());
        return ok ? Result.ok("Đã hủy kèo.", null) : Result.fail("Không thể hủy kèo (có thể đã được xử lý).");
    }

    private boolean isCaptainOrCoCaptain(int teamId, int accountId) {
        var m = teamDAO.getActiveMembership(teamId, accountId);
        return m != null && (org.example.model.TeamMember.ROLE_CAPTAIN.equals(m.getMemberRole())
                || org.example.model.TeamMember.ROLE_CO_CAPTAIN.equals(m.getMemberRole()));
    }
}
