package org.example.dto;

public class TeamInvitationDTO {
    private int invitationId;
    private int teamId;
    private String teamName;
    private String teamAvatarPath;
    private int invitedByAccountId;
    private String invitedByName;
    private String proposedRole;
    private String status;
    private String message;
    private String createdAt;
    private String expiresAt;

    public int getInvitationId() { return invitationId; }
    public void setInvitationId(int invitationId) { this.invitationId = invitationId; }

    public int getTeamId() { return teamId; }
    public void setTeamId(int teamId) { this.teamId = teamId; }

    public String getTeamName() { return teamName; }
    public void setTeamName(String teamName) { this.teamName = teamName; }

    public String getTeamAvatarPath() { return teamAvatarPath; }
    public void setTeamAvatarPath(String teamAvatarPath) { this.teamAvatarPath = teamAvatarPath; }

    public int getInvitedByAccountId() { return invitedByAccountId; }
    public void setInvitedByAccountId(int invitedByAccountId) { this.invitedByAccountId = invitedByAccountId; }

    public String getInvitedByName() { return invitedByName; }
    public void setInvitedByName(String invitedByName) { this.invitedByName = invitedByName; }

    public String getProposedRole() { return proposedRole; }
    public void setProposedRole(String proposedRole) { this.proposedRole = proposedRole; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public String getExpiresAt() { return expiresAt; }
    public void setExpiresAt(String expiresAt) { this.expiresAt = expiresAt; }
}
