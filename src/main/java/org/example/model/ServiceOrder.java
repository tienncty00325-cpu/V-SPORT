package org.example.model;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "ServiceOrder")
public class ServiceOrder {
    public static final String PENDING_CONFIRMATION = "PENDING_CONFIRMATION";
    public static final String CONFIRMED = "CONFIRMED";
    public static final String ITEM_RECEIVED = "ITEM_RECEIVED";
    public static final String IN_PROGRESS = "IN_PROGRESS";
    public static final String READY_FOR_PICKUP = "READY_FOR_PICKUP";
    public static final String COMPLETED = "COMPLETED";
    public static final String CANCELLED = "CANCELLED";
    public static final String REJECTED = "REJECTED";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "OrderID")
    private int orderID;

    @Column(name = "CustomerID", nullable = false)
    private int customerID;

    @Column(name = "CoSoID", nullable = false)
    private int coSoID;

    @Column(name = "ServiceID", nullable = false)
    private int serviceID;

    @Column(name = "BookingID")
    private Integer bookingID;

    @Column(name = "Status", nullable = false, length = 30)
    private String status = PENDING_CONFIRMATION;

    @Column(name = "RequestedAt")
    private LocalDateTime requestedAt;

    @Column(name = "AppointmentDate", nullable = false)
    private LocalDate appointmentDate;

    @Column(name = "DropOffTime", length = 20)
    private String dropOffTime;

    @Column(name = "ExpectedPickupTime")
    private LocalDateTime expectedPickupTime;

    @Column(name = "ActualReceivedTime")
    private LocalDateTime actualReceivedTime;

    @Column(name = "CompletedTime")
    private LocalDateTime completedTime;

    @Column(name = "DeliveredTime")
    private LocalDateTime deliveredTime;

    @Column(name = "CancelledTime")
    private LocalDateTime cancelledTime;

    @Column(name = "CustomerNote", length = 500)
    private String customerNote;

    @Column(name = "ManagerNote", length = 500)
    private String managerNote;

    @Column(name = "EstimatedPrice", nullable = false)
    private double estimatedPrice;

    @Column(name = "ConfirmedPrice")
    private Double confirmedPrice;

    @Column(name = "CancellationReason", length = 500)
    private String cancellationReason;

    @Column(name = "CreatedAt")
    private LocalDateTime createdAt;

    @Column(name = "UpdatedAt")
    private LocalDateTime updatedAt;

    public int getOrderID() { return orderID; }
    public void setOrderID(int orderID) { this.orderID = orderID; }
    public int getCustomerID() { return customerID; }
    public void setCustomerID(int customerID) { this.customerID = customerID; }
    public int getCoSoID() { return coSoID; }
    public void setCoSoID(int coSoID) { this.coSoID = coSoID; }
    public int getServiceID() { return serviceID; }
    public void setServiceID(int serviceID) { this.serviceID = serviceID; }
    public Integer getBookingID() { return bookingID; }
    public void setBookingID(Integer bookingID) { this.bookingID = bookingID; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDateTime getRequestedAt() { return requestedAt; }
    public void setRequestedAt(LocalDateTime requestedAt) { this.requestedAt = requestedAt; }
    public LocalDate getAppointmentDate() { return appointmentDate; }
    public void setAppointmentDate(LocalDate appointmentDate) { this.appointmentDate = appointmentDate; }
    public String getDropOffTime() { return dropOffTime; }
    public void setDropOffTime(String dropOffTime) { this.dropOffTime = dropOffTime; }
    public LocalDateTime getExpectedPickupTime() { return expectedPickupTime; }
    public void setExpectedPickupTime(LocalDateTime expectedPickupTime) { this.expectedPickupTime = expectedPickupTime; }
    public LocalDateTime getActualReceivedTime() { return actualReceivedTime; }
    public void setActualReceivedTime(LocalDateTime actualReceivedTime) { this.actualReceivedTime = actualReceivedTime; }
    public LocalDateTime getCompletedTime() { return completedTime; }
    public void setCompletedTime(LocalDateTime completedTime) { this.completedTime = completedTime; }
    public LocalDateTime getDeliveredTime() { return deliveredTime; }
    public void setDeliveredTime(LocalDateTime deliveredTime) { this.deliveredTime = deliveredTime; }
    public LocalDateTime getCancelledTime() { return cancelledTime; }
    public void setCancelledTime(LocalDateTime cancelledTime) { this.cancelledTime = cancelledTime; }
    public String getCustomerNote() { return customerNote; }
    public void setCustomerNote(String customerNote) { this.customerNote = customerNote; }
    public String getManagerNote() { return managerNote; }
    public void setManagerNote(String managerNote) { this.managerNote = managerNote; }
    public double getEstimatedPrice() { return estimatedPrice; }
    public void setEstimatedPrice(double estimatedPrice) { this.estimatedPrice = estimatedPrice; }
    public Double getConfirmedPrice() { return confirmedPrice; }
    public void setConfirmedPrice(Double confirmedPrice) { this.confirmedPrice = confirmedPrice; }
    public String getCancellationReason() { return cancellationReason; }
    public void setCancellationReason(String cancellationReason) { this.cancellationReason = cancellationReason; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
