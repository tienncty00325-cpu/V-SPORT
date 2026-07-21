package org.example.dto;

import java.util.List;

/**
 * DTO cho GET /api/customer/facilities/map — dữ liệu cơ sở tối thiểu để render
 * marker trên bản đồ Customer. Field name khớp trực tiếp key JSON (Gson serialize
 * theo field, không qua getter) — đổi tên field ở đây sẽ đổi luôn JSON contract.
 *
 * Giữ song song alias "latitude"/"longitude"/"address"/"openNow" (đã được
 * BanDo.jsp tiêu thụ từ trước) bên cạnh field mới "viDo"/"kinhDo"/"diaChi"/
 * "moCuaHienTai" theo contract mới — không phá giao diện bản đồ hiện có.
 */
public class FacilityMapDTO {
    private int coSoId;
    private String tenCoSo;
    private String diaChi;
    private String soDienThoai;
    private double viDo;
    private double kinhDo;
    private String gioMoCua;
    private String gioDongCua;
    private String trangThai;
    private String hinhAnh;
    private boolean moCuaHienTai;
    private Double distanceKm;
    private List<String> sports;

    // Alias giữ tương thích ngược cho BanDo.jsp (fac.latitude/longitude/address/openNow).
    private double latitude;
    private double longitude;
    private String address;
    private boolean openNow;
    private double minPrice;
    private int readyCourtCount;

    public int getCoSoId() { return coSoId; }
    public void setCoSoId(int coSoId) { this.coSoId = coSoId; }

    public String getTenCoSo() { return tenCoSo; }
    public void setTenCoSo(String tenCoSo) { this.tenCoSo = tenCoSo; }

    public String getDiaChi() { return diaChi; }
    public void setDiaChi(String diaChi) {
        this.diaChi = diaChi;
        this.address = diaChi;
    }

    public String getSoDienThoai() { return soDienThoai; }
    public void setSoDienThoai(String soDienThoai) { this.soDienThoai = soDienThoai; }

    public double getViDo() { return viDo; }
    public void setViDo(double viDo) {
        this.viDo = viDo;
        this.latitude = viDo;
    }

    public double getKinhDo() { return kinhDo; }
    public void setKinhDo(double kinhDo) {
        this.kinhDo = kinhDo;
        this.longitude = kinhDo;
    }

    public String getGioMoCua() { return gioMoCua; }
    public void setGioMoCua(String gioMoCua) { this.gioMoCua = gioMoCua; }

    public String getGioDongCua() { return gioDongCua; }
    public void setGioDongCua(String gioDongCua) { this.gioDongCua = gioDongCua; }

    public String getTrangThai() { return trangThai; }
    public void setTrangThai(String trangThai) { this.trangThai = trangThai; }

    public String getHinhAnh() { return hinhAnh; }
    public void setHinhAnh(String hinhAnh) { this.hinhAnh = hinhAnh; }

    public boolean isMoCuaHienTai() { return moCuaHienTai; }
    public void setMoCuaHienTai(boolean moCuaHienTai) {
        this.moCuaHienTai = moCuaHienTai;
        this.openNow = moCuaHienTai;
    }

    public Double getDistanceKm() { return distanceKm; }
    public void setDistanceKm(Double distanceKm) { this.distanceKm = distanceKm; }

    public List<String> getSports() { return sports; }
    public void setSports(List<String> sports) { this.sports = sports; }

    public double getMinPrice() { return minPrice; }
    public void setMinPrice(double minPrice) { this.minPrice = minPrice; }

    public int getReadyCourtCount() { return readyCourtCount; }
    public void setReadyCourtCount(int readyCourtCount) { this.readyCourtCount = readyCourtCount; }
}
