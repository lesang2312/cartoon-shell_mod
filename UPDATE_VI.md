# Thông báo & nút cập nhật

- **Nút**: Cài đặt → Hệ thống → thẻ "Cập nhật Cartoon Shell" (Kiểm tra / Cập nhật ngay / Tải lại shell, công tắc tự kiểm tra).
- **Thông báo**: sau khi shell chạy 20 giây rồi mỗi 2 giờ, nếu GitHub (`lesang2312/cartoon-shell_mod`, nhánh mặc định) có commit mới thì hiện popup 1 lần cho mỗi commit; đồng thời có chấm đỏ ở nút **Cài đặt** (menu trái) và mục **Hệ thống**.
- **Cách hoạt động**: `scripts/update.sh` so mã commit.
  - Thư mục shell là git clone → `git merge --ff-only` (không đè thay đổi cục bộ).
  - Không phải git → tải tarball đúng commit, **sao lưu** vào `~/.cache/cartoon-shell/backups/` (giữ 3 bản), rồi chép đè; mã commit lưu ở `.installed_commit`.
  - Repo kèm sẵn `VERSION` (số phiên bản hiển thị) và `.installed_commit` (mốc commit). Nếu xóa `.installed_commit`, lần kiểm tra đầu sẽ ghi lại mốc mới.
- Thử tay: `bash scripts/update.sh check` / `bash scripts/update.sh apply`.

## Đóng băng tác vụ không dùng (giảm CPU/GPU)
- Kiểm tra update: 20 giây sau khi khởi động, rồi mỗi **2 giờ** (không có gì khác chạy nền cho update).
- Shader chuyển cảnh hình nền chỉ tồn tại trong lúc đổi hình nền; đứng yên thì không vẽ.
- Quét Wi-Fi (`nmcli`) chỉ chạy khi đang mở bảng Wi-Fi / Quick settings / Cài đặt; nền chỉ đọc trạng thái mỗi 60 giây.
- Thăm dò mạng ở thanh: 5s/8s -> 20s/30s. Đăng ký lại bind clipboard: 15s -> 120s.
- Đĩa xoay album chỉ quay khi đang phát nhạc và đang hiện.
