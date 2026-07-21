package org.example.service;

import org.example.dao.YeuCauNghiDAO;
import org.example.dao.impl.YeuCauNghiDAOImpl;
import org.example.dao.CaLamViecDAO;
import org.example.dao.impl.CaLamViecDAOImpl;
import org.example.dao.ThongBaoDAO;
import org.example.dao.impl.ThongBaoDAOImpl;
import org.example.model.TaiKhoan;
import org.example.model.YeuCauNghi;
import org.example.model.ThongBao;

import java.time.LocalDate;
import java.util.List;

/**
 * Tên tiếng Việt: Dịch vụ xử lý yêu cầu nghỉ phép.
 *
 * Nhiệm vụ:
 * - Nhân viên gửi đơn nghỉ phép, kiểm tra hạn mức (tối đa 4 ngày/tháng).
 * - Quản lý duyệt/từ chối đơn xin nghỉ phép.
 * - Tự động xóa ca làm việc của nhân viên trong ngày nghỉ đã phê duyệt.
 * - Gửi thông báo cho quản lý chi nhánh và nhân viên khi trạng thái đơn thay đổi.
 *
 * Được gọi bởi:
 * - YeuCauNghiManagerServlet.java
 * - YeuCauNghiStaffServlet.java
 *
 * Lưu ý:
 * - Có sử dụng JPA EntityManager để truy vấn quản lý chi nhánh khi tạo đơn.
 */
public class YeuCauNghiService {
    private final YeuCauNghiDAO yeuCauNghiDAO;
    private final CaLamViecDAO caLamViecDAO;
    private final ThongBaoDAO thongBaoDAO;

    public YeuCauNghiService() {
        this.yeuCauNghiDAO = new YeuCauNghiDAOImpl();
        this.caLamViecDAO = new CaLamViecDAOImpl();
        this.thongBaoDAO = new ThongBaoDAOImpl();
    }

    public YeuCauNghiService(YeuCauNghiDAO yeuCauNghiDAO, CaLamViecDAO caLamViecDAO, ThongBaoDAO thongBaoDAO) {
        this.yeuCauNghiDAO = yeuCauNghiDAO;
        this.caLamViecDAO = caLamViecDAO;
        this.thongBaoDAO = thongBaoDAO;
    }

    /**
     * Nghĩa tiếng Việt: Tạo yêu cầu nghỉ phép mới.
     *
     * Mục đích:
     * - Nhân viên gửi đơn xin nghỉ phép. Hệ thống thực hiện kiểm tra hạn mức nghỉ (tối đa 4 ngày/tháng), 
     *   kiểm tra trùng lịch và ngày nghỉ trong quá khứ trước khi lưu đơn và gửi thông báo cho quản lý.
     *
     * Input:
     * - yeuCauNghi: Thực thể chứa thông tin đơn xin nghỉ phép
     *
     * Output:
     * - boolean: true nếu tạo thành công, false nếu thất bại
     *
     * Rủi ro:
     * - Thấp. Có thể ném IllegalArgumentException nếu dữ liệu không hợp lệ hoặc vượt hạn mức.
     */
    public boolean createYeuCauNghi(YeuCauNghi yeuCauNghi) {
        // Kiểm tra tính hợp lệ
        if (yeuCauNghi.getAccountID() <= 0) {
            throw new IllegalArgumentException("AccountID không hợp lệ");
        }
        if (yeuCauNghi.getCoSoID() <= 0) {
            throw new IllegalArgumentException("CoSoID không hợp lệ");
        }
        if (yeuCauNghi.getNgayNghi() == null) {
            throw new IllegalArgumentException("Ngày nghỉ không được để trống");
        }
        if (yeuCauNghi.getLoaiNghi() == null || yeuCauNghi.getLoaiNghi().isEmpty()) {
            throw new IllegalArgumentException("Loại nghỉ không được để trống");
        }
        if (yeuCauNghi.getLyDo() == null || yeuCauNghi.getLyDo().trim().isEmpty()) {
            throw new IllegalArgumentException("Lý do không được để trống");
        }

        // Kiểm tra ngày nghỉ không được trong quá khứ (trừ khi là hủy)
        LocalDate today = LocalDate.now();
        if (yeuCauNghi.getNgayNghi().isBefore(today) && !"DaHuy".equals(yeuCauNghi.getTrangThai())) {
            throw new IllegalArgumentException("Ngày nghỉ không được trong quá khứ");
        }

        // Kiểm tra xem đã có yêu cầu nghỉ vào ngày này chưa
        if (yeuCauNghiDAO.existsByAccountIDAndNgayNghi(yeuCauNghi.getAccountID(), yeuCauNghi.getNgayNghi())) {
            throw new IllegalArgumentException("Bạn đã có yêu cầu nghỉ vào ngày này rồi");
        }



        // Kiểm tra hạn mức nghỉ phép: tối đa 4 ngày nghỉ/tháng
        int targetMonth = yeuCauNghi.getNgayNghi().getMonthValue();
        int targetYear = yeuCauNghi.getNgayNghi().getYear();
        
        List<YeuCauNghi> existingLeaves = yeuCauNghiDAO.findByAccountID(yeuCauNghi.getAccountID());
        long leaveDaysInMonth = 0;
        if (existingLeaves != null) {
            leaveDaysInMonth = existingLeaves.stream()
                .filter(y -> !"DaHuy".equals(y.getTrangThai()) && !"TuChoi".equals(y.getTrangThai()))
                .filter(y -> y.getNgayNghi().getMonthValue() == targetMonth && y.getNgayNghi().getYear() == targetYear)
                .count();
        }
                
        if (leaveDaysInMonth >= 4) {
            throw new IllegalArgumentException("Hạn mức nghỉ phép vượt quá quy định (tối đa 4 ngày/tháng). Bạn đã đăng ký/nghỉ " + leaveDaysInMonth + " ngày trong tháng " + targetMonth + "/" + targetYear + ".");
        }

        // Đặt trạng thái mặc định là "ChoDuyet"
        yeuCauNghi.setTrangThai("ChoDuyet");
        yeuCauNghi.setNgayGui(java.time.LocalDateTime.now());

        boolean inserted = yeuCauNghiDAO.insert(yeuCauNghi) > 0;
        if (inserted) {
            // Gửi thông báo cho quản lý chi nhánh
            jakarta.persistence.EntityManager em = org.example.util.JPAUtil.getEntityManager();
            try {
                List<TaiKhoan> managers = em.createQuery(
                    "SELECT t FROM TaiKhoan t WHERE t.coSoId = :coSoId AND t.roleId = 2", TaiKhoan.class)
                    .setParameter("coSoId", yeuCauNghi.getCoSoID())
                    .getResultList();
                for (TaiKhoan manager : managers) {
                    String tieuDe = "Yêu cầu nghỉ phép mới";
                    String noiDung = String.format("Nhân viên ID %d đã gửi yêu cầu nghỉ %s ngày %s.",
                                                  yeuCauNghi.getAccountID(), yeuCauNghi.getLoaiNghi(), yeuCauNghi.getNgayNghi().toString());
                    ThongBao thongBao = new ThongBao(manager.getAccountId(), tieuDe, noiDung, "YeuCauNghi");
                    thongBaoDAO.insert(thongBao);
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                em.close();
            }
        }
        return inserted;
    }

    /**
     * Lấy yêu cầu nghỉ theo ID
     */
    public YeuCauNghi getYeuCauNghiById(int id) {
        return yeuCauNghiDAO.findById(id);
    }

    /**
     * Lấy tất cả yêu cầu nghỉ
     */
    public List<YeuCauNghi> getAllYeuCauNghi() {
        return yeuCauNghiDAO.findAll();
    }

    /**
     * Lấy tất cả yêu cầu nghỉ của một cơ sở (có thể lọc theo trạng thái)
     */
    public List<YeuCauNghi> getYeuCauNghiByCoSo(int coSoID, String trangThai) {
        if (coSoID <= 0) {
            throw new IllegalArgumentException("CoSoID không hợp lệ");
        }
        if (trangThai == null || trangThai.isEmpty()) {
            return yeuCauNghiDAO.findByCoSoID(coSoID);
        } else {
            return yeuCauNghiDAO.findByCoSoIDAndTrangThai(coSoID, trangThai);
        }
    }

    /**
     * Lấy danh sách yêu cầu nghỉ của một nhân viên
     */
    public List<YeuCauNghi> getYeuCauNghiByAccount(int accountID) {
        if (accountID <= 0) {
            throw new IllegalArgumentException("AccountID không hợp lệ");
        }
        return yeuCauNghiDAO.findByAccountID(accountID);
    }

    /**
     * Lấy danh sách yêu cầu nghỉ của một nhân viên theo trạng thái
     */
    public List<YeuCauNghi> getYeuCauNghiByAccountAndStatus(int accountID, String trangThai) {
        if (accountID <= 0) {
            throw new IllegalArgumentException("AccountID không hợp lệ");
        }
        if (trangThai == null || trangThai.isEmpty()) {
            return getYeuCauNghiByAccount(accountID);
        }
        return yeuCauNghiDAO.findByAccountIDAndTrangThai(accountID, trangThai);
    }

    /**
     * Nghĩa tiếng Việt: Lấy các yêu cầu nghỉ phép sắp tới (getUpcomingLeaves).
     *
     * Mục đích:
     * - Tìm kiếm toàn bộ danh sách đơn xin nghỉ phép trong tương lai của nhân viên dựa trên ID tài khoản.
     *
     * Input:
     * - accountID: ID của tài khoản nhân viên
     *
     * Output:
     * - List<YeuCauNghi>: Danh sách đơn nghỉ phép sắp tới
     *
     * Rủi ro:
     * - Thấp. Ném IllegalArgumentException nếu accountID không hợp lệ.
     */
    public List<YeuCauNghi> getUpcomingYeuCauNghiByAccount(int accountID) {
        if (accountID <= 0) {
            throw new IllegalArgumentException("AccountID không hợp lệ");
        }
        return yeuCauNghiDAO.findUpcomingByAccountID(accountID);
    }

    /**
     * Lấy danh sách yêu cầu chờ duyệt của một cơ sở
     */
    public List<YeuCauNghi> getPendingYeuCauNghiByCoSo(int coSoID) {
        if (coSoID <= 0) {
            throw new IllegalArgumentException("CoSoID không hợp lệ");
        }
        return yeuCauNghiDAO.findByCoSoIDAndTrangThai(coSoID, "ChoDuyet");
    }

    /**
     * Đếm số lượng yêu cầu chờ duyệt của một cơ sở
     */
    public int countPendingYeuCauNghiByCoSo(int coSoID) {
        if (coSoID <= 0) {
            throw new IllegalArgumentException("CoSoID không hợp lệ");
        }
        return yeuCauNghiDAO.countPendingByCoSoID(coSoID);
    }

    /**
     * Nghĩa tiếng Việt: Phê duyệt yêu cầu nghỉ phép.
     *
     * Mục đích:
     * - Chấp nhận đơn xin nghỉ phép của nhân viên. Hệ thống tự động chuyển trạng thái đơn sang 'DaDuyet', 
     *   xóa toàn bộ lịch ca làm việc của nhân viên đó trong ngày được nghỉ và gửi thông báo phản hồi.
     *
     * Input:
     * - yeuCauNghiID: ID của đơn xin nghỉ phép
     * - quanLyID: ID tài khoản quản lý thực hiện duyệt
     * - ghiChuQuanLy: Ghi chú giải trình của quản lý
     *
     * Output:
     * - boolean: true nếu duyệt thành công, false nếu thất bại
     *
     * Rủi ro:
     * - Trung bình. Lỗi nếu đơn không tồn tại, đã xử lý trước đó, hoặc nhân viên vẫn còn ca chưa đổi.
     */
    public boolean approveYeuCauNghi(int yeuCauNghiID, int quanLyID, String ghiChuQuanLy) {
        if (quanLyID <= 0) {
            throw new IllegalArgumentException("Quản lý ID không hợp lệ");
        }

        YeuCauNghi ycn = yeuCauNghiDAO.findById(yeuCauNghiID);
        if (ycn == null) {
            throw new IllegalArgumentException("Yêu cầu nghỉ không tồn tại");
        }

        if (!"ChoDuyet".equals(ycn.getTrangThai())) {
            throw new IllegalArgumentException("Yêu cầu đã được xử lý trước đó");
        }



        // Cập nhật trạng thái
        ycn.setTrangThai("DaDuyet");
        ycn.setGhiChuQuanLy(ghiChuQuanLy);
        ycn.setNgayXuLy(java.time.LocalDateTime.now());
        ycn.setXuLyBy(quanLyID);

        boolean success = yeuCauNghiDAO.update(ycn);

        if (success) {
            // Tự động xóa ca làm của nhân viên vào ngày nghỉ (nếu có)
            caLamViecDAO.deleteByAccountIDAndNgayLam(ycn.getAccountID(), ycn.getNgayNghi());

            // Gửi thông báo cho nhân viên
            String tieuDe = "Yêu cầu nghỉ của bạn đã được phê duyệt";
            String noiDung = String.format("Yêu cầu nghỉ %s ngày %s đã được quản lý phê duyệt.",
                                          ycn.getLoaiNghi(), ycn.getNgayNghi().toString());
            ThongBao thongBao = new ThongBao(ycn.getAccountID(), tieuDe, noiDung, "YeuCauNghi");
            thongBaoDAO.insert(thongBao);
        }

        return success;
    }

    /**
     * Nghĩa tiếng Việt: Từ chối yêu cầu nghỉ phép.
     *
     * Mục đích:
     * - Không đồng ý đơn xin nghỉ phép. Chuyển trạng thái đơn sang 'TuChoi', lưu lý do và gửi thông báo báo lại cho nhân viên.
     *
     * Input:
     * - yeuCauNghiID: ID đơn xin nghỉ
     * - quanLyID: ID quản lý xử lý
     * - ghiChuQuanLy: Lý do từ chối
     *
     * Output:
     * - boolean: true nếu thành công, false nếu thất bại
     *
     * Rủi ro:
     * - Thấp. Ném IllegalArgumentException nếu ID không hợp lệ hoặc đơn đã được duyệt trước đó.
     */
    public boolean rejectYeuCauNghi(int yeuCauNghiID, int quanLyID, String ghiChuQuanLy) {
        if (quanLyID <= 0) {
            throw new IllegalArgumentException("Quản lý ID không hợp lệ");
        }

        YeuCauNghi ycn = yeuCauNghiDAO.findById(yeuCauNghiID);
        if (ycn == null) {
            throw new IllegalArgumentException("Yêu cầu nghỉ không tồn tại");
        }

        if (!"ChoDuyet".equals(ycn.getTrangThai())) {
            throw new IllegalArgumentException("Yêu cầu đã được xử lý trước đó");
        }

        ycn.setTrangThai("TuChoi");
        ycn.setGhiChuQuanLy(ghiChuQuanLy);
        ycn.setNgayXuLy(java.time.LocalDateTime.now());
        ycn.setXuLyBy(quanLyID);

        boolean success = yeuCauNghiDAO.update(ycn);

        if (success) {
            // Gửi thông báo cho nhân viên
            String tieuDe = "Yêu cầu nghỉ của bạn đã bị từ chối";
            String noiDung = String.format("Yêu cầu nghỉ %s ngày %s đã bị quản lý từ chối. Lý do: %s",
                                          ycn.getLoaiNghi(), ycn.getNgayNghi().toString(),
                                          ghiChuQuanLy != null ? ghiChuQuanLy : "Không có lý do");
            ThongBao thongBao = new ThongBao(ycn.getAccountID(), tieuDe, noiDung, "YeuCauNghi");
            thongBaoDAO.insert(thongBao);
        }

        return success;
    }

    /**
     * Nghĩa tiếng Việt: Hủy yêu cầu nghỉ phép.
     *
     * Mục đích:
     * - Cho phép chính nhân viên đã tạo đơn tự hủy yêu cầu xin nghỉ (chỉ khả dụng khi đơn đang ở trạng thái 'ChoDuyet').
     *
     * Input:
     * - yeuCauNghiID: ID đơn xin nghỉ cần hủy
     * - accountID: ID tài khoản nhân viên thực hiện hủy
     *
     * Output:
     * - boolean: true nếu hủy thành công, false nếu thất bại
     *
     * Rủi ro:
     * - Thấp. Ném ngoại lệ nếu người hủy không phải chủ đơn hoặc đơn đã được xử lý.
     */
    public boolean cancelYeuCauNghi(int yeuCauNghiID, int accountID) {
        YeuCauNghi ycn = yeuCauNghiDAO.findById(yeuCauNghiID);
        if (ycn == null) {
            throw new IllegalArgumentException("Yêu cầu nghỉ không tồn tại");
        }

        if (ycn.getAccountID() != accountID) {
            throw new IllegalArgumentException("Bạn không có quyền hủy yêu cầu này");
        }

        if (!"ChoDuyet".equals(ycn.getTrangThai())) {
            throw new IllegalArgumentException("Chỉ có thể hủy yêu cầu đang chờ duyệt");
        }

        ycn.setTrangThai("DaHuy");
        return yeuCauNghiDAO.update(ycn);
    }

    /**
     * Kiểm tra xem một nhân viên đã có yêu cầu nghỉ vào ngày nhất định chưa
     */
    public boolean hasYeuCauNghiOnDate(int accountID, LocalDate ngayNghi) {
        return yeuCauNghiDAO.existsByAccountIDAndNgayNghi(accountID, ngayNghi);
    }
}
