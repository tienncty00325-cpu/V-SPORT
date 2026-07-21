package org.example.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.model.TaiKhoan;
import org.example.dao.TaiKhoanDAO;
import org.example.dao.impl.TaiKhoanDAOImpl;

import java.io.IOException;

@WebServlet({"/nhapma", "/he-thong/xac-thuc-otp", "/resend-otp"})
public class XacThucOTPServlet extends HttpServlet {

    private TaiKhoanDAO TaiKhoanDAO = new TaiKhoanDAOImpl();

    /** JSP nhập mã quên mật khẩu theo portal của challenge. */
    private static String forgotOtpJsp(String portal) {
        return org.example.util.AuthPortalPolicy.PORTAL_INTERNAL.equals(portal)
                ? "/auth/NhapMaQuenMatKhauNoiBo.jsp"
                : "/auth/NhapMaQuenMatKhau.jsp";
    }

    /** JSP tạo mật khẩu mới theo portal. */
    private static String newPasswordJsp(String portal) {
        return org.example.util.AuthPortalPolicy.PORTAL_INTERNAL.equals(portal)
                ? "/auth/NhapMatKhauMoiNoiBo.jsp"
                : "/auth/NhapMatKauMoi.jsp";
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();
        if ("/resend-otp".equals(path)) {
            handleResendOTP(req, resp);
            return;
        }
        // GET /nhapma | /he-thong/xac-thuc-otp: chỉ hợp lệ khi có reset challenge
        // quên-mật-khẩu trong session, ĐÚNG portal của route (đích PRG sau khi gửi
        // OTP thành công). Truy cập trực tiếp bị đẩy về đầu luồng của portal đó.
        boolean internalRoute = "/he-thong/xac-thuc-otp".equals(path);
        HttpSession session = req.getSession(false);
        org.example.service.reset.PasswordResetChallenge challenge = session == null ? null
                : (org.example.service.reset.PasswordResetChallenge) session.getAttribute("resetChallenge");
        String challengePortal = session == null ? null : (String) session.getAttribute("resetPortal");
        boolean portalMatches = internalRoute
                ? org.example.util.AuthPortalPolicy.PORTAL_INTERNAL.equals(challengePortal)
                : !org.example.util.AuthPortalPolicy.PORTAL_INTERNAL.equals(challengePortal);
        if (session != null && "FORGOT_PASSWORD".equals(session.getAttribute("authType"))
                && challenge != null && !challenge.isUsed() && portalMatches) {
            req.setAttribute("email", challenge.getMaskedDestination());
            req.getRequestDispatcher(forgotOtpJsp(challengePortal)).forward(req, resp);
        } else {
            resp.sendRedirect(req.getContextPath()
                    + (internalRoute ? "/he-thong/quen-mat-khau" : "/quenmatkhau"));
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();
        if ("/resend-otp".equals(path)) {
            handleResendOTP(req, resp);
        } else {
            handleVerifyOTP(req, resp);
        }
    }

    private void handleVerifyOTP(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        String userOtp = req.getParameter("otp");
        String sessionOtp = (String) session.getAttribute("otp");
        String authType = (String) session.getAttribute("authType"); // REGISTER, FORGOT_PASSWORD hoặc ADMIN_ADD
        String email = req.getParameter("email");
        req.setAttribute("email", email);

        // Luồng quên mật khẩu dùng challenge băm OTP + expiry + attempt limit riêng.
        if ("FORGOT_PASSWORD".equals(authType)) {
            handleForgotPasswordVerify(req, resp, session, userOtp);
            return;
        }

        String requestedWith = req.getHeader("X-Requested-With");
        boolean isAjax = "XMLHttpRequest".equals(requestedWith);

        Boolean needResend = (Boolean) session.getAttribute("needResend");
        boolean isAdminOrManagerFlow = "ADMIN_ADD".equals(authType) || "ADMIN_EDIT".equals(authType) || "MANAGER_EDIT".equals(authType) || "MANAGER_ADD".equals(authType);
        if (isAdminOrManagerFlow && needResend != null && needResend) {
            req.setAttribute("loi", "Bạn đã nhập sai 5 lần. Vui lòng nhấn 'Gửi lại ngay' để nhận mã OTP mới.");
            req.getRequestDispatcher("/auth/NhapMa.jsp").forward(req, resp);
            return;
        }

        if (sessionOtp == null || userOtp == null || !userOtp.equals(sessionOtp)) {
            if (isAdminOrManagerFlow) {
                Integer attempts = (Integer) session.getAttribute("otpAttempts");
                if (attempts == null) {
                    attempts = 0;
                }
                attempts++;
                session.setAttribute("otpAttempts", attempts);

                Integer resendCount = (Integer) session.getAttribute("resendCount");
                if (resendCount == null) {
                    resendCount = 0;
                }

                if (resendCount == 0) {
                    if (attempts >= 5) {
                        session.setAttribute("needResend", true);
                        session.removeAttribute("otp");
                        req.setAttribute("loi", "Bạn đã nhập sai 5 lần. Vui lòng nhấn 'Gửi lại ngay' để nhận mã OTP mới.");
                        req.getRequestDispatcher("/auth/NhapMa.jsp").forward(req, resp);
                        return;
                    } else {
                        req.setAttribute("loi", "Mã xác thực không chính xác. Bạn còn " + (5 - attempts) + " lần thử.");
                        req.getRequestDispatcher("/auth/NhapMa.jsp").forward(req, resp);
                        return;
                    }
                } else {
                    if (attempts >= 3) {
                        // Kick back to admin page with error
                        session.removeAttribute("otp");
                        session.removeAttribute("tempAccount");
                        session.removeAttribute("authType");
                        session.removeAttribute("otpAttempts");
                        session.removeAttribute("resendCount");
                        session.removeAttribute("needResend");
                        String errorMsg = ("ADMIN_EDIT".equals(authType) || "MANAGER_EDIT".equals(authType))
                            ? "Cập nhật tài khoản thất bại vì không nhập đúng OTP!"
                            : "Tạo tài khoản thất bại vì không nhập đúng OTP!";
                        session.setAttribute("error", errorMsg);
                        TaiKhoan loggedInUser = (TaiKhoan) session.getAttribute("user");
                        if (isAjax) {
                            resp.setContentType("application/json;charset=UTF-8");
                            resp.getWriter().write("{\"success\": false, \"loi\": \"" + errorMsg + "\", \"redirect\": \"" + (loggedInUser != null && loggedInUser.getRoleId() == 2 ? "/manager/nhan-su" : "/admin/nhan-su") + "\"}");
                            return;
                        }
                        if (loggedInUser != null && loggedInUser.getRoleId() == 2) {
                            resp.sendRedirect(req.getContextPath() + "/manager/nhan-su");
                        } else {
                            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                        }
                        return;
                    } else {
                        req.setAttribute("loi", "Mã xác thực mới không chính xác. Bạn còn " + (3 - attempts) + " lần thử.");
                        req.getRequestDispatcher("/auth/NhapMa.jsp").forward(req, resp);
                        return;
                    }
                }
            } else {
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": false, \"loi\": \"Mã xác thực không chính xác hoặc đã hết hạn.\"}");
                    return;
                }
                req.setAttribute("loi", "Mã xác thực không chính xác hoặc đã hết hạn.");
                req.getRequestDispatcher("/auth/NhapMa.jsp").forward(req, resp);
                return;
            }
        }

        // Xóa OTP và attempts sau khi dùng xong
        session.removeAttribute("otp");
        session.removeAttribute("otpAttempts");
        session.removeAttribute("resendCount");
        session.removeAttribute("needResend");

        if ("REGISTER".equals(authType) || "ADMIN_ADD".equals(authType) || "ADMIN_EDIT".equals(authType) || "MANAGER_EDIT".equals(authType) || "MANAGER_ADD".equals(authType)) {
            // Xử lý hoàn tất đăng ký hoặc admin thêm tài khoản
            TaiKhoan tempAccount = (TaiKhoan) session.getAttribute("tempAccount");
            String[] tempSports = (String[]) session.getAttribute("tempSports");

            if (tempAccount == null) {
                if ("ADMIN_ADD".equals(authType) || "ADMIN_EDIT".equals(authType)) {
                    resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                } else if ("MANAGER_EDIT".equals(authType) || "MANAGER_ADD".equals(authType)) {
                    if (isAjax) {
                        resp.setContentType("application/json;charset=UTF-8");
                        resp.getWriter().write("{\"success\": false, \"loi\": \"Phiên làm việc đã hết hạn. Vui lòng thử lại.\"}");
                        return;
                    }
                    resp.sendRedirect(req.getContextPath() + "/manager/nhan-su");
                } else {
                    if (isAjax) {
                        resp.setContentType("application/json;charset=UTF-8");
                        resp.getWriter().write("{\"success\": false, \"loi\": \"Phiên làm việc đã hết hạn. Vui lòng đăng ký lại.\"}");
                        return;
                    }
                    resp.sendRedirect(req.getContextPath() + "/dangky");
                }
                return;
            }

            if ("ADMIN_ADD".equals(authType)) {
                // Double check email uniqueness right before adding
                if (tempAccount.getEmail() != null && !tempAccount.getEmail().trim().isEmpty()) {
                    if (TaiKhoanDAO.kiemtraEmail(tempAccount.getEmail().trim())) {
                        session.setAttribute("error", "Email đã tồn tại trên hệ thống!");
                        if (isAjax) {
                            resp.setContentType("application/json;charset=UTF-8");
                            resp.getWriter().write("{\"success\": false, \"loi\": \"Email đã tồn tại trên hệ thống!\"}");
                            return;
                        }
                        TaiKhoan loggedInUser = (TaiKhoan) session.getAttribute("user");
                        if (loggedInUser != null && loggedInUser.getRoleId() == 2) {
                            resp.sendRedirect(req.getContextPath() + "/manager/nhan-su");
                        } else {
                            resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                        }
                        return;
                    }
                }

                // Admin thêm tài khoản trực tiếp sau khi xác thực thành công
                TaiKhoanDAO.addAccountByAdmin(tempAccount);

                session.removeAttribute("tempAccount");
                session.removeAttribute("tempSports");
                session.removeAttribute("authType");

                session.setAttribute("message", "Thêm tài khoản thành công!");
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": true, \"message\": \"Thêm tài khoản thành công!\"}");
                    return;
                }
                TaiKhoan loggedInUser = (TaiKhoan) session.getAttribute("user");
                if (loggedInUser != null && loggedInUser.getRoleId() == 2) {
                    resp.sendRedirect(req.getContextPath() + "/manager/nhan-su");
                } else {
                    resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                }
            } else if ("MANAGER_ADD".equals(authType)) {
                // Double check email uniqueness right before adding
                if (tempAccount.getEmail() != null && !tempAccount.getEmail().trim().isEmpty()) {
                    if (TaiKhoanDAO.kiemtraEmail(tempAccount.getEmail().trim())) {
                        session.setAttribute("error", "Email đã tồn tại trên hệ thống!");
                        session.removeAttribute("tempAccount");
                        session.removeAttribute("tempRawPassword");
                        session.removeAttribute("tempManagerAccountId");
                        session.removeAttribute("authType");
                        if (isAjax) {
                            resp.setContentType("application/json;charset=UTF-8");
                            resp.getWriter().write("{\"success\": false, \"loi\": \"Email đã tồn tại trên hệ thống!\"}");
                            return;
                        }
                        resp.sendRedirect(req.getContextPath() + "/manager/nhan-su");
                        return;
                    }
                }

                // Manager thêm nhân viên sau khi email được xác thực qua OTP
                boolean saved = TaiKhoanDAO.addAccountByAdmin(tempAccount);
                if (!saved) {
                    session.removeAttribute("tempAccount");
                    session.removeAttribute("tempRawPassword");
                    session.removeAttribute("tempManagerAccountId");
                    session.removeAttribute("authType");
                    if (isAjax) {
                        resp.setContentType("application/json;charset=UTF-8");
                        resp.getWriter().write("{\"success\": false, \"loi\": \"Lỗi hệ thống khi tạo tài khoản. Vui lòng thử lại hoặc liên hệ quản trị viên.\"}");
                        return;
                    }
                    resp.sendRedirect(req.getContextPath() + "/manager/nhan-su");
                    return;
                }

                // Gửi email thông báo kích hoạt kèm mật khẩu
                String rawPwd = (String) session.getAttribute("tempRawPassword");
                final String finalEmail = tempAccount.getEmail();
                final String finalUsername = tempAccount.getUsername();
                final String finalName = tempAccount.getFullName() != null ? tempAccount.getFullName() : finalUsername;
                final String finalPwd = rawPwd != null ? rawPwd : "(đã được thiết lập)";
                new Thread(() -> {
                    try {
                        org.example.util.EmailUtil.sendEmail(finalEmail, "Kích hoạt tài khoản V-SPORT",
                            "Chào " + finalName + ",\n\n" +
                            "Tài khoản nhân viên của bạn đã được tạo bởi Quản lý.\n" +
                            "Tên đăng nhập: " + finalUsername + "\n" +
                            "Mật khẩu: " + finalPwd + "\n\n" +
                            "Vui lòng đăng nhập và đổi mật khẩu ngay sau lần đầu tiên.");
                    } catch (Exception ignored) {}
                }).start();

                // Audit log
                TaiKhoan loggedInUser2 = (TaiKhoan) session.getAttribute("user");
                if (loggedInUser2 != null) {
                    try {
                        org.example.service.AuditLogService.log(req, loggedInUser2,
                            org.example.service.AuditLogService.ACTION_ADD_STAFF,
                            org.example.service.AuditLogService.ENTITY_ACCOUNT,
                            String.valueOf(tempAccount.getAccountId()), finalName,
                            "Manager thêm nhân viên vào chi nhánh (xác thực OTP email)");
                    } catch (Exception ignored) {}
                }

                session.removeAttribute("tempAccount");
                session.removeAttribute("tempRawPassword");
                session.removeAttribute("tempManagerAccountId");
                session.removeAttribute("authType");

                session.setAttribute("message", "Thêm nhân viên thành công!");
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": true, \"message\": \"Thêm nhân viên thành công!\"}");
                    return;
                }
                resp.sendRedirect(req.getContextPath() + "/manager/nhan-su");
            } else if ("ADMIN_EDIT".equals(authType) || "MANAGER_EDIT".equals(authType)) {
                // Double check email uniqueness right before updating
                if (tempAccount.getEmail() != null && !tempAccount.getEmail().trim().isEmpty()) {
                    TaiKhoan oldAcc = TaiKhoanDAO.getAccountById(tempAccount.getAccountId());
                    if (oldAcc != null && !tempAccount.getEmail().equalsIgnoreCase(oldAcc.getEmail())) {
                        if (TaiKhoanDAO.kiemtraEmail(tempAccount.getEmail().trim())) {
                            session.setAttribute("error", "Email đã tồn tại trên hệ thống!");
                            if ("MANAGER_EDIT".equals(authType)) {
                                resp.sendRedirect(req.getContextPath() + "/manager/nhan-su");
                            } else {
                                resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                            }
                            return;
                        }
                    }
                }

                // Cập nhật tài khoản sau khi xác thực OTP thành công
                TaiKhoanDAO.updateAccount(tempAccount);

                session.removeAttribute("tempAccount");
                session.removeAttribute("tempSports");
                session.removeAttribute("authType");

                session.setAttribute("message", "Cập nhật thông tin tài khoản thành công!");
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": true, \"message\": \"Cập nhật thông tin tài khoản thành công!\"}");
                    return;
                }
                if ("MANAGER_EDIT".equals(authType)) {
                    resp.sendRedirect(req.getContextPath() + "/manager/nhan-su");
                } else {
                    resp.sendRedirect(req.getContextPath() + "/admin/nhan-su");
                }
            } else {
                // Khách tự đăng ký
                if (tempAccount.getEmail() != null && !tempAccount.getEmail().trim().isEmpty()) {
                    if (TaiKhoanDAO.kiemtraEmail(tempAccount.getEmail().trim())) {
                        if (isAjax) {
                            resp.setContentType("application/json;charset=UTF-8");
                            resp.getWriter().write("{\"success\": false, \"loi\": \"Email đã tồn tại trên hệ thống!\"}");
                            return;
                        }
                        req.setAttribute("loi", "Email đã tồn tại trên hệ thống!");
                        req.getRequestDispatcher("/auth/DangKy.jsp").forward(req, resp);
                        return;
                    }
                }

                String ketQua = TaiKhoanDAO.dangKyKhachHang(
                    tempAccount,
                    tempSports
                );

                session.removeAttribute("tempAccount");
                session.removeAttribute("tempSports");
                session.removeAttribute("authType");

                if (ketQua.contains("thành công")) {
                    if (isAjax) {
                        resp.setContentType("application/json;charset=UTF-8");
                        resp.getWriter().write("{\"success\": true, \"step\": \"register-success\", \"thongbao\": \"Đăng ký thành công! Vui lòng đăng nhập với tài khoản của bạn.\"}");
                        return;
                    }
                    req.setAttribute("thongbao", "Đăng ký thành công! Vui lòng đăng nhập với tài khoản của bạn.");
                    req.setAttribute("username", tempAccount.getUsername());
                    req.getRequestDispatcher("/auth/DangNhap.jsp").forward(req, resp);
                } else {
                    if (isAjax) {
                        resp.setContentType("application/json;charset=UTF-8");
                        resp.getWriter().write("{\"success\": false, \"loi\": \"Lỗi hệ thống khi lưu tài khoản. Vui lòng thử lại!\"}");
                        return;
                    }
                    req.setAttribute("loi", "Lỗi hệ thống khi lưu tài khoản. Vui lòng thử lại!");
                    req.getRequestDispatcher("/auth/DangKy.jsp").forward(req, resp);
                }
            }

        } else if ("FORGOT_PASSWORD".equals(authType)) {
            // Xác thực thành công cho quên mật khẩu, chuyển sang trang nhập pass mới
            session.setAttribute("isVerified", true); // Đánh dấu đã xác thực OTP thành công
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": true, \"step\": \"reset-password\"}");
                return;
            }
            req.getRequestDispatcher("/auth/NhapMatKauMoi.jsp").forward(req, resp);
        }
    }

    /**
     * Xác thực OTP quên mật khẩu bằng PasswordResetChallenge (hash + expiry +
     * attempt limit + one-time-use, decoy chống enumeration).
     */
    private void handleForgotPasswordVerify(HttpServletRequest req, HttpServletResponse resp,
                                            HttpSession session, String userOtp)
            throws ServletException, IOException {
        String requestedWith = req.getHeader("X-Requested-With");
        boolean isAjax = "XMLHttpRequest".equals(requestedWith);

        org.example.service.reset.PasswordResetChallenge challenge =
                (org.example.service.reset.PasswordResetChallenge) session.getAttribute("resetChallenge");
        String portal = (String) session.getAttribute("resetPortal");
        boolean internal = org.example.util.AuthPortalPolicy.PORTAL_INTERNAL.equals(portal);
        String requestUrl = req.getContextPath() + (internal ? "/he-thong/quen-mat-khau" : "/quenmatkhau");

        if (challenge == null) {
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"Phiên đặt lại mật khẩu đã hết hạn. Vui lòng thực hiện lại.\"}");
                return;
            }
            resp.sendRedirect(requestUrl);
            return;
        }

        req.setAttribute("email", challenge.getMaskedDestination());
        String loi;
        switch (challenge.verify(userOtp == null ? "" : userOtp.trim(), System.currentTimeMillis())) {
            case OK:
                session.setAttribute("isVerified", true);
                session.removeAttribute("resetChallenge");
                org.apache.logging.log4j.LogManager.getLogger(XacThucOTPServlet.class)
                        .info("PASSWORD_RESET_VERIFIED portal={}", portal);
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": true, \"step\": \"reset-password\"}");
                    return;
                }
                req.getRequestDispatcher(newPasswordJsp(portal)).forward(req, resp);
                return;
            case EXPIRED:
            case USED:
                loi = "Mã xác thực không hợp lệ hoặc đã hết hạn. Vui lòng yêu cầu mã mới.";
                break;
            case LOCKED:
                loi = "Bạn đã nhập sai quá số lần cho phép. Vui lòng yêu cầu mã mới.";
                break;
            default:
                loi = "Mã xác thực không chính xác.";
        }
        org.apache.logging.log4j.LogManager.getLogger(XacThucOTPServlet.class)
                .info("PASSWORD_RESET_FAILED portal={} attempts={}", portal, challenge.getAttemptCount());
        if (isAjax) {
            resp.setContentType("application/json;charset=UTF-8");
            resp.getWriter().write("{\"success\": false, \"loi\": \"" + loi + "\"}");
            return;
        }
        req.setAttribute("loi", loi);
        req.getRequestDispatcher(forgotOtpJsp(portal)).forward(req, resp);
    }

    /** Gửi lại mã quên mật khẩu: cooldown 60s, tối đa 5 lần, mã cũ bị vô hiệu. */
    private void handleForgotPasswordResend(HttpServletRequest req, HttpServletResponse resp,
                                            HttpSession session, boolean isAjax)
            throws ServletException, IOException {
        org.example.service.reset.PasswordResetChallenge challenge =
                (org.example.service.reset.PasswordResetChallenge) session.getAttribute("resetChallenge");
        String portal = (String) session.getAttribute("resetPortal");
        boolean internal = org.example.util.AuthPortalPolicy.PORTAL_INTERNAL.equals(portal);
        String requestUrl = req.getContextPath() + (internal ? "/he-thong/quen-mat-khau" : "/quenmatkhau");

        if (challenge == null || challenge.isUsed()) {
            resp.sendRedirect(requestUrl);
            return;
        }

        req.setAttribute("email", challenge.getMaskedDestination());
        long now = System.currentTimeMillis();
        if (!challenge.canResend(now)) {
            long wait = challenge.resendWaitSeconds(now);
            String loi = wait > 0
                    ? "Vui lòng chờ " + wait + " giây trước khi yêu cầu mã mới."
                    : "Bạn đã yêu cầu gửi lại quá số lần cho phép. Vui lòng thực hiện lại từ đầu.";
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"" + loi + "\"}");
                return;
            }
            req.setAttribute("loi", loi);
            req.getRequestDispatcher(forgotOtpJsp(portal)).forward(req, resp);
            return;
        }

        // Gửi ĐỒNG BỘ mã mới; chỉ vô hiệu mã cũ khi email đi thành công.
        String newOtp = org.example.service.reset.ResetSecurityUtil.generateOtp();
        try {
            org.example.util.EmailUtil.sendEmail(challenge.getAccountEmail(),
                    "V-SPORT — Mã xác thực đặt lại mật khẩu",
                    "Mã xác thực đặt lại mật khẩu V-SPORT mới của bạn là: " + newOtp + "\n\n"
                    + "Mã có hiệu lực trong 10 phút và chỉ dùng được một lần.\n"
                    + "Nếu bạn không yêu cầu, vui lòng bỏ qua email này.");
        } catch (Exception e) {
            org.apache.logging.log4j.LogManager.getLogger(XacThucOTPServlet.class)
                    .error("Lỗi gửi lại email đặt lại mật khẩu: {}", e.getMessage());
            String loiGui = "Hiện chưa thể gửi mã xác thực. Vui lòng thử lại sau.";
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"" + loiGui + "\"}");
                return;
            }
            req.setAttribute("loi", loiGui);
            req.getRequestDispatcher(forgotOtpJsp(portal)).forward(req, resp);
            return;
        }
        challenge.applyResend(newOtp, now);

        String thongbao = "Mã xác thực mới đã được gửi.";
        if (isAjax) {
            resp.setContentType("application/json;charset=UTF-8");
            resp.getWriter().write("{\"success\": true, \"thongbao\": \"" + thongbao + "\"}");
            return;
        }
        req.setAttribute("thongbao", thongbao);
        req.getRequestDispatcher(forgotOtpJsp(portal)).forward(req, resp);
    }

    private void handleResendOTP(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        String authType = (String) session.getAttribute("authType");

        String requestedWithResend = req.getHeader("X-Requested-With");
        boolean isAjaxResend = "XMLHttpRequest".equals(requestedWithResend);
        if ("FORGOT_PASSWORD".equals(authType)) {
            handleForgotPasswordResend(req, resp, session, isAjaxResend);
            return;
        }

        String email = null;
        String fullName = "";

        if ("REGISTER".equals(authType) || "ADMIN_ADD".equals(authType) || "ADMIN_EDIT".equals(authType) || "MANAGER_EDIT".equals(authType) || "MANAGER_ADD".equals(authType)) {
            TaiKhoan tempAccount = (TaiKhoan) session.getAttribute("tempAccount");
            if (tempAccount != null) {
                email = tempAccount.getEmail();
                fullName = tempAccount.getFullName();
            }
        }
        
        String requestedWith = req.getHeader("X-Requested-With");
        boolean isAjax = "XMLHttpRequest".equals(requestedWith);

        if (email == null || email.trim().isEmpty()) {
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"Không tìm thấy thông tin email để gửi lại OTP. Vui lòng thực hiện lại.\"}");
                return;
            }
            req.setAttribute("loi", "Không tìm thấy thông tin email để gửi lại OTP. Vui lòng thực hiện lại.");
            req.getRequestDispatcher("/auth/NhapMa.jsp").forward(req, resp);
            return;
        }
        
        // Gửi OTP mới
        String otpString = "";
        if ("FORGOT_PASSWORD".equals(authType)) {
            otpString = TaiKhoanDAO.sendForgotPasswordOTP(email);
        } else {
            otpString = TaiKhoanDAO.sendRegistrationOTP(email, fullName);
        }
        
        session.setAttribute("otp", otpString);
        session.setAttribute("otpAttempts", 0); // Reset số lần thử khi gửi lại mã mới
        
        if (isAjax) {
            resp.setContentType("application/json;charset=UTF-8");
            resp.getWriter().write("{\"success\": true, \"thongbao\": \"Mã OTP mới đã được gửi thành công đến email của bạn.\"}");
            return;
        }

        req.setAttribute("email", email);
        req.setAttribute("thongbao", "Mã OTP mới đã được gửi thành công đến email của bạn.");
        req.getRequestDispatcher("/auth/NhapMa.jsp").forward(req, resp);
    }
}

