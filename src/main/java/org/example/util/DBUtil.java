package org.example.util;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.sql.Connection;
import java.sql.SQLException;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class DBUtil {
    private static final String URL;
    private static final String USER;
    private static final String PASSWORD;
    private static final String ENCRYPT;
    private static final String TRUST_SERVER_CERTIFICATE;

    private static HikariDataSource dataSource;
    private static final Logger logger = LogManager.getLogger(DBUtil.class);

    private static String getConfig(String envName, String propertyName) {
        String val = System.getenv(envName);
        if (val == null || val.trim().isEmpty()) {
            val = System.getProperty(propertyName);
        }
        if (val == null || val.trim().isEmpty()) {
            throw new IllegalStateException("Cấu hình bắt buộc bị thiếu: env " + envName + " hoặc system property " + propertyName);
        }
        return val.trim();
    }

    private static String getOptionalConfig(String envName, String propertyName, String defaultValue) {
        String val = System.getenv(envName);
        if (val == null || val.trim().isEmpty()) {
            val = System.getProperty(propertyName);
        }
        return (val == null || val.trim().isEmpty()) ? defaultValue : val.trim();
    }

    static {
        try {
            URL = getConfig("DB_URL", "db.url");
            USER = getConfig("DB_USERNAME", "db.username");
            PASSWORD = getConfig("DB_PASSWORD", "db.password");

            // encrypt/trustServerCertificate KHÔNG được đọc từ DB_URL: HikariCP's
            // DriverDataSource gọi driver.connect(url, props) với props chỉ chứa
            // user/password/addDataSourceProperty(...) - property nhúng trong chuỗi
            // URL không đáng tin cậy được driver mssql-jdbc merge lại đầy đủ trong
            // mọi trường hợp (quan sát thực tế: cùng URL, cùng thứ tự, kết nối qua
            // HikariCP vẫn báo trustServerCertificate=false dù URL có true). Khai
            // báo tường minh qua addDataSourceProperty để không phụ thuộc URL string.
            // DB_TRUST_SERVER_CERTIFICATE=true chỉ nên dùng cho local/dev với chứng
            // chỉ tự ký - ở production có chứng chỉ hợp lệ thì đặt env này = false.
            ENCRYPT = getOptionalConfig("DB_ENCRYPT", "db.encrypt", "true");
            TRUST_SERVER_CERTIFICATE = getOptionalConfig(
                    "DB_TRUST_SERVER_CERTIFICATE", "db.trustServerCertificate", "true");

            HikariConfig config = new HikariConfig();
            config.setJdbcUrl(URL);
            config.setUsername(USER);
            config.setPassword(PASSWORD);
            config.setDriverClassName("com.microsoft.sqlserver.jdbc.SQLServerDriver");

            // Connection pool settings for performance
            config.setMaximumPoolSize(20);
            config.setMinimumIdle(5);
            config.setIdleTimeout(300000);
            config.setConnectionTimeout(30000); // 30 seconds
            config.setMaxLifetime(1800000);

            // Optimization for SQL Server
            config.addDataSourceProperty("cachePrepStmts", "true");
            config.addDataSourceProperty("prepStmtCacheSize", "250");
            config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");

            // SSL - xem ghi chú phía trên vì sao đặt tường minh thay vì để trong URL.
            config.addDataSourceProperty("encrypt", ENCRYPT);
            config.addDataSourceProperty("trustServerCertificate", TRUST_SERVER_CERTIFICATE);

            dataSource = new HikariDataSource(config);
            logger.info("DBUtil: HikariCP data source initialized successfully (encrypt={}, trustServerCertificate={})",
                    ENCRYPT, TRUST_SERVER_CERTIFICATE);
        } catch (Exception e) {
            logger.error("DBUtil: Failed to initialize HikariCP data source", e);
            throw new RuntimeException("Error initializing HikariCP data source", e);
        }
    }

    public static Connection getConnection() {
        try {
            return dataSource.getConnection();
        } catch (SQLException e) {
            logger.error("DBUtil: Failed to get database connection", e);
            throw new IllegalStateException("Không thể kết nối cơ sở dữ liệu.", e);
        }
    }

    public static String getURL() { return URL; }
    public static String getUSER() { return USER; }
    public static String getPASSWORD() { return PASSWORD; }
    public static String getEncrypt() { return ENCRYPT; }
    public static String getTrustServerCertificate() { return TRUST_SERVER_CERTIFICATE; }
}

