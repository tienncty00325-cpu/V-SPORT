package org.example.controller;


import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.model.TaiKhoan;
import org.example.dao.TaiKhoanDAO;
import org.example.dao.impl.TaiKhoanDAOImpl;
import org.example.util.ValidationUtil;
import org.mindrot.jbcrypt.BCrypt;

import java.io.IOException;

@WebServlet("/dangky")
public class DangKyServlet extends HttpServlet {

    private static final Logger logger = LogManager.getLogger(DangKyServlet.class);
    private TaiKhoanDAO TaiKhoanDAO = new TaiKhoanDAOImpl();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        jakarta.servlet.http.HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("user") != null) {
            resp.sendRedirect(req.getContextPath() + "/index.jsp");
        } else {
            // Điều hướng sang trang chủ với biến auth để mở modal
            resp.sendRedirect(req.getContextPath() + "/index.jsp?auth=register");
        }
    }


    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            req.setCharacterEncoding("UTF-8");
            String username = req.getParameter("username");
            String password = req.getParameter("password");
            String email = req.getParameter("email");
            String phone = req.getParameter("phone");
            String fullname = req.getParameter("fullname");
            String comfirmpassword = req.getParameter("confirm_password");

            if (username != null) username = username.trim();
            if (password != null) password = password.trim();
            if (email != null) email = email.trim();
            if (phone != null) phone = phone.trim();
            if (fullname != null) fullname = fullname.trim();
            if (comfirmpassword != null) comfirmpassword = comfirmpassword.trim();

            String dobStr = req.getParameter("dob");
            String gender = req.getParameter("gender");
            String viTriSoTruong = req.getParameter("viTriSoTruong");
            String maNganHang = req.getParameter("maNganHang");
            String soTaiKhoan = req.getParameter("soTaiKhoan");

            String[] sports = req.getParameterValues("sport");
            String[] dongy = req.getParameterValues("agree");

            // Giữ lại giá trị người dùng đã nhập khi form bị trả về vì lỗi validation.
            req.setAttribute("phone", phone);
            req.setAttribute("regEmail", email);
            req.setAttribute("fullname", fullname);

            String requestedWith = req.getHeader("X-Requested-With");
            boolean isAjax = "XMLHttpRequest".equals(requestedWith);

            if (password == null || comfirmpassword == null || !password.equals(comfirmpassword)) {
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": false, \"loi\": \"Mật khẩu không trùng khớp!\"}");
                    return;
                }
                req.setAttribute("loi", "Mật khẩu không trùng khớp!");
                req.getRequestDispatcher("/auth/DangKy.jsp").forward(req, resp);
                return;
            }

            if (!ValidationUtil.isStrongPassword(password)) {
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": false, \"loi\": \"Mật khẩu phải có tối thiểu 8 ký tự, bao gồm cả chữ hoa, chữ thường, số và ký tự đặc biệt.\"}");
                    return;
                }
                req.setAttribute("loi", "Mật khẩu phải có tối thiểu 8 ký tự, bao gồm cả chữ hoa, chữ thường, số và ký tự đặc biệt.");
                req.getRequestDispatcher("/auth/DangKy.jsp").forward(req, resp);
                return;
            }

            if (dongy == null || !dongy[0].equals("Đồng ý")) {
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": false, \"loi\": \"Bạn chưa đồng ý với điều khoản!\"}");
                    return;
                }
                req.setAttribute("loi", "Bạn chưa đồng ý với điều khoản!");
                req.getRequestDispatcher("/auth/DangKy.jsp").forward(req, resp);
                return;
            }

            // Form đăng ký mới không còn field tên đăng nhập: tự sinh username duy nhất
            // từ email. Nếu client cũ vẫn gửi username thì giữ nguyên validation cũ.
            boolean usernameProvided = username != null && !username.isEmpty();
            if (usernameProvided && !ValidationUtil.isValidUsername(username)) {
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": false, \"loi\": \"Tên đăng nhập không hợp lệ (3-50 ký tự, không chứa khoảng trắng)!\"}");
                    return;
                }
                req.setAttribute("loi", "Tên đăng nhập không hợp lệ (3-50 ký tự, không chứa khoảng trắng)!");
                req.getRequestDispatcher("/auth/DangKy.jsp").forward(req, resp);
                return;
            }

            if (!ValidationUtil.isValidEmail(email)) {
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": false, \"loi\": \"Email không hợp lệ và không được chứa khoảng trắng!\"}");
                    return;
                }
                req.setAttribute("loi", "Email không hợp lệ và không được chứa khoảng trắng!");
                req.getRequestDispatcher("/auth/DangKy.jsp").forward(req, resp);
                return;
            }

            String normalizedPhone = org.example.util.PhoneUtil.normalizeVN(phone);
            if (normalizedPhone == null) {
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": false, \"loi\": \"Số điện thoại không hợp lệ. Vui lòng nhập số di động Việt Nam (0, +84 hoặc 84).\"}");
                    return;
                }
                req.setAttribute("loi", "Số điện thoại không hợp lệ. Vui lòng nhập số di động Việt Nam (0, +84 hoặc 84).");
                req.getRequestDispatcher("/auth/DangKy.jsp").forward(req, resp);
                return;
            }

            if (fullname == null || fullname.isEmpty() || fullname.length() < 2 || fullname.length() > 100) {
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": false, \"loi\": \"Vui lòng nhập họ và tên hợp lệ (2-100 ký tự).\"}");
                    return;
                }
                req.setAttribute("loi", "Vui lòng nhập họ và tên hợp lệ (2-100 ký tự).");
                req.getRequestDispatcher("/auth/DangKy.jsp").forward(req, resp);
                return;
            }

            if (TaiKhoanDAO.kiemtraPhone(org.example.util.PhoneUtil.lookupVariants(normalizedPhone))) {
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": false, \"loi\": \"Số điện thoại đã được đăng ký. Vui lòng dùng số khác hoặc đăng nhập.\"}");
                    return;
                }
                req.setAttribute("loi", "Số điện thoại đã được đăng ký. Vui lòng dùng số khác hoặc đăng nhập.");
                req.getRequestDispatcher("/auth/DangKy.jsp").forward(req, resp);
                return;
            }

            if (!usernameProvided) {
                username = generateUniqueUsername(email);
            }

            if (usernameProvided && TaiKhoanDAO.kiemtraUsername(username)) {
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": false, \"loi\": \"Tên đăng nhập đã tồn tại!\"}");
                    return;
                }
                req.setAttribute("loi", "Tên đăng nhập đã tồn tại!");
                req.getRequestDispatcher("/auth/DangKy.jsp").forward(req, resp);
                return;
            }
            if (TaiKhoanDAO.kiemtraEmail(email)) {
                if (isAjax) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\": false, \"loi\": \"Email đã tồn tại!\"}");
                    return;
                }
                req.setAttribute("loi", "Email đã tồn tại!");
                req.getRequestDispatcher("/auth/DangKy.jsp").forward(req, resp);
                return;
            }

            java.util.Date dob = null;
            if (dobStr != null && !dobStr.trim().isEmpty()) {
                try {
                    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd");
                    dob = sdf.parse(dobStr);
                } catch (Exception e) {
                    System.err.println("Lỗi parse ngày sinh: " + e.getMessage());
                }
            }

            // Gửi OTP (đã được làm bất đồng bộ trong DAOImpl)
            String otpString = TaiKhoanDAO.sendRegistrationOTP(email, fullname);
            req.getSession().setAttribute("otp", otpString);

            // Lưu thông tin đăng ký vào session để chờ xác thực OTP
            TaiKhoan tempAccount = new TaiKhoan();
            tempAccount.setUsername(username);
            tempAccount.setPassword(BCrypt.hashpw(password, BCrypt.gensalt(12)));
            tempAccount.setFullName(fullname);
            tempAccount.setPhoneNumber(normalizedPhone);
            tempAccount.setEmail(email);
            tempAccount.setGioiTinh(gender);
            tempAccount.setNgaySinh(dob);
            tempAccount.setViTriSoTruong(viTriSoTruong);
            tempAccount.setMaNganHang(maNganHang);
            tempAccount.setSoTaiKhoan(soTaiKhoan);

            req.getSession().setAttribute("tempAccount", tempAccount);
            req.getSession().setAttribute("tempSports", sports);
            req.getSession().setAttribute("authType", "REGISTER");

            req.setAttribute("email", email);

            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                String redirectUrl = req.getContextPath() + "/auth/NhapMa.jsp?email=" + java.net.URLEncoder.encode(email, "UTF-8");
                resp.getWriter().write("{\"success\": true, \"redirectUrl\": \"" + redirectUrl + "\", \"step\": \"otp\", \"email\": \"" + email + "\"}");
                return;
            }

            req.getRequestDispatcher("/auth/NhapMa.jsp").forward(req, resp);

        } catch (Exception e) {
            logger.error("Lỗi nghiêm trọng trong DangKyServlet", e);

            String requestedWith = req.getHeader("X-Requested-With");
            boolean isAjax = "XMLHttpRequest".equals(requestedWith);
            if (isAjax) {
                resp.setContentType("application/json;charset=UTF-8");
                try {
                    resp.getWriter().write("{\"success\": false, \"loi\": \"Lỗi hệ thống: " + e.getMessage() + "\"}");
                } catch (Exception ex) {
                    logger.error("Lỗi khi gửi phản hồi AJAX", ex);
                }
                return;
            }
            
            req.setAttribute("loi", "Lỗi hệ thống: " + e.getMessage());
            req.getRequestDispatcher("/auth/DangKy.jsp").forward(req, resp);
        }
    }

    /**
     * Sinh username duy nhất từ phần local của email (form đăng ký không còn field
     * tên đăng nhập). Đảm bảo khớp USERNAME_REGEX của ValidationUtil: [A-Za-z0-9_]{3,50}.
     */
    private String generateUniqueUsername(String email) {
        String base = email.substring(0, email.indexOf('@'))
                .toLowerCase()
                .replaceAll("[^a-z0-9_]", "");
        if (base.length() < 3) {
            base = (base + "vsport").substring(0, 6);
        }
        if (base.length() > 30) {
            base = base.substring(0, 30);
        }
        if (!TaiKhoanDAO.kiemtraUsername(base)) {
            return base;
        }
        java.security.SecureRandom random = new java.security.SecureRandom();
        for (int attempt = 0; attempt < 30; attempt++) {
            String candidate = base + (100 + random.nextInt(899900));
            if (!TaiKhoanDAO.kiemtraUsername(candidate)) {
                return candidate;
            }
        }
        return base + System.nanoTime() % 1_000_000_000L;
    }
}

