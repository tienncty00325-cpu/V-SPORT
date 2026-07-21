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
import org.example.dao.PayOSConfigDAO;
import org.example.dao.impl.AdminTrashDAOImpl;
import org.example.dao.impl.CoSoDAOImpl;
import org.example.dao.impl.PayOSConfigDAOImpl;
import org.example.dto.payment.PayOSConfigState;
import org.example.model.CoSo;
import org.example.model.TaiKhoan;
import org.example.service.admin.FacilityTrashService;
import org.example.service.admin.OwnerApprovalService;
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
import java.util.HashMap;
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
    private final FacilityTrashService facilityTrashService = new FacilityTrashService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();

        if (path.equals("/admin/chi-nhanh")) {
            String action = req.getParameter("action");
            if ("duyet".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                TaiKhoan admin = (TaiKhoan) req.getSession().getAttribute("user");
                OwnerApprovalService.ApprovalResult result = ownerApprovalService.approve(id, admin.getAccountId());
                if (result.success) {
                    Map<String, Integer> sportCounts = buildSportCounts(
                            result.coSo.getLoaiHinhKinhDoanh(), result.coSo.getSoLuongSanDuKien());
                    syncCourtsForBranch(id, sportCounts);
                    if (result.account != null) {
                        sendApprovalEmail(result.account);
                    }
                    req.getSession().setAttribute("message", "Duyệt cơ sở thành công và tài khoản quản lý đã được kích hoạt!");
                } else {
                    req.getSession().setAttribute("error", result.errorMessage);
                }
                String from = req.getParameter("from");
                if ("nhan-su".equals(from)) {
                    resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                } else {
                    resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh");
                }
                return;
            } else if ("khong-duyet".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                TaiKhoan admin = (TaiKhoan) req.getSession().getAttribute("user");
                CoSo chiNhanhBeforeReject = chiNhanhDAO.getCoSoById(id);
                String coSoName = chiNhanhBeforeReject != null ? chiNhanhBeforeReject.getTenCoSo() : null;
                OwnerApprovalService.ApprovalResult result = ownerApprovalService.reject(id);
                if (result.success) {
                    adminTrashDAO.log("OwnerRequest", id, coSoName, "CoSo", "Chờ duyệt",
                            admin.getAccountId(), null);
                    req.getSession().setAttribute("message", "Đã từ chối duyệt cơ sở.");
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
                    resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh");
                }
                return;
            }

            List<CoSo> dsChiNhanh = chiNhanhDAO.getAllCoSo();
            Map<Integer, PayOSConfigState> payosStatusMap = payOSConfigDAO.findStatusForAllCoSo();
            req.setAttribute("dsChiNhanh", dsChiNhanh);
            req.setAttribute("payosStatusMap", payosStatusMap);
            req.getRequestDispatcher("/admin/QuanLyChiNhanh.jsp").forward(req, resp);
        } else if (path.equals("/admin/chi-nhanh/sua")) {
            int id = Integer.parseInt(req.getParameter("id"));
            CoSo chiNhanh = chiNhanhDAO.getCoSoById(id);

            int countBongDa = 0;
            int countCauLong = 0;
            int countTennis = 0;
            int countPickleball = 0;

            try (Connection conn = DBUtil.getConnection()) {
                if (conn != null) {
                    String sql = "SELECT m.TenMon, COUNT(s.SanID) " +
                            "FROM San s " +
                            "JOIN LoaiSan l ON s.LoaiSanID = l.LoaiSanID " +
                            "JOIN MonTheThao m ON l.MonTheThaoID = m.MonTheThaoID " +
                            "WHERE s.CoSoID = ? " +
                            "GROUP BY m.TenMon";
                    try (PreparedStatement ps = conn.prepareStatement(sql)) {
                        ps.setInt(1, id);
                        try (ResultSet rs = ps.executeQuery()) {
                            while (rs.next()) {
                                String tenMon = rs.getNString(1);
                                int count = rs.getInt(2);
                                if ("Bóng đá".equals(tenMon))
                                    countBongDa = count;
                                else if ("Cầu lông".equals(tenMon))
                                    countCauLong = count;
                                else if ("Tennis".equals(tenMon))
                                    countTennis = count;
                                else if ("Pickleball".equals(tenMon))
                                    countPickleball = count;
                            }
                        }
                    }
                }
            } catch (Exception e) {
                logger.error("Lỗi khi tải dữ liệu chi nhánh", e);
            }

            req.setAttribute("chiNhanh", chiNhanh);
            req.setAttribute("countBongDa", countBongDa);
            req.setAttribute("countCauLong", countCauLong);
            req.setAttribute("countTennis", countTennis);
            req.setAttribute("countPickleball", countPickleball);

            if ("json".equals(req.getParameter("format"))) {
                resp.setContentType("application/json;charset=UTF-8");
                PrintWriter out = resp.getWriter();
                try {
                    if (chiNhanh == null) {
                        out.print("{\"success\":false,\"error\":\"Chi nhánh không tồn tại với ID " + id + "\"}");
                        return;
                    }
                    String ten = chiNhanh.getTenCoSo() != null ? chiNhanh.getTenCoSo().replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r") : "";
                    String diaChi = chiNhanh.getDiaChi() != null ? chiNhanh.getDiaChi().replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r") : "";
                    String sdt = chiNhanh.getSoDienThoai() != null ? chiNhanh.getSoDienThoai().replace("\"", "\\\"") : "";
                    String trangThai = chiNhanh.getTrangThai() != null ? chiNhanh.getTrangThai().replace("\"", "\\\"") : "";
                    String gioMo = chiNhanh.getGioMoCua() != null ? chiNhanh.getGioMoCua().toString() : null;
                    String gioDong = chiNhanh.getGioDongCua() != null ? chiNhanh.getGioDongCua().toString() : null;
                    String viDo = chiNhanh.getViDo() != null ? chiNhanh.getViDo().toPlainString() : "";
                    String kinhDo = chiNhanh.getKinhDo() != null ? chiNhanh.getKinhDo().toPlainString() : "";

                    out.print("{"
                        + "\"success\":true,"
                        + "\"coSoID\":" + chiNhanh.getCoSoID() + ","
                        + "\"tenCoSo\":\"" + ten + "\","
                        + "\"diaChi\":\"" + diaChi + "\","
                        + "\"soDienThoai\":\"" + sdt + "\","
                        + "\"trangThai\":\"" + trangThai + "\","
                        + "\"gioMoCua\":" + (gioMo != null ? "\"" + gioMo + "\"" : "null") + ","
                        + "\"gioDongCua\":" + (gioDong != null ? "\"" + gioDong + "\"" : "null") + ","
                        + "\"soLuongSanDuKien\":" + chiNhanh.getSoLuongSanDuKien() + ","
                        + "\"viDo\":\"" + viDo + "\","
                        + "\"kinhDo\":\"" + kinhDo + "\","
                        + "\"countBongDa\":" + countBongDa + ","
                        + "\"countCauLong\":" + countCauLong + ","
                        + "\"countTennis\":" + countTennis + ","
                        + "\"countPickleball\":" + countPickleball
                        + "}");
                } catch (Exception ex) {
                    logger.error("Error generating JSON for branch", ex);
                    out.print("{\"success\":false,\"error\":\"" + (ex.getMessage() != null ? ex.getMessage().replace("\"", "\\\"") : "NullPointerException") + "\"}");
                }
                return;
            }

            req.getRequestDispatcher("/admin/SuaChiNhanh.jsp").forward(req, resp);
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
            int id = Integer.parseInt(req.getParameter("id"));

            // Nạp bản ghi hiện có rồi chỉnh sửa tại chỗ — KHÔNG merge() một entity rỗng
            // mới tạo, vì merge() sẽ ghi đè mọi field không được set (bao gồm ViDo/KinhDo,
            // AccountID_QuanLy, HinhAnh, IsDeleted...) thành NULL trên bản ghi DB.
            CoSo chiNhanh = chiNhanhDAO.getCoSoById(id);
            if (chiNhanh == null) {
                req.getSession().setAttribute("error", "Chi nhánh không tồn tại.");
                resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh");
                return;
            }
            chiNhanh.setTenCoSo(tenCoSo);
            chiNhanh.setDiaChi(diaChi);
            chiNhanh.setSoDienThoai(soDienThoai);
            chiNhanh.setTrangThai(trangThai);
            // Chỉ ghi đè giờ hoạt động khi form thực sự gửi giá trị — không tự gán
            // mặc định 8:00/22:00 (đó chỉ dùng cho "Thêm Cơ Sở"). Nếu form để trống,
            // giữ nguyên giá trị đã nạp từ DB ở trên (kể cả khi giá trị đó là NULL).
            if (gioMoStr != null && !gioMoStr.isEmpty()) {
                chiNhanh.setGioMoCua(LocalTime.parse(gioMoStr));
            }
            if (gioDongStr != null && !gioDongStr.isEmpty()) {
                chiNhanh.setGioDongCua(LocalTime.parse(gioDongStr));
            }
            chiNhanh.setMoTa(moTa);
            // Môn thể thao / số sân KHÔNG được chỉnh ở form sửa cơ sở (Admin) — thuộc
            // quyền Quản lý cơ sở tại trang "Quản lý Sân". Không gọi setLoaiHinhKinhDoanh/
            // setSoLuongSanDuKien/syncCourtsForBranch ở đây để tránh xóa nhầm sân/lịch đặt.
            // Chỉ cập nhật vị trí khi form gửi tọa độ mới; nếu không đổi vị trí thì
            // giữ nguyên ViDo/KinhDo cũ đã nạp từ DB ở trên.
            if (viDo != null && kinhDo != null) {
                chiNhanh.setViDo(viDo);
                chiNhanh.setKinhDo(kinhDo);
            }

            chiNhanhDAO.updateCoSo(chiNhanh);
            if (user != null) {
                AuditLogService.log(req, user,
                    AuditLogService.ACTION_UPDATE, AuditLogService.ENTITY_CO_SO,
                    String.valueOf(chiNhanh.getCoSoID()), chiNhanh.getTenCoSo(),
                    "Admin cập nhật thông tin chi nhánh");
            }
        }

        resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh");
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
