package org.example.filter;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.model.TaiKhoan;
import java.io.IOException;

@WebFilter("/manager/*")
public class FilterQuyenManager implements Filter {
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        HttpSession session = httpRequest.getSession(false);

        boolean loggedIn = (session != null && session.getAttribute("user") != null);

        if (loggedIn) {
            TaiKhoan user = (TaiKhoan) session.getAttribute("user");
            // Only Role 2 (Manager) is allowed to access the manager area
            if (user.getRoleId() == 2) {
                chain.doFilter(request, response);
            } else {
                httpResponse.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền Quản lý cơ sở để truy cập chức năng này.");
            }
        } else {
            httpResponse.sendRedirect(httpRequest.getContextPath() + "/he-thong/dang-nhap");
        }
    }

    @Override
    public void destroy() {}
}
