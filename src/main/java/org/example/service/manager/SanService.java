package org.example.service.manager;

import org.example.dao.LoaiSanDAO;
import org.example.dao.SanDAO;
import org.example.dao.impl.LoaiSanDAOImpl;
import org.example.dao.impl.SanDAOImpl;
import org.example.model.LoaiSan;
import org.example.model.MonTheThao;
import org.example.model.San;
import org.example.util.BranchSecurityUtils;
import org.example.util.Constants;
import org.example.util.ValidationUtils;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import org.example.util.DBUtil;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.math.BigDecimal;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;

/**
 * Tên tiếng Việt: Dịch vụ quản lý sân và loại sân.
 *
 * Nhiệm vụ:
 * - Quản lý sân (Thêm mới, Cập nhật thông tin, Xóa).
 * - Quản lý trạng thái hoạt động của sân (Khóa sân, Bảo trì, Khôi phục).
 * - Quản lý cấu hình loại sân, khung giá và giờ lên đèn.
 * - Kiểm tra lịch đặt sân đang hoạt động trước khi đổi trạng thái sân (tránh ảnh hưởng khách hàng).
 *
 * Được gọi bởi:
 * - QuanLySanManagerServlet.java
 *
 * Lưu ý:
 * - Hiện tại lớp này còn sử dụng câu lệnh SQL trực tiếp và tự quản lý JDBC connection.
 * - TODO(sau-đánh-giá): Tách các đoạn check SQL này xuống DAO để Service chỉ xử lý nghiệp vụ.
 */
public class SanService {

    private static final Logger logger = LogManager.getLogger(SanService.class);

    private final SanDAO sanDAO;
    private final LoaiSanDAO loaiSanDAO;

    public SanService() {
        this.sanDAO = new SanDAOImpl();
        this.loaiSanDAO = new LoaiSanDAOImpl();
    }

    public SanService(SanDAO sanDAO, LoaiSanDAO loaiSanDAO) {
        this.sanDAO = sanDAO;
        this.loaiSanDAO = loaiSanDAO;
    }

    // ==================== DTOs ====================

    /**
     * DTO cho San (Court)
     */
    public static class SanDTO {
        private int sanId;
        private String tenSan;
        private int loaiSanId;
        private String tenLoaiSan;
        private int monTheThaoId;
        private String tenMonTheThao;
        private int coSoId;
        private String trangThai;
        private String moTa;
        private String hinhAnh;
        private BigDecimal giaKhongDen;
        private BigDecimal giaCoDen;
        private LocalTime gioBatDauLenDen;
        private LocalTime gioKetThucLenDen;

        // Các hàm getter và setter
        public int getSanId() { return sanId; }
        public void setSanId(int sanId) { this.sanId = sanId; }
        public String getTenSan() { return tenSan; }
        public void setTenSan(String tenSan) { this.tenSan = tenSan; }
        public int getLoaiSanId() { return loaiSanId; }
        public void setLoaiSanId(int loaiSanId) { this.loaiSanId = loaiSanId; }
        public String getTenLoaiSan() { return tenLoaiSan; }
        public void setTenLoaiSan(String tenLoaiSan) { this.tenLoaiSan = tenLoaiSan; }
        public int getMonTheThaoId() { return monTheThaoId; }
        public void setMonTheThaoId(int monTheThaoId) { this.monTheThaoId = monTheThaoId; }
        public String getTenMonTheThao() { return tenMonTheThao; }
        public void setTenMonTheThao(String tenMonTheThao) { this.tenMonTheThao = tenMonTheThao; }
        public int getCoSoId() { return coSoId; }
        public void setCoSoId(int coSoId) { this.coSoId = coSoId; }
        public String getTrangThai() { return trangThai; }
        public void setTrangThai(String trangThai) { this.trangThai = trangThai; }
        public String getMoTa() { return moTa; }
        public void setMoTa(String moTa) { this.moTa = moTa; }
        public String getHinhAnh() { return hinhAnh; }
        public void setHinhAnh(String hinhAnh) { this.hinhAnh = hinhAnh; }
        public BigDecimal getGiaKhongDen() { return giaKhongDen; }
        public void setGiaKhongDen(BigDecimal giaKhongDen) { this.giaKhongDen = giaKhongDen; }
        public BigDecimal getGiaCoDen() { return giaCoDen; }
        public void setGiaCoDen(BigDecimal giaCoDen) { this.giaCoDen = giaCoDen; }
        public LocalTime getGioBatDauLenDen() { return gioBatDauLenDen; }
        public void setGioBatDauLenDen(LocalTime gioBatDauLenDen) { this.gioBatDauLenDen = gioBatDauLenDen; }
        public LocalTime getGioKetThucLenDen() { return gioKetThucLenDen; }
        public void setGioKetThucLenDen(LocalTime gioKetThucLenDen) { this.gioKetThucLenDen = gioKetThucLenDen; }
    }

    /**
     * DTO cho Loại sân (Court Type)
     */
    public static class LoaiSanDTO {
        private int loaiSanId;
        private int monTheThaoId;
        private String tenMonTheThao;
        private String tenLoai;
        private BigDecimal giaKhongDen;
        private BigDecimal giaCoDen;
        private LocalTime gioBatDauLenDen;
        private LocalTime gioKetThucLenDen;
        private int coSoId;

        // Các hàm getter và setter
        public int getLoaiSanId() { return loaiSanId; }
        public void setLoaiSanId(int loaiSanId) { this.loaiSanId = loaiSanId; }
        public int getMonTheThaoId() { return monTheThaoId; }
        public void setMonTheThaoId(int monTheThaoId) { this.monTheThaoId = monTheThaoId; }
        public String getTenMonTheThao() { return tenMonTheThao; }
        public void setTenMonTheThao(String tenMonTheThao) { this.tenMonTheThao = tenMonTheThao; }
        public String getTenLoai() { return tenLoai; }
        public void setTenLoai(String tenLoai) { this.tenLoai = tenLoai; }
        public BigDecimal getGiaKhongDen() { return giaKhongDen; }
        public void setGiaKhongDen(BigDecimal giaKhongDen) { this.giaKhongDen = giaKhongDen; }
        public BigDecimal getGiaCoDen() { return giaCoDen; }
        public void setGiaCoDen(BigDecimal giaCoDen) { this.giaCoDen = giaCoDen; }
        public LocalTime getGioBatDauLenDen() { return gioBatDauLenDen; }
        public void setGioBatDauLenDen(LocalTime gioBatDauLenDen) { this.gioBatDauLenDen = gioBatDauLenDen; }
        public LocalTime getGioKetThucLenDen() { return gioKetThucLenDen; }
        public void setGioKetThucLenDen(LocalTime gioKetThucLenDen) { this.gioKetThucLenDen = gioKetThucLenDen; }
        public int getCoSoId() { return coSoId; }
        public void setCoSoId(int coSoId) { this.coSoId = coSoId; }
    }

    /**
     * Request để tạo sân mới
     */
    public static class SanCreateRequest {
        private String tenSan;
        private int loaiSanId;
        private String trangThai;
        private String moTa;
        private String hinhAnh;

        // Các hàm getter và setter
        public String getTenSan() { return tenSan; }
        public void setTenSan(String tenSan) { this.tenSan = tenSan; }
        public int getLoaiSanId() { return loaiSanId; }
        public void setLoaiSanId(int loaiSanId) { this.loaiSanId = loaiSanId; }
        public String getTrangThai() { return trangThai; }
        public void setTrangThai(String trangThai) { this.trangThai = trangThai; }
        public String getMoTa() { return moTa; }
        public void setMoTa(String moTa) { this.moTa = moTa; }
        public String getHinhAnh() { return hinhAnh; }
        public void setHinhAnh(String hinhAnh) { this.hinhAnh = hinhAnh; }
    }

    /**
     * Request để cập nhật sân
     */
    public static class SanUpdateRequest {
        private String tenSan;
        private int loaiSanId;
        private String trangThai;
        private String moTa;
        private String hinhAnh;

        // Các hàm getter và setter
        public String getTenSan() { return tenSan; }
        public void setTenSan(String tenSan) { this.tenSan = tenSan; }
        public int getLoaiSanId() { return loaiSanId; }
        public void setLoaiSanId(int loaiSanId) { this.loaiSanId = loaiSanId; }
        public String getTrangThai() { return trangThai; }
        public void setTrangThai(String trangThai) { this.trangThai = trangThai; }
        public String getMoTa() { return moTa; }
        public void setMoTa(String moTa) { this.moTa = moTa; }
        public String getHinhAnh() { return hinhAnh; }
        public void setHinhAnh(String hinhAnh) { this.hinhAnh = hinhAnh; }
    }

    /**
     * Request để tạo/cập nhật loại sân
     */
    public static class LoaiSanRequest {
        private String tenLoai;
        private int monTheThaoId;
        private BigDecimal giaKhongDen;
        private BigDecimal giaCoDen;
        private LocalTime gioBatDauLenDen;
        private LocalTime gioKetThucLenDen;
        /** true = sân không dùng đèn: giaCoDen, gioBatDau, gioKetThuc đều null */
        private boolean khongDungDen;

        // Các hàm getter và setter
        public String getTenLoai() { return tenLoai; }
        public void setTenLoai(String tenLoai) { this.tenLoai = tenLoai; }
        public int getMonTheThaoId() { return monTheThaoId; }
        public void setMonTheThaoId(int monTheThaoId) { this.monTheThaoId = monTheThaoId; }
        public BigDecimal getGiaKhongDen() { return giaKhongDen; }
        public void setGiaKhongDen(BigDecimal giaKhongDen) { this.giaKhongDen = giaKhongDen; }
        public BigDecimal getGiaCoDen() { return giaCoDen; }
        public void setGiaCoDen(BigDecimal giaCoDen) { this.giaCoDen = giaCoDen; }
        public LocalTime getGioBatDauLenDen() { return gioBatDauLenDen; }
        public void setGioBatDauLenDen(LocalTime gioBatDauLenDen) { this.gioBatDauLenDen = gioBatDauLenDen; }
        public LocalTime getGioKetThucLenDen() { return gioKetThucLenDen; }
        public void setGioKetThucLenDen(LocalTime gioKetThucLenDen) { this.gioKetThucLenDen = gioKetThucLenDen; }
        public boolean isKhongDungDen() { return khongDungDen; }
        public void setKhongDungDen(boolean khongDungDen) { this.khongDungDen = khongDungDen; }
    }

    // ==================== READ OPERATIONS ====================

    /**
     * Lấy danh sách sân của cơ sở
     */
    public List<San> getSansByCoSo(int coSoId) {
        return sanDAO.getSansByCoSo(coSoId);
    }

    /**
     * Lấy sân theo ID với validation branch access
     */
    public San getSanById(int sanId, int managerCoSoId) {
        San san = sanDAO.getSanById(sanId);
        BranchSecurityUtils.getEntityOrThrow(san, "Sân");

        BranchSecurityUtils.checkBranchAccess(san.getCoSoID(), managerCoSoId);

        return san;
    }

    /**
     * Lấy danh sách loại sân của cơ sở
     */
    public List<LoaiSan> getLoaiSansByCoSo(int coSoId) {
        return loaiSanDAO.getLoaiSansByCoSo(coSoId);
    }

    /**
     * Lấy tất cả môn thể thao
     */
    public List<MonTheThao> getAllMonTheThao() {
        return loaiSanDAO.getAllMonTheThao();
    }

    /**
     * Lấy danh sách môn thể thao mà cơ sở này đã đăng ký lúc tạo/đăng ký
     * (CoSo.LoaiHinhKinhDoanh — chuỗi tên môn phân tách bởi ", "), thay vì
     * toàn bộ danh mục MonTheThao của hệ thống. Dùng cho dropdown "Thêm loại
     * sân" ở Quản lý Sân — chỉ cho chọn đúng những môn Owner đã đăng ký,
     * tránh liệt kê thừa và không phù hợp với những gì cơ sở thực sự kinh doanh.
     * Nếu cơ sở không có LoaiHinhKinhDoanh hợp lệ (dữ liệu cũ/thiếu), fallback
     * về toàn bộ danh mục để không chặn thao tác của Manager.
     */
    public List<MonTheThao> getRegisteredMonTheThao(int coSoId) {
        List<MonTheThao> all = loaiSanDAO.getAllMonTheThao();
        org.example.model.CoSo coSo = new org.example.dao.impl.CoSoDAOImpl().getCoSoById(coSoId);
        if (coSo == null || coSo.getLoaiHinhKinhDoanh() == null || coSo.getLoaiHinhKinhDoanh().isBlank()) {
            return all;
        }
        java.util.Set<String> registered = new java.util.HashSet<>();
        for (String s : coSo.getLoaiHinhKinhDoanh().split(",")) {
            String trimmed = s.trim();
            if (!trimmed.isEmpty()) registered.add(trimmed);
        }
        if (registered.isEmpty()) {
            return all;
        }
        List<MonTheThao> filtered = all.stream()
                .filter(m -> registered.contains(m.getTenMon()))
                .collect(java.util.stream.Collectors.toList());
        return filtered.isEmpty() ? all : filtered;
    }

    /**
     * Lấy loại sân theo ID với validation branch access
     */
    public LoaiSan getLoaiSanById(int loaiSanId, int managerCoSoId) {
        LoaiSan ls = loaiSanDAO.getLoaiSanById(loaiSanId);
        BranchSecurityUtils.getEntityOrThrow(ls, "Loại sân");

        BranchSecurityUtils.validateBranchAccess(ls.getCoSoID(), managerCoSoId, "Loại sân");

        return ls;
    }

    /**
     * Lấy loại sân theo ID mà không validation branch access (cho audit log)
     */
    public LoaiSan getLoaiSanById(int loaiSanId) {
        return loaiSanDAO.getLoaiSanById(loaiSanId);
    }

    // ==================== SAN OPERATIONS ====================

    /**
     * Nghĩa tiếng Việt: Tạo sân thi đấu mới (createSan).
     *
     * Mục đích:
     * - Khởi tạo một sân thi đấu mới trực thuộc cơ sở quản lý. Thực hiện kiểm tra trùng tên sân trước khi lưu vào database.
     *
     * Input:
     * - request: Thông tin sân cần tạo (SanCreateRequest)
     * - managerCoSoId: ID cơ sở của quản lý
     *
     * Output:
     * - San: Đối tượng sân thi đấu đã được lưu thành công
     *
     * Rủi ro:
     * - Thấp. Ném IllegalArgumentException nếu dữ liệu trống, không hợp lệ hoặc trùng tên sân trong cùng một chi nhánh.
     */
    public San createSan(SanCreateRequest request, int managerCoSoId) {
        validateSanRequest(request);

        // Kiểm tra trùng tên sân trong cùng cơ sở
        jakarta.persistence.EntityManager em = org.example.util.JPAUtil.getEntityManager();
        try {
            Long count = em.createQuery("SELECT COUNT(s) FROM San s WHERE LOWER(TRIM(s.tenSan)) = :tenSan AND s.coSoID = :coSoId AND s.isDeleted = false", Long.class)
                    .setParameter("tenSan", request.getTenSan().trim().toLowerCase())
                    .setParameter("coSoId", managerCoSoId)
                    .getSingleResult();
            if (count > 0) {
                throw new IllegalArgumentException("Tên sân đã tồn tại trong cơ sở này.");
            }
        } finally {
            em.close();
        }

        San san = new San();
        updateSanFromRequest(san, request);
        san.setCoSoID(managerCoSoId);

        sanDAO.insert(san);
        return san;
    }

    /**
     * Nghĩa tiếng Việt: Cập nhật thông tin sân thi đấu (updateSan).
     *
     * Mục đích:
     * - Cập nhật tên, mô tả, hình ảnh và loại sân của một sân hiện có. 
     *   Kiểm tra phân quyền quản lý chi nhánh và trùng lặp tên sân sau khi sửa.
     *
     * Input:
     * - sanId: ID sân cần cập nhật
     * - request: Thông tin cập nhật (SanUpdateRequest)
     * - managerCoSoId: ID cơ sở của quản lý
     *
     * Output:
     * - Không có (void)
     *
     * Rủi ro:
     * - Thấp. Ném ngoại lệ if-else nếu tên sân mới bị trùng lặp hoặc không tìm thấy sân.
     */
    public void updateSan(int sanId, SanUpdateRequest request, int managerCoSoId) {
        San existing = sanDAO.getSanById(sanId);
        BranchSecurityUtils.getEntityOrThrow(existing, "Sân");
        BranchSecurityUtils.checkBranchAccess(existing.getCoSoID(), managerCoSoId);

        validateSanRequest(request);

        // Kiểm tra trùng tên sân trong cùng cơ sở (trừ chính nó)
        jakarta.persistence.EntityManager em = org.example.util.JPAUtil.getEntityManager();
        try {
            Long count = em.createQuery("SELECT COUNT(s) FROM San s WHERE LOWER(TRIM(s.tenSan)) = :tenSan AND s.coSoID = :coSoId AND s.sanID != :sanId AND s.isDeleted = false", Long.class)
                    .setParameter("tenSan", request.getTenSan().trim().toLowerCase())
                    .setParameter("coSoId", managerCoSoId)
                    .setParameter("sanId", sanId)
                    .getSingleResult();
            if (count > 0) {
                throw new IllegalArgumentException("Tên sân đã tồn tại trong cơ sở này.");
            }
        } finally {
            em.close();
        }

        if (request.getTrangThai() != null && !request.getTrangThai().equals(existing.getTrangThai())) {
            checkActiveBookingsForStatusChange(sanId, request.getTrangThai());
        }

        updateSanFromRequest(existing, request);
        // Đảm bảo coSoId không thay đổi
        existing.setCoSoID(managerCoSoId);

        sanDAO.update(existing);
    }

    /**
     * Nghĩa tiếng Việt: Kiểm tra các ca đặt sân đang hoạt động (checkActiveBookings).
     *
     * Mục đích:
     * - Ngăn cản quản lý thay đổi trạng thái sân nếu sân đó đang có các lịch đặt sân hoạt động trong tương lai hoặc đang diễn ra để tránh ảnh hưởng khách đặt.
     *
     * Input:
     * - sanId: ID sân cần kiểm tra
     * - newStatus: Trạng thái sân mới muốn cập nhật
     *
     * Output:
     * - Không có (void)
     *
     * Rủi ro:
     * - Cao. Ném IllegalArgumentException nếu phát hiện các đơn đặt sân đang hoạt động.
     */
    private void checkActiveBookingsForStatusChange(int sanId, String newStatus) {
        if ("Sẵn sàng".equals(newStatus)) {
            String sql = "SELECT COUNT(*) FROM LichDatSan WHERE SanID = ? AND TrangThai = N'Đang sử dụng'";
            try (Connection conn = DBUtil.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, sanId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        throw new IllegalArgumentException("Không thể chuyển sân sang Sẵn sàng vì đang có ca đặt sân Đang sử dụng.");
                    }
                }
            } catch (SQLException e) {
                logger.error("Lỗi khi kiểm tra trạng thái hoạt động của sân ID {}: {}", sanId, e.getMessage(), e);
                throw new RuntimeException("Lỗi hệ thống khi kiểm tra lịch đặt sân.", e);
            }
        }
        if ("Tạm đóng".equals(newStatus) || "Bảo trì".equals(newStatus)) {
            String sql = "SELECT COUNT(*) FROM LichDatSan " +
                         "WHERE SanID = ? AND TrangThai IN (N'Đã xác nhận', N'Chờ xác nhận', N'Đang sử dụng') " +
                         "AND DATEADD(second, DATEDIFF(second, '00:00:00', GioKetThuc), DATEADD(day, CASE WHEN GioKetThuc < GioBatDau THEN 1 ELSE 0 END, CAST(NgayDat AS datetime))) > GETDATE()";
            try (Connection conn = DBUtil.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, sanId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        throw new IllegalArgumentException(
                            "Không thể đóng hoặc bảo trì sân vì đang có " + rs.getInt(1) + 
                            " ca đặt sân hoạt động hoặc chờ duyệt trong tương lai."
                        );
                    }
                }
            } catch (SQLException e) {
                logger.error("Lỗi khi kiểm tra lịch đặt sân hoạt động của sân ID {}: {}", sanId, e.getMessage(), e);
                throw new RuntimeException("Lỗi hệ thống khi kiểm tra lịch đặt sân.", e);
            }
        }
    }

    /**
     * Xóa sân (soft delete - chuyển trạng thái)
     */
    public void deleteSan(int sanId, int managerCoSoId) {
        San san = sanDAO.getSanById(sanId);
        BranchSecurityUtils.getEntityOrThrow(san, "Sân");
        BranchSecurityUtils.checkBranchAccess(san.getCoSoID(), managerCoSoId);

        // Chặn xóa sân nếu đang có ca đặt sân hoạt động hoặc chưa hoàn thành
        String sql = "SELECT COUNT(*) FROM LichDatSan " +
                     "WHERE SanID = ? AND TrangThai IN (N'Đã xác nhận', N'Chờ xác nhận', N'Đang sử dụng') " +
                     "AND DATEADD(second, DATEDIFF(second, '00:00:00', GioKetThuc), DATEADD(day, CASE WHEN GioKetThuc < GioBatDau THEN 1 ELSE 0 END, CAST(NgayDat AS datetime))) > GETDATE()";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, sanId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) {
                    throw new IllegalArgumentException(
                        "Không thể xóa sân vì đang có " + rs.getInt(1) + 
                        " ca đặt sân hoạt động hoặc chưa hoàn thành trong tương lai."
                    );
                }
            }
        } catch (SQLException e) {
            logger.error("Lỗi khi kiểm tra lịch đặt sân hoạt động của sân ID {}: {}", sanId, e.getMessage(), e);
            throw new RuntimeException("Lỗi hệ thống khi kiểm tra lịch đặt sân.", e);
        }

        boolean success = sanDAO.softDelete(sanId, 0);
        if (!success) {
            throw new RuntimeException("Không thể thực hiện xóa mềm sân thi đấu.");
        }
    }


    /**
     * Nghĩa tiếng Việt: Cập nhật trạng thái sân / Khóa / Mở khóa sân (updateSanStatus / lockSan / unlockSan).
     *
     * Mục đích:
     * - Chuyển đổi trạng thái của sân (ví dụ: khóa tạm thời bằng trạng thái "Tạm đóng", mở khóa bằng trạng thái "Sẵn sàng").
     *
     * Input:
     * - sanId: ID sân thi đấu
     * - newStatus: Trạng thái mới ("Sẵn sàng", "Tạm đóng", "Bảo trì", v.v.)
     * - managerCoSoId: ID cơ sở của quản lý
     *
     * Output:
     * - Không có (void)
     *
     * Rủi ro:
     * - Cao. Sẽ ném IllegalArgumentException nếu trạng thái không hợp lệ hoặc vi phạm quy tắc checkActiveBookings.
     */
    public void updateSanStatus(int sanId, String newStatus, int managerCoSoId) {
        San san = sanDAO.getSanById(sanId);
        BranchSecurityUtils.getEntityOrThrow(san, "Sân");
        BranchSecurityUtils.checkBranchAccess(san.getCoSoID(), managerCoSoId);

        if (newStatus == null) {
            throw new IllegalArgumentException("Trạng thái sân không được để trống");
        }
        String status = newStatus.trim();
        if (!"Sẵn sàng".equals(status) && !"Tạm đóng".equals(status) && !"Bảo trì".equals(status) && !"Đang dùng".equals(status) && !"Đang sử dụng".equals(status)) {
            throw new IllegalArgumentException("Trạng thái sân không hợp lệ. Chỉ chấp nhận: Sẵn sàng, Tạm đóng, Bảo trì, Đang dùng, Đang sử dụng");
        }

        checkActiveBookingsForStatusChange(sanId, status);

        san.setTrangThai(status);
        sanDAO.update(san);
    }


    // ==================== LOAI SAN OPERATIONS ====================

    /**
     * Tạo loại sân mới
     */
    public LoaiSan createLoaiSan(LoaiSanRequest request, int managerCoSoId) {
        validateLoaiSanRequest(request);

        LoaiSan ls = new LoaiSan();
        updateLoaiSanFromRequest(ls, request);
        ls.setCoSoID(managerCoSoId);

        loaiSanDAO.insert(ls);
        return ls;
    }

    /**
     * Nghĩa tiếng Việt: Cập nhật cấu hình loại sân (updateLoaiSan).
     *
     * Mục đích:
     * - Sửa đổi thông tin cấu hình của loại sân (như giá tiền theo khung giờ, giờ lên đèn, v.v.).
     *
     * Input:
     * - loaiSanId: ID loại sân cần cập nhật
     * - request: Thông tin cập nhật (LoaiSanRequest)
     * - managerCoSoId: ID cơ sở của quản lý
     *
     * Output:
     * - Không có (void)
     *
     * Rủi ro:
     * - Thấp. Ném ngoại lệ if-else nếu thông tin request không hợp lệ.
     */
    public void updateLoaiSan(int loaiSanId, LoaiSanRequest request, int managerCoSoId) {
        LoaiSan existing = loaiSanDAO.getLoaiSanById(loaiSanId);
        BranchSecurityUtils.getEntityOrThrow(existing, "Loại sân");
        BranchSecurityUtils.checkBranchAccess(existing.getCoSoID(), managerCoSoId);

        validateLoaiSanRequest(request);

        updateLoaiSanFromRequest(existing, request);
        existing.setCoSoID(managerCoSoId); // Giới hạn ở chi nhánh của quản lý

        loaiSanDAO.update(existing);
    }

    /**
     * Xóa loại sân (hard delete)
     */
    public void deleteLoaiSan(int loaiSanId, int managerCoSoId) {
        LoaiSan ls = loaiSanDAO.getLoaiSanById(loaiSanId);
        BranchSecurityUtils.getEntityOrThrow(ls, "Loại sân");
        BranchSecurityUtils.checkBranchAccess(ls.getCoSoID(), managerCoSoId);

        // Kiểm tra xem có sân đang hoạt động nào sử dụng loại sân này hay không
        Long courtCount = sanDAO.countSansByLoaiSanId(loaiSanId);
        if (courtCount > 0) {
            throw new IllegalArgumentException(
                "Không thể xóa loại sân này vì đang có " + courtCount + " sân liên kết với nó"
            );
        }

        boolean success = loaiSanDAO.softDelete(loaiSanId, 0);
        if (!success) {
            throw new RuntimeException("Không thể thực hiện xóa mềm loại sân.");
        }
    }

    // ==================== VALIDATION HELPERS ====================

    private void validateSanRequest(SanCreateRequest req) {
        Map<String, String> errors = new java.util.HashMap<>();

        if (req.getTenSan() == null || req.getTenSan().trim().isEmpty()) {
            errors.put("tenSan", "Tên sân không được để trống");
        } else if (req.getTenSan().trim().length() > 50) {
            errors.put("tenSan", "Tên sân không được vượt quá 50 ký tự");
        }

        String hinhAnh = req.getHinhAnh();
        if (hinhAnh != null && !hinhAnh.trim().isEmpty()) {
            String url = hinhAnh.trim();
            if (!url.startsWith("http://") && !url.startsWith("https://") && !url.startsWith("/")) {
                errors.put("hinhAnh", "Đường dẫn ảnh không hợp lệ (phải bắt đầu bằng http://, https:// hoặc /)");
            }
        }

        if (req.getLoaiSanId() <= 0) {
            errors.put("loaiSanId", "Phải chọn loại sân");
        }

        if (req.getTrangThai() != null) {
            String status = req.getTrangThai().trim();
            if (!"Sẵn sàng".equals(status) && !"Tạm đóng".equals(status) && !"Bảo trì".equals(status) && !"Đang dùng".equals(status) && !"Đang sử dụng".equals(status)) {
                errors.put("trangThai", "Trạng thái sân không hợp lệ. Chỉ chấp nhận: Sẵn sàng, Tạm đóng, Bảo trì, Đang dùng, Đang sử dụng");
            }
        }

        if (!errors.isEmpty()) {
            throw new IllegalArgumentException(errors.toString());
        }
    }

    private void validateSanRequest(SanUpdateRequest req) {
        validateSanRequest(new SanCreateRequest() {{
            setTenSan(req.getTenSan());
            setLoaiSanId(req.getLoaiSanId());
            setTrangThai(req.getTrangThai());
            setHinhAnh(req.getHinhAnh());
        }});
    }

    private void validateLoaiSanRequest(LoaiSanRequest req) {
        Map<String, String> errors = new java.util.HashMap<>();

        if (req.getTenLoai() == null || req.getTenLoai().trim().isEmpty()) {
            errors.put("tenLoai", "Tên loại sân không được để trống");
        }

        if (req.getMonTheThaoId() <= 0) {
            errors.put("monTheThaoId", "Phải chọn môn thể thao");
        }

        ValidationUtils.validatePositiveNumber(req.getGiaKhongDen(), "giaKhongDen");

        if (!req.isKhongDungDen()) {
            // Có sử dụng đèn: bắt buộc giá và giờ đèn
            if (req.getGiaCoDen() == null || req.getGiaCoDen().compareTo(BigDecimal.ZERO) <= 0) {
                errors.put("giaCoDen", "Vui lòng nhập đầy đủ giá và thời gian áp dụng giá có đèn.");
            }
            if (req.getGioBatDauLenDen() == null) {
                errors.put("gioBatDauLenDen", "Vui lòng nhập đầy đủ giá và thời gian áp dụng giá có đèn.");
            }
            if (req.getGioKetThucLenDen() == null) {
                errors.put("gioKetThucLenDen", "Vui lòng nhập đầy đủ giá và thời gian áp dụng giá có đèn.");
            }
            // Không chặn start >= end — start > end có nghĩa là qua ngày, start == end là toàn thời gian
        }
        // Nếu khongDungDen: không bắt buộc giaCoDen, gioBatDau, gioKetThuc

        if (!errors.isEmpty()) {
            throw new IllegalArgumentException(errors.toString());
        }
    }

    /**
     * Kiểm tra một thời điểm có thuộc khung giờ đèn không.
     * - start == end: đèn toàn thời gian (luôn trả true)
     * - start < end: khung cùng ngày [start, end)
     * - start > end: khung qua nửa đêm [start, 24h) ∪ [0h, end)
     * - start hoặc end null / sân không dùng đèn: trả false
     */
    public static boolean isLightingTime(LocalTime time, LocalTime start, LocalTime end) {
        if (start == null || end == null) return false;
        if (start.equals(end)) return true;          // toàn thời gian
        if (start.isBefore(end)) {
            // Cùng ngày: [start, end)
            return !time.isBefore(start) && time.isBefore(end);
        }
        // Qua nửa đêm: [start, 24h) ∪ [0h, end)
        return !time.isBefore(start) || time.isBefore(end);
    }

    // ==================== MAPPER HELPERS ====================

    private void updateSanFromRequest(San san, SanCreateRequest req) {
        san.setTenSan(req.getTenSan());
        san.setLoaiSanID(req.getLoaiSanId());
        san.setTrangThai(req.getTrangThai() != null ? req.getTrangThai() : Constants.TRANG_THAI_SAN_SAN_SANG);
        san.setMoTa(req.getMoTa());
        san.setHinhAnh(req.getHinhAnh());
    }

    private void updateSanFromRequest(San san, SanUpdateRequest req) {
        san.setTenSan(req.getTenSan());
        san.setLoaiSanID(req.getLoaiSanId());
        if (req.getTrangThai() != null) {
            san.setTrangThai(req.getTrangThai());
        }
        san.setMoTa(req.getMoTa());
        san.setHinhAnh(req.getHinhAnh());
    }

    private void updateLoaiSanFromRequest(LoaiSan ls, LoaiSanRequest req) {
        ls.setTenLoai(req.getTenLoai());
        ls.setMonTheThaoID(req.getMonTheThaoId());
        ls.setGiaKhongDen(req.getGiaKhongDen() != null ? req.getGiaKhongDen().doubleValue() : 0.0);
        if (req.isKhongDungDen()) {
            // Sân không dùng đèn: clear toàn bộ dữ liệu đèn cũ
            ls.setGiaCoDen(0.0);
            ls.setGioBatDauLenDen(null);
            ls.setGioKetThucLenDen(null);
        } else {
            ls.setGiaCoDen(req.getGiaCoDen() != null ? req.getGiaCoDen().doubleValue() : 0.0);
            ls.setGioBatDauLenDen(req.getGioBatDauLenDen());
            ls.setGioKetThucLenDen(req.getGioKetThucLenDen());
        }
    }
}
