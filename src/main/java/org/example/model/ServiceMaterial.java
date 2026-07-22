package org.example.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "ServiceMaterial")
public class ServiceMaterial {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaterialID")
    private int materialID;

    @Column(name = "CoSoID", nullable = false)
    private int coSoID;

    @Column(name = "Name", nullable = false, length = 150)
    private String name;

    @Column(name = "Brand", length = 100)
    private String brand;

    @Column(name = "Code", length = 50)
    private String code;

    @Column(name = "Color", length = 50)
    private String color;

    @Column(name = "SportType", length = 50)
    private String sportType;

    @Column(name = "Price", nullable = false)
    private double price;

    @Column(name = "ExtraFee", nullable = false)
    private double extraFee;

    @Column(name = "Status", nullable = false, length = 20)
    private String status = "DANG_CO";

    @Column(name = "Description", length = 500)
    private String description;

    @Column(name = "IsDeleted", nullable = false)
    private boolean deleted = false;

    @Column(name = "CreatedAt")
    private LocalDateTime createdAt;

    @Column(name = "UpdatedAt")
    private LocalDateTime updatedAt;

    public int getMaterialID() { return materialID; }
    public void setMaterialID(int materialID) { this.materialID = materialID; }
    public int getCoSoID() { return coSoID; }
    public void setCoSoID(int coSoID) { this.coSoID = coSoID; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getBrand() { return brand; }
    public void setBrand(String brand) { this.brand = brand; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public String getColor() { return color; }
    public void setColor(String color) { this.color = color; }
    public String getSportType() { return sportType; }
    public void setSportType(String sportType) { this.sportType = sportType; }
    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }
    public double getExtraFee() { return extraFee; }
    public void setExtraFee(double extraFee) { this.extraFee = extraFee; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public boolean isDeleted() { return deleted; }
    public void setDeleted(boolean deleted) { this.deleted = deleted; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
