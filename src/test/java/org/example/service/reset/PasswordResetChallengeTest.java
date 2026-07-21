package org.example.service.reset;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PasswordResetChallengeTest {

    private static final long T0 = 1_000_000_000L;

    private PasswordResetChallenge real() {
        return PasswordResetChallenge.create("user@vsport.vn", "u***@vsport.vn", "customer", "123456", T0);
    }

    @Test
    void otpDungThiOkVaOneTimeUse() {
        PasswordResetChallenge c = real();
        assertEquals(PasswordResetChallenge.VerifyResult.OK, c.verify("123456", T0 + 1000));
        assertTrue(c.isUsed());
        assertEquals(PasswordResetChallenge.VerifyResult.USED, c.verify("123456", T0 + 2000));
    }

    @Test
    void otpSaiThiInvalidVaTangAttempt() {
        PasswordResetChallenge c = real();
        assertEquals(PasswordResetChallenge.VerifyResult.INVALID, c.verify("000000", T0 + 1000));
        assertEquals(1, c.getAttemptCount());
        // vẫn đúng được sau vài lần sai
        assertEquals(PasswordResetChallenge.VerifyResult.OK, c.verify("123456", T0 + 2000));
    }

    @Test
    void qua5LanSaiThiLocked() {
        PasswordResetChallenge c = real();
        for (int i = 0; i < 4; i++) {
            assertEquals(PasswordResetChallenge.VerifyResult.INVALID, c.verify("000000", T0 + i));
        }
        assertEquals(PasswordResetChallenge.VerifyResult.LOCKED, c.verify("000000", T0 + 10));
        // kể cả nhập đúng sau khi locked
        assertEquals(PasswordResetChallenge.VerifyResult.LOCKED, c.verify("123456", T0 + 11));
    }

    @Test
    void het10PhutThiExpired() {
        PasswordResetChallenge c = real();
        assertEquals(PasswordResetChallenge.VerifyResult.EXPIRED,
                c.verify("123456", T0 + PasswordResetChallenge.TTL_MS + 1));
    }

    @Test
    void decoyLuonInvalidKeCaOtpDung() {
        PasswordResetChallenge decoy = PasswordResetChallenge.create(null, null, "customer", "123456", T0);
        assertTrue(decoy.isDecoy());
        assertEquals(PasswordResetChallenge.VerifyResult.INVALID, decoy.verify("123456", T0 + 1000));
        assertNull(decoy.getAccountEmail());
    }

    @Test
    void resendCooldown60s() {
        PasswordResetChallenge c = real();
        assertFalse(c.canResend(T0 + 30_000));
        assertEquals(30, c.resendWaitSeconds(T0 + 30_000));
        assertTrue(c.canResend(T0 + 60_000));
        assertThrows(IllegalStateException.class, () -> c.applyResend("654321", T0 + 30_000));
    }

    @Test
    void resendInvalidateMaCuVaResetAttempt() {
        PasswordResetChallenge c = real();
        c.verify("000000", T0 + 1000);
        c.applyResend("654321", T0 + 61_000);
        assertEquals(0, c.getAttemptCount());
        assertEquals(2, c.getSendCount());
        // mã cũ hết hiệu lực, mã mới hoạt động
        assertEquals(PasswordResetChallenge.VerifyResult.INVALID, c.verify("123456", T0 + 62_000));
        assertEquals(PasswordResetChallenge.VerifyResult.OK, c.verify("654321", T0 + 63_000));
    }

    @Test
    void toiDa5LanGui() {
        PasswordResetChallenge c = real();
        long t = T0;
        for (int i = 2; i <= 5; i++) {
            t += 61_000;
            c.applyResend("11111" + i, t);
        }
        assertEquals(5, c.getSendCount());
        assertFalse(c.canResend(t + 120_000));
    }

    @Test
    void inputKhongPhai6SoThiInvalid() {
        PasswordResetChallenge c = real();
        assertEquals(PasswordResetChallenge.VerifyResult.INVALID, c.verify(null, T0 + 1));
        assertEquals(PasswordResetChallenge.VerifyResult.INVALID, c.verify("12345", T0 + 2));
        assertEquals(PasswordResetChallenge.VerifyResult.INVALID, c.verify("abcdef", T0 + 3));
    }
}
