package org.example.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "San")
public class San {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "SanID")
    private int sanID;

    @Column(name = "TenSan")
    private String tenSan;

    @Column(name = "LoaiSanID")
    private int loaiSanID;

    @Column(name = "CoSoID")
    private int coSoID;

    @Column(name = "TrangThai")
    private String trangThai;

    @Column(name = "MoTa")
    private String moTa;

    @Column(name = "HinhAnh")
    private String hinhAnh;

    @Column(name = "IsDeleted")
    private Boolean isDeleted;

    @Column(name = "DeletedAt")
    private LocalDateTime deletedAt;

    @Column(name = "DeletedBy")
    private Integer deletedBy;

    @Transient
    private String tenLoaiSan;
    @Transient
    private double giaKhongDen;
    @Transient
    private double giaCoDen;
    @Transient
    private java.time.LocalTime gioBatDauLenDen;
    @Transient
    private java.time.LocalTime gioKetThucLenDen;
    @Transient
    private Integer datSanIdActive;
    @Transient
    private String gioBatDauActive;
    @Transient
    private String gioKetThucActive;
    @Transient
    private String ghiChuActive;
    // Ca đang chơi (nếu có) - thời điểm ISO đầy đủ để frontend không phải tự ghép ngày+giờ,
    // và thông tin khách để hiển thị ngay trên card (không phải kéo xuống danh sách bên dưới mới biết).
    @Transient
    private LocalDateTime scheduledEndActive;
    @Transient
    private LocalDateTime actualStartActive;
    @Transient
    private String nguonDatSanActive;
    @Transient
    private String tenKhachHangActive;
    @Transient
    private String soDienThoaiActive;
    // Booking "Đã xác nhận" gần nhất sắp tới (chưa check-in) trong ngưỡng cảnh báo - lý do
    // chính xác vì sao card không được coi là AVAILABLE dù San.TrangThai = 'Sẵn sàng'.
    @Transient
    private Integer nextDatSanId;
    @Transient
    private String nextTenKhachHang;
    @Transient
    private String nextSoDienThoai;
    @Transient
    private String nextNguonDatSan;
    @Transient
    private LocalDateTime nextGioBatDau;
    @Transient
    private LocalDateTime nextGioKetThuc;


    public San(int sanID, String tenSan, int loaiSanID, int coSoID, String trangThai, String moTa, String hinhAnh) {
        this.sanID = sanID;
        this.tenSan = tenSan;
        this.loaiSanID = loaiSanID;
        this.coSoID = coSoID;
        this.trangThai = trangThai;
        this.moTa = moTa;
        this.hinhAnh = hinhAnh;
    }

    public San() {
    }

    public int getSanID() {
        return sanID;
    }

    public void setSanID(int sanID) {
        this.sanID = sanID;
    }

    public String getTenSan() {
        return tenSan;
    }

    public void setTenSan(String tenSan) {
        this.tenSan = tenSan;
    }

    public int getLoaiSanID() {
        return loaiSanID;
    }

    public void setLoaiSanID(int loaiSanID) {
        this.loaiSanID = loaiSanID;
    }

    public int getCoSoID() {
        return coSoID;
    }

    public void setCoSoID(int coSoID) {
        this.coSoID = coSoID;
    }

    public String getTrangThai() {
        return trangThai;
    }

    public void setTrangThai(String trangThai) {
        this.trangThai = trangThai;
    }

    public String getMoTa() {
        return moTa;
    }

    public void setMoTa(String moTa) {
        this.moTa = moTa;
    }

    public String getHinhAnh() {
        return hinhAnh;
    }

    public void setHinhAnh(String hinhAnh) {
        this.hinhAnh = hinhAnh;
    }

    public boolean isDeleted() { return isDeleted != null && isDeleted; }

    public void setDeleted(Boolean deleted) { isDeleted = deleted; }

    public LocalDateTime getDeletedAt() { return deletedAt; }

    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }

    public Integer getDeletedBy() { return deletedBy; }

    public void setDeletedBy(Integer deletedBy) { this.deletedBy = deletedBy; }

    public String getTenLoaiSan() { return tenLoaiSan; }
    public void setTenLoaiSan(String tenLoaiSan) { this.tenLoaiSan = tenLoaiSan; }

    public double getGiaKhongDen() { return giaKhongDen; }
    public void setGiaKhongDen(double giaKhongDen) { this.giaKhongDen = giaKhongDen; }

    public double getGiaCoDen() { return giaCoDen; }
    public void setGiaCoDen(double giaCoDen) { this.giaCoDen = giaCoDen; }

    public java.time.LocalTime getGioBatDauLenDen() { return gioBatDauLenDen; }
    public void setGioBatDauLenDen(java.time.LocalTime gioBatDauLenDen) { this.gioBatDauLenDen = gioBatDauLenDen; }

    public java.time.LocalTime getGioKetThucLenDen() { return gioKetThucLenDen; }
    public void setGioKetThucLenDen(java.time.LocalTime gioKetThucLenDen) { this.gioKetThucLenDen = gioKetThucLenDen; }

    public Integer getDatSanIdActive() { return datSanIdActive; }
    public void setDatSanIdActive(Integer datSanIdActive) { this.datSanIdActive = datSanIdActive; }

    public String getGioBatDauActive() { return gioBatDauActive; }
    public void setGioBatDauActive(String gioBatDauActive) { this.gioBatDauActive = gioBatDauActive; }

    public String getGioKetThucActive() { return gioKetThucActive; }
    public void setGioKetThucActive(String gioKetThucActive) { this.gioKetThucActive = gioKetThucActive; }

    public String getGhiChuActive() { return ghiChuActive; }
    public void setGhiChuActive(String ghiChuActive) { this.ghiChuActive = ghiChuActive; }

    public LocalDateTime getScheduledEndActive() { return scheduledEndActive; }
    public void setScheduledEndActive(LocalDateTime scheduledEndActive) { this.scheduledEndActive = scheduledEndActive; }

    public LocalDateTime getActualStartActive() { return actualStartActive; }
    public void setActualStartActive(LocalDateTime actualStartActive) { this.actualStartActive = actualStartActive; }

    public String getNguonDatSanActive() { return nguonDatSanActive; }
    public void setNguonDatSanActive(String nguonDatSanActive) { this.nguonDatSanActive = nguonDatSanActive; }

    public String getTenKhachHangActive() { return tenKhachHangActive; }
    public void setTenKhachHangActive(String tenKhachHangActive) { this.tenKhachHangActive = tenKhachHangActive; }

    public String getSoDienThoaiActive() { return soDienThoaiActive; }
    public void setSoDienThoaiActive(String soDienThoaiActive) { this.soDienThoaiActive = soDienThoaiActive; }

    public Integer getNextDatSanId() { return nextDatSanId; }
    public void setNextDatSanId(Integer nextDatSanId) { this.nextDatSanId = nextDatSanId; }

    public String getNextTenKhachHang() { return nextTenKhachHang; }
    public void setNextTenKhachHang(String nextTenKhachHang) { this.nextTenKhachHang = nextTenKhachHang; }

    public String getNextSoDienThoai() { return nextSoDienThoai; }
    public void setNextSoDienThoai(String nextSoDienThoai) { this.nextSoDienThoai = nextSoDienThoai; }

    public String getNextNguonDatSan() { return nextNguonDatSan; }
    public void setNextNguonDatSan(String nextNguonDatSan) { this.nextNguonDatSan = nextNguonDatSan; }

    public LocalDateTime getNextGioBatDau() { return nextGioBatDau; }
    public void setNextGioBatDau(LocalDateTime nextGioBatDau) { this.nextGioBatDau = nextGioBatDau; }

    public LocalDateTime getNextGioKetThuc() { return nextGioKetThuc; }
    public void setNextGioKetThuc(LocalDateTime nextGioKetThuc) { this.nextGioKetThuc = nextGioKetThuc; }

    public boolean isHasUpcomingBooking() { return nextDatSanId != null; }


    @Override
    public String toString() {
        return "San{" +
                "sanID=" + sanID +
                ", tenSan='" + tenSan + '\'' +
                ", loaiSanID=" + loaiSanID +
                ", coSoID=" + coSoID +
                ", trangThai='" + trangThai + '\'' +
                ", moTa='" + moTa + '\'' +
                ", hinhAnh='" + hinhAnh + '\'' +
                '}';
    }
}
