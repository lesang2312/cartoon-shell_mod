import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components
import qs.commons
import "./" as G

// Settings -> General -> Notifications
// Thời gian hiện / số lượng / vị trí / Không làm phiền / OSD đã có ở Behavior, nên tab này chỉ giữ phần bổ sung:
//  - Không làm phiền theo giờ (tự bật ban đêm)
//  - Tắt popup theo từng ứng dụng
//  - Ẩn thông báo mức thấp, âm báo
G.SettingPage {
    id: page
    title: (typeof lang !== "undefined" && lang && lang.general && lang.general.notifications) || "Notifications"

    function csv(str) {
        return (str || "").split(",").map(x => x.trim()).filter(x => x !== "");
    }
    function setMuted(app, muted) {
        const list = csv(Settings.behavior.notifMutedApps).filter(x => x !== app);
        if (muted)
            list.push(app);
        Settings.behavior.notifMutedApps = list.join(",");
    }
    function hh(h) {
        return (h < 10 ? "0" : "") + h + ":00";
    }
    // gộp ứng dụng đã thấy + ứng dụng đã tắt (để còn bật lại được dù không gửi nữa)
    readonly property var apps: {
        const seen = csv(Settings.behavior.notifSeenApps), muted = csv(Settings.behavior.notifMutedApps);
        const all = seen.slice();
        for (const m of muted)
            if (all.indexOf(m) < 0)
                all.push(m);
        return all;
    }

    // ============ Theo giờ ============
    G.SettingSection {
        title: "KHÔNG LÀM PHIỀN THEO GIỜ"
        appearAt: 0.3

        G.SettingRow {
            title: "Tự bật theo lịch"
            desc: Settings.behavior.dndSchedule
                ? "Im lặng từ " + page.hh(Settings.behavior.dndFromHour) + " đến " + page.hh(Settings.behavior.dndToHour) + " mỗi ngày. Thông báo khẩn cấp vẫn hiện."
                : "Tự ẩn popup vào ban đêm mà không phải nhớ bật tay"
            CustomToggleSwitch {
                adapter: Settings.behavior.dndSchedule
                onClicked: Settings.behavior.dndSchedule = !Settings.behavior.dndSchedule
            }
        }

        G.SettingChoice {
            title: "Bắt đầu lúc"
            dimmed: !Settings.behavior.dndSchedule
            current: Settings.behavior.dndFromHour
            options: [18, 19, 20, 21, 22, 23, 0].map(h => ({ v: h, l: page.hh(h) }))
            onPicked: v => Settings.behavior.dndFromHour = v
        }

        G.SettingChoice {
            title: "Kết thúc lúc"
            dimmed: !Settings.behavior.dndSchedule
            current: Settings.behavior.dndToHour
            options: [5, 6, 7, 8, 9, 10].map(h => ({ v: h, l: page.hh(h) }))
            onPicked: v => Settings.behavior.dndToHour = v
        }
    }

    // ============ Theo ứng dụng ============
    G.SettingSection {
        title: "THEO TỪNG ỨNG DỤNG"
        appearAt: 0.5

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: page.apps.length === 0
                ? "Chưa có ứng dụng nào gửi thông báo. Ứng dụng sẽ tự xuất hiện ở đây sau lần gửi đầu tiên."
                : "Tắt công tắc để ứng dụng không hiện popup nữa (thông báo khẩn cấp vẫn hiện)."
            color: page.theme.primary.dim_foreground
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
        }

        Repeater {
            model: page.apps
            delegate: G.SettingRow {
                required property string modelData
                readonly property bool muted: page.csv(Settings.behavior.notifMutedApps).indexOf(modelData) >= 0
                title: modelData
                desc: muted ? "Đã tắt popup" : "Hiện popup"
                CustomToggleSwitch {
                    adapter: !parent.parent.muted
                    onClicked: page.setMuted(modelData, !parent.parent.muted ? true : false)
                }
            }
        }

        G.SettingDivider {}

        G.SettingRow {
            title: "Gửi thông báo thử"
            desc: "Hiện một popup mẫu và thêm \"Cartoon Shell\" vào danh sách trên"
            G.SettingButton {
                icon: ""
                text: "Gửi thử"
                onActivated: Quickshell.execDetached(["notify-send", "-a", "Cartoon Shell", "Xin chào! 👋", "Đây là thông báo thử từ Cartoon Shell."])
            }
        }
    }

    // ============ Lọc & âm báo ============
    G.SettingSection {
        title: "LỌC & ÂM BÁO"
        appearAt: 0.7

        G.SettingRow {
            title: "Ẩn thông báo mức thấp"
            desc: "Không hiện popup cho thông báo ưu tiên thấp (tin tham khảo, tiến trình nền…)"
            CustomToggleSwitch {
                adapter: Settings.behavior.notifHideLow
                onClicked: Settings.behavior.notifHideLow = !Settings.behavior.notifHideLow
            }
        }

        G.SettingDivider {}

        G.SettingRow {
            title: "Phát âm khi có thông báo"
            desc: "Dùng âm lượng hiệu ứng ở Behavior; im nếu \"Âm thanh giao diện\" đang tắt"
            CustomToggleSwitch {
                adapter: Settings.behavior.notifSound
                onClicked: Settings.behavior.notifSound = !Settings.behavior.notifSound
            }
        }
    }
}
