package org.example.controller.manager;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/** Trang Manager "Yêu cầu dịch vụ" (PHẦN 12/14) - dữ liệu tải qua /api/manager/yeu-cau-dich-vu. */
@WebServlet("/manager/yeu-cau-dich-vu")
public class YeuCauDichVuServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setAttribute("pageTitle", "Yêu cầu dịch vụ");
        req.getRequestDispatcher("/manager/YeuCauDichVu.jsp").forward(req, resp);
    }
}
