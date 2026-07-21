package org.example.util;

import java.util.List;

/**
 * Chuẩn hóa số điện thoại di động Việt Nam cho đăng nhập/đăng ký.
 * Định dạng chuẩn nội bộ: dạng nội địa 10 số bắt đầu bằng 0 (ví dụ 0786041209).
 * Dữ liệu cũ trong DB có thể lưu 0..., +84... hoặc 84... nên mọi truy vấn
 * so sánh phải dùng đủ 3 biến thể từ {@link #lookupVariants(String)}.
 */
public final class PhoneUtil {

    private static final String VN_MOBILE_LOCAL_REGEX = "^0[35789][0-9]{8}$";

    private PhoneUtil() {
    }

    /**
     * Chuẩn hóa input người dùng về dạng nội địa 0XXXXXXXXX.
     * Chấp nhận 0..., +84..., 84... và các ký tự phân tách khoảng trắng/chấm/gạch/ngoặc.
     *
     * @return số đã chuẩn hóa, hoặc {@code null} nếu không phải số di động VN hợp lệ.
     */
    public static String normalizeVN(String raw) {
        if (raw == null) {
            return null;
        }
        String s = raw.trim().replaceAll("[\\s().\\-]", "");
        if (s.isEmpty()) {
            return null;
        }
        if (s.startsWith("+84")) {
            s = "0" + s.substring(3);
        } else if (s.startsWith("84") && s.length() == 11) {
            s = "0" + s.substring(2);
        }
        return s.matches(VN_MOBILE_LOCAL_REGEX) ? s : null;
    }

    /** true nếu input có thể chuẩn hóa thành số di động VN hợp lệ. */
    public static boolean isValidVN(String raw) {
        return normalizeVN(raw) != null;
    }

    /**
     * Các biến thể lưu trữ tương đương của một số đã chuẩn hóa,
     * dùng cho mệnh đề IN khi tra cứu (tránh LIKE và ambiguous match).
     */
    public static List<String> lookupVariants(String normalizedLocal) {
        if (normalizedLocal == null || !normalizedLocal.matches(VN_MOBILE_LOCAL_REGEX)) {
            throw new IllegalArgumentException("Số điện thoại chưa được chuẩn hóa");
        }
        String tail = normalizedLocal.substring(1);
        return List.of(normalizedLocal, "+84" + tail, "84" + tail);
    }
}
