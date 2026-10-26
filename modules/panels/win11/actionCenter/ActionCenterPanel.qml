// Win11 Quick Settings: ô Wi-Fi / Bluetooth / Âm thanh / Dashboard, thanh âm lượng + độ sáng, chân trang pin + cài đặt
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import qs.commons
import qs.components
import qs.services

PanelWindow {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool hasBattery: UPower.displayDevice.isLaptopBattery
    readonly property int batteryPercent: Math.round(UPower.displayDevice.percentage * 100)
    property real animationProgress: 0

    SequentialAnimation on animationProgress {
        running: true
        NumberAnimation {
            from: 0
            to: 1
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    function volumeIcon() {
        if (!sink || sink.audio.muted)
            return "volume_off";
        const v = Math.round(sink.audio.volume * 100);
        return v < 10 ? "volume_mute" : (v < 60 ? "volume_down" : "volume_up");
    }
    function brightnessIcon(b) {
        if (b <= 0)
            return "brightness_1";
        return "brightness_" + Math.min(7, Math.max(2, Math.ceil(b * 7)));
    }

    implicitWidth: ScalerService.s(380)
    implicitHeight: ScalerService.s(430)
    color: "transparent"
    focusable: true

    anchors {
        left: Settings.bar.position === "left"
        right: Settings.bar.position === "right" || Settings.bar.position === "top" || Settings.bar.position === "bottom"
        top: Settings.bar.position === "top"
        bottom: Settings.bar.position === "left" || Settings.bar.position === "right" || Settings.bar.position === "bottom"
    }
    margins {
        top: Settings.bar.position === "top" ? ScalerService.s(10) : 0
        bottom: (Settings.bar.position === "bottom" || Settings.bar.position === "left" || Settings.bar.position === "right") ? ScalerService.s(10) : 0
        left: Settings.bar.position === "left" ? ScalerService.s(10) : 0
        right: (Settings.bar.position === "right" || Settings.bar.position === "top" || Settings.bar.position === "bottom") ? ScalerService.s(10) : 0
    }

    // Ô bật/tắt kiểu Win11
    component Tile: Rectangle {
        id: tile
        property string icon: ""
        property string title: ""
        property string subtitle: ""
        property bool on: false
        signal clicked

        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(70)
        radius: ScalerService.s(Settings.appearance.radius2)
        color: on ? theme.button.text : theme.primary.dim_background
        border.width: ScalerService.s(1)
        border.color: Qt.rgba(1, 1, 1, 0.12)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: ScalerService.s(14)
            anchors.rightMargin: ScalerService.s(10)
            spacing: ScalerService.s(10)
            IconText {
                name: tile.icon
                textColor: tile.on ? theme.primary.background : theme.primary.foreground
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                CustomText {
                    Layout.fillWidth: true
                    name: tile.title
                    isBold: true
                    size: "xs"
                    textColor: tile.on ? theme.primary.background : theme.primary.foreground
                    elide: Text.ElideRight
                }
                CustomText {
                    Layout.fillWidth: true
                    name: tile.subtitle
                    size: "2xs"
                    textColor: tile.on ? theme.primary.background : theme.primary.dim_foreground
                    elide: Text.ElideRight
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                SoundService.playSound("pick");
                tile.clicked();
            }
        }
        opacity: ma.containsMouse ? 0.9 : 1
        HoverHandler {
            id: ma
        }
    }

    CustomRectangle {
        GlassPanel {
            id: glassBg
        }
        anchors.fill: parent
        opacity: root.animationProgress
        color: glassBg.active ? "transparent" : theme.primary.background
        radius: ScalerService.s(Settings.appearance.radius1)
        border.color: theme.button.border
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: ScalerService.s(20)
                spacing: ScalerService.s(14)

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: ScalerService.s(8)
                    columnSpacing: ScalerService.s(8)

                    Tile {
                        icon: NetworkService.wifi_icon_text_1
                        title: "Wi-Fi"
                        subtitle: NetworkService.connectedWifi === "Checking..." ? "..." : (NetworkService.connectedWifi || "Offline")
                        on: NetworkService.connectedWifi !== "" && NetworkService.connectedWifi !== "Checking..."
                        onClicked: VisibleService.openPanel("wifi")
                    }
                    Tile {
                        icon: "bluetooth"
                        title: "Bluetooth"
                        subtitle: lang.panel?.open || "Mở"
                        on: false
                        onClicked: VisibleService.openPanel("bluetooth")
                    }
                    Tile {
                        icon: root.volumeIcon()
                        title: lang.panel?.sound || "Âm thanh"
                        subtitle: root.sink ? Math.round(root.sink.audio.volume * 100) + "%" : "—"
                        on: root.sink ? !root.sink.audio.muted : false
                        onClicked: {
                            if (root.sink)
                                root.sink.audio.muted = !root.sink.audio.muted;
                        }
                    }
                    Tile {
                        icon: "dashboard"
                        title: "Dashboard"
                        subtitle: lang.panel?.open || "Mở"
                        on: false
                        onClicked: VisibleService.openPanel("dashboard")
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                // Âm lượng
                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScalerService.s(14)
                    IconText {
                        name: root.volumeIcon()
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: VisibleService.openPanel("mixer")
                        }
                    }
                    CustomSlider {
                        Layout.fillWidth: true
                        enabled: root.sink !== null && root.sink !== undefined
                        value: root.sink ? root.sink.audio.volume : 0
                        onMoved: {
                            if (root.sink) {
                                root.sink.audio.volume = value;
                                if (root.sink.audio.muted && value > 0)
                                    root.sink.audio.muted = false;
                            }
                        }
                    }
                }

                // Độ sáng
                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScalerService.s(14)
                    IconText {
                        name: root.brightnessIcon(BrightnessService.currentBrightness)
                    }
                    CustomSlider {
                        Layout.fillWidth: true
                        enabled: true
                        value: BrightnessService.currentBrightness
                        onMoved: BrightnessService.setBright(value)
                    }
                }
            }

            // Chân trang: pin | cài đặt | nguồn
            CustomRectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(54)
                color: theme.primary.dim_background
                bottomLeftRadius: ScalerService.s(Settings.appearance.radius1)
                bottomRightRadius: ScalerService.s(Settings.appearance.radius1)

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: ScalerService.s(1)
                    opacity: 0.4
                    color: theme.primary.dim_foreground
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: ScalerService.s(16)
                    anchors.rightMargin: ScalerService.s(16)
                    spacing: ScalerService.s(8)

                    Item {
                        Layout.preferredWidth: batteryRow.implicitWidth
                        Layout.fillHeight: true
                        RowLayout {
                            id: batteryRow
                            anchors.centerIn: parent
                            spacing: ScalerService.s(6)
                            BatteryIcon {
                                visible: root.hasBattery
                                percent: root.batteryPercent
                                textColor: theme.primary.foreground
                                iconWidth: ScalerService.s(30)
                                iconHeight: ScalerService.s(15)
                            }
                            IconText {
                                visible: !root.hasBattery
                                name: "power"
                                size: "small"
                            }
                            CustomText {
                                name: root.hasBattery ? root.batteryPercent + "%" : "AC"
                                size: "xs"
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: root.hasBattery
                            onClicked: VisibleService.openPanel("battery")
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    ButtonIconText {
                        name: "settings"
                        size: "small"
                        onClicked: {
                            VisibleService.closeAllPanels();
                            VisibleService.togglePanel("fullsetting");
                        }
                    }
                    ButtonIconText {
                        name: "power_settings_new"
                        size: "small"
                        textColor: theme.normal.red
                        onClicked: VisibleService.openPanel("dashboard")
                    }
                }
            }
        }
    }
}
