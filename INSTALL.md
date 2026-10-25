# Liquid Glass cho cartoon-shell

Giải nén đè lên `~/.config/quickshell/cartoon-shell/` (giữ nguyên cấu trúc thư mục), rồi khởi động lại shell.

## File mới
- `components/glass/` — LiquidGlass, GlassBackdrop, GlassPanel, GlassFill, GlassLens, glassNesting.js (port từ gói display)
- `services/GlassService.qml` — công tắc + thông số dùng chung
- `shaders/liquid_glass.frag` + `shaders/qsb/liquid_glass.frag.qsb` (build lại: `shaders/build-glass.sh`)
- `modules/panels/settings/appearance/theme/LiquidGlassToggle.qml` — nút bật/tắt

## File đã sửa
- `commons/Settings.qml` — thêm `appearance.liquidGlass` (mặc định tắt)
- `modules/panels/settings/appearance/Theme.qml` — thêm nút
- `modules/panels/settings/SettingsPanel.qml` — vùng nội dung dùng kính lồng
- 16 panel: launcher, mixer, bluetooth, wifi, flag, shortcutMenu, calendar, weather, music, battery, cpu, ram, tray, keyboard, keybind, package
  (mỗi panel chỉ thêm `GlassPanel { id: glassBg }` + đổi `color:` thành `glassBg.active ? "transparent" : …`)

## Dùng
Settings → Appearance → Theme → công tắc **Liquid Glass**.
Khi tắt (hoặc chưa có hình nền) mọi panel tự quay về nền màu đặc như cũ.
Chỉnh độ đậm / độ mờ: `panelTint`, `panelFrost` trong `services/GlassService.qml`.
