# Tối ưu CPU Quickshell

## Vấn đề được phát hiện trong mã
- `GlassBackdrop.qml` chạy `FrameAnimation` cho mọi panel kính kể cả panel tĩnh; canvas mới chia widget thành nhiều panel riêng, làm số lần kiểm tra hình học tăng lên.
- `GlassService.qml` đặt `textureScale: 2` dù chú thích nói 72%; giá trị 2 tạo ảnh lấy mẫu ở 2x chiều rộng và 2x chiều cao, tức xấp xỉ 4 lần số pixel so với 1x.
- `CpuSimpleService.qml` gọi `vmstat 1 2` mỗi giây, khiến tiến trình con chờ trong một giây cho mỗi mẫu.

## Các thay đổi
- Giảm `textureScale` về 0.72, đúng như chú thích: khoảng 52% tổng số pixel so với full-resolution 1x.
- Chỉ chạy frame tracking liên tục khi có `GlassFill` lồng nhau hoặc khi đang ở chế độ sắp xếp widget; các thay đổi hình học tĩnh được xử lý bằng signal.
- Đổi CPU sampler sang đọc nhanh `/proc/stat`, tính phần trăm từ chênh lệch giữa các mẫu, mỗi 2 giây.
- Giảm tần suất đọc RAM xuống 2 giây và rút ngắn animation của vòng CPU/RAM/Disk.
- Các vòng trang trí của widget Cute mới vẫn hiển thị nhưng đứng yên; animation của các widget cũ được giữ nguyên.

## Áp dụng
1. Sao lưu thư mục cấu hình Quickshell.
2. Giải nén ZIP và ghi đè các file tương ứng vào thư mục cấu hình hiện tại.
3. Khởi động lại Quickshell.
4. Đo lại CPU sau 1–2 phút khi desktop không tương tác.

Không có phiên Quickshell của máy bạn đang chạy trong môi trường tạo gói, nên chưa thể xác nhận mức CPU mới trực tiếp; đây là tối ưu dựa trên kiểm tra mã tĩnh và cần đo lại trên máy thật.
