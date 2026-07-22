package org.example.controller.manager.api;

import com.google.gson.Gson;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.model.TaiKhoan;
import org.example.service.AuditLogService;
import org.example.service.manager.ServiceOrderManagerService;
import org.example.util.Constants;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * Chuyển trạng thái đơn dịch vụ (PHẦN 13/14 Task 6). Chỉ POST, action whitelist
 * rõ ràng - không có "updateStatus" tự do. Toàn bộ business logic transition
 * nằm trong ServiceOrderManagerService; servlet chỉ parse input + map lỗi
 * sang HTTP status.
 */
@WebServlet("/api/manager/yeu-cau-dich-vu/action")
public class YeuCauDichVuActionApiServlet extends HttpServlet {

    private static final Set<String> VALID_ACTIONS = Set.of(
            "xac-nhan", "tu-choi", "da-nhan", "bat-dau", "san-sang", "hoan-thanh", "huy");

    private final ServiceOrderManagerService service = new ServiceOrderManagerService();
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
        if (user.getRoleId() != Constants.ROLE_MANAGER) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.put("success", false);
            out.put("message", "Bạn không có quyền thực hiện thao tác này.");
            resp.getWriter().write(gson.toJson(out));
            return;
        }

        String action = req.getParameter("action");
        if (action == null || !VALID_ACTIONS.contains(action)) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.put("success", false);
            out.put("message", "Hành động không hợp lệ.");
            resp.getWriter().write(gson.toJson(out));
            return;
        }

        int orderId;
        try {
            orderId = Integer.parseInt(req.getParameter("orderId"));
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.put("success", false);
            out.put("message", "Thiếu hoặc sai mã đơn.");
            resp.getWriter().write(gson.toJson(out));
            return;
        }

        int coSoId = user.getCoSoId();
        int managerId = user.getAccountId();
        ServiceOrderManagerService.Result r;

        switch (action) {
            case "xac-nhan": {
                Double confirmedPrice = parseDouble(req.getParameter("confirmedPrice"));
                LocalDateTime expectedPickup = parseDateTime(req.getParameter("expectedPickupTime"));
                String note = req.getParameter("managerNote");
                r = service.confirmOrder(managerId, coSoId, orderId, confirmedPrice, expectedPickup, note);
                if (r.success) logAudit(req, user, "CONFIRM", orderId, "Xác nhận đơn dịch vụ, giá xác nhận: " + confirmedPrice);
                break;
            }
            case "tu-choi": {
                String reason = req.getParameter("reason");
                r = service.rejectOrder(managerId, coSoId, orderId, reason);
                if (r.success) logAudit(req, user, AuditLogService.ACTION_REJECT, orderId, "Từ chối đơn dịch vụ: " + reason);
                break;
            }
            case "da-nhan": {
                String note = req.getParameter("managerNote");
                r = service.markItemReceived(managerId, coSoId, orderId, note);
                break;
            }
            case "bat-dau": {
                r = service.startProcessing(managerId, coSoId, orderId);
                break;
            }
            case "san-sang": {
                String note = req.getParameter("managerNote");
                r = service.markReadyForPickup(managerId, coSoId, orderId, note);
                break;
            }
            case "hoan-thanh": {
                r = service.completeOrder(managerId, coSoId, orderId);
                if (r.success) logAudit(req, user, AuditLogService.ACTION_UPDATE, orderId, "Hoàn thành đơn dịch vụ");
                break;
            }
            case "huy": {
                String reason = req.getParameter("reason");
                r = service.cancelOrderByManager(managerId, coSoId, orderId, reason);
                if (r.success) logAudit(req, user, AuditLogService.ACTION_CANCEL, orderId, "Manager hủy đơn dịch vụ: " + reason);
                break;
            }
            default:
                r = ServiceOrderManagerService.Result.fail(ServiceOrderManagerService.ErrorCode.VALIDATION, "Hành động không hợp lệ.");
        }

        if (r.success) {
            out.put("success", true);
            out.put("status", r.order.getStatus());
            out.put("message", successMessage(action));
        } else {
            resp.setStatus(httpStatusFor(r.errorCode));
            out.put("success", false);
            out.put("message", r.errorMessage);
        }
        resp.getWriter().write(gson.toJson(out));
    }

    private void logAudit(HttpServletRequest req, TaiKhoan user, String action, int orderId, String details) {
        AuditLogService.log(req, user, action, "ServiceOrder", String.valueOf(orderId), null, details);
    }

    private String successMessage(String action) {
        switch (action) {
            case "xac-nhan": return "Yêu cầu đã được xác nhận.";
            case "tu-choi": return "Đã từ chối đơn dịch vụ.";
            case "da-nhan": return "Đã ghi nhận cơ sở nhận vợt.";
            case "bat-dau": return "Đơn đang được xử lý.";
            case "san-sang": return "Đã đánh dấu sẵn sàng giao khách.";
            case "hoan-thanh": return "Đơn dịch vụ đã hoàn thành.";
            case "huy": return "Đã hủy đơn dịch vụ.";
            default: return "Thao tác thành công.";
        }
    }

    private int httpStatusFor(ServiceOrderManagerService.ErrorCode code) {
        if (code == null) return HttpServletResponse.SC_INTERNAL_SERVER_ERROR;
        switch (code) {
            case NOT_FOUND: return HttpServletResponse.SC_NOT_FOUND;
            case FORBIDDEN: return HttpServletResponse.SC_FORBIDDEN;
            case VALIDATION: return HttpServletResponse.SC_BAD_REQUEST;
            case CONFLICT: return HttpServletResponse.SC_CONFLICT;
            case INVALID_TRANSITION: return HttpServletResponse.SC_CONFLICT;
            default: return HttpServletResponse.SC_INTERNAL_SERVER_ERROR;
        }
    }

    private Double parseDouble(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Double.parseDouble(s.trim()); } catch (NumberFormatException e) { return null; }
    }

    private LocalDateTime parseDateTime(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return LocalDateTime.parse(s.trim()); } catch (Exception e) { return null; }
    }
}
