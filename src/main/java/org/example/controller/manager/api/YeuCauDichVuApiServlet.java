package org.example.controller.manager.api;

import com.google.gson.Gson;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.model.RacketStringingOrderDetail;
import org.example.model.ServiceMaterial;
import org.example.model.ServiceOrder;
import org.example.model.ServiceOrderStatusHistory;
import org.example.model.SportService;
import org.example.model.TaiKhoan;
import org.example.service.manager.ServiceOrderManagerService;
import org.example.util.Constants;
import org.example.util.JPAUtil;

import java.io.IOException;
import java.util.*;

/**
 * Đọc danh sách/chi tiết đơn dịch vụ cho Manager (PHẦN 11 Task 6). Chỉ GET -
 * không đổi trạng thái ở đây (xem YeuCauDichVuActionApiServlet). coSoId LUÔN
 * lấy từ session, không tin query param facilityId/coSoId (chống IDOR).
 */
@WebServlet("/api/manager/yeu-cau-dich-vu")
public class YeuCauDichVuApiServlet extends HttpServlet {

    private final ServiceOrderManagerService service = new ServiceOrderManagerService();
    private final Gson gson = new Gson();

    private static final Map<String, List<String>> TAB_STATUSES = new LinkedHashMap<>();
    static {
        TAB_STATUSES.put("moi", List.of(ServiceOrder.PENDING_CONFIRMATION));
        TAB_STATUSES.put("da-xac-nhan", List.of(ServiceOrder.CONFIRMED));
        TAB_STATUSES.put("dang-xu-ly", List.of(ServiceOrder.ITEM_RECEIVED, ServiceOrder.IN_PROGRESS));
        TAB_STATUSES.put("san-sang", List.of(ServiceOrder.READY_FOR_PICKUP));
        TAB_STATUSES.put("hoan-thanh", List.of(ServiceOrder.COMPLETED));
        TAB_STATUSES.put("da-huy", List.of(ServiceOrder.CANCELLED, ServiceOrder.REJECTED));
    }

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
        if (user.getRoleId() != Constants.ROLE_MANAGER) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.put("success", false);
            out.put("message", "Bạn không có quyền truy cập chức năng này.");
            resp.getWriter().write(gson.toJson(out));
            return;
        }
        int coSoId = user.getCoSoId();

        try {
            String action = req.getParameter("action");
            if ("detail".equals(action)) {
                handleDetail(req, resp, coSoId);
            } else {
                handleList(req, resp, coSoId);
            }
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.put("success", false);
            out.put("message", "Đã xảy ra lỗi hệ thống.");
            resp.getWriter().write(gson.toJson(out));
        }
    }

    private void handleList(HttpServletRequest req, HttpServletResponse resp, int coSoId) throws IOException {
        String tab = req.getParameter("tab");
        List<String> statuses = TAB_STATUSES.getOrDefault(tab, null);
        List<ServiceOrder> orders = service.listByCoSo(coSoId, statuses, 100);

        List<Map<String, Object>> items = new ArrayList<>();
        EntityManagerHolder h = new EntityManagerHolder();
        try {
            for (ServiceOrder o : orders) {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("orderId", o.getOrderID());
                m.put("status", o.getStatus());
                m.put("requestedAt", o.getRequestedAt() != null ? o.getRequestedAt().toString() : null);
                m.put("appointmentDate", o.getAppointmentDate() != null ? o.getAppointmentDate().toString() : null);
                m.put("estimatedPrice", o.getEstimatedPrice());
                m.put("confirmedPrice", o.getConfirmedPrice());
                enrichCustomerAndService(h.em, m, o);
                items.add(m);
            }
        } finally {
            h.close();
        }

        Map<String, Object> counts = new LinkedHashMap<>();
        for (String key : TAB_STATUSES.keySet()) {
            counts.put(key, service.listByCoSo(coSoId, TAB_STATUSES.get(key), 200).size());
        }

        Map<String, Object> out = new HashMap<>();
        out.put("success", true);
        out.put("orders", items);
        out.put("counts", counts);
        resp.getWriter().write(gson.toJson(out));
    }

    private void enrichCustomerAndService(jakarta.persistence.EntityManager em, Map<String, Object> m, ServiceOrder o) {
        TaiKhoan customer = em.find(TaiKhoan.class, o.getCustomerID());
        SportService svc = em.find(SportService.class, o.getServiceID());
        m.put("customerName", customer != null ? customer.getFullName() : "");
        m.put("customerPhone", customer != null ? customer.getPhoneNumber() : "");
        m.put("serviceName", svc != null ? svc.getServiceName() : "");
        m.put("serviceType", svc != null ? svc.getServiceType() : "");

        if (svc != null && "CANG_LUOI".equals(svc.getServiceType())) {
            RacketStringingOrderDetail detail = em.createQuery(
                    "SELECT d FROM RacketStringingOrderDetail d WHERE d.orderID = :oid",
                    RacketStringingOrderDetail.class)
                    .setParameter("oid", o.getOrderID())
                    .getResultStream().findFirst().orElse(null);
            if (detail != null) {
                m.put("racketType", detail.getRacketType());
                m.put("tensionValue", detail.getTensionValue());
                m.put("tensionUnit", detail.getTensionUnit());
            }
        }
    }

    private void handleDetail(HttpServletRequest req, HttpServletResponse resp, int coSoId) throws IOException {
        Map<String, Object> out = new HashMap<>();
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

        ServiceOrder order = service.getByIdAndCoSo(coSoId, orderId);
        if (order == null) {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            out.put("success", false);
            out.put("message", "Không tìm thấy đơn dịch vụ.");
            resp.getWriter().write(gson.toJson(out));
            return;
        }

        EntityManagerHolder h = new EntityManagerHolder();
        Map<String, Object> detail = new LinkedHashMap<>();
        try {
            TaiKhoan customer = h.em.find(TaiKhoan.class, order.getCustomerID());
            SportService svc = h.em.find(SportService.class, order.getServiceID());

            detail.put("orderId", order.getOrderID());
            detail.put("status", order.getStatus());
            detail.put("requestedAt", str(order.getRequestedAt()));
            detail.put("appointmentDate", str(order.getAppointmentDate()));
            detail.put("dropOffTime", order.getDropOffTime());
            detail.put("expectedPickupTime", str(order.getExpectedPickupTime()));
            detail.put("actualReceivedTime", str(order.getActualReceivedTime()));
            detail.put("completedTime", str(order.getCompletedTime()));
            detail.put("deliveredTime", str(order.getDeliveredTime()));
            detail.put("cancelledTime", str(order.getCancelledTime()));
            detail.put("customerNote", order.getCustomerNote());
            detail.put("managerNote", order.getManagerNote());
            detail.put("estimatedPrice", order.getEstimatedPrice());
            detail.put("confirmedPrice", order.getConfirmedPrice());
            detail.put("cancellationReason", order.getCancellationReason());
            detail.put("bookingId", order.getBookingID());

            detail.put("customerName", customer != null ? customer.getFullName() : "");
            detail.put("customerPhone", customer != null ? customer.getPhoneNumber() : "");
            detail.put("serviceName", svc != null ? svc.getServiceName() : "");
            detail.put("serviceType", svc != null ? svc.getServiceType() : "");
            detail.put("unit", svc != null ? svc.getUnit() : null);

            if (svc != null && "CANG_LUOI".equals(svc.getServiceType())) {
                RacketStringingOrderDetail rd = h.em.createQuery(
                        "SELECT d FROM RacketStringingOrderDetail d WHERE d.orderID = :oid",
                        RacketStringingOrderDetail.class)
                        .setParameter("oid", orderId)
                        .getResultStream().findFirst().orElse(null);
                if (rd != null) {
                    Map<String, Object> rc = new LinkedHashMap<>();
                    rc.put("racketType", rd.getRacketType());
                    rc.put("racketBrand", rd.getRacketBrand());
                    rc.put("racketModel", rd.getRacketModel());
                    rc.put("customerBringsString", rd.isCustomerBringsString());
                    rc.put("tensionValue", rd.getTensionValue());
                    rc.put("tensionUnit", rd.getTensionUnit());
                    rc.put("stringColor", rd.getStringColor());
                    rc.put("quantity", rd.getQuantity());
                    rc.put("technicalNote", rd.getTechnicalNote());
                    if (rd.getMaterialID() != null) {
                        ServiceMaterial mat = h.em.find(ServiceMaterial.class, rd.getMaterialID());
                        if (mat != null) {
                            rc.put("materialName", mat.getName());
                            rc.put("materialPrice", mat.getPrice());
                            rc.put("materialExtraFee", mat.getExtraFee());
                        }
                    }
                    detail.put("racketDetail", rc);
                }
            }

            List<Map<String, Object>> timeline = new ArrayList<>();
            for (ServiceOrderStatusHistory hist : service.getHistory(orderId)) {
                Map<String, Object> t = new LinkedHashMap<>();
                t.put("fromStatus", hist.getFromStatus());
                t.put("toStatus", hist.getToStatus());
                t.put("changedAt", str(hist.getChangedAt()));
                t.put("note", hist.getNote());
                timeline.add(t);
            }
            detail.put("timeline", timeline);
            detail.put("allowedActions", ServiceOrderManagerService.allowedNextStatuses(order.getStatus()));

            out.put("success", true);
            out.put("order", detail);
            resp.getWriter().write(gson.toJson(out));
        } finally {
            h.close();
        }
    }

    private static String str(Object o) { return o == null ? null : o.toString(); }

    /** Tiện ích mở EntityManager ngắn hạn cho các truy vấn enrich chỉ-đọc. */
    private static class EntityManagerHolder {
        final jakarta.persistence.EntityManager em = JPAUtil.getEntityManager();
        void close() { em.close(); }
    }
}
