package org.example.controller.customer.api;

import com.google.gson.Gson;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.example.service.customer.PublicProductSearchService;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * API tìm kiếm/chi tiết sản phẩm thể thao công khai cho Customer (tab "Sản phẩm"
 * trong /customer/dich-vu). Chỉ đọc dữ liệu public đã lọc theo capability/CoSo
 * active - không tin bất kỳ tham số coSoId nào để trả dữ liệu nội bộ.
 */
@WebServlet("/api/customer/san-pham")
public class SanPhamApiServlet extends HttpServlet {

    private final PublicProductSearchService service = new PublicProductSearchService();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("application/json; charset=UTF-8");
        String action = req.getParameter("action");

        try {
            if ("detail".equals(action)) {
                handleDetail(req, resp);
            } else {
                handleSearch(req, resp);
            }
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Map<String, Object> err = new HashMap<>();
            err.put("success", false);
            err.put("message", "Đã xảy ra lỗi khi tìm kiếm sản phẩm.");
            resp.getWriter().write(gson.toJson(err));
        }
    }

    private void handleSearch(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        PublicProductSearchService.SearchFilter f = new PublicProductSearchService.SearchFilter();
        f.q = req.getParameter("q");

        String categoryIdStr = req.getParameter("categoryId");
        if (categoryIdStr != null && !categoryIdStr.trim().isEmpty()) {
            try { f.categoryId = Integer.parseInt(categoryIdStr.trim()); } catch (NumberFormatException ignored) {}
        }
        String coSoIdStr = req.getParameter("coSoId");
        if (coSoIdStr != null && !coSoIdStr.trim().isEmpty()) {
            try { f.coSoId = Integer.parseInt(coSoIdStr.trim()); } catch (NumberFormatException ignored) {}
        }
        String latStr = req.getParameter("lat");
        String lngStr = req.getParameter("lng");
        if (latStr != null && lngStr != null && !latStr.trim().isEmpty() && !lngStr.trim().isEmpty()) {
            try {
                f.lat = Double.parseDouble(latStr.trim());
                f.lng = Double.parseDouble(lngStr.trim());
            } catch (NumberFormatException ignored) {}
        }
        String radiusStr = req.getParameter("radiusKm");
        if (radiusStr != null && !radiusStr.trim().isEmpty()) {
            try {
                double r = Double.parseDouble(radiusStr.trim());
                if (r > 0 && r <= 200) f.radiusKm = r;
            } catch (NumberFormatException ignored) {}
        }

        List<Map<String, Object>> results = service.search(f);
        Map<String, Object> out = new HashMap<>();
        out.put("success", true);
        out.put("products", results);
        out.put("total", results.size());
        resp.getWriter().write(gson.toJson(out));
    }

    private void handleDetail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String idStr = req.getParameter("productId");
        Map<String, Object> out = new HashMap<>();
        int productId;
        try {
            productId = Integer.parseInt(idStr);
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.put("success", false);
            out.put("message", "Thiếu hoặc sai mã sản phẩm.");
            resp.getWriter().write(gson.toJson(out));
            return;
        }
        Map<String, Object> detail = service.detail(productId);
        if (detail == null) {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            out.put("success", false);
            out.put("message", "Không tìm thấy sản phẩm hoặc sản phẩm không còn khả dụng.");
            resp.getWriter().write(gson.toJson(out));
            return;
        }
        out.put("success", true);
        out.put("product", detail);
        resp.getWriter().write(gson.toJson(out));
    }
}
