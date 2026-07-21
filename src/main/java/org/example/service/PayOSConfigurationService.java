package org.example.service;

import jakarta.servlet.http.HttpServletRequest;
import org.example.dao.AuditLogDAO;
import org.example.dao.CoSoDAO;
import org.example.dao.PayOSConfigDAO;
import org.example.dao.impl.AuditLogDAOImpl;
import org.example.dao.impl.CoSoDAOImpl;
import org.example.dao.impl.PayOSConfigDAOImpl;
import org.example.dto.payment.PayOSConfigState;
import org.example.dto.payment.PayOSConfigurationStatus;
import org.example.dto.payment.PayOSConfigurationUpdateResult;
import org.example.dto.payment.PayOSCredentials;
import org.example.model.AuditLog;
import org.example.model.CoSo;
import org.example.model.TaiKhoan;
import org.example.util.SecretMaskUtil;

import java.util.ArrayList;
import java.util.List;

/**
 * Nghiệp vụ cấu hình PayOS riêng theo từng Cơ Sở (màn hình Admin).
 * getCredentialsForPayment() là điểm duy nhất trả khóa PayOS thô — chỉ được
 * gọi từ tầng thanh toán backend trong tương lai, KHÔNG được expose qua
 * servlet/API trong nhiệm vụ này.
 */
public class PayOSConfigurationService {

    public static final class PayOSConfigurationException extends RuntimeException {
        private final int httpStatus;

        public PayOSConfigurationException(int httpStatus, String message) {
            super(message);
            this.httpStatus = httpStatus;
        }

        public int getHttpStatus() { return httpStatus; }
    }

    private final CoSoDAO coSoDAO;
    private final PayOSConfigDAO payOSConfigDAO;
    private final AuditLogDAO auditLogDAO;

    public PayOSConfigurationService() {
        this(new CoSoDAOImpl(), new PayOSConfigDAOImpl(), new AuditLogDAOImpl());
    }

    PayOSConfigurationService(CoSoDAO coSoDAO, PayOSConfigDAO payOSConfigDAO, AuditLogDAO auditLogDAO) {
        this.coSoDAO = coSoDAO;
        this.payOSConfigDAO = payOSConfigDAO;
        this.auditLogDAO = auditLogDAO;
    }

    public PayOSConfigurationStatus getStatus(int coSoId) {
        CoSo coSo = loadActiveCoSoOrThrow(coSoId);
        PayOSCredentials raw = payOSConfigDAO.findPayOSConfigurationStatusByCoSoId(coSoId);
        if (raw == null) raw = new PayOSCredentials(null, null, null);
        return buildStatus(coSo, raw);
    }

    public PayOSConfigurationUpdateResult updateConfiguration(int coSoId, String newClientId, String newApiKey,
                                                                String newChecksumKey, HttpServletRequest req,
                                                                TaiKhoan admin) {
        PreparedUpdate prepared;
        try {
            prepared = prepareUpdate(coSoId, newClientId, newApiKey, newChecksumKey);
        } catch (PayOSConfigurationException e) {
            return PayOSConfigurationUpdateResult.fail(e.getHttpStatus(), e.getMessage());
        }
        return persistPrepared(prepared, req, admin);
    }

    /** Merge + validate CHỈ, KHÔNG ghi DB, KHÔNG ghi audit log — dùng để quyết định có cần OTP hay không. */
    public PreparedUpdate prepareUpdate(int coSoId, String newClientId, String newApiKey, String newChecksumKey) {
        CoSo coSo = loadActiveCoSoOrThrow(coSoId);
        PayOSCredentials current = payOSConfigDAO.findPayOSConfigurationStatusByCoSoId(coSoId);
        if (current == null) current = new PayOSCredentials(null, null, null);

        MergeOutcome merged = mergeAndValidate(current, newClientId, newApiKey, newChecksumKey);
        if (!merged.valid) {
            throw new PayOSConfigurationException(400, merged.errorMessage);
        }
        return new PreparedUpdate(coSo, merged.finalClientId, merged.finalApiKey, merged.finalChecksumKey,
                merged.fieldsChanged);
    }

    /** Ghi DB + audit log cho một PreparedUpdate đã được validate (và đã xác thực OTP nếu cần). */
    public PayOSConfigurationUpdateResult persistPrepared(PreparedUpdate prepared, HttpServletRequest req,
                                                           TaiKhoan admin) {
        int coSoId = prepared.coSo.getCoSoID();
        PayOSCredentials current = payOSConfigDAO.findPayOSConfigurationStatusByCoSoId(coSoId);
        if (current == null) current = new PayOSCredentials(null, null, null);
        boolean wasConfiguredBefore = current.toState() != PayOSConfigState.NOT_CONFIGURED;

        if (prepared.fieldsChanged.isEmpty()) {
            return PayOSConfigurationUpdateResult.ok(buildStatus(prepared.coSo, current), prepared.fieldsChanged);
        }

        boolean updated = payOSConfigDAO.updatePayOSConfiguration(
                coSoId, prepared.finalClientId, prepared.finalApiKey, prepared.finalChecksumKey);
        if (!updated) {
            return PayOSConfigurationUpdateResult.fail(500, "Không thể cập nhật cấu hình PayOS. Vui lòng thử lại.");
        }

        String action = wasConfiguredBefore ? AuditLogService.ACTION_UPDATE : AuditLogService.ACTION_CREATE;
        String details = "Admin cập nhật cấu hình PayOS cho cơ sở #" + coSoId +
                " (đã xác thực OTP). Fields changed: " + String.join(", ", prepared.fieldsChanged) + ".";
        AuditLogService.log(req, admin, coSoId, action, AuditLogService.ENTITY_PAYOS_CONFIG,
                String.valueOf(coSoId), prepared.coSo.getTenCoSo(), details);

        PayOSCredentials finalRaw = new PayOSCredentials(prepared.finalClientId, prepared.finalApiKey,
                prepared.finalChecksumKey);
        return PayOSConfigurationUpdateResult.ok(buildStatus(prepared.coSo, finalRaw), prepared.fieldsChanged);
    }

    /** Sau khi OTP xác thực OK: nạp lại CoSo mới nhất rồi persist các giá trị pending trong challenge. */
    public PayOSConfigurationUpdateResult persistChallenge(PayOSConfigChallenge challenge, HttpServletRequest req,
                                                            TaiKhoan admin) {
        CoSo coSo;
        try {
            coSo = loadActiveCoSoOrThrow(challenge.getCoSoId());
        } catch (PayOSConfigurationException e) {
            return PayOSConfigurationUpdateResult.fail(e.getHttpStatus(), e.getMessage());
        }
        PreparedUpdate prepared = new PreparedUpdate(coSo, challenge.getPendingClientId(),
                challenge.getPendingApiKey(), challenge.getPendingChecksumKey(), challenge.getFieldsChanged());
        return persistPrepared(prepared, req, admin);
    }

    public static final class PreparedUpdate {
        public final CoSo coSo;
        public final String finalClientId;
        public final String finalApiKey;
        public final String finalChecksumKey;
        public final List<String> fieldsChanged;

        PreparedUpdate(CoSo coSo, String finalClientId, String finalApiKey, String finalChecksumKey,
                       List<String> fieldsChanged) {
            this.coSo = coSo;
            this.finalClientId = finalClientId;
            this.finalApiKey = finalApiKey;
            this.finalChecksumKey = finalChecksumKey;
            this.fieldsChanged = fieldsChanged;
        }
    }

    /** Chỉ dùng nội bộ tầng thanh toán backend. KHÔNG gọi từ servlet/API. */
    public PayOSCredentials getCredentialsForPayment(int coSoId) {
        CoSo coSo = coSoDAO.getCoSoById(coSoId);
        if (coSo == null || coSo.isDeleted()) return null;
        PayOSCredentials raw = payOSConfigDAO.getPayOSCredentialsForInternalUse(coSoId);
        if (raw == null || raw.toState() != PayOSConfigState.CONFIGURED) return null;
        return raw;
    }

    private CoSo loadActiveCoSoOrThrow(int coSoId) {
        if (coSoId <= 0) {
            throw new PayOSConfigurationException(400, "CoSoID không hợp lệ.");
        }
        CoSo coSo = coSoDAO.getCoSoById(coSoId);
        if (coSo == null || coSo.isDeleted()) {
            throw new PayOSConfigurationException(404, "Không tìm thấy cơ sở.");
        }
        return coSo;
    }

    private PayOSConfigurationStatus buildStatus(CoSo coSo, PayOSCredentials raw) {
        return new PayOSConfigurationStatus(
                coSo.getCoSoID(),
                coSo.getTenCoSo(),
                raw.toState(),
                raw.isClientIdConfigured(),
                raw.isApiKeyConfigured(),
                raw.isChecksumKeyConfigured(),
                SecretMaskUtil.mask(raw.getClientId()),
                SecretMaskUtil.mask(raw.getApiKey()),
                SecretMaskUtil.mask(raw.getChecksumKey()),
                fetchLastUpdatedAt(coSo.getCoSoID()));
    }

    private String fetchLastUpdatedAt(int coSoId) {
        try {
            List<AuditLog> logs = auditLogDAO.findWithFilters(
                    coSoId, AuditLogService.ENTITY_PAYOS_CONFIG, null, null, null, 1, 1);
            if (logs.isEmpty() || logs.get(0).getCreatedAt() == null) return null;
            return logs.get(0).getCreatedAt().toString();
        } catch (Exception e) {
            return null;
        }
    }

    // ═══ Pure merge/validate logic — unit-testable without a database ═══

    static final class MergeOutcome {
        final boolean valid;
        final String errorMessage;
        final String finalClientId;
        final String finalApiKey;
        final String finalChecksumKey;
        final List<String> fieldsChanged;

        private MergeOutcome(boolean valid, String errorMessage, String finalClientId, String finalApiKey,
                              String finalChecksumKey, List<String> fieldsChanged) {
            this.valid = valid;
            this.errorMessage = errorMessage;
            this.finalClientId = finalClientId;
            this.finalApiKey = finalApiKey;
            this.finalChecksumKey = finalChecksumKey;
            this.fieldsChanged = fieldsChanged;
        }

        static MergeOutcome invalid(String message) {
            return new MergeOutcome(false, message, null, null, null, List.of());
        }

        static MergeOutcome of(String clientId, String apiKey, String checksumKey, List<String> fieldsChanged) {
            return new MergeOutcome(true, null, clientId, apiKey, checksumKey, fieldsChanged);
        }
    }

    static MergeOutcome mergeAndValidate(PayOSCredentials current, String rawNewClientId,
                                          String rawNewApiKey, String rawNewChecksumKey) {
        String clientCheck = validateSubmittedField(rawNewClientId, "Client ID");
        if (clientCheck != null) return MergeOutcome.invalid(clientCheck);
        String apiCheck = validateSubmittedField(rawNewApiKey, "API Key");
        if (apiCheck != null) return MergeOutcome.invalid(apiCheck);
        String checksumCheck = validateSubmittedField(rawNewChecksumKey, "Checksum Key");
        if (checksumCheck != null) return MergeOutcome.invalid(checksumCheck);

        List<String> fieldsChanged = new ArrayList<>();
        String finalClientId = resolveField(current.getClientId(), rawNewClientId, "CLIENT_ID", fieldsChanged);
        String finalApiKey = resolveField(current.getApiKey(), rawNewApiKey, "API_KEY", fieldsChanged);
        String finalChecksumKey = resolveField(current.getChecksumKey(), rawNewChecksumKey, "CHECKSUM_KEY", fieldsChanged);

        if (isBlank(finalClientId)) return MergeOutcome.invalid("Client ID không được để trống.");
        if (isBlank(finalApiKey)) return MergeOutcome.invalid("API Key không được để trống.");
        if (isBlank(finalChecksumKey)) return MergeOutcome.invalid("Checksum Key không được để trống.");

        return MergeOutcome.of(finalClientId, finalApiKey, finalChecksumKey, fieldsChanged);
    }

    private static String resolveField(String currentValue, String rawNewValue, String fieldTag, List<String> fieldsChanged) {
        if (isBlank(rawNewValue)) {
            return currentValue;
        }
        String trimmed = rawNewValue.trim();
        if (!trimmed.equals(currentValue)) {
            fieldsChanged.add(fieldTag);
        }
        return trimmed;
    }

    /** null nếu hợp lệ (kể cả rỗng — rỗng nghĩa là giữ nguyên giá trị cũ); thông báo lỗi nếu không hợp lệ. */
    private static String validateSubmittedField(String rawValue, String fieldLabel) {
        if (isBlank(rawValue)) return null;
        String trimmed = rawValue.trim();
        if (trimmed.length() > 500) return fieldLabel + " quá dài.";
        if (containsControlChar(trimmed)) return fieldLabel + " chứa ký tự không hợp lệ.";
        if (looksLikePlaceholder(trimmed)) return fieldLabel + " không hợp lệ.";
        return null;
    }

    private static boolean containsControlChar(String value) {
        for (int i = 0; i < value.length(); i++) {
            if (Character.isISOControl(value.charAt(i))) return true;
        }
        return false;
    }

    private static boolean looksLikePlaceholder(String value) {
        if (value.contains("•")) return true;
        if (value.chars().allMatch(c -> c == '*')) return true;
        return value.equalsIgnoreCase("Đã cấu hình");
    }

    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
