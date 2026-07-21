package org.example.dao;

import org.example.dto.CustomerProfileExtraDTO;

import java.sql.SQLException;

/**
 * DAO riêng cho các trường hồ sơ Customer mở rộng (cover, thể chất, cá nhân
 * hóa) sống trên các cột mới của Accounts do sql/migration_customer_profile.sql
 * thêm vào. Cố tình KHÔNG dùng chung JPA entity TaiKhoan — TaiKhoanDAOImpl.
 * updateAccount() dùng EntityManager.merge() cập nhật toàn bộ entity, nên nếu
 * thêm cột mới vào entity đó sẽ làm hỏng mọi luồng cập nhật tài khoản hiện có
 * (admin/manager/staff/customer) trước khi migration được chạy. DAO này dùng
 * JDBC thuần, độc lập hoàn toàn với luồng đó.
 */
public interface CustomerProfileDAO {
    CustomerProfileExtraDTO getExtra(int accountId) throws SQLException;
    boolean updatePhysical(int accountId, Integer heightCm, Integer weightKg) throws SQLException;
    boolean updateNote(int accountId, String note) throws SQLException;
    boolean updatePersonalization(int accountId, String location, Integer sportId, String level, String goal, String frequency) throws SQLException;
    boolean updateCoverPath(int accountId, String coverPath) throws SQLException;
}
