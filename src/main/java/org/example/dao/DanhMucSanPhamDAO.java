package org.example.dao;

import org.example.model.DanhMucSanPham;
import java.util.List;

public interface DanhMucSanPhamDAO {
    List<DanhMucSanPham> findAll();
    DanhMucSanPham findById(int id);
    boolean insert(DanhMucSanPham category);
    boolean update(DanhMucSanPham category);
    boolean delete(int id);
}
