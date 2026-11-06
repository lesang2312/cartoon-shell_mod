pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons
import qs.services

// Lịch sử clipboard kiểu Windows (Win+V). Bật trong Settings -> General -> Behavior -> Clipboard.
//  - Chạy `wl-paste --watch cliphist store` (chữ + ảnh) khi đang bật để thu thập lịch sử
//  - Đăng ký phím tắt trên Hyprland (cả hyprlang và Lua) và Sway; gọi IPC của shell hiện tại
//  - Niri không hỗ trợ đăng ký bind runtime: cần thêm dòng spawn được hiển thị trong Settings
//  Cần cài: cliphist, wl-clipboard.
Singleton {
    id: root

    property bool open: false
    property string boundKey: ""
    readonly property bool enabled: Settings.behavior.clipboardEnabled
    readonly property string shortcut: Settings.behavior.clipboardShortcut

    readonly property var keys: ({
        "ctrl-shift-z": { hypr: "CTRL SHIFT, Z", hyprLua: "CTRL + SHIFT + Z", sway: "Ctrl+Shift+z" },
        "ctrl-shift-v": { hypr: "CTRL SHIFT, V", hyprLua: "CTRL + SHIFT + V", sway: "Ctrl+Shift+v" }, // chỉ để gỡ bind cũ
        "super-v": { hypr: "SUPER, V", hyprLua: "SUPER + V", sway: "Mod4+v" }
    })

    // Shell quote: giữ nguyên đường dẫn kể cả khi có dấu cách hoặc dấu nháy đơn.
    function _shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    // Lua string literal dùng khi gọi hyprctl eval trên Hyprland cấu hình Lua (0.55+).
    function _luaQuote(value) {
        return "\"" + String(value)
            .replace(/\\/g, "\\\\")
            .replace(/\"/g, "\\\"")
            .replace(/\n/g, "\\n")
            .replace(/\r/g, "\\r") + "\"";
    }

    // --path là option cấp cao của `qs`, phải đặt TRƯỚC `ipc`.
    readonly property string _cmd: "qs --path " + _shellQuote(Quickshell.shellDir) + " ipc call clipboard toggle"

    // gọi từ shell.qml để singleton được khởi tạo
    function init() {
        // Gỡ bind Ctrl+Shift+V từ phiên bản cũ rồi chuyển sang mặc định Ctrl+Shift+Z.
        if (!keys[shortcut] || shortcut === "ctrl-shift-v")
            Settings.behavior.clipboardShortcut = "ctrl-shift-z";
        boundKey = "ctrl-shift-v";
        apply(false);
    }

    function toggle() {
        if (enabled)
            open = !open;
    }
    function close() {
        open = false;
    }

    function _unbind(k) {
        const e = keys[k];
        if (!e)
            return "";
        const luaUnbind = "hl.unbind(" + _luaQuote(e.hyprLua) + ")";
        return 'if [ -n "$SWAYSOCK" ]; then swaymsg unbindsym ' + e.sway + ' >/dev/null 2>&1; '
            + 'elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then '
            + 'if ! hyprctl eval ' + _shellQuote(luaUnbind) + ' >/dev/null 2>&1; then '
            + 'hyprctl keyword unbind ' + _shellQuote(e.hypr) + ' >/dev/null 2>&1; fi; fi\n';
    }

    readonly property string _luaBindDescription: "Cartoon Shell clipboard history"

    function _bind(k, keepOnly) {
        const e = keys[k];
        if (!e)
            return "";

        const luaBind = "hl.bind(" + _luaQuote(e.hyprLua)
            + ", hl.dsp.exec_cmd(" + _luaQuote(_cmd)
            + "), { description = " + _luaQuote(_luaBindDescription) + " })";
        const legacyBind = e.hypr + ", exec, " + _cmd;

        // Sway IPC không có API liệt kê bind runtime; chỉ đăng ký lúc init/thay đổi.
        // Hyprland cho phép kiểm tra danh sách bind để timer không tạo bind trùng.
        return 'if [ -n "$SWAYSOCK" ]; then '
            + (keepOnly ? ':' : 'swaymsg bindsym ' + e.sway + ' exec ' + _shellQuote(_cmd)) + '; '
            + 'elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then '
            + 'hyprctl binds 2>/dev/null | grep -Fq "clipboard toggle" || '
            + '{ hyprctl eval ' + _shellQuote(luaBind) + ' >/dev/null 2>&1 '
            + '|| hyprctl keyword bind ' + _shellQuote(legacyBind) + ' >/dev/null 2>&1; }; fi\n';
    }

    // keepOnly: gọi định kỳ — Hyprland chỉ gán lại nếu bind đã mất; Sway không kiểm tra được bind runtime.
    function apply(keepOnly) {
        let sh = "";
        if (!keepOnly && boundKey !== "")
            sh += _unbind(boundKey);
        if (enabled && keys[shortcut]) {
            sh += _bind(shortcut, keepOnly);
            boundKey = shortcut;
        } else {
            boundKey = "";
        }
        if (!enabled)
            open = false;
        if (sh !== "")
            Quickshell.execDetached(["sh", "-c", sh]);
    }

    onEnabledChanged: apply(false)
    onShortcutChanged: apply(false)

    // Hyprland reload config có thể làm mất bind runtime; timer tự đăng ký lại nếu thiếu.
    // Sway không cung cấp API liệt kê bind runtime, nên chỉ đăng ký một lần khi init/thay đổi.
    Timer {
        interval: 15000
        repeat: true
        running: root.enabled
        onTriggered: root.apply(true)
    }

    // thu thập lịch sử
    Process {
        running: root.enabled
        command: ["wl-paste", "--type", "text", "--watch", "cliphist", "store"]
    }
    Process {
        running: root.enabled
        command: ["wl-paste", "--type", "image", "--watch", "cliphist", "store"]
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            root.toggle();
        }
        function show(): void {
            if (root.enabled)
                root.open = true;
        }
        function hide(): void {
            root.open = false;
        }
    }
}
