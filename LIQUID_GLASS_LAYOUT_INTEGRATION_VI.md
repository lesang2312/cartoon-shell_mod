# Gắn Liquid Glass trực tiếp vào các nút tiện ích và hàng thư mục

Gói hiện có `components/GlassUtilityTile.qml` và `components/GlassDirectoryRow.qml`. Hai component này chỉ thay lớp nền, còn icon, text, MouseArea, signal và binding cũ được giữ nguyên khi chuyển các phần tử con sang wrapper.

## 4 nút tiện ích

Trong file QML chứa bố cục 4 nút Share / Sleep / Restart / Power:

1. Đổi loại phần tử nền bên ngoài từ `Rectangle` (hoặc component nền cũ) sang `GlassUtilityTile`.
2. Giữ nguyên `x`, `y`, `width`, `height`, `anchors`, `id`, `MouseArea`, handlers và toàn bộ phần tử icon hiện có.
3. Di chuyển các phần tử con hiện có vào bên trong `GlassUtilityTile`; không thay icon bằng ký tự/emoji mới.
4. Đặt `radius: 20`. Mặc định kính dùng tint 0.30, frost 1.45 và viền 1.5 px.

## 6 hàng thư mục

Với Documents, Downloads, Musics, Pictures, `~/.config`, `~/.local`, làm tương tự nhưng đổi nền ngoài sang `GlassDirectoryRow` và đặt `radius: 12`. Giữ nguyên label, icon, màu icon, khoảng cách, kích thước, vị trí và hành vi click.

## Lưu ý về file nguồn

File ZIP nguồn được cung cấp trong phiên này chỉ có một panel pin, OSD và các component/service kính; không có QML dựng 4 nút và 6 hàng thư mục trong ảnh. Vì vậy chưa có file đích để áp dụng thay đổi vào đúng 10 instance. Hai wrapper đã sẵn sàng nhưng cần được đặt vào layout thật để chúng xuất hiện trên màn hình. Không nên tạo một layout mới hoặc đoán lại icon/handler vì sẽ có nguy cơ làm thay đổi bố cục gốc.
