package org.example.model;

import java.time.LocalDateTime;

public class TeamJoinRequest {
    public static final String STATUS_PENDING = "PENDING";
    public static final String STATUS_APPROVED = "APPROVED";
    public static final String STATUS_REJECTED = "REJECTED";
    public static final String STATUS_CANCELLED = "CANCELLED";

    private int joinRequestId;
    private int teamId;
    private int requesterAccountId;
    private String message;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime reviewedAt;
    private Integer reviewedByAccountId;

    public TeamJoinRequest() {
    }

    public int getJoinRequestId() {
        return joinRequestId;
    }

    public void setJoinRequestId(int joinRequestId) {
        this.joinRequestId = joinRequestId;
    }

    public int getTeamId() {
        return teamId;
    }

    public void setTeamId(int teamId) {
        this.teamId = teamId;
    }

    public int getRequesterAccountId() {
        return requesterAccountId;
    }

    public void setRequesterAccountId(int requesterAccountId) {
        this.requesterAccountId = requesterAccountId;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getReviewedAt() {
        return reviewedAt;
    }

    public void setReviewedAt(LocalDateTime reviewedAt) {
        this.reviewedAt = reviewedAt;
    }

    public Integer getReviewedByAccountId() {
        return reviewedByAccountId;
    }

    public void setReviewedByAccountId(Integer reviewedByAccountId) {
        this.reviewedByAccountId = reviewedByAccountId;
    }
}
