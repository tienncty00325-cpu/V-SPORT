package org.example.controller.customer;

import com.google.gson.Gson;
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
import org.example.dao.CustomerProfileDAO;
import org.example.dao.LoaiSanDAO;
import org.example.dao.TaiKhoanDAO;
import org.example.dao.TeamDAO;
import org.example.dao.impl.CustomerProfileDAOImpl;
import org.example.dao.impl.LoaiSanDAOImpl;
import org.example.dao.impl.TaiKhoanDAOImpl;
import org.example.dao.impl.TeamDAOImpl;
import org.example.dto.CustomerProfileExtraDTO;
import org.example.dto.TeamSummaryDTO;
import org.example.model.TaiKhoan;
import org.example.service.team.TeamService;
import org.example.util.RoleRedirectUtil;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Paths;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Trang hồ sơ cá nhân full-screen (/customer/ho-so) — thay thế section
 * #thongtin cũ trong TaiKhoan.jsp. Đọc thông tin cơ bản qua TaiKhoanDAO
 * (JPA, không đổi) và các trường mở rộng (cover/thể chất/cá nhân hóa) qua
 * CustomerProfileDAO (JDBC thuần, độc lập hoàn toàn khỏi entity TaiKhoan —
 * xem ghi chú trong CustomerProfileDAO).
 */
@WebServlet(urlPatterns = {
        "/customer/ho-so",
        "/customer/ho-so/cap-nhat-the-chat",
        "/customer/ho-so/cap-nhat-ghi-chu",
        "/customer/ho-so/cap-nhat-ca-nhan-hoa",
        "/customer/ho-so/doi-cover"
})
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 5 * 1024 * 1024,
        maxRequestSize = 6 * 1024 * 1024
)
public class CustomerProfileServlet extends HttpServlet {

    private static final Logger logger = LogManager.getLogger(CustomerProfileServlet.class);
    private static final Set<String> ALLOWED_COVER_TYPES = Set.of("image/jpeg", "image/png", "image/webp");
    private static final Set<String> ALLOWED_LEVELS = Set.of("Mới chơi", "Cơ bản", "Trung bình", "Khá", "Nâng cao");
    private static final Set<String> ALLOWED_FREQUENCIES = Set.of("1 lần/tuần", "2-3 lần/tuần", "4+ lần/tuần", "Không cố định");

    private final TaiKhoanDAO taiKhoanDAO = new TaiKhoanDAOImpl();
    private final CustomerProfileDAO profileDAO = new CustomerProfileDAOImpl();
    private final LoaiSanDAO loaiSanDAO = new LoaiSanDAOImpl();
    private final TeamDAO teamDAO = new TeamDAOImpl();
    private final TeamService teamService = new TeamService(teamDAO);
    private static final Gson GSON = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();
        if (!"/customer/ho-so".equals(path)) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        TaiKhoan user = requireCustomer(req, resp);
        if (user == null) return;

        TaiKhoan account = taiKhoanDAO.getAccountById(user.getAccountId());
        if (account == null || Boolean.TRUE.equals(account.isDeleted()) || account.isLocked()) {
            req.getSession().invalidate();
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        CustomerProfileExtraDTO profileExtra;
        try {
            profileExtra = profileDAO.getExtra(account.getAccountId());
        } catch (SQLException e) {
            logger.error("Không thể tải hồ sơ mở rộng cho accountId={} — có thể migration_customer_profile.sql chưa chạy: {}",
                    account.getAccountId(), e.getMessage(), e);
            profileExtra = new CustomerProfileExtraDTO();
        }

        List<org.example.model.MonTheThao> dsMon;
        try {
            dsMon = loaiSanDAO.getAllMonTheThao();
        } catch (Exception e) {
            logger.error("Không thể tải danh sách môn thể thao cho trang hồ sơ: {}", e.getMessage(), e);
            dsMon = List.of();
        }

        List<TeamSummaryDTO> myTeams;
        try {
            myTeams = teamService.getMyTeams(account.getAccountId());
        } catch (RuntimeException e) {
            logger.error("Không thể tải danh sách đội nhóm cho trang hồ sơ, accountId={}: {}",
                    account.getAccountId(), e.getMessage(), e);
            myTeams = List.of();
        }

        req.setAttribute("account", account);
        req.setAttribute("profileExtra", profileExtra);
        req.setAttribute("dsMon", dsMon);
        req.setAttribute("myTeams", myTeams);
        req.getRequestDispatcher("/customer/HoSo.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getServletPath();
        switch (path) {
            case "/customer/ho-so/cap-nhat-the-chat": handleUpdatePhysical(req, resp); return;
            case "/customer/ho-so/cap-nhat-ghi-chu": handleUpdateNote(req, resp); return;
            case "/customer/ho-so/cap-nhat-ca-nhan-hoa": handleUpdatePersonalization(req, resp); return;
            case "/customer/ho-so/doi-cover": handleUpdateCover(req, resp); return;
            default: resp.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    private void handleUpdatePhysical(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;

        Integer height = parseIntSafe(req.getParameter("heightCm"));
        Integer weight = parseIntSafe(req.getParameter("weightKg"));
        if (height != null && (height < 50 || height > 260)) {
            writeJson(resp, 400, Map.of("success", false, "message", "Chiều cao phải trong khoảng 50-260cm."));
            return;
        }
        if (weight != null && (weight < 20 || weight > 300)) {
            writeJson(resp, 400, Map.of("success", false, "message", "Cân nặng phải trong khoảng 20-300kg."));
            return;
        }

        try {
            boolean ok = profileDAO.updatePhysical(user.getAccountId(), height, weight);
            writeJson(resp, ok ? 200 : 400, Map.of("success", ok, "message", ok ? "Đã cập nhật thông tin thể chất." : "Không thể cập nhật."));
        } catch (SQLException e) {
            logger.error("Lỗi cập nhật thông tin thể chất accountId={}: {}", user.getAccountId(), e.getMessage(), e);
            writeJson(resp, 503, Map.of("success", false, "message", "Chức năng đang được cấu hình. Vui lòng thử lại sau."));
        }
    }

    private void handleUpdateNote(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;

        String note = req.getParameter("note");
        if (note != null) {
            note = note.trim();
            if (note.length() > 500) {
                writeJson(resp, 400, Map.of("success", false, "message", "Ghi chú tối đa 500 ký tự."));
                return;
            }
            if (note.isEmpty()) note = null;
        }

        try {
            boolean ok = profileDAO.updateNote(user.getAccountId(), note);
            writeJson(resp, ok ? 200 : 400, Map.of("success", ok, "message", ok ? "Đã cập nhật ghi chú." : "Không thể cập nhật."));
        } catch (SQLException e) {
            logger.error("Lỗi cập nhật ghi chú accountId={}: {}", user.getAccountId(), e.getMessage(), e);
            writeJson(resp, 503, Map.of("success", false, "message", "Chức năng đang được cấu hình. Vui lòng thử lại sau."));
        }
    }

    private void handleUpdatePersonalization(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;

        String location = trimToNull(req.getParameter("location"));
        Integer sportId = parseIntSafe(req.getParameter("sportId"));
        String level = trimToNull(req.getParameter("level"));
        String goal = trimToNull(req.getParameter("goal"));
        String frequency = trimToNull(req.getParameter("frequency"));

        if (location != null && location.length() > 255) {
            writeJson(resp, 400, Map.of("success", false, "message", "Vị trí yêu thích tối đa 255 ký tự."));
            return;
        }
        if (level != null && !ALLOWED_LEVELS.contains(level)) {
            writeJson(resp, 400, Map.of("success", false, "message", "Trình độ không hợp lệ."));
            return;
        }
        if (goal != null && goal.length() > 255) {
            writeJson(resp, 400, Map.of("success", false, "message", "Mục tiêu tối đa 255 ký tự."));
            return;
        }
        if (frequency != null && !ALLOWED_FREQUENCIES.contains(frequency)) {
            writeJson(resp, 400, Map.of("success", false, "message", "Tần suất chơi không hợp lệ."));
            return;
        }

        try {
            boolean ok = profileDAO.updatePersonalization(user.getAccountId(), location, sportId, level, goal, frequency);
            writeJson(resp, ok ? 200 : 400, Map.of("success", ok, "message", ok ? "Đã cập nhật cá nhân hóa." : "Không thể cập nhật."));
        } catch (SQLException e) {
            logger.error("Lỗi cập nhật cá nhân hóa accountId={}: {}", user.getAccountId(), e.getMessage(), e);
            writeJson(resp, 503, Map.of("success", false, "message", "Chức năng đang được cấu hình. Vui lòng thử lại sau."));
        }
    }

    private void handleUpdateCover(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        TaiKhoan user = requireCustomerJson(req, resp);
        if (user == null) return;

        Part coverPart;
        try {
            coverPart = req.getPart("cover");
        } catch (Exception e) {
            writeJson(resp, 400, Map.of("success", false, "message", "Vui lòng chọn ảnh bìa."));
            return;
        }
        if (coverPart == null || coverPart.getSize() <= 0) {
            writeJson(resp, 400, Map.of("success", false, "message", "Vui lòng chọn ảnh bìa."));
            return;
        }
        String contentType = coverPart.getContentType();
        if (contentType == null || !ALLOWED_COVER_TYPES.contains(contentType)) {
            writeJson(resp, 400, Map.of("success", false, "message", "Chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP."));
            return;
        }
        byte[] header = new byte[12];
        int read;
        try (InputStream is = coverPart.getInputStream()) {
            read = is.readNBytes(header, 0, header.length);
        }
        if (!looksLikeImage(header, read)) {
            writeJson(resp, 400, Map.of("success", false, "message", "Tệp không phải ảnh hợp lệ."));
            return;
        }

        String extension = getSafeImageExtension(coverPart.getSubmittedFileName(), contentType);
        String fileName = "cover-" + user.getAccountId() + "-" + UUID.randomUUID() + extension;
        String uploadPath = getServletContext().getRealPath("/uploads/covers");
        if (uploadPath == null) {
            uploadPath = new File(System.getProperty("user.home"), "v-sport/uploads/covers").getAbsolutePath();
        }
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists() && !uploadDir.mkdirs()) {
            writeJson(resp, 500, Map.of("success", false, "message", "Không thể tạo thư mục lưu ảnh bìa."));
            return;
        }
        File target = new File(uploadDir, fileName);
        coverPart.write(target.getAbsolutePath());
        String coverUrl = "/uploads/covers/" + fileName;

        try {
            boolean ok = profileDAO.updateCoverPath(user.getAccountId(), coverUrl);
            if (ok) {
                writeJson(resp, 200, Map.of("success", true, "message", "Đã cập nhật ảnh bìa.", "coverUrl", coverUrl));
            } else {
                writeJson(resp, 400, Map.of("success", false, "message", "Không thể lưu ảnh bìa."));
            }
        } catch (SQLException e) {
            logger.error("Lỗi cập nhật ảnh bìa accountId={}: {}", user.getAccountId(), e.getMessage(), e);
            writeJson(resp, 503, Map.of("success", false, "message", "Chức năng đang được cấu hình. Vui lòng thử lại sau."));
        }
    }

    private boolean looksLikeImage(byte[] b, int len) {
        if (len >= 3 && (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF) return true;
        if (len >= 8 && (b[0] & 0xFF) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G') return true;
        if (len >= 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') return true;
        return false;
    }

    private String getSafeImageExtension(String submittedFileName, String contentType) {
        String ext = null;
        if (submittedFileName != null && !submittedFileName.isBlank()) {
            String name = Paths.get(submittedFileName).getFileName().toString().toLowerCase();
            int dot = name.lastIndexOf('.');
            if (dot >= 0) {
                String candidate = name.substring(dot);
                if (Set.of(".jpg", ".jpeg", ".png", ".webp").contains(candidate)) ext = candidate;
            }
        }
        if (ext == null) {
            if ("image/png".equals(contentType)) ext = ".png";
            else if ("image/webp".equals(contentType)) ext = ".webp";
            else ext = ".jpg";
        }
        return ext;
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

    private void writeJson(HttpServletResponse resp, int status, Map<String, Object> payload) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json; charset=UTF-8");
        resp.getWriter().write(GSON.toJson(payload));
    }

    private Integer parseIntSafe(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return null; }
    }

    private String trimToNull(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }
}
