package org.example.service;

import jakarta.servlet.http.HttpServletRequest;
import org.example.dao.impl.AuditLogDAOImpl;
import org.example.model.AuditLog;
import org.example.model.TaiKhoan;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Tên tiếng Việt: Dịch vụ ghi nhật ký hoạt động hệ thống.
 *
 * Nhiệm vụ:
 * - Ghi lại thông tin người thực hiện hành động (ID tài khoản, Tên hiển thị, Vai trò).
 * - Ghi lại hành động gì (Thêm, Sửa, Xóa tạm, Duyệt, Từ chối).
 * - Ghi lại thực thể nào bị ảnh hưởng (Tài khoản, Sân, Ca làm, Yêu cầu nghỉ phép).
 *
 * Được gọi bởi:
 * - XacThucOTPServlet.java
 * - CheckInServlet.java
 * - YeuCauNghiManagerServlet.java
 * - ThungRacManagerServlet.java
 * - QuanLySanManagerServlet.java
 * - QuanLyCaLamManagerServlet.java
 * - NhanSuManagerServlet.java
 * - KhoDichVuManagerServlet.java
 * - QuanLySanServlet.java
 *
 * Lưu ý:
 * - Không được làm hỏng luồng nghiệp vụ chính của người dùng nếu việc ghi log gặp sự cố.
 */
public class AuditLogService {
    private static final Logger logger = LoggerFactory.getLogger(AuditLogService.class);
    private static final AuditLogDAOImpl dao = new AuditLogDAOImpl();

    // Các hằng số hành động
    public static final String ACTION_CREATE           = "CREATE";
    public static final String ACTION_UPDATE           = "UPDATE";
    public static final String ACTION_SOFT_DELETE      = "SOFT_DELETE";
    public static final String ACTION_DELETE           = "DELETE";
    public static final String ACTION_RESTORE          = "RESTORE";
    public static final String ACTION_ADD_STAFF        = "ADD_STAFF";
    public static final String ACTION_APPROVE          = "APPROVE";
    public static final String ACTION_REJECT           = "REJECT";
    public static final String ACTION_CANCEL             = "CANCEL";
    public static final String ACTION_NO_SHOW             = "NO_SHOW";
    public static final String ACTION_REPUTATION_ADJUST   = "REPUTATION_ADJUST";

    // Các hằng số loại thực thể
    public static final String ENTITY_ACCOUNT    = "TaiKhoan";
    public static final String ENTITY_SAN        = "San";
    public static final String ENTITY_LOAI_SAN   = "LoaiSan";
    public static final String ENTITY_SAN_PHAM   = "SanPham";
    public static final String ENTITY_CO_SO      = "CoSo";
    public static final String ENTITY_PAYOS_CONFIG = "PayOSConfig";
    public static final String ENTITY_CA_LAM     = "CaLamViec";
    public static final String ENTITY_YEU_CAU_NGHI = "YeuCauNghi";
    public static final String ENTITY_DAT_SAN    = "LichDatSan";
    public static final String ENTITY_REPUTATION = "CustomerReputation";
    public static final String ENTITY_HOA_DON    = "HoaDon";

    /**
     * Ghi một bản ghi audit log. Không ném exception ra ngoài — lỗi log không được phá request chính.
     */
    public static void log(HttpServletRequest req, TaiKhoan actor,
                           String action, String entityType,
                           String entityId, String entityName, String details) {
        try {
            AuditLog entry = new AuditLog();
            entry.setActorAccountId(actor.getAccountId());
            entry.setActorName(actor.getFullName() != null ? actor.getFullName() : actor.getUsername());
            entry.setActorRole(actor.getRoleId());
            entry.setCoSoId(actor.getCoSoId() != null && actor.getCoSoId() > 0 ? actor.getCoSoId() : null);
            entry.setAction(action);
            entry.setEntityType(entityType);
            entry.setEntityId(entityId);
            entry.setEntityName(entityName);
            entry.setDetails(details);
            entry.setIpAddress(getClientIp(req));
            dao.save(entry);
        } catch (Exception e) {
            logger.error("Không thể ghi AuditLog: {}", e.getMessage(), e);
        }
    }

    /** Overload khi coSoId cần ghi rõ (ví dụ Admin thao tác trên 1 chi nhánh cụ thể) */
    public static void log(HttpServletRequest req, TaiKhoan actor, Integer overrideCoSoId,
                           String action, String entityType,
                           String entityId, String entityName, String details) {
        try {
            AuditLog entry = new AuditLog();
            entry.setActorAccountId(actor.getAccountId());
            entry.setActorName(actor.getFullName() != null ? actor.getFullName() : actor.getUsername());
            entry.setActorRole(actor.getRoleId());
            entry.setCoSoId(overrideCoSoId);
            entry.setAction(action);
            entry.setEntityType(entityType);
            entry.setEntityId(entityId);
            entry.setEntityName(entityName);
            entry.setDetails(details);
            entry.setIpAddress(getClientIp(req));
            dao.save(entry);
        } catch (Exception e) {
            logger.error("Không thể ghi AuditLog: {}", e.getMessage(), e);
        }
    }

    /**
     * Ghi audit log cho hành động không có actor đăng nhập (webhook PayOS, scheduler nền) -
     * ActorAccountID=NULL, actorName mô tả nguồn gốc (vd "PAYOS_WEBHOOK", "SCHEDULER").
     * Không ném exception ra ngoài - lỗi log không được phá luồng nghiệp vụ chính.
     */
    public static void logSystem(String actorName, Integer coSoId, String action, String entityType,
                                  String entityId, String entityName, String details) {
        try {
            AuditLog entry = new AuditLog();
            entry.setActorAccountId(null);
            entry.setActorName(actorName);
            entry.setActorRole(0);
            entry.setCoSoId(coSoId);
            entry.setAction(action);
            entry.setEntityType(entityType);
            entry.setEntityId(entityId);
            entry.setEntityName(entityName);
            entry.setDetails(details);
            entry.setIpAddress(null);
            dao.save(entry);
        } catch (Exception e) {
            logger.error("Không thể ghi AuditLog (system): {}", e.getMessage(), e);
        }
    }

    public static String getClientIp(HttpServletRequest req) {
        String ip = req.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty()) ip = req.getRemoteAddr();
        // X-Forwarded-For có thể chứa nhiều IP, lấy IP đầu tiên
        if (ip != null && ip.contains(",")) ip = ip.split(",")[0].trim();
        return ip;
    }
}
