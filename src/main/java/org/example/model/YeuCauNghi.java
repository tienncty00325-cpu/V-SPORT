package org.example.model;

import java.time.LocalDate;
import java.time.LocalDateTime;
import jakarta.persistence.*;

@Entity
@Table(name = "YeuCauNghi")
public class YeuCauNghi {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "YeuCauNghiID")
    private int YeuCauNghiID;

    @Column(name = "AccountID")
    private int AccountID;

    @Column(name = "CoSoID")
    private int CoSoID;

    @Column(name = "NgayNghi")
    private LocalDate NgayNghi;

    @Column(name = "LoaiNghi")
    private String LoaiNghi;

    @Column(name = "LyDo")
    private String LyDo;

    @Column(name = "MucDoKhanCap")
    private Boolean MucDoKhanCap;

    @Column(name = "TrangThai")
    private String TrangThai;

    @Column(name = "GhiChuQuanLy")
    private String GhiChuQuanLy;

    @Column(name = "NgayXuLy")
    private LocalDateTime NgayXuLy;

    @Column(name = "XuLyBy")
    private Integer XuLyBy;

    @Column(name = "NgayGui")
    private LocalDateTime NgayGui;

    @Column(name = "CreatedAt")
    private LocalDateTime CreatedAt;

    @Column(name = "UpdatedAt")
    private LocalDateTime UpdatedAt;

    // Các trường tạm (không lưu DB) để hiển thị - mapping từ view
    @Column(name = "TenNhanVien", insertable = false, updatable = false)
    private String TenNhanVien;

    @Column(name = "TenCoSo", insertable = false, updatable = false)
    private String TenCoSo;

    @Column(name = "RoleName", insertable = false, updatable = false)
    private String RoleName;

    @Column(name = "QuanLyXuLy", insertable = false, updatable = false)
    private String QuanLyXuLy;

    @Column(name = "SoCaBiAnhHuong", insertable = false, updatable = false)
    private int SoCaBiAnhHuong;

    // Thêm trường username từ view (nếu có)
    @Column(name = "username", insertable = false, updatable = false)
    private String username;

    @Column(name = "IsDeleted")
    private Boolean isDeleted;

    @Column(name = "DeletedAt")
    private LocalDateTime deletedAt;

    @Column(name = "DeletedBy")
    private Integer deletedBy;

    // Constructors
    public YeuCauNghi() {}

    public YeuCauNghi(int AccountID, int CoSoID, LocalDate NgayNghi, String LoaiNghi, String LyDo) {
        this.AccountID = AccountID;
        this.CoSoID = CoSoID;
        this.NgayNghi = NgayNghi;
        this.LoaiNghi = LoaiNghi;
        this.LyDo = LyDo;
        this.TrangThai = "ChoDuyet";
    }

    // Getters and Setters
    public int getYeuCauNghiID() {
        return YeuCauNghiID;
    }

    public void setYeuCauNghiID(int YeuCauNghiID) {
        this.YeuCauNghiID = YeuCauNghiID;
    }

    public int getAccountID() {
        return AccountID;
    }

    public void setAccountID(int AccountID) {
        this.AccountID = AccountID;
    }

    public int getCoSoID() {
        return CoSoID;
    }

    public void setCoSoID(int CoSoID) {
        this.CoSoID = CoSoID;
    }

    public LocalDate getNgayNghi() {
        return NgayNghi;
    }

    public void setNgayNghi(LocalDate NgayNghi) {
        this.NgayNghi = NgayNghi;
    }

    public String getLoaiNghi() {
        return LoaiNghi;
    }

    public void setLoaiNghi(String LoaiNghi) {
        this.LoaiNghi = LoaiNghi;
    }

    public String getLyDo() {
        return LyDo;
    }

    public void setLyDo(String LyDo) {
        this.LyDo = LyDo;
    }

    public boolean isMucDoKhanCap() {
        return MucDoKhanCap != null && MucDoKhanCap;
    }

    public void setMucDoKhanCap(Boolean MucDoKhanCap) {
        this.MucDoKhanCap = MucDoKhanCap;
    }

    public String getTrangThai() {
        return TrangThai;
    }

    public void setTrangThai(String TrangThai) {
        this.TrangThai = TrangThai;
    }

    public String getGhiChuQuanLy() {
        return GhiChuQuanLy;
    }

    public void setGhiChuQuanLy(String GhiChuQuanLy) {
        this.GhiChuQuanLy = GhiChuQuanLy;
    }

    public LocalDateTime getNgayXuLy() {
        return NgayXuLy;
    }

    public void setNgayXuLy(LocalDateTime NgayXuLy) {
        this.NgayXuLy = NgayXuLy;
    }

    public Integer getXuLyBy() {
        return XuLyBy;
    }

    public void setXuLyBy(Integer XuLyBy) {
        this.XuLyBy = XuLyBy;
    }

    public LocalDateTime getNgayGui() {
        return NgayGui;
    }

    public void setNgayGui(LocalDateTime NgayGui) {
        this.NgayGui = NgayGui;
    }

    public LocalDateTime getCreatedAt() {
        return CreatedAt;
    }

    public void setCreatedAt(LocalDateTime CreatedAt) {
        this.CreatedAt = CreatedAt;
    }

    public LocalDateTime getUpdatedAt() {
        return UpdatedAt;
    }

    public void setUpdatedAt(LocalDateTime UpdatedAt) {
        this.UpdatedAt = UpdatedAt;
    }

    // Trường tạm để hiển thị
    public String getTenNhanVien() {
        return TenNhanVien;
    }

    public void setTenNhanVien(String TenNhanVien) {
        this.TenNhanVien = TenNhanVien;
    }

    public String getTenCoSo() {
        return TenCoSo;
    }

    public void setTenCoSo(String TenCoSo) {
        this.TenCoSo = TenCoSo;
    }

    public String getRoleName() {
        return RoleName;
    }

    public void setRoleName(String RoleName) {
        this.RoleName = RoleName;
    }

    public String getQuanLyXuLy() {
        return QuanLyXuLy;
    }

    public void setQuanLyXuLy(String QuanLyXuLy) {
        this.QuanLyXuLy = QuanLyXuLy;
    }

    public int getSoCaBiAnhHuong() {
        return SoCaBiAnhHuong;
    }

    public void setSoCaBiAnhHuong(int SoCaBiAnhHuong) {
        this.SoCaBiAnhHuong = SoCaBiAnhHuong;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public boolean isDeleted() { return isDeleted != null && isDeleted; }

    public void setDeleted(Boolean deleted) { isDeleted = deleted; }

    public LocalDateTime getDeletedAt() { return deletedAt; }

    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }

    public Integer getDeletedBy() { return deletedBy; }

    public void setDeletedBy(Integer deletedBy) { this.deletedBy = deletedBy; }

    // Helper methods
    public String getLoaiNghiDisplay() {
        switch (LoaiNghi) {
            case "FullDay":
                return "Cả ngày";
            case "HalfDay_Morning":
                return "Buổi sáng";
            case "HalfDay_Afternoon":
                return "Buổi chiều";
            default:
                return LoaiNghi;
        }
    }

    public String getTrangThaiDisplay() {
        switch (TrangThai) {
            case "ChoDuyet":
                return "Chờ duyệt";
            case "DaDuyet":
                return "Đã duyệt";
            case "TuChoi":
                return "Từ chối";
            case "DaHuy":
                return "Đã hủy";
            default:
                return TrangThai;
        }
    }

    public String getTrangThaiCSS() {
        switch (TrangThai) {
            case "ChoDuyet":
                return "bg-yellow-100 text-yellow-800";
            case "DaDuyet":
                return "bg-green-100 text-green-800";
            case "TuChoi":
                return "bg-red-100 text-red-800";
            case "DaHuy":
                return "bg-gray-100 text-gray-800";
            default:
                return "bg-blue-100 text-blue-800";
        }
    }

    public String getNgayNghiDisplay() {
        if (NgayNghi == null) return "";
        return NgayNghi.format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy"));
    }

    public String getNgayGuiDisplay() {
        if (NgayGui == null) return "";
        return NgayGui.format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
    }
}
