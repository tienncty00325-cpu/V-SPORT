package org.example.service;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PayOSConfigChallengeTest {

    private static final long T0 = 1_000_000_000L;

    private PayOSConfigChallenge real() {
        return PayOSConfigChallenge.create(7, 42, "a***@vsport.vn",
                "client-new", "api-new", "checksum-new",
                List.of("CLIENT_ID", "API_KEY", "CHECKSUM_KEY"), "123456", T0);
    }

    @Test
    void otpDungThiOkVaOneTimeUse() {
        PayOSConfigChallenge c = real();
        assertEquals(PayOSConfigChallenge.VerifyResult.OK, c.verify("123456", T0 + 1000));
        assertTrue(c.isUsed());
        assertEquals(PayOSConfigChallenge.VerifyResult.USED, c.verify("123456", T0 + 2000));
    }

    @Test
    void otpSaiThiInvalidVaTangAttempt() {
        PayOSConfigChallenge c = real();
        assertEquals(PayOSConfigChallenge.VerifyResult.INVALID, c.verify("000000", T0 + 1000));
        assertEquals(1, c.getAttemptCount());
        assertEquals(PayOSConfigChallenge.VerifyResult.OK, c.verify("123456", T0 + 2000));
    }

    @Test
    void qua5LanSaiThiLocked() {
        PayOSConfigChallenge c = real();
        for (int i = 0; i < 4; i++) {
            assertEquals(PayOSConfigChallenge.VerifyResult.INVALID, c.verify("000000", T0 + i));
        }
        assertEquals(PayOSConfigChallenge.VerifyResult.LOCKED, c.verify("000000", T0 + 10));
        assertEquals(PayOSConfigChallenge.VerifyResult.LOCKED, c.verify("123456", T0 + 11));
    }

    @Test
    void het5PhutThiExpired() {
        PayOSConfigChallenge c = real();
        assertEquals(PayOSConfigChallenge.VerifyResult.EXPIRED,
                c.verify("123456", T0 + PayOSConfigChallenge.TTL_MS + 1));
    }

    @Test
    void resendCooldown60s() {
        PayOSConfigChallenge c = real();
        assertFalse(c.canResend(T0 + 30_000));
        assertEquals(30, c.resendWaitSeconds(T0 + 30_000));
        assertTrue(c.canResend(T0 + 60_000));
        assertThrows(IllegalStateException.class, () -> c.applyResend("654321", T0 + 30_000));
    }

    @Test
    void resendInvalidateMaCuVaResetAttempt() {
        PayOSConfigChallenge c = real();
        c.verify("000000", T0 + 1000);
        c.applyResend("654321", T0 + 61_000);
        assertEquals(0, c.getAttemptCount());
        assertEquals(2, c.getSendCount());
        assertEquals(PayOSConfigChallenge.VerifyResult.INVALID, c.verify("123456", T0 + 62_000));
        assertEquals(PayOSConfigChallenge.VerifyResult.OK, c.verify("654321", T0 + 63_000));
    }

    @Test
    void pendingValuesAndFieldsChangedArePreserved() {
        PayOSConfigChallenge c = real();
        assertEquals(7, c.getCoSoId());
        assertEquals(42, c.getAdminAccountId());
        assertEquals("client-new", c.getPendingClientId());
        assertEquals("api-new", c.getPendingApiKey());
        assertEquals("checksum-new", c.getPendingChecksumKey());
        assertEquals(List.of("CLIENT_ID", "API_KEY", "CHECKSUM_KEY"), c.getFieldsChanged());
    }
}
