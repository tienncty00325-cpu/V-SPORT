package org.example.service.reset;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;

/**
 * Tiện ích thuần (pure) cho luồng đặt lại mật khẩu: sinh OTP bằng SecureRandom,
 * băm OTP với salt (DB/session không bao giờ giữ OTP raw), che email hiển thị.
 */
public final class ResetSecurityUtil {

    private static final SecureRandom RANDOM = new SecureRandom();

    private ResetSecurityUtil() {
    }

    /** OTP 6 chữ số sinh bằng SecureRandom (không dùng Math.random/timestamp). */
    public static String generateOtp() {
        return String.format("%06d", RANDOM.nextInt(1_000_000));
    }

    /** Salt hex 16 byte cho mỗi challenge. */
    public static String newSalt() {
        byte[] b = new byte[16];
        RANDOM.nextBytes(b);
        return toHex(b);
    }

    /** SHA-256(salt + otp) dạng hex. */
    public static String hashOtp(String salt, String otp) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest((salt + ":" + otp).getBytes(StandardCharsets.UTF_8));
            return toHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 không khả dụng", e);
        }
    }

    /** So sánh constant-time hai chuỗi hex hash. */
    public static boolean hashEquals(String expectedHash, String actualHash) {
        if (expectedHash == null || actualHash == null) return false;
        return MessageDigest.isEqual(
                expectedHash.getBytes(StandardCharsets.UTF_8),
                actualHash.getBytes(StandardCharsets.UTF_8));
    }

    /** Che email hiển thị: nhan@gmail.com → n***@gmail.com. */
    public static String maskEmail(String email) {
        if (email == null) return null;
        String trimmed = email.trim();
        int at = trimmed.indexOf('@');
        if (at <= 0) return "***";
        return trimmed.charAt(0) + "***" + trimmed.substring(at);
    }

    private static String toHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) sb.append(String.format("%02x", b));
        return sb.toString();
    }
}
