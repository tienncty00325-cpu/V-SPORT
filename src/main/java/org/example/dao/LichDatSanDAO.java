package org.example.dao;

import org.example.model.Lichdatsan;
import java.util.List;

public interface LichDatSanDAO {
    List<Lichdatsan> getAllLichDatSan();
    List<Lichdatsan> getLichByAccountId(int accountId);
    Lichdatsan getLichById(int id);
    boolean addLichDatSan(Lichdatsan lich);
    boolean updateTrangThai(int id, String trangThai);
    /**
     * Hủy booking do khách tự thao tác — atomic UPDATE với WHERE guard trạng thái nguồn để
     * chống double-click/retry (0 dòng ảnh hưởng nghĩa là đã hủy/đổi trạng thái từ trước, KHÔNG
     * phải lỗi). Chỉ cho phép hủy từ: Chờ xác nhận, Đã xác nhận, hoặc Chờ thanh toán còn hạn giữ chỗ.
     * @return số dòng bị ảnh hưởng (0 hoặc 1).
     */
    int cancelByCustomer(java.sql.Connection conn, int datSanId, int accountId, String cancelType, String cancelReason) throws java.sql.SQLException;
    boolean updateGhiChu(int id, String ghiChu);
    /** Xóa cứng lịch đặt sân khỏi DB */
    boolean hardDelete(int id);
    List<Lichdatsan> getLichDatSanTodayByCoSo(int coSoId);
    List<Lichdatsan> getLichDatSanByCoSo(int coSoId);
    boolean duyetLichDatSan(int datSanId, int approvedByAccountId, int coSoId, boolean confirmPriceChange) throws Exception;
    boolean tuChoiLichDatSan(int datSanId, String ghiChu, int coSoId) throws Exception;
    boolean updateDichVuDatSan(int datSanId, int[] productIds, int[] quantities) throws Exception;
    /** Như trên, nhưng bắt buộc DatSanID phải thuộc requiredCoSoId (dùng cho Manager/Staff thao tác qua Check-in). */
    boolean updateDichVuDatSan(int datSanId, int[] productIds, int[] quantities, Integer requiredCoSoId) throws Exception;
    /** Xóa mềm lịch đặt sân theo ID */
    boolean softDelete(int id, int actorId);
    /** Khôi phục lịch đặt sân đã bị xóa mềm */
    boolean restore(int id);
    /** Lấy danh sách lịch đặt sân đã bị xóa mềm theo cơ sở */
    List<Lichdatsan> findDeletedByCoSo(int coSoId);
    /** Lấy danh sách ID lịch đặt sân đã bị xóa mềm lâu hơn N ngày */
    List<Integer> findDeletedIdsOlderThan(int days);
}
