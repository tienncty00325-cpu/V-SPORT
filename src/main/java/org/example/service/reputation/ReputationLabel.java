package org.example.service.reputation;

import org.example.util.Constants;

/**
 * Nhãn hiển thị điểm uy tín cho Manager/Staff (mục 3 spec: 80-100 Uy tín tốt,
 * 50-79 Cần theo dõi, dưới 50 Rủi ro cao). Logic thuần, không đụng DB.
 */
public final class ReputationLabel {

    private ReputationLabel() {
    }

    public static String of(int score) {
        if (score >= Constants.REPUTATION_GOOD_THRESHOLD) {
            return Constants.REPUTATION_LABEL_GOOD;
        }
        if (score >= Constants.REPUTATION_WATCH_THRESHOLD) {
            return Constants.REPUTATION_LABEL_WATCH;
        }
        return Constants.REPUTATION_LABEL_RISK;
    }
}
