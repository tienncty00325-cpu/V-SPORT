package org.example.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AuthPortalPolicyTest {

    @Test
    void parsePortalTheoAllowlist() {
        assertEquals("customer", AuthPortalPolicy.parsePortal("customer"));
        assertEquals("internal", AuthPortalPolicy.parsePortal("internal"));
        assertEquals("customer", AuthPortalPolicy.parsePortal(null));
        assertEquals("customer", AuthPortalPolicy.parsePortal(""));
        assertEquals("customer", AuthPortalPolicy.parsePortal("admin"));
        assertEquals("customer", AuthPortalPolicy.parsePortal("INTERNAL"));
        assertEquals("customer", AuthPortalPolicy.parsePortal("internal'--"));
    }

    @Test
    void customerPortalChiChoCustomer() {
        assertTrue(AuthPortalPolicy.isRoleAllowed("customer", RoleRedirectUtil.ROLE_CUSTOMER));
        assertFalse(AuthPortalPolicy.isRoleAllowed("customer", RoleRedirectUtil.ROLE_ADMIN));
        assertFalse(AuthPortalPolicy.isRoleAllowed("customer", RoleRedirectUtil.ROLE_MANAGER));
        assertFalse(AuthPortalPolicy.isRoleAllowed("customer", RoleRedirectUtil.ROLE_LETÂN));
        assertFalse(AuthPortalPolicy.isRoleAllowed("customer", RoleRedirectUtil.ROLE_BAOVE));
        assertFalse(AuthPortalPolicy.isRoleAllowed("customer", null));
    }

    @Test
    void internalPortalChoAdminManagerStaff() {
        assertTrue(AuthPortalPolicy.isRoleAllowed("internal", RoleRedirectUtil.ROLE_ADMIN));
        assertTrue(AuthPortalPolicy.isRoleAllowed("internal", RoleRedirectUtil.ROLE_MANAGER));
        assertTrue(AuthPortalPolicy.isRoleAllowed("internal", RoleRedirectUtil.ROLE_LETÂN));
        assertTrue(AuthPortalPolicy.isRoleAllowed("internal", RoleRedirectUtil.ROLE_BAOVE));
        assertFalse(AuthPortalPolicy.isRoleAllowed("internal", RoleRedirectUtil.ROLE_CUSTOMER));
        assertFalse(AuthPortalPolicy.isRoleAllowed("internal", null));
        assertFalse(AuthPortalPolicy.isRoleAllowed("internal", 99));
    }

    @Test
    void isInternalRolePhanNhomDung() {
        assertTrue(AuthPortalPolicy.isInternalRole(1));
        assertTrue(AuthPortalPolicy.isInternalRole(2));
        assertTrue(AuthPortalPolicy.isInternalRole(4));
        assertTrue(AuthPortalPolicy.isInternalRole(5));
        assertFalse(AuthPortalPolicy.isInternalRole(3));
        assertFalse(AuthPortalPolicy.isInternalRole(null));
    }
}
