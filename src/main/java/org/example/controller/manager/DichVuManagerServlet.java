package org.example.controller.manager;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.model.RacketStringingConfig;
import org.example.model.ServiceMaterial;
import org.example.model.SportService;
import org.example.model.TaiKhoan;
import org.example.service.AuditLogService;
import org.example.service.manager.SportServiceManagerService;
import org.example.util.Constants;

import java.io.IOException;
import java.time.LocalTime;
import java.util.List;

/**
 * Manager CRUD dịch vụ thể thao tại cơ sở (căng lưới, thay quấn cán, sửa vợt...).
 * Route bị FilterQuyenManager chặn ở tầng backend theo Constants.SERVICE_MODULE_CAPABILITIES
 * (capability DICH_VU_THE_THAO phải APPROVED) - servlet này KHÔNG tự kiểm tra lại
 * capability, chỉ kiểm tra role + quyền sở hữu coSoId (PHẦN 6 vẫn bắt buộc chặn ở
 * đây phòng trường hợp filter bị bypass do lỗi cấu hình web.xml trong tương lai).
 */
@WebServlet("/manager/dich-vu")
public class DichVuManagerServlet extends HttpServlet {

    private final SportServiceManagerService service = new SportServiceManagerService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/he-thong/dang-nhap");
            return;
        }
        if (user.getRoleId() != Constants.ROLE_MANAGER) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền truy cập chức năng này.");
            return;
        }

        int coSoId = user.getCoSoId();
        List<SportService> services = service.listByCoSo(coSoId);
        List<ServiceMaterial> materials = service.listMaterials(coSoId);

        String successMsg = (String) session.getAttribute("successMsg");
        String errorMsg = (String) session.getAttribute("errorMsg");
        session.removeAttribute("successMsg");
        session.removeAttribute("errorMsg");

        req.setAttribute("services", services);
        req.setAttribute("materials", materials);
        req.setAttribute("successMsg", successMsg);
        req.setAttribute("errorMsg", errorMsg);
        req.setAttribute("pageTitle", "Quản lý dịch vụ");
        req.getRequestDispatcher("/manager/DichVu.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/he-thong/dang-nhap");
            return;
        }
        if (user.getRoleId() != Constants.ROLE_MANAGER) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền thực hiện hành động này.");
            return;
        }

        int coSoId = user.getCoSoId();
        String action = req.getParameter("action");

        try {
            switch (action == null ? "" : action) {
                case "add-service":
                    handleAddService(req, session, user, coSoId);
                    break;
                case "update-service":
                    handleUpdateService(req, session, user, coSoId);
                    break;
                case "delete-service":
                    handleDeleteService(req, session, user, coSoId);
                    break;
                case "toggle-accepting":
                    handleToggleAccepting(req, session, coSoId);
                    break;
                case "add-material":
                    handleAddMaterial(req, session, user, coSoId);
                    break;
                case "update-material":
                    handleUpdateMaterial(req, session, user, coSoId);
                    break;
                case "delete-material":
                    handleDeleteMaterial(req, session, user, coSoId);
                    break;
                default:
                    session.setAttribute("errorMsg", "Hành động không hợp lệ.");
            }
        } catch (NumberFormatException e) {
            session.setAttribute("errorMsg", "Dữ liệu số không hợp lệ.");
        } catch (Exception e) {
            session.setAttribute("errorMsg", "Đã xảy ra lỗi hệ thống. Vui lòng thử lại.");
        }

        resp.sendRedirect(req.getContextPath() + "/manager/dich-vu");
    }

    private SportService buildServiceFromRequest(HttpServletRequest req) {
        SportService s = new SportService();
        s.setServiceType(req.getParameter("serviceType"));
        s.setServiceName(trim(req.getParameter("serviceName")));
        s.setSportType(trim(req.getParameter("sportType")));
        s.setDescription(trim(req.getParameter("description")));
        s.setBasePrice(parseDouble(req.getParameter("basePrice"), 0));
        s.setUnit(trim(req.getParameter("unit")));
        s.setEstimatedMinutes((int) parseDouble(req.getParameter("estimatedMinutes"), 60));
        String maxReq = req.getParameter("maxRequestsPerDay");
        s.setMaxRequestsPerDay(maxReq != null && !maxReq.trim().isEmpty() ? Integer.parseInt(maxReq.trim()) : null);
        s.setReceiveTimeStart(parseTime(req.getParameter("receiveTimeStart")));
        s.setReceiveTimeEnd(parseTime(req.getParameter("receiveTimeEnd")));
        s.setImageUrl(trim(req.getParameter("imageUrl")));
        s.setAcceptingRequests("on".equals(req.getParameter("acceptingRequests")) || "true".equals(req.getParameter("acceptingRequests")));
        s.setPolicy(trim(req.getParameter("policy")));
        s.setCustomerNote(trim(req.getParameter("customerNote")));
        return s;
    }

    private RacketStringingConfig buildConfigFromRequest(HttpServletRequest req) {
        if (!"CANG_LUOI".equals(req.getParameter("serviceType"))) return null;
        RacketStringingConfig c = new RacketStringingConfig();
        c.setRacketTypes(trim(req.getParameter("racketTypes")));
        c.setStringingPrice(parseDouble(req.getParameter("stringingPrice"), 0));
        c.setMinTension(parseDouble(req.getParameter("minTension"), 0));
        c.setMaxTension(parseDouble(req.getParameter("maxTension"), 0));
        String unit = req.getParameter("tensionUnit");
        c.setTensionUnit(unit != null && !unit.trim().isEmpty() ? unit.trim() : "kg");
        c.setAllowCustomerString("on".equals(req.getParameter("allowCustomerString")) || "true".equals(req.getParameter("allowCustomerString")));
        c.setSellsString("on".equals(req.getParameter("sellsString")) || "true".equals(req.getParameter("sellsString")));
        c.setAvgCompletionMinutes((int) parseDouble(req.getParameter("avgCompletionMinutes"), 60));
        c.setMaxRacketsPerOrder((int) parseDouble(req.getParameter("maxRacketsPerOrder"), 5));
        c.setOldRacketPolicy(trim(req.getParameter("oldRacketPolicy")));
        c.setStringBreakPolicy(trim(req.getParameter("stringBreakPolicy")));
        return c;
    }

    private void handleAddService(HttpServletRequest req, HttpSession session, TaiKhoan user, int coSoId) {
        SportService s = buildServiceFromRequest(req);
        RacketStringingConfig cfg = buildConfigFromRequest(req);
        SportServiceManagerService.Result r = service.createService(coSoId, s, cfg);
        if (r.success) {
            session.setAttribute("successMsg", "Thêm dịch vụ '" + s.getServiceName() + "' thành công.");
            AuditLogService.log(req, user, AuditLogService.ACTION_CREATE, "SportService",
                    String.valueOf(s.getServiceID()), s.getServiceName(), "Manager thêm dịch vụ thể thao");
        } else {
            session.setAttribute("errorMsg", r.errorMessage);
        }
    }

    private void handleUpdateService(HttpServletRequest req, HttpSession session, TaiKhoan user, int coSoId) {
        int id = Integer.parseInt(req.getParameter("serviceId"));
        SportService s = buildServiceFromRequest(req);
        RacketStringingConfig cfg = buildConfigFromRequest(req);
        SportServiceManagerService.Result r = service.updateService(coSoId, id, s, cfg);
        if (r.success) {
            session.setAttribute("successMsg", "Cập nhật dịch vụ thành công.");
            AuditLogService.log(req, user, AuditLogService.ACTION_UPDATE, "SportService",
                    String.valueOf(id), s.getServiceName(), "Manager cập nhật dịch vụ thể thao");
        } else {
            session.setAttribute("errorMsg", r.errorMessage);
        }
    }

    private void handleDeleteService(HttpServletRequest req, HttpSession session, TaiKhoan user, int coSoId) {
        int id = Integer.parseInt(req.getParameter("serviceId"));
        SportServiceManagerService.Result r = service.softDeleteService(coSoId, id);
        if (r.success) {
            session.setAttribute("successMsg", "Đã tắt dịch vụ.");
            AuditLogService.log(req, user, AuditLogService.ACTION_SOFT_DELETE, "SportService",
                    String.valueOf(id), null, "Manager xóa mềm dịch vụ thể thao");
        } else {
            session.setAttribute("errorMsg", r.errorMessage);
        }
    }

    private void handleToggleAccepting(HttpServletRequest req, HttpSession session, int coSoId) {
        int id = Integer.parseInt(req.getParameter("serviceId"));
        boolean accepting = "1".equals(req.getParameter("value"));
        SportServiceManagerService.Result r = service.toggleAccepting(coSoId, id, accepting);
        if (r.success) {
            session.setAttribute("successMsg", accepting ? "Đã bật nhận yêu cầu." : "Đã tạm dừng nhận yêu cầu.");
        } else {
            session.setAttribute("errorMsg", r.errorMessage);
        }
    }

    private ServiceMaterial buildMaterialFromRequest(HttpServletRequest req) {
        ServiceMaterial m = new ServiceMaterial();
        m.setName(trim(req.getParameter("materialName")));
        m.setBrand(trim(req.getParameter("materialBrand")));
        m.setCode(trim(req.getParameter("materialCode")));
        m.setColor(trim(req.getParameter("materialColor")));
        m.setSportType(trim(req.getParameter("materialSportType")));
        m.setPrice(parseDouble(req.getParameter("materialPrice"), 0));
        m.setExtraFee(parseDouble(req.getParameter("materialExtraFee"), 0));
        String status = req.getParameter("materialStatus");
        m.setStatus(status != null && !status.trim().isEmpty() ? status.trim() : "DANG_CO");
        m.setDescription(trim(req.getParameter("materialDescription")));
        return m;
    }

    private void handleAddMaterial(HttpServletRequest req, HttpSession session, TaiKhoan user, int coSoId) {
        ServiceMaterial m = buildMaterialFromRequest(req);
        SportServiceManagerService.Result r = service.createMaterial(coSoId, m);
        if (r.success) {
            session.setAttribute("successMsg", "Thêm vật tư '" + m.getName() + "' thành công.");
            AuditLogService.log(req, user, AuditLogService.ACTION_CREATE, "ServiceMaterial",
                    String.valueOf(m.getMaterialID()), m.getName(), "Manager thêm vật tư dịch vụ");
        } else {
            session.setAttribute("errorMsg", r.errorMessage);
        }
    }

    private void handleUpdateMaterial(HttpServletRequest req, HttpSession session, TaiKhoan user, int coSoId) {
        int id = Integer.parseInt(req.getParameter("materialId"));
        ServiceMaterial m = buildMaterialFromRequest(req);
        SportServiceManagerService.Result r = service.updateMaterial(coSoId, id, m);
        if (r.success) {
            session.setAttribute("successMsg", "Cập nhật vật tư thành công.");
            AuditLogService.log(req, user, AuditLogService.ACTION_UPDATE, "ServiceMaterial",
                    String.valueOf(id), m.getName(), "Manager cập nhật vật tư dịch vụ");
        } else {
            session.setAttribute("errorMsg", r.errorMessage);
        }
    }

    private void handleDeleteMaterial(HttpServletRequest req, HttpSession session, TaiKhoan user, int coSoId) {
        int id = Integer.parseInt(req.getParameter("materialId"));
        SportServiceManagerService.Result r = service.softDeleteMaterial(coSoId, id);
        if (r.success) {
            session.setAttribute("successMsg", "Đã xóa vật tư.");
            AuditLogService.log(req, user, AuditLogService.ACTION_SOFT_DELETE, "ServiceMaterial",
                    String.valueOf(id), null, "Manager xóa vật tư dịch vụ");
        } else {
            session.setAttribute("errorMsg", r.errorMessage);
        }
    }

    private static String trim(String s) { return s == null ? null : (s.trim().isEmpty() ? null : s.trim()); }

    private static double parseDouble(String s, double def) {
        if (s == null || s.trim().isEmpty()) return def;
        try { return Double.parseDouble(s.trim()); } catch (NumberFormatException e) { return def; }
    }

    private static LocalTime parseTime(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return LocalTime.parse(s.trim()); } catch (Exception e) { return null; }
    }
}
