# Trạng thái tích hợp

Đã thêm hai wrapper nền kính để dùng trực tiếp cho các phần tử có nội dung con hiện có:
- `components/GlassUtilityTile.qml` — dành cho 4 nút tiện ích.
- `components/GlassDirectoryRow.qml` — dành cho 6 hàng thư mục.

**Chưa thể gắn chúng vào đúng 10 instance trong giao diện ảnh** vì ZIP nguồn trong phiên không chứa QML định nghĩa các nút và hàng đó. Gói không tự ý tạo layout thay thế để tránh làm mất icon, chữ, kích thước, căn lề hoặc handler gốc. Xem `LIQUID_GLASS_LAYOUT_INTEGRATION_VI.md` để gắn vào file layout thực tế.
