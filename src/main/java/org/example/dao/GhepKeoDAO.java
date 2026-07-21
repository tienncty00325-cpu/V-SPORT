package org.example.dao;

import org.example.model.ChiTietGhepKeo;
import org.example.model.GhepKeo;

import java.time.LocalDate;
import java.util.List;

/**
 * DAO cho Ghép kèo (Matchmaking).
 * Tối ưu cho luồng Customer Portal — read qua các *View* DTO (kèm JOIN sang LichDatSan, San,
 * CoSo, MonTheThao, TaiKhoan) để tránh N+1 query. Write dùng thẳng entity gốc.
 */
public interface GhepKeoDAO {

    class GhepKeoView {
        public int keoId;
        public int datSanId;
        public int accountIdNguoiTao;
        public String tenNguoiTao;
        public Integer diemUyTinNguoiTao;
        public Integer monTheThaoId;
        public String tenMonTheThao;
        public String moTa;
        public String trinhDo;
        public String trangThai;
        // Metadata parsed từ MoTa JSON prefix
        public int soNguoiCanTim;
        public String hinhThucDuyet; // "auto" | "manual"
        public String actualNote;    // moTa sau khi bóc JSON prefix
        // Booking gốc
        public LocalDate ngayDat;
        public String gioBatDau;
        public String gioKetThuc;
        public String trangThaiBooking;
        // Sân + cơ sở
        public int sanId;
        public String tenSan;
        public int coSoId;
        public String tenCoSo;
        public String diaChiCoSo;
        public String tenLoaiSan;
        // Người tham gia đã xác nhận (không đếm chờ duyệt/từ chối/rời)
        public int soNguoiThamGia;
    }

    class ChiTietGhepKeoView {
        public int chiTietKeoId;
        public int keoId;
        public int accountId;
        public String tenNguoiChoi;
        public Integer diemUyTin;
        public String trangThaiThamGia;
        public String viTriThamGia;
    }

    /**
     * Tạo kèo mới. Gán mặc định TrangThai = "Đang mở" nếu chưa có.
     * @return keoId mới hoặc -1 nếu thất bại.
     */
    int create(GhepKeo keo);

    /**
     * Lấy chi tiết một kèo kèm join dữ liệu hiển thị (facility, san, môn, chủ kèo, số thành viên).
     * @return null nếu không tìm thấy.
     */
    GhepKeoView getViewById(int keoId);

    /** Kèo đang mở, có thể lọc theo cơ sở/môn/ngày. Trả về sắp xếp theo ngày gần nhất trước. */
    List<GhepKeoView> listOpenMatches(Integer coSoId, Integer monTheThaoId, LocalDate fromDate, LocalDate toDate);

    /** Kèo do chủ kèo tạo. */
    List<GhepKeoView> listByCreator(int accountId);

    /** Kèo mà tài khoản đã tham gia (bất kể trạng thái tham gia nào ngoài "Đã hủy"). */
    List<GhepKeoView> listByParticipant(int accountId);

    /** Cập nhật trạng thái kèo, chỉ khi accountId là chủ kèo (return false nếu không phải). */
    boolean updateStatusIfOwner(int keoId, String newStatus, int ownerAccountId);

    /**
     * Thêm người tham gia (idempotent-ish: nếu đã có bản ghi active thì trả về id cũ).
     * Trả về chiTietKeoId. Ném IllegalStateException nếu kèo đã đầy / đóng / hoặc người dùng
     * đã ở trong kèo với trạng thái đang chờ/đã tham gia.
     */
    int addParticipant(int keoId, int accountId, String status, String position) throws Exception;

    /** Cập nhật trạng thái participant, chỉ khi actor là chủ kèo hoặc chính participant. */
    boolean updateParticipantStatus(int chiTietKeoId, String newStatus, int actorAccountId, boolean actorIsOwner);

    /** Đếm số người tham gia (trạng thái Đã tham gia). */
    int countAcceptedParticipants(int keoId);

    /** Danh sách người tham gia (kèm tên hiển thị) — dùng cho chủ kèo duyệt. */
    List<ChiTietGhepKeoView> listParticipants(int keoId);

    /** Trả về participant view của accountId cho keoId (null nếu chưa tham gia hoặc đã rời/từ chối). */
    ChiTietGhepKeoView getActiveParticipant(int keoId, int accountId);
}
