package org.example.controller.customer;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.dao.LoaiSanDAO;
import org.example.dao.impl.LoaiSanDAOImpl;
import org.example.model.MonTheThao;
import org.example.model.TaiKhoan;
import org.example.util.RoleRedirectUtil;

import java.io.IOException;
import java.util.List;

@WebServlet("/customer/ban-do")
public class BanDoServlet extends HttpServlet {

    private final LoaiSanDAO loaiSanDAO = new LoaiSanDAOImpl();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan sessionUser = session != null ? (TaiKhoan) session.getAttribute("user") : null;

        if (sessionUser != null && sessionUser.getRoleId() != RoleRedirectUtil.ROLE_CUSTOMER) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Trang này chỉ dành cho tài khoản Khách hàng.");
            return;
        }

        // Fetch MapTiler key
        String apiKey = System.getProperty("MAPTILER_API_KEY");
        if (apiKey == null || apiKey.trim().isEmpty()) {
            apiKey = getServletContext().getInitParameter("MAPTILER_API_KEY");
        }

        List<MonTheThao> dsMon = null;
        try {
            dsMon = loaiSanDAO.getAllMonTheThao();
        } catch (Exception e) {
            // Fallback to null
        }

        req.setAttribute("dsMon", dsMon);
        req.setAttribute("maptilerApiKey", apiKey);
        req.getRequestDispatcher("/customer/BanDo.jsp").forward(req, resp);
    }
}
