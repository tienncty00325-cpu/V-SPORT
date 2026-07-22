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
 * Customer gửi yêu cầu dịch vụ (PHẦN 11). customerId LUÔN lấy từ session, không
 * bao giờ tin request param - chống IDOR (PHẦN 25).
 */
@WebServlet("/api/customer/dich-vu/dat")
public class DichVuDatApiServlet extends HttpServlet {

    private final ServiceOrderService orderService = new ServiceOrderService();
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
            out.put("message", "Vui lòng đăng nhập để gửi yêu cầu dịch vụ.");
            resp.getWriter().write(gson.toJson(out));
            return;
        }
        if (user.getRoleId() != Constants.ROLE_KHACH_HANG) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.put("success", false);
            out.put("message", "Chỉ khách hàng mới có thể gửi yêu cầu dịch vụ.");
            resp.getWriter().write(gson.toJson(out));
            return;
        }

        try {
            ServiceOrderService.OrderInput input = new ServiceOrderService.OrderInput();
            input.serviceId = Integer.parseInt(req.getParameter("serviceId"));
            String bookingIdStr = req.getParameter("bookingId");
            if (bookingIdStr != null && !bookingIdStr.trim().isEmpty()) {
                input.bookingId = Integer.parseInt(bookingIdStr.trim());
            }
            input.appointmentDate = LocalDate.parse(req.getParameter("appointmentDate"));
            input.dropOffTime = req.getParameter("dropOffTime");
            input.customerNote = req.getParameter("customerNote");
            input.racketType = req.getParameter("racketType");
            input.racketBrand = req.getParameter("racketBrand");
            input.racketModel = req.getParameter("racketModel");
            String materialIdStr = req.getParameter("materialId");
            if (materialIdStr != null && !materialIdStr.trim().isEmpty()) {
                input.materialId = Integer.parseInt(materialIdStr.trim());
            }
            input.customerBringsString = "1".equals(req.getParameter("customerBringsString"))
                    || "true".equals(req.getParameter("customerBringsString"));
            String tensionStr = req.getParameter("tensionValue");
            if (tensionStr != null && !tensionStr.trim().isEmpty()) {
                input.tensionValue = Double.parseDouble(tensionStr.trim());
            }
            input.tensionUnit = req.getParameter("tensionUnit");
            input.stringColor = req.getParameter("stringColor");
            String qtyStr = req.getParameter("quantity");
            input.quantity = (qtyStr != null && !qtyStr.trim().isEmpty()) ? Integer.parseInt(qtyStr.trim()) : 1;
            input.technicalNote = req.getParameter("technicalNote");

            ServiceOrderService.Result r = orderService.createOrder(user.getAccountId(), input);
            if (r.success) {
                out.put("success", true);
                out.put("orderId", r.order.getOrderID());
                out.put("estimatedPrice", r.order.getEstimatedPrice());
                out.put("message", "Đã gửi yêu cầu dịch vụ. Cơ sở sẽ xác nhận sớm nhất.");
            } else {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.put("success", false);
                out.put("message", r.errorMessage);
            }
        } catch (NumberFormatException | java.time.format.DateTimeParseException e) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.put("success", false);
            out.put("message", "Dữ liệu gửi lên không hợp lệ.");
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.put("success", false);
            out.put("message", "Đã xảy ra lỗi hệ thống. Vui lòng thử lại.");
        }
        resp.getWriter().write(gson.toJson(out));
    }
}
