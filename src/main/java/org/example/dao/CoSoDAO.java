package org.example.dao;

import org.example.dto.FacilityMapDTO;
import org.example.model.CoSo;
import java.util.List;

public interface CoSoDAO {
    List<CoSo> getAllCoSo();

    /**
     * Tìm kiếm cơ sở đang hoạt động theo từ khóa (tên/địa chỉ) và tùy chọn lọc
     * theo môn thể thao. Dùng cho trang tìm kiếm Customer Portal (/customer/tim-kiem).
     * Toàn bộ tham số đều bind qua JPQL parameter — không nối chuỗi SQL.
     *
     * @param keyword từ khóa tìm theo tên cơ sở hoặc địa chỉ (case-insensitive,
     *                khớp một phần); null/rỗng nghĩa là không lọc theo từ khóa.
     * @param monTheThaoId lọc cơ sở có ít nhất một sân thuộc môn thể thao này
     *                     (qua San -&gt; LoaiSan -&gt; MonTheThao); null nghĩa là không lọc.
     */
    List<CoSo> searchCoSo(String keyword, Integer monTheThaoId);

    /**
     * Toàn bộ CoSo chưa bị xóa mềm, KHÔNG lọc theo TrangThai — dùng riêng cho
     * trang Quản lý Owner (cần thấy cả "Chờ duyệt"/"Từ chối" để build các tab).
     * Không dùng cho trang Quản lý Cơ sở/Nhân sự/booking (dùng getAllCoSo()).
     */
    List<CoSo> getAllCoSoIncludingPending();

    CoSo getCoSoById(int id);
    boolean addCoSo(CoSo coSo);
    boolean updateCoSo(CoSo coSo);
    boolean deleteCoSo(int id);

    // Soft-delete support (Task 5)
    boolean softDelete(int coSoId, int actorId);
    boolean restore(int coSoId);
    boolean hardDeleteCascade(int coSoId);
    List<CoSo> findDeleted();
    List<Integer> findDeletedIdsOlderThan(int days);

    // Soft-archive all rejected CoSo for an account except the one being approved
    boolean archiveRejectedForAccount(int accountId, int excludeCoSoId, int actorId);

    /**
     * Kiểm tra account đã có cơ sở khác đang "Chờ duyệt" hoặc "Đang hoạt động"
     * hay chưa (dùng khi thu hồi một OwnerRequest bị từ chối từ thùng rác,
     * tránh tạo ra hai yêu cầu/cơ sở cùng hoạt động cho một account).
     */
    boolean hasActiveOrPendingCoSo(int accountId, int excludeCoSoId);

    /**
     * Cơ sở hợp lệ để hiển thị marker trên bản đồ Customer
     * (/api/customer/facilities/map): chưa xóa mềm, TrangThai = "Đang hoạt động",
     * và có đủ cả ViDo lẫn KinhDo (không NULL). Một truy vấn duy nhất, không N+1 —
     * giá thấp nhất và số sân sẵn sàng lấy qua subquery tương quan như
     * FacilityDetailApiServlet đang dùng.
     *
     * @param sportId      lọc cơ sở có ít nhất một LoaiSan thuộc môn này; null = không lọc.
     * @param keyword      lọc theo TenCoSo hoặc DiaChi (case-insensitive, khớp một phần);
     *                     null/rỗng = không lọc.
     * @param facilityId   nếu khác null, chỉ trả đúng cơ sở này (vẫn phải thỏa các điều
     *                     kiện hợp lệ ở trên).
     */
    List<FacilityMapDTO> getAllCoSoForMap(Integer sportId, String keyword, Integer facilityId);
}
