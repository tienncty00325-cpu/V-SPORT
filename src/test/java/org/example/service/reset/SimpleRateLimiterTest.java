package org.example.service.reset;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class SimpleRateLimiterTest {

    @Test
    void chanKhiVuotGioiHanTrongWindow() {
        SimpleRateLimiter rl = new SimpleRateLimiter();
        long t = 1_000_000L;
        for (int i = 0; i < 5; i++) {
            assertTrue(rl.tryAcquire("id:test", 5, 900_000, t + i));
        }
        assertFalse(rl.tryAcquire("id:test", 5, 900_000, t + 10));
    }

    @Test
    void windowTruotChoPhepLaiSauKhiHetHan() {
        SimpleRateLimiter rl = new SimpleRateLimiter();
        long t = 1_000_000L;
        for (int i = 0; i < 5; i++) rl.tryAcquire("k", 5, 60_000, t);
        assertFalse(rl.tryAcquire("k", 5, 60_000, t + 1));
        assertTrue(rl.tryAcquire("k", 5, 60_000, t + 60_001));
    }

    @Test
    void keyDocLapNhau() {
        SimpleRateLimiter rl = new SimpleRateLimiter();
        long t = 0;
        for (int i = 0; i < 5; i++) rl.tryAcquire("a", 5, 60_000, t);
        assertFalse(rl.tryAcquire("a", 5, 60_000, t));
        assertTrue(rl.tryAcquire("b", 5, 60_000, t));
    }
}
