package org.example.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "CoSoCapability")
public class CoSoCapability {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "CapabilityID")
    private int capabilityId;

    @Column(name = "CoSoID", nullable = false)
    private int coSoId;

    @Column(name = "CapabilityType", nullable = false, length = 50)
    private String capabilityType;

    @Column(name = "TrangThai", nullable = false, length = 20)
    private String trangThai;

    @Column(name = "RequestedAt", nullable = false)
    private LocalDateTime requestedAt;

    @Column(name = "ApprovedBy")
    private Integer approvedBy;

    @Column(name = "ApprovedAt")
    private LocalDateTime approvedAt;

    @Column(name = "RejectReason", length = 500)
    private String rejectReason;

    @Column(name = "Note", length = 500)
    private String note;

    @Column(name = "UpdatedAt", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        if (requestedAt == null) requestedAt = now;
        if (updatedAt == null) updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public CoSoCapability() {
    }

    public int getCapabilityId() { return capabilityId; }
    public void setCapabilityId(int capabilityId) { this.capabilityId = capabilityId; }

    public int getCoSoId() { return coSoId; }
    public void setCoSoId(int coSoId) { this.coSoId = coSoId; }

    public String getCapabilityType() { return capabilityType; }
    public void setCapabilityType(String capabilityType) { this.capabilityType = capabilityType; }

    public String getTrangThai() { return trangThai; }
    public void setTrangThai(String trangThai) { this.trangThai = trangThai; }

    public LocalDateTime getRequestedAt() { return requestedAt; }
    public void setRequestedAt(LocalDateTime requestedAt) { this.requestedAt = requestedAt; }

    public Integer getApprovedBy() { return approvedBy; }
    public void setApprovedBy(Integer approvedBy) { this.approvedBy = approvedBy; }

    public LocalDateTime getApprovedAt() { return approvedAt; }
    public void setApprovedAt(LocalDateTime approvedAt) { this.approvedAt = approvedAt; }

    public String getRejectReason() { return rejectReason; }
    public void setRejectReason(String rejectReason) { this.rejectReason = rejectReason; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
