package org.example.service.booking;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class BookingCancellationServiceEligibilityTest {

    @Test
    void choXacNhanIsCancellable() {
        assertTrue(BookingCancellationService.isCancellableStatus("Chờ xác nhận"));
    }

    @Test
    void daXacNhanIsCancellable() {
        assertTrue(BookingCancellationService.isCancellableStatus("Đã xác nhận"));
    }

    @Test
    void choThanhToanIsCancellable() {
        assertTrue(BookingCancellationService.isCancellableStatus("Chờ thanh toán"));
    }

    @Test
    void dangSuDungIsNotCancellable() {
        assertFalse(BookingCancellationService.isCancellableStatus("Đang sử dụng"));
    }

    @Test
    void daHoanThanhIsNotCancellable() {
        assertFalse(BookingCancellationService.isCancellableStatus("Đã hoàn thành"));
    }

    @Test
    void khongDenIsNotCancellable() {
        assertFalse(BookingCancellationService.isCancellableStatus("Không đến"));
    }

    @Test
    void daHuyIsNotCancellable() {
        assertFalse(BookingCancellationService.isCancellableStatus("Đã hủy"));
    }
}
