package org.example.util;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;

/**
 * Khởi động ứng dụng: chạy các migration schema nhỏ, idempotent.
 * Không dùng hbm2ddl vì Hibernate entity có thể ánh xạ cột chưa có trong DB.
 */
@WebListener
public class AppStartupListener implements ServletContextListener {

    private static final Logger logger = LogManager.getLogger(AppStartupListener.class);

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        addHoaDonGhiChuColumn();
        checkAccountsReputationSchema();
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        // không cần dọn dẹp
    }

    /**
     * Kiểm tra xem các cột liên quan đến reputation đã tồn tại trong dbo.Accounts chưa,
     * và bảng CustomerReputationHistory có tồn tại không.
     * Chỉ ghi log cảnh báo (warn) nếu thiếu, không tự động sửa bảng.
     */
    private void checkAccountsReputationSchema() {
        String[] columns = {"DiemUyTin", "LateCancelCount", "NoShowCount", "CompletedBookingCount"};
        for (String col : columns) {
            String checkSql = "SELECT COL_LENGTH('dbo.Accounts', '" + col + "') AS col_len";
            try (Connection conn = DBUtil.getConnection();
                 PreparedStatement ps = conn.prepareStatement(checkSql);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Object lenObj = rs.getObject("col_len");
                    if (lenObj == null) {
                        logger.warn("AppStartupListener WARNING: Cột '{}' chưa tồn tại trong bảng dbo.Accounts. Vui lòng chạy file sql/migration_fix_accounts_reputation_columns.sql.", col);
                    }
                }
            } catch (Exception e) {
                logger.error("AppStartupListener: Lỗi khi kiểm tra cột '{}' trong dbo.Accounts: {}", col, e.getMessage());
            }
        }

        // Kiểm tra bảng CustomerReputationHistory
        String checkTableSql = "SELECT OBJECT_ID('dbo.CustomerReputationHistory') AS table_id";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(checkTableSql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                Object tableIdObj = rs.getObject("table_id");
                if (tableIdObj == null) {
                    logger.warn("AppStartupListener WARNING: Bảng 'dbo.CustomerReputationHistory' chưa tồn tại. Vui lòng chạy file sql/migration_customer_reputation_cancel_flow.sql.");
                }
            }
        } catch (Exception e) {
            logger.error("AppStartupListener: Lỗi khi kiểm tra bảng dbo.CustomerReputationHistory: {}", e.getMessage());
        }
    }

    /**
     * Thêm cột GhiChu vào bảng dbo.HoaDon nếu chưa tồn tại.
     * HoaDon.java có @Column(name="GhiChu") nhưng cột chưa được tạo trong DB,
     * khiến Hibernate ném "Invalid column name 'GhiChu'" khi em.find(HoaDon.class, id).
     */
    private void addHoaDonGhiChuColumn() {
        String checkSql = "SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.HoaDon') AND name = 'GhiChu'";
        String alterSql = "ALTER TABLE dbo.HoaDon ADD GhiChu NVARCHAR(500) NULL";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(checkSql);
             ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) {
                try (Statement st = conn.createStatement()) {
                    st.execute(alterSql);
                    logger.info("AppStartupListener: Đã thêm cột GhiChu vào bảng dbo.HoaDon.");
                }
            } else {
                logger.debug("AppStartupListener: Cột GhiChu đã tồn tại trong dbo.HoaDon, bỏ qua migration.");
            }
        } catch (Exception e) {
            logger.error("AppStartupListener: Lỗi khi kiểm tra/thêm cột GhiChu vào dbo.HoaDon: {}", e.getMessage(), e);
        }
    }
}
