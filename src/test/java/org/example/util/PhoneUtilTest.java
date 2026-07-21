package org.example.util;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PhoneUtilTest {

    @Test
    void normalizeGiuNguyenDangNoiDia() {
        assertEquals("0786041209", PhoneUtil.normalizeVN("0786041209"));
    }

    @Test
    void normalizeChuyenPlus84VeNoiDia() {
        assertEquals("0786041209", PhoneUtil.normalizeVN("+84786041209"));
    }

    @Test
    void normalizeChuyen84VeNoiDia() {
        assertEquals("0786041209", PhoneUtil.normalizeVN("84786041209"));
    }

    @Test
    void normalizeBoKyTuPhanTach() {
        assertEquals("0786041209", PhoneUtil.normalizeVN("+84 786 041 209"));
        assertEquals("0786041209", PhoneUtil.normalizeVN("078-604-1209"));
        assertEquals("0786041209", PhoneUtil.normalizeVN("(078) 604.1209"));
    }

    @Test
    void normalizeTuChoiInputKhongHopLe() {
        assertNull(PhoneUtil.normalizeVN(null));
        assertNull(PhoneUtil.normalizeVN(""));
        assertNull(PhoneUtil.normalizeVN("   "));
        assertNull(PhoneUtil.normalizeVN("abc"));
        assertNull(PhoneUtil.normalizeVN("012345678"));      // thiếu số
        assertNull(PhoneUtil.normalizeVN("01234567890"));    // 11 số bắt đầu 01
        assertNull(PhoneUtil.normalizeVN("0186041209"));     // đầu số 01 không hợp lệ
        assertNull(PhoneUtil.normalizeVN("0286041209"));     // đầu số 02 (cố định)
        assertNull(PhoneUtil.normalizeVN("840786041209"));   // 84 + dạng nội địa (12 số)
        assertNull(PhoneUtil.normalizeVN("+840786041209"));
        assertNull(PhoneUtil.normalizeVN("0786'041209"));    // ký tự nguy hiểm
        assertNull(PhoneUtil.normalizeVN("0786O41209"));     // chữ O thay số 0
    }

    @Test
    void isValidVNKhopVoiNormalize() {
        assertTrue(PhoneUtil.isValidVN("0786041209"));
        assertTrue(PhoneUtil.isValidVN("+84786041209"));
        assertFalse(PhoneUtil.isValidVN("12345"));
        assertFalse(PhoneUtil.isValidVN(null));
    }

    @Test
    void lookupVariantsTraVeDu3BienThe() {
        List<String> variants = PhoneUtil.lookupVariants("0786041209");
        assertEquals(List.of("0786041209", "+84786041209", "84786041209"), variants);
    }

    @Test
    void lookupVariantsTuChoiSoChuaChuanHoa() {
        assertThrows(IllegalArgumentException.class, () -> PhoneUtil.lookupVariants("+84786041209"));
        assertThrows(IllegalArgumentException.class, () -> PhoneUtil.lookupVariants(null));
    }
}
