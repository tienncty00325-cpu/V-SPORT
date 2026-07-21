package org.example.dao;

import org.example.model.TaiKhoan;

import org.example.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.List;

public interface TaiKhoanDAO {
    String dangKyKhachHang(TaiKhoan TaiKhoan, String[] favoriteSports);
    Boolean kiemtraUsername(String username);
    Boolean kiemtraEmail(String email);
    TaiKhoan dangNhapKhachHang(String usernameOrEmail, String password);

    /**
     * Tìm các tài khoản đang hoạt động (không khóa, không xóa mềm) có PhoneNumber
     * khớp một trong các biến thể đã chuẩn hóa (0..., +84..., 84...).
     * Trả về list để caller phát hiện trường hợp trùng số giữa nhiều tài khoản.
     */
    List<TaiKhoan> timTaiKhoanHoatDongTheoPhone(List<String> phoneVariants);

    /** true nếu đã có tài khoản (chưa xóa mềm) dùng một trong các biến thể số điện thoại này. */
    Boolean kiemtraPhone(List<String> phoneVariants);

    /** Tài khoản chưa xóa mềm theo email (phục vụ quên mật khẩu); null nếu không có. */
    TaiKhoan timTaiKhoanTheoEmail(String email);
    Boolean kiemTraEmailTonTai(String email);
    Boolean capNhatMatKhau(String email, String newPassword);
    TaiKhoan findByUsername(String username);
    TaiKhoan findByEmail(String email);

    // Logic previously in service
    String sendRegistrationOTP(String email, String fullName);
    String sendForgotPasswordOTP(String email);

    // Admin CRUD
    List<TaiKhoan> getAllAccounts();

    /**
     * Danh sách tài khoản dùng cho trang Nhân sự Admin: loại Owner (RoleID=2)
     * chưa có cơ sở nào được duyệt (chỉ có CoSo "Chờ duyệt" hoặc "Từ chối").
     */
    List<TaiKhoan> getStaffDirectoryAccounts();
    List<TaiKhoan> getDeletedAccounts();
    TaiKhoan getAccountById(int id);
    boolean updateAccount(TaiKhoan TaiKhoan);
    boolean deleteAccount(int id);
    boolean softDeleteAccount(int id);
    boolean softDeleteAccount(int accountId, int actorId);
    boolean restoreAccount(int id);
    List<TaiKhoan> findDeletedByCoSo(int coSoId);
    List<Integer> findDeletedIdsOlderThan(int days);
    boolean addAccountByAdmin(TaiKhoan TaiKhoan);

    // Manager operations
    List<TaiKhoan> getAccountsByCoSoAndRoleNotIn(int coSoId, List<Integer> excludedRoleIds);
    List<TaiKhoan> getAccountsByCoSoAndRoleIn(int coSoId, List<Integer> roleIds);
    List<TaiKhoan> getDeletedAccountsByCoSoAndRoleNotIn(int coSoId, List<Integer> excludedRoleIds);

    // Dashboard statistics
    long getTotalStaff();

    List<TaiKhoan> findAll();
}