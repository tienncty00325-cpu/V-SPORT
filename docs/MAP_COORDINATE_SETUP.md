# Hướng dẫn cấu hình và Tọa độ bản đồ V-SPORT

Tài liệu này hướng dẫn cách cấu hình khóa API MapTiler và cách thiết lập tọa độ địa lý cho các cơ sở thể thao (CoSo) để hiển thị trên Bản đồ Customer Portal.

## 1. Cấu hình MapTiler API Key

Hệ thống hỗ trợ 3 mức độ cấu hình API Key với độ ưu tiên giảm dần:

1. **JVM System Property:** `MAPTILER_API_KEY` (Khuyên dùng khi triển khai thực tế).
2. **Context Parameter (`web.xml`):** Thêm cấu hình `<context-param>` vào `web.xml`.
3. **OpenStreetMap Development Fallback:** Nếu không tìm thấy khóa API nào, hệ thống sẽ tự động dùng nhà cung cấp OpenStreetMap miễn phí làm fallback để nhà phát triển có thể kiểm thử ngay lập tức.

### Cách cấu hình `web.xml` (Cách 2):
Mở file `src/main/webapp/WEB-INF/web.xml` và thêm cấu hình sau trong thẻ `<web-app>`:

```xml
<context-param>
    <param-name>MAPTILER_API_KEY</param-name>
    <param-value>YOUR_MAPTILER_API_KEY_HERE</param-value>
</context-param>
```

---

## 2. Di chuyển dữ liệu Tọa độ (Database Migration)

Hệ thống lưu tọa độ vĩ độ (`ViDo`) và kinh độ (`KinhDo`) của bảng `CoSo` trong cơ sở dữ liệu Microsoft SQL Server.

Để khởi tạo các cột tọa độ và gán giá trị mặc định/mẫu cho các cơ sở hiện tại, chạy kịch bản SQL sau:

- File migration: `sql/migration_facility_geolocation.sql`
- File verify: `sql/verify_facility_geolocation.sql`

Chạy migration bằng cách thực thi file `migration_facility_geolocation.sql` trên cơ sở dữ liệu `QuanLiSport`.

---

## 3. Bản đồ hoạt động như thế nào?

- **Map Provider:** Leaflet.js làm thư viện bản đồ chính kết hợp với MapTiler Cloud hoặc OpenStreetMap.
- **Markers & Popup:** Mỗi cơ sở có một Marker màu xanh lục bảo (emerald green) biểu tượng cho V-SPORT, nhấn vào hiển thị tên cơ sở, khoảng cách (nếu bật GPS), số sân trống và nút liên kết trực tiếp tới trang đặt sân.
- **GPS Định vị:** Nhấn nút GPS ở góc trên bên phải để yêu cầu quyền định vị của trình duyệt. Bản đồ sẽ tự động zoom tới vị trí của bạn và sắp xếp các cơ sở theo khoảng cách gần nhất.
- **Bộ lọc động:** Hỗ trợ lọc theo môn thể thao, bán kính tìm kiếm (km) và trạng thái mở cửa hiện tại.
