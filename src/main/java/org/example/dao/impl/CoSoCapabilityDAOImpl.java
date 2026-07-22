package org.example.dao.impl;

import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.dao.CoSoCapabilityDAO;
import org.example.model.CoSoCapability;
import org.example.util.Constants;
import org.example.util.JPAUtil;

import java.util.Collections;
import java.util.List;

/**
 * Mọi truy vấn ở đây fail-safe (không ném exception ra ngoài) - lớp này được gọi từ
 * rất nhiều nơi (Filter, sidebar Manager, API Customer, trang Admin). Nếu bảng
 * CoSoCapability chưa được migrate hoặc DB có sự cố tạm thời, các trang KHÔNG liên
 * quan trực tiếp đến capability (vd toàn bộ khu vực Manager, trang Owner của Admin)
 * không được phép sập theo. Mặc định an toàn: coi như CHƯA duyệt (false/rỗng) khi có lỗi,
 * không bao giờ mặc định là "đã duyệt".
 */
public class CoSoCapabilityDAOImpl implements CoSoCapabilityDAO {

    private static final Logger logger = LogManager.getLogger(CoSoCapabilityDAOImpl.class);

    @Override
    public List<CoSoCapability> findByCoSoId(int coSoId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                    "SELECT c FROM CoSoCapability c WHERE c.coSoId = :coSoId ORDER BY c.capabilityType",
                    CoSoCapability.class)
                    .setParameter("coSoId", coSoId)
                    .getResultList();
        } catch (Exception e) {
            logger.error("Lỗi truy vấn CoSoCapability.findByCoSoId(coSoId={}): {}", coSoId, e.getMessage(), e);
            return Collections.emptyList();
        } finally {
            em.close();
        }
    }

    @Override
    public CoSoCapability findByCoSoIdAndType(int coSoId, String capabilityType) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                    "SELECT c FROM CoSoCapability c WHERE c.coSoId = :coSoId AND c.capabilityType = :type",
                    CoSoCapability.class)
                    .setParameter("coSoId", coSoId)
                    .setParameter("type", capabilityType)
                    .getSingleResult();
        } catch (NoResultException e) {
            return null;
        } catch (Exception e) {
            logger.error("Lỗi truy vấn CoSoCapability.findByCoSoIdAndType(coSoId={}, type={}): {}",
                    coSoId, capabilityType, e.getMessage(), e);
            return null;
        } finally {
            em.close();
        }
    }

    @Override
    public CoSoCapability findById(int capabilityId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.find(CoSoCapability.class, capabilityId);
        } catch (Exception e) {
            logger.error("Lỗi truy vấn CoSoCapability.findById(capabilityId={}): {}", capabilityId, e.getMessage(), e);
            return null;
        } finally {
            em.close();
        }
    }

    // Luôn kiểm tra thêm CoSo còn "Đang hoạt động" và chưa bị xóa mềm - một capability
    // APPROVED trên một cơ sở đã bị từ chối/khóa/xóa KHÔNG được coi là hợp lệ. Tránh
    // đúng lỗi "cơ sở bị từ chối nhưng module bán hàng vẫn bật" mà spec yêu cầu chặn.
    @Override
    public boolean isApproved(int coSoId, String capabilityType) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            Long count = em.createQuery(
                    "SELECT COUNT(c) FROM CoSoCapability c, CoSo s " +
                    "WHERE c.coSoId = :coSoId AND s.CoSoID = :coSoId AND c.capabilityType = :type " +
                    "AND c.trangThai = :approved AND s.TrangThai = :active " +
                    "AND (s.isDeleted = false OR s.isDeleted IS NULL)", Long.class)
                    .setParameter("coSoId", coSoId)
                    .setParameter("type", capabilityType)
                    .setParameter("approved", Constants.CAPABILITY_STATUS_APPROVED)
                    .setParameter("active", "Đang hoạt động")
                    .getSingleResult();
            return count != null && count > 0;
        } catch (Exception e) {
            logger.error("Lỗi truy vấn CoSoCapability.isApproved(coSoId={}, type={}): {}",
                    coSoId, capabilityType, e.getMessage(), e);
            return false;
        } finally {
            em.close();
        }
    }

    @Override
    public boolean isApprovedAny(int coSoId, List<String> capabilityTypes) {
        if (capabilityTypes == null || capabilityTypes.isEmpty()) return false;
        EntityManager em = JPAUtil.getEntityManager();
        try {
            Long count = em.createQuery(
                    "SELECT COUNT(c) FROM CoSoCapability c, CoSo s " +
                    "WHERE c.coSoId = :coSoId AND s.CoSoID = :coSoId AND c.capabilityType IN :types " +
                    "AND c.trangThai = :approved AND s.TrangThai = :active " +
                    "AND (s.isDeleted = false OR s.isDeleted IS NULL)", Long.class)
                    .setParameter("coSoId", coSoId)
                    .setParameter("types", capabilityTypes)
                    .setParameter("approved", Constants.CAPABILITY_STATUS_APPROVED)
                    .setParameter("active", "Đang hoạt động")
                    .getSingleResult();
            return count != null && count > 0;
        } catch (Exception e) {
            logger.error("Lỗi truy vấn CoSoCapability.isApprovedAny(coSoId={}, types={}): {}",
                    coSoId, capabilityTypes, e.getMessage(), e);
            return false;
        } finally {
            em.close();
        }
    }

    @Override
    public List<String> findApprovedTypes(int coSoId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                    "SELECT c.capabilityType FROM CoSoCapability c, CoSo s " +
                    "WHERE c.coSoId = :coSoId AND s.CoSoID = :coSoId AND c.trangThai = :approved " +
                    "AND s.TrangThai = :active AND (s.isDeleted = false OR s.isDeleted IS NULL)",
                    String.class)
                    .setParameter("coSoId", coSoId)
                    .setParameter("approved", Constants.CAPABILITY_STATUS_APPROVED)
                    .setParameter("active", "Đang hoạt động")
                    .getResultList();
        } catch (Exception e) {
            logger.error("Lỗi truy vấn CoSoCapability.findApprovedTypes(coSoId={}): {}", coSoId, e.getMessage(), e);
            return Collections.emptyList();
        } finally {
            em.close();
        }
    }
}
