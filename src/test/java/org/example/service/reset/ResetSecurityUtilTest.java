package org.example.service.reset;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ResetSecurityUtilTest {

    @Test
    void otpLuon6ChuSo() {
        for (int i = 0; i < 200; i++) {
            assertTrue(ResetSecurityUtil.generateOtp().matches("\\d{6}"));
        }
    }

    @Test
    void hashPhuThuocSaltVaOtp() {
        String salt = ResetSecurityUtil.newSalt();
        String h1 = ResetSecurityUtil.hashOtp(salt, "123456");
        assertEquals(h1, ResetSecurityUtil.hashOtp(salt, "123456"));
        assertNotEquals(h1, ResetSecurityUtil.hashOtp(salt, "123457"));
        assertNotEquals(h1, ResetSecurityUtil.hashOtp(ResetSecurityUtil.newSalt(), "123456"));
        assertFalse(h1.contains("123456"));
    }

    @Test
    void hashEqualsConstantTimeSemantics() {
        assertTrue(ResetSecurityUtil.hashEquals("abc", "abc"));
        assertFalse(ResetSecurityUtil.hashEquals("abc", "abd"));
        assertFalse(ResetSecurityUtil.hashEquals(null, "abc"));
        assertFalse(ResetSecurityUtil.hashEquals("abc", null));
    }

    @Test
    void maskEmailCheDungPhanLocal() {
        assertEquals("n***@gmail.com", ResetSecurityUtil.maskEmail("nhan@gmail.com"));
        assertEquals("b***@gmail.com", ResetSecurityUtil.maskEmail("  baolongtp54@gmail.com  "));
        assertEquals("a***@x.vn", ResetSecurityUtil.maskEmail("a@x.vn"));
        assertEquals("***", ResetSecurityUtil.maskEmail("khong-phai-email"));
        assertNull(ResetSecurityUtil.maskEmail(null));
    }
}
