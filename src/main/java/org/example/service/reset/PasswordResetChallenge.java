package org.example.service.reset;

import java.io.Serializable;

/**
 * Challenge đặt lại mật khẩu, lưu trong HTTP session (nhất quán với kiến trúc
 * OTP-in-session hiện có của luồng đăng ký). Chỉ giữ HASH của OTP; OTP raw chỉ
 * tồn tại trong email gửi cho người dùng.
 *
 * Challenge "decoy" (accountEmail == null) được tạo khi identifier không khớp
 * tài khoản hợp lệ của portal — mọi lần verify đều thất bại với thông báo
 * generic, chống account enumeration.
 *
 * Logic thuần với clock truyền vào để unit-test không cần DB.
 */
public class PasswordResetChallenge implements Serializable {

    private static final long serialVersionUID = 1L;

    public static final long TTL_MS = 10 * 60_000L;            // OTP hết hạn sau 10 phút
    public static final long RESEND_COOLDOWN_MS = 60_000L;     // 60s giữa 2 lần gửi
    public static final int MAX_ATTEMPTS = 5;                  // tối đa 5 lần nhập sai
    public static final int MAX_SENDS = 5;                     // tối đa 5 lần gửi mã

    public enum VerifyResult { OK, INVALID, EXPIRED, LOCKED, USED }

    private final String accountEmail;      // null = decoy
    private final String maskedDestination; // hiển thị cho người dùng (đã che)
    private final String portal;            // customer | internal

    private String salt;
    private String otpHash;
    private long expiresAt;
    private long lastSentAt;
    private int sendCount;
    private int attemptCount;
    private boolean used;

    private PasswordResetChallenge(String accountEmail, String maskedDestination, String portal) {
        this.accountEmail = accountEmail;
        this.maskedDestination = maskedDestination;
        this.portal = portal;
    }

    public static PasswordResetChallenge create(String accountEmail, String maskedDestination,
                                                String portal, String otp, long now) {
        PasswordResetChallenge c = new PasswordResetChallenge(accountEmail, maskedDestination, portal);
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
    }

    /** Xác thực OTP; tăng attempt khi sai; one-time-use khi đúng. Decoy luôn INVALID. */
    public VerifyResult verify(String input, long now) {
        if (used) return VerifyResult.USED;
        if (now > expiresAt) return VerifyResult.EXPIRED;
        if (attemptCount >= MAX_ATTEMPTS) return VerifyResult.LOCKED;
        attemptCount++;
        if (isDecoy() || input == null || !input.matches("\\d{6}")) {
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

    public boolean isDecoy() { return accountEmail == null; }
    public boolean isUsed() { return used; }
    public String getAccountEmail() { return accountEmail; }
    public String getMaskedDestination() { return maskedDestination; }
    public String getPortal() { return portal; }
    public int getAttemptCount() { return attemptCount; }
    public int getSendCount() { return sendCount; }
}
