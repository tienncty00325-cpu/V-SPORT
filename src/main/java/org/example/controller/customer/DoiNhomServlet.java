package org.example.controller.customer;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonPrimitive;
import com.google.gson.JsonSerializer;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.dao.LoaiSanDAO;
import org.example.dao.TaiKhoanDAO;
import org.example.dao.TeamDAO;
import org.example.dao.impl.LoaiSanDAOImpl;
import org.example.dao.impl.TaiKhoanDAOImpl;
import org.example.dao.impl.TeamDAOImpl;
import org.example.dto.TeamDetailDTO;
import org.example.dto.TeamInvitationDTO;
import org.example.dto.TeamJoinRequestDTO;
import org.example.dto.TeamSummaryDTO;
import org.example.model.TaiKhoan;
import org.example.service.team.TeamInvitationService;
import org.example.service.team.TeamService;
import org.example.util.RoleRedirectUtil;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.nio.file.Paths;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Module Đội nhóm (Team management). Gom mọi route /customer/doi-nhom/* và
 * /customer/api/teams/* vào 1 servlet, phân nhánh theo getServletPath(),
 * theo đúng convention multi-route-per-servlet đã dùng ở GhepKeoServlet/
 * DatSanServlet. Trang + hành động AJAX (fetch + toast), không SQL ở JSP.
 */
@WebServlet(urlPatterns = {
        "/customer/doi-nhom",
        "/customer/doi-nhom/tao",
        "/customer/doi-nhom/chi-tiet",
        "/customer/doi-nhom/chinh-sua",
        "/customer/doi-nhom/xin-tham-gia",
        "/customer/doi-nhom/huy-yeu-cau",
        "/customer/doi-nhom/duyet-tham-gia",
        "/customer/doi-nhom/tu-choi-tham-gia",
        "/customer/doi-nhom/moi-thanh-vien",
        "/customer/doi-nhom/chap-nhan-loi-moi",
        "/customer/doi-nhom/tu-choi-loi-moi",
        "/customer/doi-nhom/roi-doi",
        "/customer/doi-nhom/xoa-thanh-vien",
        "/customer/doi-nhom/chuyen-quyen",
        "/customer/doi-nhom/giai-tan",
        "/customer/api/teams",
        "/customer/api/teams/detail",
        "/customer/api/teams/invitations",
        "/customer/api/teams/join-requests"
})
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 5 * 1024 * 1024,
        maxRequestSize = 12 * 1024 * 1024
)
public class DoiNhomServlet extends HttpServlet {

    private static final Logger logger = LogManager.getLogger(DoiNhomServlet.class);

    private static final Set<String> ALLOWED_IMAGE_TYPES = Set.of("image/jpeg", "image/png", "image/webp", "image/gif");

    private final TeamDAO teamDAO = new TeamDAOImpl();
    private final TeamService teamService = new TeamService(teamDAO);
    private final TeamInvitationService invitationService = new TeamInvitationService(teamDAO);
    private final LoaiSanDAO loaiSanDAO = new LoaiSanDAOImpl();
    private final TaiKhoanDAO taiKhoanDAO = new TaiKhoanDAOImpl();

    private static final Gson GSON = new GsonBuilder()
            .registerTypeAdapter(LocalDate.class, (JsonSerializer<LocalDate>) (s, t, c) -> new JsonPrimitive(s.toString()))
            .registerTypeAdapter(LocalTime.class, (JsonSerializer<LocalTime>) (s, t, c) -> new JsonPrimitive(s.toString()))
            .registerTypeAdapter(LocalDateTime.class, (JsonSerializer<LocalDateTime>) (s, t, c) -> new JsonPrimitive(s.toString()))
            .registerTypeAdapter(BigDecimal.class, (JsonSerializer<BigDecimal>) (s, t, c) -> new JsonPrimitive(s.toPlainString()))
            .create();

    /** Dùng khi cần nhúng JSON thẳng vào {@code <script>} trong JSP (DoiNhom.jsp) — Gson mặc định đã HTML-escape. */
    private static final Gson GSON_PLAIN = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();
        try {
            switch (path) {
                case "/customer/doi-nhom": handleDashboardPage(req, resp); return;
                case "/customer/doi-nhom/tao": handleFormPage(req, resp, false); return;
                case "/customer/doi-nhom/chinh-sua": handleFormPage(req, resp, true); return;
                case "/customer/doi-nhom/chi-tiet": handleDetailPage(req, resp); return;
                case "/customer/api/teams": handleApiTeams(req, resp); return;
                case "/customer/api/teams/detail": handleApiTeamDetail(req, resp); return;
                case "/customer/api/teams/invitations": handleApiInvitations(req, resp); return;
                case "/customer/api/teams/join-requests": handleApiJoinRequests(req, resp); return;
                default: resp.sendError(HttpServletResponse.SC_NOT_FOUND); return;
            }
        } catch (RuntimeException e) {
            handleUnexpectedError(req, resp, path, e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();
        try {
            switch (path) {
                case "/customer/doi-nhom/tao": handleCreate(req, resp); return;
                case "/customer/doi-nhom/chinh-sua": handleUpdate(req, resp); return;
                case "/customer/doi-nhom/xin-tham-gia": handleSendJoinRequest(req, resp); return;
                case "/customer/doi-nhom/huy-yeu-cau": handleCancelJoinRequest(req, resp); return;
                case "/customer/doi-nhom/duyet-tham-gia": handleApproveJoinRequest(req, resp); return;
                case "/customer/doi-nhom/tu-choi-tham-gia": handleRejectJoinRequest(req, resp); return;
                case "/customer/doi-nhom/moi-thanh-vien": handleInviteMember(req, resp); return;
                case "/customer/doi-nhom/chap-nhan-loi-moi": handleAcceptInvitation(req, resp); return;
                case "/customer/doi-nhom/tu-choi-loi-moi": handleRejectInvitation(req, resp); return;
                case "/customer/doi-nhom/roi-doi": handleLeaveTeam(req, resp); return;
                case "/customer/doi-nhom/xoa-thanh-vien": handleRemoveMember(req, resp); return;
                case "/customer/doi-nhom/chuyen-quyen": handleTransferCaptain(req, resp); return;
                case "/customer/doi-nhom/giai-tan": handleDisband(req, resp); return;
                default: resp.sendError(HttpServletResponse.SC_NOT_FOUND); return;
            }
        } catch (RuntimeException e) {
            handleUnexpectedError(req, resp, path, e);
        }
    }

    /**
     * Lưới an toàn cuối cùng cho toàn bộ route /customer/doi-nhom/* và
     * /customer/api/teams/*: không bao giờ để RuntimeException (vd. SQLException
     * do bảng Teams/TeamMembers/... chưa được migrate) rơi xuống container và
     * kích hoạt trang lỗi chung /Error.jsp. Log đầy đủ ở server, trả về JSON
     * thân thiện cho route API hoặc điều hướng về dashboard cho route trang.
     */
    private void handleUnexpectedError(HttpServletRequest req, HttpServletResponse resp, String path, RuntimeException e) throws IOException {
        logger.error("Lỗi không mong muốn khi xử lý {}: {}", path, describeRootCause(e), e);
        if (path.startsWith("/customer/api/")) {
            writeJson(resp, 503, Map.of("success", false, "message", "Chức năng Đội nhóm đang được cấu hình. Vui lòng thử lại sau."));
        } else if (!resp.isCommitted()) {
            resp.sendRedirect(req.getContextPath() + "/customer/doi-nhom");
        }
    }

    /**
     * Dò tìm SQLException trong chuỗi nguyên nhân để ghi log rõ ràng khi bảng
     * dữ liệu Đội nhóm chưa được khởi tạo (migration chưa chạy) — giúp phân
     * biệt ngay trong log server thay vì phải đoán từ stack trace chung chung.
     */
    private String describeRootCause(Throwable e) {
        Throwable t = e;
        while (t != null) {
            if (t instanceof SQLException se) {
                String msg = se.getMessage() != null ? se.getMessage() : "";
                if (msg.contains("Invalid object name") && (msg.contains("Teams") || msg.contains("TeamMembers")
                        || msg.contains("TeamInvitations") || msg.contains("TeamJoinRequests"))) {
                    return "Bảng dữ liệu Đội nhóm chưa được khởi tạo trên database — cần chạy sql/migration_team_management.sql. Chi tiết SQL: " + msg;
                }
                return "SQLException (SQLState=" + se.getSQLState() + ", ErrorCode=" + se.getErrorCode() + "): " + msg;
            }
            t = t.getCause();
        }
        return e.getMessage();
    }

    // ============================ Pages ============================

    private void handleDashboardPage(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        TaiKhoan user = requireCustomer(req, resp);
        if (user == null) return;
        String tab = req.getParameter("tab");
        if (tab == null || (!tab.equals("my-teams") && !tab.equals("discover") && !tab.equals("invitations"))) {
            tab = "my-teams";
        }
        req.setAttribute("activeTab", tab);
        req.setAttribute("dsMon", safeSports());

        // Gson mặc định HTML-escape (<...) các ký tự <, >, &, ' khi toJson — an toàn
        // để nhúng thẳng vào <script> mà không bị phá cú pháp hay mở đường XSS qua TeamName/Description.
        String myTeamsJson = "[]";
        String discoverJson = "[]";
        String invitationsJson = "[]";
        try {
            myTeamsJson = GSON_PLAIN.toJson(teamService.getMyTeams(user.getAccountId()));
            discoverJson = GSON_PLAIN.toJson(teamService.discoverTeams(user.getAccountId(), null, null, false));
            invitationsJson = GSON_PLAIN.toJson(invitationService.getMyPendingInvitations(user.getAccountId()));
        } catch (RuntimeException e) {
            // Không bao giờ ném lỗi ra ngoài ở đây: người dùng chưa có đội và người
            // dùng gặp lỗi hạ tầng (bảng chưa migrate, mất kết nối DB...) đều phải
            // thấy được trang Đội nhóm bình thường — chỉ khác nhau ở banner thông báo.
            // Chi tiết SQL/tên bảng chỉ nằm trong log server, không lộ ra UI.
            logger.error("Không thể tải dữ liệu Đội nhóm cho accountId={}: {}", user.getAccountId(), describeRootCause(e), e);
            req.setAttribute("teamsFeaturePending", true);
        }
        req.setAttribute("myTeamsJson", myTeamsJson);
        req.setAttribute("discoverJson", discoverJson);
        req.setAttribute("invitationsJson", invitationsJson);
        req.getRequestDispatcher("/customer/DoiNhom.jsp").forward(req, resp);
    }

    private void handleFormPage(HttpServletRequest req, HttpServletResponse resp, boolean editMode) throws ServletException, IOException {
        TaiKhoan user = requireCustomer(req, resp);
        if (user == null) return;
        req.setAttribute("dsMon", safeSports());
        req.setAttribute("editMode", editMode);
        if (editMode) {
            Integer teamId = parseIntSafe(req.getParameter("id"));
            if (teamId == null) { resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Thiếu id."); return; }
            TeamDetailDTO team = teamService.getTeamDetail(teamId, user.getAccountId());
            if (team == null) { resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Đội không tồn tại."); return; }
            if (!team.isCaptain()) { resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Chỉ đội trưởng mới có thể chỉnh sửa đội."); return; }
            req.setAttribute("team", team);
        }
        req.getRequestDispatcher("/customer/DoiNhomTao.jsp").forward(req, resp);
    }

    private void handleDetailPage(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        TaiKhoan user = requireCustomer(req, resp);
        if (user == null) return;
        Integer teamId = parseIntSafe(req.getParameter("id"));
        if (teamId == null) { resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Thiếu id."); return; }
        TeamDetailDTO team = teamService.getTeamDetail(teamId, user.getAccountId());
        if (team == null) { resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Đội không tồn tại."); return; }
        req.setAttribute("team", team);
        req.setAttribute("dsMon", safeSports());
        if (team.isCaptain() || team.isCoCaptain()) {
            req.setAttribute("joinRequests", teamService.getPendingJoinRequests(teamId, user.getAccountId()));
        }
        req.getRequestDispatcher("/customer/DoiNhomChiTiet.jsp").forward(req, resp);
    }

    // ============================ JSON page-data (tab AJAX refresh) ============================

    private void handleApiTeams(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        String tab = req.getParameter("tab");
        if ("discover".equals(tab)) {
            String keyword = req.getParameter("keyword");
            Integer sportId = parseIntSafe(req.getParameter("sportId"));
            boolean onlyOpen = "true".equals(req.getParameter("onlyOpenSlots"));
            List<TeamSummaryDTO> list = teamService.discoverTeams(user.getAccountId(), keyword, sportId, onlyOpen);
            writeJson(resp, 200, list);
        } else {
            writeJson(resp, 200, teamService.getMyTeams(user.getAccountId()));
        }
    }

    private void handleApiTeamDetail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer teamId = parseIntSafe(req.getParameter("teamId"));
        if (teamId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu teamId.")); return; }
        TeamDetailDTO team = teamService.getTeamDetail(teamId, user.getAccountId());
        if (team == null) { writeJson(resp, 404, Map.of("success", false, "message", "Đội không tồn tại.")); return; }
        writeJson(resp, 200, team);
    }

    private void handleApiInvitations(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        List<TeamInvitationDTO> list = invitationService.getMyPendingInvitations(user.getAccountId());
        writeJson(resp, 200, list);
    }

    private void handleApiJoinRequests(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer teamId = parseIntSafe(req.getParameter("teamId"));
        if (teamId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu teamId.")); return; }
        List<TeamJoinRequestDTO> list = teamService.getPendingJoinRequests(teamId, user.getAccountId());
        writeJson(resp, 200, list);
    }

    // ============================ Mutations ============================

    private void handleCreate(HttpServletRequest req, HttpServletResponse resp) throws IOException, ServletException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;

        TeamService.CreateRequest cr = new TeamService.CreateRequest();
        cr.accountId = user.getAccountId();
        cr.teamName = req.getParameter("teamName");
        cr.description = req.getParameter("description");
        cr.sportId = parseIntOr(req.getParameter("sportId"), 0);
        cr.locationText = req.getParameter("locationText");
        cr.maxMembers = parseIntOr(req.getParameter("maxMembers"), 0);

        try {
            cr.avatarPath = handleImageUpload(req, "avatarFile", "avatars", ALLOWED_IMAGE_TYPES);
            cr.coverImagePath = handleImageUpload(req, "coverFile", "covers", ALLOWED_IMAGE_TYPES);
        } catch (IllegalArgumentException iae) {
            writeJson(resp, 400, Map.of("success", false, "message", iae.getMessage()));
            return;
        }

        TeamService.Result result = teamService.createTeam(cr);
        writeResult(resp, result.success, result.message, result.id != null ? Map.of("teamId", result.id) : null);
    }

    private void handleUpdate(HttpServletRequest req, HttpServletResponse resp) throws IOException, ServletException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer teamId = parseIntSafe(req.getParameter("teamId"));
        if (teamId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu teamId.")); return; }

        String teamName = req.getParameter("teamName");
        String description = req.getParameter("description");
        Integer sportId = parseIntSafe(req.getParameter("sportId"));
        String locationText = req.getParameter("locationText");
        Integer maxMembers = parseIntSafe(req.getParameter("maxMembers"));

        TeamService.Result result = teamService.updateTeam(teamId, user.getAccountId(), teamName, description, sportId, locationText, maxMembers);
        if (!result.success) { writeResult(resp, false, result.message, null); return; }

        try {
            String avatarPath = handleImageUpload(req, "avatarFile", "avatars", ALLOWED_IMAGE_TYPES);
            if (avatarPath != null) teamDAO.updateAvatarPath(teamId, avatarPath);
            String coverPath = handleImageUpload(req, "coverFile", "covers", ALLOWED_IMAGE_TYPES);
            if (coverPath != null) teamDAO.updateCoverImagePath(teamId, coverPath);
        } catch (IllegalArgumentException iae) {
            writeJson(resp, 400, Map.of("success", false, "message", iae.getMessage()));
            return;
        }
        writeResult(resp, true, "Cập nhật đội thành công.", Map.of("teamId", teamId));
    }

    private void handleSendJoinRequest(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer teamId = parseIntSafe(req.getParameter("teamId"));
        if (teamId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu teamId.")); return; }
        TeamService.Result r = teamService.sendJoinRequest(teamId, user.getAccountId(), req.getParameter("message"));
        writeResult(resp, r.success, r.message, null);
    }

    private void handleCancelJoinRequest(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer id = parseIntSafe(req.getParameter("joinRequestId"));
        if (id == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu joinRequestId.")); return; }
        TeamService.Result r = teamService.cancelJoinRequest(id, user.getAccountId());
        writeResult(resp, r.success, r.message, null);
    }

    private void handleApproveJoinRequest(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer id = parseIntSafe(req.getParameter("joinRequestId"));
        if (id == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu joinRequestId.")); return; }
        TeamService.Result r = teamService.approveJoinRequest(id, user.getAccountId());
        writeResult(resp, r.success, r.message, null);
    }

    private void handleRejectJoinRequest(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer id = parseIntSafe(req.getParameter("joinRequestId"));
        if (id == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu joinRequestId.")); return; }
        TeamService.Result r = teamService.rejectJoinRequest(id, user.getAccountId());
        writeResult(resp, r.success, r.message, null);
    }

    private void handleInviteMember(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer teamId = parseIntSafe(req.getParameter("teamId"));
        String email = req.getParameter("email");
        if (teamId == null || email == null || email.trim().isEmpty()) {
            writeJson(resp, 400, Map.of("success", false, "message", "Vui lòng nhập email cần mời."));
            return;
        }
        TaiKhoan invited = taiKhoanDAO.findByEmail(email.trim());
        if (invited == null || (invited.isDeleted() != null && invited.isDeleted()) || invited.isLocked()) {
            writeJson(resp, 404, Map.of("success", false, "message", "Không tìm thấy tài khoản khách hàng hợp lệ với email này."));
            return;
        }
        if (invited.getRoleId() != RoleRedirectUtil.ROLE_CUSTOMER) {
            writeJson(resp, 400, Map.of("success", false, "message", "Chỉ có thể mời tài khoản Khách hàng."));
            return;
        }
        TeamInvitationService.Result r = invitationService.inviteMember(teamId, user.getAccountId(), invited.getAccountId(), req.getParameter("proposedRole"), req.getParameter("message"));
        writeResult(resp, r.success, r.message, null);
    }

    private void handleAcceptInvitation(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer id = parseIntSafe(req.getParameter("invitationId"));
        if (id == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu invitationId.")); return; }
        TeamInvitationService.Result r = invitationService.acceptInvitation(id, user.getAccountId());
        writeResult(resp, r.success, r.message, r.id != null ? Map.of("teamId", r.id) : null);
    }

    private void handleRejectInvitation(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer id = parseIntSafe(req.getParameter("invitationId"));
        if (id == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu invitationId.")); return; }
        TeamInvitationService.Result r = invitationService.rejectInvitation(id, user.getAccountId());
        writeResult(resp, r.success, r.message, null);
    }

    private void handleLeaveTeam(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer teamId = parseIntSafe(req.getParameter("teamId"));
        if (teamId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu teamId.")); return; }
        TeamService.Result r = teamService.leaveTeam(teamId, user.getAccountId());
        writeResult(resp, r.success, r.message, null);
    }

    private void handleRemoveMember(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer teamId = parseIntSafe(req.getParameter("teamId"));
        Integer targetAccountId = parseIntSafe(req.getParameter("accountId"));
        if (teamId == null || targetAccountId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu tham số.")); return; }
        TeamService.Result r = teamService.removeMember(teamId, user.getAccountId(), targetAccountId);
        writeResult(resp, r.success, r.message, null);
    }

    private void handleTransferCaptain(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer teamId = parseIntSafe(req.getParameter("teamId"));
        Integer newCaptainAccountId = parseIntSafe(req.getParameter("accountId"));
        if (teamId == null || newCaptainAccountId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu tham số.")); return; }
        TeamService.Result r = teamService.transferCaptain(teamId, user.getAccountId(), newCaptainAccountId);
        writeResult(resp, r.success, r.message, null);
    }

    private void handleDisband(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer teamId = parseIntSafe(req.getParameter("teamId"));
        if (teamId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu teamId.")); return; }
        TeamService.Result r = teamService.disbandTeam(teamId, user.getAccountId());
        writeResult(resp, r.success, r.message, null);
    }

    // ============================ Upload helper ============================

    /**
     * Đọc Part {partName}, validate Content-Type khai báo VÀ magic-byte thật của
     * file (không chỉ tin Content-Type do trình duyệt gửi lên), lưu vào
     * /uploads/teams/{subdir}/team-{uuid}{ext}, trả về path web-relative để
     * lưu DB. Trả null nếu user không chọn file (giữ nguyên ảnh cũ khi update).
     */
    private String handleImageUpload(HttpServletRequest req, String partName, String subdir, Set<String> allowedTypes) throws IOException, ServletException {
        Part part;
        try {
            part = req.getPart(partName);
        } catch (Exception e) {
            return null; // request không phải multipart hoặc field không tồn tại — bỏ qua, không lỗi.
        }
        if (part == null || part.getSize() <= 0) return null;

        String contentType = part.getContentType();
        if (contentType == null || !allowedTypes.contains(contentType)) {
            throw new IllegalArgumentException("Chỉ hỗ trợ ảnh JPG, PNG, WEBP hoặc GIF.");
        }
        byte[] header = new byte[12];
        int read;
        try (InputStream is = part.getInputStream()) {
            read = is.readNBytes(header, 0, header.length);
        }
        if (!looksLikeImage(header, read)) {
            throw new IllegalArgumentException("Tệp không phải ảnh hợp lệ (kiểm tra nội dung thực tế thất bại).");
        }

        String extension = getSafeImageExtension(part.getSubmittedFileName(), contentType);
        String fileName = "team-" + UUID.randomUUID() + extension;

        String uploadPath = getServletContext().getRealPath("/uploads/teams/" + subdir);
        if (uploadPath == null) {
            uploadPath = new File(System.getProperty("user.home"), "v-sport/uploads/teams/" + subdir).getAbsolutePath();
        }
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists() && !uploadDir.mkdirs()) {
            throw new IOException("Không thể tạo thư mục lưu ảnh đội.");
        }
        File target = new File(uploadDir, fileName);
        part.write(target.getAbsolutePath());
        return "/uploads/teams/" + subdir + "/" + fileName;
    }

    /** Kiểm tra magic bytes JPEG/PNG/GIF/WEBP thật — không tin Content-Type do client khai báo. */
    private boolean looksLikeImage(byte[] b, int len) {
        if (len >= 3 && (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF) return true; // JPEG
        if (len >= 8 && (b[0] & 0xFF) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G') return true; // PNG
        if (len >= 6 && b[0] == 'G' && b[1] == 'I' && b[2] == 'F' && b[3] == '8') return true; // GIF87a/GIF89a
        if (len >= 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') return true; // WEBP (RIFF....WEBP)
        return false;
    }

    private String getSafeImageExtension(String submittedFileName, String contentType) {
        String ext = null;
        if (submittedFileName != null && !submittedFileName.isBlank()) {
            String name = Paths.get(submittedFileName).getFileName().toString().toLowerCase();
            int dot = name.lastIndexOf('.');
            if (dot >= 0) {
                String candidate = name.substring(dot);
                if (Set.of(".jpg", ".jpeg", ".png", ".webp", ".gif").contains(candidate)) ext = candidate;
            }
        }
        if (ext == null) {
            if ("image/png".equals(contentType)) ext = ".png";
            else if ("image/webp".equals(contentType)) ext = ".webp";
            else if ("image/gif".equals(contentType)) ext = ".gif";
            else ext = ".jpg";
        }
        return ext;
    }

    // ============================ Helpers ============================

    private List<org.example.model.MonTheThao> safeSports() {
        try {
            return loaiSanDAO.getAllMonTheThao();
        } catch (Exception e) {
            logger.error("Lỗi tải danh sách môn thể thao cho trang đội nhóm: {}", e.getMessage(), e);
            return List.of();
        }
    }

    private TaiKhoan requireCustomer(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan user = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return null;
        }
        if (user.getRoleId() != RoleRedirectUtil.ROLE_CUSTOMER) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Trang này chỉ dành cho tài khoản Khách hàng.");
            return null;
        }
        return user;
    }

    private TaiKhoan requireCustomerJson(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan user = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        if (user == null) {
            writeJson(resp, 401, Map.of("success", false, "message", "Vui lòng đăng nhập."));
            return null;
        }
        if (user.getRoleId() != RoleRedirectUtil.ROLE_CUSTOMER) {
            writeJson(resp, 403, Map.of("success", false, "message", "Trang này chỉ dành cho tài khoản Khách hàng."));
            return null;
        }
        return user;
    }

    private void writeResult(HttpServletResponse resp, boolean success, String message, Map<String, Object> extra) throws IOException {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", success);
        body.put("message", message);
        if (extra != null) body.putAll(extra);
        writeJson(resp, success ? 200 : 400, body);
    }

    private void writeJson(HttpServletResponse resp, int status, Object payload) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json; charset=UTF-8");
        resp.getWriter().write(GSON.toJson(payload));
    }

    private Integer parseIntSafe(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return null; }
    }

    private int parseIntOr(String s, int fallback) {
        Integer v = parseIntSafe(s);
        return v != null ? v : fallback;
    }
}
