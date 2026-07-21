package org.example.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.dao.TaiKhoanDAO;
import org.example.dao.impl.TaiKhoanDAOImpl;

import java.io.IOException;

@WebServlet({"/nhapmatkhaumoi", "/he-thong/dat-lai-mat-khau"})
public class DatLaiMatKhauServlet extends HttpServlet {

    private TaiKhoanDAO TaiKhoanDAO = new TaiKhoanDAOImpl();

    /** JSP tạo mật khẩu mới theo portal của reset context trong session. */
    private static String newPasswordJsp(HttpSession session) {
        boolean internal = session != null && org.example.util.AuthPortalPolicy.PORTAL_INTERNAL
                .equals(session.getAttribute("resetPortal"));
        return internal ? "/auth/NhapMatKhauMoiNoiBo.jsp" : "/auth/NhapMatKauMoi.jsp";
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        boolean internalRoute = "/he-thong/dat-lai-mat-khau".equals(req.getServletPath());
        if (session.getAttribute("isVerified") == null) {
            resp.sendRedirect(req.getContextPath()
                    + (internalRoute ? "/he-thong/quen-mat-khau" : "/quenmatkhau"));
            return;
        }
        req.getRequestDispatcher(newPasswordJsp(session)).forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        
        String requestedWith = req.getHeader("X-Requested-With");
        boolean isAjax = "XMLHttpRequest".equals(requestedWith);

        // Bảo mật: Kiểm tra xem đã qua bước OTP chưa
        if (session.getAttribute("isVerified") == null) {
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"Yêu cầu không hợp lệ. Vui lòng xác thực OTP trước.\"}");
                return;
            }
            resp.sendRedirect(req.getContextPath() + "/quenmatkhau");
            return;
        }

        String email = (String) session.getAttribute("resetEmail");
        String portal = (String) session.getAttribute("resetPortal");
        boolean internal = org.example.util.AuthPortalPolicy.PORTAL_INTERNAL.equals(portal);

        // Challenge decoy không bao giờ đến được đây (verify luôn fail), nhưng vẫn chặn cứng.
        if (email == null || email.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + (internal ? "/he-thong/quen-mat-khau" : "/quenmatkhau"));
            return;
        }

        String newPassword = req.getParameter("password");
        String confirmPassword = req.getParameter("confirm_password");

        if (newPassword != null) newPassword = newPassword.trim();
        if (confirmPassword != null) confirmPassword = confirmPassword.trim();

        // Validate password is not empty or just spaces
        if (newPassword == null || newPassword.isEmpty()) {
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"Mật khẩu không được để trống hoặc chỉ chứa khoảng trắng!\"}");
                return;
            }
            req.setAttribute("loi", "Mật khẩu không được để trống hoặc chỉ chứa khoảng trắng!");
            req.getRequestDispatcher(newPasswordJsp(session)).forward(req, resp);
            return;
        }

        if (!org.example.util.ValidationUtil.isStrongPassword(newPassword)) {
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"Mật khẩu phải có tối thiểu 8 ký tự, bao gồm cả chữ hoa, chữ thường, số và ký tự đặc biệt.\"}");
                return;
            }
            req.setAttribute("loi", "Mật khẩu phải có tối thiểu 8 ký tự, bao gồm cả chữ hoa, chữ thường, số và ký tự đặc biệt.");
            req.getRequestDispatcher(newPasswordJsp(session)).forward(req, resp);
            return;
        }

        // Optional: Reject passwords with spaces if required by business logic. Usually, spaces are allowed in passphrases, 
        // but trimming leading/trailing is good practice, or ensuring it's not ONLY spaces (handled above).
        if (newPassword == null || !newPassword.equals(confirmPassword)) {
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"Mật khẩu xác nhận không khớp!\"}");
                return;
            }
            req.setAttribute("loi", "Mật khẩu xác nhận không khớp!");
            req.getRequestDispatcher(newPasswordJsp(session)).forward(req, resp);
            return;
        }

        // Không cho đặt lại đúng mật khẩu hiện tại
        org.example.model.TaiKhoan current = TaiKhoanDAO.timTaiKhoanTheoEmail(email);
        if (current != null && current.getPassword() != null
                && org.mindrot.jbcrypt.BCrypt.checkpw(newPassword, current.getPassword())) {
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"Mật khẩu mới không được trùng với mật khẩu hiện tại.\"}");
                return;
            }
            req.setAttribute("loi", "Mật khẩu mới không được trùng với mật khẩu hiện tại.");
            req.getRequestDispatcher(newPasswordJsp(session)).forward(req, resp);
            return;
        }

        boolean success = TaiKhoanDAO.capNhatMatKhau(email, newPassword);

        if (success) {
            // Invalidate toàn bộ trạng thái reset — challenge one-time-use
            session.removeAttribute("isVerified");
            session.removeAttribute("resetEmail");
            session.removeAttribute("resetChallenge");
            session.removeAttribute("resetPortal");
            session.removeAttribute("authType");
            org.apache.logging.log4j.LogManager.getLogger(DatLaiMatKhauServlet.class)
                    .info("PASSWORD_RESET_COMPLETED portal={} accountId={}",
                            portal, current != null ? current.getAccountId() : null);
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": true, \"thongbao\": \"Đổi mật khẩu thành công! Vui lòng đăng nhập lại.\"}");
                return;
            }
            req.setAttribute("thongbao", "Đổi mật khẩu thành công! Vui lòng đăng nhập lại.");
            req.setAttribute("portal", internal ? "internal" : "customer");
            req.getRequestDispatcher(internal ? "/auth/DangNhapNoiBo.jsp" : "/auth/DangNhap.jsp").forward(req, resp);
        } else {
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\": false, \"loi\": \"Có lỗi xảy ra, vui lòng thử lại sau.\"}");
                return;
            }
            req.setAttribute("loi", "Có lỗi xảy ra, vui lòng thử lại sau.");
            req.getRequestDispatcher(newPasswordJsp(session)).forward(req, resp);
        }
    }
}

