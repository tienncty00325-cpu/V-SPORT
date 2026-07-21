package org.example.service;

import org.example.service.reset.ResetSecurityUtil;

import java.io.Serializable;
import java.util.List;

/**
 * Challenge xác thực OTP trước khi lưu thay đổi Client ID/API Key/Checksum Key
 * PayOS của một Cơ Sở. Lưu trong HTTP session (nhất quán với PasswordResetChallenge
 * và luồng OTP thêm chi nhánh hiện có). Chỉ giữ HASH của OTP; OTP raw chỉ tồn tại
 * trong email gửi cho Admin. Giá trị khóa mới (pending) được giữ tạm để commit khi
 * OTP đúng — độ nhạy cảm tương đương dữ liệu đã lưu plaintext trong CoSo.PayOS_*.
 */
public class PayOSConfigChallenge implements Serializable {

    private static final long serialVersionUID = 1L;

    public static final long TTL_MS = 5 * 60_000L;           // OTP hết hạn sau 5 phút
    public static final long RESEND_COOLDOWN_MS = 60_000L;   // 60s giữa 2 lần gửi
    public static final int MAX_ATTEMPTS = 5;                // tối đa 5 lần nhập sai
    public static final int MAX_SENDS = 5;                   // tối đa 5 lần gửi mã

    public enum VerifyResult { OK, INVALID, EXPIRED, LOCKED, USED }

    private final int coSoId;
    private final int adminAccountId;
    private final String maskedDestination;
    private final String pendingClientId;
    private final String pendingApiKey;
    private final String pendingChecksumKey;
    private final List<String> fieldsChanged;

    private String salt;
    private String otpHash;
    private long expiresAt;
    private long lastSentAt;
    private int sendCount;
    private int attemptCount;
    private boolean used;

    private PayOSConfigChallenge(int coSoId, int adminAccountId, String maskedDestination,
                                  String pendingClientId, String pendingApiKey, String pendingChecksumKey,
                                  List<String> fieldsChanged) {
        this.coSoId = coSoId;
        this.adminAccountId = adminAccountId;
        this.maskedDestination = maskedDestination;
        this.pendingClientId = pendingClientId;
        this.pendingApiKey = pendingApiKey;
        this.pendingChecksumKey = pendingChecksumKey;
        this.fieldsChanged = fieldsChanged;
    }

    public static PayOSConfigChallenge create(int coSoId, int adminAccountId, String maskedDestination,
                                               String pendingClientId, String pendingApiKey,
                                               String pendingChecksumKey, List<String> fieldsChanged,
                                               String otp, long now) {
        PayOSConfigChallenge c = new PayOSConfigChallenge(coSoId, adminAccountId, maskedDestination,
                pendingClientId, pendingApiKey, pendingChecksumKey, fieldsChanged);
        c.applyNewOtp(otp, now);
        return c;
    }

    private void applyNewOtp(String otp, long now) {
        this.salt = ResetSecurityUtil.newSalt();
        this.otpHash = ResetSecurityUtil.hashOtp(this.salt, otp);
        this.expiresAt = now + TTL_MS;
        this.lastSentAt = now;
        this.sendCount++;
        this.attemptCount = 0;
        this.used = false;
    }

    /** Xác thực OTP; tăng attempt khi sai; one-time-use khi đúng. */
    public VerifyResult verify(String input, long now) {
        if (used) return VerifyResult.USED;
        if (now > expiresAt) return VerifyResult.EXPIRED;
        if (attemptCount >= MAX_ATTEMPTS) return VerifyResult.LOCKED;
        attemptCount++;
        if (input == null || !input.matches("\\d{6}")) {
            return attemptCount >= MAX_ATTEMPTS ? VerifyResult.LOCKED : VerifyResult.INVALID;
        }
        String actual = ResetSecurityUtil.hashOtp(salt, input);
        if (ResetSecurityUtil.hashEquals(otpHash, actual)) {
            used = true;
            return VerifyResult.OK;
        }
        return attemptCount >= MAX_ATTEMPTS ? VerifyResult.LOCKED : VerifyResult.INVALID;
    }

    public boolean canResend(long now) {
        return !used && sendCount < MAX_SENDS && (now - lastSentAt) >= RESEND_COOLDOWN_MS;
    }

    /** Số giây còn phải chờ trước khi được gửi lại (0 nếu được gửi ngay). */
    public long resendWaitSeconds(long now) {
        long wait = (RESEND_COOLDOWN_MS - (now - lastSentAt) + 999) / 1000;
        return Math.max(0, wait);
    }

    /** Gửi lại: OTP mới thay OTP cũ (invalidate mã cũ), reset attempts, gia hạn expiry. */
    public void applyResend(String newOtp, long now) {
        if (!canResend(now)) {
            throw new IllegalStateException("Chưa đủ điều kiện gửi lại mã");
        }
        applyNewOtp(newOtp, now);
    }

    public int getCoSoId() { return coSoId; }
    public int getAdminAccountId() { return adminAccountId; }
    public String getMaskedDestination() { return maskedDestination; }
    public String getPendingClientId() { return pendingClientId; }
    public String getPendingApiKey() { return pendingApiKey; }
    public String getPendingChecksumKey() { return pendingChecksumKey; }
    public List<String> getFieldsChanged() { return fieldsChanged; }
    public boolean isUsed() { return used; }
    public int getAttemptCount() { return attemptCount; }
    public int getSendCount() { return sendCount; }
}
