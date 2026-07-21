package org.example.dto;

public class CustomerProfileExtraDTO {
    private String coverImageUrl;
    private Integer heightCm;
    private Integer weightKg;
    private String specialNote;
    private String preferredLocation;
    private Integer favoriteSportId;
    private String favoriteSportName;
    private String skillLevel;
    private String goal;
    private String playFrequency;

    public String getCoverImageUrl() { return coverImageUrl; }
    public void setCoverImageUrl(String coverImageUrl) { this.coverImageUrl = coverImageUrl; }

    public Integer getHeightCm() { return heightCm; }
    public void setHeightCm(Integer heightCm) { this.heightCm = heightCm; }

    public Integer getWeightKg() { return weightKg; }
    public void setWeightKg(Integer weightKg) { this.weightKg = weightKg; }

    public String getSpecialNote() { return specialNote; }
    public void setSpecialNote(String specialNote) { this.specialNote = specialNote; }

    public String getPreferredLocation() { return preferredLocation; }
    public void setPreferredLocation(String preferredLocation) { this.preferredLocation = preferredLocation; }

    public Integer getFavoriteSportId() { return favoriteSportId; }
    public void setFavoriteSportId(Integer favoriteSportId) { this.favoriteSportId = favoriteSportId; }

    public String getFavoriteSportName() { return favoriteSportName; }
    public void setFavoriteSportName(String favoriteSportName) { this.favoriteSportName = favoriteSportName; }

    public String getSkillLevel() { return skillLevel; }
    public void setSkillLevel(String skillLevel) { this.skillLevel = skillLevel; }

    public String getGoal() { return goal; }
    public void setGoal(String goal) { this.goal = goal; }

    public String getPlayFrequency() { return playFrequency; }
    public void setPlayFrequency(String playFrequency) { this.playFrequency = playFrequency; }
}
