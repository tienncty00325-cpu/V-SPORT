package org.example.controller.admin;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.dao.AdminTrashDAO;
import org.example.dao.CoSoCapabilityDAO;
import org.example.dao.impl.AdminTrashDAOImpl;
import org.example.dao.impl.CoSoCapabilityDAOImpl;
import org.example.dao.impl.CoSoDAOImpl;
import org.example.dao.impl.TaiKhoanDAOImpl;
import org.example.model.CoSo;
import org.example.model.CoSoCapability;
import org.example.model.TaiKhoan;
import org.example.service.AuditLogService;
import org.example.service.admin.CapabilityApprovalService;
import org.example.service.admin.OwnerApprovalService;
import org.example.util.Constants;
import org.example.util.DBUtil;
import org.example.util.EmailUtil;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.*;

@WebServlet("/admin/quan-ly-owner")
public class AdminOwnerServlet extends HttpServlet {

    private static final Logger logger = LogManager.getLogger(AdminOwnerServlet.class);
    private final CoSoDAOImpl coSoDAO = new CoSoDAOImpl();
    private final TaiKhoanDAOImpl taiKhoanDAO = new TaiKhoanDAOImpl();
    private final AdminTrashDAO adminTrashDAO = new AdminTrashDAOImpl();
    private final OwnerApprovalService ownerApprovalService = new OwnerApprovalService();
    private final CapabilityApprovalService capabilityApprovalService = new CapabilityApprovalService();
    private final CoSoCapabilityDAO capabilityDAO = new CoSoCapabilityDAOImpl();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan admin = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        if (admin == null || admin.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        String action = req.getParameter("action");
        // Redirect capability actions to new unified endpoint
        if (CAPABILITY_ACTIONS.contains(action)) {
            handleCapabilityAction(req, resp, action, admin);
            return;
        }
        if (action != null) {
            handleAction(req, resp, action, admin);
            return;
        }

        // Route cũ đã được tích hợp vào /admin/chi-nhanh — chuyển hướng tự động
        resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh?tab=pending");
    }

    private static final Set<String> CAPABILITY_ACTIONS = Set.of(
            "duyet-capability", "tu-choi-capability", "tam-ngung-capability", "kich-hoat-capability");

    /**
     * Duyệt/từ chối/tạm ngưng/kích hoạt lại MỘT capability cụ thể - tách biệt hoàn
     * toàn khỏi việc duyệt/từ chối cơ sở (handleAction/"duyet"/"tu-choi" ở trên).
     * Không được để lẫn hai luồng: từ chối một capability KHÔNG được đụng tới
     * CoSo.TrangThai, và ngược lại.
     */
    private void handleCapabilityAction(HttpServletRequest req, HttpServletResponse resp, String action, TaiKhoan admin) throws IOException {
        int capabilityId;
        try {
            capabilityId = Integer.parseInt(req.getParameter("capabilityId"));
        } catch (Exception e) {
            req.getSession().setAttribute("error", "ID capability không hợp lệ.");
            resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh?tab=pending");
            return;
        }
        String reason = req.getParameter("reason");
        String note = req.getParameter("note");

        CoSoCapability before = capabilityDAO.findById(capabilityId);
        if (before == null) {
            req.getSession().setAttribute("error", "Không tìm thấy yêu cầu capability.");
            resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh?tab=pending");
            return;
        }
        String beforeStatus = before.getTrangThai();
        String typeLabel = Constants.capabilityLabel(before.getCapabilityType());

        CapabilityApprovalService.Result result;
        String auditAction;
        switch (action) {
            case "duyet-capability":
                result = capabilityApprovalService.approve(capabilityId, admin.getAccountId(), note);
                auditAction = AuditLogService.ACTION_APPROVE;
                break;
            case "tu-choi-capability":
                result = capabilityApprovalService.reject(capabilityId, admin.getAccountId(), reason);
                auditAction = AuditLogService.ACTION_REJECT;
                break;
            case "tam-ngung-capability":
                result = capabilityApprovalService.suspend(capabilityId, admin.getAccountId(), reason);
                auditAction = AuditLogService.ACTION_SUSPEND;
                break;
            case "kich-hoat-capability":
                result = capabilityApprovalService.approve(capabilityId, admin.getAccountId(), note);
                auditAction = AuditLogService.ACTION_APPROVE;
                break;
            default:
                req.getSession().setAttribute("error", "Hành động không hợp lệ.");
                resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh?tab=pending");
                return;
        }

        if (result.success) {
            AuditLogService.log(req, admin, before.getCoSoId(), auditAction, AuditLogService.ENTITY_CAPABILITY,
                    String.valueOf(capabilityId), typeLabel,
                    "Trạng thái: " + Constants.capabilityStatusLabel(beforeStatus) + " -> " +
                            Constants.capabilityStatusLabel(result.capability.getTrangThai()) +
                            (reason != null && !reason.isBlank() ? " | Lý do: " + reason : "") +
                            (note != null && !note.isBlank() ? " | Ghi chú: " + note : ""));
            req.getSession().setAttribute("message", "Đã cập nhật capability \"" + typeLabel + "\".");
        } else {
            req.getSession().setAttribute("error", result.errorMessage);
        }
        resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh?tab=pending");
    }

    private void handleAction(HttpServletRequest req, HttpServletResponse resp, String action, TaiKhoan admin) throws IOException {
        int coSoId = 0;
        try { coSoId = Integer.parseInt(req.getParameter("id")); } catch (Exception e) {
            req.getSession().setAttribute("error", "ID không hợp lệ.");
            resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh?tab=pending");
            return;
        }

        CoSo coSo = coSoDAO.getCoSoById(coSoId);
        if (coSo == null) {
            req.getSession().setAttribute("error", "Không tìm thấy cơ sở.");
            resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh?tab=pending");
            return;
        }

        switch (action) {
            case "duyet": {
                OwnerApprovalService.ApprovalResult result = ownerApprovalService.approve(coSoId, admin.getAccountId());
                if (result.success) {
                    syncCourts(coSoId, result.coSo.getLoaiHinhKinhDoanh(), result.coSo.getSoLuongSanDuKien());
                    // Cho thuê sân là chức năng nền tảng của mọi cơ sở đã duyệt - kích hoạt
                    // capability SAN ngay, KHÔNG chờ Owner đăng ký riêng (khác với các
                    // capability tùy chọn như bán sản phẩm, vốn vẫn giữ nguyên PENDING).
                    capabilityApprovalService.activateCourtCapability(coSoId, admin.getAccountId());
                    if (result.account != null) {
                        sendApprovalEmail(result.account);
                    }
                    AuditLogService.log(req, admin, coSoId, AuditLogService.ACTION_APPROVE,
                            AuditLogService.ENTITY_CO_SO, String.valueOf(coSoId), result.coSo.getTenCoSo(),
                            "Duyệt yêu cầu đăng ký cơ sở, kích hoạt tài khoản quản lý.");
                    req.getSession().setAttribute("message",
                            "Đã duyệt cơ sở \"" + result.coSo.getTenCoSo() + "\" và kích hoạt tài khoản quản lý.");
                } else {
                    req.getSession().setAttribute("error", result.errorMessage);
                }
                break;
            }

            case "tu-choi": {
                String coSoName = coSo.getTenCoSo();
                OwnerApprovalService.ApprovalResult result = ownerApprovalService.reject(coSoId);
                if (result.success) {
                    adminTrashDAO.log("OwnerRequest", coSoId, coSoName, "CoSo", "Chờ duyệt",
                            admin.getAccountId(), null);
                    if (result.account != null) {
                        sendRejectionEmail(result.account, coSoName);
                    }
                    AuditLogService.log(req, admin, coSoId, AuditLogService.ACTION_REJECT,
                            AuditLogService.ENTITY_CO_SO, String.valueOf(coSoId), coSoName,
                            "Từ chối yêu cầu đăng ký cơ sở.");
                    req.getSession().setAttribute("message", "Đã từ chối yêu cầu đăng ký cơ sở \"" + coSoName + "\".");
                    req.getSession().setAttribute("trashMessage", "Đã chuyển vào thùng rác.");
                    req.getSession().setAttribute("trashUrl", req.getContextPath() + "/admin/thung-rac");
                    req.getSession().setAttribute("trashCountdownSeconds", 10);
                } else {
                    req.getSession().setAttribute("error", result.errorMessage);
                }
                break;
            }

            case "khoa":
                if (coSo.getAccountID_QuanLy() != null) {
                    TaiKhoan mgr = taiKhoanDAO.getAccountById(coSo.getAccountID_QuanLy());
                    if (mgr != null) {
                        mgr.setIsLocked(true);
                        taiKhoanDAO.updateAccount(mgr);
                        req.getSession().setAttribute("message", "Đã khóa tài khoản owner \"" + mgr.getFullName() + "\".");
                    }
                }
                break;

            case "mo-khoa":
                if (coSo.getAccountID_QuanLy() != null) {
                    TaiKhoan mgr = taiKhoanDAO.getAccountById(coSo.getAccountID_QuanLy());
                    if (mgr != null) {
                        mgr.setIsLocked(false);
                        taiKhoanDAO.updateAccount(mgr);
                        req.getSession().setAttribute("message", "Đã mở khóa tài khoản owner \"" + mgr.getFullName() + "\".");
                    }
                }
                break;

            default:
                req.getSession().setAttribute("error", "Hành động không hợp lệ.");
        }

        resp.sendRedirect(req.getContextPath() + "/admin/chi-nhanh?tab=pending");
    }

    private void loadPageData(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // Dùng getAllCoSoIncludingPending() (không phải getAllCoSo()) vì trang này
        // CẦN thấy CoSo "Chờ duyệt" để hiển thị tab tương ứng.
        List<CoSo> allBranches = coSoDAO.getAllCoSoIncludingPending();
        List<TaiKhoan> allAccounts = taiKhoanDAO.getAllAccounts();

        // Map accountId -> TaiKhoan for quick lookup
        Map<Integer, TaiKhoan> accountMap = new HashMap<>();
        if (allAccounts != null) {
            for (TaiKhoan tk : allAccounts) {
                accountMap.put(tk.getAccountId(), tk);
            }
        }

        List<Map<String, Object>> pending  = new ArrayList<>();
        List<Map<String, Object>> approved = new ArrayList<>();

        for (CoSo cs : allBranches) {
            // Only process branches that came from owner registration (have a linked manager)
            if (cs.getAccountID_QuanLy() == null) continue;
            TaiKhoan mgr = accountMap.get(cs.getAccountID_QuanLy());
            if (mgr == null) continue;

            Map<String, Object> row = new HashMap<>();
            row.put("coSo", cs);
            row.put("manager", mgr);
            row.put("capabilities", capabilityDAO.findByCoSoId(cs.getCoSoID()));

            switch (cs.getTrangThai()) {
                case "Chờ duyệt": pending.add(row); break;
                case "Đang hoạt động": approved.add(row); break;
                // "Từ chối" không hiển thị ở trang Quản lý Owner nữa —
                // chỉ xuất hiện tại /admin/thung-rac (xem AdminTrashServlet).
                default: break;
            }
        }

        req.setAttribute("pending",  pending);
        req.setAttribute("approved", approved);
        req.getRequestDispatcher("/admin/QuanLyOwner.jsp").forward(req, resp);
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private void sendApprovalEmail(TaiKhoan account) {
        final String email = account.getEmail();
        final String name  = account.getFullName();
        new Thread(() -> {
            try {
                EmailUtil.sendEmail(email,
                    "Tài khoản đối tác V-SPORT đã được phê duyệt",
                    "Chào " + name + ",\n\n" +
                    "Cơ sở thể thao của bạn đã được quản trị viên phê duyệt thành công.\n" +
                    "Bạn có thể đăng nhập tại: http://localhost:8080/Backend_java\n" +
                    "  - Email: " + email + "\n" +
                    "  - Mật khẩu mặc định: 123456\n\n" +
                    "Vui lòng đổi mật khẩu sau khi đăng nhập lần đầu.\n\nTrân trọng,\nBan quản trị V-SPORT");
            } catch (Exception e) {
                logger.error("Lỗi gửi email phê duyệt tới {}", email, e);
            }
        }).start();
    }

    private void syncCourts(int coSoId, String loaiHinh, int total) {
        if (loaiHinh == null || loaiHinh.isBlank() || total <= 0) return;
        String[] sports = Arrays.stream(loaiHinh.split(",")).map(String::trim).toArray(String[]::new);
        Map<String, Integer> sportCounts = new LinkedHashMap<>();
        int base = total / sports.length, rem = total % sports.length;
        for (int i = 0; i < sports.length; i++) sportCounts.put(sports[i], base + (i < rem ? 1 : 0));

        try (Connection conn = DBUtil.getConnection()) {
            if (conn == null) return;
            Map<String, Integer> sportTypeMap = new HashMap<>();
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT m.TenMon, l.LoaiSanID FROM LoaiSan l JOIN MonTheThao m ON l.MonTheThaoID = m.MonTheThaoID");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) sportTypeMap.put(rs.getNString(1), rs.getInt(2));
            }
            int defaultType = 1;
            try (PreparedStatement ps = conn.prepareStatement("SELECT TOP 1 LoaiSanID FROM LoaiSan");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) defaultType = rs.getInt(1);
            }
            for (Map.Entry<String, Integer> e : sportCounts.entrySet()) {
                String sport = e.getKey(); int expected = e.getValue();
                int typeId = sportTypeMap.getOrDefault(sport, defaultType);
                List<Integer> existing = new ArrayList<>();
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT s.SanID FROM San s JOIN LoaiSan l ON s.LoaiSanID=l.LoaiSanID " +
                        "JOIN MonTheThao m ON l.MonTheThaoID=m.MonTheThaoID WHERE s.CoSoID=? AND m.TenMon=? ORDER BY s.SanID")) {
                    ps.setInt(1, coSoId); ps.setNString(2, sport);
                    try (ResultSet rs = ps.executeQuery()) { while (rs.next()) existing.add(rs.getInt(1)); }
                }
                int cur = existing.size();
                if (cur < expected) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO San(TenSan,LoaiSanID,CoSoID,TrangThai,MoTa,HinhAnh) VALUES(?,?,?,?,?,?)")) {
                        for (int i = cur; i < expected; i++) {
                            int idx = i + 1;
                            ps.setNString(1, sport + " " + (idx < 10 ? "0" + idx : idx));
                            ps.setInt(2, typeId); ps.setInt(3, coSoId);
                            ps.setNString(4, "Sẵn sàng"); ps.setNString(5, ""); ps.setNString(6, "");
                            ps.addBatch();
                        }
                        ps.executeBatch();
                    }
                }
            }
        } catch (Exception ex) {
            logger.error("syncCourts error coSoId={}", coSoId, ex);
        }
    }

    private void sendRejectionEmail(TaiKhoan account, String coSoName) {
        final String email = account.getEmail();
        final String name = account.getFullName();
        new Thread(() -> {
            try {
                EmailUtil.sendEmail(email,
                    "Yêu cầu đăng ký đối tác V-SPORT đã bị từ chối",
                    "Chào " + name + ",\n\n" +
                    "Chúng tôi rất tiếc phải thông báo rằng yêu cầu đăng ký cơ sở \"" + coSoName + "\" của bạn đã bị từ chối bởi ban quản trị.\n" +
                    "Bạn vẫn có thể đăng ký lại cơ sở mới với email này khi sẵn sàng.\n\n" +
                    "Trân trọng,\nBan quản trị V-SPORT");
            } catch (Exception e) {
                logger.error("Lỗi gửi email từ chối tới {}", email, e);
            }
        }).start();
    }
}
