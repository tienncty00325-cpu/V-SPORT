package org.example.controller.manager;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.example.model.TaiKhoan;
import org.example.service.AuditLogService;
import org.example.util.DBUtil;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;
import java.sql.*;
import java.util.*;

@WebServlet("/manager/hoa-don")
public class HoaDonManagerServlet extends HttpServlet {

    private static final Logger logger = LogManager.getLogger(HoaDonManagerServlet.class);
    private static final com.google.gson.Gson gson = new com.google.gson.Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        TaiKhoan user = (TaiKhoan) req.getSession().getAttribute("user");
        if (user == null || user.getRoleId() != 2) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        String action = req.getParameter("action");
        if ("detail".equals(action)) {
            handleDetail(req, resp, user);
            return;
        }
        if ("stats".equals(action)) {
            handleStats(req, resp, user);
            return;
        }

        // Default: load invoice list
        String filterStatus = req.getParameter("filterStatus");
        String filterLoai    = req.getParameter("filterLoai");
        String filterFrom    = req.getParameter("filterFrom");
        String filterTo      = req.getParameter("filterTo");
        String filterSearch  = req.getParameter("filterSearch");
        String pageStr       = req.getParameter("page");
        int page = 1;
        try { if (pageStr != null) page = Math.max(1, Integer.parseInt(pageStr)); } catch (NumberFormatException ignored) {}
        int pageSize = 20;
        int offset   = (page - 1) * pageSize;

        List<Map<String, Object>> invoices = new ArrayList<>();
        int totalCount = 0;
        Map<String, Object> stats = new HashMap<>();

        try (Connection conn = DBUtil.getConnection()) {
            boolean hasLoaiHoaDon = columnExists(conn, "HoaDon", "LoaiHoaDon");
            boolean hasParentHoaDonID = columnExists(conn, "HoaDon", "ParentHoaDonID");
            boolean hasGhiChu = columnExists(conn, "HoaDon", "GhiChu");
            // Stats
            String sqlStats = buildStatsSql(hasLoaiHoaDon);
            try (PreparedStatement ps = conn.prepareStatement(sqlStats)) {
                ps.setInt(1, user.getCoSoId());
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        stats.put("totalCount",    rs.getInt("totalCount"));
                        stats.put("tongDoanhThu",  rs.getDouble("tongDoanhThu"));
                        stats.put("mainChuaTT",    rs.getInt("mainChuaTT"));
                        stats.put("splitChuaTT",   rs.getInt("splitChuaTT"));
                    }
                }
            }

            // Build WHERE clause
            StringBuilder where = new StringBuilder(
                "WHERE s.CoSoID = ? ");
            List<Object> params = new ArrayList<>();
            params.add(user.getCoSoId());

            if (filterStatus != null && !filterStatus.isEmpty()) {
                where.append("AND hd.TrangThaiThanhToan = ? ");
                params.add(filterStatus);
            }
            if (filterLoai != null && !filterLoai.isEmpty()) {
                if (!hasLoaiHoaDon) {
                    if (!"MAIN".equals(filterLoai)) {
                        where.append("AND 1 = 0 ");
                    }
                } else if ("MAIN".equals(filterLoai)) {
                    where.append("AND (hd.LoaiHoaDon = N'MAIN' OR hd.LoaiHoaDon IS NULL) ");
                } else {
                    where.append("AND hd.LoaiHoaDon = ? ");
                    params.add(filterLoai);
                }
            }
            if (filterFrom != null && !filterFrom.isEmpty()) {
                where.append("AND CAST(hd.NgayLap AS DATE) >= ? ");
                params.add(filterFrom);
            }
            if (filterTo != null && !filterTo.isEmpty()) {
                where.append("AND CAST(hd.NgayLap AS DATE) <= ? ");
                params.add(filterTo);
            }
            if (filterSearch != null && !filterSearch.trim().isEmpty()) {
                where.append("AND (CAST(hd.HoaDonID AS NVARCHAR) LIKE ? OR acc.FullName LIKE ? OR s.TenSan LIKE ?) ");
                String like = "%" + filterSearch.trim() + "%";
                params.add(like); params.add(like); params.add(like);
            }

            String baseQuery =
                "FROM HoaDon hd " +
                "INNER JOIN LichDatSan lds ON hd.DatSanID = lds.DatSanID " +
                "INNER JOIN San s ON lds.SanID = s.SanID " +
                "LEFT JOIN Accounts acc ON lds.AccountID = acc.AccountID " +
                "LEFT JOIN Accounts nv ON hd.AccountID_NhanVien = nv.AccountID " +
                where;

            // Count
            String sqlCount = "SELECT COUNT(*) " + baseQuery;
            try (PreparedStatement ps = conn.prepareStatement(sqlCount)) {
                for (int i = 0; i < params.size(); i++) {
                    ps.setObject(i + 1, params.get(i));
                }
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) totalCount = rs.getInt(1);
                }
            }

            // Data
            String sqlList =
                "SELECT hd.HoaDonID, hd.DatSanID, hd.NgayLap, hd.TongTienSan, hd.TongTienDichVu, " +
                "hd.TongThanhToan, hd.TrangThaiThanhToan, hd.PhuongThucThanhToan, " +
                (hasLoaiHoaDon ? "hd.LoaiHoaDon" : "CAST(N'MAIN' AS NVARCHAR(50))") + " AS LoaiHoaDon, " +
                (hasGhiChu ? "hd.GhiChu" : "CAST(NULL AS NVARCHAR(500))") + " AS GhiChu, " +
                (hasParentHoaDonID ? "hd.ParentHoaDonID" : "CAST(NULL AS INT)") + " AS ParentHoaDonID, " +
                "s.TenSan, lds.NgayDat, lds.GioBatDau, lds.GioKetThuc, " +
                "acc.FullName AS TenKhachHang, nv.FullName AS TenNhanVien " +
                baseQuery +
                "ORDER BY hd.NgayLap DESC " +
                "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";
            List<Object> listParams = new ArrayList<>(params);
            listParams.add(offset);
            listParams.add(pageSize);
            try (PreparedStatement ps = conn.prepareStatement(sqlList)) {
                for (int i = 0; i < listParams.size(); i++) {
                    ps.setObject(i + 1, listParams.get(i));
                }
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> row = new LinkedHashMap<>();
                        row.put("hoaDonId",          rs.getInt("HoaDonID"));
                        row.put("datSanId",           rs.getInt("DatSanID"));
                        row.put("ngayLap",            rs.getTimestamp("NgayLap") != null
                                ? rs.getTimestamp("NgayLap").toString().substring(0, 16) : "");
                        row.put("tongTienSan",        rs.getDouble("TongTienSan"));
                        row.put("tongTienDichVu",     rs.getDouble("TongTienDichVu"));
                        row.put("tongThanhToan",      rs.getDouble("TongThanhToan"));
                        row.put("trangThai",          rs.getString("TrangThaiThanhToan"));
                        row.put("phuongThuc",         rs.getString("PhuongThucThanhToan"));
                        String loai = rs.getString("LoaiHoaDon");
                        row.put("loaiHoaDon",         loai == null ? "MAIN" : loai);
                        row.put("ghiChu",             rs.getString("GhiChu"));
                        row.put("parentHoaDonId",     rs.getObject("ParentHoaDonID"));
                        row.put("tenSan",             rs.getString("TenSan"));
                        row.put("ngayDat",            rs.getDate("NgayDat") != null ? rs.getDate("NgayDat").toString() : "");
                        row.put("gioBatDau",          rs.getTime("GioBatDau") != null ? rs.getTime("GioBatDau").toString().substring(0,5) : "");
                        row.put("gioKetThuc",         rs.getTime("GioKetThuc") != null ? rs.getTime("GioKetThuc").toString().substring(0,5) : "");
                        row.put("tenKhachHang",       rs.getString("TenKhachHang"));
                        row.put("tenNhanVien",        rs.getString("TenNhanVien"));
                        invoices.add(row);
                    }
                }
            }
        } catch (Exception e) {
            logger.error("HoaDonManagerServlet doGet error: {}", e.getMessage(), e);
            req.setAttribute("errorMsg", "Lỗi tải danh sách hóa đơn: " + e.getMessage());
        }

        int totalPages = (int) Math.ceil((double) totalCount / pageSize);
        List<Map<String, Object>> serviceProducts = loadServiceProducts(user.getCoSoId());
        List<Map<String, Object>> payableBookings = loadPayableBookings(user.getCoSoId());

        req.setAttribute("serviceProducts", serviceProducts);
        req.setAttribute("payableBookings", payableBookings);
        req.setAttribute("invoices",     invoices);
        req.setAttribute("stats",        stats);
        req.setAttribute("totalCount",   totalCount);
        req.setAttribute("totalPages",   totalPages);
        req.setAttribute("currentPage",  page);
        req.setAttribute("filterStatus", filterStatus);
        req.setAttribute("filterLoai",   filterLoai);
        req.setAttribute("filterFrom",   filterFrom);
        req.setAttribute("filterTo",     filterTo);
        req.setAttribute("filterSearch", filterSearch);
        req.setAttribute("pageTitle",    "Quản lý hóa đơn");
        req.getRequestDispatcher("/manager/QuanLyHoaDon.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        TaiKhoan user = (TaiKhoan) req.getSession().getAttribute("user");
        if (user == null || user.getRoleId() != 2) {
            resp.getWriter().write("{\"ok\":false,\"msg\":\"Không có quyền.\"}");
            return;
        }

        String action = req.getParameter("action");
        try {
            if ("payInvoice".equals(action)) {
                int hoaDonId        = Integer.parseInt(req.getParameter("hoaDonId"));
                String paymentMethod = req.getParameter("phuongThucThanhToan");
                if (paymentMethod == null || paymentMethod.trim().isEmpty()) paymentMethod = "Tiền mặt";
                payInvoice(hoaDonId, user, paymentMethod);
                AuditLogService.log(req, user, AuditLogService.ACTION_UPDATE, AuditLogService.ENTITY_HOA_DON,
                        String.valueOf(hoaDonId), "Hóa đơn #" + hoaDonId,
                        "Manager thanh toán hóa đơn bằng " + paymentMethod + ".");
                resp.getWriter().write("{\"ok\":true,\"msg\":\"Đã thanh toán hóa đơn #" + hoaDonId + " thành công.\"}");
            } else if ("createServiceInvoice".equals(action)) {
                int newHoaDonId = createServiceInvoice(req, user);
                AuditLogService.log(req, user, AuditLogService.ACTION_CREATE, AuditLogService.ENTITY_HOA_DON,
                        String.valueOf(newHoaDonId), "Hóa đơn #" + newHoaDonId,
                        "Manager tạo hóa đơn dịch vụ.");
                resp.getWriter().write("{\"ok\":true,\"msg\":\"Đã tạo hóa đơn dịch vụ #" + newHoaDonId + ".\",\"hoaDonId\":" + newHoaDonId + "}");
            } else if ("cancelInvoice".equals(action)) {
                int hoaDonId = Integer.parseInt(req.getParameter("hoaDonId"));
                cancelInvoice(hoaDonId, user);
                AuditLogService.log(req, user, AuditLogService.ACTION_CANCEL, AuditLogService.ENTITY_HOA_DON,
                        String.valueOf(hoaDonId), "Hóa đơn #" + hoaDonId,
                        "Manager hủy hóa đơn.");
                resp.getWriter().write("{\"ok\":true,\"msg\":\"Đã hủy hóa đơn #" + hoaDonId + ".\"}");
            } else {
                resp.getWriter().write("{\"ok\":false,\"msg\":\"Hành động không hợp lệ.\"}");
            }
        } catch (Exception e) {
            logger.error("HoaDonManagerServlet doPost error: {}", e.getMessage(), e);
            String msg = e.getMessage() != null ? e.getMessage().replace("\"", "'") : "Lỗi hệ thống.";
            resp.getWriter().write("{\"ok\":false,\"msg\":\"" + msg + "\"}");
        }
    }

    // --- Private helpers ---

    private void handleDetail(HttpServletRequest req, HttpServletResponse resp, TaiKhoan user)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        try {
            int hoaDonId = Integer.parseInt(req.getParameter("hoaDonId"));
            Map<String, Object> detail = new LinkedHashMap<>();

            try (Connection conn = DBUtil.getConnection()) {
                boolean hasLoaiHoaDon = columnExists(conn, "HoaDon", "LoaiHoaDon");
                boolean hasParentHoaDonID = columnExists(conn, "HoaDon", "ParentHoaDonID");
                boolean hasGhiChu = columnExists(conn, "HoaDon", "GhiChu");
                String sql =
                    "SELECT hd.HoaDonID, hd.DatSanID, hd.NgayLap, hd.TongTienSan, hd.TongTienDichVu, " +
                    "hd.PhiGuiXe, hd.GiamGia, hd.TongThanhToan, hd.TrangThaiThanhToan, hd.PhuongThucThanhToan, " +
                    (hasLoaiHoaDon ? "hd.LoaiHoaDon" : "CAST(N'MAIN' AS NVARCHAR(50))") + " AS LoaiHoaDon, " +
                    (hasGhiChu ? "hd.GhiChu" : "CAST(NULL AS NVARCHAR(500))") + " AS GhiChu, " +
                    (hasParentHoaDonID ? "hd.ParentHoaDonID" : "CAST(NULL AS INT)") + " AS ParentHoaDonID, " +
                    "s.TenSan, s.CoSoID, lds.NgayDat, lds.GioBatDau, lds.GioKetThuc, " +
                    "acc.FullName AS TenKhachHang, nv.FullName AS TenNhanVien " +
                    "FROM HoaDon hd " +
                    "INNER JOIN LichDatSan lds ON hd.DatSanID = lds.DatSanID " +
                    "INNER JOIN San s ON lds.SanID = s.SanID " +
                    "LEFT JOIN Accounts acc ON lds.AccountID = acc.AccountID " +
                    "LEFT JOIN Accounts nv ON hd.AccountID_NhanVien = nv.AccountID " +
                    "WHERE hd.HoaDonID = ? AND s.CoSoID = ?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, hoaDonId);
                    ps.setInt(2, user.getCoSoId());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            resp.getWriter().write("{\"ok\":false,\"msg\":\"Không tìm thấy hóa đơn.\"}");
                            return;
                        }
                        String loai = rs.getString("LoaiHoaDon");
                        detail.put("hoaDonId",         rs.getInt("HoaDonID"));
                        detail.put("datSanId",          rs.getInt("DatSanID"));
                        detail.put("ngayLap",           rs.getTimestamp("NgayLap") != null
                                ? rs.getTimestamp("NgayLap").toString().substring(0, 16) : "");
                        detail.put("tongTienSan",       rs.getDouble("TongTienSan"));
                        detail.put("tongTienDichVu",    rs.getDouble("TongTienDichVu"));
                        detail.put("phiGuiXe",          rs.getDouble("PhiGuiXe"));
                        detail.put("giamGia",           rs.getDouble("GiamGia"));
                        detail.put("tongThanhToan",     rs.getDouble("TongThanhToan"));
                        detail.put("trangThai",         rs.getString("TrangThaiThanhToan"));
                        detail.put("phuongThuc",        rs.getString("PhuongThucThanhToan"));
                        detail.put("loaiHoaDon",        loai == null ? "MAIN" : loai);
                        detail.put("ghiChu",            rs.getString("GhiChu"));
                        detail.put("parentHoaDonId",    rs.getObject("ParentHoaDonID"));
                        detail.put("tenSan",            rs.getString("TenSan"));
                        detail.put("ngayDat",           rs.getDate("NgayDat") != null ? rs.getDate("NgayDat").toString() : "");
                        detail.put("gioBatDau",         rs.getTime("GioBatDau") != null ? rs.getTime("GioBatDau").toString().substring(0,5) : "");
                        detail.put("gioKetThuc",        rs.getTime("GioKetThuc") != null ? rs.getTime("GioKetThuc").toString().substring(0,5) : "");
                        detail.put("tenKhachHang",      rs.getString("TenKhachHang"));
                        detail.put("tenNhanVien",       rs.getString("TenNhanVien"));
                    }
                }

                // Line items
                String sqlItems =
                    "SELECT sp.TenSanPham, ct.SoLuong, ct.DonGiaTaiThoiDiemBan, ct.ThanhTien " +
                    "FROM ChiTietHoaDon ct " +
                    "INNER JOIN SanPham_DichVu sp ON ct.SanPhamID = sp.SanPhamID " +
                    "WHERE ct.HoaDonID = ?";
                List<Map<String, Object>> items = new ArrayList<>();
                try (PreparedStatement ps = conn.prepareStatement(sqlItems)) {
                    ps.setInt(1, hoaDonId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            Map<String, Object> item = new LinkedHashMap<>();
                            item.put("tenSanPham", rs.getString("TenSanPham"));
                            item.put("soLuong",    rs.getInt("SoLuong"));
                            item.put("donGia",     rs.getDouble("DonGiaTaiThoiDiemBan"));
                            item.put("thanhTien",  rs.getDouble("ThanhTien"));
                            items.add(item);
                        }
                    }
                }
                detail.put("items", items);
            }

            resp.getWriter().write(gson.toJson(detail));
        } catch (Exception e) {
            logger.error("handleDetail error: {}", e.getMessage(), e);
            resp.getWriter().write("{\"ok\":false,\"msg\":\"" + e.getMessage().replace("\"","'") + "\"}");
        }
    }

    private void handleStats(HttpServletRequest req, HttpServletResponse resp, TaiKhoan user)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        try (Connection conn = DBUtil.getConnection()) {
            String sql = buildStatsSql(columnExists(conn, "HoaDon", "LoaiHoaDon"));
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, user.getCoSoId());
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        Map<String, Object> stats = new LinkedHashMap<>();
                        stats.put("totalCount",   rs.getInt("totalCount"));
                        stats.put("tongDoanhThu", rs.getDouble("tongDoanhThu"));
                        stats.put("mainChuaTT",   rs.getInt("mainChuaTT"));
                        stats.put("splitChuaTT",  rs.getInt("splitChuaTT"));
                        resp.getWriter().write(gson.toJson(stats));
                        return;
                    }
                }
            }
        } catch (Exception e) {
            logger.error("handleStats error: {}", e.getMessage(), e);
        }
        resp.getWriter().write("{}");
    }


    private List<Map<String, Object>> loadServiceProducts(int coSoId) {
        List<Map<String, Object>> products = new ArrayList<>();
        String sql = "SELECT SanPhamID, TenSanPham, DonGia, DonViTinh, SoLuongTon " +
                     "FROM SanPham_DichVu " +
                     "WHERE CoSoID = ? AND (TrangThai IS NULL OR TrangThai <> N'Ngừng kinh doanh') " +
                     "AND ISNULL(IsDeleted, 0) = 0 " +
                     "ORDER BY TenSanPham";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, coSoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("sanPhamId", rs.getInt("SanPhamID"));
                    row.put("tenSanPham", rs.getString("TenSanPham"));
                    row.put("donGia", rs.getDouble("DonGia"));
                    row.put("donViTinh", rs.getString("DonViTinh"));
                    row.put("soLuongTon", rs.getInt("SoLuongTon"));
                    products.add(row);
                }
            }
        } catch (Exception e) {
            logger.error("loadServiceProducts error: {}", e.getMessage(), e);
        }
        return products;
    }

    private List<Map<String, Object>> loadPayableBookings(int coSoId) {
        List<Map<String, Object>> bookings = new ArrayList<>();
        String sql = "SELECT TOP 80 lds.DatSanID, lds.NgayDat, lds.GioBatDau, lds.GioKetThuc, lds.AccountID, " +
                     "s.TenSan, acc.FullName AS TenKhachHang " +
                     "FROM LichDatSan lds " +
                     "INNER JOIN San s ON lds.SanID = s.SanID " +
                     "LEFT JOIN Accounts acc ON lds.AccountID = acc.AccountID " +
                     "WHERE s.CoSoID = ? AND ISNULL(lds.IsDeleted, 0) = 0 " +
                     "AND lds.TrangThai NOT IN (N'Đã hủy', N'Từ chối') " +
                     "ORDER BY lds.NgayDat DESC, lds.GioBatDau DESC";
        try (Connection conn = DBUtil.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, coSoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("datSanId", rs.getInt("DatSanID"));
                    row.put("accountId", rs.getObject("AccountID"));
                    row.put("label", "#" + rs.getInt("DatSanID") + " · " + rs.getString("TenSan") + " · " +
                            (rs.getDate("NgayDat") != null ? rs.getDate("NgayDat").toString() : "") + " " +
                            (rs.getTime("GioBatDau") != null ? rs.getTime("GioBatDau").toString().substring(0, 5) : "") + "-" +
                            (rs.getTime("GioKetThuc") != null ? rs.getTime("GioKetThuc").toString().substring(0, 5) : "") +
                            " · " + (rs.getString("TenKhachHang") != null ? rs.getString("TenKhachHang") : "Khách vãng lai"));
                    bookings.add(row);
                }
            }
        } catch (Exception e) {
            logger.error("loadPayableBookings error: {}", e.getMessage(), e);
        }
        return bookings;
    }

    private int createServiceInvoice(HttpServletRequest req, TaiKhoan user) throws Exception {
        int datSanId = Integer.parseInt(req.getParameter("datSanId"));
        boolean payNow = "true".equalsIgnoreCase(req.getParameter("payNow"));
        String paymentMethod = req.getParameter("phuongThucThanhToan");
        if (paymentMethod == null || paymentMethod.trim().isEmpty()) paymentMethod = "Tiền mặt";
        String ghiChuInput = req.getParameter("ghiChu");
        String ghiChu = (ghiChuInput == null || ghiChuInput.trim().isEmpty()) ? "Manager lập hóa đơn dịch vụ" : ghiChuInput.trim();
        if (ghiChu.length() > 255) ghiChu = ghiChu.substring(0, 255);

        String[] productIds = req.getParameterValues("productId");
        String[] quantities = req.getParameterValues("quantity");
        if (productIds == null || quantities == null || productIds.length != quantities.length) {
            throw new Exception("Vui lòng chọn ít nhất một dịch vụ hợp lệ.");
        }

        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                if (!columnExists(conn, "HoaDon", "LoaiHoaDon") || !columnExists(conn, "HoaDon", "GhiChu")) {
                    throw new Exception("Database chưa có cột LoaiHoaDon/GhiChu cho hóa đơn dịch vụ. Vui lòng chạy script /sql/migration_hoadon_loai.sql rồi thử lại.");
                }
                Integer customerAccountId = null;
                String sqlBooking = "SELECT lds.AccountID, s.CoSoID FROM LichDatSan lds INNER JOIN San s ON lds.SanID = s.SanID WHERE lds.DatSanID = ?";
                try (PreparedStatement ps = conn.prepareStatement(sqlBooking)) {
                    ps.setInt(1, datSanId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new Exception("Không tìm thấy đơn đặt sân #" + datSanId);
                        if (rs.getInt("CoSoID") != user.getCoSoId()) throw new Exception("Đơn đặt sân không thuộc cơ sở của bạn.");
                        Object accObj = rs.getObject("AccountID");
                        if (accObj != null) customerAccountId = ((Number) accObj).intValue();
                    }
                }

                double total = 0;
                List<int[]> validItems = new ArrayList<>();
                String sqlProduct = "SELECT TenSanPham, DonGia, SoLuongTon FROM SanPham_DichVu WHERE SanPhamID = ? AND CoSoID = ? AND ISNULL(IsDeleted, 0) = 0";
                try (PreparedStatement ps = conn.prepareStatement(sqlProduct)) {
                    for (int i = 0; i < productIds.length; i++) {
                        int productId;
                        int qty;
                        try {
                            productId = Integer.parseInt(productIds[i]);
                            qty = Integer.parseInt(quantities[i]);
                        } catch (NumberFormatException ex) {
                            continue;
                        }
                        if (productId <= 0 || qty <= 0) continue;
                        ps.setInt(1, productId);
                        ps.setInt(2, user.getCoSoId());
                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) throw new Exception("Sản phẩm #" + productId + " không thuộc cơ sở của bạn.");
                            int stock = rs.getInt("SoLuongTon");
                            double price = rs.getDouble("DonGia");
                            if (stock < qty) throw new Exception("Sản phẩm " + rs.getString("TenSanPham") + " chỉ còn " + stock + ".");
                            validItems.add(new int[]{productId, qty, (int) Math.round(price)});
                            total += price * qty;
                        }
                    }
                }
                if (validItems.isEmpty() || total <= 0) throw new Exception("Vui lòng nhập số lượng dịch vụ lớn hơn 0.");

                String status = payNow ? "Đã thanh toán" : "Chưa thanh toán";
                String sqlInsertHD = "INSERT INTO HoaDon (DatSanID, AccountID_KhachHang, AccountID_NhanVien, NgayLap, " +
                        "TongTienSan, TongTienDichVu, PhiGuiXe, GiamGia, TongThanhToan, TrangThaiThanhToan, PhuongThucThanhToan, LoaiHoaDon, GhiChu) " +
                        "VALUES (?, ?, ?, GETDATE(), 0, ?, 0, 0, ?, ?, ?, N'SPLIT', ?)";
                int hoaDonId;
                try (PreparedStatement ps = conn.prepareStatement(sqlInsertHD, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, datSanId);
                    if (customerAccountId != null) ps.setInt(2, customerAccountId); else ps.setNull(2, Types.INTEGER);
                    ps.setInt(3, user.getAccountId());
                    ps.setDouble(4, total);
                    ps.setDouble(5, total);
                    ps.setNString(6, status);
                    if (payNow) ps.setNString(7, paymentMethod.trim()); else ps.setNull(7, Types.NVARCHAR);
                    ps.setNString(8, ghiChu);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (!keys.next()) throw new Exception("Không lấy được mã hóa đơn mới.");
                        hoaDonId = keys.getInt(1);
                    }
                }

                String sqlInsertCT = "INSERT INTO ChiTietHoaDon (HoaDonID, SanPhamID, SoLuong, DonGiaTaiThoiDiemBan, ThanhTien) VALUES (?, ?, ?, ?, ?)";
                String sqlStock = "UPDATE SanPham_DichVu SET SoLuongTon = SoLuongTon - ? WHERE SanPhamID = ? AND CoSoID = ? AND SoLuongTon >= ?";
                try (PreparedStatement psCT = conn.prepareStatement(sqlInsertCT);
                     PreparedStatement psStock = conn.prepareStatement(sqlStock)) {
                    for (int[] item : validItems) {
                        int productId = item[0];
                        int qty = item[1];
                        double price = item[2];
                        psStock.setInt(1, qty);
                        psStock.setInt(2, productId);
                        psStock.setInt(3, user.getCoSoId());
                        psStock.setInt(4, qty);
                        if (psStock.executeUpdate() == 0) throw new Exception("Không đủ tồn kho cho sản phẩm #" + productId);

                        psCT.setInt(1, hoaDonId);
                        psCT.setInt(2, productId);
                        psCT.setInt(3, qty);
                        psCT.setDouble(4, price);
                        psCT.setDouble(5, price * qty);
                        psCT.addBatch();
                    }
                    psCT.executeBatch();
                }

                conn.commit();
                return hoaDonId;
            } catch (Exception e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private void payInvoice(int hoaDonId, TaiKhoan user, String paymentMethod) throws Exception {
        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                // Verify invoice belongs to this coSo and is unpaid
                boolean hasLoaiHoaDon = columnExists(conn, "HoaDon", "LoaiHoaDon");
                String sqlCheck =
                    "SELECT hd.TrangThaiThanhToan, s.CoSoID, lds.TrangThai AS TrangThaiDatSan, " +
                    (hasLoaiHoaDon ? "hd.LoaiHoaDon" : "CAST(NULL AS NVARCHAR(50))") + " AS LoaiHoaDon " +
                    "FROM HoaDon hd " +
                    "INNER JOIN LichDatSan lds ON hd.DatSanID = lds.DatSanID " +
                    "INNER JOIN San s ON lds.SanID = s.SanID " +
                    "WHERE hd.HoaDonID = ?";
                try (PreparedStatement ps = conn.prepareStatement(sqlCheck)) {
                    ps.setInt(1, hoaDonId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new Exception("Không tìm thấy hóa đơn #" + hoaDonId);
                        if (rs.getInt("CoSoID") != user.getCoSoId())
                            throw new Exception("Hóa đơn không thuộc cơ sở của bạn.");
                        if ("Đã thanh toán".equals(rs.getString("TrangThaiThanhToan")))
                            throw new Exception("Hóa đơn này đã được thanh toán trước đó.");
                        String loaiHoaDon = rs.getString("LoaiHoaDon");
                        if (hasLoaiHoaDon && (loaiHoaDon == null || "MAIN".equalsIgnoreCase(loaiHoaDon))) {
                            throw new Exception("Hóa đơn sân chính phải thanh toán tại màn hình Mở sân/Check-in để cập nhật đồng bộ trạng thái sân và lịch đặt.");
                        }
                    }
                }
                String sqlPay =
                    "UPDATE HoaDon SET TrangThaiThanhToan = N'Đã thanh toán', " +
                    "PhuongThucThanhToan = ?, AccountID_NhanVien = ?, NgayLap = GETDATE() " +
                    "WHERE HoaDonID = ?";
                try (PreparedStatement ps = conn.prepareStatement(sqlPay)) {
                    ps.setString(1, paymentMethod.trim());
                    ps.setInt(2, user.getAccountId());
                    ps.setInt(3, hoaDonId);
                    if (ps.executeUpdate() == 0) throw new Exception("Cập nhật hóa đơn thất bại.");
                }
                conn.commit();
            } catch (Exception e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private void cancelInvoice(int hoaDonId, TaiKhoan user) throws Exception {
        try (Connection conn = DBUtil.getConnection()) {
            conn.setAutoCommit(false);
            try {
                String sqlCheck =
                    "SELECT hd.TrangThaiThanhToan, s.CoSoID " +
                    "FROM HoaDon hd " +
                    "INNER JOIN LichDatSan lds ON hd.DatSanID = lds.DatSanID " +
                    "INNER JOIN San s ON lds.SanID = s.SanID " +
                    "WHERE hd.HoaDonID = ?";
                try (PreparedStatement ps = conn.prepareStatement(sqlCheck)) {
                    ps.setInt(1, hoaDonId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new Exception("Không tìm thấy hóa đơn #" + hoaDonId);
                        if (rs.getInt("CoSoID") != user.getCoSoId())
                            throw new Exception("Hóa đơn không thuộc cơ sở của bạn.");
                        if ("Đã thanh toán".equals(rs.getString("TrangThaiThanhToan")))
                            throw new Exception("Không thể hủy hóa đơn đã thanh toán.");
                    }
                }
                String sqlCancel =
                    "UPDATE HoaDon SET TrangThaiThanhToan = N'Đã hủy', AccountID_NhanVien = ? " +
                    "WHERE HoaDonID = ?";
                try (PreparedStatement ps = conn.prepareStatement(sqlCancel)) {
                    ps.setInt(1, user.getAccountId());
                    ps.setInt(2, hoaDonId);
                    if (ps.executeUpdate() == 0) throw new Exception("Cập nhật hóa đơn thất bại.");
                }
                conn.commit();
            } catch (Exception e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private boolean columnExists(Connection conn, String tableName, String columnName) throws SQLException {
        String sql = "SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(?) AND name = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setNString(1, tableName);
            ps.setNString(2, columnName);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private String buildStatsSql(boolean hasLoaiHoaDon) {
        String paidMainCondition = hasLoaiHoaDon
                ? "TrangThaiThanhToan = N'Đã thanh toán' AND (LoaiHoaDon = N'MAIN' OR LoaiHoaDon IS NULL)"
                : "TrangThaiThanhToan = N'Đã thanh toán'";
        String unpaidMainCondition = hasLoaiHoaDon
                ? "TrangThaiThanhToan = N'Chưa thanh toán' AND (LoaiHoaDon = N'MAIN' OR LoaiHoaDon IS NULL)"
                : "TrangThaiThanhToan = N'Chưa thanh toán'";
        String unpaidSplitCondition = hasLoaiHoaDon
                ? "TrangThaiThanhToan = N'Chưa thanh toán' AND LoaiHoaDon = N'SPLIT'"
                : "1 = 0";

        return "SELECT " +
                "  COUNT(*) AS totalCount, " +
                "  SUM(CASE WHEN " + paidMainCondition + " THEN TongThanhToan ELSE 0 END) AS tongDoanhThu, " +
                "  SUM(CASE WHEN " + unpaidMainCondition + " THEN 1 ELSE 0 END) AS mainChuaTT, " +
                "  SUM(CASE WHEN " + unpaidSplitCondition + " THEN 1 ELSE 0 END) AS splitChuaTT " +
                "FROM HoaDon hd " +
                "INNER JOIN LichDatSan lds ON hd.DatSanID = lds.DatSanID " +
                "INNER JOIN San s ON lds.SanID = s.SanID " +
                "WHERE s.CoSoID = ?";
    }
}
