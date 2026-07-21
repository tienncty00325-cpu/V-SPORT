package org.example.controller.customer.api;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Read-only JSON endpoint phục vụ court detail bottom sheet ở trang chủ Customer.
 * Cùng convention với MapApiServlet (/api/customer/facilities/map): JDBC qua DBUtil,
 * Gson, UTF-8, error shape {success:false, error}. Chỉ trả cơ sở đang hoạt động,
 * chưa xóa; không lộ dữ liệu nội bộ (giá nhập, tồn kho, account quản lý...).
 */
@WebServlet("/api/customer/facilities/detail")
public class FacilityDetailApiServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        int coSoId;
        String idParam = req.getParameter("coSoId");
        try {
            if (idParam == null || idParam.trim().isEmpty()) {
                sendErrorResponse(resp, HttpServletResponse.SC_BAD_REQUEST, "Thiếu tham số coSoId.");
                return;
            }
            coSoId = Integer.parseInt(idParam.trim());
            if (coSoId <= 0) {
                sendErrorResponse(resp, HttpServletResponse.SC_BAD_REQUEST, "coSoId không hợp lệ.");
                return;
            }
        } catch (NumberFormatException e) {
            sendErrorResponse(resp, HttpServletResponse.SC_BAD_REQUEST, "coSoId không hợp lệ.");
            return;
        }

        Map<String, Object> facility = new HashMap<>();
        List<Map<String, Object>> courts = new ArrayList<>();
        List<Map<String, Object>> services = new ArrayList<>();
        Set<String> images = new LinkedHashSet<>();

        String facilitySql = "SELECT c.CoSoID, c.TenCoSo, c.DiaChi, c.SoDienThoai, c.MoTa, c.ViDo, c.KinhDo, c.HinhAnh, " +
                "       c.GioMoCua, c.GioDongCua, c.LoaiHinhKinhDoanh, " +
                "       (SELECT MIN(ls.GiaKhongDen) FROM LoaiSan ls WHERE ls.CoSoID = c.CoSoID AND (ls.IsDeleted = 0 OR ls.IsDeleted IS NULL)) AS MinPrice, " +
                "       (SELECT COUNT(*) FROM San s WHERE s.CoSoID = c.CoSoID AND s.TrangThai = N'Sẵn sàng' AND (s.IsDeleted = 0 OR s.IsDeleted IS NULL)) AS ReadyCourtCount " +
                "FROM CoSo c " +
                "WHERE c.CoSoID = ? AND (c.IsDeleted = 0 OR c.IsDeleted IS NULL) AND c.TrangThai = N'Đang hoạt động'";

        String courtsSql = "SELECT s.SanID, s.TenSan, s.TrangThai, s.HinhAnh, s.MoTa, " +
                "       ls.TenLoai, ls.GiaKhongDen, ls.GiaCoDen, mt.TenMon " +
                "FROM San s " +
                "JOIN LoaiSan ls ON s.LoaiSanID = ls.LoaiSanID " +
                "LEFT JOIN MonTheThao mt ON ls.MonTheThaoID = mt.MonTheThaoID " +
                "WHERE s.CoSoID = ? AND (s.IsDeleted = 0 OR s.IsDeleted IS NULL) " +
                "ORDER BY s.TenSan";

        String servicesSql = "SELECT TOP 30 sp.TenSanPham, sp.DonGia, sp.DonViTinh " +
                "FROM SanPham_DichVu sp " +
                "WHERE sp.CoSoID = ? AND (sp.IsDeleted = 0 OR sp.IsDeleted IS NULL) AND sp.SoLuongTon > 0 " +
                "ORDER BY sp.TenSanPham";

        try (java.sql.Connection conn = org.example.util.DBUtil.getConnection()) {

            try (java.sql.PreparedStatement ps = conn.prepareStatement(facilitySql)) {
                ps.setInt(1, coSoId);
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        sendErrorResponse(resp, HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy cơ sở hoặc cơ sở đã ngừng hoạt động.");
                        return;
                    }
                    java.sql.Time gioMo = rs.getTime("GioMoCua");
                    java.sql.Time gioDong = rs.getTime("GioDongCua");
                    LocalTime openLocal = gioMo != null ? gioMo.toLocalTime() : null;
                    LocalTime closeLocal = gioDong != null ? gioDong.toLocalTime() : null;
                    LocalTime nowTime = ZonedDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")).toLocalTime();

                    facility.put("coSoId", rs.getInt("CoSoID"));
                    facility.put("tenCoSo", rs.getString("TenCoSo"));
                    facility.put("address", rs.getString("DiaChi"));
                    facility.put("phone", emptyToNull(rs.getString("SoDienThoai")));
                    facility.put("description", emptyToNull(rs.getString("MoTa")));
                    java.math.BigDecimal viDo = rs.getBigDecimal("ViDo");
                    java.math.BigDecimal kinhDo = rs.getBigDecimal("KinhDo");
                    facility.put("latitude", viDo != null ? viDo.doubleValue() : null);
                    facility.put("longitude", kinhDo != null ? kinhDo.doubleValue() : null);
                    facility.put("openingTime", gioMo != null ? gioMo.toString().substring(0, 5) : "");
                    facility.put("closingTime", gioDong != null ? gioDong.toString().substring(0, 5) : "");
                    facility.put("openNow", isOpenNow(openLocal, closeLocal, nowTime));
                    double minPrice = rs.getDouble("MinPrice");
                    facility.put("minPrice", rs.wasNull() ? null : minPrice);
                    facility.put("readyCourtCount", rs.getInt("ReadyCourtCount"));

                    String hinhAnh = rs.getString("HinhAnh");
                    facility.put("imageUrl", hinhAnh != null ? hinhAnh.trim() : "");
                    addImage(images, hinhAnh);

                    List<String> sportsList = new ArrayList<>();
                    String loaiHinh = rs.getString("LoaiHinhKinhDoanh");
                    if (loaiHinh != null && !loaiHinh.trim().isEmpty()) {
                        for (String s : loaiHinh.split(",")) {
                            if (!s.trim().isEmpty()) {
                                sportsList.add(s.trim());
                            }
                        }
                    }
                    facility.put("sports", sportsList);
                }
            }

            try (java.sql.PreparedStatement ps = conn.prepareStatement(courtsSql)) {
                ps.setInt(1, coSoId);
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> court = new HashMap<>();
                        court.put("sanId", rs.getInt("SanID"));
                        court.put("tenSan", rs.getString("TenSan"));
                        court.put("trangThai", rs.getString("TrangThai"));
                        court.put("loaiSan", rs.getString("TenLoai"));
                        court.put("monTheThao", emptyToNull(rs.getString("TenMon")));
                        court.put("giaKhongDen", rs.getDouble("GiaKhongDen"));
                        court.put("giaCoDen", rs.getDouble("GiaCoDen"));
                        court.put("moTa", emptyToNull(rs.getString("MoTa")));
                        courts.add(court);
                        addImage(images, rs.getString("HinhAnh"));
                    }
                }
            }

            try (java.sql.PreparedStatement ps = conn.prepareStatement(servicesSql)) {
                ps.setInt(1, coSoId);
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> sv = new HashMap<>();
                        sv.put("tenSanPham", rs.getString("TenSanPham"));
                        sv.put("donGia", rs.getDouble("DonGia"));
                        sv.put("donViTinh", emptyToNull(rs.getString("DonViTinh")));
                        services.add(sv);
                    }
                }
            }
        } catch (Exception e) {
            sendErrorResponse(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Lỗi máy chủ nội bộ khi tải thông tin cơ sở.");
            return;
        }

        facility.put("courts", courts);
        facility.put("services", services);
        facility.put("images", new ArrayList<>(images));

        resp.setContentType("application/json; charset=UTF-8");
        resp.getWriter().write(new com.google.gson.Gson().toJson(facility));
    }

    private static String emptyToNull(String s) {
        return s == null || s.trim().isEmpty() ? null : s.trim();
    }

    /** Chỉ nhận URL/đường dẫn ảnh hợp lệ (http(s) hoặc đường dẫn nội bộ có '/'). */
    private static void addImage(Set<String> images, String raw) {
        if (raw == null) {
            return;
        }
        String v = raw.trim();
        if (v.isEmpty()) {
            return;
        }
        if (v.startsWith("http://") || v.startsWith("https://") || v.contains("/")) {
            images.add(v);
        }
    }

    private void sendErrorResponse(HttpServletResponse resp, int status, String message) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json; charset=UTF-8");
        Map<String, Object> error = new HashMap<>();
        error.put("success", false);
        error.put("error", message);
        resp.getWriter().write(new com.google.gson.Gson().toJson(error));
    }

    private boolean isOpenNow(LocalTime open, LocalTime close, LocalTime now) {
        if (open == null || close == null) {
            return true;
        }
        if (open.isBefore(close)) {
            return !now.isBefore(open) && !now.isAfter(close);
        } else {
            return !now.isBefore(open) || !now.isAfter(close);
        }
    }
}
