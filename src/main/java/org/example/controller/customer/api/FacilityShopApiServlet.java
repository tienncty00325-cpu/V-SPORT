package org.example.controller.customer.api;

import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.example.dao.CoSoCapabilityDAO;
import org.example.dao.impl.CoSoCapabilityDAOImpl;
import org.example.model.SanPham_DichVu;
import org.example.util.Constants;
import org.example.util.JPAUtil;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Read-only JSON endpoint cho tab "Cửa hàng" trong facility detail bottom sheet
 * (Customer). Lazy-loaded riêng - CHỈ gọi khi Customer thực sự bấm vào tab Cửa hàng,
 * không tải kèm FacilityDetailApiServlet để tránh N+1 / tải dữ liệu không cần thiết
 * cho các cơ sở không có capability bán hàng.
 *
 * Server tự kiểm tra lại capability (không tin cờ shopAvailable phía client) - đúng
 * yêu cầu "Manager/Customer không truy cập được dữ liệu khi capability chưa duyệt".
 */
@WebServlet("/api/customer/facilities/shop")
public class FacilityShopApiServlet extends HttpServlet {

    private final CoSoCapabilityDAO capabilityDAO = new CoSoCapabilityDAOImpl();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("application/json; charset=UTF-8");

        int coSoId;
        String idParam = req.getParameter("coSoId");
        try {
            if (idParam == null || idParam.trim().isEmpty()) {
                sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "Thiếu tham số coSoId.");
                return;
            }
            coSoId = Integer.parseInt(idParam.trim());
            if (coSoId <= 0) {
                sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "coSoId không hợp lệ.");
                return;
            }
        } catch (NumberFormatException e) {
            sendError(resp, HttpServletResponse.SC_BAD_REQUEST, "coSoId không hợp lệ.");
            return;
        }

        // isApproved đã tự kiểm tra CoSo còn "Đang hoạt động" và chưa xóa mềm.
        boolean available = capabilityDAO.isApprovedAny(coSoId, Constants.SHOP_MODULE_CAPABILITIES);
        if (!available) {
            Map<String, Object> body = new HashMap<>();
            body.put("available", false);
            body.put("products", new ArrayList<>());
            resp.getWriter().write(new com.google.gson.Gson().toJson(body));
            return;
        }

        List<Map<String, Object>> products = new ArrayList<>();
        EntityManager em = JPAUtil.getEntityManager();
        try {
            TypedQuery<Object[]> q = em.createQuery(
                    "SELECT s, d.TenDanhMuc FROM SanPham_DichVu s, DanhMucSanPham d " +
                    "WHERE s.CoSoID = :coSoId AND d.DanhMucID = s.DanhMucID " +
                    "AND s.isDeleted = false AND s.TrangThai = :active " +
                    "ORDER BY s.TenSanPham", Object[].class)
                    .setParameter("coSoId", coSoId)
                    .setParameter("active", Constants.TRANG_THAI_SP_DANG_KINH_DOANH)
                    .setMaxResults(200); // giới hạn hợp lý cho lần tải đầu, tránh tải toàn bộ nếu cơ sở có rất nhiều sản phẩm
            for (Object[] row : q.getResultList()) {
                SanPham_DichVu sp = (SanPham_DichVu) row[0];
                String categoryName = (String) row[1];
                Map<String, Object> p = new HashMap<>();
                p.put("id", sp.getSanPhamID());
                p.put("name", sp.getTenSanPham());
                p.put("category", categoryName);
                p.put("price", sp.getDonGia());
                p.put("unit", sp.getDonViTinh());
                p.put("description", sp.getMoTa());
                p.put("image", sp.getHinhAnh());
                p.put("stockStatus", stockStatus(sp.getSoLuongTon()));
                products.add(p);
            }
        } finally {
            em.close();
        }

        Map<String, Object> body = new HashMap<>();
        body.put("available", true);
        body.put("products", products);
        resp.getWriter().write(new com.google.gson.Gson().toJson(body));
    }

    // Không lộ số lượng tồn kho chính xác cho Customer - chỉ 3 trạng thái tổng quát.
    private static String stockStatus(int soLuongTon) {
        if (soLuongTon <= 0) return "HET_HANG";
        if (soLuongTon <= 5) return "SAP_HET";
        return "CON_HANG";
    }

    private void sendError(HttpServletResponse resp, int status, String message) throws IOException {
        resp.setStatus(status);
        Map<String, Object> body = new HashMap<>();
        body.put("success", false);
        body.put("error", message);
        resp.getWriter().write(new com.google.gson.Gson().toJson(body));
    }
}
