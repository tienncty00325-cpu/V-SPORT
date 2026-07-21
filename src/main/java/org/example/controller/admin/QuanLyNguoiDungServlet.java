package org.example.controller.admin;

import org.example.dao.TaiKhoanDAO;
import org.example.dao.VaiTroDAO;
import org.example.dao.impl.TaiKhoanDAOImpl;
import org.example.dao.impl.VaiTroDAOImpl;

import org.example.dao.CoSoDAO;
import org.example.dao.impl.CoSoDAOImpl;

import org.example.model.CoSo;
import org.example.model.TaiKhoan;
import org.example.model.VaiTro;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.example.dao.CaLamViecDAO;
import org.example.dao.impl.CaLamViecDAOImpl;
import org.example.model.CaLamViec;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.service.AuditLogService;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/admin/nhan-su")
public class QuanLyNguoiDungServlet extends HttpServlet {
    private static final Logger logger = LogManager.getLogger(QuanLyNguoiDungServlet.class);
    private TaiKhoanDAO TaiKhoanDAO = new TaiKhoanDAOImpl();
    private CoSoDAO coSoDAO = new CoSoDAOImpl();
    private VaiTroDAO VaiTroDAO = new VaiTroDAOImpl();
    private CaLamViecDAO caLamViecDAO = new CaLamViecDAOImpl();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        TaiKhoan user = (TaiKhoan) req.getSession().getAttribute("user");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }
        if (user.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        String action = req.getParameter("action");
        if ("delete".equals(action)) {
            int id = Integer.parseInt(req.getParameter("id"));
            TaiKhoan accToDelete = TaiKhoanDAO.getAccountById(id);
            if (accToDelete != null && accToDelete.getRoleId() != 1) {
                TaiKhoanDAO.softDeleteAccount(id);
            }
            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
            return;
        }

        List<TaiKhoan> accounts = TaiKhoanDAO.getStaffDirectoryAccounts();
        List<TaiKhoan> deletedAccounts = TaiKhoanDAO.getDeletedAccounts();
        List<CoSo> branches = coSoDAO.getAllCoSo();
        List<VaiTro> roles = VaiTroDAO.getAllRoles();
        List<CaLamViec> shifts = caLamViecDAO.getAllCaLamViec();

        req.setAttribute("accounts", accounts);
        req.setAttribute("staffs", accounts);
        req.setAttribute("deletedAccounts", deletedAccounts);
        req.setAttribute("branches", branches);
        req.setAttribute("roles", roles);
        req.setAttribute("shifts", shifts);
        req.getRequestDispatcher("/admin/NhanSu.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        TaiKhoan user = (TaiKhoan) req.getSession().getAttribute("user");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }
        if (user.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        String action = req.getParameter("action");
        if ("update".equals(action)) {
            TaiKhoan acc = TaiKhoanDAO.getAccountById(Integer.parseInt(req.getParameter("accountId")));
            if (acc != null) {
                String isLockedParam = req.getParameter("isLocked");
                if (isLockedParam != null) {
                    acc.setIsLocked("true".equals(isLockedParam) || "1".equals(isLockedParam));
                    TaiKhoanDAO.updateAccount(acc);
                } else {
                    String email = req.getParameter("email");
                    String phone = req.getParameter("phoneNumber");
                    String fullName = req.getParameter("fullName");
                    if (email != null) email = email.trim();
                    if (phone != null) phone = phone.trim();
                    if (fullName != null) fullName = fullName.trim();
                    
                    if (!org.example.util.ValidationUtil.isValidEmail(email)) {
                        req.getSession().setAttribute("error", "Định dạng Email không hợp lệ và không được chứa khoảng trắng!");
                        resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                        return;
                    }
                    if (phone != null && !phone.isEmpty()) {
                        if (!org.example.util.ValidationUtil.isValidVNPhone(phone)) {
                            req.getSession().setAttribute("error", "Định dạng Số điện thoại không hợp lệ (Phải bắt đầu bằng 0 hoặc +84 và có 10 số)!");
                            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                            return;
                        }
                    }

                    // Check if email has changed
                    boolean isEmailChanged = (email != null && !email.equalsIgnoreCase(acc.getEmail()));
                    if (isEmailChanged) {
                        if (TaiKhoanDAO.kiemtraEmail(email)) {
                            req.getSession().setAttribute("error", "Email đã tồn tại trên hệ thống!");
                            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                            return;
                        }
                    }
                    
                    acc.setFullName(fullName);
                    acc.setPhoneNumber(phone);
                    
                    // Only update role and branch if the account is NOT a Manager (roleId != 2)
                    if (acc.getRoleId() != 2) {
                        int newRoleId = Integer.parseInt(req.getParameter("roleId"));
                        // Prevent changing the role of an existing Admin account
                        if (acc.getRoleId() == 1 && newRoleId != 1) {
                            req.getSession().setAttribute("error", "Không thể thay đổi vai trò của tài khoản Quản trị viên!");
                            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                            return;
                        }
                        // Prevent granting Admin role to a non-admin account
                        if (acc.getRoleId() != 1 && newRoleId == 1) {
                            req.getSession().setAttribute("error", "Không thể cấp quyền Quản trị viên cho tài khoản này!");
                            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                            return;
                        }
                        acc.setRoleId(newRoleId);
                        
                        String coSoIdStr = req.getParameter("coSoId");
                        if (newRoleId == 2 && (coSoIdStr == null || coSoIdStr.isEmpty())) {
                            req.getSession().setAttribute("error", "Quản lý cần phải có Cơ sở!");
                            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                            return;
                        }
                        if (coSoIdStr != null && !coSoIdStr.isEmpty()) {
                            acc.setCoSoId(Integer.parseInt(coSoIdStr));
                        }
                    }
                    
                    // Password update: NOT allowed for Manager (2), Customer (3), Receptionist (4), and Security (5) roles.
                    boolean isRestrictedRole = (acc.getRoleId() == 2 || acc.getRoleId() == 3 || acc.getRoleId() == 4 || acc.getRoleId() == 5);
                    if (!isRestrictedRole) {
                        String rawPassword = req.getParameter("password");
                        if (rawPassword != null && !rawPassword.trim().isEmpty()) {
                            rawPassword = rawPassword.trim();
                            if (!org.example.util.ValidationUtil.isStrongPassword(rawPassword)) {
                                req.getSession().setAttribute("error", "Mật khẩu phải có tối thiểu 8 ký tự, bao gồm cả chữ hoa, chữ thường, số và ký tự đặc biệt!");
                                resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                                return;
                            }
                            acc.setPassword(org.mindrot.jbcrypt.BCrypt.hashpw(rawPassword, org.mindrot.jbcrypt.BCrypt.gensalt(12)));
                        }
                    }
                    
                    if (isEmailChanged) {
                        acc.setEmail(email);
                        String otpString = TaiKhoanDAO.sendRegistrationOTP(email, acc.getFullName());
                        req.getSession().setAttribute("otp", otpString);
                        req.getSession().setAttribute("tempAccount", acc);
                        req.getSession().setAttribute("authType", "ADMIN_EDIT");
                        req.getSession().setAttribute("otpAttempts", 0);
                        req.getSession().setAttribute("resendCount", 0);
                        req.getSession().setAttribute("needResend", false);
                        
                        String requestedWith = req.getHeader("X-Requested-With");
                        if ("XMLHttpRequest".equals(requestedWith)) {
                            resp.setContentType("application/json;charset=UTF-8");
                            resp.getWriter().write("{\"requiresOtp\": true, \"email\": \"" + email + "\"}");
                            return;
                        }

                        req.setAttribute("email", email);
                        req.getRequestDispatcher("/auth/NhapMa.jsp").forward(req, resp);
                        return;
                    } else {
                        TaiKhoanDAO.updateAccount(acc);
                        String requestedWith = req.getHeader("X-Requested-With");
                        if ("XMLHttpRequest".equals(requestedWith)) {
                            resp.setContentType("application/json;charset=UTF-8");
                            resp.getWriter().write("{\"success\": true, \"message\": \"Cập nhật tài khoản thành công!\"}");
                            return;
                        }
                    }
                }
            }
        } else if ("add".equals(action)) {
            boolean isAjax = "XMLHttpRequest".equals(req.getHeader("X-Requested-With"));
            String email = req.getParameter("email");
            String phoneNumber = req.getParameter("phoneNumber");

            if (email != null) email = email.trim();
            if (phoneNumber != null) phoneNumber = phoneNumber.trim();

            if (email == null || email.isEmpty()) {
                String msg = "Email không được để trống!";
                if (isAjax) { sendJsonError(resp, msg); return; }
                req.getSession().setAttribute("error", msg);
                resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                return;
            }

            if (!org.example.util.ValidationUtil.isValidEmail(email)) {
                String msg = "Định dạng Email không hợp lệ và không được chứa khoảng trắng!";
                if (isAjax) { sendJsonError(resp, msg); return; }
                req.getSession().setAttribute("error", msg);
                resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                return;
            }

            if (TaiKhoanDAO.kiemtraEmail(email)) {
                String msg = "Email đã tồn tại!";
                if (isAjax) { sendJsonError(resp, msg); return; }
                req.getSession().setAttribute("error", msg);
                resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                return;
            }

            if (phoneNumber != null && !phoneNumber.isEmpty()) {
                if (!org.example.util.ValidationUtil.isValidVNPhone(phoneNumber)) {
                    String msg = "Định dạng Số điện thoại không hợp lệ (Phải bắt đầu bằng 0 hoặc +84 và có 10 số)!";
                    if (isAjax) { sendJsonError(resp, msg); return; }
                    req.getSession().setAttribute("error", msg);
                    resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                    return;
                }
            }

            String fullName = req.getParameter("fullName");
            if (fullName != null) fullName = fullName.trim();

            // Generate internal username from email – not from client
            String username = generateUniqueUsername(email);

            TaiKhoan newAcc = new TaiKhoan();
            newAcc.setUsername(username);
            newAcc.setFullName(fullName);
            newAcc.setEmail(email);
            newAcc.setPhoneNumber(phoneNumber);

            int newRoleId = Integer.parseInt(req.getParameter("roleId"));
            // Prevent creating new Admin accounts
            if (newRoleId == 1) {
                String msg = "Không được tạo tài khoản Quản trị viên!";
                if (isAjax) { sendJsonError(resp, msg); return; }
                req.getSession().setAttribute("error", msg);
                resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                return;
            }
            newAcc.setRoleId(newRoleId);

            String coSoIdStr = req.getParameter("coSoId");
            if (newRoleId == 2 && (coSoIdStr == null || coSoIdStr.isEmpty())) {
                String msg = "Quản lý cần phải có Cơ sở!";
                if (isAjax) { sendJsonError(resp, msg); return; }
                req.getSession().setAttribute("error", msg);
                resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                return;
            }
            if (coSoIdStr != null && !coSoIdStr.isEmpty()) {
                newAcc.setCoSoId(Integer.parseInt(coSoIdStr));
            }

            newAcc.setZaloId(req.getParameter("zaloId"));
            newAcc.setMessengerId(req.getParameter("messengerId"));
            newAcc.setMaNganHang(req.getParameter("maNganHang"));
            newAcc.setSoTaiKhoan(req.getParameter("soTaiKhoan"));
            newAcc.setViTriSoTruong(req.getParameter("viTriSoTruong"));
            newAcc.setGioiTinh(req.getParameter("gioiTinh"));

            String ngaySinhStr = req.getParameter("ngaySinh");
            if (ngaySinhStr != null && !ngaySinhStr.isEmpty()) {
                newAcc.setNgaySinh(org.example.util.ValidationUtils.parseDate(ngaySinhStr, "yyyy-MM-dd"));
            }

            newAcc.setIsLocked(false);

            String rawPassword = req.getParameter("password");
            if (rawPassword != null) rawPassword = rawPassword.trim();
            if (rawPassword == null || rawPassword.isEmpty()) {
                rawPassword = generateRandomPassword();
            } else {
                if (!org.example.util.ValidationUtil.isStrongPassword(rawPassword)) {
                    String msg = "Mật khẩu do admin tạo phải có tối thiểu 8 ký tự, bao gồm cả chữ hoa, chữ thường, số và ký tự đặc biệt!";
                    if (isAjax) { sendJsonError(resp, msg); return; }
                    req.getSession().setAttribute("error", msg);
                    resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                    return;
                }
            }
            newAcc.setPassword(org.mindrot.jbcrypt.BCrypt.hashpw(rawPassword, org.mindrot.jbcrypt.BCrypt.gensalt(12)));

            // Generate OTP manually so we can send both OTP and password in one email
            java.util.Random random = new java.util.Random();
            int otp = random.nextInt(900000) + 100000;
            String otpString = String.valueOf(otp);
            final String finalPassword = rawPassword;
            final String finalEmail = email;
            final String finalName = newAcc.getFullName();

            new Thread(() -> {
                try {
                    org.example.util.EmailUtil.sendEmail(finalEmail, "Kích hoạt tài khoản V-SPORT",
                        "Chào " + finalName + ",\n\n" +
                        "Tài khoản nhân viên của bạn đã được khởi tạo bởi Quản trị viên.\n" +
                        "Mật khẩu của bạn là: " + finalPassword + "\n\n" +
                        "Mã OTP kích hoạt tài khoản của bạn là: " + otpString);
                } catch (Exception e) {
                    logger.error("Lỗi gửi email kích hoạt đến: " + finalEmail, e);
                }
            }).start();

            req.getSession().setAttribute("otp", otpString);
            req.getSession().setAttribute("tempAccount", newAcc);
            req.getSession().setAttribute("authType", "ADMIN_ADD");
            req.getSession().setAttribute("otpAttempts", 0);
            req.getSession().setAttribute("resendCount", 0);
            req.getSession().setAttribute("needResend", false);

            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"requiresOtp\": true, \"email\": \"" + email + "\"}");
                return;
            }
            req.setAttribute("email", email);
            req.getRequestDispatcher("/auth/NhapMa.jsp").forward(req, resp);
            return;
        } else if ("softDelete".equals(action)) {
            int id = Integer.parseInt(req.getParameter("id"));
            TaiKhoan accToDelete = TaiKhoanDAO.getAccountById(id);
            TaiKhoan actingAdmin = (TaiKhoan) req.getSession().getAttribute("user");
            if (accToDelete != null && accToDelete.getRoleId() != 1) {
                boolean deleted = TaiKhoanDAO.softDeleteAccount(id, actingAdmin.getAccountId());
                if (deleted) {
                    String displayName = accToDelete.getFullName() != null ? accToDelete.getFullName() : accToDelete.getUsername();
                    new org.example.dao.impl.AdminTrashDAOImpl().log("Account", id, displayName, "Accounts",
                            null, actingAdmin.getAccountId(), null);
                    AuditLogService.log(req, actingAdmin,
                        AuditLogService.ACTION_SOFT_DELETE, AuditLogService.ENTITY_ACCOUNT,
                        String.valueOf(id), displayName,
                        "Admin chuyển tài khoản vào thùng rác");
                    req.getSession().setAttribute("trashMessage", "Đã chuyển vào thùng rác.");
                    req.getSession().setAttribute("trashUrl", req.getContextPath() + "/admin/thung-rac");
                    req.getSession().setAttribute("trashCountdownSeconds", 10);
                } else {
                    req.getSession().setAttribute("error", "Không thể chuyển tài khoản vào thùng rác.");
                }
            } else {
                req.getSession().setAttribute("error", "Không thể xóa tài khoản Quản trị viên.");
            }
            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
            return;
        } else if ("restore".equals(action)) {
            int id = Integer.parseInt(req.getParameter("id"));
            boolean restored = TaiKhoanDAO.restoreAccount(id);
            if (restored) {
                req.getSession().setAttribute("message", "Đã khôi phục tài khoản thành công.");
                TaiKhoan restoredAcc = TaiKhoanDAO.getAccountById(id);
                AuditLogService.log(req, (TaiKhoan) req.getSession().getAttribute("user"),
                    AuditLogService.ACTION_RESTORE, AuditLogService.ENTITY_ACCOUNT,
                    String.valueOf(id),
                    restoredAcc != null ? restoredAcc.getFullName() : String.valueOf(id),
                    "Admin khôi phục tài khoản");
            } else {
                req.getSession().setAttribute("error", "Không thể khôi phục tài khoản.");
            }
            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
            return;
        }
        resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
    }

    private void sendJsonError(HttpServletResponse resp, String message) throws java.io.IOException {
        resp.setContentType("application/json;charset=UTF-8");
        String escaped = message.replace("\\", "\\\\").replace("\"", "\\\"");
        resp.getWriter().write("{\"success\": false, \"error\": \"" + escaped + "\"}");
    }

    private String generateRandomPassword() {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*";
        java.security.SecureRandom random = new java.security.SecureRandom();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 8; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }
        return sb.toString();
    }

    private String generateUniqueUsername(String email) {
        String base = email.substring(0, email.indexOf('@'))
                .toLowerCase()
                .replaceAll("[^a-z0-9_]", "");
        if (base.length() < 3) base = (base + "vsport").substring(0, 6);
        if (base.length() > 30) base = base.substring(0, 30);
        if (!TaiKhoanDAO.kiemtraUsername(base)) return base;
        java.security.SecureRandom rng = new java.security.SecureRandom();
        for (int i = 0; i < 30; i++) {
            String cand = base + (100 + rng.nextInt(899900));
            if (!TaiKhoanDAO.kiemtraUsername(cand)) return cand;
        }
        return base + System.nanoTime() % 1_000_000_000L;
    }
}

