package org.example.model;

import jakarta.persistence.*;

@Entity
@Table(name = "RacketStringingOrderDetail")
public class RacketStringingOrderDetail {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "DetailID")
    private int detailID;

    @Column(name = "OrderID", nullable = false)
    private int orderID;

    @Column(name = "RacketType", length = 50)
    private String racketType;

    @Column(name = "RacketBrand", length = 100)
    private String racketBrand;

    @Column(name = "RacketModel", length = 100)
    private String racketModel;

    @Column(name = "MaterialID")
    private Integer materialID;

    @Column(name = "CustomerBringsString", nullable = false)
    private boolean customerBringsString = false;

    @Column(name = "TensionValue", nullable = false)
    private double tensionValue;

    @Column(name = "TensionUnit", nullable = false, length = 5)
    private String tensionUnit = "kg";

    @Column(name = "StringColor", length = 50)
    private String stringColor;

    @Column(name = "Quantity", nullable = false)
    private int quantity = 1;

    @Column(name = "TechnicalNote", length = 500)
    private String technicalNote;

    public int getDetailID() { return detailID; }
    public void setDetailID(int detailID) { this.detailID = detailID; }
    public int getOrderID() { return orderID; }
    public void setOrderID(int orderID) { this.orderID = orderID; }
    public String getRacketType() { return racketType; }
    public void setRacketType(String racketType) { this.racketType = racketType; }
    public String getRacketBrand() { return racketBrand; }
    public void setRacketBrand(String racketBrand) { this.racketBrand = racketBrand; }
    public String getRacketModel() { return racketModel; }
    public void setRacketModel(String racketModel) { this.racketModel = racketModel; }
    public Integer getMaterialID() { return materialID; }
    public void setMaterialID(Integer materialID) { this.materialID = materialID; }
    public boolean isCustomerBringsString() { return customerBringsString; }
    public void setCustomerBringsString(boolean customerBringsString) { this.customerBringsString = customerBringsString; }
    public double getTensionValue() { return tensionValue; }
    public void setTensionValue(double tensionValue) { this.tensionValue = tensionValue; }
    public String getTensionUnit() { return tensionUnit; }
    public void setTensionUnit(String tensionUnit) { this.tensionUnit = tensionUnit; }
    public String getStringColor() { return stringColor; }
    public void setStringColor(String stringColor) { this.stringColor = stringColor; }
    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    public String getTechnicalNote() { return technicalNote; }
    public void setTechnicalNote(String technicalNote) { this.technicalNote = technicalNote; }
}
