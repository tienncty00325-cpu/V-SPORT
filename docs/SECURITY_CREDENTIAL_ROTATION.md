# Rotate credential đã lộ trong Git history

Commit `03a9f0a` (và các commit sau đó cho tới `4554235`, khi `.env.example` được
vệ sinh) chứa **giá trị thật** của các biến sau, đã bị đẩy lên remote nếu repo
này có push:

- `DB_PASSWORD` (mật khẩu SQL Server, user `sa`)
- `PAYOS_API_KEY`
- `PAYOS_CHECKSUM_KEY`
- `PAYOS_CLIENT_ID`

`.env.example` hiện tại (từ commit `4554235`) chỉ còn placeholder. **Điều đó
không làm các giá trị cũ an toàn** — chúng vẫn đọc được bằng `git log -p` hoặc
`git show <commit>:.env.example` bởi bất kỳ ai có quyền clone repo, kể cả sau
khi file đã được sửa ở commit mới nhất.

## Việc bắt buộc phải làm (không thể tự động hóa từ phía tôi)

1. **Rotate mật khẩu SQL Server** cho user `sa` trên server `14.225.217.109`
   (hoặc server thật đang dùng) → cập nhật `DB_PASSWORD` trong `.env.local`
   của từng máy dev và trong cấu hình biến môi trường trên môi trường
   staging/production thật.
2. **Rotate PayOS credentials** (Client ID, API Key, Checksum Key) trong
   dashboard PayOS → cập nhật lại `~/.bashrc` hoặc biến môi trường tương ứng
   trên từng máy, và trên server thật đang chạy Tomcat.
3. **Cập nhật `.env.local`** của mỗi thành viên trong nhóm với giá trị mới
   sau khi rotate — không chia sẻ `.env.local` qua chat/email, chỉ qua kênh
   quản lý secret nội bộ.
4. **Kiểm tra cấu hình SmartTomcat** (Run/Debug configuration trong IDE) —
   nếu biến môi trường được set trực tiếp trong run config thay vì đọc từ
   `.env.local`, giá trị cũ có thể vẫn đang nằm trong file cấu hình IDE
   (thường trong `.idea/`, không phải lúc nào cũng bị git bỏ qua) — cần rà
   soát riêng.
5. **Không** tự ý chạy `git filter-repo` hoặc BFG Repo-Cleaner để xóa secret
   khỏi lịch sử git nếu chưa thống nhất với cả nhóm: đây là thao tác viết
   lại lịch sử, ảnh hưởng mọi clone/fork hiện có, bắt buộc mọi người
   force-pull hoặc re-clone sau đó. Chỉ thực hiện sau khi:
   - Đã rotate xong toàn bộ credential ở trên (ưu tiên hơn xóa lịch sử,
     vì xóa lịch sử không thu hồi được giá trị đã có thể bị người khác lưu).
   - Cả nhóm đồng ý về thời điểm thực hiện và ai sẽ force-push.

## Ghi chú

Không có giá trị secret nào được in ra trong quá trình kiểm tra này — chỉ tên
biến môi trường được liệt kê. Việc rotate phải do người có quyền truy cập
tài khoản SQL Server/PayOS thực hiện.
