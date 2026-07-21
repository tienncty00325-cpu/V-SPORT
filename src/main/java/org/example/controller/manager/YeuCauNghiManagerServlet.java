package org.example.controller.manager;



import org.example.model.TaiKhoan;
import org.example.model.YeuCauNghi;
import org.example.service.YeuCauNghiService;



import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.service.AuditLogService;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;

/**
 * Servlet quáº£n lÃ½ yÃªu cáº§u nghá»‰ dÃ nh cho Manager
 * Cho phÃ©p xem, duyá»‡t, tá»« chá»‘i yÃªu cáº§u nghá»‰ cá»§a nhÃ¢n viÃªn
 */
@WebServlet("/manager/yeu-cau-nghi")
public class YeuCauNghiManagerServlet extends HttpServlet {

    private static final Logger logger = LogManager.getLogger(YeuCauNghiManagerServlet.class);

    private final YeuCauNghiService yeuCauNghiService;

    public YeuCauNghiManagerServlet() {
        this.yeuCauNghiService = new YeuCauNghiService();
    }

    public YeuCauNghiManagerServlet(YeuCauNghiService yeuCauNghiService) {
        this.yeuCauNghiService = yeuCauNghiService;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        HttpSession session = req.getSession();

        TaiKhoan manager = (TaiKhoan) session.getAttribute("user");
        if (!isAuthorizedManager(manager, req, resp, session)) {
            return;
        }

        Integer managerCoSoId = manager.getCoSoId();
        if (managerCoSoId == null) {
            session.setAttribute("error", "KhÃ´ng tÃ¬m tháº¥y thÃ´ng tin cÆ¡ sá»Ÿ cá»§a quáº£n lÃ½. Vui lÃ²ng Ä‘Äƒng nháº­p láº¡i.");
            try {
                req.getRequestDispatcher("/dangnhap").forward(req, resp);
            } catch (Exception e) {
                throw new ServletException("Forward to login failed", e);
            }
            return;
        }

        String format = req.getParameter("format");
        try {
            // Lấy parameter filter
            String status = req.getParameter("status");
            List<YeuCauNghi> allRequests = yeuCauNghiService.getYeuCauNghiByCoSo(managerCoSoId, status);

            // Check if JSON format requested (for AJAX)
            if ("json".equals(format)) {
                resp.setContentType("application/json");
                resp.setCharacterEncoding("UTF-8");
                String json = buildYeuCauNghiJson(allRequests);
                resp.getWriter().write(json);
                return;
            }

            resp.sendRedirect(req.getContextPath() + "/manager/nhan-su?tab=leave");
        } catch (Exception e) {
            logger.error("Error in YeuCauNghiManagerServlet doGet: {}", e.getMessage(), e);
            if ("json".equals(format)) {
                resp.setContentType("application/json");
                resp.setCharacterEncoding("UTF-8");
                resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                resp.getWriter().write("{\"success\":false,\"error\":\"Lỗi hệ thống: " + e.getMessage().replace("\"", "\\\"") + "\"}");
            } else {
                session.setAttribute("error", "Lỗi khi tải dữ liệu: " + e.getMessage());
                resp.sendRedirect(req.getContextPath() + "/manager/nhan-su?tab=leave");
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        HttpSession session = req.getSession();

        TaiKhoan manager = (TaiKhoan) session.getAttribute("user");
        if (!isAuthorizedManager(manager, req, resp, session)) {
            return;
        }

        Integer managerCoSoId = manager.getCoSoId();
        if (managerCoSoId == null) {
            boolean isJson = "json".equals(req.getParameter("format"));
            if (isJson) {
                resp.setContentType("application/json");
                resp.setCharacterEncoding("UTF-8");
                resp.getWriter().write("{\"success\":false,\"error\":\"TÃ i khoáº£n quáº£n lÃ½ chÆ°a Ä‘Æ°á»£c liÃªn káº¿t vá»›i cÆ¡ sá»Ÿ nÃ o.\"}");
            } else {
                session.setAttribute("error", "TÃ i khoáº£n quáº£n lÃ½ chÆ°a Ä‘Æ°á»£c liÃªn káº¿t vá»›i cÆ¡ sá»Ÿ nÃ o.");
                resp.sendRedirect(req.getContextPath() + "/manager/nhan-su?tab=leave");
            }
            return;
        }

        String action = req.getParameter("action");
        String yeuCauNghiIdStr = req.getParameter("id");
        String ghiChu = req.getParameter("ghiChu");
        boolean isJson = "json".equals(req.getParameter("format"));

        if (yeuCauNghiIdStr == null || yeuCauNghiIdStr.isEmpty()) {
            if (isJson) {
                resp.setContentType("application/json");
                resp.setCharacterEncoding("UTF-8");
                resp.getWriter().write("{\"success\":false,\"error\":\"Thiáº¿u thÃ´ng tin yÃªu cáº§u nghá»‰\"}");
            } else {
                session.setAttribute("error", "Thiáº¿u thÃ´ng tin yÃªu cáº§u nghá»‰");
                resp.sendRedirect(req.getContextPath() + "/manager/nhan-su?tab=leave");
            }
            return;
        }

        try {
            int yeuCauNghiID = Integer.parseInt(yeuCauNghiIdStr);
            int managerID = manager.getAccountId();
            String successMsg = null;
            String errorMsg = null;

            if ("approve".equals(action)) {
                boolean success = yeuCauNghiService.approveYeuCauNghi(yeuCauNghiID, managerID, ghiChu);
                if (success) {
                    successMsg = "ÄÃ£ phÃª duyá»‡t yÃªu cáº§u nghá»‰";
                    AuditLogService.log(req, manager,
                        AuditLogService.ACTION_APPROVE, AuditLogService.ENTITY_YEU_CAU_NGHI,
                        String.valueOf(yeuCauNghiID), "Yêu cầu nghỉ #" + yeuCauNghiID,
                        "Manager duyệt yêu cầu nghỉ phép");
                } else {
                    errorMsg = "KhÃ´ng thá»ƒ phÃª duyá»‡t yÃªu cáº§u";
                }
            } else if ("reject".equals(action)) {
                boolean success = yeuCauNghiService.rejectYeuCauNghi(yeuCauNghiID, managerID, ghiChu);
                if (success) {
                    successMsg = "ÄÃ£ tá»« chá»‘i yÃªu cáº§u nghá»‰";
                    AuditLogService.log(req, manager,
                        AuditLogService.ACTION_REJECT, AuditLogService.ENTITY_YEU_CAU_NGHI,
                        String.valueOf(yeuCauNghiID), "Yêu cầu nghỉ #" + yeuCauNghiID,
                        "Manager từ chối yêu cầu nghỉ phép");
                } else {
                    errorMsg = "KhÃ´ng thá»ƒ tá»« chá»‘i yÃªu cáº§u";
                }
            } else {
                errorMsg = "HÃ nh Ä‘á»™ng khÃ´ng há»£p lá»‡";
            }

            if (isJson) {
                resp.setContentType("application/json");
                resp.setCharacterEncoding("UTF-8");
                java.util.Map<String, Object> map = new java.util.HashMap<>();
                if (errorMsg != null) {
                    map.put("success", false);
                    map.put("error", errorMsg);
                } else {
                    map.put("success", true);
                    map.put("message", successMsg);
                }
                resp.getWriter().write(new com.google.gson.Gson().toJson(map));
            } else {
                if (errorMsg != null) {
                    session.setAttribute("error", errorMsg);
                } else {
                    session.setAttribute("message", successMsg);
                }
                resp.sendRedirect(req.getContextPath() + "/manager/nhan-su?tab=leave");
            }

        } catch (NumberFormatException e) {
            logger.error("Invalid ID format: {}", yeuCauNghiIdStr, e);
            if (isJson) {
                resp.setContentType("application/json");
                resp.setCharacterEncoding("UTF-8");
                java.util.Map<String, Object> map = new java.util.HashMap<>();
                map.put("success", false);
                map.put("error", "ID yÃªu cáº§u khÃ´ng há»£p lá»‡");
                resp.getWriter().write(new com.google.gson.Gson().toJson(map));
            } else {
                session.setAttribute("error", "ID yÃªu cáº§u khÃ´ng há»£p lá»‡");
                resp.sendRedirect(req.getContextPath() + "/manager/nhan-su?tab=leave");
            }
        } catch (IllegalArgumentException e) {
            logger.error("Validation error: {}", e.getMessage(), e);
            if (isJson) {
                resp.setContentType("application/json");
                resp.setCharacterEncoding("UTF-8");
                java.util.Map<String, Object> map = new java.util.HashMap<>();
                map.put("success", false);
                map.put("error", e.getMessage());
                resp.getWriter().write(new com.google.gson.Gson().toJson(map));
            } else {
                session.setAttribute("error", e.getMessage());
                resp.sendRedirect(req.getContextPath() + "/manager/nhan-su?tab=leave");
            }
        } catch (Exception e) {
            logger.error("Unexpected error in YeuCauNghiManagerServlet doPost: {}", e.getMessage(), e);
            if (isJson) {
                resp.setContentType("application/json");
                resp.setCharacterEncoding("UTF-8");
                java.util.Map<String, Object> map = new java.util.HashMap<>();
                map.put("success", false);
                map.put("error", "Lá»—i há»‡ thá»‘ng: " + e.getMessage());
                resp.getWriter().write(new com.google.gson.Gson().toJson(map));
            } else {
                session.setAttribute("error", "Lá»—i há»‡ thá»‘ng: " + e.getMessage());
                resp.sendRedirect(req.getContextPath() + "/manager/nhan-su?tab=leave");
            }
        }
    }

    /**
     * Kiá»ƒm tra xem user cÃ³ quyá»n truy cáº­p trang Manager khÃ´ng
     */
    private boolean isAuthorizedManager(TaiKhoan user, HttpServletRequest req, HttpServletResponse resp, HttpSession session)
            throws IOException {
        if (user == null) {
            session.setAttribute("error", "Vui lÃ²ng Ä‘Äƒng nháº­p Ä‘á»ƒ tiáº¿p tá»¥c");
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return false;
        }

        int roleId = user.getRoleId();
        // Admin (1) vÃ  Manager (2) Ä‘á»u cÃ³ thá»ƒ truy cáº­p
        if (roleId != 1 && roleId != 2) {
            logger.warn("Unauthorized access attempt by user ID: {}, role: {}", user.getAccountId(), roleId);
            session.setAttribute("error", "Báº¡n khÃ´ng cÃ³ quyá»n truy cáº­p trang nÃ y");
            resp.sendRedirect(req.getContextPath() + "/home");
            return false;
        }

        // Náº¿u lÃ  Manager, kiá»ƒm tra coSoId
        if (roleId == 2 && user.getCoSoId() == null) {
            logger.warn("Manager without CoSoID: {}", user.getAccountId());
            session.setAttribute("error", "TÃ i khoáº£n quáº£n lÃ½ chÆ°a Ä‘Æ°á»£c liÃªn káº¿t vá»›i cÆ¡ sá»Ÿ nÃ o");
            resp.sendRedirect(req.getContextPath() + "/home");
            return false;
        }

        return true;
    }

    private String buildYeuCauNghiJson(List<YeuCauNghi> requests) throws Exception {
        java.util.List<java.util.Map<String, Object>> list = new java.util.ArrayList<>();
        for (YeuCauNghi r : requests) {
            java.util.Map<String, Object> map = new java.util.HashMap<>();
            map.put("yeuCauNghiID", r.getYeuCauNghiID());
            map.put("accountId", r.getAccountID());
            map.put("tenNhanVien", r.getTenNhanVien() != null ? r.getTenNhanVien() : "");
            map.put("username", r.getUsername() != null ? r.getUsername() : "");
            map.put("roleName", r.getRoleName() != null ? r.getRoleName() : "");
            map.put("ngayNghi", r.getNgayNghi() != null ? r.getNgayNghi().toString() : "");
            map.put("loaiNghi", r.getLoaiNghi());
            map.put("lyDo", r.getLyDo());
            map.put("trangThai", r.getTrangThai());
            map.put("ngayGui", r.getNgayGui() != null ? r.getNgayGui().toString() : "");
            list.add(map);
        }
        return new com.google.gson.Gson().toJson(list);
    }
}
