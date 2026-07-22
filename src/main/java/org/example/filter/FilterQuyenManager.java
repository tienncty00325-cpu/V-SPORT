package org.example.filter;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.dao.CoSoCapabilityDAO;
import org.example.dao.impl.CoSoCapabilityDAOImpl;
import org.example.model.TaiKhoan;
import org.example.util.Constants;
import java.io.IOException;
import java.util.List;
import java.util.Map;

@WebFilter("/manager/*")
public class FilterQuyenManager implements Filter {

    // Route -> capability nào (ít nhất 1 trong danh sách) phải APPROVED mới được vào.
    // Đây là chốt chặn backend thật sự (Part G) - không dựa vào việc ẩn menu bằng CSS/JS.
    private static final Map<String, List<String>> CAPABILITY_GATED_PATHS = Map.of(
            "/manager/kho-dich-vu", Constants.SHOP_MODULE_CAPABILITIES,
            "/manager/dich-vu", Constants.SERVICE_MODULE_CAPABILITIES,
            "/manager/yeu-cau-dich-vu", Constants.SERVICE_MODULE_CAPABILITIES
    );

    private final CoSoCapabilityDAO capabilityDAO = new CoSoCapabilityDAOImpl();

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
            if (user.getRoleId() != 2) {
                httpResponse.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền Quản lý cơ sở để truy cập chức năng này.");
                return;
            }

            List<String> requiredCapabilities = CAPABILITY_GATED_PATHS.get(httpRequest.getServletPath());
            if (requiredCapabilities != null) {
                // Không tin coSoId từ request - luôn lấy từ tài khoản đang đăng nhập trong session.
                if (!capabilityDAO.isApprovedAny(user.getCoSoId(), requiredCapabilities)) {
                    httpResponse.sendError(HttpServletResponse.SC_FORBIDDEN,
                            "Cơ sở của bạn chưa được Admin phê duyệt loại hình kinh doanh này.");
                    return;
                }
            }

            chain.doFilter(request, response);
        } else {
            httpResponse.sendRedirect(httpRequest.getContextPath() + "/he-thong/dang-nhap");
        }
    }

    @Override
    public void destroy() {}
}
