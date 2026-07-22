package org.example.service.admin;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityTransaction;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.model.CoSoCapability;
import org.example.util.Constants;
import org.example.util.JPAUtil;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Lõi nghiệp vụ đăng ký/phê duyệt "loại hình kinh doanh" (capability) của một cơ sở,
 * tách biệt hoàn toàn khỏi CoSo.TrangThai (trạng thái duyệt cơ sở tổng thể - xem
 * OwnerApprovalService). Một cơ sở bị từ chối/tạm ngưng không được coi là đã duyệt
 * bất kỳ capability nào, dù trước đó capability đó từng ở trạng thái APPROVED.
 */
public class CapabilityApprovalService {

    private static final Logger logger = LogManager.getLogger(CapabilityApprovalService.class);

    public static class Result {
        public final boolean success;
        public final String errorMessage;
        public final CoSoCapability capability;

        private Result(boolean success, String errorMessage, CoSoCapability capability) {
            this.success = success;
            this.errorMessage = errorMessage;
            this.capability = capability;
        }

        static Result ok(CoSoCapability capability) { return new Result(true, null, capability); }
        static Result fail(String message) { return new Result(false, message, null); }
    }

    /**
     * Tạo các bản ghi capability PENDING theo lựa chọn của Owner khi đăng ký cơ sở.
     * PHẢI được gọi bên trong transaction đang mở của lời gọi (dùng chung EntityManager
     * với việc persist CoSo), để không có tình trạng CoSo được tạo nhưng capability bị
     * mất do lỗi giữa chừng. Chỉ chấp nhận các type nằm trong whitelist
     * Constants.OWNER_SELECTABLE_CAPABILITIES - không tin danh sách gửi từ client.
     */
    public void registerPending(EntityManager em, int coSoId, List<String> requestedTypes) {
        if (requestedTypes == null || requestedTypes.isEmpty()) return;
        Set<String> distinct = new LinkedHashSet<>(requestedTypes);
        for (String type : distinct) {
            if (type == null || !Constants.OWNER_SELECTABLE_CAPABILITIES.contains(type)) {
                continue; // bỏ qua giá trị không hợp lệ/không nằm trong whitelist thay vì tin client
            }
            CoSoCapability cap = new CoSoCapability();
            cap.setCoSoId(coSoId);
            cap.setCapabilityType(type);
            cap.setTrangThai(Constants.CAPABILITY_STATUS_PENDING);
            em.persist(cap);
        }
    }

    /**
     * Kích hoạt capability SAN (cho thuê sân) = APPROVED ngay khi Admin duyệt cơ sở.
     * Đây không phải một lựa chọn của Owner - là chức năng nền tảng của mọi cơ sở đã
     * được duyệt. Mở transaction riêng, gọi ngay sau khi OwnerApprovalService.approve()
     * thành công (xem AdminOwnerServlet).
     */
    public void activateCourtCapability(int coSoId, int adminId) {
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();
            CoSoCapability existing = em.createQuery(
                    "SELECT c FROM CoSoCapability c WHERE c.coSoId = :coSoId AND c.capabilityType = :type",
                    CoSoCapability.class)
                    .setParameter("coSoId", coSoId)
                    .setParameter("type", Constants.CAPABILITY_SAN)
                    .getResultStream().findFirst().orElse(null);
            if (existing == null) {
                existing = new CoSoCapability();
                existing.setCoSoId(coSoId);
                existing.setCapabilityType(Constants.CAPABILITY_SAN);
                em.persist(existing);
            }
            existing.setTrangThai(Constants.CAPABILITY_STATUS_APPROVED);
            existing.setApprovedBy(adminId);
            existing.setApprovedAt(LocalDateTime.now());
            tx.commit();
        } catch (Exception e) {
            if (tx.isActive()) tx.rollback();
            logger.error("Lỗi kích hoạt capability SAN coSoId={}: {}", coSoId, e.getMessage(), e);
        } finally {
            em.close();
        }
    }

    public Result approve(int capabilityId, int adminId, String note) {
        return transition(capabilityId, Constants.CAPABILITY_STATUS_APPROVED,
                Set.of(Constants.CAPABILITY_STATUS_PENDING, Constants.CAPABILITY_STATUS_SUSPENDED),
                "Chỉ có thể duyệt capability đang ở trạng thái chờ duyệt hoặc tạm ngưng.",
                adminId, note, null);
    }

    public Result reject(int capabilityId, int adminId, String reason) {
        if (reason == null || reason.trim().isEmpty()) {
            return Result.fail("Vui lòng nhập lý do từ chối.");
        }
        return transition(capabilityId, Constants.CAPABILITY_STATUS_REJECTED,
                Set.of(Constants.CAPABILITY_STATUS_PENDING),
                "Chỉ có thể từ chối capability đang chờ duyệt.",
                adminId, null, reason);
    }

    public Result suspend(int capabilityId, int adminId, String reason) {
        if (reason == null || reason.trim().isEmpty()) {
            return Result.fail("Vui lòng nhập lý do tạm ngưng.");
        }
        return transition(capabilityId, Constants.CAPABILITY_STATUS_SUSPENDED,
                Set.of(Constants.CAPABILITY_STATUS_APPROVED),
                "Chỉ có thể tạm ngưng capability đã được duyệt.",
                adminId, null, reason);
    }

    public Result disable(int capabilityId, int adminId, String note) {
        return transition(capabilityId, Constants.CAPABILITY_STATUS_DISABLED,
                Set.of(Constants.CAPABILITY_STATUS_APPROVED, Constants.CAPABILITY_STATUS_SUSPENDED),
                "Chỉ có thể tắt capability đang hoạt động hoặc tạm ngưng.",
                adminId, note, null);
    }

    private Result transition(int capabilityId, String newStatus, Set<String> allowedFrom,
                               String errorIfInvalid, int adminId, String note, String reason) {
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();
            CoSoCapability cap = em.find(CoSoCapability.class, capabilityId);
            if (cap == null) {
                tx.rollback();
                return Result.fail("Không tìm thấy yêu cầu capability.");
            }
            if (!allowedFrom.contains(cap.getTrangThai())) {
                tx.rollback();
                return Result.fail(errorIfInvalid);
            }
            cap.setTrangThai(newStatus);
            if (Constants.CAPABILITY_STATUS_APPROVED.equals(newStatus)) {
                cap.setApprovedBy(adminId);
                cap.setApprovedAt(LocalDateTime.now());
                cap.setRejectReason(null);
            }
            if (reason != null) cap.setRejectReason(reason);
            if (note != null) cap.setNote(note);
            tx.commit();
            return Result.ok(cap);
        } catch (Exception e) {
            if (tx.isActive()) tx.rollback();
            logger.error("Lỗi chuyển trạng thái capabilityId={} -> {}: {}", capabilityId, newStatus, e.getMessage(), e);
            return Result.fail("Lỗi hệ thống khi cập nhật capability.");
        } finally {
            em.close();
        }
    }
}
