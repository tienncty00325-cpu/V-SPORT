package org.example.dto;

/**
 * DTO tóm tắt một Team dùng cho danh sách (tab "Đội của bạn" và tab "Tham gia"
 * của /customer/doi-nhom). Gson serialize theo field — đổi tên field ở đây sẽ
 * đổi luôn JSON contract phía JS.
 */
public class TeamSummaryDTO {
    private int teamId;
    private String teamName;
    private String description;
    private int sportId;
    private String sportName;
    private String locationText;
    private String avatarPath;
    private int memberCount;
    private int maxMembers;
    private String status;
    private String myRole;              // null nếu user không phải thành viên (dùng ở tab "Tham gia")
    private boolean hasPendingJoinRequest; // true nếu user đã gửi yêu cầu tham gia và đang chờ duyệt

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

    public int getMemberCount() { return memberCount; }
    public void setMemberCount(int memberCount) { this.memberCount = memberCount; }

    public int getMaxMembers() { return maxMembers; }
    public void setMaxMembers(int maxMembers) { this.maxMembers = maxMembers; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getMyRole() { return myRole; }
    public void setMyRole(String myRole) { this.myRole = myRole; }

    public boolean isHasPendingJoinRequest() { return hasPendingJoinRequest; }
    public void setHasPendingJoinRequest(boolean hasPendingJoinRequest) { this.hasPendingJoinRequest = hasPendingJoinRequest; }
}
