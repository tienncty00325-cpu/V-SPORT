package org.example.service.reputation;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class CustomerReputationServiceClampTest {

    @Test
    void penaltyClampsAtMinimum() {
        assertEquals(0, CustomerReputationService.clamp(5, -20));
    }

    @Test
    void rewardClampsAtMaximum() {
        assertEquals(100, CustomerReputationService.clamp(99, 2));
    }

    @Test
    void normalDeltaIsUnclamped() {
        assertEquals(90, CustomerReputationService.clamp(100, -10));
    }

    @Test
    void exactlyAtFloorStaysAtFloor() {
        assertEquals(0, CustomerReputationService.clamp(0, -20));
    }
}
