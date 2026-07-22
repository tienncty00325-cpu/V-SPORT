package org.example.service.customer;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import org.example.util.Constants;
import org.example.util.JPAUtil;

import java.time.LocalTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Tìm kiếm dịch vụ thể thao công khai cho Customer (PHẦN 8/9/10). Chỉ trả về
 * dịch vụ của cơ sở đang hoạt động, có capability DICH_VU_THE_THAO đã APPROVED,
 * và bản thân dịch vụ chưa bị xóa mềm - không bao giờ để lộ dịch vụ của cơ sở
 * bị khóa/capability bị suspend/disabled (PHẦN 8, PHẦN 25).
 */
public class PublicServiceSearchService {

    public static class SearchFilter {
        public String q;
        public String serviceType;
        public String sportType;
        public Integer coSoId;
        public Double maxPrice;
        public Boolean acceptingOnly;
        public Double lat;
        public Double lng;
        public Double radiusKm;
    }

    private static final double EARTH_RADIUS_KM = 6371.0;

    public List<Map<String, Object>> search(SearchFilter f) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            StringBuilder jpql = new StringBuilder(
                    "SELECT s, c FROM SportService s, CoSo c " +
                    "WHERE s.coSoID = c.CoSoID AND s.deleted = false " +
                    "AND c.TrangThai = :active AND (c.isDeleted = false OR c.isDeleted IS NULL) " +
                    "AND EXISTS (SELECT 1 FROM CoSoCapability cc WHERE cc.coSoId = c.CoSoID " +
                    "    AND cc.capabilityType = :capType AND cc.trangThai = :capApproved) ");

            if (f.q != null && !f.q.trim().isEmpty()) {
                jpql.append("AND (LOWER(s.serviceName) LIKE :q OR LOWER(s.description) LIKE :q OR LOWER(s.sportType) LIKE :q) ");
            }
            if (f.serviceType != null && !f.serviceType.trim().isEmpty()) {
                jpql.append("AND s.serviceType = :serviceType ");
            }
            if (f.sportType != null && !f.sportType.trim().isEmpty()) {
                jpql.append("AND LOWER(s.sportType) = :sportType ");
            }
            if (f.coSoId != null) {
                jpql.append("AND c.CoSoID = :coSoId ");
            }
            if (f.maxPrice != null) {
                jpql.append("AND s.basePrice <= :maxPrice ");
            }
            if (Boolean.TRUE.equals(f.acceptingOnly)) {
                jpql.append("AND s.acceptingRequests = true ");
            }
            jpql.append("ORDER BY s.updatedAt DESC");

            Query query = em.createQuery(jpql.toString());
            query.setParameter("active", "Đang hoạt động");
            query.setParameter("capType", Constants.CAPABILITY_DICH_VU_THE_THAO);
            query.setParameter("capApproved", Constants.CAPABILITY_STATUS_APPROVED);
            if (f.q != null && !f.q.trim().isEmpty()) {
                query.setParameter("q", "%" + f.q.trim().toLowerCase() + "%");
            }
            if (f.serviceType != null && !f.serviceType.trim().isEmpty()) {
                query.setParameter("serviceType", f.serviceType.trim());
            }
            if (f.sportType != null && !f.sportType.trim().isEmpty()) {
                query.setParameter("sportType", f.sportType.trim().toLowerCase());
            }
            if (f.coSoId != null) {
                query.setParameter("coSoId", f.coSoId);
            }
            if (f.maxPrice != null) {
                query.setParameter("maxPrice", f.maxPrice);
            }
            query.setMaxResults(200);

            @SuppressWarnings("unchecked")
            List<Object[]> rows = query.getResultList();

            List<Map<String, Object>> results = new ArrayList<>();
            LocalTime now = LocalTime.now();
            for (Object[] row : rows) {
                org.example.model.SportService s = (org.example.model.SportService) row[0];
                org.example.model.CoSo c = (org.example.model.CoSo) row[1];

                Double distanceKm = null;
                if (f.lat != null && f.lng != null && c.getViDo() != null && c.getKinhDo() != null) {
                    distanceKm = haversineKm(f.lat, f.lng, c.getViDo().doubleValue(), c.getKinhDo().doubleValue());
                    if (f.radiusKm != null && distanceKm > f.radiusKm) {
                        continue;
                    }
                }

                Map<String, Object> m = new LinkedHashMap<>();
                m.put("serviceId", s.getServiceID());
                m.put("serviceName", s.getServiceName());
                m.put("serviceType", s.getServiceType());
                m.put("sportType", s.getSportType());
                m.put("description", s.getDescription());
                m.put("basePrice", s.getBasePrice());
                m.put("unit", s.getUnit());
                m.put("estimatedMinutes", s.getEstimatedMinutes());
                m.put("imageUrl", s.getImageUrl());
                m.put("acceptingRequests", s.isAcceptingRequests());
                m.put("coSoId", c.getCoSoID());
                m.put("coSoName", c.getTenCoSo());
                m.put("coSoAddress", c.getDiaChi());
                m.put("gioMoCua", c.getGioMoCua() != null ? c.getGioMoCua().toString() : null);
                m.put("gioDongCua", c.getGioDongCua() != null ? c.getGioDongCua().toString() : null);
                m.put("openNow", isOpenNow(c.getGioMoCua(), c.getGioDongCua(), now));
                if (distanceKm != null) {
                    m.put("distanceKm", Math.round(distanceKm * 100.0) / 100.0);
                }
                results.add(m);
            }

            if (f.lat != null && f.lng != null) {
                results.sort((a, b) -> {
                    Object da = a.get("distanceKm");
                    Object db = b.get("distanceKm");
                    if (da == null && db == null) return 0;
                    if (da == null) return 1;
                    if (db == null) return -1;
                    return Double.compare((Double) da, (Double) db);
                });
            }
            return results;
        } finally {
            em.close();
        }
    }

    /** Chi tiết 1 dịch vụ public (PHẦN 10), gồm cấu hình căng lưới nếu có. */
    public Map<String, Object> detail(int serviceId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            org.example.model.SportService s = em.find(org.example.model.SportService.class, serviceId);
            if (s == null || s.isDeleted()) return null;
            org.example.model.CoSo c = em.find(org.example.model.CoSo.class, s.getCoSoID());
            if (c == null || !"Đang hoạt động".equals(c.getTrangThai())) return null;

            long approvedCount = em.createQuery(
                    "SELECT COUNT(cc) FROM CoSoCapability cc WHERE cc.coSoId = :coSoId " +
                    "AND cc.capabilityType = :capType AND cc.trangThai = :approved", Long.class)
                    .setParameter("coSoId", c.getCoSoID())
                    .setParameter("capType", Constants.CAPABILITY_DICH_VU_THE_THAO)
                    .setParameter("approved", Constants.CAPABILITY_STATUS_APPROVED)
                    .getSingleResult();
            if (approvedCount == 0) return null;

            Map<String, Object> m = new LinkedHashMap<>();
            m.put("serviceId", s.getServiceID());
            m.put("serviceName", s.getServiceName());
            m.put("serviceType", s.getServiceType());
            m.put("sportType", s.getSportType());
            m.put("description", s.getDescription());
            m.put("basePrice", s.getBasePrice());
            m.put("unit", s.getUnit());
            m.put("estimatedMinutes", s.getEstimatedMinutes());
            m.put("imageUrl", s.getImageUrl());
            m.put("acceptingRequests", s.isAcceptingRequests());
            m.put("policy", s.getPolicy());
            m.put("customerNote", s.getCustomerNote());
            m.put("maxRequestsPerDay", s.getMaxRequestsPerDay());
            m.put("receiveTimeStart", s.getReceiveTimeStart() != null ? s.getReceiveTimeStart().toString() : null);
            m.put("receiveTimeEnd", s.getReceiveTimeEnd() != null ? s.getReceiveTimeEnd().toString() : null);
            m.put("coSoId", c.getCoSoID());
            m.put("coSoName", c.getTenCoSo());
            m.put("coSoAddress", c.getDiaChi());
            m.put("gioMoCua", c.getGioMoCua() != null ? c.getGioMoCua().toString() : null);
            m.put("gioDongCua", c.getGioDongCua() != null ? c.getGioDongCua().toString() : null);

            if ("CANG_LUOI".equals(s.getServiceType())) {
                org.example.model.RacketStringingConfig cfg = em.createQuery(
                        "SELECT x FROM RacketStringingConfig x WHERE x.serviceID = :sid",
                        org.example.model.RacketStringingConfig.class)
                        .setParameter("sid", serviceId)
                        .getResultStream().findFirst().orElse(null);
                if (cfg != null) {
                    Map<String, Object> rc = new LinkedHashMap<>();
                    rc.put("racketTypes", cfg.getRacketTypes());
                    rc.put("stringingPrice", cfg.getStringingPrice());
                    rc.put("minTension", cfg.getMinTension());
                    rc.put("maxTension", cfg.getMaxTension());
                    rc.put("tensionUnit", cfg.getTensionUnit());
                    rc.put("allowCustomerString", cfg.isAllowCustomerString());
                    rc.put("sellsString", cfg.isSellsString());
                    rc.put("avgCompletionMinutes", cfg.getAvgCompletionMinutes());
                    rc.put("maxRacketsPerOrder", cfg.getMaxRacketsPerOrder());
                    rc.put("oldRacketPolicy", cfg.getOldRacketPolicy());
                    rc.put("stringBreakPolicy", cfg.getStringBreakPolicy());
                    m.put("racketConfig", rc);

                    List<Map<String, Object>> materials = new ArrayList<>();
                    List<org.example.model.ServiceMaterial> mats = em.createQuery(
                            "SELECT x FROM ServiceMaterial x WHERE x.coSoID = :coSoId AND x.deleted = false AND x.status <> 'NGUNG_SU_DUNG' ORDER BY x.name",
                            org.example.model.ServiceMaterial.class)
                            .setParameter("coSoId", c.getCoSoID())
                            .getResultList();
                    for (org.example.model.ServiceMaterial mat : mats) {
                        Map<String, Object> mm = new LinkedHashMap<>();
                        mm.put("materialId", mat.getMaterialID());
                        mm.put("name", mat.getName());
                        mm.put("brand", mat.getBrand());
                        mm.put("color", mat.getColor());
                        mm.put("price", mat.getPrice());
                        mm.put("extraFee", mat.getExtraFee());
                        mm.put("status", mat.getStatus());
                        materials.add(mm);
                    }
                    m.put("materials", materials);
                }
            }
            return m;
        } finally {
            em.close();
        }
    }

    private double haversineKm(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_KM * c;
    }

    private boolean isOpenNow(LocalTime open, LocalTime close, LocalTime now) {
        if (open == null || close == null) return false;
        if (open.equals(close)) return true;
        if (open.isBefore(close)) return !now.isBefore(open) && now.isBefore(close);
        return !now.isBefore(open) || now.isBefore(close);
    }
}
