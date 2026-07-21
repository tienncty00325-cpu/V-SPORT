package org.example.filter;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.model.TaiKhoan;
import org.example.service.FacilityAccessService;

import java.io.IOException;

/**
 * Chặn MỌI request /manager/* và /staff/* của tài khoản gắn với một CoSo đã bị
 * xóa mềm (IsDeleted=1) hoặc không còn tồn tại. Đây là lớp phòng thủ trung tâm -
 * đứng trước toàn bộ servlet vận hành nên không phụ thuộc việc từng servlet có
 * tự gọi FacilityAccessService.requireActiveFacility() hay không.
 *
 * Không áp dụng cho /admin/*, trang public, login/logout - những route này không
 * khớp url-pattern của filter nên không cần loại trừ thủ công.
 *
 * Luôn đọc trạng thái CoSo trực tiếp từ database (FacilityAccessService không cache)
 * để một session đang mở bị chặn ngay ở request kế tiếp sau khi Admin xóa cơ sở,
 * không cần đợi session hết hạn.
 */
@WebFilter({"/manager/*", "/staff/*"})
public class ActiveFacilityFilter implements Filter {

    private static final Logger logger = LogManager.getLogger(ActiveFacilityFilter.class);
    private final FacilityAccessService facilityAccessService = new FacilityAccessService();

    @Override
    public void init(FilterConfig filterConfig) {
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        HttpSession session = httpRequest.getSession(false);

        if (session == null) {
            chain.doFilter(request, response);
            return;
        }

        TaiKhoan user = (TaiKhoan) session.getAttribute("user");
        if (user == null || user.getCoSoId() == null) {
            // Không đăng nhập, hoặc tài khoản không gắn cơ sở nào (vd Admin lỡ truy cập nhầm route -
            // các filter quyền khác đã xử lý riêng) - không thuộc phạm vi kiểm tra này.
            chain.doFilter(request, response);
            return;
        }

        FacilityAccessService.FacilityStatus status = facilityAccessService.getFacilityStatus(user.getCoSoId());
        if (status == FacilityAccessService.FacilityStatus.ACTIVE) {
            chain.doFilter(request, response);
            return;
        }

        logger.warn("FACILITY_INACTIVE_BLOCK accountId={}, roleId={}, coSoId={}, path={}, status={}",
                user.getAccountId(), user.getRoleId(), user.getCoSoId(), httpRequest.getRequestURI(), status);
        session.invalidate();

        if (isAjaxRequest(httpRequest)) {
            httpResponse.setStatus(HttpServletResponse.SC_FORBIDDEN);
            httpResponse.setContentType("application/json;charset=UTF-8");
            httpResponse.setCharacterEncoding("UTF-8");
            httpResponse.getWriter().write(
                    "{\"success\":false,\"code\":\"FACILITY_INACTIVE\",\"message\":\"Cơ sở đã ngừng hoạt động.\"}");
            return;
        }

        httpResponse.sendRedirect(httpRequest.getContextPath() + "/he-thong/dang-nhap?facilityInactive=true");
    }

    private boolean isAjaxRequest(HttpServletRequest req) {
        String accept = req.getHeader("Accept");
        return "XMLHttpRequest".equals(req.getHeader("X-Requested-With"))
                || (accept != null && accept.contains("application/json"))
                || "true".equals(req.getParameter("ajax"))
                || req.getParameter("action") != null;
    }

    @Override
    public void destroy() {
    }
}
