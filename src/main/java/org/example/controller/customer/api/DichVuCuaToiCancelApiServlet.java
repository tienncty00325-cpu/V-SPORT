package org.example.controller.customer.api;

import com.google.gson.Gson;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.model.TaiKhoan;
import org.example.service.customer.ServiceOrderService;
import org.example.util.Constants;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/** Customer tự hủy đơn dịch vụ (PHẦN 11 Task 7). Chỉ POST. */
@WebServlet("/api/customer/dich-vu-cua-toi/huy")
public class DichVuCuaToiCancelApiServlet extends HttpServlet {

    private final ServiceOrderService service = new ServiceOrderService();
    private final Gson gson = new Gson();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("application/json; charset=UTF-8");
        HttpSession session = req.getSession(false);
        TaiKhoan user = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        Map<String, Object> out = new HashMap<>();

        if (user == null) {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.put("success", false);
            out.put("message", "Vui lòng đăng nhập.");
            resp.getWriter().write(gson.toJson(out));
            return;
        }
        if (user.getRoleId() != Constants.ROLE_KHACH_HANG) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.put("success", false);
            out.put("message", "Chức năng này chỉ dành cho khách hàng.");
            resp.getWriter().write(gson.toJson(out));
            return;
        }

        Integer orderId;
        try {
            orderId = Integer.parseInt(req.getParameter("orderId"));
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.put("success", false);
            out.put("message", "Thiếu hoặc sai mã đơn.");
            resp.getWriter().write(gson.toJson(out));
            return;
        }
        String reason = req.getParameter("reason");

        ServiceOrderService.CancelResult r = service.cancelOrderByCustomer(user.getAccountId(), orderId, reason);
        if (r.success) {
            out.put("success", true);
            out.put("status", r.order.getStatus());
            out.put("message", "Đã hủy yêu cầu dịch vụ.");
        } else {
            resp.setStatus(httpStatusFor(r.errorCode));
            out.put("success", false);
            out.put("message", r.errorMessage);
        }
        resp.getWriter().write(gson.toJson(out));
    }

    private int httpStatusFor(ServiceOrderService.CancelErrorCode code) {
        if (code == null) return HttpServletResponse.SC_INTERNAL_SERVER_ERROR;
        switch (code) {
            case NOT_FOUND: return HttpServletResponse.SC_NOT_FOUND;
            case FORBIDDEN: return HttpServletResponse.SC_FORBIDDEN;
            case VALIDATION: return HttpServletResponse.SC_BAD_REQUEST;
            case CONFLICT: return HttpServletResponse.SC_CONFLICT;
            default: return HttpServletResponse.SC_INTERNAL_SERVER_ERROR;
        }
    }
}
