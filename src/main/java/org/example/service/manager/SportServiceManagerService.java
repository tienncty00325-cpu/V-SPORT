package org.example.service.manager;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityTransaction;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.model.RacketStringingConfig;
import org.example.model.ServiceMaterial;
import org.example.model.SportService;
import org.example.util.JPAUtil;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Lõi nghiệp vụ CRUD dịch vụ thể thao của Manager (Giai đoạn 1 - PHẦN 7). Mọi
 * thao tác đều xác định coSoId từ tham số truyền vào bởi caller (servlet), caller
 * PHẢI lấy coSoId từ session.user, không bao giờ tin request param trực tiếp.
 */
public class SportServiceManagerService {

    private static final Logger logger = LogManager.getLogger(SportServiceManagerService.class);

    public static class Result {
        public final boolean success;
        public final String errorMessage;
        public final Object data;

        private Result(boolean success, String errorMessage, Object data) {
            this.success = success;
            this.errorMessage = errorMessage;
            this.data = data;
        }

        static Result ok(Object data) { return new Result(true, null, data); }
        static Result fail(String message) { return new Result(false, message, null); }
    }

    public List<SportService> listByCoSo(int coSoId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                    "SELECT s FROM SportService s WHERE s.coSoID = :coSoId AND s.deleted = false ORDER BY s.updatedAt DESC",
                    SportService.class)
                    .setParameter("coSoId", coSoId)
                    .getResultList();
        } finally {
            em.close();
        }
    }

    public SportService findByIdAndCoSo(int serviceId, int coSoId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            SportService s = em.find(SportService.class, serviceId);
            if (s == null || s.getCoSoID() != coSoId || s.isDeleted()) return null;
            return s;
        } finally {
            em.close();
        }
    }

    public RacketStringingConfig findConfigByService(int serviceId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                    "SELECT c FROM RacketStringingConfig c WHERE c.serviceID = :sid", RacketStringingConfig.class)
                    .setParameter("sid", serviceId)
                    .getResultStream().findFirst().orElse(null);
        } finally {
            em.close();
        }
    }

    private static final java.util.Set<String> VALID_SERVICE_TYPES = java.util.Set.of(
            "CANG_LUOI", "THAY_QUAN_CAN", "SUA_VOT", "BAO_DUONG", "HUAN_LUYEN_VIEN", "KHAC");

    public Result createService(int coSoId, SportService input, RacketStringingConfig config) {
        Result v = validateService(input);
        if (!v.success) return v;
        if ("CANG_LUOI".equals(input.getServiceType())) {
            Result cv = validateConfig(config);
            if (!cv.success) return cv;
        }
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();
            input.setCoSoID(coSoId);
            input.setDeleted(false);
            input.setCreatedAt(LocalDateTime.now());
            input.setUpdatedAt(LocalDateTime.now());
            em.persist(input);
            if ("CANG_LUOI".equals(input.getServiceType()) && config != null) {
                config.setServiceID(input.getServiceID());
                em.persist(config);
            }
            tx.commit();
            return Result.ok(input);
        } catch (Exception e) {
            if (tx.isActive()) tx.rollback();
            logger.error("Lỗi tạo dịch vụ coSoId={}: {}", coSoId, e.getMessage(), e);
            return Result.fail("Lỗi hệ thống khi tạo dịch vụ.");
        } finally {
            em.close();
        }
    }

    public Result updateService(int coSoId, int serviceId, SportService input, RacketStringingConfig config) {
        Result v = validateService(input);
        if (!v.success) return v;
        if ("CANG_LUOI".equals(input.getServiceType())) {
            Result cv = validateConfig(config);
            if (!cv.success) return cv;
        }
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();
            SportService existing = em.find(SportService.class, serviceId);
            if (existing == null || existing.getCoSoID() != coSoId || existing.isDeleted()) {
                tx.rollback();
                return Result.fail("Dịch vụ không tồn tại hoặc không thuộc cơ sở này.");
            }
            existing.setServiceType(input.getServiceType());
            existing.setServiceName(input.getServiceName());
            existing.setSportType(input.getSportType());
            existing.setDescription(input.getDescription());
            existing.setBasePrice(input.getBasePrice());
            existing.setUnit(input.getUnit());
            existing.setEstimatedMinutes(input.getEstimatedMinutes());
            existing.setMaxRequestsPerDay(input.getMaxRequestsPerDay());
            existing.setReceiveTimeStart(input.getReceiveTimeStart());
            existing.setReceiveTimeEnd(input.getReceiveTimeEnd());
            existing.setImageUrl(input.getImageUrl());
            existing.setAcceptingRequests(input.isAcceptingRequests());
            existing.setPolicy(input.getPolicy());
            existing.setCustomerNote(input.getCustomerNote());
            existing.setUpdatedAt(LocalDateTime.now());

            RacketStringingConfig existingConfig = em.createQuery(
                    "SELECT c FROM RacketStringingConfig c WHERE c.serviceID = :sid", RacketStringingConfig.class)
                    .setParameter("sid", serviceId)
                    .getResultStream().findFirst().orElse(null);

            if ("CANG_LUOI".equals(input.getServiceType()) && config != null) {
                if (existingConfig == null) {
                    config.setServiceID(serviceId);
                    em.persist(config);
                } else {
                    existingConfig.setRacketTypes(config.getRacketTypes());
                    existingConfig.setStringingPrice(config.getStringingPrice());
                    existingConfig.setMinTension(config.getMinTension());
                    existingConfig.setMaxTension(config.getMaxTension());
                    existingConfig.setTensionUnit(config.getTensionUnit());
                    existingConfig.setAllowCustomerString(config.isAllowCustomerString());
                    existingConfig.setSellsString(config.isSellsString());
                    existingConfig.setAvgCompletionMinutes(config.getAvgCompletionMinutes());
                    existingConfig.setMaxRacketsPerOrder(config.getMaxRacketsPerOrder());
                    existingConfig.setOldRacketPolicy(config.getOldRacketPolicy());
                    existingConfig.setStringBreakPolicy(config.getStringBreakPolicy());
                }
            } else if (existingConfig != null) {
                em.remove(existingConfig);
            }

            tx.commit();
            return Result.ok(existing);
        } catch (Exception e) {
            if (tx.isActive()) tx.rollback();
            logger.error("Lỗi cập nhật dịch vụ serviceId={}: {}", serviceId, e.getMessage(), e);
            return Result.fail("Lỗi hệ thống khi cập nhật dịch vụ.");
        } finally {
            em.close();
        }
    }

    public Result softDeleteService(int coSoId, int serviceId) {
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();
            SportService existing = em.find(SportService.class, serviceId);
            if (existing == null || existing.getCoSoID() != coSoId) {
                tx.rollback();
                return Result.fail("Dịch vụ không tồn tại hoặc không thuộc cơ sở này.");
            }
            existing.setDeleted(true);
            existing.setUpdatedAt(LocalDateTime.now());
            tx.commit();
            return Result.ok(existing);
        } catch (Exception e) {
            if (tx.isActive()) tx.rollback();
            logger.error("Lỗi xóa dịch vụ serviceId={}: {}", serviceId, e.getMessage(), e);
            return Result.fail("Lỗi hệ thống khi xóa dịch vụ.");
        } finally {
            em.close();
        }
    }

    public Result toggleAccepting(int coSoId, int serviceId, boolean accepting) {
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();
            SportService existing = em.find(SportService.class, serviceId);
            if (existing == null || existing.getCoSoID() != coSoId || existing.isDeleted()) {
                tx.rollback();
                return Result.fail("Dịch vụ không tồn tại hoặc không thuộc cơ sở này.");
            }
            existing.setAcceptingRequests(accepting);
            existing.setUpdatedAt(LocalDateTime.now());
            tx.commit();
            return Result.ok(existing);
        } catch (Exception e) {
            if (tx.isActive()) tx.rollback();
            return Result.fail("Lỗi hệ thống.");
        } finally {
            em.close();
        }
    }

    // ── Vật tư dịch vụ (dây cước, quấn cán...) ──────────────────────────────
    private static final java.util.Set<String> VALID_MATERIAL_STATUS = java.util.Set.of(
            "DANG_CO", "TAM_HET", "NGUNG_SU_DUNG");

    public List<ServiceMaterial> listMaterials(int coSoId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                    "SELECT m FROM ServiceMaterial m WHERE m.coSoID = :coSoId AND m.deleted = false ORDER BY m.updatedAt DESC",
                    ServiceMaterial.class)
                    .setParameter("coSoId", coSoId)
                    .getResultList();
        } finally {
            em.close();
        }
    }

    public Result createMaterial(int coSoId, ServiceMaterial input) {
        Result v = validateMaterial(input);
        if (!v.success) return v;
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();
            input.setCoSoID(coSoId);
            input.setDeleted(false);
            input.setCreatedAt(LocalDateTime.now());
            input.setUpdatedAt(LocalDateTime.now());
            em.persist(input);
            tx.commit();
            return Result.ok(input);
        } catch (Exception e) {
            if (tx.isActive()) tx.rollback();
            logger.error("Lỗi tạo vật tư coSoId={}: {}", coSoId, e.getMessage(), e);
            return Result.fail("Lỗi hệ thống khi tạo vật tư.");
        } finally {
            em.close();
        }
    }

    public Result updateMaterial(int coSoId, int materialId, ServiceMaterial input) {
        Result v = validateMaterial(input);
        if (!v.success) return v;
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();
            ServiceMaterial existing = em.find(ServiceMaterial.class, materialId);
            if (existing == null || existing.getCoSoID() != coSoId || existing.isDeleted()) {
                tx.rollback();
                return Result.fail("Vật tư không tồn tại hoặc không thuộc cơ sở này.");
            }
            existing.setName(input.getName());
            existing.setBrand(input.getBrand());
            existing.setCode(input.getCode());
            existing.setColor(input.getColor());
            existing.setSportType(input.getSportType());
            existing.setPrice(input.getPrice());
            existing.setExtraFee(input.getExtraFee());
            existing.setStatus(input.getStatus());
            existing.setDescription(input.getDescription());
            existing.setUpdatedAt(LocalDateTime.now());
            tx.commit();
            return Result.ok(existing);
        } catch (Exception e) {
            if (tx.isActive()) tx.rollback();
            logger.error("Lỗi cập nhật vật tư materialId={}: {}", materialId, e.getMessage(), e);
            return Result.fail("Lỗi hệ thống khi cập nhật vật tư.");
        } finally {
            em.close();
        }
    }

    public Result softDeleteMaterial(int coSoId, int materialId) {
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction tx = em.getTransaction();
        try {
            tx.begin();
            ServiceMaterial existing = em.find(ServiceMaterial.class, materialId);
            if (existing == null || existing.getCoSoID() != coSoId) {
                tx.rollback();
                return Result.fail("Vật tư không tồn tại hoặc không thuộc cơ sở này.");
            }
            existing.setDeleted(true);
            existing.setUpdatedAt(LocalDateTime.now());
            tx.commit();
            return Result.ok(existing);
        } catch (Exception e) {
            if (tx.isActive()) tx.rollback();
            return Result.fail("Lỗi hệ thống khi xóa vật tư.");
        } finally {
            em.close();
        }
    }

    // ── Validation (PHẦN 7, PHẦN 20 constraint) ─────────────────────────────
    private Result validateService(SportService s) {
        if (s == null) return Result.fail("Thiếu dữ liệu dịch vụ.");
        if (s.getServiceName() == null || s.getServiceName().trim().isEmpty()) {
            return Result.fail("Tên dịch vụ không được trống.");
        }
        if (s.getServiceName().trim().length() > 150) {
            return Result.fail("Tên dịch vụ không được vượt quá 150 ký tự.");
        }
        if (s.getServiceType() == null || !VALID_SERVICE_TYPES.contains(s.getServiceType())) {
            return Result.fail("Loại dịch vụ không hợp lệ.");
        }
        if (s.getBasePrice() < 0) {
            return Result.fail("Giá dịch vụ không được là số âm.");
        }
        if (s.getEstimatedMinutes() <= 0) {
            return Result.fail("Thời gian thực hiện dự kiến phải lớn hơn 0.");
        }
        if (s.getMaxRequestsPerDay() != null && s.getMaxRequestsPerDay() <= 0) {
            return Result.fail("Số yêu cầu tối đa mỗi ngày phải lớn hơn 0.");
        }
        return Result.ok(null);
    }

    private Result validateConfig(RacketStringingConfig c) {
        if (c == null) return Result.fail("Thiếu cấu hình căng lưới.");
        if (c.getStringingPrice() < 0) return Result.fail("Giá công căng không được là số âm.");
        if (!"kg".equals(c.getTensionUnit()) && !"lbs".equals(c.getTensionUnit())) {
            return Result.fail("Đơn vị mức căng không hợp lệ (chỉ nhận kg hoặc lbs).");
        }
        if (c.getMinTension() <= 0 || c.getMaxTension() < c.getMinTension()) {
            return Result.fail("Khoảng mức căng không hợp lệ.");
        }
        if (c.getMaxRacketsPerOrder() <= 0) {
            return Result.fail("Số vợt tối đa mỗi đơn phải lớn hơn 0.");
        }
        return Result.ok(null);
    }

    private Result validateMaterial(ServiceMaterial m) {
        if (m == null) return Result.fail("Thiếu dữ liệu vật tư.");
        if (m.getName() == null || m.getName().trim().isEmpty()) {
            return Result.fail("Tên vật tư không được trống.");
        }
        if (m.getPrice() < 0 || m.getExtraFee() < 0) {
            return Result.fail("Giá vật tư và phụ phí không được là số âm.");
        }
        if (m.getStatus() == null || !VALID_MATERIAL_STATUS.contains(m.getStatus())) {
            return Result.fail("Trạng thái vật tư không hợp lệ.");
        }
        return Result.ok(null);
    }
}
