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
import org.example.service.FacilityAccessService;
import org.example.service.reset.SimpleRateLimiter;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;

@WebServlet({"/dangnhap", "/he-thong/dang-nhap"})
public class DangNhapServlet extends HttpServlet {

    private static final Logger LOGGER = LogManager.getLogger(DangNhapServlet.class);
    private TaiKhoanDAO TaiKhoanDAO = new TaiKhoanDAOImpl();
    private final FacilityAccessService facilityAccessService = new FacilityAccessService();

    /**
     * Thông báo lỗi DUY NHẤT cho mọi trường hợp đăng nhập thất bại (không tồn tại,
     * sai mật khẩu, sai portal, tài khoản bị khóa...). Không được phân nhánh message
     * theo nguyên nhân — xem AuthPortalPolicy và phần xử lý portal-mismatch bên dưới.
     */
    private static final String GENERIC_LOGIN_FAIL_MSG =
            "Email, số điện thoại hoặc mật khẩu không chính xác.";

    /**
     * Hash BCrypt hợp lệ cố định, không gắn với tài khoản thật nào, dùng để chạy
     * một lần checkpw() "giả" khi không tìm thấy account — giữ thời gian phản hồi
     * gần bằng trường hợp account tồn tại nhưng sai mật khẩu (chống timing attack
     * dùng để dò email/sđt tồn tại trong hệ thống).
     */
    private static final String DUMMY_BCRYPT_HASH =
            "$2a$10$e8vvlxZLrBB2hA2WySDYK.ILi34msUoVA8ngsFmy/8gfSI.T4majO";

    private static final int LOGIN_ID_MAX_ATTEMPTS = 5;
    private static final int LOGIN_IP_MAX_ATTEMPTS = 20;
    private static final long LOGIN_RATE_WINDOW_MS = 5 * 60_000L;

    /** Portal của request: theo route GET hoặc hidden input POST (allowlist, không cấp role). */
    private String resolvePortal(HttpServletRequest req) {
        if ("/he-thong/dang-nhap".equals(req.getServletPath())) {
            return org.example.util.AuthPortalPolicy.PORTAL_INTERNAL;
        }
        return org.example.util.AuthPortalPolicy.parsePortal(req.getParameter("portal"));
    }

    /** JSP đăng nhập tương ứng với portal. */
    private String loginJspFor(String portal) {
        return org.example.util.AuthPortalPolicy.PORTAL_INTERNAL.equals(portal)
                ? "/auth/DangNhapNoiBo.jsp"
                : "/auth/DangNhap.jsp";
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // Phòng ngừa link logout sai trỏ về đây
        if ("logout".equals(req.getParameter("action"))) {
            resp.sendRedirect(req.getContextPath() + "/logout");
            return;
        }

        String portal = resolvePortal(req);
        req.setAttribute("portal", portal);

        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("user") != null) {
            TaiKhoan user = (TaiKhoan) session.getAttribute("user");
            String redirectUrl = req.getContextPath()
                    + org.example.util.RoleRedirectUtil.getHomePathByRoleId(user.getRoleId());
            resp.sendRedirect(redirectUrl);
        } else if ("true".equals(req.getParameter("facilityInactive"))) {
            // ActiveFacilityFilter vừa invalidate session vì cơ sở của tài khoản đã ngừng hoạt động.
            req.setAttribute("loi", "Cơ sở của tài khoản này đã ngừng hoạt động. Vui lòng liên hệ quản trị viên.");
            resp.sendRedirect(req.getContextPath() + "/index.jsp?auth=login&error=facilityInactive");
        } else {
            // Điều hướng sang trang chủ với biến auth để mở modal
            resp.sendRedirect(req.getContextPath() + "/index.jsp?auth=login");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String portal = resolvePortal(req);
        req.setAttribute("portal", portal);
        String loginMethod = "phone".equals(req.getParameter("loginMethod")) ? "phone" : "account";
        boolean isPhoneLogin = "phone".equals(loginMethod);
        String usernameOrEmail = req.getParameter("username");
        String rawPhone = req.getParameter("phone");
        String password = req.getParameter("password");
        req.setAttribute("loginMethod", loginMethod);

        String requestedWith = req.getHeader("X-Requested-With");
        boolean isAjax = "XMLHttpRequest".equals(requestedWith);

        String identifier = isPhoneLogin ? rawPhone : usernameOrEmail;
        if (identifier == null || identifier.trim().isEmpty() ||
                password == null || password.trim().isEmpty()) {

            String emptyMsg = isPhoneLogin
                    ? "Số điện thoại và mật khẩu không được để trống!"
                    : "Tài khoản và mật khẩu không được để trống!";
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"" + emptyMsg + "\"}");
                return;
            }

            req.setAttribute("loi", emptyMsg);
            req.getRequestDispatcher(loginJspFor(portal)).forward(req, resp);
            return;
        }

        String normalizedPhone = null;
        if (isPhoneLogin) {
            normalizedPhone = org.example.util.PhoneUtil.normalizeVN(rawPhone);
            if (normalizedPhone == null) {
                String invalidMsg = "Số điện thoại không hợp lệ. Vui lòng nhập số di động Việt Nam (0, +84 hoặc 84).";
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": false, \"loi\": \"" + invalidMsg + "\"}");
                    return;
                }
                req.setAttribute("loi", invalidMsg);
                req.setAttribute("phone", rawPhone);
                req.getRequestDispatcher(loginJspFor(portal)).forward(req, resp);
                return;
            }
        }

        // ===== Rate limit server-side (theo identifier chuẩn hóa và theo IP) =====
        // Áp dụng TRƯỚC khi lookup DB để một attacker không thể dùng độ trễ DB
        // làm oracle, và để chặn brute-force trước khi tốn một lần BCrypt.
        long now = System.currentTimeMillis();
        String normalizedIdentifierForKey = isPhoneLogin
                ? normalizedPhone
                : (usernameOrEmail == null ? "" : usernameOrEmail.trim().toLowerCase());
        String idKey = "login-id:" + portal + ":" + loginMethod + ":" + normalizedIdentifierForKey;
        String ipKey = "login-ip:" + portal + ":" + req.getRemoteAddr();
        if (!SimpleRateLimiter.SHARED.tryAcquire(idKey, LOGIN_ID_MAX_ATTEMPTS, LOGIN_RATE_WINDOW_MS, now)
                || !SimpleRateLimiter.SHARED.tryAcquire(ipKey, LOGIN_IP_MAX_ATTEMPTS, LOGIN_RATE_WINDOW_MS, now)) {
            LOGGER.warn("LOGIN_RATE_LIMITED portal={} method={} identifier={} ip={}",
                    portal, loginMethod, maskIdentifier(isPhoneLogin, usernameOrEmail, normalizedPhone), req.getRemoteAddr());
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"" + GENERIC_LOGIN_FAIL_MSG + "\"}");
                return;
            }
            req.setAttribute("loi", GENERIC_LOGIN_FAIL_MSG);
            req.setAttribute("username", usernameOrEmail);
            req.setAttribute("phone", rawPhone);
            req.getRequestDispatcher(loginJspFor(portal)).forward(req, resp);
            return;
        }

        TaiKhoan taiKhoan = null;
        boolean ambiguousPhone = false;
        String dbErrorMsg = null;
        try {
            if (isPhoneLogin) {
                // Tái sử dụng đúng pipeline xác thực: tra cứu account rồi so BCrypt,
                // phần kiểm tra trạng thái/cơ sở/session/redirect bên dưới dùng chung.
                java.util.List<TaiKhoan> matches = TaiKhoanDAO
                        .timTaiKhoanHoatDongTheoPhone(org.example.util.PhoneUtil.lookupVariants(normalizedPhone));
                if (matches.size() > 1) {
                    ambiguousPhone = true;
                    // Vẫn chạy một lần BCrypt "giả" để giữ thời gian phản hồi tương đồng
                    // với các nhánh khác — tránh việc riêng nhánh ambiguous phản hồi nhanh
                    // hơn hẳn và trở thành oracle cho việc dò số điện thoại tồn tại.
                    org.mindrot.jbcrypt.BCrypt.checkpw(password, DUMMY_BCRYPT_HASH);
                } else if (matches.size() == 1) {
                    if (org.mindrot.jbcrypt.BCrypt.checkpw(password, matches.get(0).getPassword())) {
                        taiKhoan = matches.get(0);
                    }
                } else {
                    // Không tìm thấy account nào theo số điện thoại: vẫn chạy BCrypt trên
                    // dummy hash cố định để thời gian phản hồi gần bằng trường hợp account
                    // tồn tại nhưng sai mật khẩu (chống timing attack dò số điện thoại).
                    org.mindrot.jbcrypt.BCrypt.checkpw(password, DUMMY_BCRYPT_HASH);
                }
            } else {
                taiKhoan = TaiKhoanDAO.dangNhapKhachHang(usernameOrEmail, password);
            }
        } catch (ExceptionInInitializerError e) {
            LOGGER.error("Lỗi khởi tạo cấu hình kết nối database: ", e);
            dbErrorMsg = getDatabaseErrorMessage(e);
        } catch (LinkageError e) {
            // Bắt thêm LinkageError để xử lý lỗi NoClassDefFoundError phát sinh từ lỗi ExceptionInInitializerError trước đó.
            LOGGER.error("Lỗi liên kết lớp (có thể do lỗi khởi tạo CSDL trước đó): ", e);
            dbErrorMsg = getDatabaseErrorMessage(e);
        } catch (RuntimeException e) {
            LOGGER.error("Lỗi runtime database: ", e);
            dbErrorMsg = getDatabaseErrorMessage(e);
        } catch (Exception e) {
            LOGGER.error("Lỗi kết nối database thông thường: ", e);
            dbErrorMsg = getDatabaseErrorMessage(e);
        }

        if (dbErrorMsg != null) {
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"" + dbErrorMsg + "\"}");
                return;
            }
            req.setAttribute("loi", dbErrorMsg);
            req.setAttribute("username", usernameOrEmail);
            req.setAttribute("phone", rawPhone);
            req.getRequestDispatcher(loginJspFor(portal)).forward(req, resp);
            return;
        }

        if (ambiguousPhone) {
            // Không tự chọn tài khoản khi một số điện thoại gắn với nhiều account.
            // Dùng đúng generic message — không tiết lộ rằng số điện thoại này tồn tại
            // và đang liên kết với (nhiều) tài khoản thật.
            LOGGER.warn("LOGIN_AMBIGUOUS_PHONE portal={} identifier={} ip={}",
                    portal, maskIdentifier(true, usernameOrEmail, normalizedPhone), req.getRemoteAddr());
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"" + GENERIC_LOGIN_FAIL_MSG + "\"}");
                return;
            }
            req.setAttribute("loi", GENERIC_LOGIN_FAIL_MSG);
            req.setAttribute("phone", rawPhone);
            req.getRequestDispatcher(loginJspFor(portal)).forward(req, resp);
            return;
        }

        // Đã gỡ bỏ chính sách hai cổng theo yêu cầu của hệ thống mới.
        // Bất kỳ role nào cũng có thể đăng nhập từ một giao diện duy nhất (AuthModal).
        // Sau khi đăng nhập thành công, RoleRedirectUtil sẽ tự động điều hướng đúng trang chủ của role đó.

        if (taiKhoan != null && taiKhoan.getCoSoId() != null
                && !facilityAccessService.isFacilityActive(taiKhoan.getCoSoId())) {
            LOGGER.warn("LOGIN_DISABLED_ACCOUNT accountId={} roleId={} coSoId={} ip={}",
                    taiKhoan.getAccountId(), taiKhoan.getRoleId(), taiKhoan.getCoSoId(), req.getRemoteAddr());
            String facilityInactiveMsg = "Cơ sở của tài khoản này đã ngừng hoạt động. Vui lòng liên hệ quản trị viên.";
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"code\": \"FACILITY_INACTIVE\", \"loi\": \""
                        + facilityInactiveMsg + "\"}");
                return;
            }
            req.setAttribute("loi", facilityInactiveMsg);
            req.setAttribute("username", usernameOrEmail);
            req.setAttribute("phone", rawPhone);
            req.getRequestDispatcher(loginJspFor(portal)).forward(req, resp);
            return;
        }

        if (taiKhoan != null) {
            // Invalidate session cũ để tránh nhầm tài khoản khi đăng nhập liên tiếp
            HttpSession oldSession = req.getSession(false);
            if (oldSession != null) {
                oldSession.invalidate();
            }
            HttpSession session = req.getSession(true);
            session.setAttribute("user", taiKhoan);
            session.setAttribute("roleId", taiKhoan.getRoleId());
            session.setAttribute("accountId", taiKhoan.getAccountId());
            session.setAttribute("fullName", taiKhoan.getFullName() != null ? taiKhoan.getFullName() : "");
            session.setAttribute("email", taiKhoan.getEmail() != null ? taiKhoan.getEmail() : "");

            String redirectUrl = req.getContextPath()
                    + org.example.util.RoleRedirectUtil.getHomePathByRoleId(taiKhoan.getRoleId());

            LOGGER.info("LOGIN_SUCCESS accountId={} roleId={} portal={} redirect={} ip={} userAgent={}",
                    taiKhoan.getAccountId(), taiKhoan.getRoleId(), portal, redirectUrl,
                    req.getRemoteAddr(), req.getHeader("User-Agent"));

            // Phản hồi kết quả đăng nhập thành công
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": true, \"redirectUrl\": \"" + redirectUrl + "\"}");
                return;
            }

            resp.sendRedirect(redirectUrl);

        } else {
            // Không tìm thấy account HOẶC sai mật khẩu: cùng một generic message,
            // không phân biệt nguyên nhân (chống account enumeration). Chi tiết thật
            // (không tìm thấy vs. sai mật khẩu) chỉ được ghi vào server log.
            LOGGER.warn("{} portal={} method={} identifier={} ip={}",
                    "LOGIN_ACCOUNT_NOT_FOUND",
                    portal, loginMethod, maskIdentifier(isPhoneLogin, usernameOrEmail, normalizedPhone),
                    req.getRemoteAddr());
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"" + GENERIC_LOGIN_FAIL_MSG + "\"}");
                return;
            }

            req.setAttribute("loi", GENERIC_LOGIN_FAIL_MSG);
            req.setAttribute("username", usernameOrEmail);
            req.setAttribute("phone", rawPhone);
            req.getRequestDispatcher(loginJspFor(portal)).forward(req, resp);
        }
    }

    /**
     * Che email/số điện thoại để ghi log audit mà không lộ toàn bộ identifier.
     * Email: n***@gmail.com — giữ ký tự đầu + domain.
     * Phone: 078****209 — giữ 3 số đầu + 3 số cuối.
     * Không phân biệt "wrong password" và "not found" ở đây — cả hai đều dùng
     * LOGIN_ACCOUNT_NOT_FOUND làm code chung để tránh vô tình tạo oracle qua log
     * code khác nhau bị lộ ra (ví dụ qua response timing/side channel khác).
     */
    private String maskIdentifier(boolean isPhone, String usernameOrEmail, String normalizedPhone) {
        if (isPhone) {
            String p = normalizedPhone != null ? normalizedPhone : "";
            if (p.length() <= 6) return "***";
            return p.substring(0, 3) + "****" + p.substring(p.length() - 3);
        }
        String v = usernameOrEmail != null ? usernameOrEmail.trim() : "";
        int at = v.indexOf('@');
        if (at > 0) {
            String domain = v.substring(at + 1);
            return v.charAt(0) + "***@" + domain;
        }
        if (v.isEmpty()) return "***";
        return v.charAt(0) + "***";
    }

    private boolean isDatabaseConfigError(Throwable e) {
        Throwable current = e;
        while (current != null) {
            String msg = current.getMessage();
            if (msg != null) {
                if (msg.contains("DB_URL") ||
                    msg.contains("DB_USERNAME") ||
                    msg.contains("DB_PASSWORD") ||
                    msg.contains("Cấu hình bắt buộc bị thiếu") ||
                    msg.contains("Error initializing HikariCP data source")) {
                    return true;
                }
            }
            if (current instanceof IllegalStateException) {
                return true;
            }
            current = current.getCause();
        }
        return false;
    }

    private boolean isDatabaseConnectionError(Throwable e) {
        Throwable current = e;
        while (current != null) {
            String msg = current.getMessage();
            if (msg != null) {
                if (msg.contains("Connection refused") ||
                    msg.contains("The TCP/IP connection") ||
                    msg.contains("Login failed") ||
                    msg.contains("HikariPool") ||
                    msg.contains("SQLServerException")) {
                    return true;
                }
            }
            current = current.getCause();
        }
        return false;
    }

    private String getDatabaseErrorMessage(Throwable t) {
        if (isDatabaseConfigError(t)) {
            return "Hệ thống chưa được cấu hình kết nối database. Vui lòng kiểm tra DB_URL, DB_USERNAME, DB_PASSWORD.";
        }
        if (isDatabaseConnectionError(t)) {
            return "Không thể kết nối database. Vui lòng kiểm tra SQL Server hoặc cấu hình kết nối.";
        }
        return "Lỗi kết nối cơ sở dữ liệu. Vui lòng liên hệ quản trị viên hoặc kiểm tra cấu hình hệ thống!";
    }
}

