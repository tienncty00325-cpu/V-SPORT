package org.example.dto;

/**
 * DTO cho một kèo (GhepKeo) được tạo dưới danh nghĩa đội — dùng ở khu vực
 * "Tạo kèo đội" / "Thách đấu" trong /customer/doi-nhom/chi-tiet. Bọc quanh
 * domain GhepKeo hiện có (KeoID, DatSanID, TrangThai...) và bổ sung góc nhìn
 * đội (TeamIDNguoiTao/TeamIDNguoiThamGia mới thêm — xem migration_team_management.sql).
 */
public class TeamMatchSummaryDTO {
    private int keoId;
    private int teamIdNguoiTao;
    private String teamNameNguoiTao;
    private int datSanId;
    private String ngayDat;
    private String gioBatDau;
    private String gioKetThuc;
    private String tenSan;
    private String tenCoSo;
    private String diaChi;
    private Integer monTheThaoId;
    private String tenMon;
    private String trinhDo;
    private String trangThai;
    private String note;
    private Integer opponentTeamId;
    private String opponentTeamName;
    private int pendingChallengeCount;

    public int getKeoId() { return keoId; }
    public void setKeoId(int keoId) { this.keoId = keoId; }

    public int getTeamIdNguoiTao() { return teamIdNguoiTao; }
    public void setTeamIdNguoiTao(int teamIdNguoiTao) { this.teamIdNguoiTao = teamIdNguoiTao; }

    public String getTeamNameNguoiTao() { return teamNameNguoiTao; }
    public void setTeamNameNguoiTao(String teamNameNguoiTao) { this.teamNameNguoiTao = teamNameNguoiTao; }

    public int getDatSanId() { return datSanId; }
    public void setDatSanId(int datSanId) { this.datSanId = datSanId; }

    public String getNgayDat() { return ngayDat; }
    public void setNgayDat(String ngayDat) { this.ngayDat = ngayDat; }

    public String getGioBatDau() { return gioBatDau; }
    public void setGioBatDau(String gioBatDau) { this.gioBatDau = gioBatDau; }

    public String getGioKetThuc() { return gioKetThuc; }
    public void setGioKetThuc(String gioKetThuc) { this.gioKetThuc = gioKetThuc; }

    public String getTenSan() { return tenSan; }
    public void setTenSan(String tenSan) { this.tenSan = tenSan; }

    public String getTenCoSo() { return tenCoSo; }
    public void setTenCoSo(String tenCoSo) { this.tenCoSo = tenCoSo; }

    public String getDiaChi() { return diaChi; }
    public void setDiaChi(String diaChi) { this.diaChi = diaChi; }

    public Integer getMonTheThaoId() { return monTheThaoId; }
    public void setMonTheThaoId(Integer monTheThaoId) { this.monTheThaoId = monTheThaoId; }

    public String getTenMon() { return tenMon; }
    public void setTenMon(String tenMon) { this.tenMon = tenMon; }

    public String getTrinhDo() { return trinhDo; }
    public void setTrinhDo(String trinhDo) { this.trinhDo = trinhDo; }

    public String getTrangThai() { return trangThai; }
    public void setTrangThai(String trangThai) { this.trangThai = trangThai; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public Integer getOpponentTeamId() { return opponentTeamId; }
    public void setOpponentTeamId(Integer opponentTeamId) { this.opponentTeamId = opponentTeamId; }

    public String getOpponentTeamName() { return opponentTeamName; }
    public void setOpponentTeamName(String opponentTeamName) { this.opponentTeamName = opponentTeamName; }

    public int getPendingChallengeCount() { return pendingChallengeCount; }
    public void setPendingChallengeCount(int pendingChallengeCount) { this.pendingChallengeCount = pendingChallengeCount; }
}
