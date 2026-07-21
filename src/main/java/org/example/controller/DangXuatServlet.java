package org.example.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.util.AuthPortalPolicy;

import java.io.IOException;

@WebServlet("/logout")
public class DangXuatServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);

        // Xác định role TRƯỚC khi invalidate — sau invalidate session không còn đọc được nữa.
        // Ưu tiên roleId lưu trực tiếp trong session (DangNhapServlet set khi login); nếu vắng,
        // rơi về Referer để đoán vùng nội bộ (trường hợp session đã hết hạn nhưng người dùng
        // bấm logout ngay trong /admin, /manager hoặc /staff).
        Integer roleId = session != null ? (Integer) session.getAttribute("roleId") : null;
        boolean redirectToInternalLogin = AuthPortalPolicy.isInternalRole(roleId)
                || isFromInternalArea(req);

        if (session != null) {
            session.invalidate();
        }

        // Xóa JSESSIONID cookie
        String cookiePath = req.getContextPath();
        if (cookiePath == null || cookiePath.isEmpty()) {
            cookiePath = "/";
        }
        Cookie jsessionid = new Cookie("JSESSIONID", "");
        jsessionid.setMaxAge(0);
        jsessionid.setPath(cookiePath);
        resp.addCookie(jsessionid);

        // Chống browser cache giữ trang sau logout (kể cả khi bấm Back)
        resp.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        resp.setHeader("Pragma", "no-cache");
        resp.setDateHeader("Expires", 0);

        String target = redirectToInternalLogin
                ? req.getContextPath() + "/he-thong/dang-nhap"
                : req.getContextPath() + "/index.jsp";
        resp.sendRedirect(target);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        doGet(req, resp);
    }

    /**
     * Suy đoán vùng nội bộ (admin/manager/staff) từ Referer khi session đã hết hạn/không có
     * roleId (VD: mở nhiều tab, session timeout ngay trước khi bấm logout). Chỉ dùng để chọn
     * trang đích hiển thị — không cấp quyền hay dữ liệu nhạy cảm.
     */
    private boolean isFromInternalArea(HttpServletRequest req) {
        String referer = req.getHeader("Referer");
        if (referer == null || referer.isBlank()) {
            return false;
        }
        try {
            java.net.URI uri = java.net.URI.create(referer);
            String path = uri.getPath();
            if (path == null) return false;
            String ctx = req.getContextPath();
            String relative = (ctx != null && !ctx.isEmpty() && path.startsWith(ctx))
                    ? path.substring(ctx.length())
                    : path;
            return relative.startsWith("/admin") || relative.startsWith("/manager") || relative.startsWith("/staff");
        } catch (IllegalArgumentException e) {
            return false;
        }
    }
}
