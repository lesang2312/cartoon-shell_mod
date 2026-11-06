pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons
import qs.services

Singleton {
    id: root

    property bool isNiri: false
    property bool isHyprland: false
    property bool isSway: false

    property var lockscreen: null

    property ListModel workspaces: ListModel {}
    property ListModel windows: ListModel {}
    property int focusedWindowIndex: -1

    property alias displayScales: displayCacheAdapter.displays
    property bool displayScalesLoaded: false

    property var backend: null
    property string displayCachePath: Directories.shellDisplayCachePath

    // --- BỔ SUNG STATE & LOGIC CHO WORKSPACE UI ---
    property var uiWorkspaces: []
    property string activeWorkspace: "1"
    property real scrollAccumulator: 0

    signal workspaceChanged
    signal activeWindowChanged
    signal windowListChanged

    Timer {
        id: idleResetTimer
        interval: 80
        repeat: false
        onTriggered: root.scrollAccumulator = 0
    }

    Component.onCompleted: {
        detectCompositor();
    }

    // Trả về scale hợp lệ cho mỗi màn hình. Background.qml dùng hàm này để
    // tính kích thước wallpaper theo scale của compositor; mặc định 1 nếu
    // cache chưa được nạp hoặc màn hình chưa có dữ liệu.
    function getDisplayScale(displayName) {
        const displays = root.displayScales || ({});
        const entry = displayName ? displays[displayName] : null;
        const rawScale = (typeof entry === "number") ? entry : (entry ? entry.scale : 1.0);
        const scale = Number(rawScale);
        return isFinite(scale) && scale > 0 ? scale : 1.0;
    }

    // Được gọi bởi backend Hyprland/Niri sau khi truy vấn màn hình. Lưu dữ liệu
    // dưới cùng dạng map mà display.json đang dùng và phát signal cho UI cần cập nhật.
    function onDisplayScalesUpdated(scales) {
        if (!scales || typeof scales !== "object")
            return;

        const normalized = {};
        for (const name in scales) {
            if (!Object.prototype.hasOwnProperty.call(scales, name))
                continue;
            const entry = scales[name];
            const rawScale = (typeof entry === "number") ? entry : (entry ? entry.scale : 1.0);
            const parsedScale = Number(rawScale);
            const safeScale = isFinite(parsedScale) && parsedScale > 0 ? parsedScale : 1.0;

            if (entry && typeof entry === "object") {
                const copy = {};
                for (const key in entry) {
                    if (Object.prototype.hasOwnProperty.call(entry, key))
                        copy[key] = entry[key];
                }
                copy.name = copy.name || name;
                copy.scale = safeScale;
                normalized[name] = copy;
            } else {
                normalized[name] = { name: name, scale: safeScale };
            }
        }

        displayCacheAdapter.displays = normalized;
        root.displayScalesLoaded = true;
    }

    FileView {
        id: displayCacheFileView
        path: root.displayCachePath
        printErrors: false
        watchChanges: false
        onLoaded: {
            root.displayScalesLoaded = true;
        }
        onLoadFailed: {
            root.displayScalesLoaded = true;
        }
        onAdapterUpdated: {
            writeAdapter();
        }

        JsonAdapter {
            id: displayCacheAdapter
            property var displays: ({})
        }
    }

    function detectCompositor() {
        const niriSocket = Quickshell.env("NIRI_SOCKET");
        const hyprlandSignature = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE");
        const swaySock = Quickshell.env("SWAYSOCK");

        if (niriSocket && niriSocket.length > 0) {
            isNiri = true;
            backendLoader.sourceComponent = niriComponent;
        } else if (hyprlandSignature && hyprlandSignature.length > 0) {
            isHyprland = true;
            backendLoader.sourceComponent = hyprlandComponent;
        } else if (swaySock && swaySock.length > 0) {
            isSway = true;
        } else {
            isNiri = true;
            backendLoader.sourceComponent = niriComponent;
        }
    }

    Loader {
        id: backendLoader
        onLoaded: {
            if (item) {
                root.backend = item;
                root.setupBackendConnections();
                root.backend.initialize();
            }
        }
    }

    Component {
        id: niriComponent
        NiriService {}
    }
    Connections {
        target: Settings.bar

        function onWorkspaceCountChanged() {
            syncWorkspaces();
        }
    }
    Component {
        id: hyprlandComponent
        HyprlandService {}
    }

    function setupBackendConnections() {
        if (!backend)
            return;

        backend.workspaceChanged.connect(() => {
            syncWorkspaces();
            workspaceChanged();
        });

        backend.activeWindowChanged.connect(() => {
            syncWindows();
            activeWindowChanged();
        });

        backend.windowListChanged.connect(() => {
            syncWindows();
            windowListChanged();
        });

        backend.focusedWindowIndexChanged.connect(() => {
            focusedWindowIndex = backend.focusedWindowIndex;
        });

        syncWorkspaces();
        syncWindows();

        focusedWindowIndex = backend.focusedWindowIndex;
    }

    function syncWorkspaces() {
        workspaces.clear();
        const ws = backend ? backend.workspaces : null;
        if (!ws)
            return;

        var wsMap = {};
        for (var i = 0; i < ws.count; i++) {
            var item = ws.get(i);
            workspaces.append(item);
            if (item && item.id) {
                wsMap[item.id.toString()] = item;
                if (item.isActive || item.isFocused) {
                    activeWorkspace = item.id.toString();
                }
            }
        }

        // Tự động build lại mảng uiWorkspaces cho UI dùng
        var count = Settings.bar.workspaceCount || 10;
        var arr = [];
        for (var j = 1; j <= count; j++) {
            var idStr = j.toString();
            var wsData = wsMap[idStr];
            arr.push({
                id: idStr,
                exists: wsData ? (wsData.isOccupied || false) : false,
                isActive: idStr === activeWorkspace
            });
        }
        uiWorkspaces = arr;
    }

    function syncWindows() {
        windows.clear();
        const ws = backend ? backend.windows : [];
        for (var i = 0; i < ws.length; i++) {
            windows.append(ws[i]);
        }
        windowListChanged();
    }

    function switchToWorkspaceById(wsId) {
        if (!backend || !wsId)
            return;
        var workspaceObj = null;
        for (var i = 0; i < workspaces.count; i++) {
            var ws = workspaces.get(i);
            if (ws && ws.id.toString() === wsId.toString()) {
                workspaceObj = ws;
                break;
            }
        }
        if (!workspaceObj) {
            workspaceObj = {
                id: parseInt(wsId),
                idx: parseInt(wsId)
            };
        }
        if (backend.switchToWorkspace) {
            backend.switchToWorkspace(workspaceObj);
            activeWorkspace = wsId.toString();
            syncWorkspaces();
        }
    }

    function handleScroll(angleDeltaY, angleDeltaX, isVertical) {
        idleResetTimer.restart();
        var raw = isVertical ? (angleDeltaX !== 0 ? angleDeltaX : angleDeltaY) : (angleDeltaY !== 0 ? angleDeltaY : angleDeltaX);
        var current = parseInt(activeWorkspace);
        var maxWorkspace = Settings.bar.workspaceCount || 10;

        if ((raw < 0 && current >= maxWorkspace) || (raw > 0 && current <= 1)) {
            scrollAccumulator = 0;
            return;
        }
        scrollAccumulator -= raw;
        var threshold = 120;
        if (scrollAccumulator >= threshold) {
            var next = current + 1;
            if (next <= maxWorkspace)
                switchToWorkspaceById(next.toString());
            scrollAccumulator -= threshold;
        } else if (scrollAccumulator <= -threshold) {
            var prev = current - 1;
            if (prev >= 1)
                switchToWorkspaceById(prev.toString());
            scrollAccumulator += threshold;
        }
    }

    // System Actions
    // ĐĂNG XUẤT — lỗi hay gặp: màn hình đen / kẹt con trỏ nhấp nháy, SDDM không quay lại
    // (Hyprland + SDDM/greetd, nhất là khi chạy qua uwsm). Không có lệnh nào đúng cho mọi máy nên:
    //   graceful : thoát compositor đúng cách (niri/sway/uwsm stop/hyprshutdown/hyprctl dispatch exit)
    //   auto     : graceful + "chó canh" chạy tách rời: nếu sau 10 giây phiên còn sống thì ép đóng ĐÚNG phiên này
    //              bằng logind (an toàn: chỉ đụng session id cũ, không bao giờ giết phiên đăng nhập mới)
    //   force    : đóng phiên ngay bằng logind (ứng dụng không kịp lưu)
    //   custom   : chạy lệnh người dùng tự đặt (Settings -> General -> Session)
    readonly property string _sid: 'sid="${XDG_SESSION_ID:-$(loginctl show-user "$USER" -p Display --value 2>/dev/null)}"\n'
    readonly property string _graceful:
        'if [ -n "$NIRI_SOCKET" ]; then niri msg action quit --skip-confirmation\n'
        + 'elif [ -n "$SWAYSOCK" ]; then swaymsg exit\n'
        + 'else\n'
        + '  [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ] && export HYPRLAND_INSTANCE_SIGNATURE="$(ls -t "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -n1)"\n'
        + '  if command -v uwsm >/dev/null 2>&1 && uwsm check is-active >/dev/null 2>&1; then uwsm stop\n'
        + '  elif command -v hyprshutdown >/dev/null 2>&1; then hyprshutdown\n'
        + '  else hyprctl dispatch exit; fi\n'
        + 'fi\n'
    readonly property string _force:
        'if [ -n "$sid" ]; then loginctl terminate-session "$sid" 2>/dev/null; sleep 2; loginctl kill-session -s KILL "$sid" 2>/dev/null; fi\n'
    readonly property string _watchdog:
        // chạy nền, tách khỏi shell; chỉ ép khi chính phiên "$sid" vẫn còn tồn tại
        '( setsid sh -c \'sleep 10; loginctl show-session "$0" -p Id >/dev/null 2>&1 || exit 0; '
        + 'loginctl terminate-session "$0" 2>/dev/null; sleep 3; loginctl kill-session -s KILL "$0" 2>/dev/null\' "$sid" >/dev/null 2>&1 & )\n'

    function buildLogoutCommand() {
        const m = Settings.behavior.logoutMethod;
        if (m === "custom" && Settings.behavior.logoutCustom.trim() !== "")
            return ["sh", "-c", Settings.behavior.logoutCustom];
        if (m === "force")
            return ["sh", "-c", _sid + _force];
        if (m === "graceful")
            return ["sh", "-c", _graceful];
        return ["sh", "-c", _sid + '[ -n "$sid" ] && ' + _watchdog.replace(/\n$/, "") + "\n" + _graceful];
    }
    readonly property var logoutCommand: buildLogoutCommand()
    function logout() {
        Quickshell.execDetached(buildLogoutCommand());
    }

    // Tắt / bật màn hình (DPMS) — dùng cho "Tắt màn hình khi rảnh"
    function monitorsOff() {
        Quickshell.execDetached(["sh", "-c",
            'if [ -n "$NIRI_SOCKET" ]; then niri msg action power-off-monitors\n'
            + 'elif [ -n "$SWAYSOCK" ]; then swaymsg "output * power off"\n'
            + 'else hyprctl dispatch dpms off; fi']);
    }
    function monitorsOn() {
        Quickshell.execDetached(["sh", "-c",
            'if [ -n "$NIRI_SOCKET" ]; then niri msg action power-on-monitors\n'
            + 'elif [ -n "$SWAYSOCK" ]; then swaymsg "output * power on"\n'
            + 'else hyprctl dispatch dpms on; fi']);
    }
    function shutdown() {
        Quickshell.execDetached(["sh", "-c", "systemctl poweroff || loginctl poweroff"]);
    }
    function reboot() {
        Quickshell.execDetached(["sh", "-c", "systemctl reboot || loginctl reboot"]);
    }
    function suspend() {
        Quickshell.execDetached(["sh", "-c", "systemctl suspend || loginctl suspend"]);
    }
    function lock() {
        try {
            if (root.lockscreen) {
                root.lockscreen.locked = true;
                CavaService.registerComponent("lockscreen");
            }
        } catch (e) {}
    }
}
