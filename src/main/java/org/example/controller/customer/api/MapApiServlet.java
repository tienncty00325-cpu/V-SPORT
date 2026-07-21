package org.example.controller.customer.api;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.dao.CoSoDAO;
import org.example.dao.impl.CoSoDAOImpl;
import org.example.dto.FacilityMapDTO;

import java.io.IOException;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Read-only JSON endpoint cung cấp danh sách cơ sở cho bản đồ Customer.
 * Chỉ trả cơ sở chưa xóa mềm, TrangThai = "Đang hoạt động", và có đủ cả
 * ViDo lẫn KinhDo hợp lệ — không có cơ sở nào thiếu một trong hai tọa độ
 * lọt qua endpoint này.
 *
 * Query param: hỗ trợ cả tên tham số mới (lat/lng) lẫn tên cũ
 * (latitude/longitude) mà customer/BanDo.jsp đang gửi, để không phá giao
 * diện bản đồ hiện có. Response giữ nguyên hình dạng mảng JSON phẳng
 * (không bọc trong {facilities:[...]}) vì BanDo.jsp đang gọi
 * `facilities.forEach(...)` trực tiếp trên kết quả.
 */
@WebServlet("/api/customer/facilities/map")
public class MapApiServlet extends HttpServlet {

    private static final Logger logger = LogManager.getLogger(MapApiServlet.class);
    private static final double MAX_RADIUS_KM = 200.0;

    private final CoSoDAO coSoDAO = new CoSoDAOImpl();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Double lat = null;
        Double lng = null;
        Double radiusKm = null;
        Integer sportId = null;
        Integer facilityId = null;
        boolean openNow = false;
        String keyword = null;

        String latParam = firstNonBlank(req.getParameter("lat"), req.getParameter("latitude"));
        String lngParam = firstNonBlank(req.getParameter("lng"), req.getParameter("longitude"));
        String radiusParam = req.getParameter("radiusKm");
        String sportParam = req.getParameter("sportId");
        String openNowParam = req.getParameter("openNow");
        String keywordParam = req.getParameter("keyword");
        String facilityIdParam = req.getParameter("facilityId");

        try {
            if (latParam != null && !latParam.trim().isEmpty()) {
                lat = Double.parseDouble(latParam.trim());
            }
            if (lngParam != null && !lngParam.trim().isEmpty()) {
                lng = Double.parseDouble(lngParam.trim());
            }
            if (radiusParam != null && !radiusParam.trim().isEmpty()) {
                radiusKm = Double.parseDouble(radiusParam.trim());
            }
            if (sportParam != null && !sportParam.trim().isEmpty()) {
                sportId = Integer.parseInt(sportParam.trim());
            }
            if (facilityIdParam != null && !facilityIdParam.trim().isEmpty()) {
                facilityId = Integer.parseInt(facilityIdParam.trim());
            }
            if (openNowParam != null && !openNowParam.trim().isEmpty()) {
                openNow = Boolean.parseBoolean(openNowParam.trim());
            }
        } catch (NumberFormatException e) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Định dạng tham số truy vấn không hợp lệ.");
            return;
        }
        if (keywordParam != null && !keywordParam.trim().isEmpty()) {
            keyword = keywordParam.trim();
        }

        // A. lat/lng phải xuất hiện cùng nhau, và nằm trong phạm vi hợp lệ.
        if ((lat != null && lng == null) || (lat == null && lng != null)) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Cần cung cấp cả lat và lng.");
            return;
        }
        if (lat != null && (lat < -90 || lat > 90)) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Vĩ độ (lat) không hợp lệ. Phải nằm trong khoảng [-90, 90].");
            return;
        }
        if (lng != null && (lng < -180 || lng > 180)) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Kinh độ (lng) không hợp lệ. Phải nằm trong khoảng [-180, 180].");
            return;
        }
        // B. radiusKm chỉ có ý nghĩa khi có lat/lng; phải > 0 và <= giới hạn tối đa.
        if (radiusKm != null) {
            if (lat == null) {
                sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "radiusKm chỉ dùng khi có lat và lng.");
                return;
            }
            if (radiusKm <= 0) {
                sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Bán kính tìm kiếm (radiusKm) phải lớn hơn 0.");
                return;
            }
            if (radiusKm > MAX_RADIUS_KM) {
                sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Bán kính tìm kiếm (radiusKm) tối đa " + (int) MAX_RADIUS_KM + " km.");
                return;
            }
        }

        List<FacilityMapDTO> facilities;
        try {
            facilities = coSoDAO.getAllCoSoForMap(sportId, keyword, facilityId);
        } catch (Exception e) {
            logger.error("Lỗi truy vấn dữ liệu bản đồ cơ sở: {}", e.getMessage(), e);
            sendError(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Lỗi máy chủ nội bộ khi truy vấn bản đồ.");
            return;
        }

        // C. facilityId: nếu truyền mà không có cơ sở hợp lệ tương ứng -> 404.
        if (facilityId != null && facilities.isEmpty()) {
            sendError(resp, HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy cơ sở hoặc cơ sở không khả dụng.");
            return;
        }

        LocalTime nowTime = ZonedDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")).toLocalTime();
        Double finalLat = lat;
        Double finalLng = lng;
        Double finalRadius = radiusKm;

        List<FacilityMapDTO> visible = new java.util.ArrayList<>();
        for (FacilityMapDTO fac : facilities) {
            boolean isOpen = isOpenNow(fac.getGioMoCua(), fac.getGioDongCua(), nowTime);
            fac.setMoCuaHienTai(isOpen);

            // E. openNow=true: loại cơ sở đang đóng cửa. Nếu giờ mở/đóng NULL thì
            // không được tự khẳng định là đang mở -> loại luôn khi lọc openNow.
            if (openNow && !isOpen) {
                continue;
            }

            if (finalLat != null && finalLng != null) {
                double dist = haversineKm(finalLat, finalLng, fac.getViDo(), fac.getKinhDo());
                if (finalRadius != null && dist > finalRadius) {
                    continue;
                }
                fac.setDistanceKm(Math.round(dist * 100.0) / 100.0);
            } else {
                fac.setDistanceKm(null);
            }

            visible.add(fac);
        }

        if (finalLat != null && finalLng != null) {
            visible.sort((a, b) -> {
                Double d1 = a.getDistanceKm();
                Double d2 = b.getDistanceKm();
                if (d1 == null && d2 == null) return 0;
                if (d1 == null) return 1;
                if (d2 == null) return -1;
                return d1.compareTo(d2);
            });
        }

        resp.setStatus(HttpServletResponse.SC_OK);
        resp.setContentType("application/json; charset=UTF-8");
        resp.getWriter().write(new com.google.gson.Gson().toJson(visible));
    }

    private static String firstNonBlank(String a, String b) {
        if (a != null && !a.trim().isEmpty()) return a;
        return b;
    }

    /** Haversine — khoảng cách great-circle giữa 2 điểm trên mặt cầu, đơn vị km. */
    private double haversineKm(double lat1, double lon1, double lat2, double lon2) {
        final double R = 6371.0; // bán kính Trái Đất trung bình, km
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    /**
     * Đang mở cửa tại thời điểm hiện tại (Asia/Ho_Chi_Minh), hỗ trợ ca qua đêm
     * (đóng cửa sau nửa đêm, VD 08:00-02:00). Nếu open/close NULL thì KHÔNG được
     * tự khẳng định đang mở — trả false thay vì mặc định true.
     */
    private boolean isOpenNow(String openStr, String closeStr, LocalTime now) {
        if (openStr == null || closeStr == null) {
            return false;
        }
        LocalTime open;
        LocalTime close;
        try {
            open = LocalTime.parse(openStr);
            close = LocalTime.parse(closeStr);
        } catch (Exception e) {
            return false;
        }
        if (open.equals(close)) {
            return true; // mở 24h
        }
        if (open.isBefore(close)) {
            return !now.isBefore(open) && now.isBefore(close);
        } else {
            // Ca qua đêm: mở cửa >= open HOẶC còn trong khoảng trước close của ngày hôm sau.
            return !now.isBefore(open) || now.isBefore(close);
        }
    }

    private void sendError(HttpServletResponse resp, int status, String message) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json; charset=UTF-8");
        Map<String, Object> error = new HashMap<>();
        error.put("success", false);
        error.put("message", message);
        error.put("error", message);
        resp.getWriter().write(new com.google.gson.Gson().toJson(error));
    }
}
