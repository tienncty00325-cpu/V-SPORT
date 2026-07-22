package org.example.dao.impl;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityTransaction;
import org.example.dao.CoSoDAO;
import org.example.dto.FacilityMapDTO;
import org.example.model.CoSo;
import org.example.model.LoaiSan;
import org.example.model.MonTheThao;
import org.example.model.San;
import org.example.util.DBUtil;
import org.example.util.JPAUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Time;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class CoSoDAOImpl implements CoSoDAO {

    private static final Logger logger = LogManager.getLogger(CoSoDAOImpl.class);

    @Override
    public List<CoSo> getAllCoSo() {
        // Loại trừ cơ sở đang "Chờ duyệt"/"Từ chối" vì đây là yêu cầu Owner
        // chưa được Admin duyệt, không phải cơ sở đang vận hành thật sự.
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                    "SELECT c FROM CoSo c WHERE (c.isDeleted = false OR c.isDeleted IS NULL) " +
                    "AND c.TrangThai NOT IN ('Chờ duyệt', 'Từ chối')", CoSo.class)
                .getResultList();
        } finally {
            em.close();
        }
    }

    @Override
    public List<CoSo> searchCoSo(String keyword, Integer monTheThaoId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            StringBuilder jpql = new StringBuilder(
                    "SELECT DISTINCT c FROM CoSo c WHERE (c.isDeleted = false OR c.isDeleted IS NULL) " +
                    "AND c.TrangThai NOT IN ('Chờ duyệt', 'Từ chối')");

            String trimmedKeyword = keyword != null ? keyword.trim() : "";
            boolean hasKeyword = !trimmedKeyword.isEmpty();
            if (hasKeyword) {
                jpql.append(" AND (LOWER(c.TenCoSo) LIKE :kw ESCAPE '\\' OR LOWER(c.DiaChi) LIKE :kw ESCAPE '\\')");
            }
            if (monTheThaoId != null) {
                jpql.append(" AND EXISTS (SELECT 1 FROM San s JOIN LoaiSan ls ON s.loaiSanID = ls.loaiSanID " +
                        "WHERE s.coSoID = c.CoSoID AND (s.isDeleted = false OR s.isDeleted IS NULL) " +
                        "AND ls.monTheThaoID = :monTheThaoId)");
            }

            jakarta.persistence.TypedQuery<CoSo> query = em.createQuery(jpql.toString(), CoSo.class);
            if (hasKeyword) {
                // Escape LIKE wildcards trong keyword người dùng nhập để tránh họ tự ý
                // dùng % / _ làm ký tự đại diện ngoài ý muốn ứng dụng.
                String escaped = trimmedKeyword.toLowerCase()
                        .replace("\\", "\\\\")
                        .replace("%", "\\%")
                        .replace("_", "\\_");
                query.setParameter("kw", "%" + escaped + "%");
            }
            if (monTheThaoId != null) {
                query.setParameter("monTheThaoId", monTheThaoId);
            }
            return query.getResultList();
        } finally {
            em.close();
        }
    }

    @Override
    public List<CoSo> getAllCoSoIncludingPending() {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery("SELECT c FROM CoSo c WHERE c.isDeleted = false OR c.isDeleted IS NULL ORDER BY c.CoSoID DESC", CoSo.class)
                .getResultList();
        } catch (Exception e) {
            logger.error("Lỗi getAllCoSoIncludingPending: {}", e.getMessage(), e);
            return java.util.Collections.emptyList();
        } finally {
            em.close();
        }
    }

    @Override
    public CoSo getCoSoById(int id) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.find(CoSo.class, id);
        } finally {
            em.close();
        }
    }

    @Override
    public boolean addCoSo(CoSo coSo) {
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction trans = em.getTransaction();
        try {
            trans.begin();
            em.persist(coSo);
            // Flush to get the generated CoSoID
            em.flush();

            // autoGenerateCourts(coSo, em);

            trans.commit();
            return true;
        } catch (Exception e) {
            if (trans.isActive())
                trans.rollback();
            logger.error("Lỗi khi thêm cơ sở mới: {}", e.getMessage(), e);
            return false;
        } finally {
            em.close();
        }
    }

    @Override
    public boolean updateCoSo(CoSo coSo) {
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction trans = em.getTransaction();
        try {
            trans.begin();
            CoSo updatedCoSo = em.merge(coSo);

            // Check if this branch has any courts. If not, auto-generate.
            // Long count = em.createQuery("SELECT COUNT(s) FROM San s WHERE s.coSoID =
            // :id", Long.class)
            // .setParameter("id", updatedCoSo.getCoSoID())
            // .getSingleResult();

            // if (count == 0) {
            // autoGenerateCourts(updatedCoSo, em);
            // }

            trans.commit();
            return true;
        } catch (Exception e) {
            if (trans.isActive())
                trans.rollback();
            logger.error("Lỗi khi cập nhật cơ sở ID {}: {}", coSo.getCoSoID(), e.getMessage(), e);
            return false;
        } finally {
            em.close();
        }
    }

    @Override
    public boolean deleteCoSo(int id) {
        return hardDeleteCascade(id);
    }

    @Override
    public boolean softDelete(int coSoId, int actorId) {
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction trans = em.getTransaction();
        try {
            trans.begin();
            int updated = em.createQuery(
                    "UPDATE CoSo c SET c.isDeleted = true, c.deletedAt = :now, c.deletedBy = :actor " +
                    "WHERE c.CoSoID = :id AND (c.isDeleted = false OR c.isDeleted IS NULL)")
                .setParameter("now", java.time.LocalDateTime.now())
                .setParameter("actor", actorId)
                .setParameter("id", coSoId)
                .executeUpdate();
            trans.commit();
            return updated > 0;
        } catch (Exception e) {
            if (trans.isActive()) trans.rollback();
            logger.error("Lỗi soft-delete cơ sở ID {}: {}", coSoId, e.getMessage(), e);
            return false;
        } finally {
            em.close();
        }
    }

    @Override
    public boolean restore(int coSoId) {
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction trans = em.getTransaction();
        try {
            trans.begin();
            int updated = em.createQuery(
                    "UPDATE CoSo c SET c.isDeleted = false, c.deletedAt = null, c.deletedBy = null " +
                    "WHERE c.CoSoID = :id")
                .setParameter("id", coSoId)
                .executeUpdate();
            trans.commit();
            return updated > 0;
        } catch (Exception e) {
            if (trans.isActive()) trans.rollback();
            logger.error("Lỗi restore cơ sở ID {}: {}", coSoId, e.getMessage(), e);
            return false;
        } finally {
            em.close();
        }
    }

    @Override
    public List<CoSo> findDeleted() {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery("SELECT c FROM CoSo c WHERE c.isDeleted = true", CoSo.class).getResultList();
        } finally {
            em.close();
        }
    }

    @Override
    public List<Integer> findDeletedIdsOlderThan(int days) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            java.time.LocalDateTime cutoff = java.time.LocalDateTime.now().minusDays(days);
            return em.createQuery(
                    "SELECT c.CoSoID FROM CoSo c WHERE c.isDeleted = true AND c.deletedAt <= :cutoff",
                    Integer.class)
                .setParameter("cutoff", cutoff)
                .getResultList();
        } finally {
            em.close();
        }
    }

    @Override
    public boolean hardDeleteCascade(int id) {
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction trans = em.getTransaction();
        try {
            trans.begin();
            // Check if branch exists first using a count native query to be safe
            Number count = (Number) em.createNativeQuery("SELECT COUNT(*) FROM CoSo WHERE CoSoID = ?")
                    .setParameter(1, id)
                    .getSingleResult();

            if (count != null && count.intValue() > 0) {
                // 0. Get the manager account ID first to delete it robustly later
                Integer managerAccountId = null;
                try {
                    Object managerIdObj = em.createNativeQuery("SELECT AccountID_QuanLy FROM CoSo WHERE CoSoID = ?")
                            .setParameter(1, id)
                            .getSingleResult();
                    if (managerIdObj != null) {
                        managerAccountId = ((Number) managerIdObj).intValue();
                    }
                } catch (Exception ex) {
                    // Ignore if no manager found or multiple/none
                }

                // 1. Break circular dependency first
                em.createNativeQuery("UPDATE CoSo SET AccountID_QuanLy = NULL WHERE CoSoID = ?")
                        .setParameter(1, id)
                        .executeUpdate();

                // 2. Clean up bookings referencing courts of this branch
                em.createNativeQuery("DELETE FROM LichDatSan WHERE SanID IN (SELECT SanID FROM San WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .executeUpdate();

                // 3. SOS requests
                em.createNativeQuery("DELETE FROM NhatKySOSGui WHERE YeuCauSOSID IN (SELECT YeuCauSOSID FROM YeuCauSOS WHERE DatSanID IN (SELECT DatSanID FROM LichDatSan WHERE SanID IN (SELECT SanID FROM San WHERE CoSoID = ?)))")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM YeuCauSOS WHERE DatSanID IN (SELECT DatSanID FROM LichDatSan WHERE SanID IN (SELECT SanID FROM San WHERE CoSoID = ?))")
                        .setParameter(1, id)
                        .executeUpdate();

                // 4. Matchmaking
                em.createNativeQuery("DELETE FROM ChiTietGhepKeo WHERE KeoID IN (SELECT KeoID FROM GhepKeo WHERE DatSanID IN (SELECT DatSanID FROM LichDatSan WHERE SanID IN (SELECT SanID FROM San WHERE CoSoID = ?)))")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM GhepKeo WHERE DatSanID IN (SELECT DatSanID FROM LichDatSan WHERE SanID IN (SELECT SanID FROM San WHERE CoSoID = ?))")
                        .setParameter(1, id)
                        .executeUpdate();

                // 5. Reviews
                em.createNativeQuery("DELETE FROM DanhGia WHERE DatSanID IN (SELECT DatSanID FROM LichDatSan WHERE SanID IN (SELECT SanID FROM San WHERE CoSoID = ?))")
                        .setParameter(1, id)
                        .executeUpdate();

                // 6. ELO
                em.createNativeQuery("DELETE FROM LichSuELO WHERE DatSanID IN (SELECT DatSanID FROM LichDatSan WHERE SanID IN (SELECT SanID FROM San WHERE CoSoID = ?))")
                        .setParameter(1, id)
                        .executeUpdate();

                // 7. Parking card logs for bookings
                em.createNativeQuery("DELETE FROM LichXeRaVao WHERE DatSanID IN (SELECT DatSanID FROM LichDatSan WHERE SanID IN (SELECT SanID FROM San WHERE CoSoID = ?))")
                        .setParameter(1, id)
                        .executeUpdate();

                // 8. Invoices
                em.createNativeQuery("DELETE FROM ChiTietHoaDon WHERE HoaDonID IN (SELECT HoaDonID FROM HoaDon WHERE DatSanID IN (SELECT DatSanID FROM LichDatSan WHERE SanID IN (SELECT SanID FROM San WHERE CoSoID = ?)))")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM HoanTien WHERE HoaDonID IN (SELECT HoaDonID FROM HoaDon WHERE DatSanID IN (SELECT DatSanID FROM LichDatSan WHERE SanID IN (SELECT SanID FROM San WHERE CoSoID = ?)))")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM HoaDon WHERE DatSanID IN (SELECT DatSanID FROM LichDatSan WHERE SanID IN (SELECT SanID FROM San WHERE CoSoID = ?))")
                        .setParameter(1, id)
                        .executeUpdate();

                // 9. Courts
                em.createNativeQuery("DELETE FROM San WHERE CoSoID = ?")
                        .setParameter(1, id)
                        .executeUpdate();

                // 10. Court Types
                em.createNativeQuery("DELETE FROM LoaiSan WHERE CoSoID = ?")
                        .setParameter(1, id)
                        .executeUpdate();

                // 11. Products and Services
                em.createNativeQuery("DELETE FROM ChiTietHoaDon WHERE SanPhamID IN (SELECT SanPhamID FROM SanPham_DichVu WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM SanPham_DichVu WHERE CoSoID = ?")
                        .setParameter(1, id)
                        .executeUpdate();

                // 12. Parking Cards
                em.createNativeQuery("DELETE FROM LichXeRaVao WHERE TheID IN (SELECT TheID FROM TheGiuXe WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM TheGiuXe WHERE CoSoID = ?")
                        .setParameter(1, id)
                        .executeUpdate();

                // 13. Promo Codes
                em.createNativeQuery("DELETE FROM KhuyenMai WHERE CoSoID = ?")
                        .setParameter(1, id)
                        .executeUpdate();

                // 14. Accounts references cleanup
                em.createNativeQuery("UPDATE CoSo SET AccountID_QuanLy = NULL WHERE AccountID_QuanLy IN (SELECT AccountID FROM Accounts WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM CaLamViec WHERE CoSoID = ? OR AccountID IN (SELECT AccountID FROM Accounts WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .setParameter(2, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM MonTheThaoYeuThich WHERE AccountID IN (SELECT AccountID FROM Accounts WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM NhatKyChat WHERE AccountID IN (SELECT AccountID FROM Accounts WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM ThongBao WHERE AccountID IN (SELECT AccountID FROM Accounts WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM LichXeRaVao WHERE AccountID_NhanVien IN (SELECT AccountID FROM Accounts WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("UPDATE HoaDon SET AccountID_NhanVien = NULL WHERE AccountID_NhanVien IN (SELECT AccountID FROM Accounts WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("UPDATE HoaDon SET AccountID_KhachHang = NULL WHERE AccountID_KhachHang IN (SELECT AccountID FROM Accounts WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM LichSuELO WHERE AccountID IN (SELECT AccountID FROM Accounts WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM HoanTien WHERE AccountID IN (SELECT AccountID FROM Accounts WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM DanhGia WHERE AccountID_NguoiDanhGia IN (SELECT AccountID FROM Accounts WHERE CoSoID = ?) OR AccountID_NguoiBiDanhGia IN (SELECT AccountID FROM Accounts WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .setParameter(2, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM NhatKySOSGui WHERE AccountID_NhanGui IN (SELECT AccountID FROM Accounts WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .executeUpdate();
                em.createNativeQuery("DELETE FROM YeuCauSOS WHERE AccountID_Tao IN (SELECT AccountID FROM Accounts WHERE CoSoID = ?)")
                        .setParameter(1, id)
                        .executeUpdate();

                // 15. Delete Accounts associated with the branch
                em.createNativeQuery("DELETE FROM Accounts WHERE CoSoID = ?")
                        .setParameter(1, id)
                        .executeUpdate();
                if (managerAccountId != null) {
                    em.createNativeQuery("DELETE FROM Accounts WHERE AccountID = ?")
                            .setParameter(1, managerAccountId)
                            .executeUpdate();
                }

                // 16. Finally delete the branch itself
                em.createNativeQuery("DELETE FROM CoSo WHERE CoSoID = ?")
                        .setParameter(1, id)
                        .executeUpdate();

                trans.commit();
                return true;
            }
            return false;
        } catch (Exception e) {
            if (trans.isActive())
                trans.rollback();
            logger.error("Lỗi khi xóa cơ sở ID {}: {}", id, e.getMessage(), e);
            return false;
        } finally {
            em.close();
        }
    }

    @Override
    public boolean archiveRejectedForAccount(int accountId, int excludeCoSoId, int actorId) {
        EntityManager em = JPAUtil.getEntityManager();
        EntityTransaction trans = em.getTransaction();
        try {
            trans.begin();
            em.createQuery(
                    "UPDATE CoSo c SET c.isDeleted = true, c.deletedAt = :now, c.deletedBy = :actor " +
                    "WHERE c.AccountID_QuanLy = :accId AND c.TrangThai = 'Từ chối' AND c.CoSoID <> :excludeId " +
                    "AND (c.isDeleted = false OR c.isDeleted IS NULL)")
                .setParameter("now", java.time.LocalDateTime.now())
                .setParameter("actor", actorId)
                .setParameter("accId", accountId)
                .setParameter("excludeId", excludeCoSoId)
                .executeUpdate();
            trans.commit();
            return true;
        } catch (Exception e) {
            if (trans.isActive()) trans.rollback();
            logger.error("Lỗi archive rejected CoSo for accountId={}: {}", accountId, e.getMessage(), e);
            return false;
        } finally {
            em.close();
        }
    }

    @Override
    public boolean hasActiveOrPendingCoSo(int accountId, int excludeCoSoId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            Long count = em.createQuery(
                    "SELECT COUNT(c) FROM CoSo c WHERE c.AccountID_QuanLy = :accId AND c.CoSoID <> :excludeId " +
                    "AND (c.isDeleted = false OR c.isDeleted IS NULL) " +
                    "AND c.TrangThai IN ('Chờ duyệt', 'Đang hoạt động')", Long.class)
                .setParameter("accId", accountId)
                .setParameter("excludeId", excludeCoSoId)
                .getSingleResult();
            return count != null && count > 0;
        } finally {
            em.close();
        }
    }

    @Override
    public List<FacilityMapDTO> getAllCoSoForMap(Integer sportId, String keyword, Integer facilityId) {
        List<FacilityMapDTO> result = new ArrayList<>();

        StringBuilder sql = new StringBuilder(
                "SELECT c.CoSoID, c.TenCoSo, c.DiaChi, c.SoDienThoai, c.ViDo, c.KinhDo, c.HinhAnh, " +
                "       c.GioMoCua, c.GioDongCua, c.TrangThai, c.LoaiHinhKinhDoanh, " +
                "       (SELECT MIN(ls.GiaKhongDen) FROM LoaiSan ls WHERE ls.CoSoID = c.CoSoID) AS MinPrice, " +
                "       (SELECT COUNT(*) FROM San s WHERE s.CoSoID = c.CoSoID AND s.TrangThai = N'Sẵn sàng' " +
                "               AND (s.IsDeleted = 0 OR s.IsDeleted IS NULL)) AS ReadyCourtCount " +
                "FROM CoSo c " +
                "WHERE (c.IsDeleted = 0 OR c.IsDeleted IS NULL) " +
                "  AND c.TrangThai = N'Đang hoạt động' " +
                "  AND c.ViDo IS NOT NULL AND c.KinhDo IS NOT NULL " +
                "  AND c.ViDo BETWEEN -90 AND 90 AND c.KinhDo BETWEEN -180 AND 180");

        if (facilityId != null) {
            sql.append(" AND c.CoSoID = ?");
        }
        if (sportId != null) {
            sql.append(" AND c.CoSoID IN (SELECT DISTINCT ls.CoSoID FROM LoaiSan ls WHERE ls.MonTheThaoID = ?)");
        }
        boolean hasKeyword = keyword != null && !keyword.trim().isEmpty();
        if (hasKeyword) {
            sql.append(" AND (LOWER(c.TenCoSo) LIKE ? ESCAPE '\\' OR LOWER(c.DiaChi) LIKE ? ESCAPE '\\')");
        }

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {

            int idx = 1;
            if (facilityId != null) {
                ps.setInt(idx++, facilityId);
            }
            if (sportId != null) {
                ps.setInt(idx++, sportId);
            }
            if (hasKeyword) {
                String escaped = keyword.trim().toLowerCase()
                        .replace("\\", "\\\\")
                        .replace("%", "\\%")
                        .replace("_", "\\_");
                String pattern = "%" + escaped + "%";
                ps.setString(idx++, pattern);
                ps.setString(idx++, pattern);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    FacilityMapDTO dto = new FacilityMapDTO();
                    dto.setCoSoId(rs.getInt("CoSoID"));
                    dto.setTenCoSo(rs.getString("TenCoSo"));
                    dto.setDiaChi(rs.getString("DiaChi"));
                    dto.setSoDienThoai(rs.getString("SoDienThoai"));

                    BigDecimal viDo = rs.getBigDecimal("ViDo");
                    BigDecimal kinhDo = rs.getBigDecimal("KinhDo");
                    dto.setViDo(viDo.doubleValue());
                    dto.setKinhDo(kinhDo.doubleValue());

                    Time gioMo = rs.getTime("GioMoCua");
                    Time gioDong = rs.getTime("GioDongCua");
                    dto.setGioMoCua(gioMo != null ? gioMo.toString().substring(0, 5) : null);
                    dto.setGioDongCua(gioDong != null ? gioDong.toString().substring(0, 5) : null);

                    dto.setTrangThai(rs.getString("TrangThai"));
                    String hinhAnh = rs.getString("HinhAnh");
                    dto.setHinhAnh(hinhAnh != null ? hinhAnh.trim() : "");

                    double minPrice = rs.getDouble("MinPrice");
                    dto.setMinPrice(rs.wasNull() ? 0.0 : minPrice);
                    dto.setReadyCourtCount(rs.getInt("ReadyCourtCount"));

                    List<String> sportsList = new ArrayList<>();
                    String loaiHinh = rs.getString("LoaiHinhKinhDoanh");
                    if (loaiHinh != null && !loaiHinh.trim().isEmpty()) {
                        for (String s : loaiHinh.split(",")) {
                            if (!s.trim().isEmpty()) {
                                sportsList.add(s.trim());
                            }
                        }
                    }
                    dto.setSports(sportsList);

                    result.add(dto);
                }
            }
        } catch (Exception e) {
            logger.error("Lỗi khi tải danh sách cơ sở cho bản đồ: {}", e.getMessage(), e);
        }

        return result;
    }

    private void autoGenerateCourts(CoSo coSo, EntityManager em) {
        String loaiHinh = coSo.getLoaiHinhKinhDoanh();
        if (loaiHinh == null || loaiHinh.isEmpty())
            return;

        int totalCourts = coSo.getSoLuongSanDuKien();
        if (totalCourts <= 0)
            return;

        String[] sports = loaiHinh.split(", ");
        if (sports.length == 0)
            return;

        int courtsPerSport = totalCourts / sports.length;
        int remainder = totalCourts % sports.length;

        for (int i = 0; i < sports.length; i++) {
            String sportName = sports[i].trim();
            Integer loaiSanId = findLoaiSanIdBySportName(sportName, em);
            if (loaiSanId == null)
                continue;

            int countForThisSport = courtsPerSport + (i < remainder ? 1 : 0);
            for (int j = 1; j <= countForThisSport; j++) {
                San san = new San();
                san.setCoSoID(coSo.getCoSoID());
                san.setLoaiSanID(loaiSanId);
                san.setTenSan(sportName + " " + (j < 10 ? "0" + j : j));
                san.setTrangThai("Sẵn sàng");
                san.setMoTa("Sân tự động tạo từ cấu hình Cơ Sở " + coSo.getTenCoSo());
                em.persist(san);
            }
        }
    }

    private Integer findLoaiSanIdBySportName(String sportName, EntityManager em) {
        try {
            // Find MonTheThao first using TenMon field
            List<MonTheThao> mList = em
                    .createQuery("SELECT m FROM MonTheThao m WHERE m.TenMon = :name", MonTheThao.class)
                    .setParameter("name", sportName)
                    .getResultList();
            if (mList.isEmpty())
                return null;
            int monId = mList.get(0).getMonTheThaoID();

            // Then find first LoaiSan for this monId
            List<LoaiSan> lList = em.createQuery("SELECT l FROM LoaiSan l WHERE l.monTheThaoID = :monId", LoaiSan.class)
                    .setParameter("monId", monId)
                    .getResultList();
            if (lList.isEmpty())
                return null;
            return lList.get(0).getLoaiSanID();
        } catch (Exception e) {
            return null;
        }
    }
}
