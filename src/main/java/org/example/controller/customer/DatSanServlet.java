package org.example.controller.customer;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.dao.LichDatSanDAO;
import org.example.dao.LoaiSanDAO;
import org.example.dao.SanDAO;
import org.example.dao.CustomerReputationHistoryDAO;
import org.example.dao.impl.LichDatSanDAOImpl;
import org.example.dao.impl.LoaiSanDAOImpl;
import org.example.dao.impl.SanDAOImpl;
import org.example.dao.impl.CustomerReputationHistoryDAOImpl;
import org.example.model.LoaiSan;
import org.example.model.MonTheThao;
import org.example.model.Lichdatsan;
import org.example.model.TaiKhoan;
import org.example.model.San;
import org.example.model.CustomerReputationHistory;
import org.example.util.Constants;
import org.example.util.DBUtil;
import org.example.dto.payment.PayOSCheckoutSession;
import org.example.dto.payment.PayosQrData;
import org.example.dto.payment.PayOSCredentials;
import org.example.service.PayOSConfigurationService;
import org.example.service.payos.PayOSClientFactory;
import vn.payos.PayOS;
import vn.payos.exception.APIException;
import vn.payos.exception.ConnectionException;
import vn.payos.exception.ConnectionTimeoutException;
import vn.payos.model.v2.paymentRequests.CreatePaymentLinkRequest;
import vn.payos.model.v2.paymentRequests.CreatePaymentLinkResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * ===============================================================
 * DatSanServlet - Servlet xử lý toàn bộ luồng đặt sân của khách hàng
 * ===============================================================
 *
 * LUỒNG HOẠT ĐỘNG CHÍNH:
 * GET /customer/dat-san → Hiển thị trang đặt sân (Cho phép khách không đăng
 * nhập xem)
 * GET /customer/lich-su-dat-san → Xem lịch sử đặt sân (Yêu cầu đăng nhập)
 * POST /customer/dat-san → Thực hiện đặt sân (Yêu cầu đăng nhập)
 * POST /customer/huy-dat-san → Hủy lịch đặt sân (Yêu cầu đăng nhập)
 *
 * CÁC CƠ CHẾ BẢO VỆ:
 * 1. Kiểm tra ngày/giờ trong quá khứ
 * 2. Kiểm tra giờ mở/đóng cửa Cơ Sở
 * 3. Kiểm tra trạng thái sân (chỉ chấp nhận 'Sẵn sàng')
 * 4. Kiểm tra trùng lịch với row-level lock (UPDLOCK, ROWLOCK)
 * 5. Retry loop tự phục hồi khi xảy ra deadlock (SQL Error 1205)
 *
 * @author DatN (Senior refactor)
 * @version 2.0
 */
@WebServlet(urlPatterns = { "/customer/dat-san", "/customer/dat_san", "/customer/lich-su-dat-san", "/customer/huy-dat-san", "/customer/dat-dich-vu", "/customer/chi-tiet-san", "/customer/payos-return", "/customer/payos-cancel", "/customer/payos-status", "/customer/payos-retry", "/customer/payos-pay-counter" })
public class DatSanServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(DatSanServlet.class.getName());

    private static final com.google.gson.Gson gson = new com.google.gson.GsonBuilder()
            .registerTypeAdapter(java.time.LocalDate.class, (com.google.gson.JsonSerializer<java.time.LocalDate>)
                    (src, typeOfSrc, context) -> new com.google.gson.JsonPrimitive(src.toString()))
            .registerTypeAdapter(java.time.LocalTime.class, (com.google.gson.JsonSerializer<java.time.LocalTime>)
                    (src, typeOfSrc, context) -> new com.google.gson.JsonPrimitive(src.toString()))
            .registerTypeAdapter(java.time.LocalDateTime.class, (com.google.gson.JsonSerializer<java.time.LocalDateTime>)
                    (src, typeOfSrc, context) -> new com.google.gson.JsonPrimitive(src.toString()))
            .create();

    private final org.example.dao.SoftHoldDAO softHoldDAO = new org.example.dao.impl.SoftHoldDAOImpl();

    /** Số lần thử lại tối đa khi xảy ra deadlock (SQL Error 1205) */
    private static final int MAX_DEADLOCK_RETRIES = 3;

    /** SQL Server error code cho deadlock */
    private static final int SQL_DEADLOCK_ERROR_CODE = 1205;

    /** Giờ mở cửa mặc định nếu Cơ Sở không cấu hình */
    private static final LocalTime DEFAULT_OPEN_TIME = LocalTime.of(6, 0);

    /** Giờ đóng cửa mặc định nếu Cơ Sở không cấu hình */
    private static final LocalTime DEFAULT_CLOSE_TIME = LocalTime.of(23, 0);

    private final LichDatSanDAO lichDatSanDAO = new LichDatSanDAOImpl();
    private final SanDAO sanDAO = new SanDAOImpl();
    private final LoaiSanDAO loaiSanDAO = new LoaiSanDAOImpl();
    private final org.example.dao.CoSoDAO coSoDAO = new org.example.dao.impl.CoSoDAOImpl();
    private final org.example.dao.LichDatSanDichVuDAO lichDatSanDichVuDAO = new org.example.dao.impl.LichDatSanDichVuDAOImpl();
    private final CustomerReputationHistoryDAO reputationHistoryDAO = new CustomerReputationHistoryDAOImpl();
    private final org.example.service.booking.BookingCancellationService bookingCancellationService =
            new org.example.service.booking.BookingCancellationService();

    // =========================================================================
    // PHẦN 1: XỬ LÝ GET - Hiển thị trang
    // =========================================================================

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();
        HttpSession session = req.getSession();
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");

        // Khách chưa đăng nhập vẫn được xem trang đặt sân để khám phá,
        // nhưng không thể submit form (nút sẽ chuyển thành "Đăng nhập")
        // Chỉ chặn những trang yêu cầu đăng nhập bắt buộc
        if (user == null && !isBookingPage(path)) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        if (path.equals("/customer/chi-tiet-san")) {
            handleGetChiTietSan(req, resp);
        } else if (isBookingPage(path)) {
            resp.sendRedirect(req.getContextPath() + "/customer/tim-kiem");
        } else if (path.equals("/customer/lich-su-dat-san")) {
            if (user == null) {
                resp.sendRedirect(req.getContextPath() + "/dangnhap");
                return;
            }
            loadHistoryPage(req, resp, user);
        } else if (path.equals("/customer/dat-dich-vu")) {
            handleGetDichVu(req, resp, user);
        } else if (path.equals("/customer/payos-return")) {
            handlePayOSReturn(req, resp, session);
        } else if (path.equals("/customer/payos-cancel")) {
            handlePayOSCancel(req, resp, session, user);
        } else if (path.equals("/customer/payos-status")) {
            handlePayOSStatus(req, resp, user);
        }
    }

    /**
     * Tải dữ liệu và chuyển tiếp đến trang DatSan.jsp.
     * Load: danh sách sân, Cơ Sở, môn thể thao, loại sân, lịch đặt hiện tại.
     */
    private void loadBookingPage(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long t0 = System.currentTimeMillis();

        List<org.example.model.CoSo> dsCoSo = coSoDAO.getAllCoSo();
        List<San> dsSan = new java.util.ArrayList<>();
        List<MonTheThao> dsMon = new java.util.ArrayList<>();
        List<LoaiSan> dsLoai = new java.util.ArrayList<>();

        try {
            long tSan0 = System.currentTimeMillis();
            dsSan = sanDAO.getAllSan();
            dsMon = loaiSanDAO.getAllMonTheThao();
            dsLoai = loaiSanDAO.getAllLoaiSan();
            LOGGER.info(String.format("loadBookingPage: tải danh sách sân/loại=%dms, count=%d", System.currentTimeMillis() - tSan0, dsSan.size()));
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "Lỗi khi tải dữ liệu trang đặt sân", e);
        }

        // Lấy toàn bộ lịch đặt hiện tại để hiển thị timetable xung đột trên frontend
        long tAll0 = System.currentTimeMillis();
        List<Lichdatsan> activeBookings = lichDatSanDAO.getAllLichDatSan();
        LOGGER.info(String.format("loadBookingPage: getAllLichDatSan=%dms, count=%d",
                System.currentTimeMillis() - tAll0, activeBookings != null ? activeBookings.size() : 0));
        if (activeBookings != null) {
            activeBookings.removeIf(b -> "Chờ thanh toán".equals(b.getTrangThai()) &&
                    b.getCreatedTime() != null &&
                    b.getCreatedTime().plusMinutes(org.example.util.Constants.PENDING_PAYMENT_TIMEOUT_MINUTES).isBefore(LocalDateTime.now()));
        }

        // Lấy lịch sử đặt sân của cá nhân khách hàng nếu đã đăng nhập
        HttpSession session = req.getSession();
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");
        if (user != null) {
            try {
                long tUser0 = System.currentTimeMillis();
                List<Lichdatsan> dsLich = lichDatSanDAO.getLichByAccountId(user.getAccountId());
                LOGGER.info(String.format("loadBookingPage: getLichByAccountId(accountId=%d)=%dms, count=%d",
                        user.getAccountId(), System.currentTimeMillis() - tUser0, dsLich != null ? dsLich.size() : 0));
                req.setAttribute("dsLich", dsLich);
            } catch (Exception e) {
                LOGGER.log(Level.WARNING, "Lỗi khi tải lịch sử đặt sân cho khách hàng", e);
            }
        }

        req.setAttribute("dsSan", dsSan);
        req.setAttribute("dsCoSo", dsCoSo);
        req.setAttribute("dsMon", dsMon);
        req.setAttribute("dsLoai", dsLoai);
        req.setAttribute("activeBookings", activeBookings);

        LOGGER.info(String.format("loadBookingPage: tổng=%dms", System.currentTimeMillis() - t0));
        req.getRequestDispatcher("/customer/DatSan.jsp").forward(req, resp);
    }

    /**
     * Tải lịch sử đặt sân cá nhân và chuyển tiếp đến LichSuDatSan.jsp.
     */
    private void loadHistoryPage(HttpServletRequest req, HttpServletResponse resp, TaiKhoan user)
            throws ServletException, IOException {
        List<Lichdatsan> dsLich = lichDatSanDAO.getLichByAccountId(user.getAccountId());

        // Lấy tên sân và Cơ Sở để hiển thị đẹp hơn trong bảng lịch sử
        List<San> dsSan = sanDAO.getAllSan();
        List<org.example.model.CoSo> dsCoSo = coSoDAO.getAllCoSo();

        // Với mỗi booking đã hủy/không đến, tìm bản ghi lịch sử uy tín liên quan gần nhất
        // (LATE_CANCEL/NO_SHOW/EARLY_CANCEL) để hiển thị rõ tác động uy tín cho khách hàng.
        Map<Integer, CustomerReputationHistory> reputationByDatSanId = new HashMap<>();
        for (CustomerReputationHistory h : reputationHistoryDAO.getByAccountId(user.getAccountId())) {
            if (h.getDatSanId() == null) {
                continue;
            }
            if (!Constants.REPUTATION_ACTION_LATE_CANCEL.equals(h.getActionType())
                    && !Constants.REPUTATION_ACTION_NO_SHOW.equals(h.getActionType())
                    && !Constants.REPUTATION_ACTION_EARLY_CANCEL.equals(h.getActionType())) {
                continue;
            }
            // getByAccountId() trả về mới nhất trước; giữ bản ghi đầu tiên gặp cho mỗi DatSanID.
            reputationByDatSanId.putIfAbsent(h.getDatSanId(), h);
        }

        req.setAttribute("dsLich", dsLich);
        req.setAttribute("dsSan", dsSan);
        req.setAttribute("dsCoSo", dsCoSo);
        req.setAttribute("reputationByDatSanId", reputationByDatSanId);
        req.getRequestDispatcher("/customer/LichSuDatSan.jsp").forward(req, resp);
    }

    // =========================================================================
    // PHẦN 2: XỬ LÝ POST - Xử lý hành động đặt sân / hủy sân
    // =========================================================================

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String path = req.getServletPath();
        HttpSession session = req.getSession();
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");

        // POST luôn yêu cầu đăng nhập
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        if (path.equals("/customer/dat-san")) {
            handleDatSan(req, resp, session, user);
        } else if (path.equals("/customer/huy-dat-san")) {
            handleHuyDatSan(req, resp, session, user);
        } else if (path.equals("/customer/dat-dich-vu")) {
            handlePostDatDichVu(req, resp, session, user);
        } else if (path.equals("/customer/payos-retry")) {
            handlePayOSRetry(req, resp, user);
        } else if (path.equals("/customer/payos-pay-counter")) {
            handlePayOSPayCounter(req, resp, user);
        }
    }

    // =========================================================================
    // PHẦN 3: LOGIC ĐẶT SÂN - Với đầy đủ kiểm tra và retry deadlock
    // =========================================================================

    /**
     * Xử lý yêu cầu đặt sân từ khách hàng.
     *
     * QUY TRÌNH:
     * 1. Parse và validate input
     * 2. Kiểm tra ngày giờ không được trong quá khứ
     * 3. Vòng lặp retry khi deadlock (tối đa MAX_DEADLOCK_RETRIES lần):
     * a. Bắt đầu transaction
     * b. Lock hàng San (UPDLOCK, ROWLOCK) để ngăn concurrent booking
     * c. Kiểm tra trạng thái sân (chỉ chấp nhận 'Sẵn sàng')
     * d. Kiểm tra giờ mở cửa Cơ Sở
     * e. Kiểm tra trùng lịch
     * f. Tính giá và INSERT
     * g. Commit transaction
     */
    private void handleDatSan(HttpServletRequest req, HttpServletResponse resp,
            HttpSession session, TaiKhoan user) throws IOException {
        long tSubmit0 = System.currentTimeMillis();
        // --- Bước 1: Parse input ---
        int sanId;
        LocalDate ngayDat;
        LocalTime gioBatDau, gioKetThuc;
        String ghiChu;
        String paymentMethod;

        // --- Dịch vụ đi kèm đặt trước (Phase 8A) — tham số MỚI, không đụng input cũ ---
        int[] serviceIds;
        int[] serviceQtys;

        try {
            String pSanId = req.getParameter("sanId");
            String pNgayDat = req.getParameter("ngayDat");
            String pGioBatDau = req.getParameter("gioBatDau");
            String pGioKetThuc = req.getParameter("gioKetThuc");

            String missingParam = null;
            if (pSanId == null || pSanId.trim().isEmpty()) {
                missingParam = "sanId";
            } else if (pNgayDat == null || pNgayDat.trim().isEmpty()) {
                missingParam = "ngayDat";
            } else if (pGioBatDau == null || pGioBatDau.trim().isEmpty()) {
                missingParam = "gioBatDau";
            } else if (pGioKetThuc == null || pGioKetThuc.trim().isEmpty()) {
                missingParam = "gioKetThuc";
            }
            if (missingParam != null) {
                LOGGER.log(Level.WARNING, "Thiếu tham số đặt sân bắt buộc: {0}", missingParam);
                session.setAttribute("error", "Thiếu thông tin đặt sân. Vui lòng chọn lại sân, ngày và khung giờ.");
                resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                return;
            }

            sanId = Integer.parseInt(pSanId);
            ngayDat = LocalDate.parse(pNgayDat);
            gioBatDau = LocalTime.parse(pGioBatDau);
            gioKetThuc = LocalTime.parse(pGioKetThuc);
            ghiChu = req.getParameter("ghiChu");
            paymentMethod = req.getParameter("paymentMethod");
            if (paymentMethod == null || paymentMethod.trim().isEmpty()) {
                paymentMethod = "sau";
            }

            String[] serviceIdParams = req.getParameterValues("serviceId");
            String[] serviceQtyParams = req.getParameterValues("serviceQty");
            if (serviceIdParams != null && serviceQtyParams != null && serviceIdParams.length == serviceQtyParams.length) {
                serviceIds = new int[serviceIdParams.length];
                serviceQtys = new int[serviceQtyParams.length];
                for (int i = 0; i < serviceIdParams.length; i++) {
                    serviceIds[i] = Integer.parseInt(serviceIdParams[i].trim());
                    serviceQtys[i] = Integer.parseInt(serviceQtyParams[i].trim());
                }
            } else {
                serviceIds = new int[0];
                serviceQtys = new int[0];
            }
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "Dữ liệu đặt sân không hợp lệ", e);
            session.setAttribute("error", "Dữ liệu không hợp lệ. Vui lòng kiểm tra lại thông tin.");
            resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
            return;
        }

        // --- Validate số lượng dịch vụ trước khi vào transaction ---
        for (int qty : serviceQtys) {
            if (qty <= 0) {
                session.setAttribute("error", "Số lượng dịch vụ phải lớn hơn 0.");
                resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                return;
            }
        }

        // Validate paymentMethod enum value
        if (!"payos".equalsIgnoreCase(paymentMethod) && !"sau".equalsIgnoreCase(paymentMethod)) {
            session.setAttribute("error", "Phương thức thanh toán không hợp lệ.");
            resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
            return;
        }

        // --- Bước 2: Validate thứ tự giờ ---
        if (!gioKetThuc.isAfter(gioBatDau)) {
            session.setAttribute("error", "Giờ kết thúc phải sau giờ bắt đầu.");
            resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
            return;
        }

        // --- Bước 2c: Validate thời lượng đặt sân (tối thiểu 30 phút, tối đa 4 giờ) ---
        long durationMinutes = java.time.Duration.between(gioBatDau, gioKetThuc).toMinutes();
        if (durationMinutes < 30) {
            session.setAttribute("error", "Thời lượng đặt sân tối thiểu cho mỗi lượt là 30 phút.");
            resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
            return;
        }
        if (durationMinutes > 240) {
            session.setAttribute("error", "Thời lượng đặt sân tối đa cho mỗi lượt là 4 giờ (240 phút).");
            resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
            return;
        }

        // --- Bước 2b: Validate ngày/giờ không được trong quá khứ ---
        LocalDate today = LocalDate.now();
        LocalTime now = LocalTime.now();

        if (ngayDat.isBefore(today)) {
            session.setAttribute("error", "Không thể đặt sân cho ngày đã qua. Vui lòng chọn ngày từ hôm nay trở đi.");
            resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
            return;
        }

        if (ngayDat.equals(today) && gioBatDau.isBefore(now)) {
            session.setAttribute("error",
                    "Không thể đặt sân cho giờ đã qua trong ngày hôm nay. Vui lòng chọn giờ khác.");
            resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
            return;
        }

        // --- Bước 2d: Validate không đặt quá xa trong tương lai (tối đa 30 ngày) ---
        LocalDate maxDate = today.plusDays(30);
        if (ngayDat.isAfter(maxDate)) {
            session.setAttribute("error",
                    "Chỉ có thể đặt sân trong vòng 30 ngày tới (tối đa đến ngày " + maxDate + "). Vui lòng chọn ngày khác.");
            resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
            return;
        }

        // --- Bước 3: Vòng lặp retry deadlock ---
        for (int attempt = 1; attempt <= MAX_DEADLOCK_RETRIES; attempt++) {
            try (java.sql.Connection conn = org.example.util.DBUtil.getConnection()) {
                if (conn == null) {
                    session.setAttribute("error", "Không thể kết nối cơ sở dữ liệu. Vui lòng thử lại sau.");
                    resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                    return;
                }

                conn.setAutoCommit(false);
                try {
                    // ── 3a. Khóa hàng San để ngăn concurrent booking cùng sân ──
                    // Sử dụng UPDLOCK + ROWLOCK để block đọc lẫn ghi cho hàng này
                    // trong suốt transaction, tránh race condition dẫn đến double booking
                    String lockSql = "SELECT SanID, TrangThai, CoSoID FROM San WITH (UPDLOCK, ROWLOCK) WHERE SanID = ?";
                    String sanTrangThai;
                    int sanCoSoID;

                    try (java.sql.PreparedStatement lockPs = conn.prepareStatement(lockSql)) {
                        lockPs.setInt(1, sanId);
                        try (java.sql.ResultSet rsLock = lockPs.executeQuery()) {
                            if (!rsLock.next()) {
                                conn.rollback();
                                session.setAttribute("error", "Sân không tồn tại trong hệ thống.");
                                resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                                return;
                            }
                            sanTrangThai = rsLock.getString("TrangThai");
                            sanCoSoID = rsLock.getInt("CoSoID");
                        }
                    }

                    // ── 3a-1. Giải phóng SoftHold của chính tài khoản này cho đúng slot đang submit ──
                    // Từ đây trở đi việc chặn slot đã do UPDLOCK trên San + re-check overlap bên dưới
                    // đảm nhiệm; SoftHold tạm (bước "Chọn ngày & giờ") không còn cần thiết nữa dù kết
                    // quả submit là thành công hay thất bại. Dùng connection riêng (tự commit), không
                    // nằm trong transaction này, để lệnh release không bị rollback theo nếu bước nào
                    // đó bên dưới thất bại.
                    softHoldDAO.deleteHoldsByAccountAndSan(user.getAccountId(), sanId, ngayDat);

                    // ── 3a-2. Kiểm tra giới hạn số booking/ngày per customer (tối đa 3 bookings) ──
                    if (org.example.dao.impl.LichDatSanDAOImpl.countActiveBookingsForAccountAndDate(
                            conn, user.getAccountId(), ngayDat) >= 3) {
                        conn.rollback();
                        session.setAttribute("error", "Bạn đã đạt giới hạn đặt sân tối đa trong ngày hôm nay (tối đa 3 lượt đặt/ngày).");
                        resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                        return;
                    }

                    // ── 3b. Kiểm tra trạng thái sân ──
                    // Chỉ cho phép đặt khi sân ở trạng thái 'Sẵn sàng'
                    if (!"Sẵn sàng".equals(sanTrangThai)) {
                        conn.rollback();
                        session.setAttribute("error",
                                "Sân này hiện đang ở trạng thái [" + sanTrangThai + "] và không thể đặt. " +
                                        "Vui lòng chọn sân khác.");
                        resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                        return;
                    }

                    // ── 3c. Kiểm tra giờ hoạt động của Cơ Sở ──
                    // Nếu Cơ Sở không có cấu hình giờ, mặc định dùng 06:00 - 23:00
                    LocalTime branchOpen = DEFAULT_OPEN_TIME;
                    LocalTime branchClose = DEFAULT_CLOSE_TIME;
                    String branchName = "Cơ Sở";

                    String coSoSql = "SELECT TenCoSo, GioMoCua, GioDongCua FROM CoSo WHERE CoSoID = ?";
                    try (java.sql.PreparedStatement coSoPs = conn.prepareStatement(coSoSql)) {
                        coSoPs.setInt(1, sanCoSoID);
                        try (java.sql.ResultSet rsCoSo = coSoPs.executeQuery()) {
                            if (rsCoSo.next()) {
                                branchName = rsCoSo.getString("TenCoSo");
                                java.sql.Time dbOpen = rsCoSo.getTime("GioMoCua");
                                java.sql.Time dbClose = rsCoSo.getTime("GioDongCua");
                                if (dbOpen != null)
                                    branchOpen = dbOpen.toLocalTime();
                                if (dbClose != null)
                                    branchClose = dbClose.toLocalTime();
                            }
                        }
                    }

                    // Kiểm tra giờ bắt đầu không được trước giờ mở cửa
                    if (gioBatDau.isBefore(branchOpen)) {
                        conn.rollback();
                        session.setAttribute("error", String.format(
                                "%s mở cửa lúc %s. Giờ bắt đầu của bạn (%s) quá sớm.",
                                branchName,
                                branchOpen.toString().substring(0, 5),
                                gioBatDau.toString().substring(0, 5)));
                        resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                        return;
                    }

                    // Kiểm tra giờ kết thúc không được vượt quá giờ đóng cửa
                    if (gioKetThuc.isAfter(branchClose)) {
                        conn.rollback();
                        session.setAttribute("error", String.format(
                                "%s đóng cửa lúc %s. Giờ kết thúc của bạn (%s) vượt quá giờ hoạt động.",
                                branchName,
                                branchClose.toString().substring(0, 5),
                                gioKetThuc.toString().substring(0, 5)));
                        resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                        return;
                    }

                    // ── 3d. Kiểm tra trùng lịch (Overlap check) ──
                    // Công thức overlap: NOT (KetThuc <= BatDau_Khac OR BatDau >= KetThuc_Khac)
                    // "Chờ xác nhận" (COD) chặn slot cho tới khi được duyệt/từ chối/tự hết hạn.
                    // "Chờ thanh toán" chỉ chặn khi còn hạn giữ chỗ thật (HoldExpiresAt), không còn
                    // dùng DATEDIFF(CreatedTime) giả nữa.
                    // "Đã hoàn thành"/"Quá hạn"/"Đã hủy" không chặn — booking cho NgayDat/GioBatDau
                    // trong quá khứ đã bị validate ở Bước 2b phía trên rồi nên không cần chặn lại ở đây.
                    String checkSql = "SELECT COUNT(*) FROM LichDatSan " +
                            "WHERE SanID = ? AND NgayDat = ? " +
                            "AND (TrangThai IN (N'" + org.example.util.Constants.TRANG_THAI_DAT_SAN_DA_XAC_NHAN + "', " +
                            "N'" + org.example.util.Constants.TRANG_THAI_DAT_SAN_DANG_SU_DUNG + "', " +
                            "N'" + org.example.util.Constants.TRANG_THAI_DAT_SAN_CHO_XAC_NHAN + "') " +
                            "     OR (TrangThai = N'" + org.example.util.Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN + "' AND HoldExpiresAt > SYSUTCDATETIME())) " +
                            "AND NOT (GioKetThuc <= CAST(? AS time) OR GioBatDau >= CAST(? AS time))";

                    boolean hasOverlap;
                    try (java.sql.PreparedStatement checkPs = conn.prepareStatement(checkSql)) {
                        checkPs.setInt(1, sanId);
                        checkPs.setDate(2, java.sql.Date.valueOf(ngayDat));
                        checkPs.setString(3, gioBatDau.toString()); // KetThuc <= BatDauNew => không overlap
                        checkPs.setString(4, gioKetThuc.toString()); // BatDau >= KetThucNew => không overlap
                        try (java.sql.ResultSet rs = checkPs.executeQuery()) {
                            hasOverlap = rs.next() && rs.getInt(1) > 0;
                        }
                    }

                    if (hasOverlap) {
                        conn.rollback();
                        session.setAttribute("error",
                                "Khung giờ " + gioBatDau.toString().substring(0, 5) + " - " +
                                        gioKetThuc.toString().substring(0, 5) +
                                        " đã có người đặt cho sân này. Vui lòng chọn khung giờ khác.");
                        resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                        return;
                    }

                    // ── 3d-2. Kiểm tra SoftHold đang hoạt động từ tài khoản KHÁC ──
                    // Không chặn nếu hold đó là của chính tài khoản hiện tại (self-hold).
                    String checkHoldSql = "SELECT COUNT(*) FROM SoftHold " +
                            "WHERE SanID = ? AND NgayDat = ? AND AccountID <> ? " +
                            "AND DATEDIFF(minute, CreatedTime, GETDATE()) <= " +
                            org.example.util.Constants.SOFT_HOLD_TIMEOUT_MINUTES + " " +
                            "AND NOT (GioKetThuc <= CAST(? AS time) OR GioBatDau >= CAST(? AS time))";

                    boolean hasActiveHoldFromOther;
                    try (java.sql.PreparedStatement holdPs = conn.prepareStatement(checkHoldSql)) {
                        holdPs.setInt(1, sanId);
                        holdPs.setDate(2, java.sql.Date.valueOf(ngayDat));
                        holdPs.setInt(3, user.getAccountId());
                        holdPs.setString(4, gioBatDau.toString());
                        holdPs.setString(5, gioKetThuc.toString());
                        try (java.sql.ResultSet rsHold = holdPs.executeQuery()) {
                            hasActiveHoldFromOther = rsHold.next() && rsHold.getInt(1) > 0;
                        }
                    }

                    if (hasActiveHoldFromOther) {
                        conn.rollback();
                        session.setAttribute("error",
                                "Khung giờ " + gioBatDau.toString().substring(0, 5) + " - " +
                                        gioKetThuc.toString().substring(0, 5) +
                                        " hiện đang được người khác giữ chỗ tạm thời. Vui lòng thử lại sau ít phút hoặc chọn khung giờ khác.");
                        resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                        return;
                    }

                    // ── 3e. Tính giá theo loại sân và giờ đèn ──
                    double hourlyPrice = 100_000; // Fallback mặc định
                    boolean applyLights = false;

                    String loaiSanSql = "SELECT GiaKhongDen, GiaCoDen, GioBatDauLenDen FROM LoaiSan WHERE LoaiSanID = "
                            +
                            "(SELECT LoaiSanID FROM San WHERE SanID = ?)";
                    try (java.sql.PreparedStatement loaiPs = conn.prepareStatement(loaiSanSql)) {
                        loaiPs.setInt(1, sanId);
                        try (java.sql.ResultSet rsLoai = loaiPs.executeQuery()) {
                            if (rsLoai.next()) {
                                double giaKhongDen = rsLoai.getDouble("GiaKhongDen");
                                double giaCoDen = rsLoai.getDouble("GiaCoDen");
                                LocalTime gioLenDen = LocalTime.of(17, 30); // Mặc định 17:30

                                java.sql.Time sqlLenDen = rsLoai.getTime("GioBatDauLenDen");
                                if (sqlLenDen != null)
                                    gioLenDen = sqlLenDen.toLocalTime();

                                // Áp dụng giá đèn nếu giờ bắt đầu >= giờ bật đèn
                                if (!gioBatDau.isBefore(gioLenDen)) {
                                    hourlyPrice = giaCoDen;
                                    applyLights = (giaCoDen != giaKhongDen); // Chỉ ghi nhận nếu giá thực sự khác nhau
                                } else {
                                    hourlyPrice = giaKhongDen;
                                }
                            }
                        }
                    }

                    // Tính tổng tiền dự kiến
                    durationMinutes = java.time.Duration.between(gioBatDau, gioKetThuc).toMinutes();
                    double durationHours = durationMinutes / 60.0;
                    double tongTien = durationHours * hourlyPrice;

                    // ── 3f. INSERT lịch đặt sân trong cùng transaction ──
                    boolean isOnlineDeposit = "payos".equalsIgnoreCase(paymentMethod);
                    String initialStatus = isOnlineDeposit
                            ? org.example.util.Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN
                            : org.example.util.Constants.TRANG_THAI_DAT_SAN_CHO_XAC_NHAN;
                    // HoldExpiresAt là MỐC TUYỆT ĐỐI (instant) → lưu bằng SYSUTCDATETIME() (UTC), không
                    // phụ thuộc timezone máy chủ DB. Mọi nơi so sánh với HoldExpiresAt cũng dùng
                    // SYSUTCDATETIME() (SQL) hoặc Instant.now() qua TimeUtil (Java) → nhất quán UTC.
                    // Không bao giờ nhận từ frontend; BOOKING_HOLD_MINUTES là hằng số compile-time.
                    String holdExpiresAtExpr = isOnlineDeposit
                            ? "DATEADD(MINUTE, " + org.example.util.Constants.BOOKING_HOLD_MINUTES + ", SYSUTCDATETIME())"
                            : "NULL";

                    String insertSql = "INSERT INTO LichDatSan " +
                            "(AccountID, SanID, NgayDat, GioBatDau, GioKetThuc, " +
                            " ApDungGiaCoDen, TongTienDuKien, TrangThai, GhiChu, NguonDatSan, HoldExpiresAt) " +
                            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, " + holdExpiresAtExpr + ")";

                    int newDatSanId = -1;
                    try (java.sql.PreparedStatement insertPs = conn.prepareStatement(insertSql, java.sql.Statement.RETURN_GENERATED_KEYS)) {
                        insertPs.setInt(1, user.getAccountId());
                        insertPs.setInt(2, sanId);
                        insertPs.setDate(3, java.sql.Date.valueOf(ngayDat));
                        insertPs.setTime(4, java.sql.Time.valueOf(gioBatDau));
                        insertPs.setTime(5, java.sql.Time.valueOf(gioKetThuc));
                        insertPs.setBoolean(6, applyLights);
                        insertPs.setBigDecimal(7,
                                BigDecimal.valueOf(tongTien).setScale(0, java.math.RoundingMode.HALF_UP));
                        insertPs.setString(8, initialStatus);
                        insertPs.setString(9, ghiChu != null ? ghiChu.trim() : "");
                        insertPs.setString(10, "Web");
                        insertPs.executeUpdate();
                        try (java.sql.ResultSet genKeys = insertPs.getGeneratedKeys()) {
                            if (genKeys.next()) newDatSanId = genKeys.getInt(1);
                        }
                    }

                    // ── 3f-1. Lưu dịch vụ đặt trước (Phase 8A) ──
                    // Dịch vụ được đặt trước, thanh toán tại quầy — KHÔNG cộng vào tongTien/PayOS.
                    // Giá lấy từ DB (không tin client). Nếu bất kỳ dòng nào không hợp lệ (sai cơ sở,
                    // ngừng kinh doanh, vượt tồn kho) → rollback toàn bộ booking, báo lỗi rõ ràng.
                    if (serviceIds.length > 0) {
                        String svcSql = "SELECT SanPhamID, TenSanPham, DonGia, SoLuongTon, TrangThai, CoSoID " +
                                "FROM SanPham_DichVu WHERE SanPhamID = ?";
                        try (java.sql.PreparedStatement svcPs = conn.prepareStatement(svcSql)) {
                            for (int i = 0; i < serviceIds.length; i++) {
                                int spId = serviceIds[i];
                                int qty = serviceQtys[i];
                                svcPs.setInt(1, spId);
                                try (java.sql.ResultSet rsSvc = svcPs.executeQuery()) {
                                    if (!rsSvc.next()) {
                                        conn.rollback();
                                        session.setAttribute("error", "Một dịch vụ bạn chọn không tồn tại. Vui lòng thử lại.");
                                        resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                                        return;
                                    }
                                    int spCoSoId = rsSvc.getInt("CoSoID");
                                    String spTrangThai = rsSvc.getString("TrangThai");
                                    int soLuongTon = rsSvc.getInt("SoLuongTon");
                                    String tenSp = rsSvc.getString("TenSanPham");
                                    BigDecimal donGia = rsSvc.getBigDecimal("DonGia");

                                    if (spCoSoId != sanCoSoID) {
                                        conn.rollback();
                                        session.setAttribute("error", "Dịch vụ '" + tenSp + "' không thuộc cơ sở của sân bạn đang đặt.");
                                        resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                                        return;
                                    }
                                    if (!org.example.util.Constants.TRANG_THAI_SP_DANG_KINH_DOANH.equals(spTrangThai)) {
                                        conn.rollback();
                                        session.setAttribute("error", "Dịch vụ '" + tenSp + "' hiện không kinh doanh.");
                                        resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                                        return;
                                    }
                                    if (qty > soLuongTon) {
                                        conn.rollback();
                                        session.setAttribute("error", "Dịch vụ '" + tenSp + "' chỉ còn " + soLuongTon + " trong kho, không đủ số lượng bạn chọn.");
                                        resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                                        return;
                                    }

                                    BigDecimal totalPrice = donGia.multiply(BigDecimal.valueOf(qty));
                                    lichDatSanDichVuDAO.insertPreOrder(conn, newDatSanId, spId, qty, donGia, totalPrice);
                                }
                            }
                        }
                    }

                    // ── 3f-2. Dọn SoftHold của chính tài khoản này cho San+Ngày này ──
                    // (không bắt buộc cho tính đúng đắn - hold sẽ tự hết hạn sau 2 phút -
                    //  nhưng dọn ngay giúp tránh soft-hold "rác" không cần thiết)
                    String cleanupHoldSql = "DELETE FROM SoftHold WHERE AccountID = ? AND SanID = ? AND NgayDat = ?";
                    try (java.sql.PreparedStatement cleanupPs = conn.prepareStatement(cleanupHoldSql)) {
                        cleanupPs.setInt(1, user.getAccountId());
                        cleanupPs.setInt(2, sanId);
                        cleanupPs.setDate(3, java.sql.Date.valueOf(ngayDat));
                        cleanupPs.executeUpdate();
                    }

                    // ── 3g. Commit toàn bộ transaction ──
                    long tCommit0 = System.currentTimeMillis();
                    conn.commit();
                    LOGGER.info(String.format("handleDatSan: commit transaction=%dms", System.currentTimeMillis() - tCommit0));

                    LOGGER.info(String.format(
                            "Đặt sân thành công: AccountID=%d, SanID=%d, Ngày=%s, %s-%s, Tiền=%,.0fđ, PTTT=%s, tổng submit=%dms",
                            user.getAccountId(), sanId, ngayDat, gioBatDau, gioKetThuc, tongTien, paymentMethod, System.currentTimeMillis() - tSubmit0));

                    boolean isAjax = "XMLHttpRequest".equals(req.getHeader("X-Requested-With"));

                    if (isOnlineDeposit) {
                        // ── PayOS: tạo QR hoặc redirect tùy request type ──
                        String scheme = req.getScheme();
                        String serverName = req.getServerName();
                        int port = req.getServerPort();
                        String ctx = req.getContextPath();
                        boolean defaultPort = (scheme.equals("http") && port == 80)
                                || (scheme.equals("https") && port == 443);
                        String baseUrl = scheme + "://" + serverName + (defaultPort ? "" : ":" + port) + ctx;

                        String returnUrl = baseUrl + "/customer/payos-return?datSanId=" + newDatSanId;
                        String cancelUrl = baseUrl + "/customer/payos-cancel?datSanId=" + newDatSanId;
                        long amount = BigDecimal.valueOf(tongTien).setScale(0, java.math.RoundingMode.HALF_UP).longValue();
                        // description tối đa 25 ký tự theo giới hạn PayOS
                        String description = "VSport DS" + newDatSanId;

                        long tPayOS0 = System.currentTimeMillis();
                        PayOSLinkResult linkResult = createFacilityPayOSLink(
                                sanCoSoID, (long) newDatSanId, amount, description, returnUrl, cancelUrl, false);
                        LOGGER.info(String.format("handleDatSan: PayOS createPaymentLink=%dms, success=%b%s",
                                System.currentTimeMillis() - tPayOS0, linkResult.success,
                                linkResult.success ? "" : ", errorCode=" + linkResult.errorCode));

                        if (linkResult.success) {
                            PayOSCheckoutSession checkoutSession = linkResult.session;
                            // Lưu QR (session + best-effort DB cache) để trang QR nhúng render lại được
                            // khi reload/đa tab, KHÔNG gọi lại PayOS. KHÔNG redirect sang checkout PayOS.
                            stashAndPersistQr(session, newDatSanId, checkoutSession, amount, description);
                            String qrPageUrl = req.getContextPath() + "/customer/thanh-toan-qr?datSanId=" + newDatSanId;
                            if (isAjax) {
                                resp.setContentType("application/json; charset=UTF-8");
                                resp.getWriter().write(String.format(
                                        "{\"success\":true,\"datSanId\":%d,\"redirectUrl\":\"%s\"}",
                                        newDatSanId, jsonEscape(qrPageUrl)));
                            } else {
                                resp.sendRedirect(qrPageUrl);
                            }
                        } else {
                            // KHÔNG hủy booking: giữ nguyên "Chờ thanh toán" + HoldExpiresAt hiện có để
                            // khách bấm "Thử lại" (/customer/payos-retry) hoặc "Thanh toán tại quầy"
                            // (/customer/payos-pay-counter) trên CÙNG đơn — không tạo booking mới. Nếu
                            // khách không làm gì, booking tự hết hạn giữ chỗ theo HoldExpiresAt sẵn có.
                            if (isAjax) {
                                resp.setContentType("application/json; charset=UTF-8");
                                resp.getWriter().write(String.format(
                                        "{\"success\":false,\"errorCode\":\"%s\",\"message\":\"%s\",\"datSanId\":%d,\"retryable\":%b,\"fallbackAvailable\":true}",
                                        linkResult.errorCode, jsonEscape(linkResult.message), newDatSanId, linkResult.retryable));
                            } else {
                                session.setAttribute("error", linkResult.message);
                                session.setAttribute("errorCode", linkResult.errorCode);
                                session.setAttribute("errorDatSanId", newDatSanId);
                                session.setAttribute("errorRetryable", linkResult.retryable);
                                resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                            }
                        }
                    } else {
                        session.setAttribute("message",
                                "Đặt sân thành công! Sân đã được thêm vào giỏ hàng. Vui lòng chờ cơ sở xác nhận.");
                        resp.sendRedirect(req.getContextPath() + "/customer/gio-hang");
                    }
                    return;

                } catch (SQLException sqlEx) {
                    // Rollback transaction khi có lỗi SQL
                    try {
                        conn.rollback();
                    } catch (SQLException ignored) {
                    }

                    // Kiểm tra nếu là lỗi deadlock → thực hiện retry
                    if (isDeadlockException(sqlEx) && attempt < MAX_DEADLOCK_RETRIES) {
                        LOGGER.log(Level.WARNING,
                                String.format("Deadlock phát hiện (lần thử %d/%d), đang retry sau khoảng dừng ngắn...",
                                        attempt, MAX_DEADLOCK_RETRIES),
                                sqlEx);
                        sleepBeforeRetry(attempt); // Dừng ngắn trước khi retry
                        // Tiếp tục vòng lặp for (retry)
                    } else {
                        // Không phải deadlock hoặc đã hết số lần retry
                        LOGGER.log(Level.SEVERE, "Lỗi SQL không thể phục hồi khi đặt sân", sqlEx);
                        session.setAttribute("error", "Hệ thống đang bận. Vui lòng thử lại sau ít phút. (SQL Error: "
                                + sqlEx.getErrorCode() + ")");
                        resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                        return;
                    }

                } catch (Exception e) {
                    try {
                        conn.rollback();
                    } catch (SQLException ignored) {
                    }
                    LOGGER.log(Level.SEVERE, "Lỗi bất ngờ khi đặt sân", e);
                    session.setAttribute("error", "Có lỗi xảy ra: " + e.getMessage());
                    resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                    return;
                }

            } catch (SQLException connEx) {
                LOGGER.log(Level.SEVERE, "Không thể lấy kết nối DB", connEx);
                session.setAttribute("error", "Không thể kết nối cơ sở dữ liệu. Vui lòng thử lại sau.");
                resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
                return;
            }
        } // end retry loop

        // Nếu đến đây: đã retry đủ MAX lần mà vẫn deadlock
        LOGGER.severe(String.format("Đặt sân thất bại sau %d lần retry do deadlock liên tục.", MAX_DEADLOCK_RETRIES));
        session.setAttribute("error", "Hệ thống đang có nhiều yêu cầu đồng thời. Vui lòng thử lại sau vài giây.");
        resp.sendRedirect(req.getContextPath() + "/customer/dat-san");
    }

    // =========================================================================
    // PHẦN 4: LOGIC HỦY ĐẶT SÂN
    // =========================================================================

    /**
     * Xử lý hủy lịch đặt sân.
     * Chỉ cho phép hủy đơn đang ở trạng thái 'Chờ xác nhận' và phải là đơn của
     * chính người dùng.
     */
    private void handleHuyDatSan(HttpServletRequest req, HttpServletResponse resp,
            HttpSession session, TaiKhoan user) throws IOException {
        LOGGER.info(String.format("[huy-dat-san] request nhận: servletPath=%s, pathInfo=%s, accountId=%d, rawId=%s",
                req.getServletPath(), req.getPathInfo(), user.getAccountId(), req.getParameter("id")));
        try {
            int id = Integer.parseInt(req.getParameter("id"));
            String reason = req.getParameter("reason");

            org.example.service.booking.BookingCancellationService.CancelResult result =
                    bookingCancellationService.cancelByCustomer(id, user.getAccountId(), reason, req, user);

            if (result.success) {
                session.setAttribute("message", result.message);
                LOGGER.info(String.format("[huy-dat-san] THANH CONG: AccountID=%d, DatSanID=%d, lateCancel=%s",
                        user.getAccountId(), id, result.lateCancel));
            } else {
                session.setAttribute("error", result.message);
                LOGGER.info(String.format("[huy-dat-san] THAT BAI: AccountID=%d, DatSanID=%d, message=%s",
                        user.getAccountId(), id, result.message));
            }
        } catch (NumberFormatException e) {
            session.setAttribute("error", "Yêu cầu không hợp lệ.");
        }

        String source = req.getParameter("source");
        if ("gio-hang".equals(source)) {
            resp.sendRedirect(req.getContextPath() + "/customer/gio-hang");
        } else {
        resp.sendRedirect(req.getContextPath() + "/customer/gio-hang");
        }
    }

    // =========================================================================
    // PHẦN 5: PAYOS RETURN / CANCEL
    // =========================================================================

    private void handlePayOSStatus(HttpServletRequest req, HttpServletResponse resp,
            TaiKhoan user) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        if (user == null) {
            resp.getWriter().write("{\"status\":\"error\",\"error\":\"Chưa đăng nhập\"}");
            return;
        }
        String paramId = req.getParameter("datSanId");
        if (paramId == null || paramId.isBlank()) {
            resp.getWriter().write("{\"status\":\"error\",\"error\":\"Thiếu datSanId\"}");
            return;
        }
        int datSanId;
        try {
            datSanId = Integer.parseInt(paramId.trim());
        } catch (NumberFormatException e) {
            resp.getWriter().write("{\"status\":\"error\",\"error\":\"Thiếu datSanId\"}");
            return;
        }
        org.example.model.Lichdatsan lich = lichDatSanDAO.getLichById(datSanId);
        if (lich == null || lich.getAccountId() == null || !lich.getAccountId().equals(user.getAccountId())) {
            resp.getWriter().write("{\"status\":\"error\",\"error\":\"Không tìm thấy đơn\"}");
            return;
        }
        String trangThai = lich.getTrangThai();
        LocalDateTime holdExpiresAt = lich.getHoldExpiresAt();
        // HoldExpiresAt lưu UTC → so sánh bằng Instant UTC (TimeUtil), không dùng giờ JVM/VN.
        boolean holdExpired = org.example.util.TimeUtil.isPastUtc(holdExpiresAt);

        // status: giá trị gọn để frontend polling quyết định dừng (paid/cancelled/expired/pending).
        String status;
        String ctx = req.getContextPath();
        String redirectUrl = null;
        if (Constants.TRANG_THAI_DAT_SAN_DA_XAC_NHAN.equals(trangThai)) {
            status = "paid";
            redirectUrl = ctx + "/customer/gio-hang";
        } else if (Constants.TRANG_THAI_DAT_SAN_DA_HUY.equals(trangThai)) {
            status = "cancelled";
        } else if (Constants.TRANG_THAI_DAT_SAN_QUA_HAN.equals(trangThai)
                || (Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN.equals(trangThai) && holdExpired)) {
            status = "expired";
        } else if (Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN.equals(trangThai)) {
            status = "pending";
        } else {
            // "Chờ xác nhận" (trả tại quầy) hoặc trạng thái khác -> coi như đã xử lý xong với luồng QR.
            status = "settled";
        }

        long remainingSeconds = 0L;
        if ("pending".equals(status)) {
            remainingSeconds = org.example.util.TimeUtil.secondsUntilUtc(holdExpiresAt);
        }

        StringBuilder json = new StringBuilder();
        json.append("{\"success\":true")
            .append(",\"status\":\"").append(status).append("\"")
            .append(",\"bookingStatus\":\"").append(jsonEscape(trangThai != null ? trangThai : "")).append("\"")
            .append(",\"remainingSeconds\":").append(remainingSeconds);
        if (redirectUrl != null) {
            json.append(",\"redirectUrl\":\"").append(jsonEscape(redirectUrl)).append("\"");
        } else {
            json.append(",\"redirectUrl\":null");
        }
        json.append("}");
        resp.getWriter().write(json.toString());
    }

    private void handlePayOSReturn(HttpServletRequest req, HttpServletResponse resp,
            HttpSession session) throws IOException {
        session.setAttribute("message",
                "Hệ thống đang kiểm tra thanh toán. Vui lòng chờ xác nhận.");
        resp.sendRedirect(req.getContextPath() + "/customer/gio-hang");
    }

    private void handlePayOSCancel(HttpServletRequest req, HttpServletResponse resp,
            HttpSession session, TaiKhoan user) throws IOException {
        Integer datSanId = parseIntParam(req.getParameter("datSanId"));
        if (datSanId == null) datSanId = parseIntParam(req.getParameter("orderCode"));
        if (datSanId == null) {
            resp.sendRedirect(req.getContextPath() + "/customer/gio-hang");
            return;
        }

        boolean cancelled = false;
        try (java.sql.Connection conn = org.example.util.DBUtil.getConnection()) {
            // Kiểm tra quyền sở hữu + trạng thái TRƯỚC khi hủy (không cho đoán DatSanID của người khác).
            int ownerAccountId = -1, coSoId = -1; String trangThai = null;
            String checkSql = "SELECT l.AccountID, l.TrangThai, s.CoSoID FROM LichDatSan l " +
                    "JOIN San s ON s.SanID = l.SanID WHERE l.DatSanID = ?";
            try (java.sql.PreparedStatement ps = conn.prepareStatement(checkSql)) {
                ps.setInt(1, datSanId);
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        ownerAccountId = rs.getInt("AccountID");
                        trangThai = rs.getString("TrangThai");
                        coSoId = rs.getInt("CoSoID");
                    }
                }
            }

            if (trangThai == null || ownerAccountId != user.getAccountId()) {
                session.setAttribute("error", "Không tìm thấy đơn đặt sân của bạn.");
                resp.sendRedirect(req.getContextPath() + "/customer/gio-hang");
                return;
            }

            if (Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN.equals(trangThai)) {
                // Hủy link PayOS còn treo (best-effort) rồi giải phóng slot + đánh dấu hủy trong 1 UPDATE.
                cancelPayosLinkQuietly(coSoId, datSanId);
                String sql = "UPDATE LichDatSan SET TrangThai = N'" + Constants.TRANG_THAI_DAT_SAN_DA_HUY + "', " +
                        "HoldExpiresAt = NULL, " +
                        "GhiChu = CONCAT(ISNULL(GhiChu, N''), N' [Người dùng hủy thanh toán PayOS]') " +
                        "WHERE DatSanID = ? AND TrangThai = N'" + Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN + "'";
                try (java.sql.PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, datSanId);
                    cancelled = ps.executeUpdate() == 1;
                }
            }
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "Lỗi khi hủy booking PayOS DatSanID=" + datSanId, e);
        }

        session.removeAttribute(PayosQrData.sessionKey(datSanId));
        session.setAttribute("message", cancelled
                ? "Bạn đã hủy thanh toán. Khung giờ đã được giải phóng."
                : "Đơn không còn ở trạng thái có thể hủy.");
        resp.sendRedirect(req.getContextPath() + "/customer/gio-hang");
    }

    /** Hủy payment link PayOS (best-effort) cho một booking; không ném lỗi ra ngoài. */
    private void cancelPayosLinkQuietly(int coSoId, long datSanId) {
        try {
            PayOSCredentials credentials = new PayOSConfigurationService().getCredentialsForPayment(coSoId);
            if (credentials == null) return;
            PayOS client = PayOSClientFactory.create(credentials);
            try {
                client.paymentRequests().cancel(datSanId, "Khách hủy thanh toán");
            } finally {
                client.close();
            }
        } catch (Exception ignored) {
            // Không có link treo / PayOS lỗi - state nội bộ vẫn được xử lý an toàn ở caller.
        }
    }

    // =========================================================================
    // PHẦN 5B: PAYOS RETRY / CHUYỂN THANH TOÁN TẠI QUẦY (không tạo booking mới)
    // =========================================================================

    /**
     * "Thử lại" sau khi tạo link PayOS lần đầu thất bại. Dùng lại ĐÚNG booking đang "Chờ thanh
     * toán" (không insert booking mới), tính lại amount từ DB (không tin frontend), hủy link cũ
     * (nếu có) rồi tạo link mới với cùng orderCode=DatSanID. Idempotent: bấm nhiều lần chỉ tạo
     * một link còn hiệu lực tại một thời điểm.
     */
    private void handlePayOSRetry(HttpServletRequest req, HttpServletResponse resp, TaiKhoan user) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        Integer datSanId = parseIntParam(req.getParameter("datSanId"));
        if (datSanId == null) {
            resp.getWriter().write("{\"success\":false,\"errorCode\":\"VALIDATION_ERROR\",\"message\":\"Thiếu datSanId.\"}");
            return;
        }

        try (java.sql.Connection conn = org.example.util.DBUtil.getConnection()) {
            String sql = "SELECT l.AccountID, l.TrangThai, l.TongTienDuKien, l.HoldExpiresAt, s.CoSoID " +
                    "FROM LichDatSan l JOIN San s ON s.SanID = l.SanID WHERE l.DatSanID = ?";
            int accountId, coSoId; String trangThai; java.math.BigDecimal amountDb; java.sql.Timestamp holdExpiresAt;
            try (java.sql.PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, datSanId);
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        resp.getWriter().write("{\"success\":false,\"errorCode\":\"NOT_FOUND\",\"message\":\"Không tìm thấy đơn đặt sân.\"}");
                        return;
                    }
                    accountId = rs.getInt("AccountID");
                    trangThai = rs.getString("TrangThai");
                    amountDb = rs.getBigDecimal("TongTienDuKien");
                    holdExpiresAt = rs.getTimestamp("HoldExpiresAt");
                    coSoId = rs.getInt("CoSoID");
                }
            }
            if (accountId != user.getAccountId()) {
                resp.getWriter().write("{\"success\":false,\"errorCode\":\"FORBIDDEN\",\"message\":\"Đơn đặt sân không thuộc về bạn.\"}");
                return;
            }
            if (!Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN.equals(trangThai)) {
                resp.getWriter().write("{\"success\":false,\"errorCode\":\"PAYMENT_CONFLICT\",\"message\":\"Đơn không còn ở trạng thái chờ thanh toán. Vui lòng tải lại trang.\"}");
                return;
            }
            // holdExpiresAt (Timestamp) lưu UTC → so sánh bằng Instant UTC (TimeUtil.fromDb), không dùng giờ JVM.
            java.time.Instant holdInstant = org.example.util.TimeUtil.fromDb(holdExpiresAt);
            if (holdInstant == null || holdInstant.isBefore(java.time.Instant.now())) {
                resp.getWriter().write(String.format(
                        "{\"success\":false,\"errorCode\":\"HOLD_EXPIRED\",\"message\":\"%s\"}", jsonEscape(MSG_EXPIRED)));
                return;
            }

            long amount = amountDb.setScale(0, java.math.RoundingMode.HALF_UP).longValue();
            String description = "VSport DS" + datSanId;
            String baseUrl = resolveBaseUrl(req);
            String returnUrl = baseUrl + "/customer/payos-return?datSanId=" + datSanId;
            String cancelUrl = baseUrl + "/customer/payos-cancel?datSanId=" + datSanId;

            PayOSLinkResult linkResult = createFacilityPayOSLink(coSoId, (long) datSanId, amount, description, returnUrl, cancelUrl, true);
            if (linkResult.success) {
                PayOSCheckoutSession s = linkResult.session;
                // Cập nhật cache QR mới (session + DB) rồi để frontend nạp lại trang QR nhúng.
                stashAndPersistQr(req.getSession(), datSanId, s, amount, description);
                String qrPageUrl = req.getContextPath() + "/customer/thanh-toan-qr?datSanId=" + datSanId;
                resp.getWriter().write(String.format(
                        "{\"success\":true,\"datSanId\":%d,\"redirectUrl\":\"%s\"}",
                        datSanId, jsonEscape(qrPageUrl)));
            } else {
                resp.getWriter().write(String.format(
                        "{\"success\":false,\"errorCode\":\"%s\",\"message\":\"%s\",\"retryable\":%b}",
                        linkResult.errorCode, jsonEscape(linkResult.message), linkResult.retryable));
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi thử lại PayOS DatSanID=" + datSanId, e);
            resp.getWriter().write("{\"success\":false,\"errorCode\":\"INTERNAL_ERROR\",\"message\":\"Có lỗi xảy ra. Vui lòng thử lại.\"}");
        }
    }

    /**
     * Chuyển một booking đang "Chờ thanh toán" (giữ chỗ chờ PayOS) sang thanh toán tại quầy:
     * hủy link PayOS còn treo (best-effort) rồi đổi TrangThai -> "Chờ xác nhận" (đúng trạng thái
     * ban đầu của luồng thanh toán sau/tại quầy), xóa HoldExpiresAt. Không tạo booking mới.
     */
    private void handlePayOSPayCounter(HttpServletRequest req, HttpServletResponse resp, TaiKhoan user) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        Integer datSanId = parseIntParam(req.getParameter("datSanId"));
        if (datSanId == null) {
            resp.getWriter().write("{\"success\":false,\"errorCode\":\"VALIDATION_ERROR\",\"message\":\"Thiếu datSanId.\"}");
            return;
        }

        try (java.sql.Connection conn = org.example.util.DBUtil.getConnection()) {
            String sql = "SELECT l.AccountID, l.TrangThai, s.CoSoID FROM LichDatSan l JOIN San s ON s.SanID = l.SanID WHERE l.DatSanID = ?";
            int accountId, coSoId; String trangThai;
            try (java.sql.PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, datSanId);
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        resp.getWriter().write("{\"success\":false,\"errorCode\":\"NOT_FOUND\",\"message\":\"Không tìm thấy đơn đặt sân.\"}");
                        return;
                    }
                    accountId = rs.getInt("AccountID");
                    trangThai = rs.getString("TrangThai");
                    coSoId = rs.getInt("CoSoID");
                }
            }
            if (accountId != user.getAccountId()) {
                resp.getWriter().write("{\"success\":false,\"errorCode\":\"FORBIDDEN\",\"message\":\"Đơn đặt sân không thuộc về bạn.\"}");
                return;
            }
            if (!Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN.equals(trangThai)) {
                resp.getWriter().write("{\"success\":false,\"errorCode\":\"PAYMENT_CONFLICT\",\"message\":\"Đơn không còn ở trạng thái chờ thanh toán. Vui lòng tải lại trang.\"}");
                return;
            }

            PayOSCredentials credentials = new PayOSConfigurationService().getCredentialsForPayment(coSoId);
            if (credentials != null) {
                PayOS client = PayOSClientFactory.create(credentials);
                try {
                    client.paymentRequests().cancel((long) datSanId, "Khách chuyển sang thanh toán tại quầy");
                } catch (Exception ignoredNoExistingLink) {
                    // Không có link đang treo (chưa từng tạo được) - bỏ qua.
                } finally {
                    client.close();
                }
            }

            String updateSql = "UPDATE LichDatSan SET TrangThai = N'" + Constants.TRANG_THAI_DAT_SAN_CHO_XAC_NHAN +
                    "', HoldExpiresAt = NULL, GhiChu = ISNULL(GhiChu, N'') + N' [Khách chuyển sang thanh toán tại quầy]' " +
                    "WHERE DatSanID = ? AND TrangThai = N'" + Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN + "'";
            try (java.sql.PreparedStatement up = conn.prepareStatement(updateSql)) {
                up.setInt(1, datSanId);
                int updated = up.executeUpdate();
                if (updated != 1) {
                    resp.getWriter().write("{\"success\":false,\"errorCode\":\"PAYMENT_CONFLICT\",\"message\":\"Đơn đã được xử lý bởi thao tác khác. Vui lòng tải lại trang.\"}");
                    return;
                }
            }
            LOGGER.info(String.format("PAYOS_SWITCH_TO_COUNTER datSanId=%d facilityId=%d accountId=%d", datSanId, coSoId, user.getAccountId()));
            resp.getWriter().write("{\"success\":true,\"message\":\"Đã chuyển sang thanh toán tại quầy. Vui lòng đến sớm 15 phút để làm thủ tục nhận sân.\"}");
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi chuyển thanh toán tại quầy DatSanID=" + datSanId, e);
            resp.getWriter().write("{\"success\":false,\"errorCode\":\"INTERNAL_ERROR\",\"message\":\"Có lỗi xảy ra. Vui lòng thử lại.\"}");
        }
    }

    private String resolveBaseUrl(HttpServletRequest req) {
        String scheme = req.getScheme();
        String serverName = req.getServerName();
        int port = req.getServerPort();
        String ctx = req.getContextPath();
        boolean defaultPort = (scheme.equals("http") && port == 80) || (scheme.equals("https") && port == 443);
        return scheme + "://" + serverName + (defaultPort ? "" : ":" + port) + ctx;
    }

    private Integer parseIntParam(String s) {
        if (s == null || s.isBlank()) return null;
        try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return null; }
    }

    /**
     * Lưu snapshot QR PayOS cho một booking để trang QR nhúng của V-SPORT render lại được mà không
     * gọi lại PayOS: (1) HttpSession holder — dùng ngay, không phụ thuộc migration; (2) best-effort
     * UPDATE các cột cache trên LichDatSan — bền vững qua reload/đa tab, BỎ QUA êm nếu cột chưa tồn
     * tại (chưa chạy migrate_customer_embedded_payos_payment.sql). Chạy trên connection RIÊNG (auto-
     * commit) nên không ảnh hưởng transaction đặt sân. Không bao giờ log payload/secret.
     */
    private void stashAndPersistQr(HttpSession session, int datSanId, PayOSCheckoutSession s,
                                   long amount, String description) {
        Long orderCode = s.orderCode != null ? s.orderCode : (long) datSanId;
        PayosQrData data = new PayosQrData(datSanId, orderCode, s.paymentLinkId, s.qrCode, s.checkoutUrl,
                s.bin, s.accountNumber, s.accountName, amount, description, s.expiredAt);
        session.setAttribute(PayosQrData.sessionKey(datSanId), data);

        String sql = "UPDATE LichDatSan SET PayosOrderCode=?, PayosPaymentLinkId=?, PayosQrPayload=?, "
                + "PayosCheckoutUrl=?, PayosBin=?, PayosAccountNumber=?, PayosAccountName=?, PayosAmount=?, "
                + "PayosDescription=?, PayosExpiresAt=? WHERE DatSanID=?";
        try (java.sql.Connection c = DBUtil.getConnection();
             java.sql.PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, orderCode);
            ps.setString(2, s.paymentLinkId);
            ps.setString(3, s.qrCode);
            ps.setString(4, s.checkoutUrl);
            ps.setString(5, s.bin);
            ps.setString(6, s.accountNumber);
            ps.setString(7, s.accountName);
            ps.setBigDecimal(8, BigDecimal.valueOf(amount));
            ps.setString(9, description);
            // PayosExpiresAt là instant → lưu UTC nhất quán với HoldExpiresAt (qua TimeUtil).
            ps.setTimestamp(10, s.expiredAt != null
                    ? org.example.util.TimeUtil.toDb(java.time.Instant.ofEpochSecond(s.expiredAt)) : null);
            ps.setInt(11, datSanId);
            ps.executeUpdate();
        } catch (SQLException e) {
            // Cột cache chưa tồn tại (chưa migrate) hoặc lỗi ghi cache - không nghiêm trọng: session
            // holder vẫn cho trang QR hoạt động trong phiên hiện tại.
            LOGGER.fine("QR cache persist bỏ qua (có thể chưa chạy migration) datSanId=" + datSanId);
        }
    }

    // =========================================================================
    // PHẦN 5C: TẠO PAYMENT LINK PAYOS THEO CƠ SỞ (thay thế PayOSService singleton dùng biến môi trường)
    // =========================================================================

    private static final String MSG_NOT_CONFIGURED = "Thanh toán trực tuyến hiện chưa khả dụng tại cơ sở này. Bạn có thể chọn thanh toán tại quầy.";
    private static final String MSG_PROVIDER_ERROR = "PayOS đang tạm thời không phản hồi. Vui lòng thử lại sau hoặc chọn thanh toán tại quầy.";
    private static final String MSG_NETWORK_ERROR = "Không thể kết nối đến cổng thanh toán PayOS. Vui lòng thử lại hoặc chọn thanh toán tại quầy.";
    private static final String MSG_EXPIRED = "Phiên thanh toán đã hết hạn. Vui lòng tạo lại yêu cầu thanh toán.";
    private static final String MSG_UNKNOWN = "Không thể tạo liên kết thanh toán lúc này. Vui lòng thử lại hoặc chọn thanh toán tại quầy.";

    /** Kết quả nội bộ khi thử tạo/tái tạo payment link PayOS cho một booking cụ thể. */
    private static final class PayOSLinkResult {
        final boolean success;
        final PayOSCheckoutSession session;
        final String errorCode;
        final String message;
        final boolean retryable;

        private PayOSLinkResult(boolean success, PayOSCheckoutSession session, String errorCode, String message, boolean retryable) {
            this.success = success;
            this.session = session;
            this.errorCode = errorCode;
            this.message = message;
            this.retryable = retryable;
        }

        static PayOSLinkResult ok(PayOSCheckoutSession session) { return new PayOSLinkResult(true, session, null, null, false); }
        static PayOSLinkResult fail(String errorCode, String message, boolean retryable) {
            return new PayOSLinkResult(false, null, errorCode, message, retryable);
        }
    }

    /**
     * Tạo (hoặc, nếu cancelExistingFirst=true, hủy link cũ rồi tạo lại) payment link PayOS cho
     * một booking, dùng credentials RIÊNG của cơ sở (coSoId) đọc từ database qua
     * PayOSConfigurationService — KHÔNG dùng biến môi trường toàn cục
     * (PAYOS_CLIENT_ID/PAYOS_API_KEY/PAYOS_CHECKSUM_KEY không còn được đọc ở đây). Không bao giờ
     * log Client ID/API Key/Checksum Key - chỉ log trạng thái có/không cấu hình.
     */
    private PayOSLinkResult createFacilityPayOSLink(int coSoId, long orderCode, long amount, String description,
                                                      String returnUrl, String cancelUrl, boolean cancelExistingFirst) {
        PayOSCredentials credentials = new PayOSConfigurationService().getCredentialsForPayment(coSoId);
        if (credentials == null) {
            LOGGER.warning(String.format("PAYOS_NOT_CONFIGURED facilityId=%d orderCode=%d", coSoId, orderCode));
            return PayOSLinkResult.fail("PAYOS_NOT_CONFIGURED", MSG_NOT_CONFIGURED, false);
        }

        PayOS client = PayOSClientFactory.create(credentials);
        try {
            if (cancelExistingFirst) {
                try {
                    client.paymentRequests().cancel(orderCode, "Khách yêu cầu tạo lại liên kết thanh toán");
                } catch (Exception ignoredNoExistingLink) {
                    // Không có link cũ để hủy (chưa từng tạo, hoặc đã hết hạn/hủy sẵn) - bỏ qua, tiếp tục tạo mới.
                }
            }
            CreatePaymentLinkRequest request = CreatePaymentLinkRequest.builder()
                    .orderCode(orderCode)
                    .amount(amount)
                    .description(description)
                    .returnUrl(returnUrl)
                    .cancelUrl(cancelUrl)
                    .build();
            CreatePaymentLinkResponse result = client.paymentRequests().create(request);
            return PayOSLinkResult.ok(new PayOSCheckoutSession(
                    result.getCheckoutUrl(), result.getQrCode(), result.getExpiredAt(), result.getAmount(),
                    result.getBin(), result.getAccountNumber(), result.getAccountName(),
                    result.getDescription(), result.getOrderCode(), result.getPaymentLinkId()));
        } catch (ConnectionTimeoutException | ConnectionException e) {
            logPayOSFailure("PAYOS_NETWORK_ERROR", coSoId, orderCode, amount, e, null);
            return PayOSLinkResult.fail("PAYOS_NETWORK_ERROR", MSG_NETWORK_ERROR, true);
        } catch (APIException e) {
            Integer status = e.getStatusCode().orElse(null);
            String payosCode = e.getErrorCode().orElse(null);
            String payosDesc = e.getErrorDesc().orElse(null);
            String bucket; String customerMsg; boolean retryable;
            if (status != null && (status == 401 || status == 403)) {
                // Sai/hết hạn Client ID hoặc API Key - KHÔNG lộ chi tiết cho khách, chỉ ghi log server.
                bucket = "PAYOS_INVALID_CREDENTIAL"; customerMsg = MSG_PROVIDER_ERROR; retryable = true;
            } else if (status != null && status == 400) {
                // Best-effort: PayOS thường trả 400 kèm mô tả nhắc "order code" khi orderCode đã tồn tại/trùng.
                boolean looksLikeDuplicateOrderCode = payosDesc != null
                        && (payosDesc.toLowerCase().contains("order") || payosDesc.toLowerCase().contains("code"));
                bucket = looksLikeDuplicateOrderCode ? "PAYOS_DUPLICATE_ORDER_CODE" : "PAYOS_REQUEST_INVALID";
                customerMsg = looksLikeDuplicateOrderCode ? MSG_EXPIRED : MSG_UNKNOWN;
                retryable = !looksLikeDuplicateOrderCode;
            } else if (status != null && (status == 429 || status >= 500)) {
                bucket = "PAYOS_PROVIDER_ERROR"; customerMsg = MSG_PROVIDER_ERROR; retryable = true;
            } else {
                bucket = "PAYOS_PROVIDER_ERROR"; customerMsg = MSG_PROVIDER_ERROR; retryable = true;
            }
            logPayOSFailure(bucket, coSoId, orderCode, amount, e,
                    String.format("httpStatus=%s payosErrorCode=%s payosErrorDesc=%s", status, payosCode, payosDesc));
            return PayOSLinkResult.fail(bucket, customerMsg, retryable);
        } catch (Exception e) {
            logPayOSFailure("PAYOS_UNKNOWN_ERROR", coSoId, orderCode, amount, e, null);
            return PayOSLinkResult.fail("PAYOS_UNKNOWN_ERROR", MSG_UNKNOWN, true);
        } finally {
            client.close();
        }
    }

    /** Log an toàn: loại lỗi + facilityId + orderCode + amount + tên class exception + chi tiết PayOS
     * (status/errorCode/errorDesc do PayOS trả về - KHÔNG PHẢI secret). Không bao giờ log Client
     * ID/API Key/Checksum Key. */
    private void logPayOSFailure(String errorCode, int coSoId, long orderCode, long amount, Exception e, String payosDetail) {
        LOGGER.log(Level.SEVERE, String.format(
                "PAYOS_CREATE_FAILED errorCode=%s facilityId=%d orderCode=%d amount=%d exceptionType=%s%s",
                errorCode, coSoId, orderCode, amount, e.getClass().getSimpleName(),
                payosDetail != null ? " " + payosDetail : ""));
    }

    private static String jsonEscape(String s) {
        return s == null ? "" : s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    // =========================================================================
    // PHẦN 6: UTILITY METHODS
    // =========================================================================

    /**
     * Kiểm tra xem một SQLException có phải là lỗi deadlock hay không.
     * SQL Server deadlock error code = 1205.
     * Phương thức kiểm tra cả chuỗi cause chain để bắt wrapped exceptions.
     */
    private boolean isBookingPage(String path) {
        return "/customer/dat-san".equals(path) || "/customer/dat_san".equals(path) || "/customer/chi-tiet-san".equals(path);
    }

    private boolean isDeadlockException(SQLException ex) {
        // Duyệt chuỗi exception để tìm lỗi deadlock
        SQLException current = ex;
        while (current != null) {
            if (current.getErrorCode() == SQL_DEADLOCK_ERROR_CODE) {
                return true;
            }
            current = current.getNextException();
        }
        // Kiểm tra thêm thông điệp lỗi (phòng hờ JDBC driver wrap lỗi)
        return ex.getMessage() != null && ex.getMessage().toLowerCase().contains("deadlock");
    }

    /**
     * Tạm dừng ngắn trước khi retry để giảm xung đột với transaction đang chạy.
     * Thời gian dừng tăng dần: attempt=1 → 50-150ms, attempt=2 → 100-300ms, v.v.
     * Thêm thành phần ngẫu nhiên (jitter) để tránh nhiều thread retry cùng lúc.
     */
    private void sleepBeforeRetry(int attempt) {
        try {
            long baseMs = 50L * attempt;
            long jitterMs = (long) (Math.random() * 100 * attempt);
            Thread.sleep(baseMs + jitterMs);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt(); // Khôi phục trạng thái interrupt
        }
    }

    private void handleGetDichVu(HttpServletRequest req, HttpServletResponse resp, TaiKhoan user)
            throws ServletException, IOException {
        try {
            int datSanId = Integer.parseInt(req.getParameter("datSanId"));
            Lichdatsan lich = lichDatSanDAO.getLichById(datSanId);
            if (lich == null || lich.getAccountId() != user.getAccountId()) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền truy cập đơn đặt này.");
                return;
            }

            San san = sanDAO.getSanById(lich.getSanId());
            int coSoId = san.getCoSoID();

            org.example.dao.SanPhamDichVuDAO spDao = new org.example.dao.impl.SanPhamDichVuDAOImpl();
            List<org.example.model.SanPham_DichVu> allSp = spDao.findByCoSo(coSoId);
            List<org.example.model.SanPham_DichVu> products = allSp.stream()
                .filter(sp -> "Đang kinh doanh".equals(sp.getTrangThai()))
                .collect(java.util.stream.Collectors.toList());

            org.example.dao.HoaDonDAO hdDao = new org.example.dao.impl.HoaDonDAOImpl();
            int hoaDonId = -1;
            try (java.sql.Connection conn = org.example.util.DBUtil.getConnection();
                 java.sql.PreparedStatement ps = conn.prepareStatement("SELECT HoaDonID FROM HoaDon WHERE DatSanID = ?")) {
                ps.setInt(1, datSanId);
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        hoaDonId = rs.getInt("HoaDonID");
                    }
                }
            }

            List<org.example.model.ChiTietHoaDon> ordered = new java.util.ArrayList<>();
            if (hoaDonId != -1) {
                ordered = hdDao.getChiTietByHoaDonId(hoaDonId);
            }

            // Build plain maps to avoid Gson serializing lazy JPA relationships
            List<java.util.Map<String, Object>> productMaps = new java.util.ArrayList<>();
            for (org.example.model.SanPham_DichVu sp : products) {
                java.util.Map<String, Object> m = new java.util.HashMap<>();
                m.put("SanPhamID", sp.getSanPhamID());
                m.put("TenSanPham", sp.getTenSanPham());
                m.put("DonGia", sp.getDonGia());
                m.put("DonViTinh", sp.getDonViTinh());
                m.put("SoLuongTon", sp.getSoLuongTon());
                productMaps.add(m);
            }

            List<java.util.Map<String, Object>> orderedMaps = new java.util.ArrayList<>();
            for (org.example.model.ChiTietHoaDon ct : ordered) {
                java.util.Map<String, Object> m = new java.util.HashMap<>();
                m.put("SanPhamID", ct.getSanPhamID());
                m.put("SoLuong", ct.getSoLuong());
                orderedMaps.add(m);
            }

            resp.setContentType("application/json;charset=UTF-8");
            java.util.Map<String, Object> data = new java.util.HashMap<>();
            data.put("products", productMaps);
            data.put("ordered", orderedMaps);
            resp.getWriter().write(gson.toJson(data));
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi lấy danh sách dịch vụ", e);
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, e.getMessage());
        }
    }

    private void handlePostDatDichVu(HttpServletRequest req, HttpServletResponse resp, HttpSession session, TaiKhoan user)
            throws ServletException, IOException {
        try {
            int datSanId = Integer.parseInt(req.getParameter("datSanId"));
            Lichdatsan lich = lichDatSanDAO.getLichById(datSanId);
            if (lich == null || lich.getAccountId() != user.getAccountId()) {
                session.setAttribute("error", "Bạn không có quyền truy cập đơn đặt này.");
                resp.sendRedirect(req.getContextPath() + "/customer/dat-san?openHistory=true");
                return;
            }

            // Parse selected services
            String[] spIdsStr = req.getParameterValues("productId");
            String[] qtysStr = req.getParameterValues("quantity");

            int[] productIds = new int[0];
            int[] quantities = new int[0];

            if (spIdsStr != null && qtysStr != null) {
                int count = spIdsStr.length;
                productIds = new int[count];
                quantities = new int[count];
                for (int i = 0; i < count; i++) {
                    productIds[i] = Integer.parseInt(spIdsStr[i]);
                    quantities[i] = Integer.parseInt(qtysStr[i]);
                }
            }

            // Update services
            lichDatSanDAO.updateDichVuDatSan(datSanId, productIds, quantities);
            session.setAttribute("message", "Cập nhật dịch vụ đặt thêm thành công!");
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi cập nhật dịch vụ đặt thêm", e);
            session.setAttribute("error", "Lỗi: " + e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/customer/dat-san?openHistory=true");
    }

    private void handleGetChiTietSan(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            int sanId = Integer.parseInt(req.getParameter("id"));
            San san = sanDAO.getSanById(sanId);
            if (san == null) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy sân đấu.");
                return;
            }
            
            LoaiSan loai = loaiSanDAO.getLoaiSanById(san.getLoaiSanID());
            org.example.model.CoSo coSo = coSoDAO.getCoSoById(san.getCoSoID());
            
            List<org.example.model.CoSo> allCoSo = coSoDAO.getAllCoSo();
            List<LoaiSan> allLoaiSan = loaiSanDAO.getAllLoaiSan();
            List<MonTheThao> dsMon = loaiSanDAO.getAllMonTheThao();
            
            String tenMon = dsMon.stream()
                    .filter(m -> m.getMonTheThaoID() == loai.getMonTheThaoID())
                    .map(MonTheThao::getTenMon)
                    .findFirst()
                    .orElse("Khác");
            
            long totalSimilarCourts = sanDAO.countSansByLoaiSanId(san.getLoaiSanID());
            
            // Get other courts (excluding the current one)
            List<San> otherSans = sanDAO.getAllSan().stream()
                    .filter(s -> s.getSanID() != sanId)
                    .collect(java.util.stream.Collectors.toList());
            
            req.setAttribute("san", san);
            req.setAttribute("loai", loai);
            req.setAttribute("coSo", coSo);
            req.setAttribute("tenMon", tenMon);
            req.setAttribute("totalSimilarCourts", totalSimilarCourts);
            req.setAttribute("dsCoSo", allCoSo);
            req.setAttribute("dsLoaiSan", allLoaiSan);
            req.setAttribute("dsMon", dsMon);
            req.setAttribute("otherSans", otherSans);
            
            List<Lichdatsan> activeBookings = lichDatSanDAO.getAllLichDatSan();
            req.setAttribute("activeBookings", activeBookings);
            
            req.getRequestDispatcher("/customer/ChiTietSan.jsp").forward(req, resp);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Lỗi khi lấy chi tiết sân", e);
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, e.getMessage());
        }
    }
}
