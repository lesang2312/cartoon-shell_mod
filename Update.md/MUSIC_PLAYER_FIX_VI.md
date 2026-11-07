# Sửa Music Player / Mini-player

## Đã sửa
- Mini-player tự co kích thước đĩa và nút điều khiển theo chiều cao thực của dock, tránh cắt hình đĩa hoặc tràn dòng chữ khi thanh chỉ cao 30–40 px.
- Ẩn dòng nghệ sĩ và thanh tiến trình ở dock quá thấp; vẫn giữ tên bài và nút điều khiển gọn.
- Nút điều khiển chuyển sang trạng thái mờ và không nhận click khi chưa có MPRIS player.
- Giảm vùng đệm trên thanh ngang để mini-player có thêm chiều cao hiển thị.
- MPRIS ưu tiên ứng dụng đang phát nhạc, sau đó mới chọn player có metadata; tránh luôn chọn nhầm phần tử đầu tiên trong danh sách.
- Các hàm tiện ích `getActive`, `list`, `play`, `pause`, `stop` dùng cùng player đã chọn, không còn tham chiếu tới `root.active` / `root.list` không tồn tại.
- Timer cập nhật tiến trình của mini-player chỉ chạy khi có player và đang phát nhạc, không chạy nền vô ích lúc rảnh.

## Lưu ý
- Dòng “No song playing” vẫn là trạng thái bình thường khi không có ứng dụng xuất MPRIS hoặc chưa phát bài nào. Hãy mở Spotify, VLC, Firefox/Chromium (YouTube) hoặc trình phát tương thích MPRIS để kiểm tra metadata và nút điều khiển.
- Đã kiểm tra tĩnh các file QML đã sửa và cấu trúc ZIP. Môi trường đóng gói không có Quickshell / `qmllint`, nên chưa thể xác nhận runtime trên phiên Wayland/Hyprland thực tế.

## Cài đặt
Giải nén đè thư mục `cartoon-shell/` vào `~/.config/quickshell/cartoon-shell/`, sau đó khởi động lại Quickshell.
