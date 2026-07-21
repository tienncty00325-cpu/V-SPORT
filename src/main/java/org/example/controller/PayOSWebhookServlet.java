package org.example.controller;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.example.dao.PayOSPaymentAttemptDAO;
import org.example.dao.impl.PayOSPaymentAttemptDAOImpl;
import org.example.dto.payment.PayOSCredentials;
import org.example.dto.payment.PayOSFinalizeResult;
import org.example.service.PayOSConfigurationService;
import org.example.service.payos.PayOSClientFactory;
import org.example.service.payos.PayOSLegacyBookingFinalizationService;
import org.example.service.payos.PayOSPaymentFinalizationService;
import org.example.util.DBUtil;
import vn.payos.PayOS;
import vn.payos.exception.PayOSException;
import vn.payos.model.webhooks.WebhookData;

import java.io.BufferedReader;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Webhook PUBLIC nhận thông báo thanh toán từ PayOS. Route: /payos/webhook (không yêu cầu
 * đăng nhập, không qua session).
 *
 * HAI LUỒNG dùng chung route này, CẢ HAI đều verify bằng checksum key RIÊNG của từng CoSo (không
 * còn credentials toàn cục/biến môi trường):
 * 1. Manager/Staff checkout qua PayOSPaymentService: orderCode nằm trong bảng
 *    PayOSPaymentAttempt, tra CoSoID qua PayOSPaymentAttemptDAO trước khi verify.
 * 2. Khách đặt sân online qua DatSanServlet: orderCode = DatSanID, tra CoSoID qua
 *    LichDatSan/San trước khi verify.
 *
 * orderCode không được tin trước khi verify chữ ký - chỉ dùng để TRA xem nên verify bằng
 * checksum key nào, rồi verify lại bằng đúng SDK/checksum đó trước khi tin bất kỳ field nào khác.
 */
@WebServlet(urlPatterns = { "/payos/webhook" })
public class PayOSWebhookServlet extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(PayOSWebhookServlet.class.getName());
    private static final String PAYOS_SUCCESS_CODE = "00";
    private static final Gson gson = new Gson();

    private final PayOSPaymentAttemptDAO attemptDAO = new PayOSPaymentAttemptDAOImpl();
    private final PayOSConfigurationService payOSConfigurationService = new PayOSConfigurationService();
    private final PayOSPaymentFinalizationService finalizationService = new PayOSPaymentFinalizationService();
    private final PayOSLegacyBookingFinalizationService legacyFinalizationService =
            new PayOSLegacyBookingFinalizationService();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String rawBody = readRawBody(req);

        Long peekedOrderCode = peekOrderCode(rawBody);
        if (peekedOrderCode == null) {
            LOGGER.warning("PayOS webhook: không đọc được orderCode từ payload, bỏ qua");
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("Invalid payload");
            return;
        }

        Integer attemptCoSoId = lookupAttemptCoSoId(peekedOrderCode);
        if (attemptCoSoId != null) {
            handleNewFlowWebhook(rawBody, peekedOrderCode, attemptCoSoId, resp);
        } else {
            handleLegacyCustomerBookingWebhook(rawBody, peekedOrderCode, resp);
        }
    }

    /** Chỉ đọc orderCode ở mức JSON thô, KHÔNG tin bất kỳ field nào khác cho tới khi verify chữ ký xong. */
    private Long peekOrderCode(String rawBody) {
        try {
            JsonObject root = gson.fromJson(rawBody, JsonObject.class);
            if (root == null) return null;
            JsonObject data = root.has("data") && root.get("data").isJsonObject() ? root.getAsJsonObject("data") : root;
            if (data.has("orderCode")) return data.get("orderCode").getAsLong();
        } catch (Exception ignored) {
            // payload không đúng format mong đợi - để verify chữ ký (ở nhánh legacy) tự báo lỗi
        }
        return null;
    }

    private Integer lookupAttemptCoSoId(long orderCode) {
        try (java.sql.Connection c = DBUtil.getConnection()) {
            PayOSPaymentAttemptDAO.Row row = attemptDAO.findByOrderCode(c, orderCode);
            return row != null ? row.coSoId : null;
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "PayOS webhook: lỗi tra CoSoID cho orderCode=" + orderCode, e);
            return null;
        }
    }

    /** Luồng cũ: orderCode = DatSanID. Tra CoSoID qua LichDatSan -> San (không tin field khác của webhook). */
    private Integer lookupLegacyBookingCoSoId(long datSanId) {
        String sql = "SELECT s.CoSoID FROM LichDatSan l JOIN San s ON s.SanID = l.SanID WHERE l.DatSanID = ?";
        try (java.sql.Connection c = DBUtil.getConnection();
             java.sql.PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, datSanId);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("CoSoID") : null;
            }
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "PayOS webhook (legacy): lỗi tra CoSoID cho DatSanID=" + datSanId, e);
            return null;
        }
    }

    // ── Luồng MỚI: Manager/Staff checkout, credentials theo CoSoID ──

    private void handleNewFlowWebhook(String rawBody, long orderCode, int coSoId, HttpServletResponse resp) throws IOException {
        PayOSCredentials credentials = payOSConfigurationService.getCredentialsForPayment(coSoId);
        if (credentials == null) {
            LOGGER.warning(String.format("PayOS webhook: CoSoID=%d chưa cấu hình đủ PayOS, orderCode=%d", coSoId, orderCode));
            respondOk(resp, "CoSo not configured, ignored");
            return;
        }

        WebhookData data;
        PayOS client = PayOSClientFactory.create(credentials);
        try {
            data = client.webhooks().verify(rawBody);
        } catch (PayOSException e) {
            LOGGER.warning(String.format("PayOS webhook: xac thuc chu ky that bai (CoSoID=%d, orderCode=%d) - %s", coSoId, orderCode, e.getMessage()));
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("Invalid webhook");
            return;
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "PayOS webhook: loi khong xac dinh khi xac thuc (luong moi)", e);
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("Invalid webhook");
            return;
        } finally {
            client.close();
        }

        if (!PAYOS_SUCCESS_CODE.equals(data.getCode())) {
            LOGGER.info(String.format("PayOS webhook: orderCode=%d code=%s khong phai thanh cong, bo qua", orderCode, data.getCode()));
            respondOk(resp, "Payment not successful, ignored");
            return;
        }

        PayOSFinalizeResult result = finalizationService.finalizePaidPayment(
                data.getOrderCode(), data.getAmount(), data.getPaymentLinkId(), data.getReference(), "PAYOS_WEBHOOK");
        if (result.isSuccess()) {
            respondOk(resp, result.isAlreadyPaid() ? "Already confirmed" : "Confirmed");
        } else {
            // Không cập nhật DB khi mismatch/not-found - vẫn trả 200 để PayOS không lặp lại vô ích
            // (giống hành vi cũ với amount mismatch), lỗi đã được log trong finalizationService.
            respondOk(resp, "Ignored: " + result.getCode());
        }
    }

    // ── Luồng CŨ: khách đặt sân online, orderCode=DatSanID, credentials RIÊNG của cơ sở sân đó ──

    private void handleLegacyCustomerBookingWebhook(String rawBody, long peekedOrderCode, HttpServletResponse resp) throws IOException {
        Integer coSoId = lookupLegacyBookingCoSoId(peekedOrderCode);
        if (coSoId == null) {
            LOGGER.warning("PayOS webhook (legacy): không tìm thấy booking cho DatSanID=" + peekedOrderCode);
            respondOk(resp, "Booking not found, ignored");
            return;
        }
        PayOSCredentials credentials = payOSConfigurationService.getCredentialsForPayment(coSoId);
        if (credentials == null) {
            LOGGER.warning(String.format(
                    "PayOS webhook (legacy): CoSoID=%d chưa cấu hình đủ PayOS, DatSanID=%d", coSoId, peekedOrderCode));
            respondOk(resp, "CoSo not configured, ignored");
            return;
        }

        WebhookData data;
        PayOS client = PayOSClientFactory.create(credentials);
        try {
            data = client.webhooks().verify(rawBody);
        } catch (PayOSException e) {
            LOGGER.log(Level.WARNING, "PayOS webhook (legacy): xác thực chữ ký thất bại - " + e.getMessage());
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.setContentType("text/plain; charset=UTF-8");
            resp.getWriter().write("Invalid webhook");
            return;
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "PayOS webhook (legacy): lỗi không xác định khi xác thực", e);
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.setContentType("text/plain; charset=UTF-8");
            resp.getWriter().write("Invalid webhook");
            return;
        } finally {
            client.close();
        }

        Long orderCode = data.getOrderCode();
        Long amount = data.getAmount();
        String code = data.getCode();
        int datSanId = orderCode.intValue();

        LOGGER.info(String.format(
                "PayOS webhook nhan: orderCode=%d amount=%d code=%s -> DatSanID=%d",
                orderCode, amount, code, datSanId));

        if (!PAYOS_SUCCESS_CODE.equals(code)) {
            LOGGER.warning(String.format(
                    "PayOS webhook: DatSanID=%d webhook code='%s' khong phai thanh cong, khong xac nhan",
                    datSanId, code));
            respondOk(resp, "Payment not successful, ignored");
            return;
        }

        // Toàn bộ việc xác minh trạng thái/số tiền + tạo-hoặc-lấy MAIN invoice + ghi nhận thanh
        // toán chạy TRONG MỘT transaction có khóa (PayOSLegacyBookingFinalizationService) - idempotent
        // với webhook retry, và xử lý đúng race "Quá hạn nhưng thanh toán đến đồng thời".
        PayOSLegacyBookingFinalizationService.Result result =
                legacyFinalizationService.confirmPaid(datSanId, BigDecimal.valueOf(amount), data.getReference());

        switch (result.code()) {
            case CONFIRMED, ALREADY_CONFIRMED -> {
                LOGGER.info(String.format(
                        "PayOS webhook: DatSanID=%d da duoc xac nhan (hoaDonId=%s, %s)",
                        datSanId, result.hoaDonId(), result.code()));
                respondOk(resp, result.code() == PayOSLegacyBookingFinalizationService.ResultCode.ALREADY_CONFIRMED
                        ? "Already confirmed" : "Confirmed");
            }
            case NOT_FOUND -> respondOk(resp, "Booking not found, ignored");
            case CANCELLED -> respondOk(resp, "Already cancelled, ignored");
            case AMOUNT_MISMATCH -> respondOk(resp, "Amount mismatch, ignored");
            case UNEXPECTED_STATUS -> respondOk(resp, "Unexpected status, ignored");
            case DATABASE_ERROR -> respondOk(resp, "Update skipped");
        }
    }

    private String readRawBody(HttpServletRequest req) throws IOException {
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new java.io.InputStreamReader(req.getInputStream(), StandardCharsets.UTF_8))) {
            char[] buffer = new char[1024];
            int read;
            while ((read = reader.read(buffer)) != -1) {
                sb.append(buffer, 0, read);
            }
        }
        return sb.toString();
    }

    private void respondOk(HttpServletResponse resp, String message) throws IOException {
        resp.setStatus(HttpServletResponse.SC_OK);
        resp.setContentType("text/plain; charset=UTF-8");
        resp.getWriter().write(message);
    }
}
