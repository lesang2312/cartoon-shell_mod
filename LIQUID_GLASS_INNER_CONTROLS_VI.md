# Gắn Liquid Glass cho nút và hàng danh sách

1. Copy `components/GlassSurface.qml` vào thư mục `components/` của n43.
2. Trong file QML dựng mỗi nút/hàng, đổi fill nền cũ sang `color: "transparent"`.
3. Thêm component này làm con đầu tiên của tile/hàng, với `anchors.fill: parent` và cùng giá trị `radius`.
4. Giữ icon/text ở phía sau `GlassSurface` trong thứ tự QML; nếu cần viền sáng, đặt một `Rectangle` trong suốt có `border` sau `GlassSurface`.
5. Khởi động lại Quickshell. Nếu component không hiện kính, kiểm tra tile/hàng có nằm trong một panel chứa `GlassBackdrop` đang hoạt động hay không.

Thiết lập gợi ý cho ảnh giao diện:
- 4 nút tiện ích: `radius: 20`, `tintAmount: 0.30`, `frost: 1.45`.
- 6 hàng file: `radius: 12`, `tintAmount: 0.24`, `frost: 1.2`.

Nếu file layout chưa có `GlassSurface`, chỉ thêm component vào ZIP sẽ không tự thay được lớp nền của widget; phải thêm nó vào layout như ví dụ trong `GPU_RENDER_VI.md`.
