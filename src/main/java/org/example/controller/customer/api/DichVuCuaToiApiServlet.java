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
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;

/**
 * Danh sách/chi tiết đơn dịch vụ của Customer (PHẦN 4/8 Task 7). customerId
 * LUÔN lấy từ session - không nhận accountId/customerId từ query param.
 */
@WebServlet("/api/customer/dich-vu-cua-toi")
public class DichVuCuaToiApiServlet extends HttpServlet {

    private final ServiceOrderService service = new ServiceOrderService();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
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
        int customerId = user.getAccountId();

        try {
            if ("detail".equals(req.getParameter("action"))) {
                handleDetail(req, resp, customerId);
            } else {
                handleList(req, resp, customerId);
            }
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.put("success", false);
            out.put("message", "Không thể tải danh sách dịch vụ của bạn.");
            resp.getWriter().write(gson.toJson(out));
        }
    }

    private void handleList(HttpServletRequest req, HttpServletResponse resp, int customerId) throws IOException {
        String group = req.getParameter("group");
        if ("tat-ca".equals(group)) group = null;
        Integer coSoId = parseInt(req.getParameter("coSoId"));
        LocalDate dateFrom = parseDate(req.getParameter("dateFrom"));
        LocalDate dateTo = parseDate(req.getParameter("dateTo"));
        String q = req.getParameter("q");
        int page = parseInt(req.getParameter("page")) != null ? parseInt(req.getParameter("page")) : 1;
        int pageSize = parseInt(req.getParameter("pageSize")) != null ? parseInt(req.getParameter("pageSize")) : 10;

        ServiceOrderService.ListResult result = service.listForCustomer(
                customerId, group, coSoId, dateFrom, dateTo, q, page, pageSize);

        Map<String, Object> out = new HashMap<>();
        out.put("success", true);
        out.put("items", result.items);
        out.put("page", result.page);
        out.put("pageSize", result.pageSize);
        out.put("totalItems", result.totalItems);
        out.put("totalPages", result.totalPages);
        out.put("counts", result.counts);
        resp.getWriter().write(gson.toJson(out));
    }

    private void handleDetail(HttpServletRequest req, HttpServletResponse resp, int customerId) throws IOException {
        Map<String, Object> out = new HashMap<>();
        Integer orderId = parseInt(req.getParameter("orderId"));
        if (orderId == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.put("success", false);
            out.put("message", "Thiếu hoặc sai mã đơn.");
            resp.getWriter().write(gson.toJson(out));
            return;
        }
        Map<String, Object> detail = service.getDetailForCustomer(customerId, orderId);
        if (detail == null) {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            out.put("success", false);
            out.put("message", "Không tìm thấy đơn dịch vụ.");
            resp.getWriter().write(gson.toJson(out));
            return;
        }
        out.put("success", true);
        out.put("order", detail);
        resp.getWriter().write(gson.toJson(out));
    }

    private Integer parseInt(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return null; }
    }

    private LocalDate parseDate(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return LocalDate.parse(s.trim()); } catch (Exception e) { return null; }
    }
}
