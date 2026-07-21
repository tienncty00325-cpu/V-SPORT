package org.example.controller.customer;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.example.dao.CoSoDAO;
import org.example.dao.LoaiSanDAO;
import org.example.dao.impl.CoSoDAOImpl;
import org.example.dao.impl.LoaiSanDAOImpl;
import org.example.model.CoSo;
import org.example.model.MonTheThao;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/**
 * Trang tìm kiếm thật của Customer Portal: /customer/tim-kiem?q=&sportId=&openNow=
 * GET only. Đọc query param, validate, gọi DAO thật (CoSoDAO.searchCoSo — JPQL
 * bind parameter, không nối chuỗi SQL), forward dữ liệu thật sang TimKiem.jsp.
 * Cho phép khách chưa đăng nhập xem (cùng chính sách với /customer/dat-san).
 */
@WebServlet("/customer/tim-kiem")
public class TimKiemServlet extends HttpServlet {

    private static final Logger LOGGER = LogManager.getLogger(TimKiemServlet.class);
    private static final int MAX_KEYWORD_LENGTH = 120;

    private final CoSoDAO coSoDAO = new CoSoDAOImpl();
    private final LoaiSanDAO loaiSanDAO = new LoaiSanDAOImpl();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String rawQuery = req.getParameter("q");
        String query = rawQuery != null ? rawQuery.trim() : "";
        if (query.length() > MAX_KEYWORD_LENGTH) {
            query = query.substring(0, MAX_KEYWORD_LENGTH);
        }

        Integer sportId = parsePositiveInt(req.getParameter("sportId"));
        Integer coSoId = parsePositiveInt(req.getParameter("coSoId"));
        boolean openNow = "true".equals(req.getParameter("openNow")) || "1".equals(req.getParameter("openNow"));

        List<MonTheThao> dsMon;
        try {
            dsMon = loaiSanDAO.getAllMonTheThao();
        } catch (Exception e) {
            LOGGER.error("TIM_KIEM_LOAD_SPORTS_ERROR", e);
            dsMon = new ArrayList<>();
        }

        List<CoSo> results;
        try {
            results = coSoDAO.searchCoSo(query, sportId);
        } catch (Exception e) {
            LOGGER.error("TIM_KIEM_SEARCH_ERROR query={} sportId={}", query, sportId, e);
            req.setAttribute("searchError", true);
            results = new ArrayList<>();
        }

        // coSoId (đến từ nút "Lọc chi tiết" mở từ một cơ sở cụ thể, hoặc share-link)
        // thu hẹp thêm kết quả về đúng cơ sở đó, không cần DAO riêng.
        if (coSoId != null && results != null) {
            List<CoSo> narrowed = new ArrayList<>();
            for (CoSo c : results) {
                if (c.getCoSoID() == coSoId) narrowed.add(c);
            }
            results = narrowed;
        }

        // openNow lọc theo giờ mở/đóng cửa thật của từng cơ sở tại thời điểm request.
        if (openNow && results != null) {
            java.time.LocalTime now = java.time.LocalTime.now();
            List<CoSo> filtered = new ArrayList<>();
            for (CoSo c : results) {
                if (c.getGioMoCua() != null && c.getGioDongCua() != null
                        && !now.isBefore(c.getGioMoCua()) && !now.isAfter(c.getGioDongCua())) {
                    filtered.add(c);
                }
            }
            results = filtered;
        }

        req.setAttribute("query", query);
        req.setAttribute("sportId", sportId);
        req.setAttribute("coSoId", coSoId);
        req.setAttribute("openNow", openNow);
        req.setAttribute("dsMon", dsMon);
        req.setAttribute("results", results);

        req.getRequestDispatcher("/customer/TimKiem.jsp").forward(req, resp);
    }

    private Integer parsePositiveInt(String raw) {
        if (raw == null || raw.trim().isEmpty()) return null;
        try {
            int v = Integer.parseInt(raw.trim());
            return v > 0 ? v : null;
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
