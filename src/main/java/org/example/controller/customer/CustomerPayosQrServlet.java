package org.example.controller.customer;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.dto.payment.PayosQrData;
import org.example.model.TaiKhoan;
import org.example.util.Constants;
import org.example.util.DBUtil;
import org.example.util.QrCodeRenderer;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Trang QR thanh toán NHÚNG của V-SPORT (không redirect sang giao diện checkout PayOS).
 *
 *  GET /customer/thanh-toan-qr?datSanId=...  → render trang QR (state: waiting/paid/expired/cancelled)
 *  GET /customer/qr-image?datSanId=...       → stream ảnh PNG của payload VietQR (ZXing, server-side)
 *
 * Nguồn dữ liệu QR (không gọi lại PayOS khi tải trang):
 *  1) HttpSession holder (ghi khi tạo/tái tạo link ở DatSanServlet) — dùng ngay, không cần migration.
 *  2) Cột cache PayOS trên LichDatSan (bền vững qua reload/đa tab/đăng nhập lại) — đọc phòng thủ,
 *     bỏ qua nếu cột chưa tồn tại (chưa chạy migration).
 *
 * Trạng thái booking (LichDatSan.TrangThai) là nguồn sự thật; các cột Payos* chỉ là cache render.
 * Mọi endpoint đều kiểm tra đăng nhập + quyền sở hữu (booking phải thuộc khách đang đăng nhập).
 * Xác nhận thanh toán KHÔNG diễn ra ở đây — chỉ webhook/polling đã xác thực mới đổi trạng thái.
 */
@WebServlet(urlPatterns = { "/customer/thanh-toan-qr", "/customer/qr-image" })
public class CustomerPayosQrServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(CustomerPayosQrServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String path = req.getServletPath();
        HttpSession session = req.getSession();
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");
        boolean isImage = "/customer/qr-image".equals(path);

        if (user == null) {
            if (isImage) { resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED); return; }
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        Integer datSanId = parseInt(req.getParameter("datSanId"));
        if (datSanId == null) {
            if (isImage) { resp.setStatus(HttpServletResponse.SC_BAD_REQUEST); return; }
            resp.sendRedirect(req.getContextPath() + "/customer/dat-san?openHistory=true");
            return;
        }

        Booking booking = loadBooking(datSanId);
        if (booking == null || booking.accountId == null || !booking.accountId.equals(user.getAccountId())) {
            // Không tiết lộ đơn của người khác — cùng phản hồi như "không tìm thấy".
            if (isImage) { resp.setStatus(HttpServletResponse.SC_NOT_FOUND); return; }
            session.setAttribute("error", "Không tìm thấy đơn đặt sân của bạn.");
            resp.sendRedirect(req.getContextPath() + "/customer/dat-san?openHistory=true");
            return;
        }

        if (isImage) {
            streamQrImage(req, resp, session, datSanId, booking);
        } else {
            renderPage(req, resp, session, datSanId, booking);
        }
    }

    // ───────────────────────────── QR PNG ─────────────────────────────

    private void streamQrImage(HttpServletRequest req, HttpServletResponse resp, HttpSession session,
                               int datSanId, Booking booking) throws IOException {
        PayosQrData qr = resolveQrData(session, datSanId, booking);
        if (qr == null || !qr.hasQr()) {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        int size = clampSize(parseInt(req.getParameter("size")));
        try {
            byte[] png = QrCodeRenderer.toPngBytes(qr.qrPayload, size);
            resp.setContentType("image/png");
            resp.setHeader("Cache-Control", "private, max-age=60");
            resp.setContentLength(png.length);
            resp.getOutputStream().write(png);
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "QR render lỗi datSanId=" + datSanId + " loại=" + e.getClass().getSimpleName());
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    // ───────────────────────────── Trang QR ─────────────────────────────

    private void renderPage(HttpServletRequest req, HttpServletResponse resp, HttpSession session,
                            int datSanId, Booking booking) throws ServletException, IOException {
        String tt = booking.trangThai;
        // HoldExpiresAt lưu UTC → so sánh bằng Instant UTC, KHÔNG dùng LocalDateTime.now() (giờ JVM/VN)
        // để tránh kết luận hết hạn sai do lệch múi giờ.
        boolean holdExpired = org.example.util.TimeUtil.isPastUtc(booking.holdExpiresAt);

        String state;
        if (Constants.TRANG_THAI_DAT_SAN_DA_XAC_NHAN.equals(tt)) {
            state = "PAID";
        } else if (Constants.TRANG_THAI_DAT_SAN_DA_HUY.equals(tt)) {
            state = "CANCELLED";
        } else if (Constants.TRANG_THAI_DAT_SAN_QUA_HAN.equals(tt) || (Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN.equals(tt) && holdExpired)) {
            state = "EXPIRED";
        } else if (Constants.TRANG_THAI_DAT_SAN_CHO_THANH_TOAN.equals(tt)) {
            state = "WAITING";
        } else {
            // "Chờ xác nhận" (trả tại quầy) hoặc trạng thái khác — trang QR không áp dụng.
            resp.sendRedirect(req.getContextPath() + "/customer/dat-san?openHistory=true");
            return;
        }

        PayosQrData qr = resolveQrData(session, datSanId, booking);
        boolean qrAvailable = qr != null && qr.hasQr();

        req.setAttribute("datSanId", datSanId);
        req.setAttribute("state", state);
        req.setAttribute("qrAvailable", qrAvailable);
        req.setAttribute("tenCoSo", booking.tenCoSo);
        req.setAttribute("diaChi", booking.diaChi);
        req.setAttribute("tenSan", booking.tenSan);
        req.setAttribute("ngayDat", booking.ngayDat);
        req.setAttribute("gioBatDau", booking.gioBatDau);
        req.setAttribute("gioKetThuc", booking.gioKetThuc);

        long amount = booking.tongTien != null ? booking.tongTien.setScale(0, java.math.RoundingMode.HALF_UP).longValueExact() : 0L;
        if (qr != null && qr.amount > 0) amount = qr.amount;
        req.setAttribute("amount", amount);
        req.setAttribute("maDatSan", "VSport DS" + datSanId);

        if (qr != null) {
            req.setAttribute("bankBin", qr.bin);
            req.setAttribute("accountNumber", qr.accountNumber);
            req.setAttribute("accountName", qr.accountName);
            req.setAttribute("transferContent", qr.description != null ? qr.description : "VSport DS" + datSanId);
            req.setAttribute("bankName", bankNameFromBin(qr.bin));
        } else {
            req.setAttribute("transferContent", "VSport DS" + datSanId);
        }

        // Đồng hồ đếm ngược: HoldExpiresAt (UTC) là mốc giữ chỗ thật (giải phóng slot). Trình duyệt tự
        // hiển thị theo giờ địa phương của khách. PayosExpiresAt chỉ là fallback; NULL KHÔNG => hết hạn.
        java.time.Instant holdInstant = org.example.util.TimeUtil.fromUtcNaive(booking.holdExpiresAt);
        Long expiresAtEpochMs = null;
        if (holdInstant != null) {
            expiresAtEpochMs = holdInstant.toEpochMilli();
        } else if (qr != null && qr.expiresAtEpoch != null) {
            expiresAtEpochMs = qr.expiresAtEpoch * 1000L;
        }
        req.setAttribute("expiresAtEpochMs", expiresAtEpochMs);

        // Log an toàn để chẩn đoán hết hạn/timezone (KHÔNG log QR payload đầy đủ hay secret PayOS).
        LOGGER.info(String.format(
                "PAYOS_QR_RENDER datSanId=%d state=%s bookingStatus=%s currentInstant=%s holdExpiresAtInstant=%s secondsRemaining=%d qrPayloadPresent=%b",
                datSanId, state, tt, java.time.Instant.now(),
                holdInstant != null ? holdInstant.toString() : "null",
                org.example.util.TimeUtil.secondsUntilUtc(booking.holdExpiresAt), qrAvailable));

        resp.setHeader("Cache-Control", "no-store");
        req.getRequestDispatcher("/customer/ThanhToanQR.jsp").forward(req, resp);
    }

    // ───────────────────────────── Data access ─────────────────────────────

    /** Ưu tiên holder trong session (không cần migration); nếu thiếu, đọc cache DB (phòng thủ). */
    private PayosQrData resolveQrData(HttpSession session, int datSanId, Booking booking) {
        Object holder = session.getAttribute(PayosQrData.sessionKey(datSanId));
        if (holder instanceof PayosQrData d && d.hasQr()) {
            return d;
        }
        return loadQrCacheFromDb(datSanId, booking);
    }

    /** Đọc các cột cache PayOS trên LichDatSan. Trả null nếu chưa có payload HOẶC cột chưa tồn tại. */
    private PayosQrData loadQrCacheFromDb(int datSanId, Booking booking) {
        String sql = "SELECT PayosOrderCode, PayosPaymentLinkId, PayosQrPayload, PayosCheckoutUrl, "
                + "PayosBin, PayosAccountNumber, PayosAccountName, PayosAmount, PayosDescription, PayosExpiresAt "
                + "FROM LichDatSan WHERE DatSanID = ?";
        try (Connection c = DBUtil.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, datSanId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                String payload = rs.getString("PayosQrPayload");
                if (payload == null || payload.isBlank()) return null;
                long orderCode = rs.getLong("PayosOrderCode");
                BigDecimal amt = rs.getBigDecimal("PayosAmount");
                // PayosExpiresAt lưu UTC → đọc thành Instant UTC (TimeUtil.fromDb), không lệ thuộc giờ JVM.
                java.time.Instant expInstant = org.example.util.TimeUtil.fromDb(rs.getTimestamp("PayosExpiresAt"));
                Long expEpoch = expInstant != null ? expInstant.getEpochSecond() : null;
                return new PayosQrData(datSanId,
                        rs.wasNull() ? null : orderCode,
                        rs.getString("PayosPaymentLinkId"), payload, rs.getString("PayosCheckoutUrl"),
                        rs.getString("PayosBin"), rs.getString("PayosAccountNumber"), rs.getString("PayosAccountName"),
                        amt != null ? amt.longValue() : (booking.tongTien != null ? booking.tongTien.longValue() : 0L),
                        rs.getString("PayosDescription"), expEpoch);
            }
        } catch (SQLException e) {
            // Cột chưa tồn tại (chưa chạy migration) hoặc lỗi đọc — coi như không có cache, dùng session.
            LOGGER.log(Level.FINE, "Không đọc được cache QR (có thể chưa chạy migration) datSanId=" + datSanId);
            return null;
        }
    }

    private Booking loadBooking(int datSanId) {
        String sql = "SELECT l.AccountID, l.TrangThai, l.NgayDat, l.GioBatDau, l.GioKetThuc, l.TongTienDuKien, "
                + "l.HoldExpiresAt, s.TenSan, cs.TenCoSo, cs.DiaChi "
                + "FROM LichDatSan l JOIN San s ON s.SanID = l.SanID JOIN CoSo cs ON cs.CoSoID = s.CoSoID "
                + "WHERE l.DatSanID = ?";
        try (Connection c = DBUtil.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, datSanId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Booking b = new Booking();
                int acc = rs.getInt("AccountID");
                b.accountId = rs.wasNull() ? null : acc;
                b.trangThai = rs.getString("TrangThai");
                java.sql.Date d = rs.getDate("NgayDat");
                b.ngayDat = d != null ? d.toLocalDate() : null;
                java.sql.Time t1 = rs.getTime("GioBatDau");
                b.gioBatDau = t1 != null ? t1.toLocalTime() : null;
                java.sql.Time t2 = rs.getTime("GioKetThuc");
                b.gioKetThuc = t2 != null ? t2.toLocalTime() : null;
                b.tongTien = rs.getBigDecimal("TongTienDuKien");
                Timestamp h = rs.getTimestamp("HoldExpiresAt");
                b.holdExpiresAt = h != null ? h.toLocalDateTime() : null;
                b.tenSan = rs.getString("TenSan");
                b.tenCoSo = rs.getString("TenCoSo");
                b.diaChi = rs.getString("DiaChi");
                return b;
            }
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Lỗi tải booking cho trang QR datSanId=" + datSanId, e);
            return null;
        }
    }

    // ───────────────────────────── helpers ─────────────────────────────

    private static Integer parseInt(String s) {
        if (s == null || s.isBlank()) return null;
        try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return null; }
    }

    private static int clampSize(Integer s) {
        if (s == null) return 320;
        return Math.max(200, Math.min(s, 640));
    }

    /** Tên ngân hàng thân thiện từ BIN (best-effort; không có thì hiển thị chung). Chỉ dữ liệu công khai. */
    private static String bankNameFromBin(String bin) {
        if (bin == null) return null;
        switch (bin.trim()) {
            case "970436": return "Vietcombank";
            case "970415": return "VietinBank";
            case "970418": return "BIDV";
            case "970405": return "Agribank";
            case "970422": return "MB Bank";
            case "970407": return "Techcombank";
            case "970416": return "ACB";
            case "970432": return "VPBank";
            case "970423": return "TPBank";
            case "970403": return "Sacombank";
            case "970437": return "HDBank";
            case "970443": return "SHB";
            case "970431": return "Eximbank";
            case "970448": return "OCB";
            case "970454": return "VietCapital Bank";
            default: return null;
        }
    }

    private static final class Booking {
        Integer accountId;
        String trangThai;
        java.time.LocalDate ngayDat;
        java.time.LocalTime gioBatDau;
        java.time.LocalTime gioKetThuc;
        BigDecimal tongTien;
        LocalDateTime holdExpiresAt;
        String tenSan;
        String tenCoSo;
        String diaChi;
    }
}
