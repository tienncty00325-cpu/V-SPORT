package org.example.dto.payment;

import java.io.Serializable;

/**
 * Snapshot dữ liệu QR/thanh toán PayOS cho MỘT booking của khách (orderCode = DatSanID).
 *
 * Dùng để render trang QR nhúng của V-SPORT mà KHÔNG gọi lại PayOS mỗi lần tải trang:
 * - Được ghi vào HttpSession (fallback dùng ngay, không phụ thuộc migration) và, best-effort, vào
 *   các cột cache PayOS trên LichDatSan (bền vững qua reload/đa tab/đăng nhập lại - sau migration).
 * - qrPayload là chuỗi VietQR THÔ, được render thành PNG phía server (ZXing). KHÔNG chứa secret.
 * - checkoutUrl chỉ là fallback nội bộ, không dùng làm luồng mặc định.
 */
public class PayosQrData implements Serializable {
    private static final long serialVersionUID = 1L;

    public final int datSanId;
    public final Long orderCode;
    public final String paymentLinkId;
    public final String qrPayload;
    public final String checkoutUrl;
    public final String bin;
    public final String accountNumber;
    public final String accountName;
    public final long amount;
    public final String description;
    /** epoch seconds PayOS báo link hết hạn (có thể null). */
    public final Long expiresAtEpoch;

    public PayosQrData(int datSanId, Long orderCode, String paymentLinkId, String qrPayload,
                       String checkoutUrl, String bin, String accountNumber, String accountName,
                       long amount, String description, Long expiresAtEpoch) {
        this.datSanId = datSanId;
        this.orderCode = orderCode;
        this.paymentLinkId = paymentLinkId;
        this.qrPayload = qrPayload;
        this.checkoutUrl = checkoutUrl;
        this.bin = bin;
        this.accountNumber = accountNumber;
        this.accountName = accountName;
        this.amount = amount;
        this.description = description;
        this.expiresAtEpoch = expiresAtEpoch;
    }

    public boolean hasQr() {
        return qrPayload != null && !qrPayload.isBlank();
    }

    /** Khóa lưu trong HttpSession cho một booking cụ thể. */
    public static String sessionKey(int datSanId) {
        return "payosQr:" + datSanId;
    }
}
