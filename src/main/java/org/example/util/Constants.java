package org.example.util;

/**
 * Constants cho hệ thống V-SPORT
 * Centralize tất cả các giá trị constant để dễ maintain và tránh magic strings/numbers
 */
public final class Constants {

    // ========== ROLES ==========
    public static final int ROLE_ADMIN = 1;
    public static final int ROLE_MANAGER = 2;
    public static final int ROLE_KHACH_HANG = 3;
    public static final int ROLE_LE_TAN = 4;
    public static final int ROLE_BAO_VE = 5;

    // ========== BOOKING (LichDatSan) STATUS ==========
    public static final String TRANG_THAI_DAT_SAN_CHO_XAC_NHAN = "Chờ xác nhận";
    public static final String TRANG_THAI_DAT_SAN_DA_XAC_NHAN = "Đã xác nhận";
    public static final String TRANG_THAI_DAT_SAN_DA_HUY = "Đã hủy";
    public static final String TRANG_THAI_DAT_SAN_DANG_CHOI = "Đang chơi";
    public static final String TRANG_THAI_DAT_SAN_DA_HOAN_THANH = "Đã hoàn thành";
    // Reservation-hold (docs/superpowers/specs/2026-07-09-auto-booking-reservation-hold-design.md, mục 4)
    public static final String TRANG_THAI_DAT_SAN_CHO_THANH_TOAN = "Chờ thanh toán";
    public static final String TRANG_THAI_DAT_SAN_QUA_HAN = "Quá hạn";
    public static final String TRANG_THAI_DAT_SAN_KHONG_DEN = "Không đến";
    // Literal thực tế dùng trong CheckInDAO/CheckInServlet/LichDatSanDAOImpl khi booking đang được chơi.
    // KHÁC với TRANG_THAI_DAT_SAN_DANG_CHOI ("Đang chơi") ở trên — hằng số đó không được dùng ở đâu
    // trong code hiện tại, giữ nguyên không đổi/không xoá (rà soát toàn bộ codebase, 2026-07-09).
    public static final String TRANG_THAI_DAT_SAN_DANG_SU_DUNG = "Đang sử dụng";

    // ========== BOOKING CANCELLATION / REPUTATION (Điểm uy tín khách hàng) ==========
    // Ngưỡng phân loại hủy sớm/hủy sát giờ. Nếu đổi số này, đồng thời phải cập nhật
    // sql/migration_customer_reputation_cancel_flow.sql (không có cách nào để SQL đọc hằng số Java).
    public static final int LATE_CANCEL_HOURS = 6;
    public static final int LATE_CANCEL_PENALTY = -10;
    public static final int NO_SHOW_PENALTY = -20;
    public static final int COMPLETED_BOOKING_REWARD = 2;
    public static final int MAX_REPUTATION_SCORE = 100;
    public static final int MIN_REPUTATION_SCORE = 0;
    // Ngưỡng hiển thị nhãn uy tín cho Manager/Staff — dùng lại ở JSP dưới dạng số literal
    // (JSTL EL không gọi được hằng số Java), phải giữ đồng bộ nếu đổi ở đây:
    // - >= REPUTATION_GOOD_THRESHOLD (80): "Uy tín tốt"
    // - >= REPUTATION_WATCH_THRESHOLD (50) và < 80: "Cần theo dõi"
    // - < REPUTATION_WATCH_THRESHOLD (50): "Rủi ro cao"
    public static final int REPUTATION_GOOD_THRESHOLD = 80;
    public static final int REPUTATION_WATCH_THRESHOLD = 50;

    public static final String CANCEL_TYPE_EARLY = "EARLY_CANCEL";
    public static final String CANCEL_TYPE_LATE = "LATE_CANCEL";

    // Giá trị ActionType lưu trong CustomerReputationHistory.ActionType
    public static final String REPUTATION_ACTION_EARLY_CANCEL = "EARLY_CANCEL";
    public static final String REPUTATION_ACTION_LATE_CANCEL = "LATE_CANCEL";
    public static final String REPUTATION_ACTION_NO_SHOW = "NO_SHOW";
    public static final String REPUTATION_ACTION_COMPLETED_BOOKING = "COMPLETED_BOOKING";
    public static final String REPUTATION_ACTION_MANUAL_ADJUST = "MANUAL_ADJUST";

    public static final String REPUTATION_LABEL_GOOD = "Uy tín tốt";
    public static final String REPUTATION_LABEL_WATCH = "Cần theo dõi";
    public static final String REPUTATION_LABEL_RISK = "Rủi ro cao";

    // ========== TIMEOUT ==========
    public static final int PENDING_PAYMENT_TIMEOUT_MINUTES = 10;
    public static final int SOFT_HOLD_TIMEOUT_MINUTES = 2;
    // Reservation-hold (docs/superpowers/specs/2026-07-09-auto-booking-reservation-hold-design.md, mục 6)
    public static final int BOOKING_HOLD_MINUTES = 10;
    public static final int NO_SHOW_GRACE_MINUTES = 15;
    public static final int COD_APPROVAL_EXPIRE_HOURS = 2;
    public static final boolean NO_SHOW_AUTO_MODE = false;
    // Ngưỡng hiển thị "sắp hết giờ" trên card sân Check-in (staff/CheckIn.jsp) khi ca đang
    // chơi còn dưới mốc này. Ngưỡng "sắp có lịch đặt" dùng chung CheckInWindow.MAX_EARLY_MINUTES
    // (cùng cửa sổ với thời điểm được phép check-in) thay vì khai báo thêm hằng số trùng ý nghĩa.
    public static final int ENDING_SOON_MINUTES = 10;

    // ========== INVOICE (HoaDon) STATUS ==========
    public static final String TRANG_THAI_HOA_DON_CHUA_TT = "Chưa thanh toán";
    public static final String TRANG_THAI_HOA_DON_DA_TT = "Đã thanh toán";
    public static final String TRANG_THAI_HOA_DON_HOAN_TIEN = "Hoàn tiền";
    public static final String TRANG_THAI_HOA_DON_GHI_NO = "Ghi nợ";
    public static final String TRANG_THAI_HOA_DON_DA_COC = "Đã cọc";

    // ========== PAYMENT METHODS ==========
    public static final String PT_TIEN_MAT = "Tiền mặt";
    public static final String PT_CHUYEN_KHOAN = "Chuyển khoản";
    public static final String PT_PAYOS = "PayOS";
    public static final String PT_VI_DIEN_TU = "Ví điện tử";
    public static final String PT_THE = "Thẻ";

    // ========== PAYOS ==========
    // Đánh dấu trong GhiChu của LichDatSan khi PayOSWebhookServlet xác nhận thanh
    // toán thành công. Chưa có field payment_method/payment_status riêng nên tạm
    // dùng marker này để nhận diện booking đã thanh toán PayOS (xem PayOSWebhookServlet).
    public static final String PAYOS_PAID_GHI_CHU_MARKER = "PayOS webhook xác nhận thanh toán thành công";

    // ========== COURT (San) STATUS ==========
    public static final String TRANG_THAI_SAN_SAN_SANG = "Sẵn sàng";
    public static final String TRANG_THAI_SAN_TAM_DONG = "Tạm đóng";
    public static final String TRANG_THAI_SAN_BAO_MAINTENANCE = "Bảo trì";

    // ========== PRODUCT/SERVICE (SanPham_DichVu) STATUS ==========
    public static final String TRANG_THAI_SP_DANG_KINH_DOANH = "Đang kinh doanh";
    public static final String TRANG_THAI_SP_TAM_HET_HANG = "Tạm hết hàng";
    public static final String TRANG_THAI_SP_NGUNG_KINH_DOANH = "Ngừng kinh doanh";

    // ========== FACILITY CAPABILITY (CoSoCapability.CapabilityType) ==========
    // SAN = cho thuê sân, luôn được set APPROVED tự động khi CoSo được Admin duyệt
    // (không phải một checkbox trong form Owner - đó là chức năng nền tảng của mọi cơ sở).
    public static final String CAPABILITY_SAN               = "SAN";
    public static final String CAPABILITY_SAN_PHAM          = "SAN_PHAM";
    public static final String CAPABILITY_THUE_DUNG_CU      = "THUE_DUNG_CU";
    public static final String CAPABILITY_DO_AN_NUOC_UONG   = "DO_AN_NUOC_UONG";
    public static final String CAPABILITY_HUAN_LUYEN_VIEN   = "HUAN_LUYEN_VIEN";
    public static final String CAPABILITY_LOP_HOC           = "LOP_HOC";
    public static final String CAPABILITY_KHAC              = "KHAC";
    // Giai đoạn 1: cung cấp dịch vụ thể thao tại cơ sở (căng lưới, thay quấn cán, sửa vợt...).
    // Đây là capability độc lập với CAPABILITY_SAN_PHAM (bán sản phẩm bán lẻ) - không dùng chung
    // module "Quản lý cửa hàng" (SHOP_MODULE_CAPABILITIES) để tránh lẫn nghiệp vụ dịch vụ với bán lẻ.
    public static final String CAPABILITY_DICH_VU_THE_THAO  = "DICH_VU_THE_THAO";

    // Các capability Owner có thể tự chọn đăng ký trong form (loại trừ SAN - xem trên).
    public static final java.util.List<String> OWNER_SELECTABLE_CAPABILITIES = java.util.List.of(
            CAPABILITY_SAN_PHAM, CAPABILITY_THUE_DUNG_CU, CAPABILITY_DO_AN_NUOC_UONG,
            CAPABILITY_HUAN_LUYEN_VIEN, CAPABILITY_LOP_HOC, CAPABILITY_DICH_VU_THE_THAO, CAPABILITY_KHAC
    );

    // Module "Quản lý dịch vụ" (Giai đoạn 1 - căng lưới, thay quấn cán, sửa vợt...) chỉ mở khi
    // capability này được Admin duyệt - xem FilterQuyenManager.CAPABILITY_GATED_PATHS.
    public static final java.util.List<String> SERVICE_MODULE_CAPABILITIES = java.util.List.of(
            CAPABILITY_DICH_VU_THE_THAO
    );

    // Module "Quản lý cửa hàng" (KhoDichVuManagerServlet / SanPham_DichVu) phục vụ chung
    // cả 3 loại hình này (sản phẩm bán lẻ, dụng cụ cho thuê, đồ ăn/nước uống) qua cùng
    // một danh mục - Manager chỉ cần MỘT trong ba capability này được duyệt là đủ để
    // truy cập module (xem FilterQuyenManager).
    public static final java.util.List<String> SHOP_MODULE_CAPABILITIES = java.util.List.of(
            CAPABILITY_SAN_PHAM, CAPABILITY_THUE_DUNG_CU, CAPABILITY_DO_AN_NUOC_UONG
    );

    // ========== FACILITY CAPABILITY (CoSoCapability.TrangThai) ==========
    public static final String CAPABILITY_STATUS_PENDING   = "PENDING";
    public static final String CAPABILITY_STATUS_APPROVED  = "APPROVED";
    public static final String CAPABILITY_STATUS_REJECTED  = "REJECTED";
    public static final String CAPABILITY_STATUS_SUSPENDED = "SUSPENDED";
    public static final String CAPABILITY_STATUS_DISABLED  = "DISABLED";

    public static String capabilityLabel(String type) {
        if (type == null) return "";
        switch (type) {
            case CAPABILITY_SAN: return "Cho thuê sân thể thao";
            case CAPABILITY_SAN_PHAM: return "Bán sản phẩm thể thao";
            case CAPABILITY_THUE_DUNG_CU: return "Cho thuê dụng cụ thể thao";
            case CAPABILITY_DO_AN_NUOC_UONG: return "Đồ ăn và nước uống";
            case CAPABILITY_HUAN_LUYEN_VIEN: return "Huấn luyện viên";
            case CAPABILITY_LOP_HOC: return "Lớp học";
            case CAPABILITY_DICH_VU_THE_THAO: return "Cung cấp dịch vụ thể thao";
            case CAPABILITY_KHAC: return "Dịch vụ khác";
            default: return type;
        }
    }

    public static String capabilityStatusLabel(String status) {
        if (status == null) return "";
        switch (status) {
            case CAPABILITY_STATUS_PENDING: return "Chờ duyệt";
            case CAPABILITY_STATUS_APPROVED: return "Đã duyệt";
            case CAPABILITY_STATUS_REJECTED: return "Bị từ chối";
            case CAPABILITY_STATUS_SUSPENDED: return "Tạm ngưng";
            case CAPABILITY_STATUS_DISABLED: return "Đã tắt";
            default: return status;
        }
    }

    // ========== PROMOTION (KhuyenMai) STATUS ==========
    public static final String TRANG_THAI_KM_HOAT_DONG = "Hoạt động";
    public static final String TRANG_THAI_KM_TAM_DUNG = "Tạm dừng";
    public static final String TRANG_THAI_KM_HET_HAN = "Hết hạn";

    // ========== REFUND (HoanTien) STATUS ==========
    public static final String TRANG_THAI_HOAN_TIEN_CHO_DUYET = "Chờ xử lý";
    public static final String TRANG_THAI_HOAN_TIEN_DA_DUYET = "Đã duyệt";
    public static final String TRANG_THAI_HOAN_TIEN_TU_CHOI = "Từ chối";
    public static final String TRANG_THAI_HOAN_TIEN_DA_HOAN = "Đã hoàn tiền";

    // ========== SOS REQUEST (YeuCauSOS) STATUS ==========
    public static final String TRANG_THAI_SOS_DANG_TIM = "Đang tìm";
    public static final String TRANG_THAI_SOS_DA_TIM_DUOC = "Đã tìm đủ";
    public static final String TRANG_THAI_SOS_HET_HAN = "Hết hạn";

    // ========== SHIFT (CaLamViec) DEFAULT ==========
    public static final int DEFAULT_SHIFT_DURATION_HOURS = 8;

    // ========== SHIFT LIMITS ==========
    public static final int MIN_SHIFT_MINUTES = 60;
    public static final int MAX_SHIFT_MINUTES = 720;
    public static final int MONTHLY_HOUR_LIMIT_MINUTES = 160 * 60;
    public static final int MAX_SHIFTS_PER_DAY = 2;
    public static final int MIN_REST_MINUTES = 8 * 60;
    public static final int WARN_REST_MINUTES = 12 * 60;

    // ========== PAGINATION ==========
    public static final int DEFAULT_PAGE_SIZE = 20;
    public static final int MAX_PAGE_SIZE = 100;

    // ========== VALIDATION ==========
    public static final int PASSWORD_MIN_LENGTH = 8;
    public static final int PHONE_MIN_LENGTH = 10;
    public static final int PHONE_MAX_LENGTH = 15;

    // ========== DATE/TIME FORMATS ==========
    public static final String DATE_FORMAT_YYYY_MM_DD = "yyyy-MM-dd";
    public static final String DATETIME_FORMAT = "yyyy-MM-dd HH:mm:ss";
    public static final String TIME_FORMAT_HH_MM = "HH:mm";

    // ========== FILE UPLOAD ==========
    public static final long MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024; // 5MB
    public static final String[] ALLOWED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".webp"};

    // ========== TRASH / SOFT DELETE ==========
    public static final int TRASH_RETENTION_DAYS = 30;

    // ========== MESSAGES ==========
    public static final String MSG_SUCCESS_OPERATION = "Thao tác thành công";
    public static final String MSG_ERROR_DEFAULT = "Đã xảy ra lỗi, vui lòng thử lại";

    // ========== SHIFT (CaLamViec) STATUSES ==========
    public static final String SHIFT_STATUS_DRAFT = "Draft";
    public static final String SHIFT_STATUS_PUBLISHED = "Published";
    public static final String SHIFT_STATUS_CONFIRMED = "Confirmed";
    public static final String SHIFT_STATUS_CHECKED_IN = "CheckedIn";
    public static final String SHIFT_STATUS_CHECKED_OUT = "CheckedOut";
    public static final String SHIFT_STATUS_COMPLETED = "Completed";
    public static final String SHIFT_STATUS_CANCELLED = "Cancelled";

    public static final java.util.List<Integer> ALLOWED_SHIFT_ROLES = java.util.List.of(ROLE_LE_TAN, ROLE_BAO_VE);

    public static boolean isTerminalStatus(String status) {
        return SHIFT_STATUS_CHECKED_OUT.equalsIgnoreCase(status) 
            || SHIFT_STATUS_COMPLETED.equalsIgnoreCase(status);
    }

    public static boolean isEditableStatus(String status) {
        return !isTerminalStatus(status) 
            && !SHIFT_STATUS_CHECKED_IN.equalsIgnoreCase(status)
            && !SHIFT_STATUS_CANCELLED.equalsIgnoreCase(status);
    }

    public static boolean isCancellableStatus(String status) {
        return SHIFT_STATUS_DRAFT.equalsIgnoreCase(status)
            || SHIFT_STATUS_PUBLISHED.equalsIgnoreCase(status)
            || SHIFT_STATUS_CONFIRMED.equalsIgnoreCase(status);
    }

    // ========== SHIFT TEMPLATES ==========
    public static class ShiftTemplateDto {
        public String id;
        public String name;
        public String startTime;
        public String endTime;
        public int breakMinutes;

        public ShiftTemplateDto(String id, String name, String startTime, String endTime, int breakMinutes) {
            this.id = id;
            this.name = name;
            this.startTime = startTime;
            this.endTime = endTime;
            this.breakMinutes = breakMinutes;
        }
    }

    public static ShiftTemplateDto getTemplateById(String templateId) {
        if ("1".equals(templateId) || "Ca sáng".equalsIgnoreCase(templateId)) {
            return new ShiftTemplateDto("1", "Ca sáng", "06:00", "14:00", 30);
        }
        if ("2".equals(templateId) || "Ca chiều".equalsIgnoreCase(templateId)) {
            return new ShiftTemplateDto("2", "Ca chiều", "14:00", "22:00", 30);
        }
        if ("3".equals(templateId) || "Ca đêm".equalsIgnoreCase(templateId)) {
            return new ShiftTemplateDto("3", "Ca đêm", "22:00", "06:00", 0);
        }
        return null;
    }

    private Constants() {
        // Private constructor to prevent instantiation
    }
}

