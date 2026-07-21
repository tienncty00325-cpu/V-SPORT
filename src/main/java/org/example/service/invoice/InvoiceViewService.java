package org.example.service.invoice;

import org.example.dao.CoSoDAO;
import org.example.dao.HoaDonDAO;
import org.example.dao.LichDatSanDAO;
import org.example.dao.LoaiSanDAO;
import org.example.dao.SanDAO;
import org.example.dao.SanPhamDichVuDAO;
import org.example.dao.TaiKhoanDAO;
import org.example.dao.impl.CoSoDAOImpl;
import org.example.dao.impl.HoaDonDAOImpl;
import org.example.dao.impl.LichDatSanDAOImpl;
import org.example.dao.impl.LoaiSanDAOImpl;
import org.example.dao.impl.SanDAOImpl;
import org.example.dao.impl.SanPhamDichVuDAOImpl;
import org.example.dao.impl.TaiKhoanDAOImpl;
import org.example.model.ChiTietHoaDon;
import org.example.model.CoSo;
import org.example.model.HoaDon;
import org.example.model.Lichdatsan;
import org.example.model.LoaiSan;
import org.example.model.San;
import org.example.model.SanPham_DichVu;
import org.example.model.TaiKhoan;
import org.example.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;

/**
 * Nguồn sự thật duy nhất để đọc dữ liệu hiển thị của MỘT hóa đơn - dùng chung bởi
 * trang in (HoaDonPrintServlet), API chi tiết hóa đơn cho modal thanh toán, và bất kỳ
 * nơi nào khác cần xem lại hóa đơn. Chỉ đọc: không tạo hóa đơn, không thanh toán,
 * không cập nhật trạng thái, không tính lại tiền lịch sử bằng giá hiện tại.
 *
 * Ném NoSuchElementException khi không tìm thấy hóa đơn/dữ liệu liên quan (404),
 * SecurityException khi hóa đơn không thuộc cơ sở của user (403).
 */
public class InvoiceViewService {

    private static final DateTimeFormatter HM = DateTimeFormatter.ofPattern("HH:mm");
    private static final DateTimeFormatter DMY = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    private final HoaDonDAO hoaDonDAO = new HoaDonDAOImpl();
    private final LichDatSanDAO lichDatSanDAO = new LichDatSanDAOImpl();
    private final SanDAO sanDAO = new SanDAOImpl();
    private final LoaiSanDAO loaiSanDAO = new LoaiSanDAOImpl();
    private final CoSoDAO coSoDAO = new CoSoDAOImpl();
    private final TaiKhoanDAO taiKhoanDAO = new TaiKhoanDAOImpl();
    private final SanPhamDichVuDAO sanPhamDichVuDAO = new SanPhamDichVuDAOImpl();

    public InvoiceView load(int hoaDonId, TaiKhoan requestingUser, String contextPath) throws Exception {
        HoaDon hoaDon = hoaDonDAO.getHoaDonById(hoaDonId);
        if (hoaDon == null) {
            throw new NoSuchElementException("Không tìm thấy hóa đơn #" + hoaDonId + ".");
        }

        Lichdatsan lich = hoaDon.getDatSanId() != null ? lichDatSanDAO.getLichById(hoaDon.getDatSanId()) : null;
        if (lich == null) {
            throw new NoSuchElementException("Hóa đơn #" + hoaDonId + " không có dữ liệu ca chơi hợp lệ.");
        }

        San san = lich.getSanId() != null ? sanDAO.getSanById(lich.getSanId()) : null;
        if (san == null) {
            throw new NoSuchElementException("Không tìm thấy thông tin sân của hóa đơn #" + hoaDonId + ".");
        }
        LoaiSan loaiSan = loaiSanDAO.getLoaiSanById(san.getLoaiSanID());
        CoSo coSo = coSoDAO.getCoSoById(san.getCoSoID());

        if (san.getCoSoID() != requestingUser.getCoSoId()) {
            throw new SecurityException("Bạn không có quyền xem hóa đơn thuộc cơ sở khác.");
        }

        TaiKhoan khachHang = hoaDon.getAccountIdKhachHang() != null
                ? taiKhoanDAO.getAccountById(hoaDon.getAccountIdKhachHang()) : null;
        TaiKhoan nhanVien = hoaDon.getAccountIdNhanVien() != null
                ? taiKhoanDAO.getAccountById(hoaDon.getAccountIdNhanVien()) : null;

        List<ChiTietHoaDon> chiTietList = hoaDonDAO.getChiTietByHoaDonId(hoaDonId);
        List<InvoiceServiceItemView> services = new ArrayList<>();
        for (ChiTietHoaDon ct : chiTietList) {
            SanPham_DichVu sp = sanPhamDichVuDAO.findById(ct.getSanPhamID());
            String tenSp = sp != null ? sp.getTenSanPham() : ("Sản phẩm #" + ct.getSanPhamID() + " (đã ngừng kinh doanh)");
            services.add(new InvoiceServiceItemView(tenSp, ct.getSoLuong(), ct.getDonGiaTaiThoiDiemBan(), ct.getThanhTien()));
        }

        boolean isSplit = "SPLIT".equals(hoaDon.getLoaiHoaDon());
        List<Integer> splitHoaDonIds = (!isSplit) ? hoaDonDAO.getSplitHoaDonIdsByParent(hoaDonId) : List.of();

        // Thời gian bắt đầu/kết thúc thực tế (ưu tiên cột DATETIME2 mới, fallback cột TIME cũ), xử lý ca qua ngày.
        LocalDateTime startAt = lich.getActualStartAt();
        if (startAt == null) {
            startAt = LocalDateTime.of(lich.getNgayDat(),
                    lich.getActualStartTime() != null ? lich.getActualStartTime() : lich.getGioBatDau());
        }
        LocalDateTime endAt = lich.getActualEndAt();
        if (endAt == null) {
            endAt = LocalDateTime.of(lich.getNgayDat(),
                    lich.getActualEndTime() != null ? lich.getActualEndTime() : lich.getGioKetThuc());
            if (!endAt.isAfter(startAt)) endAt = endAt.plusDays(1);
        }
        boolean crossesMidnight = endAt.toLocalDate().isAfter(startAt.toLocalDate());

        long actualDurationMinutes = java.time.Duration.between(startAt, endAt).toMinutes();
        if (actualDurationMinutes < 0) actualDurationMinutes = 0;

        List<InvoiceCourtSegmentView> courtSegments = loadSegments(hoaDonId);
        long chargedDurationMinutes = courtSegments.isEmpty()
                ? actualDurationMinutes
                : courtSegments.stream().mapToLong(InvoiceCourtSegmentView::getDurationMinutes).sum();

        String startLabel = startAt.toLocalTime().format(HM) + " - " + startAt.toLocalDate().format(DMY);
        String endLabel = endAt.toLocalTime().format(HM) + " - " + endAt.toLocalDate().format(DMY);

        String isManagerPath = requestingUser.getRoleId() == 2 ? "/manager/hoa-don" : "/staff/checkin";

        String confirmedByName = null;
        String confirmedAtLabel = null;
        if (lich.getConfirmedBy() != null) {
            TaiKhoan confirmedByAccount = taiKhoanDAO.getAccountById(lich.getConfirmedBy());
            confirmedByName = confirmedByAccount != null ? confirmedByAccount.getFullName() : null;
        }
        if (lich.getConfirmedAt() != null) {
            confirmedAtLabel = lich.getConfirmedAt().format(HM) + " " + lich.getConfirmedAt().toLocalDate().format(DMY);
        }

        return new InvoiceView(
                hoaDonId,
                hoaDon.getLoaiHoaDon(),
                hoaDon.getParentHoaDonId(),
                hoaDon.getTrangThaiThanhToan(),
                hoaDon.getPhuongThucThanhToan(),
                hoaDon.getNgayLap(),
                coSo != null ? coSo.getTenCoSo() : "-",
                coSo != null ? coSo.getDiaChi() : null,
                coSo != null ? coSo.getSoDienThoai() : null,
                san.getTenSan(),
                loaiSan != null ? loaiSan.getTenLoai() : "-",
                khachHang != null && khachHang.getFullName() != null ? khachHang.getFullName() : "Khách vãng lai",
                khachHang != null ? khachHang.getPhoneNumber() : null,
                nhanVien != null ? nhanVien.getFullName() : "-",
                lich.getTimeMode(),
                startAt, endAt, startLabel, endLabel, crossesMidnight,
                actualDurationMinutes, chargedDurationMinutes,
                formatDuration(actualDurationMinutes), formatDuration(chargedDurationMinutes),
                courtSegments, services,
                hoaDon.getTongTienSan(), hoaDon.getTongTienDichVu(), hoaDon.getPhiGuiXe(), hoaDon.getGiamGia(),
                hoaDon.getTongThanhToan(),
                splitHoaDonIds,
                contextPath + isManagerPath,
                contextPath + "/staff/hoa-don/in?id=" + hoaDonId,
                lich.getTransactionCode(), confirmedByName, confirmedAtLabel
        );
    }

    private List<InvoiceCourtSegmentView> loadSegments(int hoaDonId) throws SQLException {
        List<InvoiceCourtSegmentView> rows = new ArrayList<>();
        String sql = "SELECT StartAt,EndAt,DurationMinutes,RateType,HourlyRate,Amount FROM CourtChargeSegment " +
                "WHERE HoaDonID=? ORDER BY SegmentOrder";
        try (Connection c = DBUtil.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, hoaDonId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String rateType = rs.getNString(4);
                    rows.add(new InvoiceCourtSegmentView(
                            rs.getTimestamp(1).toLocalDateTime(),
                            rs.getTimestamp(2).toLocalDateTime(),
                            rs.getLong(3),
                            rateType,
                            "WITH_LIGHT".equals(rateType) ? "Có đèn" : "Không đèn",
                            rs.getBigDecimal(5),
                            rs.getBigDecimal(6)));
                }
            }
        }
        return rows;
    }

    private static String formatDuration(long minutes) {
        long hh = minutes / 60;
        long mm = minutes % 60;
        return (hh > 0 ? hh + " giờ " : "") + mm + " phút";
    }
}
