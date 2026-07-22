package org.example.model;

import jakarta.persistence.*;

@Entity
@Table(name = "RacketStringingConfig")
public class RacketStringingConfig {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ConfigID")
    private int configID;

    @Column(name = "ServiceID", nullable = false)
    private int serviceID;

    @Column(name = "RacketTypes", length = 300)
    private String racketTypes;

    @Column(name = "StringingPrice", nullable = false)
    private double stringingPrice;

    @Column(name = "MinTension", nullable = false)
    private double minTension;

    @Column(name = "MaxTension", nullable = false)
    private double maxTension;

    @Column(name = "TensionUnit", nullable = false, length = 5)
    private String tensionUnit = "kg";

    @Column(name = "AllowCustomerString", nullable = false)
    private boolean allowCustomerString = true;

    @Column(name = "SellsString", nullable = false)
    private boolean sellsString = true;

    @Column(name = "AvgCompletionMinutes", nullable = false)
    private int avgCompletionMinutes = 60;

    @Column(name = "MaxRacketsPerOrder", nullable = false)
    private int maxRacketsPerOrder = 5;

    @Column(name = "OldRacketPolicy", length = 500)
    private String oldRacketPolicy;

    @Column(name = "StringBreakPolicy", length = 500)
    private String stringBreakPolicy;

    public int getConfigID() { return configID; }
    public void setConfigID(int configID) { this.configID = configID; }
    public int getServiceID() { return serviceID; }
    public void setServiceID(int serviceID) { this.serviceID = serviceID; }
    public String getRacketTypes() { return racketTypes; }
    public void setRacketTypes(String racketTypes) { this.racketTypes = racketTypes; }
    public double getStringingPrice() { return stringingPrice; }
    public void setStringingPrice(double stringingPrice) { this.stringingPrice = stringingPrice; }
    public double getMinTension() { return minTension; }
    public void setMinTension(double minTension) { this.minTension = minTension; }
    public double getMaxTension() { return maxTension; }
    public void setMaxTension(double maxTension) { this.maxTension = maxTension; }
    public String getTensionUnit() { return tensionUnit; }
    public void setTensionUnit(String tensionUnit) { this.tensionUnit = tensionUnit; }
    public boolean isAllowCustomerString() { return allowCustomerString; }
    public void setAllowCustomerString(boolean allowCustomerString) { this.allowCustomerString = allowCustomerString; }
    public boolean isSellsString() { return sellsString; }
    public void setSellsString(boolean sellsString) { this.sellsString = sellsString; }
    public int getAvgCompletionMinutes() { return avgCompletionMinutes; }
    public void setAvgCompletionMinutes(int avgCompletionMinutes) { this.avgCompletionMinutes = avgCompletionMinutes; }
    public int getMaxRacketsPerOrder() { return maxRacketsPerOrder; }
    public void setMaxRacketsPerOrder(int maxRacketsPerOrder) { this.maxRacketsPerOrder = maxRacketsPerOrder; }
    public String getOldRacketPolicy() { return oldRacketPolicy; }
    public void setOldRacketPolicy(String oldRacketPolicy) { this.oldRacketPolicy = oldRacketPolicy; }
    public String getStringBreakPolicy() { return stringBreakPolicy; }
    public void setStringBreakPolicy(String stringBreakPolicy) { this.stringBreakPolicy = stringBreakPolicy; }
}
