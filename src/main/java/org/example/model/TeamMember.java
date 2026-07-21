package org.example.model;

import java.time.LocalDateTime;

public class TeamMember {
    public static final String ROLE_CAPTAIN = "CAPTAIN";
    public static final String ROLE_CO_CAPTAIN = "CO_CAPTAIN";
    public static final String ROLE_MEMBER = "MEMBER";

    public static final String STATUS_ACTIVE = "ACTIVE";
    public static final String STATUS_LEFT = "LEFT";
    public static final String STATUS_REMOVED = "REMOVED";

    private int teamMemberId;
    private int teamId;
    private int accountId;
    private String memberRole;
    private String memberStatus;
    private LocalDateTime joinedAt;
    private LocalDateTime leftAt;
    private Integer addedBy;

    public TeamMember() {
    }

    public int getTeamMemberId() {
        return teamMemberId;
    }

    public void setTeamMemberId(int teamMemberId) {
        this.teamMemberId = teamMemberId;
    }

    public int getTeamId() {
        return teamId;
    }

    public void setTeamId(int teamId) {
        this.teamId = teamId;
    }

    public int getAccountId() {
        return accountId;
    }

    public void setAccountId(int accountId) {
        this.accountId = accountId;
    }

    public String getMemberRole() {
        return memberRole;
    }

    public void setMemberRole(String memberRole) {
        this.memberRole = memberRole;
    }

    public String getMemberStatus() {
        return memberStatus;
    }

    public void setMemberStatus(String memberStatus) {
        this.memberStatus = memberStatus;
    }

    public LocalDateTime getJoinedAt() {
        return joinedAt;
    }

    public void setJoinedAt(LocalDateTime joinedAt) {
        this.joinedAt = joinedAt;
    }

    public LocalDateTime getLeftAt() {
        return leftAt;
    }

    public void setLeftAt(LocalDateTime leftAt) {
        this.leftAt = leftAt;
    }

    public Integer getAddedBy() {
        return addedBy;
    }

    public void setAddedBy(Integer addedBy) {
        this.addedBy = addedBy;
    }
}
