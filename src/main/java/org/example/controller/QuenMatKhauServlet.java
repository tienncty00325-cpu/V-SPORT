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
import org.example.model.TaiKhoan;
import org.example.service.reset.PasswordResetChallenge;
import org.example.service.reset.ResetSecurityUtil;
import org.example.service.reset.SimpleRateLimiter;
import org.example.util.AuthPortalPolicy;
import org.example.util.EmailUtil;
import org.example.util.PhoneUtil;
import org.example.util.ValidationUtil;

import java.io.IOException;
import java.util.List;

/**
 * Bước 1 của luồng quên mật khẩu cho cả hai cổng:
 *  - Customer: GET/POST /quenmatkhau (tìm theo email hoặc số điện thoại)
 *  - Internal: GET/POST /he-thong/quen-mat-khau (chỉ email)
 *
 * Chỉ chuyển sang bước nhập mã khi tài khoản hợp lệ ĐÚNG portal và email OTP
 * đã gửi thành công (đồng bộ); mọi trường hợp không hợp lệ trả về message
 * generic tại chỗ, không tiết lộ role/trạng thái tài khoản.
 * OTP chỉ gửi qua email đã đăng ký; không có SMS provider nên phone chỉ dùng
 * để TÌM tài khoản (không fake SMS).
 */
@WebServlet({"/quenmatkhau", "/he-thong/quen-mat-khau"})
public class QuenMatKhauServlet extends HttpServlet {

    private static final Logger LOGGER = LogManager.getLogger(QuenMatKhauServlet.class);

    private static final String RATE_LIMIT_MSG =
            "Bạn đã yêu cầu quá nhiều lần. Vui lòng thử lại sau ít phút.";

    private static final int ID_MAX_REQUESTS = 5;
    private static final int IP_MAX_REQUESTS = 12;
    private static final long WINDOW_MS = 15 * 60_000L;

    private TaiKhoanDAO taiKhoanDAO = new TaiKhoanDAOImpl();

    private String resolvePortal(HttpServletRequest req) {
        if ("/he-thong/quen-mat-khau".equals(req.getServletPath())) {
            return AuthPortalPolicy.PORTAL_INTERNAL;
        }
        return AuthPortalPolicy.parsePortal(req.getParameter("portal"));
    }

    private String requestJspFor(String portal) {
        return AuthPortalPolicy.PORTAL_INTERNAL.equals(portal)
                ? "/auth/QuenMatKhauNoiBo.jsp"
                : "/auth/QuenMatKhau.jsp";
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String portal = resolvePortal(req);
        // Quay lại trang nhập identifier ("Đổi email") = hủy challenge đang dở
        HttpSession session = req.getSession(false);
        if (session != null && "FORGOT_PASSWORD".equals(session.getAttribute("authType"))) {
            session.removeAttribute("resetChallenge");
            session.removeAttribute("resetEmail");
            session.removeAttribute("resetPortal");
            session.removeAttribute("authType");
            session.removeAttribute("isVerified");
        }
        // Điều hướng sang trang chủ với biến auth để mở modal quên mật khẩu
        resp.sendRedirect(req.getContextPath() + "/index.jsp?auth=forgot-password");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String portal = resolvePortal(req);
        boolean internal = AuthPortalPolicy.PORTAL_INTERNAL.equals(portal);
        req.setAttribute("portal", portal);

        // Internal chỉ tìm theo email công việc
        String method = (!internal && "phone".equals(req.getParameter("method"))) ? "phone" : "email";
        String email = trim(req.getParameter("email"));
        String phone = trim(req.getParameter("phone"));

        req.setAttribute("method", method);
        req.setAttribute("resetEmailInput", email);
        req.setAttribute("resetPhoneInput", phone);

        // ===== Validate format (không phải enumeration) =====
        String normalizedPhone = null;
        if ("email".equals(method)) {
            if (!ValidationUtil.isValidEmail(email)) {
                forwardError(req, resp, portal, "Email không hợp lệ. Vui lòng kiểm tra lại.");
                return;
            }
        } else {
            normalizedPhone = PhoneUtil.normalizeVN(phone);
            if (normalizedPhone == null) {
                forwardError(req, resp, portal, "Số điện thoại không hợp lệ. Vui lòng nhập số di động Việt Nam (0, +84 hoặc 84).");
                return;
            }
        }

        // ===== Rate limit server-side (theo identifier và theo IP) =====
        long now = System.currentTimeMillis();
        String idKey = "reset-id:" + method + ":" +
                ("email".equals(method) ? email.toLowerCase() : normalizedPhone);
        String ipKey = "reset-ip:" + req.getRemoteAddr();
        if (!SimpleRateLimiter.SHARED.tryAcquire(idKey, ID_MAX_REQUESTS, WINDOW_MS, now)
                || !SimpleRateLimiter.SHARED.tryAcquire(ipKey, IP_MAX_REQUESTS, WINDOW_MS, now)) {
            LOGGER.warn("PASSWORD_RESET_RATE_LIMITED portal={} method={}", portal, method);
            forwardError(req, resp, portal, RATE_LIMIT_MSG);
            return;
        }

        // ===== Tìm tài khoản và áp portal policy (không tiết lộ kết quả) =====
        TaiKhoan account = null;
        try {
            if ("email".equals(method)) {
                account = taiKhoanDAO.timTaiKhoanTheoEmail(email);
            } else {
                List<TaiKhoan> matches = taiKhoanDAO
                        .timTaiKhoanHoatDongTheoPhone(PhoneUtil.lookupVariants(normalizedPhone));
                account = matches.size() == 1 ? matches.get(0) : null;
            }
        } catch (Throwable t) {
            LOGGER.error("Lỗi tra cứu tài khoản quên mật khẩu: {}", t.getMessage(), t);
            forwardError(req, resp, portal, "Hệ thống đang bận. Vui lòng thử lại sau.");
            return;
        }

        // Đã gỡ bỏ chính sách AuthPortalPolicy.isRoleAllowed theo yêu cầu
        boolean eligible = account != null
                && !account.isLocked()
                && account.getEmail() != null
                && ValidationUtil.isValidEmail(account.getEmail());

        // Không đủ điều kiện: giữ nguyên trang nhập, KHÔNG tạo challenge, KHÔNG gửi mail.
        // Message generic — không tiết lộ role/trạng thái/tồn tại chi tiết.
        if (!eligible) {
            LOGGER.info("PASSWORD_RESET_REQUESTED portal={} method={} account=none-or-ineligible",
                    portal, method);
            forwardError(req, resp, portal, "email".equals(method)
                    ? "Không thể gửi mã đến email này. Vui lòng kiểm tra lại thông tin."
                    : "Không thể gửi mã với số điện thoại này. Vui lòng kiểm tra lại thông tin.");
            return;
        }

        // Masked destination: với email-method là chính email người dùng nhập;
        // với phone-method chỉ hiển thị email đã che để không lộ địa chỉ đầy đủ.
        String masked = ResetSecurityUtil.maskEmail(account.getEmail());

        String otp = ResetSecurityUtil.generateOtp();
        PasswordResetChallenge challenge = PasswordResetChallenge.create(
                account.getEmail(), masked, portal, otp, now);

        // Gửi ĐỒNG BỘ: chỉ khi email đi thành công mới chuyển sang bước nhập mã.
        try {
            sendResetEmail(account.getEmail(),
                    account.getFullName() != null ? account.getFullName() : "Quý khách", otp);
        } catch (Exception e) {
            LOGGER.error("Lỗi gửi email đặt lại mật khẩu: {}", e.getMessage());
            forwardError(req, resp, portal, "Hiện chưa thể gửi mã xác thực. Vui lòng thử lại sau.");
            return;
        }
        LOGGER.info("PASSWORD_RESET_REQUESTED portal={} method={} accountId={}",
                portal, method, account.getAccountId());

        HttpSession session = req.getSession(true);
        session.setAttribute("resetChallenge", challenge);
        session.setAttribute("authType", "FORGOT_PASSWORD");
        session.setAttribute("resetEmail", account.getEmail());
        session.setAttribute("resetPortal", portal);
        session.removeAttribute("isVerified");
        session.removeAttribute("otp");

        // PRG: redirect sang trang nhập mã đúng portal (refresh không gửi lại form)
        resp.sendRedirect(req.getContextPath() + (internal ? "/he-thong/xac-thuc-otp" : "/nhapma"));
    }

    private void forwardError(HttpServletRequest req, HttpServletResponse resp, String portal, String msg)
            throws ServletException, IOException {
        req.setAttribute("loi", msg);
        req.getRequestDispatcher(requestJspFor(portal)).forward(req, resp);
    }

    /** Gửi OTP qua EmailUtil hiện có — ĐỒNG BỘ, ném exception khi gửi thất bại. */
    private void sendResetEmail(String email, String fullName, String otp) throws Exception {
        EmailUtil.sendEmail(email, "V-SPORT — Mã xác thực đặt lại mật khẩu",
                "Chào " + fullName + ",\n\n"
                + "Mã xác thực đặt lại mật khẩu V-SPORT của bạn là: " + otp + "\n\n"
                + "Mã có hiệu lực trong 10 phút và chỉ dùng được một lần.\n"
                + "Không chia sẻ mã này với bất kỳ ai, kể cả nhân viên V-SPORT.\n\n"
                + "Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.");
    }

    private static String trim(String s) {
        return s == null ? "" : s.trim();
    }
}
