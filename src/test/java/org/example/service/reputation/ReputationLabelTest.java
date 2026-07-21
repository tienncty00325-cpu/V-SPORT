package org.example.service.reputation;

import org.example.util.Constants;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ReputationLabelTest {

    @Test
    void score100IsGood() {
        assertEquals(Constants.REPUTATION_LABEL_GOOD, ReputationLabel.of(100));
    }

    @Test
    void scoreAtGoodThresholdIsGood() {
        assertEquals(Constants.REPUTATION_LABEL_GOOD, ReputationLabel.of(80));
    }

    @Test
    void scoreJustBelowGoodThresholdIsWatch() {
        assertEquals(Constants.REPUTATION_LABEL_WATCH, ReputationLabel.of(79));
    }

    @Test
    void scoreAtWatchThresholdIsWatch() {
        assertEquals(Constants.REPUTATION_LABEL_WATCH, ReputationLabel.of(50));
    }

    @Test
    void scoreJustBelowWatchThresholdIsRisk() {
        assertEquals(Constants.REPUTATION_LABEL_RISK, ReputationLabel.of(49));
    }

    @Test
    void score0IsRisk() {
        assertEquals(Constants.REPUTATION_LABEL_RISK, ReputationLabel.of(0));
    }
}
