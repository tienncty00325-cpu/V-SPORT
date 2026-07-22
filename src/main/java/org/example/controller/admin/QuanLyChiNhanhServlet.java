package org.example.controller.admin;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.service.AuditLogService;
import org.example.dao.AdminTrashDAO;
import org.example.dao.CoSoDAO;
import org.example.dao.CoSoCapabilityDAO;
import org.example.dao.PayOSConfigDAO;
import org.example.dao.impl.AdminTrashDAOImpl;
import org.example.dao.impl.CoSoCapabilityDAOImpl;
import org.example.dao.impl.CoSoDAOImpl;
import org.example.dao.impl.PayOSConfigDAOImpl;
import org.example.dao.impl.TaiKhoanDAOImpl;
import org.example.dto.payment.PayOSConfigState;
import org.example.model.CoSo;
import org.example.model.CoSoCapability;
import org.example.model.TaiKhoan;
import org.example.service.admin.CapabilityApprovalService;
import org.example.service.admin.FacilityTrashService;
import org.example.service.admin.OwnerApprovalService;
import org.example.util.Constants;
import org.example.util.DBUtil;
import org.example.util.EmailUtil;
import org.example.util.SessionUtil;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@WebServlet(urlPatterns = { "/admin/chi-nhanh", "/admin/chi-nhanh/them", "/admin/chi-nhanh/sua",
        "/admin/chi-nhanh/xoa" })
public class QuanLyChiNhanhServlet extends HttpServlet {

    private static final Logger logger = LogManager.getLogger(QuanLyChiNhanhServlet.class);
    private CoSoDAO chiNhanhDAO = new CoSoDAOImpl();
    private final PayOSConfigDAO payOSConfigDAO = new PayOSConfigDAOImpl();
    private final AdminTrashDAO adminTrashDAO = new AdminTrashDAOImpl();
    private final OwnerApprovalService ownerApprovalService = new OwnerApprovalService();
    private final CapabilityApprovalService capabilityApprovalService = new CapabilityApprovalService();
    private final CoSoCapabilityDAO capabilityDAO = new CoSoCapabilityDAOImpl();
    private final TaiKhoanDAOImpl taiKhoanDAO = new TaiKhoanDAOImpl();
    private final FacilityTrashService facilityTrashService = new FacilityTrashService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();

        if (path.equals("/admin/chi-nhanh")) {
            String action = req.getParameter("action");

            if ("duyet".equals(action)) { handleApprove(req, resp); return; }
            if ("khong-duyet".equals(action) || "tu-choi".equals(action)) { handleReject(req, resp); return; }

            loadMainPage(req, resp);
        } else if (path.equals("/admin/chi-nhanh/sua")) {
            // Admin không còn quyền chỉnh sửa cơ sở (chỉ Duyệt/Từ chối/Xóa).
            // Thông tin cơ sở do chính Owner/Quản lý cơ sở tự cập nhật.
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin không có quyền chỉnh sửa cơ sở.");
        } else if (path.equals("/admin/chi-nhanh/xoa")) {
            int id = Integer.parseInt(req.getParameter("id"));
            HttpSession session = req.getSession();
            Integer adminId = SessionUtil.getCurrentAccountId(session);

            if (adminId == null) {
                logger.error("Không xác định được AccountID của Admin trong session.");
                session.setAttribute("error", "Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.");
                resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh");
                return;
            }

            FacilityTrashService.Result result = facilityTrashService.softDeleteFacility(id, adminId);
            if (result.success) {
                session.setAttribute("trashMessage", "Đã chuyển vào thùng rác.");
                session.setAttribute("trashUrl", req.getContextPath() + "/admin/thung-rac");
                session.setAttribute("trashCountdownSeconds", 10);
                TaiKhoan admin = (TaiKhoan) session.getAttribute("user");
                if (admin != null) {
                    AuditLogService.log(req, admin, null,
                            AuditLogService.ACTION_SOFT_DELETE, AuditLogService.ENTITY_CO_SO,
                            String.valueOf(id), "CoSoID=" + id,
                            "Admin ngừng hoạt động cơ sở. Tài khoản thuộc cơ sở này sẽ không thể đăng nhập/thao tác cho đến khi được khôi phục.");
                }
            } else {
                session.setAttribute("error", result.message);
            }
            resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();

        if (path.equals("/admin/chi-nhanh")) {
            String action = req.getParameter("action");
            if ("duyet".equals(action)) { handleApprove(req, resp); return; }
            if ("khong-duyet".equals(action) || "tu-choi".equals(action)) { handleReject(req, resp); return; }
        }

        String tenCoSo = req.getParameter("tenCoSo");
        String diaChi = req.getParameter("diaChi");
        String soDienThoai = req.getParameter("soDienThoai");
        String trangThai = req.getParameter("trangThai");

        String gioMoStr = req.getParameter("gioMoCua");
        String gioDongStr = req.getParameter("gioDongCua");
        LocalTime gioMo = (gioMoStr != null && !gioMoStr.isEmpty()) ? LocalTime.parse(gioMoStr) : LocalTime.of(8, 0);
        LocalTime gioDong = (gioDongStr != null && !gioDongStr.isEmpty()) ? LocalTime.parse(gioDongStr)
                : LocalTime.of(22, 0);

        String moTa = req.getParameter("moTa");

        // Vị trí (ViDo/KinhDo): parse an toàn, validate range, và bắt buộc phải có
        // đủ cả cặp — không chấp nhận chỉ có một trong hai (tránh lưu vị trí sai lệch).
        String viDoRaw = req.getParameter("viDo");
        String kinhDoRaw = req.getParameter("kinhDo");
        java.math.BigDecimal viDo = null;
        java.math.BigDecimal kinhDo = null;
        boolean viDoInvalid = false;
        boolean kinhDoInvalid = false;
        if (viDoRaw != null && !viDoRaw.trim().isEmpty()) {
            try { viDo = new java.math.BigDecimal(viDoRaw.trim()); } catch (NumberFormatException e) { viDoInvalid = true; }
        }
        if (kinhDoRaw != null && !kinhDoRaw.trim().isEmpty()) {
            try { kinhDo = new java.math.BigDecimal(kinhDoRaw.trim()); } catch (NumberFormatException e) { kinhDoInvalid = true; }
        }
        if (viDoInvalid || kinhDoInvalid || (viDo == null) != (kinhDo == null)
                || (viDo != null && (viDo.compareTo(java.math.BigDecimal.valueOf(-90)) < 0 || viDo.compareTo(java.math.BigDecimal.valueOf(90)) > 0))
                || (kinhDo != null && (kinhDo.compareTo(java.math.BigDecimal.valueOf(-180)) < 0 || kinhDo.compareTo(java.math.BigDecimal.valueOf(180)) > 0))) {
            req.getSession().setAttribute("error",
                    "Vị trí cơ sở chưa hợp lệ. Vui lòng chọn lại vị trí trên bản đồ hoặc nhập đầy đủ tọa độ.");
            resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh");
            return;
        }

        // Xử lý nhiều môn thể thao từ checkbox
        String[] loaiHinhArray = req.getParameterValues("loaiHinhKinhDoanh");
        String loaiHinh = (loaiHinhArray != null) ? String.join(", ", loaiHinhArray) : "";

        Map<String, Integer> sportCounts = new HashMap<>();
        int totalCourts = 0;
        if (loaiHinhArray != null) {
            for (String sport : loaiHinhArray) {
                String paramName = "";
                if ("Bóng đá".equals(sport))
                    paramName = "soLuongSan_BongDa";
                else if ("Cầu lông".equals(sport))
                    paramName = "soLuongSan_CauLong";
                else if ("Tennis".equals(sport))
                    paramName = "soLuongSan_Tennis";
                else if ("Pickleball".equals(sport))
                    paramName = "soLuongSan_Pickleball";

                String valStr = req.getParameter(paramName);
                int count = (valStr != null && !valStr.isEmpty()) ? Integer.parseInt(valStr) : 1;
                sportCounts.put(sport, count);
                totalCourts += count;
            }
        }

        TaiKhoan user = (TaiKhoan) req.getSession().getAttribute("user");

        if (path.equals("/admin/chi-nhanh/them")) {
            CoSo chiNhanh = new CoSo();
            chiNhanh.setTenCoSo(tenCoSo);
            chiNhanh.setDiaChi(diaChi);
            chiNhanh.setSoDienThoai(soDienThoai);
            chiNhanh.setTrangThai(trangThai);
            chiNhanh.setGioMoCua(gioMo);
            chiNhanh.setGioDongCua(gioDong);
            chiNhanh.setMoTa(moTa);
            chiNhanh.setLoaiHinhKinhDoanh(loaiHinh);
            chiNhanh.setSoLuongSanDuKien(totalCourts);
            chiNhanh.setViDo(viDo);
            chiNhanh.setKinhDo(kinhDo);

            chiNhanhDAO.addCoSo(chiNhanh);
            // Dynamic court synchronization for new branch
            syncCourtsForBranch(chiNhanh.getCoSoID(), sportCounts);
            if (user != null) {
                AuditLogService.log(req, user,
                    AuditLogService.ACTION_CREATE, AuditLogService.ENTITY_CO_SO,
                    String.valueOf(chiNhanh.getCoSoID()), chiNhanh.getTenCoSo(),
                    "Admin tạo chi nhánh mới");
            }
        } else if (path.equals("/admin/chi-nhanh/sua")) {
            // Admin không còn quyền chỉnh sửa cơ sở (chỉ Duyệt/Từ chối/Xóa).
            // Thông tin cơ sở do chính Owner/Quản lý cơ sở tự cập nhật.
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin không có quyền chỉnh sửa cơ sở.");
            return;
        }

        resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh");
    }

    // ── Duyệt yêu cầu đăng ký (từ tab Chờ duyệt) ──
    private void handleApprove(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan admin = (TaiKhoan) req.getSession().getAttribute("user");
        int id = parseIdSafe(req.getParameter("id"), -1);
        if (id < 0 || admin == null) { resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh?tab=pending"); return; }
        OwnerApprovalService.ApprovalResult result = ownerApprovalService.approve(id, admin.getAccountId());
        if (result.success) {
            Map<String, Integer> sportCounts = buildSportCounts(
                    result.coSo.getLoaiHinhKinhDoanh(), result.coSo.getSoLuongSanDuKien());
            syncCourtsForBranch(id, sportCounts);
            // Kích hoạt capability SAN tự động khi duyệt cơ sở
            capabilityApprovalService.activateCourtCapability(id, admin.getAccountId());
            if (result.account != null) {
                sendApprovalEmail(result.account);
            }
            AuditLogService.log(req, admin, id, AuditLogService.ACTION_APPROVE,
                    AuditLogService.ENTITY_CO_SO, String.valueOf(id),
                    result.coSo.getTenCoSo(), "Duyệt yêu cầu đăng ký cơ sở, kích hoạt tài khoản quản lý.");
            req.getSession().setAttribute("message", "Đã duyệt cơ sở \"" + result.coSo.getTenCoSo() + "\" và kích hoạt tài khoản quản lý!");
        } else {
            req.getSession().setAttribute("error", result.errorMessage);
        }
        String from = req.getParameter("from");
        if ("nhan-su".equals(from)) {
            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
        } else {
            resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh?tab=pending");
        }
    }

    // ── Từ chối yêu cầu đăng ký ──
    private void handleReject(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan admin = (TaiKhoan) req.getSession().getAttribute("user");
        int id = parseIdSafe(req.getParameter("id"), -1);
        if (id < 0 || admin == null) { resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh?tab=pending"); return; }
        CoSo chiNhanhBeforeReject = chiNhanhDAO.getCoSoById(id);
        String coSoName = chiNhanhBeforeReject != null ? chiNhanhBeforeReject.getTenCoSo() : "Không rõ";
        String reason = req.getParameter("reason");
        OwnerApprovalService.ApprovalResult result = ownerApprovalService.reject(id);
        if (result.success) {
            adminTrashDAO.log("OwnerRequest", id, coSoName, "CoSo", "Chờ duyệt",
                    admin.getAccountId(), null);
            AuditLogService.log(req, admin, id, AuditLogService.ACTION_REJECT,
                    AuditLogService.ENTITY_CO_SO, String.valueOf(id), coSoName,
                    "Từ chối yêu cầu đăng ký cơ sở." + (reason != null && !reason.isBlank() ? " Lý do: " + reason : ""));
            req.getSession().setAttribute("message", "Đã từ chối yêu cầu đăng ký cơ sở.");
            req.getSession().setAttribute("trashMessage", "Đã chuyển vào thùng rác.");
            req.getSession().setAttribute("trashUrl", req.getContextPath() + "/admin/thung-rac");
            req.getSession().setAttribute("trashCountdownSeconds", 10);
        } else {
            req.getSession().setAttribute("error", result.errorMessage);
        }
        String from = req.getParameter("from");
        if ("nhan-su".equals(from)) {
            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
        } else {
            resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh?tab=pending");
        }
    }

    private void syncCourtsForBranch(int coSoId, Map<String, Integer> sportCounts) {
        try (Connection conn = DBUtil.getConnection()) {
            if (conn == null)
                return;

            // 1. Get mapping of Sport Name -> LoaiSanID
            Map<String, Integer> sportToTypeMap = new HashMap<>();
            String queryTypesSql = "SELECT m.TenMon, l.LoaiSanID FROM LoaiSan l JOIN MonTheThao m ON l.MonTheThaoID = m.MonTheThaoID ORDER BY CASE WHEN l.CoSoID = ? THEN 1 ELSE 0 END ASC";
            try (PreparedStatement ps = conn.prepareStatement(queryTypesSql)) {
                ps.setInt(1, coSoId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        sportToTypeMap.put(rs.getNString("TenMon"), rs.getInt("LoaiSanID"));
                    }
                }
            }

            // Get fallback default type (first type available in database)
            int defaultType = 1;
            try (PreparedStatement ps = conn.prepareStatement("SELECT TOP 1 LoaiSanID FROM LoaiSan");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    defaultType = rs.getInt(1);
                }
            }

            // Loop over all possible sports
            String[] allSports = { "Bóng đá", "Cầu lông", "Tennis", "Pickleball" };
            for (String sport : allSports) {
                int expectedCount = sportCounts.getOrDefault(sport, 0);
                Integer typeId = sportToTypeMap.get(sport);
                if (typeId == null) {
                    typeId = defaultType;
                }

                // Get existing courts for this sport at this branch
                List<Integer> existingSanIds = new ArrayList<>();
                String querySanSql = "SELECT s.SanID FROM San s " +
                        "JOIN LoaiSan l ON s.LoaiSanID = l.LoaiSanID " +
                        "JOIN MonTheThao m ON l.MonTheThaoID = m.MonTheThaoID " +
                        "WHERE s.CoSoID = ? AND m.TenMon = ? " +
                        "ORDER BY s.SanID ASC";
                try (PreparedStatement ps = conn.prepareStatement(querySanSql)) {
                    ps.setInt(1, coSoId);
                    ps.setNString(2, sport);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            existingSanIds.add(rs.getInt(1));
                        }
                    }
                }

                int currentCount = existingSanIds.size();

                if (currentCount < expectedCount) {
                    // Insert missing courts
                    int toAdd = expectedCount - currentCount;
                    String insertSql = "INSERT INTO San (TenSan, LoaiSanID, CoSoID, TrangThai, MoTa, HinhAnh) VALUES (?, ?, ?, ?, ?, ?)";
                    try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                        for (int i = 0; i < toAdd; i++) {
                            int courtIndex = currentCount + i + 1;
                            String courtName = sport + " " + (courtIndex < 10 ? "0" + courtIndex : courtIndex); // E.g.,
                                                                                                                // "Bóng
                                                                                                                // đá
                                                                                                                // 01"
                            ps.setNString(1, courtName);
                            ps.setInt(2, typeId);
                            ps.setInt(3, coSoId);
                            ps.setNString(4, "Sẵn sàng");
                            ps.setNString(5, "Sân thi đấu tự động tạo cho Cơ Sở.");
                            ps.setNString(6, "");
                            ps.addBatch();
                        }
                        ps.executeBatch();
                    }
                } else if (currentCount > expectedCount) {
                    // Delete excess courts
                    int toDelete = currentCount - expectedCount;
                    String deleteSql = "DELETE FROM San WHERE SanID = ?";
                    try (PreparedStatement ps = conn.prepareStatement(deleteSql)) {
                        for (int i = 0; i < toDelete; i++) {
                            int sanIdToDelete = existingSanIds.get(existingSanIds.size() - 1 - i);

                            // Delete bookings
                            try (PreparedStatement psDelBook = conn
                                    .prepareStatement("DELETE FROM LichDatSan WHERE SanID = ?")) {
                                psDelBook.setInt(1, sanIdToDelete);
                                psDelBook.executeUpdate();
                            }

                            ps.setInt(1, sanIdToDelete);
                            ps.addBatch();
                        }
                        ps.executeBatch();
                    }
                }
            }
        } catch (Exception e) {
            logger.error("Lỗi khi xử lý thao tác chi nhánh", e);
        }
    }

    private void deleteCourtsForBranch(int coSoId) {
        try (Connection conn = DBUtil.getConnection()) {
            if (conn == null)
                return;

            // Delete associated bookings
            String delBookSql = "DELETE FROM LichDatSan WHERE SanID IN (SELECT SanID FROM San WHERE CoSoID = ?)";
            try (PreparedStatement ps = conn.prepareStatement(delBookSql)) {
                ps.setInt(1, coSoId);
                ps.executeUpdate();
            }

            // Delete courts
            String delSanSql = "DELETE FROM San WHERE CoSoID = ?";
            try (PreparedStatement ps = conn.prepareStatement(delSanSql)) {
                ps.setInt(1, coSoId);
                ps.executeUpdate();
            }
        } catch (Exception e) {
            logger.error("Lỗi khi xóa sân cho cơ sở ID " + coSoId, e);
        }
    }

    private Map<String, Integer> buildSportCounts(String loaiHinh, int total) {
        Map<String, Integer> sportCounts = new HashMap<>();
        if (loaiHinh != null && !loaiHinh.trim().isEmpty() && total > 0) {
            String[] sports = loaiHinh.split(",");
            for (int i = 0; i < sports.length; i++) {
                sports[i] = sports[i].trim();
            }
            int base = total / sports.length;
            int remainder = total % sports.length;
            for (int i = 0; i < sports.length; i++) {
                sportCounts.put(sports[i], base + (i < remainder ? 1 : 0));
            }
        }
        return sportCounts;
    }

    // ── Load main page: load all facility data including pending/rejected ──
    private void loadMainPage(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            List<CoSo> dsChiNhanh = chiNhanhDAO.getAllCoSo();
            Map<Integer, PayOSConfigState> payosStatusMap = payOSConfigDAO.findStatusForAllCoSo();
            req.setAttribute("dsChiNhanh", dsChiNhanh != null ? dsChiNhanh : new ArrayList<>());
            req.setAttribute("payosStatusMap", payosStatusMap);

            // Load pending and rejected registrations (từ Owner tự đăng ký)
            List<CoSo> allCoSo = chiNhanhDAO.getAllCoSoIncludingPending();
            List<TaiKhoan> allAccounts = taiKhoanDAO.getAllAccounts();
            Map<Integer, TaiKhoan> accountMap = new HashMap<>();
            if (allAccounts != null) {
                for (TaiKhoan tk : allAccounts) accountMap.put(tk.getAccountId(), tk);
            }

            List<Map<String, Object>> pendingRequests  = new ArrayList<>();
            List<Map<String, Object>> rejectedRequests = new ArrayList<>();

            for (CoSo cs : allCoSo) {
                if (cs.getAccountID_QuanLy() == null) continue;
                TaiKhoan mgr = accountMap.get(cs.getAccountID_QuanLy());
                if (mgr == null) continue;
                String trangThai = cs.getTrangThai();
                if (!"Chờ duyệt".equals(trangThai) && !"Từ chối".equals(trangThai)) continue;

                Map<String, Object> row = new HashMap<>();
                row.put("coSo", cs);
                row.put("manager", mgr);
                row.put("capabilities", capabilityDAO.findByCoSoId(cs.getCoSoID()));
                if ("Chờ duyệt".equals(trangThai)) pendingRequests.add(row);
                else rejectedRequests.add(row);
            }

            req.setAttribute("pendingRequests", pendingRequests);
            req.setAttribute("rejectedRequests", rejectedRequests);
            req.setAttribute("pendingCount", pendingRequests.size());
            req.getSession().setAttribute("adminPendingCount", pendingRequests.size());
        } catch (Exception e) {
            logger.error("Lỗi loadMainPage: {}", e.getMessage(), e);
            req.setAttribute("pendingRequests", new ArrayList<>());
            req.setAttribute("rejectedRequests", new ArrayList<>());
            req.setAttribute("pendingCount", 0);
        }
        req.getRequestDispatcher("/admin/QuanLyChiNhanh.jsp").forward(req, resp);
    }

    private int parseIdSafe(String s, int defaultVal) {
        try { return Integer.parseInt(s); } catch (Exception e) { return defaultVal; }
    }

    private void sendApprovalEmail(TaiKhoan account) {
        new Thread(() -> {
            try {
                EmailUtil.sendEmail(
                    account.getEmail(),
                    "Tài khoản đối tác V-SPORT đã được phê duyệt",
                    "Chào " + account.getFullName() + ",\n\n" +
                    "Cơ sở thể thao của bạn đã được quản trị viên phê duyệt thành công.\n" +
                    "Bạn hiện có thể đăng nhập vào hệ thống quản lý V-SPORT bằng tài khoản sau:\n" +
                    "- Tên đăng nhập (Email): " + account.getEmail() + "\n" +
                    "- Mật khẩu mặc định: 123456\n\n" +
                    "Vui lòng đổi mật khẩu sau khi đăng nhập lần đầu tiên để bảo mật tài khoản.\n\n" +
                    "Trân trọng,\nBan quản trị V-SPORT"
                );
            } catch (Exception e) {
                logger.error("Lỗi gửi email phê duyệt đến {}", account.getEmail(), e);
            }
        }).start();
    }
}
