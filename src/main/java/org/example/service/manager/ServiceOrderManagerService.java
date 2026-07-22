package org.example.service.manager;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityTransaction;
import jakarta.persistence.LockModeType;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.model.ServiceOrder;
import org.example.model.ServiceOrderStatusHistory;
import org.example.util.JPAUtil;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * State machine + xử lý đơn dịch vụ cho Manager (PHẦN 13/14 Task 6). Mọi
 * transition đều: (1) khóa hàng bằng PESSIMISTIC_WRITE chống double-submit,
 * (2) xác nhận đơn thuộc đúng cơ sở của Manager, (3) kiểm tra transition hợp
 * lệ theo bảng ma trận cố định, (4) ghi ServiceOrderStatusHistory trong CÙNG
 * transaction. Không có endpoint "updateStatus(orderId, newStatus)" tự do.
 */
public class ServiceOrderManagerService {

    private static final Logger logger = LogManager.getLogger(ServiceOrderManagerService.class);

    public enum ErrorCode { NOT_FOUND, FORBIDDEN, INVALID_TRANSITION, VALIDATION, CONFLICT, SYSTEM }

    public static class Result {
        public final boolean success;
        public final ErrorCode errorCode;
        public final String errorMessage;
        public final ServiceOrder order;

        private Result(boolean success, ErrorCode errorCode, String errorMessage, ServiceOrder order) {
            this.success = success;
            this.errorCode = errorCode;
            this.errorMessage = errorMessage;
            this.order = order;
        }

        static Result ok(ServiceOrder o) { return new Result(true, null, null, o); }
        public static Result fail(ErrorCode code, String message) { return new Result(false, code, message, null); }
    }

    /** Bảng transition hợp lệ: trạng thái hiện tại -> tập trạng thái đích được phép. */
    private static final Map<String, Set<String>> VALID_TRANSITIONS = new HashMap<>();
    static {
        VALID_TRANSITIONS.put(ServiceOrder.PENDING_CONFIRMATION,
                Set.of(ServiceOrder.CONFIRMED, ServiceOrder.REJECTED, ServiceOrder.CANCELLED));
        VALID_TRANSITIONS.put(ServiceOrder.CONFIRMED,
                Set.of(ServiceOrder.ITEM_RECEIVED, ServiceOrder.CANCELLED));
        VALID_TRANSITIONS.put(ServiceOrder.ITEM_RECEIVED, Set.of(ServiceOrder.IN_PROGRESS));
        VALID_TRANSITIONS.put(ServiceOrder.IN_PROGRESS, Set.of(ServiceOrder.READY_FOR_PICKUP));
        VALID_TRANSITIONS.put(ServiceOrder.READY_FOR_PICKUP, Set.of(ServiceOrder.COMPLETED));
        VALID_TRANSITIONS.put(ServiceOrder.COMPLETED, Set.of());
        VALID_TRANSITIONS.put(ServiceOrder.REJECTED, Set.of());
        VALID_TRANSITIONS.put(ServiceOrder.CANCELLED, Set.of());
    }

    private static boolean canTransition(String from, String to) {
        Set<String> allowed = VALID_TRANSITIONS.get(from);
        return allowed != null && allowed.contains(to);
    }

    /** Trả về "hành động hợp lệ hiện tại" để UI chỉ hiển thị đúng nút cho từng trạng thái. */
    public static Set<String> allowedNextStatuses(String currentStatus) {
        return VALID_TRANSITIONS.getOrDefault(currentStatus, Set.of());
    }

    // ── PENDING_CONFIRMATION -> CONFIRMED ───────────────────────────────────
    public Result confirmOrder(int managerId, int coSoId, int orderId,
                                Double confirmedPrice, LocalDateTime expectedPickupTime, String managerNote) {
        if (confirmedPrice == null || confirmedPrice < 0) {
            return Result.fail(ErrorCode.VALIDATION, "Giá xác nhận không hợp lệ.");
        }
        return transition(coSoId, orderId, ServiceOrder.CONFIRMED, managerId, managerNote, order -> {
            order.setConfirmedPrice(confirmedPrice);
            if (expectedPickupTime != null) order.setExpectedPickupTime(expectedPickupTime);
            if (managerNote != null && !managerNote.trim().isEmpty()) order.setManagerNote(managerNote.trim());
        });
    }

    // ── PENDING_CONFIRMATION -> REJECTED ────────────────────────────────────
    public Result rejectOrder(int managerId, int coSoId, int orderId, String reason) {
        if (reason == null || reason.trim().isEmpty()) {
            return Result.fail(ErrorCode.VALIDATION, "Vui lòng nhập lý do từ chối.");
        }
        if (reason.trim().length() > 500) {
            return Result.fail(ErrorCode.VALIDATION, "Lý do từ chối không được vượt quá 500 ký tự.");
        }
        String cleanReason = reason.trim();
        return transition(coSoId, orderId, ServiceOrder.REJECTED, managerId, cleanReason, order -> {
            order.setCancellationReason(cleanReason);
        });
    }

    // ── CONFIRMED -> ITEM_RECEIVED ──────────────────────────────────────────
    public Result markItemReceived(int managerId, int coSoId, int orderId, String managerNote) {
        return transition(coSoId, orderId, ServiceOrder.ITEM_RECEIVED, managerId, managerNote, order -> {
            order.setActualReceivedTime(LocalDateTime.now());
            if (managerNote != null && !managerNote.trim().isEmpty()) order.setManagerNote(managerNote.trim());
        });
    }

    // ── ITEM_RECEIVED -> IN_PROGRESS ────────────────────────────────────────
    public Result startProcessing(int managerId, int coSoId, int orderId) {
        return transition(coSoId, orderId, ServiceOrder.IN_PROGRESS, managerId, null, order -> {});
    }

    // ── IN_PROGRESS -> READY_FOR_PICKUP ─────────────────────────────────────
    public Result markReadyForPickup(int managerId, int coSoId, int orderId, String managerNote) {
        return transition(coSoId, orderId, ServiceOrder.READY_FOR_PICKUP, managerId, managerNote, order -> {
            order.setCompletedTime(LocalDateTime.now());
            if (managerNote != null && !managerNote.trim().isEmpty()) order.setManagerNote(managerNote.trim());
        });
    }

    // ── READY_FOR_PICKUP -> COMPLETED ───────────────────────────────────────
    public Result completeOrder(int managerId, int coSoId, int orderId) {
        return transition(coSoId, orderId, ServiceOrder.COMPLETED, managerId, null, order -> {
            order.setDeliveredTime(LocalDateTime.now());
        });
    }

    // ── PENDING_CONFIRMATION/CONFIRMED -> CANCELLED (Manager hủy) ───────────
    public Result cancelOrderByManager(int managerId, int coSoId, int orderId, String reason) {
        if (reason == null || reason.trim().isEmpty()) {
            return Result.fail(ErrorCode.VALIDATION, "Vui lòng nhập lý do hủy.");
        }
        String cleanReason = reason.trim();
        return transition(coSoId, orderId, ServiceOrder.CANCELLED, managerId, cleanReason, order -> {
            order.setCancellationReason(cleanReason);
            order.setCancelledTime(LocalDateTime.now());
        });
    }

    @FunctionalInterface
    private interface OrderMutator { void apply(ServiceOrder order); }

    private Result transition(int coSoId, int orderId, String toStatus, int actorId, String note, OrderMutator mutator) {
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();
            // PESSIMISTIC_WRITE - chống 2 request cùng transition 1 đơn (double-click,
            // 2 Manager cùng bấm, browser retry) - PHẦN 21.
            ServiceOrder order = em.find(ServiceOrder.class, orderId, LockModeType.PESSIMISTIC_WRITE);
            if (order == null) {
                tx.rollback();
                return Result.fail(ErrorCode.NOT_FOUND, "Không tìm thấy đơn dịch vụ.");
            }
            if (order.getCoSoID() != coSoId) {
                tx.rollback();
                logger.warn("IDOR attempt: managerId={} coSoId={} tried orderId={} belonging to coSoId={}",
                        actorId, coSoId, orderId, order.getCoSoID());
                return Result.fail(ErrorCode.FORBIDDEN, "Đơn dịch vụ không thuộc cơ sở của bạn.");
            }
            String fromStatus = order.getStatus();
            if (!canTransition(fromStatus, toStatus)) {
                tx.rollback();
                return Result.fail(ErrorCode.CONFLICT,
                        "Không thể thực hiện thao tác ở trạng thái hiện tại. Đơn có thể đã được cập nhật bởi người khác - vui lòng tải lại.");
            }

            mutator.apply(order);
            order.setStatus(toStatus);
            order.setUpdatedAt(LocalDateTime.now());
            em.merge(order);

            ServiceOrderStatusHistory history = new ServiceOrderStatusHistory();
            history.setOrderID(orderId);
            history.setFromStatus(fromStatus);
            history.setToStatus(toStatus);
            history.setChangedBy(actorId);
            history.setChangedAt(LocalDateTime.now());
            history.setNote(note != null && !note.trim().isEmpty() ? note.trim() : null);
            em.persist(history);

            tx.commit();
            return Result.ok(order);
        } catch (Exception e) {
            if (tx.isActive()) tx.rollback();
            logger.error("Lỗi transition orderId={} -> {}: {}", orderId, toStatus, e.getMessage(), e);
            return Result.fail(ErrorCode.SYSTEM, "Lỗi hệ thống khi xử lý đơn dịch vụ.");
        } finally {
            em.close();
        }
    }

    // ── Danh sách & chi tiết (chỉ đọc, scope theo coSoId của Manager) ───────

    public List<ServiceOrder> listByCoSo(int coSoId, List<String> statuses, int limit) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            String jpql = "SELECT o FROM ServiceOrder o WHERE o.coSoID = :coSoId ";
            if (statuses != null && !statuses.isEmpty()) {
                jpql += "AND o.status IN :statuses ";
            }
            jpql += "ORDER BY o.requestedAt DESC";
            jakarta.persistence.TypedQuery<ServiceOrder> q = em.createQuery(jpql, ServiceOrder.class);
            q.setParameter("coSoId", coSoId);
            if (statuses != null && !statuses.isEmpty()) {
                q.setParameter("statuses", statuses);
            }
            q.setMaxResults(Math.min(Math.max(limit, 1), 200));
            return q.getResultList();
        } finally {
            em.close();
        }
    }

    public ServiceOrder getByIdAndCoSo(int coSoId, int orderId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            ServiceOrder order = em.find(ServiceOrder.class, orderId);
            if (order == null || order.getCoSoID() != coSoId) return null;
            return order;
        } finally {
            em.close();
        }
    }

    public List<ServiceOrderStatusHistory> getHistory(int orderId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                    "SELECT h FROM ServiceOrderStatusHistory h WHERE h.orderID = :oid ORDER BY h.changedAt ASC",
                    ServiceOrderStatusHistory.class)
                    .setParameter("oid", orderId)
                    .getResultList();
        } finally {
            em.close();
        }
    }
}
