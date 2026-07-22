package org.example.model;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "SportService")
public class SportService {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ServiceID")
    private int serviceID;

    @Column(name = "CoSoID", nullable = false)
    private int coSoID;

    @Column(name = "ServiceType", nullable = false, length = 30)
    private String serviceType;

    @Column(name = "ServiceName", nullable = false, length = 150)
    private String serviceName;

    @Column(name = "SportType", length = 50)
    private String sportType;

    @Column(name = "Description", length = 1000)
    private String description;

    @Column(name = "BasePrice", nullable = false)
    private double basePrice;

    @Column(name = "Unit", length = 30)
    private String unit;

    @Column(name = "EstimatedMinutes", nullable = false)
    private int estimatedMinutes;

    @Column(name = "MaxRequestsPerDay")
    private Integer maxRequestsPerDay;

    @Column(name = "ReceiveTimeStart")
    private LocalTime receiveTimeStart;

    @Column(name = "ReceiveTimeEnd")
    private LocalTime receiveTimeEnd;

    @Column(name = "ImageUrl", length = 300)
    private String imageUrl;

    @Column(name = "IsAcceptingRequests", nullable = false)
    private boolean acceptingRequests = true;

    @Column(name = "Policy", length = 1000)
    private String policy;

    @Column(name = "CustomerNote", length = 500)
    private String customerNote;

    @Column(name = "IsDeleted", nullable = false)
    private boolean deleted = false;

    @Column(name = "CreatedAt")
    private LocalDateTime createdAt;

    @Column(name = "UpdatedAt")
    private LocalDateTime updatedAt;

    public int getServiceID() { return serviceID; }
    public void setServiceID(int serviceID) { this.serviceID = serviceID; }
    public int getCoSoID() { return coSoID; }
    public void setCoSoID(int coSoID) { this.coSoID = coSoID; }
    public String getServiceType() { return serviceType; }
    public void setServiceType(String serviceType) { this.serviceType = serviceType; }
    public String getServiceName() { return serviceName; }
    public void setServiceName(String serviceName) { this.serviceName = serviceName; }
    public String getSportType() { return sportType; }
    public void setSportType(String sportType) { this.sportType = sportType; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public double getBasePrice() { return basePrice; }
    public void setBasePrice(double basePrice) { this.basePrice = basePrice; }
    public String getUnit() { return unit; }
    public void setUnit(String unit) { this.unit = unit; }
    public int getEstimatedMinutes() { return estimatedMinutes; }
    public void setEstimatedMinutes(int estimatedMinutes) { this.estimatedMinutes = estimatedMinutes; }
    public Integer getMaxRequestsPerDay() { return maxRequestsPerDay; }
    public void setMaxRequestsPerDay(Integer maxRequestsPerDay) { this.maxRequestsPerDay = maxRequestsPerDay; }
    public LocalTime getReceiveTimeStart() { return receiveTimeStart; }
    public void setReceiveTimeStart(LocalTime receiveTimeStart) { this.receiveTimeStart = receiveTimeStart; }
    public LocalTime getReceiveTimeEnd() { return receiveTimeEnd; }
    public void setReceiveTimeEnd(LocalTime receiveTimeEnd) { this.receiveTimeEnd = receiveTimeEnd; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public boolean isAcceptingRequests() { return acceptingRequests; }
    public void setAcceptingRequests(boolean acceptingRequests) { this.acceptingRequests = acceptingRequests; }
    public String getPolicy() { return policy; }
    public void setPolicy(String policy) { this.policy = policy; }
    public String getCustomerNote() { return customerNote; }
    public void setCustomerNote(String customerNote) { this.customerNote = customerNote; }
    public boolean isDeleted() { return deleted; }
    public void setDeleted(boolean deleted) { this.deleted = deleted; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
