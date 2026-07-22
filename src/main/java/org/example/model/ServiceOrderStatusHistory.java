package org.example.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "ServiceOrderStatusHistory")
public class ServiceOrderStatusHistory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "HistoryID")
    private int historyID;

    @Column(name = "OrderID", nullable = false)
    private int orderID;

    @Column(name = "FromStatus", length = 30)
    private String fromStatus;

    @Column(name = "ToStatus", nullable = false, length = 30)
    private String toStatus;

    @Column(name = "ChangedBy")
    private Integer changedBy;

    @Column(name = "ChangedAt")
    private LocalDateTime changedAt;

    @Column(name = "Note", length = 500)
    private String note;

    public int getHistoryID() { return historyID; }
    public void setHistoryID(int historyID) { this.historyID = historyID; }
    public int getOrderID() { return orderID; }
    public void setOrderID(int orderID) { this.orderID = orderID; }
    public String getFromStatus() { return fromStatus; }
    public void setFromStatus(String fromStatus) { this.fromStatus = fromStatus; }
    public String getToStatus() { return toStatus; }
    public void setToStatus(String toStatus) { this.toStatus = toStatus; }
    public Integer getChangedBy() { return changedBy; }
    public void setChangedBy(Integer changedBy) { this.changedBy = changedBy; }
    public LocalDateTime getChangedAt() { return changedAt; }
    public void setChangedAt(LocalDateTime changedAt) { this.changedAt = changedAt; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
