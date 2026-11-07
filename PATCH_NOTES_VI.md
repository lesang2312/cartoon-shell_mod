# Bản cập nhật giao diện Network / Performance / Icons / Shortcuts

## Thay đổi chính

- **Network:** thêm DNS tùy chỉnh với DNS IPv4 chính/phụ, kiểm tra địa chỉ trước khi áp dụng, hỗ trợ preset Automatic / Google / Cloudflare / AdGuard. Lệnh `nmcli` truyền tham số riêng, không ghép trực tiếp tên profile vào shell command. Chỉ báo thành công khi lưu DNS và kết nối lại đều thành công.
- **Network tools:** kiểm tra độ trễ bằng kết quả và mã thoát thật của `ping`; làm mới thông tin kết nối; khởi động lại NetworkManager; mở trình chỉnh sửa kết nối hoặc `nmtui`. Lỗi lệnh được hiển thị riêng thay vì báo thành công giả.
- **Performance:** sắp xếp lại profile nguồn thành ba thẻ cân đối; gom animation, blur, shadow và Liquid Glass vào nhóm gọn; trạng thái được kiểm tra cả animation, blur và shadow của Hyprland.
- **Icons:** thêm lựa chọn Cute (Chopper), Anime (Nami), Minimal; lưới icon workspace chỉ quét thư mục và hiển thị thêm nhiều nhân vật đã có trong assets.
- **Shortcuts:** hộp thoại thêm shortcut chuyển sang nền kính mờ trong suốt, bo góc và co giãn theo vùng nội dung; nhãn, gợi ý, nút và thông báo xung đột sử dụng bộ dịch.
- **Glass UI:** giảm độ đục của thẻ mạng, số liệu, nút và các hàng shortcut để nền phía sau vẫn nhìn thấy.

## Đa ngôn ngữ

- Giữ nguyên hệ thống 30 locale hiện tại.
- Các khóa mới có bản dịch đầy đủ trong `vi.json` và `en.json`.
- Những locale còn lại dùng fallback tiếng Anh cho các khóa mới nếu file ngôn ngữ đó chưa có bản dịch; các bản dịch có sẵn của shell vẫn được giữ nguyên.
- `LanguageService.t()` đã có fallback chung để không hiện key thô khi thiếu bản dịch.

## Điều kiện hệ thống

- DNS / Wi-Fi / khởi động lại mạng cần NetworkManager và `nmcli`.
- Kiểm tra ping cần `ping`.
- Công cụ chỉnh sửa kết nối dùng `nm-connection-editor`, nếu không có sẽ thử `kitty -e nmtui`.
- Profile nguồn cần `power-profiles-daemon` (`powerprofilesctl`). Các hiệu ứng hình ảnh cần Hyprland (`hyprctl`).

## Kiểm tra

- Đã kiểm tra cú pháp JSON của toàn bộ 30 file locale.
- Đã kiểm tra cặp khóa mới giữa tiếng Việt và tiếng Anh, icon preview Chopper/Nami, và `git diff --check`.
- Chưa thể chạy kiểm thử giao diện thực tế trong môi trường đóng gói này vì không có Quickshell / qmllint và không có NetworkManager đang hoạt động. Cần chạy thử trên phiên Linux/Hyprland thực tế trước khi sử dụng DNS trên máy chính.
