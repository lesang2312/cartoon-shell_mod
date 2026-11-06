import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components
import qs.commons
import "./" as G

// Settings -> General -> Privacy
//  - Camera / micro đang được ứng dụng nào đó dùng hay không (quét mỗi 3 giây, chỉ khi tab đang mở)
//  - Mức lộ nội dung trong popup thông báo
//  - Dọn dấu vết: clipboard, danh sách tệp gần đây
G.SettingPage {
    id: page
    title: (typeof lang !== "undefined" && lang && lang.general && lang.general.privacy) || "Privacy"

    property bool camActive: false
    property bool micActive: false
    property bool scanned: false

    Process {
        id: scanProc
        command: ["sh", "-c",
            'cam=$(ls -l /proc/[0-9]*/fd 2>/dev/null | grep -c "/dev/video"); '
            + 'mic=$(pactl list source-outputs 2>/dev/null | grep -E "application\\.(process\\.binary|name) = " | grep -viE "cava|quickshell|pavucontrol|peak" | wc -l); '
            + 'echo "cam=$cam"; echo "mic=$mic"']
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    if (line.startsWith("cam=")) page.camActive = parseInt(line.slice(4)) > 0;
                    else if (line.startsWith("mic=")) page.micActive = parseInt(line.slice(4)) > 0;
                }
                page.scanned = true;
            }
        }
    }
    Timer {
        interval: 3000
        repeat: true
        running: page.visible
        triggeredOnStart: true
        onTriggered: if (!scanProc.running) scanProc.running = true
    }

    function clean(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    // ============ Thiết bị đang dùng ============
    G.SettingSection {
        title: "THIẾT BỊ ĐANG ĐƯỢC DÙNG"
        appearAt: 0.3

        Repeater {
            model: [
                { n: "Camera", i: "", on: page.camActive },
                { n: "Micro", i: "", on: page.micActive }
            ]
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: ScalerService.s(12)

                Rectangle {
                    Layout.preferredWidth: ScalerService.s(38)
                    Layout.preferredHeight: ScalerService.s(38)
                    radius: width / 2
                    color: Qt.alpha(parent.modelData.on ? page.theme.normal.red : page.theme.normal.green, 0.18)
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text {
                        anchors.centerIn: parent
                        text: parent.parent.modelData.i
                        color: parent.parent.modelData.on ? page.theme.normal.red : page.theme.normal.green
                        font { family: Settings.appearance.font; pixelSize: ScalerService.s(17) }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: ScalerService.s(1)
                    Text {
                        text: parent.parent.modelData.n
                        color: page.theme.primary.foreground
                        font { family: Settings.appearance.font; pixelSize: ScalerService.s(15); bold: true }
                    }
                    Text {
                        text: !page.scanned ? "Đang kiểm tra…" : (parent.parent.modelData.on ? "Đang có ứng dụng sử dụng" : "Không ai đang dùng")
                        color: page.scanned && parent.parent.modelData.on ? page.theme.normal.red : page.theme.primary.dim_foreground
                        font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
                    }
                }
                Rectangle {
                    Layout.preferredWidth: ScalerService.s(12)
                    Layout.preferredHeight: ScalerService.s(12)
                    radius: width / 2
                    opacity: page.scanned ? 1 : 0.3
                    color: parent.modelData.on ? page.theme.normal.red : page.theme.normal.green
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Kết quả chỉ mang tính tham khảo (camera quét qua /dev/video*, micro qua PipeWire/PulseAudio)."
            color: page.theme.primary.dim_foreground
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(11); italic: true }
        }
    }

    // ============ Thông báo ============
    G.SettingSection {
        title: "NỘI DUNG THÔNG BÁO"
        appearAt: 0.5

        G.SettingChoice {
            title: "Popup được phép lộ gì?"
            desc: "Hữu ích khi chia sẻ màn hình hoặc làm việc ở nơi đông người"
            current: Settings.behavior.privacyNotifDetail
            options: [
                { v: "full", l: "Đầy đủ" },
                { v: "title", l: "Chỉ tiêu đề" },
                { v: "none", l: "Ẩn tất cả" }
            ]
            onPicked: v => Settings.behavior.privacyNotifDetail = v
        }
    }

    // ============ Dọn dấu vết ============
    G.SettingSection {
        title: "DỌN DẤU VẾT"
        appearAt: 0.7

        G.SettingRow {
            title: "Xóa clipboard"
            desc: "Xóa nội dung đang sao chép và lịch sử cliphist (nếu có cài)"
            G.SettingButton {
                id: bClip
                danger: true
                confirm: true
                icon: ""
                text: "Xóa"
                onActivated: {
                    page.clean("command -v cliphist >/dev/null && cliphist wipe; command -v wl-copy >/dev/null && wl-copy --clear; true");
                    bClip.flash("Đã xóa ✓");
                }
            }
        }

        G.SettingDivider {}

        G.SettingRow {
            title: "Xóa danh sách tệp gần đây"
            desc: "Xóa ~/.local/share/recently-used.xbel mà các ứng dụng GTK dùng để nhớ tệp vừa mở"
            G.SettingButton {
                id: bRecent
                danger: true
                confirm: true
                icon: ""
                text: "Xóa"
                onActivated: {
                    page.clean('rm -f "$HOME/.local/share/recently-used.xbel"');
                    bRecent.flash("Đã xóa ✓");
                }
            }
        }
    }
}
