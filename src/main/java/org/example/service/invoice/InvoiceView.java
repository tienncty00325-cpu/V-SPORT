package org.example.service.invoice;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.List;

/**
 * Bản ghi hóa đơn CHỈ ĐỌC dùng để hiển thị - dùng chung cho trang in (HoaDonPrint.jsp),
 * API chi tiết hóa đơn (dùng bởi modal thanh toán) và Quản lý hóa đơn.
 * Tất cả số tiền đã CHỐT tại thời điểm bán/thanh toán, không tính lại theo giá hiện tại.
 */
public class InvoiceView {
    private final int hoaDonId;
    private final String invoiceCode;
    private final String invoiceType;
    private final String invoiceTypeLabel;
    private final Integer parentHoaDonId;
    private final String paymentStatus;
    private final boolean paid;
    private final String paymentMethod;
    private final Date paidAt;
    private final String paidAtLabel;

    private static final DateTimeFormatter PAID_AT_FMT = DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy");

    private final String facilityName;
    private final String facilityAddress;
    private final String facilityPhone;

    private final String courtName;
    private final String courtTypeName;

    private final String customerName;
    private final String customerPhone;
    private final String cashierName;

    private final String playMode;
    private final String playModeLabel;

    private final LocalDateTime actualStartAt;
    private final LocalDateTime actualEndAt;
    private final String actualStartLabel;
    private final String actualEndLabel;
    private final boolean crossesMidnight;
    private final long actualDurationMinutes;
    private final long chargedDurationMinutes;
    private final String actualDurationLabel;
    private final String chargedDurationLabel;
    private final boolean minimumChargeApplied;

    private final List<InvoiceCourtSegmentView> courtSegments;
    private final List<InvoiceServiceItemView> services;

    private final double courtAmount;
    private final double serviceAmount;
    private final double parkingFee;
    private final double discountAmount;
    private final double totalAmount;

    private final List<Integer> splitHoaDonIds;
    private final String invoiceManagementUrl;
    private final String printUrl;

    private final String transactionCode;
    private final String confirmedByName;
    private final String confirmedAtLabel;

    public InvoiceView(int hoaDonId, String invoiceType, Integer parentHoaDonId, String paymentStatus,
                        String paymentMethod, Date paidAt, String facilityName, String facilityAddress,
                        String facilityPhone, String courtName, String courtTypeName, String customerName,
                        String customerPhone, String cashierName, String playMode, LocalDateTime actualStartAt, LocalDateTime actualEndAt,
                        String actualStartLabel, String actualEndLabel, boolean crossesMidnight,
                        long actualDurationMinutes, long chargedDurationMinutes,
                        String actualDurationLabel, String chargedDurationLabel,
                        List<InvoiceCourtSegmentView> courtSegments, List<InvoiceServiceItemView> services,
                        double courtAmount, double serviceAmount, double parkingFee, double discountAmount,
                        double totalAmount, List<Integer> splitHoaDonIds, String invoiceManagementUrl, String printUrl,
                        String transactionCode, String confirmedByName, String confirmedAtLabel) {
        this.hoaDonId = hoaDonId;
        this.invoiceCode = "#" + hoaDonId;
        this.invoiceType = invoiceType;
        this.invoiceTypeLabel = "SPLIT".equals(invoiceType) ? "Hóa đơn tách dịch vụ" : "Hóa đơn chính";
        this.parentHoaDonId = parentHoaDonId;
        this.paymentStatus = paymentStatus;
        this.paid = "Đã thanh toán".equals(paymentStatus);
        this.paymentMethod = paymentMethod;
        this.paidAt = paidAt;
        this.paidAtLabel = paidAt == null ? "-"
                : LocalDateTime.ofInstant(paidAt.toInstant(), ZoneId.systemDefault()).format(PAID_AT_FMT);
        this.facilityName = facilityName;
        this.facilityAddress = facilityAddress;
        this.facilityPhone = facilityPhone;
        this.courtName = courtName;
        this.courtTypeName = courtTypeName;
        this.customerName = customerName;
        this.customerPhone = customerPhone;
        this.cashierName = cashierName;
        this.playMode = playMode;
        this.playModeLabel = "OPEN_ENDED".equals(playMode) ? "Giờ không cố định" : "Giờ cố định";
        this.actualStartAt = actualStartAt;
        this.actualEndAt = actualEndAt;
        this.actualStartLabel = actualStartLabel;
        this.actualEndLabel = actualEndLabel;
        this.crossesMidnight = crossesMidnight;
        this.actualDurationMinutes = actualDurationMinutes;
        this.chargedDurationMinutes = chargedDurationMinutes;
        this.actualDurationLabel = actualDurationLabel;
        this.chargedDurationLabel = chargedDurationLabel;
        this.minimumChargeApplied = chargedDurationMinutes > actualDurationMinutes;
        this.courtSegments = List.copyOf(courtSegments);
        this.services = List.copyOf(services);
        this.courtAmount = courtAmount;
        this.serviceAmount = serviceAmount;
        this.parkingFee = parkingFee;
        this.discountAmount = discountAmount;
        this.totalAmount = totalAmount;
        this.splitHoaDonIds = List.copyOf(splitHoaDonIds);
        this.invoiceManagementUrl = invoiceManagementUrl;
        this.printUrl = printUrl;
        this.transactionCode = transactionCode;
        this.confirmedByName = confirmedByName;
        this.confirmedAtLabel = confirmedAtLabel;
    }

    public int getHoaDonId() { return hoaDonId; }
    public String getInvoiceCode() { return invoiceCode; }
    public String getInvoiceType() { return invoiceType; }
    public String getInvoiceTypeLabel() { return invoiceTypeLabel; }
    public boolean isSplit() { return "SPLIT".equals(invoiceType); }
    public Integer getParentHoaDonId() { return parentHoaDonId; }
    public String getPaymentStatus() { return paymentStatus; }
    public boolean isPaid() { return paid; }
    public String getPaymentMethod() { return paymentMethod; }
    public Date getPaidAt() { return paidAt; }
    public String getPaidAtLabel() { return paidAtLabel; }

    public String getFacilityName() { return facilityName; }
    public String getFacilityAddress() { return facilityAddress; }
    public String getFacilityPhone() { return facilityPhone; }

    public String getCourtName() { return courtName; }
    public String getCourtTypeName() { return courtTypeName; }

    public String getCustomerName() { return customerName; }
    public String getCustomerPhone() { return customerPhone; }
    public String getCashierName() { return cashierName; }

    public String getPlayMode() { return playMode; }
    public String getPlayModeLabel() { return playModeLabel; }

    public LocalDateTime getActualStartAt() { return actualStartAt; }
    public LocalDateTime getActualEndAt() { return actualEndAt; }
    public String getActualStartLabel() { return actualStartLabel; }
    public String getActualEndLabel() { return actualEndLabel; }
    public boolean isCrossesMidnight() { return crossesMidnight; }
    public long getActualDurationMinutes() { return actualDurationMinutes; }
    public long getChargedDurationMinutes() { return chargedDurationMinutes; }
    public String getActualDurationLabel() { return actualDurationLabel; }
    public String getChargedDurationLabel() { return chargedDurationLabel; }
    public boolean isMinimumChargeApplied() { return minimumChargeApplied; }

    public List<InvoiceCourtSegmentView> getCourtSegments() { return courtSegments; }
    public List<InvoiceServiceItemView> getServices() { return services; }

    public double getCourtAmount() { return courtAmount; }
    public double getServiceAmount() { return serviceAmount; }
    public double getParkingFee() { return parkingFee; }
    public double getDiscountAmount() { return discountAmount; }
    public double getTotalAmount() { return totalAmount; }

    public List<Integer> getSplitHoaDonIds() { return splitHoaDonIds; }
    public String getInvoiceManagementUrl() { return invoiceManagementUrl; }
    public String getPrintUrl() { return printUrl; }

    public String getTransactionCode() { return transactionCode; }
    public String getConfirmedByName() { return confirmedByName; }
    public String getConfirmedAtLabel() { return confirmedAtLabel; }
}
