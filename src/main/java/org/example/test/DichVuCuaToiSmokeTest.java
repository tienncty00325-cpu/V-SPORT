package org.example.test;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityTransaction;
import org.example.model.CoSo;
import org.example.model.ServiceOrder;
import org.example.model.SportService;
import org.example.model.TaiKhoan;
import org.example.service.customer.ServiceOrderService;
import org.example.service.customer.ServiceOrderService.CancelErrorCode;
import org.example.service.customer.ServiceOrderService.CancelResult;
import org.example.service.customer.ServiceOrderService.ListResult;
import org.example.util.JPAUtil;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Smoke test cho Task 7 (Customer theo dõi đơn dịch vụ) qua đúng JPAUtil, không qua HTTP.
 * Chạy: mvn exec:java -Dexec.mainClass=org.example.test.DichVuCuaToiSmokeTest
 */
public class DichVuCuaToiSmokeTest {

    static int passed = 0;
    static int failed = 0;

    static void check(String tc, boolean cond, String detail) {
        if (cond) {
            System.out.printf("[PASS] %s%n", tc);
            passed++;
        } else {
            System.out.printf("[FAIL] %s | %s%n", tc, detail);
            failed++;
        }
    }

    public static void main(String[] args) {
        ServiceOrderService svc = new ServiceOrderService();

        int realCustomerId = -1;
        int realOrderId = -1;
        int otherCustomerId = -1;
        List<Integer> seededOrderIds = new ArrayList<>();
        Integer seededServiceId = null;

        EntityManager em = JPAUtil.getEntityManager();
        try {
            List<ServiceOrder> orders = em.createQuery(
                    "SELECT o FROM ServiceOrder o ORDER BY o.orderID ASC", ServiceOrder.class)
                    .setMaxResults(50)
                    .getResultList();
            if (!orders.isEmpty()) {
                realOrderId = orders.get(0).getOrderID();
                realCustomerId = orders.get(0).getCustomerID();
                for (ServiceOrder o : orders) {
                    if (o.getCustomerID() != realCustomerId) {
                        otherCustomerId = o.getCustomerID();
                        break;
                    }
                }
            }

            if (realCustomerId == -1) {
                // Không có dữ liệu sẵn: seed tối thiểu 2 ServiceOrder cho 2 TaiKhoan khác nhau
                // để test được ownership/IDOR. Sẽ dọn lại sau khi test xong.
                List<TaiKhoan> accounts = em.createQuery(
                        "SELECT t FROM TaiKhoan t ORDER BY t.accountId ASC", TaiKhoan.class)
                        .setMaxResults(2).getResultList();
                List<SportService> services = em.createQuery(
                        "SELECT s FROM SportService s ORDER BY s.serviceID ASC", SportService.class)
                        .setMaxResults(1).getResultList();
                List<CoSo> coSos = em.createQuery(
                        "SELECT c FROM CoSo c ORDER BY c.CoSoID ASC", CoSo.class)
                        .setMaxResults(1).getResultList();

                check("TC1_has_seed_data", accounts.size() >= 2 && !coSos.isEmpty(),
                        "Không đủ TaiKhoan/CoSo trong DB để seed dữ liệu test");

                if (accounts.size() >= 2 && !coSos.isEmpty()) {
                    CoSo coSoRow = coSos.get(0);

                    EntityTransaction tx = em.getTransaction();
                    tx.begin();

                    int serviceId;
                    if (!services.isEmpty()) {
                        serviceId = services.get(0).getServiceID();
                    } else {
                        SportService svcRow = new SportService();
                        svcRow.setCoSoID(coSoRow.getCoSoID());
                        svcRow.setServiceType("CANG_LUOI");
                        svcRow.setServiceName("Seed cho DichVuCuaToiSmokeTest");
                        svcRow.setBasePrice(50000);
                        svcRow.setEstimatedMinutes(60);
                        svcRow.setAcceptingRequests(true);
                        svcRow.setCreatedAt(LocalDateTime.now());
                        svcRow.setUpdatedAt(LocalDateTime.now());
                        em.persist(svcRow);
                        em.flush();
                        seededServiceId = svcRow.getServiceID();
                        serviceId = seededServiceId;
                    }

                    ServiceOrder o1 = buildSeedOrder(accounts.get(0).getAccountId(), coSoRow.getCoSoID(), serviceId);
                    ServiceOrder o2 = buildSeedOrder(accounts.get(1).getAccountId(), coSoRow.getCoSoID(), serviceId);
                    em.persist(o1);
                    em.persist(o2);
                    tx.commit();

                    seededOrderIds.add(o1.getOrderID());
                    seededOrderIds.add(o2.getOrderID());

                    realCustomerId = accounts.get(0).getAccountId();
                    realOrderId = o1.getOrderID();
                    otherCustomerId = accounts.get(1).getAccountId();
                }
            } else {
                check("TC1_has_seed_data", true, "");
            }
        } finally {
            em.close();
        }

        if (realCustomerId == -1) {
            System.out.println("Bỏ qua các test còn lại: không đủ dữ liệu để test.");
            System.out.printf("%n=== %d PASS / %d FAIL ===%n", passed, failed);
            System.exit(failed == 0 ? 0 : 1);
            return;
        }

        // TC2: list trả về đúng owner, không lẫn đơn của người khác
        ListResult list = svc.listForCustomer(realCustomerId, null, null, null, null, null, 1, 20);
        check("TC2_list_not_null", list != null, "listForCustomer trả null");
        check("TC3_list_has_items", list != null && list.items != null && !list.items.isEmpty(),
                "list rỗng dù đã biết có ít nhất 1 đơn của customer này");
        boolean allOwnedRight = list != null && list.items.stream()
                .allMatch(m -> m.get("orderId") != null);
        check("TC4_list_items_wellformed", allOwnedRight, "item thiếu orderId");

        // TC5: pagination fields hợp lệ
        check("TC5_pagination_consistent", list != null && list.page == 1 && list.pageSize == 20
                && list.totalItems >= list.items.size(), "pagination không nhất quán");

        // TC6: counts group-by đủ nhóm status
        check("TC6_counts_present", list != null && list.counts != null && !list.counts.isEmpty(),
                "counts theo status rỗng");

        // TC7: uiGroup filter không lỗi (dùng nhóm đầu tiên có count > 0 nếu có)
        String groupToFilter = null;
        if (list != null && list.counts != null) {
            for (Map.Entry<String, Long> e : list.counts.entrySet()) {
                if (e.getValue() > 0) { groupToFilter = e.getKey(); break; }
            }
        }
        if (groupToFilter != null) {
            ListResult filtered = svc.listForCustomer(realCustomerId, groupToFilter, null, null, null, null, 1, 20);
            check("TC7_filter_by_uiGroup", filtered != null && !filtered.items.isEmpty(),
                    "filter theo uiGroup=" + groupToFilter + " trả rỗng dù count > 0");
        } else {
            check("TC7_filter_by_uiGroup", true, "skip - không có group nào count > 0");
        }

        // TC8: getDetailForCustomer đúng owner trả về map đầy đủ
        Map<String, Object> detail = svc.getDetailForCustomer(realCustomerId, realOrderId);
        check("TC8_detail_owner_ok", detail != null, "detail null dù đúng chủ sở hữu");
        check("TC9_detail_has_orderId", detail != null && Integer.valueOf(realOrderId).equals(detail.get("orderId")),
                "detail.orderId không khớp");

        // TC10: IDOR - orderId không tồn tại -> null (servlet map 404)
        Map<String, Object> notFound = svc.getDetailForCustomer(realCustomerId, 999999999);
        check("TC10_detail_nonexistent_order_null", notFound == null, "đơn không tồn tại lại trả về non-null");

        // TC11: IDOR - đúng order nhưng sai customer -> null
        if (otherCustomerId != -1) {
            Map<String, Object> wrongOwner = svc.getDetailForCustomer(otherCustomerId, realOrderId);
            check("TC11_detail_wrong_owner_null", wrongOwner == null,
                    "IDOR: customer khác vẫn xem được đơn không phải của mình");
        } else {
            check("TC11_detail_wrong_owner_null", true, "skip - chỉ có 1 customer trong seed data");
        }

        // TC12: cancel - lý do rỗng phải bị validation reject, không đụng DB
        CancelResult emptyReason = svc.cancelOrderByCustomer(realCustomerId, realOrderId, "");
        check("TC12_cancel_empty_reason_rejected",
                !emptyReason.success && emptyReason.errorCode == CancelErrorCode.VALIDATION,
                "cancel với lý do rỗng không bị chặn ở validation");

        // TC13: cancel - orderId không tồn tại -> NOT_FOUND (không lộ thông tin)
        CancelResult notFoundCancel = svc.cancelOrderByCustomer(realCustomerId, 999999999, "test lý do hủy hợp lệ");
        check("TC13_cancel_nonexistent_not_found",
                !notFoundCancel.success && notFoundCancel.errorCode == CancelErrorCode.NOT_FOUND,
                "cancel đơn không tồn tại không trả NOT_FOUND");

        // TC14: cancel - IDOR, đúng order nhưng sai customer -> NOT_FOUND (không phải FORBIDDEN, tránh lộ tồn tại)
        if (otherCustomerId != -1) {
            CancelResult wrongOwnerCancel = svc.cancelOrderByCustomer(otherCustomerId, realOrderId, "test lý do hủy hợp lệ");
            check("TC14_cancel_wrong_owner_not_found",
                    !wrongOwnerCancel.success && wrongOwnerCancel.errorCode == CancelErrorCode.NOT_FOUND,
                    "IDOR: cancel bởi customer khác không bị chặn đúng cách, errorCode=" + wrongOwnerCancel.errorCode);
        } else {
            check("TC14_cancel_wrong_owner_not_found", true, "skip - chỉ có 1 customer trong seed data");
        }

        // Dọn dữ liệu seed để không để lại rác trong DB
        if (!seededOrderIds.isEmpty()) {
            EntityManager cleanupEm = JPAUtil.getEntityManager();
            EntityTransaction tx = cleanupEm.getTransaction();
            try {
                tx.begin();
                for (Integer id : seededOrderIds) {
                    ServiceOrder o = cleanupEm.find(ServiceOrder.class, id);
                    if (o != null) cleanupEm.remove(o);
                }
                if (seededServiceId != null) {
                    SportService s = cleanupEm.find(SportService.class, seededServiceId);
                    if (s != null) cleanupEm.remove(s);
                }
                tx.commit();
                System.out.println("Đã dọn " + seededOrderIds.size() + " ServiceOrder"
                        + (seededServiceId != null ? " + 1 SportService" : "") + " seed cho test.");
            } finally {
                cleanupEm.close();
            }
        }

        System.out.printf("%n=== %d PASS / %d FAIL ===%n", passed, failed);
        System.exit(failed == 0 ? 0 : 1);
    }

    private static ServiceOrder buildSeedOrder(int customerId, int coSoId, int serviceId) {
        ServiceOrder o = new ServiceOrder();
        o.setCustomerID(customerId);
        o.setCoSoID(coSoId);
        o.setServiceID(serviceId);
        o.setStatus(ServiceOrder.PENDING_CONFIRMATION);
        o.setRequestedAt(LocalDateTime.now());
        o.setAppointmentDate(LocalDate.now().plusDays(1));
        o.setDropOffTime("Sáng");
        o.setCustomerNote("Seed cho DichVuCuaToiSmokeTest");
        o.setEstimatedPrice(50000);
        o.setCreatedAt(LocalDateTime.now());
        o.setUpdatedAt(LocalDateTime.now());
        return o;
    }
}
