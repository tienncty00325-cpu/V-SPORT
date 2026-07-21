-- READ-ONLY: Kiểm tra dữ liệu identifier đăng nhập (Email/Phone) của dbo.Accounts.
-- Không sửa dữ liệu. Chạy trên DB dev/test trước.

-- 1) Cột hiện có liên quan identifier
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Accounts'
  AND COLUMN_NAME IN ('Username', 'Email', 'PhoneNumber', 'Password', 'RoleID', 'IsLocked', 'IsDeleted');

-- 2) Tài khoản thiếu Email hoặc Phone (ảnh hưởng login/forgot-password mới)
SELECT AccountID, Username, RoleID, IsLocked, IsDeleted,
       CASE WHEN Email IS NULL OR LTRIM(RTRIM(Email)) = '' THEN 1 ELSE 0 END AS MissingEmail,
       CASE WHEN PhoneNumber IS NULL OR LTRIM(RTRIM(PhoneNumber)) = '' THEN 1 ELSE 0 END AS MissingPhone
FROM dbo.Accounts
WHERE (Email IS NULL OR LTRIM(RTRIM(Email)) = '' OR PhoneNumber IS NULL OR LTRIM(RTRIM(PhoneNumber)) = '')
  AND (IsDeleted = 0 OR IsDeleted IS NULL);

-- 3) Email trùng (sau khi normalize lower/trim) giữa các account đang hoạt động
SELECT LOWER(LTRIM(RTRIM(Email))) AS NormalizedEmail, COUNT(*) AS Cnt
FROM dbo.Accounts
WHERE Email IS NOT NULL AND LTRIM(RTRIM(Email)) <> ''
  AND (IsDeleted = 0 OR IsDeleted IS NULL)
GROUP BY LOWER(LTRIM(RTRIM(Email)))
HAVING COUNT(*) > 1;

-- 4) Phone trùng sau khi đưa về dạng 0xxxxxxxxx (từ 0 / 84 / +84)
;WITH P AS (
    SELECT AccountID, RoleID, IsLocked, IsDeleted,
           CASE
               WHEN PhoneNumber LIKE '+84%' THEN '0' + SUBSTRING(LTRIM(RTRIM(PhoneNumber)), 4, 20)
               WHEN PhoneNumber LIKE '84%'  THEN '0' + SUBSTRING(LTRIM(RTRIM(PhoneNumber)), 3, 20)
               ELSE LTRIM(RTRIM(PhoneNumber))
           END AS NormalizedPhone
    FROM dbo.Accounts
    WHERE PhoneNumber IS NOT NULL AND LTRIM(RTRIM(PhoneNumber)) <> ''
      AND (IsDeleted = 0 OR IsDeleted IS NULL)
)
SELECT NormalizedPhone, COUNT(*) AS Cnt
FROM P
GROUP BY NormalizedPhone
HAVING COUNT(*) > 1;

-- 5) Phân bố role/trạng thái (đối chiếu portal policy: 1=Admin 2=Manager 3=Customer 4/5=Staff)
SELECT RoleID, IsLocked, ISNULL(IsDeleted, 0) AS IsDeleted, COUNT(*) AS Cnt
FROM dbo.Accounts
GROUP BY RoleID, IsLocked, ISNULL(IsDeleted, 0)
ORDER BY RoleID;
