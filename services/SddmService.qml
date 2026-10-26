pragma Singleton

import QtQuick
import Quickshell
import qs.commons
import qs.utils

// Đồng bộ avatar (đặt trong Dashboard) sang màn hình đăng nhập SDDM (theme "cartoon").
// Theme đọc ảnh ở  <thư mục theme>/avatars/<tên đăng nhập>. Installer đã cấp quyền ghi thư mục theme
// cho user nên không cần sudo; nếu không ghi được thì bỏ qua âm thầm.
Singleton {
    id: root

    readonly property string themeDir: "/usr/share/sddm/themes/cartoon"
    readonly property string userName: Quickshell.env("USER") || ""

    function init() {
        syncAvatar(Settings.dashboard.urlAvatar);
    }

    function syncAvatar(url) {
        if (!url || root.userName === "" || !Settings.wallpaper.syncSddm)
            return;
        var src = FileUtils.trimFileProtocol(String(url));
        var dir = root.themeDir + "/avatars";
        var dst = dir + "/" + root.userName;
        // Ngoài avatar chính, giữ thêm ảnh trong "gallery" (tối đa 10, mới nhất trước) để chọn lại ở màn hình đăng nhập
        var gal = dir + "/gallery";
        var cmd = `[ -d "${root.themeDir}" ] && [ -w "${root.themeDir}" ] && mkdir -p "${gal}" && ` +
            `{ cmp -s -- "$1" "${dst}" || { cp -f -- "$1" "${dst}.tmp" && chmod 644 "${dst}.tmp" && mv -f "${dst}.tmp" "${dst}"; }; } && ` +
            `{ name="$(basename -- "$1" | tr -c 'A-Za-z0-9._-' '_')"; ` +
            `cmp -s -- "$1" "${gal}/$name" || { cp -f -- "$1" "${gal}/$name" && chmod 644 "${gal}/$name"; }; touch "${gal}/$name"; ` +
            `ls -1t "${gal}" | tail -n +11 | while read -r f; do rm -f -- "${gal}/$f"; done; }`;
        Quickshell.execDetached(["bash", "-c", cmd, "_", src]);
    }

    Connections {
        target: Settings.dashboard
        function onUrlAvatarChanged() {
            root.syncAvatar(Settings.dashboard.urlAvatar);
        }
    }
}
