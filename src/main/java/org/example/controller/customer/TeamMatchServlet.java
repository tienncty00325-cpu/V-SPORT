package org.example.controller.customer;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonPrimitive;
import com.google.gson.JsonSerializer;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.dao.CoSoDAO;
import org.example.dao.LichDatSanDAO;
import org.example.dao.LoaiSanDAO;
import org.example.dao.SanDAO;
import org.example.dao.TeamDAO;
import org.example.dao.TeamMatchDAO;
import org.example.dao.impl.CoSoDAOImpl;
import org.example.dao.impl.LichDatSanDAOImpl;
import org.example.dao.impl.LoaiSanDAOImpl;
import org.example.dao.impl.SanDAOImpl;
import org.example.dao.impl.TeamDAOImpl;
import org.example.dao.impl.TeamMatchDAOImpl;
import org.example.dto.TeamChallengeDTO;
import org.example.dto.TeamMatchSummaryDTO;
import org.example.model.CoSo;
import org.example.model.LoaiSan;
import org.example.model.Lichdatsan;
import org.example.model.San;
import org.example.model.TaiKhoan;
import org.example.service.matchmaking.TeamMatchService;
import org.example.util.RoleRedirectUtil;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Kèo đội (team-vs-team), lớp mỏng tích hợp với Ghép kèo hiện có — xem
 * javadoc TeamMatchService/TeamMatchDAO. Không đụng GhepKeoServlet.
 */
@WebServlet(urlPatterns = {
        "/customer/doi-nhom/tao-keo",
        "/customer/doi-nhom/thach-dau",
        "/customer/doi-nhom/chap-nhan-thach-dau",
        "/customer/doi-nhom/tu-choi-thach-dau",
        "/customer/doi-nhom/huy-keo",
        "/customer/api/team-matches",
        "/customer/api/team-matches/mine",
        "/customer/api/team-matches/challenges",
        "/customer/api/team-matches/eligible-bookings"
})
public class TeamMatchServlet extends HttpServlet {

    private static final List<String> ELIGIBLE_STATUSES = List.of("Chờ xác nhận", "Đã xác nhận", "Chờ thanh toán");

    private final TeamDAO teamDAO = new TeamDAOImpl();
    private final TeamMatchDAO teamMatchDAO = new TeamMatchDAOImpl();
    private final LichDatSanDAO lichDatSanDAO = new LichDatSanDAOImpl();
    private final SanDAO sanDAO = new SanDAOImpl();
    private final CoSoDAO coSoDAO = new CoSoDAOImpl();
    private final LoaiSanDAO loaiSanDAO = new LoaiSanDAOImpl();
    private final TeamMatchService service = new TeamMatchService(teamMatchDAO, teamDAO, lichDatSanDAO);

    private static final Gson GSON = new GsonBuilder()
            .registerTypeAdapter(LocalDate.class, (JsonSerializer<LocalDate>) (s, t, c) -> new JsonPrimitive(s.toString()))
            .registerTypeAdapter(LocalTime.class, (JsonSerializer<LocalTime>) (s, t, c) -> new JsonPrimitive(s.toString()))
            .registerTypeAdapter(LocalDateTime.class, (JsonSerializer<LocalDateTime>) (s, t, c) -> new JsonPrimitive(s.toString()))
            .registerTypeAdapter(BigDecimal.class, (JsonSerializer<BigDecimal>) (s, t, c) -> new JsonPrimitive(s.toPlainString()))
            .create();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();
        switch (path) {
            case "/customer/doi-nhom/tao-keo": handleCreateMatchPageRedirect(req, resp); return;
            case "/customer/api/team-matches": handleListOpen(req, resp); return;
            case "/customer/api/team-matches/mine": handleListMine(req, resp); return;
            case "/customer/api/team-matches/challenges": handleListChallenges(req, resp); return;
            case "/customer/api/team-matches/eligible-bookings": handleEligibleBookings(req, resp); return;
            default: resp.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();
        switch (path) {
            case "/customer/doi-nhom/tao-keo": handleCreateMatch(req, resp); return;
            case "/customer/doi-nhom/thach-dau": handleChallenge(req, resp); return;
            case "/customer/doi-nhom/chap-nhan-thach-dau": handleAcceptChallenge(req, resp); return;
            case "/customer/doi-nhom/tu-choi-thach-dau": handleRejectChallenge(req, resp); return;
            case "/customer/doi-nhom/huy-keo": handleCancelMatch(req, resp); return;
            default: resp.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    /** GET /customer/doi-nhom/tao-keo?teamId= chỉ là lối vào tiện lợi — mở panel "Tạo kèo đội" ngay trong trang chi tiết đội. */
    private void handleCreateMatchPageRedirect(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomer(req, resp);
        if (user == null) return;
        String teamId = req.getParameter("teamId");
        String suffix = teamId != null ? "?id=" + teamId + "#tao-keo" : "#tao-keo";
        resp.sendRedirect(req.getContextPath() + "/customer/doi-nhom/chi-tiet" + suffix);
    }

    private void handleListOpen(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer sportId = parseIntSafe(req.getParameter("sportId"));
        Integer excludeTeamId = parseIntSafe(req.getParameter("excludeTeamId"));
        writeJson(resp, 200, service.listOpenTeamMatches(sportId, excludeTeamId));
    }

    private void handleListMine(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer teamId = parseIntSafe(req.getParameter("teamId"));
        if (teamId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu teamId.")); return; }
        writeJson(resp, 200, service.listMyTeamMatches(teamId));
    }

    private void handleListChallenges(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer keoId = parseIntSafe(req.getParameter("keoId"));
        if (keoId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu keoId.")); return; }
        List<TeamChallengeDTO> challenges = service.getPendingChallenges(keoId, user.getAccountId());
        writeJson(resp, 200, challenges);
    }

    /** Danh sách ca đặt sân của chính user hiện tại đủ điều kiện gắn kèo đội — cùng logic GhepKeoServlet.handleMyBookings. */
    private void handleEligibleBookings(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        List<Lichdatsan> raw = lichDatSanDAO.getLichByAccountId(user.getAccountId());
        List<Map<String, Object>> list = new ArrayList<>();
        LocalDate today = LocalDate.now();
        for (Lichdatsan l : raw) {
            if (l.getNgayDat() == null || l.getNgayDat().isBefore(today)) continue;
            if (!ELIGIBLE_STATUSES.contains(l.getTrangThai())) continue;
            San san = l.getSanId() != null ? sanDAO.getSanById(l.getSanId()) : null;
            CoSo cs = san != null ? coSoDAO.getCoSoById(san.getCoSoID()) : null;
            LoaiSan ls = san != null ? loaiSanDAO.getLoaiSanById(san.getLoaiSanID()) : null;
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("datSanId", l.getDatSanId());
            item.put("ngayDat", l.getNgayDat());
            item.put("gioBatDau", l.getGioBatDau());
            item.put("gioKetThuc", l.getGioKetThuc());
            item.put("tenSan", san != null ? san.getTenSan() : ("Sân #" + l.getSanId()));
            item.put("tenCoSo", cs != null ? cs.getTenCoSo() : "");
            item.put("monTheThaoId", ls != null ? ls.getMonTheThaoID() : null);
            list.add(item);
        }
        writeJson(resp, 200, Map.of("success", true, "bookings", list));
    }

    private void handleCreateMatch(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer teamId = parseIntSafe(req.getParameter("teamId"));
        Integer datSanId = parseIntSafe(req.getParameter("datSanId"));
        if (teamId == null || datSanId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu teamId hoặc datSanId.")); return; }
        Integer monTheThaoId = parseIntSafe(req.getParameter("monTheThaoId"));
        TeamMatchService.Result r = service.createTeamMatch(teamId, user.getAccountId(), datSanId, monTheThaoId, req.getParameter("trinhDo"), req.getParameter("note"));
        writeResult(resp, r.success, r.message, r.id != null ? Map.of("keoId", r.id) : null);
    }

    private void handleChallenge(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer keoId = parseIntSafe(req.getParameter("keoId"));
        Integer challengerTeamId = parseIntSafe(req.getParameter("challengerTeamId"));
        if (keoId == null || challengerTeamId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu tham số.")); return; }
        TeamMatchService.Result r = service.challengeTeamMatch(keoId, challengerTeamId, user.getAccountId());
        writeResult(resp, r.success, r.message, null);
    }

    private void handleAcceptChallenge(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer chiTietKeoId = parseIntSafe(req.getParameter("chiTietKeoId"));
        Integer keoId = parseIntSafe(req.getParameter("keoId"));
        if (chiTietKeoId == null || keoId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu tham số.")); return; }
        TeamMatchService.Result r = service.acceptChallenge(chiTietKeoId, keoId, user.getAccountId());
        writeResult(resp, r.success, r.message, null);
    }

    private void handleRejectChallenge(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer chiTietKeoId = parseIntSafe(req.getParameter("chiTietKeoId"));
        Integer keoId = parseIntSafe(req.getParameter("keoId"));
        if (chiTietKeoId == null || keoId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu tham số.")); return; }
        TeamMatchService.Result r = service.rejectChallenge(chiTietKeoId, keoId, user.getAccountId());
        writeResult(resp, r.success, r.message, null);
    }

    private void handleCancelMatch(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;
        Integer keoId = parseIntSafe(req.getParameter("keoId"));
        if (keoId == null) { writeJson(resp, 400, Map.of("success", false, "message", "Thiếu keoId.")); return; }
        TeamMatchService.Result r = service.cancelTeamMatch(keoId, user.getAccountId());
        writeResult(resp, r.success, r.message, null);
    }

    // ============================ Helpers ============================

    private TaiKhoan requireCustomer(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan user = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        if (user == null) { resp.sendRedirect(req.getContextPath() + "/dangnhap"); return null; }
        if (user.getRoleId() != RoleRedirectUtil.ROLE_CUSTOMER) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Trang này chỉ dành cho tài khoản Khách hàng.");
            return null;
        }
        return user;
    }

    private TaiKhoan requireCustomerJson(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan user = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        if (user == null) { writeJson(resp, 401, Map.of("success", false, "message", "Vui lòng đăng nhập.")); return null; }
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
}
