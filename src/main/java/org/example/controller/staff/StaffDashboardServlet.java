package org.example.controller.staff;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.model.TaiKhoan;
import org.example.dao.TaiKhoanDAO;
import org.example.dao.impl.TaiKhoanDAOImpl;
import org.example.dao.CaLamViecDAO;
import org.example.dao.impl.CaLamViecDAOImpl;
import org.example.dao.SanDAO;
import org.example.dao.impl.SanDAOImpl;
import org.example.dao.DatSanDAO;
import org.example.dao.impl.DatSanDAOImpl;
import org.example.dao.HoaDonDAO;
import org.example.dao.impl.HoaDonDAOImpl;
import org.example.dao.LichDatSanDAO;
import org.example.dao.impl.LichDatSanDAOImpl;
import org.example.service.manager.NhanSuService;
import org.example.model.Lichdatsan;
import org.example.model.HoaDon;
import org.example.model.San;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Servlet điều hướng Dashboard cho Staff/Lễ tân (role 4 & 5)
 */
@WebServlet("/staff/dashboard")
public class StaffDashboardServlet extends HttpServlet {

    private final SanDAO sanDAO = new SanDAOImpl();
    private final HoaDonDAO hoaDonDAO = new HoaDonDAOImpl();
    private final LichDatSanDAO lichDatSanDAO = new LichDatSanDAOImpl();
    private final NhanSuService nhanSuService = new NhanSuService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");

        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/he-thong/dang-nhap");
            return;
        }

        // Quyền Lễ tân (4) hoặc Bảo vệ (5)
        if (user.getRoleId() != 4 && user.getRoleId() != 5) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền truy cập trang này.");
            return;
        }

        if (user.getCoSoId() == null) {
            session.setAttribute("error", "Tài khoản của bạn chưa được gán chi nhánh cơ sở.");
            resp.sendRedirect(req.getContextPath() + "/he-thong/dang-nhap");
            return;
        }

        // Lấy thông tin dashboard cho Staff
        Map<String, Object> dashboardData = getDashboardData(user);

        // Đặt dữ liệu vào request
        req.setAttribute("pageTitle", "Tổng quan Vận hành — V-SPORT");
        req.setAttribute("userFullName", user.getFullName() != null ? user.getFullName() : user.getUsername());
        req.setAttribute("userRole", user.getRoleId() == 4 ? "Lễ tân chi nhánh" : "Bảo vệ chi nhánh");
        req.setAttribute("dashboardData", dashboardData);
        req.setAttribute("currentPage", "dashboard");

        // Forward tới JSP dashboard của Staff
        req.getRequestDispatcher("/staff/Dashboard.jsp").forward(req, resp);
    }

    /**
     * Lấy dữ liệu thống kê cho dashboard tương tự manager
     */
    private Map<String, Object> getDashboardData(TaiKhoan user) {
        Map<String, Object> data = new HashMap<>();
        Integer coSoId = user.getCoSoId();

        if (coSoId == null) {
            return data;
        }

        try {
            // Thống kê sân của cơ sở
            List<San> dsSan = sanDAO.getSansByCoSo(coSoId);
            long totalFields = dsSan.size();
            long activeFields = dsSan.stream()
                .filter(s -> "Sẵn sàng".equals(s.getTrangThai()) || "Đang dùng".equals(s.getTrangThai()))
                .count();

            // Thống kê đặt sân hôm nay của cơ sở
            List<Lichdatsan> dsLichToday = lichDatSanDAO.getLichDatSanTodayByCoSo(coSoId);
            long bookingsTodayCount = dsLichToday.size();

            // Thống kê doanh thu hôm nay của cơ sở
            BigDecimal revenueToday = hoaDonDAO.getRevenueTodayByCoSo(coSoId);

            // Thống kê tổng doanh thu của cơ sở
            BigDecimal totalRevenue = hoaDonDAO.getTotalDoanhThuByCoSo(coSoId);

            // Thống kê nhân viên của cơ sở
            long totalStaff = 0;
            List<?> staffList = nhanSuService.getStaffListByBranch(coSoId);
            if (staffList != null) {
                totalStaff = staffList.size();
            }

            // Danh sách hóa đơn gần đây (limit 5)
            List<HoaDon> recentInvoices = hoaDonDAO.getRecentInvoicesByCoSo(coSoId, 5);

            data.put("totalFields", totalFields);
            data.put("activeFields", activeFields);
            data.put("bookingsTodayCount", bookingsTodayCount);
            data.put("revenueToday", revenueToday);
            data.put("totalRevenue", totalRevenue);
            data.put("totalStaff", totalStaff);
            data.put("recentInvoices", recentInvoices);
            data.put("todayBookingsList", dsLichToday);

            // Thêm dữ liệu giả lập cho biểu đồ tương tự manager
            data.put("revenueChart", getRevenueChartData());
            data.put("bookingChart", getBookingChartData());
            data.put("shiftChart", getShiftChartData());

        } catch (Exception e) {
            System.err.println("Error getting staff dashboard data: " + e.getMessage());
            e.printStackTrace();
        }

        return data;
    }

    private Map<String, Object> getRevenueChartData() {
        Map<String, Object> chartData = new HashMap<>();
        chartData.put("type", "line");
        chartData.put("labels", new String[]{"Tuần 1", "Tuần 2", "Tuần 3", "Tuần 4", "Tuần 5"});
        chartData.put("data", new double[]{1200, 1900, 2200, 2400, 2600});
        chartData.put("title", "Doanh thu theo tuần (triệu VNĐ)");
        return chartData;
    }

    private Map<String, Object> getBookingChartData() {
        Map<String, Object> chartData = new HashMap<>();
        chartData.put("type", "bar");
        chartData.put("labels", new String[]{"Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ nhật"});
        chartData.put("data", new int[]{25, 30, 22, 28, 35, 42, 38});
        chartData.put("title", "Số lượt đặt sân theo ngày trong tuần");
        return chartData;
    }

    private Map<String, Object> getShiftChartData() {
        Map<String, Object> chartData = new HashMap<>();
        chartData.put("type", "doughnut");
        chartData.put("labels", new String[]{"Ca sáng", "Ca chiều", "Ca tối", "Ca đêm"});
        chartData.put("data", new int[]{45, 35, 15, 5});
        chartData.put("title", "Phân bổ ca làm việc");
        return chartData;
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        doGet(req, resp);
    }
}
