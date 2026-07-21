package org.example.util;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.MultiFormatWriter;
import com.google.zxing.WriterException;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;

import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.EnumMap;
import java.util.Map;

import javax.imageio.ImageIO;

/**
 * Render một chuỗi payload (ở đây là VietQR do PayOS trả về) thành ảnh QR PNG NGAY TRÊN SERVER
 * bằng ZXing. Không phụ thuộc CDN ngoài, không dùng ảnh QR giả, payload không bị lộ ra frontend
 * dưới dạng chuỗi (chỉ đi ra dưới dạng ảnh).
 */
public final class QrCodeRenderer {

    private QrCodeRenderer() {}

    /**
     * @param payload chuỗi cần mã hoá (VietQR). Không được null/blank.
     * @param size    cạnh ảnh (px). Nền trắng, ô đen — độ tương phản tối đa để app ngân hàng quét tốt.
     * @return byte[] PNG.
     */
    public static byte[] toPngBytes(String payload, int size) throws WriterException, IOException {
        if (payload == null || payload.isBlank()) {
            throw new IllegalArgumentException("QR payload rỗng");
        }
        int edge = Math.max(160, Math.min(size, 1024));

        Map<EncodeHintType, Object> hints = new EnumMap<>(EncodeHintType.class);
        hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");
        // Mức sửa lỗi M: cân bằng giữa mật độ và khả năng quét (không nhúng logo đè lên mã).
        hints.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M);
        hints.put(EncodeHintType.MARGIN, 1);

        BitMatrix matrix = new MultiFormatWriter().encode(payload, BarcodeFormat.QR_CODE, edge, edge, hints);

        BufferedImage image = new BufferedImage(edge, edge, BufferedImage.TYPE_INT_RGB);
        final int black = 0x000000;
        final int white = 0xFFFFFF;
        for (int y = 0; y < edge; y++) {
            for (int x = 0; x < edge; x++) {
                image.setRGB(x, y, matrix.get(x, y) ? black : white);
            }
        }

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "PNG", out);
        return out.toByteArray();
    }
}
