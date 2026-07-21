package org.example.controller.customer;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.dao.CoSoDAO;
import org.example.dao.LichDatSanDAO;
import org.example.dao.LoaiSanDAO;
import org.example.dao.SanDAO;
import org.example.dao.TaiKhoanDAO;
import org.example.dao.impl.CoSoDAOImpl;
import org.example.dao.impl.LichDatSanDAOImpl;
import org.example.dao.impl.LoaiSanDAOImpl;
import org.example.dao.impl.SanDAOImpl;
import org.example.dao.impl.TaiKhoanDAOImpl;
import org.example.model.CoSo;
import org.example.model.LoaiSan;
import org.example.model.Lichdatsan;
import org.example.model.San;
import org.example.model.TaiKhoan;
import org.example.util.RoleRedirectUtil;
import org.mindrot.jbcrypt.BCrypt;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Trang "Tài khoản của tôi" cho Customer: hồ sơ cá nhân, thống kê đặt sân,
 * lịch sắp tới gần nhất. Chỉnh sửa hồ sơ / đổi mật khẩu dùng chung
 * UpdateProfileServlet (/account/update-profile) đã có sẵn cho toàn hệ thống.
 */
@WebServlet("/customer/tai-khoan")
public class CustomerAccountServlet extends HttpServlet {

    private static final Logger logger = LogManager.getLogger(CustomerAccountServlet.class);
    private static final String TRANG_THAI_HUY = "Đã hủy";
    private static final String TRANG_THAI_HOAN_THANH = "Đã hoàn thành";

    private final TaiKhoanDAO taiKhoanDAO = new TaiKhoanDAOImpl();
    private final LichDatSanDAO lichDatSanDAO = new LichDatSanDAOImpl();
    private final SanDAO sanDAO = new SanDAOImpl();
    private final CoSoDAO coSoDAO = new CoSoDAOImpl();
    private final LoaiSanDAO loaiSanDAO = new LoaiSanDAOImpl();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        TaiKhoan sessionUser = session != null ? (TaiKhoan) session.getAttribute("user") : null;

        if (sessionUser == null) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        if (sessionUser.getRoleId() != RoleRedirectUtil.ROLE_CUSTOMER) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Trang này chỉ dành cho tài khoản Khách hàng.");
            return;
        }

        // Luôn nạp lại tài khoản từ DB (không tin dữ liệu cũ trong session,
        // không nhận AccountID từ tham số request để tránh xem hồ sơ người khác).
        TaiKhoan account = taiKhoanDAO.getAccountById(sessionUser.getAccountId());
        if (account == null || account.isDeleted() || account.isLocked()) {
            session.invalidate();
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        List<Lichdatsan> dsLich = lichDatSanDAO.getLichByAccountId(account.getAccountId());

        int upcomingCount = 0;
        int completedCount = 0;
        int cancelledCount = 0;
        Lichdatsan nearestBooking = null;
        LocalDateTime now = LocalDateTime.now();
        List<Lichdatsan> upcomingBookings = new ArrayList<>();

        for (Lichdatsan lich : dsLich) {
            String trangThai = lich.getTrangThai();
            if (TRANG_THAI_HUY.equals(trangThai)) {
                cancelledCount++;
                continue;
            }
            if (TRANG_THAI_HOAN_THANH.equals(trangThai)) {
                completedCount++;
                continue;
            }
            if (lich.getNgayDat() == null || lich.getGioKetThuc() == null) {
                continue;
            }
            LocalDateTime end = LocalDateTime.of(lich.getNgayDat(), lich.getGioKetThuc());
            if (end.isAfter(now)) {
                upcomingCount++;
                upcomingBookings.add(lich);
                if (nearestBooking == null) {
                    nearestBooking = lich;
                } else {
                    LocalDateTime currentStart = LocalDateTime.of(nearestBooking.getNgayDat(), nearestBooking.getGioBatDau());
                    LocalDateTime candidateStart = LocalDateTime.of(lich.getNgayDat(), lich.getGioBatDau());
                    if (candidateStart.isBefore(currentStart)) {
                        nearestBooking = lich;
                    }
                }
            }
        }

        // "Danh sách đặt lịch" (view mặc định): tối đa 5 lịch sắp tới, gần nhất trước.
        upcomingBookings.sort(Comparator.comparing(l -> LocalDateTime.of(l.getNgayDat(), l.getGioBatDau())));
        if (upcomingBookings.size() > 5) {
            upcomingBookings = new ArrayList<>(upcomingBookings.subList(0, 5));
        }
        Map<Integer, String> upcomingSanNames = new HashMap<>();
        Map<Integer, String> upcomingCoSoNames = new HashMap<>();
        for (Lichdatsan lich : upcomingBookings) {
            Integer sanId = lich.getSanId();
            if (sanId == null || upcomingSanNames.containsKey(sanId)) {
                continue;
            }
            try {
                San san = sanDAO.getSanById(sanId);
                if (san != null) {
                    upcomingSanNames.put(sanId, san.getTenSan());
                    CoSo coSo = coSoDAO.getCoSoById(san.getCoSoID());
                    if (coSo != null) {
                        upcomingCoSoNames.put(sanId, coSo.getTenCoSo());
                    }
                }
            } catch (Exception e) {
                logger.warn("Không thể tải thông tin sân SanID={} cho danh sách đặt lịch: {}", sanId, e.getMessage());
            }
        }

        San nearestSan = null;
        CoSo nearestCoSo = null;
        LoaiSan nearestLoaiSan = null;
        if (nearestBooking != null && nearestBooking.getSanId() != null) {
            try {
                nearestSan = sanDAO.getSanById(nearestBooking.getSanId());
                if (nearestSan != null) {
                    nearestCoSo = coSoDAO.getCoSoById(nearestSan.getCoSoID());
                    nearestLoaiSan = loaiSanDAO.getLoaiSanById(nearestSan.getLoaiSanID());
                }
            } catch (Exception e) {
                logger.warn("Không thể tải thông tin sân cho lịch gần nhất DatSanID={}: {}",
                        nearestBooking.getDatSanId(), e.getMessage());
            }
        }

        // Booking sắp diễn ra, đã xác nhận và chưa hủy/hoàn thành/không đến -> đủ điều kiện "Tìm đối thủ gấp".
        boolean nearestBookingUrgentEligible = nearestBooking != null
                && "Đã xác nhận".equals(nearestBooking.getTrangThai());

        req.setAttribute("account", account);
        req.setAttribute("totalBookings", dsLich.size());
        req.setAttribute("upcomingCount", upcomingCount);
        req.setAttribute("completedCount", completedCount);
        req.setAttribute("cancelledCount", cancelledCount);
        req.setAttribute("nearestBooking", nearestBooking);
        req.setAttribute("nearestSan", nearestSan);
        req.setAttribute("nearestCoSo", nearestCoSo);
        req.setAttribute("nearestLoaiSan", nearestLoaiSan);
        req.setAttribute("nearestBookingUrgentEligible", nearestBookingUrgentEligible);
        req.setAttribute("upcomingBookings", upcomingBookings);
        req.setAttribute("upcomingSanNames", upcomingSanNames);
        req.setAttribute("upcomingCoSoNames", upcomingCoSoNames);

        req.getRequestDispatcher("/customer/TaiKhoan.jsp").forward(req, resp);
    }

    /**
     * Xử lý hành động "Xóa tài khoản" từ trang Cài đặt. Route riêng cho
     * Customer (không dùng chung UpdateProfileServlet vốn phục vụ cả
     * admin/manager/staff) để không đổi hành vi của các role khác. Chỉ hỗ trợ
     * action=deleteAccount — xóa mềm (soft-delete), có thể khôi phục qua
     * TaiKhoanDAO#restoreAccount, không xóa vĩnh viễn dữ liệu.
     */
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        HttpSession session = req.getSession(false);
        TaiKhoan sessionUser = session != null ? (TaiKhoan) session.getAttribute("user") : null;
        if (sessionUser == null) {
            resp.getWriter().write("{\"success\":false,\"message\":\"Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.\"}");
            return;
        }
        if (sessionUser.getRoleId() != RoleRedirectUtil.ROLE_CUSTOMER) {
            resp.getWriter().write("{\"success\":false,\"message\":\"Trang này chỉ dành cho tài khoản Khách hàng.\"}");
            return;
        }
        if (!"deleteAccount".equals(req.getParameter("action"))) {
            resp.getWriter().write("{\"success\":false,\"message\":\"Hành động không hợp lệ.\"}");
            return;
        }

        String password = req.getParameter("password");
        if (password == null || password.isEmpty()) {
            resp.getWriter().write("{\"success\":false,\"message\":\"Vui lòng nhập mật khẩu hiện tại.\"}");
            return;
        }

        try {
            TaiKhoan account = taiKhoanDAO.getAccountById(sessionUser.getAccountId());
            if (account == null) {
                resp.getWriter().write("{\"success\":false,\"message\":\"Không tìm thấy tài khoản trong hệ thống.\"}");
                return;
            }
            if (!BCrypt.checkpw(password, account.getPassword())) {
                resp.getWriter().write("{\"success\":false,\"message\":\"Mật khẩu hiện tại không chính xác.\"}");
                return;
            }
            boolean ok = taiKhoanDAO.softDeleteAccount(account.getAccountId(), account.getAccountId());
            if (!ok) {
                resp.getWriter().write("{\"success\":false,\"message\":\"Không thể xóa tài khoản lúc này. Vui lòng thử lại.\"}");
                return;
            }
            session.invalidate();
            resp.getWriter().write("{\"success\":true,\"message\":\"Đã xóa tài khoản.\"}");
        } catch (Exception e) {
            logger.error("Lỗi xóa tài khoản accountId={}: {}", sessionUser.getAccountId(), e.getMessage(), e);
            resp.getWriter().write("{\"success\":false,\"message\":\"Lỗi hệ thống. Vui lòng thử lại sau.\"}");
        }
    }
}
