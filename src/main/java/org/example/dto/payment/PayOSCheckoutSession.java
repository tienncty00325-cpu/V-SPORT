package org.example.dto.payment;

/**
 * Tên tiếng Việt: Đối tượng chứa thông tin phiên thanh toán PayOS.
 *
 * Nhiệm vụ:
 * - Lưu trữ thông tin kết quả trả về từ PayOS cho một payment link (URL, mã QR VietQR, thông tin
 *   ngân hàng nhận tiền, thời gian hết hạn, số tiền, orderCode, paymentLinkId).
 * - Là DTO thuần để chuyển dữ liệu từ tầng tạo link (DatSanServlet.createFacilityPayOSLink) sang
 *   nơi render trang QR nhúng của V-SPORT (không redirect sang checkout PayOS nữa).
 *
 * Lưu ý:
 * - DTO thuần, không logic nghiệp vụ / DB.
 * - qrCode là payload VietQR THÔ — được render thành ảnh PNG ở phía server (ZXing), KHÔNG chứa
 *   secret. checkoutUrl chỉ giữ làm fallback nội bộ, không dùng làm luồng mặc định.
 */
public class PayOSCheckoutSession {
    public final String checkoutUrl;
    public final String qrCode;
    public final Long expiredAt;   // epoch seconds do PayOS trả về (có thể null)
    public final long amount;

    // Thông tin ngân hàng nhận tiền + định danh link (để hiển thị + copy trên trang QR V-SPORT)
    public final String bin;
    public final String accountNumber;
    public final String accountName;
    public final String description;
    public final Long orderCode;
    public final String paymentLinkId;

    /** Constructor rút gọn (giữ tương thích ngược cho code cũ chỉ cần 4 field). */
    public PayOSCheckoutSession(String checkoutUrl, String qrCode, Long expiredAt, long amount) {
        this(checkoutUrl, qrCode, expiredAt, amount, null, null, null, null, null, null);
    }

    public PayOSCheckoutSession(String checkoutUrl, String qrCode, Long expiredAt, long amount,
                                String bin, String accountNumber, String accountName,
                                String description, Long orderCode, String paymentLinkId) {
        this.checkoutUrl = checkoutUrl;
        this.qrCode = qrCode;
        this.expiredAt = expiredAt;
        this.amount = amount;
        this.bin = bin;
        this.accountNumber = accountNumber;
        this.accountName = accountName;
        this.description = description;
        this.orderCode = orderCode;
        this.paymentLinkId = paymentLinkId;
    }
}
