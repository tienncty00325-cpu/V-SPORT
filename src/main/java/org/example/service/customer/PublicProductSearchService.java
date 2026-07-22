package org.example.service.customer;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import org.example.model.CoSo;
import org.example.model.SanPham_DichVu;
import org.example.util.Constants;
import org.example.util.JPAUtil;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Tìm kiếm sản phẩm thể thao công khai cho Customer (PHẦN 12/16). Cùng nguyên
 * tắc lọc như PublicServiceSearchService: chỉ trả sản phẩm của cơ sở đang hoạt
 * động, có capability SAN_PHAM đã APPROVED, và bản thân sản phẩm chưa bị xóa
 * mềm - không bao giờ để lộ sản phẩm cơ sở bị khóa/capability suspend/disabled.
 */
public class PublicProductSearchService {

    public static class SearchFilter {
        public String q;
        public Integer categoryId;
        public Integer coSoId;
        public Double lat;
        public Double lng;
        public Double radiusKm;
    }

    private static final double EARTH_RADIUS_KM = 6371.0;

    public List<Map<String, Object>> search(SearchFilter f) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            StringBuilder jpql = new StringBuilder(
                    "SELECT p, d.TenDanhMuc, c FROM SanPham_DichVu p, DanhMucSanPham d, CoSo c " +
                    "WHERE p.DanhMucID = d.DanhMucID AND p.CoSoID = c.CoSoID " +
                    "AND p.isDeleted = false AND p.TrangThai <> :ngungKinhDoanh " +
                    "AND c.TrangThai = :active AND (c.isDeleted = false OR c.isDeleted IS NULL) " +
                    "AND EXISTS (SELECT 1 FROM CoSoCapability cc WHERE cc.coSoId = c.CoSoID " +
                    "    AND cc.capabilityType = :capType AND cc.trangThai = :capApproved) ");

            if (f.q != null && !f.q.trim().isEmpty()) {
                jpql.append("AND (LOWER(p.TenSanPham) LIKE :q OR LOWER(p.MoTa) LIKE :q) ");
            }
            if (f.categoryId != null) {
                jpql.append("AND d.DanhMucID = :categoryId ");
            }
            if (f.coSoId != null) {
                jpql.append("AND c.CoSoID = :coSoId ");
            }
            jpql.append("ORDER BY p.TenSanPham ASC");

            Query query = em.createQuery(jpql.toString());
            query.setParameter("ngungKinhDoanh", Constants.TRANG_THAI_SP_NGUNG_KINH_DOANH);
            query.setParameter("active", "Đang hoạt động");
            query.setParameter("capType", Constants.CAPABILITY_SAN_PHAM);
            query.setParameter("capApproved", Constants.CAPABILITY_STATUS_APPROVED);
            if (f.q != null && !f.q.trim().isEmpty()) {
                query.setParameter("q", "%" + f.q.trim().toLowerCase() + "%");
            }
            if (f.categoryId != null) {
                query.setParameter("categoryId", f.categoryId);
            }
            if (f.coSoId != null) {
                query.setParameter("coSoId", f.coSoId);
            }
            query.setMaxResults(200);

            @SuppressWarnings("unchecked")
            List<Object[]> rows = query.getResultList();

            List<Map<String, Object>> results = new ArrayList<>();
            for (Object[] row : rows) {
                SanPham_DichVu p = (SanPham_DichVu) row[0];
                String categoryName = (String) row[1];
                CoSo c = (CoSo) row[2];

                Double distanceKm = null;
                if (f.lat != null && f.lng != null && c.getViDo() != null && c.getKinhDo() != null) {
                    distanceKm = haversineKm(f.lat, f.lng, c.getViDo().doubleValue(), c.getKinhDo().doubleValue());
                    if (f.radiusKm != null && distanceKm > f.radiusKm) {
                        continue;
                    }
                }

                Map<String, Object> m = new LinkedHashMap<>();
                m.put("productId", p.getSanPhamID());
                m.put("name", p.getTenSanPham());
                m.put("category", categoryName);
                m.put("categoryId", p.getDanhMucID());
                m.put("price", p.getDonGia());
                m.put("unit", p.getDonViTinh());
                m.put("description", p.getMoTa());
                m.put("image", p.getHinhAnh());
                m.put("stockStatus", stockStatus(p.getSoLuongTon()));
                m.put("coSoId", c.getCoSoID());
                m.put("coSoName", c.getTenCoSo());
                m.put("coSoAddress", c.getDiaChi());
                if (distanceKm != null) m.put("distanceKm", Math.round(distanceKm * 10) / 10.0);
                results.add(m);
            }
            return results;
        } finally {
            em.close();
        }
    }

    /** Chi tiết sản phẩm cho Customer - trả null nếu không public/không tồn tại (không lộ khác biệt lý do). */
    public Map<String, Object> detail(int productId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            SanPham_DichVu p = em.find(SanPham_DichVu.class, productId);
            if (p == null || p.isDeleted()
                    || Constants.TRANG_THAI_SP_NGUNG_KINH_DOANH.equals(p.getTrangThai())) {
                return null;
            }

            CoSo c = em.find(CoSo.class, p.getCoSoID());
            if (c == null || !"Đang hoạt động".equals(c.getTrangThai()) || c.isDeleted()) {
                return null;
            }

            long approvedCount = em.createQuery(
                    "SELECT COUNT(cc) FROM CoSoCapability cc WHERE cc.coSoId = :coSoId " +
                    "AND cc.capabilityType = :capType AND cc.trangThai = :approved", Long.class)
                    .setParameter("coSoId", c.getCoSoID())
                    .setParameter("capType", Constants.CAPABILITY_SAN_PHAM)
                    .setParameter("approved", Constants.CAPABILITY_STATUS_APPROVED)
                    .getSingleResult();
            if (approvedCount == 0) return null;

            org.example.model.DanhMucSanPham category = em.find(org.example.model.DanhMucSanPham.class, p.getDanhMucID());

            Map<String, Object> m = new LinkedHashMap<>();
            m.put("productId", p.getSanPhamID());
            m.put("name", p.getTenSanPham());
            m.put("category", category != null ? category.getTenDanhMuc() : null);
            m.put("price", p.getDonGia());
            m.put("unit", p.getDonViTinh());
            m.put("description", p.getMoTa());
            m.put("image", p.getHinhAnh());
            m.put("stockStatus", stockStatus(p.getSoLuongTon()));
            m.put("coSoId", c.getCoSoID());
            m.put("coSoName", c.getTenCoSo());
            m.put("coSoAddress", c.getDiaChi());
            m.put("coSoPhone", c.getSoDienThoai());
            m.put("gioMoCua", c.getGioMoCua() != null ? c.getGioMoCua().toString() : null);
            m.put("gioDongCua", c.getGioDongCua() != null ? c.getGioDongCua().toString() : null);
            return m;
        } finally {
            em.close();
        }
    }

    // Không lộ số lượng tồn kho chính xác cho Customer - chỉ 3 trạng thái tổng quát.
    private static String stockStatus(int soLuongTon) {
        if (soLuongTon <= 0) return "HET_HANG";
        if (soLuongTon <= 5) return "SAP_HET";
        return "CON_HANG";
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
}
