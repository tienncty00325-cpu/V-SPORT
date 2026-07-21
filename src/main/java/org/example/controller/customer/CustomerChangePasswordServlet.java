package org.example.controller.customer;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.model.TaiKhoan;
import org.example.util.RoleRedirectUtil;

import java.io.IOException;

/**
 * Trang "Đổi mật khẩu" (full-screen) cho Customer. Thay thế modal đổi mật khẩu
 * cũ trong trang Tài khoản: mở như một trang riêng, không sidebar / không bottom
 * nav / không popup.
 *
 * Servlet này CHỈ phục vụ GET (render trang, có kiểm tra đăng nhập). Việc đổi
 * mật khẩu thật sự vẫn đi qua endpoint an toàn sẵn có
 * {@code POST /account/update-profile} với {@code action=changePassword}, nơi đã
 * xác thực mật khẩu hiện tại bằng BCrypt, chặn trùng mật khẩu cũ, kiểm tra độ
 * mạnh và hash mật khẩu mới trước khi lưu. Không có mật khẩu/hash nào được đưa
 * ra JSP hay ghi log.
 */
@WebServlet("/customer/doi-mat-khau")
public class CustomerChangePasswordServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan sessionUser = session != null ? (TaiKhoan) session.getAttribute("user") : null;

        if (sessionUser == null) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        if (sessionUser.getRoleId() != RoleRedirectUtil.ROLE_CUSTOMER) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Trang này chỉ dành cho tài khoản Khách hàng.");
            return;
        }

        req.getRequestDispatcher("/customer/DoiMatKhau.jsp").forward(req, resp);
    }
}
