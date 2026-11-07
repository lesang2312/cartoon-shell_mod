# Render kính lỏng bằng GPU (giống quickshell)

Shader liquid_glass luôn chạy trên GPU qua scene graph của Qt. Gói này đảm bảo nó không rơi về CPU và giảm khối lượng cho GPU.

## Thay đổi
- GlassBackdrop: chỉ dựng kính khi `GraphicsInfo.api` không phải Software/Null. Không có GPU thì giữ nền đặc, không chạy shader trên CPU.
- GlassService: `textureScale` 0.72 -> 0.5 (hình nền lấy mẫu ở 1/2 độ phân giải như quickshell, ít hơn ~50% pixel); thêm `forceCpuOff` để ép tắt kính.
- GlassBackdrop: bỏ `mipmap` trên Image (layer đã tạo mipmap), tránh tạo mipmap hai lần.
- run-gpu.sh: gỡ biến ép render phần mềm, bật `QSG_RENDER_LOOP=threaded` khi có /dev/dri/renderD*.

## Cách dùng
1. Ghi đè services/GlassService.qml và components/GlassBackdrop.qml.
2. Khởi động bằng `./run-gpu.sh` (thay cho `quickshell`). Nếu khởi động bằng compositor autostart, đổi lệnh thành đường dẫn script này.
   Hoặc thêm vào dòng đầu của shell.qml: `//@ pragma Env QSG_RENDER_LOOP=threaded`
3. Kiểm tra: `nvidia-smi`/`intel_gpu_top`/`radeontop` thấy tải khi mở panel; CPU của quickshell giảm.

# Tăng khúc xạ (bản này)
Chỉnh ở đầu services/GlassService.qml: bezelRatio 0.5, bezelMax 34, thicknessScale 2.2, dispersion 0.14,
rimStrength 0.6, nestDamping 0.3. Panel lồng nhau (nestLevel 1) không còn bị ép "clear" và bị giảm khúc xạ.
Muốn mạnh hơn: tăng thicknessScale (3-4) hoặc bezelMax (40+). Muốn nhẹ hơn: giảm lại.

# Sửa tiến trình qs ngốn CPU
- WaterDropGauge / WaterDropGaugeOsd / WaterFillContainer: Canvas (vẽ bằng CPU) bị vẽ lại mỗi 45-64ms mãi mãi, kể cả khi
  OSD đang ẩn. Giờ sóng chỉ chạy ~1.6s khi giá trị đổi và khi đang hiển thị, rồi dừng.
- BatteryPanel: timer quét UPower 100ms không bao giờ dừng trên máy không có pin -> tối đa 20 lần (5s).
- NetworkService: 2 lệnh nmcli mỗi 1s -> 5s và 8s.
- GlassService: không có /dev/dri/renderD* thì tự tắt kính (tránh shader chạy CPU qua llvmpipe).

# Bảng tiến trình CPU
`ps` 300% là ảo: `ps -o pcpu` là trung bình từ lúc tiến trình khởi động nên chính lệnh `ps` vừa sinh ra hiện 300%,
và qs hiện trung bình cũ. CpuAppService giờ dùng scripts/cpu_top.sh (mẫu /proc 1 giây, % của 1 nhân như top).

# Dùng đúng shader khúc xạ của quickshell
Khúc xạ nằm trong shader `liquid_glass.frag.qsb`; thông số chỉ chỉnh được một phần. n43 đang dùng shader riêng
(shaders/qsb/liquid_glass.frag.qsb) nên không thể giống hệt. Chép shader của quickshell sang:

    ./install_quickshell_shader.sh /thư/mục/quickshell      # thư mục chứa assets/shaders/effects/
    # hoặc: find ~ -name liquid_glass.frag.qsb ; rồi cp thành shaders/qsb/liquid_glass_quickshell.frag.qsb trong n43

Gói này đã kèm sẵn shader (shaders/qsb/liquid_glass_quickshell.frag.qsb). Có file đó thì GlassService tự chuyển sang shader quickshell + bộ thông số gốc của quickshell (quickshellShader = true).
Không có thì vẫn dùng shader n43 với thông số tăng cường.

# Chữ trắng khi bật Liquid Glass
ThemeService: khi GlassService.enabled, `theme.primary.foreground` = trắng và `dim_foreground` = #e6ecf2 (như quickshell).
Theme gốc nằm ở `rawTheme`, không ghi ngược vào file; tắt Liquid Glass thì chữ về màu theme.

# Chữ trắng khi bật Liquid Glass
ThemeService: khi GlassService.enabled, `theme.primary.foreground` = trắng và `dim_foreground` = #e6ecf2 (như quickshell).
Theme gốc nằm ở `rawTheme`, không ghi ngược vào file; tắt Liquid Glass thì chữ về màu theme.

# Trong suốt kiểu giọt nước
GlassService.transparency (0..1, mặc định 1): ruột kính trong hẳn, chỉ mép khúc xạ + viền sáng; giảm tint và frost theo.
Muốn đục lại một phần: đặt 0.5; 0 = như bản trước.

# Viền xanh lạ / kính hiện sai hình nền
Kính lấy hình nền từ ảnh (hoặc khung hình video). Với video, ảnh thumbnail trước đây đặt tên theo tên file nên hai video
trùng tên dùng chung ảnh cũ. Giờ tên có mã băm đường dẫn đầy đủ. Nếu vẫn lệch: xóa `*_glass.jpg` trong thư mục cache thumbnail
của hình nền rồi khởi động lại. Video là ảnh động nên kính chỉ dùng một khung hình (giây thứ 3) của nó.

# Thanh bar mất kính sau khi khởi động
GlassBackdrop với hình nền video: tạo thumbnail xong mới nạp ảnh (không nạp file chưa tồn tại), giới hạn thử lại 3 lần.

# Viền đen trong panel lồng nhau
Panel ngoài trong suốt nên texture của nó có alpha 0 (đen khi premultiplied); GlassFill bên trong lấy mẫu texture đó nên viền ra đen.
GlassBackdrop giờ đưa hình nền đặc (`content`) cho các GlassFill lồng khi transparency > 0.5.

# Kính lỏng cả phần ruột (bản sửa)
- `GlassService.transparency` mặc định là `0.35`: phần ruột có blur/tint của kính, vẫn nhìn được wallpaper; đặt gần `1` để trong hơn hoặc gần `0` để đục hơn.
- `GlassBackdrop` không còn tự ép panel lồng sâu thành `clear = 1`.
- `GlassFill` không còn tự ép mọi thành phần lồng nhau thành trong suốt hoàn toàn; `forceClear` và `forceOpaque` vẫn hoạt động nếu một thành phần cần ngoại lệ.

# Liquid Glass cho từng nút tiện ích và từng hàng danh sách
Gói có thêm `components/GlassSurface.qml` để dùng cho các ô nhỏ như nút Share/Sleep/Restart/Power
và từng hàng Documents/Downloads/Musics/Pictures/config/local. Đặt `GlassSurface` làm con đầu tiên của
mỗi tile/hàng, đặt icon và text sau nó để nội dung hiển thị trên mặt kính. Hãy để nền đặc hiện có của
tile/hàng thành `"transparent"`; `GlassSurface` tự hiển thị `fallbackColor` khi shader không hoạt động.

Ví dụ cho nền của một nút tiện ích (giữ lại icon/text hiện có phía sau phần kính):

```qml
Rectangle {
    id: actionTile
    radius: 20
    color: "transparent"
    border.width: 0

    GlassSurface {
        anchors.fill: parent
        radius: 20
        fallbackColor: "#24283a"
        tintAmount: 0.30
        frost: 1.45
    }

    // Overlay viền tùy chọn, vẽ trên kính
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: "transparent"
        border.width: 1.5
        border.color: "#aeb8d8"
    }

    // Giữ icon/text hiện tại ở đây, sau GlassSurface và overlay viền.
}
```

Với từng hàng file, dùng cùng cách đặt `GlassSurface` nhưng đặt `radius: 12` và `tintAmount: 0.24`
để mặt kính nhẹ hơn; cần thêm một `GlassSurface` riêng cho từng hàng để mỗi hàng có viền/khúc xạ độc lập.

**Lưu ý phạm vi gói:** ZIP này chứa engine kính và module liên quan, nhưng không chứa file QML bố cục chính
đang dựng các nút và hàng file trong ảnh. Vì vậy `GlassSurface.qml` đã được thêm như component dùng lại,
nhưng cần chèn component này vào file bố cục thực tế để thay lớp nền đen hiện tại; xem ví dụ ở trên.
