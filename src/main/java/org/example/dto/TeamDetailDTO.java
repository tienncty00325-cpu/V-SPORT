package org.example.dto;

import java.util.List;

/**
 * DTO chi tiết một Team dùng cho /customer/doi-nhom/chi-tiet. Gson serialize
 * theo field — đổi tên field ở đây sẽ đổi luôn JSON contract phía JS.
 */
public class TeamDetailDTO {
    private int teamId;
    private String teamName;
    private String description;
    private int sportId;
    private String sportName;
    private String locationText;
    private String avatarPath;
    private String coverImagePath;
    private int maxMembers;
    private int memberCount;
    private String status;
    private int captainAccountId;
    private String captainName;
    private String createdAt; // ISO string, format ở DAO để tránh phụ thuộc Gson adapter phía JSP thường

    // Góc nhìn của user hiện tại đang xem trang (null nếu không phải thành viên)
    private String myRole;
    private boolean isCaptain;
    private boolean isCoCaptain;

    private List<TeamMemberDTO> members;

    public int getTeamId() { return teamId; }
    public void setTeamId(int teamId) { this.teamId = teamId; }

    public String getTeamName() { return teamName; }
    public void setTeamName(String teamName) { this.teamName = teamName; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public int getSportId() { return sportId; }
    public void setSportId(int sportId) { this.sportId = sportId; }

    public String getSportName() { return sportName; }
    public void setSportName(String sportName) { this.sportName = sportName; }

    public String getLocationText() { return locationText; }
    public void setLocationText(String locationText) { this.locationText = locationText; }

    public String getAvatarPath() { return avatarPath; }
    public void setAvatarPath(String avatarPath) { this.avatarPath = avatarPath; }

    public String getCoverImagePath() { return coverImagePath; }
    public void setCoverImagePath(String coverImagePath) { this.coverImagePath = coverImagePath; }

    public int getMaxMembers() { return maxMembers; }
    public void setMaxMembers(int maxMembers) { this.maxMembers = maxMembers; }

    public int getMemberCount() { return memberCount; }
    public void setMemberCount(int memberCount) { this.memberCount = memberCount; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public int getCaptainAccountId() { return captainAccountId; }
    public void setCaptainAccountId(int captainAccountId) { this.captainAccountId = captainAccountId; }

    public String getCaptainName() { return captainName; }
    public void setCaptainName(String captainName) { this.captainName = captainName; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public String getMyRole() { return myRole; }
    public void setMyRole(String myRole) { this.myRole = myRole; }

    public boolean isCaptain() { return isCaptain; }
    public void setCaptain(boolean captain) { isCaptain = captain; }

    public boolean isCoCaptain() { return isCoCaptain; }
    public void setCoCaptain(boolean coCaptain) { isCoCaptain = coCaptain; }

    public List<TeamMemberDTO> getMembers() { return members; }
    public void setMembers(List<TeamMemberDTO> members) { this.members = members; }
}
