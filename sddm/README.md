# Theme SDDM "cartoon"

Màn hình đăng nhập + màn hình chào mừng phong cách kính mờ tối giản cho Cartoon Shell (logo Cartoon Shell ở màn hình chào mừng).

- `themes/cartoon/` — theme SDDM (Qt 6). Cài vào `/usr/share/sddm/themes/cartoon`.
- Cài tự động bằng bộ cài `dotfiles-hyprland_mod` (thành phần `sddm`); không cần chọn thủ công.
- Hình nền đăng nhập = hình nền hiện tại của shell: shell chép ảnh vào `themes/cartoon/wallpaper`
  mỗi khi bạn đổi hình nền (tắt bằng `wallpaper.syncSddm = false` trong `settings.json`).
- Tuỳ chỉnh màu / ngôn ngữ / thời gian chào mừng trong `theme.conf`
  (`lang`, `font`, `accent`, `blur`, `splashDuration`). Muốn giữ tuỳ chỉnh khi cài lại, đặt vào `theme.conf.user`.

Thử nhanh không cần đăng xuất: `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/cartoon`
