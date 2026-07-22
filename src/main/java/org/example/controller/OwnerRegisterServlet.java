package org.example.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.dao.TaiKhoanDAO;
import org.example.dao.impl.TaiKhoanDAOImpl;
import org.example.util.ValidationUtil;
import org.example.util.JPAUtil;
import org.example.model.CoSo;
import org.example.model.TaiKhoan;
import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityTransaction;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.Types;
import java.util.Random;

/**
 * Handles the multi-step owner registration flow:
 *   GET  /owner/register    -> shows landing page
 *   GET  /owner/otp-status  -> reports whether the session still has a valid OTP / verified email (AJAX, returns JSON)
 *   POST /owner/send-otp    -> sends OTP to the given email (AJAX, returns JSON)
 *   POST /owner/verify-otp  -> verifies the OTP (AJAX, returns JSON)
 *   POST /owner/register    -> final registration submission (AJAX, returns JSON)
 */
@WebServlet(urlPatterns = {"/owner/register", "/owner/send-otp", "/owner/verify-otp", "/owner/otp-status"})
public class OwnerRegisterServlet extends HttpServlet {
    private static final Logger logger = LogManager.getLogger(OwnerRegisterServlet.class);
    private final TaiKhoanDAO taiKhoanDAO = new TaiKhoanDAOImpl();
    private final org.example.service.admin.CapabilityApprovalService capabilityApprovalService =
            new org.example.service.admin.CapabilityApprovalService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if ("/owner/otp-status".equals(req.getServletPath())) {
            handleOtpStatus(req, resp);
        } else {
            req.getRequestDispatcher("/ownerLanding.jsp").forward(req, resp);
        }
    }

    // ────────────────────────────────────────
    // OTP STATUS (dùng để khôi phục đúng bước sau khi reload trang, không lộ mã OTP)
    // ────────────────────────────────────────
    private void handleOtpStatus(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        HttpSession session = req.getSession(false);

        boolean emailVerified = false;
        boolean otpActive = false;
        String otpEmail = null;
        long secondsRemaining = 0;

        if (session != null) {
            Boolean verifiedAttr = (Boolean) session.getAttribute("ownerEmailVerified");
            emailVerified = verifiedAttr != null && verifiedAttr;

            String savedOtp = (String) session.getAttribute("ownerOtp");
            Long otpTime = (Long) session.getAttribute("ownerOtpTime");
            otpEmail = (String) session.getAttribute("ownerOtpEmail");

            if (savedOtp != null && otpTime != null) {
                long remainingMs = (5 * 60 * 1000) - (System.currentTimeMillis() - otpTime);
                if (remainingMs > 0) {
                    otpActive = true;
                    secondsRemaining = remainingMs / 1000;
                }
            }
        }

        StringBuilder json = new StringBuilder();
        json.append("{\"emailVerified\":").append(emailVerified)
                .append(",\"otpActive\":").append(otpActive)
                .append(",\"secondsRemaining\":").append(secondsRemaining)
                .append(",\"otpEmail\":").append(otpEmail != null ? "\"" + escapeJson(otpEmail) + "\"" : "null")
                .append("}");
        out.print(json.toString());
    }

    private String escapeJson(String s) {
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json;charset=UTF-8");

        String path = req.getServletPath();

        if ("/owner/send-otp".equals(path)) {
            handleSendOtp(req, resp);
        } else if ("/owner/verify-otp".equals(path)) {
            handleVerifyOtp(req, resp);
        } else {
            handleRegister(req, resp);
        }
    }

    // ────────────────────────────────────────
    // SEND OTP
    // ────────────────────────────────────────
    private void handleSendOtp(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        PrintWriter out = resp.getWriter();
        String email = req.getParameter("email");
        String phone = req.getParameter("phone");
        if (email != null) {
            email = email.trim();
        }
        if (phone != null) {
            phone = phone.trim();
        }

        if (email == null || email.isEmpty()) {
            out.print("{\"success\":false,\"message\":\"Email không được để trống.\"}");
            return;
        }
        if (!ValidationUtil.isValidEmail(email)) {
            out.print("{\"success\":false,\"message\":\"Email không hợp lệ và không được chứa khoảng trắng.\"}");
            return;
        }
        if (phone == null || phone.isEmpty()) {
            out.print("{\"success\":false,\"message\":\"Số điện thoại không được để trống.\"}");
            return;
        }
        if (!ValidationUtil.isValidVNPhone(phone)) {
            out.print("{\"success\":false,\"message\":\"Số điện thoại không hợp lệ.\"}");
            return;
        }
        // Check if email already exists (allow re-registration if previously rejected by admin)
        if (taiKhoanDAO.kiemtraEmail(email) && !isRejectedOwnerEmail(email)) {
            out.print("{\"success\":false,\"message\":\"Email đã tồn tại trong hệ thống.\"}");
            return;
        }

        try {
            // Re-use existing OTP sending infrastructure
            String otp = taiKhoanDAO.sendRegistrationOTP(email, "Chủ sân");
            HttpSession session = req.getSession();
            session.setAttribute("ownerOtp", otp);
            session.setAttribute("ownerOtpEmail", email);
            session.setAttribute("ownerOtpTime", System.currentTimeMillis());
            System.out.println("[Owner OTP] Sent OTP to " + email + ": " + otp);
            out.print("{\"success\":true}");
        } catch (Exception e) {
            logger.error("[Owner OTP] Error sending OTP to {}", email, e);
            out.print("{\"success\":false,\"message\":\"Lỗi gửi OTP. Vui lòng thử lại.\"}");
        }
    }

    // ────────────────────────────────────────
    // VERIFY OTP
    // ────────────────────────────────────────
    private void handleVerifyOtp(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        PrintWriter out = resp.getWriter();
        String email = req.getParameter("email");
        String otp = req.getParameter("otp");
        HttpSession session = req.getSession(false);

        if (session == null) {
            out.print("{\"success\":false,\"message\":\"Phiên đã hết hạn. Vui lòng thử lại.\"}");
            return;
        }

        String savedOtp = (String) session.getAttribute("ownerOtp");
        String savedEmail = (String) session.getAttribute("ownerOtpEmail");

        if (savedOtp == null || savedEmail == null) {
            out.print("{\"success\":false,\"message\":\"Chưa gửi OTP. Vui lòng quay lại bước trước.\"}");
            return;
        }

        if (!savedEmail.equalsIgnoreCase(email)) {
            out.print("{\"success\":false,\"message\":\"Email không khớp.\"}");
            return;
        }

        // Check OTP expiry (5 minutes) 
        Long otpTime = (Long) session.getAttribute("ownerOtpTime");
        if (otpTime != null && System.currentTimeMillis() - otpTime > 5 * 60 * 1000) {
            out.print("{\"success\":false,\"message\":\"Mã OTP đã hết hạn. Vui lòng gửi lại.\"}");
            return;
        }

        if (savedOtp.equals(otp)) {
            session.setAttribute("ownerEmailVerified", true);
            // Clear OTP from session
            session.removeAttribute("ownerOtp");
            out.print("{\"success\":true}");
        } else {
            out.print("{\"success\":false,\"message\":\"Mã OTP không đúng.\"}");
        }
    }

    // ────────────────────────────────────────
    // FINAL REGISTRATION
    // ────────────────────────────────────────
    private void handleRegister(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        PrintWriter out = resp.getWriter();
        HttpSession session = req.getSession(false);

        // Check that email was verified777777777
        Boolean verified = (session != null) ? (Boolean) session.getAttribute("ownerEmailVerified") : null;
        if (verified == null || !verified) {
            out.print("{\"success\":false,\"message\":\"Email chưa được xác thực.\"}");
            return;
        }

        String ownerName   = req.getParameter("ownerName");
        String email       = req.getParameter("email");
        String phone       = req.getParameter("phone");
        String address     = req.getParameter("address");
        String description = req.getParameter("description");
        String openTime    = req.getParameter("openTime");
        String closeTime   = req.getParameter("closeTime");
        String operatingDays = req.getParameter("operatingDays");
        String sportsData  = req.getParameter("sportsData"); // JSON array
        String viDoRaw     = req.getParameter("viDo");
        String kinhDoRaw   = req.getParameter("kinhDo");
        String capabilitiesRaw = req.getParameter("capabilities"); // comma-separated, whitelist-checked below

        if (ownerName != null) ownerName = ownerName.trim();
        if (email != null) email = email.trim();
        if (phone != null) phone = phone.trim();

        // Parse and validate viDo / kinhDo (optional — null allowed)
        BigDecimal viDo = null;
        BigDecimal kinhDo = null;
        if (viDoRaw != null && !viDoRaw.trim().isEmpty()) {
            try { viDo = new BigDecimal(viDoRaw.trim()); } catch (NumberFormatException ignored) {}
        }
        if (kinhDoRaw != null && !kinhDoRaw.trim().isEmpty()) {
            try { kinhDo = new BigDecimal(kinhDoRaw.trim()); } catch (NumberFormatException ignored) {}
        }
        // If user supplied one but not the other, reject
        if ((viDo == null) != (kinhDo == null)) {
            out.print("{\"success\":false,\"message\":\"Vui lòng cung cấp đủ cả vĩ độ và kinh độ.\"}");
            return;
        }
        if (viDo != null && (viDo.compareTo(BigDecimal.valueOf(-90)) < 0 || viDo.compareTo(BigDecimal.valueOf(90)) > 0)) {
            out.print("{\"success\":false,\"message\":\"Vĩ độ phải nằm trong khoảng -90 đến 90.\"}");
            return;
        }
        if (kinhDo != null && (kinhDo.compareTo(BigDecimal.valueOf(-180)) < 0 || kinhDo.compareTo(BigDecimal.valueOf(180)) > 0)) {
            out.print("{\"success\":false,\"message\":\"Kinh độ phải nằm trong khoảng -180 đến 180.\"}");
            return;
        }

        // Basic validation
        if (ownerName == null || ownerName.isEmpty() ||
                email == null || email.isEmpty() ||
                phone == null || phone.isEmpty()) {
            out.print("{\"success\":false,\"message\":\"Vui lòng điền đầy đủ thông tin bắt buộc.\"}");
            return;
        }

        if (!ValidationUtil.isValidEmail(email)) {
            out.print("{\"success\":false,\"message\":\"Email không hợp lệ và không được chứa khoảng trắng.\"}");
            return;
        }

        if (!ValidationUtil.isValidVNPhone(phone)) {
            out.print("{\"success\":false,\"message\":\"Số điện thoại không hợp lệ.\"}");
            return;
        }

        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction trans = em.getTransaction();
        try {
            trans.begin();

            // Check if email already registered — allow re-registration only if previously rejected
            Long existingCount = em.createQuery(
                    "SELECT COUNT(a) FROM TaiKhoan a WHERE a.email = :email OR a.username = :username", Long.class)
                    .setParameter("email", email)
                    .setParameter("username", email)
                    .getSingleResult();
            int reusedAccountId = -1;
            if (existingCount > 0) {
                if (!isRejectedOwnerEmail(email)) {
                    out.print("{\"success\":false,\"message\":\"Email đã được đăng ký trên hệ thống.\"}");
                    trans.rollback();
                    return;
                }
                // Soft-archive old rejected CoSo; reuse existing Account
                reusedAccountId = softArchiveRejectedOwnerCoSo(em, email);
                if (reusedAccountId < 0) {
                    out.print("{\"success\":false,\"message\":\"Không thể xử lý đăng ký lại. Vui lòng thử lại.\"}");
                    trans.rollback();
                    return;
                }
            }

            // Parse sportsData to obtain loaiHinhKinhDoanh and total count
            int totalCourts = 0;
            java.util.List<String> sportNames = new java.util.ArrayList<>();
            if (sportsData != null && !sportsData.isEmpty()) {
                java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("\"sport\"\\s*:\\s*\"([^\"]+)\"\\s*,\\s*\"quantity\"\\s*:\\s*(\\d+)");
                java.util.regex.Matcher matcher = pattern.matcher(sportsData);
                while (matcher.find()) {
                    String sportName = matcher.group(1);
                    int quantity = Integer.parseInt(matcher.group(2));
                    sportNames.add(sportName);
                    totalCourts += quantity;
                }
            }

            String loaiHinh = String.join(", ", sportNames);

            // Create new CoSo (Pending Approval)
            CoSo coSo = new CoSo();
            coSo.setTenCoSo(ownerName);
            coSo.setDiaChi(address);
            coSo.setSoDienThoai(phone);
            coSo.setTrangThai("Chờ duyệt");
            if (openTime != null && !openTime.isEmpty()) {
                coSo.setGioMoCua(java.time.LocalTime.parse(openTime));
            }
            if (closeTime != null && !closeTime.isEmpty()) {
                coSo.setGioDongCua(java.time.LocalTime.parse(closeTime));
            }
            coSo.setMoTa(description);
            coSo.setLoaiHinhKinhDoanh(loaiHinh);
            coSo.setSoLuongSanDuKien(totalCourts);
            coSo.setViDo(viDo);
            coSo.setKinhDo(kinhDo);

            em.persist(coSo);
            em.flush(); // To retrieve generated CoSoID

            // Ghi nhận các "loại hình kinh doanh" Owner đăng ký thêm (ngoài cho thuê sân).
            // Chỉ tạo bản ghi PENDING - KHÔNG kích hoạt ngay. Trong cùng transaction với
            // việc tạo CoSo để không có tình trạng CoSo tồn tại nhưng thiếu capability.
            if (capabilitiesRaw != null && !capabilitiesRaw.isBlank()) {
                java.util.List<String> requestedCapabilities = java.util.Arrays.stream(capabilitiesRaw.split(","))
                        .map(String::trim)
                        .filter(s -> !s.isEmpty())
                        .collect(java.util.stream.Collectors.toList());
                capabilityApprovalService.registerPending(em, coSo.getCoSoID(), requestedCapabilities);
            }

            // Create or reuse locked manager Account
            TaiKhoan managerAcc;
            if (reusedAccountId > 0) {
                // Re-registration: reuse existing Account, update profile fields
                managerAcc = em.find(TaiKhoan.class, reusedAccountId);
                if (managerAcc == null) {
                    out.print("{\"success\":false,\"message\":\"Không tìm thấy tài khoản. Vui lòng thử lại.\"}");
                    trans.rollback();
                    return;
                }
                managerAcc.setFullName(ownerName);
                managerAcc.setPhoneNumber(phone);
                managerAcc.setIsLocked(true);
                managerAcc.setCoSoId(coSo.getCoSoID());
                em.merge(managerAcc);
            } else {
                // First-time registration: create new Account
                managerAcc = new TaiKhoan();
                managerAcc.setUsername(email);
                managerAcc.setPassword(org.mindrot.jbcrypt.BCrypt.hashpw("123456", org.mindrot.jbcrypt.BCrypt.gensalt(12)));
                managerAcc.setFullName(ownerName);
                managerAcc.setPhoneNumber(phone);
                managerAcc.setEmail(email);
                managerAcc.setRoleId(2);
                managerAcc.setCoSoId(coSo.getCoSoID());
                managerAcc.setIsLocked(true);
                managerAcc.setDiemUyTin(100);
                managerAcc.setDiemTrinhDo(1000);
                managerAcc.setNhanThongBaoSos(true);
                em.persist(managerAcc);
                em.flush();
            }

            // Link CoSo to Manager Account
            coSo.setAccountID_QuanLy(managerAcc.getAccountId());
            em.merge(coSo);
            trans.commit();

            // Clean up session OTP attributes
            if (session != null) {
                session.removeAttribute("ownerEmailVerified");
                session.removeAttribute("ownerOtpEmail");
                session.removeAttribute("ownerOtpTime");
            }

            out.print("{\"success\":true}");
        } catch (Exception e) {
            if (trans.isActive()) {
                trans.rollback();
            }
            logger.error("[Owner Registration] Persistence error", e);
            out.print("{\"success\":false,\"message\":\"Lỗi lưu thông tin đăng ký. Vui lòng thử lại.\"}");
        } finally {
            em.close();
        }
    }

    // ────────────────────────────────────────
    // HELPERS
    // ────────────────────────────────────────

    /**
     * Returns true if the email belongs to an owner registration that was rejected by admin.
     * Rejected = TaiKhoan.isLocked=true AND linked CoSo.TrangThai='Từ chối'.
     */
    private boolean isRejectedOwnerEmail(String email) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            Long count = em.createQuery(
                    "SELECT COUNT(c) FROM CoSo c WHERE c.TrangThai = 'Từ chối' " +
                    "AND (c.isDeleted = false OR c.isDeleted IS NULL) " +
                    "AND c.AccountID_QuanLy IN " +
                    "(SELECT a.accountId FROM TaiKhoan a WHERE (a.email = :email OR a.username = :email) AND a.isLocked = true)",
                    Long.class)
                    .setParameter("email", email)
                    .getSingleResult();
            return count > 0;
        } catch (Exception e) {
            logger.error("[OwnerRegister] isRejectedOwnerEmail error for {}", email, e);
            return false;
        } finally {
            em.close();
        }
    }

    /**
     * Soft-archives all non-deleted rejected CoSo for the locked account with the given email.
     * Returns the accountId to reuse, or -1 if not found.
     */
    private int softArchiveRejectedOwnerCoSo(EntityManager em, String email) {
        try {
            java.util.List<TaiKhoan> accounts = em.createQuery(
                    "SELECT a FROM TaiKhoan a WHERE (a.email = :email OR a.username = :email) AND a.isLocked = true",
                    TaiKhoan.class)
                    .setParameter("email", email)
                    .getResultList();

            if (accounts.isEmpty()) return -1;

            TaiKhoan acc = accounts.get(0);
            em.createQuery(
                    "UPDATE CoSo c SET c.isDeleted = true, c.deletedAt = :now, c.deletedBy = :by " +
                    "WHERE c.AccountID_QuanLy = :accId AND c.TrangThai = 'Từ chối' " +
                    "AND (c.isDeleted = false OR c.isDeleted IS NULL)")
                    .setParameter("now", java.time.LocalDateTime.now())
                    .setParameter("by", acc.getAccountId())
                    .setParameter("accId", acc.getAccountId())
                    .executeUpdate();

            logger.info("[OwnerRegister] Soft-archived rejected CoSo for email: {}, accountId: {}", email, acc.getAccountId());
            return acc.getAccountId();
        } catch (Exception e) {
            logger.error("[OwnerRegister] softArchiveRejectedOwnerCoSo error for {}", email, e);
            throw e;
        }
    }
}
