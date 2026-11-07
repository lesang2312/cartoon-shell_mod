# Sửa CPU/RAM và tắt tác vụ khi widget không dùng

- CPU đọc `/proc/stat` trực tiếp, loại các trường guest bị tính trùng và hiển thị phần trăm nguyên. Lịch sử CPU vẫn cập nhật để biểu đồ hoạt động.
- RAM dùng `MemTotal - MemAvailable`, nhất quán giữa widget, thanh trạng thái và bảng RAM chi tiết; lấy dữ liệu bằng một lần đọc `/proc/meminfo`.
- Các widget bị ẩn hoặc thu nhỏ không còn được Loader tạo trong chế độ sắp xếp; timer, image, canvas và blur bên trong widget sẽ bị tháo khỏi scene cùng với component.
- GlassBackdrop không còn chạy vòng FrameAnimation 60 FPS khi đứng yên. Hình học cập nhật theo tín hiệu thay đổi; theo dõi từng frame chỉ chạy trong lúc kéo widget. Di chuyển con trỏ/hover vẫn cập nhật hiệu ứng kính theo sự kiện; vòng render theo frame chỉ chạy cho widget đang được kéo, không chạy cho toàn bộ các kính khác.
- Disk usage chỉ được thăm dò khi Activity Monitor hoặc Dashboard thực sự được tải; chu kỳ giảm xuống 10 giây.

Đã kiểm tra tĩnh các file thay đổi và cấu trúc ZIP. Chưa thể render Quickshell trực tiếp trong môi trường này nên cần xác nhận trên máy đích.
