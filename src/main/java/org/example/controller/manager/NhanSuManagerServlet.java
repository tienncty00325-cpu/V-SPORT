package org.example.controller.manager;



import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.model.TaiKhoan;
import org.example.service.manager.NhanSuService;
import org.example.service.manager.NhanSuService.NhanSuDTO;
import org.example.service.manager.NhanSuService.StaffCreateRequest;
import org.example.service.manager.NhanSuService.StaffUpdateRequest;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.service.AuditLogService;

import java.io.IOException;
import java.time.LocalTime;
import java.util.List;

@WebServlet("/manager/nhan-su")
public class NhanSuManagerServlet extends HttpServlet {

    private static final Logger logger = LogManager.getLogger(NhanSuManagerServlet.class);
    private final NhanSuService nhanSuService = new NhanSuService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        
        // Kiá»ƒm tra Ä‘Äƒng nháº­p
        if (session == null || session.getAttribute("user") == null) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }
        
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");
        
        // Kiểm tra quyền Manager (role 2)
        if (user.getRoleId() != 2) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền truy cập.");
            return;
        }
        
        Integer managerCoSoId = user.getCoSoId();
        if (managerCoSoId == null) {
            session.setAttribute("error", "Tài khoản quản lý chưa được liên kết với cơ sở nào.");
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        String action = req.getParameter("action");
        if ("list".equals(action)) {
            try {
                List<NhanSuDTO> staffList = nhanSuService.getStaffListByBranch(managerCoSoId);
                resp.setContentType("application/json");
                resp.setCharacterEncoding("UTF-8");
                String json = buildStaffListJson(staffList);
                resp.getWriter().write(json);
            } catch (Exception e) {
                logger.error("Error listing staff: {}", e.getMessage(), e);
                resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                resp.getWriter().write("Có lỗi xảy ra khi tải danh sách nhân viên.");
            }
            return;
        }
        if ("deletedList".equals(action)) {
            try {
                List<NhanSuDTO> staffList = nhanSuService.getDeletedStaffListByBranch(managerCoSoId);
                resp.setContentType("application/json");
                resp.setCharacterEncoding("UTF-8");
                String json = buildStaffListJson(staffList);
                resp.getWriter().write(json);
            } catch (Exception e) {
                logger.error("Error listing deleted staff: {}", e.getMessage(), e);
                resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                resp.getWriter().write("Có lỗi xảy ra khi tải danh sách nhân viên trong thùng rác.");
            }
            return;
        }
        
        // Forward tới trang nhân sự
        req.getRequestDispatcher("/manager/NhanSu.jsp").forward(req, resp);
    }
    
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        HttpSession session = req.getSession(false);
        
        // Kiá»ƒm tra Ä‘Äƒng nháº­p
        if (session == null || session.getAttribute("user") == null) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }
        
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");
        
        // Kiá»ƒm tra quyá»n Manager (role 2)
        if (user.getRoleId() != 2) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền truy cập.");
            return;
        }
        
        Integer managerCoSoId = user.getCoSoId();
        if (managerCoSoId == null) {
            session.setAttribute("error", "Tài khoản quản lý chưa được liên kết với cơ sở nào.");
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        String action = req.getParameter("action");
        try {
            if ("add".equals(action)) {
                String fullName = req.getParameter("fullName");
                String email = req.getParameter("email");
                String phoneNumber = req.getParameter("phoneNumber");
                int roleId = Integer.parseInt(req.getParameter("roleId"));
                String password = req.getParameter("password");

                // Trim inputs
                if (fullName != null) fullName = fullName.trim();
                if (email != null) email = email.trim();
                if (phoneNumber != null) phoneNumber = phoneNumber.trim();
                if (password != null) password = password.trim();

                // Validate fields (username generated internally – not from client)
                org.example.dao.TaiKhoanDAO taiKhoanDAO = new org.example.dao.impl.TaiKhoanDAOImpl();
                java.util.Map<String, String> errors = new java.util.LinkedHashMap<>();
                if (email == null || email.isEmpty()) errors.put("email", "Email không được để trống");
                else if (!org.example.util.ValidationUtil.isValidEmail(email)) errors.put("email", "Email không hợp lệ");
                if (taiKhoanDAO.kiemtraEmail(email)) errors.put("email", "Email đã tồn tại trên hệ thống");
                if (fullName == null || fullName.isEmpty()) errors.put("fullName", "Họ tên không được để trống");
                if (password == null || password.isEmpty()) errors.put("password", "Mật khẩu không được để trống");
                if (!errors.isEmpty()) throw new IllegalArgumentException(errors.toString());

                // Validate strong password
                org.example.util.ValidationUtils.validateStrongPassword(password);

                // Generate internal username from email
                String username = generateUniqueUsername(email, taiKhoanDAO);

                // Build TaiKhoan (but do NOT save yet – wait for OTP)
                TaiKhoan newAcc = new TaiKhoan();
                newAcc.setUsername(username);
                newAcc.setFullName(fullName);
                newAcc.setEmail(email);
                newAcc.setPhoneNumber(phoneNumber);
                newAcc.setRoleId(roleId);
                newAcc.setCoSoId(managerCoSoId);
                newAcc.setIsLocked(false);
                newAcc.setPassword(org.mindrot.jbcrypt.BCrypt.hashpw(password, org.mindrot.jbcrypt.BCrypt.gensalt(12)));

                // Send OTP to the provided email for verification
                String otpString = taiKhoanDAO.sendRegistrationOTP(email, fullName);
                session.setAttribute("otp", otpString);
                session.setAttribute("tempAccount", newAcc);
                session.setAttribute("tempRawPassword", password);
                session.setAttribute("tempManagerAccountId", user.getAccountId());
                session.setAttribute("authType", "MANAGER_ADD");
                session.setAttribute("otpAttempts", 0);
                session.setAttribute("resendCount", 0);
                session.setAttribute("needResend", false);

                String requestedWith = req.getHeader("X-Requested-With");
                if ("XMLHttpRequest".equals(requestedWith)) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"requiresOtp\": true, \"email\": \"" + email + "\"}");
                    return;
                }
                resp.sendRedirect(req.getContextPath() + "/auth/NhapMa.jsp");
                return;
            } 
            else if ("update".equals(action)) {
                int accountId = Integer.parseInt(req.getParameter("accountId"));
                String isLockedParam = req.getParameter("isLocked");
                
                StaffUpdateRequest updateReq = new StaffUpdateRequest();
                if (isLockedParam != null) {
                    updateReq.setIsLocked(Boolean.parseBoolean(isLockedParam));
                    nhanSuService.updateStaff(accountId, updateReq, managerCoSoId);
                    session.setAttribute("message", "Cập nhật trạng thái khóa thành công!");
                    resp.setStatus(HttpServletResponse.SC_OK);
                } else {
                    updateReq.setFullName(req.getParameter("fullName"));
                    updateReq.setEmail(req.getParameter("email"));
                    updateReq.setPhoneNumber(req.getParameter("phoneNumber"));
                    updateReq.setRoleId(Integer.parseInt(req.getParameter("roleId")));
                    updateReq.setPassword(req.getParameter("password"));

                    TaiKhoan account = nhanSuService.getStaffById(accountId, managerCoSoId);
                    org.example.util.BranchSecurityUtils.checkBranchAccess(account.getCoSoId(), managerCoSoId);
                    String newEmail = updateReq.getEmail();
                    if (newEmail != null) newEmail = newEmail.trim();

                    boolean isEmailChanged = (newEmail != null && !newEmail.equalsIgnoreCase(account.getEmail()));
                    if (isEmailChanged) {
                        org.example.util.ValidationUtils.validateEmail(newEmail);
                        if (new org.example.dao.impl.TaiKhoanDAOImpl().kiemtraEmail(newEmail)) {
                            throw new IllegalArgumentException("Email đã tồn tại trên hệ thống!");
                        }

                        account.setFullName(updateReq.getFullName());
                        account.setEmail(newEmail);
                        account.setPhoneNumber(updateReq.getPhoneNumber());
                        account.setRoleId(updateReq.getRoleId());
                        if (updateReq.getPassword() != null && !updateReq.getPassword().isEmpty()) {
                            org.example.util.ValidationUtils.validateStrongPassword(updateReq.getPassword());
                            account.setPassword(org.mindrot.jbcrypt.BCrypt.hashpw(updateReq.getPassword(), org.mindrot.jbcrypt.BCrypt.gensalt(12)));
                        }

                        String otpString = new org.example.dao.impl.TaiKhoanDAOImpl().sendRegistrationOTP(newEmail, account.getFullName());
                        session.setAttribute("otp", otpString);
                        session.setAttribute("tempAccount", account);
                        session.setAttribute("authType", "MANAGER_EDIT");
                        session.setAttribute("otpAttempts", 0);
                        session.setAttribute("resendCount", 0);
                        session.setAttribute("needResend", false);

                        String requestedWith = req.getHeader("X-Requested-With");
                        if ("XMLHttpRequest".equals(requestedWith)) {
                            resp.setContentType("application/json;charset=UTF-8");
                            resp.getWriter().write("{\"requiresOtp\": true, \"email\": \"" + newEmail + "\"}");
                            return;
                        }

                        resp.sendRedirect(req.getContextPath() + "/auth/NhapMa.jsp");
                    } else {
                        nhanSuService.updateStaff(accountId, updateReq, managerCoSoId);
                        session.setAttribute("message", "Cập nhật thông tin nhân viên thành công!");
                        String requestedWith = req.getHeader("X-Requested-With");
                        if ("XMLHttpRequest".equals(requestedWith)) {
                            resp.setContentType("application/json;charset=UTF-8");
                            resp.getWriter().write("{\"success\": true, \"message\": \"Cập nhật thông tin nhân viên thành công!\"}");
                            return;
                        }
                        resp.sendRedirect(req.getContextPath() + "/manager/nhan-su");
                    }
                }
            } 
            else if ("delete".equals(action)) {
                int accountId = Integer.parseInt(req.getParameter("id"));
                TaiKhoan staffToDelete = null;
                try { staffToDelete = nhanSuService.getStaffById(accountId, managerCoSoId); } catch (Exception ignored) {}
                String staffName = (staffToDelete != null && staffToDelete.getFullName() != null) ? staffToDelete.getFullName() : "ID=" + accountId;
                nhanSuService.deleteStaff(accountId, managerCoSoId);
                session.setAttribute("message", "Xóa nhân viên thành công! Bạn có thể vào trang Thùng rác để khôi phục.");
                AuditLogService.log(req, user,
                    AuditLogService.ACTION_SOFT_DELETE, AuditLogService.ENTITY_ACCOUNT,
                    String.valueOf(accountId), staffName,
                    "Manager xóa mềm nhân viên");
                resp.setStatus(HttpServletResponse.SC_OK);
            } 
            else if ("restore".equals(action)) {
                int accountId = Integer.parseInt(req.getParameter("id"));
                nhanSuService.restoreStaff(accountId, managerCoSoId);
                session.setAttribute("message", "Khôi phục nhân viên thành công!");
                resp.setStatus(HttpServletResponse.SC_OK);
            }
            else if ("permanentDelete".equals(action)) {
                // Hệ thống chỉ hỗ trợ soft delete/khôi phục. Từ chối an toàn request cũ đòi xóa
                // vĩnh viễn - không thực hiện xóa gì cả.
                resp.setStatus(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
                resp.setContentType("application/json;charset=UTF-8");
                resp.getWriter().write("{\"success\":false,\"code\":\"PERMANENT_DELETE_DISABLED\",\"message\":\"Hệ thống không hỗ trợ xóa vĩnh viễn.\"}");
            }
            else if ("addShift".equals(action)) {
                int accountId = Integer.parseInt(req.getParameter("accountId"));
                int thu = Integer.parseInt(req.getParameter("thu"));
                LocalTime gioBatDau = LocalTime.parse(req.getParameter("gioBatDau"));
                LocalTime gioKetThuc = LocalTime.parse(req.getParameter("gioKetThuc"));
                String ghiChu = req.getParameter("ghiChu");
                
                nhanSuService.addShiftPattern(accountId, managerCoSoId, thu, gioBatDau, gioKetThuc, ghiChu);
                session.setAttribute("message", "Thêm ca làm định kỳ thành công!");
                resp.setStatus(HttpServletResponse.SC_OK);
            } 
            else if ("deleteShift".equals(action)) {
                int accountId = Integer.parseInt(req.getParameter("accountId"));
                int thu = Integer.parseInt(req.getParameter("thu"));
                
                nhanSuService.deleteShiftPattern(accountId, thu, managerCoSoId);
                session.setAttribute("message", "Xóa ca làm định kỳ thành công!");
                resp.setStatus(HttpServletResponse.SC_OK);
            } 
            else {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Hành động không hợp lệ.");
            }
        } catch (IllegalArgumentException e) {
            String msg = e.getMessage();
            if (msg != null && msg.startsWith("{") && msg.endsWith("}")) {
                msg = msg.substring(1, msg.length() - 1);
                msg = msg.replaceAll("=", ": ").replaceAll(",", "; ");
            }
            logger.warn("Validation/Business error in NhanSuManagerServlet: {}", msg);
            session.setAttribute("error", msg);
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.setContentType("text/plain;charset=UTF-8");
            resp.getWriter().write(msg != null ? msg : "Yêu cầu không hợp lệ.");
        } catch (Exception e) {
            logger.error("Unexpected error in NhanSuManagerServlet doPost: {}", e.getMessage(), e);
            session.setAttribute("error", "Lỗi hệ thống. Vui lòng liên hệ quản trị viên.");
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.setContentType("text/plain;charset=UTF-8");
            resp.getWriter().write("Lỗi hệ thống. Vui lòng liên hệ quản trị viên.");
        }
    }

    private String generateUniqueUsername(String email, org.example.dao.TaiKhoanDAO dao) {
        String base = email.substring(0, email.indexOf('@'))
                .toLowerCase()
                .replaceAll("[^a-z0-9_]", "");
        if (base.length() < 3) base = (base + "vsport").substring(0, 6);
        if (base.length() > 30) base = base.substring(0, 30);
        if (!dao.kiemtraUsername(base)) return base;
        java.security.SecureRandom rng = new java.security.SecureRandom();
        for (int i = 0; i < 30; i++) {
            String cand = base + (100 + rng.nextInt(899900));
            if (!dao.kiemtraUsername(cand)) return cand;
        }
        return base + System.nanoTime() % 1_000_000_000L;
    }

    private String buildStaffListJson(List<NhanSuDTO> staffList) {
        java.util.List<java.util.Map<String, Object>> mappedList = new java.util.ArrayList<>();
        for (NhanSuDTO s : staffList) {
            java.util.Map<String, Object> map = new java.util.HashMap<>();
            map.put("id", String.valueOf(s.getAccountId()));
            map.put("username", s.getUsername());
            map.put("name", s.getFullName() != null ? s.getFullName() : s.getUsername());
            map.put("email", s.getEmail() != null ? s.getEmail() : "");
            map.put("phone", s.getPhoneNumber() != null ? s.getPhoneNumber() : "");
            map.put("roleId", s.getRoleId());
            map.put("VaiTro", s.getRoleName());
            map.put("status", s.isLocked() ? "Bị khóa" : "Đang làm");
            map.put("initial", s.getInitial());
            map.put("avatarUrl", s.getAvatarUrl() != null ? s.getAvatarUrl() : "");
            mappedList.add(map);
        }
        return new com.google.gson.Gson().toJson(mappedList);
    }
}
