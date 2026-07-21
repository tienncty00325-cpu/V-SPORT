package org.example.dto;

public class TeamJoinRequestDTO {
    private int joinRequestId;
    private int teamId;
    private int requesterAccountId;
    private String requesterName;
    private String requesterAvatarUrl;
    private String message;
    private String status;
    private String createdAt;

    public int getJoinRequestId() { return joinRequestId; }
    public void setJoinRequestId(int joinRequestId) { this.joinRequestId = joinRequestId; }

    public int getTeamId() { return teamId; }
    public void setTeamId(int teamId) { this.teamId = teamId; }

    public int getRequesterAccountId() { return requesterAccountId; }
    public void setRequesterAccountId(int requesterAccountId) { this.requesterAccountId = requesterAccountId; }

    public String getRequesterName() { return requesterName; }
    public void setRequesterName(String requesterName) { this.requesterName = requesterName; }

    public String getRequesterAvatarUrl() { return requesterAvatarUrl; }
    public void setRequesterAvatarUrl(String requesterAvatarUrl) { this.requesterAvatarUrl = requesterAvatarUrl; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
}
