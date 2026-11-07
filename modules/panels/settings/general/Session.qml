import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons
import "./" as G

// Settings -> General -> Session
// Các nút Khóa / Ngủ / Đăng xuất / Khởi động lại / Tắt máy đã có ở thanh bên, "Giữ máy thức" + tự khóa + tự ngủ
// nằm ở Behavior nên tab này chỉ giữ những gì chưa có ở đâu khác:
//  - Cách đăng xuất (sửa lỗi màn hình đen / kẹt SDDM sau khi đăng xuất)
//  - Tắt màn hình khi rảnh
G.SettingPage {
    id: page
    title: (typeof lang !== "undefined" && lang && lang.general && lang.general.session) || AutoTranslateService.t("Session")

    readonly property var methodDesc: ({
        "auto": "Thoát compositor đúng cách; nếu sau 10 giây phiên vẫn còn (màn hình đen, kẹt con trỏ) thì tự ép đóng phiên đó qua logind. Khuyên dùng.",
        "graceful": "Chỉ thoát compositor đúng cách (uwsm stop / hyprshutdown / hyprctl dispatch exit). Không ép — nếu máy bạn bị đen màn hình thì đừng chọn.",
        "force": "Đóng phiên ngay bằng logind. Luôn về được màn hình đăng nhập nhưng ứng dụng đang mở không kịp lưu.",
        "custom": "Chạy lệnh shell của riêng bạn."
    })

    G.SettingSection {
        title: AutoTranslateService.t("ĐĂNG XUẤT")
        appearAt: 0.3

        G.SettingChoice {
            title: AutoTranslateService.t("Cách đăng xuất")
            desc: page.methodDesc[Settings.behavior.logoutMethod] || ""
            current: Settings.behavior.logoutMethod
            options: [
                { v: "auto", l: "Tự động" },
                { v: "graceful", l: "Nhẹ nhàng" },
                { v: "force", l: "Ép đóng phiên" },
                { v: "custom", l: "Lệnh riêng" }
            ]
            onPicked: v => Settings.behavior.logoutMethod = v
        }

        // ô nhập lệnh riêng
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? ScalerService.s(40) : 0
            visible: Settings.behavior.logoutMethod === "custom"
            radius: ScalerService.s(12)
            color: Qt.alpha("#000000", 0.25)
            border.width: ScalerService.s(1)
            border.color: cmd.activeFocus ? page.theme.button.text : Qt.alpha(page.theme.primary.foreground, 0.2)

            TextInput {
                id: cmd
                anchors.fill: parent
                anchors.leftMargin: ScalerService.s(12)
                anchors.rightMargin: ScalerService.s(12)
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                text: Settings.behavior.logoutCustom
                color: page.theme.primary.foreground
                selectionColor: page.theme.button.text
                font { family: Settings.appearance.font; pixelSize: ScalerService.s(13) }
                onEditingFinished: Settings.behavior.logoutCustom = text
                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: cmd.text === "" && !cmd.activeFocus
                    text: AutoTranslateService.t("vd: hyprctl dispatch exit")
                    color: page.theme.primary.dim_foreground
                    font: cmd.font
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: Settings.behavior.logoutMethod === "custom" && Settings.behavior.logoutCustom.trim() === ""
            wrapMode: Text.WordWrap
            text: AutoTranslateService.t("Chưa nhập lệnh: đang dùng chế độ Tự động.")
            color: page.theme.normal.yellow
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
        }
    }

    G.SettingSection {
        title: AutoTranslateService.t("TẮT MÀN HÌNH KHI RẢNH")
        appearAt: 0.5

        G.SettingChoice {
            title: AutoTranslateService.t("Tắt màn hình sau")
            desc: AutoTranslateService.t("Chỉ tắt màn hình (máy vẫn chạy, nhạc vẫn phát); động chuột hoặc bàn phím thì bật lại. Nên đặt ngắn hơn thời gian tự khóa.")
            dimmed: Settings.behavior.keepAwake
            current: Settings.behavior.monitorOffAfterMin
            options: [
                { v: 0, l: "Tắt" }, { v: 1, l: "1 phút" }, { v: 2, l: "2 phút" }, { v: 5, l: "5 phút" },
                { v: 10, l: "10 phút" }, { v: 15, l: "15 phút" }, { v: 30, l: "30 phút" }
            ]
            onPicked: v => Settings.behavior.monitorOffAfterMin = v
        }

        Text {
            Layout.fillWidth: true
            visible: Settings.behavior.keepAwake
            wrapMode: Text.WordWrap
            text: AutoTranslateService.t("Đang tạm dừng vì \"Giữ máy thức\" (Behavior) đang bật.")
            color: page.theme.normal.yellow
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
        }
    }
}
