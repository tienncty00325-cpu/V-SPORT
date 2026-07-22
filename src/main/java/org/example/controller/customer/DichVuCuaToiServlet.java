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

/** Trang "Dịch vụ của tôi" (PHẦN 3 Task 7) - dữ liệu tải qua /api/customer/dich-vu-cua-toi. */
@WebServlet("/customer/dich-vu-cua-toi")
public class DichVuCuaToiServlet extends HttpServlet {
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

        req.getRequestDispatcher("/customer/DichVuCuaToi.jsp").forward(req, resp);
    }
}
