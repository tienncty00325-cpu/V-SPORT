package org.example.filter;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.model.TaiKhoan;
import java.io.IOException;

/**
 * Filter đặc quyền cho Admin để bảo vệ các route /admin/*
 */
@WebFilter("/admin/*")
public class FilterQuyenAdmin implements Filter {
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        HttpSession session = httpRequest.getSession(false);

        boolean loggedIn = (session != null && session.getAttribute("user") != null);
        String path = httpRequest.getServletPath();
        boolean isJsonApiRoute = path.contains("/chi-nhanh/payos");

        if (loggedIn) {
            TaiKhoan user = (TaiKhoan) session.getAttribute("user");
            if (path.contains("/quan-ly-san") || path.contains("/QuanLySan.jsp")) {
                httpResponse.sendError(HttpServletResponse.SC_FORBIDDEN, "Quản trị viên không có quyền quản lý sân (Chức năng này dành riêng cho Quản lý cơ sở).");
                return;
            }
            // Chỉ Role 1 (Admin) mới được vào vùng này
            if (user.getRoleId() == 1) {
                chain.doFilter(request, response);
            } else if (isJsonApiRoute) {
                writeForbiddenJson(httpResponse);
            } else {
                httpResponse.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền Admin để truy cập chức năng này.");
            }
        } else if (isJsonApiRoute) {
            writeForbiddenJson(httpResponse);
        } else {
            httpResponse.sendRedirect(httpRequest.getContextPath() + "/he-thong/dang-nhap");
        }
    }

    private void writeForbiddenJson(HttpServletResponse resp) throws IOException {
        resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
        resp.setContentType("application/json;charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.getWriter().write("{\"success\":false,\"message\":\"Bạn không có quyền thực hiện thao tác này.\"}");
    }

    @Override
    public void destroy() {}
}
