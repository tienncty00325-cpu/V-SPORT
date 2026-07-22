package org.example.controller.manager;

import org.example.model.LoaiSan;
import org.example.model.MonTheThao;
import org.example.model.San;
import org.example.model.TaiKhoan;
import org.example.service.manager.SanService;
import org.example.util.Constants;

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
import org.example.service.AuditLogService;

import java.io.IOException;
import java.io.File;
import java.math.BigDecimal;
import java.nio.file.Paths;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Servlet quản lý sân thi đấu dành cho Manager
 * Business logic được delegate cho SanService
 */
@WebServlet("/manager/quan-ly-san")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 5 * 1024 * 1024,
        maxRequestSize = 7 * 1024 * 1024
)
public class QuanLySanManagerServlet extends HttpServlet {

    private static final Logger logger = LogManager.getLogger(QuanLySanManagerServlet.class);
    private static final Set<String> ALLOWED_COURT_IMAGE_TYPES = Set.of("image/jpeg", "image/png", "image/webp", "image/gif");

    private final SanService sanService;

    public QuanLySanManagerServlet() {
        this.sanService = new SanService();
    }

    public QuanLySanManagerServlet(SanService sanService) {
        this.sanService = sanService;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession();

        TaiKhoan manager = (TaiKhoan) session.getAttribute("user");
        if (manager == null || manager.getRoleId() != Constants.ROLE_MANAGER) {
            response.sendRedirect(request.getContextPath() + "/dangnhap");
            return;
        }

        Integer coSoId = manager.getCoSoId();
        if (coSoId == null) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                "Tài khoản quản lý chưa được liên kết với cơ sở nào.");
            return;
        }

        try {
            List<San> dsSan = sanService.getSansByCoSo(coSoId);
            List<LoaiSan> dsLoaiSan = sanService.getLoaiSansByCoSo(coSoId);
            List<MonTheThao> dsMonTheThao = sanService.getRegisteredMonTheThao(coSoId);

            request.setAttribute("dsSan", dsSan);
            request.setAttribute("dsLoaiSan", dsLoaiSan);
            request.setAttribute("dsMonTheThao", dsMonTheThao);
            request.setAttribute("managerCoSoId", coSoId);

            request.getRequestDispatcher("/manager/QuanLySan.jsp").forward(request, response);

        } catch (Exception e) {
            logger.error("Error in doGet: {}", e.getMessage(), e);
            session.setAttribute("error", "Lỗi khi tải dữ liệu: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/manager/quan-ly-san");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession();

        TaiKhoan manager = (TaiKhoan) session.getAttribute("user");
        if (manager == null || manager.getRoleId() != Constants.ROLE_MANAGER) {
            response.sendRedirect(request.getContextPath() + "/dangnhap");
            return;
        }

        Integer coSoId = manager.getCoSoId();
        if (coSoId == null) {
            session.setAttribute("error", "Tài khoản quản lý chưa được liên kết với cơ sở nào.");
            response.sendRedirect(request.getContextPath() + "/manager/quan-ly-san");
            return;
        }

        String action = getFormField(request, "action");

        try {
            if (action == null || action.isBlank()) {
                throw new IllegalArgumentException("Không xác định được thao tác gửi lên từ form quản lý sân.");
            }
            switch (action) {
                case "add" -> handleAddSan(request, coSoId, session, manager);
                case "update" -> handleUpdateSan(request, coSoId, session, manager);
                case "delete" -> handleDeleteSan(request, coSoId, session, manager);
                case "updateStatus" -> handleUpdateSanStatus(request, coSoId, session);
                case "addType" -> handleAddLoaiSan(request, coSoId, session, manager);
                case "updateType" -> handleUpdateLoaiSan(request, coSoId, session);
                case "deleteType" -> handleDeleteLoaiSan(request, coSoId, session, manager);
                default -> logger.warn("Unknown action: {}", action);
            }
        } catch (IllegalArgumentException e) {
            logger.warn("Lỗi xử lý sân: {}", e.getMessage(), e);
            session.setAttribute("error", e.getMessage());
        } catch (Exception e) {
            logger.error("Unexpected error in doPost: {}", e.getMessage(), e);
            session.setAttribute("error", "Lỗi hệ thống: " + e.getMessage());
        }

        response.sendRedirect(request.getContextPath() + "/manager/quan-ly-san");
    }

    // ==================== HANDLER METHODS ====================

    private void handleAddSan(HttpServletRequest req, int coSoId, HttpSession session, TaiKhoan manager) throws IOException, ServletException {
        int soLuong = 1;
        String soLuongParam = req.getParameter("soLuong");
        if (soLuongParam != null && !soLuongParam.isBlank()) {
            soLuong = Math.max(1, Math.min(10, Integer.parseInt(soLuongParam)));
        }

        SanService.SanCreateRequest createReq = new SanService.SanCreateRequest();
        populateSanRequest(req, createReq);
        createReq.setHinhAnh(resolveCourtImage(req, null));

        String baseName = createReq.getTenSan() == null ? "" : createReq.getTenSan().trim();
        for (int i = 1; i <= soLuong; i++) {
            if (soLuong > 1) createReq.setTenSan(baseName + " " + i);
            San san = sanService.createSan(createReq, coSoId);
            AuditLogService.log(req, manager,
                AuditLogService.ACTION_CREATE, AuditLogService.ENTITY_SAN,
                String.valueOf(san.getSanID()), san.getTenSan(),
                "Manager tạo sân mới");
        }

        String msg = soLuong > 1
            ? "Đã tạo " + soLuong + " sân thành công!"
            : "Thêm sân thành công!";
        session.setAttribute("message", msg);
    }

    private void handleUpdateSan(HttpServletRequest req, int coSoId, HttpSession session, TaiKhoan manager) throws IOException, ServletException {
        int sanId = Integer.parseInt(req.getParameter("sanID"));
        String tenSan = req.getParameter("tenSan");

        SanService.SanUpdateRequest updateReq = new SanService.SanUpdateRequest();
        populateSanUpdateRequest(req, updateReq);
        updateReq.setHinhAnh(resolveCourtImage(req, req.getParameter("existingHinhAnh")));

        sanService.updateSan(sanId, updateReq, coSoId);
        session.setAttribute("message", "Cập nhật sân thành công!");
        AuditLogService.log(req, manager,
            AuditLogService.ACTION_UPDATE, AuditLogService.ENTITY_SAN,
            String.valueOf(sanId), tenSan,
            "Manager cập nhật thông tin sân");
    }

    private void handleDeleteSan(HttpServletRequest req, int coSoId, HttpSession session, TaiKhoan manager) {
        int sanId = Integer.parseInt(req.getParameter("sanID"));
        String tenSan = req.getParameter("tenSan");
        sanService.deleteSan(sanId, coSoId);
        session.setAttribute("message", "Đã chuyển sân thi đấu vào Thùng rác. Bạn có thể vào trang Thùng rác để khôi phục.");
        AuditLogService.log(req, manager,
            AuditLogService.ACTION_SOFT_DELETE, AuditLogService.ENTITY_SAN,
            String.valueOf(sanId), tenSan != null ? tenSan : "ID=" + sanId,
            "Manager xóa mềm sân");
    }


    private void handleUpdateSanStatus(HttpServletRequest req, int coSoId, HttpSession session) {
        int sanId = Integer.parseInt(req.getParameter("sanID"));
        String newStatus = req.getParameter("trangThai");
        sanService.updateSanStatus(sanId, newStatus, coSoId);
        session.setAttribute("message", "Đã cập nhật trạng thái sân thành công!");
    }

    private void handleAddLoaiSan(HttpServletRequest req, int coSoId, HttpSession session, TaiKhoan manager) {
        SanService.LoaiSanRequest createReq = new SanService.LoaiSanRequest();
        populateLoaiSanRequest(req, createReq);

        LoaiSan ls = sanService.createLoaiSan(createReq, coSoId);
        session.setAttribute("message", "Thêm cấu hình loại sân thành công!");
        AuditLogService.log(req, manager,
            AuditLogService.ACTION_CREATE, AuditLogService.ENTITY_LOAI_SAN,
            String.valueOf(ls.getLoaiSanID()), ls.getTenLoai(),
            "Manager tạo loại sân mới");
    }

    private void handleUpdateLoaiSan(HttpServletRequest req, int coSoId, HttpSession session) {
        int loaiSanId = Integer.parseInt(req.getParameter("loaiSanID"));

        SanService.LoaiSanRequest updateReq = new SanService.LoaiSanRequest();
        populateLoaiSanRequest(req, updateReq);

        sanService.updateLoaiSan(loaiSanId, updateReq, coSoId);
        session.setAttribute("message", "Cập nhật loại sân thành công!");
    }

    private void handleDeleteLoaiSan(HttpServletRequest req, int coSoId, HttpSession session, TaiKhoan manager) {
        int loaiSanId = Integer.parseInt(req.getParameter("loaiSanID"));
        LoaiSan loaiSan = sanService.getLoaiSanById(loaiSanId);
        String loaiSanName = loaiSan != null && loaiSan.getTenLoai() != null ? loaiSan.getTenLoai() : "ID=" + loaiSanId;
        sanService.deleteLoaiSan(loaiSanId, coSoId);
        session.setAttribute("message", "Đã chuyển cấu hình loại sân vào Thùng rác. Bạn có thể vào trang Thùng rác để khôi phục.");
        AuditLogService.log(req, manager,
            AuditLogService.ACTION_SOFT_DELETE, AuditLogService.ENTITY_LOAI_SAN,
            String.valueOf(loaiSanId), loaiSanName,
            "Manager xóa mềm loại sân");
    }


    // ==================== REQUEST POPULATORS ====================

    private void populateSanRequest(HttpServletRequest req, SanService.SanCreateRequest createReq) {
        createReq.setTenSan(getFormField(req, "tenSan"));
        createReq.setLoaiSanId(Integer.parseInt(getFormField(req, "loaiSanID")));
        createReq.setTrangThai(getFormField(req, "trangThai"));
        createReq.setMoTa(getFormField(req, "moTa"));
    }

    private void populateSanUpdateRequest(HttpServletRequest req, SanService.SanUpdateRequest updateReq) {
        updateReq.setTenSan(getFormField(req, "tenSan"));
        updateReq.setLoaiSanId(Integer.parseInt(getFormField(req, "loaiSanID")));
        updateReq.setTrangThai(getFormField(req, "trangThai"));
        updateReq.setMoTa(getFormField(req, "moTa"));
    }

    private void populateLoaiSanRequest(HttpServletRequest req, SanService.LoaiSanRequest loaiReq) {
        loaiReq.setTenLoai(getFormField(req, "tenLoai"));
        loaiReq.setMonTheThaoId(Integer.parseInt(getFormField(req, "monTheThaoID")));

        String giaKhongDenStr = getFormField(req, "giaKhongDen");
        loaiReq.setGiaKhongDen(new BigDecimal(giaKhongDenStr != null ? giaKhongDenStr.replace(",", "") : "0"));

        boolean khongDungDen = "true".equals(req.getParameter("khongDungDen"));
        loaiReq.setKhongDungDen(khongDungDen);

        if (!khongDungDen) {
            String giaCoDenStr = getFormField(req, "giaCoDen");
            if (giaCoDenStr != null && !giaCoDenStr.isBlank()) {
                loaiReq.setGiaCoDen(new BigDecimal(giaCoDenStr.replace(",", "")));
            }

            String timeStr = getFormField(req, "gioBatDauLenDen");
            if (timeStr != null && !timeStr.isEmpty()) {
                if (timeStr.length() == 5) timeStr += ":00";
                loaiReq.setGioBatDauLenDen(LocalTime.parse(timeStr));
            }

            String endTimeStr = getFormField(req, "gioKetThucLenDen");
            if (endTimeStr != null && !endTimeStr.isEmpty()) {
                if (endTimeStr.length() == 5) endTimeStr += ":00";
                loaiReq.setGioKetThucLenDen(LocalTime.parse(endTimeStr));
            }
        }
        // khongDungDen=true: giaCoDen, gioBatDau, gioKetThuc giữ null → service sẽ clear trong DB
    }

    private String resolveCourtImage(HttpServletRequest req, String existingImage) throws IOException, ServletException {
        Part imagePart = req.getPart("courtImageFile");
        if (imagePart != null && imagePart.getSize() > 0) {
            String contentType = imagePart.getContentType();
            if (contentType == null || contentType.isBlank() || !ALLOWED_COURT_IMAGE_TYPES.contains(contentType)) {
                throw new IllegalArgumentException("Chỉ hỗ trợ ảnh sân định dạng JPG, PNG, WEBP hoặc GIF.");
            }
            return saveCourtImageFile(req, imagePart);
        }
        return existingImage != null ? existingImage.trim() : null;
    }

    private String saveCourtImageFile(HttpServletRequest req, Part imagePart) throws IOException {
        String submittedFileName = Paths.get(imagePart.getSubmittedFileName()).getFileName().toString();
        String extension = getSafeImageExtension(submittedFileName, imagePart.getContentType());
        String fileName = "court-" + UUID.randomUUID() + extension;

        String uploadPath = getServletContext().getRealPath("/uploads/courts");
        if (uploadPath == null) {
            uploadPath = new File(System.getProperty("user.home"), "v-sport/uploads/courts").getAbsolutePath();
        }

        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists() && !uploadDir.mkdirs()) {
            throw new IOException("Không thể tạo thư mục lưu ảnh sân.");
        }

        File courtImageFile = new File(uploadDir, fileName);
        imagePart.write(courtImageFile.getAbsolutePath());
        return "/uploads/courts/" + fileName;
    }

    private String getSafeImageExtension(String fileName, String contentType) {
        String lowerName = fileName == null ? "" : fileName.toLowerCase();
        if (lowerName.endsWith(".jpg") || lowerName.endsWith(".jpeg")) return ".jpg";
        if (lowerName.endsWith(".png")) return ".png";
        if (lowerName.endsWith(".webp")) return ".webp";
        if (lowerName.endsWith(".gif")) return ".gif";

        if ("image/jpeg".equals(contentType)) return ".jpg";
        if ("image/png".equals(contentType)) return ".png";
        if ("image/webp".equals(contentType)) return ".webp";
        if ("image/gif".equals(contentType)) return ".gif";

        throw new IllegalArgumentException("Định dạng ảnh sân không hợp lệ.");
    }

    private String getFormField(HttpServletRequest req, String fieldName) {
        String value = req.getParameter(fieldName);
        if (value != null) {
            return value;
        }

        try {
            Part part = req.getPart(fieldName);
            if (part == null || part.getSubmittedFileName() != null) {
                return null;
            }
            java.io.InputStream inputStream = part.getInputStream();
            try (java.util.Scanner scanner = new java.util.Scanner(inputStream, java.nio.charset.StandardCharsets.UTF_8)) {
                scanner.useDelimiter("\\A");
                return scanner.hasNext() ? scanner.next() : "";
            }
        } catch (Exception e) {
            logger.debug("Không đọc được field multipart '{}': {}", fieldName, e.getMessage());
            return null;
        }
    }
}
