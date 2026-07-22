package org.example.controller.customer;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/** Trang Customer "Cửa hàng & Dịch vụ" (PHẦN 8) - render khung trang, dữ liệu tải qua /api/customer/dich-vu. */
@WebServlet("/customer/dich-vu")
public class DichVuServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.getRequestDispatcher("/customer/DichVu.jsp").forward(req, resp);
    }
}
