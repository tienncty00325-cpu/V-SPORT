package org.example.model;

import java.time.LocalDateTime;

public class TeamInvitation {
    public static final String STATUS_PENDING = "PENDING";
    public static final String STATUS_ACCEPTED = "ACCEPTED";
    public static final String STATUS_REJECTED = "REJECTED";
    public static final String STATUS_CANCELLED = "CANCELLED";
    public static final String STATUS_EXPIRED = "EXPIRED";

    private int invitationId;
    private int teamId;
    private int invitedAccountId;
    private int invitedByAccountId;
    private String proposedRole;
    private String status;
    private String message;
    private LocalDateTime createdAt;
    private LocalDateTime expiresAt;
    private LocalDateTime respondedAt;

    public TeamInvitation() {
    }

    public int getInvitationId() {
        return invitationId;
    }

    public void setInvitationId(int invitationId) {
        this.invitationId = invitationId;
    }

    public int getTeamId() {
        return teamId;
    }

    public void setTeamId(int teamId) {
        this.teamId = teamId;
    }

    public int getInvitedAccountId() {
        return invitedAccountId;
    }

    public void setInvitedAccountId(int invitedAccountId) {
        this.invitedAccountId = invitedAccountId;
    }

    public int getInvitedByAccountId() {
        return invitedByAccountId;
    }

    public void setInvitedByAccountId(int invitedByAccountId) {
        this.invitedByAccountId = invitedByAccountId;
    }

    public String getProposedRole() {
        return proposedRole;
    }

    public void setProposedRole(String proposedRole) {
        this.proposedRole = proposedRole;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(LocalDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }

    public LocalDateTime getRespondedAt() {
        return respondedAt;
    }

    public void setRespondedAt(LocalDateTime respondedAt) {
        this.respondedAt = respondedAt;
    }
}
