package org.example.dto;

public class TeamMemberDTO {
    private int teamMemberId;
    private int accountId;
    private String fullName;
    private String avatarUrl;
    private String memberRole;
    private String memberStatus;
    private String joinedAt;

    public int getTeamMemberId() { return teamMemberId; }
    public void setTeamMemberId(int teamMemberId) { this.teamMemberId = teamMemberId; }

    public int getAccountId() { return accountId; }
    public void setAccountId(int accountId) { this.accountId = accountId; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }

    public String getMemberRole() { return memberRole; }
    public void setMemberRole(String memberRole) { this.memberRole = memberRole; }

    public String getMemberStatus() { return memberStatus; }
    public void setMemberStatus(String memberStatus) { this.memberStatus = memberStatus; }

    public String getJoinedAt() { return joinedAt; }
    public void setJoinedAt(String joinedAt) { this.joinedAt = joinedAt; }
}
