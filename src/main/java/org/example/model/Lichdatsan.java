package org.example.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.LocalDateTime;

@Entity
@Table(name = "LichDatSan")
public class Lichdatsan {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "DatSanID")
    private int datSanId;

    @Column(name = "AccountID")
    private Integer accountId;

    @Column(name = "SanID")
    private Integer sanId;

    @Column(name = "NgayDat", nullable = false)
    private LocalDate ngayDat;

    @Column(name = "GioBatDau", nullable = false)
    private LocalTime gioBatDau;

    @Column(name = "GioKetThuc", nullable = false)
    private LocalTime gioKetThuc;

    @Column(name = "ApDungGiaCoDen")
    private boolean apDungGiaCoDen;

    @Column(name = "TongTienDuKien")
    private BigDecimal tongTienDuKien;

    @Column(name = "TrangThai", length = 50)
    private String trangThai;

    @Column(name = "GhiChu", length = 255)
    private String ghiChu;

    @Column(name = "NguonDatSan", length = 50)
    private String nguonDatSan;

    @Column(name = "CreatedTime", insertable = false, updatable = false)
    private LocalDateTime createdTime;

    @Column(name = "IsDeleted")
    private boolean isDeleted;

    @Column(name = "DeletedAt")
    private LocalDateTime deletedAt;

    @Column(name = "DeletedBy")
    private Integer deletedBy;

    @Column(name = "TimeMode", length = 30)
    private String timeMode;

    @Column(name = "ReservedDurationMinutes")
    private Integer reservedDurationMinutes;

    @Column(name = "actual_end_time")
    private LocalTime actualEndTime;

    @Column(name = "actual_start_time")
    private LocalTime actualStartTime;

    @Column(name = "ActualStartAt")
    private LocalDateTime actualStartAt;

    @Column(name = "ActualEndAt")
    private LocalDateTime actualEndAt;

    @Column(name = "PricingFinalizedAt")
    private LocalDateTime pricingFinalizedAt;

    @Column(name = "EarlyCheckoutReason", length = 255)
    private String earlyCheckoutReason;

    @Column(name = "EarlyCheckoutDiscount")
    private BigDecimal earlyCheckoutDiscount;

    @Column(name = "HoldExpiresAt")
    private LocalDateTime holdExpiresAt;

    @Column(name = "DepositAmount")
    private BigDecimal depositAmount;

    @Column(name = "PaymentMethodConfirmed", length = 50)
    private String paymentMethodConfirmed;

    @Column(name = "TransactionCode", length = 100)
    private String transactionCode;

    @Column(name = "ConfirmedAt")
    private LocalDateTime confirmedAt;

    @Column(name = "ConfirmedBy")
    private Integer confirmedBy;

    @Column(name = "ConfirmSource", length = 20)
    private String confirmSource;

    @Column(name = "NoShowAt")
    private LocalDateTime noShowAt;

    @Column(name = "CancelType", length = 20)
    private String cancelType;

    @Column(name = "CancelReason", length = 255)
    private String cancelReason;

    @Column(name = "CancelledAt")
    private LocalDateTime cancelledAt;

    @Column(name = "CancelledBy")
    private Integer cancelledBy;

    @Column(name = "RequiresRefundReview")
    private boolean requiresRefundReview;

    // Relationships
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "SanID", insertable = false, updatable = false)
    private San san;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "AccountID", insertable = false, updatable = false)
    private TaiKhoan account;

    public Lichdatsan() {
    }

    public Lichdatsan(int datSanId, Integer accountId, Integer sanId, LocalDate ngayDat, LocalTime gioBatDau, LocalTime gioKetThuc, boolean apDungGiaCoDen, BigDecimal tongTienDuKien, String trangThai, String ghiChu, String nguonDatSan) {
        this.datSanId = datSanId;
        this.accountId = accountId;
        this.sanId = sanId;
        this.ngayDat = ngayDat;
        this.gioBatDau = gioBatDau;
        this.gioKetThuc = gioKetThuc;
        this.apDungGiaCoDen = apDungGiaCoDen;
        this.tongTienDuKien = tongTienDuKien;
        this.trangThai = trangThai;
        this.ghiChu = ghiChu;
        this.nguonDatSan = nguonDatSan;
    }

    public int getDatSanId() {
        return datSanId;
    }

    public void setDatSanId(int datSanId) {
        this.datSanId = datSanId;
    }

    public Integer getAccountId() {
        return accountId;
    }

    public void setAccountId(Integer accountId) {
        this.accountId = accountId;
    }

    public Integer getSanId() {
        return sanId;
    }

    public void setSanId(Integer sanId) {
        this.sanId = sanId;
    }

    public LocalDate getNgayDat() {
        return ngayDat;
    }

    public void setNgayDat(LocalDate ngayDat) {
        this.ngayDat = ngayDat;
    }

    public LocalTime getGioBatDau() {
        return gioBatDau;
    }

    public void setGioBatDau(LocalTime gioBatDau) {
        this.gioBatDau = gioBatDau;
    }

    public LocalTime getGioKetThuc() {
        return gioKetThuc;
    }

    public void setGioKetThuc(LocalTime gioKetThuc) {
        this.gioKetThuc = gioKetThuc;
    }

    public boolean isApDungGiaCoDen() {
        return apDungGiaCoDen;
    }

    public void setApDungGiaCoDen(boolean apDungGiaCoDen) {
        this.apDungGiaCoDen = apDungGiaCoDen;
    }

    public BigDecimal getTongTienDuKien() {
        return tongTienDuKien;
    }

    public void setTongTienDuKien(BigDecimal tongTienDuKien) {
        this.tongTienDuKien = tongTienDuKien;
    }

    public String getTrangThai() {
        return trangThai;
    }

    public void setTrangThai(String trangThai) {
        this.trangThai = trangThai;
    }

    public String getGhiChu() {
        return ghiChu;
    }

    public void setGhiChu(String ghiChu) {
        this.ghiChu = ghiChu;
    }

    public String getNguonDatSan() {
        return nguonDatSan;
    }

    public void setNguonDatSan(String nguonDatSan) {
        this.nguonDatSan = nguonDatSan;
    }

    public San getSan() {
        return san;
    }

    public void setSan(San san) {
        this.san = san;
    }

    public TaiKhoan getAccount() {
        return account;
    }

    public void setAccount(TaiKhoan account) {
        this.account = account;
    }

    public LocalDateTime getCreatedTime() {
        return createdTime;
    }

    public void setCreatedTime(LocalDateTime createdTime) {
        this.createdTime = createdTime;
    }

    public boolean isDeleted() { return isDeleted; }

    public void setDeleted(boolean deleted) { isDeleted = deleted; }

    public LocalDateTime getDeletedAt() { return deletedAt; }

    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }

    public Integer getDeletedBy() { return deletedBy; }

    public void setDeletedBy(Integer deletedBy) { this.deletedBy = deletedBy; }

    public String getTimeMode() {
        return timeMode;
    }

    public void setTimeMode(String timeMode) {
        this.timeMode = timeMode;
    }

    public Integer getReservedDurationMinutes() {
        return reservedDurationMinutes;
    }

    public void setReservedDurationMinutes(Integer reservedDurationMinutes) {
        this.reservedDurationMinutes = reservedDurationMinutes;
    }

    public LocalTime getActualEndTime() {
        return actualEndTime;
    }

    public void setActualEndTime(LocalTime actualEndTime) {
        this.actualEndTime = actualEndTime;
    }

    public LocalTime getActualStartTime() {
        return actualStartTime;
    }

    public void setActualStartTime(LocalTime actualStartTime) {
        this.actualStartTime = actualStartTime;
    }

    public LocalDateTime getActualStartAt() { return actualStartAt; }
    public void setActualStartAt(LocalDateTime actualStartAt) { this.actualStartAt = actualStartAt; }
    public LocalDateTime getActualEndAt() { return actualEndAt; }
    public void setActualEndAt(LocalDateTime actualEndAt) { this.actualEndAt = actualEndAt; }
    public LocalDateTime getPricingFinalizedAt() { return pricingFinalizedAt; }
    public void setPricingFinalizedAt(LocalDateTime pricingFinalizedAt) { this.pricingFinalizedAt = pricingFinalizedAt; }

    public String getEarlyCheckoutReason() {
        return earlyCheckoutReason;
    }

    public void setEarlyCheckoutReason(String earlyCheckoutReason) {
        this.earlyCheckoutReason = earlyCheckoutReason;
    }

    public BigDecimal getEarlyCheckoutDiscount() {
        return earlyCheckoutDiscount;
    }

    public void setEarlyCheckoutDiscount(BigDecimal earlyCheckoutDiscount) {
        this.earlyCheckoutDiscount = earlyCheckoutDiscount;
    }

    public LocalDateTime getHoldExpiresAt() {
        return holdExpiresAt;
    }

    public void setHoldExpiresAt(LocalDateTime holdExpiresAt) {
        this.holdExpiresAt = holdExpiresAt;
    }

    public BigDecimal getDepositAmount() {
        return depositAmount;
    }

    public void setDepositAmount(BigDecimal depositAmount) {
        this.depositAmount = depositAmount;
    }

    public String getPaymentMethodConfirmed() {
        return paymentMethodConfirmed;
    }

    public void setPaymentMethodConfirmed(String paymentMethodConfirmed) {
        this.paymentMethodConfirmed = paymentMethodConfirmed;
    }

    public String getTransactionCode() {
        return transactionCode;
    }

    public void setTransactionCode(String transactionCode) {
        this.transactionCode = transactionCode;
    }

    public LocalDateTime getConfirmedAt() {
        return confirmedAt;
    }

    public void setConfirmedAt(LocalDateTime confirmedAt) {
        this.confirmedAt = confirmedAt;
    }

    public Integer getConfirmedBy() {
        return confirmedBy;
    }

    public void setConfirmedBy(Integer confirmedBy) {
        this.confirmedBy = confirmedBy;
    }

    public String getConfirmSource() {
        return confirmSource;
    }

    public void setConfirmSource(String confirmSource) {
        this.confirmSource = confirmSource;
    }

    public LocalDateTime getNoShowAt() {
        return noShowAt;
    }

    public void setNoShowAt(LocalDateTime noShowAt) {
        this.noShowAt = noShowAt;
    }

    public String getCancelType() {
        return cancelType;
    }

    public void setCancelType(String cancelType) {
        this.cancelType = cancelType;
    }

    public String getCancelReason() {
        return cancelReason;
    }

    public void setCancelReason(String cancelReason) {
        this.cancelReason = cancelReason;
    }

    public LocalDateTime getCancelledAt() {
        return cancelledAt;
    }

    public void setCancelledAt(LocalDateTime cancelledAt) {
        this.cancelledAt = cancelledAt;
    }

    public Integer getCancelledBy() {
        return cancelledBy;
    }

    public void setCancelledBy(Integer cancelledBy) {
        this.cancelledBy = cancelledBy;
    }

    public boolean getRequiresRefundReview() {
        return requiresRefundReview;
    }

    public void setRequiresRefundReview(boolean requiresRefundReview) {
        this.requiresRefundReview = requiresRefundReview;
    }

    @Override
    public String toString() {
        return "Lichdatsan{" +
                "datSanId=" + datSanId +
                ", accountId=" + accountId +
                ", sanId=" + sanId +
                ", ngayDat=" + ngayDat +
                ", gioBatDau=" + gioBatDau +
                ", gioKetThuc=" + gioKetThuc +
                ", apDungGiaCoDen=" + apDungGiaCoDen +
                ", tongTienDuKien=" + tongTienDuKien +
                ", trangThai='" + trangThai + '\'' +
                ", ghiChu='" + ghiChu + '\'' +
                ", nguonDatSan='" + nguonDatSan + '\'' +
                '}';
    }
}
