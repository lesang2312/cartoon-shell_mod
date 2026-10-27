// Win11 Quick Settings (riêng cho thanh Win11):
// lưới ô 2 cột (Wi-Fi, Bluetooth, Airplane, Battery saver, Night light, Dashboard),
// thanh độ sáng + âm lượng (kèm nút chọn thiết bị âm thanh), chân trang pin + cài đặt + nguồn.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import qs.commons
import qs.components
import qs.services
import "."

PanelWindow {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool hasBattery: UPower.displayDevice.isLaptopBattery
    readonly property int batteryPercent: Math.round(UPower.displayDevice.percentage * 100)
    readonly property bool charging: UPowerDeviceState.toString(UPower.displayDevice.state) === "Charging"

    readonly property string btSubtitle: {
        if (!btAdapter || !btAdapter.enabled)
            return "Off";
        const list = btAdapter.devices ? btAdapter.devices.values : [];
        for (let i = 0; i < list.length; i++)
            if (list[i].connected)
                return list[i].name;
        return "Not connected";
    }
    readonly property string wifiSubtitle: {
        if (!QuickSettingsService.wifiEnabled || QuickSettingsService.airplane)
            return "Off";
        const w = NetworkService.connectedWifi;
        return (w === "" || w === "Checking...") ? "Not connected" : w;
    }

    Component.onCompleted: console.log("[QuickSettings] panel loaded")

    property real appear: 0
    NumberAnimation on appear {
        from: 0
        to: 1
        duration: 220
        easing.type: Easing.OutCubic
        running: true
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
    function batteryIcon() {
        if (!hasBattery)
            return "battery_android_question";
        if (charging)
            return "battery_android_frame_bolt";
        const p = UPower.displayDevice.percentage;
        const step = Math.min(6, Math.max(1, Math.ceil(p * 6)));
        return p >= 0.95 ? "battery_android_frame_full" : "battery_android_frame_" + step;
    }

    implicitWidth: ScalerService.s(380)
    implicitHeight: ScalerService.s(410)
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

    Item {
        anchors.fill: parent
        opacity: root.appear
        transform: Translate {
            y: (1 - root.appear) * ScalerService.s(28)
        }

        CustomRectangle {
            GlassPanel {
                id: glassBg
            }
            anchors.fill: parent
            color: glassBg.active ? "transparent" : theme.primary.background
            radius: ScalerService.s(12)
            border.width: ScalerService.s(1)
            border.color: Qt.rgba(1, 1, 1, 0.16)
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: ScalerService.s(18)
                    spacing: ScalerService.s(16)

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: ScalerService.s(8)
                        columnSpacing: ScalerService.s(8)

                        QuickTile {
                            icon: QuickSettingsService.wifiEnabled && !QuickSettingsService.airplane ? NetworkService.wifi_icon_text_1 : "wifi_off"
                            title: "Wi-Fi"
                            subtitle: root.wifiSubtitle
                            checked: QuickSettingsService.wifiEnabled && !QuickSettingsService.airplane
                            hasDetail: true
                            onToggled: QuickSettingsService.toggleWifi()
                            onDetailRequested: VisibleService.openPanel("wifi")
                        }
                        QuickTile {
                            icon: root.btAdapter && root.btAdapter.enabled ? "bluetooth" : "bluetooth_disabled"
                            title: "Bluetooth"
                            subtitle: root.btSubtitle
                            checked: root.btAdapter ? root.btAdapter.enabled : false
                            available: root.btAdapter !== null && root.btAdapter !== undefined
                            hasDetail: true
                            onToggled: root.btAdapter.enabled = !root.btAdapter.enabled
                            onDetailRequested: VisibleService.openPanel("bluetooth")
                        }
                        QuickTile {
                            icon: "flight"
                            title: "Airplane mode"
                            subtitle: QuickSettingsService.airplane ? "On" : "Off"
                            checked: QuickSettingsService.airplane
                            onToggled: QuickSettingsService.toggleAirplane()
                        }
                        QuickTile {
                            icon: "battery_saver"
                            title: "Battery saver"
                            subtitle: !QuickSettingsService.hasPowerProfiles ? "Unavailable" : (QuickSettingsService.batterySaver ? "On" : "Off")
                            checked: QuickSettingsService.batterySaver
                            available: QuickSettingsService.hasPowerProfiles
                            onToggled: QuickSettingsService.toggleBatterySaver()
                        }
                        QuickTile {
                            icon: "nightlight"
                            title: "Night light"
                            subtitle: !QuickSettingsService.hasNightLight ? "Unavailable" : (QuickSettingsService.nightLight ? "On" : "Off")
                            checked: QuickSettingsService.nightLight
                            available: QuickSettingsService.hasNightLight
                            onToggled: QuickSettingsService.toggleNightLight()
                        }
                        QuickTile {
                            icon: "dashboard"
                            title: "Dashboard"
                            subtitle: "Open"
                            onToggled: VisibleService.openPanel("dashboard")
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    // Độ sáng
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScalerService.s(14)
                        IconText {
                            name: root.brightnessIcon(BrightnessService.currentBrightness)
                            size: "small"
                        }
                        CustomSlider {
                            Layout.fillWidth: true
                            enabled: true
                            value: BrightnessService.currentBrightness
                            onMoved: BrightnessService.setBright(value)
                        }
                        Item {
                            Layout.preferredWidth: ScalerService.s(28)
                        }
                    }

                    // Âm lượng + chọn thiết bị âm thanh
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScalerService.s(14)
                        IconText {
                            name: root.volumeIcon()
                            size: "small"
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.sink)
                                        root.sink.audio.muted = !root.sink.audio.muted;
                                }
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
                        Rectangle {
                            Layout.preferredWidth: ScalerService.s(28)
                            Layout.preferredHeight: ScalerService.s(28)
                            radius: ScalerService.s(6)
                            color: mixerHover.hovered ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                            IconText {
                                anchors.centerIn: parent
                                name: "chevron_right"
                                size: "small"
                            }
                            HoverHandler {
                                id: mixerHover
                                cursorShape: Qt.PointingHandCursor
                            }
                            TapHandler {
                                onTapped: VisibleService.openPanel("mixer")
                            }
                        }
                    }
                }

                // Chân trang kiểu Win11: pin | cài đặt | nguồn
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScalerService.s(54)
                    color: Qt.rgba(0, 0, 0, 0.18)

                    Rectangle {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        height: ScalerService.s(1)
                        color: Qt.rgba(1, 1, 1, 0.12)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: ScalerService.s(18)
                        anchors.rightMargin: ScalerService.s(12)
                        spacing: ScalerService.s(6)

                        Item {
                            Layout.preferredWidth: batteryRow.implicitWidth
                            Layout.fillHeight: true
                            RowLayout {
                                id: batteryRow
                                anchors.centerIn: parent
                                spacing: ScalerService.s(6)
                                IconText {
                                    name: root.batteryIcon()
                                    size: "small"
                                    textColor: root.hasBattery && !root.charging && root.batteryPercent <= 20 ? theme.normal.red : theme.primary.foreground
                                }
                                CustomText {
                                    name: root.hasBattery ? root.batteryPercent + "%" : "AC"
                                    size: "xs"
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: root.hasBattery
                                cursorShape: Qt.PointingHandCursor
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
                            onClicked: VisibleService.openPanel("dashboard")
                        }
                    }
                }
            }
        }
    }
}
