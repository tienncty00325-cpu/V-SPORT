package org.example.service.customer;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityTransaction;
import jakarta.persistence.LockModeType;
import jakarta.persistence.Query;
import jakarta.persistence.TypedQuery;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.model.*;
import org.example.util.Constants;
import org.example.util.JPAUtil;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Customer gửi yêu cầu dịch vụ (PHẦN 11/12/21). Đơn dịch vụ là thực thể độc lập,
 * không nhồi vào LichDatSan/GhiChu. Giá và trạng thái LUÔN được server tính lại,
 * không tin bất kỳ giá trị nào Customer gửi từ frontend.
 */
public class ServiceOrderService {

    private static final Logger logger = LogManager.getLogger(ServiceOrderService.class);

    public static class Result {
        public final boolean success;
        public final String errorMessage;
        public final ServiceOrder order;

        private Result(boolean success, String errorMessage, ServiceOrder order) {
            this.success = success;
            this.errorMessage = errorMessage;
            this.order = order;
        }

        static Result ok(ServiceOrder o) { return new Result(true, null, o); }
        static Result fail(String message) { return new Result(false, message, null); }
    }

    /** Input thô từ form đặt dịch vụ - mọi field đều phải được server validate lại. */
    public static class OrderInput {
        public int serviceId;
        public Integer bookingId;
        public LocalDate appointmentDate;
        public String dropOffTime;
        public String customerNote;
        // Chi tiết căng lưới (chỉ áp dụng khi dịch vụ là CANG_LUOI)
        public String racketType;
        public String racketBrand;
        public String racketModel;
        public Integer materialId;
        public boolean customerBringsString;
        public Double tensionValue;
        public String tensionUnit;
        public String stringColor;
        public Integer quantity;
        public String technicalNote;
    }

    public Result createOrder(int customerId, OrderInput input) {
        if (input == null) return Result.fail("Thiếu dữ liệu yêu cầu.");
        if (input.appointmentDate == null) return Result.fail("Vui lòng chọn ngày mang vợt/dụng cụ đến.");
        if (input.appointmentDate.isBefore(LocalDate.now())) {
            return Result.fail("Ngày mang đến không được ở trong quá khứ.");
        }

        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();

            // Tải lại dịch vụ + cơ sở từ DB (không tin dữ liệu client) - PHẦN 21.
            SportService service = em.find(SportService.class, input.serviceId);
            if (service == null || service.isDeleted()) {
                tx.rollback();
                return Result.fail("Dịch vụ không tồn tại hoặc đã bị gỡ bỏ.");
            }
            if (!service.isAcceptingRequests()) {
                tx.rollback();
                return Result.fail("Dịch vụ hiện không nhận yêu cầu mới.");
            }

            CoSo coSo = em.find(CoSo.class, service.getCoSoID());
            if (coSo == null || !"Đang hoạt động".equals(coSo.getTrangThai())
                    || (coSo.isDeleted())) {
                tx.rollback();
                return Result.fail("Cơ sở hiện không hoạt động.");
            }

            long approvedCap = em.createQuery(
                    "SELECT COUNT(cc) FROM CoSoCapability cc WHERE cc.coSoId = :coSoId " +
                    "AND cc.capabilityType = :capType AND cc.trangThai = :approved", Long.class)
                    .setParameter("coSoId", coSo.getCoSoID())
                    .setParameter("capType", Constants.CAPABILITY_DICH_VU_THE_THAO)
                    .setParameter("approved", Constants.CAPABILITY_STATUS_APPROVED)
                    .getSingleResult();
            if (approvedCap == 0) {
                tx.rollback();
                return Result.fail("Cơ sở chưa được phê duyệt cung cấp dịch vụ thể thao.");
            }

            // Nếu có gắn booking, booking phải thuộc chính Customer này (PHẦN 20 constraint).
            if (input.bookingId != null) {
                Lichdatsan booking = em.find(Lichdatsan.class, input.bookingId);
                if (booking == null || booking.getAccountId() == null
                        || booking.getAccountId() != customerId) {
                    tx.rollback();
                    return Result.fail("Lịch đặt sân không hợp lệ.");
                }
            }

            double estimatedPrice;
            RacketStringingConfig config = null;
            ServiceMaterial material = null;

            if ("CANG_LUOI".equals(service.getServiceType())) {
                config = em.createQuery(
                        "SELECT c FROM RacketStringingConfig c WHERE c.serviceID = :sid",
                        RacketStringingConfig.class)
                        .setParameter("sid", service.getServiceID())
                        .getResultStream().findFirst().orElse(null);
                if (config == null) {
                    tx.rollback();
                    return Result.fail("Dịch vụ chưa được cấu hình đầy đủ.");
                }
                if (input.tensionValue == null || input.tensionValue < config.getMinTension()
                        || input.tensionValue > config.getMaxTension()) {
                    tx.rollback();
                    return Result.fail("Mức căng phải trong khoảng " + config.getMinTension()
                            + " - " + config.getMaxTension() + " " + config.getTensionUnit() + ".");
                }
                String unit = input.tensionUnit != null && !input.tensionUnit.trim().isEmpty()
                        ? input.tensionUnit.trim() : config.getTensionUnit();
                if (!unit.equals(config.getTensionUnit())) {
                    tx.rollback();
                    return Result.fail("Đơn vị mức căng không khớp với cấu hình dịch vụ.");
                }
                int qty = input.quantity != null ? input.quantity : 1;
                if (qty <= 0 || qty > config.getMaxRacketsPerOrder()) {
                    tx.rollback();
                    return Result.fail("Số lượng vợt phải từ 1 đến " + config.getMaxRacketsPerOrder() + ".");
                }
                if (!input.customerBringsString) {
                    if (!config.isSellsString()) {
                        tx.rollback();
                        return Result.fail("Cơ sở này chỉ nhận khách tự mang dây.");
                    }
                    if (input.materialId == null) {
                        tx.rollback();
                        return Result.fail("Vui lòng chọn loại dây hoặc chọn tự mang dây.");
                    }
                    material = em.find(ServiceMaterial.class, input.materialId);
                    if (material == null || material.getCoSoID() != coSo.getCoSoID() || material.isDeleted()
                            || "NGUNG_SU_DUNG".equals(material.getStatus())) {
                        tx.rollback();
                        return Result.fail("Loại dây đã chọn không còn khả dụng.");
                    }
                    if ("TAM_HET".equals(material.getStatus())) {
                        tx.rollback();
                        return Result.fail("Loại dây đã chọn tạm thời hết hàng.");
                    }
                } else if (!config.isAllowCustomerString()) {
                    tx.rollback();
                    return Result.fail("Dịch vụ này không nhận khách tự mang dây.");
                }

                double stringPrice = material != null ? (material.getPrice() + material.getExtraFee()) : 0;
                estimatedPrice = (config.getStringingPrice() + stringPrice) * qty;
            } else {
                int qty = input.quantity != null ? input.quantity : 1;
                if (qty <= 0) {
                    tx.rollback();
                    return Result.fail("Số lượng không hợp lệ.");
                }
                estimatedPrice = service.getBasePrice() * qty;
            }

            ServiceOrder order = new ServiceOrder();
            order.setCustomerID(customerId);
            order.setCoSoID(coSo.getCoSoID());
            order.setServiceID(service.getServiceID());
            order.setBookingID(input.bookingId);
            order.setStatus(ServiceOrder.PENDING_CONFIRMATION);
            order.setRequestedAt(LocalDateTime.now());
            order.setAppointmentDate(input.appointmentDate);
            order.setDropOffTime(trim(input.dropOffTime));
            order.setCustomerNote(trim(input.customerNote));
            order.setEstimatedPrice(estimatedPrice);
            order.setCreatedAt(LocalDateTime.now());
            order.setUpdatedAt(LocalDateTime.now());
            em.persist(order);
            em.flush();

            if ("CANG_LUOI".equals(service.getServiceType())) {
                RacketStringingOrderDetail detail = new RacketStringingOrderDetail();
                detail.setOrderID(order.getOrderID());
                detail.setRacketType(trim(input.racketType));
                detail.setRacketBrand(trim(input.racketBrand));
                detail.setRacketModel(trim(input.racketModel));
                detail.setMaterialID(material != null ? material.getMaterialID() : null);
                detail.setCustomerBringsString(input.customerBringsString);
                detail.setTensionValue(input.tensionValue);
                detail.setTensionUnit(config.getTensionUnit());
                detail.setStringColor(trim(input.stringColor));
                detail.setQuantity(input.quantity != null ? input.quantity : 1);
                detail.setTechnicalNote(trim(input.technicalNote));
                em.persist(detail);
            }

            ServiceOrderStatusHistory history = new ServiceOrderStatusHistory();
            history.setOrderID(order.getOrderID());
            history.setFromStatus(null);
            history.setToStatus(ServiceOrder.PENDING_CONFIRMATION);
            history.setChangedBy(customerId);
            history.setChangedAt(LocalDateTime.now());
            history.setNote("Customer gửi yêu cầu dịch vụ");
            em.persist(history);

            tx.commit();
            return Result.ok(order);
        } catch (Exception e) {
            if (tx.isActive()) tx.rollback();
            logger.error("Lỗi tạo service order customerId={}: {}", customerId, e.getMessage(), e);
            return Result.fail("Lỗi hệ thống khi gửi yêu cầu dịch vụ.");
        } finally {
            em.close();
        }
    }

    private static String trim(String s) { return s == null ? null : (s.trim().isEmpty() ? null : s.trim()); }

    // ═══════════════════════════════════════════════════════════════════════
    // Task 7 - Customer theo dõi đơn dịch vụ (PHẦN 4/8/11)
    // ═══════════════════════════════════════════════════════════════════════

    public enum CancelErrorCode { NOT_FOUND, FORBIDDEN, VALIDATION, CONFLICT, SYSTEM }

    public static class CancelResult {
        public final boolean success;
        public final CancelErrorCode errorCode;
        public final String errorMessage;
        public final ServiceOrder order;

        private CancelResult(boolean success, CancelErrorCode errorCode, String errorMessage, ServiceOrder order) {
            this.success = success;
            this.errorCode = errorCode;
            this.errorMessage = errorMessage;
            this.order = order;
        }

        static CancelResult ok(ServiceOrder o) { return new CancelResult(true, null, null, o); }
        static CancelResult fail(CancelErrorCode code, String message) { return new CancelResult(false, code, message, null); }
    }

    /** Nhóm trạng thái kỹ thuật -> nhóm UI (PHẦN 4). Backend vẫn trả trạng thái thật riêng. */
    public static String uiStatusGroup(String status) {
        if (status == null) return "khac";
        switch (status) {
            case ServiceOrder.PENDING_CONFIRMATION: return "cho-xac-nhan";
            case ServiceOrder.CONFIRMED:
            case ServiceOrder.ITEM_RECEIVED: return "da-xac-nhan";
            case ServiceOrder.IN_PROGRESS: return "dang-xu-ly";
            case ServiceOrder.READY_FOR_PICKUP: return "san-sang";
            case ServiceOrder.COMPLETED: return "hoan-thanh";
            case ServiceOrder.CANCELLED:
            case ServiceOrder.REJECTED: return "da-huy";
            default: return "khac";
        }
    }

    private static final Map<String, List<String>> UI_GROUP_TO_STATUSES = new LinkedHashMap<>();
    static {
        UI_GROUP_TO_STATUSES.put("cho-xac-nhan", List.of(ServiceOrder.PENDING_CONFIRMATION));
        UI_GROUP_TO_STATUSES.put("da-xac-nhan", List.of(ServiceOrder.CONFIRMED, ServiceOrder.ITEM_RECEIVED));
        UI_GROUP_TO_STATUSES.put("dang-xu-ly", List.of(ServiceOrder.IN_PROGRESS));
        UI_GROUP_TO_STATUSES.put("san-sang", List.of(ServiceOrder.READY_FOR_PICKUP));
        UI_GROUP_TO_STATUSES.put("hoan-thanh", List.of(ServiceOrder.COMPLETED));
        UI_GROUP_TO_STATUSES.put("da-huy", List.of(ServiceOrder.CANCELLED, ServiceOrder.REJECTED));
    }

    /** Chỉ các trạng thái Customer còn được tự hủy (PHẦN 11) - không dùng chung state machine Manager. */
    private static boolean customerCanCancel(String status) {
        return ServiceOrder.PENDING_CONFIRMATION.equals(status) || ServiceOrder.CONFIRMED.equals(status);
    }

    public static class ListResult {
        public List<Map<String, Object>> items;
        public int page;
        public int pageSize;
        public long totalItems;
        public int totalPages;
        public Map<String, Long> counts;
    }

    /**
     * Danh sách đơn dịch vụ của Customer, phân trang ở tầng DB (PHẦN 4/17) - KHÔNG
     * tải toàn bộ rồi cắt trong Java. Đúng 3 query cố định bất kể pageSize: 1 query
     * danh sách (join SportService+CoSo 1 lượt), 1 COUNT, 1 GROUP BY status.
     */
    public ListResult listForCustomer(int customerId, String uiGroup, Integer coSoId,
                                       LocalDate dateFrom, LocalDate dateTo, String orderIdSearch,
                                       int page, int pageSize) {
        page = Math.max(page, 1);
        pageSize = Math.min(Math.max(pageSize, 1), 50);

        EntityManager em = JPAUtil.getEntityManager();
        try {
            StringBuilder where = new StringBuilder("WHERE o.customerID = :customerId ");
            List<String> statuses = uiGroup != null ? UI_GROUP_TO_STATUSES.get(uiGroup) : null;
            if (statuses != null) where.append("AND o.status IN :statuses ");
            if (coSoId != null) where.append("AND o.coSoID = :coSoId ");
            if (dateFrom != null) where.append("AND o.appointmentDate >= :dateFrom ");
            if (dateTo != null) where.append("AND o.appointmentDate <= :dateTo ");
            if (orderIdSearch != null && !orderIdSearch.trim().isEmpty()) where.append("AND CAST(o.orderID AS string) LIKE :orderIdSearch ");

            String listJpql = "SELECT o, s.serviceName, s.serviceType, c.TenCoSo FROM ServiceOrder o, SportService s, CoSo c "
                    + "WHERE o.serviceID = s.serviceID AND o.coSoID = c.CoSoID AND " + where.substring(6)
                    + "ORDER BY o.requestedAt DESC";
            TypedQuery<Object[]> listQuery = em.createQuery(listJpql, Object[].class);
            bindListParams(listQuery, customerId, statuses, coSoId, dateFrom, dateTo, orderIdSearch);
            listQuery.setFirstResult((page - 1) * pageSize);
            listQuery.setMaxResults(pageSize);
            List<Object[]> rows = listQuery.getResultList();

            String countJpql = "SELECT COUNT(o) FROM ServiceOrder o " + where;
            TypedQuery<Long> countQuery = em.createQuery(countJpql, Long.class);
            bindListParams(countQuery, customerId, statuses, coSoId, dateFrom, dateTo, orderIdSearch);
            long totalItems = countQuery.getSingleResult();

            List<Object[]> groupRows = em.createQuery(
                    "SELECT o.status, COUNT(o) FROM ServiceOrder o WHERE o.customerID = :customerId GROUP BY o.status",
                    Object[].class)
                    .setParameter("customerId", customerId)
                    .getResultList();
            Map<String, Long> counts = new LinkedHashMap<>();
            for (String g : UI_GROUP_TO_STATUSES.keySet()) counts.put(g, 0L);
            for (Object[] gr : groupRows) {
                String group = uiStatusGroup((String) gr[0]);
                counts.merge(group, (Long) gr[1], Long::sum);
            }

            List<Map<String, Object>> items = new ArrayList<>();
            for (Object[] row : rows) {
                ServiceOrder o = (ServiceOrder) row[0];
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("orderId", o.getOrderID());
                m.put("displayCode", "DV" + String.format("%06d", o.getOrderID()));
                m.put("serviceName", row[1]);
                m.put("serviceType", row[2]);
                m.put("coSoName", row[3]);
                m.put("requestedAt", str(o.getRequestedAt()));
                m.put("appointmentDate", str(o.getAppointmentDate()));
                m.put("expectedPickupTime", str(o.getExpectedPickupTime()));
                m.put("estimatedPrice", o.getEstimatedPrice());
                m.put("confirmedPrice", o.getConfirmedPrice());
                m.put("status", o.getStatus());
                m.put("uiStatusGroup", uiStatusGroup(o.getStatus()));
                m.put("bookingId", o.getBookingID());
                m.put("cancellable", customerCanCancel(o.getStatus()));
                m.put("updatedAt", str(o.getUpdatedAt()));
                items.add(m);
            }

            ListResult result = new ListResult();
            result.items = items;
            result.page = page;
            result.pageSize = pageSize;
            result.totalItems = totalItems;
            result.totalPages = (int) Math.ceil(totalItems / (double) pageSize);
            result.counts = counts;
            return result;
        } finally {
            em.close();
        }
    }

    private void bindListParams(Query q, int customerId, List<String> statuses, Integer coSoId,
                                 LocalDate dateFrom, LocalDate dateTo, String orderIdSearch) {
        q.setParameter("customerId", customerId);
        if (statuses != null) q.setParameter("statuses", statuses);
        if (coSoId != null) q.setParameter("coSoId", coSoId);
        if (dateFrom != null) q.setParameter("dateFrom", dateFrom);
        if (dateTo != null) q.setParameter("dateTo", dateTo);
        if (orderIdSearch != null && !orderIdSearch.trim().isEmpty()) {
            q.setParameter("orderIdSearch", "%" + orderIdSearch.trim() + "%");
        }
    }

    /** Chi tiết đơn cho Customer, chỉ khi đúng chủ sở hữu (chống IDOR - trả null để servlet map 404). */
    public Map<String, Object> getDetailForCustomer(int customerId, int orderId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            ServiceOrder o = em.find(ServiceOrder.class, orderId);
            if (o == null || o.getCustomerID() != customerId) return null;

            SportService svc = em.find(SportService.class, o.getServiceID());
            CoSo coSo = em.find(CoSo.class, o.getCoSoID());

            Map<String, Object> m = new LinkedHashMap<>();
            m.put("orderId", o.getOrderID());
            m.put("displayCode", "DV" + String.format("%06d", o.getOrderID()));
            m.put("status", o.getStatus());
            m.put("uiStatusGroup", uiStatusGroup(o.getStatus()));
            m.put("requestedAt", str(o.getRequestedAt()));
            m.put("serviceName", svc != null ? svc.getServiceName() : null);
            m.put("serviceType", svc != null ? svc.getServiceType() : null);
            m.put("coSoName", coSo != null ? coSo.getTenCoSo() : null);
            m.put("coSoAddress", coSo != null ? coSo.getDiaChi() : null);
            m.put("coSoPhone", coSo != null ? coSo.getSoDienThoai() : null);
            m.put("coSoGioMoCua", coSo != null && coSo.getGioMoCua() != null ? coSo.getGioMoCua().toString() : null);
            m.put("coSoGioDongCua", coSo != null && coSo.getGioDongCua() != null ? coSo.getGioDongCua().toString() : null);
            m.put("bookingId", o.getBookingID());
            m.put("appointmentDate", str(o.getAppointmentDate()));
            m.put("dropOffTime", o.getDropOffTime());
            m.put("expectedPickupTime", str(o.getExpectedPickupTime()));
            m.put("actualReceivedTime", str(o.getActualReceivedTime()));
            m.put("completedTime", str(o.getCompletedTime()));
            m.put("deliveredTime", str(o.getDeliveredTime()));
            m.put("cancelledTime", str(o.getCancelledTime()));
            m.put("customerNote", o.getCustomerNote());
            m.put("estimatedPrice", o.getEstimatedPrice());
            m.put("confirmedPrice", o.getConfirmedPrice());
            m.put("priceChanged", o.getConfirmedPrice() != null
                    && Math.abs(o.getConfirmedPrice() - o.getEstimatedPrice()) > 0.009);
            m.put("cancellationReason", o.getCancellationReason());
            m.put("cancellable", customerCanCancel(o.getStatus()));

            if (svc != null && "CANG_LUOI".equals(svc.getServiceType())) {
                RacketStringingOrderDetail rd = em.createQuery(
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
                    if (rd.getMaterialID() != null) {
                        ServiceMaterial mat = em.find(ServiceMaterial.class, rd.getMaterialID());
                        if (mat != null) {
                            rc.put("materialName", mat.getName());
                            rc.put("materialPrice", mat.getPrice());
                            rc.put("materialExtraFee", mat.getExtraFee());
                        }
                    }
                    m.put("racketDetail", rc);
                }
            }

            List<Map<String, Object>> timeline = new ArrayList<>();
            List<ServiceOrderStatusHistory> history = em.createQuery(
                    "SELECT h FROM ServiceOrderStatusHistory h WHERE h.orderID = :oid ORDER BY h.changedAt ASC",
                    ServiceOrderStatusHistory.class)
                    .setParameter("oid", orderId)
                    .getResultList();
            for (ServiceOrderStatusHistory h : history) {
                Map<String, Object> t = new LinkedHashMap<>();
                t.put("toStatus", h.getToStatus());
                t.put("changedAt", str(h.getChangedAt()));
                t.put("note", h.getNote());
                t.put("actorLabel", actorLabel(h, customerId));
                timeline.add(t);
            }
            m.put("timeline", timeline);

            return m;
        } finally {
            em.close();
        }
    }

    /** Actor kỹ thuật (account ID/role) không bao giờ trả thô cho Customer - chỉ nhãn đã làm sạch. */
    private String actorLabel(ServiceOrderStatusHistory h, int customerId) {
        if (h.getChangedBy() == null) return "Hệ thống";
        if (h.getChangedBy() == customerId) return "Bạn";
        return "Cơ sở";
    }

    private static String str(Object o) { return o == null ? null : o.toString(); }

    /**
     * Customer tự hủy đơn (PHẦN 11). Chỉ cho phép ở PENDING_CONFIRMATION/CONFIRMED
     * và CONFIRMED chỉ khi cơ sở CHƯA nhận dụng cụ (ActualReceivedTime null) - từ
     * ITEM_RECEIVED trở đi Customer không tự hủy được qua UI này.
     */
    public CancelResult cancelOrderByCustomer(int customerId, int orderId, String reason) {
        if (reason == null || reason.trim().isEmpty()) {
            return CancelResult.fail(CancelErrorCode.VALIDATION, "Vui lòng nhập lý do hủy.");
        }
        if (reason.trim().length() > 500) {
            return CancelResult.fail(CancelErrorCode.VALIDATION, "Lý do hủy không được vượt quá 500 ký tự.");
        }
        String cleanReason = reason.trim();

        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();
            ServiceOrder order = em.find(ServiceOrder.class, orderId, LockModeType.PESSIMISTIC_WRITE);
            if (order == null) {
                tx.rollback();
                return CancelResult.fail(CancelErrorCode.NOT_FOUND, "Không tìm thấy đơn dịch vụ.");
            }
            if (order.getCustomerID() != customerId) {
                tx.rollback();
                logger.warn("IDOR attempt: customerId={} tried to cancel orderId={} belonging to customerId={}",
                        customerId, orderId, order.getCustomerID());
                return CancelResult.fail(CancelErrorCode.NOT_FOUND, "Không tìm thấy đơn dịch vụ.");
            }
            String fromStatus = order.getStatus();
            boolean allowed = ServiceOrder.PENDING_CONFIRMATION.equals(fromStatus)
                    || (ServiceOrder.CONFIRMED.equals(fromStatus) && order.getActualReceivedTime() == null);
            if (!allowed) {
                tx.rollback();
                return CancelResult.fail(CancelErrorCode.CONFLICT,
                        "Không thể hủy đơn ở trạng thái hiện tại. Đơn có thể đã được cập nhật - vui lòng tải lại.");
            }

            order.setStatus(ServiceOrder.CANCELLED);
            order.setCancellationReason(cleanReason);
            order.setCancelledTime(LocalDateTime.now());
            order.setUpdatedAt(LocalDateTime.now());
            em.merge(order);

            ServiceOrderStatusHistory history = new ServiceOrderStatusHistory();
            history.setOrderID(orderId);
            history.setFromStatus(fromStatus);
            history.setToStatus(ServiceOrder.CANCELLED);
            history.setChangedBy(customerId);
            history.setChangedAt(LocalDateTime.now());
            history.setNote(cleanReason);
            em.persist(history);

            tx.commit();
            return CancelResult.ok(order);
        } catch (Exception e) {
            if (tx.isActive()) tx.rollback();
            logger.error("Lỗi hủy đơn orderId={} customerId={}: {}", orderId, customerId, e.getMessage(), e);
            return CancelResult.fail(CancelErrorCode.SYSTEM, "Lỗi hệ thống khi hủy đơn dịch vụ.");
        } finally {
            em.close();
        }
    }
}
