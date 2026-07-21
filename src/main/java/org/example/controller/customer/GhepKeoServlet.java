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
import org.example.dao.GhepKeoDAO;
import org.example.dao.LichDatSanDAO;
import org.example.dao.LoaiSanDAO;
import org.example.dao.SanDAO;
import org.example.dao.impl.CoSoDAOImpl;
import org.example.dao.impl.GhepKeoDAOImpl;
import org.example.dao.impl.LichDatSanDAOImpl;
import org.example.dao.impl.LoaiSanDAOImpl;
import org.example.dao.impl.SanDAOImpl;
import org.example.model.Lichdatsan;
import org.example.model.TaiKhoan;
import org.example.service.matchmaking.GhepKeoService;
import org.example.util.RoleRedirectUtil;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Trang "Ghép trận" cho Customer + full REST-ish API cho luồng tạo/tìm/tham gia kèo.
 *
 * Routes:
 *  - GET  /customer/ghep-keo                    → render trang JSP.
 *  - POST /customer/ghep-keo                    → tạo kèo (multipart form thường).
 *  - GET  /customer/api/matches                 → liệt kê kèo đang mở (JSON, có filter).
 *  - GET  /customer/api/matches/detail          → chi tiết một kèo (JSON).
 *  - GET  /customer/api/matches/mine            → kèo của tôi (đã tạo / đã tham gia).
 *  - GET  /customer/api/matches/my-bookings     → các ca đặt sân của tôi để chọn khi tạo kèo.
 *  - POST /customer/api/matches/join            → xin tham gia (payload: keoId).
 *  - POST /customer/api/matches/approve         → chủ kèo duyệt (payload: chiTietKeoId).
 *  - POST /customer/api/matches/reject          → chủ kèo từ chối.
 *  - POST /customer/api/matches/leave           → người chơi tự rời.
 *  - POST /customer/api/matches/cancel          → chủ kèo huỷ toàn bộ kèo.
 *  - POST /customer/api/matches/close           → chủ kèo dừng nhận thêm người.
 */
@WebServlet(urlPatterns = {
        "/customer/ghep-keo",
        "/customer/api/matches",
        "/customer/api/matches/detail",
        "/customer/api/matches/mine",
        "/customer/api/matches/my-bookings",
        "/customer/api/matches/join",
        "/customer/api/matches/approve",
        "/customer/api/matches/reject",
        "/customer/api/matches/leave",
        "/customer/api/matches/cancel",
        "/customer/api/matches/close"
})
public class GhepKeoServlet extends HttpServlet {

    private static final Gson GSON = new GsonBuilder()
            .registerTypeAdapter(LocalDate.class, (JsonSerializer<LocalDate>) (s, t, c) -> new JsonPrimitive(s.toString()))
            .registerTypeAdapter(LocalTime.class, (JsonSerializer<LocalTime>) (s, t, c) -> new JsonPrimitive(s.toString().substring(0, 5)))
            .registerTypeAdapter(LocalDateTime.class, (JsonSerializer<LocalDateTime>) (s, t, c) -> new JsonPrimitive(s.toString()))
            .registerTypeAdapter(BigDecimal.class, (JsonSerializer<BigDecimal>) (s, t, c) -> new JsonPrimitive(s.toPlainString()))
            .create();

    private final CoSoDAO coSoDAO = new CoSoDAOImpl();
    private final SanDAO sanDAO = new SanDAOImpl();
    private final LoaiSanDAO loaiSanDAO = new LoaiSanDAOImpl();
    private final LichDatSanDAO lichDatSanDAO = new LichDatSanDAOImpl();
    private final GhepKeoDAO ghepKeoDAO = new GhepKeoDAOImpl();
    private final GhepKeoService service = new GhepKeoService(ghepKeoDAO, lichDatSanDAO);

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();
        switch (path) {
            case "/customer/api/matches":              handleListOpen(req, resp);        return;
            case "/customer/api/matches/detail":       handleDetail(req, resp);          return;
            case "/customer/api/matches/mine":         handleMine(req, resp);            return;
            case "/customer/api/matches/my-bookings":  handleMyBookings(req, resp);      return;
            case "/customer/ghep-keo":                  handlePage(req, resp);            return;
            default:
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String path = req.getServletPath();
        switch (path) {
            case "/customer/ghep-keo":                  handleCreateForm(req, resp);      return;
            case "/customer/api/matches/join":          handleJoin(req, resp);            return;
            case "/customer/api/matches/approve":       handleApprove(req, resp);         return;
            case "/customer/api/matches/reject":        handleReject(req, resp);          return;
            case "/customer/api/matches/leave":         handleLeave(req, resp);           return;
            case "/customer/api/matches/cancel":        handleCancel(req, resp);          return;
            case "/customer/api/matches/close":         handleClose(req, resp);           return;
            default:
                resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        }
    }

    // ==========================================================================
    // GET /customer/ghep-keo → render JSP
    // ==========================================================================
    private void handlePage(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan user = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }
        if (user.getRoleId() != RoleRedirectUtil.ROLE_CUSTOMER) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Trang này chỉ dành cho tài khoản Khách hàng.");
            return;
        }

        String tab = req.getParameter("tab");
        // Chuẩn hoá tab: "tao-keo" | "kham-pha" | "cua-toi"
        if (tab == null) tab = "kham-pha";
        if (!tab.equals("tao-keo") && !tab.equals("kham-pha") && !tab.equals("cua-toi")) tab = "kham-pha";

        Integer coSoId = parseIntSafe(req.getParameter("coSoId"));

        req.setAttribute("initialTab", tab);
        req.setAttribute("coSoIdParam", coSoId);
        req.setAttribute("sanIdParam", parseIntSafe(req.getParameter("sanId")));
        req.setAttribute("dsCoSo", coSoDAO.getAllCoSo());
        req.setAttribute("dsMon", loaiSanDAO.getAllMonTheThao());
        req.getRequestDispatcher("/customer/GhepKeo.jsp").forward(req, resp);
    }

    // ==========================================================================
    // POST /customer/ghep-keo → create match (form)
    // ==========================================================================
    private void handleCreateForm(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession();
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");
        if (user == null) { resp.sendRedirect(req.getContextPath() + "/dangnhap"); return; }

        boolean isJson = wantsJson(req);
        GhepKeoService.CreateRequest cr = new GhepKeoService.CreateRequest();
        cr.accountId = user.getAccountId();
        cr.datSanId = parseIntOr(req.getParameter("datSanId"), 0);
        cr.monTheThaoId = parseIntSafe(req.getParameter("monTheThaoId"));
        cr.soNguoiCanTim = parseIntOr(req.getParameter("soNguoiCanTim"), 1);
        cr.trinhDo = req.getParameter("trinhDo");
        cr.hinhThucDuyet = req.getParameter("hinhThucDuyet");
        cr.note = req.getParameter("note");
        if (cr.note != null && cr.note.length() > 240) cr.note = cr.note.substring(0, 240);

        GhepKeoService.Result result = service.createMatch(cr);
        if (isJson) {
            writeResult(resp, result);
        } else if (result.success) {
            session.setAttribute("message", result.message);
            resp.sendRedirect(req.getContextPath() + "/customer/ghep-keo?tab=cua-toi&highlight=" + result.keoId);
        } else {
            session.setAttribute("error", result.message);
            resp.sendRedirect(req.getContextPath() + "/customer/ghep-keo?tab=tao-keo");
        }
    }

    // ==========================================================================
    // JSON: list open matches (Discover)
    // ==========================================================================
    private void handleListOpen(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Integer coSoId = parseIntSafe(req.getParameter("coSoId"));
        Integer sportId = parseIntSafe(req.getParameter("monTheThaoId"));
        LocalDate from = parseDateSafe(req.getParameter("from"), null);
        LocalDate to = parseDateSafe(req.getParameter("to"), null);

        List<GhepKeoDAO.GhepKeoView> list = ghepKeoDAO.listOpenMatches(coSoId, sportId, from, to);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("success", true);
        data.put("count", list.size());
        data.put("matches", list);
        writeJson(resp, HttpServletResponse.SC_OK, data);
    }

    private void handleDetail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Integer keoId = parseIntSafe(req.getParameter("keoId"));
        if (keoId == null) { writeJson(resp, 400, Map.of("success", false, "error", "Thiếu keoId.")); return; }
        GhepKeoDAO.GhepKeoView view = ghepKeoDAO.getViewById(keoId);
        if (view == null) { writeJson(resp, 404, Map.of("success", false, "error", "Kèo không tồn tại.")); return; }
        List<GhepKeoDAO.ChiTietGhepKeoView> participants = ghepKeoDAO.listParticipants(keoId);
        HttpSession session = req.getSession(false);
        TaiKhoan user = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        GhepKeoDAO.ChiTietGhepKeoView me = null;
        boolean isOwner = false;
        if (user != null) {
            me = ghepKeoDAO.getActiveParticipant(keoId, user.getAccountId());
            isOwner = (view.accountIdNguoiTao == user.getAccountId());
        }
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("success", true);
        data.put("match", view);
        data.put("participants", participants);
        data.put("me", me);
        data.put("isOwner", isOwner);
        data.put("isLoggedIn", user != null);
        writeJson(resp, 200, data);
    }

    // ==========================================================================
    // JSON: my matches (created + joined)
    // ==========================================================================
    private void handleMine(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan user = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        if (user == null) { writeJson(resp, 401, Map.of("success", false, "error", "Vui lòng đăng nhập.")); return; }

        List<GhepKeoDAO.GhepKeoView> created = ghepKeoDAO.listByCreator(user.getAccountId());
        List<GhepKeoDAO.GhepKeoView> joined = ghepKeoDAO.listByParticipant(user.getAccountId());
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("success", true);
        data.put("created", created);
        data.put("joined", joined);
        writeJson(resp, 200, data);
    }

    // ==========================================================================
    // JSON: my bookings — dropdown khi tạo kèo
    // ==========================================================================
    private void handleMyBookings(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan user = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        if (user == null) { writeJson(resp, 401, Map.of("success", false, "error", "Vui lòng đăng nhập.")); return; }
        List<Lichdatsan> raw = lichDatSanDAO.getLichByAccountId(user.getAccountId());
        List<Map<String, Object>> list = new ArrayList<>();
        LocalDate today = LocalDate.now();
        for (Lichdatsan l : raw) {
            if (l.getNgayDat() == null || l.getNgayDat().isBefore(today)) continue;
            String tt = l.getTrangThai();
            if (!"Chờ xác nhận".equals(tt) && !"Đã xác nhận".equals(tt) && !"Chờ thanh toán".equals(tt)) continue;
            org.example.model.San san = sanDAO.getSanById(l.getSanId());
            org.example.model.CoSo cs = san != null ? coSoDAO.getCoSoById(san.getCoSoID()) : null;
            org.example.model.LoaiSan ls = san != null ? loaiSanDAO.getLoaiSanById(san.getLoaiSanID()) : null;
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("datSanId", l.getDatSanId());
            item.put("ngayDat", l.getNgayDat());
            item.put("gioBatDau", l.getGioBatDau());
            item.put("gioKetThuc", l.getGioKetThuc());
            item.put("trangThai", tt);
            item.put("tongTienDuKien", l.getTongTienDuKien());
            item.put("sanId", san != null ? san.getSanID() : null);
            item.put("tenSan", san != null ? san.getTenSan() : ("Sân #" + l.getSanId()));
            item.put("coSoId", cs != null ? cs.getCoSoID() : null);
            item.put("tenCoSo", cs != null ? cs.getTenCoSo() : "");
            item.put("monTheThaoId", ls != null ? ls.getMonTheThaoID() : null);
            item.put("tenLoaiSan", ls != null ? ls.getTenLoai() : "");
            list.add(item);
        }
        writeJson(resp, 200, Map.of("success", true, "count", list.size(), "bookings", list));
    }

    // ==========================================================================
    // JSON action handlers
    // ==========================================================================
    private void handleJoin(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomer(req, resp); if (user == null) return;
        Integer keoId = parseIntSafe(req.getParameter("keoId"));
        if (keoId == null) { writeJson(resp, 400, Map.of("success", false, "error", "Thiếu keoId.")); return; }
        GhepKeoService.Result r = service.joinMatch(keoId, user.getAccountId());
        writeResult(resp, r);
    }

    private void handleApprove(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomer(req, resp); if (user == null) return;
        Integer cid = parseIntSafe(req.getParameter("chiTietKeoId"));
        if (cid == null) { writeJson(resp, 400, Map.of("success", false, "error", "Thiếu chiTietKeoId.")); return; }
        writeResult(resp, service.approveParticipant(cid, user.getAccountId()));
    }

    private void handleReject(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomer(req, resp); if (user == null) return;
        Integer cid = parseIntSafe(req.getParameter("chiTietKeoId"));
        if (cid == null) { writeJson(resp, 400, Map.of("success", false, "error", "Thiếu chiTietKeoId.")); return; }
        writeResult(resp, service.rejectParticipant(cid, user.getAccountId()));
    }

    private void handleLeave(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomer(req, resp); if (user == null) return;
        Integer cid = parseIntSafe(req.getParameter("chiTietKeoId"));
        if (cid == null) { writeJson(resp, 400, Map.of("success", false, "error", "Thiếu chiTietKeoId.")); return; }
        writeResult(resp, service.leaveMatch(cid, user.getAccountId()));
    }

    private void handleCancel(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomer(req, resp); if (user == null) return;
        Integer keoId = parseIntSafe(req.getParameter("keoId"));
        if (keoId == null) { writeJson(resp, 400, Map.of("success", false, "error", "Thiếu keoId.")); return; }
        writeResult(resp, service.cancelMatch(keoId, user.getAccountId()));
    }

    private void handleClose(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomer(req, resp); if (user == null) return;
        Integer keoId = parseIntSafe(req.getParameter("keoId"));
        if (keoId == null) { writeJson(resp, 400, Map.of("success", false, "error", "Thiếu keoId.")); return; }
        writeResult(resp, service.closeMatch(keoId, user.getAccountId()));
    }

    // ==========================================================================
    // Helpers
    // ==========================================================================
    private TaiKhoan requireCustomer(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan user = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        if (user == null) { writeJson(resp, 401, Map.of("success", false, "error", "Vui lòng đăng nhập.")); return null; }
        if (user.getRoleId() != RoleRedirectUtil.ROLE_CUSTOMER) {
            writeJson(resp, 403, Map.of("success", false, "error", "Chỉ khách hàng mới thực hiện được thao tác này."));
            return null;
        }
        return user;
    }

    private void writeResult(HttpServletResponse resp, GhepKeoService.Result r) throws IOException {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("success", r.success);
        data.put("message", r.message);
        if (r.keoId != null) data.put("keoId", r.keoId);
        if (r.chiTietKeoId != null) data.put("chiTietKeoId", r.chiTietKeoId);
        writeJson(resp, r.success ? 200 : 400, data);
    }

    private void writeJson(HttpServletResponse resp, int status, Object payload) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json;charset=UTF-8");
        try (PrintWriter w = resp.getWriter()) { w.write(GSON.toJson(payload)); }
    }

    private static boolean wantsJson(HttpServletRequest req) {
        String accept = req.getHeader("Accept");
        String xhr = req.getHeader("X-Requested-With");
        return "XMLHttpRequest".equalsIgnoreCase(xhr) || (accept != null && accept.contains("application/json"));
    }

    private static Integer parseIntSafe(String s) {
        if (s == null || s.isBlank()) return null;
        try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return null; }
    }
    private static int parseIntOr(String s, int def) { Integer v = parseIntSafe(s); return v == null ? def : v; }
    private static LocalDate parseDateSafe(String s, LocalDate fallback) {
        if (s == null || s.isBlank()) return fallback;
        try { return LocalDate.parse(s.trim()); } catch (Exception e) { return fallback; }
    }
}
