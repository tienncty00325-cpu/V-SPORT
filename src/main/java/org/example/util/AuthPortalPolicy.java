package org.example.util;

/**
 * Chính sách hai cổng đăng nhập V-SPORT.
 * Portal chỉ quyết định NHÓM ROLE ĐƯỢC PHÉP đăng nhập tại trang đó và giao diện;
 * nó tuyệt đối không cấp role — role luôn đọc từ Account sau khi BCrypt verify.
 * Mapping role theo {@link RoleRedirectUtil}: 1=Admin, 2=Manager, 3=Customer, 4/5=Staff.
 */
public final class AuthPortalPolicy {

    public static final String PORTAL_CUSTOMER = "customer";
    public static final String PORTAL_INTERNAL = "internal";

    private AuthPortalPolicy() {
    }

    /** Parse portal từ request theo allowlist; giá trị lạ/null rơi về cổng khách hàng. */
    public static String parsePortal(String raw) {
        return PORTAL_INTERNAL.equals(raw) ? PORTAL_INTERNAL : PORTAL_CUSTOMER;
    }

    /** true nếu role thuộc nhóm vận hành (Admin/Manager/Staff). */
    public static boolean isInternalRole(Integer roleId) {
        if (roleId == null) return false;
        return roleId == RoleRedirectUtil.ROLE_ADMIN
                || roleId == RoleRedirectUtil.ROLE_MANAGER
                || RoleRedirectUtil.isStaff(roleId);
    }

    /** Role có được phép đăng nhập tại portal này không (sau khi credentials đã đúng). */
    public static boolean isRoleAllowed(String portal, Integer roleId) {
        if (roleId == null) return false;
        if (PORTAL_INTERNAL.equals(portal)) {
            return isInternalRole(roleId);
        }
        return roleId == RoleRedirectUtil.ROLE_CUSTOMER;
    }
}
