pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons

Singleton {
    id: root

    property bool ready: false

    readonly property alias appearance: adapter.appearance
    readonly property alias wallpaper: adapter.wallpaper
    readonly property alias general: adapter.general
    readonly property alias effects: adapter.effects
    readonly property alias clock: adapter.clock
    readonly property alias weather: adapter.weather
    readonly property alias bar: adapter.bar
    readonly property alias dashboard: adapter.dashboard
    // Cài đặt âm thanh/EQ nằm trong nhóm effects
    readonly property alias audio: adapter.effects
    // Cài đặt Behavior (Settings -> General -> Behavior) cũng nằm trong nhóm effects, không tạo kiểu mới
    readonly property alias behavior: adapter.effects

    signal settingsLoaded
    signal settingsSaved

    Component.onCompleted: {
        settingsFileView.adapter = adapter;
    }

    Timer {
        id: saveTimer
        running: false
        interval: 1000
        onTriggered: {
            root.saveImmediate();
        }
    }

    function saveImmediate() {
        settingsFileView.writeAdapter();
        root.ready = true;
        root.settingsSaved();
    }

    FileView {
        id: settingsFileView
        path: Directories.shellConfigSettingsPath
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: saveTimer.start()
        onPathChanged: {
            if (path !== undefined) {
                reload();
            }
        }
        onLoaded: function () {
            if (!root.ready) {
                root.ready = true;
                root.settingsLoaded();
            }
        }
        onLoadFailed: function (error) {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
            }
        }
    }

    JsonAdapter {
        id: adapter

        property Wallpaper wallpaper: Wallpaper {}
        property Appearance appearance: Appearance {}
        property General general: General {}
        property Effects effects: Effects {}
        property Clock clock: Clock {}
        property Weather weather: Weather {}
        property Bar bar: Bar {}
        property Dashboard dashboard: Dashboard {}
    }

    component Effects: JsonObject {
        property string workspaceAnimation: ""
        // Equalizer 10 băng tần (dB, cách nhau bởi dấu phẩy: 31Hz ... 16kHz)
        property bool eqEnabled: false
        property string eqPreset: "Flat"
        property string eqBands: "0,0,0,0,0,0,0,0,0,0"
        // ---- Behavior ----
        property bool soundEffects: true         // âm thanh hover/click
        property real soundVolume: 0.8           // 0.0 - 1.0
        property bool confirmPowerActions: true  // hỏi xác nhận trước khi ngủ/khóa/đăng xuất/khởi động lại/tắt máy
        property bool reduceMotion: false        // tắt animation chạy nền cho đỡ nóng máy
        property int lockAfterMin: 0             // tự khóa sau N phút không thao tác (0 = tắt)
        property int suspendAfterMin: 0          // tự ngủ sau N phút không thao tác (0 = tắt)
        property bool keepAwake: false           // giữ máy thức: tạm tắt tự khóa/ngủ
        property bool hotCorner: false           // rê chuột vào góc => mở launcher
        property string hotCornerPos: "top-left" // top-left | top-right | bottom-left | bottom-right
        property bool doNotDisturb: false        // ẩn popup thông báo (khẩn cấp vẫn hiện)
        property int notifTimeoutSec: 10         // thời gian hiện popup khi ứng dụng không chỉ định (giây)
        property int notifMax: 4                 // số popup tối đa cùng lúc
        property string notifPos: "top"          // left | top | right
        property bool osdEnabled: true           // hiện OSD âm lượng / độ sáng
        property int osdDurationMs: 1000         // thời gian hiện OSD
        // ---- Clipboard (lịch sử kiểu Windows) ----
        property bool clipboardEnabled: true     // bật lịch sử clipboard + phím tắt
        property string clipboardShortcut: "ctrl-shift-z" // ctrl-shift-z | super-v
        // ---- Session ----
        property string logoutMethod: "auto"     // auto | graceful | force | custom
        property string logoutCustom: ""         // lệnh shell khi logoutMethod = custom
        property int monitorOffAfterMin: 0       // tắt màn hình sau N phút không thao tác (0 = tắt)
        // ---- Notifications ----
        property bool notifSound: false          // phát âm khi có thông báo mới
        property bool notifHideLow: false        // không hiện popup cho thông báo mức thấp
        property bool dndSchedule: false         // không làm phiền theo giờ
        property int dndFromHour: 22
        property int dndToHour: 7
        property string notifSeenApps: ""        // các ứng dụng từng gửi thông báo (cách nhau dấu phẩy)
        property string notifMutedApps: ""       // các ứng dụng bị tắt popup (cách nhau dấu phẩy)
        // ---- Privacy ----
        property string privacyNotifDetail: "full" // full | title | none: mức nội dung lộ ra trong popup
        // ---- Update ----
        property bool updateAutoCheck: true      // tự kiểm tra bản cập nhật (lúc khởi động + mỗi 6 giờ)
        property string updateLastNotified: ""   // commit đã báo rồi, để không báo lặp
    }
    component Dashboard: JsonObject {
        property string splitMethod: "dwindle_default"
        property string fullname: "long"
        property string urlAvatar: ""
        property string username: "mailong2401"
        property var appGrid: [
            {
                "type": "app",
                "target": "firefox",
                "name": "Firefox",
                "icon": Quickshell.shellDir + "/icons/animal.png",
                "autoIcon": "firefox"
            },
            {
                "type": "app",
                "target": "firefox",
                "name": "Firefox",
                "icon": Quickshell.shellDir + "/icons/anime.png",
                "autoIcon": "firefox"
            },
            {
                "type": "app",
                "target": "firefox",
                "name": "Firefox",
                "icon": Quickshell.shellDir + "/icons/camera.png",
                "autoIcon": "firefox"
            },
            {
                "type": "app",
                "target": "firefox",
                "name": "Firefox",
                "icon": Quickshell.shellDir + "/icons/cartoon.png",
                "autoIcon": "firefox"
            },
            {
                "type": "app",
                "target": "firefox",
                "name": "Firefox",
                "icon": Quickshell.shellDir + "/icons/vietnam.png",
                "autoIcon": "firefox"
            },
            {
                "type": "app",
                "target": "firefox",
                "name": "Firefox",
                "icon": Quickshell.shellDir + "/icons/cartoon.png",
                "autoIcon": "firefox"
            },
            {
                "type": "app",
                "target": "firefox",
                "name": "Firefox",
                "icon": Quickshell.shellDir + "/icons/cinema.png",
                "autoIcon": "firefox"
            },
            {
                "type": "app",
                "target": "firefox",
                "name": "Firefox",
                "icon": Quickshell.shellDir + "/icons/panda.png",
                "autoIcon": "firefox"
            },
            {
                "type": "app",
                "target": "kitty",
                "name": "Kitty",
                "icon": "",
                "autoIcon": "kitty"
            }
        ]
    }

    component Bar: JsonObject {
        property string position: "top"
        property string style: "style1"
        property string styleWorkspace: "image"
        property string iconWorkspace: "pacman"
        property string iconLauncher: "default"
        property int workspaceCount: 9
        property var ram: {
            "style": 1,
            "active": true
        }
        property var cpu: {
            "style": 1,
            "active": true
        }
        property var disk: {
            "style": 1,
            "active": true
        }
        property var brightness: {
            "style": 1,
            "active": true
        }
        property var bluetooth: {
            "style": 1,
            "active": true
        }
        property var wifi: {
            "style": 1,
            "active": true
        }
        property var volume: {
            "style": 1,
            "active": true
        }
    }

    component Clock: JsonObject {
        property string timeFormat: "24h"
        // Ẩn mặc định ở lần khởi động đầu tiên (người dùng bật lại trong Settings -> Clock Time)
        property bool enableWidget: false
        property string positionWidget: "top"
        // "current" | "iphone" | "pixel"
        property string style: "current"
        // Dải thông tin kiểu Android (pin, thời tiết, wifi) dưới đồng hồ
        property bool showInfo: true
    }

    component Weather: JsonObject {
        property string keyApi: "21e0f911c7de4308916165005251210"
        property string location: "Ho Chi Minh City,Vietnam"
    }

    component Appearance: JsonObject {
        property string theme: "matugen"
        property string mode: "dark"
        property string countryFlag: "vietnam"
        property string fonts: ""
        property string styleIcons: "image"
        property int radius1: 22
        property int radius2: 16
        property int radius3: 8
        property bool enableBorder: false
        // Hiệu ứng kính lỏng (Liquid Glass) cho các panel
        property bool liquidGlass: true
        // Kiểu hộp thoại: "classic" hoặc "cute"
        property string dialogStyle: "cute"
        // Thêm các properties cho dynamic theme
        property bool dynamic: false
        property string light: "light"
        property string dark: "dark"
        property string matugenType: "scheme-tonal-spot"
        property string font: "ComicShannsMono Nerd Font"
    }

    component General: JsonObject {
        property string lang: "vi"
        property real screenHeight: 1080
        property real screenWidth: 1920
        property real scale: 1.0
    }

    component Wallpaper: JsonObject {
        property bool enabled: true
        property bool overviewEnabled: true
        property string directory: Directories.defaultWallpaperDir
        property bool enableMultiMonitorDirectories: false
        property bool recursiveSearch: false
        property bool setWallpaperOnAllMonitors: true
        // Đồng bộ hình nền hiện tại sang màn hình đăng nhập SDDM (theme cartoon)
        property bool syncSddm: true
        property string defaultWallpaper: ""
        property string fillMode: "crop"
        property color fillColor: "#000000"
        property int shaders: 0
        property list<var> monitors: []
        property int transitionDuration: 1500
        property real transitionEdgeSmoothness: 0.1
        // Video-specific properties
        property bool videoMuted: true
        property bool videoLoop: true
        property real videoPlaybackRate: 1.0
    }
}
