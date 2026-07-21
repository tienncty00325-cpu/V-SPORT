package org.example.service.reset;

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Rate limiter sliding-window in-memory (per-JVM) cho các endpoint nhạy cảm
 * như quên mật khẩu. Server-side enforce, không phụ thuộc JavaScript.
 * Logic thuần với clock truyền vào để unit-test.
 */
public class SimpleRateLimiter {

    /** Instance dùng chung cho các servlet auth. */
    public static final SimpleRateLimiter SHARED = new SimpleRateLimiter();

    private final Map<String, Deque<Long>> events = new ConcurrentHashMap<>();

    /**
     * true nếu event được phép (và được ghi nhận); false nếu vượt giới hạn
     * maxEvents trong windowMs gần nhất.
     */
    public boolean tryAcquire(String key, int maxEvents, long windowMs, long now) {
        Deque<Long> deque = events.computeIfAbsent(key, k -> new ArrayDeque<>());
        synchronized (deque) {
            long cutoff = now - windowMs;
            Iterator<Long> it = deque.iterator();
            while (it.hasNext()) {
                if (it.next() <= cutoff) it.remove(); else break;
            }
            if (deque.size() >= maxEvents) {
                return false;
            }
            deque.addLast(now);
        }
        // Dọn key rỗng thỉnh thoảng để map không phình vô hạn
        if (events.size() > 10_000) {
            events.entrySet().removeIf(e -> {
                synchronized (e.getValue()) {
                    return e.getValue().isEmpty() || e.getValue().peekLast() <= now - windowMs;
                }
            });
        }
        return true;
    }
}
