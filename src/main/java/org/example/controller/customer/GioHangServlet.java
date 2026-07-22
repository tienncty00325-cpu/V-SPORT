package org.example.controller.customer;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.dao.LichDatSanDAO;
import org.example.dao.SanDAO;
import org.example.dao.impl.CoSoDAOImpl;
import org.example.dao.impl.LichDatSanDAOImpl;
import org.example.dao.impl.SanDAOImpl;
import org.example.model.Lichdatsan;
import org.example.model.San;
import org.example.model.TaiKhoan;
import org.example.model.CoSo;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@WebServlet(urlPatterns = {"/customer/gio-hang", "/customer/api/cart-count"})
public class GioHangServlet extends HttpServlet {

    private final LichDatSanDAO lichDatSanDAO = new LichDatSanDAOImpl();
    private final SanDAO sanDAO = new SanDAOImpl();
    private final org.example.dao.CoSoDAO coSoDAO = new CoSoDAOImpl();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();
        if ("/customer/api/cart-count".equals(path)) {
            handleCartCount(req, resp);
            return;
        }

        HttpSession session = req.getSession();
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");
        
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        List<Lichdatsan> allLich = lichDatSanDAO.getLichByAccountId(user.getAccountId());
        List<Lichdatsan> cartItems = new ArrayList<>();
        
        if (allLich != null) {
            for (Lichdatsan l : allLich) {
                if ("Chờ xác nhận".equals(l.getTrangThai()) || "Chờ thanh toán".equals(l.getTrangThai())) {
                    cartItems.add(l);
                }
            }
        }
        
        List<San> dsSan = sanDAO.getAllSan();
        List<CoSo> dsCoSo = coSoDAO.getAllCoSo();
        
        req.setAttribute("cartItems", cartItems);
        req.setAttribute("dsSan", dsSan);
        req.setAttribute("dsCoSo", dsCoSo);
        
        req.getRequestDispatcher("/customer/GioHang.jsp").forward(req, resp);
    }

    private void handleCartCount(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        HttpSession session = req.getSession(false);
        TaiKhoan user = (session != null) ? (TaiKhoan) session.getAttribute("user") : null;
        
        int count = 0;
        if (user != null) {
            List<Lichdatsan> allLich = lichDatSanDAO.getLichByAccountId(user.getAccountId());
            if (allLich != null) {
                for (Lichdatsan l : allLich) {
                    if ("Chờ xác nhận".equals(l.getTrangThai()) || "Chờ thanh toán".equals(l.getTrangThai())) {
                        count++;
                    }
                }
            }
        }
        
        resp.getWriter().write("{\"count\": " + count + "}");
    }
}
