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
 * Trang "Cài đặt thông báo" (full-screen) cho Customer. Tách khỏi tab trong
 * trang Tài khoản: mở như một trang riêng, không sidebar / không bottom nav,
 * bố cục tối giản tham chiếu giao diện notification settings dạng mobile.
 * Trạng thái công tắc hiện lưu ở phía client (localStorage) — chưa có backend
 * riêng, nên servlet chỉ lo xác thực và forward tới JSP.
 */
@WebServlet("/customer/notification-settings")
public class CustomerNotificationSettingsServlet extends HttpServlet {

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

        req.getRequestDispatcher("/customer/CaiDatThongBao.jsp").forward(req, resp);
    }
}
