package org.example.controller.manager;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.example.dao.DanhMucSanPhamDAO;
import org.example.dao.SanPhamDichVuDAO;
import org.example.dao.impl.DanhMucSanPhamDAOImpl;
import org.example.dao.impl.SanPhamDichVuDAOImpl;
import org.example.model.DanhMucSanPham;
import org.example.model.SanPham_DichVu;
import org.example.model.TaiKhoan;
import org.example.util.Constants;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityTransaction;
import org.example.util.JPAUtil;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.example.service.AuditLogService;
import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

@WebServlet("/manager/kho-dich-vu")
public class KhoDichVuManagerServlet extends HttpServlet {

    private static final Logger logger = LogManager.getLogger(KhoDichVuManagerServlet.class);
    private static final Object categoryLock = new Object();
    private static volatile boolean categoryCleaned = false;
    private final SanPhamDichVuDAO sanPhamDAO = new SanPhamDichVuDAOImpl();
    private final DanhMucSanPhamDAO categoryDAO = new DanhMucSanPhamDAOImpl();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");

        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        if (user.getRoleId() != Constants.ROLE_MANAGER) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền truy cập chức năng này.");
            return;
        }

        int coSoId = user.getCoSoId();

        if (!categoryCleaned) {
            synchronized (categoryLock) {
                if (!categoryCleaned) {
                    List<DanhMucSanPham> cats = categoryDAO.findAll();
                    if (cats.isEmpty()) {
                        categoryDAO.insert(new DanhMucSanPham(0, "Nước uống"));
                        categoryDAO.insert(new DanhMucSanPham(0, "Đồ ăn nhanh"));
                        categoryDAO.insert(new DanhMucSanPham(0, "Thuê dụng cụ"));
                        categoryDAO.insert(new DanhMucSanPham(0, "Phụ kiện thể thao"));
                        cats = categoryDAO.findAll();
                    }

                    java.util.Map<String, DanhMucSanPham> uniqueCats = new java.util.HashMap<>();
                    for (DanhMucSanPham cat : cats) {
                        String name = cat.getTenDanhMuc().trim().toLowerCase();
                        if (uniqueCats.containsKey(name)) {
                            DanhMucSanPham primaryCat = uniqueCats.get(name);
                            
                            jakarta.persistence.EntityManager em = org.example.util.JPAUtil.getEntityManager();
                            jakarta.persistence.EntityTransaction trans = em.getTransaction();
                            try {
                                trans.begin();
                                
                                List<SanPham_DichVu> products = em.createQuery(
                                    "SELECT p FROM SanPham_DichVu p WHERE p.DanhMucID = :oldCatId", SanPham_DichVu.class)
                                    .setParameter("oldCatId", cat.getDanhMucID())
                                    .getResultList();
                                for (SanPham_DichVu sp : products) {
                                    sp.setDanhMucID(primaryCat.getDanhMucID());
                                    em.merge(sp);
                                }
                                
                                DanhMucSanPham catToRemove = em.find(DanhMucSanPham.class, cat.getDanhMucID());
                                if (catToRemove != null) {
                                    em.remove(catToRemove);
                                }
                                
                                trans.commit();
                            } catch (Exception e) {
                                if (trans.isActive()) trans.rollback();
                                e.printStackTrace();
                            } finally {
                                em.close();
                            }
                        } else {
                            uniqueCats.put(name, cat);
                        }
                    }
                    categoryCleaned = true;
                }
            }
        }

        List<DanhMucSanPham> categories = categoryDAO.findAll();

        // Get filter inputs
        String search = req.getParameter("search");
        String categoryIdStr = req.getParameter("category");
        String status = req.getParameter("status");

        List<SanPham_DichVu> list = sanPhamDAO.findByCoSo(coSoId);

        // Apply filters in memory for flexibility (search name or SKU)
        if (search != null && !search.trim().isEmpty()) {
            String q = search.trim().toLowerCase();
            list = list.stream()
                    .filter(s -> (s.getTenSanPham() != null && s.getTenSanPham().toLowerCase().contains(q)) ||
                                 (s.getSkuCode() != null && s.getSkuCode().toLowerCase().contains(q)))
                    .collect(Collectors.toList());
        }

        if (categoryIdStr != null && !categoryIdStr.trim().isEmpty()) {
            try {
                int catId = Integer.parseInt(categoryIdStr.trim());
                list = list.stream()
                        .filter(s -> s.getDanhMucID() == catId)
                        .collect(Collectors.toList());
            } catch (NumberFormatException ignored) {}
        }

        if (status != null && !status.trim().isEmpty()) {
            list = list.stream()
                    .filter(s -> status.trim().equals(s.getTrangThai()))
                    .collect(Collectors.toList());
        }

        // Calculate KPI values
        long totalItems = list.size();
        double totalInventoryValue = list.stream()
                .mapToDouble(s -> s.getSoLuongTon() * s.getGiaNhap())
                .sum();
        long lowStockCount = list.stream()
                .filter(s -> s.getSoLuongTon() <= 5 && !Constants.TRANG_THAI_SP_NGUNG_KINH_DOANH.equals(s.getTrangThai()))
                .count();
        long outOfStockCount = list.stream()
                .filter(s -> s.getSoLuongTon() == 0 && !Constants.TRANG_THAI_SP_NGUNG_KINH_DOANH.equals(s.getTrangThai()))
                .count();

        // Retrieve flash messages
        String successMsg = (String) session.getAttribute("successMsg");
        String errorMsg = (String) session.getAttribute("errorMsg");
        session.removeAttribute("successMsg");
        session.removeAttribute("errorMsg");

        req.setAttribute("productList", list);
        req.setAttribute("categories", categories);
        req.setAttribute("totalItems", totalItems);
        req.setAttribute("totalInventoryValue", totalInventoryValue);
        req.setAttribute("lowStockCount", lowStockCount);
        req.setAttribute("outOfStockCount", outOfStockCount);
        req.setAttribute("search", search);
        req.setAttribute("selectedCategory", categoryIdStr);
        req.setAttribute("selectedStatus", status);
        req.setAttribute("successMsg", successMsg);
        req.setAttribute("errorMsg", errorMsg);
        req.setAttribute("pageTitle", "Quản lý kho dịch vụ");

        req.getRequestDispatcher("/manager/KhoDichVu.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession();
        TaiKhoan user = (TaiKhoan) session.getAttribute("user");

        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/dangnhap");
            return;
        }

        if (user.getRoleId() != Constants.ROLE_MANAGER) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền thực hiện hành động này.");
            return;
        }

        int coSoId = user.getCoSoId();
        String action = req.getParameter("action");

        try {
            if ("add".equals(action)) {
                String sku = req.getParameter("skuCode");
                String name = req.getParameter("tenSanPham");
                String categoryIdStr = req.getParameter("danhMucID");
                String donGiaStr = req.getParameter("donGia");
                String giaNhapStr = req.getParameter("giaNhap");
                String unit = req.getParameter("donViTinh");
                String stockStr = req.getParameter("soLuongTon");
                String status = req.getParameter("trangThai");
                String desc = req.getParameter("moTa");

                if (name == null || name.trim().isEmpty()) {
                    session.setAttribute("errorMsg", "Tên sản phẩm không được trống.");
                    resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                    return;
                }

                if (name.trim().length() > 100) {
                    session.setAttribute("errorMsg", "Tên sản phẩm không được vượt quá 100 ký tự.");
                    resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                    return;
                }

                // Auto-generate SKU if not provided
                if (sku == null || sku.trim().isEmpty()) {
                    String nanoHex = Long.toHexString(System.nanoTime()).toUpperCase();
                    sku = "SKU-" + (nanoHex.length() > 6 ? nanoHex.substring(nanoHex.length() - 6) : nanoHex);
                } else {
                    sku = sku.trim();
                }

                // Check SkuCode uniqueness
                SanPham_DichVu existingSp = sanPhamDAO.findBySkuAndCoSo(sku, coSoId);
                if (existingSp != null) {
                    session.setAttribute("errorMsg", "Mã SKU '" + sku + "' đã tồn tại trong kho của chi nhánh.");
                    resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                    return;
                }

                int categoryId = Integer.parseInt(categoryIdStr);
                double donGia = Double.parseDouble(donGiaStr);
                double giaNhap = Double.parseDouble(giaNhapStr);
                int stock = Integer.parseInt(stockStr);

                if (donGia <= 0 || giaNhap <= 0 || stock < 0) {
                    session.setAttribute("errorMsg", "Giá bán lẻ và giá nhập phải lớn hơn 0. Số lượng tồn không được là số âm.");
                    resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                    return;
                }

                SanPham_DichVu sp = new SanPham_DichVu();
                sp.setSkuCode(sku.trim());
                sp.setTenSanPham(name.trim());
                sp.setDanhMucID(categoryId);
                sp.setCoSoID(coSoId);
                sp.setDonGia(donGia);
                sp.setGiaNhap(giaNhap);
                sp.setDonViTinh(unit);
                sp.setSoLuongTon(stock);
                sp.setTrangThai(status != null ? status : Constants.TRANG_THAI_SP_DANG_KINH_DOANH);
                sp.setMoTa(desc);

                boolean success = sanPhamDAO.insert(sp);
                if (success) {
                    session.setAttribute("successMsg", "Thêm sản phẩm mới thành công.");
                    AuditLogService.log(req, user,
                        AuditLogService.ACTION_CREATE, AuditLogService.ENTITY_SAN_PHAM,
                        String.valueOf(sp.getSanPhamID()), sp.getTenSanPham(),
                        "Manager thêm sản phẩm/dịch vụ");
                } else {
                    session.setAttribute("errorMsg", "Không thể thêm sản phẩm vào cơ sở dữ liệu.");
                }

            } else if ("update".equals(action)) {
                String idStr = req.getParameter("sanPhamID");
                String sku = req.getParameter("skuCode");
                String name = req.getParameter("tenSanPham");
                String categoryIdStr = req.getParameter("danhMucID");
                String donGiaStr = req.getParameter("donGia");
                String giaNhapStr = req.getParameter("giaNhap");
                String unit = req.getParameter("donViTinh");
                String stockStr = req.getParameter("soLuongTon");
                String status = req.getParameter("trangThai");
                String desc = req.getParameter("moTa");

                int id = Integer.parseInt(idStr);
                SanPham_DichVu sp = sanPhamDAO.findById(id);

                if (sp == null || sp.getCoSoID() != coSoId) {
                    session.setAttribute("errorMsg", "Sản phẩm không tồn tại hoặc không thuộc chi nhánh này.");
                    resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                    return;
                }

                if (name == null || name.trim().isEmpty()) {
                    session.setAttribute("errorMsg", "Tên sản phẩm không được trống.");
                    resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                    return;
                }

                if (name.trim().length() > 100) {
                    session.setAttribute("errorMsg", "Tên sản phẩm không được vượt quá 100 ký tự.");
                    resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                    return;
                }

                // Check SKU conflict
                if (sku != null && !sku.trim().equalsIgnoreCase(sp.getSkuCode())) {
                    SanPham_DichVu other = sanPhamDAO.findBySkuAndCoSo(sku.trim(), coSoId);
                    if (other != null) {
                        session.setAttribute("errorMsg", "Mã SKU '" + sku + "' đã được sử dụng bởi sản phẩm khác.");
                        resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                        return;
                    }
                    sp.setSkuCode(sku.trim());
                }

                double donGia = Double.parseDouble(donGiaStr);
                double giaNhap = Double.parseDouble(giaNhapStr);
                int stock = Integer.parseInt(stockStr);

                if (donGia <= 0 || giaNhap <= 0 || stock < 0) {
                    session.setAttribute("errorMsg", "Giá bán lẻ và giá nhập phải lớn hơn 0. Số lượng tồn không được là số âm.");
                    resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                    return;
                }

                sp.setTenSanPham(name.trim());
                sp.setDanhMucID(Integer.parseInt(categoryIdStr));
                sp.setDonGia(donGia);
                sp.setGiaNhap(giaNhap);
                sp.setDonViTinh(unit);
                sp.setSoLuongTon(stock);
                sp.setTrangThai(status);
                sp.setMoTa(desc);

                boolean success = sanPhamDAO.update(sp);
                if (success) {
                    session.setAttribute("successMsg", "Cập nhật sản phẩm thành công.");
                    AuditLogService.log(req, user,
                        AuditLogService.ACTION_UPDATE, AuditLogService.ENTITY_SAN_PHAM,
                        String.valueOf(sp.getSanPhamID()), sp.getTenSanPham(),
                        "Manager cập nhật sản phẩm/dịch vụ");
                } else {
                    session.setAttribute("errorMsg", "Lỗi khi cập nhật sản phẩm.");
                }

            } else if ("delete".equals(action)) {
                String idStr = req.getParameter("id");
                int id = Integer.parseInt(idStr);
                SanPham_DichVu sp = sanPhamDAO.findById(id);

                if (sp == null || sp.getCoSoID() != coSoId) {
                    session.setAttribute("errorMsg", "Sản phẩm không hợp lệ.");
                    resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                    return;
                }

                String tenSanPham = sp.getTenSanPham();
                int spId = sp.getSanPhamID();
                boolean success = sanPhamDAO.softDelete(id, user.getAccountId());
                if (success) {
                    session.setAttribute("successMsg", "Đã chuyển sản phẩm/dịch vụ vào Thùng rác. Bạn có thể vào trang Thùng rác để khôi phục.");
                    AuditLogService.log(req, user,
                        AuditLogService.ACTION_SOFT_DELETE, AuditLogService.ENTITY_SAN_PHAM,
                        String.valueOf(spId), tenSanPham,
                        "Manager xóa mềm sản phẩm/dịch vụ");
                } else {
                    session.setAttribute("errorMsg", "Không thể thực hiện xóa sản phẩm.");
                }


            } else if ("nhap-kho".equals(action)) {
                String idStr = req.getParameter("id");
                String qtyStr = req.getParameter("amount");

                int id = Integer.parseInt(idStr);
                int qty = Integer.parseInt(qtyStr);

                if (qty <= 0) {
                    session.setAttribute("errorMsg", "Số lượng nhập kho phải lớn hơn 0.");
                    resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                    return;
                }

                EntityManager em = JPAUtil.getEntityManager();
                EntityTransaction trans = em.getTransaction();
                try {
                    trans.begin();
                    SanPham_DichVu sp = em.find(SanPham_DichVu.class, id, jakarta.persistence.LockModeType.PESSIMISTIC_WRITE);
                    if (sp == null || sp.getCoSoID() != coSoId) {
                        session.setAttribute("errorMsg", "Sản phẩm không hợp lệ.");
                        trans.rollback();
                        resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                        return;
                    }

                    sp.setSoLuongTon(sp.getSoLuongTon() + qty);
                    if (Constants.TRANG_THAI_SP_TAM_HET_HANG.equals(sp.getTrangThai())) {
                        sp.setTrangThai(Constants.TRANG_THAI_SP_DANG_KINH_DOANH);
                    }
                    em.merge(sp);
                    trans.commit();

                    logger.info("AUDIT - KHO HÀNG (NHẬP): User ID " + user.getAccountId() + " đã nhập " + qty + " sản phẩm ID " + id + " (SKU: " + sp.getSkuCode() + ")");
                    writeKhoAuditLog(user.getAccountId(), id, sp.getSkuCode(), qty, "NHAP", sp.getSoLuongTon());

                    session.setAttribute("successMsg", "Nhập kho thêm " + qty + " " + sp.getDonViTinh() + " cho '" + sp.getTenSanPham() + "' thành công.");
                } catch (Exception e) {
                    if (trans.isActive()) trans.rollback();
                    logger.error("Lỗi giao dịch nhập kho: ", e);
                    session.setAttribute("errorMsg", "Lỗi nhập kho: " + e.getMessage());
                } finally {
                    em.close();
                }

            } else if ("xuat-kho".equals(action)) {
                String idStr = req.getParameter("id");
                String qtyStr = req.getParameter("amount");

                int id = Integer.parseInt(idStr);
                int qty = Integer.parseInt(qtyStr);

                if (qty <= 0) {
                    session.setAttribute("errorMsg", "Số lượng xuất kho phải lớn hơn 0.");
                    resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                    return;
                }

                EntityManager em = JPAUtil.getEntityManager();
                EntityTransaction trans = em.getTransaction();
                try {
                    trans.begin();
                    SanPham_DichVu sp = em.find(SanPham_DichVu.class, id, jakarta.persistence.LockModeType.PESSIMISTIC_WRITE);
                    if (sp == null || sp.getCoSoID() != coSoId) {
                        session.setAttribute("errorMsg", "Sản phẩm không hợp lệ.");
                        trans.rollback();
                        resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                        return;
                    }

                    if (sp.getSoLuongTon() < qty) {
                        session.setAttribute("errorMsg", "Lỗi: Số lượng xuất kho vượt quá số lượng tồn hiện có (" + sp.getSoLuongTon() + ").");
                        trans.rollback();
                        resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                        return;
                    }

                    sp.setSoLuongTon(sp.getSoLuongTon() - qty);
                    if (sp.getSoLuongTon() == 0 && Constants.TRANG_THAI_SP_DANG_KINH_DOANH.equals(sp.getTrangThai())) {
                        sp.setTrangThai(Constants.TRANG_THAI_SP_TAM_HET_HANG);
                    }
                    em.merge(sp);
                    trans.commit();

                    logger.info("AUDIT - KHO HÀNG (XUẤT): User ID " + user.getAccountId() + " đã xuất " + qty + " sản phẩm ID " + id + " (SKU: " + sp.getSkuCode() + ")");
                    writeKhoAuditLog(user.getAccountId(), id, sp.getSkuCode(), qty, "XUAT", sp.getSoLuongTon());

                    session.setAttribute("successMsg", "Xuất kho giảm " + qty + " " + sp.getDonViTinh() + " cho '" + sp.getTenSanPham() + "' thành công.");
                } catch (Exception e) {
                    if (trans.isActive()) trans.rollback();
                    logger.error("Lỗi giao dịch xuất kho: ", e);
                    session.setAttribute("errorMsg", "Lỗi xuất kho: " + e.getMessage());
                } finally {
                    em.close();
                }

            } else if ("add-category".equals(action)) {
                String catName = req.getParameter("tenDanhMuc");
                if (catName == null || catName.trim().isEmpty()) {
                    session.setAttribute("errorMsg", "Tên danh mục không được trống.");
                    resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                    return;
                }

                String trimmedCatName = catName.trim();
                List<DanhMucSanPham> allCats = categoryDAO.findAll();
                boolean exists = false;
                for (DanhMucSanPham dm : allCats) {
                    if (dm.getTenDanhMuc().trim().equalsIgnoreCase(trimmedCatName)) {
                        exists = true;
                        break;
                    }
                }

                if (exists) {
                    session.setAttribute("errorMsg", "Danh mục '" + trimmedCatName + "' đã tồn tại.");
                } else {
                    DanhMucSanPham dm = new DanhMucSanPham();
                    dm.setTenDanhMuc(trimmedCatName);

                    boolean success = categoryDAO.insert(dm);
                    if (success) {
                        session.setAttribute("successMsg", "Thêm danh mục '" + trimmedCatName + "' thành công.");
                    } else {
                        session.setAttribute("errorMsg", "Lỗi khi thêm danh mục mới.");
                    }
                }
            } else if ("update-category".equals(action)) {
                String catIdStr = req.getParameter("danhMucID");
                String catName = req.getParameter("tenDanhMuc");
                if (catIdStr == null || catName == null || catName.trim().isEmpty()) {
                    session.setAttribute("errorMsg", "Dữ liệu cập nhật nhóm dịch vụ không hợp lệ.");
                    resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                    return;
                }

                int catId = Integer.parseInt(catIdStr.trim());
                String trimmedCatName = catName.trim();

                List<DanhMucSanPham> allCats = categoryDAO.findAll();
                boolean exists = false;
                for (DanhMucSanPham dm : allCats) {
                    if (dm.getDanhMucID() != catId && dm.getTenDanhMuc().trim().equalsIgnoreCase(trimmedCatName)) {
                        exists = true;
                        break;
                    }
                }

                if (exists) {
                    session.setAttribute("errorMsg", "Nhóm dịch vụ '" + trimmedCatName + "' đã tồn tại.");
                } else {
                    DanhMucSanPham dm = categoryDAO.findById(catId);
                    if (dm != null) {
                        String oldName = dm.getTenDanhMuc();
                        dm.setTenDanhMuc(trimmedCatName);
                        boolean success = categoryDAO.update(dm);
                        if (success) {
                            session.setAttribute("successMsg", "Cập nhật nhóm dịch vụ '" + trimmedCatName + "' thành công.");
                            AuditLogService.log(req, user,
                                AuditLogService.ACTION_UPDATE, "DanhMucSanPham",
                                String.valueOf(catId), trimmedCatName,
                                "Manager đổi tên nhóm dịch vụ từ '" + oldName + "' sang '" + trimmedCatName + "'");
                        } else {
                            session.setAttribute("errorMsg", "Không thể cập nhật nhóm dịch vụ.");
                        }
                    } else {
                        session.setAttribute("errorMsg", "Nhóm dịch vụ không tồn tại.");
                    }
                }
            } else if ("delete-category".equals(action)) {
                String catIdStr = req.getParameter("danhMucID");
                if (catIdStr == null) {
                    session.setAttribute("errorMsg", "Thiếu ID nhóm dịch vụ cần xóa.");
                    resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
                    return;
                }

                int catId = Integer.parseInt(catIdStr.trim());

                EntityManager em = JPAUtil.getEntityManager();
                try {
                    long count = em.createQuery("SELECT COUNT(p) FROM SanPham_DichVu p WHERE p.DanhMucID = :catId AND p.isDeleted = false", Long.class)
                            .setParameter("catId", catId)
                            .getSingleResult();

                    if (count > 0) {
                        session.setAttribute("errorMsg", "Không thể xóa nhóm dịch vụ này vì có " + count + " mặt hàng/dịch vụ đang thuộc nhóm.");
                    } else {
                        DanhMucSanPham dm = categoryDAO.findById(catId);
                        if (dm != null) {
                            String catName = dm.getTenDanhMuc();
                            boolean success = categoryDAO.delete(catId);
                            if (success) {
                                session.setAttribute("successMsg", "Đã xóa nhóm dịch vụ '" + catName + "' thành công.");
                                AuditLogService.log(req, user,
                                    AuditLogService.ACTION_DELETE, "DanhMucSanPham",
                                    String.valueOf(catId), catName,
                                    "Manager xóa nhóm dịch vụ '" + catName + "'");
                            } else {
                                session.setAttribute("errorMsg", "Lỗi khi xóa nhóm dịch vụ.");
                            }
                        } else {
                            session.setAttribute("errorMsg", "Nhóm dịch vụ không tồn tại.");
                        }
                    }
                } finally {
                    em.close();
                }
            } else if ("add-presets".equals(action)) {
                String[] presetNames = req.getParameterValues("presetNames");
                String[] presetCatNames = req.getParameterValues("presetCatNames");
                String[] presetDonGias = req.getParameterValues("presetDonGias");
                String[] presetGiaNhaps = req.getParameterValues("presetGiaNhaps");
                String[] presetUnits = req.getParameterValues("presetUnits");
                String[] presetStocks = req.getParameterValues("presetStocks");

                if (presetNames != null) {
                    int addedCount = 0;
                    jakarta.persistence.EntityManager em = org.example.util.JPAUtil.getEntityManager();
                    jakarta.persistence.EntityTransaction trans = em.getTransaction();
                    try {
                        trans.begin();
                        List<DanhMucSanPham> allCats = em.createQuery("SELECT d FROM DanhMucSanPham d", DanhMucSanPham.class).getResultList();
                        List<SanPham_DichVu> currentList = em.createQuery("SELECT s FROM SanPham_DichVu s WHERE s.CoSoID = :coSoId", SanPham_DichVu.class)
                            .setParameter("coSoId", coSoId)
                            .getResultList();

                        for (int i = 0; i < presetNames.length; i++) {
                            String name = presetNames[i];
                            String catName = presetCatNames[i];
                            double donGia = Double.parseDouble(presetDonGias[i]);
                            double giaNhap = Double.parseDouble(presetGiaNhaps[i]);
                            String unit = presetUnits[i];
                            int stock = Integer.parseInt(presetStocks[i]);

                            if (stock <= 0) continue;

                            boolean exists = false;
                            for (SanPham_DichVu spExisting : currentList) {
                                if (spExisting.getTenSanPham() != null && spExisting.getTenSanPham().trim().equalsIgnoreCase(name.trim())) {
                                    exists = true;
                                    spExisting.setSoLuongTon(spExisting.getSoLuongTon() + stock);
                                    if (org.example.util.Constants.TRANG_THAI_SP_TAM_HET_HANG.equals(spExisting.getTrangThai())) {
                                        spExisting.setTrangThai(org.example.util.Constants.TRANG_THAI_SP_DANG_KINH_DOANH);
                                    }
                                    em.merge(spExisting);
                                    addedCount++;
                                    break;
                                }
                            }
                            if (exists) {
                                continue;
                            }

                            int catId = -1;
                            for (DanhMucSanPham dm : allCats) {
                                if (dm.getTenDanhMuc().trim().equalsIgnoreCase(catName.trim())) {
                                    catId = dm.getDanhMucID();
                                    break;
                                }
                            }
                            if (catId == -1) {
                                DanhMucSanPham newCat = new DanhMucSanPham();
                                newCat.setTenDanhMuc(catName.trim());
                                em.persist(newCat);
                                allCats = em.createQuery("SELECT d FROM DanhMucSanPham d", DanhMucSanPham.class).getResultList();
                                for (DanhMucSanPham dm : allCats) {
                                    if (dm.getTenDanhMuc().trim().equalsIgnoreCase(catName.trim())) {
                                        catId = dm.getDanhMucID();
                                        break;
                                    }
                                }
                            }

                            String nanoHex = Long.toHexString(System.nanoTime() + i).toUpperCase();
                            String sku = "SKU-" + (nanoHex.length() > 6 ? nanoHex.substring(nanoHex.length() - 6) : nanoHex);

                            SanPham_DichVu sp = new SanPham_DichVu();
                            sp.setSkuCode(sku);
                            sp.setTenSanPham(name.trim());
                            sp.setDanhMucID(catId);
                            sp.setCoSoID(coSoId);
                            sp.setDonGia(donGia);
                            sp.setGiaNhap(giaNhap);
                            sp.setDonViTinh(unit);
                            sp.setSoLuongTon(stock);
                            sp.setTrangThai(org.example.util.Constants.TRANG_THAI_SP_DANG_KINH_DOANH);
                            sp.setMoTa(name.trim() + " chất lượng cao");

                            em.persist(sp);
                            addedCount++;
                        }
                        trans.commit();
                    } catch (Exception e) {
                        if (trans.isActive()) trans.rollback();
                        throw e;
                    } finally {
                        em.close();
                    }
                    if (addedCount > 0) {
                        session.setAttribute("successMsg", "Đã thêm/cập nhật thành công " + addedCount + " sản phẩm vào kho.");
                    } else {
                        session.setAttribute("errorMsg", "Không có sản phẩm nào được chọn để thêm.");
                    }
                } else {
                    session.setAttribute("errorMsg", "Không nhận được danh sách sản phẩm mẫu.");
                }
            } else {
                session.setAttribute("errorMsg", "Hành động không hợp lệ.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("errorMsg", "Đã xảy ra lỗi hệ thống. Vui lòng liên hệ quản trị viên.");
        }

        resp.sendRedirect(req.getContextPath() + "/manager/kho-dich-vu");
    }

    private void writeKhoAuditLog(int actorId, int spId, String sku, int qty, String type, int newStock) {
        logger.info("[AUDIT KHO] TYPE: {} | Actor ID: {} | Product ID: {} | SKU: {} | Qty Changed: {} | New Stock: {}",
                type, actorId, spId, sku, qty, newStock);
    }
}
