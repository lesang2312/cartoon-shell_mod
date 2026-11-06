import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

// Settings -> General -> Behavior
//  - Âm thanh giao diện: bật/tắt + âm lượng + nghe thử
//  - Xác nhận trước các thao tác nguồn (ngủ / khóa / đăng xuất / khởi động lại / tắt máy)
//  - Giảm chuyển động: tắt animation chạy nền để đỡ nóng máy
Item {
    id: root

    readonly property color accent: theme.button.text
    readonly property color accent2: Qt.hsla((Math.max(0, accent.hslHue) + 0.09) % 1, accent.hslSaturation, Math.max(0.52, Math.min(0.78, accent.hslLightness)), 1)

    property real animationProgress: 0
    NumberAnimation on animationProgress {
        from: 0
        to: 1
        duration: 500
        running: true
    }

    // ---------- thành phần dùng lại ----------
    // Thẻ nhóm: tiêu đề nhóm + các dòng cài đặt, hiện dần theo thứ tự
    component Section: Rectangle {
        id: sec
        property string title: ""
        property string icon: ""
        property real appearAt: 0.3
        default property alias content: body.data

        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + ScalerService.s(36) + head.implicitHeight + ScalerService.s(12)
        radius: ScalerService.s(Settings.appearance.radius2)
        color: Qt.alpha(theme.primary.dim_background, 0.6)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
        border.color: theme.button.border
        opacity: root.animationProgress > appearAt ? 1 : 0
        transform: Translate { y: root.animationProgress > sec.appearAt ? 0 : ScalerService.s(10); Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } } }
        Behavior on opacity { NumberAnimation { duration: 260 } }

        Row {
            id: head
            x: ScalerService.s(18)
            y: ScalerService.s(16)
            spacing: ScalerService.s(8)
            Rectangle {
                width: ScalerService.s(4)
                height: ScalerService.s(16)
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.accent }
                    GradientStop { position: 1.0; color: root.accent2 }
                }
            }
            Text {
                text: sec.title
                color: root.accent
                font { family: Settings.appearance.font; pixelSize: ScalerService.s(13); bold: true; letterSpacing: 0.5 }
            }
        }
        ColumnLayout {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: head.bottom
            anchors.margins: ScalerService.s(18)
            anchors.topMargin: ScalerService.s(12)
            spacing: ScalerService.s(14)
        }
    }

    // Một dòng cài đặt: tên + mô tả bên trái, điều khiển bên phải
    component SettingRow: RowLayout {
        id: sr
        property string title: ""
        property string desc: ""
        property bool dimmed: false
        default property alias control: slot.data
        Layout.fillWidth: true
        spacing: ScalerService.s(14)
        opacity: dimmed ? 0.45 : 1
        Behavior on opacity { NumberAnimation { duration: 200 } }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(2)
            Text {
                Layout.fillWidth: true
                text: sr.title
                color: theme.primary.foreground
                elide: Text.ElideRight
                font { family: Settings.appearance.font; pixelSize: ScalerService.s(15); bold: true }
            }
            Text {
                Layout.fillWidth: true
                text: sr.desc
                wrapMode: Text.WordWrap
                color: theme.primary.dim_foreground
                font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
            }
        }
        Row {
            id: slot
            Layout.alignment: Qt.AlignVCenter
            spacing: ScalerService.s(10)
        }
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.alpha(theme.primary.foreground, 0.08)
    }

    // Dòng chọn nhanh: tiêu đề + mô tả, bên dưới là dãy chip (chip đang chọn sáng gradient)
    component ChoiceRow: ColumnLayout {
        id: cr
        property string title: ""
        property string desc: ""
        property var options: []        // [{ v: 5, l: "5 phút" }, ...]
        property var current: 0
        property bool dimmed: false
        signal picked(var v)
        Layout.fillWidth: true
        spacing: ScalerService.s(8)
        opacity: dimmed ? 0.45 : 1
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            text: cr.title
            color: theme.primary.foreground
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(15); bold: true }
        }
        Text {
            Layout.fillWidth: true
            text: cr.desc
            wrapMode: Text.WordWrap
            color: theme.primary.dim_foreground
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
        }
        Flow {
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            spacing: ScalerService.s(6)
            Repeater {
                model: cr.options
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool sel: modelData.v === cr.current
                    width: chipText.implicitWidth + ScalerService.s(24)
                    height: ScalerService.s(32)
                    radius: height / 2
                    color: sel ? "transparent" : (chipMa.containsMouse ? Qt.alpha(theme.button.background_select, 0.85) : Qt.alpha(theme.button.background, 0.65))
                    Behavior on color { ColorAnimation { duration: 140 } }
                    scale: chipMa.pressed ? 0.94 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        opacity: chip.sel ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 220 } }
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.accent }
                            GradientStop { position: 1.0; color: root.accent2 }
                        }
                    }
                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: chip.modelData.l
                        color: chip.sel ? theme.primary.background : theme.primary.foreground
                        Behavior on color { ColorAnimation { duration: 180 } }
                        font { family: Settings.appearance.font; pixelSize: ScalerService.s(12); bold: chip.sel }
                    }
                    MouseArea {
                        id: chipMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cr.picked(chip.modelData.v)
                    }
                }
            }
        }
    }

    // ---------- nội dung ----------
    ScrollView {
        id: scroll
        anchors.fill: parent
        anchors.margins: ScalerService.s(20)
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: scroll.availableWidth
            spacing: ScalerService.s(16)

            HeaderSettings {
                name: lang?.general?.behavior || "Behavior"
                opacity: root.animationProgress > 0.1 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            Rectangle {
                Layout.fillWidth: true
                height: ScalerService.s(1)
                color: theme.primary.foreground
                opacity: root.animationProgress > 0.2 ? 0.2 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // ============ Âm thanh ============
            Section {
                title: "ÂM THANH"
                appearAt: 0.3

                SettingRow {
                    title: "Âm thanh giao diện"
                    desc: "Tiếng khi rê chuột và bấm nút trong các panel"
                    CustomToggleSwitch {
                        adapter: Settings.behavior.soundEffects
                        onClicked: Settings.behavior.soundEffects = !Settings.behavior.soundEffects
                    }
                }

                Divider {}

                SettingRow {
                    title: "Âm lượng hiệu ứng"
                    desc: "Độc lập với âm lượng hệ thống"
                    dimmed: !Settings.behavior.soundEffects

                    CustomSlider {
                        id: volSlider
                        anchors.verticalCenter: parent.verticalCenter
                        width: ScalerService.s(170)
                        enabled: Settings.behavior.soundEffects
                        from: 0
                        to: 1
                        stepSize: 0.05
                        value: Settings.behavior.soundVolume
                        onMoved: Settings.behavior.soundVolume = value
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: ScalerService.s(38)
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(Settings.behavior.soundVolume * 100) + "%"
                        color: root.accent
                        font { family: Settings.appearance.font; pixelSize: ScalerService.s(13); bold: true }
                    }
                    Rectangle {
                        id: testBtn
                        anchors.verticalCenter: parent.verticalCenter
                        width: testText.implicitWidth + ScalerService.s(22)
                        height: ScalerService.s(28)
                        radius: height / 2
                        color: testMa.containsMouse ? Qt.alpha(theme.button.background_select, 0.9) : Qt.alpha(theme.button.background, 0.7)
                        scale: testMa.pressed ? 0.92 : 1
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            id: testText
                            anchors.centerIn: parent
                            text: "♪  Thử"
                            color: theme.primary.foreground
                            font { family: Settings.appearance.font; pixelSize: ScalerService.s(12); weight: Font.Medium }
                        }
                        MouseArea {
                            id: testMa
                            anchors.fill: parent
                            enabled: Settings.behavior.soundEffects
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SoundService.playSound("pick")
                        }
                    }
                }
            }

            // ============ An toàn ============
            Section {
                title: "AN TOÀN"
                appearAt: 0.5

                SettingRow {
                    title: "Hỏi xác nhận thao tác nguồn"
                    desc: "Hiện hộp thoại trước khi ngủ, khóa màn hình, đăng xuất, khởi động lại hoặc tắt máy. Tắt đi thì thực hiện ngay khi bấm."
                    CustomToggleSwitch {
                        adapter: Settings.behavior.confirmPowerActions
                        onClicked: Settings.behavior.confirmPowerActions = !Settings.behavior.confirmPowerActions
                    }
                }

                // cảnh báo hiện ra khi tắt xác nhận
                Rectangle {
                    Layout.fillWidth: true
                    visible: opacity > 0.01
                    opacity: Settings.behavior.confirmPowerActions ? 0 : 1
                    Layout.preferredHeight: Settings.behavior.confirmPowerActions ? 0 : warnText.implicitHeight + ScalerService.s(20)
                    Behavior on opacity { NumberAnimation { duration: 220 } }
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    clip: true
                    radius: ScalerService.s(12)
                    color: Qt.alpha(theme.normal.red, 0.14)
                    border.width: ScalerService.s(1)
                    border.color: Qt.alpha(theme.normal.red, 0.45)
                    Text {
                        id: warnText
                        anchors.fill: parent
                        anchors.margins: ScalerService.s(10)
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter
                        text: "⚠  Bấm nhầm \"Tắt máy\" hoặc \"Đăng xuất\" sẽ làm mất công việc chưa lưu."
                        color: theme.normal.red
                        font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
                    }
                }
            }

            // ============ Hiệu năng ============
            Section {
                title: "HIỆU NĂNG"
                appearAt: 0.7

                SettingRow {
                    title: "Giảm chuyển động"
                    desc: "Tắt animation chạy nền (đĩa nhạc quay, sóng thanh tiến trình, hiệu ứng dâng của EQ). Giúp máy mát và êm quạt hơn."
                    CustomToggleSwitch {
                        adapter: Settings.behavior.reduceMotion
                        onClicked: Settings.behavior.reduceMotion = !Settings.behavior.reduceMotion
                    }
                }
            }

            // ============ Tự động khi rảnh ============
            Section {
                title: "KHI KHÔNG THAO TÁC"
                appearAt: 0.8

                SettingRow {
                    title: "Giữ máy thức"
                    desc: "Tạm dừng tự khóa và tự ngủ, hợp khi xem phim hoặc thuyết trình"
                    CustomToggleSwitch {
                        adapter: Settings.behavior.keepAwake
                        onClicked: Settings.behavior.keepAwake = !Settings.behavior.keepAwake
                    }
                }

                Divider {}

                ChoiceRow {
                    title: "Tự khóa màn hình"
                    desc: "Khóa sau khoảng thời gian không dùng chuột hoặc bàn phím"
                    dimmed: Settings.behavior.keepAwake
                    current: Settings.behavior.lockAfterMin
                    options: [
                        { v: 0, l: "Tắt" }, { v: 1, l: "1 phút" }, { v: 2, l: "2 phút" }, { v: 5, l: "5 phút" },
                        { v: 10, l: "10 phút" }, { v: 15, l: "15 phút" }, { v: 30, l: "30 phút" }
                    ]
                    onPicked: v => Settings.behavior.lockAfterMin = v
                }

                Divider {}

                ChoiceRow {
                    title: "Tự chuyển sang chế độ ngủ"
                    desc: "Khóa màn hình rồi ngủ khi không dùng. Nên đặt lâu hơn thời gian tự khóa."
                    dimmed: Settings.behavior.keepAwake
                    current: Settings.behavior.suspendAfterMin
                    options: [
                        { v: 0, l: "Tắt" }, { v: 5, l: "5 phút" }, { v: 10, l: "10 phút" }, { v: 15, l: "15 phút" },
                        { v: 30, l: "30 phút" }, { v: 60, l: "1 giờ" }
                    ]
                    onPicked: v => Settings.behavior.suspendAfterMin = v
                }
            }

            // ============ Góc nóng ============
            Section {
                title: "GÓC NÓNG"
                appearAt: 0.9

                SettingRow {
                    title: "Rê chuột vào góc để mở launcher"
                    desc: "Giữ con trỏ trong góc khoảng 0,2 giây (tránh chạm nhầm). Rê lại để đóng."
                    CustomToggleSwitch {
                        adapter: Settings.behavior.hotCorner
                        onClicked: Settings.behavior.hotCorner = !Settings.behavior.hotCorner
                    }
                }

                // sơ đồ màn hình: bấm vào góc để chọn
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScalerService.s(130)
                    opacity: Settings.behavior.hotCorner ? 1 : 0.4
                    Behavior on opacity { NumberAnimation { duration: 220 } }

                    Rectangle {
                        id: mon
                        anchors.centerIn: parent
                        width: ScalerService.s(210)
                        height: ScalerService.s(118)
                        radius: ScalerService.s(10)
                        color: Qt.alpha("#000000", 0.25)
                        border.width: ScalerService.s(2)
                        border.color: Qt.alpha(theme.primary.foreground, 0.25)

                        Text {
                            anchors.centerIn: parent
                            text: ({ "top-left": "Trên trái", "top-right": "Trên phải", "bottom-left": "Dưới trái", "bottom-right": "Dưới phải" })[Settings.behavior.hotCornerPos]
                            color: root.accent
                            font { family: Settings.appearance.font; pixelSize: ScalerService.s(13); bold: true }
                        }

                        Repeater {
                            model: ["top-left", "top-right", "bottom-left", "bottom-right"]
                            delegate: Item {
                                id: corner
                                required property string modelData
                                readonly property bool sel: Settings.behavior.hotCornerPos === modelData
                                width: ScalerService.s(44)
                                height: ScalerService.s(44)
                                x: modelData.slice(-4) === "left" ? 0 : mon.width - width
                                y: modelData.indexOf("top") === 0 ? 0 : mon.height - height

                                // quầng lan khi chọn
                                Rectangle {
                                    anchors.centerIn: dot
                                    width: corner.sel ? ScalerService.s(34) : ScalerService.s(14)
                                    height: width
                                    radius: width / 2
                                    color: Qt.alpha(root.accent, corner.sel ? 0.25 : 0)
                                    Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                                Rectangle {
                                    id: dot
                                    width: ScalerService.s(14)
                                    height: width
                                    radius: width / 2
                                    x: corner.modelData.slice(-4) === "left" ? ScalerService.s(10) : parent.width - width - ScalerService.s(10)
                                    y: corner.modelData.indexOf("top") === 0 ? ScalerService.s(10) : parent.height - height - ScalerService.s(10)
                                    color: corner.sel ? root.accent : (cornerMa.containsMouse ? root.accent2 : Qt.alpha(theme.primary.foreground, 0.4))
                                    scale: cornerMa.pressed ? 0.8 : (corner.sel ? 1.15 : 1)
                                    Behavior on color { ColorAnimation { duration: 160 } }
                                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                                }
                                MouseArea {
                                    id: cornerMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.behavior.hotCornerPos = corner.modelData
                                }
                            }
                        }
                    }
                }
            }

            // ============ Clipboard ============
            Section {
                title: "CLIPBOARD"
                appearAt: 0.93

                SettingRow {
                    title: "Lịch sử clipboard kiểu Windows"
                    desc: "Lưu các thứ bạn đã sao chép (chữ và ảnh) và mở bảng chọn nhanh bằng phím tắt để dán lại. Cần cài cliphist và wl-clipboard."
                    CustomToggleSwitch {
                        adapter: Settings.behavior.clipboardEnabled
                        onClicked: Settings.behavior.clipboardEnabled = !Settings.behavior.clipboardEnabled
                    }
                }

                Divider {}

                ChoiceRow {
                    title: "Phím tắt mở bảng"
                    desc: "Ctrl+Shift+Z là phím làm lại (redo) trong một số ứng dụng như LibreOffice; chọn Super+V nếu bị trùng."
                    dimmed: !Settings.behavior.clipboardEnabled
                    current: Settings.behavior.clipboardShortcut
                    options: [{ v: "ctrl-shift-z", l: "Ctrl + Shift + Z" }, { v: "super-v", l: "Super + V" }]
                    onPicked: v => Settings.behavior.clipboardShortcut = v
                }

                SettingRow {
                    title: "Mở thử bảng ngay"
                    desc: "Mở không cần phím tắt — nếu bảng hiện mà phím không ăn thì lỗi nằm ở việc đăng ký phím"
                    dimmed: !Settings.behavior.clipboardEnabled
                    Rectangle {
                        width: openText.implicitWidth + ScalerService.s(22)
                        height: ScalerService.s(28)
                        radius: height / 2
                        color: openMa.containsMouse ? Qt.alpha(theme.button.background_select, 0.9) : Qt.alpha(theme.button.background, 0.7)
                        scale: openMa.pressed ? 0.92 : 1
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            id: openText
                            anchors.centerIn: parent
                            text: "Mở thử"
                            color: theme.primary.foreground
                            font { family: Settings.appearance.font; pixelSize: ScalerService.s(12); weight: Font.Medium }
                        }
                        MouseArea {
                            id: openMa
                            anchors.fill: parent
                            enabled: Settings.behavior.clipboardEnabled
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ClipboardService.open = true
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: Settings.behavior.clipboardEnabled
                    text: "Phím tắt được đăng ký tự động trên Hyprland và Sway. Niri: thêm vào config  " + (Settings.behavior.clipboardShortcut === "super-v" ? "Mod+V" : "Ctrl+Shift+Z") + " { spawn \"qs\" \"ipc\" \"call\" \"clipboard\" \"toggle\"; }"
                    color: theme.primary.dim_foreground
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(11); italic: true }
                }
            }

            // ============ Thông báo & OSD ============
            Section {
                title: "THÔNG BÁO & OSD"
                appearAt: 0.95

                SettingRow {
                    title: "Không làm phiền"
                    desc: "Ẩn popup thông báo. Thông báo khẩn cấp vẫn hiện."
                    CustomToggleSwitch {
                        adapter: Settings.behavior.doNotDisturb
                        onClicked: Settings.behavior.doNotDisturb = !Settings.behavior.doNotDisturb
                    }
                }

                Divider {}

                ChoiceRow {
                    title: "Thời gian hiện thông báo"
                    desc: "Áp dụng khi ứng dụng không tự chỉ định thời gian"
                    dimmed: Settings.behavior.doNotDisturb
                    current: Settings.behavior.notifTimeoutSec
                    options: [{ v: 3, l: "3 giây" }, { v: 5, l: "5 giây" }, { v: 10, l: "10 giây" }, { v: 15, l: "15 giây" }, { v: 30, l: "30 giây" }]
                    onPicked: v => Settings.behavior.notifTimeoutSec = v
                }

                ChoiceRow {
                    title: "Số thông báo tối đa cùng lúc"
                    desc: "Thông báo cũ nhất bị đẩy ra khi vượt quá"
                    dimmed: Settings.behavior.doNotDisturb
                    current: Settings.behavior.notifMax
                    options: [{ v: 1, l: "1" }, { v: 2, l: "2" }, { v: 3, l: "3" }, { v: 4, l: "4" }, { v: 5, l: "5" }, { v: 6, l: "6" }]
                    onPicked: v => Settings.behavior.notifMax = v
                }

                ChoiceRow {
                    title: "Vị trí thông báo"
                    desc: "Góc trên màn hình nơi popup xuất hiện"
                    dimmed: Settings.behavior.doNotDisturb
                    current: Settings.behavior.notifPos
                    options: [{ v: "left", l: "Trên trái" }, { v: "top", l: "Trên giữa" }, { v: "right", l: "Trên phải" }]
                    onPicked: v => Settings.behavior.notifPos = v
                }

                Divider {}

                SettingRow {
                    title: "Hiện OSD âm lượng / độ sáng"
                    desc: "Thanh hiển thị nhanh khi chỉnh âm lượng, độ sáng hoặc độ mờ terminal"
                    CustomToggleSwitch {
                        adapter: Settings.behavior.osdEnabled
                        onClicked: Settings.behavior.osdEnabled = !Settings.behavior.osdEnabled
                    }
                }

                ChoiceRow {
                    title: "Thời gian hiện OSD"
                    desc: ""
                    dimmed: !Settings.behavior.osdEnabled
                    current: Settings.behavior.osdDurationMs
                    options: [{ v: 700, l: "0,7 giây" }, { v: 1000, l: "1 giây" }, { v: 1500, l: "1,5 giây" }, { v: 2500, l: "2,5 giây" }]
                    onPicked: v => Settings.behavior.osdDurationMs = v
                }
            }

            Item { Layout.preferredHeight: ScalerService.s(36) }
        }
    }
}
