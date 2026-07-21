package org.example.controller.customer;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonPrimitive;
import com.google.gson.JsonSerializer;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.dao.CoSoDAO;
import org.example.dao.LichDatSanDAO;
import org.example.dao.LoaiSanDAO;
import org.example.dao.SanDAO;
import org.example.dao.impl.CoSoDAOImpl;
import org.example.dao.impl.LichDatSanDAOImpl;
import org.example.dao.impl.LoaiSanDAOImpl;
import org.example.dao.impl.SanDAOImpl;
import org.example.model.CoSo;
import org.example.model.Lichdatsan;
import org.example.model.LoaiSan;
import org.example.model.MonTheThao;
import org.example.model.San;
import org.example.model.TaiKhoan;
import org.example.service.pricing.CourtPriceResult;
import org.example.service.pricing.CourtPriceSegment;
import org.example.service.pricing.CourtPricingService;
import org.example.util.Constants;
import org.example.util.DBUtil;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * VisualBookingServlet — trang "Đặt lịch trực quan" theo cơ sở + JSON API
 * (availability, price preview). Không thay đổi contract POST /customer/dat-san
 * đang tồn tại — trang này chỉ hiển thị timetable và gọi preview; khi khách
 * bấm "Tiếp theo" sẽ submit đúng form action /customer/dat-san hiện có.
 */
@WebServlet(urlPatterns = {
        "/customer/dat-lich-truc-quan",
        "/customer/dat-lich-truc-quan/xac-nhan",
        "/customer/api/timetable-availability",
        "/customer/api/timetable-price"
})
public class VisualBookingServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(VisualBookingServlet.class.getName());

    private static final LocalTime DEFAULT_OPEN = LocalTime.of(6, 0);
    private static final LocalTime DEFAULT_CLOSE = LocalTime.of(23, 0);
    private static final int SLOT_MINUTES = 30;

    private final SanDAO sanDAO = new SanDAOImpl();
    private final LoaiSanDAO loaiSanDAO = new LoaiSanDAOImpl();
    private final CoSoDAO coSoDAO = new CoSoDAOImpl();
    private final LichDatSanDAO lichDatSanDAO = new LichDatSanDAOImpl();
    private final CourtPricingService pricingService = new CourtPricingService();

    private static final Gson GSON = new GsonBuilder()
            .registerTypeAdapter(LocalDate.class, (JsonSerializer<LocalDate>) (s, t, c) -> new JsonPrimitive(s.toString()))
            .registerTypeAdapter(LocalTime.class, (JsonSerializer<LocalTime>) (s, t, c) -> new JsonPrimitive(s.toString().substring(0, 5)))
            .registerTypeAdapter(LocalDateTime.class, (JsonSerializer<LocalDateTime>) (s, t, c) -> new JsonPrimitive(s.toString()))
            .registerTypeAdapter(BigDecimal.class, (JsonSerializer<BigDecimal>) (s, t, c) -> new JsonPrimitive(s.toPlainString()))
            .create();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();
        if ("/customer/api/timetable-availability".equals(path)) {
            handleAvailabilityApi(req, resp);
        } else if ("/customer/api/timetable-price".equals(path)) {
            handlePriceApi(req, resp);
        } else {
            handleVisualPage(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String path = req.getServletPath();
        if ("/customer/api/timetable-price".equals(path)) {
            handlePriceApi(req, resp);
        } else if ("/customer/dat-lich-truc-quan/xac-nhan".equals(path)) {
            handleConfirmStep(req, resp);
        } else {
            resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        }
    }

    // =====================================================================
    // Bước "Xác nhận": server re-check availability + tính giá thật rồi forward
    // sang XacNhanDatSan.jsp. Booking THẬT chỉ được tạo khi khách bấm CTA ở trang
    // xác nhận (POST /customer/dat-san — contract cũ, DatSanServlet re-validate
    // lần cuối trong transaction với UPDLOCK).
    // =====================================================================
    private void handleConfirmStep(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession();
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        Integer sanId = parseIntSafe(req.getParameter("sanId"));
        LocalDate ngayDat = parseDateSafe(req.getParameter("ngayDat"), null);
        LocalTime gioBatDau = parseTimeSafe(req.getParameter("gioBatDau"));
        LocalTime gioKetThuc = parseTimeSafe(req.getParameter("gioKetThuc"));
        Integer coSoIdParam = parseIntSafe(req.getParameter("coSoId"));

        String backUrl = req.getContextPath() + "/customer/dat-lich-truc-quan";
        if (coSoIdParam != null) {
            backUrl += "?coSoId=" + coSoIdParam + (ngayDat != null ? "&ngay=" + ngayDat : "");
        }

        if (sanId == null || ngayDat == null || gioBatDau == null || gioKetThuc == null) {
            session.setAttribute("error", "Thiếu thông tin đặt sân. Vui lòng chọn lại khung giờ.");
            resp.sendRedirect(backUrl);
            return;
        }
        if (!gioKetThuc.isAfter(gioBatDau)) {
            session.setAttribute("error", "Giờ kết thúc phải sau giờ bắt đầu.");
            resp.sendRedirect(backUrl);
            return;
        }
        long durationMinutes = java.time.Duration.between(gioBatDau, gioKetThuc).toMinutes();
        if (durationMinutes < 30 || durationMinutes > 240) {
            session.setAttribute("error", "Thời lượng đặt sân phải từ 30 phút đến 4 giờ.");
            resp.sendRedirect(backUrl);
            return;
        }
        LocalDate today = LocalDate.now();
        if (ngayDat.isBefore(today)
                || (ngayDat.equals(today) && gioBatDau.isBefore(LocalTime.now()))) {
            session.setAttribute("error", "Không thể đặt khung giờ đã qua.");
            resp.sendRedirect(backUrl);
            return;
        }
        if (ngayDat.isAfter(today.plusDays(30))) {
            session.setAttribute("error", "Chỉ đặt được trong vòng 30 ngày tới.");
            resp.sendRedirect(backUrl);
            return;
        }

        San san = sanDAO.getSanById(sanId);
        if (san == null || san.isDeleted()) {
            session.setAttribute("error", "Sân không tồn tại.");
            resp.sendRedirect(backUrl);
            return;
        }
        if (!"Sẵn sàng".equals(san.getTrangThai())) {
            session.setAttribute("error", "Sân hiện không nhận đặt (trạng thái: " + san.getTrangThai() + ").");
            resp.sendRedirect(backUrl);
            return;
        }
        CoSo coSo = coSoDAO.getCoSoById(san.getCoSoID());
        if (coSo == null) {
            session.setAttribute("error", "Không tìm thấy cơ sở của sân.");
            resp.sendRedirect(backUrl);
            return;
        }
        // Chuẩn hoá backUrl theo cơ sở thật của sân (chống client gửi coSoId sai).
        backUrl = req.getContextPath() + "/customer/dat-lich-truc-quan?coSoId=" + coSo.getCoSoID() + "&ngay=" + ngayDat;

        LocalTime openTime = coSo.getGioMoCua() != null ? coSo.getGioMoCua() : DEFAULT_OPEN;
        LocalTime closeTime = coSo.getGioDongCua() != null ? coSo.getGioDongCua() : DEFAULT_CLOSE;
        if (gioBatDau.isBefore(openTime) || gioKetThuc.isAfter(closeTime)) {
            session.setAttribute("error", "Khung giờ nằm ngoài giờ hoạt động của cơ sở ("
                    + openTime.toString().substring(0, 5) + " - " + closeTime.toString().substring(0, 5) + ").");
            resp.sendRedirect(backUrl);
            return;
        }

        // Re-check availability: booking đang chặn + soft-hold của người khác.
        // Lỗi DB ở đây phải CHẶN luồng (fail-closed) — không được đi tiếp như thể sân trống.
        try {
            for (BookingSlot b : loadBlockingBookings(coSo.getCoSoID(), ngayDat)) {
                if (b.sanId == sanId && overlaps(gioBatDau, gioKetThuc, b.start, b.end)) {
                    session.setAttribute("error", "Khung giờ vừa được người khác đặt. Vui lòng chọn lại.");
                    resp.sendRedirect(backUrl);
                    return;
                }
            }
            for (BookingSlot h : loadActiveSoftHolds(coSo.getCoSoID(), ngayDat, user.getAccountId())) {
                if (h.sanId == sanId && overlaps(gioBatDau, gioKetThuc, h.start, h.end)) {
                    session.setAttribute("error", "Khung giờ đang được người khác giữ chỗ tạm thời. Vui lòng thử lại sau ít phút.");
                    resp.sendRedirect(backUrl);
                    return;
                }
            }
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Confirm-step availability re-check failed sanId=" + sanId, e);
            session.setAttribute("error", "Không thể kiểm tra lịch sân lúc này. Vui lòng thử lại.");
            resp.sendRedirect(backUrl);
            return;
        }

        LoaiSan loai = loaiSanDAO.getLoaiSanById(san.getLoaiSanID());
        if (loai == null) {
            session.setAttribute("error", "Sân chưa được cấu hình giá. Vui lòng chọn sân khác.");
            resp.sendRedirect(backUrl);
            return;
        }

        CourtPriceResult price;
        try {
            price = pricingService.calculate(
                    LocalDateTime.of(ngayDat, gioBatDau), LocalDateTime.of(ngayDat, gioKetThuc),
                    loai.getGioBatDauLenDen(), loai.getGioKetThucLenDen(),
                    BigDecimal.valueOf(loai.getGiaKhongDen()), BigDecimal.valueOf(loai.getGiaCoDen()));
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "Confirm-step pricing failed sanId=" + sanId, e);
            session.setAttribute("error", "Không thể tính giá lúc này. Vui lòng thử lại.");
            resp.sendRedirect(backUrl);
            return;
        }

        String tenMon = null;
        List<MonTheThao> dsMon = loaiSanDAO.getAllMonTheThao();
        if (dsMon != null) {
            for (MonTheThao m : dsMon) {
                if (m.getMonTheThaoID() == loai.getMonTheThaoID()) { tenMon = m.getTenMon(); break; }
            }
        }

        // Segments cho JSP (EL không đọc được record accessor → chuyển sang Map).
        List<Map<String, Object>> segments = new ArrayList<>();
        for (CourtPriceSegment seg : price.segments()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("start", seg.segmentStart().toLocalTime().toString().substring(0, 5));
            m.put("end", seg.segmentEnd().toLocalTime().toString().substring(0, 5));
            m.put("minutes", seg.durationMinutes());
            m.put("withLight", seg.rateType() == org.example.service.pricing.CourtRateType.WITH_LIGHT);
            m.put("hourlyRate", seg.hourlyRate());
            m.put("amount", seg.amount());
            segments.add(m);
        }

        req.setAttribute("coSo", coSo);
        req.setAttribute("san", san);
        req.setAttribute("loai", loai);
        req.setAttribute("tenMon", tenMon);
        req.setAttribute("ngayDat", ngayDat.toString());
        req.setAttribute("gioBatDau", gioBatDau.toString().substring(0, 5));
        req.setAttribute("gioKetThuc", gioKetThuc.toString().substring(0, 5));
        req.setAttribute("durationMinutes", durationMinutes);
        req.setAttribute("totalAmount", price.totalCourtAmount());
        req.setAttribute("amountWithoutLight", price.amountWithoutLight());
        req.setAttribute("amountWithLight", price.amountWithLight());
        req.setAttribute("minutesWithLight", price.minutesWithLight());
        req.setAttribute("priceSegments", segments);
        req.setAttribute("backUrl", backUrl);
        req.setAttribute("lateCancelHours", Constants.LATE_CANCEL_HOURS);
        req.setAttribute("bookingHoldMinutes", Constants.BOOKING_HOLD_MINUTES);

        req.getRequestDispatcher("/customer/XacNhanDatSan.jsp").forward(req, resp);
    }

    // =====================================================================
    // Trang "Đặt lịch trực quan"
    // =====================================================================
    private void handleVisualPage(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession();
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");

        // Cho phép cả khách chưa đăng nhập xem giao diện; khi bấm "Tiếp theo" servlet
        // POST /customer/dat-san sẽ tự redirect sang trang đăng nhập.

        Integer coSoId = parseIntSafe(req.getParameter("coSoId"));
        LocalDate initialDate = parseDateSafe(req.getParameter("ngay"), LocalDate.now());
        Integer preSanId = parseIntSafe(req.getParameter("sanId"));
        Integer sportId = parseIntSafe(req.getParameter("sportId"));

        List<CoSo> dsCoSo = coSoDAO.getAllCoSo();
        if (dsCoSo == null) dsCoSo = new ArrayList<>();
        // Chọn cơ sở mặc định: coSoId trong request, ngược lại lấy cơ sở đầu tiên đang hoạt động.
        CoSo coSo = null;
        if (coSoId != null) {
            for (CoSo cs : dsCoSo) {
                if (cs.getCoSoID() == coSoId) { coSo = cs; break; }
            }
        }
        if (coSo == null && !dsCoSo.isEmpty()) {
            coSo = dsCoSo.get(0);
            coSoId = coSo.getCoSoID();
        }

        if (coSo == null) {
            req.setAttribute("emptyState", "no_facility");
            req.setAttribute("dsCoSo", dsCoSo);
            req.setAttribute("initialDate", initialDate);
            req.getRequestDispatcher("/customer/DatLichTrucQuan.jsp").forward(req, resp);
            return;
        }

        List<San> dsSan = sanDAO.getSansByCoSo(coSo.getCoSoID());
        if (dsSan == null) dsSan = new ArrayList<>();
        // Loại bỏ sân bị soft delete và sắp xếp theo tên (Sân 1, Sân 2, ...).
        dsSan.removeIf(s -> s.isDeleted());
        dsSan.sort(Comparator.comparing(San::getTenSan, Comparator.nullsLast(String::compareToIgnoreCase)));

        List<LoaiSan> dsLoai = loaiSanDAO.getAllLoaiSan();
        List<MonTheThao> dsMon = loaiSanDAO.getAllMonTheThao();

        req.setAttribute("coSo", coSo);
        req.setAttribute("dsCoSo", dsCoSo);
        req.setAttribute("dsSan", dsSan);
        req.setAttribute("dsLoai", dsLoai != null ? dsLoai : new ArrayList<>());
        req.setAttribute("dsMon", dsMon != null ? dsMon : new ArrayList<>());
        req.setAttribute("initialDate", initialDate);
        req.setAttribute("preSanId", preSanId);
        req.setAttribute("sportId", sportId);
        req.setAttribute("slotMinutes", SLOT_MINUTES);
        req.setAttribute("minDurationMinutes", 30);
        req.setAttribute("maxDurationMinutes", 240);
        req.setAttribute("maxDaysAhead", 30);
        req.setAttribute("softHoldMinutes", Constants.SOFT_HOLD_TIMEOUT_MINUTES);
        req.setAttribute("bookingHoldMinutes", Constants.BOOKING_HOLD_MINUTES);
        req.setAttribute("maxBookingsPerDay", 3);
        req.setAttribute("openTime", coSo.getGioMoCua() != null ? coSo.getGioMoCua() : DEFAULT_OPEN);
        req.setAttribute("closeTime", coSo.getGioDongCua() != null ? coSo.getGioDongCua() : DEFAULT_CLOSE);

        req.getRequestDispatcher("/customer/DatLichTrucQuan.jsp").forward(req, resp);
    }

    // =====================================================================
    // JSON API: availability theo cơ sở + ngày
    // Trả về: cơ sở, giờ mở/đóng, danh sách sân + slot 30 phút với trạng thái,
    // giá tham chiếu theo loại sân.
    // =====================================================================
    private void handleAvailabilityApi(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");

        Integer coSoId = parseIntSafe(req.getParameter("coSoId"));
        LocalDate date = parseDateSafe(req.getParameter("date"), null);
        if (coSoId == null || date == null) {
            writeJson(resp, HttpServletResponse.SC_BAD_REQUEST,
                    Map.of("success", false, "error", "Thiếu tham số coSoId hoặc date."));
            return;
        }
        // Không cho phép truy vấn ngày quá khứ (ngăn brute-force lịch cũ).
        if (date.isBefore(LocalDate.now().minusDays(1))) {
            writeJson(resp, HttpServletResponse.SC_BAD_REQUEST,
                    Map.of("success", false, "error", "Ngày không hợp lệ."));
            return;
        }

        CoSo coSo = coSoDAO.getCoSoById(coSoId);
        if (coSo == null) {
            writeJson(resp, HttpServletResponse.SC_NOT_FOUND,
                    Map.of("success", false, "error", "Không tìm thấy cơ sở."));
            return;
        }
        LocalTime openTime = coSo.getGioMoCua() != null ? coSo.getGioMoCua() : DEFAULT_OPEN;
        LocalTime closeTime = coSo.getGioDongCua() != null ? coSo.getGioDongCua() : DEFAULT_CLOSE;

        List<San> dsSan = sanDAO.getSansByCoSo(coSoId);
        if (dsSan == null) dsSan = new ArrayList<>();
        dsSan.removeIf(San::isDeleted);
        dsSan.sort(Comparator.comparing(San::getTenSan, Comparator.nullsLast(String::compareToIgnoreCase)));

        List<LoaiSan> dsLoai = loaiSanDAO.getAllLoaiSan();
        Map<Integer, LoaiSan> loaiById = new HashMap<>();
        if (dsLoai != null) {
            for (LoaiSan l : dsLoai) loaiById.put(l.getLoaiSanID(), l);
        }

        // Lấy các booking đang chặn slot + soft-hold. Nếu query lỗi (vd: schema thiếu
        // cột HoldExpiresAt do chưa chạy migration) → trả 500 để UI hiện error state,
        // TUYỆT ĐỐI không render bảng toàn ô trống giả.
        List<BookingSlot> bookings;
        List<BookingSlot> softHolds;
        HttpSession session = req.getSession(false);
        Integer currentAccountId = session != null && session.getAttribute("user") != null
                ? ((TaiKhoan) session.getAttribute("user")).getAccountId() : null;
        try {
            bookings = loadBlockingBookings(coSoId, date);
            softHolds = loadActiveSoftHolds(coSoId, date, currentAccountId);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Availability query failed for coSoId=" + coSoId + " date=" + date
                    + " — kiểm tra schema LichDatSan/SoftHold (sql/migration_reservation_hold.sql đã chạy chưa?)", e);
            writeJson(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    Map.of("success", false, "error", "Không thể tải dữ liệu lịch sân. Vui lòng thử lại sau."));
            return;
        }

        LocalTime now = LocalTime.now();
        boolean isToday = date.equals(LocalDate.now());

        List<Map<String, Object>> courts = new ArrayList<>();
        for (San s : dsSan) {
            Map<String, Object> courtNode = new LinkedHashMap<>();
            courtNode.put("sanId", s.getSanID());
            courtNode.put("tenSan", s.getTenSan());
            courtNode.put("trangThai", s.getTrangThai());
            courtNode.put("loaiSanId", s.getLoaiSanID());

            LoaiSan loai = loaiById.get(s.getLoaiSanID());
            if (loai != null) {
                courtNode.put("tenLoai", loai.getTenLoai());
                courtNode.put("giaKhongDen", loai.getGiaKhongDen());
                courtNode.put("giaCoDen", loai.getGiaCoDen());
                courtNode.put("gioLenDen", loai.getGioBatDauLenDen() != null
                        ? loai.getGioBatDauLenDen().toString().substring(0, 5) : null);
                courtNode.put("gioTatDen", loai.getGioKetThucLenDen() != null
                        ? loai.getGioKetThucLenDen().toString().substring(0, 5) : null);
                courtNode.put("monTheThaoId", loai.getMonTheThaoID());
            }

            List<Map<String, Object>> slots = new ArrayList<>();
            for (LocalTime t = openTime; t.isBefore(closeTime); t = t.plusMinutes(SLOT_MINUTES)) {
                LocalTime slotEnd = t.plusMinutes(SLOT_MINUTES);
                if (slotEnd.isAfter(closeTime)) break;

                String status = "AVAILABLE";
                String reason = null;

                boolean courtInactive = !"Sẵn sàng".equals(s.getTrangThai());
                if (courtInactive) {
                    status = "LOCKED";
                    reason = "Sân " + (s.getTrangThai() != null ? s.getTrangThai().toLowerCase() : "không hoạt động");
                }

                if ("AVAILABLE".equals(status) && isToday && slotEnd.isBefore(now.plusMinutes(1))) {
                    status = "PAST";
                    reason = "Khung giờ đã qua";
                }

                Integer holdSelfDatSanId = null;
                if ("AVAILABLE".equals(status)) {
                    for (BookingSlot b : bookings) {
                        if (b.sanId == s.getSanID() && overlaps(t, slotEnd, b.start, b.end)) {
                            boolean isPaymentHold = Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN.equals(b.trangThai);
                            if (isPaymentHold) {
                                // Đơn PayOS chưa thanh toán: KHÔNG phải "Đã đặt". Là giữ chỗ tạm.
                                if (currentAccountId != null && currentAccountId.equals(b.accountId)) {
                                    // Của chính khách đang xem → cho phép bấm để tiếp tục thanh toán.
                                    status = "HOLD_SELF";
                                    reason = "Đơn của bạn đang chờ thanh toán";
                                    holdSelfDatSanId = b.datSanId;
                                } else {
                                    // Của người khác → chỉ hiện "đang được giữ", không lộ thông tin người đặt.
                                    status = "HOLD";
                                    reason = "Khung giờ đang được giữ";
                                }
                            } else {
                                status = "BOOKED";
                                reason = "Đã có người đặt";
                            }
                            break;
                        }
                    }
                }
                if ("AVAILABLE".equals(status)) {
                    for (BookingSlot h : softHolds) {
                        if (h.sanId == s.getSanID() && overlaps(t, slotEnd, h.start, h.end)) {
                            status = "HOLD";
                            reason = "Đang có người khác giữ chỗ tạm thời";
                            break;
                        }
                    }
                }

                Map<String, Object> slot = new LinkedHashMap<>();
                slot.put("start", t.toString().substring(0, 5));
                slot.put("end", slotEnd.toString().substring(0, 5));
                slot.put("startMinute", t.getHour() * 60 + t.getMinute());
                slot.put("status", status);
                if (reason != null) slot.put("reason", reason);
                if (holdSelfDatSanId != null) slot.put("datSanId", holdSelfDatSanId);
                slots.add(slot);
            }
            courtNode.put("slots", slots);
            courts.add(courtNode);
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("success", true);
        data.put("coSoId", coSoId);
        data.put("tenCoSo", coSo.getTenCoSo());
        data.put("date", date.toString());
        data.put("openTime", openTime.toString().substring(0, 5));
        data.put("closeTime", closeTime.toString().substring(0, 5));
        data.put("slotMinutes", SLOT_MINUTES);
        data.put("courts", courts);
        data.put("nowMinutes", isToday ? (now.getHour() * 60 + now.getMinute()) : -1);

        writeJson(resp, HttpServletResponse.SC_OK, data);
    }

    // =====================================================================
    // JSON API: preview giá — dùng CourtPricingService làm nguồn sự thật duy nhất.
    // =====================================================================
    private void handlePriceApi(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        Integer sanId = parseIntSafe(req.getParameter("sanId"));
        LocalDate date = parseDateSafe(req.getParameter("date"), null);
        LocalTime start = parseTimeSafe(req.getParameter("start"));
        LocalTime end = parseTimeSafe(req.getParameter("end"));

        if (sanId == null || date == null || start == null || end == null) {
            writeJson(resp, HttpServletResponse.SC_BAD_REQUEST,
                    Map.of("success", false, "error", "Thiếu tham số."));
            return;
        }
        if (!end.isAfter(start)) {
            writeJson(resp, HttpServletResponse.SC_BAD_REQUEST,
                    Map.of("success", false, "error", "Giờ kết thúc phải sau giờ bắt đầu."));
            return;
        }

        long minutes = java.time.Duration.between(start, end).toMinutes();
        if (minutes < 30) {
            writeJson(resp, HttpServletResponse.SC_BAD_REQUEST,
                    Map.of("success", false, "error", "Thời lượng tối thiểu là 30 phút."));
            return;
        }
        if (minutes > 240) {
            writeJson(resp, HttpServletResponse.SC_BAD_REQUEST,
                    Map.of("success", false, "error", "Thời lượng tối đa là 4 giờ (240 phút)."));
            return;
        }

        San san = sanDAO.getSanById(sanId);
        if (san == null) {
            writeJson(resp, HttpServletResponse.SC_NOT_FOUND,
                    Map.of("success", false, "error", "Không tìm thấy sân."));
            return;
        }
        LoaiSan loai = loaiSanDAO.getLoaiSanById(san.getLoaiSanID());
        if (loai == null) {
            writeJson(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    Map.of("success", false, "error", "Sân chưa được cấu hình loại/giá."));
            return;
        }

        BigDecimal rateWithout = BigDecimal.valueOf(loai.getGiaKhongDen());
        BigDecimal rateWith = BigDecimal.valueOf(loai.getGiaCoDen());
        LocalTime lightStart = loai.getGioBatDauLenDen();
        LocalTime lightEnd = loai.getGioKetThucLenDen();

        try {
            CourtPriceResult result = pricingService.calculate(
                    LocalDateTime.of(date, start), LocalDateTime.of(date, end),
                    lightStart, lightEnd, rateWithout, rateWith);

            Map<String, Object> data = new LinkedHashMap<>();
            data.put("success", true);
            data.put("sanId", sanId);
            data.put("tenSan", san.getTenSan());
            data.put("tenLoai", loai.getTenLoai());
            data.put("date", date.toString());
            data.put("start", start.toString().substring(0, 5));
            data.put("end", end.toString().substring(0, 5));
            data.put("totalMinutes", result.totalMinutes());
            data.put("minutesWithoutLight", result.minutesWithoutLight());
            data.put("minutesWithLight", result.minutesWithLight());
            data.put("amountWithoutLight", result.amountWithoutLight());
            data.put("amountWithLight", result.amountWithLight());
            data.put("totalAmount", result.totalCourtAmount());
            data.put("rateWithoutLight", rateWithout);
            data.put("rateWithLight", rateWith);
            data.put("hasLightSurcharge", result.minutesWithLight() > 0);

            List<Map<String, Object>> segments = new ArrayList<>();
            for (CourtPriceSegment seg : result.segments()) {
                Map<String, Object> segMap = new LinkedHashMap<>();
                segMap.put("start", seg.segmentStart().toLocalTime().toString().substring(0, 5));
                segMap.put("end", seg.segmentEnd().toLocalTime().toString().substring(0, 5));
                segMap.put("minutes", seg.durationMinutes());
                segMap.put("rateType", seg.rateType().name());
                segMap.put("hourlyRate", seg.hourlyRate());
                segMap.put("amount", seg.amount());
                segments.add(segMap);
            }
            data.put("segments", segments);

            writeJson(resp, HttpServletResponse.SC_OK, data);
        } catch (IllegalArgumentException iae) {
            writeJson(resp, HttpServletResponse.SC_BAD_REQUEST,
                    Map.of("success", false, "error", iae.getMessage()));
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "Lỗi tính giá sân sanId=" + sanId, e);
            writeJson(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    Map.of("success", false, "error", "Không thể tính giá lúc này."));
        }
    }

    // =====================================================================
    // Helpers
    // =====================================================================

    private static boolean overlaps(LocalTime aStart, LocalTime aEnd, LocalTime bStart, LocalTime bEnd) {
        return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
    }

    private static class BookingSlot {
        final int sanId;
        final LocalTime start;
        final LocalTime end;
        final String trangThai;
        final Integer accountId;   // chủ đơn (để phân biệt hold của chính khách đang xem)
        final int datSanId;        // để build link "Tiếp tục thanh toán" cho hold của chính mình
        BookingSlot(int sanId, LocalTime start, LocalTime end, String trangThai) {
            this(sanId, start, end, trangThai, null, 0);
        }
        BookingSlot(int sanId, LocalTime start, LocalTime end, String trangThai, Integer accountId, int datSanId) {
            this.sanId = sanId; this.start = start; this.end = end; this.trangThai = trangThai;
            this.accountId = accountId; this.datSanId = datSanId;
        }
    }

    /**
     * Đọc các booking đang chặn slot cho ngày+cơ sở (Chờ xác nhận / Đã xác nhận / Đang sử dụng
     * / Chờ thanh toán còn hạn giữ chỗ). Không đọc booking đã huỷ hoặc quá hạn.
     */
    /**
     * QUAN TRỌNG: method này KHÔNG được nuốt SQLException. Trước đây lỗi DB
     * (vd: thiếu cột HoldExpiresAt vì chưa chạy sql/migration_reservation_hold.sql)
     * bị catch âm thầm → trả list rỗng → toàn bộ timetable render thành "Trống"
     * dù DB có booking. Giờ lỗi được ném lên để caller trả error state thật.
     */
    private List<BookingSlot> loadBlockingBookings(int coSoId, LocalDate date) throws SQLException {
        List<BookingSlot> result = new ArrayList<>();
        String sql = "SELECT l.DatSanID, l.AccountID, l.SanID, l.GioBatDau, l.GioKetThuc, l.TrangThai " +
                "FROM LichDatSan l JOIN San s ON l.SanID = s.SanID " +
                "WHERE s.CoSoID = ? AND l.NgayDat = ? AND l.IsDeleted = 0 " +
                "AND (l.TrangThai IN (N'" + Constants.TRANG_THAI_DAT_SAN_CHO_XAC_NHAN + "', " +
                "N'" + Constants.TRANG_THAI_DAT_SAN_DA_XAC_NHAN + "', " +
                "N'" + Constants.TRANG_THAI_DAT_SAN_DANG_SU_DUNG + "') " +
                "OR (l.TrangThai = N'" + Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN + "' AND l.HoldExpiresAt > SYSUTCDATETIME()))";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, coSoId);
            ps.setDate(2, java.sql.Date.valueOf(date));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int acc = rs.getInt("AccountID");
                    result.add(new BookingSlot(
                            rs.getInt("SanID"),
                            rs.getTime("GioBatDau").toLocalTime(),
                            rs.getTime("GioKetThuc").toLocalTime(),
                            rs.getString("TrangThai"),
                            rs.wasNull() ? null : acc,
                            rs.getInt("DatSanID")));
                }
            }
        }
        return result;
    }

    /**
     * Đọc SoftHold đang active (chưa hết hạn) từ tài khoản khác (bỏ qua self-hold).
     */
    /** Như loadBlockingBookings: lỗi DB phải nổi lên, không âm thầm trả rỗng. */
    private List<BookingSlot> loadActiveSoftHolds(int coSoId, LocalDate date, Integer excludeAccountId) throws SQLException {
        List<BookingSlot> result = new ArrayList<>();
        String sql = "SELECT h.SanID, h.GioBatDau, h.GioKetThuc " +
                "FROM SoftHold h JOIN San s ON h.SanID = s.SanID " +
                "WHERE s.CoSoID = ? AND h.NgayDat = ? " +
                "AND (? IS NULL OR h.AccountID <> ?) " +
                "AND DATEDIFF(minute, h.CreatedTime, GETDATE()) <= " + Constants.SOFT_HOLD_TIMEOUT_MINUTES;
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, coSoId);
            ps.setDate(2, java.sql.Date.valueOf(date));
            if (excludeAccountId == null) {
                ps.setNull(3, java.sql.Types.INTEGER);
                ps.setNull(4, java.sql.Types.INTEGER);
            } else {
                ps.setInt(3, excludeAccountId);
                ps.setInt(4, excludeAccountId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(new BookingSlot(
                            rs.getInt("SanID"),
                            rs.getTime("GioBatDau").toLocalTime(),
                            rs.getTime("GioKetThuc").toLocalTime(),
                            "HOLD"));
                }
            }
        }
        return result;
    }

    private static Integer parseIntSafe(String s) {
        if (s == null || s.isBlank()) return null;
        try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return null; }
    }

    private static LocalDate parseDateSafe(String s, LocalDate fallback) {
        if (s == null || s.isBlank()) return fallback;
        try { return LocalDate.parse(s.trim()); } catch (Exception e) { return fallback; }
    }

    private static LocalTime parseTimeSafe(String s) {
        if (s == null || s.isBlank()) return null;
        String v = s.trim();
        if (v.length() == 5) v = v + ":00";
        try { return LocalTime.parse(v); } catch (Exception e) { return null; }
    }

    private static void writeJson(HttpServletResponse resp, int status, Object payload) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json;charset=UTF-8");
        try (PrintWriter w = resp.getWriter()) {
            w.write(GSON.toJson(payload));
        }
    }
}
