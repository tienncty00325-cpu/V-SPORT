package org.example.dto;

/** Một lượt thách đấu (ChiTietGhepKeo gắn TeamIDNguoiThamGia) cho một kèo đội. */
public class TeamChallengeDTO {
    private int chiTietKeoId;
    private int keoId;
    private int challengerTeamId;
    private String challengerTeamName;
    private String challengerTeamAvatarPath;
    private String status;

    public int getChiTietKeoId() { return chiTietKeoId; }
    public void setChiTietKeoId(int chiTietKeoId) { this.chiTietKeoId = chiTietKeoId; }

    public int getKeoId() { return keoId; }
    public void setKeoId(int keoId) { this.keoId = keoId; }

    public int getChallengerTeamId() { return challengerTeamId; }
    public void setChallengerTeamId(int challengerTeamId) { this.challengerTeamId = challengerTeamId; }

    public String getChallengerTeamName() { return challengerTeamName; }
    public void setChallengerTeamName(String challengerTeamName) { this.challengerTeamName = challengerTeamName; }

    public String getChallengerTeamAvatarPath() { return challengerTeamAvatarPath; }
    public void setChallengerTeamAvatarPath(String challengerTeamAvatarPath) { this.challengerTeamAvatarPath = challengerTeamAvatarPath; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
